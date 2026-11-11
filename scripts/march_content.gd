extends RefCounted

const HEIGHTS := {"nera":1.88,"lucan":1.92,"ysabet":1.84,"garran":2.0,"corvin":2.35,"anselm":1.45}
const NPCS := {
	"nera":{"name":"Nera","role":"Physician / Saint Mere refuge","cell":7,"pos":Vector2(-66,-523)},
	"lucan":{"name":"Lucan","role":"Ferryman / Reedwater Landing","cell":6,"pos":Vector2(136,-599)},
	"ysabet":{"name":"Ysabet","role":"Orchard keeper / Bellwether ashes","cell":3,"pos":Vector2(-183,-616)},
	"garran":{"name":"Garran","role":"Deserter / Gallows Cut","cell":1,"pos":Vector2(-155,-795)},
	"corvin":{"name":"Magistrate Corvin","role":"Steward / Veyr Counting House","cell":4,"pos":Vector2(177,-745)},
	"anselm":{"name":"Father Anselm","role":"Road priest / Saint Mary's Hospice","cell":5,"pos":Vector2(-8,-925)}
}
const SITES := {
	"ash_bridge":{"name":"Saint Avel's Bridge","pos":Vector2(0,-435),"sub":"The gate closed before the bell rang"},
	"ash_refuge":{"name":"Saint Mere Refuge","pos":Vector2(-65,-530),"sub":"A place for those the road left behind"},
	"ash_orchard":{"name":"Bellwether Orchard","pos":Vector2(-190,-630),"sub":"What the fire could not consume"},
	"ash_ferry":{"name":"Reedwater Landing","pos":Vector2(140,-600),"sub":"Two shores, and a letter between them"},
	"ash_manor":{"name":"Veyr Counting House","pos":Vector2(175,-760),"sub":"Every life entered in the wrong column"},
	"ash_quarry":{"name":"Gallows Cut","pos":Vector2(-155,-805),"sub":"A soldier who cannot obey another order"},
	"ash_hospice":{"name":"Saint Mary's Hospice","pos":Vector2(0,-945),"sub":"Let the living speak the names"}
}
const ROADS := [
	[Vector2(8,-330),Vector2(24,-352),Vector2(20,-380),Vector2(-10,-410),Vector2(0,-422),Vector2(0,-448),Vector2(-12,-465),Vector2(-20,-480),Vector2(-65,-530),Vector2(-40,-585),Vector2(-55,-650),Vector2(-5,-700),Vector2(20,-755),Vector2(0,-825),Vector2(0,-925)],
	[Vector2(-65,-530),Vector2(-65,-520),Vector2(-90,-526),Vector2(-110,-550),Vector2(-160,-585),Vector2(-190,-630)],
	[Vector2(-65,-530),Vector2(-60,-555),Vector2(-5,-555),Vector2(70,-570),Vector2(112,-582),Vector2(138,-582),Vector2(140,-600)],
	[Vector2(140,-600),Vector2(135,-628),Vector2(160,-655),Vector2(130,-710),Vector2(177,-745)],
	[Vector2(-190,-630),Vector2(-215,-690),Vector2(-180,-745),Vector2(-155,-805)],
	[Vector2(-155,-805),Vector2(-110,-850),Vector2(-60,-905),Vector2(0,-925)],
	[Vector2(177,-745),Vector2(177,-736),Vector2(155,-736),Vector2(155,-785),Vector2(145,-810),Vector2(125,-865),Vector2(65,-905),Vector2(0,-925)]
]
const OBJECTS := {
	"cache_refuge_1":{"name":"Refuge travel chest","kind":"cache","pos":Vector2(-48,-524),"cell":6,"loot":{"wood":2,"bread":1}},
	"cache_refuge_2":{"name":"Refuge medicine chest","kind":"cache","pos":Vector2(-88,-524),"cell":6,"loot":{"tonic":1,"gold":3}},
	"cache_refuge_3":{"name":"Refuge tool chest","kind":"cache","pos":Vector2(-87,-527),"cell":6,"loot":{"scrap":2}},
	"cache_veyr_1":{"name":"Veyr provision chest","kind":"cache","pos":Vector2(193,-768),"cell":6,"loot":{"bread":2,"gold":4}},
	"cache_veyr_2":{"name":"Veyr supply chest","kind":"cache","pos":Vector2(199,-772),"cell":6,"loot":{"tonic":1,"wood":1}},
	"cache_veyr_3":{"name":"Veyr records chest","kind":"cache","pos":Vector2(171,-766),"cell":6,"loot":{"scrap":1,"gold":5}},
	"ash_coach":{"name":"Adela's trade-route post","kind":"story","pos":Vector2(15,-334),"cell":7},
	"ash_orders":{"name":"Charred quarantine orders","kind":"story","pos":Vector2(-7,-448),"cell":6},
	"ash_locket":{"name":"A name among the ashes","kind":"story","pos":Vector2(-215,-650),"cell":7},
	"ash_letter":{"name":"Mateo's oilskin letter","kind":"story","pos":Vector2(145,-648),"cell":6},
	"ash_bandages":{"name":"Hospice bandage chest","kind":"story","pos":Vector2(-185,-810),"cell":6},
	"ash_salve":{"name":"Ferry surgeon's salve","kind":"story","pos":Vector2(155,-639),"cell":6},
	"ash_alcohol":{"name":"Reserved medicinal spirits","kind":"story","pos":Vector2(194,-775),"cell":6},
	"ash_ledger":{"name":"The steward's private ledger","kind":"story","pos":Vector2(170,-763),"cell":6},
	"ash_roll":{"name":"The hospice burial roll","kind":"story","pos":Vector2(0,-952),"cell":6},
	"ash_rope":{"name":"A sound length of ferry rope","kind":"story","pos":Vector2(45,-555),"cell":6},
	"ash_winch":{"name":"The broken ferry winch","kind":"story","pos":Vector2(140,-593),"cell":7},
	"ash_raisa":{"name":"Raisa's sickbed","kind":"story","pos":Vector2(-80,-540),"cell":7,"interaction_height":1.2},
	"ash_pavel":{"name":"Pavel's sickbed","kind":"story","pos":Vector2(-73,-540),"cell":7,"interaction_height":1.2},
	"ash_memorial":{"name":"An empty memorial stone","kind":"story","pos":Vector2(-196,-620),"cell":7},
	"ash_candle_bridge":{"name":"Tend Saint Avel's bridge votive","kind":"story","pos":Vector2(8,-439),"cell":7,"interaction_height":1.05},
	"ash_candle_orchard":{"name":"Tend the orchard shrine","kind":"story","pos":Vector2(-200,-632),"cell":7,"interaction_height":1.05},
	"ash_bell":{"name":"The hospice bell","kind":"story","pos":Vector2(0,-942),"cell":7,"interaction_height":3.9},
	"ash_names_mateo":{"name":"The nameless ferry tablet","kind":"story","pos":Vector2(-6,-937),"cell":7,"interaction_height":1.15},
	"ash_names_elias":{"name":"The nameless orchard tablet","kind":"story","pos":Vector2(6,-937),"cell":7,"interaction_height":1.15},
	"ash_names_alina":{"name":"The nameless guard tablet","kind":"story","pos":Vector2(-10,-931),"cell":7,"interaction_height":1.15}
}
const ENCOUNTERS := [
	["ash_road_1","wolf",Vector2(-10,-478)], ["ash_road_2","wolf",Vector2(-25,-482)],
	["ash_orchard_1","wraith",Vector2(-207,-646)], ["ash_orchard_2","wraith",Vector2(-223,-652)],
	["ash_ferry_1","wolf",Vector2(100,-577)], ["ash_ferry_2","bandit",Vector2(144,-639)],
	["ash_ferry_3","bandit",Vector2(160,-646)], ["ash_rope_guard","wolf",Vector2(43,-556)],
	["ash_west_1","wolf",Vector2(-207,-687)], ["ash_west_2","bandit",Vector2(-183,-741)],
	["ash_quarry_1","bandit",Vector2(-180,-809)], ["ash_quarry_2","bandit",Vector2(-189,-817)],
	["ash_quarry_3","wolf",Vector2(-171,-825)],
	["ash_east_1","wolf",Vector2(155,-679)], ["ash_east_2","bandit",Vector2(130,-711)],
	["ash_manor_1","bandit",Vector2(192,-775)], ["ash_manor_2","bandit",Vector2(202,-780)],
	["ash_manor_3","bandit",Vector2(170,-769)],
	["ash_hospice_road_1","wraith",Vector2(-71,-890)], ["ash_hospice_road_2","wraith",Vector2(100,-888)],
	["ash_hospice_1","wraith",Vector2(-7,-956)], ["ash_hospice_2","wraith",Vector2(10,-956)],
	["ash_hospice_3","wraith",Vector2(0,-970)], ["ash_mid_1","wolf",Vector2(1,-703)],
	["ash_mid_2","wraith",Vector2(13,-839)], ["ash_mid_3","wolf",Vector2(-40,-637)]
]
const ENEMY_TYPES := {
	"mournkeeper":{"name":"The Unburied / keeper of unnamed dead","cell":3,"hp":320.0,"damage":23.0,"speed":1.6,"reach":3.4,"windup":1.4,"recovery":2.1,"height":3.8,"xp":110}
}
const TRACKS := ["The Names We Carry","The Last Dose","A Name for the Ashes","Letters Below the Water","Two Shores","A Soldier's Account","What Remains of Faith"]
