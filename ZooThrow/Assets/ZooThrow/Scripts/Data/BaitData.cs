using UnityEngine;

namespace ZooThrow.Data
{
    /// <summary>Bait sold in the bait shop. Better bait shifts catches towards rare creatures.</summary>
    [CreateAssetMenu(menuName = "ZooThrow/Bait", fileName = "Bait")]
    public class BaitData : ScriptableObject
    {
        public string id = "worm";
        public string displayName = "Червяк";
        [TextArea] public string description;
        public int tier;
        public double price;
        [Tooltip("Удача: >1 сдвигает улов к редким существам.")]
        public float luck = 1f;
        [Tooltip("Небольшая прибавка к дальности заброса, метры.")]
        public float distanceBonus;
        [Tooltip("Продаётся, только когда открыта эта локация. Пусто — без условия.")]
        public string requiredBiomeId;
        [Tooltip("Минимальный уровень силы для покупки.")]
        public int requiredPowerLevel;
        public BaitShape shape;
        public Color primary = new Color(0.95f, 0.5f, 0.55f);
        public Color secondary = new Color(0.8f, 0.35f, 0.4f);
    }
}
