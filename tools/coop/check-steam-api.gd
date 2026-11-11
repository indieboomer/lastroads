extends SceneTree

func _initialize() -> void:
	assert(Engine.has_singleton("Steam"),"Launch this check using the installed GodotSteam runtime")
	var steam: Object = Engine.get_singleton("Steam")
	for method in ["steamInitEx","run_callbacks","getSteamID","createLobby","joinLobby","leaveLobby","getLobbyOwner","getLobbyData","setLobbyData","setLobbyMemberLimit","setLobbyJoinable","getNumLobbyMembers","getLobbyMemberByIndex","activateGameOverlayInviteDialog","getFriendPersonaName","setRichPresence","clearRichPresence","acceptSessionWithUser","sendMessageToUser","receiveMessagesOnChannel","initRelayNetworkAccess"]:
		assert(steam.has_method(method),method)
	for event in ["lobby_created","lobby_joined","join_requested","lobby_chat_update","network_messages_session_request"]:
		assert(steam.has_signal(event),event)
	print("STEAM API PASS: installed Windows GodotSteam 4.24 exposes every lobby/invite/identity/relay/message API and callback used by co-op. Live two-account testing remains separate.")
	quit()
