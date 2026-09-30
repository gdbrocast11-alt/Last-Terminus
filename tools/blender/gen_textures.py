#!/usr/bin/env python3
"""Procedural, seamlessly tiling PBR texture sets for Last Terminus.

Writes textures/<name>_albedo.png, _normal.png (OpenGL/Y+), _orm.png
(R=ambient occlusion, G=roughness, B=metallic). Pure numpy + PIL, no Blender.
"""
import os, sys
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "textures")
N = 512


# --------------------------------------------------------------------------- noise
def _rng(seed):
    return np.random.default_rng(seed)


def value_noise(n, freq, seed, stretch=(1, 1)):
    """Periodic value noise on an n x n grid with `freq` cells (bicubic-ish smoothstep)."""
    r = _rng(seed)
    fy, fx = max(1, int(freq * stretch[1])), max(1, int(freq * stretch[0]))
    lat = r.random((fy, fx)).astype(np.float32)
    ys = np.linspace(0, fy, n, endpoint=False)
    xs = np.linspace(0, fx, n, endpoint=False)
    y0 = np.floor(ys).astype(int); x0 = np.floor(xs).astype(int)
    ty = ys - y0; tx = xs - x0
    ty = ty * ty * (3 - 2 * ty); tx = tx * tx * (3 - 2 * tx)
    y1 = (y0 + 1) % fy; x1 = (x0 + 1) % fx
    a = lat[np.ix_(y0, x0)]; b = lat[np.ix_(y0, x1)]
    c = lat[np.ix_(y1, x0)]; d = lat[np.ix_(y1, x1)]
    top = a * (1 - tx)[None, :] + b * tx[None, :]
    bot = c * (1 - tx)[None, :] + d * tx[None, :]
    return top * (1 - ty)[:, None] + bot * ty[:, None]


def fbm(n, freq, seed, octaves=5, gain=0.5, stretch=(1, 1)):
    tot = np.zeros((n, n), np.float32); amp = 1.0; norm = 0.0
    for o in range(octaves):
        tot += amp * value_noise(n, freq * (2 ** o), seed + o * 101, stretch)
        norm += amp; amp *= gain
    return tot / norm


def voronoi(n, cells, seed):
    """Returns (F1 distance, cell id) for periodic Voronoi."""
    r = _rng(seed)
    pts = r.random((cells, cells, 2)).astype(np.float32)
    ids = r.random((cells, cells)).astype(np.float32)
    ys, xs = np.mgrid[0:n, 0:n].astype(np.float32) / n * cells
    cy = np.floor(ys).astype(int); cx = np.floor(xs).astype(int)
    best = np.full((n, n), 9.0, np.float32); bid = np.zeros((n, n), np.float32)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            yy = (cy + dy) % cells; xx = (cx + dx) % cells
            py = pts[yy, xx, 0] + cy + dy; px = pts[yy, xx, 1] + cx + dx
            dist = np.sqrt((ys - py) ** 2 + (xs - px) ** 2)
            m = dist < best
            best = np.where(m, dist, best); bid = np.where(m, ids[yy, xx], bid)
    return best, bid


def blur(a, k=2):
    for _ in range(k):
        a = (np.roll(a, 1, 0) + np.roll(a, -1, 0) + np.roll(a, 1, 1) + np.roll(a, -1, 1) + 4 * a) / 8
    return a


def normal_from_height(h, strength=2.0):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * strength * N / 64
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * strength * N / 64
    nx, ny, nz = -dx, dy, np.ones_like(h)   # +Y up (OpenGL convention: green = up)
    ln = np.sqrt(nx * nx + ny * ny + nz * nz)
    return np.stack([nx / ln, ny / ln, nz / ln], -1) * 0.5 + 0.5


# how much of each texture's own contrast survives (big flat surfaces read calmer at low contrast)
CONTRAST = {"terrazzo": 0.4, "wall_paint": 0.45, "ceiling_tile": 0.5, "concrete_rough": 0.55, "concrete_smooth": 0.55, "carpet": 0.5, "asphalt": 0.55,
            "dirt": 0.6, "gravel": 0.55, "grass": 0.7, "tile_floor": 0.7, "tile_white": 0.75, "plywood": 0.75, "cardboard": 0.75}


NORMAL_K = {"wall_paint": 0.1, "ceiling_tile": 0.35, "concrete_smooth": 0.3, "terrazzo": 0.3, "carpet": 0.4, "tile_white": 0.5, "tile_floor": 0.5}


def save_set(name, albedo, height, rough, metal=0.0, ao=None, nstrength=2.0):
    os.makedirs(OUT, exist_ok=True)
    albedo = np.clip(albedo, 0, 1)
    k = CONTRAST.get(name, 0.85)
    if albedo.ndim == 3:
        mean = albedo.mean(axis=(0, 1), keepdims=True)
        albedo = np.clip(mean + (albedo - mean) * k, 0, 1)
    nstrength = nstrength * NORMAL_K.get(name, 0.5)
    if ao is None:
        ao = 1.0 - np.clip((blur(height, 3) - height) * 3.0, 0, 0.5)
    rough = np.broadcast_to(rough, (N, N)).astype(np.float32)
    metal = np.broadcast_to(metal, (N, N)).astype(np.float32)
    orm = np.stack([np.clip(ao, 0, 1), np.clip(rough, 0, 1), np.clip(metal, 0, 1)], -1)
    def sv(arr, suffix):
        Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, f"{name}_{suffix}.png"), optimize=True)
    sv(albedo, "albedo"); sv(normal_from_height(height, nstrength), "normal"); sv(orm, "orm")


def tint(base, var, color_a, color_b=None, t=None):
    c = np.array(color_a, np.float32)
    img = np.ones((N, N, 3), np.float32) * c
    if color_b is not None:
        t = var if t is None else t
        img = img * (1 - t[..., None]) + np.array(color_b, np.float32) * t[..., None]
    return img * (0.85 + 0.3 * base[..., None])


# --------------------------------------------------------------------------- sets
def concrete_smooth():
    b = fbm(N, 3, 1); f = fbm(N, 40, 2, 3); h = 0.5 * b + 0.15 * f
    cracks, _ = voronoi(N, 5, 3); crack = np.clip(1 - cracks * 14, 0, 1) * (fbm(N, 8, 4) > 0.58)
    alb = tint(0.6 * b + 0.4 * f, None, (0.62, 0.62, 0.6)) * (1 - 0.35 * crack[..., None])
    save_set("concrete_smooth", alb, h * 0.5 - crack * 0.3, 0.55 + 0.25 * fbm(N, 6, 5) + 0.2 * crack, 0.0, nstrength=1.2)


def concrete_rough():
    b = fbm(N, 4, 11); f = fbm(N, 64, 12, 3); pits = (fbm(N, 30, 13, 2) > 0.66).astype(np.float32)
    h = 0.6 * b + 0.3 * f - 0.4 * blur(pits, 1)
    alb = tint(0.5 * b + 0.5 * f, None, (0.55, 0.55, 0.53)) * (1 - 0.3 * pits[..., None])
    save_set("concrete_rough", alb, h, 0.85 + 0.1 * f, 0.0, nstrength=3.0)


def terrazzo():
    d, cid = voronoi(N, 46, 21)
    pal = np.array([[0.95, 0.94, 0.9], [0.75, 0.7, 0.6], [0.35, 0.38, 0.42], [0.85, 0.82, 0.78], [0.55, 0.45, 0.4]], np.float32)
    idx = (cid * 5).astype(int) % 5
    chips = (fbm(N, 6, 22) > 0.47) & (d < 0.55)
    base = np.ones((N, N, 3), np.float32) * np.array([0.9, 0.89, 0.85], np.float32)
    base = np.where(chips[..., None], pal[idx], base)
    b = fbm(N, 3, 23)
    alb = base * (0.93 + 0.1 * b[..., None])
    h = 0.04 * fbm(N, 50, 24, 2) + chips.astype(np.float32) * 0.02
    save_set("terrazzo", alb, h, 0.28 + 0.12 * b, 0.0, nstrength=1.0)


def _tiles(name, rows, base, grout, seed, rough_tile, rough_grout, var=0.06, specks=0.0):
    tile = N // rows
    ys, xs = np.mgrid[0:N, 0:N]
    gy = (ys % tile); gx = (xs % tile)
    g = 4 if rows >= 4 else 6
    mask_grout = ((gy < g) | (gx < g)).astype(np.float32)
    ty, tx = ys // tile, xs // tile
    r = _rng(seed)
    per = r.random((rows, rows)).astype(np.float32)
    v = per[ty, tx]
    n = fbm(N, 12, seed + 1, 3)
    alb = np.ones((N, N, 3), np.float32) * np.array(base, np.float32) * (1 + (v[..., None] - 0.5) * var * 2) * (0.96 + 0.06 * n[..., None])
    if specks > 0:
        sp = (fbm(N, 90, seed + 2, 2) > 0.62).astype(np.float32)
        alb = alb * (1 - specks * sp[..., None])
    alb = alb * (1 - mask_grout[..., None]) + np.array(grout, np.float32) * mask_grout[..., None] * (0.9 + 0.2 * n[..., None])
    h = -0.05 * blur(mask_grout, 1) + 0.01 * n
    rough = rough_tile * (1 - mask_grout) + rough_grout * mask_grout + 0.1 * n
    save_set(name, alb, h, rough, 0.0, nstrength=6.0)


def tile_white():
    _tiles("tile_white", 4, (0.93, 0.94, 0.95), (0.55, 0.56, 0.55), 31, 0.18, 0.85)


def tile_floor():
    _tiles("tile_floor", 2, (0.7, 0.72, 0.74), (0.35, 0.36, 0.36), 41, 0.42, 0.9, 0.08, 0.15)


def carpet():
    f = fbm(N, 120, 51, 2, 0.6); c = fbm(N, 6, 52, 3)
    alb = tint(0.6 * f + 0.4 * c, None, (0.82, 0.82, 0.82)) * (0.9 + 0.2 * value_noise(N, 200, 53)[..., None])
    save_set("carpet", alb, f * 0.6, 0.95, 0.0, nstrength=2.0)


def _wood(name, seed, base, seams, dark):
    planks = seams
    pw = N // planks
    xs = np.arange(N)[None, :].repeat(N, 0)
    pid = xs // pw
    r = _rng(seed)
    ptint = r.random(planks).astype(np.float32)[pid]
    pshift = r.random(planks).astype(np.float32)[pid] * 50
    ys = np.arange(N)[:, None].repeat(N, 1)
    grain = fbm(N, 3, seed + 1, 4, 0.55, stretch=(6, 1))          # long along y
    rings = np.sin((xs / N * 30 + grain * 9 + pshift) * 2 * np.pi * 0.5)
    rings = 0.5 + 0.5 * rings
    fine = fbm(N, 20, seed + 2, 3, 0.5, stretch=(10, 1))
    seam = ((xs % pw) < 3).astype(np.float32)
    col = np.array(base, np.float32) * (0.75 + 0.35 * rings[..., None] * 0.6 + 0.3 * fine[..., None]) * (0.9 + 0.2 * ptint[..., None])
    col = col * (1 - 0.6 * seam[..., None])
    h = 0.04 * rings + 0.03 * fine - 0.08 * seam
    save_set(name, col, h, 0.5 + 0.2 * fine + 0.2 * seam, 0.0, nstrength=2.0)


def wood_planks():
    _wood("wood_planks", 61, (0.8, 0.62, 0.42), 8, False)


def plywood():
    xs = np.arange(N)[None, :].repeat(N, 0)
    g = fbm(N, 4, 71, 4, 0.55, stretch=(1, 8))
    lines = 0.5 + 0.5 * np.sin((g * 6 + xs / N * 3) * 2 * np.pi)
    col = np.array([0.85, 0.7, 0.48], np.float32) * (0.78 + 0.3 * lines[..., None]) * (0.9 + 0.15 * fbm(N, 30, 72)[..., None])
    save_set("plywood", col, 0.05 * lines, 0.75, 0.0, nstrength=1.5)


def wall_paint():
    n1 = fbm(N, 90, 81, 2); n2 = fbm(N, 5, 82, 3)
    alb = np.ones((N, N, 3), np.float32) * (0.9 + 0.08 * n2[..., None]) * (0.97 + 0.05 * n1[..., None])
    save_set("wall_paint", alb, 0.5 * n1, 0.82 + 0.08 * n2, 0.0, nstrength=1.0)


def brick():
    rows, cols = 8, 4
    bh, bw = N // rows, N // cols
    ys, xs = np.mgrid[0:N, 0:N]
    row = ys // bh
    xo = (xs + (row % 2) * (bw // 2)) % N
    col_i = xo // bw
    gy = ys % bh; gx = xo % bw
    mortar = ((gy < 6) | (gx < 6)).astype(np.float32)
    r = _rng(91)
    per = r.random((rows, cols + 1)).astype(np.float32)
    v = per[row, col_i]
    n = fbm(N, 20, 92, 3)
    base = np.array([0.66, 0.34, 0.26], np.float32) * (0.75 + 0.5 * v[..., None]) * (0.85 + 0.3 * n[..., None])
    alb = base * (1 - mortar[..., None]) + np.array([0.6, 0.58, 0.54], np.float32) * mortar[..., None]
    h = -0.1 * blur(mortar, 1) + 0.03 * n
    save_set("brick", alb, h, 0.9, 0.0, nstrength=5.0)


def asphalt():
    fine = (fbm(N, 100, 101, 2) > 0.6).astype(np.float32); b = fbm(N, 6, 102, 3); f2 = fbm(N, 60, 103, 2)
    alb = tint(0.5 * b + 0.5 * f2, None, (0.25, 0.25, 0.26)) * (1 + 0.5 * fine[..., None] * 0.4)
    save_set("asphalt", alb, 0.4 * f2 + 0.3 * fine, 0.9, 0.0, nstrength=3.0)


def gravel():
    d, cid = voronoi(N, 40, 111)
    stone = 0.35 + 0.5 * cid
    shade = 1 - np.clip(d * 1.3 - 0.15, 0, 1) * 0.5
    col = np.stack([stone * 0.9, stone * 0.85, stone * 0.78], -1) * shade[..., None]
    h = (1 - np.clip(d * 1.6, 0, 1)) * 0.6
    save_set("gravel", col, h, 0.95, 0.0, nstrength=5.0)


def grass():
    a = fbm(N, 60, 121, 3, stretch=(1, 4)); b = fbm(N, 8, 122, 3); c = fbm(N, 150, 123, 2)
    col = np.stack([0.22 + 0.2 * a, 0.42 + 0.3 * a + 0.1 * b, 0.12 + 0.1 * a], -1) * (0.85 + 0.3 * c[..., None])
    save_set("grass", col, a * 0.5 + c * 0.3, 0.92, 0.0, nstrength=3.0)


def dirt():
    b = fbm(N, 5, 131); f = fbm(N, 70, 132, 3); pebbles = (fbm(N, 40, 133, 2) > 0.68).astype(np.float32)
    col = tint(0.5 * b + 0.5 * f, None, (0.38, 0.28, 0.2)) * (1 + 0.25 * pebbles[..., None])
    save_set("dirt", col, 0.4 * b + 0.4 * f + 0.2 * pebbles, 0.95, 0.0, nstrength=4.0)


def metal_brushed():
    s = fbm(N, 2, 141, 4, 0.7, stretch=(40, 1)); f = fbm(N, 6, 142, 3)
    col = np.ones((N, N, 3), np.float32) * (0.62 + 0.25 * s[..., None]) * (0.95 + 0.1 * f[..., None])
    save_set("metal_brushed", col, 0.06 * s, 0.34 + 0.25 * s, 1.0, nstrength=1.0)


def paint_metal():
    n = fbm(N, 80, 151, 2); b = fbm(N, 4, 152, 3)
    chips = (fbm(N, 25, 153, 2) > 0.72).astype(np.float32)
    col = np.ones((N, N, 3), np.float32) * (0.92 + 0.08 * b[..., None]) * (1 - 0.35 * chips[..., None])
    save_set("paint_metal", col, 0.3 * n - 0.15 * chips, 0.4 + 0.2 * b + 0.3 * chips, 0.0, nstrength=1.0)


def corrugated():
    xs = np.arange(N)[None, :].repeat(N, 0)
    h = 0.5 + 0.5 * np.sin(xs / N * 2 * np.pi * 12)
    n = fbm(N, 10, 161, 3)
    col = np.ones((N, N, 3), np.float32) * (0.7 + 0.2 * h[..., None] * 0.3) * (0.85 + 0.2 * n[..., None])
    save_set("corrugated", col, h * 0.4, 0.45 + 0.3 * n, 1.0, nstrength=3.0)


def diamond_plate():
    t = N // 8
    ys, xs = np.mgrid[0:N, 0:N]
    u = (xs % t) / t - 0.5; v = (ys % t) / t - 0.5
    cell = (xs // t + ys // t) % 2
    ang = np.where(cell == 0, 0.6, -0.6)
    ru = u * np.cos(ang) - v * np.sin(ang); rv = u * np.sin(ang) + v * np.cos(ang)
    bump = np.clip(1 - (np.abs(ru) / 0.32) ** 2 - (np.abs(rv) / 0.09) ** 2, 0, 1)
    n = fbm(N, 12, 171, 3)
    col = np.ones((N, N, 3), np.float32) * (0.55 + 0.2 * bump[..., None]) * (0.9 + 0.15 * n[..., None])
    save_set("diamond_plate", col, bump * 0.5, 0.45 + 0.25 * n, 1.0, nstrength=4.0)


def rubber():
    f = fbm(N, 100, 181, 2); dots = (np.sin(np.mgrid[0:N, 0:N][0] / N * 2 * np.pi * 32) * np.sin(np.mgrid[0:N, 0:N][1] / N * 2 * np.pi * 32) > 0.55).astype(np.float32)
    col = np.ones((N, N, 3), np.float32) * (0.7 + 0.3 * f[..., None])
    save_set("rubber", col, 0.2 * f + 0.25 * dots, 0.85, 0.0, nstrength=2.0)


def fabric():
    ys, xs = np.mgrid[0:N, 0:N]
    weave = 0.5 + 0.25 * np.sin(xs / N * 2 * np.pi * 96) + 0.25 * np.sin(ys / N * 2 * np.pi * 96)
    weave = weave * (0.5 + 0.5 * ((xs // 4 + ys // 4) % 2))
    n = fbm(N, 6, 191, 3); f = fbm(N, 140, 192, 2)
    col = np.ones((N, N, 3), np.float32) * (0.72 + 0.2 * weave[..., None]) * (0.92 + 0.12 * n[..., None]) * (0.95 + 0.1 * f[..., None])
    save_set("fabric", col, weave * 0.4 + 0.1 * f, 0.92, 0.0, nstrength=2.5)


def cardboard():
    ys, xs = np.mgrid[0:N, 0:N]
    flute = 0.5 + 0.5 * np.sin(xs / N * 2 * np.pi * 24)
    n = fbm(N, 9, 201, 4); f = fbm(N, 80, 202, 2, stretch=(4, 1))
    col = np.ones((N, N, 3), np.float32) * (0.6 + 0.2 * n[..., None]) * (0.9 + 0.15 * flute[..., None] * 0.4) * (0.94 + 0.1 * f[..., None])
    save_set("cardboard", col, flute * 0.18 + 0.1 * f, 0.9, 0.0, nstrength=2.0)


def ceiling_tile():
    t = N // 2
    ys, xs = np.mgrid[0:N, 0:N]
    gx = xs % t; gy = ys % t
    seam = ((gx < 4) | (gy < 4)).astype(np.float32)
    holes = (fbm(N, 55, 211, 2) > 0.68).astype(np.float32)
    n = fbm(N, 12, 212, 3)
    col = np.ones((N, N, 3), np.float32) * (0.85 + 0.1 * n[..., None]) * (1 - 0.35 * holes[..., None]) * (1 - 0.5 * seam[..., None])
    save_set("ceiling_tile", col, -0.1 * seam - 0.06 * holes + 0.03 * n, 0.92, 0.0, nstrength=4.0)


def fur():
    s = fbm(N, 40, 221, 3, 0.6, stretch=(1, 22)); f = fbm(N, 150, 222, 2, 0.6, stretch=(1, 10)); b = fbm(N, 5, 223, 3)
    tone = 0.62 + 0.3 * s + 0.2 * f
    col = np.stack([tone * 0.95, tone * 0.85, tone * 0.72], -1) * (0.88 + 0.2 * b[..., None])
    save_set("fur", col, s * 0.5 + f * 0.3, 0.85, 0.0, nstrength=3.0)


SETS = [concrete_smooth, concrete_rough, terrazzo, tile_white, tile_floor, carpet, wood_planks, plywood, wall_paint,
        brick, asphalt, gravel, grass, dirt, metal_brushed, paint_metal, corrugated, diamond_plate, rubber, fabric,
        cardboard, ceiling_tile, fur]

if __name__ == "__main__":
    only = set(sys.argv[1:])
    for fn in SETS:
        if only and fn.__name__ not in only:
            continue
        fn()
        print("texture set:", fn.__name__)
