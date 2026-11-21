using UnityEngine;

namespace ZooThrow.World
{
    /// <summary>Positions of everything on the map. Y is up, the throwing track runs along +Z.</summary>
    public static class WorldLayout
    {
        public static readonly Vector3 Spawn = new Vector3(0f, 0f, -6f);
        public static readonly Vector3 ThrowPad = new Vector3(0f, 0f, 10f);
        /// <summary>World Z where throw distance is 0 m.</summary>
        public const float ThrowOriginZ = 10f;
        public const float PadRadius = 3.2f;
        public const float LaneHalfWidth = 9f;
        /// <summary>Surface height of the casting channel water.</summary>
        public const float WaterLevel = 0.08f;
        public const float WorldHalfWidth = 90f;

        public static readonly Vector3 PenCenter = new Vector3(-26f, 0f, -14f);
        public static readonly Vector2 PenSize = new Vector2(24f, 18f);
        public static readonly Vector3 PenGate = new Vector3(-14f, 0f, -14f);

        public static readonly Vector3 TrainingCenter = new Vector3(24f, 0f, -12f);
        public static readonly Vector3 PullUpBar = new Vector3(24f, 0f, -12f);
        public const float BarHeight = 3.1f;

        public static readonly Vector3 RodShop = new Vector3(-13f, 0f, 3f);
        public static readonly Vector3 BaitShop = new Vector3(13f, 0f, -4f);
        public static readonly Vector3 UpgradeShop = new Vector3(13f, 0f, 3f);
        public static readonly Vector3 Museum = new Vector3(0f, 0f, -26f);

        public const int PenColumns = 4;
        public const float PenSlotSpacingX = 5.2f;
        public const float PenSlotSpacingZ = 5.2f;

        public static Vector3 PenSlot(int index)
        {
            int col = index % PenColumns;
            int row = index / PenColumns;
            float x = (col - (PenColumns - 1) * 0.5f) * PenSlotSpacingX;
            float z = (1 - row) * PenSlotSpacingZ;
            return PenCenter + new Vector3(x, 0f, z);
        }

        public static Vector3 TrackPoint(float distance, float x = 0f) => new Vector3(x, 0f, ThrowOriginZ + distance);
        public static float DistanceOf(Vector3 world) => world.z - ThrowOriginZ;

        public static Vector3 TrainerDisplay(int index) => TrainingCenter + new Vector3(-3.5f + (index % 3) * 3.5f, 0f, -5.5f - (index / 3) * 3.2f);
    }
}
