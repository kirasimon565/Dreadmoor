extends Node

signal GameTimeAdvanced(new_time_unix: int)

# Base starting point: Sunday, June 12, 2016 00:00:00 (Unix: 1465689600)
var CurrentGameTimeUnix: int = 1465689600

func AdvanceMinutes(minutes: int) -> void:
    CurrentGameTimeUnix += (minutes * 60)
    emit_signal("GameTimeAdvanced", CurrentGameTimeUnix)

func AdvanceSeconds(seconds: int) -> void:
    CurrentGameTimeUnix += seconds
    emit_signal("GameTimeAdvanced", CurrentGameTimeUnix)

func GetCurrentDateTime() -> Dictionary:
    return Time.get_datetime_dict_from_unix_time(CurrentGameTimeUnix)

func GetFormattedTime() -> String:
    var dt = GetCurrentDateTime()
    return "%02d:%02d" % [dt.hour, dt.minute]

func GetFormattedDate() -> String:
    var dt = GetCurrentDateTime()
    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var month_str = months[dt.month - 1]
    return "%s %d, %d" % [month_str, dt.day, dt.year]
