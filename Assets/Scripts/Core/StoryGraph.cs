using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace Dreadmoor.Core
{
    public sealed class StoryGraph
    {
        public static readonly string[] EpisodeOneResources =
        {
            "assets/story/ep01/scene_01",
            "assets/story/ep01/scene_02",
            "assets/story/ep01/scene_03",
            "assets/story/ep01/scene_04",
            "assets/story/ep01/scene_05",
            "assets/story/ep01/scene_06"
        };

        public static readonly HashSet<string> SupportedTypes = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "Chat_Event", "Video_Message", "Image_Message", "Pause", "Player_Choice",
            "System_Event", "System_Notification", "News_Module", "IncomingCall",
            "Phone_Call_Event", "Secret_Hacked", "Glitch_Effect", "Accept_Call",
            // Episode-one compatibility aliases:
            "Private_Unknown", "Video_Node", "S4_VIDEO_NODE", "Force_Ringing",
            "S6_Ringing_Final", "S6_Accept_Call", "S5_CONNECTION_GLITCH"
        };

        public static readonly HashSet<string> SupportedSystemActions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "", "Push_Notification", "Switch_Context", "Add_To_Group", "Trigger_Credits",
            "Open_Diary_Lock", "Launch_Minigame"
        };

        private readonly Dictionary<string, StoryNode> _nodes;
        public IReadOnlyDictionary<string, StoryNode> Nodes => _nodes;
        public IReadOnlyList<StoryNode> OrderedNodes { get; }

        private StoryGraph(List<StoryNode> nodes)
        {
            OrderedNodes = nodes;
            _nodes = nodes.ToDictionary(node => node.id, node => node, StringComparer.OrdinalIgnoreCase);
        }

        public StoryNode Get(string nodeId)
        {
            if (string.IsNullOrWhiteSpace(nodeId)) return null;
            _nodes.TryGetValue(nodeId, out var node);
            return node;
        }

        public static StoryGraph LoadEpisodeOne()
        {
            var jsonFiles = new List<string>();
            foreach (var resourcePath in EpisodeOneResources)
            {
                var asset = Resources.Load<TextAsset>(resourcePath);
                if (asset == null)
                    throw new InvalidOperationException($"Required story resource is missing: {resourcePath}.json");
                jsonFiles.Add(asset.text);
            }
            return Parse(jsonFiles);
        }

        public static StoryGraph Parse(IEnumerable<string> jsonFiles)
        {
            var nodes = new List<StoryNode>();
            foreach (var json in jsonFiles)
            {
                if (string.IsNullOrWhiteSpace(json)) continue;
                var file = JsonUtility.FromJson<StoryFile>(json);
                if (file?.scenes == null)
                    throw new InvalidOperationException("Story JSON did not contain a 'scenes' array.");
                nodes.AddRange(file.scenes);
            }
            return new StoryGraph(nodes);
        }

        public GraphValidationResult Validate(string entryNodeId = GameStore.StartNodeId)
        {
            var result = new GraphValidationResult();
            var ids = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (var node in OrderedNodes)
            {
                if (node == null)
                {
                    result.Errors.Add("A story file contains a null node.");
                    continue;
                }
                if (string.IsNullOrWhiteSpace(node.id))
                {
                    result.Errors.Add("A story node has no id.");
                    continue;
                }
                if (!ids.Add(node.id)) result.Errors.Add($"Duplicate story node id: {node.id}");
                if (!SupportedTypes.Contains(node.type)) result.Errors.Add($"{node.id}: unsupported type '{node.type}'.");
                if ((node.type == "System_Event" || node.type == "System_Notification") && !SupportedSystemActions.Contains(node.action))
                    result.Errors.Add($"{node.id}: unsupported system action '{node.action}'.");
                if (node.type == "Player_Choice")
                {
                    if (node.options == null || node.options.Length == 0)
                        result.Errors.Add($"{node.id}: a Player_Choice requires at least one option.");
                    else
                    {
                        for (var i = 0; i < node.options.Length; i++)
                        {
                            if (string.IsNullOrWhiteSpace(node.options[i]?.text))
                                result.Errors.Add($"{node.id}: option {i} has no text.");
                            if (string.IsNullOrWhiteSpace(node.options[i]?.Target))
                                result.Errors.Add($"{node.id}: option {i} has no next target.");
                        }
                    }
                }
                if (node.type == "IncomingCall" && node.next_on_decline != null && string.IsNullOrWhiteSpace(node.next_on_decline.target))
                    result.Warnings.Add($"{node.id}: next_on_decline target is empty.");
                if (node.type == "System_Event" && node.action == "Open_Diary_Lock")
                {
                    if (node.meta == null || string.IsNullOrWhiteSpace(node.meta.word) || string.IsNullOrWhiteSpace(node.meta.pageId))
                        result.Errors.Add($"{node.id}: Open_Diary_Lock requires meta.word and meta.pageId.");
                }
            }

            foreach (var node in OrderedNodes.Where(node => node != null && !string.IsNullOrWhiteSpace(node.id)))
            {
                ValidateTarget(result, node.id, "next", node.next, ids, false);
                if (node.options != null)
                {
                    for (var i = 0; i < node.options.Length; i++)
                        ValidateTarget(result, node.id, $"options[{i}]", node.options[i]?.Target, ids, true);
                }
                if (node.next_on_decline != null)
                {
                    if (string.IsNullOrWhiteSpace(node.next_on_decline.target))
                        result.Warnings.Add($"{node.id}: next_on_decline target is empty.");
                    else
                        ValidateTarget(result, node.id, "next_on_decline", node.next_on_decline.target, ids, false);
                }
            }

            if (!ids.Contains(entryNodeId))
            {
                result.Errors.Add($"Entry node '{entryNodeId}' does not exist.");
                return result;
            }

            var reachable = ReachableFrom(entryNodeId);
            foreach (var id in ids.Where(id => !reachable.Contains(id)).OrderBy(id => id))
                result.Errors.Add($"Unreachable story node: {id}");

            var terminals = OrderedNodes.Where(node => node != null &&
                string.Equals(node.action, "Trigger_Credits", StringComparison.OrdinalIgnoreCase)).Select(node => node.id).ToArray();
            if (terminals.Length == 0)
            {
                result.Errors.Add("The story has no Trigger_Credits terminal node.");
            }
            else
            {
                var canFinish = NodesThatCanReach(terminals);
                foreach (var id in reachable.Where(id => !canFinish.Contains(id)).OrderBy(id => id))
                    result.Errors.Add($"Story node cannot reach an ending: {id}");
            }

            DetectImmediateCycles(entryNodeId, result);
            return result;
        }

        public HashSet<string> ReachableFrom(string entryNodeId)
        {
            var found = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var pending = new Stack<string>();
            pending.Push(entryNodeId);
            while (pending.Count > 0)
            {
                var id = pending.Pop();
                if (!found.Add(id)) continue;
                var node = Get(id);
                if (node == null) continue;
                foreach (var target in Targets(node))
                    if (!string.IsNullOrWhiteSpace(target)) pending.Push(target);
            }
            return found;
        }

        private HashSet<string> NodesThatCanReach(IEnumerable<string> terminalIds)
        {
            var reverse = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
            foreach (var node in OrderedNodes)
            foreach (var target in Targets(node))
            {
                if (!reverse.TryGetValue(target, out var sources))
                {
                    sources = new List<string>();
                    reverse[target] = sources;
                }
                sources.Add(node.id);
            }

            var found = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var pending = new Stack<string>(terminalIds);
            while (pending.Count > 0)
            {
                var id = pending.Pop();
                if (!found.Add(id)) continue;
                if (reverse.TryGetValue(id, out var sources))
                    foreach (var source in sources) pending.Push(source);
            }
            return found;
        }

        public static IEnumerable<string> Targets(StoryNode node)
        {
            if (!string.IsNullOrWhiteSpace(node.next)) yield return node.next;
            if (node.options != null)
                foreach (var option in node.options)
                    if (!string.IsNullOrWhiteSpace(option?.Target)) yield return option.Target;
            if (!string.IsNullOrWhiteSpace(node.next_on_decline?.target)) yield return node.next_on_decline.target;
        }

        private static void ValidateTarget(GraphValidationResult result, string nodeId, string field, string target,
            HashSet<string> ids, bool requiredWhenPresent)
        {
            if (string.IsNullOrWhiteSpace(target))
            {
                if (requiredWhenPresent) result.Errors.Add($"{nodeId}: {field} target is empty.");
                return;
            }
            if (!ids.Contains(target)) result.Errors.Add($"{nodeId}: {field} links to missing node '{target}'.");
        }

        private void DetectImmediateCycles(string entryNodeId, GraphValidationResult result)
        {
            // Cycles are legal for future episodes if they contain a player interaction,
            // pause, call, or typing delay. A cycle made exclusively from immediate system
            // nodes would spin forever in one frame and is therefore an error.
            var visiting = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var visited = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var path = new List<string>();

            Action<string> visit = null;
            visit = id =>
            {
                if (visited.Contains(id)) return;
                if (visiting.Contains(id))
                {
                    var start = path.FindIndex(item => string.Equals(item, id, StringComparison.OrdinalIgnoreCase));
                    var cycle = start >= 0 ? path.Skip(start).Concat(new[] { id }).ToList() : new List<string> { id };
                    var hasYield = cycle.Select(Get).Where(node => node != null).Any(NodeYields);
                    if (!hasYield) result.Errors.Add("Non-yielding story cycle: " + string.Join(" -> ", cycle));
                    return;
                }

                visiting.Add(id);
                path.Add(id);
                var node = Get(id);
                if (node != null)
                    foreach (var target in Targets(node)) visit(target);
                path.RemoveAt(path.Count - 1);
                visiting.Remove(id);
                visited.Add(id);
            };
            visit(entryNodeId);
        }

        private static bool NodeYields(StoryNode node)
        {
            return node.type == "Pause" || node.type == "Player_Choice" || node.type == "IncomingCall" ||
                   node.type == "Phone_Call_Event" || node.type == "Accept_Call" || node.IsTyping || node.duration > 0;
        }
    }

    public sealed class GraphValidationResult
    {
        public readonly List<string> Errors = new List<string>();
        public readonly List<string> Warnings = new List<string>();
        public bool IsValid => Errors.Count == 0;

        public override string ToString()
        {
            if (IsValid) return "Story graph is valid.";
            return string.Join("\n", Errors);
        }
    }
}
