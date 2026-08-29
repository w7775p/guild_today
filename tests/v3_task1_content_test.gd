extends Node

const CHARACTER_EXPECTATIONS: Array[Dictionary] = [
	{"path": "res://assets/data/characters/hero_aelius.tres", "id": "hero_aelius", "name": "埃利乌斯", "profession": "骑士", "battle": 7, "investigation": 4, "negotiation": 5},
	{"path": "res://assets/data/characters/hero_rin.tres", "id": "hero_rin", "name": "凛", "profession": "武士", "battle": 7, "investigation": 4, "negotiation": 2},
	{"path": "res://assets/data/characters/hero_dai.tres", "id": "hero_dai", "name": "戴禛", "profession": "牧师", "battle": 3, "investigation": 5, "negotiation": 7},
	{"path": "res://assets/data/characters/hero_patrick.tres", "id": "hero_patrick", "name": "帕特里克", "profession": "税务官", "battle": 3, "investigation": 5, "negotiation": 9},
	{"path": "res://assets/data/characters/hero_astrid.tres", "id": "hero_astrid", "name": "阿斯特里德", "profession": "【占位占位】", "battle": 8, "investigation": 8, "negotiation": 8},
	{"path": "res://assets/data/characters/hero_viletta.tres", "id": "hero_viletta", "name": "维蕾塔", "profession": "猎魔人", "battle": 6, "investigation": 7, "negotiation": 1}
]

const RESULT_IDS: Array[StringName] = [
	&"result_missing_caravan_full_success",
	&"result_missing_caravan_delayed_success",
	&"result_missing_caravan_injured_rescue",
	&"result_missing_caravan_location_confirmed",
	&"result_missing_caravan_search_failed"
]


# Task 1 只验收正式资源加载与稳定引用，不执行结果条件或效果。
func _ready() -> void:
	var passed := _validate_formal_content()
	if passed:
		print("V3 Task 1 content success: characters=6, task=task_missing_caravan, results=5, placeholders=report_text|astrid_profession")
	get_tree().quit(0 if passed else 1)


# 通过正式资源入口逐层读取六名角色、任务、结果组和五个结果。
func _validate_formal_content() -> bool:
	var passed := true
	for expected in CHARACTER_EXPECTATIONS:
		var character: CharacterAsset = load(expected["path"]) as CharacterAsset
		if character == null:
			push_error("正式角色加载失败：%s" % expected["path"])
			passed = false
			continue
		passed = _check(passed, String(character.id) == expected["id"], "角色 ID 错误：%s" % expected["id"])
		passed = _check(passed, character.name == expected["name"], "角色名称错误：%s" % expected["id"])
		passed = _check(passed, character.profession == expected["profession"], "角色职业错误：%s" % expected["id"])
		passed = _check(passed, character.battle == expected["battle"], "角色战斗值错误：%s" % expected["id"])
		passed = _check(passed, character.investigation == expected["investigation"], "角色调查值错误：%s" % expected["id"])
		passed = _check(passed, character.negotiation == expected["negotiation"], "角色交涉值错误：%s" % expected["id"])

	var task: TaskAsset = load("res://assets/data/tasks/task_missing_caravan.tres") as TaskAsset
	if task == null:
		push_error("正式任务加载失败：task_missing_caravan")
		return false
	passed = _check(passed, task.id == &"task_missing_caravan", "正式任务 ID 错误")
	passed = _check(passed, task.title == "失踪商队调查", "正式任务名称错误")
	passed = _check(passed, task.commissioner == "灰鸦商会", "正式任务委托人错误")
	passed = _check(passed, task.promised_reward == 90, "正式任务承诺报酬错误")
	passed = _check(passed, task.duration_days == 2, "正式任务持续时间错误")
	passed = _check(passed, task.min_party_size == 1 and task.max_party_size == 2, "正式任务人数限制错误")
	passed = _check(passed, task.result_group != null, "正式任务缺少结果组引用")

	var result_group: ResultGroupAsset = task.result_group
	if result_group == null:
		return false
	passed = _check(passed, result_group.id == &"result_group_missing_caravan", "正式结果组 ID 错误")
	passed = _check(passed, result_group.results.size() == RESULT_IDS.size(), "正式结果数量错误")
	for index in RESULT_IDS.size():
		if index >= result_group.results.size():
			return false
		var result_asset: ResultAsset = result_group.results[index]
		passed = _check(passed, result_asset != null, "正式结果引用为空：%s" % RESULT_IDS[index])
		if result_asset == null:
			continue
		passed = _check(passed, result_asset.id == RESULT_IDS[index], "正式结果 ID 错误：%s" % RESULT_IDS[index])
		passed = _check(passed, result_asset.report_text == "【占位占位】", "正式结果报告占位缺失：%s" % RESULT_IDS[index])

	return passed


# 统一记录失败并保留成功路径的清晰输出。
func _check(current: bool, condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return current and condition
