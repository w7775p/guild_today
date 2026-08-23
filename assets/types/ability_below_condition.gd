class_name AbilityBelowCondition
extends ConditionResource

# 只表达调查能力低于阈值，用于与 AbilityCondition 组成互补结果分支。
@export var value: int = 0


func is_met(investigation_value: int) -> bool:
	return investigation_value < value
