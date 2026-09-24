# Generates ScreenshotKit/Sources/CaseLibrary/Resources/Cases/case_005.json
# Case #005 — ROUTE DE NUIT. Friday 27 Nov 2026 night, Vercors; investigation Saturday 28 Nov 00:50.
# Core mechanic: a spoofed "new number" of the source. The player compares phone numbers across
# Contacts, Messages and an old mail signature, checks where the real source was (Messages, Photos,
# Phone) and identifies the car photographed at the pass (Photos, cross-checked with an older photo).
import json, sys

OUT = sys.argv[1]
Y = 2026


def t(day, hm, month=11, year=Y):
    return f"{year}-{month:02d}-{day:02d} {hm}"


def at(year, month, day, hm):
    return f"{year}-{month:02d}-{day:02d} {hm}"


PHONE_START = t(28, "00:50")

# ---------------------------------------------------------------- contacts
contacts = [
    dict(id="me", name="Solène Marchetti", phone="+33 6 12 84 37 65", relation="Moi",
         email="solene.marchetti@echodesalpes.fr", birthday="14/03/1992", avatarHue=0.56, isOwner=True),
    dict(id="gilles", name="Gilles Arnaud", phone="+33 4 76 95 20 10", relation="Mairie de Vallières — adjoint urbanisme",
         email="g.arnaud@vallieres-en-vercors.fr", avatarHue=0.33),
    dict(id="thierry", name="Thierry Brassac", phone="+33 6 08 44 17 52", relation="Brassac Granulats (PDG)",
         email="t.brassac@brassac-granulats.fr", avatarHue=0.07),
    dict(id="romain", name="Romain Vidal", phone="+33 6 63 20 88 41", relation="Papa de Léo et Nina", avatarHue=0.62),
    dict(id="agathe", name="Agathe Lemoine", phone="+33 6 70 52 19 03", relation="L'Écho — directrice de la rédaction",
         email="a.lemoine@echodesalpes.fr", avatarHue=0.95),
    dict(id="julien", name="Julien Faure", phone="+33 6 71 30 45 18", relation="Carrière", avatarHue=0.16),
    dict(id="jnew", name="Julien (nouveau n°)", phone="+33 7 58 11 20 94", relation="Ajouté le 25/11", avatarHue=0.16),
    dict(id="maman", name="Maman", phone="+33 6 81 27 64 09", relation="Mère", avatarHue=0.02),
    dict(id="beatrice", name="Béatrice Roux", phone="+33 6 29 71 05 86", relation="L'Écho — photo",
         email="b.roux@echodesalpes.fr", avatarHue=0.47),
    dict(id="olivier", name="Olivier Brun", phone="+33 6 34 90 12 77", relation="L'Écho — sports", avatarHue=0.72),
    dict(id="lina", name="Lina Perret", phone="+33 7 62 18 45 30", relation="L'Écho — locale", avatarHue=0.84),
    dict(id="aubert", name="Maître Aubert", phone="+33 4 76 43 18 22", relation="Avocate (divorce)",
         email="cabinet.aubert@avocats-isere.fr", avatarHue=0.26),
    dict(id="fatou", name="Fatou Diallo", phone="+33 6 45 38 90 12", relation="Nounou", avatarHue=0.10),
    dict(id="viallet", name="Marc Viallet", phone="+33 4 76 88 10 45", relation="L'Écho — service juridique",
         email="m.viallet@echodesalpes.fr", avatarHue=0.40),
    dict(id="garage", name="Garage du Plateau", phone="+33 4 76 95 33 07", avatarHue=0.52),
    dict(id="ecole", name="École de Lans", phone="+33 4 76 95 40 61", avatarHue=0.20),
    dict(id="chabert", name="Dr Chabert — pédiatre", phone="+33 4 76 95 11 28", avatarHue=0.66),
]

# ---------------------------------------------------------------- messages
convs = []


def conv(cid, participants, msgs, title=None, draft=None):
    c = dict(id=cid, participants=participants, messages=[])
    if title:
        c["title"] = title
    for i, m in enumerate(msgs):
        frm, when, text = m[0], m[1], m[2]
        extra = dict(m[3]) if len(m) > 3 else {}
        mid = extra.pop("id", f"m_{cid[2:]}_{i:03d}")
        msg = dict(id=mid, **{"from": frm}, at=when)
        if text:
            msg["text"] = text
        msg.update(extra)
        c["messages"].append(msg)
    c["messages"].sort(key=lambda x: x["at"])
    if draft:
        c["draft"] = draft
    convs.append(c)


UNREAD = {"unread": True}

# --- The real Julien (the source): lowercase, no accents, few apostrophes.
conv("c_julien", ["julien"], [
    ("julien", t(8, "20:14", 10), "bonsoir c est julien faure, on s est vu a la reunion publique sur la carriere. vous m avez laissé votre carte"),
    ("me", t(8, "20:31", 10), "Bonsoir Julien. Oui, je me souviens. Je vous écoute."),
    ("julien", t(8, "20:33", 10), "pas par msg. on peut se voir ? pas a villard, tout le monde se connait"),
    ("me", t(8, "20:40", 10), "Autrans, parking du foyer de fond, jeudi prochain 18h ?"),
    ("julien", t(8, "20:41", 10), "ok"),
    ("julien", t(15, "17:58", 10), "jsuis la, berlingo blanc au fond"),
    ("julien", t(22, "21:10", 10), "on peut se tutoyer hein 😅 merci pour l autre soir"),
    ("me", t(22, "21:25", 10), "Ok 🙂 Merci à toi. Prends ton temps pour la suite."),
    ("julien", t(5, "22:40"), "j ai acces au bureau compta demain, je tente un truc"),
    ("me", t(5, "22:44"), "Prends aucun risque. Vraiment."),
    ("julien", t(5, "22:45"), "tkt"),
    ("julien", t(6, "19:52"), "regarde le 12/09", dict(id="m_julien_doc", photo="p_doc_virements")),
    ("julien", t(6, "19:53"), "G.A. c est qui a ton avis 😶"),
    ("me", t(6, "20:10"), "J'ai une idée. On en parle pas ici."),
    ("julien", t(12, "18:30"), "y a un gars du bureau qui m a demandé pourquoi j etais passé vendredi. jcrois que c est rien"),
    ("me", t(12, "18:41"), "Tu me dis si ça bouge. Et tu effaces rien, on sait jamais."),
    ("julien", t(20, "19:05"), "fred est ok pour parler, il a vu les virements aussi. vendredi 27 au soir ca te va ? 22h ? jte dis ou, faut un coin ou personne nous voit"),
    ("me", t(20, "19:20"), "Parfait. Merci Julien."),
    ("julien", t(27, "18:02"), "me suis pété la cheville au taf, je suis aux urgences a grenoble. ce soir c est mort je pense",
     dict(id="m_julien_1802")),
    ("me", t(27, "18:04"), "Oh non. Soigne-toi, on se reparle."),
    ("julien", t(27, "18:40"), "le bijou 😩", dict(id="m_julien_platre", photo="p_platre")),
    ("julien", t(27, "21:03"), "toujours aux urgences, ils me gardent pour la nuit. on reporte ok ? désolé",
     dict(id="m_julien_2103")),
])

# --- The spoofed "new number" (Gilles Arnaud's old prepaid line): full punctuation, capitals, no tics.
conv("c_jnew", ["jnew"], [
    ("jnew", t(25, "21:12"), "C'est Julien. Nouveau numéro, l'autre est surveillé par Brassac. Efface l'ancien et écris-moi ici.",
     dict(id="m_new_2112")),
    ("me", t(25, "21:15"), "Ah. Ok. Il s'est passé quoi ?"),
    ("jnew", t(25, "21:19"), "Pas par écrit. Je t'expliquerai."),
    ("me", t(25, "21:20"), "Ok. Vendredi ça tient ? Tu viens avec Fred ?"),
    ("jnew", t(25, "21:26"), "Oui. Rappelle-moi l'heure, j'ai perdu mes notes avec l'ancien téléphone."),
    ("me", t(25, "21:27"), "22h. Tu devais me dire où."),
    ("jnew", t(25, "21:34"), "23h plutôt. Parking du col de la Croix-Perrin. Personne n'y passe en hiver."),
    ("me", t(25, "21:35"), "Le col ? Il ferme pas la nuit avec la neige ?"),
    ("jnew", t(25, "21:40"), "Il est ouvert. Je connais la route."),
    ("me", t(25, "21:41"), "Ok. Et Fred ?"),
    ("jnew", t(25, "21:49"), "Il sera là. Apporte tous les documents, il veut voir ce que tu as avant de parler."),
    ("me", t(26, "08:12"), "Tu peux m'appeler ce midi ?"),
    ("jnew", t(26, "08:40"), "Pas possible au travail. Plutôt par écrit."),
    ("jnew", t(26, "22:03"), "Tu en as parlé à qui ?"),
    ("me", t(26, "22:10"), "À ma directrice. C'est tout. Pourquoi ?"),
    ("jnew", t(26, "22:12"), "Pour rien. Moins on est, mieux c'est."),
    ("me", t(27, "18:08"), "Je viens de voir ton msg sur l'ancien numéro. Ta cheville ?! Fais gaffe à ce que tu écris dessus."),
    ("jnew", t(27, "18:30"), "Je sais. Réflexe. On verra pour ce soir."),
    ("me", t(27, "19:20"), "Tu m'as appelée sur l'ancien, j'ai fait court. Repose-toi, on décale."),
    ("jnew", t(27, "19:41"), "D'accord."),
    ("jnew", t(27, "21:40"), "Finalement je peux. 23h au parking du col de la Croix-Perrin, comme prévu. Viens seule, avec les documents.",
     dict(id="m_new_2140")),
    ("me", t(27, "21:44"), "t'es pas aux urgences ?? tu m'as écrit y a 40 min qu'ils te gardaient"),
    ("jnew", t(27, "21:46"), "Sorti. Plâtre. Un pote me conduit."),
    ("me", t(27, "21:47"), "Et Fred ?"),
    ("jnew", t(27, "21:52"), "Il vient."),
    ("me", t(27, "22:29"), "Je pars dans 10 min."),
    ("me", t(27, "23:09"), "Suis là. Personne. Brouillard à couper au couteau."),
    ("jnew", t(27, "23:12"), "J'arrive. 2 minutes."),
    ("jnew", t(27, "23:47"), "Je suis au parking du col, t'es où ?", dict(id="m_new_2347", unread=True)),
])

# --- Romain (ex-husband): dry, full sentences, no emoji.
conv("c_romain", ["romain"], [
    ("romain", t(16, "19:02", 10), "Demain 8h30 comme d'habitude. Le carnet de santé de Nina est dans son sac."),
    ("me", t(16, "19:30", 10), "Ok"),
    ("romain", t(21, "12:14", 10), "La maîtresse de Léo m'a appelé. Il s'est battu dans la cour. Rien de grave."),
    ("me", t(21, "12:40", 10), "Il m'en a parlé hier. Je lui ai expliqué."),
    ("romain", t(29, "20:40", 10), "Tu peux prendre les enfants le 11 novembre ? J'ai un séminaire."),
    ("me", t(29, "20:52", 10), "Oui. Tu me les déposes la veille ?"),
    ("romain", t(29, "20:53", 10), "Mardi soir 19h."),
    ("romain", t(7, "10:05"), "Léo veut fêter son anniversaire au laser game. Je lui ai dit que c'était non. On est d'accord ?"),
    ("me", t(7, "10:30"), "On est d'accord. Goûter à la maison, 6 copains max."),
    ("romain", t(10, "19:04"), "Devant chez toi. Nina dort dans la voiture."),
    ("romain", t(18, "21:02"), "J'ai vu ton nom sous l'article sur la carrière. Tu fais attention ?"),
    ("me", t(18, "21:30"), "Toujours."),
    ("romain", t(21, "08:10"), "J'arrive dans 20 minutes."),
    ("romain", t(21, "19:40"), "Léo a perdu sa dent. La petite souris passe par Grenoble ce soir.", dict(photo="p_r_dent")),
    ("me", t(21, "19:52"), "😍 dis-lui que je suis fière de lui"),
    ("romain", t(26, "20:31"), "Je le redis par écrit : si tu publies avec ton vrai nom, je demande la garde complète. "
                               "Je ne veux pas que les types de la carrière sachent où dorment mes enfants.",
     dict(id="m_romain_threat")),
    ("me", t(26, "20:40"), "Tu n'as pas le droit de me faire ça."),
    ("romain", t(26, "20:41"), "J'en ai parlé à mon avocat."),
    ("me", t(26, "20:52"), "On en parle mardi devant le juge. Pas ce soir."),
    ("me", t(27, "22:35"), "Je suis dehors pour le boulot ce soir. Si souci avec les enfants, appelle, pas de message."),
    ("romain", t(27, "22:41"), "Dehors où ? À cette heure-ci ?"),
    ("romain", t(27, "23:05"), "Ils dorment enfin.", dict(id="m_romain_2305", photo="p_kids_2305")),
    ("romain", t(27, "23:48"), "Tu rentres quand ? Léo a de la fièvre", dict(id="m_romain_2348", unread=True)),
    ("romain", t(27, "23:49"), "38,4. Le sirop du Dr Chabert est chez toi je crois. Rappelle-moi.", UNREAD),
])

# --- Agathe (editor in chief): brisk, capitals, the odd emoji.
conv("c_agathe", ["agathe"], [
    ("agathe", t(20, "08:50", 10), "Conf avancée à 9h, je t'attends pour la carrière."),
    ("me", t(20, "08:52", 10), "J'arrive, bouchons à Sassenage."),
    ("agathe", t(30, "18:22", 10), "Ton papier sur les pistes de fond : parfait. On le passe samedi."),
    ("me", t(30, "18:40", 10), "Merci !"),
    ("agathe", t(9, "07:45"), "Tu peux couvrir la foire aux skis d'Autrans samedi ? Olivier est en congé."),
    ("me", t(9, "08:02"), "J'ai les enfants ce week-end-là... je les emmène, ça leur fera plaisir."),
    ("agathe", t(19, "17:05"), "Le juridique veut voir tes documents lundi. Tout."),
    ("me", t(19, "17:10"), "Ok. Je les apporte en main propre, pas par mail."),
    ("agathe", t(24, "21:30"), "Brassac a appelé le directeur général. Ça remonte vite."),
    ("me", t(24, "21:41"), "Tant mieux. Ça veut dire qu'on tape juste."),
    ("agathe", t(27, "17:20"), "Je sais que tu m'en veux. Trouve-moi ta deuxième source et on passe la semaine prochaine. Promis."),
    ("me", t(27, "17:31"), "J'ai peut-être mieux que ça. Je te dis ce soir."),
    ("agathe", t(27, "22:58"), "Brassac est en direct sur TéléAlpes, il nous allume 😤", dict(id="m_agathe_2258")),
    ("agathe", t(27, "23:02"), "Bouclé. Une sur la neige, évidemment.", dict(id="m_agathe_bat", photo="p_bat_2301")),
    ("me", t(27, "23:10"), "Arrivée. Il est pas là. Je te rappelle après."),
    ("agathe", t(27, "23:40"), "Alors ??", UNREAD),
    ("agathe", t(28, "00:15"), "Solène, rappelle-moi. Même tard.", UNREAD),
])

# --- Newsroom group.
R = ["agathe", "beatrice", "olivier", "lina"]
conv("c_redac", R, [
    ("olivier", t(19, "09:02", 10), "Qui a piqué mon chargeur en salle de conf ?"),
    ("lina", t(19, "09:05", 10), "pas moi 🙄"),
    ("beatrice", t(19, "09:10", 10), "regarde sous le radiateur, c'est toujours là"),
    ("lina", t(26, "14:20", 10), "Pot vendredi pour mon anniv, 18h en salle de conf. Apportez rien, juste vous"),
    ("beatrice", t(26, "14:26", 10), "je ramène un gâteau quand même"),
    ("me", t(26, "14:40", 10), "J'y serai 🎉"),
    ("agathe", t(3, "08:10"), "Rappel : notes de frais avant le 5. Après je signe plus rien."),
    ("olivier", t(3, "08:12"), "Oui patronne"),
    ("beatrice", t(10, "11:32"), "le parking de la rédac est plein, quelqu'un a un badge pour le P2 ?"),
    ("me", t(10, "11:40"), "Pas de badge, mais la rue d'en face est gratuite entre 12h et 14h"),
    ("lina", t(13, "16:00"), "Qui me relit un papier de 3000 signes ? 🙏"),
    ("me", t(13, "16:05"), "Envoie"),
    ("olivier", t(17, "22:45"), "Victoire du GF38 ce soir, je prends deux pages demain, désolé pas désolé"),
    ("agathe", t(24, "10:15"), "Conf de vendredi : chacun arrive avec 2 sujets. Pas 1. Deux."),
    ("beatrice", t(24, "10:20"), "👍"),
    ("lina", t(27, "12:40"), "quelqu'un descend chercher des sandwichs ?"),
    ("olivier", t(27, "12:42"), "Moi. Jambon-beurre pour tout le monde ?"),
    ("olivier", t(27, "19:58"), "Béa tu nous fais un point sur le conseil de Vallières pour demain ?"),
    ("beatrice", t(27, "20:03"), "j'y suis. ça commence en retard"),
    ("beatrice", t(27, "21:14"), "le conseil de vallières a été levé à 21h10, arnaud est parti le premier, bizarre",
     dict(id="m_redac_2114")),
    ("lina", t(27, "21:16"), "donc on a rien pour demain ?"),
    ("beatrice", t(27, "21:18"), "j'ai des photos de chaises vides 😅"),
    ("agathe", t(27, "21:22"), "Une brève suffira. Merci Béa."),
    ("olivier", t(27, "23:26"), "Brassac vient de dire à l'antenne que l'Écho « harcèle les entreprises du plateau ». Sympa.", UNREAD),
    ("lina", t(27, "23:28"), "c'est pas de la pub gratuite ça ? 😂", UNREAD),
], title="Rédac Écho 📰")

# --- Mother: long, affectionate messages.
conv("c_maman", ["maman"], [
    ("maman", t(18, "11:02", 10), "Ma chérie, tu as bien reçu le colis pour les enfants ? Les gants sont un peu grands, ils grandiront."),
    ("me", t(18, "11:30", 10), "Oui merci maman ! Nina ne veut plus les enlever"),
    ("maman", t(25, "18:30", 10), "Tu travailles trop. Ton frère aussi d'ailleurs. Vous tenez ça de votre père."),
    ("maman", t(3, "09:15"), "Je viens de réserver le gîte de Méaudre pour le week-end du 14 mars ! Tes 35 ans on les fête en famille, pas de discussion 😘"),
    ("me", t(3, "09:40"), "Maman c'est dans 4 mois 😂 mais oui, merci"),
    ("maman", t(8, "16:20"), "Le chat a encore dormi dans le panier à linge.", dict(photo="p_r_chat")),
    ("maman", t(11, "12:40"), "Bon 11 novembre ! Vous faites quoi avec les petits ?"),
    ("me", t(11, "12:55"), "Luge si la neige tient. Sinon crêpes et dessin animé."),
    ("maman", t(22, "17:10"), "Ils ont parlé de ta carrière à la radio ce matin."),
    ("me", t(22, "17:25"), "C'est pas ma carrière maman 😅"),
    ("maman", t(27, "20:35"), "Couvre-toi si tu ressors ce soir. La radio annonce du brouillard sur le plateau."),
    ("me", t(27, "20:40"), "Promis. Bisous"),
])

# --- Béatrice (photographer colleague, friend): lowercase, relaxed.
conv("c_beatrice", ["beatrice"], [
    ("beatrice", t(23, "22:40", 10), "tu me passes tes photos du conseil ? j'ai raté le début"),
    ("me", t(23, "22:52", 10), "Je t'envoie ça demain"),
    ("beatrice", t(4, "19:02"), "on va courir samedi ?"),
    ("me", t(4, "19:20"), "Ok pour 10h, après l'échange des enfants"),
    ("beatrice", t(16, "13:30"), "tu as l'air crevée en ce moment. ça va vraiment ?"),
    ("me", t(16, "13:48"), "Grosse histoire. Je te raconte quand je pourrai."),
    ("me", t(27, "20:05"), "Tu me dis si Arnaud parle de la carrière ?"),
    ("beatrice", t(27, "20:07"), "promis. salle pleine, ça sent la bagarre"),
    ("beatrice", t(27, "21:20"), "tu viens pas finalement ?"),
    ("me", t(27, "21:31"), "Non. J'ai plus important ce soir."),
    ("beatrice", t(27, "23:58"), "tu dors ? agathe dit que tu réponds plus", UNREAD),
])

# --- Nanny.
conv("c_fatou", ["fatou"], [
    ("fatou", t(20, "16:40", 10), "Bonjour Solène, Nina a un peu toussé aujourd'hui mais elle a fait une grosse sieste 😊"),
    ("me", t(20, "17:02", 10), "Merci Fatou"),
    ("fatou", t(16, "17:02"), "Léo a oublié son bonnet chez moi, je le mets dans son sac demain"),
    ("me", t(16, "17:10"), "Merci !!"),
    ("me", t(18, "12:05"), "Fatou, vous pouvez garder Léo jusqu'à 18h30 ce soir ? J'emmène Nina chez le pédiatre."),
    ("fatou", t(18, "12:20"), "Pas de souci 👍"),
    ("me", t(20, "18:40"), "Je vous fais le virement de novembre ce week-end."),
    ("fatou", t(20, "18:52"), "Merci Solène, bon week-end à vous"),
    ("fatou", t(26, "19:10"), "Pour la semaine prochaine, lundi je finis à 17h exceptionnellement"),
    ("me", t(26, "19:31"), "Ok je m'organise"),
])

conv("c_garage", ["garage"], [
    ("garage", t(2, "10:05"), "Garage du Plateau : votre rendez-vous montage pneus neige est confirmé le mardi 10/11 à 8h30."),
    ("garage", t(10, "11:45"), "Garage du Plateau : votre véhicule est prêt. Montant : 312,00 €."),
])

conv("c_ecole", ["ecole"], [
    ("ecole", t(9, "08:00"), "École de Lans : grève jeudi 12/11, pas de cantine. Merci de récupérer vos enfants à 11h30 ou de prévoir un pique-nique."),
    ("ecole", t(24, "16:30"), "École de Lans : sortie raquettes le vendredi 4/12. Autorisation à rendre avant lundi."),
])

conv("c_aubert", ["aubert"], [
    ("aubert", t(12, "08:30"), "Cabinet Aubert : rendez-vous confirmé aujourd'hui à 14h."),
    ("me", t(26, "21:05"), "Maître, mon ex menace de demander la garde complète si je publie sous mon nom. Il peut ?"),
    ("aubert", t(27, "09:12"), "Bonjour Madame Marchetti. Menacer n'est pas obtenir. Gardez tous ses messages, on en parle mardi avant l'audience."),
])

# ---------------------------------------------------------------- calls
calls = []


def call(cid, contact, direction, when, dur):
    calls.append(dict(id=cid, contact=contact, direction=direction, at=when, durationSeconds=dur))


call("k01", "maman", "incoming", t(20, "19:10", 10), 1520)
call("k02", "romain", "outgoing", t(22, "20:05", 10), 240)
call("k03", "julien", "incoming", t(28, "21:02", 10), 780)
call("k04", "garage", "outgoing", t(2, "09:58"), 95)
call("k05", "agathe", "incoming", t(4, "18:10"), 410)
call("k06", "julien", "outgoing", t(6, "20:14"), 610)
call("k07", "ecole", "incoming", t(9, "10:20"), 180)
call("k08", "aubert", "outgoing", t(13, "11:40"), 540)
call("k09", "maman", "outgoing", t(15, "18:00"), 2100)
call("k10", "romain", "missed", t(18, "20:58"), 0)
call("k11", "gilles", "outgoing", t(19, "10:40"), 48)
call("k12", "julien", "incoming", t(20, "18:55"), 342)
call("k13", "fatou", "incoming", t(23, "17:40"), 130)
call("k14", "chabert", "outgoing", t(24, "08:35"), 75)
call("k15", "thierry", "outgoing", t(26, "16:05"), 0)
call("k16", "romain", "incoming", t(26, "20:15"), 420)
call("k17", "thierry", "incoming", t(27, "11:20"), 185)
call("k18", "agathe", "outgoing", t(27, "16:45"), 612)
call("k19", "viallet", "incoming", t(27, "17:05"), 300)
call("k_julien_1912", "julien", "incoming", t(27, "19:12"), 252)
call("k20", "maman", "incoming", t(27, "20:10"), 460)
call("k_agathe_2231", "agathe", "outgoing", t(27, "22:31"), 840)
call("k_new_2252", "jnew", "incoming", t(27, "22:52"), 70)
call("k_new_2346", "jnew", "missed", t(27, "23:46"), 0)
call("k_agathe_2348", "agathe", "missed", t(27, "23:48"), 0)
call("k21", "romain", "missed", t(27, "23:52"), 0)
call("k22", "maman", "missed", t(28, "00:44"), 0)

# ---------------------------------------------------------------- places & tracks
# (id, name, kind, latitude, longitude, revealedBy)
PLACES = [
    ("pl_home", "Domicile — Villard-de-Lans", "home", 45.0710, 5.5530, None),
    ("pl_col", "Col de la Croix-Perrin — parking", "parking", 45.1135, 5.5570,
     ["message:m_new_2140", "calendar:c_rdv_col"]),
    ("pl_d106", "Route du col (D106)", "road", 45.1050, 5.5710, None),
    ("pl_carriere", "Carrière Brassac Granulats", "industrial", 45.0900, 5.6050, None),
    ("pl_mairie", "Mairie de Vallières-en-Vercors", "work", 45.0950, 5.6000,
     ["photoInfo:p_mairie_4x4", "mail:mail_arnaud_2024"]),
    ("pl_echo", "L'Écho des Alpes — rédaction, Grenoble", "work", 45.1880, 5.7240, None),
    ("pl_romain", "Chez Romain — Île Verte, Grenoble", "home", 45.1935, 5.7390, None),
    ("pl_chu", "Urgences du CHU de Grenoble", "district", 45.2000, 5.7470, ["message:m_julien_1802"]),
    ("pl_imprimerie", "Imprimerie du Drac — Échirolles", "industrial", 45.1450, 5.7130, ["photoInfo:p_bat_2301"]),
    ("pl_telealpes", "Studio TéléAlpes — Grenoble", "work", 45.1900, 5.7150, ["browser:w_debat"]),
    ("pl_ecole", "École de Lans-en-Vercors", "district", 45.1280, 5.5890, None),
    ("pl_autrans", "Autrans — foyer de ski de fond", "park", 45.1750, 5.5440, None),
    ("pl_boisbarbu", "Bois Barbu — pistes de fond", "park", 45.0640, 5.5270, None),
]
LAT0, LAT1, LON0, LON1 = 45.04, 45.22, 5.50, 5.77
places = []
for pid, name, kind, lat, lon, revealed in PLACES:
    pl = dict(id=pid, name=name, kind=kind,
              x=round((lon - LON0) / (LON1 - LON0), 3), y=round(1 - (lat - LAT0) / (LAT1 - LAT0), 3),
              latitude=lat, longitude=lon)
    if revealed:
        pl["revealedBy"] = revealed
    places.append(pl)

tracks = [
    dict(id="t_me", contact="me", points=[
        dict(id="tp_me_1", at=t(23, "08:40"), place="pl_echo"),
        dict(id="tp_me_2", at=t(23, "18:50"), place="pl_home"),
        dict(id="tp_me_3", at=t(24, "10:30"), place="pl_carriere"),
        dict(id="tp_me_4", at=t(24, "12:10"), place="pl_home"),
        dict(id="tp_me_5", at=t(25, "09:05"), place="pl_echo"),
        dict(id="tp_me_6", at=t(25, "19:30"), place="pl_home"),
        dict(id="tp_me_7", at=t(26, "13:00"), place="pl_boisbarbu"),
        dict(id="tp_me_8", at=t(26, "15:10"), place="pl_home"),
        dict(id="tp_me_9", at=t(27, "09:10"), place="pl_echo"),
        dict(id="tp_me_10", at=t(27, "17:45"), place="pl_home"),
        dict(id="tp_me_11", at=t(27, "22:40"), place="pl_home", note="Départ"),
        dict(id="tp_me_12", at=t(27, "22:55"), place="pl_d106"),
        dict(id="tp_me_13", at=t(27, "23:08"), place="pl_col"),
        dict(id="tp_me_14", at=t(27, "23:48"), place="pl_col", note="Dernière position : moteur allumé"),
    ]),
    # Romain shares his position with Solène during his custody weeks.
    dict(id="t_romain", contact="romain", points=[
        dict(id="tp_ro_1", at=t(27, "16:20"), place="pl_ecole", note="Sortie d'école"),
        dict(id="tp_ro_2", at=t(27, "18:30"), place="pl_romain"),
        dict(id="tp_ro_3", at=t(27, "21:00"), place="pl_romain"),
        dict(id="tp_ro_4", at=t(27, "23:05"), place="pl_romain"),
        dict(id="tp_ro_5", at=t(28, "00:00"), place="pl_romain"),
    ]),
]

# ---------------------------------------------------------------- photos
photos = []
OWN = "iPhone 12"


def photo(pid, taken, scene, caption, details, source="camera", place=None, frm=None, received=None, device=OWN,
          style=None, lines=None):
    p = dict(id=pid, takenAt=taken, source=source, scene=scene, caption=caption, details=details)
    if style:
        p["style"] = style
    if lines:
        p["lines"] = lines
    if place:
        p["place"] = place
    if frm:
        p["from"] = frm
    if received:
        p["receivedAt"] = received
    if device:
        p["device"] = device
    photos.append(p)


# Ordinary camera roll (id, taken, scene, caption, details, place, style, lines)
roll = [
    ("p_old01", at(2019, 2, 17, "11:20"), "snow", "Villard sous la neige, février 2019.",
     "Un toit blanc, des skis plantés dans la neige.", "Villard-de-Lans", "old", None),
    ("p_old02", at(2020, 7, 12, "16:45"), "garden_stairs", "Léo, deux ans, dans l'escalier du jardin.",
     "Une petite silhouette floue qui monte les marches. Été 2020.", "Villard-de-Lans", "old", None),
    ("p_old03", at(2022, 3, 14, "20:30"), "party", "Mes 30 ans — 14 mars 2022.",
     "Des bougies en forme de 3 et de 0, des silhouettes autour d'une table.", "Villard-de-Lans", "old", None),
    ("p_old04", at(2023, 6, 3, "10:15"), "park", "Nina fait ses premiers pas au parc.",
     "Un parc au printemps, une poussette vide au premier plan.", "Grenoble", "old", None),
    ("p_old05", at(2024, 12, 24, "19:40"), "interior_warm", "Réveillon chez Maman.",
     "Une table dressée, un sapin clignotant dans le coin.", None, "old", None),
    ("p_old06", at(2025, 6, 27, "18:30"), "office", "Pot de départ de l'ancien secrétaire de rédaction.",
     "Des gobelets, une banderole « Bonne retraite Jacques ».", "L'Écho des Alpes", "old", None),
    ("p_n01", t(17, "15:10", 10), "mountain", "Le Moucherotte dans les nuages.",
     "Une crête sombre, la lumière perce sur la droite.", "Villard-de-Lans", None, None),
    ("p_n02", t(18, "14:25", 10), "forest", "Balade en forêt avec les enfants.",
     "Deux petites silhouettes en bottes, des feuilles rousses.", "Bois Barbu", None, None),
    ("p_n03", t(23, "20:02", 10), "office", "La salle du conseil municipal de Vallières, avant l'ouverture.",
     "Une vingtaine de chaises, une table en U, un micro qui ne marche pas.", "Mairie de Vallières-en-Vercors", None, None),
    ("p_n04", t(27, "11:05", 10), "mountain", "La carrière vue depuis la route.",
     "Une saignée grise dans la forêt, deux camions-bennes. Trop loin pour lire quoi que ce soit.", None, "quick", None),
    ("p_n05", t(31, "18:20", 10), "party", "Halloween : un squelette et une citrouille.",
     "Léo et Nina de dos, déguisés, devant la porte des voisins.", "Villard-de-Lans", None, None),
    ("p_n06", t(3, "07:40"), "screenshot", "Capture : météo de la semaine.", "Pluie, puis premiers flocons jeudi.",
     None, "screenshot", ["Météo — Villard-de-Lans", "Mar  🌧  6°", "Mer  🌧  4°", "Jeu  🌨  1°", "Ven  ☁  3°", "Sam  ☀  5°"]),
    ("p_n07", t(5, "09:35"), "office", "Conférence de rédaction.",
     "Un tableau blanc couvert de sujets, des gobelets de café.", "L'Écho des Alpes", None, None),
    ("p_n08", t(8, "18:05"), "interior_warm", "Les dessins de Nina sur le frigo.",
     "Un soleil violet, une maison, quatre bonshommes dont un « papa » barré puis réécrit.", "Villard-de-Lans", None, None),
    ("p_n09", t(10, "12:05"), "receipt", "Facture du garage — pneus neige.", "Montage et équilibrage de quatre pneus.",
     "Garage du Plateau", "document",
     ["GARAGE DU PLATEAU", "Villard-de-Lans", "10/11/2026", "4 pneus neige 205/55 R16", "Montage + équilibrage", "TOTAL TTC   312,00 €"]),
    ("p_n10", t(12, "07:30"), "snow", "Premiers flocons sur le balcon.", "Une fine couche blanche sur la rambarde.",
     "Villard-de-Lans", None, None),
    ("p_n11", t(13, "18:40"), "group", "Pot d'anniversaire de Lina.",
     "Cinq silhouettes autour d'un gâteau, Béatrice fait des cornes à Olivier.", "L'Écho des Alpes", "selfie", None),
    ("p_n12", t(15, "10:12"), "pocket", "Photo prise dans une poche.", "Du noir, un bout de doublure.", None, "blurry", None),
    ("p_n13", t(17, "21:15"), "document", "Planning de garde de décembre, griffonné.",
     "Les semaines sont surlignées en deux couleurs.", "Villard-de-Lans", "document",
     ["DÉCEMBRE", "28/11 → 05/12 : moi", "05/12 → 12/12 : R.", "12/12 : anniv Léo (chez moi)", "Noël : moi · Nouvel an : R."]),
    ("p_n14", t(19, "07:55"), "screenshot", "Capture : mon article de ce matin.", "Publié en page 3.",
     None, "screenshot",
     ["L'ÉCHO DES ALPES", "Vallières : la carrière s'agrandit", "L'arrêté du 20 septembre autorise 11 hectares", "de plus. Des riverains contestent.", "Par Solène Marchetti"]),
    ("p_n15", t(21, "07:02"), "ceiling", "Le plafond de la chambre.", "Photo prise par erreur au réveil.",
     "Villard-de-Lans", "blurry", None),
    ("p_n16", t(22, "14:30"), "snow", "Autrans, première neige qui tient.", "Des traces de skis de fond, un banc enneigé.",
     "Autrans", None, None),
    ("p_n17", t(24, "10:35"), "mountain", "La carrière depuis le chemin forestier.",
     "Un front de taille, une pelleteuse jaune, une barrière « Accès interdit ».", "Carrière Brassac Granulats", None, None),
    ("p_n18", t(25, "19:40"), "street_night", "Villard, la grande rue sous la pluie.",
     "Des guirlandes pas encore allumées, une voiture passe.", "Villard-de-Lans", "night", None),
    ("p_n19", t(26, "13:20"), "snow", "Bois Barbu : première sortie en skating.", "Les traces sont fraîches, personne sur la piste.",
     "Bois Barbu", None, None),
    ("p_n20", t(26, "07:45"), "screenshot", "Capture : état des routes du Vercors.", "Brouillard annoncé sur les cols.",
     None, "screenshot",
     ["Inforoute Isère", "D106 — Col de la Croix-Perrin", "Ouvert · brouillard fréquent la nuit", "D531 — Gorges de la Bourne", "Équipements hiver obligatoires"]),
    ("p_n21", t(27, "09:20"), "office", "La rédaction, avant la conf.", "Un café, des journaux empilés, l'écran d'Agathe allumé au fond.",
     "L'Écho des Alpes", None, None),
    ("p_n22", t(27, "17:50"), "rain", "La cour sous la pluie.", "Une pluie froide, la lampe du voisin allumée.",
     "Villard-de-Lans", None, None),
    ("p_n23", t(27, "22:36"), "car", "Le tableau de bord avant de partir.",
     "Le thermomètre affiche 3 °C. Réservoir au quart. Une pochette cartonnée sur le siège passager.", "Villard-de-Lans", "quick", None),
    ("p_n24", t(27, "23:09"), "road_night", "Le parking du col : rien que du brouillard.",
     "Aucune autre voiture. Un panneau « Col de la Croix-Perrin — 1220 m ».", "Col de la Croix-Perrin", "blurry", None),
]
for pid, taken, scene, cap, det, place, style, lines in roll:
    photo(pid, taken, scene, cap, det, place=place, style=style, lines=lines,
          device="iPhone 8" if taken < "2021" else OWN)

# The courtyard of the town hall, a month before: the same car as at the pass.
photo("p_mairie_4x4", t(23, "19:48", 10), "parking_night", "La cour de la mairie de Vallières, avant le conseil.",
      "Dans la cour, un 4×4 gris foncé garé sur la place « Adjoint à l'urbanisme », un macaron « ÉLU » derrière le "
      "pare-brise et un autocollant du club de ski de Vallières sur la vitre arrière.",
      place="Mairie de Vallières-en-Vercors", style="night")
# The photo of the quarry's bank statement sent by the source.
photo("p_doc_virements", t(6, "19:40"), "document", "Photo d'un relevé bancaire de Brassac Granulats.",
      "Photo prise de biais sur un bureau, un doigt masque un coin. La ligne du 12/09 est surlignée au stylo jaune.",
      source="received", frm="julien", received=t(6, "19:52"), place="Carrière Brassac Granulats", device="Galaxy A52",
      style="document",
      lines=["BRASSAC GRANULATS — RELEVÉ", "Compte courant n° •••• 4471", "02/09/2026 — Prélèvement — Assurance engins — 3 812,40 €",
             "12/09/2026 — Virement — G.A. — 25 000,00 €", "Objet : conseil", "18/09/2026 — Virement — Transports Rival — 9 460,00 €"])
photo("p_platre", t(27, "18:38"), "bed", "Une jambe plâtrée sur un brancard, sous un néon.",
      "Au poignet, un bracelet d'identification du CHU : « FAURE Julien — 27/11/2026 18:31 ». Au fond, un couloir d'urgences.",
      source="received", frm="julien", received=t(27, "18:40"), place="CHU de Grenoble", device="Galaxy A52")
photo("p_kids_2305", t(27, "23:04"), "bed", "Deux enfants endormis dans des lits superposés.",
      "Une veilleuse en forme de lune. Métadonnées : 23:04, Grenoble — Île Verte.",
      source="received", frm="romain", received=t(27, "23:05"), place="Grenoble — Île Verte", device="iPhone 14", style="night")
photo("p_bat_2301", t(27, "23:01"), "document", "Le BAT de la une de samedi.",
      "Une épreuve posée sur une table lumineuse, des rotatives floues au fond. Métadonnées : 23:01, Échirolles — Imprimerie du Drac.",
      source="received", frm="agathe", received=t(27, "23:02"), place="Imprimerie du Drac — Échirolles", device="Pixel 7",
      style="document",
      lines=["L'ÉCHO DES ALPES", "SAMEDI 28 NOVEMBRE 2026", "NEIGE : LE VERCORS SE PRÉPARE", "À UN HIVER PRÉCOCE", "BAT 23:00 — OK A.L."])
photo("p_col_2314", t(27, "23:14"), "road_night", "Des phares dans le brouillard, sur le parking du col.",
      "Des phares dans le brouillard. Un 4×4 gris foncé ; derrière le pare-brise, un macaron « ÉLU ». Un autocollant de club "
      "de ski sur la vitre arrière. La plaque est illisible.",
      place="Col de la Croix-Perrin", style="night")
# Received noise.
photo("p_r_chat", t(8, "16:15"), "cat", "Le chat de Maman dans le panier à linge.", "Un chat tigré roulé en boule sur des draps.",
      source="received", frm="maman", received=t(8, "16:20"), place="Voiron", device="iPhone SE")
photo("p_r_dent", t(21, "19:38"), "interior_warm", "Léo montre le trou de sa dent.",
      "Une silhouette d'enfant sourit, une dent posée dans une boîte d'allumettes.",
      source="received", frm="romain", received=t(21, "19:40"), place="Grenoble — Île Verte", device="iPhone 14")

# ---------------------------------------------------------------- calendar
calendar = [
    dict(id="c_ev01", start=t(23, "20:00", 10), end=t(23, "22:30", 10), title="Conseil municipal Vallières",
         location="Mairie de Vallières-en-Vercors", notes="Couvrir. Arrêté carrière pas à l'ordre du jour ?"),
    dict(id="c_ev02", start=t(14, "10:00"), title="Foire aux skis d'Autrans (+ enfants)", location="Autrans"),
    dict(id="c_ev03", start=t(12, "14:00"), end=t(12, "15:00"), title="Me Aubert", location="Grenoble"),
    dict(id="c_ev04", start=t(18, "17:30"), title="Pédiatre Nina — Dr Chabert", location="Villard-de-Lans"),
    dict(id="c_ev05", start=t(21, "08:30"), title="Échange garde → R.", location="Villard"),
    dict(id="c_ev06", start=t(26, "13:00"), end=t(26, "15:00"), title="Ski de fond", location="Bois Barbu"),
    dict(id="c_ev07", start=t(27, "09:30"), end=t(27, "11:00"), title="Conf de rédac — carrière", location="L'Écho",
         notes="2 sujets. Pitcher la carrière pour lundi."),
    dict(id="c_conseil", start=t(27, "20:00"), end=t(27, "23:00"), title="Conseil municipal Vallières",
         location="Mairie de Vallières-en-Vercors", notes="Béa y va. Moi ? Arnaud préside."),
    dict(id="c_rdv_col", start=t(27, "23:00"), end=t(27, "23:45"), title="J. — col Croix-Perrin 23h",
         location="Parking du col de la Croix-Perrin", notes="Créé le 27 nov. à 21:50"),
    dict(id="c_marche", start=t(28, "09:00"), title="Marché de Villard avec Léo et Nina", location="Villard-de-Lans",
         notes="R. les dépose à 8h30."),
    dict(id="c_ev11", start=t(1, "10:00", 12), title="Audience JAF — Me Aubert", location="Tribunal judiciaire de Grenoble"),
    dict(id="c_ev12", start=t(4, "08:30", 12), title="Sortie raquettes (école)", location="Lans-en-Vercors",
         notes="Autorisation signée ✔"),
    dict(id="c_ev13", start=t(12, "00:00", 12), title="🎂 Anniversaire Léo", allDay=True),
]

# ---------------------------------------------------------------- notes (locked: code = birthday 1403)
notes = [
    dict(id="n_enquete", title="Carrière", createdAt=t(6, "21:30"), modifiedAt=t(27, "16:40"),
         body="Carrière — ce que j'ai :\n- relevés Brassac (via J.)\n- virement 12/09 : 25 000 € à « G.A. », objet « conseil »\n"
              "- G.A. = Gilles Arnaud ?? adjoint urbanisme, a signé l'arrêté du 20/09\n- 8 jours entre le virement et la signature\n\n"
              "Il me faut une 2e source. Fred ?\nArnaud ne répond ni au mail ni au tel.\n\nClé USB : toujours sur moi. Copie papier dans la pochette."),
    dict(id="n_courses", title="Courses", createdAt=t(21, "18:00"), modifiedAt=t(26, "18:40"),
         body="- lait\n- compotes Nina\n- piles veilleuse\n- sac poubelle\n- sirop (demander Dr Chabert)\n- bougies anniv Léo"),
    dict(id="n_wifi", title="Wi-Fi rédac", createdAt=at(2025, 1, 6, "09:12"), modifiedAt=at(2025, 1, 6, "09:12"),
         body="Réseau : ECHO-REDAC\nMot de passe : rotative1946"),
    dict(id="n_sujets", title="Idées de sujets", createdAt=t(2, "22:10", 9), modifiedAt=t(24, "22:05"),
         body="- Les saisonniers qui ne trouvent plus à se loger\n- Fermeture de la ligne de bus du dimanche\n"
              "- Les pisteurs-secouristes, une nuit avec eux\n- Neige de culture : qui paie ?"),
    dict(id="n_garde", title="Garde", createdAt=t(5, "20:00", 9), modifiedAt=t(17, "21:20"),
         body="Une semaine sur deux. Échange le samedi 8h30.\nVacances de Noël : 1re semaine moi.\n"
              "Ne plus accepter les changements de dernière minute par message."),
]

# ---------------------------------------------------------------- mail
ME_MAIL = "solene.marchetti@echodesalpes.fr"
mails = [
    dict(id="mail_arnaud_2024", folder="inbox", fromName="Gilles Arnaud", fromAddress="g.arnaud@vallieres-en-vercors.fr",
         to=ME_MAIL, at=at(2024, 3, 8, "10:14"), subject="Invitation presse — inauguration du parking relais du Pré-Long",
         body="Madame,\n\nLa commune de Vallières-en-Vercors a le plaisir de vous convier à l'inauguration du parking relais "
              "du Pré-Long, samedi 16 mars 2024 à 11h, en présence du conseil municipal.\n\nUn verre de l'amitié suivra.\n\n"
              "Bien cordialement,\n\nGilles Arnaud\nAdjoint à l'urbanisme, Vallières-en-Vercors\nTél. direct : 07 58 11 20 94"),
    dict(id="mail_demande_arnaud", folder="sent", fromName="Solène Marchetti", fromAddress=ME_MAIL,
         to="g.arnaud@vallieres-en-vercors.fr", at=t(19, "10:02"), subject="Demande d'entretien — arrêté du 20 septembre",
         body="Monsieur Arnaud,\n\nJe prépare un article sur l'extension de la carrière Brassac Granulats autorisée par l'arrêté "
              "du 20 septembre. Je dispose de documents sur lesquels je souhaiterais recueillir votre réaction.\n\n"
              "Je reste joignable au 06 12 84 37 65.\n\nSolène Marchetti\nL'Écho des Alpes"),
    dict(id="mail_droit_reponse", folder="sent", fromName="Solène Marchetti", fromAddress=ME_MAIL,
         to="t.brassac@brassac-granulats.fr", at=t(26, "15:30"), subject="Article à paraître — votre réaction",
         body="Monsieur Brassac,\n\nL'Écho des Alpes s'apprête à publier un article sur des virements de votre société "
              "en septembre 2026. Je souhaite vous donner la possibilité de réagir avant publication.\n\nSolène Marchetti"),
    dict(id="mail_brassac", folder="inbox", fromName="Thierry Brassac", fromAddress="t.brassac@brassac-granulats.fr",
         to=ME_MAIL, at=t(27, "14:10"), subject="Re: Article à paraître — votre réaction",
         body="Madame Marchetti,\n\nJe n'ai rien à répondre à des accusations fondées sur des documents volés. Mes avocats "
              "sont informés.\n\nSi cet article paraît, vous le regretterez, vous et votre journal.\n\nT. Brassac\nPrésident, Brassac Granulats"),
    dict(id="mail_juridique", folder="inbox", fromName="Marc Viallet", fromAddress="m.viallet@echodesalpes.fr",
         to=ME_MAIL, at=t(27, "15:50"), subject="Carrière — avis juridique",
         body="Solène,\n\nJ'ai relu. Le relevé seul ne suffit pas : rien ne dit qui est « G.A. », et ta source, salariée de "
              "Brassac, est identifiable par recoupement.\n\nSans une deuxième source ou une réaction de l'intéressé, je ne peux "
              "pas valider.\n\nMarc"),
    dict(id="mail_agathe_stop", folder="inbox", fromName="Agathe Lemoine", fromAddress="a.lemoine@echodesalpes.fr",
         to=ME_MAIL, at=t(27, "16:30"), subject="Lundi",
         body="On ne publie pas lundi. Le juridique bloque tant qu'on n'a pas une deuxième source.\n\nJe sais ce que ça te coûte. "
              "Pas de bêtise ce week-end.\n\nA."),
    dict(id="mail_aubert", folder="inbox", fromName="Cabinet Aubert", fromAddress="cabinet.aubert@avocats-isere.fr",
         to=ME_MAIL, at=t(13, "11:20"), subject="Audience du 1er décembre",
         body="Madame,\n\nL'audience devant le juge aux affaires familiales est fixée au mardi 1er décembre à 10h. Merci de "
              "m'apporter les justificatifs de vos horaires de travail.\n\nMe C. Aubert",
         attachments=["Convocation_JAF_01-12.pdf"]),
    dict(id="mail_ecole", folder="inbox", fromName="École de Lans-en-Vercors", fromAddress="ecole.lans@ac-grenoble.fr",
         to=ME_MAIL, at=t(16, "18:05"), subject="Sortie raquettes du 4 décembre",
         body="Chers parents, la sortie raquettes des CE1 aura lieu le vendredi 4 décembre. Prévoir vêtements chauds et gourde.",
         attachments=["Autorisation_sortie.pdf"]),
    dict(id="mail_energie", folder="inbox", fromName="Alpénergie", fromAddress="facture@alpenergie.fr",
         to=ME_MAIL, at=t(10, "06:30"), subject="Votre facture de novembre", body="Votre facture de 118,40 € est disponible.",
         attachments=["Facture_novembre.pdf"]),
    dict(id="mail_ski", folder="inbox", fromName="Nordic Vercors", fromAddress="news@nordicvercors.fr",
         to=ME_MAIL, at=t(20, "12:00"), subject="Ouverture des pistes nordiques ❄️",
         body="Les premières pistes de Bois Barbu et d'Autrans ouvrent ce week-end si la neige tient. Forfaits saison en vente en ligne."),
]

# ---------------------------------------------------------------- browser
browser = [
    dict(id="w01", at=t(12, "22:14", 10), kind="search", text="arrêté extension carrière vallières"),
    dict(id="w02", at=t(12, "22:16", 10), kind="visit", text="Vallières-en-Vercors — Registre des actes",
         url="vallieres-en-vercors.fr/actes/2026-114",
         summary="Arrêté n° 2026-114 du 20 septembre 2026 autorisant l'extension de la carrière Brassac Granulats sur 11 hectares. "
                 "Signé : G. Arnaud, adjoint délégué à l'urbanisme."),
    dict(id="w03", at=t(30, "23:05", 10), kind="search", text="protéger ses sources journaliste"),
    dict(id="w04", at=t(30, "23:07", 10), kind="visit", text="Le secret des sources des journalistes : ce que dit la loi",
         url="cnpj-info.fr/secret-des-sources",
         summary="La loi protège le secret des sources. Conseils : ne pas stocker les échanges sensibles sur un téléphone professionnel, "
                 "privilégier les rencontres physiques."),
    dict(id="w05", at=t(1, "20:40"), kind="search", text="pneus neige obligatoires isère date"),
    dict(id="w06", at=t(3, "21:30"), kind="search", text="brassac granulats chiffre d'affaires"),
    dict(id="w07", at=t(18, "22:20"), kind="search", text="gilles arnaud vallières"),
    dict(id="w08", at=t(18, "22:21"), kind="visit", text="Vallières-en-Vercors — Le conseil municipal",
         url="vallieres-en-vercors.fr/conseil",
         summary="Gilles Arnaud, 54 ans, adjoint à l'urbanisme depuis 2020. Ancien moniteur, il préside aussi le club de ski de Vallières."),
    dict(id="w09", at=t(22, "21:10"), kind="search", text="idée cadeau garçon 8 ans lego"),
    dict(id="w10", at=t(25, "21:37"), kind="search", text="col croix perrin fermeture hiver"),
    dict(id="w11", at=t(25, "21:38"), kind="visit", text="Routes du Vercors : fermetures hivernales",
         url="inforoute-isere.fr/vercors",
         summary="Le col de la Croix-Perrin (D106) reste ouvert l'hiver et est déneigé la nuit. Brouillard fréquent en novembre."),
    dict(id="w12", at=t(26, "07:40"), kind="search", text="météo vercors vendredi soir"),
    dict(id="w13", at=t(26, "22:40"), kind="search", text="garde complète conditions juge aux affaires familiales"),
    dict(id="w14", at=t(27, "18:15"), kind="search", text="fracture cheville plâtre combien de temps"),
    dict(id="w15", at=t(27, "18:17"), kind="visit", text="Fracture de la cheville : prise en charge aux urgences",
         url="sante-pratique.fr/fracture-cheville",
         summary="Une fracture déplacée est souvent opérée : le patient est alors gardé à jeun pour la nuit et opéré le lendemain."),
    dict(id="w_debat", at=t(27, "19:50"), kind="visit", text="TéléAlpes — Ce soir", url="telealpes.fr/programme",
         summary="Débat en direct 22:45–23:30 : l'avenir des carrières du Vercors, avec Thierry Brassac (Brassac Granulats)."),
]

# ---------------------------------------------------------------- live events (the phone keeps living)
def live_time(after):
    total = 50 + after // 60
    return t(28, f"00:{total:02d}") if total < 60 else t(28, f"01:{total - 60:02d}")


def live_msg(eid, after, conv_id, frm, text, title, mid):
    return dict(id=eid, afterSeconds=after, kind="message", app="messages", title=title, body=text,
                conversation=conv_id, message=dict(id=mid, **{"from": frm}, at=live_time(after), text=text),
                opens=f"message:{mid}")


live = [
    live_msg("lv01", 25, "c_maman", "maman", "Solène ?? les gendarmes m'ont appelée. Rappelle-moi", "Maman", "m_live_maman"),
    dict(id="lv02", afterSeconds=80, kind="call", app="phone", title="Appel manqué", body="Agathe Lemoine",
         call=dict(id="k_lv02", contact="agathe", direction="missed", at=live_time(80), durationSeconds=0), opens="call:k_lv02"),
    live_msg("lv03", 140, "c_jnew", "jnew", "J'ai attendu 1h au col, t'es jamais venue. C'est quoi ce délire ?",
             "Julien (nouveau n°)", "m_live_new"),
    live_msg("lv04", 200, "c_romain", "romain", "Les gendarmes sont chez moi. Je garde les enfants. Réponds.", "Romain Vidal",
             "m_live_romain"),
    live_msg("lv05", 260, "c_julien", "julien", "solène les gendarmes m appellent, qu est ce qui se passe ?? je suis tjrs a l hopital",
             "Julien Faure", "m_live_julien"),
    live_msg("lv06", 320, "c_redac", "beatrice", "agathe vient de m'appeler. quelqu'un a des nouvelles de solène ?",
             "Rédac Écho 📰 — Béatrice", "m_live_beatrice"),
    dict(id="lv07", afterSeconds=380, kind="reminder", app="calendar", title="Aujourd'hui 09:00",
         body="Marché de Villard avec Léo et Nina", opens="calendar:c_marche"),
    live_msg("lv08", 440, "c_agathe", "agathe", "Je monte à la gendarmerie de Villard. Solène, si tu lis ça : on a tout gardé. Tout.",
             "Agathe Lemoine", "m_live_agathe"),
]
LEVELS = {"lv01": "urgent", "lv03": "important", "lv04": "important", "lv05": "important"}
for e in live:
    e["level"] = LEVELS.get(e["id"], "normal")

device = dict(
    id="dev_solene", label="Téléphone de Solène", model="iPhone 12",
    lockedApps=[dict(app="notes", code="1403", hint="Ma date (JJMM)")],
    contacts=contacts, conversations=convs, calls=calls, places=places, tracks=tracks, photos=photos,
    calendar=calendar, notes=notes, mails=mails, browser=browser, liveEvents=live,
    wallpaper="storm", batteryPercent=18,
)

# ---------------------------------------------------------------- suspects
suspects = [
    dict(id="s_gilles", contact="gilles", role="Adjoint à l'urbanisme de Vallières-en-Vercors", age=54,
         address="Vallières-en-Vercors",
         statement="« J'ai présidé le conseil municipal jusqu'à 23h, puis je suis rentré chez moi. Je ne connais cette journaliste que de loin. »",
         verdict="Gilles Arnaud a signé l'extension de la carrière huit jours après un virement de 25 000 € à « G.A. ». Avec une vieille "
                 "ligne prépayée — son ancien numéro direct — il s'est fait passer pour Julien, a attiré Solène au col et a levé le "
                 "conseil à 21h10 pour être au rendez-vous. Son 4×4 d'élu est sur la photo de 23:14."),
    dict(id="s_thierry", contact="thierry", role="Patron de Brassac Granulats", age=61, address="Saint-Nizier-du-Moucherotte",
         alibi="De 22:45 à 23:30, Thierry Brassac était en direct sur le plateau de TéléAlpes, à Grenoble, à près d'une heure du col.",
         alibiEvidence="e_thierry_alibi",
         trap="Un mail de menace le jour même (« vous le regretterez ») et 25 000 € sortis de ses comptes : le mobile était évident, "
              "mais pas l'occasion.",
         statement="« Ce soir-là, j'étais sur le plateau de TéléAlpes, en direct. »",
         verdict="Thierry Brassac a menacé Solène et devra s'expliquer sur ses virements. Mais pendant qu'elle attendait au col, il "
                 "parlait en direct sur TéléAlpes, à Grenoble, de 22:45 à 23:30."),
    dict(id="s_romain", contact="romain", role="Ex-mari de Solène", age=37, address="Île Verte, Grenoble",
         alibi="La position partagée de Romain le place à Grenoble toute la soirée, et il envoie à 23:05 une photo des enfants endormis, prise à 23:04 chez lui.",
         alibiEvidence="e_romain_alibi",
         trap="Des menaces sur la garde, la veille, et il savait que Solène sortait ce soir-là : un coupable tout trouvé.",
         statement="« J'étais chez moi à Grenoble avec les enfants toute la soirée. »",
         verdict="Romain voulait faire pression sur Solène à travers la garde des enfants. Mais il n'a pas quitté Grenoble : à 23:04 il "
                 "photographiait Léo et Nina endormis, à quarante minutes de route du col."),
    dict(id="s_agathe", contact="agathe", role="Directrice de la rédaction de L'Écho des Alpes", age=49, address="Grenoble",
         alibi="À 23:01, Agathe photographiait le BAT de la une à l'imprimerie d'Échirolles, à 45 minutes du col.",
         alibiEvidence="e_agathe_alibi",
         trap="Elle avait bloqué l'article l'après-midi même, et elle était la seule à qui Solène avait dit où elle allait.",
         statement="« J'ai bouclé l'édition à l'imprimerie jusqu'à minuit passé. »",
         verdict="Agathe a bloqué l'article et savait que Solène montait au col, mais elle bouclait l'édition à Échirolles : son BAT "
                 "est photographié à 23:01. C'est elle qui a donné l'alerte."),
    dict(id="s_julien", contact="julien", role="Conducteur d'engins à la carrière — la source de Solène", age=29, address="Lans-en-Vercors",
         alibi="Julien s'est cassé la cheville à 17:20. Le bracelet du CHU (18:31), son appel de 19:12 et son message de 21:03 le placent aux urgences, gardé pour la nuit.",
         alibiEvidence="e_julien_alibi",
         trap="C'est « Julien » qui a fixé le rendez-vous et « Julien » qui écrit à 23:47 qu'il attend au col. Mais ce n'est pas son numéro.",
         statement="« Je me suis cassé la cheville au travail vendredi, j'étais aux urgences à Grenoble jusqu'à 1h du matin. »",
         verdict="Julien n'a jamais changé de numéro. Pendant que son « nouveau numéro » donnait rendez-vous à Solène, lui était "
                 "plâtré aux urgences du CHU, d'où il lui écrivait de reporter."),
]

# ---------------------------------------------------------------- evidence
evidence = [
    dict(id="e_two_juliens", title="Deux Julien le même soir", importance="key", suspects=["s_gilles", "s_julien"],
         refs=["message:m_new_2140", "message:m_julien_2103"],
         meaning="À 21:03, le vrai Julien écrit de son numéro habituel qu'on le garde aux urgences. À 21:40, le « nouveau numéro » "
                 "écrit « Finalement je peux ». Ce ne sont pas la même personne."),
    dict(id="e_signature", title="Le numéro dans la signature", importance="key", suspects=["s_gilles"],
         refs=["contact:jnew", "mail:mail_arnaud_2024"],
         meaning="Le 07 58 11 20 94 du « nouveau » Julien est le « Tél. direct » de Gilles Arnaud dans son invitation presse de 2024."),
    dict(id="e_4x4", title="Le 4×4 du col", importance="key", suspects=["s_gilles"],
         refs=["photoInfo:p_col_2314"],
         meaning="Le véhicule du rendez-vous, photographié à 23:14 : un 4×4 gris foncé, un macaron « ÉLU », un autocollant de club de ski."),
    dict(id="e_motive", title="25 000 € à « G.A. »", importance="key", suspects=["s_gilles", "s_thierry"], anyOf=True,
         refs=["photoInfo:p_doc_virements", "note:n_enquete"],
         meaning="Brassac a versé 25 000 € à « G.A. » le 12 septembre ; Gilles Arnaud a signé l'extension le 20. L'article l'aurait mis en cause."),
    dict(id="e_same_car", title="Le même 4×4 à la mairie", importance="supporting", suspects=["s_gilles"],
         refs=["photoInfo:p_mairie_4x4"],
         meaning="Le 23 octobre, le même 4×4 était garé sur la place « Adjoint à l'urbanisme » : macaron ÉLU, autocollant du club de ski de Vallières."),
    dict(id="e_council_early", title="Le conseil levé à 21h10", importance="supporting", suspects=["s_gilles"],
         refs=["message:m_redac_2114"],
         meaning="Arnaud dit avoir présidé jusqu'à 23h. Le conseil a été levé à 21h10 et il est parti le premier."),
    dict(id="e_julien_alibi", title="Aux urgences", importance="supporting", suspects=["s_julien"], anyOf=True,
         refs=["photoInfo:p_platre", "call:k_julien_1912"],
         meaning="Bracelet du CHU daté de 18:31, appel de 19:12 depuis son numéro habituel : Julien est plâtré, aux urgences."),
    dict(id="e_thierry_alibi", title="En direct à la télévision", importance="supporting", suspects=["s_thierry"], anyOf=True,
         refs=["browser:w_debat", "message:m_agathe_2258"],
         meaning="Thierry Brassac débattait en direct sur TéléAlpes de 22:45 à 23:30, à Grenoble."),
    dict(id="e_romain_alibi", title="Les enfants endormis", importance="supporting", suspects=["s_romain"], anyOf=True,
         refs=["track:t_romain", "photoInfo:p_kids_2305"],
         meaning="Romain était chez lui, à l'Île Verte, de 18:30 à minuit : position partagée et photo prise à 23:04."),
    dict(id="e_agathe_alibi", title="Le BAT de 23:01", importance="supporting", suspects=["s_agathe"],
         refs=["photoInfo:p_bat_2301"],
         meaning="À 23:01, Agathe était à l'imprimerie d'Échirolles, à 45 minutes du col."),
    dict(id="f_julien_rdv", title="« Je suis au parking du col »", importance="falseLead", suspects=["s_julien"],
         refs=["message:m_new_2347"],
         meaning="« Julien » dit attendre au col — mais c'est le faux numéro, qui se couvre après coup."),
    dict(id="f_brassac_threat", title="« Vous le regretterez »", importance="falseLead", suspects=["s_thierry"],
         refs=["mail:mail_brassac"],
         meaning="Une menace d'avocats et d'image, envoyée le jour même. Brassac était pourtant à la télévision pendant le rendez-vous."),
    dict(id="f_romain_custody", title="La menace sur la garde", importance="falseLead", suspects=["s_romain"],
         refs=["message:m_romain_threat"],
         meaning="Une pression de père inquiet, pas un piège : Romain n'a pas quitté Grenoble."),
    dict(id="f_agathe_knew", title="Elle savait", importance="falseLead", suspects=["s_agathe"], anyOf=True,
         refs=["call:k_agathe_2231", "mail:mail_agathe_stop"],
         meaning="Agathe a bloqué l'article et savait que Solène montait au col. C'est aussi elle qui a donné l'alerte."),
]

hints = [
    dict(id="h1", text="Deux « Julien » écrivent à Solène le même soir. Sont-ils vraiment la même personne ?", scoreCost=0),
    dict(id="h2", text="Comparez le numéro du « nouveau » Julien avec ceux que vous trouvez ailleurs dans le téléphone : "
                       "les vieux mails gardent des signatures.", scoreCost=8),
    dict(id="h3", text="Solène a photographié la voiture qui arrivait au col à 23:14. Où a-t-elle déjà vu ce 4×4 ?",
         scoreCost=15, unlockAtRemainingSeconds=120),
]

solution = dict(
    culprit="s_gilles",
    headline="Gilles Arnaud s'est fait passer pour Julien pour attirer Solène au col.",
    summary="Le « nouveau numéro » de sa source était une vieille ligne de l'adjoint à l'urbanisme. Il voulait les documents qui le mettaient en cause.",
    reveal=[
        dict(at=at(2024, 3, 8, "10:14"), text="Gilles Arnaud signe une invitation presse : « Tél. direct : 07 58 11 20 94 »",
             evidence="e_signature"),
        dict(at=t(23, "19:48", 10), text="Solène photographie le 4×4 de l'adjoint dans la cour de la mairie", evidence="e_same_car"),
        dict(at=t(6, "19:52"), text="Julien envoie le relevé : 25 000 € versés à « G.A. » le 12 septembre", evidence="e_motive"),
        dict(at=t(25, "21:12"), text="« C'est Julien. Nouveau numéro » — depuis le 07 58 11 20 94", evidence="e_signature"),
        dict(at=t(27, "21:03"), text="Le vrai Julien, aux urgences : « ils me gardent pour la nuit »", evidence="e_julien_alibi"),
        dict(at=t(27, "21:10"), text="Arnaud lève le conseil municipal et part le premier", evidence="e_council_early"),
        dict(at=t(27, "21:40"), text="Le faux Julien : « Finalement je peux. 23h au parking du col »", evidence="e_two_juliens"),
        dict(at=t(27, "23:14"), text="Solène photographie le 4×4 qui arrive : macaron ÉLU, autocollant de club de ski", evidence="e_4x4"),
        dict(at=t(27, "23:47"), text="« Je suis au parking du col, t'es où ? » — Arnaud se couvre", evidence="f_julien_rdv"),
    ],
    story=[
        "Depuis octobre, Julien Faure, conducteur d'engins chez Brassac Granulats, renseigne Solène. Le 6 novembre, il lui envoie "
        "la photo d'un relevé : 25 000 € versés le 12 septembre à « G.A. », huit jours avant que Gilles Arnaud signe l'arrêté "
        "d'extension de la carrière.",
        "Le 19 novembre, Solène demande un entretien à Arnaud : il comprend qu'elle a des documents. Brassac, qui soupçonne Julien "
        "depuis qu'on l'a vu au bureau de la comptabilité, lui en parle. Le 25 novembre, Arnaud ressort une vieille ligne prépayée — "
        "le « numéro direct » qu'il donnait aux journalistes en 2024 — et écrit à Solène en se faisant passer pour Julien.",
        "Le faux Julien ne connaît ni l'heure prévue ni les habitudes du vrai. Il déplace le rendez-vous au col de la Croix-Perrin et "
        "promet un deuxième témoin, exactement ce que la rédaction exige. Vendredi, le vrai Julien se casse la cheville et reste aux "
        "urgences du CHU. À 21h10, Arnaud lève le conseil municipal et quitte la mairie le premier ; à 21:40, il écrit : "
        "« Finalement je peux. »",
        "Solène prévient Agathe, part à 22:40 et arrive au col à 23:08. À 23:14, par réflexe de journaliste, elle photographie le 4×4 "
        "qui sort du brouillard. Arnaud réclame la clé USB. Elle refuse et s'enfuit à pied dans la forêt ; son téléphone reste sur le "
        "siège passager. Il fouille la voiture, emporte la pochette de documents et, à 23:47, écrit « Je suis au parking du col, "
        "t'es où ? » pour faire croire que Julien l'attendait.",
        "Brassac était en direct sur TéléAlpes, Romain veillait les enfants à Grenoble, Agathe bouclait l'édition à Échirolles, Julien "
        "était plâtré au CHU. Chacun avait une raison d'en vouloir à Solène, ou savait où elle allait. Aucun n'était au col.",
        "Grâce à votre enquête, les gendarmes cherchent au bon endroit : Solène est retrouvée à 6h40 dans une cabane de chasseurs, en "
        "hypothermie, mais vivante. La clé USB était dans sa poche. Gilles Arnaud est interpellé dans la matinée ; une enquête est "
        "ouverte sur les virements de Brassac Granulats.",
    ],
)

# ---------------------------------------------------------------- opening sequence
intro = dict(shots=[
    dict(kind="scene", seconds=7, scene="road_night", camera="push", effect="hazard", ambience=["rain", "engine"],
         lines=[dict(text="COL DE LA CROIX-PERRIN · VENDREDI 27 NOVEMBRE · 23:48", at=0.3),
                dict(text="Moteur allumé. Portière ouverte.", at=2.6)]),
    dict(kind="scene", seconds=5, scene="road_night", camera="drift", effect="rain", ambience=["rain", "engine"]),
    dict(kind="phoneOnTable", seconds=7, surface="carSeat", label="Siège passager — 23:48", ambience=["rain", "engine"],
         cues=[dict(sound="vibrate", at=0.8), dict(sound="notification", at=0.85), dict(sound="notification", at=2.6),
               dict(sound="ring", at=4.2)],
         notifications=[dict(app="messages", title="Julien (nouveau n°)", body="Je suis au parking du col, t'es où ?", at=0.8),
                        dict(app="messages", title="Romain Vidal", body="Tu rentres quand ? Léo a de la fièvre", at=2.6),
                        dict(app="phone", title="Agathe Lemoine", body="Appel entrant", at=4.2, call=True)],
         lines=[dict(text="Personne ne répond.", at=5.6)]),
    dict(kind="title", seconds=1.2, cues=[dict(sound="vibrate", at=0.4)]),
    dict(kind="unlock", seconds=2.4),
])

case = dict(
    schemaVersion=1, id="case_005", number=5, title="ROUTE DE NUIT",
    tagline="Moteur allumé, portière ouverte. Personne.",
    synopsis=[
        "Vendredi 27 novembre, 23h48. Sur la route du col de la Croix-Perrin, dans le Vercors, un agent de déneigement trouve une "
        "voiture arrêtée sur le bas-côté : feux de détresse, moteur allumé, portière ouverte.",
        "La conductrice, Solène Marchetti, 34 ans, journaliste à L'Écho des Alpes, a disparu. Son téléphone était sur le siège "
        "passager. Elle enquêtait depuis des mois sur l'extension d'une carrière.",
        "Cinq personnes avaient une raison de la croiser cette nuit. Il pleut. Le temps presse.",
    ],
    objective="Identifier la personne qui a donné rendez-vous à Solène au col.",
    difficulty=1, durationSeconds=480, phoneStartTime=PHONE_START,
    challengeDurations={"investigator": 900, "detective": 480, "expert": 300},
    introScene=intro,
    devices=[device], suspects=suspects, evidence=evidence, hints=hints, solution=solution,
)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(case, f, ensure_ascii=False, indent=1)
n_msgs = sum(len(c["messages"]) for c in convs)
print(f"case_005: {len(contacts)} contacts, {len(convs)} conversations, {n_msgs} messages, {len(calls)} calls, "
      f"{len(photos)} photos, {len(calendar)} events, {len(notes)} notes, {len(mails)} mails, {len(browser)} web, "
      f"{len(live)} live events, {len(places)} places, {len(tracks)} tracks")
