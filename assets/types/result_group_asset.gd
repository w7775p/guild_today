class_name ResultGroupAsset
extends Resource

# 结果组只保存一组静态 ResultAsset 引用，不负责排序、筛选或执行条件。
@export var id: StringName = &""
@export var results: Array[ResultAsset] = []
