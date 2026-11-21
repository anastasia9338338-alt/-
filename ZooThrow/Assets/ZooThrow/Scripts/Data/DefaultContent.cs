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
            AddCreatures(db);
            AddRods(db);
            AddBaits(db);
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
            R(Rarity.Mythic, "Мифическое", "#FF3D6E", 0.05, 8, true, 2.0f, 100);
            R(Rarity.Secret, "Секретное", "#19F0E0", 0.002, 15, true, 2.5f, 140);
        }

        // ---------------- Locations ----------------
        // ground = shore, groundAlt = second shore tone, lane = water colour of the casting channel.
        static void AddBiomes(GameDatabase db)
        {
            void B(string id, string name, BiomeStyle style, float from, float to, string shore, string shore2, string water, string accent, string desc)
            {
                var b = Make<BiomeData>("Biome_" + id);
                b.id = id; b.displayName = name; b.style = style; b.startDistance = from; b.endDistance = to;
                b.groundColor = C(shore); b.groundColorAlt = C(shore2); b.laneColor = C(water); b.accentColor = C(accent);
                b.fogColor = C("#BFE6FF");
                b.description = desc;
                db.biomes.Add(b);
            }
            B("pond", "Тихий пруд", BiomeStyle.Pond, 0, 60, "#6CCB4F", "#5DB843", "#4FB8E0", "#2E8B3A", "Караси, окуни и лягушки. Здесь начинается путь рыбака.");
            B("river", "Горная река", BiomeStyle.River, 60, 110, "#5DBF5A", "#4FAE4E", "#3AA8E0", "#3A7BD5", "Быстрая вода: форель, лосось и огромный сом.");
            B("lake", "Зеркальное озеро", BiomeStyle.Lake, 110, 160, "#7AC45A", "#6AB34E", "#2E9BD8", "#2D6FB3", "Глубокое озеро, где, по слухам, живёт чудовище.");
            B("swamp", "Туманное болото", BiomeStyle.Swamp, 160, 230, "#6B7F3A", "#5E7034", "#5E7D4A", "#4E5E2A", "Мутная вода, змееголовы и болотная гидра.");
            B("mangrove", "Мангровые заросли", BiomeStyle.Mangrove, 230, 310, "#3FA34E", "#2F8F44", "#3BB3A8", "#1F7A5A", "Корни, крабы и рыба-пила.");
            B("reef", "Коралловый риф", BiomeStyle.Reef, 310, 400, "#F3E3A6", "#E9D693", "#29C6E0", "#FF7B8A", "Яркие рыбки, мурены и скаты-манты.");
            B("open_sea", "Открытое море", BiomeStyle.OpenSea, 400, 500, "#F0E0A8", "#E3CF92", "#1E7FD0", "#1E5FA8", "Тунцы, меч-рыба и белая акула. Где-то здесь плавает Левиафан.");
            B("arctic", "Ледяной океан", BiomeStyle.Arctic, 500, 610, "#E9F2F7", "#D2E0EA", "#5A9FD0", "#9FD8FF", "Нарвалы, косатки и ледяные змеи.");
            B("trench", "Глубоководная впадина", BiomeStyle.Trench, 610, 730, "#4A5570", "#3E4860", "#1C3A7A", "#3D8BFF", "Светящиеся рыбы, удильщики и Кракен.");
            B("volcano", "Вулканический разлом", BiomeStyle.Volcano, 730, 860, "#3A2E2E", "#2E2424", "#C45A2A", "#FF6A1F", "Кипящая вода, лавовые рыбы и огненный дракон.");
            B("atlantis", "Затонувшая Атлантида", BiomeStyle.Atlantis, 860, 1010, "#D9D2C0", "#C8BFAA", "#2BB5C8", "#FFD54A", "Руины древнего города и его стражи.");
            B("abyss", "Бездна", BiomeStyle.Abyss, 1010, 1200, "#1E1A2E", "#16131F", "#120E2A", "#B04DFF", "Край мира. Здесь живут существа, которых почти никто не видел.");
        }

        // ---------------- Creatures ----------------
        static readonly double[] ZoneIncome = { 1, 4, 15, 50, 180, 600, 2000, 7000, 25000, 90000, 300000, 1000000 };
        static readonly double[] RarityFactor = { 1, 1.3, 1.8, 2.5, 4, 6, 10 };

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

        // Fish: length, height, width (width >= 0.6 gives a whale-style horizontal tail).
        static AnimalModelSpec Fish(string p, string s, string a, F f, float len, float h, float w, float head = 0.4f) =>
            S(BodyPlan.Fish, p, s, a, f, len, h, w, 0f, 0f, head, 0.4f, 0f);

        // Sea serpent / dragon: total length, body thickness, head size.
        static AnimalModelSpec Serpent(string p, string s, string a, F f, float len, float thick, float head) =>
            S(BodyPlan.SeaSerpent, p, s, a, f, len, thick, thick, 0f, 0.8f, head, 1f, 0.2f);

        static void AddCreatures(GameDatabase db)
        {
            int zone = 0;
            string biome = "pond";
            void Zone(int index, string id) { zone = index; biome = id; }
            void A(string id, string name, Rarity r, float size, MovementStyle move, string trait, AnimalModelSpec spec)
            {
                var a = Make<AnimalData>("Animal_" + id);
                a.id = id; a.displayName = name; a.rarity = r; a.biomeId = biome; a.spawnWeight = 1f;
                a.baseIncome = System.Math.Round(ZoneIncome[zone] * RarityFactor[(int)r] * 10) / 10;
                a.size = size; a.movement = move; a.trait = trait; a.model = spec;
                db.animals.Add(a);
            }
            var Sw = MovementStyle.Swim;

            Zone(0, "pond");
            A("carp", "Карась", Rarity.Common, 0.8f, Sw, "Любит тёплую воду и хлеб",
                Fish("#D9B44A", "#F2E3A0", "#3A2A10", F.Fins, 0.9f, 0.5f, 0.3f));
            A("perch", "Окунь", Rarity.Common, 0.8f, Sw, "Полосатый хищник пруда",
                Fish("#8FBF3A", "#F2E07A", "#2A3A10", F.Stripes | F.Fins, 0.9f, 0.45f, 0.3f));
            A("frog", "Лягушка", Rarity.Uncommon, 0.8f, MovementStyle.Hop, "Клюёт на всё, что шевелится",
                S(BodyPlan.Frog, "#4CC24A", "#B8F07A", "#E04040", F.None, 0.6f, 0.4f, 0.55f, 0.25f, 0f, 0.42f, 0f, 0f));
            A("pike", "Щука", Rarity.Rare, 1.0f, Sw, "Пасть с сотней зубов",
                Fish("#6E8F4A", "#D8E6A8", "#2A3A1A", F.Spots | F.Snout | F.Fins, 1.6f, 0.4f, 0.3f));
            A("golden_carp", "Золотой карп", Rarity.Epic, 1.1f, Sw, "Говорят, исполняет желания",
                Fish("#FFB21A", "#FFE38A", "#E85A1A", F.Fins | F.Whiskers, 1.1f, 0.6f, 0.35f));
            A("lotus_serpent", "Лотосовый змей", Rarity.Legendary, 1.6f, Sw, "Спит под листьями кувшинок",
                Serpent("#4CC27A", "#FFB8D8", "#FF5AA8", F.Fins | F.Whiskers, 2.6f, 0.32f, 0.42f));

            Zone(1, "river");
            A("crayfish", "Рак", Rarity.Common, 0.8f, MovementStyle.Walk, "Пятится назад, но всегда вперёд",
                S(BodyPlan.Bug, "#B8402A", "#E8704A", "#2A1A10", F.Pincers, 0.8f, 0.28f, 0.55f, 0.15f, 0f, 0.3f, 0f, 0f));
            A("trout", "Форель", Rarity.Common, 0.9f, Sw, "Прыгает против течения",
                Fish("#8FA8B8", "#F5C3D0", "#3A4A5A", F.Spots | F.Fins, 1.1f, 0.45f, 0.3f));
            A("grayling", "Хариус", Rarity.Uncommon, 0.9f, Sw, "Плавник как парус",
                Fish("#7A8AA8", "#C8D0E0", "#B04DFF", F.Fins, 1.0f, 0.5f, 0.28f));
            A("salmon", "Лосось", Rarity.Rare, 1.1f, Sw, "Проходит сотни километров вверх по реке",
                Fish("#C8D0DC", "#FF8A6A", "#2A3A4A", F.Spots | F.Fins, 1.3f, 0.5f, 0.35f));
            A("catfish", "Сом", Rarity.Epic, 1.4f, Sw, "Усатый хозяин омута",
                Fish("#4A4A3A", "#B8B090", "#1A1A10", F.Whiskers | F.Fins, 1.8f, 0.6f, 0.55f, 0.5f));
            A("river_dragon", "Речной дракон", Rarity.Legendary, 1.8f, Sw, "Течение реки — его дыхание",
                Serpent("#3D8BFF", "#9FD8FF", "#FFFFFF", F.Horns | F.Spikes | F.Whiskers, 3.0f, 0.34f, 0.45f));

            Zone(2, "lake");
            A("bream", "Лещ", Rarity.Common, 0.9f, Sw, "Широкий, как сковородка",
                Fish("#B8A878", "#E8DCB0", "#3A3020", F.Fins, 0.9f, 0.75f, 0.25f));
            A("zander", "Судак", Rarity.Uncommon, 1.0f, Sw, "Видит в мутной воде",
                Fish("#8A9A7A", "#D8E0C0", "#2A2A1A", F.Stripes | F.Fins, 1.3f, 0.45f, 0.3f));
            A("turtle", "Черепаха", Rarity.Uncommon, 0.9f, MovementStyle.Walk, "Живёт сто лет",
                S(BodyPlan.Turtle, "#7AC46A", "#5A8A3A", "#3E5E2A", F.Shell, 0.9f, 0.4f, 0.75f, 0.12f, 0.1f, 0.32f, 0.1f, 0f));
            A("sturgeon", "Осётр", Rarity.Rare, 1.2f, Sw, "Царская рыба с костяными щитками",
                Fish("#6A7480", "#C8CCD0", "#2A2A2A", F.Spikes | F.LongSnout | F.Fins, 2.0f, 0.45f, 0.4f));
            A("giant_pike", "Царь-щука", Rarity.Epic, 1.6f, Sw, "Ей сто лет, и она всё помнит",
                Fish("#4E7A3A", "#C8E098", "#1A2A10", F.Spots | F.Snout | F.Fins, 2.0f, 0.55f, 0.4f));
            A("lake_monster", "Озёрное чудище", Rarity.Legendary, 2.0f, Sw, "Его фотографии всегда размыты",
                Serpent("#3E6E5A", "#8FB8A0", "#1A2A20", F.Fins | F.Spikes, 3.2f, 0.4f, 0.4f));
            A("crystal_carp", "Хрустальный карп", Rarity.Secret, 1.0f, Sw, "Прозрачный, как лёд. Встречается раз в жизни",
                Fish("#CFF5FF", "#FFFFFF", "#7FD3FF", F.Glow | F.Fins, 1.1f, 0.6f, 0.35f));

            Zone(3, "swamp");
            A("loach", "Вьюн", Rarity.Common, 0.9f, MovementStyle.Slither, "Выживает даже в иле",
                S(BodyPlan.Snake, "#6B5A3A", "#A89060", "#2A2010", F.None, 1.2f, 0.25f, 0.25f, 0f, 0f, 0.3f, 0f, 0f));
            A("toad", "Жаба", Rarity.Common, 0.8f, MovementStyle.Hop, "Квакает басом",
                S(BodyPlan.Frog, "#7A8A3A", "#C8C070", "#3A2A10", F.None, 0.65f, 0.45f, 0.6f, 0.25f, 0f, 0.45f, 0f, 0f));
            A("snakehead", "Змееголов", Rarity.Uncommon, 1.0f, Sw, "Умеет дышать воздухом",
                Fish("#5A6A3A", "#A8B070", "#2A3010", F.Spots | F.Snout | F.Fins, 1.4f, 0.4f, 0.3f));
            A("arapaima", "Арапайма", Rarity.Rare, 1.5f, Sw, "Чешуя прочнее брони",
                Fish("#4A5A4A", "#E8402A", "#1A1A1A", F.Fins, 2.2f, 0.55f, 0.45f));
            A("gar", "Панцирник", Rarity.Epic, 1.6f, Sw, "Живое ископаемое с клювом",
                Fish("#6A6A4A", "#C8C090", "#2A2A1A", F.LongSnout | F.Spikes | F.Spots, 2.0f, 0.4f, 0.35f));
            A("bog_hydra", "Болотная гидра", Rarity.Legendary, 2.0f, Sw, "Отрастит голову, даже если ты не просил",
                Serpent("#4E7A3A", "#9AC060", "#E8E070", F.Horns | F.Spikes, 3.0f, 0.42f, 0.45f));
            A("mire_serpent", "Тёмный змей топи", Rarity.Mythic, 2.3f, Sw, "Его глаза светятся сквозь туман",
                Serpent("#2A3A2A", "#4E6A3A", "#7FFF6A", F.Glow | F.Horns | F.Spikes, 3.6f, 0.45f, 0.5f));

            Zone(4, "mangrove");
            A("mudskipper", "Илистый прыгун", Rarity.Common, 0.7f, MovementStyle.Hop, "Гуляет по корням на плавниках",
                Fish("#8A7A5A", "#D8C8A0", "#2A2010", F.Spots | F.Fins, 0.8f, 0.35f, 0.3f));
            A("archerfish", "Брызгун", Rarity.Common, 0.8f, Sw, "Сбивает мошек струёй воды",
                Fish("#E8E0C0", "#F8F4E8", "#2A2A2A", F.Stripes | F.Fins, 0.9f, 0.5f, 0.28f));
            A("mangrove_crab", "Мангровый краб", Rarity.Uncommon, 0.8f, MovementStyle.Walk, "Синий панцирь, красные клешни",
                S(BodyPlan.Bug, "#3A6AB8", "#E8402A", "#FFFFFF", F.Pincers, 0.6f, 0.3f, 0.8f, 0.18f, 0f, 0.2f, 0f, 0f));
            A("barracuda", "Барракуда", Rarity.Rare, 1.3f, Sw, "Молния с зубами",
                Fish("#A8B8C8", "#E8ECF0", "#2A3A4A", F.Snout | F.Stripes | F.Fins, 1.8f, 0.38f, 0.3f));
            A("sawfish", "Рыба-пила", Rarity.Epic, 1.8f, Sw, "Пилит корни для развлечения",
                Fish("#8A9A9A", "#E8E8E0", "#F8F8F0", F.LongSnout | F.Spikes | F.Fins, 2.2f, 0.4f, 0.55f));
            A("mangrove_dragon", "Мангровый дракон", Rarity.Legendary, 2.0f, Sw, "Плавники как крылья",
                Serpent("#2F8F44", "#8AD86A", "#FFC21A", F.Wings | F.Horns, 3.0f, 0.38f, 0.45f));

            Zone(5, "reef");
            A("clownfish", "Рыба-клоун", Rarity.Common, 0.7f, Sw, "Живёт в анемоне",
                Fish("#FF7B1F", "#FFFFFF", "#FFFFFF", F.Stripes | F.Fins, 0.7f, 0.45f, 0.25f));
            A("tang", "Голубой хирург", Rarity.Common, 0.75f, Sw, "Ярче неба",
                Fish("#2E6CF6", "#FFD21A", "#1A1A3A", F.Fins, 0.8f, 0.6f, 0.22f));
            A("pufferfish", "Рыба-фугу", Rarity.Uncommon, 0.8f, Sw, "Раздувается от удивления",
                Fish("#E8D07A", "#FFF4D0", "#3A3A1A", F.Spikes | F.Spots, 0.8f, 0.75f, 0.55f));
            A("moray", "Мурена", Rarity.Rare, 1.2f, MovementStyle.Slither, "Выглядывает из каждой щели",
                S(BodyPlan.Snake, "#6A8A2A", "#D8E06A", "#1A2A0A", F.Spots, 1.8f, 0.3f, 0.3f, 0f, 0f, 0.35f, 0f, 0f));
            A("manta", "Манта", Rarity.Epic, 1.7f, Sw, "Парит в воде, как птица",
                S(BodyPlan.Ray, "#2A3A5A", "#F0F0F0", "#1A1A2A", F.None, 1.2f, 0.18f, 1.6f, 0f, 0f, 0.3f, 1.0f, 0f));
            A("coral_serpent", "Коралловый змей", Rarity.Legendary, 2.0f, Sw, "Чешуя из живых кораллов",
                Serpent("#FF7B8A", "#FFD5A0", "#B04DFF", F.Horns | F.Fins | F.Spikes, 3.0f, 0.38f, 0.45f));
            A("rainbow_fish", "Радужная рыба", Rarity.Secret, 1.1f, Sw, "Видели только во сне",
                Fish("#FF5AC8", "#5AD8FF", "#FFD21A", F.Glow | F.Stripes | F.Fins, 1.1f, 0.6f, 0.3f));

            Zone(6, "open_sea");
            A("mackerel", "Скумбрия", Rarity.Common, 0.9f, Sw, "Плавает огромными стаями",
                Fish("#3A6AA8", "#D8E8F0", "#1A2A3A", F.Stripes | F.Fins, 1.1f, 0.38f, 0.28f));
            A("jellyfish", "Медуза", Rarity.Common, 0.9f, Sw, "Почти вся из воды",
                S(BodyPlan.Jellyfish, "#C8A8FF", "#FFFFFF", "#FF9BE0", F.None, 0.8f, 0.6f, 0.8f, 0.9f, 0f, 0.3f, 0f, 0f));
            A("tuna", "Тунец", Rarity.Uncommon, 1.3f, Sw, "Самая быстрая рыба в море",
                Fish("#2A3A6A", "#D8E0E8", "#FFD21A", F.Fins, 1.6f, 0.6f, 0.45f));
            A("dolphin", "Дельфин", Rarity.Rare, 1.3f, Sw, "Умнее всех в аквариуме",
                Fish("#5AA0D8", "#DDEFFF", "#2A2A2A", F.Fins | F.Snout, 1.3f, 0.5f, 0.45f));
            A("swordfish", "Меч-рыба", Rarity.Epic, 1.5f, Sw, "Фехтует лучше рыцарей",
                Fish("#3A4A8A", "#C8D8E8", "#E8E8F0", F.LongSnout | F.Fins, 1.8f, 0.5f, 0.38f));
            A("white_shark", "Белая акула", Rarity.Legendary, 1.8f, Sw, "Гроза открытого моря",
                Fish("#6F8899", "#F1F4F6", "#FFFFFF", F.Fins | F.Crest, 1.8f, 0.65f, 0.55f, 0.45f));
            A("leviathan", "Левиафан", Rarity.Mythic, 2.6f, Sw, "Когда он всплывает, море темнеет",
                Serpent("#1E3A6A", "#8FB8E8", "#FFFFFF", F.Horns | F.Spikes | F.Fins, 4.0f, 0.5f, 0.55f));

            Zone(7, "arctic");
            A("cod", "Треска", Rarity.Common, 1.0f, Sw, "Главная рыба северных морей",
                Fish("#8A8A6A", "#E8E0C8", "#2A2A1A", F.Spots | F.Fins | F.Whiskers, 1.2f, 0.45f, 0.32f));
            A("herring", "Сельдь", Rarity.Common, 0.8f, Sw, "Серебрится, как снег",
                Fish("#A8B8C8", "#F0F4F8", "#2A3A4A", F.Fins, 0.9f, 0.35f, 0.24f));
            A("seal", "Тюлень", Rarity.Uncommon, 1.2f, Sw, "Любит лежать на льдине",
                Fish("#8A9AA8", "#D8E0E8", "#1A1A1A", F.Whiskers | F.Snout, 1.4f, 0.6f, 0.62f));
            A("narwhal", "Нарвал", Rarity.Rare, 1.4f, Sw, "Единорог северных морей",
                Fish("#C8D0D8", "#6A7A8A", "#F8F8F0", F.LongSnout | F.Spots, 1.8f, 0.6f, 0.62f));
            A("orca", "Косатка", Rarity.Epic, 1.8f, Sw, "Охотится всей семьёй",
                Fish("#1A1A1A", "#FFFFFF", "#FFFFFF", F.Fins | F.Snout, 2.0f, 0.75f, 0.65f, 0.5f));
            A("ice_serpent", "Ледяной змей", Rarity.Legendary, 2.3f, Sw, "Замораживает воду дыханием",
                Serpent("#7FD3FF", "#E6F7FF", "#2A6FD6", F.Horns | F.Spikes | F.Glow, 3.4f, 0.42f, 0.5f));
            A("frost_dragon", "Морозный дракон", Rarity.Mythic, 2.6f, Sw, "Его крылья — северное сияние",
                Serpent("#BFE8FF", "#FFFFFF", "#3D8BFF", F.Wings | F.Horns | F.Spikes | F.Glow, 3.8f, 0.48f, 0.55f));

            Zone(8, "trench");
            A("lanternfish", "Рыба-фонарь", Rarity.Common, 0.7f, Sw, "Освещает себе дорогу",
                Fish("#2A3A5A", "#4A5A7A", "#7FD3FF", F.Glow | F.Fins, 0.8f, 0.4f, 0.25f));
            A("hatchetfish", "Рыба-топорик", Rarity.Common, 0.7f, Sw, "Похожа на маленький топор",
                Fish("#A8B8C8", "#E0E8F0", "#7FD3FF", F.Glow, 0.6f, 0.65f, 0.2f));
            A("anglerfish", "Удильщик", Rarity.Uncommon, 1.0f, Sw, "Ловит рыбу на собственную удочку",
                Fish("#3A2A3A", "#6A5A6A", "#FFEE6A", F.Lure | F.Spikes, 1.0f, 0.75f, 0.6f, 0.6f));
            A("giant_squid", "Гигантский кальмар", Rarity.Rare, 1.5f, Sw, "Глаза размером с тарелку",
                S(BodyPlan.Octopus, "#C8402A", "#F29B8A", "#FFFFFF", F.None, 0.8f, 1.0f, 0.7f, 0.6f, 0f, 0.6f, 0f, 0f));
            A("goblin_shark", "Акула-домовой", Rarity.Epic, 1.6f, Sw, "Самая странная акула на свете",
                Fish("#E8A8B0", "#F8D8D8", "#FFFFFF", F.Crest | F.LongSnout | F.Fins, 1.8f, 0.55f, 0.45f, 0.45f));
            A("kraken", "Кракен", Rarity.Legendary, 2.4f, Sw, "Утаскивает корабли на дно",
                S(BodyPlan.Octopus, "#6A1A3A", "#C84A6A", "#FFEE6A", F.Glow, 0.8f, 1.0f, 0.9f, 0.6f, 0f, 0.7f, 0f, 0f));

            Zone(9, "volcano");
            A("lava_fish", "Лавовая рыбка", Rarity.Common, 0.8f, Sw, "Плавает в кипятке",
                Fish("#FF6A1F", "#FFC21A", "#3A1A1A", F.Glow | F.Fins, 0.9f, 0.45f, 0.28f));
            A("ember_eel", "Угольный угорь", Rarity.Common, 0.9f, MovementStyle.Slither, "Тлеет, как уголёк",
                S(BodyPlan.Snake, "#3A2A2A", "#FF6A1F", "#FFC21A", F.Glow, 1.4f, 0.28f, 0.28f, 0f, 0f, 0.32f, 0f, 0f));
            A("magma_crab", "Магмовый краб", Rarity.Uncommon, 0.9f, MovementStyle.Walk, "Панцирь из застывшей лавы",
                S(BodyPlan.Bug, "#2E2424", "#FF6A1F", "#FFC21A", F.Pincers | F.Glow, 0.7f, 0.32f, 0.85f, 0.18f, 0f, 0.22f, 0f, 0f));
            A("fire_ray", "Огненный скат", Rarity.Rare, 1.5f, Sw, "Оставляет за собой пар",
                S(BodyPlan.Ray, "#C8402A", "#FFC21A", "#3A1A1A", F.Glow, 1.1f, 0.18f, 1.5f, 0f, 0f, 0.3f, 1.0f, 0f));
            A("obsidian_shark", "Обсидиановая акула", Rarity.Epic, 1.8f, Sw, "Острая, как вулканическое стекло",
                Fish("#1E1A24", "#3A3044", "#B04DFF", F.Crest | F.Fins | F.Glow, 1.9f, 0.65f, 0.55f, 0.45f));
            A("lava_dragon", "Лавовый дракон", Rarity.Legendary, 2.4f, Sw, "Рождён в жерле вулкана",
                Serpent("#C8402A", "#FFC21A", "#2A1A1A", F.Wings | F.Horns | F.Spikes, 3.6f, 0.46f, 0.55f));
            A("phoenix_fish", "Рыба-феникс", Rarity.Mythic, 1.5f, Sw, "Возрождается из пузырьков лавы",
                Fish("#FF5A1F", "#FFC21A", "#FF2B2B", F.Glow | F.Fins | F.Crest, 1.4f, 0.7f, 0.4f));

            Zone(10, "atlantis");
            A("silverfin", "Серебрянка", Rarity.Common, 0.8f, Sw, "Плавает между колоннами",
                Fish("#D8E0E8", "#FFFFFF", "#2A3A4A", F.Fins, 0.9f, 0.4f, 0.26f));
            A("golden_koi", "Золотой кои", Rarity.Uncommon, 1.0f, Sw, "Любимец атлантов",
                Fish("#FFD54A", "#FFF3B0", "#E8402A", F.Whiskers | F.Fins | F.Spots, 1.2f, 0.55f, 0.32f));
            A("ancient_turtle", "Древняя черепаха", Rarity.Rare, 1.6f, MovementStyle.Walk, "Помнит, как утонул город",
                S(BodyPlan.Turtle, "#8AA07A", "#D8C870", "#FFD54A", F.Shell, 1.0f, 0.45f, 0.85f, 0.14f, 0.1f, 0.34f, 0.1f, 0f));
            A("guardian_ray", "Скат-страж", Rarity.Epic, 1.7f, Sw, "Охраняет ворота Атлантиды",
                S(BodyPlan.Ray, "#2BB5C8", "#FFD54A", "#1A3A4A", F.Glow, 1.2f, 0.2f, 1.7f, 0f, 0f, 0.32f, 1.1f, 0f));
            A("sea_king", "Морской царь", Rarity.Legendary, 2.4f, Sw, "Носит корону из жемчуга",
                Serpent("#FFD54A", "#2BB5C8", "#FFFFFF", F.Horns | F.Crest | F.Spikes, 3.6f, 0.46f, 0.55f));
            A("poseidon_whale", "Кит Посейдона", Rarity.Mythic, 2.4f, Sw, "Песня кита слышна по всему океану",
                Fish("#3A5FA8", "#DCE8F7", "#FFD54A", F.Fins | F.Glow, 2.2f, 0.9f, 0.85f, 0.7f));
            A("golden_dragon", "Золотой дракон", Rarity.Secret, 2.8f, Sw, "Шанс встретить его почти нулевой",
                Serpent("#FFD54A", "#FFF3B0", "#FF8A1F", F.Wings | F.Horns | F.Spikes | F.Glow, 4.0f, 0.5f, 0.6f));

            Zone(11, "abyss");
            A("void_fish", "Пустотная рыба", Rarity.Common, 0.9f, Sw, "Сквозь неё видно темноту",
                Fish("#2A1A3A", "#4A3A5A", "#B04DFF", F.Glow | F.Fins, 1.0f, 0.45f, 0.28f));
            A("ghost_jelly", "Призрачная медуза", Rarity.Common, 1.0f, Sw, "Светится в полной темноте",
                S(BodyPlan.Jellyfish, "#C8B8FF", "#FFFFFF", "#7FFFD0", F.Glow, 0.9f, 0.7f, 0.9f, 1.1f, 0f, 0.3f, 0f, 0f));
            A("bone_fish", "Костяная рыба", Rarity.Uncommon, 1.0f, Sw, "Плавает уже без чешуи",
                Fish("#E8E0D0", "#8A8070", "#2A2A2A", F.Spikes | F.Stripes, 1.2f, 0.5f, 0.3f));
            A("abyss_angler", "Глубинный удильщик", Rarity.Rare, 1.3f, Sw, "Его фонарь видно за километр",
                Fish("#1A1A2A", "#3A3A4A", "#7FFFD0", F.Lure | F.Spikes | F.Glow, 1.1f, 0.8f, 0.62f, 0.65f));
            A("shadow_shark", "Теневая акула", Rarity.Epic, 1.9f, Sw, "Нападает без звука",
                Fish("#1A1A24", "#2A2A3A", "#B04DFF", F.Crest | F.Glow | F.Fins, 2.0f, 0.65f, 0.55f, 0.45f));
            A("abyss_dragon", "Дракон Бездны", Rarity.Legendary, 2.6f, Sw, "Тот самый силуэт из глубины",
                Serpent("#1A1424", "#3A2A4A", "#B04DFF", F.Wings | F.Horns | F.Spikes | F.Glow, 4.0f, 0.5f, 0.6f));
            A("elder_leviathan", "Древний Левиафан", Rarity.Mythic, 3.0f, Sw, "Старше, чем сам океан",
                Serpent("#2A2A3A", "#5A4A7A", "#7F5AFF", F.Horns | F.Spikes | F.Fins | F.Glow, 4.4f, 0.55f, 0.65f));
            A("void_titan", "Титан Пустоты", Rarity.Secret, 3.0f, Sw, "Легенда, в которую никто не верит",
                Serpent("#0E0A18", "#3A1A4A", "#FF3DCE", F.Wings | F.Horns | F.Spikes | F.Glow | F.Halo, 4.4f, 0.55f, 0.65f));
        }

        // ---------------- Rods (shop 1) ----------------
        static void AddRods(GameDatabase db)
        {
            RodData R(string id, string name, int tier, double price, float distance, float luck, string reqBiome, float length, bool glows, string desc)
            {
                var r = Make<RodData>("Rod_" + id);
                r.id = id; r.displayName = name; r.tier = tier; r.price = price; r.distanceBonus = distance; r.luck = luck;
                r.requiredBiomeId = reqBiome; r.length = length; r.glows = glows; r.description = desc;
                db.rods.Add(r);
                return r;
            }
            void Look(RodData r, string blank, string grip, string reel, string metal, string accent, string line,
                RodPattern pattern, RodGlyph motif, RodGlyph emblem, RodGlyph charm, string charmColor)
            {
                r.primary = C(blank); r.secondary = C(grip); r.reelColor = C(reel); r.metal = C(metal); r.accent = C(accent);
                r.lineColor = C(line); r.pattern = pattern; r.motif = motif; r.emblem = emblem; r.charm = charm; r.charmColor = C(charmColor);
            }
            const string Gold = "#E8C24A", Silver = "#D8DDE4";
            Look(R("bamboo_rod", "Бамбуковая удочка", 0, 0, 0, 1f, "", 2.0f, false, "Бесплатная стартовая удочка."),
                "#D9B867", "#6B4628", "#E8DCC0", "#C8B070", "#7FA84A", "#FFFFFF", RodPattern.BambooNodes, RodGlyph.Leaf, RodGlyph.Leaf, RodGlyph.Leaf, "#6DBA4A");
            Look(R("willow_rod", "Ивовая удочка", 1, 100, 8, 1f, "", 2.2f, false, "Гибкая и лёгкая."),
                "#8DB04A", "#6B4628", "#E0D2A8", Gold, "#C8E08A", "#FFFFFF", RodPattern.Plain, RodGlyph.Leaf, RodGlyph.Leaf, RodGlyph.Sprout, "#6DBA4A");
            Look(R("carbon_rod", "Карбоновая удочка", 2, 1200, 20, 1.03f, "river", 2.4f, false, "Забрасывает заметно дальше."),
                "#24242C", "#C8322A", "#D8402F", Silver, "#E8402A", "#FFE36A", RodPattern.SpiralStripes, RodGlyph.None, RodGlyph.Triangle, RodGlyph.Tag, "#D8322A");
            Look(R("pike_spinning", "Спиннинг «Щучий»", 3, 15000, 40, 1.06f, "lake", 2.5f, false, "Для крупной озёрной рыбы."),
                "#2E6CE0", "#1E2640", "#2A3A6A", Silver, "#BFE4FF", "#9FD8FF", RodPattern.Plain, RodGlyph.Wave, RodGlyph.Wave, RodGlyph.Drop, "#4AA8FF");
            Look(R("sea_spinning", "Морской спиннинг", 4, 200000, 75, 1.1f, "mangrove", 2.7f, false, "Выдерживает рывки тунца."),
                "#E4E8EE", "#2A62B8", "#2A62B8", Gold, "#FFD54A", "#7FD3FF", RodPattern.Plain, RodGlyph.Star, RodGlyph.Star, RodGlyph.Star, "#FFD54A");
            Look(R("ice_spinning", "Ледяной спиннинг", 5, 3000000, 120, 1.13f, "open_sea", 2.8f, true, "Не замерзает даже в Арктике."),
                "#8FB8E0", "#2A62C8", "#2A62C8", Silver, "#FFFFFF", "#E6F7FF", RodPattern.Plain, RodGlyph.Snowflake, RodGlyph.Snowflake, RodGlyph.Snowflake, "#FFFFFF");
            Look(R("volcano_rod", "Вулканический спиннинг", 6, 50000000, 190, 1.17f, "arctic", 3.0f, true, "Выкован в лаве."),
                "#1E1A1E", "#E8702A", "#E8702A", Gold, "#E8C24A", "#FFC21A", RodPattern.Ornament, RodGlyph.Spiral, RodGlyph.Spiral, RodGlyph.Tassel, "#E8702A");
            Look(R("atlantis_trident", "Трезубец Атлантиды", 7, 800000000, 280, 1.22f, "volcano", 3.2f, true, "Удочка древних морских царей."),
                "#E8A81A", "#2AA8A8", "#3AC0C0", Silver, "#FFF3B0", "#FFF3B0", RodPattern.Ornament, RodGlyph.Wave, RodGlyph.Flower, RodGlyph.Anchor, "#E8C24A");
            Look(R("legend_rod", "Радужная удочка «Легенда»", 8, 15000000000, 400, 1.3f, "atlantis", 3.4f, true, "Достаёт до самой Бездны."),
                "#D83A9A", "#2AA8A8", "#3AC0C0", Gold, "#FFB8E0", "#FFFFFF", RodPattern.Plain, RodGlyph.Flower, RodGlyph.Flower, RodGlyph.Flower, "#FF9BC8");
        }

        // ---------------- Baits (shop 2) ----------------
        static void AddBaits(GameDatabase db)
        {
            void Bt(string id, string name, int tier, double price, float luck, string reqBiome, BaitShape shape, string c1, string c2, string desc)
            {
                var b = Make<BaitData>("Bait_" + id);
                b.id = id; b.displayName = name; b.tier = tier; b.price = price; b.luck = luck; b.distanceBonus = 0f;
                b.requiredBiomeId = reqBiome; b.shape = shape; b.primary = C(c1); b.secondary = C(c2); b.description = desc;
                db.baits.Add(b);
            }
            Bt("worm", "Червяк", 0, 0, 1f, "", BaitShape.Worm, "#F29BA8", "#D86A7A", "Бесплатная стартовая наживка.");
            Bt("maggot", "Опарыш", 1, 60, 1.1f, "", BaitShape.Maggot, "#F5ECD0", "#D8C8A0", "Мелкая рыба его обожает.");
            Bt("corn", "Кукуруза", 2, 600, 1.2f, "river", BaitShape.Corn, "#FFD21A", "#6AB84A", "Сладкая приманка для карпов.");
            Bt("shrimp", "Креветка", 3, 7000, 1.35f, "lake", BaitShape.Shrimp, "#FF8A6A", "#FFC8B0", "Морской деликатес.");
            Bt("minnow", "Живец", 4, 80000, 1.5f, "swamp", BaitShape.Minnow, "#A8B8C8", "#E8ECF0", "Хищники не устоят.");
            Bt("squid", "Кальмар", 5, 1000000, 1.7f, "reef", BaitShape.Squid, "#F29B8A", "#C8402A", "Для больших морских охотников.");
            Bt("golden_spoon", "Золотая блесна", 6, 15000000, 2.0f, "open_sea", BaitShape.Spoon, "#FFD54A", "#FFF3B0", "Сверкает так, что видно со дна.");
            Bt("glow_orb", "Светящаяся приманка", 7, 250000000, 2.4f, "trench", BaitShape.GlowOrb, "#7FFFD0", "#B04DFF", "Приманивает существ из темноты.");
            Bt("dragon_bait", "Драконья приманка", 8, 5000000000, 3.0f, "atlantis", BaitShape.DragonBait, "#E8262E", "#FFC21A", "Говорят, на неё клюют драконы.");
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
            T("gravity_kettlebell", "Гравитационная гиря", 2000000000, 3000, 55, TrainerShape.Kettlebell, "#7F5AFF", "+3000 опыта за повтор.");
            T("star_machine", "Звёздный тренажёр", 80000000000, 12000, 70, TrainerShape.CosmicMachine, "#19F0E0", "+12000 опыта за повтор.");
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
            U("pen_capacity", "Больше аквариум", UpgradeEffect.PenCapacity, 250, 3.2, 8, 1, "#5BD75B", "+1 место в аквариуме.");
            U("strong_arms", "Сильные руки", UpgradeEffect.StrongArms, 500, 2.4, 30, 0.08f, "#FF8A1F", "+8% к дальности заброса от силы.");
            U("luck", "Удача рыбака", UpgradeEffect.Luck, 1000, 2.6, 25, 0.02f, "#B04DFF", "+2% к удаче редкого улова.");
            U("offline", "Ночная смена", UpgradeEffect.OfflineHours, 2000, 2.5, 10, 1, "#3D8BFF", "+1 час накопления дохода вне игры.");
            U("training_boost", "Протеин", UpgradeEffect.TrainingBoost, 400, 2.3, 30, 0.15f, "#E8402A", "+15% опыта за тренировку.");
        }
    }
}
