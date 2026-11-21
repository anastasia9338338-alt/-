using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace ZooThrow.Visuals
{
    /// <summary>Shared runtime materials. Shaders live in Resources/Shaders so they are always included in builds.</summary>
    public static class MaterialLibrary
    {
        static readonly int SkyAmbientId = Shader.PropertyToID("_ZT_SkyAmbient");
        static readonly int GroundAmbientId = Shader.PropertyToID("_ZT_GroundAmbient");
        static readonly int SunDirectionId = Shader.PropertyToID("_ZT_SunDirection");
        public static readonly int OverlayColorId = Shader.PropertyToID("_OverlayColor");
        public static readonly int EmissionColorId = Shader.PropertyToID("_EmissionColor");
        public static readonly int TintColorId = Shader.PropertyToID("_TintColor");

        public static Material Toon { get; private set; }
        public static Material ToonEmissive { get; private set; }
        public static Material GlowAdditive { get; private set; }
        public static Material GlowAlpha { get; private set; }
        public static Material Sky { get; private set; }
        /// <summary>Opaque-looking unlit material for the fishing line (white texture, colour from vertices).</summary>
        public static Material Line { get; private set; }
        public static Texture2D SoftDot { get; private set; }

        static readonly List<string> s_Missing = new List<string>();
        public static IReadOnlyList<string> MissingShaders => s_Missing;

        public static void Init()
        {
            s_Missing.Clear();
            MeshBuilder.ConvertToLinear = QualitySettings.activeColorSpace == ColorSpace.Linear;
            var toon = Find("ZooThrow/ToonLit", "Universal Render Pipeline/Simple Lit");
            var glow = Find("ZooThrow/Glow", "Universal Render Pipeline/Particles/Unlit");
            var sky = Find("ZooThrow/Sky", "Skybox/Procedural");

            Toon = new Material(toon) { name = "ZT_Toon", enableInstancing = true };
            ToonEmissive = new Material(toon) { name = "ZT_ToonEmissive" };
            ToonEmissive.SetColor(EmissionColorId, new Color(0.25f, 0.25f, 0.25f));

            SoftDot = MakeSoftDot(64);
            GlowAdditive = new Material(glow) { name = "ZT_GlowAdd", mainTexture = SoftDot };
            GlowAdditive.SetFloat("_SrcBlend", (float)BlendMode.SrcAlpha);
            GlowAdditive.SetFloat("_DstBlend", (float)BlendMode.One);
            GlowAlpha = new Material(glow) { name = "ZT_GlowAlpha", mainTexture = SoftDot };
            GlowAlpha.SetFloat("_SrcBlend", (float)BlendMode.SrcAlpha);
            GlowAlpha.SetFloat("_DstBlend", (float)BlendMode.OneMinusSrcAlpha);
            Sky = new Material(sky) { name = "ZT_Sky" };
            Line = new Material(glow) { name = "ZT_Line", mainTexture = Texture2D.whiteTexture };
            Line.SetFloat("_SrcBlend", (float)BlendMode.SrcAlpha);
            Line.SetFloat("_DstBlend", (float)BlendMode.OneMinusSrcAlpha);
        }

        static Shader Find(string name, string fallback)
        {
            var s = Shader.Find(name);
            if (s != null && s.isSupported) return s;
            s_Missing.Add(name);
            Debug.LogError("[ZooThrow] Шейдер не найден или не поддерживается: " + name + ". Проверь, что в проекте активен URP (меню ZooThrow → Настроить проект).");
            s = Shader.Find(fallback);
            return s != null ? s : Shader.Find("Hidden/InternalErrorShader");
        }

        public static void SetAmbient(Color sky, Color ground, Vector3 sunDirection)
        {
            Shader.SetGlobalColor(SkyAmbientId, sky);
            Shader.SetGlobalColor(GroundAmbientId, ground);
            Shader.SetGlobalVector(SunDirectionId, sunDirection.normalized);
        }

        static Texture2D MakeSoftDot(int size)
        {
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false) { name = "ZT_SoftDot", wrapMode = TextureWrapMode.Clamp };
            var px = new Color32[size * size];
            float r = (size - 1) * 0.5f;
            for (int y = 0; y < size; y++)
                for (int x = 0; x < size; x++)
                {
                    float d = Mathf.Sqrt((x - r) * (x - r) + (y - r) * (y - r)) / r;
                    float a = Mathf.Clamp01(1f - d);
                    a = a * a * (3f - 2f * a);
                    px[y * size + x] = new Color32(255, 255, 255, (byte)(a * 255));
                }
            tex.SetPixels32(px);
            tex.Apply(false, true);
            return tex;
        }

        /// <summary>Creates a child renderer with the shared toon material.</summary>
        public static MeshRenderer AddRenderer(GameObject go, Mesh mesh, bool castShadows = true, Material material = null)
        {
            var mf = go.GetComponent<MeshFilter>();
            if (mf == null) mf = go.AddComponent<MeshFilter>();
            mf.sharedMesh = mesh;
            var mr = go.GetComponent<MeshRenderer>();
            if (mr == null) mr = go.AddComponent<MeshRenderer>();
            mr.sharedMaterial = material != null ? material : Toon;
            mr.shadowCastingMode = castShadows ? ShadowCastingMode.On : ShadowCastingMode.Off;
            mr.receiveShadows = true;
            mr.lightProbeUsage = LightProbeUsage.Off;
            mr.reflectionProbeUsage = ReflectionProbeUsage.Off;
            return mr;
        }

        public static GameObject MeshObject(string name, Transform parent, Mesh mesh, Vector3 localPos, bool castShadows = true)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = localPos;
            AddRenderer(go, mesh, castShadows);
            return go;
        }
    }
}
