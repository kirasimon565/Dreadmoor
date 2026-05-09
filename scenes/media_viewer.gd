extends Control

func _ready():
    %CloseBtn.pressed.connect(_on_close)

func load_media(path: String, is_video: bool = false):
    if is_video:
        %TextureRect.hide()
        %VideoPlayer.show()
        # In a real implementation we would load the .ogv file
        var stream = load(path)
        if stream:
            %VideoPlayer.stream = stream
            %VideoPlayer.play()
    else:
        %VideoPlayer.hide()
        %TextureRect.show()
        var tex = load(path)
        if tex:
            %TextureRect.texture = tex

func _on_close():
    if %VideoPlayer.is_playing():
        %VideoPlayer.stop()
    queue_free() # Assumes this is instantiated as an overlay
