extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float

var was_airborne: bool = false
var w_key_was_pressed: bool = false
var is_attacking: bool = false


# Remove old procedural Visual node if present
func _ready():
	var frames = load("res://player_sprites.tres")
	$AnimatedSprite2D.sprite_frames = frames
	# Remove procedural Visual if it exists
	if has_node("Visual"):
		get_node("Visual").queue_free()

	# Ensure an AnimatedSprite2D is present
	var anim: AnimatedSprite2D
	if has_node("AnimatedSprite2D"):
		anim = get_node("AnimatedSprite2D")
	else:
		anim = AnimatedSprite2D.new()
		anim.name = "AnimatedSprite2D"
		add_child(anim)

	# Scale is now set in the scene file
	
	# Set initial animation
	anim.play("idle")

func _physics_process(delta):
	var vel: Vector2 = velocity
	if not is_on_floor():
		vel.y += gravity * delta

	# WASD + Arrow key input
	var left_pressed = Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var right_pressed = Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	
	var dir = 0
	if left_pressed:
		dir -= 1
	if right_pressed:
		dir += 1
	
	if dir != 0:
		vel.x = dir * SPEED
		# Flip sprite when moving left
		$AnimatedSprite2D.flip_h = dir < 0
	else:
		vel.x = move_toward(vel.x, 0, SPEED)

	# Jump input - detect just pressed for W key
	var jump_pressed = Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")
	if Input.is_key_pressed(KEY_W):
		if not w_key_was_pressed:
			jump_pressed = true
	w_key_was_pressed = Input.is_key_pressed(KEY_W)

	if jump_pressed and is_on_floor():
		vel.y = JUMP_VELOCITY

	# Attack input - left mouse button
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not is_attacking:
			is_attacking = true
			$AnimatedSprite2D.play("attack")
			# Connect to animation finished signal to end attack
			if not $AnimatedSprite2D.animation_finished.is_connected(_on_attack_animation_finished):
				$AnimatedSprite2D.animation_finished.connect(_on_attack_animation_finished)

	# Update physics first
	velocity = vel
	move_and_slide()

	# Handle animations after physics update
	handle_animations()

func handle_animations():
	# Don't change animations while attacking
	if is_attacking:
		return
		
	var on_floor = is_on_floor()
	
	if not on_floor:
		# Airborne
		was_airborne = true
		if velocity.y < 0:
			$AnimatedSprite2D.play("jump")
		else:
			$AnimatedSprite2D.play("fall")
	else:
		# On ground
		if was_airborne:
			# Just landed - play ground animation
			was_airborne = false
			$AnimatedSprite2D.play("ground")
			# Connect to animation finished signal to transition to idle
			if not $AnimatedSprite2D.animation_finished.is_connected(_on_ground_animation_finished):
				$AnimatedSprite2D.animation_finished.connect(_on_ground_animation_finished)
		elif $AnimatedSprite2D.animation != "ground":
			# Only change animation if not currently playing ground animation
			if abs(velocity.x) > 1.0:
				$AnimatedSprite2D.play("run")
			else:
				$AnimatedSprite2D.play("idle")

func _on_ground_animation_finished():
	# When ground animation finishes, transition to appropriate animation
	if is_on_floor():
		if abs(velocity.x) > 1.0:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")

func _on_attack_animation_finished():
	# When attack animation finishes, end attack state
	is_attacking = false
	# Transition to appropriate animation
	if is_on_floor():
		if abs(velocity.x) > 1.0:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")
	else:
		if velocity.y < 0:
			$AnimatedSprite2D.play("jump")
		else:
			$AnimatedSprite2D.play("fall")
