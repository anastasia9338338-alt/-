using UnityEngine;
using ZooThrow.Core;
using ZooThrow.UI;
using ZooThrow.World;

namespace ZooThrow.Player
{
    /// <summary>Finds the nearest station, shows its prompt and runs it on E (or the on-screen button).</summary>
    public class InteractionSystem : MonoBehaviour
    {
        GameManager _g;
        public Station Current { get; private set; }

        public void Init(GameManager g) => _g = g;

        void Update()
        {
            if (_g == null) return;
            Current = null;
            if (_g.Mode == GameMode.Playing)
            {
                Vector3 p = transform.position;
                float best = float.MaxValue;
                foreach (var s in Station.All)
                {
                    Vector3 d = s.transform.position - p;
                    d.y = 0;
                    float dist = d.magnitude;
                    if (dist <= s.radius && dist < best) { best = dist; Current = s; }
                }
            }
            if (Current != null && GameInput.Pressed(GameKey.Interact) && !_g.UI.AnyWindowOpen) Interact(Current);
        }

        public void Interact(Station s)
        {
            if (s == null) return;
            switch (s.kind)
            {
                case StationKind.Throw: _g.Throw.RequestThrow(); break;
                case StationKind.FoodShop: _g.UI.Open(WindowId.Shop); break;
                case StationKind.UpgradeShop: _g.UI.Open(WindowId.Upgrades); break;
                case StationKind.Training: _g.Training.StartTraining(); break;
                case StationKind.Pen: _g.UI.Open(WindowId.Animals); break;
                case StationKind.Collection: _g.UI.Open(WindowId.Collection); break;
            }
        }
    }
}
