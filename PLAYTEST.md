# Bells of the Hollow — field-note update 0.3

Run **`launch.cmd`**. Choose **Begin a new journey**, then speak to Mara in front of the inn. This is the expanded adventure, replacing the tiny First Ember scene. The old design document remains the long-term vision.

Godot 4.5.1 stable is pinned. If its local executable is missing, the launcher runs `tools/setup.ps1` to download and verify the official Windows archive. The first launch imports assets. F11 switches fullscreen. The game pauses automatically when you switch to another application during play.

The new build aims at **about 20 minutes when exploring, reading conversations and doing the optional requests**. A direct main-quest run can be shorter. Human pacing and combat feel still need your playtest; automated checks do not establish either.

## What is playable

- A hand-authored valley with winding stone roads, an inn, a grove, a ruined toll, a watermill, a chapel and underchapel, a haunted fen, a cairn and Northwatch.
- Eight illustrated NPCs with authored conversations and choices.
- A main expedition: recover a caravan, hear the scout's report, acquire oil by trading or fighting, recover a ward through a crypt puzzle, prepare at the inn, and defend a restored beacon.
- Optional herbalist and courier quests, a roadkeeper's grave, a lost letter and four supply caches.
- Deserters, hounds, spirits and the Bell Warden. Attack, heavy strike, directional block and timed parry; visible wind-up, lunge and recoil poses.
- Sword and coat improvements, healing supplies, loot, campfires, safe rest, changing daylight and a personal lantern.
- Searchable, persistent enemy remains; wild berries and edible/inedible mushroom collections.
- Sharper NPC art with blinking and breathing, independent tree textures, fixed shadow proxies and foliage wind.
- A journal and valley map, with an interior map in the underchapel. The compass arrow points toward your next main objective.
- A visible outcome: the beacon burns, a caravan arrives and people return to Northwatch. Rescuing Tomas changes who reaches the restored road.

## Controls

| Action | Key |
|---|---|
| Move / look | WASD / mouse |
| Sprint / jump | Shift / Space; consume stamina |
| Strike / block | Left mouse / hold right mouse facing the attacker |
| Heavy strike | Q; costs 25 stamina and staggers ordinary enemies |
| Timed parry | Raise the shield just before impact |
| Talk / collect / use | Look toward the person or object and press E |
| Dialogue choices | Click or press 1–3; Esc leaves |
| Tonic / bread | 1 / 2 |
| Eat berries / edible mushrooms | 3 / 4 |
| Campfire / safe rest | F / R beside a fire with no nearby threat |
| Lantern | L |
| Journal & map | J, M or Tab; same key or Esc closes |
| Save / load | F5 / F9 |
| Pause | Esc |
| Sound mute | F10 |
| Fullscreen | F11 |
| Field note / bug report | Physical backtick key, above Tab on US keyboards |

Basic attacks and ordinary blocks do not use stamina. Heavy attacks and sprinting do. A regular block reduces a hit to chip damage; a timely parry prevents it and creates an opening. The Bell Warden resists ordinary heavy-strike staggering and calls spirits that shield it. Defeat its echoes before hitting it again.

A tonic restores 55 vitality. Bread restores 28 and refills stamina. At zero vitality, a remaining tonic provides self-rescue. Otherwise you return to the inn, lose up to 8 coins and retain experience and quest progress. Persistent dropped backpacks are not implemented in this build.

## A spoiler-light route

Talk to Mara and optionally Osric. Follow the north road to the fallen toll and recover the supplies. Ilya waits just beyond it. The crossroads lead west to Rook's mill and east to Sister Elian's chapel. Return to Mara once you have both the oil and clapper; she provisions the final journey to Northwatch.

Vesna's grove branches off the first stretch of road. Tomas is in the fen beyond the mill. The King's Cairn is on the chapel's northern branch. Explore these for supplies and stories before the finale. The underchapel clue stays in your journal, so you need not memorise it from the dialogue.

## Saves

`F5` writes **`saves/hollow-valley.json`**. F9 or **Continue journey** restores it. The previous save is kept as `.bak` and replacement is staged through a temporary file. Invalid or mismatched saves are rejected before changing live state.

Schema 3 stores player position and view, inventory, upgrades, time, quest flags, pickups, discoveries, enemy positions/health/attack phases, searched bodies, portable fires and defence progression. Schema-2 valley saves migrate in memory: old kills count as searched because that version already awarded their loot. Existing coin, experience and quests are retained. The player's file is not rewritten until saving; the pre-update copy is also retained in `reports/pre-0.3-player-save.json`. The much older `saves/expedition.json` belongs to the different First Ember map and is not loaded into this one.

Use E to search remains and harvest marked plants. Coins, scrap, pelts and essence now come from searching bodies; experience is still awarded on defeat. Searched remains disappear. Berries and coppercaps are food, while inedible bonnets stay separate and cannot be consumed with the food keys. Adela buys pelts and curios. Foraging placement is deterministic and collected items stay collected after saving.

## Backtick field notes

Press **`** from gameplay, a conversation, journal, pause menu or title screen. The game pauses and a text dialog opens. **Enter** saves, **Shift+Enter** adds a line, **Esc** cancels. A blank note stays open with a message. Cancelling or saving restores the previous pause state.

Each submission creates a unique UTC-stamped directory under **`debug-logs` in this project**:

- `note.txt`: your exact description, with surrounding whitespace trimmed.
- `screenshot.png`: the completed frame before the note dialog opened.
- `report.json`: the description and screenshot reference, complete coordinated game state, position, view, area/world/layout/build identities, fixed seed, current objective, dialogue and combat state, recent events, OS/GPU/viewport, FPS, process time, memory and the tail of the runtime log.

The launcher writes engine messages to `debug-logs/runtime.log`. No desktop capture or voice recording is made. A failed report write leaves your text open. Reports do not overwrite your save. Their state payload can help reproduce bugs in a later development session.

## Art and sound

The world uses a painterly 2.5D presentation: generated illustrated trees, foliage, people, creature poses and first-person equipment inside a textured 3D valley. Buildings and colliders remain 3D. Warm windows, particle fires, fog and day/night lighting support the atmosphere.

Production art lives in `assets/`. Exact prompts are in `assets/generated-manifest.json` and `assets/revision/manifest.json`; see `assets/PROVENANCE.md` for sources. Independent tree textures avoid atlas bleed. Cached sprite extraction trims invisible padding so it no longer contributes to physical height. Camera-facing cards do not cast shadows; trees use fixed shadow silhouettes and NPCs have contact shadows. Leaves and soft plants sway while lower trunks, rocks and chests remain fixed. Audio is synthesized wind, birds, quiet musical notes and game feedback. Cinzel headings use the SIL Open Font License.

## Verification

Run all rendered integration checks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/check.ps1
```

Use `-Quick` for quest/input/persistence checks, the screenshot tour and the feedback regression suite. The full set also walks the collision body along an authored route and fights the complete defence using live enemy AI. The runner checks exit status, assertion/errors and expected success output. These test modes write `reports/integration-save.json`, never the player's ordinary save. Results are recorded in `reports/validation.json`, with rendered views in `reports/`.

The smoke suite covers damage/cooldown/parry, the peaceful mill route, incorrect/correct seals, both collection quests, defence state transitions, save/load, corrupt-data rejection, nonduplicate rewards, actual backtick/Enter/Shift+Enter/E/Esc input, frozen simulation and restoring the previous pause state. Every NPC is checked for proximity selection and conversation access. The live defence check exercises both boss echo wards. The traversal test caught and led to fixes for the chapel and tower thresholds.

## Next playtest

Begin a fresh journey. Can you find Mara, follow the first objective and understand the attack tell without reading this file? After that, try an optional request and one upgrade before the finale. Record unclear objectives, frustrating fights, visual problems and positive moments through the field-note key.

Known limits: solo only; billboard characters face the camera rather than having complete directional animation; no spatial backpack, co-op, mage/cleric, voice, freeform construction, procedural areas or exported standalone package. Enemy navigation is local pursuit with collision and a home leash; it is not a complete navigation-mesh system. Some sprite edges and distant repetition can still show. The first-person weapon is an animated illustration rather than a rigged 3D mesh. The valley is a fixed authored prototype.

## 0.3.1 field-report follow-up

Launch normally and Continue: existing progress is compatible. Check fixed tree trunks away from roads, mushrooms outside roots, the wheel behind the mill, continuous stream/pond surfaces, Tomas on his platform, left-hand shield grip and overhead alternate attacks. Search a fallen enemy: three blinks precede one smoke puff; pause freezes cleanup. All NPCs use stable open-eye art to remove body flicker; Ilya has a new generated portrait/sprite. Detailed report: reports/2026-11-08-followup.md.

## 0.4 Retro Roads

Open **Settings** on the main menu or **Esc > Settings** during a journey. Turn **Retro look** on, then choose Hollow 16, Copper & Pine, DOS Chronicle, Gothic Dusk or CRT Traveller. Copper & Pine is the recommended first comparison. Pixel detail, ordered dithering and paper grain have separate controls; Back saves automatically, and Reset look restores the original presentation. Preferences live in settings.cfg and do not change journey saves.

The preview responds immediately. Worlds, sprites, buildings, water, effects and weapons share the treatment; text stays sharp. Check night visibility and water as well as the inn. Compare captures in reports/retro-gallery.html.

Latest fixes: smaller lower-left shield, sword drawn in front of it, cleaned Tomas sprite. Backtick reports now include visual settings. Automated test reports go to reports/debug-logs; player reports still go to debug-logs. Full validation now includes --visual-check and renders each style at day, water and night, plus a 2560x1440 check.

## 0.4.1 Rooted Hollow

**Settings > Trees** now offers Crossed paintings (default), Rooted 3D grove, Still illustrations and Camera-facing legacy. The choice is independent of Retro look and persists. Crossed paintings keeps the generated art on fixed intersecting planes; Rooted 3D provides solid volume; Still illustrations looks best from the road but becomes thin edge-on. Compare the same trees from three angles in reports/tree-gallery.html. Root collision and pickups never move when switching modes.

The new **Gilded Hollow** preset is a richer gold/emerald variant of Copper & Pine. Try Fine pixels, 50% dithering and 30% grain. Both sliders now show percentages. Existing colour preferences are preserved.

Check Osric outside his workshop, human eye level beside NPCs, stable character colouring during attacks, and the darker middle-distance tree colours. Human NPCs now have individual heights; player body and eye height are 1.95m and 1.80m. The full route, including the crypt, is validated with the taller collider. New snapshots include the selected tree mode.

## 0.5 Rain and Road

- **I:** open/close the paused backpack. Drag an item bundle into the 8x6 grid, **R** rotates while held, **Esc** cancels a move before closing the pack. Invalid drops cannot overlap or escape the grid. Shift-click quick-packs; Auto-arrange tidies all bundles. There is no weight system. Supplies stack by type without a stack cap; coins stay in a purse and basic equipped gear stays outside the grid. A temporarily unpacked bundle is retained safely; use Auto-arrange if a fragmented layout prevents fitting it.
- **1-8:** HUD quick slots. Select an item in the backpack and press a number, or click a slot, to bind it. The defaults are tonic, bread, berries, coppercaps, campfire, lantern, rest and torch. Right-click a selected food/tonic to use it. Reset quick slots restores the defaults. Crafting/trade items cannot be assigned as consumables.
- **T / default slot 8:** swap buckler for a torch. It provides warm light and drives ordinary night spirits back. Warden and echo enemies are not repelled; you cannot shield-block while holding the torch. Both torch and slot assignments are saved.
- Weather changes automatically through clear sky, passing clouds, rain, heavy rain, strong wind and thunderstorms. Transitions are gradual. Rain wets you; wetness, night and wind build cold. High exposure slows stamina recovery and slightly reduces movement, without dealing health damage. Shelter blocks rain, fires dry and warm you, and the ash-lined coat reduces buildup. Wetness, cold and weather progress persist.
- **Settings > World & effects:** visual wind strength (Off/Gentle/Normal/Strong), Small/Large blood and spectral splashes, and lightning flashes. Turning wind visuals off does not remove weather exposure. Lightning has visible bolts and delayed thunder.

Latest report fixes also include the actual NPC glow-intersection seam, lower camera, grounded roots and Rook boots, stationary rock options, closed road bends, a longer stream, irregular pools, more windblown grass, Ilya acknowledging Tomas and closed crypt end-wall gaps. Existing schema-2/3 saves migrate on load; the next manual save uses schema 4. Automated tests use separate saves, settings and report folders.
