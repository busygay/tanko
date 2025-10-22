extends Control
@onready var color_rect: ColorRect = $ColorRect
var scencePath:Array
var loadPro:Array
var iSloadInPro:bool
var loadingObjPath
func _process(_delta: float) -> void:
	if iSloadInPro:
		ResourceLoader.load_threaded_get_status(loadingObjPath,loadPro)
		var mat = color_rect.material as ShaderMaterial
		mat.set_shader_parameter("animation_progress",loadPro[0])
		if loadPro[0] == 1:
			var temp = ResourceLoader.load_threaded_get(loadingObjPath)
			get_tree().change_scene_to_packed(temp)
			loadPro.clear()
			iSloadInPro=false
			loadingObjPath=""
			var tween = get_tree().create_tween()
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(mat,"animation_progress",0,0.3)

###加载资源
func loadPath(path:String):
	ResourceLoader.load_threaded_request(path)
	scencePath.append(path)

func getResource(path):
	pass

###切换场景
func changeScence(path:String):
	var temp = ResourceLoader.load_threaded_get_status(path,loadPro)
	match temp:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			scencePath.append(path)
		ResourceLoader.THREAD_LOAD_FAILED:
			print("资源加载失败:"+path)
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			iSloadInPro = true
			loadingObjPath=path
		ResourceLoader.THREAD_LOAD_LOADED:
			var obj = ResourceLoader.load_threaded_get(path)
			var tween = get_tree().create_tween()
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(color_rect.material,"shader_parameter/animation_progress",1.0,0.3)
			tween.tween_callback(func():
				get_tree().change_scene_to_packed(obj)
				if get_tree().paused == true:
					get_tree().paused = false
				)
			tween.tween_property(color_rect.material,"shader_parameter/animation_progress",0,0.3)
			scencePath.erase(path)
"""
func loading(main,_ready:bool,pro:Array):
	if _ready == true:
		var tween = get_tree().create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(color_rect.material,"shader_parameter/animation_progress",1.0,0.3)
		tween.tween_callback(func():
			get_tree().change_scene_to_packed(main)
			get_tree().paused = false
			)
		tween.tween_property(color_rect.material,"shader_parameter/animation_progress",0,0.3)
		
	else:
		var mat = color_rect.material as ShaderMaterial
		mat.set_shader_parameter("animation_progress",pro[0])
		if pro[0] == 1:
			get_tree().change_scene_to_packed(main)
			var tween = get_tree().create_tween()
			
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(mat,"animation_progress",0,0.3)

"""

func _notification(what: int) -> void:
	match what:
		Node.NOTIFICATION_EXIT_TREE:
			for i in scencePath:
				var _temp = ResourceLoader.load_threaded_get(i)
				
