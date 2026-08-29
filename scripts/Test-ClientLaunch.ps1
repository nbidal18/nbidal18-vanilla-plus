<#
    Starts a real client against a throwaway game directory, waits for the title screen, and then
    reads the log for the faults that have actually shipped from this pack.

      scripts\Test-ClientLaunch.ps1
      scripts\Test-ClientLaunch.ps1 -KeepGameDir     leave the directory for inspection

    Ported from the 1.21.1 pack, which wrote it after v4.2.3 and v4.2.4 both shipped a client that
    could not start. This line has not had that failure - but it has had three of a different kind,
    and all three were in the log the whole time while nobody read it:

      v1.0.6  a resource pack's core item shader blanked every inventory slot, and the game said
              "shader program does not use sampler Sampler1" on every load
      v1.0.7  a pack's models rendered untextured, and the game said "Missing texture references"
      v1.0.10 nbidal18-invmov did nothing at all, and the tell was a line that never appeared

    So this checks two things: that the client reaches the title screen, and that the log does not
    contain a pattern that has previously cost a release.

    Nothing here touches the real Prism instance. The classpath is rebuilt from Prism's own metadata,
    so the launcher does not need to be running and the libraries are exactly the ones players get.

    The integrity helper is removed from the throwaway copy: it enforces the published channel and
    the Prism instance layout, neither of which exists here, and it refuses before the main menu when
    they are missing. Verify-PublishedChannel covers what it would have checked.

    Mixins apply on class load, so reaching the title screen proves every mixin targeting a class
    loaded during startup. A mixin into a screen that opens later still needs a play-test.
#>
[CmdletBinding()]
param(
    [int] $BootTimeoutSeconds = 300,
    [string] $InstanceName = 'nbidal18-vanilla-plus-client',
    [switch] $KeepGameDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The client keeps latest.log open while it runs, so a plain read fails with a sharing violation.
function Read-SharedText([string] $path) {
    $stream = [IO.FileStream]::new($path, [IO.FileMode]::Open, [IO.FileAccess]::Read,
        [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete)
    try {
        $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8)
        try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
    }
    finally { $stream.Dispose() }
}

# group:artifact:version[:classifier] -> the path Prism stores it at.
function Resolve-MavenPath([string] $prismRoot, [string] $coord) {
    $parts = $coord -split ':'
    $groupPath = ($parts[0] -replace '\.', '\')
    $fileName = if ($parts.Count -ge 4) { "$($parts[1])-$($parts[2])-$($parts[3]).jar" }
    else { "$($parts[1])-$($parts[2]).jar" }
    return Join-Path $prismRoot "libraries\$groupPath\$($parts[1])\$($parts[2])\$fileName"
}

$repo = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $repo 'PACK-VERSION.txt') -Raw).Trim()
$release = Join-Path (Split-Path -Parent $repo) "v.$version"
$clientSource = Join-Path $release '3. modpack\client'
$mcVersion = (Get-Content -LiteralPath (Join-Path $repo 'MINECRAFT.txt') -Raw).Trim()
$prismRoot = Join-Path $env:APPDATA 'PrismLauncher'
$instanceRoot = Join-Path $prismRoot "instances\$InstanceName"
$javaPath = Join-Path $prismRoot 'java\java-runtime-epsilon\bin\java.exe'

foreach ($required in @($clientSource, $prismRoot, $instanceRoot, $javaPath)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing input: $required" }
}

# ---------------------------------------------------------------- classpath, from Prism's metadata
$classpath = [Collections.Generic.List[string]]::new()
$mainClass = $null
$assetIndex = $null
$pack = Get-Content -LiteralPath (Join-Path $instanceRoot 'mmc-pack.json') -Raw | ConvertFrom-Json
foreach ($component in $pack.components) {
    $metaFile = Join-Path $prismRoot "meta\$($component.uid)\$($component.version).json"
    if (-not (Test-Path -LiteralPath $metaFile)) { continue }
    $meta = Get-Content -LiteralPath $metaFile -Raw | ConvertFrom-Json
    $names = $meta.PSObject.Properties.Name
    if (($names -contains 'mainClass') -and $meta.mainClass) { $mainClass = $meta.mainClass }
    if (($names -contains 'assetIndex') -and $meta.assetIndex) { $assetIndex = $meta.assetIndex.id }
    $coords = @()
    if (($names -contains 'mainJar') -and $meta.mainJar) { $coords += $meta.mainJar.name }
    if (($names -contains 'libraries') -and $meta.libraries) { $coords += $meta.libraries.name }
    foreach ($coord in $coords) {
        # LWJGL declares natives for every platform; Prism downloads only this one, so whether the
        # file exists is a better filter than reimplementing Prism's rule engine.
        if ($coord -match 'natives-(linux|macos)') { continue }
        $path = Resolve-MavenPath $prismRoot $coord
        if ((Test-Path -LiteralPath $path -PathType Leaf) -and -not $classpath.Contains($path)) {
            $classpath.Add($path)
        }
    }
}
if (-not $mainClass) { throw 'No mainClass in the Prism component metadata.' }
if (-not $assetIndex) { throw 'No assetIndex in the Prism component metadata.' }
if ($classpath.Count -eq 0) { throw 'The classpath resolved to nothing.' }

# ---------------------------------------------------------------- patterns that have cost a release
#
# Curated, not "every warning". This pack logs plenty of benign noise - Overlay's uses a `layer`
# value 26.2 dropped, Continuity references sprites a pack does not ship - and failing on all of it
# would make the check cry wolf until nobody ran it, which is how Verify-PublishedChannel nearly
# went wrong. Each entry below is a fault that actually reached players.
$fatalPatterns = @(
    @{ Name = 'core shader incompatible with the pipeline'
        Pattern = 'shader program does not use sampler'
        Note = 'a resource pack is overriding shaders/core for a different game version (v1.0.6)' }
    @{ Name = 'model with unresolved textures'
        Pattern = 'Missing texture references in model'
        Note = 'a resource pack ships models whose texture variables are undefined (v1.0.7)' }
    @{ Name = 'malformed JSON in a resource pack'
        Pattern = 'MalformedJsonException'
        Note = 'a pack ships JSON the game cannot parse and silently drops (v1.0.7)' }
    @{ Name = 'invalid namespace in a resource pack'
        Pattern = 'Non \[a-z0-9_\.-\] character in namespace'
        Note = 'a pack ships a folder name Minecraft rejects outright (v1.0.7)' }
)

# Lines that must be present. An absent line is the hardest failure to notice: nbidal18-invmov
# shipped doing nothing while everything that could report success did.
#
# Only lines that a client reaching the TITLE SCREEN can actually produce belong here. "JEI runtime
# captured" does not: JEI publishes its runtime once a world loads, so requiring it failed a
# perfectly healthy client on this check's first run. What guards that path instead is the mod's own
# startup error if its jei_mod_plugin entrypoint is missing, plus build_invmov.py refusing to
# package a jar whose declared entrypoints are not all present.
$requiredLines = @(
    @{ Name = 'InvMove bridge registered'; Pattern = 'Registered the JEI search module with InvMove' }
)

$mixinFailure = '(?m)(org\.spongepowered\.asm\.mixin\..*throwables\.|Mixin apply failed|' +
'MixinApplyError|MixinTransformerError|Critical injection failure|Mixin transformation of .* failed)'

# Short path on purpose: the deepest datapack file passes MAX_PATH from a longer root.
$testRoot = Join-Path ([IO.Path]::GetTempPath()) 'nbidal18-vp-launch'

try {
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
    New-Item -ItemType Directory -Path $testRoot | Out-Null

    foreach ($directory in @('mods', 'config', 'datapacks', 'resourcepacks', 'shaderpacks')) {
        $source = Join-Path $clientSource $directory
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $testRoot $directory) -Recurse -Force
        }
    }
    foreach ($drop in Get-ChildItem -LiteralPath (Join-Path $testRoot 'mods') -File -Filter 'nbidal18-integrity-*.jar') {
        Remove-Item -LiteralPath $drop.FullName -Force
    }
    $stagedMods = @(Get-ChildItem -LiteralPath (Join-Path $testRoot 'mods') -File -Filter '*.jar').Count
    Write-Host ("staging   {0} mods into {1}" -f $stagedMods, $testRoot)

    $arguments = @(
        '-Xms512m', '-Xmx2048m',
        '-cp', ($classpath -join ';'),
        $mainClass,
        '--username', 'LaunchCheck',
        '--version', $mcVersion,
        '--gameDir', $testRoot,
        '--assetsDir', (Join-Path $prismRoot 'assets'),
        '--assetIndex', $assetIndex,
        '--uuid', '00000000000000000000000000000000',
        '--accessToken', '0',
        '--userType', 'legacy',
        '--versionType', 'release'
    )

    # WorkingDirectory matters as much as --gameDir: several mods write relative to the process
    # working directory, and launching from the checkout once scattered files through the repo.
    $client = Start-Process -FilePath $javaPath -ArgumentList $arguments -PassThru `
        -WorkingDirectory $testRoot -WindowStyle Minimized `
        -RedirectStandardOutput (Join-Path $testRoot 'stdout.txt') `
        -RedirectStandardError (Join-Path $testRoot 'stderr.txt')

    $logPath = Join-Path $testRoot 'logs\latest.log'
    try {
        $deadline = (Get-Date).AddSeconds($BootTimeoutSeconds)
        $reachedMenu = $false
        while ((Get-Date) -lt $deadline -and -not $client.HasExited) {
            if (Test-Path -LiteralPath $logPath -PathType Leaf) {
                # Logged once the client is fully initialised, just before the title screen draws.
                if ((Read-SharedText $logPath) -match 'Sound engine started') { $reachedMenu = $true; break }
            }
            # No early exit on a mixin line: Mixin logs recoverable throwables during startup, and
            # aborting on the first one failed healthy clients. A fatal one kills the process, which
            # HasExited above already catches.
            Start-Sleep -Milliseconds 1000
        }

        $log = if (Test-Path -LiteralPath $logPath -PathType Leaf) { Read-SharedText $logPath } else { '' }
        $lines = $log -split "`r?`n"
        $mixinLines = @($lines | Where-Object { $_ -match $mixinFailure })

        if (-not $reachedMenu) {
            $crash = @(Get-ChildItem -LiteralPath (Join-Path $testRoot 'crash-reports') -File -ErrorAction SilentlyContinue)
            $detail = if ($mixinLines.Count) { "`nMixin trouble, most likely the cause:`n" + (($mixinLines | Select-Object -First 10) -join "`n") }
            elseif ($crash.Count) { "`nCrash report: $($crash[0].FullName)" }
            else { "`nLog: $logPath" }
            throw "The client never reached the title screen within $BootTimeoutSeconds seconds.$detail"
        }
        Write-Host ("launch    title screen reached, {0} mods loaded" -f $stagedMods)

        $failures = New-Object Collections.Generic.List[string]
        foreach ($check in $fatalPatterns) {
            $hits = @($lines | Where-Object { $_ -match $check.Pattern } | Select-Object -Unique)
            if ($hits.Count) {
                $failures.Add(("{0} ({1} lines) - {2}`n    {3}" -f $check.Name, $hits.Count, $check.Note,
                    (($hits | Select-Object -First 3) -join "`n    ")))
            }
        }
        foreach ($check in $requiredLines) {
            if ($log -notmatch $check.Pattern) {
                $failures.Add(("expected log line never appeared: {0} (/{1}/)" -f $check.Name, $check.Pattern))
            }
            else { Write-Host ("present   {0}" -f $check.Name) }
        }

        if ($mixinLines.Count) {
            Write-Warning ("Mixin logged and recovered from these. A mixin that quietly did not " +
                "apply is still a broken feature:`n" + (($mixinLines | Select-Object -First 10) -join "`n"))
        }
        if ($failures.Count) {
            throw ("The client started, but the log contains faults that have shipped before:`n`n" +
                ($failures -join "`n`n"))
        }
        Write-Host ''
        Write-Host 'OK        title screen reached and no known-bad pattern in the log'
    }
    finally {
        if (-not $client.HasExited) { $client.Kill(); $client.WaitForExit(30000) | Out-Null }
        $client.Dispose()
    }
}
finally {
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $KeepGameDir -and $resolved.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $resolved)) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
