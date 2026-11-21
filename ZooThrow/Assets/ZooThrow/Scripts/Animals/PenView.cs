using System.Collections.Generic;
using UnityEngine;
using ZooThrow.Core;
using ZooThrow.Visuals;
using ZooThrow.World;

namespace ZooThrow.Animals
{
    /// <summary>Shows placed animals on their pedestals, rarity rings, locked slots, and income popups.</summary>
    public class PenView : MonoBehaviour
    {
        GameManager _g;
        readonly AnimalActor[] _actors = new AnimalActor[16];
        readonly int[] _shownUid = new int[16];
        readonly List<MeshRenderer> _rings = new List<MeshRenderer>();
        readonly List<GameObject> _locks = new List<GameObject>();
        MaterialPropertyBlock _mpb;
        int _popupSlot;

        public AnimalActor ActorInSlot(int slot) => slot >= 0 && slot < _actors.Length ? _actors[slot] : null;

        public void Init(GameManager g)
        {
            _g = g;
            _mpb = new MaterialPropertyBlock();
            var pedestal = new MeshBuilder();
            pedestal.Cylinder(Vector3.zero, 1.9f, 1.7f, 0.25f, 12, new Color(0.85f, 0.85f, 0.88f));
            var pedestalMesh = pedestal.ToMesh("Pedestal");
            var ring = new MeshBuilder();
            ring.Cylinder(new Vector3(0, 0.25f, 0), 1.72f, 1.72f, 0.05f, 12, Color.white);
            var ringMesh = ring.ToMesh("PedestalRing");
            var lockMb = new MeshBuilder();
            lockMb.Box(new Vector3(0, 1.0f, 0), new Vector3(0.9f, 0.75f, 0.35f), new Color(0.95f, 0.75f, 0.2f));
            lockMb.Box(new Vector3(-0.3f, 1.55f, 0), new Vector3(0.14f, 0.5f, 0.14f), new Color(0.6f, 0.62f, 0.68f));
            lockMb.Box(new Vector3(0.3f, 1.55f, 0), new Vector3(0.14f, 0.5f, 0.14f), new Color(0.6f, 0.62f, 0.68f));
            lockMb.Box(new Vector3(0, 1.8f, 0), new Vector3(0.74f, 0.14f, 0.14f), new Color(0.6f, 0.62f, 0.68f));
            lockMb.Box(new Vector3(0, 1.0f, 0.18f), new Vector3(0.12f, 0.25f, 0.02f), new Color(0.3f, 0.2f, 0.1f));
            var lockMesh = lockMb.ToMesh("Lock");

            int slots = g.Pen.MaxSlots;
            for (int i = 0; i < slots; i++)
            {
                var basePos = WorldLayout.PenSlot(i);
                MaterialLibrary.MeshObject("Pedestal_" + i, transform, pedestalMesh, basePos, false);
                var r = MaterialLibrary.MeshObject("Ring_" + i, transform, ringMesh, basePos, false).GetComponent<MeshRenderer>();
                _rings.Add(r);
                var l = MaterialLibrary.MeshObject("Lock_" + i, transform, lockMesh, basePos, true);
                l.AddComponent<Spin>();
                _locks.Add(l);
            }
            GameEvents.PenChanged += Refresh;
            GameEvents.InventoryChanged += Refresh;
            _g.Income.IncomeTick += OnIncomeTick;
            Refresh();
        }

        void OnDestroy()
        {
            GameEvents.PenChanged -= Refresh;
            GameEvents.InventoryChanged -= Refresh;
        }

        public void Refresh()
        {
            var pen = _g.Pen;
            for (int i = 0; i < pen.MaxSlots && i < _actors.Length; i++)
            {
                bool unlocked = pen.IsSlotUnlocked(i);
                _locks[i].SetActive(!unlocked);
                int uid = unlocked ? pen.SlotUid(i) : 0;
                var owned = _g.Inventory.Get(uid);
                if (owned == null) uid = 0;

                Color ringColor = unlocked ? new Color(0.75f, 0.78f, 0.82f) : new Color(0.35f, 0.35f, 0.4f);
                if (owned != null)
                {
                    var data = _g.Inventory.DataOf(owned);
                    ringColor = _g.Db.GetRarity(data.rarity).color;
                }
                _mpb.SetColor(MaterialLibrary.OverlayColorId, new Color(ringColor.r, ringColor.g, ringColor.b, 1f));
                _mpb.SetColor(MaterialLibrary.EmissionColorId, owned != null ? ringColor * 0.35f : Color.black);
                _rings[i].SetPropertyBlock(_mpb);

                if (_shownUid[i] == uid) continue;
                if (_actors[i] != null) { Destroy(_actors[i].gameObject); _actors[i] = null; }
                _shownUid[i] = uid;
                if (owned == null) continue;
                var pos = WorldLayout.PenSlot(i) + Vector3.up * 0.27f;
                var actor = AnimalActor.Create(_g.Inventory.DataOf(owned), owned.mutation, _g.Balance, transform, pos, uid);
                actor.transform.rotation = Quaternion.Euler(0, Random.Range(0f, 360f), 0);
                actor.SetWander(pos, 1.1f);
                _actors[i] = actor;
                _g.Vfx.Poof(pos + Vector3.up);
            }
        }

        void OnIncomeTick(double amount)
        {
            // Show one "+$" popup per second over a placed animal, cycling through the slots.
            var pen = _g.Pen;
            for (int k = 0; k < pen.MaxSlots; k++)
            {
                _popupSlot = (_popupSlot + 1) % pen.MaxSlots;
                var actor = _actors[_popupSlot];
                if (actor == null) continue;
                var owned = _g.Inventory.Get(_shownUid[_popupSlot]);
                double income = _g.Inventory.IncomeOf(owned);
                Vector3 p = actor.transform.position + Vector3.up * (actor.Height + 0.6f);
                _g.UI.WorldPopup(p, "+" + NumberFormat.Money(income), new Color(0.45f, 1f, 0.45f), 0.8f);
                return;
            }
        }
    }

    public class Spin : MonoBehaviour
    {
        void Update() => transform.Rotate(0, 60f * Time.deltaTime, 0, Space.World);
    }
}
