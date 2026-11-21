using UnityEngine;
using ZooThrow.Core;

namespace ZooThrow.CameraSystem
{
    public enum CameraMode { Follow, Aim, Projectile, Showcase }

    /// <summary>Orbit camera with collision, plus cinematic modes for aiming, the food flight and the reward reveal.</summary>
    public class ThirdPersonCamera : MonoBehaviour
    {
        public Camera Cam { get; private set; }
        public CameraMode Mode { get; private set; } = CameraMode.Follow;

        public float minDistance = 3.5f, maxDistance = 20f;
        public float minPitch = -15f, maxPitch = 70f;
        const int IgnoreRaycastLayerMask = 1 << 2;

        GameManager _g;
        Transform _player;
        Transform _projectile;
        Vector3 _showcasePoint;
        float _showcaseAngle;
        float _showcaseScale = 1f;
        float _yaw, _pitch = 16f, _distance = 10f, _targetDistance = 10f;
        float _shake;
        Vector3 _smoothPos;
        Quaternion _smoothRot = Quaternion.identity;
        float _modeBlend = 1f;

        public void Init(GameManager g, Transform player, Camera cam)
        {
            _g = g;
            _player = player;
            Cam = cam;
            _yaw = player.eulerAngles.y;
            _smoothPos = player.position + new Vector3(0, 4, -10);
            transform.position = _smoothPos;
        }

        public float Yaw => _yaw;

        public void SetFollow() { Mode = CameraMode.Follow; _modeBlend = 0f; }
        public void SetAim() { Mode = CameraMode.Aim; _modeBlend = 0f; }
        public void SetProjectile(Transform projectile) { _projectile = projectile; Mode = CameraMode.Projectile; _modeBlend = 0f; }
        public void SetShowcase(Vector3 point, float subjectHeight = 1.5f)
        {
            _showcasePoint = point;
            _showcaseScale = Mathf.Max(1f, subjectHeight / 2f);
            _showcaseAngle = -35f;
            Mode = CameraMode.Showcase;
            _modeBlend = 0f;
        }
        public void Shake(float amount)
        {
            if (_g != null && !_g.State.settings.cameraShake) return;
            _shake = Mathf.Max(_shake, amount);
        }
        public void LookFromBehind(float yaw) { _yaw = yaw; _pitch = 16f; }

        void LateUpdate()
        {
            if (_player == null || _g == null) return;
            float dt = Time.deltaTime;
            var settings = _g.State.settings;
            bool look = Cursor.lockState == CursorLockMode.Locked || GameInput.SecondaryHeld;
            if (look && Mode == CameraMode.Follow && !_g.UI.BlocksCameraLook)
            {
                Vector2 d = GameInput.MouseDelta * (0.11f * settings.mouseSensitivity);
                _yaw += d.x;
                _pitch += (settings.invertY ? d.y : -d.y);
                _pitch = Mathf.Clamp(_pitch, minPitch, maxPitch);
            }
            if (!_g.UI.PointerOverUI && Mode == CameraMode.Follow)
                _targetDistance = Mathf.Clamp(_targetDistance - GameInput.Scroll * 1.5f, minDistance, maxDistance);
            _distance = Mathf.Lerp(_distance, _targetDistance, 1f - Mathf.Exp(-10f * dt));

            Vector3 desiredPos;
            Quaternion desiredRot;
            float sharpness;
            switch (Mode)
            {
                case CameraMode.Aim:
                    {
                        Vector3 pivot = _player.position + Vector3.up * 2.6f;
                        desiredPos = pivot + _player.rotation * new Vector3(2.2f, 1.2f, -6.5f);
                        Vector3 lookAt = _player.position + _player.forward * 45f + Vector3.up * 6f;
                        desiredRot = Quaternion.LookRotation(lookAt - desiredPos, Vector3.up);
                        sharpness = 6f;
                        break;
                    }
                case CameraMode.Projectile:
                    {
                        Vector3 p = _projectile != null ? _projectile.position : _player.position;
                        desiredPos = p + new Vector3(4.5f, 4.5f, -13f);
                        desiredRot = Quaternion.LookRotation(p + Vector3.forward * 6f - desiredPos, Vector3.up);
                        sharpness = 9f;
                        break;
                    }
                case CameraMode.Showcase:
                    {
                        _showcaseAngle += dt * 18f;
                        // Big monsters get a camera that backs off and looks higher.
                        Vector3 offset = Quaternion.Euler(0, _showcaseAngle, 0) * new Vector3(0, 3.2f, -8.5f) * _showcaseScale;
                        desiredPos = _showcasePoint + offset;
                        desiredRot = Quaternion.LookRotation(_showcasePoint + Vector3.up * 1.2f * _showcaseScale - desiredPos, Vector3.up);
                        sharpness = 5f;
                        break;
                    }
                default:
                    {
                        Quaternion rot = Quaternion.Euler(_pitch, _yaw, 0);
                        Vector3 pivot = _player.position + Vector3.up * 2.0f;
                        Vector3 dir = rot * Vector3.back;
                        float dist = _distance;
                        if (Physics.SphereCast(pivot, 0.35f, dir, out var hit, dist, ~IgnoreRaycastLayerMask, QueryTriggerInteraction.Ignore))
                            dist = Mathf.Max(0.8f, hit.distance - 0.1f);
                        desiredPos = pivot + dir * dist;
                        desiredRot = rot;
                        sharpness = 30f;
                        break;
                    }
            }

            // Mode switches ease in over ~0.6 s; steady following is tight.
            _modeBlend = Mathf.MoveTowards(_modeBlend, 1f, dt * 1.6f);
            float k = 1f - Mathf.Exp(-Mathf.Lerp(4f, sharpness, _modeBlend) * dt);
            _smoothPos = Vector3.Lerp(_smoothPos, desiredPos, k);
            _smoothRot = Quaternion.Slerp(_smoothRot, desiredRot, k);

            Vector3 shakeOffset = Vector3.zero;
            if (_shake > 0.001f)
            {
                float t = Time.time * 25f;
                shakeOffset = new Vector3(Mathf.PerlinNoise(t, 0.3f) - 0.5f, Mathf.PerlinNoise(0.7f, t) - 0.5f, 0) * _shake;
                _shake = Mathf.MoveTowards(_shake, 0f, dt * 2.5f);
            }
            transform.SetPositionAndRotation(_smoothPos + _smoothRot * shakeOffset, _smoothRot);
        }
    }
}
