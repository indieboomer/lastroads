extends RefCounted

func run(g: Node) -> void:
	var caches: Array = g.C.OBJECTS.keys().filter(func(id): return id.begins_with("forest_cache_"))
	assert(caches.size()>=12,"Both regions need woodland rewards")
	for id in caches:
		var record: Dictionary = g.C.OBJECTS[id]
		assert(g.C.distance_to_road(record.pos)>=40)
		assert(not g.world.water_bounds.any(func(b): return b.has_point(record.pos)))
		assert(not g.world.tree_locations.any(func(t): return t.distance_to(record.pos)<3))
	var first: String = caches[0]
	var gold: int = g.state.inventory.gold
	g._local_interact_object(first)
	var reward: int = g.C.OBJECTS[first].loot.gold
	assert(g.state.inventory.gold==gold+reward)
	g._local_interact_object(first)
	assert(g.state.inventory.gold==gold+reward,"Caches pay only once")
	for slot in g.C.ENCOUNTERS:
		if slot[1]=="bandit": g.state.defeated[slot[0]] = true
	for enemy in g.enemies:
		if enemy.kind=="bandit":
			enemy.dead = true
			enemy.health = 0
			enemy.collision_layer = 0
	g.state.elapsed = 600
	var director = preload("res://scripts/road_returns.gd")
	director.tick(g)
	assert(not g.state.road_returns.is_empty())
	assert(not g.enemies.any(func(e): return e.id.begins_with("road_return_")),"Old saves receive cooldown")
	for cycle in range(2,32):
		g.state.elapsed = cycle*600.0
		director.tick(g)
	var replacements: Array = g.enemies.filter(func(e): return e.id.begins_with("road_return_"))
	assert(not replacements.is_empty(),"Cleared roads can repopulate")
	var slots: Array = g.C.ENCOUNTERS.filter(func(e): return e[1]=="bandit" and g.C.distance_to_road(e[2])<18)
	assert(replacements.size()<=ceili(slots.size()*0.2),"Sparse population cap")
	for e in replacements: assert(e.position.distance_to(g.player.position)>=65)
	var restored = g.State.new()
	assert(restored.read_dict(g.state.to_dict(),5))
	assert(restored.road_returns==g.state.road_returns and restored.taken.has(first))
	var old: Dictionary = g.state.to_dict()
	old.erase("road_returns")
	assert(restored.read_dict(old,5) and restored.road_returns.is_empty())
	old.road_returns = {"road_1":-1}
	assert(not restored.read_dict(old,5))
	# Keep the existing wilderness suite independent from the return simulation.
	g.start_new(preload("res://scripts/character_data.gd").defaults())
	print("TRAVEL PASS: ",caches.size()," dry woodland caches, one-time loot, sparse road returns, cooldown and save migration")

