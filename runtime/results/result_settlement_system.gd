class_name ResultSettlementSystem
extends Node


# 同一派遣只能结算一次，记录由结算系统独占维护。
var _settled_dispatch_ids: Dictionary[StringName, bool] = {}


# 先验证完整效果集合，再把已确定效果分发给 GuildState。
func settle_result(result_instance: ResultInstance, guild_state: GuildState) -> bool:
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

	for effect in result_instance.resolved_effects:
		if effect is GoldEffect:
			guild_state.add_value(GuildState.GOLD_STATE_ID, (effect as GoldEffect).amount)
		elif effect is ReputationEffect:
			guild_state.add_value(GuildState.TOTAL_REPUTATION_STATE_ID, (effect as ReputationEffect).amount)
	_settled_dispatch_ids[result_instance.dispatch_instance_id] = true
	return true


# 首轮只允许两种已冻结效果，未知类型在任何状态修改前明确失败。
func _are_effects_supported(effects: Array[EffectResource]) -> bool:
	for effect in effects:
		if effect is GoldEffect or effect is ReputationEffect:
			continue
		push_error("ResultSettlementSystem 遇到未支持的效果类型")
		return false
	return true
