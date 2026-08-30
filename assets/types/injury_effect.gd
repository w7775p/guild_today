class_name InjuryEffect
extends EffectResource

# 伤势效果保存目标规则与等级，运行时不得改写 CharacterAsset。
@export var target_rule: StringName = &"highest_battle_member"
@export var severity: int = 1
