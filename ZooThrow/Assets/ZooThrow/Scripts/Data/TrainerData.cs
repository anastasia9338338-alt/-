using UnityEngine;

namespace ZooThrow.Data
{
    [CreateAssetMenu(menuName = "ZooThrow/Trainer", fileName = "Trainer")]
    public class TrainerData : ScriptableObject
    {
        public string id = "pullup_bar";
        public string displayName = "Турник";
        [TextArea] public string description;
        public double price;
        [Tooltip("Опыт за одно повторение.")]
        public double xpPerRep = 1;
        public int requiredPowerLevel;
        public TrainerShape shape;
        public Color color = new Color(0.6f, 0.6f, 0.65f);
    }
}
