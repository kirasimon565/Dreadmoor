using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Dreadmoor
{
    public partial class GlobalScheduler : Node
    {
        public static GlobalScheduler Instance { get; private set; }

        private bool _isPlaying = false;
        private Queue<Dictionary<string, object>> _eventQueue = new Queue<Dictionary<string, object>>();
        private Dictionary<string, Dictionary<string, object>> _currentSceneGraph = new();

        [Signal]
        public delegate void NodeExecutedEventHandler(string nodeId, string nodeType, Godot.Collections.Dictionary payload);

        [Signal]
        public delegate void TypingStatusChangedEventHandler(string threadId, string characterId, bool isTyping);

        [Signal]
        public delegate void PlaybackCompletedEventHandler();

        public override void _EnterTree()
        {
            if (Instance == null)
            {
                Instance = this;
            }
        }

        public void LoadSceneGraph(string episodeId, string sceneFile)
        {
            string path = $"res://episodes/{sceneFile}";
            _currentSceneGraph = JsonRuntimeParser.ParseScene(path);
            GD.Print($"GlobalScheduler: Loaded scene {sceneFile} with {_currentSceneGraph.Count} nodes.");
        }

        public async void StartPlayback(string startNodeId)
        {
            if (_isPlaying) return;

            if (_currentSceneGraph.Count == 0)
            {
                GD.PrintErr("GlobalScheduler: Cannot start playback, no scene graph loaded.");
                return;
            }

            _isPlaying = true;
            GD.Print($"GlobalScheduler: Starting playback at {startNodeId}");

            string currentNodeId = startNodeId;
            while (_isPlaying && !string.IsNullOrEmpty(currentNodeId) && _currentSceneGraph.ContainsKey(currentNodeId))
            {
                var node = _currentSceneGraph[currentNodeId];
                await ExecuteNode(node);

                // Determine next node
                if (node.TryGetValue("next", out var nextObj) && nextObj is string nextId)
                {
                    currentNodeId = nextId;
                }
                else
                {
                    currentNodeId = null; // End of chain
                }
            }

            _isPlaying = false;
            EmitSignal(SignalName.PlaybackCompleted);
            GD.Print("GlobalScheduler: Playback completed.");
        }

        public void StopPlayback()
        {
            _isPlaying = false;
            _eventQueue.Clear();
        }

        public void EnqueueNode(Dictionary<string, object> nodeData)
        {
            _eventQueue.Enqueue(nodeData);
            if (!_isPlaying)
            {
                _isPlaying = true;
                _ = ProcessQueue();
            }
        }

        private async Task ProcessQueue()
        {
            while (_isPlaying && _eventQueue.Count > 0)
            {
                var node = _eventQueue.Dequeue();
                await ExecuteNode(node);
            }

            if (_eventQueue.Count == 0)
            {
                _isPlaying = false;
            }
        }

        private async Task ExecuteNode(Dictionary<string, object> node)
        {
            string type = node.TryGetValue("type", out var typeVal) ? typeVal.ToString() : "Unknown";
            string id = node.TryGetValue("id", out var idVal) ? idVal.ToString() : "unknown_id";

            GD.Print($"GlobalScheduler: Executing node {id} of type {type}");

            // Advance time if specified
            if (node.TryGetValue("time_passed", out var timeVal) && int.TryParse(timeVal.ToString(), out int minutes))
            {
                GameClock.Instance.AdvanceMinutes(minutes);
            }

            switch (type)
            {
                case "Chat_Event":
                    // Simulate typing delay if specified
                    if (node.TryGetValue("typing_delay", out var delayVal) && float.TryParse(delayVal.ToString(), out float delay) && delay > 0)
                    {
                        string sender = node.TryGetValue("sender", out var senderVal) ? senderVal.ToString() : "unknown";
                        string thread = node.TryGetValue("thread", out var threadVal) ? threadVal.ToString() : "unknown";

                        EmitSignal(SignalName.TypingStatusChanged, thread, sender, true);
                        await Task.Delay((int)(delay * 1000));
                        EmitSignal(SignalName.TypingStatusChanged, thread, sender, false);
                    }

                    // Fire execution signal
                    var payload = new Godot.Collections.Dictionary();
                    foreach (var kvp in node)
                    {
                        payload[kvp.Key] = Godot.Variant.CreateFrom(kvp.Value);
                    }
                    EmitSignal(SignalName.NodeExecuted, id, type, payload);
                    break;

                case "Pause":
                case "Delay":
                    if (node.TryGetValue("duration", out var pauseVal) && float.TryParse(pauseVal.ToString(), out float pause))
                    {
                        await Task.Delay((int)(pause * 1000));
                    }
                    break;

                default:
                    // Just emit for unhandled types for now
                    var defaultPayload = new Godot.Collections.Dictionary();
                    foreach (var kvp in node)
                    {
                        defaultPayload[kvp.Key] = Godot.Variant.CreateFrom(kvp.Value);
                    }
                    EmitSignal(SignalName.NodeExecuted, id, type, defaultPayload);
                    break;
            }
        }
    }
}
