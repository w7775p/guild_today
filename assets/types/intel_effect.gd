class_name IntelEffect
extends EffectResource

# 情报效果保存情报与后续解锁引用；类型化占位值避免不同策划缺口共用同一运行键。
@export var intel_id: StringName = &"【intel_pending】"
@export var unlock_task_id: StringName = &"【task_unlock_pending】"
