# Changelog

One entry per **published** release. An entry means this reached players — never write one for a
build that was not published.

---

## v1.0.25

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-31 | see below | `592006cd06c62322` | `ce533358b06bf4ca` | 276 | 128 |

**Aircraft controls work with a screen open.** Confirmed in game on a gyrodyne.

### It was never a screen list

v1.0.19 and v1.0.20 approached this as "which screens should allow movement", and that was the
wrong question - the aircraft never asks InvMove anything. `KeyBindings` picks between two entirely
different control systems on one flag, `useCustomKeybindSystem`:

- **true**, the mod's default: the aircraft builds its **own** key objects,
  `key.immersive_aircraft.multi_control_*`, and `VehicleEntity.tickPilot` polls those directly.
  InvMove has never heard of them, so nothing it does can help.
- **false**: those same bindings delegate to `options.keyUp / keyLeft / keyJump / keyShift` - the
  vanilla movement keys, which are exactly what InvMove already drives while a screen is open.

The pack never shipped this config, so everyone got `true`. It now ships with `false`. Defaults are
identical either way, which is why nothing else changes - and it explains why boats and walking
always worked: those *are* vanilla keys.

### Classified `player`, and that is what makes it reach people

The same file carries genuine preferences - third person, trails, render distance - so hash-enforcing
it would stop a player turning trails off. It is not `support` either, which would restore it on
every sync.

**"Published once, preserved forever" starts at the first delivery**, so a player-class file that
already exists is still replaced the one time the pack begins publishing it. That is what carries
this to everyone already playing - and it means a player's own Immersive Aircraft settings are
replaced on this update, once.

That behaviour is now pinned by a test. `Test-LocalSync` plants the mod's default in the instance
before syncing and asserts the published copy replaced it; the opposite reading - that an existing
file is never touched - would have meant this fix silently missed every current player, and a fresh
instance cannot tell the two apart. A seed written on that wrong assumption was removed rather than
left in as dead belt-and-braces.

**Players need only click Play.**

---

## v1.0.24

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-31 | see below | `ce533358b06bf4ca` | `5fa65eb35b61f409` | 275 | 128 |

**The client cache sweep runs again, for the second world wipe.**

v1.0.20 cleared `.voxy` and `xaero/world-map` because the world had been regenerated. The world was
then cleared a second time for v1.0.23's structure spacing - and the sweep did nothing, on every
instance, because it is one-time per token and every instance already held v1.0.20's marker. So
Voxy kept drawing far terrain, and Xaero kept drawing map tiles, for a world that no longer exists.

The token is now `retired-files-v1024`. Waypoints are untouched, as before.

### The comment was half the bug

It said the token is bumped *whenever an entry is added to the list*, and that is what was done -
the list had not changed, so nothing was bumped. But both entries are caches **describing terrain**,
so they go stale every time that terrain is replaced, list unchanged. The comment now says so.

### The test could not have caught it

`Test-LocalSync` sweeps a fresh instance, which has no marker, so the sweep always fired there and
always passed. It now plants every token the sweep has ever written before syncing, so a release
that reuses a token fails instead of shipping. Confirmed by planting `retired-files-v1024` as well
and watching it fail with exactly the symptom players would have had.

`Test-DedicatedServer` was not re-run: nothing server-side changed but the helper's version stamp,
and the deploy verifies that by hash.

**Players need only click Play** - the sweep names each cache and shows its progress.

---

## v1.0.23

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-31 | see below | `5fa65eb35b61f409` | `7e776ae95cd7cbf5` | 275 | 128 |

**Structures go to spreadFactor 7, and this time the server gets the file.**

### The server had never been running the pack's value

`config/sparsestructures.json5` shipped `spreadFactor: 5` from v1.0.20, and the live server ran at
**2** the whole time - the mod's own default, which it wrote itself on first boot because nothing
ever deployed the file. v1.0.20 deployed ten jars and no config. `Deploy-LiveServer` now takes a
`-Config` list, hash-verified with the rest; the same sweep found `bcc-common.toml` on the server
still reading `v1.0.0`, twenty-two releases stale.

So the crowding that prompted this was real, and it was 2 rather than a failure of the mod.

### It does reach modded structures

Read out of the jar: `MakeStructuresSparseFabric` hooks the datapack resource loader and rewrites
`spacing` and `separation` for **any** resource under `worldgen/structure_set`, in any namespace,
skipping only `minecraft:concentric_rings` so strongholds keep their ring. Every structure mod here
ships its sets as JSON - Towns and Towers 3, Structory 5, Structory: Towers 5, Incendium 3,
Nullscape 3, Better End 12 - and Cristel Lib feeds its configured placements in as a generated
datapack, through that same loader. Nothing is bypassing it.

What made modded structures look untouched is that their base spacings are far tighter than
vanilla's: Structory's quiet ruins sit at 23 chunks against a village's 34, so at a factor of 2 they
were 736 blocks apart. At 7 they are about 2,600, and villages about 3,800.

### Also

**Spyglass Zoom 2.4.0** - scroll to zoom while holding a spyglass. Client-only, no dependencies, so
the server does not carry it.

**Players need only click Play.** The new spacing applies to chunks generated from the restart
onward, which is why it goes out against a freshly cleared world.

---

## v1.0.22

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-31 | see below | `7e776ae95cd7cbf5` | `ce4e93bcc5a33627` | 274 | 127 |

**Buckets are 3D.** Neither of the two 3D packs in this list contains a single bucket model -
checked both, zero matches each - so buckets stayed flat while the blocks and items around them did
not. **Refined Buckets 2.4.1** covers all twelve vanilla buckets and sits directly after the two 3D
packs, which is above them: later in `resourcePacks` wins.

Of the pack's eight overlays only `26-1` has any content at 26.2's resource format of **88** - four
core shader files. `21-5-FA` and `Polytone` are declared for this range but ship nothing, so there
is no Fresh Animations or Polytone interaction to reason about.

**This restates the whole resource pack row**, under a new token, because `resourcepacks-v1010` has
already fired everywhere and a seed sets a row rather than editing it. A player who had reordered
their own packs gets this order back once.

### It also finishes v1.0.21's server half

v1.0.21 reached the channel but its policy never reached the server: the server came back up between
the push and the deploy, so for a while the channel served v1.0.21 while the server still demanded
v1.0.20's digest, and any client that relaunched was refused at login. This release's policy is
deployed in the same sequence as its push, which is what should have happened there.

Nothing to do beyond clicking **Play**.

---

## v1.0.21

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-31 | see below | `ce4e93bcc5a33627` | `8088a08e154808db` | 273 | 127 |

**World Weaver's first-run screen is answered before anyone sees it.**

v1.0.20 brought World Weaver in as a Better End dependency, and it greets every player once with a
full-screen setup page holding three checkboxes. Nobody should have to read it, and one of its
defaults is worse than it looks: **"Check for new versions and notify" is on out of the box, and by
its own description it sends the player's IP address to the mod author's server and keeps it in
their logs for four weeks.** This pack updates through its own channel and has no use for it.

`config/wover/client.json` now ships with all three answered - version check **off**, BetterX world
type **off**, experimental warning left visible - and `did_present_welcome_screen` already true, so
the screen never opens.

### The BetterX world type is not needed here

It is only consulted when a world is *created*, and players join a server rather than making one.
The server does not need it either: the boot log on a `level-type=minecraft:normal` world - which is
what the live server runs - shows `Created WoverChunkGenerator with WoverEndBiomeSource`. BCLib
installs the biome source that carries Better End's biomes regardless of world type.

### Classified `player`, not `support`

The welcome screen writes this same file the moment it is answered, and all three are ordinary
settings reachable from Mod Menu. As `support` it would be restored on every sync, so a player who
changed one would find it changed back - the fault `config/voxy-config.json` was moved out of
`support` for. Published once, then theirs.

Proved rather than assumed: a real client launch leaves the file byte-identical, and the version
checker's own `cached.json` records `"last_check_date": "never"`.

Nothing to do beyond clicking **Play**.

---

## v1.0.20

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-31 | see below | `8088a08e154808db` | `9ae1eb921365cd18` | 272 | 127 |

**New worldgen in all three dimensions, and the world was reset around it.** This is the largest
release of the line and the only one so far that needed the world edited rather than the pack.

### The End: Nullscape for terrain, Better End for biomes

Nullscape overwrites `data/minecraft/dimension/the_end.json` and the End noise settings; Better End
registers its biomes through BCLib and lets BCLib swap the End's biome source at world load. Read
out of both jars: Nullscape ships 11 biomes and a `minecraft:multi_noise` source that BCLib then
replaces, and the boot log shows `Created WoverChunkGenerator with WoverEndBiomeSource` over
Nullscape's `minecraft:end` settings. The two do not fight — they occupy different halves of the
same dimension, which is why Nullscape's own page names Better End as its one compatible End mod.

Better End brings **BCLib** and **World Weaver** with it (WunderLib is nested inside World Weaver).

### Nether and overworld

**Incendium** for the Nether. **Towns and Towers**, **Structory** and **Structory: Towers** for
overworld structures, with **Cristel Lib** as their config library. **Sparse Structures** at
`spreadFactor 5` thins every structure set at once, so three structure mods stacked on vanilla's
spacing do not turn the surface into a theme park.

### Shipwreck treasure maps could come back blank

Vanilla's `ExplorationMapFunction` returns the map unmarked rather than failing when no structure is
in range, and its default `search_radius` is **50 chunks**. Tectonic's continent scale pushes
shipwrecks much further from land than vanilla assumes: the measured case was 17 by 59 chunks from
its treasure — outside the box, and invisible as anything but an empty map. `nbidal18-tectonic`
raises the radius to 100, which had 41 chunks of margin on that case.

### Movement, and a coordinate leak

Movement now continues in the Immersive Aircraft screens and the Traveler's Backpack screen. The
aircraft screens needed a second mechanism, not a longer list: the mod reads its own `KeyMapping`
objects for pitch and roll, which stay unpressed while a screen is open however InvMove answers, so
`nbidal18-invmov` now also forces the aircraft's own control keys through. Typing still wins.

Xaero's **Show/Hide coordinates** button on the waypoint dialog is greyed out and locked to hidden.
It was a one-click reveal of any waypoint's exact position to everyone.

### The client clears two caches on update

Voxy's far-terrain cache and Xaero's world-map images both describe terrain this release
regenerates, so the updater deletes `.voxy` and `xaero/world-map` once, **naming each one and
showing its progress** rather than stalling silently on several gigabytes. **Waypoints are not
touched** — `xaero/minimap` is left alone, and a test plants a waypoint and asserts it survives.

### A guard against publishing a version twice

`Build-Release.ps1` now refuses to build a version that already has an entry in this file. Three
builds this line went into an already-published version and had to be restored from git. It caught
this release's own first attempt, where the entry was written before the last code change moved
the digest.

**Players need only click Play.** The world's outer chunks, the Nether and the End were deleted
before this release, so everything beyond the explored area generates fresh with the new worldgen.
Built areas, inventories and waypoints are untouched.

---

## v1.0.19

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-30 | see below | `9ae1eb921365cd18` | `70e40a714e2d84a1` | 261 | 117 |

**Movement now continues in a plane's inventory and in Xaero's full-screen map.**

### The config for this has never worked

InvMove has a per-screen list, `config/invmove/unrecognized.json`, and setting a screen to `true`
there does nothing. `InvMove.allowMovementInScreen` asks every registered module first and consults
that map only if all of them returned `PASS` - and read out of the jar, `VanillaModule` returns
`SUGGEST_DISABLE` on six paths and `SUGGEST_ENABLE` on one. It never returns `PASS`, so a module
answer is always present and the map is never reached.

The evidence was already in the pack: **`"xaero.map.gui.GuiMap": true` shipped in v1.0.0 and has
never once worked.** Eighteen releases of a setting that cannot take effect. v1.0.18 added
`immersive_aircraft.client.gui.VehicleScreen` to the same file, copying a pattern that was already
dead rather than testing the mechanism.

### Said as a module instead

`nbidal18-invmov` gains a second module returning `Movement.FORCE_ENABLE` for those two screens.
`FORCE` outranks `SUGGEST`, which is the same mechanism the artefact's JEI half already relies on in
the opposite direction.

**Typing still wins.** A focused `EditBox` returns `PASS` and hands the decision back to InvMove's
own text-field rule, so Xaero's map search does not walk the player - the exact fault the JEI half
exists to prevent, and easy to reintroduce here. Each screen is a separate toggle in InvMove's
config screen, because that guard sees vanilla text widgets and a mod drawing its own would slip
through it.

### Two guards fired while building this

`build_invmov.py` refused a five-class jar when it expected four, and `Test-ClientLaunch` failed
because the log line it asserts had been reworded. Both exist because v1.0.10 shipped this same
artefact silently doing nothing. The required line now names both modules, so losing either one
fails the build rather than shipping half a bridge.

Nothing to do beyond clicking **Play**.

---

## v1.0.18

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-30 | see below | `70e40a714e2d84a1` | `54ef3fd20909399a` | 261 | 117 |

**Two things wrong with the aircraft, both reported from a screenshot.**

### The vehicle screen drew no items at all

Open a plane's inventory and every slot was empty - the vehicle's slots *and* the player's - while
the panel and the slot outlines drew correctly.

The port mapped 1.21's `renderBg` onto `extractContents`. Wrong method. In 26.2 `extractContents`
is the **whole content pass**: it calls `Screen.extractRenderState`, `extractLabels`,
`extractSlotHighlightBack`, **`extractSlots`** and `extractSlotHighlightFront`. Overriding it
without calling super drew the background and then nothing else, which is exactly what a screen full
of empty slots looks like.

`renderBg`'s actual replacement is **`extractBackground`**, which is what vanilla's own
`ContainerScreen` and `HopperScreen` override - and they call `super.extractBackground` first,
because that is what draws the dimmed backdrop behind the panel. Fixed to match.

**A method that still exists under a plausible name is worse than one that was deleted.** The
compiler was happy, the screen opened, and only the items were missing.

### Movement stopped while a plane's inventory was open

The 1.21.1 pack solved this and it was never carried over. It is not code - InvMove reads
`config/invmove/unrecognized.json`, and the entry is one line:

```json
"immersive_aircraft.client.gui.VehicleScreen": true
```

`nbidal18-invmov` is untouched. It exists to stop InvMove walking the player while they type in
JEI's search box, and a per-screen movement rule is a setting the mod already has - adding it to the
jar would have put an unrelated fix in an artefact named for something else.

Nothing to do beyond clicking **Play**.

---

## v1.0.17

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-30 | see below | `54ef3fd20909399a` | `449107b924ed127b` | 261 | 117 |

**Two fixes for things v1.0.16 broke, backpacks, and shipwreck maps that resolve.** Both faults were mine.

### Shipwreck treasure maps could not resolve

Vanilla's `chests/shipwreck_map` sets no `search_radius`, so `exploration_map` uses the default of
**50 - in chunks, 800 blocks**. Find nothing and it returns the stack unchanged, which is still a
blank `minecraft:map`: no message, no log line, and a chest that looks like it gave you loot. Half
of all shipwrecks are the open-ocean variant while buried treasure only generates on beaches.

That default was tuned for vanilla oceans. Tectonic ships `continents_scale 0.13` and
`ocean_offset -0.8` - checked against `ConfigState$Continents.DEFAULT` in the jar, so they are its
own shipped values and not something this pack chose - and those oceans are far larger.

Measured rather than argued. The owner's shipwreck at chunk `-88, 56`, nearest buried treasure at
chunk `-105, -3`:

```
offset  17 by 59 chunks       972 blocks
50-chunk box   outside, on the z axis alone
100-chunk box  inside, with 41 chunks to spare
```

`nbidal18-tectonic` widens it to **100**, which is what vanilla itself uses for the woodland mansion
map. Named for Tectonic and not for the loot table it edits: the reason it exists is Tectonic's
terrain, so if Tectonic ever leaves, this must leave with it.

The table is read out of the game jar and edited at build time, never copied in - a hardcoded copy
goes stale the first time Mojang touches it and nothing says so. The builder asserts vanilla still
has exactly one `exploration_map` function and still sets no radius of its own.

It is the pack's first **data-only** first-party artefact, so `Build-FirstPartyMods.ps1` now skips
the compile step for a mod with no `src\`.

### Traveler's Backpack

The 1.21.1 pack had **Inmis** and **InmisAddon**; neither has a 26.2 build and Inmis upstream has
not been touched since September 2024, so a port was the only way to keep them. That turned out to
be a much larger job than it looked: unlike Immersive Aircraft, which was Mojang-named through
Architectury, Inmis is written against **Yarn**. Its whole source needs translating before any 26.2
work starts - 926 errors across 28 files, 102 distinct missing symbols - and the backpack is drawn
on the player's back through a `FeatureRenderer`, which is the single most-rewritten corner of 26.2.
Its addon draws with `Tessellator` and `BufferBuilder`, which 26.2 deleted outright.

Traveler's Backpack does the same job, is native to 26.2, and is maintained. It brought
`forgeconfigapiport` with it as a **required** dependency that was in neither the client pack nor
the server - the same half-installed shape v1.0.15 shipped - so both jars go to both sides.

### A launch check that was right to complain

`Test-ClientLaunch` failed this release on twelve `Missing texture references in model` warnings,
the pattern that exists because of v1.0.7. Checked against the jar rather than waved through: of the
89 models under `travelersbackpack:block/`, **76 are referenced** by a blockstate, item model or
parent chain and **13 are not** - and every one of the 13 is a `backpack_*` file, while not one
referenced model starts with `backpack_`. The mod's renderer loads that geometry itself, so none of
it goes through the model registry.

So the check gets a per-pattern `Except`, scoped to exactly `travelersbackpack:block/backpack_`. It
stays live for the other 76 models and for every other mod. v1.0.7's fault was the opposite case -
models that were in use and untextured - and that is still caught.

### The hotbar could not hide

v1.0.16 put the aircraft overlay inside `AutoHudRenderer.wrap` so it would fade with the hotbar.
That call is built for Auto HUD's own elements and it drives global state: `startRender` sets
`inRender` and `AutoHudGuiItemRenderState.IS_HUD_ITEM`, and `endRender` clears both
unconditionally.

The overlay's entry point is injected at the **head** of `Hud.extractItemHotbar` and runs on every
frame whether or not you are in an aircraft. So that begin/end pair ran *before* vanilla drew the
hotbar, and `inRender` was already false by the time it did.

Auto HUD fades the HUD through two independent paths. `GuiGraphicsExtractorMixin` wraps `fill`,
`blit` and `text` and applies transparency **only while `inRender` is set** - that is the slot
frames, the durability bars and the stack counts. The item icons go through
`GuiItemRenderStateMixin` and `HudMixin.autoHud$skipItemRendering`, which do not read `inRender` at
all.

So in the hidden state the icons disappeared correctly and **the hotbar itself stayed on screen at
full opacity**, because the only path that could have faded it had been switched off. It affected
everyone, all the time, not just while flying.

It now only **reads** Auto HUD - whether the hotbar is hidden - and touches nothing Auto HUD relies
on. The overlay appears and disappears with the hotbar instead of cross-fading with it. Matching the
fade curve means threading an alpha through every draw call in the overlay, which is worth doing on
its own and not as part of a regression fix.

**No check here could have caught it.** `Test-ClientLaunch` passed on the broken jar, because the
title screen never draws a hotbar. A HUD rendering fault is invisible to every gate this pack has
and needs a play-test.

### Voxy's render distance was 32x too far

v1.0.16 seeded `section_render_distance: 32.0`, described in its changelog as a tuned value
replacing a `1.0` that "renders almost nothing and looks broken". That was wrong on both counts:
the field is not a chunk count, and at `32.0` the owner's client reported a render distance of
**1024**. `1.0` was correct all along and is what the pack shipped from v1.0.0 until v1.0.16.

Back to `1.0`, under a fresh seed token - v1.0.16's marker has already been written on every
instance that updated, and a seed never fires twice under the same one. Voxy stays **off** by
default, which was the actual intent.

Nothing to do beyond clicking **Play**.

---

## v1.0.16

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-30 | see below | `449107b924ed127b` | `86b41dd370202a81` | 258 | 114 |

**Immersive Aircraft, ported to 26.2 here**, gated behind engine tiers so it sits around the elytra
rather than before it. Plus an Auto HUD on/off switch that existed all along, and a keybind clash
every fresh install has had.

### The port

Upstream has no 26.2 build and has not done 26.1 either, so this is a source port, not a jar patch:
`nbidal18-immersiveaircraft`, source in `5. modpack source\custom mods`. 298 compile errors across
174 files, but only 25 distinct causes - the mod was already written against 26.x's render-state
model, so most of it was renames.

The one real deletion: **`MultiBufferSource` is gone.** Geometry is submitted as a deferred callback
now instead of written into a shared buffer. Rather than turn thirty method signatures inside out, a
shim records the writes and replays them through `submitCustomGeometry`, under an identity pose
because this mod bakes its own model matrix into every vertex.

**The compiler proves none of the mixins.** `GameRenderer.bobHurt` still exists by name but lost its
partial-tick argument, and the client crashed on first launch because `javap` on the *name* said it
was fine. Every mixin target had to be checked by descriptor.

### Engine gates

| Aircraft | Engine |
| --- | --- |
| gyrodyne | none |
| airship, quadrocopter, bamboo_hopper | `eco_engine` |
| cargo_airship | none - built from an airship, so it inherits that gate |
| biplane, warship | `nether_engine` |

Both engines are crafting components now rather than upgrades: their upgrade definitions and their
entries in the `upgrades` item tag are gone, because that tag is what the upgrade slot accepts and
leaving them would let a player insert an engine that no longer does anything. Steel boiler is the
only engine upgrade left.

### Auto HUD

The aircraft overlay is drawn from a mixin inside `Hud.extractItemHotbar`, which Auto HUD cannot see
- it finds modded elements through registered HUD layers. It drew at full opacity over a hotbar that
was fading out. It now goes through `AutoHudRenderer.wrap`, the same call Auto HUD uses for its own
elements, so it takes the hotbar's exact alpha and offset.

**The global on/off already existed.** `Hud.toggleHud()` turns the whole mod off and the HUD goes
back to drawing vanilla - it just shipped bound to nothing, so nobody found it. Now on **H**.

### Defaults seeded once

`options.txt` and the two config files below are player-owned, so these are `PlayerFileSeed` rows:
written once, and yours from that moment on.

| Setting | Value | Why |
| --- | --- | --- |
| `key_identifier.autohud.toggle-hud` | `H` | The switch above, which shipped unbound |
| `key_key.mute_microphone` | `L` | **Simple Voice Chat registers mute on GLFW 77 - M - and Xaero opens the map on M.** Every fresh install had both on one key, and neither mod can know about the other |
| `soundCategory_master` / `_weather` | `0.2` / `0.5` | The owner's mix, shipped as the pack's |
| `minecraft:mount_health_bar` `alwaysHidden` | `true` | |
| Voxy `enabled` / `section_render_distance` | `false` / `32.0` | Off by default - its far terrain is the heaviest thing here on a weak machine. The distance still moves so anyone who turns it on gets a tuned value rather than the shipped `1.0`, which renders almost nothing and looks broken |

### Immersive Optimization

An entity tick scheduler: it gives each entity a tier from its distance to the nearest player and
ticks it every Nth tick instead of every tick. Read from the bytecode rather than the description,
because the defaults are what decide whether it costs anything here:

| Default | Value | What it means |
| --- | --- | --- |
| `enableBlockEntities` | **false** | Hoppers, furnaces and brewing stands are untouched |
| `optimizeForceLoadedChunks` | **false** | Chunk-loaded farms are exempt |
| `minDistance` | 6 | Anything within 6 blocks always ticks fully |
| `blocksPerLevel` | 64 | One tier per 64 blocks when a player is tracking it |
| tracking / viewport culled | 10 / 20 | Far steeper for entities nobody is tracking or looking at |
| blacklist | players, ender dragon, ender pearls, `#minecraft:arrows` | Never throttled |

At `simulation-distance=8` nothing beyond 128 blocks ticks at all, so the band this can affect is
narrow - which is the reasoning the owner gave when the mod came up, and it holds. It overlaps with
nothing installed: Lithium optimises the work inside a tick, C2ME optimises chunk IO and worldgen,
and ServerCore's `dynamic` block does a blunter version of this but ships disabled.

Six of its seven mixins target `ServerLevel`, `MinecraftServer` and `EntityTickList`, so it is
**server-side work** and does nothing useful client-only. It writes its own config at runtime; the
pack ships none, so the defaults above are what apply.

### A test that could not have caught this

`Test-DedicatedServer` only ever *replaced* jars the server already had, so a release that **adds** a
server-side mod booted without it and passed - the same shape as v1.0.15's half-installed dependency
chain. It takes `-AddMods` now. Inferring it from each jar's `environment` was tried first and is
wrong: most of this pack's client-only mods declare `"*"` too, and it put Iris Extension on a server
with no Iris.

Immersive Aircraft and Immersive Optimization are both **new server-side mods**, so both were
uploaded by hand - `Deploy-LiveServer` deliberately will not add a jar the server does not already
have.

Nothing to do beyond clicking **Play**.

---

## v1.0.15

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-30 | see below | `86b41dd370202a81` | `15abbe137cc86b1a` | 256 | 112 |

**VinURL and Immersive Paintings**, both back from the 1.21.1 pack. Both had native 26.2 Fabric
builds, so neither needed porting.

### Five jars, not two

Both declare `environment: "*"`, so both belong on the server as well as the client - and they bring
a dependency chain that was only half-installed:

```
vinurl              -> owo-lib                    not in the pack at all
immersive_paintings -> fzzy_config                present client-side, absent on the server
fzzy_config         -> fabric-language-kotlin     the same
```

`Test-DedicatedServer` caught the second link by refusing to boot - the loader stopped with
`HARD_DEP_NO_CANDIDATE` on `fabric-language-kotlin` rather than starting. That is the exact gap a
side audit had flagged days earlier as a curiosity: Fzzy Config declares itself server-required and
was sitting client-side only. It stayed harmless until something server-side depended on it.

### What VinURL does, for the record

Each **client** downloads `yt-dlp`, `ffmpeg` and `ffprobe` from GitHub - about 180 MB - and runs
them as subprocesses to turn a URL into playable audio, auto-updating to whatever "latest" is. The
**server never does**: `ServerEvent` and the common class do not touch the runner, they only relay
the disc data. Worth knowing before a new player joins, not a reason to avoid it.

Nothing to do beyond clicking **Play**.

---

## v1.0.14

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-30 | see below | `15abbe137cc86b1a` | `5bb9cf7186a29e02` | 253 | 109 |

**You can land a fish from a dock now.**

### Better Fishing's landing distance

A catch lands when the hook comes within `LANDING_DISTANCE` of the player, and that distance is
measured in three dimensions. Upstream sets it to **2.35 blocks**, which is unreachable from a dock:
standing two blocks above the water puts the floating hook at least two blocks away vertically
before any horizontal distance is counted. The fight could never finish.

Worse, nothing said so. Progress is deliberately clamped to 96.5% while the hook is further away
than the landing distance, and landing is a pure distance test - so the bar sits just short of full
for ever and there is no feedback that the spot is unwinnable.

The fork raises it to **4.5 blocks**, which covers a dock or pier three to four blocks above the
water. It is not a setting: the mod's only options are difficulty and three sound toggles, and this
is a `private static final double` that javac inlined into the constant pool. Rewriting that one
pool entry moves all four use sites at once.

One consequence: the fight is about 20% shorter on a long cast, because progress is normalised over
`startDistance - LANDING_DISTANCE`.

**This is server-side.** The landing test runs in the server's copy of the mixin.

### Fishing Rod Fix removed

It changed nothing in play. It is client-only, and the fishing behaviour that matters is decided on
the server.

Nothing to do beyond clicking **Play**.

---

## v1.0.13

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-30 | see below | `5bb9cf7186a29e02` | `146ae8ca9020a032` | 254 | 110 |

**Fishing works now, and the Soul Charm can be found by name.**

### Better Fishing never ran on the server

Fishing had stayed vanilla since the mod was added. Its Fabric build declares
`"environment": "client"` and one `ClientModInitializer` - and that single client entrypoint is
where it registers its *serverbound* payload types and its `ServerPlayNetworking` receivers. A
`ClientModInitializer` never runs on a dedicated server, and the environment flag stops the mod
loading there at all. So the server never handled the reeling or catch packets and resolved fishing
with vanilla logic: the minigame drew on the client and changed nothing. Copying the jar across
would not have helped - the loader honours the flag.

`nbidal18-betterfishing` sets the environment to `*` and adds a `main` entrypoint carrying exactly
the registrations that were stranded, transcribed from upstream's own lambdas so both sides keep
agreeing about what a packet means. It does nothing on a client, where the mod's own initializer
still runs.

**This is a new mod on the server**, not just an updated one.

### The Soul Charm is findable

v1.0.12 registered it, which fixed the icon and the name but not the search. JEI's list is built
from the creative mode tabs, not the item registry, so an item in no tab is in no list. It now joins
Tools & Utilities, and typing "soul" finds it.

### Also

**Fishing Rod Fix** added, client-side only. **Fishing Real** was considered and dropped - Better
Fishing already renders the caught fish on the hook, which was the reason to want it.

A side-audit compared every jar's declared environment against where it actually is: 45 client-only
mods are correctly client-only and nothing is on the server that should not be. Better Fishing was
invisible to that check because it *declares* itself client-only - the mismatch was between what it
says and what it contains.

Nothing to do beyond clicking **Play**.

---

## v1.0.12

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-30 | see below | `146ae8ca9020a032` | `f909b2ad8cec33a2` | 253 | 109 |

**The Soul Charm is a real item, and Xaero is down to the map and its pins.**

### The Soul Charm

Hardcore Revive+ is a datapack in a mod wrapper - 129 data files and zero classes - so its Soul
Charm was a ghast tear wearing an `item_name` component. It could not be told apart from a ghast
tear in a chest, could not be found in JEI by name (JEI's list is the item registry, and no such
item was in it), and could not be given a texture without retexturing every ghast tear in the game.

The fork now carries Java and registers `hcrplus:soul_charm`: its own name, its own 3D vial, gold
contents taken from the Totem of Undying's palette. Ghast tears go back to looking like ghast tears.

**Revival is unchanged.** The datapack finds a dropped charm by its `custom_data {Revive:1b}`
component and not by item id, so any charm crafted before this release still works, and the refund
path clears both forms.

### Xaero: the full-screen map and pins, nothing else

Two new first-party mods, one per target.

Removed from the map's right-click menus, because **none of these are settings** - "Share Location
In Chat" posts coordinates as hover text and has no config at all:

```
Share Location In Chat        Teleport Here
Share Waypoint In Chat        Teleport to Waypoint / to Player
```

Cave mode, nether cave mode and the entity radar are refused through Xaero's own server-rules path,
so the mod greys them out and explains why rather than fighting a setting. Three further settings
are now pinned: waypoint coordinates hidden, tracked players not drawn in the world, server chunk
radius off.

Nothing a player has to do beyond clicking **Play**.

---

## v1.0.11

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-30 | see below | `f909b2ad8cec33a2` | `6f970dd0e8673e2c` | 251 | 107 |

**Player nametags are off**, and a latent lockout that shipped since v1.0.0 is fixed.

### Nametags above players are hidden

`config/sodium-extra-options.json` now ships `player_name_tag: false`. Sodium Extra's
`MixinLivingEntityRenderer` injects into `LivingEntityRenderer.shouldShowName` and forces `false`
when the entity is an `AbstractClientPlayer` and that option is off, so the name is not drawn at any
distance or through any wall - it is not a fade, the tag is simply never submitted.

The file is a `support` config, so the updater restores it on every sync: a player who switches
names back on in Video Settings gets them hidden again at the next launch. Say so if it should
instead be a default players can keep changing - that is a one-word reclassification to `player`.

### The manifest fix

`shaderpacks/nbidal18-§lE-LITE shaders 5.1.1.zip.txt` was listed in the preserved set with its
section sign encoded twice - `0xC2 0xA7` where the published file has `0xA7`. The updater matches
that list exactly, so the file was never recognised as player-owned and was hash-checked like any
managed file.

**The effect: selecting the E-LITE shader pack disconnected you from the server.** Iris writes that
settings file the moment the pack is applied; the file was being hash-checked like any managed file,
so `RuntimeIntegrityMonitor` saw a managed file change mid-session and pulled the player off the
server:

```
[00:47:43] Using shaderpack: nbidal18-§lE-LITE shaders 5.1.1.zip
[00:47:45] [nbidal18-integrity-scanner/WARN]: Runtime modpack integrity failure:
           modified managed file: shaderpacks/nbidal18-§lE-LITE shaders 5.1.1.zip.txt
[00:47:46] Client disconnected with reason: Modpack integrity change detected.
```

**Only E-LITE.** The other shader pack's settings file is pure ASCII, so its `localAllowed` entry
always matched and switching to it was always fine. The one path in the pack with a non-ASCII
character was the one that was broken, which is why this survived ten releases.

The cause: `Build-PackwizSite` read `config-classification.json` with `Get-Content`, which in
Windows PowerShell 5.1 decodes as the system ANSI codepage rather than UTF-8. Paths taken from the
filesystem were right; paths taken from that file were not. It affected exactly one path - the only
one in the pack with a non-ASCII character.

Found by a test written the same day, on its first run.

---

## v1.0.10

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `6f970dd0e8673e2c` | `6ea9ab20d5a99d64` | 251 | 107 |

**The JEI search fix actually works this time.** v1.0.9 shipped `nbidal18-invmov` doing nothing at
all. The mod loaded, registered its module with InvMove and logged success - and JEI never handed
over its runtime, so every question about the search box answered "no".

**On Fabric, JEI finds plugins through the `jei_mod_plugin` entrypoint**, not the `@JeiPlugin`
annotation, which is the Forge mechanism. `fabric.mod.json` declared only `client`. The entrypoint
is declared now, the mod logs an error at startup if it ever goes missing again, and the build
refuses to package a jar whose declared entrypoints are not all present.

**Life Jam is uncraftable, not merely disabled.** `mnc_lifeJam 0` turned the effect off from v1.0.0,
which is what was promised - but the recipe stayed in the datapack, so JEI listed it and it could
still be crafted: a honey bottle costing a **totem of undying** that then does nothing. Worse than
leaving the feature on. The recipe is gone, along with the two advancements whose only criterion was
unlocking it - left behind they would name a recipe that no longer exists and fail to load.

**Waypoints stay on the map.** They were also drawing in the world as floating markers.
`waypoints_in_world` is what `WaypointWorldRenderer` reads, so it turns off the in-world markers and
leaves the map untouched. Seeded once, then yours - and Xaero already binds a *Toggle In-World
Waypoints* key if you want them back.

---

## v1.0.9

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `6ea9ab20d5a99d64` | `f4d5905c3e4b870e` | 251 | 107 |

**Typing in JEI's search box no longer walks you around.** New first-party mod, `nbidal18-invmov`.

InvMove has a setting for exactly this - *text field disables movement* - and it could not work with
JEI. InvMove's check walks **the screen's own widget children** for a text box that is visible,
active and accepting input. JEI draws its ingredient overlay outside that list and routes input
itself, so there was nothing for InvMove to find, and the inventory screen is deliberately set to
allow movement. Typing `www` into the filter walked you forward.

**It is a bridge, not a patch.** InvMove publishes `registerModule(Module)` for this, and JEI
publishes `IIngredientListOverlay.hasKeyboardFocus()`. Both halves are public API, so a breaking
change upstream is a compile error rather than a mixin that quietly stops applying. The behaviour is
a toggle in InvMove's own config screen for anyone who would rather keep walking.

JEI's recipe screen needed nothing: it is a real screen, so InvMove already recognises it.

**Actually 3D is the clean upstream pack again, above 3D Default.** v1.0.8 shipped it with 45 models
stripped - the ones referencing a `#missing` texture variable. That list included crops: beetroot
and potato stages, sweet berry bushes, torchflower, and several plants. **Removing them took 3D
crops away**, which was not worth whatever those models were doing wrong. The upstream zip is back
unmodified and sits above 3D Default, so its models win.

---

## v1.0.8

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `f4d5905c3e4b870e` | `19df306ff3d3236d` | 250 | 106 |

**The world map works.** It has been black since v1.0.0, and the pack was the reason.

`load_new_chunks` was pinned to `false` from the start, on the belief that it revealed terrain the
player had not visited. It does not. It is read inside **`MapWriter`**, and it is the switch that
records chunks onto the map at all - so the map never wrote anything, in any world, for anybody.
Xaero's never showed unexplored terrain in the first place: it maps only the chunks a client
actually loads, which is exactly what the player can already see. There was nothing to prevent.

The pin is gone, the shipped default is `true`, and a one-time seed puts it back on the instances
that had it forced off. **The eight pins that do prevent something are untouched** - cave mode,
coordinates, biome names, tracked players, distances, teleport, the minimap radar and footsteps.

**Actually 3D Blocks & Items is back, patched.** v1.0.7 removed it whole; that was too blunt. Its
metadata does understate its support, but that is not what broke: **45 of its models reference a
texture variable named literally `#missing`**, the author's own placeholder left in, and those are
the ones that rendered as untextured brown geometry. Every other model resolves - all textures sit
in the base `assets/`, and the overlay that does not apply on 26.2 holds a single entry.

`nbidal18-Actually-3D-r1.8.zip` is the upstream pack minus those 45 models, minus an uppercase
namespace folder Minecraft rejects, minus a lang file with missing commas, and minus the macOS
noise. **2,112 files kept** - including the 150 three-dimensional item models that were the reason
for adding it. Vanilla and 3D Default supply the 45 blocks it no longer touches.

**Containers are light instead of dark.** Recolourful Containers 3.1.3, the same version, the
standard theme rather than the DARK variant. Only `rendertype_text.fsh` differs between the two
builds, which is the text colour and exactly what should differ. It ships 26 core shader files, but
they are byte-identical to the DARK pack that has been running all day apart from that one - checked
before shipping, because of what the last three releases cost.

---

## v1.0.7

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `19df306ff3d3236d` | `21b811bf70a105ff` | 249 | 106 |

**Actually 3D Blocks & Items is removed.** Its metadata understates its support - `max_format: 84`
against 26.2's **88**, with a single overlay that stops at 75.

> **Corrected in v1.0.8.** The format mismatch was not what broke it, and removing the whole pack
> was too blunt. 45 of its models reference a texture variable named literally `#missing`; those are
> the ones that rendered untextured. The rest resolve. v1.0.8 brings it back with those 45 removed.

The visible symptom was a brown untextured shape rendered in the player's hand. The log named the
cause on every load:

```
Missing texture references in model minecraft:item/sugar_gui
Missing texture references in model minecraft:block/crafting_table
Skipped language file: actually3d:lang/en_us.json (MalformedJsonException: Unterminated object)
Non [a-z0-9_.-] character in namespace Actually3dBlocksAndItems
```

Every model with unresolved textures came from this pack, and it sat above 3D Default in priority,
so its broken versions won. It also ships an invalid uppercase namespace folder and a lang file with
missing commas - the sloppiness and the version claim are the same story.

**3D Default stays and covers the same ground.** It declares overlays for formats 73-88 and 87-88,
which is what real 26.2 support looks like.

**Check the metadata, not the listing.** Two packs added in v1.0.4 claimed 26.2 on Modrinth; one
shipped a core shader that blanked every inventory slot, the other shipped models for a format four
versions old. Both said so in their own `pack.mcmeta`.

---

## v1.0.6

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-29 | see below | `21b811bf70a105ff` | `2731ae371d2e6b55` | 250 | 106 |

**Items render in inventory slots again.** v1.0.4 added Weskerson's Torches, and the pack ships a
replacement for `shaders/core/item.vsh` and `item.fsh` in an overlay that covers 26.2. That is the
core shader Minecraft uses to draw item sprites, and the pack's version drops the `Sampler1` uniform
26.2's item pipeline binds. The game said so on every load:

```
minecraft:pipeline/item_cutout shader program does not use sampler Sampler1
defined in the pipeline. This might be a bug.
```

The result was empty armour slots, empty hotbar slots and an inventory of nothing, while the world
itself rendered normally.

**The pack is patched rather than dropped**, so the 3D torches stay: `nbidal18-Weskersons-Torches-1.02.zip`
is the upstream pack with its fourteen shader files removed and nothing else touched, plus five
hundred stray macOS metadata entries swept out - one of which was logging a warning of its own. The
only thing lost is the emissive glow on torch *items*.

**A pack that ships core shaders can break rendering far from what it looks like it does.** Nothing
about a torch pack suggests it can blank an inventory. Worth checking `assets/minecraft/shaders/`
before adding any resource pack.

**Server-side, not shipped through the channel.** JEI is installed on the server. It is
`environment: "*"` with a server entrypoint, and without it JEI told every player their recipes
might be wrong - which for this pack is true, because Hardcore Revive+ adds the Soul Charm recipe
through a datapack. JEI now serves the server's real recipes instead of guessing from the client.

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
