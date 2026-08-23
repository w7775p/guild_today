extends Node


# 启动主场景时输出最小验证信息，确认项目运行链正常。
func _ready() -> void:
	print("Guild Today Open As Usual boot success")
	_validate_character_asset()
	_validate_task_asset()
	_validate_ability_condition()
	_validate_effect_resources()
	_validate_result_asset()


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
	assert(task.result_group == null, "TaskAsset 不应提前绑定 ResultGroup")
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
