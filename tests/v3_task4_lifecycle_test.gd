extends Node


const FORMAL_TASK_PATH := "res://assets/data/tasks/task_missing_caravan.tres"
const FORMAL_CHARACTER_PATH := "res://assets/data/characters/hero_viletta.tres"


func _ready() -> void:
	# 专项测试覆盖日期推进、两日派遣到期、角色占用和显式结束。
	var passed := _run_lifecycle_case()
	if passed:
		print("V3 Task 4 lifecycle success: day=1->3, due_day=3, occupancy_released=true")
	else:
		push_error("V3 Task 4 lifecycle failed")
	get_tree().quit(0 if passed else 1)


func _run_lifecycle_case() -> bool:
	var day_system := DaySystem.new()
	var task_system := TaskSystem.new()
	var dispatch_system := DispatchSystem.new()
	var settlement_system := ResultSettlementSystem.new()
	var guild_state := GuildState.new()
	add_child(day_system)
	add_child(task_system)
	add_child(dispatch_system)
	add_child(settlement_system)
	add_child(guild_state)
	var day_notifications: Array[int] = []
	day_system.day_advanced.connect(func(day: int) -> void: day_notifications.append(day))

	var task_asset := load(FORMAL_TASK_PATH) as TaskAsset
	var character := load(FORMAL_CHARACTER_PATH) as CharacterAsset
	var passed := _check(true, task_asset != null and character != null, "正式 Task 4 资产加载失败")
	if not passed:
		return _cleanup_and_return([day_system, task_system, dispatch_system, settlement_system, guild_state], false)
	passed = _check(passed, day_system.get_current_day() == 1, "日期系统初始日应为第 1 日")
	var task_instance := task_system.create_task_instance(task_asset)
	passed = _check(passed, task_instance != null, "Task 4 创建任务实例失败")
	passed = _check(passed, task_system.start_task_instance(task_instance.instance_id), "Task 4 启动任务失败")
	passed = _check(passed, task_instance.lifecycle_state == &"IN_PROGRESS", "任务未进入进行中状态")
	var dispatch_instance := dispatch_system.create_dispatch(task_instance.instance_id, [character], day_system.get_current_day(), task_asset.duration_days)
	passed = _check(passed, dispatch_instance != null, "Task 4 创建定时派遣失败")
	if dispatch_instance == null:
		return _cleanup_and_return([day_system, task_system, dispatch_system, settlement_system, guild_state], false)
	passed = _check(passed, dispatch_instance.started_day == 1, "派遣开始日应为第 1 日")
	passed = _check(passed, dispatch_instance.due_day == 3, "两日派遣到期日应为第 3 日")
	passed = _check(passed, dispatch_instance.ended_day == -1, "未结束派遣不应有结束日")
	passed = _check(passed, dispatch_system.is_character_occupied(character.id), "第 1 日角色应保持占用")
	passed = _check(passed, not dispatch_system.is_dispatch_due(dispatch_instance.dispatch_instance_id, 1), "第 1 日不应到期")

	day_system.advance_day()
	passed = _check(passed, day_system.get_current_day() == 2, "第一次推进后应为第 2 日")
	passed = _check(passed, dispatch_system.is_character_occupied(character.id), "第 2 日角色应保持占用")
	passed = _check(passed, not dispatch_system.is_dispatch_due(dispatch_instance.dispatch_instance_id, day_system.get_current_day()), "第 2 日不应到期")
	passed = _check(passed, task_instance.lifecycle_state == &"IN_PROGRESS", "日期推进不应直接修改任务生命周期")
	var pending_result := ResultInstance.new()
	pending_result.result_asset_id = &"test_pending_result"
	pending_result.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	var pending_asset := ResultAsset.new()
	pending_asset.id = pending_result.result_asset_id
	var early_settlement := settlement_system.settle_result(pending_result, guild_state, null, null, null, null, null, dispatch_instance, day_system.get_current_day(), pending_asset)
	passed = _check(passed, not early_settlement, "到期前不应允许结算")

	day_system.advance_day()
	passed = _check(passed, day_system.get_current_day() == 3, "第二次推进后应为第 3 日")
	passed = _check(passed, day_notifications == [2, 3], "日期变化通知次数或顺序错误")
	passed = _check(passed, dispatch_system.is_dispatch_due(dispatch_instance.dispatch_instance_id, day_system.get_current_day()), "第 3 日应可查询到期")
	var due_dispatches := dispatch_system.get_due_dispatches(day_system.get_current_day())
	passed = _check(passed, due_dispatches.size() == 1 and due_dispatches[0] == dispatch_instance, "到期派遣查询结果错误")
	passed = _check(passed, dispatch_instance.status == &"ACTIVE", "到期不应自动结束派遣")
	passed = _check(passed, task_instance.final_result_id.is_empty(), "日期推进不应直接写入结果")

	passed = _check(passed, dispatch_system.end_dispatch(dispatch_instance.dispatch_instance_id, day_system.get_current_day()), "显式结束派遣失败")
	passed = _check(passed, dispatch_instance.status == &"ENDED", "派遣结束状态错误")
	passed = _check(passed, dispatch_instance.ended_day == 3, "派遣结束日应记录为第 3 日")
	passed = _check(passed, not dispatch_system.is_character_occupied(character.id), "结束派遣后角色应释放")
	passed = _check(passed, not dispatch_system.is_dispatch_due(dispatch_instance.dispatch_instance_id, day_system.get_current_day()), "结束派遣不应继续列为到期")
	passed = _check(passed, dispatch_system.get_due_dispatches(day_system.get_current_day()).is_empty(), "结束后的派遣不应出现在到期列表")
	_cleanup_and_return([day_system, task_system, dispatch_system, settlement_system, guild_state], passed)
	return passed


func _cleanup_and_return(nodes: Array, result: bool) -> bool:
	for node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	return result


func _check(current: bool, condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return current and condition
