using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using ZooThrow.Animals;
using ZooThrow.Core;
using ZooThrow.Data;
using ZooThrow.SaveSystem;

namespace ZooThrow.UI
{
    /// <summary>Reward card for common catches and a full-screen reveal for rare and better.</summary>
    public class RewardView : MonoBehaviour
    {
        GameManager _g;
        // Card
        RectTransform _card;
        Image _cardStripe;
        RawImage _cardPortrait;
        TextMeshProUGUI _cardName, _cardRarity, _cardIncome, _cardStatus, _cardNew;
        float _cardTime = -1f;
        // Modal
        RectTransform _modal, _modalContent, _rays;
        Image _raysImg, _modalGlow;
        RawImage _modalPortrait;
        TextMeshProUGUI _modalRarity, _modalName, _modalIncome, _modalStatus, _modalNew;
        UIButton _takeButton, _penButton;
        float _modalTime;
        Action _onDismissed;
        OwnedAnimal _modalAnimal;
        public bool ModalOpen { get; private set; }

        public void Build(UIManager ui, GameManager g, RectTransform layer)
        {
            _g = g;
            BuildCard(layer);
            BuildModal(layer);
        }

        void BuildCard(RectTransform layer)
        {
            var card = UIFactory.Panel(layer, "RewardCard", UITheme.WindowBg, 26);
            _card = card.rectTransform;
            UIFactory.Place(_card, new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-24, 190), new Vector2(520, 200));
            UIFactory.Shadow(_card, 26, 0.45f, 16f);
            _cardStripe = UIFactory.Panel(_card, "Stripe", Color.white, 26);
            UIFactory.Place(_cardStripe.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), Vector2.zero, new Vector2(190, 200));
            _cardStripe.gameObject.AddComponent<VerticalGradient>().bottom = new Color(0.55f, 0.55f, 0.6f);
            _cardPortrait = UIFactory.Raw(_card, null, 180);
            UIFactory.Place(_cardPortrait.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(6, 0), new Vector2(180, 180));
            _cardRarity = UIFactory.Text(_card, "", 22, Color.white, TextAlignmentOptions.TopLeft, true, true);
            UIFactory.Place(_cardRarity.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(208, -16), new Vector2(300, 30));
            _cardName = UIFactory.Text(_card, "", 38, Color.white, TextAlignmentOptions.TopLeft, true, true);
            _cardName.enableWordWrapping = false;
            UIFactory.Place(_cardName.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(208, -46), new Vector2(300, 50));
            _cardIncome = UIFactory.Text(_card, "", 28, UITheme.Money, TextAlignmentOptions.TopLeft, true, true);
            UIFactory.Place(_cardIncome.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(208, -98), new Vector2(300, 36));
            _cardStatus = UIFactory.Text(_card, "", 20, UITheme.TextDim, TextAlignmentOptions.TopLeft, false, true);
            UIFactory.Place(_cardStatus.rectTransform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(208, -138), new Vector2(300, 52));
            _cardNew = Badge(_card, "НОВОЕ!", UITheme.Yellow, new Vector2(-14, -14));
            _card.gameObject.SetActive(false);
        }

        static TextMeshProUGUI Badge(RectTransform parent, string text, Color color, Vector2 pos)
        {
            var b = UIFactory.Panel(parent, "Badge", color, 14);
            UIFactory.Place(b.rectTransform, new Vector2(1, 1), new Vector2(1, 1), pos, new Vector2(130, 40));
            b.rectTransform.localRotation = Quaternion.Euler(0, 0, -8f);
            var t = UIFactory.Text(b.transform, text, 24, new Color(0.25f, 0.15f, 0.05f), TextAlignmentOptions.Center, true);
            UIFactory.Stretch(t.rectTransform);
            return t;
        }

        void BuildModal(RectTransform layer)
        {
            var dim = UIFactory.Panel(layer, "RewardModal", new Color(0.02f, 0.02f, 0.06f, 0.78f), 0);
            _modal = dim.rectTransform;
            UIFactory.Stretch(_modal);
            _raysImg = UIFactory.Panel(_modal, "Rays", Color.white, 0);
            _raysImg.sprite = SpriteFactory.Rays();
            _raysImg.type = Image.Type.Simple;
            _raysImg.raycastTarget = false;
            _rays = _raysImg.rectTransform;
            UIFactory.Place(_rays, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, 90), new Vector2(1100, 1100));

            _modalContent = UIFactory.Rect("Content", _modal);
            UIFactory.Stretch(_modalContent);
            _modalRarity = UIFactory.Text(_modalContent, "", 64, Color.white, TextAlignmentOptions.Center, true, true);
            _modalRarity.enableWordWrapping = false;
            UIFactory.Place(_modalRarity.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0, -60), new Vector2(1400, 90));
            _modalGlow = UIFactory.Panel(_modalContent, "Glow", Color.white, 0);
            _modalGlow.sprite = SpriteFactory.Soft(60, 60);
            _modalGlow.raycastTarget = false;
            UIFactory.Place(_modalGlow.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, 90), new Vector2(520, 520));
            _modalPortrait = UIFactory.Raw(_modalContent, null, 440);
            UIFactory.Place(_modalPortrait.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, 90), new Vector2(440, 440));
            _modalNew = Badge(_modalPortrait.rectTransform, "НОВОЕ!", UITheme.Yellow, new Vector2(30, 0));
            _modalName = UIFactory.Text(_modalContent, "", 72, Color.white, TextAlignmentOptions.Center, true, true);
            _modalName.enableWordWrapping = false;
            UIFactory.Place(_modalName.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, -190), new Vector2(1400, 90));
            _modalIncome = UIFactory.Text(_modalContent, "", 40, UITheme.Money, TextAlignmentOptions.Center, true, true);
            UIFactory.Place(_modalIncome.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, -258), new Vector2(1200, 56));
            _modalStatus = UIFactory.Text(_modalContent, "", 26, UITheme.TextDim, TextAlignmentOptions.Center, false, true);
            UIFactory.Place(_modalStatus.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, -306), new Vector2(1200, 40));

            var buttons = UIFactory.Rect("Buttons", _modalContent);
            UIFactory.Place(buttons, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 50), new Vector2(900, 110));
            UIFactory.HLayout(buttons, 24, null, TextAnchor.MiddleCenter, false, false);
            _penButton = UIFactory.Button(buttons, "В ЗАГОН", UITheme.Blue, PlaceInPen, 34, IconId.Paw, 26);
            UIFactory.Layout(_penButton.button, 360, 104);
            _takeButton = UIFactory.Button(buttons, "ЗАБРАТЬ", UITheme.Green, DismissModal, 38, IconId.Check, 26);
            UIFactory.Layout(_takeButton.button, 360, 104);
            _modal.gameObject.SetActive(false);
        }

        string StatusText(bool placed, double autoSold, bool owned)
        {
            if (!owned) return "Инвентарь полон — продано за " + NumberFormat.Money(autoSold);
            return placed ? "Уже в загоне и приносит деньги!" : "Добавлено в инвентарь (Tab)";
        }

        string IncomeText(AnimalData data, Mutation m) => "+" + NumberFormat.PerSecond(AnimalRoller.Income(_g.Db, data, m));

        string NameText(AnimalData data, Mutation m)
        {
            string mut = AnimalRoller.MutationName(m);
            return string.IsNullOrEmpty(mut) ? data.displayName : mut + " " + data.displayName.ToLowerInvariant();
        }

        public void ShowCard(OwnedAnimal owned, AnimalData data, bool firstTime, bool placed, double autoSold)
        {
            var rarity = _g.Db.GetRarity(data.rarity);
            _cardStripe.color = rarity.color;
            _cardPortrait.texture = Portraits.Animal(data);
            _cardRarity.text = rarity.displayName.ToUpperInvariant();
            _cardRarity.color = Color.Lerp(rarity.color, Color.white, 0.25f);
            _cardName.text = NameText(data, owned.mutation);
            _cardIncome.text = IncomeText(data, owned.mutation);
            _cardStatus.text = StatusText(placed, autoSold, owned.uid != 0);
            _cardNew.transform.parent.gameObject.SetActive(firstTime);
            _card.gameObject.SetActive(true);
            _cardTime = 0f;
        }

        public void ShowModal(OwnedAnimal owned, AnimalData data, bool firstTime, bool placed, double autoSold, Action onDismissed)
        {
            var rarity = _g.Db.GetRarity(data.rarity);
            _modalAnimal = owned.uid != 0 ? owned : null;
            _onDismissed = onDismissed;
            _raysImg.color = new Color(rarity.color.r, rarity.color.g, rarity.color.b, 0.55f);
            _modalGlow.color = new Color(rarity.color.r, rarity.color.g, rarity.color.b, 0.7f);
            _modalPortrait.texture = Portraits.Animal(data);
            _modalPortrait.color = owned.mutation == Mutation.Golden ? new Color(1f, 0.85f, 0.4f) : Color.white;
            _modalRarity.text = rarity.displayName.ToUpperInvariant() + "!";
            _modalRarity.color = rarity.color;
            _modalName.text = NameText(data, owned.mutation);
            _modalIncome.text = IncomeText(data, owned.mutation);
            _modalStatus.text = StatusText(placed, autoSold, owned.uid != 0);
            _modalNew.transform.parent.gameObject.SetActive(firstTime);
            bool canPen = _modalAnimal != null && !placed;
            _penButton.SetActive(canPen);
            if (canPen) _penButton.label.text = _g.Pen.HasFreeSlot ? "В ЗАГОН" : "ЗАМЕНИТЬ СЛАБОГО";
            _modal.gameObject.SetActive(true);
            _modal.SetAsLastSibling();
            ModalOpen = true;
            _modalTime = 0f;
        }

        void PlaceInPen()
        {
            if (_modalAnimal != null)
            {
                bool ok = _g.Pen.PlaceOrReplaceWeakest(_modalAnimal);
                GameEvents.RaiseToast(ok ? "Животное в загоне!" : "В загоне все сильнее — оставили в инвентаре", ok ? UITheme.Money : UITheme.Yellow);
            }
            DismissModal();
        }

        public void DismissModal()
        {
            if (!ModalOpen) return;
            ModalOpen = false;
            _modal.gameObject.SetActive(false);
            var cb = _onDismissed;
            _onDismissed = null;
            cb?.Invoke();
        }

        void Update()
        {
            float dt = Time.unscaledDeltaTime;
            if (_cardTime >= 0f)
            {
                _cardTime += dt;
                float inT = Mathf.Clamp01(_cardTime / 0.35f);
                float outT = Mathf.Clamp01((_cardTime - 3.6f) / 0.3f);
                _card.anchoredPosition = new Vector2(Mathf.Lerp(600f, -24f, Ease.OutBack(inT)) + outT * 600f, 190);
                if (_cardTime > 4f) { _card.gameObject.SetActive(false); _cardTime = -1f; }
            }
            if (ModalOpen)
            {
                _modalTime += dt;
                _rays.localRotation = Quaternion.Euler(0, 0, -_modalTime * 20f);
                float s = Mathf.LerpUnclamped(0.2f, 1f, Ease.OutBack(Mathf.Clamp01(_modalTime / 0.5f)));
                _modalPortrait.rectTransform.localScale = new Vector3(s, s, 1f);
                float pulse = 1f + Mathf.Sin(_modalTime * 3f) * 0.05f;
                _modalGlow.rectTransform.localScale = new Vector3(pulse, pulse, 1f);
                _modalRarity.rectTransform.localScale = Vector3.one * Mathf.LerpUnclamped(0.5f, 1f, Ease.OutBack(Mathf.Clamp01((_modalTime - 0.1f) / 0.4f)));
            }
        }
    }
}
