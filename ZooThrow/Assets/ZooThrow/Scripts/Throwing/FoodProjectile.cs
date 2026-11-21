using System;
using UnityEngine;
using ZooThrow.Visuals;

namespace ZooThrow.Throwing
{
    /// <summary>Reusable flying food. The path is an exact ballistic arc so it lands on the computed distance.</summary>
    public class FoodProjectile : MonoBehaviour
    {
        MeshFilter _mf;
        TrailRenderer _trail;
        Vector3 _start, _end;
        float _height, _duration, _t;
        Vector3 _spinAxis;
        float _spinSpeed;
        Action<Vector3> _onLanded;
        public bool Flying { get; private set; }

        public static FoodProjectile Create(Transform parent)
        {
            var go = new GameObject("FoodProjectile");
            go.transform.SetParent(parent, false);
            var p = go.AddComponent<FoodProjectile>();
            var model = new GameObject("Model");
            model.transform.SetParent(go.transform, false);
            model.transform.localScale = Vector3.one * 1.8f;
            MaterialLibrary.AddRenderer(model, null);
            p._mf = model.GetComponent<MeshFilter>();
            p._trail = go.AddComponent<TrailRenderer>();
            p._trail.sharedMaterial = MaterialLibrary.GlowAdditive;
            p._trail.time = 0.6f;
            p._trail.minVertexDistance = 0.4f;
            p._trail.widthCurve = new AnimationCurve(new Keyframe(0, 0.9f), new Keyframe(1, 0f));
            p._trail.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            p._trail.receiveShadows = false;
            p._trail.emitting = false;
            go.SetActive(false);
            return p;
        }

        public void Launch(Mesh mesh, Vector3 start, Vector3 end, float height, float duration, Color trailColor, Action<Vector3> onLanded)
        {
            _mf.sharedMesh = mesh;
            _start = start; _end = end; _height = height; _duration = Mathf.Max(0.2f, duration); _t = 0f;
            _onLanded = onLanded;
            _spinAxis = new Vector3(1f, UnityEngine.Random.Range(-0.4f, 0.4f), UnityEngine.Random.Range(-0.3f, 0.3f)).normalized;
            _spinSpeed = UnityEngine.Random.Range(500f, 800f);
            transform.position = start;
            gameObject.SetActive(true);
            _trail.Clear();
            var grad = new Gradient();
            grad.SetKeys(new[] { new GradientColorKey(trailColor, 0f), new GradientColorKey(Color.white, 1f) },
                         new[] { new GradientAlphaKey(0.8f, 0f), new GradientAlphaKey(0f, 1f) });
            _trail.colorGradient = grad;
            _trail.emitting = true;
            Flying = true;
        }

        void Update()
        {
            if (!Flying) return;
            _t += Time.deltaTime / _duration;
            transform.position = ThrowMath.ArcPoint(_start, _end, _height, _t);
            transform.Rotate(_spinAxis, _spinSpeed * Time.deltaTime, Space.World);
            if (_t >= 1f)
            {
                Flying = false;
                _trail.emitting = false;
                transform.position = _end;
                var cb = _onLanded;
                _onLanded = null;
                cb?.Invoke(_end);
            }
        }

        public void Hide()
        {
            Flying = false;
            _trail.emitting = false;
            gameObject.SetActive(false);
        }
    }
}
