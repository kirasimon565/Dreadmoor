extends Control

func _ready():
    %CloseBtn.pressed.connect(_on_close)

func load_media(path: String, is_video: bool = false):
    if is_video:
        %TextureRect.hide()
        %VideoPlayer.show()

        # Determine actual file extension if not hardcoded (e.g., .mp4 vs .ogv)
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
    queue_free()
