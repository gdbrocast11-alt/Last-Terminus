"""Single source of truth for materials.

Blender scripts use it for previews and to compute tile-scaled UVs; the Godot
builder (tools/godot/build_materials.gd) reads materials/materials.json,
produced by `python3 tools/blender/materials_def.py`, to create StandardMaterial3D
resources with the generated PBR texture sets.

Fields
  tex     texture set name in textures/ (albedo/normal/orm) or None
  color   albedo tint (linear-ish sRGB 0..1); multiplies the texture
  tile    world-space size in metres covered by one texture repeat
  rough / metal   scalar multipliers when no ORM texture, or roughness bias
  emit    emission colour + energy for lit signage etc.
  alpha   0..1 transparency (glass)
  vcol    use vertex colour as albedo (Pickles patches, decals)
  cull    'back' | 'none'
"""
import json, os

M = {}


def mat(name, tex=None, color=(0.8, 0.8, 0.8), tile=1.0, rough=0.7, metal=0.0, emit=None, alpha=1.0,
        vcol=False, cull="back", normal=1.0, sss=0.0):
    M[name] = dict(tex=tex, color=list(color), tile=tile, rough=rough, metal=metal, emit=emit, alpha=alpha,
                   vcol=vcol, cull=cull, normal=normal, sss=sss)


# ---- architecture ------------------------------------------------------------
mat("Concrete", "concrete_smooth", (0.72, 0.72, 0.70), 3.0, 0.75)
mat("ConcreteRough", "concrete_rough", (0.62, 0.62, 0.60), 3.0, 0.9)
mat("ConcreteDark", "concrete_rough", (0.30, 0.30, 0.31), 3.0, 0.9)
mat("Terrazzo", "terrazzo", (0.95, 0.94, 0.9), 2.5, 0.35)
mat("TerrazzoDark", "terrazzo", (0.45, 0.47, 0.5), 2.5, 0.35)
mat("TileWhite", "tile_white", (0.95, 0.96, 0.97), 1.6, 0.45)
mat("TileGrey", "tile_floor", (0.55, 0.57, 0.6), 2.4, 0.5)
mat("TileTeal", "tile_white", (0.25, 0.55, 0.55), 1.6, 0.4)
mat("CarpetGrey", "carpet", (0.32, 0.34, 0.38), 1.5, 0.95)
mat("CarpetBlue", "carpet", (0.16, 0.26, 0.42), 1.5, 0.95)
mat("CarpetSage", "carpet", (0.45, 0.55, 0.45), 1.5, 0.95)
mat("Rug", "fabric", (0.55, 0.28, 0.22), 1.2, 0.95)
mat("Wood", "wood_planks", (1.0, 0.92, 0.82), 1.6, 0.55)
mat("WoodDark", "wood_planks", (0.55, 0.36, 0.24), 1.6, 0.5)
mat("WoodWarm", "wood_planks", (0.85, 0.6, 0.38), 1.6, 0.5)
mat("Plywood", "plywood", (0.9, 0.78, 0.55), 1.4, 0.7)
mat("Lumber", "plywood", (0.85, 0.68, 0.42), 1.0, 0.75)
mat("WallWhite", "wall_paint", (0.9, 0.9, 0.88), 2.0, 0.85, normal=0.4)
mat("WallCream", "wall_paint", (0.86, 0.8, 0.66), 2.0, 0.85, normal=0.4)
mat("WallGrey", "wall_paint", (0.55, 0.58, 0.6), 2.0, 0.85, normal=0.4)
mat("WallGreen", "wall_paint", (0.4, 0.55, 0.45), 2.0, 0.85, normal=0.4)
mat("WallBlue", "wall_paint", (0.28, 0.4, 0.55), 2.0, 0.85, normal=0.4)
mat("WallRed", "wall_paint", (0.6, 0.16, 0.14), 2.0, 0.8, normal=0.4)
mat("WallSage", "wall_paint", (0.62, 0.72, 0.62), 2.0, 0.85, normal=0.4)
mat("Brick", "brick", (0.75, 0.5, 0.42), 2.4, 0.9)
mat("Asphalt", "asphalt", (0.5, 0.5, 0.5), 3.0, 0.92)
mat("Gravel", "gravel", (0.75, 0.72, 0.68), 2.0, 0.95)
mat("Grass", "grass", (0.62, 0.8, 0.5), 2.0, 0.95)
mat("Dirt", "dirt", (0.7, 0.55, 0.42), 2.5, 0.95)
mat("Sidewalk", "concrete_smooth", (0.85, 0.83, 0.8), 2.0, 0.85)
mat("CeilingTile", "ceiling_tile", (0.92, 0.92, 0.9), 0.6, 0.9)
mat("Glass", None, (0.7, 0.85, 0.9), 1.0, 0.04, alpha=0.18, cull="none")
mat("GlassTint", None, (0.25, 0.4, 0.45), 1.0, 0.05, alpha=0.4, cull="none")
mat("GlassFrost", None, (0.85, 0.9, 0.95), 1.0, 0.35, alpha=0.5, cull="none")
mat("MirrorMetal", None, (0.9, 0.9, 0.92), 1.0, 0.05, metal=1.0)
# ---- metals / industrial -----------------------------------------------------
mat("SteelBrushed", "metal_brushed", (0.85, 0.86, 0.88), 1.0, 0.45, metal=1.0)
mat("SteelDark", "metal_brushed", (0.32, 0.33, 0.36), 1.0, 0.5, metal=0.9)
mat("SteelGalv", "metal_brushed", (0.7, 0.72, 0.74), 1.0, 0.55, metal=0.9)
mat("Chrome", None, (0.95, 0.95, 0.97), 1.0, 0.08, metal=1.0)
mat("Brass", None, (0.85, 0.65, 0.25), 1.0, 0.3, metal=1.0)
mat("Corrugated", "corrugated", (0.75, 0.77, 0.78), 1.2, 0.5, metal=0.9)
mat("DiamondPlate", "diamond_plate", (0.65, 0.66, 0.68), 0.8, 0.45, metal=0.9)
mat("PaintYellow", "paint_metal", (0.95, 0.72, 0.08), 1.0, 0.5, metal=0.2)
mat("PaintRed", "paint_metal", (0.75, 0.08, 0.06), 1.0, 0.45, metal=0.2)
mat("PaintOrange", "paint_metal", (0.95, 0.4, 0.05), 1.0, 0.5, metal=0.2)
mat("PaintBlue", "paint_metal", (0.1, 0.25, 0.6), 1.0, 0.45, metal=0.2)
mat("SignBoardGreen", "paint_metal", (0.03, 0.26, 0.15), 1.5, 0.45)
mat("PaintGreen", "paint_metal", (0.12, 0.45, 0.25), 1.0, 0.45, metal=0.2)
mat("PaintWhite", "paint_metal", (0.9, 0.9, 0.9), 1.0, 0.45, metal=0.2)
mat("PaintBlack", "paint_metal", (0.05, 0.05, 0.06), 1.0, 0.5, metal=0.2)
mat("PaintGrey", "paint_metal", (0.4, 0.42, 0.45), 1.0, 0.5, metal=0.2)
mat("PaintTeal", "paint_metal", (0.1, 0.5, 0.5), 1.0, 0.45, metal=0.2)
mat("Rust", "paint_metal", (0.5, 0.25, 0.14), 1.0, 0.85, metal=0.4)
mat("Rubber", "rubber", (0.06, 0.06, 0.06), 0.5, 0.85)
mat("RubberGym", "rubber", (0.12, 0.13, 0.15), 0.8, 0.9)
mat("RubberRed", "rubber", (0.6, 0.08, 0.06), 0.8, 0.85)
# ---- plastics / fabrics / paper ------------------------------------------------
mat("PlasticWhite", None, (0.92, 0.92, 0.9), 1.0, 0.35)
mat("PlasticBlack", None, (0.04, 0.04, 0.05), 1.0, 0.4)
mat("PlasticRed", None, (0.8, 0.05, 0.04), 1.0, 0.35)
mat("PlasticBlue", None, (0.1, 0.25, 0.7), 1.0, 0.35)
mat("PlasticGreen", None, (0.1, 0.6, 0.25), 1.0, 0.35)
mat("PlasticYellow", None, (0.95, 0.8, 0.1), 1.0, 0.35)
mat("PlasticPink", None, (0.95, 0.35, 0.55), 1.0, 0.35)
mat("PlasticPurple", None, (0.5, 0.15, 0.6), 1.0, 0.35)
mat("PlasticOrange", None, (0.95, 0.42, 0.08), 1.0, 0.35)
mat("PlasticGrey", None, (0.5, 0.52, 0.55), 1.0, 0.4)
mat("Fabric", "fabric", (0.5, 0.5, 0.5), 0.8, 0.95)
mat("FabricGrey", "fabric", (0.35, 0.37, 0.4), 0.8, 0.95)
mat("FabricBlue", "fabric", (0.15, 0.28, 0.5), 0.8, 0.95)
mat("FabricRed", "fabric", (0.55, 0.1, 0.1), 0.8, 0.95)
mat("FabricGreen", "fabric", (0.2, 0.42, 0.28), 0.8, 0.95)
mat("FabricCream", "fabric", (0.85, 0.8, 0.7), 0.8, 0.95)
mat("FabricPurple", "fabric", (0.4, 0.2, 0.5), 0.8, 0.95)
mat("FabricNavy", "fabric", (0.07, 0.1, 0.22), 0.8, 0.95)
mat("FabricKhaki", "fabric", (0.6, 0.52, 0.34), 0.8, 0.95)
mat("FabricWhite", "fabric", (0.9, 0.9, 0.88), 0.8, 0.95)
mat("FabricBlack", "fabric", (0.05, 0.05, 0.06), 0.8, 0.95)
mat("FabricYellow", "fabric", (0.9, 0.7, 0.12), 0.8, 0.95)
mat("FabricOrange", "fabric", (0.9, 0.4, 0.08), 0.8, 0.95)
mat("FabricTeal", "fabric", (0.12, 0.5, 0.5), 0.8, 0.95)
mat("FabricPink", "fabric", (0.9, 0.5, 0.6), 0.8, 0.95)
mat("FabricOlive", "fabric", (0.28, 0.32, 0.18), 0.8, 0.95)
mat("FabricMaroon", "fabric", (0.35, 0.06, 0.1), 0.8, 0.95)
mat("FabricCharcoal", "fabric", (0.16, 0.17, 0.19), 0.8, 0.95)
mat("Sole", "rubber", (0.85, 0.85, 0.82), 0.5, 0.8)
mat("ShoeWhite", "fabric", (0.9, 0.9, 0.92), 0.5, 0.6)
mat("ShoeBrown", "fabric", (0.25, 0.14, 0.08), 0.5, 0.5)
mat("ShoeBlack", "fabric", (0.05, 0.05, 0.05), 0.5, 0.5)
mat("Leather", "fabric", (0.22, 0.12, 0.08), 0.8, 0.55, normal=0.6)
mat("Denim", "fabric", (0.15, 0.22, 0.38), 0.6, 0.95)
mat("Cardboard", "cardboard", (0.8, 0.62, 0.42), 0.8, 0.9)
mat("Paper", None, (0.95, 0.94, 0.9), 1.0, 0.85)
mat("Candle", None, (0.95, 0.9, 0.78), 1.0, 0.4, sss=0.5)
mat("Fur", "fur", (0.8, 0.6, 0.4), 0.6, 0.9, vcol=True, normal=0.8)
mat("Skin", None, (0.87, 0.65, 0.52), 1.0, 0.55, sss=0.4)
mat("SkinTan", None, (0.72, 0.5, 0.36), 1.0, 0.55, sss=0.4)
mat("SkinDark", None, (0.42, 0.27, 0.19), 1.0, 0.55, sss=0.4)
mat("SkinPale", None, (0.93, 0.78, 0.68), 1.0, 0.55, sss=0.4)
mat("SkinOlive", None, (0.74, 0.57, 0.42), 1.0, 0.55, sss=0.4)
mat("Lips", None, (0.72, 0.36, 0.34), 1.0, 0.4)
mat("Teeth", None, (0.95, 0.94, 0.88), 1.0, 0.3)
mat("EyeWhite", None, (0.95, 0.95, 0.95), 1.0, 0.15)
mat("EyeIris", None, (0.25, 0.4, 0.55), 1.0, 0.1)
mat("EyeDark", None, (0.08, 0.05, 0.03), 1.0, 0.1)
mat("HairBlack", None, (0.04, 0.035, 0.03), 1.0, 0.5)
mat("HairBrown", None, (0.2, 0.11, 0.06), 1.0, 0.5)
mat("HairBlonde", None, (0.75, 0.6, 0.3), 1.0, 0.5)
mat("HairGrey", None, (0.65, 0.65, 0.66), 1.0, 0.55)
mat("HairRed", None, (0.5, 0.15, 0.06), 1.0, 0.5)
mat("HairWhite", None, (0.9, 0.9, 0.9), 1.0, 0.55)
mat("Tongue", None, (0.85, 0.35, 0.4), 1.0, 0.3)
mat("Nose", None, (0.05, 0.04, 0.04), 1.0, 0.15)
mat("Paint", None, (0.72, 0.05, 0.06), 1.0, 0.3)
mat("Blood", None, (0.4, 0.0, 0.02), 1.0, 0.2)
mat("Water", None, (0.3, 0.55, 0.65), 1.0, 0.05, alpha=0.55, cull="none")
mat("Smoothie", None, (0.65, 0.2, 0.6), 1.0, 0.25)
mat("Coffee", None, (0.18, 0.1, 0.06), 1.0, 0.2)
mat("Oil", None, (0.7, 0.5, 0.08), 1.0, 0.1, alpha=0.8)
# ---- emissive / signage -----------------------------------------------------------
mat("LightTube", None, (1.0, 0.98, 0.9), 1.0, 0.2, emit=((1.0, 0.96, 0.85), 3.0))
mat("LightWarm", None, (1.0, 0.75, 0.45), 1.0, 0.3, emit=((1.0, 0.75, 0.45), 2.5))
mat("ScreenBlue", None, (0.1, 0.3, 0.6), 1.0, 0.1, emit=((0.2, 0.5, 1.0), 1.6))
mat("ScreenGreen", None, (0.1, 0.5, 0.25), 1.0, 0.1, emit=((0.3, 1.0, 0.5), 1.4))
mat("ScreenOff", None, (0.02, 0.02, 0.03), 1.0, 0.1)
mat("SignYellow", None, (0.95, 0.75, 0.05), 1.0, 0.45, emit=((0.95, 0.75, 0.05), 0.3))
mat("SignWhite", None, (0.95, 0.95, 0.95), 1.0, 0.4, emit=((1, 1, 1), 0.5))
mat("SignRed", None, (0.85, 0.05, 0.05), 1.0, 0.4, emit=((1, 0.1, 0.1), 0.6))
mat("SignGreen", None, (0.05, 0.6, 0.25), 1.0, 0.4, emit=((0.1, 1, 0.4), 0.7))
mat("LedRed", None, (1.0, 0.05, 0.02), 1.0, 0.2, emit=((1, 0.05, 0.02), 4.0))
mat("LedGreen", None, (0.1, 1.0, 0.2), 1.0, 0.2, emit=((0.1, 1, 0.2), 4.0))
mat("Fire", None, (1.0, 0.5, 0.1), 1.0, 0.5, emit=((1, 0.5, 0.1), 5.0))
mat("Hazard", "paint_metal", (0.95, 0.75, 0.05), 1.0, 0.5)
mat("Decal", None, (1, 1, 1), 1.0, 0.8)


def write_json(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    json.dump(M, open(path, "w"), indent=1)


if __name__ == "__main__":
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    write_json(os.path.join(root, "materials", "materials.json"))
    print(len(M), "materials")
