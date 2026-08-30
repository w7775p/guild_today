class_name ResultSettlementSystem
extends Node


# 同一派遣只能结算一次，记录由结算系统独占维护。
var _settled_dispatch_ids: Dictionary[StringName, bool] = {}
var _settlement_snapshots: Dictionary[StringName, Dictionary] = {}


# 先验证完整效果集合，再把已确定效果分发给各状态拥有者。
func settle_result(
	result_instance: ResultInstance,
	guild_state: GuildState,
	relationship_system: StateRelationshipSystem = null,
	character_state_system: CharacterStateSystem = null,
	report_system: ReportIntelSystem = null,
	task_system: TaskSystem = null,
	task_instance: TaskInstance = null,
	dispatch_instance: DispatchInstance = null,
	current_day: int = -1,
	authoritative_result_asset: ResultAsset = null
) -> bool:
	if result_instance == null or guild_state == null:
		push_error("ResultSettlementSystem 缺少结果实例或 GuildState")
		return false
	if result_instance.result_asset_id.is_empty() or result_instance.dispatch_instance_id.is_empty():
		push_error("ResultSettlementSystem 结果实例缺少稳定关联 ID")
		return false
	if authoritative_result_asset == null or not _result_matches_asset(result_instance, authoritative_result_asset):
		push_error("ResultSettlementSystem 必须使用匹配的权威结果资产")
		return false
	if dispatch_instance == null:
		push_error("ResultSettlementSystem 正式结算必须提供派遣实例")
		return false
	if dispatch_instance.status != &"ACTIVE" or dispatch_instance.dispatch_instance_id != result_instance.dispatch_instance_id or dispatch_instance.task_instance_id.is_empty():
		push_error("ResultSettlementSystem 结果与派遣实例关联不一致")
		return false
	if task_instance != null and dispatch_instance.task_instance_id != task_instance.instance_id:
		push_error("ResultSettlementSystem 派遣与任务实例关联不一致")
		return false
	if task_instance != null:
		if task_system == null or task_system.get_task_instance(task_instance.instance_id) != task_instance:
			push_error("ResultSettlementSystem 任务实例不属于传入 TaskSystem")
			return false
		if task_instance.lifecycle_state != TaskSystem.IN_PROGRESS_STATE or task_instance.final_result_id != result_instance.result_asset_id:
			push_error("ResultSettlementSystem 任务尚未记录匹配的最终结果")
			return false
	if _settled_dispatch_ids.has(result_instance.dispatch_instance_id):
		push_error("ResultSettlementSystem 拒绝重复结算派遣：%s" % result_instance.dispatch_instance_id)
		return false
	if dispatch_instance != null and dispatch_instance.due_day >= 1 and (current_day < 1 or current_day < dispatch_instance.due_day):
		push_error("ResultSettlementSystem 拒绝未到期派遣结算：%s" % dispatch_instance.dispatch_instance_id)
		return false
	if not _are_effects_supported(result_instance.resolved_effects):
		return false
	if not _can_apply_effects(result_instance.resolved_effects, relationship_system, character_state_system, report_system, task_system, task_instance, dispatch_instance):
		return false

	var snapshot := _capture_snapshot(result_instance, guild_state, relationship_system, character_state_system, report_system, task_instance, dispatch_instance)
	for effect in result_instance.resolved_effects:
		if effect is GoldEffect:
			guild_state.add_value(GuildState.GOLD_STATE_ID, (effect as GoldEffect).amount)
		elif effect is ReputationEffect:
			guild_state.add_value(GuildState.TOTAL_REPUTATION_STATE_ID, (effect as ReputationEffect).amount)
		elif effect is RelationshipEffect:
			if not relationship_system.add_value((effect as RelationshipEffect).relationship_id, (effect as RelationshipEffect).amount):
				_restore_snapshot(snapshot, guild_state, relationship_system, character_state_system, report_system, task_system, task_instance)
				return false
		elif effect is InjuryEffect:
			if not character_state_system.apply_injury(dispatch_instance, effect as InjuryEffect):
				_restore_snapshot(snapshot, guild_state, relationship_system, character_state_system, report_system, task_system, task_instance)
				return false
		elif effect is IntelEffect:
			var intel_effect := effect as IntelEffect
			if not report_system.record_intel(intel_effect.intel_id, intel_effect.unlock_task_id):
				_restore_snapshot(snapshot, guild_state, relationship_system, character_state_system, report_system, task_system, task_instance)
				return false
		elif effect is TaskOutcomeEffect:
			if not task_system.record_terminal_state(task_instance.instance_id, (effect as TaskOutcomeEffect).terminal_state_id):
				_restore_snapshot(snapshot, guild_state, relationship_system, character_state_system, report_system, task_system, task_instance)
				return false
	_settled_dispatch_ids[result_instance.dispatch_instance_id] = true
	_settlement_snapshots[result_instance.dispatch_instance_id] = snapshot
	return true


# 结算后续步骤失败时由上层调用，撤销所有本次状态写入和去重标记。
func rollback_settlement(
	result_instance: ResultInstance,
	guild_state: GuildState,
	relationship_system: StateRelationshipSystem = null,
	character_state_system: CharacterStateSystem = null,
	report_system: ReportIntelSystem = null,
	task_system: TaskSystem = null,
	task_instance: TaskInstance = null
) -> bool:
	if result_instance == null or result_instance.dispatch_instance_id.is_empty() or not _settlement_snapshots.has(result_instance.dispatch_instance_id):
		return false
	var snapshot: Dictionary = _settlement_snapshots[result_instance.dispatch_instance_id]
	_restore_snapshot(snapshot, guild_state, relationship_system, character_state_system, report_system, task_system, task_instance)
	_settlement_snapshots.erase(result_instance.dispatch_instance_id)
	_settled_dispatch_ids.erase(result_instance.dispatch_instance_id)
	return true


# 派遣结束并发布报告后提交事务，释放仅用于失败回滚的快照。
func finalize_settlement(dispatch_instance_id: StringName) -> bool:
	if dispatch_instance_id.is_empty() or not _settled_dispatch_ids.has(dispatch_instance_id):
		return false
	_settlement_snapshots.erase(dispatch_instance_id)
	return true


func _capture_snapshot(
	result_instance: ResultInstance,
	guild_state: GuildState,
	relationship_system: StateRelationshipSystem,
	character_state_system: CharacterStateSystem,
	report_system: ReportIntelSystem,
	task_instance: TaskInstance,
	dispatch_instance: DispatchInstance
) -> Dictionary:
	var relationship_values := {}
	var injury_values := {}
	var intel_values := {}
	for effect in result_instance.resolved_effects:
		if effect is RelationshipEffect and relationship_system != null:
			var relationship_id := (effect as RelationshipEffect).relationship_id
			if not relationship_values.has(relationship_id):
				relationship_values[relationship_id] = {"value": relationship_system.get_value(relationship_id), "present": relationship_system.has_value(relationship_id)}
		elif effect is InjuryEffect and character_state_system != null:
			var injury_target := character_state_system.get_injury_target(dispatch_instance, effect as InjuryEffect)
			if injury_target != null and not injury_values.has(injury_target.id):
				injury_values[injury_target.id] = {"value": character_state_system.get_injury_level(injury_target.id), "present": character_state_system.has_character_state(injury_target.id)}
		elif effect is IntelEffect and report_system != null:
			var intel_id := (effect as IntelEffect).intel_id
			if not intel_values.has(intel_id):
				intel_values[intel_id] = {"value": report_system.get_unlocked_task_id(intel_id), "present": report_system.has_intel(intel_id)}
	return {
		"gold": guild_state.get_value(GuildState.GOLD_STATE_ID),
		"reputation": guild_state.get_value(GuildState.TOTAL_REPUTATION_STATE_ID),
		"relationships": relationship_values,
		"injuries": injury_values,
		"intel": intel_values,
		"task_lifecycle": task_instance.lifecycle_state if task_instance != null else &"",
		"task_final_result": task_instance.final_result_id if task_instance != null else &"",
	}


func _restore_snapshot(
	snapshot: Dictionary,
	guild_state: GuildState,
	relationship_system: StateRelationshipSystem,
	character_state_system: CharacterStateSystem,
	report_system: ReportIntelSystem,
	task_system: TaskSystem,
	task_instance: TaskInstance
) -> void:
	if guild_state != null:
		guild_state.restore_value(GuildState.GOLD_STATE_ID, int(snapshot.get("gold", 0)))
		guild_state.restore_value(GuildState.TOTAL_REPUTATION_STATE_ID, int(snapshot.get("reputation", 0)))
	if relationship_system != null:
		for relationship_id in snapshot.get("relationships", {}).keys():
			var relationship_snapshot: Dictionary = snapshot["relationships"][relationship_id]
			relationship_system.restore_value(relationship_id, int(relationship_snapshot["value"]), bool(relationship_snapshot["present"]))
	if character_state_system != null:
		for character_id in snapshot.get("injuries", {}).keys():
			var injury_snapshot: Dictionary = snapshot["injuries"][character_id]
			character_state_system.restore_injury(character_id, int(injury_snapshot["value"]), bool(injury_snapshot["present"]))
	if report_system != null:
		for intel_id in snapshot.get("intel", {}).keys():
			var intel_snapshot: Dictionary = snapshot["intel"][intel_id]
			report_system.restore_intel(intel_id, intel_snapshot["value"], bool(intel_snapshot["present"]))
	if task_system != null and task_instance != null and not StringName(snapshot.get("task_lifecycle", &"")).is_empty():
		task_system.restore_runtime_state(task_instance.instance_id, snapshot["task_lifecycle"], snapshot["task_final_result"])


# 结算只接受上层依据 ResultAsset 创建的效果快照，拒绝同 ID 的篡改结果。
func _result_matches_asset(result_instance: ResultInstance, result_asset: ResultAsset) -> bool:
	if result_asset.id.is_empty() or result_asset.id != result_instance.result_asset_id:
		return false
	if result_asset.effects.size() != result_instance.resolved_effects.size():
		return false
	for index in result_asset.effects.size():
		if not _effects_match(result_asset.effects[index], result_instance.resolved_effects[index]):
			return false
	return true


func _effects_match(expected: EffectResource, actual: EffectResource) -> bool:
	if expected == null or actual == null or expected.get_script() != actual.get_script():
		return false
	if expected is GoldEffect:
		return (expected as GoldEffect).amount == (actual as GoldEffect).amount
	if expected is ReputationEffect:
		return (expected as ReputationEffect).amount == (actual as ReputationEffect).amount
	if expected is RelationshipEffect:
		var expected_relationship := expected as RelationshipEffect
		var actual_relationship := actual as RelationshipEffect
		return expected_relationship.relationship_id == actual_relationship.relationship_id and expected_relationship.amount == actual_relationship.amount
	if expected is InjuryEffect:
		var expected_injury := expected as InjuryEffect
		var actual_injury := actual as InjuryEffect
		return expected_injury.target_rule == actual_injury.target_rule and expected_injury.severity == actual_injury.severity
	if expected is IntelEffect:
		var expected_intel := expected as IntelEffect
		var actual_intel := actual as IntelEffect
		return expected_intel.intel_id == actual_intel.intel_id and expected_intel.unlock_task_id == actual_intel.unlock_task_id
	if expected is TaskOutcomeEffect:
		return (expected as TaskOutcomeEffect).terminal_state_id == (actual as TaskOutcomeEffect).terminal_state_id
	# 未知类型先允许快照匹配，再由支持类型白名单给出明确拒绝。
	return expected == actual


# 在任何状态写入前验证效果所需的最小状态拥有者。
func _can_apply_effects(
	effects: Array[EffectResource],
	relationship_system: StateRelationshipSystem,
	character_state_system: CharacterStateSystem,
	report_system: ReportIntelSystem,
	task_system: TaskSystem,
	task_instance: TaskInstance,
	dispatch_instance: DispatchInstance
) -> bool:
	if effects.is_empty():
		push_error("ResultSettlementSystem 效果集合不能为空")
		return false
	var task_outcome_count := 0
	var pending_intel_unlocks: Dictionary[StringName, StringName] = {}
	for effect in effects:
		if effect == null:
			push_error("ResultSettlementSystem 效果集合包含空引用")
			return false
		if effect is RelationshipEffect:
			if relationship_system == null or (effect as RelationshipEffect).relationship_id.is_empty():
				return false
		elif effect is InjuryEffect:
			if character_state_system == null or dispatch_instance == null or (effect as InjuryEffect).severity <= 0:
				return false
			if (effect as InjuryEffect).target_rule != CharacterStateSystem.HIGHEST_BATTLE_MEMBER_RULE:
				return false
			var injury_target := character_state_system.get_injury_target(dispatch_instance, effect as InjuryEffect)
			if injury_target == null or injury_target.id.is_empty():
				return false
		elif effect is IntelEffect:
			var intel_effect := effect as IntelEffect
			if report_system == null or not report_system.can_record_intel(intel_effect.intel_id, intel_effect.unlock_task_id):
				return false
			if pending_intel_unlocks.has(intel_effect.intel_id) and pending_intel_unlocks[intel_effect.intel_id] != intel_effect.unlock_task_id:
				push_error("ResultSettlementSystem 同批次情报引用冲突：%s" % intel_effect.intel_id)
				return false
			pending_intel_unlocks[intel_effect.intel_id] = intel_effect.unlock_task_id
		elif effect is TaskOutcomeEffect:
			task_outcome_count += 1
			if task_system == null or task_instance == null or (effect as TaskOutcomeEffect).terminal_state_id.is_empty():
				return false
			if task_system.get_task_instance(task_instance.instance_id) != task_instance:
				return false
	if task_outcome_count > 1 or (task_instance != null and task_outcome_count != 1):
		push_error("ResultSettlementSystem 任务结算必须包含且只能包含一个终态效果")
		return false
	return true


# 当前允许六种具体效果，未知类型在任何状态修改前明确失败。
func _are_effects_supported(effects: Array[EffectResource]) -> bool:
	if effects.is_empty():
		push_error("ResultSettlementSystem 效果集合不能为空")
		return false
	for effect in effects:
		if effect is GoldEffect or effect is ReputationEffect or effect is RelationshipEffect or effect is InjuryEffect or effect is IntelEffect or effect is TaskOutcomeEffect:
			continue
		push_error("ResultSettlementSystem 遇到未支持的效果类型")
		return false
	return true
