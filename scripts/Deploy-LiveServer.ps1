<#
    Deploys the server-side half of a release, in the order the rules require, and refuses rather
    than guesses.

      scripts\Deploy-LiveServer.ps1              check everything and report, change nothing
      scripts\Deploy-LiveServer.ps1 -Apply -WaitForShutdown 900     do it, and keep the outage short
      scripts\Deploy-LiveServer.ps1 -Apply       do it, server already stopped
      scripts\Deploy-LiveServer.ps1 -Apply -Rehearse    stage and verify locally, send nothing

    **Prefer -WaitForShutdown.** Only the push at the end needs the server down; the pull, the plan,
    the staging and the hash checks are read-only and safe while players are on - and the pull alone
    moves 169 MB, because it empties the mirror rather than trust it. Started while the server is up,
    all of that is done by the time the port closes and the outage is the push and the read-back.
    Started after it is stopped, the same work runs with nobody able to play. v1.0.38 was the release
    that made the difference obvious.

    **It reaches the server over SFTP, not a drive letter.** It used to write to `Y:`, a CloudMounter
    SFTP mount, and when that trial expired the default pointed at a drive that no longer existed -
    so every run since died on `Cannot find drive` and the deploy was finished by hand with
    Sync-ServerMirror, which is the exact exposure this script exists to remove. Now it pulls the
    mirror, stages into it, verifies, pings, pushes, and reads every file back off the server to
    prove it landed. Nothing about the order or the refusals changed; only how the bytes travel.

    It exists because the server half was a set of separate writes done by hand, and only the ones
    that break something announce themselves when forgotten. A stale policy locks every player out
    and a stale helper refuses logins, so those are impossible to miss. A stale MOTD breaks nothing -
    it just tells everyone the wrong version from the server list - and it was missed on both v1.0.1
    and v1.0.2, caught by the owner and not by anything here.

    **Shared mod jars are the quiet one.** Any jar the server and the client pack both carry has to
    be deployed too, and nothing here used to do it. Twice that was missed and neither failed: the
    Vanilla Refresh fork ran two commits behind and wrote its own defaults over 22 settings, and the
    Hardcore Revive fork kept serving a recipe that had been removed a release earlier - found in
    JEI by the owner, not by any check. Both were copied by hand afterwards, which is the same
    exposure again. Now every shared jar is hashed and any that differs is deployed with the rest.

    What it will not do is *work out* that a jar the server does not have belongs on it. Most of the
    client pack is client-only and nothing here can tell which of it is not, so a genuinely new
    server-side mod stays a decision - but one made by naming it in -AddMods, where it is copied and
    hash-verified with everything else, rather than dragged across afterwards. The count of
    client-only jars is printed so that stays visible rather than silent.

    Refusals, all of which have a real incident behind them:

      the channel must already serve this release's digest. Deploying first means the server demands
      a manifest nobody can download yet, so every launching client is refused for the whole of the
      Pages propagation, on top of the outage.

      the server must be down before anything is written, proved by a Server List Ping and not by a
      TCP connect or a log timestamp. The ping runs immediately before the first write, never
      earlier, so an "it's off" from a minute ago is never carried forward. -WaitForShutdown makes
      it wait for the port to close rather than refuse; it never makes it skip the proof, and the
      second ping before the first remote byte is unchanged. The pack pauses when empty, so a running server writes nothing for hours; the host
      can hold the port open with the server stopped; and log timestamps are UTC while the clock
      here is not.

      every backup is diffed against the file it copied. SFTP here serves stale content - to
      Copy-Item as well as to Bash - and a backup that silently predates the live file is not a
      rollback.

      the mirror is pulled before the plan is drawn, because the whole plan is "what does the server
      have and how does it differ from the release". Computed against a mirror of unknown age it
      would compare this release against jars the server replaced weeks ago and report a clean
      deploy for files it never looked at. -SkipPull exists for a mirror refreshed moments ago.
#>
[CmdletBinding()]
param(
    [switch] $Apply,
    # Jars this release puts on the server for the first time, named one by one. Which client jars
    # belong on a server cannot be inferred - see the note above - but doing the copy by hand
    # afterwards is the same exposure the rest of this script exists to remove. So it stays a
    # decision, and the decision is written down here rather than typed into a file manager.
    [string[]] $AddMods = @(),
    # Config files, relative to config\, to put on the server from the release's client copy.
    #
    # Named rather than synced, because most config genuinely differs: c2me.toml carries the CPU's
    # own parallelism and the server has fewer cores than any client. But nothing deployed config at
    # all, and two files paid for it - sparsestructures.json5 sat at the mod's default spreadFactor
    # of 2 while the pack shipped 5, so the server generated structures at a density nobody chose,
    # and bcc-common.toml still said v1.0.0 twenty-two releases later.
    [string[]] $Config = @(),
    # The local mirror the deploy is staged into. Defaults to the one Sync-ServerMirror keeps, which
    # is the server's own state as of the last pull - so the plan below is computed against what is
    # really installed, not against a guess. Point it somewhere else only to rehearse.
    [string] $DriveRoot,
    # Skip the pull. Only when the mirror was refreshed moments ago and nothing has touched the
    # server since, because everything downstream trusts the mirror to be the server.
    [switch] $SkipPull,
    # Stage and verify locally, then stop without touching the server. Implied by a -DriveRoot that
    # is not the real mirror, because a throwaway tree has no server behind it to push to.
    [switch] $Rehearse,
    [string] $Session = $env:NBIDAL18_WINSCP_SESSION,
    [int] $TimeoutSec = 8,
    # Seconds to wait for the server to go down, instead of refusing the moment it answers.
    #
    # This is what keeps the outage short. Everything before the write - the pull, the plan, the
    # staging, the hash checks - is local or read-only and perfectly safe while players are on, and
    # the pull alone moves 169 MB. Run with this and all of it happens while the server is still
    # serving; stop the server from the panel when it says it is waiting, and the writes go out
    # within seconds of the port closing. Without it the same work sits inside the outage, which is
    # how a two-mod release cost ten minutes of downtime.
    #
    # The server rewrites server.properties and the policy as it shuts down, so both are re-fetched
    # after the wait and before anything is staged over them.
    [int] $WaitForShutdown = 0
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $repo 'PACK-VERSION.txt') -Raw).Trim()
$release = Join-Path (Split-Path -Parent $repo) "v.$version"
if (-not (Test-Path -LiteralPath $release)) { throw "No release folder at $release" }

$serverFile = Join-Path $repo 'SERVER.txt'
if (-not (Test-Path -LiteralPath $serverFile)) { throw "No SERVER.txt at $serverFile" }
$address = (Get-Content -LiteralPath $serverFile -Raw).Trim()
$serverHost, $serverPort = $address -split ':', 2
$serverPort = [int] $serverPort

$mirrorDefault = Join-Path (Split-Path -Parent $repo) '_server-payload-cache'
if (-not $DriveRoot) { $DriveRoot = $mirrorDefault }
$isMirror = [IO.Path]::GetFullPath($DriveRoot).TrimEnd('\') -eq [IO.Path]::GetFullPath($mirrorDefault).TrimEnd('\')
$push = $isMirror -and -not $Rehearse
$syncScript = Join-Path $PSScriptRoot 'Sync-ServerMirror.ps1'

Write-Host ("release   v{0}" -f $version)
Write-Host ("server    {0}" -f $address)
Write-Host ("staging   {0}" -f $DriveRoot)

# ---------------------------------------------------------------- what this release expects
$policySource = Join-Path $release '4. server\nbidal18-integrity.properties'
if (-not (Test-Path -LiteralPath $policySource)) { throw "No generated policy at $policySource" }
$digest = (Select-String -LiteralPath $policySource -Pattern '^expected-manifest-sha256=(.+)$').Matches[0].Groups[1].Value
$localManifest = (Get-FileHash -LiteralPath (Join-Path $repo 'site\sync-manifest.json') -Algorithm SHA256).Hash.ToLower()
if ($digest -ne $localManifest) {
    throw "The policy expects $($digest.Substring(0,16))... but site\sync-manifest.json hashes to $($localManifest.Substring(0,16))... - rebuild before deploying"
}

# @() because a single match comes back as a FileInfo, not an array, and .Count then throws
# under StrictMode - which is how this line was first written and how the dry run caught it.
$helpers = @(Get-ChildItem -LiteralPath (Join-Path $release '3. modpack\client\mods') -Filter 'nbidal18-integrity-*.jar')
if ($helpers.Count -ne 1) { throw "Expected exactly one integrity helper in the release, found $($helpers.Count)" }
$helperSource = $helpers[0]
if ($helperSource.Name -notlike "*-$version+*") { throw "The helper is $($helperSource.Name) but this release is $version" }
Write-Host ("digest    {0}" -f $digest.Substring(0, 16))
Write-Host ("helper    {0}" -f $helperSource.Name)

# ---------------------------------------------------------------- the channel must be ahead of us
$packUrl = (Get-Content -LiteralPath (Join-Path $repo 'UPDATE-URL.txt') -Raw).Trim()
$manifestUrl = ($packUrl -replace '[^/]+$', '') + 'sync-manifest.json'
$tmp = Join-Path $env:TEMP ("nbidal18-live-manifest-" + [Guid]::NewGuid() + '.json')
try {
    Invoke-WebRequest -Uri ($manifestUrl + '?cb=' + [Guid]::NewGuid()) -OutFile $tmp -UseBasicParsing -TimeoutSec 30
    $served = (Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash.ToLower()
}
finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
if ($served -ne $digest) {
    # Only a real deploy is refused. A dry run and a rehearsal send nothing, and being unable to
    # preview the plan until after the push made the push the first time anyone saw it - the same
    # reason the ping below sits where it does.
    $msg = ("The channel serves $($served.Substring(0,16))... but this release is $($digest.Substring(0,16))... - " +
        'push and wait for Pages first. Deploying ahead of the channel refuses every launching client.')
    if ($Apply -and $push) { throw $msg }
    Write-Host ("channel   BEHIND - {0}" -f $msg)
}
else { Write-Host 'channel   already serving this release' }

# ---------------------------------------------------------------- the server must be down
function Get-VarInt([int] $value) {
    $bytes = New-Object Collections.Generic.List[byte]
    while ($true) {
        $b = $value -band 0x7F
        $value = [int] (([uint32] $value) -shr 7)
        if ($value -ne 0) { $bytes.Add([byte] ($b -bor 0x80)) } else { $bytes.Add([byte] $b); break }
    }
    return , $bytes.ToArray()
}

function Test-ServerUp {
    $client = New-Object Net.Sockets.TcpClient
    try {
        $task = $client.ConnectAsync($serverHost, $serverPort)
        if (-not $task.Wait($TimeoutSec * 1000) -or -not $client.Connected) { return $false }
        $stream = $client.GetStream()
        $stream.ReadTimeout = $TimeoutSec * 1000

        $hostBytes = [Text.Encoding]::UTF8.GetBytes($serverHost)
        $payload = New-Object Collections.Generic.List[byte]
        $payload.AddRange((Get-VarInt 0))            # packet id: handshake
        $payload.AddRange((Get-VarInt 767))          # protocol
        $payload.AddRange((Get-VarInt $hostBytes.Length))
        $payload.AddRange($hostBytes)
        $payload.Add([byte] (($serverPort -shr 8) -band 0xFF))
        $payload.Add([byte] ($serverPort -band 0xFF))
        $payload.AddRange((Get-VarInt 1))            # next state: status
        $frame = @((Get-VarInt $payload.Count)) + $payload
        $stream.Write($frame, 0, $frame.Length)

        $request = @((Get-VarInt 1)) + (Get-VarInt 0)
        $stream.Write($request, 0, $request.Length)
        $stream.Flush()

        # A single byte back is enough: only a running Minecraft server answers a status request.
        return ($stream.ReadByte() -ge 0)
    }
    catch { return $false }
    finally { $client.Close() }
}

# ---------------------------------------------------------------- the mirror must be the server
# Everything below reads the mirror and calls it the live server, so it has to have been the live
# server recently. A stale mirror would compare this release against jars the server replaced weeks
# ago and report a clean deploy for files it never looked at. The pull empties mods\ and config\
# first, because WinSCP's synchronize skips a locally-newer file - which is how a rehearsal's own
# output was once read back as the server's state.
if ($push -and -not $SkipPull) {
    Write-Host 'pull      refreshing the mirror from the live server'
    # Sync-ServerMirror throws if WinSCP exits non-zero, and $ErrorActionPreference stops here.
    & $syncScript -Pull -Session $Session -MirrorRoot $DriveRoot | Out-Null
}
elseif ($push) {
    Write-Host 'pull      SKIPPED by -SkipPull - the mirror is trusted to still be the server'
}

$configDir = Join-Path $DriveRoot 'config'
$modsDir = Join-Path $DriveRoot 'mods'
$propsPath = Join-Path $DriveRoot 'server.properties'
$policyLive = Join-Path $configDir 'nbidal18-integrity.properties'
$existingHelpers = @(Get-ChildItem -LiteralPath $modsDir -Filter 'nbidal18-integrity-*.jar')

# Shared jars: present on the server AND in the client pack. The helper is excluded because it is
# version-stamped and handled on its own above - matching it by name here would compare v1.0.10
# against v1.0.11 and call every release stale.
$releaseMods = Join-Path $release '3. modpack\client\mods'
$shared = @()
$serverOnly = 0
foreach ($live in @(Get-ChildItem -LiteralPath $modsDir -Filter *.jar -File)) {
    if ($live.Name -like 'nbidal18-integrity-*.jar') { continue }
    $mirror = Join-Path $releaseMods $live.Name
    if (-not (Test-Path -LiteralPath $mirror -PathType Leaf)) { $serverOnly++; continue }
    $shared += [pscustomobject]@{
        Name = $live.Name
        Live = $live.FullName
        Source = $mirror
        # Read both through the same call the deploy uses, so a stale mount shows up here and not
        # after the write.
        Stale = (Get-FileHash -LiteralPath $live.FullName -Algorithm SHA256).Hash -ne
                (Get-FileHash -LiteralPath $mirror -Algorithm SHA256).Hash
    }
}
$staleShared = @($shared | Where-Object { $_.Stale })
$clientOnly = @(Get-ChildItem -LiteralPath $releaseMods -Filter *.jar -File).Count - $shared.Count - 1

# Refuse a name that is already there as loudly as one that does not exist. A jar the server has is
# a shared jar and is compared by hash above; listing it here too would mean two rules deciding the
# same file, and the answer to "was it deployed?" would depend on which ran last.
$added = @()
foreach ($name in $AddMods) {
    $source = Join-Path $releaseMods $name
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "-AddMods named $name, which is not in the release's mods folder"
    }
    $live = Join-Path $modsDir $name
    if (Test-Path -LiteralPath $live -PathType Leaf) {
        throw "-AddMods named $name, which the server already has - it is a shared jar and is handled by hash"
    }
    $added += [pscustomobject]@{ Name = $name; Live = $live; Source = $source }
}

# Unlike -AddMods these may already exist - both files this was written for did - so an existing
# copy is overwritten rather than refused. One that already matches is dropped from the plan so the
# report says what will actually change.
$releaseConfig = Join-Path $release '3. modpack\client\config'
$configFiles = @()
foreach ($name in $Config) {
    $source = Join-Path $releaseConfig $name
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "-Config named $name, which the release does not publish under config\"
    }
    $live = Join-Path $configDir $name
    if ((Test-Path -LiteralPath $live -PathType Leaf) -and
        (Get-FileHash -LiteralPath $live -Algorithm SHA256).Hash -eq
        (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash) {
        continue
    }
    $configFiles += [pscustomobject]@{ Name = $name; Live = $live; Source = $source }
}

$wantMotd = "motd=v$version - @nbidal18 on Discord"
$propsText = [IO.File]::ReadAllText($propsPath)
$motdNow = ([regex]::Match($propsText, '(?m)^motd=.*$')).Value

Write-Host ''
Write-Host 'would change:'
Write-Host ("  policy   {0}" -f $policyLive)
Write-Host ("  helper   {0}  ->  {1}" -f (($existingHelpers | ForEach-Object { $_.Name }) -join ', '), $helperSource.Name)
Write-Host ("  motd     {0}  ->  {1}" -f $motdNow, $wantMotd)
if ($staleShared.Count) {
    foreach ($jar in $staleShared) { Write-Host ("  jar      {0}" -f $jar.Name) }
}
else {
    Write-Host ("  jars     none - all {0} shared jars already match" -f $shared.Count)
}
foreach ($jar in $added) { Write-Host ("  new jar  {0}" -f $jar.Name) }
foreach ($cfg in $configFiles) { Write-Host ("  config   {0}" -f $cfg.Name) }
Write-Host ("           {0} server-only jars untouched, {1} client-only jars not considered" -f $serverOnly, $clientOnly)

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Dry run. Re-run with -Apply to deploy.'
    return
}

# The ping sits here rather than earlier so that a dry run works whatever the server is doing -
# reading the mount is safe, and being unable to preview a deploy while the server is up is just
# an obstacle. For -Apply it is the last thing before the first write, which is where the rule
# wants it: never carry forward an earlier "it's off".
$live = $push
if ($live) {
    $waited = $false
    if ((Test-ServerUp) -and $WaitForShutdown -gt 0) {
        Write-Host ("server    up - waiting up to {0}s for it to stop. Stop it from the provider panel now." -f $WaitForShutdown)
        $waited = $true
        $deadline = (Get-Date).AddSeconds($WaitForShutdown)
        while (Test-ServerUp) {
            if ((Get-Date) -gt $deadline) {
                throw "The server was still up after ${WaitForShutdown}s. Nothing was sent."
            }
            Start-Sleep -Seconds 3
        }
    }
    if (Test-ServerUp) {
        throw ('The server answered a status ping. Stop it from the provider panel; the helper jar, ' +
            'the shared jars and the MOTD are not hot-reloadable. Pass -WaitForShutdown to have this ' +
            'wait for the port to close instead, which keeps the pull and the staging out of the outage.')
    }
    Write-Host 'server    confirmed down (no status reply)'

    # The pull above ran while the server was still serving, so its copy of these two predates the
    # shutdown. The server escapes and restamps server.properties as it stops, and pushing the older
    # copy would silently undo that - which is the same stale-file trap the backups are diffed for.
    # Only these two: the server never rewrites a jar or a mod's config.
    if ($waited) {
        Write-Host 'refresh   re-fetching server.properties and the policy after the shutdown'
        & $syncScript -Pull -VolatileOnly -Session $Session -MirrorRoot $DriveRoot | Out-Null
        $propsText = [IO.File]::ReadAllText($propsPath)
        $motdNow = ([regex]::Match($propsText, '(?m)^motd=.*$')).Value
        Write-Host ("  motd     {0}  ->  {1}" -f $motdNow, $wantMotd)
    }
}
else {
    # A rehearsal writes into a tree with no server behind it, so there is nothing to be down. This
    # exists so the write-and-verify half can be exercised without an outage - it had never run
    # against a stale jar until it was tested this way.
    Write-Host ("REHEARSAL staging only ({0}) - no ping, nothing here reaches the server" -f $DriveRoot)
}

# ---------------------------------------------------------------- back up, and prove the backup
$stamp = (Get-Date -Format 'yyyy-MM-dd') + "-v$version"
$backup = Join-Path (Join-Path $DriveRoot '.nbidal18-deploy-backups') $stamp
New-Item -ItemType Directory -Force -Path $backup | Out-Null
$toBackUp = @($policyLive, $propsPath) + ($existingHelpers | ForEach-Object { $_.FullName }) +
    ($staleShared | ForEach-Object { $_.Live })
foreach ($p in $toBackUp) {
    $dest = Join-Path $backup (Split-Path $p -Leaf)
    [IO.File]::WriteAllBytes($dest, [IO.File]::ReadAllBytes($p))
    if ((Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash) {
        throw "The backup of $p does not match the live file - the mount served stale content, do not proceed"
    }
}
Write-Host ("backup    {0} files -> {1}" -f $toBackUp.Count, $backup)

# ---------------------------------------------------------------- deploy
[IO.File]::WriteAllBytes($policyLive, [IO.File]::ReadAllBytes($policySource))
[IO.File]::WriteAllBytes((Join-Path $modsDir $helperSource.Name), [IO.File]::ReadAllBytes($helperSource.FullName))
foreach ($old in $existingHelpers) {
    if ($old.Name -ne $helperSource.Name) { [IO.File]::Delete($old.FullName) }
}
[IO.File]::WriteAllText($propsPath, [regex]::Replace($propsText, '(?m)^motd=.*$', { $wantMotd }))
foreach ($jar in @($staleShared) + @($added) + @($configFiles)) {
    [IO.File]::WriteAllBytes($jar.Live, [IO.File]::ReadAllBytes($jar.Source))
}

# ---------------------------------------------------------------- verify
$failures = New-Object Collections.Generic.List[string]
$verify = @(
    @{ s = $policySource; d = $policyLive },
    @{ s = $helperSource.FullName; d = (Join-Path $modsDir $helperSource.Name) })
foreach ($jar in @($staleShared) + @($added) + @($configFiles)) { $verify += @{ s = $jar.Source; d = $jar.Live } }
foreach ($pair in $verify) {
    $a = (Get-FileHash -LiteralPath $pair.s -Algorithm SHA256).Hash
    $b = (Get-FileHash -LiteralPath $pair.d -Algorithm SHA256).Hash
    $sa = (Get-Item -LiteralPath $pair.s).Length
    $sb = (Get-Item -LiteralPath $pair.d).Length
    if ($a -ne $b -or $sa -ne $sb) { $failures.Add((Split-Path $pair.d -Leaf)) }
    Write-Host ("{0}  {1,-46} {2,8} B" -f $(if ($a -eq $b -and $sa -eq $sb) { 'MATCH   ' } else { 'MISMATCH' }), (Split-Path $pair.d -Leaf), $sb)
}

$stale = @(Get-ChildItem -LiteralPath $modsDir -Filter 'nbidal18-integrity-*.jar' | Where-Object { $_.Name -ne $helperSource.Name })
if ($stale.Count) { $failures.Add('an older helper is still installed: ' + (($stale | ForEach-Object { $_.Name }) -join ', ')) }

# server.properties may lose nothing but the motd and the server's own date stamp.
$before = [IO.File]::ReadAllText((Join-Path $backup 'server.properties')) -split "`r?`n"
$after = [IO.File]::ReadAllText($propsPath) -split "`r?`n"
$keysBefore = @($before | Where-Object { $_ -match '^[a-z][a-z0-9.\-]*=' } | ForEach-Object { ($_ -split '=', 2)[0] })
$keysAfter = @($after | Where-Object { $_ -match '^[a-z][a-z0-9.\-]*=' } | ForEach-Object { ($_ -split '=', 2)[0] })
if (Compare-Object $keysBefore $keysAfter) { $failures.Add('server.properties gained or lost a key') }
Write-Host ("MATCH     server.properties {0} keys, motd -> v{1}" -f $keysAfter.Count, $version)

# Re-read every shared jar from the mount rather than trusting the copies above. This is the check
# that would have caught both forks, and it is cheap next to the outage it prevents.
$stillStale = @()
foreach ($jar in $shared) {
    if ((Get-FileHash -LiteralPath $jar.Live -Algorithm SHA256).Hash -ne
        (Get-FileHash -LiteralPath $jar.Source -Algorithm SHA256).Hash) {
        $stillStale += $jar.Name
    }
}
if ($stillStale.Count) { $failures.Add('shared jars still differ: ' + ($stillStale -join ', ')) }
Write-Host ("MATCH     {0} shared jars byte-identical to the release" -f $shared.Count)

if ($failures.Count) { throw ('Deployment did not verify: ' + ($failures -join '; ')) }

# ---------------------------------------------------------------- send it
# Everything above wrote into the mirror. Nothing has reached the server yet, which is the point:
# the plan is checked, staged and hash-verified against a copy first, and only a deploy that passed
# all of that is allowed near the live host.
if (-not $push) {
    Write-Host ''
    Write-Host ("OK        rehearsal complete: {0} updated and {1} new jar(s) staged and verified in {2}. The live server was not touched." -f $staleShared.Count, $added.Count, $DriveRoot)
    return
}

$sendFiles = @('config\nbidal18-integrity.properties', ('mods\' + $helperSource.Name), 'server.properties')
foreach ($jar in @($staleShared) + @($added)) { $sendFiles += ('mods\' + $jar.Name) }
foreach ($cfg in $configFiles) { $sendFiles += ('config\' + $cfg.Name) }
$sendRemove = @($existingHelpers | Where-Object { $_.Name -ne $helperSource.Name } | ForEach-Object { 'mods\' + $_.Name })

Write-Host ''
# The ping again, because the outage is only proved for the moment it was taken and the checks above
# are not instant. A server that came back up between them would save its own state over this.
if (Test-ServerUp) { throw 'The server came back up while this was staging. Nothing was sent. Stop it and re-run.' }
Write-Host 'server    still down immediately before the first remote write'

& $syncScript -Push -Files $sendFiles -Remove $sendRemove -Session $Session -MirrorRoot $DriveRoot | Out-Null

# ---------------------------------------------------------------- prove it landed
# Read every file back off the server rather than trusting the transfer's own OK. A push that
# reported success and a file that is actually there are different claims, and only the second one
# keeps players out of a lockout.
$readback = Join-Path $env:TEMP ('nbidal18-deploy-verify-' + [Guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $readback | Out-Null
$remoteBad = @()
try {
    foreach ($rel in $sendFiles) {
        $to = Join-Path $readback ($rel -replace '[\\/]', '_')
        & $syncScript -Get ($rel -replace '\\', '/') -To $to -Session $Session -MirrorRoot $DriveRoot | Out-Null
        if (-not (Test-Path -LiteralPath $to)) { $remoteBad += ($rel + ' (not readable back)'); continue }
        $want = (Get-FileHash -LiteralPath (Join-Path $DriveRoot $rel) -Algorithm SHA256).Hash
        $got = (Get-FileHash -LiteralPath $to -Algorithm SHA256).Hash
        if ($want -ne $got) { $remoteBad += ($rel + ' (hash differs on the server)') }
        Write-Host ("{0}  {1}" -f $(if ($want -eq $got) { 'ON SERVER' } else { 'DIFFERS  ' }), $rel)
    }
}
finally { Remove-Item -LiteralPath $readback -Recurse -Force -ErrorAction SilentlyContinue }
if ($remoteBad.Count) { throw ('Deployed but did not verify on the server: ' + ($remoteBad -join '; ')) }

Write-Host ''
Write-Host ("OK        policy, helper, MOTD, {0} updated and {1} new jar(s) on the server and verified by hash. Start it." -f $staleShared.Count, $added.Count)
