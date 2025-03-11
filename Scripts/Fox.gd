extends Node3D

class_name Fox

@export var move_speed: int = 1
@export var hunger_threshold: float = 50.0
@export var thirst_threshold: float = 50.0
@export var is_fox: bool = true
@export var reproduction_cooldown: float = 30.0
@export var grid_size: int = 100

var simulation_manager: Node = null
var hunger: float = 100.0
var thirst: float = 100.0
var reproduction_timer: float = 0.0
var target: Node3D = null
var predator: Node3D = null

func _ready():
	simulation_manager = get_tree().get_first_node_in_group("simulation_manager")

func run():
	update_needs()
	reproduction_timer -= 1
	
	if reproduction_timer <= 0:
		find_mate()
	elif is_fox:
		find_nearest_prey()
	else:
		find_nearest_predator()
	
	if target and is_instance_valid(target):
		move_towards(target.position)
	elif predator and is_instance_valid(predator):
		flee_from(predator.position)
	else:
		wander()

func update_needs():
	hunger -= 1
	thirst -= 1
	
	if thirst < thirst_threshold:
		find_nearest_water()
	elif hunger < hunger_threshold and is_fox:
		find_nearest_prey()
	
func find_nearest_prey():
	var rabbits = get_tree().get_nodes_in_group("rabbits")
	target = find_nearest_target(rabbits)

func find_nearest_predator():
	var foxes = get_tree().get_nodes_in_group("foxes")
	predator = find_nearest_target(foxes)

func find_nearest_water():
	var water_sources = get_tree().get_nodes_in_group("water")
	target = find_nearest_target(water_sources)

func find_mate():
	var group_name = "foxes" if is_fox else "rabbits"
	var mates = get_tree().get_nodes_in_group(group_name)
	
	var nearest_mate: Node3D = null
	var min_distance = INF
	
	for mate in mates:
		if is_instance_valid(mate) and mate != self and mate.reproduction_timer <= 0:
			var dist = position.distance_to(mate.position)
			if dist < min_distance:
				min_distance = dist
				nearest_mate = mate
	
	if nearest_mate:
		target = nearest_mate

func find_nearest_target(targets: Array) -> Node3D:
	var nearest: Node3D = null
	var min_distance = INF
	for obj in targets:
		if is_instance_valid(obj) and obj != self:
			var dist = position.distance_to(obj.position)
			if dist < min_distance:
				min_distance = dist
				nearest = obj
	return nearest

func move_towards(destination: Vector3):
	var direction = (destination - position).normalized()
	var new_position = position + Vector3(direction.x * move_speed, 0, direction.z * move_speed)
	
	new_position.x = clamp(new_position.x, 0, grid_size - 1)
	new_position.z = clamp(new_position.z, 0, grid_size - 1)
	
	position = new_position
	
	if position.distance_to(destination) < 1:
		if target and is_instance_valid(target) and (target.is_in_group("foxes") or target.is_in_group("rabbits")):
			reproduce(target)
		else:
			consume_target()

func consume_target():
	if target and is_instance_valid(target):
		if target.has_method("consume"):
			target.consume()
			target = null
			if is_fox:
				hunger = 100.0
			else:
				thirst = 100.0
		elif target.is_in_group("rabbits") and is_fox:
			print("Fox ate rabbit:", target)
			
			if simulation_manager and simulation_manager.has_method("remove_entity"):
				simulation_manager.remove_entity(target)
			
			var temp_target = target
			target = null
			temp_target.call_deferred("queue_free")
			hunger = 100.0

func reproduce(mate: Node3D):
	if simulation_manager and simulation_manager.has_method("add_entity") and mate.reproduction_timer <= 0 and reproduction_timer <= 0:
		reproduction_timer = reproduction_cooldown
		mate.reproduction_timer = reproduction_cooldown
		
		var new_animal = duplicate()
		new_animal.position = position + Vector3(randi() % 3 - 1, 0, randi() % 3 - 1)
		
		new_animal.position.x = clamp(new_animal.position.x, 0, grid_size - 1)
		new_animal.position.z = clamp(new_animal.position.z, 0, grid_size - 1)
		new_animal.reproduction_timer = reproduction_cooldown

		simulation_manager.add_entity(new_animal)
		get_parent().add_child(new_animal)

		print("New animal born at: ", new_animal.position)

		target = null
		mate.target = null

func flee_from(threat_position: Vector3):
	var direction = (position - threat_position).normalized()
	var new_position = position + Vector3(direction.x * move_speed, 0, direction.z * move_speed)
	
	new_position.x = clamp(new_position.x, 0, grid_size - 1)
	new_position.z = clamp(new_position.z, 0, grid_size - 1)
	
	position = new_position

func wander():
	var x_offset = randi() % 3 - 1
	var z_offset = randi() % 3 - 1
	
	var new_position = position + Vector3(x_offset * move_speed, 0, z_offset * move_speed)
	
	new_position.x = clamp(new_position.x, 0, grid_size - 1)
	new_position.z = clamp(new_position.z, 0, grid_size - 1)
	
	position = new_position
