import json, sys, os, math, glob
import numpy as np
from PIL import Image, ImageDraw, ImageFont

def look_at(eye, target, up=(0,1,0)):
    eye, target, up = map(np.array, (eye, target, up))
    f = target - eye; f = f/np.linalg.norm(f)
    r = np.cross(up, f); r = r/np.linalg.norm(r)   # Unity-style left-handed: right = up x forward
    u = np.cross(f, r)
    return eye, r, u, f

def render(tris, size=256, yaw_deg=35, pitch_deg=22, dist_k=2.4):
    a = np.array(tris, dtype=np.float64)
    if len(a) == 0: return Image.new('RGB', (size,size), (40,40,60)), 0, 0
    P = a[:, :9].reshape(-1, 3, 3); C = a[:, 9:12] / 255.0
    mn, mx = P.reshape(-1,3).min(0), P.reshape(-1,3).max(0)
    center = (mn + mx) / 2; radius = np.linalg.norm(mx - mn) / 2 + 1e-3
    yaw, pitch = math.radians(yaw_deg), math.radians(pitch_deg)
    d = radius * dist_k
    eye = center + d * np.array([math.sin(yaw)*math.cos(pitch), math.sin(pitch), math.cos(yaw)*math.cos(pitch)])
    eye, r, u, f = look_at(eye, center)
    light = np.array([0.4, 0.8, 0.5]); light /= np.linalg.norm(light)
    img = np.zeros((size, size, 3)); img[:] = (0.16, 0.2, 0.36)
    zbuf = np.full((size, size), np.inf)
    fov = math.radians(30); scale = size / 2 / math.tan(fov/2)
    back = 0; front = 0
    for tri, col in zip(P, C):
        n = np.cross(tri[1]-tri[0], tri[2]-tri[0])  # Unity left-handed: Cross(b-a, c-a) is the outward normal for CW faces
        nl = np.linalg.norm(n)
        if nl < 1e-12: continue
        n /= nl
        rel = tri - eye
        cam = np.stack([rel @ r, rel @ u, rel @ f], 1)
        if (cam[:,2] <= 0.01).any(): continue
        sx = size/2 + cam[:,0] / cam[:,2] * scale
        sy = size/2 - cam[:,1] / cam[:,2] * scale
        facing = np.dot(n, (tri.mean(0) - eye)) < 0
        if facing:
            shade = 0.45 + 0.55 * max(0.0, float(np.dot(n, light)))
            c = np.clip(col * shade + 0.04, 0, 1); front += 1
        else:
            c = np.array([1.0, 0.0, 1.0]); back += 1
        x0, x1 = int(max(0, math.floor(sx.min()))), int(min(size-1, math.ceil(sx.max())))
        y0, y1 = int(max(0, math.floor(sy.min()))), int(min(size-1, math.ceil(sy.max())))
        if x1 < x0 or y1 < y0: continue
        xs, ys = np.meshgrid(np.arange(x0, x1+1) + 0.5, np.arange(y0, y1+1) + 0.5)
        (ax, ay), (bx, by), (cx, cy) = (sx[0], sy[0]), (sx[1], sy[1]), (sx[2], sy[2])
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-9: continue
        w0 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / den
        w1 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / den
        w2 = 1 - w0 - w1
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        z = w0 * cam[0,2] + w1 * cam[1,2] + w2 * cam[2,2]
        sub = zbuf[y0:y1+1, x0:x1+1]
        m = inside & (z < sub)
        sub[m] = z[m]
        img[y0:y1+1, x0:x1+1][m] = c
    return Image.fromarray((img * 255).astype(np.uint8)), front, back

def sheet(files, out, cols=6, size=220, **kw):
    rows = (len(files) + cols - 1) // cols
    W = Image.new('RGB', (cols*size, rows*(size+22)), (20, 24, 40))
    dr = ImageDraw.Draw(W)
    report = []
    for i, fn in enumerate(files):
        tris = json.load(open(fn))
        im, front, back = render(tris, size, **kw)
        x, y = (i % cols) * size, (i // cols) * (size + 22)
        W.paste(im, (x, y))
        name = os.path.basename(fn)[:-5]
        dr.text((x + 6, y + size + 4), f"{name} {len(tris)}t", fill=(230, 230, 240))
        report.append((name, len(tris), front, back))
    W.save(out)
    return report

d = sys.argv[1]
for prefix, out, kw in [("animal_", "animals.png", {}), ("food_", "foods.png", {}), ("trainer_", "trainers.png", {}), ("prop_", "props.png", {})]:
    files = sorted(glob.glob(os.path.join(d, prefix + "*.json")))
    rep = sheet(files, os.path.join(d, "..", out), **kw)
    bad = [(n, b, f) for n, t, f, b in rep if b > 0]
    print(out, "models:", len(rep), "with back-facing visible tris:", bad[:12])

# icons
icons = sorted(glob.glob(os.path.join(d, "icon_*.txt")))
W = Image.new('RGB', (len(icons) * 100, 120), (40, 50, 90)); dr = ImageDraw.Draw(W)
for i, fn in enumerate(icons):
    s, px = open(fn).read().split(';'); s = int(s)
    a = np.array([int(v) for v in px.split(',')], dtype=np.uint8).reshape(s, s)[::-1]  # Unity textures are bottom-up
    im = Image.fromarray(a, 'L').convert('RGB')
    W.paste(im, (i * 100 + 2, 2))
    dr.text((i * 100 + 4, 100), os.path.basename(fn)[5:-4], fill=(255, 255, 255))
W.save(os.path.join(d, "..", "icons.png"))
print("icons", len(icons))
