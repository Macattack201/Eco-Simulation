extends Node3D

class_name SimulationManager

@export var step_time: float = 0.1  # Time between steps in seconds
@export var grid_size: int = 100  # Size of the world grid
@export var num_rabbits: int = 10  # Number of rabbits to spawn
@export var num_foxes: int = 2  # Number of foxes to spawn
@export var num_berries: int = 20  # Number of berry bushes to spawn
@export var num_water_sources: int = 20  # Number of water sources to spawn

@export var grass_scene: PackedScene
@export var rabbit_scene: PackedScene
@export var fox_scene: PackedScene
@export var berry_scene: PackedScene
@export var water_scene: PackedScene

var entities: Array = []  # List of entities to update each step
var step_timer: Timer

func _ready():
	# Initialize and start the timer
	step_timer = Timer.new()
	step_timer.wait_time = step_time
	step_timer.autostart = true
	step_timer.one_shot = false
	step_timer.timeout.connect(_on_step)
	add_child(step_timer)

	# Generate the world
	generate_world()

func _on_step():
	for entity in entities:
		if entity and entity.has_method("run"):
			entity.run()

func add_entity(entity):
	if entity not in entities:
		entities.append(entity)

func remove_entity(entity):
	entities.erase(entity)

func generate_world():
	# Generate grass for every tile
	for x in range(grid_size):
		for y in range(grid_size):
			var grass = grass_scene.instantiate()
			grass.position = Vector3(x, 0, y)
			add_child(grass)
			add_entity(grass)

	# Spawn entities randomly
	spawn_entities(rabbit_scene, num_rabbits, true)
	spawn_entities(fox_scene, num_foxes, true)
	spawn_entities(berry_scene, num_berries, false)
	spawn_entities(water_scene, num_water_sources, false)

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
