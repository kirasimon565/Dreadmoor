using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace Dreadmoor.Core
{
    /// <summary>Loads, links, and validates the native plain-text episode scripts.</summary>
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

        public IReadOnlyDictionary<string, StoryNode> Nodes { get; }
        public IReadOnlyList<StoryNode> OrderedNodes { get; }

        private StoryGraph(IEnumerable<StoryNode> nodes)
        {
            var ordered = nodes?.ToList() ?? new List<StoryNode>();
            OrderedNodes = ordered;
            Nodes = ordered
                .Where(node => node != null && !string.IsNullOrWhiteSpace(node.Id))
                .GroupBy(node => node.Id, StringComparer.OrdinalIgnoreCase)
                .ToDictionary(group => group.Key, group => group.First(), StringComparer.OrdinalIgnoreCase);

            for (var index = 0; index < ordered.Count; index++)
            {
                var node = ordered[index];
                if (node == null || node.HasChoice || node.IsTerminal) continue;
                node.NextId = !string.IsNullOrWhiteSpace(node.ExplicitDestination)
                    ? node.ExplicitDestination
                    : index + 1 < ordered.Count ? ordered[index + 1]?.Id ?? "" : "";
            }
        }

        public StoryNode Get(string id)
        {
            if (string.IsNullOrWhiteSpace(id)) return null;
            return Nodes.TryGetValue(id, out var node) ? node : null;
        }

        public static StoryGraph LoadEpisodeOne()
        {
            var scripts = new List<string>();
            foreach (var resourcePath in EpisodeOneResources)
            {
                var asset = Resources.Load<TextAsset>(resourcePath);
                if (asset == null)
                    throw new InvalidOperationException($"Required narrative script is missing: {resourcePath}.txt");
                scripts.Add(asset.text);
            }
            return ParseScripts(scripts);
        }

        public static StoryGraph ParseScripts(IEnumerable<string> scripts)
        {
            var nodes = new List<StoryNode>();
            var scriptIndex = 0;
            foreach (var script in scripts ?? Enumerable.Empty<string>())
            {
                scriptIndex++;
                if (string.IsNullOrWhiteSpace(script)) continue;
                nodes.AddRange(NarrativeScriptParser.Parse(script, $"script_{scriptIndex:00}"));
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
                    result.Errors.Add("A narrative script contains an empty section.");
                    continue;
                }
                if (string.IsNullOrWhiteSpace(node.Id))
                {
                    result.Errors.Add("A narrative section has no ID.");
                    continue;
                }
                if (!ids.Add(node.Id)) result.Errors.Add($"Duplicate narrative section ID: {node.Id}");
                if (node.Commands.Count == 0) result.Errors.Add($"{node.Id}: section contains no directive.");

                if (node.HasChoice)
                {
                    if (node.Choices.Count == 0) result.Errors.Add($"{node.Id}: @choice requires an option.");
                    for (var index = 0; index < node.Choices.Count; index++)
                    {
                        var choice = node.Choices[index];
                        if (string.IsNullOrWhiteSpace(choice?.Text)) result.Errors.Add($"{node.Id}: choice {index} has no text.");
                        if (string.IsNullOrWhiteSpace(choice?.Destination)) result.Errors.Add($"{node.Id}: choice {index} has no destination.");
                    }
                }

                var incoming = node.IncomingCall;
                if (incoming != null && !incoming.Call.IsForced && string.IsNullOrWhiteSpace(incoming.Call.DeclineDestination))
                    result.Errors.Add($"{node.Id}: a non-forced @incoming_call requires @on_decline.");
                if (node.DiaryGate != null && node.DiaryGate.Diary == null)
                    result.Errors.Add($"{node.Id}: @diary_gate requires episode_id, page_number, unlock_word, on_success_node, and on_fail_node.");
            }

            foreach (var node in OrderedNodes.Where(node => node != null && !string.IsNullOrWhiteSpace(node.Id)))
            {
                if (node.DiaryGate != null)
                {
                    ValidateDestination(result, node.Id, "diary success", node.DiaryGate.Diary.OnSuccessNode, ids, true);
                    ValidateDestination(result, node.Id, "diary fail", node.DiaryGate.Diary.OnFailNode, ids, true);
                }

                if (node.DiaryGate == null)
                    ValidateDestination(result, node.Id, "flow", node.NextId, ids, !node.HasChoice && !node.IsTerminal);
                for (var index = 0; index < node.Choices.Count; index++)
                    ValidateDestination(result, node.Id, $"choice {index}", node.Choices[index]?.Destination, ids, true);
                var decline = node.IncomingCall?.Call?.DeclineDestination;
                if (!string.IsNullOrWhiteSpace(decline)) ValidateDestination(result, node.Id, "decline", decline, ids, true);
            }

            if (!ids.Contains(entryNodeId))
            {
                result.Errors.Add($"Entry section '{entryNodeId}' does not exist.");
                return result;
            }

            var reachable = ReachableFrom(entryNodeId);
            foreach (var id in ids.Where(id => !reachable.Contains(id)).OrderBy(id => id))
                result.Errors.Add($"Unreachable narrative section: {id}");

            var terminals = OrderedNodes.Where(node => node?.IsTerminal == true).Select(node => node.Id).ToArray();
            if (terminals.Length == 0)
            {
                result.Errors.Add("The story has no @credits terminal section.");
            }
            else
            {
                var canFinish = NodesThatCanReach(terminals);
                foreach (var id in reachable.Where(id => !canFinish.Contains(id)).OrderBy(id => id))
                    result.Errors.Add($"Narrative section cannot reach an ending: {id}");
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
                foreach (var destination in Destinations(node))
                    if (!string.IsNullOrWhiteSpace(destination)) pending.Push(destination);
            }
            return found;
        }

        private HashSet<string> NodesThatCanReach(IEnumerable<string> terminalIds)
        {
            var reverse = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
            foreach (var node in OrderedNodes)
            foreach (var destination in Destinations(node))
            {
                if (!reverse.TryGetValue(destination, out var sources))
                {
                    sources = new List<string>();
                    reverse[destination] = sources;
                }
                sources.Add(node.Id);
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

        public static IEnumerable<string> Destinations(StoryNode node)
        {
            if (node == null) yield break;
            if (!string.IsNullOrWhiteSpace(node.NextId)) yield return node.NextId;
            foreach (var choice in node.Choices)
                if (!string.IsNullOrWhiteSpace(choice?.Destination)) yield return choice.Destination;
            var decline = node.IncomingCall?.Call?.DeclineDestination;
            if (!string.IsNullOrWhiteSpace(decline)) yield return decline;
            var diaryGate = node.DiaryGate?.Diary;
            if (diaryGate != null)
            {
                if (!string.IsNullOrWhiteSpace(diaryGate.OnSuccessNode) && diaryGate.OnSuccessNode != "NONE") yield return diaryGate.OnSuccessNode;
                if (!string.IsNullOrWhiteSpace(diaryGate.OnFailNode) && diaryGate.OnFailNode != "NONE") yield return diaryGate.OnFailNode;
            }
        }

        private static void ValidateDestination(GraphValidationResult result, string nodeId, string label, string destination,
            HashSet<string> ids, bool required)
        {
            if (string.IsNullOrWhiteSpace(destination))
            {
                if (required) result.Errors.Add($"{nodeId}: {label} destination is empty.");
                return;
            }
            if (!ids.Contains(destination)) result.Errors.Add($"{nodeId}: {label} links to missing section '{destination}'.");
        }

        private void DetectImmediateCycles(string entryNodeId, GraphValidationResult result)
        {
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
                    if (!cycle.Select(Get).Where(node => node != null).Any(NodeYields))
                        result.Errors.Add("Non-yielding narrative cycle: " + string.Join(" -> ", cycle));
                    return;
                }

                visiting.Add(id);
                path.Add(id);
                var node = Get(id);
                if (node != null)
                    foreach (var destination in Destinations(node)) visit(destination);
                path.RemoveAt(path.Count - 1);
                visiting.Remove(id);
                visited.Add(id);
            };
            visit(entryNodeId);
        }

        private static bool NodeYields(StoryNode node)
        {
            return node.Commands.Any(command => command.Kind == NarrativeCommandKind.Delay ||
                                                command.Kind == NarrativeCommandKind.Choice ||
                                                command.Kind == NarrativeCommandKind.IncomingCall ||
                                                command.Kind == NarrativeCommandKind.ActiveCall ||
                                                command.Kind == NarrativeCommandKind.DiaryGate ||
                                                command.Kind == NarrativeCommandKind.Typing ||
                                                command.Kind == NarrativeCommandKind.Glitch);
        }
    }

    public sealed class GraphValidationResult
    {
        public readonly List<string> Errors = new List<string>();
        public readonly List<string> Warnings = new List<string>();
        public bool IsValid => Errors.Count == 0;

        public override string ToString()
        {
            return IsValid ? "Story graph is valid." : string.Join("\n", Errors);
        }
    }
}
