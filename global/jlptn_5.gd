extends Node
var jlptN5_Data:Dictionary
var jlptN4_Data:Dictionary
var wordBookPath:Dictionary={
	"JLPTN5":'res://word/JLPTN5.csv',
	"JLPTN4":'res://word/JLPTN4.csv'
}

var word_data:Dictionary={}
var wordBookList:Array=[
	"JLPTN5",
]
var currentWordBookList:Array=[]
var allCurrentKeys:Array=[]
var allCurrentWordData:Dictionary={}
var allErrorWord:Array
var allcorrectWord:Array
var errorWord:Dictionary
var correctWord:Dictionary
var savedErrorWord
func _ready() -> void:
	_loadWord()
	Eventmanger.restartGame.connect(_restartGame)
	Eventmanger.saveErrorWord.connect(_saveErrorWord)
	Eventmanger.gameover.connect(_clearWord)

func _addErrorWord(sword:Dictionary):
	errorWord.set(sword.get("假名"),sword)
	
func _addCorrectWord(sword:Dictionary):
	correctWord.set(sword.get("假名"),sword)

func _clearWord():
	allcorrectWord.append_array(correctWord.values())
	allErrorWord.append_array(errorWord.values())
	errorWord.clear()
	correctWord.clear()

func _restartGame():
	allcorrectWord.clear()
	allErrorWord.clear()
	pass


func _saveErrorWord():
	var savepath = "user://saveErrorWordData.json"
	var exitWord:Array = []
	if FileAccess.file_exists(savepath):
		var openData = FileAccess.open(savepath,FileAccess.READ)
		if openData:
			var tempjson = openData.get_as_text()
			var tempData = JSON.parse_string(tempjson)
			if typeof(tempData) == TYPE_ARRAY:
				exitWord = tempData
			else:
				push_error("数据加载失败")
		openData.close()
	var file = FileAccess.open(savepath,FileAccess.WRITE)
	if file:
		if not exitWord.is_empty():
			for i in exitWord:
				if not allErrorWord.has(i):
					allErrorWord.append(i)
		var tempjson = JSON.stringify(allErrorWord,"\t")
		file.store_string(tempjson)
	else:
		print("保存失败")
func _loadErrorWord():
	var savepath = "user://saveErrorWordData.json"

	if FileAccess.file_exists(savepath):
		var openData = FileAccess.open(savepath,FileAccess.READ)
		if openData:
			var tempjson = openData.get_as_text()
			var tempData = JSON.parse_string(tempjson)
			if typeof(tempData) == TYPE_ARRAY:
				savedErrorWord = tempData
			else:
				push_error("数据加载失败")
		openData.close()
	pass
	
func _loadWord():
	for y in wordBookPath:
		var tempWordData:Dictionary
		var file = FileAccess.open(wordBookPath.get(y),FileAccess.READ)
		if file == null:
			push_error(y+"单词csv文件读取失败，by:jlptn_5.gd")
			continue
		else:
			var headers = file.get_csv_line()
			if not "中文翻译" in headers:
				file.close()
				push_error("文件异常，没有中文翻译，无法使用这一行作为唯一id，by:jlptn_5.gd,002")
				continue
			while not file.eof_reached():
				var line_Data = file.get_csv_line()
				if line_Data.size() <= 1 and line_Data[0] =="":
					continue
				if line_Data.size() != headers.size():
					continue
				var row_dir ={}
				for i in range(headers.size()):
					var head = headers[i]
					var temp = line_Data[i]
					row_dir[head] = temp
				tempWordData[row_dir["中文翻译"]] = row_dir
			file.close()
			word_data.set(y,tempWordData)
			print(y+"单词加载完毕共载入单词",tempWordData.size(),"个。by：jlpt_n5.gd")


func sendWordData():
	var tempdata:Dictionary={}
	for i in wordBookList:
		if not word_data.has(i):
			push_error("单词本"+ str(i)+"无法加载")
			continue
		tempdata.merge(word_data.get(i))
	return tempdata

func _setWordBookList(list:Array):
	wordBookList.clear()
	wordBookList=list
	
func _getNextWordData():
	var tiltle:Dictionary
	if allCurrentKeys.size() >=4:
		var temp = allCurrentKeys.pop_back()
		tiltle[temp] = allCurrentWordData.get(temp)
	return tiltle
	
func _getErrorWordData():
	var ran:Array
	var selectErrorWord:Array
	ran.resize(2)
	for i in range(2):
		ran[i] = randi()%allCurrentKeys.size()
		var temp = allCurrentWordData.get(allCurrentKeys[ran[i]])
		if not temp.get("日语汉字").is_empty():
			if randi()%10 < 8:
				selectErrorWord.append(temp.get("日语汉字"))
			else :
				selectErrorWord.append(temp.get("假名"))
		else :
			selectErrorWord.append(temp.get("假名"))
	return selectErrorWord

func _gameStart():
	if currentWordBookList != wordBookList:
		currentWordBookList = wordBookList
		allCurrentWordData = sendWordData()
		allCurrentKeys = allCurrentWordData.keys()
		allCurrentKeys.shuffle()

		
