extends Control

@onready var rabbit_line: Line2D = $RabbitLine
@onready var fox_line: Line2D = $FoxLine

func draw_graph(rabbit_data: Array, fox_data: Array):
	rabbit_line.clear_points()
	fox_line.clear_points()

	var num_points = max(rabbit_data.size(), fox_data.size())
	if num_points <= 1:
		return

	var all_data = rabbit_data + fox_data
	var raw_min = all_data.min()
	var raw_max = all_data.max()

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
