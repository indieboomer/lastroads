extends RefCounted

const PRESETS := [
	{"name":"Hollow 16", "tag":"THE PAINTED ROAD", "height":360, "mode":0, "description":"Fine pixels and 16-bit colour. Keeps the painted warmth, with quieter detail across sprites, stone and water."},
	{"name":"Copper & Pine", "tag":"AUTUMN ON AN OLD PC", "height":270, "mode":1, "description":"Copper light, deep pine shadows and a hand-picked earth palette. A warm, grainy storybook expedition."},
	{"name":"DOS Chronicle", "tag":"A DISKETTE FROM 1993", "height":200, "mode":2, "description":"Bold VGA colours, coarse pixels and ordered dithering. The most uncompromising old-school option."},
	{"name":"Gothic Dusk", "tag":"THE BELL AFTER DARK", "height":270, "mode":3, "description":"Slate, plum and moss, broken by amber firelight. Inspired by the brooding castle and valley reference."},
	{"name":"CRT Traveller", "tag":"ONE MORE NIGHT BY THE MONITOR", "height":360, "mode":4, "description":"Soft phosphor colour, restrained scanlines and an RGB mask. A warm late-night desktop RPG."},
	{"name":"Gilded Hollow", "tag":"GOLDEN LIGHT / DEEP EMERALD", "height":270, "mode":5, "description":"A richer Copper & Pine: gilded highlights, deep emerald woods and cool blue distance. Try Fine pixels, 50% dithering and 30% grain."},
	{"name":"Macintosh", "tag":"INK / AGED PAPER", "height":360, "mode":6, "description":"Obra Dinn-inspired one-bit engraving: near-black ink and warm ivory, with stable ordered hatching. Fine pixels suit faces; dithering reveals shaded detail."},
	{"name":"IBM 5151", "tag":"GREEN PHOSPHOR / MIDNIGHT", "height":350, "mode":7, "description":"One-bit green phosphor on deep green-black. A luminous night expedition, with etched shadows and no animated flicker."},
	{"name":"Commodore 1084", "tag":"BLUE INK / PALE PHOSPHOR", "height":360, "mode":8, "description":"One-bit navy and icy blue, inspired by Obra Dinn's monitor treatments. Grain roughens the hatching without adding extra colours. Text remains sharp."}
]
const TREES := [
	{"name":"Rooted 3D grove", "description":"Solid trunks, branches and sculpted crowns. Real depth from every side; no camera rotation. A simpler sculpted art style."},
	{"name":"Crossed paintings", "description":"Recommended: three fixed intersecting illustrations. Preserves the generated art without rotating; some paper-like overlap remains."},
	{"name":"Still illustrations", "description":"One fixed painting facing the nearest road. Beautiful from the path, but thin when seen edge-on."},
	{"name":"Camera-facing · legacy", "description":"The original rotating tree cards, retained for comparison. Roots and collision stay fixed."}
]
const DEFAULTS := {"enabled":true,"preset":1,"detail":2,"dither":0.50,"grain":0.30,"trees":1,"wind_strength":2,"blood_size":1,"lightning":true,"intimacy":true,"dense_grass":true}
const AUDIO_DEFAULTS := {"music_volume":1.0,"sound_volume":1.0}
var audio_values: Dictionary = AUDIO_DEFAULTS.duplicate()
var values: Dictionary = DEFAULTS.duplicate()

func read(path: String) -> void:
	values = DEFAULTS.duplicate()
	audio_values = AUDIO_DEFAULTS.duplicate()
	var config := ConfigFile.new()
	if config.load(path)!=OK:
		return
	for key in AUDIO_DEFAULTS:
		var raw: Variant = config.get_value("audio",key,AUDIO_DEFAULTS[key])
		if (raw is float or raw is int) and is_finite(float(raw)):
			audio_values[key] = clampf(float(raw),0.0,1.0)
	var enabled: Variant = config.get_value("visuals","enabled",DEFAULTS.enabled)
	values.enabled = enabled if enabled is bool else false
	var lightning: Variant = config.get_value("visuals","lightning",true)
	values.lightning = lightning if lightning is bool else true
	var intimacy: Variant = config.get_value("visuals","intimacy",true)
	values.intimacy = intimacy if intimacy is bool else true
	var dense: Variant = config.get_value("visuals","dense_grass",true)
	values.dense_grass = dense if dense is bool else true
	for key in ["preset","detail","trees","wind_strength","blood_size"]:
		var raw: Variant = config.get_value("visuals",key,DEFAULTS[key])
		if raw is int:
			var limit: int = PRESETS.size()-1 if key=="preset" else TREES.size()-1 if key=="trees" else 3 if key=="wind_strength" else 1 if key=="blood_size" else 2
			values[key] = clampi(raw,0,limit)
	for key in ["dither","grain"]:
		var raw: Variant = config.get_value("visuals",key,DEFAULTS[key])
		if (raw is float or raw is int) and is_finite(float(raw)):
			values[key] = clampf(float(raw),0.0,1.0)

func write(path: String) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var config := ConfigFile.new()
	for key in values:
		config.set_value("visuals",key,values[key])
	for key in audio_values:
		config.set_value("audio",key,audio_values[key])
	return config.save(path)

func uniforms(material: ShaderMaterial) -> void:
	material.set_shader_parameter("retro_enabled",values.enabled)
	material.set_shader_parameter("style",PRESETS[values.preset].mode)
	material.set_shader_parameter("virtual_height",float(PRESETS[values.preset].height)*[0.75,1.0,1.5][values.detail])
	material.set_shader_parameter("dither_amount",values.dither)
	material.set_shader_parameter("grain_amount",values.grain)

func summary() -> Dictionary:
	var result := values.duplicate()
	result["name"] = PRESETS[values.preset].name if values.enabled else "Original illustration"
	result["virtual_height"] = float(PRESETS[values.preset].height)*[0.75,1.0,1.5][values.detail]
	result["tree_mode"] = TREES[values.trees].name
	return result
