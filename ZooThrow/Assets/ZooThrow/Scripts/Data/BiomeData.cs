using UnityEngine;

namespace ZooThrow.Data
{
    [CreateAssetMenu(menuName = "ZooThrow/Biome", fileName = "Biome")]
    public class BiomeData : ScriptableObject
    {
        public string id = "forest";
        public string displayName = "Лес";
        [TextArea] public string description;
        public BiomeStyle style;
        [Tooltip("Начало биома по дальности броска, метры.")]
        public float startDistance;
        [Tooltip("Конец биома по дальности броска, метры.")]
        public float endDistance = 60f;
        public Color groundColor = new Color(0.45f, 0.78f, 0.35f);
        public Color groundColorAlt = new Color(0.40f, 0.72f, 0.30f);
        public Color laneColor = new Color(0.85f, 0.72f, 0.48f);
        public Color accentColor = Color.white;
        public Color fogColor = new Color(0.75f, 0.88f, 1f);

        public bool Contains(float distance) => distance >= startDistance && distance < endDistance;
    }
}
