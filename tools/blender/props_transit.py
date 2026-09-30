"""Station / transit props. Origin = floor centre unless noted. Front faces +Y."""
import math
from props_registry import prop, text_mesh
from lt_lib import Prop, Vector


def _legs4(p, w, d, h, t, mat, inset=0.0):
    for sx in (-1, 1):
        for sy in (-1, 1):
            p.box((t, t, h), (sx * (w / 2 - t / 2 - inset), sy * (d / 2 - t / 2 - inset), h / 2), mat)


@prop("bench", cat="transit", body="static", col="box", inspect="ch1_insp_bench")
def bench():
    p = Prop("bench")
    for sx in (-0.8, 0.8):
        p.box((0.06, 0.5, 0.05), (sx, 0, 0.42), "SteelDark", bevel=0.01)
        p.box((0.06, 0.05, 0.45), (sx, -0.2, 0.22), "SteelDark", bevel=0.01)
        p.box((0.06, 0.05, 0.45), (sx, 0.2, 0.22), "SteelDark", bevel=0.01)
        p.box((0.06, 0.04, 0.5), (sx, -0.25, 0.7), "SteelDark", rot=(-12, 0, 0))
    for i in range(4):
        p.box((1.8, 0.09, 0.04), (0, -0.2 + i * 0.13, 0.46), "WoodWarm", bevel=0.008)
    for i in range(3):
        p.box((1.8, 0.03, 0.11), (0, -0.28 - i * 0.02, 0.6 + i * 0.13), "WoodWarm", rot=(-12, 0, 0), bevel=0.006)
    return p


@prop("trash_bin", cat="transit", body="rigid", mass=6, grab="medium", col="cylinder")
def trash_bin():
    p = Prop("trash_bin")
    p.cyl(0.24, 0.85, (0, 0, 0.425), "SteelDark", seg=20)
    p.cyl(0.25, 0.06, (0, 0, 0.88), "PaintGrey", seg=20)
    p.cyl(0.14, 0.02, (0, 0, 0.92), "PlasticBlack", seg=16)
    p.box((0.2, 0.01, 0.05), (0, 0.245, 0.55), "PaintGreen")
    return p


@prop("info_kiosk", cat="transit", body="static", col="cylinder", tags=["kiosk"])
def info_kiosk():
    p = Prop("info_kiosk")
    p.cyl(1.35, 1.0, (0, 0, 0.5), "PaintBlue", seg=28)
    p.cyl(1.42, 0.06, (0, 0, 1.04), "WoodWarm", seg=28)
    p.cyl(0.35, 2.4, (0, 0, 2.2), "SteelBrushed", seg=12)
    for k in range(4):
        a = k * 90
        p.box((0.9, 0.06, 0.55), (0.0, 0.0, 2.7), "PlasticBlack", rot=(0, 0, a))
        ang = math.radians(a)
        p.box((0.82, 0.02, 0.47), (math.sin(ang) * 0.0 + -math.sin(ang) * 0.34, math.cos(ang) * 0.34, 2.7), "ScreenBlue", rot=(0, 0, a))
    p.cyl(0.55, 0.12, (0, 0, 3.5), "PaintBlue", seg=20)
    text_mesh(p, "i", 0.4, (0, 0.0, 3.5), "SignWhite", depth=0.03, rot=(0, 0, 0))
    p.box((0.3, 0.2, 0.12), (0.9, 0.9, 1.12), "PlasticBlack")   # charger brick
    p.mark("charger", (0.9, 0.9, 1.12))
    return p


@prop("ticket_machine", cat="transit", body="static", col="box", inspect=None, tags=["ticket"])
def ticket_machine():
    p = Prop("ticket_machine")
    p.box((0.75, 0.55, 1.75), (0, 0, 0.875), "PaintBlue", bevel=0.03)
    p.box((0.62, 0.02, 0.4), (0, 0.28, 1.3), "ScreenBlue")
    p.box((0.35, 0.03, 0.05), (0, 0.29, 0.98), "PlasticBlack")   # card slot
    p.box((0.3, 0.06, 0.1), (0, 0.29, 0.75), "SteelDark")        # ticket slot
    p.box((0.75, 0.6, 0.16), (0, 0, 1.75), "PaintWhite", bevel=0.02)
    text_mesh(p, "TICKETS", 0.09, (0, 0.31, 1.75), "PaintBlue", depth=0.01, rot=(90, 0, 180))
    p.box((0.5, 0.01, 0.2), (0, 0.28, 0.5), "SteelBrushed")
    return p


@prop("fare_gate", cat="transit", body="static", col="box")
def fare_gate():
    p = Prop("fare_gate")
    for sx in (-0.4, 0.4):
        p.box((0.12, 1.1, 1.0), (sx, 0, 0.5), "SteelBrushed", bevel=0.02)
        p.box((0.14, 1.12, 0.05), (sx, 0, 1.02), "PlasticBlack")
    p.box((0.05, 0.05, 0.03), (-0.34, 0.3, 1.06), "LedGreen")
    p.box((0.6, 0.02, 0.5), (0.0, -0.4, 0.75), "GlassTint")
    return p


def _suitcase(name, w, d, h, color):
    p = Prop(name)
    p.box((w, d, h), (0, 0, h / 2 + 0.03), color, bevel=0.03)
    p.box((w * 0.9, d * 0.8, 0.02), (0, 0, h + 0.03), "PlasticBlack")
    p.box((w * 0.4, 0.03, 0.03), (0, 0, h + 0.07), "PlasticBlack")   # handle
    for sx in (-1, 1):
        for sy in (-1, 1):
            p.cyl(0.025, 0.03, (sx * (w / 2 - 0.05), sy * (d / 2 - 0.05), 0.015), "Rubber", seg=8)
    p.box((w * 0.7, 0.01, 0.03), (0, d / 2, h * 0.5), "SteelBrushed")
    return p


@prop("suitcase_red", cat="transit", body="rigid", mass=8, grab="medium", col="box")
def suitcase_red(): return _suitcase("suitcase_red", 0.48, 0.28, 0.68, "PlasticRed")


@prop("suitcase_blue", cat="transit", body="rigid", mass=8, grab="medium", col="box", inspect="ch1_insp_luggage")
def suitcase_blue(): return _suitcase("suitcase_blue", 0.42, 0.25, 0.6, "PlasticBlue")


@prop("suitcase_green", cat="transit", body="rigid", mass=10, grab="medium", col="box")
def suitcase_green(): return _suitcase("suitcase_green", 0.55, 0.32, 0.78, "PlasticGreen")


@prop("backpack", cat="transit", body="rigid", mass=3, grab="light", col="box")
def backpack():
    p = Prop("backpack")
    p.box((0.32, 0.18, 0.46), (0, 0, 0.23), "FabricGrey", bevel=0.05)
    p.box((0.26, 0.06, 0.26), (0, 0.11, 0.2), "FabricGrey", bevel=0.03)
    p.box((0.05, 0.02, 0.4), (-0.09, -0.1, 0.25), "PlasticBlack")
    p.box((0.05, 0.02, 0.4), (0.09, -0.1, 0.25), "PlasticBlack")
    return p


@prop("baggage_cart", cat="transit", body="rigid", mass=45, grab="heavy", col="box", inspect="ch1_insp_cart", tags=["cart", "chain"])
def baggage_cart():
    p = Prop("baggage_cart")
    p.box((0.9, 1.4, 0.05), (0, 0, 0.2), "SteelBrushed", bevel=0.01)          # deck
    p.box((0.9, 0.04, 0.9), (0, -0.7, 0.62), "SteelBrushed")                  # back plate
    for sx in (-0.44, 0.44):
        p.box((0.03, 0.03, 0.9), (sx, -0.7, 0.62), "Chrome")
        p.box((0.03, 1.4, 0.03), (sx, 0, 0.32), "Chrome")
    p.box((0.9, 0.04, 0.04), (0, -0.7, 1.08), "PlasticBlack")                 # handle
    for sx in (-0.4, 0.4):
        for sy in (-0.55, 0.55):
            p.cyl(0.09, 0.05, (sx, sy, 0.1), "Rubber", rot=(0, 90, 0), seg=14)
            p.cyl(0.03, 0.06, (sx, sy, 0.1), "SteelDark", rot=(0, 90, 0), seg=8)
    p.box((0.44, 0.28, 0.6), (-0.12, 0.05, 0.55), "PlasticRed", bevel=0.03)   # loaded luggage
    p.box((0.4, 0.26, 0.46), (0.16, 0.25, 0.48), "PlasticBlue", bevel=0.03)
    p.box((0.3, 0.3, 0.28), (0.1, -0.25, 0.4), "Cardboard", bevel=0.01)
    p.mark("handle", (0, -0.7, 1.08))
    return p


@prop("wet_floor_sign", cat="transit", body="rigid", mass=1.5, grab="light", col="box", inspect="ch1_insp_sign", tags=["sign"])
def wet_floor_sign():
    p = Prop("wet_floor_sign")
    for s in (-1, 1):
        p.box((0.32, 0.03, 0.62), (0, s * 0.11, 0.31), "PlasticYellow", rot=(s * -14, 0, 0), bevel=0.005)
        text_mesh(p, "CAUTION", 0.06, (0, s * 0.128 + s * 0.02, 0.5), "PlasticBlack", depth=0.004, rot=(90 + s * 14, 0, 180 if s > 0 else 0))
        text_mesh(p, "WET FLOOR", 0.055, (0, s * 0.128 + s * 0.02, 0.4), "PlasticBlack", depth=0.004, rot=(90 + s * 14, 0, 180 if s > 0 else 0))
    p.box((0.32, 0.24, 0.02), (0, 0, 0.01), "PlasticYellow")
    return p


@prop("traffic_cone", cat="transit", body="rigid", mass=1.2, grab="light", col="cylinder")
def traffic_cone():
    p = Prop("traffic_cone")
    p.box((0.4, 0.4, 0.03), (0, 0, 0.015), "PlasticOrange")
    p.cyl(0.19, 0.6, (0, 0, 0.33), "PlasticOrange", seg=16, r2=0.035)
    p.cyl(0.128, 0.09, (0, 0, 0.32), "PaintWhite", seg=16, r2=0.11)
    return p


@prop("barrier_fence", cat="transit", body="static", col="box", tags=["mantle"])
def barrier_fence():
    p = Prop("barrier_fence")
    p.box((2.0, 0.04, 0.04), (0, 0, 1.0), "SteelGalv")
    p.box((2.0, 0.04, 0.04), (0, 0, 0.15), "SteelGalv")
    for i in range(11):
        p.box((0.02, 0.02, 0.9), (-0.9 + i * 0.18, 0, 0.58), "SteelGalv")
    for sx in (-1.0, 1.0):
        p.box((0.04, 0.04, 1.05), (sx, 0, 0.55), "SteelGalv")
    for sx in (-0.85, 0.85):
        p.box((0.18, 0.6, 0.08), (sx, 0, 0.04), "ConcreteRough")
    return p


@prop("stanchion", cat="transit", body="rigid", mass=6, grab="medium", col="cylinder")
def stanchion():
    p = Prop("stanchion")
    p.cyl(0.17, 0.04, (0, 0, 0.02), "Chrome", seg=20)
    p.cyl(0.025, 0.95, (0, 0, 0.5), "Chrome", seg=10)
    p.sph(0.05, (0, 0, 1.0), "Chrome", seg=10)
    return p


@prop("sculpture_momentum", cat="transit", body="none", col="none", inspect="ch1_insp_sculpture", tags=["hero", "chain"])
def sculpture_momentum():
    """Origin at ceiling attach plate centre; hangs down -Z. Six attach markers."""
    p = Prop("sculpture_momentum")
    p.cyl(0.9, 0.12, (0, 0, -0.06), "SteelDark", seg=20)
    cz = -4.2
    p.sph(1.1, (0, 0, cz), "Chrome", seg=24)
    for i, rr in enumerate((1.6, 2.0)):
        p.lathe([(rr, -0.05), (rr + 0.06, 0), (rr, 0.05)], (0, 0, cz), "Brass", rot=(20 + i * 30, i * 25, 0), seg=40, close_top=True, close_bottom=True)
    for k in range(5):
        a = k * 72
        x = 2.4 * math.cos(math.radians(a)); y = 2.4 * math.sin(math.radians(a))
        p.sph(0.32 + 0.05 * (k % 3), (x, y, cz + (0.6 if k % 2 else -0.4)), ["PaintRed", "PaintYellow", "PaintBlue", "PaintGreen", "PaintOrange"][k], seg=14)
    for k in range(6):
        a = math.radians(k * 60)
        p.mark("cable_%d" % k, (0.7 * math.cos(a), 0.7 * math.sin(a), 0.0))
        p.mark("hang_%d" % k, (0.55 * math.cos(a), 0.55 * math.sin(a), cz + 0.9))
        p.sph(0.05, (0.55 * math.cos(a), 0.55 * math.sin(a), cz + 0.98), "Chrome", seg=8)
    return p


@prop("escalator_step", cat="transit", body="none", col="none")
def escalator_step():
    p = Prop("escalator_step")
    p.box((1.0, 0.4, 0.06), (0, 0, 0.17), "SteelDark")
    for i in range(6):
        p.box((0.94, 0.012, 0.012), (0, -0.17 + i * 0.065, 0.205), "SteelBrushed")
    p.box((1.0, 0.03, 0.18), (0, 0.2, 0.09), "SteelDark")
    p.box((1.0, 0.012, 0.012), (0, 0.185, 0.205), "PaintYellow")
    return p


@prop("escalator_frame", cat="transit", body="static", col="trimesh", inspect="ch1_insp_escalator", tags=["hero", "chain"])
def escalator_frame():
    """Escalator side-frames: runs along +Y and climbs +Z. run=9.0 rise=5.2. Origin at lower landing centre."""
    p = Prop("escalator_frame")
    run, rise = 9.0, 5.2
    ang = math.degrees(math.atan2(rise, run))
    ln = math.hypot(run, rise)
    mid = (0, run / 2, rise / 2)
    for sx in (-0.65, 0.65):
        p.box((0.16, ln + 1.2, 0.5), (sx, run / 2, rise / 2 - 0.15), "SteelBrushed", rot=(ang, 0, 0), bevel=0.02)
        # balustrade glass
        p.box((0.03, ln, 0.85), (sx, run / 2, rise / 2 + 0.72), "GlassTint", rot=(ang, 0, 0))
        p.box((0.11, ln + 0.6, 0.08), (sx, run / 2, rise / 2 + 1.16), "Rubber", rot=(ang, 0, 0), bevel=0.02)
    # trusses underneath
    p.box((1.4, ln, 0.3), (0, run / 2, rise / 2 - 0.5), "SteelDark", rot=(ang, 0, 0))
    # landings
    p.box((1.5, 1.0, 0.12), (0, -0.5, 0.06), "SteelBrushed")
    p.box((1.5, 1.0, 0.12), (0, run + 0.5, rise + 0.06), "SteelBrushed")
    p.box((1.3, 0.3, 0.02), (0, -0.1, 0.13), "DiamondPlate")
    p.box((1.3, 0.3, 0.02), (0, run + 0.1, rise + 0.13), "DiamondPlate")
    p.mark("top", (0, run, rise))
    p.mark("bottom", (0, 0, 0))
    return p


@prop("scrub_robot", cat="transit", body="rigid", mass=25, grab=None, col="box", inspect="ch1_insp_scrub", tags=["robot", "chain"])
def scrub_robot():
    p = Prop("scrub_robot")
    p.box((0.7, 0.9, 0.48), (0, 0, 0.36), "PaintWhite", bevel=0.09)
    p.box((0.72, 0.5, 0.2), (0, -0.15, 0.68), "PaintTeal", bevel=0.05)
    p.box((0.6, 0.04, 0.22), (0, 0.46, 0.6), "ScreenOff")
    for sx in (-0.12, 0.12):
        p.sph(0.05, (sx, 0.475, 0.62), "LedGreen", seg=8)
    p.box((0.75, 0.08, 0.08), (0, 0.52, 0.13), "Rubber", bevel=0.02)                # squeegee
    for sx in (-0.3, 0.3):
        p.cyl(0.09, 0.1, (sx, 0.1, 0.1), "Rubber", rot=(0, 90, 0), seg=14)
    p.cyl(0.02, 0.28, (0.28, -0.35, 0.92), "PlasticBlack", seg=6)                   # antenna
    p.sph(0.04, (0.28, -0.35, 1.07), "LedRed", seg=8)
    p.box((0.24, 0.02, 0.06), (0, -0.46, 0.55), "SignYellow")
    text_mesh(p, "SCRUB-E", 0.05, (0, 0.462, 0.75), "PaintBlack", depth=0.004, rot=(90, 0, 180))
    return p


@prop("bar_stool", cat="cafe", body="rigid", mass=5, grab="medium", col="cylinder", tags=["stool"])
def bar_stool():
    p = Prop("bar_stool")
    p.cyl(0.22, 0.06, (0, 0, 0.72), "FabricRed", seg=18)
    p.cyl(0.03, 0.66, (0, 0, 0.36), "Chrome", seg=8)
    p.lathe([(0.24, 0.0), (0.2, 0.03), (0.03, 0.03)], (0, 0, 0.0), "Chrome", seg=16, close_bottom=True)
    p.lathe([(0.2, 0.0), (0.21, 0.02)], (0, 0, 0.26), "Chrome", seg=16)
    return p


@prop("cafe_table", cat="cafe", body="rigid", mass=9, grab="medium", col="cylinder", tags=["table"])
def cafe_table():
    p = Prop("cafe_table")
    p.cyl(0.4, 0.04, (0, 0, 0.74), "WoodWarm", seg=24)
    p.cyl(0.035, 0.72, (0, 0, 0.36), "SteelDark", seg=8)
    p.cyl(0.26, 0.03, (0, 0, 0.015), "SteelDark", seg=18)
    return p


@prop("cafe_chair", cat="cafe", body="rigid", mass=4, grab="medium", col="box", tags=["chair"])
def cafe_chair():
    p = Prop("cafe_chair")
    p.box((0.42, 0.42, 0.04), (0, 0, 0.45), "WoodWarm", bevel=0.01)
    _legs4(p, 0.42, 0.42, 0.44, 0.035, "SteelDark")
    p.box((0.42, 0.03, 0.4), (0, -0.2, 0.7), "WoodWarm", rot=(-6, 0, 0), bevel=0.01)
    return p


@prop("smoothie_counter", cat="cafe", body="static", col="box", inspect="ch1_insp_smoothie", tags=["hero"])
def smoothie_counter():
    p = Prop("smoothie_counter")
    p.box((3.6, 0.9, 1.05), (0, 0, 0.525), "PaintGreen", bevel=0.02)
    p.box((3.7, 1.0, 0.06), (0, 0, 1.08), "WoodWarm", bevel=0.01)
    p.box((3.6, 0.03, 0.55), (0, 0.45, 1.4), "Glass")                                      # sneeze guard
    p.box((3.6, 0.7, 0.05), (0, -0.05, 2.3), "PaintGreen")                                 # canopy
    for sx in (-1.75, 1.75):
        p.box((0.06, 0.06, 1.25), (sx, -0.3, 1.7), "SteelDark")
    text_mesh(p, "JUICE JUNCTION", 0.22, (0, 0.31, 2.3), "SignYellow", depth=0.03, rot=(90, 0, 180))
    p.box((0.45, 0.4, 0.5), (-1.2, -0.1, 1.36), "PlasticBlack", bevel=0.03)                # blender base
    p.cyl(0.14, 0.4, (-1.2, -0.1, 1.8), "Glass", seg=12, r2=0.11)
    p.box((0.5, 0.4, 0.3), (1.2, -0.05, 1.23), "SteelBrushed", bevel=0.02)
    for i in range(5):
        p.sph(0.09, (-0.3 + i * 0.18, 0.05, 1.17), ["PaintRed", "PaintOrange", "PaintYellow", "PaintGreen", "PaintPurple" if False else "PlasticPurple"][i], seg=8)
    p.box((1.2, 0.02, 0.5), (0.0, -0.44, 1.55), "PaintWhite")                              # menu board
    p.mark("cup_spot", (0.5, 0.2, 1.11))
    return p


@prop("smoothie_cup", cat="cafe", body="rigid", mass=0.4, grab="light", col="cylinder", tags=["cup", "chain"])
def smoothie_cup():
    p = Prop("smoothie_cup")
    p.cyl(0.045, 0.17, (0, 0, 0.09), "PlasticWhite", seg=14, r2=0.036, caps=False)
    p.cyl(0.043, 0.13, (0, 0, 0.09), "Smoothie", seg=14, r2=0.036)
    p.cyl(0.047, 0.015, (0, 0, 0.185), "PlasticWhite", seg=14)
    p.cyl(0.006, 0.12, (0.008, 0, 0.245), "PlasticGreen", seg=6, rot=(0, 8, 0))
    return p


@prop("coffee_cup", cat="cafe", body="rigid", mass=0.3, grab="light", col="cylinder")
def coffee_cup():
    p = Prop("coffee_cup")
    p.cyl(0.04, 0.11, (0, 0, 0.055), "PaintWhite", seg=14, r2=0.03)
    p.cyl(0.043, 0.012, (0, 0, 0.115), "PlasticBlack", seg=14)
    p.cyl(0.042, 0.04, (0, 0, 0.05), "Cardboard", seg=14, r2=0.036, caps=False)
    return p


@prop("coffee_machine", cat="cafe", body="static", col="box", tags=["chain", "finale"])
def coffee_machine():
    p = Prop("coffee_machine")
    p.box((0.7, 0.6, 0.55), (0, 0, 0.275), "SteelBrushed", bevel=0.03)
    p.box((0.7, 0.6, 0.06), (0, 0, 0.58), "PaintBlack", bevel=0.02)
    p.box((0.62, 0.42, 0.42), (0, 0, 0.82), "PaintBlack", bevel=0.03)
    p.box((0.18, 0.02, 0.1), (-0.15, 0.22, 0.98), "ScreenGreen")
    for sx in (-0.15, 0.15):
        p.cyl(0.03, 0.08, (sx, 0.18, 0.63), "Chrome", seg=8)
    p.cyl(0.015, 0.25, (0.28, 0.2, 0.7), "Chrome", rot=(70, 0, 0), seg=6)
    p.box((0.4, 0.3, 0.02), (0, 0.15, 0.22), "PaintBlack")
    return p


@prop("vending_machine", cat="transit", body="static", col="box", tags=["vending"])
def vending_machine():
    p = Prop("vending_machine")
    p.box((0.95, 0.85, 1.85), (0, 0, 0.925), "PaintRed", bevel=0.03)
    p.box((0.68, 0.02, 1.3), (-0.09, 0.43, 1.05), "GlassTint")
    for r in range(5):
        for c in range(4):
            p.box((0.1, 0.06, 0.18), (-0.33 + c * 0.16, 0.38, 0.55 + r * 0.24), ["PlasticBlue", "PlasticYellow", "PlasticGreen", "PlasticOrange"][(r + c) % 4])
    p.box((0.16, 0.03, 0.6), (0.34, 0.43, 1.3), "PaintBlack")
    p.box((0.3, 0.02, 0.1), (0.34, 0.44, 0.9), "ScreenOff")
    p.box((0.7, 0.05, 0.22), (-0.09, 0.43, 0.15), "PaintBlack")
    text_mesh(p, "FIZZ-O", 0.12, (0, 0.436, 1.76), "PaintWhite", depth=0.01, rot=(90, 0, 180))
    return p


@prop("vending_machine_phys", cat="transit", body="rigid", mass=350, grab=None, col="box", tags=["vending", "yard"])
def vending_machine_phys():
    return vending_machine()


@prop("station_clock", cat="transit", body="none", col="none", inspect="ch1_insp_clock")
def station_clock():
    p = Prop("station_clock")
    p.cyl(0.5, 0.08, (0, 0, 0), "PaintBlack", rot=(90, 0, 0), seg=28)
    p.cyl(0.46, 0.09, (0, 0.005, 0), "PaintWhite", rot=(90, 0, 0), seg=28)
    for i in range(12):
        a = math.radians(i * 30)
        p.box((0.02, 0.01, 0.06), (0.4 * math.sin(a), 0.05, 0.4 * math.cos(a)), "PaintBlack", rot=(0, -i * 30, 0))
    p.box((0.025, 0.012, 0.27), (0, 0.055, 0.12), "PaintBlack")
    p.box((0.02, 0.012, 0.36), (0.14, 0.06, 0.05), "PaintBlack", rot=(0, -70, 0))
    return p


@prop("pigeon_statue", cat="transit", body="static", col="box", inspect="ch1_insp_pigeon")
def pigeon_statue():
    p = Prop("pigeon_statue")
    p.box((0.6, 0.6, 0.6), (0, 0, 0.3), "TerrazzoDark", bevel=0.04)
    p.sph(0.3, (0, 0, 0.95), "Brass", seg=14, scale=(0.85, 1.2, 0.95))
    p.sph(0.16, (0, 0.32, 1.22), "Brass", seg=12)
    p.cyl(0.04, 0.12, (0, 0.5, 1.2), "Brass", rot=(-90, 0, 0), seg=8, r2=0.006)
    p.cyl(0.02, 0.22, (0, -0.26, 0.95), "Brass", rot=(70, 0, 0), seg=6, r2=0.005)
    p.sph(0.02, (0.06, 0.4, 1.28), "PaintBlack", seg=6)
    p.sph(0.02, (-0.06, 0.4, 1.28), "PaintBlack", seg=6)
    return p


@prop("red_handle", cat="transit", body="static", col="box", inspect="ch1_insp_handle", tags=["alarm", "chain"])
def red_handle():
    p = Prop("red_handle")
    p.box((0.16, 0.06, 0.22), (0, 0, 0), "PaintRed", bevel=0.01)
    p.box((0.06, 0.05, 0.1), (0, 0.045, -0.02), "PaintWhite", bevel=0.01)
    p.box((0.09, 0.02, 0.03), (0, 0.06, 0.07), "PaintWhite")
    text_mesh(p, "PULL", 0.03, (0, 0.033, 0.08), "PaintWhite", depth=0.004, rot=(90, 0, 180))
    return p


@prop("electrical_panel", cat="transit", body="static", col="box", inspect="ch1_insp_panel", tags=["electric", "chain"])
def electrical_panel():
    p = Prop("electrical_panel")
    p.box((0.7, 0.22, 1.1), (0, 0, 0.55), "PaintGrey", bevel=0.01)
    p.box((0.6, 0.02, 0.5), (0, 0.11, 0.7), "PaintBlack")
    p.box((0.05, 0.08, 0.3), (0, 0.15, 0.7), "PaintRed", rot=(-25, 0, 0))                      # big lever
    p.sph(0.05, (0, 0.2, 0.83), "PaintRed", seg=8)
    p.box((0.14, 0.01, 0.14), (0.2, 0.115, 0.98), "SignYellow")
    text_mesh(p, "DANGER", 0.03, (-0.15, 0.116, 0.98), "SignRed", depth=0.003, rot=(90, 0, 180))
    p.cyl(0.03, 0.9, (-0.24, 0, 1.4), "SteelGalv", seg=8)
    return p


@prop("sprinkler_head", cat="transit", body="none", col="none")
def sprinkler_head():
    p = Prop("sprinkler_head")
    p.cyl(0.02, 0.06, (0, 0, -0.03), "Brass", seg=8)
    p.cyl(0.035, 0.008, (0, 0, -0.075), "Brass", seg=10)
    p.sph(0.015, (0, 0, -0.06), "PaintRed", seg=6)
    return p


@prop("light_fixture", cat="fixtures", body="none", col="none")
def light_fixture():
    """Long fluorescent troffer. Origin at ceiling."""
    p = Prop("light_fixture")
    p.box((1.25, 0.28, 0.08), (0, 0, -0.04), "PaintWhite", bevel=0.01)
    p.box((1.15, 0.2, 0.01), (0, 0, -0.085), "LightTube")
    return p


@prop("pendant_light", cat="fixtures", body="none", col="none")
def pendant_light():
    p = Prop("pendant_light")
    p.cyl(0.005, 1.2, (0, 0, -0.6), "PlasticBlack", seg=6)
    p.lathe([(0.02, 0.0), (0.2, -0.16), (0.24, -0.2)], (0, 0, -1.2), "PaintBlack", seg=20, close_top=True)
    p.sph(0.07, (0, 0, -1.38), "LightWarm", seg=10)
    return p


@prop("sign_slogan", cat="signs", body="none", col="none", tags=["hero"])
def sign_slogan():
    p = Prop("sign_slogan")
    p.box((9.0, 0.2, 1.6), (0, 0, 0.8), "PaintBlack", bevel=0.03)
    text_mesh(p, "THE LAST STOP", 0.52, (0, 0.11, 1.15), "SignWhite", depth=0.04, rot=(90, 0, 180))
    text_mesh(p, "YOU'LL EVER NEED", 0.52, (0, 0.11, 0.45), "SignYellow", depth=0.04, rot=(90, 0, 180))
    return p


@prop("sign_platform4", cat="signs", body="none", col="none")
def sign_platform4():
    p = Prop("sign_platform4")
    p.box((3.2, 0.12, 0.7), (0, 0, 0), "PaintBlue", bevel=0.02)
    text_mesh(p, "PLATFORM 4  →", 0.3, (0, 0.07, 0), "SignWhite", depth=0.02, rot=(90, 0, 180))
    p.cyl(0.02, 1.0, (-1.2, 0, 0.85), "SteelDark", seg=6)
    p.cyl(0.02, 1.0, (1.2, 0, 0.85), "SteelDark", seg=6)
    return p


@prop("sign_exit", cat="signs", body="none", col="none")
def sign_exit():
    p = Prop("sign_exit")
    p.box((0.5, 0.06, 0.2), (0, 0, 0), "SignGreen", bevel=0.01)
    text_mesh(p, "EXIT", 0.12, (0, 0.035, 0), "SignWhite", depth=0.006, rot=(90, 0, 180))
    return p


@prop("sign_terminus_hall", cat="signs", body="none", col="none", tags=["hero"])
def sign_terminus_hall():
    p = Prop("sign_terminus_hall")
    p.box((7.0, 0.3, 1.5), (0, 0, 0.75), "PaintGreen", bevel=0.04)
    text_mesh(p, "TERMINUS STATION", 0.6, (0, 0.16, 0.95), "SignWhite", depth=0.05, rot=(90, 0, 180))
    text_mesh(p, "THE END OF THE LINE", 0.3, (0, 0.16, 0.35), "SignYellow", depth=0.05, rot=(90, 0, 180))
    return p


@prop("departures_board", cat="signs", body="none", col="none")
def departures_board():
    p = Prop("departures_board")
    p.box((3.2, 0.18, 1.4), (0, 0, 0.7), "PaintBlack", bevel=0.02)
    p.box((3.0, 0.02, 1.2), (0, 0.1, 0.7), "ScreenBlue")
    text_mesh(p, "DEPARTURES", 0.13, (0, 0.115, 1.15), "SignYellow", depth=0.004, rot=(90, 0, 180))
    for i, t in enumerate(["08:14  RIVERSIDE     P4", "08:22  HARBOR         P2", "08:31  MILLBROOK      P4", "08:40  CENTENNIAL LN  P1"]):
        text_mesh(p, t, 0.09, (0, 0.115, 0.85 - i * 0.2), "SignWhite", depth=0.004, rot=(90, 0, 180))
    return p


@prop("train_car", cat="vehicles", body="static", col="box", inspect="ch1_insp_train", tags=["hero", "train"])
def train_car():
    """Commuter rail car, 20m, origin at floor centre; front faces +Y."""
    p = Prop("train_car")
    p.box((3.0, 20.0, 3.3), (0, 0, 2.05), "PaintWhite", bevel=0.2)
    p.box((3.02, 20.02, 0.5), (0, 0, 1.1), "PaintBlue")
    p.box((3.02, 20.02, 0.16), (0, 0, 2.0), "PaintRed")
    p.box((2.9, 20.0, 0.4), (0, 0, 3.8), "PaintGrey", bevel=0.1)
    for side in (-1, 1):
        for i in range(6):
            p.box((0.04, 2.2, 1.0), (side * 1.505, -8 + i * 3.2, 2.5), "GlassTint")
        for y in (-5.5, 5.5):
            p.box((0.05, 1.4, 2.2), (side * 1.51, y, 1.8), "PaintBlue")
            p.box((0.06, 0.03, 2.2), (side * 1.51, y, 1.8), "PlasticBlack")
    p.box((2.4, 0.05, 1.1), (0, 10.0, 2.6), "GlassTint")                                        # windshield
    p.box((1.2, 0.1, 0.4), (0, 10.02, 1.0), "PaintBlack")
    for sy in (-7.0, 7.0):
        p.box((2.4, 3.2, 0.5), (0, sy, 0.55), "SteelDark")
        for sx in (-1.0, 1.0):
            for yy in (-0.9, 0.9):
                p.cyl(0.46, 0.14, (sx, sy + yy, 0.46), "SteelBrushed", rot=(0, 90, 0), seg=18)
    for x in (-0.75, 0.75):
        p.sph(0.1, (x, 10.03, 0.85), "LightTube", seg=8)
    p.cyl(0.05, 0.6, (0, 9.7, 0.45), "SteelDark", rot=(90, 0, 0), seg=8)                        # coupler
    return p


@prop("skylink_pod", cat="vehicles", body="none", col="none", inspect="ch1_insp_skylink", tags=["hero", "chain"])
def skylink_pod():
    """Elevated people-mover pod. 6m long, origin at floor centre."""
    p = Prop("skylink_pod")
    p.box((2.4, 6.0, 2.4), (0, 0, 1.5), "PaintWhite", bevel=0.35)
    p.box((2.42, 6.02, 0.3), (0, 0, 0.55), "PaintTeal")
    for side in (-1, 1):
        p.box((0.04, 4.4, 1.0), (side * 1.205, 0, 1.9), "GlassTint")
        p.box((0.05, 1.3, 1.9), (side * 1.21, 0, 1.25), "GlassTint")
    p.box((2.0, 0.05, 0.9), (0, 3.0, 1.9), "GlassTint")
    p.box((0.9, 0.9, 0.2), (0, 0, 2.85), "PaintGrey", bevel=0.05)
    p.box((1.9, 0.4, 0.3), (0, 0, 0.15), "SteelDark")
    text_mesh(p, "SKYLINK", 0.28, (1.22, 0, 2.3), "PaintTeal", depth=0.01, rot=(90, 0, 90))
    return p


@prop("planter_box", cat="transit", body="static", col="box", tags=["mantle"])
def planter_box():
    p = Prop("planter_box")
    p.box((1.6, 0.6, 0.6), (0, 0, 0.3), "Concrete", bevel=0.03)
    p.box((1.5, 0.5, 0.05), (0, 0, 0.6), "Dirt")
    for i in range(6):
        p.sph(0.28 + 0.03 * (i % 3), (-0.6 + i * 0.24, (i % 2) * 0.1 - 0.05, 0.9 + 0.05 * (i % 2)), "PaintGreen", seg=8)
    return p


@prop("plant_ficus", cat="deco", body="rigid", mass=8, grab="medium", col="cylinder")
def plant_ficus():
    p = Prop("plant_ficus")
    p.cyl(0.22, 0.4, (0, 0, 0.2), "PaintGrey", seg=14, r2=0.18)
    p.cyl(0.02, 0.9, (0, 0, 0.85), "WoodDark", seg=6)
    for i in range(9):
        a = i * 40
        p.sph(0.22, (0.16 * math.cos(math.radians(a)), 0.16 * math.sin(math.radians(a)), 1.1 + 0.08 * (i % 3)), "PaintGreen", seg=8, scale=(1, 1, 0.8))
    return p


@prop("fire_extinguisher", cat="safety", body="rigid", mass=3, grab="light", col="cylinder")
def fire_extinguisher():
    p = Prop("fire_extinguisher")
    p.cyl(0.07, 0.42, (0, 0, 0.21), "PaintRed", seg=14)
    p.sph(0.07, (0, 0, 0.42), "PaintRed", seg=10, scale=(1, 1, 0.6))
    p.box((0.05, 0.1, 0.03), (0, 0.03, 0.5), "PaintBlack")
    p.tube([(0.03, 0, 0.47), (0.1, 0.04, 0.36), (0.09, 0.05, 0.2)], 0.008, "PlasticBlack", seg=5)
    p.box((0.05, 0.005, 0.06), (0, 0.072, 0.25), "PaintWhite")
    return p


@prop("newsstand", cat="transit", body="static", col="box")
def newsstand():
    p = Prop("newsstand")
    p.box((2.6, 1.4, 2.2), (0, 0, 1.1), "PaintOrange", bevel=0.03)
    p.box((2.0, 0.05, 1.1), (0, 0.72, 1.3), "GlassFrost")
    p.box((2.8, 1.6, 0.14), (0, 0.05, 2.3), "PaintRed", bevel=0.02)
    text_mesh(p, "NEWS & GUM", 0.2, (0, 0.82, 2.3), "PaintWhite", depth=0.02, rot=(90, 0, 180))
    for i in range(6):
        p.box((0.22, 0.02, 0.3), (-0.8 + i * 0.32, 0.75, 1.0), ["PlasticBlue", "PlasticYellow", "PlasticGreen", "PlasticRed"][i % 4])
    return p


@prop("tennis_ball", cat="pickles", body="rigid", mass=0.06, grab="light", col="sphere", tags=["ball", "fetch"])
def tennis_ball():
    p = Prop("tennis_ball")
    p.sph(0.033, (0, 0, 0.033), "PlasticYellow", seg=12)
    p.lathe([(0.0335, -0.006), (0.0345, 0.0), (0.0335, 0.006)], (0, 0, 0.033), "PaintWhite", seg=24, rot=(20, 0, 0))
    return p


@prop("pa_speaker", cat="fixtures", body="none", col="none")
def pa_speaker():
    p = Prop("pa_speaker")
    p.cyl(0.12, 0.3, (0, 0.15, 0), "PaintGrey", rot=(-90, 0, 0), seg=14, r2=0.22)
    p.box((0.1, 0.1, 0.1), (0, -0.05, 0), "PaintGrey")
    return p


@prop("cctv_dome", cat="fixtures", body="none", col="none")
def cctv_dome():
    p = Prop("cctv_dome")
    p.cyl(0.11, 0.03, (0, 0, -0.015), "PaintWhite", seg=14)
    p.sph(0.09, (0, 0, -0.04), "PaintBlack", seg=10, scale=(1, 1, 0.8))
    return p


@prop("jersey_barrier", cat="yard", body="static", col="box", tags=["mantle"])
def jersey_barrier():
    p = Prop("jersey_barrier")
    p.extrude_poly([(-0.3, 0), (0.3, 0), (0.22, 0.35), (0.1, 0.8), (-0.1, 0.8), (-0.22, 0.35)], 2.4, (0, 0, 0), "Concrete", plane="XZ")
    return p


@prop("caution_tape_post", cat="safety", body="none", col="none")
def caution_tape_post():
    p = Prop("caution_tape_post")
    p.cyl(0.02, 1.1, (0, 0, 0.55), "PaintYellow", seg=6)
    p.cyl(0.09, 0.03, (0, 0, 0.015), "PaintBlack", seg=10)
    return p
