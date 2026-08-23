class_name ResultAsset
extends Resource

# 单个结果资产只组合静态条件、静态效果与首轮报告文本，不负责判断或结算。
@export var id: StringName = &""
@export var conditions: Array[ConditionResource] = []
@export var effects: Array[EffectResource] = []
@export_multiline var report_text: String = ""
