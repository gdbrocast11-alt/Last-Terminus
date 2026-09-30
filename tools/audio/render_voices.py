#!/usr/bin/env python3
"""Parse dialogue/src/*.txt and synthesise every spoken line with Kokoro.

Source line format (one per line, '|' separated, '#' comments):
    id | speaker | style | text [| flags]

Inline markup inside text:
    {p=0.6}   explicit pause in seconds (removed from subtitles)
    flags: flat (always 2D), phone, pa, tv, radio (extra filtering)

Outputs:
    audio/voice/<speaker>/<id>.ogg
    dialogue/lines.json   (id -> {s, t, d, env, style, flat})
A cache keyed by a hash of the render parameters makes re-runs incremental.
"""
import glob, hashlib, json, os, re, subprocess, sys, tempfile
import numpy as np
import soundfile as sf

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.dirname(__file__))
from voice_profiles import PROFILES, STYLES  # noqa: E402

MODEL = "/opt/tools/tts/kokoro-v1.0.onnx"
VOICES = "/opt/tools/tts/voices-v1.0.bin"
SRC_DIR = os.path.join(ROOT, "dialogue", "src")
OUT_JSON = os.path.join(ROOT, "dialogue", "lines.json")
CACHE_JSON = os.path.join(ROOT, "tools", "audio", "voice_cache.json")
VOICE_DIR = os.path.join(ROOT, "audio", "voice")
SR = 24000
TARGET_RMS_DB = -21.0
PAUSE_RE = re.compile(r"\{p=([0-9.]+)\}")


def parse_sources():
    lines = {}
    order = []
    for path in sorted(glob.glob(os.path.join(SRC_DIR, "*.txt"))):
        for n, raw in enumerate(open(path, encoding="utf-8"), 1):
            raw = raw.strip()
            if not raw or raw.startswith("#"):
                continue
            parts = [p.strip() for p in raw.split("|")]
            if len(parts) < 4:
                raise SystemExit(f"{path}:{n}: expected 'id | speaker | style | text'")
            lid, spk, style, text = parts[:4]
            flags = parts[4].split() if len(parts) > 4 else []
            if lid in lines:
                raise SystemExit(f"{path}:{n}: duplicate id {lid}")
            if spk not in PROFILES:
                raise SystemExit(f"{path}:{n}: unknown speaker {spk}")
            if style not in STYLES:
                raise SystemExit(f"{path}:{n}: unknown style {style}")
            lines[lid] = {"s": spk, "style": style, "raw": text, "flags": flags, "file": os.path.basename(path)}
            order.append(lid)
    return lines, order


def subtitle_text(raw):
    return re.sub(r"\s+", " ", PAUSE_RE.sub("", raw)).strip()


def blend_style(kokoro, blend):
    acc = None
    for name, w in blend:
        v = kokoro.get_voice_style(name)
        acc = v * w if acc is None else acc + v * w
    return acc


def sox_process(wav_in, wav_out, speaker, style, flags):
    prof = PROFILES[speaker]
    sp, pitch, gain = STYLES[style]
    semis = prof.get("pitch", 0.0) + pitch
    args = ["sox", wav_in, wav_out]
    if abs(semis) > 0.01:
        args += ["pitch", str(int(semis * 100))]
    eq = prof.get("eq", "")
    for f in flags:
        if f in ("phone", "pa", "tv", "radio"):
            eq = f
    if eq == "old":
        args += ["equalizer", "3000", "1.2q", "-4", "lowpass", "6500", "overdrive", "1", "0"]
    elif eq == "warm":
        args += ["equalizer", "180", "1q", "3", "treble", "-2"]
    elif eq == "phone":
        args += ["highpass", "350", "lowpass", "3200", "gain", "-2", "overdrive", "3", "0"]
    elif eq == "radio":
        args += ["highpass", "300", "lowpass", "3800", "overdrive", "6", "0"]
    elif eq == "pa":
        args += ["highpass", "320", "lowpass", "4200", "overdrive", "4", "0", "reverb", "35", "50", "70", "100", "40"]
    elif eq == "tv":
        args += ["highpass", "180", "lowpass", "7000", "equalizer", "2500", "1q", "3"]
    subprocess.run(args, check=True, capture_output=True)


def synth_line(kokoro, spec, style_cache):
    prof = PROFILES[spec["s"]]
    sp_mul, _, gain_db = STYLES[spec["style"]]
    speed = prof["speed"] * sp_mul
    if spec["s"] not in style_cache:
        style_cache[spec["s"]] = blend_style(kokoro, prof["blend"])
    voice = style_cache[spec["s"]]
    chunks = []
    segs = PAUSE_RE.split(spec["raw"])
    # segs alternates text, pause, text, pause, ...
    for i, seg in enumerate(segs):
        if i % 2 == 1:
            chunks.append(np.zeros(int(float(seg) * SR), dtype=np.float32))
            continue
        seg = seg.strip()
        if not seg:
            continue
        audio, sr = kokoro.create(seg, voice=voice, speed=min(max(speed, 0.5), 2.0), lang=prof["lang"])
        assert sr == SR
        chunks.append(audio.astype(np.float32))
        chunks.append(np.zeros(int(0.03 * SR), dtype=np.float32))
    audio = np.concatenate(chunks) if chunks else np.zeros(SR // 2, dtype=np.float32)
    return audio, gain_db


def finalize(audio, gain_db, spec, out_ogg):
    tmp_in = tempfile.mktemp(suffix=".wav")
    tmp_out = tempfile.mktemp(suffix=".wav")
    pad = np.zeros(int(0.06 * SR), dtype=np.float32)
    sf.write(tmp_in, np.concatenate([pad, audio, pad * 2]), SR)
    sox_process(tmp_in, tmp_out, spec["s"], spec["style"], spec["flags"])
    y, sr = sf.read(tmp_out, dtype="float32")
    if y.ndim > 1:
        y = y.mean(axis=1)
    os.unlink(tmp_in)
    os.unlink(tmp_out)
    # normalise RMS over active samples, then apply per-style gain and a soft peak limit
    act = y[np.abs(y) > 0.02]
    rms = np.sqrt(np.mean(act ** 2)) if len(act) else 1e-4
    y = y * (10 ** (TARGET_RMS_DB / 20) / max(rms, 1e-6)) * (10 ** (gain_db / 20))
    peak = np.max(np.abs(y)) if len(y) else 1.0
    if peak > 0.89:
        y = np.tanh(y / peak * 1.2) / np.tanh(1.2) * 0.89
    # fade in/out to avoid clicks
    n = int(0.01 * sr)
    y[:n] *= np.linspace(0, 1, n)
    y[-n:] *= np.linspace(1, 0, n)
    os.makedirs(os.path.dirname(out_ogg), exist_ok=True)
    tmp_wav = tempfile.mktemp(suffix=".wav")
    sf.write(tmp_wav, y, sr, subtype="PCM_16")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp_wav, "-c:a", "libvorbis", "-q:a", "4", out_ogg], check=True)
    os.unlink(tmp_wav)
    return y, sr


def envelope(y, sr, rate=25):
    win = int(sr / rate)
    n = len(y) // win
    if n == 0:
        return "0"
    rms = np.array([np.sqrt(np.mean(y[i * win:(i + 1) * win] ** 2)) for i in range(n)])
    ref = np.percentile(rms, 90) + 1e-6
    lv = np.clip(rms / ref, 0, 1) ** 0.8
    # light smoothing so the mouth does not flutter
    sm = lv.copy()
    for i in range(1, n - 1):
        sm[i] = 0.25 * lv[i - 1] + 0.5 * lv[i] + 0.25 * lv[i + 1]
    q = np.round(sm * 9).astype(int)
    return "".join(str(int(v)) for v in q)


def line_hash(spec):
    key = json.dumps([spec["s"], spec["style"], spec["raw"], spec["flags"], PROFILES[spec["s"]]], sort_keys=True, default=str)
    return hashlib.sha1(key.encode()).hexdigest()[:16]


def main():
    only = set(sys.argv[1:])
    specs, order = parse_sources()
    cache = json.load(open(CACHE_JSON)) if os.path.exists(CACHE_JSON) else {}
    result = json.load(open(OUT_JSON)) if os.path.exists(OUT_JSON) else {}
    todo = []
    for lid in order:
        spec = specs[lid]
        out = os.path.join(VOICE_DIR, spec["s"], lid + ".ogg")
        stale = cache.get(lid, {}).get("hash") != line_hash(spec) or not os.path.exists(out) or lid not in result
        if only and not any(lid.startswith(o) or spec["file"].startswith(o) for o in only):
            stale = False
        if stale:
            todo.append(lid)
    print(f"{len(order)} lines, {len(todo)} to render")
    if todo:
        from kokoro_onnx import Kokoro
        kokoro = Kokoro(MODEL, VOICES)
        style_cache = {}
        for i, lid in enumerate(todo, 1):
            spec = specs[lid]
            audio, gain = synth_line(kokoro, spec, style_cache)
            out = os.path.join(VOICE_DIR, spec["s"], lid + ".ogg")
            y, sr = finalize(audio, gain, spec, out)
            cache[lid] = {"hash": line_hash(spec)}
            result[lid] = {"d": round(len(y) / sr, 3), "env": envelope(y, sr)}
            if i % 10 == 0 or i == len(todo):
                print(f"  [{i}/{len(todo)}] {lid} ({len(y)/sr:.1f}s)", flush=True)
                json.dump(cache, open(CACHE_JSON, "w"))
                _write_json(specs, order, result)
        json.dump(cache, open(CACHE_JSON, "w"))
    _write_json(specs, order, result)
    total = sum(result[l]["d"] for l in order if l in result)
    print(f"done. {len(order)} lines, {total/60:.1f} minutes of speech")


def _write_json(specs, order, result):
    out = {}
    for lid in order:
        spec = specs[lid]
        r = result.get(lid, {})
        entry = {"s": spec["s"], "t": subtitle_text(spec["raw"]), "d": r.get("d", 0.0), "env": r.get("env", ""), "style": spec["style"]}
        if "flat" in spec["flags"] or any(f in spec["flags"] for f in ("phone", "pa", "tv", "radio")):
            entry["flat"] = True
        out[lid] = entry
    os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
    json.dump(out, open(OUT_JSON, "w"), indent=0, ensure_ascii=False)


if __name__ == "__main__":
    main()
