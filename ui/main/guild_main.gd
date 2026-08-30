class_name GuildMain
extends Control


const TASK_VIEW_SCENE := preload("res://ui/tasks/task_document_view.tscn")
const CHARACTER_CARD_SCENE := preload("res://ui/characters/character_card_view.tscn")
const DISPATCH_PANEL_SCENE := preload("res://ui/dispatch/dispatch_panel.tscn")
const REPORT_VIEW_SCENE := preload("res://ui/reports/report_view.tscn")


@onready var _session: GameSession = $GameSession


var _task_instance_id: StringName = &""
var _selected_character_ids: Array[StringName] = []
var _character_cards: Dictionary[StringName, CharacterCardView] = {}
var _task_view: TaskDocumentView
var _dispatch_panel: DispatchPanel
var _report_view: ReportView
var _character_list: VBoxContainer
var _workspace: HSplitContainer
var _day_label: Label
var _gold_label: Label
var _reputation_label: Label
var _active_label: Label
var _open_task_button: Button
var _advance_day_button: Button
var _report_button: Button


func _ready() -> void:
	# 主界面只读取 GameSession 并提交命令，不直接修改任何业务状态。
	_build_interface()
	_connect_session_notifications()
	_initialize_content()
	_refresh_ui()


func get_session() -> GameSession:
	return _session


func get_task_view() -> TaskDocumentView:
	return _task_view


func get_character_card(character_id: StringName) -> CharacterCardView:
	return _character_cards.get(character_id) as CharacterCardView


func get_dispatch_panel() -> DispatchPanel:
	return _dispatch_panel


func get_report_view() -> ReportView:
	return _report_view


func get_open_task_button() -> Button:
	return _open_task_button


func get_advance_day_button() -> Button:
	return _advance_day_button


func get_report_button() -> Button:
	return _report_button


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("1b2230")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)

	var heading := Label.new()
	heading.text = "今日公会照常营业"
	heading.add_theme_font_size_override("font_size", 32)
	page.add_child(heading)

	var status_bar := HBoxContainer.new()
	status_bar.add_theme_constant_override("separation", 14)
	page.add_child(status_bar)
	_day_label = _add_status_label(status_bar)
	_gold_label = _add_status_label(status_bar)
	_reputation_label = _add_status_label(status_bar)
	_active_label = _add_status_label(status_bar)
	var status_spacer := Control.new()
	status_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_bar.add_child(status_spacer)
	_open_task_button = Button.new()
	_open_task_button.text = "打开任务文件"
	_open_task_button.pressed.connect(_on_open_task_pressed)
	status_bar.add_child(_open_task_button)
	_advance_day_button = Button.new()
	_advance_day_button.text = "推进一天"
	_advance_day_button.pressed.connect(_on_advance_day_pressed)
	status_bar.add_child(_advance_day_button)
	_report_button = Button.new()
	_report_button.text = "报告（0）"
	_report_button.pressed.connect(_on_report_pressed)
	status_bar.add_child(_report_button)

	_task_view = TASK_VIEW_SCENE.instantiate() as TaskDocumentView
	_task_view.visible = false
	page.add_child(_task_view)

	_workspace = HSplitContainer.new()
	_workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_workspace.split_offset = 640
	page.add_child(_workspace)
	var character_scroll := ScrollContainer.new()
	character_scroll.custom_minimum_size = Vector2(600, 300)
	character_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_workspace.add_child(character_scroll)
	_character_list = VBoxContainer.new()
	_character_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_character_list.add_theme_constant_override("separation", 8)
	character_scroll.add_child(_character_list)
	_dispatch_panel = DISPATCH_PANEL_SCENE.instantiate() as DispatchPanel
	_dispatch_panel.confirm_requested.connect(_on_confirm_dispatch)
	_workspace.add_child(_dispatch_panel)

	_report_view = REPORT_VIEW_SCENE.instantiate() as ReportView
	_report_view.close_requested.connect(_on_close_report)
	page.add_child(_report_view)


func _connect_session_notifications() -> void:
	_session.task_changed.connect(func(_task_id: StringName) -> void: _refresh_ui())
	_session.day_changed.connect(func(_day: int) -> void: _refresh_ui())
	_session.dispatch_changed.connect(func(_dispatch_id: StringName) -> void: _refresh_ui())
	_session.state_changed.connect(func() -> void: _refresh_ui())
	_session.report_changed.connect(func(_report_id: StringName) -> void: _refresh_ui())


func _initialize_content() -> void:
	var published_tasks := _session.get_published_tasks()
	if published_tasks.size() == 1:
		_task_instance_id = published_tasks[0].instance_id
		_task_view.show_task(_session.get_task_asset(_task_instance_id))
	for character in _session.get_formal_characters():
		var card := CHARACTER_CARD_SCENE.instantiate() as CharacterCardView
		_character_list.add_child(card)
		card.setup(character, _session.is_character_occupied(character.id), _session.get_character_injury_level(character.id))
		card.selection_changed.connect(_on_character_selection_changed)
		_character_cards[character.id] = card


func _refresh_ui() -> void:
	_day_label.text = "第 %d 日" % _session.get_current_day()
	_gold_label.text = "金币 %d" % _session.get_guild_value(GuildState.GOLD_STATE_ID)
	_reputation_label.text = "总声望 %d" % _session.get_guild_value(GuildState.TOTAL_REPUTATION_STATE_ID)
	var active_dispatches := _session.get_active_dispatches()
	_active_label.text = "进行中派遣 %d" % active_dispatches.size()
	_advance_day_button.disabled = active_dispatches.is_empty()
	var unread_reports := _session.get_unread_reports()
	_report_button.text = "报告（%d）" % unread_reports.size()
	_report_button.disabled = unread_reports.is_empty()
	for character in _session.get_formal_characters():
		var card := get_character_card(character.id)
		if card != null:
			card.update_runtime_state(_session.is_character_occupied(character.id), _session.get_character_injury_level(character.id))
	_refresh_dispatch_panel()


func _refresh_dispatch_panel() -> void:
	var character_names: Array[String] = []
	for character_id in _selected_character_ids:
		var character := _get_character(character_id)
		if character != null:
			character_names.append(character.name)
	var validation_message := _session.validate_dispatch(_task_instance_id, _selected_character_ids)
	_dispatch_panel.update_selection(character_names, validation_message)


func _on_open_task_pressed() -> void:
	_task_view.visible = not _task_view.visible
	_open_task_button.text = "收起任务文件" if _task_view.visible else "打开任务文件"


func _on_character_selection_changed(character_id: StringName, selected: bool) -> void:
	if selected and not _selected_character_ids.has(character_id):
		_selected_character_ids.append(character_id)
	elif not selected:
		_selected_character_ids.erase(character_id)
	_refresh_dispatch_panel()


func _on_confirm_dispatch() -> void:
	var dispatch_instance := _session.submit_dispatch(_task_instance_id, _selected_character_ids)
	if dispatch_instance == null:
		_refresh_dispatch_panel()
		return
	_selected_character_ids.clear()
	for card in _character_cards.values():
		(card as CharacterCardView).set_selected(false)
	_refresh_ui()


func _on_advance_day_pressed() -> void:
	_session.advance_day()


func _on_report_pressed() -> void:
	var unread_reports := _session.get_unread_reports()
	if unread_reports.is_empty():
		return
	var report := unread_reports[0]
	var dispatch_instance := _session.get_dispatch_instance(report.dispatch_instance_id)
	_task_view.visible = false
	_workspace.visible = false
	_open_task_button.disabled = true
	_report_view.show_report(report, dispatch_instance)


func _on_close_report(report_id: StringName) -> void:
	if _session.mark_report_read(report_id):
		_report_view.visible = false
		_workspace.visible = true
		_open_task_button.disabled = false
		_open_task_button.text = "打开任务文件"
		_refresh_ui()


func _get_character(character_id: StringName) -> CharacterAsset:
	for character in _session.get_formal_characters():
		if character.id == character_id:
			return character
	return null


func _add_status_label(parent: HBoxContainer) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)
	return label
