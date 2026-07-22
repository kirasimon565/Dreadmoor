using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    public sealed partial class DreadmoorApp
    {
        private void ShowContentUpdate(Action complete)
        {
            var root = NewScreen(AppView.ContentUpdate, Color.black);
            UIFactory.Background(root, "assets/media/images/skull_noir_bg.png", new Color(0.32f, 0.32f, 0.32f, 1));
            UIFactory.Background(root, "assets/ui/glitch_overlay.png", new Color(1, 1, 1, 0.045f));
            var shade = UIFactory.Panel(root, new Color(0, 0, 0, 0.72f), "UpdateShade");
            UIFactory.Stretch(shade.rectTransform);

            var spinner = UIFactory.Text(root, "◌", 48, UIFactory.Cyan, TextAnchor.MiddleCenter, true);
            SetAnchors(spinner.rectTransform, 0.42f, 0.58f, 0.57f, 0.67f);
            spinner.gameObject.AddComponent<BreathingAnimator>().scaleAmount = 0.12f;
            var heading = UIFactory.Text(root, "VERIFYING CONTENT", 25, Color.white, TextAnchor.MiddleCenter, true);
            SetAnchors(heading.rectTransform, 0.12f, 0.88f, 0.49f, 0.58f);
            var status = UIFactory.Text(root, "Preparing story graph...", 19, new Color(1, 1, 1, 0.56f), TextAnchor.UpperCenter);
            SetAnchors(status.rectTransform, 0.08f, 0.92f, 0.4f, 0.49f);
            var progress = BuildProgressBar(root);
            SetAnchors(progress.GetComponent<RectTransform>(), 0.16f, 0.84f, 0.35f, 0.37f);
            _flow = StartCoroutine(VerifyContentFlow(status, progress, complete));
        }

        private IEnumerator VerifyContentFlow(Text status, Slider progress, Action complete)
        {
            var checks = new[]
            {
                "LOADING EPISODE MANIFEST",
                "LINKING 391 STORY NODES",
                "VERIFYING CHOICE BRANCHES",
                "VERIFYING CALL LOOPS",
                "INDEXING EVIDENCE MEDIA",
                "RESTORING LOCAL SAVE",
                "CONTENT READY"
            };
            for (var i = 0; i < checks.Length; i++)
            {
                status.text = checks[i];
                progress.value = (i + 1) / (float)checks.Length;
                yield return new WaitForSecondsRealtime(_store.Data.settings.reducedMotion ? 0.04f : 0.16f);
            }
            _flow = null;
            complete?.Invoke();
        }

        private Slider BuildProgressBar(Transform parent)
        {
            var background = UIFactory.Panel(parent, new Color(1, 1, 1, 0.2f), "ProgressBar", true);
            var slider = background.gameObject.AddComponent<Slider>();
            slider.interactable = false;
            slider.minValue = 0;
            slider.maxValue = 1;
            var fillArea = UIFactory.Stretch(background.transform, "FillArea");
            var fill = UIFactory.Panel(fillArea, UIFactory.Cyan, "Fill", true).rectTransform;
            UIFactory.Stretch(fill);
            slider.fillRect = fill;
            slider.targetGraphic = background;
            return slider;
        }

        private void ShowSaveLoad()
        {
            BuildOsShell(AppView.SaveLoad, false, out var content);
            AddHeader(content, "SAVE / LOAD", ShowSettings, "LOCAL CASE ARCHIVE");
            var body = UIFactory.Rect(content, "SaveSlots", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, Background, 24, 32);
            var explanation = UIFactory.Text(list,
                "Story progress is auto-saved. Manual slots preserve a separate snapshot that can be restored later.",
                19, Dim, TextAnchor.MiddleCenter);
            UIFactory.Preferred(explanation.gameObject, 95);
            for (var slot = 1; slot <= 3; slot++) AddSaveSlot(list, slot);
            AddSection(list, "AUTOSAVE");
            var autosave = UIFactory.Text(list,
                "LAST WRITE  " + LastSaveLabel() + "\nNODE  " + (_store.Data.currentNodeId ?? "COMPLETE") +
                "\nPROGRESS  " + _store.Data.processedNodeIds.Count + "/391",
                19, Foreground, TextAnchor.MiddleLeft);
            UIFactory.Preferred(autosave.gameObject, 130);
        }

        private void AddSaveSlot(Transform parent, int slotNumber)
        {
            var info = _store.InspectSlot(slotNumber);
            var card = UIFactory.Panel(parent, Surface, "SaveSlot" + slotNumber, true).rectTransform;
            UIFactory.Preferred(card.gameObject, 235);
            var title = UIFactory.Text(card, $"SLOT {slotNumber:00}" + (info.exists ? "  /  OCCUPIED" : "  /  EMPTY"),
                23, info.exists ? UIFactory.Cyan : Dim, TextAnchor.MiddleLeft, true);
            SetAnchors(title.rectTransform, 0.05f, 0.95f, 0.72f, 0.94f);
            var detail = UIFactory.Text(card, SaveSlotDescription(info), 17, Foreground, TextAnchor.UpperLeft);
            SetAnchors(detail.rectTransform, 0.05f, 0.95f, 0.34f, 0.72f);

            var save = UIFactory.Button(card, "SAVE", () =>
            {
                try
                {
                    _store.SaveToSlot(slotNumber);
                    ShowSaveLoad();
                }
                catch (Exception exception)
                {
                    ShowNotificationBanner(new NotificationData { title = "SAVE ERROR", message = exception.Message });
                }
            }, UIFactory.EvidenceRed, Color.white, 62, 16);
            SetAnchors(save.GetComponent<RectTransform>(), 0.05f, 0.31f, 0.06f, 0.29f);

            var load = UIFactory.Button(card, "LOAD", () =>
            {
                _scheduler.Suspend();
                if (_store.LoadFromSlot(slotNumber))
                {
                    ShowWelcome();
                }
                else
                {
                    ShowNotificationBanner(new NotificationData { title = "LOAD ERROR", message = "This slot could not be loaded." });
                    ShowSaveLoad();
                }
            }, UIFactory.Cyan, Color.white, 62, 16);
            load.interactable = info.exists;
            SetAnchors(load.GetComponent<RectTransform>(), 0.37f, 0.63f, 0.06f, 0.29f);

            var delete = UIFactory.Button(card, "DELETE", () =>
            {
                _store.DeleteSlot(slotNumber);
                ShowSaveLoad();
            }, new Color(0.22f, 0.04f, 0.04f, 1), Color.white, 62, 16);
            delete.interactable = info.exists;
            SetAnchors(delete.GetComponent<RectTransform>(), 0.69f, 0.95f, 0.06f, 0.29f);
        }

        private static string SaveSlotDescription(SaveSlotInfo info)
        {
            if (!info.exists) return "NO CASE DATA\nSelect SAVE to write the current investigation.";
            var date = DateTime.TryParse(info.savedUtc, out var parsed)
                ? parsed.ToLocalTime().ToString("dd MMM yyyy  HH:mm", CultureInfo.InvariantCulture).ToUpperInvariant()
                : "UNKNOWN DATE";
            var preview = info.preview ?? "";
            if (preview.Length > 70) preview = preview.Substring(0, 67) + "...";
            return $"{info.playerName.ToUpperInvariant()}  •  {date}\n" +
                   $"PROGRESS {info.processedNodes}/{info.totalNodes}  •  {info.activeThreadTitle}\n{preview}";
        }

        private void ShowGallery()
        {
            BuildOsShell(AppView.Gallery, false, out var content);
            AddHeader(content, "EVIDENCE GALLERY", ShowApps, "RECOVERED MEDIA");
            var body = UIFactory.Rect(content, "GalleryBody", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, Color.black, 16, 28);
            if (_store.Data.mediaItems.Count == 0)
            {
                var empty = UIFactory.Text(list, "NO MEDIA RECOVERED", 24, new Color(1, 1, 1, 0.38f), TextAnchor.MiddleCenter, true);
                UIFactory.Preferred(empty.gameObject, 580);
                return;
            }

            for (var i = 0; i < _store.Data.mediaItems.Count; i++)
            {
                var index = i;
                var item = _store.Data.mediaItems[i];
                var sender = _store.Character(item.senderId).name;
                UIFactory.Button(list,
                    (item.mediaType == "video" ? "▶ VIDEO" : "IMAGE") + "  /  " + sender.ToUpperInvariant() +
                    "\n" + item.filePath,
                    () => OpenGalleryAt(index), new Color(0.08f, 0.1f, 0.12f, 1), Color.white, 112, 18);
            }
        }

        private void OpenGalleryAt(int index)
        {
            var items = _store.Data.mediaItems.Select(MediaViewerItem.From).ToList();
            var root = NewScreen(AppView.Gallery, Color.black);
            var viewer = root.gameObject.AddComponent<MediaViewerController>();
            viewer.Initialize(items, index, ShowGallery);
        }

        private void ShowDebug()
        {
            if (!Debug.isDebugBuild && !Application.isEditor)
            {
                ShowFatal("DEBUG CONSOLE IS DISABLED IN RELEASE BUILDS.");
                return;
            }

            var root = NewScreen(AppView.Debug, UIFactory.Hex("#080D08"));
            var header = UIFactory.Panel(root, UIFactory.Hex("#0A110A"), "DebugHeader").rectTransform;
            SetAnchors(header, 0, 1, 0.92f, 1);
            var back = UIFactory.Button(header, "< EXIT", ShowSettings, Color.clear, UIFactory.Hex("#4CAF50"), 72, 18, false);
            SetAnchors(back.GetComponent<RectTransform>(), 0.02f, 0.22f, 0.08f, 0.92f);
            var title = UIFactory.Text(header, "●  DREADMOOR DEBUG CONSOLE", 21, UIFactory.Hex("#4CAF50"), TextAnchor.MiddleCenter, true);
            SetAnchors(title.rectTransform, 0.18f, 0.86f, 0.08f, 0.92f);
            var mode = UIFactory.Text(header, "DEV", 15, UIFactory.Hex("#8BC34A"), TextAnchor.MiddleRight);
            SetAnchors(mode.rectTransform, 0.84f, 0.97f, 0.08f, 0.92f);

            var body = UIFactory.Rect(root, "DebugBody", Vector2.zero, new Vector2(1, 0.92f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, UIFactory.Hex("#080D08"), 11, 24);
            var terminal = UIFactory.Text(list,
                "DREADMOOR DEBUG CONSOLE v1.0\nBUILD: DEBUG\nGRAPH: " + _scheduler.Graph.OrderedNodes.Count +
                " NODES / VALID\nREADY.\n\n" + _store.DiagnosticSummary() + "\n█",
                17, UIFactory.Hex("#69F06D"), TextAnchor.UpperLeft);
            UIFactory.Preferred(terminal.gameObject, 410);

            AddDebugSection(list, "CORE");
            AddDebugAction(list, "COPY DIAGNOSTIC REPORT", () =>
            {
                GUIUtility.systemCopyBuffer = _store.DiagnosticSummary();
                ShowNotificationBanner(new NotificationData { title = "DEBUG", message = "Diagnostic report copied." });
            });
            AddDebugAction(list, "NUKE NARRATIVE / KEEP PLAYER", () =>
            {
                _scheduler.Suspend();
                _store.ClearNarrativeProgress(true);
                ShowDebug();
            }, true);
            AddDebugAction(list, "NUKE ALL LOCAL DATA", () =>
            {
                _scheduler.Suspend();
                _store.Reset();
                ShowSetup();
            }, true);

            AddDebugSection(list, "EPISODE JUMPS");
            AddDebugJump(list, "START EP01", GameStore.StartNodeId, true);
            AddDebugJump(list, "UNKNOWN PRIVATE CHAT", "s2_private_msg", true);
            AddDebugJump(list, "GROUP CHAT", "s3_group_chat", true);
            AddDebugJump(list, "DIARY PUZZLE", "S3_Diary_Trigger", true);
            AddDebugJump(list, "PARTY VIDEO", "S4_VIDEO_NODE", true);
            AddDebugJump(list, "SECRET INTERCEPT", "s4_intercept", true);
            AddDebugJump(list, "GLITCH / CALL SEQUENCE", "s5_glitch", true);
            AddDebugJump(list, "FINAL CREDITS", "EPISODE_1_END", true);

            AddDebugSection(list, "FLAGS & TIME");
            AddDebugAction(list, "UNLOCK ALL FLAGS", () => { _scheduler.DebugUnlockAllFlags(); ShowDebug(); });
            AddDebugAction(list, "CLEAR ALL FLAGS", () => { _store.Data.flags.Clear(); _store.Save(); ShowDebug(); });
            AddDebugAction(list, "ADVANCE GAME CLOCK +1 DAY", () =>
            {
                _store.Data.gameClockMinutes += 24 * 60; _store.Save(); ShowDebug();
            });
            AddDebugAction(list, "ADVANCE GAME CLOCK +7 DAYS", () =>
            {
                _store.Data.gameClockMinutes += 7 * 24 * 60; _store.Save(); ShowDebug();
            });
            AddDebugAction(list, "MARK ALL NOTIFICATIONS READ", () =>
            {
                foreach (var notification in _store.Data.notifications) notification.isRead = true;
                _store.Save(); ShowDebug();
            });

            AddDebugSection(list, "GRAPH INSPECTOR");
            var graph = _scheduler.Graph.Validate();
            var graphText = UIFactory.Text(list,
                "VALID: " + graph.IsValid + "\nERRORS: " + graph.Errors.Count + "\nWARNINGS: " + graph.Warnings.Count +
                "\nREACHABLE: " + _scheduler.Graph.ReachableFrom(GameStore.StartNodeId).Count + "/391\n" + graph,
                16, graph.IsValid ? UIFactory.Hex("#69F06D") : UIFactory.Hex("#FF5252"), TextAnchor.UpperLeft);
            UIFactory.Preferred(graphText.gameObject, 210);
        }

        private void AddDebugSection(Transform parent, string title)
        {
            var label = UIFactory.Text(parent, "// " + title, 16, UIFactory.Hex("#8BC34A"), TextAnchor.LowerLeft, true);
            UIFactory.Preferred(label.gameObject, 55);
        }

        private void AddDebugAction(Transform parent, string title, Action action, bool danger = false)
        {
            UIFactory.Button(parent, "> " + title, action,
                danger ? UIFactory.Hex("#2B0909") : UIFactory.Hex("#0C190C"),
                danger ? UIFactory.Hex("#FF5252") : UIFactory.Hex("#69F06D"), 72, 16, false);
        }

        private void AddDebugJump(Transform parent, string title, string nodeId, bool clear)
        {
            AddDebugAction(parent, title + "  [" + nodeId + "]", () =>
            {
                ShowMessenger();
                if (!_scheduler.DebugJumpTo(nodeId, clear))
                    ShowFatal("DEBUG JUMP TARGET WAS NOT FOUND: " + nodeId);
            });
        }
    }
}
