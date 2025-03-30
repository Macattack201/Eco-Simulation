extends Node3D

class_name Fox

@export var fox_scene: PackedScene

@export var move_speed: float = 5.0
@export var move_distance: float = 15.0
@export var wait_time_between_moves: float = 1.5
@export var detection_radius: float = 45.0

@export var hunger_increase_rate: float = 1.0
@export var thirst_increase_rate: float = 1.5
@export var hunger_threshold: float = 15.0
@export var thirst_threshold: float = 30.0
@export var hunger_full_value: float = 100.0
@export var thirst_full_value: float = 100.0
@export var damage: float = 100.0

# Reproduction
@export var reproduction_radius: float = 3.0
@export var reproduction_cooldown: float = 10.0
@export var gestation_threshold: float = 60.0
@export var gestation_rate: float = 1.0
@export var mutation_strength: float = 0.2

var alive: bool = true
var can_reproduce: bool = true

var rng := RandomNumberGenerator.new()

var hunger: float = rng.randf_range(0.0, 10.0)
var thirst: float = rng.randf_range(0.0, 10.0)
var gestation: float = rng.randf_range(0.0, 10.0)

var target_position: Vector3
var moving := false
var seeking_food := false
var seeking_water := false
var seeking_mate := false
var target_node: Node3D = null

func _ready():
	rng.randomize()
	target_position = global_position
	add_to_group("foxes")
	
	if fox_scene == null:
		fox_scene = load("res://Scenes/fox.tscn")
	
	start_next_move()

func _process(delta):
	if not alive:
		return

	hunger += hunger_increase_rate * delta
	thirst += thirst_increase_rate * delta
	gestation += gestation_rate * delta

	if hunger >= 100.0 or thirst >= 100.0:
		die()
		return

	if not moving and can_reproduce and gestation >= gestation_threshold:
		seek_mate()

	if moving:
		var move_direction = target_position - global_position

		# Check for deep_water between current and target
		if is_path_over_deep_water(global_position, target_position):
			start_next_move()
			return
		
		global_position = global_position.move_toward(target_position, move_speed * delta)

		if move_direction.length() > 0.01:
			var target_angle = atan2(move_direction.x, move_direction.z)
			rotation.y = lerp_angle(rotation.y, target_angle, delta * 5.0)

		if global_position.distance_to(target_position) < 0.2:
			moving = false

			if seeking_food and is_instance_valid(target_node):
				if global_position.distance_to(find_nearest_target("rabbits").global_position) < 2.0:
					consume_food(target_node)
			elif seeking_water and is_instance_valid(target_node):
				drink_water(target_node)
			elif seeking_mate and is_instance_valid(target_node):
				reproduce_with(target_node)

			seeking_food = false
			seeking_water = false
			seeking_mate = false
			target_node = null

			start_next_move()

func is_path_over_deep_water(from_pos: Vector3, to_pos: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from_pos + Vector3.UP * 1.0, to_pos + Vector3.UP * 1.0)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)
	if result and result.has("collider"):
		var collider = result["collider"]
		if collider.is_in_group("deep_water"):
			return true
	return false

func start_next_move():
	var wait_timer = Timer.new()
	wait_timer.wait_time = wait_time_between_moves
	wait_timer.one_shot = true
	wait_timer.timeout.connect(func(): decide_action())
	add_child(wait_timer)
	wait_timer.start()

func decide_action():
	if hunger > hunger_threshold or thirst > thirst_threshold:
		if hunger >= thirst:
			try_find_food()
		else:
			try_find_water()
	else:
		wander()

func try_find_food():
	target_node = find_nearest_target("rabbits")
	if target_node:
		seeking_food = true
		seeking_water = false
		target_position = target_node.global_position
		moving = true
	else:
		wander()

func try_find_water():
	target_node = find_nearest_target("waters")
	if target_node:
		seeking_water = true
		seeking_food = false
		target_position = target_node.global_position
		moving = true
	else:
		wander()

func wander():
	seeking_food = false
	seeking_water = false
	seeking_mate = false

	var direction = Vector3(
		rng.randf_range(-1.0, 1.0),
		0,
		rng.randf_range(-1.0, 1.0)
	).normalized()
	var distance = rng.randf_range(1.0, move_distance)
	target_position = global_position + direction * distance
	moving = true

func find_nearest_target(group_name: String) -> Node3D:
	var nearest: Node3D = null
	var shortest_dist = detection_radius

	for node in get_tree().get_nodes_in_group(group_name):
		if not node is Node3D or node == self:
			continue

		var dist = global_position.distance_to(node.global_position)
		if dist < shortest_dist:
			nearest = node
			shortest_dist = dist

	return nearest

func consume_food(food: Node3D):
	if is_instance_valid(food):
		food.health -= damage
		if food.health <= 0.0:
			hunger = max(hunger - hunger_full_value, 0.0)
			if food.toxic == true:
				queue_free()
			food.queue_free()

func drink_water(water: Node3D):
	if is_instance_valid(water):
		thirst = max(thirst - thirst_full_value, 0.0)

func die():
	alive = false
	moving = false
	# print("Fox has died.")

	var death_timer := Timer.new()
	death_timer.wait_time = 1.0
	death_timer.one_shot = true
	death_timer.timeout.connect(func(): queue_free())
	add_child(death_timer)
	death_timer.start()

# --- Reproduction ---

func seek_mate():
	var partner = find_nearest_target("foxes")
	if partner and partner != self and partner is Fox and partner.alive and partner.gestation >= gestation_threshold and partner.can_reproduce:
		target_node = partner
		target_position = partner.global_position
		seeking_mate = true
		moving = true

func reproduce_with(partner: Fox):
	if fox_scene == null:
		# push_error("Reproduction failed: fox_scene is not assigned!")
		return

	can_reproduce = false
	gestation = 0.0
	partner.can_reproduce = false
	partner.gestation = 0.0

	# Cooldown timers for both parents
	var cooldown_timer := Timer.new()
	cooldown_timer.wait_time = reproduction_cooldown
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(func(): can_reproduce = true)
	add_child(cooldown_timer)
	cooldown_timer.start()

	var partner_timer := Timer.new()
	partner_timer.wait_time = reproduction_cooldown
	partner_timer.one_shot = true
	partner_timer.timeout.connect(func(): partner.can_reproduce = true)
	partner.add_child(partner_timer)
	partner_timer.start()

	# Create baby
	var baby = fox_scene.instantiate()
	if baby == null or not baby is Fox:
		# push_error("Reproduction failed: instance is not a Fox")
		return

	baby = baby as Fox
	baby.fox_scene = fox_scene
	baby.global_position = global_position + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5))
	baby.move_speed = mutate_trait((move_speed + partner.move_speed) / 2)
	baby.gestation_rate = mutate_trait((gestation_rate + partner.gestation_rate) / 2)
	baby.move_distance = mutate_trait((move_distance + partner.move_distance) / 2)

	get_tree().current_scene.add_child(baby)
	# print("New fox born - Speed: ", baby.move_speed, ", Distance: ", baby.move_distance, ", Gestation Rate: ", baby.gestation_rate)

func mutate_trait(value: float) -> float:
	var mutation_factor = 1.0 + rng.randf_range(-mutation_strength, mutation_strength)
	return max(0.1, value * mutation_factor)
