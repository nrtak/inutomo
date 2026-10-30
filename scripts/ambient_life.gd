class_name AmbientLife
extends Node2D

var location = "Island"
var clock = 0.0
const LANES = {
 "Island":[Vector4(0.015,0.20,0.095,0.20),Vector4(0.935,0.40,0.99,0.40)],
 "Home":[Vector4(0.53,0.39,0.77,0.39)],
 "Park":[Vector4(0.50,0.40,0.62,0.40)],
 "Beach":[Vector4(0.65,0.39,0.85,0.39)],
 "Beach Arrival":[Vector4(0.31,0.43,0.76,0.43)],
 "Shop":[Vector4(0.57,0.40,0.78,0.40)],
 "Harbor":[Vector4(0.51,0.43,0.65,0.43)],
 "Keeper’s Cottage":[Vector4(0.59,0.43,0.75,0.43)],
 "Lighthouse":[Vector4(0.40,0.47,0.67,0.47)]
}
func _process(delta: float) -> void:
 if Game.paused_at > 0 or not is_visible_in_tree():
  return
 clock += delta
 queue_redraw()

func _draw() -> void:
 var background = get_parent() as TextureRect
 if not is_instance_valid(background) or background.texture == null:
  return
 var texture_size = Vector2(background.texture.get_size())
 var factor = maxf(background.size.x/texture_size.x,background.size.y/texture_size.y)
 var drawn = texture_size*factor
 var origin = (background.size-drawn)*0.5
 var index = 0
 for lane in LANES.get(location,[]):
  var phase = fposmod(clock/48.0+index*0.43,1.0)
  var point = origin+Vector2(lerpf(lane.x,lane.z,phase),lerpf(lane.y,lane.w,phase))*drawn
  var alpha = smoothstep(0,0.08,phase)*(1-smoothstep(0.92,1,phase))*0.8
  var unit = maxf(0.6,drawn.x/1600.0)
  var bob = sin(clock*1.7+index)*unit
  point.y += bob
  draw_line(point+Vector2(-17,3)*unit,point+Vector2(5,3)*unit,Color(0.9,1,1,alpha*0.5),unit)
  draw_colored_polygon(PackedVector2Array([point+Vector2(-8,0)*unit,point+Vector2(8,0)*unit,point+Vector2(5,3)*unit,point+Vector2(-5,3)*unit]),Color(0.48,0.35,0.22,alpha))
  draw_colored_polygon(PackedVector2Array([point+Vector2(0,-17)*unit,point+Vector2(0,-2)*unit,point+Vector2(-7,-2)*unit]),Color(1,0.98,0.88,alpha))
  draw_colored_polygon(PackedVector2Array([point+Vector2(2,-13)*unit,point+Vector2(2,-2)*unit,point+Vector2(8,-2)*unit]),Color(0.94,0.97,1,alpha))
  index += 1
