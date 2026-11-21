using TMPro;
using UnityEngine;
using UnityEngine.UI;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Player;
using ZooThrow.World;

namespace ZooThrow.UI
{
    /// <summary>Always-on HUD: stats bar, side menu, bait/rod panel, cast/training buttons, prompts and objectives.</summary>
    public class HudView : MonoBehaviour
    {
        UIManager _ui;
        GameManager _g;
        InteractionSystem _interaction;

        TextMeshProUGUI _money, _income, _power, _biome, _record;
        UIBar _xpBar;
        TextMeshProUGUI _xpText;
        RectTransform _moneyPill;
        double _shownMoney = -1;
        float _moneyPunch;

        RectTransform _bottomRow, _trainingPanel, _promptPill;
        TextMeshProUGUI _prompt, _foodName, _foodInfo, _trainInfo, _objective, _fps, _clickHint;
        RawImage _foodPortrait;
        UIButton _throwButton, _trainButton, _interactButton;
        UIBar _trainBar, _objectiveBar;
        TextMeshProUGUI _trainBarText;
        RectTransform _clickHintRt;
        string _lastFoodId;
        float _fpsTimer;
        int _fpsFrames;

        public void Build(UIManager ui, GameManager g, RectTransform layer)
        {
            _ui = ui;
            _g = g;
            _interaction = g.Player.GetComponent<InteractionSystem>();
            BuildTopBar(layer);
            BuildSideMenu(layer);
            BuildBottom(layer);
            BuildObjective(layer);
            BuildHints(layer);
        }

        // ------------------------------------------------------------------ top bar

        RectTransform Pill(Transform parent, IconId icon, Color iconColor, float width, out TextMeshProUGUI text, float fontSize = 36f)
        {
            var pill = UIFactory.Panel(parent, "Pill", UITheme.HudPill, 30);
            UIFactory.Layout(pill, width, 74);
            var ic = UIFactory.Icon(pill.transform, icon, iconColor, 50);
            UIFactory.Place(ic.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(14, 0), new Vector2(50, 50));
            text = UIFactory.Text(pill.transform, "", fontSize, Color.white, TextAlignmentOptions.MidlineLeft, true, true);
            text.enableWordWrapping = false;
            UIFactory.Stretch(text.rectTransform, 74, 4, 14, 4);
            return pill.rectTransform;
        }

        void BuildTopBar(RectTransform layer)
        {
            var bar = UIFactory.Rect("TopBar", layer);
            UIFactory.Place(bar, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0, -18), new Vector2(1500, 80));
            UIFactory.HLayout(bar, 14, null, TextAnchor.MiddleCenter, false, false);
            _moneyPill = Pill(bar, IconId.Coin, UITheme.Gold, 330, out _money, 40);
            _money.color = UITheme.Money;
            Pill(bar, IconId.Income, UITheme.Money, 300, out _income, 32);

            var powerPill = Pill(bar, IconId.Power, new Color(0.55f, 0.8f, 1f), 330, out _power, 30);
            _power.rectTransform.offsetMin = new Vector2(74, 24);
            _xpBar = UIFactory.Bar(powerPill, new Color(1, 1, 1, 0.15f), new Color(0.45f, 0.75f, 1f), 7);
            _xpBar.root.anchorMin = new Vector2(0, 0); _xpBar.root.anchorMax = new Vector2(1, 0);
            _xpBar.root.pivot = new Vector2(0.5f, 0);
            _xpBar.root.offsetMin = new Vector2(76, 12); _xpBar.root.offsetMax = new Vector2(-18, 26);
            _xpText = UIFactory.Text(_xpBar.root, "", 16, Color.white, TextAlignmentOptions.Center, false, true);
            UIFactory.Stretch(_xpText.rectTransform, 0, -4, 0, -4);

            var biomePill = Pill(bar, IconId.Flag, new Color(0.6f, 1f, 0.6f), 420, out _biome, 30);
            _biome.rectTransform.offsetMin = new Vector2(74, 26);
            _record = UIFactory.Text(biomePill, "", 20, UITheme.TextDim, TextAlignmentOptions.MidlineLeft, false, true);
            _record.rectTransform.anchorMin = new Vector2(0, 0); _record.rectTransform.anchorMax = new Vector2(1, 0);
            _record.rectTransform.pivot = new Vector2(0.5f, 0);
            _record.rectTransform.offsetMin = new Vector2(76, 6); _record.rectTransform.offsetMax = new Vector2(-10, 32);
        }

        // ------------------------------------------------------------------ side menu

        void BuildSideMenu(RectTransform layer)
        {
            var menu = UIFactory.Rect("SideMenu", layer);
            UIFactory.Place(menu, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(22, 20), new Vector2(128, 820));
            UIFactory.VLayout(menu, 14, null, TextAnchor.MiddleCenter, true, false);
            MenuButton(menu, "Аквариум", "Tab", IconId.Fish, UITheme.Blue, () => _ui.Toggle(WindowId.Animals));
            MenuButton(menu, "Удочки", "B", IconId.Rod, UITheme.Orange, () => _ui.Toggle(WindowId.Rods));
            MenuButton(menu, "Наживка", "N", IconId.Worm, UITheme.Green, () => _ui.Toggle(WindowId.Baits));
            MenuButton(menu, "Улучшения", "U", IconId.Upgrade, UITheme.Blue, () => _ui.Toggle(WindowId.Upgrades));
            MenuButton(menu, "Коллекция", "C", IconId.Collection, UITheme.Purple, () => _ui.Toggle(WindowId.Collection));
            MenuButton(menu, "Настройки", "Esc", IconId.Gear, UITheme.Grey, () => _ui.Toggle(WindowId.Settings));
        }

        void MenuButton(Transform parent, string label, string key, IconId icon, Color color, System.Action onClick)
        {
            var b = UIFactory.Button(parent, null, color, onClick, 28, null, 24);
            UIFactory.Layout(b.button, 128, 120);
            var face = b.bg.transform;
            var ic = UIFactory.Icon(face, icon, Color.white, 58);
            UIFactory.Place(ic.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0, -12), new Vector2(58, 58));
            var t = UIFactory.Text(face, label, 19, Color.white, TextAlignmentOptions.Center, true, true);
            t.enableWordWrapping = false;
            UIFactory.Place(t.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 8), new Vector2(124, 30));
            var badge = UIFactory.Panel(face, "Key", new Color(0, 0, 0, 0.45f), 10);
            UIFactory.Place(badge.rectTransform, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-6, -6), new Vector2(key.Length > 1 ? 44 : 28, 26));
            var kt = UIFactory.Text(badge.transform, key, 16, Color.white, TextAlignmentOptions.Center, true);
            UIFactory.Stretch(kt.rectTransform);
        }

        // ------------------------------------------------------------------ bottom

        void BuildBottom(RectTransform layer)
        {
            _promptPill = UIFactory.Panel(layer, "Prompt", new Color(0.05f, 0.07f, 0.15f, 0.8f), 24).rectTransform;
            UIFactory.Place(_promptPill, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 186), new Vector2(560, 58));
            _prompt = UIFactory.Text(_promptPill, "", 28, Color.white, TextAlignmentOptions.Center, true, true);
            UIFactory.Stretch(_prompt.rectTransform, 70, 0, 16, 0);
            _interactButton = UIFactory.Button(_promptPill, "E", UITheme.Yellow, () => _interaction.Interact(_interaction.Current), 24, null, 12);
            UIFactory.Place((RectTransform)_interactButton.button.transform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(8, 2), new Vector2(54, 48));

            _bottomRow = UIFactory.Rect("BottomRow", layer);
            UIFactory.Place(_bottomRow, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 24), new Vector2(1180, 140));
            UIFactory.HLayout(_bottomRow, 18, null, TextAnchor.MiddleCenter, false, false);

            // Bait selector with the current rod underneath
            var food = UIFactory.Panel(_bottomRow, "BaitSelector", UITheme.HudPill, 30);
            UIFactory.Layout(food, 520, 130);
            var prev = UIFactory.Button(food.transform, null, UITheme.Grey, () => _g.Baits.Cycle(-1), 26, IconId.ChevronLeft, 14);
            UIFactory.Place((RectTransform)prev.button.transform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(12, 0), new Vector2(54, 96));
            var next = UIFactory.Button(food.transform, null, UITheme.Grey, () => _g.Baits.Cycle(1), 26, IconId.ChevronRight, 14);
            UIFactory.Place((RectTransform)next.button.transform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(-12, 0), new Vector2(54, 96));
            var portraitBg = UIFactory.Panel(food.transform, "PortraitBg", new Color(1, 1, 1, 0.08f), 20);
            UIFactory.Place(portraitBg.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(78, 0), new Vector2(110, 110));
            _foodPortrait = UIFactory.Raw(portraitBg.transform, null, 110);
            UIFactory.Stretch(_foodPortrait.rectTransform);
            _foodName = UIFactory.Text(food.transform, "", 32, Color.white, TextAlignmentOptions.TopLeft, true, true);
            _foodName.enableWordWrapping = false;
            UIFactory.Place(_foodName.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(200, -16), new Vector2(250, 44));
            _foodInfo = UIFactory.Text(food.transform, "", 22, UITheme.TextDim, TextAlignmentOptions.TopLeft, false, true);
            UIFactory.Place(_foodInfo.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(200, -60), new Vector2(250, 64));
            var keys = UIFactory.Text(food.transform, "Q / R", 16, new Color(1, 1, 1, 0.5f), TextAlignmentOptions.BottomRight, true);
            UIFactory.Place(keys.rectTransform, new Vector2(1, 0), new Vector2(1, 0), new Vector2(-74, 6), new Vector2(80, 24));

            _throwButton = UIFactory.Button(_bottomRow, "ЗАБРОСИТЬ", UITheme.Green, () => _g.Throw.RequestThrow(), 42, IconId.Rod, 30);
            UIFactory.Layout(_throwButton.button, 360, 130);
            var fkey = UIFactory.Panel(_throwButton.bg.transform, "Key", new Color(0, 0, 0, 0.35f), 10);
            UIFactory.Place(fkey.rectTransform, new Vector2(1, 1), new Vector2(1, 1), new Vector2(-10, -10), new Vector2(32, 28));
            var ft = UIFactory.Text(fkey.transform, "F", 18, Color.white, TextAlignmentOptions.Center, true);
            UIFactory.Stretch(ft.rectTransform);

            _trainButton = UIFactory.Button(_bottomRow, "ТРЕНИРОВАТЬСЯ", UITheme.Blue, () => _g.Training.StartTraining(), 30, IconId.Power, 30);
            UIFactory.Layout(_trainButton.button, 270, 130);

            // Training panel (replaces the bottom row while training)
            _trainingPanel = UIFactory.Panel(layer, "TrainingPanel", UITheme.HudPill, 30).rectTransform;
            UIFactory.Place(_trainingPanel, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 24), new Vector2(900, 150));
            _trainInfo = UIFactory.Text(_trainingPanel, "", 28, Color.white, TextAlignmentOptions.TopLeft, true, true);
            UIFactory.Place(_trainInfo.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(28, -16), new Vector2(560, 70));
            _trainBar = UIFactory.Bar(_trainingPanel, new Color(1, 1, 1, 0.12f), new Color(0.45f, 0.75f, 1f), 12);
            UIFactory.Place(_trainBar.root, new Vector2(0, 0), new Vector2(0, 0), new Vector2(28, 22), new Vector2(560, 36));
            _trainBarText = UIFactory.Text(_trainBar.root, "", 20, Color.white, TextAlignmentOptions.Center, true, true);
            UIFactory.Stretch(_trainBarText.rectTransform);
            var stop = UIFactory.Button(_trainingPanel, "ОСТАНОВИТЬ", UITheme.Red, () => _g.Training.StopTraining(), 30, IconId.Close, 26);
            UIFactory.Place((RectTransform)stop.button.transform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(-20, 0), new Vector2(280, 110));
            _trainingPanel.gameObject.SetActive(false);
        }

        void BuildObjective(RectTransform layer)
        {
            var card = UIFactory.Panel(layer, "Objective", UITheme.HudPill, 24);
            UIFactory.Place(card.rectTransform, new Vector2(1, 1), new Vector2(1, 1), new Vector2(-22, -120), new Vector2(420, 150));
            var ic = UIFactory.Icon(card.transform, IconId.Target, UITheme.Yellow, 40);
            UIFactory.Place(ic.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(16, -14), new Vector2(40, 40));
            var title = UIFactory.Text(card.transform, "ЗАДАНИЕ", 24, UITheme.Yellow, TextAlignmentOptions.MidlineLeft, true, true);
            UIFactory.Place(title.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(66, -14), new Vector2(300, 40));
            _objective = UIFactory.Text(card.transform, "", 22, Color.white, TextAlignmentOptions.TopLeft, false, true);
            UIFactory.Place(_objective.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(18, -58), new Vector2(386, 58));
            _objectiveBar = UIFactory.Bar(card.transform, new Color(1, 1, 1, 0.12f), UITheme.Yellow, 7);
            UIFactory.Place(_objectiveBar.root, new Vector2(0, 0), new Vector2(0, 0), new Vector2(18, 14), new Vector2(384, 14));
        }

        void BuildHints(RectTransform layer)
        {
            var help = UIFactory.Text(layer, "WASD — ходьба • Shift — бег • Пробел — прыжок • E — действие • F — заброс • Q/R — наживка • Alt — курсор • Esc — меню", 18, new Color(1, 1, 1, 0.6f), TextAlignmentOptions.BottomLeft, false, true);
            UIFactory.Place(help.rectTransform, new Vector2(0, 0), new Vector2(0, 0), new Vector2(18, 8), new Vector2(1200, 30));
            _fps = UIFactory.Text(layer, "", 20, UITheme.Money, TextAlignmentOptions.TopLeft, true, true);
            UIFactory.Place(_fps.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(16, -10), new Vector2(200, 30));
            var hint = UIFactory.Panel(layer, "ClickHint", new Color(0.05f, 0.07f, 0.15f, 0.7f), 22);
            _clickHintRt = hint.rectTransform;
            hint.raycastTarget = false;
            UIFactory.Place(_clickHintRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, -60), new Vector2(720, 56));
            _clickHint = UIFactory.Text(hint.transform, "Кликни по игре, чтобы управлять камерой мышью", 24, Color.white, TextAlignmentOptions.Center, false, true);
            UIFactory.Stretch(_clickHint.rectTransform);
            _clickHintRt.gameObject.SetActive(false);
        }

        public void SetClickHint(bool show)
        {
            if (_clickHintRt.gameObject.activeSelf != show) _clickHintRt.gameObject.SetActive(show);
        }

        // ------------------------------------------------------------------ update

        void Update()
        {
            if (_g == null) return;
            var s = _g.State;
            float dt = Time.unscaledDeltaTime;

            // Money counts up smoothly; purchases snap down.
            double money = _g.Economy.Money;
            if (_shownMoney < 0 || money < _shownMoney) _shownMoney = money;
            else _shownMoney += (money - _shownMoney) * (1 - Mathf.Exp(-10f * dt));
            if (money - _shownMoney < 0.5) _shownMoney = money;
            _money.text = NumberFormat.Money(_shownMoney);
            if (_moneyPunch > 0f)
            {
                _moneyPunch = Mathf.Max(0f, _moneyPunch - dt * 3f);
                float k = 1f + Mathf.Sin(_moneyPunch * Mathf.PI) * 0.08f;
                _moneyPill.localScale = new Vector3(k, k, 1f);
            }
            _income.text = "+" + NumberFormat.PerSecond(_g.Income.IncomePerSecond);
            _power.text = "Сила " + s.powerLevel;
            _xpBar.Set(_g.Training.Xp01);
            _xpText.text = NumberFormat.Short(s.xp) + " / " + NumberFormat.Short(_g.Training.XpToNext);
            var furthest = _g.Biomes.Furthest;
            _biome.text = furthest != null ? furthest.displayName : "—";
            _record.text = "Рекорд: " + NumberFormat.Meters(s.bestDistance);

            UpdateBottom();
            UpdateObjective();

            if (s.settings.showFps)
            {
                _fpsFrames++;
                _fpsTimer += dt;
                if (_fpsTimer >= 0.5f) { _fps.text = Mathf.RoundToInt(_fpsFrames / _fpsTimer) + " FPS"; _fpsFrames = 0; _fpsTimer = 0f; }
            }
            else if (_fps.text.Length > 0) _fps.text = "";
        }

        public void PunchMoney() => _moneyPunch = 1f;

        void UpdateBottom()
        {
            bool training = _g.Training.IsTraining;
            bool playing = _g.Mode == GameMode.Playing;
            bool showRow = !training && (playing || _g.Mode == GameMode.Aiming);
            if (_bottomRow.gameObject.activeSelf != showRow) _bottomRow.gameObject.SetActive(showRow);
            if (_trainingPanel.gameObject.activeSelf != training) _trainingPanel.gameObject.SetActive(training);

            var bait = _g.Baits.Selected;
            var rod = _g.Rods.Selected;
            string gearKey = (bait != null ? bait.id : "") + "|" + (rod != null ? rod.id : "");
            if (bait != null && gearKey != _lastFoodId)
            {
                _lastFoodId = gearKey;
                _foodName.text = bait.displayName;
                _foodInfo.text = "Удача ×" + bait.luck.ToString("0.00") +
                                 (rod != null ? "\n" + rod.displayName + (rod.distanceBonus > 0 ? " (+" + rod.distanceBonus.ToString("0") + " м)" : "") : "");
                _foodPortrait.texture = Portraits.Bait(bait);
            }

            bool nearTraining = _interaction.Current != null && _interaction.Current.kind == StationKind.Training;
            if (_trainButton.button.gameObject.activeSelf != (nearTraining && playing)) _trainButton.button.gameObject.SetActive(nearTraining && playing);
            _throwButton.SetState(_g.Throw.PlayerOnPad ? "ЗАБРОСИТЬ" : "НА ПИРС", UITheme.Green, playing);

            bool showPrompt = playing && _interaction.Current != null && !_ui.AnyWindowOpen;
            if (_promptPill.gameObject.activeSelf != showPrompt) _promptPill.gameObject.SetActive(showPrompt);
            if (showPrompt)
            {
                string p = _interaction.Current.prompt;
                if (p.StartsWith("[E] ")) p = p.Substring(4);
                _prompt.text = p;
            }

            if (training)
            {
                var t = _g.Trainers.Best;
                _trainInfo.text = "Тренировка: " + t.displayName + "\n<size=22><color=#B8C2E0>+" + NumberFormat.Short(_g.Training.XpPerRep) + " опыта за повтор • повторов: " + _g.Training.SessionReps + "</color></size>";
                _trainBar.Set(_g.Training.Xp01);
                _trainBarText.text = "Сила " + _g.State.powerLevel + " • " + NumberFormat.Short(_g.State.xp) + " / " + NumberFormat.Short(_g.Training.XpToNext);
            }
        }

        void UpdateObjective()
        {
            var s = _g.State;
            string text;
            float progress;
            var secondRod = _g.Db.rods.Count > 1 ? _g.Db.rods[1] : null;
            var secondBait = _g.Db.baits.Count > 1 ? _g.Db.baits[1] : null;
            var next = _g.Biomes.Next;
            if (s.totalThrows == 0)
            {
                text = "Встань на пирс и закинь удочку (F или кнопка «ЗАБРОСИТЬ»).";
                progress = 0f;
            }
            else if (_g.Pen.PlacedCount == 0 && _g.Inventory.Count > 0)
            {
                text = "Выпусти улов в аквариум: Tab, затем «В аквариум».";
                progress = 0.3f;
            }
            else if (s.powerLevel < 3)
            {
                text = "Потренируйся на турнике (E рядом с ним), чтобы забрасывать дальше.";
                progress = (s.powerLevel - 1 + _g.Training.Xp01) / 2f;
            }
            else if (secondRod != null && !_g.Rods.Owns(secondRod))
            {
                text = "Накопи " + NumberFormat.Money(secondRod.price) + " и купи «" + secondRod.displayName + "» в магазине удочек (B).";
                progress = (float)System.Math.Min(1.0, _g.Economy.Money / System.Math.Max(1.0, secondRod.price));
            }
            else if (secondBait != null && !_g.Baits.Owns(secondBait))
            {
                text = "Купи наживку «" + secondBait.displayName + "» (N): с ней чаще клюёт редкая рыба.";
                progress = (float)System.Math.Min(1.0, _g.Economy.Money / System.Math.Max(1.0, secondBait.price));
            }
            else if (next != null)
            {
                text = "Заброс до локации «" + next.displayName + "»: нужно " + NumberFormat.Meters(next.startDistance) + ". Твой идеальный заброс: " + NumberFormat.Meters(_g.ThrowPerfectDistance) + ".";
                progress = Mathf.Clamp01(s.bestDistance / Mathf.Max(1f, next.startDistance));
            }
            else
            {
                text = "Поймай всех существ: " + _g.Inventory.DiscoveredCount + " / " + _g.Db.animals.Count + ".";
                progress = _g.Inventory.DiscoveredCount / (float)Mathf.Max(1, _g.Db.animals.Count);
            }
            if (_objective.text != text) _objective.text = text;
            _objectiveBar.Set(progress);
        }
    }
}
