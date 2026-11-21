using UnityEngine;

namespace ZooThrow.Data
{
    [CreateAssetMenu(menuName = "ZooThrow/Upgrade", fileName = "Upgrade")]
    public class UpgradeData : ScriptableObject
    {
        public string id = "pen_capacity";
        public string displayName = "Больше аквариум";
        [TextArea] public string description;
        public UpgradeEffect effect;
        public double baseCost = 100;
        public double costGrowth = 2;
        public int maxLevel = 8;
        [Tooltip("Сила эффекта за уровень (слоты, доля, часы — зависит от эффекта).")]
        public float valuePerLevel = 1f;
        public Color color = new Color(0.3f, 0.6f, 1f);

        public double CostForLevel(int currentLevel) => System.Math.Round(baseCost * System.Math.Pow(costGrowth, currentLevel));
    }
}
