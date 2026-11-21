using System;
using System.Collections.Generic;
using System.Linq;
using ZooThrow.Data;
using ZooThrow.Throwing;
using ZooThrow.Animals;
using ZooThrow.Training;
using ZooThrow.Core;

static class Program
{
    static int fails;
    static void Check(bool ok, string what) { Console.WriteLine((ok ? "PASS " : "FAIL ") + what); if (!ok) fails++; }

    static int Main(string[] args)
    {
        var db = DefaultContent.Create();
        var b = db.balance;
        var problems = db.Validate();
        Check(problems.Count == 0, "content validates: " + string.Join("; ", problems));
        Check(db.animals.Count >= 20, "animals >= 20: " + db.animals.Count);

        // chance sums
        foreach (var biome in db.biomes)
            foreach (float luck in new[] { 1f, 2.5f, 9f })
            {
                double sum = db.animals.Where(a => a.biomeId == biome.id).Sum(a => AnimalRoller.Chance(db, a, luck));
                Check(Math.Abs(sum - 1) < 1e-6, $"chances sum to 1 in {biome.id} luck {luck}: {sum:F6}");
            }
        // empirical roll vs Chance
        {
            var rng = new Random(1); var forest = db.Biome("forest"); var counts = new Dictionary<string, int>(); int n = 400000;
            for (int i = 0; i < n; i++) { var a = AnimalRoller.Roll(db, forest, 1.3f, rng); counts[a.id] = counts.TryGetValue(a.id, out var c) ? c + 1 : 1; }
            foreach (var a in db.animals.Where(x => x.biomeId == "forest"))
            {
                double exp = AnimalRoller.Chance(db, a, 1.3f), got = counts.TryGetValue(a.id, out var c) ? (double)c / n : 0;
                Check(Math.Abs(exp - got) < 0.004 + exp * 0.1, $"roll freq {a.id}: expected {exp:P3} got {got:P3}");
            }
        }
        // grades and formula
        Check(ThrowMath.Grade(b, 0) == ThrowGrade.Perfect && ThrowMath.Grade(b, 0.1f) == ThrowGrade.Great && ThrowMath.Grade(b, 0.2f) == ThrowGrade.Good && ThrowMath.Grade(b, 0.5f) == ThrowGrade.Weak, "grade thresholds");
        var r = ThrowMath.Compute(b, 1, 1, db.Food("carrot"), 0f, 1f, 0.5f);
        Check(Math.Abs(r.total - (r.baseDistance + r.strengthDistance + r.foodBonus + r.accuracyBonus)) < 1e-3, $"distance = sum of parts ({r.total:F2})");
        var w = ThrowMath.Compute(b, 1, 1, db.Food("carrot"), 0.9f, 1f, 0.5f);
        Check(w.total < r.total && w.accuracyBonus < 0, $"weak throw shorter ({w.total:F1} < {r.total:F1})");
        var meter = new ThrowMeter(); meter.Start(1f, 0.5f, 0f); float mn = 1, mx = 0;
        for (int i = 0; i < 1000; i++) { meter.Tick(0.001f); mn = Math.Min(mn, meter.Value); mx = Math.Max(mx, meter.Value); }
        Check(mn < 0.01f && mx > 0.99f, $"meter covers bar ({mn:F3}..{mx:F3})");
        int lv = 1; double xp = 0; int gained = Progression.ApplyXp(b, ref lv, ref xp, 25);
        Check(lv == 3 && Math.Abs(xp - (25 - Progression.XpToNext(b, 1) - Progression.XpToNext(b, 2))) < 1e-9 && gained == 2, $"xp apply level {lv} xp {xp}");
        Check(NumberFormat.Money(1250) == "$1.25K" && NumberFormat.Money(999) == "$999" && NumberFormat.Money(12_345_678) == "$12.3M", "money format " + NumberFormat.Money(1250) + " " + NumberFormat.Money(12_345_678));

        // Save repair
        {
            var sd = ZooThrow.SaveSystem.SaveData.CreateNew(db);
            sd.money = double.NaN; sd.powerLevel = -5; sd.bestDistance = 150f;
            sd.animals.Add(new ZooThrow.SaveSystem.OwnedAnimal { uid = 3, animalId = "rabbit" });
            sd.animals.Add(new ZooThrow.SaveSystem.OwnedAnimal { uid = 3, animalId = "fox" });        // duplicate uid
            sd.animals.Add(new ZooThrow.SaveSystem.OwnedAnimal { uid = 9, animalId = "dragon_x" });   // unknown id
            sd.penSlots[0] = 3; sd.penSlots[1] = 3; sd.penSlots[2] = 77; sd.penSlots.Add(5);
            sd.selectedFood = "pizza"; sd.ownedFoods.Add("nonsense");
            sd.upgrades.Add(new ZooThrow.SaveSystem.UpgradeLevel { id = "luck", level = 999 });
            var fixes = ZooThrow.SaveSystem.SaveValidator.Sanitize(sd, db);
            Check(sd.money == 0 && sd.powerLevel == 1, "save: money/level repaired");
            Check(sd.animals.Count == 1 && sd.animals[0].uid == 3 && sd.nextAnimalUid == 4, "save: bad animals removed, uid counter fixed");
            Check(sd.penSlots.Count == b.maxPenSlots && sd.penSlots[0] == 3 && sd.penSlots[1] == 0 && sd.penSlots[2] == 0, "save: pen slots repaired");
            Check(sd.selectedFood == "carrot" && !sd.ownedFoods.Contains("nonsense"), "save: foods repaired");
            Check(sd.upgrades[0].level == db.Upgrade("luck").maxLevel, "save: upgrade clamped");
            Check(sd.unlockedBiomes.Contains("savanna") && sd.unlockedBiomes.Contains("desert") && !sd.unlockedBiomes.Contains("jungle"), "save: biomes implied by record");
            Check(sd.discoveredAnimals.Contains("rabbit"), "save: discovered includes owned; fixes=" + string.Join(",", fixes));
        }
        foreach (int seed in new[] { 1, 2, 3 }) Simulate(db, seed, seed == 1);
        Console.WriteLine(fails == 0 ? "ALL PASS" : $"{fails} FAILED");
        return fails == 0 ? 0 : 1;
    }

    static void Simulate(GameDatabase db, int seed, bool verbose)
    {
        var b = db.balance; var rng = new Random(seed);
        double money = b.startingMoney; int level = b.startingPowerLevel; double xp = 0;
        var foods = new List<FoodData> { db.Food("carrot") }; var trainers = new List<TrainerData> { db.Trainer("pullup_bar") };
        var up = db.upgrades.ToDictionary(u => u.id, u => 0);
        var pen = new List<double>(); var unlocked = new HashSet<string> { "forest" };
        double t = 0; int throws = 0; double firstAnimalThrow = -1, firstPurchase = -1; var biomeTimes = new Dictionary<string, double> { ["forest"] = 0 };
        int cap() => b.startingPenCapacity + up["pen_capacity"];
        double income() => pen.Sum();
        void advance(double dt) { money += income() * dt; t += dt; }
        while (t < 6 * 3600 && biomeTimes.Count < db.biomes.Count)
        {
            // train 45 s
            var tr = trainers.OrderBy(x => x.xpPerRep).Last();
            for (int i = 0; i < 45 / b.repDuration; i++) { advance(b.repDuration); Progression.ApplyXp(b, ref level, ref xp, tr.xpPerRep * (1 + up["training_boost"] * db.Upgrade("training_boost").valuePerLevel)); }
            // throw twice
            for (int k = 0; k < 2; k++)
            {
                advance(7);
                var food = foods.OrderBy(f => f.tier).Last();
                float offset = (float)(Normal(rng) * 0.13);
                var res = ThrowMath.Compute(b, level, 1 + up["strong_arms"] * db.Upgrade("strong_arms").valuePerLevel, food, offset, 1 + up["luck"] * db.Upgrade("luck").valuePerLevel, (float)rng.NextDouble());
                var biome = db.BiomeAtDistance(res.total);
                foreach (var bb in db.biomes) if (bb.startDistance <= res.total && !biomeTimes.ContainsKey(bb.id)) { biomeTimes[bb.id] = t; unlocked.Add(bb.id); }
                var a = AnimalRoller.Roll(db, biome, res.luck, rng); var m = AnimalRoller.RollMutation(b, res.luck, rng);
                double inc = AnimalRoller.Income(db, a, m); throws++;
                if (firstAnimalThrow < 0) firstAnimalThrow = throws;
                if (pen.Count < cap()) pen.Add(inc); else { int wi = pen.IndexOf(pen.Min()); if (pen[wi] < inc) pen[wi] = inc; money += Math.Max(1, inc * b.sellValueSeconds) * 0; }
            }
            // shopping: greedy cheapest useful
            bool bought = true;
            while (bought)
            {
                bought = false;
                var options = new List<(double cost, Action buy, string name)>();
                var nf = db.foods.FirstOrDefault(f => !foods.Contains(f) && (string.IsNullOrEmpty(f.requiredBiomeId) || unlocked.Contains(f.requiredBiomeId)));
                if (nf != null) options.Add((nf.price, () => foods.Add(nf), nf.id));
                var nt = db.trainers.FirstOrDefault(x => !trainers.Contains(x) && level >= x.requiredPowerLevel);
                if (nt != null) options.Add((nt.price, () => trainers.Add(nt), nt.id));
                foreach (var u in db.upgrades) if (up[u.id] < u.maxLevel && u.id != "offline") { var uu = u; options.Add((u.CostForLevel(up[u.id]), () => up[uu.id]++, u.id)); }
                var best = options.Where(o => o.cost <= money).OrderBy(o => o.cost).FirstOrDefault();
                if (best.buy != null) { money -= best.cost; best.buy(); bought = true; if (firstPurchase < 0) { firstPurchase = t; if (verbose) Console.WriteLine($"  first purchase {best.name} at {t / 60:F1} min"); } }
            }
        }
        Console.WriteLine($"seed {seed}: first animal on throw {firstAnimalThrow}, first purchase {firstPurchase / 60:F1} min, level {level}, income {NumberFormat.PerSecond(income())}, money {NumberFormat.Money(money)}");
        foreach (var kv in biomeTimes.OrderBy(k => k.Value)) Console.WriteLine($"   {kv.Key,-10} reached at {kv.Value / 60,6:F1} min");
        if (seed == 1)
        {
            Check(firstAnimalThrow <= 2, "first animal within 2 throws");
            Check(firstPurchase > 0 && firstPurchase < 6 * 60, "first purchase within a few minutes");
            Check(biomeTimes.TryGetValue("savanna", out var sv) && sv >= 4 * 60 && sv <= 11 * 60, "savanna in ~5-10 min: " + (biomeTimes.TryGetValue("savanna", out var s2) ? (s2 / 60).ToString("F1") : "never"));
        }
    }

    static double Normal(Random r) { double u1 = 1 - r.NextDouble(), u2 = r.NextDouble(); return Math.Sqrt(-2 * Math.Log(u1)) * Math.Cos(2 * Math.PI * u2); }
}
