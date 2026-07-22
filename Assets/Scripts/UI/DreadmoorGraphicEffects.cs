using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    /// <summary>Low-cost scanlines rendered in one uGUI mesh.</summary>
    public sealed class ScanlineGraphic : MaskableGraphic
    {
        [SerializeField] private float spacing = 7f;
        [SerializeField] private float thickness = 1f;

        public float Spacing
        {
            get => spacing;
            set { spacing = Mathf.Max(2f, value); SetVerticesDirty(); }
        }

        protected override void OnPopulateMesh(VertexHelper helper)
        {
            helper.Clear();
            var area = GetPixelAdjustedRect();
            var lineColor = color;
            for (var y = area.yMin; y < area.yMax; y += spacing)
                AddQuad(helper, new Rect(area.xMin, y, area.width, thickness), lineColor);
        }

        internal static void AddQuad(VertexHelper helper, Rect bounds, Color tint)
        {
            var start = helper.currentVertCount;
            var vertex = UIVertex.simpleVert;
            vertex.color = tint;
            vertex.position = new Vector3(bounds.xMin, bounds.yMin); helper.AddVert(vertex);
            vertex.position = new Vector3(bounds.xMin, bounds.yMax); helper.AddVert(vertex);
            vertex.position = new Vector3(bounds.xMax, bounds.yMax); helper.AddVert(vertex);
            vertex.position = new Vector3(bounds.xMax, bounds.yMin); helper.AddVert(vertex);
            helper.AddTriangle(start, start + 1, start + 2);
            helper.AddTriangle(start, start + 2, start + 3);
        }
    }

    /// <summary>Four-sided vignette with an animated pulse intensity.</summary>
    public sealed class VignetteGraphic : MaskableGraphic
    {
        [Range(0f, 1f)] public float intensity = 0.18f;
        [Range(0f, 0.5f)] public float borderFraction = 0.2f;
        public bool pulse;
        public float pulseSpeed = 1.2f;

        private void Update()
        {
            if (!pulse) return;
            SetVerticesDirty();
        }

        protected override void OnPopulateMesh(VertexHelper helper)
        {
            helper.Clear();
            var area = GetPixelAdjustedRect();
            var borderX = area.width * Mathf.Clamp(borderFraction, 0.02f, 0.5f);
            var borderY = area.height * Mathf.Clamp(borderFraction, 0.02f, 0.5f);
            var wave = pulse ? 0.75f + Mathf.Sin(Time.unscaledTime * pulseSpeed * Mathf.PI * 2f) * 0.25f : 1f;
            var tint = color;
            tint.a *= Mathf.Clamp01(intensity * wave);
            ScanlineGraphic.AddQuad(helper, new Rect(area.xMin, area.yMin, borderX, area.height), tint);
            ScanlineGraphic.AddQuad(helper, new Rect(area.xMax - borderX, area.yMin, borderX, area.height), tint);
            ScanlineGraphic.AddQuad(helper, new Rect(area.xMin + borderX, area.yMin, area.width - borderX * 2, borderY), tint);
            ScanlineGraphic.AddQuad(helper, new Rect(area.xMin + borderX, area.yMax - borderY, area.width - borderX * 2, borderY), tint);
        }
    }

    /// <summary>Animated waveform used by the active call and audio evidence UI.</summary>
    public sealed class AudioWaveformGraphic : MaskableGraphic
    {
        [Range(8, 96)] public int bars = 42;
        [Range(0.1f, 1f)] public float minimumHeight = 0.16f;
        public float speed = 2.4f;
        public float noiseAmount = 0.32f;
        public bool glitch = true;

        private readonly List<float> _phases = new List<float>();
        private readonly List<float> _scales = new List<float>();
        private float _nextGlitch;
        private int _glitchBar = -1;

        protected override void Awake()
        {
            base.Awake();
            BuildSeed();
            raycastTarget = false;
        }

        protected override void OnValidate()
        {
            BuildSeed();
            SetVerticesDirty();
        }

        private void Update()
        {
            if (_phases.Count != bars) BuildSeed();
            if (glitch && Time.unscaledTime >= _nextGlitch)
            {
                _nextGlitch = Time.unscaledTime + UnityEngine.Random.Range(0.08f, 0.55f);
                _glitchBar = UnityEngine.Random.value < 0.38f ? UnityEngine.Random.Range(0, bars) : -1;
            }
            SetVerticesDirty();
        }

        protected override void OnPopulateMesh(VertexHelper helper)
        {
            helper.Clear();
            if (bars <= 0) return;
            var area = GetPixelAdjustedRect();
            var slot = area.width / bars;
            var width = Mathf.Max(1f, slot * 0.5f);
            var center = area.center.y;
            for (var i = 0; i < bars; i++)
            {
                var waveA = Mathf.Sin(Time.unscaledTime * speed * _scales[i] + _phases[i]);
                var waveB = Mathf.Sin(Time.unscaledTime * speed * 0.43f + i * 0.63f);
                var normalized = minimumHeight + Mathf.Abs(waveA * 0.66f + waveB * 0.34f) * (1f - minimumHeight);
                if (i == _glitchBar) normalized = UnityEngine.Random.Range(0.75f, 1.3f);
                var height = Mathf.Clamp(area.height * normalized, 2f, area.height * 1.25f);
                var x = area.xMin + slot * i + (slot - width) * 0.5f;
                var tint = color;
                if (i == _glitchBar)
                {
                    tint.r = Mathf.Clamp01(tint.r + noiseAmount);
                    tint.a *= 0.7f;
                }
                ScanlineGraphic.AddQuad(helper, new Rect(x, center - height * 0.5f, width, height), tint);
            }
        }

        private void BuildSeed()
        {
            _phases.Clear();
            _scales.Clear();
            var random = new System.Random(1957 + bars);
            for (var i = 0; i < bars; i++)
            {
                _phases.Add((float)random.NextDouble() * Mathf.PI * 2f);
                _scales.Add(0.7f + (float)random.NextDouble() * 0.8f);
            }
        }
    }

    /// <summary>Film grain used by recap, title and fatal-error screens.</summary>
    public sealed class FilmGrainGraphic : MaskableGraphic
    {
        [Range(20, 500)] public int particles = 180;
        [Range(0.2f, 4f)] public float grainSize = 1.4f;
        public float framesPerSecond = 12f;
        private int _seed;
        private float _nextFrame;

        protected override void Awake()
        {
            base.Awake();
            raycastTarget = false;
        }

        private void Update()
        {
            if (Time.unscaledTime < _nextFrame) return;
            _nextFrame = Time.unscaledTime + 1f / Mathf.Max(1f, framesPerSecond);
            _seed++;
            SetVerticesDirty();
        }

        protected override void OnPopulateMesh(VertexHelper helper)
        {
            helper.Clear();
            var area = GetPixelAdjustedRect();
            var random = new System.Random(_seed * 48611 + 31);
            for (var i = 0; i < particles; i++)
            {
                var x = area.xMin + (float)random.NextDouble() * area.width;
                var y = area.yMin + (float)random.NextDouble() * area.height;
                var size = grainSize * (0.5f + (float)random.NextDouble());
                var tint = color;
                tint.a *= 0.25f + (float)random.NextDouble() * 0.75f;
                ScanlineGraphic.AddQuad(helper, new Rect(x, y, size, size), tint);
            }
        }
    }

    /// <summary>Scrambles text before settling, with optional recurring glitches.</summary>
    [RequireComponent(typeof(Text))]
    public sealed class GlitchTextAnimator : MonoBehaviour
    {
        public float revealDuration = 1.8f;
        public bool recurringGlitch;
        public float minimumGlitchInterval = 1.2f;
        public float maximumGlitchInterval = 4f;
        public int glitchFrames = 3;

        private const string Glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#@!%&*?/\\";
        private Text _label;
        private string _target;
        private float _start;
        private float _nextGlitch;
        private int _remainingFrames;
        private System.Random _random;

        private void Awake()
        {
            _label = GetComponent<Text>();
            _target = _label.text;
            _random = new System.Random(_target.GetHashCode());
            Restart();
        }

        public void SetText(string value, bool animate = true)
        {
            _target = value ?? "";
            if (_label == null) _label = GetComponent<Text>();
            if (animate) Restart();
            else _label.text = _target;
        }

        public void Restart()
        {
            _start = Time.unscaledTime;
            _nextGlitch = _start + UnityEngine.Random.Range(minimumGlitchInterval, maximumGlitchInterval);
            _remainingFrames = 0;
        }

        private void Update()
        {
            var progress = revealDuration <= 0 ? 1f : Mathf.Clamp01((Time.unscaledTime - _start) / revealDuration);
            if (progress < 1f)
            {
                _label.text = ScrambleByProgress(progress);
                return;
            }

            if (!recurringGlitch)
            {
                if (_label.text != _target) _label.text = _target;
                return;
            }

            if (_remainingFrames > 0)
            {
                _remainingFrames--;
                _label.text = CorruptRandomCharacters();
                return;
            }

            _label.text = _target;
            if (Time.unscaledTime >= _nextGlitch)
            {
                _remainingFrames = Mathf.Max(1, glitchFrames);
                _nextGlitch = Time.unscaledTime + UnityEngine.Random.Range(minimumGlitchInterval, maximumGlitchInterval);
            }
        }

        private string ScrambleByProgress(float progress)
        {
            var chars = _target.ToCharArray();
            var settled = Mathf.RoundToInt(chars.Length * progress);
            for (var i = settled; i < chars.Length; i++)
            {
                if (char.IsWhiteSpace(chars[i])) continue;
                chars[i] = Glyphs[(_remainingFrames * 7 + i * 13 + Mathf.FloorToInt(Time.unscaledTime * 30)) % Glyphs.Length];
            }
            return new string(chars);
        }

        private string CorruptRandomCharacters()
        {
            var chars = _target.ToCharArray();
            var changes = Mathf.Max(1, chars.Length / 7);
            for (var i = 0; i < changes; i++)
            {
                if (chars.Length == 0) break;
                var index = _random.Next(chars.Length);
                if (char.IsWhiteSpace(chars[index])) continue;
                chars[index] = Glyphs[_random.Next(Glyphs.Length)];
            }
            return new string(chars);
        }
    }

    /// <summary>Breathing scale/fade animation shared by logos and call controls.</summary>
    public sealed class BreathingAnimator : MonoBehaviour
    {
        public float scaleAmount = 0.025f;
        public float speed = 0.24f;
        public float minimumAlpha = 0.7f;
        public float maximumAlpha = 1f;
        public float startDelay;

        private Vector3 _initialScale;
        private CanvasGroup _group;
        private float _enabledAt;

        private void Awake()
        {
            _initialScale = transform.localScale;
            _group = GetComponent<CanvasGroup>();
            _enabledAt = Time.unscaledTime;
        }

        private void Update()
        {
            if (Time.unscaledTime - _enabledAt < startDelay) return;
            var value = (Mathf.Sin(Time.unscaledTime * speed * Mathf.PI * 2f) + 1f) * 0.5f;
            transform.localScale = _initialScale * (1f + value * scaleAmount);
            if (_group != null) _group.alpha = Mathf.Lerp(minimumAlpha, maximumAlpha, value);
        }
    }

    public sealed class CanvasFadeAnimator : MonoBehaviour
    {
        public float delay;
        public float duration = 0.8f;
        public float fromAlpha;
        public float toAlpha = 1f;
        public float fromScale = 0.96f;
        public float toScale = 1f;
        private CanvasGroup _group;
        private Vector3 _baseScale;

        private void Awake()
        {
            _group = GetComponent<CanvasGroup>() ?? gameObject.AddComponent<CanvasGroup>();
            _baseScale = transform.localScale;
            _group.alpha = fromAlpha;
            transform.localScale = _baseScale * fromScale;
        }

        private IEnumerator Start()
        {
            if (delay > 0) yield return new WaitForSecondsRealtime(delay);
            var elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.unscaledDeltaTime;
                var t = Mathf.Clamp01(elapsed / Mathf.Max(0.01f, duration));
                var ease = 1f - Mathf.Pow(1f - t, 3f);
                _group.alpha = Mathf.Lerp(fromAlpha, toAlpha, ease);
                transform.localScale = _baseScale * Mathf.Lerp(fromScale, toScale, ease);
                yield return null;
            }
            _group.alpha = toAlpha;
            transform.localScale = _baseScale * toScale;
        }
    }

    public sealed class GlitchOverlayAnimator : MonoBehaviour
    {
        public float intensity = 1f;
        public float framesPerSecond = 18f;
        private RawImage _image;
        private float _nextFrame;
        private Vector2 _basePosition;

        private void Awake()
        {
            _image = GetComponent<RawImage>();
            if (_image != null) _basePosition = _image.rectTransform.anchoredPosition;
        }

        private void Update()
        {
            if (_image == null || Time.unscaledTime < _nextFrame) return;
            _nextFrame = Time.unscaledTime + 1f / Mathf.Max(1f, framesPerSecond);
            _image.uvRect = new Rect(UnityEngine.Random.Range(-0.04f, 0.04f) * intensity,
                UnityEngine.Random.Range(-0.03f, 0.03f) * intensity, 1, 1);
            _image.rectTransform.anchoredPosition = _basePosition + new Vector2(
                UnityEngine.Random.Range(-12f, 12f), UnityEngine.Random.Range(-5f, 5f)) * intensity;
            var tint = _image.color;
            tint.a = UnityEngine.Random.Range(0.25f, 0.85f) * intensity;
            _image.color = tint;
        }
    }

    /// <summary>Three-dot typing pulse with deterministic staggered timing.</summary>
    public sealed class TypingDotsAnimator : MonoBehaviour
    {
        public Color color = Color.white;
        private readonly List<Image> _dots = new List<Image>();

        private void Awake()
        {
            for (var i = 0; i < 3; i++)
            {
                var dot = UIFactory.Panel(transform, color, "TypingDot", true);
                var rect = dot.rectTransform;
                rect.anchorMin = new Vector2(0.1f + i * 0.3f, 0.25f);
                rect.anchorMax = new Vector2(0.3f + i * 0.3f, 0.75f);
                rect.offsetMin = Vector2.zero;
                rect.offsetMax = Vector2.zero;
                _dots.Add(dot);
            }
        }

        private void Update()
        {
            for (var i = 0; i < _dots.Count; i++)
            {
                var value = (Mathf.Sin(Time.unscaledTime * 6f - i * 0.9f) + 1f) * 0.5f;
                var tint = color;
                tint.a *= Mathf.Lerp(0.3f, 1f, value);
                _dots[i].color = tint;
                _dots[i].rectTransform.localScale = Vector3.one * Mathf.Lerp(0.72f, 1.1f, value);
            }
        }
    }
}
