extends Control

func _ready():
    # Attempt to connect to NotificationManager
    var nm = get_node_or_null("/root/NotificationManager")
    if nm and nm.has_signal("notification_requested"):
        nm.connect("notification_requested", _on_show_notification)

func _on_show_notification(title: String, message: String, payload: Dictionary):
    %TitleLabel.text = title
    %MessageLabel.text = message

    # Animate in, hold, animate out
    var tween = create_tween()
    tween.tween_property(%Panel, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_interval(3.0)
    tween.tween_property(%Panel, "position:y", -160.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
