using System;
using System.Globalization;

namespace ZooThrow.Core
{
    public static class NumberFormat
    {
        static readonly string[] Suffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" };

        public static string Short(double value)
        {
            if (double.IsNaN(value) || double.IsInfinity(value)) return "0";
            bool neg = value < 0;
            value = Math.Abs(value);
            if (value < 1000)
            {
                string small = value < 10 && value % 1 != 0 ? value.ToString("0.#", CultureInfo.InvariantCulture) : Math.Floor(value).ToString("0", CultureInfo.InvariantCulture);
                return neg ? "-" + small : small;
            }
            int idx = 0;
            while (value >= 1000 && idx < Suffixes.Length - 1) { value /= 1000; idx++; }
            double truncated = Math.Floor(value * 100) / 100;
            string fmt = truncated >= 100 ? "0" : truncated >= 10 ? "0.#" : "0.##";
            return (neg ? "-" : "") + truncated.ToString(fmt, CultureInfo.InvariantCulture) + Suffixes[idx];
        }

        public static string Money(double value) => "$" + Short(value);

        public static string PerSecond(double value) => "$" + Short(value) + "/сек";

        public static string Meters(float value) => value.ToString(value < 100 ? "0.0" : "0", CultureInfo.InvariantCulture) + " м";

        public static string Percent(double chance)
        {
            double p = chance * 100;
            if (p >= 10) return p.ToString("0", CultureInfo.InvariantCulture) + "%";
            if (p >= 1) return p.ToString("0.#", CultureInfo.InvariantCulture) + "%";
            if (p >= 0.01) return p.ToString("0.##", CultureInfo.InvariantCulture) + "%";
            return p <= 0 ? "0%" : "<0.01%";
        }

        public static string Duration(double seconds)
        {
            var t = TimeSpan.FromSeconds(Math.Max(0, seconds));
            if (t.TotalHours >= 1) return $"{(int)t.TotalHours} ч {t.Minutes} мин";
            if (t.TotalMinutes >= 1) return $"{t.Minutes} мин {t.Seconds} сек";
            return $"{t.Seconds} сек";
        }
    }
}
