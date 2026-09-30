"""Community-center wellness pop-up props. Origin = floor centre, front faces +Y."""
import math
from props_registry import prop, text_mesh
from lt_lib import Prop, Vector
from props_transit import _legs4


@prop("yoga_mat", cat="wellness", body="rigid", mass=1.2, grab="light", col="box", inspect="ch4_insp_mat")
def yoga_mat():
    p = Prop("yoga_mat")
    p.box((0.62, 1.75, 0.012), (0, 0, 0.006), "PlasticTeal" if False else "FabricTeal", bevel=0.003)
    return p


@prop("yoga_mat_rolled", cat="wellness", body="rigid", mass=1.2, grab="light", col="cylinder", inspect="ch4_insp_mat")
def yoga_mat_rolled():
    p = Prop("yoga_mat_rolled")
    p.cyl(0.055, 0.62, (0, 0, 0.055), "FabricPurple", rot=(0, 90, 0), seg=14)
    return p


@prop("yoga_block", cat="wellness", body="rigid", mass=0.5, grab="light", col="box")
def yoga_block():
    p = Prop("yoga_block")
    p.box((0.23, 0.15, 0.1), (0, 0, 0.05), "FabricPink", bevel=0.015)
    return p


@prop("treadmill", cat="wellness", body="static", col="box", inspect="ch4_insp_tread", tags=["treadmill", "chain"], hazard=1)
def treadmill():
    p = Prop("treadmill")
    p.box((0.85, 1.8, 0.18), (0, 0, 0.16), "PaintBlack", bevel=0.03)
    p.box((0.7, 1.6, 0.02), (0, 0.02, 0.27), "RubberGym")
    for i in range(10):
        p.box((0.66, 0.02, 0.005), (0, -0.7 + i * 0.16, 0.282), "PaintGrey")
    for s in (-1, 1):
        p.box((0.05, 0.05, 1.2), (s * 0.4, -0.75, 0.75), "PaintBlack")
        p.tube([(s * 0.4, -0.72, 1.0), (s * 0.4, -0.2, 1.05)], 0.02, "PaintBlack", seg=6)
    p.box((0.75, 0.16, 0.34), (0, -0.78, 1.3), "PaintBlack", bevel=0.03, rot=(-20, 0, 0))
    p.box((0.5, 0.01, 0.16), (0, -0.7, 1.36), "ScreenGreen", rot=(-20, 0, 0))
    p.box((0.06, 0.05, 0.07), (0.12, -0.72, 1.16), "PaintRed")         # safety key socket
    p.mark("key", (0.12, -0.72, 1.16))
    return p


@prop("treadmill_key", cat="wellness", body="static", col="box", inspect="ch4_insp_key", tags=["key", "chain"], hazard=1, use_verb="Pull safety key")
def treadmill_key():
    p = Prop("treadmill_key")
    p.box((0.06, 0.04, 0.08), (0, 0, 0.04), "PaintRed", bevel=0.01)
    p.tube([(0, 0, 0.0), (0.02, 0.0, -0.15), (0.04, 0.05, -0.28)], 0.005, "PaintRed", seg=4)
    return p


@prop("resistance_machine", cat="wellness", body="static", col="box", tags=["gym"])
def resistance_machine():
    p = Prop("resistance_machine")
    p.box((0.9, 1.3, 0.1), (0, 0, 0.05), "PaintBlack")
    for s in (-1, 1):
        p.box((0.06, 0.06, 1.9), (s * 0.4, -0.5, 0.95), "PaintGrey")
    p.box((0.86, 0.08, 0.06), (0, -0.5, 1.9), "PaintGrey")
    for i in range(8):
        p.box((0.3, 0.2, 0.05), (0, -0.5, 0.2 + i * 0.07), "PaintBlack")
    p.box((0.5, 0.45, 0.12), (0, 0.15, 0.5), "Leather", bevel=0.03)
    p.box((0.5, 0.12, 0.6), (0, -0.05, 0.85), "Leather", bevel=0.03)
    return p


@prop("dumbbell", cat="wellness", body="rigid", mass=6, grab="medium", col="box", tags=["weights"])
def dumbbell():
    p = Prop("dumbbell")
    p.cyl(0.02, 0.28, (0, 0, 0.09), "Chrome", rot=(0, 90, 0), seg=8)
    for s in (-1, 1):
        p.cyl(0.085, 0.08, (s * 0.15, 0, 0.09), "PaintBlack", rot=(0, 90, 0), seg=6)
    return p


@prop("dumbbell_rack", cat="wellness", body="static", col="box", inspect="ch4_insp_weights")
def dumbbell_rack():
    p = Prop("dumbbell_rack")
    p.box((1.6, 0.5, 0.08), (0, 0, 0.5), "PaintBlack")
    for s in (-1, 1):
        p.box((0.05, 0.45, 0.5), (s * 0.75, 0, 0.25), "PaintBlack")
    for i in range(6):
        for row in (0, 1):
            p.cyl(0.02, 0.28, (-0.65 + i * 0.26, 0.0, 0.58 + row * 0.0), "Chrome", rot=(0, 90, 0), seg=6) if row == 0 else None
            p.cyl(0.075, 0.07, (-0.65 + i * 0.26 - 0.13, 0, 0.62), "PaintBlack", rot=(0, 90, 0), seg=6) if row == 0 else None
            p.cyl(0.075, 0.07, (-0.65 + i * 0.26 + 0.13, 0, 0.62), "PaintBlack", rot=(0, 90, 0), seg=6) if row == 0 else None
    return p


@prop("medicine_ball", cat="wellness", body="rigid", mass=5, grab="medium", col="sphere")
def medicine_ball():
    p = Prop("medicine_ball")
    p.sph(0.16, (0, 0, 0.16), "RubberRed", seg=14)
    return p


@prop("kettlebell", cat="wellness", body="rigid", mass=8, grab="medium", col="sphere")
def kettlebell():
    p = Prop("kettlebell")
    p.sph(0.11, (0, 0, 0.11), "PaintBlack", seg=12)
    p.tube([(-0.06, 0, 0.19), (-0.07, 0, 0.3), (0.07, 0, 0.3), (0.06, 0, 0.19)], 0.018, "PaintBlack", seg=6)
    return p


@prop("candle_pillar", cat="wellness", body="rigid", mass=0.4, grab="light", col="cylinder", tags=["candle"], hazard=1)
def candle_pillar():
    p = Prop("candle_pillar")
    p.cyl(0.04, 0.16, (0, 0, 0.08), "Candle", seg=10)
    p.sph(0.012, (0, 0, 0.18), "Fire", seg=6, scale=(1, 1, 1.8))
    return p


@prop("candle_cluster", cat="wellness", body="static", col="box", inspect="ch4_insp_candles", tags=["candle", "chain"], hazard=2, use_verb="Blow out candles")
def candle_cluster():
    p = Prop("candle_cluster")
    p.box((1.0, 0.5, 0.5), (0, 0, 0.25), "WoodWarm", bevel=0.01)
    import random
    r = random.Random(4)
    for i in range(14):
        h = r.uniform(0.1, 0.28)
        x, y = r.uniform(-0.42, 0.42), r.uniform(-0.18, 0.18)
        p.cyl(0.035, h, (x, y, 0.5 + h / 2), "Candle", seg=8)
        p.sph(0.012, (x, y, 0.5 + h + 0.03), "Fire", seg=6, scale=(1, 1, 1.8))
    return p


@prop("speaker_tall", cat="wellness", body="rigid", mass=12, grab="medium", col="box", inspect="ch4_insp_speaker", tags=["speaker", "chain"], hazard=1)
def speaker_tall():
    p = Prop("speaker_tall")
    p.box((0.36, 0.3, 1.0), (0, 0, 1.35), "PaintBlack", bevel=0.03)
    p.cyl(0.13, 0.02, (0, 0.16, 1.55), "PaintGrey", rot=(90, 0, 0), seg=16)
    p.cyl(0.06, 0.02, (0, 0.16, 1.2), "PaintGrey", rot=(90, 0, 0), seg=12)
    p.cyl(0.02, 0.85, (0, 0, 0.42), "SteelBrushed", seg=6)
    for a in (0, 120, 240):
        p.tube([(0, 0, 0.5), (0.3 * math.cos(math.radians(a)), 0.3 * math.sin(math.radians(a)), 0.02)], 0.012, "SteelBrushed", seg=5)
    return p


@prop("folding_stage", cat="wellness", body="static", col="box", inspect="ch4_insp_stage", tags=["stage", "chain"], hazard=1)
def folding_stage():
    p = Prop("folding_stage")
    for i in range(3):
        p.box((1.2, 2.4, 0.08), (-1.2 + i * 1.2, 0, 0.6), "Plywood")
        for sx in (-0.5, 0.5):
            for sy in (-1.0, 1.0):
                p.box((0.06, 0.06, 0.56), (-1.2 + i * 1.2 + sx, sy, 0.28), "SteelGalv")
    p.box((3.6, 0.03, 0.2), (0, 1.22, 0.45), "FabricPurple")
    p.box((0.05, 0.05, 0.18), (1.2, 0.6, 0.3), "PaintRed")       # pin
    return p


@prop("mic_stand", cat="wellness", body="rigid", mass=2, grab="light", col="cylinder")
def mic_stand():
    p = Prop("mic_stand")
    p.cyl(0.015, 1.5, (0, 0, 0.75), "PaintBlack", seg=6)
    for a in (0, 120, 240):
        p.tube([(0, 0, 0.1), (0.2 * math.cos(math.radians(a)), 0.2 * math.sin(math.radians(a)), 0.01)], 0.01, "PaintBlack", seg=4)
    p.sph(0.03, (0, 0.06, 1.55), "PaintGrey", seg=8)
    return p


@prop("chandelier_crystals", cat="wellness", body="none", col="none", inspect="ch4_insp_crystals", tags=["chandelier", "chain"], hazard=2)
def chandelier_crystals():
    """Origin at the ceiling ribbon anchor; hangs down -Z."""
    p = Prop("chandelier_crystals")
    p.tube([(0, 0, 0.0), (0, 0, -2.4)], 0.02, "FabricPink", seg=6)
    import random
    r = random.Random(12)
    for i in range(26):
        a = r.uniform(0, 6.28); rad = r.uniform(0.05, 0.5); z = -2.4 - r.uniform(0, 0.55)
        p.sph(0.06, (rad * math.cos(a), rad * math.sin(a), z), "GlassFrost", seg=5, scale=(0.7, 0.7, 1.6))
    p.cyl(0.55, 0.06, (0, 0, -2.35), "Brass", seg=18)
    p.tube([(0, 0, -2.4), (0, 0, -2.7)], 0.01, "PlasticWhite", seg=4)
    p.sph(0.24, (0, 0, -2.85), "GlassTint", seg=12)
    return p


@prop("chandelier_winch", cat="wellness", body="static", col="box", inspect="ch4_insp_winch", tags=["winch", "chain"], hazard=1, use_verb="Lower the crystals")
def chandelier_winch():
    p = Prop("chandelier_winch")
    p.box((0.3, 0.16, 0.3), (0, 0, 0.15), "PaintGrey", bevel=0.02)
    p.cyl(0.09, 0.15, (0, 0.05, 0.3), "SteelDark", rot=(0, 90, 0), seg=12)
    p.tube([(0.1, 0.05, 0.3), (0.2, 0.05, 0.4), (0.2, 0.05, 0.2)], 0.012, "PaintRed", seg=5)
    return p


@prop("sauna_cabin", cat="wellness", body="static", col="box", inspect="ch4_insp_sauna", tags=["sauna"])
def sauna_cabin():
    p = Prop("sauna_cabin")
    p.box((3.0, 0.1, 2.4), (0, -1.2, 1.2), "WoodWarm")
    p.box((0.1, 2.5, 2.4), (-1.5, 0, 1.2), "WoodWarm")
    p.box((0.1, 2.5, 2.4), (1.5, 0, 1.2), "WoodWarm")
    p.box((3.1, 2.6, 0.1), (0, 0, 2.45), "WoodWarm")
    p.box((0.95, 0.06, 1.9), (0.9, 1.25, 0.95), "GlassTint")          # door area
    p.box((1.9, 0.06, 1.6), (-0.55, 1.25, 1.2), "WoodWarm")
    p.box((2.6, 0.5, 0.06), (0, -0.8, 0.9), "WoodDark")
    p.box((2.6, 0.5, 0.06), (0, -0.8, 1.5), "WoodDark")
    p.box((0.5, 0.5, 0.6), (-1.05, 0.7, 0.3), "PaintBlack")
    for i in range(7):
        p.sph(0.06, (-1.2 + i * 0.08, 0.7, 0.66), "ConcreteRough", seg=5)
    return p


@prop("steam_generator", cat="wellness", body="static", col="box", inspect="ch4_insp_steam", tags=["steam", "chain"], hazard=1)
def steam_generator():
    p = Prop("steam_generator")
    p.cyl(0.32, 1.0, (0, 0, 0.5), "SteelBrushed", seg=16)
    p.box((0.24, 0.1, 0.3), (0, 0.3, 0.6), "PaintGrey")
    p.tube([(0, 0, 1.0), (0, 0, 1.4), (0.5, 0, 1.6)], 0.04, "SteelDark", seg=8)
    p.cyl(0.1, 0.04, (0.36, 0, 0.75), "PaintRed", rot=(0, 90, 0), seg=14)
    p.mark("valve", (0.4, 0, 0.75))
    return p


@prop("steam_valve", cat="wellness", body="static", col="cylinder", inspect="ch4_insp_steam", tags=["valve", "chain"], hazard=1, use_verb="Close steam valve")
def steam_valve():
    p = Prop("steam_valve")
    p.cyl(0.11, 0.025, (0, 0, 0), "PaintRed", rot=(0, 90, 0), seg=16)
    p.cyl(0.02, 0.1, (0.03, 0, 0), "Brass", rot=(0, 90, 0), seg=8)
    for a in range(4):
        p.box((0.02, 0.02, 0.22), (0, 0, 0), "PaintRed", rot=(a * 45, 0, 0))
    return p


@prop("fountain_feature", cat="wellness", body="static", col="box", inspect="ch4_insp_fountain", tags=["water"], hazard=1)
def fountain_feature():
    p = Prop("fountain_feature")
    p.cyl(0.9, 0.3, (0, 0, 0.15), "ConcreteRough", seg=20)
    p.cyl(0.8, 0.02, (0, 0, 0.31), "Water", seg=20)
    p.cyl(0.25, 0.7, (0, 0, 0.5), "ConcreteRough", seg=12)
    p.cyl(0.5, 0.05, (0, 0, 0.87), "ConcreteRough", seg=16)
    return p


@prop("plunge_pool", cat="wellness", body="static", col="box", inspect="ch4_insp_pool")
def plunge_pool():
    p = Prop("plunge_pool")
    p.box((2.0, 2.0, 0.5), (0, 0, 0.25), "TileTeal", bevel=0.04)
    p.box((1.7, 1.7, 0.02), (0, 0, 0.5), "Water")
    return p


@prop("massage_chair", cat="wellness", body="static", col="box")
def massage_chair():
    p = Prop("massage_chair")
    p.box((0.7, 0.9, 0.35), (0, 0, 0.3), "Leather", bevel=0.06)
    p.box((0.7, 0.2, 0.9), (0, -0.4, 0.75), "Leather", bevel=0.06, rot=(-15, 0, 0))
    p.box((0.7, 0.4, 0.15), (0, 0.6, 0.18), "Leather", bevel=0.04)
    return p


@prop("folding_chair", cat="wellness", body="rigid", mass=3, grab="medium", col="box", tags=["chair"])
def folding_chair():
    p = Prop("folding_chair")
    p.box((0.42, 0.4, 0.03), (0, 0, 0.45), "PlasticGrey", bevel=0.005)
    p.box((0.42, 0.03, 0.4), (0, -0.19, 0.68), "PlasticGrey", rot=(-6, 0, 0))
    for s in (-1, 1):
        p.tube([(s * 0.19, 0.18, 0.45), (s * 0.19, 0.22, 0.0)], 0.012, "SteelDark", seg=5)
        p.tube([(s * 0.19, -0.18, 0.45), (s * 0.19, -0.22, 0.0)], 0.012, "SteelDark", seg=5)
    return p


@prop("blender_machine", cat="wellness", body="static", col="box", inspect="ch4_insp_blender", tags=["blender", "chain"], hazard=1)
def blender_machine():
    p = Prop("blender_machine")
    p.box((0.3, 0.3, 0.25), (0, 0, 0.125), "PaintBlack", bevel=0.03)
    p.cyl(0.11, 0.42, (0, 0, 0.46), "Glass", seg=14, r2=0.09)
    p.cyl(0.115, 0.28, (0, 0, 0.4), "Smoothie", seg=14, r2=0.09)
    p.cyl(0.1, 0.05, (0, 0, 0.7), "PaintBlack", seg=12)
    p.sph(0.03, (0.14, 0.14, 0.18), "LedGreen", seg=6)
    return p


@prop("blender_jug", cat="wellness", body="rigid", mass=0.8, grab="light", col="cylinder", tags=["blender"])
def blender_jug():
    p = Prop("blender_jug")
    p.cyl(0.11, 0.42, (0, 0, 0.21), "Glass", seg=14, r2=0.09)
    p.cyl(0.115, 0.26, (0, 0, 0.14), "Smoothie", seg=14, r2=0.09)
    p.cyl(0.1, 0.04, (0, 0, 0.44), "PaintBlack", seg=12)
    return p


@prop("smoothie_bar", cat="wellness", body="static", col="box", tags=["bar"])
def smoothie_bar():
    p = Prop("smoothie_bar")
    p.box((3.0, 0.8, 1.05), (0, 0, 0.525), "WoodWarm", bevel=0.02)
    p.box((3.1, 0.9, 0.05), (0, 0, 1.08), "Concrete")
    p.box((3.0, 0.05, 0.4), (0, 0.4, 0.55), "FabricGreen")
    text_mesh(p, "ALIGNED ELIXIRS", 0.14, (0, 0.43, 1.6), "SignWhite", depth=0.02, rot=(90, 0, 180))
    p.box((2.4, 0.03, 0.4), (0, 0.42, 1.6), "FabricGreen")
    return p


@prop("water_cooler", cat="wellness", body="static", col="box")
def water_cooler():
    p = Prop("water_cooler")
    p.box((0.35, 0.35, 1.0), (0, 0, 0.5), "PaintWhite", bevel=0.03)
    p.cyl(0.15, 0.4, (0, 0, 1.2), "GlassTint", seg=14)
    return p


@prop("towel_stack", cat="wellness", body="rigid", mass=1, grab="light", col="box")
def towel_stack():
    p = Prop("towel_stack")
    for i in range(5):
        p.box((0.36, 0.26, 0.05), (0, 0, 0.025 + i * 0.05), ["FabricWhite", "FabricTeal", "FabricWhite", "FabricPink", "FabricWhite"][i], bevel=0.01)
    return p


@prop("lantern_paper", cat="wellness", body="none", col="none")
def lantern_paper():
    p = Prop("lantern_paper")
    p.sph(0.22, (0, 0, -0.6), "LightWarm", seg=10, scale=(1, 1, 1.2))
    p.tube([(0, 0, 0), (0, 0, -0.4)], 0.004, "PlasticBlack", seg=4)
    return p


@prop("gong_stand", cat="wellness", body="static", col="box", inspect="ch4_insp_gong", tags=["gong", "chain"], hazard=2)
def gong_stand():
    p = Prop("gong_stand")
    for s in (-1, 1):
        p.box((0.07, 0.5, 2.2), (s * 0.7, 0, 1.1), "WoodDark", bevel=0.01)
    p.box((1.5, 0.08, 0.08), (0, 0, 2.1), "WoodDark")
    p.cyl(0.5, 0.04, (0, 0.0, 1.35), "Brass", rot=(90, 0, 0), seg=24)
    p.tube([(-0.3, 0, 2.1), (-0.3, 0, 1.75)], 0.008, "PlasticBlack", seg=4)
    p.tube([(0.3, 0, 2.1), (0.3, 0, 1.75)], 0.008, "PlasticBlack", seg=4)
    return p


@prop("curtain_drape", cat="wellness", body="none", col="none")
def curtain_drape():
    p = Prop("curtain_drape")
    for i in range(9):
        p.box((0.12, 0.06, 3.2), (-0.5 + i * 0.125, 0.02 * (i % 2), 1.6), "FabricPurple", bevel=0.02)
    return p


@prop("mirror_wall", cat="wellness", body="none", col="none", inspect="ch4_insp_mirror")
def mirror_wall():
    p = Prop("mirror_wall")
    p.box((4.0, 0.03, 2.0), (0, 0, 1.0), "MirrorMetal")
    p.box((4.05, 0.04, 0.05), (0, 0, 0.03), "PaintBlack")
    return p


@prop("singing_bowl", cat="wellness", body="rigid", mass=0.6, grab="light", col="cylinder")
def singing_bowl():
    p = Prop("singing_bowl")
    p.lathe([(0.0, 0.0), (0.05, 0.0), (0.11, 0.06), (0.14, 0.11), (0.135, 0.11), (0.1, 0.06), (0.0, 0.01)], (0, 0, 0.0), "Brass", seg=18)
    return p


@prop("clipboard", cat="wellness", body="rigid", mass=0.3, grab="light", col="box")
def clipboard():
    p = Prop("clipboard")
    p.box((0.23, 0.32, 0.012), (0, 0, 0.006), "Plywood")
    p.box((0.2, 0.28, 0.004), (0, 0, 0.014), "Paper")
    p.box((0.08, 0.03, 0.02), (0, 0.15, 0.02), "Chrome")
    return p


@prop("wet_sign_a", cat="wellness", body="rigid", mass=1, grab="light", col="box")
def wet_sign_a():
    from props_transit import wet_floor_sign
    return wet_floor_sign()


@prop("banner_rollup", cat="wellness", body="rigid", mass=3, grab="medium", col="box")
def banner_rollup():
    p = Prop("banner_rollup")
    p.box((0.85, 0.05, 0.06), (0, 0, 0.03), "PaintGrey")
    p.box((0.8, 0.012, 2.0), (0, 0, 1.05), "FabricGreen")
    text_mesh(p, "ALIGNED LIVING", 0.13, (0, 0.012, 1.7), "PaintWhite", depth=0.004, rot=(90, 0, 180))
    text_mesh(p, "your energy, curated", 0.07, (0, 0.012, 1.45), "PaintWhite", depth=0.003, rot=(90, 0, 180))
    return p
