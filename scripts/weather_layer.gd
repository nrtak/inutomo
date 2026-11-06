class_name WeatherLayer
extends Node2D

var location = "Home"
var clock = 0.0
var weather = ""
var rain_strength = 0.0
const INDOOR = ["Home","Moment:Home","Shop","Vet Clinic","Lighthouse Room"]
const WINDOWS = {"Home":Rect2(0.38,0.08,0.54,0.39),"Moment:Home":Rect2(0.38,0.08,0.54,0.39),"Shop":Rect2(0.53,0.15,0.39,0.34),"Vet Clinic":Rect2(0.34,0.12,0.32,0.36),"Lighthouse Room":Rect2(0.28,0.10,0.65,0.37)}

func _process(delta: float) -> void:
 if not is_visible_in_tree() or Game.paused_at>0:
  return
 weather = IslandWeather.current()
 var target = 1.0 if weather=="Light rain" else 0.0
 rain_strength = move_toward(rain_strength,target,delta*0.3)
 if not Game.reduce_motion:
  clock += delta
 queue_redraw()

func _draw() -> void:
 var background = get_parent() as TextureRect
 if not is_instance_valid(background) or background.texture==null:
  return
 var source = Vector2(background.texture.get_size())
 var factor = maxf(background.size.x/source.x,background.size.y/source.y)
 var drawn = source*factor
 var origin = (background.size-drawn)*0.5
 var area: Rect2 = WINDOWS.get(location,Rect2(0.0,0.02,1.0,0.94))
 var bounds = Rect2(origin+area.position*drawn,area.size*drawn).intersection(Rect2(Vector2.ZERO,background.size))
 if not bounds.has_area():
  return
 # Slow passing light, never a moving camera or an opaque dark overlay.
 if weather in ["Passing clouds","Light rain"] and location not in INDOOR:
  var phase = fposmod(clock/95.0,1.0) if not Game.reduce_motion else 0.5
  var alpha = sin(phase*PI)*0.035
  draw_rect(bounds,Color(0.62,0.73,0.83,alpha))
 if rain_strength<=0:
  return
 var unit = maxf(0.6,drawn.x/1280.0)
 if Game.reduce_motion:
  # A still rain indication keeps the setting legible without drifting streaks.
  for i in 10:
   var p = bounds.position+Vector2((i+0.5)/10.0,0.25+float(i%3)*0.2)*bounds.size
   draw_line(p,p+Vector2(2,7)*unit,Color(0.76,0.9,0.96,0.3*rain_strength),unit,true)
  return
 for i in 52:
  var phase = fposmod(clock*0.22+float(i)*0.618,1.0)
  var x = fposmod(float(i)*0.381+clock*0.006,1.0)
  var p = bounds.position+Vector2(x,phase)*bounds.size
  var end = p+Vector2(3,13)*unit
  if bounds.has_point(end):
   draw_line(p,end,Color(0.75,0.90,0.98,0.26*rain_strength),unit,true)
