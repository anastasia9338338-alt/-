using System;
using System.Collections.Generic;
using ZooThrow.Data;

namespace ZooThrow.SaveSystem
{
    /// <summary>Repairs loaded data so the rest of the game can trust it. Returns the list of repairs made.</summary>
    public static class SaveValidator
    {
        static double Finite(double v, double fallback) => double.IsNaN(v) || double.IsInfinity(v) ? fallback : v;
        static float Finite(float v, float fallback) => float.IsNaN(v) || float.IsInfinity(v) ? fallback : v;

        public static List<string> Sanitize(SaveData s, GameDatabase db)
        {
            var fixes = new List<string>();
            var b = db.balance;
            if (s.settings == null) { s.settings = new SettingsData(); fixes.Add("settings"); }
            if (s.ownedFoods == null) s.ownedFoods = new List<string>();
            if (s.ownedTrainers == null) s.ownedTrainers = new List<string>();
            if (s.upgrades == null) s.upgrades = new List<UpgradeLevel>();
            if (s.animals == null) s.animals = new List<OwnedAnimal>();
            if (s.penSlots == null) s.penSlots = new List<int>();
            if (s.unlockedBiomes == null) s.unlockedBiomes = new List<string>();
            if (s.discoveredAnimals == null) s.discoveredAnimals = new List<string>();

            double money = Finite(s.money, 0);
            if (money < 0) money = 0;
            if (money != s.money) { s.money = money; fixes.Add("money"); }
            s.totalEarned = Math.Max(0, Finite(s.totalEarned, 0));
            int level = Math.Max(1, Math.Min(b.maxPowerLevel, s.powerLevel));
            if (level != s.powerLevel) { s.powerLevel = level; fixes.Add("powerLevel"); }
            s.xp = Math.Max(0, Finite(s.xp, 0));
            s.bestDistance = Math.Max(0, Math.Min(b.maxThrowDistance, Finite(s.bestDistance, 0)));
            s.totalThrows = Math.Max(0, s.totalThrows);
            s.perfectThrows = Math.Max(0, Math.Min(s.totalThrows, s.perfectThrows));

            int removed = s.ownedFoods.RemoveAll(id => db.Food(id) == null);
            Dedupe(s.ownedFoods);
            if (!s.ownedFoods.Contains(b.startingFoodId)) { s.ownedFoods.Insert(0, b.startingFoodId); removed++; }
            if (removed > 0) fixes.Add("foods");
            if (!s.ownedFoods.Contains(s.selectedFood)) { s.selectedFood = b.startingFoodId; fixes.Add("selectedFood"); }

            removed = s.ownedTrainers.RemoveAll(id => db.Trainer(id) == null);
            Dedupe(s.ownedTrainers);
            if (!s.ownedTrainers.Contains(b.startingTrainerId)) { s.ownedTrainers.Insert(0, b.startingTrainerId); removed++; }
            if (removed > 0) fixes.Add("trainers");

            var seenUpgrades = new HashSet<string>();
            removed = s.upgrades.RemoveAll(u => u == null || db.Upgrade(u.id) == null || !seenUpgrades.Add(u.id));
            foreach (var u in s.upgrades)
            {
                int max = db.Upgrade(u.id).maxLevel;
                int clamped = Math.Max(0, Math.Min(max, u.level));
                if (clamped != u.level) { u.level = clamped; removed++; }
            }
            if (removed > 0) fixes.Add("upgrades");

            var uids = new HashSet<int>();
            int maxUid = 0;
            removed = s.animals.RemoveAll(a => a == null || db.Animal(a.animalId) == null || a.uid <= 0 || !uids.Add(a.uid));
            foreach (var a in s.animals)
            {
                if (!Enum.IsDefined(typeof(Mutation), a.mutation) || (!b.mutationsEnabled && a.mutation != Mutation.None)) { a.mutation = Mutation.None; removed++; }
                maxUid = Math.Max(maxUid, a.uid);
            }
            if (s.animals.Count > b.inventoryCapacity) { s.animals.RemoveRange(b.inventoryCapacity, s.animals.Count - b.inventoryCapacity); removed++; }
            if (removed > 0) fixes.Add("animals");
            if (s.nextAnimalUid <= maxUid) { s.nextAnimalUid = maxUid + 1; fixes.Add("nextAnimalUid"); }

            bool penFixed = s.penSlots.Count != b.maxPenSlots;
            while (s.penSlots.Count < b.maxPenSlots) s.penSlots.Add(0);
            if (s.penSlots.Count > b.maxPenSlots) s.penSlots.RemoveRange(b.maxPenSlots, s.penSlots.Count - b.maxPenSlots);
            var placed = new HashSet<int>();
            var alive = new HashSet<int>();
            foreach (var a in s.animals) alive.Add(a.uid);
            for (int i = 0; i < s.penSlots.Count; i++)
            {
                int uid = s.penSlots[i];
                if (uid != 0 && (!alive.Contains(uid) || !placed.Add(uid))) { s.penSlots[i] = 0; penFixed = true; }
            }
            if (penFixed) fixes.Add("pen");

            removed = s.unlockedBiomes.RemoveAll(id => db.Biome(id) == null);
            Dedupe(s.unlockedBiomes);
            if (db.biomes.Count > 0 && !s.unlockedBiomes.Contains(db.biomes[0].id)) { s.unlockedBiomes.Insert(0, db.biomes[0].id); removed++; }
            // Biomes are unlocked by distance, so the record implies every biome before it.
            foreach (var biome in db.biomes)
                if (biome.startDistance <= s.bestDistance && !s.unlockedBiomes.Contains(biome.id)) { s.unlockedBiomes.Add(biome.id); removed++; }
            if (removed > 0) fixes.Add("biomes");

            s.discoveredAnimals.RemoveAll(id => db.Animal(id) == null);
            foreach (var a in s.animals) if (!s.discoveredAnimals.Contains(a.animalId)) s.discoveredAnimals.Add(a.animalId);
            Dedupe(s.discoveredAnimals);

            var st = s.settings;
            st.masterVolume = Clamp01(Finite(st.masterVolume, 0.8f));
            st.musicVolume = Clamp01(Finite(st.musicVolume, 0.45f));
            st.mouseSensitivity = Math.Max(0.1f, Math.Min(3f, Finite(st.mouseSensitivity, 1f)));
            st.quality = Math.Max(0, Math.Min(2, st.quality));
            if (s.lastSavedUtcTicks < 0 || s.lastSavedUtcTicks > DateTime.MaxValue.Ticks) { s.lastSavedUtcTicks = DateTime.UtcNow.Ticks; fixes.Add("time"); }
            s.version = SaveData.CurrentVersion;
            return fixes;
        }

        static float Clamp01(float v) => v < 0 ? 0 : v > 1 ? 1 : v;

        static void Dedupe(List<string> list)
        {
            var seen = new HashSet<string>();
            list.RemoveAll(x => string.IsNullOrEmpty(x) || !seen.Add(x));
        }
    }
}
