class_name DaySystem
extends Node

signal day_advanced(current_day: int)


# V3 使用从第 1 日开始递增的整数游戏日，不携带现实日期语义。
var current_day: int = 1


# 推进一天并通知已经发生的日期变化；本系统不直接触发任务或结算。
func advance_day() -> int:
	current_day += 1
	day_advanced.emit(current_day)
	return current_day


# 读取当前游戏日，供 GameSession 和派遣系统查询。
func get_current_day() -> int:
	return current_day
