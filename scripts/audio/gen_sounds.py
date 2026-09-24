# Generates the game's sounds (WAV, mono, 22.05 kHz, 16-bit) into
# ScreenshotKit/Sources/ScreenshotUI/Resources/Sounds. Everything is synthesised: no third-party audio.
#   python3 scripts/audio/gen_sounds.py
import math, os, random, struct, wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "ScreenshotKit", "Sources", "ScreenshotUI", "Resources", "Sounds")
os.makedirs(OUT, exist_ok=True)
random.seed(7)

def write(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = 0.89 / peak
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32767)) for s in samples))
    print(name, f"{len(samples) / RATE:.1f} s")

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

def env_loop(x, fade=0.4):
    # Crossfade the end into the start so the loop is seamless.
    n = int(fade * RATE); out = x[:len(x) - n]
    for i in range(n):
        t = i / n
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

# Street ambience: distant traffic rumble, cars passing, far horn.
n = RATE * 10
street = [s * 0.8 for s in lowpass(brown(n), 300)]
for start in (0.8, 4.1, 7.3):
    i0 = int(start * RATE); length = int(2.6 * RATE)
    whoosh = lowpass(noise(length), 900)
    for i in range(length):
        t = i / length
        street[(i0 + i) % n] += whoosh[i] * math.sin(math.pi * t) ** 2 * 0.5
for start in (5.6,):
    i0 = int(start * RATE)
    for i in range(int(0.35 * RATE)):
        t = i / RATE
        street[i0 + i] += 0.05 * (math.sin(2 * math.pi * 392 * t) + 0.6 * math.sin(2 * math.pi * 494 * t)) * math.sin(math.pi * i / (0.35 * RATE))
write("street", env_loop(street))

# Sirens: French two-tone (435 / 488 Hz), far away, drifting in and out, with echoes off buildings.
n = RATE * 10
siren = []
phase = 0.0
for i in range(n):
    t = i / RATE
    f = 435 if int(t / 0.6) % 2 == 0 else 488
    f *= 1 + 0.006 * math.sin(2 * math.pi * 0.09 * t)  # slow doppler drift
    phase += 2 * math.pi * f / RATE
    tone = math.sin(phase) + 0.35 * math.sin(3 * phase) + 0.15 * math.sin(5 * phase)
    siren.append(tone * (0.45 + 0.35 * math.sin(2 * math.pi * 0.07 * t + 1)))
siren = echo(lowpass(siren, 1400), 0.23, 0.35)
second = []
phase = 0.0
for i in range(n):
    t = i / RATE
    f = (435 if int((t + 0.3) / 0.6) % 2 == 0 else 488) * 0.985
    phase += 2 * math.pi * f / RATE
    second.append(math.sin(phase) * 0.25 * (0.5 + 0.5 * math.sin(2 * math.pi * 0.05 * t)))
write("sirens", env_loop(mix(siren, lowpass(second, 900))))

# Crowd: band-limited noise with many small swells (voices, far away).
n = RATE * 8
murmur = highpass(lowpass(noise(n), 1800), 250)
env = [0.0] * n
for _ in range(60):
    c = random.randint(0, n - 1); width = random.uniform(0.15, 0.5) * RATE
    for i in range(max(0, int(c - width)), min(n, int(c + width))):
        env[i] += math.exp(-((i - c) / (width / 2.5)) ** 2) * random.uniform(0.3, 1)
write("crowd", env_loop([m * (0.25 + e) for m, e in zip(murmur, env)]))

# Vibration on a table: two buzzes with the rattle of the table.
buzz = []
for i in range(int(1.1 * RATE)):
    t = i / RATE
    on = (t < 0.4) or (0.55 < t < 0.95)
    a = 1 if on else 0
    buzz.append(a * (math.sin(2 * math.pi * 170 * t) * 0.6 + (random.uniform(-1, 1) * 0.35 if on else 0)))
write("vibrate", lowpass(buzz, 1200))

# Notification: two soft bell tones.
note = [0.0] * int(0.9 * RATE)
for start, f in ((0.0, 1318.5), (0.12, 1975.5)):
    i0 = int(start * RATE)
    for i in range(len(note) - i0):
        t = i / RATE
        note[i0 + i] += math.exp(-t * 7) * (math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * f * 2 * t))
write("notification", note)

# Unlock: a short click and a soft rising air.
unlock = []
for i in range(int(0.45 * RATE)):
    t = i / RATE
    click = math.exp(-t * 400) * random.uniform(-1, 1)
    rise = math.sin(math.pi * min(1, t / 0.45)) * 0.12 * math.sin(2 * math.pi * (600 + 900 * t) * t)
    unlock.append(click + rise)
write("unlock", unlock)

# Key tap (keypad) and navigation tick.
write("key", [math.exp(-(i / RATE) * 250) * (random.uniform(-1, 1) * 0.6 + math.sin(2 * math.pi * 2200 * i / RATE) * 0.4)
              for i in range(int(0.06 * RATE))])
write("tick", [math.exp(-(i / RATE) * 500) * math.sin(2 * math.pi * 3200 * i / RATE) for i in range(int(0.03 * RATE))])

# News sting: a short rising chord (the channel's jingle).
sting = [0.0] * int(1.6 * RATE)
for f in (220, 277.2, 329.6, 440):
    for i in range(len(sting)):
        t = i / RATE
        sting[i] += math.sin(2 * math.pi * f * t * (1 + 0.02 * t)) * min(1, t * 8) * math.exp(-t * 1.6) * 0.3
write("sting", lowpass(sting, 3000))

# ---- Cases #002–#005 ----------------------------------------------------------------------------

# Metro station: low tunnel rumble, ventilation hiss, faint electrical hum.
n = RATE * 7
rumble = lowpass(brown(n), 120)
hiss = [s * 0.08 for s in highpass(lowpass(noise(n), 5000), 1500)]
hum = [0.05 * math.sin(2 * math.pi * 50 * i / RATE) + 0.03 * math.sin(2 * math.pi * 100 * i / RATE) for i in range(n)]
write("metro", env_loop(mix([r * 1.2 for r in rumble], hiss, hum)))

# Station chime: three descending bell notes before an announcement.
chime = [0.0] * int(1.6 * RATE)
for start, f in ((0.0, 880.0), (0.28, 739.99), (0.56, 587.33)):
    i0 = int(start * RATE)
    for i in range(len(chime) - i0):
        t = i / RATE
        chime[i0 + i] += math.exp(-t * 3.2) * (math.sin(2 * math.pi * f * t) + 0.25 * math.sin(2 * math.pi * f * 2.01 * t))
write("chime", echo(chime, 0.19, 0.3))

# A train pulling in: rising rumble, rail clicks, brake squeal.
n = int(4.5 * RATE)
train = []
body = lowpass(brown(n), 260)
for i in range(n):
    t = i / RATE
    level = min(1, t / 1.6) * (1 - max(0, t - 3.6) / 0.9)
    s = body[i] * 1.6 * level
    if int(t * 5.5) != int((t - 1 / RATE) * 5.5) and 0.8 < t < 3.6:
        s += 0.6 * level
    if 2.6 < t < 3.8:
        s += 0.08 * math.sin(2 * math.pi * 2350 * t) * math.sin(math.pi * (t - 2.6) / 1.2)
    train.append(s)
write("train", lowpass(train, 2500))

# Quiet room: air, a distant road, a clock-like fridge hum.
n = RATE * 7
room = mix([s * 0.35 for s in lowpass(brown(n), 200)],
           [0.02 * math.sin(2 * math.pi * 120 * i / RATE) for i in range(n)],
           [s * 0.05 for s in highpass(lowpass(noise(n), 3000), 800)])
write("room", env_loop(room))

# The sea on a sheltered bay: slow waves on sand.
n = RATE * 8
waves = highpass(lowpass(noise(n), 1400), 120)
sea = []
for i in range(n):
    t = i / RATE
    swell = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(2 * math.pi * t / 4.0)) ** 3
    sea.append(waves[i] * swell)
write("sea", env_loop(sea))

# Gulls: two far cries.
gulls = [0.0] * int(1.8 * RATE)
for start in (0.0, 0.9):
    i0 = int(start * RATE)
    for i in range(int(0.55 * RATE)):
        t = i / RATE
        f = 1400 + 500 * math.sin(math.pi * t / 0.55) - 300 * t
        gulls[i0 + i] += math.sin(2 * math.pi * f * t) * math.sin(math.pi * t / 0.55) * 0.4
write("gulls", echo(lowpass(gulls, 3000), 0.21, 0.25))

# A gala hall: murmur of a crowd and a string quartet far away (sustained chords).
n = RATE * 8
murmur = highpass(lowpass(noise(n), 1600), 250)
env = [0.0] * n
for _ in range(90):
    c = random.randint(0, n - 1); width = random.uniform(0.1, 0.4) * RATE
    for i in range(max(0, int(c - width)), min(n, int(c + width))):
        env[i] += math.exp(-((i - c) / (width / 2.5)) ** 2) * random.uniform(0.2, 0.7)
chords = [(196.0, 246.9, 293.7), (174.6, 220.0, 261.6), (164.8, 207.7, 246.9), (196.0, 246.9, 293.7)]
strings = []
for i in range(n):
    t = i / RATE
    chord = chords[int(t / 2) % len(chords)]
    k = (t % 2) / 2
    swell = math.sin(math.pi * k) ** 0.5
    strings.append(sum(math.sin(2 * math.pi * f * t) + 0.3 * math.sin(4 * math.pi * f * t) for f in chord) * 0.06 * swell)
write("hall", env_loop(mix([m * (0.2 + e) for m, e in zip(murmur, env)], echo(lowpass(strings, 1800), 0.3, 0.3))))

# Power cut: the hum dies with a thump.
n = int(1.2 * RATE)
power = []
for i in range(n):
    t = i / RATE
    f = 100 * max(0.2, 1 - t * 1.4)
    power.append(math.sin(2 * math.pi * f * t) * max(0, 1 - t * 1.1) * 0.7 + (math.exp(-t * 30) * random.uniform(-1, 1) * 0.8))
write("powerdown", lowpass(power, 1500))

# Rain on a car roof: dense ticks over a soft wash.
n = RATE * 7
rain = [s * 0.4 for s in highpass(lowpass(noise(n), 4000), 400)]
for _ in range(2200):
    i0 = random.randint(0, n - 200)
    a = random.uniform(0.2, 0.9)
    for i in range(60):
        rain[i0 + i] += a * math.exp(-i / 9) * random.uniform(-1, 1)
write("rain", env_loop(lowpass(rain, 6000)))

# A car engine idling.
n = RATE * 6
engine = []
phase = 0.0
for i in range(n):
    t = i / RATE
    f = 28 * (1 + 0.02 * math.sin(2 * math.pi * 0.7 * t))
    phase += 2 * math.pi * f / RATE
    engine.append(math.sin(phase) + 0.5 * math.sin(2 * phase) + 0.25 * math.sin(4 * phase))
write("engine", env_loop(lowpass([e + 0.15 * b for e, b in zip(engine, brown(n))], 400)))

# Phone ringing (a ringtone heard through the case): two short phrases.
ring = [0.0] * int(2.4 * RATE)
for start in (0.0, 1.2):
    i0 = int(start * RATE)
    for k, f in enumerate((987.8, 1318.5, 987.8, 1318.5)):
        j0 = i0 + int(k * 0.14 * RATE)
        for i in range(int(0.13 * RATE)):
            t = i / RATE
            ring[j0 + i] += math.sin(2 * math.pi * f * t) * math.sin(math.pi * i / (0.13 * RATE)) * 0.5
write("ring", lowpass(ring, 3500))
