extends Control

@onready var v_box_container: VBoxContainer = $Panel/MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/Panel/HBoxContainer/ScrollContainer/VBoxContainer
@onready var scroll_container: ScrollContainer = $Panel/MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/Panel/HBoxContainer/ScrollContainer
@onready var rich_text_label: RichTextLabel = $Panel/MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/MarginContainer/RichTextLabel
@onready var header: HBoxContainer = $Panel/MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/Panel/HBoxContainer/ScrollContainer/VBoxContainer/header




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
var error_words: Dictionary
var correct_words: Dictionary
var current_index: int = 0
var current_keys:Array = []

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
	var correct_count: int = Jlptn5.allcorrectWord.size()
	var error_count: int = Jlptn5.allErrorWord.size()
	var total_count: int = correct_count + error_count
	var accuracy: float = 0.0
	if total_count > 0:
		accuracy = float(correct_count) / total_count * 100.0
	
	rich_text_label.text = "此次游戏共使用%d个单词，正确数为%d，错误数为%d。准确率为%.2f%%。" % [total_count, correct_count, error_count, accuracy]
	
	# 默认显示错误单词列表
	_on_error_pressed()

# 清空VBoxContainer中的所有Label
func _clear_list() -> void:
	for child in v_box_container.get_children():
		if child.name == "header":
			continue
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
	var sourceData: Dictionary
	match current_mode:
		DisplayMode.CORRECT:
			sourceData = correct_words
		DisplayMode.ERROR:
			sourceData = error_words
		_: # 如果是 NONE 或其他情况，则不加载
			return
	current_keys = sourceData.keys()

	# 如果所有单词都已加载，则返回
	if current_index >= sourceData.size():
		return
	#开始加载上锁
	is_loading = true
	
	var count = min(BATCH_SIZE, sourceData.size() - current_index)
	
	for i in range(count):
		
		# 处理错误单词的数据结构（包含error_count）
		var temp = header.duplicate()
		var label1 = temp.get_child(0) as Label #日语
		var label2 = temp.get_child(1) as Label #中文/翻译
		var label3 = temp.get_child(2) as Label #错误次数
		var temp_word:Dictionary = sourceData.get(current_keys.get(current_index))
		
		label1.text = temp_word.get("日语汉字",null)
		if label1.text == null:
			label1.text =temp_word.get("假名",null)
		label2.text = temp_word.get("中文翻译")
		if current_mode == DisplayMode.ERROR:
			label3.text = str(temp_word.get("error_count"))
		else :
			label3.text = "--"
		current_index += 1
		header.get_parent().add_child(temp)
	# 使用 call_deferred 确保在下一帧重置 is_loading 状态，
	# 避免因UI更新延迟导致滚动条max_value未及时更新而连续触发加载。
	call_deferred("_reset_loading_flag")

func _reset_loading_flag():
	is_loading = false

func _on_restart_button_pressed() -> void:
	print("gameover _on_restart_button_pressed: 保存错题并重新开始")
	Eventmanger.saveErrorWord.emit()
	Eventmanger.restartGame.emit()
	_changeScenceToMenu()
	hide() # 游戏重新开始时隐藏这个界面
	

func _on_do_not_add_error_book_pressed() -> void:
	print("gameover _on_do_not_add_error_book_pressed: 不添加错题本，直接返回菜单")
	Eventmanger.restartGame.emit()
	_changeScenceToMenu()
	hide() # 游戏重新开始时隐藏这个界面


	
func _changeScenceToMenu():
	ChangeScenceLoad.changeScence(menuPath)
		
