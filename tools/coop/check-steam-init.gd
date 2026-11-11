extends SceneTree

func _initialize() -> void:
	call_deferred("run_check")

func run_check() -> void:
	assert(ProjectSettings.get_setting("coop/steam_app_id")==480)
	var transport := preload("res://scripts/coop_transport.gd").new()
	root.add_child(transport)
	var report := {"default_app_id":480,"steam_available":Engine.has_singleton("Steam"),"initialized":transport.steam_ready,"message":transport.last_error,"invites_sent":0,"lobbies_created":0}
	var file := FileAccess.open("res://reports/coop/steam-init-check.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("STEAM INIT CHECK: ",JSON.stringify(report))
	transport.queue_free()
	quit()
