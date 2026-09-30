"""Halloran Yard (Pickles chapter) + extra station props. Origin = floor centre, front faces +Y."""
import math
from props_registry import prop, text_mesh
from lt_lib import Prop, Vector
from props_transit import _legs4


@prop("shipping_container", cat="yard", body="static", col="box")
def shipping_container():
    p = Prop("shipping_container")
    p.box((2.44, 6.06, 2.6), (0, 0, 1.3), "Corrugated", bevel=0.02)
    p.box((2.5, 0.08, 2.65), (0, 3.0, 1.3), "PaintOrange")
    for s in (-1, 1):
        p.box((0.06, 0.06, 2.5), (s * 0.5, 3.05, 1.3), "SteelDark")
    return p


@prop("crane_gantry", cat="yard", body="static", col="box", inspect="ch6_insp_crane", tags=["crane", "yard"])
def crane_gantry():
    p = Prop("crane_gantry")
    for sx in (-3.2, 3.2):
        for sy in (-1.2, 1.2):
            p.box((0.28, 0.28, 8.0), (sx, sy, 4.0), "PaintYellow", bevel=0.02)
    for sy in (-1.2, 1.2):
        p.box((6.9, 0.36, 0.4), (0, sy, 8.0), "PaintYellow", bevel=0.02)
    for sx in (-3.2, 3.2):
        p.box((0.36, 2.9, 0.3), (sx, 0, 8.0), "PaintYellow")
    p.box((1.0, 1.6, 0.6), (0, 0, 7.55), "PaintOrange", bevel=0.03)
    p.mark("hook", (0, 0, 7.2))
    return p


@prop("crane_hook", cat="yard", body="none", col="none")
def crane_hook():
    p = Prop("crane_hook")
    p.tube([(0, 0, 0), (0, 0, -3.6)], 0.02, "SteelDark", seg=5)
    p.box((0.3, 0.2, 0.4), (0, 0, -3.8), "PaintYellow", bevel=0.02)
    p.tube([(0, 0, -4.0), (0.12, 0, -4.15), (0, 0, -4.3)], 0.03, "SteelDark", seg=6)
    return p


@prop("steel_beam", cat="yard", body="rigid", mass=800, grab=None, col="box", tags=["beam", "yard"], hazard=2)
def steel_beam():
    p = Prop("steel_beam")
    p.box((0.35, 5.0, 0.06), (0, 0, 0.03), "Rust")
    p.box((0.35, 5.0, 0.06), (0, 0, 0.41), "Rust")
    p.box((0.06, 5.0, 0.38), (0, 0, 0.22), "Rust")
    return p


@prop("yard_truck", cat="vehicles", body="rigid", mass=1400, grab=None, col="box", inspect="ch6_insp_truck", tags=["truck", "yard"], hazard=1)
def yard_truck():
    p = Prop("yard_truck")
    p.box((2.0, 2.2, 0.35), (0, 0.1, 0.65), "PaintGreen", bevel=0.05)
    p.box((1.9, 1.2, 0.9), (0, 1.1, 1.3), "PaintGreen", bevel=0.08)
    p.box((1.7, 0.05, 0.6), (0, 1.72, 1.4), "GlassTint")
    p.box((1.92, 2.6, 0.7), (0, -1.2, 0.95), "PaintGreen", bevel=0.03)
    p.box((1.6, 2.5, 0.1), (0, -1.3, 1.32), "Rust")
    p.box((2.0, 0.2, 0.3), (0, 1.9, 0.4), "PaintBlack")
    for sx in (-0.95, 0.95):
        for sy in (1.1, -1.7):
            p.cyl(0.42, 0.28, (sx, sy, 0.42), "Rubber", rot=(0, 90, 0), seg=18)
            p.cyl(0.2, 0.3, (sx, sy, 0.42), "SteelDark", rot=(0, 90, 0), seg=10)
    for sx in (-0.7, 0.7):
        p.sph(0.1, (sx, 1.85, 0.75), "LightTube", seg=8)
    p.box((0.3, 0.1, 0.3), (0, -2.5, 0.55), "PaintBlack")
    return p


@prop("mattress", cat="yard", body="rigid", mass=25, grab="heavy", col="box", inspect="ch6_insp_mattress", tags=["mattress"])
def mattress():
    p = Prop("mattress")
    p.box((1.4, 1.95, 0.24), (0, 0, 0.14), "FabricCream", bevel=0.05)
    for i in range(5):
        for j in range(4):
            p.sph(0.02, (-0.55 + i * 0.27, -0.7 + j * 0.45, 0.27), "FabricBlue", seg=4)
    return p


@prop("hay_bale", cat="yard", body="static", col="box", inspect="ch6_insp_hay", tags=["hay"])
def hay_bale():
    p = Prop("hay_bale")
    p.box((0.9, 0.5, 0.45), (0, 0, 0.225), "WoodWarm", bevel=0.05)
    p.box((0.92, 0.015, 0.47), (0.2, 0, 0.225), "PaintYellow")
    p.box((0.92, 0.015, 0.47), (-0.2, 0, 0.225), "PaintYellow")
    return p


@prop("airbag_safet", cat="yard", body="static", col="box", inspect="ch6_insp_airbag", tags=["airbag", "yard"])
def airbag_safet():
    p = Prop("airbag_safet")
    p.box((4.0, 4.0, 0.15), (0, 0, 0.075), "PlasticBlue")
    p.box((0.4, 0.4, 0.06), (0, 0, 0.18), "PaintYellow")
    text_mesh(p, "SAFE-T-BAG", 0.3, (0, 0, 0.22), "PaintWhite", depth=0.004, rot=(0, 0, 0))
    return p


@prop("airbag_inflated", cat="yard", body="static", col="box", tags=["airbag"])
def airbag_inflated():
    p = Prop("airbag_inflated")
    p.box((4.0, 4.0, 1.6), (0, 0, 0.8), "PlasticBlue", bevel=0.4)
    text_mesh(p, "SAFE-T-BAG", 0.4, (0, 2.02, 0.9), "PaintWhite", depth=0.01, rot=(90, 0, 180))
    return p


@prop("oil_drum", cat="yard", body="rigid", mass=40, grab="heavy", col="cylinder")
def oil_drum():
    p = Prop("oil_drum")
    p.cyl(0.29, 0.88, (0, 0, 0.44), "PaintBlue", seg=18)
    for z in (0.2, 0.44, 0.68):
        p.cyl(0.298, 0.02, (0, 0, z), "SteelDark", seg=18)
    return p


@prop("barrel_red", cat="yard", body="rigid", mass=45, grab="heavy", col="cylinder", tags=["barrel", "yard"], hazard=2, inspect="ch6_insp_barrels")
def barrel_red():
    p = Prop("barrel_red")
    p.cyl(0.29, 0.88, (0, 0, 0.44), "PaintRed", seg=18)
    for z in (0.2, 0.44, 0.68):
        p.cyl(0.298, 0.02, (0, 0, z), "SteelDark", seg=18)
    text_mesh(p, "!", 0.3, (0, 0.3, 0.45), "PaintWhite", depth=0.01, rot=(90, 0, 180))
    return p


@prop("sandwich_wrapper", cat="yard", body="rigid", mass=0.01, grab="light", col="box", inspect="ch6_insp_wrapper", tags=["wrapper", "yard", "fetch"])
def sandwich_wrapper():
    p = Prop("sandwich_wrapper")
    p.box((0.16, 0.12, 0.012), (0, 0, 0.006), "Paper", bevel=0.004, rot=(0, 0, 20))
    return p


@prop("scaffold_tower", cat="yard", body="static", col="box", inspect="ch6_insp_scaffold", tags=["scaffold", "yard"], hazard=1)
def scaffold_tower():
    p = Prop("scaffold_tower")
    for sx in (-0.8, 0.8):
        for sy in (-0.8, 0.8):
            p.cyl(0.024, 5.2, (sx, sy, 2.6), "SteelGalv", seg=6)
    for z in (0.3, 2.0, 3.7, 5.2):
        for s in (-0.8, 0.8):
            p.cyl(0.02, 1.6, (0, s, z), "SteelGalv", rot=(0, 90, 0), seg=6)
            p.cyl(0.02, 1.6, (s, 0, z), "SteelGalv", rot=(90, 0, 0), seg=6)
    for z in (2.0, 3.7, 5.2):
        p.box((1.6, 1.6, 0.05), (0, 0, z + 0.03), "Lumber")
    for k in range(3):
        p.cyl(0.015, 2.4, (0.8, 0, 1.15 + k * 1.7), "SteelGalv", rot=(0, 0, 45), seg=5)
    return p


@prop("scaffold_plank", cat="yard", body="rigid", mass=12, grab="medium", col="box", tags=["plank", "yard"])
def scaffold_plank():
    p = Prop("scaffold_plank")
    p.box((2.4, 0.24, 0.05), (0, 0, 0.025), "Lumber")
    return p


@prop("wrecking_ball", cat="yard", body="none", col="none", inspect="ch6_insp_ball", tags=["ball", "yard"], hazard=2)
def wrecking_ball():
    """Origin at the crane tip; hangs down -Z."""
    p = Prop("wrecking_ball")
    p.tube([(0, 0, 0), (0, 0, -5.0)], 0.03, "SteelDark", seg=6)
    p.sph(0.55, (0, 0, -5.55), "SteelDark", seg=18)
    p.cyl(0.08, 0.16, (0, 0, -4.98), "SteelBrushed", seg=8)
    return p


@prop("crane_arm", cat="yard", body="static", col="box", tags=["crane"])
def crane_arm():
    p = Prop("crane_arm")
    p.box((2.4, 3.0, 1.4), (0, -2.0, 1.2), "PaintYellow", bevel=0.05)
    p.box((0.4, 0.4, 9.0), (0, 0.2, 5.5), "PaintYellow", bevel=0.02, rot=(-8, 0, 0))
    p.box((2.6, 3.2, 0.6), (0, -2.0, 0.3), "PaintBlack")
    for sx in (-1.0, 1.0):
        p.box((0.5, 3.6, 0.6), (sx, -1.6, 0.3), "PaintBlack")
    return p


@prop("vending_lever", cat="yard", body="static", col="box", tags=["lever", "yard"], use_verb="Pull lever")
def vending_lever():
    return _lever("PaintRed")


def _lever(color):
    p = Prop("lever")
    p.box((0.3, 0.3, 0.9), (0, 0, 0.45), "PaintBlack", bevel=0.03)
    p.box((0.06, 0.06, 0.5), (0, 0, 0.9), color, rot=(20, 0, 0))
    p.sph(0.07, (0, -0.09, 1.16), color, seg=8)
    p.box((0.22, 0.02, 0.14), (0, 0.16, 0.6), "SignYellow")
    return p


@prop("yard_lever", cat="yard", body="static", col="box", tags=["lever", "yard"], use_verb="Pull lever")
def yard_lever():
    return _lever("PaintOrange")


@prop("fuse_box", cat="yard", body="static", col="box", tags=["fuse", "yard"], use_verb="Light the fuse")
def fuse_box():
    p = Prop("fuse_box")
    p.box((0.5, 0.3, 0.6), (0, 0, 0.3), "PaintRed", bevel=0.02)
    p.cyl(0.06, 0.12, (0, 0, 0.7), "SteelDark", seg=10)
    p.tube([(0, 0, 0.75), (0.1, 0.2, 0.9), (0.15, 0.3, 0.8)], 0.008, "PaintBlack", seg=4)
    return p


@prop("hazard_sign", cat="yard", body="static", col="box")
def hazard_sign():
    p = Prop("hazard_sign")
    p.cyl(0.03, 1.8, (0, 0, 0.9), "SteelGalv", seg=6)
    p.box((0.7, 0.03, 0.7), (0, 0, 1.6), "SignYellow", rot=(0, 45, 0) if False else (0, 0, 0))
    text_mesh(p, "DANGER", 0.11, (0, 0.03, 1.64), "PaintBlack", depth=0.005, rot=(90, 0, 180))
    text_mesh(p, "KEEP OUT", 0.1, (0, 0.03, 1.48), "PaintBlack", depth=0.005, rot=(90, 0, 180))
    return p


@prop("chain_fence", cat="yard", body="static", col="box")
def chain_fence():
    p = Prop("chain_fence")
    for i in range(3):
        p.cyl(0.04, 2.2, (-2.0 + i * 2.0, 0, 1.1), "SteelGalv", seg=6)
    p.box((4.0, 0.012, 1.9), (0, 0, 1.1), "MirrorMetal")
    p.cyl(0.02, 4.0, (0, 0, 2.15), "SteelGalv", rot=(0, 90, 0), seg=6)
    return p


@prop("tire_stack", cat="yard", body="rigid", mass=50, grab="heavy", col="cylinder")
def tire_stack():
    p = Prop("tire_stack")
    for i in range(4):
        p.lathe([(0.12, 0.0), (0.3, 0.0), (0.34, 0.06), (0.3, 0.12), (0.12, 0.12)], (0, 0, i * 0.12), "Rubber", seg=18)
    return p


@prop("porta_potty", cat="yard", body="static", col="box")
def porta_potty():
    p = Prop("porta_potty")
    p.box((1.1, 1.1, 2.3), (0, 0, 1.15), "PaintBlue", bevel=0.05)
    p.box((0.8, 0.02, 1.9), (0, 0.56, 1.05), "PaintWhite")
    return p


@prop("cable_spool", cat="yard", body="rigid", mass=60, grab="heavy", col="cylinder")
def cable_spool():
    p = Prop("cable_spool")
    p.cyl(0.5, 0.06, (0, 0.28, 0.5), "Lumber", rot=(90, 0, 0), seg=18)
    p.cyl(0.5, 0.06, (0, -0.28, 0.5), "Lumber", rot=(90, 0, 0), seg=18)
    p.cyl(0.3, 0.5, (0, 0, 0.5), "PaintOrange", rot=(90, 0, 0), seg=14)
    return p


@prop("dumpster", cat="yard", body="static", col="box")
def dumpster():
    p = Prop("dumpster")
    p.box((1.8, 1.2, 1.1), (0, 0, 0.75), "PaintGreen", bevel=0.03)
    p.box((1.9, 1.3, 0.06), (0, 0, 1.32), "PaintBlack")
    for sx in (-0.8, 0.8):
        p.cyl(0.08, 0.06, (sx, 0.65, 0.12), "Rubber", rot=(0, 90, 0), seg=8)
    return p


@prop("quarry_rock", cat="yard", body="static", col="convex")
def quarry_rock():
    p = Prop("quarry_rock")
    p.sph(1.2, (0, 0, 0.8), "ConcreteRough", seg=8, scale=(1.3, 1.0, 0.8))
    p.sph(0.7, (0.8, 0.3, 0.5), "ConcreteRough", seg=7)
    return p


@prop("gravel_pile", cat="yard", body="static", col="box")
def gravel_pile():
    p = Prop("gravel_pile")
    p.cyl(2.2, 1.6, (0, 0, 0.8), "Gravel", seg=14, r2=0.15)
    return p


@prop("stump_seat", cat="yard", body="static", col="cylinder", inspect="ch6_insp_stump", tags=["seat", "yard"], use_verb="Sit down")
def stump_seat():
    p = Prop("stump_seat")
    p.cyl(0.35, 0.5, (0, 0, 0.25), "WoodDark", seg=14, r2=0.32)
    return p


@prop("lamp_post", cat="yard", body="static", col="cylinder")
def lamp_post():
    p = Prop("lamp_post")
    p.cyl(0.08, 5.0, (0, 0, 2.5), "PaintGrey", seg=8)
    p.tube([(0, 0, 5.0), (0.5, 0, 5.3), (1.0, 0, 5.2)], 0.05, "PaintGrey", seg=6)
    p.box((0.5, 0.2, 0.08), (1.0, 0, 5.15), "PaintBlack")
    p.box((0.4, 0.15, 0.02), (1.0, 0, 5.1), "LightTube")
    return p


@prop("generator", cat="yard", body="static", col="box")
def generator():
    p = Prop("generator")
    p.box((1.2, 0.7, 0.8), (0, 0, 0.5), "PaintYellow", bevel=0.04)
    p.cyl(0.2, 0.3, (0.4, 0, 1.05), "SteelDark", seg=10)
    return p


@prop("rail_segment", cat="yard", body="static", col="box", tags=["rail"])
def rail_segment():
    p = Prop("rail_segment")
    for s in (-0.72, 0.72):
        p.box((0.07, 4.0, 0.15), (s, 0, 0.18), "Rust")
    for i in range(9):
        p.box((2.0, 0.25, 0.12), (0, -1.8 + i * 0.45, 0.06), "WoodDark")
    return p


@prop("rail_cart", cat="vehicles", body="rigid", mass=800, grab=None, col="box", tags=["rail", "yard"], hazard=1)
def rail_cart():
    p = Prop("rail_cart")
    p.box((1.8, 2.6, 0.2), (0, 0, 0.5), "Rust")
    p.box((1.8, 0.1, 0.7), (0, 1.25, 0.9), "Rust")
    p.box((1.8, 0.1, 0.7), (0, -1.25, 0.9), "Rust")
    for s in (-0.72, 0.72):
        for sy in (-0.9, 0.9):
            p.cyl(0.3, 0.1, (s, sy, 0.3), "SteelDark", rot=(0, 90, 0), seg=14)
    return p


@prop("tank_barrel_blue", cat="yard", body="rigid", mass=30, grab="heavy", col="cylinder")
def tank_barrel_blue():
    p = oil_drum()
    p.name = "tank_barrel_blue"
    return p


# ------------------------------------------------------------------ station extras
@prop("ladder_maint", cat="transit", body="rigid", mass=9, grab="medium", col="box", tags=["ladder", "chain"], hazard=1)
def ladder_maint():
    p = Prop("ladder_maint")
    for s in (-1, 1):
        p.box((0.05, 0.04, 3.4), (s * 0.25, 0, 1.7), "PaintYellow")
    for i in range(10):
        p.box((0.5, 0.03, 0.03), (0, 0, 0.3 + i * 0.32), "SteelGalv")
    return p


@prop("lost_found_desk", cat="transit", body="static", col="box")
def lost_found_desk():
    p = Prop("lost_found_desk")
    p.box((2.2, 0.8, 1.05), (0, 0, 0.525), "PaintTeal", bevel=0.02)
    p.box((2.3, 0.9, 0.05), (0, 0, 1.08), "WoodWarm")
    text_mesh(p, "LOST & FOUND", 0.12, (0, 0.41, 0.6), "PaintWhite", depth=0.005, rot=(90, 0, 180))
    return p


@prop("bridge_segment", cat="transit", body="static", col="box", tags=["bridge", "chain"])
def bridge_segment():
    """6m x 4.5m elevated walkway section: deck + glass rail + light strip."""
    p = Prop("bridge_segment")
    p.box((6.0, 4.5, 0.4), (0, 0, -0.2), "Concrete", bevel=0.02)
    p.box((6.0, 0.06, 1.1), (0, 2.22, 0.55), "GlassTint")
    p.box((6.0, 0.08, 0.06), (0, 2.22, 1.1), "SteelBrushed")
    p.box((6.0, 0.06, 1.1), (0, -2.22, 0.55), "GlassTint")
    p.box((6.0, 0.08, 0.06), (0, -2.22, 1.1), "SteelBrushed")
    p.box((5.8, 0.15, 0.03), (0, 0, 0.02), "PaintYellow")
    return p


@prop("bridge_column", cat="transit", body="static", col="cylinder", tags=["bridge", "chain"])
def bridge_column():
    p = Prop("bridge_column")
    p.cyl(0.45, 5.0, (0, 0, 2.5), "Concrete", seg=16)
    p.cyl(0.6, 0.3, (0, 0, 5.0), "Concrete", seg=16)
    return p


@prop("scaffold_section", cat="transit", body="static", col="box", tags=["scaffold"])
def scaffold_section():
    p = Prop("scaffold_section")
    for sx in (-1.5, 1.5):
        for sy in (-0.5, 0.5):
            p.cyl(0.024, 5.0, (sx, sy, 2.5), "SteelGalv", seg=6)
    for z in (0.5, 2.4, 4.3):
        p.box((3.1, 1.1, 0.05), (0, 0, z), "Lumber")
        for s in (-0.5, 0.5):
            p.cyl(0.02, 3.0, (0, s, z + 0.5), "SteelGalv", rot=(0, 90, 0), seg=6)
    return p


@prop("ceremony_banner", cat="transit", body="none", col="none")
def ceremony_banner():
    p = Prop("ceremony_banner")
    p.box((7.0, 0.04, 1.1), (0, 0, 0), "FabricRed")
    text_mesh(p, "GRAND REOPENING", 0.42, (0, 0.03, 0.15), "PaintWhite", depth=0.005, rot=(90, 0, 180))
    text_mesh(p, "structurally reviewed", 0.2, (0, 0.03, -0.28), "SignYellow", depth=0.005, rot=(90, 0, 180))
    return p


@prop("ribbon_cut", cat="transit", body="none", col="none")
def ribbon_cut():
    p = Prop("ribbon_cut")
    p.box((4.0, 0.01, 0.12), (0, 0, 0), "FabricRed")
    return p


@prop("podium", cat="transit", body="rigid", mass=15, grab="medium", col="box")
def podium():
    p = Prop("podium")
    p.box((0.6, 0.45, 1.05), (0, 0, 0.525), "WoodDark", bevel=0.02)
    p.box((0.65, 0.5, 0.05), (0, 0, 1.05), "WoodWarm", rot=(-8, 0, 0))
    return p


@prop("piano_grand", cat="transit", body="rigid", mass=350, grab=None, col="box", tags=["piano", "chain"], hazard=2)
def piano_grand():
    p = Prop("piano_grand")
    p.box((1.5, 2.0, 0.28), (0, 0, 0.9), "PaintBlack", bevel=0.08)
    p.box((1.4, 0.5, 0.05), (0, 0.85, 0.75), "PaintWhite")
    p.box((1.5, 1.6, 0.05), (0, -0.2, 1.1), "PaintBlack", rot=(30, 0, 0) if False else (0, 0, 0))
    for sx, sy in ((-0.65, 0.8), (0.65, 0.8), (0, -0.85)):
        p.cyl(0.05, 0.75, (sx, sy, 0.4), "PaintBlack", seg=8)
        p.cyl(0.05, 0.05, (sx, sy, 0.03), "Brass", seg=8)
    for i in range(20):
        p.box((0.06, 0.16, 0.02), (-0.57 + i * 0.06, 0.85, 0.79), "PaintBlack" if i % 7 in (1, 2, 4, 5, 6) else "PaintWhite")
    return p


@prop("stroller", cat="transit", body="rigid", mass=8, grab="medium", col="box")
def stroller():
    p = Prop("stroller")
    p.box((0.5, 0.75, 0.3), (0, 0.05, 0.55), "PaintTeal", bevel=0.06)
    p.tube([(-0.22, -0.3, 0.7), (-0.25, -0.5, 1.0), (0.25, -0.5, 1.0), (0.22, -0.3, 0.7)], 0.014, "SteelDark", seg=6)
    for sx in (-0.25, 0.25):
        p.cyl(0.11, 0.04, (sx, -0.3, 0.11), "Rubber", rot=(0, 90, 0), seg=10)
        p.cyl(0.07, 0.04, (sx, 0.3, 0.07), "Rubber", rot=(0, 90, 0), seg=10)
    return p


@prop("crate", cat="transit", body="rigid", mass=12, grab="medium", col="box")
def crate():
    p = Prop("crate")
    p.box((0.6, 0.6, 0.6), (0, 0, 0.3), "Plywood", bevel=0.01)
    for z in (0.1, 0.3, 0.5):
        p.box((0.62, 0.62, 0.03), (0, 0, z), "WoodDark")
    return p
