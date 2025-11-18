extends Control
@onready var v_box_container: VBoxContainer = $HBoxContainer/VBoxContainer
@onready var h_box_container: HBoxContainer = $HBoxContainer
const SMALL_BULLET_3 = preload('res://asset/small_bullet3.png')
func _ready() -> void:
	showAllButtel()
	Eventmanger.setbulletPos(self,false)
	Eventmanger.buttelCountChange.connect(buttelCountChange)
	#Eventmanger.playershooting.connect(showBulletCount)
	#Eventmanger.FinishReloadAmmo.connect(showreloadBulletCount)


func showAllButtel():
	for i in range(7):
		var temp = TextureRect.new()
		temp.texture = SMALL_BULLET_3
		v_box_container.add_child(temp)

func buttelCountChange(count:int):
	for i in v_box_container.get_children():
		i.hide()
	for i in range(count):
		v_box_container.get_child(i).show()



func showreloadBulletCount():
	for i in v_box_container.get_children():
		i.queue_free()
	for i in range(7):
		if v_box_container.get_children().size() <= 6:
			var temp = TextureRect.new()
			temp.texture = SMALL_BULLET_3
			v_box_container.add_child.call_deferred(temp)
	pass
func showBulletCount(count):
	if count >=7:
		return
	if v_box_container.get_children().size() != count:
		if v_box_container.get_children().size() > count:
			var tempcount:int= v_box_container.get_children().size()-count
			for i in range(tempcount):
				v_box_container.get_child(0).queue_free()
