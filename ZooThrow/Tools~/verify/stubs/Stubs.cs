// Compile-only stand-ins for package APIs not available as reference assemblies here.
// Signatures mirror Input System 1.8 and URP 14-17 public API used by the project.
using UnityEngine;
namespace UnityEngine.InputSystem.Controls
{
    public class InputControl<T> where T : struct { public T ReadValue() => default; }
    public class ButtonControl : InputControl<float> { public bool isPressed => false; public bool wasPressedThisFrame => false; public bool wasReleasedThisFrame => false; }
    public class KeyControl : ButtonControl { }
    public class Vector2Control : InputControl<Vector2> { }
    public class DeltaControl : Vector2Control { }
}
namespace UnityEngine.InputSystem
{
    using UnityEngine.InputSystem.Controls;
    public enum Key { None, Space, Enter, Tab, A, B, C, D, E, F, I, N, Q, R, S, U, W, X, Z, Digit1, LeftShift, LeftAlt, Escape, UpArrow, DownArrow, LeftArrow, RightArrow }
    public class Keyboard { public static Keyboard current { get; } public KeyControl this[Key key] => null; }
    public class Pointer { public Vector2Control position { get; protected set; } public Vector2Control delta { get; protected set; } }
    public class Mouse : Pointer { public static Mouse current { get; } public DeltaControl scroll { get; protected set; } public ButtonControl leftButton { get; protected set; } public ButtonControl rightButton { get; protected set; } }
}
namespace UnityEngine.InputSystem.UI { public class InputSystemUIInputModule : UnityEngine.EventSystems.BaseInputModule { public override void Process() { } } }
namespace UnityEngine.Rendering.Universal
{
    public abstract class ScriptableRendererData : ScriptableObject { }
    public class UniversalRendererData : ScriptableRendererData { }
    public class UniversalRenderPipelineAsset : UnityEngine.Rendering.RenderPipelineAsset
    {
        public static UniversalRenderPipelineAsset Create(ScriptableRendererData rendererData = null) => null;
        public float renderScale { get; set; }
        public float shadowDistance { get; set; }
        public int msaaSampleCount { get; set; }
        public bool supportsHDR { get; set; }
        public int shadowCascadeCount { get; set; }
        protected override UnityEngine.Rendering.RenderPipeline CreatePipeline() => null;
    }
}
