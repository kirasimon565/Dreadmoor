using System;
using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    /// <summary>
    /// Reusable message bubble supporting player/NPC alignment, group labels,
    /// system events, secret intercepts, image/video evidence and copy feedback.
    /// </summary>
    public sealed class ChatBubbleView : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IPointerExitHandler
    {
        private MessageData _message;
        private ThreadData _thread;
        private CharacterData _sender;
        private Action<MessageData> _openMedia;
        private LayoutElement _layout;
        private RectTransform _bubble;
        private float _pressStarted;
        private bool _pressing;
        private Text _copyHint;

        public void Initialize(MessageData message, ThreadData thread, CharacterData sender, Action<MessageData> openMedia)
        {
            _message = message;
            _thread = thread;
            _sender = sender;
            _openMedia = openMedia;
            Build();
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            _pressing = true;
            _pressStarted = Time.unscaledTime;
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            if (!_pressing) return;
            _pressing = false;
            if (Time.unscaledTime - _pressStarted >= 0.55f) CopyMessage();
        }

        public void OnPointerExit(PointerEventData eventData)
        {
            _pressing = false;
        }

        private void Build()
        {
            var root = transform as RectTransform;
            var isPlayer = _message.isPlayerMessage || _message.senderId == "player";
            var isSystem = _message.mediaType == "system_label" || _message.senderId == "system";
            var isMedia = _message.mediaType == "video" || _message.mediaType == "image";
            var height = CalculateHeight(_message, isSystem);
            _layout = gameObject.GetComponent<LayoutElement>() ?? gameObject.AddComponent<LayoutElement>();
            _layout.preferredHeight = height;
            _layout.minHeight = height;

            var hitArea = gameObject.GetComponent<Image>() ?? gameObject.AddComponent<Image>();
            hitArea.color = Color.clear;
            hitArea.raycastTarget = true;

            if (isSystem)
            {
                BuildSystemLabel(root);
                return;
            }

            if (!isPlayer && _thread.members != null && _thread.members.Count > 1) BuildAvatar(root);
            var left = isPlayer ? 0.2f : (_thread.members != null && _thread.members.Count > 1 ? 0.1f : 0.01f);
            var right = isPlayer ? 0.99f : 0.8f;
            _bubble = UIFactory.Panel(root, BubbleColor(isPlayer), "MessageBubble", true).rectTransform;
            SetAnchors(_bubble, left, right, 0.04f, 0.96f);

            var senderName = isPlayer ? "YOU" : (_sender?.name ?? _message.senderId).ToUpperInvariant();
            var sender = UIFactory.Text(_bubble, senderName, 15, SenderColor(isPlayer), TextAnchor.UpperLeft, true);
            SetAnchors(sender.rectTransform, 0.055f, 0.68f, 0.76f, 0.94f);
            var time = UIFactory.Text(_bubble, FormatGameTime(_message.gameMinutes), 13,
                new Color(1, 1, 1, 0.38f), TextAnchor.UpperRight);
            SetAnchors(time.rectTransform, 0.68f, 0.95f, 0.76f, 0.94f);

            if (isMedia) BuildMediaContent(_bubble);
            else BuildTextContent(_bubble);

            if (_message.isSecret || _thread.isSecret)
            {
                var secret = UIFactory.Text(_bubble, "ENCRYPTED", 11, new Color(1, 0.4f, 0.36f, 0.62f), TextAnchor.LowerRight);
                SetAnchors(secret.rectTransform, 0.68f, 0.95f, 0.02f, 0.15f);
            }

            _copyHint = UIFactory.Text(root, "COPIED", 12, UIFactory.Cyan, TextAnchor.MiddleCenter, true);
            SetAnchors(_copyHint.rectTransform, isPlayer ? 0.02f : 0.82f, isPlayer ? 0.18f : 0.98f, 0.38f, 0.62f);
            _copyHint.gameObject.SetActive(false);
        }

        private void BuildSystemLabel(RectTransform root)
        {
            var lineLeft = UIFactory.Panel(root, new Color(1, 1, 1, 0.16f), "SystemLineLeft").rectTransform;
            SetAnchors(lineLeft, 0.04f, 0.24f, 0.49f, 0.505f);
            var lineRight = UIFactory.Panel(root, new Color(1, 1, 1, 0.16f), "SystemLineRight").rectTransform;
            SetAnchors(lineRight, 0.76f, 0.96f, 0.49f, 0.505f);
            var text = UIFactory.Text(root, _message.content.ToUpperInvariant(), 14,
                new Color(1, 1, 1, 0.52f), TextAnchor.MiddleCenter, true);
            SetAnchors(text.rectTransform, 0.25f, 0.75f, 0.1f, 0.9f);
        }

        private void BuildAvatar(RectTransform root)
        {
            var avatarFrame = UIFactory.Panel(root, new Color(0, 0, 0, 0.45f), "SenderAvatar", true).rectTransform;
            SetAnchors(avatarFrame, 0.005f, 0.085f, 0.58f, 0.94f);
            var texture = !string.IsNullOrWhiteSpace(_sender?.avatarPath)
                ? UIFactory.LoadTexture(_sender.avatarPath)
                : null;
            if (texture != null)
            {
                var avatar = new GameObject("Avatar", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage))
                    .GetComponent<RawImage>();
                avatar.transform.SetParent(avatarFrame, false);
                UIFactory.Stretch(avatar.rectTransform, 3);
                avatar.texture = texture;
                avatar.raycastTarget = false;
            }
            else
            {
                var fallback = UIFactory.Text(avatarFrame, "?", 22, Color.white, TextAnchor.MiddleCenter, true);
                UIFactory.Stretch(fallback.rectTransform);
            }
        }

        private void BuildTextContent(RectTransform parent)
        {
            var text = UIFactory.Text(parent, _message.content ?? "", 20, Color.white, TextAnchor.UpperLeft);
            SetAnchors(text.rectTransform, 0.055f, 0.945f, 0.14f, 0.77f);
        }

        private void BuildMediaContent(RectTransform parent)
        {
            var preview = UIFactory.Panel(parent, new Color(0, 0, 0, 0.38f), "MediaPreview", true).rectTransform;
            SetAnchors(preview, 0.045f, 0.955f, 0.12f, 0.75f);
            Texture texture = null;
            if (_message.mediaType == "image") texture = UIFactory.LoadTexture(_message.mediaPath);
            if (texture != null)
            {
                var image = new GameObject("EvidenceImage", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage))
                    .GetComponent<RawImage>();
                image.transform.SetParent(preview, false);
                UIFactory.Stretch(image.rectTransform);
                image.texture = texture;
                image.raycastTarget = false;
            }
            else if (_message.mediaType == "video")
            {
                var thumbnail = new GameObject("VideoThumbnail", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage))
                    .GetComponent<RawImage>();
                thumbnail.transform.SetParent(preview, false);
                UIFactory.Stretch(thumbnail.rectTransform);
                thumbnail.color = new Color(0.08f, 0.08f, 0.08f, 1);
                thumbnail.raycastTarget = false;
                thumbnail.gameObject.AddComponent<VideoThumbnailView>().Initialize(_message.mediaPath);
                var play = UIFactory.Text(preview, "▶", 44, Color.white, TextAnchor.MiddleCenter, true);
                UIFactory.Stretch(play.rectTransform);
            }
            else
            {
                var label = UIFactory.Text(preview, "IMAGE EVIDENCE", 18, Color.white, TextAnchor.MiddleCenter, true);
                UIFactory.Stretch(label.rectTransform, 14);
            }
            var button = preview.gameObject.AddComponent<Button>();
            button.onClick.AddListener(() => _openMedia?.Invoke(_message));
            var file = UIFactory.Text(parent, FileLabel(_message.mediaPath), 12,
                new Color(1, 1, 1, 0.45f), TextAnchor.LowerLeft);
            SetAnchors(file.rectTransform, 0.055f, 0.75f, 0.015f, 0.12f);
        }

        private void CopyMessage()
        {
            if (string.IsNullOrWhiteSpace(_message.content)) return;
            GUIUtility.systemCopyBuffer = _message.content;
            if (_copyHint != null)
            {
                _copyHint.gameObject.SetActive(true);
                CancelInvoke(nameof(HideCopyHint));
                Invoke(nameof(HideCopyHint), 1.1f);
            }
        }

        private void HideCopyHint()
        {
            if (_copyHint != null) _copyHint.gameObject.SetActive(false);
        }

        private Color BubbleColor(bool isPlayer)
        {
            if (isPlayer) return new Color(0.015f, 0.32f, 0.4f, 0.97f);
            if (_thread.isSecret || _message.isSecret) return new Color(0.29f, 0.025f, 0.04f, 0.97f);
            return new Color(0.16f, 0.25f, 0.32f, 0.97f);
        }

        private Color SenderColor(bool isPlayer)
        {
            if (isPlayer) return new Color(0.68f, 0.94f, 1f, 0.85f);
            if (_thread.isSecret) return new Color(1f, 0.45f, 0.4f, 0.88f);
            if (!string.IsNullOrWhiteSpace(_sender?.colorHex) &&
                ColorUtility.TryParseHtmlString(_sender.colorHex, out var parsed))
            {
                parsed.r = Mathf.Max(parsed.r, 0.55f);
                parsed.g = Mathf.Max(parsed.g, 0.55f);
                parsed.b = Mathf.Max(parsed.b, 0.55f);
                return parsed;
            }
            return new Color(1, 1, 1, 0.72f);
        }

        private static float CalculateHeight(MessageData message, bool system)
        {
            if (system) return 70;
            if (message.mediaType == "video" || message.mediaType == "image") return 280;
            var lines = Mathf.Max(1, Mathf.CeilToInt((message.content?.Length ?? 0) / 34f));
            return Mathf.Clamp(94 + lines * 27, 112, 300);
        }

        private static string FileLabel(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) return "RECOVERED FILE";
            var normalized = path.Replace('\\', '/');
            var split = normalized.LastIndexOf('/');
            return (split >= 0 ? normalized.Substring(split + 1) : normalized).ToUpperInvariant();
        }

        private static string FormatGameTime(int gameMinutes)
        {
            var date = new DateTime(2016, 6, 12, 23, 42).AddMinutes(gameMinutes - GameStore.InitialGameMinutes);
            return date.ToString("HH:mm");
        }

        private static void SetAnchors(RectTransform rect, float xMin, float xMax, float yMin, float yMax)
        {
            rect.anchorMin = new Vector2(xMin, yMin);
            rect.anchorMax = new Vector2(xMax, yMax);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }
    }
}
