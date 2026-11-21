using System;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ZooThrow.UI
{
    public static class UITheme
    {
        public static readonly Color WindowBg = new Color(0.11f, 0.14f, 0.26f, 0.97f);
        public static readonly Color Card = new Color(0.16f, 0.2f, 0.36f, 1f);
        public static readonly Color CardLight = new Color(0.21f, 0.26f, 0.46f, 1f);
        public static readonly Color HudPill = new Color(0.08f, 0.1f, 0.2f, 0.78f);
        public static readonly Color Text = Color.white;
        public static readonly Color TextDim = new Color(0.72f, 0.77f, 0.9f);
        public static readonly Color Green = new Color(0.24f, 0.82f, 0.42f);
        public static readonly Color Yellow = new Color(1f, 0.79f, 0.24f);
        public static readonly Color Red = new Color(1f, 0.36f, 0.38f);
        public static readonly Color Blue = new Color(0.24f, 0.55f, 1f);
        public static readonly Color Purple = new Color(0.65f, 0.36f, 1f);
        public static readonly Color Orange = new Color(1f, 0.55f, 0.13f);
        public static readonly Color Grey = new Color(0.36f, 0.4f, 0.55f);
        public static readonly Color Money = new Color(0.45f, 1f, 0.5f);
        public static readonly Color Gold = new Color(1f, 0.82f, 0.25f);
    }

    /// <summary>Small widget wrappers so windows can update state without searching the hierarchy.</summary>
    public class UIButton
    {
        public Button button;
        public Image bg;
        public Image shade;
        public TextMeshProUGUI label;
        public Image icon;
        Color _color;

        public void SetColor(Color c)
        {
            _color = c;
            bg.color = c;
            shade.color = new Color(c.r * 0.62f, c.g * 0.62f, c.b * 0.62f, c.a);
        }

        public void SetState(string text, Color color, bool interactable)
        {
            if (label != null && label.text != text) label.text = text;
            if (_color != color) SetColor(color);
            button.interactable = interactable;
        }

        public void SetActive(bool v) => button.gameObject.SetActive(v);
    }

    public class UIBar
    {
        public RectTransform root;
        public RectTransform fill;
        public Image fillImage;
        float _value = -1f;

        public void Set(float v)
        {
            v = Mathf.Clamp01(v);
            if (Mathf.Abs(v - _value) < 0.0005f) return;
            _value = v;
            fill.anchorMax = new Vector2(Mathf.Max(0.001f, v), 1f);
        }
    }

    /// <summary>Hover/press feedback and click sound for buttons.</summary>
    public class ButtonFx : MonoBehaviour, IPointerEnterHandler, IPointerExitHandler, IPointerDownHandler, IPointerUpHandler
    {
        public Action onHoverSound;
        float _target = 1f, _scale = 1f;
        Selectable _sel;

        void Awake() => _sel = GetComponent<Selectable>();
        public void OnPointerEnter(PointerEventData e) { if (_sel == null || _sel.interactable) _target = 1.05f; }
        public void OnPointerExit(PointerEventData e) => _target = 1f;
        public void OnPointerDown(PointerEventData e) { if (_sel == null || _sel.interactable) _target = 0.94f; }
        public void OnPointerUp(PointerEventData e) => _target = 1.04f;
        void OnDisable() { _target = 1f; _scale = 1f; transform.localScale = Vector3.one; }

        void Update()
        {
            if (Mathf.Abs(_scale - _target) < 0.001f) return;
            _scale = Mathf.Lerp(_scale, _target, 1f - Mathf.Exp(-20f * Time.unscaledDeltaTime));
            transform.localScale = new Vector3(_scale, _scale, 1f);
        }
    }

    public static class UIFactory
    {
        public static Action ClickSound;

        public static RectTransform Rect(string name, Transform parent)
        {
            var go = new GameObject(name, typeof(RectTransform));
            go.layer = 5; // UI
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            return rt;
        }

        public static RectTransform Stretch(RectTransform rt, float left = 0, float top = 0, float right = 0, float bottom = 0)
        {
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = new Vector2(left, bottom);
            rt.offsetMax = new Vector2(-right, -top);
            return rt;
        }

        public static RectTransform Place(RectTransform rt, Vector2 anchor, Vector2 pivot, Vector2 pos, Vector2 size)
        {
            rt.anchorMin = rt.anchorMax = anchor;
            rt.pivot = pivot;
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
            return rt;
        }

        public static Image Panel(Transform parent, string name, Color color, int radius = 22)
        {
            var rt = Rect(name, parent);
            var img = rt.gameObject.AddComponent<Image>();
            img.sprite = radius > 0 ? SpriteFactory.Rounded(radius) : null;
            img.type = Image.Type.Sliced;
            img.color = color;
            return img;
        }

        public static Image Shadow(Transform parent, int radius = 22, float alpha = 0.45f, float spread = 18f)
        {
            var img = Panel(parent, "Shadow", new Color(0, 0, 0, alpha), 0);
            img.sprite = SpriteFactory.Soft(radius, 24);
            img.type = Image.Type.Sliced;
            img.raycastTarget = false;
            Stretch(img.rectTransform, -spread, -spread * 0.6f, -spread, -spread * 1.4f);
            img.transform.SetAsFirstSibling();
            return img;
        }

        public static TextMeshProUGUI Text(Transform parent, string text, float size, Color color, TextAlignmentOptions align = TextAlignmentOptions.Center, bool title = false, bool outline = false)
        {
            var rt = Rect("Text", parent);
            var t = rt.gameObject.AddComponent<TextMeshProUGUI>();
            t.font = title ? FontLibrary.Title : FontLibrary.Body;
            if (outline)
            {
                var m = title ? FontLibrary.TitleOutline : FontLibrary.BodyOutline;
                if (m != null) t.fontSharedMaterial = m;
            }
            t.fontSize = size;
            t.color = color;
            t.alignment = align;
            t.text = text;
            t.raycastTarget = false;
            t.enableWordWrapping = true;
            t.overflowMode = TextOverflowModes.Ellipsis;
            return t;
        }

        public static Image Icon(Transform parent, IconId id, Color color, float size)
        {
            var rt = Rect("Icon_" + id, parent);
            rt.sizeDelta = new Vector2(size, size);
            var img = rt.gameObject.AddComponent<Image>();
            img.sprite = SpriteFactory.Icon(id);
            img.color = color;
            img.raycastTarget = false;
            img.preserveAspect = true;
            return img;
        }

        public static RawImage Raw(Transform parent, Texture tex, float size)
        {
            var rt = Rect("Portrait", parent);
            rt.sizeDelta = new Vector2(size, size);
            var img = rt.gameObject.AddComponent<RawImage>();
            img.texture = tex;
            img.raycastTarget = false;
            return img;
        }

        public static UIButton Button(Transform parent, string label, Color color, Action onClick, float fontSize = 28f, IconId? icon = null, int radius = 18)
        {
            var rt = Rect("Button", parent);
            var shade = rt.gameObject.AddComponent<Image>();
            shade.sprite = SpriteFactory.Rounded(radius);
            shade.type = Image.Type.Sliced;
            var face = Panel(rt, "Face", color, radius);
            Stretch(face.rectTransform, 0, 0, 0, 6);
            face.raycastTarget = false;
            var b = rt.gameObject.AddComponent<Button>();
            b.targetGraphic = face;
            var colors = b.colors;
            colors.normalColor = Color.white;
            colors.highlightedColor = new Color(1.08f, 1.08f, 1.08f);
            colors.pressedColor = new Color(0.85f, 0.85f, 0.85f);
            colors.disabledColor = new Color(0.55f, 0.55f, 0.6f, 0.9f);
            colors.colorMultiplier = 1.2f;
            b.colors = colors;
            var nav = b.navigation;
            nav.mode = Navigation.Mode.None;
            b.navigation = nav;
            b.onClick.AddListener(() => { ClickSound?.Invoke(); onClick?.Invoke(); });
            rt.gameObject.AddComponent<ButtonFx>();
            var ui = new UIButton { button = b, bg = face, shade = shade };
            var content = Rect("Content", face.transform);
            Stretch(content, 10, 4, 10, 4);
            var h = content.gameObject.AddComponent<HorizontalLayoutGroup>();
            h.childAlignment = TextAnchor.MiddleCenter;
            h.spacing = 8;
            h.childControlWidth = true; h.childControlHeight = true;
            h.childForceExpandWidth = false; h.childForceExpandHeight = false;
            if (icon.HasValue)
            {
                ui.icon = Icon(content, icon.Value, Color.white, fontSize * 1.2f);
                var le = ui.icon.gameObject.AddComponent<LayoutElement>();
                le.preferredWidth = le.preferredHeight = fontSize * 1.2f;
            }
            if (label != null)
            {
                ui.label = Text(content, label, fontSize, Color.white, TextAlignmentOptions.Center, true, true);
                ui.label.enableWordWrapping = false;
                ui.label.overflowMode = TextOverflowModes.Overflow;
            }
            ui.SetColor(color);
            return ui;
        }

        public static UIBar Bar(Transform parent, Color bg, Color fill, int radius = 10)
        {
            var root = Panel(parent, "Bar", bg, radius);
            root.raycastTarget = false;
            var f = Panel(root.transform, "Fill", fill, radius);
            f.raycastTarget = false;
            f.rectTransform.anchorMin = Vector2.zero;
            f.rectTransform.anchorMax = new Vector2(0.5f, 1f);
            f.rectTransform.offsetMin = Vector2.zero;
            f.rectTransform.offsetMax = Vector2.zero;
            return new UIBar { root = root.rectTransform, fill = f.rectTransform, fillImage = f };
        }

        public static LayoutElement Layout(Component c, float prefW = -1, float prefH = -1, float flexW = -1, float flexH = -1, float minW = -1, float minH = -1)
        {
            var le = c.GetComponent<LayoutElement>();
            if (le == null) le = c.gameObject.AddComponent<LayoutElement>();
            le.preferredWidth = prefW; le.preferredHeight = prefH;
            le.flexibleWidth = flexW; le.flexibleHeight = flexH;
            le.minWidth = minW; le.minHeight = minH;
            return le;
        }

        public static HorizontalLayoutGroup HLayout(Component c, float spacing, RectOffset padding = null, TextAnchor align = TextAnchor.MiddleLeft, bool expandW = false, bool expandH = true)
        {
            var h = c.gameObject.AddComponent<HorizontalLayoutGroup>();
            h.spacing = spacing;
            h.padding = padding ?? new RectOffset();
            h.childAlignment = align;
            h.childControlWidth = true; h.childControlHeight = true;
            h.childForceExpandWidth = expandW; h.childForceExpandHeight = expandH;
            return h;
        }

        public static VerticalLayoutGroup VLayout(Component c, float spacing, RectOffset padding = null, TextAnchor align = TextAnchor.UpperCenter, bool expandW = true, bool expandH = false)
        {
            var v = c.gameObject.AddComponent<VerticalLayoutGroup>();
            v.spacing = spacing;
            v.padding = padding ?? new RectOffset();
            v.childAlignment = align;
            v.childControlWidth = true; v.childControlHeight = true;
            v.childForceExpandWidth = expandW; v.childForceExpandHeight = expandH;
            return v;
        }

        /// <summary>Vertical scroll view. Returns the content rect, which grows with its children.</summary>
        public static RectTransform Scroll(Transform parent, out ScrollRect scroll)
        {
            var root = Rect("Scroll", parent);
            scroll = root.gameObject.AddComponent<ScrollRect>();
            var bgImg = root.gameObject.AddComponent<Image>();
            bgImg.color = new Color(0, 0, 0, 0.001f); // raycast target for wheel/drag
            var viewport = Rect("Viewport", root);
            Stretch(viewport, 0, 0, 14, 0);
            viewport.gameObject.AddComponent<RectMask2D>();
            var content = Rect("Content", viewport);
            content.anchorMin = new Vector2(0, 1);
            content.anchorMax = new Vector2(1, 1);
            content.pivot = new Vector2(0.5f, 1f);
            content.offsetMin = content.offsetMax = Vector2.zero;
            var fitter = content.gameObject.AddComponent<ContentSizeFitter>();
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            scroll.viewport = viewport;
            scroll.content = content;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.scrollSensitivity = 40f;
            scroll.inertia = true;

            // Scrollbar
            var barRt = Rect("Scrollbar", root);
            barRt.anchorMin = new Vector2(1, 0); barRt.anchorMax = new Vector2(1, 1);
            barRt.pivot = new Vector2(1, 0.5f);
            barRt.sizeDelta = new Vector2(8, 0);
            barRt.anchoredPosition = Vector2.zero;
            var barBg = barRt.gameObject.AddComponent<Image>();
            barBg.sprite = SpriteFactory.Rounded(4); barBg.type = Image.Type.Sliced;
            barBg.color = new Color(1, 1, 1, 0.08f);
            var area = Rect("Sliding", barRt);
            Stretch(area);
            var handle = Panel(area, "Handle", new Color(1, 1, 1, 0.35f), 4);
            Stretch(handle.rectTransform);
            var sb = barRt.gameObject.AddComponent<Scrollbar>();
            sb.handleRect = handle.rectTransform;
            sb.targetGraphic = handle;
            sb.direction = Scrollbar.Direction.BottomToTop;
            scroll.verticalScrollbar = sb;
            scroll.verticalScrollbarVisibility = ScrollRect.ScrollbarVisibility.AutoHide;
            return content;
        }

        public static GridLayoutGroup Grid(RectTransform content, Vector2 cell, Vector2 spacing, int columns, RectOffset padding = null)
        {
            var g = content.gameObject.AddComponent<GridLayoutGroup>();
            g.cellSize = cell;
            g.spacing = spacing;
            g.constraint = GridLayoutGroup.Constraint.FixedColumnCount;
            g.constraintCount = columns;
            g.childAlignment = TextAnchor.UpperCenter;
            g.padding = padding ?? new RectOffset(4, 4, 4, 4);
            return g;
        }

        /// <summary>Horizontal slider with a value label callback.</summary>
        public static Slider Slider(Transform parent, Color fill, float value, Action<float> onChanged)
        {
            var root = Rect("Slider", parent);
            var s = root.gameObject.AddComponent<Slider>();
            var bg = Panel(root, "Background", new Color(1, 1, 1, 0.12f), 10);
            bg.rectTransform.anchorMin = new Vector2(0, 0.35f); bg.rectTransform.anchorMax = new Vector2(1, 0.65f);
            bg.rectTransform.offsetMin = bg.rectTransform.offsetMax = Vector2.zero;
            var fillArea = Rect("Fill Area", root);
            fillArea.anchorMin = new Vector2(0, 0.35f); fillArea.anchorMax = new Vector2(1, 0.65f);
            fillArea.offsetMin = new Vector2(0, 0); fillArea.offsetMax = new Vector2(0, 0);
            var f = Panel(fillArea, "Fill", fill, 10);
            f.rectTransform.anchorMin = Vector2.zero; f.rectTransform.anchorMax = new Vector2(0, 1);
            f.rectTransform.offsetMin = f.rectTransform.offsetMax = Vector2.zero;
            var handleArea = Rect("Handle Slide Area", root);
            Stretch(handleArea, 14, 0, 14, 0);
            var h = Panel(handleArea, "Handle", Color.white, 16);
            h.rectTransform.sizeDelta = new Vector2(30, 0);
            h.rectTransform.anchorMin = new Vector2(0, 0); h.rectTransform.anchorMax = new Vector2(0, 1);
            s.fillRect = f.rectTransform;
            s.handleRect = h.rectTransform;
            s.targetGraphic = h;
            s.direction = UnityEngine.UI.Slider.Direction.LeftToRight;
            s.minValue = 0; s.maxValue = 1;
            s.value = value;
            var nav = s.navigation; nav.mode = Navigation.Mode.None; s.navigation = nav;
            s.onValueChanged.AddListener(v => onChanged?.Invoke(v));
            return s;
        }
    }
}
