using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEngine;

namespace Dreadmoor.Core
{
    /// <summary>
    /// JSON-backed persistence for the Unity port. All narrative mutations are
    /// saved immediately so Android process termination cannot break a chain.
    /// </summary>
    public sealed partial class GameStore
    {
        public const int InitialGameMinutes = 1422;
        public const string StartNodeId = "SCENE_1_NEWS_ARTICLE";

        private static GameStore _instance;
        public static GameStore Instance => _instance ?? (_instance = new GameStore());

        public GameSaveData Data { get; private set; }
        public event Action Changed;

        public string SavePath => Path.Combine(Application.persistentDataPath, "dreadmoor-save.json");
        public bool HasPlayer => Data != null && Data.player != null && !string.IsNullOrWhiteSpace(Data.player.name);
        public bool HasActiveGame => Data != null && (Data.messages.Count > 0 || Data.processedNodeIds.Count > 0);

        private GameStore()
        {
            Load();
        }

        public void Load()
        {
            try
            {
                RecoverCompletedTemporarySave();
                if (File.Exists(SavePath))
                {
                    var parsed = JsonUtility.FromJson<GameSaveData>(File.ReadAllText(SavePath));
                    Data = parsed ?? NewSave();
                }
                else
                {
                    Data = NewSave();
                }
            }
            catch (Exception exception)
            {
                Debug.LogError($"Dreadmoor save was unreadable; a clean save was created. {exception}");
                BackupBrokenSave();
                Data = NewSave();
            }

            RepairNullCollections();
            Changed?.Invoke();
        }

        public void Save(bool notify = true)
        {
            RepairNullCollections();
            SynchronizeDerivedState();
            Data.lastSavedUtc = DateTime.UtcNow.ToString("O");
            var json = JsonUtility.ToJson(Data, true);
            var temporary = SavePath + ".tmp";

            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(SavePath) ?? Application.persistentDataPath);
                File.WriteAllText(temporary, json);
                if (File.Exists(SavePath)) File.Delete(SavePath);
                File.Move(temporary, SavePath);
            }
            catch (Exception exception)
            {
                Debug.LogError($"Dreadmoor could not persist progress: {exception}");
                // Keep a fully written temporary file. Load() can promote it if
                // the process stopped between deleting and replacing the save.
            }

            if (notify) Changed?.Invoke();
        }

        public void NotifyChanged()
        {
            Save();
        }

        public void Reset()
        {
            Data = NewSave();
            try
            {
                if (File.Exists(SavePath)) File.Delete(SavePath);
                if (File.Exists(SavePath + ".tmp")) File.Delete(SavePath + ".tmp");
                for (var slot = 1; slot <= 3; slot++)
                {
                    var slotPath = Path.Combine(Application.persistentDataPath, $"dreadmoor-slot-{slot}.json");
                    if (File.Exists(slotPath)) File.Delete(slotPath);
                    if (File.Exists(slotPath + ".tmp")) File.Delete(slotPath + ".tmp");
                }
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"Could not remove the old save: {exception.Message}");
            }
            Save();
        }

        public void SetPlayer(string name, string gender, string phone)
        {
            Data.player.name = (name ?? "").Trim();
            Data.player.gender = string.IsNullOrWhiteSpace(gender) ? "female" : gender;
            Data.player.phoneNumber = (phone ?? "").Trim();
            Save();
        }

        public ThreadData GetThread(string id)
        {
            return Data.threads.FirstOrDefault(thread => string.Equals(thread.id, id, StringComparison.OrdinalIgnoreCase));
        }

        public ThreadData EnsureThread(string id, string title = null, IEnumerable<string> members = null, bool secret = false)
        {
            if (string.IsNullOrWhiteSpace(id)) id = "unknown";
            var thread = GetThread(id);
            if (thread == null)
            {
                thread = new ThreadData
                {
                    id = id,
                    title = string.IsNullOrWhiteSpace(title) ? CharacterRegistry.Find(id).name : title,
                    isSecret = secret,
                    members = members != null ? new List<string>(members.Where(member => !string.IsNullOrWhiteSpace(member))) : new List<string>()
                };
                if (thread.members.Count == 0) thread.members.Add(id);
                Data.threads.Add(thread);
            }
            else
            {
                if (!string.IsNullOrWhiteSpace(title)) thread.title = title;
                if (members != null)
                {
                    foreach (var member in members.Where(member => !string.IsNullOrWhiteSpace(member)))
                    {
                        if (!thread.members.Contains(member)) thread.members.Add(member);
                    }
                }
                thread.isSecret |= secret;
            }
            return thread;
        }

        public List<MessageData> MessagesFor(string threadId)
        {
            return Data.messages.Where(message => string.Equals(message.threadId, threadId, StringComparison.OrdinalIgnoreCase)).ToList();
        }

        public MessageData LastMessage(string threadId)
        {
            return Data.messages.LastOrDefault(message => string.Equals(message.threadId, threadId, StringComparison.OrdinalIgnoreCase));
        }

        public bool HasMessageForNode(string nodeId)
        {
            return !string.IsNullOrWhiteSpace(nodeId) && Data.messages.Any(message => message.nodeId == nodeId);
        }

        public void AddMessage(MessageData message)
        {
            if (string.IsNullOrWhiteSpace(message.id)) message.id = Guid.NewGuid().ToString("N");
            Data.messages.Add(message);
            Save();
        }

        public void AddNotification(NotificationData notification)
        {
            var existing = Data.notifications.FindIndex(item => item.id == notification.id);
            if (existing >= 0) Data.notifications[existing] = notification;
            else Data.notifications.Insert(0, notification);
            Save();
        }

        public bool IsProcessed(string nodeId) => Data.processedNodeIds.Contains(nodeId);

        public void MarkProcessed(string nodeId)
        {
            if (!string.IsNullOrWhiteSpace(nodeId) && !Data.processedNodeIds.Contains(nodeId))
                Data.processedNodeIds.Add(nodeId);
        }

        public FlagData GetFlag(string key)
        {
            return Data.flags.FirstOrDefault(flag => flag.key == key);
        }

        public bool Flag(string key) => GetFlag(key)?.boolValue == true;

        public void SetFlag(string key, bool value = true, string stringValue = null, int? intValue = null)
        {
            var flag = GetFlag(key);
            if (flag == null)
            {
                flag = new FlagData { key = key };
                Data.flags.Add(flag);
            }
            flag.boolValue = value;
            if (stringValue != null) flag.stringValue = stringValue;
            if (intValue.HasValue) flag.intValue = intValue.Value;
            Save(false);
        }

        public DiaryProgressData GetDiary(string pageId, string targetWord)
        {
            var state = Data.diaryPages.FirstOrDefault(page => page.pageId == pageId);
            if (state == null)
            {
                state = new DiaryProgressData { pageId = pageId, targetWord = targetWord ?? "" };
                Data.diaryPages.Add(state);
            }
            if (!string.IsNullOrWhiteSpace(targetWord)) state.targetWord = targetWord.ToUpperInvariant();
            return state;
        }

        public string Sanitize(string input)
        {
            return (input ?? "").Replace("[PlayerName]", HasPlayer ? Data.player.name : "Detective");
        }

        public string FormatGameTime()
        {
            var date = new DateTime(2016, 6, 12, 23, 42, 0).AddMinutes(Data.gameClockMinutes - InitialGameMinutes);
            return date.ToString("HH:mm");
        }

        public string FormatGameDate()
        {
            var date = new DateTime(2016, 6, 12, 23, 42, 0).AddMinutes(Data.gameClockMinutes - InitialGameMinutes);
            return date.ToString("ddd, d MMM yyyy").ToUpperInvariant();
        }

        public CharacterData Character(string id)
        {
            if (string.Equals(id, "player", StringComparison.OrdinalIgnoreCase))
            {
                return new CharacterData("player", HasPlayer ? Data.player.name : "Investigator", Data.player.phoneNumber,
                    Data.player.profilePath, "My internal notes and findings.", "#4A9EBF");
            }
            return CharacterRegistry.Find(id);
        }

        private static GameSaveData NewSave()
        {
            return new GameSaveData
            {
                gameClockMinutes = InitialGameMinutes,
                currentNodeId = StartNodeId
            };
        }

        private void RepairNullCollections()
        {
            if (Data == null) Data = NewSave();
            if (Data.player == null) Data.player = new PlayerData();
            if (Data.article == null) Data.article = new ArticleData();
            if (Data.settings == null) Data.settings = new SettingsData();
            if (Data.processedNodeIds == null) Data.processedNodeIds = new List<string>();
            if (Data.threads == null) Data.threads = new List<ThreadData>();
            if (Data.messages == null) Data.messages = new List<MessageData>();
            if (Data.notifications == null) Data.notifications = new List<NotificationData>();
            if (Data.callHistory == null) Data.callHistory = new List<CallEntryData>();
            if (Data.flags == null) Data.flags = new List<FlagData>();
            if (Data.diaryPages == null) Data.diaryPages = new List<DiaryProgressData>();
            if (Data.playerNotes == null) Data.playerNotes = new List<string>();
            if (Data.characterNotes == null) Data.characterNotes = new List<CharacterNoteData>();
            if (Data.characterPhotos == null) Data.characterPhotos = new List<CharacterPhotoData>();
            if (Data.mediaItems == null) Data.mediaItems = new List<MediaItemData>();
            if (Data.minigameResults == null) Data.minigameResults = new List<MinigameResultData>();
            if (Data.episodes == null) Data.episodes = new List<EpisodeProgressData>();
            if (Data.episodes.Count == 0) Data.episodes.Add(new EpisodeProgressData());
            foreach (var legacyNote in Data.playerNotes)
            {
                if (Data.characterNotes.Any(note => note.characterId == "player" && note.noteText == legacyNote)) continue;
                Data.characterNotes.Add(new CharacterNoteData
                {
                    id = Guid.NewGuid().ToString("N"), characterId = "player", noteText = legacyNote,
                    createdUtc = DateTime.UtcNow.ToString("O"), updatedUtc = DateTime.UtcNow.ToString("O")
                });
            }
            foreach (var thread in Data.threads)
                if (thread.members == null) thread.members = new List<string>();
            if (string.IsNullOrWhiteSpace(Data.currentNodeId) && !Data.episodeComplete)
                Data.currentNodeId = StartNodeId;
        }

        private void RecoverCompletedTemporarySave()
        {
            var temporary = SavePath + ".tmp";
            if (File.Exists(SavePath) || !File.Exists(temporary)) return;
            try
            {
                // Verify that the temporary file is complete JSON before using it.
                var candidate = JsonUtility.FromJson<GameSaveData>(File.ReadAllText(temporary));
                if (candidate == null) return;
                File.Move(temporary, SavePath);
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"Temporary save recovery was skipped: {exception.Message}");
            }
        }

        private void BackupBrokenSave()
        {
            try
            {
                if (File.Exists(SavePath))
                    File.Copy(SavePath, SavePath + ".broken-" + DateTime.UtcNow.Ticks, true);
            }
            catch
            {
                // A backup failure must never prevent the game from starting.
            }
        }
    }
}
