# Chapter 02 « UNE AFFAIRE PLUS COMPLEXE » — the Atelier Varin (investigation story_001).
# Monday 12 October 2026 (the alarm: Thursday 22:31; Laurier & Fils' bid: Friday 09:00; Maëlle
# Rocher hands her phone over on Friday at 15:00, the phone's clock in the investigation).
#   S02-01 open space 08:15 (Inès, Aubrac) · S02-02 office 312 08:40 (Lacaze: file N° C02-A, the
#   phone under seal) · [story_001] · S02-03 interrogation room 19:40, debrief (Aubrac, Inès)
#   · [result] · S02-04 archives 20:10 (Colette, box BEN-2019-114: the hook to chapter 3).
# Run: python3 gen_chapter02.py <…/Resources/Story/scenes/chapter_02.json>
# The generator plays every answer path the way StoryDirector does and refuses to write a scene that
# breaks STORY_SCENES §2 (shots, close-ups, keyframes, silences, duration), DIALOGUE_UI (line
# length), the banned words, or a walk the stage would cut short (people walk at 1.1 m/s).
import json, math, os, re, sys
OUT = sys.argv[1]
LOCATIONS = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(OUT), "..", "locations.json")

def b(kind, **k):
    d = {"kind": kind}; d.update(k); return d
def shot(kind, camera, **k):
    d = {"kind": kind, "camera": camera}; d.update(k); return d
def line(id, speaker, text, **k):
    d = {"id": id, "speaker": speaker, "text": text}; d.update(k); return d
def flag(name):
    return {"kind": "flag", "flag": name}
SOLVED = {"lastCaseSolved": True}
UNSOLVED = {"lastCaseSolved": False}

scenes = []

# ---------------------------------------------------------------------------------------------
# S02-01 · Open space, 08:15 — Inès has already extracted Maëlle Rocher's phone (nobody touches a
# seized phone before her); Aubrac doubts the newcomer; the Atelier Varin affair in a few lines.
OS_AUB = shot("overShoulder", "cam_os_ots_aubrac", subject="player", other="aubrac")
AUB_TURN = shot("medium", "cam_os_aubrac_turn", subject="aubrac")
AUB_CU = shot("closeUp", "cam_os_aubrac_cu", subject="aubrac")
INES_MS = shot("medium", "cam_os_ines", subject="ines")
INES_CU = shot("closeUp", "cam_os_ines_cu", subject="ines")
scenes.append({
    "id": "S02-01", "title": "Open space", "location": "ENV_BEN_OPENSPACE", "place": "BEN · OPEN SPACE · 08:15",
    "participants": ["player", "ines", "aubrac"],
    "beats": [
        b("place", actor="ines", anchor="ines_desk"),
        b("place", actor="aubrac", anchor="aubrac_desk"),
        b("place", actor="player", anchor="entry"),
        b("camera", shot=shot("wide", "cam_os_wide", subject="player"), keyframe=True),
        b("sound", sound="door_glass"),
        b("move", actor="player", anchor="aisle"),
        b("sound", sound="steps_lino"),
        b("wait", seconds=3, silence=True),
        b("sound", sound="phone_distant"),
        b("wait", seconds=2.5),
        b("animate", actor="ines", animation="typing"),
        b("sound", sound="keyboard"),
        b("camera", shot=INES_MS),
        b("wait", seconds=3.5),
        b("move", actor="player", anchor="ines_side"),
        b("dialogue", node="i_hello"),
        b("wait", seconds=2),
        b("face", actor="ines", target="player"),
        b("dialogue", node="i_extracted"),
        b("camera", shot=shot("medium", "cam_os_aubrac_desk", subject="aubrac"), keyframe=True),
        b("dialogue", node="a_new"),
        b("face", actor="aubrac", target="player"),
        b("animate", actor="aubrac", animation="cross_arms"),
        b("camera", shot=AUB_TURN),
        b("dialogue", node="a_marseille"),
        b("camera", shot=INES_MS),
        b("dialogue", node="i_varin"),
        b("sound", sound="paper_slide"),
        b("animate", actor="ines", animation="put_down"),
        b("show", target="alarm_log"),
        b("camera", shot=shot("focusObject", "cam_os_log", prop="alarm_log", move="pushIn"), keyframe=True),
        b("dialogue", node="i_alarm"),
        b("face", actor="player", target="aubrac"),
        b("camera", shot=OS_AUB),
        b("dialogue", node="a_question"),
        b("camera", shot=INES_MS, keyframe=True),
        b("dialogue", node="i_lacaze"),
        b("animate", actor="ines", animation="typing"),
        b("move", actor="player", anchor="aisle"),
        b("camera", shot=shot("wide", "cam_os_wide", subject="player")),
        b("wait", seconds=3),
        b("exit", actor="player", anchor="entry"),
        b("sound", sound="door_glass"),
        b("wait", seconds=2),
        b("transition", style="fade", seconds=1.3),
    ],
    "dialogue": [
        line("i_hello", "ines", "Vous êtes {player.lastName}. Deux secondes.", emotion="neutral", animation="typing"),
        line("i_extracted", "ines", "Le téléphone de Maëlle Rocher. Extrait samedi, copie intégrale.", emotion="neutral",
             next="i_rule"),
        line("i_rule", "ines", "Personne ne touche un téléphone saisi avant moi. Pas même Lacaze.", emotion="amused", shot=INES_CU),
        line("a_new", "aubrac", "C'est donc vous, {g:le nouveau|la nouvelle|le nouvel agent} de Lacaze.", emotion="neutral"),
        line("a_marseille", "aubrac", "Un dossier à Marseille, et on vous confie déjà celui-là.", emotion="tired"),
        line("i_varin", "ines", "Atelier Varin. Des architectes, rue de la Folie-Méricourt, dans le 11ᵉ.", emotion="neutral",
             next="i_contest"),
        line("i_contest", "ines", "Un concours public : la médiathèque de Montreuil. Leur dossier partait vendredi avant midi.",
             emotion="neutral", next="a_laurier"),
        line("a_laurier", "aubrac", "Vendredi à neuf heures, un concurrent dépose presque le même projet. Laurier & Fils.",
             emotion="neutral", shot=AUB_TURN),
        line("i_alarm", "ines", "Le journal de l'alarme. Jeudi, 22 h 31 : le code de Maëlle Rocher, l'office manager.",
             emotion="neutral", next="i_denies"),
        line("i_denies", "ines", "Elle dit qu'elle n'y était pas. Elle nous a confié son téléphone elle-même.", emotion="neutral",
             shot=INES_MS),
        line("a_question", "aubrac", "Quelques minutes sur son téléphone, et vous nous direz qui a ouvert cette porte ?",
             emotion="tense",
             choices=[
                 {"id": "c02_promise", "text": "Oui. Avec les preuves.", "kind": "relational",
                  "remember": "Vous avez promis un nom à Aubrac avant d'avoir ouvert le téléphone.",
                  "shot": OS_AUB,
                  "effects": [flag("c02_promised"), {"kind": "respect", "npc": "aubrac", "amount": 1}],
                  "next": "p_promise"},
                 {"id": "c02_phone", "text": "Je vous dirai ce que dit le téléphone.", "kind": "relational",
                  "remember": "Vous avez répondu à Aubrac que le téléphone parlerait pour vous.",
                  "shot": OS_AUB,
                  "effects": [flag("c02_phone_speaks"), {"kind": "trust", "npc": "ines", "amount": 1}],
                  "next": "p_phone"},
                 {"id": "c02_quiet", "text": "Ne rien dire", "kind": "narrative", "silent": True, "pause": 2,
                  "remember": "Vous avez laissé Aubrac douter, sans lui répondre.",
                  "shot": AUB_CU,
                  "effects": [flag("c02_silent_aubrac")],
                  "next": "a_quiet"},
             ]),
        line("p_promise", "player", "Oui. Avec les preuves.", next="a_note"),
        line("a_note", "aubrac", "Alors je note l'heure.", emotion="neutral", shot=AUB_CU),
        line("p_phone", "player", "Je vous dirai ce que dit le téléphone.", next="i_good"),
        line("i_good", "ines", "Bonne réponse.", emotion="amused", shot=INES_CU, next="a_shrug"),
        line("a_shrug", "aubrac", "Un téléphone dit ce qu'on veut bien y lire.", emotion="neutral", animation="shrug", shot=AUB_TURN),
        line("a_quiet", "aubrac", "Au moins, vous ne promettez rien.", emotion="neutral"),
        line("i_lacaze", "ines", "Je l'ai remis sous scellé. Lacaze vous attend, bureau 312.", emotion="neutral"),
    ],
})

# ---------------------------------------------------------------------------------------------
# S02-02 · Office 312, 08:40 — Lacaze hands over file N° C02-A and the phone under seal. Ends on
# the OBJECT FOCUS of the bag (T-SIG-1 to the phone). He remembers chapter 1 and the open space.
LAC_CU = shot("closeUp", "cam_lac_cu", subject="lacaze")
LAC_OS = shot("overShoulder", "cam_lac_os", subject="player", other="lacaze")
scenes.append({
    "id": "S02-02", "title": "Le dossier C02-A", "location": "ENV_BEN_OFFICE_LACAZE", "place": "BEN · BUREAU 312 · 08:40",
    "participants": ["player", "lacaze"],
    "beats": [
        b("ambience", sound="ben_office_dawn"),
        b("place", actor="lacaze", anchor="lac_window"),
        b("place", actor="player", anchor="door_in"),
        b("camera", shot=shot("wide", "cam_lac_door", subject="lacaze"), keyframe=True),
        b("sound", sound="door_glass"),
        b("wait", seconds=3, silence=True),
        b("dialogue", node="l_enter"),
        b("move", actor="player", anchor="visitor"),
        b("wait", seconds=1.5),
        b("move", actor="lacaze", anchor="lac_desk"),
        b("camera", shot=shot("wide", "cam_lac_wide", subject="lacaze")),
        b("sound", sound="chair"),
        b("wait", seconds=2),
        b("camera", shot=shot("medium", "cam_lac_ms", subject="lacaze")),
        b("animate", actor="lacaze", animation="read"),
        b("sound", sound="page"),
        b("wait", seconds=2),
        b("dialogue", node="l_heard_promise"),
        b("camera", shot=LAC_CU, keyframe=True),
        b("dialogue", node="l_plans"),
        b("camera", shot=shot("medium", "cam_lac_ms", subject="lacaze")),
        b("sound", sound="drawer"),
        b("animate", actor="lacaze", animation="take"),
        b("dialogue", node="l_c01_defiant"),
        b("wait", seconds=1),
        b("show", target="case_folder_c02"),
        b("animate", actor="lacaze", animation="put_down"),
        b("sound", sound="paper_slide"),
        b("camera", shot=shot("focusObject", "cam_lac_desk_top", prop="case_folder_c02")),
        b("dialogue", node="l_varin"),
        b("wait", seconds=2),
        b("camera", shot=LAC_OS, keyframe=True),
        b("dialogue", node="l_maelle"),
        b("camera", shot=shot("closeUp", "cam_lac_player_cu", subject="player")),
        b("wait", seconds=3, silence=True),
        b("sound", sound="plastic_bag"),
        b("animate", actor="lacaze", animation="handover"),
        b("show", target="evidence_bag"),
        b("camera", shot=shot("focusObject", "cam_lac_desk_top", prop="evidence_bag", move="pushIn")),
        b("dialogue", node="l_seal"),
    ],
    "dialogue": [
        line("l_enter", "lacaze", "Entrez. Asseyez-vous.", emotion="tired"),
        # What the open space told him (S02-01).
        line("l_heard_promise", "lacaze", "Aubrac m'a dit que vous lui aviez promis un nom.", emotion="neutral",
             condition={"flag": "c02_promised"}, next="l_heard_phone"),
        line("l_heard_phone", "lacaze", "Inès dit que vous écoutez. Elle ne le dit de personne.", emotion="neutral",
             condition={"flag": "c02_phone_speaks"}, next="l_heard_quiet"),
        line("l_heard_quiet", "lacaze", "Aubrac dit que vous ne répondez pas. Ici, ce n'est pas un défaut.", emotion="neutral",
             condition={"flag": "c02_silent_aubrac"}),
        line("l_plans", "lacaze", "Des plans d'architecte. Pas de mort, pas de sang.", emotion="tired", next="l_money"),
        line("l_money", "lacaze", "Mais un concours public, et des mois de travail sortis en une nuit.", emotion="neutral",
             next="l_questions"),
        line("l_questions", "lacaze", "Des questions ?", emotion="neutral",
             choices=[
                 {"id": "c02_why", "text": "Pourquoi le BEN, pour des plans ?", "kind": "cosmetic", "shot": LAC_OS, "next": "p_why"},
                 {"id": "c02_none", "text": "Aucune.", "kind": "cosmetic", "shot": LAC_OS, "next": "p_none"},
                 {"id": "c02_q_silent", "text": "Ne rien dire", "kind": "cosmetic", "silent": True, "pause": 2, "shot": LAC_CU},
             ]),
        line("p_why", "player", "Pourquoi le BEN, pour des plans ?", next="l_why"),
        line("l_why", "lacaze", "Parce que la seule preuve est dans un téléphone.", emotion="neutral", shot=LAC_CU, next="l_why_2"),
        line("l_why_2", "lacaze", "Et que les téléphones, ici, on sait les lire.", emotion="neutral"),
        line("p_none", "player", "Aucune.", next="l_fine"),
        line("l_fine", "lacaze", "Bien.", emotion="neutral", animation="nod", shot=LAC_CU),
        # Chapter 1 (S01-01B): his first question to the player.
        line("l_c01_defiant", "lacaze", "Vous m'aviez demandé si je vous aurais {g:choisi|choisie|choisi}. Je ne sais toujours pas.",
             emotion="neutral", condition={"flag": "c01_defiant"}, next="l_c01_dutiful"),
        line("l_c01_dutiful", "lacaze", "Vous m'aviez promis de faire le travail. En voilà.", emotion="neutral",
             condition={"flag": "c01_dutiful"}, next="l_c01_silent"),
        line("l_c01_silent", "lacaze", "Vous ne parlez toujours pas beaucoup. Gardez ça pour les témoins.", emotion="neutral",
             condition={"flag": "c01_silent"}),
        line("l_varin", "lacaze", "Plainte de Sonia Varin, la cofondatrice. Déposée vendredi midi.", emotion="neutral",
             next="l_three"),
        line("l_three", "lacaze", "Trois noms dans le dossier. Et un code d'alarme qui n'était à aucun d'eux.", emotion="neutral"),
        line("l_maelle", "lacaze", "Maëlle Rocher nous a remis son téléphone vendredi, à quinze heures. De son plein gré.",
             emotion="neutral", next="l_not_yet"),
        line("l_not_yet", "lacaze", "Personne ne la met en cause. Pour l'instant.", emotion="neutral"),
        line("l_seal", "lacaze", "Vous signerez le registre des scellés en sortant.", emotion="neutral", next="l_phone"),
        line("l_phone", "lacaze", "Le téléphone de Maëlle Rocher. À vous.", emotion="neutral"),
    ],
})

# ---------------------------------------------------------------------------------------------
# S02-03 · Interrogation room, 19:40 — the debrief. Bellec has been heard off screen (no case
# suspect in 3D before chapter 3); Aubrac sits in the chair he left. The motive: the debt.
OS_INT = shot("overShoulder", "cam_int_os_suspect", subject="player", other="aubrac")
INT_CU = shot("closeUp", "cam_int_cu", subject="aubrac")
INT_MS = shot("medium", "cam_int_ms", subject="aubrac")
INT_INES_CU = shot("closeUp", "cam_int_ines_cu", subject="ines")
scenes.append({
    "id": "S02-03", "title": "Salle d'audition", "location": "ENV_BEN_INTERROGATION", "place": "BEN · SALLE D'AUDITION · 19:40",
    "participants": ["player", "aubrac", "ines"],
    "beats": [
        b("place", actor="aubrac", anchor="suspect"),
        b("place", actor="ines", anchor="mirror_side"),
        b("place", actor="player", anchor="door_in"),
        b("camera", shot=shot("wide", "cam_int_wide", subject="aubrac"), keyframe=True),
        b("animate", actor="aubrac", animation="read"),
        b("wait", seconds=3, silence=True),
        b("animate", actor="ines", animation="gesture"),
        b("hide", target="red_light"),
        b("sound", sound="door_close"),
        b("move", actor="player", anchor="investigator"),
        b("wait", seconds=2),
        b("sound", sound="chair"),
        b("camera", shot=OS_INT),
        b("dialogue", node="a_solved"),
        b("animate", actor="aubrac", animation="put_down"),
        b("show", target="pv_bellec"),
        b("sound", sound="paper_slide"),
        b("camera", shot=shot("focusObject", "cam_int_table", prop="pv_bellec")),
        b("wait", seconds=2),
        b("camera", shot=shot("medium", "cam_int_ines", subject="ines"), keyframe=True),
        b("dialogue", node="i_quits"),
        b("camera", shot=shot("medium", "cam_int_ines", subject="ines")),
        b("dialogue", node="i_maelle"),
        b("camera", shot=OS_INT, keyframe=True),
        b("dialogue", node="a_write"),
        b("camera", shot=shot("medium", "cam_int_mirror", subject="player")),
        b("wait", seconds=2),
        b("camera", shot=INT_MS),
        b("dialogue", node="a_sleep"),
        b("camera", shot=shot("wide", "cam_int_wide", subject="aubrac"), keyframe=True),
        b("animate", actor="player", animation="stand"),
        b("exit", actor="player", anchor="door_in"),
        b("sound", sound="door_close"),
        b("wait", seconds=3, silence=True),
        b("transition", style="fade", seconds=1.3),
    ],
    "dialogue": [
        # The case's outcome.
        line("a_solved", "aubrac", "Bellec a parlé. Votre rapport tenait.", emotion="neutral", condition=SOLVED, next="a_unsolved"),
        line("a_unsolved", "aubrac", "Votre rapport désignait quelqu'un d'autre. Inès a repris la corbeille derrière vous.",
             emotion="tired", condition=UNSOLVED, next="a_unsolved_2"),
        line("a_unsolved_2", "aubrac", "Bellec est venu à quinze heures. Il a parlé.", emotion="neutral", condition=UNSOLVED,
             next="a_promise_ok"),
        # S02-01, « Oui. Avec les preuves. »: Aubrac had noted the time.
        line("a_promise_ok", "aubrac", "J'avais noté l'heure. Votre nom est arrivé à temps.", emotion="neutral",
             condition={"flag": "c02_promised", "lastCaseSolved": True}, shot=INT_CU, next="a_promise_ko"),
        line("a_promise_ko", "aubrac", "J'avais noté l'heure. Le nom n'était pas le bon.", emotion="tired",
             condition={"flag": "c02_promised", "lastCaseSolved": False}, shot=INT_CU, next="a_debt"),
        # The motive (story only).
        line("a_debt", "aubrac", "Douze mille euros. Il les devait à Olivier Laurier depuis l'an dernier.", emotion="neutral",
             shot=INT_MS, next="a_deal"),
        line("a_deal", "aubrac", "Laurier lui a proposé d'effacer la dette. Contre le dossier Montreuil.", emotion="neutral"),
        line("i_quits", "ines", "« On est quittes. » C'était pour Laurier. Il l'a envoyé à Maëlle.", emotion="neutral",
             next="a_deleted"),
        line("a_deleted", "aubrac", "Une minute plus tard, il l'effaçait. Il croyait que ça suffisait.", emotion="neutral",
             shot=INT_MS, next="i_always"),
        line("i_always", "ines", "Ils le croient tous.", emotion="amused", shot=INT_INES_CU),
        # Maëlle kept quiet: sharing codes is forbidden at the atelier, and she was afraid.
        line("i_maelle", "ines", "Maëlle Rocher a confirmé. Elle lui a donné son code, puis elle s'est tue.", emotion="tired",
             next="i_afraid"),
        line("i_afraid", "ines", "Donner son code est interdit, à l'atelier. Elle avait peur pour sa place.", emotion="tired"),
        line("a_write", "aubrac", "Elle a donné son code à un homme qui mentait. On l'écrit, dans la synthèse ?", emotion="tense",
             choices=[
                 {"id": "c02_write", "text": "Oui. Elle a donné son code.", "kind": "relational",
                  "remember": "Vous avez fait écrire que Maëlle Rocher avait donné son code.",
                  "shot": OS_INT,
                  "effects": [flag("c02_maelle_written"), {"kind": "respect", "npc": "aubrac", "amount": 1}],
                  "next": "p_write"},
                 {"id": "c02_spare", "text": "Elle s'est fait avoir. On écrit ça.", "kind": "relational",
                  "remember": "Vous avez écrit que Maëlle Rocher s'était fait avoir.",
                  "shot": OS_INT,
                  "effects": [flag("c02_maelle_spared"), {"kind": "trust", "npc": "ines", "amount": 1}],
                  "next": "p_spare"},
                 {"id": "c02_maelle_silent", "text": "Ne rien dire", "kind": "narrative", "silent": True, "pause": 2,
                  "remember": "Vous n'avez rien dit quand Aubrac a parlé de Maëlle Rocher.",
                  "shot": INT_CU,
                  "effects": [flag("c02_maelle_silent")],
                  "next": "a_facts"},
             ]),
        line("p_write", "player", "Oui. Elle a donné son code.", next="a_procedure"),
        line("a_procedure", "aubrac", "C'est la procédure. Le parquet fera le tri.", emotion="neutral", animation="nod", shot=INT_CU),
        line("p_spare", "player", "Elle s'est fait avoir. On écrit ça.", next="i_thanks"),
        line("i_thanks", "ines", "Merci.", emotion="warm", shot=INT_INES_CU, next="a_both"),
        line("a_both", "aubrac", "On écrira les deux. Le parquet choisira.", emotion="tired", animation="shrug", shot=INT_MS),
        line("a_facts", "aubrac", "Alors j'écris les faits. Rien d'autre.", emotion="neutral"),
        line("a_sleep", "aubrac", "Rentrez dormir, {player.lastName}. Lacaze lira tout ça demain.", emotion="tired"),
    ],
})

# ---------------------------------------------------------------------------------------------
# S02-04 · Archives, 20:10 (after the result: a surprise) — the player brings Thomas Bellec's mail,
# signed « Références : ex-prestataire informatique, affaire classée BEN-2019-114 — témoin ».
# Colette finds the box and says little. The hook to chapter 3: administrative, human; nothing is
# revealed. Flags only (the result screen is already behind): chapter 3 reads them.
OS_TABLE = shot("overShoulder", "cam_arc_os_table", subject="player", other="colette")
COL_CU = shot("closeUp", "cam_arc_colette_cu", subject="colette")
COL_MS = shot("medium", "cam_arc_colette", subject="colette")
scenes.append({
    "id": "S02-04", "title": "Cent quatorze", "location": "ENV_BEN_ARCHIVES", "place": "BEN · ARCHIVES · 20:10",
    "participants": ["player", "colette"],
    "beats": [
        b("place", actor="colette", anchor="colette_desk"),
        b("place", actor="player", anchor="entry"),
        b("camera", shot=shot("wide", "cam_arc_table", subject="colette"), keyframe=True),
        b("animate", actor="colette", animation="read"),
        b("sound", sound="neon_buzz"),
        b("sound", sound="steps_lino"),
        b("move", actor="player", anchor="table_other"),
        b("wait", seconds=3, silence=True),
        b("face", actor="colette", target="player"),
        b("camera", shot=COL_MS),
        b("dialogue", node="c_closing"),
        b("camera", shot=shot("overShoulder", "cam_arc_os_desk", subject="player", other="colette")),
        b("dialogue", node="c_show"),
        b("animate", actor="player", animation="put_down"),
        b("sound", sound="paper_slide"),
        b("show", target="mail_print"),
        b("camera", shot=shot("focusObject", "cam_arc_desk_top", prop="mail_print", move="pushIn")),
        b("wait", seconds=3),
        b("camera", shot=COL_MS, keyframe=True),
        b("animate", actor="colette", animation="read"),
        b("dialogue", node="c_reads"),
        b("wait", seconds=2.5),
        b("dialogue", node="c_114"),
        b("animate", actor="colette", animation="stand"),
        b("move", actor="colette", anchor="aisle"),
        b("camera", shot=shot("wide", "cam_arc_aisle", subject="colette")),
        b("sound", sound="steps_lino"),
        b("wait", seconds=3, silence=True),
        b("wait", seconds=2.5),
        b("animate", actor="colette", animation="take"),
        b("sound", sound="paper_slide"),
        b("wait", seconds=1.5),
        b("move", actor="colette", anchor="table"),
        b("sound", sound="steps_lino"),
        b("camera", shot=shot("medium", "cam_arc_player", subject="player")),
        b("wait", seconds=4),
        b("show", target="box_114"),
        b("animate", actor="colette", animation="put_down"),
        b("camera", shot=shot("focusObject", "cam_arc_box", prop="box_114"), keyframe=True),
        b("wait", seconds=2.5),
        b("camera", shot=OS_TABLE),
        b("dialogue", node="c_request"),
        b("camera", shot=shot("medium", "cam_arc_player", subject="player")),
        b("wait", seconds=2.5),
        b("camera", shot=COL_CU, keyframe=True),
        b("dialogue", node="c_nobody"),
        b("animate", actor="colette", animation="take"),
        b("dialogue", node="c_light"),
        b("camera", shot=shot("focusObject", "cam_arc_box", prop="box_114", move="pushIn")),
        b("wait", seconds=3, silence=True),
        b("effect", effects=[flag("c02_box_114")]),
        b("transition", style="fade", seconds=1.3),
    ],
    "dialogue": [
        line("c_closing", "colette", "Je fermais.", emotion="tired", next="c_moreau"),
        line("c_moreau", "colette", "Le dossier Moreau, c'était vous. Je l'ai rangé la semaine dernière.", emotion="warm"),
        line("c_show", "colette", "Montrez.", emotion="neutral"),
        line("c_reads", "colette", "« Affaire classée BEN-2019-114 — témoin. »", emotion="neutral"),
        line("c_114", "colette", "Cent quatorze.", emotion="neutral", next="c_where"),
        line("c_where", "colette", "Allée F. Je sais où il est.", emotion="neutral"),
        line("c_request", "colette", "Pour l'ouvrir, il me faut une demande signée du commandant.", emotion="neutral",
             choices=[
                 {"id": "c02_ask_lacaze", "text": "Je la demanderai demain à Lacaze.", "kind": "narrative",
                  "shot": OS_TABLE,
                  "effects": [flag("c02_archive_lacaze"), {"kind": "trust", "npc": "colette", "amount": 1}],
                  "next": "p_ask"},
                 {"id": "c02_only_exists", "text": "Je voulais savoir s'il existait.", "kind": "narrative",
                  "shot": OS_TABLE,
                  "effects": [flag("c02_archive_quiet")],
                  "next": "p_exists"},
                 {"id": "c02_archive_silent", "text": "Ne rien dire", "kind": "narrative", "silent": True, "pause": 2,
                  "shot": COL_CU,
                  "effects": [flag("c02_archive_silent")],
                  "next": "c_aside"},
             ]),
        line("p_ask", "player", "Je la demanderai demain à Lacaze.", next="c_tomorrow"),
        line("c_tomorrow", "colette", "Demain, alors. Il reste ici.", emotion="neutral", shot=COL_CU),
        line("p_exists", "player", "Je voulais savoir s'il existait.", next="c_exists"),
        line("c_exists", "colette", "Il existe.", emotion="neutral", shot=COL_CU),
        line("c_aside", "colette", "Je le garde de côté. Le soir, personne ne descend.", emotion="warm"),
        line("c_nobody", "colette", "Personne ne l'a demandé en sept ans. Vous êtes {g:le premier|la première|la première personne}.",
             emotion="neutral"),
        line("c_light", "colette", "Il est léger.", emotion="neutral"),
    ],
})

# ---------------------------------------------------------------------------------------------
# Checks: every answer path, played the way StoryDirector plays it.
# The old concept's words are written split (« co|zy »), like LegacyWordsTests, so this file does not match itself.
_OLD_WORDS = "|".join(w.replace("|", "") for w in ["co|zy", "cli|ents?", "resta|urants?"])
BANNED = re.compile(r"(?i)(?<![\w'’])(épingl\w*|pin(?:ned|ning)?|accus\w*|recrue\w*|recruit\w*|stagiaire\w*|trainee\w*"
                    r"|trace|" + _OLD_WORDS + r"|épique|héroïque|gamer)(?![\w])")
ANIMATIONS = {"stand", "sit", "nod", "gesture", "handover", "typing", "phone", "shrug", "read", "take", "put_down",
              "cross_arms", "lean_forward"}
SOUNDS = {"steps_lino", "door_glass", "door_close", "chair", "drawer", "page", "paper_slide", "plastic_bag", "neon_buzz",
          "phone_distant", "desk_phone_ring", "keyboard", "printer", "coffee_machine"}
WALK = 1.1  # m/s, walking pace used to time the scenes
rooms = {l["id"]: l for l in json.load(open(LOCATIONS))["locations"]}

def texts(scene):
    for n in scene["dialogue"]:
        yield n["id"], n["text"]
        for c in n.get("choices", []):
            yield n["id"] + "/" + c["id"], c["text"]
            if "remember" in c: yield n["id"] + "/" + c["id"] + " remember", c["remember"]
    yield "place", scene["place"]

def holds(cond, flags, solved):
    if not cond: return True
    if "flag" in cond and cond["flag"] not in flags: return False
    if "notFlag" in cond and cond["notFlag"] in flags: return False
    if "lastCaseSolved" in cond and cond["lastCaseSolved"] != solved: return False
    return True

def play(scene, pick, flags, solved, problems):
    """One path: [(shot kind, keyframe)], seconds (blocking time: lines, choices, waits), lines."""
    room = rooms[scene["location"]]
    anchors = {a["id"]: a for a in room["anchors"]}
    nodes = {n["id"]: n for n in scene["dialogue"]}
    shots, lines = [], 0
    t = 0.0
    where, busy = {}, {}
    def say(start):
        nonlocal t, lines
        nid = start
        while nid:
            n = nodes[nid]
            if not holds(n.get("condition"), flags, solved): nid = n.get("next"); continue
            if "shot" in n: shots.append((n["shot"]["kind"], False))
            t += 1.2 + 0.045 * len(n["text"]); lines += 1
            if n.get("choices"):
                opts = [c for c in n["choices"] if holds(c.get("condition"), flags, solved)]
                c = opts[min(pick, len(opts) - 1)]
                t += 3.0  # reading the answers
                for e in c.get("effects", []):
                    if e["kind"] == "flag": flags.add(e["flag"])
                if "shot" in c: shots.append((c["shot"]["kind"], False))
                if c.get("silent"): t += c.get("pause", 2)
                nid = c.get("next")
            else:
                nid = n.get("next")
    for i, beat in enumerate(scene["beats"]):
        if not holds(beat.get("condition"), flags, solved): continue
        k, actor = beat["kind"], beat.get("actor")
        if actor and k in ("move", "exit", "animate", "face") and busy.get(actor, 0) > t + 0.05:
            problems.append(f"{scene['id']} beat {i + 1} ({k} {actor}): still walking for {busy[actor] - t:.1f} s")
        if k == "place": where[actor] = anchors[beat["anchor"]]
        elif k in ("move", "exit"):
            a, b2 = where[actor], anchors[beat["anchor"]]
            if k == "move": busy[actor] = t + 0.55 + max(0.6, math.hypot(a["x"] - b2["x"], a["z"] - b2["z"]) / WALK)
            where[actor] = b2
        elif k == "camera": shots.append((beat["shot"]["kind"], bool(beat.get("keyframe"))))
        elif k == "dialogue": say(beat["node"])
        elif k in ("wait", "transition", "title"): t += beat.get("seconds", 1)
        elif k == "animate" and beat["animation"] not in ANIMATIONS: problems.append(f"{scene['id']}: animation {beat['animation']}")
        elif k == "sound" and beat["sound"] not in SOUNDS: problems.append(f"{scene['id']}: sound {beat['sound']}")
        elif k == "effect":
            for e in beat["effects"]:
                if e["kind"] == "flag": flags.add(e["flag"])
    for n in scene["dialogue"]:
        if n.get("animation") and n["animation"] not in ANIMATIONS: problems.append(f"{scene['id']} {n['id']}: animation")
    return shots, t, lines

problems = []
summary = []
for scene in scenes:
    sid = scene["id"]
    if len(scene["participants"]) > 3: problems.append(f"{sid}: more than 3 people")
    for key, text in texts(scene):
        if len(text) > 160: problems.append(f"{sid} {key}: {len(text)} characters")
        m = BANNED.search(text)
        if m: problems.append(f"{sid} {key}: banned word « {m.group(0)} »")
    for n in scene["dialogue"]:
        if n["speaker"] not in scene["participants"]: problems.append(f"{sid} {n['id']}: speaker not in the scene")
    cams = [bt for bt in scene["beats"] if bt["kind"] == "camera"]
    room = rooms[scene["location"]]
    for bt in cams:
        if bt["shot"]["camera"] not in {c["id"] for c in room["cameras"]}: problems.append(f"{sid}: camera {bt['shot']['camera']}")
    silences = [bt for bt in scene["beats"] if bt["kind"] == "wait" and bt.get("silence")]
    if not silences or len(silences) > 3 or not all(2 <= bt["seconds"] <= 4 for bt in silences):
        problems.append(f"{sid}: 1 to 3 silent waits of 2–4 s ({len(silences)})")
    if cams[0]["shot"]["kind"] != "wide": problems.append(f"{sid}: first shot not WIDE")
    styles = {bt.get("style") for bt in scene["beats"] if bt["kind"] == "transition"}
    if not styles <= {"cut", "dissolve", "fade"}: problems.append(f"{sid}: transition {styles}")
    report = []
    for pick in (0, 1, 2):
        for solved in (True, False):
            # What the earlier answers of the same pick left: chapter 1 and S02-01.
            flags = {["c01_defiant", "c01_dutiful", "c01_silent"][pick],
                     ["c02_promised", "c02_phone_speaks", "c02_silent_aubrac"][pick]}
            shots, secs, lines = play(scene, pick, set(flags), solved, problems)
            path = f"{sid} path {'ABC'[pick]}/{'solved' if solved else 'unsolved'}"
            if not 8 <= len(shots) <= 25: problems.append(f"{path}: {len(shots)} shots")
            run = 0
            for kind, _ in shots:
                run = run + 1 if kind == "closeUp" else 0
                if run > 2: problems.append(f"{path}: 3 CLOSE in a row"); break
            last = 0
            for i, (kind, key) in enumerate(shots):
                if key:
                    if i - last > 6: problems.append(f"{path}: {i - last} shots between keyframes")
                    last = i
            if len(shots) - 1 - last > 6: problems.append(f"{path}: {len(shots) - 1 - last} shots after the last keyframe")
            if not 60 <= secs <= 180: problems.append(f"{path}: ~{secs:.0f} s")
            report.append((len(shots), secs, lines))
    words = sum(len(n["text"].split()) for n in scene["dialogue"])
    pauses = sum(bt.get("seconds", 0) for bt in scene["beats"])
    summary.append(f"{sid} « {scene['title']} »: {len(cams)} camera beats, {min(r[0] for r in report)}–{max(r[0] for r in report)} shots "
                   f"per path, ~{min(r[1] for r in report):.0f}–{max(r[1] for r in report):.0f} s, "
                   f"{min(r[2] for r in report)}–{max(r[2] for r in report)} lines (ShippedStoryTests estimate {words / 2.5 + pauses:.0f} s)")
print("\n".join(summary))
if problems:
    print("\n".join(dict.fromkeys(problems))); sys.exit(1)

json.dump({"scenes": scenes}, open(OUT, "w"), ensure_ascii=False, indent=2)
print(len(scenes), "scenes")
