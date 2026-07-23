using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TMPro;

namespace Dreadmoor.UI
{
    public static class UIFactory
    {
        public static readonly Color SlateBackground = Hex("#1E252B");
        public static readonly Color SlateSurface = Hex("#2A3239");
        public static readonly Color SlateHeader = Hex("#161C21");
        public static readonly Color SlateText = Hex("#E1E4E7");
        public static readonly Color SlateDim = Hex("#8F9BA3");
        public static readonly Color SlateBorder = Hex("#38434D");
        public static readonly Color PaperBackground = Hex("#F4ECD8");
        public static readonly Color PaperCard = Hex("#FAF6E9");
        public static readonly Color Ink = Hex("#2B2B2B");
        public static readonly Color EvidenceRed = Hex("#B71C1C");
        public static readonly Color Cyan = Hex("#00ACC1");
        public static readonly Color Caution = Hex("#FBC02D");
        public static readonly Color HeroButtonBg = new Color(10f / 255f, 18f / 255f, 24f / 255f, 0.75f);
        public static readonly Color InvestigatorCyan = Hex("#00E5FF");

        private static Font _displayFont;
        private static Font _bodyFont;
        private static Font _brandFont;
        private static Font _spaceFont;
        private static Sprite _roundedSprite;
        private static TMP_FontAsset _tmpFont;

        public static Font DisplayFont => _displayFont ?? (_displayFont = Resources.Load<Font>("assets/fonts/noir_display"));
        public static Font BodyFont => _bodyFont ?? (_bodyFont = Resources.Load<Font>("assets/fonts/mono_glitch"));
        public static Font BrandFont => _brandFont ?? (_brandFont = Resources.Load<Font>("assets/fonts/cinzel") ?? DisplayFont ?? BodyFont ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"));
        public static Font SpaceFont => _spaceFont ?? (_spaceFont = Resources.Load<Font>("assets/fonts/space_grotesk") ?? BodyFont ?? DisplayFont ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"));

        /// <summary>
        /// Runtime-built TextMeshPro font asset with an explicit fallback chain so EVERY welcome
        /// glyph is visible: the body font covers ASCII, the display font covers "▶" (U+25B6),
        /// and an OS symbol font covers "⚙" (U+2699) which neither bundled font ships.
        /// </summary>
        public static TMP_FontAsset TMPFont
        {
            get
            {
                if (_tmpFont != null) return _tmpFont;
                _tmpFont = CreateRuntimeFontAsset(SpaceFont ?? DisplayFont);
                if (_tmpFont == null) return null;

                var fallbacks = new List<TMP_FontAsset>();
                var display = CreateRuntimeFontAsset(DisplayFont);
                if (display != null && display != _tmpFont) fallbacks.Add(display);
                var symbols = CreateOsSymbolFontAsset();
                if (symbols != null) fallbacks.Add(symbols);
                _tmpFont.fallbackFontAssets = fallbacks;
                return _tmpFont;
            }
        }

        private static TMP_FontAsset CreateRuntimeFontAsset(Font font)
        {
            if (font == null) return null;
            try
            {
                var asset = TMP_FontAsset.CreateFontAsset(font);
                if (asset != null) asset.name = font.name + "_RuntimeTMP";
                return asset;
            }
            catch (Exception exception)
            {
                Debug.LogWarning("Runtime TMP font asset could not be created: " + exception.Message);
                return null;
            }
        }

        private static TMP_FontAsset CreateOsSymbolFontAsset()
        {
            try
            {
                var installed = Font.GetOSInstalledFontNames();
                if (installed == null || installed.Length == 0) return null;
                var candidates = new[]
                {
                    "Segoe UI Symbol", "Apple Symbols", "Noto Sans Symbols 2", "Noto Sans Symbols",
                    "Roboto", "DejaVu Sans", "Liberation Sans", "Arial Unicode MS", "Arial", "Helvetica"
                };
                var pick = candidates.FirstOrDefault(installed.Contains);
                if (string.IsNullOrEmpty(pick)) return null;
                var font = Font.CreateDynamicFontFromOSFont(pick, 42);
                return font == null ? null : CreateRuntimeFontAsset(font);
            }
            catch (Exception exception)
            {
                Debug.LogWarning("OS symbol TMP font unavailable: " + exception.Message);
                return null;
            }
        }

        public static Canvas CreateCanvas()
        {
            var canvasObject = new GameObject("DreadmoorCanvas", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 0;
            var scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080, 1920);
            scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
            scaler.matchWidthOrHeight = 0.5f;

            if (UnityEngine.Object.FindFirstObjectByType<EventSystem>() == null)
            {
                new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
            }
            return canvas;
        }

        public static RectTransform Rect(Transform parent, string name, Vector2 anchorMin, Vector2 anchorMax,
            Vector2 offsetMin, Vector2 offsetMax)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rect = go.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = offsetMin;
            rect.offsetMax = offsetMax;
            return rect;
        }

        public static RectTransform Stretch(Transform parent, string name)
        {
            return Rect(parent, name, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        }

        public static Image Panel(Transform parent, Color color, string name = "Panel", bool rounded = false)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            go.transform.SetParent(parent, false);
            var image = go.GetComponent<Image>();
            image.color = color;
            if (rounded)
            {
                image.sprite = RoundedSprite;
                image.type = Image.Type.Sliced;
            }
            return image;
        }

        public static Text Text(Transform parent, string value, int size, Color color, TextAnchor alignment = TextAnchor.MiddleLeft,
            bool display = false, string name = "Text")
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            go.transform.SetParent(parent, false);
            var text = go.GetComponent<Text>();
            text.text = value ?? "";
            text.font = (display ? DisplayFont : BodyFont) ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = size;
            text.color = color;
            text.alignment = alignment;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            text.lineSpacing = 1.15f;
            text.raycastTarget = false;
            return text;
        }

        /// <summary>
        /// TextMeshProUGUI with an explicitly assigned runtime TMP font (fallback chain included),
        /// single-line overflow rendering and no rich text parsing by default.
        /// </summary>
        public static TextMeshProUGUI TmpText(Transform parent, string value, float size, Color color,
            TextAlignmentOptions alignment = TextAlignmentOptions.Center, string name = "TmpText",
            FontStyles style = FontStyles.Normal)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(TextMeshProUGUI));
            go.transform.SetParent(parent, false);
            var text = go.GetComponent<TextMeshProUGUI>();
            text.text = value ?? "";
            var font = TMPFont;
            if (font != null) text.font = font;
            text.fontSize = size;
            text.color = color;
            text.alignment = alignment;
            text.fontStyle = style;
            text.enableWordWrapping = false;
            text.overflowMode = TextOverflowModes.Overflow;
            text.richText = false;
            text.raycastTarget = false;
            return text;
        }

        /// <summary>Sprite-backed Image (supports preserveAspect, unlike RawImage) for logo artwork.</summary>
        public static Image SpriteImage(Transform parent, string assetPath, string name = "SpriteImage")
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            go.transform.SetParent(parent, false);
            var image = go.GetComponent<Image>();
            var texture = LoadTexture(assetPath);
            if (texture != null)
                image.sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f));
            image.color = Color.white;
            image.preserveAspect = true;
            image.raycastTarget = false;
            return image;
        }

        public static Button Button(Transform parent, string label, Action onClick, Color color, Color textColor,
            float preferredHeight = 86f, int fontSize = 28, bool rounded = true)
        {
            var image = Panel(parent, color, "Button_" + label, rounded);
            var button = image.gameObject.AddComponent<Button>();
            var colors = button.colors;
            colors.normalColor = Color.white;
            colors.highlightedColor = new Color(0.88f, 0.94f, 1f, 1f);
            colors.pressedColor = new Color(0.72f, 0.8f, 0.84f, 1f);
            colors.disabledColor = new Color(0.5f, 0.5f, 0.5f, 0.45f);
            button.colors = colors;
            if (onClick != null) button.onClick.AddListener(() =>
            {
                DreadmoorHaptics.Selection();
                onClick();
            });
            var layout = image.gameObject.AddComponent<LayoutElement>();
            layout.preferredHeight = preferredHeight;
            layout.minHeight = preferredHeight;

            var text = Text(image.transform, label, fontSize, textColor, TextAnchor.MiddleCenter, false, "Label");
            Stretch(text.transform as RectTransform, 18f);
            return button;
        }

        /// <summary>
        /// Creates the Hero "CONTINUE / START GAME" action button matching the reference UI exactly:
        /// rounded dark semi-transparent container rgba(10,18,24,0.75) with a thin #00E5FF border,
        /// a cyan ▶ play icon on the left and a single-line bright-cyan TextMeshProUGUI label on the
        /// right. All content children use explicit RectTransform anchors/sizes (no layout group) and
        /// an assigned TMP font. No rich text tags (e.g. &lt;mspace&gt;) are used anywhere.
        /// </summary>
        public static Button CreateHeroActionButton(Transform parent, string label, Action onClick)
        {
            // Container: dark semi-transparent background with rounded corners.
            var container = Panel(parent, HeroButtonBg, "HeroActionButton", true);
            var containerLayout = container.gameObject.AddComponent<LayoutElement>();
            containerLayout.minHeight = 96f;
            containerLayout.preferredHeight = 128f;

            // Thin cyan border outline (#00E5FF).
            var outline = container.gameObject.AddComponent<Outline>();
            outline.effectColor = InvestigatorCyan;
            outline.effectDistance = new Vector2(1.5f, -1.5f);

            // Subtle outer cyan glow.
            var shadow = container.gameObject.AddComponent<Shadow>();
            shadow.effectColor = new Color(0f, 0.898f, 1f, 0.18f);
            shadow.effectDistance = new Vector2(0f, -6f);

            var button = container.gameObject.AddComponent<Button>();
            button.targetGraphic = container;
            var colors = button.colors;
            colors.normalColor = Color.white;
            colors.highlightedColor = new Color(0.05f, 0.15f, 0.2f, 0.85f);
            colors.pressedColor = new Color(0.02f, 0.1f, 0.15f, 0.9f);
            colors.disabledColor = new Color(0.5f, 0.5f, 0.5f, 0.45f);
            button.colors = colors;
            if (onClick != null) button.onClick.AddListener(() =>
            {
                DreadmoorHaptics.Selection();
                onClick();
            });

            // Centered content row with explicit rects — NO layout group, so the anchors below
            // stay exactly where we put them.
            var content = new GameObject("HeroButtonContent", typeof(RectTransform));
            var contentRect = (RectTransform)content.transform;
            contentRect.SetParent(container.transform, false);
            contentRect.anchorMin = new Vector2(0.5f, 0f);
            contentRect.anchorMax = new Vector2(0.5f, 1f);
            contentRect.pivot = new Vector2(0.5f, 0.5f);
            contentRect.offsetMin = new Vector2(-280f, 0f);
            contentRect.offsetMax = new Vector2(280f, 0f);

            // Left: cyan play triangle icon ▶ (bright cyan #00E5FF).
            var icon = TmpText(contentRect, "▶", 34, InvestigatorCyan,
                TextAlignmentOptions.Center, "PlayIcon", FontStyles.Bold);
            var iconRect = icon.rectTransform;
            iconRect.anchorMin = new Vector2(0f, 0f);
            iconRect.anchorMax = new Vector2(0f, 1f);
            iconRect.pivot = new Vector2(0.5f, 0.5f);
            iconRect.offsetMin = Vector2.zero;
            iconRect.offsetMax = new Vector2(84f, 0f);

            // Right: "CONTINUE"/"START GAME" label in bright cyan (#00E5FF) — single line,
            // explicit RectTransform anchors/size, assigned TMP font, no <mspace> tags.
            var text = TmpText(contentRect, (label ?? string.Empty).ToUpperInvariant(), 32, InvestigatorCyan,
                TextAlignmentOptions.Center, "ActionLabel", FontStyles.Bold);
            text.characterSpacing = 20f;
            text.enableWordWrapping = false;
            text.overflowMode = TextOverflowModes.Overflow;
            text.richText = false;
            var textFont = TMPFont;
            if (textFont != null) text.font = textFont;
            var textRect = text.rectTransform;
            textRect.anchorMin = new Vector2(0f, 0f);
            textRect.anchorMax = new Vector2(1f, 1f);
            textRect.pivot = new Vector2(0.5f, 0.5f);
            textRect.offsetMin = new Vector2(92f, 0f);
            textRect.offsetMax = new Vector2(-20f, 0f);

            return button;
        }

        public static InputField Input(Transform parent, string placeholder, bool numeric = false, float preferredHeight = 90f)
        {
            var image = Panel(parent, new Color(0.05f, 0.08f, 0.1f, 0.82f), "Input", true);
            var layout = image.gameObject.AddComponent<LayoutElement>();
            layout.preferredHeight = preferredHeight;
            layout.minHeight = preferredHeight;

            var input = image.gameObject.AddComponent<InputField>();
            var value = Text(image.transform, "", 30, SlateText, TextAnchor.MiddleLeft, false, "Value");
            var valueRect = value.rectTransform;
            valueRect.anchorMin = Vector2.zero;
            valueRect.anchorMax = Vector2.one;
            valueRect.offsetMin = new Vector2(28, 8);
            valueRect.offsetMax = new Vector2(-28, -8);
            value.supportRichText = false;
            var hint = Text(image.transform, placeholder, 26, new Color(SlateDim.r, SlateDim.g, SlateDim.b, 0.7f), TextAnchor.MiddleLeft, false, "Placeholder");
            var hintRect = hint.rectTransform;
            hintRect.anchorMin = Vector2.zero;
            hintRect.anchorMax = Vector2.one;
            hintRect.offsetMin = new Vector2(28, 8);
            hintRect.offsetMax = new Vector2(-28, -8);
            input.textComponent = value;
            input.placeholder = hint;
            input.lineType = InputField.LineType.SingleLine;
            input.contentType = numeric ? InputField.ContentType.Custom : InputField.ContentType.Standard;
            input.keyboardType = numeric ? TouchScreenKeyboardType.PhonePad : TouchScreenKeyboardType.Default;
            return input;
        }

        public static RectTransform Vertical(Transform parent, float spacing = 16f, float padding = 0f, string name = "Vertical")
        {
            var rect = Rect(parent, name, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var layout = rect.gameObject.AddComponent<VerticalLayoutGroup>();
            layout.spacing = spacing;
            layout.padding = new RectOffset((int)padding, (int)padding, (int)padding, (int)padding);
            layout.childAlignment = TextAnchor.UpperCenter;
            layout.childControlHeight = true;
            layout.childControlWidth = true;
            layout.childForceExpandHeight = false;
            layout.childForceExpandWidth = true;
            return rect;
        }

        public static RectTransform ScrollList(Transform parent, Color background, float spacing = 16f, float padding = 24f)
        {
            var root = Panel(parent, background, "ScrollView").gameObject;
            var rootRect = root.GetComponent<RectTransform>();
            rootRect.anchorMin = Vector2.zero;
            rootRect.anchorMax = Vector2.one;
            rootRect.offsetMin = Vector2.zero;
            rootRect.offsetMax = Vector2.zero;
            var scroll = root.AddComponent<ScrollRect>();
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Elastic;
            scroll.scrollSensitivity = 36f;

            var viewport = Panel(root.transform, Color.clear, "Viewport").gameObject;
            var viewportRect = viewport.GetComponent<RectTransform>();
            viewportRect.anchorMin = Vector2.zero;
            viewportRect.anchorMax = Vector2.one;
            viewportRect.offsetMin = Vector2.zero;
            viewportRect.offsetMax = Vector2.zero;
            viewport.AddComponent<RectMask2D>();

            var content = new GameObject("Content", typeof(RectTransform), typeof(VerticalLayoutGroup), typeof(ContentSizeFitter));
            content.transform.SetParent(viewport.transform, false);
            var contentRect = content.GetComponent<RectTransform>();
            contentRect.anchorMin = new Vector2(0, 1);
            contentRect.anchorMax = new Vector2(1, 1);
            contentRect.pivot = new Vector2(0.5f, 1);
            contentRect.offsetMin = Vector2.zero;
            contentRect.offsetMax = Vector2.zero;
            var vertical = content.GetComponent<VerticalLayoutGroup>();
            vertical.spacing = spacing;
            vertical.padding = new RectOffset((int)padding, (int)padding, (int)padding, (int)padding);
            vertical.childAlignment = TextAnchor.UpperCenter;
            vertical.childControlHeight = true;
            vertical.childControlWidth = true;
            vertical.childForceExpandHeight = false;
            vertical.childForceExpandWidth = true;
            var fitter = content.GetComponent<ContentSizeFitter>();
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            scroll.viewport = viewportRect;
            scroll.content = contentRect;
            return contentRect;
        }

        public static RawImage Background(Transform parent, string assetPath, Color tint)
        {
            var rawObject = new GameObject("Background", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage));
            rawObject.transform.SetParent(parent, false);
            var rect = rawObject.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            var image = rawObject.GetComponent<RawImage>();
            image.texture = LoadTexture(assetPath);
            image.color = tint;
            image.raycastTarget = false;
            return image;
        }

        public static RawImage ContentImage(Transform parent, string assetPath, float preferredHeight = 420f)
        {
            var rawObject = new GameObject("ContentImage", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage), typeof(LayoutElement));
            rawObject.transform.SetParent(parent, false);
            var raw = rawObject.GetComponent<RawImage>();
            raw.texture = LoadTexture(assetPath);
            raw.color = Color.white;
            raw.raycastTarget = false;
            rawObject.GetComponent<LayoutElement>().preferredHeight = preferredHeight;
            return raw;
        }

        public static Texture2D LoadTexture(string assetPath)
        {
            if (string.IsNullOrWhiteSpace(assetPath)) return null;
            if (File.Exists(assetPath))
            {
                try
                {
                    var bytes = File.ReadAllBytes(assetPath);
                    var texture = new Texture2D(2, 2, TextureFormat.RGBA32, false);
                    texture.name = "LocalProfileImage";
                    if (texture.LoadImage(bytes, true)) return texture;
                    UnityEngine.Object.Destroy(texture);
                }
                catch (Exception exception)
                {
                    Debug.LogWarning("Local image could not be loaded: " + exception.Message);
                }
            }
            return Resources.Load<Texture2D>(ResourcePath(assetPath));
        }

        public static AudioClip LoadAudio(string assetPath)
        {
            return Resources.Load<AudioClip>(ResourcePath(assetPath));
        }

        public static UnityEngine.Video.VideoClip LoadVideo(string assetPath)
        {
            return Resources.Load<UnityEngine.Video.VideoClip>(ResourcePath(assetPath));
        }

        public static TextAsset LoadText(string assetPath)
        {
            return Resources.Load<TextAsset>(ResourcePath(assetPath));
        }

        public static string ResourcePath(string assetPath)
        {
            if (string.IsNullOrWhiteSpace(assetPath)) return "";
            var path = assetPath.Replace('\\', '/').Trim();
            if (path.StartsWith("Assets/Resources/", StringComparison.OrdinalIgnoreCase)) path = path.Substring(17);
            path = path.TrimStart('/');
            if (!path.StartsWith("assets/", StringComparison.OrdinalIgnoreCase)) path = "assets/" + path;
            var extension = Path.GetExtension(path);
            if (!string.IsNullOrEmpty(extension)) path = path.Substring(0, path.Length - extension.Length);
            return path;
        }

        public static Color Hex(string value)
        {
            return ColorUtility.TryParseHtmlString(value, out var color) ? color : Color.white;
        }

        public static void Stretch(RectTransform rect, float inset = 0f)
        {
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = new Vector2(inset, inset);
            rect.offsetMax = new Vector2(-inset, -inset);
        }

        public static LayoutElement Preferred(GameObject gameObject, float height)
        {
            var layout = gameObject.GetComponent<LayoutElement>() ?? gameObject.AddComponent<LayoutElement>();
            layout.preferredHeight = height;
            layout.minHeight = height;
            return layout;
        }

        private static Sprite RoundedSprite
        {
            get
            {
                if (_roundedSprite != null) return _roundedSprite;
                const int size = 64;
                const int radius = 14;
                var texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
                texture.name = "GeneratedRoundedRectangle";
                texture.wrapMode = TextureWrapMode.Clamp;
                var pixels = new Color32[size * size];
                for (var y = 0; y < size; y++)
                for (var x = 0; x < size; x++)
                {
                    var dx = Mathf.Max(Mathf.Max(radius - x, 0), x - (size - radius - 1));
                    var dy = Mathf.Max(Mathf.Max(radius - y, 0), y - (size - radius - 1));
                    var opaque = dx * dx + dy * dy <= radius * radius;
                    pixels[y * size + x] = opaque ? new Color32(255, 255, 255, 255) : new Color32(255, 255, 255, 0);
                }
                texture.SetPixels32(pixels);
                texture.Apply();
                _roundedSprite = Sprite.Create(texture, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100,
                    0, SpriteMeshType.FullRect, new Vector4(18, 18, 18, 18));
                return _roundedSprite;
            }
        }
    }
}
