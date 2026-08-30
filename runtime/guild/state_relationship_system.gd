class_name StateRelationshipSystem
extends Node

var _values: Dictionary[StringName, int] = {}


# 关系状态由本系统独占持有，类型化占位 ID 也必须保持语义唯一。
func add_value(relationship_id: StringName, amount: int) -> bool:
	if relationship_id.is_empty():
		push_error("StateRelationshipSystem 需要有效关系状态 ID")
		return false
	_values[relationship_id] = int(_values.get(relationship_id, 0)) + amount
	return true


# 读取关系状态当前值，首次出现的状态从 0 开始。
func get_value(relationship_id: StringName) -> int:
	return int(_values.get(relationship_id, 0))


# 判断关系状态是否已有运行期写入。
func has_value(relationship_id: StringName) -> bool:
	return _values.has(relationship_id)
