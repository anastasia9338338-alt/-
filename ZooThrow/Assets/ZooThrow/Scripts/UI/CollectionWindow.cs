using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using ZooThrow.Animals;
using ZooThrow.Core;
using ZooThrow.Data;

namespace ZooThrow.UI
{
    /// <summary>Animal index per biome: discovered species, chances with the current food, locked biomes.</summary>
    public class CollectionWindow : UIWindow
    {
        class SpeciesCard
        {
            public RectTransform root;
            public Image stripe;
            public RawImage portrait;
            public TextMeshProUGUI name, rarity, chance, income, trait;
        }

        readonly List<UIButton> _tabs = new List<UIButton>();
        readonly List<SpeciesCard> _cards = new List<SpeciesCard>();
        readonly List<AnimalData> _species = new List<AnimalData>();
        RectTransform _grid;
        TextMeshProUGUI _biomeInfo;
        int _biomeIndex;

        protected override void BuildBody(RectTransform body)
        {
            var tabs = UIFactory.Rect("Tabs", body);
            tabs.anchorMin = new Vector2(0, 1); tabs.anchorMax = new Vector2(1, 1); tabs.pivot = new Vector2(0.5f, 1);
            tabs.offsetMin = new Vector2(0, -74); tabs.offsetMax = Vector2.zero;
            tabs.offsetMin = new Vector2(0, -150);
            // Twelve locations: two rows of tabs.
            var grid = tabs.gameObject.AddComponent<GridLayoutGroup>();
            grid.cellSize = new Vector2(232, 68);
            grid.spacing = new Vector2(10, 10);
            grid.constraint = GridLayoutGroup.Constraint.FixedColumnCount;
            grid.constraintCount = 6;
            for (int i = 0; i < G.Db.biomes.Count; i++)
            {
                int index = i;
                var b = UIFactory.Button(tabs, G.Db.biomes[i].displayName, UITheme.Grey, () => { _biomeIndex = index; Refresh(); }, 16, null, 16);
                _tabs.Add(b);
            }
            _biomeInfo = UIFactory.Text(body, "", 24, UITheme.TextDim, TextAlignmentOptions.MidlineLeft, true, true);
            var irt = _biomeInfo.rectTransform;
            irt.anchorMin = new Vector2(0, 1); irt.anchorMax = new Vector2(1, 1); irt.pivot = new Vector2(0.5f, 1);
            irt.offsetMin = new Vector2(6, -204); irt.offsetMax = new Vector2(-6, -158);

            var area = UIFactory.Rect("Grid", body);
            area.anchorMin = Vector2.zero; area.anchorMax = Vector2.one;
            area.offsetMin = Vector2.zero; area.offsetMax = new Vector2(0, -212);
            _grid = UIFactory.Scroll(area, out _);
            UIFactory.Stretch((RectTransform)_grid.parent.parent);
            UIFactory.Grid(_grid, new Vector2(274, 336), new Vector2(14, 14), 5, new RectOffset(4, 4, 4, 8));
        }

        SpeciesCard MakeCard()
        {
            var c = new SpeciesCard();
            var bg = UIFactory.Panel(_grid, "Species", UITheme.Card, 22);
            c.root = bg.rectTransform;
            c.stripe = UIFactory.Panel(c.root, "Stripe", Color.white, 22);
            UIFactory.Place(c.stripe.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), Vector2.zero, new Vector2(274, 172));
            c.stripe.gameObject.AddComponent<VerticalGradient>().bottom = new Color(0.35f, 0.35f, 0.45f);
            c.portrait = UIFactory.Raw(c.root, null, 164);
            UIFactory.Place(c.portrait.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -4), new Vector2(164, 164));
            c.rarity = UIFactory.Text(c.root, "", 17, Color.white, TextAlignmentOptions.TopLeft, true, true);
            UIFactory.Place(c.rarity.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(10, -8), new Vector2(240, 24));
            c.name = UIFactory.Text(c.root, "", 26, Color.white, TextAlignmentOptions.Center, true, true);
            c.name.enableWordWrapping = false;
            UIFactory.Place(c.name.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -176), new Vector2(262, 34));
            c.income = UIFactory.Text(c.root, "", 21, UITheme.Money, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(c.income.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -210), new Vector2(262, 28));
            c.chance = UIFactory.Text(c.root, "", 20, UITheme.Yellow, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(c.chance.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -238), new Vector2(262, 28));
            c.trait = UIFactory.Text(c.root, "", 17, UITheme.TextDim, TextAlignmentOptions.Top, false, true);
            UIFactory.Place(c.trait.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -268), new Vector2(250, 60));
            return c;
        }

        protected override void Refresh()
        {
            var db = G.Db;
            _biomeIndex = Mathf.Clamp(_biomeIndex, 0, db.biomes.Count - 1);
            var biome = db.biomes[_biomeIndex];
            for (int i = 0; i < _tabs.Count; i++)
            {
                var b = db.biomes[i];
                int found = 0, total = 0;
                foreach (var a in db.animals) if (a.biomeId == b.id) { total++; if (G.Inventory.IsDiscovered(a.id)) found++; }
                bool unlocked = G.Biomes.IsUnlocked(b);
                _tabs[i].label.text = b.displayName + "\n<size=80%>" + (unlocked ? "" : "закрыто • ") + found + "/" + total + "</size>";
                _tabs[i].SetColor(i == _biomeIndex ? b.accentColor : unlocked ? UITheme.Grey : new Color(0.2f, 0.22f, 0.32f));
            }

            float luck = G.CurrentLuck;
            bool biomeOpen = G.Biomes.IsUnlocked(biome);
            _biomeInfo.text = biomeOpen
                ? biome.description + "   <color=#FFD23F>Шансы для «" + G.Rods.Selected.displayName + "» и наживки «" + G.Baits.Selected.displayName + "» (удача ×" + luck.ToString("0.00") + ").</color>"
                : "<color=#FF8A8A>Локация закрыта:</color> закинь удочку на " + NumberFormat.Meters(biome.startDistance) + ". Твой идеальный заброс сейчас: " + NumberFormat.Meters(G.ThrowPerfectDistance) + ".";

            _species.Clear();
            foreach (var a in db.animals) if (a.biomeId == biome.id) _species.Add(a);
            _species.Sort((x, y) => x.rarity.CompareTo(y.rarity));
            while (_cards.Count < _species.Count) _cards.Add(MakeCard());
            for (int i = 0; i < _cards.Count; i++)
            {
                var c = _cards[i];
                bool on = i < _species.Count;
                c.root.gameObject.SetActive(on);
                if (!on) continue;
                var a = _species[i];
                bool known = G.Inventory.IsDiscovered(a.id);
                var rarity = db.GetRarity(a.rarity);
                c.stripe.color = known ? Color.Lerp(rarity.color, UITheme.Card, 0.35f) : new Color(0.12f, 0.14f, 0.24f);
                c.portrait.texture = Portraits.Animal(a);
                c.portrait.color = known ? Color.white : new Color(0.03f, 0.04f, 0.08f, 0.92f);
                c.rarity.text = rarity.displayName;
                c.rarity.color = Color.Lerp(rarity.color, Color.white, 0.3f);
                c.name.text = known ? a.displayName : "???";
                c.income.text = known ? "+" + NumberFormat.PerSecond(AnimalRoller.Income(db, a, Mutation.None)) : "+$?/сек";
                c.chance.text = "Шанс: " + NumberFormat.OneIn(AnimalRoller.Chance(db, a, luck));
                c.trait.text = known ? a.trait : "Ещё не поймано";
            }
            Subtitle.text = "Открыто " + G.Inventory.DiscoveredCount + " / " + db.animals.Count;
        }
    }
}
