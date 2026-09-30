"""Eddie's apartment (used for Aftermath, the Graves revelation and the epilogue).
blender -b --python tools/blender/gen_level_apartment.py
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lv_lib import Level

lv = Level("apartment")
H = 2.7
T = 0.3
# ---- floors / ceiling
lv.slab(-5.3, -4.3, 1.8, 4.3, 0.0, 0.3, "Wood", surface="wood")
lv.slab(1.8, -4.3, 5.3, 0.5, 0.0, 0.3, "Wood", surface="wood")
lv.slab(1.8, 0.5, 5.3, 4.3, 0.0, 0.3, "TileWhite", surface="tile")
lv.ceiling(-5.3, -4.3, 5.3, 4.3, H, 0.3, "CeilingTile" if False else "WallWhite")
# ---- outer walls (interior faces at +-5 / +-4)
lv.wall(-5.3, -4.15, 5.3, -4.15, 0, H, T, "WallCream", openings=[(0.7, 2.7, 0.9, 2.2), (3.8, 5.6, 0.9, 2.2), (8.1, 9.5, 0.9, 2.2)])
lv.wall(-5.3, 4.15, 5.3, 4.15, 0, H, T, "WallCream", openings=[(0.7, 1.7, 0.0, 2.1), (8.4, 9.4, 0.9, 2.0)])
lv.wall(-5.15, -4.3, -5.15, 4.3, 0, H, T, "WallCream")
lv.wall(5.15, -4.3, 5.15, 4.3, 0, H, T, "WallSage")
# ---- partitions
lv.wall(1.8, -4.0, 1.8, 4.0, 0, H, 0.16, "WallSage", openings=[(1.4, 2.3, 0.0, 2.1), (6.0, 6.9, 0.0, 2.1)])
lv.wall(1.8, 0.5, 5.0, 0.5, 0, H, 0.16, "TileWhite")
# ---- window glass (blocks walking, transmits light)
for (x0, x1) in ((-4.6, -2.6), (-1.8, 0.2), (2.7, 4.3)):
    lv.solid((x0, 0.9, -4.06), (x1, 2.2, -4.04), "Glass", col=True)
    lv.solid((x0 - 0.05, 0.85, -4.1), (x1 + 0.05, 0.9, -3.98), "PaintWhite", col=False)
    lv.solid((x0 - 0.05, 2.2, -4.1), (x1 + 0.05, 2.25, -3.98), "PaintWhite", col=False)
    lv.solid(((x0 + x1) / 2 - 0.02, 0.9, -4.1), ((x0 + x1) / 2 + 0.02, 2.2, -3.98), "PaintWhite", col=False)
lv.solid((-4.5, 0.9, 3.98), (-3.6, 2.0, 4.02), "Glass", col=True) if False else None
lv.solid((3.2, 1.1, 3.98), (4.0, 1.8, 4.02), "GlassFrost", col=True)
# baseboards
for (a, b) in (((-5.0, -3.97), (1.8, -3.97)), ((-5.0, 3.97), (1.8, 3.97))):
    lv.solid((a[0], 0, a[1] - 0.015), (b[0], 0.1, b[1] + 0.015), "WoodDark", col=False)
lv.solid((-4.97, 0, -4.0), (-4.94, 0.1, 4.0), "WoodDark", col=False)
# ---- exterior city backdrop seen through the windows
rnd = random.Random(21)
for i in range(46):
    x = -34 + i * 1.5 + rnd.uniform(-0.3, 0.3)
    w = rnd.uniform(1.6, 3.0)
    h = rnd.uniform(6, 20)
    z = rnd.uniform(-26, -18)
    lv.visual_box((x - w / 2, -2, z - 2), (x + w / 2, h, z + 2), "ConcreteDark")
    for r in range(int(h // 1.4)):
        if rnd.random() < 0.35:
            wx = x + rnd.uniform(-w / 2 + 0.3, w / 2 - 0.3)
            lv.visual_box((wx - 0.25, r * 1.4 + 0.5, z + 2.0), (wx + 0.25, r * 1.4 + 1.0, z + 2.02), "LightWarm")
lv.slab(-40, -30, 40, -4.3, -1.5, 0.3, "Asphalt", col=False)      # street far below
# ---- lighting
lv.light("omni", (-1.5, 2.45, -0.5), (1.0, 0.82, 0.6), 1.3, 9.0, True, name="LivingLight")
lv.light("omni", (-1.0, 2.45, 2.6), (1.0, 0.9, 0.75), 0.8, 6.0, False, name="KitchenLight")
lv.light("omni", (3.4, 2.4, -1.9), (1.0, 0.8, 0.6), 0.7, 5.5, True, name="BedroomLight")
lv.light("omni", (3.5, 2.3, 2.5), (0.95, 0.98, 1.0), 0.7, 4.5, False, name="BathLight")
lv.light("spot", (-3.6, 2.0, -6.5), (0.55, 0.65, 1.0), 2.2, 12.0, True, spot_angle=50, dir_deg=(-8, 0, 0), name="Moonlight")
lv.light("spot", (-0.8, 2.0, -6.5), (0.55, 0.65, 1.0), 2.0, 12.0, False, spot_angle=50, dir_deg=(-8, 0, 0), name="Moonlight2")
lv.light("omni", (-4.6, 1.1, 2.0), (1.0, 0.9, 0.7), 0.5, 3.0, False, name="DeskGlow")
lv.zone((-5.2, 0, -4.2), (5.2, H, 4.2), "RevSmall", 0.35, "ApartmentReverb")
lv.probe((-5.2, 0, -4.2), (1.8, H, 4.2))
lv.probe((1.8, 0, -4.2), (5.2, H, 4.2))
lv.env = {"kind": "interior_night", "ambient": [0.18, 0.2, 0.3], "ambient_energy": 0.9, "fog": 0.012, "fog_color": [0.12, 0.13, 0.2],
          "exposure": 1.0, "sdfgi": False, "vfog": True, "grade": "warm_night", "bg": [0.02, 0.03, 0.06]}

# ---- furniture
P = lv.place
P("tv_stand", (-4.72, 0, -1.2), -90, name="TVStand")
P("tv_flat", (-4.72, 0.12, -1.2), -90, name="TV")
P("couch", (-1.6, 0, -1.2), 90, name="Couch")
P("coffee_table", (-3.2, 0, -1.2), 90, name="CoffeeTable")
P("rug_livingroom", (-3.0, 0.01, -1.2), 90, name="Rug")
P("armchair", (-3.3, 0, -3.0), 200, name="Armchair")
P("bookshelf", (0.95, 0, -3.83), 180, name="Bookshelf")
P("floor_lamp", (-0.45, 0, -2.7), 0, name="FloorLamp")
P("desk", (-4.6, 0, 2.0), -90, name="Desk")
P("notebook", (-4.55, 0.77, 1.6), -90, name="Notebook")
P("office_chair", (-3.7, 0, 2.0), 80, name="OfficeChair")
P("corkboard", (-5.0, 0.95, 2.0), -90, name="Corkboard", group="aftermath")
P("fridge", (1.35, 0, 3.6), 0, name="Fridge")
P("kitchen_counter", (0.4, 0, 3.7), 0, name="CounterA")
P("stove_oven", (-0.5, 0, 3.7), 0, name="Stove")
P("kitchen_counter", (-1.5, 0, 3.7), 0, name="CounterB")
P("sink_unit", (-2.5, 0, 3.7), 0, name="Sink")
P("kettle", (-1.5, 0.9, 3.72), 0, name="Kettle")
P("dog_bed", (-0.9, 0, 1.4), 0, name="PicklesBed")
P("dog_bowl", (0.3, 0, 2.8), 0, name="PicklesBowl")
P("dog_bowl", (0.65, 0, 2.8), 0, name="PicklesWater")
P("dog_toy_duck", (-0.4, 0, 1.0), 40, name="DuckToy")
P("dog_toy_rope", (-1.6, 0, 1.9), 15, name="RopeToy")
P("pickles_vest", (-0.9, 0.16, 1.4), 0, name="PicklesVest")
P("door_apartment", (-4.85, 0, 4.0), 180, name="FrontDoor")
P("coat_rack", (-3.6, 0, 3.6), 0, name="CoatRack")
P("shoes_pair", (-4.5, 0, 3.4), 30, name="Shoes")
P("plant_pot", (-4.6, 0, -3.5), 0, name="Plant")
P("wall_clock_home", (-1.0, 2.1, 3.97), 180, name="WallClock")
P("wall_calendar", (-2.5, 1.6, 3.95), 180, name="Calendar")
# bedroom
P("bed", (3.95, 0, -2.6), 90, name="Bed")
P("helmet", (3.6, 0.63, -2.6), 20, name="BedHelmet", group="aftermath")
P("nightstand", (4.7, 0, -1.4), 90, name="Nightstand")
P("table_lamp", (4.72, 0.5, -1.52), 0, name="BedLamp")
P("laundry_basket", (2.4, 0, -3.5), 0, name="Laundry")
P("phone", (4.72, 0.5, -1.27), 90, name="Phone", opts={"use_verb": "Check phone"})
# bath
P("bath_set", (3.4, 0, 3.15), 0, name="BathSet")
# aftermath obsession decor
for i, (x, z) in enumerate(((0.55, -3.7), (1.65, 3.3), (-4.6, 3.75), (4.7, 0.9))):
    P("fire_extinguisher", (x, 0, z), i * 40, name="Extinguisher%d" % (i + 1), group="aftermath", opts={"hazard": 0})
for i, (x, y, z) in enumerate(((-3.75, 0.42, -1.5), (-2.65, 0.42, -0.9), (-2.65, 0.42, -1.5), (-3.75, 0.42, -0.9), (-4.4, 0.77, 1.3), (-4.4, 0.77, 2.7), (0.3, 0.0, -3.7))):
    P("foam_corner", (x, y, z), 0, name="Foam%d" % (i + 1), group="aftermath")
for i, (x, z) in enumerate(((-2.0, 3.97), (0.9, 3.97), (-4.97, -2.5), (-4.97, 0.4))):
    P("outlet_cover", (x, 0.3, z), 180 if z > 0 and abs(z) > 3 else -90, name="Outlet%d" % (i + 1), group="aftermath")

# ---- epilogue dressing (group "ending"; chapter 8 toggles these on and the "aftermath" group off)
P("tv_safety_show", (-4.6, 0.36, -1.2), -90, name="TvSafety", group="ending")
P("binder_dale", (-4.35, 0.77, 2.5), -70, name="DaleBinder", group="ending")
P("postcard_mills", (-4.3, 0.77, 1.2), -80, name="MillsPostcard", group="ending")
P("fridge_note_schedule", (1.2, 1.25, 3.215), 0, name="FridgeSchedule", group="ending")
P("gus_flyer", (1.55, 1.05, 3.215), 0, name="GusFlyer", group="ending")
P("brand_card", (0.95, 1.05, 3.215), 0, name="TiffCardAlive", group="ending_tiff_alive")
P("brand_card_sister", (0.95, 1.05, 3.215), 0, name="TiffCardDead", group="ending_tiff_dead")
P("scoreboard", (-5.0, 1.05, -2.9), -90, name="Scoreboard", group="ending")
P("note_graves", (-3.2, 0.44, -1.0), 20, name="GravesNote", group="ending")
P("mug", (-3.0, 0.44, -1.4), 0, name="Mug", group="ending")
P("leash_hook", (-4.9, 1.2, 3.6), -90, name="LeashHook", group="ending")
P("fire_extinguisher", (-2.7, 0, 3.72), 0, name="ExtinguisherEnd", group="ending", opts={"hazard": 0})
P("helmet", (-4.9, 0.02, 3.2), 0, name="HelmetCloset", group="ending", opts={"inspect": "ch8_insp_bed", "hazard": 0})
lv.marker("EndingStart", (-2.3, 0.05, -2.3), 90)
lv.marker("EndingDoor", (-4.3, 0.05, 3.2), 0)
lv.marker("EddieStart", (-2.3, 0.05, -2.3), 90)
lv.marker("EddieDoor", (-4.3, 0.05, 3.2), 0)
lv.marker("PicklesStart", (-0.9, 0.05, 1.0), 0)
lv.marker("SofaSit", (-1.3, 0.05, -0.6), 90)
lv.marker("GravesSpot", (-0.6, 0.05, 0.4), 250)
lv.marker("DeskSpot", (-3.9, 0.05, 1.7), -90)
lv.marker("KitchenSpot", (-1.5, 0.05, 2.8), 0)
lv.marker("PicklesBowlSpot", (0.45, 0.05, 2.5), 0)
lv.marker("WindowSpot", (-0.8, 0.05, -3.4), 0)
lv.marker("TVSpot", (-3.6, 0.05, -1.2), 270)
lv.export()
