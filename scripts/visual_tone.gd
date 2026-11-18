extends CanvasLayer

var finish: ColorRect
var photo_material: ShaderMaterial

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	finish = ColorRect.new()
	finish.name = "SoftColorFinish"
	finish.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finish.focus_mode = Control.FOCUS_NONE
	finish.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tone = ShaderMaterial.new()
	tone.shader = preload("res://scripts/visual_tone.gdshader")
	finish.material = tone
	add_child(finish)

func prepare_photo(picture: CanvasItem, filename: String) -> void:
	if not filename.begins_with("puppy_photo_soft1_"):
		return
	if photo_material == null:
		photo_material = ShaderMaterial.new()
		photo_material.shader = preload("res://scripts/photo_tone_restore.gdshader")
	picture.material = photo_material
