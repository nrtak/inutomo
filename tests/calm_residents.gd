extends SceneTree
var failures = 0
var portrait_taps = 0
func _initialize():
 call_deferred("run")
func check(value: bool, message: String):
 if not value:
  push_error(message)
  failures += 1
func click(view: SubViewport, point: Vector2):
 var motion = InputEventMouseMotion.new()
 motion.position = point
 view.push_input(motion,true)
 for pressed in [true,false]:
  var event = InputEventMouseButton.new()
  event.position = point
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  view.push_input(event,true)
  await process_frame

func check_portrait_input():
 var view = SubViewport.new()
 view.size = Vector2i(600,600)
 root.add_child(view)
 var portrait = ResidentPortrait.new()
 portrait.configure(Art.KAI)
 portrait.position = Vector2(20,20)
 portrait.size = portrait.texture.get_size()
 portrait.mouse_filter = Control.MOUSE_FILTER_STOP
 portrait.gui_input.connect(func(event):
  if event is InputEventMouseButton and event.pressed:
   portrait_taps += 1
 )
 view.add_child(portrait)
 await process_frame
 await click(view,portrait.position+Vector2(1,1))
 check(portrait_taps == 0,"Transparent portrait corners do not open a conversation")
 var frame = portrait.texture as AtlasTexture
 var image = frame.atlas.get_image()
 var visible = Vector2.ZERO
 for y in range(0,int(frame.region.size.y),8):
  for x in range(0,int(frame.region.size.x),8):
   if image.get_pixelv(Vector2i(frame.region.position)+Vector2i(x,y)).a>0.9:
    visible = Vector2(x,y)+frame.margin.position
    break
  if visible!=Vector2.ZERO:
   break
 await click(view,portrait.position+visible)
 check(portrait_taps == 1,"The visible resident still responds to an actual tap")
 view.queue_free()
 await process_frame
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
  var full_frame = Art.resident_frames(Art.daily_portrait(source))[0]
  check(portrait.frames[0].get_height() < full_frame.get_height()*0.78,"Every resident and outfit uses the larger torso framing")
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
 await check_portrait_input()
 print("Calm motion and resident checks: ","PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
