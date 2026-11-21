using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Economy;

namespace ZooThrow.UI
{
    /// <summary>Upgrades (pen, arms, luck, offline, xp) and trainer equipment.</summary>
    public class UpgradesWindow : UIWindow
    {
        class UpgradeCard
        {
            public UpgradeData data;
            public TextMeshProUGUI level, effect;
            public UIBar bar;
            public UIButton buy;
        }

        class TrainerCard
        {
            public TrainerData data;
            public Image bg;
            public TextMeshProUGUI info;
            public UIButton buy;
        }

        TextMeshProUGUI _stats;
        RectTransform _upgradesPage, _trainersPage;
        UIButton _tabUpgrades, _tabTrainers;
        readonly List<UpgradeCard> _upgrades = new List<UpgradeCard>();
        readonly List<TrainerCard> _trainers = new List<TrainerCard>();
        bool _showTrainers;

        protected override void BuildBody(RectTransform body)
        {
            var statsBg = UIFactory.Panel(body, "Stats", UITheme.Card, 18);
            var srt = statsBg.rectTransform;
            srt.anchorMin = new Vector2(0, 1); srt.anchorMax = new Vector2(1, 1); srt.pivot = new Vector2(0.5f, 1);
            srt.offsetMin = new Vector2(0, -64); srt.offsetMax = Vector2.zero;
            _stats = UIFactory.Text(srt, "", 24, Color.white, TextAlignmentOptions.Center, true, true);
            UIFactory.Stretch(_stats.rectTransform, 12, 0, 12, 0);

            var tabs = UIFactory.Rect("Tabs", body);
            tabs.anchorMin = new Vector2(0, 1); tabs.anchorMax = new Vector2(1, 1); tabs.pivot = new Vector2(0.5f, 1);
            tabs.offsetMin = new Vector2(0, -148); tabs.offsetMax = new Vector2(0, -76);
            UIFactory.HLayout(tabs, 14, null, TextAnchor.MiddleLeft, false, true);
            _tabUpgrades = UIFactory.Button(tabs, "УЛУЧШЕНИЯ", UITheme.Blue, () => SetTab(false), 26, IconId.Upgrade, 18);
            UIFactory.Layout(_tabUpgrades.button, 320, 70);
            _tabTrainers = UIFactory.Button(tabs, "ТРЕНАЖЁРЫ", UITheme.Grey, () => SetTab(true), 26, IconId.Power, 18);
            UIFactory.Layout(_tabTrainers.button, 320, 70);

            _upgradesPage = Page(body, "UpgradesPage");
            var ucontent = UIFactory.Scroll(_upgradesPage, out _);
            UIFactory.Stretch((RectTransform)ucontent.parent.parent);
            UIFactory.VLayout(ucontent, 12, new RectOffset(4, 8, 4, 8), TextAnchor.UpperCenter, true, false);
            foreach (var u in G.Db.upgrades) _upgrades.Add(MakeUpgrade(ucontent, u));

            _trainersPage = Page(body, "TrainersPage");
            var tcontent = UIFactory.Scroll(_trainersPage, out _);
            UIFactory.Stretch((RectTransform)tcontent.parent.parent);
            UIFactory.VLayout(tcontent, 12, new RectOffset(4, 8, 4, 8), TextAnchor.UpperCenter, true, false);
            foreach (var t in G.Db.trainers) _trainers.Add(MakeTrainer(tcontent, t));
            SetTab(false);
        }

        static RectTransform Page(RectTransform body, string name)
        {
            var p = UIFactory.Rect(name, body);
            p.anchorMin = Vector2.zero; p.anchorMax = Vector2.one;
            p.offsetMin = Vector2.zero; p.offsetMax = new Vector2(0, -160);
            return p;
        }

        public void SetTab(bool trainers)
        {
            _showTrainers = trainers;
            _upgradesPage.gameObject.SetActive(!trainers);
            _trainersPage.gameObject.SetActive(trainers);
            _tabUpgrades.SetColor(trainers ? UITheme.Grey : UITheme.Blue);
            _tabTrainers.SetColor(trainers ? UITheme.Blue : UITheme.Grey);
            Tick();
        }

        UpgradeCard MakeUpgrade(RectTransform parent, UpgradeData u)
        {
            var c = new UpgradeCard { data = u };
            var bg = UIFactory.Panel(parent, "Upgrade_" + u.id, UITheme.Card, 22);
            UIFactory.Layout(bg, -1, 130);
            var rt = bg.rectTransform;
            var circle = UIFactory.Panel(rt, "IconBg", u.color, 48);
            UIFactory.Place(circle.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(18, 0), new Vector2(96, 96));
            var ic = UIFactory.Icon(circle.transform, IconFor(u.effect), Color.white, 60);
            UIFactory.Place(ic.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(60, 60));
            var name = UIFactory.Text(rt, u.displayName, 32, Color.white, TextAlignmentOptions.TopLeft, true, true);
            UIFactory.Place(name.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(134, -14), new Vector2(420, 42));
            var desc = UIFactory.Text(rt, u.description, 22, UITheme.TextDim, TextAlignmentOptions.TopLeft, false, true);
            UIFactory.Place(desc.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(134, -56), new Vector2(420, 30));
            c.level = UIFactory.Text(rt, "", 20, UITheme.Yellow, TextAlignmentOptions.MidlineLeft, true, true);
            UIFactory.Place(c.level.rectTransform, new Vector2(0, 0), new Vector2(0, 0), new Vector2(134, 12), new Vector2(150, 30));
            c.bar = UIFactory.Bar(rt, new Color(1, 1, 1, 0.12f), u.color, 8);
            UIFactory.Place(c.bar.root, new Vector2(0, 0), new Vector2(0, 0), new Vector2(286, 18), new Vector2(270, 18));
            c.effect = UIFactory.Text(rt, "", 26, Color.white, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(c.effect.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(150, 0), new Vector2(380, 80));
            var card = c;
            c.buy = UIFactory.Button(rt, "", UITheme.Green, () => BuyUpgrade(card), 28, null, 20);
            UIFactory.Place((RectTransform)c.buy.button.transform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(-18, 0), new Vector2(320, 96));
            return c;
        }

        static IconId IconFor(UpgradeEffect e)
        {
            switch (e)
            {
                case UpgradeEffect.PenCapacity: return IconId.Paw;
                case UpgradeEffect.StrongArms: return IconId.Power;
                case UpgradeEffect.Luck: return IconId.Star;
                case UpgradeEffect.OfflineHours: return IconId.Clock;
                default: return IconId.Upgrade;
            }
        }

        TrainerCard MakeTrainer(RectTransform parent, TrainerData t)
        {
            var c = new TrainerCard { data = t };
            c.bg = UIFactory.Panel(parent, "Trainer_" + t.id, UITheme.Card, 22);
            UIFactory.Layout(c.bg, -1, 150);
            var rt = c.bg.rectTransform;
            var pbg = UIFactory.Panel(rt, "PortraitBg", new Color(t.color.r, t.color.g, t.color.b, 0.25f), 20);
            UIFactory.Place(pbg.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(14, 0), new Vector2(124, 124));
            var portrait = UIFactory.Raw(pbg.transform, Portraits.Trainer(t), 124);
            UIFactory.Stretch(portrait.rectTransform);
            var name = UIFactory.Text(rt, t.displayName, 34, Color.white, TextAlignmentOptions.TopLeft, true, true);
            UIFactory.Place(name.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(156, -16), new Vector2(600, 44));
            var desc = UIFactory.Text(rt, t.description, 22, UITheme.TextDim, TextAlignmentOptions.TopLeft, false, true);
            UIFactory.Place(desc.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(156, -62), new Vector2(600, 30));
            c.info = UIFactory.Text(rt, "", 24, UITheme.Yellow, TextAlignmentOptions.TopLeft, true, true);
            UIFactory.Place(c.info.rectTransform, new Vector2(0, 0), new Vector2(0, 0), new Vector2(156, 14), new Vector2(620, 34));
            var card = c;
            c.buy = UIFactory.Button(rt, "", UITheme.Green, () => BuyTrainer(card), 28, null, 20);
            UIFactory.Place((RectTransform)c.buy.button.transform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(-18, 0), new Vector2(320, 100));
            return c;
        }

        protected override void Refresh() => Tick();

        protected override void Tick()
        {
            var up = G.Upgrades;
            _stats.text = "Сила " + G.State.powerLevel + "   •   Идеальный заброс: до " + NumberFormat.Meters(G.ThrowPerfectDistance) +
                          "   •   Удача ×" + up.LuckMultiplier.ToString("0.00") + "   •   Опыт ×" + up.XpMultiplier.ToString("0.00") +
                          "   •   Офлайн: " + up.OfflineHours.ToString("0") + " ч";
            Subtitle.text = "Деньги: " + NumberFormat.Money(G.Economy.Money);
            if (!_showTrainers)
            {
                foreach (var c in _upgrades)
                {
                    int lvl = up.Level(c.data.id);
                    bool maxed = up.IsMaxed(c.data);
                    c.level.text = "Ур. " + lvl + " / " + c.data.maxLevel;
                    c.bar.Set(lvl / (float)Mathf.Max(1, c.data.maxLevel));
                    c.effect.text = maxed ? up.EffectText(c.data, lvl) + "\n<size=18><color=#B8C2E0>максимум</color></size>"
                                          : up.EffectText(c.data, lvl) + "  <color=#FFD23F>»</color>  " + up.EffectText(c.data, lvl + 1);
                    if (maxed) c.buy.SetState("МАКСИМУМ", UITheme.Grey, false);
                    else
                    {
                        double cost = up.Cost(c.data);
                        bool afford = G.Economy.CanAfford(cost);
                        c.buy.SetState((afford ? "КУПИТЬ " : "") + NumberFormat.Money(cost), afford ? UITheme.Green : UITheme.Grey, afford);
                    }
                }
            }
            else
            {
                var best = G.Trainers.Best;
                foreach (var c in _trainers)
                {
                    var t = c.data;
                    bool owned = G.Trainers.Owns(t), unlocked = G.Trainers.IsUnlocked(t);
                    c.info.text = "+" + NumberFormat.Short(t.xpPerRep) + " опыта за повтор (×" + up.XpMultiplier.ToString("0.00") + " с бонусом)";
                    c.bg.color = best == t ? Color.Lerp(UITheme.Card, UITheme.Blue, 0.25f) : UITheme.Card;
                    if (owned) c.buy.SetState(best == t ? "ИСПОЛЬЗУЕТСЯ" : "КУПЛЕНО", UITheme.Grey, false);
                    else if (!unlocked) c.buy.SetState("Нужна сила " + t.requiredPowerLevel, UITheme.Grey, false);
                    else
                    {
                        bool afford = G.Economy.CanAfford(t.price);
                        c.buy.SetState((afford ? "КУПИТЬ " : "") + NumberFormat.Money(t.price), afford ? UITheme.Green : UITheme.Grey, afford);
                    }
                }
            }
        }

        void BuyUpgrade(UpgradeCard c)
        {
            var r = G.Upgrades.TryBuy(c.data);
            if (r == PurchaseResult.Ok)
            {
                G.Vfx.Coins(G.Player.transform.position + Vector3.up * 2f);
                GameEvents.RaiseToast(c.data.displayName + ": уровень " + G.Upgrades.Level(c.data.id) + "!", UITheme.Money);
            }
            else G.Sound.Play(Audio.Sfx.Error);
            Tick();
        }

        void BuyTrainer(TrainerCard c)
        {
            var r = G.Trainers.TryBuy(c.data);
            if (r == PurchaseResult.Ok)
            {
                G.Vfx.Coins(G.Player.transform.position + Vector3.up * 2f);
                GameEvents.RaiseToast("Новый тренажёр: " + c.data.displayName + "!", UITheme.Money);
            }
            else G.Sound.Play(Audio.Sfx.Error);
            Tick();
        }
    }
}
