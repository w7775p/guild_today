extends Node


const GAME_SESSION_SCENE := preload("res://runtime/game_session.tscn")
const FORMAL_TASK_PATH := "res://assets/data/tasks/task_missing_caravan.tres"
const FULL_SUCCESS_RELATIONSHIP_ID: StringName = &"【relationship_merchant_evaluation】"
const SEARCH_FAILED_RELATIONSHIP_ID: StringName = &"【relationship_merchant_trust】"
const LOCATION_INTEL_ID: StringName = &"【intel_missing_caravan_location】"
const LOCATION_UNLOCK_TASK_ID: StringName = &"【task_missing_caravan_followup_rescue】"
const INJURED_RESULT_ID: StringName = &"result_missing_caravan_injured_rescue"

const TERMINAL_STATE_IDS: Dictionary = {
	&"result_missing_caravan_full_success": &"【task_outcome_full_success】",
	&"result_missing_caravan_delayed_success": &"【task_outcome_delayed_success】",
	&"result_missing_caravan_injured_rescue": &"【task_outcome_injured_rescue】",
	&"result_missing_caravan_location_confirmed": &"【task_outcome_location_confirmed】",
	&"result_missing_caravan_search_failed": &"【task_outcome_search_failed】",
}


func _ready() -> void:
	# 正式四条路线走 GameSession；带伤救回只在专项测试临时创建普通角色。
	var passed := _run_formal_routes()
	passed = _run_temporary_injured_route(passed)
	if passed:
		print("V3 Task 7 acceptance success: formal_routes=4, temporary_numeric_fallback=true, lifecycle=true, persistent_effects=true")
	else:
		push_error("V3 Task 7 acceptance failed")
	get_tree().quit(0 if passed else 1)


func _run_formal_routes() -> bool:
	var cases: Array[Dictionary] = [
		{"label": "完整成功", "party": [&"hero_viletta"], "expected": &"result_missing_caravan_full_success"},
		{"label": "延迟成功", "party": [&"hero_dai", &"hero_aelius"], "expected": &"result_missing_caravan_delayed_success"},
		{"label": "查明位置", "party": [&"hero_dai"], "expected": &"result_missing_caravan_location_confirmed"},
		{"label": "搜索失败", "party": [&"hero_aelius"], "expected": &"result_missing_caravan_search_failed"},
	]
	var passed := true
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

	passed = _check(passed, session.is_initialized(), "%s 正式会话初始化失败" % route_label)
	passed = _check(passed, session.get_formal_characters().size() == 6, "%s 应加载六名正式角色" % route_label)
	var published_tasks := session.get_published_tasks()
	passed = _check(passed, published_tasks.size() == 1, "%s 应发布首张正式任务" % route_label)
	if published_tasks.size() != 1:
		session.queue_free()
		return false
	var task_instance := published_tasks[0]
	var dispatch_instance := session.submit_dispatch(task_instance.instance_id, party_ids)
	passed = _check(passed, dispatch_instance != null, "%s 正式派遣失败" % route_label)
	if dispatch_instance == null:
		session.queue_free()
		return false
	passed = _check(passed, session.get_active_dispatches().size() == 1, "%s 派遣后应存在一个 ACTIVE 派遣" % route_label)
	for character_id in party_ids:
		passed = _check(passed, session.is_character_occupied(character_id), "%s 派遣角色应保持占用" % route_label)

	var occupied_party: Array[CharacterAsset] = []
	for character_id in party_ids:
		var character := _find_formal_character(session.get_formal_characters(), character_id)
		if character != null:
			occupied_party.append(character)
	var duplicate_dispatch := session.dispatch_system.create_dispatch(
		task_instance.instance_id,
		occupied_party,
		session.get_current_day(),
		2
	)
	passed = _check(passed, duplicate_dispatch == null, "%s 重复占用角色的派遣应被拒绝" % route_label)

	passed = _check(passed, session.advance_day() == 2, "%s 第一次推进后应为第 2 日" % route_label)
	passed = _check(passed, session.get_unread_reports().is_empty(), "%s 第 2 日不应提前出现报告" % route_label)
	passed = _check(passed, session.get_active_dispatches().size() == 1, "%s 第 2 日派遣仍应 ACTIVE" % route_label)

	var task_asset := session.get_task_asset(task_instance.instance_id)
	var expected_result_asset := _find_result(task_asset.result_group, expected_result_id) if task_asset != null else null
	var early_result := ResultInstance.new()
	early_result.result_asset_id = expected_result_id
	early_result.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	if expected_result_asset != null:
		early_result.resolved_effects.assign(expected_result_asset.effects)
	var early_settlement := session.settlement_system.settle_result(
		early_result,
		session.guild_state,
		session.relationship_system,
		session.character_state_system,
		session.report_system,
		session.task_system,
		task_instance,
		dispatch_instance,
		session.get_current_day(),
		expected_result_asset
	)
	passed = _check(passed, not early_settlement, "%s 到期前结算应被拒绝" % route_label)

	passed = _check(passed, session.advance_day() == 3, "%s 第二次推进后应为第 3 日" % route_label)
	var settled_task := session.get_task_instance(task_instance.instance_id)
	var report := session.get_report_for_dispatch(dispatch_instance.dispatch_instance_id)
	passed = _check(passed, settled_task.final_result_id == expected_result_id, "%s 最终结果错误：%s" % [route_label, settled_task.final_result_id])
	passed = _check(passed, settled_task.lifecycle_state == TERMINAL_STATE_IDS[expected_result_id], "%s 任务终态错误" % route_label)
	passed = _check(passed, report != null and report.result_asset_id == expected_result_id, "%s 报告结果错误" % route_label)
	passed = _check(passed, report != null and not report.text.is_empty(), "%s 报告文本不应为空" % route_label)
	passed = _check(passed, session.get_unread_reports().size() == 1, "%s 应生成一份未读报告" % route_label)
	passed = _check(passed, session.get_active_dispatches().is_empty(), "%s 结算后不应保留 ACTIVE 派遣" % route_label)
	passed = _check(passed, dispatch_instance.status == &"ENDED" and dispatch_instance.ended_day == 3, "%s 派遣结束事实错误" % route_label)
	for character_id in party_ids:
		passed = _check(passed, not session.is_character_occupied(character_id), "%s 结算后应释放角色" % route_label)

	var duplicate_settlement := ResultInstance.new()
	duplicate_settlement.result_asset_id = expected_result_id
	duplicate_settlement.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	if expected_result_asset != null:
		duplicate_settlement.resolved_effects.assign(expected_result_asset.effects)
	passed = _check(passed, not session.settlement_system.settle_result(
		duplicate_settlement,
		session.guild_state,
		session.relationship_system,
		session.character_state_system,
		session.report_system,
		session.task_system,
		task_instance,
		dispatch_instance,
		session.get_current_day(),
		expected_result_asset
	), "%s 重复结算应被拒绝" % route_label)

	if expected_result_id == &"result_missing_caravan_full_success":
		passed = _check(passed, session.get_guild_value(GuildState.GOLD_STATE_ID) == 90, "完整成功应结算 90 金币")
		passed = _check(passed, session.get_relationship_value(FULL_SUCCESS_RELATIONSHIP_ID) == 5, "完整成功关系变化应为 +5")
	elif expected_result_id == &"result_missing_caravan_delayed_success":
		passed = _check(passed, session.get_guild_value(GuildState.GOLD_STATE_ID) == 60, "延迟成功应结算 60 金币")
		passed = _check(passed, session.get_character_injury_level(&"hero_aelius") == 1, "延迟成功应使最高战斗角色受伤")
	elif expected_result_id == &"result_missing_caravan_location_confirmed":
		passed = _check(passed, session.get_unlocked_task_id(LOCATION_INTEL_ID) == LOCATION_UNLOCK_TASK_ID, "查明位置应保存情报解锁")
	elif expected_result_id == &"result_missing_caravan_search_failed":
		passed = _check(passed, session.get_relationship_value(SEARCH_FAILED_RELATIONSHIP_ID) == -5, "搜索失败关系变化应为 -5")

	passed = _check(passed, task_notifications.size() == 3, "%s 任务变化通知数量错误" % route_label)
	passed = _check(passed, day_notifications == [2, 3], "%s 日期通知顺序错误" % route_label)
	passed = _check(passed, dispatch_notifications.size() == 2, "%s 派遣变化通知数量错误" % route_label)
	passed = _check(passed, state_notifications.size() == 1, "%s 状态变化通知数量错误" % route_label)
	passed = _check(passed, report_notifications.size() == 1, "%s 报告变化通知数量错误" % route_label)
	if report != null:
		passed = _check(passed, session.mark_report_read(report.report_id), "%s 报告标记已读失败" % route_label)
		passed = _check(passed, session.get_unread_reports().is_empty(), "%s 已读报告仍出现在未读列表" % route_label)
	session.queue_free()
	return passed


func _run_temporary_injured_route(passed: bool) -> bool:
	# 该角色只为正式数值缺口提供覆盖，不保存为资源，也不加入 GameSession 正式角色池。
	var task_asset := load(FORMAL_TASK_PATH) as TaskAsset
	var temporary_character := CharacterAsset.new()
	temporary_character.id = &"test_task7_injured_rescue"
	temporary_character.name = "测试救援角色"
	temporary_character.battle = 5
	temporary_character.investigation = 5
	temporary_character.negotiation = 0
	passed = _check(passed, task_asset != null and task_asset.result_group != null, "带伤救回正式任务或结果组加载失败")
	passed = _check(passed, temporary_character.profession.is_empty(), "临时测试角色不应带特殊职业字段")
	if task_asset == null or task_asset.result_group == null:
		return false

	var day_system := DaySystem.new()
	var task_system := TaskSystem.new()
	var dispatch_system := DispatchSystem.new()
	var resolution_system := TaskResolutionSystem.new()
	var settlement_system := ResultSettlementSystem.new()
	var guild_state := GuildState.new()
	var relationship_system := StateRelationshipSystem.new()
	var character_state_system := CharacterStateSystem.new()
	var report_system := ReportIntelSystem.new()
	var nodes: Array[Node] = [day_system, task_system, dispatch_system, resolution_system, settlement_system, guild_state, relationship_system, character_state_system, report_system]
	for node in nodes:
		add_child(node)

	var task_instance := task_system.create_task_instance(task_asset)
	passed = _check(passed, task_instance != null, "带伤救回测试创建任务失败")
	if task_instance == null:
		_cleanup(nodes)
		return false
	passed = _check(passed, task_system.start_task_instance(task_instance.instance_id), "带伤救回测试启动任务失败")
	var dispatch_instance := dispatch_system.create_dispatch(
		task_instance.instance_id,
		[temporary_character],
		day_system.get_current_day(),
		task_asset.duration_days
	)
	passed = _check(passed, dispatch_instance != null, "带伤救回测试创建两日派遣失败")
	if dispatch_instance == null:
		_cleanup(nodes)
		return false
	passed = _check(passed, dispatch_instance.due_day == 3, "带伤救回测试到期日应为第 3 日")
	var duplicate_dispatch := dispatch_system.create_dispatch(
		task_instance.instance_id,
		[temporary_character],
		day_system.get_current_day(),
		task_asset.duration_days
	)
	passed = _check(passed, duplicate_dispatch == null, "带伤救回测试重复占用应被拒绝")

	day_system.advance_day()
	passed = _check(passed, day_system.get_current_day() == 2, "带伤救回测试第 2 日错误")
	var result_asset := _find_result(task_asset.result_group, INJURED_RESULT_ID)
	var early_result := ResultInstance.new()
	early_result.result_asset_id = INJURED_RESULT_ID
	early_result.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	if result_asset != null:
		early_result.resolved_effects.assign(result_asset.effects)
	passed = _check(passed, not settlement_system.settle_result(
		early_result,
		guild_state,
		relationship_system,
		character_state_system,
		report_system,
		task_system,
		task_instance,
		dispatch_instance,
		day_system.get_current_day(),
		result_asset
	), "带伤救回测试到期前结算应被拒绝")

	day_system.advance_day()
	passed = _check(passed, day_system.get_current_day() == 3, "带伤救回测试第 3 日错误")
	passed = _check(passed, dispatch_system.is_dispatch_due(dispatch_instance.dispatch_instance_id, day_system.get_current_day()), "带伤救回测试第 3 日应到期")
	var result_id := resolution_system.resolve_result(dispatch_instance, task_asset.result_group)
	passed = _check(passed, result_id == INJURED_RESULT_ID, "临时数值角色未命中带伤救回：%s" % result_id)
	passed = _check(passed, result_asset != null, "带伤救回结果资产读取失败")
	if result_asset == null:
		_cleanup(nodes)
		return false
	var result_instance := ResultInstance.new()
	result_instance.result_asset_id = result_id
	result_instance.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	result_instance.resolved_effects.assign(result_asset.effects)
	passed = _check(passed, report_system.can_record_report(result_instance), "带伤救回报告写入前检查失败")
	passed = _check(passed, not report_system.build_report(result_asset, result_instance).is_empty(), "带伤救回报告构建失败")
	passed = _check(passed, task_system.record_final_result(task_instance.instance_id, result_id), "带伤救回最终结果写入失败")
	passed = _check(passed, settlement_system.settle_result(
		result_instance,
		guild_state,
		relationship_system,
		character_state_system,
		report_system,
		task_system,
		task_instance,
		dispatch_instance,
		day_system.get_current_day(),
		result_asset
	), "带伤救回结果结算失败")
	var report := report_system.record_report(result_asset, result_instance)
	passed = _check(passed, report != null and report.result_asset_id == INJURED_RESULT_ID, "带伤救回报告记录失败")
	passed = _check(passed, task_instance.lifecycle_state == TERMINAL_STATE_IDS[INJURED_RESULT_ID], "带伤救回任务终态错误")
	passed = _check(passed, character_state_system.get_injury_level(temporary_character.id) == 1, "带伤救回伤势等级应为 1")
	passed = _check(passed, dispatch_system.end_dispatch(dispatch_instance.dispatch_instance_id, day_system.get_current_day()), "带伤救回派遣结束失败")
	passed = _check(passed, not dispatch_system.is_character_occupied(temporary_character.id), "带伤救回结束后应释放临时角色")
	if report != null:
		passed = _check(passed, report_system.mark_report_read(report.report_id), "带伤救回报告标记已读失败")
		passed = _check(passed, report.is_read, "带伤救回报告已读事实未保存")
	var duplicate_settlement := ResultInstance.new()
	duplicate_settlement.result_asset_id = result_id
	duplicate_settlement.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	duplicate_settlement.resolved_effects.assign(result_asset.effects)
	passed = _check(passed, not settlement_system.settle_result(
		duplicate_settlement,
		guild_state,
		relationship_system,
		character_state_system,
		report_system,
		task_system,
		task_instance,
		dispatch_instance,
		day_system.get_current_day(),
		result_asset
	), "带伤救回重复结算应被拒绝")
	_cleanup(nodes)
	return passed


func _find_formal_character(characters: Array[CharacterAsset], character_id: StringName) -> CharacterAsset:
	for character in characters:
		if character != null and character.id == character_id:
			return character
	return null


func _find_result(result_group: ResultGroupAsset, result_id: StringName) -> ResultAsset:
	if result_group == null:
		return null
	for result_asset in result_group.results:
		if result_asset != null and result_asset.id == result_id:
			return result_asset
	return null


func _cleanup(nodes: Array[Node]) -> void:
	for node in nodes:
		if is_instance_valid(node):
			node.queue_free()


func _check(current: bool, condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return current and condition
