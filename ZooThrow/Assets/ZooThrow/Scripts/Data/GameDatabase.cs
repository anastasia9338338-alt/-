using System.Collections.Generic;
using UnityEngine;

namespace ZooThrow.Data
{
    /// <summary>Root content asset. Loaded from Resources/ZooThrowDatabase or built from DefaultContent.</summary>
    [CreateAssetMenu(menuName = "ZooThrow/Game Database", fileName = "ZooThrowDatabase")]
    public class GameDatabase : ScriptableObject
    {
        public const string ResourcePath = "ZooThrowDatabase";

        public BalanceSettings balance;
        public List<RarityData> rarities = new List<RarityData>();
        public List<BiomeData> biomes = new List<BiomeData>();
        public List<AnimalData> animals = new List<AnimalData>();
        public List<FoodData> foods = new List<FoodData>();
        public List<TrainerData> trainers = new List<TrainerData>();
        public List<UpgradeData> upgrades = new List<UpgradeData>();

        Dictionary<string, AnimalData> _animals;
        Dictionary<string, FoodData> _foods;
        Dictionary<string, TrainerData> _trainers;
        Dictionary<string, UpgradeData> _upgrades;
        Dictionary<string, BiomeData> _biomes;
        RarityData[] _rarityByTier;

        public void BuildLookups()
        {
            _animals = new Dictionary<string, AnimalData>();
            foreach (var a in animals) if (a != null && !string.IsNullOrEmpty(a.id)) _animals[a.id] = a;
            _foods = new Dictionary<string, FoodData>();
            foreach (var f in foods) if (f != null && !string.IsNullOrEmpty(f.id)) _foods[f.id] = f;
            _trainers = new Dictionary<string, TrainerData>();
            foreach (var t in trainers) if (t != null && !string.IsNullOrEmpty(t.id)) _trainers[t.id] = t;
            _upgrades = new Dictionary<string, UpgradeData>();
            foreach (var u in upgrades) if (u != null && !string.IsNullOrEmpty(u.id)) _upgrades[u.id] = u;
            _biomes = new Dictionary<string, BiomeData>();
            foreach (var b in biomes) if (b != null && !string.IsNullOrEmpty(b.id)) _biomes[b.id] = b;
            biomes.RemoveAll(b => b == null);
            biomes.Sort((x, y) => x.startDistance.CompareTo(y.startDistance));
            foods.RemoveAll(f => f == null);
            foods.Sort((x, y) => x.tier.CompareTo(y.tier));
            trainers.RemoveAll(t => t == null);
            trainers.Sort((x, y) => x.price.CompareTo(y.price));
            _rarityByTier = new RarityData[7];
            foreach (var r in rarities) if (r != null) _rarityByTier[(int)r.rarity] = r;
        }

        public AnimalData Animal(string id) => id != null && _animals.TryGetValue(id, out var v) ? v : null;
        public FoodData Food(string id) => id != null && _foods.TryGetValue(id, out var v) ? v : null;
        public TrainerData Trainer(string id) => id != null && _trainers.TryGetValue(id, out var v) ? v : null;
        public UpgradeData Upgrade(string id) => id != null && _upgrades.TryGetValue(id, out var v) ? v : null;
        public BiomeData Biome(string id) => id != null && _biomes.TryGetValue(id, out var v) ? v : null;
        public RarityData GetRarity(Rarity r) => _rarityByTier[(int)r];

        public int BiomeIndex(BiomeData b) => biomes.IndexOf(b);

        /// <summary>Biome whose range contains the distance; past the last biome returns the last one.</summary>
        public BiomeData BiomeAtDistance(float distance)
        {
            if (biomes.Count == 0) return null;
            for (int i = 0; i < biomes.Count; i++)
                if (biomes[i].Contains(distance)) return biomes[i];
            return distance < biomes[0].startDistance ? biomes[0] : biomes[biomes.Count - 1];
        }

        /// <summary>Returns a list of human readable problems; empty means the content is consistent.</summary>
        public List<string> Validate()
        {
            var problems = new List<string>();
            if (balance == null) problems.Add("Нет BalanceSettings");
            for (int t = 0; t < 7; t++)
                if (_rarityByTier == null || _rarityByTier[t] == null) problems.Add("Нет данных редкости " + (Rarity)t);
            var ids = new HashSet<string>();
            foreach (var a in animals)
            {
                if (a == null) { problems.Add("Пустая ссылка на животное"); continue; }
                if (!ids.Add(a.id)) problems.Add("Повтор ID животного: " + a.id);
                if (Biome(a.biomeId) == null) problems.Add("Животное " + a.id + " ссылается на неизвестный биом " + a.biomeId);
                if (a.spawnWeight <= 0) problems.Add("Животное " + a.id + " с нулевым весом");
            }
            foreach (var b in biomes)
            {
                if (b.endDistance <= b.startDistance) problems.Add("Биом " + b.id + " имеет пустой диапазон");
                if (!animals.Exists(a => a != null && a.biomeId == b.id)) problems.Add("В биоме " + b.id + " нет животных");
            }
            if (balance != null && Food(balance.startingFoodId) == null) problems.Add("Стартовая еда не найдена: " + balance.startingFoodId);
            if (balance != null && Trainer(balance.startingTrainerId) == null) problems.Add("Стартовый тренажёр не найден: " + balance.startingTrainerId);
            return problems;
        }
    }
}
