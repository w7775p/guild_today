extends Node


# 独立运行 Task 0–15 的成功链，确保最终验收日志没有预期异常分支噪音。
func _ready() -> void:
	_run_runtime_chain()
	get_tree().quit()


# 只组装已有系统，验证任务到报告的第一条运行时闭环。
func _run_runtime_chain() -> void:
	var task_asset: TaskAsset = load("res://tests/fixtures/abandoned_hospital.tres") as TaskAsset
	assert(task_asset != null, "完整链所需任务资产加载失败")
	var character := CharacterAsset.new()
	character.id = &"test_character_a"
	character.name = "角色A"
	character.investigation = 12
	var party: Array[CharacterAsset] = [character]

	var task_system := TaskSystem.new()
	var dispatch_system := DispatchSystem.new()
	var resolution_system := TaskResolutionSystem.new()
	var guild_state := GuildState.new()
	var settlement_system := ResultSettlementSystem.new()
	var report_system := ReportIntelSystem.new()
	add_child(task_system)
	add_child(dispatch_system)
	add_child(resolution_system)
	add_child(guild_state)
	add_child(settlement_system)
	add_child(report_system)

	var task_instance := task_system.create_task_instance(task_asset)
	assert(task_instance != null, "完整链创建 TaskInstance 失败")
	var dispatch_instance := dispatch_system.create_dispatch(task_instance.instance_id, party)
	assert(dispatch_instance != null, "完整链创建 DispatchInstance 失败")
	assert(dispatch_system.is_character_occupied(character.id), "ACTIVE 派遣应占用角色 A")

	var result_id := resolution_system.resolve_result(dispatch_instance, task_asset.result_group)
	assert(result_id == &"test_abandoned_hospital_success", "调查 12 应唯一命中成功结果")
	var result_asset := _find_result(task_asset.result_group, result_id)
	assert(result_asset != null, "完整链无法按 result_id 读取 ResultAsset")
	assert(task_system.record_final_result(task_instance.instance_id, result_id), "完整链写入最终结果 ID 失败")

	var result_instance := ResultInstance.new()
	result_instance.result_asset_id = result_asset.id
	result_instance.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	result_instance.resolved_effects.assign(result_asset.effects)
	assert(settlement_system.settle_result(result_instance, guild_state), "完整链结算结果失败")
	assert(guild_state.get_value(GuildState.GOLD_STATE_ID) == 100, "完整链最终金币应为 100")
	assert(guild_state.get_value(GuildState.TOTAL_REPUTATION_STATE_ID) == 5, "完整链最终总声望应为 5")

	var report_text := report_system.build_report(result_asset, result_instance)
	assert(report_text == "废弃医院调查完成\n获得金币100\n声望提升5", "完整链报告文本不正确")
	assert(dispatch_system.end_dispatch(dispatch_instance.dispatch_instance_id), "完整链结束派遣失败")
	assert(not dispatch_system.is_character_occupied(character.id), "派遣结束后应释放角色 A")
	print("Runtime vertical slice success: task=%s, dispatch=%s, result=%s, gold=100, total_reputation=5, report=%s" % [task_instance.instance_id, dispatch_instance.dispatch_instance_id, result_id, report_text.replace("\n", " | ")])


# ResultGroupAsset 是静态筛选入口，测试只按已确定 ID 读取对应结果引用。
func _find_result(result_group: ResultGroupAsset, result_id: StringName) -> ResultAsset:
	for result_asset in result_group.results:
		if result_asset.id == result_id:
			return result_asset
	return null
