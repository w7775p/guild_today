class_name ResultInstance
extends RefCounted


# ResultInstance 只记录本次已经确定的结果事实，不修改静态 ResultAsset。
var result_asset_id: StringName
var dispatch_instance_id: StringName
var resolved_effects: Array[EffectResource] = []
