extends Node


const GUILD_MAIN_SCENE := preload("res://ui/main/guild_main.tscn")


func _ready() -> void:
	# 专项测试通过正式按钮和选择控件走完一轮完整成功路线。
	var passed := _run_mouse_flow()
	if passed:
		print("V3 Task 6 UI success: signal_flow=true, party_limit=true, report_read=true")
	else:
		push_error("V3 Task 6 UI failed")
	get_tree().quit(0 if passed else 1)


func _run_mouse_flow() -> bool:
	var ui := GUILD_MAIN_SCENE.instantiate() as GuildMain
	if ui == null:
		return false
	add_child(ui)
	var passed := _check(true, ui.get_session().is_initialized(), "正式 GameSession 未初始化")

	ui.get_open_task_button().pressed.emit()
	passed = _check(passed, ui.get_task_view().visible, "任务文件按钮未打开任务文档")
	passed = _check(passed, ui.get_task_view().get_display_text().contains("失踪商队调查"), "任务文档缺少正式任务标题")
	passed = _check(passed, ui.get_task_view().get_display_text().contains("调查、战斗"), "任务文档缺少能力提示")
	passed = _check(passed, ui.get_dispatch_panel().get_validation_text() == "至少选择 1 名角色", "空队伍缺少明确校验原因")
	passed = _check(passed, ui.get_dispatch_panel().get_confirm_button().disabled, "空队伍仍可确认派遣")

	var card := ui.get_character_card(&"hero_viletta")
	var second_card := ui.get_character_card(&"hero_astrid")
	var third_card := ui.get_character_card(&"hero_dai")
	passed = _check(passed, card != null, "维蕾塔角色卡不存在")
	passed = _check(passed, second_card != null and third_card != null, "人数限制测试角色卡不存在")
	if card == null or second_card == null or third_card == null:
		return false
	var select_button := card.get_select_button()
	select_button.set_pressed_no_signal(true)
	select_button.toggled.emit(true)
	passed = _check(passed, ui.get_dispatch_panel().get_validation_text() == "可以派遣", "单人合法派遣未通过界面校验")
	passed = _check(passed, not ui.get_dispatch_panel().get_confirm_button().disabled, "合法派遣确认按钮仍被禁用")
	second_card.get_select_button().set_pressed_no_signal(true)
	second_card.get_select_button().toggled.emit(true)
	passed = _check(passed, ui.get_dispatch_panel().get_validation_text() == "可以派遣", "双人合法派遣未通过界面校验")
	third_card.get_select_button().set_pressed_no_signal(true)
	third_card.get_select_button().toggled.emit(true)
	passed = _check(passed, ui.get_dispatch_panel().get_validation_text() == "最多选择 2 名角色", "三人队伍缺少明确校验原因")
	passed = _check(passed, ui.get_dispatch_panel().get_confirm_button().disabled, "三人队伍仍可确认派遣")
	second_card.get_select_button().set_pressed_no_signal(false)
	second_card.get_select_button().toggled.emit(false)
	third_card.get_select_button().set_pressed_no_signal(false)
	third_card.get_select_button().toggled.emit(false)
	passed = _check(passed, ui.get_dispatch_panel().get_validation_text() == "可以派遣", "恢复单人后派遣校验未更新")
	ui.get_dispatch_panel().get_confirm_button().pressed.emit()

	passed = _check(passed, ui.get_session().get_active_dispatches().size() == 1, "确认后未创建 ACTIVE 派遣")
	passed = _check(passed, ui.get_session().is_character_occupied(&"hero_viletta"), "派遣后角色未显示占用")
	passed = _check(passed, card.get_select_button().disabled, "ACTIVE 角色仍可在界面选择")
	ui.get_advance_day_button().pressed.emit()
	passed = _check(passed, ui.get_session().get_current_day() == 2, "第一次按钮推进后日期错误")
	passed = _check(passed, ui.get_report_button().disabled, "第 2 日提前开放报告")
	ui.get_advance_day_button().pressed.emit()
	passed = _check(passed, ui.get_session().get_current_day() == 3, "第二次按钮推进后日期错误")
	passed = _check(passed, not ui.get_report_button().disabled, "第 3 日未开放报告")
	passed = _check(passed, not ui.get_session().is_character_occupied(&"hero_viletta"), "结算后角色仍被占用")

	ui.get_report_button().pressed.emit()
	passed = _check(passed, ui.get_report_view().visible, "报告按钮未打开报告")
	passed = _check(passed, ui.get_report_view().get_content_text().contains("result_missing_caravan_full_success"), "报告缺少结果事实")
	passed = _check(passed, ui.get_report_view().get_content_text().contains("关键判定依据"), "报告缺少判定依据")
	passed = _check(passed, ui.get_report_view().get_content_text().contains("获得金币90"), "报告缺少持续后果")
	ui.get_report_view().get_close_button().pressed.emit()
	passed = _check(passed, not ui.get_report_view().visible, "关闭报告后界面仍可见")
	passed = _check(passed, ui.get_session().get_unread_reports().is_empty(), "关闭报告未改变阅读状态")
	passed = _check(passed, ui.get_session().get_guild_value(GuildState.GOLD_STATE_ID) == 90, "报告关闭后金币状态错误")
	ui.queue_free()
	return passed


func _check(current: bool, condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return current and condition
