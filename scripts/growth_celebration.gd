extends Control

signal finished
var words: Label
var portrait: TextureRect
var next_button: Button
var sparkles: Control
var dressed: bool

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop=TextureRect.new()
	backdrop.texture=Art.HOME
	Daylight.apply_to(backdrop,"Home")
	backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var content=UI.conversation_body(self,Art.NORA,"Nora")
	words=UI.label("",25)
	content.add_child(words)
	portrait=TextureRect.new()
	portrait.custom_minimum_size.y=170
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(portrait)
	var accessory: String=Game.life.accessory
	dressed=Game.items.get(accessory,0)>0 and Goods.ITEMS.get(accessory,{}).has("color")
	portrait.material=UI.art_cutout()
	if dressed:
		var ink=ShaderMaterial.new()
		ink.shader=preload("res://scripts/dog_style.gdshader")
		ink.set_shader_parameter("recolor",true)
		ink.set_shader_parameter("bandana",Goods.ITEMS[accessory].color)
		portrait.material=ink
	sparkles=Control.new()
	sparkles.mouse_filter=Control.MOUSE_FILTER_IGNORE
	sparkles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.add_child(sparkles)
	sparkles.draw.connect(draw_sparkles)
	next_button=UI.button("Watch the reveal",advance,Color("bdeab0"))
	next_button.custom_minimum_size=Vector2(220,64)
	next_button.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	content.add_child(next_button)
	refresh()
	next_button.grab_focus()

func refresh() -> void:
	var revealed=Game.pending_stage==Game.growth_stage()
	var pictures=Art.DRESSED_PUPPIES if dressed else Art.PUPPIES
	portrait.texture=pictures[Game.breed]
	sparkles.visible=revealed
	if not revealed:
		words.text="Look at %s! I think today is a big day. Shall we find out together?" % Game.puppy_name
		return
	if Game.pending_stage=="Adult":
		words.text="%s is all grown up! A %s! I remember when those paws were hardly bigger than my thumb." % [Game.puppy_name,Game.breed]
		if Game.life.picture_pages.has("growth"):
			var strip=preload("res://scripts/memory_strip.gd").new()
			portrait.get_parent().add_child(strip)
			portrait.get_parent().move_child(strip,portrait.get_index())
			strip.illustrate("growth",Game.life.picture_pages.growth)
			portrait.hide()
			sparkles.reparent(strip.last_scene,false)
			sparkles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			words.text+=" I saved this page in your Journal."
	elif Game.pending_stage=="Young puppy":
		words.text="Look at those longer legs! %s is a young puppy now. Come here, little one!" % Game.puppy_name
	else:
		words.text="Did you see that confident stance? %s has reached the growing puppy stage. I'm so proud!" % Game.puppy_name
	next_button.text="Celebrate together"

func advance() -> void:
	if Game.pending_stage==Game.growth_stage():
		finished.emit()
		return
	Game.reveal_growth()
	refresh()
	Sound.play_effect("growth",-17)
	if not Game.reduce_motion:
		var illustration=portrait if portrait.visible else sparkles.get_parent()
		illustration.modulate.a=.25
		create_tween().tween_property(illustration,"modulate:a",1.0,.45)

func draw_sparkles() -> void:
	for point in [Vector2(.15,.34),Vector2(.23,.68),Vector2(.79,.23),Vector2(.85,.66)]:
		var center=point*sparkles.size
		var radius=12 if point.y<.5 else 8
		var star=PackedVector2Array()
		for i in 8:
			star.append(center+Vector2.UP.rotated(i*PI/4)*(radius if i%2==0 else radius*.3))
		sparkles.draw_colored_polygon(star,Color("efae48"))
