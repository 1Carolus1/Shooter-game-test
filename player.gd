
extends CharacterBody3D

#movement speed
@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5

@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

@export var rotation_speed: float = 10.0

@onready var visuals: Node3D = $Visuals

@onready var camera_pivot: Node3D = $CameraPivot

var gravity: float = 9.8
var camera_pitch: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate the camera horizontally.
		camera_pivot.rotation.y -= (
			event.relative.x * mouse_sensitivity
		)

		# Rotate the camera vertically.
		camera_pitch -= event.relative.y * mouse_sensitivity
		camera_pitch = clampf(
			camera_pitch,
			deg_to_rad(-50.0),
			deg_to_rad(35.0)
		)

		camera_pivot.rotation.x = camera_pitch

	# Press Escape to release the mouse.
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Click the game window to recapture the mouse.
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	# Apply gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Reset horizontal movement each physics frame.
	velocity.x = 0.0
	velocity.z = 0.0
	
	# Choose movement speed.
	var current_speed := move_speed

	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	# Get horizontal directions relative to the camera pivot.
	var forward := -camera_pivot.global_basis.z
	var right := camera_pivot.global_basis.x

	# Ignore the camera's vertical angle.
	forward.y = 0.0
	right.y = 0.0

	forward = forward.normalized()
	right = right.normalized()

	# W and S: forward and backward.
	if Input.is_action_pressed("move_forward"):
		velocity.x += forward.x * current_speed
		velocity.z += forward.z * current_speed

	if Input.is_action_pressed("move_backward"):
		velocity.x -= forward.x * current_speed
		velocity.z -= forward.z * current_speed

	# D and A: right and left.
	if Input.is_action_pressed("move_right"):
		velocity.x += right.x * current_speed
		velocity.z += right.z * current_speed

	if Input.is_action_pressed("move_left"):
		velocity.x -= right.x * current_speed
		velocity.z -= right.z * current_speed

	# Prevent diagonal movement from being faster.
	var horizontal_velocity := Vector2(
		velocity.x,
		velocity.z
	)

	if horizontal_velocity.length() > current_speed:
		horizontal_velocity = (
			horizontal_velocity.normalized() * current_speed
		)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.y

		# Rotate the character toward the movement direction.
	var move_direction := Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	if move_direction.length_squared() > 0.001:
		var target_angle := atan2(
			move_direction.x,
			move_direction.z
		)

		visuals.rotation.y = rotate_toward(
			visuals.rotation.y,
			target_angle,
			rotation_speed * delta
		)
	# Apply movement and collisions.
	move_and_slide()
