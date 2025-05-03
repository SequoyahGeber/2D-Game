extends CharacterBody3D

# Movement Variables
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5 # How high the player jumps

# Get the gravity from the project settings to be synced with RigidBody nodes.
# You can also set a specific float value here if you prefer.
var gravity: float = 25

# Camera Look Variables
@export var mouse_sensitivity: float = 0.005 # Adjust sensitivity as needed (radians per pixel)
@export var min_pitch_degrees: float = -89.0 # How far down the player can look
@export var max_pitch_degrees: float = 89.0 # How far up the player can look

# !!! IMPORTANT: Drag your CameraPivot node here in the Inspector !!!
@export var camera_pivot_path: NodePath

@onready var camera_pivot: Node3D = get_node_or_null(camera_pivot_path)

# Using _ prefix convention for "private" variables
var _min_pitch_rad: float
var _max_pitch_rad: float

func _ready() -> void:
	# Check if the camera pivot node was correctly assigned and found
	if not camera_pivot:
		push_error("Camera Pivot node not found! Please assign the correct NodePath in the Inspector for the player script.")
		set_process(false) # Stop processing if pivot is missing
		return

	# Hide and capture the mouse cursor to control the camera
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Convert clamp degrees to radians for internal calculations
	_min_pitch_rad = deg_to_rad(min_pitch_degrees)
	_max_pitch_rad = deg_to_rad(max_pitch_degrees)


func _unhandled_input(event: InputEvent) -> void:
	# Handle mouse motion only if the cursor is captured
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if camera_pivot: # Double-check pivot exists
			# Horizontal rotation: Rotate the entire CharacterBody3D around the Y axis
			self.rotate_y(-event.relative.x * mouse_sensitivity)

			# Vertical rotation: Rotate only the CameraPivot node around its local X axis
			camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)

			# Clamp the vertical rotation (pitch)
			camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, _min_pitch_rad, _max_pitch_rad)

	# Allow releasing the cursor with the Escape key (default "ui_cancel" action)
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void: # Renamed _delta to delta
	# --- Vertical Movement (Gravity and Jump) ---
	# Apply gravity. Velocity accumulates downwards ONLY if not on the floor.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# If on the floor, maybe reset vertical velocity slightly below zero
		# to help stick to slopes, or just set to 0.
		# velocity.y = -0.1 # Optional slight downward force
		pass # Or do nothing if already grounded

	# Handle Jump. Check for input *after* checking if on floor.
	# Input.is_action_just_pressed() ensures jump only triggers once per press.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity # Apply the jump impulse

	# --- Horizontal Movement ---

	# Get input direction for horizontal movement
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Calculate direction based on player's orientation
	var direction: Vector3 = (transform.basis.z * input_dir.y + transform.basis.x * input_dir.x).normalized()

	# Apply horizontal velocity
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Smoothly stop horizontal movement
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# --- Apply Movement ---
	move_and_slide()
