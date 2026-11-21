using UnityEngine;
using ZooThrow.Animals;
using ZooThrow.Audio;
using ZooThrow.CameraSystem;
using ZooThrow.Data;
using ZooThrow.Economy;
using ZooThrow.Player;
using ZooThrow.SaveSystem;
using ZooThrow.Shops;
using ZooThrow.Throwing;
using ZooThrow.Training;
using ZooThrow.UI;
using ZooThrow.Visuals;
using ZooThrow.World;

namespace ZooThrow.Core
{
    public enum GameMode { Playing, Aiming, Throwing, Showcase, Training }

    /// <summary>Service locator for the running game. Created and wired by GameBootstrap.</summary>
    public class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }

        public GameDatabase Db { get; private set; }
        public BalanceSettings Balance => Db.balance;
        public SaveManager SaveMgr { get; private set; }
        public SaveData State => SaveMgr.Data;
        public System.Random Rng { get; private set; }

        public EconomyManager Economy { get; private set; }
        public UpgradeManager Upgrades { get; private set; }
        public BiomeManager Biomes { get; private set; }
        public BaitShop Baits { get; private set; }
        public RodShop Rods { get; private set; }
        public TrainerShop Trainers { get; private set; }
        public AnimalInventory Inventory { get; private set; }
        public AnimalPen Pen { get; private set; }

        public PassiveIncomeManager Income { get; internal set; }
        public TrainingManager Training { get; internal set; }
        public ThrowController Throw { get; internal set; }
        public PlayerController Player { get; internal set; }
        public ThirdPersonCamera Cam { get; internal set; }
        public UIManager UI { get; internal set; }
        public SoundManager Sound { get; internal set; }
        public VfxManager Vfx { get; internal set; }
        public PenView PenView { get; internal set; }
        public WorldBuilder World { get; internal set; }
        public PortraitRenderer Portraits { get; internal set; }

        public GameMode Mode { get; private set; } = GameMode.Playing;
        bool _resetting;
        float _autosaveTimer;

        public void Init(GameDatabase db, SaveManager save)
        {
            Instance = this;
            Db = db;
            SaveMgr = save;
            Rng = new System.Random(System.Environment.TickCount);
            Economy = new EconomyManager(save);
            Upgrades = new UpgradeManager(db, save, Economy);
            Biomes = new BiomeManager(db, save);
            Baits = new BaitShop(db, save, Economy, Biomes);
            Rods = new RodShop(db, save, Economy, Biomes);
            Trainers = new TrainerShop(db, save, Economy);
            Inventory = new AnimalInventory(db, save, Economy);
            Pen = new AnimalPen(db, save, Upgrades, Inventory);
        }

        public void SetMode(GameMode mode) => Mode = mode;

        public float ThrowPerfectDistance => ThrowMath.PerfectDistance(Balance, State.powerLevel, Upgrades.ArmsMultiplier, Rods.Selected, Baits.Selected);

        /// <summary>Luck of the current rod and bait including upgrades, for chance displays (no perfect bonus).</summary>
        public float CurrentLuck => ThrowMath.GearLuck(Rods.Selected, Baits.Selected) * Upgrades.LuckMultiplier;

        void Update()
        {
            if (_resetting) return;
            _autosaveTimer += Time.unscaledDeltaTime;
            if (_autosaveTimer >= Balance.autosaveSeconds)
            {
                _autosaveTimer = 0f;
                if (SaveMgr.Dirty || Economy.Money > 0) SaveMgr.Save();
            }
        }

        void OnApplicationPause(bool paused) { if (paused && !_resetting) SaveMgr?.Save(); }
        void OnApplicationFocus(bool focus) { if (!focus && !_resetting) SaveMgr?.Save(); }
        void OnApplicationQuit() { if (!_resetting) SaveMgr?.Save(); }

        public void SaveNow()
        {
            if (!_resetting) SaveMgr.Save();
        }

        /// <summary>Deletes all progress and reloads the scene.</summary>
        public void ResetProgress()
        {
            _resetting = true;
            SaveMgr.DeleteAll();
            AnimalModelFactory.ClearCache();
            var scene = UnityEngine.SceneManagement.SceneManager.GetActiveScene();
            UnityEngine.SceneManagement.SceneManager.LoadScene(scene.buildIndex >= 0 ? scene.buildIndex : 0);
        }

        void OnDestroy()
        {
            if (Instance == this) Instance = null;
        }
    }
}
