<#
    Rebuilds nbidal18-Actually-3D-26.2.zip from the published Actually 3D pack.

      scripts\Build-Actually3D.ps1

    Actually 3D covers 878 models where every other 3D pack here covers a few dozen, so it is the
    floor the pack stands on and the Weskerson packs are the detail on top. Three things had to
    change before it could be shipped, and all three are done here rather than by hand:

    **1. Models another pack already ships are dropped**, so torches stay Weskerson's and lanterns
    and chains stay Better Lanterns'. The set is read out of those two packs at build time rather
    than written down here, because written down here it was wrong three times over - see the note
    above `$dropNames` for what each wrong word cost.

    Everything else is kept, including flowers, mushrooms, bamboo and the potted plants - those
    overlap Weskerson's 3D Items, but this pack sits ABOVE it in the order, so it wins them
    deliberately, and that pack is left out of the measurement for exactly that reason.

    Blockstates and item definitions are dropped alongside the models they name. A blockstate
    pointing at a model that is no longer in the pack is a missing-model error on every placement.

    **2. Items are 3D in the hand and flat in the inventory.**

    The pack ships 114 three-dimensional item models but only 38 definitions that say "flat in the
    GUI, 3D everywhere else" - so the other 76 would be 3D in the inventory too, which is not wanted.
    This generates the missing half: a flat `<name>_gui` model from the vanilla item texture, and a
    `minecraft:select` on `display_context` sending `gui` to it and everything else to the 3D model.
    That is exactly the shape the pack's own 38 use.

    An item with no vanilla item texture cannot have a flat GUI model generated for it - a button or
    an amethyst cluster renders from its block model, not a sprite - so its 3D item model is dropped
    instead and vanilla draws it.

    **3. `pack.mcmeta` is rewritten for 26.2.** Upstream declares `max_format: 84` and carries a
    `supported_formats` block, which 26.2 rejects outright; 26.2 is format 88. This is the same
    override Immersive Interfaces needed, and the same risk: a pack built for 26.1 is being told it
    is a 26.2 pack, so a model format change between the two would show up in game rather than here.

    Foreign assets go too: `farm_and_charm` and `holdmyitems` serve mods this pack does not run.
#>
[CmdletBinding()]
param(
    [string] $ReleaseRoot,
    [string] $UpstreamVersion = 'r1.8'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repo = Split-Path -Parent $PSScriptRoot
$packVersion = (Get-Content -LiteralPath (Join-Path $repo 'PACK-VERSION.txt') -Raw).Trim()
if (-not $ReleaseRoot) { $ReleaseRoot = Join-Path (Split-Path -Parent $repo) "v.$packVersion" }
if (-not (Test-Path -LiteralPath $ReleaseRoot)) { throw "No release folder at $ReleaseRoot" }

$source = Join-Path $ReleaseRoot '5. modpack source\custom packs\nbidal18-Actually-3D'
$base = Join-Path $source ("upstream-$UpstreamVersion.zip")
if (-not (Test-Path -LiteralPath $base -PathType Leaf)) { throw "No upstream pack at $base" }

# The vanilla jar decides which items can have a flat GUI model generated for them.
$mcJar = Join-Path $env:APPDATA 'PrismLauncher\libraries\com\mojang\minecraft\26.2\minecraft-26.2-client.jar'
if (-not (Test-Path -LiteralPath $mcJar)) { throw "No Minecraft 26.2 client jar at $mcJar" }

# What gets dropped is measured, not listed. Drop exactly the block model names that Better Lanterns
# or Weskerson's Torches already ship, so those two keep the categories they do better and Actually
# 3D supplies everything else.
#
# It used to be a list of words matched as substrings, and that list was wrong in three places -
# each one a category dropped against a pack that did not actually cover it:
#
#   'torch'    also caught torchflower, potted_torchflower and both torchflower crop stages. A
#              plant, deleted by a lighting rule, in a pack shipped to win plants.
#   'lantern'  also caught jack_o_lantern and sea_lantern, which nothing else here replaces.
#   the storage group  matched 66 block models against Weskerson's 3D Items, which ships no block
#              model for any of it - its cauldron and brewing stand are held-item models
#              (item/cauldron_hand and friends). Every placed barrel, furnace, smoker, blast furnace,
#              lectern, stonecutter, loom, composter, cauldron and brewing stand went flat in v1.0.46
#              and nothing drew them. Iron bars went the same way against Better Lanterns, which
#              ships chains and no bars.
#
# Weskerson's 3D Items is deliberately not consulted. It does ship block models - twenty potted
# plants, sugar cane, a flower pot - and those are the ones Actually 3D is meant to win.
$packsDir = Join-Path $ReleaseRoot '3. modpack\client\resourcepacks'
$dropNames = New-Object Collections.Generic.HashSet[string]
foreach ($pattern in @('Better Lanterns*.zip', 'nbidal18-Weskersons-Torches-*.zip')) {
    $rivals = @(Get-ChildItem -LiteralPath $packsDir -Filter $pattern -File)
    # A pack that owns a category this build drops cannot go missing quietly. Without it the drop
    # silently becomes a no-op and Actually 3D starts winning torches, which is a visible change
    # nobody asked for.
    if (-not $rivals.Count) { throw "No resource pack matching '$pattern' in $packsDir" }
    foreach ($rival in $rivals) {
        $rz = [IO.Compression.ZipFile]::OpenRead($rival.FullName)
        try {
            foreach ($e in $rz.Entries) {
                # Leaf name only, at any depth. Better Lanterns files its models in per-block
                # subfolders - models/block/lantern/lantern.json, models/block/chain/iron_chain.json
                # - so an anchored path match found none of them, and the first run of this rule
                # silently dropped nothing but the torches.
                if ($e.FullName -match '^assets/minecraft/models/block/(?:[a-z0-9_]+/)*([a-z0-9_]+)\.json$') {
                    [void] $dropNames.Add($Matches[1])
                }
            }
        }
        finally { $rz.Dispose() }
    }
}
# Parents of the torch models above, left behind by name alone. Nothing kept references them once
# the torches are gone.
foreach ($orphan in @('template_torch', 'template_torch_wall')) { [void] $dropNames.Add($orphan) }
Write-Host ("rivals    {0} model name(s) already covered by another pack" -f $dropNames.Count)

Write-Host ("base      {0} ({1:N0} B)" -f (Split-Path $base -Leaf), (Get-Item -LiteralPath $base).Length)

# ---------------------------------------------------------------- what vanilla can draw flat
$vanillaItemTextures = New-Object Collections.Generic.HashSet[string]
$mc = [IO.Compression.ZipFile]::OpenRead($mcJar)
try {
    foreach ($e in $mc.Entries) {
        if ($e.FullName -match '^assets/minecraft/textures/item/([a-z0-9_]+)\.png$') {
            [void] $vanillaItemTextures.Add($Matches[1])
        }
    }
}
finally { $mc.Dispose() }
Write-Host ("vanilla   {0} item textures available for flat GUI models" -f $vanillaItemTextures.Count)

# ---------------------------------------------------------------- read the upstream pack
$entries = @{}
$in = [IO.Compression.ZipFile]::OpenRead($base)
try {
    foreach ($e in $in.Entries) {
        if ($e.FullName.EndsWith('/')) { continue }
        $buffer = New-Object IO.MemoryStream
        $e.Open().CopyTo($buffer)
        $entries[$e.FullName] = $buffer.ToArray()
    }
}
finally { $in.Dispose() }
Write-Host ("upstream  {0} entries" -f $entries.Count)

$kept = @{}
$dropped = [ordered]@{ category = 0; foreign = 0; junk = 0 }
foreach ($name in $entries.Keys) {
    # Foreign mods and the 1.21.9 overlay this pack does not use.
    if ($name -like 'assets/farm_and_charm/*' -or $name -like 'assets/*/holdmyitems/*' -or
        $name -like '1.21.9_and_above/*' -or $name -like '*__MACOSX*') {
        $dropped['foreign']++
        continue
    }
    if ($name -like '*.DS_Store' -or $name -like '*Thumbs.db') { $dropped['junk']++; continue }

    # Category drops: models, blockstates and item definitions alike.
    if ($name -match '^assets/minecraft/(models/(block|item)|blockstates|items)/([a-z0-9_/]+)\.json$') {
        $leaf = ($Matches[3] -split '/')[-1]
        if ($dropNames.Contains($leaf)) { $dropped['category']++; continue }
    }
    $kept[$name] = $entries[$name]
}
Write-Host ("dropped   {0} by category, {1} foreign, {2} junk" -f `
        $dropped['category'], $dropped['foreign'], $dropped['junk'])

# ---------------------------------------------------------------- items: 3D in hand, flat in GUI
$guarded = New-Object Collections.Generic.HashSet[string]
foreach ($name in $kept.Keys) {
    if ($name -match '^assets/minecraft/items/([a-z0-9_]+)\.json$') { [void] $guarded.Add($Matches[1]) }
}

$generated = 0
$droppedItemModels = 0
foreach ($name in @($kept.Keys)) {
    if ($name -notmatch '^assets/minecraft/models/item/([a-z0-9_]+)\.json$') { continue }
    $item = $Matches[1]
    if ($item.EndsWith('_gui')) { continue }
    $json = [Text.Encoding]::UTF8.GetString($kept[$name])
    if ($json -notmatch '"elements"') { continue }        # already flat, nothing to guard
    if ($guarded.Contains($item)) { continue }            # the pack guards this one itself

    if (-not $vanillaItemTextures.Contains($item)) {
        # No sprite to fall back to - this renders from a block model in vanilla, so let vanilla do
        # it rather than invent a flat model that would draw a missing texture.
        $kept.Remove($name)
        $droppedItemModels++
        continue
    }

    $guiModel = "{`n  `"parent`": `"minecraft:item/generated`",`n  `"textures`": {`n    `"layer0`": `"minecraft:item/$item`"`n  }`n}`n"
    $kept["assets/minecraft/models/item/${item}_gui.json"] = [Text.Encoding]::UTF8.GetBytes($guiModel)

    $definition = @"
{
  "model": {
    "type": "minecraft:select",
    "property": "minecraft:display_context",
    "cases": [
      {
        "when": "gui",
        "model": {
          "type": "minecraft:model",
          "model": "minecraft:item/${item}_gui"
        }
      }
    ],
    "fallback": {
      "type": "minecraft:model",
      "model": "minecraft:item/$item"
    }
  }
}
"@
    $kept["assets/minecraft/items/$item.json"] = [Text.Encoding]::UTF8.GetBytes(($definition -replace "`r`n", "`n") + "`n")
    $generated++
}
Write-Host ("items     {0} guarded by the pack, {1} guards generated, {2} dropped with no sprite" -f `
        $guarded.Count, $generated, $droppedItemModels)

# ---------------------------------------------------------------- 26.2 metadata
$mcmeta = @"
{
  "pack": {
    "description": "Actually 3D by Matt_Crowberry, block models only, repacked for 26.2 by nbidal18",
    "pack_format": 88,
    "min_format": 88,
    "max_format": 99
  }
}
"@
$kept['pack.mcmeta'] = [Text.Encoding]::UTF8.GetBytes(($mcmeta -replace "`r`n", "`n") + "`n")

# ---------------------------------------------------------------- write it
$out = Join-Path $ReleaseRoot '3. modpack\client\resourcepacks\nbidal18-Actually-3D-26.2.zip'
$fs = [IO.File]::Create($out)
$zip = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($name in ($kept.Keys | Sort-Object)) {
        # Entry names must use forward slashes. CreateFromDirectory does not, and a pack whose paths
        # contain backslashes loads with no assets at all - which cost an evening on Immersive
        # Interfaces and read as "the pack is broken" when the packaging was.
        $written = $zip.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
        $stream = $written.Open()
        $stream.Write($kept[$name], 0, $kept[$name].Length)
        $stream.Close()
    }
}
finally { $zip.Dispose(); $fs.Close() }
Write-Host ("built     {0} ({1:N0} B, {2} entries)" -f (Split-Path $out -Leaf), (Get-Item -LiteralPath $out).Length, $kept.Count)

# ---------------------------------------------------------------- prove it is loadable
$check = [IO.Compression.ZipFile]::OpenRead($out)
try {
    if (@($check.Entries | Where-Object { $_.FullName.Contains([char]92) }).Count) {
        throw 'entries have backslash paths - Minecraft would load no assets'
    }
    if (-not ($check.Entries | Where-Object { $_.FullName -eq 'pack.mcmeta' })) { throw 'no pack.mcmeta' }

    # A blockstate may only reference a model this build REMOVED. It is free to reference a model
    # the pack never shipped - that is vanilla's, and vanilla still has it. Comparing against the
    # upstream set rather than against "does it exist here" is the difference between catching a
    # category drop that orphaned a blockstate and failing on every ordinary vanilla reference.
    $present = New-Object Collections.Generic.HashSet[string]
    foreach ($e in $check.Entries) {
        if ($e.FullName -match '^assets/minecraft/models/(.+)\.json$') { [void] $present.Add($Matches[1]) }
    }
    $upstreamModels = New-Object Collections.Generic.HashSet[string]
    foreach ($name in $entries.Keys) {
        if ($name -match '^assets/minecraft/models/(.+)\.json$') { [void] $upstreamModels.Add($Matches[1]) }
    }
    $missing = New-Object Collections.Generic.List[string]
    foreach ($e in $check.Entries) {
        if ($e.FullName -notmatch '^assets/minecraft/blockstates/') { continue }
        $reader = New-Object IO.StreamReader($e.Open())
        $text = $reader.ReadToEnd(); $reader.Dispose()
        foreach ($m in [regex]::Matches($text, '"model"\s*:\s*"minecraft:([a-z0-9_/]+)"')) {
            $ref = $m.Groups[1].Value
            if (-not $present.Contains($ref) -and $upstreamModels.Contains($ref)) { $missing.Add($ref) }
        }
    }
    if ($missing.Count) {
        throw ("{0} blockstate(s) point at models this build dropped, e.g. {1} - drop the blockstate too" -f `
                $missing.Count, (($missing | Select-Object -Unique -First 5) -join ', '))
    }
    # Count .json only. Upstream ships 200 .rpo files beside its models - optimiser residue, inert
    # to Minecraft, and counted as models here until v1.0.47, which put the reported figure 66 above
    # the truth and made a real 66-model loss look like a gain.
    $blocks = @($check.Entries | Where-Object { $_.FullName -like 'assets/minecraft/models/block/*.json' }).Count
    Write-Host ("verified  {0} block models, {1} blockstates, every model reference resolves" -f `
            $blocks, @($check.Entries | Where-Object { $_.FullName -like 'assets/minecraft/blockstates/*.json' }).Count)
}
finally { $check.Dispose() }

Write-Host ''
Write-Host 'OK        run Build-Release.ps1 to fold this into the pack.'
