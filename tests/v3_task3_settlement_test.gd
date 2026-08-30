extends Node


const FORMAL_TASK_PATH := "res://assets/data/tasks/task_missing_caravan.tres"
const FULL_SUCCESS_RELATIONSHIP_ID: StringName = &"【relationship_merchant_evaluation】"
const SEARCH_FAILED_RELATIONSHIP_ID: StringName = &"【relationship_merchant_trust】"
const LOCATION_INTEL_ID: StringName = &"【intel_missing_caravan_location】"
const LOCATION_UNLOCK_TASK_ID: StringName = &"【task_missing_caravan_followup_rescue】"

const TERMINAL_STATE_IDS: Dictionary = {
	&"result_missing_caravan_full_success": &"【task_outcome_full_success】",
	&"result_missing_caravan_delayed_success": &"【task_outcome_delayed_success】",
	&"result_missing_caravan_injured_rescue": &"【task_outcome_injured_rescue】",
	&"result_missing_caravan_location_confirmed": &"【task_outcome_location_confirmed】",
	&"result_missing_caravan_search_failed": &"【task_outcome_search_failed】"
}


func _ready() -> void:
	# 专项测试覆盖五个正式结果的效果写入、报告记录与重复保护边界。
	var passed := _run_settlement_cases()
	if passed:
		print("V3 Task 3 settlement success: results=5, reports=5, persistent_effects=true")
	else:
		push_error("V3 Task 3 settlement failed")
	get_tree().quit(0 if passed else 1)


func _run_settlement_cases() -> bool:
	var task_asset := load(FORMAL_TASK_PATH) as TaskAsset
	if task_asset == null or task_asset.result_group == null:
		push_error("正式任务或结果组加载失败")
		return false
	var characters := _load_formal_characters()
	if characters.size() != 6:
		return false

	var cases: Array[Dictionary] = [
		{"result": &"result_missing_caravan_full_success", "party": [&"hero_viletta"]},
		{"result": &"result_missing_caravan_delayed_success", "party": [&"hero_dai", &"hero_aelius"]},
		{"result": &"result_missing_caravan_injured_rescue", "party": [&"test_injured_member"]},
		{"result": &"result_missing_caravan_location_confirmed", "party": [&"hero_dai"]},
		{"result": &"result_missing_caravan_search_failed", "party": [&"hero_aelius"]},
	]
	var passed := true
	for case_data in cases:
		var party := _build_party(case_data["party"], characters)
		if case_data["result"] == &"result_missing_caravan_injured_rescue":
			var injured_member := CharacterAsset.new()
			injured_member.id = &"test_injured_member"
			injured_member.name = "测试受伤角色"
			injured_member.battle = 5
			injured_member.investigation = 5
			party = [injured_member]
		passed = _check(passed, not party.is_empty(), "带伤救回测试队伍为空")
		passed = _run_case(task_asset, case_data["result"], party, passed)
	return passed


func _run_case(task_asset: TaskAsset, expected_result_id: StringName, party: Array[CharacterAsset], passed: bool) -> bool:
	var task_system := TaskSystem.new()
	var dispatch_system := DispatchSystem.new()
	var resolution_system := TaskResolutionSystem.new()
	var guild_state := GuildState.new()
	var relationship_system := StateRelationshipSystem.new()
	var character_state_system := CharacterStateSystem.new()
	var report_system := ReportIntelSystem.new()
	var settlement_system := ResultSettlementSystem.new()
	add_child(task_system)
	add_child(dispatch_system)
	add_child(resolution_system)
	add_child(guild_state)
	add_child(relationship_system)
	add_child(character_state_system)
	add_child(report_system)
	add_child(settlement_system)

	var task_instance := task_system.create_task_instance(task_asset)
	if task_instance == null:
		return _cleanup_and_return([task_system, dispatch_system, resolution_system, guild_state, relationship_system, character_state_system, report_system, settlement_system], false)
	var dispatch_instance := dispatch_system.create_dispatch(task_instance.instance_id, party)
	passed = _check(passed, task_instance != null and dispatch_instance != null, "创建任务或派遣失败")
	if not passed:
		return _cleanup_and_return([task_system, dispatch_system, resolution_system, guild_state, relationship_system, character_state_system, report_system, settlement_system], false)
	var actual_result_id := resolution_system.resolve_result(dispatch_instance, task_asset.result_group)
	passed = _check(passed, actual_result_id == expected_result_id, "结果命中错误：%s" % actual_result_id)
	var result_asset := _find_result(task_asset.result_group, actual_result_id)
	passed = _check(passed, result_asset != null, "结果资产读取失败：%s" % actual_result_id)
	if result_asset == null:
		return _cleanup_and_return([task_system, dispatch_system, resolution_system, guild_state, relationship_system, character_state_system, report_system, settlement_system], false)
	var result_instance := ResultInstance.new()
	result_instance.result_asset_id = actual_result_id
	result_instance.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	result_instance.resolved_effects.assign(result_asset.effects)
	passed = _check(passed, task_system.record_final_result(task_instance.instance_id, actual_result_id), "最终结果写入失败")
	passed = _check(passed, settlement_system.settle_result(result_instance, guild_state, relationship_system, character_state_system, report_system, task_system, task_instance, dispatch_instance), "结果结算失败：%s" % actual_result_id)
	var report := report_system.record_report(result_asset, result_instance)
	passed = _check(passed, report != null, "报告记录创建失败：%s" % actual_result_id)
	if report == null:
		return _cleanup_and_return([task_system, dispatch_system, resolution_system, guild_state, relationship_system, character_state_system, report_system, settlement_system], false)
	passed = _check(passed, report.result_asset_id == actual_result_id, "报告结果 ID 不正确")
	passed = _check(passed, report.dispatch_instance_id == dispatch_instance.dispatch_instance_id, "报告派遣 ID 不正确")
	passed = _check(passed, not report.text.is_empty(), "报告文本不应为空")
	passed = _check(passed, report_system.get_report(dispatch_instance.dispatch_instance_id) == report, "报告应可按派遣 ID 读取")
	passed = _check(passed, not settlement_system.settle_result(result_instance, guild_state, relationship_system, character_state_system, report_system, task_system, task_instance, dispatch_instance), "重复结算必须被拒绝")
	passed = _check(passed, task_instance.lifecycle_state == TERMINAL_STATE_IDS[actual_result_id], "结果终态占位 ID 错误")
	if actual_result_id == &"result_missing_caravan_full_success":
		passed = _check(passed, guild_state.get_value(GuildState.GOLD_STATE_ID) == 90, "完整成功金币应为 90")
		passed = _check(passed, relationship_system.get_value(FULL_SUCCESS_RELATIONSHIP_ID) == 5, "完整成功关系变化应为工作性推测 +5")
	elif actual_result_id == &"result_missing_caravan_delayed_success":
		passed = _check(passed, guild_state.get_value(GuildState.GOLD_STATE_ID) == 60, "延迟成功金币应为工作性推测 60")
		passed = _check(passed, character_state_system.get_injury_level(&"hero_aelius") == 1, "延迟成功应按工作规则使最高战斗角色受伤")
	elif actual_result_id == &"result_missing_caravan_injured_rescue":
		passed = _check(passed, character_state_system.get_injury_level(&"test_injured_member") == 1, "带伤救回伤势等级应为工作性推测 1")
	elif actual_result_id == &"result_missing_caravan_location_confirmed":
		passed = _check(passed, report_system.get_unlocked_task_id(LOCATION_INTEL_ID) == LOCATION_UNLOCK_TASK_ID, "查明位置应保存独立情报与解锁占位 ID")
	elif actual_result_id == &"result_missing_caravan_search_failed":
		passed = _check(passed, relationship_system.get_value(SEARCH_FAILED_RELATIONSHIP_ID) == -5, "搜索失败关系变化应为工作性推测 -5")
	passed = _check(passed, report_system.mark_report_read(report.report_id), "报告应支持标记已读")
	passed = _check(passed, report.is_read, "报告已读事实未保存")
	_cleanup_and_return([task_system, dispatch_system, resolution_system, guild_state, relationship_system, character_state_system, report_system, settlement_system], passed)
	return passed


func _build_party(ids: Array, characters: Dictionary[StringName, CharacterAsset]) -> Array[CharacterAsset]:
	var party: Array[CharacterAsset] = []
	for character_id in ids:
		if characters.has(character_id):
			party.append(characters[character_id])
	return party


func _load_formal_characters() -> Dictionary[StringName, CharacterAsset]:
	var characters: Dictionary[StringName, CharacterAsset] = {}
	for character_id in [&"hero_aelius", &"hero_rin", &"hero_dai", &"hero_patrick", &"hero_astrid", &"hero_viletta"]:
		var character := load("res://assets/data/characters/%s.tres" % character_id) as CharacterAsset
		if character == null:
			push_error("正式角色加载失败：%s" % character_id)
			return {}
		characters[character.id] = character
	return characters


func _find_result(result_group: ResultGroupAsset, result_id: StringName) -> ResultAsset:
	for result_asset in result_group.results:
		if result_asset != null and result_asset.id == result_id:
			return result_asset
	return null


func _cleanup_and_return(nodes: Array, result: bool) -> bool:
	for node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	return result


func _check(current: bool, condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return current and condition
