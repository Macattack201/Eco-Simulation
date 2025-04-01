extends Node3D

class_name Rabbit
@export var rabbit_scene: PackedScene

@export var move_speed: float = 2.0
@export var move_distance: float = 5.0
@export var wait_time_between_moves: float = 1.5
@export var detection_radius: float = 35.0
@export var danger_radius: float = 10.0

@export var base_health: float = 100.0
@export var max_health: float = base_health
@export var health: float = max_health

@export var hunger_increase_rate: float = 1.0
@export var thirst_increase_rate: float = 1.5
@export var hunger_threshold: float = 30.0
@export var thirst_threshold: float = 30.0
@export var hunger_full_value: float = 100.0
@export var thirst_full_value: float = 100.0

@export var reproduction_radius: float = 3.0
@export var reproduction_cooldown: float = 10.0
@export var mutation_strength: float = 0.4


@export var gestation_rate: float = 1.0
@export var gestation_threshold: float = 45.0

var rng := RandomNumberGenerator.new()

@export var berry_likeness = Vector3(rng.randf_range(0.1, 0.13), rng.randf_range(0.1, 0.11), rng.randf_range(0.1, 0.11))

var hunger: float = rng.randf_range(0.0, 10.0)
var thirst: float = rng.randf_range(0.0, 10.0)
var gestation: float = rng.randf_range(0.0, 10.0)

var alive: bool = true
var can_reproduce: bool = true

var temp_timer1: float = 0.0
var temp_timer2: float = 0.0

var target_position: Vector3
var moving := false
var seeking_food := false
var seeking_water := false
var fleeing := false
var target_node: Node3D = null
var seeking_mate: bool = false

var toxic: bool = false
var speed_boost: bool = false

@onready var mesh := $MeshInstance3D
@onready var speed_circle := $"Speed Boost"
@onready var toxic_circle := $Toxic

func _ready():
	var mat: Material = mesh.get_active_material(0)
	if mat:
		mat = mat.duplicate()
		mesh.set_surface_override_material(0, mat)
	if mat is StandardMaterial3D:
		var max_val = max(berry_likeness.x, berry_likeness.y, berry_likeness.z)
		if max_val > 0.0:
			mat.albedo_color = Color(
				berry_likeness.x / max_val,
				berry_likeness.y / max_val,
				berry_likeness.z / max_val
			)
		else:
			mat.albedo_color = Color(0.1, 0.1, 0.1)

	
	rng.randomize()
	target_position = global_position
	add_to_group("rabbits")

	if rabbit_scene == null:
		rabbit_scene = load("res://Scenes/rabbit.tscn")

	start_next_move()

func _process(delta):
	if not alive:
		return

	hunger += hunger_increase_rate * delta
	thirst += thirst_increase_rate * delta
	gestation += gestation_rate * delta
	temp_timer1 += 1.0 * delta
	temp_timer2 += 1.0 * delta
	
	if temp_timer1 >= 40:
		speed_boost = false
	
	if temp_timer2 >= 40:
		toxic = false
	
	speed_circle.visible = speed_boost
	toxic_circle.visible = toxic
	
	if hunger >= 100.0 or thirst >= 100.0:
		die()
		return

	if not fleeing and can_reproduce and gestation >= gestation_threshold:
		seek_mate()

	if fleeing:
		if not is_fox_nearby():
			fleeing = false
			start_next_move()

	if moving:
		var move_direction = target_position - global_position

		# Check for deep_water between current and target
		if is_path_over_deep_water(global_position, target_position):
			start_next_move()
			return

		# Continue moving if safe
		if speed_boost:
			global_position = global_position.move_toward(target_position, move_speed * delta * 2)
		else:
			global_position = global_position.move_toward(target_position, move_speed * delta)

		var target_angle = atan2(move_direction.x, move_direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, delta * 5.0)

		if global_position.distance_to(target_position) < 0.2:
			moving = false

			if seeking_food and is_instance_valid(target_node):
				if target_node.is_in_group("foods"):
					consume_food(target_node)
			elif seeking_water and is_instance_valid(target_node):
				drink_water(target_node)
			elif seeking_mate and is_instance_valid(target_node):
				reproduce_with(target_node)

			seeking_mate = false
			target_node = null

			if not fleeing:
				start_next_move()
			else:
				flee()

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

func _physics_process(_delta):
	pass # No nav-based movement needed anymore

func start_next_move():
	if not alive:
		return

	if is_fox_nearby():
		flee()
		return

	var wait_timer = Timer.new()
	wait_timer.wait_time = wait_time_between_moves
	wait_timer.one_shot = true
	wait_timer.timeout.connect(func(): decide_action())
	add_child(wait_timer)
	wait_timer.start()

func decide_action():
	if is_fox_nearby():
		flee()
		return

	if hunger > hunger_threshold or thirst > thirst_threshold:
		if hunger >= thirst:
			try_find_food()
		else:
			try_find_water()
	else:
		wander()

func try_find_food():
	var best_score := -INF
	var best_berry: Node3D = null

	for berry in get_tree().get_nodes_in_group("foods"):
		if not berry is Node3D:
			continue
		if berry.quantity <= 0:
			continue
		
		var berry_type = berry.type
		
		berry_likeness[berry_type] += 0.001

		var likeness = berry_likeness[berry_type]
		var distance = global_position.distance_to(berry.global_position)
		if distance == 0:
			distance = 0.01

		var score = likeness / distance

		if score > best_score:
			best_score = score
			best_berry = berry

	if best_berry:
		target_node = best_berry
		seeking_food = true
		seeking_water = false
		target_position = best_berry.global_position
		moving = true
	else:
		wander()

func try_find_water():
	target_node = find_nearest_target("waters")
	if target_node:
		seeking_food = false
		seeking_water = true
		target_position = target_node.global_position
		moving = true
	else:
		wander()

func wander():
	seeking_food = false
	seeking_water = false

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

func is_fox_nearby() -> bool:
	for fox in get_tree().get_nodes_in_group("foxes"):
		if not fox is Node3D:
			continue

		var dist = global_position.distance_to(fox.global_position)
		if dist < danger_radius:
			return true

	return false

func get_nearest_fox() -> Node3D:
	var nearest: Node3D = null
	var shortest_dist = danger_radius

	for fox in get_tree().get_nodes_in_group("foxes"):
		if not fox is Node3D:
			continue

		var dist = global_position.distance_to(fox.global_position)
		if dist < shortest_dist:
			nearest = fox
			shortest_dist = dist

	return nearest

func flee():
	var nearest_fox := get_nearest_fox()
	if nearest_fox:
		fleeing = true
		seeking_food = false
		seeking_water = false

		var away_direction = (global_position - nearest_fox.global_position).normalized()
		var flee_distance = danger_radius * 1.5
		target_position = global_position + away_direction * flee_distance
		moving = true

func consume_food(food: Node3D):
	if is_instance_valid(food):
		if food.quantity >= 1:
			food.consume()
			if food.type == 0:
				max_health += 10
			elif food.type == 1:
				toxic = true
				temp_timer2 = 0.0
			elif food.type == 2:
				speed_boost = true
				temp_timer1 = 0.0
			hunger = max(hunger - hunger_full_value, 0.0)
			health = max_health

func drink_water(water: Node3D):
	if is_instance_valid(water):
		thirst = max(thirst - thirst_full_value, 0.0)

func die():
	alive = false
	moving = false
	# print("Rabbit has died.")

	var death_timer := Timer.new()
	death_timer.wait_time = 1.0
	death_timer.one_shot = true
	death_timer.timeout.connect(func(): queue_free())
	add_child(death_timer)
	death_timer.start()

# --- Reproduction ---

func seek_mate():
	var partner = find_nearest_target("rabbits")
	if partner and partner != self and partner is Rabbit and partner.alive and partner.gestation >= gestation_threshold and partner.can_reproduce:
		target_node = partner
		target_position = partner.global_position
		seeking_mate = true
		moving = true

func try_reproduce():
	for other in get_tree().get_nodes_in_group("rabbits"):
		if other == self or not other is Rabbit or not other.alive:
			continue

		if global_position.distance_to(other.global_position) <= reproduction_radius:
			reproduce_with(other)
			break
		else:
			print("Not close enough")

func reproduce_with(partner: Rabbit):
	if rabbit_scene == null:
		# push_error("Reproduction failed: rabbit_scene is not assigned!")
		return

	can_reproduce = false
	gestation = 0.0
	partner.gestation = 0.0
	partner.can_reproduce = false

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

	var baby = rabbit_scene.instantiate()
	if baby == null or not baby is Rabbit:
		# push_error("Reproduction failed: instance is not a Rabbit")
		return

	baby = baby as Rabbit
	baby.rabbit_scene = rabbit_scene

	baby.move_speed = mutate_trait((move_speed + partner.move_speed) / 2)
	baby.base_health = mutate_trait((base_health + partner.base_health) / 2)
	baby.gestation_rate = mutate_trait((gestation_rate + partner.gestation_rate) / 2)
	baby.move_distance = mutate_trait((move_distance + partner.move_distance) / 2)
	baby.global_position = global_position + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5))
	
	var berry1Like = mutate_trait((berry_likeness.x + partner.berry_likeness.x) / 2)
	var berry2Like = mutate_trait((berry_likeness.y + partner.berry_likeness.y) / 2)
	var berry3Like = mutate_trait((berry_likeness.z + partner.berry_likeness.z) / 2)
	
	baby.berry_likeness = Vector3(berry1Like, berry2Like, berry3Like)

	get_tree().current_scene.add_child(baby)
	# print("New rabbit born - Speed: ", baby.move_speed, ", Distance: ", baby.move_distance, ", Berry Likeness: ", baby.berry_likeness, ", Gestation Rate: ", baby.gestation_rate, ", Health: ", baby.base_health)

func mutate_trait(value: float) -> float:
	var mutation_factor = 1.0 + rng.randf_range(-mutation_strength, mutation_strength)
	return max(0.1, value * mutation_factor)
