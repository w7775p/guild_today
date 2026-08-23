class_name GuildState
extends Node


# DEMO 只冻结金币与总声望两个稳定状态身份。
const GOLD_STATE_ID: StringName = &"gold"
const TOTAL_REPUTATION_STATE_ID: StringName = &"total_reputation"

var _states: Dictionary[StringName, StateValue] = {}


# 两个基础状态随 GuildState 创建，初始值统一为 0。
func _init() -> void:
	_register_state(GOLD_STATE_ID)
	_register_state(TOTAL_REPUTATION_STATE_ID)


# 外部通过稳定 ID 查询状态是否属于当前公会状态集合。
func has_state(state_id: StringName) -> bool:
	return _states.has(state_id)


# 未知状态会明确报错；合法状态只返回 StateValue 持有的当前值。
func get_value(state_id: StringName) -> int:
	var state_value := _get_state(state_id)
	return state_value._get_current_value() if state_value != null else 0


# 恢复入口不模拟普通游戏变化，留给未来 SaveSystem 使用。
func restore_value(state_id: StringName, restored_value: int) -> void:
	var state_value := _get_state(state_id)
	if state_value != null:
		state_value._restore_value(restored_value)


# 设置操作只能经过 GuildState，再转交对应 StateValue。
func set_value(state_id: StringName, new_value: int) -> void:
	var state_value := _get_state(state_id)
	if state_value != null:
		state_value._set_current_value(new_value)


# 增减操作只能经过 GuildState，再转交对应 StateValue。
func add_value(state_id: StringName, amount: int) -> void:
	var state_value := _get_state(state_id)
	if state_value != null:
		state_value._add_value(amount)


# GuildState 独占状态节点的创建与注册。
func _register_state(state_id: StringName) -> void:
	var state_value := StateValue.new()
	state_value.name = String(state_id)
	state_value._setup(state_id)
	add_child(state_value)
	_states[state_id] = state_value


# 所有公开写入都复用同一个未知 ID 错误边界。
func _get_state(state_id: StringName) -> StateValue:
	if not _states.has(state_id):
		push_error("GuildState 未注册状态 ID：%s" % state_id)
		return null
	return _states[state_id]
