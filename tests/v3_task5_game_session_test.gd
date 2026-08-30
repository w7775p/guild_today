extends Node


const GAME_SESSION_SCENE := preload("res://runtime/game_session.tscn")
const FULL_SUCCESS_RELATIONSHIP_ID: StringName = &"【relationship_merchant_evaluation】"
const SEARCH_FAILED_RELATIONSHIP_ID: StringName = &"【relationship_merchant_trust】"
const LOCATION_INTEL_ID: StringName = &"【intel_missing_caravan_location】"
const LOCATION_UNLOCK_TASK_ID: StringName = &"【task_missing_caravan_followup_rescue】"

const TERMINAL_STATE_IDS: Dictionary = {
	&"result_missing_caravan_full_success": &"【task_outcome_full_success】",
	&"result_missing_caravan_location_confirmed": &"【task_outcome_location_confirmed】",
	&"result_missing_caravan_search_failed": &"【task_outcome_search_failed】",
}


func _ready() -> void:
	# 三个独立正式会话覆盖成功、查明位置和失败路线，正常日志不触发 ERROR。
	var passed := true
	passed = _run_route(&"full_success", [&"hero_viletta"], &"result_missing_caravan_full_success", passed)
	passed = _run_route(&"location_confirmed", [&"hero_dai"], &"result_missing_caravan_location_confirmed", passed)
	passed = _run_route(&"search_failed", [&"hero_aelius"], &"result_missing_caravan_search_failed", passed)
	if passed:
		print("V3 Task 5 GameSession success: routes=3, formal_assets=true, reports=3, errors=0")
	else:
		push_error("V3 Task 5 GameSession failed")
	get_tree().quit(0 if passed else 1)


func _run_route(route_id: StringName, party_ids: Array[StringName], expected_result_id: StringName, passed: bool) -> bool:
	var session := GAME_SESSION_SCENE.instantiate() as GameSession
	if session == null:
		return _check(passed, false, "%s 无法实例化 GameSession" % route_id)
	var task_notifications: Array[StringName] = []
	var day_notifications: Array[int] = []
	var dispatch_notifications: Array[StringName] = []
	var state_notifications: Array[bool] = []
	var report_notifications: Array[StringName] = []
	session.task_changed.connect(func(task_id: StringName) -> void: task_notifications.append(task_id))
	session.day_changed.connect(func(day: int) -> void: day_notifications.append(day))
	session.dispatch_changed.connect(func(dispatch_id: StringName) -> void: dispatch_notifications.append(dispatch_id))
	session.state_changed.connect(func() -> void: state_notifications.append(true))
	session.report_changed.connect(func(report_id: StringName) -> void: report_notifications.append(report_id))
	add_child(session)

	passed = _check(passed, session.is_initialized(), "%s 正式会话初始化失败" % route_id)
	passed = _check(passed, session.get_formal_characters().size() == 6, "%s 应加载六名正式角色" % route_id)
	var published_tasks := session.get_published_tasks()
	passed = _check(passed, published_tasks.size() == 1, "%s 应发布首张正式任务" % route_id)
	if published_tasks.size() != 1:
		session.queue_free()
		return false
	var task_instance := published_tasks[0]
	var dispatch_instance := session.submit_dispatch(task_instance.instance_id, party_ids)
	passed = _check(passed, dispatch_instance != null, "%s 正式派遣失败" % route_id)
	if dispatch_instance == null:
		session.queue_free()
		return false
	passed = _check(passed, session.get_active_dispatches().size() == 1, "%s 派遣后应存在一个 ACTIVE 派遣" % route_id)
	for character_id in party_ids:
		passed = _check(passed, session.is_character_occupied(character_id), "%s 派遣角色应保持占用" % route_id)

	passed = _check(passed, session.advance_day() == 2, "%s 第一次推进后应为第 2 日" % route_id)
	passed = _check(passed, session.get_unread_reports().is_empty(), "%s 第 2 日不应提前出现报告" % route_id)
	passed = _check(passed, session.get_active_dispatches().size() == 1, "%s 第 2 日派遣仍应 ACTIVE" % route_id)
	passed = _check(passed, session.advance_day() == 3, "%s 第二次推进后应为第 3 日" % route_id)

	var settled_task := session.get_task_instance(task_instance.instance_id)
	var report := session.get_report_for_dispatch(dispatch_instance.dispatch_instance_id)
	passed = _check(passed, settled_task.final_result_id == expected_result_id, "%s 最终结果错误：%s" % [route_id, settled_task.final_result_id])
	passed = _check(passed, settled_task.lifecycle_state == TERMINAL_STATE_IDS[expected_result_id], "%s 任务终态错误" % route_id)
	passed = _check(passed, report != null and report.result_asset_id == expected_result_id, "%s 报告结果错误" % route_id)
	passed = _check(passed, session.get_unread_reports().size() == 1, "%s 应生成一份未读报告" % route_id)
	passed = _check(passed, session.get_active_dispatches().is_empty(), "%s 结算后不应保留 ACTIVE 派遣" % route_id)
	passed = _check(passed, dispatch_instance.status == &"ENDED" and dispatch_instance.ended_day == 3, "%s 派遣结束事实错误" % route_id)
	for character_id in party_ids:
		passed = _check(passed, not session.is_character_occupied(character_id), "%s 结算后应释放角色" % route_id)

	if expected_result_id == &"result_missing_caravan_full_success":
		passed = _check(passed, session.get_guild_value(GuildState.GOLD_STATE_ID) == 90, "完整成功应结算 90 金币")
		passed = _check(passed, session.get_relationship_value(FULL_SUCCESS_RELATIONSHIP_ID) == 5, "完整成功关系变化应为 +5")
	elif expected_result_id == &"result_missing_caravan_location_confirmed":
		passed = _check(passed, session.get_unlocked_task_id(LOCATION_INTEL_ID) == LOCATION_UNLOCK_TASK_ID, "查明位置应保存情报解锁")
	elif expected_result_id == &"result_missing_caravan_search_failed":
		passed = _check(passed, session.get_relationship_value(SEARCH_FAILED_RELATIONSHIP_ID) == -5, "搜索失败关系变化应为 -5")

	passed = _check(passed, task_notifications.size() == 3, "%s 任务变化通知数量错误" % route_id)
	passed = _check(passed, day_notifications == [2, 3], "%s 日期通知顺序错误" % route_id)
	passed = _check(passed, dispatch_notifications.size() == 2, "%s 派遣变化通知数量错误" % route_id)
	passed = _check(passed, state_notifications.size() == 1, "%s 状态变化通知数量错误" % route_id)
	passed = _check(passed, report_notifications.size() == 1, "%s 报告变化通知数量错误" % route_id)
	if report != null:
		passed = _check(passed, session.mark_report_read(report.report_id), "%s 报告标记已读失败" % route_id)
		passed = _check(passed, session.get_unread_reports().is_empty(), "%s 已读报告仍出现在未读列表" % route_id)
	session.queue_free()
	return passed


func _check(current: bool, condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return current and condition
