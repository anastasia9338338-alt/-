using System;
using UnityEngine;

namespace ZooThrow.Audio
{
    /// <summary>Generates all game sounds and the music loop at startup, so the project ships no audio files.</summary>
    public static class SoundSynth
    {
        public const int Rate = 22050;

        static float Midi(float note) => 440f * Mathf.Pow(2f, (note - 69f) / 12f);

        static AudioClip Clip(string name, float[] data)
        {
            var clip = AudioClip.Create(name, data.Length, 1, Rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        static float[] Buffer(float seconds) => new float[Mathf.Max(1, Mathf.CeilToInt(seconds * Rate))];

        // Soft square-ish tone: sine with a little third harmonic.
        static float Tone(float phase, float bright) => Mathf.Sin(phase) + bright * Mathf.Sin(phase * 3f) / 3f;

        static void AddNote(float[] buf, float start, float dur, float freq, float vol, float bright = 0.3f, float attack = 0.005f, float slideTo = 0f)
        {
            int s0 = Mathf.Max(0, (int)(start * Rate));
            int n = (int)(dur * Rate);
            double phase = 0;
            for (int i = 0; i < n && s0 + i < buf.Length; i++)
            {
                float t = i / (float)Rate;
                float f = slideTo > 0 ? Mathf.Lerp(freq, slideTo, t / dur) : freq;
                phase += 2.0 * Math.PI * f / Rate;
                float env = Mathf.Min(1f, t / attack) * Mathf.Exp(-4.5f * t / dur);
                buf[s0 + i] += Tone((float)phase, bright) * vol * env;
            }
        }

        static void AddNoise(float[] buf, float start, float dur, float vol, float lowpass, System.Random rng, bool swell)
        {
            int s0 = (int)(start * Rate);
            int n = (int)(dur * Rate);
            float y = 0f;
            for (int i = 0; i < n && s0 + i < buf.Length; i++)
            {
                float t = i / (float)n;
                float x = (float)(rng.NextDouble() * 2 - 1);
                y += (x - y) * lowpass;
                float env = swell ? Mathf.Sin(t * Mathf.PI) : Mathf.Exp(-6f * t);
                buf[s0 + i] += y * vol * env;
            }
        }

        static float[] Normalize(float[] b, float peak = 0.85f)
        {
            float m = 0.0001f;
            foreach (var v in b) m = Mathf.Max(m, Mathf.Abs(v));
            float k = peak / m;
            for (int i = 0; i < b.Length; i++) b[i] *= k;
            return b;
        }

        public static AudioClip Make(Sfx s)
        {
            var rng = new System.Random((int)s * 7919 + 13);
            float[] b;
            switch (s)
            {
                case Sfx.Click:
                    b = Buffer(0.06f); AddNote(b, 0, 0.06f, 1600, 0.6f, 0.2f); break;
                case Sfx.Open:
                    b = Buffer(0.14f); AddNote(b, 0, 0.14f, 600, 0.5f, 0.2f, 0.005f, 900); break;
                case Sfx.Close:
                    b = Buffer(0.12f); AddNote(b, 0, 0.12f, 800, 0.5f, 0.2f, 0.005f, 500); break;
                case Sfx.Coin:
                    b = Buffer(0.25f); AddNote(b, 0, 0.08f, Midi(83), 0.5f, 0.6f); AddNote(b, 0.06f, 0.2f, Midi(88), 0.5f, 0.6f); break;
                case Sfx.Buy:
                    b = Buffer(0.45f);
                    AddNote(b, 0, 0.15f, Midi(72), 0.5f, 0.5f); AddNote(b, 0.08f, 0.15f, Midi(76), 0.5f, 0.5f);
                    AddNote(b, 0.16f, 0.3f, Midi(79), 0.5f, 0.5f); AddNote(b, 0.16f, 0.3f, Midi(84), 0.3f, 0.5f);
                    break;
                case Sfx.Error:
                    b = Buffer(0.3f); AddNote(b, 0, 0.12f, 180, 0.6f, 1f); AddNote(b, 0.14f, 0.14f, 150, 0.6f, 1f); break;
                case Sfx.Whoosh:
                    b = Buffer(0.6f); AddNoise(b, 0, 0.6f, 0.9f, 0.15f, rng, true); AddNote(b, 0, 0.5f, 300, 0.15f, 0f, 0.05f, 900); break;
                case Sfx.Land:
                    b = Buffer(0.4f); AddNote(b, 0, 0.35f, 110, 0.9f, 0.1f, 0.002f, 50); AddNoise(b, 0, 0.25f, 0.6f, 0.08f, rng, false); break;
                case Sfx.Perfect:
                    b = Buffer(0.9f);
                    for (int i = 0; i < 6; i++) AddNote(b, i * 0.06f, 0.5f, Midi(79 + new[] { 0, 4, 7, 12, 16, 19 }[i]), 0.35f, 0.6f);
                    AddNoise(b, 0, 0.6f, 0.15f, 0.6f, rng, true);
                    break;
                case Sfx.Great:
                    b = Buffer(0.5f); AddNote(b, 0, 0.2f, Midi(76), 0.5f, 0.4f); AddNote(b, 0.1f, 0.35f, Midi(83), 0.5f, 0.4f); break;
                case Sfx.Good:
                    b = Buffer(0.35f); AddNote(b, 0, 0.3f, Midi(74), 0.5f, 0.3f); break;
                case Sfx.Weak:
                    b = Buffer(0.4f); AddNote(b, 0, 0.35f, Midi(62), 0.5f, 0.3f, 0.005f, Midi(57)); break;
                case Sfx.RewardCommon:
                    b = Buffer(0.6f); AddNote(b, 0, 0.2f, Midi(72), 0.5f); AddNote(b, 0.1f, 0.2f, Midi(76), 0.5f); AddNote(b, 0.2f, 0.4f, Midi(79), 0.5f); break;
                case Sfx.RewardRare:
                    b = Buffer(1.0f);
                    foreach (var (t, n) in new[] { (0f, 72f), (0.1f, 76f), (0.2f, 79f), (0.3f, 84f) }) AddNote(b, t, 0.5f, Midi(n), 0.45f, 0.5f);
                    AddNote(b, 0.4f, 0.6f, Midi(88), 0.35f, 0.5f);
                    break;
                case Sfx.RewardEpic:
                    b = Buffer(1.6f);
                    foreach (var (t, n) in new[] { (0f, 67f), (0.12f, 72f), (0.24f, 76f), (0.36f, 79f), (0.48f, 84f) }) AddNote(b, t, 0.6f, Midi(n), 0.4f, 0.6f);
                    foreach (var n in new[] { 72f, 76f, 79f, 84f }) AddNote(b, 0.62f, 1.0f, Midi(n), 0.25f, 0.4f, 0.02f);
                    AddNoise(b, 0.6f, 0.9f, 0.1f, 0.7f, rng, true);
                    break;
                case Sfx.RewardLegendary:
                    b = Buffer(2.4f);
                    foreach (var (t, n) in new[] { (0f, 60f), (0.15f, 64f), (0.3f, 67f), (0.45f, 72f), (0.6f, 76f), (0.75f, 79f) }) AddNote(b, t, 0.6f, Midi(n), 0.4f, 0.7f);
                    foreach (var n in new[] { 72f, 76f, 79f, 84f, 88f }) AddNote(b, 0.9f, 1.5f, Midi(n), 0.22f, 0.5f, 0.03f);
                    AddNoise(b, 0.8f, 1.4f, 0.12f, 0.8f, rng, true);
                    break;
                case Sfx.LevelUp:
                    b = Buffer(0.9f);
                    AddNote(b, 0, 0.7f, 400, 0.4f, 0.3f, 0.01f, 1200);
                    AddNote(b, 0.3f, 0.5f, Midi(84), 0.35f, 0.5f); AddNote(b, 0.38f, 0.5f, Midi(88), 0.35f, 0.5f);
                    break;
                case Sfx.Unlock:
                    b = Buffer(1.8f);
                    foreach (var (t, n) in new[] { (0f, 60f), (0.2f, 67f), (0.4f, 72f) }) AddNote(b, t, 0.5f, Midi(n), 0.45f, 0.6f);
                    foreach (var n in new[] { 72f, 76f, 79f }) AddNote(b, 0.6f, 1.2f, Midi(n), 0.3f, 0.5f, 0.02f);
                    break;
                case Sfx.Rep:
                    b = Buffer(0.12f); AddNote(b, 0, 0.12f, 300, 0.5f, 0.2f, 0.005f, 420); break;
                case Sfx.Jump:
                    b = Buffer(0.18f); AddNote(b, 0, 0.18f, 300, 0.5f, 0.2f, 0.005f, 600); break;
                case Sfx.Teleport:
                    b = Buffer(0.4f); AddNote(b, 0, 0.4f, 1200, 0.4f, 0.2f, 0.01f, 300); AddNoise(b, 0, 0.3f, 0.3f, 0.5f, rng, true); break;
                default:
                    b = Buffer(0.05f); break;
            }
            return Clip(s.ToString(), Normalize(b, 0.8f));
        }

        /// <summary>A gentle 4-bar loop (C–Am–F–G) with bass, plucks and soft hats. 120 BPM, 16 beats.</summary>
        public static AudioClip MakeMusic()
        {
            const float bpm = 112f;
            float beat = 60f / bpm;
            int bars = 8;
            var b = Buffer(bars * 4 * beat);
            var rng = new System.Random(42);
            int[][] chords = { new[] { 60, 64, 67 }, new[] { 57, 60, 64 }, new[] { 53, 57, 60 }, new[] { 55, 59, 62 } };
            int[] melody = { 76, 74, 72, 74, 76, 76, 79, 76, 72, 72, 74, 72, 71, 72, 74, 74 };
            for (int bar = 0; bar < bars; bar++)
            {
                var ch = chords[bar % 4];
                float t0 = bar * 4 * beat;
                AddNote(b, t0, beat * 1.8f, Midi(ch[0] - 24), 0.35f, 0.15f, 0.01f);
                AddNote(b, t0 + beat * 2, beat * 1.8f, Midi(ch[0] - 24), 0.3f, 0.15f, 0.01f);
                for (int i = 0; i < 8; i++)
                {
                    int note = ch[(i + (i / 2)) % 3] + (i % 4 == 3 ? 12 : 0);
                    AddNote(b, t0 + i * beat * 0.5f, beat * 0.6f, Midi(note), 0.12f, 0.5f);
                }
                if (bar >= 4)
                    for (int i = 0; i < 4; i++)
                        AddNote(b, t0 + i * beat, beat * 0.9f, Midi(melody[((bar - 4) * 4 + i) % melody.Length]), 0.14f, 0.35f, 0.01f);
                for (int i = 0; i < 8; i++) AddNoise(b, t0 + i * beat * 0.5f, 0.05f, i % 2 == 0 ? 0.05f : 0.03f, 0.9f, rng, false);
                for (int i = 0; i < 4; i += 2) AddNote(b, t0 + i * beat, 0.15f, 70, 0.3f, 0f, 0.002f, 40);
            }
            return Clip("Music", Normalize(b, 0.6f));
        }
    }
}
