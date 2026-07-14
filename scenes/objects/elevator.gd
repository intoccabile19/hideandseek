class_name Elevator
extends AnimatableBody3D

@export var start_y: float = -0.5
@export var target_y: float = 4.699
@export var travel_speed: float = 2.0

var _target_pos_y: float = 0.0

func _ready() -> void:
	_target_pos_y = start_y
	global_position.y = start_y

func toggle_elevator() -> void:
	if _target_pos_y == start_y:
		_target_pos_y = target_y
	else:
		_target_pos_y = start_y
	print("[Elevator %s] Toggled moving towards Y: %0.2f" % [name, _target_pos_y])

func _physics_process(delta: float) -> void:
	global_position.y = move_toward(global_position.y, _target_pos_y, travel_speed * delta)
