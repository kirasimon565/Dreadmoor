extends Control

func _ready():
    %CloseBtn.pressed.connect(_on_close)
    modulate.a = 0.0
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)

func load_media(path: String, is_video: bool = false):
    if is_video:
        %TextureRect.hide()
        %VideoPlayer.show()

        var stream = load("res://" + path.replace("assets/", "assets/"))
        if stream:
            %VideoPlayer.stream = stream
            %VideoPlayer.play()
    else:
        %VideoPlayer.hide()
        %TextureRect.show()
        var tex = load("res://" + path.replace("assets/", "assets/"))
        if tex:
            %TextureRect.texture = tex

func _on_close():
    if %VideoPlayer.is_playing():
        %VideoPlayer.stop()

    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
    tween.finished.connect(queue_free)
