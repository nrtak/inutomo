extends SceneTree
var failures = 0
func _initialize():
 call_deferred("run")
func check(value: bool, message: String):
 if not value:
  push_error(message)
  failures += 1
func run():
 var game = root.get_node("Game")
 game.set_process(false)
 game.paused_at = 0
 game.set_reduce_motion(false,false)
 for source in [Art.NORA,Art.NORA_CORAL,Art.JUNE,Art.JUNE_MINT,Art.BEN,Art.BEN_TRAINING,Art.LEAH,Art.LEAH_TUNIC,Art.OWEN,Art.OWEN_PARCEL,Art.REN,Art.REN_SWEATER,Art.KAI]:
  var portrait = ResidentPortrait.new()
  portrait.configure(source)
  root.add_child(portrait)
  var is_nora = source in [Art.NORA,Art.NORA_CORAL]
  check(portrait.frames.size() == (3 if is_nora else 2),"Every outfit has a conversation pair; Nora also has a hello wave")
  check(portrait.frames[0].get_size() == portrait.frames[1].get_size(),"Changing gesture preserves framing")
  if is_nora:
   check(portrait.frame_index == 2 and portrait.texture == portrait.frames[2],"Both Nora outfits start with the smiling hello wave")
   check(portrait.frames[2].get_size() == portrait.frames[0].get_size(),"Nora's raised hand keeps the same framing")
  var initial = portrait.texture
  portrait._process(20)
  await create_timer(0.35).timeout
  check(portrait.frame_index == (0 if is_nora else 1) and portrait.texture != initial,"A resident changes expression and gesture after a quiet pause: "+source.resource_path)
  check(portrait.get_child_count() == 0,"A gesture never overlays two faces or pairs of arms")
  if is_nora:
   portrait._process(20)
   check(portrait.frame_index == 1,"Nora continues into conversational gestures after saying hello")
   portrait._process(6)
   check(portrait.frame_index == 0 and not portrait.greeting_pending,"The hello wave does not repeat during the idle cycle")
  game.paused_at = 1
  var elapsed = portrait.elapsed
  portrait._process(30)
  check(portrait.elapsed == elapsed,"App backgrounding pauses resident animations")
  game.paused_at = 0
  portrait.hide()
  portrait._process(30)
  check(portrait.elapsed == elapsed,"Photo mode pauses hidden residents")
  portrait.queue_free()
  await process_frame
 var greeting = load("res://scripts/location_greeting.gd").new()
 greeting.texture = Art.KAI
 greeting.character_name = "Kai"
 greeting.text = "Welcome!"
 greeting.duration = 0.01
 root.add_child(greeting)
 await create_timer(0.8).timeout
 check(is_instance_valid(greeting) and greeting.get_child(0).visible and not greeting.get_child(1).visible,"Residents stay on location after the speech bubble fades")
 greeting.queue_free()
 for lanes in AmbientLife.LANES.values():
  for lane in lanes:
   check(lane.z > lane.x and is_equal_approx(lane.y,lane.w),"All boats move in the same direction without vertical rocking")
 for regions in root.get_node("Daylight").TREE_TOPS.values():
  for region in regions:
   check(region.y+region.w <= 0.4,"Wind never animates foreground flowers or bushes")
 print("Calm motion and resident checks: ","PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
