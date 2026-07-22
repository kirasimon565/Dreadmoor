using System;
using System.Collections;
using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    /// <summary>
    /// Animated notification card matching the in-game phone banner. It queues
    /// its own dismissal, supports swipe-up, marks messages read and routes taps.
    /// </summary>
    public sealed class NotificationBannerView : MonoBehaviour, IPointerClickHandler, IBeginDragHandler, IEndDragHandler
    {
        public float visibleSeconds = 4.5f;
        public float animationSeconds = 0.3f;

        private RectTransform _rect;
        private CanvasGroup _group;
        private NotificationData _notification;
        private Action<NotificationData> _onOpen;
        private Action<string> _onRead;
        private Coroutine _lifetime;
        private Vector2 _dragStart;
        private bool _closing;
        private static Sprite _bannerSprite;

        public void Initialize(NotificationData notification, Action<NotificationData> onOpen, Action<string> onRead)
        {
            _notification = notification;
            _onOpen = onOpen;
            _onRead = onRead;
            Build();
            _lifetime = StartCoroutine(Lifetime());
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (_closing || _notification == null) return;
            _onRead?.Invoke(_notification.id);
            _onOpen?.Invoke(_notification);
            Close();
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            _dragStart = eventData.position;
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            var delta = eventData.position - _dragStart;
            if (delta.y > 55 || Mathf.Abs(delta.x) > 180) Close();
        }

        public void Close()
        {
            if (_closing) return;
            _closing = true;
            if (_lifetime != null) StopCoroutine(_lifetime);
            StartCoroutine(AnimateOut());
        }

        private void Build()
        {
            _rect = transform as RectTransform;
            if (_rect == null) _rect = gameObject.AddComponent<RectTransform>();
            _rect.anchorMin = new Vector2(0.035f, 0.85f);
            _rect.anchorMax = new Vector2(0.965f, 0.95f);
            _rect.offsetMin = Vector2.zero;
            _rect.offsetMax = Vector2.zero;

            var image = gameObject.GetComponent<Image>() ?? gameObject.AddComponent<Image>();
            image.sprite = CreateBannerSprite();
            image.type = Image.Type.Sliced;
            image.color = new Color(0.035f, 0.085f, 0.12f, 0.98f);
            image.raycastTarget = true;
            _group = gameObject.GetComponent<CanvasGroup>() ?? gameObject.AddComponent<CanvasGroup>();

            var accent = UIFactory.Panel(transform, AccentColor(), "NotificationAccent", true).rectTransform;
            SetAnchors(accent, 0.018f, 0.032f, 0.17f, 0.83f);

            var icon = UIFactory.Text(transform, NotificationIcon(), 31, AccentColor(), TextAnchor.MiddleCenter, true);
            SetAnchors(icon.rectTransform, 0.045f, 0.15f, 0.14f, 0.86f);

            var title = UIFactory.Text(transform, (_notification.title ?? "SYSTEM").ToUpperInvariant(), 19,
                AccentColor(), TextAnchor.UpperLeft, true);
            SetAnchors(title.rectTransform, 0.17f, 0.79f, 0.55f, 0.9f);

            var message = UIFactory.Text(transform, _notification.message ?? "", 18, Color.white, TextAnchor.UpperLeft);
            message.horizontalOverflow = HorizontalWrapMode.Wrap;
            SetAnchors(message.rectTransform, 0.17f, 0.92f, 0.1f, 0.57f);

            var time = UIFactory.Text(transform, "NOW", 14, new Color(1, 1, 1, 0.45f), TextAnchor.UpperRight);
            SetAnchors(time.rectTransform, 0.8f, 0.95f, 0.6f, 0.9f);
        }

        private IEnumerator Lifetime()
        {
            yield return AnimateIn();
            yield return new WaitForSecondsRealtime(visibleSeconds);
            _closing = true;
            yield return AnimateOutRoutine();
        }

        private IEnumerator AnimateIn()
        {
            var start = new Vector2(0, 230);
            var end = Vector2.zero;
            _rect.anchoredPosition = start;
            _group.alpha = 0;
            var elapsed = 0f;
            while (elapsed < animationSeconds)
            {
                elapsed += Time.unscaledDeltaTime;
                var t = EaseOut(Mathf.Clamp01(elapsed / animationSeconds));
                _rect.anchoredPosition = Vector2.LerpUnclamped(start, end, t);
                _group.alpha = t;
                yield return null;
            }
            _rect.anchoredPosition = end;
            _group.alpha = 1;
        }

        private IEnumerator AnimateOut()
        {
            yield return AnimateOutRoutine();
        }

        private IEnumerator AnimateOutRoutine()
        {
            var start = _rect.anchoredPosition;
            var end = new Vector2(0, 240);
            var elapsed = 0f;
            while (elapsed < animationSeconds)
            {
                elapsed += Time.unscaledDeltaTime;
                var t = Mathf.Clamp01(elapsed / animationSeconds);
                _rect.anchoredPosition = Vector2.Lerp(start, end, t * t);
                _group.alpha = 1f - t;
                yield return null;
            }
            Destroy(gameObject);
        }

        private string NotificationIcon()
        {
            if (_notification == null) return "!";
            switch (_notification.type)
            {
                case "chat": return "✉";
                case "article": return "N";
                default: return "!";
            }
        }

        private Color AccentColor()
        {
            if (_notification == null) return UIFactory.Cyan;
            switch (_notification.type)
            {
                case "article": return UIFactory.EvidenceRed;
                case "chat": return UIFactory.Cyan;
                default: return UIFactory.Caution;
            }
        }

        private static float EaseOut(float value)
        {
            var inverse = 1f - value;
            return 1f - inverse * inverse * inverse;
        }

        private static Sprite CreateBannerSprite()
        {
            if (_bannerSprite != null) return _bannerSprite;
            const int size = 64;
            var texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
            texture.name = "NotificationBannerShape";
            var pixels = new Color32[size * size];
            for (var y = 0; y < size; y++)
            for (var x = 0; x < size; x++)
            {
                var notch = y < 10 && x > 25 && x < 39 && y < Mathf.Abs(x - 32) * 0.7f;
                var cornerX = Mathf.Max(Mathf.Max(10 - x, 0), x - 53);
                var cornerY = Mathf.Max(Mathf.Max(10 - y, 0), y - 53);
                var rounded = cornerX * cornerX + cornerY * cornerY <= 100;
                pixels[y * size + x] = rounded && !notch
                    ? new Color32(255, 255, 255, 255)
                    : new Color32(255, 255, 255, 0);
            }
            texture.SetPixels32(pixels);
            texture.Apply();
            _bannerSprite = Sprite.Create(texture, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100, 0,
                SpriteMeshType.FullRect, new Vector4(14, 14, 14, 14));
            return _bannerSprite;
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
