using UnityEngine;

namespace ZooThrow.Data
{
    /// <summary>Fishing rod sold in the rod shop. Rods add cast distance and a little luck.</summary>
    [CreateAssetMenu(menuName = "ZooThrow/Rod", fileName = "Rod")]
    public class RodData : ScriptableObject
    {
        public string id = "bamboo_rod";
        public string displayName = "Бамбуковая удочка";
        [TextArea] public string description;
        public int tier;
        public double price;
        [Tooltip("Прибавка к дальности заброса, метры.")]
        public float distanceBonus;
        [Tooltip("Множитель удачи удочки (1 = без бонуса).")]
        public float luck = 1f;
        [Tooltip("Продаётся, только когда открыта эта локация. Пусто — без условия.")]
        public string requiredBiomeId;
        [Tooltip("Цвет удилища.")]
        public Color primary = new Color(0.85f, 0.75f, 0.45f);
        [Tooltip("Цвет рукояти и катушки.")]
        public Color secondary = new Color(0.35f, 0.25f, 0.15f);
        [Tooltip("Цвет лески и следа заброса.")]
        public Color lineColor = Color.white;
        [Tooltip("Длина удилища в метрах.")]
        [Range(1f, 4f)] public float length = 2.2f;
        [Tooltip("Удилище светится (для редких удочек).")]
        public bool glows;

        [Header("Внешний вид")]
        [Tooltip("Цвет катушки.")]
        public Color reelColor = new Color(0.9f, 0.85f, 0.7f);
        [Tooltip("Цвет колец-ферул, наконечника и цепочки.")]
        public Color metal = new Color(0.85f, 0.85f, 0.88f);
        [Tooltip("Цвет узора на удилище и эмблемы на катушке.")]
        public Color accent = Color.white;
        public RodPattern pattern = RodPattern.Plain;
        [Tooltip("Узор на удилище.")]
        public RodGlyph motif = RodGlyph.None;
        [Tooltip("Эмблема на катушке.")]
        public RodGlyph emblem = RodGlyph.Leaf;
        [Tooltip("Подвеска под катушкой.")]
        public RodGlyph charm = RodGlyph.Leaf;
        public Color charmColor = new Color(0.4f, 0.75f, 0.3f);
    }
}
