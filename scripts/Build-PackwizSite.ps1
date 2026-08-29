<#
    Builds site/ from the release folder's client master.

    The version is read from PACK-VERSION.txt and nowhere else. The release folder name must agree
    with it, and the build stops if it does not - that mismatch is what published a client whose own
    integrity check rejected its own manifest in the 1.21.1 pack.

    Every published file under config/ must carry a ruling in config-classification.json. The build
    stops while any is unclassified, so adding a mod forces a deliberate decision rather than
    silently inheriting hash enforcement.
#>
[CmdletBinding()]
param(
    [switch] $SkipInstallerJars
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = Split-Path -Parent $PSScriptRoot
$line = Join-Path (Split-Path -Parent $repo) ''      # ...\vanilla_plus\
$version = (Get-Content -LiteralPath (Join-Path $repo 'PACK-VERSION.txt') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw "PACK-VERSION.txt is not a version: '$version'" }

$release = Join-Path $line "v.$version"
if (-not (Test-Path -LiteralPath $release)) {
    throw "PACK-VERSION.txt says $version but there is no release folder at $release"
}
$client = Join-Path $release '3. modpack\client'
if (-not (Test-Path -LiteralPath $client)) { throw "No client master at $client" }

Write-Host "version   $version"
Write-Host "release   $release"

# ---------------------------------------------------------------- classification gate
$classPath = Join-Path $PSScriptRoot 'config-classification.json'
$class = Get-Content -LiteralPath $classPath -Raw | ConvertFrom-Json
$rules = @{}
foreach ($r in $class.rules) { $rules[$r.match] = $r.class }

function Get-Ruling([string] $relPath) {
    $best = $null; $bestLen = -1
    foreach ($m in $rules.Keys) {
        $hit = if ($m.EndsWith('/')) { $relPath.StartsWith($m) } else { $relPath -eq $m }
        if ($hit -and $m.Length -gt $bestLen) { $best = $rules[$m]; $bestLen = $m.Length }
    }
    return $best
}

$configRoot = Join-Path $client 'config'
$unclassified = @()
if (Test-Path -LiteralPath $configRoot) {
    Get-ChildItem -LiteralPath $configRoot -Recurse -File | ForEach-Object {
        $rel = 'config/' + $_.FullName.Substring($configRoot.Length + 1).Replace('\', '/')
        if (-not (Get-Ruling $rel)) { $unclassified += $rel }
    }
}
if ($unclassified.Count) {
    throw ("{0} published config files are unclassified. Add a ruling for each in {1}:`n  {2}" -f `
            $unclassified.Count, $classPath, ($unclassified -join "`n  "))
}
Write-Host ("config    {0} files, all classified" -f $rules.Count)

# ---------------------------------------------------------------- stage
$site = Join-Path $repo 'site'
if (Test-Path -LiteralPath $site) { Remove-Item -LiteralPath $site -Recurse -Force }
New-Item -ItemType Directory -Path $site -Force | Out-Null

foreach ($root in 'mods', 'config', 'shaderpacks', 'resourcepacks', 'datapacks') {
    $src = Join-Path $client $root
    if (-not (Test-Path -LiteralPath $src)) { continue }
    robocopy $src (Join-Path $site $root) /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed for $root (exit $LASTEXITCODE)" }
}
foreach ($f in 'THIRD-PARTY-NOTICES.md', 'credits.txt') {
    $p = Join-Path $client $f
    if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination $site -Force }
}

# ---------------------------------------------------------------- pack.toml
$loader = (Get-Content -LiteralPath (Join-Path $repo 'LOADER.txt') -Raw).Trim()
$mc = (Get-Content -LiteralPath (Join-Path $repo 'MINECRAFT.txt') -Raw).Trim()
$packToml = @"
name = "nbidal18 Vanilla+"
version = "$version"
description = "Minecraft $mc vanilla+ modpack with automatic Prism updates"
pack-format = "packwiz:1.1.0"

[index]
file = "index.toml"
hash-format = "sha256"
hash = ""

[versions]
fabric = "$loader"
minecraft = "$mc"
"@
[IO.File]::WriteAllText((Join-Path $site 'pack.toml'), ($packToml -replace "`r`n", "`n"), (New-Object Text.UTF8Encoding($false)))

# ---------------------------------------------------------------- index
# packwiz refresh reads an existing index before rewriting it, so seed an empty one.
[IO.File]::WriteAllText((Join-Path $site 'index.toml'), "hash-format = `"sha256`"`n", (New-Object Text.UTF8Encoding($false)))

$packwiz = Join-Path $release '5. modpack source\auto-updater tools\packwiz.exe'
if (-not (Test-Path -LiteralPath $packwiz)) { throw "packwiz.exe not found at $packwiz" }
Push-Location $site
try {
    & $packwiz refresh 2>&1 | Where-Object { $_ -notmatch '^\s*$' } | Select-Object -Last 3 | ForEach-Object { Write-Host "packwiz   $_" }
    if ($LASTEXITCODE -ne 0) { throw "packwiz refresh failed (exit $LASTEXITCODE)" }
}
finally { Pop-Location }

$entries = (Select-String -LiteralPath (Join-Path $site 'index.toml') -Pattern '^\[\[files\]\]' -AllMatches).Count
$indexHash = (Get-FileHash -LiteralPath (Join-Path $site 'index.toml') -Algorithm SHA256).Hash.ToLower()
Write-Host ("index     {0} files, sha256 {1}" -f $entries, $indexHash.Substring(0, 16))

# ---------------------------------------------------------------- checksums
$sums = New-Object Text.StringBuilder
Get-ChildItem -LiteralPath $site -Recurse -File | Sort-Object FullName | ForEach-Object {
    $rel = $_.FullName.Substring($site.Length + 1).Replace('\', '/')
    if ($rel -eq 'SHA256SUMS.txt') { return }
    $null = $sums.AppendFormat("{0}  {1}`n", (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower(), $rel)
}
[IO.File]::WriteAllText((Join-Path $site 'SHA256SUMS.txt'), $sums.ToString(), (New-Object Text.UTF8Encoding($false)))

$total = (Get-ChildItem -LiteralPath $site -Recurse -File | Measure-Object -Sum Length)
Write-Host ("site      {0} files, {1:N1} MB" -f $total.Count, ($total.Sum / 1MB))
Write-Host "done"
