using System;
using UnityEngine;
using ZooThrow.Visuals;

namespace ZooThrow.Throwing
{
    /// <summary>
    /// Reusable bobber with the bait under it. Flies along an exact ballistic arc so it lands on the computed
    /// distance, then floats on the water until the bite.
    /// </summary>
    public class CastProjectile : MonoBehaviour
    {
        MeshFilter _baitMf;
        TrailRenderer _trail;
        Vector3 _start, _end;
        float _height, _duration, _t;
        float _floatTime, _dip;
        Action<Vector3> _onLanded;
        public bool Flying { get; private set; }
        public bool Floating { get; private set; }

        static Mesh s_BobberMesh;

        static Mesh BobberMesh()
        {
            if (s_BobberMesh != null) return s_BobberMesh;
            var mb = new MeshBuilder();
            mb.Sphere(new Vector3(0, -0.04f, 0), new Vector3(0.34f, 0.3f, 0.34f), Color.white, 10, 6);
            mb.Sphere(new Vector3(0, 0.06f, 0), new Vector3(0.32f, 0.24f, 0.32f), new Color(0.92f, 0.15f, 0.15f), 10, 5);
            mb.Cylinder(new Vector3(0, 0.15f, 0), 0.025f, 0.02f, 0.25f, 6, new Color(0.92f, 0.15f, 0.15f));
            mb.Cylinder(new Vector3(0, -0.4f, 0), 0.01f, 0.01f, 0.25f, 4, new Color(0.85f, 0.85f, 0.9f));
            s_BobberMesh = mb.ToMesh("Bobber");
            return s_BobberMesh;
        }

        public static CastProjectile Create(Transform parent)
        {
            var go = new GameObject("CastProjectile");
            go.transform.SetParent(parent, false);
            var p = go.AddComponent<CastProjectile>();
            var bobber = new GameObject("Bobber");
            bobber.transform.SetParent(go.transform, false);
            bobber.transform.localScale = Vector3.one * 1.6f;
            MaterialLibrary.AddRenderer(bobber, BobberMesh(), false);
            var bait = new GameObject("Bait");
            bait.transform.SetParent(go.transform, false);
            bait.transform.localPosition = new Vector3(0, -0.75f, 0);
            bait.transform.localScale = Vector3.one * 1.4f;
            MaterialLibrary.AddRenderer(bait, null, false);
            p._baitMf = bait.GetComponent<MeshFilter>();
            p._trail = go.AddComponent<TrailRenderer>();
            p._trail.sharedMaterial = MaterialLibrary.GlowAdditive;
            p._trail.time = 0.5f;
            p._trail.minVertexDistance = 0.4f;
            p._trail.widthCurve = new AnimationCurve(new Keyframe(0, 0.7f), new Keyframe(1, 0f));
            p._trail.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            p._trail.receiveShadows = false;
            p._trail.emitting = false;
            go.SetActive(false);
            return p;
        }

        public void Launch(Mesh baitMesh, Vector3 start, Vector3 end, float height, float duration, Color trailColor, Action<Vector3> onLanded)
        {
            _baitMf.sharedMesh = baitMesh;
            _start = start; _end = end; _height = height; _duration = Mathf.Max(0.2f, duration); _t = 0f;
            _onLanded = onLanded;
            transform.SetPositionAndRotation(start, Quaternion.identity);
            gameObject.SetActive(true);
            _trail.Clear();
            var grad = new Gradient();
            grad.SetKeys(new[] { new GradientColorKey(trailColor, 0f), new GradientColorKey(Color.white, 1f) },
                         new[] { new GradientAlphaKey(0.7f, 0f), new GradientAlphaKey(0f, 1f) });
            _trail.colorGradient = grad;
            _trail.emitting = true;
            Flying = true;
            Floating = false;
        }

        /// <summary>A fish takes the bait: the bobber is pulled under for a moment.</summary>
        public void Dip() => _dip = 0.45f;

        void Update()
        {
            if (Flying)
            {
                _t += Time.deltaTime / _duration;
                transform.position = ThrowMath.ArcPoint(_start, _end, _height, _t);
                transform.rotation = Quaternion.Euler(Mathf.Sin(_t * 20f) * 25f, 0, Mathf.Cos(_t * 17f) * 25f);
                if (_t >= 1f)
                {
                    Flying = false;
                    Floating = true;
                    _floatTime = 0f;
                    _trail.emitting = false;
                    transform.SetPositionAndRotation(_end, Quaternion.identity);
                    var cb = _onLanded;
                    _onLanded = null;
                    cb?.Invoke(_end);
                }
            }
            else if (Floating)
            {
                _floatTime += Time.deltaTime;
                _dip = Mathf.MoveTowards(_dip, 0f, Time.deltaTime * 0.8f);
                transform.position = _end + Vector3.up * (Mathf.Sin(_floatTime * 3f) * 0.06f - _dip);
                transform.rotation = Quaternion.Euler(Mathf.Sin(_floatTime * 2.3f) * 6f, 0, Mathf.Cos(_floatTime * 1.9f) * 6f);
            }
        }

        public void Hide()
        {
            Flying = false;
            Floating = false;
            _trail.emitting = false;
            gameObject.SetActive(false);
        }
    }
}
