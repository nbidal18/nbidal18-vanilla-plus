# Changelog

One entry per **published** release. An entry means this reached players — never write one for a
build that was not published.

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
