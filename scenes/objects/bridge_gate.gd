class_name BridgeGate
extends StaticBody3D

@export var active_y: float = -0.5
@export var inactive_y: float = -5.0
@export var raise_speed: float = 1.0
@export var is_active: bool = false

@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")

func _ready() -> void:
	if not is_active:
		global_position.y = inactive_y
		if collision_shape:
			collision_shape.disabled = true
	else:
		global_position.y = active_y
		if collision_shape:
			collision_shape.disabled = false
		
	# Strict Z-axis lock for 2.5D
	global_position.z = 0.0

func _physics_process(delta: float) -> void:
	var target_y = active_y if is_active else inactive_y
	if not is_equal_approx(global_position.y, target_y):
		# If raising, enable collision immediately so actors can land on it as it rises
		if is_active and collision_shape and collision_shape.disabled:
			collision_shape.disabled = false
			
		global_position.y = move_toward(global_position.y, target_y, delta * raise_speed)
		
		# If lowering, only disable once fully lowered
		if not is_active and is_equal_approx(global_position.y, target_y):
			if collision_shape:
				collision_shape.disabled = true

func activate() -> void:
	is_active = true
	SoundManager.play_object_move(global_position)
	print("[BridgeGate] Bridge raising initiated...")
