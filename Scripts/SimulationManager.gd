extends Node3D

class_name SimulationManager

@export var step_time: float = 0.1
@export var grid_size: int = 150
@export var num_rabbits: int = 25
@export var num_foxes: int = 10
@export var num_berries: int = 30

@export var grass_scene: PackedScene
@export var rabbit_scene: PackedScene
@export var fox_scene: PackedScene
@export var berry_scene: PackedScene
@export var water_scene: PackedScene
@export var sand_scene: PackedScene
@export var deep_water_scene: PackedScene

var terrain_noise := FastNoiseLite.new()
var entities: Array = []
var step_timer: Timer

func _ready():
	step_timer = Timer.new()
	step_timer.wait_time = step_time
	step_timer.autostart = true
	step_timer.one_shot = false
	add_child(step_timer)

	generate_world()

func add_entity(entity):
	if entity not in entities:
		entities.append(entity)

func remove_entity(entity):
	entities.erase(entity)

func generate_world():
	terrain_noise.seed = randi()
	terrain_noise.frequency = 0.01
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var grass_positions := []

	for x in range(grid_size):
		for y in range(grid_size):
			var value = terrain_noise.get_noise_2d(x, y)
			var pos = Vector3(x, 0, y)

			if value < -0.25:
				var deep_water = deep_water_scene.instantiate()
				deep_water.position = pos
				add_child(deep_water)
				add_entity(deep_water)
			elif value < -0.10:
				var water = water_scene.instantiate()
				water.position = pos
				add_child(water)
				add_entity(water)
			elif value < 0.05:
				var sand = sand_scene.instantiate()
				sand.position = pos
				add_child(sand)
				add_entity(sand)
			else:
				var grass = grass_scene.instantiate()
				grass.position = pos
				add_child(grass)
				add_entity(grass)
				grass_positions.append(pos)

	spawn_entities_on_positions(rabbit_scene, num_rabbits, grass_positions, true)
	spawn_entities_on_positions(fox_scene, num_foxes, grass_positions, true)
	spawn_entities_on_positions(berry_scene, num_berries, grass_positions, false)

func spawn_entities_on_positions(scene: PackedScene, count: int, positions: Array, allow_overlap: bool):
	var used := []

	for i in range(count):
		if positions.is_empty():
			return

		var pos = positions.pick_random()

		if not allow_overlap and pos in used:
			continue
		
		if scene == berry_scene:
			var entity1 = scene.instantiate()
			entity1.global_position = pos
			add_child(entity1)
			add_entity(entity1)

			entity1.type = 0
			entity1.set_mat()

			entity1.rotation.y = deg_to_rad(0)
			
			var entity2 = scene.instantiate()
			entity2.global_position = pos
			add_child(entity2)
			add_entity(entity2)

			entity2.type = 1
			entity2.set_mat()

			entity2.rotation.y = deg_to_rad(120)
			
			
			var entity3 = scene.instantiate()
			entity3.global_position = pos
			add_child(entity3)
			add_entity(entity3)

			entity3.type = 2
			entity3.set_mat()

			entity3.rotation.y = deg_to_rad(270)
		else:
			var entity = scene.instantiate()
			entity.global_position = pos
			add_child(entity)
			add_entity(entity)

		if not allow_overlap:
			used.append(pos)

func spawn_entities(scene: PackedScene, count: int, add_to_entities: bool):
	if scene == null:
		print("Error: Scene not assigned!")
		return
	for i in range(count):
		var entity = scene.instantiate()
		if entity == null:
			print("Error: Failed to instantiate entity from scene.")
			continue
		var x = randi() % grid_size
		var y = randi() % grid_size
		entity.position = Vector3(x, 0, y)
		add_child(entity)
		if add_to_entities:
			add_entity(entity)
