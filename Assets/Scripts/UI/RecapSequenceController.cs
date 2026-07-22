using System;
using System.Collections;
using System.Collections.Generic;
using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    /// <summary>Sequential "previously on" film-strip presentation.</summary>
    public sealed class RecapSequenceController : MonoBehaviour
    {
        private readonly List<GameObject> _lineObjects = new List<GameObject>();
        private IReadOnlyList<RecapLineData> _lines;
        private Action _continue;
        private ScrollRect _scroll;
        private RectTransform _content;
        private Button _continueButton;
        private Button _skipButton;
        private Coroutine _reveal;
        private bool _complete;

        public void Initialize(IReadOnlyList<RecapLineData> lines, Action onContinue)
        {
            _lines = lines ?? Array.Empty<RecapLineData>();
            _continue = onContinue;
            Build();
            _reveal = StartCoroutine(Reveal());
        }

        private void OnDestroy()
        {
            if (_reveal != null) StopCoroutine(_reveal);
        }

        private void Build()
        {
            var root = transform as RectTransform;
            var baseImage = gameObject.GetComponent<Image>() ?? gameObject.AddComponent<Image>();
            baseImage.color = UIFactory.Hex("#0A0908");

            var grainObject = new GameObject("FilmGrain", typeof(RectTransform), typeof(CanvasRenderer), typeof(FilmGrainGraphic));
            grainObject.transform.SetParent(root, false);
            var grain = grainObject.GetComponent<FilmGrainGraphic>();
            UIFactory.Stretch(grain.rectTransform);
            grain.color = new Color(1, 1, 1, 0.1f);
            grain.particles = 240;

            var header = UIFactory.Panel(root, new Color(0.04f, 0.035f, 0.03f, 0.97f), "RecapHeader").rectTransform;
            SetAnchors(header, 0, 1, 0.86f, 1);
            var small = UIFactory.Text(header, "CASE ARCHIVE  /  EPISODE 01", 16,
                new Color(1, 1, 1, 0.4f), TextAnchor.MiddleCenter);
            SetAnchors(small.rectTransform, 0.08f, 0.92f, 0.62f, 0.9f);
            var title = UIFactory.Text(header, "PREVIOUSLY IN DREADMOOR", 31, Color.white, TextAnchor.MiddleCenter, true);
            SetAnchors(title.rectTransform, 0.06f, 0.94f, 0.24f, 0.68f);
            var rule = UIFactory.Panel(header, UIFactory.EvidenceRed, "RedRule").rectTransform;
            SetAnchors(rule, 0.32f, 0.68f, 0.17f, 0.19f);
            _skipButton = UIFactory.Button(header, "SKIP", Skip, Color.clear, new Color(1, 1, 1, 0.55f), 55, 15, false);
            SetAnchors(_skipButton.GetComponent<RectTransform>(), 0.82f, 0.98f, 0.62f, 0.94f);

            var body = UIFactory.Rect(root, "RecapScroll", new Vector2(0.055f, 0.03f), new Vector2(0.945f, 0.86f), Vector2.zero, Vector2.zero);
            var background = UIFactory.Panel(body, new Color(0.12f, 0.105f, 0.085f, 0.86f), "FilmFrame");
            UIFactory.Stretch(background.rectTransform);
            _content = UIFactory.ScrollList(body, Color.clear, 18, 40);
            _scroll = body.GetComponentInChildren<ScrollRect>();
            BuildPerforations(body, true);
            BuildPerforations(body, false);

            foreach (var line in _lines)
            {
                var view = BuildLine(_content, line);
                view.SetActive(false);
                _lineObjects.Add(view);
            }

            _continueButton = UIFactory.Button(_content, "CONTINUE INVESTIGATION", Continue,
                UIFactory.EvidenceRed, Color.white, 92, 20);
            _continueButton.gameObject.SetActive(false);
        }

        private GameObject BuildLine(Transform parent, RecapLineData line)
        {
            switch (line.kind)
            {
                case RecapLineKind.Category:
                {
                    var label = UIFactory.Text(parent, line.text.ToUpperInvariant(), 21,
                        UIFactory.EvidenceRed, TextAnchor.MiddleLeft, true);
                    UIFactory.Preferred(label.gameObject, 68);
                    return label.gameObject;
                }
                case RecapLineKind.Cliffhanger:
                {
                    var panel = UIFactory.Panel(parent, new Color(0.34f, 0.02f, 0.025f, 0.95f), "Cliffhanger", true);
                    UIFactory.Preferred(panel.gameObject, Mathf.Max(120, line.text.Length * 1.45f));
                    var text = UIFactory.Text(panel.transform, line.text.ToUpperInvariant(), 28,
                        Color.white, TextAnchor.MiddleCenter, true);
                    UIFactory.Stretch(text.rectTransform, 24);
                    return panel.gameObject;
                }
                case RecapLineKind.Choice:
                {
                    var panel = UIFactory.Panel(parent, new Color(0.02f, 0.18f, 0.22f, 0.58f), "Choice", true);
                    UIFactory.Preferred(panel.gameObject, Mathf.Max(96, line.text.Length * 1.25f));
                    var text = UIFactory.Text(panel.transform, "→  " + line.text, 21,
                        UIFactory.Cyan, TextAnchor.MiddleLeft);
                    UIFactory.Stretch(text.rectTransform, 22);
                    return panel.gameObject;
                }
                case RecapLineKind.Evidence:
                {
                    var panel = UIFactory.Panel(parent, new Color(0.08f, 0.07f, 0.055f, 0.96f), "Evidence", true);
                    UIFactory.Preferred(panel.gameObject, Mathf.Max(110, line.text.Length * 1.35f));
                    var border = UIFactory.Panel(panel.transform, UIFactory.Caution, "EvidenceBorder", true).rectTransform;
                    SetAnchors(border, 0.015f, 0.025f, 0.1f, 0.9f);
                    var text = UIFactory.Text(panel.transform, "EVIDENCE  /  " + line.text, 20,
                        new Color(0.95f, 0.88f, 0.64f), TextAnchor.MiddleLeft);
                    SetAnchors(text.rectTransform, 0.055f, 0.95f, 0.08f, 0.92f);
                    return panel.gameObject;
                }
                default:
                {
                    var text = UIFactory.Text(parent, line.text, 22,
                        new Color(0.92f, 0.89f, 0.82f), TextAnchor.UpperLeft);
                    UIFactory.Preferred(text.gameObject, Mathf.Max(100, line.text.Length * 1.35f));
                    return text.gameObject;
                }
            }
        }

        private IEnumerator Reveal()
        {
            yield return new WaitForSecondsRealtime(0.4f);
            foreach (var item in _lineObjects)
            {
                item.SetActive(true);
                var group = item.GetComponent<CanvasGroup>() ?? item.AddComponent<CanvasGroup>();
                group.alpha = 0;
                var elapsed = 0f;
                while (elapsed < 0.28f)
                {
                    elapsed += Time.unscaledDeltaTime;
                    group.alpha = Mathf.Clamp01(elapsed / 0.28f);
                    yield return null;
                }
                group.alpha = 1;
                Canvas.ForceUpdateCanvases();
                if (_scroll != null) _scroll.verticalNormalizedPosition = 0;
                yield return new WaitForSecondsRealtime(0.27f);
            }
            CompleteReveal();
        }

        private void Skip()
        {
            if (_complete) return;
            if (_reveal != null)
            {
                StopCoroutine(_reveal);
                _reveal = null;
            }
            foreach (var item in _lineObjects)
            {
                item.SetActive(true);
                var group = item.GetComponent<CanvasGroup>();
                if (group != null) group.alpha = 1;
            }
            CompleteReveal();
        }

        private void CompleteReveal()
        {
            _complete = true;
            _skipButton.gameObject.SetActive(false);
            _continueButton.gameObject.SetActive(true);
            Canvas.ForceUpdateCanvases();
            if (_scroll != null) _scroll.verticalNormalizedPosition = 0;
        }

        private void Continue()
        {
            if (!_complete) return;
            _continue?.Invoke();
        }

        private static void BuildPerforations(RectTransform parent, bool left)
        {
            var rail = UIFactory.Rect(parent, left ? "LeftPerforations" : "RightPerforations",
                new Vector2(left ? 0.005f : 0.965f, 0), new Vector2(left ? 0.035f : 0.995f, 1), Vector2.zero, Vector2.zero);
            for (var i = 0; i < 14; i++)
            {
                var hole = UIFactory.Panel(rail, Color.black, "FilmHole", true).rectTransform;
                hole.anchorMin = new Vector2(0.12f, 0.015f + i / 14f);
                hole.anchorMax = new Vector2(0.88f, 0.045f + i / 14f);
                hole.offsetMin = Vector2.zero;
                hole.offsetMax = Vector2.zero;
            }
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
