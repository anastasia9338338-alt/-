using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Economy;
using ZooThrow.SaveSystem;
using ZooThrow.World;

namespace ZooThrow.Shops
{
    /// <summary>Rod shop: rods are bought once and kept; the selected rod is the one in the player's hands.</summary>
    public class RodShop
    {
        readonly GameDatabase _db;
        readonly SaveData _s;
        readonly SaveManager _save;
        readonly EconomyManager _eco;
        readonly BiomeManager _biomes;

        public RodShop(GameDatabase db, SaveManager save, EconomyManager eco, BiomeManager biomes)
        {
            _db = db; _save = save; _s = save.Data; _eco = eco; _biomes = biomes;
        }

        public RodData Selected => _db.Rod(_s.selectedRod) ?? _db.Rod(_db.balance.startingRodId);
        public bool Owns(RodData r) => r != null && _s.ownedRods.Contains(r.id);

        public bool IsUnlocked(RodData r) =>
            r != null && (string.IsNullOrEmpty(r.requiredBiomeId) || _biomes.IsUnlocked(r.requiredBiomeId));

        public string LockReason(RodData r)
        {
            if (r == null || string.IsNullOrEmpty(r.requiredBiomeId) || _biomes.IsUnlocked(r.requiredBiomeId)) return "";
            var b = _db.Biome(r.requiredBiomeId);
            return "Открой «" + (b != null ? b.displayName : r.requiredBiomeId) + "»";
        }

        public PurchaseResult TryBuy(RodData r)
        {
            if (r == null) return PurchaseResult.Unknown;
            if (Owns(r)) return PurchaseResult.AlreadyOwned;
            if (!IsUnlocked(r)) return PurchaseResult.Locked;
            if (!_eco.TrySpend(r.price)) return PurchaseResult.NotEnoughMoney;
            _s.ownedRods.Add(r.id);
            _s.selectedRod = r.id; // a new rod is always the better one, so equip it
            _save.MarkDirty();
            GameEvents.RaiseShopChanged();
            return PurchaseResult.Ok;
        }

        public bool Select(RodData r)
        {
            if (!Owns(r)) return false;
            _s.selectedRod = r.id;
            _save.MarkDirty();
            GameEvents.RaiseShopChanged();
            return true;
        }
    }
}
