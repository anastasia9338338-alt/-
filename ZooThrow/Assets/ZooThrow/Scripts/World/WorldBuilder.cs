using System.Collections.Generic;
using TMPro;
using UnityEngine;
using ZooThrow.Data;
using ZooThrow.UI;
using ZooThrow.Visuals;

namespace ZooThrow.World
{
    /// <summary>
    /// Builds the whole map procedurally: lighting and sky, the base (pen, training, shops, throw pad) and the long
    /// throwing track split into biomes. Static geometry is merged into a few large vertex-coloured meshes per
    /// area so the scene stays at a low draw-call count for WebGL.
    /// </summary>
    public class WorldBuilder : MonoBehaviour
    {
        GameDatabase _db;
        Transform _static;
        Light _sun;
        readonly List<Transform> _clouds = new List<Transform>();
        public Light Sun => _sun;

        static readonly Color BaseGrass = new Color(0.47f, 0.8f, 0.36f);
        static readonly Color BaseGrassAlt = new Color(0.43f, 0.75f, 0.33f);
        static readonly Color Path = new Color(0.86f, 0.8f, 0.68f);
        static readonly Color Wood = new Color(0.66f, 0.45f, 0.27f);
        static readonly Color Stone = new Color(0.62f, 0.64f, 0.68f);

        public void Build(GameDatabase db)
        {
            _db = db;
            _static = new GameObject("Static").transform;
            _static.SetParent(transform, false);
            BuildLighting();
            BuildColliders();
            BuildBase();
            BuildTrack();
            BuildBackdrop();
            BuildClouds();
        }

        public float GroundHeightAt(Vector3 p) => 0f;

        // ------------------------------------------------------------ lighting

        void BuildLighting()
        {
            var sunGo = new GameObject("Sun");
            sunGo.transform.SetParent(transform, false);
            sunGo.transform.rotation = Quaternion.Euler(48f, -32f, 0f);
            _sun = sunGo.AddComponent<Light>();
            _sun.type = LightType.Directional;
            _sun.color = new Color(1f, 0.96f, 0.88f);
            _sun.intensity = 1.15f;
            _sun.shadows = LightShadows.Soft;
            _sun.shadowStrength = 0.75f;
            _sun.shadowBias = 0.05f;
            _sun.shadowNormalBias = 0.4f;
            RenderSettings.sun = _sun;

            MaterialLibrary.SetAmbient(new Color(0.62f, 0.72f, 0.9f), new Color(0.42f, 0.42f, 0.38f), -sunGo.transform.forward);
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.62f, 0.72f, 0.9f);
            RenderSettings.ambientEquatorColor = new Color(0.6f, 0.65f, 0.6f);
            RenderSettings.ambientGroundColor = new Color(0.42f, 0.42f, 0.38f);
            var sky = MaterialLibrary.Sky;
            sky.SetColor("_ZenithColor", new Color(0.28f, 0.58f, 0.98f));
            sky.SetColor("_HorizonColor", new Color(0.78f, 0.9f, 1f));
            sky.SetColor("_GroundColor", new Color(0.62f, 0.78f, 0.6f));
            RenderSettings.skybox = sky;
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.Linear;
            RenderSettings.fogColor = new Color(0.78f, 0.9f, 1f);
            RenderSettings.fogStartDistance = 90f;
            RenderSettings.fogEndDistance = 320f;
        }

        public void SetFogDistances(float start, float end)
        {
            RenderSettings.fogStartDistance = start;
            RenderSettings.fogEndDistance = end;
        }

        // ------------------------------------------------------------ helpers

        GameObject Emit(string name, MeshBuilder mb, bool shadows = true)
        {
            var go = MaterialLibrary.MeshObject(name, _static, mb.ToMesh(name), Vector3.zero, shadows);
            go.isStatic = true;
            mb.Clear();
            return go;
        }

        void BoxCollider(Vector3 center, Vector3 size) => BoxCollider(center, size, Quaternion.identity);

        void BoxCollider(Vector3 center, Vector3 size, Quaternion rotation)
        {
            var go = new GameObject("Collider");
            go.transform.SetParent(_static, false);
            go.transform.SetPositionAndRotation(center, rotation);
            var c = go.AddComponent<BoxCollider>();
            c.size = size;
        }

        public static TextMeshPro WorldText(Transform parent, string text, Vector3 pos, Quaternion rot, float size, Color color, bool title = true)
        {
            var go = new GameObject("Text");
            go.transform.SetParent(parent, false);
            go.transform.SetPositionAndRotation(pos, rot);
            var t = go.AddComponent<TextMeshPro>();
            t.font = title ? FontLibrary.Title : FontLibrary.Body;
            t.fontSize = size;
            t.color = color;
            t.alignment = TextAlignmentOptions.Center;
            t.enableWordWrapping = false;
            t.text = text;
            t.rectTransform.sizeDelta = new Vector2(20f, 4f);
            var r = t.GetComponent<MeshRenderer>();
            r.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            return t;
        }

        void Sign(MeshBuilder mb, Vector3 pos, float yaw, float width, float height, Color board, string text, Color textColor, float textSize, float postHeight = 2.2f)
        {
            Quaternion rot = Quaternion.Euler(0, yaw, 0);
            mb.Box(pos + rot * new Vector3(-width * 0.42f, postHeight * 0.5f, 0), new Vector3(0.2f, postHeight, 0.2f), rot, Wood);
            mb.Box(pos + rot * new Vector3(width * 0.42f, postHeight * 0.5f, 0), new Vector3(0.2f, postHeight, 0.2f), rot, Wood);
            mb.Box(pos + Vector3.up * (postHeight + height * 0.5f), new Vector3(width + 0.25f, height + 0.25f, 0.18f), rot, MeshBuilder.Shade(board, 0.75f));
            mb.Box(pos + Vector3.up * (postHeight + height * 0.5f) + rot * new Vector3(0, 0, -0.05f), new Vector3(width, height, 0.15f), rot, board);
            // Text faces the reader (towards -Z of the sign); TMP's front is its -Z, so rotate by the sign yaw.
            WorldText(_static, text, pos + Vector3.up * (postHeight + height * 0.5f) + rot * new Vector3(0, 0, -0.14f), rot, textSize, textColor);
        }

        // ------------------------------------------------------------ colliders

        void BuildColliders()
        {
            // One large ground slab; top surface at y = 0.
            BoxCollider(new Vector3(0, -1f, 380f), new Vector3(400f, 2f, 1000f));
            // Invisible side walls so the player stays on the map.
            BoxCollider(new Vector3(WorldLayout.WorldHalfWidth + 1f, 5f, 380f), new Vector3(2f, 20f, 1000f));
            BoxCollider(new Vector3(-WorldLayout.WorldHalfWidth - 1f, 5f, 380f), new Vector3(2f, 20f, 1000f));
            BoxCollider(new Vector3(0, 5f, -62f), new Vector3(200f, 20f, 2f));
            float end = WorldLayout.ThrowOriginZ + _db.balance.maxThrowDistance + 25f;
            BoxCollider(new Vector3(0, 5f, end), new Vector3(200f, 20f, 2f));
        }

        // ------------------------------------------------------------ base

        void BuildBase()
        {
            var mb = new MeshBuilder();
            var rng = new System.Random(7);
            // Grass tiles
            for (float x = -90f; x < 90f; x += 10f)
                for (float z = -60f; z < WorldLayout.ThrowOriginZ; z += 10f)
                {
                    var c = ((int)(x / 10f) + (int)(z / 10f)) % 2 == 0 ? BaseGrass : BaseGrassAlt;
                    float z1 = Mathf.Min(z + 10f, WorldLayout.ThrowOriginZ);
                    mb.Quad(new Vector3(x, 0, z), new Vector3(x, 0, z1), new Vector3(x + 10f, 0, z1), new Vector3(x + 10f, 0, z), MeshBuilder.Jitter(c, rng, 0.03f));
                }
            // Paths
            PathStrip(mb, new Vector3(0, 0, -20f), new Vector3(0, 0, WorldLayout.ThrowOriginZ), 4f);
            PathStrip(mb, new Vector3(-14f, 0, -14f), new Vector3(14f, 0, -14f), 3.5f);
            PathStrip(mb, new Vector3(-13f, 0, 3f), new Vector3(13f, 0, 3f), 3f);
            PathStrip(mb, new Vector3(0, 0, -14f), new Vector3(0, 0, -24f), 3f);
            Emit("BaseGround", mb, false);

            BuildPen(mb, rng);
            BuildTraining(mb);
            BuildShop(mb, WorldLayout.FoodShop, new Color(1f, 0.55f, 0.15f), "ЕДА", StationKind.FoodShop, "[E] Магазин еды", rng, true);
            BuildShop(mb, WorldLayout.UpgradeShop, new Color(0.25f, 0.55f, 1f), "УЛУЧШЕНИЯ", StationKind.UpgradeShop, "[E] Улучшения и тренажёры", rng, false);
            BuildMuseum(mb);
            BuildThrowPad(mb);

            // Trees around the base edges
            for (int i = 0; i < 70; i++)
            {
                float x = (float)(rng.NextDouble() * 170 - 85);
                float z = (float)(rng.NextDouble() * 55 - 58);
                if (Mathf.Abs(x) < 46f && z > -40f) continue;
                if (rng.NextDouble() < 0.6) DecorFactory.RoundTree(mb, new Vector3(x, 0, z), rng, new Color(0.3f, 0.68f, 0.3f));
                else DecorFactory.Bush(mb, new Vector3(x, 0, z), rng, new Color(0.35f, 0.72f, 0.32f));
            }
            for (int i = 0; i < 80; i++)
            {
                float x = (float)(rng.NextDouble() * 120 - 60), z = (float)(rng.NextDouble() * 60 - 55);
                if (Mathf.Abs(x) < 5f || InsideFootprint(x, z)) continue;
                if (rng.NextDouble() < 0.7) DecorFactory.Flower(mb, new Vector3(x, 0, z), rng);
                else DecorFactory.GrassTuft(mb, new Vector3(x, 0, z), rng, new Color(0.38f, 0.7f, 0.3f));
            }
            Emit("BaseDecor", mb);
        }

        static bool InsideFootprint(float x, float z)
        {
            Vector3 pen = WorldLayout.PenCenter;
            if (Mathf.Abs(x - pen.x) < WorldLayout.PenSize.x * 0.5f + 2f && Mathf.Abs(z - pen.z) < WorldLayout.PenSize.y * 0.5f + 2f) return true;
            if (Vector2.Distance(new Vector2(x, z), new Vector2(WorldLayout.TrainingCenter.x, WorldLayout.TrainingCenter.z)) < 11f) return true;
            if (Vector2.Distance(new Vector2(x, z), new Vector2(WorldLayout.FoodShop.x, WorldLayout.FoodShop.z)) < 6f) return true;
            if (Vector2.Distance(new Vector2(x, z), new Vector2(WorldLayout.UpgradeShop.x, WorldLayout.UpgradeShop.z)) < 6f) return true;
            return false;
        }

        static void PathStrip(MeshBuilder mb, Vector3 a, Vector3 b, float width)
        {
            Vector3 d = b - a;
            Vector3 side = Vector3.Cross(Vector3.up, d.normalized) * width * 0.5f;
            Vector3 y = Vector3.up * 0.02f;
            mb.Quad(a - side + y, b - side + y, b + side + y, a + side + y, Path);
        }

        void BuildPen(MeshBuilder mb, System.Random rng)
        {
            Vector3 c = WorldLayout.PenCenter;
            Vector2 s = WorldLayout.PenSize;
            float hx = s.x * 0.5f, hz = s.y * 0.5f;
            mb.Box(c + Vector3.up * 0.01f, new Vector3(s.x, 0.04f, s.y), new Color(0.78f, 0.66f, 0.42f));
            // Fence with a gate gap on the east side (towards the spawn plaza).
            Vector3 nw = c + new Vector3(-hx, 0, hz), ne = c + new Vector3(hx, 0, hz), sw = c + new Vector3(-hx, 0, -hz), se = c + new Vector3(hx, 0, -hz);
            DecorFactory.Fence(mb, nw, ne, Wood);
            DecorFactory.Fence(mb, sw, se, Wood);
            DecorFactory.Fence(mb, nw, sw, Wood);
            DecorFactory.Fence(mb, ne, c + new Vector3(hx, 0, 2.5f), Wood);
            DecorFactory.Fence(mb, c + new Vector3(hx, 0, -2.5f), se, Wood);
            BoxCollider(c + new Vector3(0, 0.7f, hz), new Vector3(s.x, 1.4f, 0.4f));
            BoxCollider(c + new Vector3(0, 0.7f, -hz), new Vector3(s.x, 1.4f, 0.4f));
            BoxCollider(c + new Vector3(-hx, 0.7f, 0), new Vector3(0.4f, 1.4f, s.y));
            BoxCollider(c + new Vector3(hx, 0.7f, (hz + 2.5f) * 0.5f), new Vector3(0.4f, 1.4f, hz - 2.5f));
            BoxCollider(c + new Vector3(hx, 0.7f, -(hz + 2.5f) * 0.5f), new Vector3(0.4f, 1.4f, hz - 2.5f));
            // Gate arch
            Vector3 gate = c + new Vector3(hx, 0, 0);
            mb.Box(gate + new Vector3(0, 1.8f, 2.6f), new Vector3(0.35f, 3.6f, 0.35f), Wood);
            mb.Box(gate + new Vector3(0, 1.8f, -2.6f), new Vector3(0.35f, 3.6f, 0.35f), Wood);
            mb.Box(gate + new Vector3(0, 3.8f, 0), new Vector3(0.5f, 0.9f, 6.2f), new Color(0.35f, 0.75f, 0.35f));
            WorldText(_static, "ЗАГОН", gate + new Vector3(0.3f, 3.8f, 0), Quaternion.Euler(0, -90f, 0), 7f, Color.white);
            // Hay bales and a water trough
            for (int i = 0; i < 3; i++)
                mb.Box(c + new Vector3(-hx + 1.5f, 0.5f, -hz + 1.6f + i * 1.3f), new Vector3(1.8f, 1f, 1.1f), new Color(0.95f, 0.82f, 0.4f));
            mb.Box(c + new Vector3(-hx + 1.4f, 0.4f, hz - 3f), new Vector3(1.2f, 0.8f, 3f), Wood);
            mb.Box(c + new Vector3(-hx + 1.4f, 0.75f, hz - 3f), new Vector3(0.9f, 0.1f, 2.7f), new Color(0.35f, 0.65f, 1f));
            Emit("Pen", mb);
            Station.Create(_static, StationKind.Pen, gate + new Vector3(2f, 0, 0), 5.5f, "[E] Управлять загоном");
        }

        void BuildTraining(MeshBuilder mb)
        {
            Vector3 c = WorldLayout.TrainingCenter;
            mb.Box(c + new Vector3(0, 0.05f, -3f), new Vector3(14f, 0.1f, 14f), new Color(0.32f, 0.34f, 0.42f));
            mb.Box(c + new Vector3(0, 0.08f, 0), new Vector3(4f, 0.06f, 3f), new Color(0.9f, 0.3f, 0.3f));
            mb.Push(WorldLayout.PullUpBar);
            TrainerModelFactory.Build(mb, TrainerShape.PullUpBar, new Color(0.25f, 0.55f, 1f));
            mb.Pop();
            Sign(mb, c + new Vector3(0, 0, 4.5f), 180f, 6f, 1.4f, new Color(0.9f, 0.3f, 0.3f), "ТРЕНИРОВКА", Color.white, 7f, 2.6f);
            Emit("Training", mb);
            BoxCollider(WorldLayout.PullUpBar + new Vector3(-1.3f, 1.65f, 0), new Vector3(0.3f, 3.3f, 0.3f));
            BoxCollider(WorldLayout.PullUpBar + new Vector3(1.3f, 1.65f, 0), new Vector3(0.3f, 3.3f, 0.3f));
            Station.Create(_static, StationKind.Training, WorldLayout.PullUpBar, 4f, "[E] Тренироваться");
        }

        void BuildShop(MeshBuilder mb, Vector3 p, Color accent, string title, StationKind kind, string prompt, System.Random rng, bool food)
        {
            // Stall faces the plaza (towards x = 0).
            float face = p.x < 0 ? 90f : -90f;
            Quaternion rot = Quaternion.Euler(0, face, 0);
            mb.Push(p, rot);
            mb.Box(new Vector3(0, 0.6f, 0), new Vector3(5f, 1.2f, 1.4f), Wood);
            mb.Box(new Vector3(0, 1.25f, 0), new Vector3(5.3f, 0.12f, 1.7f), MeshBuilder.Shade(Wood, 1.2f));
            mb.Box(new Vector3(-2.4f, 1.9f, -1.2f), new Vector3(0.22f, 3.8f, 0.22f), Wood);
            mb.Box(new Vector3(2.4f, 1.9f, -1.2f), new Vector3(0.22f, 3.8f, 0.22f), Wood);
            mb.Box(new Vector3(-2.4f, 1.5f, 1.2f), new Vector3(0.22f, 3f, 0.22f), Wood);
            mb.Box(new Vector3(2.4f, 1.5f, 1.2f), new Vector3(0.22f, 3f, 0.22f), Wood);
            for (int i = 0; i < 7; i++)
                mb.Box(new Vector3(-2.6f + i * 0.87f, 3.45f, 0), new Vector3(0.87f, 0.12f, 3.2f), Quaternion.Euler(-12f, 0, 0), i % 2 == 0 ? accent : Color.white);
            mb.Box(new Vector3(0, 4.3f, -1.3f), new Vector3(5.2f, 1.2f, 0.25f), accent);
            if (food)
            {
                for (int i = 0; i < 4; i++)
                {
                    mb.Box(new Vector3(-1.8f + i * 1.2f, 1.55f, 0.2f), new Vector3(0.9f, 0.5f, 0.8f), MeshBuilder.Shade(Wood, 0.8f));
                    Color fc = i % 2 == 0 ? new Color(0.9f, 0.15f, 0.15f) : new Color(1f, 0.55f, 0.1f);
                    for (int k = 0; k < 4; k++) mb.Sphere(new Vector3(-2f + i * 1.2f + (k % 2) * 0.35f, 1.88f, 0.05f + (k / 2) * 0.3f), 0.3f, fc, 6, 4);
                }
            }
            else
            {
                mb.Box(new Vector3(-1.2f, 1.75f, 0.1f), new Vector3(0.5f, 0.9f, 0.5f), new Color(1f, 0.85f, 0.2f), 0.2f);
                mb.Sphere(new Vector3(0.6f, 1.8f, 0.1f), 0.8f, new Color(0.55f, 0.35f, 1f), 8, 5);
                mb.Box(new Vector3(1.8f, 1.6f, 0.1f), new Vector3(0.8f, 0.5f, 0.5f), new Color(0.3f, 0.3f, 0.35f));
            }
            mb.Pop();
            Emit("Shop_" + kind, mb);
            // The customer stands on the local +Z side (low front of the awning); the sign board is at the back.
            WorldText(_static, title, p + Vector3.up * 4.3f + rot * new Vector3(0, 0, -1.12f), rot * Quaternion.Euler(0, 180f, 0), 7f, Color.white);
            BoxCollider(p + Vector3.up * 0.6f, new Vector3(5f, 1.2f, 1.4f), rot);
            Station.Create(_static, kind, p + rot * new Vector3(0, 0, 2.5f), 4.5f, prompt);
        }

        void BuildMuseum(MeshBuilder mb)
        {
            Vector3 p = WorldLayout.Museum;
            mb.Box(p + new Vector3(0, 0.25f, 0), new Vector3(12f, 0.5f, 6f), Stone);
            for (int i = 0; i < 4; i++) mb.Cylinder(p + new Vector3(-4.5f + i * 3f, 0.5f, 2f), 0.35f, 0.35f, 4f, 8, Color.white);
            mb.Box(p + new Vector3(0, 4.8f, 0), new Vector3(12.5f, 0.6f, 6.5f), new Color(0.95f, 0.95f, 0.98f));
            mb.Box(p + new Vector3(0, 5.5f, 0), new Vector3(10f, 0.8f, 5f), new Color(0.95f, 0.8f, 0.3f), 0.6f);
            mb.Box(p + new Vector3(0, 2.5f, -2f), new Vector3(11f, 4f, 0.4f), new Color(0.55f, 0.35f, 0.75f));
            Emit("Museum", mb);
            WorldText(_static, "КОЛЛЕКЦИЯ", p + new Vector3(0, 4.8f, 3.27f), Quaternion.Euler(0, 180f, 0), 8f, new Color(0.35f, 0.2f, 0.5f));
            BoxCollider(p + new Vector3(0, 2.5f, -2f), new Vector3(11f, 5f, 0.6f));
            Station.Create(_static, StationKind.Collection, p + new Vector3(0, 0, 3.5f), 5f, "[E] Коллекция животных");
        }

        void BuildThrowPad(MeshBuilder mb)
        {
            Vector3 p = WorldLayout.ThrowPad;
            mb.Cylinder(p, WorldLayout.PadRadius + 0.3f, WorldLayout.PadRadius, 0.25f, 20, new Color(1f, 0.85f, 0.25f));
            mb.Cylinder(p + Vector3.up * 0.25f, WorldLayout.PadRadius - 0.5f, WorldLayout.PadRadius - 0.6f, 0.04f, 20, new Color(1f, 0.55f, 0.15f));
            mb.Cylinder(p + Vector3.up * 0.29f, 1.2f, 1.2f, 0.03f, 16, Color.white);
            // Arrow pointing down the track
            mb.Box(p + new Vector3(0, 0.33f, 1.8f), new Vector3(0.6f, 0.04f, 1.4f), Color.white);
            mb.Push(p + new Vector3(0, 0.3f, 2.6f), Quaternion.Euler(90f, 0, 0));
            mb.Cone(Vector3.zero, 0.8f, 0.9f, 3, Color.white);
            mb.Pop();
            // Start arch over the beginning of the track
            Vector3 arch = WorldLayout.TrackPoint(4f);
            mb.Box(arch + new Vector3(-7f, 3.5f, 0), new Vector3(0.8f, 7f, 0.8f), new Color(1f, 0.55f, 0.15f));
            mb.Box(arch + new Vector3(7f, 3.5f, 0), new Vector3(0.8f, 7f, 0.8f), new Color(1f, 0.55f, 0.15f));
            mb.Box(arch + new Vector3(0, 7.4f, 0), new Vector3(15.5f, 1.8f, 0.9f), new Color(1f, 0.85f, 0.25f));
            Emit("ThrowPad", mb);
            BoxCollider(p + Vector3.up * 0.13f, new Vector3(WorldLayout.PadRadius * 1.7f, 0.26f, WorldLayout.PadRadius * 1.7f));
            WorldText(_static, "ЗОО-БРОСОК", arch + new Vector3(0, 7.4f, -0.5f), Quaternion.identity, 12f, new Color(0.55f, 0.25f, 0.05f));
            WorldText(_static, "ЗОНА БРОСКА", p + new Vector3(0, 0.36f, 0), Quaternion.Euler(90f, 0, 0), 5f, new Color(0.55f, 0.3f, 0.05f));
            Station.Create(_static, StationKind.Throw, p, WorldLayout.PadRadius + 1f, "[E] Бросить еду");
        }

        // ------------------------------------------------------------ track and biomes

        void BuildTrack()
        {
            var b = _db.balance;
            var rng = new System.Random(99);
            float trackEnd = b.maxThrowDistance + 20f;
            var mb = new MeshBuilder();

            foreach (var biome in _db.biomes)
            {
                float z0 = WorldLayout.ThrowOriginZ + biome.startDistance;
                float z1 = WorldLayout.ThrowOriginZ + Mathf.Min(biome.endDistance, trackEnd);
                if (biome == _db.biomes[_db.biomes.Count - 1]) z1 = WorldLayout.ThrowOriginZ + trackEnd + 15f;
                bool ocean = biome.style == BiomeStyle.Ocean;
                // Ground tiles
                for (float x = -WorldLayout.WorldHalfWidth; x < WorldLayout.WorldHalfWidth; x += 10f)
                    for (float z = z0; z < z1; z += 10f)
                    {
                        float zz = Mathf.Min(z + 10f, z1);
                        Color c;
                        if (ocean)
                        {
                            bool island = Mathf.Abs(x + 5f) < 12f || Mathf.PerlinNoise(x * 0.04f + 3f, z * 0.04f) > 0.62f;
                            c = island ? biome.groundColor : biome.groundColorAlt;
                        }
                        else c = (((int)(x / 10f) + (int)(z / 10f)) & 1) == 0 ? biome.groundColor : biome.groundColorAlt;
                        mb.Quad(new Vector3(x, 0, z), new Vector3(x, 0, zz), new Vector3(x + 10f, 0, zz), new Vector3(x + 10f, 0, z), MeshBuilder.Jitter(c, rng, 0.025f));
                    }
                // Lane (a wooden pier over the ocean)
                Color lane = biome.laneColor;
                float laneY = ocean ? 0.1f : 0.03f;
                mb.Box(new Vector3(0, laneY * 0.5f, (z0 + z1) * 0.5f), new Vector3(WorldLayout.LaneHalfWidth * 2f, laneY, z1 - z0), lane);
                mb.Box(new Vector3(-WorldLayout.LaneHalfWidth, laneY + 0.02f, (z0 + z1) * 0.5f), new Vector3(0.25f, 0.05f, z1 - z0), Color.white);
                mb.Box(new Vector3(WorldLayout.LaneHalfWidth, laneY + 0.02f, (z0 + z1) * 0.5f), new Vector3(0.25f, 0.05f, z1 - z0), Color.white);
                if (ocean)
                    for (float z = z0; z < z1; z += 6f)
                    {
                        mb.Box(new Vector3(-WorldLayout.LaneHalfWidth + 0.3f, -0.5f, z), new Vector3(0.4f, 1.6f, 0.4f), new Color(0.45f, 0.3f, 0.18f));
                        mb.Box(new Vector3(WorldLayout.LaneHalfWidth - 0.3f, -0.5f, z), new Vector3(0.4f, 1.6f, 0.4f), new Color(0.45f, 0.3f, 0.18f));
                    }
                Emit("Ground_" + biome.id, mb, false);

                // Decor in 60 m slices so frustum culling (and the shadow pass) can skip far chunks.
                for (float sz = z0; sz < z1; sz += 60f)
                {
                    Decorate(mb, biome, sz, Mathf.Min(sz + 60f, z1), rng);
                    Emit("Decor_" + biome.id + "_" + Mathf.RoundToInt(sz), mb);
                }
                if (biome.style == BiomeStyle.Desert)
                {
                    DecorFactory.Pyramid(mb, new Vector3(-55f, 0, (z0 + z1) * 0.5f), 18f);
                    DecorFactory.Pyramid(mb, new Vector3(60f, 0, z0 + (z1 - z0) * 0.7f), 14f);
                    Emit("Pyramids", mb);
                }
                BuildGate(mb, biome);
                Emit("Gate_" + biome.id, mb);
            }

            BuildDistanceMarkers(mb, trackEnd);
            Emit("Markers", mb);

            // End of the world
            float endZ = WorldLayout.ThrowOriginZ + trackEnd + 8f;
            Sign(mb, new Vector3(0, 0, endZ), 0f, 9f, 2f, new Color(0.3f, 0.3f, 0.4f), "КРАЙ МИРА", Color.white, 9f, 3f);
            Emit("WorldEnd", mb);
        }

        void BuildGate(MeshBuilder mb, BiomeData biome)
        {
            if (biome.startDistance <= 0f) return;
            Vector3 p = WorldLayout.TrackPoint(biome.startDistance);
            Color c = biome.accentColor;
            mb.Box(p + new Vector3(-WorldLayout.LaneHalfWidth - 1f, 4f, 0), new Vector3(1f, 8f, 1f), c);
            mb.Box(p + new Vector3(WorldLayout.LaneHalfWidth + 1f, 4f, 0), new Vector3(1f, 8f, 1f), c);
            mb.Box(p + new Vector3(0, 8.3f, 0), new Vector3(WorldLayout.LaneHalfWidth * 2f + 4f, 2.2f, 1f), MeshBuilder.Shade(c, 1.15f));
            mb.Box(p + new Vector3(0, 0.06f, 0), new Vector3(WorldLayout.LaneHalfWidth * 2f, 0.06f, 0.6f), Color.white);
            WorldText(_static, biome.displayName.ToUpperInvariant(), p + new Vector3(0, 8.6f, -0.55f), Quaternion.identity, 11f, Color.white);
            WorldText(_static, Core.NumberFormat.Meters(biome.startDistance), p + new Vector3(0, 7.5f, -0.55f), Quaternion.identity, 6f, new Color(1f, 1f, 1f, 0.9f), false);
        }

        void BuildDistanceMarkers(MeshBuilder mb, float trackEnd)
        {
            for (float d = 10f; d <= trackEnd; d += d < 100f ? 10f : 25f)
            {
                Vector3 p = WorldLayout.TrackPoint(d);
                float y = 0.06f;
                mb.Box(p + new Vector3(0, y, 0), new Vector3(WorldLayout.LaneHalfWidth * 2f, 0.04f, 0.2f), new Color(1f, 1f, 1f, 1f));
                for (int side = -1; side <= 1; side += 2)
                {
                    Vector3 post = p + new Vector3(side * (WorldLayout.LaneHalfWidth + 1.6f), 0, 0);
                    mb.Box(post + Vector3.up * 1f, new Vector3(0.25f, 2f, 0.25f), Color.white);
                    mb.Box(post + Vector3.up * 2.4f, new Vector3(2.4f, 1f, 0.2f), new Color(0.15f, 0.2f, 0.35f));
                    WorldText(_static, d.ToString("0") + " м", post + new Vector3(0, 2.4f, -0.12f), Quaternion.identity, 6f, Color.white);
                }
            }
        }

        void Decorate(MeshBuilder mb, BiomeData biome, float z0, float z1, System.Random rng)
        {
            float length = z1 - z0;
            int count = Mathf.RoundToInt(length * 1.4f);
            for (int i = 0; i < count; i++)
            {
                float side = rng.NextDouble() < 0.5 ? -1f : 1f;
                float x = side * (WorldLayout.LaneHalfWidth + 4f + (float)rng.NextDouble() * (WorldLayout.WorldHalfWidth - WorldLayout.LaneHalfWidth - 6f));
                float z = z0 + (float)rng.NextDouble() * length;
                var p = new Vector3(x, 0, z);
                double r = rng.NextDouble();
                switch (biome.style)
                {
                    case BiomeStyle.Forest:
                        if (r < 0.35) DecorFactory.RoundTree(mb, p, rng, new Color(0.25f, 0.62f, 0.28f));
                        else if (r < 0.5) DecorFactory.PineTree(mb, p, rng, new Color(0.18f, 0.5f, 0.3f), false);
                        else if (r < 0.65) DecorFactory.Bush(mb, p, rng, new Color(0.3f, 0.66f, 0.3f));
                        else if (r < 0.75) DecorFactory.Mushroom(mb, p, rng);
                        else if (r < 0.85) DecorFactory.Rock(mb, p, rng, new Color(0.6f, 0.62f, 0.66f));
                        else DecorFactory.Flower(mb, p, rng);
                        break;
                    case BiomeStyle.Savanna:
                        if (r < 0.25) DecorFactory.AcaciaTree(mb, p, rng);
                        else if (r < 0.55) DecorFactory.GrassTuft(mb, p, rng, new Color(0.85f, 0.75f, 0.35f));
                        else if (r < 0.68) DecorFactory.TermiteMound(mb, p, rng);
                        else if (r < 0.8) DecorFactory.Bush(mb, p, rng, new Color(0.55f, 0.62f, 0.25f));
                        else DecorFactory.Rock(mb, p, rng, new Color(0.75f, 0.62f, 0.48f));
                        break;
                    case BiomeStyle.Desert:
                        if (r < 0.35) DecorFactory.Cactus(mb, p, rng);
                        else if (r < 0.5) DecorFactory.Dune(mb, p - Vector3.up * 0.8f, rng, biome.groundColorAlt);
                        else if (r < 0.7) DecorFactory.Rock(mb, p, rng, new Color(0.85f, 0.6f, 0.4f), 1.3f);
                        else if (r < 0.78) DecorFactory.PalmTree(mb, p, rng);
                        else DecorFactory.GrassTuft(mb, p, rng, new Color(0.7f, 0.65f, 0.35f));
                        break;
                    case BiomeStyle.Jungle:
                        if (r < 0.3) DecorFactory.JungleTree(mb, p, rng);
                        else if (r < 0.5) DecorFactory.PalmTree(mb, p, rng);
                        else if (r < 0.75) DecorFactory.BigLeaf(mb, p, rng);
                        else if (r < 0.85) DecorFactory.Bush(mb, p, rng, new Color(0.15f, 0.55f, 0.25f));
                        else DecorFactory.Flower(mb, p, rng);
                        break;
                    case BiomeStyle.Ocean:
                        {
                            bool island = Mathf.Abs(x + 5f) < 12f || Mathf.PerlinNoise(x * 0.04f + 3f, z * 0.04f) > 0.62f;
                            if (island)
                            {
                                if (r < 0.45) DecorFactory.PalmTree(mb, p, rng);
                                else if (r < 0.7) DecorFactory.Rock(mb, p, rng, new Color(0.8f, 0.75f, 0.6f));
                                else DecorFactory.GrassTuft(mb, p, rng, new Color(0.45f, 0.7f, 0.3f));
                            }
                            else
                            {
                                if (r < 0.45) DecorFactory.Coral(mb, p, rng);
                                else if (r < 0.55) DecorFactory.Buoy(mb, p);
                                else if (r < 0.75) DecorFactory.Rock(mb, p - Vector3.up * 0.3f, rng, new Color(0.45f, 0.55f, 0.6f));
                            }
                            break;
                        }
                    case BiomeStyle.Mountains:
                        if (r < 0.4) DecorFactory.PineTree(mb, p, rng, new Color(0.2f, 0.45f, 0.35f), true);
                        else if (r < 0.6) DecorFactory.Rock(mb, p, rng, new Color(0.6f, 0.62f, 0.68f), 1.6f);
                        else if (r < 0.7) DecorFactory.Snowman(mb, p, rng);
                        else if (r < 0.85) DecorFactory.IceCrystal(mb, p, rng);
                        else DecorFactory.Mountain(mb, p, 4f + (float)rng.NextDouble() * 4f, 6f + (float)rng.NextDouble() * 8f, new Color(0.55f, 0.58f, 0.65f), true);
                        break;
                }
                if (mb.VertexCount > 55000) Emit("Decor_" + biome.id + "_part", mb);
            }
        }

        // ------------------------------------------------------------ backdrop and sky

        void BuildBackdrop()
        {
            var mb = new MeshBuilder();
            var rng = new System.Random(5);
            float trackEnd = _db.balance.maxThrowDistance + 40f;
            for (float z = -80f; z < WorldLayout.ThrowOriginZ + trackEnd + 60f; z += 22f)
            {
                var biome = _db.BiomeAtDistance(z - WorldLayout.ThrowOriginZ);
                Color hill = biome != null && z > WorldLayout.ThrowOriginZ ? MeshBuilder.Shade(biome.groundColorAlt, 0.85f) : new Color(0.35f, 0.62f, 0.32f);
                bool snowy = biome != null && biome.style == BiomeStyle.Mountains && z > WorldLayout.ThrowOriginZ + biome.startDistance;
                for (int side = -1; side <= 1; side += 2)
                {
                    float x = side * (WorldLayout.WorldHalfWidth + 15f + (float)rng.NextDouble() * 20f);
                    float h = 18f + (float)rng.NextDouble() * (snowy ? 40f : 18f);
                    DecorFactory.Mountain(mb, new Vector3(x, -1f, z), 22f + (float)rng.NextDouble() * 10f, h, hill, snowy);
                }
            }
            // Big mountains at the end and behind the base
            for (int i = -3; i <= 3; i++)
            {
                DecorFactory.Mountain(mb, new Vector3(i * 30f, -1f, WorldLayout.ThrowOriginZ + trackEnd + 60f), 32f, 55f + (i & 1) * 15f, new Color(0.55f, 0.6f, 0.7f), true);
                DecorFactory.Mountain(mb, new Vector3(i * 30f, -1f, -95f), 30f, 30f + (i & 1) * 10f, new Color(0.35f, 0.6f, 0.35f), false);
            }
            Emit("Backdrop", mb, false);
        }

        void BuildClouds()
        {
            var rng = new System.Random(11);
            var mb = new MeshBuilder();
            float trackEnd = _db.balance.maxThrowDistance + 60f;
            for (int layer = 0; layer < 3; layer++)
            {
                for (int i = 0; i < 14; i++)
                {
                    float z = -60f + (float)rng.NextDouble() * (trackEnd + 120f);
                    float x = (float)rng.NextDouble() * 260f - 130f;
                    DecorFactory.Cloud(mb, new Vector3(x, 40f + layer * 10f + (float)rng.NextDouble() * 8f, z), rng);
                }
                var go = MaterialLibrary.MeshObject("Clouds_" + layer, transform, mb.ToMesh("Clouds"), Vector3.zero, false);
                mb.Clear();
                _clouds.Add(go.transform);
            }
        }

        void Update()
        {
            for (int i = 0; i < _clouds.Count; i++)
            {
                var t = _clouds[i];
                var p = t.localPosition;
                p.x += Time.deltaTime * (0.8f + i * 0.4f);
                if (p.x > 60f) p.x -= 120f;
                t.localPosition = p;
            }
        }
    }
}
