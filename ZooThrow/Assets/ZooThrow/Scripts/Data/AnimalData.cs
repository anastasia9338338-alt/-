using UnityEngine;

namespace ZooThrow.Data
{
    [CreateAssetMenu(menuName = "ZooThrow/Animal", fileName = "Animal")]
    public class AnimalData : ScriptableObject
    {
        [Tooltip("Уникальный ID. Хранится в сохранениях — не меняй у существующих животных.")]
        public string id = "rabbit";
        public string displayName = "Кролик";
        public Rarity rarity;
        public string biomeId = "forest";
        [Tooltip("Вес внутри своей редкости и биома.")]
        public float spawnWeight = 1f;
        [Tooltip("Базовый доход в секунду до множителя редкости и мутации.")]
        public double baseIncome = 1;
        [Tooltip("Масштаб модели.")]
        public float size = 1f;
        public MovementStyle movement = MovementStyle.Walk;
        [Tooltip("Особенность — показывается в коллекции.")]
        public string trait;
        public AnimalModelSpec model = new AnimalModelSpec();
    }
}
