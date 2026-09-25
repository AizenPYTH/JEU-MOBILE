# Generates ScreenshotKit/Sources/CaseLibrary/Resources/Cases/case_002.json
# Case #002 — PREMIER MÉTRO. Night of Friday 16 to Saturday 17 October 2026, Lyon.
# The phone is handed over on Saturday 17 October at 07:40.
#
# Core mechanic: the reassuring 03:07 message was sent from the phone while it sat at quai Arloing
# (Vaise), where the club manager lives. The player crosses Messages (the 03:07 text and its style),
# Location (the phone's own history), Calendar (the manager's address) and Phone (her 02:19 call).
# No deleted message and no locked app in this case.
import json, sys

OUT = sys.argv[1]
Y = 2026
def t(day, hm, month=10):
    return f"{Y}-{month:02d}-{day:02d} {hm}"
def s(day, hm):
    # September shortcut
    return t(day, hm, 9)

# ---------------------------------------------------------------- contacts
contacts = [
    dict(id="me", name="Clémence Aubry", phone="+33 6 48 27 15 93", relation="Moi", email="clem.aubry@mailo.fr",
         birthday="03/02/1997", avatarHue=0.55, isOwner=True),
    dict(id="anais", name="Anaïs Aubry", phone="+33 6 31 84 50 27", relation="Sœur", email="anais.aubry@mailo.fr",
         birthday="19/06/2000", avatarHue=0.95),
    dict(id="papa", name="Papa", phone="+33 6 07 62 11 48", relation="Père", avatarHue=0.07),
    dict(id="bastien", name="Bastien Kermarrec", phone="+33 6 72 39 08 64", relation="Coloc", avatarHue=0.33),
    dict(id="yanis", name="Yanis Ferhat", phone="+33 7 58 14 92 30", relation="Silo — DJ résident", avatarHue=0.75),
    dict(id="mathilde", name="Mathilde Roche", phone="+33 6 20 45 77 81", relation="Silo — gérante",
         email="m.roche@lesilo-lyon.fr", avatarHue=0.12),
    dict(id="raphael", name="Raphaël Sané", phone="+33 6 89 03 26 12", relation="Silo — sécurité", avatarHue=0.03),
    dict(id="kader", name="Kader Benslimane", phone="+33 6 44 71 58 09", relation="Silo — bar", avatarHue=0.47),
    dict(id="lou", name="Lou Perrin", phone="+33 6 15 98 36 70", relation="Run du dimanche", avatarHue=0.40),
    dict(id="nico", name="Nico Lambert", phone="+33 7 66 20 81 45", relation="Silo — régie lumière", avatarHue=0.62),
    dict(id="sofia", name="Sofia Benali", phone="+33 6 93 57 04 18", relation="Silo — bar", avatarHue=0.86),
    dict(id="helene", name="Hélène Castel", phone="+33 4 78 83 21 60", relation="La Friche Nord — direction technique",
         email="h.castel@lafrichenord.fr", avatarHue=0.20),
    dict(id="besson", name="M. Besson (proprio)", phone="+33 6 11 29 84 37", relation="Propriétaire", avatarHue=0.27),
    dict(id="dentiste", name="Cabinet des Chartreux", phone="04 78 28 90 12", relation="Dentiste", avatarHue=0.52),
    dict(id="malik", name="Malik (Anaïs)", phone="+33 6 52 80 13 66", relation="Copain d'Anaïs", avatarHue=0.68),
]

# ---------------------------------------------------------------- messages
convs = []
def conv(cid, participants, msgs, title=None, draft=None):
    c = dict(id=cid, participants=participants, messages=[])
    if title: c["title"] = title
    short = cid[2:]
    for i, m in enumerate(msgs):
        frm, at, text = m[0], m[1], m[2]
        extra = dict(m[3]) if len(m) > 3 else {}
        mid = extra.pop("id", f"m_{short}_{i:03d}")
        msg = dict(id=mid, **{"from": frm}, at=at)
        if text: msg["text"] = text
        msg.update(extra)
        c["messages"].append(msg)
    c["messages"].sort(key=lambda x: x["at"])
    if draft: c["draft"] = draft
    convs.append(c)

U = dict(unread=True)

# --- Anaïs (sister) — the fake 03:07 message sits in the middle of a long family thread
conv("c_anais", ["anais"], [
    ("anais", s(5, "12:14"), "t'as vu le groupe famille ??? papa a mis une photo de lui en maillot 😭"),
    ("me", s(5, "12:40"), "mdr jai vu"),
    ("me", s(5, "12:40"), "il est fier de son bronzage"),
    ("anais", s(8, "18:55"), "tu pourrais garder pistache le we du 10 octobre ??? je pars à annecy avec malik"),
    ("me", s(8, "19:20"), "oui tkt"),
    ("anais", s(8, "19:21"), "t'es la meilleure"),
    ("anais", s(12, "13:02"), "anniv de papa le 24 octobre, on lui offre quoi ???"),
    ("me", s(12, "14:30"), "jsp une platine ? il ecoute ses 33t sur la chaine de 1992"),
    ("anais", s(12, "14:31"), "c'est pas trop cher ??"),
    ("me", s(12, "14:35"), "on fait moitie moitie"),
    ("anais", s(12, "14:35"), "ok go"),
    ("anais", s(17, "21:48"), "t'as des nouvelles de yanis ?"),
    ("me", s(17, "22:30"), "il me rend toujours pas mon casque"),
    ("anais", s(17, "22:31"), "garde tes distances stp"),
    ("me", s(17, "22:33"), "tkt"),
    ("anais", s(23, "07:12"), "regarde qui dort sur ma blouse propre", dict(photo="p_pistache")),
    ("me", s(23, "09:40"), "le boss"),
    ("me", t(1, "13:30"), "jai eu la friche nord"),
    ("anais", t(1, "13:31"), "QUOIII ??? le poste de régie générale ?????"),
    ("me", t(1, "13:31"), "ouais a partir de decembre"),
    ("anais", t(1, "13:32"), "je suis trop fière de toi ❤️ papa va pleurer"),
    ("me", t(1, "13:34"), "dis rien je veux lui dire moi"),
    ("anais", t(2, "17:05"), "t'as dit à yanis ?"),
    ("me", t(2, "17:30"), "ce soir"),
    ("anais", t(2, "17:30"), "courage"),
    ("anais", t(8, "17:02"), "oups j'ai un peu parlé à papa… il va t'écrire 🙈"),
    ("me", t(8, "17:40"), "t'es pas possible"),
    ("anais", t(9, "20:10"), "je te dépose pistache demain 10h ??"),
    ("me", t(9, "20:31"), "11h plutot je finis tard"),
    ("anais", t(9, "20:32"), "ok 11h, sa litière est dans le sac bleu et il mange 2 fois par jour PAS PLUS"),
    ("me", t(10, "12:35"), "pistache a fait un patch", dict(photo="p_pistache_synth")),
    ("anais", t(10, "12:50"), "MDR il a plus de talent que moi"),
    ("anais", t(11, "17:15"), "je passe le récupérer vers 19h, ça va ?"),
    ("me", t(11, "17:20"), "ok"),
    ("anais", t(12, "10:02"), "la platine est commandée !!! 180 chacune ça te va ???"),
    ("me", t(12, "11:15"), "ok je te vire ca ce soir"),
    ("anais", t(14, "13:40"), "t'as vu l'histoire de la fille agressée sur les quais de saône samedi ?? fais gaffe quand tu rentres à pied la nuit stp"),
    ("me", t(14, "15:02"), "je fais gaffe tkt"),
    ("anais", t(16, "23:34"), "je bosse demain à 7h mais écris moi quand t'es rentrée stp ???"),
    ("me", t(16, "23:50"), "oui maman"),
    ("anais", t(16, "23:50"), "😒"),
    ("me", t(17, "02:12"), "je sors, je rentre a pied, je t'ecris en arrivant", dict(id="m_anais_0212")),
    ("anais", t(17, "02:13"), "ok. prends pas les quais stp"),
    ("anais", t(17, "02:47"), "t'as appelé ? ça a coupé direct"),
    ("anais", t(17, "02:48"), "clem ?"),
    ("me", t(17, "03:07"), "Ne t'inquiète pas, je dors chez Yanis. On s'est reparlé. Je t'appelle demain.",
     dict(id="m_anais_0307")),
    ("anais", t(17, "03:10"), "ah ok… vous vous êtes remis ensemble ?? bonne nuit", dict(id="m_anais_0310")),
    ("anais", t(17, "05:10"), "pourquoi ta localisation est aux terreaux ??? t'es pas chez yanis ?", U),
    ("anais", t(17, "05:12"), "clem ?? réponds stp", dict(id="m_anais_0512", unread=True)),
    ("anais", t(17, "05:40"), "j'appelle yanis il répond pas", U),
    ("anais", t(17, "06:05"), "je vais au silo", U),
    ("anais", t(17, "06:48"), "c'est fermé. y a personne. j'appelle la police", U),
    ("anais", t(17, "07:21"), "la police dit qu'on a retrouvé ton téléphone dans le métro. clem je t'en supplie", U),
])

# --- Mathilde (club manager) — polite, complete sentences; "Ne t'inquiète pas"
conv("c_mathilde", ["mathilde"], [
    ("mathilde", s(7, "10:12"), "Bonjour Clémence, je t'envoie le planning de septembre ce soir. Peux-tu me confirmer ta présence le samedi 19 ?"),
    ("me", s(7, "11:40"), "oui ok pour le 19"),
    ("mathilde", s(7, "11:42"), "Parfait, merci."),
    ("me", s(14, "16:20"), "mathilde j'ai toujours pas les heures sup d'aout sur la fiche de paie, 14h en tout"),
    ("mathilde", s(14, "17:05"), "Je regarde avec le cabinet comptable. Ce sera régularisé en septembre, promis."),
    ("me", s(14, "17:10"), "ok merci"),
    ("mathilde", s(22, "11:30"), "Peux-tu me transférer la facture du technicien pour la console ? Le cabinet la réclame."),
    ("me", s(22, "12:02"), "je te la transfere ce soir"),
    ("mathilde", s(26, "03:58"), "Merci pour ce soir, le son était parfait. Le collectif était ravi."),
    ("me", s(26, "11:20"), "trop cool merci"),
    ("mathilde", s(28, "09:45"), "Merci d'être venue hier soir. Tu as oublié ton écharpe grise, je te la rapporte vendredi."),
    ("me", s(28, "10:30"), "ah trop bien merci"),
    ("me", t(1, "10:05"), "les heures sup sont toujours pas dessus"),
    ("mathilde", t(1, "10:40"), "Je sais. C'est une période difficile pour le Silo, je te demande un peu de patience. Ne t'inquiète pas, rien ne sera oublié."),
    ("me", t(1, "10:42"), "ca fait 2 mois mathilde"),
    ("mathilde", t(1, "10:50"), "Je sais."),
    ("mathilde", t(5, "18:20"), "J'ai bien reçu ton courrier. Je suis déçue, je ne te le cache pas. Mais je comprends. On en reparle vendredi, au calme."),
    ("me", t(5, "18:45"), "merci. c'est pas contre toi"),
    ("mathilde", t(9, "13:10"), "Peux-tu arriver à 20h30 ce soir ? Balances avec le live à 21h."),
    ("me", t(9, "13:30"), "ok"),
    ("mathilde", t(14, "11:05"), "Pour vendredi : soirée Basses Fréquences, trois DJ, ouverture 23h. Le planning complet arrive par mail demain."),
    ("me", t(14, "11:20"), "ca marche"),
    ("mathilde", t(16, "22:40"), "Il faut qu'on parle ce soir, après ton service. Pas au club.", dict(id="m_mathilde_2240")),
    ("me", t(16, "22:52"), "ok", dict(id="m_mathilde_2252")),
])

# --- Yanis (DJ, ex) — "tu vas le regretter" is about her leaving for La Friche Nord
conv("c_yanis", ["yanis"], [
    ("me", s(6, "14:02"), "tu peux me rendre mon casque stp j'en ai besoin samedi"),
    ("yanis", s(6, "16:48"), "ouais je le ramène au silo vendredi"),
    ("yanis", s(11, "20:12"), "casque dans ta loge"),
    ("me", s(11, "20:30"), "merci"),
    ("yanis", s(20, "13:05"), "t'as encore mes 3 vinyles blancs de detroit ?"),
    ("me", s(20, "15:40"), "oui je te les rends"),
    ("yanis", s(20, "15:41"), "tranquille"),
    ("yanis", s(29, "23:02"), "y a une rumeur comme quoi tu pars"),
    ("me", s(29, "23:30"), "on en parle pas par msg"),
    ("me", t(2, "18:40"), "je peux te parler avant le service ce soir ?"),
    ("yanis", t(2, "18:52"), "ok 20h au bar"),
    ("yanis", t(2, "23:58"), "tu pouvais me le dire avant l'été. la friche nord sérieux ?"),
    ("me", t(3, "00:10"), "je l'ai su y a 2 jours yanis"),
    ("yanis", t(3, "00:11"), "3 ans qu'on bosse ensemble"),
    ("me", t(3, "00:15"), "je sais"),
    ("yanis", t(3, "13:20"), "désolé pour hier. ça fait juste bizarre"),
    ("me", t(3, "13:45"), "je comprends"),
    ("yanis", t(8, "17:22"), "tu leur as dit oui du coup ?"),
    ("me", t(8, "17:35"), "j'ai signe tout a l'heure"),
    ("yanis", t(8, "17:36"), "ok"),
    ("yanis", t(12, "19:10"), "je te rends tes câbles jack vendredi"),
    ("me", t(12, "19:30"), "ok"),
    ("yanis", t(16, "23:47"), "mathilde t'a dit ? elle me laisse le closing jusqu'à 3h30"),
    ("me", t(16, "23:49"), "cool pour toi"),
    ("yanis", t(17, "01:40"), "kader dit que t'as proposé à nico de venir avec toi à la friche"),
    ("me", t(17, "01:44"), "c'est pas du debauchage yanis, ils cherchent un regisseur lumiere c'est tout"),
    ("yanis", t(17, "01:47"), "et un dj ils cherchent pas ?"),
    ("me", t(17, "01:49"), "demande leur"),
    ("yanis", t(17, "01:52"), "tu vas le regretter sérieux", dict(id="m_yanis_0152")),
    ("me", t(17, "01:53"), "de quoi"),
    ("yanis", t(17, "01:55"), "de partir. le silo c'est chez toi. la friche c'est une usine à subventions"),
    ("me", t(17, "01:57"), "on en reparle demain la je bosse"),
    ("yanis", t(17, "03:48"), "t'es bien rentrée ?", U),
])

# --- Bastien (flatmate) — says he slept; he picked up at 02:14
conv("c_bastien", ["bastien"], [
    ("bastien", s(7, "19:02"), "on est à sec de PQ et de liquide vaisselle"),
    ("me", s(7, "19:30"), "je passe a la superette en rentrant"),
    ("bastien", s(9, "18:15"), "le proprio passe demain matin pour la chaudière, t'es là ?"),
    ("me", s(9, "18:40"), "oui jusqu'a midi"),
    ("bastien", s(15, "12:20"), "colis pour toi chez la gardienne"),
    ("me", s(15, "12:45"), "mes modules 🙏"),
    ("bastien", s(21, "20:10"), "planning ménage : toi salle de bain, moi évier + poubelles. marché conclu ?"),
    ("me", s(21, "20:30"), "marche conclu"),
    ("bastien", s(30, "18:04"), "loyer : 1080 / 2 = 540 chacun, je vire au proprio lundi"),
    ("me", s(30, "18:30"), "je te fais le virement ce soir"),
    ("bastien", t(4, "11:02"), "t'as couru combien ce matin ?"),
    ("me", t(4, "11:10"), "12km"),
    ("bastien", t(4, "11:10"), "psychopathe"),
    ("bastien", t(10, "15:48"), "le chat de ta sœur a vomi sur mon tapis"),
    ("me", t(10, "16:02"), "mdrrr desole je nettoie en rentrant"),
    ("bastien", t(13, "21:30"), "ciné jeudi soir ? y a le film coréen au ciné de la croix-rousse"),
    ("me", t(13, "21:44"), "je bosse pas jeudi go"),
    ("bastien", t(16, "23:50"), "rentré du bar, j'ai laissé la lumière de l'entrée allumée pour toi"),
    ("me", t(16, "23:52"), "merci"),
    ("bastien", t(17, "02:16"), "dsl j'ai bu 3 bières je peux pas conduire, prends un vélo'v ou un taxi", dict(id="m_bastien_0216")),
    ("me", t(17, "02:17"), "laisse tomber"),
    ("bastien", t(17, "07:32"), "t'es pas rentrée ? ton lit est pas défait", U),
    ("bastien", t(17, "07:36"), "clem ??", U),
])

# --- Raphaël (security) — insistent offers to walk her home, for weeks
conv("c_raphael", ["raphael"], [
    ("raphael", s(12, "01:58"), "Je te raccompagne ce soir ? Les quais c'est pas top la nuit."),
    ("me", s(12, "02:03"), "non merci ca va"),
    ("raphael", s(19, "02:05"), "Je peux te déposer, j'ai le scooter."),
    ("me", s(19, "02:09"), "c'est gentil mais non"),
    ("raphael", s(26, "03:12"), "T'es rentrée ?"),
    ("me", s(26, "11:22"), "oui dsl je dormais"),
    ("raphael", t(3, "18:40"), "Tu sais que tu peux compter sur moi hein."),
    ("me", t(3, "19:05"), "oui raphael merci"),
    ("raphael", t(10, "01:55"), "Je te raccompagne ? 5 min."),
    ("me", t(10, "01:58"), "raphael stp"),
    ("raphael", t(10, "01:58"), "Ok ok."),
    ("raphael", t(17, "02:08"), "Tu pars à quelle heure ? Je t'accompagne jusqu'au quai."),
    ("me", t(17, "02:09"), "juste a la porte alors"),
    ("raphael", t(17, "04:10"), "T'es rentrée ?", U),
])

# --- Staff group
G = ["mathilde", "kader", "raphael", "yanis", "nico", "sofia"]
conv("c_staff", G, [
    ("mathilde", s(5, "17:02"), "Bonjour à tous. Ce soir, ouverture à 23h. Merci d'être à l'heure."),
    ("kader", s(5, "17:10"), "👍"),
    ("nico", s(11, "19:30"), "qqn a vu la clé du local lumière ?"),
    ("sofia", s(11, "19:34"), "tiroir de la caisse"),
    ("nico", s(11, "19:35"), "t'es une reine"),
    ("kader", s(12, "04:12"), "caisse fermée. record de la saison 🍾"),
    ("me", s(19, "23:10"), "euh les futs devant l'issue de secours cour c'est normal ?", dict(photo="p_issue_1")),
    ("mathilde", s(19, "23:14"), "C'est provisoire, la livraison est arrivée en avance. Kader, peux-tu les déplacer demain ?"),
    ("kader", s(19, "23:15"), "ok patronne"),
    ("raphael", s(24, "17:30"), "Rappel : pas de sac à dos en loge le samedi. Consigne de la préfecture."),
    ("yanis", s(26, "18:02"), "b2b avec le collectif ce soir, prévoyez des bouchons 😈"),
    ("sofia", s(26, "18:05"), "on survivra"),
    ("mathilde", s(27, "13:10"), "Apéro ce soir chez moi à partir de 18h30 pour fêter la rentrée. L'adresse est dans l'invitation. Venez comme vous êtes."),
    ("sofia", s(27, "13:15"), "yesss"),
    ("nico", s(27, "13:40"), "je peux pas, le petit a de la fièvre 😭 amusez vous"),
    ("kader", s(27, "19:44"), "la patronne a sorti le grand jeu", dict(photo="p_apero_keys")),
    ("nico", s(27, "19:50"), "vous abusez"),
    ("raphael", t(4, "03:40"), "Fermeture ok, rien à signaler."),
    ("kader", t(4, "03:52"), "compteur ce soir : 1040 entrées 😬"),
    ("mathilde", t(4, "10:12"), "Merci de ne pas communiquer les chiffres de fréquentation sur ce groupe."),
    ("mathilde", t(7, "09:30"), "Livraison des fûts décalée à jeudi. Merci de laisser la cour libre."),
    ("me", t(10, "22:30"), "toujours les futs devant la sortie de secours", dict(photo="p_issue_2")),
    ("mathilde", t(10, "22:41"), "Je m'en occupe."),
    ("nico", t(13, "12:02"), "je peux échanger mon vendredi 23 avec qqn ?"),
    ("sofia", t(13, "12:30"), "moi je veux bien"),
    ("mathilde", t(15, "18:32"), "Le planning de vendredi est dans vos mails. Soirée Basses Fréquences, grosse affluence attendue."),
    ("sofia", t(16, "20:05"), "qqn peut ramener des citrons ? on est à sec"),
    ("kader", t(16, "20:07"), "je passe au primeur"),
    ("yanis", t(16, "22:15"), "le retour cabine est bizarre"),
    ("me", t(16, "22:16"), "je regarde"),
    ("me", t(16, "22:22"), "c'etait le retour gauche, c'est bon"),
    ("mathilde", t(17, "01:31"), "Je file. Kader, tu fermes la caisse ? Bonne fin de soirée à tous."),
    ("kader", t(17, "01:32"), "oui t'inquiète"),
    ("raphael", t(17, "02:13"), "clem est partie je l'ai laissée au coin du quai", dict(id="m_staff_0213")),
    ("nico", t(17, "02:14"), "bisous clem 👋"),
    ("kader", t(17, "02:49"), "yanis en feu ce soir 🔥", dict(photo="p_booth_0248")),
    ("sofia", t(17, "02:50"), "la piste est pleine à craquer"),
    ("raphael", t(17, "03:05"), "Grosse file encore.", dict(photo="p_door_0304")),
    ("yanis", t(17, "03:36"), "merci la team, closing de fou"),
    ("kader", t(17, "04:02"), "caisse fermée, je rentre. bonne nuit"),
    ("raphael", t(17, "04:05"), "Porte fermée."),
], title="Staff Silo 🔊")

# --- Lou (running friend)
conv("c_lou", ["lou"], [
    ("lou", s(12, "20:15"), "demain 9h au pont de la guill ?"),
    ("me", s(12, "20:40"), "go mais 9h30 je finis a 2h"),
    ("lou", s(13, "11:30"), "10km en 52 min je suis morte 💀"),
    ("me", s(13, "11:45"), "t'as tout donne"),
    ("lou", s(18, "22:10"), "t'as commencé la série danoise ?"),
    ("me", s(18, "22:40"), "episode 3 je suis accro"),
    ("lou", s(19, "16:00"), "pas de run demain j'ai mal au genou 😩"),
    ("me", s(19, "16:20"), "repose toi"),
    ("lou", t(3, "15:12"), "demain 9h30 ?"),
    ("me", t(3, "15:30"), "oui"),
    ("lou", t(4, "10:52"), "envoie ton temps"),
    ("me", t(4, "10:55"), None, dict(photo="p_run_screen")),
    ("lou", t(4, "10:56"), "t'es une machine"),
    ("lou", t(10, "18:00"), "demain même heure ?"),
    ("me", t(10, "18:30"), "oui"),
    ("lou", t(11, "12:04"), "trop beau ce matin sur les berges"),
    ("me", t(11, "12:10"), "grave"),
    ("lou", t(15, "09:20"), "ce dimanche je peux pas, anniv de ma nièce"),
    ("me", t(15, "09:45"), "ok on se cale mercredi soir"),
    ("lou", t(16, "19:40"), "bon courage pour ta soirée basses fréquences ! j'ai déjà pris des places pour la friche en décembre haha"),
    ("me", t(16, "19:52"), "mdr viens me voir"),
    ("lou", t(17, "07:12"), "clem ta sœur m'a appelée. t'es où ?", U),
])

conv("c_papa", ["papa"], [
    ("papa", s(13, "10:05"), "Bonjour ma grande. As-tu reçu le colis de ta grand-mère ? Bises. Papa"),
    ("me", s(13, "12:30"), "oui merci papa"),
    ("papa", s(27, "11:20"), "Tu viens déjeuner le dimanche 25 octobre ? Ta sœur vient. Papa"),
    ("me", s(27, "12:02"), "oui"),
    ("papa", t(8, "17:48"), "Anaïs m'a dit que tu avais une bonne nouvelle ?? Papa"),
    ("me", t(8, "17:55"), "elle peut pas se taire mdr je t'appelle ce soir"),
    ("papa", t(8, "20:40"), "Je suis très fier de toi. Papa"),
    ("papa", t(17, "07:10"), "Clémence, ta sœur m'a appelé. Rappelle-moi. Papa", U),
])

conv("c_kader", ["kader"], [
    ("kader", s(12, "18:40"), "tu peux me laisser les clés de la régie ce soir ? je dois récup la rallonge"),
    ("me", s(12, "18:55"), "dans ma loge"),
    ("kader", t(1, "22:10"), "c'est vrai pour la friche ??"),
    ("me", t(1, "22:30"), "oui mais garde le pour toi"),
    ("kader", t(1, "22:31"), "motus"),
    ("kader", t(16, "21:45"), "tu veux un truc à boire avant l'ouverture ?"),
    ("me", t(16, "21:47"), "une limonade stp"),
    ("kader", t(17, "06:55"), "ta sœur m'a appelé. t'es partie à 2h c'est ça ? réponds", U),
])

conv("c_nico", ["nico"], [
    ("nico", s(25, "15:10"), "tu peux me montrer ton patch pour la console lumière ? le dmx déconne"),
    ("me", s(25, "15:40"), "je te montre demain avant l'ouverture"),
    ("nico", t(12, "14:20"), "la friche cherche vraiment un régisseur lumière ?"),
    ("me", t(12, "14:50"), "oui envoie ton cv a helene castel"),
    ("nico", t(12, "14:51"), "merci clem t'es un amour"),
])

conv("c_helene", ["helene"], [
    ("helene", t(1, "12:35"), "Bonjour Clémence, je vous ai envoyé la proposition par mail. Hâte de travailler avec vous !"),
    ("me", t(1, "12:50"), "merci beaucoup je lis ca ce soir"),
    ("helene", t(8, "16:10"), "Contrat signé, bienvenue ! On vous prépare un badge pour le 1er décembre."),
    ("me", t(8, "16:30"), "merci !!"),
])

conv("c_besson", ["besson"], [
    ("besson", s(9, "09:02"), "Bonjour, je passerai demain jeudi à 10h pour l'entretien de la chaudière. Cordialement, R. Besson"),
    ("me", s(9, "10:15"), "bonjour, c'est note, je serai la"),
    ("besson", s(10, "11:20"), "Chaudière OK. Bonne journée."),
])

conv("c_dentiste", ["dentiste"], [
    ("dentiste", s(21, "10:00"), "Cabinet des Chartreux : rappel de votre RDV le mardi 22/09 à 09h30. Merci de prévenir en cas d'empêchement."),
])

# ---------------------------------------------------------------- calls
calls = []
def call(cid, contact, direction, at, dur):
    calls.append(dict(id=cid, contact=contact, direction=direction, at=at, durationSeconds=dur))
call("k01", "papa", "incoming", s(6, "11:00"), 640)
call("k02", "anais", "outgoing", s(8, "19:12"), 1420)
call("k03", "dentiste", "incoming", s(15, "10:05"), 45)
call("k04", "yanis", "missed", s(20, "12:30"), 0)
call("k05", "lou", "outgoing", s(13, "09:05"), 31)
call("k06", "helene", "incoming", t(1, "11:40"), 540)
call("k07", "anais", "outgoing", t(1, "13:40"), 890)
call("k08", "mathilde", "incoming", t(1, "14:10"), 312)
call("k09", "yanis", "missed", t(3, "12:40"), 0)
call("k10", "papa", "outgoing", t(8, "20:05"), 1510)
call("k11", "bastien", "incoming", t(10, "16:20"), 62)
call("k12", "anais", "incoming", t(11, "18:52"), 38)
call("k13", "besson", "incoming", t(13, "09:15"), 120)
call("k14", "lou", "incoming", t(14, "19:30"), 402)
call("k15", "mathilde", "missed", t(16, "16:48"), 0)
call("k16", "kader", "outgoing", t(16, "20:40"), 35)
call("k_bastien_0214", "bastien", "outgoing", t(17, "02:14"), 48)
call("k_mathilde_0219", "mathilde", "incoming", t(17, "02:19"), 112)
call("k_anais_0246", "anais", "outgoing", t(17, "02:46"), 4)
call("k_anais_0249", "anais", "missed", t(17, "02:49"), 0)
call("k_anais_0513", "anais", "missed", t(17, "05:13"), 0)
call("k_anais_0552", "anais", "missed", t(17, "05:52"), 0)
call("k_papa_0708", "papa", "missed", t(17, "07:08"), 0)
call("k_lou_0714", "lou", "missed", t(17, "07:14"), 0)

# ---------------------------------------------------------------- places & tracks
# (id, name, kind, latitude, longitude, revealedBy)
PLACES = [
    ("pl_home", "Domicile — montée de la Grande-Côte", "home", 45.7715, 4.8325, None),
    ("pl_silo", "Le Silo — quai Rambaud", "work", 45.7400, 4.8170, None),
    ("pl_docks", "Parking des Docks", "parking", 45.7385, 4.8195, None),
    ("pl_arloing", "Quai Arloing — Vaise", "street", 45.7725, 4.8105,
     ["calendar:c_apero_mathilde", "photoInfo:p_pocket_0309"]),
    ("pl_terreaux", "Station Terreaux-Sud", "station", 45.7675, 4.8345, None),
    ("pl_paulbert", "Rue Paul-Bert — chez Anaïs", "home", 45.7570, 4.8520, None),
    ("pl_gratteciel", "Villeurbanne — Gratte-Ciel", "district", 45.7695, 4.8815, ["message:m_anais_0307"]),
    ("pl_berges", "Berges du Rhône", "park", 45.7545, 4.8430, None),
    ("pl_marche", "Marché de la Croix-Rousse", "shop", 45.7760, 4.8320, None),
    ("pl_friche", "La Friche Nord", "work", 45.7800, 4.8040, ["mail:mail_friche_offer"]),
]
places = []
for pid, name, kind, lat, lon, revealed in PLACES:
    # Stylised fallback map: longitude 4.795→4.890 maps to x, latitude 45.785→45.735 maps to y.
    x = min(0.97, max(0.03, (lon - 4.795) / 0.095))
    y = min(0.97, max(0.03, (45.785 - lat) / 0.05))
    pl = dict(id=pid, name=name, kind=kind, x=round(x, 3), y=round(y, 3), latitude=lat, longitude=lon)
    if revealed:
        pl["revealedBy"] = revealed
    places.append(pl)

tracks = [
    # The phone itself.
    dict(id="t_me", contact="me", points=[
        dict(id="tp_me_1", at=t(8, "15:02"), place="pl_friche"),
        dict(id="tp_me_2", at=t(9, "20:25"), place="pl_silo"),
        dict(id="tp_me_3", at=t(10, "02:40"), place="pl_home"),
        dict(id="tp_me_4", at=t(10, "20:40"), place="pl_silo"),
        dict(id="tp_me_5", at=t(11, "09:35"), place="pl_berges"),
        dict(id="tp_me_6", at=t(11, "11:05"), place="pl_marche"),
        dict(id="tp_me_7", at=t(14, "18:10"), place="pl_home"),
        dict(id="tp_me_8", at=t(16, "20:35"), place="pl_silo"),
        dict(id="tp_me_9", at=t(17, "02:12"), place="pl_silo", note="Départ"),
        dict(id="tp_me_10", at=t(17, "02:24"), place="pl_docks"),
        dict(id="tp_me_11", at=t(17, "02:58"), place="pl_arloing"),
        dict(id="tp_me_12", at=t(17, "03:07"), place="pl_arloing"),
        dict(id="tp_me_13", at=t(17, "04:36"), place="pl_arloing", note="Départ"),
        dict(id="tp_me_14", at=t(17, "04:52"), place="pl_terreaux"),
        dict(id="tp_me_15", at=t(17, "05:12"), place="pl_terreaux", note="Dernière position connue"),
    ]),
    # The flatmate shares his location: home all night.
    dict(id="t_bastien", contact="bastien", points=[
        dict(id="tp_ba_1", at=t(16, "18:30"), place="pl_home"),
        dict(id="tp_ba_2", at=t(16, "23:50"), place="pl_home"),
        dict(id="tp_ba_3", at=t(17, "02:16"), place="pl_home"),
        dict(id="tp_ba_4", at=t(17, "04:30"), place="pl_home"),
        dict(id="tp_ba_5", at=t(17, "07:30"), place="pl_home"),
    ]),
    # The sister shares her location: home, then out looking at dawn.
    dict(id="t_anais", contact="anais", points=[
        dict(id="tp_an_1", at=t(16, "19:10"), place="pl_paulbert"),
        dict(id="tp_an_2", at=t(17, "03:10"), place="pl_paulbert"),
        dict(id="tp_an_3", at=t(17, "06:10"), place="pl_paulbert", note="Départ"),
        dict(id="tp_an_4", at=t(17, "06:34"), place="pl_silo"),
        dict(id="tp_an_5", at=t(17, "07:25"), place="pl_silo"),
    ]),
]

# ---------------------------------------------------------------- photos
photos = []
def photo(pid, taken, scene, caption, details, source="camera", place=None, frm=None, received=None, device="iPhone 14",
          style=None, lines=None):
    p = dict(id=pid, takenAt=taken, source=source, scene=scene, caption=caption, details=details)
    if style: p["style"] = style
    if lines: p["lines"] = lines
    if place: p["place"] = place
    if frm: p["from"] = frm
    if received: p["receivedAt"] = received
    if device: p["device"] = device
    photos.append(p)

def at(year, month, day, hm):
    return f"{year}-{month:02d}-{day:02d} {hm}"

# Old camera roll
old = [
    ("p_old01", at(2019, 8, 24, "23:40"), "concert", "Festival d'été, 2019. La scène au loin.", "Des lasers verts, la foule en contre-jour.", None),
    ("p_old02", at(2021, 6, 21, "22:15"), "street_night", "Fête de la musique 2021, rue de la République.", "Un sound system sur un trottoir, des gens qui dansent.", "Lyon 2e"),
    ("p_old03", at(2022, 2, 3, "21:05"), "party", "Anniversaire, 25 ans.", "Un gâteau avec deux bougies « 2 » et « 5 », des guirlandes.", None),
    ("p_old04", at(2023, 7, 14, "21:30"), "sunset", "Coucher de soleil sur la Saône, juillet 2023.", "Des péniches, la passerelle en contre-jour.", "Quai Saint-Vincent"),
    ("p_old05", at(2024, 12, 24, "20:10"), "interior_warm", "Réveillon chez Papa.", "Une table, des bougies, une platine vinyle à l'ancienne sur le buffet.", None),
    ("p_old06", at(2025, 5, 10, "01:20"), "club", "Selfie en cabine avec Yanis, mai 2025.", "Deux silhouettes sous une lumière rouge, un casque partagé.", "Le Silo"),
]
for pid, taken, scene, cap, det, place in old:
    photo(pid, taken, scene, cap, det, place=place, style="old", device="iPhone 8" if taken < "2023" else "iPhone 14")

# Everyday photos of the last six weeks
banal = [
    ("p_synth01", s(6, "17:20"), "desk_night", "Le rack de modules, câbles partout.", "Une vingtaine de câbles colorés, une petite lampe orange. Rien d'autre.", "Domicile", None),
    ("p_club01", s(11, "20:40"), "club", "Le Silo vide, avant l'ouverture.", "La boule à facettes éteinte, les lumières de service allumées.", "Le Silo", None),
    ("p_berges01", s(13, "09:58"), "park", "Berges du Rhône, run du dimanche.", "Des platanes, un cycliste, le fleuve gris.", "Berges du Rhône", None),
    ("p_vinyl01", s(16, "18:05"), "books", "Trois vinyles achetés chez le disquaire.", "Des pochettes sans titre, une étiquette « 12€ ».", "Domicile", None),
    ("p_loge01", s(19, "21:10"), "mirror", "Selfie dans le miroir de la loge, casque autour du cou.", "Des stickers sur le miroir, un gobelet de thé.", "Le Silo", "selfie"),
    ("p_view01", s(20, "10:30"), "view", "Lyon depuis le haut de la montée de la Grande-Côte.", "Les toits, Fourvière dans la brume.", "Domicile", None),
    ("p_sunset01", s(24, "19:30"), "sunset", "Coucher de soleil depuis la passerelle Saint-Vincent.", "Le ciel orange, des gens assis sur les marches.", None, None),
    ("p_plant01", s(28, "08:50"), "plant", "Le monstera de Bastien a une nouvelle feuille.", "Une plante près de la fenêtre, un arrosoir jaune.", "Domicile", None),
    ("p_ceiling01", s(30, "07:02"), "ceiling", "Le plafond de la chambre.", "Photo prise par erreur au réveil.", "Domicile", "blurry"),
    ("p_quick01", t(2, "14:12"), "street_day", "Une affiche collée sur un poteau.", "« Basses Fréquences — vendredi 16 octobre — Le Silo ».", None, "quick"),
    ("p_rain01", t(6, "08:20"), "rain", "Pluie sur la fenêtre du salon.", "Des gouttes, la rue floue derrière.", "Domicile", None),
    ("p_friche01", t(8, "14:50"), "gallery", "La grande salle de La Friche Nord, vide.", "Un plafond très haut, des passerelles métalliques, une console sous une bâche.", "La Friche Nord", None),
    ("p_night01", t(10, "02:35"), "street_night", "La montée de la Grande-Côte, de nuit.", "Les marches désertes, trois réverbères.", "Domicile", "night"),
    ("p_berges02", t(11, "10:02"), "park", "Selfie avec Lou après le run.", "Deux silhouettes essoufflées, le Rhône derrière.", "Berges du Rhône", "selfie"),
    ("p_market01", t(11, "11:10"), "street_day", "Le marché de la Croix-Rousse.", "Des étals de légumes, une file devant le fromager.", "Marché de la Croix-Rousse", None),
    ("p_metro01", s(22, "09:02"), "metro", "Métro presque vide, le matin.", "Un siège vide, une publicité floue.", None, None),
    ("p_club02", t(16, "20:50"), "club", "Le Silo avant la soirée Basses Fréquences.", "Les enceintes empilées de chaque côté de la scène, personne encore.", "Le Silo", None),
    ("p_console01", t(16, "21:30"), "desk_night", "La console son, prête.", "Des faders éclairés, une feuille de patch scotchée à côté.", "Le Silo", None),
    ("p_selfie01", t(16, "23:40"), "selfie", "Selfie en régie, soirée Basses Fréquences.", "Le visage éclairé en bleu, la foule floue derrière.", "Le Silo", "selfie"),
]
for pid, taken, scene, cap, det, place, style in banal:
    photo(pid, taken, scene, cap, det, place=place, style=style)

# Documents, receipts, screenshots (legible text in `lines`)
photo("p_receipt01", s(16, "18:02"), "receipt", "Ticket du disquaire.", "Trois vinyles d'occasion.",
      place="Croix-Rousse", style="document",
      lines=["DISQUES DE LA COLLINE", "16/09/2026  17:58", "VINYLE OCCASION   12,00", "VINYLE OCCASION   12,00",
             "VINYLE OCCASION   15,00", "TOTAL            39,00 €", "CB"])
photo("p_invoice01", s(22, "19:40"), "document", "Facture du technicien pour la console.", "À transférer à Mathilde.",
      place="Domicile", style="document",
      lines=["ATELIER SON RHÔNE", "Facture n° 2026-117", "Réparation console — le Silo", "Remplacement 2 faders",
             "Total TTC   340,00 €"])
photo("p_run_screen", t(4, "10:48"), "screenshot", "Capture : la course de dimanche.", "12,1 km, parcours le long du Rhône.",
      style="screenshot",
      lines=["Course à pied", "Dimanche 4 octobre · 09:36", "Distance   12,1 km", "Durée      1:03:12",
             "Allure     5'13\" /km"])
photo("p_contract", t(8, "15:20"), "document", "Contrat de travail — La Friche Nord.", "Première page, signée.",
      place="La Friche Nord", style="document",
      lines=["LA FRICHE NORD", "Contrat de travail à durée indéterminée", "Poste : régisseuse générale",
             "Prise de poste : 1er décembre 2026", "Signé à Lyon, le 8 octobre 2026"])
photo("p_meteo", t(16, "18:04"), "screenshot", "Capture : météo de la nuit.", "Il va faire froid.",
      style="screenshot",
      lines=["Météo — Lyon", "Ven 16  22h   7°", "Sam 17  02h   4°", "Sam 17  05h   2°", "Brouillard sur la Saône"])

# The emergency exit, blocked by kegs (attached to the report mail as well)
photo("p_issue_1", s(19, "23:08"), "parking_night", "La cour du Silo, de nuit : des fûts empilés.",
      "Six fûts métalliques contre une porte verte marquée « Sortie de secours ». La barre anti-panique est bloquée.",
      place="Le Silo", style="night")
photo("p_issue_2", t(10, "22:28"), "parking_night", "La cour du Silo, encore les fûts.",
      "Huit fûts cette fois, devant la même porte verte. Un chariot est garé juste devant.",
      place="Le Silo", style="night")

# The cat
photo("p_pistache", s(23, "07:05"), "cat", "Pistache, le chat d'Anaïs, couché sur une blouse.",
      "Un chat tigré roulé en boule sur un tissu bleu clair.",
      source="received", frm="anais", received=s(23, "07:12"), place="Rue Paul-Bert", device="iPhone 13")
photo("p_pistache_synth", t(10, "12:33"), "cat", "Pistache assis sur le rack de modules.",
      "Le chat a une patte sur un câble jaune. Des voyants rouges allumés.", place="Domicile")

# Received from the staff: the apéro, the booth, the door
photo("p_apero_keys", s(27, "19:41"), "interior_warm", "Apéro chez Mathilde : des verres sur une table basse.",
      "Mathilde pose ses clés sur la table basse : un porte-clés en cuir rouge avec un grand M doré. Parquet clair.",
      source="received", frm="kader", received=s(27, "19:44"), place="Vaise, Lyon", device="Galaxy A54")
photo("p_booth_0248", t(17, "02:48"), "club", "La cabine DJ, lumières rouges.",
      "Yanis aux platines, casque sur une oreille. L'horloge de la régie indique 02:48.",
      source="received", frm="kader", received=t(17, "02:49"), place="Le Silo", device="Galaxy A54")
photo("p_door_0304", t(17, "03:04"), "street_night", "La file d'attente devant l'entrée du Silo.",
      "Une trentaine de personnes derrière les barrières. Dans la vitre de la porte, le reflet d'une doudoune orange : celle de Raphaël. "
      "L'enseigne lumineuse au-dessus de l'entrée affiche 03:04.",
      source="received", frm="raphael", received=t(17, "03:05"), place="Le Silo", device="iPhone 12")

# The accidental shot taken with Clémence's phone at 03:09, in Vaise
photo("p_pocket_0309", t(17, "03:09"), "pocket", "Photo floue, sombre.",
      "Photo floue, prise par erreur. Un parquet clair, le pied d'une table basse, et un porte-clés en cuir rouge avec un grand M doré.",
      place="Quai Arloing — Vaise", style="blurry")

# ---------------------------------------------------------------- calendar
calendar = [
    dict(id="c_rdv_dentiste", start=s(22, "09:30"), end=s(22, "10:00"), title="Dentiste", location="Cabinet des Chartreux"),
    dict(id="c_apero_mathilde", start=s(27, "18:30"), end=s(27, "22:00"), title="Apéro staff chez Mathilde",
         location="14 quai Arloing, 3e ét. — Vaise", notes="Code 4127B. Apporter une bouteille."),
    dict(id="c_run_1004", start=t(4, "09:30"), end=t(4, "10:45"), title="Run berges avec Lou", location="Pont de la Guillotière"),
    dict(id="c_loyer", start=t(5, "00:00"), title="Loyer — virement à Bastien (540 €)", allDay=True),
    dict(id="c_friche_sign", start=t(8, "15:00"), end=t(8, "16:00"), title="Signature contrat — La Friche Nord",
         location="La Friche Nord, Vaise", notes="Apporter RIB + pièce d'identité."),
    dict(id="c_pistache", start=t(10, "00:00"), title="Garde Pistache 🐈", allDay=True, notes="Anaïs le dépose à 11h, le récupère dimanche 19h."),
    dict(id="c_run_1011", start=t(11, "09:30"), end=t(11, "10:45"), title="Run berges avec Lou", location="Pont de la Guillotière"),
    dict(id="c_cine", start=t(15, "20:15"), title="Ciné avec Bastien", location="Croix-Rousse"),
    dict(id="c_silo_1016", start=t(16, "21:00"), end=t(17, "02:00"), title="Silo — régie son (Basses Fréquences)", location="Le Silo"),
    dict(id="c_inspection", start=t(19, "10:00"), end=t(19, "12:00"), title="Visite inspection — Silo", location="Le Silo, quai Rambaud",
         notes="Accusé de réception reçu le 15/10."),
    dict(id="c_papa_bday", start=t(24, "00:00"), title="🎂 Anniv Papa", allDay=True, notes="Platine : moitié avec Anaïs (180 €)."),
    dict(id="c_dej_papa", start=t(25, "12:30"), title="Déjeuner chez Papa", location="Villefranche"),
    dict(id="c_last_day", start=t(30, "00:00", 11), title="Dernier jour au Silo", allDay=True),
]

# ---------------------------------------------------------------- notes
notes = [
    dict(id="n_silo", title="Silo — à noter", createdAt=s(19, "23:20"), modifiedAt=t(12, "23:30"),
         body="19/09 : fûts devant l'issue de secours (cour). Photo.\n03/10 : 1040 entrées au compteur (jauge 800).\n"
              "10/10 : fûts toujours là.\nHeures sup août + sept : 26 h, toujours pas payées.\n\n→ inspection du travail ?"),
    dict(id="n_friche", title="Friche Nord — questions", createdAt=s(30, "22:10"), modifiedAt=t(7, "23:05"),
         body="- salaire brut / heures de nuit ?\n- date : 1er décembre\n- préavis Silo : 1 mois → dernier jour 30/11\n"
              "- badge + parking\n- demander pour Nico (régie lumière)"),
    dict(id="n_patch", title="Patch basse — Basses Fréquences", createdAt=t(12, "17:40"), modifiedAt=t(15, "16:20"),
         body="VCO1 dent de scie → filtre LP, résonance 11h\nLFO lent sur cutoff\nSub : sinus -1 oct\nNe pas oublier le limiteur sur le master"),
    dict(id="n_courses", title="Courses coloc", createdAt=s(7, "19:25"), modifiedAt=t(14, "18:20"),
         body="- PQ\n- liquide vaisselle\n- café\n- croquettes (pistache ?)\n- piles"),
    dict(id="n_vinyles", title="Vinyles à chercher", createdAt=at(2026, 6, 2, "11:00"), modifiedAt=s(16, "18:10"),
         body="- réédition du premier album de la scène de Detroit\n- maxis house 92–95\n- rendre les 3 blancs à Yanis !!"),
]

# ---------------------------------------------------------------- mail
ME = "clem.aubry@mailo.fr"
mails = [
    dict(id="mail_facture", folder="inbox", fromName="Atelier Son Rhône", fromAddress="contact@atelierson-rhone.fr", to=ME,
         at=s(22, "17:12"), subject="Facture 2026-117 — réparation console",
         body="Bonjour,\n\nVeuillez trouver ci-joint la facture pour le remplacement des deux faders de la console du Silo.\n\nCordialement,\nL'Atelier",
         attachments=["Facture_2026-117.pdf"]),
    dict(id="mail_run", folder="inbox", fromName="Club de course Rive Gauche", fromAddress="news@courserivegauche.fr", to=ME,
         at=s(30, "08:00"), subject="Octobre : sorties longues le dimanche 🏃",
         body="Rendez-vous chaque dimanche à 9h30 au pont de la Guillotière. Deux groupes : 10 et 15 km."),
    dict(id="mail_friche_offer", folder="inbox", fromName="Hélène Castel", fromAddress="h.castel@lafrichenord.fr", to=ME,
         at=t(1, "12:30"), subject="Proposition — poste de régisseuse générale",
         body="Bonjour Clémence,\n\nSuite à nos échanges, j'ai le plaisir de vous proposer le poste de régisseuse générale de La Friche Nord, "
              "en CDI, à partir du 1er décembre 2026.\n\nVous trouverez la proposition détaillée en pièce jointe. Nous pourrions signer "
              "le contrat le jeudi 8 octobre à 15h, sur place, quai de la Friche à Vaise.\n\nAu plaisir,\nHélène Castel\nDirection technique — La Friche Nord",
         attachments=["Proposition_regie_generale.pdf"]),
    dict(id="mail_banque", folder="inbox", fromName="Banque Saône & Rhône", fromAddress="releves@bsr-banque.fr", to=ME,
         at=t(3, "07:00"), subject="Votre relevé de septembre est disponible",
         body="Votre relevé de compte est disponible dans votre espace personnel.", attachments=["Releve_2026-09.pdf"]),
    dict(id="mail_demission", folder="sent", fromName="Clémence Aubry", fromAddress=ME, to="m.roche@lesilo-lyon.fr",
         at=t(5, "10:02"), subject="Démission",
         body="Bonjour Mathilde,\n\nJe t'informe de ma démission de mon poste de régisseuse son. Mon préavis d'un mois commence "
              "aujourd'hui ; mon dernier jour serait le 30 novembre si on s'arrange pour les congés.\n\nMerci pour ces trois ans.\n\nClémence"),
    dict(id="mail_signalement", folder="sent", fromName="Clémence Aubry", fromAddress=ME, to="signalements.rhone@inspection-travail.fr",
         at=t(13, "11:20"), subject="Signalement — établissement Le Silo, quai Rambaud (Lyon 2e)",
         body="Bonjour,\n\nJe travaille au Silo, quai Rambaud, depuis trois ans. Je souhaite signaler :\n\n"
              "- l'issue de secours de la cour est régulièrement bloquée par des fûts (photos du 19 septembre et du 10 octobre) ;\n"
              "- l'effectif dépasse la jauge autorisée de 800 personnes presque chaque week-end (1040 entrées le samedi 3 octobre).\n\n"
              "Je préfère que mon nom ne soit pas communiqué à l'employeur.\n\nClémence Aubry",
         attachments=["issue_secours_1.jpg", "issue_secours_2.jpg"]),
    dict(id="mail_inspection_ack", folder="inbox", fromName="Inspection du travail — Rhône",
         fromAddress="signalements.rhone@inspection-travail.fr", to=ME, at=t(15, "16:05"),
         subject="Accusé de réception — votre signalement du 13 octobre",
         body="Madame,\n\nNous accusons réception de votre signalement du 13 octobre 2026 concernant l'établissement « Le Silo », "
              "quai Rambaud, Lyon 2e (encombrement d'une issue de secours, dépassement de l'effectif autorisé).\n\n"
              "Une visite de contrôle est programmée le lundi 19 octobre à 10h. Conformément à la procédure, l'exploitant en est informé "
              "ce jour. Votre identité ne lui est pas communiquée.\n\nEn cas de manquement grave, une fermeture administrative temporaire "
              "peut être proposée au préfet.\n\nCordialement,\nUnité de contrôle Lyon Centre"),
    dict(id="mail_running_order", folder="inbox", fromName="Mathilde Roche", fromAddress="m.roche@lesilo-lyon.fr",
         to="equipe@lesilo-lyon.fr", at=t(15, "18:30"), subject="Vendredi 16 — Basses Fréquences : planning",
         body="Bonjour à toutes et à tous,\n\nVoici le planning de vendredi.\n\nOuverture des portes : 23:00\nFermeture : 03:30\n\n"
              "Régie son — Clémence : 21:00 – 02:00 (Nico reprend le son après 02:00)\nRégie lumière — Nico : 21:00 – 03:45\n"
              "Porte — Raphaël : 22:00 – 04:00\nBar — Kader, Sofia : 22:00 – fermeture (Kader clôture la caisse)\n\n"
              "Line-up :\n23:00 – 00:00  Mila K.\n00:00 – 01:00  Dune Kollektiv\n01:00 – 03:30  Yanis (closing)\n\n"
              "Je partirai vers 01:30. Merci à tous, ce sera une grosse soirée.\n\nMathilde"),
    dict(id="mail_disquaire", folder="inbox", fromName="Disques de la Colline", fromAddress="bonjour@disquesdelacolline.fr", to=ME,
         at=s(15, "11:00"), subject="Votre réservation est arrivée",
         body="Bonjour, le disque que vous aviez réservé est arrivé. Il vous attend en boutique jusqu'à samedi."),
]

# ---------------------------------------------------------------- browser
browser = [
    dict(id="w01", at=s(8, "23:12"), kind="search", text="module filtre eurorack occasion lyon"),
    dict(id="w02", at=s(14, "16:05"), kind="search", text="heures supplementaires non payees que faire"),
    dict(id="w03", at=s(14, "16:08"), kind="visit", text="Heures supplémentaires non payées : vos recours",
         url="service-public.fr/particuliers/heures-sup",
         summary="Le salarié peut réclamer le paiement par écrit, puis saisir le conseil de prud'hommes dans un délai de 3 ans."),
    dict(id="w04", at=s(26, "02:08"), kind="search", text="premier metro samedi lyon horaire"),
    dict(id="w05", at=s(29, "23:40"), kind="search", text="comment dire a son ex qu'on part"),
    dict(id="w06", at=t(1, "12:40"), kind="search", text="la friche nord lyon"),
    dict(id="w07", at=t(1, "12:41"), kind="visit", text="La Friche Nord — salle de concerts, Vaise", url="lafrichenord.fr",
         summary="Ancienne usine textile reconvertie : 1 500 places, deux scènes, un studio de résidence. Ouverture de la saison en décembre."),
    dict(id="w08", at=t(5, "09:30"), kind="search", text="preavis demission cdi 3 ans anciennete"),
    dict(id="w09", at=t(9, "18:20"), kind="search", text="idées repas rapide avant service de nuit"),
    dict(id="w10", at=t(12, "23:40"), kind="search", text="inspection du travail signalement anonyme ?"),
    dict(id="w11", at=t(12, "23:44"), kind="visit", text="Signaler un danger sur son lieu de travail",
         url="travail-emploi.gouv.fr/signaler",
         summary="Tout salarié peut saisir l'inspection du travail par courrier ou par mail. L'inspecteur est tenu au secret sur l'origine du signalement."),
    dict(id="w12", at=t(13, "00:02"), kind="search", text="issue de secours encombree obligation erp"),
    dict(id="w13", at=t(14, "13:55"), kind="search", text="agression quais de saone samedi"),
    dict(id="w14", at=t(16, "18:03"), kind="search", text="meteo lyon nuit vendredi"),
    dict(id="w15", at=t(17, "04:31"), kind="search", text="premier métro terreaux samedi"),
    dict(id="w16", at=t(17, "04:32"), kind="visit", text="Horaires — Ligne D : premiers départs", url="tcl-horaires.fr/ligne-d",
         summary="Samedi : premier départ 04:55. Passage à Terreaux-Sud vers 05:04, direction Gare de Vaise."),
]

# ---------------------------------------------------------------- live events (the phone keeps living)
def live_msg(eid, after, conv_id, frm, text, title, at_hm, mid=None):
    mid = mid or ("m_" + eid)
    return dict(id=eid, afterSeconds=after, kind="message", app="messages", title=title, body=text,
                conversation=conv_id, message=dict(id=mid, **{"from": frm}, at=t(17, at_hm), text=text),
                opens=f"message:{mid}")
live = [
    live_msg("lv01", 25, "c_anais", "anais", "yanis dit qu'elle est jamais venue chez lui. clem t'es où ???", "Anaïs Aubry",
             "07:40", mid="m_live_anais_yanis"),
    dict(id="lv02", afterSeconds=80, kind="call", app="phone", title="Appel manqué", body="Papa",
         call=dict(id="k_lv_papa", contact="papa", direction="missed", at=t(17, "07:41"), durationSeconds=0), opens="call:k_lv_papa"),
    live_msg("lv03", 140, "c_mathilde", "mathilde", "Clémence, rappelle-moi dès que tu vois ça. Je me suis inquiétée toute la nuit.",
             "Mathilde Roche", "07:42", mid="m_live_mathilde"),
    dict(id="lv04", afterSeconds=200, kind="reminder", app="calendar", title="Lundi 10:00",
         body="Visite inspection — Silo · Le Silo, quai Rambaud", opens="calendar:c_inspection"),
    live_msg("lv05", 250, "c_yanis", "yanis", "c'est pas moi. j'ai fini à 3h30 demande à kader", "Yanis Ferhat", "07:44",
             mid="m_live_yanis"),
    live_msg("lv06", 310, "c_staff", "kader", "la police est au silo, ils demandent les vidéos du parking des docks",
             "Staff Silo 🔊 — Kader", "07:45", mid="m_live_staff_police"),
    live_msg("lv07", 370, "c_bastien", "bastien", "je suis désolé. j'aurais dû venir te chercher", "Bastien Kermarrec", "07:46",
             mid="m_live_bastien"),
    live_msg("lv08", 430, "c_anais", "anais", "la police me demande si t'avais des problèmes au boulot. je sais pas quoi leur dire",
             "Anaïs Aubry", "07:47", mid="m_live_anais_police"),
]
LEVELS = {"lv01": "urgent", "lv02": "normal", "lv03": "important", "lv04": "important", "lv06": "important"}
for e in live:
    e["level"] = LEVELS.get(e["id"], "normal")

device = dict(
    id="dev_clemence", label="Téléphone de Clémence", model="iPhone 14",
    lockedApps=[],
    contacts=contacts, conversations=convs, calls=calls, places=places, tracks=tracks, photos=photos,
    calendar=calendar, notes=notes, mails=mails, browser=browser, liveEvents=live,
    wallpaper="ice", batteryPercent=9,
)

# ---------------------------------------------------------------- suspects
suspects = [
    dict(id="s_mathilde", contact="mathilde", role="Gérante du Silo", age=41, address="Vaise (Lyon 9e)",
         statement="« Je suis partie du Silo vers 1h30 et je suis rentrée directement chez moi, à Vaise. Je n'ai pas revu Clémence. »",
         verdict="Mathilde Roche a menti. Elle a attendu Clémence au parking des Docks, l'a appelée à 02:19 et l'a fait monter dans sa voiture. "
                 "Après la dispute, elle a gardé le téléphone, a écrit à Anaïs à 03:07 depuis chez elle, quai Arloing, puis l'a déposé à la station Terreaux-Sud."),
    dict(id="s_yanis", contact="yanis", role="DJ résident du Silo, ex de Clémence", age=32, address="Villeurbanne — Gratte-Ciel",
         alibi="À 02:48, Yanis était aux platines du Silo (photo de Kader, horloge de la régie), et le planning le fait jouer jusqu'à 03:30. "
               "Le téléphone, lui, était déjà à Vaise.",
         alibiEvidence="e_yanis_alibi",
         trap="« Tu vas le regretter » et un message qui dit « je dors chez Yanis » : tout semblait l'accuser. Il parlait de son départ à La Friche Nord, "
              "et le message qui le nomme n'a pas été écrit par Clémence.",
         statement="« J'ai joué jusqu'à la fermeture, 3h30, puis je suis rentré à Villeurbanne en taxi. Elle n'est jamais venue chez moi. »",
         verdict="Yanis n'y est pour rien. Son « tu vas le regretter » parlait de La Friche Nord. À 02:48, il était aux platines, et le message "
                 "« je dors chez Yanis » part de Vaise, pas de Villeurbanne : quelqu'un a voulu le désigner."),
    dict(id="s_bastien", contact="bastien", role="Colocataire de Clémence", age=30, address="Montée de la Grande-Côte (Croix-Rousse)",
         alibi="Sa position partagée ne quitte pas l'appartement de la Croix-Rousse de 23:50 à 07:30.",
         alibiEvidence="e_bastien_alibi",
         trap="Il dit avoir dormi toute la nuit, mais il a décroché à 02:14 et refusé d'aller la chercher. Il a menti par honte, pas pour se couvrir.",
         statement="« Je dormais. Je n'ai rien entendu de la nuit. »",
         verdict="Bastien a menti par honte : il a décroché à 02:14 et a refusé de venir parce qu'il avait bu. Mais sa position ne quitte pas "
                 "la Croix-Rousse de la nuit."),
    dict(id="s_raphael", contact="raphael", role="Responsable sécurité du Silo", age=35, address="Oullins",
         alibi="À 03:04, il photographiait la file d'attente devant l'entrée du Silo — son reflet dans la vitre, l'heure sur l'enseigne. "
               "Le téléphone était alors à Vaise, à quatre kilomètres.",
         alibiEvidence="e_raphael_alibi",
         trap="Le dernier à l'avoir vue, et des semaines de messages insistants pour la raccompagner. Mais il n'a pas quitté la porte.",
         statement="« Je l'ai laissée devant le club à 2h12. Je suis resté à la porte jusqu'à la fermeture. »",
         verdict="Raphaël était trop insistant, mais il a dit vrai : il est resté à la porte du Silo. Sa photo de la file est prise à 03:04, "
                 "quand le téléphone de Clémence était déjà quai Arloing."),
]

# ---------------------------------------------------------------- evidence
evidence = [
    dict(id="e_fake_message", title="Le message de 03:07", importance="key", suspects=["s_mathilde"],
         refs=["message:m_anais_0307", "track:t_me"],
         meaning="À 03:07, le message « je dors chez Yanis » part du quai Arloing, à Vaise. Le téléphone n'a jamais été à Villeurbanne. "
                 "Et ce n'est pas la façon d'écrire de Clémence : majuscules, accents, points."),
    dict(id="e_address", title="L'adresse de Mathilde", importance="key", suspects=["s_mathilde"],
         refs=["calendar:c_apero_mathilde"],
         meaning="Mathilde habite 14 quai Arloing : le téléphone y a passé 1 h 38, de 02:58 à 04:36."),
    dict(id="e_call", title="L'appel de 02:19", importance="key", suspects=["s_mathilde"],
         refs=["call:k_mathilde_0219"],
         meaning="Mathilde, qui dit ne pas l'avoir revue, l'appelle à 02:19 pendant presque 2 minutes. Cinq minutes plus tard, "
                 "le téléphone est au parking des Docks."),
    dict(id="e_motive", title="Le signalement", importance="key", suspects=["s_mathilde"], anyOf=True,
         refs=["mail:mail_inspection_ack", "message:m_mathilde_2240"],
         meaning="Clémence a signalé le Silo à l'inspection du travail : visite lundi 19 à 10h, fermeture possible. "
                 "Le soir même où Mathilde l'apprend, elle écrit « Il faut qu'on parle ce soir. Pas au club. »"),
    dict(id="e_keyring", title="Le porte-clés rouge", importance="supporting", suspects=["s_mathilde"],
         refs=["photoInfo:p_pocket_0309", "photoInfo:p_apero_keys"],
         meaning="La photo prise par erreur à 03:09 montre le porte-clés en cuir rouge « M » de Mathilde, sur le même parquet clair que le soir de l'apéro."),
    dict(id="e_cut_call", title="L'appel coupé", importance="supporting", suspects=["s_mathilde"],
         refs=["call:k_anais_0246"],
         meaning="À 02:46, Clémence appelle sa sœur : 4 secondes, puis plus rien. Elle était dans la voiture de Mathilde."),
    dict(id="e_yanis_alibi", title="L'alibi de Yanis", importance="supporting", suspects=["s_yanis"], anyOf=True,
         refs=["photoInfo:p_booth_0248", "mail:mail_running_order"],
         meaning="À 02:48, Yanis est aux platines du Silo ; il joue jusqu'à 03:30."),
    dict(id="e_bastien_alibi", title="L'alibi de Bastien", importance="supporting", suspects=["s_bastien"],
         refs=["track:t_bastien"],
         meaning="Bastien n'a pas quitté l'appartement de la Croix-Rousse de 23:50 à 07:30."),
    dict(id="e_raphael_alibi", title="L'alibi de Raphaël", importance="supporting", suspects=["s_raphael"],
         refs=["photoInfo:p_door_0304"],
         meaning="À 03:04, Raphaël photographie la file devant le Silo : sa doudoune orange dans la vitre, l'heure sur l'enseigne."),
    dict(id="f_yanis_threat", title="« Tu vas le regretter »", importance="falseLead", suspects=["s_yanis"],
         refs=["message:m_yanis_0152"],
         meaning="Pas une menace : Yanis parle de son départ à La Friche Nord, comme le montrent les messages autour."),
    dict(id="f_bastien_lie", title="Le coloc qui « dormait »", importance="falseLead", suspects=["s_bastien"],
         refs=["call:k_bastien_0214"],
         meaning="Bastien a décroché 48 secondes à 02:14 et a refusé d'aller la chercher. Il a menti par honte."),
    dict(id="f_raphael_last", title="Le dernier à l'avoir vue", importance="falseLead", suspects=["s_raphael"],
         refs=["message:m_staff_0213"],
         meaning="Raphaël l'a laissée au coin du quai à 02:12, puis il est retourné à la porte. Ses messages insistants n'en font pas un coupable."),
    dict(id="f_named_yanis", title="« Vous vous êtes remis ensemble ? »", importance="falseLead", suspects=["s_yanis"],
         refs=["message:m_anais_0310"],
         meaning="Anaïs a cru le message de 03:07. C'est exactement ce que son auteur voulait : que tout le monde cherche chez Yanis."),
]

hints = [
    dict(id="h1", text="Un téléphone se souvient d'où il était. Comparez chaque message de la nuit avec l'endroit où il se trouvait.", scoreCost=0),
    dict(id="h2", text="Regardez l'historique de position « Moi » entre 2h et 5h, puis cherchez qui habite là.", scoreCost=8),
    dict(id="h3", text="Le message de 03:07 n'est pas écrit comme les autres, et il part de Vaise. Qui a appelé Clémence à 02:19 ?",
         scoreCost=15, unlockAtRemainingSeconds=120),
]

solution = dict(
    culprit="s_mathilde",
    headline="Mathilde Roche a gardé le téléphone de Clémence et a écrit à sa place.",
    summary="Elle disait être rentrée seule à Vaise. Le téléphone de Clémence y est rentré avec elle.",
    reveal=[
        dict(at=t(15, "16:05"), text="L'inspection du travail annonce une visite du Silo lundi à 10h et prévient l'exploitante", evidence="e_motive"),
        dict(at=t(16, "22:40"), text="« Il faut qu'on parle ce soir, après ton service. Pas au club. »", evidence="e_motive"),
        dict(at=t(17, "02:14"), text="Bastien décroche, mais refuse de venir la chercher", evidence="f_bastien_lie"),
        dict(at=t(17, "02:19"), text="Mathilde appelle : « je suis au parking des Docks ». À 02:24, le téléphone y est", evidence="e_call"),
        dict(at=t(17, "02:46"), text="Clémence tente d'appeler sa sœur : 4 secondes, coupé", evidence="e_cut_call"),
        dict(at=t(17, "02:58"), text="Le téléphone arrive quai Arloing, chez Mathilde, et y reste 1 h 38", evidence="e_address"),
        dict(at=t(17, "03:07"), text="« Ne t'inquiète pas, je dors chez Yanis. » — des majuscules, des points, et Vaise", evidence="e_fake_message"),
        dict(at=t(17, "03:09"), text="Une photo prise par erreur : le porte-clés rouge au grand M", evidence="e_keyring"),
        dict(at=t(17, "04:52"), text="Le téléphone est posé sur un banc de Terreaux-Sud, avant le premier métro", evidence="e_fake_message"),
    ],
    story=[
        "Mardi 13 octobre, Clémence signale le Silo à l'inspection du travail : l'issue de secours de la cour est bloquée par des fûts, "
        "et la jauge de 800 personnes est dépassée presque chaque week-end. Jeudi, l'inspection annonce une visite pour lundi 10h et prévient "
        "l'exploitante. Mathilde n'a pas besoin de nom : une seule personne avait photographié ces fûts dans le groupe du staff.",
        "Vendredi à 22:40, Mathilde écrit : « Il faut qu'on parle ce soir, après ton service. Pas au club. » À 01:31, elle annonce à tout le monde "
        "qu'elle rentre. En réalité, elle attend dans sa voiture, au parking des Docks, à deux cents mètres de la sortie.",
        "À 02:12, Clémence quitte le Silo. Il fait 4 degrés. Bastien, qui a bu, refuse de venir la chercher. À 02:19, Mathilde appelle et propose de "
        "la ramener. Dans la voiture, elle prend la direction de Vaise « pour parler cinq minutes » et exige que Clémence retire son signalement. "
        "À 02:46, Clémence essaie d'appeler sa sœur ; Mathilde lui ordonne de raccrocher.",
        "À 02:52, quai Arloing, Clémence claque la portière et part à pied le long de la Saône. Son téléphone est resté sur le socle de charge du tableau "
        "de bord, déverrouillé. Mathilde le monte chez elle. À 03:07, elle répond à Anaïs à la place de sa sœur — avec des majuscules, des accents, "
        "des points — et nomme Yanis. À 03:09, en le reposant, elle déclenche l'appareil photo : son propre porte-clés apparaît sur l'image.",
        "À 04:36, elle ressort, vérifie l'horaire du premier métro sur le téléphone de Clémence et le dépose à 04:52 sur un banc de la station Terreaux-Sud, "
        "pour faire croire que Clémence est partie seule. Un agent le trouve à 05:12, huit minutes après le passage du premier métro.",
        "Grâce à votre enquête, les recherches se concentrent sur les berges de Vaise. Clémence est retrouvée à 9h sous un pont, la cheville tordue, "
        "en hypothermie, mais vivante. Mathilde reconnaît avoir gardé le téléphone et envoyé le message.",
    ],
)

# ---------------------------------------------------------------- opening sequence
intro = {"shots": [
    {"kind": "scene", "seconds": 7, "scene": "metro", "camera": "push", "ambience": ["metro"],
     "cues": [{"sound": "chime", "at": 1.6}],
     "lines": [{"text": "STATION TERREAUX-SUD · SAMEDI 17 OCTOBRE · 05:03", "at": 0.3},
               {"text": "Le premier métro en direction de Gare de Vaise entre en station.", "at": 2.2, "speaker": "Annonce", "voiced": True}]},
    {"kind": "scene", "seconds": 5, "scene": "metro", "camera": "still", "effect": "trainArrival", "ambience": ["metro"],
     "cues": [{"sound": "train", "at": 0.2}]},
    {"kind": "phoneOnTable", "seconds": 6.5, "time": "2026-10-17 05:12", "surface": "bench", "label": "OBJET TROUVÉ — quai 2 — 05:12", "ambience": ["metro"],
     "cues": [{"sound": "vibrate", "at": 1.2}, {"sound": "notification", "at": 1.25}, {"sound": "ring", "at": 3.4}],
     "notifications": [{"app": "messages", "title": "Anaïs", "body": "clem ?? réponds stp", "at": 1.2},
                       {"app": "phone", "title": "Anaïs", "body": "Appel entrant", "at": 3.4, "call": True}],
     "lines": [{"text": "Personne ne le réclame.", "at": 5.0}]},
    {"kind": "title", "seconds": 1.4, "cues": [{"sound": "vibrate", "at": 0.5}]},
    {"kind": "unlock", "seconds": 2.4},
]}

case = dict(
    dossier=dict(rating=2, category="DISPARITION INQUIÉTANTE", city="Lyon", place="Confluence — Le Silo", subject="Clémence Aubry", subjectLabel="PERSONNE DISPARUE", subjectAge=29, subjectContact="me", lastContact="2026-10-17 02:17"),
    schemaVersion=1, id="case_002", number=2, title="PREMIER MÉTRO",
    tagline="Son téléphone a pris le premier métro. Pas elle.",
    synopsis=[
        "Vendredi 16 octobre, Clémence Aubry, 29 ans, régisseuse son au Silo, un club de la Confluence, termine son service vers 2h du matin. "
        "Elle n'est jamais rentrée chez elle.",
        "À 5h12, un agent trouve son téléphone sur un banc de la station Terreaux-Sud, quai 2, huit minutes après le passage du premier métro. "
        "Dans la nuit, sa sœur a pourtant reçu un message rassurant.",
        "Vous avez quelques minutes pour comprendre qui avait ce téléphone entre les mains.",
    ],
    objective="Découvrir qui avait le téléphone de Clémence après 2h30.",
    difficulty=1, durationSeconds=480, phoneStartTime=t(17, "07:40"),
    challengeDurations={"investigator": 900, "detective": 480, "expert": 300},
    introScene=intro,
    devices=[device], suspects=suspects, evidence=evidence, hints=hints, solution=solution,
)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(case, f, ensure_ascii=False, indent=1)
n_msgs = sum(len(c["messages"]) for c in convs)
print(f"case_002: {len(contacts)} contacts, {len(convs)} conversations, {n_msgs} messages, {len(calls)} calls, "
      f"{len(photos)} photos, {len(calendar)} events, {len(notes)} notes, {len(mails)} mails, {len(browser)} web, "
      f"{len(live)} live events, {len(places)} places, {len(tracks)} tracks")
