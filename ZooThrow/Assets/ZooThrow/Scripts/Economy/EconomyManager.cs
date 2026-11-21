using System;
using ZooThrow.Core;
using ZooThrow.SaveSystem;

namespace ZooThrow.Economy
{
    public class EconomyManager
    {
        readonly SaveData _s;
        readonly SaveManager _save;

        public EconomyManager(SaveManager save) { _save = save; _s = save.Data; }

        public double Money => _s.money;

        public void Add(double amount)
        {
            if (double.IsNaN(amount) || double.IsInfinity(amount) || amount <= 0) return;
            _s.money += amount;
            _s.totalEarned += amount;
            _save.MarkDirty();
        }

        public bool CanAfford(double cost) => cost >= 0 && _s.money + 1e-6 >= cost;

        public bool TrySpend(double cost)
        {
            if (double.IsNaN(cost) || cost < 0 || !CanAfford(cost)) return false;
            _s.money = Math.Max(0, _s.money - cost);
            _save.MarkDirty();
            GameEvents.RaiseMoneySpent(cost);
            return true;
        }
    }
}
