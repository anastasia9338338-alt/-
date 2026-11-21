using System.Collections.Generic;
using UnityEngine;

namespace ZooThrow.Visuals
{
    /// <summary>Pooled particle effects and rarity beams, all created in code (no prefabs, no Instantiate during play).</summary>
    public class VfxManager : MonoBehaviour
    {
        ParticleSystem _dust, _confetti, _sparkle, _poof, _coins, _levelUp;
        readonly List<BeamFx> _beams = new List<BeamFx>();
        float _particleScale = 1f;

        class BeamFx
        {
            public Transform t;
            public MeshRenderer r;
            public MaterialPropertyBlock mpb;
            public Color color;
            public float time, duration, intensity;
            public bool active;
        }

        public void Init()
        {
            _dust = Make("Dust", MaterialLibrary.GlowAlpha, 200, 0.9f, 1.2f, 4f, 1.6f, 0.4f, ParticleSystemShapeType.Hemisphere, 1.2f);
            _confetti = Make("Confetti", MaterialLibrary.GlowAlpha, 400, 1.6f, 0.35f, 9f, 1.2f, 1.0f, ParticleSystemShapeType.Cone, 0.6f);
            _sparkle = Make("Sparkle", MaterialLibrary.GlowAdditive, 300, 0.9f, 0.5f, 5f, 0.2f, -0.05f, ParticleSystemShapeType.Sphere, 0.8f);
            _poof = Make("Poof", MaterialLibrary.GlowAlpha, 120, 0.6f, 1.0f, 3f, 0.6f, -0.1f, ParticleSystemShapeType.Sphere, 0.6f);
            _coins = Make("Coins", MaterialLibrary.GlowAdditive, 200, 1.1f, 0.45f, 6f, 0.3f, 1.2f, ParticleSystemShapeType.Cone, 0.3f);
            _levelUp = Make("LevelUp", MaterialLibrary.GlowAdditive, 200, 1.3f, 0.45f, 3f, 0.3f, -0.6f, ParticleSystemShapeType.Circle, 1.2f);
            var cone = _confetti.shape; cone.angle = 35f; cone.rotation = new Vector3(-90f, 0, 0);
            var coinShape = _coins.shape; coinShape.angle = 25f; coinShape.rotation = new Vector3(-90f, 0, 0);
            var circle = _levelUp.shape; circle.rotation = new Vector3(-90f, 0, 0);
        }

        public void SetQuality(int quality) => _particleScale = quality == 0 ? 0.45f : quality == 1 ? 0.75f : 1f;

        ParticleSystem Make(string name, Material mat, int max, float lifetime, float size, float speed, float sizeVariance, float gravity, ParticleSystemShapeType shapeType, float radius)
        {
            var go = new GameObject("VFX_" + name);
            go.transform.SetParent(transform, false);
            var ps = go.AddComponent<ParticleSystem>();
            ps.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
            var main = ps.main;
            main.playOnAwake = false;
            main.loop = false;
            main.duration = 1f;
            main.maxParticles = max;
            main.startLifetime = new ParticleSystem.MinMaxCurve(lifetime * 0.7f, lifetime * 1.2f);
            main.startSize = new ParticleSystem.MinMaxCurve(size * (1f - Mathf.Min(0.9f, sizeVariance * 0.5f)), size * (1f + sizeVariance * 0.5f));
            main.startSpeed = new ParticleSystem.MinMaxCurve(speed * 0.5f, speed);
            main.gravityModifier = gravity;
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            main.scalingMode = ParticleSystemScalingMode.Hierarchy;
            var emission = ps.emission;
            emission.enabled = true;
            emission.rateOverTime = 0f;
            var shape = ps.shape;
            shape.enabled = true;
            shape.shapeType = shapeType;
            shape.radius = radius;
            var col = ps.colorOverLifetime;
            col.enabled = true;
            var grad = new Gradient();
            grad.SetKeys(new[] { new GradientColorKey(Color.white, 0f), new GradientColorKey(Color.white, 1f) },
                         new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0.9f, 0.6f), new GradientAlphaKey(0f, 1f) });
            col.color = grad;
            var sol = ps.sizeOverLifetime;
            sol.enabled = true;
            sol.size = new ParticleSystem.MinMaxCurve(1f, new AnimationCurve(new Keyframe(0, 0.6f), new Keyframe(0.2f, 1f), new Keyframe(1, 0.3f)));
            var r = go.GetComponent<ParticleSystemRenderer>();
            r.sharedMaterial = mat;
            r.renderMode = ParticleSystemRenderMode.Billboard;
            r.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            r.receiveShadows = false;
            return ps;
        }

        void Emit(ParticleSystem ps, Vector3 pos, Color color, int count)
        {
            count = Mathf.Max(1, Mathf.RoundToInt(count * _particleScale));
            ps.transform.position = pos;
            var p = new ParticleSystem.EmitParams { startColor = color, applyShapeToPosition = true };
            ps.Emit(p, count);
        }

        /// <summary>Water splash: a ring of droplets thrown up plus a little sparkle.</summary>
        public void Splash(Vector3 pos, Color water)
        {
            Emit(_confetti, pos + Vector3.up * 0.1f, Color.Lerp(water, Color.white, 0.6f), 22);
            Emit(_dust, pos + Vector3.up * 0.1f, new Color(1f, 1f, 1f, 0.8f), 14);
        }

        public void Landing(Vector3 pos, Color groundColor)
        {
            Emit(_dust, pos + Vector3.up * 0.2f, Color.Lerp(groundColor, Color.white, 0.4f), 26);
        }

        public void Confetti(Vector3 pos, Color rarityColor, int count)
        {
            Color[] palette = { rarityColor, Color.white, new Color(1f, 0.85f, 0.25f), Color.Lerp(rarityColor, Color.white, 0.5f) };
            int per = Mathf.Max(3, count / palette.Length);
            foreach (var c in palette) Emit(_confetti, pos, c, per);
        }

        public void Sparkle(Vector3 pos, Color color, int count) => Emit(_sparkle, pos, color, count);
        public void Poof(Vector3 pos) => Emit(_poof, pos, new Color(1f, 1f, 1f, 0.9f), 18);
        public void Coins(Vector3 pos, int count = 12) => Emit(_coins, pos, new Color(1f, 0.82f, 0.2f), count);

        public void LevelUp(Vector3 pos)
        {
            Emit(_levelUp, pos + Vector3.up * 0.3f, new Color(0.45f, 0.8f, 1f), 40);
            Emit(_sparkle, pos + Vector3.up * 2f, new Color(1f, 0.9f, 0.4f), 20);
        }

        /// <summary>Vertical light pillar for rare rewards, faded in and out over ~2.5 s.</summary>
        public void Beam(Vector3 pos, Color color, float intensity)
        {
            BeamFx b = null;
            foreach (var x in _beams) if (!x.active) { b = x; break; }
            if (b == null)
            {
                b = new BeamFx { mpb = new MaterialPropertyBlock() };
                var go = new GameObject("VFX_Beam");
                go.transform.SetParent(transform, false);
                MaterialLibrary.AddRenderer(go, BeamMesh(), false, MaterialLibrary.GlowAdditive);
                b.t = go.transform;
                b.r = go.GetComponent<MeshRenderer>();
                _beams.Add(b);
            }
            b.active = true;
            b.time = 0f;
            b.duration = 2.6f;
            b.intensity = intensity;
            b.color = color;
            b.t.position = pos;
            b.t.gameObject.SetActive(true);
        }

        static Mesh s_BeamMesh;

        /// <summary>Open cylinder, opaque at the bottom and fading to transparent at the top. UVs point at the
        /// centre of the soft-dot texture so the texture contributes full alpha.</summary>
        static Mesh BeamMesh()
        {
            if (s_BeamMesh != null) return s_BeamMesh;
            const int seg = 16;
            var v = new Vector3[(seg + 1) * 2];
            var c = new Color32[v.Length];
            var uv = new Vector2[v.Length];
            var tris = new int[seg * 6];
            for (int i = 0; i <= seg; i++)
            {
                float a = i * Mathf.PI * 2f / seg;
                var d = new Vector3(Mathf.Cos(a), 0, Mathf.Sin(a));
                v[i * 2] = d;
                v[i * 2 + 1] = d * 0.6f + Vector3.up;
                c[i * 2] = new Color32(255, 255, 255, 255);
                c[i * 2 + 1] = new Color32(255, 255, 255, 0);
                uv[i * 2] = uv[i * 2 + 1] = new Vector2(0.5f, 0.5f);
            }
            for (int i = 0; i < seg; i++)
            {
                int b0 = i * 2, t0 = i * 2 + 1, b1 = i * 2 + 2, t1 = i * 2 + 3, k = i * 6;
                tris[k] = b0; tris[k + 1] = t0; tris[k + 2] = t1;
                tris[k + 3] = b0; tris[k + 4] = t1; tris[k + 5] = b1;
            }
            s_BeamMesh = new Mesh { name = "Beam", vertices = v, colors32 = c, uv = uv, triangles = tris };
            s_BeamMesh.RecalculateBounds();
            return s_BeamMesh;
        }

        void Update()
        {
            float dt = Time.deltaTime;
            foreach (var b in _beams)
            {
                if (!b.active) continue;
                b.time += dt;
                float k = b.time / b.duration;
                if (k >= 1f) { b.active = false; b.t.gameObject.SetActive(false); continue; }
                float fade = Mathf.Sin(Mathf.Clamp01(k) * Mathf.PI);
                float width = Mathf.Lerp(0.6f, 1.4f, Mathf.Min(1f, k * 3f)) * (0.7f + 0.3f * b.intensity);
                b.t.localScale = new Vector3(width, 40f * Mathf.Min(1f, k * 4f), width);
                b.t.Rotate(0, dt * 90f, 0);
                var c = b.color;
                c.a = 0.45f * fade * Mathf.Clamp01(b.intensity);
                b.mpb.SetColor(MaterialLibrary.TintColorId, c);
                b.r.SetPropertyBlock(b.mpb);
            }
        }
    }
}
