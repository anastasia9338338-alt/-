using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Economy;

namespace ZooThrow.UI
{
    /// <summary>Food shop: buy permanent foods, pick which one to throw.</summary>
    public class ShopWindow : UIWindow
    {
        class FoodCard
        {
            public FoodData food;
            public Image bg;
            public RawImage portrait;
            public TextMeshProUGUI name, desc, stats;
            public UIButton action;
            public Image lockIcon;
        }

        readonly List<FoodCard> _cards = new List<FoodCard>();

        protected override void BuildBody(RectTransform body)
        {
            var content = UIFactory.Scroll(body, out _);
            UIFactory.Stretch((RectTransform)content.parent.parent);
            UIFactory.VLayout(content, 14, new RectOffset(4, 8, 4, 8), TextAnchor.UpperCenter, true, false);
            foreach (var f in G.Db.foods) _cards.Add(MakeCard(content, f));
        }

        FoodCard MakeCard(RectTransform parent, FoodData f)
        {
            var c = new FoodCard { food = f };
            c.bg = UIFactory.Panel(parent, "Food_" + f.id, UITheme.Card, 22);
            UIFactory.Layout(c.bg, -1, 156);
            var rt = c.bg.rectTransform;
            var pbg = UIFactory.Panel(rt, "PortraitBg", new Color(f.primary.r, f.primary.g, f.primary.b, 0.25f), 20);
            UIFactory.Place(pbg.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(14, 0), new Vector2(130, 130));
            c.portrait = UIFactory.Raw(pbg.transform, Portraits.Food(f), 130);
            UIFactory.Stretch(c.portrait.rectTransform);
            c.lockIcon = UIFactory.Icon(pbg.transform, IconId.Lock, new Color(1, 1, 1, 0.85f), 56);
            c.name = UIFactory.Text(rt, f.displayName, 36, Color.white, TextAlignmentOptions.TopLeft, true, true);
            c.name.enableWordWrapping = false;
            UIFactory.Place(c.name.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(166, -16), new Vector2(560, 46));
            c.desc = UIFactory.Text(rt, f.description, 22, UITheme.TextDim, TextAlignmentOptions.TopLeft, false, true);
            UIFactory.Place(c.desc.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(166, -62), new Vector2(560, 56));
            c.stats = UIFactory.Text(rt, "", 24, UITheme.Yellow, TextAlignmentOptions.TopLeft, true, true);
            UIFactory.Place(c.stats.rectTransform, new Vector2(0, 0), new Vector2(0, 0), new Vector2(166, 12), new Vector2(620, 34));
            var card = c;
            c.action = UIFactory.Button(rt, "", UITheme.Green, () => Clicked(card), 28, null, 20);
            UIFactory.Place((RectTransform)c.action.button.transform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(-18, 0), new Vector2(380, 100));
            return c;
        }

        protected override void Refresh() => Tick();

        protected override void Tick()
        {
            var shop = G.Foods;
            foreach (var c in _cards)
            {
                var f = c.food;
                bool owned = shop.Owns(f), unlocked = shop.IsUnlocked(f), selected = shop.Selected == f;
                c.lockIcon.gameObject.SetActive(!unlocked && !owned);
                c.portrait.color = unlocked || owned ? Color.white : new Color(0.1f, 0.1f, 0.15f, 0.9f);
                c.stats.text = (f.distanceBonus > 0 ? "+" + f.distanceBonus.ToString("0") + " м дальности" : "Без бонуса к дальности") + "   •   Удача ×" + f.luck.ToString("0.00");
                c.bg.color = selected ? Color.Lerp(UITheme.Card, UITheme.Orange, 0.25f) : UITheme.Card;
                if (selected) c.action.SetState("ВЫБРАНО", UITheme.Grey, false);
                else if (owned) c.action.SetState("ВЫБРАТЬ", UITheme.Blue, true);
                else if (!unlocked) c.action.SetState(shop.LockReason(f), UITheme.Grey, false);
                else
                {
                    bool afford = G.Economy.CanAfford(f.price);
                    c.action.SetState((afford ? "КУПИТЬ " : "") + NumberFormat.Money(f.price), afford ? UITheme.Green : UITheme.Grey, afford);
                }
                if (c.action.label != null) c.action.label.fontSize = c.action.label.text.Length > 18 ? 20 : 28;
            }
            Subtitle.text = "Деньги: " + NumberFormat.Money(G.Economy.Money);
        }

        void Clicked(FoodCard c)
        {
            var shop = G.Foods;
            if (shop.Owns(c.food)) { shop.Select(c.food); Tick(); return; }
            var r = shop.TryBuy(c.food);
            if (r == PurchaseResult.Ok)
            {
                G.Vfx.Coins(G.Player.transform.position + Vector3.up * 2f);
                GameEvents.RaiseToast("Куплено: " + c.food.displayName + "!", UITheme.Money);
            }
            else
            {
                G.Sound.Play(Audio.Sfx.Error);
                GameEvents.RaiseToast(r == PurchaseResult.NotEnoughMoney ? "Не хватает денег" : shop.LockReason(c.food), UITheme.Red);
            }
            Tick();
        }
    }
}
