extends RefCounted

const C = preload("res://scripts/content.gd")
const MEMORIES := [
	"Oilcloth protects a roadkeeper's tally: three lamps filled, one traveller still missing.",
	"A child's mitten lies beneath the supplies. Someone expected to return before winter.",
	"The lid bears the last bell's mark. Even here, someone kept a little warmth for strangers.",
	"A deserter left bread beside the coins. Hunger has a human face.",
	"A faded instruction: carry the light north; leave enough for the next soul."
]

static func register(world: Node) -> void:
	# Fixed locations and taken IDs survive upgrades; never refill on reload.
	for z in range(-935,-35,90):
		if z> -430 and z< -350: continue
		for x in [-185,-95,95,185]:
			var at := Vector2(x,z)
			if C.distance_to_road(at)<40: continue
			if C.SITES.values().any(func(s): return at.distance_to(s.pos)<45): continue
			if not world.outside_buildings(at,5): continue
			if world.water_bounds.any(func(b): return b.grow(8).has_point(at)): continue
			if preload("res://scripts/weeper_sites.gd").guard_clearing(at): continue
			var index := absi(int(x+z))/10
			var loot := {"gold":8,"scrap":2,"bread":1} if int(index)%2==0 else {"gold":5,"tonic":1,"wood":2}
			C.OBJECTS["forest_cache_%d_%d" % [x,z]] = {"name":"Roadkeeper's woodland stores","kind":"cache","pos":at,"cell":6,"loot":loot,"lore":MEMORIES[int(index)%MEMORIES.size()]}
