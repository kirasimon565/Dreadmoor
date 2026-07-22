using System;
using System.Linq;
using Dreadmoor.Core;
using Dreadmoor.UI;
using NUnit.Framework;
using UnityEngine;

namespace Dreadmoor.Tests
{
    public sealed class StoryGraphTests
    {
        private StoryGraph _graph;

        [SetUp]
        public void SetUp()
        {
            _graph = StoryGraph.LoadEpisodeOne();
        }

        [Test]
        public void EpisodeOne_HasAll391UniqueNodes()
        {
            Assert.That(_graph.OrderedNodes.Count, Is.EqualTo(391));
            Assert.That(_graph.Nodes.Count, Is.EqualTo(391));
        }

        [Test]
        public void EveryNodeAndBranch_IsLinkedAndReachable()
        {
            var validation = _graph.Validate();
            Assert.That(validation.IsValid, Is.True, validation.ToString());
            Assert.That(_graph.ReachableFrom(GameStore.StartNodeId).Count, Is.EqualTo(391));
        }

        [Test]
        public void Choices_AlwaysHaveTextAndExistingTargets()
        {
            var choices = _graph.OrderedNodes.Where(node => node.type == "Player_Choice").ToArray();
            Assert.That(choices.Length, Is.EqualTo(20));
            foreach (var node in choices)
            foreach (var option in node.options)
            {
                Assert.That(option.text, Is.Not.Empty, node.id);
                Assert.That(option.Target, Is.Not.Empty, node.id);
                Assert.That(_graph.Get(option.Target), Is.Not.Null, $"{node.id} -> {option.Target}");
            }
        }

        [Test]
        public void EveryBranch_HasAPathToEpisodeEnding()
        {
            var terminal = "EPISODE_1_END";
            var reverse = _graph.OrderedNodes
                .SelectMany(node => StoryGraph.Targets(node).Select(target => new { target, source = node.id }))
                .GroupBy(edge => edge.target)
                .ToDictionary(group => group.Key, group => group.Select(edge => edge.source).ToArray());
            var canFinish = new System.Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var pending = new System.Collections.Generic.Stack<string>();
            pending.Push(terminal);
            while (pending.Count > 0)
            {
                var id = pending.Pop();
                if (!canFinish.Add(id)) continue;
                if (reverse.TryGetValue(id, out var sources))
                    foreach (var source in sources) pending.Push(source);
            }
            Assert.That(canFinish.Count, Is.EqualTo(391), "One or more choices enter a chain that cannot finish Episode 1.");
        }

        [Test]
        public void Calls_AnswerAndDeclineTargetsExist()
        {
            foreach (var node in _graph.OrderedNodes.Where(node =>
                         node.type == "IncomingCall" || node.type == "Force_Ringing" || node.type == "Accept_Call"))
            {
                if (!string.IsNullOrWhiteSpace(node.next)) Assert.That(_graph.Get(node.next), Is.Not.Null, node.id);
                if (node.next_on_decline != null) Assert.That(_graph.Get(node.next_on_decline.target), Is.Not.Null, node.id);
            }
        }

        [Test]
        public void EveryNarrativeMediaReference_LoadsFromResources()
        {
            foreach (var node in _graph.OrderedNodes)
            {
                AssertResource(node.id, node.image_asset);
                AssertResource(node.id, node.file_asset);
                AssertResource(node.id, node.audio_loop);
                AssertResource(node.id, node.audio_asset);
            }
        }

        [Test]
        public void DiaryLock_ContainsPuzzleMetadataAndPage()
        {
            var node = _graph.Get("S3_Diary_Trigger");
            Assert.That(node, Is.Not.Null);
            Assert.That(node.meta, Is.Not.Null);
            Assert.That(node.meta.word, Is.EqualTo("ECHO"));
            Assert.That(node.meta.pageId, Is.EqualTo("page_01"));
            Assert.That(Resources.Load<TextAsset>("assets/story/ep01/diary/page_01"), Is.Not.Null);
        }

        [Test]
        public void Episode_HasOneIntentionalTerminalCreditNode()
        {
            var terminals = _graph.OrderedNodes.Where(node =>
                string.IsNullOrWhiteSpace(node.next) && (node.options == null || node.options.Length == 0)).ToArray();
            Assert.That(terminals.Length, Is.EqualTo(1));
            Assert.That(terminals[0].id, Is.EqualTo("EPISODE_1_END"));
            Assert.That(terminals[0].action, Is.EqualTo("Trigger_Credits"));
        }

        [Test]
        public void SaveDocument_RoundTripsEveryGameplayTable()
        {
            var save = new GameSaveData();
            save.player.name = "Investigator";
            save.threads.Add(new ThreadData { id = "unknown", title = "Unknown" });
            save.messages.Add(new MessageData { id = "m1", threadId = "unknown", content = "test" });
            save.characterNotes.Add(new CharacterNoteData { id = "n1", characterId = "unknown", noteText = "watcher" });
            save.characterPhotos.Add(new CharacterPhotoData { id = "p1", characterId = "unknown", photoPath = "photo.png" });
            save.mediaItems.Add(new MediaItemData { id = "media1", filePath = "clip.mp4", mediaType = "video" });
            save.minigameResults.Add(new MinigameResultData { id = "g1", minigameId = "trace", attemptsCount = 2 });
            save.episodes.Add(new EpisodeProgressData { id = "ep01", processedNodes = 42 });
            var json = JsonUtility.ToJson(save);
            var restored = JsonUtility.FromJson<GameSaveData>(json);
            Assert.That(restored.player.name, Is.EqualTo("Investigator"));
            Assert.That(restored.threads.Count, Is.EqualTo(1));
            Assert.That(restored.messages.Count, Is.EqualTo(1));
            Assert.That(restored.characterNotes.Count, Is.EqualTo(1));
            Assert.That(restored.characterPhotos.Count, Is.EqualTo(1));
            Assert.That(restored.mediaItems.Count, Is.EqualTo(1));
            Assert.That(restored.minigameResults.Count, Is.EqualTo(1));
            Assert.That(restored.episodes.Count, Is.EqualTo(1));
        }

        [Test]
        public void AllStaticInterfaceResources_AreImportable()
        {
            var resources = new[]
            {
                "assets/branding/blackmoon_logo", "assets/branding/dreadmoor_logo",
                "assets/backgrounds/studio_intro_bg", "assets/backgrounds/welcome_bg_still",
                "assets/backgrounds/welcome_fog_loop", "assets/backgrounds/messenger_bg_texture",
                "assets/ui/glitch_overlay", "assets/ui/notebook_paper", "assets/ui/quill_red",
                "assets/ui/locked_episode_overlay", "assets/media/images/forest_moon_bg",
                "assets/media/images/moon_tower_hero", "assets/media/images/skull_noir_bg",
                "assets/media/videos/intro_teaser", "assets/media/videos/title_intro",
                "assets/music/welcome_theme", "assets/icon/icon"
            };
            foreach (var resource in resources)
                Assert.That(Resources.Load<UnityEngine.Object>(resource), Is.Not.Null, resource);
        }

        private static void AssertResource(string nodeId, string assetPath)
        {
            if (string.IsNullOrWhiteSpace(assetPath)) return;
            var normalized = UIFactory.ResourcePath(assetPath);
            Assert.That(Resources.Load<UnityEngine.Object>(normalized), Is.Not.Null,
                $"{nodeId} references missing asset {assetPath} ({normalized})");
        }
    }
}
