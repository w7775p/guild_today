class_name CharacterAsset
extends Resource

# 角色静态资产只保存稳定定义，运行中的伤势、疲劳和关系等事实由运行时系统负责。
@export var id: StringName = &""
@export var name: String = ""
@export var profession: String = ""
@export var battle: int = 0
@export var investigation: int = 0
@export var negotiation: int = 0
