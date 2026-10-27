extends Node

const EFFECTS = {
 "feed": preload("res://assets/audio/feed.wav"),
 "play": preload("res://assets/audio/play.wav"),
 "care": preload("res://assets/audio/care.wav"),
 "rest": preload("res://assets/audio/rest.wav"),
 "growth": preload("res://assets/audio/growth.wav"),
 "step": preload("res://assets/audio/step.wav")
}
var ambience: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var next_voice = 0
var suspended = false
var ambience_base_db = -24.0

func _ready() -> void:
 ambience = AudioStreamPlayer.new()
 var waves: AudioStreamWAV = preload("res://assets/audio/waves.wav").duplicate()
 waves.loop_mode = AudioStreamWAV.LOOP_FORWARD
 waves.loop_end = int(waves.get_length() * waves.mix_rate)
 ambience.stream = waves
 ambience.volume_db = -22
 add_child(ambience)
 for index in 5:
  var voice = AudioStreamPlayer.new()
  add_child(voice)
  voices.append(voice)
 Game.care_performed.connect(func(kind: String): play_effect({"Pet": "care", "Treat": "feed", "Sniff": "care", "Sit": "play"}.get(kind, kind.to_lower()), -19))
 if DisplayServer.get_name() != "headless":
  set_enabled(Game.sound_enabled, false)

func set_location(location: String) -> void:
 ambience_base_db = -10 if location == "Beach" else -16
 apply_mix()

func set_enabled(enabled: bool, persist: bool = true) -> void:
 Game.sound_enabled = enabled
 apply_mix()
 if enabled and not suspended:
  if not ambience.playing:
   ambience.play()
 else:
  ambience.stop()
  for voice in voices:
   voice.stop()
 if persist:
  Game.save_game()

func play_effect(kind: String, volume: float = -23) -> void:
 if DisplayServer.get_name() == "headless" or not Game.sound_enabled or suspended or Game.effects_volume <= 0 or not EFFECTS.has(kind):
  return
 var voice = voices[next_voice]
 next_voice = (next_voice + 1) % voices.size()
 voice.stream = EFFECTS[kind]
 voice.set_meta("base_volume", volume)
 voice.volume_db = volume + linear_to_db(maxf(0.001, Game.effects_volume))
 voice.pitch_scale = randf_range(0.96, 1.04) if kind == "step" else 1.0
 voice.play()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_PAUSED:
  suspended = true
  if is_instance_valid(ambience):
   set_enabled(Game.sound_enabled, false)
 elif what == NOTIFICATION_APPLICATION_RESUMED:
  suspended = false
  if is_instance_valid(ambience):
   set_enabled(Game.sound_enabled, false)

func _exit_tree() -> void:
 if is_instance_valid(ambience):
  ambience.stop()
  ambience.stream = null
 for voice in voices:
  voice.stop()
  voice.stream = null

func apply_mix() -> void:
 if is_instance_valid(ambience):
  ambience.volume_db = ambience_base_db + linear_to_db(maxf(0.001, Game.ambience_volume))
  ambience.stream_paused = Game.ambience_volume <= 0

func set_levels(effects: float, waves: float, persist: bool = true) -> void:
 Game.effects_volume = clampf(effects, 0, 1)
 Game.ambience_volume = clampf(waves, 0, 1)
 for voice in voices:
  voice.volume_db = float(voice.get_meta("base_volume", -23.0)) + linear_to_db(maxf(0.001, Game.effects_volume))
  if Game.effects_volume <= 0:
   voice.stop()
 apply_mix()
 if persist:
  Game.save_game()
