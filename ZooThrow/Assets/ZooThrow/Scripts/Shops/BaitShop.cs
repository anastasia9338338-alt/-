using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Economy;
using ZooThrow.SaveSystem;
using ZooThrow.World;

namespace ZooThrow.Shops
{
    public class BaitShop
    {
        readonly GameDatabase _db;
        readonly SaveData _s;
        readonly SaveManager _save;
        readonly EconomyManager _eco;
        readonly BiomeManager _biomes;

        public BaitShop(GameDatabase db, SaveManager save, EconomyManager eco, BiomeManager biomes)
        {
            _db = db; _save = save; _s = save.Data; _eco = eco; _biomes = biomes;
        }

        public BaitData Selected => _db.Bait(_s.selectedBait) ?? _db.Bait(_db.balance.startingBaitId);
        public bool Owns(BaitData f) => f != null && _s.ownedBaits.Contains(f.id);

        public bool IsUnlocked(BaitData f)
        {
            if (f == null) return false;
            if (!string.IsNullOrEmpty(f.requiredBiomeId) && !_biomes.IsUnlocked(f.requiredBiomeId)) return false;
            return _s.powerLevel >= f.requiredPowerLevel;
        }

        public string LockReason(BaitData f)
        {
            if (!string.IsNullOrEmpty(f.requiredBiomeId) && !_biomes.IsUnlocked(f.requiredBiomeId))
            {
                var b = _db.Biome(f.requiredBiomeId);
                return "Открой «" + (b != null ? b.displayName : f.requiredBiomeId) + "»";
            }
            if (_s.powerLevel < f.requiredPowerLevel) return "Нужна сила " + f.requiredPowerLevel;
            return "";
        }

        public PurchaseResult TryBuy(BaitData f)
        {
            if (f == null) return PurchaseResult.Unknown;
            if (Owns(f)) return PurchaseResult.AlreadyOwned;
            if (!IsUnlocked(f)) return PurchaseResult.Locked;
            if (!_eco.TrySpend(f.price)) return PurchaseResult.NotEnoughMoney;
            _s.ownedBaits.Add(f.id);
            _s.selectedBait = f.id; // freshly bought bait is always better, so equip it
            _save.MarkDirty();
            GameEvents.RaiseShopChanged();
            return PurchaseResult.Ok;
        }

        public bool Select(BaitData f)
        {
            if (!Owns(f)) return false;
            _s.selectedBait = f.id;
            _save.MarkDirty();
            GameEvents.RaiseShopChanged();
            return true;
        }

        /// <summary>Cycles through owned baits; dir = +1 or -1.</summary>
        public void Cycle(int dir)
        {
            var owned = _db.baits.FindAll(Owns);
            if (owned.Count <= 1) return;
            int i = owned.IndexOf(Selected);
            i = ((i + dir) % owned.Count + owned.Count) % owned.Count;
            Select(owned[i]);
        }

        /// <summary>Best owned food's luck, for collection chance display.</summary>
        public float SelectedLuck => Selected != null ? Selected.luck : 1f;
    }
}
