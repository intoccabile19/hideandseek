class_name Pebble
extends Node3D

@export var speed: float = 12.0
@export var gravity: float = 18.0

var velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Create a visual representation programmatically
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	mesh_inst.mesh = sphere
	
	# Material override for visibility (glowing yellow pebble)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.3)
	mesh_inst.material_override = mat
	
	add_child(mesh_inst)

func launch(dir: Vector3) -> void:
	velocity = dir * speed

func _physics_process(delta: float) -> void:
	velocity.y -= gravity * delta
	global_position += velocity * delta
	
	# Detect hit on ground level (Y <= 0.0)
	if global_position.y <= 0.0:
		# Emit noise distraction event
		FamilyManager.sound_emitted.emit(global_position, 6.0, false)
		SoundManager.play_scrape(global_position)
		print("[Pebble] Impact at X: %0.2f. Alerted nearby Seekers." % global_position.x)
		queue_free()
