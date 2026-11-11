extends RefCounted

func run(g: Node) -> void:
 await g.get_tree().process_frame
 verify(g.test_mode and g.audio.context=="menu")
 await settings_checks(g)
 await recording_checks(g)
 for stream in g.audio.tracks.values():
  verify(stream.loop and stream.get_length()>30.0)
 g.start_new()
 g.state.day_clock = 12
 await g.get_tree().process_frame
 verify(g.audio.context=="day")
 g.state.day_clock = 22
 await g.get_tree().process_frame
 verify(g.audio.context=="night")
 g.set_modal("inventory")
 g.teleport(Vector2(-200,0),0)
 g.audio.combat_hold = 0
 verify(g.audio.desired_context(0)=="forest")
 g.state.day_clock = 12
 verify(g.audio.desired_context(0)=="forest")
 verify(g.audio.tracks.forest.loop)
 g.teleport(Vector2(0,0),0)
 verify(g.audio.desired_context(0)=="day")
 g.state.day_clock = 22
 verify(g.audio.desired_context(0)=="night")
 g.teleport(Vector2(-3,43),0)
 g.set_modal("")
 var enemy = g.enemies[0]
 enemy.position = g.player.position+Vector3(4,0,0)
 enemy.phase = "chase"
 await g.get_tree().process_frame
 verify(g.audio.context=="battle")
 verify(g.audio.combat_hold>0)
 enemy.phase = "idle"
 verify(g.audio.desired_context(0.1)=="battle")
 enemy.kind = "guardian"
 enemy.phase = "windup"
 verify(g.audio.desired_context(0.1)=="battle")
 enemy.dead = true
 g.audio.combat_hold = 0
 g.relationship.phase = "prelude"
 g.set_modal("intimacy")
 await g.get_tree().process_frame
 verify(g.audio.context=="intimacy" and g.get_tree().paused)
 g.reporting = true
 await g.get_tree().process_frame
 var position: float = g.audio.channels[g.audio.active].get_playback_position()
 var fade: float = g.audio.fade
 await g.get_tree().create_timer(0.15).timeout
 verify(is_equal_approx(g.audio.fade,fade))
 verify(absf(g.audio.channels[g.audio.active].get_playback_position()-position)<0.06)
 g.reporting = false
 g.audio.set_muted(true)
 await g.get_tree().process_frame
 verify(g.audio.channels[g.audio.active].stream_paused)
 g.audio.set_muted(false)
 g.set_modal("")
 g.audio.combat_hold = 0
 await g.get_tree().process_frame
 verify(g.audio.context=="night")
 g.state.day_clock = 12
 g.teleport(Vector2(-3,43),0.6)
 g.visuals.values.enabled = true
 for child in g.ui.hud_root.get_children():
  if child is CanvasItem and child not in [g.ui.retro_effect,g.ui.retro_copy]:
   child.hide()
 for index in range(6,9):
  g.visuals.values.preset = index
  g.ui.apply_visuals()
  await g.capture("09-monitor-"+str(index)+"-day")
  g.state.day_clock = 22
  await g.capture("09-monitor-"+str(index)+"-night")
  g.state.day_clock = 12
 verify(g.snapshot().soundtrack.track!="")
 print("SOUND PASS: persistent independent music/effects sliders, title/pause Sounds tab, bus routing/weather/zero volume/F10/invalid-config/reset isolation;  six looping supplied/recovered tracks, title/day/night/forest/combat/intimacy priority, paused intimacy playback, frozen report transition/playhead, mute/resume, two-channel crossfades, three rendered monitor styles at day/night")
 g.get_tree().quit()

func settings_checks(g: Node) -> void:
 var music_bus := AudioServer.get_bus_index(g.audio.MUSIC_BUS)
 var sound_bus := AudioServer.get_bus_index(g.audio.SOUND_BUS)
 verify(music_bus>=0 and sound_bus>=0 and music_bus!=sound_bus)
 verify(g.audio.ambient.bus==g.audio.SOUND_BUS)
 verify(g.weather.rain_stream.bus==g.audio.SOUND_BUS and g.weather.wind_stream.bus==g.audio.SOUND_BUS)
 for channel in g.audio.channels: verify(channel.bus==g.audio.MUSIC_BUS)
 for voice in g.audio.voices: verify(voice.bus==g.audio.SOUND_BUS)
 g.ui.open_settings("title")
 g.ui.settings_sound_tab.pressed.emit()
 verify(g.ui.settings_sounds.visible and not g.ui.settings_art.visible and not g.ui.settings_world.visible)
 verify(not g.ui.settings_preview.visible and not g.ui.settings_reset_look.visible)
 g.ui.settings_music_volume.value = 65
 g.ui.settings_sound_volume.value = 35
 verify(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(music_bus)),.65))
 verify(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(sound_bus)),.35))
 var saved = g.visuals.get_script().new()
 saved.read(g.settings_path())
 verify(saved.audio_values==g.visuals.audio_values)
 g.ui.settings_reset_look.pressed.emit()
 verify(g.visuals.audio_values.music_volume==.65 and g.visuals.audio_values.sound_volume==.35)
 await g.capture("12-sounds-title")
 g.ui.settings_music_volume.value = 0
 verify(AudioServer.is_bus_mute(music_bus) and not AudioServer.is_bus_mute(sound_bus))
 g.ui.settings_sound_volume.value = 0
 verify(AudioServer.is_bus_mute(sound_bus))
 g.ui.settings_sound_volume.value = 35
 g.audio.set_muted(true)
 g.ui.settings_music_volume.value = 65
 verify(AudioServer.is_bus_mute(sound_bus) and AudioServer.is_bus_mute(music_bus))
 g.audio.set_muted(false)
 verify(not AudioServer.is_bus_mute(sound_bus) and not AudioServer.is_bus_mute(music_bus))
 verify(g.visuals.audio_values.music_volume==.65 and g.visuals.audio_values.sound_volume==.35)
 var look: Dictionary = g.visuals.values.duplicate()
 g.ui.settings_reset_sound.pressed.emit()
 verify(g.visuals.values==look and g.visuals.audio_values==g.visuals.AUDIO_DEFAULTS)
 g.ui.leave_settings()
 verify(not g.started and g.get_tree().paused)
 g.start_new()
 g.ui.open_settings("pause")
 g.ui.settings_sound_tab.pressed.emit()
 g.ui.settings_music_volume.value = 25
 g.ui.settings_sound_volume.value = 80
 await g.capture("12-sounds-pause")
 g.ui.leave_settings()
 verify(g.modal=="pause" and g.get_tree().paused)
 g.ui.open_settings("pause")
 g.ui.settings_sound_tab.pressed.emit()
 verify(g.ui.settings_music_volume.value==25 and g.ui.settings_sound_volume.value==80)
 verify(g.snapshot().soundtrack.volumes.music_volume==.25)
 g.ui.settings_reset_sound.pressed.emit()
 g.ui.leave_settings()
 g.set_modal("")
 g.to_title()
 var config := ConfigFile.new()
 config.set_value("audio","music_volume",-4)
 config.set_value("audio","sound_volume",8)
 var invalid_path: String = g.data_root().path_join("reports/invalid-audio.cfg")
 verify(config.save(invalid_path)==OK)
 saved.read(invalid_path)
 verify(saved.audio_values.music_volume==0 and saved.audio_values.sound_volume==1)
 config.set_value("audio","music_volume","invalid")
 config.set_value("audio","sound_volume",true)
 config.save(invalid_path)
 saved.read(invalid_path)
 verify(saved.audio_values==g.visuals.AUDIO_DEFAULTS)
 config.clear()
 config.set_value("visuals","preset",3)
 config.save(invalid_path)
 saved.read(invalid_path)
 verify(saved.values.preset==3 and saved.audio_values==g.visuals.AUDIO_DEFAULTS)

func recording_checks(g: Node) -> void:
 g.start_new()
 g.set_physics_process(false)
 var audio: Node = g.audio
 verify(audio.library.sources.size()==94)
 for family in audio.library.families:
  for item in audio.library.families[family]:
   verify(item.stream.get_length()>0 and ResourceLoader.exists(item.path))
  var first: Dictionary = audio.library.choose(family)
  var next: Dictionary = audio.library.choose(family)
  if audio.library.families[family].size()>1: verify(first.path!=next.path)
 for family in ["footstep_dirt","footstep_grass","footstep_stone","footstep_shallow_water"]:
  var step: Dictionary = audio.library.choose(family)
  verify(step.playback.begins_with("res://sounds/footstep_") and step.stream is AudioStreamMP3)
 audio.reset_effects()
 g.talk("mara")
 verify(audio.recent_events.back().family=="npc_female_greeting" and audio.recent_events.back().ui)
 var count: int = audio.recent_events.size()
 g.talk("mara")
 verify(audio.recent_events.size()==count,"Dialogue pages must not repeat greetings")
 g.talk("osric")
 verify(audio.recent_events.back().family=="npc_male_greeting")
 var greetings := 0
 for voice in audio.ui_voices:
  if voice.playing and str(voice.get_meta("event","")).begins_with("npc_"): greetings += 1
 verify(greetings==1)
 var greeting: Variant = null
 for voice in audio.ui_voices:
  if voice.playing and voice.get_meta("event","")=="npc_male_greeting": greeting = voice
 verify(greeting!=null)
 g.open_report()
 verify(greeting.stream_paused)
 var position: float = greeting.get_playback_position()
 await g.get_tree().create_timer(.12).timeout
 verify(absf(greeting.get_playback_position()-position)<.06)
 g.close_report()
 g.set_modal("")
 audio.reset_effects()
 g.state.profile.gender = "woman"
 g.state.profile.presentation = 1
 verify(audio.play_effect("hurt"))
 verify(audio.recent_events.back().source.contains("female"))
 g.state.profile.gender = "man"
 g.state.profile.presentation = 0
 verify(audio.play_effect("hurt"))
 verify(not audio.recent_events.back().source.contains("female"))
 g.state.profile.profession_id = "cleric"
 verify(audio.play_effect("hit",g.player.position+Vector3.FORWARD))
 verify(audio.recent_events.back().family=="staff_hit")
 audio.reset_effects()
 for id in ["dart","dart_hit","ember","ember_hit","rime","rime_hit","rebuke","repulsion","judgement","sanctuary","parry","quest_complete"]:
  audio.reset_effects()
  verify(audio.play_effect(id))
  verify(audio.recent_events.back().source.begins_with("res://sounds/"))
 g.state.profile.profession_id = "ranger"
 for weapon in ["pistol","musket"]:
  g.state.ranger.weapon = weapon
  audio.reset_effects()
  verify(audio.play_effect("ranger_shot"))
  verify(audio.recent_events.back().source=="res://sounds/"+weapon+"_shot.mp3")
  audio.reset_effects()
  verify(audio.play_effect("ranger_reload"))
  verify(audio.recent_events.back().source=="res://sounds/flintlock_reload.mp3")
 audio.reset_effects()
 verify(audio.play_effect("sword_hit") and audio.recent_events.back().source.begins_with("res://sounds/sword_hit_"))
 print("RANGER RECORDINGS PASS: distinct pistol/musket shots, shared flintlock reload and supplied sword recordings")
 await rendered_audio_checks(g)
 var original: Array = audio.library.families.rebuke_cast
 audio.library.families.erase("rebuke_cast")
 audio.reset_effects()
 verify(audio.play_effect("rebuke"))
 verify(audio.recent_events.back().source=="procedural:rebuke")
 audio.library.families.rebuke_cast = original
 verify(not audio.play_effect("nonexistent_optional_sound"))
 audio.reset_effects()
 g.teleport(Vector2(0,45))
 verify(audio.step_family()=="footstep_stone")
 g.teleport(Vector2(-210,30))
 g.weather.sheltered = false
 verify(audio.step_family()=="footstep_grass")
 g.state.day_clock = 22
 audio.update_beds()
 verify(audio.ambient_family=="forest_night" and audio.ambient.stream is AudioStreamMP3)
 g.teleport(Vector2(130,-380))
 audio.update_beds()
 verify(audio.ambient_family=="crypt_interior")
 for id in ["campfire","burn_loop","sanctuary_loop"]:
  verify(audio.beds.has(id) and audio.beds[id].stream.loop and audio.beds[id].bus==audio.SOUND_BUS)
 verify(g.weather.rain_stream.stream is AudioStreamMP3 and g.weather.rain_heavy_stream.stream is AudioStreamMP3)
 verify(g.weather.rain_heavy_stream.bus==audio.SOUND_BUS)
 for voice in audio.spatial_voices: verify(voice.bus==audio.SOUND_BUS)
 g.set_physics_process(true)
 g.start_new()
 print("RECORDINGS PASS: 94 loadable source recordings, nonrepeating available variants, seven bounded footfalls, shared gender greetings/one per conversation/no overlap/paused reports, player hurt gender, staff and spell dispatch, absent-file fallback, positional routing and context loops/rain layers")

func rendered_audio_checks(g: Node) -> void:
 var audio: Node = g.audio
 AudioServer.add_bus()
 var bus := AudioServer.bus_count-1
 AudioServer.set_bus_name(bus,"RecordingProbe")
 var capture := AudioEffectRecord.new()
 capture.format = AudioStreamWAV.FORMAT_16_BITS
 AudioServer.add_bus_effect(bus,capture)
 await g.get_tree().create_timer(.15).timeout
 for id in ["pistol","musket","reload","step"]:
  audio.reset_effects()
  capture.set_recording_active(true)
  g.state.ranger.weapon = "musket" if id=="musket" else "pistol"
  g.teleport(Vector2(0,45))
  var event := "ranger_reload" if id=="reload" else "step" if id=="step" else "ranger_shot"
  verify(audio.play_effect(event))
  var selected: Dictionary = audio.recent_events.back()
  verify(selected.source.begins_with("res://sounds/") and selected.playback==selected.source)
  var voice: AudioStreamPlayer
  for candidate in audio.voices:
   if candidate.playing and candidate.get_meta("event","")==selected.family:
    voice = candidate
    break
  verify(voice!=null and voice.stream is AudioStreamMP3)
  voice.bus = "RecordingProbe"
  await g.get_tree().create_timer(1.0).timeout
  capture.set_recording_active(false)
  var wave := capture.get_recording()
  verify(wave!=null)
  var bytes := wave.data
  var peak := 0.0
  for i in range(0,bytes.size(),2):
   peak = maxf(peak,absf(bytes.decode_s16(i)/32768.0))
  verify(bytes.size()>4000 and peak>.0001,"Recorded output is silent: "+id)
  verify(wave.save_to_wav(g.data_root().path_join("reports/rendered-"+id+".wav"))==OK)
  voice.stop()
  voice.bus = audio.SOUND_BUS
  print("RENDERED AUDIO PASS: %s / %s / peak %.4f" % [id,selected.playback,peak])
 AudioServer.remove_bus(bus)

# Release exports strip assert expressions entirely. Always execute validation,
# including playback/save actions, and report failures to the build runner.
func verify(condition: bool, detail := "") -> void:
 if not condition:
  push_error("VALIDATION FAILED: "+detail)
