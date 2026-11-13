# The Last Roads — production record

**Build:** `0.17.0-roadkeepers` · **Updated:** 12 November 2026 · **Engine:** Godot 4.5.1, GL Compatibility · **Playable:** Windows, single player.

## 12 November / Roadkeeper reliability and guidance

The priority for the next human session is retaining progress and making the nine smaller stories navigable. `save_slots.gd` now owns validated JSON writes, verified previous copies, three separate rotating automatic slots and selection/recovery. New progress and two-minute intervals request automatic saves; combat, airborne movement, attacks, reloads, conversations and reporting defer them. The manual slot is not an autosave target. Continue and the pause checkpoint button resume the newest valid slot; F9 preserves explicit manual-save behavior. Healthy backups survive corrupt primaries, and loading a recovery copy does not rewrite the original. Solo/co-op and preview/test save namespaces remain separate.

Discovered unfinished side stories now participate in journal selection, map markers, compass/HUD objectives and persisted tracking. Both clue orders are retained, the next missing trace is chosen by distance, and return objectives use current NPC positions. Adela's pre-beacon availability and the underchapel exit are handled explicitly. Unknown stories do not appear in the active list, completion clears the active side track, and earlier chapter tracks remain selectable. The map has a Show objective button and a shorter legend. The level banner is moved below the reticle, and automatic-save status stays clear of the interaction prompt.

The focused checks exercise actual disk replacement/backup recovery and resume semantics, safe-save deferral, independent co-op paths, normal journal choices, map/compass progress, moving NPCs, both clue orders, completion and migration. Standalone controls, level progression, cooperative protocol, chapter III, side-story, journey and smoke regressions complement the new tests. No new plot content, private scenes or upgrade-selection UI is introduced in this pass.


## 12 November / Visible character levels

The hidden, fast 60/160/320/550 XP rank curve is replaced for new travellers with 250/1,000/2,400/4,000 XP level milestones, targeting 10?15 minutes to level 2, about 30 minutes to level 3 and about one hour to level 4 on an exploratory route. Timing is a reward-budget estimate and needs playtest calibration. All existing quest, exploration, evidence and combat XP continues to count; no idle-time rewards or time gates are introduced.

A separate, non-modal eight-second banner shows the new level and its existing automatic profession benefit. Quest toasts cannot replace it. Multiple levels queue independently, and dialogue/pause/reporting defer rather than consume the announcement. The status HUD uses the term Level and shows XP remaining. Level-up events are recorded with gameplay timestamps. Upgrade selection and a detailed progression dialog remain deferred.

Save migration preserves old earned levels and spells using a validated, versioned level floor, while leaving XP and other progress intact. Fresh saves use the new curve. Notification baselines reset on new journeys and load so old rewards are not replayed. Coverage includes JSON roundtrips, every old level in all professions, equipped advanced spells, multiple gains and menu deferral; ranger, profession and smoke regressions accompany standalone packaging.


## 12 November / The Shape of a Murder

A third connected major chapter extends the road beyond the hospice to Alderwake, Blackwater Sluice, Rowan Sanctuary, the White Kiln, the Burned Assize, the Root Cellars, the Root Court and the Listening Oak. The physical terrain now reaches north to -1845; ten new authored road paths total approximately 2,074 metres. Existing world/layout identifiers and save destinations are retained. The original terrain grid aligns with its previous samples, inhabited pads remain level, and old saves receive a fresh chapter dictionary without altering previous flags, inventory, relationships or preferences.

Seven new adults and one child form the northern cast. Oren's staged ritual murder is investigated through physical evidence, an accurate adult timeline, missing prisoners and the watch's protection contracts. Three corroborated deduction links are required before Bran can be confronted. Religious affiliation and Nell's optional recollection cannot establish guilt. The Old Faith's genuine shelter and costly willing offerings are distinguished from Vey's coerced pledges. The player independently chooses public hearing, exile/restitution or concealment, and a voluntary accord, severance or inheritance of the coercive debt: nine narrative outcome combinations, with separate confirmations and persistent aftermath. Rescue permits negotiation or force and requires a pressure vent before the release. Severance has a real three-knot shield mechanic and a new collector boss.

The full-game target is roughly two hours including exploration; the third chapter is designed around 35?50 minutes. Automated traversal verifies movement, not human reading, investigation or combat pacing. Three northern travel stops, safe recovery, supply/ammunition chests, a third map sheet and six case tracks reduce repetitive backtracking. Cartridge loot is capped at the valid pouch capacity. Two optional kindnesses and a winter-store discovery add quieter consequences.

Children Pip (eleven) and Nell (twelve) are excluded by the adult relationship allowlist and explicit minor checks. Direct private-entry/actions, portraits and active-partner appearance are regression-tested. Nell remains safe at Alderwake; her toy errand is optional, and every major ending works without meeting her. New NPC atlas artwork is original built-in generation with no real-person reference; the prompt specification is recorded in PLAYTEST.md. Authorized existing Ilya/Adela generated artwork remains included, with originals and generation metadata excluded from distributions.

Validation includes all nine endings and intermediate save states; old-save migration; all new normal focus/E interactions; both rescues; physical walking of ten new roads; rendered landmarks and NPCs; boss shielding; shared-world progress with local tracking; earlier side stories and adult relationship routes; terrain, grass, inventory, professions, original quest access and standalone export checks. `Test-Chapter-Three.cmd` offers an isolated equipped preview. The normal launcher continues the player's existing journey.



This is the current production document. `README_NEW.md` remains the broader design baseline; the earlier playtest notes and report write-ups are historical. The prototype now contains **two connected chapters, fourteen illustrated NPCs, fifteen named places, an adult character creator, consequential personal quests and two optional fade-to-black encounters**. The intended complete playthrough is approximately an hour. Reading speed, combat, exploration and optional stories affect that estimate; a timed human playthrough is still needed to establish a median.

## Ranger and held-light field reports (source update, 9 November)

The 18:54–18:57 UTC reports are addressed. The lantern now has an original painted left-hand view. Lantern and torch are mutually exclusive, occupy the left hand and block shield defence and caster offhand spells/rites until stowed. New journeys start with lights stowed; existing saves retain their selected light, with torch taking precedence if an older record had both active. RMB strikes with a held torch, dealing weaker physical damage to living enemies and stronger damage to spirits. The smooth warning columns were placeholder wilderness clues; they are now narrow, bark-textured broken timbers with passive look-at explanations. Their purpose is documented in `README_NEW.md`.

Ranger is available in the existing creator to every origin and gender. C selects pistol (80 damage), V musket (130), Q weak dagger (16); LMB attacks. Firearms use actual physics ray hits, including walls, and cannot fire again while empty. R starts a manual two-handed 4s pistol / 6s musket reload, with separate hand movement, ramrod motion, stages and progress feedback. Reloading slows movement and stows lights; changing weapon cancels and leaves the gun empty. G safely rests; older non-Ranger R-rest controls remain valid. RMB with free hands steadies aim. Ranks improve damage, reload speed, dagger and patient-shot damage. Loaded barrels, spare charges and partial reload progress persist in saves; older saves gain defaults.

Both guns start loaded, with 30 spare charges. Reload reserves one; cancellation returns it. Mara, Osric and Adela sell twelve charges for six coins through the Powder & shot conversation button. The equipped pouch holds at most 120, including a reserved charge. Empty ammunition never removes the dagger fallback. Ammunition lives in the equipped pouch rather than spatial bag cells; rest does not create it.

Built-in image_gen produced pistol, musket, dagger, lantern and a separate reload-hand cutout. Source pixels and alpha are unchanged; exact prompts, hashes and provenance are recorded in `assets/ranger/generation.json`. The image service rejected multi-pose equipment sheets, so reloads use code animation of the accepted paintings and the independent hand layer. Side-pan fire, muzzle flash, smoke, recoil, progress and sound cues are code-generated. This is a staged first-person animation, not a fully articulated weapon simulation; human reload-feel and solo-balance testing remain needed.

The requested select-inventory-item then 1–8 flow is tested through real UI selection and input, alongside the existing mouse assignment controls. `--ranger-check` covers creator combinations, hit/miss/wall collision, weapon damage, empty barrels, timed reload/cancel/pause/save, finite ammunition/resupply, progression, held-light restrictions, torch living/spirit damage and warning clues. `reports/26-*.png` contains creator, Original/Copper equipment, firing, reload stages, lights, supplies and warning captures. Existing profession, inventory, survival and sound suites cover integration. Source play remains `launch.cmd`; the 0.13.0 distribution ZIP predates these changes.

## Inventory field reports (source update, 9 November)

Reviewed the 17:36, 17:37 and 17:42 UTC player reports. Inventory Auto-arrange and Close move 33 logical pixels upward. Every supply, including crafting materials, quest herbs and trade curios, can replace any quick slot. Dragging a supply onto a slot creates a reference without moving its stack or changing the bag layout. Click or 1–8 also assigns; right-click clears a slot and Shift-drag swaps shortcuts. Depleted stacks retain their binding for replenishment. Material shortcuts open the selected supply in the inventory; they do not consume it or invent a crafting action. Poisonous bonnets remain inedible. Existing saved shortcuts remain compatible.

The reported lantern was already on. Lantern and torch are reusable starting equipment, rather than shop stock. The inventory now exposes both as carried gear with selection, assignment and activation controls; no purchase is necessary. L and T still work during play, independent of slot assignments. Equipment text also follows the selected profession. No inventory counts or save schema fields were added.

Also addressed the older 15:47 UTC bush report: the inn's roofed porch extended beyond the cottage wall footprint used for vegetation rejection. Its full floor now participates in building exclusions, keeping decorative bushes and grass outside it. The same exclusion is shared by ambient placement. The broader survival check's render assertion now samples a viewport-relative region rather than one potentially dark dither pixel at fixed desktop coordinates.

`--inventory-check` covers all supplies in all eight slots, actual UI drag/replacement/clear/swap, unchanged stacks and positions, material inspection, carried-gear buttons and activation, depleted/replenished bindings, current save/load and the recorded player saves. It reproduces the reported porch camera and checks all visible bush anchors against floor exclusions. Captures are `reports/25-*.png`; review details are in `reports/latest-debug-review.json`. Survival and field suites cover the existing drag/rotate/use, torch, weather, foraging, NPC grounding and forest behavior. Human retest: drag scrap to slot 8, rearrange the bag, save/reload, press 8 to inspect it, then select the carried torch and activate it. Existing saves need no reset. The distributed 0.13.0 ZIP predates this source update.

## Forest wildlife and seated patients (source update, 9 November)

An occasional roe doe now makes distant, noninteractive forest runs. Four painted gallop poses animate over a checked, terrain-following path of 60–75 metres. Sightings begin 35–62 metres from the player, with the opening run inside the camera view and clear of solid obstructions. Paths avoid water, buildings and the road surface; the deer fades in and out and stays outside combat, interaction, loot and save progression. One deer is pooled, with a separate cosmetic RNG and a 28–55 second interval after sightings. Failed placement retries after five seconds. Indoors, crypts, menus and field reports pause ambient activity.

Raisa and Pavel at Saint Mere now appear propped upright against pillows, with painted linen clothing and lap blankets. These cards remain upright rather than being rotated flat onto beds. Curved cloth geometry covers the lower body. Treatment preserves the selected survivor and leaves the other bed empty with a pillow and folded linen, matching Nera's existing dialogue and save state. Sickbed interactions retain their original targets and collision.

Built-in image_gen created both sheets, following the existing Old Masters palette and cloth treatment. Full prompts, sources, hashes and alpha audits are in `assets/ambient/field-generation.json`; source PNG pixels are unchanged. `--living-check` verifies visible deer placement, moving gallop poses, a full run over 50 metres, no hunting rewards and pause behavior. `--march-field-check` verifies upright patients and both empty-bed outcomes. Captures are `reports/23-deer-*.png` and `reports/24-*.png`. Human retest: watch a forest clearing while moving along a road, then visit both patients before treatment and return after choosing either survivor. Existing saves need no reset. The distributed 0.13.0 ZIP predates this source update.

## Wilderness danger (source update, 9 November)

Added distance-based wilderness danger across the Hollow and March. Roads and inhabited/quest sites keep their existing authored encounters. Away from them, woodland holds hounds, deep woods hold stronger Pitchbound or Boughstalkers, and the remotest wilds hold mixed pairs. The location HUD names the current danger tier; the journal explains warning signs and counters. Placement is deterministic with stable IDs, protects buildings, quest objects and water, and preserves defeated enemies and searched bodies across saves. Old saves gain the added wilderness encounters without losing quest progress.

Pitchbound are slow, tar-dark polearm fighters: long reach, a 1.45-second warning and a 2.2-second recovery. Their poker deals extra damage through a held guard; a timed parry stops it. Boughstalkers are pale, long-limbed hunters with broken branch crowns: fast approach and a rush inside nine metres, but an early attack warning that ordinary hits can interrupt. They award 30 XP each; Pitchbound yield coins/scrap and Boughstalkers yield essence. Original fictional enemy artwork, tarred warning posts and high claw marks use no likeness assets. Audio currently reuses the deserter and wraith families. Human combat/balance review remains necessary.

The temporary geometric enemies have been replaced by original painted sprite sheets generated with built-in image_gen. Both enemies have idle, windup, strike, stagger, corpse and recovery poses. The lookbook and NPC regeneration guide inform the cloth, anatomy and restrained Old Masters treatment. PNGs in `assets/wilderness/` retain their original generated alpha and pixels; `generation.json` records full prompts, provenance, hashes and alpha audits. Runtime pose extraction handles the wide corpse regions, maintains one pixel scale per enemy and grounds every frame. Tarred warning posts and claw marks remain code-authored. Painted animation timing and combat balance still need human playtesting.

`--wilderness-check` verifies deterministic placement, road/site protection, dry land, both enemy types, paired remote encounters, poker warning/block/parry, hunter interruption, one-time loot and save validation. It also checks all six painted poses in Original and Copper for alpha, stable scale and grounding. Captures: `reports/21-pitchbound.png`, `reports/21-boughstalker.png`, `reports/22-*.png`; encounter coordinates: `reports/wilderness-validation.json`. Human retest: leave a road until the HUD names Deep woods, identify the warning post, fight each type, retreat to shelter and save/reload after looting. The distributed 0.13.0 ZIP predates this source update.

## Profession progression (source update, 9 November)

The current source adds five profession ranks at 0, 60, 160, 320 and 550 XP. The HUD shows rank and XP; the journal lists learned and upcoming benefits. Warriors gain stronger strikes, healing with Second Wind, a Driving Strike cleave and improved blocking. Mages gain longer fire and frost effects and stronger Brittle shatters; clerics gain stronger staff attacks, faster Sanctuary healing and cheaper, faster Rebuke.

At rank 3, mages learn Cinder Ring and clerics learn Litany. Safe-rest preparation offers three learned spells while retaining two distinct equipped slots. Existing saves retain their starting spells; save validation accepts unlocked spells and rejects locked or duplicated selections. Cinder Ring costs 22 mana and burns nearby visible foes; Litany costs 26 mana, restores 22 vitality and interrupts nearby visible foes.

`--profession-check` includes rank boundaries, locked-spell rejection, three-spell preparation, slot uniqueness, unlocked-spell save/load and both new casts. Captures are `reports/20-progression-mage.png` and `reports/20-progression-cleric.png`. Human retest: reach 160 XP, rest safely, equip the new spell, save/reload and try it in combat. Balance and combat feel still require playtesting. The distributed 0.13.0 ZIP predates this source update.

## Dense grass coverage (0.13.0, 9 November)

Dense grass is enabled by default, including existing preference files that lack the new key. Settings > World & effects > Dense grass coverage toggles the additional meadow immediately and saves the choice. Off retains the lighter baseline grass. New geometry is built lazily only when enabled, and reused when toggled back on.

The field uses a deterministic jittered 0.8m grid, chunked MultiMesh geometry, wind, distance fade and nearby rendering. It covers the playable Hollow and March ground with over 700,000 additional tufts. Roads, buildings and water are kept clear. Mushrooms, fruit bushes and dry wood have persistent clearings that include blade width and wind motion; the old billboard and blade layers use the same pickup exclusions. No grass collider or global gameplay RNG changes are introduced.

`--grass-check` verifies default-on migration, saved off/on settings, actual rendered-instance clearance around pickups, old-layer clearings, UI checkbox behavior, and field/collectible views. Captures are `reports/19-*.png`; `reports/grass-performance.json` records local 1280x720 RTX 3060 on/off samples and generation time. The option is independent of Retro look and tree mode. No generated bitmap assets are needed.

## Quest interaction access (0.12.3, 9 November)

The latest bridge report reproduces a real blocker: its votive interaction ray aimed 0.7m above terrain, inside the solid 0.8m stone pedestal. The pedestal blocked its own interaction. Authored interaction heights now place shrine, sickbed, tablet and bell targets at their visible usable surfaces. Normal visibility checks still reject interactions through unrelated walls.

The reported main March chapter is already complete. Its remaining quest is **What Remains of Faith**: press E at Saint Avel's bridge votive, tend the Bellwether orchard shrine, then speak to Father Anselm at Saint Mary's Hospice, choose the vigil discussion and select prayer, silence or a remembrance ribbon. Existing saves retain their progress; no reset is needed.

HUD tracking now names the selected quest; journals include its next step. Completed selections and fully completed March quests explicitly say so and no longer show misleading destination markers. Shrine feedback names the next remaining stop. Nera's existing friendship dialogue is available with “Talk as friends…” from all her conversation branches. She has no authored intimacy scene; the optional non-explicit scenes belong to Mara and Lucan.

`--quest-access-check` uses the exact reported bridge camera and presses E, verifies unrelated-wall occlusion, reaches both votives/tablets/beds/bell through ordinary focus/E, completes the remaining faith quest through visible dialogue choices, verifies save/load and one-time rewards, and checks Nera's friendship access. Captures are `reports/18-*.png`; the exported builder runs this check too.

## March field fixes (0.12.2, 9 November)

All seven new reports from 08:46 through 10:17 UTC are addressed. Bridge and jetty colliders identify dry timber footsteps before water bounds; timber uses a short procedural footfall because the recorded pack contains no wood family. Door ramps meet the plank floor edge without coplanar overlap. The two sickbed patient decals are removed; beds retain pillows and woven blankets whose appearance follows the treatment outcome. Cross stems extend to their supporting terrain. Explicit round caps at road vertices close flat-cut gaps at bends and junctions, while all road triangles retain the terrain grid's planes.

Nera now keeps her chapter-aftermath conversation after `epilogue=true`, including old completed saves. Revisiting the outcome never repeats rewards. The reported save had already completed the epilogue, which previously routed her back to progress dialogue.

`--march-field-check` verifies bridge versus river audio, grounded crosses, removed decals, all three repeatable political aftermaths, reward idempotence and save/load. It recreates the reported threshold, both beds, orchard cross and hospice junction views under `reports/17-*.png`. The sound, terrain, March story and real-collision route suites provide integration coverage.

## Field fixes (0.12.1, 9 November)

Reviewed both latest player reports in `debug-logs`: 08:06 (harvested berry bush remains visible) and 08:08 (Captain Rook's boots sink into the road). All harvested forage now disappears completely and remains hidden after reload; fresh journeys restore it. NPC grounding samples the actual road polygons and includes their 7.5cm visual elevation, keeping boots above the painted surface throughout breathing. Existing saves use the corrected presentation automatically.

`assets/revision/tree-0.png` is replaced by a gently curved single-trunk pine, retaining the painted evergreen character without repeated large S-bends. Built-in image_gen produced the replacement; prompts, chosen source and alpha checks are recorded in `assets/revision/field-manifest.json`. The former asset remains in excluded `reports/tree-0-before.png`.

`--field-check` reproduces both reported camera positions and verifies one-time harvesting, visibility after save/load, new-journey reset and Rook's boot clearance. It also renders the replacement pine at 0/45/90-degree angles in Original and Copper. Source feedback/forest checks and the exported Windows checks cover integration; `reports/16-*.png` and the standalone staging reports contain the captures.

## Renaissance Hollow (0.12.0)

Current Windows distribution: **`dist/TheLastRoads-0.13.0-Windows.zip`**. Extract the entire folder and run TheLastRoads.exe beside its PCK. Source builds run through `launch.cmd`.

The autumn oak (`assets/revision/tree-3.png`) now has a mostly straight, single trunk for crossed paintings. Buildings have human-scale stone arched portals, recessed leaded windows, timber trusses and panelling, weathered coloured limewash with exposed brick, plank floors and capped brick chimneys. Furnishings reflect each building's use: millstones, grain hopper and sacks; workshop benches and tools; supplies and barrels; carved cupboards, turned pottery, brocade rugs and wall hangings, beds and seating. Small fixtures use a 75m visibility limit. Interior lanterns cast local shadows. The mill's existing moving wheel is preserved.

The built-in image_gen tool produced the tree edit and a four-material atlas of aged oak, woven sackcloth, brocade and brick. Exact prompts and sources are in `assets/revision/architecture-manifest.json`; all other new geometry and weathering is authored in code.

Fresh presentation remains fullscreen, Copper & Pine, Fine pixels, 50% dither and 30% grain. F11 toggles fullscreen. Existing preferences and save progression are preserved. `reports/15-*.png` contains actual rendered interiors/exteriors in Original and Copper. `reports/architecture-performance.json` records a short 1280x720 capture measurement on the local RTX 3060, not a hardware-wide performance guarantee. The architecture check probes actual doorway collision with the playable 2.45m ogre capsule and verifies clear entry aisles; forest and terrain suites cover tree modes, stable collisions, protected building pads, quests and legacy saves.

## Persistent likeness exclusion and Windows distribution

Since 2026-11-09, until direct user authorization changes it, every build excludes friends' faces and their derivative NPC paintings/portraits. `assets/friends/` remains development-only, with `.gdignore`, export exclusions and an archive audit covering imported texture payloads. Source photos `girl1.png` and `girl2.png` are excluded too. Ilya and Adela use their original fictional paintings in world and dialogue. Generic NPC, art or build requests do not authorize restoring likenesses; see `AGENTS.md`.

Rebuild with `py -3 tools/build_release.py`. The builder exports Windows x86_64 for OpenGL 3.3, applies the icon/metadata, audits its PCK, runs the standalone NPC/defaults/save/report, gameplay and sound suites, and creates a CRC-verified ZIP with engine/font notices. `reports/distribution-validation.json` and the adjacent SHA-256 file record distribution results. Test saves/reports are created in a separate staging folder and excluded from the archive. F5/F9 saves and settings remain beside the extracted executable.

## Recorded sound pack (0.10)

The **91 user-supplied MP3s in `sounds/`** now serve **46 of the 82 planned CSV sound families**. The runtime library discovers the files by name, accepts the variants actually available and avoids immediately repeating a variant where multiple choices exist. The original recordings remain in place and unchanged. Missing basic cues retain their procedural fallback; missing optional cues remain silent. Music remains the existing five-track soundtrack.

Integrated events include profession cast sounds and separate Dart/Ember/Rime impacts; staff versus sword contact; shield block versus parry; player hurt selected by character gender; enemy attack preparations, available hurt/death voices and both boss warnings; food versus tonic use; cache opening; distinct discovery/completion cues; menu confirmation/back and ability-cooldown refusal. Spell and burn damage no longer produces a false physical sword/staff contact sound. Nearby enemy cues use a bounded positional voice pool, with attack warnings taking priority over incidental sounds. Repeated vocal reactions are throttled.

NPCs use the provided shared gender groups, not fourteen nonexistent individual voice packs. **Female:** Mara, Ilya, Mother Vesna, Sister Elian, Adela, Nera and Ysabet. **Male:** Osric, Captain Rook, Tomas, Lucan, Garran, Corvin and Father Anselm. Greetings play on entering conversation, not every page; only one greeting plays at a time, with a short retrigger limit. Greeting audio can finish while dialogue pauses the world. Backtick reporting freezes it immediately along with music and world sounds.

Recorded ambience is selected for forest night and the underchapel. Nearby campfires, active Sanctuary and nearby burning enemies use quiet, bounded loops. Light and heavy rain recordings blend with rain intensity; synthesized wind and daytime ambience remain fallbacks because those recordings were not supplied. All recordings, NPC voices and weather route through **Sounds volume**, while all five music tracks retain **Music volume**. Menu/title transitions and loading clear stale effects.

Many source files are longer than their intended gameplay event. Playback offsets skip measured leading silence; brief impact/UI/reaction cues have bounded playback with tail fades. Seven footstep recordings have separate **0.46-second first-footfall WAV excerpts** with short attack/tail fades, preventing four-second recordings from stacking every walking step. Terrain selects road stone, dirt margin, grass or shallow-water recordings; crypt/indoor and raised bridge handling avoid inappropriate water footsteps. The originals are preserved. Processing details and source hashes are in `assets/audio/recordings.json` and `assets/audio/footsteps/manifest.json`; FFmpeg was used for offline decoding, not as a runtime dependency.

The CSV now lists supplied counts, source paths and integration notes. `reports/sound-integration.json` lists the supplied and still-missing families. Recorded assets were decoded and integration-tested; this is not a claim of an individual listening review of every file.

Verification covers loading all 91 sources, available-variant selection, short footsteps, shared greeting selection and page/retrigger/overlap behaviour, report freezing, player hurt gender, staff/spell dispatch, missing-file fallback, positional bus routing, night/crypt and local loops, rain layering, saved volume controls, story conversations and solo profession encounters. Current results are in `reports/validation.json`.

## Sound settings (0.9.2)

Settings now has three tabs: **Presentation**, **World & effects** and **Sounds**, available from both the title menu and paused game. Sounds provides **Music volume** and **Sound volume** sliders, each from 0?100% in one-percent increments with a numeric readout. Changes apply immediately and save automatically in the `[audio]` section of `settings.cfg`. Older settings files default both to 100%, preserving the previous mix.

Music controls all five context tracks, including crossfades and private scenes. Sound controls gameplay effects, spells, footsteps, ambient air/birds, rain, wind and thunder. Separate `RoadMusic` and `RoadSounds` buses retain the existing per-source balance. Zero percent truly mutes that bus; raising music volume resumes audibility without restarting its track. F10 temporarily mutes both categories and preserves the slider choices. **Reset sounds** restores only audio defaults; **Reset look** leaves audio choices intact. Diagnostic snapshots include both volume values.

The soundtrack/settings check verifies title and pause navigation, independent gain and zero-volume muting, every current player's bus assignment (including weather), F10 behaviour, persistence, backwards-compatible defaults, malformed-value handling and independent resets. The visual regression check passes for the existing nine styles and settings screens. Screenshots: `reports/12-sounds-title.png` and `reports/12-sounds-pause.png`. Tests use isolated report settings and do not replace normal player preferences.

## More visible spell effects and clean startup (0.9.1)

Mage Dart, Ember and Rime now use larger bright cores, elongated coloured trails and distinct fire/frost silhouettes. The trails grow behind the projectile rather than crossing through the camera at launch. Impacts last at least 0.6 seconds and expand into thick rings and elemental spokes. Dark rims preserve their silhouettes against bright backgrounds and in one-bit modes. The casting-hand diagram is roughly twice as large, with thicker strokes, and remains visible after the short hand animation.

Cleric RMB/Q Rebuke sends a large, expanding ivory/gold wave forward, with a double rim and four crosses. Its 0.75-second world effect is visible even when no enemy is hit, and stops travelling at intervening scenery. The cross gesture remains visible for 0.95 seconds. Mage Repulsion also receives a narrower blue geometric pulse. Effects use depth-tested, unshaded geometry compatible with the existing renderer and retro treatments. Spell damage, hit tests, costs and cooldowns are unchanged; the visual width of a projectile is not its collision radius. Combat pauses and diagnostic reports freeze these effects.

The default Godot boot image is disabled using `application/boot_splash/show_image=false`, with the boot background matched to the game's dark clear colour ([Godot 4.5 setting reference](https://docs.godotengine.org/en/4.5/classes/class_projectsettings.html#class-projectsettings-property-application-boot-splash-show-image)). The game opens into its existing title screen.

Rendered review captures cover Dart, Ember, Rime, Rebuke and impacts in Original, Copper & Pine and Macintosh modes (`reports/11-*.png`). The profession check also verifies effect lifetime/cleanup, paused visuals and the splash setting; live solo encounter checks confirm the combat outcomes remain intact.

## Distinct profession combat (0.9)

**Warrior** retains the sword, buckler, block/parry, heavy strike, Second Wind and Driving Strike. **Cleric** now uses a generated consecrated staff and a small Christian cross. **Mage** uses a generated wand and a free casting hand. There is no sword/shield requirement for either caster. First-person staff strikes thrust across the view; miracles raise the cross with restrained ivory/gold geometry. Wand attacks recoil briefly while the free hand draws a compact elemental diagram. The offhand temporarily replaces a held torch during a miracle or spell gesture. The shared equipment paintings are cosmetic; race-specific camera heights remain in effect.

| Mechanic | Cleric | Mage |
| --- | --- | --- |
| LMB, no mana/ammunition | Consecrated Strike: 24 physical damage, 3.6m generous melee reach, 0.78s rhythm, substantial ordinary stagger | Arcane Dart: 12 damage, aimed non-homing projectile at 38m/s, 0.55s rhythm |
| RMB or Q, no memorised slot | Rebuke: 10 mana, 5s cooldown; broad forward 5m interruption/push, stronger interruption of Abyss creatures | Repulsion: 12 mana, 8s cooldown; narrow forward 5m pulse against the nearest eligible enemy, little damage and strong ordinary push |
| Starting C | Judgement: 14 mana, 2.4s cooldown, 9m forward burst, 34 damage and strong interruption; +15% against Abyss creatures | Ember: 16 mana, 2s cooldown; visible 28m/s projectile, 24 direct damage + 4 damage/sec for 3s; 8 splash damage within 1.3m |
| Starting V | Sanctuary: 24 mana, 14s cooldown, fixed 3m radius for 8s; 35% damage reduction and 2 health/sec while inside | Rime: 12 mana, 2.6s cooldown; 14 damage, 4s slow and 6s Brittle; next Dart consumes Brittle for +18 damage |

Rime reduces ordinary movement speed to 45%, bosses to 85%; refreshes never multiply into a stronger slow. Bosses resist all displacement. Rebuke, Judgement and staff strikes build a short-lived stagger threshold; two points can interrupt a boss's explicitly labelled early windup, before 65% of the attack preparation. An active Echo Ward retains its original protection. Both bosses have colliders aligned with their taller sprites so aiming at their bodies registers. Brittle's damage interaction remains useful on bosses.

Ranged hits alert idle enemies; wounded enemies can pursue farther from home. Projectile range is capped below the enemy simulation radius (Dart about 44m, Ember/Rime about 45m), so sniping cannot repeatedly damage an unsimulated enemy.

Both casters regenerate **0.8 mana per simulation second**. Their basics remain useful at zero mana. Only two starting spells exist per profession: safe campfire rest opens a preparation panel to assign their C/V order. Escape keeps the previous order. There are no added schools, talents, reagents or ammunition. Spell slots, defensive cooldown, enemy burn/frost/Brittle/stagger timers, active projectiles and remaining Sanctuary duration persist through saves; older saves gain their profession's default slots and defensive cooldown. Invalid spell combinations and runtime payloads are rejected before loading. Osric's existing improvement now fits the chosen implement: Warrior 32?43, staff 24?28, Dart 12?15. Its original quest flag is retained for compatibility.

Sanctuary is one replaceable area, never a stacking multiplier or stacked healing source. It does not grant immunity, repel entry, warm/dry the player or count as safe rest. Walls and large vertical separation prevent protection through floors. This remains a single-player prototype; co-op ally damage/healing distribution is not implemented. Pauses and backtick reports freeze combat simulation, projectiles, statuses and animation. Diagnostic snapshots include the profession, prepared spells, active effects, positions and cooldowns.

Artwork: `assets/professions/equipment-atlas.png`, generated with the **built-in image_gen** tool. The exact prompt and layout are saved in `assets/professions/generation.json`. Runtime atlas regions preserve the original alpha; no existing equipment paintings were replaced. All nine retro looks cover the new equipment and effects. Upright depth-tested glow cards also prevent crossing light planes from painting a bright band across an actor. The actor-occlusion regression now samples the actual actor mask rather than fixed screen rows made stale by the terrain changes.

Acceptance uses the same bounded physics arena for both professions: three living bandits, three night Abyss creatures, the displacement-resistant Unburied boss, and a zero-mana ordinary encounter. Both won all four without tonic rescue or deaths. The input-driving bot uses actual attacks, collision, enemy AI, projectiles and spell costs; the Cleric approaches/holds ground and Mage retreats between casts. These automated arena results establish a playable baseline, not a human balance or full-expedition certification. Detailed runs are in `reports/profession-encounters.json`. Ten affected check groups passed (profession mechanics, live solo encounters, smoke, feedback, nine visual styles, survival, Warrior beacon combat, living world/race, production and March branches); the current roll-up is `reports/validation.json`. Full regional navigation suites were not rerun for this change. Focused checks cover aim/miss/wall collision, Brittle consumption, living-target sacred damage, boss resistance, fixed Sanctuary mitigation/healing/expiry, diagnostics, save migration and preparation. First-person captures are `reports/10-*.png`.

## Music and one-bit monitors (0.8.1)

The soundtrack now uses the supplied MP3 recordings instead of the procedural melody: `main_menu_music.mp3` on the title screen, `day_music.mp3` from 07:00 to 18:00, `night_ambient.mp3` at night and in the underchapel, `battle_music.mp3` for engaged nearby enemies including both bosses, and `love_music.mp3` during consensual private scenes and their immediate aftermath. The night source was missing but its complete MP3 bytes were recovered from Godot's existing imported audio resource and restored to `music/night_ambient.mp3`; builds no longer depend on that cache. There are five usable recordings including the title theme.

Tracks loop, with 2.5-second equal-power crossfades and a six-second combat hold to avoid switching after every swing. Intimacy overrides combat; ordinary paused dialogue retains its scene music. Music plays during the paused private-scene sequence, while opening the backtick debug report freezes playback and crossfade progress. F10 pauses all audio and resumes at the same position. Footsteps, weapon sounds, weather and environmental ambience remain separate. Diagnostic snapshots now record the music context, source, playback position, transition and mute/report status.

Settings ? Retro look ? Style now offers **nine** treatments. The three additions are **Macintosh** (near-black / aged ivory), **IBM 5151** (green-black / green phosphor) and **Commodore 1084** (navy / pale blue). These are original monitor-inspired treatments, drawing on the one-bit approach of [Lucas Pope's Return of the Obra Dinn](https://dukope.itch.io/return-of-the-obra-dinn), rather than historical hardware emulation or copied assets. Stable ordered dithering and luminance compression retain night detail. Grain perturbs the threshold rather than adding colours; blood and magic also obey the two-colour palette. Existing pixel-detail, dithering and grain controls apply. Illustrated menus, portraits and inventory art share the treatment; native UI text stays sharp. Existing preset indices and the Retro look on/off switch remain compatible.

Verification: the focused soundtrack check exercises source loading/looping, title/day/night/battle/intimacy transitions, paused intimacy, frozen reports, mute/resume and six monitor captures. Read-only pixel audits confirm exactly two RGB colours in each new world-only daylight/night capture. The visual regression check renders all nine looks at the inn, water and night and checks settings persistence, menus and diagnostics. Captures: `reports/09-monitor-{6,7,8}-{day,night}.png`; detailed outcomes are in `reports/validation.json`.

## Play or continue

Run **`launch.cmd`**. Begin a new journey to use the character creator. Continue preserves an existing character's progress; after the Northwatch beacon is restored, speak to **Adela beside the tower** to begin the Ashen March. Follow the new road around the east side of Northwatch and north over Saint Avel's Bridge. Nera waits at Saint Mere Refuge.

The original Hollow expedition is retained. A completed older save can enter the second chapter without replaying it. Existing saves and settings were backed up before this work and were not replaced by test progress. Testing uses `reports/integration-save.json` and `reports/integration-settings.cfg`.

### Controls

| Input | Action |
| --- | --- |
| WASD / mouse / Shift / Space | Walk / look / sprint / jump |
| E | Talk, investigate, collect or search a body |
| LMB / RMB / Q | Profession basic attack / class defence / heavy strike (Warrior) or class defence (casters) |
| C / V | Prepared spells for casters; Second Wind / Driving Strike for Warrior |
| I | Grid inventory; pick up and place items, R rotates a held item |
| 1–8 | Use assigned quick slot; while selecting inventory supplies, assign that slot |
| L / T | Lantern / offhand torch; a torch prevents shield blocking |
| F / R | Place a campfire / safe rest until morning, then caster spell preparation |
| J / M / Tab | Journal and regional map; dropdown chooses a tracked March quest |
| F5 / F9 | Save / load |
| Esc | Pause, leave a conversation or cancel an uncompleted private scene |
| Backtick (`) | Paused field-note entry; Enter saves; Shift+Enter adds a line |
| F10 / F11 | Sound / fullscreen |

Longer dialogue accounts scroll. The journal's **Hollow / March map** button switches map sheets. Completed ferry repairs unlock free passage between Northwatch, Saint Mere and Reedwater, avoiding repeated long return walks. Services and passage never require romance.

## Character creation

The creator appears before a new game and records name, age **18–80**, origin, profession, **Gender** (Man or Woman) and optional romance interest. The portrait automatically matches the selected gender; there is no separate portrait presentation control. Twelve generated portraits cover all six origins.

| Origin | Stored identity and treatment |
| --- | --- |
| Valdren human | `species_id=human`, `heritage_id=valdren`; western/northern road clothing |
| Shenari human | `human`, `shenari`; layered collars and eastern river traditions |
| Nambari human | `human`, `nambari`; southern lake/plateau clothing, varied Black-inspired appearances |
| Dwarf | `dwarf`, empty heritage; broad stature, no compulsory craft profession |
| Elf | `elf`, empty heritage; pointed ears, no inherited magic or religious allegiance |
| Ogre | `ogre`, empty heritage; large expressive people, no intelligence or morality penalty |

All six origins can take all three professions. Ancestry grants no mechanical or moral ranking. Camera and collision-capsule heights now follow species, on both new game and load. Eye/body heights in metres: human **1.62 / 1.95**, dwarf **1.12 / 1.42**, elf **1.76 / 2.05**, ogre **2.15 / 2.45**. Walking head bob uses the race-specific eye height. Capsule width, movement rules, equipment and first-person hand art remain shared. Age is recorded but does not repaint the face. Older independent-portrait saves normalize the portrait to gender on load; legacy third-option profiles retain their previous portrait through migration to the corresponding gender.

| Profession | Starting values | C | V |
| --- | --- | --- | --- |
| Warrior | 110 vitality, 32 blade damage | Second Wind: +35 stamina, 20-second recovery | Driving Strike: nearby visible foe, 25 stamina, 5-second recovery |
| Mage | 90 vitality, free aimed Dart: 12 damage, 80 mana | Ember: 24 direct + 12 burn / 16 mana | Rime: 14 damage, slow + Brittle / 12 mana |
| Cleric | 100 vitality, free staff strike: 24 physical damage, 70 mana | Judgement: 34 damage + interruption / 14 mana | Sanctuary: fixed protection and healing / 24 mana |

Mana returns slowly, at 0.8 per simulation second. Rest restores concentration and ability readiness. Insufficient resources or an active cooldown do not spend mana. Aimed spells and defensive pulses spend their cost even if they miss; Judgement is a forward burst, not automatic targeting. Cleric mana represents finite concentration, not a measurement of God's power. Older characters migrate to an adult Traveller profile while retaining their existing health, upgrades, items, quests and discoveries.

## Chapters and pacing

**Bells of the Hollow** remains the introductory expedition: Mara's missing caravan, Ilya's report, Rook's lamp oil, Elian's underchapel, preparation and the three-wave Northwatch defence. Vesna, Tomas, the cairn and Mara's personal conversation remain available.

**The Ashen March / The Names We Carry** adds seven locations: Saint Avel's Bridge, Saint Mere Refuge, Bellwether Orchard, Reedwater Landing, Veyr Counting House, Gallows Cut and Saint Mary's Hospice. There are twenty-six additional placed enemy encounters, an optional independent keeper fight and a settlement-dependent refuge defence. New routes connect the sites as a circuit with a central road and a restored transport shortcut.

The pacing target is roughly 15–25 minutes for the Hollow and 30–45 minutes for the March with personal stories. Walking tests cover 1,038m of Hollow routes and 2,056m of new roads/interiors, before the player's optional return trips and exploration. These are navigation measurements, not measured human completion times.

### New quest production sheet — contains spoilers

| Quest | Playable work | Decision and aftermath |
| --- | --- | --- |
| **The Names We Carry** | Meet Nera; investigate the bridge orders, private ledger, burial roll and Garran's testimony; resolve the record; return after freeing the bell | Chapter epilogue reflects the political settlement, patients, Ysabet, Lucan and the ferry. Personal quests can still be finished afterward |
| **The Last Dose** | Recover sealed bandages at Gallows Cut, salve at the ferry wreck and medicinal spirits at Veyr | Treat Raisa, a 54-year-old grain-barge owner, or Pavel, a 27-year-old bridge worker and expectant father. The other dies. The painted sickbed becomes empty and Nera acknowledges both names; neither choice buys intimacy or a superior reward |
| **A Name for the Ashes** | Find Elias Vale's locket in the burned press; obtain the hospice account; return to Ysabet | Give her the complete account or only its comforting part. Her memorial gains Elias's name; later dialogue remembers what she was told |
| **Letters Below the Water** | Recover the two dry pages from the wreck and return to Lucan | Reveal both Mateo's betrayal and his return to rescue people, or withhold the confession. Lucan's grief and later trust reflect that choice |
| **Two Shores** | Retrieve dry salvage rope and its timbers/brackets; use rope, 3 wood and 2 scrap at the winch after clearing danger | Restores ferry/trade-route passage and changes the winch presentation. Supplies are charged once; passage remains free |
| **A Soldier's Account** | Compare Garran's original order with Corvin's altered hour and clear the quarry robbers | Obtain a signed account with Garran committed to testimony, or accept his statement and let him leave in exile. His complicity is not erased by remorse |
| **The Price of Silence** | Present all four sources to Corvin; review and confirm a final settlement | Public hearing detains him and withdraws the garrison, requiring refuge defence. Private resignation preserves food and the complete record with Anselm, without a hearing today. Burning incriminating pages keeps Corvin in office, supplies moving and the official lie intact |
| **What Remains of Faith** | Tend the votives at the bridge and orchard; return to Father Anselm | Christian prayer, a silent vigil or a local remembrance ribbon. Each has authored acknowledgement; no morality meter or combat blessing is awarded |
| **A Bell Without a Master** | Resolve Corvin's record and any required refuge defence; clear the hospice grounds | Speak Mateo Venn, Elias Vale and Alina Rusk at their tablets and ring for remembrance, or call the Unburied into the open and defeat it. Both routes free the bell |

Choices are retained per character. Major political settlements require a separate confirmation and cannot award repeat rewards. Treatment, repairs and quest completions are similarly guarded. The public-hearing defence and the independent keeper can resume after saving/loading.

The March has a new safe refuge and respawn point after Nera's briefing. The refuge loses its safety protection during its required defence. Foraging, weather, cold, fire, food, equipment and portable camps work across both regions. The eastern March is explicitly outside the old underchapel region; its terrain, weather and map no longer inherit crypt behaviour merely because of its X coordinate.

## NPCs and generated artwork

Art follows `NPC_Old_Masters_Lookbook.pdf` and `NPC_Regeneration_Guide.md`: natural adult faces and hands, broad quiet cloth, selective detail, lifted shadows and distinct costume colours. The Sister technical/style pilot and Mara character pilot were produced before the rest. Mara is mature, full-bodied and self-possessed; the Sister remains covered, devotional and excluded from intimacy. Osric retains the hammer down at his side; Rook retains his feathered hat and downward rapier.

The eight original NPCs have new full-body masters: **Mara, Osric, Ilya, Mother Vesna, Captain Rook, Sister Elian, Tomas and Adela**. The six new people are **Nera** (Nambari physician), **Lucan** (Shenari ferryman), **Ysabet** (orchard keeper), **Garran** (former captain), **Corvin** (ogre magistrate) and **Father Anselm** (dwarf Christian priest). Their ancestry does not determine profession, intelligence or ethical standing.

All production images live in **`assets/old-masters/`**. Original art in `assets/revision/` is retained. Eighteen generated masters cover fourteen NPCs, twelve creator portraits in one atlas, two covered keepsake portraits and the two-bed patient atlas. Four additional generated face edits supply tightly masked eyelid changes for the lookbook characters.

| Artifact | Purpose |
| --- | --- |
| `source-contracts.json` | Original files, SHA-256, active frame size, baseline and filtering audit |
| `asset-map.json` | Original-to-new mapping, exact output frame canvases, uniform fitting and placement |
| `generation-prompts.json` | Exact prompt set and built-in generation method |
| `alpha-audit.json` | Read-only audit of original hashes, visible bounds, baselines and genuine alpha |
| `blink-audit.json` | Four blink sheets; zero changed pixels outside eyelid masks and zero alpha changes |
| `npc-*-source.png` | Preserved generated full-body sources for the original cast |
| `npc-*.png` | Stable single-frame masters; first eight normalized into their original frame canvases |
| `npc-*-poses.png` | Open/closed two-column sheets for Sister, Mara, Osric and Rook, in their original sheet dimensions |
| `*-closed-face.png` | Generated eye-edit sources; only tiny eyelid masks are composited into game frames |

The first eight masters preserve world height and ground baseline through uniform fitting, without stretching anatomy. Their painted contours naturally differ from the old illustrations. Blink sheets copy the approved master and replace only feathered 12×6-pixel eyelid masks: bodies, props, mouths, silhouette and alpha stay identical. The remaining characters keep one stable open-eye frame. World and dialogue rendering both use the appropriate frame; private relaxed portraits stay stable.

Generation used the **built-in image_gen tool**, followed by deterministic Godot image assembly. Python/Pillow is used only for read-only auditing. These are source paintings and renderer treatments, not a claim of separately hand-authored pixel-art variants. The nine retro looks, pixel detail, dithering and grain remain selectable. Four tree modes remain independent of the stone presentation; rocks always use their original camera-facing paintings.

Art rebuild/verification commands, from the project root:

```powershell
tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/build_npc_assets.gd
tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/npc_blinks.gd
python tools/art_audit.py
```

`npc_blinks.gd -- --prepare` recreates the enlarged face edit inputs. Rebuilding full-body masters should be followed by blink assembly and Godot reimport. The input contracts remain historical originals. Rollback is available through the retained revision assets and the centralized `sprite_library.gd` path selection.

## Optional intimacy and keepsakes

There are two complete authored branches, both for unambiguously adult characters and both non-explicit. **Mara, 45**, can express interest in adult travellers of any gender after the supplies/scout milestone and a personal conversation. **Lucan, 36**, is an authored gay man; his optional ending follows the complete letter and a separate conversation about grief and his own wishes. Player interest is recorded separately from appearance and ancestry.

Each flow offers friendship, reciprocation and a graceful decline, then a **separate final confirmation**. A private place is established through the inn's back room or ferry hut, followed by a fully covered relaxed portrait, fade to black and ordinary aftermath over tea. No sexual activity, explicit anatomy or sexual audio is shown. These are illustrated interludes rather than staged physical character animations.

Eligibility is checked again before the memory is committed: adult age, authored preference, relationship context, location within the NPC's safe area, enabled invitations and no nearby enemies. Esc can leave before completion. Declining keeps services, passage and quest rewards. The Sister and Father Anselm have no encounter branches. Romance is not a completion requirement or a combat upgrade.

**Settings → World & effects → Optional private invitations** disables invitations without deleting existing memories or ordinary friendship. A completed scene adds a first-time personal keepsake to the journal: Mara's *A Little Lamplight* or Lucan's *The Turning Tide*. Cards belong to the saved traveller, have no rarity or conquest count and grant no bonuses. Completion and card state are stored in the same atomic save payload; F5 saves both together.

Neither scene advances the day or elapsed simulation clock. Their transitions advance through a paused-scene controller, which also stops during a backtick field note. The debug snapshot records partner, phase, transition progress and commitment status. This is a local single-player implementation; future co-op needs private per-player UI and networking work rather than a global pause.

## Living-world ambience

The world now has randomized flocks of animated birds, small resting ground groups, tiny swirling insect clouds and drifting autumn leaves. Nearby players or living creatures scatter a resting group into flight. These are cosmetic meshes: no collision, interaction prompts, target entries, loot or quest state.

The pools are bounded at 40 birds, 40 leaves and three clouds of 28 insects. They use a private random generator, recycle distant/expired instances and operate in both regions. Heavy rain or strong winds suppress insects; the visual wind setting governs leaves. Interiors and the underchapel suppress the outdoor ambience. Menus and backtick field notes freeze the entire system. Diagnostic snapshots include population counts, scatter events and the ambient clock, as well as actual player eye and body heights.

Focused verification: `tools/check.ps1 -Only living`. The check covers both portrait rows across all origins, race height and save/load, legacy profiles, player/creature-triggered takeoff, bounded pools, weather/wind suppression, pause behaviour and rendered comparisons. Screenshots: [flock](reports/08-living-world.png), [dwarf viewpoint](reports/08-camera-dwarf.png), [ogre viewpoint](reports/08-camera-ogre.png).

## Rolling Roads / current terrain and report fixes

Build 0.8 rebuilds the landscape with seeded three-octave Perlin noise and a slower broad hill layer. Sampled relief is **30.5 metres**. Settlements, building footprints, courtyards, the bridge and banks, ponds, quest landmarks and the crypt retain flat protected pads. Roads use flattened corridors with gentle longitudinal grades; a smooth 22m transition blends site pads into surrounding hills. The physical ground is a chunked 2.5m triangular heightfield.

Road outlines now use rounded joins and are clipped against the same triangles as the physical ground. This removes both the old folded-corner holes and terrain poking through a road surface. Terrain queries interpolate that exact triangle, rather than an unrelated smooth height function. The Fen approach now follows the walking route around the marsh instead of cutting through a tree.

The new cover contains approximately **18,294 clumps**: wind-responsive, three-dimensional grass blades plus more restrained illustrated wildflowers. Grass is batched in 64m patches, fades with distance and clears roads, doors, searchable objects and water surfaces. It is cosmetic and has no collision.

| Newly supplied reports | Resolution |
| --- | --- |
| `16-03-43`, `16-04-44`: retro art missing from menus and inventory | Title, creator, dialogue/keepsake imagery and inventory/quick-slot icons now use the selected colour/pixel treatment. Atlas portraits quantize within their own atlas region. Labels and counts render separately at native resolution |
| `16-22-30`, `16-22-44`: Adela's sales/purchases appear inactive | Snapshots confirmed purchase arithmetic was working, while repeated sales had no eligible goods. Shop now stays open, displays live purse/stock totals and explicit transaction feedback, and disables an empty sale with a reason |
| `16-23-50`, `16-25-26`, `16-31-27`: triangular road gaps | Rounded road polygons conform to and are triangulated on the physical terrain, including the reported turns |
| `16-25-09`, `16-33-25`, `16-33-33`, `16-34-00`: non-interactive chests | Six former decorative refuge/Veyr chests are now registered, searchable caches with modest authored contents and persistent one-time collection |
| `16-26-59`: empty houses | Added cupboards, tables, chairs, crockery, candles and wall cloths/crosses, with clear entry aisles and exclusions around quest objects and sickbeds |

Saves remain schema 5, with an added `terrain_revision=1`. Older saves reproject the player, recorded enemies and portable fires onto the new ground once; subsequent loads retain exact positions. Quest choices, inventory and map coordinates are preserved. The pre-change player save and settings were copied to `reports/pre-0.8-player-save.json` and `reports/pre-0.8-settings.cfg`; the live files are not replaced by tests. Falling recovery now measures distance below the local ground rather than treating any negative world altitude as a fall.

Focused verification: `tools/check.ps1 -Only terrain`. Captures: [road repair](reports/09-turn-bridge.png), [ground cover](reports/09-dense-foliage.png), [furnished refuge](reports/09-furnished-refuge.png), [retro menu](reports/09-retro-title.png), [retro creator](reports/09-retro-creator.png), [retro inventory](reports/09-retro-inventory.png), [merchant feedback](reports/09-merchant-feedback.png).

## Earlier debug-log fixes

The six new reports from the 0.5 build were read with their saved context and screenshots. Older reports retained in the folder describe work already covered by the previous prototype.

| Report on 8 November | Fix |
| --- | --- |
| `12-56-42-143780346` — stones look wrong | Rocks restored to original fixed-Y camera-facing billboards in every tree setting |
| `12-59-34-316507678` — rain ignores upward camera pitch | Velocity-aligned world streak shader: only the thin axis faces the observer; the falling axis follows particle velocity, including a parallel-view safeguard |
| `13-00-18-360510950` — mill wheel misses water | Continuous millrace bend under the wheel at X≈−130.3; lower paddles enter the water |
| `13-02-33-494889686` — unsupported chimney | Masonry stack continues from hearth/floor through the roof, with a hearth apron; cottage entry ramps retain walkable access |
| `13-03-07-529151703` — persistent blood/spirit stains | Simulation-time decay: fade begins at 40 seconds, removal at 55; pause and field notes freeze decay; capped population retained |
| `13-04-06-588051634` — Ilya hair artifact | New stable Ilya master and alpha-edge preparation replace the old hair treatment; no independently regenerated full-body blink frames |

The visible-red-pixel audit is a limited colour check, not proof of the old hair artifact's exact cause. The asset replacement and rendered review address the reported appearance without inventing a confirmed diagnosis.

Backtick reporting remains available in play, menus, creation, dialogue and scene transitions. Enter writes the user's text, screenshot, stats, profile, position/orientation, area, quest choices, inventory, enemy records, weather/exposure, rendering settings, transition context and recent/runtime events into a timestamped folder under **`debug-logs/`**. Reporting does not consume gameplay time.

## Persistence and implementation

Save schema **5** adds the profile, mana/cooldowns, relationship and keepsake state and the March story record. Schemas **2, 3 and 4** remain loadable. Writes use the existing temporary-file/backup/rename transaction. Invalid profiles, unsupported story decisions and inconsistent completion/card pairs are rejected before replacing live state. `world_id` and the original layout identifier remain stable for additive continuation.

The authored content is separated into `march_content.gd`, `march.gd` and `march_world.gd`; character definitions and creator UI are in `character_data.gd` and `character_creator.gd`; `relationships.gd` owns both optional encounters. Original narrative actions are retained. The journal can track seven March objectives independently of the main expedition.

The terrain extends north to the hospice; movement/save bounds match it. New roads approach real doors and the counting-house gate, with ramped bridge/jetty/house collision surfaces. Original NPC map coordinates and physical stature, quest identifiers and key Hollow route destinations remain in place. New forest placement uses a private RNG for its extra northern population; the expansion also clears new site/object approaches.

## Validation and review artifacts

Run the complete suite with **`tools/check.ps1`**. `-Quick` omits live combat and navigation runs; `-Only production`, `-Only march` or `-Only march-route` selects focused checks. All integration modes use isolated save/settings paths.

Sixteen available check groups cover smoke, rendered tour, historical feedback, nine visual looks, four tree modes, creator/art/consent production checks, living-world/race checks, terrain/shop/UI/cache checks, inventory/weather survival, March story branches, both regional navigation runs and live beacon combat. The March checks exercise every political settlement, both final bell methods, all three faith rites, treatment consequences, evidence gates, repeat-reward protection, defence reload, Lucan's preference and consent, paused diagnostics, two maps and persistence. Creator checks cover all eighteen origin/profession combinations and reject underage or inconsistent profiles.

The live prepared-warrior beacon test completed in **62.4 simulated seconds**, with no deaths. Walking validation reached the old oil, chapel and crypt seals, plus every new road and the refuge sickbeds, Veyr ledger and hospice interior. Four blink sheets additionally have exact outside-mask/alpha comparisons. `reports/validation.json` and per-check stdout/stderr logs hold the machine results.

Selected rendered artifacts:

- [Character creator](reports/06-character-creator.png)
- [Mara aftermath](reports/06-mara-aftermath.png)
- [Lucan aftermath](reports/07-lucan-aftermath.png)
- [March journal and map](reports/07-march-journal.png)
- [Saint Mere](reports/07-site-ash_refuge.png), [Reedwater](reports/07-site-ash_ferry.png), [hospice](reports/07-site-ash_hospice.png)
- [Public-hearing epilogue](reports/07-epilogue-trial.png)
- [Animated blink and before/after review](reports/npc-blink-check.html)

## Deliberate prototype limits and next validation

The one-hour target needs human pacing feedback; direct main-quest play can be shorter than a complete personal-story run. NPCs are illustrated actors rather than fully animated 3D characters; buildings use the established painted modular architecture. The new keeper reuses the existing supernatural enemy illustration with independent encounter logic. Distinct player hand/body artwork, a broad appearance editor, voice acting, multiplayer and separately authored native pixel-art variants remain future work.

The next useful playtest is a normal new journey with one spellcaster, followed by continuation from the user's existing save. Watch story comprehension, whether the journal's selectable objectives reduce backtracking, the weight of the patient decision, and whether the three settlements feel distinct. Preserve field notes for actual friction rather than extending the world again before this hour-long route has been played.

## Sound production list

The actionable recording/delivery list is [sound_asset_list.csv](sound_asset_list.csv). This is an asset plan, not a claim that these WAVs exist or have been wired into gameplay. The CSV gives suggested filename, variants, duration, loop status, priority, current implementation/hook and creative brief for every sound family. Variant filenames use `01`, `02`, etc. The 14 optional NPC greeting files represent one per NPC, not 14 randomized voices.

At the original planning stage, five supplied MP3 tracks already served title, day, night/underchapel, battle/boss and intimacy. They do not need replacing for this pass. The short effects were then procedural placeholders: `hit`, `swing`, `block`, `hurt`, `pickup`, `quest`, `step`, `bell`, `heal`, `thunder`, `dart`, `ember`, `rime`, `judgement`, `sanctuary`, `rebuke`, `repulsion`, `brittle`, `spell_impact`. At that stage forest air/birds and weather rain/wind were also synthesized. Version 0.10 now replaces the supplied families as described above. Shared hooks need separating where the CSV calls for distinct sounds; all other rows require a new event trigger as well as the asset.

Priorities:

- **P0: 28 families / 80 files.** Combat readability and essential movement/weather: produce first.
- **P1: 45 families / 78 files.** World presence, inventory, profession detail and story feedback: second pass.
- **P2: 9 families / 28 files.** Wildlife, localized scene foley and optional NPC vocal colour: polish.

The full list is **82 families / 186 files**, including variants; five existing music tracks are additional. This is the complete suggested pack, not the minimum needed for the next playable build. For the first small delivery, start with **Rebuke, Dart cast/hit, Ember cast/hit, Rime cast/hit, Brittle shatter, Repulsion and the two boss attack warnings**. They provide the biggest immediate improvement to the new combat loops; follow with steps, weapon impacts and player hurt.

Art direction: tactile early-Baroque dark fantasy. Warrior = leather, wood and steel; Cleric = breath, pressure and restrained warm bell resonance; Mage = focused arcane snaps and clearly separated fire/frost textures. Retain sonic identity across all graphics presets. Retro visuals do not require every sound to be an electronic beep. Distinguish attack preparation, successful hit, defended hit and combo payoff. Quest resolution should accommodate grief and difficult choices. Intimacy scenes need only quiet non-explicit scene foley beneath the existing music. No new sound pack for unimplemented spells, weapons or talent systems.

Delivery specification for this project: **48 kHz / 24-bit PCM WAV masters**; mono for positional one-shots, stereo for broad ambience. Supply dry combat/foley without baked music or long reverb; bell tails may decay naturally. Trim leading silence without clipping transients, preserve decay tails, avoid clipping and heavy limiting, and keep related variants at similar perceived loudness. Ambience must loop seamlessly; rain and wind are separate layers, and thunder must not be baked into either. For purchased/third-party sources, include source and licence metadata. The file count covers final variants, not extra alternate formats or stems.

Integration notes: environmental sources and enemies should become positional rather than playing every sound at equal volume. Footstep surface detection, enemy telegraph/death triggers, differentiated impact dispatch, new ambient emitters and UI/scene triggers still need code. Add voice limits and retrigger delays for ambience, failed actions and overlapping burns. Critical enemy warnings must remain audible beneath combat music. Pause gameplay sounds with the world; retain intentional private-scene music and freeze all playback when the debug report opens. Keep this task to asset planning; no game audio behaviour was changed.

Temporary ElevenLabs queue files and generated CSV translation artifacts were removed from the project root. The canonical `sound_asset_list.csv` and runtime sounds remain. The CSV uses Godot's Keep import mode so it does not generate translation files on the next project import.


Pistol pose review (2026-11-09): latest three reports fixed using IMG_1108.jpg for forward perspective, wrist tilt and upward-facing lock. Pistol reload uses the working hand behind the weapon without a rod; musket retains its rod. Fire follows muzzle/pan transforms; smoke stays at emission points. Ranger regression and pose checks pass in Original/Copper report-camera captures (reports/27-pistol-*.png). Full asset prompt and audit: assets/ranger/pistol-pose-v2.json. Reference photograph excluded from exports. Source changes only; distribution ZIP not rebuilt.

Pistol sight clearance (2026-11-09, report 20-11-26): lowered the ready pistol by 105 virtual pixels and moved it 40 right. The image starts below y398, leaving the central aiming dot and targets clear. Camera-centred hit ray is unchanged; muzzle/pan effects follow the lowered art. Original/Copper captures reproduce the latest report camera and saved character. Source only; ZIP not rebuilt.


Equipment debug review (2026-11-09, reports 20-46-11 and 20-49-28): Unremembered collision height now matches its 2.7m visible body, fixing shots passing over the old 1.7m capsule. Dagger enlarged with sleeve overscan through all thrust phases. New detailed painted musket uses musket.png forward perspective and position, right-side flint lock, preserved aspect and matching dynamic pan/muzzle/reload-rod anchors. Provenance: assets/ranger/musket-pose-v2.json. Source only; distribution ZIP not rebuilt.


Cartridges and black-powder effects (2026-11-09): shared paper-cartridge stack is visible in the backpack and bindable to quickslots as an inspectable supply. Pistol and musket consume exactly one cartridge on firing, including misses. Reload/cancel consume none. Ammo v2 saves use inventory.cartridge, with one-time migration of old spare, loaded and in-progress charges; new Rangers carry 32 total, capacity 122, shops sell 12 for 6 coins. Musket muzzle and pan flames enlarged threefold; four-second smoke uses layered domain-warped noise, rising billows, soft edges and shaded soot instead of circle primitives. Existing likeness export exclusions unchanged. Source changes only; ZIP not rebuilt.

Separate ammunition and musket sightline (2026-11-09): new Rangers receive 10 pistol cartridges and 5 musket cartridges. Each weapon consumes its own stack, remains 80/130 damage, and shops sell 12 pistol or 6 musket for 6 coins. Ammo v3 migrates shared and older reserve ammunition once at a 2:1 ratio with total rounds preserved; old shortcut bindings map to pistol cartridges. Inventory/quickslots identify P/M stacks. Musket muzzle repositioned to (690,385) so the projected barrel points at the central aiming dot, with effects/reload anchors following the new position. Source only; ZIP not rebuilt.
