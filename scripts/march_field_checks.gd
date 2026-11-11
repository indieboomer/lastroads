extends RefCounted
const Story = preload("res://scripts/march.gd")

func run(g: Node) -> void:
	g.start_new()
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280,720))
	g.visuals.values.enabled = true
	g.visuals.values.preset = 1
	g.visuals.values.trees = 1
	g.ui.apply_visuals()
	g.state.day_clock = 12
	g.weather.force("clear")
	await g.get_tree().physics_frame
	# Actual bridge collider must take precedence over the river's 2D bounds.
	g.player.position = Vector3(-.625058,2.639133,-433.486908)
	verify(g.audio.step_family()=="footstep_wood")
	g.audio.reset_effects()
	verify(g.audio.play_effect("step"))
	verify(g.audio.recent_events[-1].family=="footstep_stone" and g.audio.recent_events[-1].source.begins_with("res://sounds/footstep_"))
	g.player.position = g.C.ground(Vector2(12,-435),.07)
	verify(g.audio.step_family()=="footstep_shallow_water")
	for stem in g.get_tree().get_nodes_in_group("march_cross_stems"):
		verify(stem.position.y-stem.mesh.size.y/2<=g.C.height_at(stem.position.x,stem.position.z),"Cross stem must reach terrain")
	for id in ["raisa","pavel"]:
		var person: Sprite3D = g.world.march_world.nodes["patient_"+id]
		verify(person.visible and person.rotation==Vector3.ZERO and person.texture.get_height()>100,"Sick people sit upright above their beds")
	await patient_review(g)
	# The reported save already had epilogue=true; closure must remain accessible.
	g.state.flags.won = true
	g.state.story = Story.DEFAULTS.duplicate(true)
	for key in ["started","briefed","orders","ledger","roll","witness","medicine_done","bell_done","epilogue","ferry_fixed"]: g.state.story[key] = true
	g.state.story.patient = "raisa"
	for verdict in ["trial","resign","burn"]:
		g.state.story.verdict = verdict
		g.talk("nera")
		verify(g.ui.dialog_body.text.contains("hospice bell reaches Saint Mere"))
		var gold: int = g.state.inventory.gold
		var xp: int = g.state.xp
		g.choose_dialog("march:epilogue")
		verify(g.ui.dialog_body.text.contains("ordinary tomorrow"))
		verify(g.state.inventory.gold==gold and g.state.xp==xp,"Revisiting aftermath must never repay rewards")
	verify(g.save_game() and g.load_game())
	g.talk("nera")
	verify(g.ui.dialog_body.text.contains("hospice bell reaches Saint Mere"))
	await g.capture("17-nera-aftermath-revisited")
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	for scene in [
		[Vector3(-76.27137,-2.000317,-528.155151),.235435,-.383899,"threshold"],
		[Vector3(-74.59449,-1.734562,-537.72406),-.699565,-.430099,"pavel-bed"],
		[Vector3(-78.30402,-1.734559,-539.61755),1.054935,-.446600,"raisa-bed"],
		[Vector3(-201.37305,-.379963,-630.09772),-.724881,-.159499,"cross"],
		[Vector3(2.166601,2.029633,-927.131531),1.982686,-.548764,"hospice-roads"]
	]:
		g.player.position = scene[0]
		g.player.rotation.y = scene[1]
		g.camera.rotation = Vector3(scene[2],0,0)
		g.world.tick(0)
		await g.capture("17-"+scene[3])
		if scene[3]=="hospice-roads":
			for screen in [Vector2(670,365),Vector2(710,385),Vector2(620,350)]:
				var ray := PhysicsRayQueryParameters3D.create(g.camera.project_ray_origin(screen),g.camera.project_ray_origin(screen)+g.camera.project_ray_normal(screen)*60,1)
				var hit: Dictionary = g.world.get_world_3d().direct_space_state.intersect_ray(ray)
				if not hit.is_empty():
					var p := Vector2(hit.position.x,hit.position.z)
					verify(g.world.road_footprints.any(func(f): return Geometry2D.is_point_in_polygon(p,f)),"Reported grass wedges must be covered at the hospice road junction")
	print("MARCH FIELD PASS: bridge wood/river water footsteps, grounded crosses, seated patients and both empty-bed outcomes, replayable saved Nera aftermath without duplicate rewards, reported scene captures")
	g.get_tree().quit()

func patient_review(g: Node) -> void:
	var original: Dictionary = g.state.story.duplicate(true)
	var nodes: Dictionary = g.world.march_world.nodes
	g.teleport(Vector2(-76.5,-532),0)
	g.player.position.y = g.C.height_at(-76.5,-532)+.32
	g.camera.look_at(g.C.ground(Vector2(-76.5,-540.5),1.5),Vector3.UP)
	for retro in [false,true]:
		g.visuals.values.enabled = retro
		g.ui.apply_visuals()
		await g.capture("24-patients-"+("copper" if retro else "original"))
	for selected in ["raisa","pavel"]:
		g.state.story.medicine_done = true
		g.state.story.patient = selected
		g.world.apply_state()
		for id in ["raisa","pavel"]:
			verify(nodes["patient_"+id].visible==(id==selected))
			verify(nodes["folded_"+id].visible==(id!=selected))
			verify(nodes["pillow_"+id].visible==(id!=selected))
			verify(nodes[id].visible==(id==selected))
		verify(g.validate_save(g.snapshot()))
		await g.capture("24-survivor-"+selected)
	g.state.story = original
	g.world.apply_state()

# Release exports strip assert expressions entirely. Always execute validation,
# including playback/save actions, and report failures to the build runner.
func verify(condition: bool, detail := "") -> void:
	if not condition:
		push_error("VALIDATION FAILED: "+detail)
