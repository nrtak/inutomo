extends HBoxContainer

var last_scene: TextureRect

# Each panel is composed from island scenery and the dog recorded at the milestone.
func illustrate(kind: String, page: Dictionary) -> void:
	add_theme_constant_override("separation",8)
	var accessory: String=page.get("accessory","")
	var picture=Art.PUPPIES[page.breed] if accessory.is_empty() else Art.DRESSED_PUPPIES[page.breed]
	match kind:
		"growth":
			panel(Art.HOME,Art.PUPPIES.Puppy,"First day home",true)
			panel(Art.HOME,picture,page.breed,false,MomentArt.resident("Nora"),accessory)
		"buddy":
			panel(Art.BACKGROUNDS["Puppy Club"],Art.PUPPIES[IslandAdventure.BUDDIES[page.buddy].breed],"Hello, "+page.buddy,true)
			panel(Art.PARK,picture,"Best friends",false,Art.PUPPIES[IslandAdventure.BUDDIES[page.buddy].breed],accessory)
		"beacon":
			panel(Art.BACKGROUNDS["Keeper’s Cottage"],MomentArt.resident("Ren"),"Ren checks the lens",false)
			panel(MomentArt.background("Lighthouse"),picture,"A light for the harbor",true,null,accessory)

func panel(scenery: Texture2D, dog: Texture2D, caption: String, small: bool, friend: Texture2D=null, accessory: String="") -> void:
	var column=UI.column(3)
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_child(column)
	var frame=PanelContainer.new()
	var ink=UI.style(UI.INK,3)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: ink.set_content_margin(side,2)
	frame.add_theme_stylebox_override("panel",ink)
	column.add_child(frame)
	var scene=TextureRect.new()
	scene.texture=scenery
	scene.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	scene.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scene.custom_minimum_size.y=150
	scene.clip_contents=true
	scene.mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame.add_child(scene)
	last_scene=scene
	if friend: figure(scene,friend,.04,.51,.19)
	figure(scene,dog,.49 if friend else .12,.95 if friend else .88,.42 if small else .13,accessory)
	var line=UI.label(caption,19)
	line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(line)

func figure(scene: Control, texture: Texture2D, left: float, right: float, top: float, accessory: String="") -> void:
	var image=TextureRect.new()
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.texture=texture
	image.material=UI.art_cutout()
	if not accessory.is_empty():
		var ink=ShaderMaterial.new()
		ink.shader=preload("res://scripts/dog_style.gdshader")
		ink.set_shader_parameter("recolor",true)
		ink.set_shader_parameter("bandana",Goods.ITEMS[accessory].color)
		image.material=ink
	scene.add_child(image)
	image.anchor_left=left
	image.anchor_right=right
	image.anchor_top=top
	image.anchor_bottom=.96
