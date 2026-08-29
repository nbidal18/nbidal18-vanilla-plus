<#
    Cuts the next version: everything between "the last release shipped" and "Build-Release can run".

      scripts\New-Release.ps1                 patch bump, 1.0.10 -> 1.0.11
      scripts\New-Release.ps1 -Version 1.1.0  an explicit version
      scripts\New-Release.ps1 -WhatIf         say what it would do

    This is the part that was done by hand ten times in one day: copy the release folder, bump the
    version in three places, regenerate the integrity helper's source, compile it, package it,
    install it, delete the previous one. Seven steps, every one of which is silent when skipped
    until something much later goes wrong.

    It compiles the first-party mods from a classpath built out of Prism's own metadata rather than
    a file kept in a scratch directory. The helper is the one mod that can lock every player out of
    the server, and until now it could not be rebuilt at all if that scratch directory were cleared.

    What it deliberately does NOT do:

      * touch site\ - that is Build-Release's job, and keeping them apart means this can be re-run
      * write a changelog entry - an entry means "this reached players", so it is written at publish
        time and by hand
      * publish anything

    After it: edit what the release changes, then Build-Release.ps1.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $Version,
    [string] $InstanceName = 'nbidal18-vanilla-plus-client'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$packRoot = Split-Path -Parent $repo
$versionFile = Join-Path $repo 'PACK-VERSION.txt'
$current = (Get-Content -LiteralPath $versionFile -Raw).Trim()

if (-not $Version) {
    $parts = $current -split '\.'
    if ($parts.Count -ne 3) { throw "Cannot patch-bump a version shaped like '$current'" }
    $Version = '{0}.{1}.{2}' -f $parts[0], $parts[1], ([int] $parts[2] + 1)
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "Not a version: $Version" }

$from = Join-Path $packRoot "v.$current"
$to = Join-Path $packRoot "v.$Version"
if (-not (Test-Path -LiteralPath $from)) { throw "No release folder for the current version: $from" }
if (Test-Path -LiteralPath $to) { throw "$to already exists - a published version is never rebuilt" }

Write-Host ("cutting   v{0} -> v{1}" -f $current, $Version)
if (-not $PSCmdlet.ShouldProcess($to, 'copy the release folder and bump every version')) { return }

# Everything past here is undone if any step throws. A half-cut release - a folder that exists with
# the version bumped and no rebuilt helper - is worse than no release: the next run refuses because
# the folder is already there, and the state looks deliberate.
$rollback = {
    if (Test-Path -LiteralPath $to) { Remove-Item -LiteralPath $to -Recurse -Force }
    [IO.File]::WriteAllText($versionFile, "$current`n", (New-Object Text.UTF8Encoding($false)))
    Write-Host ("rolled back to v{0}; nothing was left half-cut" -f $current)
}
try {

# ---------------------------------------------------------------- copy, and prove the copy
robocopy $from $to /E /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed with $LASTEXITCODE" }
$a = Get-ChildItem -LiteralPath $from -Recurse -File | Measure-Object Length -Sum
$b = Get-ChildItem -LiteralPath $to -Recurse -File | Measure-Object Length -Sum
if ($a.Count -ne $b.Count -or $a.Sum -ne $b.Sum) {
    throw "The copy does not match the source: $($a.Count)/$($a.Sum) vs $($b.Count)/$($b.Sum)"
}
Write-Host ("copied    {0} files, {1} MB" -f $b.Count, [math]::Round($b.Sum / 1MB))

# ---------------------------------------------------------------- the version, in all of its places
[IO.File]::WriteAllText($versionFile, "$Version`n", (New-Object Text.UTF8Encoding($false)))

$bcc = Join-Path $to '3. modpack\client\config\bcc-common.toml'
$text = [IO.File]::ReadAllText($bcc)
$expected = 'modpackVersion = "v{0}"' -f $current
if ($text -notmatch [regex]::Escape($expected)) { throw "bcc-common.toml does not say $expected" }
[IO.File]::WriteAllText($bcc, $text.Replace($expected, ('modpackVersion = "v{0}"' -f $Version)),
    (New-Object Text.UTF8Encoding($false)))
Write-Host ("version   PACK-VERSION.txt and bcc-common.toml -> {0}" -f $Version)

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
# The mods a first-party artefact compiles against - Fabric API, InvMove, JEI, cloth-config - come
# from the release being built, not from the instance, so a version cut compiles against what it is
# about to ship rather than against what happens to be installed.
foreach ($jar in Get-ChildItem -LiteralPath (Join-Path $to '3. modpack\client\mods') -Filter *.jar) {
    if ($jar.Name -like 'nbidal18-*') { continue }
    $classpath.Add($jar.FullName)
}
# Fabric API ships as a jar-in-jar bundle: fabric-networking-api-v1, fabric-lifecycle-events-v1 and
# the rest live inside META-INF/jars/ of the outer jar. The loader opens those at runtime; javac
# cannot see into them, so an import of net.fabricmc.fabric.api.networking.v1 fails against the
# outer jar alone. Expand one level and add what comes out.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$jijRoot = Join-Path ([IO.Path]::GetTempPath()) 'nbidal18-jij'
if (Test-Path -LiteralPath $jijRoot) { Remove-Item -LiteralPath $jijRoot -Recurse -Force }
New-Item -ItemType Directory -Path $jijRoot | Out-Null
$nested = 0
foreach ($jar in Get-ChildItem -LiteralPath (Join-Path $to '3. modpack\client\mods') -Filter *.jar) {
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
Write-Host ("classpath {0} jars ({1} nested inside other mods)" -f $classpath.Count, $nested)

$customMods = Join-Path $to '5. modpack source\custom mods'

function Build-FirstPartyMod([string] $name, [string] $generator, [string] $builder) {
    # $classpath, $javac and $out are read from the enclosing scope on purpose: this is one script's
    # helper, not a general-purpose function.
    $modRoot = Join-Path $customMods $name
    if (-not (Test-Path -LiteralPath $modRoot)) { throw "No source for $name at $modRoot" }

    if ($generator) {
        Push-Location $modRoot
        try {
            & python $generator | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "$generator failed for $name" }
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
    # Forward slashes throughout: javac's argfile parser treats a backslash inside a quoted string
    # as an escape, so a Windows path written literally is silently mangled. Quoted because the
    # release path contains spaces.
    $argFile = Join-Path $out 'javac-args.txt'
    $fwd = [char]47
    $bsl = [char]92
    $argLines = @('-cp', ('"' + ($classpath -join ';').Replace($bsl, $fwd) + '"'))
    $argLines += $sources | ForEach-Object { '"' + $_.FullName.Replace($bsl, $fwd) + '"' }
    [IO.File]::WriteAllText($argFile, ($argLines -join "`n"), (New-Object Text.UTF8Encoding($false)))

    # -Werror on purpose. The 1.21.1 build once packaged a 776-byte jar from a failed compile
    # because nothing checked the exit code; this refuses to reach the packaging step at all.
    # -serial is excluded because a checked exception without a serialVersionUID is not a defect,
    # and -classfile because Minecraft's own @Contract annotations warn on every build.
    # One quoted token: PowerShell splits an unquoted -Xlint:all,-classfile,-serial on the commas
    # and javac then sees "-classfile" as a flag of its own, which it rejects.
    #
    # -classfile  Minecraft's own @Contract annotations warn on every build
    # -serial     a checked exception without a serialVersionUID is not a defect here
    # -path       a mod's manifest Class-Path names sibling jars this pack does not ship, so javac
    #             reports "bad path element" for jars nothing actually needs. That is a fact about
    #             somebody else's manifest, not about our code, and -Werror would fail on it.
    & $javac -encoding UTF-8 '-Xlint:all,-classfile,-serial,-path' -Werror -d $out "@$argFile"
    if ($LASTEXITCODE -ne 0) { throw "javac failed for $name" }

    Push-Location $modRoot
    try {
        & python $builder $out
        if ($LASTEXITCODE -ne 0) { throw "$builder failed for $name" }
    }
    finally { Pop-Location }
    Remove-Item -LiteralPath $out -Recurse -Force
}

# ---------------------------------------------------------------- the first-party mods
Build-FirstPartyMod 'nbidal18-integrity' 'port_integrity.py' 'build_integrity.py'
Build-FirstPartyMod 'nbidal18-invmov' $null 'build_invmov.py'

# ---------------------------------------------------------------- retire the previous jars
$mods = Join-Path $to '3. modpack\client\mods'
foreach ($stale in Get-ChildItem -LiteralPath $mods -Filter 'nbidal18-integrity-*.jar') {
    if ($stale.Name -notlike "*-$Version+*") {
        [IO.File]::Delete($stale.FullName)
        Write-Host ("retired   {0}" -f $stale.Name)
    }
}
$helpers = @(Get-ChildItem -LiteralPath $mods -Filter 'nbidal18-integrity-*.jar')
if ($helpers.Count -ne 1) { throw "Expected one integrity helper, found $($helpers.Count)" }

    Write-Host ''
    Write-Host ("OK        v{0} is cut. Make the release's changes, then run Build-Release.ps1." -f $Version)
}
catch {
    & $rollback
    throw
}
finally {
    if ($jijRoot -and (Test-Path -LiteralPath $jijRoot)) {
        Remove-Item -LiteralPath $jijRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
