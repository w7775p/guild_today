class_name ResultSettlementSystem
extends Node


# 同一派遣只能结算一次，记录由结算系统独占维护。
var _settled_dispatch_ids: Dictionary[StringName, bool] = {}


# 先验证完整效果集合，再把已确定效果分发给各状态拥有者。
func settle_result(
	result_instance: ResultInstance,
	guild_state: GuildState,
	relationship_system: StateRelationshipSystem = null,
	character_state_system: CharacterStateSystem = null,
	report_system: ReportIntelSystem = null,
	task_system: TaskSystem = null,
	task_instance: TaskInstance = null,
	dispatch_instance: DispatchInstance = null
) -> bool:
	if result_instance == null or guild_state == null:
		push_error("ResultSettlementSystem 缺少结果实例或 GuildState")
		return false
	if result_instance.result_asset_id.is_empty() or result_instance.dispatch_instance_id.is_empty():
		push_error("ResultSettlementSystem 结果实例缺少稳定关联 ID")
		return false
	if _settled_dispatch_ids.has(result_instance.dispatch_instance_id):
		push_error("ResultSettlementSystem 拒绝重复结算派遣：%s" % result_instance.dispatch_instance_id)
		return false
	if not _are_effects_supported(result_instance.resolved_effects):
		return false
	if not _can_apply_effects(result_instance.resolved_effects, relationship_system, character_state_system, report_system, task_system, task_instance, dispatch_instance):
		return false

	for effect in result_instance.resolved_effects:
		if effect is GoldEffect:
			guild_state.add_value(GuildState.GOLD_STATE_ID, (effect as GoldEffect).amount)
		elif effect is ReputationEffect:
			guild_state.add_value(GuildState.TOTAL_REPUTATION_STATE_ID, (effect as ReputationEffect).amount)
		elif effect is RelationshipEffect:
			relationship_system.add_value((effect as RelationshipEffect).relationship_id, (effect as RelationshipEffect).amount)
		elif effect is InjuryEffect:
			character_state_system.apply_injury(dispatch_instance, effect as InjuryEffect)
		elif effect is IntelEffect:
			var intel_effect := effect as IntelEffect
			report_system.record_intel(intel_effect.intel_id, intel_effect.unlock_task_id)
		elif effect is TaskOutcomeEffect:
			task_system.record_terminal_state(task_instance.instance_id, (effect as TaskOutcomeEffect).terminal_state_id)
	_settled_dispatch_ids[result_instance.dispatch_instance_id] = true
	return true


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
			if character_state_system.get_injury_target(dispatch_instance, effect as InjuryEffect) == null:
				return false
		elif effect is IntelEffect:
			var intel_effect := effect as IntelEffect
			if report_system == null or intel_effect.intel_id.is_empty() or intel_effect.unlock_task_id.is_empty():
				return false
		elif effect is TaskOutcomeEffect:
			if task_system == null or task_instance == null or (effect as TaskOutcomeEffect).terminal_state_id.is_empty():
				return false
			if task_system.get_task_instance(task_instance.instance_id) != task_instance:
				return false
	return true


# 当前允许六种具体效果，未知类型在任何状态修改前明确失败。
func _are_effects_supported(effects: Array[EffectResource]) -> bool:
	for effect in effects:
		if effect is GoldEffect or effect is ReputationEffect or effect is RelationshipEffect or effect is InjuryEffect or effect is IntelEffect or effect is TaskOutcomeEffect:
			continue
		push_error("ResultSettlementSystem 遇到未支持的效果类型")
		return false
	return true
