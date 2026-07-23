using System;
using System.Collections;
using System.Linq;
using UnityEngine;

namespace Dreadmoor.Core
{
    /// <summary>
    /// Executes the plain-text narrative graph. A single coroutine owns the
    /// persisted cursor so a process interruption cannot duplicate a message or
    /// lose an interaction.
    /// </summary>
    public sealed class StoryScheduler : MonoBehaviour
    {
        public event Action StateChanged;
        public event Action<NotificationData> NotificationRaised;
        public event Action<ArticleData> ArticleRequested;
        public event Action<StoryNode> ChoiceRequested;
        public event Action<StoryNode> IncomingCallRequested;
        public event Action<StoryNode> ActiveCallRequested;
        public event Action<string, string> DiaryRequested;
        public event Action<string> ThreadFocusRequested;
        public event Action<string, float> GlitchRequested;
        public event Action<string> CreditsRequested;
        public event Action<string> SoundRequested;
        public event Action<string> FatalError;

        public StoryGraph Graph { get; private set; }
        public bool IsRunning => _runner != null;
        public bool IsWaitingForInteraction { get; private set; }
        public string TypingThreadId { get; private set; } = "";

        private GameStore _store;
        private Coroutine _runner;
        private int _generation;

        public void Initialize()
        {
            _store = GameStore.Instance;
            try
            {
                Graph = StoryGraph.LoadEpisodeOne();
                var validation = Graph.Validate();
                if (!validation.IsValid) throw new InvalidOperationException("Narrative validation failed:\n" + validation);
                Debug.Log($"Dreadmoor narrative ready: {Graph.OrderedNodes.Count} script sections.");
            }
            catch (Exception exception)
            {
                Debug.LogException(exception);
                FatalError?.Invoke(exception.Message);
            }
        }

        public void Suspend()
        {
            _generation++;
            if (_runner != null) StopCoroutine(_runner);
            _runner = null;
            TypingThreadId = "";
            IsWaitingForInteraction = false;
        }

        public void StartNewStory()
        {
            Suspend();
            _store.Data.currentNodeId = GameStore.StartNodeId;
            _store.Data.activeChoiceNodeId = "";
            _store.Data.episodeComplete = false;
            _store.Save();
            ContinueAt(GameStore.StartNodeId);
        }

        public void Resume()
        {
            if (_runner != null || _store.Data.episodeComplete) return;
            var nodeId = _store.Data.currentNodeId;
            if (!string.IsNullOrWhiteSpace(nodeId)) ContinueAt(nodeId);
        }

        public void OpenThread(string threadId)
        {
            if (string.IsNullOrWhiteSpace(threadId)) return;
            _store.Data.activeThreadId = threadId;
            var thread = _store.GetThread(threadId);
            if (thread != null) thread.unreadCount = 0;
            _store.Save();
            if (_runner == null && !_store.Data.episodeComplete) Resume();
        }

        public void LeaveThread()
        {
            _store.Data.activeThreadId = "";
            _store.Save();
        }

        public void SubmitChoice(string choiceText, string targetNodeId)
        {
            var choiceId = _store.Data.activeChoiceNodeId;
            var choiceNode = Graph?.Get(choiceId);
            if (choiceNode == null || string.IsNullOrWhiteSpace(targetNodeId)) return;
            var validChoice = choiceNode.Choices.Any(choice => choice != null &&
                choice.Destination == targetNodeId && choice.Text == choiceText);
            if (!validChoice)
            {
                Debug.LogError($"Rejected invalid choice destination '{targetNodeId}' for '{choiceId}'.");
                return;
            }

            var contextId = ResolveContext();
            var thread = StoryContexts.Ensure(_store, contextId);
            _store.AddMessage(new MessageData
            {
                nodeId = "choice_" + choiceNode.Id,
                threadId = contextId,
                senderId = "player",
                content = _store.Sanitize(choiceText),
                gameMinutes = _store.Data.gameClockMinutes,
                isPlayerMessage = true,
                isSecret = thread.isSecret
            });
            _store.MarkProcessed(choiceNode.Id);
            _store.Data.activeChoiceNodeId = "";
            _store.Data.currentNodeId = targetNodeId;
            _store.Save();
            StateChanged?.Invoke();
            ContinueAt(targetNodeId);
        }

        public void AcceptIncomingCall()
        {
            var node = Graph?.Get(_store.Data.currentNodeId);
            if (node?.IncomingCall?.Call == null) return;
            var call = node.IncomingCall.Call;
            _store.Data.callHistory.Insert(0, new CallEntryData
            {
                name = CallerName(node), number = CallerNumber(node), gameMinutes = _store.Data.gameClockMinutes,
                direction = "incoming"
            });
            CompleteInteractionNode(node, node.NextId);
        }

        public void DeclineIncomingCall()
        {
            var node = Graph?.Get(_store.Data.currentNodeId);
            var call = node?.IncomingCall?.Call;
            if (call == null || call.IsForced || string.IsNullOrWhiteSpace(call.DeclineDestination)) return;

            _store.Data.callHistory.Insert(0, new CallEntryData
            {
                name = CallerName(node), number = CallerNumber(node), gameMinutes = _store.Data.gameClockMinutes,
                direction = "missed"
            });
            _store.MarkProcessed(node.Id);
            _store.Data.currentNodeId = call.DeclineDestination;
            _store.Save();
            StateChanged?.Invoke();
            StartOwnedCoroutine(ContinueAfter(Mathf.Max(0f, call.DeclineDelaySeconds), call.DeclineDestination));
        }

        public void EndActiveCall(int durationSeconds)
        {
            var node = Graph?.Get(_store.Data.currentNodeId);
            if (node?.ActiveCall?.Call == null) return;
            if (_store.Data.callHistory.Count > 0)
                _store.Data.callHistory[0].durationSeconds = Mathf.Max(0, durationSeconds);
            CompleteInteractionNode(node, node.NextId);
        }

        public bool CompleteDiary(string pageId, string enteredWord)
        {
            var node = Graph?.Get(_store.Data.currentNodeId);
            var gate = node?.DiaryGate?.Diary;
            if (gate == null || !string.Equals(gate.PageId, pageId, StringComparison.OrdinalIgnoreCase)) return false;
            var normalized = (enteredWord ?? "").Trim().ToUpperInvariant();
            if (!string.Equals(normalized, gate.Word.Trim().ToUpperInvariant(), StringComparison.Ordinal)) return false;

            var diary = _store.GetDiary(gate.PageId, gate.Word);
            diary.enteredWord = normalized;
            diary.isUnlocked = true;
            diary.isCompleted = true;
            _store.SetFlag("diaryUnlocked");
            CompleteInteractionNode(node, node.NextId);
            return true;
        }

        public StoryNode ActiveChoice()
        {
            return Graph?.Get(_store.Data.activeChoiceNodeId);
        }

        public bool DebugJumpTo(string nodeId, bool clearNarrative = false)
        {
            if (!Debug.isDebugBuild && !Application.isEditor) return false;
            if (Graph?.Get(nodeId) == null) return false;
            Suspend();
            if (clearNarrative) _store.ClearNarrativeProgress(true);
            _store.Data.processedNodeIds.Remove(nodeId);
            _store.Data.currentNodeId = nodeId;
            _store.Data.activeChoiceNodeId = "";
            _store.Data.episodeComplete = false;
            _store.Save();
            ContinueAt(nodeId);
            return true;
        }

        public void DebugUnlockAllFlags()
        {
            if (!Debug.isDebugBuild && !Application.isEditor) return;
            var flags = new[]
            {
                "found_factory_phone", "confronted_amelia", "visited_factory", "saw_highway_crash",
                "found_diary_01", "trusted_detective", "contacted_informant", "found_recording",
                "confronted_mayor", "found_factory_clip", "intercepted_chat", "article_read", "diaryUnlocked"
            };
            foreach (var flag in flags) _store.SetFlag(flag);
            _store.Save();
        }

        public bool CanDecline(StoryNode node)
        {
            var call = node?.IncomingCall?.Call;
            return call != null && !call.IsForced && !string.IsNullOrWhiteSpace(call.DeclineDestination);
        }

        private void ContinueAt(string nodeId)
        {
            if (string.IsNullOrWhiteSpace(nodeId) || Graph == null) return;
            StartOwnedCoroutine(Run(nodeId, ++_generation));
        }

        private void StartOwnedCoroutine(IEnumerator routine)
        {
            if (_runner != null) StopCoroutine(_runner);
            _runner = StartCoroutine(routine);
        }

        private IEnumerator Run(string startNodeId, int generation)
        {
            // Ensure StartCoroutine has returned before a synchronous directive
            // can attempt to continue the narrative.
            yield return null;
            IsWaitingForInteraction = false;
            var nodeId = startNodeId;
            var immediateSteps = 0;

            while (!string.IsNullOrWhiteSpace(nodeId) && generation == _generation)
            {
                var node = Graph.Get(nodeId);
                if (node == null)
                {
                    StopWithError($"Narrative section '{nodeId}' was not found.");
                    yield break;
                }

                if (_store.IsProcessed(node.Id))
                {
                    if (string.IsNullOrWhiteSpace(node.NextId))
                    {
                        _runner = null;
                        yield break;
                    }
                    nodeId = node.NextId;
                    SetCursor(nodeId, false);
                    continue;
                }

                SetCursor(node.Id, false);
                if (!_store.Data.settings.reducedMotion) yield return new WaitForSecondsRealtime(0.12f);
                Debug.Log($"Dreadmoor -> {node.Id}");

                foreach (var command in node.Commands)
                {
                    switch (command.Kind)
                    {
                        case NarrativeCommandKind.Typing:
                        {
                            var contextId = ResolveContext(command.Sender);
                            StoryContexts.Ensure(_store, contextId);
                            TypingThreadId = contextId;
                            StateChanged?.Invoke();
                            yield return WaitSeconds(command.Seconds);
                            TypingThreadId = "";
                            StateChanged?.Invoke();
                            break;
                        }
                        case NarrativeCommandKind.Message:
                            if (!DeliverMessage(node, command, false))
                            {
                                MarkAndSetNext(node, node.NextId);
                                StateChanged?.Invoke();
                                IsWaitingForInteraction = true;
                                _runner = null;
                                yield break;
                            }
                            break;
                        case NarrativeCommandKind.Video:
                            if (!DeliverMessage(node, command, true))
                            {
                                MarkAndSetNext(node, node.NextId);
                                StateChanged?.Invoke();
                                IsWaitingForInteraction = true;
                                _runner = null;
                                yield break;
                            }
                            break;
                        case NarrativeCommandKind.Delay:
                            yield return WaitSeconds(command.Seconds);
                            break;
                        case NarrativeCommandKind.Choice:
                            ShowChoice(node);
                            yield break;
                        case NarrativeCommandKind.ContextSwitch:
                            SwitchContext(command.ContextId, false);
                            break;
                        case NarrativeCommandKind.Notification:
                            PublishNotification(node, command.Text);
                            break;
                        case NarrativeCommandKind.News:
                            PublishNews(node, command.News);
                            break;
                        case NarrativeCommandKind.Diary:
                            _store.GetDiary(command.Diary.PageId, command.Diary.Word);
                            _store.Save();
                            IsWaitingForInteraction = true;
                            DiaryRequested?.Invoke(command.Diary.Word, command.Diary.PageId);
                            _runner = null;
                            yield break;
                        case NarrativeCommandKind.Intercept:
                            SwitchContext(command.ContextId, true);
                            break;
                        case NarrativeCommandKind.Glitch:
                        {
                            var seconds = Mathf.Max(0.2f, command.Seconds);
                            GlitchRequested?.Invoke(command.Text, seconds);
                            yield return new WaitForSecondsRealtime(seconds);
                            break;
                        }
                        case NarrativeCommandKind.IncomingCall:
                            IsWaitingForInteraction = true;
                            IncomingCallRequested?.Invoke(node);
                            _runner = null;
                            yield break;
                        case NarrativeCommandKind.ActiveCall:
                            IsWaitingForInteraction = true;
                            ActiveCallRequested?.Invoke(node);
                            _runner = null;
                            yield break;
                        case NarrativeCommandKind.Credits:
                            CompleteCredits(node, command.Text);
                            yield break;
                        default:
                            StopWithError($"Unhandled narrative directive '{command.Kind}' in '{node.Id}'.");
                            yield break;
                    }
                }

                MarkAndSetNext(node, node.NextId);
                StateChanged?.Invoke();
                nodeId = node.NextId;

                immediateSteps++;
                if (immediateSteps >= 100)
                {
                    immediateSteps = 0;
                    yield return null;
                }
            }

            _runner = null;
            IsWaitingForInteraction = false;
        }

        private bool DeliverMessage(StoryNode node, NarrativeCommand command, bool isVideo)
        {
            var contextId = ResolveContext(command.Sender);
            var thread = StoryContexts.Ensure(_store, contextId);
            if (!_store.HasMessageForNode(node.Id))
            {
                var content = !string.IsNullOrWhiteSpace(command.Text) ? command.Text : command.AssetPath;
                _store.Data.messages.Add(new MessageData
                {
                    id = Guid.NewGuid().ToString("N"),
                    nodeId = node.Id,
                    threadId = contextId,
                    senderId = SenderId(command.Sender),
                    content = _store.Sanitize(content),
                    mediaType = isVideo ? "video" : "text",
                    mediaPath = isVideo ? command.AssetPath : "",
                    gameMinutes = _store.Data.gameClockMinutes,
                    isSecret = thread.isSecret
                });
                if (isVideo && !string.IsNullOrWhiteSpace(command.AssetPath))
                    _store.AddMedia(contextId, SenderId(command.Sender), "video", command.AssetPath);
            }

            var isActive = string.Equals(_store.Data.activeThreadId, contextId, StringComparison.OrdinalIgnoreCase);
            if (!isActive)
            {
                thread.unreadCount++;
                RaiseNotification(new NotificationData
                {
                    id = "msg_" + node.Id,
                    type = "chat",
                    title = thread.title,
                    message = _store.Sanitize(command.Text),
                    gameMinutes = _store.Data.gameClockMinutes,
                    threadId = contextId
                });
            }
            SoundRequested?.Invoke("assets/media/sfx/message_receive.mp3");
            return isActive;
        }

        private void ShowChoice(StoryNode node)
        {
            var contextId = ResolveContext();
            StoryContexts.Ensure(_store, contextId);
            _store.Data.activeThreadId = contextId;
            _store.Data.activeChoiceNodeId = node.Id;
            _store.Save();
            IsWaitingForInteraction = true;
            ChoiceRequested?.Invoke(node);
            ThreadFocusRequested?.Invoke(contextId);
            StateChanged?.Invoke();
            _runner = null;
        }

        private void SwitchContext(string contextId, bool secret)
        {
            var id = string.IsNullOrWhiteSpace(contextId) ? "unknown" : contextId.Trim();
            StoryContexts.Ensure(_store, id, secret);
            _store.Data.activeThreadId = id;
            ThreadFocusRequested?.Invoke(id);
        }

        private void PublishNotification(StoryNode node, string text)
        {
            var contextId = _store.Data.activeThreadId;
            if (!string.IsNullOrWhiteSpace(contextId) && !_store.HasMessageForNode(node.Id))
            {
                var thread = StoryContexts.Ensure(_store, contextId);
                _store.Data.messages.Add(new MessageData
                {
                    id = Guid.NewGuid().ToString("N"),
                    nodeId = node.Id,
                    threadId = contextId,
                    senderId = "system",
                    content = _store.Sanitize(text),
                    mediaType = "system_label",
                    gameMinutes = _store.Data.gameClockMinutes,
                    isSecret = thread.isSecret
                });
            }
            RaiseNotification(new NotificationData
            {
                id = "notice_" + node.Id,
                type = "system",
                title = "SYSTEM",
                message = _store.Sanitize(text),
                gameMinutes = _store.Data.gameClockMinutes,
                threadId = contextId ?? ""
            });
        }

        private void PublishNews(StoryNode node, StoryNews news)
        {
            var article = new ArticleData
            {
                nodeId = node.Id,
                headline = news.Headline,
                subheadline = news.Subheadline,
                photo = news.ImagePath,
                caption = news.Caption,
                body = news.Body
            };
            _store.Data.article = article;
            _store.SetFlag("article_read");
            RaiseNotification(new NotificationData
            {
                id = "news_" + node.Id,
                type = "article",
                title = "NEWS ALERT",
                message = news.Headline,
                gameMinutes = _store.Data.gameClockMinutes
            });
            ArticleRequested?.Invoke(article);
        }

        private void CompleteCredits(StoryNode node, string text)
        {
            _store.MarkProcessed(node.Id);
            _store.Data.episodeComplete = true;
            _store.Data.currentNodeId = "";
            _store.Save();
            CreditsRequested?.Invoke(text);
            StateChanged?.Invoke();
            _runner = null;
        }

        private IEnumerator ContinueAfter(float seconds, string target)
        {
            yield return null;
            if (seconds > 0f) yield return new WaitForSecondsRealtime(seconds);
            _runner = null;
            ContinueAt(target);
        }

        private object WaitSeconds(float seconds)
        {
            var speed = Mathf.Clamp(_store.Data.settings.textSpeed, 0.5f, 2f);
            return new WaitForSecondsRealtime(Mathf.Max(0.01f, seconds / speed));
        }

        private void CompleteInteractionNode(StoryNode node, string destination)
        {
            MarkAndSetNext(node, destination);
            IsWaitingForInteraction = false;
            StateChanged?.Invoke();
            ContinueAt(destination);
        }

        private void MarkAndSetNext(StoryNode node, string destination)
        {
            _store.MarkProcessed(node.Id);
            _store.Data.currentNodeId = destination ?? "";
            _store.Save();
        }

        private void SetCursor(string nodeId, bool notify)
        {
            _store.Data.currentNodeId = nodeId ?? "";
            _store.Save(notify);
        }

        private string ResolveContext(string sender = "")
        {
            if (!string.IsNullOrWhiteSpace(_store.Data.activeThreadId)) return _store.Data.activeThreadId;
            return SenderId(sender);
        }

        private void RaiseNotification(NotificationData notification)
        {
            _store.AddNotification(notification);
            NotificationRaised?.Invoke(notification);
        }

        private void StopWithError(string message)
        {
            Debug.LogError(message);
            _runner = null;
            IsWaitingForInteraction = false;
            FatalError?.Invoke(message);
        }

        private static string SenderId(string sender)
        {
            return string.IsNullOrWhiteSpace(sender) ? "unknown" : sender.Trim().ToLowerInvariant();
        }

        public static string CallerName(StoryNode node)
        {
            var name = node?.IncomingCall?.Call?.CallerName ?? node?.ActiveCall?.Call?.CallerName;
            return string.IsNullOrWhiteSpace(name) ? "Unknown" : name;
        }

        public static string CallerNumber(StoryNode node)
        {
            var number = node?.IncomingCall?.Call?.CallerNumber ?? node?.ActiveCall?.Call?.CallerNumber;
            return string.IsNullOrWhiteSpace(number) ? "Unknown Number" : number;
        }

        public static string CallAudioPath(StoryNode node)
        {
            return node?.IncomingCall?.Call?.AudioPath ?? node?.ActiveCall?.Call?.AudioPath ?? "";
        }
    }
}
