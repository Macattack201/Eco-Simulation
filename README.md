# Diverse Ecosystem Implementation
 This project aims to implement a Bio-Diverse Ecosystem Simulation, a model representing interactions between rabbits, foxes, and berries. The goal of the simulation is to explore the impact of different berry effects on rabbit populations, their adaptations, and biodiversity.
 
 ![image](https://github.com/user-attachments/assets/0f509d64-12d2-4f52-b180-39f8ff63b6b1)
 
 ## Description
 
 This project is set up in Godot. The simulation runs in steps where the entities involved are capable of moving a specified number of tiles in a given step. These entities are foxes and rabbits. The rabbits wander the world looking for berry and water tiles, while the foxes hunt for rabbits. There is a simple reproduction system in place where the different animals search for mates nearby and reproduce.
 
 ### Features
 
 * Tile-Based Movement - Animals move step-by-step across a 100x100 world grid
 * Hunger & Thirst Mechanics - Rabbits and foxes consume food and water to survive
 * Reproduction System - Animals find mates and create offspring, leading to population shifts
 * Predator-Prey Interaction - Foxes hunt rabbits, influencing population cycles
 
 ## Getting Started
 
 ### Installing
 
 * The project can be downloaded and then opened in Godot.
 * No other special implementation required.
 
 ### Running the Project
 
 1. **Clone the repository:**
    ```sh
    git clone https://github.com/macattack201/eco-simulation.git
    cd eco-simulation
    ```
 2. **Open Godot**
 3. **Load the project folder and start the simulation**
 
 ## Key Code Features
 
 ### 1. Rabbit AI - Seeking Food & Water
 Rabbits will prioritize food and water when needed, choosing the nearest available resource.
 
 ```gdscript
 func update_needs():
     hunger -= 1
     thirst -= 1
     
     if thirst < thirst_threshold:
         find_nearest_water()
     elif hunger < hunger_threshold:
         find_nearest_food()
 ```
 
 ### 2. Fox Hunting Behavior
 Foxes search for the nearest rabbit, pursue it, and consume it when caught.
 
 ```gdscript
 func find_nearest_prey():
     var rabbits = get_tree().get_nodes_in_group("rabbits")
     target = find_nearest_target(rabbits)
 
 func consume_target():
     if target and is_instance_valid(target) and target.is_in_group("rabbits"):
         target.queue_free()  # Rabbit is caught
         hunger = 100.0  # Reset fox hunger
 ```
 
 ## Future Features
 
 * **Better Movement** - The movement is currently unpredictable and choppy
 * **Rabbit and Fox Stats** - There are currently no traits to pass down to the children when reproducing
 * **UI** - There will be a UI to alter simulation speed, see an entity count, and click on and follow individual entities
 * **Population Tracking** - A system will be implemented in the UI to track the population over time, ideally storing data across multiple runs to observe consistency in the simulation
