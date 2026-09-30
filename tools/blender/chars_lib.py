"""Humanoid character construction for Last Terminus.

Body  : Blender Skin modifier over a joint graph -> subdivided organic mesh,
        materials assigned per body zone (shirt / pants / skin / shoes).
Head  : sculpted UV sphere + eyes, lids, brows, nose, ears, lips, mouth cavity,
        teeth, tongue and a hair style.
Rig   : one shared skeleton (Hips..Toes, arms with Fingers/Thumb, facial
        bones Jaw / Eye / LidU / Brow / MouthC).
Weights: computed from bone-segment distances with smoothing, top-4 per vertex.
All characters share bone names so a single animation set retargets to them.
"""
import math, sys, os, random
import bpy, bmesh
from mathutils import Vector, Matrix, Euler, Quaternion

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lt_lib as L

STD_H = 1.78

# name, parent, head, tail   (standard 1.78 m body, A-pose, facing +Y, T = +X is character-left)
def bone_table(sx=1.0):
    B = [
        ("Hips", None, (0, 0, 0.93), (0, 0, 1.02)),
        ("Spine", "Hips", (0, 0, 1.02), (0, 0, 1.20)),
        ("Chest", "Spine", (0, 0, 1.20), (0, 0, 1.48)),
        ("Neck", "Chest", (0, 0, 1.48), (0, 0.01, 1.57)),
        ("Head", "Neck", (0, 0.01, 1.57), (0, 0.01, 1.79)),
        ("Jaw", "Head", (0, 0.01, 1.63), (0, 0.10, 1.59)),
    ]
    for s, side in ((1, "R"), (-1, "L")):
        B += [
            ("Eye." + side, "Head", (0.031 * s, 0.098, 1.666), (0.031 * s, 0.13, 1.666)),
            ("LidU." + side, "Head", (0.031 * s, 0.098, 1.666), (0.031 * s, 0.13, 1.69)),
            ("Brow." + side, "Head", (0.033 * s, 0.10, 1.705), (0.033 * s, 0.12, 1.705)),
            ("MouthC." + side, "Head", (0.022 * s, 0.096, 1.589), (0.03 * s, 0.10, 1.589)),
            ("Shoulder." + side, "Chest", (0.05 * s, 0, 1.44), (0.19 * s, 0, 1.45)),
            ("UpperArm." + side, "Shoulder." + side, (0.19 * s, 0, 1.45), (0.34 * s, 0, 1.17)),
            ("LowerArm." + side, "UpperArm." + side, (0.34 * s, 0, 1.17), (0.43 * s, 0.02, 0.92)),
            ("Hand." + side, "LowerArm." + side, (0.43 * s, 0.02, 0.92), (0.47 * s, 0.03, 0.84)),
            ("Fingers." + side, "Hand." + side, (0.47 * s, 0.03, 0.84), (0.495 * s, 0.035, 0.75)),
            ("Thumb." + side, "Hand." + side, (0.455 * s, 0.05, 0.88), (0.475 * s, 0.09, 0.83)),
            ("UpperLeg." + side, "Hips", (0.09 * s, 0, 0.94), (0.09 * s, 0, 0.50)),
            ("LowerLeg." + side, "UpperLeg." + side, (0.09 * s, 0, 0.50), (0.09 * s, 0, 0.09)),
            ("Foot." + side, "LowerLeg." + side, (0.09 * s, 0, 0.09), (0.09 * s, 0.15, 0.04)),
            ("Toes." + side, "Foot." + side, (0.09 * s, 0.15, 0.04), (0.09 * s, 0.25, 0.03)),
        ]
    return B


BODY_BONES = ["Hips", "Spine", "Chest", "Neck", "Shoulder.L", "Shoulder.R", "UpperArm.L", "UpperArm.R", "LowerArm.L", "LowerArm.R",
              "Hand.L", "Hand.R", "Fingers.L", "Fingers.R", "Thumb.L", "Thumb.R", "UpperLeg.L", "UpperLeg.R", "LowerLeg.L", "LowerLeg.R",
              "Foot.L", "Foot.R", "Toes.L", "Toes.R", "Head"]
ANIM_BONES = ["Hips", "Spine", "Chest", "Neck", "Head", "Shoulder.L", "Shoulder.R", "UpperArm.L", "UpperArm.R", "LowerArm.L", "LowerArm.R",
              "Hand.L", "Hand.R", "Fingers.L", "Fingers.R", "Thumb.L", "Thumb.R", "UpperLeg.L", "UpperLeg.R", "LowerLeg.L", "LowerLeg.R",
              "Foot.L", "Foot.R", "Toes.L", "Toes.R"]


class Rig:
    def __init__(self, height=1.78, width=1.0, name="Armature"):
        self.k = height / STD_H
        self.w = width
        self.name = name
        self.bones = {}   # name -> (head Vector, tail Vector, parent)
        for (n, par, h, t) in bone_table():
            hv = Vector((h[0] * self.k * width, h[1] * self.k, h[2] * self.k))
            tv = Vector((t[0] * self.k * width, t[1] * self.k, t[2] * self.k))
            self.bones[n] = (hv, tv, par)

    def build_armature(self):
        arm = bpy.data.armatures.new(self.name)
        obj = bpy.data.objects.new(self.name, arm)
        bpy.context.scene.collection.objects.link(obj)
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        eb = {}
        for n, (h, t, par) in self.bones.items():
            b = arm.edit_bones.new(n)
            b.head = h
            b.tail = t
            b.roll = 0.0
            eb[n] = b
        for n, (h, t, par) in self.bones.items():
            if par:
                eb[n].parent = eb[par]
        bpy.ops.object.mode_set(mode="OBJECT")
        self.obj = obj
        return obj


# ------------------------------------------------------------------------------------------------
# weights
# ------------------------------------------------------------------------------------------------
def seg_dist(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length, t


def distance_weights(rig, p, candidates, power=3.0, limit=4):
    ws = {}
    for n in candidates:
        h, t, _ = rig.bones[n]
        d, _t = seg_dist(p, h, t)
        ws[n] = 1.0 / (d + 0.012) ** power
    top = sorted(ws.items(), key=lambda kv: -kv[1])[:limit]
    tot = sum(w for _, w in top)
    return {n: w / tot for n, w in top}


def smooth_weights(bm, weights, vlist, iterations=3, mix=0.5):
    """Laplacian smoothing of per-vertex weight dicts, restricted to vlist indices."""
    idxset = set(vlist)
    for _ in range(iterations):
        new = {}
        for i in vlist:
            v = bm.verts[i]
            nbrs = [e.other_vert(v).index for e in v.link_edges if e.other_vert(v).index in idxset]
            if not nbrs:
                new[i] = weights[i]
                continue
            acc = {}
            for n, w in weights[i].items():
                acc[n] = acc.get(n, 0.0) + w * (1 - mix)
            for j in nbrs:
                for n, w in weights[j].items():
                    acc[n] = acc.get(n, 0.0) + w * mix / len(nbrs)
            top = sorted(acc.items(), key=lambda kv: -kv[1])[:4]
            tot = sum(w for _, w in top)
            new[i] = {n: w / tot for n, w in top}
        weights.update(new)


# ------------------------------------------------------------------------------------------------
# body from Skin modifier
# ------------------------------------------------------------------------------------------------
def skin_body(rig, build=1.0, belly=0.0, shoulders=1.0):
    """Returns an evaluated Mesh (with modifiers applied) of the body from the neck down."""
    k, w = rig.k, rig.w
    J = {}
    def hp(n): return rig.bones[n][0]
    def tp(n): return rig.bones[n][1]
    verts, radii, edges = [], [], []
    RS = 1.32   # Subsurf shrinks the skin cross-section; compensate
    def add(name, pos, rx, ry):
        J[name] = len(verts)
        verts.append(pos)
        radii.append((rx * build * k * w * RS, ry * build * k * RS))
    add("pelvis", hp("Hips") + Vector((0, 0, 0.0)), 0.145, 0.10)
    add("abdomen", hp("Spine") + Vector((0, 0.01, 0.06)), 0.13 + belly * 0.03, 0.105 + belly * 0.05)
    add("chest", hp("Chest") + Vector((0, 0.0, 0.12)), 0.165 * shoulders, 0.113)
    add("neck", hp("Neck") + Vector((0, 0.005, 0.03)), 0.043, 0.045)
    add("neck_top", tp("Neck") + Vector((0, 0.0, 0.075 * k)), 0.042, 0.044)
    edges += [(J["pelvis"], J["abdomen"]), (J["abdomen"], J["chest"]), (J["chest"], J["neck"]), (J["neck"], J["neck_top"])]
    for side in ("L", "R"):
        s = 1 if side == "R" else -1
        add("sh_" + side, hp("UpperArm." + side) + Vector((-0.03 * s * k * w, 0, 0)), 0.055, 0.058)
        add("el_" + side, hp("LowerArm." + side), 0.042, 0.044)
        add("wr_" + side, hp("Hand." + side), 0.030, 0.027)
        add("hd_" + side, hp("Fingers." + side) + Vector((0, 0, 0.02)), 0.04, 0.02)
        add("hip_" + side, hp("UpperLeg." + side) + Vector((0, 0, -0.03)), 0.083, 0.088)
        add("kn_" + side, hp("LowerLeg." + side), 0.058, 0.058)
        add("an_" + side, hp("Foot." + side) + Vector((0, 0, 0.0)), 0.04, 0.042)
        add("ft_" + side, tp("Foot." + side) + Vector((0, 0.0, 0.01)), 0.043, 0.032)
        add("tp_" + side, tp("Toes." + side) + Vector((0, 0.0, 0.015)), 0.04, 0.025)
        edges += [(J["chest"], J["sh_" + side]), (J["sh_" + side], J["el_" + side]), (J["el_" + side], J["wr_" + side]), (J["wr_" + side], J["hd_" + side]),
                  (J["pelvis"], J["hip_" + side]), (J["hip_" + side], J["kn_" + side]), (J["kn_" + side], J["an_" + side]),
                  (J["an_" + side], J["ft_" + side]), (J["ft_" + side], J["tp_" + side])]
    me = bpy.data.meshes.new("skin_ctrl")
    me.from_pydata([tuple(v) for v in verts], edges, [])
    ob = bpy.data.objects.new("skin_ctrl", me)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    sk = ob.modifiers.new("Skin", "SKIN")
    sk.use_smooth_shade = True
    sk.branch_smoothing = 0.6
    for i, (rx, ry) in enumerate(radii):
        me.skin_vertices[0].data[i].radius = (rx, ry)
    me.skin_vertices[0].data[J["pelvis"]].use_root = True
    ss = ob.modifiers.new("Sub", "SUBSURF")
    ss.levels = 2
    ss.render_levels = 2
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    out = bpy.data.meshes.new_from_object(ev)
    bpy.data.objects.remove(ob)
    bpy.data.meshes.remove(me)
    return out


# ------------------------------------------------------------------------------------------------
# head
# ------------------------------------------------------------------------------------------------
def head_center(rig):
    return Vector((0.0, 0.02 * rig.k, 1.655 * rig.k))


class HeadSurface:
    """Ray-casts the sculpted head so face features sit exactly on the skin."""

    def __init__(self, rig, head_verts):
        from mathutils.bvhtree import BVHTree
        self.k = rig.k
        idx = {v: i for i, v in enumerate(head_verts)}
        faces = set()
        for v in head_verts:
            faces.update(v.link_faces)
        polys = [[idx[v] for v in f.verts] for f in faces]
        self.tree = BVHTree.FromPolygons([tuple(v.co) for v in head_verts], polys)

    def y(self, x, z):
        """Front surface y for unscaled-space (x, z); returns metres in rig space."""
        hit = self.tree.ray_cast(Vector((x * self.k, 1.0, z * self.k)), Vector((0, -1, 0)))
        if hit[0] is None:
            return 0.09 * self.k
        return hit[0].y

    def pt(self, x, z, off=0.0):
        return Vector((x * self.k, self.y(x, z) + off * self.k, z * self.k))


def sculpt_head(rig, p, part_skin, face_w=1.0, jaw_w=1.0, cranium=1.0, chin=1.0):
    k = rig.k
    c = head_center(rig)
    res = bmesh.ops.create_uvsphere(p.bm, u_segments=28, v_segments=18, radius=1.0)
    verts = res["verts"]
    for v in verts:
        x, y, z = v.co
        X, Y, Z = 0.077 * face_w, 0.095, 0.118 * cranium
        if z < 0:
            t = min(1.0, -z)
            x *= 1.0 - 0.22 * (t ** 1.3) / jaw_w
            if y > 0:
                y *= 1.0 - 0.10 * t
            if -0.95 < z < -0.55 and y > 0:
                y += 0.04 * chin * (1.0 - abs(x) * 1.2)
        if y > 0.35:
            y *= 0.93
        if -0.45 < z < 0.05 and y > 0 and abs(x) > 0.35:
            x *= 1.07
        if 0.15 < z < 0.5 and y > 0.5:
            y += 0.05
        v.co = Vector((x * X, y * Y, z * Z)) * k + c
    idx = p._slot(part_skin)
    fs = set()
    for v in verts:
        fs.update(v.link_faces)
    for f in fs:
        f.material_index = idx
        f.smooth = True
    return verts


def add_face(rig, p, style, hs):
    """Eyes, lids, brows, nose, ears, mouth placed on the head surface."""
    k = rig.k
    parts = {}
    skin = style.get("skin", "Skin")
    eye_mat = style.get("iris", "EyeIris")
    ex, ez = 0.031, 1.666
    for s, side in ((1, "R"), (-1, "L")):
        ec = hs.pt(ex * s, ez, -0.0035)
        parts["eye." + side] = p.sph(0.0135 * k, ec, "EyeWhite", seg=12)
        parts["iris." + side] = p.sph(0.0078 * k, ec + Vector((0, 0.0104 * k, 0)), eye_mat, seg=10, scale=(1, 0.32, 1))
        parts["pupil." + side] = p.sph(0.0039 * k, ec + Vector((0, 0.0124 * k, 0)), "EyeDark", seg=6, scale=(1, 0.3, 1))
        lid = p.sph(0.0147 * k, ec, skin, seg=14)
        bmesh.ops.delete(p.bm, geom=[v for v in lid if v.is_valid and (v.co.z - ec.z) < 0.0035 * k], context="VERTS")
        parts["lid." + side] = [v for v in lid if v.is_valid]
        bt = style.get("brow_t", 1.0)
        parts["brow." + side] = p.box((0.033 * k, 0.010 * k, 0.0085 * k * bt), hs.pt(0.033 * s, 1.703 + style.get("brow_y", 0.0), 0.0015),
                                      style.get("hair", "HairBrown"), rot=(-8, 0, -s * 9), bevel=0.003 * k)
        parts["ear." + side] = p.sph(0.02 * k, Vector((0.076 * s * k, 0.012 * k, 1.645 * k)), skin, seg=8, scale=(0.35, 0.9, 1.35))
    nl = style.get("nose", 1.0)
    parts["nose"] = p.sph(0.0125 * k, hs.pt(0, 1.638, 0.0035 * nl), skin, seg=10, scale=(0.9, 1.4 * nl, 2.2))
    parts["nose"] += p.sph(0.0115 * k, hs.pt(0, 1.622, 0.0075 * nl), skin, seg=10, scale=(1.15, 1.0, 0.95))
    # mouth
    lipm = style.get("lips", "Lips")
    parts["cavity"] = p.sph(0.03 * k, hs.pt(0, 1.588, -0.030), "EyeDark", seg=10, scale=(1.05, 1.0, 0.6))
    parts["teeth_u"] = p.box((0.038 * k, 0.005 * k, 0.008 * k), hs.pt(0, 1.591, -0.004), "Teeth", bevel=0.002 * k)
    parts["teeth_l"] = p.box((0.034 * k, 0.005 * k, 0.007 * k), hs.pt(0, 1.581, -0.004), "Teeth", bevel=0.002 * k)
    parts["tongue"] = p.sph(0.013 * k, hs.pt(0, 1.579, -0.018), "Tongue", seg=8, scale=(1.3, 1.3, 0.55))
    parts["lip_u"] = p.sph(0.0165 * k, hs.pt(0, 1.5945, 0.0012), lipm, seg=12, scale=(1.5, 0.4, 0.3))
    parts["lip_l"] = p.sph(0.0158 * k, hs.pt(0, 1.5815, 0.001), lipm, seg=12, scale=(1.4, 0.42, 0.36))
    return parts


def add_hair(rig, p, style):
    k = rig.k
    c = head_center(rig)
    hm = style.get("hair", "HairBrown")
    kind = style.get("hair_style", "short")
    out = []
    if kind == "bald":
        return out
    def V(x, y, z): return Vector((x, y, z)) * k
    def cap(scale=(1.0, 1.0, 1.0), front=0.05, back=-0.06, shift=(0, -0.004, 0.006)):
        res = bmesh.ops.create_uvsphere(p.bm, u_segments=24, v_segments=14, radius=1.0)
        vs = res["verts"]
        for v in vs:
            v.co = Vector((v.co.x * 0.084 * scale[0], v.co.y * 0.101 * scale[1], v.co.z * 0.121 * scale[2])) * k + c + V(*shift)
        kill = []
        for v in vs:
            yn = (v.co.y - c.y) / (0.101 * k)          # -1 back .. +1 front
            xn = min(1.0, abs(v.co.x - c.x) / (0.084 * k))
            hairline = (back + (front - back) * max(0.0, yn * 0.5 + 0.5) ** 1.5) * k
            hairline -= 0.075 * k * xn ** 2 * max(0.0, yn + 0.6)      # sides come down towards the ears
            if (v.co.z - c.z) < hairline:
                kill.append(v)
        bmesh.ops.delete(p.bm, geom=kill, context="VERTS")
        vs = [v for v in vs if v.is_valid]
        idx = p._slot(hm)
        fs = set()
        for v in vs:
            fs.update(v.link_faces)
        for f in fs:
            f.material_index = idx
            f.smooth = True
        return vs
    if kind == "short":
        out += cap(front=0.078, back=-0.06)
    elif kind == "messy":
        out += cap(scale=(1.02, 1.02, 1.04), front=0.082, back=-0.05, shift=(0, -0.006, 0.010))
        rnd = random.Random(7)
        for i in range(30):
            a = rnd.uniform(0, 6.28); r_ = rnd.uniform(0.0, 0.075)
            base = c + V(math.cos(a) * r_, math.sin(a) * r_ * 1.15 - 0.008, 0.1 * (1 - (r_ / 0.09) ** 2) + 0.02)
            dirv = Vector((math.cos(a) * 0.5 + rnd.uniform(-0.25, 0.25), math.sin(a) * 0.5 + rnd.uniform(-0.25, 0.25), 0.75)).normalized()
            out += p.tube([base, base + dirv * rnd.uniform(0.02, 0.036) * k], 0.014 * k, hm, seg=5, r_end=0.005 * k)
    elif kind == "long":
        out += cap(scale=(1.03, 1.04, 1.05), front=0.08, back=-0.13)
        out += p.sph(0.1 * k, c + V(0, -0.055, -0.09), hm, seg=12, scale=(0.9, 0.7, 2.2))
        for s in (-1, 1):
            out += p.sph(0.028 * k, c + V(0.076 * s, 0.015, -0.04), hm, seg=8, scale=(0.5, 1.0, 2.8))
    elif kind == "ponytail":
        out += cap(scale=(1.02, 1.03, 1.03), front=0.078, back=-0.08)
        out += p.tube([c + V(0, -0.09, 0.01), c + V(0, -0.15, -0.03), c + V(0, -0.17, -0.12), c + V(0, -0.15, -0.22)], 0.028 * k, hm, seg=8, r_end=0.012 * k)
    elif kind == "swept":
        out += cap(scale=(1.02, 1.05, 1.05), front=0.075, back=-0.13, shift=(0, -0.012, 0.005))
        out += p.sph(0.09 * k, c + V(0, -0.075, -0.06), hm, seg=12, scale=(0.95, 0.55, 2.3))
        for s in (-1, 1):
            out += p.sph(0.028 * k, c + V(0.078 * s, 0.0, -0.05), hm, seg=8, scale=(0.5, 1.0, 2.2))
    elif kind == "wisps":
        for s in (-1, 1):
            out += p.sph(0.03 * k, c + V(0.073 * s, -0.01, 0.0), hm, seg=8, scale=(0.5, 1.2, 1.2))
        out += p.sph(0.05 * k, c + V(0, -0.078, 0.0), hm, seg=8, scale=(1.5, 0.5, 1.1))
    elif kind == "curly":
        out += cap(scale=(1.05, 1.05, 1.08), front=0.07, back=-0.06)
        rnd = random.Random(3)
        for i in range(22):
            a = rnd.uniform(0, 6.28); r_ = rnd.uniform(0.02, 0.085)
            out += p.sph(0.027 * k, c + V(math.cos(a) * r_, math.sin(a) * r_ * 1.15 - 0.01, 0.055 + rnd.uniform(0, 0.055) * (1 - r_ / 0.12)), hm, seg=7)
    return out


def add_accessories(rig, p, style, hs):
    k = rig.k
    c = head_center(rig)
    def V(x, y, z): return Vector((x, y, z)) * k
    res = []
    if style.get("glasses"):
        gm = style["glasses"]
        for s in (-1, 1):
            cpt = hs.pt(0.031 * s, 1.667, 0.016)
            res.append((p.lathe([(0.0165 * k, -0.0015 * k), (0.0185 * k, 0.0), (0.0165 * k, 0.0015 * k)], cpt, gm, rot=(90, 0, 0), seg=18), "Head"))
        res.append((p.box((0.02 * k, 0.004 * k, 0.004 * k), hs.pt(0, 1.672, 0.014), gm), "Head"))
        for s in (-1, 1):
            res.append((p.box((0.004 * k, 0.09 * k, 0.004 * k), c + V(0.074 * s, 0.05, 0.012), gm), "Head"))
    if style.get("mustache"):
        res.append((p.sph(0.022 * k, hs.pt(0, 1.603, 0.006), style.get("hair", "HairGrey"), seg=8, scale=(1.5, 0.5, 0.42)), "Head"))
    if style.get("cap"):
        cm = style["cap"]
        res.append((p.sph(0.088 * k, c + V(0, 0.0, 0.05), cm, seg=14, scale=(1.0, 1.1, 0.7)), "Head"))
        res.append((p.box((0.15 * k, 0.07 * k, 0.008 * k), c + V(0, 0.105, 0.03), cm, rot=(-8, 0, 0), bevel=0.003 * k), "Head"))
    if style.get("bandana"):
        res.append((p.lathe([(0.088 * k, -0.02 * k), (0.092 * k, 0.0), (0.088 * k, 0.02 * k)], c + V(0, -0.005, 0.075), style["bandana"], seg=20), "Head"))
    if style.get("headband"):
        res.append((p.lathe([(0.086 * k, -0.008 * k), (0.089 * k, 0.0), (0.086 * k, 0.008 * k)], c + V(0, -0.004, 0.065), style["headband"], seg=20), "Head"))
    if style.get("toolbelt"):
        res.append((p.box((0.36 * k * rig.w, 0.22 * k, 0.05 * k), V(0, 0, 0.99), "Leather", bevel=0.01 * k), "auto"))
        for s in (-1, 1):
            res.append((p.box((0.06 * k, 0.05 * k, 0.12 * k), V(0.19 * s, 0.06, 0.94), "Leather", bevel=0.01 * k), "auto"))
        res.append((p.box((0.02 * k, 0.03 * k, 0.16 * k), V(0.17, 0.05, 0.94), "Chrome"), "auto"))
    if style.get("vest"):
        res.append((p.box((0.36 * k * rig.w, 0.05 * k, 0.4 * k), V(0, 0.16, 1.3), style["vest"], bevel=0.01 * k), "auto"))
    if style.get("tie"):
        res.append((p.box((0.035 * k, 0.012 * k, 0.26 * k), V(0, 0.148, 1.34), style["tie"], bevel=0.003 * k), "auto"))
    if style.get("collar"):
        res.append((p.lathe([(0.066 * k, 0.0), (0.072 * k, 0.02 * k), (0.066 * k, 0.042 * k)], V(0, 0.005, 1.475), style["collar"], seg=18), "auto"))
    if style.get("badge"):
        res.append((p.box((0.05 * k, 0.01 * k, 0.06 * k), V(0.09 * rig.w, 0.15, 1.38), "Brass", bevel=0.004 * k), "auto"))
    if style.get("radio"):
        res.append((p.box((0.05 * k, 0.035 * k, 0.09 * k), V(-0.13, 0.14, 1.36), "PlasticBlack", bevel=0.006 * k), "auto"))
        res.append((p.cyl(0.004 * k, 0.07 * k, V(-0.13, 0.14, 1.44), "PlasticBlack", seg=5), "auto"))
    if style.get("cape"):
        res.append((p.box((0.44 * k * rig.w, 0.03 * k, 0.9 * k), V(0, -0.15, 1.05), style["cape"], bevel=0.01 * k), "auto"))
    return res


def add_hands(rig, p, skin_mat):
    k = rig.k
    out = {}
    for s, side in ((1, "R"), (-1, "L")):
        hb = rig.bones["Fingers." + side]
        h0, h1 = hb[0], hb[1]
        d = (h1 - h0)
        L_ = d.length
        fv = []
        for i in range(4):
            off = Vector((0, (i - 1.5) * 0.013 * k, 0))
            length = (0.9 + 0.12 * (1 if i in (1, 2) else 0)) * L_
            base = h0 + off
            tip = base + d.normalized() * length
            fv += p.tube([base, base.lerp(tip, 0.5), tip], 0.0075 * k, skin_mat, seg=6, r_end=0.006 * k)
        out["Fingers." + side] = fv
        tb = rig.bones["Thumb." + side]
        out["Thumb." + side] = p.tube([tb[0], tb[0].lerp(tb[1], 0.5), tb[1]], 0.0095 * k, skin_mat, seg=6, r_end=0.007 * k)
    return out


# ------------------------------------------------------------------------------------------------
# build a complete character
# ------------------------------------------------------------------------------------------------
def _plane_side(rig, pos, bone_a, frac):
    """Signed distance of pos beyond the point at `frac` along bone_a (positive = further from the root)."""
    h, t, _ = rig.bones[bone_a]
    axis = (t - h).normalized()
    return (pos - (h + (t - h) * frac)).dot(axis)


def body_cut_planes(rig, style):
    """Planes (point, normal) the skin mesh is bisected at so material borders are clean."""
    cuts = []
    k = rig.k
    hem = style.get("hem", 1.12 if style.get("high_pants") else 0.93)
    cuts.append((Vector((0, 0, hem * k)), Vector((0, 0, 1))))
    for z in (0.03, 0.12):
        cuts.append((Vector((0, 0, z * k)), Vector((0, 0, 1))))
    for side in ("R", "L"):
        h, t, _ = rig.bones["LowerArm." + side]
        cuts.append((t, (t - h).normalized()))
        if style.get("sleeve_len") == "short":
            h2, t2, _ = rig.bones["UpperArm." + side]
            cuts.append((h2 + (t2 - h2) * 0.72, (t2 - h2).normalized()))
        if style.get("shorts"):
            h3, t3, _ = rig.bones["UpperLeg." + side]
            cuts.append((h3 + (t3 - h3) * 0.85, (t3 - h3).normalized()))
    return cuts


def classify_body_face(rig, pos, style):
    """Choose a material for a body face."""
    cand = ["Hips", "Spine", "Chest", "Neck", "Shoulder.L", "Shoulder.R", "UpperArm.L", "UpperArm.R", "LowerArm.L", "LowerArm.R",
            "Hand.L", "Hand.R", "UpperLeg.L", "UpperLeg.R", "LowerLeg.L", "LowerLeg.R", "Foot.L", "Foot.R", "Toes.L", "Toes.R"]
    best, bd = None, 1e9
    for n in cand:
        h, t, _ = rig.bones[n]
        d, tt = seg_dist(pos, h, t)
        if d < bd:
            bd, best = d, n
    skin = style.get("skin", "Skin")
    k = rig.k
    z = pos.z / k
    sleeves = style.get("sleeves", style.get("top", "FabricGrey"))
    if best == "Neck":
        return skin
    if best.startswith("Hand"):
        return skin
    if best.startswith(("LowerArm", "UpperArm", "Shoulder")):
        side = best[-1]
        if _plane_side(rig, pos, "LowerArm." + side, 1.0) > -0.002 * k:
            return skin
        if style.get("sleeve_len") == "short" and _plane_side(rig, pos, "UpperArm." + side, 0.72) > -0.002 * k:
            return skin
        return sleeves
    hem = style.get("hem", 1.12 if style.get("high_pants") else 0.93)
    if best in ("Hips", "Spine", "Chest") or best.startswith("UpperLeg"):
        if z > hem - 0.002:
            return style.get("jacket", style.get("top", "FabricGrey"))
        if style.get("shorts") and best.startswith("UpperLeg") and z < 0.5:
            return skin
        return style.get("pants", "Denim")
    if best.startswith("LowerLeg"):
        if style.get("shorts"):
            return skin if z > 0.12 else style.get("shoes", "ShoeWhite")
        return style.get("pants", "Denim") if z > 0.118 else style.get("shoes", "ShoeWhite")
    if best.startswith("Foot") or best.startswith("Toes"):
        return style.get("sole", "Sole") if z < 0.03 else style.get("shoes", "ShoeWhite")
    return skin


def build_character(name, height, style, width=1.0, build=1.0, belly=0.0, shoulders=1.0, face=None, facial_scale=1.0):
    face = face or {}
    rig = Rig(height, width, name="Armature")
    arm = rig.build_armature()
    p = L.Prop(name)
    bm = p.bm
    body_mesh = skin_body(rig, build, belly, shoulders)
    bm.from_mesh(body_mesh)
    bpy.data.meshes.remove(body_mesh)
    for co, no in body_cut_planes(rig, style):
        bmesh.ops.bisect_plane(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces), dist=1e-5, plane_co=co, plane_no=no)
    bm.verts.ensure_lookup_table()
    n_body = len(bm.verts)
    # material zones
    for f in bm.faces:
        cpos = f.calc_center_median()
        f.material_index = p._slot(classify_body_face(rig, cpos, style))
        f.smooth = True
    body_idx = list(range(n_body))
    # head, face, hair, accessories
    head_verts = sculpt_head(rig, p, style.get("skin", "Skin"), **face)
    hs = HeadSurface(rig, head_verts)
    parts = add_face(rig, p, style, hs)
    hair_v = add_hair(rig, p, style)
    hands = add_hands(rig, p, style.get("skin", "Skin"))
    acc = add_accessories(rig, p, style, hs)
    bm.verts.index_update()
    bm.verts.ensure_lookup_table()

    weights = {}
    body_cands = [b for b in BODY_BONES]
    # body: distance weights, neck top blends to head
    for i in body_idx:
        pos = bm.verts[i].co.copy()
        w = distance_weights(rig, pos, body_cands, power=3.2)
        weights[i] = w
    smooth_weights(bm, weights, body_idx, iterations=3, mix=0.55)
    # head sphere: Head with jaw ramp
    jaw_h = rig.bones["Jaw"][0]
    for v in head_verts:
        rel = (v.co - head_center(rig)) / rig.k
        jaw_amt = 0.0
        if rel.z < -0.006 and rel.y > -0.03:
            jaw_amt = min(1.0, (-rel.z - 0.006) / 0.045) * min(1.0, max(0.0, (rel.y + 0.03) / 0.05))
        # keep the chin bottom mostly on the jaw but the neck end on head
        weights[v.index] = {"Head": 1.0 - jaw_amt, "Jaw": jaw_amt} if jaw_amt > 0.01 else {"Head": 1.0}
    def setw(verts, bone_or_map):
        for v in verts:
            if not v.is_valid:
                continue
            if isinstance(bone_or_map, str):
                weights[v.index] = {bone_or_map: 1.0}
            else:
                weights[v.index] = bone_or_map(v)
    for side in ("L", "R"):
        setw(parts["eye." + side] + parts["iris." + side] + parts["pupil." + side], "Eye." + side)
        setw(parts["lid." + side], "LidU." + side)
        setw(parts["brow." + side], "Brow." + side)
        setw(parts["ear." + side], "Head")
    setw(parts["nose"], "Head")
    setw(parts["cavity"], "Head")
    setw(parts["teeth_u"], "Head")
    setw(parts["teeth_l"], "Jaw")
    setw(parts["tongue"], "Jaw")
    setw(parts["lip_u"], lambda v: _lip_w(v, rig, upper=True))
    setw(parts["lip_l"], lambda v: _lip_w(v, rig, upper=False))
    setw(hair_v, "Head")
    for bone, vs in hands.items():
        setw(vs, bone)
    for vs, spec in acc:
        if spec == "Head":
            setw(vs, "Head")
        else:
            for v in vs:
                weights[v.index] = distance_weights(rig, v.co, body_cands, power=3.0, limit=3)
    # any vertex without weights -> Head/Hips fallback
    for v in bm.verts:
        if v.index not in weights:
            weights[v.index] = {"Hips": 1.0}
    wlist = [weights[i] for i in range(len(bm.verts))]
    obj = p.build(weld=False)
    obj.name = name + "_Mesh"
    for bn in rig.bones:
        obj.vertex_groups.new(name=bn)
    for i, w in enumerate(wlist):
        for bn, val in w.items():
            if val > 1e-4:
                obj.vertex_groups[bn].add([i], val, "REPLACE")
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = arm
    obj.parent = arm
    return rig, arm, obj


def _lip_w(v, rig, upper):
    x = abs(v.co.x) / rig.k
    corner = min(1.0, max(0.0, (x - 0.008) / 0.02))
    side = "MouthC.R" if v.co.x > 0 else "MouthC.L"
    main = "Head" if upper else "Jaw"
    d = {main: 1.0 - corner * 0.7}
    if corner > 0.01:
        d[side] = corner * 0.7
    return d


# ------------------------------------------------------------------------------------------------
# animation authoring
# ------------------------------------------------------------------------------------------------
def rest_basis(pb):
    return pb.bone.matrix_local.to_3x3()


def world_to_local_quat(pb, rx, ry, rz):
    r = rest_basis(pb)
    W = Euler((math.radians(rx), math.radians(ry), math.radians(rz)), "XYZ").to_matrix()
    return (r.inverted() @ W @ r).to_quaternion()


class ActionBuilder:
    def __init__(self, arm_obj, fps=30, root="Hips"):
        self.arm = arm_obj
        self.root = root
        bpy.context.scene.render.fps = fps
        if arm_obj.animation_data is None:
            arm_obj.animation_data_create()
        for pb in arm_obj.pose.bones:
            pb.rotation_mode = "QUATERNION"

    def clear_pose(self):
        for pb in self.arm.pose.bones:
            pb.rotation_quaternion = Quaternion((1, 0, 0, 0))
            pb.location = (0, 0, 0)
            pb.scale = (1, 1, 1)

    def make(self, name, frames, fn, loop=True, bones=None):
        """fn(t, f) -> dict: bone -> (rx, ry, rz) [+ optional 'Hips@loc': (x, y, z)]"""
        bones = bones or ANIM_BONES
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        self.arm.animation_data.action = act
        last = frames if not loop else frames
        for f in range(0, frames + 1):
            t = f / frames
            self.clear_pose()
            pose = fn(t if not (loop and f == frames) else 0.0, f)
            for bn, val in pose.items():
                if bn.endswith("@loc"):
                    pb = self.arm.pose.bones[bn[:-4]]
                    pb.location = rest_basis(pb).inverted() @ (Vector(val) * self.k_scale())
                else:
                    pb = self.arm.pose.bones[bn]
                    pb.rotation_quaternion = world_to_local_quat(pb, *val)
            for bn in bones:
                pb = self.arm.pose.bones[bn]
                pb.keyframe_insert("rotation_quaternion", frame=f)
            self.arm.pose.bones[self.root].keyframe_insert("location", frame=f)
        self.arm.animation_data.action = None
        return act

    def k_scale(self):
        return 1.0


def push_all_to_nla(arm_obj):
    """Give every action its own NLA track so the exporter emits all of them."""
    ad = arm_obj.animation_data
    for act in bpy.data.actions:
        tr = ad.nla_tracks.new()
        tr.name = act.name
        st = tr.strips.new(act.name, 0, act)
        st.name = act.name
