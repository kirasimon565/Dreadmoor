extends Node

func _ready():
    # Hook glitch effect randomly based on scheduler/events
    if GlobalScheduler:
        GlobalScheduler.connect("NodeExecuted", _on_node)

func _on_node(id, type, payload):
    if type == "Glitch" or (payload.has("glitch") and payload.get("glitch")):
        _play_glitch()

func _play_glitch():
    var glitch = $GlitchLayer/GlitchRect
    glitch.visible = true
    glitch.modulate.a = 0.8
    if AudioManager:
        AudioManager.play_sfx("res://assets/media/sfx/phone_ringtone_glitch.mp3") # using glitch segment
    var tween = create_tween()
    tween.tween_property(glitch, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC)
    tween.finished.connect(func(): glitch.visible = false)
