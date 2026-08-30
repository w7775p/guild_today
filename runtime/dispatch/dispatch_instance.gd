class_name DispatchInstance
extends RefCounted


# DispatchInstance 保存一次派遣决定；角色引用只在这里作为运行真源。
var dispatch_instance_id: StringName
var task_instance_id: StringName
var character_refs: Array[CharacterAsset] = []
var status: StringName
var started_day: int = -1
var due_day: int = -1
var ended_day: int = -1
