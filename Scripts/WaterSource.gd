extends Node3D

class_name WaterSource

@export var resource_type: String = "water"
@export var quantity: int = 5

func consume():
	if quantity > 0:
		quantity -= 1
		if quantity == 0:
			queue_free()
		return true
	return false
