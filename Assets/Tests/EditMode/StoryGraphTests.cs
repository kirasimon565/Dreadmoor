using System;
using System.Collections.Generic;
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
        public void EpisodeOne_HasAll391UniqueScriptSections()
        {
            Assert.That(_graph.OrderedNodes.Count, Is.EqualTo(391));
            Assert.That(_graph.Nodes.Count, Is.EqualTo(391));
        }

        [Test]
        public void EverySectionAndBranch_IsLinkedAndReachable()
        {
            var validation = _graph.Validate();
            Assert.That(validation.IsValid, Is.True, validation.ToString());
            Assert.That(_graph.ReachableFrom(GameStore.StartNodeId).Count, Is.EqualTo(391));
        }

        [Test]
        public void Choices_AlwaysHaveTextAndExistingDestinations()
        {
            var choices = _graph.OrderedNodes.Where(node => node.HasChoice).ToArray();
            Assert.That(choices.Length, Is.EqualTo(20));
            foreach (var node in choices)
            foreach (var option in node.Choices)
            {
                Assert.That(option.Text, Is.Not.Empty, node.Id);
                Assert.That(option.Destination, Is.Not.Empty, node.Id);
                Assert.That(_graph.Get(option.Destination), Is.Not.Null, $"{node.Id} -> {option.Destination}");
            }
        }

        [Test]
        public void EveryBranch_HasAPathToEpisodeEnding()
        {
            const string terminal = "EPISODE_1_END";
            var reverse = _graph.OrderedNodes
                .SelectMany(node => StoryGraph.Destinations(node).Select(destination => new { destination, source = node.Id }))
                .GroupBy(edge => edge.destination)
                .ToDictionary(group => group.Key, group => group.Select(edge => edge.source).ToArray());
            var canFinish = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var pending = new Stack<string>();
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
        public void Calls_AnswerAndDeclineDestinationsExist()
        {
            foreach (var node in _graph.OrderedNodes.Where(node => node.IncomingCall != null || node.ActiveCall != null))
            {
                if (!string.IsNullOrWhiteSpace(node.NextId)) Assert.That(_graph.Get(node.NextId), Is.Not.Null, node.Id);
                var decline = node.IncomingCall?.Call?.DeclineDestination;
                if (!string.IsNullOrWhiteSpace(decline)) Assert.That(_graph.Get(decline), Is.Not.Null, node.Id);
            }
        }

        [Test]
        public void EveryNarrativeMediaReference_LoadsFromResources()
        {
            foreach (var node in _graph.OrderedNodes)
            foreach (var assetPath in node.MediaAssetPaths)
                AssertResource(node.Id, assetPath);
        }

        [Test]
        public void DiaryGate_ContainsPuzzlePageAndAnswer()
        {
            var node = _graph.Get("S3_Diary_Trigger");
            Assert.That(node, Is.Not.Null);
            Assert.That(node.DiaryGate, Is.Not.Null);
            Assert.That(node.DiaryGate.Diary.Word, Is.EqualTo("ECHO"));
            Assert.That(node.DiaryGate.Diary.EpisodeId, Is.EqualTo("ep01"));
            Assert.That(node.DiaryGate.Diary.PageNumber, Is.EqualTo("1"));
            Assert.That(node.DiaryGate.Diary.OnSuccessNode, Is.EqualTo("s4_video"));
            Assert.That(node.DiaryGate.Diary.OnFailNode, Is.EqualTo("S3_Diary_Trigger"));
            Assert.That(Resources.Load<TextAsset>("assets/story/ep01/diary/page_01"), Is.Not.Null);
        }

        [Test]
        public void Episode_HasOneIntentionalTerminalCreditsSection()
        {
            var terminals = _graph.OrderedNodes.Where(node => node.IsTerminal).ToArray();
            Assert.That(terminals.Length, Is.EqualTo(1));
            Assert.That(terminals[0].Id, Is.EqualTo("EPISODE_1_END"));
        }

        [Test]
        public void NarrativeResources_ArePlainTextAndContainNoRetiredSchema()
        {
            foreach (var resource in StoryGraph.EpisodeOneResources)
            {
                var script = Resources.Load<TextAsset>(resource);
                Assert.That(script, Is.Not.Null, resource);
                Assert.That(script.text.TrimStart(), Does.StartWith("::"), resource);
                Assert.That(script.text, Does.Not.Contain("\"type\""), resource);
                Assert.That(script.text, Does.Not.Contain("next_on_decline"), resource);
                Assert.That(script.text, Does.Not.Contain("thread_members"), resource);
            }
        }

        [Test]
        public void Parser_InfersFallthroughAndHonorsExplicitDestinations()
        {
            const string script = @":: START
@message Unknown
hello
@goto BRANCH

:: SKIPPED
@message Unknown
unused

:: BRANCH
@choice
  left -> END
  right -> END

:: END
@credits done";
            var graph = StoryGraph.ParseScripts(new[] { script });
            Assert.That(graph.Get("START").NextId, Is.EqualTo("BRANCH"));
            Assert.That(graph.Get("SKIPPED").NextId, Is.EqualTo("BRANCH"));
            Assert.That(graph.Get("BRANCH").NextId, Is.Empty);
            Assert.That(graph.Get("BRANCH").Choices[0].Destination, Is.EqualTo("END"));
            Assert.That(graph.Validate("START").IsValid, Is.False, "SKIPPED is intentionally unreachable in this parser fixture.");
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
