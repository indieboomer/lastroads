extends RefCounted
const Settings = preload("res://scripts/visual_settings.gd")

func run(g: Node) -> void:
	g.start_new()
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280,720))
	var grass: Node3D = g.world.lush_grass
	assert(Settings.DEFAULTS.dense_grass)
	var preferences = Settings.new()
	var legacy_path: String = g.data_root().path_join("reports/grass-legacy-settings.cfg")
	var legacy := ConfigFile.new()
	legacy.set_value("visuals","preset",1)
	assert(legacy.save(legacy_path)==OK)
	preferences.read(legacy_path)
	assert(preferences.values.dense_grass,"Old preference files must enable the new default")
	g.ui.change_setting("dense_grass",true)
	assert(grass.built and grass.visible and grass.instance_count>400000,"The new field must massively exceed the old sparse cover")
	var checked := 0
	for patch in grass.get_children():
		for index in range(patch.multimesh.instance_count):
			var at: Vector3 = patch.position+patch.multimesh.get_instance_transform(index).origin
			assert(grass.clear_of_items(Vector2(at.x,at.z)),"Dense grass must preserve collectible clearings")
			checked += 1
	# Independently test actual pickup positions against rendered instances and
	# allow a full metre for the widest blade silhouette and its wind motion.
	for record in g.world.foraging.values():
		verify_clearing(grass,record.pos,2.3 if record.kind=="berries" else 1.3)
	for record in g.C.OBJECTS.values():
		if record.kind=="wood": verify_clearing(grass,record.pos,1.9)
	# Recheck the old layers too: new grass must not be the only safe layer.
	for patch in g.get_tree().get_nodes_in_group("meadow_grass"):
		for index in range(patch.multimesh.instance_count):
			var at: Vector3 = patch.multimesh.get_instance_transform(index).origin
			assert(grass.clear_of_items(Vector2(at.x,at.z)))
	for sprite in g.get_tree().get_nodes_in_group("grass_sprites"):
		if sprite.visible: assert(grass.clear_of_items(Vector2(sprite.position.x,sprite.position.z)))
	g.state.day_clock = 14.0
	g.weather.force("clear")
	var metrics: Array = []
	for on in [false,true]:
		g.ui.change_setting("dense_grass",on)
		assert(grass.visible==on)
		preferences.read(g.settings_path())
		assert(preferences.values.dense_grass==on,"Toggle must persist immediately")
		for scene in [[Vector2(-24,-55),Vector2(-32,-75),"field"],[Vector2(48,-151),Vector2(33,-166),"hills"],[Vector2(-65,-520),Vector2(-78,-504),"march"]]:
			g.teleport(scene[0])
			g.player.position.y = g.C.height_at(scene[0].x,scene[0].y)
			g.camera.look_at(g.C.ground(scene[1],1.2),Vector3.UP)
			g.world.tick(0)
			for frame in range(8): await g.get_tree().process_frame
			var start := Time.get_ticks_usec()
			for frame in range(60): await g.get_tree().process_frame
			metrics.append({"scene":scene[2],"enabled":on,"frame_ms":snappedf((Time.get_ticks_usec()-start)/60000.0,.01),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
			await g.capture("19-grass-%s-%s" % [scene[2],"on" if on else "off"])
	# Actual nearby collectible views with the dense layer active.
	var mushroom: Dictionary = g.world.foraging.values().filter(func(r): return r.kind=="mushrooms")[0]
	for scene in [[g.world.foraging.berries_00.pos,"berries"],[mushroom.pos,"mushroom"],[g.C.OBJECTS.wood_1.pos,"firewood"]]:
		g.teleport(scene[0]+Vector2(0,3))
		g.camera.look_at(g.C.ground(scene[0],.35),Vector3.UP)
		g.world.tick(0)
		await g.capture("19-grass-clear-"+scene[1])
	g.ui.open_settings("pause")
	g.ui.select_settings_tab(1)
	g.ui.sync_settings()
	assert(g.ui.settings_dense_grass.button_pressed)
	await g.capture("19-grass-settings")
	g.ui.settings_dense_grass.button_pressed = false
	assert(not grass.visible and not g.visuals.values.dense_grass)
	g.ui.settings_dense_grass.button_pressed = true
	assert(grass.visible and g.visuals.values.dense_grass)
	var report := FileAccess.open(g.data_root().path_join("reports/grass-performance.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"gpu":RenderingServer.get_video_adapter_name(),"instances":grass.instance_count,"patches":grass.get_child_count(),"build_ms":grass.build_ms,"checked_clearings":checked,"measurements":metrics},"\t"))
	print("GRASS PASS: %d additional tufts / %d culled patches, all collectible clearings verified in new and old grass, default-on/legacy preferences/persistent settings toggle, field and pickup captures; build %d ms" % [grass.instance_count,grass.get_child_count(),grass.build_ms])
	g.get_tree().quit()

func verify_clearing(grass: Node3D, p: Vector2, radius: float) -> void:
	var required := radius+1.0
	for patch in grass.get_children():
		var centre := Vector2(patch.position.x,patch.position.z)
		if absf(centre.x-p.x)>16+required or absf(centre.y-p.y)>16+required: continue
		for index in range(patch.multimesh.instance_count):
			var at: Vector3 = patch.position+patch.multimesh.get_instance_transform(index).origin
			assert(p.distance_squared_to(Vector2(at.x,at.z))>=required*required,"Grass silhouette would enter a pickup clearing")
