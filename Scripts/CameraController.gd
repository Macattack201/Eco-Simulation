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

	# Sprinting (faster movement when Shift is held)
	if Input.is_action_pressed("camera_down") and !Input.is_action_pressed("camera_up"):
		speed *= sprint_multiplier

	# Lateral movement (WASD)
	if Input.is_action_pressed("camera_forward"):  # W
		direction -= transform.basis.z  # Move forward relative to camera
	if Input.is_action_pressed("camera_backward"):  # S
		direction += transform.basis.z  # Move backward
	if Input.is_action_pressed("camera_left"):  # A
		direction -= transform.basis.x  # Move left
	if Input.is_action_pressed("camera_right"):  # D
		direction += transform.basis.x  # Move right

	# Vertical movement (Space = Up, Shift = Down)
	if Input.is_action_pressed("camera_up"):
		direction.y += 1
	if Input.is_action_pressed("camera_down") and !Input.is_action_pressed("camera_forward") and !Input.is_action_pressed("camera_backward"):
		direction.y -= 1

	# Apply movement without modifying direction
	if direction != Vector3.ZERO:
		velocity = direction.normalized() * speed * delta
		global_transform.origin += velocity

func update_rotation():
	# Apply rotation while maintaining the camera's facing direction
	transform.basis = Basis.from_euler(Vector3(deg_to_rad(rotation_x), deg_to_rad(rotation_y), 0))
