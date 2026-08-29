<#
    Deploys the server-side half of a release, in the order the rules require, and refuses rather
    than guesses.

      scripts\Deploy-LiveServer.ps1              check everything and report, change nothing
      scripts\Deploy-LiveServer.ps1 -Apply       do it

    It exists because the server half is four separate writes done by hand, and only the ones that
    break something announce themselves when forgotten. A stale policy locks every player out and a
    stale helper refuses logins, so those are impossible to miss. A stale MOTD breaks nothing - it
    just tells everyone the wrong version from the server list - and it was missed on both v1.0.1
    and v1.0.2, caught by the owner and not by anything here.

    Refusals, all of which have a real incident behind them:

      the channel must already serve this release's digest. Deploying first means the server demands
      a manifest nobody can download yet, so every launching client is refused for the whole of the
      Pages propagation, on top of the outage.

      the server must be down, proved by a Server List Ping and not by a TCP connect or a log
      timestamp. The pack pauses when empty, so a running server writes nothing for hours; the host
      can hold the port open with the server stopped; and log timestamps are UTC while the clock
      here is not.

      every backup is diffed against the file it copied. This SFTP mount serves stale content - to
      Copy-Item as well as to Bash - and a backup that silently predates the live file is not a
      rollback.
#>
[CmdletBinding()]
param(
    [switch] $Apply,
    [string] $DriveRoot = 'Y:\',
    [int] $TimeoutSec = 8
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

Write-Host ("release   v{0}" -f $version)
Write-Host ("server    {0}" -f $address)

# ---------------------------------------------------------------- what this release expects
$policySource = Join-Path $release '4. server\nbidal18-integrity.properties'
if (-not (Test-Path -LiteralPath $policySource)) { throw "No generated policy at $policySource" }
$digest = (Select-String -LiteralPath $policySource -Pattern '^expected-manifest-sha256=(.+)$').Matches[0].Groups[1].Value
$localManifest = (Get-FileHash -LiteralPath (Join-Path $repo 'site\sync-manifest.json') -Algorithm SHA256).Hash.ToLower()
if ($digest -ne $localManifest) {
    throw "The policy expects $($digest.Substring(0,16))... but site\sync-manifest.json hashes to $($localManifest.Substring(0,16))... - rebuild before deploying"
}

$helperSource = Get-ChildItem -LiteralPath (Join-Path $release '3. modpack\client\mods') -Filter 'nbidal18-integrity-*.jar'
if ($helperSource.Count -ne 1) { throw "Expected exactly one integrity helper in the release, found $($helperSource.Count)" }
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
    throw ("The channel serves $($served.Substring(0,16))... but this release is $($digest.Substring(0,16))... - " +
        'push and wait for Pages first. Deploying ahead of the channel refuses every launching client.')
}
Write-Host 'channel   already serving this release'

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

if (Test-ServerUp) {
    throw 'The server answered a status ping. Stop it from the provider panel; the helper jar and the MOTD are not hot-reloadable.'
}
Write-Host 'server    confirmed down (no status reply)'

$configDir = Join-Path $DriveRoot 'config'
$modsDir = Join-Path $DriveRoot 'mods'
$propsPath = Join-Path $DriveRoot 'server.properties'
$policyLive = Join-Path $configDir 'nbidal18-integrity.properties'
$existingHelpers = @(Get-ChildItem -LiteralPath $modsDir -Filter 'nbidal18-integrity-*.jar')
$wantMotd = "motd=v$version - @nbidal18 on Discord"
$propsText = [IO.File]::ReadAllText($propsPath)
$motdNow = ([regex]::Match($propsText, '(?m)^motd=.*$')).Value

Write-Host ''
Write-Host 'would change:'
Write-Host ("  policy   {0}" -f $policyLive)
Write-Host ("  helper   {0}  ->  {1}" -f (($existingHelpers | ForEach-Object { $_.Name }) -join ', '), $helperSource.Name)
Write-Host ("  motd     {0}  ->  {1}" -f $motdNow, $wantMotd)

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Dry run. Re-run with -Apply to deploy.'
    return
}

# ---------------------------------------------------------------- back up, and prove the backup
$stamp = (Get-Date -Format 'yyyy-MM-dd') + "-v$version"
$backup = Join-Path (Join-Path $DriveRoot '.nbidal18-deploy-backups') $stamp
New-Item -ItemType Directory -Force -Path $backup | Out-Null
$toBackUp = @($policyLive, $propsPath) + ($existingHelpers | ForEach-Object { $_.FullName })
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

# ---------------------------------------------------------------- verify
$failures = New-Object Collections.Generic.List[string]
foreach ($pair in @(
        @{ s = $policySource; d = $policyLive },
        @{ s = $helperSource.FullName; d = (Join-Path $modsDir $helperSource.Name) })) {
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

if ($failures.Count) { throw ('Deployment did not verify: ' + ($failures -join '; ')) }
Write-Host ''
Write-Host 'OK        policy, helper and MOTD deployed. Start the server.'
