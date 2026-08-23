class_name TaskResolutionSystem
extends Node


# 根据派遣角色能力检查结果组，并只接受唯一命中的静态结果。
func resolve_result(dispatch_instance: DispatchInstance, result_group: ResultGroupAsset) -> StringName:
	if dispatch_instance == null or result_group == null:
		push_error("TaskResolutionSystem 缺少派遣实例或结果组")
		return &""
	if dispatch_instance.character_refs.is_empty():
		push_error("TaskResolutionSystem 派遣实例没有角色")
		return &""
	for character in dispatch_instance.character_refs:
		if character == null:
			push_error("TaskResolutionSystem 派遣实例包含空角色引用")
			return &""
	var ability_totals := _aggregate_abilities(dispatch_instance.character_refs)
	var matched_results: Array[ResultAsset] = []
	for result_asset in result_group.results:
		if result_asset == null:
			push_error("TaskResolutionSystem 结果组包含空结果引用")
			return &""
		if _are_conditions_met(result_asset.conditions, ability_totals[&"investigation"]):
			matched_results.append(result_asset)
	if matched_results.size() != 1:
		push_error("TaskResolutionSystem 要求唯一结果，实际命中 %d 个" % matched_results.size())
		return &""
	return matched_results[0].id


# 三项能力只从 DispatchInstance 的角色真源即时汇总，不保存第二份运行状态。
func _aggregate_abilities(character_refs: Array[CharacterAsset]) -> Dictionary[StringName, int]:
	var ability_totals: Dictionary[StringName, int] = {
		&"battle": 0,
		&"investigation": 0,
		&"negotiation": 0,
	}
	for character in character_refs:
		ability_totals[&"battle"] += character.battle
		ability_totals[&"investigation"] += character.investigation
		ability_totals[&"negotiation"] += character.negotiation
	return ability_totals


# 当前条件契约使用默认 AND，并只读取已冻结的调查能力参数。
func _are_conditions_met(conditions: Array[ConditionResource], investigation_total: int) -> bool:
	if conditions.is_empty():
		return false
	for condition in conditions:
		if condition == null or not condition.is_met(investigation_total):
			return false
	return true
