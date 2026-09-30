"""Build all procedural props:  blender -b --python tools/blender/gen_props.py -- [category_modules...] [--only name,...]

Outputs props/<name>.glb, props/props_def.json and source_art/props_<module>.blend.
"""
import sys, os, importlib, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import props_registry as R
import lt_lib as L

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
only = None
if "--only" in argv:
    i = argv.index("--only")
    only = set(argv[i + 1].split(","))
    argv = argv[:i] + argv[i + 2:]
modules = argv or ["props_transit", "props_store", "props_wellness", "props_home", "props_yard", "props_street"]
out_dir = os.path.join(L.ROOT, "props")
meta_path = os.path.join(out_dir, "props_def.json")
for m in modules:
    R.REG.clear()
    mod = importlib.import_module(m)
    importlib.reload(mod)
    meta = R.export_all([m], out_dir, os.path.join(L.ROOT, "source_art", m + ".blend"), only=only)
    R.write_meta(meta, meta_path)
    print("PROPS", m, len(meta))
