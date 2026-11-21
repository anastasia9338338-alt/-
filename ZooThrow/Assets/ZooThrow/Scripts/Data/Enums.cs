namespace ZooThrow.Data
{
    public enum Rarity { Common = 0, Uncommon = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Secret = 6 }

    public enum Mutation { None = 0, Golden = 1, Rainbow = 2, Giant = 3 }

    public enum ThrowGrade { Weak = 0, Good = 1, Great = 2, Perfect = 3 }

    public enum BodyPlan { Quadruped, Bird, Frog, Snail, Fish, Snake, Bug, Ape, Octopus, Turtle, Dragon, SeaSerpent, Jellyfish, Ray }

    public enum MovementStyle { Walk, Hop, Fly, Swim, Slither }

    /// <summary>Visual style of a fishing location: shore decoration and water tone.</summary>
    public enum BiomeStyle { Pond, River, Lake, Swamp, Mangrove, Reef, OpenSea, Arctic, Trench, Volcano, Atlantis, Abyss }

    public enum BaitShape { Worm, Maggot, Corn, Shrimp, Minnow, Squid, Spoon, GlowOrb, DragonBait }

    /// <summary>Small decorative symbol used for rod emblems, blank motifs and charms.</summary>
    public enum RodGlyph { None, Leaf, Snowflake, Flower, Star, Triangle, Wave, Spiral, Anchor, Tag, Drop, Tassel, Sprout }

    /// <summary>Surface treatment of the rod blank.</summary>
    public enum RodPattern { Plain, BambooNodes, SpiralStripes, Ornament }

    public enum TrainerShape { PullUpBar, Dumbbells, Barbell, Kettlebell, PowerRack, CosmicMachine }

    public enum UpgradeEffect { PenCapacity, StrongArms, Luck, OfflineHours, TrainingBoost }

    [System.Flags]
    public enum AnimalFeatures
    {
        None = 0,
        LongEars = 1 << 0,
        RoundEars = 1 << 1,
        PointyEars = 1 << 2,
        Horns = 1 << 3,
        Antlers = 1 << 4,
        Mane = 1 << 5,
        Trunk = 1 << 6,
        Stripes = 1 << 7,
        Spots = 1 << 8,
        Hump = 1 << 9,
        Shell = 1 << 10,
        Beak = 1 << 11,
        Wings = 1 << 12,
        Fins = 1 << 13,
        Whiskers = 1 << 14,
        Tusks = 1 << 15,
        Crest = 1 << 16,
        Snout = 1 << 17,
        FluffyTail = 1 << 18,
        Pincers = 1 << 19,
        Stinger = 1 << 20,
        Fire = 1 << 21,
        Halo = 1 << 22,
        LongNeck = 1 << 23,
        Fluffy = 1 << 24,
        Spikes = 1 << 25,
        SingleHorn = 1 << 26,
        /// <summary>Long pointed bill (swordfish, marlin).</summary>
        LongSnout = 1 << 27,
        /// <summary>Glowing lure on a stalk (anglerfish).</summary>
        Lure = 1 << 28,
        /// <summary>Emissive glow spots for deep-sea creatures.</summary>
        Glow = 1 << 29,
    }
}
