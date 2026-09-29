# ARCHIVED / LEGACY — the game plays no video: this only documents the story scenes for work outside the game.
# Exports every story scene as a shooting script with ready-to-paste video prompts:
#   python3 docs/archive/tools/export_cinematic_prompts.py
# Read from the game's data (Resources/Story): nothing is written by hand scene by scene, so the document always
# matches what the game plays. Character, set and style descriptions are the handoff's (docs/design_story).
import glob, json, math, os, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..")
R = os.path.join(ROOT, "ScreenshotKit", "Sources", "StoryLibrary", "Resources", "Story")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "archive", "PROMPTS_CINEMATIQUES_HISTOIRE.md")

locations = {l["id"]: l for l in json.load(open(os.path.join(R, "locations.json")))["locations"]}
npcs = {n["id"]: n for n in json.load(open(os.path.join(R, "npcs.json")))["npcs"]}
catalog = json.load(open(os.path.join(R, "characters.json")))
campaign = json.load(open(os.path.join(R, "campaign.json")))
scenes = {s["id"]: s for f in sorted(glob.glob(os.path.join(R, "scenes", "*.json"))) for s in json.load(open(f))["scenes"]}

STYLE = ("Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified "
         "micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent "
         "light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows "
         "tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera "
         "moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only "
         "on meaningful objects (a seal, a recording light).")
END = "No subtitles, no on-screen text, no captions, no logos, no readable signs."

# Characters (NPC_DIRECTION.md + npcs.json): English for the prompts, French for the notes.
PEOPLE = {
    "lacaze": ("Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding "
               "grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a "
               "loosened navy tie; tired but sharp, rare half-smile, never raises his voice",
               "Voix : masculine, 55–60 ans, grave, légèrement éraillée ; lent, phrases courtes."),
    "ines": ("Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped "
             "face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones "
             "around her neck; focused, ironic",
             "Voix : féminine, 30 ans, claire ; rapide, vocabulaire technique simple."),
    "aubrac": ("Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey "
               "beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival",
               "Voix : masculine, 50 ans, ronde ; posé."),
    "colette": ("Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin "
                "chain, beige cardigan over grey; kind and slow",
                "Voix : féminine, 60+ ans, douce ; lente."),
    "agent_a": ("Julien Roche, a BEN officer in the background: 30s, navy polo shirt, busy, out of focus",
                "Figurant, pas de réplique."),
}
PLAYER_NOTE = ("the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or "
               "with the face out of focus), in a dark coat")
PLAYER_PRESETS = {
    "elise": "Élise Morel: woman, 1.68 m, light skin, oval face, brown hair in a low ponytail, grey-green eyes, charcoal wool coat over a roll-neck",
    "vincent": "Vincent Delmas: man, 1.80 m, medium skin, square face, short black faded hair, stubble, brown eyes, navy parka over an écru shirt",
}

SETS = {
    "ENV_BEN_CORRIDOR": "The BEN's 3rd-floor corridor: 24 m long, 2.2 m wide, glass partitions on the left, numbered doors 301 to 318 on the right, 60 × 60 cm suspended ceiling tiles with fluorescent panels (one flickers), dark grey linoleum, administrative grey walls, a water fountain, a trolley of cardboard files, a safety poster, night windows and a BEN sign at the far end",
    "ENV_BEN_OFFICE_LACAZE": "Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off",
    "ENV_BEN_OFFICE_PLAYER": "The player's own office at the BEN: a 3.5 × 4 m box, grey metal desk, articulated lamp, a computer screen, a desk phone, two files, a window on the courtyard, a ceiling neon (from level 2: an archive cabinet, a framed picture, a mug, a plant, a shelf for rewards)",
    "ENV_BEN_OPENSPACE": "The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning",
    "ENV_BEN_ARCHIVES": "The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk",
    "ENV_BEN_INTERROGATION": "The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup",
    "ENV_BEN_BRIEFING": "The BEN's meeting room: 6 × 8 m, a long table, ten chairs, a wall screen, a whiteboard, dimmed neons",
}

ANCHORS = {
    "entry": "at the entrance", "hall": "a few steps in", "mid": "halfway down the corridor", "hero": "in the corridor",
    "door312": "at the door of office 312", "far": "at the far end", "wait": "waiting by the wall",
    "lac_desk": "seated behind his desk", "lac_stand": "standing beside his desk", "lac_window": "standing at the window, back to the room",
    "visitor": "seated in the visitor's chair", "visitor_b": "in the second visitor's chair", "door_in": "just inside the door",
    "before_desk": "standing in front of the desk", "side": "standing by the shelves",
    "po_desk": "seated at the desk", "po_entry": "coming in", "po_stand": "standing by the desk", "po_window": "at the window",
    "ines_desk": "seated at her desk", "ines_side": "standing beside Inès's desk", "aisle": "in the aisle",
    "aubrac_desk": "seated at his desk", "aubrac_lean": "leaning against a desk", "aisle_deep": "deep in an aisle",
    "table": "at the reading table", "table_other": "across the reading table", "colette_desk": "seated at her desk",
    "suspect": "in the suspect's chair", "investigator": "in the investigator's chair", "investigator_b": "in the second investigator's chair",
    "mirror_side": "by the one-way mirror",
}
ANIMATIONS = {
    "read": "reads a file and turns a page", "take": "takes something out of a drawer", "put_down": "puts it down on the desk",
    "handover": "hands something over", "nod": "nods", "gesture": "makes a small gesture of the hand", "typing": "types on a keyboard",
    "phone": "looks at a phone", "shrug": "shrugs", "cross_arms": "crosses the arms", "lean_forward": "leans forward",
    "sit": "sits down", "stand": "stands up",
}
SHOTS = {
    "wide": ("WIDE", "wide establishing shot, people at most a third of the frame height"),
    "medium": ("MEDIUM", "medium shot, waist to head"),
    "closeUp": ("CLOSE", "close shot, shoulders to head"),
    "overShoulder": ("PAR-DESSUS L'ÉPAULE", "over-the-shoulder shot, the foreground shoulder out of focus at the frame's edge"),
    "twoShot": ("DEUX PERSONNES", "two-shot"),
    "profile": ("PROFIL", "profile shot"),
    "focusObject": ("OBJET", "macro insert on the object, background out of focus"),
}
MOVES = {"pushIn": "a very slow push-in (about 12 cm over the shot)", "track": "a slow lateral tracking shot (under 8 cm/s)", None: "static camera", "cut": "static camera"}
SOUNDS = {
    "steps_lino": "footsteps on linoleum", "door_glass": "a glass door opening", "door_close": "a door closing softly",
    "chair": "a chair creaking", "drawer": "a wooden drawer sliding", "page": "a page turned", "paper_slide": "a file slid on a desk",
    "plastic_bag": "a plastic evidence bag crinkling", "neon_buzz": "a neon tube crackling", "phone_distant": "a landline ringing far away",
    "desk_phone_ring": "a desk phone ringing", "keyboard": "typing", "printer": "a printer", "coffee_machine": "a coffee machine",
}
AMBIENCES = {
    "ben_hvac": "air conditioning hum", "ben_office_night": "quiet office at night, distant city", "ben_office_dawn": "quiet office at dawn, a few distant birds",
    "ben_openspace": "open-plan office murmur, keyboards", "ben_archives": "basement hum, faint neon buzz", "ben_interrogation": "near silence, electrical hum",
}

SHORT = {"lacaze": "Lacaze", "ines": "Inès", "aubrac": "Aubrac", "colette": "Colette", "agent_a": "the officer", "player": "the investigator"}

def who(actor):
    return SHORT.get(actor, actor)

def spoken_text(text):
    """A line as it is said on screen: the player's name and gendered words for the Vincent Delmas model."""
    import re
    text = (text.replace("{player.lastName}", "Delmas").replace("{player.LASTNAME}", "DELMAS")
            .replace("{player.firstName}", "Vincent").replace("{player.fullName}", "Vincent Delmas")
            .replace("{player.rank}", "Enquêteur"))
    return re.sub(r"\{g:([^|}]*)\|[^}]*\}", r"\1", text)

def prop_text(loc, pid):
    p = next((p for p in loc["props"] if p["id"] == pid), None)
    if not p:
        return pid
    label = p.get("label", "")
    kind = p["kind"]
    if kind == "folder":
        colour = "a grey-blue agent's file" if p.get("color") == "#6F7A86" else ("a printed sheet" if p.get("color") in ("#EFEBE3", "#D9D4C8") else "a worn kraft case folder")
        return f"{colour} ({label})" if label else colour
    if kind == "evidence_bag":
        return "a transparent sealed evidence bag with a red seal strip, a black smartphone inside"
    if kind == "card":
        return "a white BEN ID card with the player's name and service number"
    if kind == "archive_box":
        return f"a cardboard archive box labelled {label}"
    if kind == "red_light":
        return "the small red recording light"
    return f"{kind} {label}".strip()

def line_seconds(text):
    return 1.2 + 0.045 * len(text)

def speaker_name(sid):
    if sid == "player":
        return "JOUEUR"
    if sid == "narrator":
        return "NARRATEUR"
    n = npcs.get(sid)
    return (n["firstName"] + " " + n["lastName"]).upper() if n else sid.upper()

out = []
w = out.append

def camera_line(loc, shot):
    cam = next((c for c in loc["cameras"] if c["id"] == shot.get("camera")), None)
    if not cam:
        return "", 50
    d = math.dist((cam["x"], cam["y"], cam["z"]), (cam["lookX"], cam["lookY"], cam["lookZ"]))
    return (f"caméra `{cam['id']}` · {int(cam.get('focal', 50))} mm · hauteur {cam['y']:.2f} m · à {d:.1f} m de sa cible"), int(cam.get("focal", 50))

def dialogue_flow(scene, start, depth=0, seen=None):
    """The lines from `start` (with the answers as branches)."""
    seen = seen or set()
    nodes = {n["id"]: n for n in scene["dialogue"]}
    lines, secs = [], 0.0
    nid = start
    while nid and nid in nodes and nid not in seen:
        seen.add(nid)
        n = nodes[nid]
        cond = n.get("condition")
        tag = ""
        if cond and "lastCaseSolved" in cond:
            tag = " *(si l'affaire est résolue)*" if cond["lastCaseSolved"] else " *(si l'affaire n'est pas résolue)*"
        elif cond and cond.get("flag"):
            tag = f" *(si `{cond['flag']}`)*"
        elif cond and cond.get("notFlag"):
            tag = f" *(sans `{cond['notFlag']}`)*"
        shot = n.get("shot")
        if shot:
            label = SHOTS.get(shot["kind"], (shot["kind"],))[0]
            lines.append(f"{'  ' * depth}- *(coupe : {label} `{shot.get('camera')}`)*")
        anim = f" — *{ANIMATIONS.get(n['animation'], n['animation'])}*" if n.get("animation") else ""
        lines.append(f"{'  ' * depth}- **{speaker_name(n['speaker'])}**{tag} : « {n['text']} »{anim}")
        secs += line_seconds(n["text"])
        if n.get("choices"):
            for i, c in enumerate(n["choices"]):
                letter = "—" if c.get("silent") else "ABCD"[i]
                extra = []
                if c.get("remember"):
                    extra.append(f"fin de chapitre : « {c['remember']} »")
                if c.get("silent"):
                    extra.append(f"silence tenu {c.get('pause', 2)} s" + (f", {SHOTS.get(c['shot']['kind'], ('',))[0]} `{c['shot'].get('camera')}`" if c.get("shot") else ""))
                lines.append(f"{'  ' * depth}  - **Réponse {letter}** « {c['text']} »" + (f" *({'; '.join(extra)})*" if extra else ""))
                sub, s2 = dialogue_flow(scene, c.get("next"), depth + 2, set(seen))
                lines += sub
            break
        nid = n.get("next")
    return lines, secs

def scene_doc(scene, number_in_chapter):
    loc = locations[scene["location"]]
    w(f"### {scene['id']} — {scene.get('title', '')}\n")
    w(f"**Lieu** : {loc['name']} (`{loc['id']}`) · **Carton** : « {scene.get('place', '')} » · "
      f"**Personnages** : {', '.join(speaker_name(p).title() if p != 'player' else 'le joueur' for p in scene['participants'])}\n")
    w(f"**Décor** : {SETS.get(loc['id'], loc['name'])}.\n")
    # Cut into shots at each camera beat.
    shots, current, pos = [], None, {}
    ambience = loc.get("ambience")
    for b in scene["beats"]:
        k = b["kind"]
        if k == "camera":
            current = {"shot": b["shot"], "events": [], "sounds": [], "secs": 0.0, "people": dict(pos), "keyframe": b.get("keyframe"), "ambience": ambience}
            shots.append(current)
            continue
        if current is None:
            current = {"shot": None, "events": [], "sounds": [], "secs": 0.0, "people": {}, "ambience": ambience}
            shots.append(current)
        if k in ("place", "enter", "move"):
            where = ANCHORS.get(b["anchor"], b["anchor"])
            verb = {"place": "is", "enter": "comes in and goes", "move": "walks and ends"}[k]
            current["events"].append(f"{who(b['actor'])} {verb} {where}")
            pos[b["actor"]] = b["anchor"]
            current["people"][b["actor"]] = b["anchor"]
            if k != "place":
                current["secs"] += 2.5
        elif k == "exit":
            current["events"].append(f"{who(b['actor'])} leaves")
            pos.pop(b.get("actor"), None)
        elif k == "face":
            current["events"].append(f"{who(b['actor'])} turns towards {who(b['target']) if b['target'] in npcs or b['target'] == 'player' else prop_text(loc, b['target'])}")
        elif k == "animate":
            current["events"].append(f"{who(b['actor'])} {ANIMATIONS.get(b['animation'], b['animation'])}")
            current["secs"] += 1.0
        elif k == "show":
            current["events"].append(f"{prop_text(loc, b['target'])} appears (put on the desk / brought in)")
        elif k == "hide":
            current["events"].append(f"{prop_text(loc, b['target'])} is taken away")
        elif k == "wait":
            current["events"].append(f"a silent beat of {b.get('seconds', 1):g} s" + (" (narrative silence: everything but the ambience goes quiet)" if b.get("silence") else ""))
            current["secs"] += b.get("seconds", 1)
        elif k == "sound":
            current["sounds"].append(SOUNDS.get(b["sound"], b["sound"]))
        elif k == "ambience":
            ambience = b.get("sound")
            current["ambience"] = ambience
        elif k == "transition":
            current["events"].append(f"transition: {b.get('style', 'fade')} ({b.get('seconds', 0.6):g} s)")
            current["secs"] += b.get("seconds", 0.6)
        elif k == "dialogue":
            cond = b.get("condition")
            current.setdefault("dialogues", []).append((b["node"], cond))
        elif k == "notification":
            current["events"].append(f"the player's own phone buzzes with a notification ({b.get('title', '')})")
    total = 0.0
    shots = [s for s in shots if s["shot"] is not None]
    for i, s in enumerate(shots, 1):
        shot = s["shot"]
        kind_fr, kind_en = SHOTS.get(shot["kind"], (shot["kind"], shot["kind"]))
        cam, focal = camera_line(loc, shot)
        subject = shot.get("subject")
        dlg_lines, dlg_secs = [], 0.0
        for node, cond in s.get("dialogues", []):
            if cond and "lastCaseSolved" in cond:
                dlg_lines.append(f"- *{'Si l’affaire est résolue' if cond['lastCaseSolved'] else 'Si l’affaire n’est pas résolue'} :*")
            l, sec = dialogue_flow(scene, node, 1 if cond else 0)
            dlg_lines += l
            dlg_secs += sec
        secs = max(2.0, s["secs"] + dlg_secs)
        total += secs
        w(f"\n#### Plan {i} — {kind_fr}" + (f" sur {speaker_name(subject).title() if subject != 'player' else 'le joueur'}" if subject else "")
          + (f" · objet : {prop_text(loc, shot['prop'])}" if shot.get("prop") else "") + f" (≈ {secs:.0f} s)\n")
        w(f"- {cam} · mouvement : {MOVES.get(shot.get('move'), 'static camera')}" + (" · point de reprise" if s.get("keyframe") else ""))
        if s["events"]:
            w("- Action : " + " ; ".join(s["events"]) + ".")
        audio = ([AMBIENCES.get(s["ambience"], s["ambience"])] if s.get("ambience") else []) + s["sounds"]
        if audio:
            w("- Son : " + ", ".join(audio) + ".")
        if dlg_lines:
            w("- Dialogue :")
            out.extend("  " + l for l in dlg_lines)
        # The prompt.
        people = {a for a in s["people"]} | ({subject} if subject else set()) | ({shot.get("other")} if shot.get("other") else set())
        cast = "; ".join((PEOPLE[p][0] if p in PEOPLE else PLAYER_NOTE) + f", {ANCHORS.get(s['people'].get(p, ''), 'in the room')}" for p in sorted(people) if p)
        focus = f"on {who(subject)}" if subject else (f"on {prop_text(loc, shot['prop'])}" if shot.get("prop") else "")
        spoken = []
        for node, cond in s.get("dialogues", []):
            n = next((n for n in scene["dialogue"] if n["id"] == node), None)
            if n and n["speaker"] not in ("player", "narrator"):
                spoken.append(f"{who(n['speaker'])} says quietly in French: \"{spoken_text(n['text'])}\"")
        prompt = (f"A scene from a fictional contemporary French police drama. {SETS.get(loc['id'], loc['name'])}. "
                  f"{kind_en[0].upper() + kind_en[1:]} {focus}, {focal} mm lens, {MOVES.get(shot.get('move'), 'static camera')}. "
                  + (f"In the scene: {cast}. " if cast else "")
                  + (f"Action: {'; '.join(s['events'])}. " if s["events"] else "")
                  + (" ".join(spoken) + " " if spoken else "")
                  + (f"Audio: {', '.join(audio)}. " if audio else "")
                  + f"{STYLE} {END}")
        w("\n```\n" + prompt + "\n```")
        # Reaction shots inside the answers' branches (a line with its own camera).
        for node, _ in s.get("dialogues", []):
            for label, n in branch_shots(scene, node):
                bshot = n["shot"]
                bkind_fr, bkind_en = SHOTS.get(bshot["kind"], (bshot["kind"], bshot["kind"]))
                _, bfocal = camera_line(loc, bshot)
                say = (f"{who(n['speaker'])} says quietly in French: \"{spoken_text(n['text'])}\" " if n["speaker"] not in ("player", "narrator")
                       else "")
                silent = "He holds a silence for two seconds, then looks up. " if n.get("_silent") else ""
                w(f"\n*Plan {i} · {label} — {bkind_fr} (`{bshot.get('camera')}`)*\n")
                w("```\n" + f"A scene from a fictional contemporary French police drama. {SETS.get(loc['id'], loc['name'])}. "
                  f"{bkind_en[0].upper() + bkind_en[1:]} on {who(bshot.get('subject') or n['speaker'])}, {bfocal} mm lens, static camera. "
                  f"In the scene: {PEOPLE.get(bshot.get('subject') or n['speaker'], (PLAYER_NOTE,))[0]}. {silent}{say}"
                  f"{STYLE} {END}" + "\n```")
    return total

def branch_shots(scene, start):
    """(label, node) for every line of an answer's branch that has its own shot, and the silences."""
    nodes = {n["id"]: n for n in scene["dialogue"]}
    found, nid, seen = [], start, set()
    while nid and nid in nodes and nid not in seen:
        seen.add(nid)
        n = nodes[nid]
        for i, c in enumerate(n.get("choices") or []):
            letter = "silence" if c.get("silent") else f"réponse {'ABCD'[i]}"
            if c.get("silent") and c.get("shot"):
                found.append((letter, {"speaker": c["shot"].get("subject", ""), "text": "", "shot": c["shot"], "_silent": True}))
            bid, bseen = c.get("next"), set()
            while bid and bid in nodes and bid not in bseen:
                bseen.add(bid)
                if nodes[bid].get("shot"):
                    found.append((letter, nodes[bid]))
                bid = nodes[bid].get("next")
        nid = n.get("next")
    return found

# ------------------------------------------------------------------------------------------------------------------
w("# Mode HISTOIRE — prompts des cinématiques (scènes des chapitres)\n")
w("> **ARCHIVÉ / LEGACY.** Le jeu ne lit **aucune** vidéo et n'en attendra aucune : les scènes sont jouées en 3D temps "
  "réel. Ce document ne sert qu'à un travail hors du jeu (bande-annonce, réseaux).\n")
w("> Généré par `docs/archive/tools/export_cinematic_prompts.py` à partir des données du jeu "
  "(`ScreenshotKit/Sources/StoryLibrary/Resources/Story`) : chaque scène, chaque plan, chaque réplique, chaque réponse. "
  "Relancer le script après toute modification d'une scène.\n")
w("Chaque scène est jouée en 3D temps réel par le jeu (SceneKit). Pour la refaire en vidéo : un prompt par **plan** "
  "(une coupe caméra = un plan), à monter ensuite dans l'ordre. Les répliques du joueur n'ont pas de voix (sous-titres "
  "seulement). Les répliques des PNJ peuvent être dites dans la vidéo ou doublées (ElevenLabs, fiches voix ci-dessous) ; "
  "les sous-titres sont toujours affichés par le jeu. Les choix du joueur créent des **branches** : il faut une vidéo "
  "par branche pour les plans concernés (repérés « Réponse A / B / — »).\n")
w("**Le nom du joueur** : certaines répliques le disent (« {player.lastName}. Fermez la porte. »). Les prompts l'écrivent "
  "avec le modèle Vincent Delmas ; pour un doublage, enregistrer une version par nom ou couper le nom au montage (le jeu "
  "affiche toujours la réplique exacte en sous-titre).\n")
w("## Style commun (déjà inclus dans chaque prompt)\n")
w("```\n" + STYLE + " " + END + "\n```\n")
w("Règles du handoff (STORY_SCENES, STORY_ART_DIRECTION) : une scène = un lieu, 3 personnes au plus à l'écran, toujours un "
  "plan large en ouverture, jamais plus de 2 plans serrés d'affilée, au moins un plan muet de 2 à 4 s, un plan sur objet "
  "avant chaque passage au téléphone, transitions coupe / fondu enchaîné / fondu au noir uniquement. Focales : 28 · 35 · "
  "50 · 85 · 100 mm. Hauteur de caméra par défaut 1,45 m.\n")
w("## Personnages\n")
w("### Le joueur (personnalisé)\n")
w("Le joueur crée son enquêteur (2 bases, teint, visage, cheveux, yeux, 4 tenues × 2 couleurs). Pour qu'une seule vidéo "
  "serve à tous : **le filmer de dos, par-dessus l'épaule, ou visage hors de mise au point**. Modèles de départ :\n")
for k, v in PLAYER_PRESETS.items():
    w(f"- {v}")
w("")
for pid, (en, voice) in PEOPLE.items():
    n = npcs.get(pid, {})
    w(f"### {n.get('title', '')} {n.get('firstName', '')} {n.get('lastName', '')}".strip())
    w(f"- {n.get('bio', '')}")
    w(f"- {voice}")
    w("```\n" + en + ". Realistic proportions, matte skin, no heroic pose.\n```\n")
w("## Décors\n")
for lid, text in SETS.items():
    loc = locations[lid]
    cams = ", ".join(f"`{c['id']}` ({int(c.get('focal', 50))} mm)" for c in loc["cameras"])
    w(f"### {loc['name']} (`{lid}`)\n")
    w(f"{text}.\n\nCaméras : {cams}.\n")

grand_total = 0.0
for chapter in campaign["chapters"]:
    if chapter["status"] != "playable":
        continue
    w(f"\n---\n\n## Chapitre {chapter['number']:02d} — {chapter['title']}\n")
    w(f"*{chapter['synopsis']}*\n")
    order = []
    for step in chapter["steps"]:
        if step["kind"] == "scene":
            order.append(f"scène {step['scene']} « {step.get('title', '')} »")
        elif step["kind"] == "investigation":
            order.append(f"**téléphone** : affaire `{step['caseID']}` « {step.get('title', '')} »")
        elif step["kind"] == "result":
            order.append("fin de chapitre (écrans papier)")
        elif step["kind"] == "office":
            order.append("mon bureau (écran 3D interactif)")
    w("Déroulé : " + " → ".join(order) + ".\n")
    for i, step in enumerate([s for s in chapter["steps"] if s["kind"] == "scene"], 1):
        grand_total += scene_doc(scenes[step["scene"]], i)
        w("")

w(f"\n---\n\nDurée totale estimée des scènes : ≈ {grand_total / 60:.0f} min (hors branches).\n")
open(OUT, "w").write("\n".join(out) + "\n")
print(f"{OUT}: {sum(1 for l in out if l.lstrip().startswith('#### Plan'))} plans, ≈ {grand_total:.0f} s")
