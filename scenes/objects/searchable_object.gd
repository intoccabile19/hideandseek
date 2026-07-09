class_name SearchableObject
extends Node3D

@export var mesh: MeshInstance3D

var _original_y: float = 0.0

func _ready() -> void:
	add_to_group("searchable_objects")
	if mesh:
		_original_y = mesh.position.y

func lift(height: float, duration: float) -> void:
	if not mesh:
		return
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh, "position:y", _original_y + height, duration)

func lower(duration: float) -> void:
	if not mesh:
		return
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(mesh, "position:y", _original_y, duration)
