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
 game.storage_path = "user://cel_world_test.json"
 game.intro_seen = true
 game.pending_stage = ""
 game.health = PuppyHealth.fresh()
 game.life = IslandLife.fresh()
 game.resting = false
 game.breed = "Puppy"
 game.points = 0
 game.active_seconds = 0
 game.set_reduce_motion(false,false)
 for texture in Art.BACKGROUNDS.values()+[Art.ISLAND]:
  check(texture.resource_path.ends_with("_cel.png"),"Every location and the island map uses the shared cel backgrounds")
 for breed in Art.PUPPIES:
  check(Art.PUPPIES[breed].atlas == BeachStyle.DOGS and Art.SLEEP_TEXTURES[breed].atlas == BeachStyle.DOGS,"Every dog pose shares the approved artwork at every location")
  check(Art.WALKS[breed].resource_path.ends_with("_walk_cel.png"),"Walking preserves the same dog art style")
  var sheet_bounds = Rect2(Vector2.ZERO,Art.WALKS[breed].get_size())
  for region in Art.WALK_REGIONS[breed]:
   check(sheet_bounds.encloses(region),"Every walk phase stays within its source sheet")
 for source in [Art.NORA,Art.NORA_CORAL,Art.JUNE,Art.JUNE_MINT,Art.BEN,Art.BEN_TRAINING,Art.LEAH,Art.LEAH_TUNIC,Art.OWEN,Art.OWEN_PARCEL,Art.REN,Art.REN_SWEATER,Art.KAI]:
  var frames = Art.resident_frames(source)
  check(frames.size() >= 2,"Both outfits keep their resident expression cycle")
  for frame in frames:
   check(frame.atlas.resource_path.ends_with("_cel_sheet.png") and Rect2(Vector2.ZERO,frame.atlas.get_size()).encloses(frame.region),"All resident poses use registered, unclipped cel art")
  check(UI.resident_icon(source).atlas == frames[0].atlas,"Menu and help portraits match the current character artwork")
 UI.safe_override = {"left":105,"right":105,"top":20,"bottom":25}
 for width in [1280,1558]:
  var view = SubViewport.new()
  view.size = Vector2i(width,720)
  root.add_child(view)
  var main = load("res://scenes/main.tscn").instantiate()
  view.add_child(main)
  for place in ["Home","Puppy Club","Park","Shop","Vet Clinic","Beach","Harbor","Keeper’s Cottage","Lighthouse"]:
   main.show_page(place)
   await process_frame
   await process_frame
   var greeting = main.world_host.get_node_or_null("LocationGreeting")
   if is_instance_valid(greeting):
    var dog = main.habitat.puppy
    var bounds: Rect2 = dog.sprite.get_global_transform()*dog.sprite.get_rect()
    check(not greeting.get_child(1).get_global_rect().intersects(bounds),"The greeting leaves the dog visible at "+place+" on "+str(width))
   if main.camera_button.get_parent() == main.menu_button.get_parent() and main.camera_button.visible:
    check(main.camera_button.get_index()+1 == main.menu_button.get_index(),"Camera and Menu retain their order after repeated travel")
   if place == "Home":
    var bowl = main.habitat.decor_sprites.get("Feed") as Sprite2D
    if is_instance_valid(bowl):
     var bounds: Rect2 = bowl.get_global_transform()*bowl.get_rect()
     check(bounds.end.y <= 695,"The Home bowl stays above the phone's bottom edge")
   if place in ["Lighthouse","Keeper’s Cottage"]:
    check(main.habitat.background.get_global_rect().position.y >= -0.1,"Tall landmarks keep their roofs inside the screen")
  view.queue_free()
  await process_frame
 UI.safe_override.clear()
 for suffix in ["", ".tmp", ".bak"]:
  if FileAccess.file_exists(game.storage_path+suffix):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
 print("Cel world checks: ","PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
