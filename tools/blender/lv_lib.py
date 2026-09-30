"""Level shell builder.

Levels are authored in *Godot coordinates* (x right, y up, z back/south); this
module converts to Blender axes internally (bx = x, by = -z, bz = y).

A level script creates a `Level`, adds solids/walls/floors, lights, props,
markers and zones, then calls `level.export(name)` which writes:
    environments/<name>.glb    visual shell
    environments/<name>.json   colliders, lights, props, markers, zones, env
The Godot builder (tools/godot/build_levels.gd) assembles the final scene.
"""
import json, math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
import lt_lib as L
from lt_lib import Prop, Vector


def B(x, y, z):
    """Godot coordinate -> Blender coordinate."""
    return (x, -z, y)


class Level:
    def __init__(self, name):
        self.name = name
        L.reset_scene()
        self.shell = Prop(name + "_shell")
        self.shells = {"shell": self.shell}
        self.cols = []
        self.props = []
        self.lights = []
        self.markers = {}
        self.zones = []
        self.probes = []
        self.occluders = []
        self.env = {}
        self.decals = []
        self.groups = {}
        self._n = {}

    # ------------------------------------------------------------ geometry
    def region(self, name):
        """Switch the visual shell to a named chunk (separate mesh => separate frustum/occlusion culling)."""
        if name not in self.shells:
            self.shells[name] = Prop("%s_%s" % (self.name, name))
        self.shell = self.shells[name]

    def solid(self, mn, mx, mat, col=True, surface="concrete", visible=True, nav=True):
        """Axis-aligned box from min corner to max corner (Godot coords)."""
        x0, y0, z0 = mn
        x1, y1, z1 = mx
        if visible:
            c = ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
            s = (abs(x1 - x0), abs(z1 - z0), abs(y1 - y0))      # blender size x, y(=z), z(=y)
            self.shell.box(s, B(*c), mat)
        if col:
            self.cols.append({"c": [(x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2], "s": [abs(x1 - x0), abs(y1 - y0), abs(z1 - z0)],
                              "r": [0, 0, 0], "surface": surface, "nav": nav})

    def slab(self, x0, z0, x1, z1, y, thick, mat, surface="concrete", col=True):
        """Horizontal slab whose TOP is at y."""
        self.solid((min(x0, x1), y - thick, min(z0, z1)), (max(x0, x1), y, max(z0, z1)), mat, col=col, surface=surface)

    def ceiling(self, x0, z0, x1, z1, y, thick, mat, col=False):
        """Horizontal slab whose BOTTOM is at y."""
        self.solid((min(x0, x1), y, min(z0, z1)), (max(x0, x1), y + thick, max(z0, z1)), mat, col=col)

    def wall(self, x0, z0, x1, z1, y0, y1, thick, mat, openings=(), surface="concrete", col=True, mat_b=None):
        """Wall along an axis-aligned line. openings: (t0, t1, sill, head) where t is distance along the wall."""
        horizontal = abs(z1 - z0) < 1e-6
        length = abs(x1 - x0) if horizontal else abs(z1 - z0)
        start = min(x0, x1) if horizontal else min(z0, z1)
        fixed = z0 if horizontal else x0
        segs = []
        cur = 0.0
        for (t0, t1, sill, head) in sorted(openings):
            if t0 > cur + 1e-4:
                segs.append((cur, t0, y0, y1))
            if sill > y0 + 1e-4:
                segs.append((t0, t1, y0, sill))
            if head < y1 - 1e-4:
                segs.append((t0, t1, head, y1))
            cur = t1
        if cur < length - 1e-4:
            segs.append((cur, length, y0, y1))
        for (a, b, ya, yb) in segs:
            if horizontal:
                self.solid((start + a, ya, fixed - thick / 2), (start + b, yb, fixed + thick / 2), mat, col=col, surface=surface)
            else:
                self.solid((fixed - thick / 2, ya, start + a), (fixed + thick / 2, yb, start + b), mat, col=col, surface=surface)

    def column(self, x, z, y0, y1, size, mat, col=True):
        s = size / 2
        self.solid((x - s, y0, z - s), (x + s, y1, z + s), mat, col=col)

    def round_column(self, x, z, y0, y1, r, mat, col=True, seg=16):
        self.shell.cyl(r, y1 - y0, B(x, (y0 + y1) / 2, z), mat, seg=seg)
        if col:
            self.cols.append({"c": [x, (y0 + y1) / 2, z], "s": [r * 2, y1 - y0, r * 2], "r": [0, 0, 0], "surface": "concrete", "nav": True})

    def ramp(self, x0, z0, x1, z1, y_start, y_end, mat, axis="z", surface="concrete", width_axis_thick=0.3, visible=True):
        """Sloped slab from (x0,z0) at y_start to (x1,z1) at y_end. Box collider rotated to match."""
        dx, dz, dy = x1 - x0, z1 - z0, y_end - y_start
        if axis == "z":
            length = math.hypot(dz, dy)
            width = abs(dx)
            ang = math.degrees(math.atan2(dy, abs(dz))) * (1 if dz > 0 else -1)
            cx, cy, cz = (x0 + x1) / 2, (y_start + y_end) / 2 - width_axis_thick / 2, (z0 + z1) / 2
            # visual: rotated box in Blender space (rotate about X)
            if visible:
                self.shell.box((width, length, width_axis_thick), B(cx, cy, cz), mat, rot=(ang, 0, 0))
            self.cols.append({"c": [cx, cy, cz], "s": [width, width_axis_thick, length], "r": [-ang, 0, 0], "surface": surface, "nav": True})
        else:
            length = math.hypot(dx, dy)
            width = abs(dz)
            ang = math.degrees(math.atan2(dy, abs(dx))) * (1 if dx > 0 else -1)
            cx, cy, cz = (x0 + x1) / 2, (y_start + y_end) / 2 - width_axis_thick / 2, (z0 + z1) / 2
            if visible:
                self.shell.box((length, width, width_axis_thick), B(cx, cy, cz), mat, rot=(0, -ang, 0))
            self.cols.append({"c": [cx, cy, cz], "s": [length, width_axis_thick, width], "r": [0, 0, ang], "surface": surface, "nav": True})

    def stairs(self, x0, z0, y0, x1, z1, y1, steps, mat, axis="z", surface="concrete"):
        """Stairs climbing from (x0,z0,y0) toward (x1,z1,y1)."""
        for i in range(steps):
            t0, t1 = i / steps, (i + 1) / steps
            yb = y0 + (y1 - y0) * t1
            if axis == "z":
                za, zb = z0 + (z1 - z0) * t0, z0 + (z1 - z0) * t1
                self.solid((min(x0, x1), y0, min(za, zb)), (max(x0, x1), yb, max(za, zb)), mat, surface=surface)
            else:
                xa, xb = x0 + (x1 - x0) * t0, x0 + (x1 - x0) * t1
                self.solid((min(xa, xb), y0, min(z0, z1)), (max(xa, xb), yb, max(z0, z1)), mat, surface=surface)

    def cyl(self, x, y, z, r, h, mat, seg=16, col=False):
        self.shell.cyl(r, h, B(x, y + h / 2, z), mat, seg=seg)
        if col:
            self.cols.append({"c": [x, y + h / 2, z], "s": [r * 2, h, r * 2], "r": [0, 0, 0], "surface": "concrete", "nav": True})

    def visual_box(self, mn, mx, mat, rot=(0, 0, 0)):
        x0, y0, z0 = mn
        x1, y1, z1 = mx
        c = ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
        self.shell.box((abs(x1 - x0), abs(z1 - z0), abs(y1 - y0)), B(*c), mat, rot=rot)

    def text(self, text, size, pos, mat, rot=(90, 0, 0), depth=0.03):
        """3D text; rot in Blender degrees (default: reads from -Y toward +Y i.e. from Godot +Z side)."""
        from props_registry import text_mesh
        text_mesh(self.shell, text, size, B(*pos), mat, depth=depth, rot=rot)

    # ------------------------------------------------------------ content
    def light(self, kind, pos, color=(1, 0.95, 0.85), energy=1.0, rng=8.0, shadow=False, spot_angle=60, dir_deg=(-90, 0, 0), name=None, fog=1.0, cookie=None):
        self.lights.append({"kind": kind, "p": list(pos), "color": list(color), "energy": energy, "range": rng, "shadow": shadow,
                            "angle": spot_angle, "rot": list(dir_deg), "name": name or "", "fog": fog, "cookie": cookie})

    def place(self, scene, pos, yaw=0.0, name=None, group=None, rot=None, opts=None, scale=None):
        n = self._n.get(scene, 0) + 1
        self._n[scene] = n
        nm = name or "%s_%d" % (scene, n)
        d = {"scene": scene, "name": nm, "p": list(pos), "r": rot if rot else [0, yaw, 0], "opts": opts or {}}
        if scale:
            d["scale"] = scale
        if group:
            d["group"] = group
        self.props.append(d)
        return nm

    def marker(self, name, pos, yaw=0.0):
        self.markers[name] = [pos[0], pos[1], pos[2], yaw]

    def zone(self, mn, mx, reverb="RevSmall", amount=0.5, name=None):
        self.zones.append({"mn": list(mn), "mx": list(mx), "reverb": reverb, "amount": amount, "name": name or "zone%d" % len(self.zones)})

    def probe(self, mn, mx):
        self.probes.append({"mn": list(mn), "mx": list(mx)})

    def occluder(self, mn, mx):
        self.occluders.append({"mn": list(mn), "mx": list(mx)})

    # ------------------------------------------------------------ output
    def export(self, extra=None):
        objs = []
        nfaces = 0
        for key, sh in self.shells.items():
            if not sh.parts_count():
                continue
            o = sh.build(weld=True)
            o.name = self.name + "_" + key if key != "shell" else self.name + "_shell"
            nfaces += len(o.data.polygons)
            objs.append(o)
        obj = objs[0]
        out_dir = os.path.join(L.ROOT, "environments")
        L.export_glb(objs, os.path.join(out_dir, self.name + ".glb"))
        L.save_blend(os.path.join(L.ROOT, "source_art", "level_" + self.name + ".blend"))
        data = {"name": self.name, "shell": "res://environments/%s.glb" % self.name, "cols": self.cols, "props": self.props, "lights": self.lights,
                "markers": self.markers, "zones": self.zones, "probes": self.probes, "occluders": self.occluders, "env": self.env, "groups": self.groups}
        if extra:
            data.update(extra)
        json.dump(data, open(os.path.join(out_dir, self.name + ".json"), "w"), indent=0)
        print("LEVEL", self.name, "chunks", len(objs), "faces", nfaces, "cols", len(self.cols), "props", len(self.props), "lights", len(self.lights))
