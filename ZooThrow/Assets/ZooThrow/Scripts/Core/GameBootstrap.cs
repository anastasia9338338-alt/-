using UnityEngine;
using ZooThrow.Animals;
using ZooThrow.Audio;
using ZooThrow.CameraSystem;
using ZooThrow.Data;
using ZooThrow.Economy;
using ZooThrow.Player;
using ZooThrow.SaveSystem;
using ZooThrow.Throwing;
using ZooThrow.Training;
using ZooThrow.UI;
using ZooThrow.Visuals;
using ZooThrow.World;

namespace ZooThrow.Core
{
    /// <summary>
    /// Entry point. The only object in the scene: everything else (world, player, camera, UI, systems) is created
    /// here in a fixed order, so the project does not depend on hand-wired scene references.
    /// </summary>
    [DefaultExecutionOrder(-1000)]
    public class GameBootstrap : MonoBehaviour
    {
        void Awake()
        {
            // A previous game in the same scene (not one being unloaded by a progress reset) means this is a duplicate.
            if (GameManager.Instance != null && GameManager.Instance.gameObject.scene == gameObject.scene)
            {
                Destroy(gameObject);
                return;
            }
            Application.runInBackground = true;
            GameEvents.Reset();
            FontLibrary.Init();
            MaterialLibrary.Init();

            var db = Resources.Load<GameDatabase>(GameDatabase.ResourcePath);
            if (db == null)
            {
                Debug.LogWarning("[ZooThrow] Resources/" + GameDatabase.ResourcePath + " не найден — используются встроенные данные DefaultContent.");
                db = DefaultContent.Create();
            }
            db.BuildLookups();
            var problems = db.Validate();
            foreach (var p in problems) Debug.LogError("[ZooThrow] Ошибка данных: " + p);
            if (problems.Count > 0 && db.balance == null)
            {
                db = DefaultContent.Create();
                Debug.LogError("[ZooThrow] Данные непригодны, загружены встроенные.");
            }

            var save = new SaveManager(db);
            save.Load();

            var g = gameObject.AddComponent<GameManager>();
            g.Init(db, save);

            var sound = Child<SoundManager>("Audio");
            sound.Init();
            g.Sound = sound;
            var vfx = Child<VfxManager>("VFX");
            vfx.Init();
            g.Vfx = vfx;
            var portraits = Child<PortraitRenderer>("Portraits");
            portraits.Init();
            g.Portraits = portraits;

            var world = Child<WorldBuilder>("World");
            world.Build(db);
            g.World = world;

            // Camera
            var camGo = new GameObject("Main Camera");
            camGo.tag = "MainCamera";
            var cam = camGo.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.Skybox;
            cam.fieldOfView = 60f;
            cam.nearClipPlane = 0.3f;
            cam.farClipPlane = 360f;
            cam.cullingMask = ~(1 << PortraitRenderer.Layer);
            camGo.AddComponent<AudioListener>();

            // Player (on the Ignore Raycast layer so the camera collision ignores it)
            var playerGo = new GameObject("Player");
            playerGo.layer = 2;
            playerGo.AddComponent<CharacterController>();
            var player = playerGo.AddComponent<PlayerController>();
            player.Init(g, camGo.transform);
            player.Teleport(WorldLayout.Spawn, 0f);
            var interaction = playerGo.AddComponent<InteractionSystem>();
            interaction.Init(g);
            g.Player = player;

            var tpc = camGo.AddComponent<ThirdPersonCamera>();
            tpc.Init(g, playerGo.transform, cam);
            g.Cam = tpc;

            var income = Child<PassiveIncomeManager>("PassiveIncome");
            income.Init(g);
            g.Income = income;
            var training = Child<TrainingManager>("Training");
            training.Init(g);
            g.Training = training;
            var throwCtrl = Child<ThrowController>("Throwing");
            throwCtrl.Init(g);
            g.Throw = throwCtrl;

            var ui = Child<UIManager>("UIRoot");
            g.UI = ui;
            ui.Build(g);

            var pen = Child<PenView>("PenView");
            g.PenView = pen;
            pen.Init(g);
            var trainingView = Child<TrainingView>("TrainingView");
            trainingView.Init(g);

            SettingsApplier.Apply(g);
            GameEvents.SettingsChanged += () => SettingsApplier.Apply(g);

            ReportLoad(g, save);
            if (MaterialLibrary.MissingShaders.Count > 0)
                ui.Toast("Не найдены шейдеры ZooThrow — запусти «ZooThrow → Настроить проект» в редакторе", UITheme.Red);
            if (FontLibrary.UsingFallback)
                Debug.LogWarning("[ZooThrow] Запусти «ZooThrow → Настроить проект», чтобы создать кириллические шрифты.");
        }

        T Child<T>(string name) where T : Component
        {
            var go = new GameObject(name);
            go.transform.SetParent(transform, false);
            return go.AddComponent<T>();
        }

        static void ReportLoad(GameManager g, SaveManager save)
        {
            switch (save.Outcome)
            {
                case SaveManager.LoadOutcome.RestoredBackup:
                    g.UI.Message("Сохранение восстановлено", "Основное сохранение было повреждено. Загружена резервная копия.", "ОК", null);
                    break;
                case SaveManager.LoadOutcome.CorruptedReset:
                    g.UI.Message("Сохранение повреждено", "Не удалось прочитать сохранение и резервную копию. Начата новая игра.", "ОК", null);
                    break;
                case SaveManager.LoadOutcome.Loaded:
                    {
                        var (seconds, money) = g.Income.ComputeOffline(save.PreviousSaveUtcTicks);
                        if (money > 0)
                        {
                            g.Economy.Add(money);
                            g.UI.Message("С возвращением!", "Пока тебя не было (" + NumberFormat.Duration(seconds) + "), твой аквариум заработал\n<color=#73FF80><size=48>" + NumberFormat.Money(money) + "</size></color>", "ЗАБРАТЬ",
                                () => { g.Sound.Play(Sfx.Coin); g.Vfx.Coins(g.Player.transform.position + Vector3.up * 2f, 30); });
                        }
                        break;
                    }
            }
            save.Save();
        }
    }
}
