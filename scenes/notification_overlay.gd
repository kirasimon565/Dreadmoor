extends Control

var _queue = []
var _is_showing = false

func _ready():
    if NotificationManager:
        NotificationManager.connect("notification_requested", _on_show_notification)

    # Assuming the Panel starts hidden off-screen.
    if %Panel:
        %Panel.position.y = -160.0

func _on_show_notification(title: String, message: String, payload: Dictionary):
    _queue.push_back({"title": title, "message": message, "payload": payload})
    if not _is_showing:
        _process_queue()

func _process_queue():
    if _queue.is_empty():
        return

    _is_showing = true
    var notif = _queue.pop_front()

    %TitleLabel.text = notif.title
    %MessageLabel.text = notif.message

    var tween = create_tween()
    tween.tween_property(%Panel, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_interval(3.0)
    tween.tween_property(%Panel, "position:y", -160.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

    tween.finished.connect(_on_notification_done)

func _on_notification_done():
    _is_showing = false
    _process_queue()
