using System.Collections.Generic;
using UnityEngine;
using ZooThrow.Data;
using ZooThrow.Visuals;

namespace ZooThrow.Throwing
{
    /// <summary>Low-poly food models (about 0.5 m across), cached per food id.</summary>
    public static class FoodModelFactory
    {
        static readonly Dictionary<string, Mesh> s_Cache = new Dictionary<string, Mesh>();

        public static Mesh Get(FoodData f)
        {
            if (s_Cache.TryGetValue(f.id, out var m)) return m;
            var mb = new MeshBuilder();
            Color a = f.primary, b = f.secondary;
            switch (f.shape)
            {
                case FoodShape.Carrot:
                    mb.Push(new Vector3(0, 0, 0.3f), Quaternion.Euler(90f, 0, 0));
                    mb.Cone(Vector3.zero, 0.14f, 0.6f, 7, a);
                    mb.Pop();
                    for (int i = 0; i < 3; i++)
                    {
                        mb.Push(new Vector3(0, 0, 0.3f), Quaternion.Euler(-70f + i * 20f, i * 120f, 0));
                        mb.Box(new Vector3(0, 0.12f, 0), new Vector3(0.05f, 0.25f, 0.08f), b, 0.4f);
                        mb.Pop();
                    }
                    break;
                case FoodShape.Apple:
                    mb.Sphere(Vector3.zero, new Vector3(0.42f, 0.38f, 0.42f), a, 9, 6);
                    mb.Box(new Vector3(0, 0.22f, 0), new Vector3(0.03f, 0.12f, 0.03f), new Color(0.4f, 0.25f, 0.1f));
                    mb.Box(new Vector3(0.07f, 0.25f, 0), new Vector3(0.12f, 0.02f, 0.07f), Quaternion.Euler(0, 0, 20f), b);
                    break;
                case FoodShape.Bread:
                    mb.Box(Vector3.zero, new Vector3(0.3f, 0.22f, 0.6f), a, 0.8f);
                    for (int i = -1; i <= 1; i++) mb.Box(new Vector3(0, 0.11f, i * 0.16f), new Vector3(0.2f, 0.03f, 0.04f), Quaternion.Euler(0, 30f, 0), b);
                    break;
                case FoodShape.Burger:
                    mb.Cylinder(new Vector3(0, -0.15f, 0), 0.26f, 0.27f, 0.08f, 10, b);
                    mb.Cylinder(new Vector3(0, -0.07f, 0), 0.29f, 0.29f, 0.08f, 10, a);
                    mb.Box(new Vector3(0, 0.02f, 0), new Vector3(0.5f, 0.03f, 0.5f), Quaternion.Euler(0, 45f, 0), new Color(1f, 0.85f, 0.2f));
                    mb.Cylinder(new Vector3(0, 0.03f, 0), 0.3f, 0.3f, 0.03f, 10, new Color(0.3f, 0.8f, 0.25f));
                    mb.Sphere(new Vector3(0, 0.12f, 0), new Vector3(0.54f, 0.24f, 0.54f), b, 10, 4);
                    break;
                case FoodShape.Pizza:
                    mb.Cylinder(Vector3.zero, 0.34f, 0.34f, 0.05f, 12, a);
                    mb.Cylinder(new Vector3(0, -0.005f, 0), 0.37f, 0.37f, 0.04f, 12, new Color(0.85f, 0.6f, 0.3f));
                    for (int i = 0; i < 6; i++)
                    {
                        float ang = i * Mathf.PI / 3f;
                        mb.Cylinder(new Vector3(Mathf.Cos(ang) * 0.19f, 0.05f, Mathf.Sin(ang) * 0.19f), 0.06f, 0.06f, 0.015f, 7, b);
                    }
                    break;
                case FoodShape.Steak:
                    mb.Sphere(Vector3.zero, new Vector3(0.55f, 0.14f, 0.4f), a, 8, 4);
                    mb.Sphere(new Vector3(0.05f, 0.03f, 0), new Vector3(0.4f, 0.1f, 0.28f), MeshBuilder.Shade(a, 1.15f), 7, 3);
                    mb.Box(new Vector3(-0.32f, 0, 0), new Vector3(0.22f, 0.06f, 0.06f), b);
                    mb.Sphere(new Vector3(-0.44f, 0, 0.04f), 0.09f, b, 6, 4);
                    mb.Sphere(new Vector3(-0.44f, 0, -0.04f), 0.09f, b, 6, 4);
                    break;
                case FoodShape.GoldenStar:
                    for (int i = 0; i < 5; i++)
                    {
                        float ang = i * 72f;
                        mb.Push(Vector3.zero, Quaternion.Euler(0, 0, ang));
                        mb.Box(new Vector3(0, 0.18f, 0), new Vector3(0.16f, 0.32f, 0.14f), a, 0.15f);
                        mb.Pop();
                    }
                    mb.Sphere(Vector3.zero, new Vector3(0.26f, 0.26f, 0.18f), b, 8, 4);
                    break;
                case FoodShape.RainbowCake:
                    {
                        Color[] rainbow = { new Color(1f, 0.3f, 0.3f), new Color(1f, 0.6f, 0.2f), new Color(1f, 0.9f, 0.3f), new Color(0.4f, 0.9f, 0.4f), new Color(0.3f, 0.6f, 1f), new Color(0.7f, 0.4f, 1f) };
                        for (int i = 0; i < rainbow.Length; i++)
                            mb.Cylinder(new Vector3(0, -0.2f + i * 0.065f, 0), 0.3f - i * 0.02f, 0.3f - i * 0.02f, 0.065f, 12, rainbow[i]);
                        mb.Sphere(new Vector3(0, 0.22f, 0), 0.12f, Color.white, 7, 4);
                        mb.Sphere(new Vector3(0, 0.3f, 0), 0.08f, new Color(1f, 0.2f, 0.3f), 6, 4);
                        break;
                    }
            }
            m = mb.ToMesh("Food_" + f.id);
            s_Cache[f.id] = m;
            return m;
        }
    }
}
