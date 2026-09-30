"""Toolbert's Home Center props (hardware + garden). Origin = floor centre, front faces +Y."""
import math
from props_registry import prop, text_mesh
from lt_lib import Prop, Vector
from props_transit import _legs4


def _can(p, loc, mat, h=0.19, r=0.08):
    p.cyl(r, h, (loc[0], loc[1], loc[2] + h / 2), "SteelGalv", seg=14)
    p.cyl(r * 0.99, 0.006, (loc[0], loc[1], loc[2] + h + 0.003), mat, seg=14)
    p.cyl(r * 1.005, h * 0.55, (loc[0], loc[1], loc[2] + h * 0.45), mat, seg=14)
    p.cyl(r * 1.02, 0.008, (loc[0], loc[1], loc[2] + 0.004), "SteelGalv", seg=14)
    p.cyl(r * 1.02, 0.008, (loc[0], loc[1], loc[2] + h - 0.004), "SteelGalv", seg=14)


@prop("paint_can", cat="store", body="rigid", mass=1.5, grab="light", col="cylinder", tags=["paint", "can"])
def paint_can():
    p = Prop("paint_can")
    _can(p, (0, 0, 0), "PaintRed")
    p.tube([(-0.08, 0, 0.18), (0, 0, 0.27), (0.08, 0, 0.18)], 0.004, "SteelDark", seg=5)
    return p


@prop("paint_can_stack", cat="store", body="rigid", mass=40, grab="heavy", col="box", inspect="ch3_insp_stack", tags=["paint", "chain"], hazard=1)
def paint_can_stack():
    p = Prop("paint_can_stack")
    cols = ["PaintRed", "PaintBlue", "PaintYellow", "PaintGreen", "PaintOrange", "PaintWhite"]
    p.box((1.2, 1.2, 0.08), (0, 0, 0.04), "Plywood")
    n = 0
    for lvl, count in enumerate((4, 3, 2, 1)):
        for i in range(count):
            for j in range(count):
                x = (i - (count - 1) / 2) * 0.24
                y = (j - (count - 1) / 2) * 0.24
                _can(p, (x, y, 0.08 + lvl * 0.19), cols[(n + lvl) % 6])
                n += 1
    text_mesh(p, "SALE", 0.12, (0, 0.62, 0.3), "SignRed", depth=0.01, rot=(90, 0, 180))
    return p


@prop("paint_mixer", cat="store", body="static", col="box", inspect="ch3_insp_mixer", tags=["paint"], hazard=1)
def paint_mixer():
    p = Prop("paint_mixer")
    p.box((0.9, 0.7, 1.5), (0, 0, 0.75), "PaintGrey", bevel=0.03)
    p.box((0.7, 0.05, 0.5), (0, 0.36, 1.0), "ScreenGreen")
    p.box((0.6, 0.5, 0.06), (0, 0.1, 0.75), "PaintBlack")
    _can(p, (0, 0.1, 0.78), "PaintRed")
    p.cyl(0.03, 0.4, (0, 0.1, 1.15), "SteelDark", seg=8)
    for i, c in enumerate(["PaintRed", "PaintBlue", "PaintYellow", "PaintGreen"]):
        p.cyl(0.05, 0.16, (-0.3 + i * 0.2, -0.24, 1.58), c, seg=10)
    return p


@prop("paint_shaker", cat="store", body="static", col="box", inspect="ch3_insp_shaker", tags=["paint", "shaker"], hazard=1)
def paint_shaker():
    p = Prop("paint_shaker")
    p.box((0.6, 0.6, 0.5), (0, 0, 0.25), "PaintBlue", bevel=0.03)
    p.box((0.5, 0.5, 0.05), (0, 0, 0.52), "SteelDark")
    p.box((0.52, 0.52, 0.5), (0, 0, 0.8), "SteelGalv", bevel=0.02)
    _can(p, (0, 0, 0.56), "PaintRed")
    p.sph(0.03, (0.26, 0.31, 0.3), "LedGreen", seg=6)
    return p


@prop("shelving_unit", cat="store", body="static", col="box")
def shelving_unit():
    p = Prop("shelving_unit")
    for sx in (-0.95, 0.95):
        for sy in (-0.24, 0.24):
            p.box((0.05, 0.05, 2.4), (sx, sy, 1.2), "PaintBlue")
    for z in (0.15, 0.75, 1.35, 1.95):
        p.box((1.95, 0.5, 0.04), (0, 0, z), "SteelGalv")
    import random
    r = random.Random(9)
    for z in (0.15, 0.75, 1.35, 1.95):
        for i in range(6):
            c = r.choice(["Cardboard", "PlasticYellow", "PlasticRed", "PlasticBlue", "PlasticGreen", "PaintWhite"])
            h = r.uniform(0.18, 0.5)
            p.box((r.uniform(0.18, 0.3), 0.36, h), (-0.75 + i * 0.3, 0.0, z + 0.02 + h / 2), c)
    return p


@prop("lumber_bundle", cat="store", body="static", col="box")
def lumber_bundle():
    p = Prop("lumber_bundle")
    for i in range(4):
        for j in range(3):
            p.box((2.4, 0.09, 0.045), (0, -0.14 + i * 0.095, 0.05 + j * 0.05), "Lumber")
    p.box((0.05, 0.4, 0.16), (-0.6, 0, 0.08), "PlasticBlue")
    p.box((0.05, 0.4, 0.16), (0.6, 0, 0.08), "PlasticBlue")
    return p


@prop("pipe_bundle", cat="store", body="rigid", mass=25, grab="heavy", col="box")
def pipe_bundle():
    p = Prop("pipe_bundle")
    for i in range(3):
        for j in range(3 - i):
            p.cyl(0.05, 2.4, (-0.1 + i * 0.05 + j * 0.1, 0, 0.06 + i * 0.09), "PlasticGrey", rot=(90, 0, 0), seg=10)
    return p


@prop("flatbed_cart", cat="store", body="rigid", mass=40, grab="heavy", col="box", inspect="ch3_insp_cart", tags=["cart", "chain"], hazard=1)
def flatbed_cart():
    p = Prop("flatbed_cart")
    p.box((0.75, 1.6, 0.05), (0, 0, 0.22), "PaintBlue", bevel=0.01)
    p.box((0.75, 0.04, 0.8), (0, -0.8, 0.6), "PaintBlue")
    p.tube([(-0.35, -0.8, 0.9), (-0.35, -0.9, 1.05), (0.35, -0.9, 1.05), (0.35, -0.8, 0.9)], 0.015, "Chrome", seg=6)
    for sx in (-0.34, 0.34):
        for sy in (-0.6, 0.6):
            p.cyl(0.1, 0.05, (sx, sy, 0.1), "Rubber", rot=(0, 90, 0), seg=14)
    return p


@prop("hand_truck", cat="store", body="rigid", mass=12, grab="medium", col="box")
def hand_truck():
    p = Prop("hand_truck")
    p.box((0.05, 0.05, 1.1), (-0.17, -0.05, 0.6), "PaintRed")
    p.box((0.05, 0.05, 1.1), (0.17, -0.05, 0.6), "PaintRed")
    p.box((0.4, 0.3, 0.02), (0, 0.12, 0.06), "SteelGalv")
    for sx in (-0.24, 0.24):
        p.cyl(0.11, 0.05, (sx, -0.05, 0.11), "Rubber", rot=(0, 90, 0), seg=12)
    return p


@prop("wheelbarrow", cat="garden", body="rigid", mass=14, grab="medium", col="box", inspect="ch3_insp_wheelbarrow", tags=["wheelbarrow", "chain"], hazard=1)
def wheelbarrow():
    p = Prop("wheelbarrow")
    p.box((0.62, 0.8, 0.28), (0, 0.05, 0.45), "PaintGreen", bevel=0.05)
    p.cyl(0.19, 0.06, (0, 0.62, 0.22), "Rubber", rot=(0, 90, 0), seg=16)
    p.cyl(0.04, 0.09, (0, 0.62, 0.22), "SteelDark", rot=(0, 90, 0), seg=8)
    for sx in (-0.2, 0.2):
        p.tube([(sx, 0.4, 0.36), (sx, -0.3, 0.42), (sx, -0.75, 0.72)], 0.018, "WoodWarm", seg=6)
        p.box((0.04, 0.04, 0.4), (sx, -0.3, 0.2), "SteelDark")
    return p


@prop("tire", cat="store", body="rigid", mass=9, grab="medium", col="cylinder", inspect="ch3_insp_tire", tags=["tire", "chain"], hazard=1)
def tire():
    p = Prop("tire")
    # standing tire: axis along X, origin at floor centre
    p.lathe([(0.2, -0.11), (0.3, -0.11), (0.34, -0.08), (0.345, 0.0), (0.34, 0.08), (0.3, 0.11), (0.2, 0.11), (0.2, 0.06), (0.22, 0.0), (0.2, -0.06), (0.2, -0.11)],
            (0, 0, 0.345), "Rubber", rot=(0, 90, 0), seg=28, close_top=False)
    p.cyl(0.19, 0.16, (0, 0, 0.345), "Chrome", rot=(0, 90, 0), seg=20)
    for i in range(5):
        a = i * 72
        p.cyl(0.02, 0.17, (0, 0.11 * math.sin(math.radians(a)), 0.345 + 0.11 * math.cos(math.radians(a))), "SteelDark", rot=(0, 90, 0), seg=6)
    return p


@prop("tire_rack", cat="store", body="static", col="box", inspect="ch3_insp_tire", tags=["chain"], hazard=1)
def tire_rack():
    p = Prop("tire_rack")
    for sx in (-0.9, 0.9):
        p.box((0.06, 0.7, 2.2), (sx, 0, 1.1), "PaintOrange")
    for z in (0.05, 0.75, 1.45):
        p.box((1.9, 0.7, 0.05), (0, 0, z), "SteelGalv")
    for z in (0.05, 0.75, 1.45):
        for i in range(3):
            p.lathe([(0.15, -0.11), (0.3, -0.11), (0.34, 0.0), (0.3, 0.11), (0.15, 0.11)], (-0.6 + i * 0.6, 0, z + 0.36), "Rubber", rot=(0, 0, 0), seg=20)
    return p


@prop("ladder_step", cat="store", body="rigid", mass=8, grab="medium", col="box", inspect="ch3_insp_stepladder", tags=["ladder"], hazard=2)
def ladder_step():
    p = Prop("ladder_step")
    for s in (-1, 1):
        p.box((0.05, 0.04, 1.8), (s * 0.27, 0.36, 0.9), "PaintYellow", rot=(-12, 0, 0))
        p.box((0.05, 0.04, 1.8), (s * 0.27, -0.36, 0.9), "PaintYellow", rot=(12, 0, 0))
    for i in range(5):
        z = 0.3 + i * 0.32
        p.box((0.54, 0.16, 0.03), (0, 0.36 * (1 - z / 1.8) * 0.9, z), "SteelGalv")
    p.box((0.54, 0.4, 0.04), (0, 0, 1.78), "PaintYellow")
    return p


@prop("ladder_rolling", cat="store", body="rigid", mass=22, grab=None, col="box", inspect="ch3_insp_ladder", tags=["ladder", "chain"], hazard=2, use_verb="Set wheel brake")
def ladder_rolling():
    """Library ladder: leans against shelving along -Y... origin at foot, front faces +Y."""
    p = Prop("ladder_rolling")
    for s in (-1, 1):
        p.box((0.05, 0.05, 3.3), (s * 0.3, -0.35, 1.65), "SteelBrushed", rot=(-13, 0, 0))
        p.box((0.05, 0.05, 3.3), (s * 0.3, 0.0, 1.55), "SteelBrushed", rot=(-13, 0, 0))
    for i in range(9):
        z = 0.3 + i * 0.34
        p.box((0.6, 0.11, 0.03), (0, -0.05 - z * 0.23 - 0.06, z), "DiamondPlate")
    for s in (-1, 1):
        p.cyl(0.06, 0.05, (s * 0.3, 0.05, 0.06), "Rubber", rot=(0, 90, 0), seg=10)
        p.cyl(0.06, 0.05, (s * 0.3, -0.5, 0.06), "Rubber", rot=(0, 90, 0), seg=10)
    p.box((0.7, 0.08, 0.03), (0, -0.55, 3.25), "PaintRed")
    return p


@prop("saw_table", cat="store", body="static", col="box", inspect="ch3_insp_saw", tags=["saw"], hazard=2)
def saw_table():
    p = Prop("saw_table")
    p.box((1.0, 0.8, 0.9), (0, 0, 0.45), "PaintGrey", bevel=0.03)
    p.box((1.05, 0.85, 0.05), (0, 0, 0.92), "SteelBrushed")
    p.cyl(0.13, 0.008, (0, 0.02, 1.02), "Chrome", rot=(0, 90, 0), seg=28)
    p.box((0.02, 0.5, 0.03), (0.2, 0, 0.965), "PaintRed")
    p.box((0.16, 0.12, 0.12), (0.05, -0.32, 1.0), "PaintRed", bevel=0.02)
    p.sph(0.04, (0.32, 0.4, 1.0), "PaintRed", seg=8)
    return p


@prop("nailgun", cat="store", body="rigid", mass=1.4, grab="light", col="box", inspect="ch3_insp_nailgun", tags=["nailgun", "chain"], hazard=2, use_verb="Engage safety")
def nailgun():
    p = Prop("nailgun")
    p.box((0.06, 0.28, 0.1), (0, 0, 0.09), "PaintYellow", bevel=0.015)
    p.box((0.05, 0.06, 0.14), (0, -0.06, 0.0), "PaintBlack", bevel=0.01)
    p.box((0.03, 0.04, 0.02), (0, 0.16, 0.12), "SteelDark")
    p.box((0.02, 0.02, 0.06), (0, 0.13, 0.03), "PaintRed")
    p.tube([(0, -0.14, 0.09), (0, -0.4, 0.05), (0, -0.7, 0.02)], 0.012, "PlasticBlack", seg=6)
    return p


@prop("nailgun_rack", cat="store", body="static", col="box", tags=["nailgun"])
def nailgun_rack():
    p = Prop("nailgun_rack")
    p.box((1.2, 0.5, 1.4), (0, 0, 0.7), "PaintYellow", bevel=0.02)
    p.box((1.1, 0.02, 1.0), (0, 0.26, 0.7), "PaintBlack")
    p.box((1.2, 0.04, 0.3), (0, 0.0, 1.55), "PaintRed")
    text_mesh(p, "POWER TOOLS", 0.08, (0, 0.03, 1.55), "PaintWhite", depth=0.006, rot=(90, 0, 180))
    return p


@prop("air_compressor", cat="store", body="static", col="box", inspect="ch3_insp_compressor", tags=["compressor", "chain"], hazard=1, use_verb="Close air valve")
def air_compressor():
    p = Prop("air_compressor")
    p.cyl(0.24, 0.9, (0, 0, 0.6), "PaintRed", rot=(0, 90, 0), seg=18)
    p.box((0.16, 0.5, 0.06), (0, 0, 0.98), "PaintBlack")
    p.box((0.4, 0.25, 0.2), (-0.45, 0, 0.3), "PaintBlack", bevel=0.02)
    for sx in (-0.4, 0.4):
        p.cyl(0.09, 0.05, (sx, 0.24, 0.09), "Rubber", rot=(0, 90, 0), seg=10)
    p.cyl(0.035, 0.05, (0.3, 0.26, 0.85), "SignRed", rot=(90, 0, 0), seg=10)
    p.tube([(0.5, 0.05, 0.6), (0.6, 0.3, 0.4), (0.7, 0.6, 0.15)], 0.015, "PlasticBlack", seg=6)
    return p


@prop("power_strip", cat="store", body="rigid", mass=0.6, grab="light", col="box", inspect="ch3_insp_strip", tags=["strip", "chain", "electric"], hazard=1, use_verb="Unplug")
def power_strip():
    p = Prop("power_strip")
    p.box((0.38, 0.09, 0.04), (0, 0, 0.02), "PaintWhite", bevel=0.01)
    for i in range(6):
        p.box((0.04, 0.005, 0.02), (-0.14 + i * 0.056, 0.047, 0.025), "PaintBlack")
    p.box((0.03, 0.02, 0.012), (0.16, 0.048, 0.037), "LedRed")
    p.tube([(-0.19, 0, 0.02), (-0.4, 0.1, 0.01), (-0.9, 0.05, 0.008)], 0.006, "PlasticBlack", seg=5)
    p.box((0.04, 0.03, 0.02), (-0.92, 0.05, 0.012), "PlasticBlack")
    return p


@prop("plug_cord", cat="store", body="none", col="none")
def plug_cord():
    p = Prop("plug_cord")
    p.tube([(0, 0, 0.0), (0.3, 0.05, 0.005), (0.8, 0.0, 0.006), (1.4, 0.1, 0.005)], 0.006, "PlasticBlack", seg=5)
    return p


@prop("drill", cat="store", body="rigid", mass=1.2, grab="light", col="box")
def drill():
    p = Prop("drill")
    p.box((0.06, 0.2, 0.08), (0, 0.04, 0.12), "PaintYellow", bevel=0.015)
    p.box((0.05, 0.06, 0.12), (0, -0.02, 0.05), "PaintBlack", bevel=0.01)
    p.cyl(0.006, 0.09, (0, 0.18, 0.12), "Chrome", rot=(90, 0, 0), seg=6)
    return p


@prop("hammer", cat="store", body="rigid", mass=0.9, grab="light", col="box")
def hammer():
    p = Prop("hammer")
    p.cyl(0.015, 0.32, (0, 0, 0.02), "WoodWarm", rot=(90, 0, 0), seg=8)
    p.box((0.15, 0.04, 0.045), (0, 0.16, 0.03), "SteelDark", bevel=0.005)
    return p


@prop("wrench", cat="store", body="rigid", mass=0.8, grab="light", col="box", tags=["wrench", "tool"])
def wrench():
    p = Prop("wrench")
    p.box((0.03, 0.34, 0.012), (0, 0, 0.008), "SteelBrushed", bevel=0.003)
    p.cyl(0.032, 0.014, (0, 0.18, 0.008), "SteelBrushed", seg=12)
    p.box((0.03, 0.05, 0.016), (0, 0.2, 0.008), "PaintBlack")
    return p


@prop("crowbar", cat="store", body="rigid", mass=1.5, grab="light", col="box")
def crowbar():
    p = Prop("crowbar")
    p.tube([(0, -0.35, 0.012), (0, 0.25, 0.012), (0, 0.32, 0.06)], 0.012, "SteelDark", seg=6)
    return p


@prop("toolbox", cat="store", body="rigid", mass=4, grab="medium", col="box")
def toolbox():
    p = Prop("toolbox")
    p.box((0.5, 0.22, 0.2), (0, 0, 0.1), "PaintRed", bevel=0.02)
    p.tube([(-0.18, 0, 0.2), (-0.18, 0, 0.28), (0.18, 0, 0.28), (0.18, 0, 0.2)], 0.012, "SteelDark", seg=6)
    return p


@prop("ceiling_fan", cat="store", body="none", col="none", inspect="ch3_insp_fan", tags=["fan", "chain"], hazard=2)
def ceiling_fan():
    """Origin at the ceiling attachment; hangs down -Z."""
    p = Prop("ceiling_fan")
    p.cyl(0.02, 0.5, (0, 0, -0.25), "SteelBrushed", seg=6)
    p.cyl(0.12, 0.12, (0, 0, -0.56), "PaintBlack", seg=14)
    for i in range(5):
        a = i * 72
        p.box((0.6, 0.13, 0.012), (0.34 * math.cos(math.radians(a)), 0.34 * math.sin(math.radians(a)), -0.6), "WoodWarm", rot=(0, 0, a - 90 + 90))
    p.cyl(0.08, 0.06, (0, 0, -0.66), "LightWarm", seg=12)
    return p


@prop("fan_rack", cat="store", body="static", col="box", tags=["fan", "chain"])
def fan_rack():
    p = Prop("fan_rack")
    p.box((2.6, 0.08, 0.08), (0, 0, 3.2), "PaintBlack")
    for sx in (-1.25, 1.25):
        p.box((0.08, 0.08, 3.2), (sx, 0, 1.6), "PaintBlack")
    p.box((2.6, 0.9, 0.05), (0, 0, 0.03), "PaintGrey")
    return p


@prop("sale_banner", cat="store", body="none", col="none", inspect="ch3_insp_banner", tags=["chain"], hazard=1)
def sale_banner():
    p = Prop("sale_banner")
    p.box((3.0, 0.02, 0.8), (0, 0, 0), "SignRed", bevel=0.005)
    text_mesh(p, "MEGA SALE", 0.34, (0, 0.02, 0), "PaintWhite", depth=0.006, rot=(90, 0, 180))
    p.tube([(-1.4, 0, 0.4), (-1.4, 0, 1.2)], 0.008, "PlasticBlack", seg=4)
    p.tube([(1.4, 0, 0.4), (1.4, 0, 1.2)], 0.008, "PlasticBlack", seg=4)
    return p


@prop("sprinkler_display", cat="garden", body="static", col="box", inspect="ch3_insp_sprinkler", tags=["sprinkler", "chain"], hazard=1)
def sprinkler_display():
    p = Prop("sprinkler_display")
    p.box((1.4, 0.5, 0.9), (0, 0, 0.45), "PaintGreen", bevel=0.02)
    for i in range(5):
        p.cyl(0.02, 0.35, (-0.5 + i * 0.25, 0, 1.05), "Chrome", seg=6)
        p.sph(0.04, (-0.5 + i * 0.25, 0, 1.24), "PaintBlack", seg=8)
    p.box((1.3, 0.04, 0.3), (0, 0.27, 0.6), "PaintWhite")
    return p


@prop("hose_reel", cat="garden", body="rigid", mass=8, grab="medium", col="cylinder", inspect="ch3_insp_hose", tags=["hose", "chain"], hazard=1)
def hose_reel():
    p = Prop("hose_reel")
    p.cyl(0.3, 0.32, (0, 0, 0.32), "PaintGreen", rot=(0, 90, 0), seg=18)
    p.cyl(0.32, 0.03, (0.18, 0, 0.32), "PaintBlack", rot=(0, 90, 0), seg=18)
    p.cyl(0.32, 0.03, (-0.18, 0, 0.32), "PaintBlack", rot=(0, 90, 0), seg=18)
    p.box((0.5, 0.04, 0.05), (0, 0, 0.03), "PaintBlack")
    p.tube([(0.2, 0.0, 0.32), (0.4, 0.4, 0.05), (0.7, 0.9, 0.02)], 0.014, "PaintGreen", seg=6)
    return p


@prop("fertilizer_bag", cat="garden", body="rigid", mass=15, grab="medium", col="box")
def fertilizer_bag():
    p = Prop("fertilizer_bag")
    p.box((0.5, 0.32, 0.12), (0, 0, 0.07), "PaintGreen", bevel=0.05)
    text_mesh(p, "GROW", 0.07, (0, 0.17, 0.08), "PaintWhite", depth=0.004, rot=(90, 0, 180))
    return p


@prop("propane_cylinder", cat="garden", body="rigid", mass=8, grab="medium", col="cylinder", inspect="ch3_insp_propane", tags=["propane"], hazard=2)
def propane_cylinder():
    p = Prop("propane_cylinder")
    p.lathe([(0.0, 0.0), (0.16, 0.0), (0.185, 0.04), (0.185, 0.4), (0.16, 0.46), (0.06, 0.5), (0.0, 0.5)], (0, 0, 0.0), "PaintWhite", seg=20, close_top=True, close_bottom=True)
    p.cyl(0.07, 0.06, (0, 0, 0.53), "Brass", seg=10)
    p.cyl(0.13, 0.03, (0, 0, 0.02), "PaintWhite", seg=16)
    text_mesh(p, "PROPANE", 0.05, (0, 0.187, 0.24), "PaintRed", depth=0.003, rot=(90, 0, 180))
    return p


@prop("propane_cage", cat="garden", body="static", col="box", tags=["propane"])
def propane_cage():
    p = Prop("propane_cage")
    for sx in (-0.7, 0.7):
        for sy in (-0.4, 0.4):
            p.box((0.05, 0.05, 1.5), (sx, sy, 0.75), "PaintYellow")
    for z in (0.2, 0.75, 1.45):
        for k in (-0.4, 0.4):
            p.box((1.45, 0.03, 0.03), (0, k, z), "PaintYellow")
        for k in (-0.7, 0.7):
            p.box((0.03, 0.83, 0.03), (k, 0, z), "PaintYellow")
    p.box((1.5, 0.9, 0.05), (0, 0, 0.03), "SteelGalv")
    return p


@prop("flamingo", cat="garden", body="rigid", mass=1.4, grab="light", col="box", inspect="ch3_insp_flamingo", tags=["flamingo"])
def flamingo():
    p = Prop("flamingo")
    p.tube([(0, 0, 0.0), (0, 0, 0.42)], 0.007, "SteelDark", seg=5)
    p.tube([(0, 0, 0.0), (0.02, 0, 0.42)], 0.007, "SteelDark", seg=5)
    p.sph(0.1, (0, 0, 0.55), "PlasticPink", seg=12, scale=(0.9, 1.5, 1.0))
    p.tube([(0, 0.09, 0.6), (0, 0.15, 0.8), (0, 0.07, 0.98), (0, 0.13, 1.06)], 0.016, "PlasticPink", seg=8, r_end=0.012)
    p.sph(0.028, (0, 0.14, 1.09), "PlasticPink", seg=8)
    p.cyl(0.012, 0.09, (0, 0.2, 1.08), "PaintBlack", rot=(-80, 0, 0), seg=6)
    p.sph(0.006, (0.02, 0.15, 1.1), "PaintBlack", seg=4)
    p.sph(0.006, (-0.02, 0.15, 1.1), "PaintBlack", seg=4)
    p.sph(0.06, (0, -0.1, 0.62), "PlasticPink", seg=8, scale=(0.7, 1.5, 0.7))
    return p


@prop("flamingo_red", cat="garden", body="rigid", mass=1.4, grab="light", col="box", inspect="ch3_insp_flamingo", tags=["flamingo"])
def flamingo_red():
    p = flamingo()
    p.name = "flamingo_red"
    for i, m in enumerate(p.mats):
        if m == "PlasticPink":
            p.mats[i] = "Paint"
    return p


@prop("flamingo_pallet", cat="garden", body="rigid", mass=60, grab=None, col="box", tags=["flamingo", "chain"])
def flamingo_pallet():
    p = Prop("flamingo_pallet")
    p.box((1.2, 1.0, 0.12), (0, 0, 0.06), "Plywood")
    import random
    r = random.Random(5)
    for i in range(4):
        for j in range(3):
            for k in range(2):
                x, y = -0.42 + i * 0.28, -0.32 + j * 0.32
                p.sph(0.09, (x, y, 0.28 + k * 0.28), "PlasticPink", seg=8, scale=(0.8, 1.3, 0.9))
                p.tube([(x, y + 0.05, 0.3 + k * 0.28), (x, y + 0.12, 0.42 + k * 0.28)], 0.014, "PlasticPink", seg=5)
    p.box((1.25, 1.05, 0.02), (0, 0, 0.62), "PaintWhite")
    return p


@prop("corn_dog_cart", cat="garden", body="static", col="box", inspect="ch3_insp_fryer", tags=["fryer"], hazard=2)
def corn_dog_cart():
    p = Prop("corn_dog_cart")
    p.box((1.4, 0.8, 0.85), (0, 0, 0.5), "PaintYellow", bevel=0.03)
    p.box((1.0, 0.5, 0.05), (0, 0, 0.95), "SteelBrushed")
    p.box((0.9, 0.4, 0.08), (0, 0, 0.96), "Oil")
    p.cyl(0.03, 2.0, (0.65, -0.35, 1.5), "PaintRed", seg=6)
    p.cyl(0.03, 2.0, (-0.65, -0.35, 1.5), "PaintRed", seg=6)
    p.box((1.6, 1.0, 0.06), (0, -0.05, 2.5), "PaintRed", bevel=0.01)
    text_mesh(p, "CORN DOGS", 0.16, (0, 0.46, 0.95), "PaintRed", depth=0.005, rot=(90, 0, 180))
    for sx in (-0.5, 0.5):
        p.cyl(0.11, 0.05, (sx, 0.35, 0.12), "Rubber", rot=(0, 90, 0), seg=10)
    return p


@prop("forklift", cat="store", body="static", col="box", inspect="ch3_insp_forklift", tags=["forklift", "chain"], hazard=1)
def forklift():
    """Front (forks) toward +Y."""
    p = Prop("forklift")
    p.box((1.15, 2.0, 0.9), (0, -0.25, 0.65), "PaintOrange", bevel=0.05)
    p.box((1.1, 0.8, 0.3), (0, -0.85, 1.25), "PaintOrange", bevel=0.03)
    p.box((0.05, 0.05, 1.3), (-0.5, 0.2, 1.65), "PaintBlack")
    p.box((0.05, 0.05, 1.3), (0.5, 0.2, 1.65), "PaintBlack")
    p.box((1.15, 1.0, 0.05), (0, -0.35, 2.3), "PaintBlack")
    for sx in (-0.47, 0.47):
        p.cyl(0.32, 0.22, (sx, 0.4, 0.32), "Rubber", rot=(0, 90, 0), seg=16)
        p.cyl(0.26, 0.2, (sx, -0.9, 0.26), "Rubber", rot=(0, 90, 0), seg=16)
    # mast + forks (raised)
    for sx in (-0.42, 0.42):
        p.box((0.07, 0.07, 3.3), (sx, 0.85, 1.8), "SteelDark")
    for sx in (-0.4, 0.4):
        p.box((0.11, 1.2, 0.05), (sx, 1.4, 3.05), "SteelBrushed")
    p.box((1.0, 0.04, 0.3), (0, 0.92, 3.1), "SteelDark")
    p.box((0.14, 0.14, 0.24), (0.55, 0.25, 1.8), "PaintRed", bevel=0.02)          # red emergency lowering handle
    p.mark("handle", (0.55, 0.25, 1.85))
    p.mark("pallet", (0, 1.4, 3.1))
    p.sph(0.06, (0, -0.9, 2.4), "LightWarm", seg=8)
    return p


@prop("forklift_handle", cat="store", body="static", col="box", inspect="ch3_insp_handle", tags=["handle", "chain"], hazard=1, use_verb="Pin the handle")
def forklift_handle():
    p = Prop("forklift_handle")
    p.box((0.06, 0.06, 0.22), (0, 0, 0.11), "PaintRed", bevel=0.012)
    p.sph(0.05, (0, 0, 0.24), "PaintRed", seg=8)
    return p


@prop("pallet", cat="store", body="rigid", mass=18, grab="heavy", col="box")
def pallet():
    p = Prop("pallet")
    for y in (-0.42, 0, 0.42):
        p.box((1.2, 0.1, 0.09), (0, y, 0.07), "Plywood")
    for x in (-0.55, 0, 0.55):
        p.box((0.1, 1.0, 0.03), (x, 0, 0.14), "Plywood")
    return p


@prop("checkout_lane", cat="store", body="static", col="box")
def checkout_lane():
    p = Prop("checkout_lane")
    p.box((0.8, 2.6, 0.9), (0, 0, 0.45), "PaintGrey", bevel=0.02)
    p.box((0.82, 2.6, 0.04), (0, 0, 0.92), "Concrete")
    p.box((0.4, 0.4, 0.3), (0.05, -0.8, 1.1), "PaintBlack", bevel=0.02)
    p.box((0.3, 0.02, 0.2), (0.05, -0.61, 1.15), "ScreenGreen")
    p.box((0.08, 0.7, 0.03), (0, 0.5, 0.95), "Rubber")
    p.cyl(0.02, 1.9, (-0.3, -1.0, 1.3), "SteelDark", seg=6)
    p.box((0.4, 0.06, 0.28), (-0.3, -1.0, 2.2), "SignYellow")
    return p


@prop("shopping_cart", cat="store", body="rigid", mass=12, grab="heavy", col="box")
def shopping_cart():
    p = Prop("shopping_cart")
    p.box((0.55, 0.9, 0.05), (0, 0, 0.35), "SteelBrushed")
    for s in (-1, 1):
        p.box((0.02, 0.9, 0.35), (s * 0.27, 0, 0.55), "SteelBrushed")
    p.box((0.55, 0.02, 0.35), (0, 0.45, 0.55), "SteelBrushed")
    p.tube([(-0.27, -0.45, 0.72), (-0.27, -0.55, 0.9), (0.27, -0.55, 0.9), (0.27, -0.45, 0.72)], 0.014, "PaintRed", seg=5)
    for sx in (-0.24, 0.24):
        for sy in (-0.38, 0.38):
            p.cyl(0.05, 0.03, (sx, sy, 0.06), "Rubber", rot=(0, 90, 0), seg=8)
    return p


@prop("aisle_sign", cat="signs", body="none", col="none")
def aisle_sign():
    p = Prop("aisle_sign")
    p.box((1.4, 0.05, 0.5), (0, 0, 0), "PaintOrange", bevel=0.01)
    p.tube([(-0.5, 0, 0.25), (-0.5, 0, 0.6)], 0.006, "PlasticBlack", seg=4)
    p.tube([(0.5, 0, 0.25), (0.5, 0, 0.6)], 0.006, "PlasticBlack", seg=4)
    return p


@prop("garden_gnome", cat="garden", body="rigid", mass=3, grab="light", col="box", inspect="ch3_insp_gnome")
def garden_gnome():
    p = Prop("garden_gnome")
    p.cyl(0.1, 0.3, (0, 0, 0.15), "PaintBlue", seg=10, r2=0.08)
    p.sph(0.07, (0, 0, 0.36), "Skin", seg=8)
    p.cyl(0.08, 0.2, (0, 0, 0.5), "PaintRed", seg=10, r2=0.005)
    p.sph(0.05, (0, 0.05, 0.3), "PaintWhite", seg=8, scale=(1, 0.7, 1.4))
    return p


@prop("lawn_mower", cat="garden", body="rigid", mass=22, grab="heavy", col="box", inspect="ch3_insp_mower")
def lawn_mower():
    p = Prop("lawn_mower")
    p.box((0.5, 0.6, 0.22), (0, 0.1, 0.28), "PaintRed", bevel=0.05)
    p.tube([(-0.18, -0.15, 0.4), (-0.2, -0.5, 0.95), (0.2, -0.5, 0.95), (0.18, -0.15, 0.4)], 0.014, "SteelDark", seg=6)
    for sx in (-0.24, 0.24):
        p.cyl(0.09, 0.05, (sx, 0.32, 0.1), "Rubber", rot=(0, 90, 0), seg=10)
        p.cyl(0.11, 0.05, (sx, -0.1, 0.11), "Rubber", rot=(0, 90, 0), seg=10)
    return p


@prop("tripod", cat="store", body="rigid", mass=1.5, grab="light", col="box", inspect="ch3_insp_tripod", tags=["tripod", "chain"], hazard=1)
def tripod():
    p = Prop("tripod")
    for a in (0, 120, 240):
        p.tube([(0, 0, 1.15), (0.35 * math.cos(math.radians(a)), 0.35 * math.sin(math.radians(a)), 0.0)], 0.012, "PlasticBlack", seg=5)
    p.box((0.09, 0.05, 0.14), (0, 0, 1.22), "PaintBlack")
    p.box((0.075, 0.009, 0.155), (0, 0.03, 1.3), "PaintBlack")
    p.sph(0.012, (0, 0.036, 1.36), "LedRed", seg=6)
    return p


@prop("coin", cat="store", body="rigid", mass=0.02, grab="light", col="cylinder", inspect="ch3_insp_coin", tags=["coin", "chain", "fetch"], hazard=1)
def coin():
    p = Prop("coin")
    p.cyl(0.013, 0.003, (0, 0, 0.0015), "Brass", seg=14)
    return p


@prop("shoe", cat="store", body="rigid", mass=0.5, grab="light", col="box")
def shoe():
    p = Prop("shoe")
    p.box((0.1, 0.27, 0.09), (0, 0, 0.045), "ShoeBrown", bevel=0.03)
    p.box((0.105, 0.28, 0.02), (0, 0, 0.01), "Sole")
    return p


@prop("bucket", cat="store", body="rigid", mass=1.2, grab="light", col="cylinder")
def bucket():
    p = Prop("bucket")
    p.cyl(0.16, 0.3, (0, 0, 0.15), "PaintOrange", seg=14, r2=0.13)
    p.tube([(-0.16, 0, 0.3), (0, 0, 0.42), (0.16, 0, 0.3)], 0.006, "SteelDark", seg=5)
    return p


@prop("chain_hoist", cat="store", body="none", col="none", inspect="ch3_insp_chain", hazard=2)
def chain_hoist():
    p = Prop("chain_hoist")
    p.tube([(0, 0, 0.0), (0, 0, -0.7)], 0.012, "SteelDark", seg=5)
    p.box((0.16, 0.16, 0.22), (0, 0, -0.85), "PaintYellow", bevel=0.02)
    p.tube([(0, 0, -0.95), (0, 0, -1.6)], 0.008, "SteelDark", seg=5)
    p.tube([(0, 0, -1.6), (0.08, 0, -1.7), (0, 0, -1.78)], 0.012, "SteelDark", seg=5)
    return p


@prop("extension_cord_floor", cat="store", body="none", col="none", inspect="ch3_insp_cord")
def extension_cord_floor():
    p = Prop("extension_cord_floor")
    p.tube([(-1.5, 0, 0.012), (-0.6, 0.15, 0.012), (0.4, -0.1, 0.012), (1.5, 0.05, 0.012)], 0.011, "PaintOrange", seg=5)
    return p


@prop("phone_selfie", cat="store", body="rigid", mass=0.3, grab="light", col="box", tags=["phone"])
def phone_selfie():
    p = Prop("phone_selfie")
    p.box((0.075, 0.15, 0.009), (0, 0, 0.0045), "PaintBlack", bevel=0.008)
    p.tube([(0, -0.07, 0.0), (0, -0.3, 0.06)], 0.008, "PlasticBlack", seg=5)
    return p
