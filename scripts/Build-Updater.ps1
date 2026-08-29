<#
    Builds the two Prism pre-launch jars from client\*.java.

      nbidal18-packwiz-sync.jar      the supervisor. Small, stable, and what Prism actually runs.
                                     It promotes any staged .next.jar and then runs the updater.
      nbidal18-packwiz-updater.jar   the updater. Talks to the channel, drives packwiz-installer,
                                     shows real 0-100% progress, preserves player-owned files and
                                     enforces the manifest's property rules.

    Neither imports Minecraft or Fabric: they run before the game starts. That is why this builds
    with plain javac and no game jar on the classpath.

    Both are also written into site\ with a .next.jar suffix. That is the self-update path: the
    updater downloads the .next copies, and on the following launch the supervisor promotes them
    before running anything. It is the reason the updater can replace itself without Prism ever
    starting Minecraft from a half-updated release.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = Split-Path -Parent $PSScriptRoot
$client = Join-Path $repo 'client'
$site = Join-Path $repo 'site'
$out = Join-Path $client 'java-build'

$jdk = Join-Path $env:APPDATA 'PrismLauncher\java\java-runtime-epsilon\bin'
$javac = Join-Path $jdk 'javac.exe'
$jar = Join-Path $jdk 'jar.exe'
foreach ($tool in $javac, $jar) {
    if (-not (Test-Path -LiteralPath $tool)) { throw "Missing $tool" }
}

if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Recurse -Force }
New-Item -ItemType Directory -Path $out -Force | Out-Null

$sources = @(
    (Join-Path $client 'Nbidal18PackwizSync.java'),
    (Join-Path $client 'Nbidal18PackwizSupervisor.java')
)
& $javac -Xlint:all -Werror -d $out @sources
if ($LASTEXITCODE -ne 0) { throw "javac failed ($LASTEXITCODE)" }
Write-Host ("compiled  {0} classes" -f (Get-ChildItem -LiteralPath $out -Filter *.class).Count)

$builds = @(
    @{ jar = 'nbidal18-packwiz-sync.jar'; main = 'Nbidal18PackwizSupervisor' },
    @{ jar = 'nbidal18-packwiz-updater.jar'; main = 'Nbidal18PackwizSync' }
)
foreach ($b in $builds) {
    $target = Join-Path $client $b.jar
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
    $classes = Get-ChildItem -LiteralPath $out -Filter ($b.main + '*.class') | ForEach-Object { $_.Name }
    if (-not $classes) { throw "No classes for $($b.main)" }
    Push-Location $out
    try {
        & $jar --create --file $target --main-class $b.main @classes
        if ($LASTEXITCODE -ne 0) { throw "jar failed for $($b.jar)" }
    }
    finally { Pop-Location }

    # ship it, and ship the staged copy the supervisor promotes on the next launch
    Copy-Item -LiteralPath $target -Destination (Join-Path $site $b.jar) -Force
    Copy-Item -LiteralPath $target -Destination (Join-Path $site ($b.jar -replace '\.jar$', '.next.jar')) -Force
    Write-Host ("built     {0,-34} {1,8:N0} B  ({2} classes)" -f $b.jar, (Get-Item -LiteralPath $target).Length, $classes.Count)
}

# packwiz's own jars are staged the same way, so a channel can replace them too
$tools = Join-Path (Split-Path -Parent $repo) ("v." + (Get-Content -LiteralPath (Join-Path $repo 'PACK-VERSION.txt') -Raw).Trim() + '\5. modpack source\auto-updater tools')
foreach ($j in 'packwiz-installer-bootstrap.jar', 'packwiz-installer.jar') {
    Copy-Item -LiteralPath (Join-Path $tools $j) -Destination (Join-Path $site ($j -replace '\.jar$', '.next.jar')) -Force
}
Write-Host "staged    packwiz-installer(.bootstrap).next.jar"
Write-Host "done"
