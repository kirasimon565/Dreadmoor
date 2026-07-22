using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEngine;

namespace Dreadmoor.Core
{
    public sealed partial class GameStore
    {
        public IReadOnlyList<CharacterNoteData> NotesFor(string characterId)
        {
            RepairNullCollections();
            return Data.characterNotes
                .Where(note => string.Equals(note.characterId, characterId, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(note => note.updatedUtc)
                .ToList();
        }

        public CharacterNoteData AddCharacterNote(string characterId, string text)
        {
            RepairNullCollections();
            var normalized = (text ?? "").Trim();
            if (normalized.Length == 0) return null;
            var now = DateTime.UtcNow.ToString("O");
            var note = new CharacterNoteData
            {
                id = Guid.NewGuid().ToString("N"),
                characterId = string.IsNullOrWhiteSpace(characterId) ? "player" : characterId,
                noteText = normalized,
                createdUtc = now,
                updatedUtc = now
            };
            Data.characterNotes.Add(note);
            if (note.characterId == "player" && !Data.playerNotes.Contains(normalized))
                Data.playerNotes.Insert(0, normalized);
            Save();
            return note;
        }

        public bool UpdateCharacterNote(string noteId, string text)
        {
            var note = Data.characterNotes.FirstOrDefault(item => item.id == noteId);
            if (note == null || string.IsNullOrWhiteSpace(text)) return false;
            note.noteText = text.Trim();
            note.updatedUtc = DateTime.UtcNow.ToString("O");
            Save();
            return true;
        }

        public bool DeleteCharacterNote(string noteId)
        {
            var index = Data.characterNotes.FindIndex(note => note.id == noteId);
            if (index < 0) return false;
            var removed = Data.characterNotes[index];
            Data.characterNotes.RemoveAt(index);
            if (removed.characterId == "player") Data.playerNotes.Remove(removed.noteText);
            Save();
            return true;
        }

        public IReadOnlyList<CharacterPhotoData> PhotosFor(string characterId)
        {
            return Data.characterPhotos
                .Where(photo => string.Equals(photo.characterId, characterId, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(photo => photo.createdUtc)
                .ToList();
        }

        public CharacterPhotoData AddCharacterPhoto(string characterId, string path, string caption = "")
        {
            if (string.IsNullOrWhiteSpace(path)) return null;
            var existing = Data.characterPhotos.FirstOrDefault(photo =>
                photo.characterId == characterId && photo.photoPath == path);
            if (existing != null) return existing;
            var photo = new CharacterPhotoData
            {
                id = Guid.NewGuid().ToString("N"),
                characterId = characterId,
                photoPath = path,
                caption = caption ?? "",
                createdUtc = DateTime.UtcNow.ToString("O")
            };
            Data.characterPhotos.Add(photo);
            Save();
            return photo;
        }

        public IReadOnlyList<MediaItemData> MediaForThread(string threadId)
        {
            return Data.mediaItems
                .Where(item => string.Equals(item.threadId, threadId, StringComparison.OrdinalIgnoreCase))
                .OrderBy(item => item.createdUtc)
                .ToList();
        }

        public IReadOnlyList<MediaItemData> MediaForCharacter(string characterId)
        {
            return Data.mediaItems
                .Where(item => string.Equals(item.senderId, characterId, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(item => item.createdUtc)
                .ToList();
        }

        public MediaItemData AddMedia(string threadId, string senderId, string mediaType, string path, string thumbnail = "")
        {
            if (string.IsNullOrWhiteSpace(path)) return null;
            var existing = Data.mediaItems.FirstOrDefault(item => item.threadId == threadId && item.filePath == path);
            if (existing != null) return existing;
            var media = new MediaItemData
            {
                id = Guid.NewGuid().ToString("N"),
                threadId = threadId,
                senderId = senderId,
                mediaType = mediaType,
                filePath = path,
                thumbnailPath = thumbnail ?? "",
                createdUtc = DateTime.UtcNow.ToString("O")
            };
            Data.mediaItems.Add(media);
            return media;
        }

        public MinigameResultData GetMinigame(string minigameId)
        {
            var result = Data.minigameResults.FirstOrDefault(item => item.minigameId == minigameId);
            if (result != null) return result;
            result = new MinigameResultData
            {
                id = Guid.NewGuid().ToString("N"),
                minigameId = minigameId,
                heartsRemaining = 5
            };
            Data.minigameResults.Add(result);
            Save();
            return result;
        }

        public void RecordMinigameAttempt(string minigameId, bool completed, int heartsRemaining, string sessionData = "")
        {
            var result = GetMinigame(minigameId);
            result.attemptsCount++;
            result.heartsRemaining = Math.Max(0, heartsRemaining);
            result.sessionData = sessionData ?? "";
            if (completed)
            {
                result.completed = true;
                result.completedAtUtc = DateTime.UtcNow.ToString("O");
                result.cooldownUntilUtc = "";
            }
            else if (result.heartsRemaining <= 0)
            {
                result.cooldownUntilUtc = DateTime.UtcNow.AddMinutes(15).ToString("O");
            }
            Save();
        }

        public EpisodeProgressData Episode(string id = "ep01")
        {
            RepairNullCollections();
            var episode = Data.episodes.FirstOrDefault(item => item.id == id);
            if (episode == null)
            {
                episode = new EpisodeProgressData
                {
                    id = id,
                    title = id == "ep01" ? "Episode 1: The Disappearance" : "Classified Episode",
                    isUnlocked = id == "ep01"
                };
                Data.episodes.Add(episode);
            }
            SynchronizeEpisode(episode);
            return episode;
        }

        public SaveSlotInfo InspectSlot(int slot)
        {
            ValidateSlot(slot);
            var path = SlotPath(slot);
            if (!File.Exists(path)) return new SaveSlotInfo { slot = slot, exists = false };
            try
            {
                var data = JsonUtility.FromJson<GameSaveData>(File.ReadAllText(path));
                if (data == null) return new SaveSlotInfo { slot = slot, exists = false };
                var thread = data.threads?.FirstOrDefault(item => item.id == data.activeThreadId);
                var lastMessage = data.messages?.LastOrDefault();
                return new SaveSlotInfo
                {
                    slot = slot,
                    exists = true,
                    playerName = data.player?.name ?? "Investigator",
                    savedUtc = data.lastSavedUtc ?? "",
                    episodeId = "ep01",
                    processedNodes = data.processedNodeIds?.Count ?? 0,
                    totalNodes = 391,
                    currentNodeId = data.currentNodeId ?? "",
                    activeThreadTitle = thread?.title ?? "",
                    preview = lastMessage?.content ?? "No messages recovered."
                };
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"Save slot {slot} could not be inspected: {exception.Message}");
                return new SaveSlotInfo { slot = slot, exists = false, preview = "CORRUPTED SLOT" };
            }
        }

        public SaveSlotInfo SaveToSlot(int slot)
        {
            ValidateSlot(slot);
            SynchronizeDerivedState();
            Save(false);
            var destination = SlotPath(slot);
            var temporary = destination + ".tmp";
            Directory.CreateDirectory(Application.persistentDataPath);
            File.WriteAllText(temporary, JsonUtility.ToJson(Data, true));
            if (File.Exists(destination)) File.Delete(destination);
            File.Move(temporary, destination);
            Changed?.Invoke();
            return InspectSlot(slot);
        }

        public bool LoadFromSlot(int slot)
        {
            ValidateSlot(slot);
            var path = SlotPath(slot);
            if (!File.Exists(path)) return false;
            try
            {
                var candidate = JsonUtility.FromJson<GameSaveData>(File.ReadAllText(path));
                if (candidate == null) return false;
                Data = candidate;
                RepairNullCollections();
                Save();
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogError($"Save slot {slot} failed to load: {exception}");
                return false;
            }
        }

        public bool DeleteSlot(int slot)
        {
            ValidateSlot(slot);
            var path = SlotPath(slot);
            try
            {
                if (File.Exists(path)) File.Delete(path);
                if (File.Exists(path + ".tmp")) File.Delete(path + ".tmp");
                Changed?.Invoke();
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"Save slot {slot} failed to delete: {exception.Message}");
                return false;
            }
        }

        public void ClearNarrativeProgress(bool keepPlayer = true)
        {
            var player = keepPlayer ? Data.player : new PlayerData();
            var settings = Data.settings;
            Data = NewSave();
            Data.player = player ?? new PlayerData();
            Data.settings = settings ?? new SettingsData();
            Save();
        }

        public string DiagnosticSummary()
        {
            RepairNullCollections();
            return
                $"PLAYER: {(HasPlayer ? Data.player.name : "NONE")}\n" +
                $"NODE: {Data.currentNodeId}\n" +
                $"THREADS: {Data.threads.Count}\n" +
                $"MESSAGES: {Data.messages.Count}\n" +
                $"NOTIFICATIONS: {Data.notifications.Count}\n" +
                $"FLAGS: {Data.flags.Count}\n" +
                $"PROCESSED: {Data.processedNodeIds.Count}/391\n" +
                $"MEDIA: {Data.mediaItems.Count}\n" +
                $"NOTES: {Data.characterNotes.Count}\n" +
                $"CALLS: {Data.callHistory.Count}\n" +
                $"CLOCK: {FormatGameTime()}";
        }

        private string SlotPath(int slot)
        {
            return Path.Combine(Application.persistentDataPath, $"dreadmoor-slot-{slot}.json");
        }

        private static void ValidateSlot(int slot)
        {
            if (slot < 1 || slot > 3) throw new ArgumentOutOfRangeException(nameof(slot), "Dreadmoor has save slots 1 through 3.");
        }

        private void SynchronizeDerivedState()
        {
            RepairNullCollections();
            foreach (var episode in Data.episodes) SynchronizeEpisode(episode);
        }

        private void SynchronizeEpisode(EpisodeProgressData episode)
        {
            if (episode.id != "ep01") return;
            episode.totalNodes = 391;
            episode.processedNodes = Data.processedNodeIds.Count;
            episode.completed = Data.episodeComplete || Flag("ep01_complete");
            episode.isUnlocked = true;
        }
    }
}
