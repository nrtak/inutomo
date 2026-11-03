class_name ResidentPortrait
extends TextureRect

var frames: Array[Texture2D] = []
var frame_index = 0
var elapsed = 0.0
var next_change = 11.0
var greeting_pending = false
var hit_source: Texture2D
var hit_image: Image

func configure(source: Texture2D) -> void:
 frames = Art.resident_frames(Art.daily_portrait(source),true)
 # Nora opens with a hello, then joins the quieter conversation cycle.
 greeting_pending = frames.size() == 3
 frame_index = 2 if greeting_pending else 0
 texture = frames[frame_index]
 material = UI.art_cutout()
 expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 stretch_mode = TextureRect.STRETCH_SCALE
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 elapsed = 0
 next_change = 3.5 if greeting_pending else randf_range(10.0,17.0)

func _process(delta: float) -> void:
 var game = get_node_or_null("/root/Game")
 if not is_visible_in_tree() or (is_instance_valid(game) and (game.paused_at > 0 or game.reduce_motion)) or frames.size() < 2:
  return
 elapsed += delta
 if elapsed >= next_change:
  elapsed = 0
  frame_index = 0 if greeting_pending else 1-frame_index
  greeting_pending = false
  next_change = randf_range(3.0,4.5) if frame_index == 1 else randf_range(10.0,17.0)
  show_frame(frame_index)

func show_frame(index: int) -> void:
 if index < 0 or index >= frames.size():
  return
 # Draw one clean pose, avoiding doubled eyes and arms from blended cutouts.
 frame_index = index
 texture = frames[index]

func _has_point(point: Vector2) -> bool:
 # Transparent padding must not steal a tap intended for the dog or scenery.
 if texture == null or size.x <= 0 or size.y <= 0 or not Rect2(Vector2.ZERO,size).has_point(point):
  return false
 var source = texture
 var pixel = point/size*texture.get_size()
 if texture is AtlasTexture:
  var frame = texture as AtlasTexture
  pixel -= frame.margin.position
  if not Rect2(Vector2.ZERO,frame.region.size).has_point(pixel):
   return false
  pixel += frame.region.position
  source = frame.atlas
 if source != hit_source:
  hit_source = source
  hit_image = source.get_image()
 if hit_image == null or not Rect2i(Vector2i.ZERO,hit_image.get_size()).has_point(Vector2i(pixel)):
  return false
 return hit_image.get_pixelv(Vector2i(pixel)).a >= 0.5
