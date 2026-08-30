class_name ReportView
extends PanelContainer

signal close_requested(report_id: StringName)


var _report_id: StringName = &""
var _content_label: Label
var _close_button: Button


func _ready() -> void:
	# 报告界面只展示已结算事实；关闭按钮只请求修改阅读状态。
	visible = false
	custom_minimum_size = Vector2(0, 260)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	var title := Label.new()
	title.text = "任务报告"
	title.add_theme_font_size_override("font_size", 26)
	content.add_child(title)
	_content_label = Label.new()
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_content_label)
	_close_button = Button.new()
	_close_button.text = "收起报告"
	_close_button.custom_minimum_size = Vector2(0, 44)
	_close_button.pressed.connect(_on_close_pressed)
	content.add_child(_close_button)


func show_report(report: ReportRecord, dispatch_instance: DispatchInstance) -> void:
	if report == null or dispatch_instance == null:
		return
	_report_id = report.report_id
	var character_names: Array[String] = []
	var highest_battle := 0
	var highest_investigation := 0
	var highest_negotiation := 0
	for character in dispatch_instance.character_refs:
		if character == null:
			continue
		character_names.append(character.name)
		highest_battle = maxi(highest_battle, character.battle)
		highest_investigation = maxi(highest_investigation, character.investigation)
		highest_negotiation = maxi(highest_negotiation, character.negotiation)
	_content_label.text = "结果：%s\n队伍：%s\n关键判定依据：战斗 %d｜调查 %d｜交涉 %d\n\n%s" % [
		report.result_asset_id,
		"、".join(character_names),
		highest_battle,
		highest_investigation,
		highest_negotiation,
		report.text,
	]
	visible = true


func get_content_text() -> String:
	return _content_label.text


func get_close_button() -> Button:
	return _close_button


func _on_close_pressed() -> void:
	close_requested.emit(_report_id)
