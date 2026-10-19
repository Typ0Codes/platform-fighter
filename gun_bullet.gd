extends RigidBody2D

@export var speed := 400.0
@export var lifetime := 3.0

var team := 1:
	set(value):
		team = value
		if is_node_ready():
			$Hitbox2D.team = team

var direction := Vector2.RIGHT:
	set(value):
		direction = value
		linear_velocity = direction * speed

func _ready() -> void:
	gravity_scale = 0.0
	linear_damp = 0.0
	lock_rotation = true
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	$Hitbox2D.team = team
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return
	queue_free()
