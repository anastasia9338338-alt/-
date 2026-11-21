using System.Collections.Generic;
using UnityEngine;
using ZooThrow.Data;
using ZooThrow.Visuals;

namespace ZooThrow.Throwing
{
    /// <summary>Low-poly bait models (about 0.4 m across, shown on the hook and in the shop), cached per bait id.</summary>
    public static class BaitModelFactory
    {
        static readonly Dictionary<string, Mesh> s_Cache = new Dictionary<string, Mesh>();

        public static Mesh Get(BaitData f)
        {
            if (s_Cache.TryGetValue(f.id, out var m)) return m;
            var mb = new MeshBuilder();
            Color a = f.primary, b = f.secondary;
            switch (f.shape)
            {
                case BaitShape.Worm:
                    // Wiggly chain of segments
                    for (int i = 0; i < 9; i++)
                        mb.Sphere(new Vector3(Mathf.Sin(i * 0.8f) * 0.08f, Mathf.Cos(i * 0.5f) * 0.03f, -0.24f + i * 0.06f), Vector3.one * (i == 4 ? 0.1f : 0.08f), i == 4 ? b : a, 6, 4);
                    break;
                case BaitShape.Maggot:
                    for (int i = 0; i < 5; i++)
                        mb.Sphere(new Vector3(0, 0, -0.12f + i * 0.06f), new Vector3(0.12f - i * 0.008f, 0.11f, 0.08f), i % 2 == 0 ? a : b, 6, 4);
                    break;
                case BaitShape.Corn:
                    for (int i = 0; i < 3; i++)
                        mb.Sphere(new Vector3((i - 1) * 0.1f, 0, (i % 2) * 0.05f), new Vector3(0.11f, 0.09f, 0.1f), a, 6, 4);
                    mb.Box(new Vector3(0, -0.04f, -0.1f), new Vector3(0.05f, 0.02f, 0.15f), Quaternion.Euler(0, 30f, 0), b);
                    break;
                case BaitShape.Shrimp:
                    for (int i = 0; i < 6; i++)
                    {
                        float ang = i * 0.35f;
                        mb.Sphere(new Vector3(0, Mathf.Sin(ang) * 0.1f, Mathf.Cos(ang) * 0.12f - i * 0.03f), Vector3.one * (0.12f - i * 0.012f), i % 2 == 0 ? a : b, 6, 4);
                    }
                    mb.Box(new Vector3(0.03f, 0.04f, 0.18f), new Vector3(0.01f, 0.01f, 0.2f), Quaternion.Euler(-20f, 15f, 0), a);
                    mb.Box(new Vector3(-0.03f, 0.04f, 0.18f), new Vector3(0.01f, 0.01f, 0.2f), Quaternion.Euler(-20f, -15f, 0), a);
                    break;
                case BaitShape.Minnow:
                    mb.Sphere(Vector3.zero, new Vector3(0.1f, 0.12f, 0.34f), a, 8, 5);
                    mb.Sphere(new Vector3(0, -0.03f, 0.02f), new Vector3(0.08f, 0.07f, 0.28f), b, 6, 4);
                    mb.Box(new Vector3(0, 0, -0.2f), new Vector3(0.02f, 0.12f, 0.08f), a, 0.4f);
                    mb.Sphere(new Vector3(0.05f, 0.02f, 0.1f), Vector3.one * 0.03f, Color.black, 4, 3);
                    mb.Sphere(new Vector3(-0.05f, 0.02f, 0.1f), Vector3.one * 0.03f, Color.black, 4, 3);
                    break;
                case BaitShape.Squid:
                    mb.Push(new Vector3(0, 0, -0.05f), Quaternion.Euler(-90f, 0, 0));
                    mb.Cone(Vector3.zero, 0.09f, 0.28f, 7, a);
                    mb.Pop();
                    for (int i = 0; i < 6; i++)
                    {
                        float ang = i * Mathf.PI / 3f;
                        mb.Box(new Vector3(Mathf.Cos(ang) * 0.05f, Mathf.Sin(ang) * 0.05f, 0.08f), new Vector3(0.02f, 0.02f, 0.18f), b);
                    }
                    break;
                case BaitShape.Spoon:
                    mb.Sphere(Vector3.zero, new Vector3(0.16f, 0.03f, 0.3f), a, 8, 4);
                    mb.Sphere(new Vector3(0, 0.01f, 0.02f), new Vector3(0.1f, 0.03f, 0.18f), b, 6, 3);
                    mb.Cylinder(new Vector3(0, 0, -0.16f), 0.03f, 0.03f, 0.03f, 6, b);
                    break;
                case BaitShape.GlowOrb:
                    mb.Sphere(Vector3.zero, Vector3.one * 0.24f, a, 10, 6);
                    for (int i = 0; i < 6; i++)
                    {
                        float ang = i * Mathf.PI / 3f;
                        mb.Sphere(new Vector3(Mathf.Cos(ang) * 0.13f, 0, Mathf.Sin(ang) * 0.13f), Vector3.one * 0.06f, b, 4, 3);
                    }
                    break;
                case BaitShape.DragonBait:
                    mb.Sphere(Vector3.zero, new Vector3(0.3f, 0.12f, 0.24f), a, 8, 4);
                    mb.Sphere(new Vector3(0.04f, 0.03f, 0), new Vector3(0.2f, 0.08f, 0.16f), MeshBuilder.Shade(a, 1.2f), 6, 3);
                    for (int i = 0; i < 4; i++)
                    {
                        mb.Push(new Vector3(-0.08f + i * 0.06f, 0.05f, 0), Quaternion.Euler(0, 0, -20f + i * 12f));
                        mb.Cone(Vector3.zero, 0.03f, 0.12f, 4, b);
                        mb.Pop();
                    }
                    break;
            }
            m = mb.ToMesh("Bait_" + f.id);
            s_Cache[f.id] = m;
            return m;
        }
    }

    /// <summary>Fishing rod model built along +Y from the butt (y = 0) to the tip (y = length).</summary>
    public static class RodModelFactory
    {
        static readonly Dictionary<string, Mesh> s_Cache = new Dictionary<string, Mesh>();

        public static Vector3 TipLocal(RodData r) => new Vector3(0, r.length, 0);

        public static Mesh Get(RodData r)
        {
            if (s_Cache.TryGetValue(r.id, out var m)) return m;
            var mb = new MeshBuilder();
            float len = r.length;
            // Handle with grip rings
            mb.Cylinder(Vector3.zero, 0.05f, 0.045f, len * 0.22f, 8, r.secondary);
            for (int i = 0; i < 3; i++) mb.Cylinder(new Vector3(0, len * (0.03f + i * 0.06f), 0), 0.056f, 0.056f, 0.02f, 8, MeshBuilder.Shade(r.secondary, 0.7f));
            // Reel
            mb.Box(new Vector3(0, len * 0.14f, 0.07f), new Vector3(0.03f, 0.05f, 0.06f), MeshBuilder.Shade(r.secondary, 1.2f));
            mb.Push(new Vector3(-0.05f, len * 0.14f, 0.12f), Quaternion.Euler(0, 0, 90f));
            mb.Cylinder(Vector3.zero, 0.06f, 0.06f, 0.1f, 10, Color.Lerp(r.secondary, Color.white, 0.4f));
            mb.Pop();
            mb.Box(new Vector3(0.07f, len * 0.14f, 0.12f), new Vector3(0.02f, 0.02f, 0.08f), Color.white);
            // Blank: tapered rod
            mb.Cylinder(new Vector3(0, len * 0.22f, 0), 0.035f, 0.012f, len * 0.78f, 6, r.primary, false);
            // Line guides
            for (int i = 1; i <= 4; i++)
            {
                float y = len * (0.3f + i * 0.16f);
                mb.Box(new Vector3(0, y, 0.025f), new Vector3(0.012f, 0.012f, 0.03f), Color.Lerp(r.primary, Color.white, 0.5f));
            }
            if (r.glows)
                for (int i = 0; i < 4; i++)
                    mb.Sphere(new Vector3(0, len * (0.35f + i * 0.15f), 0), Vector3.one * 0.05f, r.lineColor, 5, 3);
            m = mb.ToMesh("Rod_" + r.id);
            s_Cache[r.id] = m;
            return m;
        }
    }
}
