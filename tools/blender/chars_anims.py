"""Procedural humanoid animation set. Angles in degrees about armature-space axes.

Axis cheat sheet (character faces +Y, +X is the character's RIGHT):
  limbs pointing down : +rx swings forward, ry = -abduction for right arm, +abduction for left arm
  spine/head (up)     : -rx leans/looks forward, +rz turns left
  knee                : rx negative bends the shin backwards
"""
import math
from chars_lib import ActionBuilder, ANIM_BONES

S = math.sin
C = math.cos
TAU = 2 * math.pi


def arm(side, fwd=0.0, out=0.0, elbow=0.0, twist=0.0, roll=0.0, hand=None, curl=0.0, thumb=0.0):
    s = 1 if side == "R" else -1
    d = {
        f"UpperArm.{side}": (fwd, -s * out, twist),
        f"LowerArm.{side}": (elbow, 0, roll * s),
        f"Fingers.{side}": (0, -s * curl, 0),
        f"Thumb.{side}": (0, -s * thumb, 0),
    }
    if hand is not None:
        d[f"Hand.{side}"] = hand
    return d


def leg(side, fwd=0.0, knee=0.0, out=0.0, flat=True, foot=0.0, toe=0.0):
    s = 1 if side == "R" else -1
    f = (knee - fwd) if flat else foot
    return {f"UpperLeg.{side}": (fwd, -s * out * 0.0, s * out), f"LowerLeg.{side}": (-knee, 0, 0), f"Foot.{side}": (f, 0, 0), f"Toes.{side}": (toe, 0, 0)}


def M(*dicts):
    out = {}
    for d in dicts:
        out.update(d)
    return out


def relaxed_arms(t=0.0, sway=0.0):
    return M(arm("R", 4 + sway, 6, 8, curl=18, thumb=6), arm("L", 4 - sway, 6, 8, curl=18, thumb=6))


def walk(t, f):
    p = t * TAU
    thR = 27 * S(p)
    thL = -thR
    kR = 38 * max(0.0, C(p)) ** 1.3 + 6
    kL = 38 * max(0.0, -C(p)) ** 1.3 + 6
    return M(
        {"Hips@loc": (0, 0, 0.014 * C(2 * p) - 0.01), "Hips": (0, 0, 4 * S(p)), "Spine": (-3, 0, -3 * S(p)), "Chest": (0, 0, -3 * S(p)), "Head": (0, 0, 2 * S(p))},
        leg("R", thR, kR), leg("L", thL, kL),
        arm("R", -22 * S(p), 5, 14 + 10 * max(0, -S(p)), curl=25), arm("L", 22 * S(p), 5, 14 + 10 * max(0, S(p)), curl=25))


def run(t, f):
    p = t * TAU
    thR = 52 * S(p)
    thL = -thR
    kR = 85 * max(0.0, C(p)) ** 1.2 + 10
    kL = 85 * max(0.0, -C(p)) ** 1.2 + 10
    return M(
        {"Hips@loc": (0, 0, 0.05 * abs(C(p)) - 0.03), "Hips": (0, 0, 6 * S(p)), "Spine": (-11, 0, -6 * S(p)), "Chest": (-4, 0, -6 * S(p)), "Head": (8, 0, 3 * S(p))},
        leg("R", thR, kR), leg("L", thL, kL),
        arm("R", -55 * S(p), 6, 85, curl=60), arm("L", 55 * S(p), 6, 85, curl=60))


def idle(t, f):
    p = t * TAU
    return M(
        {"Hips@loc": (0.006 * S(p), 0, -0.004 * (1 - C(2 * p))), "Hips": (0, 0, 1.2 * S(p)), "Spine": (0.5 * S(2 * p), 0, -1 * S(p)), "Chest": (-1.2 * S(2 * p), 0, 0), "Head": (1.2 * S(p + 1), 0, 2 * S(p))},
        leg("R", 1.5 * S(p), 2), leg("L", -1.5 * S(p), 2), relaxed_arms(t, 1.5 * S(2 * p)))


def idle_look(t, f):
    p = t * TAU
    d = idle(t, f)
    d["Head"] = (2 * S(3 * p), 0, 32 * S(p))
    d["Neck"] = (0, 0, 8 * S(p))
    return d


def talk_a(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("R", 40 + 22 * S(2 * p), 22, 72 + 14 * S(4 * p), twist=-10, curl=10, thumb=10))
    d.update(arm("L", 8, 10, 18))
    d["Head"] = (2 * S(4 * p), 0, 5 * S(2 * p))
    d["Chest"] = (0, 0, 3 * S(2 * p))
    return d


def talk_b(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("R", 32 + 14 * S(3 * p), 28, 60 + 10 * S(2 * p), twist=-14, curl=8))
    d.update(arm("L", 32 + 14 * S(3 * p + 1), 28, 60 + 10 * S(2 * p + 2), twist=14, curl=8))
    d["Head"] = (1, 0, 4 * S(p))
    return d


def talk_c(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("R", 70, 5, 20 + 10 * S(3 * p), curl=70, thumb=-10))
    d["Head"] = (2, 0, -4 * S(2 * p))
    return d


def talk_calm(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("R", 30 + 8 * S(p), 16, 55, twist=-8, curl=12))
    d["Head"] = (1.5 * S(2 * p), 0, 2 * S(p))
    return d


def argue(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("R", 50 + 35 * S(3 * p), 30, 65, curl=10))
    d.update(arm("L", 50 + 35 * S(3 * p + 2), 30, 65, curl=10))
    d["Chest"] = (0, 0, 6 * S(3 * p))
    d["Head"] = (0, 0, 8 * S(3 * p + 1))
    return d


def panic_idle(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("R", 120 + 4 * S(9 * p), 30, 100, curl=40))
    d.update(arm("L", 120 + 4 * S(9 * p + 1), 30, 100, curl=40))
    d["Head"] = (-6, 0, 6 * S(5 * p))
    d["Spine"] = (-6, 0, 0)
    d["Hips@loc"] = (0.004 * S(11 * p), 0, -0.02)
    return d


def panic_run(t, f):
    p = t * TAU
    d = run(t, f)
    d.update(arm("R", 130 + 30 * S(p), 40, 30, curl=30))
    d.update(arm("L", 130 - 30 * S(p), 40, 30, curl=30))
    d["Head"] = (5, 0, 10 * S(p))
    return d


def point(t, f):
    d = idle(t, f)
    d.update(arm("R", 92, 10, 4, curl=90, thumb=-10))
    d["Fingers.R"] = (0, 0, 0)
    d["Head"] = (0, 0, -6)
    return d


def wave(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("R", 20, 110, 80 + 12 * S(3 * p), curl=6))
    return d


def sit_idle(t, f):
    p = t * TAU
    d = M(
        {"Hips@loc": (0, -0.02, -0.5), "Hips": (0, 0, 0.5 * S(p)), "Spine": (-4, 0, 0), "Chest": (1 - 1.2 * S(2 * p), 0, 0), "Head": (3, 0, 2 * S(p))},
        leg("R", 88, 90, out=4), leg("L", 88, 90, out=4),
        arm("R", 30, 12, 60, curl=25), arm("L", 30, 12, 60, curl=25))
    return d


def sit_slump(t, f):
    d = sit_idle(t, f)
    d["Spine"] = (-22, 0, 0)
    d["Head"] = (-16, 0, 0)
    d.update(arm("R", 20, 10, 30, curl=15))
    d.update(arm("L", 20, 10, 30, curl=15))
    return d


def sit_talk(t, f):
    p = t * TAU
    d = sit_idle(t, f)
    d.update(arm("R", 45 + 20 * S(2 * p), 30, 78, curl=8))
    d["Head"] = (2 * S(4 * p), 0, 6 * S(2 * p))
    return d


def crouch_idle(t, f):
    p = t * TAU
    return M({"Hips@loc": (0, -0.14, -0.5), "Spine": (-30, 0, 0), "Chest": (-12, 0, 0), "Head": (14, 0, 0)},
             leg("R", 100, 128, out=6), leg("L", 100, 128, out=6),
             arm("R", 55, 8, 60, curl=30), arm("L", 55, 8, 60, curl=30))


def hands_hips(t, f):
    d = idle(t, f)
    d.update(arm("R", -10, 38, 100, curl=40))
    d.update(arm("L", -10, 38, 100, curl=40))
    return d


def arms_cross(t, f):
    d = idle(t, f)
    d.update(arm("R", 50, -12, 118, twist=-40, curl=50))
    d.update(arm("L", 50, -12, 118, twist=40, curl=50))
    return d


def shrug(t, f):
    s = S(t * math.pi)
    d = idle(t, f)
    d.update(arm("R", 20, 40 * s, 60 * s, curl=10))
    d.update(arm("L", 20, 40 * s, 60 * s, curl=10))
    d["Shoulder.R"] = (0, 0, 0)
    d["Head"] = (0, 0, 8 * s)
    return d


def facepalm(t, f):
    a = min(1.0, S(t * math.pi) * 2.5)
    d = idle(t, f)
    d.update(arm("R", 60 + 45 * a, 8, 40 + 100 * a, curl=20))
    d["Head"] = (-15 * a, 0, 0)
    return d


def cheer(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("R", 160, 25, 20 + 10 * S(4 * p), curl=20))
    d.update(arm("L", 160, 25, 20 + 10 * S(4 * p + 1), curl=20))
    d["Hips@loc"] = (0, 0, 0.03 * abs(S(2 * p)))
    return d


def victory_fist(t, f):
    d = idle(t, f)
    d.update(arm("R", 150, 20, 70, curl=90, thumb=30))
    return d


def phone_film(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("R", 78, 8, 100, curl=40, thumb=15))
    d.update(arm("L", 40, 10, 80, curl=30))
    d["Head"] = (2 * S(p), 0, 2 * S(2 * p))
    return d


def phone_ear(t, f):
    d = idle(t, f)
    d.update(arm("R", 110, 30, 130, curl=45))
    d["Head"] = (0, 0, -6)
    return d


def check_watch(t, f):
    d = idle(t, f)
    d.update(arm("L", 60, 0, 100, curl=20))
    d["Head"] = (-10, 0, 0)
    return d


def clipboard(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("L", 50, -10, 100, curl=30))
    d.update(arm("R", 65 + 3 * S(6 * p), 4, 95, curl=60))
    d["Head"] = (-9, 0, 0)
    return d


def work_reach(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("R", 150 + 4 * S(3 * p), 8, 20, twist=6 * S(4 * p), curl=70))
    d.update(arm("L", 20, 14, 30))
    d["Spine"] = (5, 0, 0)
    d["Head"] = (10, 0, 0)
    return d


def work_low(t, f):
    p = t * TAU
    d = crouch_idle(t, f)
    d.update(arm("R", 65 + 6 * S(3 * p), 10, 40, twist=8 * S(4 * p), curl=80))
    d.update(arm("L", 55, 10, 45, curl=40))
    return d


def pickup(t, f):
    a = S(t * math.pi)
    d = idle(t, f)
    d["Spine"] = (-50 * a, 0, 0)
    d["Chest"] = (-14 * a, 0, 0)
    d["Hips@loc"] = (0, -0.08 * a, -0.16 * a)
    d.update(leg("R", 45 * a, 60 * a))
    d.update(leg("L", 45 * a, 60 * a))
    d.update(arm("R", 90 * a + 4, 6, 20, curl=70 * a))
    d.update(arm("L", 90 * a + 4, 6, 20, curl=70 * a))
    return d


def push(t, f):
    p = t * TAU
    d = walk(t, f)
    d.update(arm("R", 78, 6, 12, curl=20))
    d.update(arm("L", 78, 6, 12, curl=20))
    d["Spine"] = (-14, 0, 0)
    return d


def throw(t, f):
    a = S(t * math.pi)
    d = idle(t, f)
    d.update(arm("R", 170 * (1 - t) if t < 0.5 else 170 * (1 - t) - 30, 20, 60 * (1 - t), curl=10))
    d["Spine"] = (12 * a, 0, -20 * a)
    return d


def eat(t, f):
    p = t * TAU
    a = 0.5 + 0.5 * S(2 * p)
    d = idle(t, f)
    d.update(arm("R", 95 + 25 * a, 15, 105 + 25 * a, curl=50))
    d["Head"] = (-4 * a, 0, 0)
    return d


def dodge_left(t, f):
    a = S(t * math.pi)
    d = idle(t, f)
    d["Hips@loc"] = (-0.35 * a, 0, -0.1 * a)
    d["Spine"] = (0, 12 * a, 14 * a)
    d.update(arm("R", 90 * a, 60 * a, 40 * a))
    d.update(arm("L", 90 * a, 60 * a, 40 * a))
    d.update(leg("R", 10 * a, 20 * a)); d.update(leg("L", 35 * a, 40 * a))
    return d


def dodge_right(t, f):
    d = dodge_left(t, f)
    d["Hips@loc"] = (-d["Hips@loc"][0], 0, d["Hips@loc"][2])
    d["Spine"] = (0, -d["Spine"][1], -d["Spine"][2])
    return d


def stagger(t, f):
    p = t * TAU
    a = S(t * math.pi)
    d = idle(t, f)
    d["Spine"] = (12 * a, 0, 10 * S(p))
    d["Hips@loc"] = (0.05 * S(p), -0.12 * a, 0)
    d.update(arm("R", 60 * a, 70 * a, 30)); d.update(arm("L", 60 * a, 70 * a, 30))
    d.update(leg("R", -20 * a, 25 * a)); d.update(leg("L", 22 * a, 10 * a))
    return d


def stand_up_from_lie(t, f):
    # inverse of death_back, ease back to standing
    u = 1 - min(1.0, t * 1.2)
    return {"Hips": (90 * u, 0, 0), "Hips@loc": (0, 0, -0.84 * u)}


def _lie(sign):
    def fn(t, f):
        e = min(1.0, t * 1.4)
        e = e * e * (3 - 2 * e)
        a = 90 * sign * e
        wob = 1 - e
        d = {"Hips": (a, 0, 6 * S(t * 9) * wob), "Hips@loc": (0, -0.05 * e * sign * -1, -0.84 * e), "Spine": (-6 * e * sign * 0.3, 0, 0), "Head": (-8 * sign * e * 0.2, 0, 0)}
        d.update(arm("R", 60 * wob + 20, 90 * e, 25, curl=30))
        d.update(arm("L", 60 * wob + 20, 90 * e, 25, curl=30))
        d.update(leg("R", 12 * e, 10 * e, flat=False))
        d.update(leg("L", -6 * e, 14 * e, flat=False))
        return d
    return fn


death_back = _lie(1)
death_front = _lie(-1)


def slip(t, f):
    # feet fly forward, land on back
    e = min(1.0, t * 1.6)
    e = e * e * (3 - 2 * e)
    d = {"Hips": (80 * e, 0, 0), "Hips@loc": (0, 0, -0.78 * e + 0.25 * S(min(1.0, t * 2.2) * math.pi) * (1 - e * 0.6))}
    d.update(arm("R", 140 * (1 - e) + 20, 60, 10, curl=10)); d.update(arm("L", 140 * (1 - e) + 20, 60, 10, curl=10))
    d.update(leg("R", 50 * (1 - e) + 10, 10, flat=False)); d.update(leg("L", 30 * (1 - e) + 4, 30, flat=False))
    return d


def lie_idle(t, f):
    p = t * TAU
    d = death_back(1.0, 30)
    d["Chest"] = (-1.5 * S(p), 0, 0)
    return d


def scared_cower(t, f):
    p = t * TAU
    d = crouch_idle(t, f)
    d.update(arm("R", 130, 20, 130, curl=60)); d.update(arm("L", 130, 20, 130, curl=60))
    d["Head"] = (-20, 0, 0)
    d["Hips@loc"] = (0.004 * S(13 * p), -0.14, -0.52)
    return d


def shake_head(t, f):
    p = t * TAU
    d = idle(t, f)
    d["Head"] = (0, 0, 22 * S(2 * p))
    return d


def nod(t, f):
    p = t * TAU
    d = idle(t, f)
    d["Head"] = (-12 * S(2 * p), 0, 0)
    return d


def flail(t, f):
    p = t * TAU
    d = idle(t, f)
    d.update(arm("R", 140 * S(p), 80 + 30 * S(2 * p), 20))
    d.update(arm("L", 140 * S(p + 2), 80 + 30 * S(2 * p + 1), 20))
    d["Spine"] = (6 * S(p), 6 * S(p), 8 * S(p))
    d.update(leg("R", 40 * S(p), 30)); d.update(leg("L", 40 * S(p + 3), 30))
    return d


def hold_cup(t, f):
    d = idle(t, f)
    d.update(arm("R", 70, 6, 105, curl=50, thumb=12))
    return d


def carry(t, f):
    p = t * TAU
    d = walk(t, f)
    d.update(arm("R", 60, 6, 80, curl=60)); d.update(arm("L", 60, 6, 80, curl=60))
    return d


def sweat_wipe(t, f):
    d = idle(t, f)
    d.update(arm("R", 120, 15, 130 - 20 * S(t * TAU * 2), curl=20))
    return d


def wink_thumbs(t, f):
    d = idle(t, f)
    d.update(arm("R", 60, 20, 90, curl=90, thumb=-40))
    return d


def sit_ground(t, f):
    p = t * TAU
    return M({"Hips@loc": (0, 0, -0.86), "Spine": (-8, 0, 0), "Head": (2, 0, 0)},
             leg("R", 92, 22, out=15, flat=False), leg("L", 92, 22, out=15, flat=False),
             arm("R", 28, 8, 40, curl=30), arm("L", 28, 8, 40, curl=30))


def sit_ground_hug(t, f):
    p = t * TAU
    d = sit_ground(t, f)
    d.update(arm("R", 50, 10, 90, twist=-20, curl=50)); d.update(arm("L", 50, 10, 90, twist=20, curl=50))
    d["Spine"] = (-14, 0, 0)
    return d


ACTIONS = [
    ("idle", 90, idle, True), ("idle_look", 90, idle_look, True), ("walk", 30, walk, True), ("run", 20, run, True),
    ("talk_a", 72, talk_a, True), ("talk_b", 72, talk_b, True), ("talk_c", 60, talk_c, True), ("talk_calm", 90, talk_calm, True),
    ("argue", 45, argue, True), ("panic_idle", 45, panic_idle, True), ("panic_run", 20, panic_run, True),
    ("point", 30, point, True), ("wave", 45, wave, True), ("sit_idle", 90, sit_idle, True), ("sit_slump", 90, sit_slump, True),
    ("sit_talk", 72, sit_talk, True), ("crouch_idle", 60, crouch_idle, True), ("hands_hips", 60, hands_hips, True),
    ("arms_cross", 60, arms_cross, True), ("shrug", 40, shrug, False), ("facepalm", 50, facepalm, False),
    ("cheer", 40, cheer, True), ("victory_fist", 40, victory_fist, True), ("phone_film", 60, phone_film, True),
    ("phone_ear", 60, phone_ear, True), ("check_watch", 60, check_watch, True), ("clipboard", 60, clipboard, True),
    ("work_reach", 45, work_reach, True), ("work_low", 45, work_low, True), ("pickup", 30, pickup, False),
    ("push", 30, push, True), ("throw", 24, throw, False), ("eat", 60, eat, True), ("dodge_left", 20, dodge_left, False),
    ("dodge_right", 20, dodge_right, False), ("stagger", 30, stagger, False), ("death_back", 40, death_back, False),
    ("death_front", 40, death_front, False), ("slip", 30, slip, False), ("lie_idle", 90, lie_idle, True),
    ("scared_cower", 45, scared_cower, True), ("shake_head", 45, shake_head, False), ("nod", 40, nod, False),
    ("flail", 24, flail, True), ("hold_cup", 90, hold_cup, True), ("carry", 30, carry, True), ("sweat_wipe", 60, sweat_wipe, True),
    ("thumbs_up", 60, wink_thumbs, True), ("sit_ground", 90, sit_ground, True), ("sit_ground_hug", 90, sit_ground_hug, True),
    ("stand_up", 40, stand_up_from_lie, False),
]


def build_all(arm_obj):
    ab = ActionBuilder(arm_obj)
    for name, frames, fn, loop in ACTIONS:
        ab.make(name, frames, fn, loop)
    return ab
