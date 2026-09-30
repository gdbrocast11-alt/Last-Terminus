"""Terminus Station (chapters 1 and 7). blender -b --python tools/blender/gen_level_station.py

Godot coordinates. Concourse x[-24,24] z[-18,18] H=12; facade at z=+18; forecourt z>18;
north wall z=-18 with gates onto platform 4 (z<-18); gallery/mezzanine along the north wall at y=5.4.
Deco groups: "day1" (opening-day commuters/props) and "finale" (reopening ceremony).
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lv_lib import Level

lv = Level("station")
H = 12.0
GY = 5.4          # gallery floor height
rnd = random.Random(7)

# ================================================================ concourse shell
lv.region("floor")
lv.slab(-24, -18, 24, 18, 0.0, 0.4, "Terrazzo", surface="tile")
# inlaid dark strip guiding to the gates + border
lv.visual_box((-0.6, 0.0, -18), (0.6, 0.012, 18), "TerrazzoDark")
lv.visual_box((-24, 0.0, 17.2), (24, 0.012, 18), "TerrazzoDark")
for x in (-12, 12):
    lv.visual_box((x - 0.15, 0.0, -18), (x + 0.15, 0.012, 18), "TerrazzoDark")

lv.region("walls")
# facade (south) with glazing + doorway; wall centred on z=18.3
lv.wall(-24, 18.3, 24, 18.3, 0, H, 0.6, "WallWhite",
        openings=[(1.0, 21.0, 0.0, 7.5), (27.0, 47.0, 0.0, 7.5), (21.0, 27.0, 0.0, 3.6)])
for (x0, x1) in ((-23, -3), (3, 23)):
    lv.region("glass")
    lv.solid((x0, 0.0, 18.05), (x1, 7.5, 18.10), "Glass", col=True, surface="glass")
    lv.region("walls")
    for xx in [x0 + i * 4.0 for i in range(int((x1 - x0) / 4.0) + 1)]:
        lv.solid((xx - 0.06, 0.0, 18.0), (xx + 0.06, 7.5, 18.16), "SteelDark", col=False)
    lv.solid((x0, 3.7, 18.0), (x1, 3.78, 18.16), "SteelDark", col=False)
    lv.solid((x0, 7.5, 18.0), (x1, 7.6, 18.16), "SteelDark", col=False)
# entrance doorway header + canopy
lv.solid((-3, 3.6, 17.9), (3, 4.0, 18.6), "SteelBrushed", col=False)
lv.solid((-6, 7.4, 18.6), (6, 7.7, 25), "SteelDark", col=True)        # canopy
for cx in (-5.6, 5.6):
    lv.round_column(cx, 24.4, 0, 7.4, 0.14, "SteelBrushed")
# north wall with gate openings and a service door
lv.wall(-24, -18.3, 24, -18.3, 0, H, 0.6, "WallWhite", openings=[(30.0, 38.0, 0.0, 4.5), (2.0, 4.0, 0.0, 2.6)])
# side walls
lv.wall(-24.3, -18.6, -24.3, 18.6, 0, H, 0.6, "WallCream")
lv.wall(24.3, -18.6, 24.3, 18.6, 0, H, 0.6, "WallCream")
# green accent band
lv.visual_box((-24.0, 0.0, -18.0), (-23.98, 1.0, 18.0), "PaintGreen")
lv.visual_box((23.98, 0.0, -18.0), (24.0, 1.0, 18.0), "PaintGreen")

lv.region("ceiling")
lv.ceiling(-24, -18, 24, 18, H, 0.5, "CeilingTile")
for i in range(7):
    z = -16 + i * 5.4
    lv.visual_box((-24, H - 0.7, z - 0.18), (24, H, z + 0.18), "SteelDark")           # trusses
for i in range(-3, 4):
    lv.visual_box((i * 7 - 0.2, H - 0.7, -18), (i * 7 + 0.2, H, 18), "SteelDark")
for i in range(4):
    lv.visual_box((-16 + i * 10.6, H - 0.02, -6), (-11 + i * 10.6, H, 8), "LightTube")   # skylight panels (emissive)

# structural columns (two rows)
lv.region("columns")
for x in (-18, -6, 6, 18):
    for z in (-6.0, 10.0):
        lv.round_column(x, z, 0, H, 0.45, "Concrete")
        lv.cyl(x, 0, z, 0.6, 0.15, "TerrazzoDark")

# ================================================================ gallery / mezzanine
lv.region("gallery")
lv.slab(-24, -18, 24, -11, GY, 0.5, "Concrete", surface="concrete")
lv.solid((-24, GY, -11.1), (24, GY + 1.1, -11.0), "Glass", col=True, surface="glass")         # balustrade glass
lv.solid((-24, GY + 1.1, -11.15), (24, GY + 1.2, -10.95), "SteelBrushed", col=False)
for x in [-23 + i * 2.0 for i in range(24)]:
    lv.solid((x - 0.03, GY, -11.15), (x + 0.03, GY + 1.15, -10.95), "SteelBrushed", col=False)
# columns supporting gallery
for x in (-20, -8, 8, 20):
    lv.round_column(x, -11.6, 0, GY, 0.3, "Concrete")
# east stairs (up to gallery) along the east wall, running north
lv.stairs(20.4, -1.0, 0.0, 23.6, -10.8, GY, 30, "Concrete", axis="z", surface="concrete")
lv.solid((20.3, 0.0, -10.8), (20.4, GY + 1.0, -1.0), "Glass", col=True, surface="glass")
# gallery back wall banner strip
lv.visual_box((-24, GY + 1.5, -17.95), (24, GY + 3.5, -17.9), "WallSage")
# escalator well: opening is implicit (slab starts z=-11); escalator ramp collider (visual is the escalator prop)
lv.ramp(-16.9, -0.5, -15.1, -11.0, 0.0, GY, "Concrete", axis="z", visible=False)
lv.solid((-17.1, 0.0, -11.0), (-14.9, 0.05, -0.5), "TerrazzoDark", col=False)
# gates / platform side under the gallery
lv.region("platform")
lv.slab(-24, -46, 24, -18.6, 0.0, 0.4, "Concrete", surface="concrete")
lv.slab(-24, -33.8, 24, -26.0, -1.3, 0.4, "ConcreteDark", surface="gravel")        # track pit
lv.slab(-24, -46, 24, -33.8, 0.0, 0.4, "Concrete", surface="concrete")             # far platform
lv.solid((-24, -1.3, -26.2), (24, 0.0, -26.0), "ConcreteDark", col=True)
lv.solid((-24, -1.3, -33.9), (24, 0.0, -33.7), "ConcreteDark", col=True)
lv.solid((-24, 0.0, -26.4), (24, 0.9, -26.2), "Hazard", col=False)                # tactile edge
for z in (-29.0, -31.0):
    lv.visual_box((-24, -1.15, z - 0.07), (24, -1.0, z + 0.07), "Rust")            # rails
lv.wall(-24.3, -46.3, -24.3, -18.6, 0, 9, 0.6, "WallCream")
lv.wall(24.3, -46.3, 24.3, -18.6, 0, 9, 0.6, "WallCream")
lv.wall(-24, -46.3, 24, -46.3, 0, 9, 0.6, "ConcreteRough")
lv.ceiling(-24, -46, 24, -18.6, 9, 0.5, "CeilingTile")
for x in (-18, -6, 6, 18):
    lv.round_column(x, -24.0, 0, 9, 0.3, "Concrete")
# invisible barrier keeps the player off the tracks (train car fills the gap in-game)
lv.solid((-24, 0.0, -26.0), (24, 1.2, -25.9), "Glass", col=True, visible=False, surface="glass")

# ================================================================ forecourt (exterior)
lv.region("forecourt")
lv.slab(-46, 18.6, 46, 46, 0.0, 0.5, "ConcreteRough", surface="concrete")
lv.slab(-46, 46, 46, 80, -0.15, 0.5, "Asphalt", surface="concrete")
lv.visual_box((-46, -0.15, 45.9), (46, 0.02, 46.1), "PaintYellow")
for x in range(-44, 46, 6):
    lv.visual_box((x, -0.14, 62.9), (x + 3, -0.12, 63.1), "PaintWhite")            # lane dash
lv.solid((-46, 0.0, 44.4), (46, 0.15, 46.0), "Concrete", col=True)                 # curb
# planter walls + bollards
for x in (-14, -9, 9, 14):
    lv.solid((x - 1.3, 0.0, 28), (x + 1.3, 0.7, 29.2), "ConcreteRough", col=True)
for x in [-30 + i * 2.5 for i in range(25)]:
    if abs(x) > 4:
        lv.round_column(x, 40, 0, 0.9, 0.12, "SteelBrushed")
# side walls / distant city backdrop
lv.solid((-46, 0.0, 18.6), (-45.6, 8.0, 46), "WallGrey", col=True)
lv.solid((45.6, 0.0, 18.6), (46, 8.0, 46), "WallGrey", col=True)
lv.solid((-46, 0.0, 79.6), (46, 8.0, 80), "WallGrey", col=True)
for i in range(40):
    x = -60 + i * 3.1 + rnd.uniform(-0.6, 0.6)
    w, h = rnd.uniform(3.5, 7.0), rnd.uniform(14, 40)
    lv.visual_box((x - w / 2, -1, 88), (x + w / 2, h, 88 + rnd.uniform(8, 14)), rnd.choice(["ConcreteDark", "Brick", "WallGrey", "Concrete"]))
    for r in range(int(h // 3)):
        if rnd.random() < 0.4:
            lv.visual_box((x - w / 2 + 0.5, r * 3 + 1.4, 87.9), (x + w / 2 - 0.5, r * 3 + 2.6, 88.0), "GlassTint")

# ================================================================ lighting
lv.light("dir", (0, 30, 60), (1.0, 0.96, 0.88), 1.0, 120.0, True, dir_deg=(-38, 8, 0), name="Sun")
for (x, z) in [(-16, -4), (0, -4), (16, -4), (-16, 8), (0, 8), (16, 8), (-8, 14), (8, 14)]:
    lv.light("omni", (x, 10.6, z), (1.0, 0.97, 0.9), 1.6, 15.0, False, fog=0.3)
lv.light("omni", (-12, 10.0, 0), (1.0, 0.97, 0.9), 0.8, 20.0, True, name="HallShadowA")
lv.light("omni", (12, 10.0, 0), (1.0, 0.97, 0.9), 0.8, 20.0, True, name="HallShadowB")
for x in (-16, -4, 8, 20):
    lv.light("omni", (x, 4.6, -14.5), (1.0, 0.95, 0.85), 1.1, 9.0, False)
for x in (-18, -6, 6, 18):
    lv.light("omni", (x, 7.5, -22), (0.9, 0.97, 1.0), 1.4, 12.0, False)
    lv.light("omni", (x, 7.5, -38), (0.9, 0.97, 1.0), 1.2, 12.0, False)
lv.light("omni", (0, 3.0, 22), (1.0, 0.95, 0.85), 1.4, 10.0, False, name="CanopyLight")
lv.light("omni", (17, 2.6, 6), (1.0, 0.75, 0.55), 1.1, 6.0, False, name="JuiceLight")
lv.zone((-24, 0, -18), (24, H, 18), "RevLarge", 0.55, "HallReverb")
lv.zone((-24, 0, -46), (24, 9, -18.5), "RevLarge", 0.5, "PlatformReverb")
lv.zone((-46, -0.5, 18.7), (46, 30, 80), "RevOutdoor", 0.25, "OutsideReverb")
lv.probe((-24, 0, -18), (0, H, 18))
lv.probe((0, 0, -18), (24, H, 18))
lv.probe((-46, 0, 18.6), (46, 20, 60), interior=False)
lv.occluder((-24.5, 0, -18.6), (-24.0, H, 18.6))
lv.occluder((24.0, 0, -18.6), (24.5, H, 18.6))
lv.occluder((-24, 0, -18.6), (24, H, -18.0))
lv.env = {"kind": "exterior_day", "sky_top": [0.28, 0.5, 0.85], "sky_horizon": [0.78, 0.86, 0.95], "ambient_energy": 0.5,
          "fog": 0.004, "fog_color": [0.75, 0.82, 0.9], "exposure": 0.9, "sdfgi": True, "vfog": True, "grade": "", "dof": True}

# ================================================================ props
P = lv.place
# -- signage
P("sign_slogan", (0, 8.0, 17.55), 0, name="SloganSign")
P("sign_terminus_hall", (0, 8.2, 18.75), 180, name="FacadeSign")
P("departures_board", (-23.55, 8.0, -2.0), -90, name="DeparturesBoard")
P("departures_board", (23.55, 8.0, 4.0), 90, name="ArrivalsBoard")
P("sign_platform4", (10, 4.2, -17.5), 0, name="Platform4Sign")
P("station_clock", (-23.6, 5.5, 10.0), -90, name="StationClock")
P("sign_exit", (0, 3.4, 17.6), 0, name="ExitSign")
P("sign_exit", (-23.5, 3.0, -16), -90, name="ExitSign2")
# -- skylink rail + pod
lv.region("rail")
lv.solid((-24, 8.9, -16.4), (24, 9.1, -16.0), "SteelDark", col=False)
for x in (-22, -10, 2, 14, 22):
    lv.solid((x - 0.1, 9.1, -16.3), (x + 0.1, H, -16.1), "SteelDark", col=False)
P("skylink_pod", (14, 7.4, -15.9), 90, name="SkyLinkPod")
# -- sculpture (hangs from the ceiling)
P("sculpture_momentum", (0, 11.6, 2.0), 0, name="Sculpture")
# -- escalator (visual; conveyor script drives the steps)
P("escalator_frame", (-16.0, 0.0, -0.5), 0, name="Escalator", opts={"nocol": True})
# -- gates / barrier
for i in range(4):
    P("fare_gate", (7.0 + i * 2.0, 0, -16.0), 180 if False else 0, name="Gate%d" % (i + 1))
P("barrier_fence", (10.0, 0, -13.2), 0, name="TempBarrier", group="day1")
P("barrier_fence", (12.0, 0, -13.2), 0, name="TempBarrier2", group="day1")
P("barrier_fence", (8.0, 0, -13.2), 0, name="TempBarrier3", group="day1")
# -- ticket area (west)
for i in range(3):
    P("ticket_machine", (-23.5, 0, 6.0 + i * 1.6), -90, name="TicketMachine%d" % (i + 1) if i else "TicketMachine")
P("info_kiosk", (-8.0, 0, 12.0), 0, name="InfoKiosk")
P("lost_found_desk", (-19.0, 0, -8.0), 90, name="CoatCheck", group="finale")
P("vending_machine", (-23.5, 0, -6.0), -90, name="Vending1")
P("vending_machine", (-23.5, 0, -7.2), -90, name="Vending2")
P("newsstand", (0.0, 0, -9.5), 180, name="Newsstand")
P("trash_bin", (-21.5, 0, 2.6), 0, name="Trash1")
P("trash_bin", (6.2, 0, 4.6), 0, name="Trash2")
P("pigeon_statue", (-2.6, 0, 13.6), 0, name="PigeonStatue")
P("pigeon_statue", (2.6, 0, 13.6), 200, name="PigeonStatue2")
for i, (x, z, y) in enumerate(((-13, 15.3, 0), (-4.5, 15.3, 0), (4.5, 15.3, 0), (13, 15.3, 0))):
    P("planter_box", (x, 0, z), 0, name="Planter%d" % (i + 1))
    P("plant_ficus", (x, 1.28, z), rnd.randint(0, 360), name="Ficus%d" % (i + 1), opts={"grab": ""})
# -- benches
P("bench", (-8.0, 0, 9.0), 0, name="BenchKid")
P("bench", (6.0, 0, 7.5), 0, name="SitBench")
P("bench", (-4.0, 0, -6.0), 180, name="Bench3")
P("bench", (4.0, 0, -6.0), 180, name="Bench4")
P("bench", (22.6, 0, 9.0), 90, name="Bench5")
# -- cafe (Juice Junction, east)
P("smoothie_counter", (21.3, 0, 6.0), 90, name="JuiceCounter")
P("cafe_table", (16.0, 0, 3.6), 0, name="CafeTable1")
P("cafe_table", (16.0, 0, 8.6), 0, name="CafeTable2")
P("cafe_table", (13.0, 0, 6.0), 0, name="CafeTable3")
P("bar_stool", (16.9, 0, 3.6), 0, name="Stool1")
P("bar_stool", (15.1, 0, 3.6), 0, name="Stool2")
P("bar_stool", (16.9, 0, 8.6), 0, name="Stool3")
P("bar_stool", (15.1, 0, 8.6), 0, name="Stool4")
P("smoothie_cup", (13.0, 0.78, 6.0), 0, name="TiffanyCup")
P("smoothie_cup", (21.0, 1.12, 6.5), 0, name="CounterCup")
P("coffee_machine", (21.1, 1.12, 8.0), 90, name="CoffeeMachine")
P("coffee_cup", (16.0, 0.78, 8.6), 0, name="CoffeeCup1")
# -- hazards shared by both visits
P("baggage_cart", (5.0, 0, 6.5), 90, name="BaggageCart")
P("scrub_robot", (13.0, 0, 12.0), 0, name="ScrubRobot")
P("wet_floor_sign", (-9.0, 0, 3.0), 30, name="WetSign")
P("red_handle", (-22.0, 1.4, 8.6), -90, name="AlarmHandle")
P("electrical_panel", (23.6, 0, -6.0), 90, name="ElecPanel")
P("suitcase_red", (-3.0, 0, 5.0), 40, name="Suitcase1")
P("suitcase_blue", (-2.4, 0, 5.3), 100, name="Suitcase2")
P("suitcase_green", (10.0, 0, 11.0), 70, name="Suitcase3", group="day1")
P("backpack", (-5.8, 0, 9.4), 20, name="Backpack1")
P("tennis_ball", (-8.2, 0.03, 8.7), 0, name="KidBall")
P("stanchion", (-2.0, 0, 16.2), 0, name="Stanchion1")
P("stanchion", (2.0, 0, 16.2), 0, name="Stanchion2")
P("fire_extinguisher", (-23.6, 0, 0.0), 0, name="Extinguisher1")
P("fire_extinguisher", (23.6, 0, -10.0), 0, name="Extinguisher2")
P("ladder_maint", (-20.0, 0, -13.0), 0, name="MaintLadder", group="day1")
# -- day1 only
P("scaffold_section", (-9.0, 0, 15.0), 0, name="Scaffold1", group="day1")
P("scaffold_section", (-5.9, 0, 15.0), 0, name="Scaffold2", group="day1")
P("caution_tape_post", (-10.8, 0, 13.6), 0, name="TapePost1", group="day1")
P("caution_tape_post", (-4.0, 0, 13.6), 0, name="TapePost2", group="day1")
# -- finale only
P("scaffold_section", (-18.0, GY, -11.6), 0, name="BridgeScaffold1", group="finale")
P("scaffold_section", (-14.9, GY, -11.6), 0, name="BridgeScaffold2", group="finale")
P("scaffold_section", (9.0, GY, -11.6), 0, name="BridgeScaffold3", group="finale")
P("bridge_segment", (0, GY - 0.02, -14.3), 0, name="BridgeSegment", group="finale", opts={"nocol": True})
P("ceremony_banner", (0, 8.6, 16.9), 0, name="CeremonyBanner", group="finale")
P("podium", (0, 0, 9.5), 180, name="Podium", group="finale")
P("ribbon_cut", (0, 1.0, 6.4), 0, name="Ribbon", group="finale")
P("piano_grand", (3.6, 7.6, 3.4), 20, name="PianoHoist", group="finale", opts={"nocol": True})
P("chain_hoist", (3.6, 11.6, 3.4), 0, name="PianoCable", group="finale")
P("bottle_glass", (14.0, 0, 9.5), 0, name="FinaleBottle", group="finale")
P("bench", (6.0, 0, 7.5), 0, name="FinaleBenchProp", group="finale") if False else None
P("wet_floor_sign", (9.0, 0, 8.0), 60, name="WetSign2", group="finale")
P("baggage_cart", (14.0, 0, -3.0), 30, name="BaggageCart2", group="finale")
P("crate", (-6.8, 0, -1.0), 20, name="FinaleCrate", group="finale")
P("cafe_chair", (-10, 0, 0), 0, name="Chair1", group="finale")
P("ladder_maint", (-20.5, GY, -12.6), 0, name="ScaffoldWrench", group="finale", opts={"hazard": 0})
P("train_car", (0, -1.3 + 0.35, -29.9), 90, name="Train", opts={"nocol": True})
# -- exterior
P("sedan", (-30, 0, 55), 90, name="Sedan1")
P("sedan", (28, 0, 71), -90, name="Sedan2")
P("bus_stop_shelter", (32, 0, 41.5), 0, name="BusStop")
P("street_lamp", (-22, 0, 42.5), 0, name="Lamp1")
P("street_lamp", (22, 0, 42.5), 180, name="Lamp2")
P("tree_street", (-32, 0, 30), 0, name="Tree1")
P("tree_street", (34, 0, 30), 90, name="Tree2")
P("hydrant", (-26, 0, 43.4), 0, name="Hydrant")
P("bench", (-20, 0, 32), 0, name="ForecourtBench")
P("bench", (20, 0, 32), 0, name="ForecourtBench2")
P("trash_can_street", (-18.5, 0, 32.3), 0, name="StreetBin")

# ================================================================ markers
lv.marker("PlayerStart", (0, 0.05, 34), 0)
lv.marker("PicklesStart", (1.6, 0.05, 35), 0)
lv.marker("EnterHall", (0, 0.05, 15), 0)
lv.marker("KidSpot", (-7.4, 0.05, 10.6), 200)
lv.marker("BallSpot", (-8.0, 0.05, 8.7), 0)
lv.marker("BrendaSpot", (-2.6, 0.05, 3.0), 60)
lv.marker("DaleSpot", (-13.0, 0.05, 1.0), 180)
lv.marker("TiffanySpot", (14.6, 0.05, 6.0), 90)
lv.marker("GusSpot", (20.0, 0.05, -1.6), 270)
lv.marker("MarcoSpot", (-19.5, 0.05, 11.0), 20)
lv.marker("LuisSpot", (-18.3, 0.05, 11.8), 200)
lv.marker("MillsSpot", (2.0, 0.05, 13.0), 0)
lv.marker("TicketSpot", (-22.0, 0.05, 7.0), 90)
lv.marker("BarrierSpot", (10.0, 0.05, -11.6), 180)
lv.marker("PremSpot", (8.0, 0.05, -8.0), 180)
lv.marker("BenchSit", (6.0, 0.05, 6.4), 0)
lv.marker("ScrubStart", (13.0, 0.05, 12.0), 0)
lv.marker("ScrubTarget", (12.6, 0.05, 6.8), 0)
lv.marker("ScrubSlide", (8.8, 0.05, 6.6), 60)
lv.marker("CupFloor", (13.7, 0.03, 6.9), 0)
lv.marker("CartStart", (5.0, 0.05, 6.5), 90)
lv.marker("CartMid", (-6.0, 0.05, 3.5), 90)
lv.marker("CartCrash", (-14.4, 0.05, 0.4), 90)
lv.marker("EscBase", (-16.0, 0.05, -0.5), 180)
lv.marker("EscTop", (-16.0, GY, -11.0), 0)
lv.marker("CupSpot", (13.0, 0.78, 6.0), 0)
lv.marker("SculptureFloor", (0.0, 0.05, 2.0), 0)
lv.marker("PodFall", (14.0, 0.05, -12.0), 0)
lv.marker("SculptureBelow", (0.0, 0.05, 2.0), 0)
lv.marker("WatchSpot", (0, 0.05, 40), 0)         # where the player watches the collapse from the forecourt
lv.marker("WatchPickles", (1.8, 0.05, 40.4), 0)
lv.marker("MillsOut", (-2.6, 0.05, 34.5), 0)
lv.marker("CrowdA", (-9, 0.05, 32.5), 0)
lv.marker("CrowdB", (-5, 0.05, 31), 0)
lv.marker("CrowdC", (6, 0.05, 32), 0)
lv.marker("CrowdD", (10, 0.05, 34), 0)
lv.marker("CrowdE", (-12, 0.05, 35), 0)
lv.marker("CrowdF", (13, 0.05, 36), 0)
lv.marker("ExitDoor", (0, 0.05, 20.5), 0)
lv.marker("DoorInside", (0, 0.05, 15.5), 0)
lv.marker("PlatformStep", (12.0, 0.05, -21), 0)
lv.marker("PileCenter", (3.0, 0.05, 5.0), 0)
lv.marker("FinaleStart", (0, 0.05, 30), 0)
lv.marker("FinaleBench", (6.0, 0.05, 6.4), 0)
lv.marker("FinaleMills", (-19.0, 0.05, -6.2), 90)
lv.marker("FinaleGus", (-7.0, 0.05, -3.2), 0)
lv.marker("FinaleDale", (-12.5, 0.05, 8.0), 90)
lv.marker("FinaleMarco", (-4.4, 0.05, 9.0), 60)
lv.marker("FinaleLuis", (-3.0, 0.05, 10.2), 240)
lv.marker("FinaleTiffany", (12.0, 0.05, 2.5), 90)
lv.marker("FinaleBrenda", (10.0, 0.05, 9.5), 180)
lv.marker("FinaleGraves", (4.0, 0.05, 14.0), 0)
lv.marker("FinaleDoor", (0, 0.05, 15.2), 0)
lv.export()
