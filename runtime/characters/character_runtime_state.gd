class_name CharacterRuntimeState
extends RefCounted

# 角色运行状态只保存本局事实，不向静态 CharacterAsset 回写。
var character_id: StringName
var injury_level: int = 0
