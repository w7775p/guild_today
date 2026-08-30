class_name TaskOutcomeEffect
extends EffectResource

# 任务终态效果只保存稳定终态 ID，实际生命周期写入由 TaskSystem 负责。
@export var terminal_state_id: StringName = &"【task_outcome_pending】"
