class_name DispatchSystem
extends Node


# DispatchSystem 独占保存派遣历史，并从 ACTIVE 实例实时推导角色占用。
var _dispatch_instances: Dictionary[StringName, DispatchInstance] = {}
var _next_dispatch_sequence: int = 1


# 只在任务 ID 与全部角色引用合法且空闲时创建 ACTIVE 派遣。
func create_dispatch(task_instance_id: StringName, character_refs: Array[CharacterAsset]) -> DispatchInstance:
	if task_instance_id.is_empty() or not _can_create_dispatch(character_refs):
		return null
	var dispatch_instance := DispatchInstance.new()
	dispatch_instance.dispatch_instance_id = StringName("%s_dispatch_%d" % [task_instance_id, _next_dispatch_sequence])
	dispatch_instance.task_instance_id = task_instance_id
	dispatch_instance.character_refs.assign(character_refs)
	dispatch_instance.status = &"ACTIVE"
	_next_dispatch_sequence += 1
	_dispatch_instances[dispatch_instance.dispatch_instance_id] = dispatch_instance
	return dispatch_instance


# 通过稳定 ID 读取本系统保存的派遣历史。
func get_dispatch_instance(dispatch_instance_id: StringName) -> DispatchInstance:
	return _dispatch_instances.get(dispatch_instance_id) as DispatchInstance


# 显式结束 ACTIVE 派遣，使其角色立即从占用推导中释放。
func end_dispatch(dispatch_instance_id: StringName) -> bool:
	var dispatch_instance := get_dispatch_instance(dispatch_instance_id)
	if dispatch_instance == null or dispatch_instance.status != &"ACTIVE":
		return false
	dispatch_instance.status = &"ENDED"
	return true


# 角色占用只扫描 ACTIVE 派遣，不维护可独立修改的 is_busy 副本。
func is_character_occupied(character_id: StringName) -> bool:
	if character_id.is_empty():
		return false
	for value in _dispatch_instances.values():
		var dispatch_instance := value as DispatchInstance
		if dispatch_instance.status != &"ACTIVE":
			continue
		for character in dispatch_instance.character_refs:
			if character.id == character_id:
				return true
	return false


# 同一批次拒绝重复角色，并拒绝已经参加 ACTIVE 派遣的角色。
func _can_create_dispatch(character_refs: Array[CharacterAsset]) -> bool:
	if character_refs.is_empty():
		return false
	var selected_character_ids: Dictionary[StringName, bool] = {}
	for character in character_refs:
		if character == null or character.id.is_empty():
			return false
		if selected_character_ids.has(character.id) or is_character_occupied(character.id):
			return false
		selected_character_ids[character.id] = true
	return true
