using System;
using ZooThrow.Data;

namespace ZooThrow.Training
{
    public static class Progression
    {
        public static double XpToNext(BalanceSettings b, int level)
        {
            if (level < 1) level = 1;
            return Math.Ceiling(b.xpBase * Math.Pow(b.xpGrowth, level - 1));
        }

        /// <summary>Applies xp to (level, xp) and returns how many levels were gained.</summary>
        public static int ApplyXp(BalanceSettings b, ref int level, ref double xp, double gained)
        {
            if (double.IsNaN(gained) || gained <= 0) return 0;
            xp += gained;
            int levels = 0;
            while (level < b.maxPowerLevel)
            {
                double need = XpToNext(b, level);
                if (xp < need) break;
                xp -= need;
                level++;
                levels++;
            }
            if (level >= b.maxPowerLevel) xp = Math.Min(xp, XpToNext(b, level));
            return levels;
        }
    }
}
