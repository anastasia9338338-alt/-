using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using UnityEngine;
using ZooThrow.Animals;
using ZooThrow.Data;
using ZooThrow.Throwing;
using ZooThrow.UI;
using ZooThrow.Visuals;
using ZooThrow.World;

static class Program
{
    static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

    static void AppendMesh(StringBuilder sb, Mesh m, Func<Vector3, Vector3> xf)
    {
        for (int i = 0; i < m.T.Count; i += 3)
        {
            sb.Append('[');
            for (int k = 0; k < 3; k++)
            {
                var v = xf(m.V[m.T[i + k]]);
                sb.Append(string.Format(Inv, "{0:0.###},{1:0.###},{2:0.###},", v.x, v.y, v.z));
            }
            var c = m.C[m.T[i]];
            sb.Append(c.r).Append(',').Append(c.g).Append(',').Append(c.b).Append("],");
        }
    }

    static void Write(string dir, string name, StringBuilder tris)
    {
        if (tris.Length > 0 && tris[tris.Length - 1] == ',') tris.Length--;
        File.WriteAllText(Path.Combine(dir, name + ".json"), "[" + tris + "]");
    }

    static void Main(string[] args)
    {
        string outDir = args[0];
        Directory.CreateDirectory(outDir);
        var db = DefaultContent.Create();
        foreach (var a in db.animals)
        {
            var model = AnimalModelFactory.Get(a);
            var sb = new StringBuilder();
            AppendMesh(sb, model.body, v => v);
            foreach (var limb in model.limbs)
            {
                float sx = limb.kind == LimbKind.Wing && limb.side < 0 ? -1f : 1f;
                // Wings spread slightly for the preview, legs at rest.
                var rot = limb.kind == LimbKind.Wing ? Quaternion.Euler(0, 0, 10f * limb.side) : Quaternion.identity;
                var l = limb;
                AppendMesh(sb, l.mesh, v => l.pivot + rot * new Vector3(v.x * sx, v.y, v.z));
            }
            Write(outDir, "animal_" + a.id, sb);
        }
        foreach (var f in db.baits) { var sb = new StringBuilder(); AppendMesh(sb, BaitModelFactory.Get(f), v => v); Write(outDir, "bait_" + f.id, sb); }
        foreach (var r in db.rods) { var sb = new StringBuilder(); AppendMesh(sb, RodModelFactory.Get(r), v => Quaternion.Euler(50f, 0, 0) * v); Write(outDir, "rod_" + r.id, sb); }
        foreach (var t in db.trainers) { var sb = new StringBuilder(); AppendMesh(sb, TrainerModelFactory.Get(t), v => v); Write(outDir, "trainer_" + t.id, sb); }

        var rng = new System.Random(3);
        var props = new (string, Action<MeshBuilder>)[]
        {
            ("round_tree", mb => DecorFactory.RoundTree(mb, Vector3.zero, rng, new Color(0.25f, 0.62f, 0.28f))),
            ("pine_snow", mb => DecorFactory.PineTree(mb, Vector3.zero, rng, new Color(0.2f, 0.45f, 0.35f), true)),
            ("acacia", mb => DecorFactory.AcaciaTree(mb, Vector3.zero, rng)),
            ("cactus", mb => DecorFactory.Cactus(mb, Vector3.zero, rng)),
            ("palm", mb => DecorFactory.PalmTree(mb, Vector3.zero, rng)),
            ("jungle_tree", mb => DecorFactory.JungleTree(mb, Vector3.zero, rng)),
            ("snowman", mb => DecorFactory.Snowman(mb, Vector3.zero, rng)),
            ("ice", mb => DecorFactory.IceCrystal(mb, Vector3.zero, rng)),
            ("coral", mb => DecorFactory.Coral(mb, Vector3.zero, rng)),
            ("mushroom", mb => DecorFactory.Mushroom(mb, Vector3.zero, rng)),
            ("bush", mb => DecorFactory.Bush(mb, Vector3.zero, rng, new Color(0.3f, 0.66f, 0.3f))),
            ("termite", mb => DecorFactory.TermiteMound(mb, Vector3.zero, rng)),
            ("fence", mb => DecorFactory.Fence(mb, new Vector3(-3, 0, 0), new Vector3(3, 0, 0), new Color(0.66f, 0.45f, 0.27f))),
            ("buoy", mb => DecorFactory.Buoy(mb, Vector3.zero)),
            ("pyramid", mb => DecorFactory.Pyramid(mb, Vector3.zero, 4f)),
            ("cloud", mb => DecorFactory.Cloud(mb, Vector3.zero, rng)),
            ("reeds", mb => DecorFactory.Reeds(mb, Vector3.zero, rng, new Color(0.45f, 0.65f, 0.3f))),
            ("lily", mb => DecorFactory.LilyPad(mb, Vector3.zero, new System.Random(5))),
            ("dead_tree", mb => DecorFactory.DeadTree(mb, Vector3.zero, rng, new Color(0.35f, 0.3f, 0.22f))),
            ("glow_crystal", mb => DecorFactory.GlowCrystal(mb, Vector3.zero, rng, new Color(0.7f, 0.3f, 1f))),
            ("column", mb => DecorFactory.Column(mb, Vector3.zero, rng, new Color(0.92f, 0.9f, 0.84f))),
        };
        foreach (var (name, build) in props)
        {
            var mb = new MeshBuilder();
            build(mb);
            var sb = new StringBuilder();
            AppendMesh(sb, mb.ToMesh(name), v => v);
            Write(outDir, "prop_" + name, sb);
        }

        foreach (IconId id in Enum.GetValues(typeof(IconId)))
        {
            var sp = SpriteFactory.Icon(id);
            var t = sp.texture;
            var sb = new StringBuilder();
            sb.Append(t.width).Append(';');
            foreach (var p in t.px) sb.Append(p.a).Append(',');
            File.WriteAllText(Path.Combine(outDir, "icon_" + id + ".txt"), sb.ToString().TrimEnd(','));
        }
        var rounded = SpriteFactory.Rounded(22).texture;
        Console.WriteLine("rounded sprite " + rounded.width + " ok; animals " + db.animals.Count);
    }
}
