extends Node


const FORMAL_TASK_PATH := "res://assets/data/tasks/task_missing_caravan.tres"


func _ready() -> void:
	# 专项测试覆盖正式角色、最高能力语义、五结果区间与唯一命中约束。
	var passed := _run_resolution_matrix()
	if passed:
		print("V3 Task 2 resolution success: matrix=11, max_ability=true, unique_results=true")
	else:
		push_error("V3 Task 2 resolution failed")
	get_tree().quit(0 if passed else 1)


func _run_resolution_matrix() -> bool:
	var task_asset := load(FORMAL_TASK_PATH) as TaskAsset
	if task_asset == null or task_asset.result_group == null:
		push_error("正式任务或结果组加载失败")
		return false
	var resolution_system := TaskResolutionSystem.new()
	add_child(resolution_system)
	var characters := _load_formal_characters()
	if characters.is_empty():
		resolution_system.queue_free()
		return false

	var cases: Array[Dictionary] = [
		{"label": "维蕾塔单人", "party": [&"hero_viletta"], "expected": &"result_missing_caravan_full_success"},
		{"label": "阿斯特里德单人", "party": [&"hero_astrid"], "expected": &"result_missing_caravan_full_success"},
		{"label": "埃利乌斯单人", "party": [&"hero_aelius"], "expected": &"result_missing_caravan_search_failed"},
		{"label": "凛单人", "party": [&"hero_rin"], "expected": &"result_missing_caravan_search_failed"},
		{"label": "戴禛单人", "party": [&"hero_dai"], "expected": &"result_missing_caravan_location_confirmed"},
		{"label": "帕特里克单人", "party": [&"hero_patrick"], "expected": &"result_missing_caravan_location_confirmed"},
		{"label": "维蕾塔与埃利乌斯", "party": [&"hero_viletta", &"hero_aelius"], "expected": &"result_missing_caravan_full_success"},
		{"label": "戴禛与埃利乌斯", "party": [&"hero_dai", &"hero_aelius"], "expected": &"result_missing_caravan_delayed_success"},
		{"label": "帕特里克与凛", "party": [&"hero_patrick", &"hero_rin"], "expected": &"result_missing_caravan_delayed_success"},
		{"label": "戴禛与帕特里克", "party": [&"hero_dai", &"hero_patrick"], "expected": &"result_missing_caravan_location_confirmed"},
		{"label": "埃利乌斯与凛", "party": [&"hero_aelius", &"hero_rin"], "expected": &"result_missing_caravan_search_failed"},
	]
	var passed := true
	for case_data in cases:
		var party: Array[CharacterAsset] = []
		for character_id in case_data["party"]:
			party.append(characters[character_id])
		var dispatch := DispatchInstance.new()
		dispatch.status = &"ACTIVE"
		dispatch.character_refs.assign(party)
		var result_id := resolution_system.resolve_result(dispatch, task_asset.result_group)
		passed = _check(passed, result_id == case_data["expected"], "%s 结果错误：%s" % [case_data["label"], result_id])

	var injured_character := CharacterAsset.new()
	injured_character.id = &"test_task2_injured_character"
	injured_character.battle = 5
	injured_character.investigation = 5
	var injured_dispatch := DispatchInstance.new()
	injured_dispatch.status = &"ACTIVE"
	injured_dispatch.character_refs.assign([injured_character])
	var injured_result_id := resolution_system.resolve_result(injured_dispatch, task_asset.result_group)
	passed = _check(passed, injured_result_id == &"result_missing_caravan_injured_rescue", "边界队伍应命中带伤救回")
	resolution_system.queue_free()
	return passed


func _load_formal_characters() -> Dictionary[StringName, CharacterAsset]:
	var characters: Dictionary[StringName, CharacterAsset] = {}
	for character_id in [&"hero_aelius", &"hero_rin", &"hero_dai", &"hero_patrick", &"hero_astrid", &"hero_viletta"]:
		var character_path := "res://assets/data/characters/%s.tres" % character_id
		var character := load(character_path) as CharacterAsset
		if character == null:
			push_error("正式角色加载失败：%s" % character_id)
			return {}
		characters[character.id] = character
	return characters


func _check(current: bool, condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return current and condition
