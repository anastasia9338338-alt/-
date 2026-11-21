using UnityEngine;
using ZooThrow.Core;

namespace ZooThrow.Player
{
    [RequireComponent(typeof(CharacterController))]
    public class PlayerController : MonoBehaviour
    {
        public float walkSpeed = 7f;
        public float runSpeed = 11.5f;
        public float jumpSpeed = 8.5f;
        public float gravity = -26f;
        public float turnSharpness = 14f;

        public PlayerAvatar Avatar { get; private set; }
        public bool Grounded => _cc.isGrounded;
        public Vector3 Velocity => _velocity;

        CharacterController _cc;
        Vector3 _velocity;
        float _verticalSpeed;
        GameManager _g;
        Transform _cameraTransform;
        bool _trainingLock;

        public void Init(GameManager g, Transform cameraTransform)
        {
            _g = g;
            _cameraTransform = cameraTransform;
            _cc = GetComponent<CharacterController>();
            _cc.height = 2.2f;
            _cc.radius = 0.55f;
            _cc.center = new Vector3(0, 1.1f, 0);
            _cc.slopeLimit = 50f;
            _cc.stepOffset = 0.5f;
            _cc.skinWidth = 0.06f;
            var visual = new GameObject("Avatar");
            visual.transform.SetParent(transform, false);
            Avatar = visual.AddComponent<PlayerAvatar>();
            Avatar.Build();
        }

        bool CanMove => _g.Mode == GameMode.Playing;

        void Update()
        {
            if (_g == null) return;
            float dt = Time.deltaTime;
            if (_trainingLock)
            {
                Avatar.SetPullUp(_g.Training.RepProgress01);
                Avatar.SetLocomotion(0, 0, true);
                return;
            }

            Vector2 input = Vector2.zero;
            if (CanMove && !_g.UI.IsTyping)
            {
                if (GameInput.Held(GameKey.Forward)) input.y += 1;
                if (GameInput.Held(GameKey.Back)) input.y -= 1;
                if (GameInput.Held(GameKey.Right)) input.x += 1;
                if (GameInput.Held(GameKey.Left)) input.x -= 1;
            }
            if (input.sqrMagnitude > 1f) input.Normalize();
            bool running = GameInput.Held(GameKey.Sprint) && input.sqrMagnitude > 0.01f;

            Vector3 fwd = _cameraTransform.forward; fwd.y = 0; fwd.Normalize();
            Vector3 right = _cameraTransform.right; right.y = 0; right.Normalize();
            Vector3 wish = (fwd * input.y + right * input.x) * (running ? runSpeed : walkSpeed);
            float accel = _cc.isGrounded ? 60f : 20f;
            Vector3 horiz = new Vector3(_velocity.x, 0, _velocity.z);
            horiz = Vector3.MoveTowards(horiz, wish, accel * dt);

            if (_cc.isGrounded)
            {
                if (_verticalSpeed < -2f) _verticalSpeed = -2f;
                if (CanMove && GameInput.Pressed(GameKey.Jump))
                {
                    _verticalSpeed = jumpSpeed;
                    _g.Sound.Play(Audio.Sfx.Jump, 0.5f);
                }
            }
            _verticalSpeed += gravity * dt;
            _velocity = new Vector3(horiz.x, _verticalSpeed, horiz.z);
            var flags = _cc.Move(_velocity * dt);
            if ((flags & CollisionFlags.Above) != 0 && _verticalSpeed > 0) _verticalSpeed = 0;

            if (horiz.sqrMagnitude > 0.05f)
            {
                var target = Quaternion.LookRotation(horiz.normalized, Vector3.up);
                transform.rotation = Quaternion.Slerp(transform.rotation, target, 1f - Mathf.Exp(-turnSharpness * dt));
            }
            if (transform.position.y < -20f) Teleport(World.WorldLayout.Spawn, 0f);

            Avatar.SetLocomotion(Mathf.Clamp01(horiz.magnitude / walkSpeed), running ? 1f : 0f, _cc.isGrounded);
        }

        public void Teleport(Vector3 position, float yaw)
        {
            _cc.enabled = false;
            transform.SetPositionAndRotation(position + Vector3.up * 0.05f, Quaternion.Euler(0, yaw, 0));
            _cc.enabled = true;
            _velocity = Vector3.zero;
            _verticalSpeed = 0f;
        }

        public void FaceYaw(float yaw) => transform.rotation = Quaternion.Euler(0, yaw, 0);

        public void BeginTraining(Vector3 barBase)
        {
            Teleport(barBase, 180f);
            _trainingLock = true;
            Avatar.SetPose(AvatarPose.PullUp);
        }

        public void EndTraining()
        {
            _trainingLock = false;
            Avatar.SetPose(AvatarPose.Locomotion);
            Teleport(transform.position + transform.forward * -1.5f, transform.eulerAngles.y);
        }

        public void StopMotion()
        {
            _velocity = Vector3.zero;
            Avatar.SetLocomotion(0, 0, true);
        }
    }
}
