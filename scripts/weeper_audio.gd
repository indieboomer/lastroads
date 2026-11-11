extends RefCounted

const FILES := {
	"lament":["weeper_lament_1","weeper_lament_2","weeper_lament_3","weeper_lament_4"],
	"windup":["weeper_inhale_1","weeper_inhale_2"],
	"scream":["weeper_scream_1","weeper_scream_2","weeper_scream_3","weeper_scream_4"],
	"recover":["weeper_breathe_1","weeper_breathe_2"],
	"sweep":["weeper_arm_swing"],
	"death":["weeper_death_1","weeper_death_2"]
}
const CAPS := {"lament":13.0,"windup":1.15,"scream":2.1,"recover":2.15,"sweep":.75,"death":4.0}
var previous: Dictionary = {}
var audit: Dictionary = {}

func _init() -> void:
	if FileAccess.file_exists("res://assets/audio/weeper-recordings.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/weeper-recordings.json"))
		if parsed is Dictionary: audit = parsed

func choose(event: String) -> Dictionary:
	if not FILES.has(event): return {}
	var options: Array = FILES[event]
	var index := randi_range(0,options.size()-1)
	if options.size()>1 and index==previous.get(event,-1): index = (index+1)%options.size()
	previous[event] = index
	var file: String = options[index]+".mp3"
	var path := "res://sounds/weeper/"+file
	if not ResourceLoader.exists(path): return {}
	var stream: AudioStream = load(path)
	var timing: Dictionary = audit.get(file,{})
	var offset: float = timing.get("offset",0.0)
	var end: float = timing.get("end",stream.get_length())
	var gain := clampf(linear_to_db(.65/maxf(.01,float(timing.get("peak",1.0)))),-8,15)
	return {"stream":stream,"path":path,"offset":offset,"length":minf(end-offset,CAPS[event]),"gain":gain}
