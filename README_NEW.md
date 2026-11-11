# The Last Roads

**Playable build: Friends update (0.14.2).** Run `launch.cmd` for two connected single-player chapters. New Windows ZIP defaults to fullscreen, Copper & Pine, Fine pixels, 50% dithering and 30% grain. Dense grass coverage is on by default, with clearings around mushrooms, berries and firewood; switch it off in Settings > World & effects for the lighter cover. Quest access fixes restore shrine/bed/tablet/bell prompts, clarify selected and completed quests, and expose Nera's friendship conversation. Previous March fixes correct bridge footsteps, doorstep overlap, road junction gaps and floating crosses; remove patient decals; and keep Nera's aftermath available after completion. Earlier field fixes hide harvested bushes, ground NPC boots above roads and give tree-0 a gentler trunk. Includes Renaissance-inspired arched buildings, weathered limewash and brick, dark timber, brocade textiles, carved furniture, location-specific interiors and a straighter autumn oak. Friend-based Ilya and Adela artwork and portraits are restored by direct user authorization on 2026-11-10. The 0.14.2 Windows build includes all current ranger, firearm, ammunition and smoke updates. Pistol and musket use the new supplied shot recordings and shared flintlock reload; the dagger uses sword recordings. Ilya, Captain Rook, Lucan and Garran now also sell both cartridge types. The 0.14.2 EXE embeds all game data and sounds and reads footsteps directly from sounds/. Update by replacing TheLastRoads.exe in the existing game folder; keep saves/ and settings.cfg. Includes a standalone Windows playtest ZIP; 91 supplied sound recordings, shared NPC greetings and contextual ambience; separate saved Music and Sounds volume sliders in Settings; prominent spell trails, impacts and Rebuke waves, no engine splash; distinct Cleric staff/miracles and Mage wand/projectile combat, safe-rest spell preparation; contextual music and three one-bit monitor looks; rolling Perlin terrain with protected flat sites, denser grass, repaired road bends, searchable chests, clearer merchant transactions and consistent retro artwork across menus and inventory. Current production status, controls and verification are consolidated in [game_production.md](game_production.md). `README_NEW.md` remains the broader design baseline.

## Agent-first cooperative RPG — Game Design Document

**Version:** 2.1 — 8 November 2026  
**Status:** Revised setting and character baseline; existing playable-build status retained above  
**Platform:** Windows / Steam first; preserve the option of a later Xbox port  
**Players:** 1–4; social experience designed primarily for 3–4 friends  
**Initial engine:** Godot, with an exact stable version pinned at project creation  
**Initial presentation:** First-person stylised 3D  
**Required alternative:** First-person retro presentation using directional 2D pixel-art sprites inside the same navigable 3D world

This document replaces the scope and production assumptions of version 1. It adopts the revised expedition-based concept and makes migration to a retro sprite presentation an architectural requirement. Numeric budgets are prototype targets, not established balance. Implementation proposals and deferred features are identified explicitly. Version 2.1 incorporates the supplied Bells of the Hollow README and establishes Christianity, the Old Faith, and the playable peoples below. These are design requirements, not claims that new content has already been implemented. Preserve working prototype features while applying this revision incrementally.

## 1. Product vision

The Last Roads is a cooperative fantasy RPG set in a strange alternative late-Renaissance and early-Baroque world where Christianity is part of everyday life, older powers linger beyond the roads, and demonic night threatens isolated settlements. Players gather rumours in a roadside inn, prepare an expedition, recover treasure, survive after dark and bring abandoned roads back into use.

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

The tone is approximately 60 percent adventurous and 40 percent frightening, with horror concentrated at night. Retain the emerging prototype identity: late Renaissance shading into early Baroque, Spanish-inspired dress and devotional imagery, strange ruins, and a sense of sacred places surviving amid danger. Elden Ring is a reference for awe, mystery and threatening landscapes, not a requirement for its combat, lore or production scale.

Northern European woods, marshes and roadside settlements remain the geographical foundation. Spanish-inspired doublets, dark cloaks, stiff collars, broad hats, breastplates, rapiers, pistols and muskets define the inhabited world's silhouette. This is a deliberate alternative world, not a reconstruction of historical Spain. Folkloric influences may remain where they fit the Old Faith.

Mature themes include politics, violence and moral uncertainty. The prototype uses dialogue and consequences rather than elaborate cinematic scenes. Explicit intimate scenes and a nudity system are outside the production baseline. Sexual violence must not be depicted or available as a player action.

### 2.1 Christianity as lived religion

Christianity is the principal public religion and the game's explicit religious vocabulary. Use God, Jesus Christ, the Holy Spirit, the Virgin Mary and the saints by those names. Crosses, crucifixes, roadside chapels, church bells, candles, devotional images, prayers and Christian burial belong naturally in settlements and on journeys. Do not replace them with a renamed fantasy sun cult or introduce selectable competing gods.

The visual and devotional register is Catholic-inspired. Mary and the saints are venerated and invoked for intercession; they are not additional deities or rival sources of elemental powers. A chapel dedicated to a saint remains part of the same faith. No patron-deity selector, deity reputation system or pantheon-based respawn restriction is present.

Faith is expressed through ordinary conduct: blessings at departure, prayers for the missing, a candle kept for a sick child, a merchant giving thanks, a soldier making the sign of the cross. Characters differ in devotion, doubt, education and temperament. Avoid giving every speaker the same religious catchphrase or turning each conversation into a sermon.

The Church is a human institution within this world. It can contain courageous carers, frightened officials, ambitious dignitaries and corrupt individuals. Criticism of an individual or institution does not reveal that Christianity itself secretly serves the Abyss. Believers can be mistaken about a particular person, custom or supernatural occurrence.

### 2.2 The Old Faith

The Old Faith is a loose name for obscure inherited customs, obligations and encounters with old powers. It has no fully enumerated selectable pantheon. Its practitioners do not all share a single doctrine or organisation. Players discover fragments through places, consequences and conflicting testimony.

Old wells, boundary stones, burial groves, roots beneath ruined foundations and forgotten agreements may protect, demand payment, mislead or harm. Their powers are not automatically demons, Christian miracles, or benevolent nature guardians. Preserve genuine uncertainty about their ultimate nature while making individual actions and consequences understandable.

Some customs help people survive; some are dangerous; some are empty habit. A village may attend church and quietly keep an older promise at a spring. A priest may tolerate a harmless custom, condemn a cruel one, or misinterpret something unfamiliar. An Old Faith keeper may be generous in one matter and merciless in another.

Do not make all Old Faith encounters a disguised demonic trap. Equally, do not reveal that all old customs are morally superior to Christianity. Their ambiguity is a recurring source of discovery and choice.

### 2.3 The Abyss and moral clarity

Demons and hostile Abyssal spirits are genuinely evil and opposed to God and Christianity. They seek corruption, cruelty, desecration and the destruction of human and nonhuman communities. Their claims to innocence may be manipulations; the game must not ultimately recast the Abyss as a misunderstood liberation movement.

Separate moral identity from appearance and accusation. A mortal accused of possession may be innocent. A corpse animated by an evil force does not make its deceased owner evil. A feared Old Faith presence need not belong to the Abyss. Use distinct content classifications for demonic entities, hostile hauntings, animated dead, Old Faith presences and ordinary people.

Hostile ghosts and night apparitions in the enemy roster belong to the evil threat. Do not use the vague label “spirit” to silently collapse all supernatural encounters into that roster. Christian protection and exorcism counter defined Abyssal targets, not every unfamiliar creature or non-Christian person.

The moral question is often whom to trust, how to rescue someone, or what price to accept. It need not be whether an actual demon is secretly good.

### 2.4 Alternative-world conventions

Christianity is real within the fiction; the setting's invented institutions and magic are not presented as historical or doctrinal claims about real Christianity. Preserve the existing female cleric/priestess and her visible cross. Women may hold this fictional Church's adventuring clerical office. The profession remains `cleric` in gameplay data.

Humans, dwarves, elves and ogres are persons who can share Christian communities and religious vocations. No ancestry is spiritually impure, excluded from salvation, inherently demonic or automatically a follower of the Old Faith. Individual affiliation is a narrative characteristic, not an ancestry lock.

Detailed Church hierarchy, real-world geography and denomination history are not prerequisites for the prototype. Do not introduce inquisitions, historical wars or a complete alternate history merely to explain the art direction.

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

Roadside Christian chapels and their bells can serve as visible anchors of restored safety. A chapel is not automatically protected merely because it contains a cross: its operational sanctuary state is explicit. Closing rifts may involve a Christian rite and a consumed resource, but must remain possible for parties without a cleric through an authored item or NPC service. Exact resource and rite design remain deferred. Old Faith sites do not automatically function as interchangeable Christian respawn checkpoints.

Exact campaign length is uncommitted. Validate the first progression stage before extrapolating to eight bosses.

## 6. Characters and advancement

### 6.1 Professions

Begin with one playable warrior in the technical slice. The expedition prototype adds mage and cleric. The November source extension adds Ranger as a fourth fixed profession, available to every origin and gender. Rogue, bard and druid remain later expansion options.

The Ranger is a road scout with strong single-shot firearms and a weak utility dagger, rather than a spellcaster. C selects a pistol, V a musket, Q the dagger; LMB attacks. The pistol deals 80 damage and reloads in four seconds; the musket deals 130 and reloads in six. R explicitly starts a two-handed reload, slows movement, stows carried lights and displays loading, ramming and priming stages. Switching weapons cancels the reload without granting a loaded shot. A saved journey preserves loaded barrels, inventory cartridges and remaining reload time. RMB with free hands steadies aim. The weak dagger provides a fallback when there is no time or ammunition to reload.

Ranger starts with both firearms loaded and two visible ammunition stacks: 10 pistol cartridges and 5 musket cartridges, including loaded ammunition. Each is a paper package of black powder and a lead ball. The pistol uses its smaller charge for 80 damage; the musket uses its heavier charge for 130. Firing consumes exactly one matching cartridge, hit or miss; reload/cancel consume none. Mara, Osric and Adela sell twelve pistol cartridges or six musket cartridges for six coins, with capacity 122 per type. Existing shared ammunition migrates once in a 2:1 pistol/musket split without losing rounds. Inventory and shortcut icons show P/M badges. Rest does not generate ammunition or reload firearms. Progression adds firearm damage at rank two, faster handling at rank three, improved dagger damage at rank four and a patient aimed shot at rank five. These values are prototype balance, pending human solo playtests.

Professions are fixed development paths. A warrior does not become a mage. Characters begin as novices with a small equipment and ability set. Incompatible equipment may impose clearly displayed penalties; the prototype only exposes combinations with defined behaviour.

The intended roster has six player-facing origins: three human peoples, dwarf, elf and ogre. Implement the human options with a shared humanoid body family first; extreme body proportions and their equipment compatibility may follow. Cosmetic variation comes from head, complexion, hair, clothing and accessories. Do not remove any already working character options merely to reproduce an earlier milestone.

### 6.2 Progression

Earn EXP and spend it on profession abilities, attributes and upgrades. Level depends on lifetime EXP earned; spending EXP cannot reduce level. Rare masters may award an improvement through a quest.

Crafting investment competes with combat investment. Begin with a small set of meaningful upgrades rather than large trees of percentage bonuses. Equal participating party members receive equal EXP rewards; exact distance and participation boundaries must be specified before implementation.

Character data and world progression remain separate. However, unrestricted character transfer between worlds is deferred until save reconciliation is implemented and tested. Separation of data must not be mistaken for a completed transfer feature.

### 6.3 Playable peoples and character creation

Use **Origin** as the player-facing category. Internally separate `species_id`, `heritage_id`, appearance and profession. The following are fictional setting names, not renamed real-world nations. Descriptions of human appearance are art direction, not ability or personality rules.

| Origin | Species / heritage ID | Appearance direction | Setting and material-culture direction |
|---|---|---|---|
| **Valdren** | `human` / `valdren` | White / European-inspired human appearances, from fair to olive complexions; varied hair and facial features | Western and northern road provinces; wool, dark doublets, linen collars and weathered travelling cloaks |
| **Shenari** | `human` / `shenari` | East Asian-inspired human appearances, with varied faces and complexions | Eastern river cities and upland towns; restrained embroidery, layered collars and woven travel sashes adapted to local coats and armour |
| **Nambari** | `human` / `nambari` | Black / sub-Saharan African-inspired human appearances; varied dark skin tones, faces and hair textures | Southern lake and plateau realms; patterned woven panels, brass fasteners and practical layered travel clothing |
| **Dwarf** | `dwarf` / unset initially | Short, broad, recognisably nonhuman proportions; varied complexions and facial hair | Multiple communities, including town dwellers and travellers; craft traditions are cultural possibilities, not compulsory jobs |
| **Elf** | `elf` / unset initially | Slender silhouettes and pointed ears; varied complexions and features | Both urban and woodland communities; neither Old Faith affiliation nor magical profession is automatic |
| **Ogre** | `ogre` / unset initially | Large, heavy, clearly distinct silhouette; expressive faces | Full members of society who may be soldiers, scholars, clergy or craftspeople; size does not imply stupidity or cruelty |

Valdren, Shenari and Nambari are three human peoples, not an exhaustive classification of humanity. A character's birthplace, upbringing and clothing need not match their ancestry. Shared local fashion keeps a diverse party visually coherent. The Spanish-inspired regional style can be worn by every origin.

All professions are available to every origin, including Christian clerics. Human origins use the same base mechanical capabilities. If background bonuses are introduced, attach them to chosen upbringing or training rather than skin colour. Nonhuman physical traits may later support modest gameplay distinctions, but exact bonuses and balance remain uncommitted.

Character creation must not offer different gods. Faith and personal convictions may be optional narrative background, without a hidden morality score or mandatory faction choice. Do not add background systems to the first playable solely to populate this screen.

### 6.4 Names and everyday identity

Naming suggestions are production seeds, not mandatory naming rules: Valdren — Alven, Isera, Marel; Shenari — Shuren, Meilin, Renai; Nambari — Ndera, Amari, Kalemi. These proposed fictional personal names are not assertions of linguistic authenticity or uniqueness. Settled families may use local names regardless of origin.

Write each important NPC as an individual with a trade, need, relationship and belief. Do not derive honesty, intelligence, aggression, accent or religiosity from their appearance. A Nambari priest, a Shenari innkeeper, a Valdren hedge practitioner and a dwarven Christian pilgrim all fit the setting without special explanation.

## 7. Combat and magic

Combat is real-time, first-person and direct. The initial weapon supports an attack and a block. Enemies visibly telegraph attacks and react to damage. Hit sound, impact reaction and timing are acceptance criteria, not late polish.

Stamina supports sprinting and jumping. Ordinary attacks and blocks do not initially consume stamina. Mana regenerates more slowly and pays for spells. Friendly fire is disabled.

The current source includes shields, the Ranger's pistol and musket, and a weak dagger. Bows, crossbows and additional two-handed melee families remain later options. Firearms are slow and powerful, with carried ammunition. Each new family requires a distinct gameplay purpose and presentation validation in both visual profiles.

A held lantern or torch occupies the left hand and disables shield use and left-hand spells/rites. Switching lights stows the previous one. A held torch can strike with RMB: it is weaker than a sword against living creatures but stronger against spirits. Stowing the light restores offhand actions. A musket and all firearm reloads require both hands. G provides safe rest independently of R, which is reserved for Ranger reloads. Inventory shortcuts are references: select any supply and press 1–8, or retain the existing click/drag assignment. Materials open their inventory detail instead of being consumed.

Wilderness warning timbers are ordinary environmental clues, not magical columns or quest keys. Pitch marks warn of Pitchbound; high pale claw marks warn of Boughstalkers. Their bark, broken tops and passive look-at descriptions should communicate their purpose without an interaction button.

### 7.1 Common effect vocabulary

Build abilities from a bounded set of effects: damage, heal, protect, illuminate, apply status and knock back. Effects have explicit ranges, durations, target rules and stacking policies. A content definition may combine supported effects; it must not inject arbitrary executable behaviour.

Spells are learned from books or scrolls subject to level requirements. Prepared slots change during valid rest. Magical professions share mana and preparation rules but have different spell lists. The prototype needs only a small offensive and healing set.

Food and potions take effect immediately. Repeated potion consumption remains allowed; balance through supply and inventory constraints rather than adding an undocumented cooldown.

### 7.2 Difficulty

Each area has a baseline danger. Party-size scaling must preserve that identity. Power-based adjustments are bounded so advancement still makes earlier threats easier. Solo is playable but deliberately less forgiving than a coordinated group.

Avoid balancing only through inflated enemy health. Test enemy count, attack pressure and recovery opportunities while retaining readable encounters.

### 7.3 Religious and magical traditions

Keep the common effect system and existing combat timings. Distinguish the fiction and presentation of abilities:

- **Cleric:** Christian prayer, blessings and protective rites. Healing and protection express divine aid; the cross remains a recognisable devotional object. Proposed ability names include *Prayer of Mercy*, *Vigil Light* and *Ward against the Unclean*. Saints may be invoked as intercessors, not equipped as competing gods.
- **Mage:** Learned study of the world's created properties, using diagrams, books and disciplined practice. Magic is not automatically a pact with demons. A Christian mage is possible. Specific forbidden practices can be dangerous without condemning the entire profession.
- **Druid, if later implemented:** Knowledge of old places, natural processes and inherited obligations associated with the Old Faith. This is not a cleric of a second selectable pantheon. Relationships and costs are defined per authored ability or encounter.

Mana remains the shared mechanical resource. For clerics it represents finite concentration and exertion in gameplay, not a measurable quantity of God's power. Rest prepares abilities for all relevant professions. Rites, diagrams and oral instruction may complement books and scrolls as acquisition fiction, using the same underlying unlock system.

Do not introduce a simulation of prayer correctness or make real-world religious knowledge necessary to cast an ability. Decorative crosses and saint images are not automatically active magical shields. Protection comes from explicit abilities and designated sanctuary states, so the rules remain readable and testable.

## 8. Night, fire and lightweight survival

A full day lasts approximately 20–24 minutes, with a 3:1 daylight-to-night ratio. The prototype may use controlled starting times to exercise dusk reliably, but the public rules must be consistent.

Night brings evil Abyssal creatures: hostile spirits, demons and animated undead, distinct from the ambiguous presences associated with the Old Faith. Most normal inhabitants shelter. At dawn the affected creatures disappear or become inert according to their defined family behaviour.

### 8.1 Two primary survival concerns

- **Provisions:** Food supports expedition preparation and immediate recovery. Running out weakens preparedness rather than causing a separate starvation death timer.
- **Exposure:** Cold and wet conditions increase a readable exposure state. Clothing reduces buildup; fire and shelter allow recovery. Severe exposure weakens the character. Lethal extremes are deferred until the basic loop is validated.

Separate thirst, disease simulation, drunkenness and complex wound treatment are deferred. This explicitly replaces the larger survival model of version 1.

### 8.2 Fire and rest

Campfires consume wood, provide warmth and deter weaker night creatures. Ordinary fire retains this established survival function; a cleric is not required to make every camp viable. Stronger enemies may cross their protection, with a readable warning. A torch provides partial personal protection. Shelter protects against rain and improves rest.

Use an explicit safe-rest check rather than relying on how bright a rendered fire appears. All players must agree to skip to morning, and rest is blocked by nearby active threats. Exact safe radius and interrupt rules are tunable data.

Waiting around a fire must include useful activities: equipment preparation, crafting and discussion. Test whether a full night is engaging; do not assume passive waiting is inherently atmospheric.

## 9. Inventory, death and crafting

### 9.1 Inventory and rewards

Use a spatial inventory with items occupying rectangular cells. Support quick transfer, clear comparisons and optional auto-arrangement. Item footprints are gameplay data independent of icon resolution or mesh dimensions.

Loot is shared physical content. Cooperative play increases available rewards through defined tables. The host resolves pickup ownership to prevent duplicate acquisition.

### 9.2 Dying and respawn

Before death, a character enters a rescuable state. Another player can revive them using a defined consumable or ability. Solo provides an equivalent self-rescue opportunity if an eligible resource remains.

On death, retain the equipped basic loadout and drop backpack contents at the death position. Preserve EXP and skills. Respawn with full health at the area's activated Christian sanctuary; if none exists, use its designated safe entry sanctuary. These checkpoints are accessible to all origins, professions and narrative beliefs; there is no patron-deity restriction. In dialogue, return may be called a mercy whose full workings remain mysterious. Routine enemy or civilian deaths are not automatically reversible: this player-facing rule does not establish universal resurrection for the entire population. This replaces version 1's full equipment loss.

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

### 10.1 Dialogue voice

NPCs naturally refer to God, Christ, Our Lady and the saints. Use short invocations at emotionally appropriate moments: greeting, gratitude, fear, departure, grief or an oath. Vary frequency and phrasing by speaker. Everyday humour and swearing can coexist with sincere devotion.

Illustrative English lines, to be adapted to individual characters:

| Speaker / context | Example |
|---|---|
| Innkeeper at arrival | “God be praised. Come in before the bell.” |
| Worried traveller | “Our Lady keep them. They should have reached the bridge by now.” |
| Soldier preparing to leave | “Saint Michael stand with us. Check your powder.” |
| Cleric treating a wound | “Hold still. We can give thanks when the bleeding stops.” |
| Merchant relieved by a safe road | “Thanks be to God. I thought those wagons were lost.” |
| Villager discussing an old custom | “I light a candle at the chapel. I leave the first cup at the well. My mother did both.” |
| Old Faith keeper | “Pray as you please. But do not move the stone.” |
| Dwarven pilgrim | “My father carried that cross through three winters. I can carry it one more mile.” |

Do not insert an invocation into every line. Avoid modern ironic distancing that makes all believers sound embarrassed by faith. Avoid uniform pseudo-biblical speech and random decorative Latin. New prayers and saint references require editorial review for consistency; the text is fictional dialogue, not a historical quotation.

### 10.2 Quest patterns for the revised setting

These are proposed content examples, not a claim that the current build contains them.

**The silent bell:** Recover a chapel bell stolen for its metal. The thieves are desperate mortals; a demon exploiting the unprotected route is not. Return, negotiation and combat use existing objective types. The moral decision concerns people and restitution, not the demon's innocence.

**The first cup:** An old well offers clean water while a local obligation is honoured. Breaking the custom changes the supply; keeping it involves a real cost or inconvenience. Investigate before choosing. Do not automatically reveal a demon behind the well, and do not assume every church official understands its nature.

**The false accusation:** A healer is blamed for a haunting because she keeps old customs. Evidence points to an Abyssal presence elsewhere. A priest can help establish the truth. The quest distinguishes accusation, supernatural evidence and personal guilt.

**The unburied:** An evil force animates travellers' bodies. Defeat the hostile manifestations and recover the dead for burial. The victims remain victims; a violent combat encounter can lead to a compassionate resolution.

Use finite authored states and the existing investigate, retrieve, defend and restore systems. No procedural theology engine, universal belief simulation or runtime LLM is required.

## 11. Visual direction and asset production

### 11.1 Initial 3D identity

Use bold, carved silhouettes, restrained surface detail and coherent colour groups. Figures resemble painted wooden or sculpted miniatures rather than realistic people. Warm amber inns contrast with blue-green forests and dark night silhouettes. Preserve the prototype’s specific Renaissance/Baroque character rather than replacing working assets with a generic medieval kit.

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

### 11.3 Sacred, old and Abyssal visual vocabularies

| Tradition | Reusable visual vocabulary | Direction |
|---|---|---|
| Christianity | Latin crosses, crucifixes, bells, candles, small Marian images, saint panels, prayer books, roadside niches and chapel altars | Lived-in, cared for, sometimes poor or damaged; warmth, mourning, protection and human effort |
| Old Faith | Weathered stones, marked wells, knots, root-bound thresholds, modest offerings and worn boundaries | Incomplete and locally specific; neither a second church kit nor generic evil pentagrams |
| Abyss | Corruption of familiar forms, hostile apparitions, broken human silhouettes and desecrated spaces | Clearly threatening and destructive; an organised enemy vocabulary distinct from ordinary old customs |

Spanish-inspired clothing uses strong silhouettes: fitted doublets, cloaks, restrained ruffs or stiff collars, broad hats, rapier belts and breastplates. Early-Baroque character can come from a few focal objects, dramatic light and devotional composition; avoid expensive ornamental detail across every surface.

The female cleric's visible cross is retained as a defining readable feature. Offer the same Christian visual language to clerics of every origin. A cross can be a shared attachment with a suitable contrast against the costume. Human heritage variants share the same equipment and animation pipeline; no three separate human asset libraries are required.

Start with one chapel niche, one cross attachment, one small devotional panel and one old boundary stone built from existing modules. Add detail where the player approaches or interacts. Do not remove or redesign the current tree-rendering choices or colour looks as a side effect of this lore revision.

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

### 12.8 Setting identity in both visual profiles

Maintain the cross silhouette, characteristic collars and hats, and the distinction between a Christian niche and an Old Faith marker at the intended pixel scale. When a pendant becomes unreadable, simplify its shape or increase contrast within the style rather than adding gameplay-dependent texture detail.

Test skin tones, hair and facial shapes under daylight, warm firelight, night lighting and all existing colour looks. Different human origins must remain legible without making dark skin vanish into shadow or relying on caricature. Palette conversion must preserve useful value separation.

Sacred protection uses logical tags and state, never detection of cross-shaped pixels or apparent light. Both adapters consume the same ability and sanctuary state. New origins must use existing stable entity and content conventions; visual changes must not alter damage or save semantics.

### 12.9 Early migration proof

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

### 14.4 Applying this revision to Bells of the Hollow

Treat the playable-build note at the top as supplied project status; this documentation revision does not verify or change the executable. Inspect the actual project before deciding which milestone features remain missing. Preserve its launch instructions, report links, colour looks, tree options and working gameplay.

Apply the setting update in bounded steps:

1. Audit existing deity, shrine, cleric, spell, NPC and ancestry content. Replace pantheon references with the approved vocabulary; do not blindly replace every use of “spirit” or “old”.
2. Preserve the female cleric and visible cross. Update dialogue and descriptions first, using current mechanics.
3. Add shared-rig human appearance presets for Valdren, Shenari and Nambari as the creator permits. Keep species, heritage, profession and belief separate in data; do not force a schema migration merely for display labels.
4. Give Christian sanctuaries and Old Faith sites distinct content tags. Preserve current checkpoint behaviour unless a reviewed change is required.
5. If old saves contain patron IDs, map them explicitly to the universal sanctuary rule. Define how any existing patron bonuses are retained or compensated; do not silently delete progression. Use a versioned migration and backup.
6. Add one short authored Old Faith encounter and review it for genuine ambiguity. Expand only after testing its fit with the current expedition.
7. Check the updated content in the current visual mode and the retro parity fixture. Verify that relabelling does not break items, quest references or saves.

These are instructions for a later implementation pass. Updating this document alone does not complete them.

## 15. Staged playable scope

The stages below remain planning and acceptance references. The supplied README reports a playable solo build; do not restart development at Stage A or remove later features merely to follow this sequence. Evaluate the current repository against these criteria.

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
- NPC dialogue conveys Christianity as everyday belief, with varied voices and recognisable Christian names.
- No character-creation or respawn flow requires selecting a competing deity.
- Old Faith encounters retain meaningful ambiguity; hostile Abyssal entities remain genuinely evil.
- Every origin can use every profession, including cleric, without ancestry-based religious restrictions.
- The cleric's cross and key costume silhouettes remain readable in the retro fixture.
- Existing launch instructions, report references and supported visual settings survive the documentation and content update.

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
| Broad race and profession scope | Shared human body family first; six target origins; staged profession expansion |
| Character transfer assumed available | Separate data retained; transfer implementation deferred |
| Large prototype feature bundle | Technical proof, small expedition, then four-player prototype |

### 16.4 Version 2.1 decisions and remaining lore work

Established: explicit Christianity with Catholic-inspired devotion; an ambiguous Old Faith; genuinely evil Abyssal enemies; a female Christian cleric with a visible cross; Spanish-inspired late-Renaissance/early-Baroque character; Valdren, Shenari and Nambari humans plus dwarves, elves and ogres; all professions available to all origins; no selectable pantheon.

Still open: local Church offices and order names, the detailed history of each fictional people, individual Old Faith obligations, the exact explanation of player return, and final spell/item names. These should be authored only as needed for playable content. This revision does not add a religious reputation meter, compulsory conversion system or automatic stat bonuses for human heritage.

The final quality bar is a short shared adventure that players want to repeat. Asset count, generated land area and number of implemented systems are supporting measures, not substitutes for that result.
