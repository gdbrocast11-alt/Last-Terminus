#!/usr/bin/env python3
"""Original soundtrack for Last Terminus: composed in code, rendered with FluidSynth.

Every cue is defined by chord progressions + motifs written here (no borrowed
material). Loops are rendered two cycles deep and the second cycle is cropped so
reverb tails wrap seamlessly. Stems (chain layers) share one length.

  python3 tools/audio/gen_music.py [cue ...]
"""
import os, subprocess, sys, tempfile, random
import numpy as np
import soundfile as sf
import mido

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "audio", "music")
SF2 = "/usr/share/sounds/sf2/FluidR3_GM.sf2"
SR = 44100

# GM programs (0-based)
PIZZ, STRINGS, TREM, HARP = 45, 48, 44, 46
MARIMBA, XYLO, VIBES, GLOCK, CELESTA, MUSICBOX = 12, 13, 11, 9, 8, 10
CLARINET, OBOE, BASSOON, FLUTE, WHISTLE = 71, 68, 70, 73, 78
MUTED_TPT, TPT, TROMBONE, TUBA, HORN = 59, 56, 57, 58, 60
HONKY, EPIANO, PIANO = 3, 4, 0
ORGAN_CH, HARPSI = 19, 6
NYLON, PAD_WARM, PAD_CHOIR, CHOIR = 24, 89, 91, 52
SYN_BASS, ACO_BASS, TIMPANI, TAIKO, ORCH_HIT = 38, 32, 47, 116, 55
STEEL_DRUM, KAZOO_LIKE = 114, 80

SCALES = {"maj": [0, 2, 4, 5, 7, 9, 11], "min": [0, 2, 3, 5, 7, 8, 10], "dor": [0, 2, 3, 5, 7, 9, 10], "phr": [0, 1, 3, 5, 7, 8, 10], "lyd": [0, 2, 4, 6, 7, 9, 11]}
CH = {"maj": [0, 4, 7], "min": [0, 3, 7], "dim": [0, 3, 6], "dom7": [0, 4, 7, 10], "min7": [0, 3, 7, 10], "maj7": [0, 4, 7, 11], "sus2": [0, 2, 7], "sus4": [0, 5, 7], "aug": [0, 4, 8], "m6": [0, 3, 7, 9], "5": [0, 7]}
# GM drum map
KICK, SNARE, SIDE, HAT, OHAT, BONGO_H, BONGO_L, WOODB_H, WOODB_L, COWBELL, TAMB, SHAKER, CLAVES, TRI, RIDE, CRASH, TOM_L, TOM_M = 36, 38, 37, 42, 46, 60, 61, 76, 77, 56, 54, 82, 75, 81, 51, 49, 45, 47


class Score:
    def __init__(self, bpm, bars, beats=4):
        self.bpm, self.bars, self.beats = bpm, bars, beats
        self.tracks = {}

    def track(self, name, program, drum=False, vol=100, pan=64, reverb=40):
        self.tracks[name] = dict(program=program, drum=drum, notes=[], vol=vol, pan=pan, reverb=reverb, bends=[])

    def n(self, name, start, dur, pitch, vel=90):
        self.tracks[name]["notes"].append((start, dur, int(pitch), int(vel)))

    @property
    def length_beats(self):
        return self.bars * self.beats

    def chord(self, name, start, dur, root, quality, vel=70, octave_shift=0, spread=0.0):
        for i, iv in enumerate(CH[quality]):
            self.n(name, start + i * spread, dur, root + iv + 12 * octave_shift, vel)

    def to_midi(self, path, names=None, cycles=2):
        mid = mido.MidiFile(ticks_per_beat=480)
        L = self.length_beats
        for ci, (name, t) in enumerate(self.tracks.items()):
            if names and name not in names:
                continue
            tr = mido.MidiTrack()
            mid.tracks.append(tr)
            ch = 9 if t["drum"] else min(ci if ci < 9 else ci + 1, 15)
            if ch == 9 and not t["drum"]:
                ch = 10
            if not t["drum"] and ch == 9:
                ch = 10
            tr.append(mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(self.bpm)))
            tr.append(mido.Message("program_change", channel=ch, program=t["program"], time=0))
            tr.append(mido.Message("control_change", channel=ch, control=7, value=t["vol"], time=0))
            tr.append(mido.Message("control_change", channel=ch, control=10, value=t["pan"], time=0))
            tr.append(mido.Message("control_change", channel=ch, control=91, value=t["reverb"], time=0))
            ev = []
            for cyc in range(cycles):
                for (s, d, p, v) in t["notes"]:
                    on = int(round((s + cyc * L) * 480))
                    off = int(round((s + d + cyc * L) * 480))
                    ev.append((on, 1, mido.Message("note_on", channel=ch, note=max(0, min(127, p)), velocity=v)))
                    ev.append((off, 0, mido.Message("note_off", channel=ch, note=max(0, min(127, p)), velocity=0)))
            ev.sort(key=lambda e: (e[0], e[1]))
            last = 0
            for (tt, _, m) in ev:
                m.time = tt - last
                last = tt
                tr.append(m)
        mid.save(path)


def render(score, out_name, names=None, loop=True, tail=1.5, gain=0.65, target_db=-14.0, cycles=2):
    """Render `score` (optionally a subset of tracks) to audio/music/<out_name>.ogg"""
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as td:
        mid = os.path.join(td, "x.mid")
        wav = os.path.join(td, "x.wav")
        score.to_midi(mid, names, cycles if loop else 1)
        subprocess.run(["fluidsynth", "-ni", "-g", str(gain), "-r", str(SR), "-F", wav, SF2, mid], check=True, capture_output=True)
        y, sr = sf.read(wav, dtype="float32")
    if y.ndim > 1:
        y = y.mean(axis=1) if False else y
    sec = score.length_beats * 60.0 / score.bpm
    if loop:
        a = int(sec * sr)
        y = y[a:a + a]
    else:
        y = y[: int((sec + tail) * sr)]
    return finish(y, sr, out_name, target_db, fade=not loop)


def finish(y, sr, out_name, target_db=-14.0, fade=False):
    rms = np.sqrt(np.mean(y ** 2)) + 1e-9
    y = y * (10 ** (target_db / 20) / rms)
    pk = np.max(np.abs(y))
    if pk > 0.95:
        y = np.tanh(y / pk * 1.4) / np.tanh(1.4) * 0.95
    if fade:
        n = int(0.05 * sr)
        y[-n:] *= np.linspace(1, 0, n)[:, None] if y.ndim > 1 else np.linspace(1, 0, n)
    fn = os.path.join(OUT, out_name + ".ogg")
    tmp = tempfile.mktemp(suffix=".wav")
    sf.write(tmp, np.ascontiguousarray(y, dtype=np.float32), sr, subtype="PCM_16")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5", fn], check=True)
    os.unlink(tmp)
    print("  music", out_name, "%.1fs" % (len(y) / sr))
    return fn


# ------------------------------------------------------------------ helpers for patterns
def prog(score, name, chords, dur=4, pattern=None, vel=70, octave=0, **kw):
    """chords: list of (root, quality) one per `dur` beats."""
    for i, (r, q) in enumerate(chords):
        score.chord(name, i * dur, dur * 0.95, r, q, vel, octave, **kw)


def bass_walk(score, name, chords, dur=4, vel=90, octave=-24, style="walk"):
    for i, (r, q) in enumerate(chords):
        b = i * dur
        nxt = chords[(i + 1) % len(chords)][0]
        third = r + (3 if q.startswith("min") or q in ("dim", "m6") else 4)
        fifth = r + 7
        base = r + octave
        if style == "walk":
            seq = [base, third + octave, fifth + octave, (nxt + octave) + (1 if nxt > r else -1)]
            for k in range(min(4, dur)):
                score.n(name, b + k, 0.8, seq[k], vel - (8 if k % 2 else 0))
        elif style == "oompah":
            for k in range(dur):
                score.n(name, b + k, 0.7, base if k % 2 == 0 else fifth + octave, vel)
        elif style == "pedal":
            score.n(name, b, dur * 0.95, base, vel)
        elif style == "eighths":
            for k in range(dur * 2):
                score.n(name, b + k * 0.5, 0.4, base if k % 4 != 3 else fifth + octave, vel - (10 if k % 2 else 0))


def arp(score, name, chords, dur=4, step=0.5, vel=70, octave=0, pattern=(0, 1, 2, 1), gate=0.9):
    for i, (r, q) in enumerate(chords):
        notes = [r + iv + 12 * octave for iv in CH[q]]
        for k in range(int(dur / step)):
            score.n(name, i * dur + k * step, step * gate, notes[pattern[k % len(pattern)] % len(notes)], vel - (10 if k % 2 else 0))


def motif(score, name, notes, start, vel=85, transpose=0):
    """notes: list of (offset_beats, dur, pitch)."""
    for (o, d, p) in notes:
        score.n(name, start + o, d, p + transpose, vel)


def drum_pattern(score, name, pattern, bars, beats=4, vel=80):
    """pattern: dict pitch -> list of beat positions within a bar (float)."""
    for b in range(bars):
        for pitch, poss in pattern.items():
            for pos in poss:
                v = vel if float(pos).is_integer() else vel - 15
                score.n(name, b * beats + pos, 0.2, pitch, v)


N = {"C": 60, "Db": 61, "D": 62, "Eb": 63, "E": 64, "F": 65, "Gb": 66, "G": 67, "Ab": 68, "A": 69, "Bb": 70, "B": 71}

# ------------------------------------------------------------------ cues
def cue_title():
    s = Score(84, 16)
    D, F, A, C, G, Bb, E = N["D"], N["F"], N["A"], N["C"], N["G"], N["Bb"], N["E"]
    ch = [(D, "min"), (Bb - 12, "maj7"), (G - 12, "min7"), (A - 12, "dom7")] * 4
    s.track("bass", PIZZ, vol=105); bass_walk(s, "bass", ch, octave=-12)
    s.track("cel", CELESTA, vol=85, pan=90); arp(s, "cel", ch, step=0.5, octave=1, vel=60, pattern=(0, 2, 1, 2))
    s.track("clar", CLARINET, vol=90, pan=50)
    mel = [(0, 1.5, D + 12), (1.5, 0.5, F + 12), (2, 1, A + 12), (3, 1, G + 12), (4, 1.5, F + 12), (5.5, 0.5, E + 12), (6, 2, D + 12), (8, 1.5, Bb + 12), (9.5, 0.5, A + 12), (10, 1, G + 12), (11, 1, F + 12), (12, 2, E + 12), (14, 2, A + 12)]
    for rep in range(2):
        motif(s, "clar", mel, rep * 32, 80)
    s.track("tpt", MUTED_TPT, vol=80, pan=80)
    for rep in (16, 48):
        motif(s, "tpt", [(0, 0.5, A), (1, 0.5, A), (2, 1, C + 12), (4, 0.5, Bb), (5, 0.5, Bb), (6, 1, D + 12), (8, 4, A + 12), (12, 2, G + 12)], rep, 70)
    s.track("pad", PAD_WARM, vol=70, reverb=70); prog(s, "pad", ch, vel=45, octave=-1)
    s.track("drums", 0, drum=True, vol=90)
    drum_pattern(s, "drums", {SIDE: [1, 3], SHAKER: [0.5, 1.5, 2.5, 3.5], WOODB_H: [2.5]}, 16, vel=60)
    render(s, "mus_title")


def cue_explore_station():
    s = Score(104, 16)
    C, D, E, F, G, A, Bb = N["C"], N["D"], N["E"], N["F"], N["G"], N["A"], N["Bb"]
    ch = [(C, "maj"), (A - 12, "min7"), (F, "maj7"), (G, "dom7"), (C, "maj"), (E - 12, "dom7"), (A - 12, "min"), (D - 12, "min7")] * 2
    s.track("bass", PIZZ, vol=105); bass_walk(s, "bass", ch, octave=-12)
    s.track("xylo", XYLO, vol=85, pan=90)
    m = [(0, 0.5, E + 12), (0.5, 0.5, G + 12), (1, 1, C + 24), (2, 0.5, B if False else N["B"] + 12), (2.5, 0.5, A + 12), (3, 1, G + 12)]
    for b in range(0, 64, 8):
        motif(s, "xylo", m, b, 70)
    s.track("clar", CLARINET, vol=80, pan=40)
    for b in range(0, 64, 16):
        motif(s, "clar", [(0, 2, G), (2, 1, A), (3, 1, C + 12), (4, 3, E + 12), (7, 1, D + 12)], b + 4, 65)
    s.track("pad", PAD_WARM, vol=55, reverb=70); prog(s, "pad", ch, vel=40, octave=-1)
    s.track("drums", 0, drum=True, vol=80)
    drum_pattern(s, "drums", {SIDE: [1, 3], HAT: [0.5, 1.5, 2.5, 3.5], WOODB_L: [3.5]}, 16, vel=55)
    render(s, "mus_explore_station")


def cue_explore_low():
    s = Score(88, 16)
    A, C, D, E, F, G, B = N["A"], N["C"], N["D"], N["E"], N["F"], N["G"], N["B"]
    ch = [(A - 12, "min7"), (F - 12, "maj7"), (D - 12, "min7"), (E - 12, "dom7")] * 4
    s.track("bass", PIZZ, vol=105); bass_walk(s, "bass", ch, octave=0, style="oompah")
    s.track("vibes", VIBES, vol=80, pan=85); arp(s, "vibes", ch, step=1.0, octave=1, vel=55, pattern=(0, 2, 1, 3))
    s.track("bcl", CLARINET, vol=95, pan=45)
    for b in range(0, 64, 16):
        motif(s, "bcl", [(0, 3, A - 12), (3, 1, C), (4, 3, E), (7, 1, D), (8, 2, C), (10, 2, B - 12), (12, 4, A - 12)], b, 70)
    s.track("pad", PAD_CHOIR, vol=45, reverb=90); prog(s, "pad", ch, vel=35)
    s.track("drums", 0, drum=True, vol=70)
    drum_pattern(s, "drums", {SIDE: [1.5, 3.5], WOODB_L: [0], CLAVES: [2.5]}, 16, vel=45)
    render(s, "mus_explore_low")


def cue_store():
    s = Score(108, 16)
    G, A, Bb, C, D, E, F = N["G"], N["A"], N["Bb"], N["C"], N["D"], N["E"], N["F"]
    ch = [(G - 12, "min7"), (C, "dom7"), (G - 12, "min7"), (D - 12, "dom7")] * 4
    s.track("bass", PIZZ, vol=108); bass_walk(s, "bass", ch, octave=0, style="eighths")
    s.track("mar", MARIMBA, vol=90, pan=85); arp(s, "mar", ch, step=0.5, octave=1, vel=65, pattern=(0, 2, 1, 2, 3, 2))
    s.track("tpt", MUTED_TPT, vol=80, pan=35)
    for b in range(0, 64, 16):
        motif(s, "tpt", [(0, 0.5, G + 12), (0.5, 0.5, Bb + 12), (1, 1, D + 24), (3, 1, C + 24), (4, 0.5, Bb + 12), (5, 0.5, A + 12), (6, 2, G + 12)], b + 8, 65)
    s.track("drums", 0, drum=True, vol=85)
    drum_pattern(s, "drums", {KICK: [0, 2.5], SIDE: [1, 3], HAT: [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5], COWBELL: [3.5]}, 16, vel=60)
    render(s, "mus_store")


def cue_wellness():
    s = Score(76, 16)
    C, D, E, F, G, A, B = N["C"], N["D"], N["E"], N["F"], N["G"], N["A"], N["B"]
    ch = [(F, "maj7"), (E - 12, "min7"), (D - 12, "min7"), (G - 12, "dom7"), (C, "maj7"), (A - 12, "min7"), (D - 12, "min7"), (G - 12, "sus4")] * 2
    s.track("pad", PAD_WARM, vol=85, reverb=90); prog(s, "pad", ch, vel=55)
    s.track("vibes", VIBES, vol=90, pan=80); arp(s, "vibes", ch, step=1.0, octave=1, vel=55, pattern=(0, 1, 2, 3, 2, 1))
    s.track("fl", FLUTE, vol=80, pan=45)
    for b in range(0, 64, 16):
        motif(s, "fl", [(0, 2, A + 12), (2, 1, G + 12), (3, 1, F + 12), (4, 4, E + 12), (8, 2, D + 12), (10, 2, F + 12), (12, 4, G + 12)], b, 60)
    s.track("bass", ACO_BASS, vol=90); bass_walk(s, "bass", ch, octave=-12, style="pedal")
    s.track("perc", 0, drum=True, vol=60)
    drum_pattern(s, "perc", {SHAKER: [0, 1, 2, 3], TRI: [0]}, 16, vel=40)
    render(s, "mus_wellness")


def cue_yard():
    s = Score(72, 16)
    D, E, F, G, A, Bb, C = N["D"], N["E"], N["F"], N["G"], N["A"], N["Bb"], N["C"]
    ch = [(D - 12, "min"), (Bb - 24, "maj"), (F - 12, "maj"), (A - 24, "dom7")] * 4
    s.track("tuba", TUBA, vol=95, pan=64); bass_walk(s, "tuba", ch, octave=0, style="pedal")
    s.track("bcl", CLARINET, vol=95, pan=45)
    for b in range(0, 64, 16):
        motif(s, "bcl", [(0, 3, D), (3, 1, F), (4, 2, A - 12), (6, 2, C), (8, 4, D), (12, 2, E), (14, 2, F)], b, 65)
    s.track("gtr", NYLON, vol=80, pan=90); arp(s, "gtr", ch, step=1.0, octave=0, vel=55, pattern=(0, 1, 2, 1))
    s.track("drums", 0, drum=True, vol=80)
    drum_pattern(s, "drums", {SIDE: [1, 3], CLAVES: [2.5], TOM_L: [0]}, 16, vel=50)
    render(s, "mus_yard")


def cue_apartment():
    s = Score(66, 16)
    A, C, D, E, F, G = N["A"], N["C"], N["D"], N["E"], N["F"], N["G"]
    ch = [(A - 12, "min"), (F - 12, "maj7"), (C, "maj"), (G - 12, "sus4")] * 4
    s.track("pno", PIANO, vol=95, pan=70); arp(s, "pno", ch, step=1.0, octave=0, vel=50, pattern=(0, 1, 2, 1))
    s.track("pad", PAD_WARM, vol=65, reverb=90); prog(s, "pad", ch, vel=40)
    s.track("cel", MUSICBOX, vol=75, pan=95)
    for b in range(0, 64, 16):
        motif(s, "cel", [(0, 1, E + 12), (2, 1, A + 12), (4, 2, C + 24), (8, 1, B if False else N["B"] + 12), (10, 1, A + 12), (12, 4, E + 12)], b, 55)
    s.track("bass", PIZZ, vol=85); bass_walk(s, "bass", ch, octave=0, style="pedal")
    render(s, "mus_apartment")


def cue_graves():
    s = Score(72, 16)
    D, E, F, G, A, Bb, C = N["D"], N["E"], N["F"], N["G"], N["A"], N["Bb"], N["C"]
    ch = [(D, "min"), (A - 12, "dom7"), (D, "min"), (G - 12, "min7"), (Bb - 12, "maj7"), (A - 12, "dom7"), (D, "min"), (A - 12, "sus4")] * 2
    s.track("hpsi", HARPSI, vol=100, pan=64); arp(s, "hpsi", ch, step=0.5, octave=0, vel=70, pattern=(0, 1, 2, 3, 2, 1))
    s.track("org", ORGAN_CH, vol=75, reverb=100); prog(s, "org", ch, vel=45, octave=-1)
    s.track("bass", PIZZ, vol=100); bass_walk(s, "bass", ch, octave=-12, style="walk")
    s.track("bsn", BASSOON, vol=90, pan=40)
    for b in range(0, 64, 16):
        motif(s, "bsn", [(0, 1, D), (1.5, 0.5, F), (2, 2, E), (4, 1, D), (5.5, 0.5, C), (6, 2, A - 12), (8, 4, D)], b + 4, 65)
    render(s, "mus_graves")


def cue_chase():
    s = Score(164, 8)
    D, E, F, G, A, Bb, C = N["D"], N["E"], N["F"], N["G"], N["A"], N["Bb"], N["C"]
    ch = [(D - 12, "min"), (D - 12, "min"), (Bb - 24, "maj"), (A - 24, "dom7")] * 2
    s.track("bass", PIZZ, vol=110); bass_walk(s, "bass", ch, octave=0, style="eighths")
    s.track("xylo", XYLO, vol=90, pan=90); arp(s, "xylo", ch, step=0.5, octave=2, vel=75, pattern=(0, 2, 1, 3))
    s.track("tpt", TPT, vol=85, pan=35)
    for b in (0, 16):
        motif(s, "tpt", [(0, 1, D + 12), (1, 1, F + 12), (2, 2, A + 12), (4, 1, G + 12), (5, 1, F + 12), (6, 2, E + 12), (8, 1, D + 12), (9, 1, F + 12), (10, 2, A + 12), (12, 4, C + 24)], b, 90)
    s.track("drums", 0, drum=True, vol=100)
    drum_pattern(s, "drums", {KICK: [0, 1, 2, 3], SNARE: [1, 3], HAT: [0.5, 1.5, 2.5, 3.5], TOM_L: [3.5]}, 8, vel=85)
    render(s, "mus_chase")


def cue_credits():
    s = Score(122, 16)
    F, G, A, Bb, C, D, E = N["F"], N["G"], N["A"], N["Bb"], N["C"], N["D"], N["E"]
    ch = [(F, "maj"), (C, "maj"), (G - 12, "min7"), (C, "dom7"), (F, "maj"), (Bb - 12, "maj"), (G - 12, "min7"), (C, "sus4")] * 2
    s.track("bass", PIZZ, vol=105); bass_walk(s, "bass", ch, octave=-12, style="oompah")
    s.track("gl", GLOCK, vol=85, pan=90); arp(s, "gl", ch, step=0.5, octave=1, vel=60, pattern=(0, 1, 2, 1))
    s.track("ep", EPIANO, vol=85, pan=40); prog(s, "ep", ch, dur=2 if False else 4, vel=55)
    s.track("wh", WHISTLE, vol=80, pan=64)
    for b in range(0, 64, 16):
        motif(s, "wh", [(0, 1, A), (1, 1, C + 12), (2, 2, F + 12), (4, 1, E + 12), (5, 1, D + 12), (6, 2, C + 12), (8, 1, A), (9, 1, Bb), (10, 2, D + 12), (12, 4, C + 12)], b, 75)
    s.track("drums", 0, drum=True, vol=85)
    drum_pattern(s, "drums", {KICK: [0, 2], SNARE: [1, 3], HAT: [0.5, 1.5, 2.5, 3.5], TAMB: [1, 3]}, 16, vel=60)
    render(s, "mus_credits")


def cue_ending_walk():
    s = Score(86, 16)
    G, A, B, C, D, E = N["G"], N["A"], N["B"], N["C"], N["D"], N["E"]
    ch = [(G - 12, "maj"), (E - 12, "min7"), (C, "maj7"), (D - 12, "sus4")] * 4
    s.track("gtr", NYLON, vol=100, pan=60); arp(s, "gtr", ch, step=0.5, octave=0, vel=62, pattern=(0, 1, 2, 1, 2, 1))
    s.track("fl", FLUTE, vol=85, pan=80)
    for b in range(0, 64, 16):
        motif(s, "fl", [(0, 2, B), (2, 2, D + 12), (4, 3, G + 12), (7, 1, F if False else N["E"] + 12), (8, 2, D + 12), (10, 2, B), (12, 4, A)], b, 60)
    s.track("str", STRINGS, vol=65, reverb=80); prog(s, "str", ch, vel=40)
    s.track("bass", ACO_BASS, vol=85); bass_walk(s, "bass", ch, octave=-12, style="pedal")
    render(s, "mus_ending_walk")


# ---- premonition: fragmented, unstable tones
def cue_premonition():
    rnd = random.Random(5)
    s = Score(60, 8)
    s.track("trem", TREM, vol=100, reverb=100)
    s.track("hpsi", HONKY, vol=90, reverb=100)
    s.track("tim", TIMPANI, vol=100, reverb=90)
    s.track("hit", ORCH_HIT, vol=60)
    for b in range(0, 32, 4):
        s.chord("trem", b, 4.5, 50 + rnd.choice([0, 1, 3]), "dim", 60, 0)
    base = [62, 63, 68, 61, 66]
    for i in range(20):
        s.n("hpsi", rnd.uniform(0, 31), rnd.uniform(0.1, 0.5), rnd.choice(base) + rnd.choice([0, 12, -12]) + rnd.choice([0, 1]), rnd.randint(40, 85))
    for i in range(0, 32, 2):
        s.n("tim", i + rnd.choice([0, 0.5]), 0.5, 38, 70)
    s.n("hit", 0, 0.5, 40, 60); s.n("hit", 24, 0.5, 45, 70)
    fn = render(s, "mus_premonition", target_db=-17)
    # tape-warp: slow pitch drift + darker tone
    y, sr = sf.read(fn, dtype="float32")
    t = np.arange(len(y)) / sr
    idx = np.clip(t + 0.008 * np.sin(2 * np.pi * 0.4 * t), 0, len(y) / sr - 1e-3)
    y = np.stack([np.interp(idx * sr, np.arange(len(y)), y[:, c]) for c in range(y.shape[1])], 1).astype(np.float32)
    finish(y, sr, "mus_premonition", -17)


# ---- chain layers: 5 synchronised stems at 132 bpm (D minor), 8 bars
def cue_chain():
    s = Score(132, 8)
    D, E, F, G, A, Bb, C = N["D"], N["E"], N["F"], N["G"], N["A"], N["Bb"], N["C"]
    ch = [(D - 12, "min"), (D - 12, "min"), (Bb - 24, "maj"), (A - 24, "dom7")] * 2
    s.track("perc", 0, drum=True, vol=100)
    drum_pattern(s, "perc", {WOODB_H: [0.5, 1.5, 2.5, 3.5], SIDE: [1, 3], SHAKER: [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5]}, 8, vel=65)
    s.track("bass", PIZZ, vol=110); bass_walk(s, "bass", ch, octave=0, style="eighths")
    s.track("mar", MARIMBA, vol=95, pan=85); arp(s, "mar", ch, dur=4, step=0.5, octave=1, vel=75, pattern=(0, 2, 1, 3))
    s.track("str", TREM, vol=90, pan=50); prog(s, "str", ch, vel=70)
    s.track("brass", TPT, vol=95, pan=30)
    for b in (0, 16):
        motif(s, "brass", [(0, 0.75, D + 12), (1, 0.75, F + 12), (2, 1, A + 12), (4, 0.75, G + 12), (5, 0.75, F + 12), (6, 1, D + 12), (8, 2, Bb), (10, 2, C + 12), (12, 4, D + 12)], b, 95)
    for i, stem in enumerate(("perc", "bass", "mar", "str", "brass")):
        render(s, "chain_a__" + stem, names=[stem], target_db=-16)


# ---- pickles: dramatic build + stupid resolutions
def cue_pickles_build():
    s = Score(96, 4)
    s.track("trem", TREM, vol=110, reverb=90)
    s.track("tim", TIMPANI, vol=110)
    s.track("ch", CHOIR, vol=90, reverb=110)
    s.track("hit", ORCH_HIT, vol=100)
    for i, p in enumerate((50, 53, 57, 60)):
        s.n("trem", i * 4, 4.2, p, 50 + i * 12)
        s.n("trem", i * 4, 4.2, p + 7, 45 + i * 12)
        s.n("ch", i * 4 + 1, 3.5, p + 12, 40 + i * 14)
    for i in range(0, 16 * 4):
        s.n("tim", i * 0.25, 0.2, 40, 35 + int(i * 1.3))
    s.n("hit", 15.5, 0.3, 50, 120)
    render(s, "sting_tragic_build", loop=False, target_db=-13, tail=2.0)


def cue_pickles_resolves():
    for k in range(3):
        s = Score(120, 2)
        s.track("tuba", TUBA, vol=120); s.track("xy", XYLO, vol=100, pan=90); s.track("sw", WHISTLE, vol=90); s.track("bd", 0, drum=True, vol=100)
        if k == 0:
            motif(s, "tuba", [(0, 0.5, 43), (0.5, 0.5, 43), (1, 1.5, 38)], 0, 100)
            motif(s, "xy", [(1.5, 0.25, 84), (2, 0.5, 91)], 0, 90)
        elif k == 1:
            motif(s, "tuba", [(0, 0.5, 41), (0.75, 0.5, 41), (1.5, 1, 36)], 0, 100)
            motif(s, "sw", [(0, 0.25, 79), (0.25, 0.25, 83), (0.5, 0.25, 86), (0.75, 0.25, 91)], 0.5, 85)
            motif(s, "xy", [(2, 0.5, 96)], 0, 90)
        else:
            motif(s, "tuba", [(0, 0.5, 40), (0.5, 0.5, 47), (1, 1, 40)], 0, 100)
            motif(s, "xy", [(1.5, 0.25, 79), (1.75, 0.25, 84), (2, 0.5, 88)], 0, 90)
            s.n("bd", 2.5, 0.2, WOODB_H, 100)
        render(s, "sting_stupid_resolve_%02d" % (k + 1), loop=False, target_db=-13, tail=1.2)


def cue_stings():
    def one(name, build, bpm=110, bars=2, db=-13, tail=1.5):
        s = Score(bpm, bars)
        build(s)
        render(s, name, loop=False, target_db=db, tail=tail)
    def saved(s):
        s.track("gl", GLOCK, vol=100, pan=90); s.track("pz", PIZZ, vol=100); s.track("fl", FLUTE, vol=90)
        motif(s, "gl", [(0, 0.5, 79), (0.5, 0.5, 83), (1, 0.5, 86), (1.5, 1.5, 91)], 0, 90)
        motif(s, "pz", [(0, 0.5, 48), (1, 0.5, 55), (1.5, 1.5, 60)], 0, 90)
    one("sting_saved", saved)
    def oh_no(s):
        s.track("tb", TROMBONE, vol=110); s.track("tu", TUBA, vol=100)
        motif(s, "tb", [(0, 0.75, 62), (0.75, 0.75, 61), (1.5, 0.75, 60), (2.25, 2.0, 56)], 0, 100)
        motif(s, "tu", [(2.25, 2.0, 32)], 0, 100)
    one("sting_oh_no", oh_no, bpm=100, bars=3)
    def death(s):
        s.track("hit", ORCH_HIT, vol=110); s.track("tim", TIMPANI, vol=110); s.track("tb", TROMBONE, vol=100)
        s.n("hit", 0, 0.5, 45, 120); s.n("tim", 0, 1, 33, 120)
        motif(s, "tb", [(1, 0.5, 57), (1.5, 0.5, 56), (2, 0.5, 55), (2.5, 2.0, 50)], 0, 90)
    one("sting_death", death, bpm=90, bars=3)
    def reveal(s):
        s.track("hit", ORCH_HIT, vol=110); s.track("tim", TIMPANI, vol=110)
        s.n("hit", 0, 0.4, 50, 120); s.n("hit", 1, 0.4, 52, 120); s.n("hit", 2, 1.5, 47, 127); s.n("tim", 2, 1.5, 35, 120)
    one("sting_reveal", reveal, bpm=80, bars=3)
    def title_card(s):
        s.track("hit", ORCH_HIT, vol=120); s.track("tim", TIMPANI, vol=120); s.track("org", ORGAN_CH, vol=90); s.track("ch", CHOIR, vol=90)
        s.n("hit", 0, 1, 38, 127); s.n("tim", 0, 3, 31, 127)
        s.chord("org", 0, 5, 38, "min", 100, 0); s.chord("ch", 0.5, 5, 50, "min", 80, 0)
    one("sting_title_card", title_card, bpm=60, bars=6, tail=3.0)
    def good_boy(s):
        s.track("gl", GLOCK, vol=100, pan=90); s.track("wh", WHISTLE, vol=90); s.track("pz", PIZZ, vol=100)
        motif(s, "gl", [(0, 0.5, 72), (0.5, 0.5, 76), (1, 0.5, 79), (1.5, 0.5, 84), (2, 2, 88)], 0, 85)
        motif(s, "wh", [(2, 0.5, 79), (2.5, 0.5, 84), (3, 2, 88)], 0, 80)
        motif(s, "pz", [(0, 1, 48), (2, 1, 55), (3, 1, 60)], 0, 90)
    one("sting_good_boy", good_boy, bpm=120, bars=4)
    def mystery(s):
        s.track("hp", HARP, vol=100); s.track("cl", CLARINET, vol=90); s.track("pad", PAD_WARM, vol=70)
        motif(s, "hp", [(0, 0.5, 60), (0.5, 0.5, 63), (1, 0.5, 66), (1.5, 2, 69)], 0, 80)
        motif(s, "cl", [(2, 3, 57)], 0, 70)
        s.chord("pad", 0, 5, 45, "dim", 60, 0)
    one("sting_mystery", mystery, bpm=80, bars=4)
    def finale_flop(s):
        s.track("tu", TUBA, vol=110); s.track("ho", HONKY, vol=100); s.track("sw", WHISTLE, vol=90)
        motif(s, "tu", [(0, 0.5, 36), (0.5, 0.5, 36), (1, 0.5, 43), (1.5, 1.5, 34)], 0, 100)
        motif(s, "ho", [(2, 0.25, 72), (2.25, 0.25, 71), (2.5, 0.25, 73), (2.75, 1, 60)], 0, 90)
    one("sting_finale_flop", finale_flop, bpm=120, bars=3)
    def bus(s):
        s.track("tu", TUBA, vol=120); s.track("hit", ORCH_HIT, vol=110)
        s.n("hit", 0, 0.3, 38, 127); motif(s, "tu", [(0.5, 1, 31)], 0, 110)
    one("sting_bus", bus, bpm=100, bars=2)


# ---- finale: grand doom, and a confused version of the same phrases
def cue_finale():
    s = Score(66, 16)
    D, E, F, G, A, Bb, C = N["D"], N["E"], N["F"], N["G"], N["A"], N["Bb"], N["C"]
    ch = [(D - 12, "min"), (Bb - 24, "maj"), (G - 12, "min"), (A - 24, "dom7")] * 4
    s.track("ch", CHOIR, vol=100, reverb=110); prog(s, "ch", ch, vel=75, octave=0)
    s.track("org", ORGAN_CH, vol=85, reverb=100); prog(s, "org", ch, vel=60, octave=-1)
    s.track("tim", TIMPANI, vol=115)
    for b in range(0, 64, 4):
        s.n("tim", b, 1.5, 38, 100); s.n("tim", b + 2, 1, 43, 80)
    s.track("bell", 14, vol=90, pan=90)
    for b in range(0, 64, 16):
        motif(s, "bell", [(0, 4, D + 12), (4, 4, F + 12), (8, 4, A + 12), (12, 4, D + 24)], b, 85)
    s.track("hit", ORCH_HIT, vol=100)
    for b in range(0, 64, 16):
        s.n("hit", b, 0.5, 38, 110)
    render(s, "mus_finale_doom")
    c = Score(66, 16)
    c.track("ho", HONKY, vol=100, pan=60); c.track("tu", TUBA, vol=110); c.track("kz", KAZOO_LIKE if False else 80, vol=80, pan=90); c.track("wh", WHISTLE, vol=80)
    c.track("tim", TIMPANI, vol=100)
    rnd = random.Random(2)
    for i, (r, q) in enumerate(ch):
        c.chord("ho", i * 4 + rnd.choice([0, 0.5]), 3, r + rnd.choice([0, 1, -1]), q, 70, 0)
        c.n("tu", i * 4, 1.5, r - 12, 100)
    for b in range(0, 64, 16):
        motif(c, "kz", [(0, 1, D + 12), (1, 1, F + 12), (2, 1, A + 12), (3, 0.5, D + 24), (3.5, 0.5, 71), (4, 1.5, F + 12), (6, 1, 70), (8, 4, A + 12)], b, 80)
        motif(c, "wh", [(12, 0.25, 100), (12.25, 0.25, 96), (12.5, 0.25, 92), (12.75, 0.25, 88)], b, 70)
    for b in range(0, 64, 4):
        c.n("tim", b + rnd.choice([0, 0.25]), 0.5, 38, 90)
    render(c, "mus_finale_confused")


ALL = dict(title=cue_title, station=cue_explore_station, low=cue_explore_low, store=cue_store, wellness=cue_wellness, yard=cue_yard, apartment=cue_apartment,
           graves=cue_graves, chase=cue_chase, credits=cue_credits, ending=cue_ending_walk, premonition=cue_premonition, chain=cue_chain,
           pickles=lambda: (cue_pickles_build(), cue_pickles_resolves()), stings=cue_stings, finale=cue_finale)

if __name__ == "__main__":
    want = sys.argv[1:] or list(ALL.keys())
    for k in want:
        print("cue", k)
        ALL[k]()
