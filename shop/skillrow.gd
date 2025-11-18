extends TextureButton
@onready var label: Label = $VBoxContainer/Label
@onready var rich_text_label: RichTextLabel = $VBoxContainer/MarginContainer2/RichTextLabel
@onready var bg_texture_rect: TextureRect = $TextureRect
@onready var skill_texture_rect: TextureRect = $VBoxContainer/MarginContainer/TextureRect
@onready var texture_rect: TextureRect = $VBoxContainer/MarginContainer/TextureRect

var Data
var skill_name:String
var tips:String
var header:String
var skill_cname:String
var SkillAssMod:bool = false
var select:bool = false
var drag_offset:Vector2
var basePos:Vector2 = Vector2(INF,INF)

var tweenbox:Tween
func _setData(_Data):
	Data = _Data
	skill_name = Data.skill_name
	header = Data.skill_type
	skill_cname = Data.skill_cname
	tips = Data.tips
	texture_rect.texture = Data.sprite
	_bbcodeset()
	pass
	

func _bbcodeset():
	label.text = header
	var bbcodeText = """[b]{skill_cname}[/b]：{tips}
	""".format({
	"skill_cname": skill_cname, # 修正了拼写
	"tips": tips
	})
	rich_text_label.text = bbcodeText
	pass

func _process(_delta: float) -> void:
	if SkillAssMod and select:
		self.global_position = get_global_mouse_position() - drag_offset*self.scale.x
		pass
	




func dissolve():
	var temp = self.material.duplicate()
	self.material = temp
	bg_texture_rect.material = temp
	skill_texture_rect.material = temp
	var tween = get_tree().create_tween()
	tween.set_parallel()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(material, "shader_parameter/dissolve_value", 0.0, 0.5)
	tween.finished.connect(func():
		_SkillAssemblyMod()
		# get_parent().remove_child(self)
		Eventmanger.setequipData.emit(self)
		Eventmanger.ShowSkillAssembly.emit()
		temp.set("shader_parameter/dissolve_value",1.0)
		)
		
func _SkillAssemblyMod():
	SkillAssMod = true
	z_index = 99



func _gui_input(event: InputEvent) -> void:
	# 只处理鼠标左键相关的事件
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		
		# --- 按下鼠标左键的逻辑 ---
		if event.is_pressed():
			if SkillAssMod:
				# 进入拖拽模式
				select = true
				# 记录初始位置 (如果还没记录过)
				if basePos == Vector2(INF, INF):
					basePos = global_position
				
				# 计算偏移
				drag_offset = get_global_mouse_position() - global_position
				
				# 提升渲染层级，确保被拖拽的图标在最上层
				z_index = 99
				mouse_filter=Control.MOUSE_FILTER_IGNORE
				tweenbox = get_tree().create_tween()
				tweenbox.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				self.pivot_offset = size/2.0
				tweenbox.set_ease(Tween.EASE_OUT_IN)
				tweenbox.parallel().tween_property(self,^"scale",Vector2(0.2,0.2),0.3)
				#tweenbox.parallel().tween_property(self,^"drag_offset",Vector2.ZERO,0.5)
			else:
				# 非拖拽模式下的点击，执行 dissolve
				print("skillRowTest。 by:skillrow.gd")
				dissolve()
		
		# --- 松开鼠标左键的逻辑 ---
		#elif event.is_released(): # 使用 is_released() 来判断松开
			#if SkillAssMod and select:
				## 结束拖拽模式
				#self.mouse_filter=Control.MOUSE_FILTER_IGNORE
				#self.mouse_filter = Control.MOUSE_FILTER_PASS
				#select = false
				#z_index = 0 # 恢复渲染层级
				#mouse_filter=Control.MOUSE_FILTER_PASS
				## 发出拖拽结束信号，无论鼠标在哪里松开
				#Eventmanger.drag_ended.emit(self, get_global_mouse_position())
				#
				## 使用Tween返回原位 (或者根据装备结果决定是否返回)
				#if tweenbox.is_running():
					#tweenbox.stop()
				#var tween = get_tree().create_tween()
				#tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				#tween.parallel().tween_property(self,^"scale",Vector2(0.8,0.8),0.3)
				#tween.parallel().tween_property(self, ^"global_position", basePos, 0.5)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# --- 按下鼠标左键的逻辑 ---
		if event.is_pressed():
			pass
		elif event.is_released():
			if SkillAssMod and select:
				# 结束拖拽模式
				self.mouse_filter=Control.MOUSE_FILTER_IGNORE
				self.mouse_filter = Control.MOUSE_FILTER_PASS
				select = false
				z_index = 0 # 恢复渲染层级
				mouse_filter=Control.MOUSE_FILTER_PASS
				# 发出拖拽结束信号，无论鼠标在哪里松开
				Eventmanger.drag_ended.emit(self, get_global_mouse_position())
				
				# 使用Tween返回原位 (或者根据装备结果决定是否返回)
				if tweenbox.is_running():
					tweenbox.stop()
				var tween = get_tree().create_tween()
				tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tween.parallel().tween_property(self,^"scale",Vector2(0.8,0.8),0.3)
				tween.parallel().tween_property(self, ^"global_position", basePos, 0.5)
