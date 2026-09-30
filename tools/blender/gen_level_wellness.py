"""Riverbend Community Recreation Center -- Aligned Living pop-up (chapter 4).
blender -b --python tools/blender/gen_level_wellness.py
Hall x[-20,20] z[-16,16] H=7.5; lobby z[16,24]; stage north; fitness corner west; smoothie bar + sauna east.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lv_lib import Level

lv = Level("wellness")
H = 7.5
rnd = random.Random(31)

lv.region("floor")
lv.slab(-20, -16, 20, 16, 0.0, 0.4, "Wood", surface="wood")
lv.slab(-8, 16, 8, 24, 0.0, 0.4, "TileGrey", surface="tile")
lv.slab(-20, -3, -13.5, 6, 0.02, 0.05, "RubberGym", surface="rubber")      # treadmill mats
lv.visual_box((-20, 0.0, -16), (20, 0.011, -15.8), "WoodDark")
# free-throw court markings
lv.visual_box((-19.9, 0.0, 15.8), (19.9, 0.011, 15.9), "PaintOrange")
lv.visual_box((-0.05, 0.0, -14), (0.05, 0.011, 15.8), "PaintWhite")
lv.slab(-13, 6.0, -6, 13, 0.02, 0.05, "CarpetSage", surface="carpet")       # fountain nook rug

lv.region("walls")
lv.wall(-20.3, -16.3, -20.3, 16.6, 0, H, 0.6, "WallSage")
lv.wall(20.3, -16.3, 20.3, 16.6, 0, H, 0.6, "WallSage")
lv.wall(-20, -16.3, 20, -16.3, 0, H, 0.6, "WallCream")
lv.wall(-20, 16.3, 20, 16.3, 0, H, 0.6, "WallCream", openings=[(12, 28, 0.0, 3.2)])
# lobby
lv.wall(-8.3, 16.6, -8.3, 24.3, 0, 4.2, 0.6, "WallCream")
lv.wall(8.3, 16.6, 8.3, 24.3, 0, 4.2, 0.6, "WallCream")
lv.wall(-8, 24.3, 8, 24.3, 0, 4.2, 0.6, "WallCream", openings=[(6, 10, 0.0, 3.0)])
lv.ceiling(-8, 16, 8, 24, 4.2, 0.3, "CeilingTile")
lv.solid((-2.5, 0.0, 24.0), (2.5, 3.0, 24.05), "Glass", col=True, surface="glass") if False else None
# high clerestory windows (light shafts)
for x in range(-16, 17, 8):
    lv.solid((x - 1.8, 5.0, -16.05), (x + 1.8, 6.8, -15.95), "Glass", col=False)
    lv.solid((x - 1.8, 5.0, 15.95), (x + 1.8, 6.8, 16.05), "Glass", col=False)
# basketball hoop backboards (decor)
for x in (-19.6, 19.6):
    lv.visual_box((x - 0.05, 3.0, -1.0), (x + 0.05, 4.2, 1.0), "PaintWhite")
    lv.cyl(x * 0.985, 3.0, 0, 0.23, 0.02, "PaintOrange")
lv.region("ceiling")
lv.ceiling(-20, -16, 20, 16, H, 0.4, "CeilingTile")
for i in range(9):
    lv.visual_box((-20, H - 0.6, -15 + i * 3.75 - 0.12), (20, H, -15 + i * 3.75 + 0.12), "SteelGalv")
lv.region("columns")
for z in (-8, 0, 8):
    for x in (-14, 14):
        lv.column(x, z, 0, H, 0.45, "PaintTeal") if False else lv.column(x, z, 0, H, 0.45, "WallSage")

# ---- plunge alcove tile floor
lv.slab(8, 8.5, 20, 16, 0.02, 0.05, "TileTeal", surface="tile")
# ---- exterior lot
lv.region("lot")
lv.slab(-50, 24.6, 50, 80, -0.1, 0.4, "Asphalt", surface="concrete")
lv.slab(-8, 24.6, 8, 34, 0.0, 0.4, "Sidewalk", surface="concrete")
for x in range(-40, 42, 6):
    lv.visual_box((x, -0.08, 42), (x + 0.15, -0.06, 50), "PaintWhite")
lv.solid((-50, 0, 79.6), (50, 8, 80), "WallGrey", col=True, visible=False)
lv.solid((-50.5, 0, 24.6), (-50, 8, 80), "WallGrey", col=True, visible=False)
lv.solid((50, 0, 24.6), (50.5, 8, 80), "WallGrey", col=True, visible=False)
lv.solid((-50, 0, 24.6), (-8.4, 8, 24.7), "WallGrey", col=True, visible=False)
lv.solid((8.4, 0, 24.6), (50, 8, 24.7), "WallGrey", col=True, visible=False)
lv.text("RIVERBEND", 0.9, (0, 3.6, 24.66), "SignWhite", rot=(90, 0, 0), depth=0.05)
lv.text("COMMUNITY RECREATION CENTER", 0.28, (0, 2.95, 24.66), "SignWhite", rot=(90, 0, 0), depth=0.04)
for i in range(24):
    x = -70 + i * 6.3 + rnd.uniform(-1, 1)
    h = rnd.uniform(6, 16)
    lv.visual_box((x - 2.2, -1, 90), (x + 2.2, h, 96), rnd.choice(["Brick", "WallGrey", "ConcreteDark"]))

# ---- lighting: warm dusk through clerestory, candles, spot on stage
for x in (-14, 0, 14):
    for z in (-10, 0, 10):
        lv.light("omni", (x, H - 1.0, z), (1.0, 0.92, 0.78), 1.2, 12.0, False, fog=0.4)
lv.light("spot", (0, H - 0.8, -8.5), (1.0, 0.9, 0.75), 4.0, 14.0, True, spot_angle=42, dir_deg=(-72, 0, 0), name="StageSpot")
lv.light("omni", (0, 4.4, -11.6), (1.0, 0.85, 0.6), 1.2, 6.0, False, name="ChandelierGlow")
lv.light("omni", (16, 2.4, -6), (1.0, 0.6, 0.85), 1.0, 5.0, False, name="BarGlow")
lv.light("omni", (16, 2.2, 6), (1.0, 0.75, 0.5), 0.9, 6.0, False, name="SaunaGlow")
lv.light("omni", (-16.5, 3.4, 0), (0.85, 0.95, 1.0), 1.0, 8.0, False, name="GymLight")
lv.light("omni", (0, 3.4, 20), (1.0, 0.95, 0.85), 1.4, 8.0, False, name="LobbyLight")
lv.light("dir", (0, 30, 60), (1.0, 0.7, 0.45), 0.6, 100.0, False, dir_deg=(-14, 160, 0), name="SunsetSun")
lv.zone((-20, 0, -16), (20, H, 16), "RevLarge", 0.5, "HallReverb")
lv.zone((-8, 0, 16), (8, 4.2, 24), "RevSmall", 0.35, "LobbyReverb")
lv.zone((-50, -0.5, 24.7), (50, 20, 80), "RevOutdoor", 0.2, "LotReverb")
lv.probe((-20, 0, -16), (0, H, 16))
lv.probe((0, 0, -16), (20, H, 16))
lv.occluder((-20.6, 0, -16.6), (-20.0, H, 16.6))
lv.occluder((20.0, 0, -16.6), (20.6, H, 16.6))
lv.occluder((-20, 0, -16.6), (20, H, -16.0))
lv.env = {"kind": "exterior_dusk", "sky_top": [0.18, 0.2, 0.42], "sky_horizon": [0.95, 0.6, 0.4], "ambient_energy": 0.42, "fog": 0.014,
          "fog_color": [0.8, 0.6, 0.5], "exposure": 1.05, "sdfgi": True, "vfog": True, "grade": "sunset", "dof": True}

P = lv.place
# ---- stage + chandelier
P("folding_stage", (0, 0, -12.8), 0, name="Stage")
P("mic_stand", (0, 0.64, -12.0), 0, name="MicStand")
P("speaker_tall", (-4.6, 0, -10.6), 15, name="SpeakerL")
P("speaker_tall", (4.6, 0, -10.6), -15, name="SpeakerR")
P("chandelier_crystals", (0, 7.3, -11.4), 0, name="Chandelier")
P("chandelier_winch", (8.6, 1.3, -15.5), 0, name="Winch")
for i in range(4):
    P("curtain_drape", (-6.7 + i * 4.5, 0.3, -15.6), 0, name="Curtain%d" % (i + 1))
P("candle_cluster", (-2.4, 0, -10.6), 0, name="CandlesStageL")
P("candle_cluster", (2.4, 0, -10.6), 0, name="CandlesStageR")
P("candle_cluster", (-5.2, 0, -14.9), 0, name="CandlesCurtainL")
P("candle_cluster", (5.2, 0, -14.9), 0, name="CandlesCurtainR")
P("banner_rollup", (-3.3, 0, -9.6), 0, name="AlignedBanner1")
P("banner_rollup", (3.3, 0, -9.6), 0, name="AlignedBanner2")
P("gong_stand", (10.0, 0, -12.5), 0, name="Gong")
# ---- audience mats + chairs
for r in range(4):
    for c in range(6):
        P("yoga_mat", (-7.5 + c * 3.0, 0.02, -5.0 + r * 3.0), 0, name="Mat_%d_%d" % (r, c))
for c in range(5):
    P("folding_chair", (-6 + c * 3.0, 0, 8.0), 180, name="Chair%d" % (c + 1))
P("yoga_block", (-4.0, 0.03, -3.5), 20, name="Block1")
P("yoga_mat_rolled", (-2.0, 0.03, 0.2), 90, name="MatRoll1")
P("singing_bowl", (0.0, 0.03, -1.2), 0, name="Bowl1")
# ---- smoothie bar (east) + electrical mess
P("smoothie_bar", (17.6, 0, -6.0), 90, name="SmoothieBar")
P("blender_machine", (17.9, 1.02, -6.9), 90, name="BarBlender")
P("blender_jug", (17.9, 1.02, -5.2), 0, name="SpareJug")
P("water_cooler", (19.4, 0, -10.5), 0, name="WaterCooler")
P("power_strip", (14.5, 0.0, -6.9), 0, name="BarStrip")
P("extension_cord_floor", (13.0, 0, -7.6), 15, name="BarCordA")
P("extension_cord_floor", (11.0, 0, -8.6), -20, name="BarCordB")
P("power_strip", (10.2, 0.0, -9.0), 90, name="BarStrip2")
P("towel_stack", (18.9, 1.05, -3.0), 0, name="Towels1")
# ---- steam room / sauna
P("sauna_cabin", (17.4, 0, 6.0), -90, name="Sauna")
P("steam_generator", (19.3, 0, 2.2), 90, name="SteamGen")
P("steam_valve", (18.85, 1.2, 2.2), 0, name="SteamValve")
P("plunge_pool", (13.0, 0.02, 12.6), 0, name="PlungePool")
P("massage_chair", (18.6, 0, 13.6), 200, name="MassageChair")
P("lantern_paper", (10.0, 3.4, 10.0), 0, name="Lantern1")
P("lantern_paper", (16.0, 3.4, 11.0), 0, name="Lantern2")
# ---- water feature nook
P("fountain_feature", (-9.5, 0.05, 9.5), 0, name="Fountain")
P("extension_cord_floor", (-8.0, 0, 7.4), -70, name="FountainCord")
P("power_strip", (-6.3, 0.0, 6.4), 0, name="FountainStrip")
P("candle_cluster", (-12.0, 0, 11.6), 0, name="CandlesFountain")
# ---- fitness corner (west)
for i in range(4):
    P("treadmill", (-16.6, 0.02, -2.0 + i * 2.3), -90, name="Treadmill%d" % (i + 1))
P("mirror_wall", (-19.95, 0.1, 0.0), -90, name="MirrorWall")
P("resistance_machine", (-16.8, 0, 8.6), -90, name="Resistance1")
P("dumbbell_rack", (-19.3, 0, -8.0), -90, name="DumbbellRack")
P("dumbbell", (-19.2, 0.66, -8.0), 0, name="Dumbbell1")
P("dumbbell", (-17.0, 0.02, -6.0), 30, name="Dumbbell2")
P("kettlebell", (-17.8, 0, -10.0), 0, name="Kettlebell1")
P("medicine_ball", (-16.0, 0, -9.4), 0, name="MedBall1")
P("wet_sign_a", (-12.6, 0, 4.4), 30, name="WetSign")
P("treadmill_key", (-16.9, 1.02, 1.5), 0, name="SafetyKey_Marco")
# ---- misc
P("fire_extinguisher", (19.7, 0, 10.0), 90, name="Extinguisher1")
P("fire_extinguisher", (-19.7, 0, 13.0), -90, name="Extinguisher2")
P("plant_ficus", (-7.0, 0, 18.4), 0, name="LobbyPlant1")
P("plant_ficus", (7.0, 0, 18.4), 0, name="LobbyPlant2")
P("bench", (-4.0, 0, 21.4), 0, name="LobbyBench")
P("sign_exit", (0, 3.2, 15.9), 180, name="ExitSignHall")
P("sedan", (-22, 0, 52), 0, name="CarA")
P("sedan", (24, 0, 60), 180, name="CarB")
P("street_lamp", (-12, 0, 30), 0, name="LotLamp1")
P("street_lamp", (12, 0, 30), 180, name="LotLamp2")
P("tree_street", (-24, 0, 32), 0, name="LotTree1")

# ---- markers
lv.marker("PlayerStart", (0, 0.05, 40), 0)
lv.marker("PicklesStart", (1.4, 0.05, 41), 0)
lv.marker("Lobby", (0, 0.05, 19.5), 0)
lv.marker("TiffanyLobby", (-3.0, 0.05, 20), 200)
lv.marker("TiffanyStage", (0.0, 0.64, -12.2), 0)
lv.marker("TiffanyMat", (0.0, 0.05, -8.0), 0)
lv.marker("GusSpot", (9.0, 0.05, 4.0), 250)
lv.marker("GusBar", (13.2, 0.05, -7.8), 90)
lv.marker("GusStage", (4.0, 0.05, -9.5), 0)
lv.marker("GusSteam", (17.2, 0.05, 2.6), 90)
lv.marker("GusFountain", (-7.5, 0.05, 7.4), 180)
lv.marker("GusCandle", (-4.0, 0.05, -9.0), 0)
lv.marker("GusTread", (-14.6, 0.05, 2.0), 270)
lv.marker("GusGong", (8.6, 0.05, -11.2), 0)
lv.marker("GusSpeaker", (4.0, 0.05, -9.4), 0)
lv.marker("MarcoTread", (-16.6, 0.02, -2.0), 270)
lv.marker("LuisTread", (-16.6, 0.02, 0.3), 270)
lv.marker("MarcoFall", (-19.4, 0.05, -2.0), 270)
lv.marker("BrendaSpot", (-5.5, 0.05, 2.6), 0)
lv.marker("WinchSpot", (7.6, 0.05, -14.0), 0)
lv.marker("ChandelierHang", (0, 7.3, -11.4), 0)
lv.marker("ChandelierLow", (0, 1.7, -11.4), 0)
lv.marker("StrangerBlend", (16.5, 0.05, -6.6), 90)
lv.marker("StrangerA", (-1.5, 0.05, -4.0), 0)
lv.marker("StrangerB", (4.5, 0.05, -1.0), 0)
lv.marker("StrangerC", (-4.5, 0.05, 0.5), 0)
lv.marker("StrangerD", (2.0, 0.05, 2.5), 0)
lv.marker("SpeakerFeedback", (4.6, 1.6, -10.6), 0)
lv.marker("CandleCurtain", (5.2, 0.3, -14.9), 0)
lv.marker("SprinklerA", (-3, 6.5, -8), 0)
lv.marker("SprinklerB", (3, 6.5, -8), 0)
lv.marker("SprinklerC", (0, 6.5, -2), 0)
lv.marker("ExitOut", (0, 0.05, 30), 180)
lv.export()
