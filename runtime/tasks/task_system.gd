class_name TaskSystem
extends Node


# TaskSystem 独占保存并修改本局 TaskInstance，静态 TaskAsset 始终只读。
const PUBLISHED_STATE: StringName = &"PUBLISHED"
const IN_PROGRESS_STATE: StringName = &"IN_PROGRESS"
var _task_instances: Dictionary[StringName, TaskInstance] = {}
var _task_assets: Dictionary[StringName, TaskAsset] = {}
var _next_instance_sequence: int = 1


# 从静态任务创建一个已发布实例，并生成系统内唯一的确定性实例 ID。
func create_task_instance(task_asset: TaskAsset) -> TaskInstance:
	if task_asset == null or task_asset.id.is_empty():
		push_error("TaskSystem 创建实例需要有效的 TaskAsset 与稳定 ID")
		return null
	var task_instance := TaskInstance.new()
	task_instance.instance_id = StringName("%s_instance_%d" % [task_asset.id, _next_instance_sequence])
	task_instance.task_id = task_asset.id
	task_instance.lifecycle_state = PUBLISHED_STATE
	_next_instance_sequence += 1
	_task_instances[task_instance.instance_id] = task_instance
	_task_assets[task_instance.instance_id] = task_asset
	return task_instance


# 通过稳定实例 ID 读取由本系统拥有的任务事实。
func get_task_instance(instance_id: StringName) -> TaskInstance:
	return _task_instances.get(instance_id) as TaskInstance


# 只有已发布任务可以显式进入进行中，避免 UI 或日期系统直接改生命周期字段。
func start_task_instance(instance_id: StringName) -> bool:
	var task_instance := get_task_instance(instance_id)
	if task_instance == null or task_instance.lifecycle_state != PUBLISHED_STATE:
		return false
	task_instance.lifecycle_state = IN_PROGRESS_STATE
	return true


# 最终结果只能经 TaskSystem 写入对应 TaskInstance。
func record_final_result(instance_id: StringName, result_id: StringName) -> bool:
	var task_instance := get_task_instance(instance_id)
	if task_instance == null or result_id.is_empty():
		push_error("TaskSystem 记录最终结果需要有效的任务实例与结果 ID")
		return false
	if task_instance.lifecycle_state != IN_PROGRESS_STATE:
		push_error("TaskSystem 只能为进行中的任务记录最终结果：%s" % instance_id)
		return false
	var task_asset := _task_assets.get(instance_id) as TaskAsset
	if task_asset == null or task_asset.result_group == null:
		push_error("TaskSystem 无法确认结果属于任务结果组：%s" % instance_id)
		return false
	var result_belongs_to_task := false
	for result_asset in task_asset.result_group.results:
		if result_asset != null and result_asset.id == result_id:
			result_belongs_to_task = true
			break
	if not result_belongs_to_task:
		push_error("TaskSystem 拒绝不属于任务结果组的结果：%s" % result_id)
		return false
	if not task_instance.final_result_id.is_empty():
		push_error("TaskSystem 拒绝覆盖已有最终结果：%s" % instance_id)
		return false
	task_instance.final_result_id = result_id
	return true


# 任务终态只能经 TaskSystem 写入，未确认终态暂以占位 ID 保存。
func record_terminal_state(instance_id: StringName, terminal_state_id: StringName) -> bool:
	var task_instance := get_task_instance(instance_id)
	if task_instance == null or terminal_state_id.is_empty():
		push_error("TaskSystem 记录任务终态需要有效的任务实例与终态 ID")
		return false
	if task_instance.lifecycle_state != IN_PROGRESS_STATE or task_instance.final_result_id.is_empty():
		push_error("TaskSystem 只有已记录结果的进行中任务可以进入终态：%s" % instance_id)
		return false
	task_instance.lifecycle_state = terminal_state_id
	return true


# 结算预检失败时撤销尚未进入终态的最终结果，避免留下半写入任务事实。
func clear_final_result(instance_id: StringName) -> bool:
	var task_instance := get_task_instance(instance_id)
	if task_instance == null or task_instance.lifecycle_state != IN_PROGRESS_STATE:
		return false
	if task_instance.final_result_id.is_empty():
		return true
	task_instance.final_result_id = &""
	return true


# 结算事务失败时恢复任务生命周期与最终结果事实。
func restore_runtime_state(instance_id: StringName, lifecycle_state: StringName, final_result_id: StringName) -> bool:
	var task_instance := get_task_instance(instance_id)
	if task_instance == null or lifecycle_state.is_empty():
		return false
	task_instance.lifecycle_state = lifecycle_state
	task_instance.final_result_id = final_result_id
	return true
