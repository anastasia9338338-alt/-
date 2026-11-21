// Minimal stand-in for the few UnityEngine types used by the pure data/logic files, for offline balance simulation only.
using System;
namespace UnityEngine
{
    public class Object { public string name; }
    public class ScriptableObject : Object { public static T CreateInstance<T>() where T : ScriptableObject => (T)Activator.CreateInstance(typeof(T)); }
    public class CreateAssetMenuAttribute : Attribute { public string menuName, fileName; }
    public class TooltipAttribute : Attribute { public TooltipAttribute(string s) { } }
    public class HeaderAttribute : Attribute { public HeaderAttribute(string s) { } }
    public class TextAreaAttribute : Attribute { }
    public class RangeAttribute : Attribute { public RangeAttribute(float a, float b) { } }
    public struct Color { public float r, g, b, a; public Color(float r, float g, float b, float a = 1) { this.r = r; this.g = g; this.b = b; this.a = a; } public static Color white => new Color(1,1,1); public static Color gray => new Color(.5f,.5f,.5f); public static Color black => new Color(0,0,0); }
    public static class ColorUtility { public static bool TryParseHtmlString(string s, out Color c) { c = new Color(Convert.ToInt32(s.Substring(1,2),16)/255f, Convert.ToInt32(s.Substring(3,2),16)/255f, Convert.ToInt32(s.Substring(5,2),16)/255f); return true; } }
    public struct Vector3 { public float x, y, z; public static Vector3 LerpUnclamped(Vector3 a, Vector3 b, float t) => new Vector3 { x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t, z = a.z + (b.z - a.z) * t }; }
    public static class Mathf
    {
        public const float PI = (float)Math.PI;
        public static float Abs(float v) => Math.Abs(v);
        public static float Max(float a, float b) => Math.Max(a, b);
        public static float Min(float a, float b) => Math.Min(a, b);
        public static float Pow(float a, float b) => (float)Math.Pow(a, b);
        public static float Sqrt(float a) => (float)Math.Sqrt(a);
        public static float Cos(float a) => (float)Math.Cos(a);
        public static float Clamp01(float v) => v < 0 ? 0 : v > 1 ? 1 : v;
        public static float Clamp(float v, float a, float b) => v < a ? a : v > b ? b : v;
        public static float Lerp(float a, float b, float t) => a + (b - a) * Clamp01(t);
        public static float InverseLerp(float a, float b, float v) => a == b ? 0 : Clamp01((v - a) / (b - a));
        public static float Repeat(float t, float l) => Clamp(t - (float)Math.Floor(t / l) * l, 0, l);
    }
}
