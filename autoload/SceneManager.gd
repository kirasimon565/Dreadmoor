extends Node

signal scene_changed(new_scene_name)
signal transition_started
signal transition_finished

@onready var main_node = get_tree().root.get_node_or_null("Main")
var current_scene_node: Node = null

var transition_layer: CanvasLayer
var color_rect: ColorRect
var tween: Tween

func _ready():
    # Setup transition overlay
    transition_layer = CanvasLayer.new()
    transition_layer.layer = 150 # On top of everything
    add_child(transition_layer)

    color_rect = ColorRect.new()
    color_rect.color = Color(0, 0, 0, 0)
    color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    transition_layer.add_child(color_rect)

    # Load initial scene if Main exists
    if main_node and main_node.has_node("SceneContainer"):
        call_deferred("change_scene", "res://scenes/studio_intro.tscn", false)

func change_scene(scene_path: String, use_transition: bool = true, duration: float = 0.5):
    if not main_node:
        main_node = get_tree().root.get_node_or_null("Main")
        if not main_node:
            push_error("Main scene not found!")
            return

    var container = main_node.get_node("SceneContainer")

    if use_transition:
        emit_signal("transition_started")
        color_rect.mouse_filter = Control.MOUSE_FILTER_STOP # Block input

        if tween:
            tween.kill()
        tween = create_tween()
        tween.tween_property(color_rect, "color:a", 1.0, duration)
        await tween.finished

        _perform_scene_swap(scene_path, container)

        tween = create_tween()
        tween.tween_property(color_rect, "color:a", 0.0, duration)
        await tween.finished
        color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        emit_signal("transition_finished")
    else:
        _perform_scene_swap(scene_path, container)

func _perform_scene_swap(scene_path: String, container: Node):
    if current_scene_node:
        current_scene_node.queue_free()

    var new_scene_resource = load(scene_path)
    if new_scene_resource:
        current_scene_node = new_scene_resource.instantiate()
        container.add_child(current_scene_node)
        emit_signal("scene_changed", scene_path.get_file().get_basename())
    else:
        push_error("Failed to load scene: " + scene_path)
