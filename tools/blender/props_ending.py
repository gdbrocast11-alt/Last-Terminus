"""Small dressing props for the epilogue apartment (chapter 8). Origin = base centre, front faces +Y (Blender)."""
from props_registry import prop, text_mesh
from lt_lib import Prop


def _card(name, w, h, mat, lines, text_mat="PaintBlack", size=0.028, thick=0.006):
    p = Prop(name)
    p.box((w, thick, h), (0, 0, h / 2 + 0.002), mat, bevel=0.002)
    n = len(lines)
    for i, ln in enumerate(lines):
        text_mesh(p, ln, size, (0, thick / 2 + 0.001, h / 2 + 0.002 + (n - 1) * size * 0.9 - i * size * 1.8), text_mat, depth=0.0012, rot=(90, 0, 180))
    return p


@prop("binder_dale", cat="ending", body="rigid", mass=0.6, grab="light", col="box", inspect="ch8_dale_binder", tags=["ending"])
def binder_dale():
    p = Prop("binder_dale")
    p.box((0.26, 0.06, 0.32), (0, 0, 0.16), "PaintRed", bevel=0.006)
    p.box((0.22, 0.062, 0.05), (0, 0, 0.2), "PaperWhite" if False else "SignWhite")
    text_mesh(p, "THE TRUTH", 0.03, (0, 0.035, 0.25), "SignWhite", depth=0.002, rot=(90, 0, 180))
    text_mesh(p, "VOL. 1 OF 9", 0.022, (0, 0.035, 0.2), "SignYellow", depth=0.002, rot=(90, 0, 180))
    return p


@prop("brand_card", cat="ending", body="none", col="none", inspect="ch8_tiff_card", tags=["ending"])
def brand_card():
    return _card("brand_card", 0.2, 0.12, "PaintWhite", ["ACCEPTANCE(tm)", "It happens."], size=0.02)


@prop("brand_card_sister", cat="ending", body="none", col="none", inspect="ch8_tiff_card_dead", tags=["ending"])
def brand_card_sister():
    return _card("brand_card_sister", 0.2, 0.12, "PaintWhite", ["ALIGNED LIVING", "Be careful."], size=0.02)


@prop("gus_flyer", cat="ending", body="none", col="none", inspect="ch8_gus_flyer", tags=["ending"])
def gus_flyer():
    return _card("gus_flyer", 0.21, 0.3, "PaintYellow", ["GUS", "Retired safety", "inspector.", "Will fix", "anything."], size=0.026)


@prop("scoreboard", cat="ending", body="none", col="none", inspect="ch8_ml_score", tags=["ending"])
def scoreboard():
    p = Prop("scoreboard")
    p.box((0.9, 0.03, 0.6), (0, 0, 0.3), "PaintWhite", bevel=0.01)
    p.box((0.94, 0.02, 0.04), (0, 0, 0.6), "SteelBrushed")
    text_mesh(p, "MARCO   9", 0.075, (0, 0.02, 0.44), "PaintBlue", depth=0.004, rot=(90, 0, 180))
    text_mesh(p, "LUIS   9*", 0.075, (0, 0.02, 0.28), "PaintRed", depth=0.004, rot=(90, 0, 180))
    text_mesh(p, "*8.5", 0.04, (0.28, 0.02, 0.12), "PaintBlack", depth=0.003, rot=(90, 0, 180))
    return p


@prop("postcard_mills", cat="ending", body="none", col="none", inspect="ch8_mills_card", tags=["ending"])
def postcard_mills():
    return _card("postcard_mills", 0.15, 0.1, "Paper", ["PARKING PERMIT", "OFFICE", "best posting ever"], size=0.013)


@prop("note_graves", cat="ending", body="none", col="none", inspect="ch8_graves_note", tags=["ending"])
def note_graves():
    p = _card("note_graves", 0.14, 0.18, "Paper", ["The universe", "is a stickler.", "Enjoy your", "evening.", "P.S. Sandwiches."], size=0.014)
    p.box((0.1, 0.02, 0.03), (0.02, -0.03, 0.02), "WoodWarm")
    return p


@prop("tv_safety_show", cat="ending", body="none", col="none", tags=["ending"])
def tv_safety_show():
    p = Prop("tv_safety_show")
    p.box((1.15, 0.01, 0.65), (0, 0, 0.33), "ScreenBlue")
    text_mesh(p, "SAFETY FIRST, ISH!", 0.08, (0, 0.008, 0.36), "SignWhite", depth=0.002, rot=(90, 0, 180))
    return p


@prop("mug", cat="ending", body="rigid", mass=0.3, grab="light", col="cylinder", tags=["ending"])
def mug():
    p = Prop("mug")
    p.cyl(0.04, 0.09, (0, 0, 0.045), "PaintWhite", seg=12)
    p.tube([(0.04, 0, 0.07), (0.075, 0, 0.065), (0.075, 0, 0.03), (0.04, 0, 0.025)], 0.006, "PaintWhite", seg=4)
    return p


@prop("fridge_note_schedule", cat="ending", body="none", col="none", inspect="ch8_insp_fridge", tags=["ending"])
def fridge_note_schedule():
    return _card("fridge_note_schedule", 0.22, 0.28, "Paper", ["PICKLES", "7am  breakfast", "6pm  dinner", "(no colours)"], size=0.018)


@prop("leash_hook", cat="ending", body="none", col="none", tags=["ending"])
def leash_hook():
    p = Prop("leash_hook")
    p.box((0.05, 0.02, 0.1), (0, 0, 0.05), "WoodWarm")
    p.tube([(0, 0.02, 0.08), (0.02, 0.06, 0.0), (0.03, 0.1, -0.15), (0.0, 0.1, -0.3)], 0.006, "FabricRed", seg=4)
    return p
