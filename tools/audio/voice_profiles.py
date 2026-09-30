"""Voice casting for Last Terminus.

All voices are synthetic (Kokoro-82M, Apache-2.0). Each character is a blend of
stock Kokoro style vectors plus pitch/tempo processing, so no voice imitates a
real performer. `styles` tweak delivery per line.
"""

# blend: list of (kokoro voice, weight)
PROFILES = {
    "eddie":   {"blend": [("am_michael", 0.65), ("am_adam", 0.35)], "speed": 1.00, "pitch": 0.6, "lang": "en-us"},
    "brenda":  {"blend": [("af_nova", 0.6), ("af_jessica", 0.4)], "speed": 1.13, "pitch": 0.0, "lang": "en-us"},
    "dale":    {"blend": [("am_puck", 1.0)], "speed": 1.27, "pitch": 1.8, "lang": "en-us"},
    "tiffany": {"blend": [("af_heart", 0.55), ("af_sky", 0.45)], "speed": 1.04, "pitch": 0.5, "lang": "en-us"},
    "mills":   {"blend": [("am_onyx", 0.7), ("am_eric", 0.3)], "speed": 1.00, "pitch": -1.0, "lang": "en-us"},
    "gus":     {"blend": [("am_fenrir", 0.6), ("bm_george", 0.4)], "speed": 0.84, "pitch": -2.6, "lang": "en-us", "eq": "old"},
    "marco":   {"blend": [("am_eric", 1.0)], "speed": 1.12, "pitch": 0.4, "lang": "en-us"},
    "luis":    {"blend": [("am_echo", 1.0)], "speed": 1.2, "pitch": 3.0, "lang": "en-us"},
    "graves":  {"blend": [("bm_fable", 0.6), ("bm_lewis", 0.4)], "speed": 0.76, "pitch": -4.0, "lang": "en-gb", "eq": "warm"},
    "pa":      {"blend": [("af_kore", 1.0)], "speed": 0.95, "pitch": 0.0, "lang": "en-us", "eq": "pa"},
    "news":    {"blend": [("af_nicole", 0.6), ("af_bella", 0.4)], "speed": 1.08, "pitch": 0.0, "lang": "en-us", "eq": "tv"},
    "stranger": {"blend": [("af_sarah", 1.0)], "speed": 1.05, "pitch": -0.5, "lang": "en-us"},
    "kid":     {"blend": [("af_river", 1.0)], "speed": 1.15, "pitch": 4.0, "lang": "en-us"},
    "driver":  {"blend": [("bm_daniel", 1.0)], "speed": 1.0, "pitch": -2.0, "lang": "en-us"},
    "guard":   {"blend": [("am_adam", 1.0)], "speed": 1.0, "pitch": -2.5, "lang": "en-us"},
    "clerk":   {"blend": [("af_alloy", 1.0)], "speed": 1.05, "pitch": 0.0, "lang": "en-us"},
    "machine": {"blend": [("af_alloy", 1.0)], "speed": 0.98, "pitch": -0.5, "lang": "en-us", "eq": "radio"},
    "crowd":   {"blend": [("am_liam", 1.0)], "speed": 1.15, "pitch": 0.0, "lang": "en-us"},
}

# per-line delivery tweaks: speed multiplier, pitch shift (semitones), gain dB
STYLES = {
    "": (1.0, 0.0, 0.0),
    "dry": (0.97, -0.3, 0.0),
    "calm": (0.95, -0.2, -1.0),
    "tired": (0.9, -0.8, -1.5),
    "panic": (1.15, 1.2, 1.5),
    "shout": (1.05, 1.5, 3.0),
    "whisper": (0.9, -0.5, -6.0),
    "mumble": (0.92, -1.0, -3.0),
    "excited": (1.1, 1.0, 1.5),
    "deadpan": (0.93, -0.5, -0.5),
    "theatrical": (0.92, 0.3, 1.0),
    "sincere": (0.92, -0.2, -0.5),
    "smug": (1.0, 0.4, 0.0),
    "bright": (1.05, 0.8, 0.5),
    "grim": (0.92, -1.2, 0.0),
}

# post-processing EQ chains handled in render_voices.py
