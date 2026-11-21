using System.Collections.Generic;
using UnityEngine;
using ZooThrow.Data;

namespace ZooThrow.Audio
{
    public enum Sfx
    {
        Click, Open, Close, Coin, Buy, Error, Whoosh, Land, Perfect, Great, Good, Weak,
        RewardCommon, RewardRare, RewardEpic, RewardLegendary, LevelUp, Unlock, Rep, Jump, Teleport
    }

    public class SoundManager : MonoBehaviour
    {
        readonly Dictionary<Sfx, AudioClip> _clips = new Dictionary<Sfx, AudioClip>();
        readonly List<AudioSource> _pool = new List<AudioSource>();
        AudioSource _music;
        float _sfxVolume = 0.8f;
        int _next;

        public void Init()
        {
            foreach (Sfx s in System.Enum.GetValues(typeof(Sfx))) _clips[s] = SoundSynth.Make(s);
            for (int i = 0; i < 10; i++)
            {
                var src = gameObject.AddComponent<AudioSource>();
                src.playOnAwake = false;
                src.spatialBlend = 0f;
                _pool.Add(src);
            }
            _music = gameObject.AddComponent<AudioSource>();
            _music.clip = SoundSynth.MakeMusic();
            _music.loop = true;
            _music.playOnAwake = false;
            _music.spatialBlend = 0f;
            _music.Play();
        }

        public void SetVolumes(float sfx, float music)
        {
            _sfxVolume = Mathf.Clamp01(sfx);
            if (_music != null) _music.volume = Mathf.Clamp01(music) * 0.5f;
        }

        public void Play(Sfx s, float volume = 1f, float pitch = 1f)
        {
            if (_sfxVolume <= 0f || !_clips.TryGetValue(s, out var clip)) return;
            var src = _pool[_next];
            _next = (_next + 1) % _pool.Count;
            src.pitch = pitch;
            src.PlayOneShot(clip, volume * _sfxVolume);
        }

        public void PlayReward(Rarity r)
        {
            switch (r)
            {
                case Rarity.Common:
                case Rarity.Uncommon: Play(Sfx.RewardCommon); break;
                case Rarity.Rare: Play(Sfx.RewardRare); break;
                case Rarity.Epic: Play(Sfx.RewardEpic); break;
                default: Play(Sfx.RewardLegendary); break;
            }
        }
    }
}
