class_name ReportRecord
extends RefCounted

# 报告记录保存一次结果的稳定关联与阅读事实。
var report_id: StringName
var result_asset_id: StringName
var dispatch_instance_id: StringName
var text: String
var is_read: bool = false
