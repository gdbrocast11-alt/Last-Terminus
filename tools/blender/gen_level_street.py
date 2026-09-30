"""Residential street for the epilogue (chapter 8). blender -b --python tools/blender/gen_level_street.py
Main street runs along +X from x=-100 to a dead end at x=+64 (the reconstructed Terminus sign).
North sidewalk z in [-8,-4], road z in [-4,4], south sidewalk z in [4,8]. Crosswalk at x=44.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lv_lib import Level

lv = Level("street")
rnd = random.Random(77)

lv.region("ground")
lv.slab(-110, -4, 66, 4, 0.0, 0.5, "Asphalt", surface="concrete")                     # road
lv.slab(-110, -9, 66, -4, 0.15, 0.6, "Sidewalk", surface="concrete")                  # north walk (raised curb 0.15)
lv.slab(-110, 4, 66, 9, 0.15, 0.6, "Sidewalk", surface="concrete")                    # south walk
lv.slab(-110, -30, 66, -9, 0.0, 0.6, "Grass", surface="grass")                        # north yards
lv.slab(-110, 9, 66, 30, 0.0, 0.6, "Grass", surface="grass")
lv.slab(60, -30, 80, 30, 0.0, 0.6, "Grass", surface="grass")                          # dead-end lawn
lv.slab(60, -4, 66, 4, 0.0, 0.5, "Asphalt", surface="concrete")
for x in range(-104, 62, 8):
    lv.visual_box((x, 0.0, -0.08), (x + 3.5, 0.012, 0.08), "PaintYellow")
# crosswalk stripes at x=44 (spanning the road in z)
for i in range(9):
    z = -3.6 + i * 0.9
    lv.visual_box((42.6, 0.0, z), (45.4, 0.013, z + 0.45), "PaintWhite")
# boundary walls
lv.solid((-110.6, 0, -30), (-110, 6, 30), "WallGrey", col=True, visible=False)
lv.solid((80, 0, -30), (80.6, 6, 30), "WallGrey", col=True, visible=False)
lv.solid((-110, 0, -30.6), (80, 6, -30), "WallGrey", col=True, visible=False)
lv.solid((-110, 0, 30), (80, 6, 30.6), "WallGrey", col=True, visible=False)
lv.solid((66, 0, -4), (66.6, 4, 4), "WallGrey", col=False, visible=False)
# hills / far city backdrop
lv.region("backdrop")
for i in range(46):
    x = -140 + i * 6.5 + rnd.uniform(-1.5, 1.5)
    h = rnd.uniform(8, 30)
    lv.visual_box((x - 3, -1, 60), (x + 3, h, 68), rnd.choice(["Brick", "WallGrey", "ConcreteDark", "WallCream"]))
    lv.visual_box((x - 3, -1, -68), (x + 3, h * 0.8, -60), rnd.choice(["Brick", "WallGrey", "ConcreteDark", "WallCream"]))

# lights: golden hour
lv.light("dir", (0, 30, 60), (1.0, 0.72, 0.45), 1.7, 220.0, True, dir_deg=(-14, 250, 0), name="Sun")
lv.light("omni", (44, 3.6, -7), (1.0, 0.8, 0.5), 0.5, 8.0, False, name="CrossGlow")
lv.zone((-110, -0.5, -30), (80, 40, 30), "RevOutdoor", 0.22, "StreetReverb")
lv.probe((-110, -1, -30), (80, 20, 30))
lv.env = {"kind": "exterior_sunset", "sky_top": [0.28, 0.4, 0.75], "sky_horizon": [1.0, 0.68, 0.42], "ambient_energy": 0.8, "fog": 0.004,
          "fog_color": [1.0, 0.75, 0.55], "exposure": 1.0, "sdfgi": True, "vfog": False, "grade": "sunset", "dof": True}

P = lv.place
# ---- Eddie's building (start) -- scaled house facade + door prop
P("house_facade", (-95, 0, -20), 180, name="AptBuilding", scale=[1.5, 1.4, 1.5])
# ---- houses, north side (front faces +Z => yaw 180)
xs_n = [-78, -66, -54, -42, -30, -18, -6, 6, 18, 30]
for i, x in enumerate(xs_n):
    P("house_facade", (x, 0, -20.5), 180, name="HouseN%d" % (i + 1))
    P("picket_fence", (x, 0, -10.5), 0, name="FenceN%d" % (i + 1))
    if i % 2 == 0:
        P("tree_street", (x + 4.5, 0, -12.5), rnd.randint(0, 359), name="TreeN%d" % (i + 1))
    P("mailbox", (x - 3, 0.15, -9.6), 0, name="MailboxN%d" % (i + 1))
# ---- houses, south side (front faces -Z => yaw 0)
for i, x in enumerate([-84, -72, -60, -48, -36, -24, -12, 0, 12, 24, 36]):
    P("house_facade", (x, 0, 20.5), 0, name="HouseS%d" % (i + 1))
    P("picket_fence", (x, 0, 10.5), 0, name="FenceS%d" % (i + 1))
    if i % 3 == 1:
        P("tree_street", (x - 4.5, 0, 12.5), rnd.randint(0, 359), name="TreeS%d" % (i + 1))
for i, x in enumerate(range(-100, 66, 20)):
    P("street_lamp", (x, 0.15, -8.6), 0, name="LampN%d" % i)
    P("street_lamp", (x + 10, 0.15, 8.6), 180, name="LampS%d" % i)
P("hydrant", (-62, 0.15, -8.5), 0, name="Hydrant1")
P("bench_street", (-46, 0.15, 8.4), 180, name="BenchS")
P("trash_can_street", (-10, 0.15, -4.6), 0, name="BinN")

# ---- hazards along the walk (Eddie's paranoia list) -- x positions increase along the walk
P("ladder_maint", (-52.5, 0.15, -14.2), 0, name="LadderHouse", rot=[-12, 180, 0], opts={"inspect": "ch8_ladder", "hazard": 1})
P("lawn_mower", (-40, 0, -14.0), 40, name="Mower", opts={"inspect": "ch8_mower", "hazard": 1})
P("pipe_truck", (-26, 0.0, -2.2), 90, name="PipeTruck")
P("ac_unit", (-6.2, 3.3, -16.2), 180, name="AcUnit", opts={"inspect": "ch8_ac"})
P("baseball", (3.0, 0.0, -10.5), 0, name="Baseball", opts={"inspect": "ch8_kid"})
P("bicycle", (13, 0.15, -6.0), 90, name="Bicycle")
P("excavator_mini", (24, 0.0, -2.4), 90, name="Excavator")
P("bottle_glass", (34.6, 0.15, -4.4), 0, name="Bottle")
# ---- crosswalk + signal
P("traffic_signal", (42.2, 0.15, -6.6), 0, name="Signal", opts={"inspect": "ch8_signal"})
P("traffic_signal", (42.2, 0.15, 6.6), 180, name="SignalS")
P("cctv_pole", (46.6, 0.15, 6.8), 180, name="CctvPole")
P("bus_stop_shelter", (36, 0.15, 6.4), 180, name="BusStop")
P("sedan", (-70, 0, 6.6), 90, name="Sedan1", opts={"grab": ""})
P("sedan", (-14, 0, 6.6), 270, name="Sedan2")
P("sedan", (6, 0, 6.6), 90, name="Sedan3")
# ---- the reconstructed Terminus sign at the dead end (x=62)
P("terminus_sign_street", (62.0, 0, 0), 90, name="TerminusSign")
lv.marker("SignA", (62.0, 3.35, -2.5), 90)
lv.marker("SignWord", (62.0, 3.35, 0.2), 90)
lv.marker("SignB", (62.0, 3.35, 2.8), 90)
P("bench_street", (58, 0, -8), 0, name="MemorialBench")
P("tree_street", (70, 0, -14), 0, name="TreeEnd1")
P("tree_street", (70, 0, 14), 0, name="TreeEnd2")
P("bus", (-140, 0, 1.8), 90, name="Bus", opts={"nocol": True})

# ---- markers
lv.marker("PlayerStart", (-92.5, 0.2, -5.5), 270)          # outside the apartment doorway, facing +X after a turn
lv.marker("PicklesStart", (-92.0, 0.2, -6.5), 270)
lv.marker("WalkStart", (-90.5, 0.2, -6.0), 270)
lv.marker("Crosswalk", (44, 0.2, -4.8), 180)
lv.marker("CrossMid", (44, 0.05, 0.0), 180)
lv.marker("KidSpot", (2.4, 0.2, -10.2), 180)
lv.marker("CyclistA", (6.0, 0.16, -6.0), 90)
lv.marker("CyclistB", (30.0, 0.16, -6.0), 90)
lv.marker("BusStart", (-110, 0.0, 1.8), 90)
lv.marker("BusAxleFail", (30, 0.0, 1.8), 90)
lv.marker("BusEnd", (61.0, 0.0, 0.0), 90)
lv.marker("CctvCam", (46.6, 6.0, 7.0), 180)
lv.marker("SignHit", (61.6, 3.0, 0.0), 90)
lv.marker("HonkPoint", (10, 1.5, 1.8), 90)
lv.export()
