using System;
using System.Collections.Generic;
using UnityEngine;
using ZooThrow.Data;

namespace ZooThrow.Animals
{
    /// <summary>Pure random selection of animals and mutations. Takes an explicit System.Random so it is testable.</summary>
    public static class AnimalRoller
    {
        static readonly List<AnimalData> s_Pool = new List<AnimalData>(16);
        static readonly double[] s_Weights = new double[7];

        public static double RarityWeight(GameDatabase db, Rarity r, float luck)
        {
            var rd = db.GetRarity(r);
            if (rd == null) return 0;
            luck = Mathf.Max(0.01f, luck);
            return rd.baseWeight * Math.Pow(luck, rd.Tier * db.balance.luckTierScale);
        }

        /// <summary>Fills s_Weights with the weight of each rarity present in the biome; returns their sum.</summary>
        static double FillWeights(GameDatabase db, BiomeData biome, float luck)
        {
            Array.Clear(s_Weights, 0, s_Weights.Length);
            for (int i = 0; i < db.animals.Count; i++)
            {
                var a = db.animals[i];
                if (a == null || a.biomeId != biome.id) continue;
                s_Weights[(int)a.rarity] = RarityWeight(db, a.rarity, luck);
            }
            double sum = 0;
            for (int t = 0; t < 7; t++) sum += s_Weights[t];
            return sum;
        }

        public static AnimalData Roll(GameDatabase db, BiomeData biome, float luck, System.Random rng)
        {
            if (biome == null) return null;
            double sum = FillWeights(db, biome, luck);
            if (sum <= 0) return null;
            double pick = rng.NextDouble() * sum;
            int tier = 0;
            for (int t = 0; t < 7; t++)
            {
                if (s_Weights[t] <= 0) continue;
                tier = t;
                pick -= s_Weights[t];
                if (pick < 0) break;
            }

            s_Pool.Clear();
            float poolWeight = 0;
            for (int i = 0; i < db.animals.Count; i++)
            {
                var a = db.animals[i];
                if (a == null || a.biomeId != biome.id || (int)a.rarity != tier) continue;
                s_Pool.Add(a);
                poolWeight += Mathf.Max(0.0001f, a.spawnWeight);
            }
            if (s_Pool.Count == 0) return null;
            double p = rng.NextDouble() * poolWeight;
            for (int i = 0; i < s_Pool.Count; i++)
            {
                p -= Mathf.Max(0.0001f, s_Pool[i].spawnWeight);
                if (p < 0) return s_Pool[i];
            }
            return s_Pool[s_Pool.Count - 1];
        }

        /// <summary>Exact probability of getting this animal when food lands in its biome with the given luck.</summary>
        public static double Chance(GameDatabase db, AnimalData animal, float luck)
        {
            var biome = db.Biome(animal.biomeId);
            if (biome == null) return 0;
            double sum = FillWeights(db, biome, luck);
            if (sum <= 0) return 0;
            double rarityShare = s_Weights[(int)animal.rarity] / sum;
            float poolWeight = 0;
            foreach (var a in db.animals)
                if (a != null && a.biomeId == biome.id && a.rarity == animal.rarity) poolWeight += Mathf.Max(0.0001f, a.spawnWeight);
            return poolWeight <= 0 ? 0 : rarityShare * Mathf.Max(0.0001f, animal.spawnWeight) / poolWeight;
        }

        public static Mutation RollMutation(BalanceSettings b, float luck, System.Random rng)
        {
            if (!b.mutationsEnabled) return Mutation.None;
            double boost = Math.Sqrt(Math.Max(1.0, luck));
            double r = rng.NextDouble();
            double rainbow = b.rainbowChance * boost, golden = b.goldenChance * boost, giant = b.giantChance * boost;
            if (r < rainbow) return Mutation.Rainbow;
            if (r < rainbow + golden) return Mutation.Golden;
            if (r < rainbow + golden + giant) return Mutation.Giant;
            return Mutation.None;
        }

        public static double MutationMultiplier(BalanceSettings b, Mutation m)
        {
            switch (m)
            {
                case Mutation.Golden: return b.goldenIncomeMultiplier;
                case Mutation.Rainbow: return b.rainbowIncomeMultiplier;
                case Mutation.Giant: return b.giantIncomeMultiplier;
                default: return 1;
            }
        }

        public static double Income(GameDatabase db, AnimalData a, Mutation m)
        {
            if (a == null) return 0;
            var rd = db.GetRarity(a.rarity);
            return a.baseIncome * (rd != null ? rd.incomeMultiplier : 1) * MutationMultiplier(db.balance, m);
        }

        public static string MutationName(Mutation m)
        {
            switch (m)
            {
                case Mutation.Golden: return "Золотой";
                case Mutation.Rainbow: return "Радужный";
                case Mutation.Giant: return "Гигантский";
                default: return "";
            }
        }
    }
}
