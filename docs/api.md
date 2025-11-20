# Tankou 项目 API 接口文档

## 目录

1. [事件管理器API (EventManager)](#事件管理器api-eventmanager)
   - [信号定义](#信号定义)
   - [公共方法](#公共方法)
   - [使用示例](#使用示例)

2. [题库管理系统API (Jlptn5)](#题库管理系统api-jlptn5)
   - [数据加载方法](#数据加载方法)
   - [题目生成方法](#题目生成方法)
   - [错题本管理](#错题本管理)
   - [游戏状态管理方法](#游戏状态管理方法)

3. [技能管理器API (SkillManager)](#技能管理器api-skillmanager)
   - [技能获取和装备](#技能获取和装备)
   - [资源管理](#资源管理)
   - [技能效果应用](#技能效果应用)

4. [主游戏控制器API (Main)](#主游戏控制器api-main)
   - [资源管理方法 (EP/Bullet/AP)](#资源管理方法-epbulletap)
   - [连击系统](#连击系统)
   - [升级系统](#升级系统)
   - [游戏流程控制](#游戏流程控制)

5. [敌人基类API (baseEnemy)](#敌人基类api-baseenemy)
   - [状态管理](#状态管理)
   - [属性访问](#属性访问)
   - [伤害处理](#伤害处理)
   - [行为控制](#行为控制)

6. [关卡管理器API (Level)](#关卡管理器api-level)
   - [关卡生成](#关卡生成)
   - [难度计算](#难度计算)
   - [敌人配置](#敌人配置)

7. [音频管理器API (AudioManager)](#音频管理器api-audiomanager)
   - [音频播放控制](#音频播放控制)
   - [音效资源管理](#音效资源管理)

8. [场景加载管理器API (ChangeSceneLoad)](#场景加载管理器api-changesceneload)
   - [场景切换控制](#场景切换控制)
   - [加载状态管理](#加载状态管理)
   - [过渡效果](#过渡效果)

---

## 事件管理器API (EventManager)

事件管理器是Tankou项目的核心通信中枢，负责处理游戏内所有事件的分发和监听。

### 信号定义

| 信号名 | 参数 | 触发时机 | 说明 |
|--------|------|----------|------|
| `correctcountchange` | 无 | 正确答案计数变化时 | 当玩家答对题目导致正确计数变化时触发 |
| `actionPointUp` | 无 | 行动点增加时 | 玩家获得额外行动点时触发 |
| `actionPointSub` | 无 | 行动点减少时 | 玩家消耗行动点时触发 |
| `playershooting` | 无 | 玩家射击开始时 | 玩家开始射击动作时触发 |
| `playerShooted` | 无 | 玩家射击完成时 | 玩家完成射击动作时触发 |
| `playerGotHurt` | `damage: int` | 玩家受伤时 | 玩家受到伤害时触发，传递伤害值 |
| `reloadAmmo` | 无 | 开始换弹时 | 玩家开始换弹动作时触发 |
| `FinishReloadAmmo` | 无 | 换弹完成时 | 玩家完成换弹动作时触发 |
| `bulletCountChange` | `count: int` | 弹药数量变化时 | 玩家弹药数量变化时触发，传递当前弹药数 |
| `playerbulletCount` | `count: int` | 增加单次射击子弹数 | 用于双重射击等技能，增加单次射击发射的子弹数量 |
| `parryInvincible` | 无 | 无敌状态时 | 玩家进入无敌状态时触发 |
| `playerCdSub` | 无 | 冷却减少时 | 玩家技能冷却时间减少时触发 |
| `playerBaseDamageUp` | 无 | 基础伤害提升时 | 玩家基础伤害值提升时触发 |
| `playerTrueDamageUp` | 无 | 真实伤害提升时 | 玩家真实伤害值提升时触发 |
| `playerGlobalDamageBonusChange` | `bonus: int` | 全局伤害加成变化时 | 玩家全局伤害加成变化时触发，传递加成值 |
| `answered` | `isanswer: bool` | 回答完成时 | 玩家回答题目完成时触发，传递是否正确 |
| `questionSkipped` | 无 | 题目跳过时 | 玩家选择跳过当前题目时触发 |
| `comboChange` | 无 | 连击变化时 | 玩家连击数发生变化时触发 |
| `wordReorderCompleted` | 无 | 单词重组完成时 | 玩家完成单词重组题目时触发 |
| `enterTreeEnemy` | 无 | 敌人进入场景时 | 新敌人进入场景树时触发 |
| `exitTreeEnemy` | 无 | 敌人离开场景时 | 敌人离开场景树时触发 |
| `enemySpawn` | `enemynode` | 敌人生成时 | 新敌人生成时触发，传递敌人节点 |
| `enemydeath` | `enemynode` | 敌人死亡时 | 敌人死亡时触发，传递敌人节点 |
| `spawnEnemy` | `_node` | 请求生成敌人时 | 请求生成新敌人时触发，传递敌人节点 |
| `levelOver` | 无 | 关卡结束时 | 当前关卡结束时触发 |
| `NextLevel` | 无 | 进入下一关时 | 准备进入下一关卡时触发 |
| `ShowShoping` | `levelDone: bool` | 显示商店时 | 显示商店界面时触发，传递是否完成关卡 |
| `GameStart` | 无 | 游戏开始时 | 游戏开始时触发 |
| `gameover` | 无 | 游戏结束时 | 游戏结束时触发 |
| `restartGame` | 无 | 重新开始游戏时 | 重新开始游戏时触发 |
| `saveErrorWord` | 无 | 保存错题时 | 保存错题记录时触发 |
| `UIHideAll` | `_node` | 隐藏所有UI时 | 隐藏所有UI元素时触发，传递触发节点 |
| `UIShowAll` | 无 | 显示所有UI时 | 显示所有UI元素时触发 |
| `twoComboEmit` | 无 | 2连击时 | 玩家达到2连击时触发 |
| `fiveComboEmit` | 无 | 5连击时 | 玩家达到5连击时触发 |
| `onComboEmit` | 无 | 连击持续时 | 连击状态持续时触发 |
| `brokenComboEmit` | 无 | 连击中断时 | 玩家连击中断时触发 |
| `APGainedEmit` | 无 | 获得AP时 | 玩家获得行动点时触发 |
| `APSpentEmit` | 无 | 消耗AP时 | 玩家消耗行动点时触发 |
| `setequipData` | `_node` | 设置装备数据时 | 设置装备数据时触发，传递节点 |
| `drag_ended` | `_node, pos` | 拖拽结束时 | 拖拽操作结束时触发，传递节点和位置 |
| `equipSkill` | `tiggerName, SkillNode` | 装备技能时 | 装备技能时触发，传递触发器名和技能节点 |
| `ShowSkillAssembly` | 无 | 显示技能装配时 | 显示技能装配界面时触发 |
| `ricochetShootUp` | 无 | 跳弹射击提升时 | 跳弹射击能力提升时触发 |
| `doubleShootUP` | 无 | 双重射击提升时 | 双重射击能力提升时触发 |

### 公共方法

#### `register_player(player_node)`

注册玩家节点到事件管理器。

**参数：**
- `player_node`: 玩家节点对象

**返回值：** 无

**功能说明：** 将玩家节点注册到事件管理器，使事件管理器能够访问玩家相关功能。

**调用时机：** 游戏初始化时，在玩家节点创建后调用。

**注意事项：** 必须在调用其他需要玩家引用的方法之前调用。

```gdscript
# 使用示例
Eventmanger.register_player(player_node)
```

#### `setbulletPos(_node, who: bool)`

设置子弹位置，使其与答题面板对齐。

**参数：**
- `_node`: 要设置位置的节点
- `who`: 布尔值，true表示答题面板节点，false表示子弹节点

**返回值：** 无

**功能说明：** 协调答题面板和子弹的位置关系，确保子弹正确显示在答题面板下方。

**调用时机：** 当答题面板和子弹节点都准备好时调用。

**注意事项：** 需要答题面板和子弹节点都存在才能正确设置位置。

```gdscript
# 使用示例
Eventmanger.setbulletPos(answer_panel, true)  # 设置答题面板
Eventmanger.setbulletPos(bullet_node, false)   # 设置子弹位置
```

#### `setpowerPos(_node, who: bool)`

设置能量条位置，使其与答题面板对齐。

**参数：**
- `_node`: 要设置位置的节点
- `who`: 布尔值，true表示答题面板节点，false表示能量条节点

**返回值：** 无

**功能说明：** 协调答题面板和能量条的位置关系，确保能量条正确显示在答题面板下方。

**调用时机：** 当答题面板和能量条节点都准备好时调用。

**注意事项：** 需要答题面板和能量条节点都存在才能正确设置位置。

```gdscript
# 使用示例
Eventmanger.setpowerPos(answer_panel, true)  # 设置答题面板
Eventmanger.setpowerPos(power_bar, false)    # 设置能量条位置
```

#### `reloadAmmofunc()`

执行换弹动作。

**参数：** 无

**返回值：** 无

**功能说明：** 触发玩家换弹动画。

**调用时机：** 需要换弹时调用。

**注意事项：** 通过玩家节点的动画播放器执行换弹动画。

```gdscript
# 使用示例
Eventmanger.reloadAmmofunc()  # 执行换弹动作
```

#### `addCurrentAmmo(isanswer: bool)`

根据答题结果增加弹药。

**参数：**
- `isanswer: bool` - 是否回答正确

**返回值：** 无

**功能说明：** 当玩家回答正确时增加弹药数量。

**调用时机：** 玩家完成答题时通过信号自动调用。

**注意事项：** 只有回答正确时才会增加弹药。

```gdscript
# 使用示例
Eventmanger.addCurrentAmmo(true)   # 回答正确，增加弹药
Eventmanger.addCurrentAmmo(false)  # 回答错误，不增加弹药
```

### 使用示例

#### 基本信号连接

```gdscript
# 在_ready()函数中连接信号
func _ready():
    # 连接游戏状态信号
    Eventmanger.GameStart.connect(_on_game_start)
    Eventmanger.gameover.connect(_on_game_over)
    Eventmanger.restartGame.connect(_on_restart_game)
    
    # 连接玩家状态信号
    Eventmanger.playerGotHurt.connect(_on_player_hurt)
    Eventmanger.answered.connect(_on_answered)
    Eventmanger.comboChange.connect(_on_combo_change)

# 信号处理函数
func _on_game_start():
    print("游戏开始")
    # 初始化游戏状态

func _on_player_hurt(damage: int):
    print("玩家受到伤害: ", damage)
    # 处理玩家受伤逻辑

func _on_answered(is_correct: bool):
    if is_correct:
        print("回答正确")
    else:
        print("回答错误")
```

#### 发射信号

```gdscript
# 在适当的时候发射信号
func check_answer(player_answer):
    var is_correct = validate_answer(player_answer)
    
    # 发射回答完成信号
    Eventmanger.answered.emit(is_correct)
    
    if is_correct:
        # 发射连击信号
        Eventmanger.comboChange.emit(true)
    else:
        # 发射连击中断信号
        Eventmanger.brokenComboEmit.emit()
```

---

## 题库管理系统API (Jlptn5)

题库管理系统负责管理JLPT日语单词数据，包括单词加载、题目生成、错题本管理等功能。

### 数据加载方法

#### `_loadWord()`

从CSV文件加载单词数据到内存。

**参数：** 无

**返回值：** 无

**功能说明：** 读取配置的单词本CSV文件，解析数据并存储到内存中。支持多个单词本的加载。

**调用时机：** 在_ready()函数中自动调用，游戏初始化时执行。

**注意事项：** CSV文件必须包含"中文翻译"字段作为唯一标识符。

```gdscript
# 内部调用示例
func _ready():
    _loadWord()  # 自动加载所有配置的单词本
```

#### `_loadErrorWord()`

从文件加载已保存的错误单词和已掌握单词数据。

**参数：** 无

**返回值：** 无

**功能说明：** 从用户数据目录加载错误单词和已掌握单词的JSON文件，恢复历史学习记录。

**调用时机：** 在_ready()函数中自动调用，游戏初始化时执行。

**注意事项：** 如果文件不存在，会创建新的空文件。

```gdscript
# 内部调用示例
func _ready():
    _loadErrorWord()  # 加载历史错题记录
```

#### `sendWordData()`

根据当前单词本列表返回合并后的单词数据。

**参数：** 无

**返回值：** `Dictionary` - 合并后的单词数据字典

**功能说明：** 将当前选中的所有单词本数据合并为一个字典，用于游戏中的题目生成。

**调用时机：** 游戏开始时调用，初始化当前关卡使用的单词数据。

**注意事项：** 如果单词本不存在，会输出错误信息并跳过。

```gdscript
# 使用示例
var all_words = Jlptn5.sendWordData()
print("总共加载了 ", all_words.size(), " 个单词")
```

#### `_setWordBookList(list: Array)`

设置当前使用的单词本列表。

**参数：**
- `list: Array` - 单词本名称数组

**返回值：** 无

**功能说明：** 设置游戏中使用的单词本列表，影响题目生成的单词范围。

**调用时机：** 在菜单界面选择单词本后调用。

**注意事项：** 会清空原有列表并设置新列表。

```gdscript
# 使用示例
var selected_books = ["JLPTN5", "JLPTN4"]
Jlptn5._setWordBookList(selected_books)
```

### 题目生成方法

#### `_gameStart()`

游戏开始时初始化单词数据。

**参数：** 无

**返回值：** 无

**功能说明：** 检查单词本列表是否发生变化，如果变化则重新加载和随机化单词数据。

**调用时机：** 游戏开始时，在答题界面初始化时调用。

**注意事项：** 只有当单词本列表发生变化时才会重新加载数据。

```gdscript
# 使用示例
Jlptn5._gameStart()  # 初始化游戏单词数据
```

#### `updateWordCount(word: Dictionary, count_change: int)`

更新单词的错误次数。

**参数：**
- `word: Dictionary` - 要更新的单词数据
- `count_change: int` - 错误次数变化量（-1为答对，3为答错）

**返回值：** 无

**功能说明：** 根据答题结果更新单词的错误次数，支持增加或减少错误次数。当错误次数降至0时，从错题本中移除并添加到已掌握单词列表。

**调用时机：** 答题后更新错误次数时调用。

**注意事项：** 会同时更新当前游戏错误列表和历史错误列表。

```gdscript
# 使用示例
# 答对题目，减少错误次数
var word_data = {"假名": "あかい", "中文翻译": "红色的", "日语汉字": "赤い"}
Jlptn5.updateWordCount(word_data, -1)

# 答错题目，增加错误次数
Jlptn5.updateWordCount(word_data, 3)
```

#### `getNextQuestion(type: int = 0)`

获取下一道题目数据。

**参数：**
- `type: int` - 题目类型（0为普通题目，1为错题插入，2为单词重组）

**返回值：** `Dictionary` - 包含题目数据的字典

**功能说明：** 根据指定类型生成题目数据，包括题目内容、正确选项、错误选项等。

**调用时机：** 需要生成新题目时调用。

**注意事项：** 会根据题目类型自动选择合适的数据源，如果指定类型的数据不可用会自动降级。

```gdscript
# 使用示例
# 获取普通题目
var normal_question = Jlptn5.getNextQuestion(0)
print("题目类型: ", normal_question.type)
print("题目内容: ", normal_question.tiltle)

# 获取错题复习题目
var error_question = Jlptn5.getNextQuestion(1)
print("错题复习: ", error_question.tiltle)

# 获取单词重组题目
var reorder_question = Jlptn5.getNextQuestion(2)
print("重组题目: ", reorder_question.tiltle)
```

### 错题本管理

#### 错题本管理说明

题库管理系统的错题本管理功能已整合到 `updateWordCount()` 方法中。该方法统一处理答对和答错的情况，自动维护错误单词列表和已掌握单词列表。

**主要变化：**
- 移除了独立的 `_addErrorWord()` 和 `_addCorrectWord()` 方法
- 移除了独立的 `_updateErrorWordCount()` 方法
- 所有错题本管理功能现在通过 `updateWordCount()` 方法统一处理

**使用方式：**
- 答对题目时调用 `updateWordCount(word, -1)`
- 答错题目时调用 `updateWordCount(word, 3)`

```gdscript
# 使用示例
# 答对题目，减少错误次数
var word_data = {"假名": "あかい", "中文翻译": "红色的", "日语汉字": "赤い"}
Jlptn5.updateWordCount(word_data, -1)

# 答错题目，增加错误次数
Jlptn5.updateWordCount(word_data, 3)
```

#### `_clearWord()`

游戏结束时清理当前游戏的单词数据。

**参数：** 无

**返回值：** 无

**功能说明：** 游戏结束时清理当前游戏的单词数据，将正确和错误单词保存到历史记录。

**调用时机：** 游戏结束时调用。

**注意事项：** 会清空当前游戏的错误和正确单词列表。

```gdscript
# 使用示例
Jlptn5._clearWord()  # 清理当前游戏数据
```

#### `_saveErrorWord()`

保存错误单词和已掌握单词到文件。

**参数：** 无

**返回值：** 无

**功能说明：** 保存错误单词和已掌握单词到不同文件，合并历史记录和当前游戏记录。

**调用时机：** 游戏结束时调用。

**注意事项：** 会合并已存在的错误单词记录，累加错误次数。

```gdscript
# 使用示例
Jlptn5._saveErrorWord()  # 保存错题记录
```

### 游戏状态管理方法

#### `_restartGame()`

重置游戏状态，清空所有单词记录。

**参数：** 无

**返回值：** 无

**功能说明：** 重置游戏状态，清空所有单词记录。

**调用时机：** 重新开始游戏时调用。

**注意事项：** 会清空历史累计的正确和错误单词记录。

```gdscript
# 使用示例
Jlptn5._restartGame()  # 重置游戏状态
```

### 使用示例

#### 基本单词数据管理

```gdscript
# 设置单词本列表
func setup_word_books():
    var selected_books = ["JLPTN5"]
    Jlptn5._setWordBookList(selected_books)
    
    # 开始游戏，初始化单词数据
    Jlptn5._gameStart()
    
    # 获取合并后的单词数据
    var all_words = Jlptn5.sendWordData()
    print("可用单词数量: ", all_words.size())

# 生成新题目
func generate_new_question():
    var question_data = Jlptn5.getNextQuestion(0)  # 0为普通题目
    if not question_data.is_empty():
        print("题目类型: ", question_data.type)
        print("题目内容: ", question_data.tiltle)
        print("正确选项: ", question_data.correctData)
        print("错误选项: ", question_data.selectErrorWordData)
        
        # 显示题目
        show_question(question_data)
```

#### 错题本管理

```gdscript
# 处理答题结果
func handle_answer(is_correct: bool, word_data: Dictionary):
    if is_correct:
        # 答对题目，减少错误次数
        Jlptn5.updateWordCount(word_data, -1)
    else:
        # 答错题目，增加错误次数
        Jlptn5.updateWordCount(word_data, 3)

# 游戏结束时保存数据
func on_game_over():
    # 清理当前游戏数据并保存到历史记录
    Jlptn5._clearWord()
    
    # 保存到文件
    Jlptn5._saveErrorWord()

# 错题复习
func start_error_review():
    var error_question = Jlptn5.getNextQuestion(1)  # 1为错题插入
    if not error_question.is_empty():
        print("开始错题复习: ", error_question.tiltle["中文翻译"])
        # 显示错题复习界面
        show_error_review(error_question)
```

#### 单词重组模式

```gdscript
# 单词重组模式
func start_word_reorder():
    var reorder_question = Jlptn5.getNextQuestion(2)  # 2为单词重组
    
    if not reorder_question.is_empty():
        print("单词重组题目: ", reorder_question.tiltle["中文翻译"])
        print("目标字符: ", reorder_question.correctData)
        print("干扰字符: ", reorder_question.selectErrorWordData)
        
        # 显示重组界面
        show_word_reorder(reorder_question)
    else:
        print("没有已掌握的单词可用于重组模式")
```

---

## 技能管理器API (SkillManager)

技能管理器负责管理游戏中的技能系统，包括技能加载、随机获取、装备管理等功能。

### 技能获取和装备

#### `loadAllSkill()`

加载所有技能资源到内存。

**参数：** 无

**返回值：** 无

**功能说明：** 从配置的路径加载所有技能资源到内存，并初始化技能箱。

**调用时机：** 在_ready()函数中自动调用，游戏初始化时执行。

**注意事项：** 使用异步加载，每3个技能后等待一帧以避免卡顿。

**技能路径配置：**
- `doubleShoot`: 'res://skill/resource/doubleShoot.tres'
- `cdSub`: 'res://skill/resource/cdSub.tres'
- `baseDamageUp`: 'res://skill/resource/baseDamageUp.tres'
- `ricochetShoot`: 'res://skill/resource/ricochetShoot.tres'
- `BT-7270`: 'res://skill/resource/BT-7270.tres'
- `fullPower`: 'res://skill/resource/fullPower.tres'
- `trueDamageUp`: 'res://skill/resource/trueDamageUp.tres'

```gdscript
# 内部调用示例
func _ready():
    loadAllSkill()  # 自动加载所有技能
```

#### `_getRandomSkill()`

随机获取3个技能用于商店显示。

**参数：** 无

**返回值：** `Array` - 包含3个技能资源的数组

**功能说明：** 从当前可用的技能中随机选择3个，用于商店界面显示。

**调用时机：** 商店界面需要显示技能选项时调用。

**注意事项：** 如果可用技能少于3个，返回所有可用技能。

```gdscript
# 使用示例
var random_skills = SkillManager._getRandomSkill()
for skill in random_skills:
    print("可选技能: ", skill.skill_name)
```

#### `_SubSkillBox(SkillName: String)`

从技能箱中移除一个技能。

**参数：**
- `SkillName: String` - 要移除的技能名称

**返回值：** 无

**功能说明：** 从技能箱中移除指定技能，如果技能数量大于1则减少数量，否则完全移除。

**调用时机：** 玩家购买技能后调用。

**注意事项：** 只有当技能存在于技能箱中时才会执行移除操作。

**技能初始数量配置：**
- `doubleShoot`: 1
- `cdSub`: 9
- `baseDamageUp`: 5
- `ricochetShoot`: 1
- `BT-7270`: 1
- `fullPower`: 1
- `trueDamageUp`: 5

```gdscript
# 使用示例
SkillManager._SubSkillBox("doubleShoot")  # 移除一个双重射击技能
```

#### `_resetSkillBox()`

重置技能箱到初始状态。

**参数：** 无

**返回值：** 无

**功能说明：** 将技能箱重置到初始状态，恢复所有技能和数量。

**调用时机：** 重新开始游戏或需要重置技能状态时调用。

**注意事项：** 会恢复所有技能到初始数量。

```gdscript
# 使用示例
SkillManager._resetSkillBox()  # 重置技能箱
```

#### `_addSkill(skillName: String, skillResource: Resource, SkillCount: int)`

添加新技能到技能箱。

**参数：**
- `skillName: String` - 技能名称
- `skillResource: Resource` - 技能资源
- `SkillCount: int` - 技能数量

**返回值：** 无

**功能说明：** 添加新技能到技能箱，如果技能已存在则不添加。

**调用时机：** 需要添加新技能时调用。

**注意事项：** 如果技能已存在于技能箱中，会直接返回不添加。

```gdscript
# 使用示例
var new_skill_resource = load("res://skill/resource/new_skill.tres")
SkillManager._addSkill("newSkill", new_skill_resource, 3)
```

### 资源管理

#### `_skillBoxSet()`

初始化技能箱数据副本。

**参数：** 无

**返回值：** 无

**功能说明：** 创建技能数据和数量的副本，用于游戏中的技能管理。

**调用时机：** 在loadAllSkill()后自动调用。

**注意事项：** 创建副本以避免修改原始数据。

```gdscript
# 内部调用示例
func loadAllSkill():
    # ... 加载技能代码 ...
    _skillBoxSet()  # 初始化技能箱副本
```

### 技能效果应用

技能效果主要通过信号系统触发，具体效果由各个技能脚本实现。

#### 相关信号

| 信号名 | 参数 | 触发时机 | 说明 |
|--------|------|----------|------|
| `playerCdSub` | 无 | 冷却减少时 | 减少技能冷却时间 |
| `playerBaseDamageUp` | 无 | 基础伤害提升时 | 提升基础伤害值 |
| `playerTrueDamageUp` | 无 | 真实伤害提升时 | 提升真实伤害值 |
| `ricochetShootUp` | 无 | 跳弹射击提升时 | 提升跳弹射击能力 |
| `doubleShootUP` | 无 | 双重射击提升时 | 提升双重射击能力 |

### 使用示例

#### 基本技能管理

```gdscript
# 获取商店技能选项
func get_shop_skills():
    var available_skills = SkillManager._getRandomSkill()
    
    # 显示技能选项
    for i in range(available_skills.size()):
        var skill = available_skills[i]
        display_skill_option(i, skill)

# 处理技能购买
func buy_skill(skill_name: String):
    # 检查玩家是否有足够的资源
    if player.coins >= get_skill_cost(skill_name):
        # 扣除资源
        player.coins -= get_skill_cost(skill_name)
        
        # 从技能箱移除技能
        SkillManager._SubSkillBox(skill_name)
        
        # 应用技能效果
        apply_skill_effect(skill_name)
        
        print("成功购买技能: ", skill_name)
    else:
        print("资源不足，无法购买技能")

# 应用技能效果
func apply_skill_effect(skill_name: String):
    match skill_name:
        "doubleShoot":
            Eventmanger.doubleShootUP.emit()
        "cdSub":
            Eventmanger.playerCdSub.emit()
        "baseDamageUp":
            Eventmanger.playerBaseDamageUp.emit()
        "ricochetShoot":
            Eventmanger.ricochetShootUp.emit()
```

#### 技能重置和管理

```gdscript
# 重置技能状态
func reset_skills():
    SkillManager._resetSkillBox()
    print("技能箱已重置")

# 添加自定义技能
func add_custom_skill():
    var custom_skill = load("res://skills/custom_skill.tres")
    SkillManager._addSkill("customSkill", custom_skill, 1)
    print("已添加自定义技能")

# 检查技能可用性
func check_skill_availability(skill_name: String):
    # 这里需要访问内部变量，实际使用时可能需要添加公共方法
    if SkillManager._skillDataCopy.has(skill_name):
        var count = SkillManager._SkillCountCopy.get(skill_name, 0)
        print("技能 ", skill_name, " 可用数量: ", count)
        return count > 0
    else:
        print("技能 ", skill_name, " 不可用")
        return false
```

---

## 主游戏控制器API (Main)

主游戏控制器是Tankou项目的核心游戏逻辑控制器，负责管理游戏流程、资源系统、连击系统、升级系统等核心功能。

### 资源管理方法

#### `_addCorrectCount(iscorrect)`

处理答题结果并更新资源。

**参数：**
- `iscorrect: bool` - 是否回答正确

**返回值：** 无

**功能说明：** 根据答题结果更新正确计数、行动点(AP)、错误计数，并更新错题记录。

**调用时机：** 玩家完成答题时调用。

**注意事项：** 正确计数达到10时会增加AP，错误计数达到2时会减少正确计数。

```gdscript
# 使用示例
# 玩家答对题目
_addCorrectCount(true)

# 玩家答错题目
_addCorrectCount(false)
```

#### `wrongAnswerCount` (属性)

答错题目计数器。

**类型：** int

**功能说明：** 记录玩家答错题目的次数，用于控制正确计数的减少。

**调用时机：** 答错题目时自动增加，达到2次时会减少正确计数并重置。

**注意事项：** 每答错2次题目会减少1次正确计数。

```gdscript
# 使用示例
print("当前答错次数: ", wrongAnswerCount)
```

#### `upDatascore(_node)`

更新游戏分数。

**参数：**
- `_node` - 击败的敌人节点

**返回值：** 无

**功能说明：** 增加游戏分数，更新分数显示。

**调用时机：** 敌人死亡时通过信号触发。

**注意事项：** 每击败一个敌人增加1分。

```gdscript
# 使用示例
# 通常通过信号连接自动调用
Eventmanger.enemydeath.connect(upDatascore)
```

### 连击系统

#### `comboChange(iscorrect)`

处理连击变化。

**参数：**
- `iscorrect: bool` - 是否回答正确

**返回值：** 无

**功能说明：** 根据答题结果更新连击数，触发相应的连击信号和无敌状态。

**调用时机：** 玩家完成答题时调用。

**注意事项：** 连击达到2和5时会触发特殊信号，连击中断时会触发中断信号。

```gdscript
# 使用示例
# 答对题目，增加连击
comboChange(true)

# 答错题目，中断连击
comboChange(false)
```

#### `_on_on_combo_timer_timeout()`

连击计时器超时处理。

**参数：** 无

**返回值：** 无

**功能说明：** 连击计时器超时时触发连击持续信号。

**调用时机：** 连击计时器超时时自动调用。

**注意事项：** 用于维持连击状态的持续效果。

```gdscript
# 内部调用示例
# 连击计时器超时时自动触发
func _on_on_combo_timer_timeout():
    Eventmanger.onComboEmit.emit()
```

### 升级系统

#### `currentExp` (属性)

当前经验值属性，带有setter逻辑。

**参数：**
- `new` - 新的经验值

**返回值：** 无

**功能说明：** 设置当前经验值，当经验值达到升级要求时自动处理升级逻辑。

**调用时机：** 玩家获得经验时调用。

**注意事项：** 升级时会暂停游戏，显示商店界面，并计算下一级所需经验。

```gdscript
# 使用示例
# 增加经验值
currentExp += 1  # 会自动检查是否升级

# 直接设置经验值
currentExp = 50  # 会自动检查是否升级
```

### 游戏流程控制

#### `stopgamefunc()`

暂停游戏。

**参数：** 无

**返回值：** 无

**功能说明：** 暂停游戏进程。

**调用时机：** 升级、游戏结束等需要暂停游戏时调用。

**注意事项：** 使用get_tree().paused = true暂停整个游戏树。

```gdscript
# 使用示例
stopgamefunc()  # 暂停游戏
```

#### `resumegamefunc()`

恢复游戏。

**参数：** 无

**返回值：** 无

**功能说明：** 恢复游戏进程。

**调用时机：** 需要恢复游戏时调用。

**注意事项：** 使用get_tree().paused = false恢复游戏。

```gdscript
# 使用示例
resumegamefunc()  # 恢复游戏
```

#### `enterTreeEnemyfunc()`

敌人进入场景计数。

**参数：** 无

**返回值：** 无

**功能说明：** 增加场景中的敌人计数。

**调用时机：** 敌人进入场景树时通过信号触发。

**注意事项：** 用于跟踪场景中的敌人数量。

```gdscript
# 使用示例
# 通常通过信号连接自动调用
Eventmanger.enterTreeEnemy.connect(enterTreeEnemyfunc)
```

#### `exitTreeEnemyfunc()`

敌人离开场景计数。

**参数：** 无

**返回值：** 无

**功能说明：** 减少场景中的敌人计数，当敌人为0且生成完成时结束关卡。

**调用时机：** 敌人离开场景树时通过信号触发。

**注意事项：** 当所有敌人都被消灭且生成完成时会结束关卡。

```gdscript
# 使用示例
# 通常通过信号连接自动调用
Eventmanger.exitTreeEnemy.connect(exitTreeEnemyfunc)
```

#### `_on_question_skipped()`

处理题目跳过。

**参数：** 无

**返回值：** 无

**功能说明：** 处理玩家跳过题目的逻辑，不获得/损失资源，不影响错题记录。

**调用时机：** 玩家跳过题目时通过信号触发。

**注意事项：** 连击数保持不变。

```gdscript
# 使用示例
# 通常通过信号连接自动调用
Eventmanger.questionSkipped.connect(_on_question_skipped)
```

#### `_on_word_reorder_completed()`

处理单词重组完成。

**参数：** 无

**返回值：** 无

**功能说明：** 单词重组完成时额外奖励1AP。

**调用时机：** 单词重组完成时通过信号触发。

**注意事项：** 会增加正确计数并可能增加AP。

```gdscript
# 使用示例
# 通常通过信号连接自动调用
Eventmanger.wordReorderCompleted.connect(_on_word_reorder_completed)
```

### 使用示例

#### 基本游戏流程控制

```gdscript
# 游戏初始化
func _ready():
    # 连接信号
    Eventmanger.answered.connect(_addCorrectCount)
    Eventmanger.enemydeath.connect(upDatascore)
    Eventmanger.questionSkipped.connect(_on_question_skipped)
    Eventmanger.wordReorderCompleted.connect(_on_word_reorder_completed)
    
    # 开始游戏
    currentExp = 0
    Eventmanger.GameStart.emit()

# 处理答题结果
func handle_answer_result(is_correct: bool):
    # 更新连击
    comboChange(is_correct)
    
    # 更新资源
    _addCorrectCount(is_correct)
    
    # 检查游戏状态
    check_game_status()

# 检查游戏状态
func check_game_status():
    if allInTreeEnemyCount <= 0 and Level.enemysSpanwFinsh.size() == 0:
        stopgamefunc()
        Eventmanger.levelOver.emit()
```

#### 资源管理示例

```gdscript
# 自定义资源管理
func custom_resource_management():
    # 增加经验值
    currentExp += 5
    
    # 检查当前状态
    print("当前等级: ", playerLevel)
    print("当前经验: ", currentExp)
    print("下一级所需经验: ", NextLevelExp)
    print("当前AP: ", power)
    print("当前正确计数: ", Correctcount)
    print("当前连击: ", combo)

# 手动控制游戏流程
func manual_game_control():
    # 暂停游戏
    stopgamefunc()
    
    # 显示商店
    Eventmanger.ShowShoping.emit(false)
    
    # 恢复游戏
    resumegamefunc()
```

#### 连击系统示例

```gdscript
# 自定义连击处理
func custom_combo_handler():
    # 监听连击信号
    Eventmanger.twoComboEmit.connect(_on_two_combo)
    Eventmanger.fiveComboEmit.connect(_on_five_combo)
    Eventmanger.brokenComboEmit.connect(_on_combo_broken)
    Eventmanger.onComboEmit.connect(_on_combo_continue)

func _on_two_combo():
    print("达成2连击！")
    # 应用2连击效果

func _on_five_combo():
    print("达成5连击！")
    # 应用5连击效果

func _on_combo_broken():
    print("连击中断！")
    # 处理连击中断效果

func _on_combo_continue():
    print("连击持续！")
    # 维持连击效果
```

---

## 敌人基类API (baseEnemy)

敌人基类是所有敌人类型的基类，提供敌人的基本行为、状态管理、属性访问和伤害处理等功能。

### 状态管理

#### `_enter_state(new_state: state)`

进入新的状态。

**参数：**
- `new_state: state` - 要进入的新状态

**返回值：** 无

**功能说明：** 切换敌人到指定状态，播放相应动画，设置状态逻辑。

**调用时机：** 需要改变敌人状态时调用。

**注意事项：** 只有当新状态与当前状态不同，或者是重复进入受伤状态时才会执行。

```gdscript
# 使用示例
_enter_state(state.walk)    # 进入行走状态
_enter_state(state.att)      # 进入攻击状态
_enter_state(state.hurt)     # 进入受伤状态
_enter_state(state.death)    # 进入死亡状态
```

#### 状态枚举

敌人支持以下状态：

| 状态 | 说明 |
|------|------|
| `state.idle` | 空闲状态 |
| `state.walk` | 行走状态 |
| `state.att` | 攻击状态 |
| `state.hurt` | 受伤状态 |
| `state.death` | 死亡状态 |
| `state.nothing` | 无状态 |

**状态切换逻辑：**
- 只有当新状态与当前状态不同，或者是重复进入受伤状态时才会执行状态切换
- 受伤状态时不执行物理逻辑
- 攻击状态会在动画完成后自动返回到上一个状态
- 死亡状态会隐藏敌人并从场景中移除

#### 状态逻辑方法

| 方法 | 对应状态 | 说明 |
|------|----------|------|
| `_state_logic_idle()` | `state.idle` | 空闲状态逻辑 |
| `_state_logic_walk()` | `state.walk` | 行走状态逻辑 |
| `_state_logic_att()` | `state.att` | 攻击状态逻辑 |

### 属性访问

#### `initData(Mul: float)`

初始化敌人数据。

**参数：**
- `Mul: float` - 敌人倍数，用于调整难度

**返回值：** 无

**功能说明：** 根据当前关卡和倍数初始化敌人的生命值、速度、伤害等属性。

**调用时机：** 敌人创建后立即调用。

**注意事项：** 倍数大于1时为精英敌人，会增强各项属性。

```gdscript
# 使用示例
# 普通敌人
initData(1.0)

# 精英敌人
initData(1.5)

# Boss敌人
initData(2.0)
```

#### 主要属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `health` | int | 生命值 |
| `speed` | int | 移动速度 |
| `damage` | int | 攻击伤害 |
| `armor` | float | 护甲值 |
| `attCd` | int | 攻击冷却时间 |
| `baseScale` | Vector2 | 基础缩放 |
| `currentFacingDir` | bool | 当前面朝方向 |
| `baseDir` | bool | 初始面朝方向 |
| `player` | Node | 玩家节点引用 |
| `playerbox` | Array | 攻击范围内的玩家列表 |
| `currentState` | state | 当前状态 |

**属性说明：**
- `health`: 根据关卡和倍数计算，基础值为 `int(currentLevel/5.0)*2+5`
- `speed`: 基础速度乘以随机因子(0.8-1.2)，精英敌人速度会根据倍数调整
- `damage`: 基础伤害，精英敌人和Boss会根据倍数增加
- `playerbox`: 存储进入攻击检测范围的玩家节点，用于攻击逻辑
- `currentState`: 敌人当前的状态，影响行为和动画播放

### 伤害处理

#### `getHurt(_damage)`

处理受到伤害。

**参数：**
- `_damage` - 受到的伤害值

**返回值：** 无

**功能说明：** 减少敌人生命值，如果生命值降至0则进入死亡状态，否则进入受伤状态。

**调用时机：** 敌人受到伤害时调用。

**注意事项：** 伤害值会直接从生命值中扣除，不考虑护甲等减伤效果。

```gdscript
# 使用示例
getHurt(10)  # 敌人受到10点伤害
```

#### `att()`

执行攻击动作。

**参数：** 无

**返回值：** 无

**功能说明：** 对攻击范围内的玩家造成伤害。

**调用时机：** 攻击动画中调用，通常通过AnimationPlayer的动画帧调用。

**注意事项：** 只有当玩家在攻击范围内时才会造成伤害。

```gdscript
# 使用示例
# 通常在动画中调用
att()  # 执行攻击
```

#### `die()`

处理敌人死亡。

**参数：** 无

**返回值：** 无

**功能说明：** 隐藏敌人并从场景中移除。

**调用时机：** 死亡动画播放完成后调用。

**注意事项：** 会触发enemydeath信号。

```gdscript
# 使用示例
# 通常在死亡动画结束时调用
die()  # 敌人死亡
```

### 行为控制

#### `_physics_process(_delta: float)`

物理处理逻辑。

**参数：**
- `_delta: float` - 物理帧时间

**返回值：** 无

**功能说明：** 根据当前状态执行相应的物理处理逻辑。

**调用时机：** 每物理帧自动调用。

**注意事项：** 受伤状态时不执行物理逻辑。

```gdscript
# 内部调用示例
# 每物理帧自动调用
func _physics_process(_delta: float):
    match currentState:
        state.idle:
            _state_logic_idle()
        state.walk:
            _state_logic_walk()
        state.att:
            _state_logic_att()
        state.hurt:
            return  # 受伤状态不执行物理逻辑
```

#### `_on_eye_body_entered(body: Node2D)`

检测体进入事件。

**参数：**
- `body: Node2D` - 进入检测体的节点

**返回值：** 无

**功能说明：** 当玩家进入敌人检测范围时，将玩家添加到攻击列表。

**调用时机：** 玩家进入敌人检测范围时自动调用。

**注意事项：** 只有玩家节点才会被添加到攻击列表。

```gdscript
# 内部调用示例
# 玩家进入检测范围时自动调用
func _on_eye_body_entered(body: Node2D):
    if body.is_in_group("player"):
        playerbox.append(body)
```

#### `_on_eye_body_exited(body: Node2D)`

检测体离开事件。

**参数：**
- `body: Node2D` - 离开检测体的节点

**返回值：** 无

**功能说明：** 当玩家离开敌人检测范围时，将玩家从攻击列表中移除。

**调用时机：** 玩家离开敌人检测范围时自动调用。

**注意事项：** 会检查玩家是否在攻击列表中再移除。

```gdscript
# 内部调用示例
# 玩家离开检测范围时自动调用
func _on_eye_body_exited(body: Node2D):
    if body.is_in_group("player"):
        if playerbox.has(body):
            playerbox.erase(body)
```

#### `_on_timer_timeout()`

攻击计时器超时事件。

**参数：** 无

**返回值：** 无

**功能说明：** 当攻击计时器超时时，如果玩家仍在攻击范围内则进入攻击状态。

**调用时机：** 攻击计时器超时时自动调用。

**注意事项：** 只有在空闲状态且玩家在攻击范围内时才会攻击。

```gdscript
# 内部调用示例
# 攻击计时器超时时自动调用
func _on_timer_timeout():
    if currentState == state.idle and (not playerbox.is_empty()):
        _enter_state(state.att)
```

### 使用示例

#### 基本敌人创建和控制

```gdscript
# 创建敌人
func create_enemy(enemy_type: String, position: Vector2, multiplier: float = 1.0):
    var enemy_scene = load("res://enemy/" + enemy_type + ".tscn")
    var enemy = enemy_scene.instantiate()
    
    # 设置位置
    enemy.position = position
    
    # 初始化数据
    enemy.initData(multiplier)
    
    # 添加到场景
    get_tree().get_first_node_in_group("main").add_child(enemy)
    
    return enemy

# 控制敌人状态
func control_enemy_state(enemy: BaseEnemy):
    # 让敌人移动
    enemy._enter_state(state.walk)
    
    # 让敌人攻击
    enemy._enter_state(state.att)
    
    # 让敌人受伤
    enemy.getHurt(5)
    
    # 检查敌人状态
    print("敌人当前状态: ", enemy.currentState)
    print("敌人当前生命: ", enemy.health)
```

#### 自定义敌人行为

```gdscript
# 扩展敌人行为
func custom_enemy_behavior(enemy: BaseEnemy):
    # 自定义移动逻辑
    func custom_walk_logic():
        var direction = enemy.global_position.direction_to(player.global_position)
        enemy.velocity = direction * enemy.speed * 1.5  # 加速移动
        enemy.move_and_slide()
    
    # 自定义攻击逻辑
    func custom_attack_logic():
        # 范围攻击
        for target in enemy.playerbox:
            if target.has_method("getHurt"):
                target.getHurt(enemy.damage * 2)  # 双倍伤害
    
    # 自定义受伤逻辑
    func custom_hurt_logic(damage):
        # 考虑护甲减伤
        var actual_damage = max(1, damage - enemy.armor)
        enemy.getHurt(actual_damage)
```

#### 敌人事件监听

```gdscript
# 监听敌人事件
func setup_enemy_listeners():
    # 监听敌人生成
    Eventmanger.enemySpawn.connect(_on_enemy_spawned)
    
    # 监听敌人死亡
    Eventmanger.enemydeath.connect(_on_enemy_died)

func _on_enemy_spawned(enemy_node):
    print("新敌人生成: ", enemy_node.name)
    # 可以对新敌人进行特殊处理

func _on_enemy_died(enemy_node):
    print("敌人死亡: ", enemy_node.name)
    # 处理敌人死亡后的逻辑
    add_score(10)
    check_level_complete()
```

---

## 关卡管理器API (Level)

关卡管理器负责管理游戏关卡系统，包括关卡生成、难度计算、敌人配置等功能。

### 关卡生成

#### `enterLevel()`

进入新关卡。

**参数：** 无

**返回值：** 无

**功能说明：** 增加关卡计数，生成敌人生成队列，开始生成敌人。

**调用时机：** 游戏开始或进入下一关时调用。

**注意事项：** 会自动调用getSpawnQueue()生成敌人队列。

```gdscript
# 使用示例
# 通常通过信号连接自动调用
Eventmanger.NextLevel.connect(enterLevel)
Eventmanger.GameStart.connect(enterLevel)

# 手动调用
enterLevel()  # 进入下一关
```

#### `getSpawnQueue()`

生成敌人生成队列。

**参数：** 无

**返回值：** `Array` - 敌人生成队列

**功能说明：** 根据当前关卡计算敌人数量和类型，生成包含敌人和倍数的队列。

**调用时机：** 进入新关卡时调用。

**注意事项：** 队列会随机打乱，每5关会出现Boss。

```gdscript
# 使用示例
var spawn_queue = getSpawnQueue()
print("本关敌人数量: ", spawn_queue.size())
for enemy_data in spawn_queue:
    print("敌人类型: ", enemy_data[0], " 倍数: ", enemy_data[1])
```

#### `spawnenemy(_spawnQueue: Array, spawncd: float)`

生成敌人。

**参数：**
- `_spawnQueue: Array` - 敌人生成队列
- `spawncd: float` - 生成间隔时间

**返回值：** 无

**功能说明：** 从队列中取出敌人并生成到场景中，递归调用直到队列为空。

**调用时机：** 进入关卡时调用。

**注意事项：**
- 生成间隔会逐渐减少，每次减少0.05秒，最小为1.0秒
- 使用 `enemysSpanwFinsh` 数组跟踪生成状态
- 每次生成都会检查main场景是否存在
- 使用 `call_deferred` 延迟添加敌人到场景

```gdscript
# 使用示例
# 通常在enterLevel()中自动调用
spawnenemy(spawnQueue, 1.0)  # 开始生成敌人
```

### 难度计算

#### 关卡难度公式

| 项目 | 计算公式 | 说明 |
|------|----------|------|
| 基础敌人数量 | `(currentLevel-1)*3+5` | 每关增加3个基础敌人 |
| 精英敌人数量 | `int(baseEnemyCount/5.0)` | 每5个基础敌人对应1个精英敌人 |
| 敌人类型数量 | `min((currentLevel-1)/5.0+1, enemys.size())` | 每5关增加一种敌人类型 |
| Boss出现 | `currentLevel%5 == 0` | 每5关出现Boss |

#### 敌人属性计算

| 属性 | 普通敌人 | 精英敌人 (Mul > 1) | Boss敌人 (Mul = 2.0) |
|------|----------|-------------------|-------------------|
| 生命值 | `int(currentLevel/5.0)*2+5` | `生命值 * Mul` | `生命值 * 2.0` |
| 移动速度 | `基础速度 * 随机因子(0.8-1.2)` | `速度 * (2.0-Mul)` | `速度 * 0.0` (通常为0) |
| 伤害 | 基础伤害 | `伤害 * Mul` | `伤害 * 2.0` |
| 大小 | 基础大小 | `大小 * Mul` | `大小 * 2.0` |

### 敌人配置

#### `loadAllenemy()`

加载所有敌人资源。

**参数：** 无

**返回值：** 无

**功能说明：** 从配置路径加载所有敌人场景资源，并随机打乱敌人顺序。

**调用时机：** 在_ready()函数中自动调用。

**注意事项：** 使用异步加载，每3个敌人后等待一帧。

```gdscript
# 内部调用示例
func _ready():
    loadAllenemy()  # 自动加载所有敌人资源
```

#### `getrandipos()`

获取随机生成位置。

**参数：** 无

**返回值：** `Vector2` - 随机位置坐标

**功能说明：** 在屏幕左右两侧随机选择一个生成位置。

**调用时机：** 生成敌人时调用。

**注意事项：** Y坐标在屏幕上方75%到顶部之间随机。

```gdscript
# 使用示例
var spawn_pos = getrandipos()
print("敌人生成位置: ", spawn_pos)
```

#### `_restart()`

重置关卡状态。

**参数：** 无

**返回值：** 无

**功能说明：** 重置关卡计数，清理所有已生成的敌人。

**调用时机：** 重新开始游戏时调用。

**注意事项：** 会清理所有内存中的敌人引用。

```gdscript
# 使用示例
# 通常通过信号连接自动调用
Eventmanger.restartGame.connect(_restart)

# 手动调用
_restart()  # 重置关卡
```

### 使用示例

#### 基本关卡管理

```gdscript
# 关卡初始化
func initialize_level_system():
    # 加载敌人资源
    loadAllenemy()
    
    # 连接信号
    Eventmanger.NextLevel.connect(enterLevel)
    Eventmanger.GameStart.connect(enterLevel)
    Eventmanger.restartGame.connect(_restart)
    
    # 开始第一关
    enterLevel()

# 自定义关卡生成
func custom_level_generation(level_number: int):
    currentLevel = level_number
    
    # 生成自定义敌人队列
    var custom_queue = []
    
    # 添加基础敌人
    for i in range(level_number * 2):
        var enemy_type = enemysKeys[randi() % enemysKeys.size()]
        custom_queue.append([enemys[enemy_type], 1.0])
    
    # 添加精英敌人
    for i in range(level_number):
        var enemy_type = enemysKeys[randi() % enemysKeys.size()]
        var multiplier = randf_range(1.2, 1.8)
        custom_queue.append([enemys[enemy_type], multiplier])
    
    # 添加Boss（每5关）
    if level_number % 5 == 0:
        var boss_type = enemysKeys[min(level_number / 5, enemysKeys.size() - 1)]
        custom_queue.append([enemys[boss_type], 2.0])
    
    # 开始生成敌人
    spawnenemy(custom_queue, 1.0)
```

#### 难度调整

```gdscript
# 自定义难度曲线
func custom_difficulty_curve(level: int):
    # 自定义基础敌人数量
    var base_count = level * 2 + 3
    
    # 自定义精英敌人比例
    var elite_ratio = 0.2 + (level * 0.02)
    elite_ratio = min(elite_ratio, 0.5)  # 最多50%
    
    # 自定义Boss强度
    var boss_multiplier = 1.5 + (level * 0.1)
    boss_multiplier = min(boss_multiplier, 3.0)  # 最多3倍
    
    print("关卡 ", level, " 难度配置:")
    print("基础敌人: ", base_count)
    print("精英比例: ", elite_ratio * 100, "%")
    print("Boss倍数: ", boss_multiplier)

# 动态难度调整
func dynamic_difficulty_adjustment():
    # 根据玩家表现调整难度
    var player_performance = calculate_player_performance()
    
    if player_performance > 0.8:  # 玩家表现很好
        # 增加难度
        currentLevel += 1
        print("玩家表现优秀，增加难度")
    elif player_performance < 0.3:  # 玩家表现较差
        # 减少难度
        currentLevel = max(1, currentLevel - 1)
        print("玩家表现较差，降低难度")
```

#### 敌人生成控制

```gdscript
# 精确控制敌人生成
func controlled_enemy_spawn():
    var spawn_queue = []
    
    # 按顺序生成特定敌人
    spawn_queue.append([enemys["zomble"], 1.0])      # 普通僵尸
    spawn_queue.append([enemys["flyDemon"], 1.2])   # 精英飞行恶魔
    spawn_queue.append([enemys["slime"], 1.5])      # 强化史莱姆
    spawn_queue.append([enemys["zomble"], 2.0])      # Boss僵尸
    
    # 自定义生成间隔
    var spawn_intervals = [1.0, 0.8, 0.6, 0.4]
    
    # 按间隔生成敌人
    for i in range(spawn_queue.size()):
        var timer = get_tree().create_timer(spawn_intervals[i])
        timer.timeout.connect(func():
            spawn_single_enemy(spawn_queue[i][0], spawn_queue[i][1])
        )

# 生成单个敌人
func spawn_single_enemy(enemy_scene, multiplier: float):
    var enemy = enemy_scene.instantiate()
    enemy.initData(multiplier)
    enemy.position = getrandipos()
    get_tree().get_first_node_in_group("main").add_child(enemy)
```


## 音频管理器API (AudioManager)

音频管理器负责管理游戏中的音效播放，包括UI音效和空间化音效的播放控制。

### 音频播放控制

#### `play_sfx(sound_name: String)`

播放非空间化音效（如UI音效）。

**参数：**
- `sound_name: String` - 音效名称，必须在`sfx_library`中预定义

**返回值：** 无

**功能说明：** 创建新的AudioStreamPlayer实例并播放指定音效，播放完成后自动销毁。

**调用时机：** 需要播放UI音效、界面点击音效等非空间化音效时调用。

**注意事项：** 音效名称必须在`sfx_library`中预定义，否则无法播放。

```gdscript
# 使用示例
AudioManager.play_sfx("22LRSingleMP3")           # 播放射击音效
AudioManager.play_sfx("Semi22LRReloadFullMP3")    # 播放换弹音效
AudioManager.play_sfx("Semi22LRCantReloadMP3")     # 播放换弹失败音效
```

#### `play_sfx_at_position(sound_name: String, position: Vector2, _DB: float = 1.0)`

播放空间化音效（在指定位置播放）。

**参数：**
- `sound_name: String` - 音效名称，必须在`sfx_library`中预定义
- `position: Vector2` - 音效播放的世界坐标位置
- `_DB: float` - 音量线性值，默认为1.0

**返回值：** 无

**功能说明：** 创建新的AudioStreamPlayer2D实例，在指定世界坐标位置播放音效，播放完成后自动销毁。

**调用时机：** 需要在游戏世界中特定位置播放音效时调用，如敌人死亡、技能释放等。

**注意事项：** 
- 音效名称必须在`sfx_library`中预定义
- 位置使用世界坐标系，不是相对坐标
- 音量值为线性值，范围通常为0.0-1.0

```gdscript
# 使用示例
# 在玩家位置播放射击音效
AudioManager.play_sfx_at_position("22LRSingleMP3", player.global_position)

# 在敌人位置播放死亡音效，音量减半
AudioManager.play_sfx_at_position("762x54rSprayIsolatedMP3", enemy.global_position, 0.5)
```

### 音效资源管理

#### `sfx_library` (属性)

音效库字典，预加载所有音效资源。

**类型：** `Dictionary`

**功能说明：** 存储所有预加载的音效资源，键为音效名称，值为AudioStream资源。

**预定义音效：**
- `"22LRSingleMP3"`: preload('res://sounds/22LRSingleMP3.mp3') - 射击音效
- `"Semi22LRReloadFullMP3"`: preload('res://sounds/Semi22LRReloadFullMP3.mp3') - 完整换弹音效
- `"Semi22LRCantReloadMP3"`: preload('res://sounds/Semi22LRCantReloadMP3.mp3') - 换弹失败音效
- `"762x54rSprayIsolatedMP3"`: preload('uid://bsnnskomqvgqj') - 扫射音效

**调用时机：** 在播放音效时内部自动使用。

**注意事项：** 使用预加载可以显著提高音效播放性能，避免每次播放时重新加载资源。

```gdscript
# 使用示例
# 检查音效是否存在
if AudioManager.sfx_library.has("22LRSingleMP3"):
    print("射击音效已加载")
else:
    print("射击音效未找到")
```

### 使用示例

#### 基本音效播放

```gdscript
# UI音效播放
func play_ui_sounds():
    AudioManager.play_sfx("22LRSingleMP3")  # UI点击音效

# 游戏世界音效播放
func play_game_sounds():
    # 玩家射击
    var player_pos = get_tree().get_first_node_in_group("player").global_position
    AudioManager.play_sfx_at_position("22LRSingleMP3", player_pos)
    
    # 敌人死亡
    for enemy in enemies:
        AudioManager.play_sfx_at_position("762x54rSprayIsolatedMP3", enemy.global_position, 0.8)
```

#### 音效事件处理

```gdscript
# 连接游戏事件到音效播放
func setup_audio_events():
    # 连接射击事件
    Eventmanger.playershooting.connect(_on_player_shooting)
    
    # 连接换弹事件
    Eventmanger.reloadAmmo.connect(_on_reload_start)
    Eventmanger.FinishReloadAmmo.connect(_on_reload_finish)

func _on_player_shooting():
    # 玩家开始射击时的音效
    var player = get_tree().get_first_node_in_group("player")
    AudioManager.play_sfx_at_position("22LRSingleMP3", player.global_position)

func _on_reload_start():
    # 开始换弹音效
    AudioManager.play_sfx("Semi22LRReloadFullMP3")

func _on_reload_finish():
    # 换弹完成音效
    AudioManager.play_sfx("Semi22LRReloadFullMP3")
```

---

## 场景加载管理器API (ChangeSceneLoad)

场景加载管理器负责处理游戏场景的异步加载和切换，提供流畅的场景过渡效果和加载状态管理。

### 场景切换控制

#### `changeScence(path: String)`

切换到指定场景。

**参数：**
- `path: String` - 目标场景文件路径

**返回值：** 无

**功能说明：** 检查场景加载状态，根据状态决定是直接切换还是显示加载动画。

**调用时机：** 需要切换到新场景时调用。

**注意事项：** 
- 如果场景已加载完成，会直接切换
- 如果场景正在加载中，会显示加载进度
- 如果场景加载失败，会输出错误信息
- 如果场景未开始加载，会启动加载动画

```gdscript
# 使用示例
ChangeSceneLoad.changeScence("res://main/main.tscn")        # 切换到主游戏场景
ChangeSceneLoad.changeScence("res://menu/menu.tscn")        # 切换到菜单场景
```

#### `loadPath(path: String)`

预加载指定路径的资源。

**参数：**
- `path: String` - 要预加载的资源路径

**返回值：** 无

**功能说明：** 启动资源的异步加载，将路径添加到预加载列表。

**调用时机：** 提前预加载可能需要的场景资源时调用。

**注意事项：** 使用多线程加载，不会阻塞主线程。

```gdscript
# 使用示例
ChangeSceneLoad.loadPath("res://main/main.tscn")    # 预加载主场景
ChangeSceneLoad.loadPath("res://menu/menu.tscn")    # 预加载菜单场景
```

### 加载状态管理

#### `iSloadInPro` (属性)

加载进行状态标志。

**类型：** `bool`

**功能说明：** 标识当前是否有场景正在加载过程中。

**调用时机：** 在_process()中用于检查加载状态。

**注意事项：** 当为true时，会更新加载进度显示。

```gdscript
# 使用示例
if ChangeSceneLoad.iSloadInPro:
    print("场景正在加载中...")
else:
    print("没有场景在加载")
```

#### `loadingObjPath` (属性)

当前加载对象路径。

**类型：** `String`

**功能说明：** 存储当前正在加载的场景资源路径。

**调用时机：** 在加载过程中用于跟踪当前加载的资源。

**注意事项：** 加载完成后会清空此路径。

```gdscript
# 使用示例
print("当前加载场景: ", ChangeSceneLoad.loadingObjPath)
```

#### `loadPro` (属性)

加载进度数组。

**类型：** `Array`

**功能说明：** 存储资源加载的进度信息，由ResourceLoader返回。

**调用时机：** 在_process()中用于更新加载进度显示。

**注意事项：** 第一个元素为加载进度（0.0-1.0）。

```gdscript
# 使用示例
if not ChangeSceneLoad.loadPro.is_empty():
    var progress = ChangeSceneLoad.loadPro[0]
    print("加载进度: ", progress * 100, "%")
```

#### `scencePath` (属性)

预加载场景路径列表。

**类型：** `Array`

**功能说明：** 存储所有需要预加载的场景路径列表。

**调用时机：** 在loadPath()方法中添加路径，在对象销毁时清理。

**注意事项：** 对象销毁时会尝试完成所有预加载资源的加载。

```gdscript
# 使用示例
print("预加载场景列表: ", ChangeSceneLoad.scencePath)
```

### 过渡效果

#### `_process(_delta: float)`

处理加载进度更新和场景切换。

**参数：**
- `_delta: float` - 帧时间

**返回值：** 无

**功能说明：** 在加载过程中更新进度显示，加载完成时执行场景切换。

**调用时机：** 每帧自动调用。

**注意事项：** 只有在iSloadInPro为true时才处理加载逻辑。

```gdscript
# 内部调用示例
# 每帧自动检查加载状态
func _process(_delta: float):
    if iSloadInPro:
        ResourceLoader.load_threaded_get_status(loadingObjPath, loadPro)
        var mat = color_rect.material as ShaderMaterial
        mat.set_shader_parameter("animation_progress", loadPro[0])
        if loadPro[0] == 1:
            var temp = ResourceLoader.load_threaded_get(loadingObjPath)
            get_tree().change_scene_to_packed(temp)
            loadPro.clear()
            iSloadInPro = false
            loadingObjPath = ""
            var tween = get_tree().create_tween()
            tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
            tween.tween_property(mat, "animation_progress", 0, 0.3)
```

### 使用示例

#### 基本场景切换

```gdscript
# 场景切换函数
func go_to_main_game():
    ChangeSceneLoad.changeScence("res://main/main.tscn")

func go_to_menu():
    ChangeSceneLoad.changeScence("res://menu/menu.tscn")
```

#### 预加载策略

```gdscript
# 场景预加载管理
func preload_scenes():
    # 预加载常用场景
    ChangeSceneLoad.loadPath("res://main/main.tscn")
    ChangeSceneLoad.loadPath("res://menu/menu.tscn")

# 预加载状态检查
func check_preload_status():
    print("预加载场景列表: ", ChangeSceneLoad.scencePath)
```

#### 加载状态监控

```gdscript
# 加载状态监控
func _process(_delta):
    if ChangeSceneLoad.iSloadInPro:
        var progress = 0.0
        if not ChangeSceneLoad.loadPro.is_empty():
            progress = ChangeSceneLoad.loadPro[0]
        
        print("加载中: ", ChangeSceneLoad.loadingObjPath)
        print("进度: ", progress * 100, "%")
```

---

## API使用注意事项

### 通用注意事项

1. **信号连接时机**：所有信号连接应在`_ready()`函数中完成，确保信号能够正确触发。

2. **节点引用检查**：在使用节点引用前，应使用`is_instance_valid()`检查节点是否有效。

3. **资源管理**：注意资源的加载和释放，避免内存泄漏。

4. **状态同步**：确保游戏状态在不同系统间保持同步。

### 性能优化建议

1. **批量操作**：对于需要处理大量数据的操作，应考虑批量处理以减少性能开销。

2. **异步加载**：使用异步加载避免游戏卡顿，特别是在加载大量资源时。

3. **对象池**：对于频繁创建和销毁的对象（如子弹），考虑使用对象池技术。

### 调试技巧

1. **日志输出**：在关键操作处添加日志输出，便于调试和问题定位。

2. **信号监控**：使用信号监控工具跟踪信号的触发和连接情况。

3. **状态检查**：定期检查游戏状态，确保系统正常运行。

### 版本兼容性

本文档基于Tankou项目当前版本编写，API可能会在后续版本中发生变化。使用时请注意：

1. **废弃API**：标注为废弃的API将在未来版本中移除，建议尽快迁移到新API。

2. **实验性API**：实验性API可能会发生变化，不建议在生产环境中使用。

3. **版本更新**：升级项目版本时，请检查API变更日志，确保兼容性。

---

## 更新日志

### v1.1 (2025-11-18)
- 修正事件管理器API文档，添加缺失的方法和修正信号名称
- 重构题库管理系统API文档，移除不存在的方法，添加新的`getNextQuestion()`和`updateWordCount()`方法
- 更新技能管理器API文档，添加技能路径配置和初始数量配置
- 修正主游戏控制器API文档，添加`wrongAnswerCount`属性说明
- 完善敌人基类API文档，添加状态切换逻辑和新增属性说明
- 更新关卡管理器API文档，修正敌人生成逻辑说明
- 所有API文档现在与实际代码实现保持一致

### v1.0 (2025-11-15)
- 初始版本，包含所有核心系统的API文档

---

*本文档最后更新时间：2025-11-18*
*文档版本：v1.1*
*对应游戏版本：当前开发版本*
