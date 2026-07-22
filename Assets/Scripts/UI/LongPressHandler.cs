using System;
using UnityEngine;
using UnityEngine.EventSystems;

namespace Dreadmoor.UI
{
    public sealed class LongPressHandler : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IPointerExitHandler
    {
        public float holdSeconds = 0.75f;
        public Action Triggered;
        private bool _holding;
        private bool _triggered;
        private float _started;

        public void OnPointerDown(PointerEventData eventData)
        {
            _holding = true;
            _triggered = false;
            _started = Time.unscaledTime;
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            _holding = false;
        }

        public void OnPointerExit(PointerEventData eventData)
        {
            _holding = false;
        }

        private void Update()
        {
            if (!_holding || _triggered || Time.unscaledTime - _started < holdSeconds) return;
            _triggered = true;
            _holding = false;
            DreadmoorHaptics.HeavyImpact();
            Triggered?.Invoke();
        }
    }
}
