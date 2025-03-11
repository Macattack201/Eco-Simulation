extends Node3D

class_name AnimalAI

@export var move_speed: int = 1  # Tiles moved per step
@export var hunger_threshold: float = 50.0  # When to seek food
@export var thirst_threshold: float = 50.0  # When to seek water

var hunger: float = 100.0
var thirst: float = 100.0
var target: Node3D = null

func run():
	update_needs()
	if target:
		move_towards(target.position)
	else:
		wander()

func update_needs():
	hunger -= 1  # Decrease hunger over time
	thirst -= 1  # Decrease thirst over time
	
	if hunger < hunger_threshold:
		find_nearest_food()
	elif thirst < thirst_threshold:
		find_nearest_water()

func find_nearest_food():
	var food = get_tree().get_nodes_in_group("food")
	if food.size() > 0:
		target = food[randi() % food.size()]

func find_nearest_water():
	var water_sources = get_tree().get_nodes_in_group("water")
	if water_sources.size() > 0:
		target = water_sources[randi() % water_sources.size()]

func move_towards(destination: Vector3):
	var direction = (destination - position).normalized()
	var new_position = position + Vector3(direction.x * move_speed, 0, direction.z * move_speed)
	position = new_position
	
	if position.distance_to(destination) < 1:
		target = null  # Reached target

func wander():
	var x_offset = randi() % 3 - 1
	var z_offset = randi() % 3 - 1
	position += Vector3(x_offset * move_speed, 0, z_offset * move_speed)
