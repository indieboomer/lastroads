extends RefCounted
const Story = preload("res://scripts/march.gd")

func run(g: Node) -> void:
	g.start_new()
	g.set_physics_process(false)
	g.state.flags.won = true
	g.state.story = Story.DEFAULTS.duplicate(true)
	for key in ["started","briefed","orders","ledger","roll","witness","medicine_done","ashes_done","letters_done","ferry_fixed","soldier_done","defense_done","bell_done","epilogue","faith_accepted"]: g.state.story[key] = true
	g.state.story.patient = "raisa"
	g.state.story.verdict = "trial"
	g.state.story.track = 6
	g.world.apply_state()
	g.set_modal("")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280,720))
	await g.get_tree().physics_frame
	g.player.position = Vector3(6.767937,2.374136,-436.932251)
	g.player.rotation.y = -.55218464
	g.camera.rotation = Vector3(-.26070112,0,0)
	assert(g.nearest_interaction().get("id","")=="ash_candle_bridge","The exact reported view must show the bridge votive prompt")
	g.ui.tick(0)
	assert(g.ui.tracker.text.begins_with("WHAT REMAINS OF FAITH"))
	await g.capture("18-bridge-votive-prompt")
	# A real unrelated wall must still block interaction after raising the anchor.
	var target: Vector3 = g.object_interaction_point("ash_candle_bridge")
	var obstruction: MeshInstance3D = g.world.block((g.camera.global_position+target)*.5,Vector3(.7,2,.7),g.world.paint("stone"))
	await g.get_tree().physics_frame
	assert(g.nearest_interaction().get("id","")!="ash_candle_bridge")
	obstruction.queue_free()
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	g.press_key(KEY_E)
	assert(g.state.story.candle_bridge and g.modal=="dialog","Normal E interaction must advance the reported quest")
	assert(g.ui.dialog_body.text.contains("orchard shrine"))
	assert(g.save_game() and g.load_game())
	assert(g.state.story.candle_bridge and not g.state.story.candle_orchard)
	assert(g.march.objective().pos==g.C.OBJECTS.ash_candle_orchard.pos)
	g.set_modal("")
	# Exercise authored objects through the same focus/E path, not direct quest calls.
	for id in ["ash_candle_orchard","ash_names_mateo","ash_names_elias","ash_names_alina","ash_raisa","ash_pavel","ash_bell"]:
		var p: Vector2 = g.C.OBJECTS[id].pos
		# Two tablets are inside the hospice wall: approach from its interior.
		g.teleport(p+Vector2(0,-2.5 if id.begins_with("ash_names_") else 2.5))
		g.player.position.y = g.C.height_at(g.player.position.x,g.player.position.z)+.32
		g.camera.look_at(g.object_interaction_point(id),Vector3.UP)
		await g.get_tree().physics_frame
		assert(g.nearest_interaction().get("id","")==id,"Unreachable authored interaction: "+id)
		g.press_key(KEY_E)
		assert(g.modal=="dialog","E must open the authored interaction: "+id)
		if id=="ash_candle_orchard":
			assert(g.state.story.candle_orchard and g.ui.dialog_body.text.contains("Father Anselm"))
			await g.capture("18-both-votives-tended")
		g.set_modal("")
	g.talk("anselm")
	choose(g,"march:faith")
	assert(g.ui.current_choices.size()==3 and g.ui.current_choices[1].action=="march:faith_silence")
	await g.capture("18-vigil-options")
	choose(g,"march:faith_silence")
	assert(g.state.story.faith_done and g.state.story.faith_rite=="silence" and g.state.story.epilogue)
	var xp: int = g.state.xp
	var gold: int = g.state.inventory.gold
	g.choose_dialog("march:faith_prayer")
	assert(g.state.xp==xp and g.state.inventory.gold==gold and g.state.story.faith_rite=="silence")
	assert(g.save_game() and g.load_game() and g.state.story.faith_done)
	assert(g.march.objective().text.begins_with("All March quests complete") and not g.march.objective().has("pos"))
	g.ui.tick(0)
	g.ui.show_map()
	await g.capture("18-march-quests-complete")
	# Nera has an authored friendship conversation, accessible from every branch.
	g.talk("nera")
	choose(g,"personal:entry:nera")
	assert(g.modal=="dialog" and g.ui.dialog_body.text.contains("My husband died"))
	await g.capture("18-nera-friendship")
	g.choose_dialog("march:medicine")
	choose(g,"march:nera_personal")
	assert(g.ui.dialog_body.text.contains("My husband died"))
	print("QUEST ACCESS PASS: exact bridge report/E interaction; real-wall occlusion; both votives, tablets, beds and bell through normal focus/E; remaining faith quest completed through visible Anselm choices, save/load and one-time rewards; Nera friendship reachable from aftermath/patients")
	g.get_tree().quit()

func choose(g: Node, action: String) -> void:
	var index: int = g.ui.current_choices.find_custom(func(c): return c.action==action)
	assert(index>=0 and index<3,"Required dialogue choice must be visible: "+action)
	g.ui.choose(index)
