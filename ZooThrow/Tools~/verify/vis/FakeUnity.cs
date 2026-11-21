// Minimal managed re-implementation of the UnityEngine math/mesh types used by the procedural model code,
// so the real MeshBuilder/AnimalModelFactory/DecorFactory/SpriteFactory code can run outside Unity for visual checks.
using System;
using System.Collections.Generic;
namespace UnityEngine.Rendering { public enum IndexFormat { UInt16, UInt32 } }
namespace UnityEngine
{
    public class Object { public string name; public static void Destroy(Object o) { } }
    public class ScriptableObject : Object { public static T CreateInstance<T>() where T : ScriptableObject => (T)Activator.CreateInstance(typeof(T)); }
    public class CreateAssetMenuAttribute : Attribute { public string menuName, fileName; }
    public class TooltipAttribute : Attribute { public TooltipAttribute(string s) { } }
    public class HeaderAttribute : Attribute { public HeaderAttribute(string s) { } }
    public class TextAreaAttribute : Attribute { }
    public class RangeAttribute : Attribute { public RangeAttribute(float a, float b) { } }
    public static class Mathf
    {
        public const float PI = (float)Math.PI, Rad2Deg = 57.29578f, Deg2Rad = 0.01745329f;
        public static float Abs(float v) => Math.Abs(v);
        public static int Max(int a, int b) => Math.Max(a, b);
        public static float Max(float a, float b) => Math.Max(a, b);
        public static float Min(float a, float b) => Math.Min(a, b);
        public static int Min(int a, int b) => Math.Min(a, b);
        public static float Pow(float a, float b) => (float)Math.Pow(a, b);
        public static float Sqrt(float a) => (float)Math.Sqrt(a);
        public static float Sin(float a) => (float)Math.Sin(a);
        public static float Cos(float a) => (float)Math.Cos(a);
        public static float Atan2(float y, float x) => (float)Math.Atan2(y, x);
        public static float Clamp01(float v) => v < 0 ? 0 : v > 1 ? 1 : v;
        public static float Clamp(float v, float a, float b) => v < a ? a : v > b ? b : v;
        public static int Clamp(int v, int a, int b) => v < a ? a : v > b ? b : v;
        public static float Lerp(float a, float b, float t) => a + (b - a) * Clamp01(t);
        public static float InverseLerp(float a, float b, float v) => a == b ? 0 : Clamp01((v - a) / (b - a));
        public static int RoundToInt(float v) => (int)Math.Round(v);
        public static int CeilToInt(float v) => (int)Math.Ceiling(v);
        public static float PerlinNoise(float x, float y) => 0.5f + 0.25f * (float)(Math.Sin(x * 1.7 + y * 0.3) * Math.Cos(y * 1.3 - x * 0.2));
    }
    public struct Vector2
    {
        public float x, y;
        public Vector2(float x, float y) { this.x = x; this.y = y; }
        public static Vector2 zero => new Vector2(0, 0);
        public float magnitude => (float)Math.Sqrt(x * x + y * y);
        public static float Dot(Vector2 a, Vector2 b) => a.x * b.x + a.y * b.y;
        public static Vector2 operator +(Vector2 a, Vector2 b) => new Vector2(a.x + b.x, a.y + b.y);
        public static Vector2 operator -(Vector2 a, Vector2 b) => new Vector2(a.x - b.x, a.y - b.y);
        public static Vector2 operator *(Vector2 a, float k) => new Vector2(a.x * k, a.y * k);
    }
    public struct Vector4 { public float x, y, z, w; public Vector4(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; } }
    public struct Vector3
    {
        public float x, y, z;
        public Vector3(float x, float y, float z) { this.x = x; this.y = y; this.z = z; }
        public Vector3(float x, float y) { this.x = x; this.y = y; z = 0; }
        public static Vector3 zero => new Vector3(0, 0, 0);
        public static Vector3 one => new Vector3(1, 1, 1);
        public static Vector3 up => new Vector3(0, 1, 0);
        public static Vector3 down => new Vector3(0, -1, 0);
        public static Vector3 forward => new Vector3(0, 0, 1);
        public static Vector3 back => new Vector3(0, 0, -1);
        public static Vector3 right => new Vector3(1, 0, 0);
        public float sqrMagnitude => x * x + y * y + z * z;
        public float magnitude => (float)Math.Sqrt(sqrMagnitude);
        public Vector3 normalized { get { float m = magnitude; return m > 1e-6f ? this * (1f / m) : zero; } }
        public void Normalize() { this = normalized; }
        public static Vector3 Cross(Vector3 a, Vector3 b) => new Vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
        public static float Dot(Vector3 a, Vector3 b) => a.x * b.x + a.y * b.y + a.z * b.z;
        public static Vector3 Lerp(Vector3 a, Vector3 b, float t) { t = Mathf.Clamp01(t); return a + (b - a) * t; }
        public static Vector3 LerpUnclamped(Vector3 a, Vector3 b, float t) => a + (b - a) * t;
        public static Vector3 operator +(Vector3 a, Vector3 b) => new Vector3(a.x + b.x, a.y + b.y, a.z + b.z);
        public static Vector3 operator -(Vector3 a, Vector3 b) => new Vector3(a.x - b.x, a.y - b.y, a.z - b.z);
        public static Vector3 operator -(Vector3 a) => new Vector3(-a.x, -a.y, -a.z);
        public static Vector3 operator *(Vector3 a, float k) => new Vector3(a.x * k, a.y * k, a.z * k);
        public static Vector3 operator *(float k, Vector3 a) => a * k;
        public static Vector3 operator /(Vector3 a, float k) => a * (1f / k);
    }
    public struct Quaternion
    {
        public float x, y, z, w;
        public Quaternion(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; }
        public static Quaternion identity => new Quaternion(0, 0, 0, 1);
        static Quaternion Axis(Vector3 a, float deg) { float h = deg * Mathf.Deg2Rad * 0.5f; float s = (float)Math.Sin(h); return new Quaternion(a.x * s, a.y * s, a.z * s, (float)Math.Cos(h)); }
        public static Quaternion Euler(float x, float y, float z) => Axis(Vector3.up, y) * Axis(Vector3.right, x) * Axis(Vector3.forward, z);
        public static Quaternion operator *(Quaternion a, Quaternion b) => new Quaternion(
            a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
            a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
            a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
            a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z);
        public static Vector3 operator *(Quaternion q, Vector3 v)
        {
            var u = new Vector3(q.x, q.y, q.z);
            var t = Vector3.Cross(u, v) * 2f;
            return v + t * q.w + Vector3.Cross(u, t);
        }
        public static Quaternion FromToRotation(Vector3 from, Vector3 to)
        {
            from = from.normalized; to = to.normalized;
            float d = Vector3.Dot(from, to);
            if (d > 0.99999f) return identity;
            if (d < -0.99999f) { var ax = Vector3.Cross(Vector3.right, from); if (ax.sqrMagnitude < 1e-6f) ax = Vector3.Cross(Vector3.up, from); return Axis(ax.normalized, 180f); }
            var c = Vector3.Cross(from, to);
            var q = new Quaternion(c.x, c.y, c.z, 1f + d);
            float m = (float)Math.Sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
            return new Quaternion(q.x / m, q.y / m, q.z / m, q.w / m);
        }
        public static Quaternion LookRotation(Vector3 f, Vector3 up)
        {
            f = f.normalized; var r = Vector3.Cross(up, f).normalized; var u = Vector3.Cross(f, r);
            float m00 = r.x, m01 = u.x, m02 = f.x, m10 = r.y, m11 = u.y, m12 = f.y, m20 = r.z, m21 = u.z, m22 = f.z;
            float tr = m00 + m11 + m22; Quaternion q;
            if (tr > 0) { float s = (float)Math.Sqrt(tr + 1) * 2; q = new Quaternion((m21 - m12) / s, (m02 - m20) / s, (m10 - m01) / s, 0.25f * s); }
            else if (m00 > m11 && m00 > m22) { float s = (float)Math.Sqrt(1 + m00 - m11 - m22) * 2; q = new Quaternion(0.25f * s, (m01 + m10) / s, (m02 + m20) / s, (m21 - m12) / s); }
            else if (m11 > m22) { float s = (float)Math.Sqrt(1 + m11 - m00 - m22) * 2; q = new Quaternion((m01 + m10) / s, 0.25f * s, (m12 + m21) / s, (m02 - m20) / s); }
            else { float s = (float)Math.Sqrt(1 + m22 - m00 - m11) * 2; q = new Quaternion((m02 + m20) / s, (m12 + m21) / s, 0.25f * s, (m10 - m01) / s); }
            return q;
        }
    }
    public struct Matrix4x4
    {
        public Quaternion r; public Vector3 t, s; public bool hasParent; public Vector3[] chainT; // simple affine as 3x4
        public float[] m;
        public static Matrix4x4 identity { get { var x = new Matrix4x4 { m = new float[12] }; x.m[0] = x.m[5] = x.m[10] = 1; return x; } }
        public static Matrix4x4 TRS(Vector3 p, Quaternion q, Vector3 sc)
        {
            var ex = q * new Vector3(sc.x, 0, 0); var ey = q * new Vector3(0, sc.y, 0); var ez = q * new Vector3(0, 0, sc.z);
            var x = new Matrix4x4 { m = new float[12] };
            x.m[0] = ex.x; x.m[1] = ey.x; x.m[2] = ez.x; x.m[3] = p.x;
            x.m[4] = ex.y; x.m[5] = ey.y; x.m[6] = ez.y; x.m[7] = p.y;
            x.m[8] = ex.z; x.m[9] = ey.z; x.m[10] = ez.z; x.m[11] = p.z;
            return x;
        }
        public static Matrix4x4 operator *(Matrix4x4 a, Matrix4x4 b)
        {
            var r = new Matrix4x4 { m = new float[12] };
            for (int i = 0; i < 3; i++)
            {
                for (int j = 0; j < 4; j++)
                {
                    float v = a.m[i * 4] * b.m[j] + a.m[i * 4 + 1] * b.m[4 + j] + a.m[i * 4 + 2] * b.m[8 + j];
                    if (j == 3) v += a.m[i * 4 + 3];
                    r.m[i * 4 + j] = v;
                }
            }
            return r;
        }
        public Vector3 MultiplyPoint3x4(Vector3 p) => new Vector3(m[0] * p.x + m[1] * p.y + m[2] * p.z + m[3], m[4] * p.x + m[5] * p.y + m[6] * p.z + m[7], m[8] * p.x + m[9] * p.y + m[10] * p.z + m[11]);
    }
    public struct Color
    {
        public float r, g, b, a;
        public Color(float r, float g, float b, float a = 1) { this.r = r; this.g = g; this.b = b; this.a = a; }
        public static Color white => new Color(1, 1, 1); public static Color black => new Color(0, 0, 0); public static Color gray => new Color(.5f, .5f, .5f);
        public static Color Lerp(Color x, Color y, float t) { t = Mathf.Clamp01(t); return new Color(x.r + (y.r - x.r) * t, x.g + (y.g - x.g) * t, x.b + (y.b - x.b) * t, x.a + (y.a - x.a) * t); }
        public Color linear => new Color((float)Math.Pow(r, 2.2), (float)Math.Pow(g, 2.2), (float)Math.Pow(b, 2.2), a);
        public static Color operator *(Color c, float k) => new Color(c.r * k, c.g * k, c.b * k, c.a * k);
        public static Color operator +(Color x, Color y) => new Color(x.r + y.r, x.g + y.g, x.b + y.b, x.a + y.a);
        public static bool operator ==(Color x, Color y) => x.r == y.r && x.g == y.g && x.b == y.b && x.a == y.a;
        public static bool operator !=(Color x, Color y) => !(x == y);
        public override bool Equals(object o) => o is Color c && c == this; public override int GetHashCode() => 0;
        public static implicit operator Color32(Color c) => new Color32((byte)(Mathf.Clamp01(c.r) * 255), (byte)(Mathf.Clamp01(c.g) * 255), (byte)(Mathf.Clamp01(c.b) * 255), (byte)(Mathf.Clamp01(c.a) * 255));
    }
    public struct Color32 { public byte r, g, b, a; public Color32(byte r, byte g, byte b, byte a) { this.r = r; this.g = g; this.b = b; this.a = a; } }
    public static class ColorUtility { public static bool TryParseHtmlString(string s, out Color c) { c = new Color(Convert.ToInt32(s.Substring(1, 2), 16) / 255f, Convert.ToInt32(s.Substring(3, 2), 16) / 255f, Convert.ToInt32(s.Substring(5, 2), 16) / 255f); return true; } }
    public struct Bounds { public Vector3 min, max; public Vector3 size => max - min; }
    public class Mesh : Object
    {
        public Rendering.IndexFormat indexFormat;
        public List<Vector3> V = new List<Vector3>(); public List<Color32> C = new List<Color32>(); public List<int> T = new List<int>();
        public void SetVertices(List<Vector3> v) => V = new List<Vector3>(v);
        public void SetNormals(List<Vector3> n) { }
        public void SetColors(List<Color32> c) => C = new List<Color32>(c);
        public void SetTriangles(List<int> t, int sub, bool calc) => T = new List<int>(t);
        public void UploadMeshData(bool b) { }
        public Bounds bounds { get { var b = new Bounds { min = new Vector3(1e9f, 1e9f, 1e9f), max = new Vector3(-1e9f, -1e9f, -1e9f) }; foreach (var v in V) { b.min = new Vector3(Math.Min(b.min.x, v.x), Math.Min(b.min.y, v.y), Math.Min(b.min.z, v.z)); b.max = new Vector3(Math.Max(b.max.x, v.x), Math.Max(b.max.y, v.y), Math.Max(b.max.z, v.z)); } return b; } }
    }
    public enum TextureFormat { RGBA32 } public enum TextureWrapMode { Clamp } public enum FilterMode { Bilinear } public enum SpriteMeshType { FullRect }
    public struct Rect { public Rect(float x, float y, float w, float h) { } }
    public class Texture2D : Object
    {
        public int width, height; public Color32[] px; public TextureWrapMode wrapMode; public FilterMode filterMode;
        public Texture2D(int w, int h, TextureFormat f, bool mip) { width = w; height = h; }
        public void SetPixels32(Color32[] p) => px = p; public void Apply(bool a, bool b) { }
    }
    public class Sprite : Object
    {
        public Texture2D texture;
        public static Sprite Create(Texture2D t, Rect r, Vector2 pivot, float ppu, uint extrude = 0, SpriteMeshType m = SpriteMeshType.FullRect, Vector4 border = default) => new Sprite { texture = t };
        public static Sprite Create(Texture2D t, Rect r, Vector2 pivot, float ppu) => new Sprite { texture = t };
    }
}
