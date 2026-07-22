using Dreadmoor.Core;
using UnityEngine;

namespace Dreadmoor.UI
{
    public static class DreadmoorHaptics
    {
        public static void Selection()
        {
            Vibrate(18, 55);
        }

        public static void Confirmation()
        {
            Vibrate(32, 105);
        }

        public static void HeavyImpact()
        {
            Vibrate(55, 180);
        }

        private static void Vibrate(long milliseconds, int amplitude)
        {
            if (!GameStore.Instance.Data.settings.haptics) return;
#if UNITY_ANDROID && !UNITY_EDITOR
            try
            {
                using (var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
                using (var activity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity"))
                using (var contextClass = new AndroidJavaClass("android.content.Context"))
                using (var vibrator = activity.Call<AndroidJavaObject>("getSystemService",
                           contextClass.GetStatic<string>("VIBRATOR_SERVICE")))
                using (var version = new AndroidJavaClass("android.os.Build$VERSION"))
                {
                    if (version.GetStatic<int>("SDK_INT") >= 26)
                    {
                        using (var effectClass = new AndroidJavaClass("android.os.VibrationEffect"))
                        using (var effect = effectClass.CallStatic<AndroidJavaObject>("createOneShot", milliseconds, amplitude))
                            vibrator.Call("vibrate", effect);
                    }
                    else
                    {
                        vibrator.Call("vibrate", milliseconds);
                    }
                }
            }
            catch
            {
                // Haptics are optional and must never interrupt story input.
            }
#endif
        }
    }
}
