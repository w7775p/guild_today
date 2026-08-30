class_name CharacterCardView
extends PanelContainer

signal selection_changed(character_id: StringName, selected: bool)


var _character_id: StringName = &""
var _select_button: CheckButton
var _identity_label: Label
var _abilities_label: Label
var _status_label: Label


func _ready() -> void:
	# 角色卡只展示静态角色与 GameSession 提供的派生状态。
	custom_minimum_size = Vector2(0, 92)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	_select_button = CheckButton.new()
	_select_button.text = "选择"
	_select_button.custom_minimum_size = Vector2(86, 0)
	_select_button.toggled.connect(_on_selection_toggled)
	row.add_child(_select_button)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	_identity_label = Label.new()
	_identity_label.add_theme_font_size_override("font_size", 18)
	details.add_child(_identity_label)
	_abilities_label = Label.new()
	details.add_child(_abilities_label)
	_status_label = Label.new()
	details.add_child(_status_label)


func setup(character: CharacterAsset, occupied: bool, injury_level: int) -> void:
	if character == null:
		return
	_character_id = character.id
	_identity_label.text = "%s｜%s" % [character.name, character.profession]
	_abilities_label.text = "战斗 %d　调查 %d　交涉 %d" % [character.battle, character.investigation, character.negotiation]
	update_runtime_state(occupied, injury_level)


func update_runtime_state(occupied: bool, injury_level: int) -> void:
	_select_button.disabled = occupied
	if occupied:
		_select_button.set_pressed_no_signal(false)
	var occupation_text := "派遣中" if occupied else "可派遣"
	var injury_text := "无伤势" if injury_level <= 0 else "伤势等级 %d" % injury_level
	_status_label.text = "%s｜%s" % [occupation_text, injury_text]


func set_selected(selected: bool) -> void:
	_select_button.set_pressed_no_signal(selected)


func get_select_button() -> CheckButton:
	return _select_button


func get_character_id() -> StringName:
	return _character_id


func _on_selection_toggled(selected: bool) -> void:
	selection_changed.emit(_character_id, selected)
