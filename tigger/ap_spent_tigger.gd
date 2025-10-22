extends Node

func _ready() -> void:
	Eventmanger.APSpentEmit.connect(skillemit)
	
func skillemit():
	var count = get_child_count() 
	if count >0:
		var temp = randi_range(0,count-1)
		get_child(temp)._skillEmit()
	pass
