using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using UnityEngine.Video;

namespace Dreadmoor.UI
{
    [Serializable]
    public sealed class MediaViewerItem
    {
        public string path = "";
        public string mediaType = "image";
        public string sender = "";
        public string caption = "";
        public string timestamp = "";

        public bool IsVideo => string.Equals(mediaType, "video", StringComparison.OrdinalIgnoreCase) ||
                               string.Equals(Path.GetExtension(path ?? ""), ".mp4", StringComparison.OrdinalIgnoreCase);

        public static MediaViewerItem From(MediaItemData item)
        {
            return new MediaViewerItem
            {
                path = item.filePath,
                mediaType = item.mediaType,
                sender = item.senderId,
                timestamp = item.createdUtc
            };
        }
    }

    /// <summary>
    /// Full-screen media gallery with paging, swipe gestures, video transport,
    /// time scrubber, auto-hiding chrome, captions and evidence metadata.
    /// </summary>
    public sealed class MediaViewerController : MonoBehaviour, IPointerClickHandler, IBeginDragHandler, IEndDragHandler
    {
        private readonly List<MediaViewerItem> _items = new List<MediaViewerItem>();
        private RectTransform _root;
        private RectTransform _stage;
        private RectTransform _topBar;
        private RectTransform _bottomBar;
        private Text _counter;
        private Text _metadata;
        private Text _timeCurrent;
        private Text _timeTotal;
        private Slider _scrubber;
        private Button _playButton;
        private RawImage _visual;
        private VideoPlayer _video;
        private AudioSource _videoAudio;
        private RenderTexture _target;
        private Action _onClose;
        private int _index;
        private bool _chromeVisible = true;
        private bool _settingSlider;
        private Vector2 _dragStart;
        private Coroutine _autoHide;

        public void Initialize(IReadOnlyList<MediaViewerItem> items, int initialIndex, Action onClose)
        {
            _root = transform as RectTransform;
            _items.Clear();
            if (items != null) _items.AddRange(items);
            _index = Mathf.Clamp(initialIndex, 0, Mathf.Max(0, _items.Count - 1));
            _onClose = onClose;
            BuildChrome();
            DisplayCurrent();
        }

        private void OnDestroy()
        {
            ReleaseVideo();
        }

        private void Update()
        {
            if (_video == null || !_video.isPrepared || _scrubber == null) return;
            var duration = Math.Max(0.001, _video.length);
            _settingSlider = true;
            _scrubber.value = (float)(_video.time / duration);
            _settingSlider = false;
            if (_timeCurrent != null) _timeCurrent.text = FormatTime(_video.time);
            if (_timeTotal != null) _timeTotal.text = FormatTime(_video.length);
            if (_playButton != null)
            {
                var text = _playButton.GetComponentInChildren<Text>();
                if (text != null) text.text = _video.isPlaying ? "Ⅱ" : "▶";
            }
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (eventData.dragging) return;
            SetChromeVisible(!_chromeVisible);
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            _dragStart = eventData.position;
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            var delta = eventData.position - _dragStart;
            if (Mathf.Abs(delta.x) < 90 || Mathf.Abs(delta.x) < Mathf.Abs(delta.y)) return;
            if (delta.x < 0) Next();
            else Previous();
        }

        private void BuildChrome()
        {
            var baseImage = gameObject.GetComponent<Image>() ?? gameObject.AddComponent<Image>();
            baseImage.color = Color.black;
            baseImage.raycastTarget = true;

            _stage = UIFactory.Rect(_root, "MediaStage", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            _visual = new GameObject("MediaVisual", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage))
                .GetComponent<RawImage>();
            _visual.transform.SetParent(_stage, false);
            UIFactory.Stretch(_visual.rectTransform);
            _visual.color = Color.white;
            _visual.raycastTarget = false;

            _topBar = UIFactory.Panel(_root, new Color(0, 0, 0, 0.78f), "MediaTopBar").rectTransform;
            SetAnchors(_topBar, 0, 1, 0.91f, 1);
            var close = UIFactory.Button(_topBar, "×", Close, Color.clear, Color.white, 75, 34, false);
            SetAnchors(close.GetComponent<RectTransform>(), 0.015f, 0.13f, 0.05f, 0.95f);
            _counter = UIFactory.Text(_topBar, "", 21, Color.white, TextAnchor.MiddleCenter, true);
            SetAnchors(_counter.rectTransform, 0.2f, 0.8f, 0.1f, 0.9f);
            var share = UIFactory.Button(_topBar, "INFO", ToggleMetadata, Color.clear, Color.white, 75, 17, false);
            SetAnchors(share.GetComponent<RectTransform>(), 0.82f, 0.985f, 0.05f, 0.95f);

            _bottomBar = UIFactory.Panel(_root, new Color(0, 0, 0, 0.82f), "MediaBottomBar").rectTransform;
            SetAnchors(_bottomBar, 0, 1, 0, 0.14f);
            var previous = UIFactory.Button(_bottomBar, "‹", Previous, Color.clear, Color.white, 78, 38, false);
            SetAnchors(previous.GetComponent<RectTransform>(), 0.01f, 0.12f, 0.03f, 0.65f);
            var next = UIFactory.Button(_bottomBar, "›", Next, Color.clear, Color.white, 78, 38, false);
            SetAnchors(next.GetComponent<RectTransform>(), 0.88f, 0.99f, 0.03f, 0.65f);
            _metadata = UIFactory.Text(_bottomBar, "", 17, new Color(1, 1, 1, 0.72f), TextAnchor.MiddleCenter);
            SetAnchors(_metadata.rectTransform, 0.13f, 0.87f, 0.02f, 0.38f);

            var transport = UIFactory.Rect(_bottomBar, "VideoTransport", new Vector2(0.13f, 0.4f), new Vector2(0.87f, 0.96f), Vector2.zero, Vector2.zero);
            _playButton = UIFactory.Button(transport, "▶", TogglePlayback, Color.clear, Color.white, 64, 25, false);
            SetAnchors(_playButton.GetComponent<RectTransform>(), 0, 0.1f, 0, 1);
            _timeCurrent = UIFactory.Text(transport, "00:00", 14, Color.white, TextAnchor.MiddleCenter);
            SetAnchors(_timeCurrent.rectTransform, 0.1f, 0.22f, 0, 1);
            _timeTotal = UIFactory.Text(transport, "00:00", 14, Color.white, TextAnchor.MiddleCenter);
            SetAnchors(_timeTotal.rectTransform, 0.88f, 1, 0, 1);
            _scrubber = BuildSlider(transport);
            SetAnchors(_scrubber.GetComponent<RectTransform>(), 0.23f, 0.87f, 0.2f, 0.8f);
            _scrubber.onValueChanged.AddListener(ScrubTo);

            var dots = UIFactory.Text(_root, "", 18, Color.white, TextAnchor.MiddleCenter);
            dots.name = "PageDots";
            SetAnchors(dots.rectTransform, 0.2f, 0.8f, 0.145f, 0.18f);
        }

        private Slider BuildSlider(Transform parent)
        {
            var root = UIFactory.Panel(parent, new Color(1, 1, 1, 0.25f), "Scrubber", true);
            var slider = root.gameObject.AddComponent<Slider>();
            slider.minValue = 0;
            slider.maxValue = 1;
            slider.wholeNumbers = false;
            var fillArea = UIFactory.Rect(root.transform, "FillArea", Vector2.zero, Vector2.one,
                new Vector2(4, 4), new Vector2(-4, -4));
            var fill = UIFactory.Panel(fillArea, UIFactory.Cyan, "Fill", true).rectTransform;
            UIFactory.Stretch(fill);
            var handleArea = UIFactory.Stretch(root.transform, "HandleArea");
            var handle = UIFactory.Panel(handleArea, Color.white, "Handle", true).rectTransform;
            handle.sizeDelta = new Vector2(26, 26);
            slider.fillRect = fill;
            slider.handleRect = handle;
            slider.targetGraphic = handle.GetComponent<Image>();
            slider.direction = Slider.Direction.LeftToRight;
            return slider;
        }

        private void DisplayCurrent()
        {
            ReleaseVideo();
            if (_items.Count == 0)
            {
                _visual.texture = null;
                _counter.text = "NO MEDIA";
                _metadata.text = "No evidence recovered.";
                SetTransportVisible(false);
                return;
            }

            _index = Mathf.Clamp(_index, 0, _items.Count - 1);
            var item = _items[_index];
            _counter.text = $"{_index + 1} / {_items.Count}";
            _metadata.text = BuildMetadata(item);
            var dots = transform.Find("PageDots")?.GetComponent<Text>();
            if (dots != null)
            {
                var value = "";
                for (var i = 0; i < _items.Count; i++) value += i == _index ? "● " : "○ ";
                dots.text = value.TrimEnd();
            }

            if (item.IsVideo) DisplayVideo(item.path);
            else DisplayImage(item.path);
            RestartAutoHide();
        }

        private void DisplayImage(string path)
        {
            _visual.texture = UIFactory.LoadTexture(path);
            _visual.color = _visual.texture != null ? Color.white : new Color(0.12f, 0.12f, 0.12f, 1);
            SetTransportVisible(false);
        }

        private void DisplayVideo(string path)
        {
            var clip = UIFactory.LoadVideo(path);
            if (clip == null)
            {
                _visual.texture = null;
                _metadata.text += "\nVIDEO FILE UNAVAILABLE";
                SetTransportVisible(false);
                return;
            }

            _target = new RenderTexture(1080, 1920, 0, RenderTextureFormat.ARGB32);
            _target.Create();
            _visual.texture = _target;
            _video = gameObject.AddComponent<VideoPlayer>();
            _videoAudio = gameObject.AddComponent<AudioSource>();
            _video.clip = clip;
            _video.playOnAwake = false;
            _video.isLooping = false;
            _video.renderMode = VideoRenderMode.RenderTexture;
            _video.targetTexture = _target;
            _video.audioOutputMode = VideoAudioOutputMode.AudioSource;
            _video.SetTargetAudioSource(0, _videoAudio);
            _video.prepareCompleted += player =>
            {
                if (player != _video) return;
                _timeTotal.text = FormatTime(player.length);
                player.Play();
            };
            _video.loopPointReached += player =>
            {
                if (player == _video) SetChromeVisible(true);
            };
            _video.Prepare();
            SetTransportVisible(true);
        }

        private void TogglePlayback()
        {
            if (_video == null || !_video.isPrepared) return;
            if (_video.isPlaying) _video.Pause();
            else _video.Play();
            RestartAutoHide();
        }

        private void ScrubTo(float normalized)
        {
            if (_settingSlider || _video == null || !_video.isPrepared) return;
            _video.time = Mathf.Clamp01(normalized) * _video.length;
            RestartAutoHide();
        }

        private void Next()
        {
            if (_items.Count <= 1) return;
            _index = (_index + 1) % _items.Count;
            DisplayCurrent();
        }

        private void Previous()
        {
            if (_items.Count <= 1) return;
            _index = (_index - 1 + _items.Count) % _items.Count;
            DisplayCurrent();
        }

        private void ToggleMetadata()
        {
            if (_metadata == null) return;
            _metadata.gameObject.SetActive(!_metadata.gameObject.activeSelf);
            RestartAutoHide();
        }

        private void Close()
        {
            ReleaseVideo();
            _onClose?.Invoke();
        }

        private void SetChromeVisible(bool visible)
        {
            _chromeVisible = visible;
            if (_topBar != null) _topBar.gameObject.SetActive(visible);
            if (_bottomBar != null) _bottomBar.gameObject.SetActive(visible);
            var dots = transform.Find("PageDots");
            if (dots != null) dots.gameObject.SetActive(visible && _items.Count > 1);
            if (visible) RestartAutoHide();
        }

        private void SetTransportVisible(bool visible)
        {
            if (_playButton != null) _playButton.gameObject.SetActive(visible);
            if (_scrubber != null) _scrubber.gameObject.SetActive(visible);
            if (_timeCurrent != null) _timeCurrent.gameObject.SetActive(visible);
            if (_timeTotal != null) _timeTotal.gameObject.SetActive(visible);
        }

        private void RestartAutoHide()
        {
            if (_autoHide != null) StopCoroutine(_autoHide);
            _autoHide = StartCoroutine(AutoHide());
        }

        private IEnumerator AutoHide()
        {
            yield return new WaitForSecondsRealtime(3.5f);
            if (_video != null && _video.isPlaying) SetChromeVisible(false);
            _autoHide = null;
        }

        private void ReleaseVideo()
        {
            if (_autoHide != null)
            {
                StopCoroutine(_autoHide);
                _autoHide = null;
            }
            if (_video != null)
            {
                _video.Stop();
                Destroy(_video);
                _video = null;
            }
            if (_videoAudio != null)
            {
                _videoAudio.Stop();
                Destroy(_videoAudio);
                _videoAudio = null;
            }
            if (_target != null)
            {
                _target.Release();
                Destroy(_target);
                _target = null;
            }
        }

        private static string BuildMetadata(MediaViewerItem item)
        {
            var sender = string.IsNullOrWhiteSpace(item.sender) ? "UNKNOWN SOURCE" : item.sender.ToUpperInvariant();
            var caption = string.IsNullOrWhiteSpace(item.caption) ? "RECOVERED EVIDENCE" : item.caption;
            return sender + "  •  " + caption;
        }

        private static string FormatTime(double seconds)
        {
            if (double.IsNaN(seconds) || double.IsInfinity(seconds) || seconds < 0) seconds = 0;
            var whole = Mathf.FloorToInt((float)seconds);
            return $"{whole / 60:00}:{whole % 60:00}";
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
