class_name PuppyActor
extends Node2D

var sprite: Sprite2D
var shadow: Sprite2D
var walk_area = PackedVector2Array()
var target = Vector2(640, 550):
	set(value):
		target = WalkArea.nearest(walk_area, value)
var bounds = Rect2(390, 510, 460, 40)
var mood = "Sniffing the sea breeze"
var clock = 0.0
var decision = 3.0
var controlled = false
var base_scale = 1.0
var location_portrait = false
var reaction_time = 0.0
var reaction_kind = ""
var nap_remaining = 65.0
var awake_remaining = 0.0
var napping = true
var current_breed = ""
var visible_size = Vector2.ONE
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
var preview_accessory = ""
var carrying_toy = false
var discovery_time = 0.0
var command_delay = 0.0
var home_interactions = false
var pending_decor_action = ""
var arriving_at_decor = false
var settling_for_rest = false

func _ready() -> void:
	shadow = Sprite2D.new()
	shadow.texture = preload("res://assets/puppies/shadow.svg")
	shadow.position.y = -5
	shadow.scale = Vector2(1.5, 1)
	add_child(shadow)
	sprite = Sprite2D.new()
	sleep_material = ShaderMaterial.new()
	sleep_material.shader = preload("res://scripts/sleep_cutout.gdshader")
	style_material = ShaderMaterial.new()
	style_material.shader = preload("res://scripts/dog_style.gdshader")
	add_child(sprite)
	reaction_icon = Sprite2D.new()
	reaction_icon.position = Vector2(125, -180)
	reaction_icon.visible = false
	add_child(reaction_icon)
	Game.care_performed.connect(react_to_care)
	set_breed()
	position = Vector2(640, 550)

func set_breed() -> void:
	current_breed = Game.breed
	prepare_walk_frames()
	var baby = Game.breed == "Puppy"
	shadow.scale = Vector2(0.85, 0.65) if baby else Vector2(1.5, 1)
	reaction_icon.position = Vector2(75, -100) if baby else Vector2(125, -180)
	set_pose(false)

func set_pose(asleep: bool) -> void:
	var texture: Texture2D = Art.SLEEP_TEXTURES[Game.breed] if asleep else Art.PUPPIES[Game.breed]
	sprite.material = sleep_material if asleep and Game.breed != "Puppy" else null
	var accessory: String = preview_accessory if not preview_accessory.is_empty() else Game.life.accessory
	if Goods.ITEMS.has(accessory) and Goods.ITEMS[accessory].has("color") and (not preview_accessory.is_empty() or Game.items.get(accessory, 0) > 0):
		style_material.set_shader_parameter("bandana", Goods.ITEMS[accessory].color)
		style_material.set_shader_parameter("recolor", true)
		style_material.set_shader_parameter("sleeping_cutout", asleep and Game.breed != "Puppy")
		sprite.material = style_material
	if sprite.texture != texture:
		sprite.texture = texture
		if not pose_bounds.has(texture):
			pose_bounds[texture] = Art.SLEEP_REGIONS[Game.breed] if asleep else texture.get_image().get_used_rect()
		var visible_rect: Rect2i = pose_bounds[texture]
		sprite.region_enabled = true
		sprite.region_rect = visible_rect
		sprite.offset.x = 0
		sprite.offset.y = -visible_rect.size.y * 0.5
		visible_size = visible_rect.size
	var growth = Game.growth_fraction()
	if asleep:
		base_scale = (lerpf(200, 290, growth) if Game.breed == "Puppy" else 390.0) / visible_size.x
	else:
		base_scale = (lerpf(180, 280, growth) if Game.breed == "Puppy" else 320.0) / visible_size.y
	sprite.scale = Vector2.ONE * base_scale

func request_move(point: Vector2) -> void:
	if controlled or Game.resting:
		return
	if Game.breed == "Puppy":
		wake_briefly()
		target = position + (point - position).limit_length(45)
	else:
		target = point
	pending_decor_action = ""
	carrying_toy = false
	decision = 4.0

func wake_briefly() -> void:
	nap_remaining = 0
	awake_remaining = lerpf(10, 30, Game.growth_fraction())
	napping = false

func _process(delta: float) -> void:
	if Game.paused_at > 0:
		return
	if location_portrait:
		if current_breed != Game.breed:
			set_breed()
		clock += delta
		napping = Game.resting
		set_pose(Game.resting)
		reaction_time = maxf(0,reaction_time-delta)
		reaction_icon.visible = reaction_time > 0
		sprite.position.y = 0 if Game.reduce_motion else sin(clock*2)*0.7
		if reaction_icon.visible:
			reaction_icon.position = Vector2(35,-125)
			reaction_icon.modulate.a = minf(1,reaction_time*2)
			sprite.rotation = 0 if Game.reduce_motion else sin(reaction_time*4)*0.015
		else:
			sprite.rotation = 0
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
	if asleep:
		target = position
		move_speed = 0
		mood = "Napping in a cozy little bundle"
		sprite.position.y = 0
		sprite.rotation = 0
		sprite.scale = Vector2(1, 1 + sin(clock * 2) * 0.015) * base_scale
		reaction_time = maxf(0, reaction_time - delta)
		reaction_icon.visible = sleepy_reaction and reaction_time > 0
		if reaction_icon.visible:
			reaction_icon.position = Vector2(35, -125 - sin(clock * 3) * 5)
			reaction_icon.modulate.a = minf(1, reaction_time * 2)
			sprite.rotation = sin(clock * 4) * 0.018
			mood = "A sleepy little nuzzle" if reaction_kind == "Pet" else "A sleepy nibble, then back to dreaming"
		else:
			sleepy_reaction = false
		return
	reaction_time = maxf(0, reaction_time - delta)
	queue_redraw()
	reaction_icon.visible = reaction_time > 0 or carrying_toy
	if reaction_time > 0 and not controlled and (reaction_kind != "Come" or position.distance_to(target) < 1):
		sprite.flip_h = false
		sprite.rotation = 0
		var bounce = absf(sin(reaction_time * 7))
		match reaction_kind:
			"Feed":
				sprite.position.y = bounce * 3
				sprite.rotation = sin(reaction_time * 5) * 0.035
				reaction_icon.position = Vector2(60, -12)
			"Play":
				sprite.position.y = -bounce * (18 if IslandLife.personality(Game) == "Playful" else 14)
				sprite.rotation = sin(reaction_time * 8) * 0.05
				reaction_icon.position = Vector2(75 + sin(reaction_time * 5) * 15, -20 - bounce * 35)
			"Care":
				sprite.position.y = 0
				reaction_icon.position = Vector2(70, -100)
				queue_redraw()
			"Pet", "Treat":
				sprite.position.y = -bounce * (0.5 if PuppyHealth.unwell(Game) else (4 if IslandLife.personality(Game) == "Playful" else 2))
				sprite.rotation = (0.045 if reaction_kind == "Pet" and IslandLife.personality(Game) == "Cuddly" else 0) + sin(reaction_time * 5) * 0.025
				reaction_icon.position = Vector2(50, -120 - bounce * 8)
			"Sniff", "Sit", "Stay":
				var steadiness = 1.0 - float(Game.life.training.get(reaction_kind,0)) / 5.0
				sprite.position.y = bounce * (2 if reaction_kind == "Sniff" else 2 * steadiness)
				sprite.rotation = sin(reaction_time * 3) * 0.02 * (1.0 if reaction_kind == "Sniff" else steadiness)
				reaction_icon.position = Vector2(65, -90)
			_:
				sprite.position.y = 0
				reaction_icon.position = Vector2(70, -100)
		sprite.scale = Vector2(1 + bounce * 0.025, 1 - bounce * 0.025) * base_scale
		reaction_icon.modulate.a = minf(1, reaction_time * 2)
		return
	sprite.rotation = 0
	if decision <= 0 and not controlled:
		decision = 20.0 if baby else randf_range(3, 6)
		if home_interactions and IslandLife.personality(Game) == "Playful" and randf() < 0.3 and begin_toy_visit():
			pass
		elif baby:
			target = position + Vector2(randf_range(-30, 30) * (1 + Game.growth_fraction() * 2), randf_range(-5, 5))
			target = target.clamp(bounds.position, bounds.end)
			mood = "A tiny stretch before another nap"
		elif Game.needs.Energy < 20:
			target = position
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
	var distance = position.distance_to(target)
	var moving = distance > 1
	if moving:
		var desired_speed = lerpf(45, 100, Game.growth_fraction()) if baby and not controlled else 150.0
		if not controlled and PuppyHealth.unwell(Game):
			desired_speed *= 0.55
			mood = "Taking it gently while recovering"
		# Ease into each walk and slow down before the last planted step.
		var braking_speed = sqrt(2.0 * 320.0 * distance)
		move_speed = move_toward(move_speed, minf(desired_speed, braking_speed), delta * 320)
		var step_distance = minf(distance, delta * move_speed)
		var direction = (target - position).normalized()
		if carrying_toy:
			reaction_icon.position = Vector2(-45 if direction.x < 0 else 45, -65)
		position = WalkArea.nearest(walk_area, position + direction * step_distance)
		stride_distance += step_distance
		footfall_distance += step_distance
		if footfall_distance >= stride_length() * 0.5:
			footfall_distance = fmod(footfall_distance, stride_length() * 0.5)
			Sound.play_effect("step", -22)
		settle_time = 0.22
		sprite.flip_h = direction.x < 0
		set_walk_pose()
		var phase = stride_distance / stride_length() * TAU
		sprite.position.y = -absf(sin(phase)) * 0.7
		sprite.rotation = sin(phase) * 0.005
	else:
		move_speed = 0
		stride_distance = 0
		sprite.position.y = sin(clock * 2) * 0.5
		sprite.rotation = 0
		settle_time = maxf(0, settle_time - delta)
		if controlled or settle_time > 0:
			set_walk_pose()

func prepare_walk_frames() -> void:
	walk_texture = Art.WALKS[Game.breed]
	walk_frames.clear()
	for region in Art.WALK_REGIONS[Game.breed]:
		walk_frames.append(region)

func stride_length() -> float:
	return 100.0 if Game.breed == "Puppy" else 160.0

func set_walk_pose() -> void:
	var baby = Game.breed == "Puppy"
	var frame_index = int(fmod(stride_distance / stride_length(), 1.0) * walk_frames.size())
	sprite.texture = walk_texture
	sprite.region_enabled = true
	sprite.region_rect = walk_frames[frame_index]
	sprite.offset.y = -sprite.region_rect.size.y * 0.5
	var anchor: float = Art.WALK_ANCHORS[Game.breed][frame_index]
	sprite.offset.x = (sprite.region_rect.size.x * 0.5 - anchor) * (-1 if sprite.flip_h else 1)
	base_scale = (lerpf(180, 280, Game.growth_fraction()) if baby else 320.0) / float(Art.WALK_HEIGHTS[Game.breed])
	sprite.scale = Vector2.ONE * base_scale

func react_to_care(kind: String) -> void:
	if controlled and not location_portrait:
		return
	command_delay = 0
	if not arriving_at_decor:
		pending_decor_action = ""
		carrying_toy = false
	if home_interactions and not arriving_at_decor and ((kind == "Feed" and Game.life.bowl) or (kind == "Play" and Game.items.get(Game.life.toy, 0) > 0)):
		var destination = WalkArea.nearest(walk_area, IslandLife.home_point(Game, kind))
		if position.distance_to(destination) > 2:
			wake_briefly()
			awake_remaining = maxf(awake_remaining, 30)
			target = destination
			pending_decor_action = kind
			reaction_time = 0
			decision = 30
			return
	if kind == "Rest":
		settling_for_rest = false
		if home_interactions and Game.resting and Game.items.get(Game.life.bed, 0) > 0:
			target = WalkArea.nearest(walk_area, Vector2([550.0, 650.0, 760.0][Game.life.spot], 505))
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
	reaction_duration = 3.2 if kind == "Feed" else (3.0 if kind == "Care" else 2.4)
	if kind == "Pet" and IslandLife.personality(Game) == "Cuddly":
		reaction_duration = 3.5
	reaction_time = reaction_duration
	decision = 4.0
	target = position
	var icon_name: String = {"Pet": "heart", "Treat": "treat", "Sniff": "shell", "Sit": "training_treat", "Stay":"training_treat", "Come": "heart"}.get(kind, kind.to_lower())
	if kind == "Treat" and Game.last_food == IslandLife.favorite(Game, "Food"):
		icon_name = "heart"
	if kind == "Play" and Game.life.toy == IslandLife.favorite(Game, "Toys") and Game.items.get(Game.life.toy, 0) > 0:
		icon_name = "heart"
	reaction_icon.texture = load("res://assets/ui/" + icon_name + ".svg")
	if kind == "Play" and icon_name != "heart" and Game.items.get(Game.life.toy, 0) > 0:
		reaction_icon.texture = Goods.picture(Game.life.toy)
	reaction_icon.scale = Vector2.ONE * (58.0 / reaction_icon.texture.get_width())
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
	if discovery_time > 0 and IslandLife.personality(Game) == "Curious":
		for i in 3:
			draw_circle(Vector2(40+i*14,-12-i*9),3,Color(0.4,0.8,0.7,minf(1,discovery_time)))
	if reaction_time > 0 and reaction_kind == "Care" and not controlled:
		for i in 5:
			var rise = fmod(reaction_duration - reaction_time + i * 0.35, 1.8)
			var point = Vector2(-55 + i * 27, -25 - rise * 65)
			draw_circle(point, 4 + i % 3, Color(0.7, 0.9, 1, minf(0.8, reaction_time)), false, 2)

func react_to_discovery() -> void:
	discovery_time = 1.8
	mood = {"Curious":"Investigating a new island find", "Cuddly":"Sharing a little discovery with you", "Playful":"Excited about a new treasure"}[IslandLife.personality(Game)]
	if not controlled and not Game.resting:
		react_to_care("Sniff" if IslandLife.personality(Game) == "Curious" else "Pet")

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
