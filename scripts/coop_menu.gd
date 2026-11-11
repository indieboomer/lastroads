extends Control

var game: Node
var ui: CanvasLayer
var status: Label
var party: Label
var address: LineEdit
var port: SpinBox
var host_steam_button: Button
var join_steam_button: Button
var preview: Node3D

func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.size = Vector2(1280,720)
	background.color = Color("102124")
	add_child(background)
	ui.label("TAKE THE ROAD TOGETHER",Vector2(65,38),34,self,true)
	ui.label("Up to four travellers / shared world, personal characters",Vector2(67,91),20,self)
	status = ui.label("",Vector2(67,143),19,self)
	status.size = Vector2(1135,85)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host_steam_button = ui.button("Host / Steam friends",Vector2(65,244),Vector2(350,54),self,func(): choose_character("host_steam"))
	join_steam_button = ui.button("Accept Steam invitation",Vector2(440,244),Vector2(350,54),self,func(): choose_character("join_steam"))
	ui.button("Invite friends",Vector2(815,244),Vector2(350,54),self,func(): game.coop.transport.invite())
	ui.label("Local network / development testing",Vector2(67,333),22,self,true)
	address = LineEdit.new()
	address.position = Vector2(65,380)
	address.size = Vector2(350,44)
	address.placeholder_text = "Host address"
	address.text = "127.0.0.1"
	add_child(address)
	port = SpinBox.new()
	port.position = Vector2(440,380)
	port.size = Vector2(170,44)
	port.min_value = 1024; port.max_value = 65535; port.value = 27841
	add_child(port)
	ui.button("Host on LAN",Vector2(65,444),Vector2(350,50),self,func(): choose_character("host_lan"))
	ui.button("Join host",Vector2(440,444),Vector2(350,50),self,func(): choose_character("join_lan"))
	party = ui.label("",Vector2(67,525),19,self)
	party.size = Vector2(1120,80)
	ui.button("Back",Vector2(65,635),Vector2(220,48),self,close)
	ui.button("Leave co-op",Vector2(815,635),Vector2(350,48),self,func(): game.coop.disconnect_session())
	game.coop.changed.connect(refresh)
	hide()

func open(mode := "") -> void:
	game.set_modal("coop")
	game.ui.title.hide()
	show()
	refresh()
	if mode=="join_steam": status.text = "Steam invitation received. Accept it, then choose a character and recognition color."

func refresh() -> void:
	status.text = game.coop.status
	if not game.coop.transport.steam_ready and not game.coop.active: status.text += "\n"+game.coop.transport.last_error
	host_steam_button.disabled = not game.coop.transport.steam_ready or game.coop.active
	join_steam_button.disabled = not game.coop.transport.steam_ready or game.coop.pending_lobby<=0 or game.coop.active
	var members: Array[String] = []
	for record in game.coop.roster.values():
		members.append(record.nickname+" / "+record.profile.origin_id.capitalize()+" "+record.profile.profession_id.capitalize())
	party.text = "Party (%d/4):\n" % members.size()+"    |    ".join(members)

func choose_character(mode: String) -> void:
	if game.coop.active:
		status.text = "Leave the current party before starting another session."
		return
	game.coop.pending_mode = mode
	game.coop.pending_address = address.text.strip_edges()
	game.coop.pending_port = int(port.value)
	game.ui.open_creator()
	game.ui.creator.coop_mode = mode
	game.ui.creator.recognition_color.show()
	game.ui.creator.color_label.show()
	game.ui.creator.refresh()

func close() -> void:
	hide()
	game.set_modal("")
	if not game.started: game.ui.title.show()
