class_name StateValue
extends Node


# 状态变化信号只通知已经发生的事实，并携带稳定状态 ID 与前后数值。
signal value_changed(state_id: StringName, previous_value: int, current_value: int)

var _state_id: StringName
var _current_value: int = 0


# GuildState 创建状态时一次性配置稳定 ID 与初始值。
func _setup(new_state_id: StringName, initial_value: int = 0) -> void:
	_state_id = new_state_id
	_current_value = initial_value


# 只读接口避免调用方直接接触内部数值字段。
func _get_current_value() -> int:
	return _current_value


# 恢复值服务未来加载边界，本 Task 不在恢复时发送运行期变化通知。
func _restore_value(restored_value: int) -> void:
	_current_value = restored_value


# 普通设置只在值实际变化时通知事实。
func _set_current_value(new_value: int) -> void:
	if new_value == _current_value:
		return
	var previous_value := _current_value
	_current_value = new_value
	value_changed.emit(_state_id, previous_value, _current_value)


# 增减统一复用设置流程，确保变化通知语义一致。
func _add_value(amount: int) -> void:
	_set_current_value(_current_value + amount)
