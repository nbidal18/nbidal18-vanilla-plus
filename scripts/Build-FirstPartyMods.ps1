<#
    Compiles and packages every first-party mod into the current release.

      scripts\Build-FirstPartyMods.ps1                       all of them
      scripts\Build-FirstPartyMods.ps1 -Only nbidal18-invmov just that one

    This used to live inside New-Release, which meant a first-party mod could only be rebuilt by
    cutting a version. Editing one line of a mixin and getting it into the release you are already
    working in was impossible - the workaround was to cut another release, which burns a version
    number for nothing, or to build the jar by hand, which is how stale jars get shipped.

    The classpath is built from Prism's own metadata plus the mods the release is about to ship, so
    a first-party mod compiles against what it will run beside rather than against whatever is
    installed on this machine today. Fabric API's ~190 nested jars are expanded one level, because
    javac cannot see into a jar-in-jar and every fabric.api import would otherwise fail.

    Each mod is a folder under `5. modpack source\custom mods\` with `src\*.java` and a Python
    builder that takes the compiled-classes directory and writes the jar. A mod may also have a
    generator that runs first - the integrity helper's source is generated from the pack version.
#>
[CmdletBinding()]
param(
    [string] $ReleaseRoot,
    [string] $InstanceName = 'nbidal18-vanilla-plus-client',
    [string[]] $Only
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $repo 'PACK-VERSION.txt') -Raw).Trim()
if (-not $ReleaseRoot) { $ReleaseRoot = Join-Path (Split-Path -Parent $repo) "v.$version" }
if (-not (Test-Path -LiteralPath $ReleaseRoot)) { throw "No release folder at $ReleaseRoot" }

# Each entry: folder name, optional generator, builder. Order matters only in that the integrity
# helper is the one that can lock players out, so it is built first and fails loudest.
$mods = @(
    @{ Name = 'nbidal18-integrity'; Generator = 'port_integrity.py'; Builder = 'build_integrity.py' },
    @{ Name = 'nbidal18-invmov'; Generator = $null; Builder = 'build_invmov.py' },
    @{ Name = 'nbidal18-hardcorerevive'; Generator = $null; Builder = 'patch_hcrplus.py' },
    @{ Name = 'nbidal18-xaerominimap'; Generator = $null; Builder = 'build_xaerominimap.py' },
    @{ Name = 'nbidal18-xaeroworldmap'; Generator = $null; Builder = 'build_xaeroworldmap.py' },
    @{ Name = 'nbidal18-betterfishing'; Generator = $null; Builder = 'patch_betterfishing.py' },
    # Neutralises BOTH PostHog clients this mod ships - its own, and the one inside the bundled
    # meza_core library. meza's is the one that mattered: PostHog's sender thread is non-daemon, so
    # the JVM could not exit and Minecraft's watchdog halted it 15 seconds later, which is a
    # non-zero exit and why Prism opened its console on every quit. A thread dump names the culprit
    # in one line; two releases were spent guessing before anyone took one. Drop this fork the
    # moment upstream calls its own Telemetry.shutdown().
    @{ Name = 'nbidal18-soundsbegone'; Generator = $null; Builder = 'build_soundsbegone.py' },
    # skin_overrides schedules three fixed-rate tasks on a pool with no thread factory, so its
    # threads are non-daemon: the JVM could not exit and the watchdog halted it 15 seconds later.
    # Its own cleanup hangs off Util.shutdownExecutors(), which 26.2 no longer reaches on that path,
    # so this makes the threads daemon instead - correct whenever cleanup runs, or does not.
    @{ Name = 'nbidal18-skinoverrides'; Generator = $null; Builder = 'build_skinoverrides.py' },
    # Mouse Wheelie's InteractionManager constructs a ScheduledThreadPoolExecutor in <clinit>
    # with no thread factory, so non-daemon, and schedules a fixed-rate tick that never ends and
    # is never shut down. Second of the two threads that stopped the client exiting.
    @{ Name = 'nbidal18-mousewheelie'; Generator = $null; Builder = 'build_mousewheelie.py' },
    # Ctrl+Alt+W holds the forward key down until the back key cancels it. First-party content
    # rather than a fork - it patches nothing, so it has no target to be named for. It holds the
    # key and not the movement input, which is what makes it work for boats, horses and Immersive
    # Aircraft rather than only for walking.
    @{ Name = 'nbidal18-autopilot'; Generator = $null; Builder = 'build_autopilot.py' },
    # Reliable Gliders has no dimension setting, so without this the Nether is the easiest place in
    # the pack to cross rather than the hardest. Sets a gliding player on fire there. No mixin - the
    # mod exposes GlidingState.isGliding(Player) as public static API. **Runs on the server too**,
    # so it needs -AddMods on the release that publishes it.
    @{ Name = 'nbidal18-reliablegliders'; Generator = $null; Builder = 'build_reliablegliders.py' },
    # Carry On poses a carrying player with two hands, and EMF draws the Fresh Animations Player
    # Extended pose straight over the top of it, so the block appears to float. This registers a
    # pause condition with EMF - asking to be asked - rather than pushing a pause in and taking it
    # back out, which is what the 1.21.1 equivalent did and why that one needed a ledger to avoid
    # leaving a disconnected player's animations stuck. Client only.
    @{ Name = 'nbidal18-carryon'; Generator = $null; Builder = 'build_carryon.py' },
    # Voxy World Gen's client silently discards incoming LOD payloads when its ingest queue
    # overruns, while the server has already recorded them as delivered - a permanent hole, and not
    # a rare one: the client takes 96 sections a tick and any backfill overruns the queue within a
    # minute. This drops the farthest payload instead of the nearest, remembers it, and asks the
    # server to resend once the client has caught up. **It runs on the server too** - it adds a
    # packet - so it needs -AddMods on the release that publishes it.
    @{ Name = 'nbidal18-voxyworldgen'; Generator = $null; Builder = 'build_voxyworldgen.py' },
    # Sparse Structures records every structure set in one static TreeSet, filled from 26.2's
    # PARALLEL registry loader. A TreeSet cannot take concurrent writes: the tree corrupts and the
    # next insert throws, killing the server at boot with a NullPointerException naming whichever
    # mod was mid-insert - Incendium, in the one observed crash, which is innocent. Reproduced from
    # eight threads against the real class; fails on the first round. This serialises the writes.
    # The list only feeds a debug dump command, so there is no gameplay behaviour either way.
    # **Runs on the server too** - it is a server boot crash - so it needs -AddMods to deploy.
    @{ Name = 'nbidal18-sparsestructures'; Generator = $null; Builder = 'build_sparsestructures.py' },

    # nbidal18-travelersbackpack is deliberately NOT built. Its source stays under `custom mods\`
    # because the work is sound and will be picked up again, but a uniform tint is not what
    # Recolourful does - it recolours a panel region by region - so shipping it looked unfinished
    # next to the vanilla containers rather than matching them. Re-add this line to revive it.
    # Data only - no src\, so no javac. Its builder reads the vanilla loot table out of the game jar
    # and edits it, which is why it needs no classpath either.
    @{ Name = 'nbidal18-tectonic'; Generator = $null; Builder = 'build_tectonic.py' }
)
if ($Only) {
    $mods = @($mods | Where-Object { $Only -contains $_.Name })
    if ($mods.Count -eq 0) { throw "No first-party mod matches: $($Only -join ', ')" }
}

# ---------------------------------------------------------------- classpath, from Prism's metadata
function Resolve-MavenPath([string] $prismRoot, [string] $coord) {
    $parts = $coord -split ':'
    $groupPath = ($parts[0] -replace '\.', '\')
    $fileName = if ($parts.Count -ge 4) { "$($parts[1])-$($parts[2])-$($parts[3]).jar" }
    else { "$($parts[1])-$($parts[2]).jar" }
    return Join-Path $prismRoot "libraries\$groupPath\$($parts[1])\$($parts[2])\$fileName"
}

$prismRoot = Join-Path $env:APPDATA 'PrismLauncher'
$instanceRoot = Join-Path $prismRoot "instances\$InstanceName"
$javaBin = Join-Path $prismRoot 'java\java-runtime-epsilon\bin'
$javac = Join-Path $javaBin 'javac.exe'
foreach ($required in @($instanceRoot, $javac)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing build input: $required" }
}

$releaseMods = Join-Path $ReleaseRoot '3. modpack\client\mods'
$classpath = [Collections.Generic.List[string]]::new()
$pack = Get-Content -LiteralPath (Join-Path $instanceRoot 'mmc-pack.json') -Raw | ConvertFrom-Json
foreach ($component in $pack.components) {
    $metaFile = Join-Path $prismRoot "meta\$($component.uid)\$($component.version).json"
    if (-not (Test-Path -LiteralPath $metaFile)) { continue }
    $meta = Get-Content -LiteralPath $metaFile -Raw | ConvertFrom-Json
    $names = $meta.PSObject.Properties.Name
    $coords = @()
    if (($names -contains 'mainJar') -and $meta.mainJar) { $coords += $meta.mainJar.name }
    if (($names -contains 'libraries') -and $meta.libraries) { $coords += $meta.libraries.name }
    foreach ($coord in $coords) {
        if ($coord -match 'natives-(linux|macos)') { continue }
        $path = Resolve-MavenPath $prismRoot $coord
        if ((Test-Path -LiteralPath $path -PathType Leaf) -and -not $classpath.Contains($path)) {
            $classpath.Add($path)
        }
    }
}
foreach ($jar in Get-ChildItem -LiteralPath $releaseMods -Filter *.jar) {
    if ($jar.Name -like 'nbidal18-*') { continue }
    $classpath.Add($jar.FullName)
}
# A fork compiles against the upstream jar it patches, which by then has been replaced in mods\ by
# the fork itself - so the original is kept in the mod's own dl\ and added here. Without this a
# fork can only be built once, and never rebuilt.
$customModsRoot = Join-Path $ReleaseRoot '5. modpack source\custom mods'
if (Test-Path -LiteralPath $customModsRoot) {
    foreach ($jar in Get-ChildItem -LiteralPath $customModsRoot -Recurse -Filter *.jar -File |
        Where-Object { $_.Directory.Name -eq 'dl' }) {
        if (-not $classpath.Contains($jar.FullName)) { $classpath.Add($jar.FullName) }
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$jijRoot = Join-Path ([IO.Path]::GetTempPath()) 'nbidal18-jij'
if (Test-Path -LiteralPath $jijRoot) { Remove-Item -LiteralPath $jijRoot -Recurse -Force }
New-Item -ItemType Directory -Path $jijRoot | Out-Null
$nested = 0
try {
    foreach ($jar in Get-ChildItem -LiteralPath $releaseMods -Filter *.jar) {
        $archive = [IO.Compression.ZipFile]::OpenRead($jar.FullName)
        try {
            foreach ($entry in $archive.Entries) {
                if ($entry.FullName -notlike 'META-INF/jars/*.jar') { continue }
                $target = Join-Path $jijRoot ($jar.BaseName + '__' + (Split-Path $entry.FullName -Leaf))
                if (-not (Test-Path -LiteralPath $target)) {
                    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
                }
                if (-not $classpath.Contains($target)) { $classpath.Add($target); $nested++ }
            }
        }
        finally { $archive.Dispose() }
    }

    if ($classpath.Count -eq 0) { throw 'The classpath resolved to nothing.' }
    Write-Host ("release   {0}" -f $ReleaseRoot)
    Write-Host ("classpath {0} jars ({1} nested inside other mods)" -f $classpath.Count, $nested)

    $customMods = Join-Path $ReleaseRoot '5. modpack source\custom mods'

    foreach ($mod in $mods) {
        $name = $mod.Name
        $modRoot = Join-Path $customMods $name
        if (-not (Test-Path -LiteralPath $modRoot)) { throw "No source for $name at $modRoot" }

        if ($mod.Generator) {
            Push-Location $modRoot
            try {
                & python $mod.Generator | Out-Null
                if ($LASTEXITCODE -ne 0) { throw "$($mod.Generator) failed for $name" }
            }
            finally { Pop-Location }
        }

        # A first-party artefact may be data only - a loot table or a datapack override with no Java
        # at all. Those skip the compile entirely rather than being made to carry an empty src\.
        # Assigned in two statements, not as an if-expression: under StrictMode the empty branch
        # yields $null rather than an empty array, and $sources.Count then throws.
        $srcRoot = Join-Path $modRoot 'src'
        $sources = @()
        if (Test-Path -LiteralPath $srcRoot) {
            $sources = @(Get-ChildItem -LiteralPath $srcRoot -Recurse -Filter *.java)
        }
        if ((Test-Path -LiteralPath $srcRoot) -and $sources.Count -eq 0) {
            throw "$modRoot has a src\ directory but no .java in it"
        }
        if ($sources.Count -eq 0) {
            Push-Location $modRoot
            try {
                & python $mod.Builder
                if ($LASTEXITCODE -ne 0) { throw "$($mod.Builder) failed for $name" }
            }
            finally { Pop-Location }
            continue
        }
        $out = Join-Path ([IO.Path]::GetTempPath()) "nbidal18-build-$name"
        if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Recurse -Force }
        New-Item -ItemType Directory -Path $out | Out-Null

        # An @argfile carrying BOTH the classpath and the sources. Fabric API alone contributes ~190
        # nested jars, and passing that on the command line fails with "the filename or extension is
        # too long" before javac ever starts.
        #
        # Forward slashes throughout: javac's argfile parser treats a backslash inside a quoted
        # string as an escape, so a Windows path written literally is silently mangled. Quoted
        # because the release path contains spaces.
        $argFile = Join-Path $out 'javac-args.txt'
        $fwd = [char]47
        $bsl = [char]92
        $argLines = @('-cp', ('"' + ($classpath -join ';').Replace($bsl, $fwd) + '"'))
        $argLines += $sources | ForEach-Object { '"' + $_.FullName.Replace($bsl, $fwd) + '"' }
        [IO.File]::WriteAllText($argFile, ($argLines -join "`n"), (New-Object Text.UTF8Encoding($false)))

        # -Werror on purpose. The 1.21.1 build once packaged a 776-byte jar from a failed compile
        # because nothing checked the exit code; this refuses to reach the packaging step at all.
        #
        # -classfile  Minecraft's own @Contract annotations warn on every build
        # -serial     a checked exception without a serialVersionUID is not a defect here
        # -path       a mod's manifest Class-Path names sibling jars this pack does not ship, so
        #             javac reports "bad path element" for jars nothing needs. That is a fact about
        #             somebody else's manifest, not about our code, and -Werror would fail on it.
        #
        # One quoted token: PowerShell splits an unquoted -Xlint:all,-classfile,-serial on the
        # commas and javac then sees "-classfile" as a flag of its own, which it rejects.
        & $javac -encoding UTF-8 '-Xlint:all,-classfile,-serial,-path' -Werror -d $out "@$argFile"
        if ($LASTEXITCODE -ne 0) { throw "javac failed for $name" }

        Push-Location $modRoot
        try {
            & python $mod.Builder $out
            if ($LASTEXITCODE -ne 0) { throw "$($mod.Builder) failed for $name" }
        }
        finally { Pop-Location }
        Remove-Item -LiteralPath $out -Recurse -Force
    }
}
finally {
    if (Test-Path -LiteralPath $jijRoot) { Remove-Item -LiteralPath $jijRoot -Recurse -Force -ErrorAction SilentlyContinue }
}

# ---------------------------------------------------------------- retire superseded jars
# Every first-party jar carries a version in its file name, so building a new one leaves the old one
# beside it. Two jars in mods\ is not a warning at runtime, it is a second mod claiming the same id,
# and the loader picks one.
#
# This covered only the integrity helper until v1.0.48, because the helper is the one whose version
# moves every release. That was the wrong reason to single it out: any first-party mod leaves the
# same wreckage the moment its own version is bumped, and voxyworldgen did it twice in one day -
# 1.2.0 beside 1.3.0, then 1.3.0 beside 1.4.0. Both were caught by eye. The second one would have
# shipped a client that could not start.
foreach ($stale in Get-ChildItem -LiteralPath $releaseMods -Filter 'nbidal18-integrity-*.jar') {
    if ($stale.Name -notlike "*-$version+*") {
        [IO.File]::Delete($stale.FullName)
        Write-Host ("retired   {0}" -f $stale.Name)
    }
}
$helpers = @(Get-ChildItem -LiteralPath $releaseMods -Filter 'nbidal18-integrity-*.jar')
if ($helpers.Count -ne 1) { throw "Expected one integrity helper, found $($helpers.Count)" }

# The rest carry their own versions, which move on their own schedule, so the survivor is the one
# this run just wrote rather than the one matching the pack version. Scoped to the exact mod name
# each time - nothing outside `<mod>-*.jar` is ever a candidate.
foreach ($mod in $mods) {
    $siblings = @(Get-ChildItem -LiteralPath $releaseMods -Filter ("{0}-*.jar" -f $mod.Name) -File |
            Sort-Object LastWriteTimeUtc -Descending)
    if ($siblings.Count -lt 2) { continue }
    foreach ($stale in $siblings[1..($siblings.Count - 1)]) {
        [IO.File]::Delete($stale.FullName)
        Write-Host ("retired   {0}  (superseded by {1})" -f $stale.Name, $siblings[0].Name)
    }
}

Write-Host ''
Write-Host ("OK        {0} first-party mod(s) built into v{1}." -f $mods.Count, $version)
