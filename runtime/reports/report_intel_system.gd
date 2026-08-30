class_name ReportIntelSystem
extends Node


# 报告系统独占保存报告记录与已获得情报。
var _reports: Dictionary[StringName, ReportRecord] = {}
var _intel_unlocks: Dictionary[StringName, StringName] = {}


# 把已确定结果与效果转换为玩家可读文本。
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
			var gold_amount := (effect as GoldEffect).amount
			report_lines.append("获得金币%d" % gold_amount)
		elif effect is ReputationEffect:
			var reputation_amount := (effect as ReputationEffect).amount
			if reputation_amount >= 0:
				report_lines.append("声望提升%d" % reputation_amount)
			else:
				report_lines.append("声望下降%d" % absi(reputation_amount))
		elif effect is RelationshipEffect:
			var relationship_amount := (effect as RelationshipEffect).amount
			report_lines.append("商人关系变化%d" % relationship_amount)
		elif effect is InjuryEffect:
			report_lines.append("角色受伤，伤势等级%d" % (effect as InjuryEffect).severity)
		elif effect is IntelEffect:
			report_lines.append("获得情报：%s" % (effect as IntelEffect).intel_id)
		elif effect is TaskOutcomeEffect:
			report_lines.append("任务终态：%s" % (effect as TaskOutcomeEffect).terminal_state_id)
	return "\n".join(report_lines)


# 保存一条可按派遣 ID 读取的报告记录，重复派遣报告会被拒绝。
func record_report(result_asset: ResultAsset, result_instance: ResultInstance) -> ReportRecord:
	if result_instance == null:
		return null
	var report_text := build_report(result_asset, result_instance)
	if report_text.is_empty() or result_instance.dispatch_instance_id.is_empty():
		return null
	if _reports.has(result_instance.dispatch_instance_id):
		push_error("ReportIntelSystem 拒绝重复报告：%s" % result_instance.dispatch_instance_id)
		return null
	var record := ReportRecord.new()
	record.report_id = result_instance.dispatch_instance_id
	record.result_asset_id = result_instance.result_asset_id
	record.dispatch_instance_id = result_instance.dispatch_instance_id
	record.text = report_text
	_reports[record.report_id] = record
	return record


# 在写入前检查报告记录是否可以创建，供结算流程保持明确失败边界。
func can_record_report(result_instance: ResultInstance) -> bool:
	return result_instance != null and not result_instance.dispatch_instance_id.is_empty() and not _reports.has(result_instance.dispatch_instance_id)


# 通过稳定报告 ID读取已保存记录。
func get_report(report_id: StringName) -> ReportRecord:
	return _reports.get(report_id) as ReportRecord


# 未读报告从报告真源即时筛选，供 GameSession 和后续 UI 查询。
func get_unread_reports() -> Array[ReportRecord]:
	var unread_reports: Array[ReportRecord] = []
	for value in _reports.values():
		var report := value as ReportRecord
		if not report.is_read:
			unread_reports.append(report)
	return unread_reports


# 关闭报告只改变阅读事实，不重复触发任何效果。
func mark_report_read(report_id: StringName) -> bool:
	var record := get_report(report_id)
	if record == null:
		return false
	record.is_read = true
	return true


# 情报与后续解锁由报告系统持有，未确认 ID 仍按占位值记录。
func record_intel(intel_id: StringName, unlock_task_id: StringName) -> bool:
	if intel_id.is_empty() or unlock_task_id.is_empty():
		push_error("ReportIntelSystem 情报效果缺少稳定引用")
		return false
	_intel_unlocks[intel_id] = unlock_task_id
	return true


# 读取情报对应的后续解锁 ID。
func get_unlocked_task_id(intel_id: StringName) -> StringName:
	return StringName(_intel_unlocks.get(intel_id, &""))


# 报告支持当前 Task 3 的具体效果类型，不引入通用文案注册表。
func _are_effects_supported(effects: Array[EffectResource]) -> bool:
	for effect in effects:
		if effect is GoldEffect or effect is ReputationEffect or effect is RelationshipEffect or effect is InjuryEffect or effect is IntelEffect or effect is TaskOutcomeEffect:
			continue
		push_error("ReportIntelSystem 遇到未支持的效果类型")
		return false
	return true
