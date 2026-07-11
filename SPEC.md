# BUILD PROMPT — "Purrvivors" (Godot survivor-like)

> Paste this whole file into an AI coding tool (Claude Code, Cursor, or Claude Desktop) that has the **PixelLab MCP** connected. It will generate all pixel art via PixelLab and build a complete, playable game in Godot 4.x that runs on **web, mobile, and desktop**.

---

## ROLE & OBJECTIVE

You are a senior Godot game developer. Build a **complete, playable, polished, cross-platform** top-down survivor-like (Vampire Survivors–style) called **Purrvivors** in **Godot 4.x using GDScript**. The game must run and feel good on **Web (browser), Mobile (touch), and Desktop (keyboard)** with a **responsive** layout. You have access to the **PixelLab MCP** for pixel-art generation — use it to create **every visual asset** so the game looks cohesive and finished. No placeholder colored rectangles in the final build.

**Elevator pitch:** You play a cute cat swarmed by growing hordes of critters — mice, dogs, roombas, dashing cats and more. Auto-attack fights them off, and **defeated enemies drop tasty snacks** — gobble them up to gain XP and level up. Survive 15 minutes and the bosses, earn Fish Coins, and spend them in the Cat Café shop on permanent upgrades and new cats.

---

## CRAFT BAR — THIS MUST NOT FEEL LIKE "AI SLOP" (read first; governs everything below)

Top priority, above feature count: the finished game must feel **intentional, cohesive, and hand-crafted** — like a small studio made it with love — never generic, template-swapped, machine-spat filler. **AI-generated art and code are raw material to be curated, not shipped as-is.** Hold this bar on every asset, system, and screen.

**Creative pillars — everything serves these:**
- **Cozy but chaotic:** a warm, charming cat world that erupts into satisfying horde mayhem.
- **Readable & juicy:** the player always understands the screen, and every action feels good.
- **Charming, with personality:** humor and cuteness live in the *details*, not just the premise.

**Anti-slop rules:**
1. **One art direction, ruthlessly consistent.** Single locked palette, **one pixel density** (never mix sprite scales), nearest-neighbor + integer scaling, cohesive outline/shading. **Curate, don't dump:** review every generated asset against the anchor style and **regenerate anything off-model, muddy, wrongly-lit, or generic.** If it doesn't sit with the others, it doesn't ship.
2. **Game feel is non-negotiable.** Weighty movement, snappy hit feedback, **hit-stop** on big hits, knockback, screen shake, particles, satisfying pickups, easing with anticipation + follow-through. Nothing floaty, weightless, or abrupt.
3. **Personality & voice everywhere.** Characterful, funny copy — never "Enemy" / "Upgrade 1" / "Play." Name every weapon, passive, enemy and cat with charm; add flavor text, cheeky level-up blurbs, cute menu/results lines, tiny reactive touches. Carry the Cozy Cat Café identity into *every* screen.
4. **Sound sells it.** Cohesive, characterful SFX + music that fit the tone (playful, punchy). Silence or generic beeps read as unfinished.
5. **Finish the last 20%** — the details AI projects skip: transitions between every state, empty/edge states handled, consistent spacing/alignment, **idle animations** (a breathing/tail-flick idle beats a static sprite), satisfying feedback loops. No hard cuts, no gray boxes, no dead ends.
6. **Depth, not a checklist.** Weapons must *feel* distinct and combine into builds; upgrades must matter; difficulty + economy must be tuned (see Balance & Tuning). Systems that merely "exist" are slop.
7. **Small delights.** Bake in a few surprises — an easter-egg cat, a rare golden snack, a silly boss intro, reactive flavor — the touches that signal a human cared.

**Before calling it done, run a "does this feel crafted?" pass:** actually play it, view every screen and asset *together*, and fix anything that reads as generic, inconsistent, unfinished, or soulless. When in doubt, **polish over adding**.

---

## TECH CONSTRAINTS

- **Engine:** Godot **4.x** (current stable 4.x APIs — `CharacterBody2D`, `Area2D`, signals, `@export`, typed GDScript).
- **Language:** GDScript only.
- **Perspective:** 2D top-down, camera-follow arena.
- **Platforms (all first-class, from the start):** Web (HTML5/WASM), Mobile (touch), Desktop (Windows/macOS/Linux, keyboard). Set up export presets for each and verify the **web build runs in a browser**. **Mobile scope, realistically:** full touch support + responsive layout verified via a phone browser or emulated mobile viewport; configure the Android/iOS export presets but **do not attempt to build/sign native binaries** (that needs platform SDKs + certificates the user will handle later).
- **Responsive:** UI and play area must adapt to any screen size, aspect ratio, and both portrait & landscape.
- **No paid plugins.** PixelLab MCP for art; Godot built-ins for everything else.

---

## CROSS-PLATFORM & RESPONSIVE (build this in from day one — do not bolt it on later)

### Display / scaling
- Project Settings → Display → Window → **Stretch mode = `canvas_items`**, **Aspect = `expand`**. Set a sensible base viewport reference; let it expand to fill any aspect.
- **Camera:** drive `Camera2D.zoom` from the current viewport size so a consistent slice of the arena is visible on every device (phones shouldn't see a tiny sliver; desktops shouldn't see too much). Recompute on window `size_changed`.
- Support **both portrait and landscape**; recompute layout + camera on resize/orientation change.

### Responsive UI
- Build **all** HUD and menus with `Control` nodes using **anchors + containers** (`MarginContainer`, `VBoxContainer`/`HBoxContainer`, `AspectRatioContainer`). Never hardcode pixel positions for UI.
- Scale fonts/UI with screen size (scalable theme). Test at phone portrait, tablet, and wide desktop.
- **Safe areas / notches:** keep interactive UI inside `DisplayServer.get_display_safe_area()`; add margins so nothing hides under a notch or rounded corner.

### Adaptive input
- **Desktop/keyboard:** WASD/arrows for movement. Attacks are **automatic** (classic survivor-like) — the player only steers.
- **Mobile/touch:** on-screen **virtual joystick** (bottom area) for movement + a pause button. Because attacks auto-fire, **no attack buttons are needed** — perfect for touch.
- Show touch controls **only** on touch devices — detect via `DisplayServer.is_touchscreen_available()` and/or first touch event; hide on desktop. Web can run on phones, so support both touch and keyboard on web.
- Unified movement: resolve the move vector from whichever source is active (joystick OR keyboard).

### Web-specific
- **Audio autoplay:** browsers block audio until a user gesture — unlock/start audio on first tap/click/keypress.
- Handle browser **canvas resize** (covered by the responsive layout + resize handling above).
- **Auto-pause on focus loss** (tab switch / phone lock / window blur) — resume via the pause menu.
- Keep the web build lightweight; confirm smooth frame rate with a full horde on screen.

### Performance (critical now that it targets web + mobile)
- **Object pooling** for enemies, projectiles, **and dropped snacks** — survivor-likes spawn hundreds of nodes; instancing/freeing every frame will stutter on web/mobile. Pre-instance and reuse via a pool autoload.
- **Do NOT give every horde enemy a full physics body.** Hundreds of `CharacterBody2D`s will tank web/mobile framerates. Swarm/chaser enemies should use **lightweight manual movement** (plain `Node2D`/`Area2D` + velocity math + a simple spatial grid or distance checks for separation and hit detection). Reserve `CharacterBody2D` physics for the **player and bosses** only. Profile with 300+ enemies on the web build early.
- Simple collision shapes; cap on-screen entity counts; distance-cull or use `VisibleOnScreenNotifier2D` where helpful.
- Test GPU vs `CPUParticles2D` on web — fall back to cheaper effects if particles are heavy.

---

## PIXELLAB ASSET PIPELINE (do this FIRST, before gameplay code)

### Setup
- Confirm the PixelLab MCP is available. Inspect exact tool schemas before calling — do **not** assume argument names. Expected tools include roughly:
  - `create_character(description, n_directions=8, ...)` → directional character sprite sheets
  - `animate_character(character_id, animation)` → walk / idle / run animations
  - `create_tileset(lower, upper, ...)` → Wang tilesets for ground
  - `generate_image_pixflux(description, ...)` → general text→pixel-art (icons, pickups, projectiles, UI)
  - `generate_image_bitforge(description, style_reference, ...)` → style-matched generation
  - `get_balance()` → remaining credits / generations
  - `save_to_file` param on generators → write PNG to disk
- Read the PixelLab **Godot** resource docs before building tiles, e.g. `pixellab://docs/godot/wang-tilesets` and `pixellab://docs/godot/isometric-tiles`. Follow their TileSet setup exactly.

### Budget & diversity plan (use the plan's full monthly pool — but wisely)
**Goal: maximize *meaningful* visual diversity within the paid plan's monthly generation pool.** Protocol:
- Call `get_balance()` first, tell me the number, and treat the remaining monthly generations as the budget.
- **Test cheaply before committing:** generate ONLY the anchor cat + one enemy + one snack, wire them in, confirm crisp import in Godot. Then proceed.
- **Reserve ~25% of the pool for iteration/regeneration** (many assets need a second try). Spend up to ~75% on new assets.
- Generate in **priority tiers** (see "Diversity expansion" below): finish Tier 1 (core) first, then work *down* the tiers, checking `get_balance` between tiers and **reporting spend after each**. Stop as you approach the cap and tell me what got skipped.
- **Multiply for free at runtime — don't spend generations on it:** elites, seasonal recolors, and palette skins = tint + scale in Godot. Reserve generation budget for distinct silhouettes and animations, the things players actually notice.
- Async (~2–5 min each) and rate-limited — **pace batches**, poll, save each into `res://assets/…`. Don't fire hundreds at once.
- **Keep the web build lean:** pack sprites into **texture atlases**, compress, and after the asset pass check the web export's download size + load time. Diversity must not tank web/mobile performance.

### Style consistency (this is what makes it polished)
1. Generate the **first cat** as the visual anchor.
2. For every later asset, pass that sprite as the **style reference** (`generate_image_bitforge`, `style_reference`) so palette/outline/shading stay consistent.
3. Lock a shared spec in every prompt: *"cute chibi pixel art, top-down 3/4 view, thick dark outline, soft pastel palette, 48×48 (characters) / 16×16 (pickups), transparent background."* Keep sizes consistent.
4. **Generate the title/menu background LAST,** once the palette is established, using the same style reference + palette so it matches the sprites. Full scenes are the hardest to style-match — if a couple of regens don't land, fall back to composing the menu from the tileset + props + logo (guaranteed consistent).

### FULL ASSET MANIFEST
Generate all of the following into an organized `res://assets/` tree.

**Playable cats — `create_character`, 8 dir, + walk & idle animations:**
1. `tabby` — orange tabby, balanced (the anchor).
2. `chonk` — big grey chonky cat, tanky & slow.
3. `kitten` — tiny black kitten, fast & fragile.

**Enemies — `create_character`, 8 dir, + walk animation (~8 archetypes for variety over a full run):**
`mouse` (tiny swarmer), `bee` (flying swarmer), `dog` (basic chaser), `raccoon` (erratic chaser), `roomba` (slow tank), `rival_cat` (fast dasher), `crow` (dive-bomber), `dust_bunny` (splitter — spawns 2–3 minis on death), `sprinkler` (slow/stationary ranged poker). Generate ~8 of these.
*Elite variants cost no extra generation:* at runtime, **tint + upscale** any base sprite for tougher "elite" versions (more HP/damage, bonus coins).

**Bosses — `create_character`, larger (~96×96), + walk + a telegraphed attack frame — ONE PER 5-MIN MILESTONE:**
`boss_bulldog` (5:00 — charging bruiser), `boss_vacuum` (10:00 — summons mini-roombas / AoE suck), `boss_fatcat` (15:00 — FINAL boss, multi-phase; defeating it clears the run). Each drops big Fish Coins + several snacks. (To save credits you *could* palette-swap one boss sprite across milestones, but distinct bosses are more fun.)

**Snacks / XP pickups — `generate_image_pixflux`, 16×16 icons:**
`cookie` (small XP), `fish` (medium XP), `sushi` (big XP), `milk_carton` (rare heal). These are **dropped by enemies** (see below).

**Weapon / projectile FX — `generate_image_pixflux`, small transparent sprites:**
`hairball`, `laser_dot`, `thrown_fish`, `sparkle`, `claw_swipe` (arc), `meow_ring` (expanding shockwave).

**Ground tilesets — `create_tileset` (Wang), per the Godot tileset doc:**
`kitchen_floor`, `backyard_grass`, `living_room`. One per run or rotate.

**UI / HUD — `generate_image_pixflux` (design panels/frames/buttons as 9-slice: generous borders, flat centers):**
XP bar frame + fill, heart/health icon, Fish Coin icon, level-up **card frame**, button (normal/hover), shop-panel frame, **virtual joystick base + thumb** (for touch), pause button, and a title logo "Purrvivors".
*Also needed (external, not PixelLab):* a free **pixel font** — see the UI Design & Theming section.

**Scenery / props — `generate_image_pixflux` (static decorative sprites, ~24–48px):**
`food_bowl`, `water_bowl`, `food_bag`, `cardboard_box`, `potted_plant`, `cat_tower`, `yarn_ball`, `rug_patch` (≈8). Optional per-theme accents (~2–3 more): `garden_bush` (backyard), `couch` (living room), `fridge` (kitchen). Scatter a handful per run as **non-colliding decoration** by default (so they don't snag the horde's pathing); optionally flag 1–2 as solid cover. Randomize placement each run so the map feels fresh.

**Title / menu background — one large `generate_image_pixflux` (~400×400, tier-capped resolution):** a cozy illustrated scene of cats surrounded by snacks in a warm room, shown behind the logo and menus. (This is the only "full picture" asset — the in-game floor is a repeating tileset, not a background image.)

> **Everything above = TIER 1 (core, ~65 generations).** Generate and wire it up first. Then add diversity from the tiers below, in order, until you approach the budget cap. The top tiers add the most noticeable variety per generation.

### DIVERSITY EXPANSION (generate down this list as the monthly pool allows)
- **Tier 2 — Animation depth (highest value):** add **hurt + death** animations to every cat and enemy, and an **attack** animation to cats + bosses. Death animations especially sell the polish.
- **Tier 3 — Enemy roster (variety):** +6–8 more archetypes (target ~14–16 total) so each biome fields a different cast — e.g., `ant`/`cockroach` (kitchen swarm), `frog`/`snail`/`wasp` (backyard), `pigeon`/`sewer_rat`/`drone` (city). Reuse the existing behavior archetypes; only the sprite is new.
- **Tier 4 — Biomes (fresh scenery):** +3–4 more `create_tileset` environments (target ~6–7): `bathroom`, `garage`, `rooftop`, `park`, each with 3–4 biome-specific props.
- **Tier 5 — Playable cats:** +2–3 more cats (target ~5–6), each a distinct look + signature starting weapon. (Cosmetic skins = runtime tints, not generations.)
- **Tier 6 — Icon set:** a dedicated icon per **weapon, passive, and shop upgrade** (clearer level-up cards + shop). If weapon evolutions are enabled, add evolved-weapon sprites + their FX.
- **Tier 7 — More bosses & phases:** +2–3 additional rotating bosses, plus **phase-2** sprites for the existing three.
- **Tier 8 — Pickups & world objects:** many more snack varieties (visual flavor), plus `chest`, `crate` (breakable), `coin_pile`, `magnet`, `bomb`, and a couple of hazard sprites.
- **Tier 9 — UI flourish:** menu banners, achievement/unlock badges, difficulty-tier icons, a game-over stamp, loading art.

Report budget spent after each tier; stop before crossing the ~75% cap.

> After generation: import PNGs with **filter OFF** (nearest-neighbor) so pixels stay crisp. Build `AnimatedSprite2D`/`SpriteFrames` from the directional sheets (map 8 directions to movement angle).

---

## RUN GOAL — WIN & LOSE CONDITIONS

- **Primary goal:** beat as many of the 3 milestone bosses (5:00 / 10:00 / 15:00) as you can while surviving. Difficulty ramps throughout; the final minutes are a swarm crescendo.
- **A run is a WIN if you defeat at least 1 boss — even if your cat dies before 15:00.** The win *tier* scales with bosses beaten:
  - 🐾 **Tier 1 — Bronze Paw:** 1 boss defeated → small Fish Coin bonus.
  - 🐾🐾 **Tier 2 — Silver Paw:** 2 bosses defeated → medium bonus.
  - 🐾🐾🐾 **Tier 3 — Golden Paw (full clear):** all 3 bosses (you survived to 15:00 and beat the final boss) → large bonus + unlock/achievement. Optional **endless overtime** afterward for a high score.
- **The only non-win outcome is "Defeat":** HP reaches 0 with **0 bosses** beaten. Even then the roguelite rule holds — **all Fish Coins and unlocks earned that run are kept.**
- **Layered objectives that give each run purpose:**
  - *Immediate:* eat snacks, level up, survive the next wave.
  - *Run:* build a strong weapon + passive combo, beat the milestone bosses, rack up kills/coins, reach the final boss.
  - *Meta:* spend Fish Coins in the Cat Café on permanent upgrades, unlock new cats, and clear runs / harder cats you couldn't before.
- **Scoring:** track kills, survival time, bosses beaten, and a final score on the results screen; **save the best win tier + best score per cat.**

---

## CORE GAMEPLAY LOOP

1. Pick a cat → spawn in the arena.
2. Move (keyboard or touch joystick). **Attacks auto-fire** at nearby enemies.
3. **Defeat enemies → each dead enemy drops a snack where it fell.**
4. Walk over dropped snacks to eat them → gain XP.
5. Fill the XP bar → **level up** → game pauses, offers **3 random upgrade cards** (new weapon / weapon level-up / passive). Pick one, resume.
6. Enemies spawn in escalating waves and chase you; contact damages you.
7. Survive the run timer; a **boss** appears at every 5-min milestone (5:00, 10:00) and the **final boss** at 15:00 (the climax).
8. **Win** by defeating ≥1 boss — win tier (1–3 paws) = bosses beaten; only a 0-boss death is a **Defeat**. Either way, tally **Fish Coins** (kept regardless) + tier bonus → results screen → shop.

---

## PLAYER

- `CharacterBody2D`, 8-directional movement, normalized velocity, exported `move_speed`, `max_hp`, `pickup_radius`.
- Sprite swaps animation/direction by velocity angle (8-way); idle when still.
- Brief invulnerability + flash on hit. `Camera2D` follows smoothly.
- Per-cat base stats differ (tabby balanced / chonk tanky-slow / kitten fast-fragile).
- (Input is adaptive per the Cross-Platform section — keyboard on desktop, joystick on touch.)

## SNACK DROPS, XP & LEVELING

- **Snacks come from defeated enemies only — there is NO random/ambient spawning on the map.**
- On death, an enemy instances a **Snack** pickup at its position (pooled). Snack type scales with enemy tier:
  - mouse → `cookie` (small XP), dog/roomba/raccoon → `fish` (medium), rival_cat/tanky → `sushi` (big), **boss → several snacks + a guaranteed special drop**.
- **Rare bonus drops** (low rates): `milk_carton` (heal), Fish Coin bonus, and an optional "vacuum" pickup that magnets all on-screen snacks.
- Default drop rate ≈ 100% of kills yield an XP snack (tune per tier) so XP keeps flowing; weakest enemies may drop less if balance needs it.
- **Pickup behavior:** within `pickup_radius` the snack magnets toward the player, then is eaten → XP. XP curve grows per level; on level-up, pause tree, show 3 weighted-random cards (no maxed dupes), apply, unpause.

## WEAPONS & PASSIVES (a fun mix)

Start with one weapon; gain more via level-ups (max ~6 weapons + ~6 passives). Each weapon ~5 levels scaling damage/count/area/cooldown.

**Weapons:** Hairball Spit (auto-fire at nearest), Claw Swipe (melee arc), Laser Pointer (orbiting/sweeping dot), Thrown Fish (returning boomerang), Meow Shockwave (periodic expanding AoE).

**Passives:** Milk (HP regen), Catnip (+damage), Collar (+move speed), Bigger Bowl (+pickup radius), Nine Lives (extra revive), Lucky Paw (+card luck).

*(Optional stretch, OFF by default per "standard" scope: weapon "evolutions" when a maxed weapon + specific passive combine, e.g. Laser Pointer + Catnip → "Death Ray." Leave hooks.)*

## ENEMIES, WAVES & BOSSES

- Base enemy: **lightweight pooled node** (see Performance — NOT a `CharacterBody2D` for swarm types) steering toward the player; exported `hp`, `speed`, `damage`, `xp_value`, `coin_value`, `drop_type`, `behavior`.
- **On death: spawn the matching Snack drop (pooled) + death poof particles.**
- **Behavior archetypes (this is what keeps 15 min fun — variety, not just numbers):**
  - *Swarmers* (mouse, bee): weak, fast, spawn in large packs — the core "horde" feel.
  - *Chasers* (dog, raccoon): steady pursuers, the bulk of the crowd.
  - *Tanks* (roomba): slow, high HP, soak damage and body-block.
  - *Dashers* (rival_cat, crow): telegraphed dash/dive at the player, then recover.
  - *Splitter* (dust_bunny): on death, spawns 2–3 mini versions.
  - *Ranged poker* (sprinkler): keeps distance and lobs a slow projectile, forcing you to keep moving.
- **Elites:** periodically upgrade a spawned enemy to an **elite** (runtime tint + upscale, ~3× HP/damage, bonus coins) — cheap variety, no extra art.
- **HORDES:** the **spawn director** ramps on-screen enemy count from a handful early to **hundreds** by late-game, scaling rate/count/mix and toughness with the run clock. Include periodic **swarm surges** and **pincer waves** from multiple screen edges, with short breathers between. Spawn just off-screen around the player. (Director handles ENEMIES only — not snacks.) *Object pooling is mandatory to keep this smooth on web/mobile.*
- **Bosses — one at every 5-minute milestone (5:00, 10:00, 15:00),** each tougher: `boss_bulldog` → `boss_vacuum` → `boss_fatcat` (final). High HP, telegraphed attacks, big Fish Coin + snack drops. **Each boss beaten raises the run's win tier (see Run Goal); the 15:00 final boss = Golden Paw / full clear.** **Boss rules:** a spawned boss **persists until killed** (it doesn't despawn); the next milestone boss spawns on schedule even if an earlier one is still alive; regular spawns continue during boss fights (slightly reduced rate); **only killed bosses count toward the win tier**, in any order.
- Enemies flash on hit and poof on death.

## DIFFICULTY CURVE (incremental — this is the roguelite gate)

Difficulty must **rise continuously across the 15-minute run**, driven by elapsed time. A fresh, un-upgraded cat should **NOT** be able to reach 15:00 on run one — it should die partway (earning a Bronze/Silver Paw + coins), and **only a well-built, meta-upgraded character clears the full run.** That gap *is* the core loop, so tune the ramp to enforce it (but keep partial-win tiers feeling like real progress — a climb, not a brick wall).

- **Global difficulty scalar** that increases with run time (step up every ~30–45 s), multiplying enemy **HP, damage, spawn rate, and the on-screen count cap**. Document the formula; keep it tunable.
- **Enemy tiers unlock over time** so the *cast* gets harder, not just the numbers:
  - **0–3 min (Tier A):** weak swarmers + basic chasers only.
  - **3–6 min (Tier B):** add tanks + dashers.
  - **6–10 min (Tier C):** add splitters + ranged pokers; heavier packs.
  - **10–15 min (Tier D):** full mix, dense hordes, **frequent elites**.
- **Elite frequency ramps** with time (rare early → common late). **Density** grows from a few dozen on screen to **hundreds** by the end (pooling keeps it smooth).
- **Boss checkpoints (5 / 10 / 15)** are difficulty spikes and skill checks — each a wall a fresh build won't pass, which is exactly why meta-progression matters.
- **Intended pacing:** a starting cat ≈ reaches boss 1; modest upgrades ≈ reach boss 2; a strong build + upgrades achieves the Golden Paw full clear. Target **~8–15 runs to first full clear** — tunable (see Balance & Tuning).

## META-PROGRESSION & SHOP (the roguelite layer)

- **Currency:** **Fish Coins**, earned per run (kills, bosses, survival) **plus a win-tier completion bonus** (Bronze/Silver/Golden Paw). Persist across runs.
- **Save system:** `user://save.cfg` (`ConfigFile`) or JSON storing Fish Coins, purchased upgrades, unlocked cats, best tier/score per cat — **with a `schema_version` field** and graceful migration/fallback if the format changes. Load on boot. (Works on web via `user://` too.)
- **Cat Café shop** (menu): permanent upgrades applied to every future run — +Max HP, +Move Speed, +Pickup Radius, +Starting Damage, +Luck, +Starting weapon level, Revive token — plus **unlock new cats** (chonk, kitten) for coins.
- Clearly show current coins, purchased tiers, locked/unlocked cats.

## BALANCE & TUNING (must be well-calculated, not guessed)

Treat balance as a first-class deliverable. **Centralize every tunable number in data** (exported resources / `.tres` / a `Balance.gd` config autoload) — never scatter magic numbers through gameplay scripts — so the whole game can be retuned in one place.

- **Weapons — parity with distinct roles:** at equal investment, weapons should sit in a comparable **DPS band**, each with a clear niche and tradeoff (single-target vs AoE, melee vs range, steady vs burst, reliable vs high-ceiling). **No dominant weapon, no dead weapon.** Define each weapon's per-level curve (damage / cooldown / count / area / pierce) as data and sanity-check effective DPS per level on paper.
- **Enemies — threat-proportional stats & rewards:** HP / damage / speed / spawn-weight per type, all scaled by the time scalar. **XP and coin values scale with how dangerous/tanky an enemy is** (a tank is worth more than a swarmer); elites and bosses pay out accordingly.
- **Economy — a deliberate curve:**
  - **XP curve:** ~a level-up every few seconds early, gradually slowing, so choices stay frequent but meaningful.
  - **Coin income vs shop cost:** per-run income should make a *dent*, not buy everything — shop upgrades on an **escalating cost curve** so real power takes several runs. Win-tier bonuses calibrated so higher paws are clearly worth pushing for. Cat-unlock costs priced as milestone goals.
- **Power budget across runs:** shop upgrades + a good in-run build should roughly equal what's needed to survive the late-game scalar — a full clear **achievable with mastery**, neither trivial nor impossible.
- **Verify, don't vibe:** include a **debug/balance mode** (toggle god-mode, scrub run time, force-spawn enemies/bosses, grant coins/levels) to test each stage fast. Do a tuning pass and leave a short **balance table** (comment or doc) listing the key numbers + reasoning so I can adjust them.

## UI DESIGN & THEMING (polished from the first build — no default gray Controls)

Default `Control` nodes look generic; a polished game never ships them raw. Build a real design system:

1. **One global `Theme` resource (`ui_theme.tres`), applied at the root** — it styles every button, panel, label, bar and slider at once. Define all `StyleBox`es, fonts, colors and constants here. *A gray default Control anywhere is a bug, not a placeholder.*
2. **Pixel font — set this up on day one.** PixelLab doesn't generate fonts, so bundle a free pixel/bitmap font (e.g. Daniel Linssen's *m5x7 / m6x11*, *Press Start 2P*, *Silver*, or Google Fonts' *Pixelify Sans / Tiny5*). Import with **filtering OFF, hinting None, antialiasing off**; use sizes that are clean multiples. This sells the aesthetic more than any single sprite.
3. **9-slice every panel & button.** Use the generated panel/button/frame art as `StyleBoxTexture` (or `NinePatchRect`) with correct 9-patch margins, so pixel frames scale crisply to any resolution without stretching the corners — required for the responsive/multi-device target.
4. **Full interaction states** in the theme: normal / hover / pressed / disabled / focus, plus a subtle **scale or shift `Tween` on hover/press** so every interactive element reacts.
5. **Design tokens — define once, reuse everywhere:** the pastel palette from the sprites, a spacing scale (4 / 8 / 16 / 24 px), font sizes (title / heading / body / small), one corner + outline style. Consistency is what reads as "polished."
6. **Themed, diegetic menus — not generic screens.** Default direction = **"Cozy Cat Café":** warm cream/paper panels with soft dark outlines, wood + café accents, paw-print bullets and food motifs. The shop is a café storefront; the pause panel is a cardboard box; buttons look like rounded tiles or food bowls; the title uses the illustrated background + logo. Carry this identity through every screen.
7. **Motion & feedback (polish = movement):** drive transitions with `Tween` — menus slide/fade in, dialogs pop with a slight bounce, level-up cards **deal in** one at a time, the Game-Over coin total **counts up**, states cross-fade. No instant hard cuts.
8. **Apply the Theme + font EARLY** (right after the core loop runs), using temporary flat StyleBoxes in the palette until the 9-slice art is generated — so every milestone looks intentional and you never see a "gray box" build.

## UI / HUD (screens)

- In-run HUD: styled XP bar + level number, heart row, prominent run timer, Fish Coin count, kill count; **touch joystick + pause button on touch devices**; anchored inside mobile **safe areas**, non-intrusive.
- Level-up: 3 upgrade **cards** (icon + name + effect) on the themed card frame; they animate in; tap/click to pick.
- Menus: Title (logo over the illustrated bg), Play (cat select), Cat Café (shop), Pause, **Results** (earned **win tier — 1–3 paws** + bosses beaten, survival time, kills, and counting-up coins + tier bonus → menu).
- All built with responsive `Control` containers **inheriting the global Theme** — consistent pixel scale, tested at phone-portrait, tablet, and wide-desktop aspect ratios.

## POLISH / "JUICE"

- Screen shake on boss hits / player damage. Hit-flash on damageable entities.
- Particles: snack-eat sparkle, enemy death poof, level-up burst (web-friendly; fall back to `CPUParticles2D` if needed).
- Damage numbers optional.

## AUDIO & MUSIC (PixelLab can't do this — source it deliberately)

Sound is part of the craft bar, and every file ends up in a **public repo**, so it must be license-clean:
- **Sources (CC0/public-domain first):** SFX from **Kenney.nl audio packs** (CC0) or **freesound.org filtered to CC0**; music from CC0/CC-BY chiptune packs (e.g. OpenGameArt filtered by license) — cute, playful, loopable. Alternatively **generate retro SFX procedurally** with a jsfxr/sfxr-style tool for a perfectly cohesive set.
- **Required SFX set:** snack eat (a cute *nom*), level-up jingle, player hit, enemy hit + death poof, coin, boss intro roar + boss defeat, button hover/click, win-tier fanfare (escalating per paw tier). **Music:** one cozy menu loop + one energetic run loop (optionally intensify late-run).
- **Cohesion rule:** all SFX from one pack/generator family so they sound related — mixed-source grab-bags read as slop.
- **Licensing:** record every file's source + license in `CREDITS.md` (include font attribution too); CC-BY requires attribution — CC0 preferred. **No unlicensed rips, ever.**
- Route everything through an audio bus with a volume setting + the **web audio unlock on first input**.

## SUGGESTED SCENE / SCRIPT ARCHITECTURE

- `Main.tscn` (root; state machine: Menu / Playing / Paused / GameOver)
- `Player.tscn` (+ `player.gd`), `Enemy.tscn` base + variants, `Boss.tscn`
- `Snack.tscn` (pickup; **spawned by enemies on death**, pooled)
- Weapons as scenes/resources under a `WeaponManager` on the player
- `Spawner.gd` (enemy director only), `XPSystem.gd`, `UpgradePool.gd`
- `HUD.tscn`, `LevelUpScreen.tscn`, `Shop.tscn`, `TitleScreen.tscn`, `TouchControls.tscn`
- Autoloads: `SaveManager.gd`, `GameData.gd` (run/meta state), `AudioManager.gd`, `ObjectPool.gd`, `InputRouter.gd` (adaptive input)

---

## BUILD ORDER

1. **Project setup:** Godot 4.x project, folders, autoloads, **responsive display settings** (stretch/expand, camera-zoom-from-viewport), **export presets for web/mobile/desktop**, **adaptive input map**, object pool, and a **global UI Theme resource + imported pixel font + base StyleBoxes** (so no screen is ever default-gray).
2. **PixelLab test:** `get_balance`, generate anchor cat + dog + one snack, import & confirm crisp in-engine.
3. **Core loop:** player movement (keyboard + touch joystick), a test enemy that **drops a snack on death**, eat → XP → level-up cards, one working weapon.
4. **Enemies & director:** chase, contact damage, escalating spawner, death poof + snack drop, pooling.
5. **Asset generation (tiered):** generate **Tier 1 (core)** — remaining cats/enemies/tiles/UI, scenery props, title background (style-referenced) — and import. Then work **down the Diversity Expansion tiers** as budget allows (`get_balance` between tiers), atlasing as you go.
6. **Weapons & passives:** full pool with leveling; card wiring.
7. **Boss + wave tuning.**
8. **Meta layer:** Fish Coins, save/load, Cat Café shop, cat unlocks/select.
9. **Responsive UI, touch controls, menus (with the title-screen background), scattered decorative props in the arena, polish/juice, audio (with web unlock).**
10. **Craft pass (anti-slop — do not skip):** play the whole game; review every screen and asset *together* for one cohesive art direction, **regenerating any off-model/generic sprites**; add character (charming names + flavor text everywhere) and small delights; tighten game feel (hit-stop, shake, easing, idle anims); fix every hard cut, empty state, and rough edge. Polish over adding.
11. **Export & test on the Web build (in browser), a mobile/portrait viewport, and desktop.** Verify responsiveness, safe areas, and frame rate under a full horde. Write a README on how to run/export.
12. **Publish (see below):** push the source to `github.com/lelelilo-studios/purrvivors` and deploy the web build to GitHub Pages; report the repo link + live URL.

---

## VERSION CONTROL & PUBLISHING (GitHub)

- **Repo:** push all source to **`github.com/lelelilo-studios/purrvivors`** (create it with the `gh` CLI if it doesn't exist; the environment needs git auth for the `lelelilo-studios` account). Commit `project.godot`, all scenes/scripts, `res://assets/`, the theme + fonts, and `export_presets.cfg`.
- **Source hygiene:** add a Godot **`.gitignore`** (ignore `.godot/`, import caches, local exported binaries), a **README** (what it is, how to open/run in Godot, how to export), a **LICENSE**, and a **`CREDITS.md`** listing every third-party asset (fonts, SFX, music) with its source + license — only license-clean (preferably CC0) assets in this public repo.
- **NEVER commit secrets:** keep the **PixelLab API token** and any keys out of the repo (env vars + `.gitignore`). The repo is public — verify no token is anywhere in history before pushing.
- **Publish the web build to GitHub Pages** so it's playable at **`https://lelelilo-studios.github.io/purrvivors/`**:
  - Export the **Web/HTML5** preset into a **`docs/`** folder and set Pages to serve from `main` → `/docs` (this both "uploads the web version to the repo" and hosts it in one step).
  - **Godot 4 + Pages gotcha:** GitHub Pages can't set the `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy` headers that *threaded* web exports need. Fix it by **(recommended) exporting with threads DISABLED** (Godot 4.3+ non-threaded web export needs no special headers), or by including the **`coi-serviceworker.js`** shim to inject those headers client-side.
  - Make sure asset paths resolve under the `/purrvivors/` subpath, and confirm the live page actually loads and plays.
- **Automate it (preferred over manual re-exports):** add a **GitHub Actions** workflow that installs Godot headless, runs the web export, and deploys to Pages on every push to `main` (setup-godot action → `actions/upload-pages-artifact` → `actions/deploy-pages`). Commit the workflow file.
- Put the **repo link and live Pages URL in the README**, and report both back to me when done.

## ACCEPTANCE CRITERIA

- Runs in Godot 4.x with **no errors**; a full run is playable start→finish.
- **Runs in a browser (web export), plays with touch (verified on a phone browser or emulated mobile viewport, portrait + landscape), and on desktop with keyboard.** UI is responsive across aspect ratios and respects safe areas. Android/iOS export presets configured (native signing/builds left to the user).
- **Snacks drop only from defeated enemies** (no random floor spawns); eating them grants XP.
- **Tiered win goal:** defeating ≥1 boss = a win; the results screen shows the earned tier (1–3 paws) by bosses beaten, and a 0-boss death as Defeat. Best tier saved per cat; Fish Coins always kept.
- Arena feels furnished (scattered props) and menus use the illustrated title background — not a bare floor.
- All visuals are PixelLab pixel art with a consistent style; no placeholder shapes.
- **UI is themed and polished from the first build:** one global Theme (pixel font + 9-slice panels/buttons + hover/press states), animated `Tween` transitions, and **zero default-gray Controls** on any screen.
- **Does NOT feel like AI slop:** one cohesive, curated art direction (off-model assets regenerated, not accepted as-is); strong game feel (hit-stop, shake, easing, idle anims); **personality in all copy/naming + flavor text**; cohesive audio; finished transitions and edge states — and a final craft-review pass was actually done.
- Leveling, ≥5 weapons + ≥5 passives, ~8 enemy archetypes with distinct behaviors, hordes (hundreds on screen late-game), and 3 milestone bosses all functional.
- **Visual diversity scaled to the budget:** multiple biomes, an expanded enemy cast, hurt/death animations, and a full icon set as the pool allowed — sprites **atlased**, web build still fast to load.
- Fish Coins persist; shop upgrades and cat unlocks actually affect runs.
- **Difficulty scales continuously with run time** (spawn rate, count, enemy tiers A→D, elite frequency); a fresh un-upgraded cat cannot full-clear run 1 — the Golden Paw requires meta-progression across multiple runs.
- **Balanced & tunable:** key numbers centralized in data (no scattered magic numbers); weapons sit in a comparable DPS band with distinct roles (no dominant/dead weapon); XP/coin/enemy values are threat-proportional; economy on an escalating curve; a debug/balance mode + balance table are included.
- Smooth performance with a full horde on web/mobile (object pooling + lightweight swarm movement — no per-swarm-enemy physics bodies).
- **Audio is cohesive and license-clean:** one consistent SFX family + fitting music, every third-party asset (audio + fonts) credited in `CREDITS.md` with a compatible license.
- Clean, commented, modular GDScript + a short README.
- **Published:** source pushed to `github.com/lelelilo-studios/purrvivors` (no secrets in history), and the web build is **live on GitHub Pages at `lelelilo-studios.github.io/purrvivors`** and actually loads + plays.

---

## TWEAKABLE DEFAULTS (I chose these — change any before/while building)

- **Run length:** 15 minutes (bosses at 5:00, 10:00, 15:00). Bump this up later for longer runs.
- **Win condition:** defeat ≥1 of the 3 bosses = a win; tier = # bosses beaten (🐾 Bronze / 🐾🐾 Silver / 🐾🐾🐾 Golden = full clear). 0 bosses + death = Defeat. Coins always kept. Optional endless overtime after a full clear.
- **Difficulty ramp:** continuous time-based scalar + enemy-tier unlocks (0–3 / 3–6 / 6–10 / 10–15 min); tune the slope to taste.
- **Progression gate:** fresh cat ≈ boss 1; target ~8–15 runs to the first Golden Paw full clear (tunable).
- **Playable cats:** 3 (tabby / chonk / kitten).
- **Currency / shop:** Fish Coins / Cat Café.
- **Snacks = XP, dropped by enemies** (heal only via rare milk drops / Milk passive).
- **Drop rate:** ≈100% of kills drop an XP snack, size by enemy tier; rare heal/coin/vacuum drops.
- **Orientation:** both portrait & landscape supported (change if you want to lock one).
- **Controls:** keyboard on desktop, virtual joystick on touch; auto-attack everywhere.
- **Weapon evolutions:** OFF (hooks left in).
- **Asset budget:** generate up to ~75% of the PixelLab monthly pool (Tier 1 core first, then Diversity Expansion tiers), keeping ~25% for regenerations. Elites/skins are runtime tints, not generations.
- **Art spec:** cute chibi, top-down 3/4, pastel palette, 48px characters / 16px pickups.

If any of these should change (longer/shorter runs, lock orientation, more cats, evolutions ON, health-snacks instead of XP-snacks), say so and adjust the relevant section.
