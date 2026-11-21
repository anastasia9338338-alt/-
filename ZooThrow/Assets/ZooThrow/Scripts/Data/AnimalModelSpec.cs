using System;
using UnityEngine;

namespace ZooThrow.Data
{
    /// <summary>Parameters for the procedural low-poly animal model. Units are metres at size 1.</summary>
    [Serializable]
    public class AnimalModelSpec
    {
        public BodyPlan plan = BodyPlan.Quadruped;
        public AnimalFeatures features;
        public Color primary = Color.white;
        public Color secondary = Color.gray;
        public Color accent = Color.black;
        [Range(0.2f, 3f)] public float bodyLength = 1f;
        [Range(0.2f, 3f)] public float bodyHeight = 0.7f;
        [Range(0.2f, 3f)] public float bodyWidth = 0.6f;
        [Range(0f, 2f)] public float legLength = 0.5f;
        [Range(0f, 3f)] public float neckLength = 0.2f;
        [Range(0.1f, 2f)] public float headSize = 0.45f;
        [Range(0f, 2f)] public float tailLength = 0.3f;
        [Range(0f, 1.5f)] public float earSize = 0.2f;

        public AnimalModelSpec Clone() => (AnimalModelSpec)MemberwiseClone();
    }
}
