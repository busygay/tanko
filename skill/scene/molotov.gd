extends "res://skill/scene/skill.gd"

func _ready() -> void:
	super ()

func _skillEmit(_dic: Dictionary = {}):
	await super ()
	# TODO: 实现具体燃烧瓶逻辑
	var pos_array: Array = []
	var view_size = get_viewport_rect().size
	var player = get_tree().get_first_node_in_group("player")
	var center_pos = view_size / 2
	if player:
		center_pos = player.global_position

	if _dic.has("fiveCombo"):
		print("执行金黄色长效火墙逻辑")
		var y_pos = randf_range(view_size.y * 0.2, view_size.y * 0.8)
		var start_x = view_size.x * 0.2
		var end_x = view_size.x * 0.8
		var step = (end_x - start_x) / 4
		for i in range(5):
			pos_array.append(Vector2(start_x + i * step, y_pos))
			
	elif _dic.has("brokenCombo"):
		print("执行环形火焰保护圈逻辑")
		var radius = 150.0
		for i in range(5):
			var angle = i * (TAU / 5.0)
			var offset = Vector2(cos(angle), sin(angle)) * radius
			pos_array.append(center_pos + offset)
			
	elif _dic.has("APSpent"):
		print("执行高能蓝火逻辑")
		var padding = 50.0
		var pos = Vector2(
			randf_range(padding, view_size.x - padding),
			randf_range(padding, view_size.y - padding)
		)
		pos_array.append(pos)
		
	else:
		print("执行常规随机火海逻辑")
		var padding = 50.0
		var pos = Vector2(
			randf_range(padding, view_size.x - padding),
			randf_range(padding, view_size.y - padding)
		)
		pos_array.append(pos)
	
	print("Molotov positions:", pos_array)
