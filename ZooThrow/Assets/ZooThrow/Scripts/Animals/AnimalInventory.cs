using System;
using System.Collections.Generic;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Economy;
using ZooThrow.SaveSystem;

namespace ZooThrow.Animals
{
    public class AnimalInventory
    {
        readonly GameDatabase _db;
        readonly SaveData _s;
        readonly SaveManager _save;
        readonly EconomyManager _eco;

        public AnimalInventory(GameDatabase db, SaveManager save, EconomyManager eco)
        {
            _db = db; _save = save; _s = save.Data; _eco = eco;
        }

        public IReadOnlyList<OwnedAnimal> All => _s.animals;
        public int Count => _s.animals.Count;
        public int Capacity => _db.balance.inventoryCapacity;
        public bool IsFull => _s.animals.Count >= Capacity;

        public OwnedAnimal Get(int uid)
        {
            if (uid == 0) return null;
            foreach (var a in _s.animals) if (a.uid == uid) return a;
            return null;
        }

        public AnimalData DataOf(OwnedAnimal a) => a != null ? _db.Animal(a.animalId) : null;
        public double IncomeOf(OwnedAnimal a) => a == null ? 0 : AnimalRoller.Income(_db, DataOf(a), a.mutation);
        public double SellPrice(OwnedAnimal a) => Math.Max(1, Math.Round(IncomeOf(a) * _db.balance.sellValueSeconds));
        public bool IsDiscovered(string animalId) => _s.discoveredAnimals.Contains(animalId);
        public int DiscoveredCount => _s.discoveredAnimals.Count;

        /// <summary>Adds a caught animal. Returns null when the inventory is full (the animal is sold instead).</summary>
        public OwnedAnimal Add(AnimalData data, Mutation mutation, out bool firstTime, out double autoSoldFor)
        {
            firstTime = !IsDiscovered(data.id);
            autoSoldFor = 0;
            if (firstTime) _s.discoveredAnimals.Add(data.id);
            var owned = new OwnedAnimal { uid = _s.nextAnimalUid++, animalId = data.id, mutation = mutation, obtainedUtcTicks = DateTime.UtcNow.Ticks };
            _save.MarkDirty();
            if (IsFull)
            {
                autoSoldFor = SellPrice(owned);
                _eco.Add(autoSoldFor);
                GameEvents.RaiseAnimalObtained(owned, firstTime);
                return null;
            }
            _s.animals.Add(owned);
            GameEvents.RaiseAnimalObtained(owned, firstTime);
            GameEvents.RaiseInventoryChanged();
            return owned;
        }

        /// <summary>Removes the animal (and from the pen) and pays its sell price.</summary>
        public double Sell(OwnedAnimal a, AnimalPen pen)
        {
            if (a == null || !_s.animals.Contains(a)) return 0;
            double price = SellPrice(a);
            pen.RemoveIfPlaced(a.uid, false);
            _s.animals.Remove(a);
            _eco.Add(price);
            _save.MarkDirty();
            GameEvents.RaiseInventoryChanged();
            GameEvents.RaisePenChanged();
            return price;
        }

        public double SellAllNotPlaced(AnimalPen pen, out int count)
        {
            double total = 0;
            count = 0;
            for (int i = _s.animals.Count - 1; i >= 0; i--)
            {
                var a = _s.animals[i];
                if (pen.IsPlaced(a.uid)) continue;
                total += SellPrice(a);
                _s.animals.RemoveAt(i);
                count++;
            }
            if (count > 0)
            {
                _eco.Add(total);
                _save.MarkDirty();
                GameEvents.RaiseInventoryChanged();
            }
            return total;
        }
    }
}
