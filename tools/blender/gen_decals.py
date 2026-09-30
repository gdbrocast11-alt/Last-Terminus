#!/usr/bin/env python3
"""Procedural decal + particle textures (white masks, tinted in-engine)."""
import os
import numpy as np
from PIL import Image
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "textures")
N = 256
rng = np.random.default_rng(77)
yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
cx = cy = N / 2


def save_mask(name, m, normal=True):
    m = np.clip(m, 0, 1)
    rgba = np.zeros((N, N, 4), np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = (m * 255).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, name + ".png"), optimize=True)


def blob(x0, y0, r, soft=0.15):
    d = np.sqrt((xx - x0) ** 2 + (yy - y0) ** 2)
    return np.clip((r - d) / (r * soft + 1e-3), 0, 1)


def splat(seed, main_r=60, drops=40):
    r = np.random.default_rng(seed)
    m = blob(cx, cy, main_r, 0.2)
    ang = r.uniform(0, 6.28, 9)
    for a in ang:                                 # streaks
        L = r.uniform(30, 100)
        for t in np.linspace(0, 1, 16):
            m = np.maximum(m, blob(cx + np.cos(a) * L * t, cy + np.sin(a) * L * t, main_r * 0.35 * (1 - t) + 2, 0.3))
    for _ in range(drops):
        a = r.uniform(0, 6.28); d = r.uniform(main_r * 0.9, N * 0.46)
        m = np.maximum(m, blob(cx + np.cos(a) * d, cy + np.sin(a) * d, r.uniform(2, 8), 0.3))
    return m


def main():
    os.makedirs(OUT, exist_ok=True)
    for i in range(3):
        save_mask("decal_splat_%d" % (i + 1), splat(i + 3, 50 + 10 * i, 30 + 12 * i))
    n = np.zeros((N, N), np.float32)
    for k in range(6):
        n = np.maximum(n, blob(cx + rng.uniform(-30, 30), cy + rng.uniform(-30, 30), rng.uniform(50, 80), 0.25))
    save_mask("decal_puddle", n * 0.85)
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / (N / 2)
    save_mask("decal_scorch", np.clip(1.0 - d, 0, 1) ** 0.7 * (0.75 + 0.25 * rng.uniform(size=(N, N))))
    save_mask("fx_soft", np.clip(1.0 - d, 0, 1) ** 2)
    save_mask("fx_spark", np.clip(1.0 - d * 1.6, 0, 1) ** 3)
    ring = np.exp(-((d - 0.7) ** 2) / 0.01)
    save_mask("fx_ring", ring)
    save_mask("fx_star", np.clip((np.abs(np.cos(np.arctan2(yy - cy, xx - cx) * 2.5)) ** 8 * 0.9 + 0.1) * np.clip(1.4 - d * 1.4, 0, 1), 0, 1))
    print("decals ok")

main()
