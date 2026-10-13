extends CharacterBody2D

@export var speed = 150
@export var jump_speed = -350
@export var acceleration = 15
@export var friction = 16

var coyote_frames = 6
var coyote = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var last_floor = false
var jumping = false
var dead = false


func _ready():
	
	$CoyoteTimer.wait_time = coyote_frames / 60.0

func get_input(delta):
	var direction = Input.get_axis("Left", "Right")
	if direction:
		velocity.x = lerp(velocity.x, direction * speed, acceleration * delta)
		
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)	
		
	if jumping:
		if velocity.y < 0:
			print("jump up ani")
		elif velocity.y > 0:
			print("jump down ani")
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote):
		velocity.y = jump_speed
		jumping = true
	
func _physics_process(delta):
	velocity.y += gravity * delta
	if dead:
		print("Dead")
		return
	get_input(delta)
	move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i).get_collider()
		var n = get_slide_collision(i).get_normal()
		if c.is_in_group("pushable"):
			c.apply_central_impulse(-n * 5)
#			c.set_axis_velocity(-n * 10)
	if is_on_floor() and jumping:
		jumping = false
	if !is_on_floor() and last_floor and !jumping:
		coyote = true
		$CoyoteTimer.start()
	if velocity.x > 0:
		$Sprite2D.flip_h = false
	if velocity.x < 0:
		$Sprite2D.flip_h = true
	last_floor = is_on_floor()


func _on_coyote_timer_timeout():
	coyote = false
