class_name TaskAsset
extends Resource

# 任务资产只保存静态定义，运行时任务事实由后续 Instance 与 System 负责。
@export var id: StringName = &""
@export var title: String = ""
@export_multiline var description: String = ""
@export var commissioner: String = ""
@export_multiline var objective: String = ""
@export var promised_reward: int = 0
@export var duration_days: int = 0
@export var min_party_size: int = 0
@export var max_party_size: int = 0
@export var repeatable: bool = false
@export var result_group: ResultGroupAsset = null
@export var event_reference: Resource = null
