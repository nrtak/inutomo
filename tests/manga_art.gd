extends SceneTree

var failures=0
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
	if not value:
		push_error(message)
		failures+=1

func run():
	var game=root.get_node("Game")
	game.set_process(false)
	game.life=IslandLife.fresh()
	game.items={}
	game.resting=false
	var manifest: Dictionary=load("res://assets/manga/manifest.json").data
	check(manifest.assets.size()==77,"The artwork inventory covers the original production set, eight directional run sheets and the app icon")
	for item in manifest.assets:
		var texture=load("res://"+item.production) as Texture2D
		check(texture!=null and texture.get_width()>0 and texture.get_height()>0,"Production artwork loads: "+item.production)
		check(FileAccess.get_sha256("res://"+item.source)!=FileAccess.get_sha256("res://"+item.production),"The approved production artwork replaces its older image: "+item.production)
	for breed in Art.PUPPIES:
		game.breed=breed
		game.life.accessory="CoralBandana"
		var dog=load("res://scripts/puppy.gd").new()
		root.add_child(dog)
		dog.set_process(false)
		check(not dog.outfit_equipped(),"An unpurchased accessory never appears on "+breed)
		dog.set_pose(false)
		check(dog.sprite.texture==Art.PUPPIES[breed] and "bare" in dog.sprite.texture.atlas.resource_path,"The starting dog is bare-necked: "+breed)
		check(dog.sprite.material==dog.sleep_material,"All default poses use the same clean alpha edge")
		for dressed in [false,true]:
			var data: Dictionary=(Art.DRESSED_WALK_DATA if dressed else Art.WALK_DATA)[breed]
			var sheet: Texture2D=(Art.DRESSED_WALKS if dressed else Art.WALKS)[breed]
			check(data.regions.size()==8 and data.anchors.size()==8,"All eight registered gait phases remain available")
			for i in 8:
				var b: Array=data.regions[i]
				check(Rect2(Vector2.ZERO,sheet.get_size()).encloses(Rect2(b[0],b[1],b[2],b[3])),"Walk crop remains inside its manga sheet")
				check(data.anchors[i]>=0 and data.anchors[i]<=b[2],"The torso anchor remains inside its own phase")
			for pose in ["Tilt","Stretch","Greet","Tug"]:
				var frame=Art.expression_texture(breed,pose,dressed) as AtlasTexture
				check(Rect2(Vector2.ZERO,frame.atlas.get_size()).encloses(frame.region),"Every reaction is registered inside the new artwork")
		dog.queue_free()
		await process_frame
	game.life.accessory=""
	for kind in Goods.PICTURE_REGIONS.keys()+Goods.EXPANDED_REGIONS.keys():
		var frame=Goods.picture(kind) as AtlasTexture
		check(frame.atlas.resource_path.begins_with("res://assets/manga/"),"Shop and Home props share the manga artwork")
		check(Rect2(Vector2.ZERO,frame.atlas.get_size()).encloses(frame.region),"The measured goods crop remains inside its sheet")
	for kind in ["Home","Recall","Beach","Cottage","Lighthouse"]:
		check(MomentArt.background(kind).resource_path.begins_with("res://assets/manga/"),"Story scenes retain the same production style")
	for name in Art.RESIDENT_DATA:
		var sheet: Texture2D=load("res://"+Art.RESIDENT_DATA[name].atlas)
		var image=sheet.get_image()
		var columns=3 if name=="nora" else 2
		var padding_clear=true
		for column in range(1,columns):
			var x=int(image.get_width()*column/columns)
			for y in image.get_height():
				if image.get_pixel(x,y).a>=0.76: padding_clear=false
		check(padding_clear,"Neighboring resident gestures cannot bleed across their cell boundary: "+name)
	print("Manga artwork checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
