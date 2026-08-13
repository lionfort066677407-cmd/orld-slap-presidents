extends Node3D

# ============================================================
# WORLD SLAP PRESIDENTS
# Prototype 0.2
# Godot 4.x
#
# CONGO 🇨🇬 VS NIGERIA 🇳🇬
# ============================================================

const MAX_HEALTH := 100.0
const MAX_ROUNDS := 6
const ROUND_TIME := 10.0
const SLAP_DISTANCE := 3.0
const PLAYER_SPEED := 4.0
const AI_SPEED := 2.0

var congo_health := MAX_HEALTH
var nigeria_health := MAX_HEALTH

var current_round := 1
var round_time := ROUND_TIME

var game_over := false
var round_active := true

var congo_power := 0.0
var congo_charging := false

var nigeria_attack_timer := 1.5

var congo: CharacterBody3D
var nigeria: CharacterBody3D

var camera: Camera3D

var congo_health_bar: ProgressBar
var nigeria_health_bar: ProgressBar

var round_label: Label
var timer_label: Label
var result_label: Label
var instruction_label: Label

var power_bar: ProgressBar
var restart_button: Button


func _ready() -> void:
	_create_world()
	_create_fighters()
	_create_camera()
	_create_ui()
	_update_ui()


func _create_world() -> void:

	var light := DirectionalLight3D.new()
	light.name = "ArenaLight"
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.5
	add_child(light)

	var environment := WorldEnvironment.new()
	environment.name = "Environment"

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.04)

	environment.environment = env
	add_child(environment)

	var floor := StaticBody3D.new()
	floor.name = "ArenaFloor"
	add_child(floor)

	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "FloorMesh"

	var plane := BoxMesh.new()
	plane.size = Vector3(20, 0.5, 20)

	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.25

	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.08, 0.08, 0.08)

	floor_mesh.material_override = floor_material
	floor.add_child(floor_mesh)

	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()

	floor_shape.size = Vector3(20, 0.5, 20)

	floor_collision.shape = floor_shape
	floor_collision.position.y = -0.25

	floor.add_child(floor_collision)


func _create_fighters() -> void:

	congo = _create_fighter(
		"President_Congo",
		Vector3(-2.5, 1, 0),
		Color(0.05, 0.65, 0.25)
	)

	nigeria = _create_fighter(
		"President_Nigeria",
		Vector3(2.5, 1, 0),
		Color(0.05, 0.70, 0.25)
	)


func _create_fighter(
	fighter_name: String,
	position: Vector3,
	color: Color
) -> CharacterBody3D:

	var fighter := CharacterBody3D.new()

	fighter.name = fighter_name
	fighter.position = position

	add_child(fighter)

	var mesh := MeshInstance3D.new()
	mesh.name = "Body"

	var capsule := CapsuleMesh.new()
	capsule.radius = 0.5
	capsule.height = 2.0

	mesh.mesh = capsule

	var material := StandardMaterial3D.new()
	material.albedo_color = color

	mesh.material_override = material
	fighter.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()

	shape.radius = 0.5
	shape.height = 2.0

	collision.shape = shape

	fighter.add_child(collision)

	return fighter


func _create_camera() -> void:

	camera = Camera3D.new()
	camera.name = "MainCamera"

	camera.position = Vector3(0, 5.5, 10)

	add_child(camera)

	camera.look_at(
		Vector3(0, 1, 0)
	)


func _process(delta: float) -> void:

	if game_over:
		return

	if not round_active:
		return

	round_time -= delta
	nigeria_attack_timer -= delta

	_player_input(delta)
	_nigeria_ai()
	_face_opponents()

	if round_time <= 0.0:
		_end_round()

	_update_ui()


func _player_input(delta: float) -> void:

	var direction := Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		direction.z -= 1.0

	if Input.is_key_pressed(KEY_S):
		direction.z += 1.0

	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0

	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0

	if direction.length() > 0:

		direction = direction.normalized()

		congo.velocity = direction * PLAYER_SPEED

		congo.move_and_slide()

	else:

		congo.velocity = Vector3.ZERO


	if Input.is_action_pressed("slap"):

		if not congo_charging:
			congo_charging = true

		congo_power += delta * 80.0

		congo_power = clamp(
			congo_power,
			0.0,
			100.0
		)


	if (
		congo_charging
		and Input.is_action_just_released("slap")
	):

		_slap(
			congo,
			nigeria,
			congo_power
		)

		congo_power = 0.0
		congo_charging = false


func _nigeria_ai() -> void:

	var distance := nigeria.position.distance_to(
		congo.position
	)

	if distance > SLAP_DISTANCE:

		var direction := (
			congo.position -
			nigeria.position
		)

		direction.y = 0

		if direction.length() > 0:

			direction = direction.normalized()

			nigeria.velocity = direction * AI_SPEED

			nigeria.move_and_slide()

	else:

		nigeria.velocity = Vector3.ZERO

		if nigeria_attack_timer <= 0.0:

			var power := randf_range(
				30.0,
				100.0
			)

			_slap(
				nigeria,
				congo,
				power
			)

			nigeria_attack_timer = 2.0


func _slap(
	attacker: CharacterBody3D,
	target: CharacterBody3D,
	power: float
) -> void:

	if not round_active:
		return

	var distance := attacker.position.distance_to(
		target.position
	)

	if distance > SLAP_DISTANCE:
		return

	var damage := 5.0 + power * 0.35

	if target == congo:

		congo_health = max(
			0.0,
			congo_health - damage
		)

	else:

		nigeria_health = max(
			0.0,
			nigeria_health - damage
		)

	var direction := (
		target.position -
		attacker.position
	)

	direction.y = 0

	if direction.length() > 0:

		direction = direction.normalized()

		target.velocity = (
			direction *
			(power * 0.04)
		)

		target.move_and_slide()

	_check_knockout()


func _face_opponents() -> void:

	if not congo:
		return

	if not nigeria:
		return

	congo.look_at(
		Vector3(
			nigeria.position.x,
			congo.position.y,
			nigeria.position.z
		)
	)

	nigeria.look_at(
		Vector3(
			congo.position.x,
			nigeria.position.y,
			congo.position.z
		)
	)


func _check_knockout() -> void:

	if congo_health <= 0:

		_finish_match(
			"🇳🇬 NIGERIA WINS!"
		)

	elif nigeria_health <= 0:

		_finish_match(
			"🇨🇬 CONGO WINS!"
		)


func _end_round() -> void:

	round_active = false

	await get_tree().create_timer(1.0).timeout

	if game_over:
		return

	if current_round >= MAX_ROUNDS:

		_finish_after_six_rounds()

		return

	current_round += 1
	round_time = ROUND_TIME
	round_active = true


func _finish_after_six_rounds() -> void:

	if congo_health > nigeria_health:

		_finish_match(
			"🇨🇬 CONGO WINS!"
		)

	elif nigeria_health > congo_health:

		_finish_match(
			"🇳🇬 NIGERIA WINS!"
		)

	else:

		_finish_match(
			"DRAW!"
		)


func _finish_match(message: String) -> void:

	game_over = true
	round_active = false

	result_label.text = (
		"GAME OVER\n\n" +
		message
	)

	result_label.visible = true
	restart_button.visible = true


func _create_ui() -> void:

	var canvas := CanvasLayer.new()

	canvas.name = "GameUI"
	add_child(canvas)


	var title := Label.new()

	title.text = "WORLD SLAP PRESIDENTS"

	title.position = Vector2(420, 20)

	title.add_theme_font_size_override(
		"font_size",
		32
	)

	canvas.add_child(title)


	round_label = Label.new()

	round_label.position = Vector2(570, 70)

	round_label.add_theme_font_size_override(
		"font_size",
		26
	)

	canvas.add_child(round_label)


	timer_label = Label.new()

	timer_label.position = Vector2(600, 110)

	timer_label.add_theme_font_size_override(
		"font_size",
		25
	)

	canvas.add_child(timer_label)


	var congo_label := Label.new()

	congo_label.text = "🇨🇬 CONGO"

	congo_label.position = Vector2(150, 70)

	congo_label.add_theme_font_size_override(
		"font_size",
		24
	)

	canvas.add_child(congo_label)


	congo_health_bar = _create_health_bar(
		canvas,
		Vector2(120, 110)
	)


	var nigeria_label := Label.new()

	nigeria_label.text = "🇳🇬 NIGERIA"

	nigeria_label.position = Vector2(1000, 70)

	nigeria_label.add_theme_font_size_override(
		"font_size",
		24
	)

	canvas.add_child(nigeria_label)


	nigeria_health_bar = _create_health_bar(
		canvas,
		Vector2(950, 110)
	)


	instruction_label = Label.new()

	instruction_label.text = (
		"WASD = Déplacement\n" +
		"ESPACE = Charger / Relâcher = GIFLE"
	)

	instruction_label.position = Vector2(470, 650)

	instruction_label.add_theme_font_size_override(
		"font_size",
		20
	)

	canvas.add_child(instruction_label)


	power_bar = _create_power_bar(canvas)


	result_label = Label.new()

	result_label.position = Vector2(450, 300)

	result_label.add_theme_font_size_override(
		"font_size",
		40
	)

	result_label.visible = false

	canvas.add_child(result_label)


	restart_button = Button.new()

	restart_button.text = "REJOUER"

	restart_button.position = Vector2(540, 450)

	restart_button.size = Vector2(180, 60)

	restart_button.visible = false

	restart_button.pressed.connect(
		_restart_game
	)

	canvas.add_child(restart_button)


func _create_health_bar(
	canvas: CanvasLayer,
	pos: Vector2
) -> ProgressBar:

	var bar := ProgressBar.new()

	bar.position = pos

	bar.size = Vector2(300, 30)

	bar.max_value = MAX_HEALTH

	bar.value = MAX_HEALTH

	bar.show_percentage = false

	canvas.add_child(bar)

	return bar


func _create_power_bar(
	canvas: CanvasLayer
) -> ProgressBar:

	var bar := ProgressBar.new()

	bar.position = Vector2(520, 600)

	bar.size = Vector2(250, 25)

	bar.max_value = 100

	bar.value = 0

	bar.show_percentage = true

	canvas.add_child(bar)

	return bar


func _update_ui() -> void:

	if congo_health_bar:
		congo_health_bar.value = congo_health

	if nigeria_health_bar:
		nigeria_health_bar.value = nigeria_health

	if round_label:

		round_label.text = (
			"ROUND %d / %d"
			% [
				current_round,
				MAX_ROUNDS
			]
		)

	if timer_label:

		timer_label.text = (
			"%.1f"
			% max(
				round_time,
				0.0
			)
		)

	if power_bar:
		power_bar.value = congo_power


func _restart_game() -> void:

	get_tree().reload_current_scene()
