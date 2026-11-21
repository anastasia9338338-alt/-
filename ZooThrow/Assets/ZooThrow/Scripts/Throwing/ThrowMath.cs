using UnityEngine;
using ZooThrow.Data;

namespace ZooThrow.Throwing
{
    public struct ThrowResult
    {
        public ThrowGrade grade;
        /// <summary>Distance of the stopped indicator from the target centre, in bar widths (0 = dead centre).</summary>
        public float offset;
        public float accuracyMultiplier;
        public float baseDistance;
        public float strengthDistance;
        public float foodBonus;
        public float accuracyBonus;
        public float total;
        public float luck;
    }

    /// <summary>Pure throw formulas. No scene access, so they can be checked outside Unity.</summary>
    public static class ThrowMath
    {
        public static float StrengthDistance(BalanceSettings b, int powerLevel, float armsMultiplier)
        {
            if (powerLevel < 1) powerLevel = 1;
            return b.distancePerPowerLevel * Mathf.Pow(powerLevel, b.powerCurveExponent) * armsMultiplier;
        }

        public static ThrowGrade Grade(BalanceSettings b, float offset)
        {
            offset = Mathf.Abs(offset);
            if (offset <= b.perfectHalfWidth) return ThrowGrade.Perfect;
            if (offset <= b.greatHalfWidth) return ThrowGrade.Great;
            if (offset <= b.goodHalfWidth) return ThrowGrade.Good;
            return ThrowGrade.Weak;
        }

        public static float AccuracyMultiplier(BalanceSettings b, float offset)
        {
            offset = Mathf.Abs(offset);
            switch (Grade(b, offset))
            {
                case ThrowGrade.Perfect: return b.perfectMultiplier;
                case ThrowGrade.Great: return b.greatMultiplier;
                case ThrowGrade.Good: return b.goodMultiplier;
                default:
                    float t = Mathf.InverseLerp(b.goodHalfWidth, 1f, offset);
                    return Mathf.Lerp(b.weakMultiplierMax, b.weakMultiplierMin, t);
            }
        }

        /// <summary>
        /// Distance = base + strength + food bonus + accuracy bonus.
        /// The accuracy bonus is (multiplier - 1) × (base + strength + food), so a weak throw has a negative bonus.
        /// jitter01 is a uniform random value in [0,1] used for the small natural spread.
        /// </summary>
        public static ThrowResult Compute(BalanceSettings b, int powerLevel, float armsMultiplier, FoodData food,
            float offset, float luckMultiplier, float jitter01)
        {
            var r = new ThrowResult();
            r.offset = Mathf.Abs(offset);
            r.grade = Grade(b, r.offset);
            r.accuracyMultiplier = AccuracyMultiplier(b, r.offset);
            r.baseDistance = b.baseDistance;
            r.strengthDistance = StrengthDistance(b, powerLevel, armsMultiplier);
            r.foodBonus = food != null ? food.distanceBonus : 0f;
            float raw = r.baseDistance + r.strengthDistance + r.foodBonus;
            r.accuracyBonus = raw * (r.accuracyMultiplier - 1f);
            float jitter = 1f + (Mathf.Clamp01(jitter01) * 2f - 1f) * b.distanceJitter;
            r.total = Mathf.Clamp((raw + r.accuracyBonus) * jitter, 1f, b.maxThrowDistance);
            float foodLuck = food != null ? food.luck : 1f;
            r.luck = foodLuck * luckMultiplier * (r.grade == ThrowGrade.Perfect ? b.perfectLuckBonus : 1f);
            return r;
        }

        /// <summary>Best possible distance (perfect, no jitter) — used for UI previews and biome hints.</summary>
        public static float PerfectDistance(BalanceSettings b, int powerLevel, float armsMultiplier, FoodData food)
        {
            float raw = b.baseDistance + StrengthDistance(b, powerLevel, armsMultiplier) + (food != null ? food.distanceBonus : 0f);
            return Mathf.Min(raw * b.perfectMultiplier, b.maxThrowDistance);
        }

        public static float FlightTime(BalanceSettings b, float distance) => b.minFlightTime + b.flightTimePerSqrtMeter * Mathf.Sqrt(Mathf.Max(0f, distance));

        public static float ArcHeight(BalanceSettings b, float distance) => Mathf.Min(b.maxArcHeight, 3f + distance * b.arcHeightPerMeter);

        /// <summary>Ballistic arc: constant horizontal speed and a parabolic height, i.e. constant gravity.</summary>
        public static Vector3 ArcPoint(Vector3 start, Vector3 end, float height, float t01)
        {
            t01 = Mathf.Clamp01(t01);
            Vector3 p = Vector3.LerpUnclamped(start, end, t01);
            p.y += 4f * height * t01 * (1f - t01);
            return p;
        }

        public static string GradeText(ThrowGrade g)
        {
            switch (g)
            {
                case ThrowGrade.Perfect: return "PERFECT THROW!";
                case ThrowGrade.Great: return "Отличный бросок!";
                case ThrowGrade.Good: return "Хороший бросок";
                default: return "Слабый бросок";
            }
        }
    }

    /// <summary>Ping-pong accuracy meter. Value runs 0..1..0; the target zone is centred at TargetCenter.</summary>
    public class ThrowMeter
    {
        public float Value { get; private set; }
        public float TargetCenter { get; private set; } = 0.5f;
        public bool Running { get; private set; }
        float _phase;
        float _cyclesPerSecond;

        public void Start(float cyclesPerSecond, float targetCenter, float startPhase01)
        {
            _cyclesPerSecond = Mathf.Max(0.05f, cyclesPerSecond);
            TargetCenter = Mathf.Clamp(targetCenter, 0.1f, 0.9f);
            _phase = Mathf.Repeat(startPhase01, 1f);
            Value = Evaluate(_phase);
            Running = true;
        }

        public void Tick(float dt)
        {
            if (!Running) return;
            _phase = Mathf.Repeat(_phase + dt * _cyclesPerSecond, 1f);
            Value = Evaluate(_phase);
        }

        /// <summary>Stops the meter and returns the signed offset from the target centre.</summary>
        public float Stop()
        {
            Running = false;
            return Value - TargetCenter;
        }

        public void Cancel() => Running = false;

        // Smooth ping-pong: slows slightly at the ends like a pendulum, fast through the middle.
        static float Evaluate(float phase)
        {
            float tri = 1f - Mathf.Abs(phase * 2f - 1f);
            return Mathf.Lerp(tri, 0.5f - 0.5f * Mathf.Cos(tri * Mathf.PI), 0.35f);
        }
    }
}
