# Maison A : maison individuelle à étage, modélisée par script dans Blender (bpy).
# Unités : studs Roblox. Repère Blender : X à droite, Y vers l'arrière, Z vers le haut, façade en -Y.
# Chaque objet porte le nom de sa matière (WALL_EXT, PLASTER, ROOF, TRIM, GLASS, ...) : le script
# Roblox (17_BlenderHouses) applique les matières Roblox d'après ce nom. Les boîtes de collision et
# les points utiles (porte, meubles) partent dans un JSON à côté du modèle.
# Lancement : python house_a.py <dossier_de_sortie> [--render]
import bpy, bmesh, json, math, sys, os
from mathutils import Vector, Matrix

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
RENDER = "--render" in sys.argv
ARGW = [a for a in sys.argv if a.startswith("--w=")]
WIDTH = float(ARGW[0][4:]) if ARGW else 24.0
TAG = "HouseA_%d" % round(WIDTH)

bpy.ops.wm.read_factory_settings(use_empty=True)

MESHES = {}  # matière -> liste de (verts, faces)
COLL = []  # boîtes de collision {c, s}
INFO = {"name": TAG}


def add(mat, verts, faces):
    MESHES.setdefault(mat, []).append((verts, faces))


def box(mat, c, s, coll=False, rot_z=0.0):
    cx, cy, cz = c
    sx, sy, sz = s[0] / 2, s[1] / 2, s[2] / 2
    vs = [(-sx, -sy, -sz), (sx, -sy, -sz), (sx, sy, -sz), (-sx, sy, -sz), (-sx, -sy, sz), (sx, -sy, sz), (sx, sy, sz), (-sx, sy, sz)]
    cr, sr = math.cos(rot_z), math.sin(rot_z)
    vs = [(cx + x * cr - y * sr, cy + x * sr + y * cr, cz + z) for x, y, z in vs]
    fs = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    add(mat, vs, fs)
    if coll:
        COLL.append({"c": [cx, cy, cz], "s": list(s)})


def poly_prism(mat, pts2d, y0, y1):
    """Prisme : polygone dans le plan XZ (x, z), extrudé de y0 à y1."""
    n = len(pts2d)
    vs = [(x, y0, z) for x, z in pts2d] + [(x, y1, z) for x, z in pts2d]
    fs = [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        fs.append((i, j, n + j, n + i))
    add(mat, vs, fs)


def slab(mat, p0, p1, width_axis, thick):
    """Plaque inclinée entre deux arêtes (toit) : p0 bas, p1 haut, largeur le long de width_axis."""
    p0, p1 = Vector(p0), Vector(p1)
    w = Vector(width_axis)
    up = (p1 - p0).cross(w).normalized()
    if up.z < 0:
        up = -up
    a, b = p0 - w / 2, p0 + w / 2
    c, d = p1 + w / 2, p1 - w / 2
    vs = [a, b, c, d, a + up * thick, b + up * thick, c + up * thick, d + up * thick]
    vs = [tuple(v) for v in vs]
    fs = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    add(mat, vs, fs)


def cyl(mat, c, r, h, axis="z", seg=8):
    cx, cy, cz = c
    vs, fs = [], []
    for k in range(seg):
        a = 2 * math.pi * k / seg
        u, v = math.cos(a) * r, math.sin(a) * r
        for t in (-h / 2, h / 2):
            if axis == "z":
                vs.append((cx + u, cy + v, cz + t))
            elif axis == "x":
                vs.append((cx + t, cy + u, cz + v))
            else:
                vs.append((cx + u, cy + t, cz + v))
    for k in range(seg):
        j = (k + 1) % seg
        fs.append((2 * k, 2 * j, 2 * j + 1, 2 * k + 1))
    fs.append(tuple(2 * k for k in range(seg - 1, -1, -1)))
    fs.append(tuple(2 * k + 1 for k in range(seg)))
    add(mat, vs, fs)


# ---------------------------------------------------------------- dimensions
W, D = WIDTH, 18.0
K = W / 24.0  # les positions en X sont dessinées pour 24 studs de large
X0, X1, Y0, Y1 = -W / 2, W / 2, -D / 2, D / 2
F0 = 1.2  # dessus du plancher bas
H = 9.5  # hauteur sous plafond + dalle
SL = 0.6
F1 = F0 + H + SL  # dessus du plancher haut
TOP = F1 + H  # haut des murs
TE, TI = 0.35, 0.45  # épaisseur peau extérieure / intérieure
T = TE + TI
DOOR = {"x": -3.0 * K, "w": 3.6, "h": 7.6}

INFO.update({"W": W, "D": D, "F0": F0, "F1": F1, "TOP": TOP, "door": DOOR})


def wall(axis, fixed, a1, a2, z0, z1, ops, outward, ext="WALL_EXT"):
    """Mur en deux peaux avec ouvertures. axis 'X' : mur le long de X à y=fixed (face ext. vers outward)."""
    ops = sorted(ops, key=lambda o: o["c"])

    def seg(a, b, za, zb):
        if b - a < 0.02 or zb - za < 0.02:
            return
        for mat, off, th in ((ext, T / 2 - TE / 2, TE), ("PLASTER", -(T / 2 - TI / 2), TI)):
            if axis == "X":
                box(mat, ((a + b) / 2, fixed + outward * off, (za + zb) / 2), (b - a, th, zb - za))
            else:
                box(mat, (fixed + outward * off, (a + b) / 2, (za + zb) / 2), (th, b - a, zb - za))
        if axis == "X":
            COLL.append({"c": [(a + b) / 2, fixed, (za + zb) / 2], "s": [b - a, T, zb - za]})
        else:
            COLL.append({"c": [fixed, (a + b) / 2, (za + zb) / 2], "s": [T, b - a, zb - za]})

    cur = a1
    for o in ops:
        a, b = o["c"] - o["w"] / 2, o["c"] + o["w"] / 2
        seg(cur, a, z0, z1)
        seg(a, b, z0, o["b"])
        seg(a, b, o["t"], z1)
        cur = b
        opening(axis, fixed, o, outward)
    seg(cur, a2, z0, z1)


def opening(axis, fixed, o, outward):
    """Encadrement, appui, vitrage et petits-bois d'une fenêtre ; chambranle d'une porte."""
    c, w, b, t = o["c"], o["w"], o["b"], o["t"]
    h = t - b
    face = fixed + outward * (T / 2)

    def at(u, z, off, size):
        sx, sy, sz = size
        if axis == "X":
            box(o.get("mat", "TRIM"), (u, face + outward * off, z), (sx, sy, sz))
        else:
            box(o.get("mat", "TRIM"), (face + outward * off, u, z), (sy, sx, sz))

    def put(mat, u, z, off, size):
        sx, sy, sz = size
        if axis == "X":
            box(mat, (u, face + outward * off, z), (sx, sy, sz))
        else:
            box(mat, (face + outward * off, u, z), (sy, sx, sz))

    tw = 0.35
    if o["kind"] == "window":
        # encadrement en saillie
        put("TRIM", c - w / 2 - tw / 2, (b + t) / 2, 0.08, (tw, 0.16, h))
        put("TRIM", c + w / 2 + tw / 2, (b + t) / 2, 0.08, (tw, 0.16, h))
        put("TRIM", c, t + tw / 2, 0.08, (w + 2 * tw, 0.16, tw))
        put("TRIM", c, t + tw + 0.12, 0.14, (w + 2 * tw + 0.3, 0.28, 0.24))  # linteau
        put("TRIM", c, b - 0.12, 0.2, (w + 2 * tw + 0.3, 0.55, 0.24))  # appui
        # dormant en retrait + vitrage + petits-bois
        put("FRAME", c, (b + t) / 2, -0.35, (w, 0.12, 0.18))
        put("FRAME", c, b + 0.09, -0.3, (w, 0.2, 0.18))
        put("FRAME", c, t - 0.09, -0.3, (w, 0.2, 0.18))
        put("FRAME", c - w / 2 + 0.09, (b + t) / 2, -0.3, (0.18, 0.2, h))
        put("FRAME", c + w / 2 - 0.09, (b + t) / 2, -0.3, (0.18, 0.2, h))
        put("FRAME", c, (b + t) / 2, -0.3, (0.12, 0.16, h))
        put("FRAME", c, b + h * 0.62, -0.3, (w, 0.16, 0.1))
        put("GLASS", c, (b + t) / 2, -0.36, (w - 0.1, 0.06, h - 0.1))
    else:
        # porte : chambranle large + seuil
        put("TRIM", c - w / 2 - 0.25, (b + t) / 2, 0.08, (0.5, 0.18, h + 0.5))
        put("TRIM", c + w / 2 + 0.25, (b + t) / 2, 0.08, (0.5, 0.18, h + 0.5))
        put("TRIM", c, t + 0.3, 0.12, (w + 1.4, 0.26, 0.6))
        put("STONE", c, b - 0.05, -0.2, (w, T + 0.3, 0.1))


# ---------------------------------------------------------------- ouvertures
def win(c, b, w=3.6, h=4.6):
    kk = min(1.0, K)
    return {"kind": "window", "c": c * K * (0.96 if K < 1 else 1.0), "w": w * kk, "b": b, "t": b + h}


gb, ub = F0 + 2.6, F1 + 2.4
front_g = [{"kind": "door", "c": DOOR["x"], "w": DOOR["w"], "b": F0, "t": F0 + DOOR["h"]}, win(-8.6, gb, 4.2), win(4.2, gb, 4.2), win(8.8, gb, 3.2)]
front_u = [win(-8.6, ub, 3.4, 4.2), win(-3.0, ub, 3.0, 4.2), win(4.2, ub, 3.4, 4.2), win(8.8, ub, 3.0, 4.2)]
back_g = [win(-7.0, gb, 4.6), win(1.0, gb, 3.2), win(7.6, gb, 4.2)]
back_u = [win(-7.0, ub, 3.4, 4.2), win(1.0, ub, 2.6, 3.0), win(7.6, ub, 3.4, 4.2)]
side_g = [win(-3.0, gb, 3.2), win(4.0, gb, 3.2)]
side_u = [win(-3.0, ub, 3.0, 4.2), win(4.0, ub, 3.0, 4.2)]

for z0, z1, fr, bk, sd in ((F0, F1, front_g, back_g, side_g), (F1, TOP, front_u, back_u, side_u)):
    wall("X", Y0 + T / 2, X0, X1, z0, z1, [dict(o) for o in fr], -1)
    wall("X", Y1 - T / 2, X0, X1, z0, z1, [dict(o) for o in bk], 1)
    wall("Z", X0 + T / 2, Y0 + T, Y1 - T, z0, z1, [dict(o) for o in sd], -1)
    wall("Z", X1 - T / 2, Y0 + T, Y1 - T, z0, z1, [dict(o) for o in sd], 1)

# soubassement en pierre, bandeau entre étages, planches d'angle
box("STONE", (0, 0, F0 / 2 - 0.05), (W + 0.5, D + 0.5, F0 + 0.1), coll=True)
for y, s in ((Y0 - 0.12, -1), (Y1 + 0.12, 1)):
    box("TRIM", (0, y, F1 + 0.1), (W + 0.4, 0.3, 0.55))
for x, s in ((X0 - 0.12, -1), (X1 + 0.12, 1)):
    box("TRIM", (x, 0, F1 + 0.1), (0.3, D + 0.4, 0.55))
for x in (X0, X1):
    for y in (Y0, Y1):
        box("TRIM", (x + (0.12 if x > 0 else -0.12) * 0.5, y + (0.12 if y > 0 else -0.12) * 0.5, (F0 + TOP) / 2), (0.6, 0.6, TOP - F0))

# planchers / plafonds
box("FLOOR", (0, 0, F0 + 0.05), (W - 2 * T, D - 2 * T, 0.1))
STAIR = {"x0": X0 + T, "x1": X0 + T + 3.4, "y0": -2.2, "steps": 12}
run = 0.85
hole_y0 = STAIR["y0"] + 2.2
hole = (STAIR["x0"], STAIR["x1"] + 0.1, hole_y0, Y1 - T)
# dalle haute découpée par la trémie
def slab_with_hole(z, th, mat_top, mat_bot):
    xi0, xi1, yi0, yi1 = X0 + T, X1 - T, Y0 + T, Y1 - T
    hx0, hx1, hy0, hy1 = hole
    parts = [(hx1, xi1, yi0, yi1), (xi0, hx1, yi0, hy0)]
    for a, b, c, d in parts:
        box(mat_bot, ((a + b) / 2, (c + d) / 2, z + 0.05), (b - a, d - c, 0.1))
        box("SLAB", ((a + b) / 2, (c + d) / 2, z + th / 2), (b - a, d - c, th - 0.2), coll=False)
        COLL.append({"c": [(a + b) / 2, (c + d) / 2, z + th / 2], "s": [b - a, d - c, th]})
        box(mat_top, ((a + b) / 2, (c + d) / 2, z + th - 0.05), (b - a, d - c, 0.1))
slab_with_hole(F1 - SL, SL, "FLOOR", "CEILING")
box("CEILING", (0, 0, TOP - 0.05), (W - 2 * T, D - 2 * T, 0.1))
COLL.append({"c": [0, 0, TOP + 0.2], "s": [W, D, 0.4]})

# escalier droit le long du mur gauche, montant vers l'arrière
rise = (F1 - F0) / STAIR["steps"]
for k in range(STAIR["steps"]):
    z = F0 + rise * (k + 1)
    y = STAIR["y0"] + run * k + run / 2
    box("STAIRS", ((STAIR["x0"] + STAIR["x1"]) / 2, y, z - rise / 2), (STAIR["x1"] - STAIR["x0"], run, rise), coll=True)
# garde-corps autour de la trémie (côté pièce)
gx = STAIR["x1"] + 0.05
for k in range(10):
    yy = hole_y0 + 0.4 + k * (Y1 - T - hole_y0 - 0.8) / 9
    box("FRAME", (gx, yy, F1 + 1.6), (0.12, 0.12, 3.2))
box("STAIRS", (gx, (hole_y0 + Y1 - T) / 2, F1 + 3.25), (0.3, Y1 - T - hole_y0, 0.2))
COLL.append({"c": [gx, (hole_y0 + Y1 - T) / 2, F1 + 1.7], "s": [0.3, Y1 - T - hole_y0, 3.4]})

# cloisons intérieures avec passages
def partition(axis, fixed, a1, a2, z0, z1, gaps):
    cur = a1
    for g0, g1 in sorted(gaps):
        for a, b, za, zb in ((cur, g0, z0, z1), (g0, g1, z0 + 7.8, z1)):
            if b - a > 0.05 and zb - za > 0.05:
                if axis == "X":
                    box("PLASTER", ((a + b) / 2, fixed, (za + zb) / 2), (b - a, 0.4, zb - za), coll=True)
                else:
                    box("PLASTER", (fixed, (a + b) / 2, (za + zb) / 2), (0.4, b - a, zb - za), coll=True)
        cur = g1
    if a2 - cur > 0.05:
        if axis == "X":
            box("PLASTER", ((cur + a2) / 2, fixed, (z0 + z1) / 2), (a2 - cur, 0.4, z1 - z0), coll=True)
        else:
            box("PLASTER", (fixed, (cur + a2) / 2, (z0 + z1) / 2), (0.4, a2 - cur, z1 - z0), coll=True)

PX = 2.4 * K
partition("Z", PX, Y0 + T, Y1 - T, F0, F1 - SL, [(-2.2, 1.6)])
partition("Z", PX, Y0 + T, Y1 - T, F1, TOP, [(-1.2, 2.6)])
partition("X", 1.2, PX, X1 - T, F1, TOP, [(6.0 * K, 9.2 * K)])

# ---------------------------------------------------------------- porche
px, pw, pd = DOOR["x"], 7.4, 4.6
pz = F0 - 0.05
box("CONCRETE", (px, Y0 - pd / 2, pz / 2), (pw, pd, pz), coll=True)
box("CONCRETE", (px, Y0 - pd - 0.6, pz / 3), (pw - 1.2, 1.2, pz * 2 / 3), coll=True)
for sx in (-1, 1):
    cx = px + sx * (pw / 2 - 0.4)
    box("TRIM", (cx, Y0 - pd + 0.4, pz + 0.25), (0.8, 0.8, 0.5))
    box("TRIM", (cx, Y0 - pd + 0.4, (pz + 9.6) / 2), (0.5, 0.5, 9.6 - pz))
    box("TRIM", (cx, Y0 - pd + 0.4, 9.45), (0.75, 0.75, 0.3))
ph, prise = 9.6, 2.6
box("TRIM", (px, Y0 - pd + 0.4, ph + 0.25), (pw, 0.5, 0.5))
for sx in (-1, 1):
    slab("ROOF", (px + sx * (pw / 2 + 0.5), Y0 - pd - 0.3, ph + 0.45), (px, Y0 - pd - 0.3, ph + 0.45 + prise), (0, pd + 0.3 + 0.2, 0), 0.3)
poly_prism("TRIM", [(px - pw / 2, ph + 0.45), (px + pw / 2, ph + 0.45), (px, ph + 0.45 + prise - 0.15)], Y0 - pd + 0.1, Y0 - pd + 0.3)
poly_prism("WALL_EXT", [(px - pw / 2 + 0.3, ph + 0.5), (px + pw / 2 - 0.3, ph + 0.5), (px, ph + 0.4 + prise - 0.4)], Y0 - pd + 0.3, Y0)
box("CEILING", (px, Y0 - pd / 2, ph + 0.4), (pw - 0.2, pd, 0.1))

# ---------------------------------------------------------------- toit à deux pans (faîtage le long de X)
OV, RAKE, RISE, RT = 1.3, 0.9, 7.2, 0.45
half = D / 2 + OV
slope = RISE / (D / 2)
zeave = TOP - OV * slope
for s in (-1, 1):
    slab("ROOF", (0, s * half, zeave), (0, 0, TOP + RISE), (W + 2 * RAKE, 0, 0), RT)
    # bordure de rive (fascia) et gouttière
    box("TRIM", (0, s * (half + 0.05), zeave - 0.15), (W + 2 * RAKE + 0.1, 0.25, 0.75))
    cyl("GUTTER", (0, s * (half + 0.35), zeave - 0.25), 0.3, W + 2 * RAKE, axis="x")
    for x in (X0 + 0.6, X1 - 0.6):
        cyl("GUTTER", (x, s * (D / 2 + 0.35), (zeave + F0) / 2 - 0.3), 0.18, zeave - F0 - 0.4, axis="z")
    # sous-face du débord
    box("CEILING", (0, s * (D / 2 + OV / 2), zeave + 0.15), (W + 2 * RAKE, OV, 0.1))
# pignons dans la matière du mur + planches de rive inclinées
for s in (-1, 1):
    x = s * (W / 2 - TE / 2)
    pts = [(-D / 2, TOP), (D / 2, TOP), (0, TOP + RISE - 0.1)]
    vs = [(x - TE / 2, y, z) for y, z in pts] + [(x + TE / 2, y, z) for y, z in pts]
    add("WALL_EXT", vs, [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)])
    vs = [(x - s * 0.3 - TI / 2 * 0, y * 0.97, z - 0.05) for y, z in pts]
    for side in (-1, 1):
        p0 = Vector((s * (W / 2 + RAKE), side * half, zeave))
        p1 = Vector((s * (W / 2 + RAKE), 0, TOP + RISE))
        mid, dvec = (p0 + p1) / 2, p1 - p0
        L = dvec.length
        ang = math.atan2(dvec.z, abs(dvec.y))
        bm_v = []
        # planche : boîte orientée le long de dvec
        u = dvec.normalized()
        n = Vector((1, 0, 0))
        up = n.cross(u).normalized()
        if up.z < 0:
            up = -up
        hw, ht = 0.12, 0.4
        corners = []
        for a in (-L / 2, L / 2):
            for bx in (-hw, hw):
                for bz in (-ht, ht):
                    corners.append(tuple(mid + u * a + n * bx + up * bz))
        add("TRIM", corners, [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)])
# faîtière
box("ROOFCAP", (0, 0, TOP + RISE + RT * 0.6), (W + 2 * RAKE, 0.9, 0.3))
# cheminée en brique
chx, chy = 7.5 * K, 2.0
box("BRICK", (chx, chy, (TOP + TOP + RISE + 3.2) / 2 - 1), (2.4, 2.0, RISE + 5.2))
box("CONCRETE", (chx, chy, TOP + RISE + 2.7), (2.8, 2.4, 0.35))
cyl("GUTTER", (chx, chy, TOP + RISE + 3.2), 0.35, 0.8)

# ---------------------------------------------------------------- porte (objet séparé, pivote dans Roblox)
dx, dw, dh = DOOR["x"], DOOR["w"] - 0.1, DOOR["h"] - 0.05
dyc = Y0 + T / 2 - 0.05
box("DOOR", (dx, dyc, F0 + dh / 2), (dw, 0.22, dh))
# panneaux moulurés + vitre haute (même objet porte)
for zz in (F0 + 1.6, F0 + 4.1):
    for sx in (-1, 1):
        box("DOOR", (dx + sx * dw / 4.2, dyc - 0.14, zz), (dw / 2.8, 0.06, 1.9))
box("DOOR_GLASS", (dx, dyc - 0.12, F0 + 6.2), (dw * 0.6, 0.05, 1.3))
INFO["doorBox"] = {"c": [dx, dyc, F0 + dh / 2], "s": [dw, 0.22, dh]}

# meubles (Meshy dans Roblox) : nom, position, orientation (vers où regarde la face avant)
INFO["furniture"] = [
    {"n": "Sofa", "p": [-6.5 * K, 6.0, F0], "f": [0, -1, 0], "h": 2.8},
    {"n": "TV", "p": [-6.5 * K, -4.6, F0], "f": [0, 1, 0], "h": 3.6},
    {"n": "Plant", "p": [-10.6 * K, -7.6, F0], "f": [1, 0, 0], "h": 3.6},
    {"n": "Kitchen", "p": [7.5 * K, 7.7, F0], "f": [0, -1, 0], "h": 3.8},
    {"n": "Fridge", "p": [10.5 * K, 4.0, F0], "f": [-1, 0, 0], "h": 6.6},
    {"n": "Dining", "p": [7.0 * K, -2.0, F0], "f": [0, 1, 0], "h": 3.2},
    {"n": "Bed", "p": [7.5 * K, 5.2, F1], "f": [0, -1, 0], "h": 3.0},
    {"n": "Wardrobe", "p": [10.6 * K, -1.0, F1], "f": [-1, 0, 0], "h": 7.2},
    {"n": "Desk", "p": [6.0 * K, -7.4, F1], "f": [0, 1, 0], "h": 3.4},
    {"n": "Bathroom", "p": [-3.5 * K, 7.4, F1], "f": [0, -1, 0], "h": 4.0},
    {"n": "Bookshelf", "p": [-1.2 * K, -7.6, F1], "f": [0, 1, 0], "h": 6.4},
]
INFO["lights"] = [[-5, 0, F1 - SL - 0.2], [7, 0, F1 - SL - 0.2], [-2, 0, TOP - 0.2], [7, -4, TOP - 0.2]]


# ---------------------------------------------------------------- construction des objets Blender
def build_objects():
    objs = []
    for mat, items in MESHES.items():
        bm = bmesh.new()
        uvl = bm.loops.layers.uv.new("UVMap")
        for verts, faces in items:
            vmap = [bm.verts.new(v) for v in verts]
            for f in faces:
                try:
                    bm.faces.new([vmap[i] for i in f])
                except ValueError:
                    pass
        bm.normal_update()
        # UV en projection cubique à l'échelle du monde (1 unité UV = 8 studs)
        for f in bm.faces:
            n = f.normal
            ax = max(range(3), key=lambda i: abs(n[i]))
            for loop in f.loops:
                co = loop.vert.co
                if ax == 0:
                    uv = (co.y, co.z)
                elif ax == 1:
                    uv = (co.x, co.z)
                else:
                    uv = (co.x, co.y)
                loop[uvl].uv = (uv[0] / 8.0, uv[1] / 8.0)
        me = bpy.data.meshes.new(mat)
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new(mat, me)
        bpy.context.scene.collection.objects.link(ob)
        m = bpy.data.materials.get(mat) or bpy.data.materials.new(mat)
        m.use_nodes = True
        COLORS = {
            "WALL_EXT": (0.82, 0.78, 0.68), "PLASTER": (0.92, 0.9, 0.86), "ROOF": (0.18, 0.18, 0.2), "TRIM": (0.95, 0.95, 0.93),
            "GLASS": (0.35, 0.45, 0.5), "FRAME": (0.95, 0.95, 0.95), "DOOR": (0.1, 0.16, 0.3), "DOOR_GLASS": (0.4, 0.5, 0.55),
            "FLOOR": (0.55, 0.38, 0.24), "CEILING": (0.96, 0.95, 0.92), "STAIRS": (0.45, 0.3, 0.2), "GUTTER": (0.9, 0.9, 0.9),
            "STONE": (0.45, 0.43, 0.4), "CONCRETE": (0.7, 0.7, 0.68), "BRICK": (0.5, 0.25, 0.18), "ROOFCAP": (0.15, 0.15, 0.16), "SLAB": (0.6, 0.6, 0.6),
        }
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        col = COLORS.get(mat, (0.8, 0.8, 0.8))
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (*col, 1)
            if mat in ("GLASS", "DOOR_GLASS"):
                bsdf.inputs["Alpha"].default_value = 0.45
        ob.data.materials.append(m)
        objs.append(ob)
    return objs


objs = build_objects()
tris = sum(len(o.data.polygons) for o in objs)
INFO["collision"] = COLL
INFO["faces"] = tris
os.makedirs(OUT, exist_ok=True)
with open(os.path.join(OUT, TAG + ".json"), "w") as f:
    json.dump(INFO, f, separators=(",", ":"))
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, TAG + ".glb"), export_format="GLB", export_apply=True, export_yup=True)
print("faces", tris, "objects", len(objs), "coll", len(COLL))

if RENDER:
    scn = bpy.context.scene
    scn.render.engine = "CYCLES"
    scn.cycles.samples = 24
    scn.cycles.device = "CPU"
    scn.render.resolution_x, scn.render.resolution_y = 900, 600
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.6, 0.75, 0.95, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    scn.world = world
    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 4
    so = bpy.data.objects.new("sun", sun)
    so.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
    scn.collection.objects.link(so)
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, 0))
    g = bpy.context.active_object
    gm = bpy.data.materials.new("ground")
    gm.use_nodes = True
    gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.25, 0.35, 0.18, 1)
    g.data.materials.append(gm)
    cam = bpy.data.cameras.new("cam")
    cam.lens = 28
    co = bpy.data.objects.new("cam", cam)
    scn.collection.objects.link(co)
    scn.camera = co
    for name, loc in (("front", (22, -42, 14)), ("back", (-26, 38, 16))):
        co.location = loc
        d = Vector((0, 0, 9)) - Vector(loc)
        co.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        scn.render.filepath = os.path.join(OUT, f"{TAG}_{name}.png")
        bpy.ops.render.render(write_still=True)
