extends Node


const FORMAL_TASK_PATH := "res://assets/data/tasks/task_missing_caravan.tres"
const TEST_CHARACTER_PATH := "res://tests/fixtures/test_injured_rescue_character.tres"


func _ready() -> void:
	# 只用普通 CharacterAsset fixture 验证正式“带伤救回”结果条件可被命中。
	var passed := _run_injured_rescue_case()
	if passed:
		print("V3 Task 7 injured rescue fixture success: result=injured_rescue, special_fields=false")
	else:
		push_error("V3 Task 7 injured rescue fixture failed")
	get_tree().quit(0 if passed else 1)


func _run_injured_rescue_case() -> bool:
	var task_asset := load(FORMAL_TASK_PATH) as TaskAsset
	var character := load(TEST_CHARACTER_PATH) as CharacterAsset
	var passed := _check(true, task_asset != null and task_asset.result_group != null, "正式任务或结果组加载失败")
	passed = _check(passed, character != null, "测试角色加载失败")
	if not passed:
		return false
	passed = _check(passed, character.id == &"test_injured_rescue_character", "测试角色 ID 错误")
	passed = _check(passed, character.battle == 5 and character.investigation == 5, "测试角色能力值未达到带伤救回边界")
	var resolution_system := TaskResolutionSystem.new()
	add_child(resolution_system)
	var dispatch_instance := DispatchInstance.new()
	dispatch_instance.status = &"ACTIVE"
	dispatch_instance.character_refs.assign([character])
	var result_id := resolution_system.resolve_result(dispatch_instance, task_asset.result_group)
	passed = _check(passed, result_id == &"result_missing_caravan_injured_rescue", "测试角色未命中带伤救回：%s" % result_id)
	resolution_system.queue_free()
	return passed


func _check(current: bool, condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return current and condition
