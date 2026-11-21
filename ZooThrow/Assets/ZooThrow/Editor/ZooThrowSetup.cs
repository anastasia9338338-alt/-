using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using TMPro;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;
using UnityEngine.TextCore.LowLevel;
using ZooThrow.Core;
using ZooThrow.Data;

namespace ZooThrow.EditorTools
{
    /// <summary>
    /// One-click project setup: TMP Essentials, URP pipeline asset, Cyrillic TMP fonts, ScriptableObject content,
    /// the game scene, build settings and WebGL player settings. Runs automatically once after the scripts first
    /// compile (marker file in ProjectSettings) and is available from the "ZooThrow" menu.
    /// </summary>
    [InitializeOnLoad]
    public static class ZooThrowSetup
    {
        const string Root = "Assets/ZooThrow";
        const string MarkerPath = "ProjectSettings/ZooThrowSetup.txt";
        const string ScenePath = Root + "/Scenes/ZooThrow.unity";
        const string SettingsFolder = Root + "/Settings";
        const string DataFolder = Root + "/ScriptableObjects";
        const string ResourcesFolder = Root + "/Resources";
        const string FontsFolder = Root + "/Fonts";
        const string BuildFolder = "Builds/WebGL";

        static bool s_WaitingForTmpImport;

        static ZooThrowSetup()
        {
            if (Application.isBatchMode) return;
            if (File.Exists(MarkerPath)) return;
            EditorApplication.delayCall += () =>
            {
                if (EditorApplication.isPlayingOrWillChangePlaymode || File.Exists(MarkerPath)) return;
                Debug.Log("[ZooThrow] Первая настройка проекта...");
                RunSetup(false);
            };
        }

        [MenuItem("ZooThrow/1. Настроить проект", priority = 1)]
        public static void SetupMenu() => RunSetup(true);

        [MenuItem("ZooThrow/2. Открыть игровую сцену", priority = 2)]
        public static void OpenScene()
        {
            if (!File.Exists(ScenePath)) CreateScene();
            if (EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) EditorSceneManager.OpenScene(ScenePath);
        }

        [MenuItem("ZooThrow/3. Собрать WebGL", priority = 3)]
        public static void BuildMenu()
        {
            RunSetupSynchronousParts();
            var report = BuildWebGL();
            if (report.summary.result == BuildResult.Succeeded)
            {
                EditorUtility.DisplayDialog("ZooThrow", "WebGL-сборка готова:\n" + Path.GetFullPath(BuildFolder) + "\n\nЗапусти её через локальный HTTP-сервер (см. README).", "OK");
                EditorUtility.RevealInFinder(BuildFolder);
            }
            else EditorUtility.DisplayDialog("ZooThrow", "Сборка не удалась: " + report.summary.result + ". Подробности — в Console.", "OK");
        }

        [MenuItem("ZooThrow/Пересоздать данные (сбросит правки баланса)", priority = 20)]
        public static void RecreateDataMenu()
        {
            if (!EditorUtility.DisplayDialog("ZooThrow", "Удалить и заново создать все ScriptableObject-данные из DefaultContent? Ручные правки баланса будут потеряны.", "Пересоздать", "Отмена")) return;
            AssetDatabase.DeleteAsset(DataFolder);
            AssetDatabase.DeleteAsset(ResourcesFolder + "/" + GameDatabase.ResourcePath + ".asset");
            CreateData();
        }

        [MenuItem("ZooThrow/Удалить сохранение игрока", priority = 21)]
        public static void DeleteSaveMenu()
        {
            if (!EditorUtility.DisplayDialog("ZooThrow", "Удалить сохранение игры в редакторе (PlayerPrefs)?", "Удалить", "Отмена")) return;
            PlayerPrefs.DeleteAll();
            PlayerPrefs.Save();
        }

        /// <summary>Command line: Unity -batchmode -quit -projectPath . -executeMethod ZooThrow.EditorTools.ZooThrowSetup.BuildWebGLBatch</summary>
        public static void BuildWebGLBatch()
        {
            try
            {
                if (!TmpEssentialsPresent()) ImportTmpEssentials();
                RunSetupSynchronousParts();
                var report = BuildWebGL();
                EditorApplication.Exit(report.summary.result == BuildResult.Succeeded ? 0 : 1);
            }
            catch (Exception e)
            {
                Debug.LogException(e);
                EditorApplication.Exit(2);
            }
        }

        // ------------------------------------------------------------------ setup pipeline

        static void RunSetup(bool interactive)
        {
            if (!TmpEssentialsPresent())
            {
                if (s_WaitingForTmpImport) return;
                s_WaitingForTmpImport = true;
                AssetDatabase.importPackageCompleted += OnTmpImported;
                AssetDatabase.importPackageFailed += OnTmpImportFailed;
                if (!ImportTmpEssentials())
                {
                    s_WaitingForTmpImport = false;
                    AssetDatabase.importPackageCompleted -= OnTmpImported;
                    AssetDatabase.importPackageFailed -= OnTmpImportFailed;
                    Debug.LogError("[ZooThrow] Не найден пакет TMP Essential Resources. Импортируй вручную: Window → TextMeshPro → Import TMP Essential Resources, затем снова ZooThrow → Настроить проект.");
                    return;
                }
                return; // continues in OnTmpImported
            }
            RunSetupSynchronousParts();
            if (interactive && EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) EditorSceneManager.OpenScene(ScenePath);
            else if (!interactive && SceneManager.GetActiveScene().path != ScenePath && string.IsNullOrEmpty(SceneManager.GetActiveScene().path)) EditorSceneManager.OpenScene(ScenePath);
            Debug.Log("[ZooThrow] Проект настроен. Открой сцену " + ScenePath + " и нажми Play.");
            if (interactive) EditorUtility.DisplayDialog("ZooThrow", "Проект настроен.\nСцена: " + ScenePath + "\nНажми Play, чтобы играть.", "OK");
        }

        static void OnTmpImported(string packageName)
        {
            if (!s_WaitingForTmpImport) return;
            s_WaitingForTmpImport = false;
            AssetDatabase.importPackageCompleted -= OnTmpImported;
            AssetDatabase.importPackageFailed -= OnTmpImportFailed;
            EditorApplication.delayCall += () => RunSetup(false);
        }

        static void OnTmpImportFailed(string packageName, string error)
        {
            s_WaitingForTmpImport = false;
            AssetDatabase.importPackageCompleted -= OnTmpImported;
            AssetDatabase.importPackageFailed -= OnTmpImportFailed;
            Debug.LogError("[ZooThrow] Импорт TMP Essentials не удался: " + error);
        }

        static void RunSetupSynchronousParts()
        {
            EnsureFolders();
            ConfigureUrp();
            CreateFonts();
            if (AssetDatabase.LoadAssetAtPath<GameDatabase>(ResourcesFolder + "/" + GameDatabase.ResourcePath + ".asset") == null) CreateData();
            if (!File.Exists(ScenePath)) CreateScene();
            ConfigureBuildSettings();
            ConfigurePlayerSettings();
            AssetDatabase.SaveAssets();
            File.WriteAllText(MarkerPath, "ZooThrow setup completed " + DateTime.Now.ToString("u") + "\n");
        }

        static void EnsureFolders()
        {
            foreach (var f in new[] { SettingsFolder, DataFolder, ResourcesFolder, ResourcesFolder + "/Fonts", Root + "/Scenes" })
                EnsureFolder(f);
        }

        static void EnsureFolder(string path)
        {
            if (AssetDatabase.IsValidFolder(path)) return;
            string parent = Path.GetDirectoryName(path).Replace('\\', '/');
            EnsureFolder(parent);
            AssetDatabase.CreateFolder(parent, Path.GetFileName(path));
        }

        // ------------------------------------------------------------------ TMP

        static bool TmpEssentialsPresent() => Resources.Load<TMP_Settings>("TMP Settings") != null;

        static bool ImportTmpEssentials()
        {
            var info = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(TMP_Text).Assembly);
            var candidates = new List<string>();
            if (info != null) candidates.Add(Path.Combine(info.resolvedPath, "Package Resources", "TMP Essential Resources.unitypackage"));
            candidates.Add(Path.GetFullPath("Packages/com.unity.ugui/Package Resources/TMP Essential Resources.unitypackage"));
            candidates.Add(Path.GetFullPath("Packages/com.unity.textmeshpro/Package Resources/TMP Essential Resources.unitypackage"));
            foreach (var c in candidates)
            {
                if (!File.Exists(c)) continue;
                Debug.Log("[ZooThrow] Импорт TMP Essential Resources: " + c);
                AssetDatabase.ImportPackage(c, false);
                return true;
            }
            return false;
        }

        static void CreateFonts()
        {
            var body = CreateFont(FontsFolder + "/PTSans-Bold.ttf", ResourcesFolder + "/Fonts/PTSans SDF.asset");
            var title = CreateFont(FontsFolder + "/RussoOne-Regular.ttf", ResourcesFolder + "/Fonts/RussoOne SDF.asset");
            bool changed = false;
            if (title != null && body != null)
            {
                if (title.fallbackFontAssetTable == null) title.fallbackFontAssetTable = new List<TMP_FontAsset>();
                if (!title.fallbackFontAssetTable.Contains(body)) { title.fallbackFontAssetTable.Add(body); changed = true; EditorUtility.SetDirty(title); }
            }
            var def = TMP_Settings.defaultFontAsset;
            if (body != null && def != null && def != body)
            {
                if (body.fallbackFontAssetTable == null) body.fallbackFontAssetTable = new List<TMP_FontAsset>();
                if (!body.fallbackFontAssetTable.Contains(def)) { body.fallbackFontAssetTable.Add(def); changed = true; EditorUtility.SetDirty(body); }
            }
            if (changed) AssetDatabase.SaveAssets();
        }

        const string Alphabet = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя" +
                                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?-+=/%$()[]«»—…•×'\"<>#&*_";

        static TMP_FontAsset CreateFont(string ttfPath, string assetPath)
        {
            var existing = AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(assetPath);
            if (existing != null) return existing;
            var font = AssetDatabase.LoadAssetAtPath<Font>(ttfPath);
            if (font == null)
            {
                Debug.LogError("[ZooThrow] Не найден файл шрифта " + ttfPath);
                return null;
            }
            var fa = TMP_FontAsset.CreateFontAsset(font, 64, 6, GlyphRenderMode.SDFAA, 1024, 1024, AtlasPopulationMode.Dynamic, true);
            if (fa == null)
            {
                Debug.LogError("[ZooThrow] TMP не смог создать шрифт из " + ttfPath);
                return null;
            }
            fa.name = Path.GetFileNameWithoutExtension(assetPath);
            AssetDatabase.CreateAsset(fa, assetPath);
            var tex = fa.atlasTextures[0];
            tex.name = fa.name + " Atlas";
            AssetDatabase.AddObjectToAsset(tex, fa);
            var mat = fa.material;
            if (mat != null)
            {
                var sdf = Shader.Find("TextMeshPro/Distance Field");
                if (sdf != null) mat.shader = sdf;
                mat.name = fa.name + " Material";
                AssetDatabase.AddObjectToAsset(mat, fa);
            }
            fa.TryAddCharacters(Alphabet, out _);
            EditorUtility.SetDirty(fa);
            AssetDatabase.SaveAssets();
            AssetDatabase.ImportAsset(assetPath);
            Debug.Log("[ZooThrow] Создан шрифт " + assetPath);
            return AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(assetPath);
        }

        // ------------------------------------------------------------------ URP

        static void ConfigureUrp()
        {
            var current = GraphicsSettings.defaultRenderPipeline;
            if (current is UniversalRenderPipelineAsset)
            {
                AssignToQualityLevels(current);
                return;
            }
            string rendererPath = SettingsFolder + "/ZooThrow_Renderer.asset";
            string assetPath = SettingsFolder + "/ZooThrow_URP.asset";
            var rendererData = AssetDatabase.LoadAssetAtPath<UniversalRendererData>(rendererPath);
            if (rendererData == null)
            {
                rendererData = ScriptableObject.CreateInstance<UniversalRendererData>();
                AssetDatabase.CreateAsset(rendererData, rendererPath);
            }
            var urp = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(assetPath);
            if (urp == null)
            {
                urp = UniversalRenderPipelineAsset.Create(rendererData);
                AssetDatabase.CreateAsset(urp, assetPath);
            }
            TuneUrpAsset(urp);
            GraphicsSettings.defaultRenderPipeline = urp;
            AssignToQualityLevels(urp);
            AssetDatabase.SaveAssets();
            Debug.Log("[ZooThrow] URP настроен: " + assetPath);
        }

        static void TuneUrpAsset(UniversalRenderPipelineAsset urp)
        {
            var so = new SerializedObject(urp);
            void SetInt(string name, int v) { var p = so.FindProperty(name); if (p != null) p.intValue = v; }
            void SetBool(string name, bool v) { var p = so.FindProperty(name); if (p != null) p.boolValue = v; }
            void SetFloat(string name, float v) { var p = so.FindProperty(name); if (p != null) p.floatValue = v; }
            SetBool("m_SupportsHDR", false);
            SetInt("m_MSAA", 2);
            SetFloat("m_RenderScale", 1f);
            SetBool("m_MainLightShadowsSupported", true);
            SetInt("m_MainLightShadowmapResolution", 2048);
            SetFloat("m_ShadowDistance", 110f);
            SetInt("m_ShadowCascadeCount", 1);
            SetBool("m_SoftShadowsSupported", true);
            SetInt("m_AdditionalLightsRenderingMode", 0);
            SetBool("m_RequireDepthTexture", false);
            SetBool("m_RequireOpaqueTexture", false);
            so.ApplyModifiedPropertiesWithoutUndo();
            EditorUtility.SetDirty(urp);
        }

        /// <summary>Per-quality-level pipeline overrides win over the default one, so point them all at our asset.</summary>
        static void AssignToQualityLevels(RenderPipelineAsset asset)
        {
            var qs = AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/QualitySettings.asset").FirstOrDefault();
            if (qs == null) return;
            var so = new SerializedObject(qs);
            var levels = so.FindProperty("m_QualitySettings");
            if (levels == null) return;
            bool changed = false;
            for (int i = 0; i < levels.arraySize; i++)
            {
                var rp = levels.GetArrayElementAtIndex(i).FindPropertyRelative("customRenderPipeline");
                if (rp != null && rp.objectReferenceValue == null) { rp.objectReferenceValue = asset; changed = true; }
            }
            if (changed) so.ApplyModifiedPropertiesWithoutUndo();
        }

        // ------------------------------------------------------------------ data

        static void CreateData()
        {
            EnsureFolders();
            var db = DefaultContent.Create();
            string Save<T>(T so, string sub) where T : ScriptableObject
            {
                EnsureFolder(DataFolder + "/" + sub);
                string path = DataFolder + "/" + sub + "/" + so.name + ".asset";
                AssetDatabase.CreateAsset(so, path);
                return path;
            }
            Save(db.balance, "Balance");
            foreach (var r in db.rarities) Save(r, "Rarities");
            foreach (var b in db.biomes) Save(b, "Biomes");
            foreach (var a in db.animals) Save(a, "Animals");
            foreach (var f in db.baits) Save(f, "Baits");
            foreach (var r in db.rods) Save(r, "Rods");
            foreach (var t in db.trainers) Save(t, "Trainers");
            foreach (var u in db.upgrades) Save(u, "Upgrades");
            db.name = "ZooThrowDatabase";
            AssetDatabase.CreateAsset(db, ResourcesFolder + "/" + GameDatabase.ResourcePath + ".asset");
            AssetDatabase.SaveAssets();
            Debug.Log("[ZooThrow] Созданы данные игры: " + db.animals.Count + " существ, " + db.rods.Count + " удочек, " + db.baits.Count + " видов наживки, " + db.biomes.Count + " локаций.");
        }

        // ------------------------------------------------------------------ scene and build

        static void CreateScene()
        {
            EnsureFolders();
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var go = new GameObject("ZooThrow");
            go.AddComponent<GameBootstrap>();
            EditorSceneManager.SaveScene(scene, ScenePath);
            Debug.Log("[ZooThrow] Создана сцена " + ScenePath);
        }

        static void ConfigureBuildSettings()
        {
            var scenes = EditorBuildSettings.scenes.ToList();
            scenes.RemoveAll(s => s.path == ScenePath);
            scenes.Insert(0, new EditorBuildSettingsScene(ScenePath, true));
            EditorBuildSettings.scenes = scenes.ToArray();
        }

        static void ConfigurePlayerSettings()
        {
            PlayerSettings.companyName = "ZooThrow";
            PlayerSettings.productName = "Клёвый Улов";
            PlayerSettings.colorSpace = ColorSpace.Linear;
            PlayerSettings.runInBackground = true;
            PlayerSettings.defaultWebScreenWidth = 1280;
            PlayerSettings.defaultWebScreenHeight = 720;
            PlayerSettings.WebGL.compressionFormat = WebGLCompressionFormat.Brotli;
            PlayerSettings.WebGL.decompressionFallback = true;
            PlayerSettings.WebGL.dataCaching = true;
            PlayerSettings.WebGL.exceptionSupport = WebGLExceptionSupport.ExplicitlyThrownExceptionsOnly;
            if (AssetDatabase.IsValidFolder("Assets/WebGLTemplates/ZooThrow")) PlayerSettings.WebGL.template = "PROJECT:ZooThrow";
        }

        static BuildReport BuildWebGL()
        {
            if (EditorUserBuildSettings.activeBuildTarget != BuildTarget.WebGL)
                EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.WebGL, BuildTarget.WebGL);
            Directory.CreateDirectory(BuildFolder);
            var options = new BuildPlayerOptions
            {
                scenes = new[] { ScenePath },
                locationPathName = BuildFolder,
                target = BuildTarget.WebGL,
                options = BuildOptions.None,
            };
            var report = BuildPipeline.BuildPlayer(options);
            Debug.Log("[ZooThrow] WebGL build: " + report.summary.result + ", размер " + (report.summary.totalSize / (1024f * 1024f)).ToString("0.0") + " МБ, ошибок " + report.summary.totalErrors);
            return report;
        }
    }
}
