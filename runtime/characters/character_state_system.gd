class_name CharacterStateSystem
extends Node

const HIGHEST_BATTLE_MEMBER_RULE: StringName = &"highest_battle_member"

var _states: Dictionary[StringName, CharacterRuntimeState] = {}


# 为角色建立独立运行状态，避免把伤势写入静态角色资产。
func ensure_character(character_id: StringName) -> CharacterRuntimeState:
	if character_id.is_empty():
		push_error("CharacterStateSystem 需要有效角色 ID")
		return null
	if not _states.has(character_id):
		var state := CharacterRuntimeState.new()
		state.character_id = character_id
		_states[character_id] = state
	return _states[character_id]


# 通过稳定角色 ID 读取当前伤势等级。
func get_injury_level(character_id: StringName) -> int:
	var state := _states.get(character_id) as CharacterRuntimeState
	return state.injury_level if state != null else 0


# 事务快照需要区分“未初始化”和“已初始化但伤势为 0”的角色状态。
func has_character_state(character_id: StringName) -> bool:
	return _states.has(character_id)


# 结算事务失败时恢复角色伤势；原先没有状态的角色回到未初始化状态。
func restore_injury(character_id: StringName, previous_level: int, previously_present: bool) -> void:
	if previously_present:
		var state := ensure_character(character_id)
		if state != null:
			state.injury_level = previous_level
	else:
		_states.erase(character_id)


# 伤势只通过角色运行状态系统累加，保留后续可替换空间。
func add_injury(character_id: StringName, severity: int) -> bool:
	if severity <= 0:
		push_error("CharacterStateSystem 伤势等级必须为正数")
		return false
	var state := ensure_character(character_id)
	if state == null:
		return false
	state.injury_level += severity
	return true


# 按当前工作规则选择实际派遣队伍中战斗能力最高的角色。
func apply_injury(dispatch_instance: DispatchInstance, effect: InjuryEffect) -> bool:
	if dispatch_instance == null or effect == null:
		push_error("CharacterStateSystem 缺少派遣实例或伤势效果")
		return false
	if effect.target_rule != HIGHEST_BATTLE_MEMBER_RULE:
		push_error("CharacterStateSystem 未支持的伤势目标规则：%s" % effect.target_rule)
		return false
	var target := get_injury_target(dispatch_instance, effect)
	if target == null:
		return false
	return add_injury(target.id, effect.severity)


# 结算前检查伤势目标是否存在，避免前置效果写入后才发现目标无效。
func get_injury_target(dispatch_instance: DispatchInstance, effect: InjuryEffect) -> CharacterAsset:
	if dispatch_instance == null or effect == null or effect.target_rule != HIGHEST_BATTLE_MEMBER_RULE:
		return null
	var target: CharacterAsset = null
	for character in dispatch_instance.character_refs:
		if character == null or character.id.is_empty():
			push_error("CharacterStateSystem 伤势目标缺少稳定角色 ID")
			return null
		if target == null or character.battle > target.battle:
			target = character
	if target == null:
		push_error("CharacterStateSystem 无法从派遣队伍选择伤势目标")
	return target
