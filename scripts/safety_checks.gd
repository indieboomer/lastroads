extends RefCounted

func remove_test_files(g: Node) -> void:
	assert(g.test_mode and g.save_path().replace("\\","/").contains("/reports/"))
	var paths: Array[String] = [g.save_path()]
	paths.append_array(g.saves.auto_paths())
	for path in paths:
		for suffix in ["",".bak",".tmp",".bak.tmp"]:
			if FileAccess.file_exists(path+suffix): assert(DirAccess.remove_absolute(path+suffix)==OK)

func run(g: Node) -> void:
	g.start_new()
	for enemy in g.enemies: enemy.queue_free()
	g.enemies.clear()
	g.set_modal("")
	for i in range(40): await g.get_tree().physics_frame
	g.set_physics_process(false)
	assert(g.player.is_on_floor() and g.saves.safe())
	remove_test_files(g)
	g.saves.reset()
	assert(not g.saves.has_resume())
	g.state.xp = 21
	assert(g.save_game())
	var manual: PackedByteArray = FileAccess.get_file_as_bytes(g.save_path())
	for xp in [42,63,84,105]:
		g.state.xp = xp
		assert(g.saves.save_auto("Rotation test"))
	assert(FileAccess.get_file_as_bytes(g.save_path())==manual,"Automatic saves must never replace the manual slot")
	var values: Array = []
	for path in g.saves.auto_paths(): values.append(int(g.saves.read_valid(path).state.xp))
	values.sort()
	assert(values==[63,84,105],"Three rotating slots retain the latest checkpoints")
	assert(g.saves.resume_info().kind=="auto")
	g.state.xp = 120
	assert(g.save_game())
	assert(g.saves.read_valid(g.save_path()+".bak").state.xp==21)
	assert(g.saves.resume_info().kind=="manual")
	# Pending progress waits through menus and combat, then saves in safety.
	g.saves.request("Combat deferral")
	g.set_modal("pause")
	g.saves.tick(3)
	assert(not g.saves.pending.is_empty())
	g.set_modal("")
	var guard: Node = g.spawn_enemy("save_safety_guard","bandit",Vector2(g.player.position.x,g.player.position.z)+Vector2(0,8))
	g.saves.tick(3)
	assert(not g.saves.pending.is_empty())
	guard.hit(1000,true,false)
	g.saves.tick(.01)
	assert(g.saves.pending.is_empty())
	# Actual resume restores the freshest checkpoint. F9 keeps manual semantics.
	var newest: Dictionary = g.saves.resume_info()
	var auto_xp: int = int(g.state.xp)
	assert(newest.kind=="auto")
	g.continue_game()
	assert(g.state.xp==auto_xp and g.started and g.modal=="")
	assert(g.load_game() and g.state.xp==120)
	g.set_physics_process(false)
	var broken := FileAccess.open(g.save_path(),FileAccess.WRITE)
	broken.store_string("deliberately broken JSON")
	broken.close()
	assert(g.load_game() and g.state.xp==21,"F9 recovers an intact manual backup without mutating the damaged primary")
	assert(FileAccess.get_file_as_string(g.save_path())=="deliberately broken JSON")
	assert(g.saves.resume_info().recovered)
	# A rejected new payload cannot overwrite either existing primary or backup.
	var before_backup := FileAccess.get_file_as_bytes(g.save_path()+".bak")
	var bad: Dictionary = g.snapshot()
	bad.state.flags.accepted = "wrong type"
	assert(not g.saves.write(g.save_path(),bad).ok)
	assert(FileAccess.get_file_as_bytes(g.save_path()+".bak")==before_backup)
	# A later legitimate save must not copy a damaged primary over its healthy backup.
	g.state.xp = 200
	assert(g.save_game())
	assert(FileAccess.get_file_as_bytes(g.save_path()+".bak")==before_backup)
	broken = FileAccess.open(g.save_path(),FileAccess.WRITE)
	broken.store_string("broken primary again")
	broken.close()
	# If every primary is damaged, resume still offers a valid backup.
	for path in g.saves.auto_paths():
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string("broken checkpoint")
		file.close()
	var recovered: Dictionary = g.saves.resume_info()
	assert(recovered.path.ends_with(".bak") and g.load_game(recovered.path))
	# Save names stay inside their own solo/co-op namespace.
	var solo_paths: Array = g.saves.auto_paths()
	g.coop.active = true
	g.coop.is_host = true
	var host_paths: Array = g.saves.auto_paths()
	g.coop.is_host = false
	var visitor_paths: Array = g.saves.auto_paths()
	assert(host_paths!=solo_paths and visitor_paths!=host_paths)
	g.coop.active = false
	g.coop.is_host = false
	g.set_modal("pause")
	assert(not g.ui.checkpoint_button.disabled)
	if DisplayServer.get_name()!="headless": await g.capture("35-save-recovery-menu")
	assert(g.save_game())
	print("SAFETY PASS: validated replacement/backups, three independent autosave slots, newest resume/manual F9, damaged-primary recovery, rejected-payload protection, combat/menu deferral, co-op isolation")
	g.get_tree().quit()
