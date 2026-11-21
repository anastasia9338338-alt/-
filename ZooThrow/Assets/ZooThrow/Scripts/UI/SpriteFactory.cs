using System;
using System.Collections.Generic;
using UnityEngine;

namespace ZooThrow.UI
{
    public enum IconId
    {
        Circle, Coin, Income, Power, Paw, Shop, Upgrade, Collection, Gear, Lock, Star, Close, ChevronLeft, ChevronRight,
        Check, Flag, Food, Sparkle, Clock, Target
    }

    /// <summary>UI sprites generated at runtime: anti-aliased rounded rectangles (9-sliced) and vector-like icons.</summary>
    public static class SpriteFactory
    {
        static readonly Dictionary<string, Sprite> s_Cache = new Dictionary<string, Sprite>();

        public static Sprite Rounded(int radius)
        {
            string key = "round" + radius;
            if (s_Cache.TryGetValue(key, out var sp)) return sp;
            int size = radius * 2 + 4;
            var tex = NewTex(size, "ZT_Round" + radius);
            var px = new Color32[size * size];
            float c = (size - 1) * 0.5f, half = c;
            for (int y = 0; y < size; y++)
                for (int x = 0; x < size; x++)
                {
                    float d = RoundBox(new Vector2(x - c, y - c), new Vector2(half, half), radius);
                    px[y * size + x] = new Color32(255, 255, 255, (byte)(Mathf.Clamp01(0.5f - d) * 255));
                }
            tex.SetPixels32(px);
            tex.Apply(false, true);
            float b = radius + 1;
            sp = Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100f, 0, SpriteMeshType.FullRect, new Vector4(b, b, b, b));
            s_Cache[key] = sp;
            return sp;
        }

        /// <summary>Soft blurred rounded rectangle for drop shadows and glows.</summary>
        public static Sprite Soft(int radius, int blur)
        {
            string key = "soft" + radius + "_" + blur;
            if (s_Cache.TryGetValue(key, out var sp)) return sp;
            int size = (radius + blur) * 2 + 4;
            var tex = NewTex(size, "ZT_Soft");
            var px = new Color32[size * size];
            float c = (size - 1) * 0.5f;
            for (int y = 0; y < size; y++)
                for (int x = 0; x < size; x++)
                {
                    float d = RoundBox(new Vector2(x - c, y - c), new Vector2(radius, radius), radius * 0.6f);
                    float a = 1f - Mathf.Clamp01((d + blur * 0.2f) / blur);
                    a = a * a * (3f - 2f * a);
                    px[y * size + x] = new Color32(255, 255, 255, (byte)(a * 255));
                }
            tex.SetPixels32(px);
            tex.Apply(false, true);
            float b = radius + blur + 1;
            sp = Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100f, 0, SpriteMeshType.FullRect, new Vector4(b, b, b, b));
            s_Cache[key] = sp;
            return sp;
        }

        /// <summary>Radial sun-ray burst used behind big rewards.</summary>
        public static Sprite Rays()
        {
            const string key = "rays";
            if (s_Cache.TryGetValue(key, out var sp)) return sp;
            const int size = 256;
            var tex = NewTex(size, "ZT_Rays");
            var px = new Color32[size * size];
            float c = (size - 1) * 0.5f;
            for (int y = 0; y < size; y++)
                for (int x = 0; x < size; x++)
                {
                    float dx = x - c, dy = y - c;
                    float r = Mathf.Sqrt(dx * dx + dy * dy) / c;
                    float ang = Mathf.Atan2(dy, dx);
                    float ray = Mathf.Clamp01(Mathf.Cos(ang * 12f) * 2.2f - 0.6f);
                    float a = ray * Mathf.Clamp01(1f - r) * 0.9f + Mathf.Clamp01(1f - r * 1.6f) * 0.5f;
                    px[y * size + x] = new Color32(255, 255, 255, (byte)(Mathf.Clamp01(a) * 255));
                }
            tex.SetPixels32(px);
            tex.Apply(false, true);
            sp = Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100f);
            s_Cache[key] = sp;
            return sp;
        }

        public static Sprite Icon(IconId id)
        {
            string key = "icon" + id;
            if (s_Cache.TryGetValue(key, out var sp)) return sp;
            sp = Raster(key, 96, IconSdf(id));
            s_Cache[key] = sp;
            return sp;
        }

        static Texture2D NewTex(int size, string name) =>
            new Texture2D(size, size, TextureFormat.RGBA32, false) { name = name, wrapMode = TextureWrapMode.Clamp, filterMode = FilterMode.Bilinear };

        static Sprite Raster(string name, int size, Func<Vector2, float> sdf)
        {
            var tex = NewTex(size, "ZT_" + name);
            var px = new Color32[size * size];
            float px2uv = 2f / size;
            for (int y = 0; y < size; y++)
                for (int x = 0; x < size; x++)
                {
                    var p = new Vector2((x + 0.5f) * px2uv - 1f, (y + 0.5f) * px2uv - 1f);
                    float d = sdf(p) / px2uv; // distance in pixels
                    px[y * size + x] = new Color32(255, 255, 255, (byte)(Mathf.Clamp01(0.5f - d) * 255));
                }
            tex.SetPixels32(px);
            tex.Apply(false, true);
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100f);
        }

        // ---------------------------------------------------------------- signed distance helpers

        static float RoundBox(Vector2 p, Vector2 half, float r)
        {
            Vector2 q = new Vector2(Mathf.Abs(p.x), Mathf.Abs(p.y)) - half + new Vector2(r, r);
            return new Vector2(Mathf.Max(q.x, 0), Mathf.Max(q.y, 0)).magnitude + Mathf.Min(Mathf.Max(q.x, q.y), 0f) - r;
        }

        static float Circle(Vector2 p, Vector2 c, float r) => (p - c).magnitude - r;
        static float Ring(Vector2 p, Vector2 c, float r, float w) => Mathf.Abs((p - c).magnitude - r) - w;
        static float Box(Vector2 p, Vector2 c, Vector2 half, float r) => RoundBox(p - c, half, r);

        static float Segment(Vector2 p, Vector2 a, Vector2 b, float r)
        {
            Vector2 pa = p - a, ba = b - a;
            float h = Mathf.Clamp01(Vector2.Dot(pa, ba) / Vector2.Dot(ba, ba));
            return (pa - ba * h).magnitude - r;
        }

        static float Poly(Vector2 p, Vector2[] v)
        {
            float d = Vector2.Dot(p - v[0], p - v[0]);
            float s = 1f;
            for (int i = 0, j = v.Length - 1; i < v.Length; j = i, i++)
            {
                Vector2 e = v[j] - v[i], w = p - v[i];
                Vector2 b = w - e * Mathf.Clamp01(Vector2.Dot(w, e) / Vector2.Dot(e, e));
                d = Mathf.Min(d, Vector2.Dot(b, b));
                bool c1 = p.y >= v[i].y, c2 = p.y < v[j].y, c3 = e.x * w.y > e.y * w.x;
                if ((c1 && c2 && c3) || (!c1 && !c2 && !c3)) s = -s;
            }
            return s * Mathf.Sqrt(d);
        }

        static Vector2[] StarPoints(int points, float outer, float inner, float rotation)
        {
            var v = new Vector2[points * 2];
            for (int i = 0; i < points * 2; i++)
            {
                float a = rotation + i * Mathf.PI / points;
                float r = i % 2 == 0 ? outer : inner;
                v[i] = new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * r;
            }
            return v;
        }

        static float U(float a, float b) => Mathf.Min(a, b);
        static float Sub(float a, float b) => Mathf.Max(a, -b);

        static Func<Vector2, float> IconSdf(IconId id)
        {
            switch (id)
            {
                case IconId.Coin:
                    return p => Sub(Sub(Circle(p, Vector2.zero, 0.88f), Ring(p, Vector2.zero, 0.64f, 0.06f)), Box(p, Vector2.zero, new Vector2(0.11f, 0.34f), 0.05f));
                case IconId.Income:
                    return p => U(Segment(p, new Vector2(0, -0.75f), new Vector2(0, 0.55f), 0.15f),
                                 U(Segment(p, new Vector2(0, 0.7f), new Vector2(-0.5f, 0.2f), 0.15f), Segment(p, new Vector2(0, 0.7f), new Vector2(0.5f, 0.2f), 0.15f)));
                case IconId.Power:
                    return p => U(Segment(p, new Vector2(-0.6f, 0), new Vector2(0.6f, 0), 0.1f),
                                 U(U(Box(p, new Vector2(-0.55f, 0), new Vector2(0.13f, 0.45f), 0.06f), Box(p, new Vector2(0.55f, 0), new Vector2(0.13f, 0.45f), 0.06f)),
                                   U(Box(p, new Vector2(-0.82f, 0), new Vector2(0.09f, 0.3f), 0.05f), Box(p, new Vector2(0.82f, 0), new Vector2(0.09f, 0.3f), 0.05f))));
                case IconId.Paw:
                    return p => U(U(Circle(p, new Vector2(0, -0.3f), 0.42f), Circle(p, new Vector2(-0.58f, 0.18f), 0.2f)),
                                 U(U(Circle(p, new Vector2(-0.22f, 0.55f), 0.21f), Circle(p, new Vector2(0.22f, 0.55f), 0.21f)), Circle(p, new Vector2(0.58f, 0.18f), 0.2f)));
                case IconId.Shop:
                    return p => U(Sub(Box(p, new Vector2(0, -0.15f), new Vector2(0.62f, 0.5f), 0.12f), Box(p, new Vector2(0, -0.1f), new Vector2(0.06f, 0.6f), 0f)),
                                 Sub(Ring(p, new Vector2(0, 0.38f), 0.3f, 0.08f), Box(p, new Vector2(0, 0.1f), new Vector2(1f, 0.28f), 0)));
                case IconId.Upgrade:
                    return p => U(U(Segment(p, new Vector2(-0.6f, -0.05f), new Vector2(0, 0.55f), 0.14f), Segment(p, new Vector2(0.6f, -0.05f), new Vector2(0, 0.55f), 0.14f)),
                                 U(Segment(p, new Vector2(-0.6f, -0.6f), new Vector2(0, 0f), 0.14f), Segment(p, new Vector2(0.6f, -0.6f), new Vector2(0, 0f), 0.14f)));
                case IconId.Collection:
                    return p => U(U(Box(p, new Vector2(-0.4f, 0.4f), new Vector2(0.32f, 0.32f), 0.1f), Box(p, new Vector2(0.4f, 0.4f), new Vector2(0.32f, 0.32f), 0.1f)),
                                 U(Box(p, new Vector2(-0.4f, -0.4f), new Vector2(0.32f, 0.32f), 0.1f), Box(p, new Vector2(0.4f, -0.4f), new Vector2(0.32f, 0.32f), 0.1f)));
                case IconId.Gear:
                    return p =>
                    {
                        float d = Circle(p, Vector2.zero, 0.6f);
                        for (int i = 0; i < 8; i++)
                        {
                            float a = i * Mathf.PI / 4f;
                            var dir = new Vector2(Mathf.Cos(a), Mathf.Sin(a));
                            d = U(d, Segment(p, dir * 0.5f, dir * 0.82f, 0.13f));
                        }
                        return Sub(d, Circle(p, Vector2.zero, 0.25f));
                    };
                case IconId.Lock:
                    return p => U(Sub(Box(p, new Vector2(0, -0.25f), new Vector2(0.58f, 0.45f), 0.1f), Circle(p, new Vector2(0, -0.2f), 0.12f)),
                                 Sub(Ring(p, new Vector2(0, 0.25f), 0.34f, 0.1f), Box(p, new Vector2(0, -0.2f), new Vector2(1f, 0.45f), 0)));
                case IconId.Star:
                    {
                        var v = StarPoints(5, 0.92f, 0.4f, Mathf.PI / 2f);
                        return p => Poly(p, v);
                    }
                case IconId.Sparkle:
                    {
                        var v = StarPoints(4, 0.92f, 0.22f, Mathf.PI / 2f);
                        return p => Poly(p, v);
                    }
                case IconId.Close:
                    return p => U(Segment(p, new Vector2(-0.55f, -0.55f), new Vector2(0.55f, 0.55f), 0.15f), Segment(p, new Vector2(-0.55f, 0.55f), new Vector2(0.55f, -0.55f), 0.15f));
                case IconId.ChevronLeft:
                    return p => U(Segment(p, new Vector2(0.3f, 0.6f), new Vector2(-0.3f, 0f), 0.16f), Segment(p, new Vector2(-0.3f, 0f), new Vector2(0.3f, -0.6f), 0.16f));
                case IconId.ChevronRight:
                    return p => U(Segment(p, new Vector2(-0.3f, 0.6f), new Vector2(0.3f, 0f), 0.16f), Segment(p, new Vector2(0.3f, 0f), new Vector2(-0.3f, -0.6f), 0.16f));
                case IconId.Check:
                    return p => U(Segment(p, new Vector2(-0.6f, 0f), new Vector2(-0.15f, -0.45f), 0.15f), Segment(p, new Vector2(-0.15f, -0.45f), new Vector2(0.65f, 0.45f), 0.15f));
                case IconId.Flag:
                    {
                        var v = new[] { new Vector2(-0.45f, 0.8f), new Vector2(0.7f, 0.45f), new Vector2(-0.45f, 0.1f) };
                        return p => U(Segment(p, new Vector2(-0.5f, -0.85f), new Vector2(-0.5f, 0.8f), 0.09f), Poly(p, v));
                    }
                case IconId.Food:
                    return p => U(U(Circle(p, new Vector2(-0.22f, -0.15f), 0.55f), Circle(p, new Vector2(0.22f, -0.15f), 0.55f)), Segment(p, new Vector2(0, 0.35f), new Vector2(0.3f, 0.75f), 0.1f));
                case IconId.Clock:
                    return p => U(Ring(p, Vector2.zero, 0.75f, 0.1f), U(Segment(p, Vector2.zero, new Vector2(0, 0.5f), 0.08f), Segment(p, Vector2.zero, new Vector2(0.35f, -0.1f), 0.08f)));
                case IconId.Target:
                    return p => U(Ring(p, Vector2.zero, 0.75f, 0.09f), U(Ring(p, Vector2.zero, 0.42f, 0.09f), Circle(p, Vector2.zero, 0.14f)));
                default:
                    return p => Circle(p, Vector2.zero, 0.95f);
            }
        }
    }
}
