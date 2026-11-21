using System;
using UnityEngine;
using ZooThrow.Core;

namespace ZooThrow.Economy
{
    /// <summary>
    /// Pays pen income every frame and handles time away: closed game (offline earnings) and hidden browser tabs,
    /// where WebGL stops calling Update and the real-time gap is paid like offline time.
    /// </summary>
    public class PassiveIncomeManager : MonoBehaviour
    {
        GameManager _g;
        double _lastRealtime;
        double _popupAccumulator;
        bool _started;
        public double IncomePerSecond => _g != null ? _g.Pen.TotalIncome : 0;

        /// <summary>Raised roughly once a second with the amount earned, for floating "+$" popups.</summary>
        public event Action<double> IncomeTick;

        public void Init(GameManager g)
        {
            _g = g;
            _lastRealtime = Time.realtimeSinceStartupAsDouble;
        }

        /// <summary>Offline earnings since the previous save. Returns (seconds counted, money).</summary>
        public (double seconds, double money) ComputeOffline(long previousSaveUtcTicks)
        {
            double elapsed = (DateTime.UtcNow.Ticks - previousSaveUtcTicks) / (double)TimeSpan.TicksPerSecond;
            if (double.IsNaN(elapsed) || elapsed < _g.Balance.minOfflineSeconds) return (0, 0);
            double cap = _g.Upgrades.OfflineHours * 3600.0;
            double counted = Math.Min(elapsed, cap);
            double money = counted * IncomePerSecond * _g.Balance.offlineRate;
            return (counted, money);
        }

        void Update()
        {
            if (_g == null) return;
            double now = Time.realtimeSinceStartupAsDouble;
            double dt = now - _lastRealtime;
            _lastRealtime = now;
            if (!_started)
            {
                // The first frame can arrive seconds after Init (world generation); that is not time away.
                _started = true;
                return;
            }
            if (dt <= 0) return;
            double income = IncomePerSecond;
            if (dt > 5.0)
            {
                // Background tab: frames stopped. Pay the gap at the offline rate, capped like offline time.
                double counted = Math.Min(dt, _g.Upgrades.OfflineHours * 3600.0);
                double gapMoney = counted * income * _g.Balance.offlineRate;
                if (gapMoney > 0)
                {
                    _g.Economy.Add(gapMoney);
                    GameEvents.RaiseToast("Пока вкладка была свёрнута: +" + NumberFormat.Money(gapMoney), new Color(0.4f, 1f, 0.5f));
                }
                return;
            }
            if (income <= 0) return;
            double earned = income * dt;
            _g.Economy.Add(earned);
            _popupAccumulator += dt;
            if (_popupAccumulator >= 1.0)
            {
                IncomeTick?.Invoke(income * _popupAccumulator);
                _popupAccumulator = 0;
            }
        }
    }
}
