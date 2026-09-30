"""Shared Blender (bpy) modelling helpers for Last Terminus.

Run inside Blender:  blender -b --python tools/blender/gen_xxx.py

Conventions
  * Units are metres. Blender Z is up; assets face Blender +Y, which becomes
    Godot -Z (forward) after the glTF exporter's Y-up conversion.
  * Every prop is one mesh with several material slots, built through a
    bmesh so we can add many primitives cheaply.
  * UVs are box-projected in *world scale* using each material's `tile`
    size, so tiling PBR textures keep a constant texel density.
"""
import bpy, bmesh, math, os, sys, json
from mathutils import Vector, Matrix, Euler

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import materials_def  # noqa: E402

MD = materials_def.M
_mat_cache = {}


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _mat_cache.clear()


def get_mat(name):
    if name in _mat_cache and name in bpy.data.materials:
        return bpy.data.materials[name]
    if name not in MD:
        raise KeyError("unknown material " + name)
    d = MD[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    c = d["color"]
    bsdf.inputs["Base Color"].default_value = (c[0], c[1], c[2], 1)
    bsdf.inputs["Roughness"].default_value = d["rough"]
    bsdf.inputs["Metallic"].default_value = d["metal"]
    if d["alpha"] < 1:
        bsdf.inputs["Alpha"].default_value = d["alpha"]
    if d.get("vcol"):
        vc = m.node_tree.nodes.new("ShaderNodeVertexColor")
        vc.layer_name = "Col"
        m.node_tree.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
    if d["emit"]:
        e, s = d["emit"]
        bsdf.inputs["Emission Color"].default_value = (e[0], e[1], e[2], 1)
        bsdf.inputs["Emission Strength"].default_value = s
    _mat_cache[name] = True
    return m


def rot_matrix(rot_deg):
    return Euler([math.radians(a) for a in rot_deg], "XYZ").to_matrix().to_4x4()


class Prop:
    """Accumulates primitives into a single bmesh with per-face materials."""

    def parts_count(self):
        return len(self.bm.faces)

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.mats = []
        self.markers = {}        # named local points exported as empties (attachment points)
        self.collision_boxes = []  # (centre, size) local boxes for shells

    # ---- internals ---------------------------------------------------
    def _slot(self, mat_name):
        if mat_name not in self.mats:
            self.mats.append(mat_name)
        return self.mats.index(mat_name)

    def _finish(self, geom, mat_name, xf, smooth):
        verts = [g for g in geom if isinstance(g, bmesh.types.BMVert)]
        faces = [g for g in geom if isinstance(g, bmesh.types.BMFace)]
        bmesh.ops.transform(self.bm, matrix=xf, verts=verts)
        idx = self._slot(mat_name)
        for f in faces:
            f.material_index = idx
            f.smooth = smooth
        return verts, faces

    @staticmethod
    def _xf(loc, rot):
        return Matrix.Translation(Vector(loc)) @ rot_matrix(rot)

    # ---- primitives --------------------------------------------------
    def box(self, size, loc, mat, rot=(0, 0, 0), bevel=0.0):
        """size=(x,y,z) full extents; loc = centre."""
        idx = self._slot(mat)
        before = set(self.bm.faces) if bevel > 0 else None
        r = bmesh.ops.create_cube(self.bm, size=1.0)
        sx, sy, sz = size
        sm = Matrix.Diagonal((sx, sy, sz, 1.0))
        verts = r["verts"]
        bmesh.ops.transform(self.bm, matrix=self._xf(loc, rot) @ sm, verts=verts)
        fs = set()
        for v in verts:
            fs.update(v.link_faces)
        for f in fs:
            f.material_index = idx
            f.smooth = False
        if bevel > 0:
            edges = set()
            for v in verts:
                edges.update(v.link_edges)
            bmesh.ops.bevel(self.bm, geom=list(edges), offset=min(bevel, min(size) * 0.45), segments=2, affect="EDGES")
            for f in self.bm.faces:
                if f not in before:
                    f.material_index = idx
                    f.smooth = False
        return [v for v in verts if v.is_valid]

    def cyl(self, r, h, loc, mat, rot=(0, 0, 0), seg=16, r2=None, smooth=True, caps=True):
        """Cylinder/cone along local Z, centred on loc. r2 = top radius (default r)."""
        r2 = r if r2 is None else r2
        res = bmesh.ops.create_cone(self.bm, cap_ends=caps, cap_tris=False, segments=seg, radius1=r, radius2=r2, depth=h)
        verts = res["verts"]
        bmesh.ops.transform(self.bm, matrix=self._xf(loc, rot), verts=verts)
        idx = self._slot(mat)
        fs = set()
        for v in verts:
            fs.update(v.link_faces)
        for f in fs:
            f.material_index = idx
            f.smooth = smooth and len(f.verts) == 4
        return verts

    def sph(self, r, loc, mat, seg=12, scale=(1, 1, 1), rot=(0, 0, 0), smooth=True):
        res = bmesh.ops.create_uvsphere(self.bm, u_segments=seg, v_segments=max(4, seg // 2 + 1), radius=r)
        verts = res["verts"]
        sm = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
        bmesh.ops.transform(self.bm, matrix=self._xf(loc, rot) @ sm, verts=verts)
        idx = self._slot(mat)
        fs = set()
        for v in verts:
            fs.update(v.link_faces)
        for f in fs:
            f.material_index = idx
            f.smooth = smooth
        return verts

    def lathe(self, profile, loc, mat, rot=(0, 0, 0), seg=20, smooth=True, close_top=False, close_bottom=False):
        """Revolve a (radius, z) profile around local Z."""
        rings = []
        for (rad, z) in profile:
            ring = []
            for i in range(seg):
                a = 2 * math.pi * i / seg
                ring.append(self.bm.verts.new((rad * math.cos(a), rad * math.sin(a), z)))
            rings.append(ring)
        allv = [v for r_ in rings for v in r_]
        idx = self._slot(mat)
        faces = []
        for k in range(len(rings) - 1):
            for i in range(seg):
                j = (i + 1) % seg
                try:
                    f = self.bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
                    faces.append(f)
                except ValueError:
                    pass
        if close_bottom and profile[0][0] > 1e-5:
            try: faces.append(self.bm.faces.new(list(reversed(rings[0]))))
            except ValueError: pass
        if close_top and profile[-1][0] > 1e-5:
            try: faces.append(self.bm.faces.new(rings[-1]))
            except ValueError: pass
        bmesh.ops.transform(self.bm, matrix=self._xf(loc, rot), verts=allv)
        for f in faces:
            f.material_index = idx
            f.smooth = smooth
        if close_top and close_bottom:
            bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        return allv

    def tube(self, pts, r, mat, seg=8, caps=True, smooth=True, r_end=None):
        """Tube along a polyline of Vector-like points."""
        pts = [Vector(p) for p in pts]
        rings = []
        for k, p in enumerate(pts):
            if k == 0:
                t = (pts[1] - pts[0])
            elif k == len(pts) - 1:
                t = (pts[-1] - pts[-2])
            else:
                t = (pts[k + 1] - pts[k - 1])
            t.normalize()
            up = Vector((0, 0, 1)) if abs(t.z) < 0.95 else Vector((1, 0, 0))
            a = t.cross(up).normalized(); b = t.cross(a).normalized()
            rr = r if r_end is None else r + (r_end - r) * k / max(1, len(pts) - 1)
            ring = []
            for i in range(seg):
                ang = 2 * math.pi * i / seg
                ring.append(self.bm.verts.new(p + a * rr * math.cos(ang) + b * rr * math.sin(ang)))
            rings.append(ring)
        idx = self._slot(mat)
        faces = []
        for k in range(len(rings) - 1):
            for i in range(seg):
                j = (i + 1) % seg
                faces.append(self.bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i])))
        if caps:
            faces.append(self.bm.faces.new(list(reversed(rings[0]))))
            faces.append(self.bm.faces.new(rings[-1]))
        for f in faces:
            f.material_index = idx
            f.smooth = smooth and len(f.verts) == 4
        return [v for r_ in rings for v in r_]

    def extrude_poly(self, pts2d, depth, loc, mat, rot=(0, 0, 0), plane="XZ"):
        """Extrude a 2D polygon. plane XZ: polygon in local X/Z, extruded along Y."""
        vs = []
        for (u, v) in pts2d:
            if plane == "XZ":
                vs.append(Vector((u, -depth / 2, v)))
            else:
                vs.append(Vector((u, v, -depth / 2)))
        base = [self.bm.verts.new(p) for p in vs]
        try:
            f = self.bm.faces.new(base)
        except ValueError:
            return
        res = bmesh.ops.extrude_face_region(self.bm, geom=[f] + list(f.edges) + base)
        nv = [g for g in res["geom"] if isinstance(g, bmesh.types.BMVert)]
        off = Vector((0, depth, 0)) if plane == "XZ" else Vector((0, 0, depth))
        bmesh.ops.translate(self.bm, vec=off, verts=nv)
        allv = base + nv
        bmesh.ops.transform(self.bm, matrix=self._xf(loc, rot), verts=allv)
        idx = self._slot(mat)
        fs = set()
        for v in allv:
            fs.update(v.link_faces)
        for ff in fs:
            ff.material_index = idx
            ff.smooth = False
        bmesh.ops.recalc_face_normals(self.bm, faces=list(fs))

    def quad(self, p0, p1, p2, p3, mat, smooth=False):
        vs = [self.bm.verts.new(p) for p in (p0, p1, p2, p3)]
        f = self.bm.faces.new(vs)
        f.material_index = self._slot(mat)
        f.smooth = smooth
        return f

    def mark(self, name, loc):
        self.markers[name] = tuple(loc)

    # ---- output ------------------------------------------------------
    def uv_project(self):
        uv = self.bm.loops.layers.uv.verify()
        for f in self.bm.faces:
            tile = MD[self.mats[f.material_index]]["tile"] if self.mats else 1.0
            n = f.normal
            ax = max(range(3), key=lambda i: abs(n[i]))
            for loop in f.loops:
                p = loop.vert.co
                if ax == 0:
                    u, v = p.y, p.z
                elif ax == 1:
                    u, v = p.x, p.z
                else:
                    u, v = p.x, p.y
                loop[uv].uv = (u / tile, v / tile)

    def build(self, collection=None, weld=True):
        if weld:
            bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=1e-5)
        self.bm.normal_update()
        self.uv_project()
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        obj = bpy.data.objects.new(self.name, mesh)
        for m in self.mats:
            mesh.materials.append(get_mat(m))
        (collection or bpy.context.scene.collection).objects.link(obj)
        for name, loc in self.markers.items():
            e = bpy.data.objects.new(name, None)
            e.empty_display_type = "PLAIN_AXES"
            e.location = loc
            e.parent = obj
            (collection or bpy.context.scene.collection).objects.link(e)
        self.bm.free()
        return obj


# --------------------------------------------------------------------------------------
# collections / export
# --------------------------------------------------------------------------------------
def select_only(objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    if objs:
        bpy.context.view_layer.objects.active = objs[0]


def export_glb(objs, path, animations=False, tangents=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    select_only(objs)
    kwargs = dict(filepath=path, export_format="GLB", use_selection=True, export_apply=not animations,
                  export_yup=True, export_texcoords=True, export_normals=True, export_materials="EXPORT",
                  export_animations=animations, export_extras=True)
    if animations:
        kwargs.update(export_animation_mode="ACTIONS", export_optimize_animation_size=True,
                      export_force_sampling=True, export_frame_step=1)
    if tangents:
        kwargs["export_tangents"] = True
    kwargs["export_vertex_color"] = "MATERIAL"
    try:
        bpy.ops.export_scene.gltf(**kwargs)
    except TypeError:
        for k in ("export_animation_mode", "export_optimize_animation_size", "export_force_sampling", "export_frame_step"):
            kwargs.pop(k, None)
        bpy.ops.export_scene.gltf(**kwargs)


def save_blend(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=path, compress=True)


def layout_grid(objs, spacing=3.0, cols=8):
    """Place finished props on a grid for the retained .blend library."""
    for i, o in enumerate(objs):
        o.location.x += (i % cols) * spacing
        o.location.y -= (i // cols) * spacing
