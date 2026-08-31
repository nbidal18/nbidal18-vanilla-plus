<#
    Runs the real updater against the local build and checks what it produced.

      scripts\Test-LocalSync.ps1
      scripts\Test-LocalSync.ps1 -KeepGameDir     leave the instance for inspection

    `site\` is served on a loopback port and the updater is pointed at it, so this tests the release
    **before** it is published rather than after. Nothing touches the real instance, the real server
    or the channel.

    Every other check looks at one end of the pipe. `Build-Release` proves the build is coherent and
    `Verify-PublishedChannel` proves the channel serves it; only this proves the thing in between -
    that the updater, given that channel, produces the instance the manifest describes.

    The assertions, and why each is here:

      installs      every managed file arrives with the hash the manifest records
      preserves     a `player`-class file the updater must never restore is still published once
      pins          every property rule holds after the sync
      seeds         a declared player-file row is written, which is how a shipped default reaches an
                    existing instance at all
      no intruders  nothing appears under an exact root that the manifest does not name
      idempotent    a second sync changes nothing. This is the one that would have caught the
                    .gitattributes byte rewrite as what it was - files redownloading on every
                    launch, for ever, without converging
#>
[CmdletBinding()]
param(
    [int] $Port = 29180,
    [switch] $KeepGameDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $repo 'PACK-VERSION.txt') -Raw).Trim()
$release = Join-Path (Split-Path -Parent $repo) "v.$version"
$site = Join-Path $repo 'site'
$packwiz = Join-Path $release '5. modpack source\auto-updater tools\packwiz.exe'
$javaPath = Join-Path $env:APPDATA 'PrismLauncher\java\java-runtime-epsilon\bin\java.exe'

foreach ($required in @($site, $packwiz, $javaPath, (Join-Path $site 'pack.toml'))) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing input: $required" }
}

function Get-Sha([string] $path) {
    return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-NormalizedSha([string] $path) {
    $text = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($path))
    $normalized = $text.Replace("`r`n", "`n").Replace("`r", "`n")
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes($normalized)))).Replace('-', '').ToLowerInvariant()
    }
    finally { $algorithm.Dispose() }
}

# Property rules are one key inside an otherwise player-owned file, so read that key the way the
# updater does rather than hashing the file.
function Get-PropertyValue([string] $path, [string] $key) {
    foreach ($line in [IO.File]::ReadAllLines($path)) {
        $trimmed = $line.Trim()
        if ($trimmed.StartsWith('#')) { continue }
        $separator = $trimmed.IndexOfAny(@(':', '='))
        if ($separator -lt 1) { continue }
        if ($trimmed.Substring(0, $separator).Trim() -ceq $key) {
            return $trimmed.Substring($separator + 1).Trim()
        }
    }
    return $null
}

$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
$testRoot = Join-Path $tempBase ('nbidal18-vp-sync-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$minecraft = Join-Path $testRoot 'minecraft'
$server = $null
$failures = [Collections.Generic.List[string]]::new()

function Assert([bool] $condition, [string] $message) {
    if (-not $condition) { $failures.Add($message) }
}

try {
    New-Item -ItemType Directory -Path $minecraft -Force | Out-Null

    $server = Start-Process -FilePath $packwiz -ArgumentList "serve --basic --port $Port" `
        -WorkingDirectory $site -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $testRoot 'serve.log') `
        -RedirectStandardError (Join-Path $testRoot 'serve.err')
    $ready = $false
    foreach ($attempt in 1..60) {
        if ($server.HasExited) { throw "The local server exited: $([IO.File]::ReadAllText((Join-Path $testRoot 'serve.err')))" }
        try {
            Invoke-WebRequest -Uri "http://127.0.0.1:$Port/pack.toml" -UseBasicParsing -TimeoutSec 1 | Out-Null
            $ready = $true; break
        }
        catch { Start-Sleep -Milliseconds 200 }
    }
    if (-not $ready) { throw "The local server never answered on port $Port" }
    Write-Host ("serving   site\\ on http://127.0.0.1:{0}" -f $Port)

    # The four tool jars a fresh instance starts with, exactly as the client ZIP delivers them.
    # Seeded from nbidal18-client.zip rather than by picking files, because that is literally what a
    # player imports - and it means this also proves the ZIP carries what a first install needs.
    # The .next copies matter: the supervisor promotes them before running anything and throws when
    # one is absent. An earlier draft copied only the four live jars and failed exactly there.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zipPath = Join-Path $site 'nbidal18-client.zip'
    if (-not (Test-Path -LiteralPath $zipPath)) { throw "Missing client ZIP: $zipPath" }
    $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
    $seeded = 0
    try {
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -notlike 'minecraft/*' -or $entry.FullName.EndsWith('/')) { continue }
            $target = Join-Path $minecraft $entry.FullName.Substring('minecraft/'.Length).Replace('/', [IO.Path]::DirectorySeparatorChar)
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
            $seeded++
        }
    }
    finally { $zip.Dispose() }
    Write-Host ("seeded    {0} files from nbidal18-client.zip" -f $seeded)

    $env:INST_MC_DIR = $minecraft
    $env:NBIDAL18_PACK_URL = "http://127.0.0.1:$Port/pack.toml"
    $env:NBIDAL18_MANIFEST_URL = "http://127.0.0.1:$Port/sync-manifest.json"
    $env:NBIDAL18_HEADLESS_TEST = '1'

    function Invoke-Sync([string] $label) {
        $previous = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $output = & $javaPath -jar (Join-Path $minecraft 'nbidal18-packwiz-sync.jar') 2>&1
        $code = $LASTEXITCODE
        $ErrorActionPreference = $previous
        if ($code -ne 0) {
            throw ("$label exited with $code`n" + (($output | Select-Object -Last 15) -join "`n"))
        }
        Write-Host ("{0,-9} completed" -f $label)
        return $output
    }

    # The retired-directory sweep deletes whole trees on a player's machine, so it is checked here
    # rather than trusted. Two must go - Voxy's LOD cache and Xaero's map images, both stale the
    # moment worldgen changes - and one must survive: the minimap folder holds the waypoints, which
    # are the single Xaero feature this pack kept.
    $sep = [IO.Path]::DirectorySeparatorChar
    $doomedVoxy = Join-Path $minecraft (@('.voxy', 'saves', '194.54.88.14_27107') -join $sep)
    $doomedMap = Join-Path $minecraft (@('xaero', 'world-map', 'Multiplayer_test', 'tiles') -join $sep)
    $keptWaypoints = Join-Path $minecraft (@('xaero', 'minimap', 'Multiplayer_test') -join $sep)
    foreach ($dir in @($doomedVoxy, $doomedMap, $keptWaypoints)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [IO.File]::WriteAllText((Join-Path $doomedVoxy 'lod.bin'), 'cache')
    [IO.File]::WriteAllText((Join-Path $doomedMap 'region.zip'), 'cache')
    $waypointFile = Join-Path $keptWaypoints 'waypoints.txt'
    [IO.File]::WriteAllText($waypointFile, "waypoint:Keep me:K:1:2:3")

    # Every marker the sweep has ever written, planted before the sync. A fresh instance cannot show
    # the failure that matters: these caches describe terrain, so they go stale every time the world
    # is regenerated, and the sweep is one-time per token. v1.0.23 cleared the world a second time
    # without bumping the token, so the sweep did nothing on every instance that already carried
    # v1.0.20's marker - which was all of them. Planting them here means the release either brings a
    # token no instance has seen or this fails.
    $stateDir = Join-Path $minecraft '.nbidal18-packwiz'
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    foreach ($old in @('retired-files-v1020')) {
        [IO.File]::WriteAllText((Join-Path $stateDir ("applied-" + $old)), $old)
    }

    $firstSync = Invoke-Sync 'sync 1'

    Assert (-not (Test-Path -LiteralPath (Join-Path $minecraft '.voxy'))) `
        "the retired-directory sweep left Voxy's LOD cache behind"
    Assert (-not (Test-Path -LiteralPath (Join-Path $minecraft (@('xaero', 'world-map') -join $sep)))) `
        "the retired-directory sweep left Xaero's map cache behind"
    Assert (Test-Path -LiteralPath $waypointFile) `
        'the retired-directory sweep deleted the Xaero waypoints, which it must never touch'

    # Deleting several gigabytes silently reads as a hang, so the sweep has to say what it is doing
    # by name. Asserted rather than assumed: a status line that quietly stops being emitted would
    # otherwise only show up as a player watching a frozen updater.
    $swept = @($firstSync | Where-Object { $_ -match "Clearing Voxy's far-terrain cache" })
    Assert ($swept.Count -gt 0) `
        'the sweep removed the caches without announcing it - the updater would look frozen'
    if ($swept.Count) { Write-Host ("retired   {0}" -f ($swept[0] -replace '^\[nbidal18 packwiz\] ', '')) }
    if ((Test-Path -LiteralPath $waypointFile) -and
        -not (Test-Path -LiteralPath (Join-Path $minecraft '.voxy'))) {
        Write-Host 'retired   Voxy and Xaero map caches removed, waypoints preserved'
    }

    $manifest = [IO.File]::ReadAllText((Join-Path $site 'sync-manifest.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
    $normalized = @{}
    foreach ($entry in $manifest.normalizedTextFiles) { $normalized[$entry.path] = $entry.sha256 }
    $localAllowed = @{}
    foreach ($path in $manifest.localAllowed) { $localAllowed[$path] = $true }

    # installs
    $missing = 0; $wrong = 0
    foreach ($entry in $manifest.files) {
        $local = Join-Path $minecraft $entry.path.Replace('/', '\')
        if (-not (Test-Path -LiteralPath $local -PathType Leaf)) { $missing++; continue }
        $expected = if ($normalized.ContainsKey($entry.path)) { $normalized[$entry.path] } else { $entry.sha256 }
        $actual = if ($normalized.ContainsKey($entry.path)) { Get-NormalizedSha $local } else { Get-Sha $local }
        if ($actual -ne $expected) { $wrong++ }
    }
    Assert ($missing -eq 0) "$missing managed files were not installed"
    Assert ($wrong -eq 0) "$wrong installed files do not match the hash the manifest records"
    Write-Host ("installed {0} managed files, {1} missing, {2} mismatched" -f $manifest.files.Count, $missing, $wrong)

    # preserves - a player-class file that is ALSO published must arrive on a first install. Being in
    # localAllowed alone does not imply publication: it means "never police this", and a file the
    # owning mod writes for itself is allowed without being shipped.
    $published = @{}
    foreach ($entry in $manifest.files) { $published[$entry.path] = $true }
    $shouldExist = @($manifest.localAllowed | Where-Object { $published.ContainsKey($_) })
    $preservedMissing = @($shouldExist | Where-Object {
            -not (Test-Path -LiteralPath (Join-Path $minecraft $_.Replace('/', '\')) -PathType Leaf)
        })
    Assert ($preservedMissing.Count -eq 0) ("player-class files not published on a first install: " + ($preservedMissing -join ', '))

    # Every localAllowed path must name a file that is either published or already on disk. The
    # updater matches this list exactly, so a path that names nothing is a file being enforced when
    # it should be preserved - which is how a mojibake section sign went unnoticed: the E-LITE shader
    # settings file was policed, and any player changing a shader option would have been refused at
    # login.
    $orphanAllowed = @($manifest.localAllowed | Where-Object {
            -not $published.ContainsKey($_) -and
            -not (Test-Path -LiteralPath (Join-Path $minecraft $_.Replace('/', '\')) -PathType Leaf)
        })
    Assert ($orphanAllowed.Count -eq 0) ("localAllowed names paths that are neither published nor present - look for an encoding mismatch: " + ($orphanAllowed -join ', '))
    Write-Host ("preserved {0} of {1} player-class paths, {2} orphaned" -f `
            ($shouldExist.Count - $preservedMissing.Count), $manifest.localAllowed.Count, $orphanAllowed.Count)

    # pins
    $badPins = [Collections.Generic.List[string]]::new()
    foreach ($rule in $manifest.propertyRules) {
        $target = Join-Path $minecraft $rule.path.Replace('/', '\')
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { $badPins.Add("$($rule.path) missing"); continue }
        $value = Get-PropertyValue $target $rule.key
        if ($value -ne $rule.value) { $badPins.Add("$($rule.path)#$($rule.key) = $value, expected $($rule.value)") }
    }
    Assert ($badPins.Count -eq 0) ("property rules not applied: " + ($badPins -join '; '))
    Write-Host ("pinned    {0} property rules hold" -f $manifest.propertyRules.Count)

    # seeds - a flat file the updater creates from nothing when it is absent
    $options = Join-Path $minecraft 'options.txt'
    Assert (Test-Path -LiteralPath $options -PathType Leaf) 'the seed did not create options.txt'
    if (Test-Path -LiteralPath $options -PathType Leaf) {
        $packsRow = Get-PropertyValue $options 'resourcePacks'
        Assert ($null -ne $packsRow -and $packsRow.StartsWith('[')) 'the resourcePacks row was not seeded'
        Write-Host 'seeded    options.txt carries the declared rows'
    }

    # no intruders
    $managed = @{}
    foreach ($entry in $manifest.files) { $managed[$entry.path.ToLowerInvariant()] = $true }
    foreach ($path in $manifest.localAllowed) { $managed[$path.ToLowerInvariant()] = $true }
    $extra = [Collections.Generic.List[string]]::new()
    foreach ($root in $manifest.exactRoots) {
        if ($manifest.extraTolerantRoots -contains $root) { continue }
        $rootPath = Join-Path $minecraft $root
        if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) { continue }
        foreach ($file in Get-ChildItem -LiteralPath $rootPath -Recurse -File -Force) {
            $relative = $file.FullName.Substring($minecraft.Length).TrimStart('\').Replace('\', '/')
            if (-not $managed.ContainsKey($relative.ToLowerInvariant())) { $extra.Add($relative) }
        }
    }
    Assert ($extra.Count -eq 0) ("files under an exact root that the manifest does not name: " + ($extra -join ', '))
    Write-Host ("intruders {0}" -f $extra.Count)

    # idempotent
    $before = @{}
    foreach ($entry in $manifest.files) {
        $local = Join-Path $minecraft $entry.path.Replace('/', '\')
        if (Test-Path -LiteralPath $local -PathType Leaf) {
            $before[$entry.path] = (Get-Item -LiteralPath $local).LastWriteTimeUtc
        }
    }
    Invoke-Sync 'sync 2' | Out-Null
    $rewritten = [Collections.Generic.List[string]]::new()
    foreach ($path in $before.Keys) {
        $local = Join-Path $minecraft $path.Replace('/', '\')
        if ((Test-Path -LiteralPath $local -PathType Leaf) -and
            (Get-Item -LiteralPath $local).LastWriteTimeUtc -ne $before[$path]) {
            $rewritten.Add($path)
        }
    }
    Assert ($rewritten.Count -eq 0) ("a second sync rewrote {0} files that had not changed - they would redownload on every launch: {1}" -f `
            $rewritten.Count, (($rewritten | Select-Object -First 8) -join ', '))
    Write-Host ("idempotent {0} files rewritten by a second sync" -f $rewritten.Count)

    $stamp = Join-Path $minecraft '.nbidal18-packwiz\last-successful-manifest.json'
    Assert (Test-Path -LiteralPath $stamp -PathType Leaf) 'no successful-sync stamp was written'
    if (Test-Path -LiteralPath $stamp -PathType Leaf) {
        $installed = ([IO.File]::ReadAllText($stamp, [Text.Encoding]::UTF8) | ConvertFrom-Json).packVersion
        Assert ($installed -eq $manifest.packVersion) "the stamp says $installed but the build is $($manifest.packVersion)"
    }

    if ($failures.Count) { throw ("Local sync check failed:`n  " + ($failures -join "`n  ")) }
    Write-Host ''
    Write-Host ("OK        the updater installs, preserves, pins, seeds and converges on v{0}" -f $version)
}
finally {
    if ($server -and -not $server.HasExited) { $server.Kill(); $server.WaitForExit(10000) | Out-Null }
    if ($server) { $server.Dispose() }
    Remove-Item Env:INST_MC_DIR, Env:NBIDAL18_PACK_URL, Env:NBIDAL18_MANIFEST_URL, Env:NBIDAL18_HEADLESS_TEST -ErrorAction SilentlyContinue
    $resolved = [IO.Path]::GetFullPath($testRoot)
    if (-not $KeepGameDir -and $resolved.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $resolved)) {
        Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue
    }
}

exit 0
