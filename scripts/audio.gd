extends Node

var library = preload("res://scripts/sound_library.gd").new()
var spatial_voices: Array[AudioStreamPlayer3D] = []
var ui_voices: Array[AudioStreamPlayer] = []
var beds: Dictionary = {}
var recent_events: Array = []
var cooldowns: Dictionary = {}
var ambient_family := "procedural"
var breath_clock := 0.0
var bed_clock := 0.0
var voices: Array[AudioStreamPlayer] = []
var cache: Dictionary = {}
var base_ambience: AudioStream
var ambient: AudioStreamPlayer
var game: Node
var channels: Array[AudioStreamPlayer] = []
var tracks: Dictionary = {}
var context := ""
var active := 0
var fade := 1.0
var outgoing_gain := 0.0
var combat_hold := 0.0
var step_clock := 0.0
var muted := false
const MUSIC_BUS := "RoadMusic"
const SOUND_BUS := "RoadSounds"
const TRACKS := {"menu":"main_menu_music.mp3", "day":"day_music.mp3", "forest":"deep_forest_music.mp3", "night":"night_ambient.mp3", "battle":"battle_music.mp3", "intimacy":"love_music.mp3"}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name in [MUSIC_BUS,SOUND_BUS]:
		if AudioServer.get_bus_index(bus_name)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
	apply_volumes()
	library.scan()
	for i in range(12):
		var voice := AudioStreamPlayer3D.new()
		voice.bus = SOUND_BUS
		voice.process_mode = Node.PROCESS_MODE_PAUSABLE
		voice.max_distance = 40.0
		voice.unit_size = 5.0
		add_child(voice)
		spatial_voices.append(voice)
	for i in range(4):
		var voice := AudioStreamPlayer.new()
		voice.bus = SOUND_BUS
		voice.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(voice)
		ui_voices.append(voice)
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.bus = SOUND_BUS
		voice.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(voice)
		voices.append(voice)
	ambient = AudioStreamPlayer.new()
	ambient.bus = SOUND_BUS
	ambient.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(ambient)
	ambient.volume_db = -26
	ambient.stream = ambience()
	base_ambience = ambient.stream
	ambient.play()
	for key in TRACKS:
		var stream := load("res://music/"+TRACKS[key]) as AudioStreamMP3
		assert(stream!=null,"Missing soundtrack: "+TRACKS[key])
		stream = stream.duplicate()
		stream.loop = true
		tracks[key] = stream
	for i in range(2):
		var channel := AudioStreamPlayer.new()
		channel.bus = MUSIC_BUS
		add_child(channel)
		channel.volume_db = -80
		channels.append(channel)
	select_track("menu")

func set_muted(value: bool) -> void:
	muted = value
	apply_volumes()
	for voice in voices+spatial_voices+ui_voices:
		voice.stream_paused = value or game.reporting
	ambient.stream_paused = value
	for channel in channels:
		channel.stream_paused = value or game.reporting

func pause_for_report(value: bool) -> void:
	for voice in ui_voices+channels:
		voice.stream_paused = muted or value

func apply_volumes() -> void:
	for entry in [[MUSIC_BUS,"music_volume"],[SOUND_BUS,"sound_volume"]]:
		var index := AudioServer.get_bus_index(entry[0])
		if index<0: continue
		var value: float = game.visuals.audio_values[entry[1]]
		AudioServer.set_bus_mute(index,muted or value<=0.0)
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(value,0.0001)))

func desired_context(dt: float) -> String:
	if not game.started:
		combat_hold = 0.0
		return "menu"
	if game.modal=="intimacy" or (game.relationship.phase=="aftermath" and game.relationship.relaxed):
		return "intimacy"
	if game.modal=="":
		combat_hold = maxf(0.0,combat_hold-dt)
		for enemy in game.enemies:
			if not is_instance_valid(enemy) or enemy.dead:
				continue
			var distance: float = enemy.global_position.distance_to(game.player.global_position)
			if distance<30.0 and enemy.phase in ["chase","windup","recover","stunned"]:
				combat_hold = 6.0
				break
	if combat_hold>0:
		return "battle"
	if not game.in_crypt() and game.Wilderness.tier(Vector2(game.player.position.x,game.player.position.z),game.state.day_clock,game.world)>0:
		return "forest"
	return "night" if game.state.day_clock>=18 or game.state.day_clock<7 or game.in_crypt() else "day"

func select_track(next: String) -> void:
	if context==next:
		return
	# Only two voices: a rapid transition never accumulates orphan players.
	outgoing_gain = db_to_linear(channels[active].volume_db) if channels[active].playing else 0.0
	channels[1-active].stop()
	active = 1-active
	channels[active].stream = tracks[next]
	channels[active].volume_db = -80
	channels[active].play()
	context = next
	fade = 0.0

func _process(dt: float) -> void:
	var frozen: bool = muted or game.reporting
	for voice in ui_voices: voice.stream_paused = frozen
	if not frozen:
		trim_voices()
		if game.started and game.modal=="":
			bed_clock -= dt
			if bed_clock<=0:
				bed_clock = .2
				update_beds()
	for channel in channels:
		channel.stream_paused = frozen
	if frozen:
		return
	select_track(desired_context(dt))
	fade = minf(1.0,fade+dt/2.5)
	channels[active].volume_db = linear_to_db(maxf(0.0001,sin(fade*PI*0.5)*0.36))
	channels[1-active].volume_db = linear_to_db(maxf(0.0001,cos(fade*PI*0.5)*outgoing_gain))
	if fade>=1.0:
		channels[1-active].stop()

func summary() -> Dictionary:
	return {"context":context,"track":TRACKS.get(context,""),"position_seconds":channels[active].get_playback_position(),"transition":fade,"muted":muted,"report_paused":game.reporting,"volumes":game.visuals.audio_values.duplicate(),"recorded_files":library.sources.size(),"ambient_bed":ambient_family,"recent_effects":recent_events.duplicate(true)}

func make_wave(freq: float, duration: float, noise := 0.0, bell := false) -> AudioStreamWAV:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var samples := int(duration*22050)
	var bytes := PackedByteArray()
	bytes.resize(samples*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 882
	for i in range(samples):
		var t := float(i)/22050
		var envelope := pow(1.0-float(i)/samples,2)*minf(t*80,1)
		var value := sin(t*freq*TAU)*0.6 + sin(t*freq*TAU*2.01)*(0.3 if bell else 0.12)
		value = value*(1-noise)+rng.randf_range(-1,1)*noise
		bytes.encode_s16(i*2,int(clampf(value*envelope,-1,1)*20000))
	wave.data = bytes
	return wave

func ambience() -> AudioStreamWAV:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var count := 22050*12
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 712
	var low := 0.0
	for i in range(count):
		var t := float(i)/22050
		low = lerpf(low,rng.randf_range(-1,1),0.025)
		var wind := low*0.6*(0.7+0.3*sin(t*TAU/12))
		var bird := 0.0
		var phase := fmod(t,4.0)
		if phase>1.0 and phase<1.36:
			bird = sin(t*(2200+sin(t*32)*500)*TAU)*sin((phase-1)*PI/0.36)*0.035
		bytes.encode_s16(i*2,int(clampf(wind+bird,-1,1)*22000))
	wave.data = bytes
	wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wave.loop_end = count
	return wave

func procedural(id: String) -> AudioStream:
	if not cache.has(id):
		var specs := {"hit":[95.0,0.13,0.7],"swing":[240.0,0.15,0.85],"block":[530.0,0.2,0.16],"hurt":[65.0,0.2,0.5],"pickup":[660.0,0.25,0.0],"quest":[440.0,0.6,0.0],"step":[80.0,0.08,0.9],"bell":[196.0,2.5,0.0],"heal":[392.0,0.45,0.0],"thunder":[38.0,3.0,0.92]}
		specs["footstep_wood"] = [145.0,.075,.32]
		specs.merge({"ranger_shot":[58.0,.48,.98],"ranger_reload":[170.0,.18,.6],"ranger_cock":[740.0,.075,.45]})
		specs.merge({"dart":[780.0,0.12,0.1],"ember":[130.0,0.3,0.65],"rime":[980.0,0.3,0.2],"judgement":[330.0,0.35,0.05],"sanctuary":[262.0,0.7,0.0],"rebuke":[185.0,0.25,0.2],"repulsion":[95.0,0.2,0.6],"brittle":[1350.0,0.22,0.4],"spell_impact":[420.0,0.15,0.3]})
		var p: Array = specs.get(id,specs.hit)
		cache[id] = make_wave(p[0],p[1],p[2],id=="bell")
	return cache[id]

func family_for(id: String) -> String:
	var aliases := {"dart":"dart_cast","ember":"ember_cast","rime":"rime_cast","rebuke":"rebuke_cast","repulsion":"repulsion_cast","judgement":"judgement_cast","sanctuary":"sanctuary_cast","block":"shield_block","parry":"shield_parry","brittle":"brittle_shatter","quest":"quest_discovery","pickup":"item_pickup","ranger_shot":"musket_shot" if game.state.ranger.weapon=="musket" else "pistol_shot","ranger_reload":"flintlock_reload"}
	if id=="hurt": return "hurt_female" if game.state.profile.gender=="woman" else "hurt_male"
	if id=="swing": return "staff_swing" if game.state.profile.profession_id=="cleric" else "sword_swing"
	if id=="hit": return "staff_hit" if game.state.profile.profession_id=="cleric" else "sword_hit"
	if id=="step":
		var surface := step_family()
		return "footstep_stone" if surface=="footstep_wood" and not library.has(surface) else surface
	return aliases.get(id,id)

func play_effect(id: String, at := Vector3.INF, ui := false, fallback := "") -> bool:
	if muted or game.reporting or game.visuals.audio_values.sound_volume<=0: return false
	var family := family_for(id)
	var selected: Dictionary = library.choose(family)
	var legacy := {"parry":"block","quest_complete":"quest","dart_hit":"spell_impact","ember_hit":"spell_impact","rime_hit":"spell_impact","judgement_hit":"spell_impact"}
	var base_ids := ["hit","swing","block","hurt","pickup","quest","step","bell","heal","thunder","dart","ember","rime","judgement","sanctuary","rebuke","repulsion","brittle","spell_impact"]
	var substitute: String = fallback if not fallback.is_empty() else id if id in base_ids else legacy.get(id,"")
	if id in ["ranger_shot","ranger_reload","ranger_cock"]: substitute = id
	if family=="footstep_wood" and selected.is_empty(): substitute = "footstep_wood"
	if selected.is_empty() and substitute.is_empty(): return false
	var stream: AudioStream = selected.stream if not selected.is_empty() else procedural(substitute)
	var pool: Array = ui_voices if ui else spatial_voices if at!=Vector3.INF else voices
	var chosen: Variant = null
	for voice in pool:
		if not voice.playing:
			chosen = voice; break
	var priority := 3 if family.ends_with("_windup") else 2 if family.ends_with("_death") else 0 if id=="step" else 1
	if chosen==null and not ui:
		for voice in pool:
			if int(voice.get_meta("priority",0))<priority:
				chosen = voice; break
	if chosen==null and ui:
		chosen = pool[0]
	if chosen==null: return false
	chosen.stop()
	chosen.set_meta("priority",priority)
	chosen.stream = stream
	chosen.pitch_scale = randf_range(.97,1.03) if not ui else 1.0
	var volume := -17.0 if id=="step" else -12.0 if family.begins_with("npc_") else -20.0 if ui else -12.0
	chosen.volume_db = volume
	if chosen is AudioStreamPlayer3D: chosen.global_position = at
	var cap := 0.0
	if id=="step": cap = .46
	elif id in ["confirm","back_close","cooldown_not_ready"]: cap = .4
	elif family=="dart_cast" or family.ends_with("_hit"): cap = .75
	var offset: float = selected.get("offset",0.0)
	var ending: float = selected.get("end",stream.get_length())
	if family.ends_with("_windup"): cap = 1.4
	if family.begins_with("hurt_") or family.ends_with("_hurt"): cap = .9
	chosen.set_meta("cap",minf(ending,offset+cap) if cap>0 else ending)
	chosen.set_meta("event",family)
	chosen.set_meta("base_db",volume)
	chosen.play(offset)
	recent_events.append({"event":id,"family":family,"source":selected.get("path","procedural:"+substitute),"playback":selected.get("playback",""),"ui":ui})
	if recent_events.size()>24: recent_events.pop_front()
	return true

func trim_voices() -> void:
	for voice in voices+spatial_voices+ui_voices:
		var cap: float = voice.get_meta("cap",0.0)
		if voice.playing and cap>0:
			var remaining: float = cap-voice.get_playback_position()
			if remaining<=0: voice.stop()
			elif remaining<.06: voice.volume_db = voice.get_meta("base_db",-12.0)+linear_to_db(maxf(.001,remaining/.06))

func throttled(id: String, key: String, seconds: float, at := Vector3.INF, ui := false) -> bool:
	var now := Time.get_ticks_msec()/1000.0
	if now<float(cooldowns.get(key,-100.0))+seconds: return false
	if not play_effect(id,at,ui): return false
	cooldowns[key] = now
	return true

func greet(id: String) -> void:
	for voice in ui_voices:
		if str(voice.get_meta("event","")).begins_with("npc_"): voice.stop()
	var female := id in ["mara","ilya","vesna","sister","merchant","nera","ysabet"]
	throttled("npc_female_greeting" if female else "npc_male_greeting","greet:"+id,6.0,Vector3.INF,true)

func enemy_event(kind: String, event: String, at: Vector3, key: String) -> void:
	if kind=="pitchbound": kind = "bandit"
	elif kind=="boughstalker": kind = "wraith"
	var family := "warden" if kind=="guardian" else "unburied" if kind=="mournkeeper" else kind
	var name := "boss_death" if event=="death" and kind in ["guardian","mournkeeper"] else family+"_"+event
	throttled(name,key+":"+event,.6 if event=="hurt" else .8,at)

func step_family() -> String:
	if game.in_crypt(): return "footstep_stone"
	var p := Vector2(game.player.position.x,game.player.position.z)
	var contact: String = game.world.contact_step_family(game.player.position)
	if not contact.is_empty(): return contact
	if game.player.position.y<game.C.height_at(p.x,p.y)+.6:
		for bounds in game.world.water_bounds:
			if bounds.has_point(p): return "footstep_shallow_water"
	if game.weather and game.weather.sheltered: return "footstep_wood"
	var road: float = game.C.distance_to_road(p)
	return "footstep_stone" if road<2.8 else "footstep_dirt" if road<5.0 else "footstep_grass"

func bed(id: String) -> AudioStreamPlayer:
	if beds.has(id): return beds[id]
	var stream: AudioStream = library.loop_stream(id)
	if not stream: return null
	var player := AudioStreamPlayer.new()
	player.bus = SOUND_BUS
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.stream = stream
	player.volume_db = -80
	add_child(player)
	player.play()
	beds[id] = player
	return player

func update_beds() -> void:
	var wanted := "crypt_interior" if game.in_crypt() else "forest_night" if game.state.day_clock>=18 or game.state.day_clock<7 else "procedural"
	if wanted!=ambient_family:
		ambient_family = wanted
		ambient.stream = library.loop_stream(wanted) if library.has(wanted) else base_ambience
		ambient.play()
	ambient.volume_db = -30 if wanted!="procedural" else -26
	var fire := bed("campfire")
	if fire:
		var distance: float = game.fire_distance(game.player.position)
		fire.volume_db = linear_to_db(maxf(.0001,(1.0-clampf(distance/10.0,0.0,1.0))*.20))
	var sacred := bed("sanctuary_loop")
	if sacred:
		var inside: bool = game.combat.protected_at(game.player.position)
		sacred.volume_db = -27 if inside else -80
	var burning := bed("burn_loop")
	if burning:
		var distance := 999.0
		for enemy in game.enemies:
			if not enemy.dead and enemy.burning>0: distance = minf(distance,enemy.position.distance_to(game.player.position))
		burning.volume_db = linear_to_db(maxf(.0001,(1.0-clampf(distance/14.0,0.0,1.0))*.14))

func reset_effects() -> void:
	cooldowns.clear()
	for voice in voices+spatial_voices+ui_voices: voice.stop()
	for source in beds.values(): source.volume_db = -80
	bed_clock = 0.0

func tick(dt: float, moving: bool, sprint: bool) -> void:
	if muted:
		return
	breath_clock -= dt
	if sprint and game.state.stamina<30 and breath_clock<=0:
		play_effect("low_stamina_breath")
		breath_clock = 7.0
	step_clock -= dt
	if moving and step_clock<=0:
		play_effect("step")
		step_clock = 0.32 if sprint else 0.48
