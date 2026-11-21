using TMPro;
using UnityEngine;
using UnityEngine.UI;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Throwing;

namespace ZooThrow.UI
{
    /// <summary>Accuracy meter, grade pop text and live flight distance.</summary>
    public class ThrowHud : MonoBehaviour
    {
        GameManager _g;
        RectTransform _meterPanel, _bar, _indicator, _good, _great, _perfect;
        TextMeshProUGUI _grade, _flightDistance, _flightBiome, _preview;
        RectTransform _gradeRt, _flightRt;
        float _gradeTime = -1f;
        RectTransform _hookRt, _reelRt;
        TextMeshProUGUI _hookText, _reelText;
        UIBar _reelBar;
        float _hookTime;
        const float BarWidth = 860f;

        public void Build(UIManager ui, GameManager g, RectTransform layer)
        {
            _g = g;
            var panel = UIFactory.Panel(layer, "Meter", new Color(0.06f, 0.08f, 0.17f, 0.88f), 28);
            _meterPanel = panel.rectTransform;
            UIFactory.Place(_meterPanel, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 190), new Vector2(940, 190));
            UIFactory.Shadow(_meterPanel, 28, 0.4f, 16f);
            var title = UIFactory.Text(_meterPanel, "Останови индикатор в <color=#FFD23F>золотой</color> зоне!", 30, Color.white, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(title.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0, -12), new Vector2(900, 44));

            var barBg = UIFactory.Panel(_meterPanel, "Bar", new Color(0.92f, 0.33f, 0.33f), 14);
            _bar = barBg.rectTransform;
            UIFactory.Place(_bar, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, -6), new Vector2(BarWidth, 54));
            _good = Zone("Good", new Color(1f, 0.78f, 0.25f));
            _great = Zone("Great", new Color(0.35f, 0.85f, 0.4f));
            _perfect = Zone("Perfect", new Color(1f, 0.95f, 0.45f));
            _perfect.gameObject.AddComponent<Outline>().effectColor = new Color(1f, 0.6f, 0f, 1f);

            var ind = UIFactory.Panel(_bar, "Indicator", Color.white, 4);
            _indicator = ind.rectTransform;
            _indicator.anchorMin = _indicator.anchorMax = new Vector2(0, 0.5f);
            _indicator.pivot = new Vector2(0.5f, 0.5f);
            _indicator.sizeDelta = new Vector2(12, 84);
            ind.gameObject.AddComponent<Outline>().effectColor = new Color(0.05f, 0.05f, 0.15f, 1f);
            var arrow = UIFactory.Icon(_indicator, IconId.ChevronLeft, Color.white, 30);
            UIFactory.Place(arrow.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 0f), new Vector2(0, 2), new Vector2(30, 30));
            arrow.rectTransform.localRotation = Quaternion.Euler(0, 0, 90f);

            var hint = UIFactory.Text(_meterPanel, "ЛКМ • Пробел • F — бросить      Esc — отмена", 22, UITheme.TextDim, TextAlignmentOptions.Center, false, true);
            UIFactory.Place(hint.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 10), new Vector2(900, 34));
            _preview = UIFactory.Text(_meterPanel, "", 22, UITheme.Yellow, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(_preview.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 0f), new Vector2(0, 8), new Vector2(900, 34));
            _meterPanel.gameObject.SetActive(false);

            _grade = UIFactory.Text(layer, "", 96, Color.white, TextAlignmentOptions.Center, true, true);
            _gradeRt = _grade.rectTransform;
            UIFactory.Place(_gradeRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, 170), new Vector2(1400, 140));
            _grade.enableWordWrapping = false;
            _grade.gameObject.SetActive(false);

            var flight = UIFactory.Panel(layer, "Flight", new Color(0.06f, 0.08f, 0.17f, 0.75f), 30);
            _flightRt = flight.rectTransform;
            UIFactory.Place(_flightRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0, -120), new Vector2(520, 140));
            _flightDistance = UIFactory.Text(_flightRt, "", 72, Color.white, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(_flightDistance.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0, -6), new Vector2(500, 86));
            _flightBiome = UIFactory.Text(_flightRt, "", 28, UITheme.TextDim, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(_flightBiome.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 10), new Vector2(500, 40));
            _flightRt.gameObject.SetActive(false);

            // Hook prompt: a big pulsing call to action while the bobber dips
            var hook = UIFactory.Panel(layer, "Hook", new Color(0.75f, 0.12f, 0.12f, 0.9f), 30);
            _hookRt = hook.rectTransform;
            UIFactory.Place(_hookRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, 120), new Vector2(760, 150));
            UIFactory.Shadow(_hookRt, 30, 0.45f, 16f);
            _hookText = UIFactory.Text(_hookRt, "ПОДСЕКАЙ!\n<size=45%>Жми ЛКМ / Пробел! Чем быстрее, тем выше шанс на редкий улов</size>", 72, Color.white, TextAlignmentOptions.Center, true, true);
            UIFactory.Stretch(_hookText.rectTransform, 10, 6, 10, 6);
            _hookRt.gameObject.SetActive(false);

            // Reel panel: progress towards the pier
            var reel = UIFactory.Panel(layer, "Reel", new Color(0.06f, 0.08f, 0.17f, 0.88f), 28);
            _reelRt = reel.rectTransform;
            UIFactory.Place(_reelRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 190), new Vector2(820, 150));
            _reelText = UIFactory.Text(_reelRt, "", 30, Color.white, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(_reelText.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0, -12), new Vector2(800, 44));
            _reelBar = UIFactory.Bar(_reelRt, new Color(1, 1, 1, 0.12f), new Color(0.35f, 0.85f, 1f), 14);
            UIFactory.Place(_reelBar.root, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 46), new Vector2(760, 40));
            var reelHint = UIFactory.Text(_reelRt, "Жми ЛКМ / Пробел, чтобы тянуть быстрее", 20, UITheme.TextDim, TextAlignmentOptions.Center, false, true);
            UIFactory.Place(reelHint.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 10), new Vector2(800, 30));
            _reelRt.gameObject.SetActive(false);
        }

        public void ShowHook(bool show)
        {
            _hookRt.gameObject.SetActive(show);
            _hookTime = 0f;
        }

        public void ShowReel(bool show) => _reelRt.gameObject.SetActive(show);

        public void SetReel(float progress, float metersLeft)
        {
            _reelBar.Set(progress);
            _reelText.text = "Вытягиваем улов! Осталось " + NumberFormat.Meters(metersLeft);
        }

        RectTransform Zone(string name, Color c)
        {
            var z = UIFactory.Panel(_bar, name, c, 10);
            z.raycastTarget = false;
            var rt = z.rectTransform;
            rt.anchorMin = new Vector2(0, 0); rt.anchorMax = new Vector2(0, 1);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.offsetMin = new Vector2(0, 3); rt.offsetMax = new Vector2(0, -3);
            return rt;
        }

        static void SetZone(RectTransform z, float center, float half)
        {
            z.anchoredPosition = new Vector2(center * BarWidth, 0);
            z.sizeDelta = new Vector2(Mathf.Max(8f, half * 2f * BarWidth), -6f);
        }

        public void ShowMeter(bool show)
        {
            _meterPanel.gameObject.SetActive(show);
            if (!show) return;
            var b = _g.Balance;
            float c = _g.Throw.Meter.TargetCenter;
            SetZone(_good, c, b.goodHalfWidth);
            SetZone(_great, c, b.greatHalfWidth);
            SetZone(_perfect, c, b.perfectHalfWidth);
            var food = _g.Baits.Selected;
            _preview.text = "Идеальный заброс: до " + NumberFormat.Meters(_g.ThrowPerfectDistance) + "  •  " + (food != null ? food.displayName : "") + "  •  " + _g.Rods.Selected.displayName;
        }

        public void ShowGrade(ThrowResult r)
        {
            _grade.gameObject.SetActive(true);
            _grade.text = ThrowMath.GradeText(r.grade);
            switch (r.grade)
            {
                case ThrowGrade.Perfect: _grade.color = new Color(1f, 0.85f, 0.2f); break;
                case ThrowGrade.Great: _grade.color = new Color(0.45f, 1f, 0.5f); break;
                case ThrowGrade.Good: _grade.color = new Color(0.6f, 0.85f, 1f); break;
                default: _grade.color = new Color(1f, 0.55f, 0.5f); break;
            }
            _grade.fontSize = r.grade == ThrowGrade.Perfect ? 110 : 80;
            _gradeTime = 0f;
        }

        public void ShowFlight(bool show) => _flightRt.gameObject.SetActive(show);

        void Update()
        {
            if (_g == null) return;
            if (_hookRt.gameObject.activeSelf)
            {
                _hookTime += Time.unscaledDeltaTime;
                float k = 1f + Mathf.Abs(Mathf.Sin(_hookTime * 10f)) * 0.08f;
                _hookRt.localScale = new Vector3(k, k, 1f);
            }
            if (_meterPanel.gameObject.activeSelf)
                _indicator.anchoredPosition = new Vector2(_g.Throw.Meter.Value * BarWidth, 0);

            if (_gradeTime >= 0f)
            {
                _gradeTime += Time.unscaledDeltaTime;
                float t = _gradeTime;
                float s = t < 0.25f ? Mathf.LerpUnclamped(0.3f, 1f, Ease.OutBack(t / 0.25f)) : 1f + Mathf.Sin(t * 8f) * 0.02f;
                _gradeRt.localScale = new Vector3(s, s, 1f);
                var c = _grade.color;
                c.a = t < 1.4f ? 1f : Mathf.Clamp01(1f - (t - 1.4f) / 0.4f);
                _grade.color = c;
                if (t > 1.8f) { _grade.gameObject.SetActive(false); _gradeTime = -1f; }
            }

            if (_flightRt.gameObject.activeSelf)
            {
                float d = _g.Throw.LiveDistance;
                _flightDistance.text = NumberFormat.Meters(d);
                var biome = _g.Db.BiomeAtDistance(d);
                if (biome != null)
                {
                    _flightBiome.text = biome.displayName + (_g.Biomes.IsUnlocked(biome) ? "" : " • НОВЫЙ!");
                    _flightBiome.color = Color.Lerp(biome.accentColor, Color.white, 0.4f);
                }
            }
        }
    }
}
