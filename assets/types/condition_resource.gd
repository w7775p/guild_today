class_name ConditionResource
extends Resource


# 条件基类只声明当前切片需要的判断接口；直接调用基类属于配置错误。
func is_met(_investigation_value: int) -> bool:
	push_error("ConditionResource 必须由具体条件实现判断")
	return false
