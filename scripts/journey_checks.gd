extends RefCounted

func run(g: Node) -> void:
	g.start_new()
	g.set_physics_process(false)
	g.get_tree().paused = true
	var finds: Array = g.C.OBJECTS.keys().filter(func(id): return id.begins_with("road_find_"))
	assert(finds.size()>=10,"Roads need discoverable content in both chapters")
	for id in finds:
		var at: Vector2 = g.C.OBJECTS[id].pos
		assert(g.C.distance_to_road(at)<5)
		assert(not g.world.water_bounds.any(func(b): return b.has_point(at)))
		assert(not g.world.tree_locations.any(func(t): return at.distance_to(t)<3))
	var first: String = finds[0]
	var item: String = g.C.OBJECTS[first].loot.keys()[0]
	var count: int = g.state.inventory[item]
	g._local_interact_object(first)
	g._local_interact_object(first)
	assert(g.state.inventory[item]==count+g.C.OBJECTS[first].loot[item])
	# Scout still reachable when collecting both supplies before hearing his report.
	g.state.flags.oil = true
	g.state.flags.relic = true
	g.state.flags.supplies = true
	g.state.flags.accepted = true
	g.world.apply_state()
	assert(g.world.npcs.ilya.position.distance_to(g.C.ground(g.C.NPCS.ilya.pos))<3)
	g.dialogue_id = "ilya"
	g._local_choose_dialog("scout_report")
	assert(g.world.npcs.ilya.position.distance_to(g.C.ground(Vector2(-7,-332)))<3)
	assert(g.target().pos==Vector2(-7,-332))
	g.teleport(Vector2(-7,-332))
	g.talk("ilya")
	assert(g.ui.current_choices.any(func(c): return c.action=="prepare"))
	var tonics: int = g.state.inventory.tonic
	g.choose_dialog("prepare")
	g.choose_dialog("prepare")
	assert(g.state.flags.prepared and g.state.inventory.tonic==tonics+3,"Preparation is one-time at either contact")
	assert(g.target().pos==g.C.OBJECTS.beacon.pos)
	# The rescued-courier dialogue has a second route to the scout report.
	g.state.flags.prepared = false
	g.state.flags.scout = false
	g.state.flags.courier_done = true
	g.world.apply_state()
	g._local_choose_dialog("ilya_next")
	assert(g.world.npcs.ilya.position.distance_to(g.C.ground(Vector2(-7,-332)))<3)
	g.state.flags.prepared = true
	g.state.flags.courier_done = false
	# Remove authored danger to test travel guards separately.
	for enemy in g.enemies:
		enemy.dead = true
		enemy.health = 0
		enemy.collision_layer = 0
	g.teleport(g.journey.STOPS.inn)
	assert(not g.journey.requirement("journey:go:mill").allowed)
	g.state.discovered.mill = true
	assert(not g.journey.requirement("journey:go:mill").allowed,"Discovery alone is insufficient")
	g.state.flags.bargain = true
	assert(g.journey.requirement("journey:go:mill").allowed)
	var threat: Node = g.spawn_enemy("journey_destination_guard","bandit",g.journey.STOPS.mill)
	assert(not g.journey.requirement("journey:go:mill").allowed,"Destination danger blocks passage")
	threat.dead = true
	var origin_guard: Node = g.spawn_enemy("journey_origin_guard","bandit",g.journey.STOPS.inn)
	assert(not g.journey.requirement("journey:go:mill").allowed,"Origin danger blocks passage")
	origin_guard.dead = true
	g.choose_dialog("journey:go:mill")
	assert(g.player.position.distance_to(g.C.ground(g.journey.STOPS.mill))<2)
	g.teleport(Vector2(210,-120))
	assert(not g.journey.requirement("journey:go:inn").allowed,"Cannot depart from the wilderness")
	g.teleport(g.journey.STOPS.inn)
	g.state.discovered.ash_refuge = true
	g.state.flags.won = true
	assert(not g.journey.requirement("journey:go:ash_refuge").allowed)
	g.state.story.ferry_fixed = true
	assert(g.journey.requirement("journey:go:ash_refuge").allowed)
	# Settlement runners consume the same medicine and cannot duplicate rewards.
	g.state.inventory.yarrow = 3
	g.state.inventory.moonwort = 3
	assert(not g.journey.requirement("journey:yarrow").allowed)
	g.state.flags.herbalist = true
	g.state.flags.courier = true # Hearing the rumor must not permit remote rescue.
	assert(not g.journey.requirement("journey:moonwort").allowed)
	g.state.discovered.met_courier = true
	var coins: int = g.state.inventory.gold
	g.choose_dialog("journey:yarrow")
	g.choose_dialog("journey:yarrow")
	g.choose_dialog("journey:moonwort")
	g.choose_dialog("journey:moonwort")
	assert(g.state.flags.herbs_done and g.state.flags.courier_done)
	assert(g.state.inventory.gold==coins+55 and g.state.inventory.yarrow==0 and g.state.inventory.moonwort==0)
	# Cadence follows actual travel, defers to combat, and excludes teleport jumps.
	g.teleport(Vector2(0,-55))
	g.ui.toast_timer = 0
	g.ui.discovery_timer = 0
	g.state.journey.interest = 0
	g.state.journey.story = 0
	g.journey.tick(30)
	assert(g.state.journey.interest==0,"Standing still does not emit travel prompts")
	g.journey.last_position = g.player.position-Vector3(0.2,0,0)
	g.journey.tick(30)
	assert(g.state.events.back().event=="journey_interest")
	g.ui.toast_timer = 0
	g.ui.discovery_timer = 0
	g.journey.last_position = g.player.position-Vector3(0.2,0,0)
	g.journey.tick(270)
	assert(g.state.discovered.has("journey_story_ferry"))
	assert(g.journey.journal().contains("Two shores"))
	var discovered: int = g.state.discovered.size()
	g.journey.story_beat()
	assert(g.state.discovered.size()==discovered+1,"Milestone scenes do not repeat")
	assert(g.journey.stride(5,true))
	threat = g.spawn_enemy("journey_stride_guard","wolf",Vector2(0,-58))
	assert(not g.journey.stride(0.1,true) and g.journey.stride_clock==0)
	g.ui.toast_timer = 0
	g.ui.discovery_timer = 0
	g.state.journey.interest = 30.0
	var events_before: int = g.state.events.size()
	g.journey.last_position = g.player.position-Vector3(0.2,0,0)
	g.journey.tick(1)
	assert(g.state.events.size()==events_before and g.state.journey.interest==30,"Combat defers interest beats")
	threat.dead = true
	var save: Dictionary = g.snapshot()
	assert(g.validate_save(save))
	var restored = g.State.new()
	assert(restored.read_dict(JSON.parse_string(JSON.stringify(save.state)),5))
	assert(is_equal_approx(restored.journey.interest,g.state.journey.interest) and is_equal_approx(restored.journey.story,g.state.journey.story))
	assert(restored.journey.observations==g.state.journey.observations and restored.discovered.has("journey_story_ferry"))
	save.state.erase("journey")
	assert(restored.read_dict(save.state,5) and restored.journey.interest==0)
	save.state.journey = {"interest":31,"story":0,"observations":0}
	assert(not restored.read_dict(save.state,5))
	# Capture the real menus for layout inspection.
	g.teleport(g.journey.STOPS.inn)
	g.journey.travel_menu()
	await g.get_tree().process_frame
	await g.get_tree().process_frame
	g.get_viewport().get_texture().get_image().save_png(g.data_root().path_join("reports/journey-travel-menu.png"))
	g.journey.errands()
	await g.get_tree().process_frame
	await g.get_tree().process_frame
	g.get_viewport().get_texture().get_image().save_png(g.data_root().path_join("reports/journey-errands-menu.png"))
	g.set_modal("")
	var find_at: Vector2 = g.C.OBJECTS[finds[finds.size()-1]].pos
	g.teleport(find_at+Vector2(0,5))
	g.camera.look_at(g.C.ground(find_at,0.6))
	await g.get_tree().process_frame
	await g.get_tree().process_frame
	g.get_viewport().get_texture().get_image().save_png(g.data_root().path_join("reports/journey-road-find.png"))
	print("JOURNEY PASS: ",finds.size()," road finds; Ilya preparation and early-supply route; safe/discovered travel/ferry gates; one-time remote rewards; 30s/300s movement cadence; stride safety; save migration and menus")
	g.get_tree().quit()
