extends Node


var isTestMode:bool = false
var wordBookList:Array=[
	"JLPTN5"
]
var BGMSoundVolume:float=1
var GUNSoundVolume:float=1
var enableObfuscationWord:bool = false



var saveSettingsPath:String="user://settings.json"

func _ready() -> void:
	loadSettings()


func _exit_tree() -> void:
	svaeSettings()



func svaeSettings() -> void:
	var saveData:Dictionary = {
		"isTestMode": isTestMode,
		"wordBookList": wordBookList,
		"enableObfuscationWord": enableObfuscationWord
	}
	var jsonData= JSON.stringify(saveData)
	var file = FileAccess.open(saveSettingsPath, FileAccess.WRITE)
	if file:
		file.store_string(jsonData)
		file.close()
	else:
		push_error("无法打开设置保存文件进行写入！")


func loadSettings() -> void:
	var file = FileAccess.open(saveSettingsPath, FileAccess.READ)
	if file:
		
		var jsonData = file.get_as_text()
		var loadData = JSON.parse_string(jsonData)
		
		if loadData != null:
			
			isTestMode = loadData.get("isTestMode", false)
			if loadData.get("wordBookList", null) == null or loadData.get("wordBookList").is_empty():
				wordBookList = ["JLPTN5"]
			else:
				wordBookList =loadData.get("wordBookList")
			enableObfuscationWord = loadData.get("enableObfuscationWord", false)
		
		else:
			push_error("设置文件解析错误，使用默认设置！")
		file.close()
	else:
		push_warning("设置文件不存在，使用默认设置！")

func setIsTestMode(value: bool) -> void:
	isTestMode = value

func setWordBookList(bookList: Array) -> void:
	wordBookList = bookList

func setEnableObfuscationWord(value: bool) -> void:
	enableObfuscationWord = value
