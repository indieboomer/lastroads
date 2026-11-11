extends "res://scripts/enemy.gd"

const Sites = preload("res://scripts/weeper_sites.gd")
const SCREAM_RANGE := 11.0
const SCREAM_HALF_ANGLE := 27.0
const LOCK_AT := .90
var scream_direction := Vector3.FORWARD
var interrupt_guard := 0.0
var feedback_clock := 0.0
var lament_clock := 1.0
var site_id := ""
var voice: AudioStreamPlayer3D
var breath_voice: AudioStreamPlayer3D
var cues = preload("res://scripts/weeper_audio.gd").new()
var cue_clock := 0.0
var cue_length := 0.0
var cue_gain := -12.0
var breath_left := 0.0
var breath_gain := -19.0
var scream_serial := 0
var last_scream_serial := 0
var cone_guide: MeshInstance3D
var last_phase := ""
var guide_clock := 0.0

func setup(owner_game: Node, uid: String, family: String, at: Vector3) -> void:
	super.setup(owner_game,uid,family,at)
	process_mode = Node.PROCESS_MODE_PAUSABLE
	site_id = uid.trim_prefix("weeper_intro_").trim_prefix("weeper_site_")
	var site: Dictionary = Sites.get_site(site_id)
	if not site.is_empty(): home = C.ground(site.pos+Vector2(0,3.5),.25)
	var saved: Dictionary = game.state.enemies.get(id,{})
	if not site.is_empty() and not saved.is_empty() and saved.get("weeper_site_revision",0)<1:
		var offset: Vector2 = site.pos-site.legacy_pos
		position += Vector3(offset.x,0,offset.y)
		position.y = C.height_at(position.x,position.z)+.25
	if C.ENEMY_TYPES.has("hollow_weeper") and game.State.valid_vector(saved.get("weeper_aim")):
		var p: Array = saved.weeper_aim
		scream_direction = Vector3(p[0],0,p[2]).normalized()
	interrupt_guard = clampf(float(saved.get("weeper_interrupt_guard",0.0)),0,3.0)
	scream_serial = int(saved.get("weeper_scream_serial",0))
	last_scream_serial = scream_serial
	voice = AudioStreamPlayer3D.new()
	voice.bus = game.audio.SOUND_BUS
	voice.unit_size = 18
	voice.max_distance = 100
	voice.position.y = 1.92
	voice.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(voice)
	breath_voice = AudioStreamPlayer3D.new()
	breath_voice.bus = game.audio.SOUND_BUS
	breath_voice.unit_size = 18
	breath_voice.max_distance = 70
	breath_voice.position.y = 2.28
	breath_voice.volume_db = -19
	add_child(breath_voice)
	cone_guide = MeshInstance3D.new()
	cone_guide.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cone_guide)
	render_pose()

func record() -> Dictionary:
	var data: Dictionary = super.record()
	data.weeper_aim = [scream_direction.x,0.0,scream_direction.z]
	data.weeper_interrupt_guard = interrupt_guard
	data.weeper_scream_serial = scream_serial
	data.weeper_site_revision = 1
	return data

func play_cue(event: String) -> void:
	if voice==null: return
	var cue: Dictionary = cues.choose(event)
	if cue.is_empty(): return
	if event=="recover":
		breath_voice.stream = cue.stream
		breath_left = cue.length
		breath_gain = -19+cue.gain
		breath_voice.volume_db = breath_gain
		breath_voice.play(cue.offset)
		return
	voice.stream = cue.stream
	cue_clock = 0
	cue_length = cue.length
	cue_gain = (-14 if event=="lament" else -12)+cue.gain
	voice.volume_db = cue_gain
	voice.play(cue.offset)
	if event in ["windup","sweep","death"]:
		breath_voice.stop()
		breath_left = 0

func _process(dt: float) -> void:
	if voice==null: return
	voice.stream_paused = game.audio.muted or game.reporting
	breath_voice.stream_paused = voice.stream_paused
	if not game.started:
		voice.stop()
		breath_voice.stop()
		return
	if not voice.stream_paused:
		cue_clock += dt
		if voice.playing:
			voice.volume_db = cue_gain+linear_to_db(clampf((cue_length-cue_clock)/.10,.0001,1))
			if cue_clock>=cue_length: voice.stop()
		breath_left = maxf(0,breath_left-dt)
		breath_voice.volume_db = breath_gain+linear_to_db(clampf(breath_left/.12,.0001,1))
		if breath_left<=0: breath_voice.stop()
	if dead:
		cone_guide.hide()
		return
	render_pose()
	lament_clock -= dt
	if phase!=last_phase:
		if phase=="windup": play_cue("windup")
		elif phase=="sweep_windup": play_cue("sweep")
		elif phase=="recover": play_cue("recover")
		last_phase = phase
	if scream_serial!=last_scream_serial:
		last_scream_serial = scream_serial
		play_cue("scream")
		for delay in [0.0,.13,.26]: emit_scream_ring(delay)
	if not engaged and lament_clock<=0:
		play_cue("lament")
		lament_clock = cue_length+14.0+float(absi(id.hash())%11)
	guide_clock -= dt
	if phase=="windup" and guide_clock<=0:
		guide_clock = .09
		update_cone()

func render_pose() -> void:
	if dead: return
	set_art_pose(1 if phase=="windup" else 2 if phase=="sweep_windup" else 5 if phase=="recover" or phase=="retreat" else 3 if hit_flash>0 else 0)
	visual.modulate = Color("d8ba9e") if phase=="windup" else Color(1.2,.75,.65) if hit_flash>0 else Color.WHITE
	if cone_guide: cone_guide.visible = phase=="windup"

func emit_scream_ring(delay: float) -> void:
	var direction := scream_direction
	var origin := global_position+Vector3.UP*2.1
	if not is_inside_tree(): return
	var ring := preload("res://scripts/weeper_scream.gd").new()
	ring.age = -delay
	game.add_child(ring)
	ring.global_position = origin
	ring.look_at(origin+direction,Vector3.UP)

func tick(dt: float) -> void:
	if dead:
		super.tick(dt)
		return
	interrupt_guard = maxf(0,interrupt_guard-dt)
	feedback_clock = maxf(0,feedback_clock-dt)
	hit_flash = maxf(0,hit_flash-dt)
	rimed = maxf(0,rimed-dt)
	brittle = maxf(0,brittle-dt)
	stun = 0
	if burning>0:
		burn_clock += minf(dt,burning)
		burning = maxf(0,burning-dt)
		if burn_clock>=.5:
			burn_clock -= .5
			hit(2,false,false)
			if dead: return
	var targets := all_targets()
	if targets.is_empty(): return
	targets.sort_custom(func(a,b): return a.p.distance_squared_to(position)<b.p.distance_squared_to(position))
	var target: Dictionary = targets[0]
	var offset: Vector3 = target.p-position
	offset.y = 0
	var distance := offset.length()
	if targets.any(func(player): return player.p.distance_to(home)<9): engaged = true
	if engaged and targets.all(func(player): return player.p.distance_to(home)>27) and distance>17:
		engaged = false
		phase = "idle"
		clock = 0
	velocity.x = 0
	velocity.z = 0
	velocity.y -= 24*dt
	if not engaged:
		phase = "idle"
		clock = 0
		if position.distance_to(home)>1.3: walk_toward(home-position,spec.speed*.7)
	elif phase=="windup":
		clock += dt
		if clock<LOCK_AT and distance>.01: scream_direction = offset.normalized()
		if clock>=spec.windup:
			release_scream()
			phase = "recover"
			clock = 0
	elif phase=="sweep_windup":
		clock += dt
		if clock<.45 and distance>.01: scream_direction = offset.normalized()
		if clock>=.75:
			for player in targets:
				var gap: Vector3 = player.p-position
				gap.y = 0
				if gap.length()<3.2 and gap.length()>.01 and scream_direction.dot(gap.normalized())>.5 and game.line_clear(position+Vector3.UP*1.5,player.eye): strike_target(player.id,36.0,"hollow_weeper_sweep")
			phase = "retreat"
			clock = 0
	elif phase=="retreat":
		clock += dt
		if position.distance_to(home)<18: walk_toward(-offset,spec.speed*1.2)
		if clock>=.8: phase = "recover"
	elif phase=="recover":
		clock += dt
		if clock>=spec.recovery: phase = "chase"; clock = 0
	else:
		if distance<=SCREAM_RANGE:
			scream_direction = offset.normalized() if distance>.01 else Vector3.FORWARD
			phase = "sweep_windup" if distance<2.9 else "windup"
			clock = 0
		elif position.distance_to(home)<18: walk_toward(offset,spec.speed*(.85 if rimed>0 else 1.0))
	move_and_slide()
	if position.y<C.height_at(position.x,position.z)-2: position.y = C.height_at(position.x,position.z)+.05
	render_pose()

func walk_toward(offset: Vector3, speed: float) -> void:
	offset.y = 0
	if offset.length()>.01:
		velocity.x = offset.normalized().x*speed
		velocity.z = offset.normalized().z*speed

func update_cone() -> void:
	var shape := ImmediateMesh.new()
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.albedo_color = Color(.78,.70,.50,.18 if clock<LOCK_AT else .30)
	shape.surface_begin(Mesh.PRIMITIVE_LINES,ink)
	var angle := atan2(scream_direction.x,scream_direction.z)
	for i in range(14):
		for step in [i,i+1]:
			var a: float = angle+deg_to_rad(-SCREAM_HALF_ANGLE+2*SCREAM_HALF_ANGLE*step/14.)
			var p := Vector2(position.x+sin(a)*SCREAM_RANGE,position.z+cos(a)*SCREAM_RANGE)
			shape.surface_add_vertex(C.ground(p,.08)-position)
	shape.surface_end()
	cone_guide.mesh = shape

func in_scream(at: Vector3) -> bool:
	var offset := at-position
	if absf(offset.y)>3.5: return false
	offset.y = 0
	return offset.length()<=SCREAM_RANGE and offset.length()>.01 and scream_direction.dot(offset.normalized())>=cos(deg_to_rad(SCREAM_HALF_ANGLE))

func release_scream() -> void:
	scream_serial += 1
	for target in all_targets():
		if in_scream(target.p) and game.line_clear(position+Vector3.UP*1.8,target.eye):
			strike_target(target.id,58.0,"hollow_weeper")

func all_targets() -> Array:
	# tick_enemy may temporarily target a visitor; recover the true local player.
	var targets := []
	if game.coop.active:
		for peer in game.coop.poses:
			var pose: Dictionary = game.coop.poses[peer]
			if pose.health<=0: continue
			var p := Vector3(pose.p[0],pose.p[1],pose.p[2])
			if peer==game.coop.transport.local_id: p = game.player.position
			var profile: Dictionary = game.coop.roster[peer].profile
			targets.append({"id":peer,"p":p,"eye":p+Vector3.UP*preload("res://scripts/character_data.gd").stature(profile.species_id).eye})
	else: targets.append({"id":0,"p":game.player.position,"eye":game.camera.global_position})
	return targets

func strike_target(peer: int, amount: float, family: String) -> void:
	if game.coop.active and peer!=game.coop.transport.local_id:
		game.coop.send(peer,"damage",{"amount":amount,"from":[position.x,position.y,position.z],"family":family})
	else:
		var old: int = game.coop.target_peer
		game.coop.target_peer = 0
		game.receive_hit(amount,position,family)
		game.coop.target_peer = old

func hit(amount: float, heavy := false, physical := true) -> void:
	if game.coop.active and not game.coop.is_host and not game.coop.applying:
		game.coop.request_hit(self,amount,heavy,physical)
		return
	if dead: return
	var source: int = game.coop.damage_source_peer
	var profession: String = game.state.profile.profession_id
	var enchanted: bool = game.state.weapon_resin_seconds>0
	if game.coop.active and source!=0:
		profession = game.coop.roster[source].profile.profession_id
		enchanted = game.coop.poses[source].get("enchanted",false)
	var multiplier := .25 if physical else 1.0
	var label := "IRON SKIDS / 75% resisted. Try spells, sacred attacks or Graveward resin."
	if physical and profession=="cleric": multiplier = 1.15; label = "SACRED HIT / The Old Faith flesh yields."
	elif physical and enchanted: multiplier = .90; label = "ENCHANTED HIT / Graveward resin bites through her defenses."
	elif not physical: label = "MAGIC BITES / Corporeal Old Faith guardian, not an Abyssal demon."
	if phase=="recover": multiplier *= 1.25; label += " EXHAUSTED / counterattack bonus."
	var strong: bool = heavy and amount>=40
	if strong: try_interrupt(1.0)
	super.hit(amount*multiplier,heavy,physical)
	stun = 0.0
	if feedback_clock<=0:
		feedback_clock = .8
		if game.coop.active and source!=0: game.coop.send(source,"weeper_feedback",{"text":label})
		else: game.message(label,3)
	if dead: play_cue("death")

func try_interrupt(power: float) -> bool:
	if power<1 or interrupt_guard>0 or phase not in ["windup","sweep_windup"] or clock>=LOCK_AT: return false
	phase = "recover"
	clock = 0
	interrupt_guard = 3.0
	game.message("SCREAM BROKEN / Two seconds to counterattack.",2)
	return true

func force_reaction(_direction: Vector3, _strength: float, _duration: float, stagger: float) -> void:
	if game.coop.active and not game.coop.is_host:
		if stagger>=1: game.coop.send(game.coop.transport.host_id,"weeper_interrupt",{"id":id,"pose":game.coop.local_pose()})
		return
	try_interrupt(stagger)
	# Ordinary strikes never create chained stun. She is corporeal and weighty.

func search_body() -> void:
	if not dead or game.state.looted.has(id): return
	game.state.looted[id] = true
	game.state.inventory.burial_cloth += 1
	game.state.inventory.ancient_beads += 2
	var tear: bool = absi(id.hash())%5==0 or id.begins_with("weeper_intro_")
	if tear: game.state.inventory.resin_tear += 1
	game.message("Burial cloth +1 / ancient beads +2"+(" / rare resin tear +1. At a fire, combine with essence to make Graveward resin." if tear else ""),6)
	game.state.log_event("body_searched:"+id)
	game.audio.play_effect("pickup")
	cleanup_clock = 0.0
