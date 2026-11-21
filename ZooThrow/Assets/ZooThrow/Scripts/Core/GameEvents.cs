using System;
using UnityEngine;
using ZooThrow.Data;
using ZooThrow.SaveSystem;

namespace ZooThrow.Core
{
    /// <summary>Game-wide notifications. Reset on bootstrap so a disabled domain reload cannot leak handlers.</summary>
    public static class GameEvents
    {
        public static event Action InventoryChanged;
        public static event Action PenChanged;
        public static event Action ShopChanged;
        public static event Action PowerChanged;
        public static event Action<int> PowerLevelUp;
        public static event Action<BiomeData> BiomeUnlocked;
        public static event Action<OwnedAnimal, bool> AnimalObtained;
        public static event Action SettingsChanged;
        public static event Action<string, Color> Toast;
        public static event Action<double> MoneySpent;

        public static void Reset()
        {
            InventoryChanged = null; PenChanged = null; ShopChanged = null; PowerChanged = null; PowerLevelUp = null;
            BiomeUnlocked = null; AnimalObtained = null; SettingsChanged = null; Toast = null; MoneySpent = null;
        }

        public static void RaiseInventoryChanged() => InventoryChanged?.Invoke();
        public static void RaisePenChanged() => PenChanged?.Invoke();
        public static void RaiseShopChanged() => ShopChanged?.Invoke();
        public static void RaisePowerChanged() => PowerChanged?.Invoke();
        public static void RaisePowerLevelUp(int level) => PowerLevelUp?.Invoke(level);
        public static void RaiseBiomeUnlocked(BiomeData b) => BiomeUnlocked?.Invoke(b);
        public static void RaiseAnimalObtained(OwnedAnimal a, bool firstTime) => AnimalObtained?.Invoke(a, firstTime);
        public static void RaiseSettingsChanged() => SettingsChanged?.Invoke();
        public static void RaiseToast(string text, Color color) => Toast?.Invoke(text, color);
        public static void RaiseMoneySpent(double amount) => MoneySpent?.Invoke(amount);
    }
}
