extends Control

@onready var rabbit_line: Line2D = $RabbitLine
@onready var fox_line: Line2D = $FoxLine

@onready var x1: Label = $"Graph Numbers/X1"
@onready var x2: Label = $"Graph Numbers/X2"
@onready var x3: Label = $"Graph Numbers/X3"
@onready var x4: Label = $"Graph Numbers/X4"
@onready var x5: Label = $"Graph Numbers/X5"
@onready var x6: Label = $"Graph Numbers/X6"
@onready var x7: Label = $"Graph Numbers/X7"
@onready var x8: Label = $"Graph Numbers/X8"
@onready var x9: Label = $"Graph Numbers/X9"
@onready var x10: Label = $"Graph Numbers/X10"
@onready var x11: Label = $"Graph Numbers/X11"

@onready var y1: Label = $"Graph Numbers/Y1"
@onready var y2: Label = $"Graph Numbers/Y2"
@onready var y3: Label = $"Graph Numbers/Y3"
@onready var y4: Label = $"Graph Numbers/Y4"
@onready var y5: Label = $"Graph Numbers/Y5"
@onready var y6: Label = $"Graph Numbers/Y6"

func draw_graph(rabbit_data: Array, fox_data: Array):
	rabbit_line.clear_points()
	fox_line.clear_points()

	var num_points = max(rabbit_data.size(), fox_data.size())
	if num_points <= 1:
		return

	var all_data = rabbit_data + fox_data
	var raw_min = all_data.min()
	var raw_max = all_data.max()

	x1.text = "0"
	x2.text = str(num_points/10)
	x3.text = str((num_points/10) * 2)
	x4.text = str((num_points/10) * 3)
	x5.text = str((num_points/10) * 4)
	x6.text = str((num_points/10) * 5)
	x7.text = str((num_points/10) * 6)
	x8.text = str((num_points/10) * 7)
	x9.text = str((num_points/10) * 8)
	x10.text = str((num_points/10) * 9)
	x11.text = str(num_points)
	
	y1.text = str(raw_min)
	y2.text = str(raw_max / 5)
	y3.text = str((raw_max / 5) * 2)
	y4.text = str((raw_max / 5) * 3)
	y5.text = str((raw_max / 5) * 4)
	y6.text = str(raw_max)
	
	# Avoid divide by zero
	if raw_max == raw_min:
		raw_max += 1.0

	# Add padding for better visuals
	var padding = (raw_max - raw_min) * 0.05
	var min_value = raw_min - padding
	var max_value = raw_max + padding
	var range = max_value - min_value
	
	

	var margin := 100.0
	var graph_width := size.x - margin * 2
	var graph_height := size.y - margin * 2

	# Rabbit Line
	for i in range(rabbit_data.size()):
		var x = float(i) / float(num_points - 1) * graph_width + margin
		var y_val = rabbit_data[i]
		var norm = clamp((y_val - min_value) / range, 0.0, 1.0)
		var y = size.y - (norm * graph_height + margin)
		rabbit_line.add_point(Vector2(x, y))

	# Fox Line
	for i in range(fox_data.size()):
		var x = float(i) / float(num_points - 1) * graph_width + margin
		var y_val = fox_data[i]
		var norm = clamp((y_val - min_value) / range, 0.0, 1.0)
		var y = size.y - (norm * graph_height + margin)
		fox_line.add_point(Vector2(x, y))
	
		save_csv(rabbit_data, fox_data)

func save_csv(rabbit_data: Array, fox_data: Array):
	var filename = "C:/Users/gcrav/OneDrive/Documents/GitHub/Eco-Simulation/population_data.csv"
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if not file:
		return

	file.store_line("time,rabbits,foxes")

	var max_len = max(rabbit_data.size(), fox_data.size())
	for i in range(max_len):
		var r = rabbit_data[i] if i < rabbit_data.size() else ""
		var f = fox_data[i] if i < fox_data.size() else ""

		file.store_line("%d,%s,%s" % [i, str(r), str(f)])

	file.flush()
	file.close()
