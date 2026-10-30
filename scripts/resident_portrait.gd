class_name ResidentPortrait
extends TextureRect

var frames: Array[Texture2D] = []
var frame_index = 0
var elapsed = 0.0
var next_change = 11.0
var incoming: TextureRect
var transition: Tween

func configure(source: Texture2D) -> void:
 frames = Art.resident_frames(Art.daily_portrait(source))
 texture = frames[0]
 expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 stretch_mode = TextureRect.STRETCH_SCALE
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 next_change = randf_range(10.0,17.0)

func _process(delta: float) -> void:
 var game = get_node_or_null("/root/Game")
 if is_instance_valid(game) and game.reduce_motion and transition != null and transition.is_valid():
  transition.kill()
  if is_instance_valid(incoming):
   incoming.visible = false
  frame_index = maxi(0,frames.find(texture))
  elapsed = 0
  next_change = randf_range(10.0,17.0)
 if not is_visible_in_tree() or (is_instance_valid(game) and (game.paused_at > 0 or game.reduce_motion)) or frames.size() < 2:
  return
 elapsed += delta
 if elapsed >= next_change:
  elapsed = 0
  frame_index = 1-frame_index
  next_change = randf_range(3.0,4.5) if frame_index == 1 else randf_range(10.0,17.0)
  show_frame(frame_index)

func show_frame(index: int) -> void:
 if transition != null and transition.is_valid():
  transition.kill()
 if not is_instance_valid(incoming):
  incoming = TextureRect.new()
  incoming.mouse_filter = Control.MOUSE_FILTER_IGNORE
  incoming.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  incoming.stretch_mode = TextureRect.STRETCH_SCALE
  incoming.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  add_child(incoming)
 incoming.texture = frames[index]
 incoming.modulate.a = 0
 incoming.visible = true
 transition = create_tween()
 transition.tween_property(incoming,"modulate:a",1.0,0.16)
 transition.tween_callback(func():
  texture = frames[index]
  incoming.visible = false
 )
