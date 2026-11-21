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
    public enum ThrowPhase { None, Aiming, WindUp, Flying, Bite, Hook, Reel, Jump, Reward }

    /// <summary>
    /// The fishing loop: accuracy meter → cast → the bobber flies along a ballistic arc followed by the camera →
    /// it lands in a location → wait for the bite → hook set (a reaction test that boosts luck) → the catch is
    /// reeled towards the pier, fighting and splashing (clicks reel faster) → it leaps out of the water → reward.
    /// The rod is always in the player's hand; the line runs from the rod tip to the bobber, then to the catch.
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
        Transform _lineTarget;

        // Hook and reel state
        const float HookWindow = 1.1f;
        const float PerfectHook = 0.35f;
        float _nextDip;
        AnimalData _caught;
        Mutation _caughtMutation;
        float _hookLuck = 1f;
        float _reelProgress, _reelDuration, _fight, _splashTimer;
        Vector3 _reelFrom, _reelTo, _jumpFrom, _jumpTo;
        bool _bigCatch;

        /// <summary>Reel progress 0..1 and the remaining distance in metres, for the HUD.</summary>
        public float ReelProgress => _reelProgress;
        public float ReelMetersLeft => _rewardActor != null ? Mathf.Max(0f, _rewardActor.transform.position.z - _reelTo.z) : 0f;

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
                    if (_phaseTime >= _biteAt) StartHook();
                    break;
                case ThrowPhase.Hook:
                    _phaseTime += dt;
                    if (_phaseTime >= _nextDip) { _projectile.Dip(); _nextDip += 0.3f; _g.Vfx.Splash(_landing, Color.white); }
                    if (ActionPressed()) SetHook(_phaseTime);
                    else if (_phaseTime >= HookWindow) SetHook(-1f);
                    break;
                case ThrowPhase.Reel:
                    UpdateReel(dt);
                    break;
                case ThrowPhase.Jump:
                    UpdateJump(dt);
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
            Vector3 a = _rodTip.position;
            Vector3 b = _lineTarget != null ? _lineTarget.position + Vector3.up * 0.3f : _projectile.transform.position + Vector3.up * 0.25f;
            // Taut while flying and reeling, slack while the bobber floats.
            float sag = Phase == ThrowPhase.Flying || Phase == ThrowPhase.Reel || Phase == ThrowPhase.Jump ? 0.15f : Mathf.Min(6f, Vector3.Distance(a, b) * 0.08f);
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

        bool ActionPressed() =>
            (GameInput.PrimaryPressed && !_g.UI.PointerOverUI) || GameInput.Pressed(GameKey.Jump) ||
            GameInput.Pressed(GameKey.Throw) || GameInput.Pressed(GameKey.Interact);

        /// <summary>The fish bites: the bobber starts dipping and the player has a short window to set the hook.</summary>
        void StartHook()
        {
            Phase = ThrowPhase.Hook;
            _phaseTime = 0f;
            _nextDip = 0f;
            _g.UI.ShowFlight(false);
            _g.UI.ShowHook(true);
            _g.UI.WorldPopup(_landing + Vector3.up * 2.2f, "!", new Color(1f, 0.35f, 0.3f), 2.2f);
            _g.Sound.Play(Audio.Sfx.Great);
            _g.Cam.Shake(0.15f);
        }

        /// <summary>Sets the hook. A fast reaction raises the luck of this catch; a missed window lowers it.</summary>
        void SetHook(float reaction)
        {
            _g.UI.ShowHook(false);
            string text;
            Color color;
            if (reaction >= 0f && reaction <= PerfectHook) { _hookLuck = 1.25f; text = "ИДЕАЛЬНАЯ ПОДСЕЧКА!"; color = new Color(1f, 0.85f, 0.2f); _g.Sound.Play(Audio.Sfx.Perfect); }
            else if (reaction >= 0f) { _hookLuck = 1f; text = "Подсечка!"; color = new Color(0.55f, 1f, 0.55f); _g.Sound.Play(Audio.Sfx.Good); }
            else { _hookLuck = 0.85f; text = "Поздно, но рыба на крючке"; color = new Color(1f, 0.6f, 0.5f); _g.Sound.Play(Audio.Sfx.Weak); }
            _g.UI.WorldPopup(_landing + Vector3.up * 2.6f, text, color, 1.3f);

            var db = _g.Db;
            var r = LastResult;
            var biome = db.BiomeAtDistance(r.total);
            float luck = r.luck * _hookLuck;
            _caught = AnimalRoller.Roll(db, biome, luck, _g.Rng);
            _caughtMutation = AnimalRoller.RollMutation(_g.Balance, luck, _g.Rng);
            if (_caught == null)
            {
                Debug.LogError("[ZooThrow] В локации " + (biome != null ? biome.id : "null") + " нет существ — проверь данные.");
                FinishThrow();
                return;
            }

            // The catch is now on the line: hide the bobber and pull the creature towards the pier.
            _projectile.Hide();
            if (_rewardActor != null) Destroy(_rewardActor.gameObject);
            _rewardActor = AnimalActor.Create(_caught, _caughtMutation, _g.Balance, transform, _landing, _g.Rng.Next());
            _rewardActor.transform.rotation = Quaternion.Euler(0, 180f, 0);
            _lineTarget = _rewardActor.transform;
            int tier = (int)_caught.rarity;
            _bigCatch = _rewardActor.Height > 2.4f;
            _reelFrom = _landing;
            _reelTo = WorldLayout.TrackPoint(_bigCatch ? 10f : 4f);
            _reelProgress = 0f;
            _reelDuration = Mathf.Clamp(1.6f + r.total * 0.004f + tier * 0.35f, 1.6f, 6f);
            _fight = 1f + tier * 0.6f;
            _splashTimer = 0f;
            Phase = ThrowPhase.Reel;
            _phaseTime = 0f;
            _g.Cam.SetProjectile(_rewardActor.transform);
            _g.UI.ShowReel(true);
        }

        void UpdateReel(float dt)
        {
            _phaseTime += dt;
            float speed = 1f / _reelDuration;
            if (ActionPressed())
            {
                _reelProgress += 0.06f;
                _g.Sound.Play(Audio.Sfx.Rep, 0.4f, 1f + _reelProgress * 0.3f);
            }
            _reelProgress = Mathf.Min(1f, _reelProgress + speed * dt);
            float e = 1f - Mathf.Pow(1f - _reelProgress, 2f);
            Vector3 p = Vector3.Lerp(_reelFrom, _reelTo, e);
            // The fish fights: it darts left and right, harder for rare catches, calming down near the pier.
            float lateral = Mathf.Sin(_phaseTime * (3f + _fight)) * _fight * (1f - _reelProgress);
            p.x = Mathf.Clamp(p.x + lateral, -WorldLayout.LaneHalfWidth + 1f, WorldLayout.LaneHalfWidth - 1f);
            // Half under water: only the back and the dorsal fin show above the surface.
            p.y = WorldLayout.WaterLevel - _rewardActor.Height * 0.45f;
            var t = _rewardActor.transform;
            Vector3 move = p - t.position;
            t.position = p;
            if (move.sqrMagnitude > 1e-5f)
                t.rotation = Quaternion.Slerp(t.rotation, Quaternion.LookRotation(new Vector3(move.x, 0, move.z).normalized + Vector3.back * 0.5f, Vector3.up), 1f - Mathf.Exp(-8f * dt));
            _splashTimer -= dt;
            if (_splashTimer <= 0f)
            {
                _splashTimer = 0.16f;
                var biome = _g.Db.BiomeAtDistance(WorldLayout.DistanceOf(p));
                _g.Vfx.Splash(new Vector3(p.x, WorldLayout.WaterLevel, p.z), biome != null ? biome.laneColor : Color.white);
            }
            _g.UI.SetReel(_reelProgress, ReelMetersLeft);
            if (_reelProgress >= 1f) StartJump();
        }

        void StartJump()
        {
            _g.UI.ShowReel(false);
            Phase = ThrowPhase.Jump;
            _phaseTime = 0f;
            _jumpFrom = _rewardActor.transform.position;
            // Small catches land on the pier in front of the player; giants surface in the water ahead of it.
            _jumpTo = _bigCatch ? WorldLayout.TrackPoint(9f) + Vector3.up * WorldLayout.WaterLevel
                                : WorldLayout.ThrowPad + new Vector3(0, 0.3f, 2.2f);
            _rewardActor.Celebrate();
            _g.Vfx.Splash(new Vector3(_jumpFrom.x, WorldLayout.WaterLevel, _jumpFrom.z), Color.white);
            _g.Sound.Play(Audio.Sfx.Whoosh, 0.7f);
            _g.Cam.SetShowcase(_jumpTo, _rewardActor.Height);
        }

        void UpdateJump(float dt)
        {
            _phaseTime += dt;
            float k = Mathf.Clamp01(_phaseTime / 0.75f);
            float h = 2.5f + _rewardActor.Height * 0.6f;
            var p = ThrowMath.ArcPoint(_jumpFrom, _jumpTo, h, k);
            _rewardActor.transform.position = p;
            _rewardActor.transform.rotation = Quaternion.Euler(-60f + k * 60f, 180f, 0);
            if (k >= 1f) Catch();
        }

        /// <summary>The catch has landed: add it to the collection and show the reward.</summary>
        void Catch()
        {
            var db = _g.Db;
            var r = LastResult;
            Vector3 pos = _jumpTo;
            _lineTarget = null;
            _line.enabled = false;
            var animal = _caught;
            var mutation = _caughtMutation;

            float previousBest = _g.State.bestDistance;
            var newlyUnlocked = _g.Biomes.RegisterLanding(r.total);
            var s = _g.State;
            s.totalThrows++;
            if (r.grade == ThrowGrade.Perfect) s.perfectThrows++;
            _g.SaveMgr.MarkDirty();

            _g.Vfx.Splash(pos, Color.white);
            _g.Cam.Shake(0.3f);

            var owned = _g.Inventory.Add(animal, mutation, out bool firstTime, out double autoSold);
            bool placed = false;
            if (owned != null && s.settings.autoPlaceAnimals) placed = _g.Pen.Place(owned);
            var displayed = owned ?? new OwnedAnimal { uid = 0, animalId = animal.id, mutation = mutation };

            var rarity = db.GetRarity(animal.rarity);
            _g.Vfx.Confetti(pos + Vector3.up, rarity.color, rarity.particleBurst);
            if (rarity.glowIntensity > 0f) _g.Vfx.Beam(pos, rarity.color, rarity.glowIntensity);
            _g.Sound.PlayReward(animal.rarity);
            _rewardActor.transform.SetPositionAndRotation(pos, Quaternion.Euler(0, 180f, 0));
            _rewardActor.Celebrate();

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
            _lineTarget = null;
            _g.UI.ShowHook(false);
            _g.UI.ShowReel(false);
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
