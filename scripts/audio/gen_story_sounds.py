# Generates the STORY mode sounds (the BEN: offices, corridor, open space, archives, interrogation room)
# into ScreenshotKit/Sources/ScreenshotUI/Resources/Sounds. Everything is synthesised: no third-party audio,
# no music, no stinger. It writes only the files named below; the other sounds come from gen_sounds.py,
# which this script never touches.
#   python3 scripts/audio/gen_story_sounds.py
#
# Same approach as gen_sounds.py, whose helpers are copied here (that script generates its sounds when
# imported). Format: WAV, mono, 16-bit PCM like the existing files. One-shots at 22.05 kHz, the rate of
# the existing sounds; ambience loops at 11.025 kHz (dark, low content that needs no more), so six loops
# of 10–20 s stay light.
# Loops are seamless: noise beds are crossfaded into their own start (env_loop, equal power), tones have a
# whole number of cycles per loop, filters and reverbs run circularly and events wrap around the end.
# Levels are set here, not by peak normalisation: ambiences sit very low (RMS target), effects are dry and
# restrained (loudest 50 ms target); see docs/design_story/TRANSITIONS.md §5.
# Deterministic: each sound reseeds the generator from its own name, so changing one never changes another.
import math, os, random, struct, wave, zlib

FX_RATE = 22050   # one-shots: the rate of every existing sound
AMB_RATE = 11025  # ambience loops
RATE = FX_RATE
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "ScreenshotKit", "Sources", "ScreenshotUI", "Resources", "Sounds")
os.makedirs(OUT, exist_ok=True)

# Files owned by gen_sounds.py: never overwritten from here.
EXISTING = {"street", "sirens", "crowd", "vibrate", "notification", "unlock", "key", "tick", "sting", "metro", "chime",
            "train", "room", "sea", "gulls", "hall", "powerdown", "rain", "engine", "ring", "stamp", "paper", "folder",
            "typewriter"}


def use(name, rate):
    """Starts a sound: its sample rate and its own fixed seed."""
    global RATE
    RATE = rate
    random.seed(zlib.crc32(("story/" + name).encode()))

# ---- Helpers copied from gen_sounds.py (write gains a level target and edge fades) --------------------

def write(name, samples, rms_db=None, loud_db=None):
    # Level in dBFS: rms_db = RMS of the whole file (loops), loud_db = loudest 50 ms window (one-shots).
    # Never above the existing files' peak (0.89).
    assert name not in EXISTING, name
    peak = max(1e-9, max(abs(s) for s in samples))
    if rms_db is not None:
        gain = 10 ** (rms_db / 20) / max(1e-12, rms(samples))
    elif loud_db is not None:
        gain = 10 ** (loud_db / 20) / max(1e-12, loudest(samples))
    else:
        gain = 0.89 / peak
    gain = min(gain, 0.89 / peak)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32767)) for s in samples))
    print(name, f"{len(samples) / RATE:.1f} s", f"{RATE} Hz")

def lowpass(x, cutoff):
    a = math.exp(-2 * math.pi * cutoff / RATE); y = 0.0; out = []
    for s in x:
        y = (1 - a) * s + a * y; out.append(y)
    return out

def highpass(x, cutoff):
    lp = lowpass(x, cutoff)
    return [a - b for a, b in zip(x, lp)]

def noise(n):
    return [random.uniform(-1, 1) for _ in range(n)]

def brown(n):
    y = 0.0; out = []
    for _ in range(n):
        y = max(-1, min(1, y + random.uniform(-0.04, 0.04))); out.append(y)
    return out

def env_loop(x, fade=0.4, equal_power=False):
    # Crossfade the end into the start so the loop is seamless. Equal power keeps the level of
    # uncorrelated noise constant across the seam (a linear fade dips by 3 dB in the middle).
    n = int(fade * RATE); out = x[:len(x) - n]
    for i in range(n):
        t = i / n
        if equal_power:
            out[i] = out[i] * math.sin(math.pi / 2 * t) + x[len(x) - n + i] * math.cos(math.pi / 2 * t)
        else:
            out[i] = out[i] * t + x[len(x) - n + i] * (1 - t)
    return out

def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] if i < len(t) else 0 for t in tracks) for i in range(n)]

def echo(x, delay, decay, times=3):
    out = list(x); d = int(delay * RATE)
    for k in range(1, times + 1):
        for i in range(len(x)):
            j = i + d * k
            if j < len(out): out[j] += x[i] * (decay ** k)
    return out

# ---- More helpers ---------------------------------------------------------------------------------

def rms(x):
    return math.sqrt(sum(s * s for s in x) / max(1, len(x)))

def loudest(x, win=0.05):
    # RMS of the loudest window (hop of 10 ms).
    w = max(1, int(win * RATE)); hop = max(1, int(0.01 * RATE))
    acc = [0.0]
    for s in x: acc.append(acc[-1] + s * s)
    best = 0.0
    for i in range(0, max(1, len(x) - w + 1), hop):
        j = min(len(x), i + w)
        best = max(best, (acc[j] - acc[i]) / max(1, j - i))
    return math.sqrt(best)

def gain(x, g):
    return [s * g for s in x]

def at_rms(x, db):
    return gain(x, 10 ** (db / 20) / max(1e-12, rms(x)))

def at_peak(x, db):
    return gain(x, 10 ** (db / 20) / max(1e-12, max(abs(s) for s in x)))

def silence(sec):
    return [0.0] * int(sec * RATE)

def add(buf, x, at, g=1.0, wrap=False):
    # Adds x into buf at `at` seconds; with wrap, what passes the end comes back at the start (loops).
    i0 = int(at * RATE); n = len(buf)
    for i, s in enumerate(x):
        j = i0 + i
        if wrap: j %= n
        elif j >= n: break
        buf[j] += s * g
    return buf

def shape(x, fn):
    n = len(x)
    return [s * fn(i / n) for i, s in enumerate(x)]

def bell(t):
    return math.sin(math.pi * t) ** 2

def edges(x, fade_in=0.002, fade_out=0.012):
    # One-shots carry no DC and start and end on silence (no click at either end).
    n_in = max(1, int(fade_in * RATE)); n_out = max(1, int(fade_out * RATE)); out = highpass(x, 20)
    for i in range(min(n_in, len(out))): out[i] *= i / n_in
    for i in range(min(n_out, len(out))): out[-1 - i] *= i / n_out
    return out

def biquad(x, kind, f, q=0.707):
    # RBJ cookbook filter: "lp", "hp" or "bp" (band-pass, 0 dB at the centre).
    w = 2 * math.pi * min(f, RATE * 0.45) / RATE; c = math.cos(w); al = math.sin(w) / (2 * q)
    if kind == "bp": b0, b1, b2 = al, 0.0, -al
    elif kind == "lp": b0, b1, b2 = (1 - c) / 2, 1 - c, (1 - c) / 2
    else: b0, b1, b2 = (1 + c) / 2, -(1 + c), (1 + c) / 2
    a0 = 1 + al; a1 = -2 * c / a0; a2 = (1 - al) / a0; b0 /= a0; b1 /= a0; b2 /= a0
    x1 = x2 = y1 = y2 = 0.0; out = []
    for s in x:
        y = b0 * s + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = s; y2 = y1; y1 = y
        out.append(y)
    return out

def burst(dur, lo, hi, decay, amp=1.0):
    # A band of noise that dies away (clicks, contacts, rubs).
    x = noise(int(dur * RATE))
    if hi: x = lowpass(lowpass(x, hi), hi)
    if lo: x = highpass(x, lo)
    return [s * amp * math.exp(-decay * i / RATE) for i, s in enumerate(x)]

def modal(dur, modes):
    # An object struck once: damped sines (frequency Hz, decay per second, amplitude).
    n = int(dur * RATE); out = [0.0] * n
    for f, d, a in modes:
        if f >= RATE / 2: continue
        w = 2 * math.pi * f / RATE; k = math.exp(-d / RATE); g = a
        for i in range(n):
            out[i] += g * math.sin(w * i); g *= k
    return out

def reverb(x, rt=0.8, damp=3000.0):
    # A small Schroeder room (damped parallel combs, two allpasses): the wet signal only.
    n = len(x); wet = [0.0] * n; a = math.exp(-2 * math.pi * damp / RATE)
    for ms in (29.7, 37.1, 41.1, 43.7):
        d = max(1, int(ms * RATE / 1000)); g = 10 ** (-3 * ms / 1000 / rt); y = [0.0] * n; lp = 0.0
        for i in range(n):
            if i >= d:
                lp = (1 - a) * y[i - d] + a * lp
                y[i] = x[i - d] + g * lp
            wet[i] += y[i]
    for ms in (5.0, 1.7):
        d = max(1, int(ms * RATE / 1000)); out = [0.0] * n
        for i in range(n):
            out[i] = -0.7 * wet[i] + (wet[i - d] + 0.7 * out[i - d] if i >= d else 0.0)
        wet = out
    return [w * 0.25 for w in wet]

def circular(fn, x):
    # Runs a filter or a reverb on a loop as if it repeated forever (its tail wraps into its start).
    n = len(x)
    return fn(x + x)[n:]

def loop_noise(T, make, fade=1.5):
    # A noise layer of T seconds with no seam: made `fade` seconds longer, then its tail is crossfaded
    # (equal power) into its start.
    return env_loop(make(int(T * RATE) + int(fade * RATE)), fade, equal_power=True)

def periodic(T, parts):
    # Steady tones (frequency, amplitude, phase), each with a whole number of cycles in the loop.
    n = int(T * RATE); out = [0.0] * n
    for f, a, ph in parts:
        assert abs(f * T - round(f * T)) < 1e-6, (f, T)
        w = 2 * math.pi * f / RATE
        for i in range(n): out[i] += a * math.sin(w * i + ph)
    return out

def rel(x, ref, db):
    # Scales an event so that its peak sits `db` above (or below) the RMS of the bed `ref`.
    return at_peak(x, 20 * math.log10(max(1e-12, rms(ref))) + db)

# ---- Shared sources -------------------------------------------------------------------------------

def hvac_bed(T):
    # Office air conditioning: a steady low broadband hum, a narrow fan whirr, the hiss of the
    # diffusers, a faint mains hum (50 Hz and harmonics); the fan "breathes" very slightly.
    rumble = loop_noise(T, lambda n: highpass(highpass(lowpass(lowpass(noise(n), 260), 260), 45), 45))
    whirr = loop_noise(T, lambda n: biquad(noise(n), "bp", 170, 6))
    air = loop_noise(T, lambda n: highpass(lowpass(noise(n), 2600), 700))
    mains = periodic(T, [(50, 1.0, 0.0), (100, 0.7, 1.3), (150, 0.3, 2.1)])
    bed = mix(at_rms(rumble, 0), at_rms(whirr, -17), at_rms(air, -16))
    n = len(bed)
    breath = [1 + 0.04 * math.sin(2 * math.pi * i / n) + 0.02 * math.sin(6 * math.pi * i / n + 1) for i in range(n)]
    return mix([b * m for b, m in zip(bed, breath)], at_rms(mains, -22))

def city(T, swell=0.25):
    # The city at night behind a closed window: a low rumble and a slow wash of far traffic.
    rumble = loop_noise(T, lambda n: highpass(highpass(lowpass(lowpass(brown(n), 140), 140), 28), 28))
    wash = loop_noise(T, lambda n: highpass(lowpass(lowpass(noise(n), 420), 420), 60))
    n = len(wash)
    wash = [w * (1 - swell + swell * math.sin(2 * math.pi * 2 * i / n + 0.5)) for i, w in enumerate(wash)]
    return mix(at_rms(rumble, 0), at_rms(wash, -8))

def far_car(dur, bright=520.0):
    # A car passing far away behind the window: tyres and engine as a soft band of noise that swells
    # and fades, a little brighter while it approaches.
    n = int(dur * RATE); y1 = y2 = 0.0; out = []
    for i, s in enumerate(noise(n)):
        t = i / n
        a = math.exp(-2 * math.pi * bright * (1.25 - 0.5 * t) / RATE)
        y1 = (1 - a) * s + a * y1; y2 = (1 - a) * y1 + a * y2
        out.append(y2 * math.sin(math.pi * t ** 0.9) ** 3)
    return highpass(out, 70)

def keystroke(space=False):
    # An office keyboard key: press click, dull bottom-out, softer release.
    out = silence(0.12)
    press = mix(at_peak(modal(0.03, [(random.uniform(2300, 3100), 520, 1.0), (random.uniform(4200, 5200), 700, 0.45)]), 0),
                at_peak(burst(0.005, 1200, 9000, 1500), -2))
    low = (170, 360) if space else (random.uniform(330, 420), random.uniform(780, 950))
    bottom = at_peak(modal(0.04, [(low[0], 160, 1.0), (low[1], 220, 0.4)]), 0 if space else -3)
    add(out, press, 0, 0.8)
    add(out, bottom, 0.004, 1.0)
    add(out, at_peak(modal(0.02, [(random.uniform(2600, 3400), 600, 1.0)]), -9), random.uniform(0.055, 0.085))
    if space:  # the stabiliser bar rattles a little
        for t in (0.009, 0.017):
            add(out, at_peak(modal(0.01, [(random.uniform(3500, 4500), 900, 1.0)]), -12), t)
    return out

def typing(keys, pause_after=None, space_at=None):
    t = 0.01; times = []
    for k in range(keys):
        times.append((t, k == space_at))
        t += random.uniform(0.075, 0.16) + (0.2 if k == pause_after else 0)
    out = silence(t + 0.15)
    for tk, sp in times:
        add(out, keystroke(sp), tk, random.uniform(0.65, 1.0))
    return out

def printer_page():
    # A laser printer feeding one page (1.8 s): motor and gears spin up, the pick-up clutch clacks,
    # the sheet runs through the rollers, comes out and settles in the tray, the motor spins down.
    n = int(1.8 * RATE); out = [0.0] * n

    def speed(t):
        return min(1.0, t / 0.15) * max(0.0, min(1.0, (1.8 - t) / 0.25))
    p1 = p2 = 0.0; motor = []
    for i in range(n):
        t = i / RATE; v = speed(t); k = 0.35 + 0.65 * v
        p1 += 2 * math.pi * 118 * k / RATE; p2 += 2 * math.pi * 790 * k / RATE
        motor.append(v * (math.sin(p1) + 0.45 * math.sin(2 * p1) + 0.2 * math.sin(3 * p1))
                     + v * 0.18 * math.sin(p2) * (1 + 0.3 * math.sin(2 * math.pi * 23 * t)))
    add(out, at_peak(motor, -9), 0)
    fan = lowpass(lowpass(noise(n), 900), 900)
    add(out, at_peak([f * min(1.0, i / (0.2 * RATE)) * min(1.0, (n - i) / (0.2 * RATE)) for i, f in enumerate(fan)], -16), 0)
    clutch = mix(modal(0.08, [(1250, 120, 1.0), (2980, 180, 0.6), (260, 70, 0.7)]), burst(0.012, 400, 7000, 350, 0.8))
    add(out, at_peak(clutch, -2), 0.2)
    L = int(1.1 * RATE)
    sheet = highpass(lowpass(noise(L), 5200), 900)
    sheet = [s * (1 + 0.3 * math.sin(2 * math.pi * 13 * i / RATE)) * min(1.0, i / (0.06 * RATE)) * min(1.0, (L - i) / (0.1 * RATE))
             for i, s in enumerate(sheet)]
    add(out, at_peak(sheet, -9), 0.28)
    add(out, at_peak(shape(highpass(lowpass(noise(int(0.18 * RATE)), 7000), 1500), bell), -7), 1.30)
    add(out, at_peak(mix(burst(0.05, 150, 3000, 80), modal(0.05, [(240, 70, 0.4)])), -8), 1.47)
    return out

def chirp(f0, f1, dur, vib=(0.0, 0.0)):
    n = int(dur * RATE); ph = 0.0; out = []
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * t + vib[1] * math.sin(2 * math.pi * vib[0] * i / RATE)
        ph += 2 * math.pi * f / RATE
        out.append(math.sin(ph) * math.sin(math.pi * t) ** 1.5)
    return out

def sparrow(k):
    # k short falling chirps.
    out = []
    for _ in range(k):
        c = chirp(random.uniform(3900, 4300), random.uniform(2800, 3200), random.uniform(0.05, 0.07))
        out += gain(c, random.uniform(0.7, 1.0)) + silence(random.uniform(0.07, 0.12))
    return out

def whistle():
    # A blackbird-like fluted phrase, far.
    return chirp(2100, 2600, 0.12, (28, 40)) + chirp(2600, 2250, 0.18, (28, 40)) + silence(0.05) + chirp(2400, 2000, 0.14, (24, 30))

def voice_phrase(dur, f0):
    # One unintelligible phrase: a buzzy glottal source cut into syllables, each through its own pair
    # of formants, with a falling intonation.
    n = int(dur * RATE); out = [0.0] * n; pos = int(0.02 * RATE); phase = 0.0
    while pos < n - int(0.1 * RATE):
        L = min(int(random.uniform(0.11, 0.26) * RATE), n - pos)
        a = random.uniform(0.35, 1.0); f1 = random.uniform(320, 780); f2 = random.uniform(950, 1900)
        src = []
        for i in range(L):
            t = (pos + i) / n
            f = f0 * (1.1 - 0.2 * t) * (1 + 0.04 * math.sin(2 * math.pi * 3 * (pos + i) / RATE))
            phase += f / RATE; phase -= int(phase)
            src.append(2 * phase - 1 + 0.15 * random.uniform(-1, 1))
        syl = mix(biquad(src, "bp", f1, 4), gain(biquad(src, "bp", f2, 5), 0.6))
        for i in range(L):
            out[pos + i] += syl[i] * a * math.sin(math.pi * i / L) ** 0.8
        pos += L + int(random.choice((0, 0, 0.02, 0.05, 0.12)) * RATE)
    return out

# ---- Ambience loops (11.025 kHz) -------------------------------------------------------------------

# Office air conditioning (BEN corridor, offices, briefing room).
use("ben_hvac", AMB_RATE)
write("ben_hvac", hvac_bed(12), rms_db=-22)

# An office at night: the air conditioning, softer, and the city through the window; now and then a
# far car.
use("ben_office_night", AMB_RATE)
T = 20
night = mix(at_rms(hvac_bed(T), -4), at_rms(city(T), 0))
add(night, rel(far_car(5.5), night, 6), 3.0, wrap=True)
add(night, rel(far_car(4.5, 450), night, 3), 12.4, wrap=True)
write("ben_office_night", night, rms_db=-21)

# The same office at dawn: lighter; one far car, and a few distant birds near the end of the loop.
use("ben_office_dawn", AMB_RATE)
T = 20
dawn = mix(at_rms(hvac_bed(T), -3), at_rms(city(T, 0.15), -3))
add(dawn, rel(far_car(4.5, 480), dawn, 1), 4.6, wrap=True)
birds = silence(T)
for start, call, g in ((14.8, sparrow(3), 1.0), (16.3, whistle(), 0.8), (17.6, sparrow(2), 0.6), (18.7, sparrow(1), 0.45)):
    add(birds, call, start, g)
birds = echo(lowpass(birds, 3200), 0.09, 0.25, 2)
add(dawn, rel(birds, dawn, -10), 0)
write("ben_office_dawn", dawn, rms_db=-22)

# The open space: air conditioning, far voices, a few keyboards, a printer once.
use("ben_openspace", AMB_RATE)
T = 20
room = hvac_bed(T)
voices = silence(T)
for f0, g, phrases in ((115, 1.0, ((0.6, 2.4), (5.9, 1.8), (13.2, 2.6))),
                       (205, 0.8, ((3.3, 1.9), (8.4, 2.2), (16.4, 2.1))),
                       (135, 0.5, ((10.6, 2.8), (18.8, 2.4)))):
    for start, dur in phrases:
        add(voices, voice_phrase(dur, f0), start, g, wrap=True)
voices = circular(lambda v: lowpass(lowpass(highpass(v, 150), 1300), 1300), voices)
voices = mix(gain(voices, 0.6), circular(lambda v: reverb(v, 0.7, 1800), voices))
office = mix(room, at_rms(voices, -8))
keys = silence(T)
for start, count, g in ((1.6, 9, 0.8), (8.3, 13, 1.0), (16.1, 6, 0.55)):
    add(keys, typing(count, pause_after=count // 2), start, g, wrap=True)
keys = circular(lambda k: lowpass(k, 2800), keys)
add(office, rel(keys, office, -2), 0)
printer = lowpass(lowpass(printer_page(), 1600), 1600)
printer = mix(printer, gain(reverb(printer + silence(0.6), 0.6, 1500), 0.8))
add(office, rel(printer, office, -3), 11.2, wrap=True)
write("ben_openspace", office, rms_db=-20)

# The archives in the basement: a lower hum, the faint 100 Hz buzz of a neon, a rare pipe tick.
use("ben_archives", AMB_RATE)
T = 16
low = loop_noise(T, lambda n: highpass(highpass(lowpass(lowpass(noise(n), 150), 150), 30), 30))
air = loop_noise(T, lambda n: highpass(lowpass(noise(n), 1500), 350))
mains = periodic(T, [(50, 1.0, 0.0), (100, 0.5, 0.7)])
neon = periodic(T, [(100, 1.0, 0.0), (200, 0.55, 0.4), (300, 0.4, 1.1), (400, 0.25, 2.0), (500, 0.18, 0.3),
                    (600, 0.1, 1.7), (700, 0.08, 2.6), (900, 0.05, 0.9), (1100, 0.03, 1.9)])
sizzle = loop_noise(T, lambda n: biquad(noise(n), "bp", 2000, 1.0))
sizzle = [s * abs(math.sin(2 * math.pi * 50 * i / RATE)) ** 12 for i, s in enumerate(sizzle)]
basement = mix(at_rms(low, 0), at_rms(air, -20), at_rms(mains, -20), at_rms(neon, -17), at_rms(sizzle, -27))
tick = silence(1.2)
for t, g in ((0.0, 1.0), (0.34, 0.45)):
    add(tick, mix(modal(0.4, [(730, 45, 1.0), (1840, 70, 0.5), (2960, 110, 0.3), (4100, 160, 0.15)]), burst(0.004, 500, 6000, 1500, 0.6)), t, g)
tick = lowpass(tick, 2600)
tick = mix(tick, gain(reverb(tick, 0.6, 2200), 0.9))
add(basement, rel(tick, basement, 1), 9.3, wrap=True)
write("ben_archives", basement, rms_db=-22)

# The interrogation room: near silence; the room tone and the hum of the recording equipment.
use("ben_interrogation", AMB_RATE)
T = 10
tone = loop_noise(T, lambda n: highpass(highpass(lowpass(lowpass(noise(n), 170), 170), 30), 30))
air = loop_noise(T, lambda n: highpass(lowpass(noise(n), 1800), 450))
equipment = periodic(T, [(50, 0.45, 0.0), (100, 1.0, 0.9), (150, 0.5, 2.2), (200, 0.3, 0.4), (250, 0.16, 1.6),
                         (300, 0.12, 2.9), (400, 0.05, 1.2)])
write("ben_interrogation", mix(at_rms(tone, 0), at_rms(air, -17), at_rms(equipment, -9)), rms_db=-26)

# ---- One-shots (22.05 kHz) ------------------------------------------------------------------------

# Footsteps on linoleum, soft soles: five steps along the corridor.
use("steps_lino", FX_RATE)

def footstep(w):
    out = silence(0.24)
    heel = mix(at_peak(modal(0.12, [(110 * random.uniform(0.9, 1.1), 45, 0.8), (260 * random.uniform(0.9, 1.1), 70, 0.5),
                                    (520 * random.uniform(0.9, 1.1), 110, 0.25)]), 0),
               at_peak(burst(0.04, 150, 1600, 110), -1))
    add(out, heel, 0, w)
    t0 = random.uniform(0.055, 0.085)  # the roll to the toe
    toe = mix(at_peak(modal(0.08, [(300, 80, 0.35), (680, 120, 0.2)]), -2), at_peak(burst(0.05, 400, 2600, 90), -3))
    add(out, toe, t0, 0.6 * w)
    add(out, at_peak(shape(burst(0.06, 1500, 5000, 0), bell), 0), t0 + 0.03, 0.1 * w)  # the sole scuffs the lino
    return out

steps = silence(1.85)
for t, w in zip((0.03, 0.42, 0.80, 1.19, 1.57), (0.85, 1.0, 0.9, 1.0, 0.92)):
    add(steps, footstep(w), t + random.uniform(-0.012, 0.012))
steps = mix(steps, gain(reverb(steps, 0.5, 2500), 0.35))
write("steps_lino", edges(steps), loud_db=-15)

# A glass office door opening: the handle, the latch, the pane shivering in its frame, the swing.
use("door_glass", FX_RATE)
door = silence(1.0)
handle = mix(at_peak(modal(0.06, [(2350, 160, 0.6), (3720, 220, 0.4), (5100, 300, 0.25), (820, 90, 0.35)]), 0),
             at_peak(burst(0.01, 800, 8000, 500), -2))
add(door, handle, 0.02, 0.55)
latch = mix(at_peak(modal(0.05, [(2900, 200, 0.5), (4400, 280, 0.3)]), 0), at_peak(burst(0.008, 1500, 9000, 700), -2))
add(door, latch, 0.105, 0.4)
add(door, at_peak(modal(0.35, [(1180, 14, 0.18), (2870, 18, 0.12), (4630, 24, 0.08), (6120, 30, 0.05)]), -16), 0.105)
add(door, at_peak(modal(0.08, [(120, 50, 0.5), (210, 70, 0.3)]), -12), 0.13)  # the seal lets go
swing = highpass(lowpass(lowpass(noise(int(0.75 * RATE)), 700), 700), 80)
add(door, at_peak(shape(swing, lambda t: math.sin(math.pi * min(1.0, t * 1.2)) ** 2 * (1 - 0.3 * t)), -9), 0.16)
door = mix(door, gain(reverb(door, 0.4, 3000), 0.3))
write("door_glass", edges(door), loud_db=-14)

# A solid door closing softly: the air it pushes, the thud of the wood, the latch.
use("door_close", FX_RATE)
close = silence(0.8)
add(close, at_peak(shape(lowpass(lowpass(noise(int(0.24 * RATE)), 450), 450), lambda t: t * t), -10), 0.0)
thud = mix(at_peak(modal(0.4, [(72, 22, 1.0), (138, 28, 0.6), (231, 36, 0.45), (415, 55, 0.3), (690, 90, 0.15)]), 0),
           at_peak(burst(0.03, 100, 1800, 120), -4))
add(close, thud, 0.22)
click = mix(at_peak(modal(0.04, [(2650, 250, 0.4), (4150, 320, 0.25)]), 0), at_peak(burst(0.006, 2000, 9000, 900), -3))
add(close, click, 0.232, 0.5)
add(close, click, 0.256, 0.3)
close = mix(close, gain(reverb(close, 0.45, 2000), 0.35))
write("door_close", edges(close), loud_db=-13)

# An office chair taking someone's weight: a soft thump, the foam, the fabric, the tilt spring creaking.
use("chair", FX_RATE)

def creak(dur, r0, r1, modes):
    # Stick-slip: a train of irregular impulses ringing the mechanism.
    n = int(dur * RATE); imp = [0.0] * n; ph = 0.0
    for i in range(n):
        t = i / n
        ph += (r0 + (r1 - r0) * math.sin(math.pi * t)) / RATE
        if ph >= 1:
            ph -= 1; imp[i] = random.uniform(0.6, 1.0) * math.sin(math.pi * t) ** 0.7
    return mix(*[at_peak(biquad(imp, "bp", f, q), 20 * math.log10(a)) for f, q, a in modes])

chair = silence(0.8)
add(chair, at_peak(modal(0.25, [(68, 22, 0.8), (120, 30, 0.5), (210, 45, 0.3)]), -2), 0.02)
add(chair, at_peak(shape(lowpass(lowpass(noise(int(0.28 * RATE)), 650), 650), lambda t: math.sin(math.pi * t) ** 1.5 * (1 - t)), -6), 0.01)
fabric = biquad(noise(int(0.5 * RATE)), "bp", 2600, 0.8)
grain = [abs(g) for g in lowpass(noise(len(fabric)), 40)]
top = max(grain)
add(chair, at_peak(shape([f * (0.3 + g / top) for f, g in zip(fabric, grain)], bell), -12), 0.03)
add(chair, at_peak(creak(0.34, 55, 130, [(640, 12, 1.0), (1370, 14, 0.6), (2250, 16, 0.35)]), -3), 0.07)
add(chair, at_peak(creak(0.14, 70, 95, [(710, 12, 1.0), (1500, 14, 0.5)]), -9), 0.50)
write("chair", edges(chair), loud_db=-15)

# A wooden desk drawer sliding open: the handle, wood rubbing on wood, the stop, pens rolling inside.
use("drawer", FX_RATE)
drawer = silence(0.9)
add(drawer, at_peak(mix(modal(0.08, [(240, 60, 1.0), (520, 90, 0.5), (1300, 150, 0.25)]), burst(0.01, 300, 5000, 400, 0.6)), -6), 0.0)
L = int(0.6 * RATE)
rub = mix(biquad(noise(L), "bp", 750, 0.9), gain(biquad(noise(L), "bp", 1900, 1.4), 0.6), gain(biquad(noise(L), "bp", 190, 2.5), 0.8))
grain = [abs(g) for g in lowpass(noise(L), 45)]
top = max(grain)

def pull(t):
    return min(1.0, t / 0.25) * (1 - max(0.0, t - 0.7) / 0.3 * 0.8)

add(drawer, at_peak(shape([r * (0.45 + 0.55 * g / top) for r, g in zip(rub, grain)], pull), -3), 0.04)
add(drawer, at_peak(mix(modal(0.2, [(165, 35, 1.0), (330, 50, 0.55), (610, 80, 0.3)]), burst(0.02, 100, 2500, 150, 0.5)), -2), 0.64)
for t, db in ((0.655, -16), (0.672, -18), (0.70, -17), (0.735, -20)):
    add(drawer, at_peak(modal(0.03, [(random.uniform(2800, 4200), 300, 1.0), (random.uniform(5000, 6500), 400, 0.5)]), db), t)
write("drawer", edges(drawer), loud_db=-14)

# One page turned: the corner bends, the sheet swishes over, lands.
use("page", FX_RATE)

def crackle():
    return gain(burst(0.004, 2500, 10000, 1500), random.choice((-1, 1)))

page = silence(0.5)
for _ in range(5):
    add(page, at_peak(crackle(), 0), random.uniform(0.0, 0.07), random.uniform(0.1, 0.3))
L = int(0.3 * RATE)
swish = highpass(lowpass(noise(L), 7500), 1600)
swish = [s * (1 + 0.25 * math.sin(2 * math.pi * 17 * i / RATE)) * ((i / L) / 0.6 if i < 0.6 * L else (1 - i / L) / 0.4) ** 1.5
         for i, s in enumerate(swish)]
add(page, at_peak(swish, -6), 0.05)
for _ in range(10):
    add(page, at_peak(crackle(), 0), random.uniform(0.07, 0.33), random.uniform(0.05, 0.25))
add(page, at_peak(mix(burst(0.06, 200, 3500, 70), modal(0.06, [(210, 60, 0.3)])), -4), 0.35)
write("page", edges(page), loud_db=-17)

# A file slid across a desk: its edge lands, cardboard rubs on the wood, it stops.
use("paper_slide", FX_RATE)
slide = silence(0.6)
add(slide, at_peak(mix(burst(0.03, 150, 2000, 140), modal(0.05, [(190, 70, 0.5)])), -5), 0.0)
L = int(0.5 * RATE)
rub = mix(highpass(lowpass(noise(L), 4800), 650), gain(biquad(noise(L), "bp", 420, 1.2), 0.5))
grain = [abs(g) for g in lowpass(noise(L), 25)]
top = max(grain)

def glide(t):
    return min(1.0, t / 0.16) * (1.0 if t < 0.55 else max(0.0, (1 - t) / 0.45)) ** 1.3

add(slide, at_peak(shape([r * (0.6 + 0.4 * g / top) for r, g in zip(rub, grain)], glide), -3), 0.03)
add(slide, at_peak(burst(0.03, 100, 1200, 120), -10), 0.52)
write("paper_slide", edges(slide), loud_db=-17)

# Handling a plastic evidence bag: crinkles in two gestures over a thin rustle.
use("plastic_bag", FX_RATE)
bag = silence(0.9)
gestures = ((0.02, 0.36, 0.15), (0.44, 0.84, 0.6))

def density(t):
    d = 0.0
    for a, b, p in gestures:
        if a <= t <= b:
            d = max(d, (t - a) / (p - a) if t < p else (b - t) / (b - p))
    return d

for _ in range(420):
    t = random.uniform(0.02, 0.84)
    if random.random() > density(t): continue
    f = random.uniform(1800, 7500); d = random.uniform(900, 2500); a = random.random() ** 2.5
    add(bag, mix(modal(0.012, [(f, d, a), (f * 1.7, d * 1.3, a * 0.5)]), burst(0.002, 2000, None, 3000, a * 0.6)), t)
for _ in range(8):  # a few heavier folds of the thick plastic
    t = random.uniform(0.05, 0.8)
    add(bag, modal(0.02, [(random.uniform(900, 1600), 500, 0.8), (random.uniform(2400, 3200), 700, 0.4)]), t, density(t))
rustle = highpass(lowpass(noise(len(bag)), 8000), 2500)
add(bag, [r * density(i / RATE) * 0.1 for i, r in enumerate(rustle)], 0)
write("plastic_bag", edges(bag), loud_db=-16)

# A neon tube crackling three times over its faint ballast hum.
use("neon_buzz", FX_RATE)
n = int(1.2 * RATE)

MEAN = {p: sum(abs(math.sin(math.pi * k / 400)) ** p for k in range(400)) / 400 for p in (0.3, 0.5)}

def rectified(t, p):
    # The ballast's 100 Hz buzz: a sharpened rectified 50 Hz sine, without its DC.
    return abs(math.sin(2 * math.pi * 50 * t)) ** p - MEAN[p]

steady = [rectified(i / RATE, 0.5) for i in range(n)]
neon = at_peak(shape(steady, lambda t: min(1.0, t / 0.07) * min(1.0, (1 - t) / 0.07)), -30)
for start, dur, level in ((0.04, 0.20, 1.0), (0.38, 0.11, 0.7), (0.62, 0.36, 0.9)):
    m = int(dur * RATE)
    halves = [random.uniform(0.4, 1.0) for _ in range(int(dur * 200) + 2)]  # the arc wavers every half cycle
    buzz = []
    for i in range(m):
        t = i / RATE
        env = min(1.0, t / 0.005) * min(1.0, (dur - t) / 0.015)
        buzz.append(rectified(t, 0.3) * halves[int(t * 200)] * env)
    for _ in range(int(dur * 150)):  # the arc spits
        add(buzz, burst(0.003, 1500, 9000, 2000, random.uniform(0.2, 0.8)), random.uniform(0, dur - 0.004))
    add(buzz, mix(modal(0.02, [(3800, 400, 0.8), (5200, 500, 0.4)]), burst(0.003, 1000, 9000, 1500)), 0)  # the strike
    add(neon, at_peak(lowpass(buzz, 5000), -6 + 20 * math.log10(level)), start)
write("neon_buzz", edges(neon), loud_db=-17)

# The office phones (an electronic two-tone trill through a small loudspeaker).
def ringer(dur, fa=950.0, fb=1250.0, alt=16.0):
    n = int(dur * RATE); ph = 0.0; out = []
    for i in range(n):
        t = i / RATE
        ph += 2 * math.pi * (fa if int(t * alt * 2) % 2 == 0 else fb) / RATE
        out.append(math.tanh(2.2 * math.sin(ph)) * min(1.0, t / 0.006) * min(1.0, (dur - t) / 0.02))
    return out

def speaker(x):
    y = highpass(highpass(x, 350), 350)
    return lowpass(mix(y, gain(biquad(y, "bp", 1650, 2), 0.5)), 5200)

# A landline ringing twice, far down the corridor.
use("phone_distant", FX_RATE)
far = silence(2.0)
for start in (0.0, 0.95):
    add(far, ringer(0.55), start)
far = highpass(lowpass(lowpass(speaker(far), 1500), 1500), 300)
far = mix(gain(echo(far, 0.037, 0.35, 2), 0.35), gain(reverb(far, 1.1, 1800), 1.8))
write("phone_distant", edges(far, 0.002, 0.08), loud_db=-18)

# The desk phone ringing once, close.
use("desk_phone_ring", FX_RATE)
desk = silence(1.5)
add(desk, speaker(ringer(1.1)), 0.02)
desk = mix(desk, gain(reverb(desk, 0.35, 3500), 0.2))
write("desk_phone_ring", edges(desk, 0.002, 0.05), loud_db=-12)

# A short burst of typing on an office keyboard (a pause, a space bar).
use("keyboard", FX_RATE)
kb = silence(1.2)
t = 0.02
for k, step in enumerate((0.10, 0.085, 0.12, 0.095, 0.2, 0.11, 0.085, 0.1, 0.09, 0.0)):
    add(kb, keystroke(k == 4), t + random.uniform(-0.008, 0.008), random.uniform(0.65, 1.0))
    t += step
write("keyboard", edges(kb), loud_db=-16)

# A laser printer feeding one page.
use("printer", FX_RATE)
pr = printer_page()
pr = mix(pr, gain(reverb(pr, 0.4, 3000), 0.2))[:int(1.8 * RATE)]
write("printer", edges(pr, 0.002, 0.05), loud_db=-14)

# The office espresso machine: a click, the vibratory pump's 50 Hz burr, a thin flow, the valve.
use("coffee_machine", FX_RATE)
cm = silence(1.8)
add(cm, at_peak(mix(modal(0.03, [(3100, 400, 1.0), (1450, 250, 0.5)]), burst(0.004, 1500, 9000, 1500)), -8), 0.0)
L = int(1.5 * RATE)
knocks = [0.0] * L
for k in range(int(1.5 * 50)):  # the piston knocks 50 times a second
    j = int(k * RATE / 50)
    if j < L: knocks[j] = random.uniform(0.8, 1.0)
for k in range(int(1.5 * 50)):
    add(knocks, burst(0.004, 200, 6000, 1200, 0.5), k / 50)
bright = mix(at_peak(biquad(knocks, "bp", 960, 6), 0), at_peak(biquad(knocks, "bp", 2100, 6), -4))
dark = mix(at_peak(biquad(knocks, "bp", 185, 4), 0), at_peak(biquad(knocks, "bp", 420, 5), -2))
hum = [math.sin(2 * math.pi * 50 * i / RATE) + 0.5 * math.sin(2 * math.pi * 100 * i / RATE) for i in range(L)]
pump = []
for i in range(L):
    t = i / RATE; p = min(1.0, t / 0.35)  # pressure builds: the burr gets heavier and darker
    env = (0.55 + 0.45 * p) * min(1.0, t / 0.01) * min(1.0, (1.5 - t) / 0.03)
    pump.append(env * ((1 - 0.6 * p) * bright[i] + (0.4 + 0.6 * p) * dark[i] + 0.3 * hum[i]))
add(cm, at_peak(pump, -3), 0.06)
F = int(0.95 * RATE)
flow = biquad(noise(F), "bp", 1200, 0.7)
grain = [abs(g) for g in lowpass(noise(F), 30)]
top = max(grain)
add(cm, at_peak(shape([f * g / top for f, g in zip(flow, grain)], lambda t: min(1.0, t / 0.2) * min(1.0, (1 - t) / 0.1)), -16), 0.55)
for _ in range(14):  # small bubbles
    add(cm, at_peak(chirp(random.uniform(350, 500), random.uniform(700, 900), 0.015), random.uniform(-22, -18)), random.uniform(0.6, 1.45))
add(cm, at_peak(mix(modal(0.03, [(2500, 350, 1.0), (900, 200, 0.5)]), burst(0.004, 1000, 8000, 1500)), -9), 1.56)
add(cm, at_peak(shape(highpass(lowpass(noise(int(0.2 * RATE)), 7000), 1800), lambda t: min(1.0, t / 0.05) * math.exp(-t * 4)), -12), 1.57)
write("coffee_machine", edges(cm), loud_db=-14)
