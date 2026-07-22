using System;
using System.Linq;
using Dreadmoor.Core;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEngine;
#if UNITY_ANDROID
using UnityEditor.Android;
#endif

namespace Dreadmoor.Editor
{
    /// <summary>Fails locally and in CI before a build can ship with a broken story edge.</summary>
    public sealed class DreadmoorBuildValidator : IPreprocessBuildWithReport
    {
        public int callbackOrder => -1000;

        public void OnPreprocessBuild(BuildReport report)
        {
            ValidateOrThrow();
            ConfigurePlayer();
        }

        [MenuItem("Dreadmoor/Validate Complete Game")]
        public static void ValidateMenu()
        {
            ValidateOrThrow();
            Debug.Log("Dreadmoor validation passed: all story nodes, choices, calls, media and scenes are linked.");
        }

        public static void ValidateOrThrow()
        {
            var graph = StoryGraph.LoadEpisodeOne();
            var result = graph.Validate();
            if (!result.IsValid) throw new BuildFailedException(result.ToString());
            if (graph.OrderedNodes.Count != 391)
                throw new BuildFailedException($"Expected 391 episode-one nodes but loaded {graph.OrderedNodes.Count}.");

            foreach (var node in graph.OrderedNodes)
            {
                ValidateResource(node.id, node.image_asset);
                ValidateResource(node.id, node.file_asset);
                ValidateResource(node.id, node.audio_loop);
                ValidateResource(node.id, node.audio_asset);
            }

            var required = new[]
            {
                "assets/branding/blackmoon_logo", "assets/branding/dreadmoor_logo",
                "assets/backgrounds/studio_intro_bg", "assets/backgrounds/welcome_bg_still",
                "assets/backgrounds/welcome_fog_loop", "assets/backgrounds/messenger_bg_texture",
                "assets/characters/rebecca_silhouette", "assets/ui/glitch_overlay", "assets/ui/notebook_paper",
                "assets/media/images/forest_moon_bg", "assets/media/images/moon_tower_hero",
                "assets/media/images/skull_noir_bg", "assets/media/headers/default_case",
                "assets/media/videos/intro_teaser", "assets/media/videos/title_intro",
                "assets/music/welcome_theme", "assets/media/sfx/message_receive",
                "assets/story/ep01/diary/page_01", "assets/fonts/noir_display", "assets/fonts/mono_glitch",
                "assets/icon/icon"
            };
            foreach (var path in required)
                if (Resources.Load<UnityEngine.Object>(path) == null)
                    throw new BuildFailedException("Required game resource is missing: " + path);

            var scenes = EditorBuildSettings.scenes.Where(scene => scene.enabled).ToArray();
            if (scenes.Length == 0 || scenes.All(scene => scene.path != "Assets/Scenes/Main.unity"))
                throw new BuildFailedException("Assets/Scenes/Main.unity must be enabled in Build Settings.");
        }

        private static void ValidateResource(string nodeId, string assetPath)
        {
            if (string.IsNullOrWhiteSpace(assetPath)) return;
            var resourcePath = Dreadmoor.UI.UIFactory.ResourcePath(assetPath);
            if (Resources.Load<UnityEngine.Object>(resourcePath) == null)
                throw new BuildFailedException($"{nodeId} references missing resource '{assetPath}' ({resourcePath}).");
        }

        private static void ConfigurePlayer()
        {
            PlayerSettings.companyName = "Blackmoon Studio";
            PlayerSettings.productName = "Dreadmoor";
            PlayerSettings.bundleVersion = "1.0.0";
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android, "com.blackmoonstudio.dreadmoor");
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.Portrait;
            PlayerSettings.allowedAutorotateToLandscapeLeft = false;
            PlayerSettings.allowedAutorotateToLandscapeRight = false;
            PlayerSettings.allowedAutorotateToPortrait = true;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26;
            PlayerSettings.Android.targetSdkVersion = AndroidSdkVersions.AndroidApiLevelAuto;
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
            PlayerSettings.Android.bundleVersionCode = 1;
            // GameCI fills the keystore path/password/alias from encrypted inputs.
            PlayerSettings.Android.useCustomKeystore = true;
            ConfigureAndroidIcons();
        }

        private static void ConfigureAndroidIcons()
        {
#if UNITY_ANDROID
            var source = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Resources/assets/icon/icon.png");
            if (source == null) return;
            SetAndroidIconKind(AndroidPlatformIconKind.Legacy, source);
            SetAndroidIconKind(AndroidPlatformIconKind.Round, source);
#endif
        }

#if UNITY_ANDROID
        private static void SetAndroidIconKind(PlatformIconKind kind, Texture2D source)
        {
            var slots = PlayerSettings.GetPlatformIcons(NamedBuildTarget.Android, kind);
            foreach (var slot in slots) slot.SetTexture(source);
            PlayerSettings.SetPlatformIcons(NamedBuildTarget.Android, kind, slots);
        }
#endif
    }
}
