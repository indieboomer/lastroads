extends RefCounted

const C = preload("res://scripts/content.gd")
const LABELS := ["Road country", "Woodland / caution", "Deep woods / dangerous", "Wilds / extreme danger"]

const DAY_DEPTH := 38.0 # Ten seconds at normal walking speed.
const NIGHT_DEPTH := 16.0

static func tier(p: Vector2, hour := 12.0, world: Node = null) -> int:
	var depth := NIGHT_DEPTH if hour>=18 or hour<7 else DAY_DEPTH
	var road: float = C.distance_to_road(p)
	var shelter := 10000.0
	# Protect every authored inhabited site and quest interaction, including ruins.
	for site in C.SITES.values(): shelter = minf(shelter,p.distance_to(site.pos))
	for npc in C.NPCS.values(): shelter = minf(shelter,p.distance_to(npc.pos))
	if road<depth or shelter<depth: return 0
	if world!=null and not world.outside_buildings(p,depth): return 0
	if road<depth+12: return 2
	return 3

static func legacy_tier(p: Vector2) -> int:
	# Existing save IDs must keep their original enemy families.
	var road: float = C.distance_to_road(p)
	var shelter := 10000.0
	for site in C.SITES.values(): shelter = minf(shelter,p.distance_to(site.pos))
	for npc in C.NPCS.values(): shelter = minf(shelter,p.distance_to(npc.pos))
	if road<18 or shelter<38: return 0
	if road<38 or shelter<60: return 1
	if road<65 or shelter<90: return 2
	return 3

static func encounters(world: Node) -> Array:
	var result: Array = []
	var counts := [0,0]
	# Fixed cells and stable IDs: no random spawning behind the player or on reload.
	for z in range(-965,-35,55):
		for x in range(-205,206,55):
			var p := Vector2(x,z)
			if preload("res://scripts/weeper_sites.gd").guard_clearing(p): continue
			var danger := legacy_tier(p)
			var chapter := 1 if z< -425 else 0
			if danger<1 or counts[chapter]>=18 or not world.outside_buildings(p,12): continue
			if world.tree_locations.any(func(tree): return p.distance_to(tree)<2.5): continue
			if world.water_bounds.any(func(bounds): return bounds.grow(10).has_point(p)): continue
			# Avoid the underchapel's above-ground footprint and map transition.
			if z> -430 and z< -350: continue
			if C.OBJECTS.values().any(func(object): return p.distance_to(object.pos)<20): continue
			var kind := "wolf" if danger==1 else "pitchbound" if (x+z)%2==0 else "boughstalker"
			var uid := "wild_%d_%d" % [x,z]
			result.append([uid,kind,p])
			counts[chapter] += 1
			if danger==3 and not preload("res://scripts/weeper_sites.gd").guard_clearing(p+Vector2(7,5)):
				result.append([uid+"_hunter","boughstalker" if kind=="pitchbound" else "pitchbound",p+Vector2(7,5)])
	# Stable roadside encounters; the shared depth rule controls when they hunt.
	for r in range(C.ROADS.size()):
		var road = C.ROADS[r]
		for segment in range(road.size()-1):
			var midpoint: Vector2 = (road[segment]+road[segment+1])*0.5
			var normal: Vector2 = (road[segment+1]-road[segment]).normalized().orthogonal()
			for offset in [-44.0,-14.0,14.0,44.0]:
				# Keep the original save ID while moving nighttime homes twice as far out.
				var placement_offset: float = offset*2.0 if absf(offset)==14.0 else offset
				var p: Vector2 = midpoint+normal*placement_offset
				if preload("res://scripts/weeper_sites.gd").guard_clearing(p): continue
				if tier(p,22,world)==0 or absf(p.x)>225 or p.y< -995 or p.y>65: continue
				if not world.outside_buildings(p,12): continue
				if world.water_bounds.any(func(bounds): return bounds.grow(5).has_point(p)): continue
				if world.tree_locations.any(func(tree): return p.distance_to(tree)<2.5): continue
				if C.OBJECTS.values().any(func(object): return p.distance_to(object.pos)<12): continue
				if result.any(func(entry): return p.distance_to(entry[2])<24): continue
				result.append(["wild_edge_%d_%d_%d" % [r,segment,int(offset)],"pitchbound" if (r+segment)%2==0 else "boughstalker",p])
	# Validate companion offsets too: clearing trees can reveal cells close to
	# an inhabited footprint that used to be rejected by vegetation alone.
	return result.filter(func(entry): return tier(entry[2],22,world)>0 and C.distance_to_road(entry[2])>=16)
