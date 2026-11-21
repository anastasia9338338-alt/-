using UnityEngine;
using ZooThrow.Animals;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.Player;
using ZooThrow.SaveSystem;
using ZooThrow.Visuals;
using ZooThrow.World;

namespace ZooThrow.Throwing
{
    public enum ThrowPhase { None, Aiming, WindUp, Flying, Bite, Reward }

    /// <summary>
    /// The fishing loop: accuracy meter → cast → the bobber flies along a ballistic arc followed by the camera →
    /// it lands in a location → a short wait for the bite → a random creature jumps out of the water → reward reveal.
    /// The rod is always in the player's hand; the line runs from the rod tip to the bobber.
    /// </summary>
    public class ThrowController : MonoBehaviour
    {
        const float ReleaseTime = 0.32f;
        const float SmallRewardHold = 2.4f;
        const int LinePoints = 16;

        GameManager _g;
        CastProjectile _projectile;
        GameObject _rodObject;
        Transform _rodTip;
        string _rodShownId;
        LineRenderer _line;
        AnimalActor _rewardActor;
        float _phaseTime;
        float _biteAt;
        int _aimStartFrame;
        bool _waitingForModal;
        BaitData _bait;
        RodData _rod;
        Vector3 _landing;

        public ThrowMeter Meter { get; } = new ThrowMeter();
        public ThrowPhase Phase { get; private set; }
        public ThrowResult LastResult { get; private set; }
        public float LiveDistance { get; private set; }

        public void Init(GameManager g)
        {
            _g = g;
            _projectile = CastProjectile.Create(transform);
            _rodObject = new GameObject("Rod");
            MaterialLibrary.AddRenderer(_rodObject, null);
            _rodTip = new GameObject("RodTip").transform;
            _rodTip.SetParent(_rodObject.transform, false);
            var lineGo = new GameObject("FishingLine");
            lineGo.transform.SetParent(transform, false);
            _line = lineGo.AddComponent<LineRenderer>();
            _line.sharedMaterial = MaterialLibrary.Line;
            _line.positionCount = LinePoints;
            _line.widthMultiplier = 0.035f;
            _line.useWorldSpace = true;
            _line.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            _line.receiveShadows = false;
            _line.enabled = false;
            RefreshRod();
            GameEvents.ShopChanged += RefreshRod;
        }

        void OnDestroy() => GameEvents.ShopChanged -= RefreshRod;

        /// <summary>Puts the selected rod into the right hand, pointing forward and up.</summary>
        void RefreshRod()
        {
            var rod = _g.Rods.Selected;
            if (rod == null || rod.id == _rodShownId) return;
            _rodShownId = rod.id;
            _rodObject.GetComponent<MeshFilter>().sharedMesh = RodModelFactory.Get(rod);
            _rodObject.transform.SetParent(_g.Player.Avatar.RightHand, false);
            _rodObject.transform.localPosition = new Vector3(0, -0.05f, 0);
            _rodObject.transform.localRotation = Quaternion.Euler(60f, 0, 0);
            _rodTip.localPosition = RodModelFactory.TipLocal(rod);
            _line.startColor = _line.endColor = rod.lineColor;
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

        /// <summary>Starts aiming. Off the pier the player is brought to the casting spot first.</summary>
        public void RequestThrow()
        {
            if (_g.Mode == GameMode.Training) _g.Training.StopTraining();
            if (_g.Mode != GameMode.Playing || Phase != ThrowPhase.None) return;
            _bait = _g.Baits.Selected;
            _rod = _g.Rods.Selected;
            if (_bait == null || _rod == null) return;

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

            var b = _g.Balance;
            float speed = b.meterCyclesPerSecond + b.meterSpeedPerBiome * Mathf.Max(0, _g.Biomes.UnlockedCount - 1);
            Meter.Start(speed, Random.Range(0.35f, 0.65f), Random.value);
            _aimStartFrame = Time.frameCount;
            _g.UI.ShowMeter(true);
            _g.Sound.Play(Audio.Sfx.Click);
        }

        public void CancelAim()
        {
            if (Phase != ThrowPhase.Aiming) return;
            Meter.Cancel();
            Phase = ThrowPhase.None;
            _g.UI.ShowMeter(false);
            _g.Player.Avatar.SetPose(AvatarPose.Locomotion);
            _g.Cam.SetFollow();
            _g.SetMode(GameMode.Playing);
        }

        /// <summary>Stops the meter and starts the cast animation.</summary>
        public void ConfirmAim()
        {
            if (Phase != ThrowPhase.Aiming) return;
            float offset = Meter.Stop();
            var s = _g.State;
            var result = ThrowMath.Compute(_g.Balance, s.powerLevel, _g.Upgrades.ArmsMultiplier, _rod, _bait, offset, _g.Upgrades.LuckMultiplier, (float)_g.Rng.NextDouble());
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
                case ThrowPhase.Bite:
                    _phaseTime += dt;
                    if (_phaseTime >= _biteAt) Catch();
                    break;
                case ThrowPhase.Reward:
                    _phaseTime += dt;
                    if (!_waitingForModal && _phaseTime >= SmallRewardHold) FinishThrow();
                    break;
            }
        }

        void LateUpdate()
        {
            if (!_line.enabled) return;
            // A sagging line from the rod tip to the bobber; taut while flying, slack while floating.
            Vector3 a = _rodTip.position, b = _projectile.transform.position + Vector3.up * 0.25f;
            float sag = Phase == ThrowPhase.Flying ? 0.2f : Mathf.Min(6f, Vector3.Distance(a, b) * 0.08f);
            for (int i = 0; i < LinePoints; i++)
            {
                float t = i / (float)(LinePoints - 1);
                Vector3 p = Vector3.Lerp(a, b, t);
                p.y -= Mathf.Sin(t * Mathf.PI) * sag;
                _line.SetPosition(i, p);
            }
        }

        void Launch()
        {
            var b = _g.Balance;
            var r = LastResult;
            Vector3 start = _rodTip.position;
            float lateral = Random.Range(-WorldLayout.LaneHalfWidth * 0.45f, WorldLayout.LaneHalfWidth * 0.45f);
            Vector3 end = WorldLayout.TrackPoint(r.total, lateral);
            end.y = WorldLayout.WaterLevel;
            _landing = end;
            float height = ThrowMath.ArcHeight(b, r.total);
            float duration = ThrowMath.FlightTime(b, r.total);
            var trailColor = r.grade == ThrowGrade.Perfect ? new Color(1f, 0.85f, 0.2f) : _rod.lineColor;
            _projectile.Launch(BaitModelFactory.Get(_bait), start, end, height, duration, trailColor, OnLanded);
            _line.enabled = true;
            Phase = ThrowPhase.Flying;
            LiveDistance = 0f;
            _g.Cam.SetProjectile(_projectile.transform);
            _g.Sound.Play(Audio.Sfx.Whoosh);
            _g.UI.ShowFlight(true);
            _g.Player.Avatar.SetPose(AvatarPose.Reel);
        }

        void OnLanded(Vector3 pos)
        {
            LiveDistance = LastResult.total;
            var biome = _g.Db.BiomeAtDistance(LastResult.total);
            _g.Vfx.Splash(pos, biome != null ? biome.laneColor : new Color(0.4f, 0.7f, 1f));
            _g.Sound.Play(Audio.Sfx.Land, 0.7f);
            Phase = ThrowPhase.Bite;
            _phaseTime = 0f;
            _biteAt = Random.Range(_g.Balance.biteDelayMin, _g.Balance.biteDelayMax);
        }

        void Catch()
        {
            var db = _g.Db;
            var r = LastResult;
            Vector3 pos = _landing;
            _projectile.Dip();
            _g.UI.WorldPopup(pos + Vector3.up * 2.2f, "КЛЮЁТ!", new Color(1f, 0.35f, 0.3f), 1.6f);
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

            _g.Vfx.Splash(pos, Color.white);
            _g.Cam.Shake(0.3f);

            if (animal == null)
            {
                Debug.LogError("[ZooThrow] В локации " + (biome != null ? biome.id : "null") + " нет существ — проверь данные.");
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
            _g.Cam.SetShowcase(pos, _rewardActor.Height);

            Phase = ThrowPhase.Reward;
            _phaseTime = 0f;
            _g.SetMode(GameMode.Showcase);
            _waitingForModal = rarity.bigRewardScreen;
            _g.UI.ShowReward(displayed, animal, firstTime, placed, autoSold, rarity.bigRewardScreen, OnRewardDismissed);

            if (r.total > previousBest && previousBest > 0f)
                GameEvents.RaiseToast("Новый рекорд заброса: " + NumberFormat.Meters(r.total) + "!", new Color(1f, 0.85f, 0.25f));
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
            _projectile.Hide();
            _line.enabled = false;
            if (_rewardActor != null)
            {
                _g.Vfx.Poof(_rewardActor.transform.position + Vector3.up * 0.5f);
                Destroy(_rewardActor.gameObject);
                _rewardActor = null;
            }
            _g.UI.ShowFlight(false);
            _g.Player.Avatar.SetPose(AvatarPose.Locomotion);
            _g.Cam.LookFromBehind(0f);
            _g.Cam.SetFollow();
            _g.SetMode(GameMode.Playing);
        }
    }
}
