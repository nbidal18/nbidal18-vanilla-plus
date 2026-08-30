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
    @{ Name = 'nbidal18-hardcorerevive'; Generator = $null; Builder = 'patch_hcrplus.py' }
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

        $sources = @(Get-ChildItem -LiteralPath (Join-Path $modRoot 'src') -Recurse -Filter *.java)
        if ($sources.Count -eq 0) { throw "No sources under $modRoot\src" }
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

# ---------------------------------------------------------------- retire superseded helper jars
# The integrity helper carries the pack version in its file name, so building a new one leaves the
# old one beside it. Two helpers in mods\ is not a warning at runtime, it is a second mod claiming
# the same id, and the loader picks one.
foreach ($stale in Get-ChildItem -LiteralPath $releaseMods -Filter 'nbidal18-integrity-*.jar') {
    if ($stale.Name -notlike "*-$version+*") {
        [IO.File]::Delete($stale.FullName)
        Write-Host ("retired   {0}" -f $stale.Name)
    }
}
$helpers = @(Get-ChildItem -LiteralPath $releaseMods -Filter 'nbidal18-integrity-*.jar')
if ($helpers.Count -ne 1) { throw "Expected one integrity helper, found $($helpers.Count)" }

Write-Host ''
Write-Host ("OK        {0} first-party mod(s) built into v{1}." -f $mods.Count, $version)
