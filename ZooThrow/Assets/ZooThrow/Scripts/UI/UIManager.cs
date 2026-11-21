using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.SaveSystem;
using ZooThrow.Throwing;

namespace ZooThrow.UI
{
    /// <summary>Builds the whole Canvas in code and routes UI requests from gameplay systems.</summary>
    public class UIManager : MonoBehaviour
    {
        GameManager _g;
        RectTransform _root;
        RectTransform _hudLayer, _windowLayer, _overlayLayer, _popupLayer;
        HudView _hud;
        ThrowHud _throwHud;
        RewardView _reward;
        ToastView _toasts;
        BannerView _banner;
        DialogView _dialog;
        WorldPopups _popups;
        readonly Dictionary<WindowId, UIWindow> _windows = new Dictionary<WindowId, UIWindow>();
        bool _cursorWanted = true;

        public RectTransform Root => _root;
        public bool AnyWindowOpen
        {
            get
            {
                foreach (var w in _windows.Values) if (w.IsOpen) return true;
                return (_dialog != null && _dialog.IsOpen) || (_reward != null && _reward.ModalOpen);
            }
        }
        public bool PointerOverUI => EventSystem.current != null && Cursor.lockState != CursorLockMode.Locked && EventSystem.current.IsPointerOverGameObject();
        public bool BlocksCameraLook => AnyWindowOpen;
        public bool IsTyping => false;

        public void Build(GameManager g)
        {
            _g = g;
            UIFactory.ClickSound = () => _g.Sound.Play(Audio.Sfx.Click, 0.6f);
            EnsureEventSystem();

            var canvasGo = new GameObject("UI", typeof(RectTransform));
            canvasGo.transform.SetParent(transform, false);
            canvasGo.layer = 5;
            var canvas = canvasGo.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 10;
            var scaler = canvasGo.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);
            scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
            scaler.matchWidthOrHeight = 0.6f;
            canvasGo.AddComponent<GraphicRaycaster>();
            _root = (RectTransform)canvasGo.transform;

            _popupLayer = UIFactory.Stretch(UIFactory.Rect("Popups", _root));
            _hudLayer = UIFactory.Stretch(UIFactory.Rect("HUD", _root));
            _windowLayer = UIFactory.Stretch(UIFactory.Rect("Windows", _root));
            _overlayLayer = UIFactory.Stretch(UIFactory.Rect("Overlay", _root));

            _popups = _popupLayer.gameObject.AddComponent<WorldPopups>();
            _popups.Init(_popupLayer);
            _hud = _hudLayer.gameObject.AddComponent<HudView>();
            _hud.Build(this, _g, _hudLayer);
            _throwHud = _hudLayer.gameObject.AddComponent<ThrowHud>();
            _throwHud.Build(this, _g, _hudLayer);

            AddWindow<AnimalsWindow>(WindowId.Animals, "Аквариум", IconId.Fish, UITheme.Blue, new Vector2(1500, 900));
            AddWindow<RodShopWindow>(WindowId.Rods, "Удочки", IconId.Rod, UITheme.Orange, new Vector2(1400, 860));
            AddWindow<BaitShopWindow>(WindowId.Baits, "Наживка", IconId.Worm, UITheme.Green, new Vector2(1400, 860));
            AddWindow<UpgradesWindow>(WindowId.Upgrades, "Улучшения", IconId.Upgrade, UITheme.Blue, new Vector2(1400, 880));
            AddWindow<CollectionWindow>(WindowId.Collection, "Коллекция", IconId.Collection, UITheme.Purple, new Vector2(1500, 900));
            AddWindow<SettingsWindow>(WindowId.Settings, "Меню", IconId.Gear, UITheme.Grey, new Vector2(1000, 860));

            _reward = _overlayLayer.gameObject.AddComponent<RewardView>();
            _reward.Build(this, _g, _overlayLayer);
            _banner = _overlayLayer.gameObject.AddComponent<BannerView>();
            _banner.Build(_overlayLayer);
            _toasts = _overlayLayer.gameObject.AddComponent<ToastView>();
            _toasts.Build(_overlayLayer);
            _dialog = _overlayLayer.gameObject.AddComponent<DialogView>();
            _dialog.Build(this, _overlayLayer);

            GameEvents.Toast += (text, color) => _toasts.Show(text, color);
            GameEvents.InventoryChanged += () => MarkDirty(WindowId.Animals, WindowId.Collection);
            GameEvents.PenChanged += () => MarkDirty(WindowId.Animals);
            GameEvents.ShopChanged += () => MarkDirty(WindowId.Rods, WindowId.Baits, WindowId.Upgrades, WindowId.Collection);
            GameEvents.PowerChanged += () => MarkDirty(WindowId.Upgrades);
            GameEvents.PowerLevelUp += level =>
            {
                _banner.Enqueue("СИЛА ЗАБРОСА " + level + "!", "Дальность: до " + NumberFormat.Meters(_g.ThrowPerfectDistance), UITheme.Blue, 1.6f);
                MarkDirty(WindowId.Rods, WindowId.Baits, WindowId.Upgrades);
            };
            GameEvents.MoneySpent += _ => _g.Sound.Play(Audio.Sfx.Buy);
        }

        static void EnsureEventSystem()
        {
            if (EventSystem.current != null) return;
            var es = new GameObject("EventSystem");
            es.AddComponent<EventSystem>();
#if ENABLE_INPUT_SYSTEM
            es.AddComponent<UnityEngine.InputSystem.UI.InputSystemUIInputModule>();
#else
            es.AddComponent<StandaloneInputModule>();
#endif
        }

        void AddWindow<T>(WindowId id, string title, IconId icon, Color accent, Vector2 size) where T : UIWindow
        {
            var rt = UIFactory.Rect("Window_" + id, _windowLayer);
            var w = rt.gameObject.AddComponent<T>();
            w.Build(this, id, title, icon, accent, size);
            _windows[id] = w;
        }

        void MarkDirty(params WindowId[] ids)
        {
            foreach (var id in ids) if (_windows.TryGetValue(id, out var w)) w.MarkDirty();
        }

        public bool IsOpen(WindowId id) => _windows.TryGetValue(id, out var w) && w.IsOpen;

        public void Open(WindowId id)
        {
            if (_reward.ModalOpen || _dialog.IsOpen) return;
            if (_g.Mode == GameMode.Aiming) _g.Throw.CancelAim();
            foreach (var kv in _windows) if (kv.Key != id && kv.Value.IsOpen) kv.Value.Close();
            if (_windows.TryGetValue(id, out var w) && !w.IsOpen)
            {
                w.Open();
                _g.Sound.Play(Audio.Sfx.Open, 0.7f);
            }
        }

        public void Close(WindowId id)
        {
            if (_windows.TryGetValue(id, out var w) && w.IsOpen)
            {
                w.Close();
                _g.Sound.Play(Audio.Sfx.Close, 0.6f);
            }
        }

        public void Toggle(WindowId id)
        {
            if (IsOpen(id)) Close(id); else Open(id);
        }

        public bool CloseTop()
        {
            if (_dialog.IsOpen) { _dialog.Cancel(); return true; }
            foreach (var w in _windows.Values) if (w.IsOpen) { Close(w.Id); return true; }
            return false;
        }

        void Update()
        {
            if (_g == null) return;
            HandleHotkeys();
            HandleCursor();
        }

        void HandleHotkeys()
        {
            if (GameInput.Pressed(GameKey.Menu))
            {
                if (_g.Mode == GameMode.Aiming) return; // ThrowController cancels the aim
                if (_reward.ModalOpen) { _reward.DismissModal(); return; }
                if (!CloseTop())
                {
                    if (_g.Mode == GameMode.Training) _g.Training.StopTraining();
                    Open(WindowId.Settings);
                }
                return;
            }
            if (_reward.ModalOpen || _dialog.IsOpen) return;
            bool free = _g.Mode == GameMode.Playing || _g.Mode == GameMode.Training || AnyWindowOpen;
            if (!free) return;
            if (GameInput.Pressed(GameKey.Animals)) Toggle(WindowId.Animals);
            else if (GameInput.Pressed(GameKey.Rods)) Toggle(WindowId.Rods);
            else if (GameInput.Pressed(GameKey.Baits)) Toggle(WindowId.Baits);
            else if (GameInput.Pressed(GameKey.Upgrades)) Toggle(WindowId.Upgrades);
            else if (GameInput.Pressed(GameKey.Collection)) Toggle(WindowId.Collection);
            else if (!AnyWindowOpen)
            {
                if (GameInput.Pressed(GameKey.Throw)) _g.Throw.RequestThrow();
                if (GameInput.Pressed(GameKey.PrevBait)) _g.Baits.Cycle(-1);
                if (GameInput.Pressed(GameKey.NextBait)) _g.Baits.Cycle(1);
            }
        }

        /// <summary>
        /// The cursor is locked for mouse-look while playing. It is released for windows, dialogs, while Alt is held,
        /// and when the browser drops pointer lock (Esc). A click on the game world locks it again.
        /// </summary>
        void HandleCursor()
        {
            bool modal = AnyWindowOpen;
            bool wantLocked = _cursorWanted && !modal && !GameInput.Held(GameKey.FreeCursor);
            if (!wantLocked && Cursor.lockState == CursorLockMode.Locked)
            {
                Cursor.lockState = CursorLockMode.None;
                Cursor.visible = true;
            }
            else if (wantLocked && Cursor.lockState != CursorLockMode.Locked && GameInput.PrimaryPressed && !IsPointerOverUIRaw())
            {
                Cursor.lockState = CursorLockMode.Locked;
                Cursor.visible = false;
            }
            _hud.SetClickHint(!modal && Cursor.lockState != CursorLockMode.Locked && _g.Mode == GameMode.Playing);
        }

        static bool IsPointerOverUIRaw() => EventSystem.current != null && EventSystem.current.IsPointerOverGameObject();

        // ------------------------------------------------------------------ requests from gameplay

        public void ShowMeter(bool show) => _throwHud.ShowMeter(show);
        public void ShowGrade(ThrowResult r) => _throwHud.ShowGrade(r);
        public void ShowFlight(bool show) => _throwHud.ShowFlight(show);
        public void ShowHook(bool show) => _throwHud.ShowHook(show);
        public void ShowReel(bool show) => _throwHud.ShowReel(show);
        public void SetReel(float progress, float metersLeft) => _throwHud.SetReel(progress, metersLeft);

        public void ShowReward(OwnedAnimal owned, AnimalData data, bool firstTime, bool placed, double autoSold, bool big, Action onDismissed)
        {
            if (big) _reward.ShowModal(owned, data, firstTime, placed, autoSold, onDismissed);
            else _reward.ShowCard(owned, data, firstTime, placed, autoSold);
        }

        public void QueueBiomeBanner(BiomeData b)
        {
            _banner.Enqueue("НОВАЯ ЛОКАЦИЯ ОТКРЫТА!", b.displayName.ToUpperInvariant(), b.accentColor, 3f, Audio.Sfx.Unlock);
            MarkDirty(WindowId.Rods, WindowId.Baits, WindowId.Collection);
        }

        public void WorldPopup(Vector3 world, string text, Color color, float scale = 1f) => _popups.Show(world, text, color, scale);

        public void Toast(string text, Color color) => _toasts.Show(text, color);

        public void Confirm(string title, string text, string yes, Color yesColor, Action onYes) => _dialog.Confirm(title, text, yes, yesColor, onYes);

        public void Message(string title, string text, string ok, Action onOk) => _dialog.Message(title, text, ok, onOk);

        public bool BannerBusy => _banner.Busy;
        public bool RewardModalOpen => _reward.ModalOpen;
    }
}
