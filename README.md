# nbidal18 Vanilla+ — update channel

Packwiz update channel for the **nbidal18 Vanilla+** modpack: Minecraft **26.2**, Fabric,
client-side only except for worldgen.

**This repository is independent of `nbidal18-packwiz`.** It shares no version file, no manifest,
no digest, no server and no publish sequence with the Fabric 1.21.1 pack. Nothing here should ever
be pointed at that channel, and a change there never implies a change here.

| | |
| --- | --- |
| Minecraft | 26.2 |
| Loader | Fabric, loader `0.19.3` |
| Pack version | see `PACK-VERSION.txt` — **never write it anywhere else** |
| Channel | see `UPDATE-URL.txt` |
| Release folders | `..\v.<version>` |

## The pack in one line

Vanilla, expanded rather than extended: **no mod adds new content.** The only exceptions, agreed
deliberately, are the worldgen mods — Terralith, Tectonic — and Better Days. Everything else either
improves what vanilla already has or is a client-side rendering, sound, input or diagnostic mod.

## Layout

- `site/` — generated publication output. **Never hand-edit it.**
- `scripts/` — build and test tooling.
- `templates/` — sources the build renders into `site/`.
- `client/` — client-side updater material.

## The version lives in exactly one place

`PACK-VERSION.txt`. Every script reads it. This is the single rule carried over from the 1.21.1
pack without argument, because breaking it there once published a client whose own integrity check
rejected its own manifest and locked every player out at login.

## Publishing

**Always ask before publishing.** Building, testing and reviewing the diff is the job; pushing
`main` and deploying the server is a separate, explicit decision each time.

**One publish per version.** A version number is published once and never reused. A fix after a
release is a new version, not a second publish of the same one.
