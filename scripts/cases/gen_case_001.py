# Generates ScreenshotKit/Sources/CaseLibrary/Resources/Cases/case_001.json
# Case #001 — LE DERNIER MESSAGE. Saturday 12 Sept 2026 night; investigation Sunday 13 Sept 10:00.
import json, sys

OUT = sys.argv[1]
Y = 2026
def t(day, hm, month=9):
    return f"{Y}-{month:02d}-{day:02d} {hm}"

# ---------------------------------------------------------------- contacts
contacts = [
    dict(id="me", name="Alex Moreau", phone="+33 6 41 22 87 90", relation="Moi", email="alex.moreau@mailo.fr",
         birthday="16/09/1999", avatarHue=0.58, isOwner=True),
    dict(id="emma", name="Emma Roussel", phone="+33 6 72 10 45 33", relation="Collectif Lumen (trésorière)",
         email="emma.roussel@mailo.fr", avatarHue=0.93),
    dict(id="lucas", name="Lucas Ferrand", phone="+33 6 18 64 02 71", relation="Meilleur ami", avatarHue=0.08),
    dict(id="sarah", name="Sarah Vasseur", phone="+33 7 81 40 12 56", relation="Ex", avatarHue=0.78),
    dict(id="karim", name="Karim Haddad", phone="+33 6 55 90 31 08", relation="Ami", avatarHue=0.13),
    dict(id="ines", name="Inès Carpentier", phone="+33 6 03 77 61 24", relation="Amie", avatarHue=0.45),
    dict(id="tom", name="Tom Delorme", phone="+33 7 69 25 13 80", relation="Escalade", avatarHue=0.30),
    dict(id="maman", name="Maman", phone="+33 6 80 11 42 07", relation="Mère", avatarHue=0.02),
    dict(id="elodie", name="Élodie Garnier", phone="+33 6 91 52 38 14", relation="Collègue — Agence Varenne",
         email="e.garnier@agence-varenne.fr", avatarHue=0.52),
    dict(id="hugo", name="Hugo Vasseur", phone="+33 6 27 48 90 65", relation="Frère de Sarah", avatarHue=0.70),
    dict(id="banque", name="Banque Azur", phone="38 21", avatarHue=0.60),
    dict(id="colis", name="Colis Express", phone="36 44", avatarHue=0.10),
]

# ---------------------------------------------------------------- messages
convs = []
def conv(cid, participants, msgs, title=None, draft=None):
    c = dict(id=cid, participants=participants, messages=[])
    if title: c["title"] = title
    for i, m in enumerate(msgs):
        frm, at, text = m[0], m[1], m[2]
        extra = m[3] if len(m) > 3 else {}
        mid = extra.pop("id", f"m_{cid}_{i:03d}")
        msg = dict(id=mid, **{"from": frm}, at=at)
        if text: msg["text"] = text
        msg.update(extra)
        c["messages"].append(msg)
    c["messages"].sort(key=lambda x: x["at"])
    if draft: c["draft"] = draft
    convs.append(c)

# --- Emma (collective Lumen, treasurer) — the truth hides in deleted messages
conv("c_emma", ["emma"], [
    ("emma", t(17, "10:12", 8), "Hello ! Tu as toujours les clés du local ?"),
    ("me", t(17, "10:40", 8), "Oui, je passe les déposer jeudi"),
    ("emma", t(17, "10:41", 8), "Parfait merci 🙏"),
    ("emma", t(20, "18:05", 8), "Les tirages pour l'expo sont prêts. 14 au total"),
    ("me", t(20, "18:30", 8), "Top. On met quoi comme cadres ?"),
    ("emma", t(20, "18:31", 8), "Bois clair, comme l'an dernier. Je m'occupe de la commande"),
    ("me", t(20, "18:32", 8), "Ok, tu me dis combien je te dois"),
    ("emma", t(20, "18:40", 8), "C'est l'asso qui paie, t'inquiète 😉"),
    ("emma", t(26, "21:02", 8), "Tu as vu le mail de la mairie pour la buvette ?"),
    ("me", t(26, "21:30", 8), "Oui, le 5 septembre c'est bon pour eux"),
    ("emma", t(26, "21:31", 8), "Génial"),
    ("emma", t(1, "09:15"), "Je t'envoie le tableau des dépenses de l'été ce soir"),
    ("me", t(1, "12:02"), "Merci. Le comptable veut tout pour le 8"),
    ("emma", t(1, "12:10"), "Oui oui je sais"),
    ("emma", t(3, "23:48"), "Tableau envoyé. Il manque 2-3 justificatifs, je les retrouve"),
    ("me", t(4, "08:30"), "Ok merci"),
    ("emma", t(5, "23:58"), "Merci pour ce soir ✨ le vernissage était parfait"),
    ("me", t(6, "10:21"), "Merci à toi ! Belle équipe"),
    ("emma", t(8, "19:04"), "Tu passes au local demain ?"),
    ("me", t(8, "19:40"), "Non, grosse journée au boulot"),
    ("emma", t(9, "19:20"), "Le comptable t'a écrit à toi aussi ?"),
    ("me", t(9, "19:52"), "Oui."),
    ("emma", t(9, "19:53"), "On en parle ?"),
    ("me", t(9, "20:15"), "Pas par message."),
    ("emma", t(10, "22:40"), "Tu m'en veux ?"),
    ("me", t(11, "08:02"), "Je veux juste comprendre."),
    ("emma", t(12, "16:12"), "Tu as dit quelque chose aux autres ?"),
    ("me", t(12, "16:40"), "Non."),
    ("emma", t(12, "16:41"), "Ok. Merci."),
    ("emma", t(12, "21:40"), "Parking du Quai 9. 22h. Viens seul.", dict(id="m_emma_del1", deletedAt=t(12, "21:44"))),
    ("emma", t(12, "21:41"), "Et efface cette conversation stp.", dict(id="m_emma_del2", deletedAt=t(12, "21:44"))),
    ("emma", t(12, "22:30"), "T'es où ? Moi je suis restée chez moi toute la soirée, regarde l'état 😩",
     dict(id="m_emma_2230", photo="p_emma_couch")),
    ("emma", t(13, "01:12"), "Alex ???", dict(id="m_emma_0112", unread=True)),
])

# --- Lucas (best friend) — lies about his evening
conv("c_lucas", ["lucas"], [
    ("lucas", t(16, "14:03", 8), "Tu viens jouer ce soir ?"),
    ("me", t(16, "14:20", 8), "Vers 21h ok"),
    ("lucas", t(16, "23:58", 8), "Gg pour la dernière partie 😂"),
    ("lucas", t(23, "11:45", 8), "Ma Clio est ENFIN sortie du garage", dict(photo="p_lucas_car")),
    ("me", t(23, "11:50", 8), "Elle a jamais été aussi propre"),
    ("lucas", t(23, "11:51", 8), "400 balles le parallélisme, je pleure"),
    ("lucas", t(28, "19:10", 8), "Tu peux m'aider à monter le canapé dimanche ?"),
    ("me", t(28, "19:30", 8), "Ouais. 14h ?"),
    ("lucas", t(28, "19:31", 8), "Parfait, je te dois une bière"),
    ("lucas", t(30, "17:22", 8), "Merci mec, sans toi il serait encore dans l'escalier"),
    ("lucas", t(2, "20:44"), "T'as vu le match ??"),
    ("me", t(2, "21:10"), "La fin était folle"),
    ("lucas", t(4, "18:02"), "Vendredi soir Levant ?"),
    ("me", t(4, "18:20"), "Pas ce week-end, vernissage demain soir. Samedi prochain ?"),
    ("lucas", t(7, "12:30"), "Tu me prêtes ton pied photo ce week-end ?"),
    ("me", t(7, "12:45"), "Pas de souci, passe le prendre"),
    ("lucas", t(10, "20:14"), "Emma est bizarre en ce moment non ?"),
    ("me", t(10, "20:40"), "Pourquoi tu dis ça"),
    ("lucas", t(10, "20:41"), "Je sais pas, elle répond plus sur le groupe"),
    ("me", t(10, "20:52"), "Elle est débordée avec l'asso"),
    ("lucas", t(12, "17:30"), "Comme dit au tel : 19h30 au Levant"),
    ("me", t(12, "17:33"), "Oui"),
    ("lucas", t(12, "21:38"), "T'es parti où ?"),
    ("me", t(12, "21:39"), "Truc à régler. Je t'explique demain."),
    ("lucas", t(12, "22:09"), "Je conduis, je te rappelle", dict(id="m_lucas_2209")),
    ("lucas", t(13, "09:14"), "Mec la police m'a appelé. T'es où ???", dict(unread=True)),
])

# --- Sarah (ex) — threatening message is a false lead
conv("c_sarah", ["sarah"], [
    ("sarah", t(19, "20:02", 8), "Tu as toujours mon livre sur Vivian Maier ?"),
    ("me", t(19, "20:30", 8), "Oui, je te le rends samedi"),
    ("sarah", t(19, "20:31", 8), "Pas de stress"),
    ("sarah", t(27, "13:15", 8), "Tu peux me renvoyer les photos de l'anniv de Jade de l'an dernier ?"),
    ("me", t(27, "13:40", 8), "Je cherche"),
    ("sarah", t(27, "13:41", 8), "Ne dis rien à mes parents surtout, c'est à lui de le faire"),
    ("me", t(27, "13:45", 8), "Promis"),
    ("sarah", t(3, "08:55"), "Merci pour le livre ❤️"),
    ("sarah", t(7, "22:03"), "Je sais ce que tu as fait.", dict(id="m_sarah_0907")),
    ("me", t(7, "22:10"), "Sarah…"),
    ("sarah", t(7, "22:11"), "Ne m'appelle pas."),
    ("sarah", t(11, "21:14"), "Il faut vraiment qu'on parle."),
    ("me", t(11, "21:30"), "Demain au Levant ?"),
    ("sarah", t(11, "21:31"), "Ok"),
    ("sarah", t(12, "18:32"), "Tu viens ce soir ?"),
    ("me", t(12, "18:40"), "Oui mais je pars tôt"),
    ("sarah", t(12, "21:06"), "Je file à l'anniv de Jade, on finit la discussion demain"),
    ("sarah", t(12, "23:05"), "T'es rentré ?", dict(unread=True)),
], draft=dict(id="d_sarah", text="S'il m'arrive un truc, c'est à cause de", at=t(12, "22:26")))

# --- Karim (debt) — motive, but solid alibi
conv("c_karim", ["karim"], [
    ("karim", t(15, "12:20", 8), "Bien arrivé ?"),
    ("me", t(15, "13:01", 8), "Oui merci pour le trajet"),
    ("karim", t(1, "18:47"), "Tu me dois toujours 1 200 €. Ça fait 4 mois."),
    ("me", t(1, "19:30"), "Je sais. Fin du mois, promis."),
    ("karim", t(1, "19:31"), "Tu disais pareil en juin."),
    ("karim", t(10, "23:12"), "Samedi dernier délai. Sinon je passe chez toi.", dict(id="m_karim_0910")),
    ("me", t(10, "23:40"), "Ok ok. Samedi je te fais un virement."),
    ("me", t(12, "20:31"), "Virement de 600 fait. Le reste fin septembre."),
    ("karim", t(12, "20:44"), "C'est pas ce qu'on avait dit."),
    ("karim", t(12, "22:48"), "Je suis de nuit à l'hôtel. On en reparle demain.", dict(photo="p_karim_desk")),
    ("karim", t(13, "08:40"), "Alex réponds. Laisse tomber pour l'argent, sérieux. T'es où ?", dict(unread=True)),
])

# --- Group "Les Levantins"
G = ["sarah", "karim", "lucas", "emma", "ines", "tom"]
conv("c_group", G, [
    ("ines", t(21, "18:02", 8), "Qui est chaud pour le Levant samedi ?"),
    ("tom", t(21, "18:05", 8), "Moi !"),
    ("lucas", t(21, "18:10", 8), "Présent"),
    ("emma", t(21, "18:30", 8), "Ok pour moi"),
    ("karim", t(21, "19:02", 8), "Je bosse à 21h mais je passe avant"),
    ("me", t(21, "19:20", 8), "Go"),
    ("sarah", t(22, "23:51", 8), "Merci pour la soirée les gens 🫶"),
    ("tom", t(24, "09:12", 8), "Quelqu'un a retrouvé une écharpe verte ?"),
    ("ines", t(24, "09:30", 8), "C'est la mienne 🙈"),
    ("lucas", t(29, "20:02", 8), "Qui veut des places pour le match le 20 ?"),
    ("karim", t(29, "20:15", 8), "Moi si c'est pas trop cher"),
    ("lucas", t(29, "20:16", 8), "18 balles"),
    ("karim", t(29, "20:17", 8), "Ok"),
    ("emma", t(2, "12:02"), "Rappel : vernissage Lumen samedi 5, 19h, venez nombreux !"),
    ("ines", t(2, "12:10"), "J'y serai"),
    ("tom", t(2, "12:30"), "Moi aussi"),
    ("sarah", t(2, "13:05"), "Je passerai plus tard"),
    ("karim", t(5, "22:41"), "Bravo pour l'expo, vraiment"),
    ("emma", t(5, "22:50"), "Merci ❤️"),
    ("ines", t(6, "11:02"), "J'ai des photos du vernissage, je vous les envoie"),
    ("tom", t(8, "19:40"), "Bloc jeudi 19h ?"),
    ("me", t(8, "19:52"), "Ok"),
    ("ines", t(10, "13:03"), "Quelqu'un a un chargeur USB-C à prêter demain ?"),
    ("lucas", t(10, "13:10"), "Moi"),
    ("lucas", t(11, "18:30"), "Levant demain 19h30 ?"),
    ("tom", t(11, "18:33"), "Yes"),
    ("sarah", t(11, "18:40"), "Je passe mais je pars tôt, anniv de Jade"),
    ("ines", t(11, "18:41"), "Ok !"),
    ("emma", t(11, "19:02"), "Je sais pas encore"),
    ("karim", t(12, "18:50"), "Je passe vite fait avant le boulot"),
    ("emma", t(12, "19:58"), "Je vais pas venir, migraine 🤕 amusez-vous", dict(id="m_group_emma_1958")),
    ("ines", t(12, "19:59"), "Repose-toi !"),
    ("tom", t(12, "19:30"), "On est en terrasse au fond"),
    ("sarah", t(12, "22:21"), "L'anniv de Jade 🎈", dict(photo="p_sarah_jade")),
    ("ines", t(12, "22:22"), "Trop mignon"),
    ("emma", t(12, "22:34"), "Désolée pour ce soir, je suis au lit depuis 20h 😴", dict(id="m_group_emma_2234")),
    ("lucas", t(12, "23:40"), "Rentré direct après le Levant, au lit à 22h 😴 bonne nuit", dict(id="m_group_lucas_2340")),
    ("ines", t(13, "09:02"), "Quelqu'un a des nouvelles d'Alex ? Sa mère m'a appelée", dict(unread=True)),
    ("tom", t(13, "09:05"), "Non… il est parti tôt hier", dict(unread=True)),
], title="Les Levantins")

conv("c_maman", ["maman"], [
    ("maman", t(24, "19:03", 8), "Tu as pensé à appeler ta grand-mère ?"),
    ("me", t(24, "20:10", 8), "Oui ce midi"),
    ("maman", t(31, "08:20", 8), "Bonne rentrée mon chéri"),
    ("me", t(31, "08:50", 8), "Merci maman"),
    ("maman", t(6, "17:44"), "Tu as l'air fatigué ces temps-ci"),
    ("me", t(6, "18:02"), "Beaucoup de boulot, ça va"),
    ("maman", t(10, "12:15"), "Mercredi c'est le 16 ! Tu passes à la maison ?"),
    ("me", t(10, "12:40"), "Oui, vers 19h"),
    ("maman", t(10, "12:41"), "Super. 27 ans déjà…"),
    ("maman", t(13, "08:31"), "Alex rappelle-moi s'il te plaît", dict(unread=True)),
    ("maman", t(13, "09:31"), "Je suis très inquiète", dict(unread=True)),
])

conv("c_elodie", ["elodie"], [
    ("elodie", t(2, "09:02"), "Tu as la dernière version de la maquette Varenne ?"),
    ("me", t(2, "09:10"), "Je te l'envoie"),
    ("elodie", t(4, "17:40"), "Varenne valide la maquette 🎉"),
    ("me", t(4, "17:45"), "Enfin !"),
    ("elodie", t(9, "10:22"), "Réunion déplacée à lundi 9h30, ça te va ?"),
    ("me", t(9, "10:30"), "Impossible lundi 9h, j'ai le bureau de l'asso. 11h ?"),
    ("elodie", t(9, "10:31"), "Ok 11h"),
    ("elodie", t(11, "18:12"), "Bon week-end !"),
    ("me", t(11, "18:20"), "Toi aussi"),
])

conv("c_tom", ["tom"], [
    ("tom", t(18, "18:00", 8), "Salle ce soir ?"),
    ("me", t(18, "18:10", 8), "Go 19h"),
    ("tom", t(25, "21:05", 8), "Ta voie jaune tu l'as enfin passée ?"),
    ("me", t(25, "21:20", 8), "Presque 😅"),
    ("tom", t(3, "08:12"), "Tu me rends la perceuse quand tu peux"),
    ("me", t(3, "08:40"), "Ce week-end promis"),
    ("tom", t(10, "22:02"), "Bloc super ce soir, à refaire"),
])

conv("c_ines", ["ines"], [
    ("ines", t(6, "11:05"), "Tiens, les photos du vernissage", dict(photo="p_vernissage")),
    ("me", t(6, "11:30"), "Merci ! Elles sont top"),
    ("ines", t(9, "20:40"), "Tu as l'air soucieux en ce moment, tout va bien ?"),
    ("me", t(9, "21:02"), "Une histoire avec l'asso. Je t'en parlerai"),
])

conv("c_hugo", ["hugo"], [
    ("hugo", t(27, "19:05", 8), "Je pars à Lyon en octobre. Dis rien à Sarah ni aux parents, je leur annonce moi-même."),
    ("me", t(27, "19:12", 8), "Promis."),
    ("hugo", t(6, "16:20"), "J'ai dit à Sarah que tu étais au courant pour Lyon… désolé"),
    ("me", t(6, "16:45"), "Pas grave. Elle va m'en vouloir"),
    ("hugo", t(6, "16:46"), "Elle t'en veut déjà 😬"),
])

conv("c_banque", ["banque"], [
    ("banque", t(28, "10:00", 8), "Banque Azur : votre carte a été utilisée pour un paiement de 42,90 € chez LIBRAIRIE DU PORT."),
    ("banque", t(12, "20:30"), "Banque Azur : virement de 600,00 € vers K. HADDAD effectué."),
])

conv("c_colis", ["colis"], [
    ("colis", t(4, "08:02"), "Colis Express : votre colis n°CX4821 sera livré aujourd'hui entre 12h et 14h."),
    ("colis", t(4, "13:20"), "Colis Express : votre colis a été livré dans votre boîte aux lettres."),
])

# ---------------------------------------------------------------- calls
calls = []
def call(cid, contact, direction, at, dur):
    calls.append(dict(id=cid, contact=contact, direction=direction, at=at, durationSeconds=dur))
call("k01", "maman", "incoming", t(24, "18:40", 8), 912)
call("k02", "lucas", "outgoing", t(28, "19:05", 8), 124)
call("k03", "elodie", "incoming", t(1, "09:30"), 302)
call("k04", "karim", "missed", t(1, "18:45"), 0)
call("k05", "tom", "outgoing", t(3, "18:02"), 45)
call("k06", "emma", "outgoing", t(5, "17:20"), 188)
call("k07", "maman", "outgoing", t(6, "18:10"), 1420)
call("k08", "sarah", "outgoing", t(7, "22:30"), 0)
call("k09", "hugo", "incoming", t(8, "12:02"), 214)
call("k10", "emma", "incoming", t(9, "19:40"), 0)
call("k11", "karim", "missed", t(10, "23:05"), 0)
call("k12", "emma", "incoming", t(11, "20:05"), 252)
call("k13", "elodie", "outgoing", t(11, "17:30"), 96)
call("k14", "lucas", "incoming", t(12, "17:20"), 71)
call("k15", "emma", "incoming", t(12, "21:34"), 52)
call("k16", "lucas", "outgoing", t(12, "22:08"), 0)
call("k17", "karim", "missed", t(12, "22:52"), 0)
call("k18", "sarah", "missed", t(12, "23:07"), 0)
call("k19", "maman", "missed", t(13, "08:29"), 0)
call("k20", "lucas", "missed", t(13, "09:15"), 0)
call("k21", "maman", "missed", t(13, "09:30"), 0)
call("k22", "ines", "missed", t(13, "09:40"), 0)
# fix k10: a 0-second incoming call is a missed one
calls[9]["direction"] = "missed"

# ---------------------------------------------------------------- places & tracks
places = [
    dict(id="pl_home_alex", name="Domicile d'Alex — rue Vauban", kind="home", x=0.36, y=0.46),
    dict(id="pl_levant", name="Le Levant (bar)", kind="bar", x=0.47, y=0.38),
    dict(id="pl_home_emma", name="Rue Paradis", kind="street", x=0.60, y=0.27),
    dict(id="pl_home_lucas", name="Avenue des Chênes", kind="home", x=0.18, y=0.24),
    dict(id="pl_quai9", name="Parking du Quai 9 — zone portuaire", kind="parking", x=0.84, y=0.80),
    dict(id="pl_rocade", name="Rocade Nord — sortie 4", kind="road", x=0.46, y=0.60),
    dict(id="pl_lilas", name="Rue des Lilas", kind="street", x=0.14, y=0.72),
    dict(id="pl_hotel", name="Hôtel Le Cygne", kind="work", x=0.72, y=0.16),
    dict(id="pl_varenne", name="Agence Varenne", kind="work", x=0.24, y=0.56),
    dict(id="pl_bloc", name="Salle d'escalade Bloc Out", kind="park", x=0.26, y=0.88),
    dict(id="pl_gare", name="Gare centrale", kind="station", x=0.58, y=0.52),
    dict(id="pl_local", name="Local du collectif Lumen", kind="shop", x=0.52, y=0.72),
]
# Real coordinates (the phone's map is a real city). A place with `revealedBy` stays off the map
# until the player has come across it elsewhere (a photo, an event, a search, a location history).
COORDS = {'pl_home_alex': (43.2855, 5.3795, None), 'pl_levant': (43.294, 5.3833, None), 'pl_home_emma': (43.289, 5.3785, ['photoInfo:p_invoice', 'photoInfo:p_emma_couch', 'track:t_emma']), 'pl_home_lucas': (43.3, 5.401, None), 'pl_quai9': (43.317, 5.362, ['calendar:c_quai9', 'browser:w15', 'message:m_emma_del1', 'photo:p_parking']), 'pl_rocade': (43.328, 5.405, ['track:t_lucas']), 'pl_lilas': (43.277, 5.4, ['photoInfo:p_sarah_jade', 'track:t_sarah']), 'pl_hotel': (43.295, 5.373, ['photoInfo:p_karim_desk', 'track:t_karim']), 'pl_varenne': (43.299, 5.38, None), 'pl_bloc': (43.28, 5.415, None), 'pl_gare': (43.303, 5.3805, None), 'pl_local': (43.2975, 5.39, None)}
for pl in places:
    lat, lon, revealed = COORDS[pl["id"]]
    pl["latitude"], pl["longitude"] = lat, lon
    if revealed:
        pl["revealedBy"] = revealed
tracks = [
    dict(id="t_me", contact="me", points=[
        dict(id="tp_me_1", at=t(11, "08:52"), place="pl_varenne"),
        dict(id="tp_me_2", at=t(11, "18:41"), place="pl_bloc"),
        dict(id="tp_me_3", at=t(11, "21:12"), place="pl_home_alex"),
        dict(id="tp_me_4", at=t(12, "14:05"), place="pl_local"),
        dict(id="tp_me_5", at=t(12, "18:50"), place="pl_home_alex"),
        dict(id="tp_me_6", at=t(12, "19:34"), place="pl_levant"),
        dict(id="tp_me_7", at=t(12, "21:36"), place="pl_levant", note="Départ"),
        dict(id="tp_me_8", at=t(12, "21:49"), place="pl_gare"),
        dict(id="tp_me_9", at=t(12, "22:02"), place="pl_quai9"),
        dict(id="tp_me_10", at=t(12, "22:36"), place="pl_quai9", note="Dernière position connue — localisation interrompue"),
    ]),
    dict(id="t_lucas", contact="lucas", points=[
        dict(id="tp_lu_1", at=t(12, "18:40"), place="pl_home_lucas"),
        dict(id="tp_lu_2", at=t(12, "19:28"), place="pl_levant"),
        dict(id="tp_lu_3", at=t(12, "21:52"), place="pl_levant", note="Départ"),
        dict(id="tp_lu_4", at=t(12, "21:58"), place="pl_home_emma", note="Arrêt 3 min"),
        dict(id="tp_lu_5", at=t(12, "22:17"), place="pl_quai9"),
        dict(id="tp_lu_6", at=t(12, "22:24"), place="pl_rocade"),
        dict(id="tp_lu_7", at=t(12, "22:41"), place="pl_home_lucas"),
    ]),
    dict(id="t_sarah", contact="sarah", points=[
        dict(id="tp_sa_1", at=t(12, "19:31"), place="pl_levant"),
        dict(id="tp_sa_2", at=t(12, "21:08"), place="pl_levant", note="Départ"),
        dict(id="tp_sa_3", at=t(12, "21:29"), place="pl_lilas"),
        dict(id="tp_sa_4", at=t(12, "23:52"), place="pl_lilas"),
    ]),
    dict(id="t_karim", contact="karim", points=[
        dict(id="tp_ka_1", at=t(12, "19:40"), place="pl_levant"),
        dict(id="tp_ka_2", at=t(12, "20:48"), place="pl_hotel"),
        dict(id="tp_ka_3", at=t(12, "23:59"), place="pl_hotel"),
        dict(id="tp_ka_4", at=t(13, "07:05"), place="pl_hotel"),
    ]),
    dict(id="t_ines", contact="ines", points=[
        dict(id="tp_in_1", at=t(12, "19:35"), place="pl_levant"),
        dict(id="tp_in_2", at=t(12, "23:10"), place="pl_levant"),
    ]),
    dict(id="t_emma", contact="emma", points=[
        dict(id="tp_em_1", at=t(12, "18:05"), place="pl_home_emma"),
        dict(id="tp_em_2", at=t(12, "19:40"), place="pl_home_emma"),
    ], sharingStoppedAt=t(12, "21:31")),
]

# ---------------------------------------------------------------- photos
photos = []
def photo(pid, taken, scene, caption, details, source="camera", place=None, frm=None, received=None, device="iPhone 13",
          style=None, lines=None):
    p = dict(id=pid, takenAt=taken, source=source, scene=scene, caption=caption, details=details)
    if style: p["style"] = style
    if lines: p["lines"] = lines
    if place: p["place"] = place
    if frm: p["from"] = frm
    if received: p["receivedAt"] = received
    if device: p["device"] = device
    photos.append(p)

banal = [
    ("p_b01", t(17, "19:58", 8), "sunset", "Coucher de soleil sur le port.", "Des grues au loin, un ferry à quai. Rien de particulier.", "Quai des Arts"),
    ("p_b02", t(18, "20:31", 8), "climbing", "Tom dans une voie jaune.", "La salle est presque vide. Tom porte un t-shirt rouge.", "Salle d'escalade Bloc Out"),
    ("p_b03", t(19, "08:15", 8), "rain", "Pluie sur la fenêtre du bureau.", "Des gouttes sur la vitre, la rue floue derrière.", "Agence Varenne"),
    ("p_b04", t(20, "13:02", 8), "street_day", "Une rue du centre, en plein soleil.", "Des passants, une vitrine de disquaire.", None),
    ("p_b05", t(21, "22:10", 8), "concert", "Concert au parc — lumières violettes.", "La scène est loin, la photo est floue.", "Parc des Tilleuls"),
    ("p_b06", t(22, "23:15", 8), "bar", "Le Levant, terrasse du fond.", "Des verres sur la table, Inès rit.", "Le Levant"),
    ("p_b07", t(24, "17:40", 8), "cat", "Le chat de la voisine sur le palier.", "Un chat roux qui dort sur le paillasson.", "Domicile"),
    ("p_b08", t(25, "12:12", 8), "screenshot", "Capture : horaires de la salle d'escalade.", "Lun–Ven 10h–23h, Sam–Dim 9h–21h.", None),
    ("p_b09", t(26, "18:44", 8), "books", "Étagère de livres photo.", "Vivian Maier, Saul Leiter, Martin Parr…", "Domicile"),
    ("p_b10", t(28, "09:30", 8), "sky", "Ciel très bleu, une traînée d'avion.", "Rien d'autre.", None),
    ("p_b12", t(30, "15:20", 8), "interior_warm", "Le canapé de Lucas, enfin monté.", "Lucas fait un pouce levé au fond. Des cartons partout.", "Avenue des Chênes"),
    ("p_b13", t(1, "08:47"), "station", "Gare centrale, le matin.", "Le panneau affiche un retard de 10 minutes.", "Gare centrale"),
    ("p_b14", t(2, "19:05"), "laptop", "Maquette Varenne à l'écran.", "Une affiche bleue et orange sur l'écran.", "Agence Varenne"),
    ("p_b15", t(3, "21:40"), "street_night", "La rue Vauban sous les réverbères.", "Une rue calme, une voiture garée.", "Domicile"),
    ("p_b16", t(4, "13:25"), "document", "Colis reçu : une nouvelle optique 35 mm.", "La boîte est ouverte sur le bureau.", "Domicile"),
    ("p_b17", t(5, "18:40"), "gallery", "Montage de l'expo Lumen au local.", "Les cadres en bois clair sont posés contre le mur.", "Local du collectif Lumen"),
    ("p_b19", t(5, "22:15"), "gallery", "Des visiteurs devant les tirages.", "Une dizaine de personnes, lumière chaude.", "Local du collectif Lumen"),
    ("p_b20", t(6, "12:30"), "park", "Balade au parc le lendemain.", "Des feuilles qui commencent à jaunir.", None),
    ("p_b21", t(7, "08:05"), "screenshot", "Capture : météo de la semaine.", "Soleil jusqu'à samedi, orages dimanche.", None),
    ("p_b22", t(8, "19:10"), "climbing", "Mur de bloc, voie bleue.", "Des traces de magnésie sur les prises.", "Salle d'escalade Bloc Out"),
    ("p_b23", t(9, "07:55"), "sky", "Lever de soleil depuis la fenêtre.", "Rose et orange au-dessus des toits.", "Domicile"),
    ("p_b24", t(10, "12:44"), "street_day", "Travaux devant l'agence.", "Une pelleteuse bloque le trottoir.", "Agence Varenne"),
    ("p_b25", t(10, "21:30"), "plant", "Le pothos du salon a doublé de taille.", "Une plante verte près de la fenêtre.", "Domicile"),
    ("p_b26", t(11, "18:55"), "climbing", "Tom en haut du mur.", "Photo prise d'en bas, contre-jour.", "Salle d'escalade Bloc Out"),
    ("p_b27", t(12, "14:10"), "gallery", "Le local Lumen, rangé après l'expo.", "Les cartons d'archives de l'asso sont empilés dans un coin.", "Local du collectif Lumen"),
    ("p_b28", t(12, "20:02"), "bar", "Le Levant, verres sur la table.", "Lucas, en sweat noir, regarde son téléphone. Sarah parle avec Inès.", "Le Levant"),
    ("p_b29", t(12, "21:05"), "bar", "Tom montre une vidéo à Lucas.", "Photo floue, prise de travers.", "Le Levant"),
    ("p_b30", t(12, "21:52"), "street_night", "Arrêt de bus, ligne 12.", "L'écran annonce le prochain bus dans 4 minutes, direction « Port ».", "Gare centrale"),
]
for pid, taken, scene, cap, det, place in banal:
    photo(pid, taken, scene, cap, det, place=place)

# What can be read on the screenshots.
LINES = {
    "p_b08": ["BLOC OUT", "Horaires", "Lun – Ven   10:00 – 23:00", "Sam – Dim   09:00 – 21:00", "Fermé les jours fériés"],
    "p_b21": ["Météo — Marseille", "Lun  ☀  27°", "Mar  ☀  28°", "Mer  ☀  26°", "Sam  ⛅  24°", "Dim  ⛈  19°"],
}
for p in photos:
    if p["id"] in LINES:
        p["lines"] = LINES[p["id"]]

# A real camera roll: years of photos, selfies, blurred shots, pockets, receipts, screenshots.
def at(year, month, day, hm):
    return f"{year}-{month:02d}-{day:02d} {hm}"

noise = [
    ("p_old01", at(2019, 7, 14, "22:41"), "sky", "Feu d'artifice du 14 juillet, 2019.", "Des traînées floues au-dessus du port.", "Vieux-Port", "old", None),
    ("p_old02", at(2020, 4, 2, "16:10"), "interior_warm", "Confinement : le salon de l'ancien appartement.", "Des cartons, une guitare contre le mur.", None, "old", None),
    ("p_old03", at(2021, 8, 9, "11:25"), "beach", "Plage des Catalans, août 2021.", "Des serviettes, un parasol rayé.", "Plage des Catalans", "old", None),
    ("p_old04", at(2022, 12, 24, "20:05"), "interior_warm", "Réveillon chez Maman.", "Une table dressée, des bougies.", None, "old", None),
    ("p_old05", at(2023, 2, 11, "09:40"), "snow", "Neige à la montagne, février 2023.", "Des sapins blancs, un télésiège au loin.", None, "old", None),
    ("p_old06", at(2024, 6, 21, "23:12"), "concert", "Fête de la musique 2024.", "Une foule, des lumières rouges.", None, "old", None),
    ("p_old07", at(2024, 10, 3, "18:30"), "group", "Premier accrochage du collectif Lumen.", "Quatre silhouettes devant un mur blanc.", "Local du collectif Lumen", "old", None),
    ("p_self01", t(19, "08:02", 8), "mirror", "Selfie dans le miroir de l'ascenseur.", "Alex, un café à la main, l'air pas réveillé.", "Agence Varenne", "selfie", None),
    ("p_self02", t(29, "17:48", 8), "beach", "Selfie à la plage avec Lucas.", "Deux silhouettes à contre-jour, cheveux mouillés.", "Plage des Catalans", "selfie", None),
    ("p_self03", t(6, "13:15"), "selfie", "Selfie après le vernissage, cernes comprises.", "Le visage est flou, l'arrière-plan net.", "Domicile", "selfie", None),
    ("p_blur01", t(22, "23:58", 8), "pocket", "Photo prise dans une poche.", "Tout est noir avec une lueur orange.", None, "blurry", None),
    ("p_blur02", t(31, "07:12", 8), "ceiling", "Le plafond de la chambre.", "Photo prise par erreur au réveil.", "Domicile", "blurry", None),
    ("p_blur03", t(12, "21:22"), "bar", "Le Levant, photo ratée.", "Un bras, une lampe, des reflets. Rien d'utile.", "Le Levant", "blurry", None),
    ("p_quick01", t(27, "12:05", 8), "street_day", "Une affiche de concert, prise en passant.", "« Nuits du Port — 18 septembre ».", None, "quick", None),
    ("p_quick02", t(9, "13:02"), "car", "Une voiture mal garée devant l'agence.", "Une berline noire sur le trottoir.", "Agence Varenne", "quick", None),
    ("p_night01", t(4, "23:40"), "street_night", "La rue en bas, depuis la fenêtre.", "Un scooter passe, trois réverbères.", "Domicile", "night", None),
    ("p_night02", t(11, "22:15"), "view", "La ville depuis le toit de l'immeuble.", "Des lumières jusqu'à la mer.", "Domicile", "night", None),
    ("p_doc01", t(3, "12:40"), "receipt", "Ticket de caisse — supérette.", "Pâtes, café, lessive. 23,40 €.", None, "document",
     ["PROXI MARCHÉ", "03/09/2026  12:38", "PÂTES 500G      1,20", "CAFÉ MOULU      4,90", "LESSIVE        11,30", "PAIN            1,10", "TOTAL          23,40 €"]),
    ("p_doc02", t(28, "10:20", 8), "document", "Attestation d'assurance habitation.", "Pour le propriétaire.", "Domicile", "document",
     ["ATTESTATION D'ASSURANCE", "Habitation — Formule Essentielle", "Assuré : M. Alex Moreau", "Adresse : rue Vauban, Marseille", "Valable du 01/09/2026 au 31/08/2027"]),
    ("p_scr01", t(24, "22:30", 8), "screenshot", "Capture : un mème envoyé par Tom.", "Un chat en baudrier. « Moi au premier dévers ».", None, "screenshot",
     ["Tom Delorme", "Moi au premier dévers 😭", "Réaction : 😂 3"]),
    ("p_scr02", t(2, "08:14"), "screenshot", "Capture : itinéraire vers l'agence.", "18 min en vélo.", None, "screenshot",
     ["Itinéraires", "Domicile → Agence Varenne", "🚲  18 min · 4,2 km", "🚶  52 min", "🚌  24 min · ligne 12"]),
    ("p_scr03", t(11, "12:31"), "screenshot", "Capture : confirmation de commande.", "Des sangles pour le pied photo.", None, "screenshot",
     ["Commande confirmée", "N° 48-22917", "Sangle trépied ×2", "Livraison : mardi 15 septembre", "Total : 18,90 €"]),
]
for pid, taken, scene, cap, det, place, style, lines in noise:
    photo(pid, taken, scene, cap, det, place=place, style=style, lines=lines,
          device="iPhone 8" if taken < "2022" else "iPhone 13")

photo("p_lucas_car", t(23, "11:43", 8), "car", "La Clio grise de Lucas, sortie du garage.",
      "Une petite citadine grise, carrosserie propre. La plaque est à moitié cachée par un vélo.",
      source="received", frm="lucas", received=t(23, "11:45", 8), place="Garage Martin", device="Pixel 7")
photo("p_vernissage", t(5, "20:12"), "group", "Vernissage Lumen : Emma, Inès et Alex devant les tirages.",
      "Emma porte une veste en jean clair, délavée. Alex tient une coupe. Au fond, les 14 tirages encadrés.",
      source="received", frm="ines", received=t(6, "11:05"), place="Local du collectif Lumen", device="iPhone 12")
photo("p_invoice", t(9, "18:20"), "document", "Photo d'une facture « Studio Nova » n°114.",
      "Facture de 1 650 € pour « prestations de tirage ». Signature « E.R. — trésorière ». L'adresse de Studio Nova est rue Paradis.",
      place="Domicile", style="document",
      lines=["STUDIO NOVA", "FACTURE N° 114", "Prestations de tirage", "Total TTC  1 650,00 €"])
photo("p_bar_selfie", t(12, "20:12"), "group", "Selfie au Levant : Alex, Lucas, Sarah, Karim, Inès, Tom.",
      "Tout le monde sourit. Karim a déjà sa veste de travail sur le bras. Emma n'est pas là.",
      place="Le Levant", style="selfie")
photo("p_emma_couch", t(12, "19:42"), "bed", "Emma sous la couette, une tasse fumante, la télé allumée.",
      "Par la fenêtre derrière le lit, le ciel est encore clair : il fait jour dehors. L'horloge du décodeur, en bas de la télé, est illisible.",
      source="received", frm="emma", received=t(12, "22:30"), place="Rue Paradis", device="iPhone 14")
photo("p_parking", t(12, "22:18"), "parking_night", "Le parking du Quai 9, de nuit.",
      "Au fond, les feux arrière d'une petite citadine grise qui repart. Près de la barrière, une silhouette dans une veste claire.",
      place="Parking du Quai 9", style="night")
photo("p_sarah_jade", t(12, "22:19"), "party", "L'anniversaire de Jade : ballons et guirlandes.",
      "Sarah est au premier plan avec sa sœur Jade. Guirlandes lumineuses, une vingtaine d'invités.",
      source="received", frm="sarah", received=t(12, "22:21"), place="Rue des Lilas", device="iPhone 15")
photo("p_karim_desk", t(12, "22:47"), "desk_night", "Le comptoir d'accueil de l'hôtel, de nuit.",
      "Un écran de réservation, une sonnette, le logo « Le Cygne » sur le mur. L'horloge murale indique 22:47.",
      source="received", frm="karim", received=t(12, "22:48"), place="Hôtel Le Cygne", device="Galaxy S22")

# ---------------------------------------------------------------- calendar
calendar = [
    dict(id="c_ev01", start=t(21, "19:00", 8), title="Bloc avec Tom", location="Bloc Out"),
    dict(id="c_ev02", start=t(30, "14:00", 8), title="Canapé Lucas", location="Avenue des Chênes"),
    dict(id="c_ev03", start=t(2, "10:00"), end=t(2, "11:00"), title="Point Varenne", location="Agence"),
    dict(id="c_ev04", start=t(5, "19:00"), title="Vernissage Lumen", location="Local du collectif", notes="Apporter l'enceinte."),
    dict(id="c_ev05", start=t(8, "09:30"), title="Dentiste — Dr Lefèvre", location="12 rue Garibaldi"),
    dict(id="c_ev06", start=t(10, "19:00"), title="Bloc", location="Bloc Out"),
    dict(id="c_ev07", start=t(12, "19:30"), title="Le Levant", location="Le Levant"),
    dict(id="c_quai9", start=t(12, "22:00"), end=t(12, "22:30"), title="P. Quai 9 — E.", location="Quai 9",
         notes="Créé le 12 sept. à 21:44"),
    dict(id="c_ev09", start=t(14, "09:00"), end=t(14, "10:30"), title="Bureau Lumen — comptes", location="Local du collectif",
         notes="Ordre du jour : bilan de l'expo, comptes 2026, factures fournisseurs."),
    dict(id="c_ev10", start=t(14, "11:00"), title="Réunion Varenne (Élodie)", location="Agence"),
    dict(id="c_ev11", start=t(16, "00:00"), title="🎂 Mon anniversaire", allDay=True),
    dict(id="c_ev12", start=t(16, "19:00"), title="Chez maman", location="Maison"),
    dict(id="c_ev13", start=t(20, "21:00"), title="Match avec Lucas & Karim", location="Stade"),
]

# ---------------------------------------------------------------- notes (locked: code = birthday 1609)
notes = [
    dict(id="n_lumen", title="Lumen — comptes", createdAt=t(9, "23:10"), modifiedAt=t(12, "17:02"),
         body="Factures « Studio Nova » : n°112, 114, 117.\nTotal : 4 300 €.\nToutes validées par la trésorière.\n"
              "Studio Nova = même adresse que… rue Paradis ?? Vérifier.\n\n→ Lui en parler AVANT lundi.\n"
              "→ Bureau lundi 9h : tout mettre sur la table."),
    dict(id="n_k", title="Ne jamais faire confiance à K.", createdAt=t(14, "01:20", 3), modifiedAt=t(14, "01:20", 3),
         body="Ne jamais faire confiance à K."),
    dict(id="n_todo", title="À faire", createdAt=t(1, "08:10"), modifiedAt=t(12, "20:33"),
         body="- Rendre la perceuse à Tom\n- Payer le loyer\n- Rembourser Karim (reste 600)\n- Appeler mamie\n- Renouveler l'abonnement escalade"),
    dict(id="n_expo", title="Idées expo printemps", createdAt=t(18, "22:40", 8), modifiedAt=t(6, "10:50"),
         body="Thème : « Les gens de la nuit ». Portraits au flash, chauffeurs de bus, gardiens, soignants.\nDemander à Karim pour l'hôtel ?"),
    dict(id="n_wifi", title="Wi-Fi local", createdAt=t(2, "12:00", 6), modifiedAt=t(2, "12:00", 6),
         body="Réseau : LUMEN-LOCAL\nMot de passe : argentique2024"),
    dict(id="n_lisbonne", title="Lisbonne ?", createdAt=t(12, "22:15", 7), modifiedAt=t(20, "09:00", 8),
         body="Octobre ? Vols ~120 €. Voir avec Lucas et Tom."),
]

# ---------------------------------------------------------------- mail
mails = [
    dict(id="mail_comptable", folder="inbox", fromName="Cabinet Ferran", fromAddress="contact@cabinet-ferran.fr",
         to="alex.moreau@mailo.fr", at=t(9, "17:48"), subject="Collectif Lumen — anomalies sur les comptes 2026",
         body="Bonjour Monsieur Moreau,\n\nEn préparant le bilan du collectif, nous avons relevé trois factures du fournisseur « Studio Nova » "
              "(n°112, 114 et 117) pour un total de 4 300 €, sans bon de commande ni justificatif de prestation.\n\n"
              "Ces factures ont été validées par la trésorière, Mme E. Roussel. Le SIRET indiqué ne correspond à aucune entreprise enregistrée.\n\n"
              "En tant que président, nous vous invitons à clarifier la situation avant la réunion du bureau.\n\nCopies des factures en pièce jointe.\n\nCordialement,\nP. Ferran",
         attachments=["Facture_StudioNova_112.pdf", "Facture_StudioNova_114.pdf", "Facture_StudioNova_117.pdf"]),
    dict(id="mail_reply", folder="sent", fromName="Alex Moreau", fromAddress="alex.moreau@mailo.fr", to="contact@cabinet-ferran.fr",
         at=t(9, "19:02"), subject="Re: Collectif Lumen — anomalies sur les comptes 2026",
         body="Bonjour,\n\nMerci. Je préfère d'abord en parler à la personne concernée. Je reviens vers vous après le bureau de lundi.\n\nAlex"),
    dict(id="mail_expo", folder="inbox", fromName="Emma Roussel", fromAddress="emma.roussel@mailo.fr", to="bureau@collectif-lumen.fr",
         at=t(3, "23:47"), subject="Tableau des dépenses — été",
         body="Voici le tableau des dépenses de l'été. Il manque encore quelques justificatifs, je les ajoute dès que possible.\n\nEmma",
         attachments=["Depenses_ete_2026.xlsx"]),
    dict(id="mail_bloc", folder="inbox", fromName="Bloc Out", fromAddress="news@blocout.fr", to="alex.moreau@mailo.fr",
         at=t(1, "10:00"), subject="Nouvelles voies en septembre 🧗", body="Découvrez les 24 nouvelles voies ouvertes cette semaine."),
    dict(id="mail_colis", folder="inbox", fromName="Colis Express", fromAddress="noreply@colisexpress.fr", to="alex.moreau@mailo.fr",
         at=t(3, "18:30"), subject="Votre colis CX4821 est en route", body="Livraison prévue demain."),
    dict(id="mail_banque", folder="inbox", fromName="Banque Azur", fromAddress="releves@banqueazur.fr", to="alex.moreau@mailo.fr",
         at=t(5, "07:00"), subject="Votre relevé d'août est disponible", body="Votre relevé de compte est disponible dans votre espace personnel.",
         attachments=["Releve_2026-08.pdf"]),
    dict(id="mail_mairie", folder="inbox", fromName="Mairie — Vie associative", fromAddress="asso@mairie.fr", to="bureau@collectif-lumen.fr",
         at=t(26, "09:40", 8), subject="Autorisation buvette — vernissage du 5 septembre", body="Votre demande d'autorisation de buvette temporaire est acceptée."),
    dict(id="mail_varenne", folder="inbox", fromName="Élodie Garnier", fromAddress="e.garnier@agence-varenne.fr", to="alex.moreau@mailo.fr",
         at=t(11, "16:05"), subject="Réunion lundi 11h", body="Je t'envoie l'ordre du jour ce week-end. Bon week-end !"),
    dict(id="mail_concert", folder="inbox", fromName="Billetterie Halcyon", fromAddress="tickets@halcyon.fr", to="alex.moreau@mailo.fr",
         at=t(29, "20:00", 8), subject="Vos billets", body="Merci pour votre commande. 2 billets — 4 octobre.",
         attachments=["Billets_Halcyon_4-oct.pdf"]),
]

# ---------------------------------------------------------------- browser
browser = [
    dict(id="w01", at=t(19, "22:30", 8), kind="search", text="vivian maier exposition 2026"),
    dict(id="w02", at=t(25, "07:50", 8), kind="search", text="régler dérailleur vélo"),
    dict(id="w03", at=t(28, "21:15", 8), kind="search", text="location camion déménagement dimanche"),
    dict(id="w04", at=t(29, "19:44", 8), kind="visit", text="Billetterie Halcyon — Concerts d'automne", url="halcyon.fr/automne",
         summary="Programmation d'automne : 14 concerts, du 26 septembre au 20 décembre. Tarif réduit pour les moins de 26 ans."),
    dict(id="w05", at=t(2, "13:10"), kind="search", text="rembourser dette ami sans se fâcher"),
    dict(id="w06", at=t(27, "22:02", 8), kind="search", text="objectif 35mm argentique occasion"),
    dict(id="w07", at=t(7, "22:20"), kind="search", text="comment s'excuser auprès de son ex"),
    dict(id="w08", at=t(9, "23:31"), kind="search", text="trésorière association détournement que faire"),
    dict(id="w09", at=t(9, "23:40"), kind="visit", text="Détournement de fonds dans une association : les recours",
         url="service-public.fr/associations/detournement",
         summary="Le président peut saisir le bureau, demander une expertise des comptes et porter plainte pour abus de confiance."),
    dict(id="w10", at=t(10, "08:12"), kind="search", text="siret studio nova"),
    dict(id="w11", at=t(10, "08:14"), kind="visit", text="Annuaire des entreprises — aucun résultat pour « Studio Nova »",
         url="annuaire-entreprises.fr/recherche?q=studio+nova", summary="Aucune entreprise ne correspond à cette recherche."),
    dict(id="w12", at=t(11, "12:30"), kind="search", text="météo samedi"),
    dict(id="w13", at=t(12, "18:10"), kind="search", text="le levant happy hour"),
    dict(id="w14", at=t(12, "21:42"), kind="search", text="bus nuit ligne 12 horaires"),
    dict(id="w15", at=t(12, "21:44"), kind="search", text="parking quai 9 ouvert la nuit"),
    dict(id="w16", at=t(12, "21:55"), kind="search", text="abus de confiance association peine"),
    dict(id="w17", at=t(12, "21:56"), kind="visit", text="Abus de confiance : ce que risque l'auteur",
         url="justice.fr/fiches/abus-de-confiance", summary="Jusqu'à 5 ans d'emprisonnement et 375 000 € d'amende."),
]

# ---------------------------------------------------------------- live events (phone keeps living)
def live_msg(eid, after, conv_id, frm, text, title, opens=None, mid=None):
    return dict(id=eid, afterSeconds=after, kind="message", app="messages", title=title, body=text,
                conversation=conv_id, message=dict(id=mid or ("m_" + eid), **{"from": frm}, at=t(13, "10:00"), text=text),
                opens=opens or f"message:{mid or ('m_' + eid)}")
live = [
    live_msg("lv01", 25, "c_lucas", "lucas", "Alex réponds stp, faut que je te parle d'hier soir", "Lucas Ferrand"),
    dict(id="lv02", afterSeconds=70, kind="call", app="phone", title="Appel manqué", body="Maman",
         call=dict(id="k_lv02", contact="maman", direction="missed", at=t(13, "10:01"), durationSeconds=0), opens="call:k_lv02"),
    live_msg("lv03", 120, "c_group", "ines", "La police a son téléphone ?? Quelqu'un sait où il allait après le Levant ?", "Les Levantins — Inès"),
    live_msg("lv04", 175, "c_karim", "karim", "Je te jure que j'ai rien à voir avec ça. J'étais au boulot toute la nuit.", "Karim Haddad"),
    dict(id="lv05", afterSeconds=230, kind="reminder", app="calendar", title="Demain 09:00",
         body="Bureau Lumen — comptes · Local du collectif", opens="calendar:c_ev09"),
    dict(id="lv06", afterSeconds=285, kind="deletion", app="messages", title="Les Levantins",
         body="Emma a supprimé un message", conversation="c_group", deletesMessage="m_group_emma_2234",
         opens="message:m_group_emma_2234"),
    live_msg("lv07", 340, "c_emma", "emma", "Si quelqu'un lit ces messages : Alex allait bien quand je l'ai quitté.", "Emma Roussel",
             mid="m_live_emma_quit"),
    live_msg("lv08", 400, "c_lucas", "lucas", "J'ai pas tout dit à la police. J'ai déposé quelqu'un au port hier soir. Je peux pas dire qui.",
             "Lucas Ferrand", mid="m_live_lucas_port"),
    live_msg("lv09", 450, "c_sarah", "sarah", "Mon « je sais ce que tu as fait », c'était pour Hugo et Lyon. Rien d'autre. Je m'en veux.",
             "Sarah Vasseur", mid="m_live_sarah_hugo"),
]

LEVELS = {"lv02": "important", "lv04": "important", "lv05": "important", "lv06": "important", "lv07": "urgent", "lv08": "urgent"}
for e in live:
    e["level"] = LEVELS.get(e["id"], "normal")

device = dict(
    id="dev_alex", label="Téléphone d'Alex", model="iPhone 13",
    lockedApps=[dict(app="notes", code="1609", hint="Mon anniversaire (JJMM)")],
    contacts=contacts, conversations=convs, calls=calls, places=places, tracks=tracks, photos=photos,
    calendar=calendar, notes=notes, mails=mails, browser=browser, liveEvents=live,
)

suspects = [
    dict(id="s_sarah", contact="sarah", role="Ex d'Alex", age=27, address="Rue des Lilas",
         alibi="À 22:19, Sarah photographiait l'anniversaire de sa sœur Jade, rue des Lilas — sa position partagée l'y place de 21:29 à minuit.",
         alibiEvidence="e_sarah_alibi",
         trap="« Je sais ce que tu as fait » sonnait comme une menace. C'était une histoire de famille : Alex savait avant elle que son frère partait à Lyon.",
         statement="« J'ai quitté le Levant vers 21h pour l'anniversaire de ma sœur. Je n'ai pas revu Alex. »",
         verdict="Sarah n'était pas impliquée. Son « Je sais ce que tu as fait » visait une histoire de famille : Alex savait que son frère Hugo partait à Lyon. À 22:19, elle photographiait l'anniversaire de sa sœur, rue des Lilas, à l'autre bout de la ville."),
    dict(id="s_karim", contact="karim", role="Ami — Alex lui doit 1 200 €", age=30, address="Quartier de la Gare",
         alibi="Karim était à l'accueil de l'hôtel Le Cygne de 20:48 au matin : sa position et sa photo du comptoir de 22:47 le confirment.",
         alibiEvidence="e_karim_alibi",
         trap="Une dette, des messages menaçants, une note « Ne jamais faire confiance à K. » : un mobile parfait, mais aucune occasion.",
         statement="« J'ai pris mon service à l'hôtel Le Cygne à 21h. Je n'ai pas bougé de la nuit. »",
         verdict="Karim avait un mobile — une dette de 1 200 € et des messages menaçants — mais pas l'occasion. Sa position le place à l'hôtel Le Cygne de 20:48 au matin, et sa photo du comptoir est bien prise à 22:47."),
    dict(id="s_lucas", contact="lucas", role="Meilleur ami d'Alex", age=27, address="Avenue des Chênes",
         alibi="À 22:24, Lucas roulait déjà sur la rocade Nord, et Alex écrivait encore à 22:26. Il avait seulement déposé quelqu'un au port.",
         alibiEvidence="e_draft",
         trap="Il a menti sur sa soirée et sa voiture était au port à 22:17. Mais il protégeait quelqu'un, pas lui-même.",
         statement="« Je suis rentré directement chez moi après le Levant. J'étais au lit vers 22h. »",
         verdict="Lucas a menti, mais pas pour se couvrir lui-même. Il a déposé quelqu'un au port à 22:17 puis il est reparti : à 22:24 il roulait sur la rocade Nord, et Alex était encore en train d'écrire à 22:26."),
    dict(id="s_emma", contact="emma", role="Co-fondatrice du collectif Lumen", age=28, address="Rue Paradis",
         statement="« J'avais la migraine. Je suis restée chez moi toute la soirée. »",
         verdict="Emma Roussel a menti sur toute sa soirée. Elle a donné rendez-vous à Alex au parking du Quai 9 à 22h, s'est fait conduire au port par Lucas, puis s'est fabriqué un alibi avec une photo prise à 19:42."),
]

evidence = [
    dict(id="e_rdv", title="Les messages effacés", importance="key", suspects=["s_emma"], anyOf=True,
         refs=["message:m_emma_del1", "message:m_emma_del2"],
         meaning="« Parking du Quai 9. 22h. Viens seul. » — Emma a fixé le rendez-vous, puis a demandé à Alex d'effacer la conversation."),
    dict(id="e_photo_meta", title="La photo « chez moi »", importance="key", suspects=["s_emma"],
         refs=["photoInfo:p_emma_couch", "message:m_emma_2230"],
         meaning="Envoyée à 22:30 comme preuve qu'elle était au lit, la photo a en réalité été prise à 19:42 — il faisait encore jour."),
    dict(id="e_calendar", title="Le rendez-vous du calendrier", importance="key", suspects=["s_emma"],
         refs=["calendar:c_quai9"],
         meaning="« P. Quai 9 — E. » à 22h, créé à 21:44, juste après les messages effacés. « E. », c'est Emma — pas Élodie, qu'Alex voyait lundi à 11h."),
    dict(id="e_sharing", title="Le partage de position coupé", importance="key", suspects=["s_emma"],
         refs=["track:t_emma"],
         meaning="Emma a arrêté de partager sa position à 21:31, dix minutes avant d'écrire à Alex."),
    dict(id="e_motive", title="Les factures Studio Nova", importance="key", suspects=["s_emma"], anyOf=True,
         refs=["mail:mail_comptable", "note:n_lumen", "photoInfo:p_invoice"],
         meaning="4 300 € de fausses factures validées par la trésorière, Emma. Alex allait tout révéler au bureau de lundi : c'est le mobile."),
    dict(id="e_lucas_route", title="Le détour de Lucas", importance="key", suspects=["s_lucas", "s_emma"],
         refs=["track:t_lucas"],
         meaning="Lucas s'est arrêté rue Paradis — chez Emma — à 21:58, avant d'aller au port. Il l'a conduite au rendez-vous."),
    dict(id="e_quit", title="« Quand je l'ai quitté »", importance="supporting", suspects=["s_emma"],
         refs=["message:m_live_emma_quit"],
         meaning="Emma, qui dit être restée chez elle, admet avoir vu Alex ce soir-là."),
    dict(id="e_draft", title="Le dernier message", importance="supporting", suspects=["s_lucas"],
         refs=["draft:d_sarah"],
         meaning="À 22:26, Alex écrivait encore « S'il m'arrive un truc, c'est à cause de… » : Lucas était déjà reparti (rocade Nord à 22:24)."),
    dict(id="e_parking", title="La silhouette du parking", importance="supporting", suspects=["s_emma"],
         refs=["photoInfo:p_parking"],
         meaning="Une silhouette en veste claire près de la barrière, et la Clio grise de Lucas qui repart : Emma portait sa veste en jean clair au vernissage."),
    dict(id="e_sarah_alibi", title="L'alibi de Sarah", importance="supporting", suspects=["s_sarah"], anyOf=True,
         refs=["photoInfo:p_sarah_jade", "track:t_sarah"],
         meaning="Sarah était rue des Lilas de 21:29 à minuit : photo prise à 22:19, position partagée."),
    dict(id="e_karim_alibi", title="L'alibi de Karim", importance="supporting", suspects=["s_karim"], anyOf=True,
         refs=["photoInfo:p_karim_desk", "track:t_karim"],
         meaning="Karim était à l'hôtel Le Cygne toute la nuit : position et photo cohérentes."),
    dict(id="e_lucas_confession", title="L'aveu de Lucas", importance="supporting", suspects=["s_lucas", "s_emma"],
         refs=["message:m_live_lucas_port"],
         meaning="Lucas reconnaît avoir déposé quelqu'un au port — sans dire qui."),
    dict(id="f_sarah_threat", title="« Je sais ce que tu as fait »", importance="falseLead", suspects=["s_sarah"],
         refs=["message:m_sarah_0907"],
         meaning="Une dispute de famille : Alex savait avant elle que son frère Hugo partait à Lyon."),
    dict(id="f_karim_debt", title="La dette de Karim", importance="falseLead", suspects=["s_karim"], anyOf=True,
         refs=["message:m_karim_0910", "call:k17"],
         meaning="Un vrai mobile, mais Karim n'a jamais quitté l'hôtel."),
    dict(id="f_note_k", title="« Ne jamais faire confiance à K. »", importance="falseLead", suspects=["s_karim"],
         refs=["note:n_k"],
         meaning="Une note écrite en mars, deux mois avant qu'Alex n'emprunte de l'argent à Karim. Elle n'a rien à voir avec la dette ni avec samedi."),
    dict(id="f_lucas_lie", title="Le mensonge de Lucas", importance="falseLead", suspects=["s_lucas"],
         refs=["message:m_group_lucas_2340"],
         meaning="Lucas ment sur sa soirée pour protéger Emma, qui lui a demandé de se taire."),
]

hints = [
    dict(id="h1", text="Comparez ce que chacun affirme avec les positions partagées entre 21h et 23h. Et regardez qui n'apparaît plus sur la carte.", scoreCost=0),
    dict(id="h2", text="Une photo n'est pas toujours prise au moment où elle est envoyée.", scoreCost=8),
    dict(id="h3", text="Ce qui a été effacé n'a pas forcément disparu : la corbeille garde les messages de 21:40.", scoreCost=15, unlockAtRemainingSeconds=120),
]

solution = dict(
    culprit="s_emma",
    headline="Emma Roussel a attiré Alex au Quai 9 pour le convaincre de se taire.",
    summary="Elle disait être restée au lit. Elle était au port, et elle avait tout à perdre lundi matin.",
    reveal=[
        dict(at=t(9, "17:48"), text="Le comptable signale 4 300 € de fausses factures validées par Emma", evidence="e_motive"),
        dict(at=t(12, "21:31"), text="Emma coupe le partage de sa position", evidence="e_sharing"),
        dict(at=t(12, "21:40"), text="« Parking du Quai 9. 22h. Viens seul. » — puis « efface cette conversation »", evidence="e_rdv"),
        dict(at=t(12, "21:44"), text="Alex note le rendez-vous : « P. Quai 9 — E. »", evidence="e_calendar"),
        dict(at=t(12, "21:58"), text="Lucas s'arrête rue Paradis, chez Emma, puis la dépose au port à 22:17", evidence="e_lucas_route"),
        dict(at=t(12, "22:26"), text="Alex commence à écrire : « S'il m'arrive un truc, c'est à cause de… »", evidence="e_draft"),
        dict(at=t(12, "22:30"), text="Emma envoie une photo « chez moi », prise en réalité à 19:42", evidence="e_photo_meta"),
        dict(at=t(13, "10:05"), text="« Alex allait bien quand je l'ai quitté » : elle admet l'avoir vu", evidence="e_quit"),
    ],
    story=[
        "Mercredi 9 septembre, le cabinet comptable prévient Alex : trois factures « Studio Nova », 4 300 €, validées par la trésorière du collectif Lumen. Studio Nova n'existe pas. Son adresse : la rue Paradis, chez Emma.",
        "Alex décide de lui en parler avant la réunion du bureau, lundi 9h. Emma, elle, le supplie de ne rien dire aux autres.",
        "Samedi, Emma annonce une migraine et reste loin du Levant. À 21:31, elle coupe le partage de sa position. À 21:34, elle appelle Alex, qui quitte le Levant deux minutes plus tard. À 21:40, elle précise par écrit : « Parking du Quai 9. 22h. Viens seul. » — puis demande à Alex d'effacer la conversation. Il obéit, mais note le rendez-vous : « P. Quai 9 — E. ».",
        "Sans voiture, Emma appelle Lucas. Il passe la prendre rue Paradis à 21:58 et la dépose au port à 22:17. Elle lui fait promettre de ne rien dire : il inventera être rentré directement.",
        "La discussion tourne mal. Alex, qui commençait à écrire à Sarah « S'il m'arrive un truc… », tombe du quai de chargement d'un entrepôt voisin. Emma panique et s'enfuit à pied, puis rentre en taxi. Le téléphone reste au sol.",
        "À 22:30, elle envoie à Alex une photo d'elle au lit, prise en réalité à 19:42, pour se fabriquer un alibi. À 22:34, elle confirme au groupe être « au lit depuis 20h ». Ce matin, elle a supprimé ce message.",
        "Grâce à votre enquête, Alex est retrouvé dans l'après-midi, blessé mais vivant, dans un entrepôt du Quai 9.",
    ],
)

# ---------------------------------------------------------------- opening sequence
intro = dict(shots=[
    dict(kind="title", seconds=4.5, ambience=["street", "sirens"],
         lines=[dict(text="DIMANCHE 13 SEPTEMBRE · 09:52", at=0.4),
                dict(text="Zone portuaire, Marseille.", at=1.6)]),
    dict(kind="broadcast", seconds=11, ambience=["street", "crowd", "sirens"], scene="parking_night",
         channel="INFO 24", label="09:54", location="Zone portuaire — Parking du Quai 9",
         headline="Un homme de 26 ans porté disparu", ticker="Disparition à Marseille : la police lance un appel à témoins",
         lines=[dict(text="Nous sommes devant le parking du Quai 9, où le téléphone d'Alex Moreau a été retrouvé ce matin.", at=0.6, speaker="Reporter", voiced=True),
                dict(text="Le jeune homme n'a plus donné signe de vie depuis samedi soir.", at=5.2, speaker="Reporter", voiced=True),
                dict(text="Les enquêteurs espèrent que son téléphone parlera.", at=8.4, speaker="Reporter", voiced=True)]),
    dict(kind="title", seconds=1.6, cues=[dict(sound="vibrate", at=0.9)]),
    dict(kind="phoneOnTable", seconds=6, label="SCELLÉ N°3\nTéléphone de A. Moreau",
         cues=[dict(sound="vibrate", at=2.0), dict(sound="notification", at=2.1)],
         notification=dict(app="messages", title="Maman", body="Je suis très inquiète", at=2.0),
         lines=[dict(text="Vous avez quelques minutes.", at=3.6)]),
    dict(kind="unlock", seconds=2.4),
])

case = dict(
    schemaVersion=1, id="case_001", number=1, title="LE DERNIER MESSAGE",
    tagline="Alex ne donne plus signe de vie depuis samedi soir.",
    synopsis=[
        "Samedi 12 septembre, Alex Moreau, 26 ans, quitte ses amis au bar Le Levant vers 21h30. Il n'est jamais rentré chez lui.",
        "Son téléphone a été retrouvé ce matin, au sol, dans un parking de la zone portuaire. Vous avez accès à son contenu pendant quelques minutes.",
        "Quatre personnes gravitaient autour de lui ce soir-là. Toutes n'ont pas dit la vérité.",
    ],
    objective="Identifier la personne qui a vu Alex en dernier.",
    difficulty=1, durationSeconds=480, phoneStartTime=t(13, "10:00"),
    challengeDurations={"investigator": 900, "detective": 480, "expert": 300},
    introScene=intro,
    devices=[device], suspects=suspects, evidence=evidence, hints=hints, solution=solution,
)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(case, f, ensure_ascii=False, indent=1)
n_msgs = sum(len(c["messages"]) for c in convs)
print(f"case_001: {len(convs)} conversations, {n_msgs} messages, {len(calls)} calls, {len(photos)} photos, "
      f"{len(calendar)} events, {len(notes)} notes, {len(mails)} mails, {len(browser)} web, {len(live)} live events")
