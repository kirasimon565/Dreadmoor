extends Node

signal NodeExecuted(nodeId: String, nodeType: String, payload: Dictionary)
signal TypingStatusChanged(threadId: String, characterId: String, isTyping: bool)
signal PlaybackCompleted()

var _isPlaying: bool = false
var _eventQueue: Array = []
var _currentSceneGraph: Dictionary = {}

func LoadSceneGraph(episodeId: String, sceneFile: String) -> void:
    var path = "res://episodes/" + sceneFile
    if JsonRuntimeParser:
        _currentSceneGraph = JsonRuntimeParser.ParseScene(path)
        print("GlobalScheduler: Loaded scene %s with %d nodes." % [sceneFile, _currentSceneGraph.size()])
    else:
        push_error("GlobalScheduler: JsonRuntimeParser not found.")

func StartPlayback(startNodeId: String) -> void:
    if _isPlaying: return

    if _currentSceneGraph.size() == 0:
        push_error("GlobalScheduler: Cannot start playback, no scene graph loaded.")
        return

    _isPlaying = true
    print("GlobalScheduler: Starting playback at ", startNodeId)

    var currentNodeId: String = startNodeId
    while _isPlaying and not currentNodeId.is_empty() and _currentSceneGraph.has(currentNodeId):
        var node = _currentSceneGraph[currentNodeId]
        await ExecuteNode(node)

        # Determine next node
        if node.has("next") and typeof(node["next"]) == TYPE_STRING:
            currentNodeId = node["next"]
        else:
            currentNodeId = "" # End of chain

    _isPlaying = false
    emit_signal("PlaybackCompleted")
    print("GlobalScheduler: Playback completed.")

func StopPlayback() -> void:
    _isPlaying = false
    _eventQueue.clear()

func EnqueueNode(nodeData: Dictionary) -> void:
    _eventQueue.push_back(nodeData)
    if not _isPlaying:
        _isPlaying = true
        ProcessQueue()

func ProcessQueue() -> void:
    while _isPlaying and _eventQueue.size() > 0:
        var node = _eventQueue.pop_front()
        await ExecuteNode(node)

    if _eventQueue.size() == 0:
        _isPlaying = false

func ExecuteNode(node: Dictionary) -> void:
    var type = node.get("type", "Unknown")
    var id = node.get("id", "unknown_id")

    print("GlobalScheduler: Executing node %s of type %s" % [id, type])

    # Advance time if specified
    if node.has("time_passed"):
        var timeVal = str(node["time_passed"])
        if timeVal.is_valid_int():
            if GameClock:
                GameClock.AdvanceMinutes(timeVal.to_int())

    match type:
        "Chat_Event":
            # Simulate typing delay if specified
            if node.has("typing_delay"):
                var delayVal = str(node["typing_delay"])
                if delayVal.is_valid_float():
                    var delay = delayVal.to_float()
                    if delay > 0:
                        var sender = str(node.get("sender", "unknown"))
                        var thread = str(node.get("thread", "unknown"))

                        emit_signal("TypingStatusChanged", thread, sender, true)
                        await get_tree().create_timer(delay).timeout
                        emit_signal("TypingStatusChanged", thread, sender, false)

            # Fire execution signal
            emit_signal("NodeExecuted", id, type, node.duplicate(true))

        "Pause", "Delay":
            if node.has("duration"):
                var pauseVal = str(node["duration"])
                if pauseVal.is_valid_float():
                    var pause_duration = pauseVal.to_float()
                    await get_tree().create_timer(pause_duration).timeout

        _:
            # Just emit for unhandled types for now
            emit_signal("NodeExecuted", id, type, node.duplicate(true))
