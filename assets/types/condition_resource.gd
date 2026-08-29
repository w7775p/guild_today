class_name ConditionResource
extends Resource


# 条件基类只声明单项能力判断接口；直接调用基类属于配置错误。
func is_met(_ability_value: int) -> bool:
	push_error("ConditionResource 必须由具体条件实现判断")
	return false
