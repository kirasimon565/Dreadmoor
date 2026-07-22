using System.Collections.Generic;

namespace Dreadmoor.Core
{
    public static class RecapBuilder
    {
        public static List<RecapLineData> Build(GameStore store, string episodeId)
        {
            var lines = new List<RecapLineData>();
            if (episodeId == "ep01") BuildEpisodeOne(store, lines);
            else lines.Add(new RecapLineData(RecapLineKind.Body, "The investigation remains cold."));

            var evidence = BuildEvidence(store);
            if (evidence.Count > 0)
            {
                lines.Add(new RecapLineData(RecapLineKind.Category, "Evidence On File"));
                lines.AddRange(evidence);
            }

            if (store.Data.messages.Count > 0)
            {
                lines.Add(new RecapLineData(RecapLineKind.Category, "Current Status"));
                lines.Add(new RecapLineData(RecapLineKind.Cliffhanger,
                    store.Data.episodeComplete
                        ? "The line went dead. You are being watched."
                        : "The investigation is active. Someone is waiting for your next move."));
            }
            return lines;
        }

        private static void BuildEpisodeOne(GameStore store, ICollection<RecapLineData> lines)
        {
            lines.Add(new RecapLineData(RecapLineKind.Category, "The Disappearance"));
            lines.Add(new RecapLineData(RecapLineKind.Body,
                "Rebecca Stone vanished after a party at the abandoned factory. The official story says she left at midnight."));

            if (store.Flag("confronted_chris"))
                lines.Add(new RecapLineData(RecapLineKind.Choice,
                    "You forced Chris to admit he did not see Rebecca leave."));
            if (store.Flag("trusted_unknown"))
                lines.Add(new RecapLineData(RecapLineKind.Choice,
                    "You followed the unknown hacker's lead into the group chat."));
            else
                lines.Add(new RecapLineData(RecapLineKind.Choice,
                    "You entered the investigation with deep suspicion."));

            if (store.GetThread("group_dreadmoor_news") != null)
                lines.Add(new RecapLineData(RecapLineKind.Body,
                    "Amelia, Chris, Abigail and Michael tried to hold a single version of the night together."));
            if (store.GetThread("intercept_amelia_michael") != null)
                lines.Add(new RecapLineData(RecapLineKind.Body,
                    "A private intercept exposed panic behind their public story."));
        }

        private static List<RecapLineData> BuildEvidence(GameStore store)
        {
            var evidence = new List<RecapLineData>();
            if (store.Flag("found_factory_clip") || store.HasMessageForNode("S4_VIDEO_NODE"))
                evidence.Add(new RecapLineData(RecapLineKind.Evidence,
                    "Party Footage — proof that the midnight timeline was manipulated."));
            if (store.Flag("intercepted_chat") || store.GetThread("intercept_amelia_michael") != null)
                evidence.Add(new RecapLineData(RecapLineKind.Evidence,
                    "Leaked Intercept — Amelia and Michael coordinated their stories."));
            if (store.Flag("diaryUnlocked"))
                evidence.Add(new RecapLineData(RecapLineKind.Evidence,
                    "Rebecca's Diary — she knew the factory gathering was not a harmless joke."));
            if (store.Data.callHistory.Count > 0)
                evidence.Add(new RecapLineData(RecapLineKind.Evidence,
                    "Threatening Call — the unknown source made direct contact after the intercept."));
            return evidence;
        }
    }
}
