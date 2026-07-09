class_name CoverZone
extends Area3D

@export_enum("Small", "Medium", "Large") var zone_size: String = "Medium"
@export var capacity: int = 1

var assigned_actors: Array[Node3D] = []

func _ready() -> void:
	add_to_group("cover_zones")
	collision_layer = 8
	collision_mask = 3 # Detect Layer 1 (Companions) and Layer 2 (Player)

func has_space_for(actor_size: String) -> bool:
	if assigned_actors.size() >= capacity:
		return false
		
	# Size compatibility logic:
	# - Small cover: only fits Small actors (Toddler)
	# - Medium cover: fits Small (Toddler) and Medium (Player)
	# - Large cover: fits any size (Small, Medium, Large)
	match zone_size:
		"Small":
			return actor_size == "Small"
		"Medium":
			return actor_size == "Small" or actor_size == "Medium"
		"Large":
			return true
	return false

func assign_actor(actor: Node3D) -> float:
	if not assigned_actors.has(actor):
		assigned_actors.append(actor)
	return get_slot_x(actor)

func get_slot_x(actor: Node3D) -> float:
	var idx := assigned_actors.find(actor)
	if idx == -1:
		return global_position.x
		
	# Distribute slot positions horizontally based on current count
	var width: float = 2.0
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape and col_shape.shape is BoxShape3D:
		width = col_shape.shape.size.x * 0.8
		
	var offset_ratio: float = 0.0
	if assigned_actors.size() > 1:
		offset_ratio = (float(idx) / float(assigned_actors.size() - 1)) - 0.5
		
	return global_position.x + (offset_ratio * width)

func release_actor(actor: Node3D) -> void:
	assigned_actors.erase(actor)
