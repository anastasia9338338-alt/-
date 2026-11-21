using UnityEngine;
using ZooThrow.Animals;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Throwing;
using ZooThrow.Visuals;
using ZooThrow.World;

namespace ZooThrow.UI
{
    /// <summary>3D portraits for UI cards, rendered once per item by PortraitRenderer.</summary>
    public static class Portraits
    {
        static PortraitRenderer R => GameManager.Instance != null ? GameManager.Instance.Portraits : null;

        public static Texture Animal(AnimalData a)
        {
            if (R == null || a == null) return null;
            return R.Get("animal_" + a.id, root =>
            {
                var actor = AnimalActor.Create(a, Mutation.None, GameManager.Instance.Balance, root, root.position, 1);
                var model = AnimalModelFactory.Get(a);
                return Mathf.Max(actor.Height, model.length * a.size * 0.75f);
            }, 150f);
        }

        public static Texture Bait(BaitData f)
        {
            if (R == null || f == null) return null;
            return R.Get("bait_" + f.id, root =>
            {
                var go = MaterialLibrary.MeshObject("Bait", root, BaitModelFactory.Get(f), new Vector3(0, 0.3f, 0));
                go.transform.localScale = Vector3.one * 2f;
                go.transform.localRotation = Quaternion.Euler(-25f, 30f, 10f);
                return 0.75f;
            }, 160f);
        }

        public static Texture Rod(RodData r)
        {
            if (R == null || r == null) return null;
            return R.Get("rod_" + r.id, root =>
            {
                // Lay the rod diagonally so the whole blank fits the square portrait.
                var go = MaterialLibrary.MeshObject("Rod", root, RodModelFactory.Get(r), new Vector3(-r.length * 0.3f, 0.1f, 0));
                go.transform.localRotation = Quaternion.Euler(0, 0, -50f);
                return r.length * 0.75f;
            }, 180f);
        }

        public static Texture Trainer(TrainerData t)
        {
            if (R == null || t == null) return null;
            return R.Get("trainer_" + t.id, root =>
            {
                MaterialLibrary.MeshObject("Trainer", root, TrainerModelFactory.Get(t), Vector3.zero);
                return t.shape == TrainerShape.PullUpBar || t.shape == TrainerShape.PowerRack || t.shape == TrainerShape.CosmicMachine ? 3.2f : 1.8f;
            }, 155f);
        }
    }
}
