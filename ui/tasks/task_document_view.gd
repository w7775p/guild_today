class_name TaskDocumentView
extends PanelContainer


var _title_label: Label
var _commissioner_label: Label
var _description_label: Label
var _objective_label: Label
var _reward_label: Label
var _duration_label: Label
var _party_label: Label
var _risk_label: Label


func _ready() -> void:
	# 任务文档只展示 TaskAsset 的静态定义和由条件资源推导的能力提示。
	custom_minimum_size = Vector2(0, 250)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)
	_title_label = _add_label(content, "任务文件", 26)
	_commissioner_label = _add_label(content, "", 16)
	_description_label = _add_wrapped_label(content)
	_objective_label = _add_wrapped_label(content)
	_reward_label = _add_label(content, "", 16)
	_duration_label = _add_label(content, "", 16)
	_party_label = _add_label(content, "", 16)
	_risk_label = _add_label(content, "", 16)


func show_task(task_asset: TaskAsset) -> void:
	if task_asset == null:
		visible = false
		return
	_title_label.text = task_asset.title
	_commissioner_label.text = "委托人：%s" % task_asset.commissioner
	_description_label.text = "情况：%s" % task_asset.description
	_objective_label.text = "目标：%s" % task_asset.objective
	_reward_label.text = "承诺报酬：%d 金币" % task_asset.promised_reward
	_duration_label.text = "预计时长：%d 日" % task_asset.duration_days
	_party_label.text = "派遣人数：%d–%d 人" % [task_asset.min_party_size, task_asset.max_party_size]
	_risk_label.text = "影响结果的能力：%s" % _build_ability_hint(task_asset)


func get_display_text() -> String:
	return "\n".join([
		_title_label.text,
		_commissioner_label.text,
		_description_label.text,
		_objective_label.text,
		_reward_label.text,
		_duration_label.text,
		_party_label.text,
		_risk_label.text,
	])


func _build_ability_hint(task_asset: TaskAsset) -> String:
	var ability_ids: Dictionary[StringName, bool] = {}
	if task_asset.result_group != null:
		for result_asset in task_asset.result_group.results:
			if result_asset == null:
				continue
			for condition in result_asset.conditions:
				if condition is AbilityCondition:
					ability_ids[(condition as AbilityCondition).ability_id] = true
				elif condition is AbilityBelowCondition:
					ability_ids[(condition as AbilityBelowCondition).ability_id] = true
	var names: Array[String] = []
	for ability_id in [&"investigation", &"battle", &"negotiation"]:
		if ability_ids.has(ability_id):
			names.append(_ability_name(ability_id))
	return "、".join(names) if not names.is_empty() else "暂无公开提示"


func _ability_name(ability_id: StringName) -> String:
	if ability_id == &"investigation":
		return "调查"
	if ability_id == &"battle":
		return "战斗"
	if ability_id == &"negotiation":
		return "交涉"
	return String(ability_id)


func _add_label(parent: VBoxContainer, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _add_wrapped_label(parent: VBoxContainer) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)
	return label
