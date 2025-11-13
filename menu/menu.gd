extends Control
@onready var start_button: TextureButton = $HBoxContainer/startButton
@onready var set_panel: Panel = $setPanel
@onready var error_word_panel: Panel = $ErrorWordPanel
@onready var error_word_vbox: VBoxContainer = %ErrorWordVBox
@onready var button_v_box_container: VBoxContainer = $setPanel/MarginContainer/NinePatchRect/VBoxContainer/MarginContainer/Panel/MarginContainer/HBoxContainer/MarginContainer/ColorRect/buttonVBoxContainer

###控制背景用
@onready var bg_player: Node2D = $BG/bgPlayer
@onready var bg_enemy_example: AnimatedSprite2D = $BG/bgEnemyExample
@onready var bg_enemy_box: Node2D = $BG/bgEnemyBox
@onready var bg_spawn_timer: Timer = $BG/bgSpawnTimer
var bgInEyeBox:Array

var loadmain
var loadProgress:Array
var loadAnima:bool = false
var wordBook:Array=[]
var mainPath:String="res://main/main.tscn"

func _ready() -> void:
	if get_tree().paused ==true:
		get_tree().paused =false
	set_panel.hide()
	error_word_panel.hide()
	ChangeScenceLoad.loadPath(mainPath)
	bg_player.get_node(^"body").play("idle")
	bg_player.get_node(^"gun").play("idle")
func _process(_delta: float) -> void:
	BG()

func _on_start_button_pressed() -> void:
	ChangeScenceLoad.changeScence(mainPath)

func _on_set_btton_pressed() -> void:
	set_panel.show()
	pass # Replace with function body.

func _on_error_word_button_pressed() -> void:
	_loadErrorWordData()
	error_word_panel.show()

func _on_back_pressed() -> void:
	connectWordSelectButton()
	set_panel.hide()
	pass # Replace with function body.

func _on_error_word_back_pressed() -> void:
	error_word_panel.hide()

func connectWordSelectButton():
	wordBook.clear()
	for i in button_v_box_container.get_children():
		if i.button_pressed == true:
			wordBook.append(i.text)
	if wordBook.is_empty():
		wordBook.append("JLPTN5")
	Jlptn5._setWordBookList(wordBook)
	pass
	
func BG():
	var gun:AnimatedSprite2D= bg_player.get_node(^"gun") as AnimatedSprite2D
	if not bgInEyeBox.is_empty():
		var enemy:Node=bgInEyeBox[0]
		gun.look_at(enemy.global_position)
		if gun.animation !="att":
			enemy=bgInEyeBox.pop_front()
			var body:AnimatedSprite2D=bg_player.get_node(^"body") as AnimatedSprite2D
			body.play("att")
			gun.play("att")
			AudioManager.play_sfx_at_position("22LRSingleMP3",gun.global_position)
			enemy.queue_free()
			var line = Line2D.new()
			line.width =1
			var startPoint:Vector2 = gun.get_node("Marker2D").global_position
			var endPoint:Vector2 = enemy.global_position
			line.points = [startPoint,endPoint]
			get_parent().add_child(line)
			var timer = get_tree().create_timer(0.1)
			timer.timeout.connect(func():
				line.queue_free()
				)
			gun.animation_finished.connect(func():
				body.play("idle")
				gun.play("idle")
				)

func _on_bg_spawn_timer_timeout() -> void:
	var temp:AnimatedSprite2D = bg_enemy_example.duplicate()
	temp.play("walk")
	temp.show()
	temp.startMove(bg_player)
	bg_enemy_box.add_child(temp)
	bg_spawn_timer.start(randf_range(1,4))
	pass # Replace with function body.

func _loadErrorWordData() -> void:
	print("menu _loadErrorWordData: 开始加载错题数据")
	# 清空现有的错题显示
	for child in error_word_vbox.get_children():
		child.queue_free()
	
	# 重新加载错误单词数据
	Jlptn5._loadErrorWord()
	
	# 从Jlptn5获取保存的错题数据
	var saved_error_words = Jlptn5.savedErrorWord
	
	print("menu _loadErrorWordData: 从 Jlptn5 获取到 %d 个错误单词" % saved_error_words.size())
	
	if saved_error_words.is_empty():
		print("menu _loadErrorWordData: 没有错题记录")
		var no_data_label = Label.new()
		no_data_label.text = "暂无错题记录"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_data_label.add_theme_font_size_override("font_size", 32)
		error_word_vbox.add_child(no_data_label)
		return
	
	# 按错误次数排序（从高到低）
	saved_error_words.sort_custom(func(a, b): return a.error_count > b.error_count)
	
	print("menu _loadErrorWordData: 开始创建 %d 个错题条目" % saved_error_words.size())
	
	# 创建错题条目
	for error_word_data in saved_error_words:
		var word_data = error_word_data.word_data
		var error_count = error_word_data.error_count
		
		var word_item = Panel.new()
		word_item.custom_minimum_size = Vector2(0, 80)
		
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 20)
		
		
		# 单词信息
		var word_label = Label.new()
		var word_text = word_data.get("日语汉字", "")
		if word_text.is_empty():
			word_text = word_data.get("假名", "")
		word_label.text = word_text
		word_label.add_theme_font_size_override("font_size", 28)
		word_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# 假名
		var kana_label = Label.new()
		kana_label.text = word_data.get("假名", "")
		kana_label.add_theme_font_size_override("font_size", 24)
		kana_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# 中文翻译
		var meaning_label = Label.new()
		meaning_label.text = word_data.get("中文翻译", "")
		meaning_label.add_theme_font_size_override("font_size", 24)
		meaning_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# 错误次数
		var error_count_label = Label.new()
		error_count_label.text = "错误: %d次" % error_count
		error_count_label.add_theme_font_size_override("font_size", 24)
		error_count_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		
		hbox.add_child(word_label)
		hbox.add_child(kana_label)
		hbox.add_child(meaning_label)
		hbox.add_child(error_count_label)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_top", 5)
		margin.add_theme_constant_override("margin_bottom", 5)
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_child(hbox)
		
		word_item.add_child(margin)
		error_word_vbox.add_child(word_item)
	
	print("menu _loadErrorWordData: 错题条目创建完成")


###debug用寻找孤立实例
func check_leaked_object(id):
	print("--- 正在检查实例 ID: ",id, " ---")
	
	# 使用 instance_from_id 查找对象
	var obj = instance_from_id(id)
	
	if is_instance_valid(obj):
		print("!!! 找到了对象 !!!")
		print("  - 对象类型 (Class): ", obj.get_class())
		print("  - 对象的脚本 (Script): ", obj.get_script())
		print("  - 对象的字符串表示: ", str(obj))
		# 我们可以尝试获取更多信息
		if obj is Resource:
			print("  - 这是一个资源, 路径: ", obj.resource_path)

		if obj is SceneTreeTimer:
			print("  - 这是一个 SceneTreeTimer!")
			print("    - 剩余时间: ", obj.time_left)

		if obj is Tween:
			print("  - 这是一个 Tween!")

	else:
		print("--- 对象未找到或已失效 ---")


func _on_area_2d_area_entered(area: Area2D) -> void:
	var temp =  area.get_parent()
	if temp.has_method("startMove"):
		bgInEyeBox.append(temp)
	pass # Replace with function body.


func _on_check_button_toggled(toggled_on: bool) -> void:
	globalSet.isTestMode = toggled_on
	
	pass # Replace with function body.
