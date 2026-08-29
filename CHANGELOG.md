# Changelog

One entry per **published** release. An entry means this reached players — never write one for a
build that was not published.

---

## v1.0.0

| Date | Commit | Manifest digest | Files | Mods |
| --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `a1d49ddb7f12884c` | 240 | 103 |

**The first release.** Minecraft 26.2 on Fabric, and a different pack from the 1.21.1 one: vanilla
expanded rather than extended. **No mod adds new blocks or items to find.** The deliberate
exceptions are the ones that change the ground you walk on — Terralith and Tectonic — plus Better
Days, and the revive system below.

**Death is not the end of the world, but it costs somebody a totem.** The server runs hardcore. Your
first death is your last: you become a ghost, and the only way back is another living player
crafting a Soul Charm — four redstone blocks, two copper, two bone and a **totem of undying** — and
**dropping it within two blocks of your body**. Nothing revives at range, nothing revives on a
timer, and coming back costs the returning player a minute of slowness, weakness, hunger, mining
fatigue and blindness. Ghost possession and the Life Jam are both off: possession is a different
game, and with one life the Jam restores nothing.

**Ghosts cannot fly through rock.** A spectator who can pass through terrain can map a cave system
for the living, which is the same advantage the ore pins exist to remove, arriving by another door.
Anti Spectator Noclip keeps them out of blocks.

**The map does not do your exploring for you.** Xaero's World Map ships with eight settings pinned
off: other players, the entity radar, biome names, chunk distances, coordinates, map teleport,
loading chunks you have never visited, and **cave mode** — which sounds harmless and is X-ray with a
different name. Xaero's Minimap is installed **only** because waypoints live in it; the minimap
itself, its radar and its cave mode are held off rather than merely switched off, because a keybind
can toggle them back.

**Neither shader will light ores through walls.** Eclipse and E-LITE both expose an ore-glow switch,
both are pinned to off, and E-LITE ships that switch **enabled** upstream. E-LITE also carries a
new **Mob Hurt Flash** toggle, off by default, that drops the red damage tint while keeping the
white flash a creeper gives you before it goes off.

**Vanilla Refresh is configurable from Mod Menu**, with the names and descriptions Vanilla Refresh
itself uses in its chat menu — read out of the datapack rather than rewritten, so an upstream
rewording follows on its own. Ninety-eight settings, grouped the way its own menu groups them.
Changes sync both ways: the screen writes the file, and the datapack's chat menu writes it back.

**Updating is clicking Play.** The pre-launch updater shows real 0–100% progress, preserves every
player-owned file, and enforces the pinned settings above so a shader or map preference cannot
quietly reintroduce an advantage.

**Not in this release:** the integrity helper. Nothing yet refuses a client whose files do not match
the server — Better Compatibility Checker marks a mismatch but permits the connection. The
classification and the manifest that the helper will read are in place and shipping.

**Maintainer-facing.** New line at `vanilla_plus\`, independent of `nbidal18-packwiz`: its own
version file, channel, Pages workflow and manifest, sharing nothing. 118 config files classified —
9 gameplay, 99 support, 10 player — with three demoted to player on measured evidence rather than
assumption, `sodium-fingerprint.json` among them, the file that locked the 1.21.1 pack out on
2026-08-18. 110 configs were measured as rewritten byte-identically at startup, which is why the
check compares content and never timestamps. Six first-party artefacts: `nbidal18-autohud`,
`nbidal18-JEI`, `nbidal18-betterthirdperson` (a 26.2 port of a closed-source mod),
`nbidal18-immersivethunder`, `nbidal18-vanillarefresh`, `nbidal18-hardcorerevive`, plus a patched
Camera Overhaul and two patched shaders.
