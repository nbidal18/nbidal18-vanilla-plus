<#
    Works out what this release changes on the server, stages it, and proves it - without touching
    the live server at all beyond reading it.

      scripts\Test-ServerDeployment.ps1
      scripts\Test-ServerDeployment.ps1 -AddMods carryon-fabric-26.2-2.11.0.jar -Config carryon-common.json
      scripts\Test-ServerDeployment.ps1 -DriveRoot C:\scratch\mirror    rehearse, never deployable

    **Run this while the server is still up and players are still on it.** Everything here is local
    or read-only: the pull downloads, the plan compares hashes, the staging writes into the local
    mirror, and the verification re-reads what it wrote. None of it needs an outage, and the pull
    alone moves 169 MB - measured at 48.7s against 1.0s for the two files a deploy has to re-read
    once the server has actually stopped.

    That is why this is a separate script. All of it used to live in Deploy-LiveServer, which meant
    the only way to run it was to run the deploy - so it ran after the server was stopped, and the
    outage carried a 169 MB transfer nobody was waiting on. v1.0.38 was the release that made that
    obvious. Deploy-LiveServer now does nothing but send what this proved and check that it landed.

    It ends by writing a **deployment plan** to `.nbidal18-deploy-plan.json` in the mirror: the exact
    list of files to send, the exact list to delete, and the SHA-256 each staged file must still have
    when the deploy runs. Deploy-LiveServer refuses to send anything that is not in that plan, and
    refuses a plan whose version, digest or mirror does not match what it is being asked to deploy.

    What it decides, and why each decision is named rather than inferred:

      the helper jar and the integrity policy come from the release and are not optional
      the MOTD is set from the version, because it was forgotten on v1.0.1 and v1.0.2
      **shared jars** - any jar the server and the client pack both carry - are compared by hash and
      re-deployed when they differ. This is the quiet one: the Vanilla Refresh fork ran two commits
      behind and silently wrote its own defaults over 22 settings, and the Hardcore Revive fork kept
      serving a recipe removed a release earlier. Both were found by the owner, not by a check
      **-AddMods** names a jar the server does not have yet. Most of the client pack is client-only
      and nothing here can tell which of it is not, so this stays a decision - but one written down
      here rather than dragged across in a file manager afterwards
      **-Config** names a config file to take from the release's client copy. Named rather than
      synced, because most config genuinely differs: c2me.toml carries the CPU's own parallelism.
      But nothing deployed config at all until v1.0.29, and two files paid for it - sparsestructures
      sat at the mod's default while the pack shipped 5, and bcc-common.toml said v1.0.0 for
      twenty-two releases

    Backups of everything it is about to overwrite go to `.nbidal18-deploy-backups\` in the mirror,
    and every one is diffed against the file it copied. SFTP here serves stale content - to
    Copy-Item as well as to Bash - and a backup that silently predates the live file is not a
    rollback. `server.properties` and the policy are backed up here too, but the deploy re-reads
    both after the shutdown, because the server rewrites them as it stops.
#>
[CmdletBinding()]
param(
    [string[]] $AddMods = @(),
    [string[]] $Config = @(),
    # The local mirror to stage into. Defaults to the one Sync-ServerMirror keeps, which is the
    # server's own state as of the last pull - so the plan is computed against what is really
    # installed, not against a guess. Point it elsewhere to rehearse: a plan staged anywhere but the
    # real mirror is marked rehearsal and Deploy-LiveServer will not accept it.
    [string] $DriveRoot,
    # Skip the pull. Only when the mirror was refreshed moments ago and nothing has touched the
    # server since, because everything downstream trusts the mirror to be the server.
    [switch] $SkipPull,
    [string] $Session = $env:NBIDAL18_WINSCP_SESSION
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $repo 'PACK-VERSION.txt') -Raw).Trim()
$release = Join-Path (Split-Path -Parent $repo) "v.$version"
if (-not (Test-Path -LiteralPath $release)) { throw "No release folder at $release" }

$mirrorDefault = Join-Path (Split-Path -Parent $repo) '_server-payload-cache'
if (-not $DriveRoot) { $DriveRoot = $mirrorDefault }
$isMirror = [IO.Path]::GetFullPath($DriveRoot).TrimEnd([char]92) -eq [IO.Path]::GetFullPath($mirrorDefault).TrimEnd([char]92)
$syncScript = Join-Path $PSScriptRoot 'Sync-ServerMirror.ps1'

Write-Host ("release   v{0}" -f $version)
Write-Host ("staging   {0}{1}" -f $DriveRoot, $(if ($isMirror) { '' } else { '   (REHEARSAL - not deployable)' }))

# ---------------------------------------------------------------- what this release expects
$policySource = Join-Path $release '4. server\nbidal18-integrity.properties'
if (-not (Test-Path -LiteralPath $policySource)) { throw "No generated policy at $policySource" }
$digest = (Select-String -LiteralPath $policySource -Pattern '^expected-manifest-sha256=(.+)$').Matches[0].Groups[1].Value
$localManifest = (Get-FileHash -LiteralPath (Join-Path $repo 'site\sync-manifest.json') -Algorithm SHA256).Hash.ToLower()
if ($digest -ne $localManifest) {
    throw "The policy expects $($digest.Substring(0,16))... but site\sync-manifest.json hashes to $($localManifest.Substring(0,16))... - rebuild before staging"
}

# @() because a single match comes back as a FileInfo, not an array, and .Count then throws
# under StrictMode - which is how this line was first written and how the dry run caught it.
$helpers = @(Get-ChildItem -LiteralPath (Join-Path $release '3. modpack\client\mods') -Filter 'nbidal18-integrity-*.jar')
if ($helpers.Count -ne 1) { throw "Expected exactly one integrity helper in the release, found $($helpers.Count)" }
$helperSource = $helpers[0]
if ($helperSource.Name -notlike "*-$version+*") { throw "The helper is $($helperSource.Name) but this release is $version" }
Write-Host ("digest    {0}" -f $digest.Substring(0, 16))
Write-Host ("helper    {0}" -f $helperSource.Name)

# ---------------------------------------------------------------- the mirror must be the server
# Everything below reads the mirror and calls it the live server, so it has to have been the live
# server recently. A stale mirror would compare this release against jars the server replaced weeks
# ago and report a clean deploy for files it never looked at. The pull empties mods\ and config\
# first, because WinSCP's synchronize skips a locally-newer file - which is how a rehearsal's own
# output was once read back as the server's state.
if ($isMirror -and -not $SkipPull) {
    Write-Host 'pull      refreshing the mirror from the live server'
    # Safe while the server is running: it reads, and writes nothing remote.
    # Sync-ServerMirror throws if WinSCP exits non-zero, and $ErrorActionPreference stops here.
    & $syncScript -Pull -Session $Session -MirrorRoot $DriveRoot | Out-Null
}
elseif ($isMirror) {
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

# Any first-party jar the server holds that this release does not ship is superseded and has to go.
# Two jars declaring one mod id is not a duplicate the loader tolerates: it picks one, and which one
# is not something to leave to chance.
#
# Read here, before the staging below deletes the old helper out of the mirror - the list has to be
# what the *server* holds, not what is left after staging. This used to cover only the integrity
# helper, because that was the only first-party jar ever deployed; nbidal18-voxyworldgen going 1.0.0
# to 1.1.0 renamed a server-side jar for the first time and would have left both installed.
#
# Scoped to nbidal18-* on purpose. A server jar that is not ours - spark, the whitelist mod - is
# server-only by definition and must never be swept up by a rule about what the client pack ships.
$releaseJarNames = @{}
foreach ($jar in @(Get-ChildItem -LiteralPath $releaseMods -Filter *.jar -File)) {
    $releaseJarNames[$jar.Name] = $true
}
$superseded = @(Get-ChildItem -LiteralPath $modsDir -Filter 'nbidal18-*.jar' -File |
        Where-Object { -not $releaseJarNames.ContainsKey($_.Name) })
$shared = @()
$serverOnly = 0
foreach ($live in @(Get-ChildItem -LiteralPath $modsDir -Filter *.jar -File)) {
    if ($live.Name -like 'nbidal18-integrity-*.jar') { continue }
    $mirror = Join-Path $releaseMods $live.Name
    # A superseded first-party jar is also absent from the release, but it is being retired rather
    # than left alone, so counting it as "server-only, untouched" would report the opposite of what
    # is about to happen to it.
    if (-not (Test-Path -LiteralPath $mirror -PathType Leaf)) {
        if (-not ($superseded | Where-Object { $_.Name -eq $live.Name })) { $serverOnly++ }
        continue
    }
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
foreach ($old in $superseded) { Write-Host ("  retire   {0}" -f $old.Name) }
Write-Host ("           {0} server-only jars untouched, {1} client-only jars not considered" -f $serverOnly, $clientOnly)

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

# ---------------------------------------------------------------- stage
[IO.File]::WriteAllBytes($policyLive, [IO.File]::ReadAllBytes($policySource))
[IO.File]::WriteAllBytes((Join-Path $modsDir $helperSource.Name), [IO.File]::ReadAllBytes($helperSource.FullName))
foreach ($old in $existingHelpers) {
    if ($old.Name -ne $helperSource.Name) { [IO.File]::Delete($old.FullName) }
}
[IO.File]::WriteAllText($propsPath, [regex]::Replace($propsText, '(?m)^motd=.*$', { $wantMotd }))
foreach ($jar in @($staleShared) + @($added) + @($configFiles)) {
    [IO.File]::WriteAllBytes($jar.Live, [IO.File]::ReadAllBytes($jar.Source))
}

# ---------------------------------------------------------------- verify what was staged
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

# Re-read every shared jar rather than trusting the copies above. This is the check that would have
# caught both forks, and it is cheap next to the outage it prevents.
$stillStale = @()
foreach ($jar in $shared) {
    if ((Get-FileHash -LiteralPath $jar.Live -Algorithm SHA256).Hash -ne
        (Get-FileHash -LiteralPath $jar.Source -Algorithm SHA256).Hash) {
        $stillStale += $jar.Name
    }
}
if ($stillStale.Count) { $failures.Add('shared jars still differ: ' + ($stillStale -join ', ')) }
Write-Host ("MATCH     {0} shared jars byte-identical to the release" -f $shared.Count)

if ($failures.Count) { throw ('Staging did not verify: ' + ($failures -join '; ')) }

# ---------------------------------------------------------------- hand over
# The plan is the handover, and it is deliberately explicit: Deploy-LiveServer sends this list and
# nothing else, and re-hashes every entry before it sends it. A plan is not a suggestion of what
# might need deploying - it is the whole permitted set.
$sendFiles = @('config\nbidal18-integrity.properties', ('mods\' + $helperSource.Name), 'server.properties')
foreach ($jar in @($staleShared) + @($added)) { $sendFiles += ('mods\' + $jar.Name) }
foreach ($cfg in $configFiles) { $sendFiles += ('config\' + $cfg.Name) }
$sendRemove = @($superseded | ForEach-Object { 'mods\' + $_.Name })

$send = @()
foreach ($rel in $sendFiles) {
    $send += [pscustomobject]@{
        rel = $rel
        sha256 = (Get-FileHash -LiteralPath (Join-Path $DriveRoot $rel) -Algorithm SHA256).Hash.ToLower()
    }
}

$plan = [pscustomobject]@{
    version      = $version
    digest       = $digest
    mirrorRoot   = [IO.Path]::GetFullPath($DriveRoot).TrimEnd([char]92)
    rehearsal    = (-not $isMirror)
    stagedUtc    = (Get-Date).ToUniversalTime().ToString('o')
    motd         = $wantMotd
    backup       = $backup
    send         = $send
    remove       = $sendRemove
    sharedJars   = $shared.Count
    staleShared  = $staleShared.Count
    addedJars    = $added.Count
}
$planPath = Join-Path $DriveRoot '.nbidal18-deploy-plan.json'
[IO.File]::WriteAllText($planPath, ($plan | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))

Write-Host ''
if ($isMirror) {
    Write-Host ("OK        {0} file(s) staged and verified, {1} to remove. Plan written to {2}" -f $send.Count, $sendRemove.Count, (Split-Path $planPath -Leaf))
    Write-Host '          Nothing has reached the server. Push and wait for Pages, then:'
    Write-Host '          scripts\Deploy-LiveServer.ps1 -Apply -WaitForShutdown 900'
}
else {
    Write-Host ("OK        rehearsal complete: {0} file(s) staged and verified in {1}. The live server was not touched, and this plan is not deployable." -f $send.Count, $DriveRoot)
}
