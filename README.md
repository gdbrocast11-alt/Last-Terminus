# LAST TERMINUS

*The last stop you'll ever need.*

A first-person slapstick horror-comedy for Godot 4.7 (Forward+, Jolt physics). You are **Eddie Mercer**,
who had a vision of a train-station collapse, got thrown out by security for pulling the fire alarm, and
now can't stop seeing how everyone in the station is supposed to die. With his dog **Pickles** (unkillable,
extremely good) he tries to break the chain of stupid accidents that keeps almost-killing the survivors.

Roughly 50-60 minutes across eight chapters:

| # | Chapter | Where | The gag |
|---|---------|-------|---------|
| 1 | Terminus Station | brand new transit hub | premonition, panic, alarm, thrown out, the collapse seen through the glass |
| 2 | Aftermath | Eddie's over-secured apartment | news, voicemails, the sequence |
| 3 | Toolbert's Home Center | hardware store after hours | Brenda's shoot; a 14-step Rube Goldberg machine ending in a rain of lawn flamingos |
| 4 | The Alignment Pop-Up | rec-centre wellness event | Gus quietly defuses everything; the machine reroutes to a chandelier and a treadmill |
| 5 | Doctor Graves Explains Nothing | apartment | a theory about the dog |
| 6 | Halloran Yard | abandoned maintenance yard | six lethal setups x three lucky escapes; then "you win" -- and the whole yard goes off |
| 7 | Return to Terminus | reopening ceremony | do absolutely nothing |
| 8 | A Normal Evening | apartment, street, CCTV | "Nah." |

## Controls (all remappable, gamepad supported)

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move / look | WASD / mouse | left stick / right stick |
| Sprint / crouch | Shift / Ctrl or C | L3 / R3 |
| Jump / mantle | Space | A |
| Interact / inspect (RMB, works at long range) | E / RMB | X / LB |
| Use / throw | LMB | RT |
| Drop | R | B |
| Pickles: **F** = contextual (Fetch / Go there / Bark / Stay / Come); hold **F** = Come | F | Y |
| Danger intuition (highlights hazards) | Q | RB |
| Notebook (the Sequence, clues, survivors) | Tab | Back |
| Pause | Esc | Start |

Accessibility: subtitles with speaker names (size/opacity/background), reduced flashing, premonition
distortion slider, camera shake / head bob sliders, toggle sprint & crouch, hold-to-toggle options,
optional gore reduction, high-contrast prompts, full remapping.

## Building

Requirements: Godot 4.7.x (with export templates), Blender 5.2 LTS (headless), Python 3 with NumPy/SciPy/Pillow/mido/soundfile,
FluidSynth + FluidR3_GM.sf2, FFmpeg, SoX, and the Kokoro-82M ONNX model for the voices.

Everything in the game is generated from source in this repository:

```
tools/blender/*.py        procedural textures, props, 15 rigged characters + Pickles, animations, level shells
tools/audio/*.py          Kokoro voices, procedural SFX, MIDI -> FluidSynth music
tools/godot/build_*.gd    bakes generated assets into scenes (materials, props, characters, levels + navmesh)
scripts/                  gameplay: player, Pickles, NPCs, accident-chain framework, chapters, UI
dialogue/src/*.txt        every spoken line (id | speaker | style | text)
```

Typical rebuild:

```bash
python3 tools/blender/gen_textures.py
blender -b --python tools/blender/gen_props.py
blender -b --python tools/blender/gen_characters.py
for l in apartment station store wellness yard street; do blender -b --python tools/blender/gen_level_$l.py; done
python3 tools/audio/render_voices.py && python3 tools/audio/gen_sfx.py && python3 tools/audio/gen_music.py
tools/refresh.sh                                            # import
for t in materials props characters levels; do godot --headless --path . res://tools/godot/builder.tscn -- $t; done
tools/lint.sh                                               # every script must parse
tools/export.sh all                                         # builds/linux + builds/windows
```

## Developer tooling

* **F1** (editor runs or `--dev`) opens the dev overlay: FPS/draw calls/physics bodies, chapter select, trigger chain,
  toggle hazard volumes, summon Pickles, force survivor states, fire a premonition.
* `godot --path . -- --qa-autoplay [--qa-from=N] [--qa-beat=b] [--qa-until=N] [--qa-speed=4] [--qa-full] [--qa-nointervene]`
  plays the game with a bot (see `scripts/qa/qa_autoplay.gd`); every chapter registers QA hooks with `qa_add`.
* `builder.tscn -- walktest <level> a:b ...` physically walks the real player controller between markers;
  `-- probe <level>` checks markers against colliders; `-- perf`, `-- shot`, `-- gallery`, `-- animsheet` for visual QA.
* `builder.tscn -- usetest <chapter> <beat> <prop> ...` stands the real player in front of props and presses the real
  Interact input (proves every bound action is reachable); `-- savetest` covers checkpoints, the rolling backup,
  corrupt/tampered saves and Continue; `-- dumpprop` prints a prop's node/collision tree.
* `--qa-nointervene` / `--qa-dead=brenda,tiffany` make the bot let people die / start with fixed survivor fates,
  to exercise the failure branches of every chapter.
* `python3 tools/lint_lines.py` checks that every dialogue id used by a script exists and has rendered audio.

## How the accidents work

`scripts/chain/accident_chain.gd` is a data-driven, deterministic Rube-Goldberg engine. A chain is a list of
*steps* (`Ch.step(...)`) with dependencies (`after`, `any`, `after_blocked`), delays, tween-driven actions
(move / tip / roll / impulse / fx / sfx / npc / kill), and *blockers* (something the player moved, unplugged,
braked, pinned...). Physics is presentation only, so a rolling tire can never miss its target or soft-lock the
level. When a step is blocked its `alt` steps reroute the machine ("I stopped it! ...oh no."). The same chain
is replayed in **vision mode** (no deaths, blockers ignored, sped up) as the premonition, then rewound.

## Licence and credits

Code: MIT (see LICENSE). All art, audio and dialogue are original and generated procedurally; the voices are
synthesised with Kokoro-82M (Apache-2.0). Full attributions are in `credits/THIRD_PARTY.md` and in the in-game credits.
