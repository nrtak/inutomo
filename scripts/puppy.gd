class_name PuppyActor
extends Node2D

var sprite: Sprite2D
var shadow: Sprite2D
var target = Vector2(640, 550)
var bounds = Rect2(390, 510, 460, 40)
var mood = "Sniffing the sea breeze"
var clock = 0.0
var decision = 3.0
var controlled = false
var base_scale = 1.0

func _ready() -> void:
	shadow = Sprite2D.new()
	shadow.texture = preload("res://assets/puppies/shadow.svg")
	shadow.position.y = -5
	shadow.scale = Vector2(1.5, 1)
	add_child(shadow)
	sprite = Sprite2D.new()
	add_child(sprite)
	set_breed()
	position = Vector2(640, 550)

func set_breed() -> void:
	sprite.texture = Art.PUPPIES[Game.breed]
	sprite.offset.y = -sprite.texture.get_height() * 0.5
	base_scale = 320.0 / float(sprite.texture.get_height())
	sprite.scale = Vector2.ONE * base_scale

func _process(delta: float) -> void:
	clock += delta
	decision -= delta
	if sprite.texture != Art.PUPPIES[Game.breed]:
		set_breed()
	if Game.resting and not controlled:
		mood = "Dreaming of tiny adventures"
		sprite.rotation = 0.08
		sprite.scale = Vector2(1, 0.9 + sin(clock * 2) * 0.02) * base_scale
		return
	sprite.rotation = 0
	if decision <= 0 and not controlled:
		decision = randf_range(3, 6)
		if Game.needs.Energy < 20:
			target = position
			mood = "A little sleepy"
		elif Game.needs.Hunger < 30:
			target = Vector2(430, 540)
			mood = "Looking for a tasty snack"
		else:
			target = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
			mood = ["Sniffing the sea breeze", "Chasing a sunbeam", "Exploring with happy paws"].pick_random()
	var moving = position.distance_to(target) > 3
	if moving:
		var go_left = target.x < position.x
		position = position.move_toward(target, delta * 150)
		sprite.flip_h = go_left
	sprite.position.y = sin(clock * (12 if moving else 3)) * (5 if moving else 2)
	sprite.scale = Vector2.ONE * base_scale
