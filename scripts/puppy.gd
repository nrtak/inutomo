class_name PuppyActor
extends Node2D

var sprite: Sprite2D
var shadow: Sprite2D
var walk_area = PackedVector2Array()
var barriers: Array[Rect2] = []
var bed_barrier = Rect2()
var route_points: Array[Vector2] = []
var route_goal = Vector2(INF,INF)
var route_barriers: Array[Rect2] = []
var motion_velocity = Vector2.ZERO
var target = Vector2(640, 550):
	set(value):
		target = WalkArea.destination(walk_area, barriers, value)
var bounds = Rect2(390, 510, 460, 40)
var mood = "Sniffing the sea breeze"
var clock = 0.0
var decision = 3.0
var controlled = false
var base_scale = 1.0
var location_portrait = false
var presentation_style = ""
var portrait_width: float = 320.0
var portrait_height: float = 325.0
var portrait_scale_height = 0.0
var reaction_time = 0.0
var reaction_kind = ""
var nap_remaining = 65.0
var awake_remaining = 0.0
var napping = true
var current_breed = ""
var visible_size: Vector2 = Vector2.ONE
var pose_bounds: Dictionary = {}
var walk_texture: Texture2D
var walk_frames: Array[Rect2] = []
var stride_distance = 0.0
var move_speed = 0.0
var settle_time = 0.0
var footfall_distance = 0.0
var reaction_duration = 2.4
var reaction_icon: Sprite2D
var sleepy_reaction = false
var sleep_material: ShaderMaterial
var style_material: ShaderMaterial
var pet_material: ShaderMaterial
var preview_accessory = ""
var trick_command = ""
var trick_elapsed = 0.0
var carrying_toy = false
var discovery_time = 0.0
var command_delay = 0.0
var home_interactions = false
var home_headroom = 300.0
var pending_decor_action = ""
var arriving_at_decor = false
var settling_for_rest = false
var reaction_above_head = false
var illustrated_pose = ""
var illustrated_width = 0.0
var illustrated_height = 0.0
var dressed_walk = false
var expression_time = 0.0
var expression_kind = ""
var expression_clock = 0.0
var expression_index = 0
var screen_width_limit = INF
var include_actor_scale_in_width_limit = false
var feeding_spot = Vector2(INF,INF)
var feeding_barrier = Rect2()
var welcome_duration = 0.0
var welcome_hops = 0
var fetch_running = false
var fetch_mouth_down = false
var returning_ball = false
var run_view = "side"
var activity_speed = 0.0
var attention_time = 0.0
var attention_left = false
var celebration_time = 0.0
var displayed_size = Vector2.ZERO
var action_item: Sprite2D
var action_item_time=0.0
var action_item_duration=0.0
var action_item_kind=""

func _ready() -> void:
	shadow = Sprite2D.new()
	shadow.texture = preload("res://assets/manga/puppies/shadow.svg")
	shadow.position.y = -5
	shadow.scale = Vector2(1.5, 1)
	add_child(shadow)
	sprite = Sprite2D.new()
	sleep_material = ShaderMaterial.new()
	sleep_material.shader = preload("res://scripts/sleep_cutout.gdshader")
	style_material = ShaderMaterial.new()
	style_material.shader = preload("res://scripts/dog_style.gdshader")
	pet_material = style_material.duplicate()
	add_child(sprite)
	reaction_icon = Sprite2D.new()
	reaction_icon.position = Vector2(125, -180)
	reaction_icon.visible = false
	add_child(reaction_icon)
	action_item=Sprite2D.new()
	action_item.material=UI.art_cutout()
	action_item.visible=false
	add_child(action_item)
	Game.care_performed.connect(react_to_care)
	set_breed()
	position = Vector2(640, 550)

func set_breed() -> void:
	current_breed = Game.breed
	prepare_walk_frames()
	var baby = Game.breed == "Puppy"
	if not baby: napping = false
	shadow.scale = Vector2(0.85, 0.65) if baby else Vector2(1.5, 1)
	reaction_icon.position = Vector2(75, -100) if baby else Vector2(125, -180)
	set_pose(false)

func set_pose(asleep: bool) -> void:
	var unified = presentation_style == "Beach"
	var texture: Texture2D = (Art.DRESSED_SLEEP_TEXTURES[Game.breed] if asleep else Art.DRESSED_PUPPIES[Game.breed]) if outfit_equipped() else (Art.SLEEP_TEXTURES[Game.breed] if asleep else Art.PUPPIES[Game.breed])
	sprite.material = sleep_material
	var accessory: String = preview_accessory if not preview_accessory.is_empty() else Game.life.accessory
	if Goods.ITEMS.has(accessory) and Goods.ITEMS[accessory].has("color") and (not preview_accessory.is_empty() or Game.items.get(accessory, 0) > 0):
		style_material.set_shader_parameter("bandana", Goods.ITEMS[accessory].color)
		style_material.set_shader_parameter("recolor", true)
		style_material.set_shader_parameter("sleeping_cutout", asleep and Game.breed != "Puppy")
		sprite.material = style_material
	if sprite.texture != texture:
		sprite.texture = texture
		if not pose_bounds.has(texture):
			pose_bounds[texture] = Rect2i(Vector2i.ZERO,texture.get_size())
		var visible_rect: Rect2i = pose_bounds[texture]
		sprite.region_enabled = true
		sprite.region_rect = visible_rect
		sprite.offset.x = 0
		sprite.offset.y = -visible_rect.size.y * 0.5
		visible_size = visible_rect.size
	var growth = Game.growth_fraction()
	if asleep:
		base_scale = (lerpf(200, 290, growth) if Game.breed == "Puppy" else Art.sleeping_width(Game.breed)) / visible_size.x
	else:
		base_scale = awake_height() / visible_size.y
	sprite.scale = Vector2.ONE * base_scale
	if unified:
		base_scale = minf(portrait_width/visible_size.x,portrait_height/visible_size.y)
		sprite.scale = Vector2.ONE*base_scale
		shadow.scale = Vector2(visible_size.x*base_scale/140.0,0.8)
		shadow.modulate = Color("b39b81")
	fit_screen_width()

func fit_screen_width() -> void:
	if is_inf(screen_width_limit) or not is_instance_valid(sprite) or sprite.texture==null: return
	var width=screen_width_limit/maxf(.01,scale.x) if include_actor_scale_in_width_limit else screen_width_limit
	base_scale=minf(base_scale,width/maxf(1,sprite.get_rect().size.x))
	sprite.scale=Vector2.ONE*base_scale

func request_move(point: Vector2) -> void:
	if controlled or Game.resting:
		return
	if Game.breed == "Puppy":
		wake_briefly()
		target = position + (point - position).limit_length(45)
	else:
		target = point
	pending_decor_action = ""
	if reaction_kind in ["Feed","Pet","Play"]:
		reaction_time = 0
		action_item_time = 0
	carrying_toy = false
	decision = 4.0

func wake_briefly() -> void:
	nap_remaining = 0
	awake_remaining = lerpf(10, 30, Game.growth_fraction())
	napping = false

func awake_height() -> float:
	var height = lerpf(180,280,Game.growth_fraction()) if Game.breed=="Puppy" else Art.adult_height(Game.breed)
	# Home's closer camera uses perspective so taller dogs stay below the HUD.
	return minf(height,maxf(120,position.y-home_headroom)) if home_interactions else height

func begin_expression(kind: String, duration: float = 2.0) -> bool:
	if Game.resting or PuppyHealth.unwell(Game) or (Game.breed=="Puppy" and napping) or not pending_decor_action.is_empty(): return false
	expression_kind = kind
	expression_time = duration
	expression_clock = 0
	welcome_duration = 0.0
	return true

func welcome_player(away_seconds: float = 0.0) -> void:
	if Game.resting or PuppyHealth.unwell(Game): return
	if Game.breed=="Puppy" and napping and away_seconds<1800:
		react_to_care("Pet")
	else:
		wake_briefly()
		target = position
		motion_velocity = Vector2.ZERO
		reaction_time = 0
		pending_decor_action = ""
		trick_command = ""
		welcome_hops = 3 if away_seconds>=7200 else (2 if away_seconds>=1800 else 1)
		var duration = 1.2+welcome_hops*0.6
		begin_expression("Greet",duration)
		welcome_duration = duration
		decision = duration+2
		mood = "So happy you're back!" if away_seconds>=1800 else "Happy to see you"

func show_expression() -> void:
	if welcome_duration>0 and not Game.reduce_motion:
		var elapsed = welcome_duration-expression_time-0.2
		if elapsed >= 0 and elapsed < welcome_hops*0.6:
			var phase = fmod(elapsed,0.6)/0.6
			var height = awake_height()
			var lift = minf(18.0,height*0.075)
			if home_interactions:
				height = minf(height,maxf(1.0,position.y-home_headroom-lift))
			sprite.flip_h = false
			sprite.rotation = 0
			# Gather, push off, reach forward, then plant the paws before the next bound.
			show_run_frame("toward",int(phase*4),height)
			var flight = clampf((phase-0.25)/0.55,0,1)
			sprite.position = Vector2(0,-lift*4*flight*(1-flight))
			reaction_icon.visible = false
			return
	show_reaction_pose(expression_kind)

func show_reaction_pose(pose: String) -> void:
	var dressed = outfit_equipped()
	sprite.texture = MomentArt.dog(Game.breed,pose,dressed)
	sprite.region_enabled = false
	visible_size = sprite.texture.get_size()
	sprite.offset = Vector2(0,-sprite.texture.get_height()*0.5)
	sprite.material = style_material if dressed else sleep_material
	if dressed:
		var accessory = preview_accessory if not preview_accessory.is_empty() else Game.life.accessory
		style_material.set_shader_parameter("recolor",true)
		style_material.set_shader_parameter("bandana",Goods.ITEMS[accessory].color)
	var height = minf(portrait_width,portrait_height) if presentation_style=="Beach" else awake_height()
	# Story sniff poses come from higher-resolution sheets than the idle reactions.
	base_scale = height*0.68/visible_size.y if pose=="Sniff" else height/Art.expression_texture(Game.breed,"Tilt",dressed).get_height()
	sprite.scale = Vector2.ONE*base_scale
	fit_screen_width()
	sprite.position = Vector2.ZERO
	sprite.rotation = 0
	sprite.flip_h = false
	reaction_icon.visible = false

func show_meal_reaction() -> void:
	var elapsed = reaction_duration-reaction_time
	var eating = elapsed>=0.65 and reaction_time>=0.45
	show_reaction_pose("Sniff" if eating else ("Greet" if elapsed<0.65 else "Tilt"))
	if home_interactions and reaction_time>=0.45 and Game.life.bowl:
		sprite.flip_h = bowl_bounds().get_center().x<position.x
	if eating and not Game.reduce_motion:
		var bite = sin((elapsed-0.65)/(reaction_duration-1.1)*TAU)
		sprite.scale.y *= 1.0-0.055*bite*bite
	reaction_icon.visible = true
	reaction_icon.position = Vector2(0,-visible_size.y*base_scale-22)
	reaction_icon.modulate.a = minf(1,reaction_time*2)

func bowl_bounds() -> Rect2:
	return feeding_barrier if feeding_barrier.has_area() else IslandLife.bowl_barrier(Game)

func meal_approach() -> Vector2:
	var bowl = bowl_bounds()
	var waiting = beside_bowl()
	var sniff = MomentArt.dog(Game.breed,"Sniff",outfit_equipped()).get_size()
	var width = minf(screen_width_limit,sniff.x*awake_height()*0.68/sniff.y)
	var reach = (SNIFF_MUZZLES[Game.breed].x-0.5)*width
	var distance = maxf(bowl.size.x*0.5+2,bowl.size.x*0.22+reach)
	var mouth_height = (1.0-SNIFF_MUZZLES[Game.breed].y)*width*sniff.y/sniff.x
	return bowl.get_center()+Vector2(signf(waiting.x-bowl.get_center().x)*distance,mouth_height-bowl.size.y*0.57)

func beside_bowl() -> Vector2:
	return IslandLife.feeding_point(Game) if is_inf(feeding_spot.x) else feeding_spot

func sleep_overlaps_bowl() -> bool:
	var size_px: Vector2 = Art.SLEEP_TEXTURES[Game.breed].get_size()
	var width = lerpf(200,290,Game.growth_fraction()) if Game.breed=="Puppy" else Art.sleeping_width(Game.breed)
	var footprint = size_px*(minf(width,screen_width_limit)/size_px.x)
	return bowl_bounds().intersects(Rect2(position-Vector2(footprint.x*0.5,footprint.y),footprint))

func ready_for_growth_moment() -> bool:
	return (welcome_duration<=0 or expression_time<=0) and reaction_time<=0 and pending_decor_action.is_empty()

# Eye centers on each tilted-head portrait, measured in the cropped frame.
const PET_EYES = {
	"Puppy":Vector4(.50,.31,.73,.23), "Shiba Inu":Vector4(.61,.27,.79,.20),
	"Golden Retriever":Vector4(.65,.21,.78,.14), "Dachshund":Vector4(.42,.23,.55,.13),
	"Miniature Collie":Vector4(.47,.26,.59,.20), "Beagle":Vector4(.50,.21,.68,.13),
	"Corgi":Vector4(.46,.30,.57,.25), "Toy Poodle":Vector4(.40,.24,.54,.18)
}

func show_pet_blink(elapsed: float) -> void:
	var closed = smoothstep(0.55,0.83,elapsed)*(1.0-smoothstep(0.95,1.24,elapsed))
	if closed<=0: return
	var frame: AtlasTexture = sprite.texture
	var eyes: Vector4 = PET_EYES[Game.breed]
	if outfit_equipped() and Game.breed=="Beagle": eyes=Vector4(.36,.20,.51,.13)
	var atlas_size = frame.atlas.get_size()
	var left = (frame.region.position+Vector2(eyes.x,eyes.y)*frame.region.size)/atlas_size
	var right = (frame.region.position+Vector2(eyes.z,eyes.w)*frame.region.size)/atlas_size
	var radius = Vector2(.072,.075)*frame.region.size/atlas_size
	pet_material.set_shader_parameter("eye_centers",Vector4(left.x,left.y,right.x,right.y))
	pet_material.set_shader_parameter("eye_radius",radius)
	pet_material.set_shader_parameter("blink",closed)
	pet_material.set_shader_parameter("recolor",outfit_equipped())
	if outfit_equipped(): pet_material.set_shader_parameter("bandana",style_material.get_shader_parameter("bandana"))
	sprite.material=pet_material

func show_social_reaction() -> void:
	var elapsed = reaction_duration-reaction_time
	if reaction_kind=="Play":
		show_reaction_pose("Stretch" if reaction_time>0.45 else "Greet")
		return
	show_reaction_pose("Tilt")
	sprite.flip_h = attention_left
	if not Game.reduce_motion:
		var lean = sin(PI*elapsed/reaction_duration)
		sprite.rotation = (-1.0 if attention_left else 1.0)*0.045*lean
	show_pet_blink(elapsed)
	reaction_icon.visible = true
	reaction_icon.position = Vector2(0,-visible_size.y*base_scale-18)
	reaction_icon.modulate.a = minf(1,reaction_time*2)

func cuddly_settle() -> bool:
	return home_interactions and not controlled and reaction_kind=="Care" and reaction_time>0 and reaction_duration-reaction_time>=2.4 and IslandLife.personality(Game)=="Cuddly" and (not Game.life.bowl or not sleep_overlaps_bowl())

func idle_expression(delta: float) -> void:
	if Game.reduce_motion or Game.resting or PuppyHealth.unwell(Game) or reaction_time>0 or position.distance_to(target)>1: return
	expression_clock += delta
	if expression_clock>=14.0:
		var poses = ["Tilt","Stretch","Greet"]
		begin_expression(poses[expression_index%poses.size()])
		expression_index += 1

func _process(delta: float) -> void:
	if Game.paused_at>0: return
	_animate(delta)
	update_action_item(delta)
	var target_size=sprite.get_rect().size*sprite.scale
	var welcome_stride = welcome_duration>0 and expression_time>0 and sprite.region_enabled
	if displayed_size==Vector2.ZERO or Game.reduce_motion or controlled or welcome_stride or not illustrated_pose.is_empty():
		displayed_size=target_size
	else:
		displayed_size=displayed_size.lerp(target_size,1.0-exp(-delta*24.0))
		var width_limit=screen_width_limit if not is_inf(screen_width_limit) else displayed_size.x
		displayed_size.x=minf(displayed_size.x,width_limit)
		sprite.scale*=Vector2(displayed_size.x/maxf(1,target_size.x),displayed_size.y/maxf(1,target_size.y))
	attention_time=maxf(0,attention_time-delta)
	if attention_time>0 and not Game.resting and not napping and move_speed<1 and (reaction_time<=0 or reaction_kind not in ["Feed","Pet","Play"]) and trick_command.is_empty():
		sprite.flip_h=attention_left
		if not Game.reduce_motion: sprite.rotation+=sin(minf(1,attention_time)*PI)*(-0.025 if attention_left else 0.025)
	celebration_time=maxf(0,celebration_time-delta)
	queue_redraw()

func show_action_item(texture: Texture2D, kind: String = "Find", seconds: float = 3.0) -> void:
	if texture==null: return
	action_item.texture=texture
	action_item_kind=kind
	action_item_duration=seconds
	action_item_time=seconds
	if kind=="Find":
		target=position
		motion_velocity=Vector2.ZERO
		begin_expression("Sniff",0.9)
	update_action_item(0)

func update_action_item(delta: float) -> void:
	if not is_instance_valid(action_item): return
	var previous=action_item_time
	action_item_time=maxf(0,action_item_time-delta)
	if Game.resting and action_item_kind!="Treat": action_item_time=0
	var elapsed=action_item_duration-action_item_time
	action_item.visible=action_item_time>0 and (action_item_kind!="Find" or elapsed>=.55)
	if not action_item.visible: return
	if action_item_kind in ["Care","Treat","Play"]: reaction_icon.visible=false
	var height=visible_size.y*base_scale
	var width=visible_size.x*base_scale
	var object_size=minf(76,maxf(32,height*.29))
	action_item.scale=Vector2.ONE*(object_size/maxf(1,action_item.texture.get_size().length()))
	action_item.modulate.a=minf(1,action_item_time*3)
	action_item.rotation=0
	match action_item_kind:
		"Care":
			if cuddly_settle():
				action_item.visible=false
				return
			action_item.position=Vector2(width*.27,-height*.56+(0 if Game.reduce_motion else fposmod(elapsed,0.65)*24))
			action_item.rotation=-.35
		"Treat":
			action_item.position=Vector2(width*.22,-height*.55)
			action_item.scale*=lerpf(.3,1.0,action_item_time/action_item_duration)
		"Play":
			action_item.position=Vector2(width*.36,-object_size*.4-(0 if Game.reduce_motion else absf(sin(elapsed*4))*height*.12))
		_:
			action_item.position=Vector2(width*.40,-object_size*.35)
			if previous>action_item_duration-1 and action_item_time<=action_item_duration-1: celebrate_success()

func notice_point(point: Vector2) -> void:
	if Game.resting or napping or PuppyHealth.unwell(Game): return
	attention_left=point.x<position.x
	attention_time=1.4
	if not location_portrait and reaction_time<=0 and position.distance_to(target)<1: begin_expression("Tilt",1.4)

func celebrate_success() -> void:
	if Game.resting or PuppyHealth.unwell(Game): return
	celebration_time=0.9
	begin_expression("Greet",0.9)
	Sound.play_effect("happy",-27)

func _animate(delta: float) -> void:
	if Game.paused_at > 0:
		return
	sprite.position.x = 0
	if current_breed!=Game.breed:
		expression_time = 0
		set_breed()
	if dressed_walk != outfit_equipped():
		prepare_walk_frames()
	if expression_time>0:
		if Game.resting or PuppyHealth.unwell(Game) or position.distance_to(target)>1:
			expression_time = 0
		else:
			expression_time = maxf(0,expression_time-delta)
			show_expression()
			return
	if controlled and fetch_mouth_down:
		var facing_left = sprite.flip_h
		show_reaction_pose("Sniff")
		sprite.flip_h = facing_left
		return
	if not illustrated_pose.is_empty() and not Game.resting and not PuppyHealth.unwell(Game):
		sprite.material = sleep_material
		if outfit_equipped():
			var accessory: String = preview_accessory if not preview_accessory.is_empty() else Game.life.accessory
			style_material.set_shader_parameter("bandana", Goods.ITEMS[accessory].color)
			style_material.set_shader_parameter("recolor", true)
			style_material.set_shader_parameter("sleeping_cutout", false)
			sprite.material = style_material
		sprite.texture = MomentArt.dog(Game.breed,illustrated_pose,outfit_equipped())
		sprite.region_enabled = false
		visible_size = sprite.texture.get_size()
		sprite.offset = Vector2(0,-visible_size.y*0.5)
		base_scale = (illustrated_width if illustrated_width > 0 else (260.0 if Game.breed == "Puppy" else 300.0))/visible_size.x
		if illustrated_height > 0:
			base_scale = minf(base_scale,illustrated_height/visible_size.y)
		sprite.scale = Vector2.ONE*base_scale
		sprite.flip_h = false
		sprite.position = Vector2.ZERO
		sprite.rotation = 0
		reaction_icon.visible = false
		return
	if not trick_command.is_empty():
		if current_breed != Game.breed:
			set_breed()
		trick_elapsed += delta
		if trick_elapsed < 3.2 and not Game.resting and not PuppyHealth.unwell(Game):
			show_trick_pose()
			return
		trick_command = ""
		reaction_time = 0
		set_pose(Game.resting)
	if location_portrait:
		if current_breed != Game.breed:
			set_breed()
		clock += delta
		napping = Game.resting
		set_pose(Game.resting)
		if portrait_scale_height > 0:
			scale = Vector2.ONE*minf(1.85,portrait_scale_height/(visible_size.y*base_scale))
			fit_screen_width()
		reaction_time = maxf(0,reaction_time-delta)
		if reaction_time>0 and reaction_kind=="Feed" and not Game.resting:
			show_meal_reaction()
			return
		if reaction_time>0 and reaction_kind in ["Pet","Play"] and not sleepy_reaction and not Game.resting:
			show_social_reaction()
			return
		reaction_icon.visible = reaction_time > 0
		sprite.position.y = 0 if Game.reduce_motion else sin(clock*2)*0.7
		if reaction_icon.visible:
			reaction_icon.position = Vector2(0,-visible_size.y*base_scale-18) if presentation_style == "Beach" else Vector2(35,-125)
			reaction_icon.modulate.a = minf(1,reaction_time*2)
			sprite.rotation = 0 if Game.reduce_motion else sin(reaction_time*4)*0.015
		else:
			sprite.rotation = 0
		idle_expression(delta)
		return
	if Game.paused_at > 0:
		return
	if Game.resting or PuppyHealth.unwell(Game):
		command_delay = 0
		if pending_decor_action in ["ToyVisit", "ToyReturn"]:
			target = position
			pending_decor_action = ""
			carrying_toy = false
	discovery_time = maxf(0, discovery_time - delta)
	if command_delay > 0:
		command_delay = maxf(0, command_delay-delta)
		return
	if settling_for_rest and (not Game.resting or position.distance_to(target) < 1):
		settling_for_rest = false
	if not pending_decor_action.is_empty() and position.distance_to(target) < 2:
		var action = pending_decor_action
		pending_decor_action = ""
		if action == "ToyVisit":
			carrying_toy = true
			reaction_icon.texture = Goods.picture(Game.life.toy)
			reaction_icon.scale = Vector2.ONE * (45.0 / reaction_icon.texture.get_width())
			reaction_icon.modulate.a = 1
			target = WalkArea.nearest(walk_area, IslandLife.home_point(Game,"Rest") + Vector2(-45,30))
			pending_decor_action = "ToyReturn"
			decision = 30
		else:
			carrying_toy = false
			arriving_at_decor = true
			react_to_care("Play" if action == "ToyReturn" else action)
			arriving_at_decor = false
			if action == "ToyReturn":
				mood = "Brought a favorite toy over to share"
				Sound.play_effect("happy",-25)
	clock += delta
	decision -= delta
	if current_breed != Game.breed:
		set_breed()
	var baby = Game.breed == "Puppy"
	var was_napping = napping
	if sleepy_reaction and reaction_time > 0:
		napping = true
	elif baby and not controlled and not Game.resting and reaction_time <= 0:
		if nap_remaining > 0:
			nap_remaining = maxf(0, nap_remaining - delta)
			napping = nap_remaining > 0
			if not napping:
				awake_remaining = randf_range(8, 12) + Game.growth_fraction() * 30
				decision = 0
		elif awake_remaining > 0:
			awake_remaining = maxf(0, awake_remaining - delta)
			if awake_remaining == 0:
				nap_remaining = randf_range(55, 85) - Game.growth_fraction() * 35
				napping = true
	else:
		napping = false
	var asleep = not controlled and not settling_for_rest and (Game.resting or (baby and napping))
	set_pose(asleep)
	if was_napping and not napping and not controlled and reaction_time<=0 and not Game.reduce_motion:
		begin_expression("Stretch",1.8)
	if asleep:
		target = position
		move_speed = 0
		motion_velocity = Vector2.ZERO
		mood = "Napping in a cozy little bundle"
		sprite.position.y = 0
		sprite.rotation = 0
		sprite.scale = Vector2.ONE*base_scale if Game.reduce_motion else Vector2(1, 1 + sin(clock * 2) * 0.015) * base_scale
		reaction_time = maxf(0, reaction_time - delta)
		reaction_icon.visible = sleepy_reaction and reaction_time > 0
		if reaction_icon.visible:
			reaction_icon.position = Vector2(35, -125 if Game.reduce_motion else -125 - sin(clock * 3) * 5)
			reaction_icon.modulate.a = minf(1, reaction_time * 2)
			sprite.rotation = 0 if Game.reduce_motion else sin(clock * 4) * 0.018
			mood = "A sleepy little nuzzle" if reaction_kind == "Pet" else "A sleepy nibble, then back to dreaming"
		else:
			sleepy_reaction = false
		return
	var finishing_meal = home_interactions and Game.life.bowl and reaction_kind=="Feed" and reaction_time>0 and reaction_time<=delta
	reaction_time = maxf(0, reaction_time - delta)
	if finishing_meal:
		target = beside_bowl()
		awake_remaining = maxf(awake_remaining,8)
		decision = 8
	queue_redraw()
	reaction_icon.visible = reaction_time > 0 or carrying_toy
	if reaction_time > 0 and not controlled and (reaction_kind != "Come" or position.distance_to(target) < 1):
		sprite.flip_h = false
		sprite.rotation = 0
		var bounce = 0.0 if Game.reduce_motion else absf(sin(reaction_time * 7))
		match reaction_kind:
			"Feed":
				show_meal_reaction()
				return
			"Play","Pet":
				show_social_reaction()
				return
			"Care":
				if cuddly_settle():
					set_pose(true)
					sprite.position=Vector2.ZERO
					reaction_icon.visible=false
					mood="Settled close after a gentle brush"
					return
				sprite.position.y = 0
				reaction_icon.position = Vector2(70, -100)
				queue_redraw()
			"Treat":
				sprite.position.y = -bounce * (0.5 if PuppyHealth.unwell(Game) else (4 if IslandLife.personality(Game) == "Playful" else 2))
				sprite.rotation = sin(reaction_time * 5) * 0.025
				reaction_icon.position = Vector2(50, -120 - bounce * 8)
			"Sniff", "Sit", "Stay":
				if reaction_kind=="Sniff" and discovery_time>0 and IslandLife.personality(Game)=="Curious":
					show_reaction_pose("Sniff" if discovery_time>.75 else "Tilt")
					return
				var steadiness = 1.0 - float(Game.life.training.get(reaction_kind,0)) / 5.0
				sprite.position.y = bounce * (2 if reaction_kind == "Sniff" else 2 * steadiness)
				sprite.rotation = sin(reaction_time * 3) * 0.02 * (1.0 if reaction_kind == "Sniff" else steadiness)
				reaction_icon.position = Vector2(65, -90)
			_:
				sprite.position.y = 0
				reaction_icon.position = Vector2(70, -100)
		if reaction_above_head:
			reaction_icon.position = Vector2(0, -visible_size.y * base_scale - 22)
		if Game.reduce_motion:
			sprite.position = Vector2.ZERO
			sprite.rotation = 0
		sprite.scale = Vector2(1 + bounce * 0.025, 1 - bounce * 0.025) * base_scale
		reaction_icon.modulate.a = minf(1, reaction_time * 2)
		return
	sprite.rotation = 0
	if decision <= 0 and not controlled:
		decision = 20.0 if baby else randf_range(3, 6)
		if home_interactions and Game.needs.Hunger>=45 and Game.needs.Energy>=30 and randf() < (0.3 if IslandLife.personality(Game)=="Playful" else 0.12) and begin_toy_visit():
			pass
		elif baby:
			target = position + Vector2(randf_range(-30, 30) * (1 + Game.growth_fraction() * 2), randf_range(-5, 5))
			target = target.clamp(bounds.position, bounds.end)
			mood = "A tiny stretch before another nap"
		elif Game.needs.Energy < 20:
			target = WalkArea.destination(walk_area,active_barriers(),IslandLife.home_point(Game,"Rest")) if home_interactions else position
			mood = "A little sleepy"
		elif Game.needs.Hunger < 30:
			target = Vector2(430, 540)
			mood = "Looking for a tasty snack"
		else:
			target = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
			if IslandLife.personality(Game) == "Cuddly":
				target = position + Vector2(randf_range(-45, 45), randf_range(-8, 8))
				decision = randf_range(6, 10)
			elif IslandLife.personality(Game) == "Playful":
				decision = randf_range(2.5, 4)
			mood = {"Curious": "Sniffing for a new discovery", "Cuddly": "Looking for a gentle pat", "Playful": "Looking for a favorite toy"}[IslandLife.personality(Game)]
	if advance_walk(delta):
		var direction = motion_velocity.normalized()
		if carrying_toy:
			reaction_icon.position = Vector2(-45 if direction.x < 0 else 45, -65)
		if footfall_distance >= stride_length() * 0.5:
			footfall_distance = fmod(footfall_distance, stride_length() * 0.5)
			Sound.play_effect("step", -22)
		settle_time = 0.22
		if absf(direction.x)>0.12:
			sprite.flip_h = direction.x < 0
		set_walk_pose()
		var phase = stride_distance / stride_length() * TAU
		sprite.position.y = 0 if Game.reduce_motion else -absf(sin(phase)) * 0.7
		sprite.rotation = 0 if Game.reduce_motion else sin(phase) * 0.005
	else:
		move_speed = 0
		motion_velocity = Vector2.ZERO
		sprite.position.y = 0 if Game.reduce_motion else sin(clock * 2) * 0.5
		sprite.rotation = 0
		settle_time = maxf(0, settle_time - delta)
		if (controlled or settle_time > 0) and not fetch_running:
			set_walk_pose()
		if not controlled: idle_expression(delta)

func active_barriers() -> Array[Rect2]:
	var result: Array[Rect2] = barriers.duplicate()
	if home_interactions and Game.life.bowl:
		result.append(bowl_bounds())
	if bed_barrier.has_area() and not Game.resting and not settling_for_rest and not napping:
		result.append(bed_barrier)
	return result

func advance_walk(delta: float) -> bool:
	var obstacles = active_barriers()
	var goal = WalkArea.destination(walk_area,obstacles,target)
	if goal!=target: target = goal
	if route_goal!=target or route_barriers!=obstacles or (route_points.is_empty() and position.distance_to(target)>1):
		route_points = WalkArea.route(walk_area,obstacles,position,target)
		route_goal = target
		route_barriers = obstacles.duplicate()
	while not route_points.is_empty() and position.distance_to(route_points[0])<=0.35:
		position = route_points.pop_front()
	if position.distance_to(target)<=1 or route_points.is_empty(): return false
	var waypoint = route_points[0]
	var distance = position.distance_to(waypoint)
	var direction = (waypoint-position).normalized()
	var desired_speed = lerpf(45,100,Game.growth_fraction()) if Game.breed=="Puppy" and not controlled else 150.0
	if fetch_running: desired_speed = 210.0
	if controlled and activity_speed>0: desired_speed=activity_speed
	if not controlled and PuppyHealth.unwell(Game):
		desired_speed *= 0.55
		mood = "Taking it gently while recovering"
	# Velocity eases through starts and reversals; each corner brakes before turning.
	var braking_speed = sqrt(2.0*300.0*distance)
	motion_velocity = motion_velocity.move_toward(direction*minf(desired_speed,braking_speed),delta*420.0)
	var movement = motion_velocity*delta
	if movement.length()>distance and movement.dot(direction)>0: movement = direction*distance
	var next = WalkArea.nearest(walk_area,position+movement)
	if not WalkArea.clear_segment(position,next,obstacles,true):
		next = position+direction*minf(distance,movement.length())
		if not WalkArea.clear_segment(position,next,obstacles,true): return false
	var travelled = position.distance_to(next)
	position = next
	move_speed = motion_velocity.length()
	stride_distance += travelled
	footfall_distance += travelled
	return travelled>0.0001

func prepare_walk_frames() -> void:
	dressed_walk = outfit_equipped()
	walk_texture = (Art.DRESSED_WALKS if dressed_walk else Art.WALKS)[Game.breed]
	walk_frames.clear()
	for bounds in (Art.DRESSED_WALK_DATA if dressed_walk else Art.WALK_DATA)[Game.breed].regions:
		walk_frames.append(Rect2(bounds[0],bounds[1],bounds[2],bounds[3]))

func outfit_equipped() -> bool:
	var accessory: String = preview_accessory if not preview_accessory.is_empty() else Game.life.accessory
	return Goods.ITEMS.has(accessory) and Goods.ITEMS[accessory].has("color") and (not preview_accessory.is_empty() or Game.items.get(accessory,0)>0)

func stride_length() -> float:
	return 64.0 if Game.breed == "Puppy" else (84.0 if Game.breed=="Dachshund" else 104.0)

func set_walk_pose() -> void:
	if fetch_running:
		var direction = motion_velocity.normalized()
		run_view = "toward" if direction.y>0.18 else ("away" if direction.y < -0.18 else "side")
		if returning_ball and run_view=="away": run_view="side"
		if run_view!="side":
			set_run_pose(run_view)
			return
	var baby = Game.breed == "Puppy"
	var frame_index = int(fmod(stride_distance / stride_length(), 1.0) * walk_frames.size())
	sprite.texture = walk_texture
	sprite.region_enabled = true
	sprite.region_rect = walk_frames[frame_index]
	sprite.offset.y = -sprite.region_rect.size.y * 0.5
	var data: Dictionary = (Art.DRESSED_WALK_DATA if dressed_walk else Art.WALK_DATA)[Game.breed]
	var anchor: float = data.anchors[frame_index]
	sprite.offset.x = (sprite.region_rect.size.x * 0.5 - anchor) * (-1 if sprite.flip_h else 1)
	base_scale = awake_height() / float(data.height)
	if fetch_running: base_scale *= fetch_perspective()
	sprite.scale = Vector2.ONE * base_scale
	fit_screen_width()

func fetch_perspective() -> float:
	return lerpf(0.93,1.04,clampf((position.y-505.0)/130.0,0,1))

# Muzzle positions within the side and three-quarter gait frames.
const FETCH_MUZZLES = {
	"Puppy":Vector4(.89,.47,.76,.56), "Shiba Inu":Vector4(.91,.34,.79,.46),
	"Golden Retriever":Vector4(.92,.35,.81,.47), "Dachshund":Vector4(.90,.37,.89,.52),
	"Miniature Collie":Vector4(.92,.34,.83,.45), "Beagle":Vector4(.87,.35,.85,.43),
	"Corgi":Vector4(.92,.46,.85,.53), "Toy Poodle":Vector4(.92,.40,.84,.48)
}
const SNIFF_MUZZLES = {
	"Puppy":Vector2(.81,.92), "Shiba Inu":Vector2(.86,.88), "Golden Retriever":Vector2(.85,.88),
	"Dachshund":Vector2(.77,.94), "Miniature Collie":Vector2(.74,.95), "Beagle":Vector2(.69,.94),
	"Corgi":Vector2(.67,.95), "Toy Poodle":Vector2(.65,.94)
}

func fetch_muzzle() -> Vector2:
	var points: Vector4 = FETCH_MUZZLES[Game.breed]
	var uv = Vector2(points.x,points.y) if run_view=="side" else Vector2(points.z,points.w)
	if fetch_mouth_down: uv = SNIFF_MUZZLES[Game.breed]
	if sprite.flip_h: uv.x = 1.0-uv.x
	var rect = sprite.get_rect()
	return get_parent().to_local(sprite.to_global(rect.position+rect.size*uv))

func set_run_pose(angle: String) -> void:
	var frame = int(fmod(stride_distance/stride_length(),1.0)*4)
	show_run_frame(angle,frame,awake_height()*fetch_perspective())

func show_run_frame(angle: String, frame: int, height: float) -> void:
	var dressed = outfit_equipped()
	var data: Dictionary = Art.RUN_DATA[Game.breed]["dressed" if dressed else "bare"][angle]
	var box: Array = data.regions[frame]
	sprite.texture = Art.run_sheet(Game.breed)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(box[0],box[1],box[2],box[3])
	visible_size = sprite.region_rect.size
	sprite.offset = Vector2((box[2]*0.5-float(data.anchors[frame]))*(-1 if sprite.flip_h else 1),-box[3]*0.5)
	sprite.material = style_material if dressed else sleep_material
	if dressed:
		var accessory = preview_accessory if not preview_accessory.is_empty() else Game.life.accessory
		style_material.set_shader_parameter("recolor",true)
		style_material.set_shader_parameter("bandana",Goods.ITEMS[accessory].color)
	base_scale = height/float(data.height)
	sprite.scale = Vector2.ONE*base_scale
	fit_screen_width()

func react_to_care(kind: String) -> void:
	if controlled and not location_portrait:
		return
	action_item_time=0
	if is_instance_valid(action_item): action_item.visible=false
	expression_time = 0
	expression_clock = 0
	welcome_duration = 0.0
	command_delay = 0
	if not arriving_at_decor:
		pending_decor_action = ""
		carrying_toy = false
	if home_interactions and not arriving_at_decor and ((kind == "Feed" and Game.life.bowl) or (kind == "Play" and Game.items.get(Game.life.toy, 0) > 0)):
		var point = meal_approach() if kind=="Feed" else IslandLife.home_point(Game,kind)
		var destination = WalkArea.destination(walk_area,active_barriers(),point)
		if position.distance_to(destination) > 2:
			wake_briefly()
			awake_remaining = maxf(awake_remaining, 30)
			target = destination
			pending_decor_action = kind
			reaction_time = 0
			decision = 30
			if kind=="Feed": mood = "Dinner! Hurrying over for a tasty bowl"
			return
	if kind == "Rest":
		settling_for_rest = false
		var has_bed = Game.items.get(Game.life.bed, 0) > 0
		if home_interactions and Game.resting:
			var rest_point = position
			if has_bed:
				rest_point = IslandLife.home_point(Game,"Rest")
			elif Game.life.bowl and sleep_overlaps_bowl():
				rest_point = beside_bowl()
			target = WalkArea.nearest(walk_area,rest_point)
			settling_for_rest = position.distance_to(target) > 1
			if settling_for_rest:
				wake_briefly()
				reaction_time = 0
				decision = 20
				return
	sleepy_reaction = kind in ["Pet", "Treat"] and ((Game.breed == "Puppy" and napping) or Game.resting)
	if not sleepy_reaction:
		wake_briefly()
	reaction_kind = kind
	if kind in ["Paw","Spin","Bow","Roll Over"]:
		trick_command = kind
		trick_elapsed = 0
	reaction_duration = 3.2 if kind == "Feed" else (3.0 if kind == "Care" else 2.4)
	if kind=="Care" and home_interactions and IslandLife.personality(Game)=="Cuddly":
		reaction_duration=4.2
	if kind == "Pet" and IslandLife.personality(Game) == "Cuddly":
		reaction_duration = 3.5
	reaction_time = reaction_duration
	decision = 4.0
	target = position
	var icon_name: String = {"Feed":"heart", "Pet": "heart", "Treat": "treat", "Sniff": "shell", "Sit": "training_treat", "Stay":"training_treat", "Come": "heart", "Paw":"training_treat", "Spin":"training_treat", "Bow":"training_treat", "Roll Over":"training_treat"}.get(kind, kind.to_lower())
	if kind == "Treat" and Game.last_food == IslandLife.favorite(Game, "Food"):
		icon_name = "heart"
	if kind == "Play" and Game.life.toy == IslandLife.favorite(Game, "Toys") and Game.items.get(Game.life.toy, 0) > 0:
		icon_name = "heart"
	reaction_icon.texture = load("res://assets/manga/ui/" + icon_name + ".svg")
	if kind == "Play" and icon_name != "heart" and Game.items.get(Game.life.toy, 0) > 0:
		reaction_icon.texture = Goods.picture(Game.life.toy)
	reaction_icon.scale = Vector2.ONE * (58.0 / reaction_icon.texture.get_width())
	if kind in ["Care","Treat","Play"]:
		var picture=Goods.picture("Brush" if kind=="Care" else (Game.last_food if kind=="Treat" and Goods.ITEMS.has(Game.last_food) else (Game.life.toy if kind=="Play" and Goods.ITEMS.has(Game.life.toy) and Game.items.get(Game.life.toy,0)>0 else ("Treat" if kind=="Treat" else "Toy"))))
		show_action_item(picture,kind,reaction_duration)
	mood = {"Feed": "Enjoying a tasty snack", "Play": "Wiggling with excitement", "Care": "Feeling fresh and loved", "Rest": "Settling in for a nap", "Pet": "Leaning into a gentle pat", "Treat": "Savoring a little reward", "Sniff": "Sniffing the salty breeze", "Sit": "Trying a patient little sit"}.get(kind, "Enjoying island life")
	if kind in IslandLife.COMMANDS:
		var level = int(Game.life.training.get(kind,0))
		command_delay = float(5-level) * 0.10
		reaction_duration = 2.4 + level * 0.25
		reaction_time = reaction_duration
		mood = ("Confident " if level == 5 else "Practicing ") + kind.to_lower()
	if kind == "Come":
		mood = "Coming when you call"
		target = WalkArea.nearest(walk_area, position + Vector2(55 + int(Game.life.training.Come) * 10, 0))
	if kind == "Rest" and not Game.resting:
		mood = "Ready for a new adventure"

func _draw() -> void:
	if celebration_time>0:
		var rise=0.0 if Game.reduce_motion else (0.9-celebration_time)*12
		var height=visible_size.y*base_scale
		var color=Color(1,1,1,minf(1,celebration_time*3))
		draw_texture_rect(preload("res://assets/manga/ui/heart.svg"),Rect2(Vector2(-12,-height-30-rise),Vector2(24,24)),false,color)
	if discovery_time > 0 and IslandLife.personality(Game) == "Curious":
		for i in 3:
			draw_circle(Vector2(40+i*14,-12-i*9),3,Color(0.4,0.8,0.7,minf(1,discovery_time)))
	if cuddly_settle() and not Game.reduce_motion:
		# A single pair of manga motion marks at the tail, then quiet again.
		if reaction_time>.83 and reaction_time<1.12:
			var tail=Vector2(-visible_size.x*.40,-visible_size.y*.30)*base_scale
			draw_arc(tail,12,PI,PI*1.43,12,UI.INK,2,true)
			draw_arc(tail,18,PI,PI*1.37,12,UI.INK,2,true)
	elif reaction_time > 0 and reaction_kind == "Care" and not controlled and not Game.reduce_motion:
		for i in 5:
			var rise = fmod(reaction_duration - reaction_time + i * 0.35, 1.8)
			var point = Vector2(-55 + i * 27, -25 - rise * 65)
			draw_circle(point, 4 + i % 3, Color(0.7, 0.9, 1, minf(0.8, reaction_time)), false, 2)

func react_to_discovery() -> void:
	discovery_time = 1.8
	mood = {"Curious":"Investigating a new island find", "Cuddly":"Sharing a little discovery with you", "Playful":"Excited about a new treasure"}[IslandLife.personality(Game)]
	if not controlled and not Game.resting:
		react_to_care("Sniff" if IslandLife.personality(Game) == "Curious" else "Pet")
	elif not Game.resting:
		begin_expression("Sniff",1.3)

func begin_toy_visit() -> bool:
	if not home_interactions or controlled or not Game.can_explore() or Game.items.get(Game.life.toy,0) <= 0 or not pending_decor_action.is_empty():
		return false
	wake_briefly()
	awake_remaining = maxf(awake_remaining,30)
	reaction_time = 0
	target = WalkArea.nearest(walk_area,IslandLife.home_point(Game,"Play"))
	pending_decor_action = "ToyVisit"
	decision = 30
	mood = "Fetching a toy to share"
	return true

func show_trick_pose() -> void:
	var frames = Art.trick_frames(Game.breed,trick_command,outfit_equipped())
	if frames.is_empty():
		trick_command = ""
		return
	# Preserve the dog's outfit and size while showing actual new limb poses.
	set_pose(false)
	var phase = trick_elapsed / 3.2
	var order = [0,1,2,1,0] if trick_command == "Paw" else ([0,1,2,0] if trick_command == "Spin" else [0,1,2])
	var index: int = order[mini(order.size()-1,int(phase*order.size()))]
	if Game.reduce_motion:
		index = 1
	if sprite.material == null:
		sprite.material = sleep_material
	sprite.texture = Art.trick_sheet(Game.breed,outfit_equipped())
	sprite.region_enabled = true
	sprite.region_rect = frames[index]
	sprite.offset = Vector2(0,-frames[index].size.y*0.5)
	sprite.flip_h = false
	sprite.position.y = 0
	sprite.rotation = 0
	var height = minf(portrait_width,portrait_height) if presentation_style=="Beach" else awake_height()
	sprite.scale = Vector2.ONE*(height/float((Art.DRESSED_TRICK_DATA if outfit_equipped() else Art.TRICK_DATA)[Game.breed].height))
	reaction_icon.visible = false
