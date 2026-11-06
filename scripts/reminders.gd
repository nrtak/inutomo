extends Node

signal updated
var native: Object
var pending = false
var status = ""

func _ready() -> void:
 if OS.get_name() == "iOS" and Engine.has_singleton("PuppyReminders"):
  native = Engine.get_singleton("PuppyReminders")
 sync_preference()

func available() -> bool:
 return is_instance_valid(native)

func sync_preference() -> void:
 if available():
  native.configure(Game.visit_reminder_enabled,Game.puppy_name)

func set_enabled(enabled: bool) -> void:
 if not enabled:
  pending = false
  Game.visit_reminder_enabled = false
  # Opting out cancels the notice immediately, even if saving needs a retry.
  sync_preference()
  status = "" if Game.save_game() else Game.save_error
 elif available() and not pending:
  pending = true
  status = ""
  native.request_permission()
 elif not available():
  status = "Visit reminders are available on iPhone."
 updated.emit()

func _process(_delta: float) -> void:
 if not pending or not available():
  return
 var result: Dictionary = native.get_result()
 if not result.get("ready",false):
  return
 pending = false
 if result.get("error",false):
  status = "The reminder could not be enabled. Please try again."
 else:
  var previous = Game.visit_reminder_enabled
  Game.visit_reminder_enabled = bool(result.get("granted",false))
  if not Game.save_game():
   Game.visit_reminder_enabled = previous
   status = Game.save_error
  else:
   status = "" if Game.visit_reminder_enabled else "Allow notifications for Inushima in iPhone Settings to enable this reminder."
 sync_preference()
 updated.emit()
