using System.Collections.Generic;
using UnityEngine;
using ZooThrow.Data;
using ZooThrow.Visuals;

namespace ZooThrow.Throwing
{
    /// <summary>
    /// Stylised fishing rods: a metal butt cap, a thick cross-wrapped grip, a boxy reel with an emblem on both
    /// sides and a charm hanging on a chain, then a tapered blank in sections with metal ferrules, a pattern,
    /// decorative motifs, line guides and a metal tip. Built along +Y from the butt (y = 0) to the tip.
    /// </summary>
    public static class RodModelFactory
    {
        static readonly Dictionary<string, Mesh> s_Cache = new Dictionary<string, Mesh>();

        public static Vector3 TipLocal(RodData r) => new Vector3(0, r.length, 0);

        public static Mesh Get(RodData r)
        {
            if (s_Cache.TryGetValue(r.id, out var m)) return m;
            var mb = new MeshBuilder();
            Build(mb, r);
            m = mb.ToMesh("Rod_" + r.id);
            s_Cache[r.id] = m;
            return m;
        }

        static void Build(MeshBuilder mb, RodData r)
        {
            float len = r.length;
            float gripLen = Mathf.Min(0.62f, len * 0.24f);
            // Chunky, toy-like proportions to match the stylised look.
            const float gripR = 0.09f;
            float blankR0 = 0.06f, blankR1 = 0.022f;
            Color grip = r.secondary, gripDark = MeshBuilder.Shade(r.secondary, 0.7f);

            // Butt cap
            mb.Cylinder(Vector3.zero, gripR * 0.8f, gripR * 1.05f, 0.05f, 10, r.metal);
            // Grip with cross wrapping
            mb.Cylinder(new Vector3(0, 0.05f, 0), gripR, gripR * 0.92f, gripLen - 0.05f, 12, grip);
            // Two leather wrap bands spiralling around the grip
            for (int band = 0; band < 2; band++)
                for (float y = 0.08f; y < gripLen - 0.04f; y += 0.012f)
                {
                    float a = band * 180f + (y - 0.08f) * 900f;
                    Vector3 dir = Quaternion.Euler(0, a, 0) * Vector3.forward;
                    float rr = Mathf.Lerp(gripR, gripR * 0.92f, y / gripLen);
                    mb.Box(new Vector3(0, y, 0) + dir * rr, new Vector3(0.035f, 0.022f, 0.008f), Quaternion.Euler(0, a, 35f), gripDark);
                }
            mb.Cylinder(new Vector3(0, gripLen - 0.02f, 0), gripR * 0.98f, gripR * 0.98f, 0.035f, 10, r.metal);
            mb.Cylinder(new Vector3(0, 0.05f, 0), gripR * 1.06f, gripR * 1.06f, 0.025f, 10, r.metal);

            // Reel on the front (+Z) of the grip
            float reelY = gripLen * 0.55f;
            var reelC = new Vector3(0, reelY, gripR + 0.1f);
            mb.Box(new Vector3(0, reelY, gripR + 0.02f), new Vector3(0.06f, 0.06f, 0.06f), r.metal);
            mb.Box(reelC, new Vector3(0.15f, 0.18f, 0.18f), r.reelColor, 0.92f);
            Color face = Color.Lerp(r.reelColor, Color.white, 0.25f);
            for (int side = -1; side <= 1; side += 2)
            {
                mb.Box(reelC + new Vector3(side * 0.077f, 0, 0), new Vector3(0.01f, 0.145f, 0.145f), face);
                mb.Push(reelC + new Vector3(side * 0.085f, 0, 0), Quaternion.Euler(0, side * 90f, 0));
                Glyph(mb, r.emblem, 0.11f, r.accent, 0.014f);
                mb.Pop();
            }
            // Crank on top so it never covers the emblems
            mb.Box(reelC + new Vector3(0, 0.1f, 0.02f), new Vector3(0.025f, 0.03f, 0.08f), r.metal);
            mb.Sphere(reelC + new Vector3(0, 0.12f, 0.065f), Vector3.one * 0.04f, MeshBuilder.Shade(r.reelColor, 0.8f), 6, 4);

            // Charm hanging on a chain under the reel
            Vector3 chain = reelC + new Vector3(0, -0.1f, 0);
            for (int i = 0; i < 5; i++)
                mb.Sphere(chain + new Vector3(0, -i * 0.03f, 0), Vector3.one * 0.02f, r.metal, 5, 3);
            mb.Push(chain + new Vector3(0, -0.24f, 0), Quaternion.Euler(0, 90f, 0));
            Glyph(mb, r.charm, 0.14f, r.charmColor, 0.035f);
            mb.Pop();

            // Blank in three sections with metal ferrules
            float b0 = gripLen;
            float blankLen = len - b0;
            float RadiusAt(float y) => Mathf.Lerp(blankR0, blankR1, Mathf.Clamp01((y - b0) / blankLen));
            float[] joints = { 0f, 0.42f, 0.7f, 1f };
            for (int i = 0; i < 3; i++)
            {
                float y0 = b0 + blankLen * joints[i], y1 = b0 + blankLen * joints[i + 1];
                mb.Cylinder(new Vector3(0, y0, 0), RadiusAt(y0), RadiusAt(y1), y1 - y0, 8, r.primary, false);
                if (i > 0) mb.Cylinder(new Vector3(0, y0 - 0.02f, 0), RadiusAt(y0) + 0.007f, RadiusAt(y0) + 0.007f, 0.04f, 8, r.metal);
            }

            switch (r.pattern)
            {
                case RodPattern.BambooNodes:
                    for (float y = b0 + 0.12f; y < len - 0.1f; y += len * 0.12f)
                        mb.Cylinder(new Vector3(0, y, 0), RadiusAt(y) + 0.006f, RadiusAt(y) + 0.006f, 0.025f, 8, MeshBuilder.Shade(r.primary, 0.72f));
                    break;
                case RodPattern.SpiralStripes:
                    for (float y = b0 + 0.05f; y < b0 + blankLen * 0.62f; y += 0.03f)
                    {
                        float a = (y - b0) * 900f;
                        Vector3 dir = Quaternion.Euler(0, a, 0) * Vector3.forward;
                        mb.Box(new Vector3(0, y, 0) + dir * (RadiusAt(y) + 0.002f), new Vector3(0.03f, 0.03f, 0.01f), Quaternion.Euler(0, a, 40f), r.accent);
                    }
                    break;
                case RodPattern.Ornament:
                    foreach (float t in new[] { 0.15f, 0.5f, 0.78f })
                    {
                        float y = b0 + blankLen * t;
                        mb.Cylinder(new Vector3(0, y, 0), RadiusAt(y) + 0.004f, RadiusAt(y) + 0.004f, 0.012f, 8, r.accent);
                        mb.Cylinder(new Vector3(0, y + 0.05f, 0), RadiusAt(y) + 0.004f, RadiusAt(y) + 0.004f, 0.012f, 8, r.accent);
                    }
                    break;
            }

            // Decorative motifs on both sides of the blank, plus small accent dots
            if (r.motif != RodGlyph.None)
                foreach (float t in new[] { 0.28f, 0.58f })
                {
                    float y = b0 + blankLen * t;
                    for (int side = -1; side <= 1; side += 2)
                    {
                        mb.Push(new Vector3(side * (RadiusAt(y) + 0.003f), y, 0), Quaternion.Euler(0, side * 90f, 0));
                        Glyph(mb, r.motif, 0.1f, r.accent, 0.01f);
                        mb.Pop();
                    }
                }
            for (int i = 0; i < 5; i++)
            {
                float y = b0 + blankLen * (0.38f + i * 0.11f);
                mb.Sphere(new Vector3(RadiusAt(y), y, 0), Vector3.one * 0.022f, Color.Lerp(r.accent, Color.white, 0.4f), 4, 3);
            }

            // Line guides on the front and a metal tip
            for (int i = 1; i <= 5; i++)
            {
                float y = b0 + blankLen * (i / 6f);
                float rr = RadiusAt(y);
                mb.Box(new Vector3(0, y, rr + 0.02f), new Vector3(0.008f, 0.012f, 0.04f), r.metal);
                mb.Cylinder(new Vector3(0, y - 0.008f, rr + 0.045f), 0.016f, 0.016f, 0.016f, 6, r.metal, false);
            }
            mb.Sphere(new Vector3(0, len, 0), Vector3.one * 0.03f, r.metal, 6, 4);
            if (r.glows)
                mb.Sphere(new Vector3(0, len + 0.01f, 0), Vector3.one * 0.045f, r.lineColor, 6, 4);
        }

        /// <summary>
        /// Draws a small symbol centred at the origin in the local XY plane, facing +Z, about <paramref name="s"/>
        /// across and <paramref name="depth"/> thick.
        /// </summary>
        public static void Glyph(MeshBuilder mb, RodGlyph g, float s, Color c, float depth)
        {
            Color dark = MeshBuilder.Shade(c, 0.7f);
            switch (g)
            {
                case RodGlyph.Leaf:
                    mb.Push(Vector3.zero, Quaternion.Euler(0, 0, -25f));
                    mb.Sphere(Vector3.zero, new Vector3(s * 0.5f, s, depth * 2f), c, 7, 4);
                    mb.Box(new Vector3(0, 0, depth * 0.6f), new Vector3(s * 0.06f, s * 0.85f, depth * 0.5f), dark);
                    mb.Pop();
                    break;
                case RodGlyph.Sprout:
                    mb.Box(new Vector3(0, -s * 0.2f, 0), new Vector3(s * 0.1f, s * 0.6f, depth), dark);
                    for (int side = -1; side <= 1; side += 2)
                    {
                        mb.Push(new Vector3(side * s * 0.2f, s * 0.15f, 0), Quaternion.Euler(0, 0, side * -50f));
                        mb.Sphere(Vector3.zero, new Vector3(s * 0.3f, s * 0.55f, depth * 2f), c, 6, 4);
                        mb.Pop();
                    }
                    break;
                case RodGlyph.Snowflake:
                    for (int i = 0; i < 3; i++)
                    {
                        mb.Push(Vector3.zero, Quaternion.Euler(0, 0, i * 60f));
                        mb.Box(Vector3.zero, new Vector3(s * 0.12f, s, depth), c);
                        for (int end = -1; end <= 1; end += 2)
                            for (int side = -1; side <= 1; side += 2)
                                mb.Box(new Vector3(side * s * 0.08f, end * s * 0.32f, 0), new Vector3(s * 0.08f, s * 0.22f, depth), Quaternion.Euler(0, 0, side * end * 40f), c);
                        mb.Pop();
                    }
                    break;
                case RodGlyph.Flower:
                    for (int i = 0; i < 5; i++)
                    {
                        float a = i * Mathf.PI * 2f / 5f;
                        mb.Sphere(new Vector3(Mathf.Cos(a), Mathf.Sin(a), 0) * s * 0.3f, new Vector3(s * 0.42f, s * 0.42f, depth * 2f), c, 6, 4);
                    }
                    mb.Sphere(Vector3.zero, new Vector3(s * 0.3f, s * 0.3f, depth * 2.5f), new Color(1f, 0.85f, 0.3f), 6, 4);
                    break;
                case RodGlyph.Star:
                    mb.Push(Vector3.zero, Quaternion.identity, new Vector3(1f, 1f, depth / (s * 0.2f)));
                    for (int i = 0; i < 4; i++)
                    {
                        mb.Push(Vector3.zero, Quaternion.Euler(0, 0, i * 90f));
                        mb.Cone(Vector3.zero, s * 0.18f, s * 0.55f, 4, c);
                        mb.Pop();
                    }
                    mb.Pop();
                    break;
                case RodGlyph.Triangle:
                    for (int i = 0; i < 3; i++)
                    {
                        float a = i * 120f;
                        mb.Push(Vector3.zero, Quaternion.Euler(0, 0, a));
                        mb.Box(new Vector3(0, -s * 0.25f, 0), new Vector3(s * 0.85f, s * 0.12f, depth), c);
                        mb.Pop();
                    }
                    break;
                case RodGlyph.Wave:
                    for (int i = 0; i < 7; i++)
                    {
                        float a = i * 0.75f;
                        float rr = s * 0.42f * (1f - i * 0.1f);
                        mb.Sphere(new Vector3(Mathf.Cos(a) * rr, Mathf.Sin(a) * rr, 0), new Vector3(s * 0.16f, s * 0.16f, depth * 2f), c, 5, 3);
                    }
                    mb.Box(new Vector3(-s * 0.1f, -s * 0.38f, 0), new Vector3(s * 0.9f, s * 0.1f, depth), c);
                    break;
                case RodGlyph.Spiral:
                    for (int i = 0; i < 10; i++)
                    {
                        float a = i * 0.85f;
                        float rr = s * 0.48f * (1f - i * 0.085f);
                        mb.Sphere(new Vector3(Mathf.Cos(a) * rr, Mathf.Sin(a) * rr, 0), new Vector3(s * 0.15f, s * 0.15f, depth * 2f), c, 5, 3);
                    }
                    break;
                case RodGlyph.Anchor:
                    mb.Box(new Vector3(0, 0, 0), new Vector3(s * 0.1f, s * 0.8f, depth), c);
                    mb.Box(new Vector3(0, s * 0.22f, 0), new Vector3(s * 0.5f, s * 0.09f, depth), c);
                    for (int i = 0; i < 6; i++)
                    {
                        float a = i * Mathf.PI * 2f / 6f;
                        mb.Sphere(new Vector3(Mathf.Cos(a) * s * 0.1f, s * 0.46f + Mathf.Sin(a) * s * 0.1f, 0), new Vector3(s * 0.07f, s * 0.07f, depth * 1.5f), c, 4, 3);
                    }
                    for (int i = 0; i <= 6; i++)
                    {
                        float a = Mathf.PI + i * Mathf.PI / 6f;
                        mb.Sphere(new Vector3(Mathf.Cos(a) * s * 0.36f, -s * 0.12f + Mathf.Sin(a) * s * 0.3f, 0), new Vector3(s * 0.11f, s * 0.11f, depth * 1.5f), c, 5, 3);
                    }
                    for (int side = -1; side <= 1; side += 2)
                    {
                        mb.Push(new Vector3(side * s * 0.36f, -s * 0.12f, 0), Quaternion.Euler(0, 0, side * 20f));
                        mb.Cone(Vector3.zero, s * 0.09f, s * 0.18f, 4, c);
                        mb.Pop();
                    }
                    break;
                case RodGlyph.Tag:
                    mb.Box(Vector3.zero, new Vector3(s * 0.55f, s * 0.85f, depth), c);
                    mb.Box(new Vector3(0, -s * 0.05f, depth * 0.55f), new Vector3(s * 0.08f, s * 0.45f, depth * 0.2f), Quaternion.Euler(0, 0, 30f), Color.white);
                    mb.Box(new Vector3(s * 0.1f, -s * 0.1f, depth * 0.55f), new Vector3(s * 0.08f, s * 0.35f, depth * 0.2f), Quaternion.Euler(0, 0, 30f), Color.white);
                    mb.Sphere(new Vector3(0, s * 0.32f, 0), new Vector3(s * 0.12f, s * 0.12f, depth * 1.5f), dark, 5, 3);
                    break;
                case RodGlyph.Drop:
                    mb.Sphere(new Vector3(0, -s * 0.12f, 0), new Vector3(s * 0.55f, s * 0.55f, depth * 3f), c, 8, 5);
                    mb.Cone(new Vector3(0, s * 0.05f, 0), s * 0.24f, s * 0.45f, 8, c);
                    break;
                case RodGlyph.Tassel:
                    mb.Sphere(new Vector3(0, s * 0.3f, 0), Vector3.one * s * 0.28f, dark, 6, 4);
                    mb.Cylinder(new Vector3(0, s * 0.18f, 0), s * 0.12f, s * 0.12f, s * 0.08f, 6, new Color(1f, 0.85f, 0.3f));
                    mb.Push(new Vector3(0, s * 0.18f, 0), Quaternion.Euler(180f, 0, 0));
                    mb.Cylinder(Vector3.zero, s * 0.1f, s * 0.24f, s * 0.6f, 8, c);
                    mb.Pop();
                    break;
            }
        }
    }
}
