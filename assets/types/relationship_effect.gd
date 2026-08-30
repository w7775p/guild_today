class_name RelationshipEffect
extends EffectResource

# 关系效果只保存关系状态 ID 与确定性变化量，实际写入由状态系统负责。
@export var relationship_id: StringName = &"【relationship_pending】"
@export var amount: int = 0
