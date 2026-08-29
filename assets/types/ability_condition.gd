class_name AbilityCondition
extends ConditionResource

@export var ability_id: StringName = &"investigation"
@export var value: int = 0


# 条件只比较系统传入的指定能力值，能力来源由 TaskResolutionSystem 统一选择。
func is_met(ability_value: int) -> bool:
	return ability_value >= value
