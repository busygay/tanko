extends Control

@onready var v_box_container: VBoxContainer = $Panel/MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/Panel/HBoxContainer/ScrollContainer/VBoxContainer
@onready var scroll_container: ScrollContainer = $Panel/MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/Panel/HBoxContainer/ScrollContainer

# 使用枚举来定义显示模式，更清晰
var menuPath:String = 'res://menu/menu.tscn'
var loadPro:Array
var loading:bool =false
enum DisplayMode {
	NONE,
	CORRECT,
	ERROR
}

var current_mode: DisplayMode = DisplayMode.NONE
var error_words: Array
var correct_words: Array
var current_index: int = 0

var v_scrollbar: VScrollBar
var label_settings: LabelSettings
var is_loading: bool = false # 使用更具描述性的变量名替换 lock
const BATCH_SIZE = 25 # 定义每批加载的数量为一个常量

func _ready() -> void:
	ChangeScenceLoad.loadPath(menuPath)
	hide()
	label_settings = LabelSettings.new()
	label_settings.font_size = 32
	v_scrollbar = scroll_container.get_v_scroll_bar()
	
	# 假设 Jlptn5 是一个 autoload/singleton
	error_words = Jlptn5.allErrorWord
	correct_words = Jlptn5.allcorrectWord
	
	Eventmanger.gameover.connect(show_game_over)

func _process(_delta: float) -> void:
	# 只在列表可见且未在加载时检查滚动位置
	if not visible or is_loading or current_mode == DisplayMode.NONE:
		return

	# 检查是否滚动到底部附近，如果是，则加载下一批
	# v_scrollbar.max_value > 0 确保在内容不足一页时不会触发
	if v_scrollbar.max_value > 0 and v_scrollbar.value >= v_scrollbar.max_value * 0.95:
		_load_word_batch()
	if loading == true:
		var menu 
		if ResourceLoader.load_threaded_get_status(menuPath,loadPro)==ResourceLoader.THREAD_LOAD_LOADED:
			@warning_ignore('unassigned_variable')
			menu = ResourceLoader.load_threaded_get(menu)
		ChangeScenceLoad.loading(menu,false,loadPro)
func show_game_over() -> void:
	show()
	# 默认显示错误单词列表
	_on_error_pressed()
	

# 清空VBoxContainer中的所有Label
func _clear_list() -> void:
	for child in v_box_container.get_children():
		child.queue_free()

func _on_correct_pressed() -> void:
	if current_mode == DisplayMode.CORRECT:
		return
	
	current_mode = DisplayMode.CORRECT
	current_index = 0
	_clear_list()
	_load_word_batch()

func _on_error_pressed() -> void:
	if current_mode == DisplayMode.ERROR:
		return
	current_mode = DisplayMode.ERROR
	current_index = 0
	_clear_list()
	_load_word_batch()

# 合并后的通用加载函数
func _load_word_batch() -> void:
	if is_loading:
		return
	
	var source_array: Array
	match current_mode:
		DisplayMode.CORRECT:
			source_array = correct_words
		DisplayMode.ERROR:
			source_array = error_words
		_: # 如果是 NONE 或其他情况，则不加载
			return

	# 如果所有单词都已加载，则返回
	if current_index >= source_array.size():
		return

	is_loading = true
	
	var count = min(BATCH_SIZE, source_array.size() - current_index)
	
	for i in range(count):
		var word_data:Dictionary = source_array[current_index]
		var temp_word: String
		if  not word_data.get("日语汉字").is_empty():
			temp_word = word_data.get("日语汉字")
		else:
			temp_word = word_data.get("假名")
			
		var temp_label = Label.new()
		temp_label.label_settings = label_settings
		# 【关键修正】设置文本并添加到场景树
		temp_label.text = "%d. %s" % [current_index + 1, temp_word] # 加上序号更友好
		v_box_container.add_child(temp_label)
		
		current_index += 1
	
	# 使用 call_deferred 确保在下一帧重置 is_loading 状态，
	# 避免因UI更新延迟导致滚动条max_value未及时更新而连续触发加载。
	call_deferred("_reset_loading_flag")

func _reset_loading_flag():
	is_loading = false

func _on_restart_button_pressed() -> void:
	Eventmanger.saveErrorWord.emit()
	Eventmanger.restartGame.emit()
	_changeScenceToMenu()
	hide() # 游戏重新开始时隐藏这个界面
	

func _on_do_not_add_error_book_pressed() -> void:
	Eventmanger.restartGame.emit()
	_changeScenceToMenu()
	hide() # 游戏重新开始时隐藏这个界面


	
func _changeScenceToMenu():
	ChangeScenceLoad.changeScence(menuPath)
		
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
