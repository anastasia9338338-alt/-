using System.Collections.Generic;
using UnityEngine;
using ZooThrow.Data;
using ZooThrow.Visuals;

namespace ZooThrow.World
{
    public static class TrainerModelFactory
    {
        static readonly Dictionary<string, Mesh> s_Cache = new Dictionary<string, Mesh>();
        static readonly Color Metal = new Color(0.72f, 0.75f, 0.8f);
        static readonly Color Dark = new Color(0.18f, 0.18f, 0.22f);

        public static Mesh Get(TrainerData t)
        {
            if (s_Cache.TryGetValue(t.id, out var m)) return m;
            var mb = new MeshBuilder();
            Build(mb, t.shape, t.color);
            m = mb.ToMesh("Trainer_" + t.id);
            s_Cache[t.id] = m;
            return m;
        }

        public static void Build(MeshBuilder mb, TrainerShape shape, Color c)
        {
            switch (shape)
            {
                case TrainerShape.PullUpBar:
                    mb.Box(new Vector3(-1.3f, 1.65f, 0), new Vector3(0.22f, 3.3f, 0.22f), c);
                    mb.Box(new Vector3(1.3f, 1.65f, 0), new Vector3(0.22f, 3.3f, 0.22f), c);
                    mb.Push(new Vector3(-1.3f, WorldLayout.BarHeight, 0), Quaternion.Euler(0, 0, -90f));
                    mb.Cylinder(Vector3.zero, 0.07f, 0.07f, 2.6f, 8, Metal);
                    mb.Pop();
                    mb.Box(new Vector3(-1.3f, 0.08f, 0), new Vector3(0.7f, 0.16f, 0.7f), Dark);
                    mb.Box(new Vector3(1.3f, 0.08f, 0), new Vector3(0.7f, 0.16f, 0.7f), Dark);
                    break;
                case TrainerShape.Dumbbells:
                    mb.Box(new Vector3(0, 0.35f, 0), new Vector3(1.8f, 0.7f, 0.8f), Dark);
                    for (int i = -1; i <= 1; i += 2)
                    {
                        Vector3 p = new Vector3(i * 0.45f, 0.85f, 0);
                        mb.Push(p + new Vector3(0, 0, -0.35f), Quaternion.Euler(90f, 0, 0));
                        mb.Cylinder(Vector3.zero, 0.05f, 0.05f, 0.7f, 6, Metal);
                        mb.Cylinder(Vector3.zero, 0.18f, 0.18f, 0.14f, 8, c);
                        mb.Cylinder(new Vector3(0, 0.56f, 0), 0.18f, 0.18f, 0.14f, 8, c);
                        mb.Pop();
                    }
                    break;
                case TrainerShape.Barbell:
                    mb.Box(new Vector3(-0.9f, 0.5f, 0), new Vector3(0.15f, 1f, 0.5f), Dark);
                    mb.Box(new Vector3(0.9f, 0.5f, 0), new Vector3(0.15f, 1f, 0.5f), Dark);
                    mb.Push(new Vector3(-1.4f, 1.05f, 0), Quaternion.Euler(0, 0, -90f));
                    mb.Cylinder(Vector3.zero, 0.05f, 0.05f, 2.8f, 6, Metal);
                    mb.Cylinder(new Vector3(0, 0.1f, 0), 0.45f, 0.45f, 0.14f, 10, c);
                    mb.Cylinder(new Vector3(0, 2.56f, 0), 0.45f, 0.45f, 0.14f, 10, c);
                    mb.Pop();
                    break;
                case TrainerShape.Kettlebell:
                    mb.Sphere(new Vector3(0, 0.45f, 0), new Vector3(0.9f, 0.85f, 0.9f), c, 9, 6);
                    mb.Box(new Vector3(-0.25f, 1.0f, 0), new Vector3(0.12f, 0.35f, 0.14f), c);
                    mb.Box(new Vector3(0.25f, 1.0f, 0), new Vector3(0.12f, 0.35f, 0.14f), c);
                    mb.Box(new Vector3(0, 1.2f, 0), new Vector3(0.62f, 0.12f, 0.14f), c);
                    mb.Box(new Vector3(0, 0.5f, 0.42f), new Vector3(0.3f, 0.2f, 0.04f), new Color(1f, 0.85f, 0.2f));
                    break;
                case TrainerShape.PowerRack:
                    for (int x = -1; x <= 1; x += 2)
                        for (int z = -1; z <= 1; z += 2)
                            mb.Box(new Vector3(x * 0.9f, 1.4f, z * 0.6f), new Vector3(0.14f, 2.8f, 0.14f), c);
                    mb.Box(new Vector3(0, 2.8f, 0), new Vector3(1.95f, 0.14f, 1.35f), c, 1f);
                    mb.Push(new Vector3(-1.3f, 1.6f, 0), Quaternion.Euler(0, 0, -90f));
                    mb.Cylinder(Vector3.zero, 0.05f, 0.05f, 2.6f, 6, Metal);
                    mb.Cylinder(new Vector3(0, 0.05f, 0), 0.38f, 0.38f, 0.12f, 10, Dark);
                    mb.Cylinder(new Vector3(0, 2.43f, 0), 0.38f, 0.38f, 0.12f, 10, Dark);
                    mb.Pop();
                    mb.Box(new Vector3(0, 0.05f, 0), new Vector3(2.2f, 0.1f, 1.6f), Dark);
                    break;
                case TrainerShape.CosmicMachine:
                    mb.Cylinder(Vector3.zero, 1.1f, 0.9f, 0.4f, 10, Dark);
                    mb.Cylinder(new Vector3(0, 0.4f, 0), 0.3f, 0.25f, 1.6f, 8, Metal);
                    mb.Sphere(new Vector3(0, 2.3f, 0), 1.2f, c, 10, 6);
                    for (int i = 0; i < 3; i++)
                    {
                        float a = i * 120f;
                        mb.Box(new Vector3(0, 2.3f, 0), new Vector3(2.4f, 0.08f, 0.3f), Quaternion.Euler(20f, a, 0), new Color(0.5f, 0.95f, 1f));
                    }
                    mb.Sphere(new Vector3(0, 3.2f, 0), 0.25f, new Color(1f, 0.9f, 0.4f), 6, 4);
                    break;
            }
        }
    }
}
