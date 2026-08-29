# Changelog

One entry per **published** release. An entry means this reached players — never write one for a
build that was not published.

---

## v1.0.5

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `2731ae371d2e6b55` | `19d2fc241fc34dee` | 250 | 106 |

**Voxy really does ship at 32 chunks now, and raising it finally sticks.** Two corrections to
v1.0.4, both of which made that release's headline claim untrue.

**The number was double what it said.** Voxy's option stores `sectionRenderDistance`, its slider
reads that x16, and a *display formatter* then doubles it again - so the screen shows the stored
value x32. v1.0.4 shipped `2.0` believing it was 32 chunks; it was 64. The correct value is `1.0`.
The formatter was visible in the same bytecode as the getter and was not read.

**And it could not be kept anyway.** `config/voxy-config.json` was classified `support`, which means
the updater restores it on every sync - so a player who raised the distance lost it on the next
launch, which is the exact opposite of shipping a low default so people can raise it. It is `player`
now, alongside `iris.properties` and `sodium-options.json`, on the reasoning its own rule already
gave: client-side and machine-dependent.

**Your own setting is safe.** As a `player` file it is published once and never restored, so an
existing install keeps whatever distance it is on. Only new installs start at 32.

Nothing else changed: same 106 mods, same 17 resource packs, same order, same seed token.

---

## v1.0.4

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `19d2fc241fc34dee` | `2769fc637c42839b` | 250 | 106 |

**Torches are 3D too.** Weskerson's Torches joins the pack, above everything that would otherwise
replace its models. Os' Colorful Grasses moves above the two 3D packs, and Simple Voice Chat's dark
icon set is enabled at the very top.

**It starts gentle.** Shaders now ship **off** and Voxy ships lower. Both shaders stay installed
and one stays selected, so turning them on is a toggle — but a first launch no longer hands a
low-end machine a shader pack and hundreds of chunks of LOD before the player has any say. Turn
either up as far as your machine likes.

> **Corrected in v1.0.5.** This entry claimed 32 chunks. What shipped was `2.0`, which displays as
> **64**: Voxy's screen shows the stored value ×32, not ×16, because a display formatter doubles
> the slider on top of the getter's ×16. And `config/voxy-config.json` was `support`, so a raised
> value was restored away on the next sync. v1.0.5 ships `1.0` and reclassifies it `player`.

**Two files stopped shipping somebody else's settings.** `config/sounds/chat.json` shipped a personal
`@handle` as the mention keyword, so every new player's chat pinged on a name that was not theirs;
it ships empty now. `config/resourceful-config-web.json` shipped one machine's generated password
UUID to every install and is no longer published at all — the mod writes its own on first launch, so
each install gets its own secret. **Marking a file as player-owned protects it after the first copy,
not the first copy itself.**

**Updating is clicking Play**, and the pack order arrives with it.

**Maintainer-facing.** The seed carries a new token, `resourcepacks-v104`; a marker is written once
and never re-read, so changed rows need a new one and the previous declaration is replaced rather
than left beside it. Weskerson's Torches declares `max_format` 84 against 26.2's 88, so it ships in
the acknowledged-incompatible list like Actually 3D — its `26.1` overlay covers 84–128 and applies
normally. The classification is down to 118 rules — 10 gameplay, 99 support, 9 player — and 109
measured runtime rewrites.

---

## v1.0.3

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `2769fc637c42839b` | `2a03fec926e56324` | 250 | 106 |

**The update engine can update itself again, which it has never actually been able to do.** Nothing
in the pack changed; this release fixes how the pack is delivered.

The four staged jars the updater replaces itself with — `nbidal18-packwiz-sync.next.jar`,
`nbidal18-packwiz-updater.next.jar`, `packwiz-installer.next.jar` and
`packwiz-installer-bootstrap.next.jar` — were written into `site\` **after** `packwiz refresh` had
already built the index. They were served on the channel and listed nowhere, and nothing but the
index fetches them: packwiz downloads what the index lists, and the supervisor promotes what packwiz
delivered. **Every instance therefore kept whatever update engine its client ZIP shipped, from
v1.0.0 to v1.0.2.**

It surfaced because v1.0.2's resource pack order never arrived. The order was seeded correctly into
the new updater; the new updater never reached anyone.

**The release gate reported "ready to publish" on all three.** It required those four files to exist
in `site\`, which they did. Existing and being reachable are not the same property. The gate now
reads `index.toml`, and was tested against a deliberately broken index before being trusted.

**So v1.0.2's resource pack order lands on the first launch after this one** — the old engine syncs,
packwiz delivers the four jars, the supervisor promotes them and re-runs the new engine before
Minecraft starts. Still one click of Play.

**Maintainer-facing.** `Build-Updater` runs first now and writes only to `client\`;
`Build-PackwizSite` stages the `.next` copies before refreshing. The live engine jars are no longer
published at all — indexing `nbidal18-packwiz-updater.jar` would have packwiz overwrite the jar
running the sync. The channel's root-level files and their manifest treatment are now identical to
the 1.21.1 pack's, which has always done this correctly. The updater, the supervisor and the
integrity helper were diffed against that pack afterwards: the helper is line-for-line identical bar
the two 26.2 API changes, and the other two are method-for-method identical. Every divergence this
line has had was in the build layer, not the Java.

---

## v1.0.2

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `2a03fec926e56324` | `6fe2b134898ec273` | 246 | 106 |

**Blocks and items are 3D now.** *3D Default* and *Actually 3D Blocks & Items* join the pack, *Fancy
Crops* leaves it, and all sixteen resource packs are reordered.

**The order reaches you, which it normally could not.** `options.txt` is never published — it holds
every keybind and video setting a player owns — so a new pack would arrive on disk switched off and
the order would only ever be right on a fresh install. The two rows are seeded instead: written once
by the updater, then yours again from that moment. **One click of Play does all of it**; the
supervisor promotes the new update engine and re-runs it before Minecraft starts.

**Connected glass wins over 3D glass panes.** Continuity's culling fix and 3D Default both replace
the same two vanilla glass-pane models, so one of them had to sit above the other. Continuity does,
which keeps connected glass culling correctly at the cost of flat panes.

*Actually 3D Blocks & Items* declares support only to resource format 84 and 26.2 is 88, so it ships
in the acknowledged-incompatible list. Without that entry Minecraft drops it on first launch.

**The updater no longer edits your resource pack list behind your back.** It carried the 1.21.1
pack's migration wholesale, which ran on **every launch** and added `file/Enhanced Grass V1_4.zip` —
a pack this line has never shipped — to `options.txt`, anchored to the position of Fancy Crops.
Minecraft drops a selected pack it cannot find, so nothing broke visibly, but it had been writing
that row since v1.0.0. **v1.0.0 was this line's first release; there was never anything to migrate.**
Removed entirely, along with the four container packs and the Nature X remap it also carried.

**Server-side, not shipped through the channel.** The multiplayer list showed a screenshot of the old
world instead of the pack icon. `MinecraftServer.loadStatusIcon()` reads `server-icon.png` from the
server root and falls back to the world's own `icon.png` when it is absent — and there was no
`server-icon.png`. There is now.

---

## v1.0.1

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `6fe2b134898ec273` | `d3dbe17a78672dc8` | 245 | 106 |

**You can talk to each other now.** Simple Voice Chat was running on the server and was missing from
the client, so nobody could hear anybody. It ships to clients from this release, on UDP **27108**,
48 blocks of range and 24 for whisper.

**Nothing else about the pack changed.** The integrity helper is rebuilt only because the pack
version is compiled into it — `PACK_VERSION` is a compile-time constant, so javac inlines it into
`SyncManifest` as well, and a helper left on `1.0.0` would refuse to parse a `1.0.1` manifest and
lock everyone out. That is the failure this line exists to avoid, not a new feature.

**Updating is clicking Play.** Nothing to re-import.

**Server-side, not shipped through the channel.** Two things were wrong on the server and are now
fixed. It was running a Vanilla Refresh build from two commits before the play-tested values were
adopted, and had written its own config from *that* jar's defaults — 22 settings wrong, including
death souls and the death message switched off. And the singleplayer world upload brought its Voxy
generation cache with it: 565,452 chunks marked already-generated, so nothing near a player ever
loaded, so no distant terrain was ever sent. Voxy streams LOD on chunk **load**, and its backfill
only sends chunks already in memory. Deleting that cache lets the generator re-walk from the player
outward, reading chunks off disk rather than regenerating them.

---

## v1.0.0

| Date | Commit | Manifest digest | Files | Mods |
| --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `d3dbe17a78672dc8` | 244 | 105 |

> **This entry was corrected on 2026-08-29.** It first recorded `a1d49ddb7f12884c` / 240 files / 103
> mods, and v1.0.0 was then published three more times on the same version number — to ship the
> `prism/mmc-pack.json` that blocked launch, to add the integrity helper, and to remove ore glow from
> both shaders. The row above is what players actually ended up on. **This is exactly what the
> one-publish-per-version rule exists to prevent**; from v1.0.1 a fix after release is a patch bump.

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
