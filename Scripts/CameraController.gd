extends Node3D

@export var move_speed: float = 10.0  # Normal movement speed
@export var sprint_multiplier: float = 2.0  # Speed boost when sprinting
@export var mouse_sensitivity: float = 0.2  # Mouse look sensitivity

var rotation_enabled: bool = false
var velocity: Vector3 = Vector3.ZERO
var rotation_x: float = 0.0
var rotation_y: float = 0.0

@onready var camera = $Camera3D  # Reference to the Camera3D node

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Mouse visible by default

func _input(event):
	# Enable/Disable Rotation with Right Mouse Button
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotation_enabled = event.pressed
			if rotation_enabled:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Hide mouse
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Show mouse again

	# Handle Mouse Movement (Rotation)
	if event is InputEventMouseMotion and rotation_enabled:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, -90, 90)  # Prevent camera flipping

func _process(delta):
	handle_movement(delta)
	update_rotation()

func handle_movement(delta):
	var direction = Vector3.ZERO
	var speed = move_speed

	if Input.is_action_pressed("camera_down") and !Input.is_action_pressed("camera_up"):
		speed *= sprint_multiplier

	if Input.is_action_pressed("camera_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("camera_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("camera_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("camera_right"):
		direction += transform.basis.x

	if Input.is_action_pressed("camera_up"):
		direction.y += 1
	if Input.is_action_pressed("camera_down") and !Input.is_action_pressed("camera_forward") and !Input.is_action_pressed("camera_backward"):
		direction.y -= 1

	if direction != Vector3.ZERO:
		velocity = direction.normalized() * speed * delta
		global_transform.origin += velocity

func update_rotation():
	transform.basis = Basis.from_euler(Vector3(deg_to_rad(rotation_x), deg_to_rad(rotation_y), 0))
