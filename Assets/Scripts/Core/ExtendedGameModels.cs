using System;
using System.Collections.Generic;

namespace Dreadmoor.Core
{
    /// <summary>
    /// Additional records preserved from the original Drift schema. They are
    /// intentionally separate from the story records so future episodes can
    /// evolve without invalidating existing saves.
    /// </summary>
    [Serializable]
    public sealed class CharacterNoteData
    {
        public string id = "";
        public string characterId = "";
        public string noteText = "";
        public string createdUtc = "";
        public string updatedUtc = "";
    }

    [Serializable]
    public sealed class CharacterPhotoData
    {
        public string id = "";
        public string characterId = "";
        public string photoPath = "";
        public string caption = "";
        public string createdUtc = "";
    }

    [Serializable]
    public sealed class MediaItemData
    {
        public string id = "";
        public string threadId = "";
        public string senderId = "";
        public string mediaType = "";
        public string filePath = "";
        public string thumbnailPath = "";
        public string createdUtc = "";
    }

    [Serializable]
    public sealed class MinigameResultData
    {
        public string id = "";
        public string minigameId = "";
        public bool completed;
        public int attemptsCount;
        public int heartsRemaining = 5;
        public string cooldownUntilUtc = "";
        public string completedAtUtc = "";
        public string sessionData = "";
    }

    [Serializable]
    public sealed class EpisodeProgressData
    {
        public string id = "ep01";
        public string title = "Episode 1: The Disappearance";
        public bool isUnlocked = true;
        public int processedNodes;
        public int totalNodes = 391;
        public int version = 1;
        public bool completed;

        public float NormalizedProgress => totalNodes <= 0 ? 0f :
            Math.Min(1f, Math.Max(0f, processedNodes / (float)totalNodes));
    }

    [Serializable]
    public sealed class SaveSlotInfo
    {
        public int slot;
        public bool exists;
        public string playerName = "";
        public string savedUtc = "";
        public string episodeId = "ep01";
        public int processedNodes;
        public int totalNodes = 391;
        public string currentNodeId = "";
        public string activeThreadTitle = "";
        public string preview = "";

        public float Progress => totalNodes <= 0 ? 0f :
            Math.Min(1f, Math.Max(0f, processedNodes / (float)totalNodes));
    }

    [Serializable]
    public sealed class GalleryCollectionData
    {
        public List<MediaItemData> items = new List<MediaItemData>();
    }

    public enum SchedulerWaitReason
    {
        None,
        InactiveThread,
        Choice,
        DiaryPuzzle,
        IncomingCall,
        ActiveCall,
        Suspended
    }

    public enum PhoneCallRuntimeState
    {
        Idle,
        Incoming,
        Active
    }

    public enum DreadmoorNotificationType
    {
        Chat,
        Article,
        System
    }

    public enum RecapLineKind
    {
        Category,
        Cliffhanger,
        Choice,
        Evidence,
        Body
    }

    [Serializable]
    public sealed class RecapLineData
    {
        public RecapLineKind kind;
        public string text = "";

        public RecapLineData() { }
        public RecapLineData(RecapLineKind kind, string text)
        {
            this.kind = kind;
            this.text = text;
        }
    }
}
