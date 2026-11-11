extends RefCounted

# Only the two starting spells per caster. Basics and defence are never slots.
const VFX = preload("res://scripts/spell_visuals.gd")
const SPELLS := {"mage":["ember","rime"],"cleric":["judgement","sanctuary"]}
const COSTS := {"ember":16.0,"rime":12.0,"judgement":14.0,"sanctuary":24.0,"cinder_ring":22.0,"litany":26.0}
const COOLDOWNS := {"ember":2.0,"rime":2.6,"judgement":2.4,"sanctuary":14.0,"cinder_ring":9.0,"litany":16.0}
const COLOURS := {"rebuke":Color("f2dfab"),"repulsion":Color("8bb5e5"),"dart":Color("76d7e8"),"ember":Color("ed813b"),"rime":Color("a6ddf2"),"judgement":Color("f4e5b5"),"sanctuary":Color("ddca8b"),"cinder_ring":Color("ed813b"),"litany":Color("f4e5b5")}
var game: Node
var projectiles: Array = []
var sanctuary: Dictionary = {}
var fx: Array = []
var gesture := ""
var gesture_clock := 0.0
var visual_clock := 0.0
var visual_duration := 0.7

func profession() -> String:
	return game.state.profile.profession_id

func reset() -> void:
	for shot in projectiles:
		if is_instance_valid(shot.node): shot.node.queue_free()
	projectiles.clear()
	for item in fx:
		if is_instance_valid(item.node): item.node.queue_free()
	fx.clear()
	if sanctuary.has("node") and is_instance_valid(sanctuary.node): sanctuary.node.queue_free()
	sanctuary.clear()
	gesture_clock = 0.0
	visual_clock = 0.0

func animate(id: String, duration := 0.4) -> void:
	gesture = id
	gesture_clock = duration
	visual_duration = 0.95 if id=="rebuke" else 0.30 if id=="dart" else 0.72
	visual_clock = visual_duration if id!="staff" else 0.0
	game.swing_duration = duration
	game.swing = duration

func basic() -> void:
	if profession()=="mage":
		launch("dart")
		game.attack_clock = 0.55
		animate("dart",0.25)
		game.audio.play_effect("dart")
	else:
		game.attack_clock = 0.78
		animate("staff",0.46)
		game.audio.play_effect("swing")
		var target: Node = null
		var closest := 3.6
		for enemy in game.enemies:
			if enemy.dead: continue
			var aim: Vector3 = enemy.position+Vector3.UP*minf(1.4,enemy.spec.height*0.5)
			var offset: Vector3 = aim-game.camera.global_position
			if offset.length()<closest and forward().dot(offset.normalized())>0.65 and game.line_clear(game.camera.global_position,aim):
				target = enemy
				closest = offset.length()
		if target:
			target.hit(24.0+(4.0 if game.state.rank()>=2 else 0.0)+(4.0 if game.state.flags.sword_upgrade else 0.0),true)
			target.force_reaction(forward(),0.8,0.65,0.5)
	game.state.log_event("basic:"+profession())

func forward() -> Vector3:
	return -game.camera.global_basis.z

func defend() -> void:
	if game.offhand_busy():
		if game.torch_equipped: game.torch_attack()
		else: game.message("Stow the lantern [L] to free your left hand.",2)
		return
	if not game.started or game.modal!="" or game.reporting or profession()=="warrior": return
	var cost := (6.0 if game.state.rank()>=5 else 10.0) if profession()=="cleric" else 12.0
	if game.state.ability_cooldowns.defensive>0:
		game.audio.throttled("cooldown_not_ready","ability_not_ready",.8)
		game.message("%s recovering: %ds" % ["Rebuke" if profession()=="cleric" else "Repulsion",ceili(game.state.ability_cooldowns.defensive)],1)
		return
	if game.state.mana<cost:
		game.message("Not enough mana for defence. Move to safety while it recovers.",2)
		return
	game.state.mana -= cost
	game.state.ability_cooldowns.defensive = (3.0 if game.state.rank()>=5 else 5.0) if profession()=="cleric" else 8.0
	animate("rebuke" if profession()=="cleric" else "repulsion",0.4)
	var count := 0
	var candidates: Array = game.enemies.duplicate()
	candidates.sort_custom(func(a,b): return a.position.distance_squared_to(game.player.position)<b.position.distance_squared_to(game.player.position))
	for enemy in candidates:
		if not in_cone(enemy,5.0,0.45 if profession()=="cleric" else 0.9): continue
		var abyss: bool = enemy.kind in ["wraith","guardian","mournkeeper"]
		enemy.hit(5.0 if profession()=="cleric" else 3.0,false,false)
		enemy.force_reaction((enemy.position-game.player.position).normalized(),6.5 if profession()=="cleric" else 9.0,1.3 if abyss and profession()=="cleric" else 0.8,1.0)
		count += 1
		burst(enemy.position+Vector3.UP,Color("f2dfab") if profession()=="cleric" else Color("8bb5e5"),0.45)
		if profession()=="mage": break
	defence_wave(profession()=="cleric")
	game.audio.play_effect("rebuke" if profession()=="cleric" else "repulsion")
	game.message(("REBUKE" if profession()=="cleric" else "REPULSION")+" / %d interrupted" % count,1.8)
	game.state.log_event("defence:"+profession())

func cast(secondary: bool) -> void:
	if game.offhand_busy():
		game.message("Stow your held light [L/T] before casting with your left hand.",2)
		return
	if game.attack_clock>0: return
	var key := "secondary" if secondary else "primary"
	var spell: String = game.state.prepared[1 if secondary else 0]
	if game.state.ability_cooldowns[key]>0:
		game.audio.throttled("cooldown_not_ready","ability_not_ready",.8)
		game.message(spell.capitalize()+" recovering: %ds" % ceili(game.state.ability_cooldowns[key]),1.5)
		return
	if game.state.mana<COSTS[spell]:
		game.message("Not enough mana. Your basic attack is free.",2)
		return
	game.state.mana -= COSTS[spell]
	game.state.ability_cooldowns[key] = COOLDOWNS[spell]
	game.attack_clock = 0.28
	animate(spell,0.36)
	if spell in ["ember","rime"]:
		launch(spell)
	elif spell in ["cinder_ring","litany"]:
		if spell=="litany": game.state.health = minf(game.state.max_health,game.state.health+22.0)
		for enemy in game.enemies:
			if enemy.dead or enemy.position.distance_to(game.player.position)>5.0 or not game.line_clear(game.camera.global_position,enemy.position+Vector3.UP): continue
			enemy.hit(28.0 if spell=="cinder_ring" else 8.0,false,false)
			if spell=="cinder_ring": enemy.burning = 3.0
			else: enemy.force_reaction((enemy.position-game.player.position).normalized(),2.0,1.0,1.0)
		ring(game.player.position+Vector3.UP*.1,5.0,COLOURS.ember if spell=="cinder_ring" else COLOURS.judgement,.8)
	elif spell=="judgement":
		for enemy in game.enemies:
			if not in_cone(enemy,9.0,0.8): continue
			enemy.hit(34.0*(1.15 if enemy.kind in ["wraith","guardian","mournkeeper"] else 1.0),false,false)
			enemy.force_reaction(forward(),2.0,1.05,1.0)
			burst(enemy.position+Vector3.UP,COLOURS.judgement,0.5)
			game.audio.play_effect("judgement_hit",enemy.position+Vector3.UP)
		game.ability_trail(game.camera.global_position,game.camera.global_position+forward()*9,COLOURS.judgement)
	else:
		# Replacement, never additive: no stacked mitigation or regeneration.
		if sanctuary.has("node") and is_instance_valid(sanctuary.node): sanctuary.node.queue_free()
		var at: Vector3 = game.player.position
		var node := make_ring(at+Vector3.UP*0.06,3.0,COLOURS.sanctuary)
		sanctuary = {"position":at,"left":8.0,"node":node}
	game.audio.play_effect("ember" if spell=="cinder_ring" else "sanctuary" if spell=="litany" else spell)
	game.message(spell.to_upper()+" / %d mana" % COSTS[spell],2)
	game.state.log_event("spell:"+spell)

func in_cone(enemy: Node, reach: float, dot_limit: float) -> bool:
	if enemy.dead: return false
	var aim: Vector3 = enemy.position+Vector3.UP*minf(1.4,enemy.spec.height*0.5)
	var offset: Vector3 = aim-game.camera.global_position
	return offset.length()<reach and forward().dot(offset.normalized())>dot_limit and game.line_clear(game.camera.global_position,aim)

func protected_at(at: Vector3) -> bool:
	return own_protected_at(at) or (game.coop!=null and game.coop.ally_protected_at(at))

func own_protected_at(at: Vector3) -> bool:
	return not sanctuary.is_empty() and sanctuary.left>0 and Vector2(at.x,at.z).distance_to(Vector2(sanctuary.position.x,sanctuary.position.z))<=3.0 and absf(at.y-sanctuary.position.y)<2.0 and game.line_clear(sanctuary.position+Vector3.UP,at+Vector3.UP)

func launch(kind: String, at := Vector3.INF, velocity := Vector3.INF, left := 1.6) -> void:
	# An actual ballistic ray segment per step, never a target lookup or homing.
	if at==Vector3.INF: at = game.camera.global_position
	if velocity==Vector3.INF:
		velocity = forward()*(38.0 if kind=="dart" else 28.0)
		left = minf(left,1.15 if kind=="dart" else 1.6)
	var node := Node3D.new()
	VFX.projectile(node,kind,COLOURS[kind])
	game.world.add_child(node)
	node.global_position = at
	node.look_at(at+velocity,Vector3.UP)
	node.visible = false
	projectiles.append({"node":node,"position":at,"velocity":velocity,"left":left,"kind":kind,"travelled":0.0})

func tick(dt: float) -> void:
	gesture_clock = maxf(0.0,gesture_clock-dt)
	visual_clock = maxf(0.0,visual_clock-dt)
	for index in range(projectiles.size()-1,-1,-1):
		var shot: Dictionary = projectiles[index]
		var next: Vector3 = shot.position+shot.velocity*dt
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(shot.position,next,3))
		shot.left -= dt
		if not hit.is_empty():
			impact(shot.kind,hit.collider,hit.position)
		if not hit.is_empty() or shot.left<=0:
			shot.node.queue_free()
			projectiles.remove_at(index)
		else:
			shot.travelled += shot.position.distance_to(next)
			shot.node.visible = shot.travelled>0.35
			shot.node.scale.z = clampf((shot.travelled-.28)/2.0,.02,1.0)
			shot.node.global_position = next
			shot.position = next
	if not sanctuary.is_empty():
		sanctuary.left -= dt
		if sanctuary.left<=0:
			sanctuary.node.queue_free()
			sanctuary.clear()
		elif own_protected_at(game.player.position):
			game.state.health = minf(game.state.max_health,game.state.health+(4.0 if game.state.rank()>=4 else 2.0)*dt)
	for index in range(fx.size()-1,-1,-1):
		var effect: Dictionary = fx[index]
		effect.left -= dt
		if effect.left<=0:
			effect.node.queue_free()
			fx.remove_at(index)
		else:
			var progress: float = 1.0-effect.left/effect.duration
			if effect.get("mode","")=="wave":
				effect.node.global_position = effect.origin+effect.direction*lerpf(0.65,effect.travel,progress)
				effect.node.scale = Vector3.ONE*lerpf(.42,2.8 if effect.sacred else 1.5,progress)
			else:
				effect.node.scale = Vector3.ONE*(1.0+progress*1.25)
			for fade in effect.get("materials",[]):
				var tint: Color = fade.material.albedo_color
				tint.a = fade.alpha*pow(1.0-progress,.6)
				fade.material.albedo_color = tint

func impact(kind: String, body: Object, at: Vector3) -> void:
	var enemy: Node = body as Node
	var direct: bool = enemy!=null and enemy.has_method("force_reaction") and not enemy.dead
	if direct:
		var warded: bool = enemy.shielded
		var damage := 12.0+(3.0 if game.state.flags.sword_upgrade else 0.0) if kind=="dart" else 24.0 if kind=="ember" else 14.0
		if kind=="dart" and enemy.brittle>0 and not warded:
			damage += 30.0 if game.state.rank()>=5 else 18.0
			enemy.brittle = 0.0
			game.audio.play_effect("brittle")
			game.message("BRITTLE SHATTER / +18",1.2)
			ring(at,0.5,COLOURS.rime,0.35)
		enemy.hit(damage,false,false)
		if not warded and not enemy.dead:
			if kind=="ember": enemy.burning = 5.0 if game.state.rank()>=2 else 3.0
			if kind=="rime":
				enemy.rimed = 6.0 if game.state.rank()>=4 else 4.0
				enemy.brittle = 6.0
				game.message("RIME / slowed + Brittle: follow with LMB",2)
	if kind=="ember":
		for other in game.enemies:
			if other==enemy or other.dead: continue
			if (other.position+Vector3.UP).distance_to(at)<1.3 and game.line_clear(at,other.position+Vector3.UP): other.hit(8.0,false,false)
	burst(at,COLOURS[kind],0.3)
	game.audio.play_effect(kind+"_hit",at)

func material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = colour
	mat.no_depth_test = false
	return mat

func make_ring(at: Vector3, radius: float, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,material(colour))
	for i in range(64):
		for angle in [float(i)*TAU/64.0,float(i+1)*TAU/64.0]:
			mesh.surface_add_vertex(Vector3(cos(angle)*radius,0,sin(angle)*radius))
	# Four restrained crosses make the fixed sanctuary boundary explicit.
	for i in range(4):
		var point := Vector3(cos(i*PI/2.0)*radius,0,sin(i*PI/2.0)*radius)
		for pair in [[point,point+Vector3.UP*0.4],[point+Vector3(-.12,.26,0),point+Vector3(.12,.26,0)]]:
			mesh.surface_add_vertex(pair[0]); mesh.surface_add_vertex(pair[1])
	mesh.surface_end()
	node.mesh = mesh
	game.world.add_child(node)
	node.global_position = at
	return node

func ring(at: Vector3, radius: float, colour: Color, duration: float) -> void:
	fx.append({"node":make_ring(at,radius,colour),"left":duration,"duration":duration})

func burst(at: Vector3, colour: Color, duration: float) -> void:
	var node := Node3D.new()
	var mat := VFX.paint(colour,.90)
	VFX.impact(node,mat,colour==COLOURS.rime)
	game.world.add_child(node)
	node.global_position = at
	if at.distance_to(game.camera.global_position)>.1: node.look_at(game.camera.global_position,Vector3.UP)
	var lifetime := maxf(duration,0.60)
	fx.append({"node":node,"left":lifetime,"duration":lifetime,"material":mat,"materials":VFX.fading_materials(node)})

func defence_wave(sacred: bool) -> void:
	var node := Node3D.new()
	var mat := VFX.paint(Color("fff0bf") if sacred else Color("9cddff"),.90)
	VFX.wave(node,mat,sacred)
	game.world.add_child(node)
	var origin: Vector3 = game.camera.global_position
	var direction := forward()
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,origin+direction*5.0,1))
	var travel := 4.8
	if not hit.is_empty(): travel = clampf(origin.distance_to(hit.position)-.15,.65,4.8)
	node.global_position = origin+direction*.65
	node.look_at(node.global_position+direction,Vector3.UP)
	node.scale = Vector3.ONE*.42
	var duration := .75 if sacred else .6
	fx.append({"node":node,"left":duration,"duration":duration,"material":mat,"materials":VFX.fading_materials(node),"mode":"wave","origin":origin,"direction":direction,"travel":travel,"sacred":sacred})

func summary() -> Dictionary:
	return {"profession":profession(),"projectiles":projectiles.size(),"gesture":gesture,"gesture_seconds":gesture_clock,"visual_seconds":visual_clock,"visual_effects":fx.size(),"sanctuary_seconds":sanctuary.get("left",0.0),"sanctuary_position":var_to_str(sanctuary.get("position",Vector3.ZERO)),"protected":protected_at(game.player.position),"runtime":record(),"prepared":game.state.prepared.duplicate()}

func record() -> Dictionary:
	var shots: Array = []
	for shot in projectiles:
		shots.append({"kind":shot.kind,"position":[shot.position.x,shot.position.y,shot.position.z],"velocity":[shot.velocity.x,shot.velocity.y,shot.velocity.z],"left":shot.left})
	var area: Dictionary = {}
	if not sanctuary.is_empty(): area = {"position":[sanctuary.position.x,sanctuary.position.y,sanctuary.position.z],"left":sanctuary.left}
	return {"projectiles":shots,"sanctuary":area}

static func valid_point(point: Variant) -> bool:
	if not point is Array or point.size()!=3: return false
	for value in point:
		if not (value is float or value is int) or not is_finite(float(value)) or absf(value)>10000: return false
	return true

static func valid_record(data: Variant) -> bool:
	if not data is Dictionary: return false
	if data.is_empty(): return true
	if not data.get("projectiles") is Array or data.projectiles.size()>32 or not data.get("sanctuary") is Dictionary: return false
	for shot in data.projectiles:
		if not shot is Dictionary or shot.get("kind") not in ["dart","ember","rime"] or not valid_point(shot.get("position")) or not valid_point(shot.get("velocity")): return false
		var left: Variant = shot.get("left")
		if not (left is float or left is int) or not is_finite(float(left)) or left<=0 or left>1.6: return false
		var speed := Vector3(shot.velocity[0],shot.velocity[1],shot.velocity[2]).length()
		if speed<1 or speed>40: return false
	if not data.sanctuary.is_empty():
		var area: Dictionary = data.sanctuary
		if not valid_point(area.get("position")): return false
		var left: Variant = area.get("left")
		if not (left is float or left is int) or not is_finite(float(left)) or left<=0 or left>8: return false
	return true

func restore(data: Dictionary) -> void:
	reset()
	if data.is_empty(): return
	for shot in data.projectiles:
		launch(shot.kind,Vector3(shot.position[0],shot.position[1],shot.position[2]),Vector3(shot.velocity[0],shot.velocity[1],shot.velocity[2]),shot.left)
	if not data.sanctuary.is_empty():
		var area: Dictionary = data.sanctuary
		var at := Vector3(area.position[0],area.position[1],area.position[2])
		sanctuary = {"position":at,"left":area.left,"node":make_ring(at+Vector3.UP*0.06,3.0,COLOURS.sanctuary)}
