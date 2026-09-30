"""Generate all human characters.
   blender -b --python tools/blender/gen_characters.py -- [--only eddie,brenda]
Outputs characters/<id>.glb (skinned, animated) and source_art/characters.blend (last built).
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
import lt_lib as L
import chars_lib as C
import chars_anims as A

# id: (height, width, build, belly, shoulders, face kwargs, style)
CHARS = {
    "eddie": dict(height=1.78, width=1.0, build=1.0, belly=0.02, shoulders=1.0,
                  face=dict(face_w=1.0, jaw_w=1.0, cranium=1.0),
                  style=dict(skin="Skin", top="FabricGreen", sleeves="FabricGreen", jacket="FabricGreen", pants="Denim", shoes="ShoeWhite",
                             hair="HairBrown", hair_style="messy", iris="EyeIris", stubble=True, brow_t=1.1, collar="FabricGrey", nose=1.05)),
    "brenda": dict(height=1.68, width=0.96, build=0.98, belly=0.0, shoulders=1.0,
                   face=dict(face_w=1.02, jaw_w=1.0, cranium=1.0),
                   style=dict(skin="SkinTan", top="FabricYellow", sleeves="FabricYellow", jacket="Denim", pants="Denim", shoes="ShoeBrown",
                              hair="HairRed", hair_style="ponytail", bandana="FabricRed", toolbelt=True, sleeve_len="short", high_pants=True, nose=0.9,
                              iris="EyeDark")),
    "dale": dict(height=1.75, width=0.92, build=0.9, belly=0.0, shoulders=0.95,
                 face=dict(face_w=0.96, jaw_w=1.1, cranium=1.03),
                 style=dict(skin="SkinPale", top="FabricOlive", sleeves="FabricOlive", jacket="FabricOlive", pants="FabricKhaki", shoes="ShoeBlack",
                            hair="HairBlack", hair_style="curly", glasses="PlasticBlack", collar="FabricWhite", nose=1.15)),
    "tiffany": dict(height=1.72, width=0.92, build=0.9, belly=0.0, shoulders=0.92,
                    face=dict(face_w=0.94, jaw_w=1.0, cranium=1.0),
                    style=dict(skin="SkinOlive", top="FabricWhite", sleeves="FabricWhite", jacket="FabricWhite", pants="FabricWhite", shoes="ShoeWhite",
                               hair="HairBlonde", hair_style="long", headband="FabricPink", sleeve_len="short", nose=0.85, iris="EyeIris",
                               high_pants=True)),
    "mills": dict(height=1.85, width=1.12, build=1.12, belly=0.1, shoulders=1.12,
                  face=dict(face_w=1.06, jaw_w=0.85, cranium=1.0, chin=1.2),
                  style=dict(skin="SkinDark", top="FabricNavy", sleeves="FabricNavy", jacket="FabricNavy", pants="FabricCharcoal", shoes="ShoeBlack",
                             hair="HairBlack", hair_style="bald", cap="FabricNavy", badge=True, radio=True, tie="FabricBlack", iris="EyeDark", nose=1.0)),
    "gus": dict(height=1.70, width=0.96, build=0.95, belly=0.05, shoulders=0.9,
                face=dict(face_w=0.98, jaw_w=1.1, cranium=1.0),
                style=dict(skin="SkinPale", top="FabricKhaki", sleeves="FabricKhaki", jacket="FabricKhaki", pants="FabricKhaki", shoes="ShoeBrown",
                           hair="HairWhite", hair_style="wisps", glasses="MirrorMetal", high_pants=True, nose=1.2, iris="EyeIris",
                           brow_t=1.6, collar="FabricWhite")),
    "marco": dict(height=1.80, width=1.1, build=1.08, belly=0.06, shoulders=1.1,
                  face=dict(face_w=1.05, jaw_w=0.9, cranium=1.0),
                  style=dict(skin="SkinOlive", top="FabricRed", sleeves="FabricRed", jacket="FabricRed", pants="FabricCharcoal", shoes="ShoeWhite",
                             hair="HairBlack", hair_style="short", sleeve_len="short", iris="EyeDark", nose=1.1, brow_t=1.3)),
    "luis": dict(height=1.75, width=0.96, build=0.95, belly=0.0, shoulders=0.98,
                 face=dict(face_w=0.98, jaw_w=1.0, cranium=1.0),
                 style=dict(skin="SkinOlive", top="FabricBlue", sleeves="FabricBlue", jacket="FabricBlue", pants="Denim", shoes="ShoeWhite",
                            hair="HairBlack", hair_style="messy", headband="FabricWhite", iris="EyeDark", nose=1.0, brow_t=1.2)),
    "graves": dict(height=1.90, width=0.94, build=0.9, belly=0.0, shoulders=0.96,
                   face=dict(face_w=0.92, jaw_w=1.05, cranium=1.04, chin=1.3),
                   style=dict(skin="SkinPale", top="FabricBlack", sleeves="FabricBlack", jacket="FabricBlack", pants="FabricBlack", shoes="ShoeBlack",
                              hair="HairGrey", hair_style="swept", mustache=True, collar="FabricWhite", tie="FabricMaroon", nose=1.35,
                              cape="FabricBlack", iris="EyeIris", brow_t=1.5)),
    "stranger_a": dict(height=1.66, width=0.95, build=0.95, belly=0.0, shoulders=0.95,
                       face=dict(), style=dict(skin="SkinTan", top="FabricTeal", sleeves="FabricTeal", jacket="FabricTeal", pants="FabricBlack", shoes="ShoeBlack",
                                               hair="HairBrown", hair_style="long", high_pants=True)),
    "stranger_b": dict(height=1.82, width=1.05, build=1.05, belly=0.08, shoulders=1.05,
                       face=dict(), style=dict(skin="SkinDark", top="FabricCharcoal", sleeves="FabricCharcoal", jacket="FabricCharcoal", pants="FabricCharcoal", shoes="ShoeBlack",
                                               hair="HairBlack", hair_style="short", tie="FabricRed", collar="FabricWhite")),
    "stranger_c": dict(height=1.62, width=1.0, build=1.0, belly=0.04, shoulders=0.95,
                       face=dict(), style=dict(skin="SkinPale", top="FabricPurple", sleeves="FabricPurple", jacket="FabricPurple", pants="Denim", shoes="ShoeWhite",
                                               hair="HairBlonde", hair_style="ponytail", sleeve_len="short")),
    "stranger_d": dict(height=1.76, width=1.0, build=1.0, belly=0.0, shoulders=1.0,
                       face=dict(), style=dict(skin="SkinOlive", top="FabricOrange", sleeves="FabricOrange", jacket="FabricOrange", pants="FabricKhaki", shoes="ShoeBrown",
                                               hair="HairBrown", hair_style="short", cap="FabricBlue")),
    "kid": dict(height=1.22, width=0.72, build=0.8, belly=0.03, shoulders=0.8,
                face=dict(face_w=1.12, jaw_w=1.2, cranium=1.15),
                style=dict(skin="SkinTan", top="FabricYellow", sleeves="FabricYellow", jacket="FabricYellow", pants="Denim", shoes="ShoeWhite",
                           hair="HairBlack", hair_style="messy", sleeve_len="short", nose=0.6, iris="EyeDark", shorts=True)),
    "driver": dict(height=1.78, width=1.15, build=1.15, belly=0.12, shoulders=1.1,
                   face=dict(face_w=1.05), style=dict(skin="SkinTan", top="FabricTeal", sleeves="FabricTeal", jacket="FabricTeal", pants="FabricNavy", shoes="ShoeBlack",
                                                      hair="HairGrey", hair_style="short", cap="FabricNavy", mustache=True)),
}

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
only = None
if "--only" in argv:
    only = set(argv[argv.index("--only") + 1].split(","))
noanim = "--noanim" in argv

for cid, spec in CHARS.items():
    if only and cid not in only:
        continue
    L.reset_scene()
    style = dict(spec["style"])
    rig, arm, mesh = C.build_character(cid, spec["height"], style, width=spec["width"], build=spec["build"], belly=spec["belly"],
                                       shoulders=spec["shoulders"], face=spec["face"])
    if not noanim:
        ab = A.build_all(arm)
        ab.k_scale = lambda k=rig.k: k
        # rebuild with proper height scaling for hip offsets
        for act in list(bpy.data.actions):
            bpy.data.actions.remove(act)
        ab = C.ActionBuilder(arm)
        ab.k_scale = lambda k=rig.k: k
        for name, frames, fn, loop in A.ACTIONS:
            ab.make(name, frames, fn, loop)
        C.push_all_to_nla(arm)
    out = os.path.join(L.ROOT, "characters", cid + ".glb")
    L.export_glb([arm, mesh], out, animations=not noanim)
    L.save_blend(os.path.join(L.ROOT, "source_art", "char_" + cid + ".blend"))
    print("CHAR", cid, os.path.getsize(out) // 1024, "KB")
