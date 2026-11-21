using System;
using System.Collections.Generic;
using ZooThrow.Data;

namespace ZooThrow.SaveSystem
{
    [Serializable]
    public class OwnedAnimal
    {
        public int uid;
        public string animalId;
        public Mutation mutation;
        public long obtainedUtcTicks;
    }

    [Serializable]
    public class UpgradeLevel
    {
        public string id;
        public int level;
    }

    [Serializable]
    public class SettingsData
    {
        public float masterVolume = 0.8f;
        public float musicVolume = 0.45f;
        public float mouseSensitivity = 1f;
        public bool invertY;
        public int quality = 2; // 0 low, 1 medium, 2 high
        public bool showFps;
        public bool autoPlaceAnimals = true;
        public bool cameraShake = true;
    }

    /// <summary>The whole persistent player state. JsonUtility-friendly: no dictionaries, no properties.</summary>
    [Serializable]
    public class SaveData
    {
        public const int CurrentVersion = 1;

        public int version = CurrentVersion;
        public double money;
        public double totalEarned;
        public int powerLevel = 1;
        public double xp;
        public List<string> ownedFoods = new List<string>();
        public string selectedFood;
        public List<string> ownedTrainers = new List<string>();
        public List<UpgradeLevel> upgrades = new List<UpgradeLevel>();
        public List<OwnedAnimal> animals = new List<OwnedAnimal>();
        public int nextAnimalUid = 1;
        /// <summary>Animal uid per pen slot, 0 = empty.</summary>
        public List<int> penSlots = new List<int>();
        public List<string> unlockedBiomes = new List<string>();
        public List<string> discoveredAnimals = new List<string>();
        public float bestDistance;
        public int totalThrows;
        public int perfectThrows;
        public int tutorialStep;
        public SettingsData settings = new SettingsData();
        public long lastSavedUtcTicks;

        public static SaveData CreateNew(GameDatabase db)
        {
            var b = db.balance;
            var s = new SaveData
            {
                money = b.startingMoney,
                powerLevel = Math.Max(1, b.startingPowerLevel),
                selectedFood = b.startingFoodId,
                lastSavedUtcTicks = DateTime.UtcNow.Ticks,
            };
            s.ownedFoods.Add(b.startingFoodId);
            s.ownedTrainers.Add(b.startingTrainerId);
            if (db.biomes.Count > 0) s.unlockedBiomes.Add(db.biomes[0].id);
            for (int i = 0; i < b.maxPenSlots; i++) s.penSlots.Add(0);
            return s;
        }
    }
}
