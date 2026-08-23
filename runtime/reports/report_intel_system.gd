class_name ReportIntelSystem
extends Node


# 把已确定结果与效果转换为首轮玩家可读文本，不保存报告历史。
func build_report(result_asset: ResultAsset, result_instance: ResultInstance) -> String:
	if result_asset == null or result_instance == null:
		push_error("ReportIntelSystem 缺少结果资产或结果实例")
		return ""
	if result_asset.id.is_empty() or result_asset.id != result_instance.result_asset_id:
		push_error("ReportIntelSystem 结果资产与结果实例不匹配")
		return ""
	if result_asset.report_text.is_empty():
		push_error("ReportIntelSystem 结果资产缺少报告文本")
		return ""
	if not _are_effects_supported(result_instance.resolved_effects):
		return ""

	var report_lines: Array[String] = [result_asset.report_text]
	for effect in result_instance.resolved_effects:
		if effect is GoldEffect:
			report_lines.append("获得金币%d" % (effect as GoldEffect).amount)
		elif effect is ReputationEffect:
			report_lines.append("声望提升%d" % (effect as ReputationEffect).amount)
	return "\n".join(report_lines)


# 首轮报告只解释当前已冻结的两种效果，不建立通用文案注册表。
func _are_effects_supported(effects: Array[EffectResource]) -> bool:
	for effect in effects:
		if effect is GoldEffect or effect is ReputationEffect:
			continue
		push_error("ReportIntelSystem 遇到未支持的效果类型")
		return false
	return true
