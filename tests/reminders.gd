extends SceneTree
var failures = 0

class FakeNative extends RefCounted:
 var calls: Array = []
 var requests = 0
 var answer: Dictionary = {}
 func configure(enabled: bool,dog_name: String):
  calls.append({"enabled":enabled,"name":dog_name})
 func request_permission():
  requests += 1
 func get_result() -> Dictionary:
  var result = answer.duplicate()
  answer.clear()
  return result

func _initialize():
 call_deferred("run")
func check(value: bool,message: String):
 if not value:
  push_error(message)
  failures += 1
func run():
 var game = root.get_node("Game")
 var reminders = root.get_node("Reminders")
 game.set_process(false)
 reminders.set_process(false)
 game.storage_path = "user://reminder_test.json"
 game.intro_seen = true
 game.name_chosen = true
 game.pending_stage = ""
 game.visit_reminder_enabled = false
 var fake = FakeNative.new()
 reminders.native = fake
 reminders.sync_preference()
 check(not fake.calls.back().enabled,"The reminder starts off")
 check(fake.requests == 0,"Opening the game never prompts for notification permission")
 game.puppy_name = "Sora"
 reminders.set_enabled(true)
 check(reminders.pending and not game.visit_reminder_enabled,"Permission is required before opting in")
 reminders.set_enabled(true)
 check(fake.requests == 1,"Repeated taps cannot open multiple permission requests")
 fake.answer = {"ready":true,"granted":true,"error":false}
 reminders._process(0)
 check(game.visit_reminder_enabled and not reminders.pending,"Permission enables the single reminder")
 check(fake.calls.back().enabled and fake.calls.back().name == "Sora","The native reminder receives the player's actual dog name")
 game.visit_reminder_enabled = false
 game.load_game()
 check(game.visit_reminder_enabled,"The choice survives save and load")
 game.puppy_name = "むぎ"
 check(game.save_game(),"A renamed dog saves")
 check(fake.calls.back().name == "むぎ","Names including Japanese characters reach the reminder")
 var saved = game.read_data(game.storage_path)
 saved.erase("visit_reminder_enabled")
 check(game.valid_save(saved),"Older saves remain compatible and default to no reminders")
 saved.visit_reminder_enabled = "yes"
 check(not game.valid_save(saved),"An invalid reminder preference is rejected")
 reminders.set_enabled(false)
 check(not game.visit_reminder_enabled and not fake.calls.back().enabled,"Opting out immediately cancels the reminder")
 reminders.set_enabled(true)
 reminders.set_enabled(false)
 fake.answer = {"ready":true,"granted":true,"error":false}
 reminders._process(0)
 check(not game.visit_reminder_enabled and not fake.calls.back().enabled,"A late permission callback cannot undo an opt-out")
 reminders.set_enabled(true)
 fake.answer = {"ready":true,"granted":false,"error":false}
 reminders._process(0)
 check(not game.visit_reminder_enabled and "iPhone Settings" in reminders.status,"Denied permission stays off and explains how to enable it")
 reminders.set_enabled(true)
 fake.answer = {"ready":true,"granted":false,"error":true}
 reminders._process(0)
 check(not game.visit_reminder_enabled and not reminders.status.is_empty(),"A permission error leaves reminders off")
 var good_path: String = game.storage_path
 game.storage_path = "user://missing_reminder_folder/save.json"
 reminders.set_enabled(true)
 fake.answer = {"ready":true,"granted":true,"error":false}
 reminders._process(0)
 check(not game.visit_reminder_enabled and not fake.calls.back().enabled,"A failed save cannot silently opt the player in")
 game.storage_path = good_path
 game.save_error = ""
 reminders.status = ""
 UI.safe_override = {"left":105,"right":105,"top":20,"bottom":25}
 for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
  var view = SubViewport.new()
  view.size = dimensions
  root.add_child(view)
  var menu = load("res://scenes/start_menu.tscn").instantiate()
  view.add_child(menu)
  menu.show_sound_settings()
  await process_frame
  await process_frame
  var controls = menu.settings_overlay.find_children("VisitReminderToggle","CheckButton",true,false)
  check(controls.size() == 1,"Settings has exactly one reminder switch")
  if controls.size() == 1:
   check(not controls[0].button_pressed,"The optional reminder is not preselected")
  var panels = menu.settings_overlay.find_children("*","PanelContainer",true,false)
  for panel in panels:
   check(panel.get_global_rect().position.y >= 20 and panel.get_global_rect().end.y <= dimensions.y-20,"Settings stays inside a small phone screen")
  menu.queue_free()
  await process_frame
  view.queue_free()
  await process_frame
 UI.safe_override.clear()
 reminders.native = null
 reminders.pending = false
 for suffix in ["",".tmp",".bak"]:
  if FileAccess.file_exists(game.storage_path+suffix):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
 print("Visit reminder checks: ","PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
