# The Last Roads

**Playable build: Roadkeepers (0.17.0).** Three separate rotating autosaves and verified recovery protect progress while preserving the manual save. Discovered side stories can be tracked in the journal, compass and map, including moved return contacts and correct region selection. Level-ups now show a dedicated banner and the gained profession benefit; the HUD shows level and XP remaining. New-character pacing targets level 2 at 10?15 minutes, level 3 around 30 minutes and level 4 around one hour. Existing saves retain earned levels and abilities. Run `launch.cmd` for three connected chapters, or `Test-Chapter-Three.cmd` for an isolated, equipped preview of the new murder investigation. Continue your existing journey normally to reach Alderwake north of Saint Mary's Hospice after freeing its bell. The new chapter adds eight NPCs, eight locations, fourteen evidence discoveries, revisable deductions, negotiation or combat rescue, and nine combinations of justice and woodland outcomes. Nine independent woodland side stories remain available. Full-game pacing targets roughly two hours with exploration; human timing is still needed. Pip (eleven) and Nell (twelve) are excluded from every adult relationship path. The authorized generated Ilya and Adela likeness assets are included; original photos and generation metadata remain excluded. Existing saves, settings and controls are preserved. Production details and checks are in [game_production.md](game_production.md); current test routes are in [PLAYTEST.md](PLAYTEST.md). `README_NEW.md` is the broader historical design baseline.

## Agent-first cooperative RPG — Game Design Document

**Version:** 2.0 — 7 November 2026  
**Status:** Revised design baseline for prototyping  
**Platform:** Windows / Steam first; preserve the option of a later Xbox port  
**Players:** 1–4; social experience designed primarily for 3–4 friends  
**Initial engine:** Godot, with an exact stable version pinned at project creation  
**Initial presentation:** First-person stylised 3D  
**Required alternative:** First-person retro presentation using directional 2D pixel-art sprites inside the same navigable 3D world

This document replaces the scope and production assumptions of version 1. It adopts the revised expedition-based concept and makes migration to a retro sprite presentation an architectural requirement. Numeric budgets are prototype targets, not established balance. Implementation proposals and deferred features are identified explicitly.

## 1. Product vision

The Last Roads is a cooperative fantasy RPG about restoring connections between isolated settlements in a land threatened by supernatural night. Players gather rumours in a roadside inn, prepare an expedition, recover treasure, survive after dark and bring abandoned roads back into use.

The world visibly responds: windows light up, a merchant arrives, a workshop opens and another safe destination appears on the map. Progress is expressed through both character development and a growing network of inhabited places.

**Player promise:** Venture out together. Bring back treasure. Light a fire before darkness falls. Bring life back to the last roads.

The design serves three priorities:

1. Agents can implement, generate and validate a playable game in small increments, including its assets.
2. Classic RPG progression and exploration coexist with readable combat, convenient cooperation and short sessions.
3. Art direction can move from stylised 3D to retro 2D pixel art without rewriting rules, saves, networking or level connectivity.

### 1.1 Design pillars

- **Shared expeditions:** Preparation, travel, danger, discovery and recovery create stories between friends.
- **The warmth of safety:** Inns, shelters and fires contrast with the threatening wilderness.
- **A changing road network:** Restoring a connection produces visible, useful and persistent improvements.
- **Character identity:** Fixed professions, learned abilities and equipment choices support distinct roles.
- **Bounded production:** New content primarily combines proven modules, behaviours and effects.

### 1.2 Non-goals

The initial product does not require a seamless continent, a fully simulated society, freeform terrain editing, a realistic human appearance or a universal custom engine. It is not a roguelite that discards the world after each expedition. Runtime LLM dialogue or live AI-generated gameplay is not required.

## 2. Audience and tone

Classic RPG players receive professions, EXP investment, prepared spells, spatial inventory, dangerous regions and meaningful exploration. Contemporary cooperative players receive clear objectives, responsive action, readable feedback, convenient joining and visible shared progress.

These audience assumptions must be tested with both groups; nostalgia and low production cost alone do not establish appeal.

The tone is approximately 60 percent adventurous and 40 percent frightening, with horror concentrated at night. Northern European woods, marshes and roadside settlements provide the landscape. Late-Renaissance and early gunpowder fantasy informs clothing and equipment: broad hats, long coats, breastplates, rapiers, pistols and muskets. A light Slavic influence appears in folklore and local stories.

Mature themes include politics, violence and moral uncertainty. The prototype uses dialogue and consequences rather than elaborate cinematic scenes. Explicit intimate scenes and a nudity system are outside the production baseline. Sexual violence must not be depicted or available as a player action.

## 3. Core loop and session structure

1. Meet at an inn or another secure stop.
2. Hear rumours and choose an objective.
3. Select supplies, equipment and prepared abilities.
4. Explore a persistent local area, including optional branches and shortcuts.
5. Fight, negotiate or recover an objective.
6. Choose whether to return, camp or continue after dark.
7. Convert rewards into character improvements, services and restored connections.

A satisfying expedition should normally fit approximately 20–25 minutes. This is a pacing target, not a countdown or forced extraction. Saves allow longer expeditions to span sessions.

### 3.1 Example expedition

An innkeeper reports lights in an abandoned roadside chapel. The party crosses a forest, fights bandits and finds stolen supplies. A prisoner claims the bandits were feeding a nearby settlement. Players choose what to return. On the way home dusk arrives; they use wood to establish a fire and shelter, then survive the night. Returned materials allow a damaged watchtower to be repaired. After defending it, the party opens a road to another inn.

This example describes the desired experience, not a requirement to implement every branch in the first build.

## 4. World structure

### 4.1 Persistent areas connected by roads

The world is a graph of substantial explorable areas connected by roads, gates, passes and dungeon entrances. Each area has stable identity and persistent changes. Crossing an area boundary may load a new area; uninterrupted continent-scale traversal is not required.

The world map communicates the larger island and the state of its connections. Areas contain loops, optional destinations, secrets and return shortcuts. They must not feel like a sequence of mandatory combat corridors.

Initially, the party shares one active expedition area. Area transitions require everyone to gather and confirm. Independent parties exploring different areas simultaneously are deferred. Players can spread out within the current area.

### 4.2 Generation rules

The first playable area is fixed. Once it is enjoyable, a constrained generator may assemble variants from validated terrain patches, road sections, encounter spaces and landmarks.

Generate an area once on first creation and preserve its identity. Store the generated layout or sufficient versioned data to reconstruct it exactly; a seed without a generator version is not a persistence contract. Updates must not silently rearrange an existing world.

Generation validates:

- Required destinations are connected by traversable routes.
- Doorways and passages have sufficient clearance.
- Encounter and interaction points are reachable.
- At least one useful camping site exists on the intended expedition route.
- Spawns do not overlap walls or essential interaction points.
- Shortcuts cannot bypass a deliberately locked progression requirement.

### 4.3 Content and renewal

Initial environments are forest, roadside ruins and a small crypt or cave. Later areas may add marshes, farms, rocky uplands and small settlements. Underwater exploration and continuous sea travel are deferred.

Wilderness encounters and ordinary treasure may renew under explicit rules. Restored sites and secured road interiors do not receive ordinary hostile repopulation. Special authored events may threaten them. Closing a local Abyssal rift suppresses night incursions within its defined protected area.

## 5. Roads, inns and long-term progression

Restoring a connection requires delivering resources and completing a defence encounter. A successful defence changes the connection state and unlocks its services. A failed defence leaves the objective available for another attempt; prototype losses must not permanently block the campaign.

Benefits may include a new merchant, travel destination, workshop or expedition rumour. Visible improvements are authored state variants, not a fully simulated settlement economy.

Fast travel costs a carriage fare and follows restored road connections. The entire active party must gather. Prototype travel is a transition with a clear confirmation screen; carriage simulation and ambushes are deferred. Travel time advancement must be explicit and consistent with the day/night clock.

The full vision retains eight sequential major bosses. Each opens access to further regions or opportunities. Boss victory does not automatically secure every surrounding location. Closing rifts remains a separate activity using a magical resource, with its final acquisition and cost deferred.

Exact campaign length is uncommitted. Validate the first progression stage before extrapolating to eight bosses.

## 6. Characters and advancement

### 6.1 Professions

Begin with one playable warrior in the technical slice. The expedition prototype adds mage and cleric. Ranger, rogue, bard and druid remain expansion options after the core roles work.

Professions are fixed development paths. A warrior does not become a mage. Characters begin as novices with a small equipment and ability set. Incompatible equipment may impose clearly displayed penalties; the prototype only exposes combinations with defined behaviour.

Use one humanoid body family initially. Additional races, extreme body proportions and their equipment compatibility are deferred. Cosmetic variation comes from head, colour, clothing and accessories.

### 6.2 Progression

Earn EXP and spend it on profession abilities, attributes and upgrades. Level depends on lifetime EXP earned; spending EXP cannot reduce level. Rare masters may award an improvement through a quest.

Crafting investment competes with combat investment. Begin with a small set of meaningful upgrades rather than large trees of percentage bonuses. Equal participating party members receive equal EXP rewards; exact distance and participation boundaries must be specified before implementation.

Character data and world progression remain separate. However, unrestricted character transfer between worlds is deferred until save reconciliation is implemented and tested. Separation of data must not be mistaken for a completed transfer feature.

## 7. Combat and magic

Combat is real-time, first-person and direct. The initial weapon supports an attack and a block. Enemies visibly telegraph attacks and react to damage. Hit sound, impact reaction and timing are acceptance criteria, not late polish.

Stamina supports sprinting and jumping. Ordinary attacks and blocks do not initially consume stamina. Mana regenerates more slowly and pays for spells. Friendly fire is disabled.

Later equipment may include shields, two-handed weapons, bows, crossbows, pistols and muskets. Firearms are slow and powerful, with carried ammunition. Each new family requires a distinct gameplay purpose and presentation validation in both visual profiles.

### 7.1 Common effect vocabulary

Build abilities from a bounded set of effects: damage, heal, protect, illuminate, apply status and knock back. Effects have explicit ranges, durations, target rules and stacking policies. A content definition may combine supported effects; it must not inject arbitrary executable behaviour.

Spells are learned from books or scrolls subject to level requirements. Prepared slots change during valid rest. Magical professions share mana and preparation rules but have different spell lists. The prototype needs only a small offensive and healing set.

Food and potions take effect immediately. Repeated potion consumption remains allowed; balance through supply and inventory constraints rather than adding an undocumented cooldown.

### 7.2 Difficulty

Each area has a baseline danger. Party-size scaling must preserve that identity. Power-based adjustments are bounded so advancement still makes earlier threats easier. Solo is playable but deliberately less forgiving than a coordinated group.

Avoid balancing only through inflated enemy health. Test enemy count, attack pressure and recovery opportunities while retaining readable encounters.

## 8. Night, fire and lightweight survival

A full day lasts approximately 20–24 minutes, with a 3:1 daylight-to-night ratio. The prototype may use controlled starting times to exercise dusk reliably, but the public rules must be consistent.

Night brings Abyssal creatures: spirits, demons and undead. Most normal inhabitants shelter. At dawn the affected creatures disappear or become inert according to their defined family behaviour.

### 8.1 Two primary survival concerns

- **Provisions:** Food supports expedition preparation and immediate recovery. Running out weakens preparedness rather than causing a separate starvation death timer.
- **Exposure:** Cold and wet conditions increase a readable exposure state. Clothing reduces buildup; fire and shelter allow recovery. Severe exposure weakens the character. Lethal extremes are deferred until the basic loop is validated.

Separate thirst, disease simulation, drunkenness and complex wound treatment are deferred. This explicitly replaces the larger survival model of version 1.

### 8.2 Fire and rest

Campfires consume wood, provide warmth and deter weaker night creatures. Stronger enemies may cross their protection, with a readable warning. A torch provides partial personal protection. Shelter protects against rain and improves rest.

Use an explicit safe-rest check rather than relying on how bright a rendered fire appears. All players must agree to skip to morning, and rest is blocked by nearby active threats. Exact safe radius and interrupt rules are tunable data.

Waiting around a fire must include useful activities: equipment preparation, crafting and discussion. Test whether a full night is engaging; do not assume passive waiting is inherently atmospheric.

## 9. Inventory, death and crafting

### 9.1 Inventory and rewards

Use a spatial inventory with items occupying rectangular cells. Support quick transfer, clear comparisons and optional auto-arrangement. Item footprints are gameplay data independent of icon resolution or mesh dimensions.

Loot is shared physical content. Cooperative play increases available rewards through defined tables. The host resolves pickup ownership to prevent duplicate acquisition.

### 9.2 Dying and respawn

Before death, a character enters a rescuable state. Another player can revive them using a defined consumable or ability. Solo provides an equivalent self-rescue opportunity if an eligible resource remains.

On death, retain the equipped basic loadout and drop backpack contents at the death position. Preserve EXP and skills. Respawn with full health at the area's activated universal shrine; if none exists, use its designated safe entry shrine. This replaces version 1's full equipment loss.

Dropped backpacks have persistent IDs and remain recoverable after saving and loading. Expiry and multiple-death handling must be visible rules, not incidental cleanup behaviour.

### 9.3 Crafting and construction

Gather a small set of resources using simple tool interactions. Materials and crafting skill determine available products and quality. Start with repairs, supplies and a few upgrades.

Place complete objects such as a fire, lean-to, barricade or workbench. Use valid placement zones or constrained placement checks. Inn improvements occupy designated locations. Freeform wall-by-wall construction, structural collapse and terrain modification are deferred.

Full durability simulation is not required for the first slice. If introduced later, zero condition means repairable, not destroyed.

## 10. Quests, dialogue and social systems

Use short authored rumours and local stories supported by reusable objective types: defeat, retrieve, investigate, deliver, defend and restore. Generated tasks combine valid locations, objectives and rewards; they do not generate unconstrained plots at runtime.

Dialogue offers a few meaningful choices, including persuasion, intimidation and neutral responses where appropriate. The speaking player chooses. Consequences are represented by explicit quest and world-state changes.

The baseline does not include unrestricted town murder or a general witness-and-prison simulation. Conflict with residents is handled through authored situations. This is an intentional reduction from version 1.

Text chat, pings and party-wide voice are intended features. Voice is equally audible regardless of distance. External voice is acceptable for early technical testing; in-game voice integration is not a prerequisite for proving the expedition loop.

## 11. Visual direction and asset production

### 11.1 Initial 3D identity

Use bold, carved silhouettes, restrained surface detail and coherent colour groups. Figures resemble painted wooden or sculpted miniatures rather than realistic people. Warm amber inns contrast with blue-green forests and dark night silhouettes.

Trees, rocks, buildings and equipment must remain readable without detailed textures. Lighting, composition, sound and animation provide atmosphere. Avoid visually generic collections of unrelated procedural shapes.

### 11.2 Asset families

| Family | Production method | Shared constraints |
|---|---|---|
| Vegetation and rocks | Parameterised geometry generators | Palette, silhouette, collision envelope and size ranges |
| Buildings | Modular walls, roofs, windows and beams | Common grid, doorway dimensions and connection points |
| Dungeons | Validated rooms and connectors | Passage clearance, navigation and encounter markers |
| Characters | One modular humanoid family initially | Common animation names, attachment points and proportions |
| Weapons and props | Small component families | Standard grip, origin, dimensions and interaction proxy |
| Inventory icons | Automated renders of source assets | Fixed camera, lighting, framing and transparent background |
| Magic | Reusable particles and material effects | Explicit gameplay radius independent of visible extent |
| Audio | Synthesised simple effects plus a curated recorded set where necessary | Event names, loudness consistency and provenance |

Generators produce inspectable outputs during development or build. Do not regenerate expensive geometry every frame. Limit variation to parameters that have been visually and mechanically validated.

All included assets require a recorded source and usage basis. The project can use code-generated assets without generative image inference. Generative reference images, if used, are not automatically production-ready meshes, sprites or animations. Audio quality and coherent character motion remain explicit production risks.

## 12. Required migration path to retro 2D pixel art

### 12.1 Definition and limits

The required retro mode retains first-person navigation in the same 3D areas. Characters and suitable props become directional pixel-art billboards; architecture and terrain retain simple 3D geometry with pixel textures. First-person equipment may use sprite overlays. Effects and interface receive a matching pixel treatment.

This is a 2.5D presentation of the existing game. It does **not** mean a later conversion into a top-down 2D game, nor replacing every building with a flat image. Those changes would alter navigation, visibility and level design and are outside this migration promise.

The architecture supports a later visual change or optional profile; it does not commit the product to shipping two fully polished art packs. Only a small parity fixture is maintained in both profiles throughout development.

### 12.2 Presentation-independent entity contract

Each gameplay entity owns stable data and a logical spatial representation. A replaceable visual adapter consumes that state.

| Gameplay owns | Presentation owns |
|---|---|
| Entity ID, transform, facing and velocity | Mesh or sprite selection |
| Health, status and progression | Materials, palettes and lighting response |
| Collision, hit volumes and interaction range | Animation frames, interpolation and cosmetic motion |
| Attack state, timing and damage events | Swing appearance, particles, sound triggers and hit flashes |
| Navigation and visibility queries | Billboard orientation and visual shadows |
| Item ownership and persistence | Inventory icon and equipment depiction |

**Mandatory rules:**

1. Damage and attack completion never depend on a rendered animation callback.
2. Collision uses authored logical proxies, not the current mesh or sprite rectangle.
3. Gameplay interaction targets use those proxies; transparent sprite pixels do not define reachability.
4. Network replication sends logical state and events, not sprite frame indices or mesh bone transforms.
5. Saves reference stable content IDs, never renderer-specific resource paths.
6. Visibility, stealth, warmth and fire protection use logical queries, not rendered brightness or shadows.
7. Local cameras choose sprite directions independently; two clients may see different views of the same enemy at the same moment.

### 12.3 Asset manifest

Every renderable content ID resolves through an asset manifest. A character entry supplies a 3D visual resource and, when available, a retro sprite resource. Shared metadata defines world height, footprint, facing convention, origin, animation vocabulary and required sockets.

An example content ID is `enemy.road_bandit`. It must remain unchanged when its presentation switches. Missing retro assets fail validation for a retro-target build; a mixed-style fallback is allowed only in explicit development mode.

Keep animation names stable: `idle`, `move`, `attack`, `hurt`, `downed` and `death`. Add `cast` only for actors that require it. Timing is defined by gameplay state, with visual samples mapped to normalised progress. An animation with fewer frames must still display the same windup and impact moment.

### 12.4 Sprite production pipeline

Use the stylised 3D source models as an optional intermediate for sprite production:

1. Load a validated source model and a known animation.
2. Render it from a fixed set of azimuth directions using a repeatable capture scene.
3. Sample animation phases using the gameplay timing contract.
4. Render to a fixed low-resolution canvas with consistent framing and transparency.
5. Quantise to an approved palette if required; use nearest-neighbour sampling.
6. Pack frames and export direction, phase, pivot and socket metadata.
7. Inspect the result in motion at its intended screen size and revise silhouettes or frames.

Recommended first target: eight horizontal directions and a 96–128 pixel character height in source frames. These are test budgets, not universal requirements. Store them in manifests rather than hard-coding them into gameplay. Four-direction assets may be used for an early visual check.

An automated low-resolution render is a starting point, not a guarantee of convincing pixel art. Important enemies, weapons and faces may require frame cleanup and palette adjustment. Pixelated 3D is not a substitute for implementing actual sprite entities in the parity fixture.

### 12.5 Perspective, elevation and occlusion

Use upright billboards with a fixed ground pivot. Select the directional frame from the angle between entity facing and the viewer's horizontal position. Add direction-change hysteresis if boundary flicker is visible.

Prefer modest elevation differences in initial encounters. Looking directly down onto a flat actor exposes the technique; extreme overhead views and towering climbable enemies are outside the initial style envelope. Free look remains available, so elevated viewpoints must be tested rather than hidden by an assumed camera restriction.

Sprite entities depth-test against world geometry. Validate doors, corners, stairs and partial cover. Billboard width must not cause severe visible wall penetration. Use consistent logical hit volumes and readable target silhouettes; invisible generous hitboxes must not become a substitute for visual alignment.

Initially, retro enemies use simple blob shadows or a consistent inexpensive alternative. Avoid systems whose readability relies on accurate animated humanoid shadows.

### 12.6 Equipment and first-person weapons

For third-person views of other players, begin with a limited set of equipment silhouettes. Prefer layered sprite attachments with per-frame sockets where practical. Bake selected combinations when layering fails. Do not assume every possible weapon, armour and body combination can be generated cheaply.

First-person weapon visuals are separate from the gameplay attack and camera controller. Provide a 3D viewmodel adapter initially and a sprite-overlay adapter for the retro fixture. Both follow the same windup, strike, recovery and block states. Hits use the same logical targeting rules.

### 12.7 World materials and UI

Use common world dimensions and collision geometry in both profiles. Retro world materials use small tileable textures and consistent texel density. Fullscreen pixelation is optional; it must not be the only retro treatment.

UI layout, input and text content remain shared. A theme switches fonts, borders, icons and spacing as necessary. Text must stay readable at the intended resolution. Inventory occupancy does not change when icon art changes.

### 12.8 Early migration proof

Before expanding the content library, demonstrate the same saved test scene in both visual profiles with:

- One moving and attacking enemy.
- One remote player with visible equipment.
- One first-person weapon and block state.
- One item, one fire and one spell effect.
- A doorway, partial cover and a modest elevation change.
- Inventory, damage, death and save/load behaviour.

Switching profiles may require reloading visuals or restarting the scene; an instant live toggle is not required. No gameplay code or saved state should need modification. Verify logical event outcomes using the same controlled inputs; screenshots are expected to differ.

## 13. Software architecture and cooperation

Use Godot for the first implementation and pin the engine and dependency versions. Do not build a custom renderer or an engine-independent framework before proving the game.

Separate modules for gameplay rules, content definitions, world state, persistence, networking and presentation. Separation means clear ownership and interfaces; it does not require reimplementing the engine's physics or UI.

Use a host-authoritative world. The host resolves combat, pickups, quest transitions and persistent construction. Clients request actions and display replicated results. Simulation runs independently of whether the hosting player's character is present.

Stopping the hosting process stops world time. Leaving as a character while continuing hosting leaves the world running for friends. A departing character disappears with their inventory. Rejoining restores a valid recorded position or a defined safe fallback.

Support manual saves. Save character and world state as a coordinated snapshot for the prototype. Recovery must not duplicate backpack contents, world drops or quest rewards. Schema versions and explicit migrations are required before changing persistent data structures.

Initial controls use mouse and keyboard. Keep actions abstracted for later controller support. Xbox remains a future port, not an assumed consequence of renderer separation.

## 14. Agent-oriented production workflow

### 14.1 Unit of work

An agent task produces a small playable and reviewable result with a defined test. Examples include adding a chapel using the existing building kit, introducing an enemy using supported attacks, or implementing one road restoration state transition.

Avoid tasks such as “generate a complete fantasy region” before the allowed modules and validation rules exist.

### 14.2 Definition of done

Each integrated change must:

- Build and launch from a documented command.
- Use valid content IDs and supported schema fields.
- Pass checks relevant to the changed system.
- Preserve save and network behaviour where affected.
- Produce a screenshot or short recording when appearance or movement changes.
- Record known limitations and a short human playtest objective.

Headless tests verify rules and state transitions. Rendered checks verify visual output. Human playtests evaluate feel, atmosphere and comprehension. A successful launch alone proves none of the latter.

### 14.3 Development diary

Provide a notebook for observations, bugs and suggestions. Capture note text, screenshot, position, world and area IDs, seed, generator version, build version and relevant recent events. Add a diagnostic state snapshot where practical.

Export a package manually after playing. Development occurs in a separate phase. The package must not overwrite the player's ordinary save. Do not capture voice conversations by default.

Review duplicates, distinguish defects from design changes, implement selected work and retain a retest list. Preserve positive observations as well as complaints.

## 15. Staged playable scope

### Stage A — Technical and visual proof

Two players in one small fixed area. One humanoid enemy, movement, attack, block, health and a basic pickup. Demonstrate host authority and the two presentation adapters using the parity fixture.

**Exit condition:** Two clients observe consistent combat and pickup ownership; the visual switch does not change logical outcomes.

### Stage B — First shared expedition

One inn, one forest area, one ruin, one warrior, two ordinary enemy types and one night creature. Add a treasure chest, simple spatial backpack, one upgrade choice, fire, day/night cycle, rescue, respawn, save/load and diary export. Restore one road connection through a small objective.

**Exit condition:** Two people complete a coherent departure, discovery, danger and return loop, and can stop and resume without losing or duplicating progression.

### Stage C — Four-player prototype

Support four players, warrior/mage/cleric, a small dungeon, one boss, exposure, shelter, a limited crafting set and a complete watchtower defence. Target a satisfying approximately 25-minute expedition. Add party communication features as needed for independent testing.

**Exit condition:** Groups understand their roles, feel a meaningful difference between day and night, and see a useful persistent result from restoring the road. Solo remains viable.

### Stage D — Controlled content expansion

Introduce constrained area generation, more expeditions and additional progression. Expand only after the fixed area is enjoyable and save/network behaviour is reliable. Validate each generated layout before accepting it into a playable world.

No calendar estimate or staffing assumption is attached to these stages. Measure actual iteration speed and rework before promising a release schedule.

## 16. Acceptance criteria and remaining decisions

### 16.1 Core acceptance criteria

- A new group can identify an objective, prepare and start without external explanation.
- Combat reads clearly at the intended viewing distance in both visual fixtures.
- A fire changes survival options and player behaviour rather than being only decoration.
- Road restoration produces a visible and useful world change.
- Four-player combat, drops and quest rewards remain consistent.
- The host can leave their character while others continue.
- Saves preserve collected loot, dropped backpacks and restored sites.
- The same content identity, hit volumes and rules work with mesh and sprite adapters.
- Procedural assets look like one art direction when assembled into an actual scene.

### 16.2 Decisions to resolve through prototyping

Exact combat timing; enemy scaling bounds; safe-rest rules; exposure rates; backpack capacity; resource costs; carriage time advancement; shrine placement; sprite size and direction count; equipment layering; audio sourcing; and minimum hardware targets.

The most important early risk is that cheaply generated content looks and feels interchangeable. Address it through strong silhouettes, authored landmarks, distinct enemy behaviours and a small number of memorable choices before increasing world size.

### 16.3 Explicit changes from version 1

| Version 1 | Version 2 baseline |
|---|---|
| Seamless Daggerfall-scale island ambition | Persistent connected explorable areas |
| Retro sprites as initial presentation | Stylised 3D first, with an early tested sprite migration path |
| Broad survival simulation | Provisions and exposure initially |
| Valheim-like freeform building | Complete placeable objects and designated upgrades |
| Full town crime and murder simulation | Authored social conflicts |
| All equipment dropped on death | Equipped basic loadout retained; backpack dropped |
| Broad race and profession scope | One body family; one then three professions |
| Character transfer assumed available | Separate data retained; transfer implementation deferred |
| Large prototype feature bundle | Technical proof, small expedition, then four-player prototype |

The final quality bar is a short shared adventure that players want to repeat. Asset count, generated land area and number of implemented systems are supporting measures, not substitutes for that result.
