using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace Dreadmoor.Core
{
    /// <summary>
    /// A parsed section of a plain-text narrative script. Sections fall through
    /// to the next section in file order unless an explicit <c>@goto</c> is used.
    /// </summary>
    public sealed class StoryNode
    {
        public string Id { get; }
        public IReadOnlyList<NarrativeCommand> Commands { get; }
        public string NextId { get; internal set; } = "";
        internal string ExplicitDestination { get; set; } = "";

        public StoryNode(string id, IReadOnlyList<NarrativeCommand> commands)
        {
            Id = id ?? "";
            Commands = commands ?? Array.Empty<NarrativeCommand>();
        }

        public bool HasChoice => Commands.Any(command => command.Kind == NarrativeCommandKind.Choice);
        public bool IsTerminal => Commands.Any(command => command.Kind == NarrativeCommandKind.Credits);
        public IReadOnlyList<StoryChoice> Choices => Commands.FirstOrDefault(command => command.Kind == NarrativeCommandKind.Choice)?.Choices
                                                    ?? Array.Empty<StoryChoice>();
        public NarrativeCommand IncomingCall => Commands.FirstOrDefault(command => command.Kind == NarrativeCommandKind.IncomingCall);
        public NarrativeCommand ActiveCall => Commands.FirstOrDefault(command => command.Kind == NarrativeCommandKind.ActiveCall);
        public NarrativeCommand DiaryGate => Commands.FirstOrDefault(command => command.Kind == NarrativeCommandKind.DiaryGate);

        public IEnumerable<string> MediaAssetPaths => Commands.SelectMany(command => new[]
        {
            command.AssetPath,
            command.News?.ImagePath,
            command.Call?.AudioPath
        }).Where(path => !string.IsNullOrWhiteSpace(path) && path != "-");
    }

    public enum NarrativeCommandKind
    {
        Typing,
        Message,
        Delay,
        Choice,
        ContextSwitch,
        Notification,
        Video,
        Image,
        News,
        Diary,
        DiaryGate,
        Intercept,
        Glitch,
        IncomingCall,
        ActiveCall,
        Credits
    }

    /// <summary>One native directive from a narrative script.</summary>
    public sealed class NarrativeCommand
    {
        public NarrativeCommandKind Kind { get; }
        public string Sender { get; }
        public string Text { get; }
        public float Seconds { get; }
        public string ContextId { get; }
        public string AssetPath { get; }
        public IReadOnlyList<StoryChoice> Choices { get; }
        public StoryNews News { get; }
        public StoryDiaryGate Diary { get; }
        public StoryCall Call { get; }

        public NarrativeCommand(NarrativeCommandKind kind, string sender = "", string text = "", float seconds = 0f,
            string contextId = "", string assetPath = "", IReadOnlyList<StoryChoice> choices = null,
            StoryNews news = null, StoryDiaryGate diary = null, StoryCall call = null)
        {
            Kind = kind;
            Sender = sender ?? "";
            Text = text ?? "";
            Seconds = seconds;
            ContextId = contextId ?? "";
            AssetPath = assetPath ?? "";
            Choices = choices ?? Array.Empty<StoryChoice>();
            News = news;
            Diary = diary;
            Call = call;
        }
    }

    public sealed class StoryChoice
    {
        public string Text { get; }
        public string Destination { get; }

        public StoryChoice(string text, string destination)
        {
            Text = text ?? "";
            Destination = destination ?? "";
        }
    }

    public sealed class StoryNews
    {
        public string Headline { get; }
        public string Subheadline { get; }
        public string ImagePath { get; }
        public string Caption { get; }
        public string[] Body { get; }

        public StoryNews(string headline, string subheadline, string imagePath, string caption, string[] body)
        {
            Headline = headline ?? "";
            Subheadline = subheadline ?? "";
            ImagePath = imagePath ?? "";
            Caption = caption ?? "";
            Body = body ?? Array.Empty<string>();
        }
    }

    public sealed class StoryDiaryGate
    {
        public string EpisodeId { get; }
        public string PageNumber { get; }
        public string Word { get; }
        public string OnSuccessNode { get; }
        public string OnFailNode { get; }

        public StoryDiaryGate(string episodeId, string pageNumber, string word, string onSuccessNode, string onFailNode)
        {
            EpisodeId = episodeId ?? "";
            PageNumber = pageNumber ?? "";
            Word = word ?? "";
            OnSuccessNode = onSuccessNode ?? "";
            OnFailNode = onFailNode ?? "";
        }
    }

    public sealed class StoryCall
    {
        public string CallerName { get; }
        public string CallerNumber { get; }
        public string AudioPath { get; }
        public bool IsForced { get; }
        public float DeclineDelaySeconds { get; set; }
        public string DeclineDestination { get; set; } = "";

        public StoryCall(string callerName, string callerNumber, string audioPath, bool isForced)
        {
            CallerName = callerName ?? "";
            CallerNumber = callerNumber ?? "";
            AudioPath = audioPath ?? "";
            IsForced = isForced;
        }
    }

    /// <summary>
    /// Context presentation belongs to the game, not the authoring format. Scripts
    /// refer only to stable context IDs through <c>@switch_context</c> and
    /// <c>@intercept</c>.
    /// </summary>
    public static class StoryContexts
    {
        private sealed class Definition
        {
            public readonly string Title;
            public readonly string[] Members;
            public readonly bool Secret;

            public Definition(string title, string[] members, bool secret = false)
            {
                Title = title;
                Members = members;
                Secret = secret;
            }
        }

        private static readonly Dictionary<string, Definition> Definitions = new Dictionary<string, Definition>(StringComparer.OrdinalIgnoreCase)
        {
            { "unknown", new Definition("Unknown", new[] { "unknown" }) },
            { "group_dreadmoor_news", new Definition("Dreadmoor News", new[] { "amelia", "chris", "abigail", "michael" }) },
            { "intercept_amelia_michael", new Definition("Amelia & Michael", new[] { "amelia", "michael" }, true) }
        };

        public static ThreadData Ensure(GameStore store, string contextId, bool secret = false)
        {
            var id = string.IsNullOrWhiteSpace(contextId) ? "unknown" : contextId.Trim();
            if (Definitions.TryGetValue(id, out var definition))
                return store.EnsureThread(id, definition.Title, definition.Members, secret || definition.Secret);
            return store.EnsureThread(id, null, null, secret);
        }
    }

    [Serializable]
    public sealed class PlayerData
    {
        public string name = "";
        public string gender = "female";
        public string phoneNumber = "";
        public string profilePath = "";
    }

    [Serializable]
    public sealed class CharacterData
    {
        public string id;
        public string name;
        public string phoneNumber;
        public string avatarPath;
        public string bio;
        public string colorHex;

        public CharacterData(string id, string name, string phoneNumber, string avatarPath, string bio, string colorHex)
        {
            this.id = id;
            this.name = name;
            this.phoneNumber = phoneNumber;
            this.avatarPath = avatarPath;
            this.bio = bio;
            this.colorHex = colorHex;
        }
    }

    [Serializable]
    public sealed class ThreadData
    {
        public string id = "";
        public string title = "";
        public List<string> members = new List<string>();
        public bool isSecret;
        public bool isTyping;
        public int unreadCount;
    }

    [Serializable]
    public sealed class MessageData
    {
        public string id = "";
        public string nodeId = "";
        public string threadId = "";
        public string senderId = "";
        public string content = "";
        public string mediaType = "text";
        public string mediaPath = "";
        public int gameMinutes;
        public bool isPlayerMessage;
        public bool isSecret;
    }

    [Serializable]
    public sealed class NotificationData
    {
        public string id = "";
        public string type = "system";
        public string title = "";
        public string message = "";
        public int gameMinutes;
        public string threadId = "";
        public bool isRead;
    }

    [Serializable]
    public sealed class ArticleData
    {
        public string nodeId = "";
        public string headline = "";
        public string subheadline = "";
        public string photo = "";
        public string caption = "";
        public string[] body = Array.Empty<string>();
    }

    [Serializable]
    public sealed class CallEntryData
    {
        public string name = "";
        public string number = "";
        public int gameMinutes;
        public string direction = "incoming";
        public int durationSeconds;
    }

    [Serializable]
    public sealed class FlagData
    {
        public string key = "";
        public bool boolValue;
        public int intValue;
        public string stringValue = "";
    }

    [Serializable]
    public sealed class DiaryProgressData
    {
        public string pageId = "";
        public string targetWord = "";
        public string enteredWord = "";
        public bool isUnlocked;
        public bool isCompleted;
    }

    [Serializable]
    public sealed class SettingsData
    {
        public bool lightTheme;
        public bool soundEffects = true;
        public bool music = true;
        public bool haptics = true;
        public bool reducedMotion;
        public float textSpeed = 1f;
    }

    [Serializable]
    public sealed class GameSaveData
    {
        public int schemaVersion = 1;
        public PlayerData player = new PlayerData();
        public int gameClockMinutes = 1422;
        public string currentNodeId = "SCENE_1_NEWS_ARTICLE";
        public string activeThreadId = "";
        public string activeChoiceNodeId = "";
        public bool introCinematicSeen;
        public bool episodeComplete;
        public string lastSavedUtc = "";
        public ArticleData article = new ArticleData();
        public List<string> processedNodeIds = new List<string>();
        public List<ThreadData> threads = new List<ThreadData>();
        public List<MessageData> messages = new List<MessageData>();
        public List<NotificationData> notifications = new List<NotificationData>();
        public List<CallEntryData> callHistory = new List<CallEntryData>();
        public List<FlagData> flags = new List<FlagData>();
        public List<DiaryProgressData> diaryPages = new List<DiaryProgressData>();
        public List<string> playerNotes = new List<string>();
        public List<CharacterNoteData> characterNotes = new List<CharacterNoteData>();
        public List<CharacterPhotoData> characterPhotos = new List<CharacterPhotoData>();
        public List<MediaItemData> mediaItems = new List<MediaItemData>();
        public List<MinigameResultData> minigameResults = new List<MinigameResultData>();
        public List<EpisodeProgressData> episodes = new List<EpisodeProgressData>();
        public SettingsData settings = new SettingsData();
    }

    public static class CharacterRegistry
    {
        public static readonly CharacterData[] All =
        {
            new CharacterData("unknown", "Unknown", "private/hidden", "assets/characters/unknown.png", "I see more than you think.", "#746fbc"),
            new CharacterData("amelia", "Amelia", "+1 251 396", "assets/characters/amelia.png", "Working late again at Joy's Diner.", "#08025c"),
            new CharacterData("chris", "Chris", "+1 978 726", "assets/characters/chris.png", "Night shifts and bad coffee.", "#becc00"),
            new CharacterData("abigail", "Abigail", "+1 466 098", "assets/characters/abigail.png", "If you know, you know.", "#00290a"),
            new CharacterData("michael", "Michael", "+1 689 140", "assets/characters/michael.png", "Reporter at Dreadmoor Daily.", "#9b0000"),
            new CharacterData("system", "System", "0000", "", "System notifications.", "#FFFFFF")
        };

        public static CharacterData Find(string id)
        {
            if (string.IsNullOrWhiteSpace(id)) id = "unknown";
            foreach (var character in All)
            {
                if (string.Equals(character.id, id, StringComparison.OrdinalIgnoreCase)) return character;
            }
            return new CharacterData(id, TitleCase(id), id, "", "No dossier data recovered.", "#746fbc");
        }

        private static string TitleCase(string value)
        {
            if (string.IsNullOrEmpty(value)) return "Unknown";
            return char.ToUpperInvariant(value[0]) + value.Substring(1).Replace('_', ' ');
        }
    }
}
