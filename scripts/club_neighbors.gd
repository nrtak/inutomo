extends Control

var dogs: Array[Sprite2D] = []
var clock = 0.0
var friendly_pose = false
var found_toy: Sprite2D
func _ready() -> void:
	name="ClubNeighbors"
	z_index=-1
	set_meta("screen_layout_manual",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	for name in ["Momo","Pippin"]:
		var dog=Sprite2D.new()
		dog.set_meta("breed",IslandAdventure.BUDDIES[name].breed)
		dog.texture=Art.PUPPIES[dog.get_meta("breed")]
		dog.material=UI.art_cutout()
		add_child(dog)
		dogs.append(dog)
	if Game.life.surprises.found_toy:
		found_toy=Sprite2D.new()
		found_toy.texture=Goods.picture("Toy")
		found_toy.material=UI.art_cutout()
		found_toy.scale=Vector2.ONE*(35.0/found_toy.texture.get_width())
		add_child(found_toy)
	resized.connect(arrange)
	arrange.call_deferred()

func arrange() -> void:
	var portrait=size.y>size.x
	if is_instance_valid(found_toy): found_toy.position=Vector2(size.x*.55,size.y*(.66 if portrait else .69))
	for i in dogs.size():
		var dog=dogs[i]
		var height=150.0 if portrait else 130.0
		dog.scale=Vector2.ONE*(height/dog.texture.get_height())
		dog.offset=Vector2(0,-dog.texture.get_height()*.5)
		dog.position=Vector2(size.x*([.14,.68][i] if portrait else [.40,.63][i]),size.y*(.64 if portrait else .66))

func _process(delta: float) -> void:
	if Game.paused_at>0 or Game.reduce_motion or not Game.is_processing(): return
	clock+=delta
	if clock>=12:
		clock=0
		friendly_pose=not friendly_pose
		for i in dogs.size():
			var dog=dogs[i]
			dog.texture=Art.expression_texture(dog.get_meta("breed"),"Tilt") if friendly_pose else Art.PUPPIES[dog.get_meta("breed")]
		arrange()
