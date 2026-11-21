using UnityEngine;
using ZooThrow.Visuals;

namespace ZooThrow.World
{
    /// <summary>Low-poly props appended into a MeshBuilder at a world position. Sizes are in metres.</summary>
    public static class DecorFactory
    {
        static readonly Color Trunk = new Color(0.52f, 0.34f, 0.2f);
        static readonly Color Snow = new Color(0.96f, 0.98f, 1f);

        static float R(System.Random rng, float a, float b) => a + (float)rng.NextDouble() * (b - a);

        public static void RoundTree(MeshBuilder mb, Vector3 p, System.Random rng, Color leaves)
        {
            float s = R(rng, 0.8f, 1.4f);
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0), Vector3.one * s);
            mb.Cylinder(Vector3.zero, 0.35f, 0.25f, 2.2f, 6, Trunk);
            mb.Sphere(new Vector3(0, 3.2f, 0), new Vector3(3f, 2.6f, 3f), leaves, 7, 5);
            mb.Sphere(new Vector3(0.6f, 4.2f, 0.3f), new Vector3(2f, 1.8f, 2f), MeshBuilder.Shade(leaves, 1.1f), 6, 4);
            mb.Sphere(new Vector3(-0.7f, 3.8f, -0.4f), new Vector3(1.8f, 1.6f, 1.8f), MeshBuilder.Shade(leaves, 0.92f), 6, 4);
            mb.Pop();
        }

        public static void PineTree(MeshBuilder mb, Vector3 p, System.Random rng, Color leaves, bool snowy)
        {
            float s = R(rng, 0.8f, 1.5f);
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0), Vector3.one * s);
            mb.Cylinder(Vector3.zero, 0.3f, 0.2f, 1.4f, 6, Trunk);
            for (int i = 0; i < 3; i++)
            {
                float y = 1.1f + i * 1.25f, r = 1.9f - i * 0.5f;
                mb.Cone(new Vector3(0, y, 0), r, 2.0f, 7, MeshBuilder.Shade(leaves, 1f + i * 0.06f));
                if (snowy) mb.Cone(new Vector3(0, y + 1.1f, 0), r * 0.45f, 0.9f, 7, Snow);
            }
            mb.Pop();
        }

        public static void Bush(MeshBuilder mb, Vector3 p, System.Random rng, Color c)
        {
            float s = R(rng, 0.6f, 1.2f);
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0), Vector3.one * s);
            mb.Sphere(new Vector3(0, 0.5f, 0), new Vector3(1.6f, 1.1f, 1.4f), c, 6, 4);
            mb.Sphere(new Vector3(0.6f, 0.4f, 0.2f), new Vector3(1.0f, 0.8f, 1.0f), MeshBuilder.Shade(c, 1.1f), 6, 4);
            if (rng.NextDouble() < 0.4)
                for (int i = 0; i < 3; i++) mb.Sphere(new Vector3(R(rng, -0.6f, 0.6f), R(rng, 0.7f, 1.0f), R(rng, -0.5f, 0.5f)), 0.18f, new Color(1f, 0.35f, 0.4f), 5, 3);
            mb.Pop();
        }

        public static void Rock(MeshBuilder mb, Vector3 p, System.Random rng, Color c, float scale = 1f)
        {
            float s = R(rng, 0.6f, 1.6f) * scale;
            mb.Push(p, Quaternion.Euler(R(rng, -10, 10), R(rng, 0, 360), R(rng, -10, 10)), new Vector3(s * R(rng, 0.8f, 1.3f), s * R(rng, 0.5f, 0.9f), s));
            mb.Sphere(new Vector3(0, 0.3f, 0), new Vector3(1.6f, 1.2f, 1.3f), c, 5, 3);
            mb.Sphere(new Vector3(0.5f, 0.2f, 0.4f), new Vector3(0.8f, 0.7f, 0.8f), MeshBuilder.Shade(c, 0.9f), 5, 3);
            mb.Pop();
        }

        public static void Flower(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            Color[] petals = { new Color(1f, 0.4f, 0.5f), new Color(1f, 0.85f, 0.3f), new Color(0.6f, 0.5f, 1f), Color.white };
            var c = petals[rng.Next(petals.Length)];
            mb.Push(p);
            mb.Box(new Vector3(0, 0.25f, 0), new Vector3(0.05f, 0.5f, 0.05f), new Color(0.3f, 0.7f, 0.3f));
            for (int i = 0; i < 4; i++)
                mb.Box(new Vector3(0, 0.52f, 0), new Vector3(0.32f, 0.05f, 0.12f), Quaternion.Euler(0, i * 45f, 0), c);
            mb.Box(new Vector3(0, 0.55f, 0), new Vector3(0.1f, 0.06f, 0.1f), new Color(1f, 0.9f, 0.2f));
            mb.Pop();
        }

        public static void Mushroom(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            float s = R(rng, 0.5f, 1.1f);
            mb.Push(p, Quaternion.identity, Vector3.one * s);
            mb.Cylinder(Vector3.zero, 0.15f, 0.12f, 0.5f, 6, new Color(0.96f, 0.92f, 0.85f));
            mb.Cylinder(new Vector3(0, 0.45f, 0), 0.5f, 0.05f, 0.4f, 8, new Color(0.9f, 0.2f, 0.2f));
            mb.Sphere(new Vector3(0.2f, 0.68f, 0.1f), 0.1f, Color.white, 4, 3);
            mb.Sphere(new Vector3(-0.15f, 0.65f, -0.15f), 0.08f, Color.white, 4, 3);
            mb.Pop();
        }

        public static void GrassTuft(MeshBuilder mb, Vector3 p, System.Random rng, Color c)
        {
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0));
            for (int i = 0; i < 4; i++)
                mb.Box(new Vector3(R(rng, -0.2f, 0.2f), 0.35f, R(rng, -0.2f, 0.2f)), new Vector3(0.08f, R(rng, 0.5f, 0.9f), 0.04f), Quaternion.Euler(R(rng, -15, 15), i * 45f, R(rng, -15, 15)), c, 0.2f);
            mb.Pop();
        }

        public static void AcaciaTree(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            float s = R(rng, 0.9f, 1.4f);
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0), Vector3.one * s);
            mb.Box(new Vector3(0, 1.5f, 0), new Vector3(0.4f, 3f, 0.4f), Quaternion.Euler(0, 0, 8f), Trunk);
            mb.Box(new Vector3(0.9f, 3f, 0), new Vector3(0.25f, 1.6f, 0.25f), Quaternion.Euler(0, 0, -45f), Trunk);
            mb.Box(new Vector3(-0.8f, 3f, 0.2f), new Vector3(0.25f, 1.4f, 0.25f), Quaternion.Euler(0, 0, 40f), Trunk);
            var leaves = new Color(0.45f, 0.62f, 0.2f);
            mb.Sphere(new Vector3(0.2f, 3.8f, 0), new Vector3(5.5f, 0.9f, 4.2f), leaves, 8, 3);
            mb.Sphere(new Vector3(1.4f, 4.1f, 0.4f), new Vector3(2.8f, 0.6f, 2.4f), MeshBuilder.Shade(leaves, 1.12f), 7, 3);
            mb.Pop();
        }

        public static void TermiteMound(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            float s = R(rng, 0.7f, 1.3f);
            mb.Push(p, Quaternion.identity, Vector3.one * s);
            var c = new Color(0.72f, 0.45f, 0.28f);
            mb.Cone(Vector3.zero, 1.1f, 3.2f, 7, c);
            mb.Cone(new Vector3(0.6f, 0, 0.3f), 0.6f, 1.8f, 6, MeshBuilder.Shade(c, 0.9f));
            mb.Pop();
        }

        public static void Cactus(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            float s = R(rng, 0.8f, 1.5f);
            var c = new Color(0.3f, 0.65f, 0.3f);
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0), Vector3.one * s);
            mb.Cylinder(Vector3.zero, 0.38f, 0.32f, 3f, 7, c);
            mb.Sphere(new Vector3(0, 3f, 0), 0.64f, c, 7, 4);
            mb.Cylinder(new Vector3(0.35f, 1.2f, 0), 0.2f, 0.2f, 0.6f, 6, c);
            mb.Box(new Vector3(0.75f, 1.35f, 0), new Vector3(0.6f, 0.35f, 0.35f), c);
            mb.Cylinder(new Vector3(0.95f, 1.35f, 0), 0.18f, 0.16f, 1.1f, 6, c);
            mb.Sphere(new Vector3(0.95f, 2.45f, 0), 0.34f, c, 6, 3);
            if (rng.NextDouble() < 0.5) mb.Sphere(new Vector3(0, 3.35f, 0), 0.25f, new Color(1f, 0.45f, 0.6f), 5, 3);
            mb.Pop();
        }

        public static void Dune(MeshBuilder mb, Vector3 p, System.Random rng, Color c)
        {
            mb.Sphere(p, new Vector3(R(rng, 8f, 16f), R(rng, 1.5f, 3.5f), R(rng, 6f, 12f)), c, 8, 4);
        }

        public static void Pyramid(MeshBuilder mb, Vector3 p, float size)
        {
            var c = new Color(0.93f, 0.78f, 0.5f);
            mb.Cylinder(p, size, 0f, size * 0.9f, 4, c);
            mb.Cylinder(p + Vector3.up * size * 0.62f, size * 0.32f, 0f, size * 0.29f, 4, new Color(1f, 0.85f, 0.3f));
        }

        public static void PalmTree(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            float s = R(rng, 0.9f, 1.4f);
            float lean = R(rng, -15f, 15f);
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0), Vector3.one * s);
            Vector3 top = Vector3.zero;
            for (int i = 0; i < 5; i++)
            {
                mb.Box(top + new Vector3(0, 0.5f, 0), new Vector3(0.35f - i * 0.03f, 1.05f, 0.35f - i * 0.03f), Quaternion.Euler(0, 0, lean * 0.3f), i % 2 == 0 ? Trunk : MeshBuilder.Shade(Trunk, 1.15f));
                top += Quaternion.Euler(0, 0, lean * 0.3f) * new Vector3(0, 1f, 0);
            }
            var leaf = new Color(0.25f, 0.7f, 0.3f);
            for (int i = 0; i < 6; i++)
            {
                mb.Push(top, Quaternion.Euler(25f, i * 60f, 0));
                mb.Box(new Vector3(0, 0, 1.3f), new Vector3(0.7f, 0.06f, 2.6f), Quaternion.Euler(15f, 0, 0), i % 2 == 0 ? leaf : MeshBuilder.Shade(leaf, 0.85f), 0.6f);
                mb.Pop();
            }
            mb.Sphere(top + new Vector3(0.2f, -0.2f, 0), 0.3f, new Color(0.45f, 0.3f, 0.15f), 5, 3);
            mb.Sphere(top + new Vector3(-0.2f, -0.25f, 0.1f), 0.3f, new Color(0.45f, 0.3f, 0.15f), 5, 3);
            mb.Pop();
        }

        public static void BigLeaf(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            var c = new Color(0.15f, 0.6f, 0.25f);
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0));
            for (int i = 0; i < 5; i++)
            {
                mb.Push(Vector3.zero, Quaternion.Euler(R(rng, 30f, 55f), i * 72f, 0));
                mb.Box(new Vector3(0, 0, 0.9f), new Vector3(0.8f, 0.05f, 1.8f), MeshBuilder.Shade(c, R(rng, 0.85f, 1.15f)), 0.5f);
                mb.Pop();
            }
            mb.Pop();
        }

        public static void JungleTree(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            float s = R(rng, 1.1f, 1.8f);
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0), Vector3.one * s);
            mb.Cylinder(Vector3.zero, 0.55f, 0.35f, 4.5f, 7, MeshBuilder.Shade(Trunk, 0.85f));
            var c = new Color(0.12f, 0.55f, 0.22f);
            mb.Sphere(new Vector3(0, 5.2f, 0), new Vector3(5f, 2.6f, 5f), c, 8, 4);
            mb.Sphere(new Vector3(1.2f, 6f, 0.8f), new Vector3(3f, 2f, 3f), MeshBuilder.Shade(c, 1.15f), 7, 4);
            for (int i = 0; i < 3; i++)
                mb.Box(new Vector3(R(rng, -1.8f, 1.8f), 3.4f, R(rng, -1.8f, 1.8f)), new Vector3(0.06f, 3f, 0.06f), new Color(0.2f, 0.5f, 0.2f));
            mb.Pop();
        }

        public static void Coral(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            Color[] cols = { new Color(1f, 0.45f, 0.5f), new Color(1f, 0.65f, 0.3f), new Color(0.7f, 0.45f, 1f) };
            var c = cols[rng.Next(cols.Length)];
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0));
            for (int i = 0; i < 4; i++)
            {
                mb.Push(Vector3.zero, Quaternion.Euler(R(rng, -30, 30), i * 90f, R(rng, -30, 30)));
                mb.Cylinder(Vector3.zero, 0.15f, 0.08f, R(rng, 0.8f, 1.6f), 5, c);
                mb.Pop();
            }
            mb.Pop();
        }

        public static void Buoy(MeshBuilder mb, Vector3 p)
        {
            mb.Cylinder(p, 0.6f, 0.4f, 0.8f, 8, new Color(1f, 0.3f, 0.25f));
            mb.Cylinder(p + Vector3.up * 0.8f, 0.4f, 0.3f, 0.3f, 8, Color.white);
            mb.Cone(p + Vector3.up * 1.1f, 0.3f, 0.6f, 8, new Color(1f, 0.3f, 0.25f));
        }

        public static void Snowman(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            mb.Push(p, Quaternion.Euler(0, R(rng, 120, 240), 0));
            mb.Sphere(new Vector3(0, 0.7f, 0), 1.5f, Snow, 8, 5);
            mb.Sphere(new Vector3(0, 1.85f, 0), 1.1f, Snow, 8, 5);
            mb.Sphere(new Vector3(0, 2.7f, 0), 0.8f, Snow, 8, 5);
            mb.Push(new Vector3(0, 2.7f, 0.35f), Quaternion.Euler(90f, 0, 0));
            mb.Cone(Vector3.zero, 0.09f, 0.45f, 5, new Color(1f, 0.5f, 0.1f));
            mb.Pop();
            mb.Box(new Vector3(-0.15f, 2.85f, 0.36f), Vector3.one * 0.08f, Color.black);
            mb.Box(new Vector3(0.15f, 2.85f, 0.36f), Vector3.one * 0.08f, Color.black);
            mb.Cylinder(new Vector3(0, 3.05f, 0), 0.45f, 0.45f, 0.08f, 8, new Color(0.2f, 0.2f, 0.25f));
            mb.Cylinder(new Vector3(0, 3.1f, 0), 0.3f, 0.3f, 0.5f, 8, new Color(0.2f, 0.2f, 0.25f));
            mb.Box(new Vector3(0, 2.35f, 0), new Vector3(0.9f, 0.15f, 0.9f), new Color(0.9f, 0.2f, 0.2f));
            mb.Pop();
        }

        public static void IceCrystal(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            var c = new Color(0.65f, 0.88f, 1f);
            mb.Push(p, Quaternion.Euler(R(rng, -15, 15), R(rng, 0, 360), R(rng, -15, 15)));
            for (int i = 0; i < 3; i++)
            {
                mb.Push(Vector3.zero, Quaternion.Euler(R(rng, -25, 25), i * 120f, R(rng, -25, 25)));
                float h = R(rng, 1.2f, 2.6f);
                mb.Cylinder(Vector3.zero, 0.35f, 0.3f, h, 6, MeshBuilder.Shade(c, 1f + i * 0.05f));
                mb.Cone(Vector3.up * h, 0.3f, 0.6f, 6, Color.white);
                mb.Pop();
            }
            mb.Pop();
        }

        public static void Mountain(MeshBuilder mb, Vector3 p, float radius, float height, Color rock, bool snowCap)
        {
            mb.Cone(p, radius, height, 7, rock);
            if (snowCap) mb.Cylinder(p + Vector3.up * height * 0.62f, radius * 0.38f, 0f, height * 0.38f, 7, Snow);
        }

        public static void Fence(MeshBuilder mb, Vector3 a, Vector3 b, Color wood)
        {
            Vector3 d = b - a;
            float len = d.magnitude;
            int posts = Mathf.Max(1, Mathf.CeilToInt(len / 2.4f));
            for (int i = 0; i <= posts; i++)
            {
                Vector3 p = Vector3.Lerp(a, b, i / (float)posts);
                mb.Box(p + Vector3.up * 0.65f, new Vector3(0.28f, 1.3f, 0.28f), MeshBuilder.Shade(wood, 0.9f), 0.85f);
            }
            Quaternion rot = Quaternion.LookRotation(d.normalized, Vector3.up);
            mb.Box(a + d * 0.5f + Vector3.up * 0.45f, new Vector3(0.12f, 0.18f, len), rot, wood);
            mb.Box(a + d * 0.5f + Vector3.up * 1.0f, new Vector3(0.12f, 0.18f, len), rot, wood);
        }

        public static void Reeds(MeshBuilder mb, Vector3 p, System.Random rng, Color c)
        {
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0));
            int n = rng.Next(5, 9);
            for (int i = 0; i < n; i++)
            {
                float h = R(rng, 1.2f, 2.2f);
                Vector3 b = new Vector3(R(rng, -0.4f, 0.4f), 0, R(rng, -0.4f, 0.4f));
                mb.Box(b + new Vector3(0, h * 0.5f, 0), new Vector3(0.05f, h, 0.05f), Quaternion.Euler(R(rng, -8, 8), 0, R(rng, -8, 8)), c);
                if (i % 2 == 0) mb.Box(b + new Vector3(0, h * 0.85f, 0), new Vector3(0.12f, h * 0.22f, 0.12f), new Color(0.45f, 0.3f, 0.18f)); // cattail head
            }
            mb.Pop();
        }

        public static void LilyPad(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            float r = R(rng, 0.35f, 0.7f);
            mb.Cylinder(p, r, r, 0.03f, 9, new Color(0.3f, 0.65f, 0.3f));
            if (rng.NextDouble() < 0.35)
            {
                Color petal = rng.NextDouble() < 0.5 ? new Color(1f, 0.75f, 0.85f) : Color.white;
                for (int i = 0; i < 5; i++)
                {
                    float a = i * 72f;
                    mb.Box(p + Quaternion.Euler(0, a, 0) * new Vector3(0, 0.12f, 0.1f), new Vector3(0.1f, 0.05f, 0.2f), Quaternion.Euler(-35f, a, 0), petal, 0.4f);
                }
                mb.Sphere(p + Vector3.up * 0.12f, 0.08f, new Color(1f, 0.85f, 0.2f), 5, 3);
            }
        }

        public static void DeadTree(MeshBuilder mb, Vector3 p, System.Random rng, Color bark)
        {
            float s = R(rng, 0.8f, 1.4f);
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0), Vector3.one * s);
            mb.Cylinder(Vector3.zero, 0.3f, 0.15f, 3.2f, 6, bark);
            for (int i = 0; i < 3; i++)
            {
                mb.Push(new Vector3(0, 1.6f + i * 0.5f, 0), Quaternion.Euler(R(rng, 35, 60), i * 120f, 0));
                mb.Cylinder(Vector3.zero, 0.1f, 0.03f, R(rng, 0.8f, 1.4f), 5, bark, false);
                mb.Pop();
            }
            mb.Pop();
        }

        public static void GlowCrystal(MeshBuilder mb, Vector3 p, System.Random rng, Color c)
        {
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0));
            int n = rng.Next(2, 5);
            for (int i = 0; i < n; i++)
            {
                mb.Push(new Vector3(R(rng, -0.4f, 0.4f), 0, R(rng, -0.4f, 0.4f)), Quaternion.Euler(R(rng, -25, 25), 0, R(rng, -25, 25)));
                float h = R(rng, 0.8f, 2.4f);
                mb.Cylinder(Vector3.zero, 0.25f, 0.22f, h, 5, MeshBuilder.Shade(c, R(rng, 0.85f, 1.15f)));
                mb.Cone(Vector3.up * h, 0.22f, 0.5f, 5, Color.Lerp(c, Color.white, 0.5f));
                mb.Pop();
            }
            mb.Pop();
        }

        public static void Column(MeshBuilder mb, Vector3 p, System.Random rng, Color marble)
        {
            float h = R(rng, 1.5f, 5f);
            bool broken = rng.NextDouble() < 0.5;
            mb.Box(p + new Vector3(0, 0.2f, 0), new Vector3(1.4f, 0.4f, 1.4f), MeshBuilder.Shade(marble, 0.9f));
            mb.Cylinder(p + new Vector3(0, 0.4f, 0), 0.5f, 0.45f, h, 10, marble);
            if (!broken) mb.Box(p + new Vector3(0, 0.4f + h + 0.15f, 0), new Vector3(1.3f, 0.3f, 1.3f), MeshBuilder.Shade(marble, 0.95f));
            else mb.Box(p + new Vector3(R(rng, 0.6f, 1.2f), 0.3f, R(rng, -0.6f, 0.6f)), new Vector3(0.8f, 0.6f, 0.8f), Quaternion.Euler(0, R(rng, 0, 90), 70f), marble);
            if (rng.NextDouble() < 0.4) mb.Sphere(p + new Vector3(0.4f, 0.4f, 0.3f), new Vector3(0.6f, 0.5f, 0.6f), new Color(0.3f, 0.6f, 0.4f), 5, 3); // seaweed
        }

        public static void Cloud(MeshBuilder mb, Vector3 p, System.Random rng)
        {
            float s = R(rng, 1f, 2.2f);
            mb.Push(p, Quaternion.Euler(0, R(rng, 0, 360), 0), Vector3.one * s);
            int n = rng.Next(3, 6);
            for (int i = 0; i < n; i++)
                mb.Sphere(new Vector3(i * 2.2f - n, R(rng, -0.3f, 0.6f), R(rng, -1f, 1f)), new Vector3(R(rng, 3f, 4.5f), R(rng, 2f, 3f), R(rng, 2.5f, 3.5f)), Color.white, 7, 4);
            mb.Pop();
        }
    }
}
