using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    /// <summary>Episode dossier card with lock treatment, progress and staggered reveal.</summary>
    public sealed class EpisodeTeaserView : MonoBehaviour
    {
        private string _episodeId;
        private string _title;
        private string _description;
        private string _imagePath;
        private bool _locked;
        private bool _completed;
        private float _progress;
        private int _index;
        private Action _onOpen;
        private CanvasGroup _group;
        private RectTransform _rect;

        public void Initialize(string episodeId, string title, string description, string imagePath,
            bool locked, bool completed, float progress, int index, Action onOpen)
        {
            _episodeId = episodeId;
            _title = title;
            _description = description;
            _imagePath = imagePath;
            _locked = locked;
            _completed = completed;
            _progress = Mathf.Clamp01(progress);
            _index = index;
            _onOpen = onOpen;
            Build();
            StartCoroutine(Reveal());
        }

        private void Build()
        {
            _rect = transform as RectTransform;
            var layout = gameObject.GetComponent<LayoutElement>() ?? gameObject.AddComponent<LayoutElement>();
            layout.preferredHeight = 350;
            layout.minHeight = 350;
            var card = gameObject.GetComponent<Image>() ?? gameObject.AddComponent<Image>();
            card.color = UIFactory.Hex("#101820");
            card.sprite = BuildCardSprite();
            card.type = Image.Type.Sliced;
            var button = gameObject.GetComponent<Button>() ?? gameObject.AddComponent<Button>();
            button.interactable = !_locked;
            button.onClick.AddListener(() => _onOpen?.Invoke());
            _group = gameObject.GetComponent<CanvasGroup>() ?? gameObject.AddComponent<CanvasGroup>();

            var art = UIFactory.ContentImage(transform, _imagePath, 200);
            art.color = _locked ? new Color(0.25f, 0.25f, 0.25f, 0.72f) : Color.white;
            SetAnchors(art.rectTransform, 0, 0.42f, 0, 1);
            var artShade = UIFactory.Panel(art.transform, new Color(0, 0, 0, 0.28f), "ArtShade");
            UIFactory.Stretch(artShade.rectTransform);

            var episode = UIFactory.Text(transform, _episodeId.ToUpperInvariant(), 16,
                _locked ? new Color(1, 1, 1, 0.35f) : UIFactory.Cyan, TextAnchor.UpperLeft, true);
            SetAnchors(episode.rectTransform, 0.46f, 0.94f, 0.79f, 0.94f);
            var title = UIFactory.Text(transform, _title.ToUpperInvariant(), 27,
                _locked ? new Color(1, 1, 1, 0.45f) : Color.white, TextAnchor.UpperLeft, true);
            SetAnchors(title.rectTransform, 0.46f, 0.95f, 0.55f, 0.82f);
            var description = UIFactory.Text(transform, _description, 17,
                _locked ? new Color(1, 1, 1, 0.28f) : new Color(1, 1, 1, 0.64f), TextAnchor.UpperLeft);
            SetAnchors(description.rectTransform, 0.46f, 0.94f, 0.29f, 0.57f);

            var state = _locked ? "LOCKED" : _completed ? "REPLAY" : _progress > 0 ? "CONTINUE" : "START";
            var action = UIFactory.Text(transform, state, 17,
                _locked ? new Color(1, 1, 1, 0.3f) : UIFactory.EvidenceRed, TextAnchor.MiddleRight, true);
            SetAnchors(action.rectTransform, 0.72f, 0.94f, 0.06f, 0.23f);

            if (_locked)
            {
                var lockImage = UIFactory.ContentImage(transform, "assets/ui/locked_episode_overlay.png", 100);
                lockImage.color = new Color(1, 1, 1, 0.72f);
                SetAnchors(lockImage.rectTransform, 0, 0.42f, 0, 1);
            }
            else
            {
                BuildProgress();
            }

            var border = UIFactory.Panel(transform, _locked ? new Color(1, 1, 1, 0.12f) : UIFactory.Cyan,
                "EpisodeBorder", true).rectTransform;
            SetAnchors(border, 0.419f, 0.426f, 0.04f, 0.96f);
        }

        private void BuildProgress()
        {
            var label = UIFactory.Text(transform, $"PROGRESS  {Mathf.RoundToInt(_progress * 100):00}%", 14,
                new Color(1, 1, 1, 0.5f), TextAnchor.MiddleLeft);
            SetAnchors(label.rectTransform, 0.46f, 0.7f, 0.06f, 0.2f);
            var track = UIFactory.Panel(transform, new Color(1, 1, 1, 0.13f), "EpisodeProgress", true).rectTransform;
            SetAnchors(track, 0.46f, 0.7f, 0.035f, 0.06f);
            var fill = UIFactory.Panel(track, UIFactory.Cyan, "Fill", true).rectTransform;
            fill.anchorMin = Vector2.zero;
            fill.anchorMax = new Vector2(_progress, 1);
            fill.offsetMin = Vector2.zero;
            fill.offsetMax = Vector2.zero;
        }

        private IEnumerator Reveal()
        {
            _group.alpha = 0;
            _rect.localScale = Vector3.one * 0.95f;
            yield return new WaitForSecondsRealtime(_index * 0.12f);
            var elapsed = 0f;
            while (elapsed < 0.42f)
            {
                elapsed += Time.unscaledDeltaTime;
                var t = Mathf.Clamp01(elapsed / 0.42f);
                var ease = 1f - Mathf.Pow(1f - t, 3f);
                _group.alpha = ease;
                _rect.localScale = Vector3.one * Mathf.Lerp(0.95f, 1f, ease);
                yield return null;
            }
            _group.alpha = 1;
            _rect.localScale = Vector3.one;
        }

        private static Sprite _sprite;
        private static Sprite BuildCardSprite()
        {
            if (_sprite != null) return _sprite;
            const int size = 64;
            const int radius = 8;
            var texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var pixels = new Color32[size * size];
            for (var y = 0; y < size; y++)
            for (var x = 0; x < size; x++)
            {
                var dx = Mathf.Max(Mathf.Max(radius - x, 0), x - (size - radius - 1));
                var dy = Mathf.Max(Mathf.Max(radius - y, 0), y - (size - radius - 1));
                pixels[y * size + x] = dx * dx + dy * dy <= radius * radius
                    ? new Color32(255, 255, 255, 255)
                    : new Color32(255, 255, 255, 0);
            }
            texture.SetPixels32(pixels);
            texture.Apply();
            _sprite = Sprite.Create(texture, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100, 0,
                SpriteMeshType.FullRect, new Vector4(12, 12, 12, 12));
            return _sprite;
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
