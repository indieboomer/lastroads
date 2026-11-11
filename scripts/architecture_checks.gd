extends RefCounted

func run(g: Node) -> void:
	g.start_new()
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280,720))
	await g.get_tree().physics_frame
	# Test the actual solid geometry, including the largest playable capsule.
	var space: PhysicsDirectSpaceState3D = g.world.get_world_3d().direct_space_state
	for h in g.world.cottages:
		var size: Vector2 = h.get_meta("footprint")
		var body := CapsuleShape3D.new()
		body.radius = .32
		body.height = 2.45
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = body
		query.collision_mask = 1
		query.transform = Transform3D(Basis.IDENTITY,h.to_global(Vector3(0,1.785,size.y/2)))
		assert(space.intersect_shape(query).is_empty(),"Building doorway must fit the ogre: "+str(h.position))
		var ray := PhysicsRayQueryParameters3D.create(h.to_global(Vector3(0,1.7,size.y/2+1)),h.to_global(Vector3(0,1.7,0)),1)
		assert(space.intersect_ray(ray).is_empty(),"Entry aisle must remain clear")
	# Same tree in crossed-card and fixed-card presentations, plus original/retro rooms.
	g.state.day_clock = 14.0
	g.weather.force("clear")
	g.visuals.values.trees = 1
	g.world.forest.apply_mode(1)
	var metrics: Array = []
	for look in [-1,1]:
		g.visuals.values.enabled = look>=0
		g.visuals.values.preset = maxi(look,0)
		g.ui.apply_visuals()
		for scene in [
			[Vector2(-5,49),Vector3(-14,2.2,30),"inn-outside"],
			[Vector2(-13,34),Vector3(-17,1.5,28),"inn-inside"],
			[Vector2(-118,-154),Vector3(-123,2.5,-166),"mill-outside"],
			[Vector2(-122,-162),Vector3(-125.6,1.4,-169),"mill-inside"],
			[Vector2(17,23),Vector3(14,1.5,18),"workshop"],
			[Vector2(-46,-537),Vector3(-49,1.7,-544),"refuge-pantry"],
			[Vector2(178,-754),Vector3(172,1.6,-761),"counting-house"]
		]:
			g.teleport(scene[0])
			g.camera.look_at(Vector3(scene[1].x,g.C.height_at(scene[0].x,scene[0].y)+scene[1].y,scene[1].z),Vector3.UP)
			g.world.tick(0)
			await g.capture("15-%s-look-%d" % [scene[2],look])
			var start := Time.get_ticks_usec()
			for frame in range(12): await g.get_tree().process_frame
			metrics.append({"scene":scene[2],"look":look,"frame_ms":snappedf((Time.get_ticks_usec()-start)/12000.0,.01),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	# Place a review specimen in a clear yard so other trees cannot obscure it.
	var sample: Sprite3D = g.world.sprite("trees",3,4,1,g.C.ground(Vector2(0,13)),12.0)
	g.world.wind(sample,.13,.48)
	var proxy: MeshInstance3D = g.world.static_tree_shadow(sample)
	g.world.forest.register_tree(sample,proxy,Vector2(0,13),12.0,3,9001)
	g.world.forest.mode = -1
	for mode in [1,2]:
		g.world.forest.apply_mode(mode)
		g.teleport(Vector2(0,31))
		g.camera.look_at(sample.global_position,Vector3.UP)
		await g.capture("15-oak-mode-%d" % mode)
	var report := FileAccess.open(g.data_root().path_join("reports/architecture-performance.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"gpu":RenderingServer.get_video_adapter_name(),"viewport":g.get_viewport().size,"measurements":metrics},"\t"))
	print("ARCHITECTURE PASS: every doorway fits the 2.45m playable ogre capsule, entry aisles clear; inn/mill/workshop/pantry/counting-house rendered in original and Copper, replacement oak in crossed and still modes")
	g.get_tree().quit()
