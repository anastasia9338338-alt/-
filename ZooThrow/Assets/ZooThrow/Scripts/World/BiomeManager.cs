using System.Collections.Generic;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.SaveSystem;

namespace ZooThrow.World
{
    public class BiomeManager
    {
        readonly GameDatabase _db;
        readonly SaveData _s;
        readonly SaveManager _save;
        readonly List<BiomeData> _newly = new List<BiomeData>();

        public BiomeManager(GameDatabase db, SaveManager save) { _db = db; _save = save; _s = save.Data; }

        public bool IsUnlocked(string id) => _s.unlockedBiomes.Contains(id);
        public bool IsUnlocked(BiomeData b) => b != null && IsUnlocked(b.id);

        public BiomeData Furthest
        {
            get
            {
                BiomeData f = _db.biomes.Count > 0 ? _db.biomes[0] : null;
                foreach (var b in _db.biomes) if (IsUnlocked(b)) f = b;
                return f;
            }
        }

        public BiomeData Next
        {
            get
            {
                foreach (var b in _db.biomes) if (!IsUnlocked(b)) return b;
                return null;
            }
        }

        public int UnlockedCount => _s.unlockedBiomes.Count;

        /// <summary>Records a landing. Every biome that starts at or before the distance becomes unlocked.</summary>
        public List<BiomeData> RegisterLanding(float distance)
        {
            _newly.Clear();
            foreach (var b in _db.biomes)
            {
                if (b.startDistance <= distance && !IsUnlocked(b))
                {
                    _s.unlockedBiomes.Add(b.id);
                    _newly.Add(b);
                }
            }
            bool record = distance > _s.bestDistance;
            if (record) _s.bestDistance = distance;
            if (_newly.Count > 0 || record) _save.MarkDirty();
            foreach (var b in _newly) GameEvents.RaiseBiomeUnlocked(b);
            if (_newly.Count > 0) GameEvents.RaiseShopChanged();
            return _newly;
        }
    }
}
