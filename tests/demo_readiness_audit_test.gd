extends Node


const FORMAL_CHARACTER_IDS: Array[StringName] = [
	&"hero_aelius",
	&"hero_rin",
	&"hero_dai",
	&"hero_patrick",
	&"hero_astrid",
	&"hero_viletta",
]
const FORMAL_TASK_PATHS: Array[String] = [
	"res://assets/data/tasks/task_missing_caravan.tres",
	"res://assets/data/tasks/task_collapsed_mine_rescue.tres",
]
const VALID_ABILITY_IDS: Array[StringName] = [&"battle", &"investigation", &"negotiation"]


var _failed_checks: int = 0


# Demo Readiness 审计入口覆盖正式资产、边界状态、异常数据与可验证的运行时闭环。
func _ready() -> void:
	_check_formal_asset_inventory()
	_check_formal_characters()
	_check_formal_tasks()
	_check_task_lifecycle_boundaries()
	_check_dispatch_boundaries()
	_check_resolution_boundaries()
	_check_settlement_boundaries()
	_check_game_session_asset_boundary()
	_check_report_view_boundary()
	_check_restore_boundary()
	var passed := _failed_checks == 0
	if passed:
		print("Demo Readiness audit success: checks=all, save_disk=NOT_IMPLEMENTED")
	else:
		push_error("Demo Readiness audit failed: checks=%d" % _failed_checks)
	get_tree().quit(0 if passed else 1)


# 枚举全部正式资源，避免审计只覆盖写死的两张任务和六名角色。
func _check_formal_asset_inventory() -> void:
	var seen_ids: Dictionary[StringName, String] = {}
	var referenced_result_groups: Dictionary[StringName, bool] = {}
	var referenced_results: Dictionary[StringName, bool] = {}
	_check_formal_directory("res://assets/data/characters", &"character", seen_ids, referenced_result_groups, referenced_results)
	_check_formal_directory("res://assets/data/tasks", &"task", seen_ids, referenced_result_groups, referenced_results)
	_check_formal_directory("res://assets/data/results", &"result", seen_ids, referenced_result_groups, referenced_results)
	var result_dir := DirAccess.open("res://assets/data/results")
	if result_dir != null:
		var result_file := result_dir.get_next()
		while not result_file.is_empty():
			if not result_dir.current_is_dir() and result_file.ends_with(".tres"):
				var result_asset := load("res://assets/data/results/%s" % result_file) as ResultAsset
				if result_asset != null:
					_check(referenced_results.has(result_asset.id), "正式结果资产未被结果组引用：%s" % result_asset.id)
			result_file = result_dir.get_next()
		result_dir.list_dir_end()


func _check_formal_directory(
	directory: String,
	asset_kind: StringName,
	seen_ids: Dictionary[StringName, String],
	referenced_result_groups: Dictionary[StringName, bool],
	referenced_results: Dictionary[StringName, bool]
) -> void:
	var dir := DirAccess.open(directory)
	if not _check(dir != null, "正式资源目录无法读取：%s" % directory):
		return
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource_path := "%s/%s" % [directory, file_name]
			var resource := load(resource_path)
			var asset_id: StringName = &""
			if asset_kind == &"character":
				var character := resource as CharacterAsset
				asset_id = character.id if character != null else &""
			elif asset_kind == &"task":
				var task := resource as TaskAsset
				asset_id = task.id if task != null else &""
				if task != null and task.result_group != null:
					referenced_result_groups[task.result_group.id] = true
					for result_asset in task.result_group.results:
						if result_asset != null:
							referenced_results[result_asset.id] = true
			elif asset_kind == &"result":
				var result_group := resource as ResultGroupAsset
				if result_group != null:
					asset_id = result_group.id
					_check(referenced_result_groups.has(result_group.id), "正式结果组未被任务引用：%s" % result_group.id)
				else:
					var result_asset := resource as ResultAsset
					asset_id = result_asset.id if result_asset != null else &""
			_check(resource != null and not asset_id.is_empty(), "正式资源加载或 ID 失败：%s" % resource_path)
			if not asset_id.is_empty():
				_check(not seen_ids.has(asset_id), "正式资源 ID 重复：%s" % asset_id)
				seen_ids[asset_id] = resource_path
		file_name = dir.get_next()
	dir.list_dir_end()


func _check_formal_characters() -> void:
	var seen_ids: Dictionary[StringName, bool] = {}
	for character_id in FORMAL_CHARACTER_IDS:
		var character := load("res://assets/data/characters/%s.tres" % character_id) as CharacterAsset
		if not _check(character != null, "正式角色加载失败：%s" % character_id):
			continue
		_check(character.id == character_id, "正式角色 ID 与路径不一致：%s" % character_id)
		_check(not character.name.strip_edges().is_empty(), "正式角色名称为空：%s" % character_id)
		_check(not character.profession.strip_edges().is_empty(), "正式角色职业为空：%s" % character_id)
		_check(character.battle >= 0 and character.investigation >= 0 and character.negotiation >= 0, "正式角色能力出现负数：%s" % character_id)
		_check(not seen_ids.has(character.id), "正式角色 ID 重复：%s" % character.id)
		seen_ids[character.id] = true
	_check(seen_ids.size() == FORMAL_CHARACTER_IDS.size(), "正式角色 ID 集合不完整")


func _check_formal_tasks() -> void:
	for task_path in FORMAL_TASK_PATHS:
		var task_asset := load(task_path) as TaskAsset
		if not _check(task_asset != null, "正式任务加载失败：%s" % task_path):
			continue
		_check(not task_asset.id.is_empty(), "正式任务 ID 为空：%s" % task_path)
		_check(not task_asset.title.strip_edges().is_empty(), "正式任务标题为空：%s" % task_asset.id)
		_check(task_asset.duration_days >= 1, "正式任务时长非法：%s" % task_asset.id)
		_check(task_asset.min_party_size >= 1 and task_asset.max_party_size >= task_asset.min_party_size, "正式任务人数范围非法：%s" % task_asset.id)
		var result_group := task_asset.result_group
		if not _check(result_group != null and not result_group.id.is_empty(), "正式任务结果组缺失：%s" % task_asset.id):
			continue
		var result_ids: Dictionary[StringName, bool] = {}
		for result_asset in result_group.results:
			if not _check(result_asset != null, "结果组包含空引用：%s" % result_group.id):
				continue
			_check(not result_asset.id.is_empty() and not result_ids.has(result_asset.id), "结果 ID 为空或重复：%s" % result_group.id)
			result_ids[result_asset.id] = true
			_check(not result_asset.conditions.is_empty(), "结果条件为空：%s" % result_asset.id)
			_check(not result_asset.effects.is_empty(), "结果效果为空：%s" % result_asset.id)
			_check(not result_asset.report_text.strip_edges().is_empty(), "结果报告为空：%s" % result_asset.id)
			var terminal_effect_count := 0
			for effect in result_asset.effects:
				if effect is TaskOutcomeEffect:
					terminal_effect_count += 1
			_check(terminal_effect_count == 1, "正式结果必须包含唯一任务终态效果：%s" % result_asset.id)
		_check(result_ids.size() == result_group.results.size(), "结果组 ID 集合不完整：%s" % result_group.id)


func _check_task_lifecycle_boundaries() -> void:
	var task_asset := load("res://tests/fixtures/abandoned_hospital.tres") as TaskAsset
	var task_system := TaskSystem.new()
	add_child(task_system)
	var task_instance := task_system.create_task_instance(task_asset)
	if not _check(task_instance != null, "生命周期测试创建任务失败"):
		task_system.queue_free()
		return
	_check(not task_system.record_final_result(task_instance.instance_id, &"test_abandoned_hospital_success"), "PUBLISHED 任务不应写入最终结果")
	_check(not task_system.record_terminal_state(task_instance.instance_id, &"terminal_before_start"), "PUBLISHED 任务不应直接进入终态")
	_check(task_system.start_task_instance(task_instance.instance_id), "任务进入进行中失败")
	_check(not task_system.record_final_result(task_instance.instance_id, &"forged_result_id"), "任务不应接受不属于结果组的结果 ID")
	_check(task_system.record_final_result(task_instance.instance_id, &"test_abandoned_hospital_success"), "进行中任务写入最终结果失败")
	_check(not task_system.record_final_result(task_instance.instance_id, &"test_abandoned_hospital_failure"), "最终结果不应被覆盖")
	_check(task_system.record_terminal_state(task_instance.instance_id, &"terminal_lifecycle"), "已有结果的任务进入终态失败")
	_check(not task_system.record_terminal_state(task_instance.instance_id, &"terminal_overwrite"), "任务终态不应被覆盖")
	_check(not task_system.start_task_instance(task_instance.instance_id), "终态任务不应再次启动")
	task_system.queue_free()


func _check_dispatch_boundaries() -> void:
	var character := CharacterAsset.new()
	character.id = &"audit_dispatch_character"
	character.name = "审计角色"
	var dispatch_system := DispatchSystem.new()
	add_child(dispatch_system)
	var timed_dispatch := dispatch_system.create_dispatch(&"audit_task", [character], 1, 2)
	if not _check(timed_dispatch != null, "定时派遣创建失败"):
		dispatch_system.queue_free()
		return
	_check(not dispatch_system.end_dispatch(timed_dispatch.dispatch_instance_id, 2), "定时派遣不应提前结束")
	_check(dispatch_system.is_character_occupied(character.id), "提前结束失败后角色应继续占用")
	_check(dispatch_system.can_end_dispatch(timed_dispatch.dispatch_instance_id, 3), "到期派遣结束预检失败")
	_check(dispatch_system.end_dispatch(timed_dispatch.dispatch_instance_id, 3), "到期派遣结束失败")
	_check(not dispatch_system.is_character_occupied(character.id), "结束派遣后角色未释放")
	_check(not dispatch_system.end_dispatch(timed_dispatch.dispatch_instance_id, 3), "ENDED 派遣不应重复结束")
	var untimed_dispatch := dispatch_system.create_dispatch(&"audit_task_2", [character])
	_check(untimed_dispatch != null, "无日期派遣创建失败")
	if untimed_dispatch != null:
		_check(not dispatch_system.end_dispatch(untimed_dispatch.dispatch_instance_id, 0), "非法结束日应被拒绝")
		_check(dispatch_system.end_dispatch(untimed_dispatch.dispatch_instance_id), "无日期派遣兼容结束失败")
	var rollback_dispatch := dispatch_system.create_dispatch(&"audit_rollback_task", [character], 1, 2)
	_check(rollback_dispatch != null, "回滚派遣创建失败")
	if rollback_dispatch != null:
		_check(dispatch_system.cancel_dispatch(rollback_dispatch.dispatch_instance_id), "创建回滚入口失败")
		_check(rollback_dispatch.status == &"CANCELLED" and not dispatch_system.is_character_occupied(character.id), "回滚派遣未释放角色")
	var duplicate_party: Array[CharacterAsset] = [character, character]
	_check(dispatch_system.create_dispatch(&"audit_task_3", duplicate_party) == null, "同批重复角色应被拒绝")
	var null_party: Array[CharacterAsset] = [null]
	_check(dispatch_system.create_dispatch(&"audit_task_4", null_party) == null, "空角色引用应被拒绝")
	dispatch_system.queue_free()


func _check_resolution_boundaries() -> void:
	var task_asset := load("res://assets/data/tasks/task_missing_caravan.tres") as TaskAsset
	var character := load("res://assets/data/characters/hero_viletta.tres") as CharacterAsset
	var resolution_system := TaskResolutionSystem.new()
	add_child(resolution_system)
	var dispatch := DispatchInstance.new()
	dispatch.status = &"ACTIVE"
	dispatch.character_refs.assign([character])
	_check(resolution_system.resolve_result(dispatch, task_asset.result_group) == &"result_missing_caravan_full_success", "正式结果唯一命中失败")
	dispatch.status = &"ENDED"
	_check(resolution_system.resolve_result(dispatch, task_asset.result_group).is_empty(), "ENDED 派遣不应继续生成结果")
	dispatch.status = &"ACTIVE"
	var negative_character := CharacterAsset.new()
	negative_character.id = &"audit_negative_character"
	negative_character.investigation = -1
	dispatch.character_refs.assign([negative_character])
	_check(resolution_system.resolve_result(dispatch, task_asset.result_group).is_empty(), "负能力角色应被拒绝")
	var valid_condition := AbilityCondition.new()
	valid_condition.ability_id = &"investigation"
	valid_condition.value = 0
	var duplicate_a := ResultAsset.new()
	duplicate_a.id = &"audit_duplicate"
	duplicate_a.conditions.append(valid_condition)
	var duplicate_b := ResultAsset.new()
	duplicate_b.id = &"audit_duplicate"
	duplicate_b.conditions.append(valid_condition.duplicate() as ConditionResource)
	var duplicate_group := ResultGroupAsset.new()
	duplicate_group.id = &"audit_duplicate_group"
	duplicate_group.results.assign([duplicate_a, duplicate_b])
	dispatch.character_refs.assign([character])
	_check(resolution_system.resolve_result(dispatch, duplicate_group).is_empty(), "重复结果 ID 应被拒绝")
	var empty_result := ResultAsset.new()
	empty_result.id = &"audit_empty_result"
	var empty_group := ResultGroupAsset.new()
	empty_group.id = &"audit_empty_group"
	empty_group.results.append(empty_result)
	_check(resolution_system.resolve_result(dispatch, empty_group).is_empty(), "空条件结果应被拒绝")
	var unknown_condition := AbilityCondition.new()
	unknown_condition.ability_id = &"alchemy"
	unknown_condition.value = 1
	var unknown_result := ResultAsset.new()
	unknown_result.id = &"audit_unknown_ability"
	unknown_result.conditions.append(unknown_condition)
	var unknown_group := ResultGroupAsset.new()
	unknown_group.id = &"audit_unknown_group"
	unknown_group.results.append(unknown_result)
	_check(resolution_system.resolve_result(dispatch, unknown_group).is_empty(), "未知能力引用应被拒绝")
	_check(VALID_ABILITY_IDS.size() == 3, "审计能力白名单配置错误")
	resolution_system.queue_free()


func _check_settlement_boundaries() -> void:
	var task_asset := load("res://tests/fixtures/abandoned_hospital.tres") as TaskAsset
	var result_asset := load("res://tests/fixtures/test_abandoned_hospital_success.tres") as ResultAsset
	var character := CharacterAsset.new()
	character.id = &"audit_settlement_character"
	character.investigation = 12
	var task_system := TaskSystem.new()
	var dispatch_system := DispatchSystem.new()
	var settlement_system := ResultSettlementSystem.new()
	var guild_state := GuildState.new()
	add_child(task_system)
	add_child(dispatch_system)
	add_child(settlement_system)
	add_child(guild_state)
	var task_instance := task_system.create_task_instance(task_asset)
	var dispatch_instance := dispatch_system.create_dispatch(task_instance.instance_id, [character])
	task_system.start_task_instance(task_instance.instance_id)
	var result_instance := ResultInstance.new()
	result_instance.result_asset_id = result_asset.id
	result_instance.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	result_instance.resolved_effects.assign(result_asset.effects)
	var valid_outcome := TaskOutcomeEffect.new()
	valid_outcome.terminal_state_id = &"audit_valid_terminal"
	result_instance.resolved_effects.append(valid_outcome)
	var authoritative_result := ResultAsset.new()
	authoritative_result.id = result_asset.id
	authoritative_result.effects.assign(result_instance.resolved_effects)
	task_system.record_final_result(task_instance.instance_id, result_asset.id)
	_check(settlement_system.settle_result(result_instance, guild_state, null, null, null, task_system, task_instance, dispatch_instance, -1, authoritative_result), "合法资源结算失败")
	_check(guild_state.get_value(GuildState.GOLD_STATE_ID) == 100, "合法结算金币错误")
	_check(guild_state.get_value(GuildState.TOTAL_REPUTATION_STATE_ID) == 5, "合法结算声望错误")
	_check(not settlement_system.settle_result(result_instance, guild_state, null, null, null, task_system, task_instance, dispatch_instance, -1, authoritative_result), "重复结算应被拒绝")
	var rollback_task := task_system.create_task_instance(task_asset)
	task_system.start_task_instance(rollback_task.instance_id)
	var rollback_character := CharacterAsset.new()
	rollback_character.id = &"audit_rollback_character"
	var rollback_dispatch := dispatch_system.create_dispatch(rollback_task.instance_id, [rollback_character])
	var rollback_result := ResultInstance.new()
	rollback_result.result_asset_id = result_asset.id
	rollback_result.dispatch_instance_id = rollback_dispatch.dispatch_instance_id if rollback_dispatch != null else &"audit_missing_rollback_dispatch"
	rollback_result.resolved_effects.assign(result_asset.effects)
	var rollback_outcome := TaskOutcomeEffect.new()
	rollback_outcome.terminal_state_id = &"audit_rollback_terminal"
	rollback_result.resolved_effects.append(rollback_outcome)
	var rollback_asset := ResultAsset.new()
	rollback_asset.id = rollback_result.result_asset_id
	rollback_asset.effects.assign(rollback_result.resolved_effects)
	if _check(rollback_dispatch != null, "结算回滚测试派遣创建失败"):
		task_system.record_final_result(rollback_task.instance_id, rollback_result.result_asset_id)
		_check(settlement_system.settle_result(rollback_result, guild_state, null, null, null, task_system, rollback_task, rollback_dispatch, -1, rollback_asset), "结算回滚测试首次结算失败")
		_check(settlement_system.rollback_settlement(rollback_result, guild_state, null, null, null, task_system, rollback_task), "结算回滚入口失败")
		_check(guild_state.get_value(GuildState.GOLD_STATE_ID) == 100, "结算回滚未恢复金币")
		_check(rollback_task.lifecycle_state == TaskSystem.IN_PROGRESS_STATE and rollback_task.final_result_id == rollback_result.result_asset_id, "结算回滚未恢复任务事实")
		_check(rollback_dispatch.status == &"ACTIVE", "结算回滚不应改变派遣状态")
		dispatch_system.cancel_dispatch(rollback_dispatch.dispatch_instance_id)
	var atomic_task := task_system.create_task_instance(task_asset)
	task_system.start_task_instance(atomic_task.instance_id)
	var atomic_character := CharacterAsset.new()
	atomic_character.id = &"audit_atomic_character"
	atomic_character.battle = 4
	var atomic_dispatch := dispatch_system.create_dispatch(atomic_task.instance_id, [atomic_character])
	var atomic_relationship := StateRelationshipSystem.new()
	var atomic_character_state := CharacterStateSystem.new()
	var atomic_report := ReportIntelSystem.new()
	add_child(atomic_relationship)
	add_child(atomic_character_state)
	add_child(atomic_report)
	atomic_relationship.add_value(&"audit_atomic_relationship", 3)
	atomic_character_state.add_injury(atomic_character.id, 2)
	var atomic_gold := GoldEffect.new()
	atomic_gold.amount = 7
	var atomic_relationship_effect := RelationshipEffect.new()
	atomic_relationship_effect.relationship_id = &"audit_atomic_relationship"
	atomic_relationship_effect.amount = 4
	var atomic_injury := InjuryEffect.new()
	atomic_injury.severity = 2
	var atomic_intel := IntelEffect.new()
	atomic_intel.intel_id = &"audit_atomic_intel"
	atomic_intel.unlock_task_id = &"audit_atomic_followup"
	var atomic_outcome := TaskOutcomeEffect.new()
	atomic_outcome.terminal_state_id = &"audit_atomic_terminal"
	var atomic_result := ResultInstance.new()
	atomic_result.result_asset_id = result_asset.id
	atomic_result.dispatch_instance_id = atomic_dispatch.dispatch_instance_id if atomic_dispatch != null else &"audit_missing_atomic_dispatch"
	atomic_result.resolved_effects.assign([atomic_gold, atomic_relationship_effect, atomic_injury, atomic_intel, atomic_outcome])
	var atomic_asset := ResultAsset.new()
	atomic_asset.id = atomic_result.result_asset_id
	atomic_asset.effects.assign(atomic_result.resolved_effects)
	if _check(atomic_dispatch != null, "多状态结算回滚测试派遣创建失败"):
		task_system.record_final_result(atomic_task.instance_id, atomic_result.result_asset_id)
		_check(settlement_system.settle_result(atomic_result, guild_state, atomic_relationship, atomic_character_state, atomic_report, task_system, atomic_task, atomic_dispatch, -1, atomic_asset), "多状态结算回滚测试首次结算失败")
		_check(guild_state.get_value(GuildState.GOLD_STATE_ID) == 107, "多状态结算金币写入错误")
		_check(atomic_relationship.get_value(&"audit_atomic_relationship") == 7, "多状态结算关系写入错误")
		_check(atomic_character_state.get_injury_level(atomic_character.id) == 4, "多状态结算伤势写入错误")
		_check(atomic_report.get_unlocked_task_id(&"audit_atomic_intel") == &"audit_atomic_followup", "多状态结算情报写入错误")
		_check(settlement_system.rollback_settlement(atomic_result, guild_state, atomic_relationship, atomic_character_state, atomic_report, task_system, atomic_task), "多状态结算回滚入口失败")
		_check(guild_state.get_value(GuildState.GOLD_STATE_ID) == 100, "多状态回滚未恢复金币")
		_check(atomic_relationship.get_value(&"audit_atomic_relationship") == 3, "多状态回滚未恢复关系")
		_check(atomic_character_state.get_injury_level(atomic_character.id) == 2, "多状态回滚未恢复伤势")
		_check(atomic_report.get_unlocked_task_id(&"audit_atomic_intel").is_empty(), "多状态回滚未清理情报")
		_check(atomic_task.lifecycle_state == TaskSystem.IN_PROGRESS_STATE, "多状态回滚未恢复任务状态")
		dispatch_system.cancel_dispatch(atomic_dispatch.dispatch_instance_id)
	atomic_report.queue_free()
	atomic_character_state.queue_free()
	atomic_relationship.queue_free()
	var forged_result := ResultInstance.new()
	forged_result.result_asset_id = result_asset.id
	forged_result.dispatch_instance_id = &"audit_forged_dispatch"
	forged_result.resolved_effects.assign(result_asset.effects)
	_check(not settlement_system.settle_result(forged_result, guild_state, null, null, null, task_system, task_instance, dispatch_instance, -1, result_asset), "伪造派遣 ID 应被拒绝")
	var cross_task := task_system.create_task_instance(task_asset)
	task_system.start_task_instance(cross_task.instance_id)
	var cross_task_result := ResultInstance.new()
	cross_task_result.result_asset_id = result_asset.id
	cross_task_result.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	cross_task_result.resolved_effects.assign(result_asset.effects)
	_check(not settlement_system.settle_result(cross_task_result, guild_state, null, null, null, task_system, cross_task, dispatch_instance, -1, result_asset), "跨任务结算应被拒绝")
	var invalid_character := CharacterAsset.new()
	invalid_character.id = &"audit_invalid_settlement_character"
	var invalid_dispatch := dispatch_system.create_dispatch(&"audit_invalid_settlement_task", [invalid_character])
	_check(invalid_dispatch != null, "异常效果测试派遣创建失败")
	if invalid_dispatch != null:
		var tampered_result := ResultInstance.new()
		tampered_result.result_asset_id = result_asset.id
		tampered_result.dispatch_instance_id = invalid_dispatch.dispatch_instance_id
		var tampered_gold := GoldEffect.new()
		tampered_gold.amount = 999
		var tampered_reputation := ReputationEffect.new()
		tampered_reputation.amount = 5
		tampered_result.resolved_effects.assign([tampered_gold, tampered_reputation])
		_check(not settlement_system.settle_result(tampered_result, guild_state, null, null, null, null, null, invalid_dispatch, -1, result_asset), "匹配 ID 但篡改效果应被拒绝")
	var empty_result := ResultInstance.new()
	empty_result.result_asset_id = &"audit_empty_effects"
	empty_result.dispatch_instance_id = invalid_dispatch.dispatch_instance_id if invalid_dispatch != null else &"audit_missing_dispatch"
	var empty_asset := ResultAsset.new()
	empty_asset.id = empty_result.result_asset_id
	_check(not settlement_system.settle_result(empty_result, guild_state, null, null, null, null, null, invalid_dispatch, -1, empty_asset), "空效果结果应被拒绝")
	var unsupported_result := ResultInstance.new()
	unsupported_result.result_asset_id = &"audit_unsupported_effect"
	unsupported_result.dispatch_instance_id = invalid_dispatch.dispatch_instance_id if invalid_dispatch != null else &"audit_missing_dispatch"
	unsupported_result.resolved_effects.append(EffectResource.new())
	var unsupported_asset := ResultAsset.new()
	unsupported_asset.id = unsupported_result.result_asset_id
	unsupported_asset.effects.assign(unsupported_result.resolved_effects)
	_check(not settlement_system.settle_result(unsupported_result, guild_state, null, null, null, null, null, invalid_dispatch, -1, unsupported_asset), "未知效果类型应被拒绝")
	var conflict_report_system := ReportIntelSystem.new()
	add_child(conflict_report_system)
	conflict_report_system.record_intel(&"audit_conflict_intel", &"audit_old_task")
	var conflict_gold := GoldEffect.new()
	conflict_gold.amount = 7
	var conflict_intel := IntelEffect.new()
	conflict_intel.intel_id = &"audit_conflict_intel"
	conflict_intel.unlock_task_id = &"audit_new_task"
	var conflict_result := ResultInstance.new()
	conflict_result.result_asset_id = &"audit_conflict_result"
	conflict_result.dispatch_instance_id = invalid_dispatch.dispatch_instance_id if invalid_dispatch != null else &"audit_missing_dispatch"
	conflict_result.resolved_effects.assign([conflict_gold, conflict_intel])
	var conflict_asset := ResultAsset.new()
	conflict_asset.id = conflict_result.result_asset_id
	conflict_asset.effects.assign(conflict_result.resolved_effects)
	_check(not settlement_system.settle_result(conflict_result, guild_state, null, null, conflict_report_system, null, null, invalid_dispatch, -1, conflict_asset), "冲突情报引用应使整次结算失败")
	_check(guild_state.get_value(GuildState.GOLD_STATE_ID) == 100, "情报预检失败不应留下金币半写入")
	var batch_intel_a := IntelEffect.new()
	batch_intel_a.intel_id = &"audit_batch_conflict_intel"
	batch_intel_a.unlock_task_id = &"audit_batch_task_a"
	var batch_intel_b := IntelEffect.new()
	batch_intel_b.intel_id = batch_intel_a.intel_id
	batch_intel_b.unlock_task_id = &"audit_batch_task_b"
	var batch_result := ResultInstance.new()
	batch_result.result_asset_id = &"audit_batch_conflict_result"
	batch_result.dispatch_instance_id = invalid_dispatch.dispatch_instance_id if invalid_dispatch != null else &"audit_missing_dispatch"
	var batch_gold := GoldEffect.new()
	batch_gold.amount = 11
	batch_result.resolved_effects.assign([batch_gold, batch_intel_a, batch_intel_b])
	var batch_asset := ResultAsset.new()
	batch_asset.id = batch_result.result_asset_id
	batch_asset.effects.assign(batch_result.resolved_effects)
	_check(not settlement_system.settle_result(batch_result, guild_state, null, null, conflict_report_system, null, null, invalid_dispatch, -1, batch_asset), "同批次冲突情报应被拒绝")
	_check(guild_state.get_value(GuildState.GOLD_STATE_ID) == 100, "同批次情报预检失败不应留下金币半写入")
	conflict_report_system.queue_free()
	if invalid_dispatch != null:
		_check(dispatch_system.cancel_dispatch(invalid_dispatch.dispatch_instance_id), "异常效果测试派遣回滚失败")
	_check(guild_state.get_value(GuildState.GOLD_STATE_ID) == 100, "失败结算不应改变金币")
	var outcome_task := task_system.create_task_instance(task_asset)
	task_system.start_task_instance(outcome_task.instance_id)
	var outcome_character := CharacterAsset.new()
	outcome_character.id = &"audit_outcome_character"
	var outcome_dispatch := dispatch_system.create_dispatch(outcome_task.instance_id, [outcome_character])
	if not _check(outcome_dispatch != null, "终态边界派遣创建失败"):
		task_system.queue_free()
		dispatch_system.queue_free()
		settlement_system.queue_free()
		guild_state.queue_free()
		return
	var outcome_effect := TaskOutcomeEffect.new()
	outcome_effect.terminal_state_id = &"audit_terminal"
	var outcome_result := ResultInstance.new()
	outcome_result.result_asset_id = result_asset.id
	outcome_result.dispatch_instance_id = outcome_dispatch.dispatch_instance_id
	outcome_result.resolved_effects.append(outcome_effect)
	var outcome_asset := ResultAsset.new()
	outcome_asset.id = outcome_result.result_asset_id
	outcome_asset.effects.assign(outcome_result.resolved_effects)
	_check(not settlement_system.settle_result(outcome_result, guild_state, null, null, null, task_system, outcome_task, outcome_dispatch, -1, outcome_asset), "未记录最终结果的任务不应结算终态")
	_check(outcome_task.lifecycle_state == TaskSystem.IN_PROGRESS_STATE, "失败终态结算不应改变任务状态")
	_check(task_system.record_final_result(outcome_task.instance_id, outcome_result.result_asset_id), "终态数量边界测试写入结果失败")
	var second_outcome := TaskOutcomeEffect.new()
	second_outcome.terminal_state_id = &"audit_second_terminal"
	outcome_result.resolved_effects.append(second_outcome)
	outcome_asset.effects.assign(outcome_result.resolved_effects)
	_check(not settlement_system.settle_result(outcome_result, guild_state, null, null, null, task_system, outcome_task, outcome_dispatch, -1, outcome_asset), "多个终态效果应被拒绝")
	_check(outcome_task.lifecycle_state == TaskSystem.IN_PROGRESS_STATE, "多个终态效果失败不应改变任务状态")
	var ended_character := CharacterAsset.new()
	ended_character.id = &"audit_ended_character"
	var ended_dispatch := dispatch_system.create_dispatch(&"audit_ended_task", [ended_character])
	if ended_dispatch != null:
		dispatch_system.end_dispatch(ended_dispatch.dispatch_instance_id)
		var ended_result := ResultInstance.new()
		ended_result.result_asset_id = result_asset.id
		ended_result.dispatch_instance_id = ended_dispatch.dispatch_instance_id
		ended_result.resolved_effects.assign(result_asset.effects)
		_check(not settlement_system.settle_result(ended_result, guild_state, null, null, null, null, null, ended_dispatch, -1, result_asset), "ENDED 派遣不应结算")
	task_system.queue_free()
	dispatch_system.queue_free()
	settlement_system.queue_free()
	guild_state.queue_free()


func _check_game_session_asset_boundary() -> void:
	var session_scene := preload("res://runtime/game_session.tscn")
	var session := session_scene.instantiate() as GameSession
	if not _check(session != null, "GameSession 场景实例化失败"):
		return
	session.task_asset_path = "res://tests/fixtures/abandoned_hospital.tres"
	add_child(session)
	_check(not session.is_initialized(), "正式会话不应接受测试夹具路径")
	session.queue_free()
	var traversal_session := session_scene.instantiate() as GameSession
	if not _check(traversal_session != null, "路径穿越测试实例化失败"):
		return
	traversal_session.task_asset_path = "res://assets/data/tasks/../../tests/fixtures/abandoned_hospital.tres"
	add_child(traversal_session)
	_check(not traversal_session.is_initialized(), "正式会话不应接受路径穿越任务")
	traversal_session.queue_free()


# 报告引用或正文损坏时，界面必须拒绝展示并保持隐藏。
func _check_report_view_boundary() -> void:
	var report_view := preload("res://ui/reports/report_view.tscn").instantiate() as ReportView
	if not _check(report_view != null, "报告界面实例化失败"):
		return
	add_child(report_view)
	var dispatch := DispatchInstance.new()
	dispatch.dispatch_instance_id = &"audit_report_dispatch"
	var malformed_report := ReportRecord.new()
	malformed_report.report_id = dispatch.dispatch_instance_id
	malformed_report.result_asset_id = &"audit_report_result"
	malformed_report.dispatch_instance_id = dispatch.dispatch_instance_id
	malformed_report.text = "  "
	_check(not report_view.show_report(malformed_report, dispatch), "空报告正文不应展示")
	_check(not report_view.visible, "拒绝空报告后界面应保持隐藏")
	malformed_report.text = "有效报告"
	malformed_report.dispatch_instance_id = &"audit_other_dispatch"
	_check(not report_view.show_report(malformed_report, dispatch), "错配报告派遣 ID 不应展示")
	report_view.queue_free()


func _check_restore_boundary() -> void:
	var guild_state := GuildState.new()
	add_child(guild_state)
	guild_state.set_value(GuildState.GOLD_STATE_ID, 17)
	guild_state.restore_value(GuildState.GOLD_STATE_ID, 9)
	_check(guild_state.get_value(GuildState.GOLD_STATE_ID) == 9, "内存状态恢复入口失败")
	var report_system := ReportIntelSystem.new()
	add_child(report_system)
	_check(report_system.record_intel(&"audit_intel", &"audit_task"), "首次情报解锁写入失败")
	_check(report_system.record_intel(&"audit_intel", &"audit_task"), "相同情报重复写入应保持幂等")
	_check(not report_system.record_intel(&"audit_intel", &"audit_other_task"), "情报解锁不应被冲突引用覆盖")
	if ResourceLoader.exists("res://runtime/save/save_system.gd"):
		print("SaveSystem status: IMPLEMENTED_PATH_DETECTED")
	else:
		print("SaveSystem status: NOT_IMPLEMENTED")
	report_system.queue_free()
	guild_state.queue_free()


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed_checks += 1
	push_error(message)
	get_tree().quit(1)
	return false
