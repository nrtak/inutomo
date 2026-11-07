extends VBoxContainer

var host: Control
var habitat: Habitat
var clue: CommandHint
var progress: Label
var feedback: Label
var spots: Array[Button] = []
var pending = -1
var day = ""
var shown_route = -1

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 habitat = host.habitat
 habitat.puppy.controlled = true
 habitat.puppy.position = Vector2(500,560)
 habitat.puppy.target = habitat.puppy.position
 habitat.puppy.wake_briefly()
 IslandAdventure.begin_scent(Game)
 day = IslandLife.today()
 var space = Control.new()
 space.size_flags_vertical = Control.SIZE_EXPAND_FILL
 space.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(space)
 var panel = UI.card()
 panel.custom_minimum_size.x = 330
 panel.size_flags_horizontal = Control.SIZE_SHRINK_END
 add_child(panel)
 var content = UI.column(10)
 content.custom_minimum_size.x = 290
 panel.add_child(content)
 progress = UI.label("",25,UI.TEAL)
 content.add_child(progress)
 clue = UI.hint_label("",22)
 content.add_child(clue)
 feedback = UI.label("Choose a scent spot on the path.",21)
 content.add_child(feedback)
 content.add_child(UI.button("Back to Park",host.request_page.bind("Park"),Color("c8eddd")))
 for i in 3:
  var spec: Dictionary = IslandAdventure.TRAILS[0][i]
  var button = UI.button(["Tree","Path","Bench"][i],choose_spot.bind(i),Color("fff0bd"))
  button.icon = load("res://assets/ui/"+spec.icon+".svg")
  button.expand_icon = true
  button.add_theme_constant_override("icon_max_width",24)
  button.add_theme_font_size_override("font_size",19)
  button.custom_minimum_size = Vector2(95,50)
  button.position = spec.point-Vector2(47,10)
  habitat.world.add_child(button)
  spots.append(button)
 update_state()

func choose_spot(choice: int) -> void:
 if pending>=0 or not Game.can_explore() or Game.cooldowns.get("Scent",0)>0 or Game.life.adventure.scent.step>=3 or Game.life.adventure.scent.day!=IslandLife.today():
  return
 pending = choice
 habitat.puppy.target = IslandAdventure.TRAILS[0][choice].point
 feedback.text = "Following the scent..."
 update_state()

func _process(_delta: float) -> void:
 if Game.paused_at>0:
  return
 if day != IslandLife.today() or (Game.can_explore() and Game.life.adventure.scent.day < IslandLife.today()):
  pending = -1
  habitat.puppy.target = habitat.puppy.position
  day = IslandLife.today()
  if IslandAdventure.begin_scent(Game):
   feedback.text = "A fresh trail! Choose a scent spot."
 if pending>=0:
  if not Game.can_explore():
   pending = -1
   habitat.puppy.target = habitat.puppy.position
   feedback.text = "A little rest or recovery first. Your trail is saved."
  elif habitat.puppy.position.distance_to(habitat.puppy.target)<2:
   var result = IslandAdventure.sniff(Game,pending)
   feedback.text = result.text
   pending = -1
 update_state()

func update_state() -> void:
 var state: Dictionary = Game.life.adventure.scent
 var current_day = state.day==IslandLife.today()
 var done = state.step>=3 and current_day
 progress.text = "Trail complete!" if done else "Scent trail: %d of 3" % state.step
 clue.text = "A lovely discovery together. Return tomorrow for a fresh trail." if done else IslandAdventure.scent_stop(Game).clue
 if not done and IslandLife.personality(Game)=="Curious":
  clue.text = "That curious nose pauses. " + clue.text
 if not current_day:
  clue.text = "Your daily trail is saved. Come back for a fresh trail another day."
 if shown_route != state.route:
  shown_route = state.route
  for i in spots.size():
   spots[i].icon = load("res://assets/ui/"+IslandAdventure.TRAILS[state.route][i].icon+".svg")
 var blocked = Game.activity_block_reason()
 if not blocked.is_empty():
  clue.text = blocked+". Your discoveries are saved."
 for i in spots.size():
  spots[i].visible = current_day and not done and i>=state.step
  spots[i].disabled = not current_day or pending>=0 or not blocked.is_empty() or Game.cooldowns.get("Scent",0)>0
