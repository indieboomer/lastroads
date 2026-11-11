extends Control

var game: Node

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var c = game.combat
	if c.gesture=="staff": return
	var colour: Color = c.COLOURS.get(c.gesture,Color("accbe0"))
	var elapsed: float = c.visual_duration-c.visual_clock
	var phase := minf(elapsed/0.06,1.0)*minf(c.visual_clock/0.25,1.0)
	colour.a = phase*0.95
	if c.profession()=="cleric":
		var at := Vector2(245,430)-Vector2(0,phase*90)
		draw_line(at-Vector2(0,46),at+Vector2(0,52),colour,6)
		draw_line(at-Vector2(30,12),at+Vector2(30,-12),colour,6)
		draw_arc(at,62,0,TAU,48,colour,3)
	else:
		var at := Vector2(280,500)-Vector2(0,phase*45)
		draw_arc(at,48+phase*16,0,TAU,48,colour,4)
		draw_arc(at,72,0,TAU,48,colour,2)
		for i in range(3):
			var angle := i*TAU/3.0
			draw_line(at+Vector2.from_angle(angle)*38,at+Vector2.from_angle(angle+TAU/3.0)*38,colour,4)
