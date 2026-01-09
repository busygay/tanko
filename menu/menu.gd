extends Control
@onready var start_button: TextureButton = $HBoxContainer/startButton
@onready var set_panel: Panel = $setPanel
@onready var error_word_panel: Panel = $ErrorWordPanel
@onready var error_word_vbox: VBoxContainer = %ErrorWordVBox

@onready var error_word_data_button: Button = $ErrorWordPanel/MarginContainer/NinePatchRect/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer/errorWordData
@onready var rebuild_error_word_data_button: Button = $ErrorWordPanel/MarginContainer/NinePatchRect/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer/reBuildErrorWordData
@onready var header: HBoxContainer = error_word_vbox.get_node("header")
@onready var testmodeButton: CheckButton= $setPanel/MarginContainer/NinePatchRect/VBoxContainer/testmode/CheckButton
@onready var wordListVbox :VBoxContainer =$setPanel/MarginContainer/NinePatchRect/VBoxContainer/MarginContainer/Panel/MarginContainer/HBoxContainer/MarginContainer/ColorRect/wordListVbox

###混淆词功能的启停
@onready var obfuscation_mode: MarginContainer = $setPanel/MarginContainer/NinePatchRect/VBoxContainer/ObfuscationMode

var obfuscation_tooltip: Panel = null
var obfuscation_tooltip_label: Label = null



###控制背景用
@onready var bg_player: Node2D = $BG/bgPlayer
@onready var bg_enemy_example: AnimatedSprite2D = $BG/bgEnemyExample
@onready var bg_enemy_box: Node2D = $BG/bgEnemyBox
@onready var bg_spawn_timer: Timer = $BG/bgSpawnTimer
var bgInEyeBox:Array

var loadmain
var loadProgress:Array
var loadAnima:bool = false
var mainPath:String="res://main/main.tscn"

var wordBook:Array=[]
var isTestMode:bool=false

func _ready() -> void:
	if get_tree().paused ==true:
		get_tree().paused =false
	set_panel.hide()
	error_word_panel.hide()
	ChangeScenceLoad.loadPath(mainPath)
	bg_player.get_node(^"body").play("idle")
	bg_player.get_node(^"gun").play("idle")
	
	# 创建混淆词提示面板
	_create_obfuscation_tooltip()
	
	# 连接错题本相关按钮信号
	error_word_data_button.pressed.connect(_on_error_word_data_button_pressed)
	rebuild_error_word_data_button.pressed.connect(_on_rebuild_error_word_data_button_pressed)
	#	添加单词库列表
	_addWordBookCheckBox()
	_readSvaeData()
	
	print("menu.gd _ready 完成")



func _addWordBookCheckBox():
	var wordBookPathKeys =Jlptn5.wordBookPath.keys()
	for i in wordBookPathKeys:
		var tempCheckBtton =CheckBox.new()
		tempCheckBtton.name = i
		tempCheckBtton.text = i
		tempCheckBtton.add_theme_font_size_override("font_size",28)
		wordListVbox.add_child(tempCheckBtton)
	

# 创建混淆词提示面板
func _create_obfuscation_tooltip():
	# 创建提示面板
	obfuscation_tooltip = Panel.new()
	obfuscation_tooltip.z_index = 100
	obfuscation_tooltip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	obfuscation_tooltip.set_position(Vector2(0, 0))
	obfuscation_tooltip.hide()
	
	# 创建样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.7, 1.0, 1.0)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	obfuscation_tooltip.add_theme_stylebox_override("panel", style_box)
	
	# 创建标签
	obfuscation_tooltip_label = Label.new()
	obfuscation_tooltip_label.text = "tips:使用JLPTN1词库和N2词库,混淆词模式会造成奇怪的bug"
	obfuscation_tooltip_label.add_theme_font_size_override("font_size", 20)
	obfuscation_tooltip_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	obfuscation_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	obfuscation_tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	obfuscation_tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	obfuscation_tooltip_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 将标签添加到面板
	obfuscation_tooltip.add_child(obfuscation_tooltip_label)
	
	# 将提示面板添加到场景中（添加到根节点）
	add_child(obfuscation_tooltip)
	

func _readSvaeData() -> void:
	isTestMode = globalSet.isTestMode
	wordBook = globalSet.wordBookList.duplicate()
	Jlptn5._setWordBookList(wordBook)
	Jlptn5.setEnableObfuscationWord(globalSet.enableObfuscationWord)
	##设置单词本选择按钮状态
	for i in wordListVbox.get_children():
		if wordBook.has(i.text):
			i.button_pressed = true
		else:
			i.button_pressed = false
	##设置测试模式按钮状态
	testmodeButton.button_pressed = isTestMode
	pass # Replace with function body




func _process(_delta: float) -> void:
	BG()

func _on_start_button_pressed() -> void:
	ChangeScenceLoad.changeScence(mainPath)

func _on_set_btton_pressed() -> void:
	set_panel.show()
	pass # Replace with function body.

func _on_error_word_button_pressed() -> void:
	_loadErrorWordData("error_book")  # 默认显示错题本
	error_word_panel.show()


##发送单词本选择变化给JLPNT5，并向globalSet发生设置
func _on_back_pressed() -> void:
	connectWordSelectButton()
	globalSet.setIsTestMode(isTestMode)
	globalSet.setWordBookList(wordBook)
	globalSet.setEnableObfuscationWord(Jlptn5.enableObfuscationWord)
	set_panel.hide()
	pass # Replace with function body.

func _on_error_word_back_pressed() -> void:
	error_word_panel.hide()

func connectWordSelectButton():
	wordBook.clear()
	for i in wordListVbox.get_children():
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

func _loadErrorWordData(display_mode: String) -> void:
	print("menu _loadErrorWordData: 开始加载数据，显示模式: %s" % display_mode)
	# 清空现有的显示内容
	for child in error_word_vbox.get_children():
		if child.name == "header":
			continue  # 保留头部
		child.queue_free()
	
	# 重新加载错误单词数据
	Jlptn5._loadErrorWord()
	
	# 从Jlptn5获取保存的错题数据
	var saved_error_words = Jlptn5.savedErrorWord
	var masetredWord = Jlptn5.masteredWord
	print("menu _loadErrorWordData: 从 Jlptn5 获取到 %d 个单词数据" % saved_error_words.size())
	
	# 根据显示模式筛选数据
	var display_data = []
	
	if display_mode == "error_book":
		# 错题本模式：只显示错误次数大于0的单词
		for wordKey in saved_error_words:
			display_data.append(saved_error_words.get(wordKey))
		print("menu _loadErrorWordData: 错题本模式，筛选出 %d 个错题" % display_data.size())
	elif display_mode == "rebuild_book":
		# 单词重组词库模式：显示所有单词（包括已掌握的）
		for wordkey in masetredWord:
			display_data.append(masetredWord.get(wordkey))
		print("menu _loadErrorWordData: 单词重组词库模式，共 %d 个单词" % display_data.size())
	
	if display_data.is_empty():
		print("menu _loadErrorWordData: 没有数据记录")
		var no_data_label = Label.new()
		if display_mode == "error_book":
			no_data_label.text = "暂无错题记录"
		else:
			no_data_label.text = "暂无单词记录"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_data_label.add_theme_font_size_override("font_size", 32)
		error_word_vbox.add_child(no_data_label)
		return
	
	#无需创建头部，头部不会被删除。
	#var header = _createWordHeader()
	#error_word_vbox.add_child(header)

	# 按错误次数排序（从高到低），对于单词重组词库模式，已掌握的（error_count=0）排在后面
	if display_mode == "error_book":

		display_data.sort_custom(func(a, b):
			if a.error_count == 0 and b.error_count > 0:
				return false
			elif a.error_count > 0 and b.error_count == 0:
				return true
			else:
				return a.error_count > b.error_count
	)
	
	print("menu _loadErrorWordData: 开始创建 %d 个单词条目" % display_data.size())
	
	# 创建单词条目
	for word_entry in display_data:
		var word_data = word_entry
		var error_count = word_entry.get("error_count","--")
		var word_item = _createWordItem(word_data, error_count, display_mode,)
		error_word_vbox.add_child(word_item)
	
	print("menu _loadErrorWordData: 单词条目创建完成")


func _createWordItem(word_data: Dictionary, error_count, display_mode: String) -> HBoxContainer:
	var tempWordHbox:HBoxContainer = header.duplicate()

	var tempJapaneseLabel:Label = tempWordHbox.get_child(0) as Label
	var tempChineseLabel:Label = tempWordHbox.get_child(1) as Label
	var tempCountLabel:Label = tempWordHbox.get_child(2) as Label
	tempJapaneseLabel.text = word_data.get("日语汉字", "")
	if tempJapaneseLabel.text.is_empty():
		tempJapaneseLabel.text = word_data.get("假名", "")
	tempChineseLabel.text = word_data.get("中文翻译", "")
	if display_mode == "error_book":
		# 错题本模式：显示错误次数
		tempCountLabel.text = "错误: %d次" % error_count
		tempCountLabel.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	else:
		tempCountLabel.text = "--" 
		# 单词重组词库模式：用"-"代替次数
		pass
	return tempWordHbox


func _on_error_word_data_button_pressed() -> void:
	print("错题本按钮被按下")
	_loadErrorWordData("error_book")

func _on_rebuild_error_word_data_button_pressed() -> void:
	print("单词重组词库按钮被按下")
	_loadErrorWordData("rebuild_book")


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

###测试模式
func _on_check_button_toggled(toggled_on: bool) -> void:
	isTestMode = toggled_on
	
	pass # Replace with function body.


func _on_obfuscation_check_button_toggled(toggled_on: bool) -> void:
	Jlptn5.setEnableObfuscationWord(toggled_on)


func _on_obfuscation_mode_mouse_entered() -> void:
	print("鼠标进入混淆词模式区域")
	# 鼠标进入时显示提示（仅当设置面板可见时）
	if set_panel.visible and obfuscation_tooltip:
		# 获取 obfuscation_mode 的全局位置
		var obfuscation_global_pos = obfuscation_mode.global_position
		var obfuscation_size = obfuscation_mode.size
		
		# 计算提示面板位置（在 obfuscation_mode 右侧）
		var tooltip_pos = Vector2(
			obfuscation_global_pos.x + obfuscation_size.x + 10,
			obfuscation_global_pos.y
		)
		
		# 设置提示面板位置和大小
		obfuscation_tooltip.set_position(tooltip_pos)
		obfuscation_tooltip.custom_minimum_size = Vector2(400, 100)
		
		# 显示提示面板
		obfuscation_tooltip.show()



func _on_obfuscation_mode_mouse_exited() -> void:
	print("鼠标退出混淆词模式区域")
	# 鼠标退出时隐藏提示
	if obfuscation_tooltip:
		obfuscation_tooltip.hide()
