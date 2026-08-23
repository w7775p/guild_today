class_name AbilityCondition
extends ConditionResource

# 当前切片只验证调查能力阈值，其他能力与组合逻辑等待真实需求。
@export var value: int = 0


func is_met(investigation_value: int) -> bool:
	return investigation_value >= value
