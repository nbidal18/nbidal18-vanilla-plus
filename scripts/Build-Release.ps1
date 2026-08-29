<#
    Builds the whole release, in the only order that works, and refuses to finish if the result is
    incomplete.

    The order matters and is not obvious. Build-PackwizSite WIPES site\ before staging, so anything
    the other two scripts put there is destroyed if they run first. That happened once and would
    have published a channel with no client ZIP and no .next staging jars - the updater would have
    installed the pack and then failed to find the files it promotes on the next launch.

    Checksums are written here rather than inside Build-PackwizSite, because SHA256SUMS.txt has to
    cover the jars and the ZIP that are added after staging.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = Split-Path -Parent $PSScriptRoot
$site = Join-Path $repo 'site'

Write-Host "== 1/4 pack content"
& (Join-Path $PSScriptRoot 'Build-PackwizSite.ps1')
Write-Host "`n== 2/4 updater jars"
& (Join-Path $PSScriptRoot 'Build-Updater.ps1')
Write-Host "`n== 3/4 client shell"
& (Join-Path $PSScriptRoot 'Build-ClientShell.ps1') | Select-Object -First 1

Write-Host "`n== 4/4 checksums and release gate"
$sums = New-Object Text.StringBuilder
Get-ChildItem -LiteralPath $site -Recurse -File | Sort-Object FullName | ForEach-Object {
    $rel = $_.FullName.Substring($site.Length + 1).Replace('\', '/')
    if ($rel -eq 'SHA256SUMS.txt') { return }
    $null = $sums.AppendFormat("{0}  {1}`n", (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower(), $rel)
}
[IO.File]::WriteAllText((Join-Path $site 'SHA256SUMS.txt'), $sums.ToString(), (New-Object Text.UTF8Encoding($false)))

# Everything a client needs from the channel, none of which is in the packwiz index.
$required = @(
    'pack.toml', 'index.toml', 'sync-manifest.json', 'SHA256SUMS.txt',
    'nbidal18-client.zip',
    'nbidal18-packwiz-sync.jar', 'nbidal18-packwiz-sync.next.jar',
    'nbidal18-packwiz-updater.jar', 'nbidal18-packwiz-updater.next.jar',
    'packwiz-installer.next.jar', 'packwiz-installer-bootstrap.next.jar'
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $site $_)) })
if ($missing.Count) { throw ("The release is incomplete; these are missing from site\: " + ($missing -join ', ')) }

$total = Get-ChildItem -LiteralPath $site -Recurse -File | Measure-Object -Sum Length
Write-Host ("release   {0} files, {1:N1} MB, all {2} required artefacts present" -f `
        $total.Count, ($total.Sum / 1MB), $required.Count)
Write-Host "ready to publish"
