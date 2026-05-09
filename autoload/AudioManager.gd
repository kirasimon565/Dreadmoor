extends Node

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready():
    bgm_player = AudioStreamPlayer.new()
    bgm_player.bus = "Music"
    add_child(bgm_player)

    sfx_player = AudioStreamPlayer.new()
    sfx_player.bus = "SFX"
    add_child(sfx_player)

func play_bgm(stream_path: String, fade_duration: float = 1.0):
    var stream = load(stream_path)
    if not stream:
        push_error("Failed to load BGM: " + stream_path)
        return

    if bgm_player.stream == stream and bgm_player.playing:
        return

    if bgm_player.playing and fade_duration > 0:
        var tween = create_tween()
        tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration / 2.0)
        await tween.finished
        bgm_player.stream = stream
        bgm_player.play()
        tween = create_tween()
        tween.tween_property(bgm_player, "volume_db", 0.0, fade_duration / 2.0)
    else:
        bgm_player.stream = stream
        bgm_player.volume_db = 0.0
        bgm_player.play()

func stop_bgm(fade_duration: float = 1.0):
    if not bgm_player.playing: return

    if fade_duration > 0:
        var tween = create_tween()
        tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration)
        await tween.finished
        bgm_player.stop()
    else:
        bgm_player.stop()

func play_sfx(stream_path: String):
    var stream = load(stream_path)
    if stream:
        var player = AudioStreamPlayer.new()
        player.bus = "SFX"
        player.stream = stream
        add_child(player)
        player.play()
        player.finished.connect(player.queue_free)
    else:
        push_error("Failed to load SFX: " + stream_path)
