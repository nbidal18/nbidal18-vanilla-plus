<#
    Rebuilds the pack's Eclipse shader with nbidal18 IntegratedPBR.

      scripts\Build-EclipseShader.ps1                     patch the release's own copy in place
      scripts\Build-EclipseShader.ps1 -Out <path\to.zip>  write the result somewhere else, for testing

    Owner, 2026-09-17: "if u are able to port the complimentary one, do it custom". Complementary's
    generated normals and coated textures, on terrain, entities and the held item, because Eclipse's
    own materials come from a labPBR resource pack and this pack ships none.

    **The input is the pack's own fork**, not upstream Eclipse: the untouched zip it was forked from
    is not on this machine any more, so the fork carries the earlier ore-glow and hurt-flash changes
    and this adds to it. The builder refuses to run on a zip without those two markers, and refuses
    to run twice. The output keeps the same file name, because Iris keys a player's shader settings
    to it.

    The work is in build_eclipse_ipbr.py beside its GLSL, in the release's source folder.
#>
[CmdletBinding()]
param(
    [string] $ReleaseRoot,
    [string] $Out
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$packVersion = (Get-Content -LiteralPath (Join-Path $repo 'PACK-VERSION.txt') -Raw).Trim()
if (-not $ReleaseRoot) { $ReleaseRoot = Join-Path (Split-Path -Parent $repo) "v.$packVersion" }
if (-not (Test-Path -LiteralPath $ReleaseRoot)) { throw "No release folder at $ReleaseRoot" }

$builder = Join-Path $ReleaseRoot '5. modpack source\custom packs\nbidal18-Eclipse-Shader\build_eclipse_ipbr.py'
if (-not (Test-Path -LiteralPath $builder -PathType Leaf)) { throw "Missing input: $builder" }

$arguments = @($ReleaseRoot)
if ($Out) { $arguments += @('--out', $Out) }
& python $builder @arguments
if ($LASTEXITCODE -ne 0) { throw 'build_eclipse_ipbr.py failed' }
