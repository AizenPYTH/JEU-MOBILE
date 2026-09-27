# Chapter 01 « PREMIÈRE AFFECTATION » — STORY_SCENES §5 (S01-01, S01-02, S01-03).
import json, sys
OUT = sys.argv[1]

def b(kind, **k):
    d = {"kind": kind}; d.update(k); return d
def shot(kind, camera, **k):
    d = {"kind": kind, "camera": camera}; d.update(k); return d
def line(id, speaker, text, **k):
    d = {"id": id, "speaker": speaker, "text": text}; d.update(k); return d

scenes = []

# S01-01 · Arrivée au BEN — corridor (shots 1–2), then the door of office 312.
scenes.append({
    "id": "S01-01", "title": "Arrivée au BEN", "location": "ENV_BEN_CORRIDOR", "place": "BEN · 3ᵉ ÉTAGE · 21:04",
    "participants": ["player"],
    "beats": [
        b("place", actor="player", anchor="entry"),
        b("camera", shot=shot("wide", "cam_corr_wide", subject="player"), keyframe=True),
        b("sound", sound="door_glass"),
        b("move", actor="player", anchor="hall"),
        b("sound", sound="steps_lino"),
        b("wait", seconds=3, silence=True),
        b("camera", shot=shot("medium", "cam_corr_follow", subject="player", move="track")),
        b("move", actor="player", anchor="mid"),
        b("sound", sound="neon_buzz"),
        b("wait", seconds=2.5),
        b("sound", sound="phone_distant"),
        b("camera", shot=shot("wide", "cam_corr_door312", subject="player"), keyframe=True),
        b("move", actor="player", anchor="door312"),
        b("wait", seconds=2.5),
    ],
    "dialogue": [],
})

# S01-01 (suite) · Bureau 312 — shots 3–11, ends on the phone under seal (T-SIG-1).
scenes.append({
    "id": "S01-01B", "title": "Bureau 312", "location": "ENV_BEN_OFFICE_LACAZE", "place": "BEN · BUREAU 312 · 21:06",
    "participants": ["player", "lacaze"],
    "beats": [
        b("place", actor="lacaze", anchor="lac_desk"),
        b("place", actor="player", anchor="door_in"),
        b("camera", shot=shot("wide", "cam_lac_door", subject="lacaze"), keyframe=True),
        b("animate", actor="lacaze", animation="read"),
        b("wait", seconds=3, silence=True),
        b("camera", shot=shot("medium", "cam_lac_ms", subject="lacaze")),
        b("dialogue", node="l_close_door"),
        b("sound", sound="door_close"),
        b("camera", shot=shot("overShoulder", "cam_lac_os", subject="player", other="lacaze")),
        b("move", actor="player", anchor="visitor"),
        b("sound", sound="chair"),
        b("wait", seconds=2),
        b("show", target="agent_folder"),
        b("camera", shot=shot("closeUp", "cam_lac_cu", subject="lacaze"), keyframe=True),
        b("animate", actor="lacaze", animation="read"),
        b("dialogue", node="l_twelve_years"),
        b("camera", shot=shot("medium", "cam_lac_ms", subject="lacaze"), keyframe=True),
        b("hide", target="agent_folder"),
        b("sound", sound="drawer"),
        b("animate", actor="lacaze", animation="take"),
        b("wait", seconds=1.5),
        b("show", target="case_folder"),
        b("animate", actor="lacaze", animation="put_down"),
        b("camera", shot=shot("focusObject", "cam_lac_desk_top", prop="case_folder")),
        b("dialogue", node="l_marseille"),
        b("sound", sound="plastic_bag"),
        b("show", target="evidence_bag"),
        b("camera", shot=shot("focusObject", "cam_lac_desk_top", prop="evidence_bag", move="pushIn"), keyframe=True),
        b("dialogue", node="l_phone"),
    ],
    "dialogue": [
        line("l_close_door", "lacaze", "{player.lastName}. Fermez la porte.", emotion="tired"),
        line("l_twelve_years", "lacaze", "Douze ans de terrain. Vous êtes là parce qu'on me l'a demandé.", emotion="neutral",
             choices=[
                 {"id": "c01_defiant", "text": "Et vous, vous l'auriez demandé ?", "kind": "relational",
                  "remember": "Vous avez demandé à Lacaze s'il vous aurait {g:choisi|choisie|choisi}.",
                  "shot": shot("overShoulder", "cam_lac_os", subject="player", other="lacaze"),
                  "effects": [{"kind": "flag", "flag": "c01_defiant"}, {"kind": "respect", "npc": "lacaze", "amount": 1}],
                  "next": "p_defiant"},
                 {"id": "c01_dutiful", "text": "Je ferai le travail.", "kind": "relational",
                  "remember": "Vous avez promis à Lacaze de faire le travail.",
                  "shot": shot("overShoulder", "cam_lac_os", subject="player", other="lacaze"),
                  "effects": [{"kind": "flag", "flag": "c01_dutiful"}, {"kind": "trust", "npc": "lacaze", "amount": 1}],
                  "next": "p_dutiful"},
                 {"id": "c01_silent", "text": "Ne rien dire", "kind": "narrative", "silent": True, "pause": 2,
                  "remember": "Vous n'avez rien répondu à Lacaze, et il a levé les yeux.",
                  "shot": shot("closeUp", "cam_lac_cu", subject="lacaze"),
                  "effects": [{"kind": "flag", "flag": "c01_silent"}]},
             ]),
        line("p_defiant", "player", "Et vous, vous l'auriez demandé ?", next="l_not_yet"),
        line("l_not_yet", "lacaze", "Pas encore.", emotion="neutral", shot=shot("closeUp", "cam_lac_cu", subject="lacaze")),
        line("p_dutiful", "player", "Je ferai le travail.", next="l_we_will_see"),
        line("l_we_will_see", "lacaze", "On verra.", emotion="tired", animation="nod", shot=shot("closeUp", "cam_lac_cu", subject="lacaze")),
        line("l_marseille", "lacaze", "Marseille. Un homme de vingt-six ans.", emotion="neutral"),
        line("l_phone", "lacaze", "Son téléphone a été retrouvé ce matin. À vous.", emotion="neutral"),
    ],
})

# S01-02 · Retour — after the report of #001.
scenes.append({
    "id": "S01-02", "title": "Retour", "location": "ENV_BEN_OFFICE_LACAZE", "place": "BEN · BUREAU 312 · 05:40",
    "participants": ["player", "lacaze"],
    "beats": [
        b("ambience", sound="ben_office_dawn"),
        b("place", actor="lacaze", anchor="lac_desk"),
        b("place", actor="player", anchor="visitor"),
        b("camera", shot=shot("wide", "cam_lac_wide", subject="lacaze"), keyframe=True),
        b("wait", seconds=3, silence=True),
        b("camera", shot=shot("medium", "cam_lac_ms", subject="lacaze")),
        b("animate", actor="lacaze", animation="read"),
        b("sound", sound="page"),
        b("wait", seconds=2),
        b("camera", shot=shot("closeUp", "cam_lac_cu", subject="lacaze"), keyframe=True),
        b("dialogue", node="l_good", condition={"lastCaseSolved": True}),
        b("dialogue", node="l_happens", condition={"lastCaseSolved": False}),
        b("camera", shot=shot("overShoulder", "cam_lac_os", subject="player", other="lacaze")),
        b("animate", actor="lacaze", animation="handover"),
        b("show", target="ben_card"),
        b("dialogue", node="l_card"),
        b("camera", shot=shot("focusObject", "cam_lac_desk_top", prop="ben_card", move="pushIn"), keyframe=True),
        b("wait", seconds=2.5),
        b("camera", shot=shot("medium", "cam_lac_ms", subject="lacaze")),
        b("dialogue", node="l_office"),
        b("transition", style="fade", seconds=1.3),
    ],
    "dialogue": [
        line("l_good", "lacaze", "Bien.", emotion="neutral", animation="nod"),
        line("l_happens", "lacaze", "Ça arrive. Pas deux fois.", emotion="tired"),
        line("l_card", "lacaze", "Elle est à votre nom. Ne la perdez pas.", emotion="neutral",
             choices=[
                 {"id": "c01_thanks", "text": "Merci, commandant.", "kind": "cosmetic", "next": "l_nothing"},
                 {"id": "c01_first", "text": "Et le dossier Moreau ?", "kind": "relational",
                  "remember": "Vous avez demandé ce que deviendrait le dossier Moreau.",
                  "effects": [{"kind": "respect", "npc": "lacaze", "amount": 1}], "next": "l_moreau"},
                 {"id": "c01_card_silent", "text": "Ne rien dire", "kind": "cosmetic", "silent": True, "pause": 2,
                  "shot": shot("closeUp", "cam_lac_cu", subject="lacaze")},
             ]),
        line("l_nothing", "lacaze", "Ne me remerciez pas. Ce n'est qu'une carte.", emotion="tired"),
        line("l_moreau", "lacaze", "Il part au parquet de Marseille ce matin. Avec votre nom dessus.", emotion="neutral"),
        line("l_office", "lacaze", "Votre bureau est au bout du couloir.", emotion="neutral"),
    ],
})

# S01-03 · Mon bureau — once, level 01.
scenes.append({
    "id": "S01-03", "title": "Mon bureau", "location": "ENV_BEN_OFFICE_PLAYER", "place": "BEN · BUREAU 327 · 06:05",
    "participants": ["player"],
    "beats": [
        b("place", actor="player", anchor="po_entry"),
        b("camera", shot=shot("wide", "cam_po_wide", subject="player"), keyframe=True),
        b("wait", seconds=2, silence=True),
        b("move", actor="player", anchor="po_stand"),
        b("animate", actor="player", animation="put_down"),
        b("sound", sound="paper_slide"),
        b("wait", seconds=2),
        b("sound", sound="desk_phone_ring"),
        b("camera", shot=shot("focusObject", "cam_po_obj_phone", prop="desk_phone", move="pushIn"), keyframe=True),
        b("wait", seconds=2.5),
        b("transition", style="fade", seconds=1.0),
    ],
    "dialogue": [],
})

json.dump({"scenes": scenes}, open(OUT, "w"), ensure_ascii=False, indent=2)
print(len(scenes), "scenes")
