extends Node2D

var location = "Home"

func _ready() -> void:
	if Game.life.connections.mystery!=5: return
	if location=="Puppy Club":
		var star = Sprite2D.new()
		star.texture = preload("res://assets/goods/welcome_star.svg")
		star.material = UI.art_cutout()
		star.scale = Vector2.ONE*(48.0/star.texture.get_width())
		star.position = Vector2(210,175)
		add_child(star)
	elif location=="Home":
		position.x = -150
		var frame = Sprite2D.new()
		frame.texture = Art.PUPPIES[Game.life.connections.memory_breed]
		frame.material = UI.art_cutout()
		frame.scale = Vector2.ONE*minf(57.0/frame.texture.get_width(),61.0/frame.texture.get_height())
		frame.position = Vector2(1050,393)
		add_child(frame)
		var star = Sprite2D.new()
		star.texture = preload("res://assets/goods/welcome_star.svg")
		star.material = UI.art_cutout()
		star.scale = Vector2.ONE*(20.0/star.texture.get_width())
		star.position = Vector2(1077,416)
		add_child(star)
	queue_redraw()

func _draw() -> void:
	if Game.life.connections.mystery!=5: return
	if location=="Home":
		draw_polyline(PackedVector2Array([Vector2(1038,353),Vector2(1050,337),Vector2(1062,353)]),Color("8e6043"),2,true)
		draw_style_box(UI.style(Color("c59062"),5),Rect2(1012,353,76,83))
		draw_rect(Rect2(1019,360,62,69),Color("fff6e5"))
	elif location=="Puppy Club":
		draw_line(Vector2(210,145),Vector2(210,155),Color("b98a68"),3,true)
