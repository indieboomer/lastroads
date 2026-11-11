extends CharacterBody3D

const C = preload("res://scripts/content.gd")
var game: Node
var id := ""
var kind := "bandit"
var spec: Dictionary
var health := 85.0
var home := Vector3.ZERO
var phase := "idle"
var clock := 0.0
var stun := 0.0
var hit_flash := 0.0
var visual: Sprite3D
var halo: MeshInstance3D
var animation_clock := 0.0
var dead := false
var cleanup_clock := -1.0
var boss_phase := 0
var shielded := false
var burning := 0.0
var burn_clock := 0.0
var rimed := 0.0
var brittle := 0.0
var poise := 0.0
var poise_clock := 0.0
var push := Vector3.ZERO
var illustrated_wilderness := false
var engaged := false
var forest_home := Vector3.ZERO
var forest_day_home := Vector3.ZERO

func setup(owner_game: Node, uid: String, family: String, at: Vector3) -> void:
	game = owner_game
	id = uid
	kind = family
	spec = C.ENEMY_TYPES[kind]
	health = spec.hp
	home = at
	forest_home = at
	position = at+Vector3(0,0.05,0)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = spec.height if kind in ["guardian","mournkeeper","wraith","pitchbound","boughstalker","hollow_weeper"] else 1.7 if kind!="wolf" else 1.0
	capsule.radius = 0.85 if kind in ["guardian","mournkeeper"] else 0.42
	if kind=="hollow_weeper": capsule.radius *= 1.2
	if capsule.height<capsule.radius*2:
		capsule.height = capsule.radius*2
	collision.shape = capsule
	collision.position.y = capsule.height/2
	add_child(collision)
	collision_layer = 2
	collision_mask = 1 | 2
	visual = game.world.sprite("combat",spec.cell*4,4,4,Vector3.ZERO,spec.height,false,self)
	illustrated_wilderness = kind in ["pitchbound","boughstalker","hollow_weeper"]
	if illustrated_wilderness: visual.texture = game.world.wilderness_art.frame(game.world.library,kind,0)
	visual.material_override = game.world.actor_material(visual.texture)
	if illustrated_wilderness: set_art_pose(0)
	halo = game.world.glow(Vector3(0,1.5,0),3,Color(1,0.2,0.05,0),self)
	if game.state.defeated.has(id):
		dead = true
		hide()
		collision_layer = 0
	if game.state.enemies.has(id):
		var record: Dictionary = game.state.enemies[id]
		health = clampf(record.health,0,spec.hp)
		position = Vector3(record.position[0],record.position[1],record.position[2])
		phase = record.get("phase","idle")
		engaged = record.get("engaged",health<spec.hp or phase!="idle")
		clock = record.get("clock",0.0)
		stun = record.get("stun",0.0)
		boss_phase = record.get("boss_phase",0)
		burning = record.get("burning",0.0)
		burn_clock = record.get("burn_clock",0.0)
		rimed = record.get("rimed",0.0)
		brittle = record.get("brittle",0.0)
		poise = record.get("poise",0.0)
		poise_clock = record.get("poise_clock",0.0)
		if health<=0:
			dead = true
			hide()
			collision_layer = 0
	if dead and not game.state.looted.has(id):
		show_corpse()
	if not dead: forest_presence(true)

func forest_presence(initial := false) -> void:
	if kind not in ["pitchbound","boughstalker"] or not id.begins_with("wild_"): return
	var p := Vector2(forest_home.x,forest_home.z)
	var day: bool = game.state.day_clock>=7 and game.state.day_clock<18
	home = forest_home
	if day and C.distance_to_road(p)<38:
		if forest_day_home!=Vector3.ZERO:
			home = forest_day_home
		else:
			forest_day_home = deeper_forest_home(p)
			home = forest_day_home
	if not engaged and ((initial and not game.state.enemies.has(id)) or not game.coop.party_near(position,40)):
		position = home
	visible = not (day and not engaged and C.distance_to_road(Vector2(position.x,position.z))<38)
	collision_layer = 2 if visible else 0

func deeper_forest_home(p: Vector2) -> Vector3:
		var nearest := p
		var best := INF
		for road in C.ROADS:
			for index in range(road.size()-1):
				var point := Geometry2D.get_closest_point_to_segment(p,road[index],road[index+1])
				if point.distance_to(p)<best: nearest = point; best = point.distance_to(p)
		var candidate := p+(p-nearest).normalized()*40
		if preload("res://scripts/weeper_sites.gd").guard_clearing(candidate): return forest_home
		if not game.world.outside_buildings(candidate,3) or game.world.water_bounds.any(func(bounds): return bounds.grow(2).has_point(candidate)): return forest_home
		return C.ground(candidate,.25)

func record() -> Dictionary:
	return {"kind":kind,"health":health,"engaged":engaged,"position":[position.x,position.y,position.z],"phase":phase,"clock":clock,"stun":stun,"boss_phase":boss_phase,"burning":burning,"burn_clock":burn_clock,"rimed":rimed,"brittle":brittle,"poise":poise,"poise_clock":poise_clock}

func tick(dt: float) -> void:
	if dead:
		if cleanup_clock>=0:
			cleanup_clock += dt
			visual.visible = int(cleanup_clock/0.14)%2==0
			if cleanup_clock>=0.84:
				game.world.corpse_smoke(position)
				cleanup_clock = -1.0
				hide()
		return
	forest_presence()
	if burning>0:
		burn_clock += minf(dt,burning)
		burning = maxf(0.0,burning-dt)
		if burn_clock>=0.5:
			burn_clock -= 0.5
			hit(2.0,false,false)
			if dead: return
	rimed = maxf(0.0,rimed-dt)
	brittle = maxf(0.0,brittle-dt)
	poise_clock = maxf(0.0,poise_clock-dt)
	if poise_clock<=0: poise = 0.0
	animation_clock += dt
	hit_flash = maxf(0,hit_flash-dt)
	stun = maxf(0,stun-dt)
	var frame := 0
	if hit_flash>0 or stun>0:
		frame = 3
	elif phase=="windup":
		frame = 1
	elif phase=="recover" and clock<0.3:
		frame = 2
	elif phase=="recover" and illustrated_wilderness:
		frame = 5
	if illustrated_wilderness:
		set_art_pose(frame)
	else:
		visual.texture = game.world.atlas("enemies",spec.cell,4,1) if frame==0 else game.world.atlas("combat",spec.cell*4+frame,4,4)
		(visual.material_override as ShaderMaterial).set_shader_parameter("image",visual.texture)
		visual.pixel_size = spec.height/visual.texture.get_height()
	var diff: Vector3 = game.player.position-position
	diff.y = 0
	var distance := diff.length()
	var night_factor := 1.0 if game.state.day_clock<18 else 0.7
	visual.modulate = Color(night_factor,night_factor,night_factor)
	if hit_flash>0:
		visual.modulate = Color(1.8,0.65,0.4)
	elif brittle>0:
		visual.modulate = Color(0.65,1.12,1.45)
	elif burning>0:
		visual.modulate = Color(1.3,0.8,0.5)
	elif phase=="windup":
		visual.modulate = Color(1.3,0.74,0.47)
	elif stun>0:
		visual.modulate = Color(0.6,1.0,1.2)
	var hm: ShaderMaterial = halo.material_override
	shielded = kind=="guardian" and game.enemies.any(func(e): return not e.dead and e.id.begins_with(id+"_echo"))
	hm.set_shader_parameter("color",Color(0.2,0.75,1.0,0.7) if shielded else Color(1,0.24,0.04,0.5 if phase=="windup" else 0))
	var light_fearing: bool = kind in ["pitchbound","boughstalker","wraith"]
	if light_fearing and phase in ["windup","recover"]: engaged = true
	if distance>48 and not (light_fearing and engaged):
		return
	velocity.y -= 24*dt
	velocity.x = 0
	velocity.z = 0
	if light_fearing and game.forest_light_protection(kind!="wraith"):
		var retreat: Vector3 = -diff.normalized()*spec.speed*0.75
		velocity.x = retreat.x
		velocity.z = retreat.z
		phase = "idle"
		clock = 0
		move_and_slide()
		return
	var pursuing: bool = light_fearing and engaged
	var can_hunt: bool = pursuing or distance<(28.0 if id.begins_with("wild_") else 17.0) or phase!="idle"
	if not visible and not engaged: can_hunt = false
	if id.begins_with("wild_") and not pursuing and distance>spec.reach+0.65 and (game.in_crypt() or game.Wilderness.tier(Vector2(game.player.position.x,game.player.position.z),game.state.day_clock,game.world)==0):
		can_hunt = false
	if game.near_safety() and kind!="guardian" and not light_fearing:
		can_hunt = false
	if position.distance_to(home)>(48.0 if health<spec.hp else 32.0) and not id.begins_with("defence") and not pursuing:
		can_hunt = false
	if stun>0:
		phase = "stunned"
		clock = 0
	elif not can_hunt:
		phase = "idle"
		clock = 0
		if position.distance_to(home)>2:
			var back := (home-position).normalized()
			velocity.x = back.x*spec.speed*0.7
			velocity.z = back.z*spec.speed*0.7
	elif phase=="windup":
		clock += dt
		visual.rotation.z = sin(clock*9)*0.08
		if clock>=spec.windup:
			phase = "recover"
			clock = 0
			visual.rotation.z = -0.18
			if distance<spec.reach+0.65 and game.line_clear(global_position+Vector3.UP,game.camera.global_position):
				game.receive_hit(spec.damage,global_position,kind)
				if kind=="wolf":
					velocity.x = diff.normalized().x*5
					velocity.z = diff.normalized().z*5
	elif phase=="recover":
		clock += dt
		if clock>=spec.recovery:
			phase = "chase"
			clock = 0
	else:
		if light_fearing: engaged = true
		phase = "chase"
		visual.rotation.z = 0
		if distance<spec.reach:
			phase = "windup"
			game.audio.enemy_event(kind,"windup",position+Vector3.UP,id)
			clock = 0
		elif distance>0.1:
			var speed: float = spec.speed
			if kind=="boughstalker" and distance>3 and distance<9: speed *= 1.4
			if rimed>0: speed *= 0.85 if kind in ["guardian","mournkeeper"] else 0.45
			if kind=="wraith" and game.fire_distance(global_position)<8:
				speed *= 0.15
			velocity.x = diff.normalized().x*speed
			velocity.z = diff.normalized().z*speed
	visual.position.y = visual.texture.get_height()*visual.pixel_size/2 + sin(animation_clock*(3.0 if kind=="wraith" else 7.0))*0.035
	velocity.x += push.x
	velocity.z += push.z
	push = push.move_toward(Vector3.ZERO,dt*20.0)
	move_and_slide()
	position.x = clampf(position.x,-235,235)
	position.z = clampf(position.z,-1010,85)
	if position.y<C.height_at(position.x,position.z)-2:
		position.y = C.height_at(position.x,position.z)+0.05

func set_art_pose(frame: int) -> void:
	visual.texture = game.world.wilderness_art.frame(game.world.library,kind,frame)
	(visual.material_override as ShaderMaterial).set_shader_parameter("image",visual.texture)
	# One pixel scale per enemy; raised weapons and lowered bodies never resize it.
	visual.pixel_size = spec.height/game.world.wilderness_art.frame(game.world.library,kind,0).get_height()
	visual.position.y = visual.texture.get_height()*visual.pixel_size/2

func hit(amount: float, heavy := false, physical := true) -> void:
	if game.coop.active and not game.coop.is_host and not game.coop.applying:
		game.coop.request_hit(self,amount,heavy,physical)
		return
	if dead:
		return
	if shielded:
		game.audio.play_effect("block")
		game.message("THE ECHO WARD · Defeat the spirits feeding the Warden's blue shield.",3)
		return
	health -= amount
	if game.weeper_director: game.weeper_director.observe_kind(kind)
	engaged = true
	if kind=="boughstalker" and phase=="windup" and clock<spec.windup*.65:
		stun = maxf(stun,.9)
	if phase=="idle":
		phase = "chase"
		clock = 0.0
	hit_flash = 0.22
	stun = 0.8 if heavy and kind not in ["guardian","mournkeeper","hollow_weeper"] else stun
	game.state.log_event("hit:%s:%d" % [id,amount])
	if physical: game.audio.play_effect("hit",position+Vector3.UP)
	if health>0: game.audio.enemy_event(kind,"hurt",position+Vector3.UP,id)
	game.world.impact(global_position+Vector3(0,minf(1.3,spec.height*0.6),0),kind in ["wraith","guardian","mournkeeper"],heavy)
	if kind=="guardian" and health>0 and boss_phase<2 and health<spec.hp*(0.68 if boss_phase==0 else 0.34):
		boss_phase += 1
		game.spawn_enemy(id+"_echo_%da" % boss_phase,"wraith",Vector2(-7,-331))
		game.spawn_enemy(id+"_echo_%db" % boss_phase,"wraith",Vector2(7,-331))
		shielded = true
		game.audio.play_effect("bell")
		game.message("THE BELL REMEMBERS · Two echoes feed its ward. Silence them first.",7)
	if health<=0:
		dead = true
		game.audio.enemy_event(kind,"death",position+Vector3.UP,id)
		game.state.defeated[id] = true
		game.state.xp += spec.xp
		game.state.log_event("defeated:"+id)
		game.message("%s falls. +%d experience" % [spec.name,spec.xp])
		collision_layer = 0
		show_corpse()

func show_corpse() -> void:
	show()
	halo.hide()
	if illustrated_wilderness:
		visual.show()
		set_art_pose(4)
		visual.rotation = Vector3.ZERO
		visual.modulate = Color.WHITE
		position.y = game.world.surface_height(position)
		return
	visual.texture = game.world.library.cell("res://assets/revision/corpses.png",spec.cell,2,2)
	(visual.material_override as ShaderMaterial).set_shader_parameter("image",visual.texture)
	visual.pixel_size = (3.6 if kind in ["guardian","mournkeeper"] else 2.3 if kind=="bandit" else 1.8)/visual.texture.get_width()
	visual.position = Vector3(0,visual.texture.get_height()*visual.pixel_size/2-0.02,0)
	visual.rotation = Vector3.ZERO
	visual.modulate = Color.WHITE
	position.y = game.world.surface_height(position)

func search_body() -> void:
	if not dead or game.state.looted.has(id):
		return
	game.state.looted[id] = true
	var pack: Dictionary = game.state.inventory
	var description := ""
	match kind:
		"pitchbound":
			pack.gold += 5
			pack.scrap += 2
			description = "5 coins and two pieces of scrap"
		"boughstalker":
			pack.essence += 2
			description = "two motes of pale essence"
		"bandit":
			pack.gold += 3
			pack.scrap += 1
			description = "3 coins and a piece of scrap"
		"wolf":
			pack.fur += 1
			description = "a hound pelt"
		"wraith":
			pack.essence += 1
			description = "a mote of pale essence"
		"guardian", "mournkeeper":
			pack.gold += 35
			pack.essence += 3
			description = "35 coins and three motes of essence"
	game.state.log_event("body_searched:"+id)
	game.message("Recovered "+description+".")
	game.audio.play_effect("pickup")
	cleanup_clock = 0.0

func force_reaction(direction: Vector3, strength: float, duration: float, stagger: float) -> void:
	if dead or shielded: return
	if kind in ["guardian","mournkeeper"]:
		poise = minf(2.0,poise+stagger)
		poise_clock = 6.0
		if poise>=2.0 and phase=="windup" and clock<spec.windup*0.65:
			stun = maxf(stun,0.4)
			poise = 0.0
			game.message("BOSS STAGGER / early windup interrupted",1.5)
		return
	stun = maxf(stun,duration)
	direction.y = 0
	push = direction.normalized()*strength
