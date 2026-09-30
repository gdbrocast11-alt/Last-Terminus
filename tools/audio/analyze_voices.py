#!/usr/bin/env python3
"""Report median F0 / duration / loudness per rendered voice file (QA for casting)."""
import glob, os, subprocess, sys, tempfile
import numpy as np, soundfile as sf

def f0_median(y, sr):
    frame, hop = int(0.04 * sr), int(0.01 * sr)
    vals = []
    for s in range(0, len(y) - frame, hop):
        x = y[s:s + frame] * np.hanning(frame)
        if np.sqrt(np.mean(x ** 2)) < 0.02:
            continue
        ac = np.correlate(x, x, "full")[frame - 1:]
        lo, hi = int(sr / 400), int(sr / 70)
        seg = ac[lo:hi]
        k = np.argmax(seg)
        if ac[0] > 0 and seg[k] / ac[0] > 0.35:
            vals.append(sr / (lo + k))
    return float(np.median(vals)) if vals else 0.0

root = os.path.join(os.path.dirname(__file__), "..", "..", "audio", "voice")
by_speaker = {}
for f in sorted(glob.glob(os.path.join(root, "*", "*.ogg"))):
    spk = os.path.basename(os.path.dirname(f))
    tmp = tempfile.mktemp(suffix=".wav")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", f, tmp], check=True)
    y, sr = sf.read(tmp, dtype="float32")
    os.unlink(tmp)
    act = y[np.abs(y) > 0.02]
    rms_db = 20 * np.log10(np.sqrt(np.mean(act ** 2)) + 1e-9) if len(act) else -99
    by_speaker.setdefault(spk, []).append((f0_median(y, sr), len(y) / sr, rms_db, np.max(np.abs(y))))
print(f"{'speaker':10s} {'n':>3s} {'F0 Hz':>7s} {'sec/line':>9s} {'rms dB':>7s} {'peak':>5s}")
for spk, rows in by_speaker.items():
    a = np.array(rows)
    print(f"{spk:10s} {len(rows):3d} {np.median(a[:,0]):7.0f} {a[:,1].mean():9.1f} {a[:,2].mean():7.1f} {a[:,3].max():5.2f}")
