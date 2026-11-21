using UnityEngine;
using ZooThrow.Visuals;

namespace ZooThrow.Player
{
    public enum AvatarPose { Locomotion, Aim, Throw, PullUp, Reel }

    /// <summary>Blocky cartoon character built from boxes, animated procedurally (idle, walk, run, jump, throw, pull-ups).</summary>
    public class PlayerAvatar : MonoBehaviour
    {
        public Transform RightHand { get; private set; }

        Transform _hips, _torso, _head, _armL, _armR, _legL, _legR;
        float _phase, _time;
        float _speed01, _run01, _airborne01;
        float _throwT = -1f;
        AvatarPose _pose;
        float _pullUp01;

        static readonly Color Skin = new Color(1f, 0.82f, 0.62f);
        static readonly Color Hoodie = new Color(1f, 0.55f, 0.12f);
        static readonly Color HoodieDark = new Color(0.85f, 0.38f, 0.08f);
        static readonly Color Pants = new Color(0.15f, 0.55f, 0.62f);
        static readonly Color Shoes = new Color(0.95f, 0.95f, 0.95f);
        static readonly Color Cap = new Color(0.2f, 0.35f, 0.95f);
        static readonly Color Dark = new Color(0.1f, 0.1f, 0.13f);

        public void Build()
        {
            _hips = Node("Hips", transform, new Vector3(0, 0.9f, 0));
            _torso = Node("Torso", _hips, Vector3.zero);
            var mb = new MeshBuilder();
            mb.Box(new Vector3(0, 0.42f, 0), new Vector3(0.95f, 0.85f, 0.5f), Hoodie);
            mb.Box(new Vector3(0, 0.05f, 0), new Vector3(0.97f, 0.12f, 0.52f), HoodieDark);
            mb.Box(new Vector3(0, 0.38f, 0.26f), new Vector3(0.45f, 0.22f, 0.04f), HoodieDark); // pocket
            mb.Box(new Vector3(0, 0.6f, -0.32f), new Vector3(0.55f, 0.55f, 0.18f), new Color(0.3f, 0.75f, 0.35f)); // backpack
            MaterialLibrary.AddRenderer(_torso.gameObject, mb.ToMesh("Torso"));

            _head = Node("Head", _torso, new Vector3(0, 0.85f, 0));
            mb.Clear();
            mb.Box(new Vector3(0, 0.3f, 0), new Vector3(0.62f, 0.6f, 0.6f), Skin);
            mb.Box(new Vector3(-0.14f, 0.36f, 0.305f), new Vector3(0.09f, 0.13f, 0.02f), Dark);
            mb.Box(new Vector3(0.14f, 0.36f, 0.305f), new Vector3(0.09f, 0.13f, 0.02f), Dark);
            mb.Box(new Vector3(-0.12f, 0.39f, 0.315f), new Vector3(0.03f, 0.04f, 0.01f), Color.white);
            mb.Box(new Vector3(0.16f, 0.39f, 0.315f), new Vector3(0.03f, 0.04f, 0.01f), Color.white);
            mb.Box(new Vector3(0, 0.17f, 0.305f), new Vector3(0.22f, 0.04f, 0.02f), Dark);   // smile
            mb.Box(new Vector3(-0.12f, 0.19f, 0.305f), new Vector3(0.04f, 0.04f, 0.02f), Dark);
            mb.Box(new Vector3(0.12f, 0.19f, 0.305f), new Vector3(0.04f, 0.04f, 0.02f), Dark);
            mb.Box(new Vector3(-0.22f, 0.24f, 0.302f), new Vector3(0.09f, 0.05f, 0.01f), new Color(1f, 0.6f, 0.6f)); // cheeks
            mb.Box(new Vector3(0.22f, 0.24f, 0.302f), new Vector3(0.09f, 0.05f, 0.01f), new Color(1f, 0.6f, 0.6f));
            mb.Box(new Vector3(0, 0.62f, -0.02f), new Vector3(0.66f, 0.12f, 0.64f), Cap);       // cap
            mb.Box(new Vector3(0, 0.58f, 0.38f), new Vector3(0.6f, 0.05f, 0.3f), Cap);          // visor
            mb.Box(new Vector3(0, 0.7f, -0.02f), new Vector3(0.12f, 0.06f, 0.12f), Color.white);
            MaterialLibrary.AddRenderer(_head.gameObject, mb.ToMesh("Head"));

            mb.Clear();
            mb.Box(new Vector3(0, -0.36f, 0), new Vector3(0.3f, 0.72f, 0.3f), Hoodie);
            mb.Box(new Vector3(0, -0.8f, 0), new Vector3(0.27f, 0.18f, 0.27f), Skin);
            var armMesh = mb.ToMesh("Arm");
            _armL = Node("ArmL", _torso, new Vector3(-0.64f, 0.78f, 0));
            _armR = Node("ArmR", _torso, new Vector3(0.64f, 0.78f, 0));
            MaterialLibrary.AddRenderer(_armL.gameObject, armMesh);
            MaterialLibrary.AddRenderer(_armR.gameObject, armMesh);
            RightHand = Node("RightHand", _armR, new Vector3(0, -0.9f, 0.12f));

            mb.Clear();
            mb.Box(new Vector3(0, -0.38f, 0), new Vector3(0.4f, 0.76f, 0.42f), Pants);
            mb.Box(new Vector3(0, -0.84f, 0.06f), new Vector3(0.42f, 0.14f, 0.56f), Shoes);
            var legMesh = mb.ToMesh("Leg");
            _legL = Node("LegL", _hips, new Vector3(-0.24f, 0f, 0));
            _legR = Node("LegR", _hips, new Vector3(0.24f, 0f, 0));
            MaterialLibrary.AddRenderer(_legL.gameObject, legMesh);
            MaterialLibrary.AddRenderer(_legR.gameObject, legMesh);
        }

        static Transform Node(string name, Transform parent, Vector3 localPos)
        {
            var t = new GameObject(name).transform;
            t.SetParent(parent, false);
            t.localPosition = localPos;
            return t;
        }

        public void SetLocomotion(float speed01, float run01, bool grounded)
        {
            _speed01 = speed01;
            _run01 = run01;
            _airborne01 = Mathf.MoveTowards(_airborne01, grounded ? 0f : 1f, Time.deltaTime * 6f);
        }

        public void SetPose(AvatarPose pose) { _pose = pose; if (pose == AvatarPose.Throw) _throwT = 0f; }
        public void SetPullUp(float progress01) => _pullUp01 = progress01;
        public float ThrowProgress => _throwT;

        void LateUpdate()
        {
            float dt = Time.deltaTime;
            _time += dt;
            _phase += dt * Mathf.Lerp(7f, 11f, _run01) * Mathf.Max(0.2f, _speed01);
            float swing = Mathf.Sin(_phase) * Mathf.Lerp(32f, 55f, _run01) * _speed01;
            float bob = Mathf.Abs(Mathf.Sin(_phase)) * 0.08f * _speed01;
            float breathe = Mathf.Sin(_time * 2f) * 0.015f;

            Vector3 hips = new Vector3(0, 0.9f + bob + breathe, 0);
            Quaternion torso = Quaternion.Euler(_run01 * 10f * _speed01, 0, 0);
            Quaternion armL = Quaternion.Euler(-swing, 0, -4f), armR = Quaternion.Euler(swing, 0, 4f);
            Quaternion legL = Quaternion.Euler(swing, 0, 0), legR = Quaternion.Euler(-swing, 0, 0);
            Quaternion head = Quaternion.Euler(Mathf.Sin(_time * 1.1f) * 2f, Mathf.Sin(_time * 0.7f) * 4f, 0);

            if (_airborne01 > 0.01f)
            {
                armL = Quaternion.Slerp(armL, Quaternion.Euler(-150f, 0, -20f), _airborne01);
                armR = Quaternion.Slerp(armR, Quaternion.Euler(-150f, 0, 20f), _airborne01);
                legL = Quaternion.Slerp(legL, Quaternion.Euler(-30f, 0, 0), _airborne01);
                legR = Quaternion.Slerp(legR, Quaternion.Euler(15f, 0, 0), _airborne01);
            }

            switch (_pose)
            {
                case AvatarPose.Aim:
                    armR = Quaternion.Euler(-110f + Mathf.Sin(_time * 3f) * 5f, 0, 25f);
                    armL = Quaternion.Euler(-60f, 0, -15f);
                    torso = Quaternion.Euler(0, 25f, 0);
                    legL = Quaternion.Euler(-12f, 0, 0); legR = Quaternion.Euler(12f, 0, 0);
                    break;
                case AvatarPose.Throw:
                    {
                        _throwT += dt;
                        float t = Mathf.Clamp01(_throwT / 0.45f);
                        // wind-up (0..0.45) then fast release (0.45..0.7) then follow-through
                        float wind = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(t / 0.45f));
                        float release = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01((t - 0.45f) / 0.25f));
                        float armAngle = Mathf.Lerp(-110f, -200f, wind);
                        armAngle = Mathf.Lerp(armAngle, -20f, release);
                        armR = Quaternion.Euler(armAngle, 0, 20f);
                        armL = Quaternion.Euler(Mathf.Lerp(-60f, 30f, release), 0, -20f);
                        torso = Quaternion.Euler(Mathf.Lerp(-5f, 20f, release), Mathf.Lerp(30f, -25f, release), 0);
                        legL = Quaternion.Euler(Mathf.Lerp(-12f, -30f, release), 0, 0);
                        legR = Quaternion.Euler(Mathf.Lerp(12f, 25f, release), 0, 0);
                        break;
                    }
                case AvatarPose.Reel:
                    {
                        // Both hands on the rod, held out in front, with a small reeling motion.
                        armR = Quaternion.Euler(-55f + Mathf.Sin(_time * 9f) * 4f, 0, 8f);
                        armL = Quaternion.Euler(-45f, 0, -25f + Mathf.Sin(_time * 9f) * 6f);
                        torso = Quaternion.Euler(-6f, 0, 0);
                        legL = Quaternion.Euler(-10f, 0, 0); legR = Quaternion.Euler(10f, 0, 0);
                        break;
                    }
                case AvatarPose.PullUp:
                    {
                        // hands on the bar above the head, body rises with each rep
                        float lift = Mathf.Sin(_pullUp01 * Mathf.PI);
                        // Hands stay near the bar (WorldLayout.BarHeight): hips rise while the arms bend.
                        hips = new Vector3(0, 1.35f + lift * 0.6f, 0);
                        armL = Quaternion.Euler(-180f + lift * 70f, 0, -10f);
                        armR = Quaternion.Euler(-180f + lift * 70f, 0, 10f);
                        legL = Quaternion.Euler(-20f - lift * 15f, 0, 0);
                        legR = Quaternion.Euler(-10f - lift * 15f, 0, 0);
                        torso = Quaternion.Euler(-lift * 6f, 0, 0);
                        head = Quaternion.Euler(-10f - lift * 8f, 0, 0);
                        break;
                    }
            }

            float k = 1f - Mathf.Exp(-18f * dt);
            _hips.localPosition = Vector3.Lerp(_hips.localPosition, hips, k);
            _torso.localRotation = Quaternion.Slerp(_torso.localRotation, torso, k);
            _head.localRotation = Quaternion.Slerp(_head.localRotation, head, k);
            float limbK = _pose == AvatarPose.Throw ? 1f : k;
            _armL.localRotation = Quaternion.Slerp(_armL.localRotation, armL, limbK);
            _armR.localRotation = Quaternion.Slerp(_armR.localRotation, armR, limbK);
            _legL.localRotation = Quaternion.Slerp(_legL.localRotation, legL, k);
            _legR.localRotation = Quaternion.Slerp(_legR.localRotation, legR, k);
        }
    }
}
