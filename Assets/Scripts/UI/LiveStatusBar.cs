using System;
using UnityEngine;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    [RequireComponent(typeof(Text))]
    public sealed class LiveClockText : MonoBehaviour
    {
        private Text _text;
        private int _lastSecond = -1;

        private void Awake()
        {
            _text = GetComponent<Text>();
            Refresh();
        }

        private void Update()
        {
            if (DateTime.Now.Second == _lastSecond) return;
            Refresh();
        }

        private void Refresh()
        {
            var now = DateTime.Now;
            _lastSecond = now.Second;
            _text.text = now.ToString("HH:mm");
        }
    }

    [RequireComponent(typeof(Text))]
    public sealed class DeviceStatusText : MonoBehaviour
    {
        private Text _text;
        private float _nextUpdate;

        private void Awake()
        {
            _text = GetComponent<Text>();
            Refresh();
        }

        private void Update()
        {
            if (Time.unscaledTime < _nextUpdate) return;
            Refresh();
        }

        private void Refresh()
        {
            _nextUpdate = Time.unscaledTime + 10f;
            var battery = SystemInfo.batteryLevel;
            var batteryText = battery < 0 ? "--" : Mathf.RoundToInt(battery * 100f).ToString();
            _text.text = "VPN  •  " + batteryText + "%";
        }
    }
}
