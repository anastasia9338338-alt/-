using System.Collections;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using ZooThrow.Core;

namespace ZooThrow.UI
{
    public enum WindowId { Animals, Shop, Upgrades, Collection, Settings }

    /// <summary>Modal window with a dimmed backdrop, header, close button and pop-in/out animation.</summary>
    public abstract class UIWindow : MonoBehaviour
    {
        public WindowId Id { get; private set; }
        public bool IsOpen { get; private set; }
        protected UIManager UI { get; private set; }
        protected GameManager G => GameManager.Instance;
        protected RectTransform Body { get; private set; }
        protected TextMeshProUGUI Subtitle { get; private set; }

        RectTransform _panel;
        CanvasGroup _group;
        Coroutine _anim;
        float _tickTimer;
        bool _dirty;

        public void Build(UIManager ui, WindowId id, string title, IconId icon, Color accent, Vector2 size)
        {
            UI = ui;
            Id = id;
            var root = (RectTransform)transform;
            UIFactory.Stretch(root);
            _group = gameObject.AddComponent<CanvasGroup>();

            var dim = UIFactory.Panel(root, "Dim", new Color(0.02f, 0.03f, 0.08f, 0.55f), 0);
            UIFactory.Stretch(dim.rectTransform);
            var dimButton = dim.gameObject.AddComponent<Button>();
            dimButton.transition = Selectable.Transition.None;
            dimButton.onClick.AddListener(() => UI.Close(Id));

            var panelImg = UIFactory.Panel(root, "Panel", UITheme.WindowBg, 28);
            _panel = panelImg.rectTransform;
            UIFactory.Place(_panel, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, size);
            UIFactory.Shadow(_panel, 28, 0.5f, 22f);

            var header = UIFactory.Panel(_panel, "Header", accent, 28);
            UIFactory.Place(header.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), Vector2.zero, new Vector2(size.x, 96f));
            header.raycastTarget = false;
            header.gameObject.AddComponent<VerticalGradient>().bottom = new Color(0.78f, 0.78f, 0.82f);
            var headerFix = UIFactory.Panel(header.transform, "HeaderBottom", accent, 0);
            headerFix.rectTransform.anchorMin = new Vector2(0, 0); headerFix.rectTransform.anchorMax = new Vector2(1, 0);
            headerFix.rectTransform.pivot = new Vector2(0.5f, 0); headerFix.rectTransform.sizeDelta = new Vector2(0, 28);
            headerFix.color = new Color(accent.r * 0.8f, accent.g * 0.8f, accent.b * 0.82f, 1f);
            headerFix.raycastTarget = false;

            var iconImg = UIFactory.Icon(header.transform, icon, Color.white, 58);
            UIFactory.Place(iconImg.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(30, 0), new Vector2(58, 58));
            var titleText = UIFactory.Text(header.transform, title, 46, Color.white, TextAlignmentOptions.MidlineLeft, true, true);
            UIFactory.Place(titleText.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(104, 4), new Vector2(size.x * 0.5f, 80));
            Subtitle = UIFactory.Text(header.transform, "", 26, new Color(1, 1, 1, 0.92f), TextAlignmentOptions.MidlineRight, false, true);
            UIFactory.Place(Subtitle.rectTransform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(-110, 2), new Vector2(size.x * 0.45f, 80));

            var close = UIFactory.Button(header.transform, null, UITheme.Red, () => UI.Close(Id), 30, IconId.Close, 16);
            UIFactory.Place((RectTransform)close.button.transform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(-22, 4), new Vector2(68, 64));

            Body = UIFactory.Rect("Body", _panel);
            UIFactory.Stretch(Body, 26, 112, 26, 24);
            BuildBody(Body);
            gameObject.SetActive(false);
        }

        protected abstract void BuildBody(RectTransform body);
        protected virtual void OnOpened() { }
        protected virtual void OnClosed() { }
        /// <summary>Called ~4 times a second while open (affordability, timers).</summary>
        protected virtual void Tick() { }
        /// <summary>Rebuild the list content. Called on open and after MarkDirty.</summary>
        protected virtual void Refresh() { }

        public void MarkDirty() { if (IsOpen) _dirty = true; }

        public void Open()
        {
            if (IsOpen) return;
            IsOpen = true;
            gameObject.SetActive(true);
            transform.SetAsLastSibling();
            Refresh();
            OnOpened();
            Tick();
            if (_anim != null) StopCoroutine(_anim);
            _anim = StartCoroutine(Animate(true));
        }

        public void Close()
        {
            if (!IsOpen) return;
            IsOpen = false;
            OnClosed();
            if (!gameObject.activeInHierarchy) return;
            if (_anim != null) StopCoroutine(_anim);
            _anim = StartCoroutine(Animate(false));
        }

        IEnumerator Animate(bool open)
        {
            float t = 0f, dur = open ? 0.22f : 0.14f;
            _group.blocksRaycasts = open;
            while (t < dur)
            {
                t += Time.unscaledDeltaTime;
                float k = Mathf.Clamp01(t / dur);
                float e = open ? Ease.OutBack(k) : 1f - Ease.InQuad(k);
                _group.alpha = open ? Mathf.Clamp01(k * 1.6f) : 1f - k;
                float s = Mathf.LerpUnclamped(0.85f, 1f, e);
                _panel.localScale = new Vector3(s, s, 1f);
                yield return null;
            }
            _group.alpha = open ? 1f : 0f;
            _panel.localScale = Vector3.one;
            if (!open) gameObject.SetActive(false);
            _anim = null;
        }

        void Update()
        {
            if (!IsOpen) return;
            if (_dirty) { _dirty = false; Refresh(); }
            _tickTimer += Time.unscaledDeltaTime;
            if (_tickTimer >= 0.25f) { _tickTimer = 0f; Tick(); }
        }
    }

    public static class Ease
    {
        public static float OutBack(float t) { const float c1 = 1.70158f, c3 = c1 + 1f; t -= 1f; return 1f + c3 * t * t * t + c1 * t * t; }
        public static float InQuad(float t) => t * t;
        public static float OutCubic(float t) { t = 1f - t; return 1f - t * t * t; }
    }

    /// <summary>Vertical gradient tint for any Graphic (multiplies vertex colours from top to bottom).</summary>
    public class VerticalGradient : BaseMeshEffect
    {
        public Color top = Color.white;
        public Color bottom = new Color(0.8f, 0.8f, 0.8f);

        public override void ModifyMesh(VertexHelper vh)
        {
            if (!IsActive() || vh.currentVertCount == 0) return;
            var rect = graphic.rectTransform.rect;
            UIVertex v = default;
            for (int i = 0; i < vh.currentVertCount; i++)
            {
                vh.PopulateUIVertex(ref v, i);
                float k = Mathf.InverseLerp(rect.yMin, rect.yMax, v.position.y);
                v.color = (Color32)((Color)v.color * Color.Lerp(bottom, top, k));
                vh.SetUIVertex(v, i);
            }
        }
    }
}
