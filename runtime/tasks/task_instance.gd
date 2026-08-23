class_name TaskInstance
extends RefCounted


# TaskInstance 只保存本局中一次任务实例的运行事实，不改写静态 TaskAsset。
var instance_id: StringName
var task_id: StringName
var lifecycle_state: StringName
var final_result_id: StringName
var runtime_progress: Dictionary = {}
