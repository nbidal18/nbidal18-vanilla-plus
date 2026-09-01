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
    [switch] $KeepGameDir,
    # Leave the client running at the title screen instead of killing it, and keep the game
    # directory. For looking at something that only exists on screen - a GUI, a model, a shader -
    # which no log line can confirm.
    #
    # It exists because the alternative was cutting a release per attempt. The updater keeps
    # resourcepacks exact-match, so a candidate pack dropped into the real instance is deleted
    # before the game starts; this directory has no updater and no integrity helper.
    [switch] $Hold,
    # Copy these files over the staged resourcepacks folder, by name, after staging. A candidate
    # fork of a pack the release already ships replaces the shipped one.
    [string[]] $ReplacePack = @(),
    # A saves folder to restore into the throwaway instance, so a run can start inside a world.
    # Container GUIs, held items and anything else that only exists in game cannot be reached from
    # the title screen, and creating a world by hand every run made that a person's job.
    [string] $World,
    # Load straight into this level and skip the menus. Needs -World.
    [string] $QuickPlay
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
        Note = 'a resource pack ships models whose texture variables are undefined (v1.0.7)'
        # Traveler's Backpack ships its backpack geometry as loose Blockbench sources under
        # models/block/. Measured against the jar rather than assumed: of 89 models there, 76 are
        # referenced by a blockstate, item model or parent chain and 13 are not - and every one of
        # the 13 is a backpack_* file, while not one referenced model starts with backpack_. The
        # mod's renderer loads that geometry itself, so nothing goes through the model registry and
        # nothing renders untextured; the loader simply parses every file in the folder and warns.
        #
        # The v1.0.7 fault this pattern exists for was the opposite case - models that were in use
        # and untextured - so the check stays live for every other model, including the other 76.
        Except = 'travelersbackpack:block/backpack_' }
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
    # Matches both module names, so losing either one fails here rather than shipping a bridge that
    # loads and does half its job. v1.0.10's did exactly that with the JEI half.
    @{ Name = 'InvMove bridge registered'
        Pattern = 'Registered the JEI search and allow-movement modules with InvMove' }
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

    foreach ($candidate in $ReplacePack) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { throw "-ReplacePack: no file at $candidate" }
        $dest = Join-Path (Join-Path $testRoot 'resourcepacks') (Split-Path $candidate -Leaf)
        $verb = if (Test-Path -LiteralPath $dest) { 'replaced' } else { 'added   ' }
        Copy-Item -LiteralPath $candidate -Destination $dest -Force
        Write-Host ("{0}  {1}" -f $verb, (Split-Path $candidate -Leaf))
    }

    # The staged instance has no options.txt, so the game would boot with every pack switched off
    # and prove nothing about how they look. Both rows are copied from the release, which is what
    # the updater seeds onto a player's instance.
    if ($World) {
        if (-not (Test-Path -LiteralPath $World -PathType Container)) { throw "-World: no folder at $World" }
        Copy-Item -LiteralPath $World -Destination (Join-Path $testRoot 'saves') -Recurse -Force
        Write-Host ("world     restored {0}" -f ((Get-ChildItem -LiteralPath $World -Directory | ForEach-Object { $_.Name }) -join ', '))
    }

    $releaseOptions = Join-Path $clientSource 'options.txt'
    if ($Hold -and (Test-Path -LiteralPath $releaseOptions -PathType Leaf)) {
        $rows = ([IO.File]::ReadAllText($releaseOptions) -split "`r?`n") |
            Where-Object { $_ -match '^(resourcePacks|incompatibleResourcePacks):' }
        [IO.File]::WriteAllText((Join-Path $testRoot 'options.txt'), (($rows -join "`n") + "`n"),
            (New-Object Text.UTF8Encoding($false)))
        Write-Host ("seeded    options.txt with {0} pack rows from the release" -f $rows.Count)
    }

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
    if ($QuickPlay) { $arguments += @('--quickPlaySingleplayer', $QuickPlay) }

    # WorkingDirectory matters as much as --gameDir: several mods write relative to the process
    # working directory, and launching from the checkout once scattered files through the repo.
    # Minimized for a pass/fail run, on screen for -Hold: the whole point of Hold is to look at it.
    $client = Start-Process -FilePath $javaPath -ArgumentList $arguments -PassThru `
        -WorkingDirectory $testRoot -WindowStyle $(if ($Hold) { 'Normal' } else { 'Minimized' }) `
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
            # An exemption is per-line and per-pattern, so the check stays live for everything else.
            if ($check.ContainsKey('Except')) {
                $hits = @($hits | Where-Object { $_ -notmatch $check.Except })
            }
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
            # -Hold is for looking at something on screen, and it deliberately turns the resource
            # packs on, which is when most of these fire. Reporting them is useful; throwing would
            # kill the client the run exists to leave open.
            if ($Hold) {
                Write-Warning ("Faults in the log, reported rather than fatal because -Hold:`n`n" +
                    ($failures -join "`n`n"))
            }
            else {
                throw ("The client started, but the log contains faults that have shipped before:`n`n" +
                    ($failures -join "`n`n"))
            }
        }
        Write-Host ''
        Write-Host 'OK        title screen reached and no known-bad pattern in the log'
    }
    finally {
        if ($Hold -and -not $client.HasExited) {
            Write-Host ''
            Write-Host 'HOLD      the client is open and left running. Close it yourself when done.'
            Write-Host '          Create a creative world to look at containers - this directory is'
            Write-Host '          a throwaway and nothing in it reaches your real instance.'
        }
        elseif (-not $client.HasExited) { $client.Kill(); $client.WaitForExit(30000) | Out-Null }
        if (-not $Hold) { $client.Dispose() }
    }
}
finally {
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $KeepGameDir -and -not $Hold -and
        $resolved.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $resolved)) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
