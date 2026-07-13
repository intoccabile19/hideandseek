class_name RetractingObstacle
extends StaticBody3D

@export var active_y: float = 0.4
@export var inactive_y: float = 4.0
@export var retract_speed: float = 0.8
@export var is_retracted: bool = false

@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")

func _ready() -> void:
	global_position.y = inactive_y if is_retracted else active_y
	if collision_shape:
		collision_shape.disabled = is_retracted
	if is_retracted:
		visible = false

func _physics_process(delta: float) -> void:
	var target_y = inactive_y if is_retracted else active_y
	if not is_equal_approx(global_position.y, target_y):
		global_position.y = move_toward(global_position.y, target_y, delta * retract_speed)
		# Only disable collision once fully retracted to prevent clipping while moving
		if is_retracted and is_equal_approx(global_position.y, target_y):
			if collision_shape:
				collision_shape.disabled = true
			visible = false

func retract() -> void:
	is_retracted = true
	SoundManager.play_object_move(global_position)
	print("[RetractingObstacle] Retraction initiated...")
