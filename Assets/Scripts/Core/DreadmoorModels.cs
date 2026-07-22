using System;
using System.Collections.Generic;
using UnityEngine;

namespace Dreadmoor.Core
{
    [Serializable]
    public sealed class StoryFile
    {
        public StoryNode[] scenes = Array.Empty<StoryNode>();
    }

    [Serializable]
    public sealed class StoryNode
    {
        public string id = "";
        public string type = "";
        public string sender = "";
        public string text = "";
        public string next = "";
        public string action = "";
        public string chat = "";
        public string thread_id = "";
        public string thread_title = "";
        public string[] thread_members = Array.Empty<string>();
        public bool thread_secret;
        public int duration;
        public int time_passed;
        public StoryChoice[] options = Array.Empty<StoryChoice>();
        public DeclineTarget next_on_decline;
        public string target = "";
        public string caller_name = "";
        public string caller_id = "";
        public string audio_loop = "";
        public string audio_asset = "";
        public bool disable_decline;
        public string visual_effect = "";
        public string file_asset = "";
        public string next_screen = "";
        public string flag_name = "";
        public string theme = "";
        public string headline = "";
        public string subheadline = "";
        public string image_asset = "";
        public string caption = "";
        public string[] body = Array.Empty<string>();
        public EmbeddedMetadata meta;

        public string SenderId => string.IsNullOrWhiteSpace(sender) ? "unknown" : sender.Trim().ToLowerInvariant();
        public bool IsTyping => string.Equals(action, "Typing", StringComparison.OrdinalIgnoreCase);
    }

    [Serializable]
    public sealed class StoryChoice
    {
        public string text = "";
        public string next = "";
        public string target = "";
        public string Target => !string.IsNullOrWhiteSpace(next) ? next : target;
    }

    [Serializable]
    public sealed class DeclineTarget
    {
        public int delay_seconds;
        public string target = "";
    }

    [Serializable]
    public sealed class EmbeddedMetadata
    {
        public string word = "";
        public string pageId = "";
    }

    [Serializable]
    public sealed class DiaryPageFile
    {
        public string id = "";
        public string episode = "";
        public int page;
        public string word = "";
        public string[] content = Array.Empty<string>();
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
