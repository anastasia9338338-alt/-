using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Economy;
using ZooThrow.SaveSystem;

namespace ZooThrow.Shops
{
    public class TrainerShop
    {
        readonly GameDatabase _db;
        readonly SaveData _s;
        readonly SaveManager _save;
        readonly EconomyManager _eco;

        public TrainerShop(GameDatabase db, SaveManager save, EconomyManager eco)
        {
            _db = db; _save = save; _s = save.Data; _eco = eco;
        }

        public bool Owns(TrainerData t) => t != null && _s.ownedTrainers.Contains(t.id);
        public bool IsUnlocked(TrainerData t) => t != null && _s.powerLevel >= t.requiredPowerLevel;

        /// <summary>The owned trainer with the highest xp per rep — training always uses the best one.</summary>
        public TrainerData Best
        {
            get
            {
                TrainerData best = null;
                foreach (var t in _db.trainers)
                    if (Owns(t) && (best == null || t.xpPerRep > best.xpPerRep)) best = t;
                return best ?? _db.Trainer(_db.balance.startingTrainerId);
            }
        }

        public PurchaseResult TryBuy(TrainerData t)
        {
            if (t == null) return PurchaseResult.Unknown;
            if (Owns(t)) return PurchaseResult.AlreadyOwned;
            if (!IsUnlocked(t)) return PurchaseResult.Locked;
            if (!_eco.TrySpend(t.price)) return PurchaseResult.NotEnoughMoney;
            _s.ownedTrainers.Add(t.id);
            _save.MarkDirty();
            GameEvents.RaiseShopChanged();
            return PurchaseResult.Ok;
        }
    }
}
