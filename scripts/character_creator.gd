extends Control

const Data = preload("res://scripts/character_data.gd")
var game: Node
var ui: CanvasLayer
var name_entry: LineEdit
var age: SpinBox
var origin: OptionButton
var profession: OptionButton
var gender: OptionButton
var interest: OptionButton
var heritage_text: RichTextLabel
var profession_text: RichTextLabel
var portrait: TextureRect
var error: Label
var recognition_color: OptionButton
var color_label: Label
var coop_mode := ""

func build() -> void:
	size = Vector2(1280,720)
	var background := ColorRect.new()
	background.color = Color("102124")
	background.size = size
	add_child(background)
	ui.label("WHO TAKES THE ROAD?",Vector2(65,30),32,self,true)
	ui.label("Bells of the Hollow / a traveller's beginning",Vector2(67,78),17,self)
	portrait = TextureRect.new()
	portrait.position = Vector2(55,125)
	portrait.size = Vector2(365,415)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(portrait)
	ui.label("An adult traveller, with a life before this road.\nPortraits suggest a look, never a personality.\nAll origins can follow every profession.",Vector2(65,552),16,self)
	ui.label("Name",Vector2(470,116),16,self)
	name_entry = LineEdit.new()
	name_entry.position = Vector2(470,143)
	name_entry.size = Vector2(415,40)
	name_entry.max_length = 32
	name_entry.text = "Traveller"
	add_child(name_entry)
	ui.label("Age / 18+",Vector2(925,116),16,self)
	age = SpinBox.new()
	age.position = Vector2(925,143)
	age.size = Vector2(275,40)
	age.min_value = 18
	age.max_value = 80
	age.value = 30
	add_child(age)
	origin = option("Origin",Vector2(470,201),Data.ORIGINS.map(func(e): return e.name))
	profession = option("Profession",Vector2(925,201),Data.PROFESSIONS.map(func(e): return e.name),275)
	heritage_text = prose(Vector2(470,275),Vector2(415,100))
	profession_text = prose(Vector2(925,275),Vector2(275,210))
	gender = option("Gender",Vector2(470,386),["Man","Woman"],415)
	interest = option("Optional romance interest",Vector2(470,476),["Adults of any gender","Men","Women","No invitations"],415)
	ui.label("Your origin sets your stature and view of the world.\nChoose a recognition color when joining co-op.\nWASD / mouse / E interact / C and V profession abilities.",Vector2(470,566),16,self)
	color_label = ui.label("Co-op recognition color",Vector2(925,500),16,self)
	recognition_color = OptionButton.new()
	recognition_color.position = Vector2(925,528)
	recognition_color.size = Vector2(275,40)
	for color in ["Crimson","Blue","Gold","Green","Violet","Orange","Teal","Rose"]: recognition_color.add_item(color)
	add_child(recognition_color)
	recognition_color.item_selected.connect(func(_index): refresh())
	recognition_color.hide()
	color_label.hide()
	error = ui.label("",Vector2(470,637),15,self)
	error.modulate = Color("f0ab8e")
	ui.button("Back",Vector2(65,647),Vector2(180,45),self,func(): game.set_modal(""); game.ui.title.show())
	ui.button("Take the road",Vector2(955,638),Vector2(245,52),self,begin)
	for control in [origin,profession,gender]:
		control.item_selected.connect(func(_index): refresh())
	refresh()
	hide()

func option(caption: String, at: Vector2, values: Array, width := 415) -> OptionButton:
	ui.label(caption,at,16,self)
	var field := OptionButton.new()
	field.position = at+Vector2(0,28)
	field.size = Vector2(width,40)
	for value in values: field.add_item(value)
	add_child(field)
	return field

func prose(at: Vector2, bounds: Vector2) -> RichTextLabel:
	var text := RichTextLabel.new()
	text.position = at
	text.size = bounds
	text.add_theme_font_size_override("normal_font_size",16)
	add_child(text)
	return text

func refresh() -> void:
	portrait.material = null
	heritage_text.text = Data.ORIGINS[origin.selected].description+"\nName ideas: "+Data.ORIGINS[origin.selected].names
	profession_text.text = Data.PROFESSIONS[profession.selected].description
	var path := "res://assets/old-masters/traveller-portraits.png"
	if ResourceLoader.exists(path):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(path)
		var w := atlas.atlas.get_width()/6
		var h := atlas.atlas.get_height()/2
		atlas.region = Rect2(origin.selected*w,gender.selected*h,w,h)
		portrait.texture = atlas
		ui.style_graphic(portrait)
	var body_path: String = Data.body_path(profile())
	if (not coop_mode.is_empty() or not ResourceLoader.exists(path)) and ResourceLoader.exists(body_path):
		var body: Texture2D = load(body_path)
		var frame := AtlasTexture.new()
		frame.atlas = body
		frame.region = Rect2(0,0,body.get_width()/4.0,body.get_height()/6.0)
		portrait.texture = frame
		var dye := ShaderMaterial.new()
		dye.shader = preload("res://shaders/coop_preview.gdshader")
		dye.set_shader_parameter("recognition_color",Color(game.coop.COLORS[recognition_color.selected]))
		portrait.material = dye

func profile() -> Dictionary:
	var o: Dictionary = Data.ORIGINS[origin.selected]
	return {"name":name_entry.text.strip_edges(),"age":int(age.value),"origin_id":o.id,"species_id":o.species,"heritage_id":o.heritage,"profession_id":Data.PROFESSIONS[profession.selected].id,"gender":Data.GENDERS[gender.selected],"presentation":gender.selected,"romance_interest":Data.INTERESTS[interest.selected]}

func begin() -> void:
	var selected := profile()
	if not Data.valid(selected):
		error.text = "Choose a name (1–32 characters) and an adult age (18–80)."
		return
	if not coop_mode.is_empty():
		var result: Error = game.coop.prepare(coop_mode,selected,game.coop.COLORS[recognition_color.selected],game.coop.pending_address,game.coop.pending_port)
		if result!=OK: error.text = game.coop.status
		return
	game.start_new(selected)
