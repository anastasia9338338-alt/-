using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using ZooThrow.Core;

namespace ZooThrow.UI
{
    /// <summary>Short notifications stacked under the top bar.</summary>
    public class ToastView : MonoBehaviour
    {
        class Toast { public RectTransform rt; public TextMeshProUGUI text; public Image bg; public float time; public bool active; }
        readonly List<Toast> _pool = new List<Toast>();
        static readonly Comparison<Toast> s_ByAge = (a, b) => a.time.CompareTo(b.time);
        RectTransform _root;

        public void Build(RectTransform layer)
        {
            _root = UIFactory.Rect("Toasts", layer);
            UIFactory.Place(_root, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0, -116), new Vector2(900, 400));
            for (int i = 0; i < 5; i++)
            {
                var bg = UIFactory.Panel(_root, "Toast", new Color(0.06f, 0.08f, 0.17f, 0.9f), 22);
                bg.raycastTarget = false;
                var t = UIFactory.Text(bg.transform, "", 28, Color.white, TextAlignmentOptions.Center, true, true);
                UIFactory.Stretch(t.rectTransform, 20, 0, 20, 0);
                bg.gameObject.SetActive(false);
                _pool.Add(new Toast { rt = bg.rectTransform, text = t, bg = bg });
            }
        }

        public void Show(string text, Color color)
        {
            Toast slot = null;
            float oldest = -1f;
            foreach (var t in _pool)
            {
                if (!t.active) { slot = t; break; }
                if (t.time > oldest) { oldest = t.time; slot = t; }
            }
            slot.active = true;
            slot.time = 0f;
            slot.text.text = text;
            slot.text.color = color;
            slot.rt.SetAsLastSibling();
            slot.rt.gameObject.SetActive(true);
        }

        void Update()
        {
            float dt = Time.unscaledDeltaTime;
            int index = 0;
            // Newest at the top: sort by age ascending.
            _pool.Sort(s_ByAge);
            foreach (var t in _pool)
            {
                if (!t.active) continue;
                t.time += dt;
                float w = Mathf.Min(900f, t.text.preferredWidth + 60f);
                float alpha = t.time < 0.2f ? t.time / 0.2f : t.time > 3f ? 1f - (t.time - 3f) / 0.4f : 1f;
                t.rt.anchorMin = t.rt.anchorMax = new Vector2(0.5f, 1f);
                t.rt.pivot = new Vector2(0.5f, 1f);
                t.rt.sizeDelta = new Vector2(w, 54f);
                var target = new Vector2(0, -index * 62f);
                t.rt.anchoredPosition = Vector2.Lerp(t.rt.anchoredPosition, target, 1f - Mathf.Exp(-14f * dt));
                var c = t.bg.color; c.a = 0.9f * Mathf.Clamp01(alpha); t.bg.color = c;
                var tc = t.text.color; tc.a = Mathf.Clamp01(alpha); t.text.color = tc;
                if (t.time > 3.4f) { t.active = false; t.rt.gameObject.SetActive(false); }
                index++;
            }
        }
    }

    /// <summary>Big centre banners (new biome, level up), shown one after another.</summary>
    public class BannerView : MonoBehaviour
    {
        struct Item { public string title, subtitle; public Color color; public float duration; public Audio.Sfx? sound; }
        readonly Queue<Item> _queue = new Queue<Item>();
        RectTransform _rt;
        Image _bg;
        TextMeshProUGUI _title, _subtitle;
        float _time = -1f, _duration;
        public bool Busy => _time >= 0f || _queue.Count > 0;

        public void Build(RectTransform layer)
        {
            _bg = UIFactory.Panel(layer, "Banner", Color.white, 30);
            _bg.raycastTarget = false;
            _rt = _bg.rectTransform;
            UIFactory.Place(_rt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, 250), new Vector2(1000, 190));
            _bg.gameObject.AddComponent<VerticalGradient>().bottom = new Color(0.7f, 0.7f, 0.75f);
            _title = UIFactory.Text(_rt, "", 40, Color.white, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(_title.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0, -14), new Vector2(980, 56));
            _subtitle = UIFactory.Text(_rt, "", 72, Color.white, TextAlignmentOptions.Center, true, true);
            _subtitle.enableWordWrapping = false;
            UIFactory.Place(_subtitle.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 18), new Vector2(980, 100));
            _rt.gameObject.SetActive(false);
        }

        public void Enqueue(string title, string subtitle, Color color, float duration, Audio.Sfx? sound = null)
        {
            _queue.Enqueue(new Item { title = title, subtitle = subtitle, color = color, duration = duration, sound = sound });
        }

        void Update()
        {
            var g = GameManager.Instance;
            if (_time < 0f)
            {
                if (_queue.Count == 0 || (g != null && g.UI.RewardModalOpen)) return;
                var it = _queue.Dequeue();
                _title.text = it.title;
                _subtitle.text = it.subtitle;
                _subtitle.fontSize = it.subtitle.Length > 24 ? 40 : 72;
                _bg.color = new Color(it.color.r, it.color.g, it.color.b, 0.95f);
                _duration = it.duration;
                _time = 0f;
                _rt.gameObject.SetActive(true);
                if (it.sound.HasValue && g != null) g.Sound.Play(it.sound.Value);
            }
            _time += Time.unscaledDeltaTime;
            float inK = Mathf.Clamp01(_time / 0.35f), outK = Mathf.Clamp01((_time - _duration) / 0.3f);
            float s = Mathf.LerpUnclamped(0.6f, 1f, Ease.OutBack(inK)) * (1f - outK * 0.2f);
            _rt.localScale = new Vector3(s, s, 1f);
            var c = _bg.color; c.a = 0.95f * (1f - outK); _bg.color = c;
            _title.alpha = 1f - outK; _subtitle.alpha = 1f - outK;
            if (_time > _duration + 0.3f) { _rt.gameObject.SetActive(false); _time = -1f; }
        }
    }

    /// <summary>Modal confirm / message dialog.</summary>
    public class DialogView : MonoBehaviour
    {
        RectTransform _root;
        TextMeshProUGUI _title, _text;
        UIButton _yes, _no;
        Action _onYes;
        public bool IsOpen { get; private set; }

        public void Build(UIManager ui, RectTransform layer)
        {
            var dim = UIFactory.Panel(layer, "Dialog", new Color(0.02f, 0.02f, 0.06f, 0.7f), 0);
            _root = dim.rectTransform;
            UIFactory.Stretch(_root);
            var panel = UIFactory.Panel(_root, "Panel", UITheme.WindowBg, 28);
            UIFactory.Place(panel.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(820, 440));
            UIFactory.Shadow(panel.rectTransform, 28, 0.5f, 20f);
            _title = UIFactory.Text(panel.transform, "", 46, Color.white, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(_title.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0, -30), new Vector2(760, 64));
            _text = UIFactory.Text(panel.transform, "", 30, UITheme.TextDim, TextAlignmentOptions.Center, false, true);
            UIFactory.Place(_text.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, 20), new Vector2(740, 180));
            var row = UIFactory.Rect("Buttons", panel.transform);
            UIFactory.Place(row, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 36), new Vector2(760, 96));
            UIFactory.HLayout(row, 24, null, TextAnchor.MiddleCenter, false, false);
            _no = UIFactory.Button(row, "ОТМЕНА", UITheme.Grey, Cancel, 32, null, 22);
            UIFactory.Layout(_no.button, 300, 90);
            _yes = UIFactory.Button(row, "ДА", UITheme.Green, Accept, 32, null, 22);
            UIFactory.Layout(_yes.button, 300, 90);
            _root.gameObject.SetActive(false);
        }

        public void Confirm(string title, string text, string yes, Color yesColor, Action onYes)
        {
            Show(title, text, yes, yesColor, onYes, true);
        }

        public void Message(string title, string text, string ok, Action onOk)
        {
            Show(title, text, ok, UITheme.Green, onOk, false);
        }

        void Show(string title, string text, string yes, Color yesColor, Action onYes, bool cancelable)
        {
            _title.text = title;
            _text.text = text;
            _yes.label.text = yes;
            _yes.SetColor(yesColor);
            _no.SetActive(cancelable);
            _onYes = onYes;
            IsOpen = true;
            _root.gameObject.SetActive(true);
            _root.SetAsLastSibling();
        }

        void Accept()
        {
            var cb = _onYes;
            Hide();
            cb?.Invoke();
        }

        public void Cancel()
        {
            if (!_no.button.gameObject.activeSelf) { Accept(); return; }
            Hide();
        }

        void Hide()
        {
            IsOpen = false;
            _onYes = null;
            _root.gameObject.SetActive(false);
        }
    }

    /// <summary>Floating texts anchored to world positions ("+$5", "+3 опыта").</summary>
    public class WorldPopups : MonoBehaviour
    {
        class Popup { public RectTransform rt; public TextMeshProUGUI text; public Vector3 world; public float time; public bool active; public float scale; }
        readonly List<Popup> _pool = new List<Popup>();
        RectTransform _layer;
        Camera _cam;

        public void Init(RectTransform layer)
        {
            _layer = layer;
            for (int i = 0; i < 24; i++)
            {
                var t = UIFactory.Text(layer, "", 34, Color.white, TextAlignmentOptions.Center, true, true);
                t.enableWordWrapping = false;
                t.rectTransform.sizeDelta = new Vector2(400, 60);
                t.gameObject.SetActive(false);
                _pool.Add(new Popup { rt = t.rectTransform, text = t });
            }
        }

        public void Show(Vector3 world, string text, Color color, float scale)
        {
            Popup p = null;
            foreach (var x in _pool) if (!x.active) { p = x; break; }
            if (p == null) return; // all busy — skip rather than steal a visible one
            p.active = true;
            p.time = 0f;
            p.world = world;
            p.scale = scale;
            p.text.text = text;
            p.text.color = color;
            p.rt.gameObject.SetActive(true);
        }

        void LateUpdate()
        {
            if (_cam == null) _cam = Camera.main;
            if (_cam == null) return;
            float dt = Time.unscaledDeltaTime;
            foreach (var p in _pool)
            {
                if (!p.active) continue;
                p.time += dt;
                if (p.time > 1.3f) { p.active = false; p.rt.gameObject.SetActive(false); continue; }
                Vector3 w = p.world + Vector3.up * p.time * 1.4f;
                Vector3 sp = _cam.WorldToScreenPoint(w);
                if (sp.z <= 0.5f || sp.z > 90f) { p.text.alpha = 0f; continue; }
                RectTransformUtility.ScreenPointToLocalPointInRectangle(_layer, sp, null, out var local);
                p.rt.localPosition = local;
                float distScale = Mathf.Clamp(14f / sp.z, 0.45f, 1.3f) * p.scale;
                float pop = p.time < 0.15f ? Mathf.Lerp(0.5f, 1f, p.time / 0.15f) : 1f;
                p.rt.localScale = Vector3.one * distScale * pop;
                p.text.alpha = p.time > 0.9f ? 1f - (p.time - 0.9f) / 0.4f : 1f;
            }
        }
    }
}
