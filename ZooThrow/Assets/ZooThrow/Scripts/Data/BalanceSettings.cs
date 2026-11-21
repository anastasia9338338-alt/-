using UnityEngine;

namespace ZooThrow.Data
{
    /// <summary>All economy and feel coefficients. Edit the asset, not the code.</summary>
    [CreateAssetMenu(menuName = "ZooThrow/Balance Settings", fileName = "BalanceSettings")]
    public class BalanceSettings : ScriptableObject
    {
        [Header("Старт")]
        public double startingMoney = 0;
        public int startingPowerLevel = 1;
        public int startingPenCapacity = 4;
        public int maxPenSlots = 12;
        public int inventoryCapacity = 200;
        public string startingFoodId = "carrot";
        public string startingTrainerId = "pullup_bar";

        [Header("Дальность = база + сила + еда + бонус точности")]
        public float baseDistance = 12f;
        [Tooltip("Метры силы за каждый уровень Throw Power.")]
        public float distancePerPowerLevel = 3f;
        [Tooltip("Показатель степени роста силы по уровню (1 = линейно).")]
        public float powerCurveExponent = 1.0f;
        [Range(0f, 0.2f)] public float distanceJitter = 0.03f;
        public float maxThrowDistance = 760f;

        [Header("Мини-игра точности")]
        [Tooltip("Полных проходов индикатора туда-обратно в секунду.")]
        public float meterCyclesPerSecond = 0.75f;
        [Tooltip("Ускорение индикатора за каждый открытый биом.")]
        public float meterSpeedPerBiome = 0.06f;
        [Range(0.005f, 0.2f)] public float perfectHalfWidth = 0.045f;
        [Range(0.01f, 0.4f)] public float greatHalfWidth = 0.13f;
        [Range(0.02f, 0.6f)] public float goodHalfWidth = 0.27f;
        public float weakMultiplierMin = 0.55f;
        public float weakMultiplierMax = 0.85f;
        public float goodMultiplier = 1.0f;
        public float greatMultiplier = 1.15f;
        public float perfectMultiplier = 1.35f;
        [Tooltip("Удача умножается на это значение при PERFECT.")]
        public float perfectLuckBonus = 1.3f;
        [Tooltip("Насколько сильно удача сдвигает веса редкостей: вес × удача^(уровень редкости × это число).")]
        public float luckTierScale = 0.6f;

        [Header("Полёт еды")]
        public float minFlightTime = 1.4f;
        public float flightTimePerSqrtMeter = 0.12f;
        public float arcHeightPerMeter = 0.22f;
        public float maxArcHeight = 110f;

        [Header("Тренировка")]
        public double xpBase = 10;
        public double xpGrowth = 1.4;
        public float repDuration = 0.8f;
        public int maxPowerLevel = 250;

        [Header("Доход")]
        [Tooltip("Продажа животного = доход в секунду × это число секунд.")]
        public double sellValueSeconds = 20;
        public float baseOfflineHours = 2f;
        [Range(0f, 1f)] public float offlineRate = 0.5f;
        public float minOfflineSeconds = 60f;

        [Header("Мутации")]
        public bool mutationsEnabled = true;
        [Range(0f, 1f)] public float goldenChance = 0.04f;
        [Range(0f, 1f)] public float rainbowChance = 0.01f;
        [Range(0f, 1f)] public float giantChance = 0.03f;
        public double goldenIncomeMultiplier = 2;
        public double rainbowIncomeMultiplier = 3;
        public double giantIncomeMultiplier = 1.5;
        public float giantScale = 1.6f;

        [Header("Сохранение")]
        public float autosaveSeconds = 5f;
    }
}
