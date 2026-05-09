extends CanvasLayer

func _ready():
    $Control/ToggleBtn.pressed.connect(_on_toggle)
    %ForceCallBtn.pressed.connect(_on_force_call)
    %ForceNotiBtn.pressed.connect(_on_force_noti)
    %SecretChatBtn.pressed.connect(_on_secret_chat)

func _on_toggle():
    %Panel.visible = !%Panel.visible

func _on_force_call():
    var sm = SceneManager
    if sm:
        sm.change_scene("res://scenes/incoming_call_screen.tscn")
        %Panel.visible = false

func _on_force_noti():
    var nm = NotificationManager
    if nm:
        nm.show_notification("DEBUG", "This is a forced notification payload.")

func _on_secret_chat():
    var sm = SceneManager
    if sm:
        sm.change_scene("res://scenes/secret_chat_screen.tscn")
        %Panel.visible = false
