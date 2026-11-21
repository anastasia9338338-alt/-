using UnityEngine;
using F = ZooThrow.Data.AnimalFeatures;

namespace ZooThrow.Data
{
    /// <summary>
    /// Built-in starting content and balance table. The editor menu "ZooThrow/Пересоздать данные" writes these
    /// values into ScriptableObject assets; after that the assets are the source of truth and can be tuned
    /// in the Inspector. At runtime this is used only when Resources/ZooThrowDatabase is missing.
    /// </summary>
    public static class DefaultContent
    {
        public static GameDatabase Create()
        {
            var db = ScriptableObject.CreateInstance<GameDatabase>();
            db.name = "ZooThrowDatabase (default)";
            db.balance = ScriptableObject.CreateInstance<BalanceSettings>();
            db.balance.name = "BalanceSettings";
            AddRarities(db);
            AddBiomes(db);
            AddAnimals(db);
            AddFoods(db);
            AddTrainers(db);
            AddUpgrades(db);
            db.BuildLookups();
            return db;
        }

        static T Make<T>(string assetName) where T : ScriptableObject
        {
            var so = ScriptableObject.CreateInstance<T>();
            so.name = assetName;
            return so;
        }

        static Color C(string hex)
        {
            ColorUtility.TryParseHtmlString(hex, out var c);
            return c;
        }

        // ---------------- Rarities ----------------
        static void AddRarities(GameDatabase db)
        {
            void R(Rarity r, string name, string hex, double weight, double mult, bool big, float glow, int burst)
            {
                var d = Make<RarityData>("Rarity_" + r);
                d.rarity = r; d.displayName = name; d.color = C(hex); d.baseWeight = weight; d.incomeMultiplier = mult;
                d.bigRewardScreen = big; d.glowIntensity = glow; d.particleBurst = burst;
                db.rarities.Add(d);
            }
            R(Rarity.Common, "Обычное", "#C9D1D9", 60, 1, false, 0f, 14);
            R(Rarity.Uncommon, "Необычное", "#5BD75B", 25, 1.5, false, 0.2f, 20);
            R(Rarity.Rare, "Редкое", "#3D8BFF", 10, 2, true, 0.6f, 30);
            R(Rarity.Epic, "Эпическое", "#B04DFF", 4, 3, true, 1.0f, 45);
            R(Rarity.Legendary, "Легендарное", "#FFC21A", 0.9, 5, true, 1.5f, 70);
            R(Rarity.Mythic, "Мифическое", "#FF3D6E", 0.09, 8, true, 2.0f, 100);
            R(Rarity.Secret, "Секретное", "#19F0E0", 0.01, 15, true, 2.5f, 140);
        }

        // ---------------- Biomes ----------------
        static void AddBiomes(GameDatabase db)
        {
            void B(string id, string name, BiomeStyle style, float from, float to, string g1, string g2, string lane, string accent, string fog, string desc)
            {
                var b = Make<BiomeData>("Biome_" + id);
                b.id = id; b.displayName = name; b.style = style; b.startDistance = from; b.endDistance = to;
                b.groundColor = C(g1); b.groundColorAlt = C(g2); b.laneColor = C(lane); b.accentColor = C(accent); b.fogColor = C(fog);
                b.description = desc;
                db.biomes.Add(b);
            }
            B("forest", "Лес", BiomeStyle.Forest, 0, 60, "#6CCB4F", "#5DB843", "#E2C48B", "#2E8B3A", "#BFE6FF", "Начальная зона: улитки, кролики и совы.");
            B("savanna", "Саванна", BiomeStyle.Savanna, 60, 140, "#D9C75A", "#CDB94C", "#E8D7A0", "#C9862E", "#FFE9B8", "Зебры, жирафы и сам царь зверей.");
            B("desert", "Пустыня", BiomeStyle.Desert, 140, 240, "#F2CF86", "#E9C277", "#F8E2B0", "#D9883B", "#FFE2B0", "Верблюды, скорпионы и легенды о фениксе.");
            B("jungle", "Джунгли", BiomeStyle.Jungle, 240, 360, "#2FAE4E", "#279A43", "#B98D5A", "#14702E", "#B5F0C8", "Попугаи, тигры и гориллы.");
            B("ocean", "Океан", BiomeStyle.Ocean, 360, 500, "#F3E3A6", "#3FB8E8", "#F7EBC0", "#1E7FD0", "#A9E4FF", "Острова и необычные морские существа.");
            B("mountains", "Горы", BiomeStyle.Mountains, 500, 760, "#E9F2F7", "#C9D6DE", "#B8B0A6", "#6F7F8F", "#E6F2FF", "Снежные вершины: редкие и легендарные питомцы.");
        }

        // ---------------- Animals ----------------
        static AnimalModelSpec S(BodyPlan plan, string primary, string secondary, string accent, F features,
            float len, float height, float width, float leg, float neck, float head, float tail, float ear)
        {
            return new AnimalModelSpec
            {
                plan = plan, primary = C(primary), secondary = C(secondary), accent = C(accent), features = features,
                bodyLength = len, bodyHeight = height, bodyWidth = width, legLength = leg, neckLength = neck,
                headSize = head, tailLength = tail, earSize = ear
            };
        }

        static void AddAnimals(GameDatabase db)
        {
            void A(string id, string name, Rarity r, string biome, float weight, double baseIncome, float size, MovementStyle move, string trait, AnimalModelSpec spec)
            {
                var a = Make<AnimalData>("Animal_" + id);
                a.id = id; a.displayName = name; a.rarity = r; a.biomeId = biome; a.spawnWeight = weight; a.baseIncome = baseIncome;
                a.size = size; a.movement = move; a.trait = trait; a.model = spec;
                db.animals.Add(a);
            }

            // Forest
            A("snail", "Улитка", Rarity.Common, "forest", 1.2f, 1, 0.8f, MovementStyle.Slither, "Медленно, но верно",
                S(BodyPlan.Snail, "#E8D36A", "#C0703A", "#3A2A1A", F.None, 0.9f, 0.3f, 0.35f, 0f, 0f, 0.3f, 0f, 0.15f));
            A("frog", "Лягушка", Rarity.Common, "forest", 1f, 1.5, 0.8f, MovementStyle.Hop, "Прыгает выше всех",
                S(BodyPlan.Frog, "#4CC24A", "#B8F07A", "#E04040", F.None, 0.6f, 0.4f, 0.55f, 0.25f, 0f, 0.42f, 0f, 0f));
            A("rabbit", "Кролик", Rarity.Uncommon, "forest", 1.2f, 2, 0.8f, MovementStyle.Hop, "Пушистый хвостик",
                S(BodyPlan.Quadruped, "#F4F1EC", "#F7B8C8", "#3A3A3A", F.LongEars | F.FluffyTail | F.Whiskers, 0.6f, 0.45f, 0.42f, 0.18f, 0.05f, 0.4f, 0.12f, 0.45f));
            A("hedgehog", "Ёжик", Rarity.Uncommon, "forest", 1f, 2.5, 0.7f, MovementStyle.Walk, "Колючий, но добрый",
                S(BodyPlan.Quadruped, "#8A5A3C", "#E9CFA8", "#2A2A2A", F.Spikes | F.Snout | F.RoundEars, 0.65f, 0.42f, 0.5f, 0.1f, 0f, 0.32f, 0.05f, 0.12f));
            A("owl", "Сова", Rarity.Rare, "forest", 1f, 4, 0.8f, MovementStyle.Fly, "Видит в темноте",
                S(BodyPlan.Bird, "#9A6A42", "#F0DDB5", "#FFC21A", F.Beak | F.Wings | F.PointyEars, 0.55f, 0.75f, 0.55f, 0.12f, 0f, 0.48f, 0.1f, 0.15f));
            A("fox", "Лиса", Rarity.Epic, "forest", 1f, 6, 0.9f, MovementStyle.Walk, "Хитрая: иногда приносит монетку",
                S(BodyPlan.Quadruped, "#F07A22", "#FFFFFF", "#2A2A2A", F.PointyEars | F.FluffyTail | F.Snout, 0.9f, 0.5f, 0.42f, 0.35f, 0.1f, 0.42f, 0.6f, 0.25f));
            A("unicorn", "Единорог", Rarity.Secret, "forest", 1f, 20, 1.1f, MovementStyle.Walk, "Секрет леса. Говорят, его видели лишь однажды",
                S(BodyPlan.Quadruped, "#FFFFFF", "#FF9BE0", "#FFD54A", F.SingleHorn | F.Mane | F.Halo, 1.1f, 0.65f, 0.48f, 0.65f, 0.45f, 0.42f, 0.45f, 0.15f));

            // Savanna
            A("cow", "Корова", Rarity.Common, "savanna", 1f, 20, 1f, MovementStyle.Walk, "Даёт молоко и монеты",
                S(BodyPlan.Quadruped, "#FFFFFF", "#2B2B2B", "#F5A6B5", F.Horns | F.Spots | F.Snout | F.RoundEars, 1.2f, 0.75f, 0.65f, 0.5f, 0.1f, 0.5f, 0.35f, 0.18f));
            A("zebra", "Зебра", Rarity.Uncommon, "savanna", 1f, 60, 1f, MovementStyle.Walk, "Нет двух одинаковых полосок",
                S(BodyPlan.Quadruped, "#F5F5F5", "#1E1E1E", "#1E1E1E", F.Stripes | F.Mane | F.PointyEars, 1.15f, 0.65f, 0.5f, 0.7f, 0.4f, 0.42f, 0.35f, 0.18f));
            A("giraffe", "Жираф", Rarity.Rare, "savanna", 1f, 60, 1.1f, MovementStyle.Walk, "Достаёт до облаков",
                S(BodyPlan.Quadruped, "#F2C14E", "#A0612C", "#6B3E1C", F.LongNeck | F.Spots | F.Horns | F.PointyEars, 1.0f, 0.6f, 0.48f, 1.0f, 1.4f, 0.38f, 0.35f, 0.15f));
            A("lion", "Лев", Rarity.Epic, "savanna", 1f, 150, 1.1f, MovementStyle.Walk, "Царь саванны",
                S(BodyPlan.Quadruped, "#E8B04A", "#9A4E1A", "#2A2A2A", F.Mane | F.RoundEars | F.Whiskers | F.Snout, 1.2f, 0.65f, 0.55f, 0.55f, 0.15f, 0.5f, 0.55f, 0.15f));
            A("elephant", "Слон", Rarity.Legendary, "savanna", 1f, 200, 1.4f, MovementStyle.Walk, "Никогда не забывает о доходе",
                S(BodyPlan.Quadruped, "#9AA3AD", "#C9D0D6", "#FFF6E0", F.Trunk | F.Tusks | F.RoundEars, 1.4f, 0.95f, 0.9f, 0.6f, 0f, 0.62f, 0.2f, 0.5f));

            // Desert
            A("lizard", "Ящерица", Rarity.Common, "desert", 1f, 150, 0.8f, MovementStyle.Walk, "Греется на солнце",
                S(BodyPlan.Quadruped, "#9BC24A", "#E6D27A", "#2A2A2A", F.Spikes, 1.0f, 0.25f, 0.35f, 0.12f, 0.05f, 0.3f, 0.9f, 0f));
            A("camel", "Верблюд", Rarity.Common, "desert", 1f, 200, 1.2f, MovementStyle.Walk, "Неделю без воды",
                S(BodyPlan.Quadruped, "#D9A55B", "#B8843F", "#4A3020", F.Hump | F.LongNeck | F.Snout, 1.2f, 0.7f, 0.55f, 0.9f, 0.6f, 0.4f, 0.3f, 0.1f));
            A("fennec", "Фенек", Rarity.Uncommon, "desert", 1f, 300, 0.75f, MovementStyle.Hop, "Самые большие уши",
                S(BodyPlan.Quadruped, "#F2D29B", "#FFF3DD", "#2A2A2A", F.PointyEars | F.FluffyTail | F.Snout, 0.65f, 0.42f, 0.38f, 0.28f, 0.05f, 0.38f, 0.45f, 0.55f));
            A("scorpion", "Скорпион", Rarity.Rare, "desert", 1f, 500, 0.9f, MovementStyle.Walk, "Жало из чистого янтаря",
                S(BodyPlan.Bug, "#3A2A2A", "#D8572A", "#FFB300", F.Pincers | F.Stinger, 0.8f, 0.25f, 0.5f, 0.15f, 0f, 0.3f, 0.7f, 0f));
            A("ostrich", "Страус", Rarity.Epic, "desert", 1f, 1000, 1.2f, MovementStyle.Walk, "Бегает быстрее ветра",
                S(BodyPlan.Bird, "#2E2A2A", "#F2F2F2", "#F4A25B", F.Beak | F.LongNeck, 0.8f, 0.6f, 0.6f, 0.9f, 0.9f, 0.3f, 0.25f, 0f));
            A("phoenix", "Феникс", Rarity.Mythic, "desert", 1f, 2500, 1.2f, MovementStyle.Fly, "Возрождается из пепла",
                S(BodyPlan.Bird, "#FF5A1F", "#FFC21A", "#FF2B2B", F.Beak | F.Wings | F.Crest | F.Fire, 0.8f, 0.6f, 0.5f, 0.15f, 0.1f, 0.42f, 0.8f, 0.2f));
            A("scarab", "Золотой скарабей", Rarity.Secret, "desert", 1f, 2000, 0.9f, MovementStyle.Walk, "Тайный хранитель пирамид",
                S(BodyPlan.Bug, "#FFD54A", "#2BB5A6", "#B57A12", F.Halo | F.Horns, 0.8f, 0.4f, 0.65f, 0.15f, 0f, 0.3f, 0f, 0f));

            // Jungle
            A("parrot", "Попугай", Rarity.Common, "jungle", 1f, 1500, 0.8f, MovementStyle.Fly, "Повторяет «ням-ням»",
                S(BodyPlan.Bird, "#E8262E", "#2E7CF6", "#FFD21A", F.Beak | F.Wings | F.Crest, 0.5f, 0.55f, 0.42f, 0.12f, 0f, 0.38f, 0.55f, 0f));
            A("monkey", "Обезьянка", Rarity.Uncommon, "jungle", 1f, 2000, 0.8f, MovementStyle.Hop, "Обожает бананы",
                S(BodyPlan.Ape, "#8A5530", "#F1C9A0", "#2A2A2A", F.RoundEars, 0.5f, 0.6f, 0.45f, 0.45f, 0f, 0.45f, 0.7f, 0.15f));
            A("crocodile", "Крокодил", Rarity.Rare, "jungle", 1f, 3000, 1.2f, MovementStyle.Walk, "Улыбается во все зубы",
                S(BodyPlan.Quadruped, "#3E8E3A", "#A6CF6A", "#FFFFFF", F.Spikes | F.Snout, 1.6f, 0.35f, 0.55f, 0.15f, 0f, 0.38f, 1.1f, 0f));
            A("tiger", "Тигр", Rarity.Epic, "jungle", 1f, 3333, 1.1f, MovementStyle.Walk, "Полоски приносят удачу",
                S(BodyPlan.Quadruped, "#F28A1A", "#1E1E1E", "#FFFFFF", F.Stripes | F.RoundEars | F.Whiskers | F.Snout, 1.2f, 0.62f, 0.55f, 0.55f, 0.1f, 0.5f, 0.7f, 0.15f));
            A("gorilla", "Горилла", Rarity.Legendary, "jungle", 1f, 6000, 1.3f, MovementStyle.Walk, "Самая сильная на базе",
                S(BodyPlan.Ape, "#2F2F35", "#6B6B78", "#1E1E1E", F.None, 0.8f, 1.0f, 0.9f, 0.5f, 0f, 0.5f, 0f, 0.1f));

            // Ocean
            A("crab", "Краб", Rarity.Common, "ocean", 1f, 12000, 0.8f, MovementStyle.Walk, "Ходит боком",
                S(BodyPlan.Bug, "#E8402A", "#FF8A5A", "#FFFFFF", F.Pincers, 0.6f, 0.3f, 0.8f, 0.18f, 0f, 0.2f, 0f, 0f));
            A("turtle", "Черепаха", Rarity.Uncommon, "ocean", 1f, 15000, 0.9f, MovementStyle.Walk, "Живёт сто лет",
                S(BodyPlan.Turtle, "#7AC46A", "#5A8A3A", "#3E5E2A", F.Shell, 0.9f, 0.4f, 0.75f, 0.12f, 0.1f, 0.32f, 0.1f, 0f));
            A("dolphin", "Дельфин", Rarity.Rare, "ocean", 1f, 25000, 1f, MovementStyle.Swim, "Умнее всех в загоне",
                S(BodyPlan.Fish, "#5AA0D8", "#DDEFFF", "#2A2A2A", F.Fins | F.Snout, 1.3f, 0.5f, 0.45f, 0f, 0f, 0.4f, 0.4f, 0f));
            A("shark", "Акула", Rarity.Epic, "ocean", 1f, 40000, 1.1f, MovementStyle.Swim, "Гроза океана",
                S(BodyPlan.Fish, "#6F8899", "#F1F4F6", "#FFFFFF", F.Fins | F.Crest, 1.6f, 0.6f, 0.55f, 0f, 0f, 0.45f, 0.5f, 0f));
            A("octopus", "Осьминог", Rarity.Legendary, "ocean", 1f, 60000, 1f, MovementStyle.Slither, "Восемь рук — восемь монет",
                S(BodyPlan.Octopus, "#C04AD8", "#F29BFF", "#FFFFFF", F.None, 0.8f, 0.8f, 0.8f, 0.5f, 0f, 0.6f, 0f, 0f));
            A("whale", "Кит", Rarity.Mythic, "ocean", 1f, 100000, 1.7f, MovementStyle.Swim, "Песня кита слышна на всей базе",
                S(BodyPlan.Fish, "#3A5FA8", "#DCE8F7", "#1E2E50", F.Fins, 2.0f, 0.9f, 0.85f, 0f, 0f, 0.7f, 0.6f, 0f));

            // Mountains
            A("goat", "Горный козёл", Rarity.Common, "mountains", 1f, 100000, 1f, MovementStyle.Hop, "Скачет по скалам",
                S(BodyPlan.Quadruped, "#EDE7DC", "#8C7A66", "#4A4A4A", F.Horns | F.Snout | F.PointyEars, 0.95f, 0.6f, 0.45f, 0.55f, 0.2f, 0.4f, 0.15f, 0.15f));
            A("llama", "Лама", Rarity.Uncommon, "mountains", 1f, 130000, 1.1f, MovementStyle.Walk, "Плюётся только в своих",
                S(BodyPlan.Quadruped, "#F3E6CF", "#C88E5A", "#5A3A2A", F.LongNeck | F.Fluffy | F.LongEars, 1.0f, 0.65f, 0.55f, 0.7f, 0.75f, 0.38f, 0.2f, 0.25f));
            A("bear", "Медведь", Rarity.Rare, "mountains", 1f, 200000, 1.3f, MovementStyle.Walk, "Любит мёд и тишину",
                S(BodyPlan.Quadruped, "#7A4E2E", "#C49A6C", "#2A2A2A", F.RoundEars | F.Snout, 1.2f, 0.85f, 0.8f, 0.45f, 0.1f, 0.55f, 0.1f, 0.18f));
            A("snow_leopard", "Снежный барс", Rarity.Epic, "mountains", 1f, 350000, 1.1f, MovementStyle.Walk, "Призрак гор",
                S(BodyPlan.Quadruped, "#E8EEF2", "#5A6470", "#9FD8FF", F.Spots | F.FluffyTail | F.RoundEars | F.Whiskers, 1.15f, 0.55f, 0.5f, 0.5f, 0.1f, 0.45f, 0.9f, 0.14f));
            A("eagle", "Орёл", Rarity.Legendary, "mountains", 1f, 600000, 1.1f, MovementStyle.Fly, "Видит каждую монетку с высоты",
                S(BodyPlan.Bird, "#6B4428", "#FFFFFF", "#FFC21A", F.Beak | F.Wings, 0.7f, 0.6f, 0.55f, 0.15f, 0.1f, 0.4f, 0.35f, 0f));
            A("ice_dragon", "Ледяной дракон", Rarity.Mythic, "mountains", 1f, 1500000, 1.5f, MovementStyle.Fly, "Дыхание вечной зимы",
                S(BodyPlan.Dragon, "#7FD3FF", "#E6F7FF", "#2A6FD6", F.Wings | F.Horns | F.Spikes, 1.4f, 0.7f, 0.65f, 0.5f, 0.6f, 0.5f, 1.2f, 0.1f));
            A("yeti", "Йети", Rarity.Secret, "mountains", 1f, 1000000, 1.5f, MovementStyle.Walk, "Его никто не видел... кроме тебя",
                S(BodyPlan.Ape, "#F4F8FF", "#9CC9E8", "#3A4A6A", F.Fluffy | F.Halo, 0.9f, 1.1f, 0.95f, 0.55f, 0f, 0.55f, 0f, 0.1f));
        }

        // ---------------- Food ----------------
        static void AddFoods(GameDatabase db)
        {
            void Fd(string id, string name, int tier, double price, float bonus, float luck, string reqBiome, FoodShape shape, string c1, string c2, string desc)
            {
                var f = Make<FoodData>("Food_" + id);
                f.id = id; f.displayName = name; f.tier = tier; f.price = price; f.distanceBonus = bonus; f.luck = luck;
                f.requiredBiomeId = reqBiome; f.shape = shape; f.primary = C(c1); f.secondary = C(c2); f.description = desc;
                db.foods.Add(f);
            }
            Fd("carrot", "Морковь", 0, 0, 0, 1f, "", FoodShape.Carrot, "#FF8A1F", "#3FB54A", "Бесплатная стартовая еда.");
            Fd("apple", "Яблоко", 1, 75, 6, 1.15f, "", FoodShape.Apple, "#E8262E", "#3FB54A", "Хрустит в полёте. Немного дальше и удачнее.");
            Fd("bread", "Хлеб", 2, 600, 14, 1.3f, "", FoodShape.Bread, "#D99A4E", "#F3D19A", "Тёплый батон для голодных зверей.");
            Fd("burger", "Бургер", 3, 8000, 30, 1.5f, "savanna", FoodShape.Burger, "#9A5A2A", "#F2B544", "Двойной сыр — двойная дальность.");
            Fd("pizza", "Пицца", 4, 90000, 55, 1.8f, "desert", FoodShape.Pizza, "#F2C14E", "#E8402A", "Крутится в воздухе как диск.");
            Fd("steak", "Стейк", 5, 1200000, 90, 2.2f, "jungle", FoodShape.Steak, "#B8402A", "#F2E6D8", "Хищники чуют его за километр.");
            Fd("golden_food", "Золотая еда", 6, 20000000, 140, 2.8f, "ocean", FoodShape.GoldenStar, "#FFD54A", "#FFF3B0", "Сияет так, что редкие звери не устоят.");
            Fd("rainbow_food", "Радужная еда", 7, 400000000, 200, 3.6f, "mountains", FoodShape.RainbowCake, "#FF5AC8", "#5AD8FF", "Легендарное лакомство для мифических существ.");
        }

        // ---------------- Trainers ----------------
        static void AddTrainers(GameDatabase db)
        {
            void T(string id, string name, double price, double xp, int level, TrainerShape shape, string color, string desc)
            {
                var t = Make<TrainerData>("Trainer_" + id);
                t.id = id; t.displayName = name; t.price = price; t.xpPerRep = xp; t.requiredPowerLevel = level; t.shape = shape;
                t.color = C(color); t.description = desc;
                db.trainers.Add(t);
            }
            T("pullup_bar", "Турник", 0, 1, 0, TrainerShape.PullUpBar, "#9AA3AD", "Базовые подтягивания: +1 опыт за повтор.");
            T("dumbbells", "Гантели", 150, 3, 0, TrainerShape.Dumbbells, "#3D8BFF", "+3 опыта за повтор.");
            T("barbell", "Штанга", 3000, 10, 8, TrainerShape.Barbell, "#E8402A", "+10 опыта за повтор.");
            T("kettlebell", "Гиря", 60000, 40, 15, TrainerShape.Kettlebell, "#2B2B2B", "+40 опыта за повтор.");
            T("power_rack", "Силовая рама", 1500000, 160, 25, TrainerShape.PowerRack, "#FFC21A", "+160 опыта за повтор.");
            T("cosmic_machine", "Космо-тренажёр", 50000000, 700, 40, TrainerShape.CosmicMachine, "#B04DFF", "+700 опыта за повтор.");
        }

        // ---------------- Upgrades ----------------
        static void AddUpgrades(GameDatabase db)
        {
            void U(string id, string name, UpgradeEffect effect, double cost, double growth, int max, float value, string color, string desc)
            {
                var u = Make<UpgradeData>("Upgrade_" + id);
                u.id = id; u.displayName = name; u.effect = effect; u.baseCost = cost; u.costGrowth = growth; u.maxLevel = max;
                u.valuePerLevel = value; u.color = C(color); u.description = desc;
                db.upgrades.Add(u);
            }
            U("pen_capacity", "Больше загон", UpgradeEffect.PenCapacity, 250, 3.2, 8, 1, "#5BD75B", "+1 место в загоне.");
            U("strong_arms", "Сильные руки", UpgradeEffect.StrongArms, 500, 2.4, 30, 0.08f, "#FF8A1F", "+8% к дальности от силы.");
            U("luck", "Удача", UpgradeEffect.Luck, 1000, 2.6, 25, 0.06f, "#B04DFF", "+6% к шансу редких животных.");
            U("offline", "Ночная смена", UpgradeEffect.OfflineHours, 2000, 2.5, 10, 1, "#3D8BFF", "+1 час накопления дохода вне игры.");
            U("training_boost", "Протеин", UpgradeEffect.TrainingBoost, 400, 2.3, 30, 0.15f, "#E8402A", "+15% опыта за тренировку.");
        }
    }
}
