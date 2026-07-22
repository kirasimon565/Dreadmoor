using System;
using System.Collections.Generic;
using System.Linq;
using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    /// <summary>Messenger pill header with participant stack and profile routing.</summary>
    public sealed class ChatHeaderView : MonoBehaviour
    {
        private ThreadData _thread;
        private GameStore _store;
        private Action _back;
        private Action<string> _profile;

        public void Initialize(ThreadData thread, GameStore store, Action onBack, Action<string> onProfile)
        {
            _thread = thread;
            _store = store;
            _back = onBack;
            _profile = onProfile;
            Build();
        }

        private void Build()
        {
            var root = transform as RectTransform;
            var image = gameObject.GetComponent<Image>() ?? gameObject.AddComponent<Image>();
            image.color = _thread.isSecret
                ? new Color(0.24f, 0.01f, 0.02f, 0.96f)
                : new Color(0.02f, 0.1f, 0.16f, 0.96f);

            var back = UIFactory.Button(root, "‹", _back, Color.clear, Color.white, 80, 36, false);
            SetAnchors(back.GetComponent<RectTransform>(), 0.01f, 0.1f, 0.05f, 0.95f);

            var members = (_thread.members ?? new List<string>()).Where(member => member != "player").ToList();
            var titleRight = members.Count > 1 ? 0.72f : 0.82f;
            var title = UIFactory.Text(root, _thread.title.ToUpperInvariant(), 27, Color.white,
                TextAnchor.MiddleCenter, true);
            SetAnchors(title.rectTransform, 0.12f, titleRight, 0.34f, 0.94f);
            var subtitle = _thread.isSecret
                ? "VPN ACTIVE  /  ENCRYPTION HIGH"
                : members.Count > 1 ? members.Count + " PARTICIPANTS  •  ONLINE" : "ONLINE  •  SECURE CHANNEL";
            var status = UIFactory.Text(root, subtitle, 13,
                _thread.isSecret ? new Color(1, 0.36f, 0.3f) : UIFactory.Cyan, TextAnchor.UpperCenter);
            SetAnchors(status.rectTransform, 0.12f, titleRight, 0.04f, 0.4f);

            if (members.Count == 0) members.Add(_thread.id);
            if (members.Count == 1)
            {
                AddAvatar(root, members[0], 0.84f, 0.965f, 0.12f, 0.88f);
            }
            else
            {
                var visible = Mathf.Min(3, members.Count);
                for (var i = 0; i < visible; i++)
                {
                    var x = 0.7f + i * 0.085f;
                    AddAvatar(root, members[i], x, x + 0.12f, 0.13f, 0.87f);
                }
                if (members.Count > visible)
                {
                    var count = UIFactory.Text(root, "+" + (members.Count - visible), 13, Color.white,
                        TextAnchor.MiddleCenter, true);
                    SetAnchors(count.rectTransform, 0.92f, 0.99f, 0.08f, 0.32f);
                }
            }

            if (_thread.isSecret)
            {
                var signal = UIFactory.Panel(root, new Color(1, 0.1f, 0.08f, 0.7f), "SignalPulse", true);
                SetAnchors(signal.rectTransform, 0.025f, 0.038f, 0.18f, 0.82f);
                signal.gameObject.AddComponent<BreathingAnimator>().scaleAmount = 0.35f;
            }
        }

        private void AddAvatar(Transform parent, string characterId, float xMin, float xMax, float yMin, float yMax)
        {
            var character = _store.Character(characterId);
            var frame = UIFactory.Panel(parent, new Color(0.02f, 0.04f, 0.06f, 0.95f), "Avatar_" + characterId, true);
            SetAnchors(frame.rectTransform, xMin, xMax, yMin, yMax);
            var texture = UIFactory.LoadTexture(character.avatarPath);
            if (texture != null)
            {
                var raw = new GameObject("Portrait", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage))
                    .GetComponent<RawImage>();
                raw.transform.SetParent(frame.transform, false);
                UIFactory.Stretch(raw.rectTransform, 3);
                raw.texture = texture;
                raw.raycastTarget = false;
            }
            else
            {
                var fallback = UIFactory.Text(frame.transform, character.name.Substring(0, 1).ToUpperInvariant(), 21,
                    Color.white, TextAnchor.MiddleCenter, true);
                UIFactory.Stretch(fallback.rectTransform);
            }
            var button = frame.gameObject.AddComponent<Button>();
            button.onClick.AddListener(() => _profile?.Invoke(characterId));
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
