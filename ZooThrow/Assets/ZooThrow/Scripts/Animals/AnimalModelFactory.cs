using System.Collections.Generic;
using UnityEngine;
using ZooThrow.Data;
using ZooThrow.Visuals;
using F = ZooThrow.Data.AnimalFeatures;

namespace ZooThrow.Animals
{
    public enum LimbKind { Leg, Arm, Wing }

    public class LimbSpec
    {
        public Mesh mesh;
        public Vector3 pivot;
        public LimbKind kind;
        /// <summary>Phase offset in radians for the gait cycle.</summary>
        public float phase;
        /// <summary>+1 right side, -1 left side (wings mirror their flap).</summary>
        public float side;
    }

    public class AnimalModel
    {
        public Mesh body;
        public readonly List<LimbSpec> limbs = new List<LimbSpec>();
        public float height;
        public float length;
    }

    /// <summary>
    /// Procedural low-poly animals assembled from boxes, spheres and cones. One body mesh per species plus
    /// separate limb meshes so legs and wings can be animated. Results are cached per species id.
    /// </summary>
    public static class AnimalModelFactory
    {
        static readonly Dictionary<string, AnimalModel> s_Cache = new Dictionary<string, AnimalModel>();
        static readonly Color Black = new Color(0.08f, 0.08f, 0.1f);
        static readonly Color White = new Color(0.98f, 0.98f, 0.98f);

        public static AnimalModel Get(AnimalData data)
        {
            if (s_Cache.TryGetValue(data.id, out var m)) return m;
            m = Build(data.id, data.model);
            s_Cache[data.id] = m;
            return m;
        }

        public static void ClearCache()
        {
            foreach (var m in s_Cache.Values)
            {
                if (m.body != null) Object.Destroy(m.body);
                foreach (var l in m.limbs) if (l.mesh != null) Object.Destroy(l.mesh);
            }
            s_Cache.Clear();
        }

        static AnimalModel Build(string id, AnimalModelSpec s)
        {
            var model = new AnimalModel();
            var mb = new MeshBuilder();
            var rng = new System.Random(StableHash(id));
            switch (s.plan)
            {
                case BodyPlan.Bird: BuildBird(mb, model, s); break;
                case BodyPlan.Frog: BuildFrog(mb, model, s); break;
                case BodyPlan.Snail: BuildSnail(mb, model, s); break;
                case BodyPlan.Fish: BuildFish(mb, model, s); break;
                case BodyPlan.Snake: BuildSnake(mb, model, s); break;
                case BodyPlan.Bug: BuildBug(mb, model, s); break;
                case BodyPlan.Ape: BuildApe(mb, model, s, rng); break;
                case BodyPlan.Octopus: BuildOctopus(mb, model, s); break;
                case BodyPlan.Turtle: BuildTurtle(mb, model, s, rng); break;
                case BodyPlan.Dragon: BuildQuadruped(mb, model, s, rng, true); break;
                default: BuildQuadruped(mb, model, s, rng, false); break;
            }
            model.body = mb.ToMesh("Animal_" + id);
            var bounds = model.body.bounds;
            model.height = Mathf.Max(bounds.max.y, 0.3f);
            model.length = bounds.size.z;
            return model;
        }

        static int StableHash(string s)
        {
            unchecked
            {
                int h = 23;
                foreach (char c in s) h = h * 31 + c;
                return h;
            }
        }

        // ------------------------------------------------------------------ shared details

        static void Eyes(MeshBuilder mb, Vector3 headCenter, float headSize, float frontZ, float spacing, float eyeSize, bool big = false)
        {
            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 p = headCenter + new Vector3(side * spacing, headSize * 0.12f, frontZ);
                if (big)
                {
                    mb.Sphere(p, eyeSize * 1.6f, White, 6, 4);
                    mb.Sphere(p + new Vector3(0, 0, eyeSize * 0.55f), eyeSize * 0.9f, Black, 6, 4);
                }
                else
                {
                    mb.Box(p, new Vector3(eyeSize, eyeSize * 1.25f, eyeSize * 0.5f), Black);
                    mb.Box(p + new Vector3(side * -eyeSize * 0.18f, eyeSize * 0.25f, eyeSize * 0.2f), Vector3.one * eyeSize * 0.35f, White);
                }
            }
        }

        static void Ears(MeshBuilder mb, AnimalModelSpec s, Vector3 headCenter, float headSize)
        {
            float e = Mathf.Max(0.05f, s.earSize);
            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 basePos = headCenter + new Vector3(side * headSize * 0.32f, headSize * 0.45f, -headSize * 0.1f);
                if ((s.features & F.LongEars) != 0)
                {
                    mb.Box(basePos + new Vector3(side * 0.02f, e * 0.5f, 0), new Vector3(headSize * 0.22f, e, headSize * 0.12f), Quaternion.Euler(-8f, 0, side * -10f), s.primary);
                    mb.Box(basePos + new Vector3(side * 0.02f, e * 0.5f, headSize * 0.04f), new Vector3(headSize * 0.12f, e * 0.8f, headSize * 0.06f), Quaternion.Euler(-8f, 0, side * -10f), s.secondary);
                }
                else if ((s.features & F.PointyEars) != 0)
                {
                    mb.Push(basePos, Quaternion.Euler(0, 0, side * -12f));
                    mb.Box(new Vector3(0, e * 0.5f, 0), new Vector3(headSize * 0.3f, e, headSize * 0.14f), s.primary, 0.08f);
                    mb.Box(new Vector3(0, e * 0.42f, headSize * 0.05f), new Vector3(headSize * 0.16f, e * 0.75f, headSize * 0.06f), s.secondary, 0.08f);
                    mb.Pop();
                }
                else if ((s.features & F.RoundEars) != 0)
                {
                    mb.Sphere(basePos + new Vector3(side * e * 0.2f, e * 0.25f, 0), new Vector3(e * 1.1f, e * 1.1f, e * 0.35f), s.primary, 8, 4);
                    mb.Sphere(basePos + new Vector3(side * e * 0.2f, e * 0.25f, e * 0.1f), new Vector3(e * 0.6f, e * 0.6f, e * 0.2f), s.secondary, 6, 3);
                }
            }
        }

        static void HeadExtras(MeshBuilder mb, AnimalModelSpec s, Vector3 head, float hs)
        {
            if ((s.features & F.Horns) != 0)
            {
                Color hc = Color.Lerp(s.accent, White, 0.5f);
                for (int side = -1; side <= 1; side += 2)
                {
                    mb.Push(head + new Vector3(side * hs * 0.25f, hs * 0.45f, -hs * 0.05f), Quaternion.Euler(-15f, 0, side * -25f));
                    mb.Cone(Vector3.zero, hs * 0.1f, hs * 0.45f, 6, hc);
                    mb.Pop();
                }
            }
            if ((s.features & F.SingleHorn) != 0)
            {
                mb.Push(head + new Vector3(0, hs * 0.45f, hs * 0.25f), Quaternion.Euler(35f, 0, 0));
                mb.Cone(Vector3.zero, hs * 0.11f, hs * 0.8f, 6, s.accent);
                mb.Pop();
            }
            if ((s.features & F.Halo) != 0)
            {
                Vector3 c = head + new Vector3(0, hs * 0.95f, 0);
                for (int i = 0; i < 12; i++)
                {
                    float a = i * Mathf.PI * 2f / 12f;
                    mb.Box(c + new Vector3(Mathf.Cos(a), 0, Mathf.Sin(a)) * hs * 0.45f, new Vector3(hs * 0.14f, hs * 0.06f, hs * 0.14f), Quaternion.Euler(0, -a * Mathf.Rad2Deg, 0), new Color(1f, 0.88f, 0.3f));
                }
            }
            if ((s.features & F.Whiskers) != 0)
            {
                for (int side = -1; side <= 1; side += 2)
                    for (int k = 0; k < 2; k++)
                        mb.Box(head + new Vector3(side * hs * 0.45f, -hs * (0.08f + k * 0.09f), hs * 0.5f), new Vector3(hs * 0.4f, 0.012f, 0.012f), Quaternion.Euler(0, 0, side * (k == 0 ? 6f : -6f)), Black);
            }
            if ((s.features & F.Crest) != 0)
            {
                for (int i = 0; i < 3; i++)
                {
                    mb.Push(head + new Vector3(0, hs * 0.4f, -hs * 0.15f * i), Quaternion.Euler(-25f - i * 15f, 0, 0));
                    mb.Box(new Vector3(0, hs * 0.2f, 0), new Vector3(hs * 0.08f, hs * 0.45f, hs * 0.18f), s.accent, 0.3f);
                    mb.Pop();
                }
            }
        }

        static void Tail(MeshBuilder mb, AnimalModelSpec s, Vector3 attach, bool fluffy)
        {
            if (s.tailLength <= 0.01f) return;
            float t = s.tailLength;
            mb.Push(attach, Quaternion.Euler(-35f, 0, 0));
            mb.Box(new Vector3(0, 0, -t * 0.5f), new Vector3(0.08f + s.bodyWidth * 0.08f, 0.08f + s.bodyWidth * 0.08f, t), s.primary);
            if (fluffy) mb.Sphere(new Vector3(0, 0, -t), Vector3.one * Mathf.Max(0.18f, t * 0.45f), (s.features & F.LongEars) != 0 ? White : Color.Lerp(s.primary, s.secondary, 0.5f), 7, 4);
            mb.Pop();
        }

        static Mesh LegMesh(float width, float length, Color col, Color foot)
        {
            var mb = new MeshBuilder();
            mb.Box(new Vector3(0, -length * 0.45f, 0), new Vector3(width, length * 0.9f, width), col, 0.95f);
            mb.Box(new Vector3(0, -length * 0.95f, width * 0.08f), new Vector3(width * 1.1f, length * 0.12f, width * 1.25f), foot);
            return mb.ToMesh("Leg");
        }

        static Mesh WingMesh(float span, float chord, Color col, Color tip)
        {
            var mb = new MeshBuilder();
            // Built for the right wing (+X); the left wing uses a mirrored transform.
            mb.Box(new Vector3(span * 0.35f, 0, 0), new Vector3(span * 0.7f, 0.05f, chord), col);
            mb.Box(new Vector3(span * 0.8f, 0, -chord * 0.1f), new Vector3(span * 0.4f, 0.04f, chord * 0.75f), tip);
            return mb.ToMesh("Wing");
        }

        static void AddLegs(AnimalModel model, Mesh leg, float halfW, float frontZ, float backZ, float hipY)
        {
            model.limbs.Add(new LimbSpec { mesh = leg, pivot = new Vector3(-halfW, hipY, frontZ), kind = LimbKind.Leg, phase = 0f, side = -1 });
            model.limbs.Add(new LimbSpec { mesh = leg, pivot = new Vector3(halfW, hipY, frontZ), kind = LimbKind.Leg, phase = Mathf.PI, side = 1 });
            model.limbs.Add(new LimbSpec { mesh = leg, pivot = new Vector3(-halfW, hipY, backZ), kind = LimbKind.Leg, phase = Mathf.PI, side = -1 });
            model.limbs.Add(new LimbSpec { mesh = leg, pivot = new Vector3(halfW, hipY, backZ), kind = LimbKind.Leg, phase = 0f, side = 1 });
        }

        static void AddWings(AnimalModel model, Mesh wing, float halfW, float y, float z)
        {
            model.limbs.Add(new LimbSpec { mesh = wing, pivot = new Vector3(halfW, y, z), kind = LimbKind.Wing, side = 1 });
            model.limbs.Add(new LimbSpec { mesh = wing, pivot = new Vector3(-halfW, y, z), kind = LimbKind.Wing, side = -1 });
        }

        // ------------------------------------------------------------------ body plans

        static void BuildQuadruped(MeshBuilder mb, AnimalModel model, AnimalModelSpec s, System.Random rng, bool dragon)
        {
            float L = s.bodyLength, H = s.bodyHeight, W = s.bodyWidth, leg = s.legLength, hs = s.headSize;
            float bodyY = leg + H * 0.5f;
            Vector3 bodyC = new Vector3(0, bodyY, 0);
            mb.Box(bodyC, new Vector3(W, H, L), s.primary, 0.88f);
            // Belly
            mb.Box(bodyC + new Vector3(0, -H * 0.32f, 0), new Vector3(W * 0.8f, H * 0.4f, L * 0.8f), Color.Lerp(s.primary, s.secondary, (s.features & (F.Stripes | F.Spots)) != 0 ? 0f : 0.6f));

            if ((s.features & F.Fluffy) != 0)
            {
                Color wool = Color.Lerp(s.primary, White, 0.35f);
                for (int i = 0; i < 10; i++)
                {
                    float a = i * Mathf.PI * 2f / 10f;
                    mb.Sphere(bodyC + new Vector3(Mathf.Cos(a) * W * 0.45f, Mathf.Abs(Mathf.Sin(a)) * H * 0.35f, (i % 3 - 1) * L * 0.3f), Vector3.one * H * 0.55f, wool, 6, 4);
                }
            }
            if ((s.features & F.Stripes) != 0)
            {
                int n = Mathf.Max(4, Mathf.RoundToInt(L * 6f));
                for (int i = 0; i < n; i++)
                {
                    float z = -L * 0.42f + i * (L * 0.84f / (n - 1));
                    mb.Box(bodyC + new Vector3(0, H * 0.08f, z), new Vector3(W * 1.02f, H * 0.86f, L * 0.05f), s.secondary, 0.88f);
                }
            }
            if ((s.features & F.Spots) != 0)
            {
                for (int i = 0; i < 9; i++)
                {
                    float z = ((float)rng.NextDouble() - 0.5f) * L * 0.8f;
                    float y = ((float)rng.NextDouble() - 0.2f) * H * 0.5f;
                    float side = rng.NextDouble() < 0.5 ? -1f : 1f;
                    float sz = 0.08f + (float)rng.NextDouble() * 0.12f;
                    mb.Box(bodyC + new Vector3(side * (W * 0.5f), y, z), new Vector3(0.04f, sz, sz * 1.3f), s.secondary);
                    if (i % 3 == 0) mb.Box(bodyC + new Vector3(((float)rng.NextDouble() - 0.5f) * W * 0.6f, H * 0.5f, z), new Vector3(sz, 0.04f, sz * 1.2f), s.secondary);
                }
            }
            if ((s.features & F.Hump) != 0)
            {
                mb.Sphere(bodyC + new Vector3(0, H * 0.5f, -L * 0.05f), new Vector3(W * 0.75f, H * 0.8f, L * 0.45f), s.secondary, 8, 5);
            }
            if ((s.features & F.Spikes) != 0)
            {
                int n = Mathf.Max(4, Mathf.RoundToInt(L * 5f));
                for (int i = 0; i < n; i++)
                {
                    float z = -L * 0.45f + i * (L * 0.9f / (n - 1));
                    if ((s.features & F.Snout) != 0 && s.bodyHeight > 0.4f)
                    {
                        // Hedgehog: spines all over the back
                        for (int k = -1; k <= 1; k++)
                        {
                            mb.Push(bodyC + new Vector3(k * W * 0.3f, H * 0.42f, z), Quaternion.Euler(-40f, 0, k * -35f));
                            mb.Cone(Vector3.zero, 0.06f, 0.28f, 4, MeshBuilder.Shade(s.primary, 0.7f));
                            mb.Pop();
                        }
                    }
                    else
                    {
                        mb.Push(bodyC + new Vector3(0, H * 0.48f, z), Quaternion.Euler(-15f, 0, 0));
                        mb.Cone(Vector3.zero, Mathf.Max(0.05f, H * 0.18f), Mathf.Max(0.1f, H * 0.35f), 4, dragon ? s.accent : s.secondary);
                        mb.Pop();
                    }
                }
            }

            // Neck and head
            Vector3 neckBase = new Vector3(0, bodyY + H * 0.3f, L * 0.42f);
            float neck = s.neckLength;
            Vector3 head;
            if (neck > 0.05f)
            {
                Quaternion tilt = Quaternion.Euler(-25f, 0, 0);
                Vector3 neckDir = tilt * Vector3.up;
                mb.Box(neckBase + neckDir * neck * 0.5f, new Vector3(Mathf.Max(0.15f, W * 0.42f), neck + 0.1f, Mathf.Max(0.15f, W * 0.45f)), tilt, s.primary);
                if ((s.features & F.Spots) != 0 && (s.features & F.LongNeck) != 0)
                    for (int i = 1; i < 4; i++)
                        mb.Box(neckBase + neckDir * neck * (i / 4f) + new Vector3(0, 0, W * 0.23f), new Vector3(W * 0.2f, 0.12f, 0.03f), tilt, s.secondary);
                if ((s.features & F.Mane) != 0)
                    mb.Box(neckBase + neckDir * neck * 0.5f + new Vector3(0, 0, -W * 0.22f), new Vector3(0.08f, neck + 0.05f, 0.12f), tilt, s.secondary);
                head = neckBase + neckDir * neck + new Vector3(0, hs * 0.2f, hs * 0.25f);
            }
            else
            {
                head = new Vector3(0, bodyY + H * 0.2f, L * 0.5f + hs * 0.3f);
            }
            mb.Box(head, new Vector3(hs, hs * 0.9f, hs * 1.0f), s.primary, 0.9f);
            bool snout = (s.features & (F.Snout | F.Trunk)) != 0;
            if (snout)
            {
                float snoutLen = s.bodyHeight < 0.4f ? hs * 0.9f : hs * 0.45f; // crocodiles/lizards get long jaws
                mb.Box(head + new Vector3(0, -hs * 0.15f, hs * 0.5f + snoutLen * 0.4f), new Vector3(hs * 0.6f, hs * 0.45f, snoutLen), Color.Lerp(s.primary, s.secondary, 0.5f), 0.9f);
                mb.Box(head + new Vector3(0, -hs * 0.02f, hs * 0.5f + snoutLen * 0.85f), new Vector3(hs * 0.2f, hs * 0.14f, hs * 0.1f), Black);
                if (s.bodyHeight < 0.4f && (s.features & F.Spikes) != 0)
                    for (int i = 0; i < 4; i++)
                        for (int side = -1; side <= 1; side += 2)
                            mb.Box(head + new Vector3(side * hs * 0.26f, -hs * 0.3f, hs * 0.55f + i * snoutLen * 0.22f), new Vector3(0.03f, 0.06f, 0.03f), White);
            }
            else
            {
                mb.Box(head + new Vector3(0, -hs * 0.05f, hs * 0.5f), new Vector3(hs * 0.18f, hs * 0.12f, hs * 0.08f), s.accent == Black ? Black : Color.Lerp(s.accent, Black, 0.3f));
            }
            Eyes(mb, head, hs, hs * 0.5f, hs * 0.27f, hs * 0.14f);
            Ears(mb, s, head, hs);
            HeadExtras(mb, s, head, hs);
            if ((s.features & F.Mane) != 0 && (s.features & F.Halo) == 0 && neck < 0.3f)
            {
                // Big lion mane ring around the head
                for (int i = 0; i < 12; i++)
                {
                    float a = i * Mathf.PI * 2f / 12f;
                    mb.Sphere(head + new Vector3(Mathf.Cos(a) * hs * 0.6f, Mathf.Sin(a) * hs * 0.6f, -hs * 0.25f), Vector3.one * hs * 0.55f, s.secondary, 6, 4);
                }
            }
            else if ((s.features & F.Mane) != 0 && (s.features & F.Halo) != 0)
            {
                // Unicorn mane: coloured tufts behind the head
                Color[] cols = { new Color(1f, 0.5f, 0.8f), new Color(0.6f, 0.7f, 1f), new Color(0.6f, 1f, 0.8f) };
                for (int i = 0; i < 3; i++) mb.Box(head + new Vector3(0, hs * 0.2f - i * hs * 0.3f, -hs * 0.55f), new Vector3(0.1f, hs * 0.35f, 0.18f), cols[i]);
            }
            if ((s.features & F.Trunk) != 0)
            {
                Vector3 p = head + new Vector3(0, -hs * 0.1f, hs * 0.55f);
                for (int i = 0; i < 5; i++)
                {
                    float w = hs * (0.3f - i * 0.03f);
                    mb.Box(p, new Vector3(w, hs * 0.25f, w), Quaternion.Euler(i * 12f, 0, 0), s.primary);
                    p += Quaternion.Euler(i * 14f, 0, 0) * new Vector3(0, -hs * 0.22f, hs * 0.08f);
                }
            }
            if ((s.features & F.Tusks) != 0)
                for (int side = -1; side <= 1; side += 2)
                {
                    mb.Push(head + new Vector3(side * hs * 0.22f, -hs * 0.35f, hs * 0.45f), Quaternion.Euler(70f, 0, 0));
                    mb.Cone(Vector3.zero, hs * 0.07f, hs * 0.5f, 5, s.accent);
                    mb.Pop();
                }

            Tail(mb, s, new Vector3(0, bodyY + H * 0.25f, -L * 0.5f), (s.features & F.FluffyTail) != 0);

            if (dragon)
            {
                var wing = WingMesh(L * 1.1f, L * 0.5f, s.accent, s.secondary);
                AddWings(model, wing, W * 0.4f, bodyY + H * 0.4f, L * 0.1f);
                // Ice crystals on the tail tip
                mb.Push(new Vector3(0, bodyY, -L * 0.5f - s.tailLength * 0.9f), Quaternion.Euler(-60f, 0, 0));
                mb.Cone(Vector3.zero, 0.12f, 0.35f, 4, s.secondary);
                mb.Pop();
            }

            if (leg > 0.01f)
            {
                float legW = Mathf.Clamp(W * 0.28f, 0.08f, 0.35f);
                var legMesh = LegMesh(legW, leg + H * 0.15f, s.primary, Color.Lerp(s.primary, Black, 0.45f));
                AddLegs(model, legMesh, W * 0.5f - legW * 0.5f, L * 0.38f - legW * 0.5f, -L * 0.38f + legW * 0.5f, leg + H * 0.15f);
            }
        }

        static void BuildBird(MeshBuilder mb, AnimalModel model, AnimalModelSpec s)
        {
            float L = s.bodyLength, H = s.bodyHeight, W = s.bodyWidth, leg = s.legLength, hs = s.headSize;
            bool upright = (s.features & F.PointyEars) != 0; // owls sit upright
            float bodyY = leg + H * 0.5f;
            Vector3 bodyC = new Vector3(0, bodyY, 0);
            mb.Sphere(bodyC, new Vector3(W, H, L), s.primary, 10, 6);
            mb.Sphere(bodyC + new Vector3(0, -H * 0.05f, L * 0.22f), new Vector3(W * 0.75f, H * 0.75f, L * 0.55f), s.secondary, 8, 5);
            Vector3 head;
            if ((s.features & F.LongNeck) != 0)
            {
                mb.Box(bodyC + new Vector3(0, H * 0.4f + s.neckLength * 0.5f, L * 0.3f), new Vector3(0.12f, s.neckLength, 0.12f), Quaternion.Euler(10f, 0, 0), Color.Lerp(s.accent, s.secondary, 0.3f));
                head = bodyC + new Vector3(0, H * 0.4f + s.neckLength + hs * 0.3f, L * 0.38f);
            }
            else if (upright)
            {
                head = bodyC + new Vector3(0, H * 0.5f + hs * 0.25f, L * 0.05f);
            }
            else
            {
                head = bodyC + new Vector3(0, H * 0.35f + hs * 0.2f, L * 0.42f);
            }
            mb.Sphere(head, Vector3.one * hs, (s.features & F.LongNeck) != 0 ? Color.Lerp(s.accent, s.secondary, 0.3f) : s.primary, 8, 5);
            if (upright) mb.Sphere(head + new Vector3(0, -hs * 0.05f, hs * 0.3f), new Vector3(hs * 0.85f, hs * 0.7f, hs * 0.35f), s.secondary, 8, 4);
            mb.Push(head + new Vector3(0, -hs * 0.05f, hs * 0.45f), Quaternion.Euler(upright ? 120f : 95f, 0, 0));
            mb.Cone(Vector3.zero, hs * 0.16f, hs * (upright ? 0.3f : 0.5f), 5, s.accent);
            mb.Pop();
            Eyes(mb, head, hs, hs * 0.42f, hs * 0.22f, hs * (upright ? 0.2f : 0.13f), upright);
            if (upright)
                for (int side = -1; side <= 1; side += 2)
                {
                    mb.Push(head + new Vector3(side * hs * 0.3f, hs * 0.42f, 0), Quaternion.Euler(0, 0, side * -20f));
                    mb.Box(new Vector3(0, hs * 0.15f, 0), new Vector3(hs * 0.2f, hs * 0.35f, hs * 0.12f), s.primary, 0.1f);
                    mb.Pop();
                }
            HeadExtras(mb, s, head, hs);
            // Tail feathers
            float t = Mathf.Max(0.15f, s.tailLength);
            for (int i = -1; i <= 1; i++)
            {
                mb.Push(bodyC + new Vector3(i * W * 0.12f, H * 0.05f, -L * 0.45f), Quaternion.Euler(upright ? 45f : -15f, i * 18f, 0));
                mb.Box(new Vector3(0, 0, -t * 0.5f), new Vector3(W * 0.2f, 0.04f, t), i == 0 ? s.accent : s.primary, 1f);
                mb.Pop();
            }
            if ((s.features & F.Fire) != 0)
            {
                Color[] flame = { new Color(1f, 0.85f, 0.2f), new Color(1f, 0.45f, 0.1f), new Color(1f, 0.2f, 0.15f) };
                for (int i = 0; i < 7; i++)
                {
                    mb.Push(bodyC + new Vector3((i - 3) * W * 0.12f, H * 0.2f, -L * 0.5f - (i % 2) * 0.1f), Quaternion.Euler(-60f + (i % 3) * 10f, (i - 3) * 10f, 0));
                    mb.Cone(Vector3.zero, 0.08f, 0.45f + (i % 3) * 0.12f, 4, flame[i % 3]);
                    mb.Pop();
                }
            }
            if ((s.features & F.Wings) != 0)
            {
                var wing = WingMesh(L * 0.8f, L * 0.5f, s.primary, (s.features & F.Fire) != 0 ? s.secondary : Color.Lerp(s.primary, s.accent, 0.35f));
                AddWings(model, wing, W * 0.42f, bodyY + H * 0.15f, 0f);
            }
            else
            {
                for (int side = -1; side <= 1; side += 2)
                    mb.Sphere(bodyC + new Vector3(side * W * 0.45f, H * 0.05f, 0), new Vector3(W * 0.2f, H * 0.5f, L * 0.7f), s.primary, 6, 4);
            }
            if (leg > 0.01f)
            {
                var legMesh = LegMesh(Mathf.Max(0.05f, W * 0.08f), leg + H * 0.1f, s.accent, s.accent);
                model.limbs.Add(new LimbSpec { mesh = legMesh, pivot = new Vector3(-W * 0.2f, leg + H * 0.1f, 0), kind = LimbKind.Leg, phase = 0, side = -1 });
                model.limbs.Add(new LimbSpec { mesh = legMesh, pivot = new Vector3(W * 0.2f, leg + H * 0.1f, 0), kind = LimbKind.Leg, phase = Mathf.PI, side = 1 });
            }
        }

        static void BuildFrog(MeshBuilder mb, AnimalModel model, AnimalModelSpec s)
        {
            float L = s.bodyLength, H = s.bodyHeight, W = s.bodyWidth;
            Vector3 c = new Vector3(0, H * 0.5f, 0);
            mb.Sphere(c, new Vector3(W, H, L), s.primary, 10, 6);
            mb.Sphere(c + new Vector3(0, -H * 0.15f, L * 0.15f), new Vector3(W * 0.8f, H * 0.65f, L * 0.7f), s.secondary, 8, 5);
            Vector3 head = c + new Vector3(0, H * 0.35f, L * 0.25f);
            Eyes(mb, head, s.headSize, 0f, W * 0.28f, s.headSize * 0.28f, true);
            mb.Box(head + new Vector3(0, -H * 0.25f, L * 0.24f), new Vector3(W * 0.5f, 0.025f, 0.03f), Black);
            for (int side = -1; side <= 1; side += 2)
            {
                mb.Sphere(c + new Vector3(side * W * 0.45f, -H * 0.25f, -L * 0.2f), new Vector3(W * 0.35f, H * 0.4f, L * 0.55f), s.primary, 6, 4);
                mb.Box(new Vector3(side * W * 0.5f, 0.03f, -L * 0.05f), new Vector3(W * 0.3f, 0.06f, L * 0.3f), s.primary);
                mb.Box(new Vector3(side * W * 0.3f, 0.03f, L * 0.4f), new Vector3(W * 0.18f, 0.06f, L * 0.18f), s.primary);
            }
            // tiny crown spot for flair
            mb.Sphere(c + new Vector3(0, H * 0.5f, -L * 0.1f), new Vector3(W * 0.25f, 0.05f, L * 0.25f), s.accent, 6, 3);
        }

        static void BuildSnail(MeshBuilder mb, AnimalModel model, AnimalModelSpec s)
        {
            float L = s.bodyLength, H = s.bodyHeight, W = s.bodyWidth;
            mb.Box(new Vector3(0, H * 0.3f, 0), new Vector3(W, H * 0.6f, L), s.primary, 0.8f);
            mb.Sphere(new Vector3(0, H * 0.45f, L * 0.48f), new Vector3(W * 0.95f, H * 1.3f, W * 0.9f), s.primary, 8, 5);
            Vector3 shellC = new Vector3(0, H * 0.6f + L * 0.3f, -L * 0.08f);
            mb.Sphere(shellC, new Vector3(W * 0.95f, L * 0.7f, L * 0.7f), s.secondary, 10, 6);
            mb.Sphere(shellC + new Vector3(W * 0.12f, L * 0.05f, L * 0.05f), new Vector3(W * 0.98f, L * 0.42f, L * 0.42f), Color.Lerp(s.secondary, White, 0.25f), 8, 5);
            mb.Sphere(shellC + new Vector3(W * 0.2f, L * 0.08f, L * 0.08f), new Vector3(W, L * 0.2f, L * 0.2f), s.secondary, 6, 4);
            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 p = new Vector3(side * W * 0.22f, H * 0.8f, L * 0.55f);
                mb.Push(p, Quaternion.Euler(20f, 0, side * -15f));
                mb.Cylinder(Vector3.zero, 0.03f, 0.03f, H * 1.1f, 5, s.primary, false);
                mb.Sphere(new Vector3(0, H * 1.15f, 0), 0.12f, White, 6, 4);
                mb.Sphere(new Vector3(0, H * 1.15f, 0.05f), 0.07f, Black, 6, 4);
                mb.Pop();
            }
            mb.Box(new Vector3(0, H * 0.3f, L * 0.72f), new Vector3(W * 0.35f, 0.025f, 0.03f), Black);
        }

        static void BuildFish(MeshBuilder mb, AnimalModel model, AnimalModelSpec s)
        {
            float L = s.bodyLength, H = s.bodyHeight, W = s.bodyWidth, hs = s.headSize;
            float y = H * 0.5f + 0.05f;
            Vector3 c = new Vector3(0, y, 0);
            mb.Sphere(c, new Vector3(W, H, L), s.primary, 10, 6);
            mb.Sphere(c + new Vector3(0, -H * 0.18f, L * 0.05f), new Vector3(W * 0.85f, H * 0.65f, L * 0.85f), s.secondary, 8, 5);
            if ((s.features & F.Snout) != 0)
                mb.Box(c + new Vector3(0, -H * 0.1f, L * 0.52f), new Vector3(W * 0.3f, H * 0.2f, L * 0.18f), s.primary, 0.8f);
            Eyes(mb, c + new Vector3(0, H * 0.05f, L * 0.3f), hs, 0f, W * 0.42f, Mathf.Max(0.06f, hs * 0.14f));
            bool shark = (s.features & F.Crest) != 0;
            if (shark)
            {
                for (int i = 0; i < 5; i++)
                    mb.Box(c + new Vector3((i - 2) * W * 0.09f, -H * 0.22f, L * 0.42f), new Vector3(0.04f, 0.07f, 0.03f), White, 0.2f);
            }
            if ((s.features & F.Fins) != 0)
            {
                // dorsal
                mb.Push(c + new Vector3(0, H * 0.45f, -L * 0.02f), Quaternion.Euler(-20f, 0, 0));
                mb.Box(new Vector3(0, H * (shark ? 0.3f : 0.2f), 0), new Vector3(0.05f, H * (shark ? 0.6f : 0.4f), L * 0.25f), s.primary, 0.15f);
                mb.Pop();
                for (int side = -1; side <= 1; side += 2)
                {
                    mb.Push(c + new Vector3(side * W * 0.45f, -H * 0.2f, L * 0.12f), Quaternion.Euler(20f, 0, side * -50f));
                    mb.Box(new Vector3(side * L * 0.1f, 0, 0), new Vector3(L * 0.2f, 0.04f, L * 0.13f), s.primary);
                    mb.Pop();
                }
            }
            // tail fluke
            for (int side = -1; side <= 1; side += 2)
            {
                mb.Push(c + new Vector3(0, 0, -L * 0.48f), Quaternion.Euler(0, 0, 0));
                if (shark || W < 0.6f && (s.features & F.Snout) == 0)
                    mb.Box(new Vector3(0, side * H * 0.25f, -L * 0.08f), new Vector3(0.05f, H * 0.5f, L * 0.18f), Quaternion.Euler(side * 30f, 0, 0), s.primary, 0.4f);
                else
                    mb.Box(new Vector3(side * W * 0.3f, 0, -L * 0.08f), new Vector3(W * 0.6f, 0.05f, L * 0.18f), Quaternion.Euler(0, side * 25f, 0), s.primary, 0.6f);
                mb.Pop();
            }
            if (s.bodyLength > 1.8f)
            {
                // whale: belly grooves and a blowhole spout
                for (int i = 0; i < 4; i++) mb.Box(c + new Vector3(0, -H * 0.48f, L * (0.25f - i * 0.1f)), new Vector3(W * 0.6f, 0.03f, 0.04f), Color.Lerp(s.secondary, s.accent, 0.3f));
                mb.Cylinder(c + new Vector3(0, H * 0.45f, L * 0.15f), 0.05f, 0.12f, 0.35f, 6, new Color(0.75f, 0.9f, 1f));
            }
        }

        static void BuildSnake(MeshBuilder mb, AnimalModel model, AnimalModelSpec s)
        {
            float W = s.bodyWidth;
            Vector3 p = new Vector3(0, W * 0.4f, -s.bodyLength * 0.5f);
            for (int i = 0; i < 8; i++)
            {
                float x = Mathf.Sin(i * 0.9f) * W * 0.6f;
                mb.Sphere(new Vector3(x, W * 0.35f, p.z + i * s.bodyLength / 8f), new Vector3(W * 0.7f, W * 0.65f, s.bodyLength / 6f), i % 2 == 0 ? s.primary : s.secondary, 6, 4);
            }
            Vector3 head = new Vector3(Mathf.Sin(8 * 0.9f) * W * 0.6f, W * 0.5f, s.bodyLength * 0.55f);
            mb.Box(head, new Vector3(s.headSize, s.headSize * 0.6f, s.headSize * 1.1f), s.primary, 0.85f);
            Eyes(mb, head, s.headSize, s.headSize * 0.4f, s.headSize * 0.3f, s.headSize * 0.15f);
        }

        static void BuildBug(MeshBuilder mb, AnimalModel model, AnimalModelSpec s)
        {
            float L = s.bodyLength, H = s.bodyHeight, W = s.bodyWidth, leg = s.legLength;
            float y = leg + H * 0.5f;
            Vector3 c = new Vector3(0, y, 0);
            bool crab = (s.features & F.Stinger) == 0 && (s.features & F.Pincers) != 0;
            mb.Sphere(c, new Vector3(W, H, L), s.primary, 10, 6);
            mb.Sphere(c + new Vector3(0, H * 0.15f, 0), new Vector3(W * 0.8f, H * 0.6f, L * 0.8f), Color.Lerp(s.primary, s.secondary, 0.35f), 8, 4);
            if ((s.features & F.Halo) != 0)
            {
                // scarab shell split line and gem
                mb.Box(c + new Vector3(0, H * 0.48f, -L * 0.05f), new Vector3(0.03f, 0.03f, L * 0.75f), s.accent);
                mb.Sphere(c + new Vector3(0, H * 0.5f, L * 0.25f), 0.14f, s.secondary, 6, 4);
            }
            Vector3 head = c + new Vector3(0, 0, L * 0.48f);
            if (crab)
            {
                for (int side = -1; side <= 1; side += 2)
                {
                    mb.Cylinder(c + new Vector3(side * W * 0.18f, H * 0.3f, L * 0.3f), 0.025f, 0.025f, 0.25f, 5, s.primary, false);
                    mb.Sphere(c + new Vector3(side * W * 0.18f, H * 0.3f + 0.27f, L * 0.3f), 0.1f, White, 6, 4);
                    mb.Sphere(c + new Vector3(side * W * 0.18f, H * 0.3f + 0.27f, L * 0.34f), 0.055f, Black, 6, 4);
                }
                mb.Box(c + new Vector3(0, -H * 0.05f, L * 0.48f), new Vector3(W * 0.2f, 0.025f, 0.03f), Black);
            }
            else
            {
                mb.Sphere(head, new Vector3(W * 0.5f, H * 0.7f, L * 0.3f), s.primary, 8, 4);
                Eyes(mb, head, s.headSize, L * 0.12f, W * 0.14f, 0.06f);
            }
            // six static legs
            for (int side = -1; side <= 1; side += 2)
                for (int i = 0; i < 3; i++)
                {
                    float z = (i - 1) * L * 0.28f;
                    mb.Push(new Vector3(side * W * 0.42f, y, z), Quaternion.Euler(0, side * (i - 1) * -20f, side * -55f));
                    mb.Box(new Vector3(0, -leg * 0.6f, 0), new Vector3(0.05f, leg * 1.4f + 0.1f, 0.05f), Color.Lerp(s.primary, Black, 0.3f));
                    mb.Pop();
                }
            if ((s.features & F.Pincers) != 0)
                for (int side = -1; side <= 1; side += 2)
                {
                    // Arm runs from inside the body edge to the claw, so it always stays attached.
                    Vector3 shoulder = c + new Vector3(side * W * 0.25f, 0, L * 0.2f);
                    Vector3 claw = c + new Vector3(side * (W * 0.42f + 0.1f), 0.05f, L * 0.5f + 0.22f);
                    Vector3 arm = claw - shoulder;
                    mb.Box((shoulder + claw) * 0.5f, new Vector3(0.1f, 0.1f, arm.magnitude), Quaternion.LookRotation(arm.normalized, Vector3.up), s.primary);
                    mb.Sphere(claw, new Vector3(0.24f, 0.2f, 0.3f), s.secondary, 6, 4);
                    mb.Box(claw + new Vector3(side * 0.05f, 0, 0.2f), new Vector3(0.06f, 0.08f, 0.2f), Quaternion.Euler(0, side * 15f, 0), s.secondary, 0.4f);
                    mb.Box(claw + new Vector3(side * -0.05f, 0, 0.2f), new Vector3(0.06f, 0.08f, 0.18f), Quaternion.Euler(0, side * -15f, 0), s.secondary, 0.4f);
                }
            if ((s.features & F.Stinger) != 0)
            {
                Vector3 p = c + new Vector3(0, H * 0.1f, -L * 0.45f);
                float t = Mathf.Max(0.4f, s.tailLength);
                for (int i = 0; i < 6; i++)
                {
                    float a = i * 30f;
                    mb.Sphere(p, Vector3.one * (0.19f - i * 0.012f), s.primary, 6, 4);
                    p += Quaternion.Euler(a + 10f, 0, 0) * new Vector3(0, 0, -t * 0.17f); // curls up and over the back
                }
                mb.Push(p, Quaternion.Euler(150f, 0, 0));
                mb.Cone(Vector3.zero, 0.09f, 0.25f, 5, s.accent);
                mb.Pop();
            }
            if ((s.features & F.Horns) != 0)
            {
                mb.Push(head + new Vector3(0, H * 0.15f, L * 0.05f), Quaternion.Euler(-30f, 0, 0));
                mb.Cone(Vector3.zero, 0.07f, 0.35f, 5, s.accent);
                mb.Pop();
            }
        }

        static void BuildApe(MeshBuilder mb, AnimalModel model, AnimalModelSpec s, System.Random rng)
        {
            float H = s.bodyHeight, W = s.bodyWidth, L = s.bodyLength, leg = s.legLength, hs = s.headSize;
            float hipY = leg;
            Vector3 torso = new Vector3(0, hipY + H * 0.5f, 0);
            mb.Box(torso, new Vector3(W, H, L * 0.6f), s.primary, 0.85f);
            mb.Box(torso + new Vector3(0, -H * 0.05f, L * 0.3f), new Vector3(W * 0.6f, H * 0.6f, 0.05f), s.secondary);
            Vector3 head = torso + new Vector3(0, H * 0.5f + hs * 0.4f, L * 0.08f);
            mb.Box(head, new Vector3(hs, hs * 0.95f, hs * 0.9f), s.primary, 0.9f);
            mb.Box(head + new Vector3(0, -hs * 0.12f, hs * 0.42f), new Vector3(hs * 0.7f, hs * 0.55f, hs * 0.12f), s.secondary);
            mb.Box(head + new Vector3(0, -hs * 0.2f, hs * 0.5f), new Vector3(hs * 0.25f, hs * 0.1f, hs * 0.05f), Black);
            Eyes(mb, head, hs, hs * 0.48f, hs * 0.2f, hs * 0.12f);
            mb.Box(head + new Vector3(0, hs * 0.22f, hs * 0.45f), new Vector3(hs * 0.75f, hs * 0.1f, hs * 0.1f), Color.Lerp(s.primary, Black, 0.3f));
            Ears(mb, s, head, hs);
            HeadExtras(mb, s, head, hs);
            if ((s.features & F.Fluffy) != 0)
                for (int i = 0; i < 14; i++)
                {
                    Vector3 p = torso + new Vector3(((float)rng.NextDouble() - 0.5f) * W, ((float)rng.NextDouble() - 0.5f) * H, ((float)rng.NextDouble() - 0.5f) * L * 0.6f);
                    mb.Sphere(p, Vector3.one * W * 0.35f, Color.Lerp(s.primary, White, 0.2f), 6, 4);
                }
            if (s.tailLength > 0.05f)
            {
                Vector3 p = torso + new Vector3(0, -H * 0.35f, -L * 0.3f);
                int segments = Mathf.Max(4, Mathf.CeilToInt(s.tailLength / 0.08f));
                for (int i = 0; i < segments; i++)
                {
                    mb.Sphere(p, Vector3.one * 0.13f, s.primary, 5, 3);
                    p += Quaternion.Euler(-i * (180f / segments), 0, 0) * new Vector3(0, 0.02f, -0.08f);
                }
            }
            float legW = Mathf.Clamp(W * 0.32f, 0.1f, 0.35f);
            var legMesh = LegMesh(legW, leg, s.primary, Color.Lerp(s.secondary, Black, 0.2f));
            model.limbs.Add(new LimbSpec { mesh = legMesh, pivot = new Vector3(-W * 0.25f, hipY, 0), kind = LimbKind.Leg, phase = 0, side = -1 });
            model.limbs.Add(new LimbSpec { mesh = legMesh, pivot = new Vector3(W * 0.25f, hipY, 0), kind = LimbKind.Leg, phase = Mathf.PI, side = 1 });
            float armLen = H * 0.9f + leg * 0.6f;
            var armMesh = LegMesh(legW * 0.9f, armLen, s.primary, s.secondary);
            model.limbs.Add(new LimbSpec { mesh = armMesh, pivot = new Vector3(-W * 0.5f - legW * 0.45f, hipY + H * 0.9f, 0), kind = LimbKind.Arm, phase = Mathf.PI, side = -1 });
            model.limbs.Add(new LimbSpec { mesh = armMesh, pivot = new Vector3(W * 0.5f + legW * 0.45f, hipY + H * 0.9f, 0), kind = LimbKind.Arm, phase = 0, side = 1 });
        }

        static void BuildOctopus(MeshBuilder mb, AnimalModel model, AnimalModelSpec s)
        {
            float H = s.bodyHeight, W = s.bodyWidth, hs = s.headSize;
            Vector3 head = new Vector3(0, 0.35f + H * 0.5f, 0);
            mb.Sphere(head, new Vector3(W, H * 1.1f, W * 0.95f), s.primary, 10, 6);
            for (int i = 0; i < 5; i++)
                mb.Sphere(head + new Vector3(Mathf.Cos(i * 1.3f) * W * 0.3f, H * 0.2f + i * 0.04f, Mathf.Sin(i * 1.3f) * W * 0.3f), Vector3.one * 0.1f, s.secondary, 5, 3);
            Eyes(mb, head + new Vector3(0, -H * 0.1f, 0), hs, W * 0.44f, W * 0.2f, 0.11f, true);
            for (int i = 0; i < 8; i++)
            {
                float a = i * Mathf.PI * 2f / 8f;
                Vector3 dir = new Vector3(Mathf.Cos(a), 0, Mathf.Sin(a));
                Vector3 p = head + new Vector3(0, -H * 0.4f, 0) + dir * W * 0.25f;
                for (int k = 0; k < 8; k++)
                {
                    // Overlapping segments: spacing stays below the segment size so the tentacle reads as one piece.
                    float sz = 0.24f - k * 0.015f;
                    mb.Sphere(p, Vector3.one * sz, k % 2 == 0 ? s.primary : Color.Lerp(s.primary, s.secondary, 0.4f), 6, 4);
                    p += dir * 0.09f + Vector3.down * (k < 3 ? 0.07f : k > 5 ? -0.03f : 0f);
                }
            }
        }

        static void BuildTurtle(MeshBuilder mb, AnimalModel model, AnimalModelSpec s, System.Random rng)
        {
            float L = s.bodyLength, H = s.bodyHeight, W = s.bodyWidth, leg = s.legLength + 0.08f, hs = s.headSize;
            Vector3 c = new Vector3(0, leg + 0.05f, 0);
            mb.Box(c, new Vector3(W * 0.9f, 0.1f, L * 0.9f), s.secondary);
            mb.Sphere(c + new Vector3(0, 0.02f, 0), new Vector3(W, H * 1.6f, L), s.secondary, 10, 5);
            for (int i = 0; i < 7; i++)
            {
                float a = i * Mathf.PI * 2f / 6f;
                Vector3 p = i == 6 ? c + new Vector3(0, H * 0.78f, 0) : c + new Vector3(Mathf.Cos(a) * W * 0.25f, H * 0.6f, Mathf.Sin(a) * L * 0.25f);
                mb.Box(p, new Vector3(W * 0.22f, 0.05f, L * 0.22f), Quaternion.Euler(0, a * Mathf.Rad2Deg, 0), Color.Lerp(s.accent, s.secondary, (float)rng.NextDouble() * 0.5f));
            }
            Vector3 head = c + new Vector3(0, 0.08f, L * 0.55f);
            mb.Box(head, new Vector3(hs, hs * 0.8f, hs * 1.1f), s.primary, 0.85f);
            Eyes(mb, head, hs, hs * 0.5f, hs * 0.3f, hs * 0.16f);
            mb.Box(head + new Vector3(0, -hs * 0.2f, hs * 0.55f), new Vector3(hs * 0.4f, 0.02f, 0.02f), Black);
            var legMesh = LegMesh(0.16f, leg, s.primary, s.primary);
            AddLegs(model, legMesh, W * 0.38f, L * 0.3f, -L * 0.3f, leg);
        }
    }
}
