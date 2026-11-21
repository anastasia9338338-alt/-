using UnityEngine;

namespace ZooThrow.Data
{
    [CreateAssetMenu(menuName = "ZooThrow/Food", fileName = "Food")]
    public class FoodData : ScriptableObject
    {
        public string id = "carrot";
        public string displayName = "Морковь";
        [TextArea] public string description;
        public int tier;
        public double price;
        [Tooltip("Прибавка к дальности броска, метры.")]
        public float distanceBonus;
        [Tooltip("Удача: >1 сдвигает выпадение к редким животным.")]
        public float luck = 1f;
        [Tooltip("Еда продаётся, только когда открыт этот биом. Пусто — без условия.")]
        public string requiredBiomeId;
        [Tooltip("Минимальный уровень силы для покупки.")]
        public int requiredPowerLevel;
        public FoodShape shape;
        public Color primary = new Color(1f, 0.55f, 0.1f);
        public Color secondary = new Color(0.3f, 0.75f, 0.2f);
    }
}
