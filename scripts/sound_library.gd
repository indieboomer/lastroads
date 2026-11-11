extends RefCounted

var families: Dictionary = {}
var previous: Dictionary = {}
var sources: Array = []
var rng := RandomNumberGenerator.new()

func scan() -> void:
	families.clear()
	sources.clear()
	rng.randomize()
	if not DirAccess.dir_exists_absolute("res://sounds"): return
	var audit: Dictionary = {}
	if FileAccess.file_exists("res://assets/audio/recordings.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/recordings.json"))
		if parsed is Dictionary: audit = parsed
	var files := DirAccess.get_files_at("res://sounds")
	files.sort()
	var suffix := RegEx.new()
	suffix.compile("_[0-9]+$")
	for entry in files:
		var file: String = entry.trim_suffix(".remap").trim_suffix(".import")
		if file.get_extension().to_lower() not in ["mp3","wav","ogg"]: continue
		var path := "res://sounds/"+file
		if path in sources: continue
		var family := file.get_basename().to_lower()
		if family.begins_with("hurt_") and family.ends_with("_female"):
			family = "hurt_female"
		else:
			family = suffix.sub(family,"")
			if family=="hurt": family = "hurt_male"
		var playback := path
		if not ResourceLoader.exists(playback): playback = path
		var stream := load(playback) as AudioStream
		if not stream: continue
		if not families.has(family): families[family] = []
		var timing: Dictionary = audit.get(file,{}) if playback==path else {}
		families[family].append({"path":path,"playback":playback,"stream":stream,"offset":timing.get("offset",0.0),"end":timing.get("end",stream.get_length())})
		sources.append(path)

func has(family: String) -> bool:
	return families.has(family) and not families[family].is_empty()

func choose(family: String) -> Dictionary:
	if not has(family): return {}
	var options: Array = families[family]
	var index := rng.randi_range(0,options.size()-1)
	if options.size()>1 and index==previous.get(family,-1): index = (index+1)%options.size()
	previous[family] = index
	return options[index]

func loop_stream(family: String, variant := -1) -> AudioStream:
	var selected: Dictionary = choose(family) if variant<0 else families[family][mini(variant,families[family].size()-1)] if has(family) else {}
	if selected.is_empty(): return null
	var stream: AudioStream = selected.stream.duplicate()
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size()/((2 if stream.format==AudioStreamWAV.FORMAT_16_BITS else 1)*(2 if stream.stereo else 1))
	return stream
