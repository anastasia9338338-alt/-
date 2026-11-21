using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.SaveSystem;

namespace ZooThrow.Economy
{
    public enum PurchaseResult { Ok, NotEnoughMoney, MaxLevel, Locked, Unknown, AlreadyOwned }

    public class UpgradeManager
    {
        readonly GameDatabase _db;
        readonly SaveData _s;
        readonly SaveManager _save;
        readonly EconomyManager _eco;

        public UpgradeManager(GameDatabase db, SaveManager save, EconomyManager eco)
        {
            _db = db; _save = save; _s = save.Data; _eco = eco;
        }

        public int Level(string id)
        {
            foreach (var u in _s.upgrades) if (u.id == id) return u.level;
            return 0;
        }

        void SetLevel(string id, int level)
        {
            foreach (var u in _s.upgrades) if (u.id == id) { u.level = level; return; }
            _s.upgrades.Add(new UpgradeLevel { id = id, level = level });
        }

        public bool IsMaxed(UpgradeData u) => Level(u.id) >= u.maxLevel;
        public double Cost(UpgradeData u) => u.CostForLevel(Level(u.id));

        public PurchaseResult TryBuy(UpgradeData u)
        {
            if (u == null) return PurchaseResult.Unknown;
            if (IsMaxed(u)) return PurchaseResult.MaxLevel;
            if (!_eco.TrySpend(Cost(u))) return PurchaseResult.NotEnoughMoney;
            SetLevel(u.id, Level(u.id) + 1);
            _save.MarkDirty();
            GameEvents.RaiseShopChanged();
            if (u.effect == UpgradeEffect.PenCapacity) GameEvents.RaisePenChanged();
            return PurchaseResult.Ok;
        }

        float Sum(UpgradeEffect effect)
        {
            float v = 0;
            foreach (var u in _db.upgrades) if (u.effect == effect) v += Level(u.id) * u.valuePerLevel;
            return v;
        }

        public int PenCapacity => System.Math.Min(_db.balance.maxPenSlots, _db.balance.startingPenCapacity + UnityEngine.Mathf.RoundToInt(Sum(UpgradeEffect.PenCapacity)));
        public float ArmsMultiplier => 1f + Sum(UpgradeEffect.StrongArms);
        public float LuckMultiplier => 1f + Sum(UpgradeEffect.Luck);
        public float OfflineHours => _db.balance.baseOfflineHours + Sum(UpgradeEffect.OfflineHours);
        public float XpMultiplier => 1f + Sum(UpgradeEffect.TrainingBoost);

        public string EffectText(UpgradeData u, int level)
        {
            float v = level * u.valuePerLevel;
            switch (u.effect)
            {
                case UpgradeEffect.PenCapacity: return (_db.balance.startingPenCapacity + UnityEngine.Mathf.RoundToInt(v)) + " мест";
                case UpgradeEffect.StrongArms: return "+" + UnityEngine.Mathf.RoundToInt(v * 100f) + "% силы";
                case UpgradeEffect.Luck: return "×" + (1f + v).ToString("0.00");
                case UpgradeEffect.OfflineHours: return (_db.balance.baseOfflineHours + v).ToString("0") + " ч";
                case UpgradeEffect.TrainingBoost: return "+" + UnityEngine.Mathf.RoundToInt(v * 100f) + "% опыта";
                default: return v.ToString("0.##");
            }
        }
    }
}
