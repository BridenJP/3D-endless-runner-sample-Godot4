extends CharacterBody3D

const SPEED = 8.0 # Running speed
const JUMP_VELOCITY = 4.5  # Determines how high we can jump
const LANE_W = 3.3 # Width is 1/3 of total available
const LANE_CHANGE_SPEED = 10.0  # Speed of lane change, higher is faster

# State trackng
enum State {Running, Jumping, Sliding, Falling}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var lane: int = 0 # Current lane
var target_x: float = 0.0  # Target x position for smooth lane changes
var state: State # Current state

func _ready() -> void:
	update_target_x() # This makes sure we start off in the center lane
	set_state(State.Running) # And we are running
	velocity.z = -SPEED # Always ahead (negative Z direction) with the same speed

func update_target_x() -> void:
	target_x = lane * LANE_W

func _physics_process(delta: float) -> void:
	# We can't do anything else while sliding
	if state != State.Sliding:
		# If we are in the air...
		if not is_on_floor():
			# ... and we WERE running ...
			if state == State.Running:
				# ... then we are now falling!
				set_state(State.Falling)
			# Affected by gravity
			velocity.y -= gravity * delta
		# If we are not in the air ...
		else:
			# ... but were previously ...
			if state == State.Jumping or state == State.Falling:
				# ... go back to running
				set_state(State.Running)

	# Check inputs, but only when running
	if state == State.Running:
		handle_input()

	# Move towards the current lane
	global_transform.origin.x = move_toward(global_transform.origin.x, target_x, LANE_CHANGE_SPEED * delta)
	
	# Handle moving and collisions
	move_and_slide()

	# If we've hit something solid...
	if is_on_wall():
		# Ouch!
		$PlayerModel/AnimationPlayer.play("Hurt")
		# Stop processing
		$SliderTimer.stop()
		set_physics_process(false)
		# Start a timer and then restart the game
		$RestartTimer.start()

func handle_input() -> void:
	# Up = Jump
	if Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VELOCITY
		set_state(State.Jumping)
	# Down = slide
	elif Input.is_action_just_pressed("ui_down"):
		set_state(State.Sliding)
	# Left = switch lanes left
	elif Input.is_action_just_pressed("ui_left") and lane > -1:
		lane -= 1
		update_target_x()
	# Right = switch lanes right
	elif Input.is_action_just_pressed("ui_right") and lane < 1:
		lane += 1
		update_target_x()

# This is our "normal" position and rotation
func set_default_transform() -> void:
	$PlayerModel.set_position(Vector3(0, -0.8, 0))
	$PlayerColl.set_rotation_degrees(Vector3(0, 0, 0))
	$PlayerModel.set_rotation_degrees(Vector3(0, -180, 0))

# This is our special sliding position and rotation
func set_sliding_transform() -> void:
	$PlayerModel.set_position(Vector3(0, -0.6, -0.8))
	$PlayerColl.set_rotation_degrees(Vector3(90, 0, 0))
	$PlayerModel.set_rotation_degrees(Vector3(-20, 90, 90))

# Change of state:
# - Set the appropriate animation and transformation and use the timer for sliding
func set_state(new_state: State) -> void:
	state = new_state
	match state:
		State.Running:
			$PlayerModel/AnimationPlayer.play("Run")
			set_default_transform()
		State.Jumping:
			$PlayerModel/AnimationPlayer.play("Jump")
			set_default_transform()
		State.Sliding:
			$PlayerModel/AnimationPlayer.play("GroundSlide")
			set_sliding_transform()
			$SliderTimer.stop()
			$SliderTimer.start()
		State.Falling:
			$PlayerModel/AnimationPlayer.play("Fall")
			set_default_transform()

# When the slider timer runs out, start running again
func _on_slider_timer_timeout() -> void:
	set_state(State.Running)

