extends Node

signal notification_requested(title: String, message: String, payload: Dictionary)

func _ready():
    pass

func show_notification(title: String, message: String, payload: Dictionary = {}):
    emit_signal("notification_requested", title, message, payload)

    # In a full implementation, we'd also play a sound or trigger haptics
    # if the system allows it.
    if AudioManager:
        # We would play a generic notification sound here, but wait until assets are configured.
        pass
