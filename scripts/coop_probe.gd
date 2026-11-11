extends RefCounted

func run(g: Node) -> void:
	var role := "host"
	var slot := 0
	var port := 29141
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="): role = arg.trim_prefix("--role=")
		if arg.begins_with("--slot="): slot = int(arg.trim_prefix("--slot="))
		if arg.begins_with("--port="): port = int(arg.trim_prefix("--port="))
	var session = g.coop
	var profile: Dictionary = session.Data.defaults()
	profile.name = "Coop probe "+str(slot)+" / "+str(port)
	profile.profession_id = session.Data.PROFESSIONS[slot%4].id
	if slot%2==1: profile.gender = "woman"; profile.presentation = 1
	var origin: Dictionary = session.Data.ORIGINS[slot%6]
	profile.origin_id = origin.id; profile.species_id = origin.species; profile.heritage_id = origin.heritage
	assert(session.prepare("host_lan" if role=="host" else "join_lan",profile,session.COLORS[slot],"127.0.0.1",port)==OK)
	g.set_physics_process(false)
	if role=="host":
		var marker := FileAccess.open(g.data_root().path_join("reports/coop/listening-"+str(port)+".txt"),FileAccess.WRITE)
		marker.store_string("ready")
		marker.close()
	# The host remains in a menu while clients join: networking must not pause.
	if role=="host": g.set_modal("pause")
	var started := Time.get_ticks_msec()/1000.0
	var largest := 0
	var changed_world := false
	var damage_checked := false
	var attacker_checked := false
	var weeper_released := false
	var personal_kept := true
	var original_profile: Dictionary = profile.duplicate(true)
	var report := {"incoming_damage":false,"role":role,"slot":slot,"passed":false,"max_party":0,"world_synced":false,"enemy_sync":false,"personal_profile":false,"save_isolated":false}
	while Time.get_ticks_msec()/1000.0-started<(34 if role=="host" else 29):
		await g.get_tree().process_frame
		g.set_physics_process(false)
		largest = maxi(largest,session.roster.size())
		if session.active and session.session_ready:
			personal_kept = personal_kept and g.state.profile==original_profile
			if role=="host" and largest==4 and not changed_world:
				g.state.flags.accepted = true
				g.state.story.started = true
				g.state.story.patient = "raisa"
				g.state.day_clock = 22.0
				g.state.weeper_world.pitchbound_seen = true
				g.state.weeper_world.boughstalker_seen = true
				g.state.weeper_world.introduced = true
				g.state.weeper_world.intro_site = "east_graves"
				g.state.weeper_world.selected = ["east_graves"]
				g.spawn_enemy("weeper_intro_east_graves","hollow_weeper",preload("res://scripts/weeper_sites.gd").get_site("east_graves").pos+Vector2(0,3.5))
				changed_world = true
			if role!="host" and g.state.flags.accepted and g.state.story.patient=="raisa":
				report.world_synced = g.state.weeper_world.introduced and g.state.weeper_world.intro_site=="east_graves"
				report.weeper_frame = g.enemies.any(func(enemy): return enemy.kind=="hollow_weeper" and enemy.id=="weeper_intro_east_graves")
				g.player.position = g.player.position.move_toward(g.C.ground(Vector2(25+slot,40),.3),.15)
			if role=="host" and changed_world and not damage_checked:
				var foe: Node = g.spawn_enemy("defence_coop_probe","pitchbound",Vector2(27,37))
				foe.set_meta("coop_probe",true)
				g.spawn_enemy("defence_weeper_probe","hollow_weeper",Vector2(27,32))
				damage_checked = true
			if role=="host" and damage_checked and not weeper_released and Time.get_ticks_msec()/1000.0-started>20:
				for foe in g.enemies:
					if foe.id=="defence_weeper_probe":
						foe.scream_direction = Vector3.BACK
						var visitors: Array = foe.all_targets().filter(func(target): return target.id!=session.transport.local_id)
						if visitors.size()!=3 or not visitors.all(func(target): return foe.in_scream(target.p) and g.line_clear(foe.position+Vector3.UP*1.8,target.eye)): continue
						report.guardian_targets = []
						for target in foe.all_targets(): report.guardian_targets.append({"id":target.id,"p":[target.p.x,target.p.y,target.p.z],"cone":foe.in_scream(target.p),"clear":g.line_clear(foe.position+Vector3.UP*1.8,target.eye)})
						foe.release_scream()
						weeper_released = true
			if role!="host" and report.world_synced and not attacker_checked:
				for foe in g.enemies:
					if foe.id=="defence_coop_probe" and foe.position.distance_to(g.player.position)<3.5:
						foe.hit(12.0,false,false)
						attacker_checked = true
			if role=="host" and damage_checked:
				for foe in g.enemies:
					if foe.id=="defence_coop_probe": session.tick_enemy(foe,.05)
				for foe in g.enemies:
					if foe.id=="defence_coop_probe" and foe.health<foe.spec.hp: report.enemy_sync = true
			if role!="host" and report.world_synced:
				for foe in g.enemies:
					if foe.id=="defence_coop_probe" and foe.health<foe.spec.hp: report.enemy_sync = true
			if role!="host" and g.state.events.any(func(event): return str(event.event).begins_with("incoming:")): report.incoming_damage = true
			if role!="host": report.guardian_damage = g.state.events.any(func(event): return str(event.event).begins_with("incoming:hollow_weeper:"))
			if slot==1 and report.world_synced:
				report.host_runs_in_menu = not g.get_tree().paused
			if role=="host" and largest==4 and report.enemy_sync and Time.get_ticks_msec()/1000.0-started>28: break
			if role!="host" and report.world_synced and report.enemy_sync and Time.get_ticks_msec()/1000.0-started>23: break
		elif not session.active: break
	report.attacker = attacker_checked
	report.position = [g.player.position.x,g.player.position.y,g.player.position.z]
	for foe in g.enemies:
		if foe.id=="defence_coop_probe": report.enemy = {"health":foe.health,"phase":foe.phase,"p":[foe.position.x,foe.position.y,foe.position.z]}
	report.max_party = largest
	report.personal_profile = personal_kept
	report.save_isolated = not session.active or g.save_path().contains("/coop/")
	report.world_synced = report.world_synced or changed_world
	report.passed = largest==4 and report.world_synced and report.enemy_sync and personal_kept and report.save_isolated
	if slot==4: report.passed = largest==0 # Fifth connection must never enter the roster.
	var file := FileAccess.open(g.data_root().path_join("reports/coop/probe-"+str(slot)+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("COOP PROBE ",JSON.stringify(report))
	if session.active: session.disconnect_session("Co-op probe completed.")
	g.get_tree().quit(0 if report.passed else 1)
