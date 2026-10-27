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

func _ready() -> void:
	shadow = Sprite2D.new()
	shadow.texture = preload("res://assets/puppies/shadow.svg")
	shadow.position.y = -5
	shadow.scale = Vector2(1.5, 1)
	add_child(shadow)
	sprite = Sprite2D.new()
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
	var texture: Texture2D = Art.PUPPY_SLEEP if asleep and Game.breed == "Puppy" else Art.PUPPIES[Game.breed]
	if sprite.texture != texture:
		sprite.texture = texture
		if not pose_bounds.has(texture):
			pose_bounds[texture] = texture.get_image().get_used_rect()
		var visible_rect: Rect2i = pose_bounds[texture]
		sprite.region_enabled = true
		sprite.region_rect = visible_rect
		sprite.offset.x = 0
		sprite.offset.y = -visible_rect.size.y * 0.5
		visible_size = visible_rect.size
	var growth = Game.growth_fraction()
	base_scale = (lerpf(200, 290, growth) / visible_size.x) if asleep and Game.breed == "Puppy" else ((lerpf(180, 280, growth) if Game.breed == "Puppy" else 320.0) / visible_size.y)
	sprite.scale = Vector2.ONE * base_scale

func request_move(point: Vector2) -> void:
	if controlled or Game.resting:
		return
	if Game.breed == "Puppy":
		wake_briefly()
		target = position + (point - position).limit_length(45)
	else:
		target = point
	decision = 4.0

func wake_briefly() -> void:
	nap_remaining = 0
	awake_remaining = lerpf(10, 30, Game.growth_fraction())
	napping = false

func _process(delta: float) -> void:
	if Game.paused_at > 0:
		return
	clock += delta
	decision -= delta
	if current_breed != Game.breed:
		set_breed()
	var baby = Game.breed == "Puppy"
	if baby and not controlled and not Game.resting and reaction_time <= 0:
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
	var asleep = not controlled and (Game.resting or (baby and napping))
	set_pose(asleep)
	if asleep:
		target = position
		move_speed = 0
		mood = "Napping in a cozy little bundle"
		sprite.position.y = 0
		sprite.rotation = 0
		sprite.scale = Vector2(1, 1 + sin(clock * 2) * 0.015) * base_scale
		reaction_time = 0
		reaction_icon.visible = false
		return
	reaction_time = maxf(0, reaction_time - delta)
	queue_redraw()
	reaction_icon.visible = reaction_time > 0
	if reaction_time > 0 and not controlled:
		sprite.flip_h = false
		sprite.rotation = 0
		var bounce = absf(sin(reaction_time * 7))
		match reaction_kind:
			"Feed":
				sprite.position.y = bounce * 3
				sprite.rotation = sin(reaction_time * 5) * 0.035
				reaction_icon.position = Vector2(60, -12)
			"Play":
				sprite.position.y = -bounce * 14
				sprite.rotation = sin(reaction_time * 8) * 0.05
				reaction_icon.position = Vector2(75 + sin(reaction_time * 5) * 15, -20 - bounce * 35)
			"Care":
				sprite.position.y = 0
				reaction_icon.position = Vector2(70, -100)
				queue_redraw()
			_:
				sprite.position.y = 0
				reaction_icon.position = Vector2(70, -100)
		sprite.scale = Vector2(1 + bounce * 0.025, 1 - bounce * 0.025) * base_scale
		reaction_icon.modulate.a = minf(1, reaction_time * 2)
		return
	sprite.rotation = 0
	if decision <= 0 and not controlled:
		decision = 20.0 if baby else randf_range(3, 6)
		if baby:
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
			mood = ["Sniffing the sea breeze", "Chasing a sunbeam", "Exploring with happy paws"].pick_random()
	var distance = position.distance_to(target)
	var moving = distance > 1
	if moving:
		var desired_speed = lerpf(45, 100, Game.growth_fraction()) if baby and not controlled else 150.0
		# Ease into each walk and slow down before the last planted step.
		var braking_speed = sqrt(2.0 * 320.0 * distance)
		move_speed = move_toward(move_speed, minf(desired_speed, braking_speed), delta * 320)
		var step_distance = minf(distance, delta * move_speed)
		var direction = (target - position).normalized()
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
	if controlled:
		return
	wake_briefly()
	reaction_kind = kind
	reaction_duration = 3.2 if kind == "Feed" else (3.0 if kind == "Care" else 2.4)
	reaction_time = reaction_duration
	decision = 4.0
	target = position
	reaction_icon.texture = load("res://assets/ui/" + kind.to_lower() + ".svg")
	reaction_icon.scale = Vector2.ONE * (58.0 / reaction_icon.texture.get_width())
	mood = {"Feed": "Enjoying a tasty snack", "Play": "Wiggling with excitement", "Care": "Feeling fresh and loved", "Rest": "Settling in for a nap"}[kind]
	if kind == "Rest" and not Game.resting:
		mood = "Ready for a new adventure"

func _draw() -> void:
	if reaction_time > 0 and reaction_kind == "Care" and not controlled:
		for i in 5:
			var rise = fmod(reaction_duration - reaction_time + i * 0.35, 1.8)
			var point = Vector2(-55 + i * 27, -25 - rise * 65)
			draw_circle(point, 4 + i % 3, Color(0.7, 0.9, 1, minf(0.8, reaction_time)), false, 2)
