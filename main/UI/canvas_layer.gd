extends CanvasLayer
const LIGHTNING = preload('res://asset/lightning.png')
@onready var action_point: HBoxContainer = $HBoxContainer/actionPoint
@onready var word_confirm: Control = $wordConfirm
@onready var shoping: Control = $shoping
@onready var card_pile: TextureRect = $card_pile
@onready var path_2d: Path2D = $Path2D
@onready var gameover: Control = $gameover
@onready var fps: Label = $FPS
@onready var skill_assembly: Control = $skillAssembly


var main
func _ready() -> void:
	main = get_tree().get_first_node_in_group(&'main') 
	Eventmanger.actionPointUp.connect(actionPointUpfunc)
	Eventmanger.actionPointSub.connect(actionPointSubfunc)
	Eventmanger.UIHideAll.connect(hideAll)
	Eventmanger.NextLevel.connect(ShowAll)
	Eventmanger.UIShowAll.connect(ShowAll)
	resetActionPoint()
	
func _process(_delta: float) -> void:
	var current_fps = Performance.get_monitor(Performance.TIME_FPS)
	fps.text = "FPS: "+str(current_fps)
	pass
	
func resetActionPoint():
	for i in action_point.get_children():
		i.queue_free()
	for i in range(main.power):
		actionPointUpfunc()
func actionPointUpfunc():
	var temptexture = TextureRect.new()
	temptexture.texture =LIGHTNING
	temptexture.clip_contents = true
	temptexture.custom_minimum_size = Vector2(30,30)
	temptexture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	temptexture.stretch_mode = TextureRect.STRETCH_SCALE
	action_point.add_child.call_deferred(temptexture)
	pass

func actionPointSubfunc():
	action_point.get_child(0).queue_free()

func hideAll(_node):
	for i in self.get_children():
		i.hide()
	_node.show()
	
func ShowAll():
	for i in self.get_children():

		if i.is_in_group("popup"):
			i.hide()
		#if i == word_confirm or i == shoping or i == gameover or i == skill_assembly:
		else:
			i.show()

func setPath2dPosition():
	path_2d.curve.set_point_position(0,card_pile.global_position)
	
	
