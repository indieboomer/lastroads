extends RefCounted

func run(g: Node) -> void:
	g.start_new()
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280,720))
	# The 08:06 field note: harvest is immediate, one-time, and survives save/load.
	assert(g.world.foraging.berries_00.node.visible)
	g.harvest("berries_00")
	assert(not g.world.foraging.berries_00.node.visible and g.state.inventory.berries==2)
	g.harvest("berries_00")
	assert(g.state.inventory.berries==2)
	assert(g.save_game() and g.load_game())
	assert(not g.world.foraging.berries_00.node.visible)
	g.teleport(Vector2(-5.410916,1.866324),-2.80390048)
	g.player.position.y = 1.21281838
	g.camera.rotation.x = -.76519984
	g.visuals.values.preset = 1
	g.visuals.values.trees = 1
	g.visuals.values.enabled = true
	g.visuals.values.dither = .7
	g.visuals.values.grain = .4
	g.ui.apply_visuals()
	g.state.day_clock = 15.25
	g.world.tick(0)
	await g.capture("16-harvested-bush-field-camera")
	g.start_new()
	assert(g.world.foraging.berries_00.node.visible,"New journeys must restore forage")
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	# The 08:08 field note: compare soles with the rendered road, not its terrain.
	var rook: Sprite3D = g.world.npcs.rook
	var p: Vector2 = g.C.NPCS.rook.pos
	var road_y: float = g.C.height_at(p.x,p.y)+.075
	for elapsed in [0.0,.6,1.6,3.0]:
		g.state.elapsed = elapsed
		g.world.tick(0)
		var sole: float = rook.position.y-rook.scale.y*g.C.NPC_HEIGHTS.rook*.5
		assert(sole>=road_y+.01 and sole<road_y+.04,"Rook's boots must clear the painted road throughout breathing")
	assert(g.save_game() and g.load_game())
	g.teleport(Vector2(-108.986343,-157.360382),1.26719832)
	g.player.position.y = -.28889734
	g.camera.rotation.x = -.35600069
	g.state.day_clock = 17.0
	for look in [-1,1]:
		g.visuals.values.enabled = look>=0
		g.ui.apply_visuals()
		g.world.tick(0)
		await g.capture("16-rook-boots-field-camera-look-%d" % look)
	# Oblique views of the revised pine, where the old repeated bends looked worst.
	g.visuals.values.trees = 1
	var sample: Sprite3D = g.world.sprite("trees",0,4,1,g.C.ground(Vector2.ZERO),12.0)
	g.world.wind(sample,.13,.48)
	var proxy: MeshInstance3D = g.world.static_tree_shadow(sample)
	g.world.forest.register_tree(sample,proxy,Vector2.ZERO,12.0,0,9002)
	g.world.forest.mode = -1
	g.world.forest.apply_mode(1)
	for record in g.world.forest.records:
		if record.card!=sample:
			record.card.hide()
			record.shadow.hide()
			for extra in record.extra: extra.hide()
	g.state.day_clock = 14.0
	g.weather.force("clear")
	for look in [-1,1]:
		g.visuals.values.enabled = look>=0
		g.ui.apply_visuals()
		for angle in [0.0,PI/4,PI/2]:
			g.teleport(Vector2(sin(angle),cos(angle))*18)
			g.camera.look_at(sample.global_position,Vector3.UP)
			g.world.tick(0)
			await g.capture("16-pine-look-%d-angle-%d" % [look,roundi(rad_to_deg(angle))])
	print("FIELD PASS: picked berry bush hidden immediately/after reload, one-time loot and fresh-journey reset; Rook boots clear raised road during breathing/reload; revised pine rendered at 0/45/90 degrees in Original and Copper")
	g.get_tree().quit()
