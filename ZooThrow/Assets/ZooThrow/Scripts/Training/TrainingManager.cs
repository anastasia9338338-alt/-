using UnityEngine;
using ZooThrow.Core;
using ZooThrow.World;

namespace ZooThrow.Training
{
    /// <summary>Pull-up training: each repetition gives xp from the best owned trainer; xp raises Throw Power.</summary>
    public class TrainingManager : MonoBehaviour
    {
        GameManager _g;
        float _repTimer;
        int _startFrame;

        public bool IsTraining { get; private set; }
        public float RepProgress01 => IsTraining ? Mathf.Clamp01(_repTimer / _g.Balance.repDuration) : 0f;
        public int SessionReps { get; private set; }
        public double XpPerRep => _g.Trainers.Best.xpPerRep * _g.Upgrades.XpMultiplier;
        public double XpToNext => Progression.XpToNext(_g.Balance, _g.State.powerLevel);
        public float Xp01 => (float)System.Math.Min(1.0, _g.State.xp / System.Math.Max(1.0, XpToNext));

        public void Init(GameManager g) => _g = g;

        public bool StartTraining()
        {
            if (IsTraining) return true;
            if (_g.Mode != GameMode.Playing) return false;
            IsTraining = true;
            _startFrame = Time.frameCount;
            _repTimer = 0f;
            SessionReps = 0;
            _g.SetMode(GameMode.Training);
            _g.Player.BeginTraining(WorldLayout.PullUpBar);
            _g.Sound.Play(Audio.Sfx.Click);
            return true;
        }

        public void StopTraining()
        {
            if (!IsTraining) return;
            IsTraining = false;
            _g.Player.EndTraining();
            if (_g.Mode == GameMode.Training) _g.SetMode(GameMode.Playing);
        }

        void Update()
        {
            if (!IsTraining) return;
            // Ignore the key press that started the session (E or the button) and the frame after it.
            if (Time.frameCount > _startFrame + 1 && (GameInput.Pressed(GameKey.Jump) || GameInput.Pressed(GameKey.Interact) ||
                GameInput.Pressed(GameKey.Forward) || GameInput.Pressed(GameKey.Back) || GameInput.Pressed(GameKey.Left) || GameInput.Pressed(GameKey.Right)))
            {
                StopTraining();
                return;
            }
            _repTimer += Time.deltaTime;
            float dur = Mathf.Max(0.1f, _g.Balance.repDuration);
            while (_repTimer >= dur)
            {
                _repTimer -= dur;
                DoRep();
            }
        }

        void DoRep()
        {
            SessionReps++;
            double gained = XpPerRep;
            int level = _g.State.powerLevel;
            double xp = _g.State.xp;
            int levels = Progression.ApplyXp(_g.Balance, ref level, ref xp, gained);
            _g.State.powerLevel = level;
            _g.State.xp = xp;
            _g.SaveMgr.MarkDirty();
            Vector3 head = _g.Player.transform.position + Vector3.up * 3.2f;
            _g.UI.WorldPopup(head, "+" + NumberFormat.Short(gained) + " опыта", new Color(0.55f, 0.85f, 1f));
            _g.Sound.Play(Audio.Sfx.Rep, 0.35f, 1f + Random.Range(-0.05f, 0.05f));
            GameEvents.RaisePowerChanged();
            if (levels > 0)
            {
                _g.Sound.Play(Audio.Sfx.LevelUp);
                _g.Vfx.LevelUp(_g.Player.transform.position);
                GameEvents.RaisePowerLevelUp(level);
            }
        }
    }
}
