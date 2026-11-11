extends RefCounted

const C = preload("res://scripts/content.gd")
const ACCOUNTS := [
	["A roadkeeper's spare pack","A note under the flap: 'If the lamps fail, leave supplies where another pair of hands can find them.'",{"wood":1}],
	["A pilgrim's wrapped bread","The cloth is stitched with a small bell. 'For whoever has farther to go than I did.'",{"bread":1}],
	["A mill worker's tool case","A tally scratched in the lid records flour delivered without payment. Hunger came before the barricade.",{"scrap":1}],
	["A courier's roadside pouch","An undelivered envelope contains a pressed flower. 'The garden took. Come home when the road permits.'",{"gold":3}],
	["An old watch patrol's stores","Beside the supplies is a roll of names. The last instruction reads: 'Leave one lamp burning until they return.'",{"wood":1}],
	["A refugee's mended basket","The handle has been repaired three times. A scrap of linen lists a child's height, measured each spring.",{"bread":1}]
]

static func register(world: Node) -> void:
	for r in range(C.ROADS.size()):
		var walked := 0.0
		var next := 55.0
		var number := 0
		var road: Array = C.ROADS[r]
		for segment in range(road.size()-1):
			var start: Vector2 = road[segment]
			var finish: Vector2 = road[segment+1]
			var length := start.distance_to(finish)
			while next<=walked+length:
				var along: Vector2 = start.lerp(finish,(next-walked)/length)
				var at: Vector2 = along+(finish-start).normalized().orthogonal()*3.5
				var id := "road_find_%d_%d" % [r,number]
				next += 95.0
				number += 1
				if at.y> -430 and at.y< -350 and at.x>95: continue
				if not world.outside_buildings(at,3): continue
				if world.water_bounds.any(func(b): return b.grow(2).has_point(at)): continue
				if C.OBJECTS.values().any(func(o): return at.distance_to(o.pos)<12): continue
				if C.NPCS.values().any(func(n): return at.distance_to(n.pos)<12): continue
				if preload("res://scripts/weeper_sites.gd").reserved(at): continue
				var account: Array = ACCOUNTS[(r+number)%ACCOUNTS.size()]
				C.OBJECTS[id] = {"name":account[0],"kind":"cache","pos":at,"cell":6,"loot":account[2].duplicate(),"lore":account[1]}
			walked += length
