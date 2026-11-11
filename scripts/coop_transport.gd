extends Node

signal packet_received(sender: int, packet: Dictionary)
signal departed(peer: int)
signal status_changed(text: String)
signal invite_received(lobby: int)
const PROTOCOL := 1
const MAX_PACKET := 512000
var steam: Object
var steam_ready := false
var lobby := 0
var local_id := 1
var host_id := 1
var hosting := false
var active := false
var mode := ""
var peer: ENetMultiplayerPeer
var last_error := ""
var pending_lobby := 0
var connected_ids: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")
		var app_id: int = int(ProjectSettings.get_setting("coop/steam_app_id",480))
		# An explicit file overrides the development default; environment wins last.
		for path in [ProjectSettings.globalize_path("res://steam_appid.txt"),OS.get_executable_path().get_base_dir().path_join("steam_appid.txt"),OS.get_executable_path().get_base_dir().get_base_dir().path_join("steam_appid.txt")]:
			if FileAccess.file_exists(path):
				app_id = int(FileAccess.get_file_as_string(path).strip_edges())
				break
		if OS.has_environment("LAST_ROADS_STEAM_APP_ID"): app_id = int(OS.get_environment("LAST_ROADS_STEAM_APP_ID"))
		if app_id>0:
			var result: Dictionary = steam.steamInitEx(app_id,false)
			steam_ready = result.get("status",-1)==0
			if not steam_ready: last_error = "Steam could not initialize. Open Steam and check the configured App ID."
		else: last_error = "Set the game's Steam App ID before using Steam invitations."
	else: last_error = "Steam support requires launch-coop.cmd (GodotSteam). Local network co-op is available."
	if steam_ready:
		steam.lobby_created.connect(_lobby_created)
		steam.lobby_joined.connect(_lobby_joined)
		steam.join_requested.connect(func(id, _friend): pending_lobby = id; invite_received.emit(id))
		steam.network_messages_session_request.connect(_session_requested)
		steam.lobby_chat_update.connect(_lobby_update)
		steam.initRelayNetworkAccess()
	var args := OS.get_cmdline_args()+OS.get_cmdline_user_args()
	for index in range(args.size()-1):
		if args[index]=="+connect_lobby": pending_lobby = int(args[index+1])
	if pending_lobby>0: call_deferred("_announce_invite")

func _announce_invite() -> void:
	invite_received.emit(pending_lobby)

func host_steam() -> Error:
	if not steam_ready: return ERR_UNAVAILABLE
	leave()
	mode = "steam"
	hosting = true
	local_id = steam.getSteamID()
	host_id = local_id
	steam.createLobby(1,4) # Friends only, including the host.
	return OK

func join_steam(id: int) -> Error:
	if not steam_ready or id<=0: return ERR_UNAVAILABLE
	leave()
	mode = "steam"
	hosting = false
	local_id = steam.getSteamID()
	steam.joinLobby(id)
	return OK

func _lobby_created(result: int, id: int) -> void:
	if result!=1: status_changed.emit("Steam could not create a lobby."); return
	lobby = id
	steam.setLobbyData(id,"game","the_last_roads")
	steam.setLobbyData(id,"protocol",str(PROTOCOL))
	steam.setLobbyData(id,"build",preload("res://scripts/content.gd").BUILD)
	steam.setLobbyMemberLimit(id,4)
	steam.setLobbyJoinable(id,true)
	steam.setRichPresence("connect","+connect_lobby "+str(id))
	active = true
	status_changed.emit("Steam lobby ready / invite up to three friends.")

func _lobby_joined(id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response!=1: status_changed.emit("Steam lobby is full or unavailable."); return
	lobby = id
	if hosting: return
	if steam.getLobbyData(id,"game")!="the_last_roads" or steam.getLobbyData(id,"protocol")!=str(PROTOCOL):
		leave(); status_changed.emit("This invitation is for an incompatible lobby."); return
	host_id = steam.getLobbyOwner(id)
	active = true
	status_changed.emit("Connected to Steam lobby.")

func lobby_member(id: int) -> bool:
	if not steam_ready or lobby==0: return false
	for index in range(steam.getNumLobbyMembers(lobby)):
		if steam.getLobbyMemberByIndex(lobby,index)==id: return true
	return false

func _session_requested(id: int) -> void:
	if lobby_member(id): steam.acceptSessionWithUser(id)

func _lobby_update(_id: int, changed: int, _actor: int, state: int) -> void:
	if state & (2|4|8|16): departed.emit(changed)

func invite() -> void:
	if steam_ready and lobby>0: steam.activateGameOverlayInviteDialog(lobby)

func nickname(id: int) -> String:
	return steam.getFriendPersonaName(id).substr(0,32) if steam_ready and mode=="steam" else ""

func host_lan(port := 27841) -> Error:
	leave()
	peer = ENetMultiplayerPeer.new()
	var result := peer.create_server(port,3)
	if result!=OK: peer = null; return result
	mode = "lan"; hosting = true; active = true; local_id = 1; host_id = 1
	peer.peer_connected.connect(func(id): connected_ids[id] = true)
	peer.peer_disconnected.connect(func(id): connected_ids.erase(id); departed.emit(id))
	return OK

func join_lan(address: String, port := 27841) -> Error:
	leave()
	peer = ENetMultiplayerPeer.new()
	var result := peer.create_client(address,port)
	if result!=OK: peer = null; return result
	mode = "lan"; hosting = false; local_id = peer.get_unique_id(); host_id = 1
	peer.peer_connected.connect(func(id): connected_ids[id] = true)
	peer.peer_disconnected.connect(func(id): connected_ids.erase(id); departed.emit(id))
	return OK

func connected() -> bool:
	return active if mode=="steam" else peer!=null and peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED

func send_to(id: int, value: Dictionary, reliable := true) -> void:
	var raw := var_to_bytes(value)
	var bytes := raw.compress(FileAccess.COMPRESSION_GZIP)
	if bytes.size()>MAX_PACKET: return
	if mode=="steam":
		if active and lobby_member(id): steam.sendMessageToUser(id,bytes,8 if reliable else 0,0)
	elif connected() and connected_ids.has(id):
		peer.set_target_peer(id)
		peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE if reliable else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
		peer.put_packet(bytes)

func _decode(sender: int, bytes: PackedByteArray) -> void:
	if bytes.size()==0 or bytes.size()>MAX_PACKET: return
	var decoded := bytes.decompress_dynamic(MAX_PACKET,FileAccess.COMPRESSION_GZIP)
	if decoded.is_empty() or decoded.size()>MAX_PACKET: return
	var value: Variant = bytes_to_var(decoded) # Objects are never allowed from the network.
	if value is Dictionary and value.get("protocol")==PROTOCOL: packet_received.emit(sender,value)

func _process(_dt: float) -> void:
	if steam_ready: steam.run_callbacks()
	if active and mode=="steam":
		for message in steam.receiveMessagesOnChannel(0,128):
			if lobby_member(message.identity): _decode(message.identity,message.payload)
	if peer!=null:
		peer.poll()
		if peer==null: return
		active = connected()
		var count := 0
		while peer!=null and peer.get_available_packet_count()>0 and count<128:
			var sender := peer.get_packet_peer()
			_decode(sender,peer.get_packet())
			count += 1

func leave() -> void:
	if steam_ready and lobby>0:
		steam.leaveLobby(lobby)
		steam.clearRichPresence()
	if peer!=null: peer.close(); peer = null
	connected_ids.clear()
	lobby = 0; active = false

func _exit_tree() -> void:
	leave()
