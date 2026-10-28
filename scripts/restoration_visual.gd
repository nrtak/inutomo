extends Node2D

func _ready() -> void:
 Game.changed.connect(queue_redraw)

func state() -> Dictionary:
 return {"crate":Game.life.story.get("repair_supplies",false) and not Game.life.story.get("path_repaired",false), "path":Game.life.story.get("path_repaired",false), "display":Game.life.story.get("lens_polished",false), "beacon":Game.life.story.get("beacon_checked",false)}

func _draw() -> void:
 var progress = state()
 # Small independent scenery layers keep the background replaceable.
 for i in 4:
  var center = Vector2(292 + i * 28, 469 + i * 4)
  var shape = PackedVector2Array([center+Vector2(-17,-7),center+Vector2(8,-10),center+Vector2(20,1),center+Vector2(5,9),center+Vector2(-19,5)])
  draw_colored_polygon(shape,Color("e9cf9e") if progress.path else Color("a89579"))
  draw_polyline(shape,Color("bda071"),1.5)
  if not progress.path:
   draw_line(center+Vector2(-8,-5),center+Vector2(3,4),Color("766b5a"),2)
 if progress.crate:
  draw_style_box(UI.style(Color("be8a56"),3),Rect2(402,419,53,36))
  draw_line(Vector2(405,427),Vector2(452,427),Color("efd5a0"),4)
  draw_line(Vector2(405,448),Vector2(452,448),Color("efd5a0"),4)
 if progress.display:
  draw_line(Vector2(348,423),Vector2(345,438),Color("946849"),4)
  draw_line(Vector2(374,423),Vector2(377,438),Color("946849"),4)
  draw_style_box(UI.style(Color("946849"),5),Rect2(341,375,41,52))
  draw_style_box(UI.style(Color("fff0cf"),3),Rect2(346,380,31,37))
  draw_colored_polygon(PackedVector2Array([Vector2(354,405),Vector2(350,394),Vector2(364,385),Vector2(373,399),Vector2(366,408)]),Color("69c7bc"))
  draw_line(Vector2(356,395),Vector2(365,390),Color("e9ffff"),2)
 if progress.beacon:
  draw_circle(Vector2(628,91),7,Color(1,0.91,0.61,0.35))
  draw_circle(Vector2(628,91),3,Color("fff4c7"))
