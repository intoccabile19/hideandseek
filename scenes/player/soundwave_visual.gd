class_name SoundwaveVisual
extends MeshInstance3D

var target_radius: float = 2.0
var current_radius: float = 0.0
var duration: float = 0.4
var timer: float = 0.0

var _material: StandardMaterial3D

func _ready() -> void:
	# Create a flat Torus ring mesh
	var torus := TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 3
	mesh = torus

	# Material with additive transparency for a glowing soundwave effect
	_material = StandardMaterial3D.new()
	_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = Color(0.2, 0.6, 1.0, 0.4)
	material_override = _material

func _process(delta: float) -> void:
	timer += delta
	var progress := timer / duration
	if progress >= 1.0:
		queue_free()
		return
		
	# Expand size to target radius
	current_radius = lerp(0.0, target_radius, progress)
	scale = Vector3(current_radius, 1.0, current_radius)
	
	# Smoothly fade out transparency
	_material.albedo_color.a = lerp(0.4, 0.0, progress)
