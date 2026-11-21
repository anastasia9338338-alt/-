using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using ZooThrow.Animals;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.SaveSystem;

namespace ZooThrow.UI
{
    /// <summary>Inventory and pen management: place, remove, replace, sell.</summary>
    public class AnimalsWindow : UIWindow
    {
        class SlotCard
        {
            public UIButton button;
            public RawImage portrait;
            public TextMeshProUGUI name, income;
            public Image lockIcon, stripe;
            public int slot;
        }

        class AnimalCard
        {
            public RectTransform root;
            public Image stripe;
            public RawImage portrait;
            public TextMeshProUGUI name, rarity, income, mutation, placedBadge;
            public UIButton place, sell;
            public OwnedAnimal animal;
        }

        TextMeshProUGUI _stats;
        RectTransform _grid;
        TextMeshProUGUI _empty;
        readonly List<SlotCard> _slots = new List<SlotCard>();
        readonly List<AnimalCard> _cards = new List<AnimalCard>();
        readonly List<OwnedAnimal> _sorted = new List<OwnedAnimal>();

        protected override void BuildBody(RectTransform body)
        {
            var top = UIFactory.Rect("Top", body);
            UIFactory.Place(top, new Vector2(0, 1), new Vector2(0, 1), Vector2.zero, new Vector2(0, 64));
            top.anchorMax = new Vector2(1, 1);
            top.sizeDelta = new Vector2(0, 64);
            _stats = UIFactory.Text(top, "", 28, Color.white, TextAlignmentOptions.MidlineLeft, true, true);
            UIFactory.Stretch(_stats.rectTransform, 4, 0, 760, 0);
            var best = UIFactory.Button(top, "ЛУЧШИХ В АКВАРИУМ", UITheme.Blue, () =>
            {
                G.Pen.ArrangeBest();
                GameEvents.RaiseToast("В аквариуме самый доходный улов!", UITheme.Money);
            }, 24, IconId.Upgrade, 18);
            UIFactory.Place((RectTransform)best.button.transform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(-400, 0), new Vector2(350, 62));
            var sellAll = UIFactory.Button(top, "ПРОДАТЬ ВСЁ ВНЕ АКВАРИУМА", UITheme.Red, SellAllClicked, 22, IconId.Coin, 18);
            UIFactory.Place((RectTransform)sellAll.button.transform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(0, 0), new Vector2(390, 62));

            // Pen strip
            var penPanel = UIFactory.Panel(body, "Pen", UITheme.Card, 22);
            var prt = penPanel.rectTransform;
            prt.anchorMin = new Vector2(0, 1); prt.anchorMax = new Vector2(1, 1); prt.pivot = new Vector2(0.5f, 1);
            prt.offsetMin = new Vector2(0, -280); prt.offsetMax = new Vector2(0, -76);
            var penTitle = UIFactory.Text(prt, "АКВАРИУМ — нажми на существо, чтобы вернуть его в садок", 22, UITheme.TextDim, TextAlignmentOptions.MidlineLeft, true, true);
            UIFactory.Place(penTitle.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(16, -6), new Vector2(1200, 34));
            var row = UIFactory.Rect("Slots", prt);
            row.anchorMin = new Vector2(0, 0); row.anchorMax = new Vector2(1, 1);
            row.offsetMin = new Vector2(12, 10); row.offsetMax = new Vector2(-12, -42);
            UIFactory.HLayout(row, 8, null, TextAnchor.MiddleCenter, false, true);
            for (int i = 0; i < G.Balance.maxPenSlots; i++) _slots.Add(MakeSlot(row, i));

            // Inventory grid
            var scrollRoot = UIFactory.Rect("InventoryArea", body);
            scrollRoot.anchorMin = Vector2.zero; scrollRoot.anchorMax = Vector2.one;
            scrollRoot.offsetMin = Vector2.zero; scrollRoot.offsetMax = new Vector2(0, -292);
            _grid = UIFactory.Scroll(scrollRoot, out _);
            UIFactory.Stretch((RectTransform)_grid.parent.parent);
            UIFactory.Grid(_grid, new Vector2(272, 330), new Vector2(14, 14), 5, new RectOffset(4, 4, 4, 8));
            _empty = UIFactory.Text(scrollRoot, "Садок пуст. Закинь удочку, чтобы поймать первую рыбу!", 30, UITheme.TextDim, TextAlignmentOptions.Center, true, true);
            UIFactory.Stretch(_empty.rectTransform);
        }

        SlotCard MakeSlot(Transform parent, int slot)
        {
            var c = new SlotCard { slot = slot };
            c.button = UIFactory.Button(parent, null, UITheme.CardLight, () => SlotClicked(slot), 20, null, 16);
            UIFactory.Layout(c.button.button, 108, 150);
            var face = c.button.bg.transform;
            c.stripe = UIFactory.Panel(face, "Stripe", Color.white, 6);
            UIFactory.Place(c.stripe.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -4), new Vector2(92, 8));
            c.portrait = UIFactory.Raw(face, null, 92);
            UIFactory.Place(c.portrait.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -12), new Vector2(92, 92));
            c.name = UIFactory.Text(face, "", 16, Color.white, TextAlignmentOptions.Center, true, true);
            c.name.enableWordWrapping = false;
            UIFactory.Place(c.name.rectTransform, new Vector2(0.5f, 0), new Vector2(0.5f, 0), new Vector2(0, 22), new Vector2(104, 22));
            c.income = UIFactory.Text(face, "", 15, UITheme.Money, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(c.income.rectTransform, new Vector2(0.5f, 0), new Vector2(0.5f, 0), new Vector2(0, 2), new Vector2(104, 22));
            c.lockIcon = UIFactory.Icon(face, IconId.Lock, new Color(1, 1, 1, 0.5f), 54);
            UIFactory.Place(c.lockIcon.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, 14), new Vector2(54, 54));
            return c;
        }

        AnimalCard MakeCard()
        {
            var c = new AnimalCard();
            var bg = UIFactory.Panel(_grid, "Card", UITheme.Card, 22);
            c.root = bg.rectTransform;
            c.stripe = UIFactory.Panel(c.root, "Stripe", Color.white, 22);
            UIFactory.Place(c.stripe.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), Vector2.zero, new Vector2(272, 168));
            c.stripe.gameObject.AddComponent<VerticalGradient>().bottom = new Color(0.35f, 0.35f, 0.45f);
            c.portrait = UIFactory.Raw(c.root, null, 160);
            UIFactory.Place(c.portrait.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -4), new Vector2(160, 160));
            c.rarity = UIFactory.Text(c.root, "", 16, Color.white, TextAlignmentOptions.TopLeft, true, true);
            UIFactory.Place(c.rarity.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(10, -8), new Vector2(200, 24));
            c.mutation = UIFactory.Text(c.root, "", 16, UITheme.Gold, TextAlignmentOptions.TopRight, true, true);
            UIFactory.Place(c.mutation.rectTransform, new Vector2(1, 1), new Vector2(1, 1), new Vector2(-10, -8), new Vector2(150, 24));
            c.name = UIFactory.Text(c.root, "", 24, Color.white, TextAlignmentOptions.Center, true, true);
            c.name.enableWordWrapping = false;
            UIFactory.Place(c.name.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -170), new Vector2(260, 32));
            c.income = UIFactory.Text(c.root, "", 22, UITheme.Money, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(c.income.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -202), new Vector2(260, 30));
            c.placedBadge = UIFactory.Text(c.root, "В АКВАРИУМЕ", 16, UITheme.Yellow, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(c.placedBadge.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -232), new Vector2(260, 22));
            var card = c;
            c.place = UIFactory.Button(c.root, "В АКВАРИУМ", UITheme.Blue, () => PlaceClicked(card), 18, null, 14);
            UIFactory.Place((RectTransform)c.place.button.transform, new Vector2(0, 0), new Vector2(0, 0), new Vector2(10, 10), new Vector2(122, 60));
            c.sell = UIFactory.Button(c.root, "ПРОДАТЬ", UITheme.Red, () => SellClicked(card), 16, null, 14);
            UIFactory.Place((RectTransform)c.sell.button.transform, new Vector2(1, 0), new Vector2(1, 0), new Vector2(-10, 10), new Vector2(122, 60));
            return c;
        }

        protected override void Refresh()
        {
            var inv = G.Inventory;
            var pen = G.Pen;
            _sorted.Clear();
            _sorted.AddRange(inv.All);
            _sorted.Sort((a, b) =>
            {
                int pa = pen.IsPlaced(a.uid) ? 0 : 1, pb = pen.IsPlaced(b.uid) ? 0 : 1;
                if (pa != pb) return pa.CompareTo(pb);
                return inv.IncomeOf(b).CompareTo(inv.IncomeOf(a));
            });
            while (_cards.Count < _sorted.Count) _cards.Add(MakeCard());
            for (int i = 0; i < _cards.Count; i++)
            {
                var c = _cards[i];
                bool on = i < _sorted.Count;
                if (c.root.gameObject.activeSelf != on) c.root.gameObject.SetActive(on);
                if (on) BindCard(c, _sorted[i]);
            }
            _empty.gameObject.SetActive(_sorted.Count == 0);

            for (int i = 0; i < _slots.Count; i++) BindSlot(_slots[i]);
            Subtitle.text = "Инвентарь " + inv.Count + " / " + inv.Capacity;
        }

        void BindCard(AnimalCard c, OwnedAnimal a)
        {
            c.animal = a;
            var data = G.Inventory.DataOf(a);
            var rarity = G.Db.GetRarity(data.rarity);
            c.stripe.color = Color.Lerp(rarity.color, UITheme.Card, 0.35f);
            c.portrait.texture = Portraits.Animal(data);
            c.rarity.text = rarity.displayName;
            c.rarity.color = Color.Lerp(rarity.color, Color.white, 0.3f);
            c.mutation.text = AnimalRoller.MutationName(a.mutation);
            c.mutation.color = a.mutation == Mutation.Rainbow ? new Color(1f, 0.5f, 0.9f) : a.mutation == Mutation.Giant ? new Color(0.6f, 0.9f, 1f) : UITheme.Gold;
            c.name.text = data.displayName;
            c.income.text = "+" + NumberFormat.PerSecond(G.Inventory.IncomeOf(a));
            bool placed = G.Pen.IsPlaced(a.uid);
            c.placedBadge.gameObject.SetActive(placed);
            c.place.label.text = placed ? "УБРАТЬ" : "В АКВАРИУМ";
            c.place.SetColor(placed ? UITheme.Grey : UITheme.Blue);
            c.sell.label.text = NumberFormat.Money(G.Inventory.SellPrice(a));
        }

        void BindSlot(SlotCard c)
        {
            var pen = G.Pen;
            bool unlocked = pen.IsSlotUnlocked(c.slot);
            var owned = unlocked ? G.Inventory.Get(pen.SlotUid(c.slot)) : null;
            c.lockIcon.gameObject.SetActive(!unlocked || owned == null);
            c.lockIcon.sprite = SpriteFactory.Icon(unlocked ? IconId.Paw : IconId.Lock);
            c.lockIcon.color = unlocked ? new Color(1, 1, 1, 0.18f) : new Color(1, 1, 1, 0.5f);
            c.portrait.gameObject.SetActive(owned != null);
            if (owned != null)
            {
                var data = G.Inventory.DataOf(owned);
                c.portrait.texture = Portraits.Animal(data);
                c.name.text = data.displayName;
                c.income.text = NumberFormat.PerSecond(G.Inventory.IncomeOf(owned));
                c.stripe.color = G.Db.GetRarity(data.rarity).color;
            }
            else
            {
                c.name.text = unlocked ? "Пусто" : "Закрыто";
                c.income.text = unlocked ? "" : "Улучшения";
                c.stripe.color = new Color(1, 1, 1, 0.1f);
            }
            c.button.SetColor(unlocked ? UITheme.CardLight : new Color(0.12f, 0.14f, 0.24f));
        }

        protected override void Tick()
        {
            _stats.text = "Аквариум " + G.Pen.PlacedCount + "/" + G.Pen.Capacity + "   •   <color=#73FF80>+" + NumberFormat.PerSecond(G.Pen.TotalIncome) + "</color>";
        }

        void SlotClicked(int slot)
        {
            var pen = G.Pen;
            if (!pen.IsSlotUnlocked(slot))
            {
                UI.Open(WindowId.Upgrades);
                return;
            }
            int uid = pen.SlotUid(slot);
            if (uid != 0) pen.RemoveIfPlaced(uid);
        }

        void PlaceClicked(AnimalCard c)
        {
            if (c.animal == null) return;
            var pen = G.Pen;
            if (pen.IsPlaced(c.animal.uid))
            {
                pen.RemoveIfPlaced(c.animal.uid);
                return;
            }
            if (pen.Place(c.animal)) return;
            if (pen.PlaceOrReplaceWeakest(c.animal))
            {
                GameEvents.RaiseToast("Заменили самое слабое существо в аквариуме", UITheme.Yellow);
                return;
            }
            G.Sound.Play(Audio.Sfx.Error);
            GameEvents.RaiseToast("Аквариум полон, и все в нём доходнее. Улучши аквариум!", UITheme.Red);
        }

        void SellClicked(AnimalCard c)
        {
            var a = c.animal;
            if (a == null) return;
            var data = G.Inventory.DataOf(a);
            if (data.rarity >= Rarity.Epic || a.mutation != Mutation.None)
            {
                UI.Confirm("Продать?", data.displayName + " — " + G.Db.GetRarity(data.rarity).displayName.ToLowerInvariant() + " существо.\nТы получишь " + NumberFormat.Money(G.Inventory.SellPrice(a)) + ".",
                    "ПРОДАТЬ", UITheme.Red, () => DoSell(a));
            }
            else DoSell(a);
        }

        void DoSell(OwnedAnimal a)
        {
            double price = G.Inventory.Sell(a, G.Pen);
            if (price > 0)
            {
                G.Sound.Play(Audio.Sfx.Coin);
                GameEvents.RaiseToast("+" + NumberFormat.Money(price), UITheme.Money);
            }
        }

        void SellAllClicked()
        {
            int count = 0;
            double total = 0;
            foreach (var a in G.Inventory.All)
                if (!G.Pen.IsPlaced(a.uid)) { count++; total += G.Inventory.SellPrice(a); }
            if (count == 0)
            {
                GameEvents.RaiseToast("Весь улов уже в аквариуме", UITheme.Yellow);
                return;
            }
            UI.Confirm("Продать " + count + " шт.?", "Весь улов вне аквариума будет продан за " + NumberFormat.Money(total) + ".\nСущества в аквариуме останутся.", "ПРОДАТЬ", UITheme.Red, () =>
            {
                double sum = G.Inventory.SellAllNotPlaced(G.Pen, out int n);
                G.Sound.Play(Audio.Sfx.Coin);
                GameEvents.RaiseToast("Продано " + n + " за " + NumberFormat.Money(sum), UITheme.Money);
            });
        }
    }
}
