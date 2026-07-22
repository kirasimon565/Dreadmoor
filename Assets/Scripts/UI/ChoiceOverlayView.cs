using System;
using System.Collections;
using System.Linq;
using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    /// <summary>
    /// Expandable response composer. The collapsed state resembles the red
    /// quill input from the original UI; expanded state presents validated
    /// choices, participant silhouettes and send feedback.
    /// </summary>
    public sealed class ChoiceOverlayView : MonoBehaviour
    {
        private StoryNode _node;
        private ThreadData _thread;
        private Action<string, string> _submit;
        private LayoutElement _layout;
        private RectTransform _panel;
        private RectTransform _options;
        private Text _prompt;
        private Button _toggle;
        private bool _expanded;
        private bool _submitting;
        private Coroutine _blink;
        private Image _cursor;

        public event Action<bool> ExpandedChanged;

        public void Initialize(StoryNode node, ThreadData thread, Action<string, string> submit)
        {
            _node = node;
            _thread = thread;
            _submit = submit;
            Build();
            SetExpanded(false, false);
        }

        private void OnDestroy()
        {
            if (_blink != null) StopCoroutine(_blink);
        }

        private void Build()
        {
            var root = transform as RectTransform;
            _layout = gameObject.GetComponent<LayoutElement>() ?? gameObject.AddComponent<LayoutElement>();
            _panel = UIFactory.Panel(root, new Color(0.035f, 0.075f, 0.1f, 0.98f), "ChoiceComposer", true).rectTransform;
            UIFactory.Stretch(_panel);

            var topLine = UIFactory.Panel(_panel, UIFactory.EvidenceRed, "ChoiceAccent", true).rectTransform;
            topLine.anchorMin = new Vector2(0.04f, 0.94f);
            topLine.anchorMax = new Vector2(0.96f, 0.965f);
            topLine.offsetMin = Vector2.zero;
            topLine.offsetMax = Vector2.zero;

            _toggle = UIFactory.Button(_panel, "", Toggle, Color.clear, Color.white, 90, 20, false);
            var toggleRect = _toggle.GetComponent<RectTransform>();
            toggleRect.anchorMin = new Vector2(0.02f, 0.02f);
            toggleRect.anchorMax = new Vector2(0.98f, 0.94f);
            toggleRect.offsetMin = Vector2.zero;
            toggleRect.offsetMax = Vector2.zero;

            var quill = UIFactory.ContentImage(_panel, "assets/ui/quill_red.png", 70);
            quill.raycastTarget = false;
            quill.rectTransform.anchorMin = new Vector2(0.035f, 0.16f);
            quill.rectTransform.anchorMax = new Vector2(0.15f, 0.82f);
            quill.rectTransform.offsetMin = Vector2.zero;
            quill.rectTransform.offsetMax = Vector2.zero;

            _prompt = UIFactory.Text(_panel, "CHOOSE A REPLY...", 19,
                new Color(1, 1, 1, 0.72f), TextAnchor.MiddleLeft);
            _prompt.rectTransform.anchorMin = new Vector2(0.17f, 0.14f);
            _prompt.rectTransform.anchorMax = new Vector2(0.82f, 0.86f);
            _prompt.rectTransform.offsetMin = Vector2.zero;
            _prompt.rectTransform.offsetMax = Vector2.zero;

            _cursor = UIFactory.Panel(_panel, UIFactory.EvidenceRed, "ChoiceCursor", true);
            _cursor.rectTransform.anchorMin = new Vector2(0.84f, 0.28f);
            _cursor.rectTransform.anchorMax = new Vector2(0.85f, 0.72f);
            _cursor.rectTransform.offsetMin = Vector2.zero;
            _cursor.rectTransform.offsetMax = Vector2.zero;
            _blink = StartCoroutine(BlinkCursor());

            var arrow = UIFactory.Text(_panel, "⌃", 29, UIFactory.EvidenceRed, TextAnchor.MiddleCenter, true);
            arrow.name = "ExpandArrow";
            arrow.rectTransform.anchorMin = new Vector2(0.88f, 0.15f);
            arrow.rectTransform.anchorMax = new Vector2(0.97f, 0.85f);
            arrow.rectTransform.offsetMin = Vector2.zero;
            arrow.rectTransform.offsetMax = Vector2.zero;

            _options = UIFactory.Rect(root, "ChoiceOptions", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var optionLayout = _options.gameObject.AddComponent<VerticalLayoutGroup>();
            optionLayout.padding = new RectOffset(18, 18, 88, 20);
            optionLayout.spacing = 12;
            optionLayout.childControlHeight = true;
            optionLayout.childControlWidth = true;
            optionLayout.childForceExpandHeight = false;
            optionLayout.childForceExpandWidth = true;
            BuildOptions();
        }

        private void BuildOptions()
        {
            var memberStrip = UIFactory.Rect(_options, "ChoiceParticipants", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            UIFactory.Preferred(memberStrip.gameObject, 66);
            var participantLabel = _thread != null && _thread.members != null && _thread.members.Count > 1
                ? string.Join("  •  ", _thread.members.Select(member => member.ToUpperInvariant()))
                : (_thread?.title ?? "UNKNOWN").ToUpperInvariant();
            var participants = UIFactory.Text(memberStrip, "CHANNEL: " + participantLabel, 15,
                new Color(1, 1, 1, 0.48f), TextAnchor.MiddleLeft);
            UIFactory.Stretch(participants.rectTransform, 8);

            foreach (var option in _node?.options ?? Array.Empty<StoryChoice>())
            {
                if (option == null || string.IsNullOrWhiteSpace(option.Target)) continue;
                var capturedText = option.text;
                var capturedTarget = option.Target;
                var button = UIFactory.Button(_options, "›  " + capturedText, () => Submit(capturedText, capturedTarget),
                    new Color(0.055f, 0.14f, 0.18f, 0.98f), Color.white, 94, 19);
                var navigation = button.navigation;
                navigation.mode = Navigation.Mode.Automatic;
                button.navigation = navigation;
            }
        }

        private void Toggle()
        {
            if (_submitting) return;
            SetExpanded(!_expanded, true);
        }

        private void SetExpanded(bool expanded, bool notify)
        {
            _expanded = expanded;
            _options.gameObject.SetActive(expanded);
            _panel.gameObject.SetActive(true);
            var optionCount = _node?.options?.Length ?? 0;
            _layout.preferredHeight = expanded ? 170 + optionCount * 106 : 104;
            _layout.minHeight = _layout.preferredHeight;
            _prompt.text = expanded ? "SELECT RESPONSE" : "CHOOSE A REPLY...";
            var arrow = _panel.Find("ExpandArrow")?.GetComponent<Text>();
            if (arrow != null) arrow.text = expanded ? "⌄" : "⌃";
            if (notify) ExpandedChanged?.Invoke(expanded);
            LayoutRebuilder.ForceRebuildLayoutImmediate(transform.parent as RectTransform);
        }

        private void Submit(string text, string target)
        {
            if (_submitting) return;
            _submitting = true;
            _toggle.interactable = false;
            foreach (var button in _options.GetComponentsInChildren<Button>()) button.interactable = false;
            _prompt.text = "TRANSMITTING...";
            StartCoroutine(SubmitAfterFeedback(text, target));
        }

        private IEnumerator SubmitAfterFeedback(string text, string target)
        {
            yield return new WaitForSecondsRealtime(0.16f);
            _submit?.Invoke(text, target);
        }

        private IEnumerator BlinkCursor()
        {
            while (true)
            {
                if (_cursor != null) _cursor.enabled = !_cursor.enabled;
                yield return new WaitForSecondsRealtime(0.53f);
            }
        }
    }
}
