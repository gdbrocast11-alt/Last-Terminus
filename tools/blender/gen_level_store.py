"""Toolbert's Home Center, after hours (chapter 3). blender -b --python tools/blender/gen_level_store.py

Store x[-32,32] z[-26,26] H=8.5. Storefront (south, z=+26). Paint dept west, tools north-centre,
garden centre east/south-east. Chain geometry (see scripts/chapters/ch3_store.gd markers):
coin -> power strip -> compressor -> nail gun -> paint stack -> rolling ladder -> fan rack -> banner/tire
-> hose reel/sprinklers -> slip -> forklift handle -> flamingo pallet.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lv_lib import Level

lv = Level("store")
H = 8.5
rnd = random.Random(11)

lv.region("floor")
lv.slab(-32, -26, 32, 26, 0.0, 0.4, "Concrete", surface="concrete")
# garden centre grass patch + yellow aisle striping
lv.slab(15, -9, 31.6, 20, 0.02, 0.05, "Grass", surface="grass")
for x in (-9, 0, 9):
    lv.visual_box((x - 0.06, 0.0, -20), (x + 0.06, 0.012, 24), "PaintYellow")
lv.visual_box((-30, 0.0, 12.9), (14, 0.012, 13.1), "PaintYellow")

lv.region("walls")
lv.wall(-32.3, -26.3, -32.3, 26.6, 0, H, 0.6, "WallGrey")
lv.wall(32.3, -26.3, 32.3, 26.6, 0, H, 0.6, "WallGrey")
lv.wall(-32, -26.3, 32, -26.3, 0, H, 0.6, "WallGrey")
lv.wall(-32, 26.3, 32, 26.3, 0, H, 0.6, "WallGrey", openings=[(2, 30, 0.0, 3.6), (34, 62, 0.0, 3.6), (30, 34, 0.0, 3.4)])
for (x0, x1) in ((-30, -2), (2, 30)):
    lv.solid((x0, 0.0, 26.0), (x1, 3.6, 26.06), "Glass", col=True, surface="glass")
    for xx in [x0 + i * 4.0 for i in range(int((x1 - x0) / 4.0) + 1)]:
        lv.solid((xx - 0.05, 0.0, 25.95), (xx + 0.05, 3.6, 26.12), "PaintOrange", col=False)
# orange band + TOOLBERT'S fascia
lv.visual_box((-32, 3.6, 25.95), (32, 6.0, 26.02), "PaintOrange")
lv.text("TOOLBERT'S", 1.6, (0, 4.6, 26.05), "SignWhite", rot=(90, 0, 0), depth=0.06)
lv.text("HOME CENTER", 0.55, (0, 3.85, 26.05), "SignWhite", rot=(90, 0, 0), depth=0.04)

lv.region("ceiling")
lv.ceiling(-32, -26, 32, 26, H, 0.4, "Corrugated")
for i in range(9):
    z = -24 + i * 6.0
    lv.visual_box((-32, H - 0.9, z - 0.15), (32, H, z + 0.15), "SteelGalv")
for i in range(-4, 5):
    lv.visual_box((i * 7 - 0.12, H - 1.3, -26), (i * 7 + 0.12, H - 0.9, 26), "SteelDark")
for x in (-24, -8, 8, 24):
    for z in (-18, -6, 6, 18):
        lv.visual_box((x - 0.7, H - 1.5, z - 0.12), (x + 0.7, H - 1.4, z + 0.12), "LightTube")  # tube fixtures (emissive)

lv.region("columns")
for x in (-24, -8, 8, 24):
    for z in (-18, 0, 18):
        lv.column(x, z, 0, H, 0.5, "PaintYellow")
        lv.solid((x - 0.28, 0, z - 0.28), (x + 0.28, 0.9, z + 0.28), "Hazard", col=False)

# ---- garden-centre greenhouse partition (glass wall with opening)
lv.region("garden")
lv.wall(14.5, -9.0, 14.5, 20.0, 0, 4.0, 0.12, "Glass", openings=[(4.0, 8.0, 0.0, 3.6), (18.0, 22.0, 0.0, 3.6)], surface="glass")
lv.wall(14.5, -9.0, 32.0, -9.0, 0, 4.0, 0.12, "Glass", openings=[(6.0, 9.0, 0.0, 3.6)], surface="glass")
lv.visual_box((14.4, 4.0, -9.1), (14.6, 4.15, 20.0), "PaintOrange")
lv.visual_box((14.4, 0.0, -9.1), (14.6, 0.3, 20.0), "PaintOrange")
# loading-dock door on the east wall (behind the forklift)
lv.wall(31.9, 0.0, 31.9, 8.0, 0.0, 4.0, 0.2, "Corrugated") if False else None
# ---- exterior (parking lot at night)
lv.region("lot")
lv.slab(-70, 26.6, 70, 90, -0.1, 0.4, "Asphalt", surface="concrete")
for x in range(-56, 60, 6):
    lv.visual_box((x, -0.08, 36), (x + 0.15, -0.06, 44), "PaintWhite")
lv.solid((-70, -0.1, 90), (70, 8, 90.5), "WallGrey", col=True, visible=False)
lv.solid((-70.5, -0.1, 26.6), (-70, 8, 90.5), "WallGrey", col=True, visible=False)
lv.solid((70, -0.1, 26.6), (70.5, 8, 90.5), "WallGrey", col=True, visible=False)
for i in range(30):
    x = -80 + i * 5.6 + rnd.uniform(-1, 1)
    h = rnd.uniform(8, 22)
    lv.visual_box((x - 2, -1, 100), (x + 2, h, 106), rnd.choice(["ConcreteDark", "Brick", "WallGrey"]))
    for r in range(int(h // 3)):
        if rnd.random() < 0.3:
            lv.visual_box((x - 1, r * 3 + 1.5, 99.9), (x + 1, r * 3 + 2.5, 100.0), "LightWarm")

# ---- lights (after-hours: half the bank is off; tubes flicker in script)
for x in (-24, -8, 8, 24):
    for z in (-18, -6, 6, 18):
        lv.light("omni", (x, H - 1.6, z), (0.85, 0.95, 1.0), 1.3, 13.0, False, name="Tube_%d_%d" % (x, z), fog=0.5)
lv.light("spot", (0.5, H - 1.7, -8), (1.0, 0.92, 0.8), 3.0, 14.0, True, spot_angle=55, dir_deg=(-90, 0, 0), name="ToolSpot")
lv.light("omni", (22, 5.5, 6), (0.85, 1.0, 0.8), 1.6, 12.0, True, name="GardenLight")
lv.light("omni", (0, 3.2, 30), (1.0, 0.9, 0.7), 2.0, 10.0, False, name="FrontLight")
lv.light("dir", (0, 30, 60), (0.45, 0.55, 0.85), 0.18, 100.0, False, dir_deg=(-50, 20, 0), name="Moon")
lv.zone((-32, 0, -26), (32, H, 26), "RevLarge", 0.45, "StoreReverb")
lv.zone((-70, -0.5, 26.6), (70, 20, 90), "RevOutdoor", 0.2, "LotReverb")
lv.probe((-32, 0, -26), (0, H, 26))
lv.probe((0, 0, -26), (32, H, 26))
lv.occluder((-32.6, 0, -26.6), (-32.0, H, 26.6))
lv.occluder((32.0, 0, -26.6), (32.6, H, 26.6))
lv.occluder((-32, 0, -26.6), (32, H, -26.0))
lv.env = {"kind": "exterior_night", "sky_top": [0.02, 0.04, 0.12], "sky_horizon": [0.1, 0.13, 0.25], "ambient_energy": 0.45, "fog": 0.008,
          "fog_color": [0.35, 0.4, 0.5], "exposure": 1.05, "sdfgi": True, "vfog": True, "grade": "cool_teal", "dof": True}

P = lv.place
# ===== front of store
for i, x in enumerate((-10, -4, 2, 8)):
    P("checkout_lane", (x, 0, 19), 0, name="Checkout%d" % (i + 1))
for i in range(5):
    P("shopping_cart", (-27 + i * 0.7, 0, 22.5), 8 * i, name="Cart%d" % (i + 1))
P("sign_exit", (-1.5, 3.7, 25.6), 180, name="ExitSign")
P("aisle_sign", (-24, 5.2, 12.0), 0, name="SignPaint", opts={})
P("aisle_sign", (0, 5.2, -5.5), 0, name="SignTools")
P("aisle_sign", (22, 5.2, 12.0), 0, name="SignGarden")
# ===== paint department (west)
for i in range(5):
    P("shelving_unit", (-31.5, 0, -18 + i * 2.05), -90, name="PaintShelfW%d" % (i + 1))
for i in range(4):
    P("shelving_unit", (-20.5, 0, -16.0 + i * 2.05), 90, name="PaintShelfA%d" % (i + 1))
    P("shelving_unit", (-19.7, 0, -16.0 + i * 2.05), -90, name="PaintShelfB%d" % (i + 1))
P("paint_mixer", (-25.0, 0, 3.0), 90, name="PaintMixer", opts={"hazard": 0})
P("paint_shaker", (-25.0, 0, 5.0), 90, name="PaintShaker")
P("paint_can", (-25.4, 1.05, 4.0), 0, name="BarnRedCan")
P("wet_floor_sign", (-22.0, 0, 5.5), 40, name="PaintWetSign")
P("paint_can", (-27.8, 0, 6.2), 0, name="PaintCanFloor1")
P("bucket", (-27.5, 0, 1.0), 0, name="Bucket1")
P("ladder_step", (-28.5, 0, -1.5), 60, name="StepLadder")
P("hand_truck", (-22.5, 0, -6.5), 25, name="HandTruck")
# ===== tools department (north centre) -- chain ground zero
P("lost_found_desk", (0.5, 0, -10.0), 0, name="ToolCounter")
P("tripod", (0.5, 0, -6.9), 180, name="BrendaTripod")
P("phone_selfie", (0.5, 1.4, -7.0), 0, name="TripodPhone", opts={"grab": ""})
P("coin", (0.9, 1.12, -9.8), 0, name="Coin")
P("power_strip", (4.6, 0.0, -10.2), 0, name="PowerStrip")
P("plug_cord", (5.6, 0.0, -10.4), 0, name="PlugCord")
P("extension_cord_floor", (-3.0, 0, -7.5), 15, name="TripCord")
P("air_compressor", (7.6, 0, -10.6), 0, name="Compressor")
P("nailgun_rack", (9.6, 0, -12.0), 0, name="NailRack")
P("nailgun", (9.6, 1.38, -11.8), 90, name="NailGun")
P("paint_can_stack", (13.2, 0, -12.0), 0, name="PaintStack")
P("saw_table", (-4.0, 0, -12.5), 20, name="SawTable")
P("drill", (-4.2, 0.95, -12.9), 40, name="Drill1")
P("toolbox", (-6.3, 0, -11.5), 10, name="Toolbox1")
P("hammer", (-6.1, 0.24, -11.6), 30, name="Hammer1")
for i in range(6):
    P("shelving_unit", (-11.5 + i * 2.05, 0, -25.5), 0, name="ToolShelfN%d" % (i + 1))
for i in range(3):
    P("shelving_unit", (-3.5 + i * 2.05, 0, -19.8), 180, name="ToolShelfS%d" % (i + 1))
    P("shelving_unit", (-3.5 + i * 2.05, 0, -19.2), 0, name="ToolShelfT%d" % (i + 1))
# rolling ladder + rail on the east tools aisle (rolls south along x=15.0)
P("ladder_rolling", (15.2, 0, -12.0), 90, name="RollingLadder")
lv.region("rail")
lv.visual_box((14.9, 3.1, -14.5), (15.0, 3.2, -2.0), "SteelDark")
lv.visual_box((15.3, 0.0, -14.5), (15.4, 0.04, -2.0), "SteelDark")
for i in range(5):
    P("shelving_unit", (16.0, 0, -13.5 + i * 2.05), 90, name="RailShelf%d" % (i + 1))
P("fan_rack", (14.0, 0, -1.6), 0, name="FanRack")
P("ceiling_fan", (14.0, 6.4, -1.6), 0, name="DisplayFan")
P("sale_banner", (17.5, 4.6, -1.6), 0, name="SaleBanner")
lv.marker("BannerPostA", (14.1, 4.7, -1.6), 0)
lv.marker("BannerPostB", (20.9, 4.6, -1.6), 0)
P("tire_rack", (19.0, 0, -6.0), 90, name="TireRack")
P("tire", (19.0, 1.5, -6.0), 0, name="TireTop")
P("tire", (19.0, 0.35, -5.2), 0, name="TireLow")
P("tire", (24.5, 0, -6.6), 0, name="TireLoose")
P("pallet", (21.5, 0, -14), 0, name="PalletA")
P("lumber_bundle", (21.5, 0.15, -14), 90, name="LumberA")
P("lumber_bundle", (21.5, 0.35, -14.3), 90, name="LumberB")
P("pipe_bundle", (26.5, 0, -16), 0, name="PipesA")
P("flatbed_cart", (25.5, 0, -12.0), 40, name="FlatbedCart")
P("chain_hoist", (8.0, 5.0, -4.0), 0, name="ChainHoist")
# ===== garden centre -- slip + forklift zone
P("hose_reel", (25.6, 0, -1.8), 0, name="HoseReel")
P("sprinkler_display", (23.6, 0, 4.4), 0, name="Sprinklers")
P("wet_floor_sign", (21.4, 0, 8.6), 100, name="GardenWetSign")
P("forklift", (28.0, 0, 8.0), -90, name="Forklift")
P("forklift_handle", (27.0, 1.05, 7.0), 0, name="LowerHandle")
P("flamingo_pallet", (28.0, 3.3, 8.0), 90, name="FlamingoPallet")
P("flamingo_red", (26.6, 0.0, 12.0), 30, name="RedFlamingo", opts={"grab": "medium"})
for i in range(6):
    P("flamingo", (17.5 + (i % 3) * 0.9, 0, 15.5 + (i // 3) * 1.0), rnd.randint(0, 359), name="Flamingo%d" % (i + 1), opts={"grab": "medium"})
P("flamingo", (19.8, 0, 12.4), 190, name="BrendaFlamingo", opts={"grab": "medium"})
P("garden_gnome", (16.6, 0, 11.0), 20, name="Gnome1")
P("garden_gnome", (17.2, 0, 11.5), 300, name="Gnome2")
P("lawn_mower", (18.5, 0, 5.5), 260, name="Mower")
P("wheelbarrow", (16.5, 0, 0.5), 110, name="Wheelbarrow1")
P("fertilizer_bag", (29.5, 0.0, 15.0), 30, name="Fert1")
P("fertilizer_bag", (29.5, 0.13, 15.0), 70, name="Fert2")
P("propane_cage", (30.5, 0, 0.0), -90, name="PropaneCage")
P("propane_cylinder", (30.2, 0, 0.0), 0, name="Propane1")
P("propane_cylinder", (30.2, 0, 0.5), 0, name="Propane2")
P("corn_dog_cart", (20.0, 0, 2.4), 250, name="CornDogCart")
P("sale_banner", (23.0, 3.8, 17.2), 180, name="GardenBanner")
P("shelving_unit", (31.5, 0, 12.0), 90, name="GardenShelf1")
P("shelving_unit", (31.5, 0, 14.05), 90, name="GardenShelf2")
# ===== extra dressing
P("fire_extinguisher", (-31.6, 0, 8.0), 90, name="Extinguisher1")
P("fire_extinguisher", (-13.0, 0, 24.5), 0, name="Extinguisher2")
P("trash_bin", (12.6, 0, 22.5), 0, name="Trash1")
P("cable_spool", (-8.0, 0, 8.0), 20, name="Spool1")
P("crate", (-6.0, 0, 8.0), 20, name="Crate1")
P("crate", (-6.0, 0.6, 8.0), 60, name="Crate2")
P("shoe", (13.2, 0.0, -13.6), 70, name="LostShoe", opts={"grab": "light"})

# ===== markers
lv.marker("PlayerStart", (0, 0.05, 60), 0)
lv.marker("PicklesStart", (1.5, 0.05, 61), 0)
lv.marker("StoreDoor", (0, 0.05, 27.5), 0)
lv.marker("BrendaIntro", (0, 0.05, 21.5), 180)
lv.marker("BrendaPaint", (-23.4, 0.05, 4.0), 270)
lv.marker("BrendaTools", (0.5, 0.05, -8.2), 0)
lv.marker("BrendaWalkA", (9.0, 0.05, -4.5), 0)
lv.marker("BrendaWalkB", (16.5, 0.05, -1.0), 0)
lv.marker("BrendaSlip", (22.6, 0.05, 6.0), 0)
lv.marker("BrendaGarden", (26.0, 0.05, 6.4), 90)
lv.marker("BrendaFinal", (26.6, 0.05, 9.4), 180)
lv.marker("DaleDoor", (0, 0.05, 24.4), 180)
lv.marker("DaleInside", (-1.5, 0.05, 15.0), 180)
lv.marker("CoinStart", (0.9, 1.13, -9.8), 0)
lv.marker("CoinEnd", (4.0, 0.03, -10.0), 0)
lv.marker("StripSpark", (4.6, 0.10, -10.2), 0)
lv.marker("CompressorTop", (7.6, 1.05, -10.6), 0)
lv.marker("NailMuzzle", (10.2, 1.3, -11.8), 0)
lv.marker("StackTop", (13.2, 0.9, -12.0), 0)
lv.marker("LadderStart", (15.2, 0, -12.0), 90)
lv.marker("LadderEnd", (15.2, 0, -3.6), 90)
lv.marker("FanFallTo", (14.0, 0.05, -2.8), 0)
lv.marker("TireStart", (19.0, 1.5, -6.0), 0)
lv.marker("TireEnd", (25.6, 0.34, 0.2), 0)
lv.marker("HoseWhip", (25.0, 0.5, 1.2), 0)
lv.marker("SprinklerBurst", (23.6, 0.7, 4.4), 0)
lv.marker("ForkliftPallet", (28.0, 3.3, 8.0), 90)
lv.marker("PalletDrop", (26.2, 0.15, 8.6), 0)
lv.marker("TripodSpot", (0.5, 0.05, -6.9), 180)
lv.marker("EddieShoot", (-1.5, 0.05, -3.5), 0)
lv.marker("ExitLot", (0, 0.05, 44), 180)
lv.marker("CornDogSpot", (19.0, 0.05, 3.6), 250)
lv.marker("OilSpot", (21.6, 0.03, 4.6), 0)
lv.marker("BannerLow", (17.5, 1.2, -1.6), 0)
lv.marker("HandlePivot", (27.0, 1.05, 7.0), 0)
lv.marker("PaintStackSafe", (7.0, 0.05, -18.0), 0)
lv.export()
