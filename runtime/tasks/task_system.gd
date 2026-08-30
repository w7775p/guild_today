class_name TaskSystem
extends Node


# TaskSystem 独占保存并修改本局 TaskInstance，静态 TaskAsset 始终只读。
var _task_instances: Dictionary[StringName, TaskInstance] = {}
var _next_instance_sequence: int = 1


# 从静态任务创建一个已发布实例，并生成系统内唯一的确定性实例 ID。
func create_task_instance(task_asset: TaskAsset) -> TaskInstance:
	if task_asset == null or task_asset.id.is_empty():
		push_error("TaskSystem 创建实例需要有效的 TaskAsset 与稳定 ID")
		return null
	var task_instance := TaskInstance.new()
	task_instance.instance_id = StringName("%s_instance_%d" % [task_asset.id, _next_instance_sequence])
	task_instance.task_id = task_asset.id
	task_instance.lifecycle_state = &"PUBLISHED"
	_next_instance_sequence += 1
	_task_instances[task_instance.instance_id] = task_instance
	return task_instance


# 通过稳定实例 ID 读取由本系统拥有的任务事实。
func get_task_instance(instance_id: StringName) -> TaskInstance:
	return _task_instances.get(instance_id) as TaskInstance


# 最终结果只能经 TaskSystem 写入对应 TaskInstance。
func record_final_result(instance_id: StringName, result_id: StringName) -> bool:
	var task_instance := get_task_instance(instance_id)
	if task_instance == null or result_id.is_empty():
		push_error("TaskSystem 记录最终结果需要有效的任务实例与结果 ID")
		return false
	task_instance.final_result_id = result_id
	return true


# 任务终态只能经 TaskSystem 写入，未确认终态暂以占位 ID 保存。
func record_terminal_state(instance_id: StringName, terminal_state_id: StringName) -> bool:
	var task_instance := get_task_instance(instance_id)
	if task_instance == null or terminal_state_id.is_empty():
		push_error("TaskSystem 记录任务终态需要有效的任务实例与终态 ID")
		return false
	task_instance.lifecycle_state = terminal_state_id
	return true
