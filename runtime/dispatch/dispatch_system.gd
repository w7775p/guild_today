class_name DispatchSystem
extends Node


# DispatchSystem 独占保存派遣历史，并从 ACTIVE 实例实时推导角色占用。
var _dispatch_instances: Dictionary[StringName, DispatchInstance] = {}
var _next_dispatch_sequence: int = 1


# 只在任务 ID、角色引用和可选日期事实合法且角色空闲时创建 ACTIVE 派遣。
func create_dispatch(
	task_instance_id: StringName,
	character_refs: Array[CharacterAsset],
	started_day: int = -1,
	duration_days: int = -1
) -> DispatchInstance:
	if task_instance_id.is_empty() or not _is_timing_valid(started_day, duration_days) or not _can_create_dispatch(character_refs):
		return null
	var dispatch_instance := DispatchInstance.new()
	dispatch_instance.dispatch_instance_id = StringName("%s_dispatch_%d" % [task_instance_id, _next_dispatch_sequence])
	dispatch_instance.task_instance_id = task_instance_id
	dispatch_instance.character_refs.assign(character_refs)
	dispatch_instance.status = &"ACTIVE"
	if started_day >= 1:
		dispatch_instance.started_day = started_day
		dispatch_instance.due_day = started_day + duration_days
	_next_dispatch_sequence += 1
	_dispatch_instances[dispatch_instance.dispatch_instance_id] = dispatch_instance
	return dispatch_instance


# 通过稳定 ID 读取本系统保存的派遣历史。
func get_dispatch_instance(dispatch_instance_id: StringName) -> DispatchInstance:
	return _dispatch_instances.get(dispatch_instance_id) as DispatchInstance


# 显式结束 ACTIVE 派遣，使其角色立即从占用推导中释放；定时派遣只能在到期日结束。
func end_dispatch(dispatch_instance_id: StringName, ended_day: int = -1) -> bool:
	var dispatch_instance := get_dispatch_instance(dispatch_instance_id)
	if not _can_end_dispatch(dispatch_instance, ended_day):
		return false
	if ended_day >= 1:
		dispatch_instance.ended_day = ended_day
	dispatch_instance.status = &"ENDED"
	return true


# 派遣创建后的任务启动失败只走回滚入口，避免把“提前结束”混入正式完成语义。
func cancel_dispatch(dispatch_instance_id: StringName) -> bool:
	var dispatch_instance := get_dispatch_instance(dispatch_instance_id)
	if dispatch_instance == null or dispatch_instance.status != &"ACTIVE":
		return false
	dispatch_instance.status = &"CANCELLED"
	if dispatch_instance.started_day >= 1:
		dispatch_instance.ended_day = dispatch_instance.started_day
	return true


# 结算事务最后一步失败时恢复仍处于已结束状态的派遣。
func restore_active_dispatch(dispatch_instance_id: StringName, previous_ended_day: int = -1) -> bool:
	var dispatch_instance := get_dispatch_instance(dispatch_instance_id)
	if dispatch_instance == null or dispatch_instance.status != &"ENDED":
		return false
	dispatch_instance.status = &"ACTIVE"
	dispatch_instance.ended_day = previous_ended_day
	return true


# GameSession 在执行结算写入前使用同一规则预检结束操作，避免最后一步失败。
func can_end_dispatch(dispatch_instance_id: StringName, ended_day: int = -1) -> bool:
	return _can_end_dispatch(get_dispatch_instance(dispatch_instance_id), ended_day)


# 只有仍在 ACTIVE 且达到 due_day 的派遣才允许进入结算链。
func is_dispatch_due(dispatch_instance_id: StringName, current_day: int) -> bool:
	var dispatch_instance := get_dispatch_instance(dispatch_instance_id)
	return dispatch_instance != null \
		and dispatch_instance.status == &"ACTIVE" \
		and dispatch_instance.due_day >= 1 \
		and current_day >= dispatch_instance.due_day


# 返回当前日已经到期的 ACTIVE 派遣，日期系统不直接修改这些实例。
func get_due_dispatches(current_day: int) -> Array[DispatchInstance]:
	var due_dispatches: Array[DispatchInstance] = []
	for value in _dispatch_instances.values():
		var dispatch_instance := value as DispatchInstance
		if dispatch_instance == null:
			continue
		if is_dispatch_due(dispatch_instance.dispatch_instance_id, current_day):
			due_dispatches.append(dispatch_instance)
	return due_dispatches


# ACTIVE 派遣由本系统现有实例即时筛选，GameSession 不保存第二份占用清单。
func get_active_dispatches() -> Array[DispatchInstance]:
	var active_dispatches: Array[DispatchInstance] = []
	for value in _dispatch_instances.values():
		var dispatch_instance := value as DispatchInstance
		if dispatch_instance == null:
			continue
		if dispatch_instance.status == &"ACTIVE":
			active_dispatches.append(dispatch_instance)
	return active_dispatches


# 角色占用只扫描 ACTIVE 派遣，不维护可独立修改的 is_busy 副本。
func is_character_occupied(character_id: StringName) -> bool:
	if character_id.is_empty():
		return false
	for value in _dispatch_instances.values():
		var dispatch_instance := value as DispatchInstance
		if dispatch_instance == null:
			continue
		if dispatch_instance.status != &"ACTIVE":
			continue
		for character in dispatch_instance.character_refs:
			if character != null and character.id == character_id:
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


# 保留 V2 无日期派遣兼容路径；Task 4 的正式派遣必须同时提供开始日与持续天数。
func _is_timing_valid(started_day: int, duration_days: int) -> bool:
	var has_timing := started_day >= 1 or duration_days >= 1
	if not has_timing:
		return started_day == -1 and duration_days == -1
	return started_day >= 1 and duration_days >= 1


# 定时派遣没有“提前放弃”状态，防止结束后永远失去结算入口；无日期派遣保留 V2 兼容路径。
func _can_end_dispatch(dispatch_instance: DispatchInstance, ended_day: int) -> bool:
	if dispatch_instance == null or dispatch_instance.status != &"ACTIVE":
		return false
	if dispatch_instance.started_day < 1:
		return ended_day == -1 or ended_day >= 1
	if ended_day < 1:
		return false
	if ended_day < dispatch_instance.started_day or ended_day < dispatch_instance.due_day:
		return false
	return true
