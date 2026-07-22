using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Video;

namespace Dreadmoor.UI
{
    /// <summary>Extracts and displays the first useful frame of a bundled video.</summary>
    [RequireComponent(typeof(RawImage))]
    public sealed class VideoThumbnailView : MonoBehaviour
    {
        private RawImage _image;
        private VideoPlayer _player;
        private RenderTexture _target;
        private Coroutine _timeout;

        public void Initialize(string assetPath)
        {
            _image = GetComponent<RawImage>();
            var clip = UIFactory.LoadVideo(assetPath);
            if (clip == null)
            {
                _image.color = new Color(0.08f, 0.08f, 0.08f, 1);
                return;
            }

            _target = new RenderTexture(512, 288, 0, RenderTextureFormat.ARGB32);
            _target.Create();
            _image.texture = _target;
            _player = gameObject.AddComponent<VideoPlayer>();
            _player.clip = clip;
            _player.playOnAwake = false;
            _player.isLooping = false;
            _player.audioOutputMode = VideoAudioOutputMode.None;
            _player.renderMode = VideoRenderMode.RenderTexture;
            _player.targetTexture = _target;
            _player.sendFrameReadyEvents = true;
            _player.prepareCompleted += Prepared;
            _player.frameReady += FrameReady;
            _player.errorReceived += Error;
            _player.Prepare();
            _timeout = StartCoroutine(Timeout());
        }

        private void Prepared(VideoPlayer player)
        {
            if (player != _player) return;
            player.time = Mathf.Min(0.2f, (float)player.length * 0.05f);
            player.Play();
        }

        private void FrameReady(VideoPlayer player, long frame)
        {
            if (player != _player || frame < 0) return;
            player.Pause();
            player.sendFrameReadyEvents = false;
            _image.color = Color.white;
            if (_timeout != null)
            {
                StopCoroutine(_timeout);
                _timeout = null;
            }
        }

        private void Error(VideoPlayer player, string error)
        {
            if (player != _player) return;
            Debug.LogWarning("Video thumbnail unavailable: " + error);
            _image.color = new Color(0.08f, 0.08f, 0.08f, 1);
        }

        private IEnumerator Timeout()
        {
            yield return new WaitForSecondsRealtime(5f);
            if (_player != null) _player.Pause();
            _timeout = null;
        }

        private void OnDestroy()
        {
            if (_timeout != null) StopCoroutine(_timeout);
            if (_player != null)
            {
                _player.Stop();
                Destroy(_player);
            }
            if (_target != null)
            {
                _target.Release();
                Destroy(_target);
            }
        }
    }
}
