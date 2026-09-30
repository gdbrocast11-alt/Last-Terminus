"""Residential street / ending props. Origin = floor centre, front faces +Y."""
import math
from props_registry import prop, text_mesh
from lt_lib import Prop, Vector


@prop("house_facade", cat="street", body="static", col="box")
def house_facade():
    p = Prop("house_facade")
    p.box((8.0, 7.0, 6.2), (0, 0, 3.1), "Brick", bevel=0.02)
    p.box((8.4, 7.4, 0.3), (0, 0, 6.35), "PaintGrey")
    p.extrude_poly([(-4.2, 6.2), (4.2, 6.2), (0, 8.6)], 7.4, (0, 0, 0), "PaintGrey", plane="XZ")
    p.box((1.1, 0.12, 2.1), (-1.6, 3.55, 1.05), "WoodDark")
    p.sph(0.05, (-1.25, 3.62, 1.0), "Brass", seg=6)
    for x in (1.4, 3.0):
        p.box((1.1, 0.1, 1.3), (x, 3.55, 1.7), "GlassTint")
        p.box((1.25, 0.14, 0.08), (x, 3.55, 1.02), "PaintWhite")
    for x in (-2.8, -0.4, 2.0):
        p.box((1.1, 0.1, 1.3), (x, 3.55, 4.4), "GlassTint")
        p.box((1.25, 0.14, 0.08), (x, 3.55, 3.72), "PaintWhite")
    p.box((2.4, 1.2, 0.12), (-1.6, 4.1, 0.9), "Concrete")
    return p


@prop("picket_fence", cat="street", body="static", col="box")
def picket_fence():
    p = Prop("picket_fence")
    for i in range(14):
        p.box((0.08, 0.03, 0.9), (-3.25 + i * 0.5, 0, 0.45), "PaintWhite")
    p.box((7.0, 0.05, 0.06), (0, 0, 0.3), "PaintWhite")
    p.box((7.0, 0.05, 0.06), (0, 0, 0.7), "PaintWhite")
    return p


@prop("mailbox", cat="street", body="static", col="box")
def mailbox():
    p = Prop("mailbox")
    p.cyl(0.03, 1.1, (0, 0, 0.55), "WoodDark", seg=6)
    p.box((0.2, 0.45, 0.22), (0, 0, 1.2), "PaintBlue", bevel=0.05)
    return p


@prop("tree_street", cat="street", body="static", col="cylinder")
def tree_street():
    p = Prop("tree_street")
    p.cyl(0.22, 3.2, (0, 0, 1.6), "WoodDark", seg=10, r2=0.16)
    for i, (x, y, z, r) in enumerate(((0, 0, 4.4, 1.6), (0.9, 0.3, 3.7, 1.1), (-0.9, -0.4, 3.9, 1.2), (0.2, -0.9, 4.0, 1.0), (-0.3, 0.9, 4.1, 1.0))):
        p.sph(r, (x, y, z), "PaintGreen", seg=8)
    return p


@prop("street_lamp", cat="street", body="static", col="cylinder")
def street_lamp():
    p = Prop("street_lamp")
    p.cyl(0.07, 4.6, (0, 0, 2.3), "PaintBlack", seg=8)
    p.tube([(0, 0, 4.6), (0.4, 0, 4.85), (0.9, 0, 4.75)], 0.05, "PaintBlack", seg=6)
    p.box((0.4, 0.18, 0.08), (0.95, 0, 4.7), "PaintBlack")
    p.box((0.32, 0.13, 0.02), (0.95, 0, 4.65), "LightWarm")
    return p


@prop("traffic_signal", cat="street", body="static", col="cylinder", tags=["signal"])
def traffic_signal():
    """Pedestrian signal pole. Head faces +Y. WALK lamp is a separate marker."""
    p = Prop("traffic_signal")
    p.cyl(0.06, 3.2, (0, 0, 1.6), "PaintGrey", seg=8)
    p.box((0.4, 0.22, 0.55), (0, 0.1, 2.9), "PaintBlack", bevel=0.03)
    p.box((0.28, 0.02, 0.2), (0, 0.22, 3.05), "SignWhite")
    text_mesh(p, "WALK", 0.07, (0, 0.235, 3.05), "PaintBlack", depth=0.004, rot=(90, 0, 180))
    p.box((0.28, 0.02, 0.2), (0, 0.22, 2.78), "SignRed")
    p.box((0.16, 0.16, 0.22), (0.14, 0.05, 1.2), "PaintBlack")
    p.mark("walk_lamp", (0, 0.23, 3.05))
    return p


@prop("bus", cat="vehicles", body="rigid", mass=9000, grab=None, col="box", tags=["bus", "finale"])
def bus():
    p = Prop("bus")
    p.box((2.5, 11.0, 2.9), (0, 0, 1.9), "PaintTeal", bevel=0.25)
    p.box((2.52, 11.02, 0.9), (0, 0, 0.75), "PaintWhite")
    p.box((2.54, 11.04, 0.12), (0, 0, 1.4), "PaintYellow")
    p.box((2.4, 0.06, 1.2), (0, 5.5, 2.3), "GlassTint")
    for s in (-1, 1):
        for i in range(7):
            p.box((0.05, 1.1, 0.9), (s * 1.26, -4.2 + i * 1.35, 2.35), "GlassTint")
        p.box((0.06, 1.0, 2.0), (s * 1.27, 4.0, 1.5), "PaintBlack")
    p.box((2.0, 0.1, 0.4), (0, 5.52, 3.1), "ScreenGreen")
    text_mesh(p, "END OF LINE", 0.2, (0, 5.56, 3.1), "SignYellow", depth=0.004, rot=(90, 0, 180))
    for sx in (-1.15, 1.15):
        for sy in (3.4, -3.4):
            p.cyl(0.55, 0.3, (sx, sy, 0.55), "Rubber", rot=(0, 90, 0), seg=20)
            p.cyl(0.28, 0.32, (sx, sy, 0.55), "SteelBrushed", rot=(0, 90, 0), seg=12)
    for sx in (-0.85, 0.85):
        p.sph(0.12, (sx, 5.52, 0.95), "LightTube", seg=8)
    p.box((1.0, 0.1, 0.25), (0, 5.55, 0.32), "PaintBlack")
    p.box((2.3, 2.0, 0.15), (0, 0, 3.45), "PaintWhite")
    p.mark("front_axle", (0, 3.4, 0.55))
    return p


@prop("sedan", cat="vehicles", body="static", col="box")
def sedan():
    p = Prop("sedan")
    p.box((1.8, 4.4, 0.7), (0, 0, 0.7), "PaintBlue", bevel=0.12)
    p.box((1.6, 2.2, 0.6), (0, -0.2, 1.2), "PaintBlue", bevel=0.15)
    p.box((1.55, 0.05, 0.5), (0, 0.9, 1.2), "GlassTint")
    p.box((1.55, 0.05, 0.5), (0, -1.3, 1.2), "GlassTint")
    for s in (-1, 1):
        p.box((0.04, 1.8, 0.45), (s * 0.81, -0.2, 1.2), "GlassTint")
        for sy in (1.4, -1.4):
            p.cyl(0.33, 0.24, (s * 0.85, sy, 0.33), "Rubber", rot=(0, 90, 0), seg=14)
            p.cyl(0.17, 0.26, (s * 0.85, sy, 0.33), "SteelBrushed", rot=(0, 90, 0), seg=10)
    return p


@prop("pipe_truck", cat="vehicles", body="rigid", mass=3500, grab=None, col="box", inspect="ch8_truck", tags=["truck", "hazard_street"], hazard=1)
def pipe_truck():
    p = Prop("pipe_truck")
    p.box((2.2, 2.0, 1.3), (0, 2.2, 1.1), "PaintOrange", bevel=0.1)
    p.box((2.0, 0.05, 0.6), (0, 3.2, 1.5), "GlassTint")
    p.box((2.2, 5.0, 0.3), (0, -1.0, 0.75), "PaintGrey")
    for i in range(4):
        for j in range(3):
            p.cyl(0.13, 5.8, (-0.6 + i * 0.4, -1.4, 1.1 + j * 0.28), "PlasticGrey", rot=(90, 0, 0), seg=10)
    for sx in (-1.05, 1.05):
        for sy in (2.2, -1.0, -2.6):
            p.cyl(0.5, 0.3, (sx, sy, 0.5), "Rubber", rot=(0, 90, 0), seg=16)
    return p


@prop("excavator_mini", cat="street", body="static", col="box", inspect="ch8_dig", tags=["hazard_street"], hazard=1)
def excavator_mini():
    p = Prop("excavator_mini")
    p.box((1.6, 2.4, 0.5), (0, 0, 0.35), "PaintBlack")
    p.box((1.4, 1.3, 0.9), (0, -0.3, 1.0), "PaintYellow", bevel=0.05)
    p.box((1.0, 0.6, 0.9), (0, 0.3, 1.4), "GlassTint")
    p.tube([(0, 0.7, 0.9), (0, 1.6, 2.4), (0, 2.5, 2.0)], 0.13, "PaintYellow", seg=6)
    p.box((0.6, 0.6, 0.5), (0, 2.5, 1.7), "SteelDark", bevel=0.05)
    return p


@prop("bicycle", cat="street", body="rigid", mass=12, grab="heavy", col="box", inspect="ch8_cyclist")
def bicycle():
    p = Prop("bicycle")
    for sy in (0.55, -0.55):
        p.lathe([(0.32, -0.02), (0.34, 0.0), (0.32, 0.02)], (0, sy, 0.34), "Rubber", rot=(0, 90, 0), seg=20)
    p.tube([(0, 0.55, 0.34), (0, 0.2, 0.62), (0, -0.15, 0.7), (0, -0.55, 0.34)], 0.014, "PaintRed", seg=5)
    p.tube([(0, 0.2, 0.62), (0, 0.45, 0.95)], 0.014, "PaintRed", seg=5)
    p.tube([(-0.25, 0.45, 0.95), (0.25, 0.45, 0.95)], 0.012, "SteelDark", seg=5)
    p.box((0.1, 0.2, 0.05), (0, -0.2, 0.78), "PaintBlack")
    return p


@prop("baseball", cat="street", body="rigid", mass=0.15, grab="light", col="sphere", tags=["fetch"])
def baseball():
    p = Prop("baseball")
    p.sph(0.037, (0, 0, 0.037), "PaintWhite", seg=10)
    p.tube([(-0.02, 0.03, 0.05), (0, 0.037, 0.07), (0.02, 0.03, 0.05)], 0.003, "PaintRed", seg=4)
    return p


@prop("ac_unit", cat="street", body="static", col="box", inspect="ch8_ac", tags=["hazard_street"], hazard=1)
def ac_unit():
    p = Prop("ac_unit")
    p.box((0.7, 0.5, 0.45), (0, 0, 0.225), "PaintWhite", bevel=0.03)
    p.box((0.6, 0.02, 0.3), (0, 0.26, 0.22), "PaintGrey")
    return p


@prop("bottle_glass", cat="street", body="rigid", mass=0.4, grab="light", col="cylinder", inspect="ch8_bottle", tags=["hazard_street"], hazard=1)
def bottle_glass():
    p = Prop("bottle_glass")
    p.lathe([(0.0, 0.0), (0.035, 0.0), (0.04, 0.02), (0.04, 0.15), (0.03, 0.2), (0.012, 0.26), (0.012, 0.3), (0.0, 0.3)], (0, 0, 0), "PlasticGreen", seg=12)
    return p


@prop("hydrant", cat="street", body="static", col="cylinder")
def hydrant():
    p = Prop("hydrant")
    p.cyl(0.12, 0.6, (0, 0, 0.3), "PaintRed", seg=10)
    p.sph(0.13, (0, 0, 0.65), "PaintRed", seg=8)
    p.cyl(0.05, 0.4, (0, 0, 0.42), "PaintRed", rot=(0, 90, 0), seg=8)
    return p


@prop("bus_stop_shelter", cat="street", body="static", col="box")
def bus_stop_shelter():
    p = Prop("bus_stop_shelter")
    for sx in (-1.4, 1.4):
        p.box((0.06, 0.06, 2.4), (sx, -0.5, 1.2), "PaintGrey")
    p.box((3.0, 1.3, 0.08), (0, -0.05, 2.4), "PaintGrey")
    p.box((2.8, 0.03, 1.6), (0, -0.55, 1.2), "GlassTint")
    p.box((2.0, 0.4, 0.05), (0, -0.35, 0.5), "PaintGrey")
    return p


@prop("terminus_sign_street", cat="street", body="none", col="none", tags=["hero", "finale"])
def terminus_sign_street():
    """Stand-alone frame. The letters are separate props (sign_letter) placed by the level."""
    p = Prop("terminus_sign_street")
    p.box((10.0, 0.5, 0.3), (0, 0, 0.15), "Concrete")
    for sx in (-4.8, 4.8):
        p.box((0.3, 0.4, 3.6), (sx, 0, 1.8), "PaintGrey")
    p.box((10.0, 0.3, 3.0), (0, 0, 2.0), "PaintGreen", bevel=0.05)
    return p


@prop("sign_letter_word", cat="street", body="rigid", mass=6, grab=None, col="box", tags=["letters"])
def sign_letter_word():
    p = Prop("sign_letter_word")
    text_mesh(p, "THE END", 0.75, (0, 0, 0), "SignWhite", depth=0.1, rot=(90, 0, 180))
    return p


@prop("sign_letter_a", cat="street", body="rigid", mass=6, grab=None, col="box", tags=["letters"])
def sign_letter_a():
    p = Prop("sign_letter_a")
    text_mesh(p, "TERMINUS STATION", 0.55, (0, 0, 0), "SignWhite", depth=0.1, rot=(90, 0, 180))
    return p


@prop("sign_letter_b", cat="street", body="rigid", mass=6, grab=None, col="box", tags=["letters"])
def sign_letter_b():
    p = Prop("sign_letter_b")
    text_mesh(p, "OF THE LINE", 0.55, (0, 0, 0), "SignWhite", depth=0.1, rot=(90, 0, 180))
    return p


@prop("cctv_pole", cat="street", body="static", col="cylinder")
def cctv_pole():
    p = Prop("cctv_pole")
    p.cyl(0.07, 6.0, (0, 0, 3.0), "PaintGrey", seg=8)
    p.box((0.2, 0.4, 0.2), (0, 0.2, 6.0), "PaintBlack", bevel=0.03)
    p.sph(0.04, (0, 0.4, 6.02), "LedRed", seg=6)
    return p


@prop("trash_can_street", cat="street", body="rigid", mass=8, grab="medium", col="cylinder")
def trash_can_street():
    p = Prop("trash_can_street")
    p.cyl(0.3, 0.9, (0, 0, 0.45), "PaintGreen", seg=14)
    p.cyl(0.31, 0.06, (0, 0, 0.92), "PaintBlack", seg=14)
    return p


@prop("bench_street", cat="street", body="static", col="box")
def bench_street():
    p = Prop("bench_street")
    p.box((1.6, 0.45, 0.06), (0, 0, 0.45), "WoodWarm", bevel=0.01)
    p.box((1.6, 0.06, 0.4), (0, -0.22, 0.75), "WoodWarm", bevel=0.01, rot=(-10, 0, 0))
    for sx in (-0.7, 0.7):
        p.box((0.06, 0.45, 0.45), (sx, 0, 0.225), "SteelDark")
    return p


@prop("baseball_kid_bat", cat="street", body="rigid", mass=0.9, grab="light", col="box")
def baseball_kid_bat():
    p = Prop("baseball_kid_bat")
    p.tube([(0, -0.3, 0.02), (0, 0.3, 0.03)], 0.02, "WoodWarm", seg=6, r_end=0.03)
    return p
