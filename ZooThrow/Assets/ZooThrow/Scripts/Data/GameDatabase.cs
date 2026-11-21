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
        public List<BaitData> baits = new List<BaitData>();
        public List<RodData> rods = new List<RodData>();
        public List<TrainerData> trainers = new List<TrainerData>();
        public List<UpgradeData> upgrades = new List<UpgradeData>();

        Dictionary<string, AnimalData> _animals;
        Dictionary<string, BaitData> _baits;
        Dictionary<string, RodData> _rods;
        Dictionary<string, TrainerData> _trainers;
        Dictionary<string, UpgradeData> _upgrades;
        Dictionary<string, BiomeData> _biomes;
        RarityData[] _rarityByTier;

        public void BuildLookups()
        {
            _animals = new Dictionary<string, AnimalData>();
            foreach (var a in animals) if (a != null && !string.IsNullOrEmpty(a.id)) _animals[a.id] = a;
            _baits = new Dictionary<string, BaitData>();
            foreach (var f in baits) if (f != null && !string.IsNullOrEmpty(f.id)) _baits[f.id] = f;
            _rods = new Dictionary<string, RodData>();
            foreach (var r in rods) if (r != null && !string.IsNullOrEmpty(r.id)) _rods[r.id] = r;
            _trainers = new Dictionary<string, TrainerData>();
            foreach (var t in trainers) if (t != null && !string.IsNullOrEmpty(t.id)) _trainers[t.id] = t;
            _upgrades = new Dictionary<string, UpgradeData>();
            foreach (var u in upgrades) if (u != null && !string.IsNullOrEmpty(u.id)) _upgrades[u.id] = u;
            _biomes = new Dictionary<string, BiomeData>();
            foreach (var b in biomes) if (b != null && !string.IsNullOrEmpty(b.id)) _biomes[b.id] = b;
            biomes.RemoveAll(b => b == null);
            biomes.Sort((x, y) => x.startDistance.CompareTo(y.startDistance));
            baits.RemoveAll(f => f == null);
            baits.Sort((x, y) => x.tier.CompareTo(y.tier));
            rods.RemoveAll(r => r == null);
            rods.Sort((x, y) => x.tier.CompareTo(y.tier));
            trainers.RemoveAll(t => t == null);
            trainers.Sort((x, y) => x.price.CompareTo(y.price));
            _rarityByTier = new RarityData[7];
            foreach (var r in rarities) if (r != null) _rarityByTier[(int)r.rarity] = r;
        }

        public AnimalData Animal(string id) => id != null && _animals.TryGetValue(id, out var v) ? v : null;
        public BaitData Bait(string id) => id != null && _baits.TryGetValue(id, out var v) ? v : null;
        public RodData Rod(string id) => id != null && _rods.TryGetValue(id, out var v) ? v : null;
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
                if (a == null) { problems.Add("Пустая ссылка на существо"); continue; }
                if (!ids.Add(a.id)) problems.Add("Повтор ID существа: " + a.id);
                if (Biome(a.biomeId) == null) problems.Add("Существо " + a.id + " ссылается на неизвестную локацию " + a.biomeId);
                if (a.spawnWeight <= 0) problems.Add("Существо " + a.id + " с нулевым весом");
            }
            foreach (var b in biomes)
            {
                if (b.endDistance <= b.startDistance) problems.Add("Локация " + b.id + " имеет пустой диапазон");
                if (!animals.Exists(a => a != null && a.biomeId == b.id)) problems.Add("В локации " + b.id + " нет существ");
            }
            if (balance != null && Bait(balance.startingBaitId) == null) problems.Add("Стартовая наживка не найдена: " + balance.startingBaitId);
            if (balance != null && Rod(balance.startingRodId) == null) problems.Add("Стартовая удочка не найдена: " + balance.startingRodId);
            if (balance != null && Trainer(balance.startingTrainerId) == null) problems.Add("Стартовый тренажёр не найден: " + balance.startingTrainerId);
            return problems;
        }
    }
}
