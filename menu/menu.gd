extends Control
@onready var start_button: TextureButton = $HBoxContainer/startButton
@onready var set_panel: Panel = $setPanel
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

func _on_back_pressed() -> void:
	connectWordSelectButton()
	set_panel.hide()
	pass # Replace with function body.

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
			get_tree().root.add_child(line)
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
