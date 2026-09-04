# Changelog

One entry per **published** release. An entry means this reached players — never write one for a
build that was not published.

---

## v1.0.64

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-04 | see below | `08b8fac54699` | `edd141f766b6` | 293 | 143 |

**Far terrain follows you after a death, not your corpse; ghosts generate nothing and stay put.**
Click **Play**. Nothing to clear.

### The corpse

Found by the owner an hour after v1.0.63 went live: he died for a Soul Charm test, flew off, and
watched the far terrain keep growing around the spot where he had died while nothing at all grew
around him. Vanilla replaces the player object on respawn; Voxy World Gen's tracker kept the old
one, whose position was frozen at the corpse, and every generation task worked for it until the next
relog. A straight strip of vanilla-loaded chunks under the real player was all he got. That is also
where some of the previous night's "zero chunks a second" went: Abdo had died twice in that run.
The instance is now swapped the moment a player respawns.

### Ghosts

- A Hardcore Revive ghost - a spectator with no lives - no longer drives far-terrain generation
  and is not swept for. It keeps what its client has; revival resumes everything.
- A ghost cannot change dimension, and cannot go more than 100 blocks from where it rose on x or
  z. Any height. Ghosts already could not pass through terrain; this is the rest of the owner's rule.
  The anchor is taken a second after the ghost appears and cleared on revival.

### No more idle kick

`player-idle-timeout` is 0 on the server, at the owner's request: standing still never disconnects
anyone. Server Pause still idles an empty server. Set through the deployment plan, not by hand.

### Cosmetic

The `generator` line no longer flickers amber at 6 of 6 tasks: the worker hands out six at a time
and they finish within a few ticks, which is normal. It colours only when it is at its cap with no
rate at all, which is the stuck case.

### Tested before publishing

Updater sync, client launch and dedicated-server boot pass, plus a second boot with the renamed
Voxy jar named. **What it needs from you:** die once, relog nothing, and watch the disc follow you;
then as a ghost try to fly 200 blocks away and through a portal.

---

## v1.0.63

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-04 | see below | `edd141f766b6` | `d9b3b47773a5` | 293 | 143 |

**Far terrain arrives nearest-first and the readout can now say when the server is not generating;
the Soul Charm revives again; a passenger who logs out of a plane comes back safely; enchanted tools
look like plain ones and the fishing rod is vanilla.** Click **Play**. The first launch clears Voxy's
store and Xaero's map tiles once more, waypoints kept, and the world fills in from nothing.

### The ring, and why it formed

Terrain reaches a client by two routes at very different speeds. A chunk the server has never seen
is generated and sent the moment it exists. A chunk it already generated for anyone is never
generated again and can only reach a second player through the sweep, which was capped at about 16
chunks a second. So around another player's old route the recorded band trickled in while everything
beyond it, being new, appeared at once: a filled far band with an empty one inside it, in the same
place for everyone. Measured on 2026-09-03 from the server's record against the owner's client ledger.

- **Nearest-first.** While the sweep still owes a player terrain, a fresh chunk farther out than the
  sweep has reached is held for the sweep instead of sent ahead of it. Whatever is missing is now at
  the outer edge, not a hole. Only chunks the generator has recorded are held this way.
- **Four times the sweep.** 32 loads per player and 96 in all, from 8 and 24.
- **The generator's own state** is on the status packet: paused by tick time, tasks active of six,
  chunks left in radius, rate. Voxy World Gen stops generating outright when the tick averages 75 ms,
  and until now nothing could see it - a player sat at a visible edge of terrain at 0 chunk/s with
  every line green. The headline now reads *the server is NOT generating* and says why.

### Soul Charm

A dropped charm did nothing for a ghost. The item's `Revive` marker is one of its default components,
and 26.2 does not save a default on the dropped item, so the datapack's detection never matched. It
now also looks for the charm by its item id. `tag <player> add Revive` from the console still works.

### Safe rejoin

Vanilla saves a ride only for its sole passenger, so the second person in a plane who logged out came
back at their last coordinates, in the air. The server now remembers the vehicle by id and puts the
player back aboard on rejoin, or on the first solid block or water surface below with no fall damage.
A moving or airborne vehicle also counts as activity, so the idle kick no longer fires mid-flight.

### The 3D pack, 1.1

Weskerson's fishing rod - gripped at its butt, stood on end on the ground, red-and-pink when enchanted -
is dropped whole, so the rod is vanilla in hand, on the ground and in frames. Every enchantment branch
in an item definition is collapsed, so an enchanted carrot on a stick, flint and steel, shears or
warped fungus on a stick looks exactly like a plain one, which is what shipping No Enchant Glint
already asked for. Your pack list is updated on the next launch.

### Clean sheet

Both stores start empty again, at the owner's request: the first reading of the order rule should
describe only it, and a client ledger that might claim chunks its Voxy store no longer holds goes
with the store. The server's generation record was removed in the same deploy, through the plan,
with a backup after the shutdown.

### Tested before publishing

Updater sync, client launch and dedicated-server boot pass; the dedicated boot again with both new
jars named passes. The window controller's simulation is unchanged and passes. The 3D build's own
re-measurement: 1,177 items 3D in hand, inventory identical to vanilla for every item, no missing
reference. **What it needs from you and your friends:** `/voxysync show` through a first session -
the `generator` line and `behind sweep` count are new; fly out and confirm terrain fills nearest-first
with no ring; drop a charm next to a ghost; log a passenger out of a plane over water and rejoin.

---

## v1.0.62

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-03 | see below | `d9b3b47773a5` | `162539710eea` | 292 | 142 |

**One 3D resource pack instead of four, and every item now follows one rule: 3D in your hand, on
the ground and in item frames; exactly vanilla in any inventory.** Click **Play**. Nothing to clear.

### What was wrong

Actually 3D, Weskerson's 3D Items, 3D Food and Torches were four separate packs, each with its own
idea of where an item is 3D. Measured against vanilla, the inventory look of 254 items differed
without anyone having decided it: every ore, planks and copper block drew Actually 3D's version of
the cube, all sixteen beds drew its bed, tools drew its three-dimensional-looking sprites, and
Weskerson's food lay flat on the ground and in item frames. Two of Weskerson's hanging signs pointed
at a model no pack ships and drew the purple placeholder in hand.

### What changed

The four packs are merged at build time into **`nbidal18-3D`**, the one 3D pack this modpack
maintains, and the rule is enforced by measurement rather than by lists: every item definition in
the game is resolved through the real pack order down to what it draws, and wherever the inventory
would not look exactly like vanilla's, the pack sends the inventory to a copy of vanilla's own
model and textures. Wherever a 3D item was flat on the ground or in a frame, it is 3D there now,
sized from its own model. The build re-measures the finished pack and refuses to ship one that
breaks the rule. A `SOURCES.md` inside names the four authors; none of the artwork is ours.

- **Beds** show vanilla's own small 3D bed in the inventory, because vanilla 26.2 has no flat bed
  sprite at all. In hand and placed they are Actually 3D's.
- **Compass, recovery compass and clock** keep Weskerson's flat picture on the ground and in frames:
  their 3D hand model is an animated dial that a static transform cannot follow.
- Your pack list is updated on the next launch. The four old packs are removed by the updater.

### Tested before publishing

The build's own re-measurement: inventory identical to vanilla for every one of 1,542 items, 1,178
items 3D in hand, no missing model or texture. Client launch, updater sync and dedicated-server boot
pass. **What it needs from you:** open a chest and your inventory and look; hold a few things; drop
them; put them in a frame. Beds, tools, ores, potions and food are the ones that changed most.

---

## v1.0.61

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-03 | see below | `162539710eea` | `0721583a860a` | 295 | 142 |

**Far terrain remembers only what Voxy actually kept, the readout shows the sweep working, and both
stores start from nothing once more.** Click **Play**. The first launch clears Voxy's store and
Xaero's map tiles, waypoints kept, so give it a minute; the world then fills in from nothing.

### The fault this fixes

Your client keeps a record of the far terrain it has received, and tells the server at join so
nothing is sent twice. v1.0.60 wrote a chunk into that record the moment it was handed to Voxy.
Voxy queues what it is handed and converts it on its own threads - and when it shuts down, at every
logout, `/voxy reload` or turning Voxy off, it throws that queue away unconverted. Whatever was still
queued at your logout was written down as held and discarded, and the server never sent it again
because the record said you had it. On a client whose Voxy runs on one thread, that is a band of
missing terrain at wherever the delivery frontier stood when you logged out: fixed in the world,
never filled by the server, filled only where you fly.

**The record is now written when Voxy inserts a chunk into its store**, section by section, not when
the chunk is handed over. Anything Voxy refuses or discards is simply never recorded, and streams
again next time.

### What else changed

- **`/voxysync` reads the right things.** `repeats` is gone: it counted the second half of any chunk
  larger than one packet and read as half of everything. In its place, `already had` counts chunks
  the server sent that your record had already reported holding - the one number that says the
  dedupe has stopped working - with the server's own `skipped N already held` beside it. New lines:
  `voxy queue` (Voxy's internal backlog, and hand-overs it had nowhere to put) and `loaded N from
  disk` with both load caps, which is the proof the sweep is reaching terrain that had unloaded.
  `delivered by sweep` now counts a chunk whichever path sent it; it read zero for exactly the work
  the sweep exists to do.
- **`/voxyflow <player>`** on the server, for operators: any player's readout, same lines in the same
  order as their overlay, from the server's own state and the figures their client now sends on
  every acknowledgement. It works for a client that has stopped answering, which is the one worth
  reading.
- **`/voxysync refresh`** forgets one dimension on both sides instead of every dimension on the
  server, and says how long the re-stream will take at your current rate. Judged after a minute it
  looked like nothing happened; at 135 chunk/s, 118,000 chunks is a quarter of an hour.
- **`/voxysync here [radius]`** takes a radius up to 32 chunks, so a hole can be probed from outside
  it rather than by standing in it.
- **A join no longer opens with a burst of chunks you already hold.** The server waits up to five
  seconds for your record to arrive before sending anything for a dimension.
- Two smaller defects found in passing: a block update the server was too far behind to send now
  lets the sweep resend the whole chunk (before, the chunk stayed marked held and the update was
  lost), and a failure inside one delivery batch can no longer strand the rest of the batch.

### Clean sheet

Both stores start empty, at the owner's request: a record written under the old rule can hold
chunks Voxy never kept, and the first reading of the new rule should describe only it. Your client's
store and its record go on the next launch; the server's generation record was removed in the same
deploy - through the deployment plan this time, with a backup taken after the shutdown, rather than
by hand over SFTP as in v1.0.30, v1.0.55, v1.0.56 and v1.0.60.

### Tested before publishing

The window controller is untouched and its simulation still passes. Client launch, dedicated-server
boot with the new jar, the updater's sweep against planted markers from every previous wipe, and
the deployment plan all pass. **What it needs from you and your friend:** `/voxysync show` on both
clients through a full first session and a relog. `already had` should sit at 0 after the first
seconds, `voxy queue` should read small and never `refused`, `loaded N from disk` should climb while
`sweep has more` is up, and the second join should re-stream nothing. If a band appears again, run
`/voxyflow <name>` from the console before anything else and paste it.

---

## v1.0.60

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-03 | see below | `0721583a860a` | `41da87f307e8` | 295 | 142 |

**A clean sheet for far terrain.** Click **Play**. The first launch clears Voxy's store and Xaero's
map tiles, waypoints kept, so give it a minute; the world then fills in from nothing.

### Why

v1.0.59 put far terrain under a new pacing and delivery layer. The stores every client built under
stock were not wrong, and the new layer would have re-streamed everything on a first join anyway -
but the owner would rather the first readings of the new layer describe only it, with no old files
in the picture. So both sides start empty:

- **your client's store**, and with it the new ledger of what you have received, which lives inside
  the same folder so the two can never disagree;
- **the server's generation record**, removed while the server was down, with a backup taken first.

Nothing else changes. The mod is the one v1.0.59 shipped.

### What the first session looks like

The server re-generates the area around each player nearest-first - loading the chunks that exist
from disk, not making new terrain - and streams as it goes, paced to your connection. That first
session is the heaviest load the new layer will ever carry. Judge it on the second. `/voxysync show`
tells you what it is doing.

---

## v1.0.59

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-03 | see below | `41da87f307e8` | `f5c407825975` | 295 | 142 |

**Far terrain is paced to what your connection and your client can actually take, and nothing it
holds back is ever lost.** Click **Play**. Nothing is cleared; your stored far terrain stays.

### What was wrong

Two things, both in the live pack:

- **A thin connection drowned.** The stream that fires as terrain generates is unthrottled. A link
  that cannot carry it does not lose packets - it queues them, in your router and your provider - and
  everything else waits behind them until the keep-alive comes back too late and you are *Timed out*.
- **A dropped chunk was a hole.** Your client throws payloads away once its queue passes 8192, while
  the server has already recorded them as delivered. Holes that fill only when flown over.

### What changed

`nbidal18-voxyworldgen` 3.0.0, on the server and on every client:

- **Every send is gated.** The server keeps the bytes in flight to you under a window that follows the
  queueing delay it measures from marks your client acknowledges every tick - fresh every 50 ms,
  where vanilla's ping updates every fifteen seconds. Queueing rises, the window shrinks; it stays
  low, the window grows. A deep client queue pauses the stream outright.
- **Held-back chunks are delivered, not forgotten.** A sweep sends them nearest-first at that pace and
  **loads a chunk from disk if it has unloaded** - which is the part the v1.0.48-55 attempts lacked,
  and exactly why they left a ring of missing terrain: the mod's own backfill cannot load a chunk and
  retries the same unloaded ones for ever.
- **Rejoining re-streams nothing.** Your client records what it has taken, in `.voxy` next to its
  store, and tells the server at join. Wipe `.voxy` and everything streams again, without a ring.
- **Dropped chunks are asked for again**, and the server can now actually get them back.
- **`/voxysync` is back**: `show`, `hide`, `here`, and a new `refresh` that forgets everything received
  for the current dimension. The overlay appears on command only. When the server is holding back it
  says so, and why - link delay or your client's queue - instead of guessing.

Switching Voxy off still stops the stream. Chunks the mod used to send twice - once on load, once
after generation - are sent once.

### Tested before publishing

The control law runs against modelled links without a game (`scripts\Test-FlowController.ps1`),
which is how a 90-second base-delay memory was found to pin the window to the floor on a link whose
base delay rises in the evening, and shortened to 60 before anyone had to feel it. Client launch,
dedicated-server boot with the jar, the updater, and the deployment plan all pass.

**What it needs from you and your friend**: `/voxysync show`. Dropping should stay at 0 and the ping
flat while his side reads *paced by the server (link delay)*. Then a `.voxy` wipe and rejoin: terrain
fills nearest-first with no ring, and the next join re-streams nothing.

---

## v1.0.58

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-03 | see below | `f5c407825975` | `82dbf3d7b7d4` | 295 | 142 |

**Ingots are properly flat in the inventory, and beds look like vanilla's again.** Click **Play**.

### v1.0.57 said it fixed the ingots. It did not

The definition was right - the inventory was pointed at a flat model. **The artwork was wrong.**

Actually 3D replaces **33 vanilla item sprites** with its own, deliberately three-dimensional
looking. A texture named `item/iron_ingot` resolves against every installed pack, not against
vanilla - so the flat model was drawing the pack's 3D artwork on a flat surface, and an ingot still
looked three-dimensional.

Each generated flat model now carries **vanilla's own image**, copied in under a private name that no
pack can replace. Deleting the pack's versions instead would have fixed six of them and broken
others: its `gold_ingot` image is also what gold nuggets are drawn with.

### And the beds were never even looked at

The build decided an item was three-dimensional by looking for geometry **in that item's own file**.
`black_bed.json` has none - it is four lines naming a colour and inheriting everything from a shared
bed model. So all sixteen beds fell through both branches and were never considered.

It now follows the inheritance chain. Beds have no flat sprite in vanilla to fall back on - vanilla
builds them from the bed's head and foot - so **the pack now steps aside and lets vanilla draw them**,
which is what they looked like before Actually 3D was added.

Iron, gold, copper and diamond blocks are still three-dimensional in the inventory. **So are
vanilla's** - a block item is drawn as a block - so those are correct as they stand.

## v1.0.57

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-03 | see below | `82dbf3d7b7d4` | `3cb8f5f74a44` | 295 | 142 |

**Ingots and a handful of other items stop being three-dimensional in your inventory.** Click
**Play**.

### What was wrong

Items are meant to be 3D in your hand and flat in the inventory. Seven were 3D in both:
**iron, gold and copper ingots**, plus the **amethyst shard**, **firework star**, **sugar** and
**wind charge**.

The build decided an item was already handled by asking *"does the pack ship a definition for it"*.
That is not the same question as *"does that definition send the inventory to a flat model"*, and the
difference is exactly where these fell through:

- The **ingots** have a definition, but it selects on the item's **custom name** - nothing to do with
  where it is being drawn - so the inventory got the 3D model.
- The other four ship models the pack itself names `<item>_gui`, and **those are 3D as well**. The
  name collides with the one the build generates for flat models, which is how they were misread as
  already correct.

It now resolves what each definition actually draws in the inventory, follows that model's parent
chain to see whether it is a sprite or geometry, and only skips items that genuinely end up flat.
Generated models are named `_flat_gui` so they cannot collide with the pack's own.

### Beds and metal blocks are left alone

They are still 3D in the inventory, and that is correct: **vanilla draws them that way too.** There
is no flat sprite for a bed or an iron block to fall back on - making them flat would mean inventing
artwork that does not exist.

## v1.0.56

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-03 | see below | `3cb8f5f74a44` | `779a090075a1` | 295 | 142 |

**Beds stop rendering as a purple-and-black square, and far terrain goes back to how its own
developers wrote it.** Click **Play**. Far terrain rebuilds from nothing.

### Beds were broken, and so were two other models

Every bed drew as the missing-texture placeholder in your hand. All sixteen share one parent model,
`template_bed`, and our Actually 3D fork **deleted it**.

The fork drops a 3D item model when nothing guards it and vanilla has no flat sprite to fall back
on. `template_bed` is a shared parent rather than a real item, so it had neither - and nothing
checked whether other models still pointed at it. It has been broken since Actually 3D was added in
v1.0.46.

Two more models named textures that do not exist anywhere - leftovers of a mod's assets we removed -
and drew the same placeholder. Those are dropped so vanilla draws them instead.

**The build now refuses to finish if any model's parent or texture does not resolve**, in the pack
or in vanilla. It already refused on a dangling blockstate; it should have had the same rule for
models pointing at models, and this shipped for ten releases while the build reported success.

### Far terrain is stock again

The add-on that paced far terrain is **removed**. Six releases changed how it worked and the
readings from the one player it was built for got worse across three of them; at the end nobody
could say which of its parts helped.

**Voxy and Voxy World Gen were never modified** - both jars are byte-identical to the developers',
verified against Modrinth's own hashes - so there was nothing to restore, only ours to take away.

**One piece stays**, because it is the only part that was demonstrably working: switching Voxy off in
game still stops the server sending far terrain. That is now the whole of it - about 4 KB, client
side only, no longer installed on the server at all.

Everything else is archived with a full audit of what worked, what did not, and the measurements
behind both, so it can be picked up rather than rediscovered.

### Stored far terrain is cleared, again

Your client's store and Xaero's map tiles go on next launch, waypoints kept; the server's generation
cache is removed in the same deploy. Everything cached was built under rules that no longer apply.

**So it rebuilds from nothing, and the first session is the heaviest load far terrain can produce.**
Defaults are unchanged: Voxy ships **off**, at 32 chunks if you switch it on.

### Still not fixed

The ring of missing far terrain between your render distance and where it resumes. Four explanations
were proposed and all four were wrong - the last falsified by the observation that terrain beyond the
ring is also pre-existing and works fine. Nobody has yet checked the one thing that would narrow it:
**whether the ring moves with the player or stays put in the world.**

## v1.0.55

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `779a090075a1` | `b77a4b97568e` | 295 | 142 |

**Far-terrain handling is rolled back to how it worked in v1.0.51, and every stored copy of far
terrain is cleared on both sides.** Click **Play**. Expect the world to fill in from nothing.

### Rolled back

v1.0.52 through v1.0.54 changed how the server decides when to slow far terrain down: first a
tighter byte threshold, then a speed limit steered by ping, then a fix for that speed limit having
made things worse. The end state was no better than where it started, and along the way one release
was actively harmful.

The mod is now **byte-for-byte the build v1.0.52 shipped** - not a rewrite that resembles it, the
same jar - so what happens next is attributable to a known quantity rather than to four releases of
changes nobody can hold in their head at once.

### Everything cached is cleared

Both sides, in one pass:

- **Your client's far-terrain store**, along with Xaero's map tiles. Waypoints are kept
- **The server's generation cache**

Clearing one side without the other leaves the two disagreeing about what exists, which is why they
go together.

**So the world will rebuild from nothing**, and the first session after this is the heaviest load
far terrain can produce - more than anything measured while tuning it. That is the reset, not a
fault. Judge it on the second session.

### What is still not fixed, and is not this

A ring of empty terrain between your render distance and where far terrain resumes is **a separate
problem and predates all of this**. Chunks that already exist on disk but are not loaded fall
between the mod's two delivery paths: nothing needs generating there, so the generator skips them,
and the backfill will not load a chunk to send it. Flying through the ring loads them and fills it
permanently. A proper fix is written up but deliberately not attempted in this release.

## v1.0.54

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `b77a4b97568e` | `9da344bd3fbc` | 295 | 142 |

**Fixes a bug that made far terrain worse the harder the server tried to help.** Click **Play**.

### What v1.0.53 actually did

Holding a chunk back was supposed to mean "not now, send it later". It also, silently, meant
**"forget this player ever had it"** - including chunks already sitting on their disk. The backfill
then sent them again.

While holding back was rare that cost nothing. v1.0.53 added a real speed limit, so it became
constant, and the server started un-sending terrain faster than it could deliver it: the same chunks
going round and round, **total traffic rising** exactly when it was supposed to fall.

For the player it was meant to help, that was worse than doing nothing. Chunks arriving at a
fraction of the old rate and a connection so congested he could not open a chest or load the ground
under his feet.

### The fix

The pack now holds chunks back through a path that changes nothing else. A chunk the player already
has stays delivered and is never re-sent; one they do not have stays pending, and the backfill
delivers it at its own steady rate.

**That backfill is the floor under all of this**: even a player paced right down still receives far
terrain, just slowly. It was always there - v1.0.53 was fighting it rather than leaning on it.

### Honest note

This is the fourth release in a row touching how far terrain is paced, and the third that did not do
what was intended. The first two tuned a threshold that turned out not to be connected to the
problem; this one was actively harmful. The mechanism is now right, and **the speed limit itself has
not been retuned** - that comes after seeing real numbers rather than before.

## v1.0.53

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `9da344bd3fbc` | `b975e91cf1f6` | 295 | 142 |

**Far terrain is now sent at a speed each connection can actually carry, instead of being stopped
once it is already too late.** Click **Play**. On a fast connection nothing changes.

### What was wrong with the old approach

Since v1.0.48 the server held far terrain back whenever a player's outbound socket buffer started
backing up. That ended the disconnections, but it never made a thin connection comfortable - and
three readings from a real player showed why:

```
receiving 248 chunk/s   ping 643 ms   server: nothing wrong
receiving 228 chunk/s   ping 546 ms   server: nothing wrong
receiving  82 chunk/s   ping 643 ms   holding back, 2423 held
```

**In the two worst frames the server did not think anything was wrong.** That buffer only fills once
the connection is *already* blocked - after the queue has built up in the player's own router and
their provider's network, where nothing on our side can see it. It reports a problem that formed
seconds ago.

Tightening it proved the point: across three releases the threshold went 64 KB, 16 KB, 4 KB, and the
ping went **484 ms, then 546, then 643**. The wrong direction. The lever was not connected to the
thing it was supposed to move.

### What happens now

The server gives each player a **speed limit in chunks per second**, and adjusts it from the ping
that player is actually experiencing. Over 100 ms and the limit halves immediately. Under, it grows
back. So instead of noticing a full pipe, it stops overfilling one.

A new connection starts slow and doubles every few seconds while the ping holds, so a healthy player
reaches full speed in about twenty seconds and a thin line reveals itself long before then. After the
first back-off, growth becomes gentle rather than doubling, so it settles near the line's real
capacity instead of bouncing over it. This also replaces the fixed 90-second window from v1.0.49 -
earning the rate is the same idea without a magic duration.

**Nothing is lost when a chunk is held back.** It is marked undelivered and the backfill sends it
again once there is room, exactly as before.

The old buffer check is kept as a backstop - it costs nothing and covers the moments before a ping
has caught up - but it is no longer in charge.

## v1.0.52

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `b975e91cf1f6` | `bc10d8b8466a` | 295 | 142 |

**Carrying a block no longer leaves your armour swinging, and the sync overlay stops appearing when
nothing is wrong.** Click **Play**.

### Armour kept animating while carrying

v1.0.49 stopped Fresh Animations drawing over Carry On's two-handed pose. It only got half the
player: the body froze and **worn armour carried on moving**, which looks worse than not posing at
all.

The instruction we gave EMF was "pause this player's animation", and EMF acts on that in exactly one
place - the model root. Armour is drawn by its own root and never saw it.

It is now told to use the **vanilla model** for a carrying player instead, which covers the whole
player rather than one part of it. That is also the more honest instruction: Carry On's pose *is* a
vanilla pose, so there was nothing of Fresh Animations worth keeping mid-carry.

### The overlay appeared when everything was fine

v1.0.51 made the sync overlay show itself while the stream was being paced. But pacing is the system
working, not a fault - a real player sat paced and completely healthy at 67 ms - so it appeared on
every join and said nothing was wrong. A warning that fires when nothing is wrong stops being read.

**The rule is now simply: the overlay appears when something on it is not green.** Paced and fast
stays quiet. Paced and slow, dropping chunks, or a stream filling your connection puts it up.

The bar for a green ping also drops from 150 ms to **100 ms**, because by 150 you can already feel
it - and it is the same number the overlay colours itself by, so "it came up on its own" and
"something on it is not green" cannot disagree.

`/voxysync show` and `hide` are unchanged, and hiding still takes effect the moment everything reads
green.

## v1.0.51

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `bc10d8b8466a` | `5a6d8930d9a8` | 295 | 142 |

**The far-terrain readout now appears on its own when there is something to see.** Click **Play**.

`/voxysync show` and `/voxysync hide` still work and your choice is remembered. On top of that, the
overlay puts itself on screen whenever the far-terrain stream is **being paced to fit your
connection**, **dropping chunks**, or **filling your connection** - and stays up until that clears,
even if you have hidden it.

Those are the moments the game looks broken and the readout is the only thing that explains it.
Rather than a player wondering why the world is filling in slowly just after joining, they get told
that the server is pacing it on purpose and it will settle.

`/voxysync hide` during one of those says so instead of silently doing nothing, and takes effect the
moment the sync is healthy again.

### One state deliberately left out

**A slow connection with nothing arriving does not force the overlay up.** That is the single
verdict meaning the problem is not this pack's - a high ping with no far-terrain traffic to blame -
and unlike the other three it does not clear on its own. An overlay nobody can dismiss, about
something the pack neither caused nor can fix, would just be nagging. It still shows for anyone who
asks for it with `/voxysync show`.

## v1.0.50

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `5a6d8930d9a8` | `70ed3c107d6f` | 295 | 142 |

**The server can no longer kill itself at boot.** Click **Play**. Nothing changes in game.

### What was happening

Roughly one server start in twenty died before finishing loading, with a message blaming a mod:

```
Failed to parse incendium:lesser_structures from pack incendium
Caused by: NullPointerException: Cannot read field "right" because "l" is null
    at java.util.TreeMap.rotateRight
    at java.util.TreeSet.add
    at StructureSetsSet.addStructureSet
```

**Incendium was innocent**, and so is every other mod that message has ever named. Sparse Structures
keeps a list of every structure set it sees, in an ordinary list that cannot cope with being written
to by more than one thread at once - and 26.2 loads registries on four threads in parallel. The list
tangles itself, the next write falls off the end of it, and the server dies. The mod named in the
error is simply whichever one was being written at that instant, so a different boot blames a
different mod.

That is the expensive part: the log sends you off to read somebody else's worldgen code. A restart
always fixed it, because nothing was actually damaged - it lost a coin toss and won the next one.

### The fix

Writes to that list now happen one at a time.

**Nothing else changes.** That list exists only to feed a debug command that prints structure set
names; nothing about structure spacing, generation or placement ever reads it. There is no
behaviour to get wrong in either direction.

Confirmed by reproduction rather than by reasoning: driving the real method from eight threads fails
on the first attempt with the same stack. It is rare on a real server only because the loader pushes
a few hundred entries through four threads and usually gets away with it.

## v1.0.49

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `70ed3c107d6f` | `5948c00e262c` | 294 | 141 |

**Carried blocks are held in two hands, AFK players get a cinematic, and the far-terrain readout
finally tells you the truth.** Click **Play**.

### Carry On's animation is no longer drawn over

Picking a block up puts you in Carry On's two-handed pose, and Entity Model Features was drawing the
Fresh Animations pose straight over it - so the block appeared to float beside a normal idle
animation. While you are carrying, EMF now stands aside.

Solved once before in the 1.21.1 pack. That version pushed a pause into EMF every tick and took it
back out again, and needed a ledger to avoid leaving a player's animations stuck if they
disconnected mid-carry. EMF 26.2 lets a mod register a condition and be *asked* instead, so nothing
is applied and nothing has to be undone - the stuck-animation case cannot happen.

### AFK Cinematics

Go idle and the camera takes over. Client-side only, no configuration. The server's idle kick moves
from **5 minutes to 15** to suit it.

### The far-terrain readout was blaming your connection for its own load

`/voxysync show` had no way of knowing the server had started pacing far terrain to fit a
connection - v1.0.48 added the pacing and told the client nothing. So it went on guessing from ping,
and from the receiving end *"your connection is struggling"* and *"the server is holding back so it
does not"* look identical. It showed a red alarm and advised turning Voxy off while the system was
working exactly as intended.

The server now says so directly, and the overlay reports it in green with a count of how much has
been held back. Nothing to act on - it is the pacing doing its job.

### Pacing is stricter when it matters

A real session showed the danger is the **first minute**, not steady play: a player joined at a
4888 ms ping and, with nothing changed, was at 86 ms after three minutes and 67 ms after four,
still pulling ~290 chunks a second. What used to disconnect him was the opening burst, when the
whole backlog of terrain around him goes out at once.

So the margin now sits where the risk is. For the first 90 seconds the queue is held four times
tighter than afterwards. **The only effect is that the world fills in a little more slowly right
after joining.**

### Under the hood

`server.properties` can now be changed through the deployment scripts instead of by hand. Until this
release the MOTD was the only key they could touch, so setting anything else meant editing the live
file over SFTP with no backup, no hash check and no record of what it used to say - while every
other deployed byte in this pack goes through a reviewed, verified plan. It refuses to create a key
that does not already exist, because a typo would otherwise sit in the file being silently ignored.

The packaging script also only ever checked a `main` entrypoint, so the first client-only
first-party mod made it fail with a raw `KeyError` instead of the clear message that check exists to
give.

## v1.0.48

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `5948c00e262c` | `cf598509ea4a` | 292 | 139 |

**The far-terrain stream no longer sends faster than your connection can take.** Click **Play**.

### What was happening

A player was being disconnected with *Timed out* about a minute into every session — **fifteen
sessions across three days, not one longer than 60 seconds**, while another player on the same
server played for 98 minutes at a stretch. It read exactly like a bad connection at his end. It was
not.

`/voxysync show` on that player, mid-session:

```
receiving  232 chunk/s      data flowing fine
dropping   0 chunk/s        nothing being lost
ping       4888 ms          five second round trip
```

**Five seconds of latency with zero loss is not a slow line, it is a full queue.** TCP does not
drop what it cannot deliver, it queues it — so a stream sent faster than the link can carry does not
show up as missing chunks, it shows up as everything else waiting in line behind it. The server's
keep-alive was stuck in that queue, the reply came back too late, and the server dropped him.

The server sends far terrain two ways. The backfill is throttled to about 20 chunks a second. The
path that fires as terrain generates is **not throttled at all**, and with a generation radius of
512 a moving player pulls 200-300 a second down it. On a connection that can absorb 40, the surplus
became his ping.

### What changed

Each player now receives far terrain **only as fast as their own connection is draining it**. Before
sending, the server checks whether that player's outbound buffer is backing up; if it is, they are
skipped for that chunk and the existing backfill delivers it once the buffer clears. Nothing is
lost — the chunk is marked undelivered, which is a path the mod already relies on.

The result is that a slow connection gets far terrain more slowly instead of drowning, and **a fast
one is not affected at all** — the check never trips if the buffer never backs up.

The signal is the outbound buffer rather than the ping, because the ping is only recalculated when a
keep-alive comes back every 15 seconds. It reports the jam long after it forms.

### `/voxysync` was pointing at the wrong culprit

It had three verdicts, and high-ping-but-nothing-dropping was reported as *"the connection is the
problem, and no pack setting will fix it"* — which is precisely backwards when the pack is what is
filling the connection. That message sent a real person off to blame their internet provider.

There is now a fourth verdict that separates the two cases: **chunks arriving and ping high** means
the stream is saturating the link and turning Voxy off will clear it, while **nothing arriving and
ping high** is genuinely the connection. Only the second one is out of our hands.

### Under the hood

The build now retires a superseded first-party jar for **every** mod, not just the integrity helper.
It only ever covered the helper because that is the one whose version moves every release — but any
first-party mod leaves the same wreckage when its own version is bumped, and this one did it twice
in a day. Two jars claiming one mod id is not a warning at startup, it is a client that will not
start, and both times it was caught by eye rather than by a check.

---

## v1.0.47

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `cf598509ea4a` | `f1597bac0304` | 292 | 139 |

**Turning Voxy off now actually stops the download, and placed blocks that went flat in v1.0.46 are
three-dimensional again.** Click **Play**. Nothing else to do.

### Switching Voxy off never stopped the stream

v1.0.42 added a switch: turn Voxy off on your client and the server stops sending far-terrain data,
so a thin connection is not paying for terrain it is throwing away. **It has never once worked.**

To find out whether Voxy was on, it called Voxy World Gen's helper, which looks the setting up by
name — `VoxyConfig.isEnabled`. **The Voxy in this pack has no such method.** It has a field called
`enabled` and a method called `isRenderingEnabled`, and nothing called `isEnabled` at all. So the
lookup failed on every client, and the helper answers *every* question it cannot resolve with
"yes, Voxy is on":

```
if (voxyEnabledMethod == null) return true;   // the method does not exist
```

The result: every player was announced to the server as "Voxy on" no matter what they set, and kept
the full stream. On a player with Voxy switched off, `/voxysync show` was reading **286 chunks a
second arriving on a client rendering none of them** — which is how it was finally caught, four
releases after it shipped.

This now reads Voxy's own `enabled` field directly, and keeps **three** answers instead of two: on,
off, and *cannot tell*. Cannot-tell no longer means on — it means say nothing and leave Voxy World
Gen's own handshake alone. Guessing "on" is the entire bug.

`/voxysync show` gained a line saying what the server was last told, and it says **UNREADABLE** in
red if the setting cannot be read at all. Without that line this failure has no symptom except a
stream that will not stop.

### v1.0.46 dropped 49 models it did not need to

The table in the v1.0.46 entry below says storage and workstations were dropped because Weskerson's
3D Items covers them. **That was wrong.** Weskerson's 3D Items ships no block model for any of it —
its chests and cauldrons are *held-item* models, drawn in your hand and nowhere else. So every
placed barrel, furnace, blast furnace, smoker, lectern, stonecutter, loom, composter, grindstone,
brewing stand, cauldron, enchanting table and smithing, cartography and fletching table rendered
flat for one release, and nothing was drawing them.

The same mistake took **iron bars**, dropped against Better Lanterns, which ships chains and no
bars — and, because the rule matched substrings of file names, **torchflower**, **potted
torchflower**, both **torchflower crop stages**, the **jack o'lantern** and the **sea lantern**: a
plant and two light-emitting blocks deleted by a rule about torches.

49 models restored. Torches still belong to Weskerson and lanterns and chains to Better Lanterns —
those overlaps are real.

**The fork no longer decides this from a written list.** It reads the model names out of Better
Lanterns and Weskerson's Torches at build time and drops exactly those. Weskerson's 3D Items is
deliberately left out of that measurement: it *does* ship block models, but they are the twenty
potted plants, and plants are what Actually 3D is meant to win.

### The compass needle no longer sticks

A compass is a flipbook of 32 pictures. Weskerson's 3D Items listed only 31 of them for a
**lodestone** compass, so at one bearing the needle showed the previous picture and appeared to hold
a beat before catching up. Ordinary compasses were always complete. Fixed.

This is **not** the compass that went invisible in v1.0.45 — that cleared on a resource reload and
has not come back.

### Weskerson's 3D Items is 790 KB smaller

Its fork is now built by a script instead of by hand, and that script drops the 1,639 macOS metadata
files the pack ships. Nothing that renders changed. The same script re-applies the removal of the
pack's **core shaders**, which was done by hand in v1.0.32 and written down nowhere — they are the
same shaders that blanked every inventory slot in v1.0.6, so re-downloading the pack without that
step would bring the bug straight back.

### Under the hood

The updater no longer claims to be version 1.0.0 in its download header. It had said so since
v1.0.1 and was the last place in this pack that stated a version instead of reading it.

---

## v1.0.46

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `f1597bac0304` | `bbcd2c415455` | 292 | 139 |

**Actually 3D is back, block-only.** Click **Play**. Your resource-pack order is updated for you.

Doors, beds, ores, rails, crops, redstone, bookshelves, ladders and amethyst are three-dimensional
again. Actually 3D covers **878 models** where every other 3D pack here covers a few dozen, so it is
the floor and the Weskerson packs are the detail on top.

### What was kept, and what was not

Three categories are **dropped**, because a pack already here does them better:

| Dropped | Kept by |
| --- | --- |
| Torches and lighting | Weskerson Torches, Better Lanterns |
| Panes, bars and chains | Better Lanterns |
| Storage and workstations | Weskerson 3D Items |

Flowers, mushrooms and bamboo overlap too, and those are **kept deliberately** - the fork sits
*above* the Weskerson packs, so it wins them. **Weskerson Nature is removed** as a result: its entire
overlap with Actually 3D was those three categories, so underneath it, it would have drawn nothing.

### Items are 3D in the hand and flat in the inventory

The pack ships 114 three-dimensional item models but only 53 definitions saying "flat in the GUI, 3D
everywhere else", so the rest would have been 3D in the inventory too. The fork generates the
missing half: 23 flat `_gui` models from the vanilla item texture, plus a `display_context` select
sending `gui` to them. The 53 with no vanilla sprite - buttons, amethyst clusters, things that render
from a block model rather than an icon - have their 3D item model dropped instead, so vanilla draws
them.

### Repacked for 26.2

Upstream declares `max_format: 84` and a `supported_formats` block, which 26.2 rejects outright;
26.2 is format 88. `pack.mcmeta` is rewritten. This is the same override Immersive Interfaces needed
and carries the same risk: a 26.1 pack is being told it is a 26.2 pack, so a model format change
between the two would show up in game rather than in the build.

`farm_and_charm` and `holdmyitems` assets are dropped - they serve mods this pack does not run.

`scripts\Build-Actually3D.ps1` does all of it, and refuses if a blockstate is left pointing at a
model the category filter removed.

---

## v1.0.45

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `bbcd2c415455` | `6eedc62bc1f4` | 292 | 139 |

**Aircraft and gliders burn in the Nether.** Click **Play**.

### The Nether stops being the easy dimension

Flying made the Nether the easiest place in the pack to cross rather than the hardest. Now anything
you fly there catches fire.

- **Immersive Aircraft** - `VehicleEntity.tick()` ignites in the Nether. `VehicleEntity` is not
  fire-immune and takes damage through `hurtServer`, so an aircraft left up there genuinely burns
  down rather than only looking like it is on fire
- **Reliable Gliders** - `nbidal18-reliablegliders`, a new first-party artefact, sets a gliding
  player alight in the Nether

**Fire rather than a refusal, deliberately.** Immersive Aircraft has a `validDimensions` setting, but
it is checked in `interact()` and nowhere else - it refuses to let you *board* in a dimension, so an
aircraft flown in through a portal keeps working. Fire costs you the longer you stay up, still allows
a deliberate hop across a gap, and destroys the vehicle if you try to cross the dimension in it.

The burn is topped up each tick rather than set once, so it stops shortly after you leave and water
puts it out as normal.

Both run server-side - setting something alight is the server's call - and both are deployed there
with this release.

### The autopilot no longer stops when you type

Ctrl+Alt+W now needs a grabbed cursor to engage, and so does the back key to cancel. Reading the raw
keyboard could not tell a keypress from a keystroke, so typing "stone" into a JEI search ended the
flight on the **s**.

The cost: the back key does not cancel from inside an inventory either, even though InvMove lets you
keep moving there. Close the screen and press it.

---

## v1.0.44

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `6eedc62bc1f4` | `d32d043d8cfa` | 291 | 138 |

**A glider, an autopilot, and a way to see what Voxy is doing.** Click **Play**.

### /voxysync - is it Voxy, or is it your connection?

Three releases were spent guessing at that question. This answers it.

- `/voxysync` - print the state once
- `/voxysync show` / `hide` - the same numbers as a live overlay
- `/voxysync here` - re-request the 81 chunks around you

All client-side, so **no permissions and no operator** - the person who needs them is the one having
trouble, not the one running the server.

The top line is a verdict: **healthy**, **OVERWHELMED** (your client cannot ingest as fast as the
server sends - turning Voxy down helps, your connection is not the problem), or **connection**
(Voxy is coping; no pack setting will help). Below it: chunks received a second, chunks dropped a
second, the ingest backlog against its 8192 ceiling, how many are waiting to be re-asked for, and
your ping.

It blames Voxy first when both look bad, because backlog and drops are measured here and certain,
while ping is the server's own estimate and moves around.

`here` is the one that answers a hole. If it fills in, the data path works and something lost that
chunk. If it does not, the server is not sending it at all - never generated, out of range, or lost
before it reached the queue - which is a different problem entirely.

It is a HUD element rather than an F3 module because BetterF3 discards every modded F3 entry, as
v1.0.39 found out the hard way.

### Reliable Gliders

One item, `reliable_gliders:glider` - crafted from phantom membrane, leather and sticks, repaired
with phantom membrane, and it rises on updrafts over fire, campfires, lava and magma.

Paragliders was asked for first. Its 26.2 build is **NeoForge only** - the last Fabric release is
for Minecraft 1.20.1 - so it cannot go in this pack without a full port. Reliable Gliders is the
Fabric-native equivalent, and it happens to be exactly what was wanted: no stamina wheel, no heart
containers, no vessels. There was nothing to turn off.

### nbidal18-autopilot

**Ctrl+Alt+W** holds the forward key down; the back key cancels it.

It holds the **key**, not the movement input, so one implementation covers running, boats, horses and
Immersive Aircraft - anything reading a keybind on that key sees it. Both keys come from
`key.forward` and `key.back`, so they are W and S by default and follow a rebind.

It keeps going while a screen is open, because this pack ships InvMove precisely so you can move
through an inventory - stopping there would cancel out the mod that makes it work. Only *engaging* is
refused from a screen, so Ctrl+Alt+W typed into chat does nothing.

### Settings that were one person's preference

Both are player-class - published once and then yours - so both carry a token to reach instances
that already have the file.

- **Eclipse shader**: the pack now ships the full tuning rather than a single line, and
  `SELECT_BOX=true` turns **block outlines back on**. Off is a preference, and one that costs a
  player the only cue for which block they are about to break.
- **Auto HUD**: the **crosshair is no longer hidden**. Auto HUD already fades it with the rest of the
  HUD; hiding it outright left players aiming at nothing whenever the HUD went idle.

### Voxy's generation radius goes back to 512

v1.0.41 halved it to 256 and slowed updates to five seconds, both aimed at a player whose game kept
stuttering. Neither was the cause - his MTU was, and then a stale server-side generation cache was.
The radius is restored; the five-second flush stays, because it has been fine throughout.

---

## v1.0.43

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `d32d043d8cfa` | `f9e7cb7bf3bd` | 289 | 137 |

**Turning Voxy off now stops the download, and the far-terrain caches are swept once more.**
Click **Play**. The first launch clears Voxy's cache, so give it a minute.

### Voxy off means Voxy off

Until now, switching Voxy off stopped it *drawing* far terrain while the server kept streaming every
LOD packet, which the client received and threw away. On a poor connection that is the worst of both:
all of the cost, none of the benefit.

`nbidal18-voxyworldgen` 1.1.0 announces the change the moment it happens, and the server stops
sending. Switching it back on resumes immediately - no rejoining.

**No new packet was needed.** The server decides who to stream to from `PlayerTracker.isModded`,
which it sets from the `handshake_ack` the client sends at join - and that handler is stateless: it
reads `clientHasMod`, calls `setModded`, and kicks the generation manager when true. Nothing in it
assumes it runs only once, so re-sending the same ack whenever the setting changes is the whole
mechanism.

**Toggling costs no chunks.** `broadcastLODData` tests `isModded` *before* `setSyncedState`, so a
switched-off player is skipped entirely and nothing is recorded as delivered to them. Everything
missed while off is still unsynced and arrives normally on the way back in.

### The caches are swept again

The retired-cache token is bumped, so `.voxy` and `xaero/world-map` are cleared once on the next
launch. Waypoints are untouched - `xaero/minimap` is deliberately not in that list.

**Why now, and a correction.** The v1.0.30 sweep was suspected of never having run, because a player
holding its marker still had a holed world. It had run: the marker was there and the directory had
been deleted. The store simply refilled just as holed, because Voxy World Gen was dropping incoming
chunks on the floor and never asking for them again - the bug fixed in v1.0.42. A sweep before that
release could not have helped no matter how well it worked. This one refills cleanly, which is the
entire reason to do it again.

The sweep now also **verifies before it records**. It re-checks that each directory is actually gone
and refuses to write its marker otherwise, so a sweep that half-finished is retried on the next
launch instead of being silently retired.

### A superseded first-party jar is now retired from the server

Deploying only ever removed the old integrity helper, because that was the only first-party jar the
server carried. `nbidal18-voxyworldgen` going from 1.0.0 to 1.1.0 renamed a server-side jar for the
first time, and both copies would have been left installed - two jars declaring one mod id, with the
loader picking one. `Test-ServerDeployment` now retires any `nbidal18-*` jar the server holds that
the release does not ship. Scoped to ours: spark and the whitelist mod are server-only and are never
touched by a rule about what the client pack ships.

---

## v1.0.42

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-02 | see below | `f9e7cb7bf3bd` | `bda87d84fcf9` | 289 | 137 |

**Two first-party mods: Voxy stops losing chunks, and Ctrl+Alt+W walks for you.** Click **Play**.

### nbidal18-voxyworldgen - the holes

Voxy World Gen's client appends every incoming LOD payload to a queue and, once that queue passes
8192, throws one away:

```
INGEST_QUEUE.addLast(payload);
if (INGEST_QUEUE.size() > 8192) INGEST_QUEUE.pollFirst();
```

Nothing tells the server, and the server has already recorded that chunk in the player's synced set
- so it never sends it again. **That chunk is a permanent hole.** It discards the *oldest* entry,
which during a backfill is the batch sent first: the chunks nearest the player. Holes appear
underfoot rather than at the horizon.

This is not an edge case. The client ingests 96 sections a tick, about 1920 a second, while a
backfill at a 256-chunk radius is 262,144 chunks. The queue holds roughly thirty seconds of that,
so it overruns within the first minute, every time. Dropping is how the client survives; the defect
is that dropping is silent and final. It is also why deleting a Voxy folder only helped for a
while - reconnecting forces a backfill, which floods the queue and makes fresh holes.

The fork, in three parts:

- the drop takes the **farthest** payload instead of the oldest, so what is lost is far terrain
- the dropped chunk is written down
- once the client has gone three seconds without dropping - it has capacity again - it sends a small
  `resync` packet, and the server clears those chunks' synced flags

Clearing the flag is exactly what the mod's own `dropSend` does when its *send* queue overflows. The
server already knew how to recover from a lost chunk; it simply had no way to hear about one lost on
the client. Batches are capped at 512 positions with a second between them, so asking for what was
lost cannot itself refill the queue.

**This one runs on the server as well**, because it adds a packet, and it is deployed there with
this release. A client whose server lacks it degrades quietly - `canSend` is false, nothing is sent,
and it keeps the half that needs no cooperation.

Existing holes are not repaired by installing it. They clear on the next relog, which forces a full
backfill - and that backfill will now actually land.

### nbidal18-autopilot - Ctrl+Alt+W

Ctrl+Alt+W holds the forward key down; the back key cancels it.

**It holds the key, not the movement input**, which is why one implementation covers running, boats,
horses and Immersive Aircraft at once - anything reading a keybind on that key sees it. Driving the
player's movement input instead would walk the player and leave an aircraft idle.

Both keys are read from `key.forward` and `key.back`, so they are W and S by default and follow a
rebind rather than breaking on one. Engaging only works in gameplay, so the combination does nothing
inside a GUI; opening a screen pauses the hold and closing it resumes, so a map can be opened
mid-flight; leaving the world disengages.

A mod that polls GLFW directly rather than going through a `KeyMapping` would not see this. Nothing
in this pack does.

---

## v1.0.41

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `bda87d84fcf9` | `377c60eafdf9` | 287 | 135 |

**Voxy sends less, and less often.** One config file. Click **Play**.

`config/voxyworldgenv2.json`:

| | Was | Now | Effect |
| --- | --- | --- | --- |
| `generationRadius` | 512 | **256** | LOD sync radius 8192 -> **4096 blocks** |
| `update_interval` | 20 | **100** | LOD flush every 1000ms -> **every 5000ms** |

Nothing about how far Voxy renders changes for anyone who was inside 4 km of what they were
looking at, and far terrain now updates up to five seconds later - which is not perceptible at LOD
distance.

### Why

A player on a constrained connection was fine on the 1.21.1 pack and not on this one. That pack
ships no LOD mod at all, and runs a *higher* vanilla view distance (20 against this pack's 10) - so
it was not view distance, it was the LOD stream on top of it.

Reading the mod rather than guessing at it:

- `syncRadiusSq()` is `(generationRadius * 16)^2`, and `generationRadius` is in chunks - so 512 was
  a **8192-block** sync radius. Every player was within LOD range of essentially the whole active
  world, so every block anyone changed rebroadcast that chunk's LOD to everyone
- `ChunkUpdateTracker` coalesces updates over `update_interval * 50` ms, so 20 meant a flush **every
  second**, continuously
- each send is capped at `MAX_PACKET_BYTES = 32768`, about 23 full-size TCP segments per burst

Together that is a relentless burst pattern that the other pack does not produce at all.

**Both values are server-authoritative.** `Config$ServerConfig` is a record the server pushes to
every client over `SERVER_CONFIG_PUSH_ID`, so a client's own copy of these fields is overridden.
Changing them means changing the server's file, which this release deploys; the published client
copy is kept in step so the two do not disagree on paper.

This reduces how hard a bad network path gets hit. It does not repair one - the player's own router
still cannot carry 1500-byte packets, and that is a separate fix on his side.

---

## v1.0.40

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `377c60eafdf9` | `3a514f7d1a7a` | 287 | 135 |

**Reverts the F3 change from v1.0.39.** One config file. Click **Play**.

`config/betterf3.json` goes back to its v1.0.38 contents, byte for byte. F3 looks and behaves
exactly as it did before v1.0.39. Nothing else in v1.0.39 is affected - Carry On, Carry On Extend
and the carryable gyrodyne all stay.

### Why it was reverted

v1.0.39 enabled BetterF3's **Misc Left** and **Misc Right** modules, which were genuinely missing
from this pack's config, on the reasoning that they display the debug lines other mods add - Voxy's
among them. They were missing, and enabling them changed nothing.

Those modules read the **old string-based debug list**. 26.2 replaced it with the
`DebugScreenEntry` system, which is what both Voxy mods register through, and BetterF3's own
`DebugMixin` overrides `getCurrentlyEnabled()` on that list to return a hardcoded one-element list
holding only BetterF3's own entry. **While BetterF3 is enabled, no mod's F3 entry renders at all**,
so the Misc modules have nothing to collect. That was read out of the compiled mixin after the
change had already shipped; it should have been read before.

**To read Voxy's stats in the meantime**, set `"disable_mod": true` in `config/betterf3.json` for
plain vanilla F3, and back to `false` afterwards. That file is never enforced at login and the
updater does not restore it, so the edit is yours to keep.

A first-party fork that lets third-party entries through was offered and declined for now.

---

## v1.0.39

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `3a514f7d1a7a` | `f59606236c9a` | 287 | 135 |

**Small aircraft can be carried, and F3 shows what mods put there.** Two config files. Click **Play**.

### Gyrodynes and quadrocopters are carryable

v1.0.38 blocked every Immersive Aircraft entity from Carry On. That was too blunt: carrying a small
aircraft is useful, and Carry On already refuses anything too big. The blanket entry is gone and the
size limit decides, which also means a future aircraft is classified the day it is added rather than
whenever someone remembers the list.

Carry On allows up to **1.5 wide by 2.5 tall** in survival, compared with `>=`. Against Immersive
Aircraft's registered dimensions:

| Aircraft | Size | |
| --- | --- | --- |
| Gyrodyne | 1.3 x 0.6 | **carryable** |
| Quadrocopter | 1.5 x 0.5 | **carryable** |
| Biplane | 1.75 x 0.85 | too wide |
| Bamboo hopper | 3.0 x 1.5 | too wide |
| Airship | 1.5 x 3.0 | too tall |
| Cargo airship | 1.75 x 3.0 | too wide, too tall |
| Warship | 5.0 x 6.5 | both |

Both numbers were read out of the two mods rather than estimated - the sizes from Immersive
Aircraft's entity registration, the comparison from Carry On's pickup handler.

The other six blacklist entries are unchanged: spawners, trial spawners, vaults, Lootr containers,
Traveler's Backpack blocks and Immersive Paintings.

### F3: this half did not work, and v1.0.40 reverts it

**Struck out.** This release enabled BetterF3's Misc Left and Misc Right modules, on the reasoning
that they show the debug lines other mods add and neither was in the pack's config. They were
indeed missing, but enabling them changed nothing, and the claim that Voxy's stats would appear was
wrong.

Those two modules read the **old string-based debug list**. 26.2 replaced it with the
`DebugScreenEntry` system, which is what Voxy registers through - and BetterF3's own `DebugMixin`
overrides `getCurrentlyEnabled()` on that list to return a hardcoded one-element list containing
only BetterF3's own entry. **No mod's F3 entry renders at all while BetterF3 is enabled**, so there
is nothing for the Misc modules to pick up.

v1.0.40 puts `betterf3.json` back to its v1.0.38 contents, byte for byte. To read Voxy's stats
meanwhile, set `"disable_mod": true` in `config/betterf3.json` for plain vanilla F3 - that file is
never enforced and the edit survives updates.

---

## v1.0.38

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `f59606236c9a` | `a61f7fdb6274` | 287 | 135 |

**Carry On.** Two mods. Click **Play**.

- **Carry On** `2.11.0` - pick up chests, furnaces, barrels and mobs and carry them somewhere else.
  Carrying slows you down, and more so for a bigger block or a bigger animal
- **Carry On Extend** `1.5.1` - throw what you are carrying, with a charge-up power meter

Both run on the server as well as the client, so both were deployed there with this release.

### What you cannot pick up

Carry On's own blacklist is written for packs this one shares nothing with - it knows about Create
and Thaumcraft and not about anything installed here - so seven entries were added for this pack:

| Blocked | Why |
| --- | --- |
| `minecraft:spawner`, `trial_spawner`, `vault` | Carrying a spawner is a mob farm without silk touch |
| `lootr:*` | Its containers hold per-player loot; moving one is a duplication waiting to happen |
| `travelersbackpack:*` | A placed backpack is an inventory |
| `immersive_paintings:*`, `immersive_aircraft:*` | Matching Carry On's own `minecraft:painting` and `vehicle:*` entries |

Everything else the mod allows by default is allowed here, including picking up other players.

`config/carryon-common.json` is enforced at login, because the server reads its own copy of it - a
client that had edited it would be told it can carry things the server refuses. `carryon-client.json`
holds only how a carried thing is drawn and is not enforced.

### Shorter outages from here

Only the push at the end of a deploy needs the server down. The pull before it empties the mirror and
re-fetches all 169 MB of server mods, and it ran **after** the server was stopped, so it sat inside
the outage for no reason - measured at **48.7s**, against **1.0s** for the two files that actually
need re-reading once the server has stopped.

So the deploy is now two scripts, and only the second one needs an outage:

- **`Test-ServerDeployment.ps1`** pulls, works out what changes, stages it, backs up what it
  overwrites and hashes the lot, then writes a plan file. Nothing it does reaches the server, so it
  runs with players still on
- **`Deploy-LiveServer.ps1`** sends that plan and nothing else. It refuses a plan for another
  version, digest or mirror, re-hashes every staged file immediately before sending it, and with
  `-WaitForShutdown` waits for you to stop the server rather than refusing outright

The proof that the server is down is unchanged: a status ping, a refusal to write to a live server,
and a second ping immediately before the first remote byte. `server.properties` and the policy are
re-read after the shutdown - the server escapes `level-type` and restamps its date comment as it
stops, so the copy staged while it was running is already behind. Their backups are re-taken from
what was just read, and the MOTD is re-applied to the fresh copy.

A dry run no longer requires the channel to be ahead of the release, so the plan can be read before
the push instead of only after it.

### The mod inventory is measured again

`docs/archive/audit_mods.json` was assembled by hand during the v1.0.0 audit and then never
regenerated. It claimed 117 client mods against 136 installed, so the inventory that exists to catch
a missing row was missing nineteen. `docs/archive/gen_audit_mods.py` measures it now, and `mods.md`
is generated end to end.

---

## v1.0.37

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `a61f7fdb6274` | `c514e2bfcfcd` | 283 | 133 |

**Selection highlights, in the pack's colours.** Three textures. Click **Play**.

Immersive Interfaces marked the selected hotbar slot and the hovered container slot with metal corner
brackets. Both are now a soft highlight in the pack's own wood tone:

- **`hud/hotbar_selection.png`** - vanilla's box, tinted, and thinned from a **4-pixel border to 2**
- **`container/slot_highlight_front.png`** and **`_back.png`** - vanilla's soft overlay, tinted

**The colour is measured, not chosen.** Sampled from the pack's own `slot.png`, averaging the
mid-tone wood and skipping the dark outlines and the rivets, which gives **#B38C58**. The highlight is
that lifted about 30% to **#E8B672**, so it reads as a highlight sitting on the wood rather than
disappearing into it.

The pack's `slot_highlight_front.png.mcmeta` is dropped: its highlight was 24x48 with two animation
frames and vanilla's is a static 24x24, so the mcmeta would point an animation at frames that no
longer exist. The container highlight no longer pulses.

### The pack is reproducible now

`scripts\Build-ImmersiveInterfaces.ps1` rebuilds the fork from the published Modrinth release plus an
overlay kept in `5. modpack source\custom packs\`. Until now it had been assembled by hand across an
evening, and two of the ways that went wrong are worth keeping in one place:

- **v1.0.33 built it from the author's GitHub `main`, which is not a complete pack** - it is missing
  every `lang/*.json`, and in this pack those are not translations. The container art is drawn as
  glyphs and the language files map each container to its art.
- **The first zip was written with backslash entry paths**, which is what Windows PowerShell's
  `ZipFile.CreateFromDirectory` produces. Minecraft opened the pack, found no assets, and applied
  nothing - indistinguishable from a broken pack.

The script refuses to produce either: it writes forward slashes explicitly and then verifies the
result has no backslash paths, has `pack.mcmeta`, both 26.2 shaders, and at least 100 language files.
It reproduces this release's pack with **zero content differences**, entry for entry.

---

## v1.0.36

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `c514e2bfcfcd` | `3842e2436270` | 283 | 133 |

**The Prism console is fixed, and this time it was measured rather than reasoned about.** Click
**Play**. Nothing else changes.

### What it actually was

A JVM will not exit while a single **non-daemon** thread is alive. A thread dump taken during the
hang showed `DestroyJavaVM` - so `main()` had already returned and the game was completely finished -
with every thread marked daemon except **two** nameless `pool-N-thread-1` threads, both parked
forever in `DelayedWorkQueue.take`. Minecraft's shutdown watchdog gave up on them after fifteen
seconds and halted the JVM, and that halt is a non-zero exit, which is exactly what Prism opens its
console for.

| Mod | | |
| --- | --- | --- |
| **skin_overrides** | schedules three `scheduleAtFixedRate` tasks on a pool created with no thread factory | its own cleanup calls `shutdownNow()` from `Util.shutdownExecutors()`, which **26.2 no longer reaches** on that path - stale hook, not a broken one |
| **Mouse Wheelie** | `new ScheduledThreadPoolExecutor(1)` in `<clinit>`, then a fixed-rate tick | never shut down at all |

No thread factory means `Executors.defaultThreadFactory` - which is what produces the
`pool-N-thread-M` name and, crucially, a **non-daemon** thread.

`nbidal18-skinoverrides` and `nbidal18-mousewheelie` give each pool a daemon factory. A daemon thread
never holds the JVM open, whenever - or whether - cleanup runs. Both pools behave identically while
the game is running.

**Both were verified before shipping**, by dumping the live client's threads and watching each
nameless pool disappear and its named daemon replacement appear, then by a real quit that produced
no watchdog line and no crash report.

### Three earlier attempts were wrong, and are corrected here

**`nbidal18-ixeris` is removed entirely.** v1.0.35 claimed Ixeris busy-spun at shutdown. That was
reasoning from a log tail - Ixeris's "Exiting event polling thread" is simply the last line printed
before the wait - and it fixed nothing.

**v1.0.27 blamed SoundsBegone's telemetry.** It did not cause this either. That fork stays, because
it does stop a PostHog client being built and does make its threads daemon, which is worth having on
its own - but it was never the shutdown fix and this file said otherwise with more confidence than
the evidence supported.

**This release also neutralises the second PostHog client**, in the `meza_core` library SoundsBegone
bundles, which v1.0.27 missed. **That is a privacy change, not the shutdown fix** - it was written
while still chasing the wrong cause, and the dump shows the thread it removes was not the one holding
the JVM open. Kept for what it actually does.

**The lesson, recorded in the mods' own source:** a thread dump lists every non-daemon thread in one
line and would have named both culprits on the first day. Three releases were spent guessing at logs
before anyone took one.

---

## v1.0.35

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `3842e2436270` | `9e2b57ba02e0` | 282 | 132 |

**The Prism console should stop opening when you quit**, and the GUI open animation is back. Click
**Play**.

### The console popup, three releases late

**Ixeris, not SoundsBegone.** `MainThreadDispatcher.runNowImpl` hands work to the process main thread
and then waits for it like this:

```java
sendToMainThread(r);
while (!r.hasFinished) { Thread.onSpinWait(); }
```

A busy spin with **no timeout and no way out**. At shutdown the main thread leaves its polling loop -
it logs `Exiting event polling thread` - so anything queued after that never runs, `hasFinished` never
becomes true, and the render thread spins at full speed until Minecraft's own watchdog halts the JVM.
That halt is a non-zero exit, which is exactly what Prism opens its console for.

The timing was identical in all five logs checked: last line is Ixeris exiting its polling thread,
then fifteen seconds of silence, then `[Client shutdown watchdog #1/ERROR]`.

**`nbidal18-ixeris`** cancels that wait once there is provably nobody left to run the task -
`Ixeris.shouldExit` is set, or the main thread is no longer alive. The task is dropped rather than
run on the wrong thread, because it is a GLFW call and the window is being destroyed anyway. Neither
condition can hold while the game is running.

**v1.0.27's SoundsBegone fork was aimed at the wrong mod.** It is kept - it does stop that mod
building a PostHog client and leaving non-daemon threads behind, which is worth having on its own -
but it never was the cause, and the changelog said so with more confidence than the evidence
supported.

### The GUI animation is back on

v1.0.34 disabled SmoothGUI's open animation because a chest flashed at one row before snapping to
size. **That was never the animation.** It was the broken frame selection, and once Immersive
Interfaces was actually working the flash was gone - re-tested with the animation on and the shipped
packs before restoring it. The container art is drawn from glyphs now, so there is no wrong frame for
an animation to catch mid-flight.

---

## v1.0.34

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `9e2b57ba02e0` | `26c3ec426f67` | 281 | 131 |

**The GUI overhaul actually works now**, three mods are added, and Compact Font is out. Click **Play**.

### Three new mods

| | |
| --- | --- |
| **Accurate Block Placement Reborn 1.4.6** | client only - placing blocks while moving lands where you aimed |
| **Bridging Mod 2.7.0** | client only - crosshair and outline help when bridging |
| **The Block Keeps Ticking 1.2.1** | **client and server** - crops, furnaces, campfires and brewing stands catch up on the time a chunk spent unloaded |

**The Block Keeps Ticking does not keep chunks loaded**, which is the obvious worry. Its 21 mixins are
all growable blocks and block entities - `CropBlock`, `SugarCane`, `AbstractFurnace`, `Campfire`,
`BrewingStand`, `BuddingAmethyst`, `PointedDripstone` - and **none touch chunk loading or tickets**.
It records when a chunk was last loaded and simulates the elapsed time when it loads again. The
server carries it too, because growth is decided there.

### Immersive Interfaces, finally right

v1.0.33 shipped a build of the author's GitHub `main`, and **that repository is not a complete pack**.
It was missing 134 files - every `lang/*.json`. In this pack those are not translations: **the
container art is drawn as glyphs, and the language files are what map each container to its art.**
Without them every storage block fell back to a bare grid with a literal title like `Large chest`,
which is what the last release actually shipped.

This one is the **published 0.8.2 release, whole**, with only the 26.2 work grafted on:

- the author's `_26.2_shaders` overlay and updated `interfaces.glsl`
- **a `text.vsh` port**, written here. 26.2 renamed the `rendertype_text` core shader to `text`, so
  the pack's text shader was a dead file and the glyph art was positioned by vanilla instead of by
  `interfaces_text()` - the art was drawn but offset from the panel it belonged to
- **a fix to the `posCheck` helpers.** Upstream corrects the quad corner index for batched draws
  inside `interfaces()`, but the three helper functions above it still used the raw `gl_VertexID`.
  Chest sizing is a chain of those helpers, so it never matched, `rows` stayed 0, and every chest,
  barrel, ender chest and copper chest drew the one-row frame

### Compact Font is removed

It replaced the font atlas that Immersive Interfaces probes for its marker glyphs. With both
installed, ordinary letters read as markers and the shader **deleted them** - every `t` in the game
vanished, and the deleted glyphs flew across the screen as white streaks. The two cannot both be
installed. Compact Font lost, because it is a font and the other is every container in the game.

### Modded containers fall back to vanilla art

38 keys added, taking each mod's own display name and appending the vanilla art marker: Better End's
10 chests, 10 barrels and 10 chest boats, and Lootr's chests, copper variants, barrel and minecart.

`entity.betterend.*_chest_boat` had **no translation at all**, which is why the raw key showed on
screen. Those now read properly as well as drawing the oak boat art.

**Immersive Aircraft is deliberately left on the vanilla UI** for now.

### Items are no longer dark

The three Weskerson packs shipped an `item.fsh` in their `26.1` overlay that 26.2's item pipeline
does not match - the `item_cutout shader program does not use sampler Sampler1` warning the launch
test has been printing since v1.0.31. Stripped. They keep every 3D model and lose only the emissive
shading, which Weskerson's Torches never had. Renamed with the `nbidal18-` prefix, because they are
forks now.

### SmoothGUI's open animation is off

Its 220 ms scale animation moves GUI vertices while the shader is reading their positions, so a chest
opened as one row and snapped to full size. Off everywhere, which is broader than the fault - a
`screensForceDisabled` list would be narrower, and is untested.

### The dev harness

`Test-ClientLaunch.ps1` gained `-Hold`, `-ReplacePack`, `-ReplaceConfig`, `-World` and `-QuickPlay`.
It stages a throwaway instance, swaps in candidate packs and configs, restores a world and loads
straight into it. None of the above could be judged from a log line, and the updater keeps
`resourcepacks` exact-match so candidates cannot be tested on a real instance. Every fix in this
release was confirmed there before it was built.

---

## v1.0.33

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `26c3ec426f67` | `c39781e18777` | 279 | 128 |

**Immersive Interfaces works.** Every vanilla screen - inventory, chests, enchanting table, the rest -
is styled instead of showing a chest-shaped smear. Click **Play**. Nothing else changed.

### Why it was broken

The pack is a GUI engine written in a **core shader**. Its container textures are single sheets
holding several frames side by side - `generic_54.png` is six chests in a row, one per size - and
`position_tex_color` picks the frame, then *resizes the drawn quad* to fit art that is deliberately
larger than the 176x166 panel Minecraft draws. Nothing about that can be fixed by editing a PNG,
because the panel geometry is Minecraft's, not the pack's.

**26.2 changed GUI rendering and the released 0.8.2 has no shader for it.** Its newest overlay updates
`rendertype_text` for 26.1 - and 26.2 renamed that shader to `text`, so even that was a dead file.
The shader loaded and ran (forcing its output red turned the whole GUI red), computed the screen size
correctly, and still matched no element, so every container drew its raw multi-frame sheet.

**The author has already written the 26.2 port**, in a `_26.2_shaders` overlay on the repository's
`main` branch, declared for formats 88-200 and rewritten to `#version 330`. It is not in any Modrinth
release. This ships a build of that source.

`max_format` is 999 there, so 26.2 accepts the pack outright - the log says *"Removed from
incompatibility list because it's now compatible"* - and it is the one pack dropped from
`incompatibleResourcePacks` in the seed.

Named `nbidal18-Immersive-Interfaces-26.2.zip` because it is a build of an unreleased branch rather
than a version anyone can download, and a file named like the release would be a trap for whoever
reads it next. The JEI and Traveler's Backpack add-ons are untouched; they never needed the shader.

### A dev harness, because this could not be tested any other way

`Test-ClientLaunch.ps1` gained `-Hold`, `-ReplacePack`, `-World` and `-QuickPlay`. It stages a
throwaway instance, swaps in a candidate pack, restores a world, loads straight into it and leaves
the client open. A GUI cannot be judged from a log line, and the updater keeps `resourcepacks`
exact-match, so a candidate dropped into the real instance is deleted before the game starts. The
alternative was cutting a release per attempt.

**It also caught the mistake that wasted the most time here.** A first build of the pack came out
with every entry path written using backslashes - `ZipFile.CreateFromDirectory` on Windows
PowerShell does that - so Minecraft opened the pack, found no assets in it, and applied nothing. It
read as "the pack is broken" when the packaging was.

---

## v1.0.32

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `c39781e18777` | `b447e789e955` | 279 | 128 |

**Fixes v1.0.31: five of the six new packs were switched back off on the next launch.** No pack is
added or removed. Click **Play**.

### What went wrong

`options.txt` holds **two** pack lists, not one. `resourcePacks` is the selection;
`incompatibleResourcePacks` is the list of packs the player has acknowledged through the *"this pack
was made for an older version of Minecraft, use anyway?"* prompt. **Minecraft drops a pack from the
first list at startup unless it is also in the second**, and logs it:

```
Removed resource pack file/Weskerson's Nature.zip from options because it is no longer compatible
```

v1.0.31 seeded only `resourcePacks`. So 3D Food, Nature, Immersive Interfaces and both of its add-ons
were selected once, removed on the next launch, and never seen. Only 3D Items survived, because it is
the one whose declared range reaches past 26.2's resource format of **88**.

**Weskerson's Torches gave the game away.** It declares `min_format 46, max_format 84` - byte-for-byte
the same range as Nature, which was dropped - and stayed selected throughout, because it has been in
`incompatibleResourcePacks` since the owner accepted that prompt for it long ago.

### This was already written down

The v1.0.10 seed sets **both** rows, and its comment says why: *"without its entry there Minecraft
treats it as unacknowledged and drops it from the selection on the first launch that reads the row"*.
Every seed since - v1.0.29 and v1.0.31 included - restated only `resourcePacks` and quietly lost the
second row. It went unnoticed because until now every pack that needed acknowledging had already been
acknowledged by hand on the owner's instance.

The seed now restates both rows, and the list is the game's own, read back out of `options.txt` after
Minecraft had rebuilt it rather than worked out by hand.

### Not a metadata problem

v1.0.31 patched the JEI and Traveler's Backpack add-ons from `supported_formats` to
`min_format`/`max_format`, on the reading that 26.2 refuses the older field. **That patch was not what
was wrong here** - both add-ons were dropped anyway, by the rule above. It is kept because a pack that
parses is strictly better than one that may not, but it is not the fix and should not be remembered
as one.

### Immersive Interfaces still looks wrong on the vanilla inventory

Its mod-support add-ons are fine. The main pack is not, and the cause is **not** its version range:
**26.2 added a `textures/gui/sprites/container/slot/*` family** - helmet, chestplate, leggings, boots,
shield, saddle and the rest - which 1.21.1 baked into the single `container/inventory.png` sheet. So
26.2 draws vanilla slot squares at vanilla coordinates on top of a panel that has its own slots
painted in, and the two do not line up. Immersive Interfaces 0.8.2 is the newest build and targets
26.1.2, before that change.

Left as it is in this release, and being worked on separately.

---

## v1.0.31

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `b447e789e955` | `0ef8c4e74c5a` | 279 | 128 |

**Resource packs only.** No mod, config or server change. Click **Play**.

### Out

**Actually 3D** and **Recolourful Containers**, both by request.

### In, below Weskerson's Torches

Three more packs from the same author, so the 3D look extends past torches:

| | |
| --- | --- |
| **Tools & Utils 2.5** | published as *Weskerson's 3D Items* - 411 item models, the largest of the three |
| **Weskerson's 3D Food 1.0** | 41 food items |
| **Weskerson's Nature 1.02** | 20 items, plus blockstates |

### In, below Compact Font

**Immersive Interfaces 0.8.2**, a full GUI overhaul, with its **JEI** and **Traveler's Backpack**
add-ons. The pack runs both of those mods, so both add-ons have something to target.

### Two of them would not have loaded

The JEI and Traveler's Backpack add-ons declared only `supported_formats` in `pack.mcmeta`, with no
`min_format` or `max_format`. **That is the same shape that made Modded Containers silently vanish in
v1.0.26** - it was never rejected for being too old, it was dropped from `options.txt` and the
texture path everyone suspected was correct all along.

That pack's metadata was re-read to confirm the reading rather than assume it: it declared
`supported_formats` covering **30 to 99**, which already includes 26.2's resource format of **88**.
So the range was never the problem. **26.2 refuses the field itself.**

Both add-ons now carry `min_format`/`max_format` instead and are renamed with the `nbidal18-` prefix,
the same treatment `nbidal18-Weskersons-Torches` already has. The other four packs declare the modern
fields and were shipped untouched.

**Out of range is fine; the wrong field is fatal.** Weskerson's Torches has declared `max_format: 84`
against 26.2's 88 since it was added, and works. A pack whose metadata parses is loaded even when it
says it is for an older game.

### What to expect from 3D Food

These packs get their 3D from item models, but their emissive shading from a custom `item` shader
supplied per game version. 3D Food's newest overlay stops at format 75, so at 88 it gets **the models
but not the shader** - exactly the state Weskerson's Torches has been in all along, whose 26.1
overlay is empty. Nature and 3D Items both carry a 26.1 overlay that does apply.

Immersive Aircraft's UI is still vanilla light. Known, and left for later.

---

## v1.0.30

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | see below | `0ef8c4e74c5a` | `0a1c06ae4da3` | 275 | 128 |

**Far terrain resets. Nothing else changes** - no mod added, removed or updated, no config touched.
The only edit is the sweep token, and the only thing you have to do is click **Play**.

### What went wrong

**EasyAuth, deployed to the server on the evening of 2026-08-31, silently stopped Voxy World Gen
from pre-generating anything.**

EasyAuth blocks custom network packets until a player has logged in. Voxy World Gen's client
announces itself the instant it joins - before `/login` - and the server only generates terrain for
players it has heard that announcement from. So it heard from nobody, and generated nothing, for
about a day. The server's generation counter last grew at 18:12 that evening and never moved again.

There was no error and no warning. The only visible sign was terrain quietly refusing to fill in,
which is exactly what a merely overloaded server looks like - and this one was measured at 20 TPS and
7 ms, so it was not overloaded.

**Adding an exemption for Voxy's channel did not fix it.** After the change and a fresh join the
server still loaded 0 chunks. Whether that exemption works at all here is now unknown, and that
uncertainty applies equally to the one Simple Voice Chat depends on. EasyAuth was removed instead.

### What that left behind

Every client's far-terrain store held a snapshot from before the gap and nothing after it, so the
world it drew and the world that exists had drifted apart - seen in game as flat planes of water
hanging in the air over the ocean.

**Both sides are cleared together in this release.** The client sweep removes `.voxy` and
`xaero/world-map`; the server's `voxy_gen` record is deleted in the same deployment. Clearing one
side alone leaves the two disagreeing about which chunks exist, which is the mismatch that produced
this in the first place.

**Your Xaero waypoints are preserved.** Only the drawn map tiles go.

**Expect no distant terrain at first.** It rebuilds as the server regenerates and streams it out, and
comes back further each session rather than all at once.

### Server, unpublished

EasyAuth is gone from the server. It was server-side only, so it never appeared in the manifest and
its removal moves no digest - but it means **name impersonation is possible again**: the server runs
`online-mode=false` with a name-based whitelist, so anyone who knows a whitelisted name can join as
that player. Left that way deliberately for now. `online-mode=true` is the alternative that cannot
cause this class of failure, because it filters no packets at all.

---

## v1.0.29

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-31 | see below | `0a1c06ae4da331ae` | `b0c7bd8277a4139b` | 275 | 128 |

**3D Maps is out, and Recolourful Containers is back.**

### 3D Maps removed

It reads badly under this pack's shaders, which is the one thing the stock trial in v1.0.26 existed
to find out. Removed from the client and the server; the pack no longer carries `maps3d`.

`nbidal18-3dmaps` goes with it - a fork of a mod the pack does not ship is only a trap for whoever
reads it next. Nothing is lost: v.1.0.28's release folder keeps the full source, and the two
findings behind it are recorded in this file. The patch was never the problem - it built, the server
booted with it, and both mixins applied.

**Any map you filled while the patch was live keeps its data.** `Map3DSavedData` persists a volume
per map and never re-captures a column it already has, so those maps stayed trimmed in the middle
and filled in at the edges as you explored. With the mod gone they are inert either way.

### Recolourful Containers back, on its own

Vanilla containers are coloured again, back in its old place just below Compact Font. Modded GUIs -
the aircraft, the backpack - stay plain: Modded Containers is not compatible with 26.2 as shipped,
and the backpack tint did not match Recolourful's per-region recolouring.

**Actually 3D Blocks & Items** remains the single 3D pack.

**Players need only click Play.**

---

## v1.0.28

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-31 | see below | `b0c7bd8277a4139b` | `8a9719601c679fbb` | 275 | 129 |

**3D Maps goes back to stock, and Actually 3D Blocks & Items comes back on its own.**

### The ore-finder patch is off

`nbidal18-3dmaps` is no longer built, so 3D Maps captures a full voxel volume again and its cutaway
reaches bedrock. **The map can be used to find caves and ores.** That is a deliberate choice to
judge the mod at stock quality first, not an oversight.

The work is intact - the source stays under `custom mods\`, and re-adding one line to
Build-FirstPartyMods revives it. Nothing about the patch was wrong: it built, the server booted with
it, and both mixins applied.

### One 3D pack, not three

**Actually 3D Blocks & Items** returns on its own, directly above `Overlay's` where it used to sit.
3D Default and Refined Buckets stay out.

That was the lesson from v1.0.26: the three together covered 470 of 1,533 items with overlapping and
inconsistent styles, which read as unfinished rather than as a look. One pack of 130 hand-modelled
items is a smaller claim, consistently made.

**Players need only click Play.**

---

## v1.0.27

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-31 | see below | `8a9719601c679fbb` | `cf4890137dc2328e` | 275 | 130 |

**3D Maps can no longer be used to find ores, the client can finally exit, and the visual work is rolled back to plain.**

### The map records one block per column

`nbidal18-3dmaps` trims every captured column to its topmost block before the volume stores it. The
interior is not hidden, filtered or gated - it is never recorded, so there is nothing to reveal.

A Y threshold was the obvious fix and it does not work: a mountain has caves well above any
threshold worth picking. Per-column removes Y from the question entirely and is correct at every
elevation. Digging a shaft does not defeat it either, because the exclusion is per column - a shaft
lowers only its own column, its neighbours keep their surface, and you see the hole you dug.

It is done on the **capture**, which runs server-side, rather than on the renderer or the cutaway
slider. The client only ever draws what `Map3DDataPayload` sends it, so a modified client has
nothing to recover. Same principle as the integrity helper: do not police the client, do not send it
the information.

Cliffs still read as solid because the mesh builder extrudes each column to the volume floor -
`Map3DMesh` already carries `BASE_DEPTH` and a `SURFACE_DETAIL` level for exactly this shape.

Injected at `applyColumn`, the single choke point every captured column passes through, so no
capture path can bypass it. `@Coerce` reaches the package-private `ColumnSample`; both mixins ship
`defaultRequire: 1`, so a failed injection stops the server rather than quietly leaving an ore
finder running.

### The visual work comes out

Everything from v1.0.26 and the three 3D item packs are removed, back to 2D items and a plain
light-mode UI, until the whole look can be settled in one go rather than half-applied.

- **3D Default, Actually 3D Blocks & Items, Refined Buckets.** Between them they covered 470 of
  1,533 items, which read as inconsistent rather than as a style - and they were the source of the
  `Invalid path ..._3D_e.png` errors in every client log.
- **Recolourful Containers**, so vanilla containers go back to plain light mode.
- **`nbidal18-travelersbackpack`.** It worked, but a uniform tint is not what Recolourful does -
  Recolourful recolours a panel region by region - so the backpack looked tinted rather than
  themed. The source stays under `custom mods\`; re-adding one line to Build-FirstPartyMods revives it.

### Modded Containers never loaded at all

Worth recording, because it looked like it simply had no effect. 26.2 **refuses** the pack:

```
Pack key supported_formats is deprecated starting from pack format 65.
Removed resource pack Modded Containers from options because it is no longer compatible
```

Its `pack.mcmeta` declares only `supported_formats`, which throws from format 65 onward, so the pack
was rejected and Minecraft pruned it from `options.txt` on save. The texture path was right all
along - the fork blits `immersive_aircraft:textures/gui/container/inventory.png` and the addon
supplies exactly that. Reviving it needs `min_format`/`max_format` in place of `supported_formats`,
and nothing else.

### The client stopped hanging on exit

Quitting left the process alive for 15 seconds until Minecraft's shutdown watchdog force-killed it.
That exits non-zero, which is why Prism's console appeared long after the window had closed - every
session, on every client.

The thread dump in each crash report showed four threads: the JVM trying to exit, and three that
would not let it. All three came from **SoundsBegone**. Its `Telemetry` builds a PostHog analytics
client and a single-thread scheduler, both non-daemon, and one non-daemon thread is enough to stop
the JVM exiting. It has a `shutdown()` that tears both down correctly, and nothing in the mod ever
calls it.

Its own telemetry setting could not have fixed this: the constructor builds PostHog *before*
consulting the toggle, so the setting only decides whether events are sent, never whether the
threads exist.

`nbidal18-soundsbegone` makes the scheduler a daemon thread, never builds the PostHog client, and
drops the one call that would have used it. Sound muting is untouched. What stops is the reporting -
by default it sent the player's OS, Java version, language and muted sounds to eu.posthog.com, keyed
by a hash of their username.

**Drop this fork when upstream calls its own `shutdown()`.** The build fails loudly if the redirects
stop matching, which is the signal to check.

**Players need only click Play.**

---

## v1.0.26

| Date | Commit | Manifest digest | Replaces | Files | Mods |
| --- | --- | --- | --- | --- | --- |
| 2026-08-31 | see below | `cf4890137dc2328e` | `592006cd06c62322` | 279 | 129 |

**Modded container GUIs get colour, and 3D Maps goes in for evaluation.**

### The backpack panel now matches the backpack

Recolourful Containers colours every vanilla container after the block it belongs to, which left
Traveler's Backpack as the one screen still flat grey - and it was only noticeable *because* the
vanilla ones had been coloured.

No resource pack can fix it. The mod draws one background texture for all 44 backpacks, and a dyed
backpack carries an arbitrary RGB value, so there is no finite set of textures anyone could author.
Every pack that targets this mod is dark-mode, or 4x resolution, or stops at 1.20.2.

`nbidal18-travelersbackpack` tints the panel instead. A dyed backpack uses its dye; anything else
uses the colour **sampled from that backpack's own texture at build time** - bee yellow, diamond
cyan, creeper green, standard dark brown, netherite grey. `generate_backpack_colors.py` reads all 44
textures out of the mod's jar, so a backpack added by a future update is themed by the next build
with nobody choosing a colour for it.

Brightness is normalised into a readable band while hue and saturation are left alone: the panel is
`#C6C6C6`, and an unmodified standard-backpack brown would render the inventory nearly black. Slots
stay vanilla grey for free, because `slots.png` is a separate texture the tint never reaches.

### The aircraft screen

**Modded Containers v6** (light) covers `immersive_aircraft`. It declares pack formats 30-99, so
26.2 loads it without a compatibility warning.

It sits **directly below Recolourful** in the pack list, and that ordering is load-bearing: it
overrides 115 vanilla files, 14 of which Recolourful also replaces. Below it, Recolourful keeps every
vanilla container and Modded Containers still supplies the modded namespaces - which is the only
reason an addon built for a different GUI family works alongside this one.

### 3D Maps, stock and unpatched

**Maps in item frames render as 3D terrain.** Installed as shipped, to confirm it works with this
pack's shaders before any work goes into it.

**It can currently be used to find ores.** Its cutaway defaults to y=48 and can be dragged to -64,
and the volume it captures genuinely includes what is underground. That is a known, temporary state:
the next release patches the server-side capture to record one surface block per column, after which
the data simply does not exist to reveal. Shipping it stock first is deliberate - there is no point
patching a mod that turns out to render wrong on these shaders.

**Players need only click Play.**

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
