extends Node3D

class_name WaterSource

@export var resource_type: String = "water"  # Can be "berry" or "water"
@export var quantity: int = 5  # Amount of resource available

func consume():
	if quantity > 0:
		quantity -= 1
		if quantity == 0:
			queue_free()
		return true
	return false
