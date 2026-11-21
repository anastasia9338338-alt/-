using System.Collections.Generic;
using UnityEngine;
using ZooThrow.Core;
using ZooThrow.Visuals;

namespace ZooThrow.World
{
    /// <summary>Displays every owned trainer next to the pull-up bar; the best one gets a highlight.</summary>
    public class TrainingView : MonoBehaviour
    {
        GameManager _g;
        readonly Dictionary<string, GameObject> _shown = new Dictionary<string, GameObject>();
        GameObject _highlight;

        public void Init(GameManager g)
        {
            _g = g;
            var mb = new MeshBuilder();
            mb.Cylinder(Vector3.zero, 1.4f, 1.4f, 0.06f, 16, new Color(1f, 0.85f, 0.2f));
            _highlight = MaterialLibrary.MeshObject("BestTrainerHighlight", transform, mb.ToMesh("Highlight"), Vector3.zero, false);
            _highlight.GetComponent<MeshRenderer>().sharedMaterial = MaterialLibrary.ToonEmissive;
            GameEvents.ShopChanged += Refresh;
            Refresh();
        }

        void OnDestroy() => GameEvents.ShopChanged -= Refresh;

        void Refresh()
        {
            int index = 0;
            foreach (var t in _g.Db.trainers)
            {
                if (t.shape == Data.TrainerShape.PullUpBar) continue;
                if (_g.Trainers.Owns(t) && !_shown.ContainsKey(t.id))
                {
                    var go = MaterialLibrary.MeshObject("Trainer_" + t.id, transform, TrainerModelFactory.Get(t), WorldLayout.TrainerDisplay(index));
                    _shown[t.id] = go;
                    _g.Vfx.Poof(go.transform.position + Vector3.up);
                }
                index++;
            }
            var best = _g.Trainers.Best;
            if (best != null && _shown.TryGetValue(best.id, out var bestGo))
            {
                _highlight.SetActive(true);
                _highlight.transform.position = bestGo.transform.position + Vector3.up * 0.02f;
            }
            else
            {
                _highlight.SetActive(true);
                _highlight.transform.position = WorldLayout.PullUpBar + Vector3.up * 0.12f;
            }
        }
    }
}
