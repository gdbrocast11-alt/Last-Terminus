"""Registry + batch exporter for procedural props."""
import json, os, sys, math
import bpy
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lt_lib as L

REG = {}


def prop(name, cat="misc", body="static", mass=5.0, grab=None, col="box", inspect=None, tags=(), **extra):
    """Register a prop generator.

    body:  static | rigid | none
    grab:  None | light | medium | heavy  (how the player can move it)
    col:   box | convex | capsule | sphere | cylinder | trimesh | none
    """
    def deco(fn):
        REG[name] = dict(fn=fn, cat=cat, body=body, mass=mass, grab=grab, col=col, inspect=inspect, tags=list(tags), **extra)
        return fn
    return deco


def text_mesh(p, text, size, loc, mat, depth=0.02, rot=(90, 0, 0), align="CENTER", bold=0.0):
    """Append 3D text to a Prop. Default rotation stands the text up facing -Y... see below.

    Text is created in the XY plane facing +Z; rot=(90,0,0) stands it up so it reads
    correctly when viewed from -Y (i.e. from the *front* of a prop that faces +Y is the back,
    so pass rot=(90,0,180) for text visible from +Y).
    """
    import bmesh
    cu = bpy.data.curves.new("txt", "FONT")
    cu.body = text
    cu.size = size
    cu.extrude = depth
    cu.bevel_depth = bold
    cu.align_x = align
    cu.align_y = "CENTER"
    ob = bpy.data.objects.new("txt", cu)
    bpy.context.scene.collection.objects.link(ob)
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev)
    bpy.data.objects.remove(ob)
    bpy.data.curves.remove(cu)
    xf = L.Matrix.Translation(Vector(loc)) @ L.rot_matrix(rot)
    me.transform(xf)
    idx = p._slot(mat)
    before = len(p.bm.faces)
    tmp = bmesh.new()
    tmp.from_mesh(me)
    for f in tmp.faces:
        f.material_index = 0
    tmp.to_mesh(me)
    tmp.free()
    p.bm.from_mesh(me)
    p.bm.faces.ensure_lookup_table()
    for f in list(p.bm.faces)[before:]:
        f.material_index = idx
        f.smooth = False
    bpy.data.meshes.remove(me)


def export_all(module_names, out_dir, blend_path, only=None):
    """Build every registered prop, export one GLB each and a combined .blend."""
    L.reset_scene()
    scene_objs = []
    meta = {}
    coll = bpy.context.scene.collection
    for name, d in REG.items():
        if only and name not in only:
            continue
        p = d["fn"]()
        p.name = name
        obj = p.build(coll)
        scene_objs.append(obj)
        children = [c for c in obj.children]
        L.export_glb([obj] + children, os.path.join(out_dir, name + ".glb"))
        meta[name] = {k: v for k, v in d.items() if k != "fn"}
        meta[name]["markers"] = p.markers
        meta[name]["mats"] = p.mats
        bb = [Vector(c) for c in obj.bound_box]
        mn = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
        mx = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
        # store in Godot axes: (x, z, -y)
        meta[name]["aabb_min"] = [mn.x, mn.z, -mx.y]
        meta[name]["aabb_max"] = [mx.x, mx.z, -mn.y]
    L.layout_grid(scene_objs, spacing=4.0, cols=10)
    L.save_blend(blend_path)
    return meta


def write_meta(meta, path):
    existing = {}
    if os.path.exists(path):
        existing = json.load(open(path))
    existing.update(meta)
    json.dump(existing, open(path, "w"), indent=1)
