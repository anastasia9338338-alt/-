using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Economy;

namespace ZooThrow.UI
{
    /// <summary>
    /// Shared layout for the two gear shops: a list of cards with a 3D portrait, description, stats and one
    /// action button (buy / select / selected / locked). Subclasses describe their items.
    /// </summary>
    public abstract class GearShopWindow : UIWindow
    {
        class Card
        {
            public int index;
            public Image bg;
            public RawImage portrait;
            public TextMeshProUGUI stats;
            public UIButton action;
            public Image lockIcon;
        }

        readonly List<Card> _cards = new List<Card>();

        protected abstract int Count { get; }
        protected abstract string ItemName(int i);
        protected abstract string ItemDescription(int i);
        protected abstract string ItemStats(int i);
        protected abstract Texture ItemPortrait(int i);
        protected abstract Color ItemTint(int i);
        protected abstract double ItemPrice(int i);
        protected abstract bool IsOwned(int i);
        protected abstract bool IsSelected(int i);
        protected abstract bool IsUnlocked(int i);
        protected abstract string LockReason(int i);
        protected abstract PurchaseResult Buy(int i);
        protected abstract void Select(int i);
        protected abstract Color Accent { get; }

        protected override void BuildBody(RectTransform body)
        {
            var content = UIFactory.Scroll(body, out _);
            UIFactory.Stretch((RectTransform)content.parent.parent);
            UIFactory.VLayout(content, 14, new RectOffset(4, 8, 4, 8), TextAnchor.UpperCenter, true, false);
            for (int i = 0; i < Count; i++) _cards.Add(MakeCard(content, i));
        }

        Card MakeCard(RectTransform parent, int i)
        {
            var c = new Card { index = i };
            c.bg = UIFactory.Panel(parent, "Item_" + i, UITheme.Card, 22);
            UIFactory.Layout(c.bg, -1, 156);
            var rt = c.bg.rectTransform;
            var tint = ItemTint(i);
            var pbg = UIFactory.Panel(rt, "PortraitBg", new Color(tint.r, tint.g, tint.b, 0.25f), 20);
            UIFactory.Place(pbg.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(14, 0), new Vector2(130, 130));
            c.portrait = UIFactory.Raw(pbg.transform, ItemPortrait(i), 130);
            UIFactory.Stretch(c.portrait.rectTransform);
            c.lockIcon = UIFactory.Icon(pbg.transform, IconId.Lock, new Color(1, 1, 1, 0.85f), 56);
            var name = UIFactory.Text(rt, ItemName(i), 34, Color.white, TextAlignmentOptions.TopLeft, true, true);
            name.enableWordWrapping = false;
            UIFactory.Place(name.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(166, -16), new Vector2(600, 46));
            var desc = UIFactory.Text(rt, ItemDescription(i), 22, UITheme.TextDim, TextAlignmentOptions.TopLeft, false, true);
            UIFactory.Place(desc.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(166, -62), new Vector2(600, 56));
            c.stats = UIFactory.Text(rt, "", 24, UITheme.Yellow, TextAlignmentOptions.TopLeft, true, true);
            UIFactory.Place(c.stats.rectTransform, new Vector2(0, 0), new Vector2(0, 0), new Vector2(166, 12), new Vector2(680, 34));
            var card = c;
            c.action = UIFactory.Button(rt, "", UITheme.Green, () => Clicked(card), 28, null, 20);
            UIFactory.Place((RectTransform)c.action.button.transform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(-18, 0), new Vector2(380, 100));
            return c;
        }

        protected override void Refresh() => Tick();

        protected override void Tick()
        {
            foreach (var c in _cards)
            {
                int i = c.index;
                bool owned = IsOwned(i), unlocked = IsUnlocked(i), selected = IsSelected(i);
                c.lockIcon.gameObject.SetActive(!unlocked && !owned);
                c.portrait.color = unlocked || owned ? Color.white : new Color(0.1f, 0.1f, 0.15f, 0.9f);
                c.stats.text = ItemStats(i);
                c.bg.color = selected ? Color.Lerp(UITheme.Card, Accent, 0.25f) : UITheme.Card;
                if (selected) c.action.SetState("ВЫБРАНО", UITheme.Grey, false);
                else if (owned) c.action.SetState("ВЫБРАТЬ", UITheme.Blue, true);
                else if (!unlocked) c.action.SetState(LockReason(i), UITheme.Grey, false);
                else
                {
                    double price = ItemPrice(i);
                    bool afford = G.Economy.CanAfford(price);
                    c.action.SetState((afford ? "КУПИТЬ " : "") + NumberFormat.Money(price), afford ? UITheme.Green : UITheme.Grey, afford);
                }
                if (c.action.label != null) c.action.label.fontSize = c.action.label.text.Length > 18 ? 20 : 28;
            }
            Subtitle.text = "Деньги: " + NumberFormat.Money(G.Economy.Money);
        }

        void Clicked(Card c)
        {
            int i = c.index;
            if (IsOwned(i)) { Select(i); Tick(); return; }
            var r = Buy(i);
            if (r == PurchaseResult.Ok)
            {
                G.Vfx.Coins(G.Player.transform.position + Vector3.up * 2f);
                GameEvents.RaiseToast("Куплено: " + ItemName(i) + "!", UITheme.Money);
            }
            else
            {
                G.Sound.Play(Audio.Sfx.Error);
                GameEvents.RaiseToast(r == PurchaseResult.NotEnoughMoney ? "Не хватает денег" : LockReason(i), UITheme.Red);
            }
            Tick();
        }
    }

    /// <summary>Shop 1: fishing rods. Rods add cast distance.</summary>
    public class RodShopWindow : GearShopWindow
    {
        List<RodData> Items => G.Db.rods;
        protected override int Count => Items.Count;
        protected override Color Accent => UITheme.Orange;
        protected override string ItemName(int i) => Items[i].displayName;
        protected override string ItemDescription(int i) => Items[i].description;
        protected override string ItemStats(int i)
        {
            var r = Items[i];
            return (r.distanceBonus > 0 ? "+" + r.distanceBonus.ToString("0") + " м к забросу" : "Без бонуса к дальности") +
                   (r.luck > 1.001f ? "   •   Удача ×" + r.luck.ToString("0.00") : "");
        }
        protected override Texture ItemPortrait(int i) => Portraits.Rod(Items[i]);
        protected override Color ItemTint(int i) => Items[i].primary;
        protected override double ItemPrice(int i) => Items[i].price;
        protected override bool IsOwned(int i) => G.Rods.Owns(Items[i]);
        protected override bool IsSelected(int i) => G.Rods.Selected == Items[i];
        protected override bool IsUnlocked(int i) => G.Rods.IsUnlocked(Items[i]);
        protected override string LockReason(int i) => G.Rods.LockReason(Items[i]);
        protected override PurchaseResult Buy(int i) => G.Rods.TryBuy(Items[i]);
        protected override void Select(int i) => G.Rods.Select(Items[i]);
    }

    /// <summary>Shop 2: bait. Better bait raises the chance of rare catches.</summary>
    public class BaitShopWindow : GearShopWindow
    {
        List<BaitData> Items => G.Db.baits;
        protected override int Count => Items.Count;
        protected override Color Accent => UITheme.Green;
        protected override string ItemName(int i) => Items[i].displayName;
        protected override string ItemDescription(int i) => Items[i].description;
        protected override string ItemStats(int i)
        {
            var b = Items[i];
            return "Удача ×" + b.luck.ToString("0.00") + (b.distanceBonus > 0 ? "   •   +" + b.distanceBonus.ToString("0") + " м" : "");
        }
        protected override Texture ItemPortrait(int i) => Portraits.Bait(Items[i]);
        protected override Color ItemTint(int i) => Items[i].primary;
        protected override double ItemPrice(int i) => Items[i].price;
        protected override bool IsOwned(int i) => G.Baits.Owns(Items[i]);
        protected override bool IsSelected(int i) => G.Baits.Selected == Items[i];
        protected override bool IsUnlocked(int i) => G.Baits.IsUnlocked(Items[i]);
        protected override string LockReason(int i) => G.Baits.LockReason(Items[i]);
        protected override PurchaseResult Buy(int i) => G.Baits.TryBuy(Items[i]);
        protected override void Select(int i) => G.Baits.Select(Items[i]);
    }
}
