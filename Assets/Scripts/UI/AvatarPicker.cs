using System;
using UnityEngine;

namespace Dreadmoor.UI
{
    /// <summary>Android document picker bridge used by the player profile.</summary>
    public static class AvatarPicker
    {
        public static bool IsSupported
        {
            get
            {
#if UNITY_ANDROID && !UNITY_EDITOR
                return true;
#else
                return false;
#endif
            }
        }

        public static void PickImage(Action<string> unavailable = null)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            try
            {
                using (var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
                using (var activity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity"))
                using (var plugin = new AndroidJavaClass("com.blackmoonstudio.dreadmoor.DreadmoorGalleryPlugin"))
                {
                    plugin.CallStatic("pickImage", activity, "DreadmoorApplication", "OnAvatarPicked");
                }
            }
            catch (Exception exception)
            {
                Debug.LogError("Avatar picker failed: " + exception);
                unavailable?.Invoke(exception.Message);
            }
#else
            unavailable?.Invoke("Image selection is available in Android builds.");
#endif
        }
    }
}
