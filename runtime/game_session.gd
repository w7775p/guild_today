class_name GameSession
extends Node

signal task_changed(task_instance_id: StringName)
signal day_changed(current_day: int)
signal dispatch_changed(dispatch_instance_id: StringName)
signal state_changed
signal report_changed(report_id: StringName)


const FORMAL_TASK_PATH := "res://assets/data/tasks/task_missing_caravan.tres"
const FORMAL_CHARACTER_PATH_PATTERN := "res://assets/data/characters/%s.tres"
const FORMAL_CHARACTER_IDS: Array[StringName] = [
	&"hero_aelius",
	&"hero_rin",
	&"hero_dai",
	&"hero_patrick",
	&"hero_astrid",
	&"hero_viletta",
]


@onready var guild_state: GuildState = $GuildState
@onready var task_system: TaskSystem = $TaskSystem
@onready var dispatch_system: DispatchSystem = $DispatchSystem
@onready var resolution_system: TaskResolutionSystem = $TaskResolutionSystem
@onready var settlement_system: ResultSettlementSystem = $ResultSettlementSystem
@onready var relationship_system: StateRelationshipSystem = $StateRelationshipSystem
@onready var character_state_system: CharacterStateSystem = $CharacterStateSystem
@onready var report_system: ReportIntelSystem = $ReportIntelSystem
@onready var day_system: DaySystem = $DaySystem


var _formal_characters: Dictionary[StringName, CharacterAsset] = {}
var _formal_task: TaskAsset = null
var _task_instance: TaskInstance = null
var _initialized: bool = false


func _ready() -> void:
	# GameSession 只负责装配和调用现有状态拥有者，不保存业务状态副本。
	day_system.day_advanced.connect(_on_day_advanced)
	_initialized = _initialize_formal_content()


# 供正式场景和测试确认首张任务与六名角色已经完成装配。
func is_initialized() -> bool:
	return _initialized


# 返回按正式角色 ID 固定排序的新数组，静态 CharacterAsset 仍保持只读。
func get_formal_characters() -> Array[CharacterAsset]:
	var characters: Array[CharacterAsset] = []
	for character_id in FORMAL_CHARACTER_IDS:
		if _formal_characters.has(character_id):
			characters.append(_formal_characters[character_id])
	return characters


# 当前切片只发布首张正式任务；生命周期事实继续由 TaskSystem 持有。
func get_published_tasks() -> Array[TaskInstance]:
	var tasks: Array[TaskInstance] = []
	if _task_instance != null and _task_instance.lifecycle_state == &"PUBLISHED":
		tasks.append(_task_instance)
	return tasks


func get_task_instance(task_instance_id: StringName) -> TaskInstance:
	return task_system.get_task_instance(task_instance_id)


# 任务展示只读取与 TaskInstance 关联的正式静态资产。
func get_task_asset(task_instance_id: StringName) -> TaskAsset:
	var task_instance := task_system.get_task_instance(task_instance_id)
	if task_instance == null or _formal_task == null or task_instance.task_id != _formal_task.id:
		return null
	return _formal_task


# 返回空字符串表示派遣合法；UI 使用同一检查结果显示明确失败原因。
func validate_dispatch(task_instance_id: StringName, character_ids: Array[StringName]) -> String:
	if not _initialized or _formal_task == null:
		return "游戏会话尚未初始化"
	var task_instance := task_system.get_task_instance(task_instance_id)
	if task_instance == null or task_instance != _task_instance:
		return "任务实例不存在"
	if task_instance.lifecycle_state != &"PUBLISHED":
		return "当前任务已经派遣"
	if character_ids.size() < _formal_task.min_party_size:
		return "至少选择 %d 名角色" % _formal_task.min_party_size
	if character_ids.size() > _formal_task.max_party_size:
		return "最多选择 %d 名角色" % _formal_task.max_party_size
	var selected_ids: Dictionary[StringName, bool] = {}
	for character_id in character_ids:
		if not _formal_characters.has(character_id):
			return "选择中包含未知角色"
		if selected_ids.has(character_id):
			return "同一角色不能重复选择"
		if dispatch_system.is_character_occupied(character_id):
			return "%s 正在执行其他派遣" % _formal_characters[character_id].name
		selected_ids[character_id] = true
	return ""


# 校验正式任务、人数、角色引用和占用后，把派遣命令交给对应 System。
func submit_dispatch(task_instance_id: StringName, character_ids: Array[StringName]) -> DispatchInstance:
	if not validate_dispatch(task_instance_id, character_ids).is_empty():
		return null
	var task_instance := task_system.get_task_instance(task_instance_id)

	var party: Array[CharacterAsset] = []
	for character_id in character_ids:
		party.append(_formal_characters[character_id])

	var dispatch_instance := dispatch_system.create_dispatch(
		task_instance.instance_id,
		party,
		day_system.get_current_day(),
		_formal_task.duration_days
	)
	if dispatch_instance == null:
		return null
	if not task_system.start_task_instance(task_instance.instance_id):
		dispatch_system.end_dispatch(dispatch_instance.dispatch_instance_id, day_system.get_current_day())
		return null
	task_changed.emit(task_instance.instance_id)
	dispatch_changed.emit(dispatch_instance.dispatch_instance_id)
	return dispatch_instance


# 推进日期后只处理已经到期的派遣，日期系统本身仍不执行任务逻辑。
func advance_day() -> int:
	if not _initialized:
		return -1
	var current_day := day_system.advance_day()
	for dispatch_instance in dispatch_system.get_due_dispatches(current_day):
		if not _settle_due_dispatch(dispatch_instance, current_day):
			push_error("GameSession 到期派遣结算失败：%s" % dispatch_instance.dispatch_instance_id)
	return current_day


func get_current_day() -> int:
	return day_system.get_current_day()


func get_active_dispatches() -> Array[DispatchInstance]:
	return dispatch_system.get_active_dispatches()


func get_dispatch_instance(dispatch_instance_id: StringName) -> DispatchInstance:
	return dispatch_system.get_dispatch_instance(dispatch_instance_id)


func is_character_occupied(character_id: StringName) -> bool:
	return dispatch_system.is_character_occupied(character_id)


func get_unread_reports() -> Array[ReportRecord]:
	return report_system.get_unread_reports()


func get_report_for_dispatch(dispatch_instance_id: StringName) -> ReportRecord:
	return report_system.get_report(dispatch_instance_id)


func mark_report_read(report_id: StringName) -> bool:
	if not report_system.mark_report_read(report_id):
		return false
	report_changed.emit(report_id)
	return true


# 状态查询只委托给实际拥有者，供后续 UI 与当前端到端测试读取。
func get_guild_value(state_id: StringName) -> int:
	return guild_state.get_value(state_id)


func get_relationship_value(relationship_id: StringName) -> int:
	return relationship_system.get_value(relationship_id)


func get_character_injury_level(character_id: StringName) -> int:
	return character_state_system.get_injury_level(character_id)


func get_unlocked_task_id(intel_id: StringName) -> StringName:
	return report_system.get_unlocked_task_id(intel_id)


# 首次进入场景时加载正式资产并发布首张 TaskInstance。
func _initialize_formal_content() -> bool:
	_formal_task = load(FORMAL_TASK_PATH) as TaskAsset
	if _formal_task == null or _formal_task.result_group == null:
		push_error("GameSession 无法加载首张正式任务")
		return false
	for character_id in FORMAL_CHARACTER_IDS:
		var character := load(FORMAL_CHARACTER_PATH_PATTERN % character_id) as CharacterAsset
		if character == null or character.id != character_id:
			push_error("GameSession 无法加载正式角色：%s" % character_id)
			return false
		_formal_characters[character_id] = character
	_task_instance = task_system.create_task_instance(_formal_task)
	if _task_instance == null:
		return false
	task_changed.emit(_task_instance.instance_id)
	return true


# 严格按 Resolution → ResultInstance → Task → Settlement → Report → Dispatch 顺序编排。
func _settle_due_dispatch(dispatch_instance: DispatchInstance, current_day: int) -> bool:
	if dispatch_instance == null or _formal_task == null:
		return false
	var task_instance := task_system.get_task_instance(dispatch_instance.task_instance_id)
	if task_instance == null or task_instance != _task_instance:
		return false
	var result_id := resolution_system.resolve_result(dispatch_instance, _formal_task.result_group)
	if result_id.is_empty():
		return false
	var result_asset := _find_result_asset(result_id)
	if result_asset == null:
		return false

	var result_instance := ResultInstance.new()
	result_instance.result_asset_id = result_asset.id
	result_instance.dispatch_instance_id = dispatch_instance.dispatch_instance_id
	result_instance.resolved_effects.assign(result_asset.effects)
	if not report_system.can_record_report(result_instance):
		return false
	if report_system.build_report(result_asset, result_instance).is_empty():
		return false
	if not task_system.record_final_result(task_instance.instance_id, result_id):
		return false
	if not settlement_system.settle_result(
		result_instance,
		guild_state,
		relationship_system,
		character_state_system,
		report_system,
		task_system,
		task_instance,
		dispatch_instance,
		current_day
	):
		return false
	var report := report_system.record_report(result_asset, result_instance)
	if report == null:
		return false
	if not dispatch_system.end_dispatch(dispatch_instance.dispatch_instance_id, current_day):
		return false

	task_changed.emit(task_instance.instance_id)
	state_changed.emit()
	report_changed.emit(report.report_id)
	dispatch_changed.emit(dispatch_instance.dispatch_instance_id)
	return true


func _find_result_asset(result_id: StringName) -> ResultAsset:
	for result_asset in _formal_task.result_group.results:
		if result_asset != null and result_asset.id == result_id:
			return result_asset
	return null


func _on_day_advanced(current_day: int) -> void:
	day_changed.emit(current_day)
