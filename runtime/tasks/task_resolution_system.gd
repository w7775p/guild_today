class_name TaskResolutionSystem
extends Node


const VALID_ABILITY_IDS: Array[StringName] = [&"battle", &"investigation", &"negotiation"]


# 根据派遣角色能力检查结果组，并只接受唯一命中的静态结果。
func resolve_result(dispatch_instance: DispatchInstance, result_group: ResultGroupAsset) -> StringName:
	if dispatch_instance == null or result_group == null:
		push_error("TaskResolutionSystem 缺少派遣实例或结果组")
		return &""
	if dispatch_instance.status != &"ACTIVE":
		push_error("TaskResolutionSystem 只接受 ACTIVE 派遣")
		return &""
	if dispatch_instance.character_refs.is_empty():
		push_error("TaskResolutionSystem 派遣实例没有角色")
		return &""
	for character in dispatch_instance.character_refs:
		if character == null:
			push_error("TaskResolutionSystem 派遣实例包含空角色引用")
			return &""
		if not _are_character_values_valid(character):
			return &""
	if not _validate_result_group(result_group):
		return &""
	var ability_maxima := _get_ability_maxima(dispatch_instance.character_refs)
	var matched_results: Array[ResultAsset] = []
	for result_asset in result_group.results:
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


# 结果组在匹配前整体校验，避免空 ID、重复 ID 或未知条件被合法结果掩盖。
func _validate_result_group(result_group: ResultGroupAsset) -> bool:
	if result_group.id.is_empty() or result_group.results.is_empty():
		push_error("TaskResolutionSystem 结果组缺少稳定 ID 或结果")
		return false
	var result_ids: Dictionary[StringName, bool] = {}
	for result_asset in result_group.results:
		if result_asset == null or result_asset.id.is_empty() or result_ids.has(result_asset.id):
			push_error("TaskResolutionSystem 结果组包含空或重复结果 ID")
			return false
		result_ids[result_asset.id] = true
		if result_asset.conditions.is_empty():
			push_error("TaskResolutionSystem 结果缺少条件：%s" % result_asset.id)
			return false
		for condition in result_asset.conditions:
			if not _is_condition_valid(condition):
				return false
	return true


func _is_condition_valid(condition: ConditionResource) -> bool:
	if condition == null:
		push_error("TaskResolutionSystem 条件集合包含空引用")
		return false
	var ability_id := _get_condition_ability_id(condition)
	if not VALID_ABILITY_IDS.has(ability_id):
		push_error("TaskResolutionSystem 条件引用未知能力：%s" % ability_id)
		return false
	if condition is AbilityCondition and (condition as AbilityCondition).value < 0:
		push_error("TaskResolutionSystem 达标条件阈值不能为负数")
		return false
	if condition is AbilityBelowCondition and (condition as AbilityBelowCondition).value < 0:
		push_error("TaskResolutionSystem 低于条件阈值不能为负数")
		return false
	return true


func _are_character_values_valid(character: CharacterAsset) -> bool:
	if character.battle < 0 or character.investigation < 0 or character.negotiation < 0:
		push_error("TaskResolutionSystem 角色能力不能为负数：%s" % character.id)
		return false
	return true
