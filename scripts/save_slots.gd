extends RefCounted

const INTERVAL := 120.0
const DEBOUNCE := 2.0
const SLOT_COUNT := 3
const MAX_BYTES := 32*1024*1024
var game: Node
var pending := ""
var grace := 0.0
var elapsed := 0.0
var retry := 0.0
var status := ""
var status_left := 0.0

func reset() -> void:
	pending = ""
	grace = 0
	elapsed = 0
	retry = 0
	status = ""
	status_left = 0

func enabled() -> bool:
	return not game.test_mode or "--safety-check" in OS.get_cmdline_user_args()

func request(reason: String) -> void:
	if not game.started or not enabled(): return
	if pending.is_empty(): grace = DEBOUNCE
	pending = reason

func auto_paths() -> Array[String]:
	var paths: Array[String] = []
	for i in range(SLOT_COUNT): paths.append(game.save_path().get_basename()+"-auto-%d.json" % (i+1))
	return paths

func read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>MAX_BYTES: return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text())!=OK: return {}
	var value: Variant = parser.data
	return value if value is Dictionary and game.validate_save(value) else {}

func stamp(path: String, payload: Dictionary = {}) -> float:
	var value: Variant = payload.get("saved_at_unix",FileAccess.get_modified_time(path))
	return float(value) if (value is int or value is float) and is_finite(float(value)) else 0.0

func resume_info() -> Dictionary:
	var result := {}
	var paths: Array[String] = [game.save_path()]
	paths.append_array(auto_paths())
	var damaged := false
	for path in paths:
		var payload := read_valid(path)
		if payload.is_empty():
			if FileAccess.file_exists(path): damaged = true
			continue
		var when := stamp(path,payload)
		if result.is_empty() or when>result.stamp:
			result = {"path":path,"stamp":when,"kind":payload.get("save_kind","manual"),"recovered":false}
	# Backups are recovery copies, never competitors to an intact save slot.
	if result.is_empty():
		for path in paths:
			var backup := path+".bak"
			var payload := read_valid(backup)
			if payload.is_empty(): continue
			var when := stamp(backup,payload)
			if result.is_empty() or when>result.stamp:
				result = {"path":backup,"stamp":when,"kind":"backup","recovered":true}
	if not result.is_empty() and damaged: result.recovered = true
	return result

func has_resume() -> bool: return not resume_info().is_empty()

func load_choice(explicit_path := "") -> Dictionary:
	if not explicit_path.is_empty():
		var value := read_valid(explicit_path)
		return {"path":explicit_path,"payload":value} if not value.is_empty() else {}
	# F9 keeps its manual-save meaning. If that slot is damaged or missing,
	# recovery can use its intact backup or the separate automatic checkpoints.
	for path in [game.save_path(),game.save_path()+".bak"]:
		var value := read_valid(path)
		if not value.is_empty(): return {"path":path,"payload":value}
	var latest := resume_info()
	if latest.is_empty(): return {}
	return {"path":latest.path,"payload":read_valid(latest.path)}

func write(path: String, payload: Dictionary) -> Dictionary:
	# Validate the on-disk JSON form too: a valid live Variant must not become
	# an unreadable save after JSON numeric conversion or interrupted writing.
	var text := JSON.stringify(payload,"\t")
	var parsed: Variant = JSON.parse_string(text)
	if not game.validate_save(parsed): return {"ok":false,"reason":"Save validation failed; existing files kept."}
	var folder_error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if folder_error!=OK: return {"ok":false,"reason":"Cannot create save folder: "+error_string(folder_error)}
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return {"ok":false,"reason":"Cannot write save: "+error_string(FileAccess.get_open_error())}
	file.store_string(text)
	file.flush()
	file.close()
	if read_valid(path+".tmp").is_empty(): return {"ok":false,"reason":"Written save could not be verified; existing files kept."}
	# Never replace a healthy backup with a corrupt primary file.
	if not read_valid(path).is_empty():
		var backup_error := DirAccess.copy_absolute(path,path+".bak.tmp")
		if backup_error!=OK or read_valid(path+".bak.tmp").is_empty(): return {"ok":false,"reason":"Save backup failed; existing save kept."}
		backup_error = DirAccess.rename_absolute(path+".bak.tmp",path+".bak")
		if backup_error!=OK: return {"ok":false,"reason":"Cannot finalize backup; existing save kept."}
	var error := DirAccess.rename_absolute(path+".tmp",path)
	if error!=OK:
		if not FileAccess.file_exists(path) and not read_valid(path+".bak").is_empty(): DirAccess.copy_absolute(path+".bak",path)
		return {"ok":false,"reason":"Cannot finalize save; recovery copies kept: "+error_string(error)}
	return {"ok":true,"reason":""}

func safe() -> bool:
	if not game.started or game.modal!="" or game.reporting or game.state.health<=0: return false
	if game.coop.active and not game.coop.session_ready: return false
	if not game.player.is_on_floor() or game.attack_clock>0 or game.swing>0: return false
	if game.threats_near(game.player.position,28): return false
	if game.combat.projectiles.size()>0 or game.state.ranger.reload_left>0: return false
	return true

func save_auto(reason := "Road checkpoint") -> bool:
	if not safe(): return false
	var paths := auto_paths()
	var path: String = paths[0]
	var oldest := INF
	for candidate in paths:
		var payload := read_valid(candidate)
		if payload.is_empty():
			path = candidate
			break
		var when := stamp(candidate,payload)
		if when<oldest:
			oldest = when
			path = candidate
	var payload: Dictionary = game.snapshot()
	payload.save_kind = "auto"
	payload.save_reason = reason
	payload.saved_at_unix = Time.get_unix_time_from_system()
	var result := write(path,payload)
	if not result.ok:
		retry = 30
		status = "Autosave failed / "+result.reason
		status_left = 12
		game.message(status,8)
		return false
	game.state.log_event("autosave:"+reason)
	pending = ""
	elapsed = 0
	grace = 0
	status = "Autosaved / "+Time.get_time_string_from_system().left(5)
	status_left = 8
	return true

func tick(dt: float) -> void:
	if not enabled(): return
	status_left = maxf(0,status_left-dt)
	elapsed += dt
	grace = maxf(0,grace-dt)
	retry = maxf(0,retry-dt)
	if elapsed>=INTERVAL and pending.is_empty(): request("Two minutes on the road")
	if not pending.is_empty() and grace<=0 and retry<=0 and safe(): save_auto(pending)
