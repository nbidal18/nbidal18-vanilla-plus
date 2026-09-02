<#
    Rebuilds nbidal18-Weskersons-3D-Items-2.5.zip from Weskerson's published pack.

      scripts\Build-Weskersons3DItems.ps1

    This fork existed from v1.0.32 with no script and no note. Two things had been done to it by
    hand, and only one of them was written down anywhere - which is the reason this file exists at
    all, not the compass.

    **1. Its core shaders are stripped.** The pack ships `shaders/core/entity`,
    `rendertype_item_entity_translucent_cull` and, in the 26.1 overlay, `item.vsh` and `item.fsh`.
    That last pair is the same bug that blanked every inventory slot in v1.0.6: Weskerson's item
    shader drops the `Sampler1` uniform the item pipeline binds, so item sprites stop drawing while
    the world renders fine. Weskerson's Torches was patched for exactly this. Re-downloading the
    pack without this step brings the bug straight back, and it announces itself only in the log.

    **2. One compass frame is restored.** A compass is a flipbook of 32 pictures. Vanilla lists 33
    entries per branch - thresholds 0 through 31.5 - because the last one wraps back to the first
    picture. Weskerson's `spawn` branches do this; its two `lodestone` branches stop at 30.5 and
    have 32. The effect is one picture short at one bearing on a lodestone compass: the needle holds
    a beat, then catches up. Cosmetic, and nothing to do with the compass that went invisible in
    v1.0.45 - that was a bad model bake and cleared on a resource reload.

    The wrap entry is not written out here. It is copied from whatever that branch's threshold-0
    entry points at, which is what vanilla does and what makes it right for both branches - one
    counts from `compass_16`, the other from `enchanted_compass_hand_16`.
#>
[CmdletBinding()]
param(
    [string] $ReleaseRoot,
    [string] $UpstreamVersion = '2.5'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repo = Split-Path -Parent $PSScriptRoot
$packVersion = (Get-Content -LiteralPath (Join-Path $repo 'PACK-VERSION.txt') -Raw).Trim()
if (-not $ReleaseRoot) { $ReleaseRoot = Join-Path (Split-Path -Parent $repo) "v.$packVersion" }
if (-not (Test-Path -LiteralPath $ReleaseRoot)) { throw "No release folder at $ReleaseRoot" }

$source = Join-Path $ReleaseRoot '5. modpack source\custom packs\nbidal18-Weskersons-3D-Items'
$base = Join-Path $source ("upstream-$UpstreamVersion.zip")
if (-not (Test-Path -LiteralPath $base -PathType Leaf)) { throw "No upstream pack at $base" }

Write-Host ("base      {0} ({1:N0} B)" -f (Split-Path $base -Leaf), (Get-Item -LiteralPath $base).Length)

# ---------------------------------------------------------------- read the upstream pack
$entries = [ordered]@{}
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

# ---------------------------------------------------------------- 1. drop the core shaders
$kept = [ordered]@{}
$droppedShaders = 0
$droppedJunk = 0
foreach ($name in $entries.Keys) {
    if ($name -like '__MACOSX*' -or $name -like '*.DS_Store' -or $name -like '*Thumbs.db') {
        $droppedJunk++
        continue
    }
    # Anywhere, not just the base directory: this pack keeps four version overlays and the one that
    # matters on 26.2 is 26.1/, so a rule anchored on assets/ would have left the live copy in.
    if ($name -match '(^|/)assets/minecraft/shaders/core/') {
        $droppedShaders++
        continue
    }
    $kept[$name] = $entries[$name]
}
Write-Host ("dropped   {0} core shader file(s), {1} junk" -f $droppedShaders, $droppedJunk)

# ---------------------------------------------------------------- 2. the missing compass frame
#
# Done on the text rather than by reparsing and rewriting the file. Windows PowerShell's JSON
# writer reformats and re-escapes everything it touches, which would rewrite all 15 KB of a file
# where two lines are wrong and make the next diff of this pack unreadable.
#
# The file lists one entry per line, so a small state machine over the lines is enough: find each
# "entries" array, and if it holds 32 of them, append a copy of its first entry at threshold 31.5.
$compassPath = 'assets/minecraft/items/compass.json'
if (-not $kept.Contains($compassPath)) { throw "No $compassPath in the upstream pack" }

$text = [Text.Encoding]::UTF8.GetString($kept[$compassPath])
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = $text -split "`r?`n"

$out = New-Object Collections.Generic.List[string]
$block = New-Object Collections.Generic.List[string]
$inEntries = $false
$patched = 0
foreach ($line in $lines) {
    if (-not $inEntries) {
        $out.Add($line)
        if ($line -match '"entries"\s*:\s*\[\s*$') { $inEntries = $true; $block.Clear() }
        continue
    }
    if ($line -match '^\s*\]') {
        # The array closed. Patch it only if it is one of the short ones.
        if ($block.Count -eq 32 -and $block[0] -match '"threshold"\s*:\s*0(\.0)?\s*,') {
            # The line being copied is the FIRST of thirty-odd entries, so it carries a trailing
            # comma; as the new last entry it must not. Getting this wrong produced a file that
            # looked right in a diff and would not parse, and the check at the bottom is the only
            # reason it did not ship.
            $wrap = ($block[0] -replace '"threshold"\s*:\s*0(\.0)?\s*,', '"threshold": 31.5,').TrimEnd().TrimEnd(',')
            $block[$block.Count - 1] = $block[$block.Count - 1].TrimEnd() + ','
            $block.Add($wrap)
            $patched++
        }
        foreach ($kept_line in $block) { $out.Add($kept_line) }
        $out.Add($line)
        $inEntries = $false
        continue
    }
    $block.Add($line)
}
if ($inEntries) { throw 'compass.json ended inside an entries array - the file is not what this expects' }
if ($patched -ne 2) { throw "Expected 2 short compass branches, patched $patched - check the pack before shipping it" }
Write-Host ("compass   {0} lodestone branch(es) given their 33rd frame" -f $patched)

$kept[$compassPath] = [Text.Encoding]::UTF8.GetBytes(($out -join $newline))

# ---------------------------------------------------------------- write it
$out_zip = Join-Path $ReleaseRoot '3. modpack\client\resourcepacks\nbidal18-Weskersons-3D-Items-2.5.zip'
$fs = [IO.File]::Create($out_zip)
$zip = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Create)
try {
    # Sorted, so an unchanged upstream rebuilds to the same bytes and does not move the digest for
    # no reason. Same rule as every first-party jar here.
    foreach ($name in ($kept.Keys | Sort-Object)) {
        $written = $zip.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
        $stream = $written.Open()
        $stream.Write($kept[$name], 0, $kept[$name].Length)
        $stream.Close()
    }
}
finally { $zip.Dispose(); $fs.Close() }
Write-Host ("built     {0} ({1:N0} B, {2} entries)" -f (Split-Path $out_zip -Leaf), (Get-Item -LiteralPath $out_zip).Length, $kept.Count)

# ---------------------------------------------------------------- prove it
$check = [IO.Compression.ZipFile]::OpenRead($out_zip)
try {
    if (@($check.Entries | Where-Object { $_.FullName.Contains([char]92) }).Count) {
        throw 'entries have backslash paths - Minecraft would load no assets'
    }
    if (@($check.Entries | Where-Object { $_.FullName -match '(^|/)assets/minecraft/shaders/core/' }).Count) {
        throw 'a core shader survived - this is the file that blanked every inventory slot in v1.0.6'
    }
    $entry = $check.Entries | Where-Object { $_.FullName -eq $compassPath }
    if (-not $entry) { throw "no $compassPath in the built pack" }
    $reader = New-Object IO.StreamReader($entry.Open())
    $compass = $reader.ReadToEnd() | ConvertFrom-Json
    $reader.Dispose()

    # Parsed, not trusted: the patch above is a text edit, so the only proof it produced valid JSON
    # with the right shape is reading it back.
    $counts = New-Object Collections.Generic.List[int]
    $walk = {
        param($node)
        if ($node -is [Management.Automation.PSCustomObject]) {
            $properties = $node.PSObject.Properties
            if (($properties.Name -contains 'type') -and $node.type -eq 'minecraft:range_dispatch') {
                $counts.Add(@($node.entries).Count)
            }
            foreach ($property in $properties) { & $walk $property.Value }
        }
        elseif ($node -is [Object[]]) {
            foreach ($item in $node) { & $walk $item }
        }
    }
    & $walk $compass
    $wrong = @($counts | Where-Object { $_ -ne 33 })
    if ($wrong.Count) {
        throw ("compass branches have {0} frames, all four should have 33" -f (($counts | Sort-Object -Unique) -join ', '))
    }
    Write-Host ("verified  {0} entries, no core shaders, all {1} compass branches carry 33 frames" -f `
            @($check.Entries).Count, $counts.Count)
}
finally { $check.Dispose() }

Write-Host ''
Write-Host 'OK        run Build-Release.ps1 to fold this into the pack.'
