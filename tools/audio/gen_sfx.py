#!/usr/bin/env python3
"""Procedural sound-effect library for Last Terminus (no third-party samples).

Everything is synthesised with numpy/scipy: modal synthesis for metal/glass,
filtered noise for surfaces and machines, and a source-filter model
(harmonic pulse train + vowel formants) for Pickles' vocalisations.
Output: audio/sfx/<name>_NN.ogg  (44.1 kHz mono Vorbis)
"""
import os, sys
import numpy as np
import soundfile as sf
from scipy import signal

SR = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "audio", "sfx")
rng = np.random.default_rng(1234)
made = {}


# ---------------------------------------------------------------- primitives
def T(d): return np.arange(int(d * SR)) / SR
def noise(d): return rng.uniform(-1, 1, int(d * SR)).astype(np.float32)
def pink(d):
    w = noise(d)
    b, a = [0.049922035, -0.095993537, 0.050612699, -0.004408786], [1, -2.494956002, 2.017265875, -0.522189400]
    return signal.lfilter(b, a, w).astype(np.float32) * 4.0
def brown(d):
    x = np.cumsum(noise(d)); x -= np.mean(x); return (x / (np.max(np.abs(x)) + 1e-9)).astype(np.float32)
def env_exp(n, decay): return np.exp(-np.arange(n) / (decay * SR)).astype(np.float32)
def adsr(n, a=0.005, d=0.05, s=0.6, r=0.05):
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    e = np.ones(n, np.float32) * s
    e[:a_n] = np.linspace(0, 1, max(a_n, 1))
    e[a_n:a_n + d_n] = np.linspace(1, s, max(d_n, 1))[: max(0, min(d_n, n - a_n))]
    if r_n: e[-r_n:] *= np.linspace(1, 0, r_n)
    return e
def lp(x, f, o=2): return signal.sosfilt(signal.butter(o, min(f, SR * 0.49) / (SR / 2), "low", output="sos"), x).astype(np.float32)
def hp(x, f, o=2): return signal.sosfilt(signal.butter(o, max(f, 20) / (SR / 2), "high", output="sos"), x).astype(np.float32)
def bp(x, f0, f1, o=2): return signal.sosfilt(signal.butter(o, [max(f0, 20) / (SR / 2), min(f1, SR * 0.49) / (SR / 2)], "band", output="sos"), x).astype(np.float32)
def norm(x, peak=0.85): return (x / (np.max(np.abs(x)) + 1e-9) * peak).astype(np.float32)
def pad(x, d):
    n = int(d * SR)
    return np.pad(x, (0, max(0, n - len(x))))[:n]
def mix(*xs):
    n = max(len(x) for x in xs)
    out = np.zeros(n, np.float32)
    for x in xs: out[:len(x)] += x
    return out
def at(x, t, y):
    out = np.zeros(max(len(x), int((t) * SR) + len(y)), np.float32); out[:len(x)] += x
    i = int(t * SR); out[i:i + len(y)] += y; return out
def modal(freqs, decays, amps, d, pitch=1.0):
    t = T(d); y = np.zeros(len(t), np.float32)
    for f, dc, a in zip(freqs, decays, amps):
        y += a * np.sin(2 * np.pi * f * pitch * t + rng.uniform(0, 6.28)) * np.exp(-t / dc)
    return y.astype(np.float32)
def loopify(x, xf=0.12):
    n = int(xf * SR)
    y = x.copy(); fade = np.linspace(0, 1, n)
    y[:n] = x[:n] * fade + x[-n:] * (1 - fade)
    return y[:-n]
def sweep(f0, f1, d, shape="exp"):
    t = T(d)
    f = f0 * (f1 / f0) ** (t / d) if shape == "exp" else np.linspace(f0, f1, len(t))
    return np.sin(2 * np.pi * np.cumsum(f) / SR).astype(np.float32)
def saw(f, d):
    t = T(d)
    f = np.broadcast_to(f, t.shape)
    ph = np.cumsum(f) / SR
    return (2 * (ph % 1.0) - 1).astype(np.float32)
def reverb(x, tail=0.5, wet=0.25, dens=8):
    ir = noise(tail) * np.exp(-T(tail) / (tail * 0.3))
    ir = lp(ir, 5000)
    y = signal.fftconvolve(x, ir * wet * 0.3)[: len(x) + int(tail * SR)]
    return mix(x, y.astype(np.float32))


def save(name, x, variants=1, loop=False):
    os.makedirs(OUT, exist_ok=True)
    x = np.asarray(x, np.float32)
    x = np.tanh(x * 1.1) if np.max(np.abs(x)) > 1 else x
    fn = os.path.join(OUT, name + ".ogg")
    sf.write(fn, x, SR, format="OGG", subtype="VORBIS")
    base = name.rsplit("_", 1)[0] if name[-2:].isdigit() and name[-3] == "_" else name
    made[base] = made.get(base, 0) + 1


def variants(name, fn, n=3, **kw):
    for i in range(n):
        save("%s_%02d" % (name, i + 1), fn(i, **kw))


# ---------------------------------------------------------------- UI
def ui():
    save("ui_click", norm(lp(noise(0.03), 4000) * env_exp(int(0.03 * SR), 0.006) + sweep(1800, 900, 0.03) * 0.4, 0.5))
    save("ui_hover", norm(sweep(900, 1300, 0.05) * env_exp(int(0.05 * SR), 0.02), 0.3))
    save("ui_back", norm(sweep(1000, 600, 0.08) * env_exp(int(0.08 * SR), 0.03), 0.4))
    n = modal([880, 1320, 1760, 2640], [0.5, 0.4, 0.3, 0.25], [1, 0.6, 0.5, 0.3], 0.9)
    save("achievement", norm(mix(n, at(np.zeros(1, np.float32), 0.12, modal([1175, 1760, 2350], [0.5, 0.4, 0.3], [1, 0.6, 0.4], 0.8))), 0.6))
    scr = pink(0.5)
    scr = scr * (np.abs(np.sin(T(0.5) * 2 * np.pi * 14)) ** 0.7) * adsr(len(scr), 0.02, 0.05, 0.8, 0.1)
    save("notebook_scribble", norm(bp(scr, 1500, 6000), 0.35))
    save("notebook_page", norm(bp(noise(0.25), 800, 5000) * np.sin(np.linspace(0, np.pi, int(0.25 * SR))) ** 2, 0.4))
    save("click_soft", norm(lp(noise(0.04), 2500) * env_exp(int(0.04 * SR), 0.01), 0.4))


# ---------------------------------------------------------------- player / footsteps
def footstep(i, kind):
    d = 0.22
    n = int(d * SR)
    if kind == "concrete":
        x = bp(noise(d), 500, 5000) * env_exp(n, 0.035) + lp(noise(d), 200) * env_exp(n, 0.06) * 0.8
    elif kind == "tile":
        x = bp(noise(d), 1500, 9000) * env_exp(n, 0.025) + modal([1900 + 200 * i, 3100], [0.03, 0.02], [0.2, 0.1], d)
    elif kind == "wood":
        x = lp(noise(d), 900) * env_exp(n, 0.05) + modal([180 + 20 * i, 310], [0.08, 0.05], [0.6, 0.3], d)
    elif kind == "carpet":
        x = lp(noise(d), 700) * env_exp(n, 0.06) * 0.7
    elif kind == "gravel":
        x = np.zeros(n, np.float32)
        for k in range(14):
            t0 = int(rng.uniform(0, 0.12) * SR)
            g = bp(noise(0.03), 1500, 8000) * env_exp(int(0.03 * SR), 0.006) * rng.uniform(0.3, 1)
            x[t0:t0 + len(g)] += g[: n - t0]
    elif kind == "grass":
        x = bp(noise(d), 1200, 6000) * np.sin(np.linspace(0, np.pi, n)) ** 1.5 * 0.5 + lp(noise(d), 300) * env_exp(n, 0.05) * 0.4
    else:  # metal
        x = bp(noise(d), 700, 6000) * env_exp(n, 0.03) + modal([420 + 30 * i, 910, 1380], [0.12, 0.09, 0.06], [0.4, 0.25, 0.15], d)
    return norm(x, 0.5)


def player():
    for k in ("concrete", "tile", "wood", "carpet", "gravel", "grass", "metal"):
        variants("step_" + k, footstep, 4, kind=k)
    save("mantle", norm(mix(lp(noise(0.35), 900) * adsr(int(0.35 * SR), 0.05, 0.1, 0.4, 0.15), sweep(300, 120, 0.2) * 0.5 * env_exp(int(0.2 * SR), 0.1)), 0.6))
    variants("thump", lambda i: norm(mix(sweep(140 - 20 * i, 45, 0.3) * env_exp(int(0.3 * SR), 0.09), lp(noise(0.15), 500) * env_exp(int(0.15 * SR), 0.03) * 0.7), 0.85), 3)
    save("pickup", norm(mix(bp(noise(0.12), 600, 3500) * adsr(int(0.12 * SR), 0.01, 0.05, 0.3, 0.05), sweep(500, 800, 0.08) * 0.2 * env_exp(int(0.08 * SR), 0.03)), 0.35))
    variants("drop", lambda i: norm(mix(lp(noise(0.2), 1500) * env_exp(int(0.2 * SR), 0.03), modal([200 + 40 * i, 480], [0.06, 0.04], [0.6, 0.3], 0.2)), 0.6), 3)
    save("throw", norm(bp(noise(0.35), 500, 4000) * np.sin(np.linspace(0, np.pi, int(0.35 * SR))) ** 2, 0.5))
    save("shove", norm(mix(lp(noise(0.25), 700) * env_exp(int(0.25 * SR), 0.06), sweep(180, 90, 0.2) * 0.6 * env_exp(int(0.2 * SR), 0.08)), 0.7))
    save("focus_on", norm(sweep(200, 900, 0.5) * np.sin(np.linspace(0, np.pi, int(0.5 * SR))) * 0.5 + bp(noise(0.5), 3000, 9000) * np.linspace(0, 1, int(0.5 * SR)) * 0.2, 0.5))
    # heartbeat loop 3 s @ 68 bpm
    hb = np.zeros(int(3.0 * SR), np.float32)
    for beat in np.arange(0, 3.0, 60 / 68.0):
        for off, amp in ((0.0, 1.0), (0.16, 0.7)):
            i = int((beat + off) * SR)
            b = sweep(70, 38, 0.18) * env_exp(int(0.18 * SR), 0.05) * amp
            hb[i:i + len(b)] += b[: len(hb) - i]
    save("heartbeat", norm(hb, 0.9))
    t = T(3.0)
    tin = (np.sin(2 * np.pi * 3150 * t) * 0.3 + np.sin(2 * np.pi * 4720 * t) * 0.12) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.7 * t))
    save("tinnitus", norm(loopify(tin.astype(np.float32)), 0.35))
    d = 1.4
    x = mix(sweep(90, 40, d) * env_exp(int(d * SR), 0.5) * 0.8, modal([160, 233, 340], [0.5, 0.4, 0.3], [0.5, 0.3, 0.2], d), lp(noise(d), 300) * env_exp(int(d * SR), 0.3) * 0.4)
    save("death_sting", norm(reverb(x, 0.6, 0.6), 0.8))


# ---------------------------------------------------------------- props / impacts
def props():
    variants("clink", lambda i: norm(modal([2900 + 300 * i, 4300, 5900], [0.09, 0.06, 0.04], [1, 0.6, 0.4], 0.35) + pad(hp(noise(0.02), 5000), 0.35) * 0.2, 0.55), 3)
    variants("ting", lambda i: norm(modal([3520 * (1 + 0.06 * i), 5300 * (1 + 0.06 * i), 7900], [0.3, 0.2, 0.12], [1, 0.4, 0.2], 0.7), 0.55), 3)
    def clang(i):
        f = 190 + 40 * i
        x = modal([f, f * 2.76, f * 5.4, f * 8.9, f * 11.3, f * 15.2], [0.6, 0.45, 0.3, 0.2, 0.14, 0.1], [1, 0.8, 0.6, 0.4, 0.3, 0.2], 1.2)
        x = mix(x, pad(bp(noise(0.05), 800, 8000) * env_exp(int(0.05 * SR), 0.01), 1.2) * 0.8)
        return norm(x, 0.8)
    variants("clang", clang, 3)
    def creak(i):
        d = 0.9 + 0.25 * i
        f = np.linspace(160 + 30 * i, 90 - 10 * i, int(d * SR)) * (1 + 0.06 * np.sin(2 * np.pi * (9 + 3 * i) * T(d)))
        x = saw(f, d)
        x = bp(x, 300, 2400, 2) * (0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 7 * T(d)))) * adsr(len(x), 0.1, 0.1, 0.8, 0.3)
        return norm(x + bp(noise(d), 1000, 3000) * 0.1, 0.55)
    variants("creak", creak, 3)
    variants("snap", lambda i: norm(mix(hp(noise(0.02), 1500) * env_exp(int(0.02 * SR), 0.004), modal([900 + 200 * i, 1900], [0.03, 0.02], [0.6, 0.3], 0.12)), 0.85), 3)
    def spark(i):
        d = 0.5
        x = np.zeros(int(d * SR), np.float32)
        for k in range(int(30 + 10 * i)):
            t0 = int(abs(rng.normal(0.08, 0.12)) * SR)
            if t0 > len(x) - 500: continue
            g = hp(noise(0.006), 3000) * rng.uniform(0.3, 1)
            x[t0:t0 + len(g)] += g
        return norm(mix(x, sweep(70, 60, d) * 0.15 * env_exp(len(x), 0.3), bp(noise(d), 2000, 9000) * env_exp(len(x), 0.08) * 0.3), 0.7)
    variants("spark", spark, 3)
    def thump_big(i):
        d = 0.6
        return norm(mix(sweep(90, 30, d) * env_exp(int(d * SR), 0.2), lp(noise(d), 300) * env_exp(int(d * SR), 0.12) * 0.7), 0.95)
    variants("boom_small", thump_big, 2)
    variants("squeak", lambda i: norm(sweep(1100 + 200 * i, 1900 - 100 * i, 0.25) * (1 + 0.3 * np.sin(2 * np.pi * 35 * T(0.25))) * adsr(int(0.25 * SR), 0.02, 0.05, 0.7, 0.1), 0.35), 3)
    save("whirr", norm(loopify(mix(saw(np.linspace(90, 130, int(2 * SR)) , 2.0) * 0.4, bp(noise(2.0), 400, 2500) * 0.15)), 0.4))
    hum = np.sin(2 * np.pi * 100 * T(2.0)) + 0.5 * np.sin(2 * np.pi * 200 * T(2.0)) + 0.3 * np.sin(2 * np.pi * 300 * T(2.0)) + 0.1 * noise(2.0)
    save("buzz", norm(loopify(hum.astype(np.float32)), 0.3))
    save("wet_splat", norm(mix(bp(noise(0.3), 300, 3500) * env_exp(int(0.3 * SR), 0.05), sweep(300, 90, 0.18) * 0.5 * env_exp(int(0.18 * SR), 0.06)), 0.7))
    save("wet_splat_02", norm(mix(bp(noise(0.4), 250, 3000) * env_exp(int(0.4 * SR), 0.09), sweep(220, 70, 0.25) * 0.5 * env_exp(int(0.25 * SR), 0.09)), 0.7))
    save("water_spray", norm(loopify(bp(noise(3.0), 2000, 11000) * 0.6), 0.4))
    def glass(i):
        d = 1.3
        x = np.zeros(int(d * SR), np.float32)
        for k in range(60):
            t0 = int(abs(rng.normal(0.05, 0.3)) * SR)
            if t0 > len(x) - 4000: continue
            g = modal([rng.uniform(3000, 9000), rng.uniform(5000, 11000)], [0.03, 0.02], [1, 0.5], 0.09)
            x[t0:t0 + len(g)] += g * rng.uniform(0.2, 1) * np.exp(-t0 / (0.5 * SR))
        return norm(mix(x, hp(noise(0.06), 2000) * env_exp(int(0.06 * SR), 0.01)), 0.8)
    variants("glass_break", glass, 2)
    def crash(i):
        d = 2.5
        x = mix(sweep(120, 35, d) * env_exp(int(d * SR), 0.5) * 0.9, lp(noise(d), 700) * env_exp(int(d * SR), 0.5), pad(bp(noise(1.0), 600, 7000) * env_exp(int(1.0 * SR), 0.2), d) * 0.7)
        for k in range(14):
            t0 = rng.uniform(0.05, 1.6)
            x = at(x, t0, modal([rng.uniform(200, 2200), rng.uniform(2000, 6000)], [0.2, 0.1], [0.5, 0.3], 0.4) * rng.uniform(0.3, 0.9))
        return norm(reverb(x, 0.8, 0.5), 0.95)
    variants("metal_crash", crash, 2)
    save("debris_rumble", norm(mix(lp(brown(4.0), 250) * 1.5, bp(noise(4.0), 300, 3000) * np.abs(np.sin(2 * np.pi * 5 * T(4.0))) * 0.15), 0.6))
    d = 2.2
    save("explosion", norm(reverb(mix(sweep(90, 28, d) * env_exp(int(d * SR), 0.45), lp(noise(d), 1400) * env_exp(int(d * SR), 0.3), bp(noise(d), 200, 6000) * env_exp(int(d * SR), 0.08) * 0.7), 1.2, 0.5), 1.0))
    d = 5.0
    big = mix(sweep(70, 22, d) * env_exp(int(d * SR), 1.2), lp(noise(d), 500) * env_exp(int(d * SR), 1.0), bp(noise(d), 200, 5000) * env_exp(int(d * SR), 0.6) * 0.5)
    for k in range(30):
        big = at(big, rng.uniform(0.3, 3.5), modal([rng.uniform(150, 1800)], [0.3], [0.6], 0.5) * rng.uniform(0.2, 0.8))
    save("big_boom", norm(reverb(big, 1.4, 0.7), 1.0))
    variants("whoosh", lambda i: norm(bp(noise(0.7), 300 + 200 * i, 4000) * np.sin(np.linspace(0, np.pi, int(0.7 * SR))) ** 2, 0.6), 2)
    save("door_open", norm(mix(modal([90, 210], [0.12, 0.08], [0.6, 0.3], 0.25), pad(bp(noise(0.3), 500, 2500) * env_exp(int(0.3 * SR), 0.1), 0.35) * 0.4), 0.6))
    save("door_close", norm(mix(sweep(130, 60, 0.3) * env_exp(int(0.3 * SR), 0.09), lp(noise(0.2), 1200) * env_exp(int(0.2 * SR), 0.04) * 0.8, modal([340, 620], [0.06, 0.04], [0.3, 0.2], 0.2)), 0.8))
    save("drawer", norm(bp(noise(0.4), 300, 2500) * adsr(int(0.4 * SR), 0.05, 0.2, 0.5, 0.1) * 0.6, 0.5))
    save("switch_click", norm(mix(modal([1500, 3200], [0.015, 0.01], [1, 0.5], 0.06), hp(noise(0.01), 3000)), 0.6))
    save("plug_pull", norm(mix(bp(noise(0.12), 400, 3000) * env_exp(int(0.12 * SR), 0.03), modal([700, 1800], [0.04, 0.03], [0.5, 0.3], 0.15)), 0.6))
    save("plug_in", norm(mix(bp(noise(0.08), 500, 3000) * env_exp(int(0.08 * SR), 0.02), modal([1100, 2400], [0.03, 0.02], [0.5, 0.3], 0.12)), 0.55))
    _v = mix(saw(np.linspace(180, 140, int(1.2 * SR)), 1.2) * 0.2, bp(noise(1.2), 600, 2500) * 0.3)
    save("valve_turn", norm(_v * adsr(len(_v), 0.1, 0.2, 0.8, 0.2), 0.45))
    save("cart_rattle", norm(loopify(bp(noise(3.0), 200, 2500) * (0.5 + 0.5 * np.abs(np.sin(2 * np.pi * 11 * T(3.0)))) + lp(brown(3.0), 200) * 0.6), 0.5))
    save("roll_loop", norm(loopify(mix(lp(brown(3.0), 400), bp(noise(3.0), 800, 3500) * (0.4 + 0.6 * np.abs(np.sin(2 * np.pi * 6 * T(3.0)))) * 0.25)), 0.5))
    save("roll_light", norm(loopify(mix(lp(brown(3.0), 700) * 0.6, bp(noise(3.0), 1500, 6000) * (0.3 + 0.7 * np.abs(np.sin(2 * np.pi * 9 * T(3.0)))) * 0.3)), 0.4))
    save("escalator_hum", norm(loopify(mix(np.sin(2 * np.pi * 62 * T(3.0)) * 0.4, lp(pink(3.0), 400) * 0.8, bp(noise(3.0), 500, 2000) * (0.5 + 0.5 * np.sin(2 * np.pi * 2.2 * T(3.0))) * 0.12)), 0.4))
    d = 1.6
    save("escalator_jam", norm(mix(bp(noise(d), 200, 3500) * np.abs(np.sin(2 * np.pi * np.linspace(30, 4, int(d * SR)).cumsum() / SR)) * env_exp(int(d * SR), 0.7), sweep(160, 40, d) * 0.6 * env_exp(int(d * SR), 0.5), modal([260, 700], [0.4, 0.3], [0.3, 0.2], d)), 0.9))
    al = (np.sign(np.sin(2 * np.pi * np.cumsum(np.where(T(2.0) % 1.0 < 0.5, 900, 700)) / SR)) * 0.5).astype(np.float32)
    save("alarm_loop", norm(loopify(lp(al, 4000)), 0.5))
    save("pa_chime", norm(modal([660, 880, 990], [0.5, 0.5, 0.6], [1, 0.7, 0.9], 1.4) * 0.6, 0.5))
    d = 3.0
    save("train_horn", norm(mix(saw(np.full(int(d * SR), 311.0), d) * 0.4, saw(np.full(int(d * SR), 391.0), d) * 0.4, saw(np.full(int(d * SR), 466.0), d) * 0.3) * adsr(int(d * SR), 0.05, 0.1, 0.9, 0.5), 0.6))
    save("train_pass", norm(mix(lp(brown(6.0), 500) * np.sin(np.linspace(0, np.pi, int(6 * SR))) ** 2, bp(noise(6.0), 300, 4000) * (0.4 + 0.6 * np.abs(np.sin(2 * np.pi * 7 * T(6.0)))) * np.sin(np.linspace(0, np.pi, int(6 * SR))) ** 2 * 0.4), 0.6))
    save("sprinkler_burst", norm(mix(bp(noise(3.0), 1500, 10000) * adsr(int(3.0 * SR), 0.08, 0.2, 0.85, 0.5), lp(noise(3.0), 400) * 0.3), 0.6))
    save("zap", norm(mix(hp(noise(0.4), 1500) * (np.random.default_rng(3).uniform(size=int(0.4 * SR)) > 0.85), sweep(1600, 90, 0.4) * env_exp(int(0.4 * SR), 0.15) * 0.5), 0.8))
    fl = np.zeros(int(1.2 * SR), np.float32)
    for k in range(8):
        i = int(rng.uniform(0, 1.0) * SR)
        g = mix(np.sin(2 * np.pi * 120 * T(0.06)) * 0.5, hp(noise(0.06), 2000) * 0.5) * env_exp(int(0.06 * SR), 0.02)
        fl[i:i + len(g)] += g
    save("fluorescent_flicker", norm(fl, 0.4))
    variants("nail_gun", lambda i: norm(mix(hp(noise(0.05), 1500) * env_exp(int(0.05 * SR), 0.008), sweep(240, 90, 0.08) * 0.7 * env_exp(int(0.08 * SR), 0.02), modal([2600, 4200], [0.03, 0.02], [0.3, 0.2], 0.1)), 0.9), 2)
    save("saw_loop", norm(loopify(mix(saw(np.full(int(2 * SR), 210.0) * (1 + 0.01 * np.sin(2 * np.pi * 3 * T(2.0))), 2.0) * 0.4, bp(noise(2.0), 2000, 9000) * 0.4)), 0.5))
    save("drill_burst", norm(mix(saw(np.linspace(300, 620, int(0.9 * SR)), 0.9) * 0.4, bp(noise(0.9), 800, 5000) * 0.3) * adsr(int(0.9 * SR), 0.05, 0.1, 0.9, 0.2), 0.5))
    save("fan_wobble", norm(loopify(mix(lp(pink(2.5), 800) * (0.6 + 0.4 * np.sin(2 * np.pi * 3.3 * T(2.5))), bp(noise(2.5), 200, 900) * (0.4 + 0.6 * np.sin(2 * np.pi * 3.3 * T(2.5) + 1)) * 0.3)), 0.4))
    save("blender_loop", norm(loopify(mix(saw(np.full(int(2 * SR), 260.0), 2.0) * 0.3, bp(noise(2.0), 1000, 5000) * 0.6, np.sin(2 * np.pi * 120 * T(2.0)) * 0.2)), 0.55))
    save("engine_idle", norm(loopify(mix(np.sin(2 * np.pi * 42 * T(3.0)) * 0.5, saw(np.full(int(3 * SR), 84.0) * (1 + 0.02 * np.sin(2 * np.pi * 21 * T(3.0))), 3.0) * 0.3, lp(pink(3.0), 350) * 0.5)), 0.5))
    save("engine_rev", norm(mix(saw(np.linspace(80, 240, int(1.5 * SR)), 1.5) * 0.5, lp(noise(1.5), 600) * 0.4) * adsr(int(1.5 * SR), 0.1, 0.2, 0.9, 0.3), 0.6))
    d = 1.8
    horn = mix(saw(np.full(int(d * SR), 415.0), d) * 0.5, saw(np.full(int(d * SR), 523.0), d) * 0.5, saw(np.full(int(d * SR), 622.0), d) * 0.3)
    save("bus_horn", norm(lp(horn, 3500) * adsr(int(d * SR), 0.02, 0.05, 0.95, 0.15), 0.85))
    d = 3.5
    bc = mix(sweep(100, 25, d) * env_exp(int(d * SR), 0.7), lp(noise(d), 800) * env_exp(int(d * SR), 0.5), bp(noise(d), 400, 6000) * env_exp(int(d * SR), 0.3) * 0.6)
    for k in range(24):
        bc = at(bc, rng.uniform(0.1, 2.6), modal([rng.uniform(150, 2500), rng.uniform(2500, 7000)], [0.25, 0.1], [0.6, 0.3], 0.5) * rng.uniform(0.3, 0.9))
    save("bus_crash", norm(reverb(bc, 1.2, 0.6), 1.0))
    save("forklift_beep", norm(loopify(np.concatenate([np.sin(2 * np.pi * 1200 * T(0.25)) * adsr(int(0.25 * SR), 0.005, 0.01, 1, 0.01), np.zeros(int(0.5 * SR))]).astype(np.float32), 0.02), 0.4))
    save("paint_shaker", norm(loopify(mix(bp(noise(2.0), 100, 900) * (0.5 + 0.5 * np.sin(2 * np.pi * 15 * T(2.0))), lp(pink(2.0), 250) * 0.6, modal([180, 320], [1.5, 1.2], [0.2, 0.15], 2.0))), 0.5))
    save("hose_hiss", norm(loopify(bp(noise(2.0), 3000, 12000) * 0.6), 0.35))
    save("fire_crackle", norm(loopify(mix(lp(brown(3.0), 500) * 0.6, np.array([0.0] * int(3 * SR), np.float32) + hp(noise(3.0), 2500) * (np.random.default_rng(9).uniform(size=int(3 * SR)) > 0.996) * 2)), 0.5))
    variants("coin_drop", lambda i: norm(modal([3300 + 400 * i, 5100, 7200], [0.35, 0.25, 0.15], [1, 0.6, 0.3], 0.9), 0.5), 2)
    save("coin_spin", norm(np.sin(2 * np.pi * np.cumsum(np.linspace(1800, 2600, int(1.4 * SR))) / SR) * np.abs(np.sin(2 * np.pi * np.cumsum(np.linspace(6, 40, int(1.4 * SR))) / SR)) * env_exp(int(1.4 * SR), 0.9) * 0.6, 0.4))
    save("shoe_thud", norm(mix(sweep(110, 60, 0.15) * env_exp(int(0.15 * SR), 0.05), lp(noise(0.1), 900) * env_exp(int(0.1 * SR), 0.03)), 0.7))
    save("phone_buzz", norm(loopify(np.tile(np.sin(2 * np.pi * 150 * T(0.15)) * adsr(int(0.15 * SR), 0.01, 0.01, 1, 0.02), 4).astype(np.float32).repeat(1)) , 0.5))
    save("message_ping", norm(modal([1568, 2349], [0.2, 0.15], [1, 0.5], 0.4), 0.5))
    save("tv_static", norm(loopify(bp(noise(2.0), 1000, 9000) * 0.5), 0.3))
    save("siren_far", norm(loopify(lp(np.sin(2 * np.pi * np.cumsum(500 + 250 * np.sin(2 * np.pi * 0.5 * T(4.0))) / SR).astype(np.float32), 2500) * 0.4, 0.15), 0.25))
    save("mattress_bounce", norm(mix(lp(noise(0.5), 400) * env_exp(int(0.5 * SR), 0.15), sweep(200, 70, 0.4) * env_exp(int(0.4 * SR), 0.15) * 0.6), 0.7))
    save("airbag_hiss", norm(mix(bp(noise(1.4), 1200, 7000) * env_exp(int(1.4 * SR), 0.7), lp(noise(0.3), 300) * env_exp(int(0.3 * SR), 0.05) * 1.4), 0.6))
    save("sigh_comic", norm(sweep(500, 180, 0.9) * adsr(int(0.9 * SR), 0.1, 0.2, 0.5, 0.4) * 0.5 + bp(noise(0.9), 500, 2500) * 0.1, 0.4))
    save("comic_boing", norm(np.sin(2 * np.pi * np.cumsum(300 + 400 * np.abs(np.sin(np.pi * T(0.5) * 2.2)) * np.exp(-T(0.5) * 4)) / SR) * env_exp(int(0.5 * SR), 0.25), 0.6))
    save("comic_slide_whistle", norm(sweep(300, 1800, 0.7) * adsr(int(0.7 * SR), 0.02, 0.05, 0.9, 0.1) * 0.5, 0.5))
    save("comic_slide_down", norm(sweep(1600, 200, 0.9) * adsr(int(0.9 * SR), 0.02, 0.05, 0.9, 0.1) * 0.5, 0.5))
    save("scratch_metal", norm(bp(noise(0.5), 1500, 8000) * (0.5 + 0.5 * np.sin(2 * np.pi * 30 * T(0.5))) * adsr(int(0.5 * SR), 0.05, 0.1, 0.8, 0.2), 0.4))
    save("cloth_rustle", norm(bp(noise(0.5), 2000, 9000) * np.abs(np.sin(2 * np.pi * 12 * T(0.5))) * adsr(int(0.5 * SR), 0.05, 0.1, 0.7, 0.2), 0.3))
    save("bell_shop", norm(modal([1568, 2093, 3136], [0.6, 0.4, 0.3], [1, 0.6, 0.3], 1.5), 0.5))
    save("cash_register", norm(mix(modal([2000, 3400], [0.1, 0.08], [1, 0.5], 0.3), pad(modal([1700, 2900, 5000], [0.5, 0.3, 0.2], [1, 0.6, 0.4], 0.9), 0.9) * 0.9), 0.6))
    save("bounce_plastic", norm(mix(modal([500, 900, 1400], [0.08, 0.05, 0.03], [1, 0.5, 0.3], 0.2), lp(noise(0.05), 3000) * env_exp(int(0.05 * SR), 0.01) * 0.3), 0.6))
    save("sizzle", norm(loopify(mix(bp(noise(2.5), 3000, 12000) * (0.4 + 0.6 * (np.random.default_rng(8).uniform(size=int(2.5 * SR)) > 0.6)) * 0.5, lp(pink(2.5), 800) * 0.3)), 0.35))
    save("gurgle", norm(loopify(bp(noise(2.0), 150, 700) * (0.5 + 0.5 * np.sin(2 * np.pi * 5 * T(2.0) + np.sin(2 * np.pi * 2 * T(2.0)) * 3)) * 0.8), 0.4))
    save("steam_hiss", norm(loopify(bp(noise(3.0), 2500, 11000) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.4 * T(3.0)))), 0.4))
    save("gong", norm(reverb(modal([98, 156, 250, 391, 588, 825], [4, 3.2, 2.5, 2, 1.5, 1.2], [1, 0.8, 0.7, 0.5, 0.4, 0.3], 5.0), 1.5, 0.5), 0.7))
    save("singing_bowl", norm(modal([430, 1180, 2280], [4, 3, 2], [1, 0.4, 0.15], 5.0), 0.5))
    save("weights_clank", norm(mix(modal([320, 890, 1700], [0.25, 0.15, 0.1], [1, 0.6, 0.3], 0.6), pad(hp(noise(0.02), 2500), 0.6) * 0.5), 0.8))
    save("treadmill_belt", norm(loopify(mix(lp(pink(2.0), 500) * 0.7, bp(noise(2.0), 300, 1500) * (0.5 + 0.5 * np.sin(2 * np.pi * 4 * T(2.0))) * 0.4, np.sin(2 * np.pi * 70 * T(2.0)) * 0.2)), 0.35))


# ---------------------------------------------------------------- Pickles
def formant(x, formants):
    y = np.zeros_like(x)
    for f, bw, g in formants:
        y += g * bp(x, max(60, f - bw), f + bw, 2)
    return y


def voc(f0_curve, dur, formants, breath=0.1, jitter=0.02, env=None):
    n = int(dur * SR)
    f0 = np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(f0_curve)), f0_curve) * (1 + jitter * np.random.default_rng(int(dur * 1000)).normal(size=n).cumsum() / 50)
    ph = np.cumsum(f0) / SR
    src = np.zeros(n, np.float32)
    for h in range(1, 40):
        src += np.sin(2 * np.pi * h * ph).astype(np.float32) / h ** 0.9
    src += noise(dur) * breath
    y = formant(src, formants)
    e = env if env is not None else adsr(n, 0.008, 0.06, 0.55, 0.06)
    return norm(y * e, 0.7)


def pickles():
    vow_aw = [(700, 150, 1.0), (1150, 200, 0.7), (2600, 300, 0.35)]
    vow_ah = [(850, 160, 1.0), (1300, 220, 0.6), (2500, 300, 0.3)]
    for i in range(5):
        f = 480 + 60 * i
        save("pk_bark_%02d" % (i + 1), voc([f * 1.25, f, f * 0.7], 0.16 + 0.03 * i, vow_ah, 0.18, 0.03, adsr(int((0.16 + 0.03 * i) * SR), 0.004, 0.05, 0.4, 0.05)))
    for i in range(3):
        f = 260 + 30 * i
        save("pk_woof_%02d" % (i + 1), voc([f * 1.2, f, f * 0.75], 0.24, vow_aw, 0.12, 0.02, adsr(int(0.24 * SR), 0.01, 0.07, 0.5, 0.08)))
    for i in range(3):
        d = 0.8 + 0.2 * i
        f0 = [620, 900, 1100, 880, 760] if i != 1 else [900, 1200, 1000, 800]
        save("pk_whine_%02d" % (i + 1), voc(f0, d, [(1000, 200, 1.0), (2200, 300, 0.5), (3200, 300, 0.2)], 0.05, 0.04, adsr(int(d * SR), 0.1, 0.1, 0.8, 0.2) * (1 + 0.25 * np.sin(2 * np.pi * 6 * T(d)))))
    t = 2.0
    pant = np.zeros(int(t * SR), np.float32)
    for k in range(6):
        i = int((k / 3.0) * SR)
        g = bp(noise(0.18), 800, 4500) * np.sin(np.linspace(0, np.pi, int(0.18 * SR))) ** 1.5
        pant[i:i + len(g)] += g[: len(pant) - i] * 0.7
    save("pk_pant", norm(loopify(pant), 0.3))
    for i in range(3):
        s = np.zeros(int(0.6 * SR), np.float32)
        for k in range(3):
            g = bp(noise(0.09), 1200, 7000) * np.sin(np.linspace(0, np.pi, int(0.09 * SR)))
            j = int((k * 0.16 + 0.02 * i) * SR)
            s[j:j + len(g)] += g
        save("pk_sniff_%02d" % (i + 1), norm(s, 0.4))
    for i in range(3):
        j = mix(*[at(np.zeros(1, np.float32), rng.uniform(0, 0.12), modal([rng.uniform(3200, 5400), rng.uniform(5400, 8000)], [0.05, 0.03], [1, 0.4], 0.14)) for _ in range(4)])
        save("pk_jingle_%02d" % (i + 1), norm(j, 0.35))
    d = 1.2
    save("pk_shake", norm(mix(bp(noise(d), 500, 5000) * (0.5 + 0.5 * np.sin(2 * np.pi * 14 * T(d))) * adsr(int(d * SR), 0.03, 0.1, 0.8, 0.3), mix(*[at(np.zeros(1, np.float32), rng.uniform(0, 1.0), modal([rng.uniform(3200, 5400)], [0.05], [1], 0.1)) for _ in range(9)])[: int(d * SR)] * 0.5), 0.55))
    save("pk_lick", norm(bp(noise(0.5), 400, 3000) * np.abs(np.sin(2 * np.pi * 6 * T(0.5))) * adsr(int(0.5 * SR), 0.02, 0.1, 0.7, 0.1) * 0.6, 0.4))
    save("pk_yawn", voc([500, 800, 700, 350], 1.1, [(900, 200, 1.0), (1800, 300, 0.4)], 0.2, 0.05, adsr(int(1.1 * SR), 0.2, 0.2, 0.8, 0.3)))
    save("pk_grumble", voc([95, 88, 100, 85], 0.9, [(400, 100, 1.0), (900, 150, 0.5)], 0.25, 0.08, adsr(int(0.9 * SR), 0.1, 0.1, 0.8, 0.2)))
    s = np.zeros(int(1.2 * SR), np.float32)
    for k in range(6):
        g = mix(bp(noise(0.05), 600, 4000) * env_exp(int(0.05 * SR), 0.01), lp(noise(0.04), 300) * 0.4)
        j = int((k * 0.19) * SR)
        s[j:j + len(g)] += g
    save("pk_eat", norm(s, 0.5))
    for i in range(3):
        save("pk_paw_%02d" % (i + 1), norm(lp(noise(0.06), 1800) * env_exp(int(0.06 * SR), 0.015) + modal([300 + 30 * i], [0.03], [0.3], 0.06), 0.3))
    save("pk_sneeze", norm(mix(bp(noise(0.15), 1500, 7000) * env_exp(int(0.15 * SR), 0.03), voc([900, 700], 0.15, [(1500, 300, 1)], 0.3)), 0.5))


# ---------------------------------------------------------------- ambiences (30 s-ish loops)
def ambiences():
    d = 8.0
    n = int(d * SR)
    save("amb_station", norm(loopify(mix(lp(pink(d), 600) * 0.7, bp(noise(d), 300, 1800) * (0.3 + 0.2 * np.sin(2 * np.pi * 0.3 * T(d))) * 0.3, np.sin(2 * np.pi * 60 * T(d)) * 0.05), 0.5), 0.35))
    save("amb_apartment", norm(loopify(mix(lp(brown(d), 200) * 0.9, lp(pink(d), 400) * 0.25, np.sin(2 * np.pi * 50 * T(d)) * 0.06), 0.5), 0.3))
    save("amb_store", norm(loopify(mix(lp(pink(d), 500) * 0.5, np.sin(2 * np.pi * 120 * T(d)) * 0.05 + np.sin(2 * np.pi * 240 * T(d)) * 0.02, bp(noise(d), 1000, 4000) * 0.04), 0.5), 0.3))
    save("amb_wellness", norm(loopify(mix(lp(pink(d), 400) * 0.35, np.sin(2 * np.pi * 174 * T(d)) * 0.08 * (0.6 + 0.4 * np.sin(2 * np.pi * 0.2 * T(d))), np.sin(2 * np.pi * 261 * T(d)) * 0.05), 0.5), 0.3))
    save("amb_yard", norm(loopify(mix(lp(pink(d), 800) * 0.5, bp(noise(d), 2000, 6000) * (0.2 + 0.2 * np.sin(2 * np.pi * 0.13 * T(d))) * 0.1, lp(brown(d), 150) * 0.5), 0.5), 0.35))
    save("amb_street", norm(loopify(mix(lp(pink(d), 700) * 0.4, lp(brown(d), 200) * 0.6, bp(noise(d), 3000, 8000) * 0.02), 0.5), 0.3))
    save("amb_crowd", norm(loopify(mix(*[bp(pink(d), 250 + 40 * k, 1800 + 200 * k) * (0.4 + 0.3 * np.sin(2 * np.pi * (0.2 + 0.07 * k) * T(d) + k)) for k in range(5)]), 0.5), 0.3))
    save("amb_wind", norm(loopify(bp(pink(d), 150, 1200) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.15 * T(d))), 0.5), 0.3))
    save("amb_silence", np.zeros(int(2 * SR), np.float32))


if __name__ == "__main__":
    only = set(sys.argv[1:])
    groups = {"ui": ui, "player": player, "props": props, "pickles": pickles, "ambiences": ambiences}
    for k, fn in groups.items():
        if not only or k in only:
            fn()
            print("sfx group", k, "done")
    print("total sfx groups:", len(made), "names")
