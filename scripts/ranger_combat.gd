extends RefCounted

const WEAPONS := {"pistol":{"damage":80.0,"reload":4.0,"reach":60.0},"musket":{"damage":130.0,"reload":6.0,"reach":100.0},"dagger":{"damage":16.0,"reload":0.0,"reach":2.7}}
var game: Node
var flash := 0.0
var smoke := 0.0
var dagger_clock := 0.0
var last_stage := -1
var steady := 0.0
var shot_serial := 0

static func defaults() -> Dictionary:
	return {"weapon":"pistol","pistol_loaded":true,"musket_loaded":true,"ammo_version":3,"reload_left":0.0,"reload_total":0.0,"reload_weapon":""}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("weapon") not in WEAPONS: return false
	if value.get("ammo_version",1)!=1 and value.get("ammo_version",1)!=2 and value.get("ammo_version",1)!=3: return false
	var reserve: Variant = value.get("reserve",30)
	if not (reserve is int or reserve is float) or not is_finite(float(reserve)) or reserve<0 or reserve>120 or reserve!=floor(reserve): return false
	for key in ["pistol_loaded","musket_loaded"]:
		if not value.get(key) is bool: return false
	for key in ["reload_left","reload_total"]:
		if not (value.get(key) is float or value.get(key) is int) or not is_finite(float(value[key])) or value[key]<0 or value[key]>6: return false
	if value.reload_left>value.reload_total or not value.get("reload_weapon") is String: return false
	if value.reload_left>0:
		return (value.get("ammo_version",1)>=2 or reserve<120) and value.reload_weapon in ["pistol","musket"] and value.weapon==value.reload_weapon and not value[value.reload_weapon+"_loaded"] and value.reload_total>0
	return value.reload_weapon=="" and value.reload_total==0

func active() -> bool:
	return game.state.profile.profession_id=="ranger"

func reset() -> void:
	flash = 0
	smoke = 0
	dagger_clock = 0
	steady = 0
	last_stage = -1
	if game.camera: game.camera.fov = 76

func select(weapon: String) -> void:
	if not active() or weapon not in WEAPONS: return
	var r: Dictionary = game.state.ranger
	if r.weapon==weapon: return
	if r.reload_left>0:
		r.reload_left = 0.0
		r.reload_total = 0.0
		r.reload_weapon = ""
		game.message("Reload interrupted; the firearm remains empty.",3)
	r.weapon = weapon
	steady = 0
	if weapon=="musket":
		if game.offhand_busy(): game.message("Light stowed / the musket needs both hands.",2)
		game.stow_lights()
	game.attack_clock = maxf(game.attack_clock,.25)
	game.state.log_event("ranger_equipped:"+weapon)

func stage() -> int:
	var r: Dictionary = game.state.ranger
	if r.reload_left<=0: return -1
	return mini(2,int((1.0-r.reload_left/r.reload_total)*3.0))

func reload() -> void:
	if not active() or not game.started or game.modal!="" or game.reporting: return
	var r: Dictionary = game.state.ranger
	if r.weapon=="dagger":
		game.message("C selects pistol; V selects musket. R reloads the selected firearm.",3)
		return
	if r.reload_left>0: return
	if r[r.weapon+"_loaded"]:
		game.message(r.weapon.capitalize()+" is already loaded.",2)
		return
	if game.state.inventory[r.weapon+"_cartridge"]<=0:
		game.message("No cartridges. Look for Paper cartridges when talking to innkeepers, traders, scouts, soldiers or Lucan. Q draws your dagger.",4)
		return
	game.stow_lights()
	r.reload_total = WEAPONS[r.weapon].reload*(.8 if game.state.rank()>=3 else 1.0)
	r.reload_left = r.reload_total
	r.reload_weapon = r.weapon
	last_stage = -1
	steady = 0
	game.message("Both hands occupied / reloading "+r.weapon+". Switching weapon cancels.",3)
	game.state.log_event("reload_started:"+r.weapon)

func tick(dt: float) -> void:
	if not active() or game.modal!="" or game.reporting: return
	flash = maxf(0,flash-dt)
	smoke = maxf(0,smoke-dt)
	dagger_clock = maxf(0,dagger_clock-dt)
	var r: Dictionary = game.state.ranger
	var aim: bool = r.reload_left<=0 and r.weapon!="dagger" and not game.offhand_busy() and game.controls.held("defend")
	steady = minf(2.0,steady+dt) if aim else 0.0
	game.camera.fov = move_toward(game.camera.fov,56.0 if aim else 76.0,dt*85)
	if r.reload_left<=0: return
	var current := stage()
	if current!=last_stage:
		if last_stage==-1: game.audio.play_effect("ranger_reload")
		last_stage = current
	r.reload_left = maxf(0,r.reload_left-dt)
	if r.reload_left<=0:
		r[r.reload_weapon+"_loaded"] = true
		r.reload_total = 0.0
		r.reload_weapon = ""
		game.audio.play_effect("ranger_cock")
		game.state.log_event("reload_complete:"+r.weapon)
		game.message(r.weapon.capitalize()+" loaded.",1.5)

func attack() -> void:
	if not active() or not game.started or game.modal!="" or game.reporting or game.attack_clock>0: return
	var r: Dictionary = game.state.ranger
	if r.reload_left>0:
		game.message("Both hands are reloading. Switch weapon to interrupt.",1.5)
		return
	if r.weapon=="dagger":
		game.attack_clock = .6
		dagger_clock = .4
		game.audio.play_effect("sword_hit")
		for foe in game.enemies:
			if game.combat.in_cone(foe,2.7,.82):
				foe.hit(20.0 if game.state.rank()>=4 else 16.0,false,true)
				break
		return
	if r.weapon=="musket" and game.offhand_busy():
		game.message("Stow the light first; the musket needs both hands.",2)
		return
	if game.state.inventory[r.weapon+"_cartridge"]<=0:
		game.message("No cartridges. Buy paper cartridges or draw your dagger [Q].",3)
		return
	if not r[r.weapon+"_loaded"]:
		game.message(r.weapon.capitalize()+" is empty / press R to reload.",2)
		game.audio.throttled("ranger_cock","empty_firearm",.7)
		return
	game.state.inventory[r.weapon+"_cartridge"] -= 1
	shot_serial += 1
	r[r.weapon+"_loaded"] = false
	game.attack_clock = .65
	flash = .16
	smoke = 4.0 if r.weapon=="musket" else 2.0
	game.audio.play_effect("ranger_shot")
	var origin: Vector3 = game.camera.global_position
	var end: Vector3 = origin-game.camera.global_basis.z*WEAPONS[r.weapon].reach
	var query := PhysicsRayQueryParameters3D.create(origin,end,3)
	query.exclude = [game.player.get_rid()]
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		end = hit.position
		var target: Node = hit.collider
		if target in game.enemies and not target.dead:
			var damage: float = WEAPONS[r.weapon].damage*(1.1 if game.state.rank()>=2 else 1.0)
			if game.state.flags.sword_upgrade: damage *= 1.05
			if game.state.rank()>=5 and steady>=1.0: damage *= 1.15
			target.hit(damage,true,true)
			target.force_reaction(-game.camera.global_basis.z,1.5,.4,.7)
	game.ability_trail(origin-game.camera.global_basis.z*.7,end,Color("ddcdb1"))
	game.state.log_event("ranger_shot:"+r.weapon)
