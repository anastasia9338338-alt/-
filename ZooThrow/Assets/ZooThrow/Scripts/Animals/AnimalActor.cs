using System.Collections.Generic;
using UnityEngine;
using ZooThrow.Data;
using ZooThrow.Visuals;

namespace ZooThrow.Animals
{
    /// <summary>A living animal in the world: procedural model, mutation look, idle/move animation and wandering.</summary>
    public class AnimalActor : MonoBehaviour
    {
        public AnimalData Data { get; private set; }
        public Mutation Mutation { get; private set; }
        public float Height { get; private set; }

        Transform _visual;
        Transform _body;
        readonly List<Transform> _limbTransforms = new List<Transform>();
        readonly List<LimbSpec> _limbSpecs = new List<LimbSpec>();
        readonly List<Renderer> _renderers = new List<Renderer>();
        MaterialPropertyBlock _mpb;

        Vector3 _home;
        float _wanderRadius;
        bool _wander;
        Vector3 _target;
        float _wait;
        float _moving01;
        float _phase;
        float _time;
        float _celebrate = -1f;
        float _speed;
        float _baseScale;
        System.Random _rng;

        public static AnimalActor Create(AnimalData data, Mutation mutation, BalanceSettings balance, Transform parent, Vector3 position, int seed)
        {
            var go = new GameObject("Animal_" + data.id);
            go.transform.SetParent(parent, false);
            go.transform.position = position;
            var actor = go.AddComponent<AnimalActor>();
            actor.Setup(data, mutation, balance, seed);
            return actor;
        }

        void Setup(AnimalData data, Mutation mutation, BalanceSettings balance, int seed)
        {
            Data = data;
            Mutation = mutation;
            _rng = new System.Random(seed);
            _time = (float)_rng.NextDouble() * 10f;
            var model = AnimalModelFactory.Get(data);
            _visual = new GameObject("Visual").transform;
            _visual.SetParent(transform, false);
            _baseScale = Mathf.Max(0.1f, data.size) * (mutation == Mutation.Giant ? balance.giantScale : 1f);
            _visual.localScale = Vector3.one * _baseScale;
            _body = new GameObject("Body").transform;
            _body.SetParent(_visual, false);
            _renderers.Add(MaterialLibrary.AddRenderer(_body.gameObject, model.body));
            foreach (var limb in model.limbs)
            {
                var t = new GameObject(limb.kind.ToString()).transform;
                t.SetParent(_body, false);
                t.localPosition = limb.pivot;
                if (limb.kind == LimbKind.Wing && limb.side < 0) t.localScale = new Vector3(-1f, 1f, 1f);
                _renderers.Add(MaterialLibrary.AddRenderer(t.gameObject, limb.mesh));
                _limbTransforms.Add(t);
                _limbSpecs.Add(limb);
            }
            Height = model.height * _baseScale;
            _speed = SpeedFor(data.movement) * Mathf.Lerp(1f, data.size, 0.5f);
            ApplyMutationLook(0f);
        }

        static float SpeedFor(MovementStyle m)
        {
            switch (m)
            {
                case MovementStyle.Hop: return 1.6f;
                case MovementStyle.Fly: return 1.5f;
                case MovementStyle.Swim: return 1.1f;
                case MovementStyle.Slither: return 0.45f;
                default: return 1.2f;
            }
        }

        public void SetWander(Vector3 home, float radius)
        {
            _home = home;
            _wanderRadius = radius;
            _wander = radius > 0.05f;
            _target = transform.position;
            _wait = (float)_rng.NextDouble() * 2f;
        }

        public void StopWander() => _wander = false;

        public void Celebrate() => _celebrate = 0f;

        void ApplyMutationLook(float t)
        {
            if (_mpb == null) _mpb = new MaterialPropertyBlock();
            Color overlay = new Color(1, 1, 1, 0), emission = Color.black;
            switch (Mutation)
            {
                case Mutation.Golden:
                    overlay = new Color(1f, 0.78f, 0.2f, 0.6f);
                    emission = new Color(0.22f, 0.15f, 0.02f) * (0.8f + 0.2f * Mathf.Sin(t * 3f));
                    break;
                case Mutation.Rainbow:
                    var c = Color.HSVToRGB(Mathf.Repeat(t * 0.25f, 1f), 0.75f, 1f);
                    overlay = new Color(c.r, c.g, c.b, 0.55f);
                    emission = c * 0.12f;
                    break;
            }
            _mpb.SetColor(MaterialLibrary.OverlayColorId, overlay);
            _mpb.SetColor(MaterialLibrary.EmissionColorId, emission);
            for (int i = 0; i < _renderers.Count; i++) _renderers[i].SetPropertyBlock(_mpb);
        }

        void Update()
        {
            float dt = Time.deltaTime;
            _time += dt;
            if (Mutation == Mutation.Rainbow || Mutation == Mutation.Golden) ApplyMutationLook(_time);

            bool moving = false;
            if (_wander)
            {
                Vector3 pos = transform.position;
                Vector3 to = _target - pos;
                to.y = 0;
                if (_wait > 0f)
                {
                    _wait -= dt;
                    if (_wait <= 0f) PickTarget();
                }
                else if (to.magnitude < 0.15f)
                {
                    _wait = 1.5f + (float)_rng.NextDouble() * 3.5f;
                }
                else
                {
                    moving = true;
                    Vector3 step = to.normalized * Mathf.Min(_speed * dt, to.magnitude);
                    transform.position = pos + step;
                    var look = Quaternion.LookRotation(to.normalized, Vector3.up);
                    transform.rotation = Quaternion.Slerp(transform.rotation, look, 1f - Mathf.Exp(-6f * dt));
                }
            }
            _moving01 = Mathf.MoveTowards(_moving01, moving ? 1f : 0f, dt * 4f);
            _phase += dt * (moving ? 9f : 2f) * (Data.movement == MovementStyle.Hop ? 0.7f : 1f);
            Animate(dt);
        }

        void PickTarget()
        {
            float a = (float)_rng.NextDouble() * Mathf.PI * 2f;
            float r = Mathf.Sqrt((float)_rng.NextDouble()) * _wanderRadius;
            _target = _home + new Vector3(Mathf.Cos(a) * r, 0, Mathf.Sin(a) * r);
        }

        void Animate(float dt)
        {
            float bodyY = 0f, roll = 0f, pitch = 0f;
            float breathe = 1f + Mathf.Sin(_time * 2.2f) * 0.025f;
            Vector3 scale = new Vector3(1f, breathe, 1f);
            switch (Data.movement)
            {
                case MovementStyle.Walk:
                    bodyY = Mathf.Abs(Mathf.Sin(_phase)) * 0.06f * _moving01;
                    roll = Mathf.Sin(_phase) * 3f * _moving01;
                    break;
                case MovementStyle.Hop:
                    {
                        float hop = Mathf.Abs(Mathf.Sin(_phase * 0.9f));
                        bodyY = hop * 0.35f * _moving01 + (_moving01 < 0.01f ? Mathf.Max(0f, Mathf.Sin(_time * 1.3f) - 0.92f) * 2.5f : 0f);
                        pitch = -hop * 12f * _moving01;
                        break;
                    }
                case MovementStyle.Fly:
                    bodyY = 0.9f + Mathf.Sin(_time * 2f) * 0.15f;
                    pitch = 8f * _moving01;
                    roll = Mathf.Sin(_time * 1.3f) * 6f;
                    break;
                case MovementStyle.Swim:
                    bodyY = 0.35f + Mathf.Sin(_time * 1.6f) * 0.12f;
                    roll = Mathf.Sin(_time * 1.2f) * 10f;
                    pitch = Mathf.Sin(_time * 1.6f + 1f) * 6f;
                    break;
                case MovementStyle.Slither:
                    scale = new Vector3(1f, breathe, 1f + Mathf.Sin(_time * 3f) * 0.08f);
                    break;
            }

            float yaw = 0f;
            if (_celebrate >= 0f)
            {
                _celebrate += dt;
                float c = Mathf.Clamp01(_celebrate / 0.9f);
                bodyY += Mathf.Sin(c * Mathf.PI) * 1.2f;
                yaw = c * 360f;
                if (_celebrate >= 0.9f) _celebrate = -1f;
            }

            _body.localPosition = new Vector3(0, bodyY, 0);
            _body.localRotation = Quaternion.Euler(pitch, yaw, roll);
            _body.localScale = scale;

            for (int i = 0; i < _limbTransforms.Count; i++)
            {
                var spec = _limbSpecs[i];
                var t = _limbTransforms[i];
                switch (spec.kind)
                {
                    case LimbKind.Leg:
                        {
                            float swing = Data.movement == MovementStyle.Hop ? Mathf.Sin(_phase * 0.9f) * 30f : Mathf.Sin(_phase + spec.phase) * 35f;
                            if (Data.movement == MovementStyle.Fly) swing = 25f;
                            t.localRotation = Quaternion.Euler(swing * Mathf.Max(_moving01, Data.movement == MovementStyle.Fly ? 1f : 0f), 0, 0);
                            break;
                        }
                    case LimbKind.Arm:
                        t.localRotation = Quaternion.Euler(Mathf.Sin(_phase + spec.phase) * 40f * _moving01 + Mathf.Sin(_time * 1.5f) * 4f, 0, spec.side * 8f);
                        break;
                    case LimbKind.Wing:
                        {
                            bool flying = Data.movement == MovementStyle.Fly;
                            bool swimming = Data.movement == MovementStyle.Swim;
                            // Flyers beat fast, swimmers (rays, sea dragons) glide with slow strokes, others keep wings folded.
                            float flap = flying ? Mathf.Sin(_time * 11f) * 40f + 5f
                                       : swimming ? Mathf.Sin(_time * 2.2f) * 28f
                                       : Mathf.Sin(_time * 1.5f) * 4f - 55f;
                            // The left wing is mirrored with a negative x scale, so it needs the opposite z angle.
                            t.localRotation = Quaternion.Euler(0, 0, flap * spec.side);
                            break;
                        }
                }
            }
        }
    }
}
