extends RefCounted

const NPCS := {
	"hester":{"name":"Hester Vann","role":"Coroner / Alderwake","age":48,"cell":0,"pos":Vector2(-16, -1090)},
	"bran":{"name":"Constable Bran","role":"Watch commander / Alderwake","age":41,"cell":1,"pos":Vector2(21, -1100)},
	"maelin":{"name":"Maelin","role":"Keeper of the willing / Rowan Sanctuary","age":63,"cell":2,"pos":Vector2(-153, -1325)},
	"sella":{"name":"Sella","role":"Millwright / Blackwater Sluice","age":34,"cell":3,"pos":Vector2(139, -1207)},
	"vey":{"name":"Vey","role":"Oathkeeper / The Root Court","age":52,"cell":4,"pos":Vector2(32, -1635)},
	"edric":{"name":"Edric","role":"Scribe / The Burned Assize","age":57,"cell":5,"pos":Vector2(-155, -1510)},
	"ada":{"name":"Ada","role":"Prisoner's sister / Alderwake","age":30,"cell":6,"pos":Vector2(-30, -1114)},
	"nell":{"name":"Nell","role":"Child, age 12 / Alderwake","age":12,"minor":true,"cell":7,"pos":Vector2(-22, -1080)},
}

const HEIGHTS := {
	"hester":1.86,
	"bran":1.98,
	"maelin":1.78,
	"sella":1.83,
	"vey":1.97,
	"edric":1.85,
	"ada":1.84,
	"nell":1.36,
}

const SITES := {
	"nw_village":{"name":"Alderwake","pos":Vector2(0, -1100),"sub":"A death is already becoming a rumour"},
	"nw_sluice":{"name":"Blackwater Sluice","pos":Vector2(137, -1225),"sub":"Water keeps its own account of time"},
	"nw_sanctuary":{"name":"Rowan Sanctuary","pos":Vector2(-150, -1335),"sub":"An old faith, and the right to refuse"},
	"nw_kiln":{"name":"The White Kiln","pos":Vector2(165, -1400),"sub":"Iron, ash, and a debt called protection"},
	"nw_assize":{"name":"The Burned Assize","pos":Vector2(-150, -1525),"sub":"The witnesses did not burn with the records"},
	"nw_cells":{"name":"The Root Cellars","pos":Vector2(143, -1555),"sub":"Someone decided consent could wait"},
	"nw_court":{"name":"The Root Court","pos":Vector2(30, -1645),"sub":"Every promise has a creditor"},
	"nw_heart":{"name":"The Listening Oak","clearing":32,"pos":Vector2(-95, -1770),"sub":"Choose what may be asked of the living"},
}

const ROADS := [
	[Vector2(0, -990),Vector2(5, -1035),Vector2(0, -1070),Vector2(0, -1100)],
	[Vector2(0, -1100),Vector2(0, -1138),Vector2(52, -1155),Vector2(100, -1170),Vector2(125, -1202),Vector2(125, -1232),Vector2(137, -1230)],
	[Vector2(0, -1100),Vector2(0, -1138),Vector2(-60, -1180),Vector2(-115, -1230),Vector2(-150, -1290),Vector2(-150, -1340)],
	[Vector2(-150, -1340),Vector2(-182, -1400),Vector2(-165, -1460),Vector2(-150, -1520)],
	[Vector2(-150, -1520),Vector2(-128, -1520),Vector2(-115, -1560),Vector2(-85, -1585),Vector2(0, -1625),Vector2(30, -1645)],
	[Vector2(137, -1230),Vector2(165, -1290),Vector2(165, -1350),Vector2(165, -1400)],
	[Vector2(165, -1400),Vector2(140, -1460),Vector2(145, -1510),Vector2(143, -1555)],
	[Vector2(143, -1555),Vector2(125, -1550),Vector2(116, -1585),Vector2(95, -1600),Vector2(30, -1645)],
	[Vector2(30, -1645),Vector2(-25, -1700),Vector2(-95, -1740),Vector2(-95, -1770)],
	[Vector2(-150, -1340),Vector2(-65, -1375),Vector2(5, -1405),Vector2(80, -1400),Vector2(165, -1400)],
]

const OBJECTS := {
	"nw_body":{"name":"Oren's covered remains","kind":"woods","pos":Vector2(130, -1230),"cell":6,"evidence":"body"},
	"nw_bolt":{"name":"A broken watch bolt","kind":"woods","pos":Vector2(147, -1253),"cell":6,"evidence":"bolt"},
	"nw_watch":{"name":"The unaltered night-watch book","kind":"woods","pos":Vector2(21, -1110),"cell":6,"evidence":"watch"},
	"nw_letter":{"name":"Oren's undelivered inquiry","kind":"woods","pos":Vector2(-8, -1120),"cell":6,"evidence":"letter"},
	"nw_mould":{"name":"A split bolt mould","kind":"woods","pos":Vector2(173, -1410),"cell":6,"evidence":"mould"},
	"nw_ledger":{"name":"The protection ledger","kind":"woods","pos":Vector2(156, -1393),"cell":6,"evidence":"ledger"},
	"nw_rites":{"name":"The sanctuary's consent cords","kind":"woods","pos":Vector2(-156, -1340),"cell":6,"evidence":"rites"},
	"nw_review":{"name":"The old assize transcript","kind":"woods","pos":Vector2(-146, -1533),"cell":6,"evidence":"review"},
	"nw_prison":{"name":"The prisoner transfer roll","kind":"woods","pos":Vector2(152, -1552),"cell":6,"evidence":"prison"},
	"nw_knife":{"name":"Maelin's antler knife","kind":"woods","pos":Vector2(-140, -1350),"cell":6,"evidence":"knife"},
	"nw_cache_memory":{"name":"A keeper's unfinished letter","kind":"woods","pos":Vector2(-205, -1430),"cell":6,"evidence":"cache_memory"},
	"nw_cache_raid":{"name":"A raider's winter account","kind":"woods","pos":Vector2(205, -1480),"cell":6,"evidence":"cache_raid"},
	"nw_boat":{"name":"Nell's carved boat","kind":"woods","pos":Vector2(118, -1270),"cell":6,"evidence":"boat"},
	"nw_winter":{"name":"Emergency winter stores","kind":"woods","pos":Vector2(-180, -1570),"cell":6,"evidence":"winter"},
	"nw_caseboard":{"name":"Hester's investigation board","kind":"woods","pos":Vector2(-13, -1098),"cell":7},
	"nw_notice":{"name":"Alderwake appeal for witnesses","kind":"woods","pos":Vector2(7, -1015),"cell":7},
	"nw_vent":{"name":"The cellar pressure vent","kind":"woods","pos":Vector2(137, -1551),"cell":7},
	"nw_gate":{"name":"The root cellar release","kind":"woods","pos":Vector2(143, -1560),"cell":7},
	"nw_heart":{"name":"The listening heartwood","kind":"woods","pos":Vector2(-95, -1772),"cell":7},
	"nw_ward_west":{"name":"Western binding knot","kind":"woods","pos":Vector2(-108, -1765),"cell":7},
	"nw_ward_east":{"name":"Eastern binding knot","kind":"woods","pos":Vector2(-82, -1765),"cell":7},
	"nw_ward_north":{"name":"Northern binding knot","kind":"woods","pos":Vector2(-95, -1786),"cell":7},
	"nw_vigil":{"name":"The sanctuary remembrance bowl","kind":"woods","pos":Vector2(-160, -1325),"cell":7},
	"cache_nw_village":{"name":"Northern road stores / village","kind":"cache","pos":Vector2(-28, -1104),"cell":6,"loot":{"tonic":2,"bread":3,"wood":3},"lore":"Relief supplies left for travellers. Take what you can use."},
	"cache_nw_sluice":{"name":"Northern road stores / sluice","kind":"cache","pos":Vector2(151, -1207),"cell":6,"loot":{"scrap":3,"pistol_cartridge":12,"musket_cartridge":6},"lore":"Relief supplies left for travellers. Take what you can use."},
	"cache_nw_sanctuary":{"name":"Northern road stores / sanctuary","kind":"cache","pos":Vector2(-161, -1315),"cell":6,"loot":{"tonic":2,"bread":2,"graveward_resin":1},"lore":"Relief supplies left for travellers. Take what you can use."},
	"cache_nw_kiln":{"name":"Northern road stores / kiln","kind":"cache","pos":Vector2(180, -1384),"cell":6,"loot":{"scrap":3,"gold":10,"pistol_cartridge":12,"musket_cartridge":6},"lore":"Relief supplies left for travellers. Take what you can use."},
	"cache_nw_assize":{"name":"Northern road stores / assize","kind":"cache","pos":Vector2(-138, -1508),"cell":6,"loot":{"wood":3,"bread":2},"lore":"Relief supplies left for travellers. Take what you can use."},
	"cache_nw_cells":{"name":"Northern road stores / cells","kind":"cache","pos":Vector2(155, -1540),"cell":6,"loot":{"tonic":2,"bread":2},"lore":"Relief supplies left for travellers. Take what you can use."},
	"cache_nw_court":{"name":"Northern road stores / court","kind":"cache","pos":Vector2(46, -1627),"cell":6,"loot":{"wood":2,"tonic":2,"graveward_resin":1},"lore":"Relief supplies left for travellers. Take what you can use."},
	"cache_nw_oak":{"name":"Northern road stores / oak","kind":"cache","pos":Vector2(-111, -1743),"cell":6,"loot":{"tonic":2,"bread":2,"pistol_cartridge":12,"musket_cartridge":6},"lore":"Relief supplies left for travellers. Take what you can use."},
}

const ENCOUNTERS := [
	["nw_approach_1","wolf",Vector2(35, -1050)],
	["nw_approach_2","wolf",Vector2(42, -1056)],
	["nw_mill_1","bandit",Vector2(86, -1176)],
	["nw_mill_2","bandit",Vector2(94, -1182)],
	["nw_grove_1","boughstalker",Vector2(-108, -1252)],
	["nw_grove_2","wolf",Vector2(-115, -1258)],
	["nw_kiln_1","bandit",Vector2(167, -1360)],
	["nw_kiln_2","bandit",Vector2(179, -1365)],
	["nw_kiln_3","pitchbound",Vector2(192, -1424)],
	["nw_assize_1","wraith",Vector2(-183, -1467)],
	["nw_assize_2","wraith",Vector2(-175, -1475)],
	["nw_east_1","pitchbound",Vector2(165, -1490)],
	["nw_east_2","boughstalker",Vector2(177, -1500)],
	["nw_west_1","wolf",Vector2(-101, -1570)],
	["nw_west_2","wolf",Vector2(-92, -1577)],
	["nw_court_1","wraith",Vector2(74, -1615)],
	["nw_oak_road_1","pitchbound",Vector2(-25, -1725)],
	["nw_oak_road_2","boughstalker",Vector2(-36, -1729)],
	["nw_wild_west","boughstalker",Vector2(-198, -1428)],
	["nw_wild_east","pitchbound",Vector2(205, -1472)],
]

const TRACKS := [
	"The Shape of a Murder",
	"Witnesses and Contradictions",
	"The Root Cellars",
	"A Faith That Can Refuse",
	"Judgement at Alderwake",
	"The Listening Oak",
]

const EVIDENCE := {
	"body":{"title":"Hester's field examination","body":"Reeve Oren, forty-six. A narrow iron wound entered beneath the ribs before death. The antler-shaped cuts were made later: there is almost no bleeding around them. Someone arranged a woodland execution after an ordinary killing. Hester covers him again. A cruel official is still a person whose death requires an account."},
	"bolt":{"title":"Iron in the silt","body":"A bolt head lies in the drained channel. Its socket has a crescent-shaped flaw. This is a manufactured watch bolt, not an antler knife. The silt has preserved a little blue sealing wax. A wound and a weapon tell you how Oren died; neither yet names his killer."},
	"watch":{"title":"Two clocks","body":"Bran entered himself at the west road at the ninth bell. A counter-signature records him taking the only sluice key at the eighth. The west patrol's returning guard wrote that Bran never arrived. The official copy omits this last line. A key can be lent; the omission needs an explanation."},
	"letter":{"title":"What Oren meant to expose","body":"To the assize: 'I sold clearance rights and called it recovery. I knew there would be removals. I did not authorize people being delivered to the roots. Three adults entered the watch cells; no release orders exist. Summon Bran and Vey separately.' Oren planned to expose them. This does not absolve his own dispossessions."},
	"mould":{"title":"The crescent in the iron","body":"The kiln's watch mould has a chipped crescent at the socket. A sealed batch list assigns all twelve blue-waxed bolts to Bran's personal crossbow; eleven remain in his locked return box. The recovered bolt is the missing twelfth. The list bears the kiln worker's mark, not just Bran's signature."},
	"ledger":{"title":"What shelter cost","body":"Three winters ago Vey promised Bran a ring of living roots against famine raiders. At first the offerings were Bran's own memories. Later he pledged condemned adults, then people held on suspicion. Vey calls the change practical. Beside each delivery is Bran's receipt and the watch seal. The village's safety was real; so were the people used to buy it."},
	"rites":{"title":"A faith with a refusal","body":"Each cord records a spoken adult consent, a named offering and a way to withdraw before the rite. One woman exchanged the memory of her wedding for a season of clean water. Another refused and remained welcome. Maelin's rule forbids offerings by children and offerings made for another person. The Root Court has broken these rules; its existence does not make every believer its accomplice."},
	"review":{"title":"An acquittal that mattered","body":"An earlier hearing acquitted Maelin of a disappearance after a missing traveller returned. Bran swore that suspicion of the Old Faith was no crime. Edric preserved the original. The constable once believed the principle he is now using as camouflage. Oren later suppressed a complaint against his land agents."},
	"prison":{"title":"Three people, no consent","body":"Silas, Jory and Teren: adults taken from the watch cells, entered as 'willing shelter-bearers'. Beneath the copied consent is the same clerk's hand. Ada's brother Silas cannot write. All three are alive inside the root cellar. The roll provides independent evidence even if you cannot yet free them."},
	"knife":{"title":"A stolen shape","body":"Maelin's antler blade was returned secretly after the killing. Its chipped edge fits the ceremonial marks but is too broad for the fatal wound. She admits someone in her congregation stole it. Religious language supplied the disguise; a borrowed ritual tool did not make its owner the murderer."},
	"cache_memory":{"title":"What she chose to forget","body":"A former keeper writes: 'I gave away my son's first word to keep the well sweet. He is a man now and thinks I never listened. I chose the bargain. I did not know what explaining the choice would cost.' There is no commandment in the margin, only an address she cannot bring herself to use."},
	"cache_raid":{"title":"The first bargain","body":"A raider describes living roots stopping his company while the houses stayed warm. Bran did not invent the protection. The next entry lists the household food the raiders intended to take, and the two deserters they hanged for objecting. Real dangers can become a license for new cruelties."},
	"boat":{"title":"A small thing returned","body":"A toy boat is caught in the reed basket, safely above the channel. Nell watched the watch cart pass from the mill cottage. She did not see a killing. The story she can tell is a child's limited recollection, not proof of anyone's guilt."},
	"winter":{"title":"Another way to keep people alive","body":"The assize's emergency depot still holds sealed grain and dry timber. Oren claimed these stores were exhausted. The grain is sound. Ada can organize a fair count. Losing the woodland protection would be costly, but the village need not face winter empty-handed."},
}
const ENEMY_TYPES := {
	"rootwarden":{"name":"The Borrowed Heart","cell":3,"hp":410.0,"damage":26.0,"speed":1.85,"reach":3.6,"windup":1.5,"recovery":2.2,"height":3.9,"xp":130},
}
