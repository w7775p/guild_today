extends Node


# 启动主场景时输出最小验证信息，确认项目运行链正常。
func _ready() -> void:
	print("Guild Today Open As Usual boot success")
	_validate_character_asset()
	_validate_task_asset()
	_validate_ability_condition()
	_validate_effect_resources()
	_validate_result_asset()
	_validate_result_group_asset()
	_validate_task_instance()
	_validate_dispatch_instance()
	_validate_result_instance()
	_validate_task_system()
	_validate_dispatch_system()
	_validate_task_resolution_system()


# 通过实际加载 TEST_ONLY 资源，验证 Task 1 的静态字段和稳定 ID。
func _validate_character_asset() -> void:
	var character: CharacterAsset = load("res://tests/fixtures/character_a.tres") as CharacterAsset
	assert(character != null, "CharacterAsset fixture 加载失败")
	assert(String(character.id) == "test_character_a", "CharacterAsset ID 不正确")
	assert(character.name == "角色A", "CharacterAsset 名称不正确")
	assert(character.battle == 5, "CharacterAsset battle 不正确")
	assert(character.investigation == 10, "CharacterAsset investigation 不正确")
	assert(character.negotiation == 7, "CharacterAsset negotiation 不正确")
	print("CharacterAsset load success: id=%s, name=%s, investigation=%d" % [character.id, character.name, character.investigation])


# 通过实际加载 TEST_ONLY 资源，验证 Task 2 的静态字段。
func _validate_task_asset() -> void:
	var task: TaskAsset = load("res://tests/fixtures/abandoned_hospital.tres") as TaskAsset
	assert(task != null, "TaskAsset fixture 加载失败")
	assert(String(task.id) == "test_abandoned_hospital", "TaskAsset ID 不正确")
	assert(task.title == "废弃医院调查", "TaskAsset 标题不正确")
	assert(task.description == "调查废弃医院中的异常情况。", "TaskAsset 描述不正确")
	assert(task.repeatable == false, "TaskAsset repeatable 不正确")
	assert(task.result_group is ResultGroupAsset, "TaskAsset 应绑定 ResultGroupAsset")
	assert(task.event_reference == null, "TaskAsset 不应提前绑定 EventAsset")
	print("TaskAsset load success: id=%s, title=%s, repeatable=%s" % [task.id, task.title, task.repeatable])


# 通过两个确定性 TEST_ONLY 资源验证调查能力阈值的成立与不成立分支。
func _validate_ability_condition() -> void:
	var threshold_10: AbilityCondition = load("res://tests/fixtures/test_investigation_at_least_10.tres") as AbilityCondition
	var threshold_13: AbilityCondition = load("res://tests/fixtures/test_investigation_at_least_13.tres") as AbilityCondition
	assert(threshold_10 != null, "AbilityCondition 阈值 10 fixture 加载失败")
	assert(threshold_13 != null, "AbilityCondition 阈值 13 fixture 加载失败")
	assert(threshold_10.value == 10, "AbilityCondition 阈值 10 读取错误")
	assert(threshold_13.value == 13, "AbilityCondition 阈值 13 读取错误")
	assert(threshold_10.is_met(12), "调查能力 12 应满足阈值 10")
	assert(not threshold_13.is_met(12), "调查能力 12 不应满足阈值 13")
	print("AbilityCondition check success: investigation=12, threshold_10=true, threshold_13=false")


# 只验证效果 Resource 的具体类型和值，不在本 Task 执行任何状态写入。
func _validate_effect_resources() -> void:
	var gold_effect: GoldEffect = load("res://tests/fixtures/test_gold_plus_100.tres") as GoldEffect
	var reputation_effect: ReputationEffect = load("res://tests/fixtures/test_reputation_plus_5.tres") as ReputationEffect
	assert(gold_effect != null, "GoldEffect fixture 加载失败")
	assert(reputation_effect != null, "ReputationEffect fixture 加载失败")
	assert(gold_effect is EffectResource, "GoldEffect 必须继承 EffectResource")
	assert(reputation_effect is EffectResource, "ReputationEffect 必须继承 EffectResource")
	assert(gold_effect.amount == 100, "GoldEffect amount 不正确")
	assert(reputation_effect.amount == 5, "ReputationEffect amount 不正确")
	print("EffectResource load success: gold=100, reputation=5")


# 只沿 ResultAsset 读取静态引用，条件判断与效果执行留给后续系统。
func _validate_result_asset() -> void:
	var result: ResultAsset = load("res://tests/fixtures/test_abandoned_hospital_success.tres") as ResultAsset
	assert(result != null, "ResultAsset fixture 加载失败")
	assert(String(result.id) == "test_abandoned_hospital_success", "ResultAsset ID 不正确")
	assert(result.conditions.size() == 1, "ResultAsset 条件数量不正确")
	assert(result.effects.size() == 2, "ResultAsset 效果数量不正确")
	assert(result.conditions[0] is AbilityCondition, "ResultAsset 条件类型不正确")
	assert((result.conditions[0] as AbilityCondition).value == 10, "ResultAsset 调查阈值不正确")
	assert(result.effects[0] is GoldEffect, "ResultAsset 金币效果类型不正确")
	assert((result.effects[0] as GoldEffect).amount == 100, "ResultAsset 金币效果值不正确")
	assert(result.effects[1] is ReputationEffect, "ResultAsset 声望效果类型不正确")
	assert((result.effects[1] as ReputationEffect).amount == 5, "ResultAsset 声望效果值不正确")
	assert(result.report_text == "废弃医院调查完成", "ResultAsset 报告文本不正确")
	print("ResultAsset load success: id=%s, conditions=1, effects=2, report=%s" % [result.id, result.report_text])


# 沿 TaskAsset 引用读取结果组及两个结果，不在本 Task 执行筛选或排序。
func _validate_result_group_asset() -> void:
	var task: TaskAsset = load("res://tests/fixtures/abandoned_hospital.tres") as TaskAsset
	assert(task != null, "TaskAsset fixture 加载失败")
	var result_group: ResultGroupAsset = task.result_group
	assert(result_group != null, "ResultGroupAsset fixture 加载失败")
	assert(String(result_group.id) == "test_abandoned_hospital_results", "ResultGroupAsset ID 不正确")
	assert(result_group.results.size() == 2, "ResultGroupAsset 结果数量不正确")
	assert(String(result_group.results[0].id) == "test_abandoned_hospital_success", "成功结果 ID 不正确")
	assert(String(result_group.results[1].id) == "test_abandoned_hospital_failure", "失败结果 ID 不正确")
	assert(result_group.results[0].conditions[0] is AbilityCondition, "成功结果条件类型不正确")
	assert(result_group.results[1].conditions[0] is AbilityBelowCondition, "失败结果条件类型不正确")
	var success_condition := result_group.results[0].conditions[0] as AbilityCondition
	var failure_condition := result_group.results[1].conditions[0] as AbilityBelowCondition
	assert(failure_condition.value == 10, "失败结果阈值不正确")
	assert(not success_condition.is_met(9) and failure_condition.is_met(9), "调查能力 9 应只满足失败条件")
	assert(success_condition.is_met(10) and not failure_condition.is_met(10), "调查能力 10 应只满足成功条件")
	print("ResultGroupAsset load success: id=%s, success=%s, failure=%s" % [result_group.id, result_group.results[0].id, result_group.results[1].id])


# 手动创建同一静态任务的两个运行实例，验证每份运行事实彼此隔离。
func _validate_task_instance() -> void:
	var first_instance := TaskInstance.new()
	first_instance.instance_id = &"test_task_instance_001"
	first_instance.task_id = &"test_abandoned_hospital"
	first_instance.lifecycle_state = &"PUBLISHED"
	first_instance.runtime_progress[&"investigation"] = 1

	var second_instance := TaskInstance.new()
	second_instance.instance_id = &"test_task_instance_002"
	second_instance.task_id = &"test_abandoned_hospital"
	second_instance.lifecycle_state = &"PUBLISHED"
	second_instance.runtime_progress[&"investigation"] = 3

	first_instance.lifecycle_state = &"IN_PROGRESS"
	first_instance.final_result_id = &"test_abandoned_hospital_success"
	first_instance.runtime_progress[&"investigation"] = 2

	assert(first_instance.instance_id != second_instance.instance_id, "TaskInstance 实例 ID 必须不同")
	assert(first_instance.task_id == second_instance.task_id, "两个实例应引用同一静态任务 ID")
	assert(first_instance.lifecycle_state == &"IN_PROGRESS", "第一个实例生命周期事实不正确")
	assert(second_instance.lifecycle_state == &"PUBLISHED", "第二个实例生命周期事实被污染")
	assert(first_instance.final_result_id == &"test_abandoned_hospital_success", "第一个实例最终结果 ID 不正确")
	assert(second_instance.final_result_id.is_empty(), "第二个实例最终结果 ID 被污染")
	assert(first_instance.runtime_progress[&"investigation"] == 2, "第一个实例进度不正确")
	assert(second_instance.runtime_progress[&"investigation"] == 3, "第二个实例进度被污染")
	print("TaskInstance isolation success: first=%s, second=%s, task=%s" % [first_instance.instance_id, second_instance.instance_id, first_instance.task_id])


# 创建三个 TEST_ONLY 角色引用，验证派遣成员只保存在 DispatchInstance。
func _validate_dispatch_instance() -> void:
	var character_a: CharacterAsset = load("res://tests/fixtures/character_a.tres") as CharacterAsset
	assert(character_a != null, "DispatchInstance 角色 A 加载失败")
	var character_b := CharacterAsset.new()
	character_b.id = &"test_character_b"
	character_b.name = "角色B"
	var character_c := CharacterAsset.new()
	character_c.id = &"test_character_c"
	character_c.name = "角色C"

	var dispatch := DispatchInstance.new()
	dispatch.dispatch_instance_id = &"test_dispatch_instance_001"
	dispatch.task_instance_id = &"test_task_instance_001"
	dispatch.character_refs.assign([character_a, character_b, character_c])
	dispatch.status = &"ACTIVE"

	assert(dispatch.dispatch_instance_id == &"test_dispatch_instance_001", "DispatchInstance ID 不正确")
	assert(dispatch.task_instance_id == &"test_task_instance_001", "DispatchInstance 任务实例 ID 不正确")
	assert(dispatch.character_refs.size() == 3, "DispatchInstance 应保存三个角色引用")
	assert(dispatch.character_refs[0] == character_a, "DispatchInstance 角色 A 引用不正确")
	assert(dispatch.character_refs[1] == character_b, "DispatchInstance 角色 B 引用不正确")
	assert(dispatch.character_refs[2] == character_c, "DispatchInstance 角色 C 引用不正确")
	assert(dispatch.status == &"ACTIVE", "DispatchInstance 状态不正确")
	assert(not "party_member_ids" in TaskInstance.new(), "TaskInstance 不得保存可变派遣成员副本")
	print("DispatchInstance refs success: id=%s, task=%s, characters=%s" % [dispatch.dispatch_instance_id, dispatch.task_instance_id, [dispatch.character_refs[0].id, dispatch.character_refs[1].id, dispatch.character_refs[2].id]])


# 从成功结果复制已确定效果引用，验证运行记录不会改写静态 ResultAsset 数组。
func _validate_result_instance() -> void:
	var result_asset: ResultAsset = load("res://tests/fixtures/test_abandoned_hospital_success.tres") as ResultAsset
	assert(result_asset != null, "ResultInstance 所需 ResultAsset 加载失败")
	var gold_effect := result_asset.effects[0]
	var reputation_effect := result_asset.effects[1]

	var result_instance := ResultInstance.new()
	result_instance.result_asset_id = result_asset.id
	result_instance.dispatch_instance_id = &"test_dispatch_instance_001"
	result_instance.resolved_effects.assign(result_asset.effects)

	assert(result_instance.result_asset_id == &"test_abandoned_hospital_success", "ResultInstance 结果资产 ID 不正确")
	assert(result_instance.dispatch_instance_id == &"test_dispatch_instance_001", "ResultInstance 派遣实例 ID 不正确")
	assert(result_instance.resolved_effects.size() == 2, "ResultInstance 应保存两个已确定效果")
	assert(result_instance.resolved_effects[0] == gold_effect, "ResultInstance 金币效果引用不正确")
	assert(result_instance.resolved_effects[1] == reputation_effect, "ResultInstance 声望效果引用不正确")
	result_instance.resolved_effects.reverse()
	assert(result_asset.effects[0] == gold_effect, "ResultInstance 数组变化不应改写 ResultAsset")
	assert(result_asset.effects[1] == reputation_effect, "ResultAsset 效果顺序被运行记录污染")
	result_instance.resolved_effects.reverse()
	print("ResultInstance record success: result=%s, dispatch=%s, effects=%d" % [result_instance.result_asset_id, result_instance.dispatch_instance_id, result_instance.resolved_effects.size()])


# 让 TaskSystem 创建并拥有两个实例，再通过公开 API 写入其中一个最终结果。
func _validate_task_system() -> void:
	var task_asset: TaskAsset = load("res://tests/fixtures/abandoned_hospital.tres") as TaskAsset
	assert(task_asset != null, "TaskSystem 所需 TaskAsset 加载失败")
	var task_system := TaskSystem.new()
	add_child(task_system)

	var first_instance := task_system.create_task_instance(task_asset)
	var second_instance := task_system.create_task_instance(task_asset)
	assert(first_instance != null and second_instance != null, "TaskSystem 创建任务实例失败")
	assert(first_instance.instance_id != second_instance.instance_id, "TaskSystem 生成了重复实例 ID")
	assert(first_instance.task_id == task_asset.id, "第一个 TaskInstance 的任务 ID 不正确")
	assert(second_instance.task_id == task_asset.id, "第二个 TaskInstance 的任务 ID 不正确")
	assert(first_instance.lifecycle_state == &"PUBLISHED", "第一个 TaskInstance 初始状态不正确")
	assert(second_instance.lifecycle_state == &"PUBLISHED", "第二个 TaskInstance 初始状态不正确")
	assert(task_system.get_task_instance(first_instance.instance_id) == first_instance, "TaskSystem 未保存第一个实例")
	assert(task_system.get_task_instance(second_instance.instance_id) == second_instance, "TaskSystem 未保存第二个实例")
	assert(task_system.record_final_result(first_instance.instance_id, &"test_abandoned_hospital_success"), "TaskSystem 记录最终结果失败")
	assert(first_instance.final_result_id == &"test_abandoned_hospital_success", "TaskSystem 最终结果写入不正确")
	assert(second_instance.final_result_id.is_empty(), "TaskSystem 污染了另一个任务实例")
	print("TaskSystem ownership success: first=%s, second=%s, result=%s" % [first_instance.instance_id, second_instance.instance_id, first_instance.final_result_id])
	task_system.queue_free()


# 验证 ACTIVE 派遣阻止角色重复占用，显式结束后同一角色可以再次派遣。
func _validate_dispatch_system() -> void:
	var character: CharacterAsset = load("res://tests/fixtures/character_a.tres") as CharacterAsset
	assert(character != null, "DispatchSystem 所需角色加载失败")
	var party: Array[CharacterAsset] = [character]
	var dispatch_system := DispatchSystem.new()
	add_child(dispatch_system)

	var first_dispatch := dispatch_system.create_dispatch(&"test_task_instance_001", party)
	assert(first_dispatch != null, "DispatchSystem 第一次派遣创建失败")
	assert(first_dispatch.status == &"ACTIVE", "第一次派遣应为 ACTIVE")
	assert(dispatch_system.get_dispatch_instance(first_dispatch.dispatch_instance_id) == first_dispatch, "DispatchSystem 未保存第一次派遣")
	assert(dispatch_system.is_character_occupied(character.id), "ACTIVE 派遣应占用角色")

	var blocked_dispatch := dispatch_system.create_dispatch(&"test_task_instance_002", party)
	assert(blocked_dispatch == null, "同一角色不得同时进入第二个 ACTIVE 派遣")
	assert(dispatch_system.end_dispatch(first_dispatch.dispatch_instance_id), "DispatchSystem 结束第一次派遣失败")
	assert(first_dispatch.status == &"ENDED", "第一次派遣应变为 ENDED")
	assert(not dispatch_system.is_character_occupied(character.id), "ENDED 派遣不应继续占用角色")

	var second_dispatch := dispatch_system.create_dispatch(&"test_task_instance_002", party)
	assert(second_dispatch != null, "角色释放后应允许再次派遣")
	assert(second_dispatch.status == &"ACTIVE", "第二次派遣应为 ACTIVE")
	assert(second_dispatch.dispatch_instance_id != first_dispatch.dispatch_instance_id, "两次派遣必须使用不同实例 ID")
	print("DispatchSystem occupancy success: first=%s, second=%s, released=true" % [first_dispatch.dispatch_instance_id, second_dispatch.dispatch_instance_id])
	dispatch_system.queue_free()


# 验证调查能力分别命中成功与失败，并让无命中、重复命中显式失败。
func _validate_task_resolution_system() -> void:
	var task_asset: TaskAsset = load("res://tests/fixtures/abandoned_hospital.tres") as TaskAsset
	var character: CharacterAsset = load("res://tests/fixtures/character_a.tres") as CharacterAsset
	assert(task_asset != null and character != null, "TaskResolutionSystem 所需 fixture 加载失败")
	var resolution_system := TaskResolutionSystem.new()
	add_child(resolution_system)

	var successful_dispatch := DispatchInstance.new()
	successful_dispatch.character_refs.assign([character])
	var success_result_id := resolution_system.resolve_result(successful_dispatch, task_asset.result_group)
	assert(success_result_id == &"test_abandoned_hospital_success", "调查能力达标时应选择成功结果")

	var low_investigation_character := CharacterAsset.new()
	low_investigation_character.id = &"test_low_investigation_character"
	low_investigation_character.investigation = 9
	var failed_dispatch := DispatchInstance.new()
	failed_dispatch.character_refs.assign([low_investigation_character])
	var failure_result_id := resolution_system.resolve_result(failed_dispatch, task_asset.result_group)
	assert(failure_result_id == &"test_abandoned_hospital_failure", "调查能力不足时应选择失败结果")

	var unreachable_result := ResultAsset.new()
	unreachable_result.id = &"test_unreachable_result"
	var unreachable_condition := AbilityCondition.new()
	unreachable_condition.value = 11
	unreachable_result.conditions.append(unreachable_condition)
	var zero_match_group := ResultGroupAsset.new()
	zero_match_group.id = &"test_zero_match_group"
	zero_match_group.results.append(unreachable_result)
	assert(resolution_system.resolve_result(successful_dispatch, zero_match_group).is_empty(), "零命中必须明确失败")

	var overlap_a := ResultAsset.new()
	overlap_a.id = &"test_overlap_a"
	var overlap_a_condition := AbilityCondition.new()
	overlap_a_condition.value = 0
	overlap_a.conditions.append(overlap_a_condition)
	var overlap_b := ResultAsset.new()
	overlap_b.id = &"test_overlap_b"
	var overlap_b_condition := AbilityCondition.new()
	overlap_b_condition.value = 0
	overlap_b.conditions.append(overlap_b_condition)
	var multiple_match_group := ResultGroupAsset.new()
	multiple_match_group.id = &"test_multiple_match_group"
	multiple_match_group.results.assign([overlap_a, overlap_b])
	assert(resolution_system.resolve_result(successful_dispatch, multiple_match_group).is_empty(), "多命中必须明确失败")

	print("TaskResolutionSystem selection success: success=%s, failure=%s, zero_error=true, multiple_error=true" % [success_result_id, failure_result_id])
	resolution_system.queue_free()
