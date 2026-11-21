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

        public static Texture Food(FoodData f)
        {
            if (R == null || f == null) return null;
            return R.Get("food_" + f.id, root =>
            {
                var go = MaterialLibrary.MeshObject("Food", root, FoodModelFactory.Get(f), new Vector3(0, 0.35f, 0));
                go.transform.localScale = Vector3.one * 1.4f;
                go.transform.localRotation = Quaternion.Euler(-25f, 0, 10f);
                return 0.9f;
            }, 160f);
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
