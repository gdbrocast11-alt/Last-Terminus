"""Apartment / domestic props and Pickles items. Origin = floor centre, front faces +Y."""
import math
from props_registry import prop, text_mesh
from lt_lib import Prop, Vector
from props_transit import _legs4


@prop("couch", cat="home", body="static", col="box", inspect="ch2_insp_couch")
def couch():
    p = Prop("couch")
    p.box((2.1, 0.92, 0.42), (0, 0, 0.21), "FabricGrey", bevel=0.03)
    p.box((2.1, 0.28, 0.5), (0, -0.4, 0.68), "FabricGrey", bevel=0.05, rot=(-8, 0, 0))
    for s in (-1, 1):
        p.box((0.24, 0.92, 0.28), (s * 0.93, 0, 0.56), "FabricGrey", bevel=0.05)
    for s in (-0.42, 0.42):
        p.box((0.8, 0.66, 0.16), (s, 0.1, 0.5), "FabricBlue", bevel=0.05)
    p.box((0.4, 0.13, 0.4), (0.7, -0.15, 0.78), "FabricRed", bevel=0.04, rot=(-15, 0, 12))
    for sx in (-0.95, 0.95):
        for sy in (-0.4, 0.4):
            p.cyl(0.03, 0.08, (sx, sy, 0.04), "WoodDark", seg=8)
    return p


@prop("armchair", cat="home", body="static", col="box")
def armchair():
    p = Prop("armchair")
    p.box((0.9, 0.85, 0.4), (0, 0, 0.2), "FabricGreen", bevel=0.04)
    p.box((0.9, 0.22, 0.55), (0, -0.33, 0.65), "FabricGreen", bevel=0.05, rot=(-8, 0, 0))
    for s in (-1, 1):
        p.box((0.16, 0.8, 0.28), (s * 0.4, 0, 0.5), "FabricGreen", bevel=0.04)
    return p


@prop("coffee_table", cat="home", body="rigid", mass=12, grab="medium", col="box", tags=["table"])
def coffee_table():
    p = Prop("coffee_table")
    p.box((1.1, 0.6, 0.05), (0, 0, 0.42), "WoodWarm", bevel=0.01)
    _legs4(p, 1.1, 0.6, 0.4, 0.05, "WoodDark")
    return p


@prop("tv_stand", cat="home", body="static", col="box")
def tv_stand():
    p = Prop("tv_stand")
    p.box((1.6, 0.42, 0.5), (0, 0, 0.25), "WoodDark", bevel=0.01)
    p.box((1.5, 0.02, 0.28), (0, 0.215, 0.27), "PaintBlack")
    p.box((1.3, 0.04, 0.03), (0, 0.22, 0.5), "SteelBrushed")
    return p


@prop("tv_flat", cat="home", body="static", col="box", inspect="ch2_insp_tv", tags=["tv"])
def tv_flat():
    p = Prop("tv_flat")
    p.box((1.25, 0.06, 0.72), (0, 0, 0.76), "PaintBlack", bevel=0.01)
    p.box((1.2, 0.01, 0.67), (0, 0.033, 0.76), "ScreenBlue")
    p.box((0.4, 0.2, 0.03), (0, 0, 0.395), "PaintBlack")
    p.box((0.05, 0.05, 0.28), (0, -0.02, 0.5), "PaintBlack")
    return p


@prop("bookshelf", cat="home", body="static", col="box")
def bookshelf():
    p = Prop("bookshelf")
    p.box((1.0, 0.32, 1.9), (0, 0, 0.95), "WoodDark", bevel=0.01)
    p.box((0.9, 0.02, 1.8), (0, 0.16, 0.95), "WoodWarm")
    for i in range(5):
        z = 0.12 + i * 0.37
        p.box((0.94, 0.3, 0.025), (0, 0.01, z), "WoodDark")
        for j in range(7):
            h = 0.22 + 0.06 * ((i * 7 + j) % 3)
            c = ["FabricRed", "FabricBlue", "FabricGreen", "FabricCream", "FabricPurple", "FabricOrange", "FabricTeal"][(i + j * 2) % 7]
            p.box((0.05, 0.22, h), (-0.4 + j * 0.13 + (i % 2) * 0.02, 0.01, z + 0.0125 + h / 2), c)
    return p


@prop("desk", cat="home", body="static", col="box", inspect="ch2_insp_desk", tags=["desk"])
def desk():
    p = Prop("desk")
    p.box((1.4, 0.7, 0.05), (0, 0, 0.74), "Plywood", bevel=0.01)
    for s in (-1, 1):
        p.box((0.05, 0.6, 0.72), (s * 0.65, 0, 0.36), "SteelDark")
    p.box((1.3, 0.02, 0.35), (0, 0.32, 0.55), "Plywood")
    p.box((0.34, 0.05, 0.23), (0.4, 0.12, 0.8), "PaintBlack")     # laptop
    p.box((0.3, 0.2, 0.01), (0.4, 0.12, 0.775), "PaintGrey")
    return p


@prop("notebook", cat="home", body="rigid", mass=0.3, grab="light", col="box", tags=["notebook"], use_verb="Open notebook")
def notebook():
    p = Prop("notebook")
    p.box((0.17, 0.23, 0.02), (0, 0, 0.01), "FabricRed", bevel=0.004)
    p.box((0.155, 0.215, 0.012), (0.004, 0, 0.012), "Paper")
    p.box((0.01, 0.235, 0.022), (-0.085, 0, 0.011), "PaintBlack")
    return p


@prop("office_chair", cat="home", body="rigid", mass=8, grab="medium", col="cylinder", tags=["chair"])
def office_chair():
    p = Prop("office_chair")
    p.cyl(0.24, 0.07, (0, 0, 0.5), "FabricBlack", seg=14)
    p.box((0.42, 0.06, 0.5), (0, -0.22, 0.8), "FabricBlack", bevel=0.02, rot=(-8, 0, 0))
    p.cyl(0.025, 0.36, (0, 0, 0.28), "Chrome", seg=8)
    for i in range(5):
        a = i * 72
        p.box((0.32, 0.04, 0.03), (0.16 * math.cos(math.radians(a)), 0.16 * math.sin(math.radians(a)), 0.08), "PlasticBlack", rot=(0, 0, a))
        p.cyl(0.03, 0.03, (0.3 * math.cos(math.radians(a)), 0.3 * math.sin(math.radians(a)), 0.03), "Rubber", seg=8)
    return p


@prop("floor_lamp", cat="home", body="rigid", mass=4, grab="medium", col="cylinder", tags=["lamp"], inspect="ch2_insp_lamp", hazard=1)
def floor_lamp():
    p = Prop("floor_lamp")
    p.cyl(0.14, 0.03, (0, 0, 0.015), "PaintBlack", seg=14)
    p.cyl(0.015, 1.5, (0, 0, 0.78), "PaintBlack", seg=6)
    p.lathe([(0.1, 0.0), (0.16, 0.24)], (0, 0, 1.5), "FabricCream", seg=16)
    p.sph(0.04, (0, 0, 1.55), "LightWarm", seg=8)
    return p


@prop("table_lamp", cat="home", body="rigid", mass=1.2, grab="light", col="cylinder", tags=["lamp"])
def table_lamp():
    p = Prop("table_lamp")
    p.cyl(0.07, 0.03, (0, 0, 0.015), "PaintBlack", seg=12)
    p.cyl(0.015, 0.22, (0, 0, 0.13), "PaintBlack", seg=6)
    p.lathe([(0.06, 0.0), (0.1, 0.13)], (0, 0, 0.24), "FabricCream", seg=14)
    p.sph(0.03, (0, 0, 0.28), "LightWarm", seg=8)
    return p


@prop("bed", cat="home", body="static", col="box", inspect="ch2_insp_bed")
def bed():
    p = Prop("bed")
    p.box((1.5, 2.05, 0.3), (0, 0, 0.25), "WoodDark", bevel=0.02)
    p.box((1.44, 1.95, 0.22), (0, 0.02, 0.5), "FabricWhite", bevel=0.04)
    p.box((1.46, 1.3, 0.05), (0, 0.35, 0.63), "FabricBlue", bevel=0.02)
    p.box((1.5, 0.08, 0.9), (0, -1.0, 0.65), "WoodDark", bevel=0.02)
    for s in (-0.35, 0.35):
        p.box((0.55, 0.36, 0.13), (s, -0.75, 0.66), "FabricWhite", bevel=0.05)
    return p


@prop("nightstand", cat="home", body="static", col="box")
def nightstand():
    p = Prop("nightstand")
    p.box((0.45, 0.4, 0.5), (0, 0, 0.25), "WoodDark", bevel=0.01)
    p.box((0.4, 0.01, 0.16), (0, 0.2, 0.38), "WoodWarm")
    p.sph(0.014, (0, 0.21, 0.38), "Brass", seg=6)
    return p


@prop("fridge", cat="home", body="static", col="box", inspect="ch2_insp_fridge")
def fridge():
    p = Prop("fridge")
    p.box((0.7, 0.7, 1.75), (0, 0, 0.875), "PaintWhite", bevel=0.03)
    p.box((0.7, 0.01, 0.02), (0, 0.35, 1.2), "PaintGrey")
    p.box((0.03, 0.03, 0.4), (0.27, 0.37, 1.45), "Chrome")
    p.box((0.03, 0.03, 0.5), (0.27, 0.37, 0.75), "Chrome")
    p.box((0.34, 0.006, 0.45), (-0.05, 0.352, 1.45), "Paper", rot=(0, 0, 0))   # feeding schedule
    for i in range(6):
        p.box((0.32, 0.007, 0.04), (-0.05, 0.356, 1.6 - i * 0.07), ["PaintRed", "PaintBlue", "PaintGreen", "PaintYellow", "PaintOrange", "PaintTeal"][i])
    return p


@prop("kitchen_counter", cat="home", body="static", col="box")
def kitchen_counter():
    p = Prop("kitchen_counter")
    p.box((1.2, 0.62, 0.86), (0, 0, 0.43), "WoodWarm", bevel=0.01)
    p.box((1.24, 0.66, 0.04), (0, 0, 0.88), "Concrete", bevel=0.005)
    for s in (-0.3, 0.3):
        p.box((0.55, 0.01, 0.5), (s, 0.31, 0.45), "WoodDark")
        p.sph(0.012, (s + 0.2, 0.32, 0.65), "Chrome", seg=6)
    return p


@prop("stove_oven", cat="home", body="static", col="box", inspect="ch2_insp_oven", hazard=1)
def stove_oven():
    p = Prop("stove_oven")
    p.box((0.62, 0.62, 0.88), (0, 0, 0.44), "SteelBrushed", bevel=0.02)
    p.box((0.56, 0.01, 0.4), (0, 0.31, 0.38), "PaintBlack")
    for x in (-0.14, 0.14):
        for y in (-0.12, 0.12):
            p.cyl(0.09, 0.012, (x, y, 0.895), "PaintBlack", seg=14)
    for i, x in enumerate((-0.2, -0.07, 0.07, 0.2)):
        p.cyl(0.025, 0.03, (x, 0.32, 0.8), "PaintBlack", rot=(90, 0, 0), seg=8)
        p.cyl(0.033, 0.02, (x, 0.335, 0.8), "FabricRed", rot=(90, 0, 0), seg=8)   # oven mitts on the knobs
    return p


@prop("sink_unit", cat="home", body="static", col="box")
def sink_unit():
    p = Prop("sink_unit")
    p.box((1.0, 0.6, 0.86), (0, 0, 0.43), "WoodWarm", bevel=0.01)
    p.box((1.04, 0.64, 0.04), (0, 0, 0.88), "Concrete")
    p.box((0.5, 0.4, 0.02), (0, 0, 0.895), "SteelBrushed")
    p.tube([(0, -0.22, 0.9), (0, -0.22, 1.08), (0, -0.1, 1.12)], 0.012, "Chrome", seg=6)
    return p


@prop("kettle", cat="home", body="rigid", mass=0.9, grab="light", col="cylinder", inspect="ch2_insp_kettle", hazard=1)
def kettle():
    p = Prop("kettle")
    p.lathe([(0.075, 0.0), (0.09, 0.08), (0.075, 0.2), (0.04, 0.23)], (0, 0, 0), "SteelBrushed", seg=14, close_bottom=True)
    p.tube([(0.05, 0, 0.21), (0.11, 0, 0.2), (0.11, 0, 0.1)], 0.01, "PlasticBlack", seg=6)
    p.tube([(-0.07, 0, 0.12), (-0.13, 0, 0.16)], 0.012, "SteelBrushed", seg=6)
    return p


@prop("dog_bed", cat="pickles", body="static", col="box")
def dog_bed():
    p = Prop("dog_bed")
    p.lathe([(0.0, 0.0), (0.42, 0.0), (0.46, 0.05), (0.47, 0.14), (0.42, 0.16), (0.36, 0.09), (0.0, 0.08)], (0, 0, 0.0), "FabricRed", seg=22)
    p.cyl(0.36, 0.06, (0, 0, 0.06), "FabricCream", seg=20)
    return p


@prop("dog_bowl", cat="pickles", body="rigid", mass=0.4, grab="light", col="cylinder", tags=["bowl"], use_verb="Fill bowl")
def dog_bowl():
    p = Prop("dog_bowl")
    p.lathe([(0.07, 0.0), (0.11, 0.05), (0.13, 0.06), (0.105, 0.052), (0.07, 0.01)], (0, 0, 0.0), "SteelBrushed", seg=18)
    p.cyl(0.095, 0.02, (0, 0, 0.03), "SteelDark", seg=16)
    return p


@prop("dog_toy_duck", cat="pickles", body="rigid", mass=0.1, grab="light", col="sphere", tags=["toy", "fetch"])
def dog_toy_duck():
    p = Prop("dog_toy_duck")
    p.sph(0.05, (0, 0, 0.05), "PlasticYellow", seg=10, scale=(1, 1.3, 0.9))
    p.sph(0.03, (0, 0.05, 0.09), "PlasticYellow", seg=8)
    p.box((0.03, 0.03, 0.012), (0, 0.085, 0.085), "PlasticOrange")
    return p


@prop("dog_toy_rope", cat="pickles", body="rigid", mass=0.15, grab="light", col="box", tags=["toy", "fetch"])
def dog_toy_rope():
    p = Prop("dog_toy_rope")
    p.tube([(-0.12, 0, 0.02), (0, 0.01, 0.03), (0.12, 0, 0.02)], 0.014, "FabricRed", seg=6)
    for s in (-1, 1):
        p.sph(0.026, (0.13 * s, 0, 0.026), "FabricBlue", seg=8)
    return p


@prop("pickles_vest", cat="pickles", body="rigid", mass=0.2, grab="light", col="box", inspect="ch2_insp_vest")
def pickles_vest():
    p = Prop("pickles_vest")
    p.box((0.3, 0.2, 0.03), (0, 0, 0.015), "PlasticOrange", bevel=0.01)
    p.box((0.05, 0.2, 0.031), (0, 0, 0.016), "PaintWhite")
    return p


@prop("helmet", cat="home", body="rigid", mass=0.4, grab="light", col="sphere", inspect="ch2_insp_bed")
def helmet():
    p = Prop("helmet")
    p.sph(0.12, (0, 0, 0.09), "PlasticBlue", seg=14, scale=(0.9, 1.1, 0.8))
    p.box((0.2, 0.03, 0.02), (0, 0.1, 0.06), "PlasticBlack")
    return p


@prop("foam_corner", cat="home", body="none", col="none", inspect="ch2_insp_corners")
def foam_corner():
    p = Prop("foam_corner")
    p.box((0.09, 0.09, 0.09), (0, 0, 0.045), "FabricYellow", bevel=0.02)
    return p


@prop("outlet_cover", cat="home", body="none", col="none", inspect="ch2_insp_outlet")
def outlet_cover():
    p = Prop("outlet_cover")
    p.box((0.075, 0.02, 0.115), (0, 0, 0), "PlasticYellow", bevel=0.004)
    return p


@prop("corkboard", cat="home", body="static", col="box", inspect="ch2_insp_wall", tags=["wall"])
def corkboard():
    p = Prop("corkboard")
    p.box((2.4, 0.04, 1.4), (0, 0, 0.7), "Plywood", bevel=0.01)
    p.box((2.3, 0.02, 1.3), (0, 0.025, 0.7), "Cardboard")
    import random
    r = random.Random(4)
    pts = []
    for i in range(14):
        x = r.uniform(-1.0, 1.0); z = r.uniform(0.2, 1.2)
        pts.append((x, z))
        c = ["Paper", "PlasticYellow", "PaintWhite", "PlasticPink"][i % 4]
        p.box((r.uniform(0.15, 0.3), 0.006, r.uniform(0.12, 0.25)), (x, 0.04, z), c, rot=(0, r.uniform(-12, 12), 0))
        p.sph(0.012, (x, 0.05, z + 0.06), "PlasticRed", seg=6)
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[(i * 5 + 3) % len(pts)]
        p.tube([(a[0], 0.052, a[1]), (b[0], 0.052, b[1])], 0.003, "PaintRed", seg=4)
    return p


@prop("rug_livingroom", cat="home", body="none", col="none")
def rug_livingroom():
    p = Prop("rug_livingroom")
    p.box((2.6, 1.8, 0.015), (0, 0, 0.0075), "Rug", bevel=0.004)
    p.box((2.2, 1.4, 0.017), (0, 0, 0.0085), "FabricCream")
    return p


@prop("curtains", cat="home", body="none", col="none")
def curtains():
    p = Prop("curtains")
    p.cyl(0.015, 2.6, (0, 0, 2.3), "Chrome", rot=(0, 90, 0), seg=6)
    for s in (-1, 1):
        for i in range(5):
            p.box((0.1, 0.07, 1.9), (s * (0.95 - i * 0.16), 0.02 * (i % 2), 1.3), "FabricTeal", bevel=0.02)
    return p


@prop("coat_rack", cat="home", body="static", col="box")
def coat_rack():
    p = Prop("coat_rack")
    p.cyl(0.02, 1.7, (0, 0, 0.85), "WoodDark", seg=6)
    p.cyl(0.2, 0.03, (0, 0, 0.015), "WoodDark", seg=12)
    for i in range(4):
        a = i * 90
        p.tube([(0, 0, 1.65), (0.1 * math.cos(math.radians(a)), 0.1 * math.sin(math.radians(a)), 1.72)], 0.01, "WoodDark", seg=5)
    p.box((0.4, 0.1, 0.7), (0.05, 0.08, 1.3), "FabricGreen", bevel=0.03)
    return p


@prop("shoes_pair", cat="home", body="rigid", mass=0.6, grab="light", col="box")
def shoes_pair():
    p = Prop("shoes_pair")
    for s in (-0.07, 0.07):
        p.box((0.09, 0.26, 0.09), (s, 0, 0.045), "ShoeWhite", bevel=0.03)
        p.box((0.095, 0.27, 0.02), (s, 0, 0.01), "Sole")
    return p


@prop("laundry_basket", cat="home", body="rigid", mass=2, grab="medium", col="cylinder")
def laundry_basket():
    p = Prop("laundry_basket")
    p.cyl(0.25, 0.5, (0, 0, 0.25), "PlasticBlue", seg=16, r2=0.3)
    p.box((0.4, 0.3, 0.1), (0, 0, 0.55), "FabricWhite", bevel=0.03)
    return p


@prop("phone", cat="home", body="rigid", mass=0.2, grab="light", col="box", tags=["phone"])
def phone():
    p = Prop("phone")
    p.box((0.075, 0.15, 0.009), (0, 0, 0.0045), "PaintBlack", bevel=0.008)
    p.box((0.068, 0.138, 0.001), (0, 0, 0.0095), "ScreenBlue")
    return p


@prop("framed_photo", cat="home", body="none", col="none")
def framed_photo():
    p = Prop("framed_photo")
    p.box((0.32, 0.025, 0.24), (0, 0, 0), "WoodDark", bevel=0.005)
    p.box((0.28, 0.005, 0.2), (0, 0.015, 0), "SkinTan")
    p.sph(0.03, (-0.04, 0.02, 0.0), "FabricGreen", seg=6)
    p.sph(0.02, (0.04, 0.02, -0.03), "Fur", seg=6)
    return p


@prop("wall_calendar", cat="home", body="none", col="none")
def wall_calendar():
    p = Prop("wall_calendar")
    p.box((0.3, 0.01, 0.4), (0, 0, 0), "Paper")
    for i in range(5):
        for j in range(6):
            p.box((0.03, 0.002, 0.03), (-0.1 + i * 0.05, 0.006, 0.08 - j * 0.05), "PaintBlack" if (i + j) % 7 else "PaintRed")
    return p


@prop("bath_set", cat="home", body="static", col="box")
def bath_set():
    p = Prop("bath_set")
    p.box((1.6, 0.75, 0.55), (0, -0.0, 0.275), "PaintWhite", bevel=0.05)
    p.box((1.45, 0.62, 0.05), (0, 0, 0.56), "Water")
    p.cyl(0.18, 0.4, (1.0, 0, 0.2), "PaintWhite", seg=12)
    p.box((0.4, 0.2, 0.06), (1.0, 0, 0.42), "PaintWhite", bevel=0.02)
    p.box((0.5, 0.4, 0.85), (-1.15, 0, 0.42), "WoodWarm")
    p.box((0.5, 0.42, 0.06), (-1.15, 0, 0.85), "PaintWhite")
    return p


@prop("plant_pot", cat="deco", body="rigid", mass=3, grab="medium", col="cylinder")
def plant_pot():
    p = Prop("plant_pot")
    p.cyl(0.13, 0.22, (0, 0, 0.11), "PaintOrange", seg=12, r2=0.1)
    for i in range(7):
        a = i * 51
        p.sph(0.08, (0.07 * math.cos(math.radians(a)), 0.07 * math.sin(math.radians(a)), 0.32 + 0.05 * (i % 3)), "PaintGreen", seg=6, scale=(1, 1, 1.6))
    return p


@prop("wall_clock_home", cat="home", body="none", col="none")
def wall_clock_home():
    p = Prop("wall_clock_home")
    p.cyl(0.15, 0.03, (0, 0, 0), "PaintWhite", rot=(90, 0, 0), seg=20)
    p.box((0.008, 0.008, 0.1), (0, 0.02, 0.04), "PaintBlack")
    p.box((0.008, 0.008, 0.07), (0.03, 0.02, 0.0), "PaintBlack", rot=(0, -60, 0))
    return p


@prop("door_apartment", cat="doors", body="static", col="box", use_verb="Open", tags=["door"])
def door_apartment():
    """Door leaf with hinge on -X edge; origin at hinge, closed = spans +X 0.9m. Front faces +Y."""
    p = Prop("door_apartment")
    p.box((0.9, 0.045, 2.05), (0.45, 0, 1.025), "WoodWarm", bevel=0.004)
    p.box((0.7, 0.05, 1.75), (0.45, 0, 1.03), "WoodDark")
    p.cyl(0.02, 0.1, (0.82, 0.05, 1.0), "Brass", rot=(90, 0, 0), seg=8)
    p.sph(0.03, (0.82, 0.1, 1.0), "Brass", seg=8)
    for i, z in enumerate((1.55, 1.42, 1.29)):
        p.box((0.05, 0.02, 0.03), (0.75, 0.03, z), "Chrome")     # chain locks
    return p


@prop("door_generic", cat="doors", body="static", col="box", use_verb="Open", tags=["door"])
def door_generic():
    p = Prop("door_generic")
    p.box((0.9, 0.045, 2.05), (0.45, 0, 1.025), "PaintGrey", bevel=0.004)
    p.box((0.16, 0.06, 0.03), (0.75, 0.0, 1.0), "Chrome")
    p.sph(0.025, (0.8, 0.05, 1.0), "Chrome", seg=8)
    return p


@prop("door_glass", cat="doors", body="static", col="box", use_verb="Open", tags=["door"])
def door_glass():
    p = Prop("door_glass")
    p.box((1.0, 0.04, 2.3), (0.5, 0, 1.15), "Glass")
    p.box((0.05, 0.05, 2.3), (0.025, 0, 1.15), "Chrome")
    p.box((0.05, 0.05, 2.3), (0.975, 0, 1.15), "Chrome")
    p.box((1.0, 0.05, 0.05), (0.5, 0, 2.275), "Chrome")
    p.box((1.0, 0.05, 0.12), (0.5, 0, 0.06), "Chrome")
    p.box((0.03, 0.05, 0.7), (0.88, 0.05, 1.05), "Chrome")
    return p
