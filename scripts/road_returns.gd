extends RefCounted

const C = preload("res://scripts/content.gd")
const INTERVAL := 600.0

static func tick(g: Node) -> void:
	if g.coop.active and not g.coop.is_host: return
	var cycle := int(g.state.elapsed/INTERVAL)
	if cycle<1: return
	var slots: Array = C.ENCOUNTERS.filter(func(e): return e[1]=="bandit" and C.distance_to_road(e[2])<18)
	var cap := maxi(1,ceili(slots.size()*0.2))
	var living: int = g.enemies.filter(func(e): return e.id.begins_with("road_return_") and not e.dead).size()
	for slot in slots:
		var key: String = slot[0]
		if not g.state.defeated.has(key): continue
		# Old saves start a fresh cooldown; loading never rolls a new encounter.
		if not g.state.road_returns.has(key):
			g.state.road_returns[key] = cycle
			continue
		if int(g.state.road_returns[key])>=cycle: continue
		var at: Vector2 = slot[2]+Vector2(5 if cycle%2==0 else -5,3)
		if at.distance_to(Vector2(g.player.position.x,g.player.position.z))<65: continue
		if g.coop.active and g.coop.avatars.values().any(func(a): return a.position.distance_to(C.ground(at))<65): continue
		g.state.road_returns[key] = cycle
		if living>=cap or absi((key+str(cycle)).hash())%5!=0: continue
		if C.NPCS.values().any(func(n): return at.distance_to(n.pos)<25): continue
		if not g.world.outside_buildings(at,4): continue
		if g.world.water_bounds.any(func(b): return b.grow(3).has_point(at)): continue
		if g.world.tree_locations.any(func(t): return at.distance_to(t)<2.5): continue
		if g.enemies.any(func(e): return not e.dead and e.position.distance_to(C.ground(at))<25): continue
		# Each replacement has its own saved body and loot; original quest kills stay true.
		g.spawn_enemy("road_return_%s_%d" % [key,cycle],"bandit",at)
		living += 1
