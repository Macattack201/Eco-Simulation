extends Node3D

class_name Fox

@export var move_speed: int = 1  # Tiles moved per step
@export var hunger_threshold: float = 50.0  # When to seek food
@export var thirst_threshold: float = 50.0  # When to seek water
@export var is_fox: bool = true  # Determines if the entity is a fox
@export var reproduction_cooldown: float = 30.0  # Time before an animal can reproduce again

var simulation_manager: Node = null  # Reference to the Simulation Manager
var hunger: float = 100.0
var thirst: float = 100.0
var reproduction_timer: float = 0.0
var target: Node3D = null
var predator: Node3D = null

func _ready():
	# Attempt to find the simulation manager in the scene
	simulation_manager = get_tree().get_first_node_in_group("simulation_manager")

func run():
	update_needs()
	reproduction_timer -= 1  # Decrease reproduction timer
	
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
	hunger -= 1  # Decrease hunger over time
	thirst -= 1  # Decrease thirst over time
	
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
		target = nearest_mate  # Move toward mate instead of instant reproduction

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
	position = new_position
	
	if position.distance_to(destination) < 1:
		if target and is_instance_valid(target) and (target.is_in_group("foxes") or target.is_in_group("rabbits")):
			reproduce(target)  # Reproduce only when they reach the mate
		else:
			consume_target()

func consume_target():
	if target and is_instance_valid(target):  # Ensure target is still valid
		if target.has_method("consume"):
			target.consume()
			target = null  # Reset target after consuming
			if is_fox:
				hunger = 100.0  # Reset hunger when eating a rabbit
			else:
				thirst = 100.0  # Reset thirst when drinking water
		elif target.is_in_group("rabbits") and is_fox:
			print("Fox ate rabbit:", target)
			
			# Remove rabbit from Simulation Manager's entities list
			if simulation_manager and simulation_manager.has_method("remove_entity"):
				simulation_manager.remove_entity(target)
			
			var temp_target = target  # Store reference before nullifying
			target = null  # Immediately remove reference to avoid errors
			temp_target.call_deferred("queue_free")  # Delay deletion to prevent crashes
			hunger = 100.0  # Reset hunger after eating

func reproduce(mate: Node3D):
	if simulation_manager and simulation_manager.has_method("add_entity"):
		var new_animal = duplicate()
		new_animal.position = position + Vector3(randi() % 3 - 1, 0, randi() % 3 - 1)
		new_animal.reproduction_timer = reproduction_cooldown
		mate.reproduction_timer = reproduction_cooldown
		reproduction_timer = reproduction_cooldown
		simulation_manager.add_entity(new_animal)
		get_parent().add_child(new_animal)  # Ensure it spawns in the scene
		print("New animal born at: ", new_animal.position)

func flee_from(threat_position: Vector3):
	var direction = (position - threat_position).normalized()
	var new_position = position + Vector3(direction.x * move_speed, 0, direction.z * move_speed)
	position = new_position

func wander():
	var x_offset = randi() % 3 - 1
	var z_offset = randi() % 3 - 1
	position += Vector3(x_offset * move_speed, 0, z_offset * move_speed)
