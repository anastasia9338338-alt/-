using UnityEngine;
using ZooThrow.Animals;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Player;
using ZooThrow.SaveSystem;
using ZooThrow.World;

namespace ZooThrow.Throwing
{
    public enum ThrowPhase { None, Aiming, WindUp, Flying, Reward }

    /// <summary>
    /// The main loop of a throw: accuracy meter → wind-up → ballistic flight followed by the camera →
    /// landing in a biome → random animal → reward reveal.
    /// </summary>
    public class ThrowController : MonoBehaviour
    {
        const float ReleaseTime = 0.32f;
        const float SmallRewardHold = 2.2f;

        GameManager _g;
        FoodProjectile _projectile;
        GameObject _heldFood;
        AnimalActor _rewardActor;
        float _phaseTime;
        int _aimStartFrame;
        bool _waitingForModal;
        FoodData _food;

        public ThrowMeter Meter { get; } = new ThrowMeter();
        public ThrowPhase Phase { get; private set; }
        public ThrowResult LastResult { get; private set; }
        public float LiveDistance { get; private set; }

        public void Init(GameManager g)
        {
            _g = g;
            _projectile = FoodProjectile.Create(transform);
            _heldFood = new GameObject("HeldFood");
            Visuals.MaterialLibrary.AddRenderer(_heldFood, null);
            _heldFood.SetActive(false);
        }

        public bool IsBusy => Phase != ThrowPhase.None;

        public bool PlayerOnPad
        {
            get
            {
                var p = _g.Player.transform.position;
                var d = new Vector2(p.x - WorldLayout.ThrowPad.x, p.z - WorldLayout.ThrowPad.z);
                return d.magnitude <= WorldLayout.PadRadius && Mathf.Abs(p.y - WorldLayout.ThrowPad.y) < 2f;
            }
        }

        /// <summary>Starts aiming. Off the pad the player is brought to the pad first.</summary>
        public void RequestThrow()
        {
            if (_g.Mode == GameMode.Training) _g.Training.StopTraining();
            if (_g.Mode != GameMode.Playing || Phase != ThrowPhase.None) return;
            _food = _g.Foods.Selected;
            if (_food == null) return;

            if (!PlayerOnPad)
            {
                _g.Vfx.Poof(_g.Player.transform.position + Vector3.up);
                _g.Player.Teleport(WorldLayout.ThrowPad + Vector3.up * 0.3f, 0f);
                _g.Vfx.Poof(WorldLayout.ThrowPad + Vector3.up);
                _g.Sound.Play(Audio.Sfx.Teleport, 0.6f);
            }
            _g.Player.FaceYaw(0f);
            _g.Player.StopMotion();
            _g.SetMode(GameMode.Aiming);
            Phase = ThrowPhase.Aiming;
            _g.Cam.SetAim();
            _g.Player.Avatar.SetPose(AvatarPose.Aim);
            AttachHeldFood();

            var b = _g.Balance;
            float speed = b.meterCyclesPerSecond + b.meterSpeedPerBiome * Mathf.Max(0, _g.Biomes.UnlockedCount - 1);
            Meter.Start(speed, Random.Range(0.35f, 0.65f), Random.value);
            _aimStartFrame = Time.frameCount;
            _g.UI.ShowMeter(true);
            _g.Sound.Play(Audio.Sfx.Click);
        }

        void AttachHeldFood()
        {
            var hand = _g.Player.Avatar.RightHand;
            _heldFood.GetComponent<MeshFilter>().sharedMesh = FoodModelFactory.Get(_food);
            _heldFood.transform.SetParent(hand, false);
            _heldFood.transform.localPosition = Vector3.zero;
            _heldFood.transform.localRotation = Quaternion.identity;
            _heldFood.transform.localScale = Vector3.one * 0.9f;
            _heldFood.SetActive(true);
        }

        public void CancelAim()
        {
            if (Phase != ThrowPhase.Aiming) return;
            Meter.Cancel();
            Phase = ThrowPhase.None;
            _heldFood.SetActive(false);
            _g.UI.ShowMeter(false);
            _g.Player.Avatar.SetPose(AvatarPose.Locomotion);
            _g.Cam.SetFollow();
            _g.SetMode(GameMode.Playing);
        }

        /// <summary>Stops the meter and starts the throw animation.</summary>
        public void ConfirmAim()
        {
            if (Phase != ThrowPhase.Aiming) return;
            float offset = Meter.Stop();
            var s = _g.State;
            var result = ThrowMath.Compute(_g.Balance, s.powerLevel, _g.Upgrades.ArmsMultiplier, _food, offset, _g.Upgrades.LuckMultiplier, (float)_g.Rng.NextDouble());
            LastResult = result;
            Phase = ThrowPhase.WindUp;
            _phaseTime = 0f;
            _g.SetMode(GameMode.Throwing);
            _g.Player.Avatar.SetPose(AvatarPose.Throw);
            _g.UI.ShowMeter(false);
            _g.UI.ShowGrade(result);
            switch (result.grade)
            {
                case ThrowGrade.Perfect:
                    _g.Sound.Play(Audio.Sfx.Perfect);
                    _g.Vfx.Sparkle(_g.Player.transform.position + Vector3.up * 2.5f, new Color(1f, 0.85f, 0.2f), 40);
                    _g.Cam.Shake(0.35f);
                    break;
                case ThrowGrade.Great: _g.Sound.Play(Audio.Sfx.Great); break;
                case ThrowGrade.Good: _g.Sound.Play(Audio.Sfx.Good); break;
                default: _g.Sound.Play(Audio.Sfx.Weak); break;
            }
        }

        void Update()
        {
            if (_g == null) return;
            float dt = Time.deltaTime;
            switch (Phase)
            {
                case ThrowPhase.Aiming:
                    Meter.Tick(dt);
                    if (Time.frameCount > _aimStartFrame + 1)
                    {
                        if (GameInput.Pressed(GameKey.Menu)) { CancelAim(); break; }
                        bool click = GameInput.PrimaryPressed && !_g.UI.PointerOverUI;
                        if (click || GameInput.Pressed(GameKey.Jump) || GameInput.Pressed(GameKey.Throw) || GameInput.Pressed(GameKey.Interact))
                            ConfirmAim();
                    }
                    break;
                case ThrowPhase.WindUp:
                    _phaseTime += dt;
                    if (_phaseTime >= ReleaseTime) Launch();
                    break;
                case ThrowPhase.Flying:
                    LiveDistance = Mathf.Max(0f, WorldLayout.DistanceOf(_projectile.transform.position));
                    break;
                case ThrowPhase.Reward:
                    _phaseTime += dt;
                    if (!_waitingForModal && _phaseTime >= SmallRewardHold) FinishThrow();
                    break;
            }
        }

        void Launch()
        {
            var b = _g.Balance;
            var r = LastResult;
            _heldFood.SetActive(false);
            Vector3 start = _g.Player.Avatar.RightHand.position;
            float lateral = Random.Range(-WorldLayout.LaneHalfWidth * 0.45f, WorldLayout.LaneHalfWidth * 0.45f);
            Vector3 end = WorldLayout.TrackPoint(r.total, lateral);
            end.y = _g.World.GroundHeightAt(end);
            float height = ThrowMath.ArcHeight(b, r.total);
            float duration = ThrowMath.FlightTime(b, r.total);
            var trailColor = r.grade == ThrowGrade.Perfect ? new Color(1f, 0.85f, 0.2f) : _food.primary;
            _projectile.Launch(FoodModelFactory.Get(_food), start, end, height, duration, trailColor, OnLanded);
            Phase = ThrowPhase.Flying;
            LiveDistance = 0f;
            _g.Cam.SetProjectile(_projectile.transform);
            _g.Sound.Play(Audio.Sfx.Whoosh);
            _g.UI.ShowFlight(true);
        }

        void OnLanded(Vector3 pos)
        {
            var db = _g.Db;
            var r = LastResult;
            LiveDistance = r.total;
            _projectile.Hide();
            _g.UI.ShowFlight(false);

            var biome = db.BiomeAtDistance(r.total);
            var animal = AnimalRoller.Roll(db, biome, r.luck, _g.Rng);
            var mutation = AnimalRoller.RollMutation(_g.Balance, r.luck, _g.Rng);
            float previousBest = _g.State.bestDistance;
            var newlyUnlocked = _g.Biomes.RegisterLanding(r.total);
            var s = _g.State;
            s.totalThrows++;
            if (r.grade == ThrowGrade.Perfect) s.perfectThrows++;
            _g.SaveMgr.MarkDirty();

            _g.Vfx.Landing(pos, biome != null ? biome.laneColor : Color.white);
            _g.Sound.Play(Audio.Sfx.Land);
            _g.Cam.Shake(0.25f);

            if (animal == null)
            {
                Debug.LogError("[ZooThrow] В биоме " + (biome != null ? biome.id : "null") + " нет животных — проверь данные.");
                FinishThrow();
                return;
            }

            var owned = _g.Inventory.Add(animal, mutation, out bool firstTime, out double autoSold);
            bool placed = false;
            if (owned != null && s.settings.autoPlaceAnimals) placed = _g.Pen.Place(owned);
            var displayed = owned ?? new OwnedAnimal { uid = 0, animalId = animal.id, mutation = mutation };

            var rarity = db.GetRarity(animal.rarity);
            _g.Vfx.Confetti(pos + Vector3.up, rarity.color, rarity.particleBurst);
            if (rarity.glowIntensity > 0f) _g.Vfx.Beam(pos, rarity.color, rarity.glowIntensity);
            _g.Sound.PlayReward(animal.rarity);

            if (_rewardActor != null) Destroy(_rewardActor.gameObject);
            _rewardActor = AnimalActor.Create(animal, mutation, _g.Balance, transform, pos, _g.Rng.Next());
            _rewardActor.transform.rotation = Quaternion.Euler(0, 180f, 0);
            _rewardActor.Celebrate();
            _g.Cam.SetShowcase(pos);

            Phase = ThrowPhase.Reward;
            _phaseTime = 0f;
            _g.SetMode(GameMode.Showcase);
            _waitingForModal = rarity.bigRewardScreen;
            _g.UI.ShowReward(displayed, animal, firstTime, placed, autoSold, rarity.bigRewardScreen, OnRewardDismissed);

            if (r.total > previousBest && previousBest > 0f)
                GameEvents.RaiseToast("Новый рекорд: " + NumberFormat.Meters(r.total) + "!", new Color(1f, 0.85f, 0.25f));
            foreach (var b in newlyUnlocked) _g.UI.QueueBiomeBanner(b);
            _g.SaveNow();
        }

        void OnRewardDismissed()
        {
            _waitingForModal = false;
            if (Phase == ThrowPhase.Reward) FinishThrow();
        }

        void FinishThrow()
        {
            Phase = ThrowPhase.None;
            _waitingForModal = false;
            if (_rewardActor != null)
            {
                _g.Vfx.Poof(_rewardActor.transform.position + Vector3.up * 0.5f);
                Destroy(_rewardActor.gameObject);
                _rewardActor = null;
            }
            _g.Player.Avatar.SetPose(AvatarPose.Locomotion);
            _g.Cam.LookFromBehind(0f);
            _g.Cam.SetFollow();
            _g.SetMode(GameMode.Playing);
        }
    }
}
