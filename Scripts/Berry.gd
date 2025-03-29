extends Node3D

class_name Berry

@export var resource_type: String = "berry"
@export var max_quantity: int = 5
@export var quantity: int = max_quantity

var max_time: float = 120.0
var respawn_timer: float = max_time
var type;
var rng = RandomNumberGenerator.new()
@onready var mesh := $MeshInstance3D

func _process(delta):
	respawn_timer -= 1.0 * delta
	if respawn_timer <= 0:
		quantity = max_quantity
		set_mat()

func set_mat():
	var mat: Material = mesh.get_active_material(0)
	if mat:
		mat = mat.duplicate()
		mesh.set_surface_override_material(0, mat)
	if mat is StandardMaterial3D:
		if type == 0:
			mat.albedo_color = Color(1.0, 0, 0)
		elif type == 1:
			mat.albedo_color = Color(0, 1.0, 0)
		elif type == 2:
			mat.albedo_color = Color(0, 0, 1.0)

func consume():
	quantity -= 1
	if quantity <= 0:
		respawn_timer = max_time
		var material = mesh.get_active_material(0)
		if material:
			var new_material = material.duplicate()
			if new_material is StandardMaterial3D:
				new_material.albedo_color = Color(0.1, 0.1, 0.1)
				mesh.set_surface_override_material(0, new_material)
