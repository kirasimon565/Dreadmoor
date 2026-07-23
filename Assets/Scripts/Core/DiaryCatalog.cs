using System;
using System.Collections.Generic;
using UnityEngine;

namespace Dreadmoor.Core
{
    public sealed class DiaryPageData
    {
        public string Id { get; }
        public string EpisodeId { get; }
        public int PageNumber { get; }
        public string TargetWord { get; }
        public string Content { get; }

        public DiaryPageData(string id, string episodeId, int pageNumber, string targetWord, string content)
        {
            Id = id;
            EpisodeId = episodeId;
            PageNumber = pageNumber;
            TargetWord = targetWord?.ToUpperInvariant() ?? "";
            Content = content ?? "";
        }
    }

    public static class DiaryCatalog
    {
        private static readonly Dictionary<string, DiaryPageData> _pages = new Dictionary<string, DiaryPageData>();

        public static void Initialize()
        {
            _pages.Clear();
            var assets = Resources.LoadAll<TextAsset>("assets/story");
            foreach (var asset in assets)
            {
                if (!asset.name.StartsWith("page_")) continue;
                try
                {
                    var nodes = NarrativeScriptParser.Parse(asset.text, asset.name);
                    foreach (var node in nodes)
                    {
                        var diaryCommand = node.Commands.Find(c => c.Kind == NarrativeCommandKind.Diary);
                        if (diaryCommand != null)
                        {
                            var epId = diaryCommand.Diary.EpisodeId;
                            var pageNumStr = diaryCommand.Diary.PageNumber;
                            var word = diaryCommand.Diary.Word;
                            int pageNum = int.Parse(pageNumStr);
                            var id = $"{epId}_page_{pageNum:D2}";
                            var content = diaryCommand.Text;
                            _pages[id] = new DiaryPageData(id, epId, pageNum, word, content);
                        }
                    }
                }
                catch (Exception e)
                {
                    Debug.LogWarning($"Failed to parse diary page {asset.name}: {e.Message}");
                }
            }
        }
        
        public static DiaryPageData GetPage(string id)
        {
            return _pages.TryGetValue(id, out var page) ? page : null;
        }

        public static IReadOnlyCollection<DiaryPageData> GetAllPages() => _pages.Values;
    }
}
