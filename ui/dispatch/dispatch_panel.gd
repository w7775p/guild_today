class_name DispatchPanel
extends PanelContainer

signal confirm_requested


var _selection_label: Label
var _validation_label: Label
var _confirm_button: Button


func _ready() -> void:
	# 派遣面板只展示选择与 GameSession 的校验结果，并提交确认请求。
	custom_minimum_size = Vector2(300, 220)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title := Label.new()
	title.text = "派遣准备"
	title.add_theme_font_size_override("font_size", 22)
	content.add_child(title)
	_selection_label = Label.new()
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_selection_label)
	_validation_label = Label.new()
	_validation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_validation_label)
	_confirm_button = Button.new()
	_confirm_button.text = "确认派遣"
	_confirm_button.custom_minimum_size = Vector2(0, 48)
	_confirm_button.pressed.connect(func() -> void: confirm_requested.emit())
	content.add_child(_confirm_button)


func update_selection(character_names: Array[String], validation_message: String) -> void:
	_selection_label.text = "已选角色：%s" % ("、".join(character_names) if not character_names.is_empty() else "无")
	_validation_label.text = "可以派遣" if validation_message.is_empty() else validation_message
	_confirm_button.disabled = not validation_message.is_empty()


func get_confirm_button() -> Button:
	return _confirm_button


func get_validation_text() -> String:
	return _validation_label.text
