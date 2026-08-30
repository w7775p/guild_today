extends Node


var _failed_checks: int = 0


# 独立运行 Task 0–15 的成功链，失败时返回非零退出码供自动验证消费。
func _ready() -> void:
	_run_runtime_chain()
	var passed := _failed_checks == 0
	if passed:
		print("Runtime vertical slice success")
	else:
		push_error("Runtime vertical slice failed: checks=%d" % _failed_checks)
	get_tree().quit(0 if passed else 1)


# 只组装已有系统，验证任务到报告的第一条运行时闭环。
func _run_runtime_chain() -> void:
	var task_asset: TaskAsset = load("res://tests/fixtures/abandoned_hospital.tres") as TaskAsset
	if not _check(task_asset != null, "完整链所需任务资产加载失败"):
		return
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
	if not _check(task_instance != null, "完整链创建 TaskInstance 失败"):
		return
	if not _check(task_system.start_task_instance(task_instance.instance_id), "完整链启动任务失败"):
		return
	var dispatch_instance := dispatch_system.create_dispatch(task_instance.instance_id, party)
	if not _check(dispatch_instance != null, "完整链创建 DispatchInstance 失败"):
		return
	_check(dispatch_system.is_character_occupied(character.id), "ACTIVE 派遣应占用角色 A")

	var result_id := resolution_system.resolve_result(dispatch_instance, task_asset.result_group)
	if not _check(result_id == &"test_abandoned_hospital_success", "调查 12 应唯一命中成功结果"):
		return
	var result_asset := _find_result(task_asset.result_group, result_id)
	if not _check(result_asset != null, "完整链无法按 result_id 读取 ResultAsset"):
		return

	var result_instance := ResultInstance.new()
	result_instance.result_asset_id = result_asset.id
	result_instance.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	result_instance.resolved_effects.assign(result_asset.effects)
	_check(task_system.record_final_result(task_instance.instance_id, result_id), "完整链写入最终结果 ID 失败")
	_check(settlement_system.settle_result(result_instance, guild_state, null, null, null, null, null, dispatch_instance, -1, result_asset), "完整链结算结果失败")
	_check(guild_state.get_value(GuildState.GOLD_STATE_ID) == 100, "完整链最终金币应为 100")
	_check(guild_state.get_value(GuildState.TOTAL_REPUTATION_STATE_ID) == 5, "完整链最终总声望应为 5")

	var report_text := report_system.build_report(result_asset, result_instance)
	_check(report_text == "废弃医院调查完成\n获得金币100\n声望提升5", "完整链报告文本不正确")
	var report := report_system.record_report(result_asset, result_instance)
	_check(report != null, "完整链报告记录失败")
	_check(report != null and report_system.get_report(dispatch_instance.dispatch_instance_id) == report, "完整链报告无法按派遣 ID 读取")
	_check(dispatch_system.end_dispatch(dispatch_instance.dispatch_instance_id), "完整链结束派遣失败")
	_check(not dispatch_system.is_character_occupied(character.id), "派遣结束后应释放角色 A")


# ResultGroupAsset 是静态筛选入口，测试只按已确定 ID 读取对应结果引用。
func _find_result(result_group: ResultGroupAsset, result_id: StringName) -> ResultAsset:
	for result_asset in result_group.results:
		if result_asset != null and result_asset.id == result_id:
			return result_asset
	return null


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed_checks += 1
	push_error(message)
	get_tree().quit(1)
	return false
