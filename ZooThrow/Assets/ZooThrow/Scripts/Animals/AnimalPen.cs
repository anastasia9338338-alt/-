using System.Collections.Generic;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Economy;
using ZooThrow.SaveSystem;

namespace ZooThrow.Animals
{
    /// <summary>Pen slots and the passive income they produce.</summary>
    public class AnimalPen
    {
        readonly GameDatabase _db;
        readonly SaveData _s;
        readonly SaveManager _save;
        readonly UpgradeManager _upgrades;
        readonly AnimalInventory _inv;
        double _incomeCache = -1;

        public AnimalPen(GameDatabase db, SaveManager save, UpgradeManager upgrades, AnimalInventory inv)
        {
            _db = db; _save = save; _s = save.Data; _upgrades = upgrades; _inv = inv;
            GameEvents.PenChanged += Invalidate;
            GameEvents.InventoryChanged += Invalidate;
        }

        void Invalidate() => _incomeCache = -1;

        public int Capacity => _upgrades.PenCapacity;
        public int MaxSlots => _s.penSlots.Count;
        public int SlotUid(int slot) => slot >= 0 && slot < _s.penSlots.Count ? _s.penSlots[slot] : 0;
        public bool IsSlotUnlocked(int slot) => slot < Capacity;

        public int PlacedCount
        {
            get
            {
                int n = 0;
                for (int i = 0; i < Capacity && i < _s.penSlots.Count; i++) if (_s.penSlots[i] != 0) n++;
                return n;
            }
        }

        public bool HasFreeSlot => FreeSlot() >= 0;

        public bool IsPlaced(int uid)
        {
            if (uid == 0) return false;
            for (int i = 0; i < _s.penSlots.Count; i++) if (_s.penSlots[i] == uid) return true;
            return false;
        }

        int FreeSlot()
        {
            for (int i = 0; i < Capacity && i < _s.penSlots.Count; i++) if (_s.penSlots[i] == 0) return i;
            return -1;
        }

        public bool Place(OwnedAnimal a)
        {
            if (a == null || IsPlaced(a.uid) || _inv.Get(a.uid) == null) return false;
            int slot = FreeSlot();
            if (slot < 0) return false;
            _s.penSlots[slot] = a.uid;
            _save.MarkDirty();
            GameEvents.RaisePenChanged();
            return true;
        }

        public bool RemoveIfPlaced(int uid, bool notify = true)
        {
            for (int i = 0; i < _s.penSlots.Count; i++)
            {
                if (_s.penSlots[i] != uid) continue;
                _s.penSlots[i] = 0;
                _save.MarkDirty();
                if (notify) GameEvents.RaisePenChanged();
                return true;
            }
            return false;
        }

        /// <summary>Replaces the weakest placed animal if the candidate earns more. Returns true if placed.</summary>
        public bool PlaceOrReplaceWeakest(OwnedAnimal a)
        {
            if (Place(a)) return true;
            int weakest = -1;
            double weakestIncome = double.MaxValue;
            for (int i = 0; i < Capacity && i < _s.penSlots.Count; i++)
            {
                double inc = _inv.IncomeOf(_inv.Get(_s.penSlots[i]));
                if (inc < weakestIncome) { weakestIncome = inc; weakest = i; }
            }
            if (weakest < 0 || _inv.IncomeOf(a) <= weakestIncome) return false;
            _s.penSlots[weakest] = a.uid;
            _save.MarkDirty();
            GameEvents.RaisePenChanged();
            return true;
        }

        /// <summary>Fills the pen with the highest earning animals from the whole collection.</summary>
        public void ArrangeBest()
        {
            var list = new List<OwnedAnimal>(_inv.All);
            list.Sort((x, y) => _inv.IncomeOf(y).CompareTo(_inv.IncomeOf(x)));
            for (int i = 0; i < _s.penSlots.Count; i++) _s.penSlots[i] = 0;
            for (int i = 0; i < Capacity && i < list.Count && i < _s.penSlots.Count; i++) _s.penSlots[i] = list[i].uid;
            _save.MarkDirty();
            GameEvents.RaisePenChanged();
        }

        public double TotalIncome
        {
            get
            {
                if (_incomeCache >= 0) return _incomeCache;
                double sum = 0;
                for (int i = 0; i < Capacity && i < _s.penSlots.Count; i++)
                    sum += _inv.IncomeOf(_inv.Get(_s.penSlots[i]));
                _incomeCache = sum;
                return sum;
            }
        }

        public void InvalidateIncome() => _incomeCache = -1;
    }
}
