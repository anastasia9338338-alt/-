using System.Collections.Generic;
using UnityEngine;

namespace ZooThrow.World
{
    public enum StationKind { Throw, FoodShop, UpgradeShop, Training, Pen, Collection }

    /// <summary>An interactable spot on the map. The player's InteractionSystem picks the nearest one in range.</summary>
    public class Station : MonoBehaviour
    {
        public static readonly List<Station> All = new List<Station>();

        public StationKind kind;
        public float radius = 4f;
        public string prompt;

        void OnEnable() => All.Add(this);
        void OnDisable() => All.Remove(this);

        public static Station Create(Transform parent, StationKind kind, Vector3 position, float radius, string prompt)
        {
            var go = new GameObject("Station_" + kind);
            go.transform.SetParent(parent, false);
            go.transform.position = position;
            var s = go.AddComponent<Station>();
            s.kind = kind;
            s.radius = radius;
            s.prompt = prompt;
            return s;
        }
    }
}
