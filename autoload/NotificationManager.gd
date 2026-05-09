extends Node

signal notification_requested(title: String, message: String, payload: Dictionary)

func _ready():
    pass

func show_notification(title: String, message: String, payload: Dictionary = {}):
    emit_signal("notification_requested", title, message, payload)

    if AudioManager:
        AudioManager.play_sfx("res://assets/media/sfx/notification.mp3")
