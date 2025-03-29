extends Node3D

@export var radius: float = 2.0
@export var thickness: float = 0.1
@export var segments: int = 64
@export var color: Color = Color.RED
@export var y_offset: float = 0.05

@onready var mesh_instance := $MeshInstance3D

func _ready():
	var mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)

	for i in range(segments + 1):
		var angle = TAU * float(i) / segments
		var dir = Vector2(cos(angle), sin(angle))
		var outer = dir * radius
		var inner = dir * (radius - thickness)

		# 🔁 Flip the winding order to face upward
		mesh.surface_add_vertex(Vector3(inner.x, y_offset, inner.y))
		mesh.surface_add_vertex(Vector3(outer.x, y_offset, outer.y))

	mesh.surface_end()
	mesh_instance.mesh = mesh
