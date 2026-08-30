extends Node


const GAME_SESSION_SCENE := preload("res://runtime/game_session.tscn")
const COLLAPSED_MINE_TASK_PATH := "res://assets/data/tasks/task_collapsed_mine_rescue.tres"
const COLLAPSED_MINE_TASK_ID: StringName = &"task_collapsed_mine_rescue"
const COLLAPSED_MINE_GROUP_ID: StringName = &"result_group_collapsed_mine_rescue"

const TERMINAL_STATE_IDS: Dictionary = {
	&"result_collapsed_mine_ventilation_rescue": &"【task_outcome_collapsed_mine_ventilation_rescue】",
	&"result_collapsed_mine_side_shaft_rescue": &"【task_outcome_collapsed_mine_side_shaft_rescue】",
	&"result_collapsed_mine_forced_entry": &"【task_outcome_collapsed_mine_forced_entry】",
	&"result_collapsed_mine_safe_nest_clearance": &"【task_outcome_collapsed_mine_safe_nest_clearance】",
	&"result_collapsed_mine_side_shaft_mapping": &"【task_outcome_collapsed_mine_side_shaft_mapping】",
	&"result_collapsed_mine_coordinated_entry": &"【task_outcome_collapsed_mine_coordinated_entry】",
	&"result_collapsed_mine_failure": &"【task_outcome_collapsed_mine_failure】",
	&"result_collapsed_mine_total_rescue": &"【task_outcome_collapsed_mine_total_rescue】",
}


func _ready() -> void:
	# 八个能力分区全部通过正式 GameSession，验证第二张任务没有另建判定链。
	var passed := _validate_asset_shape()
	passed = _run_formal_routes(passed)
	if passed:
		print("V3 Task 8 collapsed mine success: results=8, formal_routes=8, unique_results=true, game_session=true")
	else:
		push_error("V3 Task 8 collapsed mine failed")
	get_tree().quit(0 if passed else 1)


func _validate_asset_shape() -> bool:
	var task_asset := load(COLLAPSED_MINE_TASK_PATH) as TaskAsset
	var passed := _check(true, task_asset != null, "塌方矿井任务资产加载失败")
	if task_asset == null:
		return false
	passed = _check(passed, task_asset.id == COLLAPSED_MINE_TASK_ID, "塌方矿井任务 ID 错误")
	passed = _check(passed, task_asset.result_group != null, "塌方矿井缺少结果组引用")
	if task_asset.result_group == null:
		return false
	passed = _check(passed, task_asset.result_group.id == COLLAPSED_MINE_GROUP_ID, "塌方矿井结果组 ID 错误")
	passed = _check(passed, task_asset.result_group.results.size() == TERMINAL_STATE_IDS.size(), "塌方矿井结果数量应为 8")
	var seen_ids: Dictionary[StringName, bool] = {}
	for result_asset in task_asset.result_group.results:
		passed = _check(passed, result_asset != null, "塌方矿井结果引用为空")
		if result_asset == null:
			continue
		passed = _check(passed, not seen_ids.has(result_asset.id), "塌方矿井结果 ID 重复：%s" % result_asset.id)
		seen_ids[result_asset.id] = true
		passed = _check(passed, TERMINAL_STATE_IDS.has(result_asset.id), "塌方矿井存在未登记结果：%s" % result_asset.id)
		passed = _check(passed, result_asset.conditions.size() == 3, "塌方矿井结果应使用三项能力条件：%s" % result_asset.id)
		passed = _check(passed, result_asset.effects.size() == 1, "塌方矿井结果应使用一个任务终态效果：%s" % result_asset.id)
		passed = _check(passed, not result_asset.report_text.is_empty(), "塌方矿井报告占位不能为空：%s" % result_asset.id)
	return passed


func _run_formal_routes(passed: bool) -> bool:
	var cases: Array[Dictionary] = [
		{"label": "只满足调查", "party": [&"hero_viletta"], "expected": &"result_collapsed_mine_ventilation_rescue"},
		{"label": "只满足交涉", "party": [&"hero_patrick"], "expected": &"result_collapsed_mine_side_shaft_rescue"},
		{"label": "只满足战斗", "party": [&"hero_rin"], "expected": &"result_collapsed_mine_forced_entry"},
		{"label": "调查加战斗", "party": [&"hero_viletta", &"hero_rin"], "expected": &"result_collapsed_mine_safe_nest_clearance"},
		{"label": "调查加交涉", "party": [&"hero_viletta", &"hero_patrick"], "expected": &"result_collapsed_mine_side_shaft_mapping"},
		{"label": "交涉加战斗", "party": [&"hero_aelius", &"hero_patrick"], "expected": &"result_collapsed_mine_coordinated_entry"},
		{"label": "三项均不足", "party": [&"hero_dai"], "expected": &"result_collapsed_mine_failure"},
		{"label": "三项全部满足", "party": [&"hero_astrid"], "expected": &"result_collapsed_mine_total_rescue"},
	]
	for case_data in cases:
		var party_ids: Array[StringName] = []
		for character_id in case_data["party"]:
			party_ids.append(character_id)
		passed = _run_formal_route(case_data["label"], party_ids, case_data["expected"], passed)
	return passed


func _run_formal_route(route_label: String, party_ids: Array[StringName], expected_result_id: StringName, passed: bool) -> bool:
	var session := GAME_SESSION_SCENE.instantiate() as GameSession
	if session == null:
		return _check(passed, false, "%s 无法实例化 GameSession" % route_label)
	# 通过场景配置切换正式任务，系统节点和结算编排与首张任务完全复用。
	session.task_asset_path = COLLAPSED_MINE_TASK_PATH
	add_child(session)

	passed = _check(passed, session.is_initialized(), "%s 正式会话初始化失败" % route_label)
	passed = _check(passed, session.get_formal_characters().size() == 6, "%s 应加载六名正式角色" % route_label)
	var published_tasks := session.get_published_tasks()
	passed = _check(passed, published_tasks.size() == 1, "%s 应发布一张塌方矿井任务" % route_label)
	if published_tasks.size() != 1:
		session.queue_free()
		return false
	var task_instance := published_tasks[0]
	var task_asset := session.get_task_asset(task_instance.instance_id)
	passed = _check(passed, task_asset != null and task_asset.id == COLLAPSED_MINE_TASK_ID, "%s 正式任务读取错误" % route_label)
	var dispatch_instance := session.submit_dispatch(task_instance.instance_id, party_ids)
	passed = _check(passed, dispatch_instance != null, "%s 正式派遣失败" % route_label)
	if dispatch_instance == null:
		session.queue_free()
		return false
	passed = _check(passed, dispatch_instance.started_day == 1 and dispatch_instance.due_day == 3, "%s 派遣日期事实错误" % route_label)
	passed = _check(passed, session.get_active_dispatches().size() == 1, "%s 派遣后应存在一个 ACTIVE 派遣" % route_label)

	passed = _check(passed, session.advance_day() == 2, "%s 第一次推进后应为第 2 日" % route_label)
	passed = _check(passed, session.get_unread_reports().is_empty(), "%s 第 2 日不应提前出现报告" % route_label)
	passed = _check(passed, session.advance_day() == 3, "%s 第二次推进后应为第 3 日" % route_label)
	var settled_task := session.get_task_instance(task_instance.instance_id)
	var report := session.get_report_for_dispatch(dispatch_instance.dispatch_instance_id)
	passed = _check(passed, settled_task != null and settled_task.final_result_id == expected_result_id, "%s 最终结果错误：%s" % [route_label, settled_task.final_result_id if settled_task != null else &""])
	passed = _check(passed, settled_task != null and settled_task.lifecycle_state == TERMINAL_STATE_IDS[expected_result_id], "%s 任务终态错误" % route_label)
	passed = _check(passed, report != null and report.result_asset_id == expected_result_id, "%s 报告结果错误" % route_label)
	passed = _check(passed, report != null and not report.text.is_empty(), "%s 报告内容不能为空" % route_label)
	passed = _check(passed, session.get_active_dispatches().is_empty(), "%s 结算后不应保留 ACTIVE 派遣" % route_label)
	passed = _check(passed, dispatch_instance.status == &"ENDED" and dispatch_instance.ended_day == 3, "%s 派遣结束事实错误" % route_label)
	for character_id in party_ids:
		passed = _check(passed, not session.is_character_occupied(character_id), "%s 结算后应释放角色" % route_label)
	if report != null:
		passed = _check(passed, session.mark_report_read(report.report_id), "%s 报告标记已读失败" % route_label)
		passed = _check(passed, session.get_unread_reports().is_empty(), "%s 报告已读后仍在未读列表" % route_label)
	session.queue_free()
	return passed


func _check(current: bool, condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return current and condition
