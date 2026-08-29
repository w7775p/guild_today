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
	var ability_maxima := _get_ability_maxima(dispatch_instance.character_refs)
	var matched_results: Array[ResultAsset] = []
	for result_asset in result_group.results:
		if result_asset == null:
			push_error("TaskResolutionSystem 结果组包含空结果引用")
			return &""
		if _are_conditions_met(result_asset.conditions, ability_maxima):
			matched_results.append(result_asset)
	if matched_results.size() != 1:
		push_error("TaskResolutionSystem 要求唯一结果，实际命中 %d 个" % matched_results.size())
		return &""
	return matched_results[0].id


# 三项能力只从 DispatchInstance 的角色真源即时读取最高值，不保存第二份运行状态。
func _get_ability_maxima(character_refs: Array[CharacterAsset]) -> Dictionary[StringName, int]:
	var ability_maxima: Dictionary[StringName, int] = {
		&"battle": 0,
		&"investigation": 0,
		&"negotiation": 0,
	}
	for character in character_refs:
		ability_maxima[&"battle"] = maxi(ability_maxima[&"battle"], character.battle)
		ability_maxima[&"investigation"] = maxi(ability_maxima[&"investigation"], character.investigation)
		ability_maxima[&"negotiation"] = maxi(ability_maxima[&"negotiation"], character.negotiation)
	return ability_maxima


# 多个条件固定采用 AND；每个能力条件通过 ability_id 读取最高能力值。
func _are_conditions_met(conditions: Array[ConditionResource], ability_maxima: Dictionary[StringName, int]) -> bool:
	if conditions.is_empty():
		return false
	for condition in conditions:
		if condition == null:
			return false
		var ability_id := _get_condition_ability_id(condition)
		if ability_id.is_empty() or not ability_maxima.has(ability_id):
			push_error("TaskResolutionSystem 条件引用未知能力：%s" % ability_id)
			return false
		if not condition.is_met(ability_maxima[ability_id]):
			return false
	return true


# 只接受当前已冻结的两种能力条件，避免引入通用规则解析器。
func _get_condition_ability_id(condition: ConditionResource) -> StringName:
	if condition is AbilityCondition:
		return (condition as AbilityCondition).ability_id
	if condition is AbilityBelowCondition:
		return (condition as AbilityBelowCondition).ability_id
	push_error("TaskResolutionSystem 不支持的条件类型：%s" % condition.get_class())
	return &""
