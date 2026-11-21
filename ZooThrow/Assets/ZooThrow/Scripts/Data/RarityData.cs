using UnityEngine;

namespace ZooThrow.Data
{
    [CreateAssetMenu(menuName = "ZooThrow/Rarity", fileName = "Rarity")]
    public class RarityData : ScriptableObject
    {
        public Rarity rarity;
        public string displayName = "Обычное";
        public Color color = Color.white;
        [Tooltip("Базовый вес выпадения до учёта удачи еды.")]
        public double baseWeight = 1.0;
        [Tooltip("Множитель дохода животного этой редкости.")]
        public double incomeMultiplier = 1.0;
        [Tooltip("Показывать большой экран награды вместо карточки.")]
        public bool bigRewardScreen;
        [Range(0f, 3f)] public float glowIntensity;
        [Range(0, 200)] public int particleBurst = 20;

        public int Tier => (int)rarity;
    }
}
