extends RefCounted

const Progression = preload("res://scripts/progression.gd")

func rank() -> int:
	return Progression.rank(xp)

var health := 100.0
var max_health := 100.0
var stamina := 100.0
var xp := 0
var elapsed := 0.0
var day_clock := 14.5
var damage := 30.0
var inventory := {"graveward_resin":0,"burial_cloth":0,"ancient_beads":0,"resin_tear":0,"pistol_cartridge":0,"musket_cartridge":0,"tonic":3,"bread":3,"wood":3,"gold":12,"scrap":0,"yarrow":0,"moonwort":0,"berries":0,"mushrooms":0,"toadstools":0,"fur":0,"essence":0}
var flags := {"accepted":false,"supplies":false,"scout":false,"bargain":false,"oil":false,"relic":false,"herbalist":false,"herbs_done":false,"courier":false,"courier_done":false,"prepared":false,"beacon_lit":false,"won":false,"sword_upgrade":false,"coat_upgrade":false,"grave":false,"letter":false,"keeper":false,"root":false,"flame":false,"bell":false}
var taken: Dictionary = {}
var defeated: Dictionary = {}
var road_returns: Dictionary = {}
var journey := {"interest":0.0,"story":0.0,"observations":0}
var looted: Dictionary = {}
var discovered: Dictionary = {}
var enemies: Dictionary = {}
var fires: Array = []
var events: Array = []
var deaths := 0
var wave := 0
var wave_timer := 0.0
var pack = preload("res://scripts/backpack.gd").new()
var wetness := 0.0
var cold := 0.0
var weather := {"phase":0,"age":0.0,"clock":0.0,"rain":0.0,"wind":0.18,"clouds":0.05,"flash":0.0,"thunder":-1.0,"strike_in":12.0}
var story: Dictionary = preload("res://scripts/march.gd").DEFAULTS.duplicate(true)
var profile: Dictionary = preload("res://scripts/character_data.gd").defaults()
var mana := 0.0
var max_mana := 0.0
var ability_cooldowns := {"primary":0.0,"secondary":0.0,"defensive":0.0}
var prepared: Array = []
var ranger: Dictionary = preload("res://scripts/ranger_combat.gd").defaults()
var relationships: Dictionary = preload("res://scripts/romance_options.gd").defaults()
var keepsakes: Dictionary = {}
var weapon_resin_seconds := 0.0
var weeper_world: Dictionary = preload("res://scripts/weeper_sites.gd").DEFAULTS.duplicate(true)

func create_character(selected: Dictionary) -> void:
	profile = selected.duplicate(true)
	inventory.pistol_cartridge = 10 if profile.profession_id=="ranger" else 0
	inventory.musket_cartridge = 5 if profile.profession_id=="ranger" else 0
	var profession := preload("res://scripts/character_data.gd").profession(profile.profession_id)
	max_health = profession.health
	health = max_health
	damage = profession.damage
	max_mana = profession.mana
	mana = max_mana
	prepared = preload("res://scripts/profession_combat.gd").SPELLS.get(profile.profession_id,[]).duplicate()

func log_event(message: String) -> void:
	events.append({"time":snappedf(elapsed,0.01),"event":message})
	if events.size()>120:
		events.pop_front()

func to_dict() -> Dictionary:
	pack.sync(inventory)
	return {"journey":journey.duplicate(true),"road_returns":road_returns.duplicate(true),"weapon_resin_seconds":weapon_resin_seconds,"weeper_world":weeper_world.duplicate(true),"ranger":ranger.duplicate(true),"story":story.duplicate(true),"profile":profile.duplicate(true),"mana":mana,"max_mana":max_mana,"ability_cooldowns":ability_cooldowns.duplicate(),"prepared":prepared.duplicate(),"relationships":relationships.duplicate(),"keepsakes":keepsakes.duplicate(true),"health":health,"max_health":max_health,"stamina":stamina,"xp":xp,"elapsed":elapsed,"day_clock":day_clock,"damage":damage,"inventory":inventory.duplicate(true),"flags":flags.duplicate(true),"taken":taken.duplicate(true),"defeated":defeated.duplicate(true),"looted":looted.duplicate(true),"discovered":discovered.duplicate(true),"enemies":enemies.duplicate(true),"fires":fires.duplicate(true),"events":events.duplicate(true),"deaths":deaths,"wave":wave,"wave_timer":wave_timer,"backpack":pack.record(),"wetness":wetness,"cold":cold,"weather":weather.duplicate(true)}

func read_dict(d: Dictionary, schema_version := 3) -> bool:
	var journey_record: Variant = d.get("journey",{"interest":0.0,"story":0.0,"observations":0})
	if not journey_record is Dictionary: return false
	for key in ["interest","story","observations"]:
		var value: Variant = journey_record.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or value<0: return false
		if key=="interest" and value>30 or key=="story" and value>300: return false
		if key=="observations" and (value!=floor(value) or value>100000000): return false
	var returns: Variant = d.get("road_returns",{})
	if not returns is Dictionary: return false
	for value in returns.values():
		if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value!=floor(float(value)): return false
	var ranger_record: Variant = d.get("ranger",preload("res://scripts/ranger_combat.gd").defaults())
	if not preload("res://scripts/ranger_combat.gd").valid(ranger_record): return false
	var ammo_version: int = int(ranger_record.get("ammo_version",1)) if d.has("ranger") else 1
	for key in ["pistol_cartridge","musket_cartridge"] if ammo_version>=3 else ["cartridge"]:
		if ammo_version>=2 and d.has("ranger") and (not d.get("inventory") is Dictionary or not d.inventory.has(key)): return false
		var count: Variant = d.inventory.get(key,0) if d.get("inventory") is Dictionary else 0
		if not (count is int or count is float) or not is_finite(float(count)) or count<0 or count>122 or count!=floor(count): return false
	if ammo_version<3:
		d = d.duplicate(true)
		var old_total: int = int(d.inventory.get("cartridge",0)) if d.get("inventory") is Dictionary else 0
		if ammo_version<2:
			old_total = mini(122,int(ranger_record.get("reserve",30))+int(ranger_record.pistol_loaded)+int(ranger_record.musket_loaded)+int(ranger_record.reload_left>0)) if d.get("profile") is Dictionary and d.profile.get("profession_id","")=="ranger" else 0
		if d.get("inventory") is Dictionary:
			d.inventory.pistol_cartridge = ceili(old_total*2.0/3.0)
			d.inventory.musket_cartridge = old_total-d.inventory.pistol_cartridge
		if d.get("backpack") is Dictionary:
			if d.backpack.get("layout") is Dictionary and d.backpack.layout.has("cartridge"):
				d.backpack.layout.pistol_cartridge = d.backpack.layout.cartridge
				d.backpack.layout.erase("cartridge")
			if d.backpack.get("slots") is Array:
				for i in range(d.backpack.slots.size()):
					if d.backpack.slots[i]=="cartridge": d.backpack.slots[i] = "pistol_cartridge"
	# Validate the whole payload before changing live state.
	var loaded_weeper: Variant = d.get("weeper_world",preload("res://scripts/weeper_sites.gd").DEFAULTS.duplicate(true))
	if not preload("res://scripts/weeper_sites.gd").valid(loaded_weeper): return false
	var loaded_resin: Variant = d.get("weapon_resin_seconds",0.0)
	if not (loaded_resin is float or loaded_resin is int) or not is_finite(float(loaded_resin)) or loaded_resin<0 or loaded_resin>120: return false
	for key in ["health","max_health","stamina","xp","elapsed","day_clock","damage","deaths","wave","wave_timer"]:
		if not d.has(key) or not (d[key] is float or d[key] is int) or not is_finite(float(d[key])):
			return false
	for key in ["inventory","flags","taken","defeated","discovered","enemies"]:
		if not d.get(key) is Dictionary:
			return false
	for key in inventory:
		if key in ["burial_cloth","ancient_beads","resin_tear","graveward_resin"] and not d.inventory.has(key): continue
		if key in ["pistol_cartridge","musket_cartridge"] and ammo_version<3: continue
		if schema_version==2 and key in ["berries","mushrooms","toadstools","fur","essence"] and not d.inventory.has(key):
			continue
		if not d.inventory.get(key) is float and not d.inventory.get(key) is int:
			return false
		if d.inventory[key]<0 or d.inventory[key]>100000:
			return false
	for key in flags:
		if not d.flags.get(key) is bool:
			return false
	for key in ["taken","defeated","discovered"]:
		for value in d[key].values():
			if not value is bool:
				return false
	if not d.get("fires") is Array or not d.get("events") is Array:
		return false
	for fire in d.fires:
		if not fire is Dictionary or not valid_vector(fire.get("position")) or not fire.get("fuel") is float and not fire.get("fuel") is int:
			return false
	for foe in d.enemies.values():
		if not foe is Dictionary or not valid_vector(foe.get("position")) or not (foe.get("health") is float or foe.get("health") is int):
			return false
		if not foe.get("engaged",false) is bool: return false
		if foe.has("weeper_aim") and not valid_vector(foe.weeper_aim): return false
		if foe.has("weeper_site_revision"):
			var revision: Variant = foe.weeper_site_revision
			if not (revision is int or revision is float) or not is_finite(float(revision)) or revision!=floor(float(revision)) or revision<0 or revision>1: return false
		if foe.has("weeper_scream_serial"):
			var serial: Variant = foe.weeper_scream_serial
			if not (serial is int or serial is float) or not is_finite(float(serial)) or serial!=floor(float(serial)) or serial<0 or serial>1000000: return false
		for key in ["burning","burn_clock","rimed","brittle","poise","poise_clock","weeper_interrupt_guard"]:
			var value: Variant = foe.get(key,0.0)
			if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>10: return false
	if schema_version>=3:
		if not d.get("looted") is Dictionary:
			return false
		for value in d.looted.values():
			if not value is bool:
				return false
	if schema_version>=4:
		for key in ["wetness","cold"]:
			if not (d.get(key) is float or d.get(key) is int) or not is_finite(float(d[key])) or d[key]<0 or d[key]>100:
				return false
		if not d.get("weather") is Dictionary:
			return false
		for key in weather:
			if not (d.weather.get(key) is float or d.weather.get(key) is int) or not is_finite(float(d.weather[key])):
				return false
		if d.weather.phase<0 or d.weather.phase>7 or d.weather.age<0 or d.weather.clock<0 or d.weather.rain<0 or d.weather.rain>1 or d.weather.wind<0 or d.weather.wind>2 or d.weather.clouds<0 or d.weather.clouds>1:
			return false
		if d.weather.phase!=floor(d.weather.phase) or d.weather.flash<0 or d.weather.flash>1 or d.weather.thunder< -1 or d.weather.thunder>5 or d.weather.strike_in<0 or d.weather.strike_in>30:
			return false
		var candidate_pack = preload("res://scripts/backpack.gd").new()
		if not candidate_pack.restore(d.get("backpack"),d.inventory):
			return false
		pack = candidate_pack
		wetness = d.wetness
		cold = d.cold
		weather = d.weather.duplicate(true)
	if schema_version>=5:
		if d.has("story"):
			if not preload("res://scripts/march.gd").valid(d.story): return false
			story = d.story.duplicate(true)
		var loaded_profile: Variant = preload("res://scripts/character_data.gd").migrate_profile(d.get("profile"))
		if not preload("res://scripts/character_data.gd").valid(loaded_profile):
			return false
		for key in ["mana","max_mana"]:
			if not (d.get(key) is float or d.get(key) is int) or not is_finite(float(d[key])) or d[key]<0 or d[key]>100:
				return false
		if d.mana>d.max_mana or not d.get("ability_cooldowns") is Dictionary or not d.get("relationships") is Dictionary or not d.get("keepsakes") is Dictionary:
			return false
		for key in ability_cooldowns:
			var value: Variant = d.ability_cooldowns.get(key,0.0)
			if not (value is float or value is int) or not is_finite(float(value)) or value<0 or value>60:
				return false
		for key in relationships:
			if not key.begins_with("mara_") and not d.relationships.has(key): continue
			if not d.relationships.get(key) is bool: return false
		for key in d.keepsakes:
			if key.trim_suffix("_lamplight") not in preload("res://scripts/romance_options.gd").PEOPLE or not key.ends_with("_lamplight") or d.keepsakes[key]!=true: return false
		if d.relationships.mara_evening!=d.keepsakes.get("mara_lamplight",false): return false
		for id in preload("res://scripts/romance_options.gd").PEOPLE:
			if d.relationships.get(id+"_evening",false)!=d.keepsakes.get(id+"_lamplight",false): return false
		var allowed: Array = preload("res://scripts/profession_combat.gd").SPELLS.get(loaded_profile.profession_id,[])
		var loaded_slots: Variant = d.get("prepared",allowed)
		allowed = Progression.spells(loaded_profile.profession_id,int(d.xp))
		if not loaded_slots is Array or loaded_slots.size()!=(2 if loaded_profile.profession_id in ["mage","cleric"] else 0): return false
		for spell in loaded_slots:
			if spell not in allowed or loaded_slots.count(spell)!=1: return false
		prepared = loaded_slots.duplicate()
		profile = loaded_profile.duplicate(true)
		mana = d.mana
		max_mana = d.max_mana
		ability_cooldowns.merge(d.ability_cooldowns,true)
		relationships = preload("res://scripts/romance_options.gd").defaults()
		relationships.merge(d.relationships.duplicate(),true)
		keepsakes = d.keepsakes.duplicate()
	max_health = clampf(d.max_health,90,150)
	health = clampf(d.health,1,max_health)
	stamina = clampf(d.stamina,0,100)
	xp = maxi(0,int(d.xp))
	elapsed = maxf(0,d.elapsed)
	day_clock = fposmod(d.day_clock,24)
	damage = clampf(d.damage,16,47)
	inventory.merge(d.inventory.duplicate(true),true)
	ranger = preload("res://scripts/ranger_combat.gd").defaults()
	ranger.merge(ranger_record.duplicate(true),true)
	if ammo_version<3:
		var total: int = int(d.inventory.get("cartridge",0))
		if ammo_version<2:
			total = mini(122,int(ranger_record.get("reserve",30))+int(ranger.pistol_loaded)+int(ranger.musket_loaded)+int(ranger.reload_left>0)) if profile.profession_id=="ranger" else 0
		inventory.pistol_cartridge = ceili(total*2.0/3.0)
		inventory.musket_cartridge = total-inventory.pistol_cartridge
	inventory.erase("cartridge")
	ranger.erase("reserve")
	ranger.ammo_version = 3
	pack.sync(inventory)
	weapon_resin_seconds = loaded_resin
	weeper_world = loaded_weeper.duplicate(true)
	flags = d.flags.duplicate(true)
	taken = d.taken.duplicate(true)
	defeated = d.defeated.duplicate(true)
	road_returns = returns.duplicate(true)
	journey = {"interest":float(journey_record.interest),"story":float(journey_record.story),"observations":int(journey_record.observations)}
	# Schema 2 already awarded loot on death. Mark those bodies searched so
	# continuing an existing journey cannot award the same loot a second time.
	looted = d.defeated.duplicate(true) if schema_version==2 else d.looted.duplicate(true)
	discovered = d.discovered.duplicate(true)
	enemies = d.enemies.duplicate(true)
	fires = d.fires.duplicate(true)
	events = d.events.duplicate(true)
	deaths = maxi(0,int(d.deaths))
	wave = clampi(int(d.wave),0,4)
	wave_timer = maxf(0,d.wave_timer)
	return true

static func valid_vector(v: Variant) -> bool:
	if not v is Array or v.size()!=3:
		return false
	for n in v:
		if not (n is float or n is int) or not is_finite(float(n)) or absf(float(n))>10000:
			return false
	return true
