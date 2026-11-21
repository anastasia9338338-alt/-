using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace ZooThrow.Core
{
    public enum GameKey { Forward, Back, Left, Right, Jump, Sprint, Interact, Throw, Menu, Animals, Rods, Baits, Upgrades, Collection, FreeCursor, PrevBait, NextBait }

    /// <summary>
    /// One input facade for both the new Input System and the legacy Input Manager, so the project works with
    /// either "Active Input Handling" setting. Mouse delta is in pixels.
    /// </summary>
    public static class GameInput
    {
        public static bool Held(GameKey k)
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb == null) return false;
            switch (k)
            {
                case GameKey.Forward: return kb[Key.W].isPressed || kb[Key.UpArrow].isPressed;
                case GameKey.Back: return kb[Key.S].isPressed || kb[Key.DownArrow].isPressed;
                case GameKey.Left: return kb[Key.A].isPressed || kb[Key.LeftArrow].isPressed;
                case GameKey.Right: return kb[Key.D].isPressed || kb[Key.RightArrow].isPressed;
                case GameKey.FreeCursor: return kb[Key.LeftAlt].isPressed;
                default: { var c = Control(kb, k); return c != null && c.isPressed; }
            }
#else
            switch (k)
            {
                case GameKey.Forward: return Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow);
                case GameKey.Back: return Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow);
                case GameKey.Left: return Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow);
                case GameKey.Right: return Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow);
                case GameKey.FreeCursor: return Input.GetKey(KeyCode.LeftAlt);
                default: return Input.GetKey(Legacy(k));
            }
#endif
        }

        public static bool Pressed(GameKey k)
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb == null) return false;
            var c = Control(kb, k);
            return c != null && c.wasPressedThisFrame;
#else
            return Input.GetKeyDown(Legacy(k));
#endif
        }

#if ENABLE_INPUT_SYSTEM
        static UnityEngine.InputSystem.Controls.KeyControl Control(Keyboard kb, GameKey k)
        {
            switch (k)
            {
                case GameKey.Forward: return kb[Key.W];
                case GameKey.Back: return kb[Key.S];
                case GameKey.Left: return kb[Key.A];
                case GameKey.Right: return kb[Key.D];
                case GameKey.Jump: return kb[Key.Space];
                case GameKey.Sprint: return kb[Key.LeftShift];
                case GameKey.Interact: return kb[Key.E];
                case GameKey.Throw: return kb[Key.F];
                case GameKey.Menu: return kb[Key.Escape];
                case GameKey.Animals: return kb[Key.Tab];
                case GameKey.Rods: return kb[Key.B];
                case GameKey.Baits: return kb[Key.N];
                case GameKey.Upgrades: return kb[Key.U];
                case GameKey.Collection: return kb[Key.C];
                case GameKey.FreeCursor: return kb[Key.LeftAlt];
                case GameKey.PrevBait: return kb[Key.Q];
                case GameKey.NextBait: return kb[Key.R];
                default: return null;
            }
        }
#else
        static KeyCode Legacy(GameKey k)
        {
            switch (k)
            {
                case GameKey.Forward: return KeyCode.W;
                case GameKey.Back: return KeyCode.S;
                case GameKey.Left: return KeyCode.A;
                case GameKey.Right: return KeyCode.D;
                case GameKey.Jump: return KeyCode.Space;
                case GameKey.Sprint: return KeyCode.LeftShift;
                case GameKey.Interact: return KeyCode.E;
                case GameKey.Throw: return KeyCode.F;
                case GameKey.Menu: return KeyCode.Escape;
                case GameKey.Animals: return KeyCode.Tab;
                case GameKey.Rods: return KeyCode.B;
                case GameKey.Baits: return KeyCode.N;
                case GameKey.Upgrades: return KeyCode.U;
                case GameKey.Collection: return KeyCode.C;
                case GameKey.FreeCursor: return KeyCode.LeftAlt;
                case GameKey.PrevBait: return KeyCode.Q;
                case GameKey.NextBait: return KeyCode.R;
                default: return KeyCode.None;
            }
        }
#endif

        public static Vector2 MouseDelta
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                return m != null ? m.delta.ReadValue() : Vector2.zero;
#else
                // Default Input Manager axes scale pixel delta by 0.1.
                return new Vector2(Input.GetAxisRaw("Mouse X"), Input.GetAxisRaw("Mouse Y")) * 10f;
#endif
            }
        }

        /// <summary>Scroll in "notches": positive = wheel up.</summary>
        public static float Scroll
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                if (m == null) return 0f;
                float y = m.scroll.ReadValue().y;
                return Mathf.Abs(y) >= 10f ? y / 120f : y;
#else
                return Input.mouseScrollDelta.y;
#endif
            }
        }

        public static bool PrimaryPressed
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                return m != null && m.leftButton.wasPressedThisFrame;
#else
                return Input.GetMouseButtonDown(0);
#endif
            }
        }

        public static bool SecondaryHeld
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                return m != null && m.rightButton.isPressed;
#else
                return Input.GetMouseButton(1);
#endif
            }
        }

        public static Vector2 PointerPosition
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                return m != null ? m.position.ReadValue() : Vector2.zero;
#else
                return Input.mousePosition;
#endif
            }
        }
    }
}
