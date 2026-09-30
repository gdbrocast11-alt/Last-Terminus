"""Halloran Maintenance Yard (chapter 6, the Pickles chapter). blender -b --python tools/blender/gen_level_yard.py
Yard x[-60,60] z[-36,50]; quarry pit north (z<-36). Six stations around the central plaza (0,0,10);
exit gate south (0,0,47). Everything is authored in Godot coordinates.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lv_lib import Level

lv = Level("yard")
rnd = random.Random(53)

lv.region("ground")
lv.slab(-60, -36, 60, 50, 0.0, 1.0, "Dirt", surface="gravel")
lv.slab(-8, 30, 8, 80, 0.0, 1.0, "Asphalt", surface="concrete")             # access road through the gate
lv.slab(-6, -6, 6, 26, 0.01, 0.05, "ConcreteRough", surface="concrete")       # plaza pad
for cx, cz, r in ((-44, 12, 9), (44, -6, 8), (-10, 40, 7), (48, 40, 8)):
    lv.cyl(cx, 0.0, cz, r, 0.03, "Grass")
lv.slab(-60, 50, 60, 80, -0.1, 1.0, "Dirt", surface="gravel")
lv.solid((-60.6, -0.1, -36), (-60, 6, 80), "WallGrey", col=True, visible=False)
lv.solid((60, -0.1, -36), (60.6, 6, 80), "WallGrey", col=True, visible=False)
lv.solid((-60, -0.1, 80), (60, 6, 80.6), "WallGrey", col=True, visible=False)

# quarry
lv.region("quarry")
depth = 16.0
lv.slab(-60, -70, 60, -36, -depth, 1.0, "Gravel", surface="gravel", col=True)
for i, (zz, yy) in enumerate(((-36, 0), (-42, -5), (-49, -10), (-56, -14))):
    lv.solid((-60, yy - 5.0, zz - 6.0), (60, yy, zz), "ConcreteRough", col=True, surface="gravel")
lv.solid((-60, -depth, -70.6), (60, 30, -70), "ConcreteRough", col=True)
lv.solid((-60.6, -depth, -70), (-60, 30, -36), "ConcreteRough", col=True)
lv.solid((60, -depth, -70), (60.6, 30, -36), "ConcreteRough", col=True)
# invisible rim barrier so nobody walks off the edge
lv.solid((-60, 0, -36.6), (60, 3.0, -36.4), "Glass", col=True, visible=False, surface="concrete")
# far rock walls
for i in range(28):
    x = -64 + i * 4.6 + rnd.uniform(-1, 1)
    h = rnd.uniform(10, 26)
    lv.visual_box((x - 3, -depth, -80), (x + 3, h, -70), rnd.choice(["ConcreteRough", "Dirt", "ConcreteDark"]))

# perimeter (fence + containers) with the gate opening at x in [-5,5]
lv.region("perimeter")
lv.wall(-60, 49.5, -5, 49.5, 0, 3.0, 0.4, "Corrugated", surface="concrete")
lv.wall(5, 49.5, 60, 49.5, 0, 3.0, 0.4, "Corrugated", surface="concrete")
lv.solid((-5.3, 0, 49.2), (-4.7, 3.4, 49.8), "PaintYellow")
lv.solid((4.7, 0, 49.2), (5.3, 3.4, 49.8), "PaintYellow")
lv.visual_box((-5, 3.2, 49.3), (5, 3.5, 49.7), "PaintYellow")
lv.text("HALLORAN MAINT. YARD", 0.5, (0, 3.9, 49.75), "SignYellow", rot=(90, 0, 0), depth=0.04)

# lighting: overcast afternoon
lv.light("dir", (0, 30, 60), (0.9, 0.92, 1.0), 1.15, 200.0, True, dir_deg=(-52, 35, 0), name="Sun")
lv.light("omni", (0, 3.0, 9.0), (1.0, 0.95, 0.85), 0.5, 10.0, False, name="ApologyGlow")
lv.zone((-60, -0.5, -36), (60, 40, 80), "RevOutdoor", 0.3, "YardReverb")
lv.probe((-60, -2, -36), (60, 30, 80), interior=False)
lv.env = {"kind": "exterior_overcast", "sky_top": [0.42, 0.48, 0.58], "sky_horizon": [0.78, 0.8, 0.82], "ambient_energy": 0.9, "fog": 0.006,
          "fog_color": [0.7, 0.72, 0.75], "exposure": 1.0, "sdfgi": True, "vfog": False, "grade": "bleak", "dof": True}

P = lv.place
# ---- central plaza
P("stump_seat", (-4.0, 0, 13.0), 0, name="Stump")
P("hazard_sign", (0, 0, 22), 180, name="DangerSign")
P("chain_fence", (-14, 0, 47), 0, name="Fence1")
P("chain_fence", (14, 0, 47), 0, name="Fence2")
P("sandwich_wrapper", (2.0, 0.01, 15.0), 30, name="Wrapper1")
P("lamp_post", (-9, 0, 26), 0, name="Lamp1")
P("lamp_post", (9, 0, 26), 180, name="Lamp2")

# ---- Station A: crane + beam (west)
P("crane_gantry", (-30, 0, -8), 0, name="GantryCrane")
P("steel_beam", (-30, 4.1, -8), 90, name="Beam", opts={"nocol": True})
P("yard_lever", (-24, 0, -2), 0, name="LeverBeam")
P("hay_bale", (-30, 0, -11), 0, name="HayA")
P("hay_bale", (-31.5, 0, -11), 0, name="HayA2")
P("sandwich_wrapper", (-33, 0.01, -3), 60, name="WrapperA")
P("tire_stack", (-27, 0, -12), 0, name="TiresA")

# ---- Station B: truck + slope (east)
lv.region("slope")
lv.ramp(28.0, -24.0, 32.0, -6.0, 3.2, 0.0, "ConcreteRough", axis="z", surface="concrete", width_axis_thick=0.5)
lv.solid((26.0, 0.0, -24.5), (34.0, 3.0, -24.0), "ConcreteRough", col=True)        # back stop / launch pad
lv.slab(26, -30.5, 34, -24, 3.2, 0.5, "ConcreteRough", surface="concrete")
lv.solid((25.7, 0.0, -30.5), (26.0, 3.7, -6.0), "ConcreteRough", col=True)
lv.solid((34.0, 0.0, -30.5), (34.3, 3.7, -6.0), "ConcreteRough", col=True)
P("yard_truck", (30, 3.2, -26.5), 180, name="YardTruck")
P("yard_lever", (24.0, 0, -15.0), 90, name="LeverTruck")
P("hay_bale", (30, 0, 4.6), 0, name="HayB")
P("hay_bale", (31.5, 0, 4.6), 0, name="HayB2")
P("jersey_barrier", (26.0, 0, 4.0), 90, name="JerseyB1")
P("jersey_barrier", (34.0, 0, 4.0), 90, name="JerseyB2")
P("oil_drum", (36.0, 0, -2.0), 0, name="DrumB")

# ---- Station C: scaffold drop (north)
P("scaffold_tower", (0, 0, -22), 0, name="ScaffoldDrop")
P("mattress", (-3.0, 0.0, -18.0), 0, name="Mattress")
P("crate", (0, 5.6, -22), 0, name="DropCrate")
P("yard_lever", (5.0, 0, -18), -90, name="LeverDrop")
P("scaffold_plank", (2.0, 0, -26), 0, name="PlankC")
P("cable_spool", (-8.0, 0, -24), 0, name="SpoolC")
P("gravel_pile", (10.0, 0, -28), 0, name="GravelC")

# ---- Station D: barrels + fuse (south-west)
for i, (x, z) in enumerate(((-22, 22), (-20.8, 22.2), (-22.6, 23.4), (-21.2, 23.6), (-23.8, 22.4))):
    P("barrel_red", (x, 0, z), i * 40, name="Barrel%d" % (i + 1))
P("propane_cylinder", (-21.6, 0, 20.9), 0, name="PropaneD1")
P("propane_cylinder", (-22.4, 0, 20.9), 0, name="PropaneD2")
P("fuse_box", (-14.0, 0, 27.0), 90, name="FuseBox")
P("airbag_safet", (-36, 0, 28), 0, name="Airbag")
P("airbag_inflated", (-36, 0, 28), 0, name="AirbagInflated")
P("hazard_sign", (-18, 0, 21), 90, name="DangerSignD")

# ---- Station E: vending machines (south-east)
P("vending_machine_phys", (20.0, 0, 22.0), 180, name="VendA")
P("vending_machine_phys", (20.0, 0, 25.0), 0, name="VendB")
P("yard_lever", (16.0, 0, 20.0), 0, name="LeverVend")
P("vending_machine_phys", (28.0, 0, 30.0), 90, name="VendSpare")
P("mattress", (22.0, 0, 27.6), 0, name="MattressE")
P("porta_potty", (12.0, 0, 34.0), 200, name="Potty")

# ---- Station F: wrecking ball hung from a second gantry (swings along z through the mark)
P("crane_gantry", (40, 0, 30), 0, name="WreckerGantry")
P("wrecking_ball", (40, 7.2, 30), 0, name="WreckingBall", opts={"nocol": True}, scale=[1.15, 1.15, 1.15])
P("yard_lever", (44, 0, 24), 0, name="LeverBall")
P("hay_bale", (40, 0, 38), 0, name="HayF")
P("hay_bale", (41.5, 0, 38), 0, name="HayF2")
P("dumpster", (46, 0, 12), 160, name="DumpsterF")

# ---- decoration: containers, rails, rocks, generators, debris
for x, z, yw in ((-52, -12, 0), (-52, 4, 0), (-52, 20, 0), (52, 30, 0), (52, 14, 0), (-46, 40, 90), (46, 44, 90), (0, -33, 90)):
    P("shipping_container", (x, 0, z), yw, name="Container_%d_%d" % (x, z))
P("shipping_container", (-52, 2.6, 4), 0, name="ContainerStack1")
P("rail_segment", (-12, 0, 36), 0, name="RailA")
P("rail_segment", (-12, 0, 40), 0, name="RailB")
P("rail_cart", (-12, 0.15, 41.4), 0, name="RailCart")
P("generator", (-4, 0, 38), 0, name="Generator")
P("quarry_rock", (-40, 0, -30), 20, name="Rock1")
P("quarry_rock", (44, 0, -32), 200, name="Rock2")
P("gravel_pile", (-48, 0, -22), 0, name="GravelA")
P("gravel_pile", (50, 0, -20), 0, name="GravelB")
P("tire_stack", (-8, 0, 44), 0, name="TireStackC")
P("tank_barrel_blue", (8, 0, 44), 0, name="BlueBarrel")
P("oil_drum", (9, 0, 44.6), 0, name="OilDrum")
P("jersey_barrier", (-6, 0, 30), 90, name="GateBarrierL")
P("jersey_barrier", (6, 0, 30), 90, name="GateBarrierR")
P("lamp_post", (-6, 0, 47), 0, name="GateLampL")
P("lamp_post", (6, 0, 47), 180, name="GateLampR")
P("dumpster", (-40, 0, 44), 20, name="DumpsterA")
P("porta_potty", (-30, 0, 38), 0, name="PottyB")
P("bench_street", (-9.5, 0, 44), 0, name="GateBench", opts={"grab": ""})

# ---- Graves' folding chair and sandwich table are added by script after the run
lv.marker("PlayerStart", (0, 0.05, 70), 0)
lv.marker("PicklesStart", (1.4, 0.05, 71), 0)
lv.marker("Gate", (0, 0.05, 48), 180)
lv.marker("Plaza", (0, 0.05, 10), 0)
lv.marker("PicklesPlaza", (1.6, 0.05, 11), 0)
lv.marker("SitSpot", (-4.0, 0.5, 13.0), 180)
lv.marker("GravesChair", (0, 0.05, 56), 0)
lv.marker("GravesAppear", (0, 0.05, 60), 180)
lv.marker("ExitRun", (0, 0.05, 54), 180)
lv.marker("A_Mark", (-30, 0.02, -8), 0)
lv.marker("A_Lever", (-24, 0.05, -2), 90)
lv.marker("B_Mark", (30, 0.02, 1.5), 0)
lv.marker("B_Lever", (24, 0.05, -15), 90)
lv.marker("B_TruckStart", (30, 3.2, -26.5), 180)
lv.marker("C_Mark", (0, 0.02, -22), 0)
lv.marker("C_Lever", (5, 0.05, -18), 90)
lv.marker("D_Mark", (-22, 0.02, 22.5), 0)
lv.marker("D_Lever", (-14, 0.05, 25.4), 0)
lv.marker("D_Land", (-36, 0.4, 28), 0)
lv.marker("E_Mark", (20, 0.02, 23.5), 0)
lv.marker("E_Lever", (16, 0.05, 20), 90)
lv.marker("F_Mark", (40, 0.02, 30), 0)
lv.marker("F_Lever", (44, 0.05, 24), 0)
lv.marker("BallPivot", (40, 7.2, 30), 0)
lv.marker("F_Land", (40, 0.4, 37.5), 0)
lv.marker("RunStart", (0, 0.05, 12), 0)
lv.marker("RunA", (0, 0.05, 16), 0)
lv.marker("RunB", (0, 0.05, 26), 0)
lv.marker("RunC", (0, 0.05, 33), 0)
lv.marker("RunD", (0, 0.05, 39), 0)
lv.marker("RunE", (0, 0.05, 44), 0)
lv.export()
