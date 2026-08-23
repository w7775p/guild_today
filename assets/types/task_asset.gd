class_name TaskAsset
extends Resource

# 任务资产只保存静态定义，运行时任务事实由后续 Instance 与 System 负责。
@export var id: StringName = &""
@export var title: String = ""
@export_multiline var description: String = ""
@export var repeatable: bool = false
@export var result_group: Resource = null
@export var event_reference: Resource = null
