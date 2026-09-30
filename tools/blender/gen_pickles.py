"""Pickles: scruffy medium mutt, full rig + animation set.
   blender -b --python tools/blender/gen_pickles.py
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Vector
import lt_lib as L
import chars_lib as C

S, Cs, TAU = math.sin, math.cos, 2 * math.pi
ZS = 0.92   # overall height scale (shoulder height ~0.46 m)

BONES = [("Root", None, (0, -0.27, 0.50), (0, -0.2, 0.50)),
         ("Spine1", "Root", (0, -0.2, 0.50), (0, -0.02, 0.52)),
         ("Spine2", "Spine1", (0, -0.02, 0.52), (0, 0.2, 0.53)),
         ("Neck", "Spine2", (0, 0.2, 0.53), (0, 0.38, 0.64)),
         ("Head", "Neck", (0, 0.38, 0.64), (0, 0.55, 0.67)),
         ("Jaw", "Head", (0, 0.46, 0.65), (0, 0.60, 0.62)),
         ("Tail1", "Root", (0, -0.32, 0.55), (0, -0.44, 0.61)),
         ("Tail2", "Tail1", (0, -0.44, 0.61), (0, -0.52, 0.68)),
         ("Tail3", "Tail2", (0, -0.52, 0.68), (0, -0.55, 0.76)),
         ("Tail4", "Tail3", (0, -0.55, 0.76), (0, -0.55, 0.84))]
for s, side in ((1, "R"), (-1, "L")):
    BONES += [
        ("Eye." + side, "Head", (0.037 * s, 0.53, 0.71), (0.037 * s, 0.56, 0.71)),
        ("Ear1." + side, "Head", (0.055 * s, 0.45, 0.745), (0.085 * s, 0.44, 0.68)),
        ("Ear2." + side, "Ear1." + side, (0.085 * s, 0.44, 0.68), (0.10 * s, 0.43, 0.60)),
        ("FrontUpper." + side, "Spine2", (0.10 * s, 0.18, 0.46), (0.10 * s, 0.16, 0.26)),
        ("FrontLower." + side, "FrontUpper." + side, (0.10 * s, 0.16, 0.26), (0.10 * s, 0.17, 0.10)),
        ("FrontPaw." + side, "FrontLower." + side, (0.10 * s, 0.17, 0.10), (0.10 * s, 0.24, 0.03)),
        ("HindUpper." + side, "Root", (0.11 * s, -0.27, 0.45), (0.10 * s, -0.20, 0.27)),
        ("HindLower." + side, "HindUpper." + side, (0.10 * s, -0.20, 0.27), (0.10 * s, -0.31, 0.15)),
        ("HindFoot." + side, "HindLower." + side, (0.10 * s, -0.31, 0.15), (0.10 * s, -0.26, 0.03)),
    ]

ANIM = ["Root", "Spine1", "Spine2", "Neck", "Head", "Jaw", "Tail1", "Tail2", "Tail3", "Tail4"]
for side in "RL":
    ANIM += ["Ear1." + side, "Ear2." + side, "FrontUpper." + side, "FrontLower." + side, "FrontPaw." + side,
             "HindUpper." + side, "HindLower." + side, "HindFoot." + side]


class DogRig(C.Rig):
    def __init__(self):
        self.k = 1.0
        self.w = 1.0
        self.name = "Armature"
        self.bones = {n: (Vector((h[0], h[1], h[2] * ZS)), Vector((t[0], t[1], t[2] * ZS)), par) for (n, par, h, t) in BONES}


def build_body(rig):
    verts, radii, edges, J = [], [], [], {}
    def add(n, pos, rx, ry):
        J[n] = len(verts); verts.append(Vector(pos)); radii.append((rx * 1.3, ry * 1.3))
    add("pelvis", (0, -0.26, 0.48), 0.13, 0.135)
    add("mid", (0, -0.06, 0.50), 0.135, 0.15)
    add("chest", (0, 0.15, 0.49), 0.15, 0.17)
    add("nb", (0, 0.29, 0.585), 0.085, 0.095)
    add("nt", (0, 0.40, 0.65), 0.07, 0.075)
    add("t0", (0, -0.34, 0.55), 0.04, 0.04); add("t1", (0, -0.45, 0.62), 0.033, 0.033)
    add("t2", (0, -0.53, 0.70), 0.03, 0.03); add("t3", (0, -0.55, 0.78), 0.028, 0.028); add("t4", (0, -0.55, 0.85), 0.032, 0.032)
    edges += [(J["pelvis"], J["mid"]), (J["mid"], J["chest"]), (J["chest"], J["nb"]), (J["nb"], J["nt"]),
              (J["pelvis"], J["t0"]), (J["t0"], J["t1"]), (J["t1"], J["t2"]), (J["t2"], J["t3"]), (J["t3"], J["t4"])]
    for s, side in ((1, "R"), (-1, "L")):
        add("fs" + side, (0.09 * s, 0.17, 0.44), 0.075, 0.085); add("fe" + side, (0.10 * s, 0.16, 0.26), 0.048, 0.048)
        add("fw" + side, (0.10 * s, 0.17, 0.10), 0.038, 0.038); add("fp" + side, (0.10 * s, 0.235, 0.03), 0.05, 0.036)
        add("hh" + side, (0.10 * s, -0.26, 0.44), 0.10, 0.105); add("hk" + side, (0.10 * s, -0.20, 0.27), 0.06, 0.06)
        add("hc" + side, (0.10 * s, -0.31, 0.15), 0.04, 0.04); add("hp" + side, (0.10 * s, -0.25, 0.03), 0.05, 0.036)
        edges += [(J["chest"], J["fs" + side]), (J["fs" + side], J["fe" + side]), (J["fe" + side], J["fw" + side]), (J["fw" + side], J["fp" + side]),
                  (J["pelvis"], J["hh" + side]), (J["hh" + side], J["hk" + side]), (J["hk" + side], J["hc" + side]), (J["hc" + side], J["hp" + side])]
    me = bpy.data.meshes.new("dog_ctrl")
    me.from_pydata([tuple(v) for v in verts], edges, [])
    ob = bpy.data.objects.new("dog_ctrl", me)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    sk = ob.modifiers.new("Skin", "SKIN"); sk.use_smooth_shade = True; sk.branch_smoothing = 0.7
    for i, r in enumerate(radii):
        me.skin_vertices[0].data[i].radius = r
    me.skin_vertices[0].data[J["pelvis"]].use_root = True
    ss = ob.modifiers.new("Sub", "SUBSURF"); ss.levels = 2; ss.render_levels = 2
    ev = ob.evaluated_get(bpy.context.evaluated_depsgraph_get())
    out = bpy.data.meshes.new_from_object(ev)
    bpy.data.objects.remove(ob); bpy.data.meshes.remove(me)
    return out


def fur_color(pos):
    """Vertex colour patches: tan coat, white chest/paws/muzzle, brown saddle."""
    x, y, z = pos
    base = Vector((0.80, 0.58, 0.36))
    white = Vector((0.95, 0.92, 0.86))
    saddle = Vector((0.52, 0.34, 0.20))
    col = base.copy()
    if z > 0.5 and -0.3 < y < 0.15 and abs(x) < 0.12:
        col = col.lerp(saddle, min(1.0, (z - 0.5) * 12))
    if y > 0.05 and z < 0.5 and abs(x) < 0.09:
        col = col.lerp(white, min(1.0, (0.5 - z) * 8 + 0.25))
    if z < 0.1:
        col = col.lerp(white, min(1.0, (0.1 - z) * 20))
    if y > 0.5:
        col = col.lerp(white, 0.5)
    if y < -0.5 and z > 0.75:
        col = col.lerp(white, min(1.0, (z - 0.75) * 12))
    return col


def build_dog():
    rig = DogRig()
    arm = rig.build_armature()
    p = L.Prop("pickles")
    bm = p.bm
    bm.from_mesh(build_body(rig))
    n_body = len(bm.verts)
    fur = p._slot("Fur")
    for f in bm.faces:
        f.material_index = fur
        f.smooth = True
    body_idx = list(range(n_body))
    P_ = []      # (verts, weights fn)
    def V(x, y, z): return Vector((x, y, z))
    # head: skull, muzzle, jaw, nose, eyes, brows, ears
    skull = p.sph(0.078, V(0, 0.47, 0.685), "Fur", seg=16, scale=(0.95, 1.0, 0.95))
    muzzle = p.sph(0.05, V(0, 0.56, 0.655), "Fur", seg=14, scale=(0.75, 1.35, 0.72))
    jaw = p.sph(0.04, V(0, 0.555, 0.63), "Fur", seg=12, scale=(0.72, 1.35, 0.5))
    nose = p.sph(0.021, V(0, 0.625, 0.66), "Nose", seg=10, scale=(1.1, 0.8, 0.85))
    teeth = p.box((0.04, 0.05, 0.006), V(0, 0.57, 0.64), "Teeth")
    tongue = p.sph(0.02, V(0, 0.57, 0.625), "Tongue", seg=8, scale=(0.9, 1.5, 0.35))
    cav = p.sph(0.03, V(0, 0.55, 0.64), "EyeDark", seg=8, scale=(0.9, 1.4, 0.4))
    eyes = {}
    brows = {}
    ears = {}
    for s, side in ((1, "R"), (-1, "L")):
        eyes[side] = p.sph(0.0145, V(0.037 * s, 0.53, 0.712), "EyeDark", seg=10)
        eyes[side] += p.sph(0.004, V(0.043 * s, 0.542, 0.72), "PaintWhite", seg=5)
        brows[side] = p.sph(0.018, V(0.037 * s, 0.525, 0.737), "Fur", seg=8, scale=(1.3, 1.0, 0.6))
        # floppy ear: tapered flattened ellipsoid hanging from the top of the skull
        ears[side] = p.sph(0.03, V(0.085 * s, 0.44, 0.665), "Fur", seg=10, scale=(0.32, 1.0, 2.1), rot=(0, 12 * s, 0))
    # scruffy tufts (tapered tubes) with fur vertex colour
    rnd = random.Random(11)
    tufts = []
    def tuft(base, direction, length, r):
        return p.tube([base, base + direction.normalized() * length], r, "Fur", seg=5, r_end=r * 0.15)
    for i in range(34):
        a = rnd.uniform(0, TAU); yy = rnd.uniform(-0.3, 0.3); zz = 0.5 + rnd.uniform(-0.03, 0.09)
        base = V(math.cos(a) * 0.12, yy, zz + math.sin(a) * 0.14)
        tufts.append((tuft(base, V(math.cos(a) * 0.55, rnd.uniform(-1.0, -0.4), math.sin(a) * 0.55), rnd.uniform(0.022, 0.036), 0.009), "auto"))
    for s in (-1, 1):
        for k_ in range(3):   # cheek / eyebrow tufts
            tufts.append((tuft(V(0.06 * s, 0.5 + k_ * 0.02, 0.68 - k_ * 0.02), V(s * 0.6, -0.3, -0.5 - 0.2 * k_), 0.035, 0.012), "Head"))
        tufts.append((tuft(V(0.04 * s, 0.53, 0.735), V(s * 0.5, 0.8, 0.5), 0.025, 0.011), "Head"))
    for i in range(7):
        tufts.append((tuft(V(rnd.uniform(-0.03, 0.03), -0.55 + rnd.uniform(0, 0.02), 0.78 + i * 0.012), V(rnd.uniform(-1, 1), -0.4, 0.6), 0.04, 0.011), "Tail4"))
    for i in range(6):
        tufts.append((tuft(V(rnd.uniform(-0.05, 0.05), 0.32 + rnd.uniform(0, 0.05), 0.5 + rnd.uniform(0, 0.05)), V(rnd.uniform(-0.5, 0.5), -0.2, -1), 0.035, 0.011), "auto"))
    for v in bm.verts:
        v.co.z *= ZS
    bm.verts.index_update(); bm.verts.ensure_lookup_table()
    W = {}
    cands = [b for b in rig.bones if b not in ("Jaw", "Eye.L", "Eye.R", "Ear1.L", "Ear1.R", "Ear2.L", "Ear2.R")]
    for i in body_idx:
        W[i] = C.distance_weights(rig, bm.verts[i].co.copy(), cands, power=3.2)
    C.smooth_weights(bm, W, body_idx, iterations=3, mix=0.55)
    # Neck-top vertices should follow Head fully where they enter the skull
    for i in body_idx:
        v = bm.verts[i]
        if v.co.y > 0.41:
            W[i] = {"Head": 1.0}
    def setw(vs, w):
        for v in vs:
            if v.is_valid:
                W[v.index] = ({w: 1.0} if isinstance(w, str) else w(v))
    setw(skull, "Head"); setw(muzzle, "Head"); setw(nose, "Head"); setw(teeth, "Head"); setw(cav, "Head")
    setw(jaw, "Jaw"); setw(tongue, "Jaw")
    for side in "RL":
        setw(eyes[side], "Eye." + side); setw(brows[side], "Head")
        setw(ears[side], lambda v, sd=side: {"Ear1." + sd: 1.0 if v.co.z > 0.7 else 0.35, "Ear2." + sd: 0.0 if v.co.z > 0.7 else 0.65} if v.co.z <= 0.7 else {"Ear1." + sd: 1.0})
    for vs, spec in tufts:
        if spec == "auto":
            for v in vs:
                W[v.index] = C.distance_weights(rig, v.co.copy(), cands, power=3.0, limit=3)
        else:
            setw(vs, spec)
    for v in bm.verts:
        W.setdefault(v.index, {"Root": 1.0})
    # vertex colours
    for old in list(bm.loops.layers.color):
        bm.loops.layers.color.remove(old)
    lay = bm.loops.layers.color.new("Col")
    for f in bm.faces:
        for lp in f.loops:
            c = lp.vert.co
            col = fur_color(c)
            mi = f.material_index
            mname = p.mats[mi]
            if mname == "Fur":
                # ears darker
                if abs(c.x) > 0.06 and c.y < 0.5 and c.y > 0.38 and 0.58 < c.z < 0.77:
                    col = Vector((0.33, 0.2, 0.11))
                lp[lay] = (col.x, col.y, col.z, 1.0)
            else:
                lp[lay] = (1, 1, 1, 1)
    wlist = [W[i] for i in range(len(bm.verts))]
    obj = p.build(weld=False)
    obj.name = "Pickles_Mesh"
    for bn in rig.bones:
        obj.vertex_groups.new(name=bn)
    for i, w in enumerate(wlist):
        for bn, val in w.items():
            if val > 1e-4:
                obj.vertex_groups[bn].add([i], val, "REPLACE")
    mod = obj.modifiers.new("Armature", "ARMATURE"); mod.object = arm
    obj.parent = arm
    return rig, arm, obj


# ---------------------------------------------------------------- animations
def tail_wag(t, amp, speed, base_lift=0.0, curl=0.0):
    p = t * TAU * speed
    d = {}
    for i, n in enumerate(("Tail1", "Tail2", "Tail3", "Tail4")):
        d[n] = (base_lift * (1 if i == 0 else 0.3) + curl * i, 0, amp * S(p - i * 0.7) * (0.6 + 0.3 * i))
    return d


def legs(fl, fr, hl, hr, elbow=0.0):
    """fl/fr/hl/hr: (swing, flex)"""
    d = {}
    for side, (sw, fx) in (("L", fl), ("R", fr)):
        d["FrontUpper." + side] = (sw, 0, 0); d["FrontLower." + side] = (-fx, 0, 0); d["FrontPaw." + side] = (fx * 0.6 - sw * 0.3, 0, 0)
    for side, (sw, fx) in (("L", hl), ("R", hr)):
        d["HindUpper." + side] = (sw, 0, 0); d["HindLower." + side] = (fx, 0, 0); d["HindFoot." + side] = (-fx * 0.7 - sw * 0.4, 0, 0)
    return d


def M(*ds):
    o = {}
    for d in ds: o.update(d)
    return o


def ears_pose(flop=0.0, flick=0.0):
    return {"Ear1.L": (flop, 0, flick), "Ear1.R": (flop, 0, -flick), "Ear2.L": (flop * 0.6, 0, 0), "Ear2.R": (flop * 0.6, 0, 0)}


def a_idle(t, f):
    p = t * TAU
    return M({"Root@loc": (0, 0, 0.004 * S(p)), "Spine2": (1.2 * S(p), 0, 0), "Neck": (6 + 1.5 * S(p), 0, 3 * S(p * 0.5)), "Head": (-5, 0, 2 * S(p)), "Jaw": (2, 0, 0)},
             tail_wag(t, 14, 2, 8), legs((0, 0), (0, 0), (0, 0), (0, 0)), ears_pose(2 + 3 * max(0, S(p * 3) - 0.9) * 10, 0))


def a_idle_alert(t, f):
    d = a_idle(t, f)
    d["Neck"] = (16, 0, 0); d["Head"] = (-6, 0, 6 * S(t * TAU * 2)); d["Spine1"] = (-2, 0, 0)
    d.update(ears_pose(-14, 0)); d.update(tail_wag(t, 5, 3, 22))
    return d


def a_walk(t, f):
    p = t * TAU
    a, b = 24 * S(p), -24 * S(p)
    fx = lambda ph: 30 * max(0, S(ph + 1.57))
    return M({"Root@loc": (0, 0, 0.012 * Cs(2 * p)), "Root": (0, 0, 3 * S(p)), "Spine1": (0, 0, -4 * S(p)), "Spine2": (1.5 * S(2 * p), 0, -3 * S(p)), "Neck": (5, 0, 4 * S(p)), "Head": (-4, 0, 0)},
             legs((a, fx(p)), (b, fx(p + math.pi)), (b, -fx(p + math.pi) * 0.9), (a, -fx(p) * 0.9)),
             tail_wag(t, 16, 1, 22), ears_pose(4 + 3 * S(2 * p)))


def a_trot(t, f):
    p = t * TAU
    a, b = 34 * S(p), -34 * S(p)
    fx = lambda ph: 48 * max(0, S(ph + 1.57))
    return M({"Root@loc": (0, 0, 0.02 * abs(S(p))), "Root": (0, 0, 2 * S(p)), "Spine1": (-2, 0, -2 * S(p)), "Neck": (2, 0, 2 * S(p)), "Head": (-3, 0, 0)},
             legs((a, fx(p)), (b, fx(p + math.pi)), (b, -fx(p + math.pi)), (a, -fx(p))),
             tail_wag(t, 12, 2, 35), ears_pose(16 + 8 * S(2 * p)))


def a_run(t, f):
    p = t * TAU
    g = S(p)
    fx = lambda ph: 60 * max(0, S(ph + 1.2))
    return M({"Root@loc": (0, 0, 0.05 * abs(S(p)) - 0.01), "Root": (-8 * S(p), 0, 0), "Spine1": (10 * S(p), 0, 0), "Spine2": (-10 * S(p), 0, 0), "Neck": (2, 0, 0), "Head": (-2, 0, 0), "Jaw": (10, 0, 0)},
             legs((45 * S(p), fx(p)), (45 * S(p + 0.4), fx(p + 0.4)), (-45 * S(p + 3.2), -fx(p + 3.2) * 0.9), (-45 * S(p + 3.6), -fx(p + 3.6) * 0.9)),
             tail_wag(t, 6, 1, 45), ears_pose(30 + 10 * S(2 * p)))


def a_sit(t, f):
    p = t * TAU
    return M({"Root@loc": (0, -0.06, -0.30), "Root": (48, 0, 0), "Spine1": (6, 0, 0), "Spine2": (4, 0, 0), "Neck": (-4, 0, 2 * S(p * 0.5)), "Head": (-8, 0, 0)},
             {"FrontUpper.L": (-58, 0, 0), "FrontUpper.R": (-58, 0, 0)},
             {"HindUpper.L": (32, 0, 0), "HindUpper.R": (32, 0, 0), "HindLower.L": (-115, 0, 0), "HindLower.R": (-115, 0, 0), "HindFoot.L": (125, 0, 0), "HindFoot.R": (125, 0, 0)},
             tail_wag(t, 22, 1.5, -10, -2), ears_pose(4))


def a_sit_alert(t, f):
    d = a_sit(t, f)
    d["Neck"] = (6, 0, 0); d.update(ears_pose(-14)); d["Head"] = (-6, 0, 5 * S(t * TAU))
    return d


def a_lie(t, f):
    p = t * TAU
    return M({"Root@loc": (0, 0, -0.27), "Spine2": (1 * S(p), 0, 0), "Neck": (6, 0, 8), "Head": (-6, 0, 0)},
             {"FrontUpper.L": (80, 0, 0), "FrontUpper.R": (80, 0, 0), "FrontLower.L": (-20, 0, 0), "FrontLower.R": (-20, 0, 0), "FrontPaw.L": (5, 0, 0), "FrontPaw.R": (5, 0, 0)},
             {"HindUpper.L": (95, 0, 12), "HindUpper.R": (95, 0, -12), "HindLower.L": (-100, 0, 0), "HindLower.R": (-100, 0, 0), "HindFoot.L": (85, 0, 0), "HindFoot.R": (85, 0, 0)},
             tail_wag(t, 6, 0.5, -20), ears_pose(6))


def a_sleep(t, f):
    p = t * TAU
    d = a_lie(t, f)
    d["Spine2"] = (2.5 * S(p), 0, 0); d["Neck"] = (-14, 0, 14); d["Head"] = (-12, 0, 10)
    return d


def a_sniff(t, f):
    p = t * TAU
    d = a_walk(t * 0.5, f)
    d["Neck"] = (-38 + 4 * S(8 * p), 0, 8 * S(p)); d["Head"] = (-10 + 6 * S(8 * p), 0, 0); d["Spine2"] = (-4, 0, 0)
    d.update(tail_wag(t, 10, 1, 30))
    return d


def a_sniff_stand(t, f):
    p = t * TAU
    d = a_idle(t, f)
    d["Neck"] = (-34 + 4 * S(8 * p), 0, 10 * S(p)); d["Head"] = (-12 + 5 * S(8 * p), 0, 0)
    return d


def a_scratch(t, f):
    p = t * TAU
    d = a_sit(t, f)
    d["HindUpper.R"] = (85, 0, 20); d["HindLower.R"] = (-60 + 25 * S(p * 9), 0, 0); d["HindFoot.R"] = (30, 0, 0)
    d["Neck"] = (4, 0, -12); d["Head"] = (-4, 0, -14); d["Root"] = (48, 0, -8)
    return d


def a_bark(t, f):
    a = S(min(1.0, t * 1.0) * math.pi)
    d = a_idle(t, f)
    d["Neck"] = (28 * a, 0, 0); d["Head"] = (-10 + 16 * a, 0, 0); d["Jaw"] = (-38 * a, 0, 0)
    d["Spine2"] = (-4 * a, 0, 0); d["Root@loc"] = (0, 0, 0.01 * a)
    d.update(legs((-6 * a, 0), (-6 * a, 0), (0, 0), (0, 0)))
    d.update(ears_pose(-10 * a))
    return d


def a_whine(t, f):
    p = t * TAU
    d = a_sit(t, f)
    d["Head"] = (-14, 0, 14); d["Neck"] = (-8, 0, 6); d.update(ears_pose(24)); d.update(tail_wag(t, 3, 1, -28, -6)); d["Jaw"] = (-6 - 4 * S(p * 4), 0, 0)
    return d


def a_shake(t, f):
    p = t * TAU
    a = 1 - abs(2 * t - 1) * 0.3
    return M({"Root@loc": (0, 0, 0), "Root": (0, 0, 26 * S(p * 6) * a * 0.7), "Spine1": (0, 0, 34 * S(p * 6 + 0.7) * a), "Spine2": (0, 0, 40 * S(p * 6 + 1.4) * a),
              "Neck": (0, 0, 46 * S(p * 6 + 2.0) * a), "Head": (-6, 0, 30 * S(p * 6 + 2.6) * a)}, legs((0, 0), (0, 0), (0, 0), (0, 0)),
             tail_wag(t, 40, 6, 20), ears_pose(30, 40 * S(p * 6)))


def a_play_bow(t, f):
    p = t * TAU
    return M({"Root@loc": (0, 0, 0.06), "Root": (8, 0, 0), "Spine1": (-20, 0, 0), "Spine2": (-22, 0, 0), "Neck": (-8, 0, 0), "Head": (10, 0, 0), "Jaw": (-14 * abs(S(p * 2)), 0, 0)},
             legs((-40, 40), (-40, 40), (5, 0), (5, 0)), tail_wag(t, 36, 3, 46), ears_pose(20))


def a_happy(t, f):
    p = t * TAU
    return M({"Root@loc": (0, 0, 0.05 * abs(S(p * 2))), "Root": (0, 0, 10 * S(p * 2)), "Spine1": (0, 0, -14 * S(p * 2)), "Spine2": (0, 0, 14 * S(p * 2)),
              "Neck": (10, 0, -10 * S(p * 2)), "Head": (-4, 0, 6 * S(p * 2)), "Jaw": (-16 - 6 * S(p * 3), 0, 0)},
             legs((14 * S(p * 2), 10), (-14 * S(p * 2), 10), (-10 * S(p * 2), 6), (10 * S(p * 2), 6)), tail_wag(t, 46, 5, 40), ears_pose(12))


def a_beg(t, f):
    p = t * TAU
    d = a_sit(t, f)
    d["Root@loc"] = (0, -0.14, -0.22); d["Root"] = (68, 0, 0); d["Spine1"] = (10, 0, 0); d["Spine2"] = (8, 0, 0)
    d["Neck"] = (-10, 0, 0); d["Head"] = (-6, 0, 8 * S(p))
    d.update({"FrontUpper.L": (-30 + 8 * S(p * 2), 0, 0), "FrontUpper.R": (-30 - 8 * S(p * 2), 0, 0), "FrontLower.L": (-95, 0, 0), "FrontLower.R": (-95, 0, 0)})
    d["HindUpper.L"] = (12, 0, 0); d["HindUpper.R"] = (12, 0, 0)
    return d


def a_tilt(t, f):
    a = S(min(1.0, t) * math.pi)
    d = a_idle_alert(t, f)
    d["Head"] = (-6, 26 * a, 4 * a); d["Neck"] = (18, 0, 6 * a)
    d.update(ears_pose(-8 * a, 14 * a))
    return d


def a_look_back(t, f):
    a = S(min(1.0, t) * math.pi)
    d = a_walk(t, f)
    d["Neck"] = (8, 0, 60 * a); d["Head"] = (-4, 0, 26 * a); d["Spine2"] = (0, 0, 16 * a)
    return d


def a_stretch(t, f):
    a = S(min(1.0, t) * math.pi)
    d = a_play_bow(t, f)
    for k_ in ("Root", "Spine1", "Spine2", "Neck"):
        d[k_] = tuple(v * a for v in d[k_])
    d["Jaw"] = (-30 * a, 0, 0)
    return d


def a_eat(t, f):
    p = t * TAU
    d = a_idle(t, f)
    d["Neck"] = (-40 + 6 * S(p * 3), 0, 0); d["Head"] = (-16, 0, 0); d["Jaw"] = (-10 * abs(S(p * 3)), 0, 0)
    d.update(tail_wag(t, 24, 3, 30))
    return d


def a_carry(t, f):
    d = a_trot(t, f)
    d["Neck"] = (16, 0, 0); d["Head"] = (-10, 0, 0); d["Jaw"] = (-6, 0, 0)
    return d


def a_jump(t, f):
    a = S(t * math.pi)
    d = a_run(0.25, f)
    d["Root@loc"] = (0, 0, 0.35 * a); d["Root"] = (-14 * a, 0, 0)
    return d


def a_dodge(t, f):
    a = S(t * math.pi)
    d = a_idle_alert(t, f)
    d["Root@loc"] = (0.25 * a, 0, 0.05 * a); d["Spine1"] = (0, 0, -18 * a); d["Root"] = (0, 0, 10 * a)
    return d


def a_roll(t, f):
    d = a_lie(t, f)
    e = S(min(1.0, t) * math.pi)
    d["Root"] = (0, 180 * min(1.0, t * 1.4), 0)
    d["Root@loc"] = (0, 0, -0.26 + 0.1 * e)
    d.update(legs((-70 * e, 20), (-70 * e, 20), (-70 * e, 20), (-70 * e, 20)))
    return d


def a_yawn(t, f):
    a = S(min(1.0, t) * math.pi)
    d = a_sit(t, f)
    d["Neck"] = (30 * a - 4, 0, 0); d["Jaw"] = (-45 * a, 0, 0); d["Head"] = (10 * a - 8, 0, 0)
    return d


def a_ride(t, f):
    """Sits proudly on moving vehicles, ears flapping in the wind."""
    d = a_sit_alert(t, f)
    d.update(ears_pose(50 + 15 * S(t * TAU * 6), 6 * S(t * TAU * 6)))
    d["Jaw"] = (-18, 0, 0)
    d.update(tail_wag(t, 40, 6, 20))
    return d


def a_shiver(t, f):
    d = a_sit(t, f)
    d["Root"] = (48, 0, 3 * S(t * TAU * 12)); d.update(ears_pose(30)); d.update(tail_wag(t, 2, 1, -40, -6))
    return d


ACT = [("idle", 90, a_idle, True), ("idle_alert", 60, a_idle_alert, True), ("walk", 27, a_walk, True), ("trot", 20, a_trot, True), ("run", 16, a_run, True),
       ("sit", 90, a_sit, True), ("sit_alert", 60, a_sit_alert, True), ("lie", 90, a_lie, True), ("sleep", 120, a_sleep, True), ("sniff", 60, a_sniff, True),
       ("sniff_stand", 60, a_sniff_stand, True), ("scratch", 60, a_scratch, True), ("bark", 20, a_bark, False), ("whine", 60, a_whine, True), ("shake", 36, a_shake, False),
       ("play_bow", 45, a_play_bow, True), ("happy", 30, a_happy, True), ("beg", 60, a_beg, True), ("tilt", 45, a_tilt, False), ("look_back", 45, a_look_back, False),
       ("stretch", 60, a_stretch, False), ("eat", 45, a_eat, True), ("carry", 20, a_carry, True), ("jump", 24, a_jump, False), ("dodge", 20, a_dodge, False),
       ("roll", 60, a_roll, False), ("yawn", 60, a_yawn, False), ("ride", 40, a_ride, True), ("shiver", 30, a_shiver, True)]

if __name__ == "__main__":
    L.reset_scene()
    rig, arm, mesh = build_dog()
    ab = C.ActionBuilder(arm, root="Root")
    for name, frames, fn, loop in ACT:
        ab.make(name, frames, fn, loop, bones=ANIM)
    C.push_all_to_nla(arm)
    out = os.path.join(L.ROOT, "characters", "pickles.glb")
    L.export_glb([arm, mesh], out, animations=True)
    L.save_blend(os.path.join(L.ROOT, "source_art", "char_pickles.blend"))
    print("PICKLES", os.path.getsize(out) // 1024, "KB")
