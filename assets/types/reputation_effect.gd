class_name ReputationEffect
extends EffectResource

# 声望效果只保存确定性变化量，实际写入由后续结算系统负责。
@export var amount: int = 0
