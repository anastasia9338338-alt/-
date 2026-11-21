using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using ZooThrow.Core;
using ZooThrow.SaveSystem;

namespace ZooThrow.UI
{
    /// <summary>Pause menu: audio, controls, graphics quality, statistics and progress reset.</summary>
    public class SettingsWindow : UIWindow
    {
        Slider _volume, _music, _sensitivity;
        TextMeshProUGUI _volumeValue, _musicValue, _sensValue, _stats;
        readonly List<(UIButton button, Func<bool> get, Action toggle, string label)> _toggles = new List<(UIButton, Func<bool>, Action, string)>();
        readonly UIButton[] _quality = new UIButton[3];
        bool _binding;

        SettingsData S => G.State.settings;

        protected override void BuildBody(RectTransform body)
        {
            var content = UIFactory.Scroll(body, out _);
            UIFactory.Stretch((RectTransform)content.parent.parent);
            UIFactory.VLayout(content, 12, new RectOffset(6, 10, 4, 10), TextAnchor.UpperCenter, true, false);

            Section(content, "Звук и управление");
            _volume = SliderRow(content, "Звуки", out _volumeValue, v => { S.masterVolume = v; Changed(); });
            _music = SliderRow(content, "Музыка", out _musicValue, v => { S.musicVolume = v; Changed(); });
            _sensitivity = SliderRow(content, "Чувствительность мыши", out _sensValue, v => { S.mouseSensitivity = Mathf.Lerp(0.1f, 3f, v); Changed(); });
            ToggleRow(content, "Инверсия мыши по вертикали", () => S.invertY, () => S.invertY = !S.invertY);
            ToggleRow(content, "Тряска камеры", () => S.cameraShake, () => S.cameraShake = !S.cameraShake);
            ToggleRow(content, "Сразу выпускать улов в аквариум", () => S.autoPlaceAnimals, () => S.autoPlaceAnimals = !S.autoPlaceAnimals);
            ToggleRow(content, "Показывать FPS", () => S.showFps, () => S.showFps = !S.showFps);

            Section(content, "Графика");
            var qrow = UIFactory.Rect("Quality", content);
            UIFactory.Layout(qrow, -1, 78);
            UIFactory.HLayout(qrow, 12, null, TextAnchor.MiddleCenter, true, true);
            string[] names = { "НИЗКОЕ", "СРЕДНЕЕ", "ВЫСОКОЕ" };
            for (int i = 0; i < 3; i++)
            {
                int q = i;
                _quality[i] = UIFactory.Button(qrow, names[i], UITheme.Grey, () => { S.quality = q; Changed(); }, 26, null, 18);
            }

            Section(content, "Статистика");
            _stats = UIFactory.Text(content, "", 24, UITheme.TextDim, TextAlignmentOptions.TopLeft, false, true);
            UIFactory.Layout(_stats, -1, 130);

            var row = UIFactory.Rect("Buttons", content);
            UIFactory.Layout(row, -1, 100);
            UIFactory.HLayout(row, 14, null, TextAnchor.MiddleCenter, true, true);
            UIFactory.Button(row, "ПРОДОЛЖИТЬ", UITheme.Green, () => UI.Close(Id), 28, IconId.Check, 20);
            UIFactory.Button(row, "СОХРАНИТЬ", UITheme.Blue, () => { G.SaveNow(); GameEvents.RaiseToast("Прогресс сохранён", UITheme.Money); }, 28, null, 20);
            UIFactory.Button(row, "СБРОСИТЬ ПРОГРЕСС", UITheme.Red, ResetClicked, 24, null, 20);
        }

        void Section(RectTransform parent, string title)
        {
            var t = UIFactory.Text(parent, title.ToUpperInvariant(), 26, UITheme.Yellow, TextAlignmentOptions.BottomLeft, true, true);
            UIFactory.Layout(t, -1, 46);
        }

        Slider SliderRow(RectTransform parent, string label, out TextMeshProUGUI value, Action<float> onChanged)
        {
            var bg = UIFactory.Panel(parent, "Row", UITheme.Card, 18);
            UIFactory.Layout(bg, -1, 76);
            var l = UIFactory.Text(bg.transform, label, 26, Color.white, TextAlignmentOptions.MidlineLeft, true, true);
            l.rectTransform.anchorMin = new Vector2(0, 0); l.rectTransform.anchorMax = new Vector2(0.45f, 1);
            l.rectTransform.offsetMin = new Vector2(20, 0); l.rectTransform.offsetMax = Vector2.zero;
            var s = UIFactory.Slider(bg.transform, UITheme.Blue, 0.5f, v => { if (!_binding) onChanged(v); });
            var srt = (RectTransform)s.transform;
            srt.anchorMin = new Vector2(0.46f, 0.2f); srt.anchorMax = new Vector2(0.86f, 0.8f);
            srt.offsetMin = srt.offsetMax = Vector2.zero;
            value = UIFactory.Text(bg.transform, "", 24, UITheme.TextDim, TextAlignmentOptions.MidlineRight, true, true);
            value.rectTransform.anchorMin = new Vector2(0.86f, 0); value.rectTransform.anchorMax = new Vector2(1, 1);
            value.rectTransform.offsetMin = Vector2.zero; value.rectTransform.offsetMax = new Vector2(-20, 0);
            return s;
        }

        void ToggleRow(RectTransform parent, string label, Func<bool> get, Action toggle)
        {
            var bg = UIFactory.Panel(parent, "Toggle", UITheme.Card, 18);
            UIFactory.Layout(bg, -1, 76);
            var l = UIFactory.Text(bg.transform, label, 26, Color.white, TextAlignmentOptions.MidlineLeft, true, true);
            UIFactory.Stretch(l.rectTransform, 20, 0, 220, 0);
            var b = UIFactory.Button(bg.transform, "", UITheme.Green, () => { toggle(); Changed(); }, 24, null, 16);
            UIFactory.Place((RectTransform)b.button.transform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(-14, 0), new Vector2(180, 60));
            _toggles.Add((b, get, toggle, label));
        }

        void Changed()
        {
            G.SaveMgr.MarkDirty();
            GameEvents.RaiseSettingsChanged();
            Bind();
        }

        protected override void Refresh() => Bind();

        void Bind()
        {
            _binding = true;
            _volume.value = S.masterVolume;
            _music.value = S.musicVolume;
            _sensitivity.value = Mathf.InverseLerp(0.1f, 3f, S.mouseSensitivity);
            _binding = false;
            _volumeValue.text = Mathf.RoundToInt(S.masterVolume * 100) + "%";
            _musicValue.text = Mathf.RoundToInt(S.musicVolume * 100) + "%";
            _sensValue.text = S.mouseSensitivity.ToString("0.0");
            foreach (var t in _toggles)
            {
                bool on = t.get();
                t.button.SetState(on ? "ВКЛ" : "ВЫКЛ", on ? UITheme.Green : UITheme.Grey, true);
            }
            for (int i = 0; i < 3; i++) _quality[i].SetColor(S.quality == i ? UITheme.Blue : UITheme.Grey);
        }

        protected override void Tick()
        {
            var s = G.State;
            _stats.text = "Забросов: " + s.totalThrows + "   •   Идеальных: " + s.perfectThrows + "\n" +
                          "Рекорд дальности: " + NumberFormat.Meters(s.bestDistance) + "   •   Открыто локаций: " + s.unlockedBiomes.Count + " / " + G.Db.biomes.Count + "\n" +
                          "Всего заработано: " + NumberFormat.Money(s.totalEarned) + "   •   Видов в коллекции: " + s.discoveredAnimals.Count + " / " + G.Db.animals.Count;
        }

        void ResetClicked()
        {
            UI.Confirm("Сбросить прогресс?", "Все деньги, улов, удочки, улучшения и рекорды будут удалены без возможности восстановления.", "СБРОСИТЬ", UITheme.Red, () =>
                UI.Confirm("Точно?", "Это последнее предупреждение. Начать игру заново?", "ДА, СБРОСИТЬ", UITheme.Red, () => G.ResetProgress()));
        }
    }
}
