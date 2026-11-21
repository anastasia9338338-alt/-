using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ZooThrow.Core
{
    /// <summary>Applies saved settings: volumes, graphics quality (shadows, render scale, fog distance, particles).</summary>
    public static class SettingsApplier
    {
        public static void Apply(GameManager g)
        {
            var s = g.State.settings;
            g.Sound.SetVolumes(s.masterVolume, s.musicVolume);
            g.Vfx.SetQuality(s.quality);
            var sun = g.World.Sun;
            float shadowDistance, renderScale, fogEnd;
            switch (s.quality)
            {
                case 0:
                    sun.shadows = LightShadows.None; shadowDistance = 0f; renderScale = 0.75f; fogEnd = 220f;
                    break;
                case 1:
                    sun.shadows = LightShadows.Hard; shadowDistance = 60f; renderScale = 0.9f; fogEnd = 280f;
                    break;
                default:
                    sun.shadows = LightShadows.Soft; shadowDistance = 110f; renderScale = 1f; fogEnd = 320f;
                    break;
            }
            g.World.SetFogDistances(fogEnd * 0.3f, fogEnd);
            if (g.Cam != null && g.Cam.Cam != null) g.Cam.Cam.farClipPlane = fogEnd + 40f;
#if !UNITY_EDITOR
            // Not in the Editor: changing the pipeline asset there would modify the asset file on disk.
            if (GraphicsSettings.currentRenderPipeline is UniversalRenderPipelineAsset urp)
            {
                urp.renderScale = renderScale;
                urp.shadowDistance = Mathf.Max(1f, shadowDistance);
            }
#endif
            QualitySettings.vSyncCount = 1;
            Application.targetFrameRate = -1;
        }
    }
}
