using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace ZooThrow.Visuals
{
    /// <summary>
    /// Builds flat-shaded low-poly meshes with vertex colours. Every shape is appended through the current
    /// transform matrix, so a whole prop, animal or biome chunk becomes one mesh and one draw call.
    /// </summary>
    public class MeshBuilder
    {
        readonly List<Vector3> _v = new List<Vector3>(1024);
        readonly List<Vector3> _n = new List<Vector3>(1024);
        readonly List<Color32> _c = new List<Color32>(1024);
        readonly List<int> _t = new List<int>(2048);
        Matrix4x4 _m = Matrix4x4.identity;
        readonly Stack<Matrix4x4> _stack = new Stack<Matrix4x4>();

        /// <summary>
        /// Vertex colours bypass Unity's sRGB conversion, so in Linear colour space they are converted here to
        /// look the same as in Gamma space. Set once at startup from QualitySettings.activeColorSpace.
        /// </summary>
        public static bool ConvertToLinear;

        public int VertexCount => _v.Count;

        public void Clear()
        {
            _v.Clear(); _n.Clear(); _c.Clear(); _t.Clear();
            _m = Matrix4x4.identity; _stack.Clear();
        }

        public void Push(Vector3 position, Quaternion rotation, Vector3 scale)
        {
            _stack.Push(_m);
            _m = _m * Matrix4x4.TRS(position, rotation, scale);
        }

        public void Push(Vector3 position, Quaternion rotation) => Push(position, rotation, Vector3.one);
        public void Push(Vector3 position) => Push(position, Quaternion.identity, Vector3.one);
        public void Pop() { if (_stack.Count > 0) _m = _stack.Pop(); }

        // One flat triangle (own vertices, so normals are faceted).
        public void Tri(Vector3 a, Vector3 b, Vector3 c, Color col)
        {
            a = _m.MultiplyPoint3x4(a); b = _m.MultiplyPoint3x4(b); c = _m.MultiplyPoint3x4(c);
            Vector3 n = Vector3.Cross(b - a, c - a);
            if (n.sqrMagnitude < 1e-12f) return;
            n.Normalize();
            int i = _v.Count;
            _v.Add(a); _v.Add(b); _v.Add(c);
            _n.Add(n); _n.Add(n); _n.Add(n);
            Color32 c32 = ConvertToLinear ? col.linear : col;
            _c.Add(c32); _c.Add(c32); _c.Add(c32);
            _t.Add(i); _t.Add(i + 1); _t.Add(i + 2);
        }

        public void Quad(Vector3 a, Vector3 b, Vector3 c, Vector3 d, Color col)
        {
            Tri(a, b, c, col);
            Tri(a, c, d, col);
        }

        /// <summary>Axis-aligned box in local space (before the current matrix), optional tapered top.</summary>
        public void Box(Vector3 center, Vector3 size, Color col, float topScale = 1f)
        {
            Vector3 h = size * 0.5f;
            Vector3 ht = new Vector3(h.x * topScale, h.y, h.z * topScale);
            Vector3 p000 = center + new Vector3(-h.x, -h.y, -h.z), p100 = center + new Vector3(h.x, -h.y, -h.z);
            Vector3 p001 = center + new Vector3(-h.x, -h.y, h.z), p101 = center + new Vector3(h.x, -h.y, h.z);
            Vector3 p010 = center + new Vector3(-ht.x, h.y, -ht.z), p110 = center + new Vector3(ht.x, h.y, -ht.z);
            Vector3 p011 = center + new Vector3(-ht.x, h.y, ht.z), p111 = center + new Vector3(ht.x, h.y, ht.z);
            Quad(p010, p011, p111, p110, col);           // top
            Quad(p000, p100, p101, p001, Shade(col, 0.8f)); // bottom
            Quad(p001, p101, p111, p011, col);           // front (+z)
            Quad(p100, p000, p010, p110, col);           // back (-z)
            Quad(p000, p001, p011, p010, col);           // left (-x)
            Quad(p101, p100, p110, p111, col);           // right (+x)
        }

        public void Box(Vector3 center, Vector3 size, Quaternion rotation, Color col, float topScale = 1f)
        {
            Push(center, rotation);
            Box(Vector3.zero, size, col, topScale);
            Pop();
        }

        /// <summary>Cylinder / frustum along local +Y from base centre.</summary>
        public void Cylinder(Vector3 baseCenter, float radiusBottom, float radiusTop, float height, int segments, Color col, bool caps = true)
        {
            segments = Mathf.Max(3, segments);
            for (int i = 0; i < segments; i++)
            {
                float a0 = i * Mathf.PI * 2f / segments, a1 = (i + 1) * Mathf.PI * 2f / segments;
                Vector3 d0 = new Vector3(Mathf.Cos(a0), 0, Mathf.Sin(a0)), d1 = new Vector3(Mathf.Cos(a1), 0, Mathf.Sin(a1));
                Vector3 b0 = baseCenter + d0 * radiusBottom, b1 = baseCenter + d1 * radiusBottom;
                Vector3 t0 = baseCenter + Vector3.up * height + d0 * radiusTop, t1 = baseCenter + Vector3.up * height + d1 * radiusTop;
                if (radiusTop > 0.0001f) Quad(b0, t0, t1, b1, col);
                else Tri(b0, t0, b1, col);
                if (caps)
                {
                    Tri(baseCenter, b0, b1, Shade(col, 0.8f));
                    if (radiusTop > 0.0001f) Tri(baseCenter + Vector3.up * height, t1, t0, col);
                }
            }
        }

        public void Cone(Vector3 baseCenter, float radius, float height, int segments, Color col) =>
            Cylinder(baseCenter, radius, 0f, height, segments, col);

        /// <summary>Low-poly UV sphere (ellipsoid via size), centred.</summary>
        public void Sphere(Vector3 center, Vector3 size, Color col, int lon = 8, int lat = 5)
        {
            lon = Mathf.Max(3, lon); lat = Mathf.Max(2, lat);
            Vector3 r = size * 0.5f;
            for (int y = 0; y < lat; y++)
            {
                float v0 = Mathf.PI * y / lat - Mathf.PI * 0.5f, v1 = Mathf.PI * (y + 1) / lat - Mathf.PI * 0.5f;
                for (int x = 0; x < lon; x++)
                {
                    float u0 = Mathf.PI * 2f * x / lon, u1 = Mathf.PI * 2f * (x + 1) / lon;
                    Vector3 a = center + Scale(Dir(u0, v0), r), b = center + Scale(Dir(u1, v0), r);
                    Vector3 c = center + Scale(Dir(u1, v1), r), d = center + Scale(Dir(u0, v1), r);
                    if (y == 0) Tri(a, d, c, col);
                    else if (y == lat - 1) Tri(a, d, b, col);
                    else Quad(a, d, c, b, col);
                }
            }
        }

        public void Sphere(Vector3 center, float diameter, Color col, int lon = 8, int lat = 5) =>
            Sphere(center, Vector3.one * diameter, col, lon, lat);

        /// <summary>Flat disc in the XZ plane facing up.</summary>
        public void Disc(Vector3 center, float radius, int segments, Color col)
        {
            for (int i = 0; i < segments; i++)
            {
                float a0 = i * Mathf.PI * 2f / segments, a1 = (i + 1) * Mathf.PI * 2f / segments;
                Tri(center, center + new Vector3(Mathf.Cos(a1), 0, Mathf.Sin(a1)) * radius, center + new Vector3(Mathf.Cos(a0), 0, Mathf.Sin(a0)) * radius, col);
            }
        }

        static Vector3 Dir(float u, float v) => new Vector3(Mathf.Cos(v) * Mathf.Cos(u), Mathf.Sin(v), Mathf.Cos(v) * Mathf.Sin(u));
        static Vector3 Scale(Vector3 a, Vector3 b) => new Vector3(a.x * b.x, a.y * b.y, a.z * b.z);

        public static Color Shade(Color c, float k) => new Color(c.r * k, c.g * k, c.b * k, c.a);

        public static Color Jitter(Color c, System.Random rng, float amount)
        {
            float k = 1f + ((float)rng.NextDouble() * 2f - 1f) * amount;
            return new Color(Mathf.Clamp01(c.r * k), Mathf.Clamp01(c.g * k), Mathf.Clamp01(c.b * k), c.a);
        }

        public Mesh ToMesh(string name)
        {
            var mesh = new Mesh { name = name };
            if (_v.Count > 65000) mesh.indexFormat = IndexFormat.UInt32;
            mesh.SetVertices(_v);
            mesh.SetNormals(_n);
            mesh.SetColors(_c);
            mesh.SetTriangles(_t, 0, true);
            mesh.UploadMeshData(false);
            return mesh;
        }
    }
}
