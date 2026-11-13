# Roadkeeper playtest / 0.17.0

This pass concentrates on protecting the existing adventure and making its side stories easier to follow. Downloadable builds are under `dist/TheLastRoads-0.17.0-Windows`.

## Save safety

The game now keeps three rotating automatic checkpoints, separate from the existing F5 manual save. Quest progress, dialogue decisions and discoveries request a checkpoint; a periodic checkpoint is also requested after two active minutes. Saving waits until the traveller is grounded, out of nearby danger, no longer attacking or reloading, and outside menus/reports. The lower-left HUD briefly confirms a successful automatic save. A failure is shown and retried later.

**Continue journey** and **Load latest checkpoint** in the pause menu choose the newest valid manual/automatic save. **F9** retains its manual-save meaning, with recovery if that file is missing or damaged. Existing manual saves are never overwritten by an automatic checkpoint. Each committed slot is validated after JSON serialization and writing, retains a verified previous copy, and does not replace a healthy backup with a damaged primary. Recovery reads leave the original damaged files untouched.

Solo checkpoints live beside `saves/hollow-valley.json` as `hollow-valley-auto-1.json` through `-3.json`. Co-op host and visitor files retain separate names and directories. Preview and automated test files remain isolated under `reports/`. Keep the whole saves folder when upgrading.

## Quest guidance

Every discovered, unfinished woodland side story can now be selected in J/M before the beacon is restored. Alternatively, use **Track this story** in its conversation. The HUD and compass track the nearer missing trace, the map shows both traces, and read traces turn green. Finding them in either order remains valid. Once both are found, the return marker uses the NPC's current world position, including Ilya and Tomas after relocation. Adela's story points to the unfinished beacon expedition until she can actually arrive.

**Show objective** selects the correct regional map sheet. Side-story tracking persists through saving, switches cleanly back to chapter tracks, and clears after completion. Unknown side stories are absent from the selector; completed ones remain in the journal history. A tracked outside quest directs the traveller to the underchapel exit first. The level-up banner is now below the aiming reticle.

## Verification

`--safety-check` covers slot rotation, byte-for-byte manual-save preservation, verified overwrite/backup behavior, damaged-save recovery, newest Continue, manual F9 semantics, rejected payloads, safe deferral and co-op namespace separation. `--journal-check` covers discovered-only selection, both clue orders, moved contacts, pre-beacon Adela, chapter switching, completion cleanup, crypt navigation and save migration. Rendered captures are `reports/35-save-recovery-menu.png` and `reports/35-track-side-story.png`. Existing controls, levels, co-op, chapter III, side-story, journey and gameplay smoke checks are included in standalone packaging.

---

# Visible progression / 0.16.1

A dedicated eight-second **LEVEL UP / LEVEL N** banner announces the existing automatic profession benefit. It remains separate from quest and exploration toasts, queues multiple levels, and waits while dialogue, pause or reporting obscures the world. The HUD now says **Level** and shows XP remaining until the next level. No upgrade-selection dialog has been added.

Fresh-character XP thresholds are 0, 250, 1,000, 2,400 and 4,000. The reward-budget targets are level 2 around 10?15 minutes, level 3 around 30 minutes and level 4 around one hour. Actual times depend on route, reading and combat; idling never grants XP. Level-up events record the current elapsed gameplay time for future pacing review.

Older saves retain their exact XP, previously earned levels, unlocked profession benefits and equipped advanced spells. A versioned minimum earned level prevents the pacing change from downgrading those travellers. Loading never repeats previously earned level messages. New saves use the new thresholds immediately.

`--level-check` verifies threshold boundaries, message visibility/independence, pause/dialog deferral, multiple gains, the HUD, all four professions' legacy levels and advanced spells, and an actual JSON save/load. `reports/34-level-up.png` is the rendered check. Windows packaging is `dist/TheLastRoads-0.16.1-Windows`.

---

# Current playtest / Rowan March 0.16.0

The game now has three connected chapters and nine new woodland side stories. The full-game pacing target is about two hours with exploration and reading. The third chapter targets roughly 35?50 minutes; the automated road traversal is about nine minutes of walking simulation and does not establish human playtime.

Run `launch.cmd` to continue normally. After the hospice bell is freed in Chapter II, follow the northern road to Hester in Alderwake. Nera and Anselm also offer a **Rowan March case** button. `Test-Chapter-Three.cmd` starts an equipped rank-five traveller at Alderwake's approach and isolates saves/preferences under test files in `reports/`.

The new Windows build and ZIP are under `dist/TheLastRoads-0.16.0-Windows`. Replace only the executable when upgrading an existing install; retain `saves/`, `settings.cfg` and `controls.cfg`.

## Chapter III / spoiler-free route

- Explore east toward Blackwater Sluice and the White Kiln, or west toward Rowan Sanctuary and the Burned Assize. Neither branch must be first.
- Collect physical records, hear Sella's adult account, and compare cause, access and motive at Hester's board. Wrong deductions remain revisable.
- Find the prisoner records at the eastern cellars. Negotiate with Vey at the Root Court or defeat the collectors. Open the side vent before the release.
- Decide the murderer's disposition at Alderwake. This decision is independent of the woodland pact.
- For an accord, read the sanctuary's refusal rules and obtain Sella's and Ada's own support after the rescue. For severance, face the collector and open all three binding knots. A darker inheritance is also possible.
- Bring the final account to Hester. Returning Nell's toy boat, remembering Enna, and finding winter reserves remain optional.

Use six Chapter III tracks in J/M and cycle all three map sheets. Three northern travel stops join the existing network after a first visit on foot. Hester provides safe free recovery; eight supply chests support all professions. Evidence and outcomes persist through death and saving. Existing saves without chapter data migrate to an unstarted investigation.

## Current validation

`--woods-check` covers all nine combinations of endings, both clue orders, early/unsupported accusations, normal focus/E access to every new NPC and quest object, peaceful and combat rescue, vent ordering, genuine boss shielding, repeated reward protection, old-save migration, chapter-state validation, three map sheets, travel pages and shared-world synchronization. `--woods-route` physically walks every northern road. `--woods-capture` renders the eight landmarks, Hester and Nell, and the third map sheet.

The child checks cover both Pip and Nell with adult invitations enabled: absent personal choices, rejected direct personal actions, rejected direct private entry, no private portrait or world pose even if a minor is forcibly set as the active partner. Nell's testimony is unnecessary for every deduction and every ending. Children remain in safe settlements and never become ritual offerings or intimacy candidates.

The broader checks cover side quests, adult relationship routes, terrain/level building pads, road geometry, grass clearings, co-op protocol, inventory, professions, original chapter access and save/load. The standalone Windows build is tested separately from source and audited to exclude source photos, developer saves, preferences and generation metadata.

## Cast artwork provenance

Built-in image generation produced `assets/rowan/cast-atlas.png`; no photographic references were used. The final asset is a transparent 4-by-2 atlas of seven adults and Nell, twelve. Each character is isolated by its atlas cell and rendered at an authored physical height. The prompt specified painterly Old Masters lighting, muted northern early-modern clothing, full-body silhouettes, transparent margins, fully clothed figures, and no text or scenery. The named subjects and ages were Hester 48, Bran 41, Maelin 63, Sella 34, Vey 52, Edric 57, Ada 30, Nell 12. Nell was explicitly specified as an unmistakable, non-sexualized preadolescent in a loose patched wool dress, boots and knitted hat, holding a toy boat. The same generated atlas supplies world figures and ordinary dialogue portraits; there are no private variants for this cast.

---

## Historical playtest notes

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


## Woodland side stories

Talk to contacts and select **Off the road**, or discover either clue in the woods before meeting the contact. No main-story flags are required for evidence collection. Find both traces in either order, then return to the contact to choose an ending. The journal records directions, coordinates and progress. Revisiting clues and finished stories must never duplicate loot or experience.

| Story | Contact | Theme |
| --- | --- | --- |
| Names Under the Charcoal | Sister Elian | Exploited workers and public remembrance |
| The Price of Winter | Rook | Restitution after desperate theft |
| A Measured Mercy | Vesna | End-of-life care, grief and medical privacy |
| The Captain of Both Boots | Osric | A quartermaster's absurd missing boots |
| A Bell for the Living | Mara | Institutional neglect and accountability |
| Where the Ribbon Went | Pip; also introduced by Mara | Loss, honest answers and family support |
| An Oath in the Moss | Ilya | Medical neutrality and protecting deserters |
| The Saint of Stolen Spoons | Tomas | A magpie's accidental religious career |
| What Was Never Yours | Adela | Coerced marriage, autonomy and refuge |

Clues yield bog amber, sealed mineral salts or silver snare wire once each. Adela buys each for 12 coins; completion also gives experience and 8 coins. Existing saves without these inventory entries remain valid.

Pip is eleven, remains at Wayfarer's Rest, and uses a separate fully clothed child illustration. Pip is excluded from the adult relationship allowlist. Verify no personal options, private portraits, private scenes or appearance changes occur, even when attempting direct personal action dispatch.

Automated coverage: `tools\godot\Godot_v4.5.1-stable_win64_console.exe --headless --path . -- --side-quest-check`. Covers interaction access to all 18 clues, both clue orders, all 18 endings, save migration, duplicate rewards, trade and child relationship rejection. The existing `--romance-check` requires a rendering display for its screenshots.
