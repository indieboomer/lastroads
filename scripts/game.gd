extends Node3D

signal loading_complete

func loading_stage(text: String) -> void:
	var loader := get_tree().root.get_node_or_null("LoadingScreen")
	if loader: await loader.present(text)

const C = preload("res://scripts/content.gd")
const State = preload("res://scripts/state.gd")
const World = preload("res://scripts/world.gd")
const Interface = preload("res://scripts/interface.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Wilderness = preload("res://scripts/wilderness.gd")
var wilderness_encounters: Array = []
var road_return_clock := 0.0
var journey = preload("res://scripts/journey.gd").new()
const Narrative = preload("res://scripts/narrative.gd")
const Audio = preload("res://scripts/audio.gd")
var controls = preload("res://scripts/input_controls.gd").new()
var controls_view: CanvasLayer
var visuals = preload("res://scripts/visual_settings.gd").new()
var saves = preload("res://scripts/save_slots.gd").new()
var state = State.new()
var weeper_director: Node
var player_stagger := 0.0
var coop: Node
var woods = preload("res://scripts/woods.gd").new()
var side_quests = preload("res://scripts/side_quests.gd").new()
var march = preload("res://scripts/march.gd").new()
var combat = preload("res://scripts/profession_combat.gd").new()
var ranger = preload("res://scripts/ranger_combat.gd").new()
var relationship = preload("res://scripts/relationships.gd").new()
var world: Node3D
var ui: CanvasLayer
var audio: Node
var weather: Node3D
var player: CharacterBody3D
var player_collision: CollisionShape3D
var eye_height := C.EYE_HEIGHT
var camera: Camera3D
var lantern: OmniLight3D
var torch_light: OmniLight3D
var torch_equipped := false
var enemies: Array = []
var started := false
var modal := ""
var reporting := false
var attack_clock := 0.0
var swing := 0.0
var blocking := false
var block_age := 0.0
var dialogue_id := ""
var shop_owner := ""
var report_image: Image
var report_snapshot: Dictionary
var location_id := "inn"
var test_mode := false
var night_announced := false
var fire_tick := 0.0
var tutorial_timer := 0.0
var route_active := false
var route_goal := Vector2.ZERO
var route_distance := 0.0
var bot_active := false
var bot_heavy_count := 0
var swing_style := 0
var swing_duration := 0.27

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	saves.game = self
	combat.game = self
	ranger.game = self
	relationship.game = self
	woods.game = self
	side_quests.game = self
	march.game = self
	journey.game = self
	test_mode = Array(OS.get_cmdline_user_args()).any(func(arg): return arg in ["--grass-check","--quest-access-check","--march-field-check","--field-check","--architecture-check","--release-check","--profession-check","--profession-encounters","--sound-check","--terrain-check","--living-check","--march-check","--march-route","--production-check","--smoke","--tour","--route","--combat-check","--feedback-check","--visual-check","--forest-check","--survival-check"])
	test_mode = Array(OS.get_cmdline_user_args()).any(func(arg): return arg in ["--safety-check","--journal-check","--level-check","--woods-check","--woods-preview","--woods-capture","--woods-route"]) or test_mode
	test_mode = "--side-quest-check" in OS.get_cmdline_user_args() or test_mode
	test_mode = "--weeper-check" in OS.get_cmdline_user_args() or test_mode
	test_mode = "--godrays-check" in OS.get_cmdline_user_args() or test_mode
	test_mode = "--romance-check" in OS.get_cmdline_user_args() or "--coop-check" in OS.get_cmdline_user_args() or "--coop-probe" in OS.get_cmdline_user_args() or test_mode
	test_mode = test_mode or "--wilderness-check" in OS.get_cmdline_user_args() or "--inventory-check" in OS.get_cmdline_user_args() or "--ranger-check" in OS.get_cmdline_user_args()
	test_mode = test_mode or "--journey-check" in OS.get_cmdline_user_args()
	test_mode = test_mode or "--controls-check" in OS.get_cmdline_user_args()
	controls.setup(self)
	visuals.read(settings_path())
	coop = preload("res://scripts/coop_session.gd").new()
	coop.game = self
	coop.name = "Coop"
	add_child(coop)
	world = World.new()
	world.game = self
	add_child(world)
	world.build()
	await loading_stage("Preparing the traveller…")
	make_player()
	audio = Audio.new()
	audio.game = self
	add_child(audio)
	ui = Interface.new()
	ui.game = self
	add_child(ui)
	ui.build()
	controls_view = preload("res://scripts/controls_view.gd").new()
	controls_view.game = self
	controls.view = controls_view
	add_child(controls_view)
	controls_view.build()
	ui.coop_menu = preload("res://scripts/coop_menu.gd").new()
	ui.coop_menu.game = self
	ui.coop_menu.ui = ui
	ui.add_child(ui.coop_menu)
	ui.coop_menu.build()
	await loading_stage("Gathering travellers and creatures…")
	ui.title_continue.disabled = not saves.has_resume()
	spawn_enemies()
	await loading_stage("Lighting the sky…")
	weather = preload("res://scripts/weather.gd").new()
	weather.game = self
	add_child(weather)
	weather.build()
	weeper_director = preload("res://scripts/weeper_director.gd").new()
	weeper_director.game = self
	add_child(weeper_director)
	get_tree().paused = true
	loading_complete.emit()
	if "--controls-check" in OS.get_cmdline_user_args():
		await preload("res://scripts/controls_checks.gd").new().run(self)
	elif "--journey-check" in OS.get_cmdline_user_args():
		await preload("res://scripts/journey_checks.gd").new().run(self)
	elif "--weeper-check" in OS.get_cmdline_user_args():
		call_deferred("weeper_check")
	elif "--godrays-check" in OS.get_cmdline_user_args():
		call_deferred("godrays_check")
	elif "--coop-check" in OS.get_cmdline_user_args():
		call_deferred("coop_check")
	elif "--coop-probe" in OS.get_cmdline_user_args():
		call_deferred("coop_probe")
	elif "--romance-check" in OS.get_cmdline_user_args():
		call_deferred("romance_check")
	elif "--ranger-check" in OS.get_cmdline_user_args():
		call_deferred("ranger_check")
	elif "--inventory-check" in OS.get_cmdline_user_args():
		call_deferred("inventory_check")
	elif "--wilderness-check" in OS.get_cmdline_user_args():
		call_deferred("wilderness_check")
	elif "--grass-check" in OS.get_cmdline_user_args():
		call_deferred("grass_check")
	elif "--safety-check" in OS.get_cmdline_user_args():
		call_deferred("safety_check")
	elif "--journal-check" in OS.get_cmdline_user_args():
		call_deferred("journal_check")
	elif "--level-check" in OS.get_cmdline_user_args():
		call_deferred("level_check")
	elif "--woods-check" in OS.get_cmdline_user_args():
		call_deferred("woods_check")
	elif "--woods-capture" in OS.get_cmdline_user_args():
		call_deferred("woods_capture")
	elif "--woods-route" in OS.get_cmdline_user_args():
		call_deferred("woods_route")
	elif "--woods-preview" in OS.get_cmdline_user_args():
		call_deferred("woods_preview")
	elif "--side-quest-check" in OS.get_cmdline_user_args():
		call_deferred("side_quest_check")
	elif "--quest-access-check" in OS.get_cmdline_user_args():
		call_deferred("quest_access_check")
	elif "--march-field-check" in OS.get_cmdline_user_args():
		call_deferred("march_field_check")
	elif "--field-check" in OS.get_cmdline_user_args():
		call_deferred("field_check")
	elif "--architecture-check" in OS.get_cmdline_user_args():
		call_deferred("architecture_check")
	elif "--release-check" in OS.get_cmdline_user_args():
		call_deferred("release_check")
	elif "--profession-check" in OS.get_cmdline_user_args():
		call_deferred("profession_check")
	elif "--profession-encounters" in OS.get_cmdline_user_args():
		call_deferred("profession_encounters")
	elif "--sound-check" in OS.get_cmdline_user_args():
		call_deferred("sound_check")
	elif "--terrain-check" in OS.get_cmdline_user_args():
		call_deferred("terrain_check")
	elif "--living-check" in OS.get_cmdline_user_args():
		call_deferred("living_check")
	elif "--march-check" in OS.get_cmdline_user_args():
		call_deferred("march_check")
	elif "--march-route" in OS.get_cmdline_user_args():
		call_deferred("march_route")
	elif "--production-check" in OS.get_cmdline_user_args():
		call_deferred("production_check")
	elif "--smoke" in OS.get_cmdline_user_args():
		call_deferred("smoke")
	elif "--tour" in OS.get_cmdline_user_args():
		call_deferred("tour")
	elif "--route" in OS.get_cmdline_user_args():
		call_deferred("route_test")
	elif "--combat-check" in OS.get_cmdline_user_args():
		call_deferred("combat_test")
	elif "--survival-check" in OS.get_cmdline_user_args():
		call_deferred("survival_test")
	elif "--forest-check" in OS.get_cmdline_user_args():
		call_deferred("forest_test")
	elif "--visual-check" in OS.get_cmdline_user_args():
		call_deferred("visual_test")
	elif "--feedback-check" in OS.get_cmdline_user_args():
		call_deferred("feedback_test")

func make_player() -> void:
	player = CharacterBody3D.new()
	player.collision_layer = 4
	player.collision_mask = 1 | 2
	player.floor_snap_length = 0.4
	add_child(player)
	var hit := CollisionShape3D.new()
	player_collision = hit
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = C.PLAYER_HEIGHT
	hit.shape = capsule
	hit.position.y = C.PLAYER_HEIGHT*0.5
	player.add_child(hit)
	player.position = C.ground(Vector2(0,42),0.5)
	camera = Camera3D.new()
	player.add_child(camera)
	camera.position.y = C.EYE_HEIGHT
	camera.fov = 76
	camera.far = 310
	camera.near = 0.06
	lantern = OmniLight3D.new()
	camera.add_child(lantern)
	lantern.position = Vector3(0.3,-0.25,-0.3)
	lantern.light_color = Color("ffca86")
	lantern.light_energy = 1.4
	lantern.omni_range = 11
	torch_light = OmniLight3D.new()
	camera.add_child(torch_light)
	torch_light.position = Vector3(-0.45,-0.15,-0.4)
	torch_light.light_color = Color("ffac53")
	torch_light.light_energy = 1.6
	torch_light.omni_range = 10
	torch_light.hide()

func spawn_enemies() -> void:
	for e in enemies:
		e.hide()
		e.collision_layer = 0
		e.queue_free()
	enemies.clear()
	for entry in C.ENCOUNTERS:
		spawn_enemy(entry[0],entry[1],entry[2])
	if wilderness_encounters.is_empty():
		wilderness_encounters = Wilderness.encounters(world)
		for entry in wilderness_encounters:
			if entry[1] in ["pitchbound","boughstalker"]:
				preload("res://scripts/wilderness_model.gd").warning(world,entry[2],entry[1]=="boughstalker")
	for entry in wilderness_encounters: spawn_enemy(entry[0],entry[1],entry[2])
	for id in state.enemies:
		if id in enemies.map(func(e): return e.id):
			continue
		var record: Dictionary = state.enemies[id]
		if record.get("kind","") in C.ENEMY_TYPES:
			spawn_enemy(id,record.kind,Vector2(record.position[0],record.position[2]))

func spawn_enemy(id: String, kind: String, at: Vector2) -> Node:
	for old in enemies:
		if old.id==id:
			return old
	var e: Node = preload("res://scripts/hollow_weeper.gd").new() if kind=="hollow_weeper" else Enemy.new()
	add_child(e)
	e.setup(self,id,kind,C.ground(at,0.25))
	enemies.append(e)
	return e

func apply_player_stature() -> void:
	var size: Dictionary = preload("res://scripts/character_data.gd").stature(state.profile.species_id)
	eye_height = size.eye
	camera.position.y = eye_height
	var capsule := player_collision.shape as CapsuleShape3D
	capsule.height = size.body
	player_collision.position.y = size.body*0.5

func start_new(profile: Dictionary = {}) -> void:
	audio.reset_effects()
	combat.reset()
	relationship.cancel()
	state = State.new()
	saves.reset()
	ui.reset_progression()
	if weeper_director: weeper_director.announced = false
	player_stagger = 0.0
	if not profile.is_empty():
		if not preload("res://scripts/character_data.gd").valid(profile): return
		state.create_character(profile)
	apply_player_stature()
	world.ambient.reset()
	ranger.reset()
	lantern.hide()
	torch_equipped = false
	torch_light.hide()
	world.clear_impacts()
	world.apply_state()
	spawn_enemies()
	player.position = C.ground(Vector2(0,42),0.5)
	player.velocity = Vector3.ZERO
	player.rotation.y = 0.55
	camera.rotation.x = -0.015
	started = true
	reporting = false
	modal = ""
	attack_clock = 0
	swing = 0
	blocking = false
	night_announced = false
	ui.title.hide()
	ui.close_modals()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	state.log_event("new_journey")
	saves.request("A new journey")
	state.discovered.inn = true
	journey.reset()
	ui.discover("Wayfarer's Rest","Talk to Mara, by the lantern in the inn yard")
	tutorial_timer = 22
	message("%s to talk / %s journal / %s quick slots and road actions" % [controls.hint("interact"),controls.hint("map"),controls.hint("tools")],8)

func continue_game() -> void:
	var latest: Dictionary = saves.resume_info()
	if latest.is_empty() or not load_game(latest.path):
		ui.title_continue.text = "Save unavailable — start new"
		return
	started = true
	ui.title.hide()
	set_modal("")

func to_title() -> void:
	if coop!=null and coop.active:
		coop.disconnect_session()
		return
	started = false
	set_modal("")
	get_tree().paused = true
	ui.title.show()
	ui.title_continue.disabled = not saves.has_resume()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_modal(kind: String) -> void:
	if kind=="" and modal!="" and audio: audio.throttled("back_close","back_close",.15,Vector3.INF,true)
	if kind!="dialog": march.pending_verdict = ""
	if kind not in ["dialog","intimacy","keepsake"]:
		relationship.cancel()
	ui.close_modals()
	modal = kind
	ui.modal_type = kind
	get_tree().paused = (reporting or kind!="" or not started) and not coop.active
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if started and kind=="" and not reporting else Input.MOUSE_MODE_VISIBLE
	blocking = false
	if kind=="pause":
		ui.checkpoint_button.disabled = not saves.has_resume()
		ui.pause_panel.show()
	elif kind=="inventory":
		state.pack.sync(state.inventory)
		ui.backpack.show()

func _input(ev: InputEvent) -> void:
	if controls.handle_input(ev): get_viewport().set_input_as_handled()

func _process(dt: float) -> void:
	if ui: controls.menu_tick(dt)
	if started and (coop.active or (modal=="" and not reporting)):
		state.weapon_resin_seconds = maxf(0,state.weapon_resin_seconds-dt)
	if ui and started and not reporting:
		relationship.tick(dt)
		ui.tick(dt)

func _physics_process(dt: float) -> void:
	if not started: return
	if coop.active and not coop.session_ready: return
	if modal!="" or reporting:
		coop.host_while_busy(dt)
		return
	for key in state.ability_cooldowns:
		state.ability_cooldowns[key] = maxf(0,state.ability_cooldowns[key]-dt)
	state.mana = minf(state.max_mana,state.mana+dt*0.8)
	if not coop.active or coop.is_host:
		march.tick(dt)
		woods.tick(dt)
	state.elapsed += dt
	road_return_clock += dt
	if road_return_clock>=10.0:
		road_return_clock = 0.0
		preload("res://scripts/road_returns.gd").tick(self)
	state.day_clock = fposmod(state.day_clock+dt/60.0,24)
	attack_clock = maxf(0,attack_clock-dt)
	swing = maxf(0,swing-dt)
	tutorial_timer = maxf(0,tutorial_timer-dt)
	var was_blocking := blocking
	blocking = state.profile.profession_id=="warrior" and controls.held("defend") and not offhand_busy()
	var bot_foe: Node = null
	if bot_active:
		bot_foe = bot_target()
		blocking = bot_foe!=null and bot_foe.phase=="windup" and bot_foe.clock>bot_foe.spec.windup*0.65
	block_age = block_age+dt if blocking and was_blocking else 0.0
	controls.look(dt)
	var input := controls.movement()
	var sprint: bool = controls.held("sprint") and state.stamina>1 and input.length()>0 and not blocking
	var road_stride: bool = journey.stride(dt,sprint)
	var sprint_cost := 10.0 if journey.stride_clock>0 else 20.0
	state.stamina = clampf(state.stamina+(-sprint_cost if sprint and not road_stride else 4 if road_stride else 18*weather.stamina_factor())*dt,0,100)
	var direction := player.basis*Vector3(input.x,0,input.y)
	if route_active:
		var gap := route_goal-Vector2(player.position.x,player.position.z)
		direction = Vector3(gap.x,0,gap.y).normalized() if gap.length()>0.45 else Vector3.ZERO
	if bot_active and bot_foe:
		var gap: Vector3 = bot_foe.position-player.position
		gap.y = 0
		player.rotation.y = atan2(-gap.x,-gap.z)
		camera.rotation.x = 0
		direction = gap.normalized() if gap.length()>2.3 else Vector3.ZERO
		if not blocking and gap.length()<3.0:
			var heavy: bool = state.stamina>60 and bot_foe.kind!="guardian"
			if attack_clock<=0:
				bot_heavy_count += 1 if heavy else 0
			attack(heavy)
	player_stagger = maxf(0,player_stagger-dt)
	var speed := 6.0 if sprint else 3.8
	if player_stagger>0: speed *= .45
	if ranger.active():
		ranger.tick(dt)
		if state.ranger.reload_left>0: speed *= .5
	speed *= 1.0-clampf((state.cold-65)/35.0,0,1)*0.10
	if blocking:
		speed *= 0.55
	player.velocity.x = direction.x*speed
	player.velocity.z = direction.z*speed
	player.velocity.y -= 21*dt
	player.move_and_slide()
	player.position.x = clampf(player.position.x,-235,235)
	player.position.z = clampf(player.position.z,-1845,85)
	if player.position.y<C.height_at(player.position.x,player.position.z)-12:
		player.position = C.ground(Vector2(0,42),1.0)
		message("The road's ember catches you. Returned to the inn.")
	camera.position.y = eye_height + sin(state.elapsed*(10 if sprint else 7))*minf(input.length()*0.025,0.025)
	camera.fov = lerpf(camera.fov,80 if sprint else 76,dt*5)
	if not route_active:
		for e in enemies:
			coop.tick_enemy(e,dt)
	combat.tick(dt)
	world.tick(dt)
	weather.tick(dt)
	torch_light.light_energy = 1.6+sin(state.weather.clock*9.0)*0.14
	audio.tick(dt,input.length()>0.1 and player.is_on_floor(),sprint)
	update_location()
	journey.tick(dt)
	saves.tick(dt)
	if not coop.active or coop.is_host: update_defence(dt)
	if state.day_clock>=18 and not night_announced:
		night_announced = true
		message("Dusk settles over the Hollow. Carry light. Fire slows the unremembered.",8)
		state.log_event("dusk")
	fire_tick += dt
	if fire_tick>=1.0:
		fire_tick = 0
		if fire_distance(player.position)<4.5 and not threats_near(player.position,12):
			state.health = minf(state.max_health,state.health+1.5)
		for fire in state.fires:
			fire.fuel = maxf(0,fire.fuel-1)
		if state.fires.any(func(f): return f.fuel==0):
			state.fires = state.fires.filter(func(f): return f.fuel>0)
			world.apply_state()

func message(text: String, duration := 4.0) -> void:
	if ui:
		ui.toast_message(text,duration)

func line_clear(a: Vector3, b: Vector3) -> bool:
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1)).is_empty()

func near_safety() -> bool:
	var p := Vector2(player.position.x,player.position.z)
	return state.woods.started and p.distance_to(Vector2(0,-1100))<38 or p.distance_to(Vector2(0,30))<37 or state.story.briefed and p.distance_to(Vector2(-65,-530))<23 and (state.story.verdict!="trial" or state.story.defense_done)

func fire_distance(at: Vector3) -> float:
	var closest := 9999.0
	for fire in world.fire_nodes:
		if is_instance_valid(fire.node):
			closest = minf(closest,at.distance_to(fire.node.global_position))
	return closest

func forest_light_protection(night_only := true) -> bool:
	if night_only and state.day_clock>=7 and state.day_clock<18: return false
	if coop.active and coop.target_peer!=0:
		if not coop.poses[coop.target_peer].light: return false
	elif not torch_equipped and not lantern.visible: return false
	var p := Vector2(player.position.x,player.position.z)
	if C.distance_to_road(p)<4.0 or near_safety() or fire_distance(player.global_position)<8.0: return true
	if not world.outside_buildings(p,8.0): return true
	for site in C.SITES.values():
		if p.distance_to(site.pos)<24.0: return true
	return false

func threats_near(at: Vector3, radius: float) -> bool:
	for e in enemies:
		if not e.dead and e.position.distance_to(at)<radius:
			return true
	return false

func update_location() -> void:
	var closest := location_id
	var distance := 9999.0
	for id in C.SITES:
		var d := Vector2(player.position.x,player.position.z).distance_to(C.SITES[id].pos)
		if d<distance:
			distance = d
			closest = id
	location_id = closest
	ui.location.text = "The Underchapel" if in_crypt() else C.SITES[closest].name if distance<35 else "Old Pine Road"
	if not in_crypt() and distance>=35:
		ui.location.text = Wilderness.LABELS[Wilderness.tier(Vector2(player.position.x,player.position.z),state.day_clock,world)]

	if distance<28 and not state.discovered.has(closest):
		state.discovered[closest] = true
		state.log_event("discovered:"+closest)
		state.xp += 10
		saves.request("A new place discovered")
		ui.discover(C.SITES[closest].name,C.SITES[closest].sub)
		audio.play_effect("quest")

func in_crypt() -> bool:
	return player.position.x>100 and player.position.x<163 and player.position.z<-355 and player.position.z> -430

func target_enemy() -> Node:
	var best: Node = null
	var distance := 16.0
	for e in enemies:
		if e.dead:
			continue
		var diff: Vector3 = e.position+Vector3(0,e.spec.height*0.5,0)-camera.global_position
		if diff.length()<distance and (-camera.global_basis.z).dot(diff.normalized())>0.8:
			distance = diff.length()
			best = e
	return best

func use_ability(secondary: bool) -> void:
	if ranger.active():
		ranger.select("musket" if secondary else "pistol")
		return
	if state.profile.profession_id!="warrior":
		if started and modal=="" and not reporting: combat.cast(secondary)
		return
	if not started or modal!="" or reporting or attack_clock>0: return
	var key := "secondary" if secondary else "primary"
	if state.ability_cooldowns[key]>0:
		message("Recovering: %ds" % ceili(state.ability_cooldowns[key]),2)
		return
	var profession: String = state.profile.profession_id
	var foe: Node = null
	if profession=="warrior":
		if secondary:
			foe = target_enemy()
			if foe==null or foe.position.distance_to(player.position)>3.9 or not line_clear(camera.global_position,foe.position+Vector3.UP):
				message("Driving strike needs a nearby foe in sight."); return
			if state.stamina<25: message("Driving strike needs 25 stamina."); return
			state.stamina -= 25
			foe.hit(state.damage*1.5*(1.1 if state.rank()>=2 else 1.0),true)
			if state.rank()>=4:
				for other in enemies:
					if other!=foe and not other.dead and other.position.distance_to(foe.position)<2.5 and line_clear(camera.global_position,other.position+Vector3.UP): other.hit(state.damage*.65,true)
			state.ability_cooldowns[key] = 5.0
			message("DRIVING STRIKE",2)
		else:
			if state.stamina>=100: message("Your breath is already steady."); return
			state.stamina = minf(100,state.stamina+35)
			if state.rank()>=3: state.health = minf(state.max_health,state.health+12.0)
			state.ability_cooldowns[key] = 20.0
			message("SECOND WIND / 35 stamina",2)
	attack_clock = 0.4
	audio.play_effect("bell" if profession=="cleric" else "swing")
	state.log_event("ability:"+profession+":"+key)

func ability_trail(from: Vector3, to: Vector3, colour: Color) -> void:
	var trail := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,material)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()
	trail.mesh = mesh
	world.add_child(trail)
	trail.add_to_group("combat_fx")
	get_tree().create_timer(0.25,false).timeout.connect(trail.queue_free)

func attack(heavy := false) -> void:
	if ranger.active():
		ranger.attack()
		return
	if state.profile.profession_id!="warrior":
		if started and modal=="" and not reporting and attack_clock<=0:
			if heavy: combat.defend()
			else: combat.basic()
		return
	if attack_clock>0 or not started or modal!="" or reporting:
		return
	if heavy and state.stamina<25:
		message("Too tired for a heavy strike. Lower your shield and recover.")
		return
	if heavy:
		state.stamina -= 25
	attack_clock = 1.1 if heavy else 0.52
	swing = 0.40 if heavy else 0.27
	swing_duration = 0.48 if heavy else 0.36
	swing = swing_duration
	swing_style = randi_range(0,2)
	audio.play_effect("swing")
	state.log_event("heavy_strike" if heavy else "strike")
	var hit_target: Node = null
	var nearest := 3.9 if heavy else 3.3
	for e in enemies:
		if e.dead:
			continue
		var aim: Vector3 = e.position+Vector3(0,minf(1.55,e.spec.height*0.55),0)
		var diff := aim-camera.global_position
		if diff.length()<nearest and (-camera.global_basis.z).dot(diff.normalized())>0.58 and line_clear(camera.global_position,aim):
			nearest = diff.length()
			hit_target = e
	if hit_target:
		hit_target.hit(state.damage*(1.1 if state.rank()>=2 else 1.0)*(1.8 if heavy else 1.0),heavy)
		ui.damage_flash = 0.0

func receive_hit(damage: float, from: Vector3, family: String) -> void:
	if coop.damage_remote(damage,from,family): return
	if (modal!="" or reporting) and not coop.active:
		return
	var toward := (from-player.position).normalized()
	var guarded: bool = state.profile.profession_id=="warrior" and blocking and not offhand_busy() and (-player.basis.z).dot(toward)>0.15
	var weeper_attack: bool = family.begins_with("hollow_weeper")
	var parry: bool = guarded and block_age<0.34 and not weeper_attack
	if guarded:
		damage = damage*(.35 if block_age<.34 else .45) if weeper_attack else 0 if parry else (1 if state.rank()>=5 else 2)
		if family=="pitchbound" and not parry: damage += 5
		audio.play_effect("parry" if parry else "block")
		message("PARRY · the opening is yours" if parry else "Blocked",1.3)
		if parry:
			for e in enemies:
				if not e.dead and e.position.distance_to(from)<0.5:
					e.stun = 1.5
	else:
		audio.play_effect("hurt")
		ui.damage_flash = 0.75
	if state.flags.coat_upgrade and damage>0:
		damage = maxf(1,damage*0.8)
	if combat.protected_at(player.position): damage *= 0.65
	if family=="hollow_weeper" and damage>0:
		player_stagger = .32
		attack_clock = maxf(attack_clock,.32)
	state.health -= damage
	state.log_event("incoming:%s:%d:%s" % [family,damage,"parry" if parry else "block" if guarded else "hit"])
	if state.health<=0:
		if state.inventory.tonic>0:
			state.inventory.tonic -= 1
			state.health = 45
			for e in enemies:
				if e.position.distance_to(player.position)<10:
					e.stun = 2.5
			message("SECOND CHANCE · A tonic pulls you back. Find room to breathe.",6)
			state.log_event("tonic_self_rescue")
		else:
			respawn()

func respawn() -> void:
	state.deaths += 1
	state.health = state.max_health
	state.stamina = 100
	state.inventory.gold = maxi(0,state.inventory.gold-8)
	player.position = C.ground(Vector2(-7,-1081) if state.woods.started and player.position.z< -1005 else Vector2(-65,-514) if state.story.briefed else Vector2(0,42),0.5)
	player.velocity = Vector3.ZERO
	player.rotation.y = 0
	camera.rotation = Vector3.ZERO
	if state.woods.started and player.position.z< -1005:
		message("Hester brings you back to Alderwake. 8 coins lost; all evidence and experience kept.",8)
		state.log_event("respawn_at_alderwake")
		return
	state.log_event("respawn_at_inn")
	message("Nera brings you back to Saint Mere. 8 coins lost; quest records and experience kept." if state.story.briefed else "Mara finds you on the road. 8 coins lost; quest items and experience kept.",8)

func use_item(id: String) -> void:
	if id=="resin_tear":
		if state.inventory.resin_tear<=0: return
		if fire_distance(player.position)>4.5 or threats_near(player.position,16):
			message("Brew Graveward resin beside a safe fire.",4)
			return
		if state.inventory.essence<2:
			message("Graveward resin needs one resin tear and two essence.",4)
			return
		state.inventory.resin_tear -= 1
		state.inventory.essence -= 2
		state.inventory.graveward_resin += 1
		message("Graveward resin brewed. Use it to enchant your weapon for two minutes.",5)
		return
	if id=="graveward_resin":
		if state.inventory.graveward_resin<=0: return
		state.inventory.graveward_resin -= 1
		state.weapon_resin_seconds = 120
		message("GRAVEWARD / Weapon enchanted for 120 seconds.",5)
		return
	# Materials and poisonous plants can be inspected, never consumed as food.
	if id not in ["tonic","bread","berries","mushrooms"]:
		message(state.pack.details(id).use,4)
		return
	if state.inventory[id]<=0:
		message("No %s left." % id)
		return
	if state.health>=state.max_health and id=="tonic":
		message("You are already at full vitality.")
		return
	state.inventory[id] -= 1
	var healing := {"tonic":55,"bread":28,"berries":10,"mushrooms":18}
	state.health = minf(state.max_health,state.health+healing.get(id,0))
	if id=="bread":
		state.stamina = 100
	state.log_event("used:"+id)
	audio.play_effect("tonic_drink" if id=="tonic" else "food_eat")
	message("%s restores %d vitality." % [id.capitalize(),healing.get(id,0)])

func _local_place_fire() -> void:
	if state.inventory.wood<=0:
		message("Find dry wood along the road before making a fire.")
		return
	if in_crypt():
		message("The underchapel has no room for a safe camp. Return to Elian's fire.")
		return
	if fire_distance(player.position)<7:
		message("There is already a fire nearby. R to rest when threats are clear.")
		return
	var at := player.position-player.basis.z*2
	at.y = C.height_at(at.x,at.z)
	if not line_clear(camera.global_position,at+Vector3.UP):
		message("There isn't room for a fire there.")
		return
	state.inventory.wood -= 1
	state.fires.append({"position":[at.x,at.y,at.z],"fuel":240.0})
	world.add_fire(at)
	audio.play_effect("campfire_light")
	state.log_event("campfire_built")
	message("Fire lit for four minutes. Spirits slow in its warmth. R to rest safely.",6)

func _local_rest() -> void:
	if fire_distance(player.position)>4.5:
		message("Find a campfire first. F builds one from dry wood.")
		return
	if threats_near(player.position,16):
		message("You cannot rest while enemies are this close.")
		return
	if state.flags.beacon_lit and not state.flags.won:
		message("Northwatch needs you awake. Finish defending the beacon.")
		return
	state.health = state.max_health
	state.stamina = 100
	state.day_clock = 7.0
	night_announced = false
	state.wetness = 0
	state.cold = 0
	state.mana = state.max_mana
	state.ability_cooldowns = {"primary":0.0,"secondary":0.0,"defensive":0.0}
	state.log_event("safe_rest_to_morning")
	message("You rest by the fire until morning. Vitality and stamina restored.",5)
	audio.play_effect("heal")
	if state.profile.profession_id in ["mage","cleric"]: ui.show_preparation()

func nearest_interaction() -> Dictionary:
	var best := 4.2
	var found: Dictionary = {}
	for id in C.NPCS:
		if not world.npcs[id].visible:
			continue
		var at: Vector3 = world.npcs[id].global_position-Vector3(0,0.125,0)
		var diff := at-camera.global_position
		if diff.length()<best and (-camera.global_basis.z).dot(diff.normalized())>0.25 and line_clear(camera.global_position,at):
			best = diff.length()
			found = {"type":"npc","id":id,"name":C.NPCS[id].name}
	for id in C.OBJECTS:
		if state.taken.has(id):
			continue
		var at := object_interaction_point(id)
		var diff := at-camera.global_position
		if diff.length()<best and (-camera.global_basis.z).dot(diff.normalized())>0.05 and line_clear(camera.global_position,at):
			best = diff.length()
			found = {"type":"object","id":id,"name":C.OBJECTS[id].name}
	for foe in enemies:
		if not foe.dead or state.looted.has(foe.id) or not foe.visible:
			continue
		var at: Vector3 = foe.position+Vector3(0,0.25,0)
		var diff := at-camera.global_position
		if diff.length()<best and (-camera.global_basis.z).dot(diff.normalized())>0.1 and line_clear(camera.global_position,at):
			best = diff.length()
			found = {"type":"corpse","id":foe.id,"name":"Search "+foe.spec.name}
	for id in world.foraging:
		if state.taken.has(id):
			continue
		var record: Dictionary = world.foraging[id]
		var at: Vector3 = C.ground(record.pos,0.35)
		var diff := at-camera.global_position
		if diff.length()<best and (-camera.global_basis.z).dot(diff.normalized())>0.15 and line_clear(camera.global_position,at):
			best = diff.length()
			found = {"type":"forage","id":id,"name":record.name}
	if found.is_empty() and weeper_director: found = weeper_director.nearest_offering()
	return found

func object_interaction_point(id: String) -> Vector3:
	var record: Dictionary = C.OBJECTS[id]
	return C.ground(record.pos,float(record.get("interaction_height",.7)))

func interaction_prompt() -> String:
	if modal!="":
		return ""
	var found := nearest_interaction()
	if not found.is_empty():
		return "[ "+controls.hint("interact")+" ]  " + ("Talk to " if found.type=="npc" else "") + found.name
	if fire_distance(player.position)<4.5:
		return "[ "+controls.hint("rest")+" ]  Rest until morning · only when the road is clear"
	for marker in get_tree().get_nodes_in_group("wilderness_warnings"):
		var at: Vector3 = marker.global_position+Vector3.UP*1.4
		var offset: Vector3 = at-camera.global_position
		if offset.length()<7 and (-camera.global_basis.z).dot(offset.normalized())>.7 and line_clear(camera.global_position,at):
			return marker.get_meta("warning")
	if tutorial_timer>0:
		return "%s talk / interact · %s journal & map · %s heavy strike" % [controls.hint("interact"),controls.hint("map"),controls.hint("heavy")] if state.flags.accepted else "Talk to Mara in the inn yard · look at her and press "+controls.hint("interact")
	return ""

func interact() -> void:
	var found := nearest_interaction()
	if found.is_empty():
		return
	if found.type=="weeper_offering":
		weeper_director.take_offering(found.id)
	elif found.type=="npc":
		talk(found.id)
	elif found.type=="corpse":
		for foe in enemies:
			if foe.id==found.id:
				foe.search_body()
	elif found.type=="forage":
		harvest(found.id)
	else:
		interact_object(found.id)

func talk(id: String) -> void:
	side_quests.active_id = ""
	if id in woods.D.NPCS:
		woods.talk(id)
		return
	if id=="pip":
		dialogue_id = id
		ui.show_dialog(id,Narrative.page("Pip, eleven, sorts carved animals by the inn hearth. 'Mara says I can ask for help without going into the woods myself. Have you seen a blue ribbon?'",[Narrative.choice("Tell me about the ribbon.","side:open:ribbon"),Narrative.choice("Stay warm, Pip.","leave")]))
		return
	state.journey.interest = 0.0
	if id=="courier": state.discovered.met_courier = true
	if modal!="dialog" or dialogue_id!=id: audio.greet(id)
	shop_owner = ""
	if id in preload("res://scripts/march_content.gd").NPCS or id=="merchant" and state.flags.won:
		march.talk(id)
		return
	dialogue_id = id
	state.log_event("talk:"+id)
	ui.show_dialog(id,Narrative.dialogue(id,state))

func open_powder_shop(id: String) -> void:
	if not ranger.active() or id not in C.AMMO_SELLERS: return
	dialogue_id = id
	ui.show_dialog(id,Narrative.page("Paper cartridges: black powder and a lead ball wrapped in paper.\n\nPistol: %d / Musket: %d (capacity 122 each)\nCoins: %d\n\nEach shot uses one cartridge of the selected weapon. Reloading and cancelling consume none." % [state.inventory.pistol_cartridge,state.inventory.musket_cartridge,state.inventory.gold],[Narrative.choice("Buy 12 pistol cartridges. [6 coins]","buy_powder"),Narrative.choice("Buy 6 musket cartridges. [6 coins]","buy_musket_powder"),Narrative.choice("Return to our conversation.","powder_back")]))

func open_shop(id: String) -> void:
	dialogue_id = id
	shop_owner = id
	var stock: Dictionary = state.inventory
	ui.show_dialog(id,Narrative.page("Adela opens her travelling case.\n\n[color=#dec48e]Your purse: %d coins / Tonics: %d\nTo sell: %d pelts, %d essence, %d widow's bonnets.[/color]\n\nWoodland curios: %d amber, %d salts, %d silver wire (12 coins each).\nTonic: 8 coins. Adela pays 4 per pelt, 3 per essence and 1 per bonnet. Purchases and sales update your pack immediately." % [stock.gold,stock.tonic,stock.fur,stock.essence,stock.toadstools,stock.get("amber",0),stock.get("salt",0),stock.get("wire",0)],[Narrative.choice("Buy a tonic. [8 coins]","buy_tonic"),Narrative.choice("Sell pelts and woodland curios.","sell_curios"),Narrative.choice("Back to the road business.","shop_back")]))

func _local_choose_dialog(action: String) -> void:
	if action.begins_with("woods:"):
		woods.choose(action)
		return
	if action.begins_with("side:"):
		side_quests.choose(action)
		return
	if action.begins_with("journey:"):
		journey.choose(action)
		return
	if action.begins_with("march:"):
		march.choose(action)
		return
	if action.begins_with("personal:"):
		relationship.choose(action)
		return
	var f: Dictionary = state.flags
	state.log_event("choice:"+action)
	var requirement := affordability(action)
	if not requirement.allowed:
		if not dialogue_id.is_empty():
			if shop_owner==dialogue_id: open_shop(dialogue_id)
			else: talk(dialogue_id)
			ui.dialog_feedback.text = requirement.reason
		return
	match action:
		"buy_powder", "buy_musket_powder":
			var ammo: String = "musket_cartridge" if action=="buy_musket_powder" else "pistol_cartridge"
			var amount: int = 6 if action=="buy_musket_powder" else 12
			if ranger.active() and state.inventory.gold>=6 and state.inventory[ammo]<=122-amount:
				state.inventory.gold -= 6
				state.inventory[ammo] += amount
				state.log_event("bought_"+ammo+":"+str(amount))
				open_powder_shop(dialogue_id)
		"powder_back": talk(dialogue_id)
		"shop_back": talk(dialogue_id)
		"leave": set_modal("")
		"return": talk(dialogue_id)
		"ilya_next":
			if f.supplies and not f.scout:
				f.scout = true
				quest_reward("Scout's report",25)
			world.apply_state()
			ui.show_dialog("ilya",Narrative.page("The mill holds the oil. The underchapel holds the clapper. Meet me at Northwatch with both, or prepare with Mara at the inn. Tomas is safe; finish the road for him.",[Narrative.choice("I know the way.","leave")]))
		"accept":
			f.accepted = true
			quest_reward("The Road North",10)
			set_modal("")
		"tutorial":
			ui.show_dialog(dialogue_id,Narrative.page(controls.help_text(),[Narrative.choice("I understand.","leave")]))
		"mara_history":
			ui.show_dialog("mara",Narrative.page("My husband kept the first Northwatch fire. He said a road wasn't stones. It was the certainty that somebody would answer when you knocked at the other end.\n\nHe's buried where the east path reaches the King's Cairn. I used to walk up there on Sundays. Now the only visitors are things that have forgotten how to knock.\n\nIf you go, tell him the inn is still here.",[Narrative.choice("I'll visit the cairn if I can.","leave")]))
		"mara_rest", "chapel_heal":
			state.health = state.max_health
			state.stamina = 100
			audio.play_effect("heal")
			message("Warmth, water and a moment to breathe. Vitality restored.")
			set_modal("")
		"scout_report":
			if not f.scout:
				f.scout = true
				quest_reward("Ilya's report",25)
			world.apply_state()
			if dialogue_id=="ilya":
				ui.show_dialog("ilya",Narrative.page("Ilya unfolds a weathered map and marks two places.\n\n[color=#dec48e]Lamp oil: the Widow's Mill, west of the crossroads.\nThe clapper: Sister Elian's chapel, east of the crossroads.[/color]\n\nMeet me at Northwatch with both. Mara will send provisions ahead. You can still return to the inn if you want Osric's help. Your journal now carries these instructions.",[Narrative.choice("Tell me about the missing courier.","courier_rumor"),Narrative.choice("I'll find the oil and clapper.","leave")]))
			else:
				set_modal("")
		"courier_rumor", "courier_accept":
			f.courier = true
			message("Journal updated: find Tomas in the Lantern Fen.")
			if dialogue_id=="ilya":
				ui.show_dialog("ilya",Narrative.page("Tomas carried the valley's letters. He vanished beyond the mill, in the Lantern Fen.\n\nFind him by the reeds and bring three moonwort if he is fevered. Mother Vesna knows the plants.\n\n[color=#dec48e]Letters for the Living has been added to your journal.[/color]",[Narrative.choice("Back to the road report.","return"),Narrative.choice("I'll look for Tomas.","leave")]))
			else:
				set_modal("")
		"herbalist_accept":
			f.herbalist = true
			message("Journal updated: three yarrow in the Foxglove Grove.")
			set_modal("")
		"give_yarrow":
			if state.inventory.yarrow>=3 and not f.herbs_done:
				state.inventory.yarrow -= 3
				state.inventory.tonic += 2
				state.inventory.gold += 20
				f.herbs_done = true
				f.herbalist = true
				quest_reward("A Little Green Mercy",40)
			set_modal("")
		"buy_tonic":
			if state.inventory.gold>=8:
				state.inventory.gold -= 8
				state.inventory.tonic += 1
				message("Tonic purchased. Press 1 when wounded.")
			else:
				message("A tonic costs 8 coins.")
			set_modal("")
		"rook_bread", "rook_gold":
			var item := "bread" if action=="rook_bread" else "gold"
			var price := 2 if item=="bread" else 12
			if state.inventory[item]>=price and not f.bargain:
				state.inventory[item] -= price
				f.bargain = true
				quest_reward("A bargain at the mill",35)
				message("Rook steps aside. The oil is behind the mill, beside the wheel.",6)
			else:
				message("You need %d %s. You can return with supplies." % [price,item])
			set_modal("")
		"rook_fight":
			set_modal("")
			spawn_enemy("mill_enforcer_1","bandit",Vector2(-106,-166))
			spawn_enemy("mill_enforcer_2","bandit",Vector2(-113,-174))
			message("Rook's guards draw steel. Defeat them to take the oil.",6)
		"keeper_accept":
			f.keeper = true
			message("Remember: Root → Flame → Bell. The stair is beside the chapel altar.",7)
			set_modal("")
		"save_courier":
			if state.inventory.moonwort>=3 and not f.courier_done:
				state.inventory.moonwort -= 3
				state.inventory.gold += 35
				f.courier_done = true
				f.courier = true
				quest_reward("Letters for the Living",60)
			set_modal("")
		"prepare":
			if f.oil and f.relic and not f.prepared:
				f.prepared = true
				state.inventory.tonic += 3
				state.inventory.bread += 2
				state.inventory.wood += 2
				state.health = state.max_health
				quest_reward("A Light for Northwatch",60)
				message("Provisioned for Northwatch. Light the beacon when you are ready.",7)
			set_modal("")
		"upgrade_sword":
			if f.sword_upgrade:
				message("Your implement is already improved.")
			elif state.inventory.scrap>=4 and state.inventory.gold>=15:
				state.inventory.scrap -= 4
				state.inventory.gold -= 15
				f.sword_upgrade = true
				state.damage = 43
				quest_reward("An honest edge",20)
			else:
				message("Improving your implement needs 4 scrap and 15 coins. Look for old chests.")
			set_modal("")
		"upgrade_coat":
			if f.coat_upgrade:
				message("Your coat is already reinforced.")
			elif state.inventory.scrap>=3 and state.inventory.gold>=12:
				state.inventory.scrap -= 3
				state.inventory.gold -= 12
				f.coat_upgrade = true
				state.max_health = 125
				state.health = minf(state.max_health,state.health+25)
				quest_reward("Ash-lined coat",20)
			else:
				message("A reinforced coat needs 3 scrap and 12 coins.")
			set_modal("")
		"journal": ui.show_map()
		"sell_curios":
			var income: int = state.inventory.fur*4+state.inventory.essence*3+state.inventory.toadstools
			for key in ["amber","salt","wire"]:
				income += state.inventory.get(key,0)*12
				state.inventory[key] = 0
			state.inventory.gold += income
			state.inventory.fur = 0
			state.inventory.essence = 0
			state.inventory.toadstools = 0
			message("Sold pelts and curios for %d coins." % income)
			open_shop(dialogue_id)
			ui.dialog_feedback.text = "Sold pelts and curios for %d coins. Your purse now holds %d." % [income,state.inventory.gold]
			ui.dialog_feedback.add_theme_color_override("font_color",Color("a6d5a5"))
	if action in ["upgrade_sword","upgrade_coat","buy_tonic"] and not dialogue_id.is_empty():
		if shop_owner==dialogue_id: open_shop(dialogue_id)
		else: talk(dialogue_id)
		ui.dialog_feedback.add_theme_color_override("font_color",Color("a6d5a5"))
		ui.dialog_feedback.text = "Purchased tonic for 8 coins. Tonics: %d / Coins: %d." % [state.inventory.tonic,state.inventory.gold] if action=="buy_tonic" else "Purchase complete. Your pack and equipment have been updated."

func affordability(action: String) -> Dictionary:
	if action.begins_with("journey:"): return journey.requirement(action)
	if action in ["buy_powder","buy_musket_powder"]:
		if not ranger.active(): return {"allowed":false,"reason":"For a Ranger's pouch"}
		if state.inventory["musket_cartridge" if action=="buy_musket_powder" else "pistol_cartridge"]>(116 if action=="buy_musket_powder" else 110): return {"allowed":false,"reason":"Not enough pouch space"}
		return {"allowed":state.inventory.gold>=6,"reason":"Need 6 coins" if state.inventory.gold<6 else ""}
	if action=="sell_curios" and state.inventory.fur+state.inventory.essence+state.inventory.toadstools+state.inventory.get("amber",0)+state.inventory.get("salt",0)+state.inventory.get("wire",0)==0:
		return {"allowed":false,"reason":"No pelts, essence or bonnets to sell"}
	var costs := {"upgrade_sword":{"scrap":4,"gold":15},"upgrade_coat":{"scrap":3,"gold":12},"buy_tonic":{"gold":8},"rook_bread":{"bread":2},"rook_gold":{"gold":12}}
	if action=="upgrade_sword" and state.flags.sword_upgrade:
		return {"allowed":false,"reason":"Already reforged"}
	if action=="upgrade_coat" and state.flags.coat_upgrade:
		return {"allowed":false,"reason":"Already reinforced"}
	var missing: Array[String] = []
	for item in costs.get(action,{}):
		var shortage: int = costs[action][item]-state.inventory[item]
		if shortage>0:
			missing.append("%d %s" % [shortage,"coins" if item=="gold" else item])
	return {"allowed":missing.is_empty(),"reason":"Need "+", ".join(missing) if not missing.is_empty() else ""}

func _local_harvest(id: String) -> void:
	if state.taken.has(id) or not world.foraging.has(id):
		return
	var record: Dictionary = world.foraging[id]
	state.journey.interest = 0.0
	state.inventory[record.kind] += 2 if record.kind=="berries" else 1
	state.taken[id] = true
	state.log_event("foraged:"+id)
	world.apply_foraging()
	audio.play_effect("pickup")
	message("Picked wild berries. [3] Eat berries." if record.kind=="berries" else "Coppercap collected. Edible: [4] to eat." if record.kind=="mushrooms" else "Widow's bonnet collected. INEDIBLE — kept separate from food.")

func quest_reward(name_text: String, xp: int) -> void:
	state.xp += xp
	saves.request("Quest progress")
	state.log_event("quest:"+name_text)
	audio.play_effect("quest_complete",Vector3.INF,true)
	message("%s · +%d experience" % [name_text,xp],5)

func take(id: String) -> void:
	if C.OBJECTS.get(id,{}).get("kind","")=="cache" or C.OBJECTS.get(id,{}).has("loot") or id=="ash_bandages": audio.play_effect("chest_open")
	state.taken[id] = true
	world.objects[id].hide()
	state.log_event("collected:"+id)
	state.journey.interest = 0.0
	if id in ["oil","relic"]: world.apply_state()
	audio.play_effect("pickup")

func _local_interact_object(id: String) -> void:
	if id.begins_with("nw_"):
		woods.interact(id)
		return
	if id.begins_with("side_"):
		side_quests.interact(id)
		return
	if C.OBJECTS.has(id) and C.OBJECTS[id].has("loot"):
		if state.taken.has(id): return
		var items: Array[String] = []
		for item in C.OBJECTS[id].loot:
			var count: int = C.OBJECTS[id].loot[item]
			if item in ["pistol_cartridge","musket_cartridge"]:
				count = mini(count,maxi(0,122-int(state.inventory.get(item,0))))
			state.inventory[item] += count
			items.append("%d %s" % [count,item])
		take(id)
		message("Chest searched: "+", ".join(items)+". "+C.OBJECTS[id].get("lore",""),9)
		return
	if id.begins_with("ash_"):
		march.interact(id)
		return
	if state.taken.has(id):
		return
	var d: Dictionary = C.OBJECTS[id]
	var f: Dictionary = state.flags
	match id:
		"crypt_entry":
			if not f.keeper:
				message("Ask Sister Elian about the standing stone before descending.")
				return
			teleport(Vector2(130,-369))
			ui.discover("The Underchapel","Root remembers. Flame forgives. Bell calls home.")
			return
		"crypt_exit":
			teleport(Vector2(132,-215),PI)
			return
		"rune_root", "rune_flame", "rune_bell":
			var rune := id.trim_prefix("rune_")
			if threats_near(C.ground(d.pos),7):
				message("The seal will not wake while spirits gather this close.")
				return
			if rune=="root" or rune=="flame" and f.root or rune=="bell" and f.flame and f.root:
				f[rune] = true
				world.objects[id].modulate = Color("a6e8df")
				audio.play_effect("bell")
				message("The %s seal wakes. %s" % [rune,"The relic is released." if f.bell else "Flame comes next." if rune=="root" else "Bell comes last."],6)
				state.log_event("seal:"+rune)
			else:
				f.root = false
				f.flame = false
				f.bell = false
				for seal in ["rune_root","rune_flame","rune_bell"]:
					world.objects[seal].modulate = Color.WHITE
				state.health = maxf(1,state.health-5)
				message("A wrong note. The seals fall silent. Root → Flame → Bell.",6)
			return
		"beacon":
			if f.won:
				message("The road is restored. Adela has arrived by the watchtower.",6)
			elif f.beacon_lit:
				message("Hold the courtyard. The Bell Warden is coming.",5)
			elif not f.prepared:
				message("Bring oil and the clapper. Ilya can provision you here, or Mara can help at the inn.",6)
			else:
				f.beacon_lit = true
				state.wave = 0
				state.wave_timer = 3
				state.day_clock = 19.0
				world.apply_state()
				audio.play_effect("bell")
				state.log_event("beacon_defence_started")
				ui.discover("KEEP THE FIRE","Three waves. Stand your ground. The road depends on you.")
			return
		"supplies":
			if threats_near(C.ground(d.pos),17):
				message("Clear the caravan's attackers before gathering the stores.")
				return
			f.supplies = true
			f.accepted = true
			state.inventory.bread += 3
			state.inventory.tonic += 1
			state.inventory.scrap += 2
			quest_reward("The lost caravan",40)
			message("Stores recovered. Ilya is beside the fire just east of the cart.",7)
		"oil":
			if not f.bargain and not state.defeated.has("mill_enforcer_1"):
				message("Rook owns this oil. Speak with him before taking it.")
				return
			if not f.bargain and threats_near(C.ground(d.pos),20):
				message("Rook's guards still hold the mill.")
				return
			f.oil = true
			quest_reward("The millkeeper's oil",45)
		"relic":
			if not f.bell:
				message("Three seals bind the clapper. Root, then Flame, then Bell.",6)
				return
			if threats_near(C.ground(d.pos),12):
				message("The last spirit holds the altar. Clear it first.")
				return
			f.relic = true
			quest_reward("The Last Bell",80)
			message("The clapper is yours. The southern stair leads back to the chapel.",7)
		"grave":
			f.grave = true
			quest_reward("Someone at the other end",45)
			ui.discover("A ROADKEEPER'S MEMORY","'Keep a light for me. I will always know the way.' — E. Vale")
		"letter":
			f.letter = true
			quest_reward("An undelivered letter",15)
			message("'Mother — the roads are bad, but I will be home before winter. Leave the lamp.'",10)
	match d.kind:
		"cache":
			state.inventory.scrap += 3
			state.inventory.gold += 12
			state.inventory.tonic += 1
			message("Old stores: 3 scrap, 12 coins and a tonic. Osric can use the scrap.",5)
		"herb":
			state.inventory.yarrow += 1
			message("Golden yarrow · %d / 3 for Mother Vesna" % state.inventory.yarrow)
		"moonwort":
			state.inventory.moonwort += 1
			message("Moonwort · %d / 3 for the fevered courier" % state.inventory.moonwort)
		"wood":
			state.inventory.wood += 2
			message("Two bundles of dry wood. F makes a campfire.")
	take(id)

func teleport(at: Vector2, yaw := 0.0) -> void:
	player.position = C.ground(at,0.8)
	player.velocity = Vector3.ZERO
	player.rotation.y = yaw
	camera.rotation = Vector3.ZERO
	state.log_event("stair_transition:"+str(at))
	journey.reset()

func update_defence(dt: float) -> void:
	if not state.flags.beacon_lit or state.flags.won:
		return
	if not coop.party_near(C.ground(Vector2(0,-340)),65):
		return
	state.wave_timer = maxf(0,state.wave_timer-dt)
	var living := enemies.filter(func(e): return not e.dead and e.id.begins_with("defence"))
	if not living.is_empty():
		return
	if state.wave_timer>0:
		return
	state.wave += 1
	match state.wave:
		1:
			spawn_enemy("defence_1a","wraith",Vector2(-9,-319))
			spawn_enemy("defence_1b","wolf",Vector2(11,-319))
			state.wave_timer = 12
			message("THE FIRST CALL · Two shapes emerge from the trees.",7)
		2:
			spawn_enemy("defence_2a","wraith",Vector2(-10,-320))
			spawn_enemy("defence_2b","wraith",Vector2(10,-320))
			spawn_enemy("defence_2c","wolf",Vector2(0,-315))
			state.wave_timer = 15
			state.inventory.tonic += 1
			message("THE SECOND CALL · The beacon yields a warming ember. +1 tonic.",7)
		3:
			spawn_enemy("defence_boss","guardian",Vector2(0,-317))
			state.wave_timer = 12
			audio.play_effect("bell")
			ui.discover("THE BELL WARDEN","Parry its slow strike. Use Q to break its guard.")
		4:
			state.flags.won = true
			state.health = state.max_health
			state.day_clock = 6.8
			quest_reward("The Hollow is connected again",200)
			world.apply_state()
			ui.discover("THE ROAD REMEMBERS","A caravan arrives. An ordinary tomorrow begins.")
			save_game()
			message("Expedition complete. Talk to Adela beside the tower. Your journey is saved.",10)

func target() -> Dictionary:
	var side: Dictionary = side_quests.objective(state.tracked_side)
	if not side.is_empty(): return side
	return main_target()

func main_target() -> Dictionary:
	if state.woods.focus and state.story.bell_done or state.story.epilogue and not state.woods.started and int(state.story.track)==0:
		return woods.objective()
	var f: Dictionary = state.flags
	if f.won:
		return march.objective()
	if f.beacon_lit:
		return {"text":"Defend Northwatch · call %d / 3" % mini(3,maxi(1,state.wave)),"pos":C.SITES.tower.pos}
	if f.prepared:
		return {"text":"Light the Northwatch beacon.","pos":C.OBJECTS.beacon.pos}
	if not f.accepted:
		return {"text":"Speak to Mara at the inn.","pos":C.NPCS.mara.pos}
	if not f.supplies:
		return {"text":"Recover the lost caravan at the toll.","pos":C.OBJECTS.supplies.pos}
	if not f.scout:
		return {"text":"Hear Ilya's report by the toll fire.","pos":C.NPCS.ilya.pos}
	if not f.oil:
		return {"text":"Collect Rook's oil beside the mill wheel.","pos":C.OBJECTS.oil.pos} if f.bargain or state.defeated.has("mill_enforcer_1") else {"text":"Obtain lamp oil at the Widow's Mill.","pos":C.NPCS.rook.pos}
	if not f.relic:
		if in_crypt():
			if not f.root:
				return {"text":"Wake the Root seal · western chamber.","pos":C.OBJECTS.rune_root.pos}
			if not f.flame:
				return {"text":"Wake the Flame seal · eastern chamber.","pos":C.OBJECTS.rune_flame.pos}
			if not f.bell:
				return {"text":"Wake the Bell seal · northern altar.","pos":C.OBJECTS.rune_bell.pos}
			return {"text":"Recover the clapper at the northern altar.","pos":C.OBJECTS.relic.pos}
		return {"text":"Seek the clapper at the eastern chapel.","pos":C.NPCS.sister.pos if not f.keeper else C.OBJECTS.crypt_entry.pos}
	if in_crypt():
		return {"text":"Return up the southern stair.","pos":C.OBJECTS.crypt_exit.pos}
	return {"text":"Prepare with Ilya at Northwatch (or Mara at the inn).","pos":Vector2(-7,-332)}

func journal_text() -> String:
	var f: Dictionary = state.flags
	var lines: String = "[color=#e2c38a]THE ROAD NORTH[/color]\n" + main_target().text + "\n\n"
	lines += "Oil and clapper can be gathered in either order. Ilya will meet you at Northwatch with Mara's provisions once both are found.\n\n"
	for row in [[f.accepted,"Hear Mara's request"],[f.supplies,"Recover the caravan"],[f.scout,"Hear the scout's report"],[f.oil,"Bring oil from the mill"],[f.relic,"Recover the chapel's clapper"],[f.prepared,"Prepare with Ilya or Mara"],[f.won,"Restore and defend Northwatch"]]:
		lines += ("[color=#92b79a]✓ " if row[0] else "[color=#a8b5ab]○ ") + row[1]+"[/color]\n"
	lines += "\n[color=#e2c38a]OTHER PEOPLE'S TROUBLES[/color]\n"
	lines += ("✓" if f.herbs_done else "○") + " A Little Green Mercy — 3 yarrow for Vesna (%d/3)\n" % state.inventory.yarrow
	lines += ("✓" if f.courier_done else "○") + " Letters for the Living — 3 moonwort for Tomas (%d/3)\n" % state.inventory.moonwort
	lines += ("✓" if f.grave else "○") + " Visit the roadkeeper's grave at the King's Cairn\n"
	lines += "\nRoad services: settlement contacts can forward Vesna's yarrow and Tomas's moonwort after you meet them. Use Travel from the journal at a visited, secured stop. Safe road sprint becomes a steady stride after five seconds.\n"
	lines += "\n[color=#e2c38a]TRAVELLER'S NOTES[/color]\nRoot → Flame → Bell.\nFire slows spirits. G rests when no enemy is nearby.\nOsric needs scrap and coins to improve your equipment.\nA parry is a block raised just before impact.\n"
	if state.weeper_world.introduced:
		lines += "\nHOLLOW WEEPER / Corporeal guardian of the Old Faith. She endures dawn and torchlight. Leave her offerings and stay outside her clearing to pass safely. Iron deals only a quarter damage; spells, sacred attacks and Graveward resin work better. When her face opens, sidestep or take solid cover: her aim locks just before the scream. Shields only reduce it. Counterattack during her two-second exhaustion. Strong early interrupts work, repeated ordinary hits do not. A resin tear and two essence brew Graveward resin at a safe fire.\n"
	if state.weapon_resin_seconds>0: lines += "\nGraveward enchantment: %d seconds left.\n" % ceili(state.weapon_resin_seconds)
	lines += "\n[color=#e2c38a]YOUR PACK[/color]\n%d coins · %d scrap · %d wood\n%d tonics · %d bread\n%s sword · %s coat\n%d experience · %d returns from the brink\n" % [state.inventory.gold,state.inventory.scrap,state.inventory.wood,state.inventory.tonic,state.inventory.bread,"Improved" if f.sword_upgrade else state.profile.profession_id.capitalize(),"Ash-lined" if f.coat_upgrade else "Traveller's",state.xp,state.deaths]
	lines += "\n%d berries · %d edible coppercaps\n%d inedible bonnets · %d pelts · %d essence\n[3] Eat berries · [4] Eat coppercaps\nSearch fallen enemies with E. Adela buys pelts and curios.\n" % [state.inventory.berries,state.inventory.mushrooms,state.inventory.toadstools,state.inventory.fur,state.inventory.essence]
	if state.flags.won or state.story.started:
		lines = march.journal()+"\n"+lines
	var profile_data = preload("res://scripts/character_data.gd")
	lines += "\n[color=#e2c38a]THIS TRAVELLER[/color]\n"+state.profile.name+" / "+str(int(state.profile.age))+" / "+profile_data.origin(state.profile.origin_id).name+"\n"+profile_data.profession(state.profile.profession_id).description+"\n"
	lines += state.Progression.journal(state.profile.profession_id,state.xp,state.level_floor)
	if state.woods.started and state.woods.focus: lines = woods.journal()+"\n"+lines
	elif state.story.bell_done: lines += woods.journal()
	if not state.tracked_side.is_empty(): lines = side_quests.tracked_journal()+"\n"+lines
	lines += side_quests.journal()
	lines += journey.journal()
	lines += "\nDEEP WOODS\nDanger rises away from roads and inhabited places. Woodland hounds give way to Pitchbound and Boughstalkers; the remotest wilds hold pairs. Roads still have authored ambushes.\nTar on posts warns of Pitchbound: step out of their long poker's reach, then punish the slow recovery. Blocking takes chip damage; a timed parry stops it. High claw marks warn of Boughstalkers: interrupt their attack warning with a strike. Retreat toward shelter if outmatched.\n"
	return lines

func data_root() -> String:
	# The Steam preview runs a PCK with the editor-capable GodotSteam binary.
	# In that mode res:// is virtual, so saves must use the pack's real folder.
	var pack_folder: String = OS.get_executable_path().get_base_dir().get_base_dir()
	if FileAccess.file_exists(pack_folder.path_join("TheLastRoads.pck")): return pack_folder
	var source: String = ProjectSettings.globalize_path("res://")
	if OS.has_feature("editor") and not source.is_empty() and DirAccess.dir_exists_absolute(source): return source
	return OS.get_executable_path().get_base_dir()

func save_path() -> String:
	if coop!=null and coop.active:
		return data_root().path_join(("reports/coop/" if test_mode else "")+coop.save_name())
	return data_root().path_join("reports/integration-save.json" if test_mode else "saves/hollow-valley.json")

func runtime_tail() -> Array:
	var path := data_root().path_join("debug-logs/runtime.log")
	if not FileAccess.file_exists(path):
		path = ProjectSettings.get_setting("debug/file_logging/log_path","user://logs/godot.log")
	if not FileAccess.file_exists(path): return []
	var f := FileAccess.open(path,FileAccess.READ)
	if f==null:
		return []
	var count := mini(f.get_length(),16384)
	f.seek(f.get_length()-count)
	var lines := Array(f.get_buffer(count).get_string_from_utf8().split("\n"))
	return lines.slice(maxi(0,lines.size()-45))

func snapshot() -> Dictionary:
	state.enemies.clear()
	for e in enemies:
		state.enemies[e.id] = e.record()
	var objective := target().duplicate()
	if objective.has("pos"):
		objective["position"] = [objective.pos.x,objective.pos.y]
		objective.erase("pos")
	return {"schema_version":5,"terrain_revision":C.TERRAIN_REVISION,"build":C.BUILD,"engine":Engine.get_version_info().string,"world_id":C.WORLD_ID,"area_id":"underchapel" if in_crypt() else "rowan_march" if player.position.z< -1005 else "ashen_march" if player.position.z< -430 else "hollow_valley","layout_version":C.LAYOUT,"seed":C.SEED,"ambient_life":world.ambient.summary(),"player":{"eye_height":eye_height,"body_height":player_collision.shape.height,"position":[player.position.x,player.position.y,player.position.z],"yaw":player.rotation.y,"pitch":camera.rotation.x,"velocity":[player.velocity.x,player.velocity.y,player.velocity.z],"lantern":lantern.visible,"torch":torch_equipped},"state":state.to_dict(),"objective":objective,"location":ui.location.text if ui else location_id,"session":{"last_march_document":march.document_id,"creator_draft":ui.creator.profile() if modal=="creator" else {},"relationship":{"partner":relationship.active_id,"phase":relationship.phase,"committed":relationship.committed,"transition_seconds":relationship.clock},"modal":modal,"dialogue_id":dialogue_id,"attack_clock":attack_clock,"swing":swing,"swing_style":swing_style,"swing_duration":swing_duration,"blocking":blocking,"block_age":block_age,"started":started},"system":{"os":OS.get_name(),"gpu":RenderingServer.get_video_adapter_name(),"viewport":[get_viewport().size.x,get_viewport().size.y],"fps":Engine.get_frames_per_second(),"memory_mb":snappedf(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,0.1),"process_ms":snappedf(Performance.get_monitor(Performance.TIME_PROCESS)*1000,0.01)},"combat_runtime":combat.record(),"profession_combat":combat.summary(),"soundtrack":audio.summary(),"visual_settings":visuals.summary(),"runtime_log_tail":runtime_tail()}

func save_game() -> bool:
	var payload: Dictionary = snapshot()
	payload.save_kind = "manual"
	payload.saved_at_unix = Time.get_unix_time_from_system()
	var result: Dictionary = saves.write(save_path(),payload)
	if not result.ok:
		message(result.reason,8)
		return false
	state.log_event("manual_save")
	saves.pending = ""
	saves.elapsed = 0
	message("Journey saved. F9 restores this manual save.")
	return true

func validate_save(d: Variant) -> bool:
	if not d is Dictionary or (d.get("schema_version")!=2 and d.get("schema_version")!=3 and d.get("schema_version")!=4 and d.get("schema_version")!=5) or d.get("world_id")!=C.WORLD_ID or d.get("layout_version")!=C.LAYOUT:
		return false
	if not combat.valid_record(d.get("combat_runtime",{})): return false
	if not d.get("player") is Dictionary or not State.valid_vector(d.player.get("position")):
		return false
	for key in ["yaw","pitch"]:
		if not (d.player.get(key) is float or d.player.get(key) is int) or not is_finite(float(d.player[key])):
			return false
	for key in ["lantern","torch"]:
		if d.player.has(key) and not d.player[key] is bool:
			return false
	if not d.get("state") is Dictionary:
		return false
	var candidate = State.new()
	return candidate.read_dict(d.state,int(d.schema_version))

func load_game(path_override := "") -> bool:
	var chosen: Dictionary = saves.load_choice(path_override)
	if chosen.is_empty():
		message("No valid save found. Existing saves and recovery copies were kept.",8)
		return false
	var path: String = chosen.path
	var d: Dictionary = chosen.payload
	var candidate = State.new()
	candidate.read_dict(d.state,int(d.schema_version))
	combat.reset()
	audio.reset_effects()
	state = candidate
	saves.reset()
	ui.reset_progression()
	journey.reset()
	if weeper_director: weeper_director.announced = state.weeper_world.introduced
	player_stagger = 0
	ranger.reset()
	if d.get("terrain_revision",0)!=C.TERRAIN_REVISION:
		for record in state.enemies.values():
			var at: Array = record.position
			at[1] += C.height_at(at[0],at[2])-C.legacy_height_at(at[0],at[2])
		for fire in state.fires:
			var at: Array = fire.position
			at[1] += C.height_at(at[0],at[2])-C.legacy_height_at(at[0],at[2])
	apply_player_stature()
	world.ambient.reset()
	var p: Array = d.player.position
	player.position = Vector3(clampf(p[0],-235,235),p[1],clampf(p[2],-1845,85))
	if d.get("terrain_revision",0)!=C.TERRAIN_REVISION:
		player.position.y += C.height_at(player.position.x,player.position.z)-C.legacy_height_at(player.position.x,player.position.z)
		player.position.y = maxf(player.position.y,world.surface_height(player.position)+.04)
	player.rotation.y = d.player.yaw
	camera.rotation.x = clampf(d.player.pitch,-1.25,1.25)
	player.velocity = Vector3.ZERO
	lantern.visible = d.player.get("lantern",false)
	torch_equipped = d.player.get("torch",false)
	lantern.visible = lantern.visible and not torch_equipped
	torch_light.visible = torch_equipped
	if ranger.active() and (state.ranger.reload_left>0 or state.ranger.weapon=="musket"): stow_lights()
	attack_clock = 0
	blocking = false
	world.apply_state()
	spawn_enemies()
	if weather:
		weather.shelter_clock = 0
		weather.apply_visuals()
	combat.restore(d.get("combat_runtime",{}))
	state.log_event("manual_load")
	night_announced = state.day_clock>=18
	message("Journey recovered from a backup. Your original files were kept." if path.ends_with(".bak") else "Automatic checkpoint restored. Your manual save is unchanged." if d.get("save_kind","")=="auto" else "Journey restored. Your discoveries and choices remain.",7)
	return true

func open_report() -> void:
	report_image = get_viewport().get_texture().get_image()
	report_snapshot = snapshot()
	reporting = true
	audio.pause_for_report(true)
	get_tree().paused = not coop.active
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui.report_entry.text = ""
	ui.report_error.text = ""
	ui.move_child(ui.report_panel,ui.get_child_count()-1)
	ui.report_panel.show()
	ui.report_entry.grab_focus()

func close_report() -> void:
	ui.report_panel.hide()
	reporting = false
	audio.pause_for_report(false)
	get_tree().paused = (modal!="" or not started) and not coop.active
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if started and modal=="" else Input.MOUSE_MODE_VISIBLE

func submit_report() -> bool:
	var text: String = ui.report_entry.text.strip_edges()
	if text.is_empty():
		ui.report_error.text = "Please describe the problem before saving."
		return false
	var stamp := Time.get_datetime_string_from_system(true).replace(":","-")+"-"+str(Time.get_ticks_usec())
	# Automated export checks must not bury player feedback in synthetic reports.
	var folder := data_root().path_join("reports/debug-logs" if test_mode else "debug-logs").path_join(stamp)
	var err := DirAccess.make_dir_recursive_absolute(folder)
	if err!=OK:
		ui.report_error.text = "Cannot create report folder: "+error_string(err)
		return false
	var image_error := report_image.save_png(folder.path_join("screenshot.png"))
	var f := FileAccess.open(folder.path_join("report.json"),FileAccess.WRITE)
	if image_error!=OK or f==null:
		ui.report_error.text = "Write failed. Your note is still here; check folder permissions."
		return false
	report_snapshot["note"] = text
	report_snapshot["captured_at_utc"] = stamp
	report_snapshot["screenshot"] = "screenshot.png"
	f.store_string(JSON.stringify(report_snapshot,"\t"))
	f.close()
	var note := FileAccess.open(folder.path_join("note.txt"),FileAccess.WRITE)
	if note!=null:
		note.store_string(text)
	state.log_event("debug_report_saved:"+stamp)
	close_report()
	message("Field note saved with screenshot and state in debug-logs.",6)
	return true

func capture(name_text: String) -> void:
	DirAccess.make_dir_recursive_absolute(data_root().path_join("reports"))
	ui.discovery_timer = 0
	ui.toast_timer = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(data_root().path_join("reports/"+name_text+".png"))

func smoke() -> void:
	start_new()
	await get_tree().physics_frame
	choose_dialog("accept")
	assert(state.flags.accepted)
	var foe = enemies[0]
	teleport(Vector2(foe.position.x,foe.position.z+2.3))
	await get_tree().physics_frame
	var before_health: float = foe.health
	attack()
	assert(foe.health==before_health-state.damage,"Sword must damage a reachable target")
	attack()
	assert(foe.health==before_health-state.damage,"Cooldown must prevent double hits")
	blocking = true
	block_age = 0.1
	var before: float = state.health
	receive_hit(17,player.position+Vector3(0,0,-2),"bandit")
	assert(state.health==before,"A timely front-facing block must parry")
	blocking = false
	for e in enemies:
		if not e.dead:
			e.hit(999)
	interact_object("supplies")
	assert(state.flags.supplies)
	choose_dialog("scout_report")
	choose_dialog("rook_bread")
	assert(state.flags.bargain)
	interact_object("oil")
	choose_dialog("keeper_accept")
	interact_object("rune_bell")
	assert(not state.flags.bell)
	interact_object("rune_root")
	interact_object("rune_flame")
	interact_object("rune_bell")
	interact_object("relic")
	assert(state.flags.relic)
	for id in ["herb_1","herb_2","herb_3","fen_1","fen_2","fen_3"]:
		interact_object(id)
	choose_dialog("give_yarrow")
	choose_dialog("save_courier")
	assert(state.flags.herbs_done and state.flags.courier_done)
	choose_dialog("prepare")
	assert(state.flags.prepared)
	teleport(Vector2(0,-337))
	interact_object("beacon")
	for wave in range(4):
		state.wave_timer = 0
		update_defence(0)
		for e in enemies:
			if e.id.begins_with("defence") and not e.dead:
				e.hit(999)
	assert(state.flags.won)
	assert(save_game())
	var gold: int = state.inventory.gold
	state.inventory.gold = 0
	assert(load_game())
	assert(state.inventory.gold==gold and state.flags.won)
	var valid := snapshot()
	assert(validate_save(valid))
	var invalid := valid.duplicate(true)
	invalid.state.inventory.tonic = "broken"
	assert(not validate_save(invalid),"Malformed save must be rejected")
	var old_gold: int = state.inventory.gold
	interact_object("supplies")
	assert(state.inventory.gold==old_gold,"Taken objects must not reward twice")
	teleport(Vector2(0,42))
	await capture("smoke-world")
	var old_time: float = state.elapsed
	var old_pos := player.position
	press_key(KEY_QUOTELEFT)
	assert(reporting,"The physical backtick shortcut must open the report dialog")
	assert(not submit_report(),"Blank reports must stay open")
	await get_tree().process_frame
	await get_tree().process_frame
	assert(state.elapsed==old_time and player.position==old_pos,"Report must freeze simulation")
	ui.report_entry.text = "Line one"
	ui.report_entry.set_caret_column(8)
	press_key(KEY_ENTER,true)
	assert(reporting and ui.report_entry.text.contains("\n"),"Shift+Enter must add a line without submitting")
	ui.report_entry.text = "AUTOMATED "+C.BUILD+": full quest, combat, persistence and paused diagnostics integration test."
	press_key(KEY_ENTER)
	assert(not reporting and not get_tree().paused)
	ui.show_map()
	await capture("journal")
	open_report()
	close_report()
	assert(modal=="map" and get_tree().paused,"Report cancellation must restore previous pause state")
	set_modal("")
	set_modal("pause")
	press_key(KEY_QUOTELEFT)
	assert(reporting)
	assert(ui.get_child(ui.get_child_count()-1)==ui.report_panel,"Field notes must render above the pause menu")
	press_key(KEY_ESCAPE)
	assert(modal=="pause" and get_tree().paused)
	set_modal("")
	for id in C.NPCS:
		var at: Vector3 = world.npcs[id].global_position
		teleport(Vector2(at.x,at.z+2.1))
		await get_tree().physics_frame
		var found := nearest_interaction()
		assert(found.get("id")==id,"NPC must be reachable and selectable: "+id+" got "+str(found))
		press_key(KEY_E)
		assert(modal=="dialog" and dialogue_id==id)
		press_key(KEY_ESCAPE)
	print("SMOKE PASS: combat, parry, cooldown, peaceful mill, crypt puzzle, side quests, beacon waves, persistence, validation, nonduplicate rewards, paused diagnostic export")
	get_tree().quit()

func tour() -> void:
	await capture("00-title")
	start_new()
	choose_dialog("accept")
	teleport(Vector2(0,47),0.55)
	ui.discovery_timer = 0
	ui.toast_timer = 0
	tutorial_timer = 0
	camera.rotation.x = -0.04
	await capture("01-inn")
	teleport(Vector2(4,-67),0)
	await capture("02-toll")
	teleport(Vector2(-108,-145),0.35)
	await capture("03-mill")
	teleport(Vector2(128,-177),0)
	await capture("04-chapel")
	teleport(Vector2(130,-370),0)
	await capture("05-underchapel")
	teleport(Vector2(-106,-225),0.2)
	await capture("06-fen")
	teleport(Vector2(0,-323),0)
	await capture("07-northwatch")
	talk("mara")
	await capture("08-dialogue")
	set_modal("")
	ui.show_map()
	await capture("09-map")
	set_modal("")
	state.day_clock = 19.0
	teleport(Vector2(0,-328))
	spawn_enemy("tour_guardian","guardian",Vector2(0,-337))
	await capture("10-warden-at-dusk")
	state.flags.won = true
	state.flags.beacon_lit = true
	state.day_clock = 7
	for foe in enemies:
		foe.hide()
		foe.dead = true
		foe.collision_layer = 0
	world.apply_state()
	teleport(Vector2(6,-310),-0.1)
	await capture("11-road-restored")
	print("TOUR PASS: 12 rendered frames captured in reports")
	get_tree().quit()

func press_key(code: Key, shift := false) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.shift_pressed = shift
	ev.pressed = true
	Input.parse_input_event(ev)
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and started and not test_mode and modal=="" and not reporting and ui:
		set_modal("pause")

func feedback_test() -> void:
	start_new()
	await get_tree().physics_frame
	# Exercise the observed conversation failure through the real keyboard path.
	state.flags.supplies = true
	state.flags.accepted = true
	talk("ilya")
	press_key(KEY_1)
	assert(state.flags.scout and modal=="dialog","Scout report must advance without dismissing conversation")
	press_key(KEY_1)
	assert(state.flags.courier and modal=="dialog","Courier rumour must remain readable")
	press_key(KEY_1)
	assert(modal=="dialog")
	press_key(KEY_ESCAPE)
	state.inventory.gold = 12
	state.inventory.scrap = 0
	talk("osric")
	assert(ui.choices[0].disabled and ui.dialog_feedback.text.contains("Need"))
	press_key(KEY_1)
	assert(modal=="dialog" and not state.flags.sword_upgrade)
	await capture("03-osric-requirements")
	state.inventory.gold = 20
	state.inventory.scrap = 4
	talk("osric")
	press_key(KEY_1)
	assert(state.flags.sword_upgrade and modal=="dialog" and ui.choices[0].disabled)
	press_key(KEY_ESCAPE)
	dialogue_id = ""
	teleport(Vector2(0,-48))
	var wolf := spawn_enemy("feedback_wolf","wolf",Vector2(0,-50))
	await get_tree().physics_frame
	wolf.hit(999)
	assert(wolf.dead and wolf.visible and not state.looted.has(wolf.id))
	var gold_before: int = state.inventory.gold
	assert(save_game())
	assert(load_game())
	wolf = enemies.filter(func(e): return e.id=="feedback_wolf")[0]
	assert(wolf.dead and wolf.visible and not state.looted.has(wolf.id))
	camera.rotation.x = -0.45
	await capture("03-searchable-body")
	var found := nearest_interaction()
	assert(found.get("type")=="corpse","A fallen body must be selectable")
	press_key(KEY_E)
	assert(state.looted.has(wolf.id) and state.inventory.fur==1)
	wolf.search_body()
	assert(state.inventory.fur==1 and state.inventory.gold==gold_before,"Searching twice must never duplicate loot")
	assert(save_game() and load_game())
	assert(state.looted.has("feedback_wolf") and state.inventory.fur==1)
	assert(world.foraging.size()>20)
	harvest("berries_00")
	harvest("berries_00")
	assert(state.inventory.berries==2)
	assert(not world.foraging.berries_00.node.visible,"A picked berry bush must disappear completely")
	var edible_id := ""
	var inedible_id := ""
	for id in world.foraging:
		if world.foraging[id].kind=="mushrooms":
			edible_id = id
		if world.foraging[id].kind=="toadstools":
			inedible_id = id
	assert(not edible_id.is_empty() and not inedible_id.is_empty())
	harvest(edible_id)
	harvest(inedible_id)
	state.health = 50
	use_item("mushrooms")
	assert(state.health==68 and state.inventory.toadstools==1)
	assert(save_game() and load_game())
	assert(state.taken.has(edible_id) and state.taken.has(inedible_id) and state.inventory.berries==2)
	assert(not world.foraging.berries_00.node.visible,"Picked bushes must stay absent after save/load")
	for id in ["herb_1","herb_2","herb_3"]:
		assert(world.outside_buildings(C.OBJECTS[id].pos,0.2),"Yarrow must be outside the hut")
	var legacy_path := data_root().path_join("reports/pre-0.3-player-save.json")
	if FileAccess.file_exists(legacy_path):
		var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(legacy_path))
		assert(validate_save(legacy),"The player's schema-2 save must remain loadable")
		var migrated = State.new()
		assert(migrated.read_dict(legacy.state,2))
		assert(migrated.inventory.gold==legacy.state.inventory.gold)
		assert(migrated.xp==legacy.state.xp and migrated.flags==legacy.state.flags)
		for id in legacy.state.defeated:
			assert(migrated.looted.has(id),"Old auto-awarded loot must not become claimable twice")
	teleport(Vector2(-14,31))
	camera.rotation.x = 0.9
	await capture("03-roof-inside")
	teleport(Vector2(-3,43),0.6)
	camera.rotation.x = 0
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	await capture("03-shield-inner-side")
	mouse = mouse.duplicate()
	mouse.pressed = false
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	for style in range(3):
		swing_duration = 0.48
		swing = swing_duration*0.5
		swing_style = style
		await capture("03-sword-motion-%d" % style)
	talk("mara")
	await capture("03-mara-close")
	press_key(KEY_ESCAPE)
	teleport(Vector2(-76,-57),0.3)
	camera.rotation.x = -0.1
	await capture("03-grove-outside")
	# Regressions from the remaining Nov 8 field notes.
	assert(get_tree().get_nodes_in_group("tree_trunks").size()==world.tree_locations.size())
	for id in C.NPCS:
		var eyes_open: Texture2D = world.library.npc(id,false)
		var eyes_closed: Texture2D = world.library.npc(id,true)
		assert(eyes_open.get_size()==eyes_closed.get_size(),"Blink must preserve the entire painted body's bounds")
		if id not in ["sister","mara","osric","rook"]:
			assert(eyes_open==eyes_closed,"Unedited NPCs keep their one stable master")
	for id in world.foraging:
		if id.begins_with("mushroom_"):
			for trunk in world.tree_locations:
				assert(world.foraging[id].pos.distance_to(trunk)>=3.8,"Mushrooms must clear rotating roots")
	assert(world.mill_wheel.position.x+0.8 < -5.5)
	assert(world.npc_ground(C.NPCS.courier.pos).y-C.NPC_HEIGHTS.courier*0.5 >= C.height_at(-117,-241)+0.2)
	var cleanup := spawn_enemy("cleanup_regression","wolf",Vector2(0,-50))
	cleanup.hit(999)
	cleanup.search_body()
	for blink_index in range(6):
		cleanup.tick(0.14)
		if blink_index<5:
			assert(cleanup.visual.visible==(int(cleanup.cleanup_clock/0.14)%2==0))
	cleanup.tick(0.01)
	assert(not cleanup.visible and cleanup.cleanup_clock<0)
	var effects := get_tree().get_nodes_in_group("combat_fx").size()
	cleanup.tick(1.0)
	cleanup.search_body()
	assert(get_tree().get_nodes_in_group("combat_fx").size()==effects,"Cleanup smoke must happen once")
	var actual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(data_root().path_join("reports/pre-0.3.1-player-save.json")))
	assert(validate_save(actual),"Current player save remains compatible")
	print("FEEDBACK PASS: dialogue continuation, shop requirements, persistent searchable bodies, one-time loot, foraging, food separation, hut placement, player-save migration and rendered regressions")
	get_tree().quit()

func route_walk(points: Array) -> bool:
	for point in points:
		route_goal = point
		var last := Vector2(player.position.x,player.position.z)
		var stuck := 0.0
		var timeout := 0.0
		while Vector2(player.position.x,player.position.z).distance_to(point)>0.65:
			await get_tree().physics_frame
			var now := Vector2(player.position.x,player.position.z)
			route_distance += now.distance_to(last)
			stuck = stuck+get_physics_process_delta_time() if now.distance_to(last)<0.002 else 0.0
			timeout += get_physics_process_delta_time()
			if stuck>4 or timeout>70:
				push_error("ROUTE BLOCKED from %s to %s at %s" % [last,point,player.position])
				return false
			last = now
	return true

func route_test() -> void:
	start_new()
	for e in enemies:
		e.collision_layer = 0
	route_active = true
	route_goal = Vector2(0,42)
	Engine.time_scale = 6.0
	var routes := [
		[Vector2(0,30),Vector2(-4,27)],
		[Vector2(0,30),Vector2(0,12),Vector2(-12,-20),Vector2(0,-55),Vector2(8,-92),Vector2(8,-103)],
		[Vector2(8,-112),Vector2(0,-120),Vector2(-35,-130),Vector2(-75,-145),Vector2(-109,-155)],
		[Vector2(-109,-151),Vector2(-132,-151),Vector2(-132,-168)],
		[Vector2(-132,-151),Vector2(-115,-146),Vector2(-75,-145),Vector2(-35,-130),Vector2(0,-120),Vector2(15,-162),Vector2(55,-165),Vector2(95,-183),Vector2(130,-193),Vector2(132,-211),Vector2(132,-217)]
	]
	for points in routes:
		if not await route_walk(points):
			get_tree().quit(1)
			return
	teleport(Vector2(130,-369))
	if not await route_walk([Vector2(130,-392),Vector2(116,-394),Vector2(130,-394),Vector2(145,-397),Vector2(130,-397),Vector2(130,-416),Vector2(130,-367)]):
		get_tree().quit(1)
		return
	teleport(Vector2(-115,-218))
	if not await route_walk([Vector2(-117,-242),Vector2(-115,-260),Vector2(-90,-270),Vector2(-30,-270),Vector2(0,-285),Vector2(0,-330),Vector2(0,-341)]):
		get_tree().quit(1)
		return
	print("ROUTE PASS: inn, main road, toll, mill/oil, chapel entry, all crypt seals, fen and beacon reachable. Walked %dm; walking-only simulation %ds" % [route_distance,state.elapsed])
	get_tree().quit()

func bot_target() -> Node:
	var best: Node = null
	var distance := 50.0
	for foe in enemies:
		if foe.dead or foe.shielded:
			continue
		var d: float = foe.position.distance_to(player.position)
		if d<distance:
			distance = d
			best = foe
	return best

func combat_test() -> void:
	start_new()
	state.flags.prepared = true
	state.flags.accepted = true
	state.inventory.tonic = 6
	state.damage = 43
	state.flags.sword_upgrade = true
	teleport(Vector2(0,-340))
	interact_object("beacon")
	bot_active = true
	Engine.time_scale = 3.0
	var fight_start: float = state.elapsed
	while not state.flags.won and state.elapsed-fight_start<240:
		await get_tree().physics_frame
		if state.wave==3 and not FileAccess.file_exists(data_root().path_join("reports/bell-warden.png")):
			await capture("bell-warden")
	bot_active = false
	await capture("combat-result")
	if not state.flags.won:
		push_error("COMBAT FAIL: live defence did not finish. State saved in reports/combat-failure.json")
		var f := FileAccess.open(data_root().path_join("reports/combat-failure.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify(snapshot(),"\t"))
		get_tree().quit(1)
		return
	assert(state.deaths==0,"A prepared warrior should survive the live defence")
	print("COMBAT PASS: live three-wave defence, both echo wards and guardian defeated in %.1fs simulation; %d tonics remaining, %d heavy attacks, %d deaths" % [state.elapsed-fight_start,state.inventory.tonic,bot_heavy_count,state.deaths])
	get_tree().quit()

func settings_path() -> String:
	return data_root().path_join("reports/integration-settings.cfg" if test_mode else "settings.cfg")

func forest_test() -> void:
	start_new()
	await get_tree().physics_frame
	assert(camera.position.y>=C.EYE_HEIGHT-0.03 and C.PLAYER_HEIGHT==1.95)
	assert(world.outside_buildings(C.NPCS.osric.pos,1.0),"Osric needs room for the full turning silhouette")
	for id in C.NPCS:
		if id in preload("res://scripts/march_content.gd").HEIGHTS:
			assert(C.NPC_HEIGHTS[id]==preload("res://scripts/march_content.gd").HEIGHTS[id],"New dwarf/ogre NPCs keep their authored stature")
		else:
			assert(C.NPC_HEIGHTS[id]>=1.8 and C.NPC_HEIGHTS[id]<=2.0)
		assert(absf(world.npcs[id].texture.get_height()*world.npcs[id].pixel_size-C.NPC_HEIGHTS[id])<0.01)
	var specimen: Dictionary = world.forest.records[0]
	for record in world.forest.records:
		if record.family==0 and record.p.distance_to(Vector2(0,30))<65 and C.distance_to_road(record.p)<12:
			specimen = record
			break
	var p: Vector2 = specimen.p
	var fixed_roots: Array = []
	for trunk in get_tree().get_nodes_in_group("tree_trunks"):
		fixed_roots.append(trunk.global_transform)
	var from := C.ground(p,1.5)+Vector3(3,0,0)
	var to := C.ground(p,1.5)-Vector3(3,0,0)
	var collision := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
	assert(not collision.is_empty() and collision.collider.is_in_group("tree_trunks"))
	set_modal("pause")
	ui.pause_panel.hide()
	state.day_clock = 14.0
	world.tick(0.0)
	visuals.values.enabled = false
	for tree_mode in range(visuals.TREES.size()):
		visuals.values.trees = tree_mode
		ui.apply_visuals()
		var stored_transform: Transform3D = specimen.card.global_transform
		for view in range(3):
			var angle := float(view)*TAU/3.0+0.4
			var at := p+Vector2(sin(angle),cos(angle))*20.0
			teleport(at)
			player.position.y = C.height_at(at.x,at.y)
			camera.look_at(C.ground(p,float(specimen.height)*0.48),Vector3.UP)
			await capture("05-tree-%d-view-%d" % [tree_mode,view])
			assert(specimen.card.global_transform==stored_transform,"Trees must keep their fixed world transform while orbiting")
			if view==0:
				ui.hud_root.hide()
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(data_root().path_join("reports/05-forest-preview-%d.png" % tree_mode))
				ui.hud_root.show()
		var index := 0
		for trunk in get_tree().get_nodes_in_group("tree_trunks"):
			assert(trunk.global_transform==fixed_roots[index],"Tree settings must never move collision")
			index += 1
	assert(world.forest.records.size()==fixed_roots.size())
	visuals.values.trees = 0
	visuals.values.enabled = true
	visuals.values.detail = 2
	visuals.values.dither = 0.5
	visuals.values.grain = 0.3
	for preset in [1,5]:
		visuals.values.preset = preset
		ui.apply_visuals()
		# Reproduce the reported pale middle-distance trees from the saved camera.
		teleport(Vector2(0.6405,-67.543),2.0713)
		player.position.y = C.height_at(player.position.x,player.position.z)
		camera.rotation.x = -0.0018
		state.day_clock = 17.4
		world.tick(0.0)
		await capture("05-mid-distance-%d" % preset)
		visuals.values.trees = 3
		ui.apply_visuals()
		await capture("05-mid-distance-cards-%d" % preset)
		visuals.values.trees = 0
		ui.apply_visuals()
		teleport(Vector2(10,30.5),0.0)
		player.position.y = C.height_at(player.position.x,player.position.z)
		camera.look_at(world.npcs.osric.global_position+Vector3(0,0.65,0),Vector3.UP)
		await capture("05-osric-human-scale-%d" % preset)
	visuals.values.preset = 5
	ui.apply_visuals()
	set_modal("")
	set_modal("pause")
	ui.open_settings("pause")
	ui.settings_trees.item_selected.emit(1)
	assert(visuals.values.trees==1)
	ui.settings_toggle.set_pressed(false)
	assert(visuals.values.trees==1 and world.forest.mode==1,"Tree modes work with Retro look off")
	var stored = preload("res://scripts/visual_settings.gd").new()
	stored.read(settings_path())
	assert(stored.values==visuals.values and snapshot().visual_settings.tree_mode=="Crossed paintings")
	ui.settings_toggle.set_pressed(true)
	ui.settings_trees.item_selected.emit(0)
	await capture("05-tree-settings")
	ui.leave_settings()
	set_modal("")
	set_modal("pause")
	ui.pause_panel.hide()
	DisplayServer.window_set_size(Vector2i(2560,1440))
	await get_tree().process_frame
	await get_tree().process_frame
	var performance: Array = []
	for tree_mode in range(4):
		visuals.values.trees = tree_mode
		ui.apply_visuals()
		await get_tree().create_timer(0.2).timeout
		var began := Time.get_ticks_usec()
		for frame in range(90):
			await RenderingServer.frame_post_draw
		var seconds := float(Time.get_ticks_usec()-began)/1000000.0
		performance.append({"mode":visuals.TREES[tree_mode].name,"frames":90,"fps":90.0/seconds,"resolution":[get_viewport().size.x,get_viewport().size.y]})
	var performance_file := FileAccess.open(data_root().path_join("reports/forest-performance.json"),FileAccess.WRITE)
	performance_file.store_string(JSON.stringify(performance,"\t"))
	performance_file.close()
	print("FOREST PASS: four rendered tree modes from three angles, stable root collision, camera/body scale, Osric clearance, richer palette, middle-distance fog and persistent independent tree settings")
	get_tree().quit()

func visual_test() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Exercise the real menu controls, persistence and modal return paths.
	visuals.values = visuals.DEFAULTS.duplicate()
	visuals.values.enabled = false
	ui.apply_visuals()
	assert(not ui.retro_effect.visible)
	ui.open_settings("title")
	assert(modal=="settings" and get_tree().paused and not started)
	ui.settings_toggle.set_pressed(true)
	ui.settings_style.select(3)
	ui.settings_style.item_selected.emit(3)
	assert(visuals.values.enabled and visuals.values.preset==3)
	var stored = preload("res://scripts/visual_settings.gd").new()
	stored.read(settings_path())
	assert(stored.values==visuals.values,"Visual preferences must survive restarting")
	await get_tree().process_frame
	assert(ui.settings_preview.size.x==680 and ui.settings_preview.size.y<383,"Preview must stay within the settings panel")
	ui.settings_style.show_popup()
	await get_tree().process_frame
	await get_tree().process_frame
	press_key(KEY_ESCAPE)
	await get_tree().process_frame
	assert(modal=="settings" and not ui.settings_style.get_popup().visible,"Esc closes the dropdown before the settings menu")
	await capture("04-settings-title")
	press_key(KEY_ESCAPE)
	assert(modal=="" and not started and get_tree().paused)
	start_new()
	teleport(Vector2(-3,43),0.6)
	state.day_clock = 14.5
	await get_tree().physics_frame
	# Save a clean world preview from the actual scene, without interface chrome.
	ui.hud_root.hide()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(data_root().path_join("reports/04-preview-source.png"))
	ui.hud_root.show()
	set_modal("pause")
	ui.open_settings("pause")
	var elapsed_before: float = state.elapsed
	await get_tree().create_timer(0.15).timeout
	assert(state.elapsed==elapsed_before and get_tree().paused)
	press_key(KEY_ESCAPE)
	assert(modal=="pause" and get_tree().paused)
	press_key(KEY_ESCAPE)
	assert(modal=="" and not get_tree().paused)
	assert(ui.hud_root.get_children().find(ui.weapon)>ui.hud_root.get_children().find(ui.shield),"Sword must draw in front of shield")
	assert(ui.hud_root.get_children().find(ui.retro_effect)>ui.hud_root.get_children().find(ui.weapon),"One treatment must cover world and weapons")
	visuals.values.enabled = false
	ui.apply_visuals()
	await capture("04-original-inn")
	for preset in range(visuals.PRESETS.size()):
		visuals.values.enabled = true
		visuals.values.preset = preset
		ui.apply_visuals()
		await capture("04-style-%d-inn" % preset)
		teleport(Vector2(-126,-150),0.0)
		camera.rotation.x = -0.15
		await capture("04-style-%d-water" % preset)
		teleport(Vector2(10,-325),0.0)
		state.day_clock = 20.0
		world.tick(0.0)
		await capture("04-style-%d-night" % preset)
		teleport(Vector2(-3,43),0.6)
		state.day_clock = 14.5
		world.tick(0.0)
	visuals.values.preset = 1
	ui.apply_visuals()
	talk("ilya")
	await capture("04-retro-dialogue")
	press_key(KEY_ESCAPE)
	set_modal("pause")
	ui.open_settings("pause")
	await capture("04-settings-game")
	press_key(KEY_QUOTELEFT)
	assert(reporting and get_tree().paused)
	assert(report_snapshot.visual_settings.name=="Copper & Pine")
	ui.report_entry.text = "AUTOMATED retro settings / paused report regression"
	assert(submit_report())
	assert(modal=="settings" and get_tree().paused)
	ui.leave_settings()
	set_modal("")
	visuals.values.enabled = false
	ui.apply_visuals()
	teleport(Vector2(-117.34,-240.88),0.0)
	camera.rotation.x = 0.12
	await capture("04-tomas-clean")
	teleport(Vector2(-3,43),0.6)
	blocking = false
	ui.tick(0.0)
	await capture("04-shield-rest")
	for style in range(3):
		for step in range(3):
			swing_style = style
			swing_duration = 1.0
			swing = 1.0-[0.2,0.5,0.7][step]
			ui.tick(0.0)
			await capture("04-strike-%d-%d" % [style,step])
	# Corrupt or out-of-range settings may never feed bad shader values.
	var invalid := ConfigFile.new()
	invalid.set_value("visuals","preset",999)
	invalid.set_value("visuals","detail",-5)
	invalid.set_value("visuals","grain","not a number")
	invalid.set_value("visuals","enabled","yes")
	var invalid_path := data_root().path_join("reports/invalid-settings.cfg")
	assert(invalid.save(invalid_path)==OK)
	stored.read(invalid_path)
	assert(stored.values.preset==visuals.PRESETS.size()-1 and stored.values.detail==0 and not stored.values.enabled)
	assert(stored.values.grain==stored.DEFAULTS.grain)
	# Exercise the actual full-screen pixel grid at the player's reported resolution.
	DisplayServer.window_set_size(Vector2i(2560,1440))
	await get_tree().process_frame
	await get_tree().process_frame
	visuals.values.enabled = true
	visuals.values.preset = 1
	ui.apply_visuals()
	await capture("04-retro-1440p")
	ui.open_settings("pause")
	await capture("04-settings-1440p")
	ui.leave_settings()
	set_modal("")
	var performance_results: Array = []
	for preset in range(visuals.PRESETS.size()):
		visuals.values.preset = preset
		ui.apply_visuals()
		await get_tree().create_timer(0.15).timeout
		var began := Time.get_ticks_usec()
		for frame in range(60):
			await RenderingServer.frame_post_draw
		var seconds := float(Time.get_ticks_usec()-began)/1000000.0
		performance_results.append({"preset":visuals.PRESETS[preset].name,"frames":60,"seconds":seconds,"fps":60.0/seconds,"resolution":[get_viewport().size.x,get_viewport().size.y]})
	var performance_file := FileAccess.open(data_root().path_join("reports/retro-performance.json"),FileAccess.WRITE)
	performance_file.store_string(JSON.stringify(performance_results,"\t"))
	performance_file.close()
	print("VISUAL PASS: main/pause settings, persistent preferences, nine rendered presets at day/water/night, sharp dialogue, paused diagnostics with visual metadata, sword layering, shield clearance, Tomas cutout and invalid-config handling")
	get_tree().quit()

func use_quick_slot(index: int) -> void:
	if index<0 or index>=state.pack.slots.size(): return
	var key: String = state.pack.slots[index]
	ui.quickbar.highlighted = index
	ui.quickbar.highlight_time = state.elapsed+0.45
	match key:
		"lantern": toggle_lantern()
		"torch": toggle_torch()
		"rest": rest()
		"wood": place_fire()
		"": message("Slot %d is empty. Open I and select an item to assign it." % (index+1))
		_:
			state.pack.sync(state.inventory)
			if state.inventory.get(key,0)>0:
				if state.pack.ITEMS[key].usable:
					use_item(key)
				else:
					set_modal("inventory")
					ui.backpack.selected = key
					ui.backpack.notice = "%s: %d carried. %s" % [state.pack.details(key).name,state.inventory[key],state.pack.details(key).use]
			else:
				message("No %s left. This shortcut stays bound for when you find more." % state.pack.details(key).name)

func survival_test() -> void:
	# Pixel/collision fixtures below are authored for the logical 1280x720 view.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280,720))
	start_new()
	await get_tree().physics_frame
	var legacy: Dictionary = snapshot()
	legacy.schema_version = 3
	var previous_save := data_root().path_join("reports/pre-0.5-player-save.json")
	if FileAccess.file_exists(previous_save):
		legacy = JSON.parse_string(FileAccess.get_file_as_string(previous_save))
	assert(validate_save(legacy),"The player's previous journey must remain compatible")
	var migrated = State.new()
	assert(migrated.read_dict(legacy.state,int(legacy.schema_version)))
	assert(migrated.inventory==legacy.state.inventory and migrated.flags==legacy.state.flags)
	var pack = preload("res://scripts/backpack.gd").new()
	assert(pack.move("wood",Vector2i(5,5),true))
	assert(not pack.move("tonic",Vector2i(5,5),false),"Overlapping items cannot be placed")
	assert(not pack.move("wood",Vector2i(7,5),false),"Items must remain inside the bag")
	assert(pack.layout.wood.rotated)
	for key in pack.ITEMS:
		state.inventory[key] = 5
	state.pack.sync(state.inventory)
	assert(state.pack.arrange(state.inventory) and state.pack.unpacked.is_empty())
	assert(state.pack.layout.size()==pack.ITEMS.size())
	var saved_layout: Dictionary = state.pack.layout.duplicate(true)
	var restored = preload("res://scripts/backpack.gd").new()
	assert(restored.restore(JSON.parse_string(JSON.stringify(state.pack.record())),state.inventory))
	assert(restored.layout==saved_layout)
	var bad: Dictionary = state.pack.record()
	bad.layout.tonic.x = bad.layout.wood.x
	bad.layout.tonic.y = bad.layout.wood.y
	assert(not restored.restore(bad,state.inventory),"Overlapping saved layouts are rejected")
	press_key(KEY_I)
	assert(modal=="inventory" and get_tree().paused)
	# Drive the drag/rotate/drop path through the actual backpack control.
	var wood: Dictionary = state.pack.layout.wood.duplicate()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = ui.backpack.ORIGIN+Vector2(wood.x,wood.y)*ui.backpack.CELL+Vector2(12,12)
	ui.backpack._gui_input(down)
	assert(ui.backpack.held=="wood")
	press_key(KEY_R)
	var found_cell := Vector2i(-1,-1)
	for y in range(6):
		for x in range(8):
			if state.pack.fits("wood",Vector2i(x,y),not wood.rotated):
				found_cell = Vector2i(x,y)
				break
		if found_cell.x>=0:
			break
	assert(found_cell.x>=0)
	var point: Vector2 = ui.backpack.ORIGIN+Vector2(found_cell)*ui.backpack.CELL+Vector2(12,12)
	Input.warp_mouse(ui.backpack.get_global_transform_with_canvas()*point)
	await get_tree().process_frame
	var release := down.duplicate() as InputEventMouseButton
	release.pressed = false
	release.position = point
	ui.backpack._gui_input(release)
	assert(ui.backpack.held.is_empty() and state.pack.layout.wood.rotated!=wood.rotated)
	ui.backpack.selected = "tonic"
	var tonics: int = state.inventory.tonic
	press_key(KEY_8)
	assert(state.pack.slots[7]=="tonic" and state.inventory.tonic==tonics)
	ui.backpack.held = "wood"
	ui.backpack.rotated = false
	press_key(KEY_R)
	assert(ui.backpack.rotated)
	press_key(KEY_ESCAPE)
	assert(modal=="inventory" and ui.backpack.held.is_empty())
	await capture("06-backpack")
	var clock: float = state.weather.clock
	await get_tree().create_timer(0.15).timeout
	assert(state.weather.clock==clock,"Inventory must pause weather/exposure")
	press_key(KEY_QUOTELEFT)
	assert(reporting and report_snapshot.state.backpack.slots[7]=="tonic")
	ui.report_entry.text = "AUTOMATED inventory / weather / paused diagnostic export"
	assert(submit_report() and modal=="inventory" and get_tree().paused)
	press_key(KEY_I)
	state.health = 35
	press_key(KEY_8)
	assert(state.health==90 and state.inventory.tonic==tonics-1)
	var light_before: bool = lantern.visible
	press_key(KEY_6)
	assert(lantern.visible!=light_before)
	press_key(KEY_6)
	state.day_clock = 20.0
	state.pack.bind_slot(7,"torch")
	press_key(KEY_8)
	assert(torch_equipped and torch_light.visible and not blocking)
	var ghost := spawn_enemy("torch_ward_regression","wraith",Vector2(player.position.x,player.position.z-3))
	ghost.tick(0.1)
	assert(ghost.phase=="idle" and ghost.velocity.dot(ghost.position-player.position)>0,"A torch must drive ordinary night spirits back")
	ghost.hit(999)
	ui.tick(0)
	assert(not ui.shield.visible and ui.torch_view.visible)
	await capture("06-torch-night")
	press_key(KEY_T)
	assert(not torch_equipped)
	state.pack.bind_slot(7,"tonic")
	state.day_clock = 20.0
	weather.force("heavy")
	state.wetness = 0
	state.cold = 0
	var health_before: float = state.health
	for second in range(180):
		weather.update_exposure(1.0,false,false)
	var bare_wet: float = state.wetness
	var bare_cold: float = state.cold
	assert(bare_wet>60 and bare_cold>35 and weather.stamina_factor()<1.0)
	assert(state.health==health_before,"Exposure is nonlethal")
	state.wetness = 0
	state.cold = 0
	state.flags.coat_upgrade = true
	for second in range(180):
		weather.update_exposure(1.0,false,false)
	assert(state.wetness<bare_wet and state.cold<bare_cold)
	for second in range(180):
		weather.update_exposure(1.0,true,true)
	assert(state.wetness==0 and state.cold==0)
	teleport(Vector2(130,-380))
	assert(weather.under_roof())
	weather.shelter_clock = 0
	weather.tick(0)
	assert(not weather.rain.visible)
	teleport(Vector2(0,47),0.55)
	state.day_clock = 14.5
	state.flags.coat_upgrade = false
	for id in ["clear","clouds","rain","heavy","wind","storm"]:
		weather.force(id)
		weather.shelter_clock = 0
		set_modal("")
		await get_tree().create_timer(0.45).timeout
		assert(not weather.sheltered)
		if id=="storm":
			weather.strike()
			weather.apply_visuals()
			world.tick(0)
		await capture("06-weather-"+id)
		if id=="clear":
			# Sample the world at viewport-relative points: one dark dither pixel
			# or a changed desktop resolution must not masquerade as a black frame.
			var scene_image := get_viewport().get_texture().get_image()
			var brightness := 0.0
			for y in range(4):
				for x in range(8):
					var pixel := scene_image.get_pixel(int(scene_image.get_width()*(.28+x*.055)),int(scene_image.get_height()*(.2+y*.09)))
					brightness += pixel.r+pixel.g+pixel.b
			assert(brightness/32.0>0.3,"Retro pass must retain the rendered world after soft-depth effects")
		set_modal("pause")
		ui.pause_panel.hide()
	weather.force("clear")
	state.weather.age = 85.1
	weather.tick(0)
	assert(weather.kind()=="clouds","The automatic weather sequence must advance")
	weather.force("storm")
	state.wetness = 65
	state.cold = 58
	var record := snapshot()
	assert(validate_save(record) and save_game() and load_game())
	assert(state.wetness==65 and state.cold==58 and weather.kind()=="storm" and state.pack.slots[7]=="tonic")
	var invalid := snapshot()
	invalid.state.wetness = -1
	assert(not validate_save(invalid))
	var purse_before: int = state.inventory.gold
	state.flags.courier_done = true
	state.flags.supplies = true
	state.flags.scout = false
	talk("ilya")
	assert(ui.dialog_body.text.contains("Tomas") and ui.dialog_body.text.contains("complete"))
	choose_dialog("ilya_next")
	assert(state.inventory.gold==purse_before and state.flags.scout)
	var report_xp: int = state.xp
	choose_dialog("ilya_next")
	assert(state.xp==report_xp,"Finishing Tomas early must not duplicate Ilya's report reward or stall the main quest")
	set_modal("")
	teleport(Vector2(130,-365))
	await get_tree().physics_frame
	for z in [-362.0,-420.0]:
		for x in [120.0,140.0]:
			var wall := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(130,2,z),Vector3(x,2,z),1))
			assert(not wall.is_empty(),"Crypt end walls must not leave side gaps")
	player.position = Vector3(131.5138,0.151,-364.2501)
	player.rotation.y = -1.8667
	camera.rotation = Vector3(-0.0055,0,0)
	await capture("06-crypt-walls")
	invalid = snapshot()
	invalid.state.weather.phase = 99
	assert(not validate_save(invalid))
	ui.open_settings("pause")
	ui.settings_art.hide()
	ui.settings_world.show()
	ui.settings_wind.item_selected.emit(3)
	ui.settings_blood.item_selected.emit(1)
	assert(visuals.values.wind_strength==3 and visuals.values.blood_size==1)
	var preferences = preload("res://scripts/visual_settings.gd").new()
	preferences.read(settings_path())
	assert(preferences.values.wind_strength==3 and preferences.values.blood_size==1)
	await capture("06-world-settings")
	ui.leave_settings()
	set_modal("")
	weather.force("clear")
	state.day_clock = 14.5
	state.wetness = 0
	state.cold = 0
	teleport(Vector2(10.5,29.5),0)
	await get_tree().create_timer(0.4).timeout
	camera.look_at(world.npcs.osric.position+Vector3(0,0.65,0),Vector3.UP)
	await capture("06-osric-no-seam")
	# Keep the reported view as a stable fixture after the user clears old logs.
	var seam := {"player":{"position":[10.094401,1.533813,27.367537],"yaw":-1.798485,"pitch":-0.2240003}}
	set_modal("pause")
	ui.pause_panel.hide()
	player.position = Vector3(seam.player.position[0],seam.player.position[1],seam.player.position[2])
	player.rotation.y = seam.player.yaw
	camera.rotation = Vector3(seam.player.pitch,0,0)
	await capture("06-osric-reported-camera")
	visuals.values.enabled = false
	ui.apply_visuals()
	await capture("06-osric-unfiltered")
	var lantern_before: bool = lantern.visible
	lantern.hide()
	await capture("06-osric-no-lantern")
	var local_lights := world.find_children("*","OmniLight3D",true,false)
	var light_visibility: Array = []
	for light in local_lights:
		light_visibility.append(light.visible)
		light.hide()
	await capture("06-osric-no-local-lights")
	var actor_material: Material = world.npcs.osric.material_override
	var flat_shader := Shader.new()
	flat_shader.code = (actor_material as ShaderMaterial).shader.code.replace("ALBEDO=road_atmosphere(colour,world_at,INV_VIEW_MATRIX[3].xyz);","ALBEDO=vec3(.05,.65,.05);")
	var flat_material := ShaderMaterial.new()
	flat_material.shader = flat_shader
	flat_material.set_shader_parameter("image",world.npcs.osric.texture)
	world.npcs.osric.material_override = flat_material
	await capture("06-osric-flat-before-glow")
	var before_glow := get_viewport().get_texture().get_image()
	var crossing_glow: MeshInstance3D = world.glow(C.ground(C.NPCS.osric.pos,1.8),1.1,Color(1,0.55,0.16,0.8))
	await capture("06-osric-flat-diagnostic")
	var flat_image := get_viewport().get_texture().get_image()
	# Terrain/camera changes move the actor: sample its actual diagnostic mask.
	var actor_pixels := 0
	for row in range(180,590):
		for column in range(400,850):
			var before := before_glow.get_pixel(column,row)
			if before.g>0.45 and before.r<0.20 and before.b<0.20:
				actor_pixels += 1
				assert(absf(flat_image.get_pixel(column,row).r-before.r)<0.12,"A crossing glow must not cut a bright band into an actor")
	assert(actor_pixels>1000,"The occlusion test must inspect the actor, not its background")
	crossing_glow.queue_free()
	world.npcs.osric.material_override = actor_material
	for i in range(local_lights.size()):
		local_lights[i].visible = light_visibility[i]
	lantern.visible = lantern_before
	visuals.values.enabled = true
	ui.apply_visuals()
	set_modal("")
	teleport(Vector2(-128,-146),0.0)
	await get_tree().create_timer(0.35).timeout
	camera.look_at(C.ground(Vector2(-135,-165),0.25),Vector3.UP)
	await capture("06-mill-river")
	teleport(Vector2(0,47),0.55)
	await get_tree().create_timer(0.35).timeout
	world.impact(player.position-player.basis.z*3+Vector3(0,1.0,0),false,true)
	world.impact(player.position-player.basis.z*3+player.basis.x*1.5+Vector3(0,1.0,0),true,true)
	await get_tree().create_timer(0.12).timeout
	await capture("06-liquid-splashes")
	DisplayServer.window_set_size(Vector2i(2560,1440))
	weather.force("storm")
	await get_tree().create_timer(0.6).timeout
	var began := Time.get_ticks_usec()
	for frame in range(90):
		await RenderingServer.frame_post_draw
	var seconds := float(Time.get_ticks_usec()-began)/1000000.0
	var performance_file := FileAccess.open(data_root().path_join("reports/weather-performance.json"),FileAccess.WRITE)
	performance_file.store_string(JSON.stringify({"weather":"storm","frames":90,"fps":90.0/seconds,"resolution":[get_viewport().size.x,get_viewport().size.y]},"\t"))
	performance_file.close()
	print("SURVIVAL PASS: tetris bounds/rotation/overlap/auto-arrange, eight quick slots, legacy migration, schema-4 save roundtrip, wet/cold/coat/fire/shelter, six changing weather states, lightning, wind/effects settings, paused reports and rendered regressions")
	get_tree().quit()

func toggle_lantern() -> void:
	if ranger.active() and (state.ranger.reload_left>0 or state.ranger.weapon=="musket"):
		message("Both hands are needed. Select pistol [C] or dagger [Q] before holding a light.",3)
		return
	lantern.visible = not lantern.visible
	if lantern.visible:
		torch_equipped = false
		torch_light.hide()
	blocking = false
	message("Lantern held in left hand / offhand actions unavailable. L stows it." if lantern.visible else "Lantern stowed / left hand free.",3)

func toggle_torch() -> void:
	if ranger.active() and (state.ranger.reload_left>0 or state.ranger.weapon=="musket"):
		message("Both hands are needed. Select pistol [C] or dagger [Q] before holding a light.",3)
		return
	torch_equipped = not torch_equipped
	torch_light.visible = torch_equipped
	if torch_equipped: lantern.hide()
	blocking = false
	var profession: String = state.profile.profession_id
	if torch_equipped:
		message("Torch held / offhand actions unavailable. RMB swings it: weak against living foes, stronger against spirits. T stows it.")
	else:
		message("Buckler readied." if profession=="warrior" else "Cross readied." if profession=="cleric" else "Casting hand free.")

func offhand_busy() -> bool:
	return torch_equipped or lantern.visible

func stow_lights() -> void:
	torch_equipped = false
	torch_light.hide()
	lantern.hide()
	blocking = false

func torch_attack() -> void:
	if not torch_equipped or not started or modal!="" or reporting or attack_clock>0: return
	attack_clock = .9
	combat.animate("torch",.6)
	audio.play_effect("swing")
	for foe in enemies:
		if not combat.in_cone(foe,2.9,.7): continue
		var spirit: bool = foe.kind in ["wraith","guardian","mournkeeper"]
		foe.hit(maxf(36,state.damage*1.15) if spirit else minf(18,state.damage*.55),false,true)
		if spirit: foe.force_reaction(-camera.global_basis.z,2,.4,.5)
		break
	state.log_event("torch_strike")

func production_check() -> void:
	await preload("res://scripts/production_checks.gd").new().run(self)

func march_check() -> void:
	await preload("res://scripts/march_checks.gd").new().run(self)

func march_route() -> void:
	await preload("res://scripts/march_checks.gd").new().route(self)

func living_check() -> void:
	await preload("res://scripts/living_world_checks.gd").new().run(self)

func terrain_check() -> void:
	await preload("res://scripts/terrain_checks.gd").new().run(self)

func sound_check() -> void:
	await preload("res://scripts/sound_checks.gd").new().run(self)

func profession_check() -> void:
	await preload("res://scripts/profession_checks.gd").new().run(self)

func profession_encounters() -> void:
	await preload("res://scripts/profession_checks.gd").new().encounters(self)

func release_check() -> void:
	await preload("res://scripts/release_checks.gd").new().run(self)

func architecture_check() -> void:
	await preload("res://scripts/architecture_checks.gd").new().run(self)

func field_check() -> void:
	await preload("res://scripts/field_checks.gd").new().run(self)

func march_field_check() -> void:
	await preload("res://scripts/march_field_checks.gd").new().run(self)

func quest_access_check() -> void:
	await preload("res://scripts/quest_access_checks.gd").new().run(self)

func grass_check() -> void:
	await preload("res://scripts/grass_checks.gd").new().run(self)

func wilderness_check() -> void:
	await preload("res://scripts/wilderness_checks.gd").new().run(self)

func inventory_check() -> void:
	await preload("res://scripts/inventory_checks.gd").new().run(self)

func ranger_check() -> void:
	await preload("res://scripts/ranger_checks.gd").new().run(self)

func romance_check() -> void:
	await preload("res://scripts/romance_checks.gd").new().run(self)
	get_tree().quit()

func progress_stamp() -> int:
	return hash([state.flags,state.story,state.woods,state.taken,state.relationships,state.keepsakes,state.xp])

func choose_dialog(action: String) -> void:
	var before := progress_stamp()
	if action.begins_with("woods:") and woods.origin.begins_with("nw_") and woods.near(woods.origin):
		coop.transact("object",woods.origin,"_local_choose_dialog",[action])
	else:
		coop.transact("npc",dialogue_id,"_local_choose_dialog",[action])
	if before!=progress_stamp(): saves.request("A conversation changed the journey")

func interact_object(id: String) -> void:
	var before := progress_stamp()
	coop.transact("object",id,"_local_interact_object",[id])
	if before!=progress_stamp(): saves.request("A discovery recorded")

func harvest(id: String) -> void:
	coop.transact("forage",id,"_local_harvest",[id])

func place_fire() -> void:
	coop.transact("camp","fire","_local_place_fire",[])

func rest() -> void:
	coop.transact("camp","rest","_local_rest",[])

func coop_check() -> void:
	await preload("res://scripts/coop_checks.gd").new().run(self)

func coop_probe() -> void:
	await preload("res://scripts/coop_probe.gd").new().run(self)

func godrays_check() -> void:
	await preload("res://scripts/godrays_checks.gd").new().run(self)

func weeper_check() -> void:
	await preload("res://scripts/weeper_checks.gd").new().run(self)

func side_quest_check() -> void:
	await preload("res://scripts/side_quest_checks.gd").new().run(self)

func woods_check() -> void:
	await preload("res://scripts/woods_checks.gd").new().run(self)

func woods_preview() -> void:
	await preload("res://scripts/woods_checks.gd").new().preview(self)

func woods_capture() -> void:
	await preload("res://scripts/woods_checks.gd").new().captures(self)

func woods_route() -> void:
	await preload("res://scripts/woods_checks.gd").new().route(self)

func level_check() -> void:
	await preload("res://scripts/level_checks.gd").new().run(self)

func safety_check() -> void:
	await preload("res://scripts/safety_checks.gd").new().run(self)

func journal_check() -> void:
	await preload("res://scripts/journal_checks.gd").new().run(self)
