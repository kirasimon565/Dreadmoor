using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    public sealed partial class DreadmoorApp
    {
        private void ShowFatal(string message)
        {
            _scheduler?.Suspend();
            var root = NewScreen(AppView.Fatal, Color.black);
            var scanlineObject = new GameObject("Scanlines", typeof(RectTransform), typeof(CanvasRenderer), typeof(ScanlineGraphic));
            scanlineObject.transform.SetParent(root, false);
            var scanlines = scanlineObject.GetComponent<ScanlineGraphic>();
            UIFactory.Stretch(scanlines.rectTransform);
            scanlines.color = new Color(1, 1, 1, 0.035f);
            scanlines.Spacing = 7;
            var vignetteObject = new GameObject("FailureVignette", typeof(RectTransform), typeof(CanvasRenderer), typeof(VignetteGraphic));
            vignetteObject.transform.SetParent(root, false);
            var vignette = vignetteObject.GetComponent<VignetteGraphic>();
            UIFactory.Stretch(vignette.rectTransform);
            vignette.color = UIFactory.EvidenceRed;
            vignette.intensity = 0.34f;
            vignette.pulse = true;

            var icon = UIFactory.Text(root, "!", 74, UIFactory.EvidenceRed, TextAnchor.MiddleCenter, true);
            SetAnchors(icon.rectTransform, 0.4f, 0.6f, 0.72f, 0.84f);
            icon.gameObject.AddComponent<BreathingAnimator>().scaleAmount = 0.12f;
            var title = UIFactory.Text(root, "SYSTEM FAILURE", 41, UIFactory.EvidenceRed, TextAnchor.MiddleCenter, true);
            SetAnchors(title.rectTransform, 0.08f, 0.92f, 0.62f, 0.74f);
            var glitch = title.gameObject.AddComponent<GlitchTextAnimator>();
            glitch.revealDuration = 1.8f;
            glitch.recurringGlitch = true;
            var detail = UIFactory.Text(root,
                (string.IsNullOrWhiteSpace(message) ? "AN UNRECOVERABLE ERROR HAS OCCURRED." : message) +
                "\n\nERROR TRACE CAPTURED\nThe story cursor stopped before local data could be corrupted.",
                21, new Color(1, 1, 1, 0.76f), TextAnchor.MiddleCenter);
            SetAnchors(detail.rectTransform, 0.08f, 0.92f, 0.34f, 0.61f);
            var reset = UIFactory.Button(root, "REBOOT SYSTEM", ShowStudio, Color.clear, UIFactory.EvidenceRed, 92, 21);
            var resetImage = reset.GetComponent<Image>();
            resetImage.color = new Color(0.3f, 0.02f, 0.025f, 0.65f);
            SetAnchors(reset.GetComponent<RectTransform>(), 0.22f, 0.78f, 0.2f, 0.28f);
            if (Debug.isDebugBuild || Application.isEditor)
            {
                var debugTint = new Color(1f, 1f, 1f, 0.38f);
                var debugButton = UIFactory.Button(root, "OPEN DEBUG CONSOLE", () => ShowDebug(), Color.clear, debugTint, 62, 15, false);
                SetAnchors(debugButton.GetComponent<RectTransform>(), 0.3f, 0.7f, 0.1f, 0.15f);
            }
        }

    }
}
