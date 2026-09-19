<#
    Rebuilds the pack's Eclipse shader with nbidal18 IntegratedPBR.

      scripts\Build-EclipseShader.ps1                     build the Complementary variant beside the plain fork
      scripts\Build-EclipseShader.ps1 -Out <path\to.zip>  write the result somewhere else, for testing

    Owner, 2026-09-17: "if u are able to port the complimentary one, do it custom". Complementary's
    generated normals and coated textures, on terrain, entities and the held item, because Eclipse's
    own materials come from a labPBR resource pack and this pack ships none.

    **Two shaders ship from v1.0.104.** The plain fork, nbidal18-Eclipse-Shader-Unstable.zip - Eclipse
    with only the ore-glow and hurt-flash changes - is this script's input and is never modified. The
    output is a second pack beside it, nbidal18-Eclipse-Complementary-Unstable.zip. Owner, 2026-09-19:
    "keep this eclipse shader u are working on patching it with complimentary stuff, but rename it to
    eclipse-complimentary-unstable, then put back a normal eclipse-unstable". The builder refuses a
    zip without the fork's two markers, and refuses one that already has IntegratedPBR, so it cannot
    patch its own output. Iris keys a player's shader settings to the zip's file name, so each has
    its own settings file.

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
