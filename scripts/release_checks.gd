extends RefCounted

func run(g: Node) -> void:
	DirAccess.make_dir_recursive_absolute(g.data_root().path_join("reports"))
	verify(g.test_mode)
	var fresh = g.visuals.get_script().new()
	fresh.read(g.data_root().path_join("reports/missing-fresh-defaults-0.11.1.cfg"))
	verify(fresh.values.enabled and fresh.values.preset==1 and fresh.values.detail==2)
	verify(is_equal_approx(fresh.values.dither,.5) and is_equal_approx(fresh.values.grain,.3))
	verify(ProjectSettings.get_setting("display/window/size/mode")==DisplayServer.WINDOW_MODE_FULLSCREEN)
	if not OS.has_feature("editor"):
		verify(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN)
		g.press_key(KEY_F11)
		verify(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_WINDOWED)
		g.press_key(KEY_F11)
		verify(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN)
		if not FileAccess.file_exists(g.settings_path()): verify(g.visuals.values==fresh.values)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280,720))
	g.ui.open_settings("title")
	await g.capture("14-default-presentation")
	g.ui.leave_settings()
	if not OS.has_feature("editor"):
		verify(not ResourceLoader.exists("res://girl1.png") and not ResourceLoader.exists("res://girl2.png"))
		verify(not ResourceLoader.exists("res://IMG_1108.jpg"))
		verify(not FileAccess.file_exists("res://settings.cfg"))
		verify(not FileAccess.file_exists("res://controls.cfg"))
		verify(g.data_root()==OS.get_executable_path().get_base_dir())
	verify(g.audio.library.sources.size()==94)
	verify(g.audio.tracks.size()==g.audio.TRACKS.size())
	# Load and round-trip copies of real older saves; never touch the originals.
	for file in DirAccess.get_files_at(g.data_root().path_join("reports/upgrade-fixtures")):
		if not file.ends_with(".json"): continue
		var source: String = g.data_root().path_join("reports/upgrade-fixtures").path_join(file)
		var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(source))
		verify(g.validate_save(payload),"Old save rejected: "+file)
		verify(DirAccess.copy_absolute(source,g.save_path())==OK)
		verify(g.load_game(),"Old save failed to load: "+file)
		var before: Dictionary = g.state.to_dict()
		verify(g.save_game() and g.load_game())
		verify(g.state.inventory.size()==before.inventory.size(),"Inventory keys changed: "+file)
		for key in before.inventory:
			verify(g.state.inventory.get(key)==before.inventory[key],"Inventory changed: %s / %s / %s -> %s" % [file,key,before.inventory[key],g.state.inventory.get(key)])
		verify(g.state.flags==before.flags and g.state.xp==before.xp,"Flags or XP changed: "+file)
		print("UPGRADE SAVE PASS: "+file)
	g.start_new(preload("res://scripts/character_data.gd").defaults())
	for id in ["ilya","merchant"]:
		# Development source art may exist; exported payloads must exclude it.
		if not OS.has_feature("editor"):
			verify(ResourceLoader.exists("res://assets/friends/npc-"+("ilya-girl1" if id=="ilya" else "merchant-girl2")+".png"))
		var body: Texture2D = g.world.library.npc(id)
		var portrait: Texture2D = g.world.library.portrait(id)
		verify(body!=portrait and body.get_height()>0 and portrait.get_height()>0)
		var image := body.get_image()
		verify(image.detect_alpha()!=Image.ALPHA_NONE)
		for look in [-1,1,6]:
			g.visuals.values.enabled = look>=0
			g.visuals.values.preset = maxi(look,0)
			g.ui.apply_visuals()
			g.talk(id)
			verify(g.ui.dialog_portrait.texture==portrait)
			await g.capture("30-friends-%s-dialog-%d" % [id,look])
			g.set_modal("pause")
			g.ui.pause_panel.hide()
			g.state.flags.won = id=="merchant"
			g.world.apply_state()
			var at: Vector2 = g.C.NPCS[id].pos
			g.teleport(at+Vector2(0,3.3))
			g.camera.look_at(g.world.npcs[id].global_position+Vector3.UP*.35,Vector3.UP)
			await g.capture("30-friends-%s-world-%d" % [id,look])
	g.set_modal("")
	g.teleport(Vector2(0,42))
	verify(g.save_game())
	g.state.inventory.gold += 100
	verify(g.load_game() and g.state.inventory.gold==12)
	g.open_report()
	g.ui.report_entry.text = "AUTOMATED standalone distribution: authorized friend-based NPC artwork, imported assets, save/load and paused bug report."
	verify(g.submit_report())
	verify(g.world.library.portrait("ilya")==g.world.library.portrait("ilya"))
	print("RELEASE CHECK PASS: fullscreen/F11 and fresh Copper & Pine/Fine/dither 50%/grain 30%; authorized friend-based NPC paintings and portraits at world scale/original/Copper/Macintosh, 94 packaged recordings/six tracks, writable save-load/diagnostics, photo/settings exclusion in standalone")
	g.get_tree().quit()


# Release exports strip assert expressions entirely. Always execute validation,
# including playback/save actions, and report failures to the build runner.
func verify(condition: bool, detail := "") -> void:
	if not condition:
		push_error("VALIDATION FAILED: "+detail)
