using System;
using System.Collections.Generic;
using UnityEngine;

namespace ZooThrow.Visuals
{
    /// <summary>
    /// Renders 3D models into small RenderTextures for UI cards (animals, food, trainers). One portrait per frame,
    /// on an isolated layer far below the map, with a camera that is enabled only while work is queued.
    /// </summary>
    public class PortraitRenderer : MonoBehaviour
    {
        public const int Layer = 30;
        const int Size = 160;
        static readonly Vector3 StagePosition = new Vector3(0f, -600f, 0f);

        class Job
        {
            public string key;
            public RenderTexture rt;
            public Func<Transform, float> build; // builds under the stage root and returns the model's size
            public float yaw;
        }

        readonly Dictionary<string, RenderTexture> _done = new Dictionary<string, RenderTexture>();
        readonly Queue<Job> _queue = new Queue<Job>();
        Camera _cam;
        Transform _stage;
        Job _current;
        GameObject _currentModel;

        public void Init()
        {
            _stage = new GameObject("PortraitStage").transform;
            _stage.SetParent(transform, false);
            _stage.position = StagePosition;
            var camGo = new GameObject("PortraitCamera");
            camGo.transform.SetParent(transform, false);
            _cam = camGo.AddComponent<Camera>();
            _cam.cullingMask = 1 << Layer;
            _cam.clearFlags = CameraClearFlags.SolidColor;
            _cam.backgroundColor = new Color(0f, 0f, 0f, 0f);
            _cam.fieldOfView = 26f;
            _cam.nearClipPlane = 0.1f;
            _cam.farClipPlane = 60f;
            _cam.allowMSAA = false;
            _cam.allowHDR = false;
            _cam.enabled = false;
            _cam.depth = -10;
        }

        /// <summary>Returns the portrait texture for a key, queueing a render if needed. The texture fills in a frame later.</summary>
        public RenderTexture Get(string key, Func<Transform, float> build, float yaw = 150f)
        {
            if (_done.TryGetValue(key, out var rt)) return rt;
            rt = new RenderTexture(Size, Size, 16, RenderTextureFormat.ARGB32) { name = "Portrait_" + key, antiAliasing = 1 };
            rt.Create();
            _done[key] = rt;
            _queue.Enqueue(new Job { key = key, rt = rt, build = build, yaw = yaw });
            return rt;
        }

        void LateUpdate()
        {
            // Clean up the model rendered last frame.
            if (_currentModel != null)
            {
                Destroy(_currentModel);
                _currentModel = null;
            }
            _current = null;
            if (_queue.Count == 0)
            {
                _cam.enabled = false;
                return;
            }
            _current = _queue.Dequeue();
            if (_current.rt == null || !_current.rt.IsCreated()) _current.rt?.Create();
            _currentModel = new GameObject("Portrait_" + _current.key);
            _currentModel.transform.SetParent(_stage, false);
            float size = Mathf.Max(0.3f, _current.build(_currentModel.transform));
            _currentModel.transform.localRotation = Quaternion.Euler(0, _current.yaw, 0);
            SetLayerRecursive(_currentModel.transform, Layer);
            foreach (var r in _currentModel.GetComponentsInChildren<Renderer>())
                r.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            foreach (var b in _currentModel.GetComponentsInChildren<MonoBehaviour>()) b.enabled = false;

            Vector3 center = StagePosition + Vector3.up * size * 0.45f;
            float dist = size * 2.6f + 0.6f;
            _cam.transform.position = center + new Vector3(0f, size * 0.35f, -dist);
            _cam.transform.LookAt(center);
            _cam.targetTexture = _current.rt;
            _cam.enabled = true;
        }

        static void SetLayerRecursive(Transform t, int layer)
        {
            t.gameObject.layer = layer;
            for (int i = 0; i < t.childCount; i++) SetLayerRecursive(t.GetChild(i), layer);
        }
    }
}
