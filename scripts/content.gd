extends RefCounted

const BUILD = "0.15.5-coop-preview"
const AMMO_SELLERS = ["mara","osric","merchant","ilya","rook","lucan","garran"]
const PLAYER_HEIGHT = 1.95
const EYE_HEIGHT = 1.62
static var NPC_HEIGHTS = {"mara":1.85,"osric":2.0,"ilya":1.90,"vesna":1.80,"rook":2.0,"sister":1.88,"courier":1.90,"merchant":1.88}
const WORLD_ID = "hollow_valley"
const SEED = 1776
const LAYOUT = "hollow-authored-2"
static var ROADS = [
	[Vector2(0,45),Vector2(0,12),Vector2(-12,-20),Vector2(0,-55),Vector2(8,-92),Vector2(0,-120),Vector2(15,-162),Vector2(8,-202),Vector2(24,-245),Vector2(0,-285),Vector2(0,-340)],
	[Vector2(0,-120),Vector2(-35,-130),Vector2(-75,-145),Vector2(-115,-160)],
	[Vector2(15,-162),Vector2(55,-165),Vector2(95,-183),Vector2(130,-200)],
	[Vector2(-115,-160),Vector2(-125,-195),Vector2(-115,-240),Vector2(-115,-260),Vector2(-90,-270),Vector2(-30,-270),Vector2(0,-285)],
	[Vector2(130,-200),Vector2(125,-245),Vector2(88,-280),Vector2(24,-300),Vector2(0,-340)],
	[Vector2(-12,-20),Vector2(-54,-38),Vector2(-80,-65)],
	[Vector2(88,-280),Vector2(130,-300),Vector2(160,-310)]
]
static var SITES = {
	"inn":{"name":"Wayfarer's Rest","pos":Vector2(0,30),"sub":"A little warmth at the edge of the world"},
	"grove":{"name":"The Foxglove Grove","pos":Vector2(-80,-65),"sub":"Where the quiet things grow"},
	"gate":{"name":"The Fallen Toll","pos":Vector2(8,-92),"sub":"Not every thief is a monster"},
	"mill":{"name":"The Widow's Mill","pos":Vector2(-115,-160),"sub":"Hunger has a human face"},
	"chapel":{"name":"Chapel of the Last Bell","pos":Vector2(130,-200),"sub":"Even the dead remember a promise"},
	"marsh":{"name":"The Lantern Fen","pos":Vector2(-115,-240),"sub":"Follow the lights. But not every light."},
	"overlook":{"name":"The King's Cairn","pos":Vector2(160,-310),"sub":"Someone walked this road before you"},
	"tower":{"name":"Northwatch","pos":Vector2(0,-340),"sub":"One fire can be seen for miles"}
}
static var NPCS = {
	"mara":{"name":"Mara","role":"Innkeeper · Wayfarer's Rest","cell":0,"pos":Vector2(-8,42)},
	"osric":{"name":"Osric","role":"Smith · a practical man","cell":1,"pos":Vector2(11,27.5)},
	"ilya":{"name":"Ilya","role":"Road scout · Fallen Toll","cell":2,"pos":Vector2(13,-102)},
	"vesna":{"name":"Mother Vesna","role":"Herbalist · Foxglove Grove","cell":3,"pos":Vector2(-79,-64)},
	"rook":{"name":"Captain Rook","role":"Outlaw · Widow's Mill","cell":4,"pos":Vector2(-111,-158)},
	"sister":{"name":"Sister Elian","role":"Keeper · Chapel of the Last Bell","cell":5,"pos":Vector2(122,-190)},
	"courier":{"name":"Tomas","role":"Missing courier · Lantern Fen","cell":6,"pos":Vector2(-117,-242)},
	"merchant":{"name":"Adela","role":"Caravan trader · Northwatch","cell":7,"pos":Vector2(8,-330)}
}
static var ENEMY_TYPES = {
	"hollow_weeper":{"name":"Hollow Weeper","cell":2,"hp":150.0,"damage":58.0,"speed":2.1,"reach":11.0,"windup":1.15,"recovery":2.15,"height":3.06,"xp":65,"affiliation":"Old Faith / corporeal"},
	"pitchbound":{"name":"Pitchbound","cell":0,"hp":125.0,"damage":26.0,"speed":1.8,"reach":3.8,"windup":1.45,"recovery":2.2,"height":2.4,"xp":30},
	"boughstalker":{"name":"Boughstalker","cell":2,"hp":95.0,"damage":22.0,"speed":3.9,"reach":2.6,"windup":0.8,"recovery":1.9,"height":2.9,"xp":30},
	"bandit":{"name":"Road deserter","cell":0,"hp":85.0,"damage":17.0,"speed":2.25,"reach":2.3,"windup":0.85,"recovery":1.4,"height":2.35,"xp":15},
	"wolf":{"name":"Hollow hound","cell":1,"hp":55.0,"damage":12.0,"speed":3.6,"reach":2.15,"windup":0.6,"recovery":1.4,"height":1.35,"xp":10},
	"wraith":{"name":"The unremembered","cell":2,"hp":80.0,"damage":19.0,"speed":1.8,"reach":2.6,"windup":1.15,"recovery":1.8,"height":2.7,"xp":20},
	"guardian":{"name":"The Bell Warden","cell":3,"hp":390.0,"damage":27.0,"speed":1.65,"reach":3.5,"windup":1.35,"recovery":2.0,"height":4.4,"xp":100}
}
static var ENCOUNTERS = [
	["road_1","bandit",Vector2(0,-65)], ["road_2","bandit",Vector2(10,-83)],
	["grove_1","wolf",Vector2(-54,-45)], ["grove_2","wolf",Vector2(-88,-77)],
	["mill_1","wolf",Vector2(-54,-139)], ["mill_2","bandit",Vector2(-91,-149)],
	["chapel_road_1","bandit",Vector2(63,-168)], ["chapel_road_2","wolf",Vector2(98,-174)],
	["chapel_1","wraith",Vector2(135,-210)], ["chapel_2","wraith",Vector2(120,-223)],
	["marsh_road","wolf",Vector2(-127,-203)], ["marsh_1","wraith",Vector2(-105,-230)],
	["marsh_2","wraith",Vector2(-125,-251)], ["north_1","wolf",Vector2(-65,-270)],
	["north_2","wraith",Vector2(20,-280)], ["cairn_1","wraith",Vector2(146,-302)],
	["cairn_2","bandit",Vector2(155,-319)],
	["crypt_1","wraith",Vector2(130,-380)], ["crypt_2","wraith",Vector2(116,-394)],
	["crypt_3","wraith",Vector2(144,-397)], ["crypt_4","wraith",Vector2(130,-409)]
]
static var OBJECTS = {
	"supplies":{"name":"The broken caravan","kind":"quest","pos":Vector2(3,-103),"cell":6},
	"oil":{"name":"Millkeeper's lamp oil","kind":"quest","pos":Vector2(-132,-168),"cell":6},
	"relic":{"name":"The last bell's clapper","kind":"quest","pos":Vector2(130,-416),"cell":7},
	"crypt_entry":{"name":"Stair to the underchapel","kind":"portal","pos":Vector2(132,-219),"cell":7},
	"crypt_exit":{"name":"Stair to daylight","kind":"portal","pos":Vector2(130,-366),"cell":7},
	"rune_root":{"name":"The Root seal","kind":"rune","pos":Vector2(116,-394),"cell":7},
	"rune_flame":{"name":"The Flame seal","kind":"rune","pos":Vector2(145,-397),"cell":7},
	"rune_bell":{"name":"The Bell seal","kind":"rune","pos":Vector2(130,-413),"cell":7},
	"beacon":{"name":"Northwatch beacon","kind":"beacon","pos":Vector2(0,-344),"cell":7},
	"grave":{"name":"A roadkeeper's memory","kind":"lore","pos":Vector2(160,-311),"cell":7},
	"letter":{"name":"A letter that never arrived","kind":"lore","pos":Vector2(63,-181),"cell":6},
	"cache_grove":{"name":"Abandoned tool chest","kind":"cache","pos":Vector2(-86,-58),"cell":6},
	"cache_gate":{"name":"Tollkeeper's lockbox","kind":"cache","pos":Vector2(19,-88),"cell":6},
	"cache_chapel":{"name":"Pilgrim's offering","kind":"cache","pos":Vector2(142,-202),"cell":6},
	"cache_north":{"name":"Old road stores","kind":"cache","pos":Vector2(3,-303),"cell":6},
	"herb_1":{"name":"Golden yarrow","kind":"herb","pos":Vector2(-75,-59),"cell":5},
	"herb_2":{"name":"Golden yarrow","kind":"herb","pos":Vector2(-72,-72),"cell":5},
	"herb_3":{"name":"Golden yarrow","kind":"herb","pos":Vector2(-92,-60),"cell":5},
	"fen_1":{"name":"Moonwort","kind":"moonwort","pos":Vector2(-109,-248),"cell":5},
	"fen_2":{"name":"Moonwort","kind":"moonwort","pos":Vector2(-122,-233),"cell":5},
	"fen_3":{"name":"Moonwort","kind":"moonwort","pos":Vector2(-105,-238),"cell":5},
	"wood_1":{"name":"Dry firewood","kind":"wood","pos":Vector2(7,-30),"cell":1},
	"wood_2":{"name":"Dry firewood","kind":"wood","pos":Vector2(-37,-133),"cell":1},
	"wood_3":{"name":"Dry firewood","kind":"wood","pos":Vector2(94,-185),"cell":1},
	"wood_4":{"name":"Dry firewood","kind":"wood","pos":Vector2(-102,-268),"cell":1}
}

static var terrain = preload("res://scripts/terrain.gd").new()
const TERRAIN_REVISION := 1

static func height_at(x: float, z: float) -> float:
	return terrain.height_at(x,z)

static func legacy_height_at(x: float, z: float) -> float:
	return preload("res://scripts/terrain.gd").legacy(x,z)

static func ground(p: Vector2, offset := 0.0) -> Vector3:
	return Vector3(p.x,height_at(p.x,p.y)+offset,p.y)

static func distance_to_road(p: Vector2) -> float:
	var best := 10000.0
	for road in ROADS:
		for i in range(road.size()-1):
			best = minf(best,p.distance_to(Geometry2D.get_closest_point_to_segment(p,road[i],road[i+1])))
	return best

static func _static_init() -> void:
	var march = preload("res://scripts/march_content.gd")
	NPC_HEIGHTS.merge(march.HEIGHTS)
	NPCS.merge(march.NPCS)
	SITES.merge(march.SITES)
	ROADS.append_array(march.ROADS)
	OBJECTS.merge(march.OBJECTS)
	ENCOUNTERS.append_array(march.ENCOUNTERS)
	ENEMY_TYPES.merge(march.ENEMY_TYPES)
	terrain.configure(ROADS)
