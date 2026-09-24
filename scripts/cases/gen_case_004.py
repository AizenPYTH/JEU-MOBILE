# Generates ScreenshotKit/Sources/CaseLibrary/Resources/Cases/case_004.json
# Case #004 — 90 SECONDES. Thursday 12 Nov 2026, opening gala of the « Éclats » exhibition at the
# Pavillon Mercure (Paris). The phone is Salomé Tessier's (the curator), handed over at 23:25.
# Truth: the necklace on display was already a copy since the 17:30 slot the lender (Sterne) asked
# for; the 22:14 "power cut" was a 90 s blackout cue he requested; he opened the case with his own
# key in the dark and pocketed the copy, to collect the insurance he had just raised to 4.2 M€.
import json, sys

OUT = sys.argv[1]
Y = 2026
def t(day, hm, month=11):
    return f"{Y}-{month:02d}-{day:02d} {hm}"
def o(day, hm):
    # October dates
    return t(day, hm, 10)

# ---------------------------------------------------------------- contacts
contacts = [
    dict(id="me", name="Salomé Tessier", phone="+33 6 12 48 73 05", relation="Moi", email="salome.tessier@volute.fr",
         birthday="09/05/1990", avatarHue=0.11, isOwner=True),
    dict(id="sterne", name="Adrien Sterne", phone="+33 6 07 21 94 58", relation="Prêteur — collier Aurore",
         email="a.sterne@collection-sterne.fr", avatarHue=0.09),
    dict(id="enzo", name="Enzo Barros", phone="+33 6 51 38 72 44", relation="Extra Relais Intérim (gala)", avatarHue=0.55),
    dict(id="victor", name="Victor Almeida", phone="+33 6 33 70 15 82", relation="Régisseur lumière — Pavillon Mercure",
         email="v.almeida@pavillon-mercure.fr", avatarHue=0.62),
    dict(id="iris", name="Iris Nakamura", phone="+33 6 80 44 27 19", relation="Animatrice du gala", avatarHue=0.88),
    dict(id="josiane", name="Josiane Petit", phone="+33 6 22 91 03 67", relation="Vestiaire — Pavillon Mercure", avatarHue=0.03),
    dict(id="helene", name="Hélène Dubreuil", phone="+33 6 45 12 88 30", relation="Directrice du Pavillon Mercure",
         email="h.dubreuil@pavillon-mercure.fr", avatarHue=0.40),
    dict(id="noemie", name="Noémie Castel", phone="+33 7 68 02 51 94", relation="Assistante", email="noemie.castel@volute.fr",
         avatarHue=0.33),
    dict(id="camille", name="Camille Tessier", phone="+33 6 74 39 60 12", relation="Sœur", avatarHue=0.95),
    dict(id="samir", name="Samir Bouaziz", phone="+33 6 19 57 84 26", relation="Ami", avatarHue=0.20),
    dict(id="lemaire", name="Pierre-Yves Lemaire", phone="+33 6 90 26 47 71", relation="Scénographe — atelier Bagnolet",
         email="py@lemaire-scenographie.fr", avatarHue=0.72),
    dict(id="garrel", name="Étienne Garrel", phone="+33 1 42 60 18 35", relation="Expert joaillerie (constats d'état)",
         email="e.garrel@garrel-expertise.fr", avatarHue=0.50),
    dict(id="valmont", name="Cécile Morin — Valmont Art", phone="+33 1 46 93 70 22", relation="Assureur (chargée de compte)",
         email="c.morin@valmont-art.fr", avatarHue=0.66),
    dict(id="agence", name="Relais Intérim", phone="01 44 52 18 90", relation="Agence d'intérim", avatarHue=0.15),
    dict(id="fauve", name="Maison Fauve Réceptions", phone="01 43 57 62 08", relation="Prestataire du cocktail", avatarHue=0.80),
    dict(id="arteo", name="Arteo Transports", phone="01 48 12 77 40", relation="Transport d'œuvres", avatarHue=0.25),
    dict(id="banque", name="Banque Citadine", phone="36 10", avatarHue=0.58),
]

# ---------------------------------------------------------------- messages
convs = []
def conv(cid, participants, msgs, title=None, draft=None):
    c = dict(id=cid, participants=participants, messages=[])
    if title: c["title"] = title
    for i, m in enumerate(msgs):
        frm, at, text = m[0], m[1], m[2]
        extra = dict(m[3]) if len(m) > 3 else {}
        mid = extra.pop("id", f"m_{cid[2:]}_{i:03d}")
        msg = dict(id=mid, **{"from": frm}, at=at)
        if text: msg["text"] = text
        msg.update(extra)
        c["messages"].append(msg)
    c["messages"].sort(key=lambda x: x["at"])
    if draft: c["draft"] = draft
    convs.append(c)

# --- Adrien Sterne (lender, culprit): formal, long, signs "A. S."
conv("c_sterne", ["sterne"], [
    ("sterne", o(2, "16:05"), "Chère Salomé, merci pour ce déjeuner. Votre projet pour « Éclats » m'a convaincu : l'Aurore sera des vôtres. "
                               "Mon notaire vous fera parvenir la convention de prêt dans la semaine. Bien à vous, A. S."),
    ("me", o(2, "16:40"), "Merci infiniment, Monsieur Sterne. C'est une très belle nouvelle pour l'exposition."),
    ("sterne", o(9, "18:22"), "Convention signée ce jour. Je compte sur vous pour que l'Aurore soit traitée comme une personne, "
                               "et non comme un objet. A. S."),
    ("me", o(9, "18:35"), "Elle le sera. Vitrine 4, salle 2, dans l'axe de l'entrée. Je vous envoie le plan dès qu'il est validé."),
    ("sterne", o(16, "11:03"), "Chère Salomé, mon joaillier a revu l'estimation de l'Aurore : les perles fines de cette qualité ont "
                                "pris beaucoup de valeur ces dernières années. J'ai prié Valmont d'en tenir compte. Pardonnez-moi ces formalités. A. S."),
    ("me", o(16, "11:20"), "Aucun souci, je transmets à Hélène pour le dossier de la salle."),
    ("sterne", o(28, "15:48"), "M. Garrel sort de chez moi. Il a trouvé l'Aurore « en parfait état ». J'avoue en être soulagé. A. S."),
    ("me", o(28, "16:02"), "Oui, il m'a appelée, tout est conforme. Vous aurez son rapport ce soir."),
    ("sterne", o(29, "09:12"), "Comme convenu dans la convention de prêt, je conserve le double de la clé de la vitrine 4. "
                                "Je préfère qu'il en soit ainsi. A. S.", dict(id="m_sterne_key")),
    ("me", o(29, "09:30"), "Entendu. L'original reste avec moi, dans le coffre du Pavillon."),
    ("sterne", t(6, "19:10"), "Pour la soirée, je rêve d'un vrai moment de théâtre autour de l'Aurore. Me permettez-vous d'en toucher "
                              "un mot à votre équipe technique ? A. S."),
    ("me", t(6, "19:31"), "Bien sûr, voyez directement avec Victor, le régisseur. Il adore ce genre de défi."),
    ("sterne", t(10, "20:05"), "Je serai là jeudi dès 17h. J'ai hâte, et un peu le trac, je l'avoue. A. S."),
    ("sterne", t(12, "17:12"), "Mon joaillier, M. Kessler, passera avec moi à 17h30 pour un dernier nettoyage. Vingt minutes, seuls, "
                               "s'il vous plaît. A. S.", dict(id="m_sterne_1712")),
    ("me", t(12, "17:14"), "Bien sûr, je préviens la sécurité."),
    ("sterne", t(12, "17:53"), "C'est fait. Elle brille comme au premier jour. Merci de votre confiance. A. S."),
    ("me", t(12, "22:24"), "Monsieur Sterne, où êtes-vous ? La police veut voir tout le monde en salle 1."),
])

# --- Team group (the gala crew)
TEAM = ["helene", "victor", "noemie", "josiane", "lemaire"]
conv("c_team", TEAM, [
    ("helene", o(5, "09:02"), "Bonjour à tous, je crée le groupe pour le gala du 12/11. Merci de garder les échanges ici plutôt que par mail 🙏"),
    ("noemie", o(5, "09:10"), "Parfait !"),
    ("victor", o(5, "09:31"), "ok"),
    ("lemaire", o(5, "10:02"), "Bonjour à tous. Premier plan de salle d'ici mercredi."),
    ("lemaire", o(7, "18:40"), "Plan v1 sur le drive. 6 vitrines, scène côté jardin."),
    ("me", o(7, "19:02"), "Merci PY. On en parle demain 10h au Pavillon."),
    ("victor", o(13, "14:15"), "qui a les clés du local technique ? faut que je sorte les découpes"),
    ("helene", o(13, "14:20"), "Moi. Je descends."),
    ("noemie", o(20, "08:47"), "Arteo confirme les vitrines pour demain, créneau 8h-10h"),
    ("me", o(20, "08:50"), "Super. Il faut quelqu'un au quai de livraison dès 7h45"),
    ("josiane", o(20, "08:52"), "Je serai là, j'ouvre à 7h30 de toute façon"),
    ("noemie", o(21, "10:14"), "Le camion est bloqué sur le périph 🙃 ils annoncent 11h30"),
    ("noemie", o(21, "11:40"), "Les vitrines sont là ! Une rayure sur la 6, je la prends en photo pour les réserves"),
    ("lemaire", o(23, "17:05"), "Plan v3 validé par Hélène. La vitrine 4 est dans l'axe de la poursuite."),
    ("victor", o(23, "17:10"), "je la règle lundi"),
    ("helene", o(27, "12:30"), "Rappel : noms + fonctions pour les badges avant le 6/11"),
    ("noemie", o(27, "12:44"), "Je fais le tableau"),
    ("josiane", t(3, "09:15"), "Combien de personnes au vestiaire le 12 ? J'ai 280 cintres"),
    ("me", t(3, "09:40"), "350 invités. On prend des portants en plus ?"),
    ("josiane", t(3, "09:41"), "Je m'en occupe"),
    ("victor", t(5, "18:22"), "toujours pas de réponse pour mes heures du 11. je vais finir par leur faire un noir en plein discours 😤",
     dict(id="m_team_victor_joke")),
    ("helene", t(5, "18:30"), "Victor, on en parle demain matin dans mon bureau."),
    ("noemie", t(9, "16:02"), "Les cartels sont arrivés. Coquille sur la vitrine 2 : « 1928 » au lieu de « 1938 »"),
    ("me", t(9, "16:10"), "Je rappelle l'imprimeur. Merci Noémie"),
    ("helene", t(11, "08:05"), "Courage à ceux qui montent aujourd'hui malgré le férié. Café et viennoiseries à l'accueil ☕"),
    ("lemaire", t(11, "08:30"), "Merci !! 🥐"),
    ("noemie", t(12, "07:58"), "Jour J 💫"),
    ("helene", t(12, "13:40"), "La sécurité arrive à 16h. Personne ne touche aux vitrines sans Salomé ou moi."),
    ("me", t(12, "16:12"), "Aurore posée, vitrine 4 fermée à 16h10. Merci Hélène."),
    ("victor", t(12, "19:52"), "régie ok. conducteur envoyé à Salomé"),
    ("helene", t(12, "20:01"), "Portes ouvertes. Bonne soirée à tous 🥂"),
    ("noemie", t(12, "21:47"), "Discours dans 3 min, Hélène t'es où ?"),
    ("helene", t(12, "21:48"), "J'arrive"),
    ("noemie", t(12, "22:16"), "LA VITRINE 4 EST VIDE"),
    ("me", t(12, "22:16"), "Personne ne sort. Hélène, les portes."),
    ("victor", t(12, "22:16"), "je suis en régie !! c'était le noir du conducteur, personne t'a prévenue ??",
     dict(id="m_victor_2216", photo="p_regie_2215")),
    ("josiane", t(12, "22:18"), "Au vestiaire tout le monde est calme, je bouge pas"),
    ("helene", t(12, "22:19"), "l'extra est parti par l'arrière !!!", dict(id="m_team_2219")),
    ("noemie", t(12, "22:20"), "Le serveur ?? Celui de ce soir ?"),
    ("helene", t(12, "22:22"), "Sécurité prévenue. Police appelée."),
    ("helene", t(12, "22:31"), "la police est là"),
    ("noemie", t(12, "22:58"), "Ils prennent les identités de tout le monde en salle 1"),
    ("helene", t(12, "23:12"), "Salomé, ils veulent ton téléphone aussi. Désolée.", dict(unread=True)),
], title="Éclats — équipe gala ✨")

# --- Victor (lighting technician): lowercase, blunt
conv("c_victor", ["victor"], [
    ("victor", o(8, "11:20"), "salut, t'as la fiche technique des vitrines ? faut que je sache s'il y a de la led dedans"),
    ("me", o(8, "11:45"), "Pas de LED intégrée, tout vient de tes découpes. Je t'envoie la fiche."),
    ("victor", o(19, "17:02"), "tes cartels sont trop brillants, ça va me faire des reflets partout"),
    ("me", o(19, "17:20"), "Je demande une finition mate à l'imprimeur"),
    ("victor", o(26, "22:14"), "réglage vitrine 4 fini. ça claque"),
    ("me", o(26, "22:30"), "Hâte de voir !"),
    ("victor", t(7, "10:05"), "le monsieur du collier m'a appelé. il veut un effet pour la révélation, je te fais un point"),
    ("me", t(7, "10:40"), "Ok, vois avec lui tant que ça reste élégant. Mets tout dans le conducteur."),
    ("victor", t(12, "19:41"), "conducteur v3 dans ta boîte. lis le avant 22h stp"),
    ("me", t(12, "19:44"), "Oui oui dès que je souffle"),
    ("victor", t(12, "22:30"), "C'était pas une panne. Personne t'a prévenue ?? C'est écrit dans le conducteur, 22:14, je l'ai pas inventé",
     dict(id="m_victor_2230")),
    ("victor", t(12, "22:33"), "ils photographient ma console comme si j'étais un voleur"),
])

# --- Hélène (director of the venue)
conv("c_helene", ["helene"], [
    ("helene", o(1, "17:30"), "Salomé, le conseil valide les dates : gala le 12 novembre, ouverture au public le 13. Bravo !"),
    ("me", o(1, "17:45"), "Merci Hélène !! On va faire quelque chose de beau."),
    ("helene", o(12, "09:20"), "Tu peux passer signer la convention de mise à disposition de la salle ?"),
    ("me", o(12, "09:40"), "Jeudi matin ?"),
    ("helene", o(12, "09:41"), "Parfait"),
    ("helene", o(22, "19:02"), "Petite question : Victor a déclaré 14h sup sur le montage, c'est validé de ton côté ?"),
    ("me", o(22, "19:30"), "Oui, il a fait tous les réglages le soir. C'est justifié."),
    ("helene", o(29, "11:05"), "Le coffre est libre pour la clé de la 4. Code habituel."),
    ("me", o(29, "11:10"), "Top. M. Sterne garde le double, c'est dans sa convention."),
    ("helene", o(29, "11:12"), "Ok, noté pour la sécurité."),
    ("helene", t(10, "18:00"), "Iris Nakamura m'a demandé si elle pouvait « voir le collier de près » avant jeudi. J'ai dit non 🙂"),
    ("me", t(10, "18:12"), "Moi aussi. Personne n'ouvre la 4."),
    ("helene", t(12, "22:17"), "C'est Victor qui a coupé le courant ?! Il est où ??", dict(id="m_helene_2217")),
    ("me", t(12, "22:18"), "Il dit que c'était prévu. Je vérifie."),
    ("helene", t(12, "22:40"), "Les policiers veulent la liste des extras. Tu as le contact de l'agence ?"),
    ("me", t(12, "22:41"), "Relais Intérim, je te transfère."),
])

# --- Iris (host of the evening, fashion journalist)
conv("c_iris", ["iris"], [
    ("iris", o(4, "14:22"), "Salooomé !! Hélène m'a proposé d'animer ton gala, je dis OUI évidemment 🥹✨"),
    ("me", o(4, "14:50"), "Trop contente !! On se cale un café pour le déroulé ?"),
    ("iris", o(4, "14:51"), "mardi 13 ? je suis dispo à partir de 16h"),
    ("iris", o(13, "18:05"), "merci pour le café, j'adore le concept. je bosse mes textes"),
    ("iris", o(30, "21:40"), "tu peux m'envoyer 3-4 lignes sur chaque pièce ? mes abonnés vont poser des questions en live"),
    ("me", o(30, "22:10"), "Je t'envoie les textes des cartels demain"),
    ("iris", t(10, "15:32"), "Tu pourrais m'ouvrir la vitrine 4 avant la soirée ? Juste 2 minutes pour un gros plan, promis je touche pas 😇",
     dict(id="m_iris_access")),
    ("me", t(10, "16:05"), "Non Iris, désolée 😅 Personne n'y touche à part le prêteur, c'est dans l'assurance. Tu auras la poursuite, c'est déjà pas mal."),
    ("iris", t(10, "16:06"), "ok ok madame la commissaire 🫡"),
    ("iris", t(10, "21:14"), "et sinon mon look pour jeudi, validé ?", dict(photo="p_iris_look")),
    ("me", t(10, "21:30"), "Validé à 200 %"),
    ("iris", t(12, "18:45"), "je suis là ! loge 2 c'est bien ça ?"),
    ("me", t(12, "18:47"), "Loge 2 oui. Maquillage à 19h."),
    ("me", t(12, "22:21"), "Iris tu as posté ?? Enlève ça tout de suite stp"),
    ("iris", t(12, "22:25"), "j'ai cru bien faire, tout le monde filmait de toute façon 😓"),
])

# --- Josiane (cloakroom): warm, a bit old-fashioned
conv("c_josiane", ["josiane"], [
    ("josiane", o(20, "20:04"), "Bonsoir Salomé c'est Josiane du vestiaire. Hélène m'a donné votre numéro. Pour le 12 je peux avoir 2 personnes en renfort ?"),
    ("me", o(20, "20:30"), "Bonsoir Josiane ! Je demande à l'agence, normalement oui."),
    ("josiane", o(20, "20:31"), "Merci ma belle"),
    ("josiane", t(12, "17:20"), "Le petit extra est gentil comme tout. Il m'aide à monter les portants avant de passer au service"),
    ("me", t(12, "17:25"), "Parfait, merci Josiane !"),
    ("josiane", t(12, "22:40"), "Salomé, pour le petit Enzo : il était avec moi au vestiaire pendant tout le noir, il était venu m'apporter "
                                "un verre d'eau. Il tenait la lampe de son téléphone pour que je voie les tickets. Il a paniqué après, "
                                "il n'est pas déclaré le pauvre.", dict(id="m_josiane_2240")),
    ("me", t(12, "22:42"), "Merci Josiane. Dites-le à la police, c'est important."),
    ("josiane", t(12, "22:43"), "Je leur ai dit. Ils écrivent tout."),
])

# --- Noémie (assistant)
conv("c_noemie", ["noemie"], [
    ("noemie", o(1, "09:05"), "Coucou ! J'attaque les demandes de prêt ce matin"),
    ("noemie", o(6, "13:12"), "Le musée de Lyon est ok pour les deux broches 🎉"),
    ("me", o(6, "13:20"), "YES"),
    ("noemie", o(14, "18:50"), "Je pars plus tôt demain, dentiste à 16h, ça va ?"),
    ("me", o(14, "19:02"), "Bien sûr"),
    ("noemie", o(23, "12:05"), "Tu veux quoi comme sandwich ? Je descends"),
    ("me", o(23, "12:06"), "Poulet crudités stp, merci !!"),
    ("noemie", t(2, "10:15"), "Liste presse à jour : 42 accrédités"),
    ("me", t(2, "10:30"), "Top. Tu relances les mensuels ?"),
    ("noemie", t(2, "10:31"), "C'est parti"),
    ("noemie", t(9, "19:30"), "Tu as vu l'article sur Sterne dans la Gazette ? 😬"),
    ("me", t(9, "19:40"), "Oui… On n'en parle pas trop, il est susceptible."),
    ("noemie", t(12, "22:13"), "la salle est magnifique 😍", dict(photo="p_room_2213")),
    ("noemie", t(12, "22:50"), "Ça va toi ? Je suis avec les policiers en salle 1, ils demandent tout le monde"),
    ("me", t(12, "22:52"), "Tiens bon. J'arrive."),
])

# --- Camille (sister, lives in Lyon)
conv("c_camille", ["camille"], [
    ("camille", o(3, "11:02"), "t'es dispo pour un facetime ce soir ? maman veut qu'on parle de noël 🙄"),
    ("me", o(3, "11:30"), "Vers 21h ?"),
    ("camille", o(3, "11:31"), "ok"),
    ("camille", o(11, "16:40"), "Jules a perdu sa première dent !!", dict(photo="p_jules")),
    ("me", o(11, "17:02"), "Trop mignon !! Dis-lui que tata envoie une pièce 😂"),
    ("camille", o(22, "22:14"), "je monte à paris le week-end du 7, je peux dormir chez toi ?"),
    ("me", o(22, "22:40"), "Évidemment ! Par contre je bosse le samedi après-midi, le gala c'est le 12"),
    ("camille", o(22, "22:41"), "pas grave je ferai les boutiques"),
    ("camille", t(6, "21:15"), "train demain 8h04, arrivée gare de lyon 10h02"),
    ("me", t(6, "21:20"), "Je viens te chercher"),
    ("camille", t(8, "18:55"), "bien rentrée, merci pour le week end ❤️ courage pour jeudi"),
    ("camille", t(12, "22:48"), "je viens de voir un truc sur ton gala sur les réseaux ??? ça va ?"),
    ("me", t(12, "23:05"), "Ça va. Police. Je t'appelle demain."),
    ("camille", t(12, "23:06"), "ok. je t'aime"),
])

# --- Samir (friend, invited to the gala)
conv("c_samir", ["samir"], [
    ("samir", o(3, "20:12"), "Yo, footing dimanche aux Buttes ?"),
    ("me", o(3, "20:40"), "Si c'est 10h et pas 8h, oui"),
    ("samir", o(3, "20:41"), "10h deal"),
    ("samir", o(17, "12:05"), "t'as vu la saison 3 ? j'ai pas dormi"),
    ("me", o(17, "12:30"), "Pas le temps de rien voir, je vis au Pavillon 😭"),
    ("samir", o(25, "09:58"), "je suis devant l'entrée du parc, t'es où"),
    ("me", o(25, "10:01"), "2 min !!"),
    ("me", t(4, "19:20"), "Tu veux venir au gala jeudi 12 ? J'ai une place pour toi"),
    ("samir", t(4, "19:28"), "grave. costume obligatoire ?"),
    ("me", t(4, "19:29"), "Tenue de soirée. Donc oui 😇"),
    ("samir", t(12, "20:22"), "arrivé. c'est ouf ici"),
    ("samir", t(12, "22:14"), "tout s'éteint ?? c'est voulu ?", dict(id="m_samir_2214", photo="p_stage_2214")),
    ("samir", t(12, "22:26"), "je sais pas si ça peut servir mais Iris a pas lâché son micro sur pied de tout le noir. elle parlait, "
                              "j'étais au premier rang à 2 m d'elle", dict(id="m_samir_2226")),
    ("me", t(12, "22:27"), "Merci. Dis-le aux policiers."),
])

# --- Enzo (temp waiter, hired the same day)
conv("c_enzo", ["enzo"], [
    ("enzo", t(12, "16:52"), "bonjour madame c'est Enzo de relais interim, je suis a l'entrée du personnel mais le monsieur veut pas me laisser rentrer"),
    ("me", t(12, "16:54"), "Bonjour Enzo, je descends. La petite porte grise à droite du perron ?"),
    ("enzo", t(12, "16:54"), "oui"),
    ("me", t(12, "22:44"), "Enzo, où êtes-vous ? Revenez ou appelez-moi, s'il vous plaît."),
    ("enzo", t(12, "23:08"), "je vous jure j'ai rien pris madame. j'ai eu peur c'est tout. je viens demain voir la police si il faut"),
])

# --- Pierre-Yves Lemaire (set designer, Bagnolet workshop)
conv("c_lemaire", ["lemaire"], [
    ("lemaire", o(7, "22:05"), "Salomé, je pense qu'on peut gagner 40 cm en décalant la scène. Je te montre demain."),
    ("me", o(7, "22:30"), "Ok. Pas trop près de la 4 quand même."),
    ("me", o(14, "13:05"), "Je suis devant l'atelier"),
    ("lemaire", o(14, "13:06"), "je descends !"),
    ("lemaire", o(29, "17:40"), "Les bustes de velours sont prêts. Le noir est plus profond que l'échantillon, tu vas aimer"),
    ("me", o(29, "17:52"), "J'ai hâte"),
    ("lemaire", t(12, "12:40"), "Je t'attends à l'atelier à 13h pour les derniers socles. Tu restes manger un bout ?"),
    ("me", t(12, "12:42"), "Vite fait alors, je dois être au Pavillon vers 15h"),
    ("lemaire", t(12, "23:01"), "Je viens d'apprendre. Je suis désolé. Dis-moi si je peux faire quoi que ce soit.", dict(unread=True)),
])

conv("c_agence", ["agence"], [
    ("agence", t(12, "11:02"), "Relais Intérim : renfort confirmé pour le gala du 12/11 au Pavillon Mercure : 1 extra service, Enzo B. "
                               "Prise de poste 17h, entrée du personnel. Contrat de mission établi le 13/11 (demande tardive)."),
    ("agence", t(12, "11:03"), "Relais Intérim : numéro de l'extra : 06 51 38 72 44."),
])

conv("c_arteo", ["arteo"], [
    ("arteo", o(20, "16:00"), "ARTEO Transports : livraison AT-2210 prévue le 21/10 entre 08:00 et 10:00. Merci de prévoir un accès quai."),
    ("arteo", o(21, "10:12"), "ARTEO Transports : votre livraison AT-2210 est retardée. Nouvelle heure estimée : 11:30."),
    ("arteo", o(21, "11:34"), "ARTEO Transports : livraison AT-2210 effectuée. Signataire : J. PETIT."),
])

conv("c_banque", ["banque"], [
    ("banque", o(5, "08:00"), "Banque Citadine : prélèvement LOYER OCTOBRE de 1 140,00 € effectué."),
    ("banque", t(5, "08:00"), "Banque Citadine : prélèvement LOYER NOVEMBRE de 1 140,00 € effectué."),
    ("banque", t(12, "18:31"), "Banque Citadine : paiement de 12,80 € chez PHARMACIE WILSON."),
])

# ---------------------------------------------------------------- calls
calls = []
def call(cid, contact, direction, at, dur):
    calls.append(dict(id=cid, contact=contact, direction=direction, at=at, durationSeconds=dur))
call("k01", "sterne", "incoming", o(1, "12:10"), 246)
call("k02", "camille", "outgoing", o(3, "21:04"), 1840)
call("k03", "helene", "incoming", o(12, "09:15"), 182)
call("k04", "iris", "outgoing", o(13, "15:40"), 58)
call("k05", "valmont", "incoming", o(20, "14:40"), 312)
call("k06", "arteo", "missed", o(21, "10:05"), 0)
call("k07", "lemaire", "incoming", o(23, "16:50"), 424)
call("k08", "samir", "missed", o(25, "09:56"), 0)
call("k09", "garrel", "outgoing", o(26, "10:05"), 151)
call("k10", "garrel", "incoming", o(28, "12:20"), 97)
call("k11", "camille", "incoming", t(1, "19:00"), 1210)
call("k12", "victor", "missed", t(7, "10:01"), 0)
call("k13", "noemie", "outgoing", t(11, "08:10"), 95)
call("k14", "agence", "outgoing", t(12, "10:40"), 214)
call("k15", "fauve", "incoming", t(12, "14:20"), 131)
call("k16", "helene", "outgoing", t(12, "22:21"), 62)
call("k_sterne_2231", "sterne", "incoming", t(12, "22:31"), 180)
call("k17", "enzo", "outgoing", t(12, "22:46"), 0)
call("k18", "camille", "missed", t(12, "22:55"), 0)
call("k19", "enzo", "incoming", t(12, "23:02"), 160)
call("k20", "valmont", "missed", t(12, "23:14"), 0)

# ---------------------------------------------------------------- places & tracks
places = [
    dict(id="pl_pavillon", name="Pavillon Mercure — avenue du Président-Wilson", kind="work", x=0.18, y=0.52),
    dict(id="pl_home", name="Domicile — rue des Envierges", kind="home", x=0.82, y=0.36),
    dict(id="pl_sterne", name="Hôtel particulier Sterne — avenue Foch", kind="home", x=0.10, y=0.34),
    dict(id="pl_kessler", name="Atelier Kessler — rue de la Paix", kind="shop", x=0.46, y=0.40),
    dict(id="pl_valmont", name="Assurances Valmont Art — La Défense", kind="work", x=0.04, y=0.12),
    dict(id="pl_rossignol", name="Salle des ventes Rossignol — rue Drouot", kind="shop", x=0.52, y=0.33),
    dict(id="pl_atelier", name="Atelier Lemaire — Bagnolet", kind="industrial", x=0.95, y=0.55),
    dict(id="pl_gare", name="Gare de Lyon", kind="station", x=0.70, y=0.78),
    dict(id="pl_cafe", name="Café du Jourdain", kind="bar", x=0.83, y=0.30),
    dict(id="pl_buttes", name="Parc des Buttes-Chaumont", kind="park", x=0.80, y=0.20),
]
COORDS = {
    "pl_pavillon": (48.8650, 2.2975, None),
    "pl_home": (48.8715, 2.3895, None),
    "pl_sterne": (48.8715, 2.2830, ["mail:mail_avenant"]),
    "pl_kessler": (48.8690, 2.3310, ["calendar:c_sterne_1730"]),
    "pl_valmont": (48.8920, 2.2380, ["mail:mail_avenant"]),
    "pl_rossignol": (48.8740, 2.3420, ["browser:w_gazette"]),
    "pl_atelier": (48.8640, 2.4170, None),
    "pl_gare": (48.8443, 2.3740, None),
    "pl_cafe": (48.8752, 2.3890, None),
    "pl_buttes": (48.8800, 2.3830, None),
}
for pl in places:
    lat, lon, revealed = COORDS[pl["id"]]
    pl["latitude"], pl["longitude"] = lat, lon
    if revealed:
        pl["revealedBy"] = revealed

tracks = [
    dict(id="t_me", contact="me", points=[
        dict(id="tp_me_1", at=t(7, "09:55"), place="pl_gare"),
        dict(id="tp_me_2", at=t(7, "10:40"), place="pl_home"),
        dict(id="tp_me_3", at=t(8, "10:05"), place="pl_buttes"),
        dict(id="tp_me_4", at=t(11, "08:35"), place="pl_pavillon"),
        dict(id="tp_me_5", at=t(11, "20:10"), place="pl_home"),
        dict(id="tp_me_6", at=t(12, "07:55"), place="pl_home", note="Départ"),
        dict(id="tp_me_7", at=t(12, "08:30"), place="pl_pavillon"),
        dict(id="tp_me_8", at=t(12, "12:20"), place="pl_pavillon", note="Départ"),
        dict(id="tp_me_9", at=t(12, "12:58"), place="pl_atelier"),
        dict(id="tp_me_10", at=t(12, "14:25"), place="pl_atelier", note="Départ"),
        dict(id="tp_me_11", at=t(12, "15:10"), place="pl_pavillon"),
        dict(id="tp_me_12", at=t(12, "23:20"), place="pl_pavillon", note="Toujours sur place"),
    ]),
]

# ---------------------------------------------------------------- photos
photos = []
def photo(pid, taken, scene, caption, details, source="camera", place=None, frm=None, received=None, device="iPhone 16 Pro",
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

PAV = "Pavillon Mercure"
# Everyday camera roll: montage, Paris, family, failed shots, screenshots, receipts, old years.
roll = [
    ("p_old01", at(2019, 3, 14, "18:20"), "gallery", "Accrochage « Verre & lumière », Lyon, 2019.", "Des vases sur des socles blancs. Salomé, de dos, un mètre ruban à la main.", "Lyon", "old", None),
    ("p_old02", at(2021, 6, 26, "21:40"), "party", "Vernissage à Nantes, juin 2021.", "Des guirlandes, du monde dans une cour pavée.", "Nantes", "old", None),
    ("p_old03", at(2023, 8, 12, "17:15"), "beach", "Plage avec Camille et Jules, été 2023.", "Un seau rouge, un château de sable effondré.", None, "old", None),
    ("p_old04", at(2024, 12, 30, "15:02"), "snow", "Neige au chalet, décembre 2024.", "Des sapins, une luge contre un mur en bois.", None, "old", None),
    ("p_old05", at(2025, 5, 9, "20:30"), "interior_warm", "Mes 35 ans.", "Des bougies, une table pleine de verres.", "Domicile", "old", None),
    ("p_b01", o(1, "11:10"), "gallery", "Salle 2 du Pavillon, encore vide.", "Parquet nu, murs blancs, des rails lumière au plafond.", PAV, None, None),
    ("p_b02", o(8, "10:20"), "laptop", "Plan v1 à l'écran.", "Six rectangles numérotés et une scène à gauche.", PAV, None, None),
    ("p_b03", o(10, "09:12"), "cat", "Pistache sur la pile de catalogues.", "Un chat tigré couché sur des épreuves imprimées.", "Domicile", None, None),
    ("p_b04", o(9, "15:40"), "document", "Convention de prêt — page 1.", "Un tampon d'étude notariale en bas de page.", "Étude Lanvin", "document",
     ["CONVENTION DE PRÊT D'ŒUVRE", "Prêteur : M. Adrien Sterne", "Emprunteur : Pavillon Mercure", "Objet : collier dit « Aurore », Paris, 1928",
      "Exposition « Éclats » — 13/11/2026 – 28/02/2027", "Art. 7 — Accès aux vitrines : voir annexe 2"]),
    ("p_b05", o(14, "13:30"), "office", "L'atelier de PY à Bagnolet.", "Des maquettes de vitrines en carton plume, des pots de peinture noire.", "Bagnolet", None, None),
    ("p_b06", o(16, "23:05"), "street_night", "Belleville, la nuit, en rentrant.", "Une rue en pente, des réverbères, un scooter garé.", "Domicile", "night", None),
    ("p_b07", o(18, "11:50"), "terrace", "Café au Jourdain, un dimanche.", "Deux tasses, un croissant entamé, du soleil sur la table.", "Café du Jourdain", None, None),
    ("p_b08", o(21, "11:45"), "vitrine", "Livraison des vitrines.", "Six vitrines encore sous bâche, des sangles au sol. Une rayure sur la 6.", PAV, None, None),
    ("p_b09", o(23, "17:20"), "screenshot", "Capture : plan de salle v3.", "La vitrine 4 est au centre, face à l'entrée.", None, "screenshot",
     ["SALLE 2 — PLAN v3", "Scène (animation) — côté jardin", "Vitrines 1 à 6", "Vitrine 4 : collier Aurore — axe poursuite",
      "Régie : mezzanine, fond de salle", "Vestiaire : entrée Wilson", "Sortie de service : couloir B"]),
    ("p_b10", o(25, "10:35"), "park", "Footing aux Buttes-Chaumont.", "Les arbres roux, le temple au loin, Samir essoufflé.", "Parc des Buttes-Chaumont", None, None),
    ("p_b11", o(27, "23:48"), "receipt", "Reçu de taxi.", "Retour tardif du Pavillon.", None, "document",
     ["TAXI PARISIEN", "27/10/2026  23:21 → 23:46", "Av. du Pdt-Wilson → Rue des Envierges", "Montant : 31,40 €", "Merci de votre confiance"]),
    ("p_b12", o(30, "14:12"), "document", "Épreuve du cartel de la vitrine 4.", "Une étiquette noire, lettres dorées.", PAV, "document",
     ["VITRINE 4", "Collier « Aurore »", "Paris, 1928", "Perles fines en chute, platine, diamants taille ancienne", "Prêt de M. Adrien Sterne"]),
    ("p_b13", t(2, "16:40"), "books", "Épreuves du catalogue.", "Des pages étalées sur le bureau, des post-it jaunes partout.", PAV, None, None),
    ("p_b14", t(4, "08:20"), "rain", "Pluie sur la fenêtre du salon.", "Des gouttes, les toits gris derrière.", "Domicile", None, None),
    ("p_b15", t(6, "21:15"), "gallery", "Essais lumière en salle 2.", "Un rond de lumière blanche sur une vitrine vide, le reste dans le noir.", PAV, None, None),
    ("p_b16", t(7, "10:04"), "station", "Gare de Lyon, en attendant Camille.", "Le panneau affiche « Lyon Part-Dieu — arrivée 10h02 — à l'heure ».", "Gare de Lyon", "quick", None),
    ("p_b17", t(7, "20:45"), "selfie", "Selfie avec Camille.", "Deux sœurs, même nez, même rire. Une bougie derrière.", "Domicile", "selfie", None),
    ("p_b18", t(11, "15:30"), "gallery", "Montage du 11 novembre.", "Les vitrines numérotées sont en place, encore vides. Des escabeaux partout.", PAV, None, None),
    ("p_b19", t(12, "08:41"), "view", "Le matin, depuis le perron du Pavillon.", "La Seine en contrebas, la tour dans la brume.", PAV, None, None),
    ("p_b20", t(12, "16:05"), "vitrine", "Pose de l'Aurore dans la vitrine 4.",
     "Le collier est posé sur le buste de velours noir, le fermoir bien visible au centre, face à la salle. Photo prise de trop loin pour compter les perles. Hélène tient la porte de la vitrine.",
     PAV, None, None),
    ("p_b21", t(12, "18:40"), "gala", "La salle prête, avant l'ouverture.", "Tables hautes, nappes noires, les six vitrines allumées.", PAV, None, None),
    ("p_b22", t(12, "19:58"), "mirror", "Selfie avec Noémie, en noir.", "Deux robes noires, des badges « ORGANISATION ».", PAV, "selfie", None),
    ("p_b23", t(12, "20:35"), "gala", "Les premiers invités.", "Une foule en tenue de soirée, des coupes, la vitrine 4 au fond.", PAV, None, None),
    ("p_b24", t(12, "21:52"), "gala", "Discours d'Hélène.", "Photo floue : Hélène au pupitre, un bras levé devant l'objectif.", PAV, "blurry", None),
    ("p_blur01", o(19, "07:10"), "ceiling", "Le plafond de la chambre.", "Photo prise par erreur au réveil.", "Domicile", "blurry", None),
    ("p_blur02", t(12, "22:14"), "pocket", "Photo déclenchée par erreur dans le noir.", "Tout est noir. En haut à droite, la lueur verte d'un bloc de secours « SORTIE ».", PAV, "blurry", None),
    ("p_scr01", t(12, "07:40"), "screenshot", "Capture : météo de jeudi.", "Pluie le matin, sec le soir.", None, "screenshot",
     ["Paris — jeudi 12 novembre", "08h  🌧  9°", "14h  ☁  12°", "20h  ☁  10°", "23h  🌙  8°"]),
    ("p_scr02", t(10, "11:15"), "screenshot", "Capture : liste des badges.", "Le tableau de Noémie.", None, "screenshot",
     ["BADGES GALA — 12/11", "Organisation : S. Tessier, N. Castel", "Pavillon : H. Dubreuil, V. Almeida, J. Petit", "Animation : I. Nakamura",
      "Prêteur : A. Sterne + 1", "Cocktail : Maison Fauve (8)"]),
]
for pid, taken, scene, cap, det, place, style, lines in roll:
    photo(pid, taken, scene, cap, det, place=place, style=style, lines=lines,
          device="iPhone 11" if taken < "2023" else ("iPhone 14" if taken < "2026" else "iPhone 16 Pro"))

# The photos that matter (and the ones that only look like they do).
photo("p_vitrine_1752", t(12, "17:52"), "vitrine", "La vitrine 4 sous les projecteurs, pour les réseaux.",
      "En zoomant : on compte 41 perles. Le fermoir est tourné vers le fond de la vitrine, invisible.", place=PAV)
photo("p_vitrine_2216", t(12, "22:16"), "vitrine_empty", "La vitrine 4, vide, sous la poursuite.",
      "La porte vitrée est entrouverte de deux centimètres. La serrure est intacte, sans rayure ni trace d'outil : elle a été ouverte avec une clé. Le buste de velours est vide.",
      place=PAV)
photo("p_room_2213", t(12, "22:13"), "gala", "La salle 2 pendant la présentation d'Iris.",
      "La scène à gauche, Iris au micro dans la poursuite. À droite, près de la vitrine 4, Adrien Sterne, seul, une main dans la poche de sa veste.",
      source="received", frm="noemie", received=t(12, "22:13"), place=PAV, device="iPhone 15")
photo("p_stage_2214", t(12, "22:14"), "gala", "La scène au moment où tout s'éteint.",
      "Prise à 22:14 pile. Iris Nakamura, au micro sur pied, est le dernier point éclairé de la salle. La vitrine 4, à l'autre bout, est déjà dans le noir, à une vingtaine de mètres.",
      source="received", frm="samir", received=t(12, "22:14"), place=PAV, device="Pixel 8", style="night")
photo("p_regie_2215", t(12, "22:15"), "desk_night", "La console de la régie, dans le noir.",
      "L'écran affiche « Q47 — NOIR 90 s — GO 22:14:00 » et un compte à rebours. La régie est sur la mezzanine au fond de la salle, à une trentaine de mètres de la vitrine 4. Le reflet de Victor, casque sur les oreilles, dans l'écran.",
      source="received", frm="victor", received=t(12, "22:16"), place=PAV, device="Galaxy S23", style="night")
photo("p_iris_look", t(10, "21:10"), "mirror", "Iris dans une robe noire à sequins.",
      "Selfie dans un miroir de cabine d'essayage. Rien de plus.", source="received", frm="iris", received=t(10, "21:14"),
      device="iPhone 16", style="selfie")
photo("p_jules", o(11, "16:38"), "interior_warm", "Jules montre le trou de sa dent.", "Un petit garçon hilare, une dent dans la main.",
      source="received", frm="camille", received=o(11, "16:40"), place="Lyon", device="iPhone 13")

# ---------------------------------------------------------------- calendar
calendar = [
    dict(id="c_ev01", start=o(2, "12:30"), end=o(2, "14:30"), title="Déjeuner M. Sterne", location="Chez lui — avenue Foch"),
    dict(id="c_ev02", start=o(9, "15:00"), end=o(9, "16:00"), title="Signature convention de prêt — Aurore", location="Étude Me Lanvin"),
    dict(id="c_ev03", start=o(13, "16:00"), title="Café avec Iris — déroulé du gala", location="Café du Jourdain"),
    dict(id="c_ev04", start=o(14, "13:00"), title="Atelier PY — maquettes vitrines", location="Bagnolet"),
    dict(id="c_ev05", start=o(21, "08:00"), end=o(21, "10:00"), title="Livraison vitrines (Arteo)", location="Pavillon Mercure — quai"),
    dict(id="c_ev06", start=o(28, "10:00"), end=o(28, "12:00"), title="Constat d'état Aurore — É. Garrel", location="Avenue Foch"),
    dict(id="c_ev07", start=t(7, "10:02"), title="Camille — gare de Lyon", location="Gare de Lyon"),
    dict(id="c_ev08", start=t(11, "08:30"), end=t(11, "20:00"), title="Montage (férié !)", location="Pavillon Mercure"),
    dict(id="c_ev09", start=t(12, "13:00"), end=t(12, "14:30"), title="Atelier PY — derniers socles", location="Bagnolet"),
    dict(id="c_ev10", start=t(12, "16:00"), end=t(12, "16:15"), title="Pose Aurore + fermeture vitrine 4 (avec Hélène)", location="Pavillon Mercure — salle 2"),
    dict(id="c_sterne_1730", start=t(12, "17:30"), end=t(12, "17:50"),
         title="M. Sterne + son joaillier (M. Kessler) — vitrine 4 ouverte", location="Pavillon Mercure — salle 2",
         notes="Dernier nettoyage avant le gala. Seuls, à sa demande. Prévenir la sécurité."),
    dict(id="c_gala", start=t(12, "20:00"), end=t(13, "00:30"), title="GALA — Éclats", location="Pavillon Mercure",
         notes="20:00 portes · 21:50 discours Hélène · 22:10 Iris : présentation des pièces, finale sur l'Aurore · 23:00 DJ"),
    dict(id="c_presse", start=t(13, "09:00"), end=t(13, "10:00"), title="Point presse Éclats", location="Pavillon Mercure"),
    dict(id="c_ev11", start=t(13, "10:00"), title="Ouverture au public", location="Pavillon Mercure"),
    dict(id="c_ev12", start=t(16, "00:00"), title="🎂 Jules — 7 ans", allDay=True),
]

# ---------------------------------------------------------------- notes
notes = [
    dict(id="n_todo", title="Gala — à faire", createdAt=t(2, "08:50"), modifiedAt=t(12, "15:20"),
         body="- Badges (Noémie) ✓\n- Coquille cartel vitrine 2 ✓\n- Portants vestiaire (Josiane) ✓\n- Extra en plus → Relais ✓\n"
              "- Lire le conducteur de Victor\n- Plan de table carré VIP\n- Récupérer la clé de la 4 au coffre après la soirée"),
    dict(id="n_textes", title="Textes pour Iris", createdAt=o(31, "10:12"), modifiedAt=o(31, "11:40"),
         body="V1 — Broche « Hirondelle », 1911. Or, émail plique-à-jour. Prêt du musée de Lyon.\n"
              "V2 — Bracelet « Rails », 1938. Platine, onyx.\n"
              "V4 — Collier « Aurore », Paris, 1928. Perles fines en chute, fermoir platine et diamants taille ancienne. "
              "Porté une seule fois en public, en 1931. Prêt de M. Adrien Sterne.\n"
              "V6 — Montre-bracelet « Cadran nuit », 1952."),
    dict(id="n_appart", title="Appart", createdAt=o(4, "21:30"), modifiedAt=t(3, "22:10"),
         body="Loyer 1 140 € le 5.\nChaudière : le technicien passe le 20/11 entre 8h et 12h.\nRendre les clés de cave à la gardienne."),
    dict(id="n_apres", title="Après Éclats", createdAt=o(18, "23:02"), modifiedAt=t(8, "22:30"),
         body="Vacances. Vraies vacances.\nProjet 2027 : les bijoux d'artistes (Calder ?). Voir avec Noémie pour les demandes de prêt."),
]

# ---------------------------------------------------------------- mail
ME_MAIL = "salome.tessier@volute.fr"
mails = [
    dict(id="mail_avenant", folder="inbox", fromName="Cécile Morin — Valmont Art", fromAddress="c.morin@valmont-art.fr",
         to=ME_MAIL, at=o(20, "15:12"), subject="Avenant n°2 — exposition « Éclats » — collier Aurore",
         body="Bonjour Madame Tessier,\n\nSuite à notre échange téléphonique, veuillez trouver ci-joint l'avenant n°2 au contrat « clou à clou » "
              "de l'exposition « Éclats ».\n\nLa valeur assurée du collier Aurore est portée de 1,8 M€ à 4,2 M€ à la demande du prêteur, "
              "M. Adrien Sterne (avenue Foch, Paris 16e), sur la base d'une nouvelle estimation établie par l'Atelier Kessler le 14 octobre 2026.\n\n"
              "Les autres garanties restent inchangées. L'avenant prend effet au 21 octobre 2026.\n\n"
              "Je reste à votre disposition à notre siège de La Défense.\n\nBien cordialement,\nCécile Morin\nChargée de compte — Valmont Art",
         attachments=["Avenant_Aurore_n2.pdf"]),
    dict(id="mail_avenant_re", folder="sent", fromName="Salomé Tessier", fromAddress=ME_MAIL, to="c.morin@valmont-art.fr",
         at=o(20, "16:02"), subject="Re: Avenant n°2 — exposition « Éclats » — collier Aurore",
         body="Bonjour Madame Morin,\n\nBien reçu, merci. Je transmets à la direction du Pavillon Mercure.\n\nBien à vous,\nSalomé Tessier"),
    dict(id="mail_expertise", folder="inbox", fromName="Étienne Garrel", fromAddress="e.garrel@garrel-expertise.fr",
         to=ME_MAIL, at=o(28, "18:30"), subject="Constat d'état avant exposition — collier Aurore",
         body="Madame,\n\nVoici mon constat d'état, établi ce matin au domicile du prêteur.\n\n"
              "Description : collier de 43 perles fines, montées en chute (de 4,1 à 8,6 mm), fermoir platine et diamants taille ancienne, "
              "présenté fermoir visible de face.\n\nÉtat : très bon. Lustre homogène, enfilage récent (2019), aucune perle manquante ni fêlée.\n\n"
              "Recommandations : vitrine climatisée, hygrométrie 45–55 %, aucune manipulation sans gants.\n\nCordialement,\nÉtienne Garrel\nExpert près la cour d'appel",
         attachments=["Constat_Aurore_face.jpg", "Constat_Aurore.pdf"]),
    dict(id="mail_conducteur", folder="inbox", fromName="Victor Almeida", fromAddress="v.almeida@pavillon-mercure.fr",
         to=ME_MAIL, at=t(12, "19:40"), subject="Conducteur lumière — gala v3", unread=True,
         body="Salut,\n\nConducteur v3 ci-joint, les tops principaux :\n\n"
              "19:45 — salle en préchauffe, vitrines à 60 %\n20:00 — ouverture, ambiance ambre\n"
              "21:50 — pupitre, découpe sur Hélène\n22:10 — poursuite sur Iris (scène)\n"
              "22:14:00 — NOIR TOTAL 90 s (blocs de secours seuls). À la demande de M. Sterne : effet de révélation, ne pas prévenir la salle.\n"
              "22:15:30 — poursuite sur vitrine 4, retour salle progressif.\n23:00 — DJ, ambiance club\n00:30 — service\n\n"
              "Lis-le avant 22h stp.\n\nVictor",
         attachments=["Conducteur_gala_v3.pdf"]),
    dict(id="mail_arteo", folder="inbox", fromName="Arteo Transports", fromAddress="planning@arteo-transports.fr", to=ME_MAIL,
         at=o(19, "10:30"), subject="Confirmation — livraison AT-2210 (6 vitrines)",
         body="Bonjour,\n\nNous confirmons la livraison de 6 vitrines au Pavillon Mercure le mercredi 21 octobre, créneau 08:00–10:00.\n\nL'équipe Arteo"),
    dict(id="mail_presse", folder="inbox", fromName="Noémie Castel", fromAddress="noemie.castel@volute.fr", to=ME_MAIL,
         at=t(2, "10:14"), subject="Accréditations presse — liste v2",
         body="Coucou,\n\nListe à jour : 42 accrédités, dont 6 photographes. Les mensuels sont à relancer.\n\nNoémie",
         attachments=["Accreditations_Eclats_v2.xlsx"]),
    dict(id="mail_invit", folder="inbox", fromName="Hélène Dubreuil", fromAddress="h.dubreuil@pavillon-mercure.fr", to=ME_MAIL,
         at=o(26, "17:05"), subject="Carton d'invitation — BAT",
         body="Salomé,\n\nLe BAT du carton est en pièce jointe. Je trouve le doré un peu fort, qu'en penses-tu ?\n\nHélène",
         attachments=["Carton_Eclats_BAT.pdf"]),
    dict(id="mail_sorel", folder="inbox", fromName="Imprimerie Sorel", fromAddress="compta@imprimerie-sorel.fr", to=ME_MAIL,
         at=t(10, "09:05"), subject="Facture n°2026-318 — cartels « Éclats »",
         body="Madame,\n\nVeuillez trouver ci-joint notre facture pour 24 cartels (finition mate) et la réimpression du cartel V2.\n\nMontant : 612,00 € TTC.",
         attachments=["Facture_2026-318.pdf"]),
    dict(id="mail_gazette", folder="inbox", fromName="La Gazette des ventes", fromAddress="lettre@gazette-des-ventes.fr", to=ME_MAIL,
         at=t(9, "07:00"), subject="La lettre du lundi",
         body="Au sommaire : le marché des perles fines au plus haut, les ventes de décembre à Drouot, un grand collectionneur parisien se sépare d'une partie de sa collection."),
]

# ---------------------------------------------------------------- browser
browser = [
    dict(id="w01", at=o(1, "22:40"), kind="search", text="exposition joaillerie xxe siècle paris 2026"),
    dict(id="w02", at=o(8, "23:10"), kind="search", text="convention de prêt oeuvre particulier clauses clés vitrine"),
    dict(id="w03", at=o(16, "11:30"), kind="search", text="collier aurore 1928 perles"),
    dict(id="w04", at=o(16, "11:33"), kind="visit", text="Le collier Aurore, une pièce légendaire de 1928",
         url="bijoux-anciens.fr/aurore-1928",
         summary="Réalisé à Paris en 1928 pour une danseuse, porté une seule fois en public en 1931. Acquis en 1987 par la famille Sterne. Aucune photo récente publiée."),
    dict(id="w05", at=o(20, "15:30"), kind="search", text="avenant assurance oeuvre prêt valeur agréée"),
    dict(id="w06", at=t(1, "22:05"), kind="search", text="vitrine musée serrure combien de temps pour ouvrir"),
    dict(id="w07", at=t(5, "07:52"), kind="visit", text="Itinéraire : Rue des Envierges → Avenue du Président-Wilson",
         url="plan.ratp-itineraires.fr", summary="Métro ligne 11 puis ligne 9 : 38 min. Taxi : 27 min."),
    dict(id="w08", at=t(6, "21:25"), kind="search", text="train lyon paris 8h04 samedi arrivée voie"),
    dict(id="w_gazette", at=t(9, "19:34"), kind="visit", text="Adrien Sterne se sépare de douze pièces de sa collection — vente le 3 décembre",
         url="gazette-des-ventes.fr/actualites/sterne-dispersion",
         summary="Le collectionneur disperse douze pièces le jeudi 3 décembre à la salle des ventes Rossignol, rue Drouot. "
                 "Selon plusieurs marchands, il traverserait de sérieuses difficultés financières : son hôtel particulier de l'avenue Foch "
                 "serait hypothéqué. L'Aurore ne fait pas partie de la vente."),
    dict(id="w10", at=t(9, "19:41"), kind="search", text="salle des ventes rossignol drouot 3 décembre catalogue"),
    dict(id="w11", at=t(10, "15:50"), kind="search", text="iris nakamura abonnés"),
    dict(id="w12", at=t(12, "07:39"), kind="search", text="météo paris jeudi soir"),
    dict(id="w_iris_post", at=t(12, "22:21"), kind="visit", text="iris.nakamura — publication", url="fil.social/iris.nakamura/p/8812",
         summary="Publié à 22:17. Une photo floue de la vitrine vide sous la poursuite : « Scène surréaliste au gala Éclats : noir total, "
                 "et le collier Aurore a DISPARU. Je suis sous le choc. » 12 400 j'aime. Commentaires : « c'est elle qui a fait le coup pour le buzz 😂 », "
                 "« la régie a coupé exprès ?? »."),
    dict(id="w14", at=t(12, "22:38"), kind="search", text="vol bijou exposition prêteur assurance qui est indemnisé"),
    dict(id="w15", at=t(12, "22:57"), kind="search", text="extra intérim sans contrat droits"),
]

# ---------------------------------------------------------------- live events
LIVE_AT = t(12, "23:25")
def live_at(after):
    total = 23 * 60 + 25 + after // 60
    return t(12, f"{total // 60:02d}:{total % 60:02d}")

def live_msg(eid, after, conv_id, frm, text, title, mid):
    return dict(id=eid, afterSeconds=after, kind="message", app="messages", title=title, body=text,
                conversation=conv_id, message=dict(id=mid, **{"from": frm}, at=live_at(after), text=text),
                opens=f"message:{mid}")

live = [
    live_msg("lv01", 25, "c_team", "helene", "La police veut la liste de tout le personnel avec les horaires. Tu l'as ?",
             "Éclats — équipe gala — Hélène", "m_live_helene_list"),
    dict(id="lv02", afterSeconds=75, kind="call", app="phone", title="Appel manqué", body="Adrien Sterne",
         call=dict(id="k_lv_sterne", contact="sterne", direction="missed", at=live_at(75), durationSeconds=0), opens="call:k_lv_sterne"),
    live_msg("lv03", 130, "c_sterne", "sterne", "Chère Salomé, je suis anéanti. Mon avocat vous contactera demain. A. S.",
             "Adrien Sterne", "m_live_sterne_lawyer"),
    live_msg("lv04", 190, "c_iris", "iris", "je suis désolée pour le post, j'aurais pas dû 🙏", "Iris Nakamura", "m_live_iris_sorry"),
    live_msg("lv05", 250, "c_victor", "victor", "Je leur ai donné le conducteur. Ils me regardent comme si c'était moi.",
             "Victor Almeida", "m_live_victor_cue"),
    dict(id="lv06", afterSeconds=310, kind="reminder", app="calendar", title="Demain 09:00",
         body="Point presse Éclats · Pavillon Mercure", opens="calendar:c_presse"),
    live_msg("lv07", 370, "c_josiane", "josiane", "Monsieur Sterne a récupéré son manteau au vestiaire à 22h35, il était pressé",
             "Josiane Petit", "m_live_josiane_coat"),
    dict(id="lv08", afterSeconds=430, kind="call", app="phone", title="Appel manqué", body="Relais Intérim",
         call=dict(id="k_lv_agence", contact="agence", direction="missed", at=live_at(430), durationSeconds=0), opens="call:k_lv_agence"),
]
LEVELS = {"lv02": "important", "lv03": "important", "lv05": "important"}
for e in live:
    e["level"] = LEVELS.get(e["id"], "normal")

device = dict(
    id="dev_salome", label="Téléphone de Salomé", model="iPhone 16 Pro", lockedApps=[],
    contacts=contacts, conversations=convs, calls=calls, places=places, tracks=tracks, photos=photos,
    calendar=calendar, notes=notes, mails=mails, browser=browser, liveEvents=live,
    wallpaper="gold", batteryPercent=31,
)

# ---------------------------------------------------------------- suspects
suspects = [
    dict(id="s_enzo", contact="enzo", role="Extra serveur, embauché le jour même", age=23, address="Aubervilliers",
         statement="« J'ai paniqué, je travaillais sans être déclaré. Je n'ai rien pris. »",
         alibi="Pendant les 90 secondes de noir, Enzo était au vestiaire avec Josiane Petit, la lampe de son téléphone allumée pour qu'elle voie les tickets.",
         alibiEvidence="e_enzo_alibi",
         trap="Il s'est enfui par la sortie de service à 22:18. Mais il fuyait un contrat qui n'existait pas encore, pas la police.",
         verdict="Enzo Barros n'a rien pris. Il a fui parce que son contrat de mission n'était pas encore établi et qu'il se croyait en faute. Pendant tout le noir, il tenait la lampe de son téléphone au vestiaire, à côté de Josiane."),
    dict(id="s_victor", contact="victor", role="Régisseur lumière du Pavillon", age=47, address="Montreuil",
         statement="« Je n'ai fait qu'exécuter le conducteur. Le noir était prévu. »",
         alibi="À 22:15, Victor photographiait sa console en régie, sur la mezzanine, à trente mètres de la vitrine 4 : le noir était le top « Q47 » du conducteur.",
         alibiEvidence="e_victor_alibi",
         trap="C'est lui qui a « coupé le courant », et il avait plaisanté sur un noir en plein discours. Mais il n'a fait qu'exécuter un effet commandé par quelqu'un d'autre.",
         verdict="Victor Almeida a lancé le noir, mais il ne l'a pas inventé : c'était écrit dans le conducteur envoyé à 19:40, « à la demande de M. Sterne ». Pendant les 90 secondes, il était en régie, à trente mètres de la vitrine."),
    dict(id="s_iris", contact="iris", role="Animatrice de la soirée", age=34, address="Paris 11e",
         statement="« J'étais sur scène, au micro, pendant tout le noir. »",
         alibi="Iris n'a pas quitté son micro sur pied pendant le noir : un invité du premier rang, à deux mètres, l'a photographiée à 22:14 et l'a entendue parler jusqu'au retour de la lumière.",
         alibiEvidence="e_iris_alibi",
         trap="Elle avait demandé qu'on lui ouvre la vitrine 4, et elle a annoncé la disparition en ligne trois minutes après. Une journaliste qui a flairé le scoop, pas une voleuse.",
         verdict="Iris Nakamura voulait un gros plan, puis un scoop. Rien de plus. Pendant les 90 secondes, elle parlait au micro, sur scène, à une vingtaine de mètres de la vitrine 4."),
    dict(id="s_sterne", contact="sterne", role="Collectionneur, propriétaire du collier", age=61, address="Avenue Foch, Paris 16e",
         statement="« J'étais près de la vitrine quand la lumière s'est éteinte. Je n'ai rien vu. Ce collier était toute ma vie. »",
         verdict="Adrien Sterne a organisé la disparition de son propre collier. Le vrai avait été remplacé par une copie à 17:30, pendant les vingt minutes qu'il avait exigées « seul » avec son joaillier. Le noir de 22:14, c'est lui qui l'avait commandé ; la vitrine, il l'a ouverte avec son double de la clé."),
]

# ---------------------------------------------------------------- evidence
evidence = [
    dict(id="e_pearls", title="41 perles au lieu de 43", importance="key", suspects=["s_sterne"],
         refs=["photoInfo:p_vitrine_1752", "mail:mail_expertise"],
         meaning="Sur la photo de 17:52, le collier n'a que 41 perles et le fermoir est caché ; le constat de l'expert en compte 43, fermoir de face. Bien avant le noir, la vitrine 4 ne contenait déjà plus le vrai collier."),
    dict(id="e_swap_slot", title="Vingt minutes, seuls", importance="key", suspects=["s_sterne"],
         refs=["calendar:c_sterne_1730"],
         meaning="La seule ouverture de la vitrine 4 entre la pose (16:05) et la photo de 17:52 : M. Sterne et « son joaillier », seuls, de 17:30 à 17:50. C'est là que la copie a remplacé le vrai collier."),
    dict(id="e_cue", title="Le noir était commandé", importance="key", suspects=["s_sterne", "s_victor"],
         refs=["mail:mail_conducteur"],
         meaning="« 22:14:00 — NOIR TOTAL 90 s. À la demande de M. Sterne : ne pas prévenir la salle. » La « panne » était un effet exigé par le prêteur."),
    dict(id="e_key", title="Le double de la clé", importance="key", suspects=["s_sterne"],
         refs=["message:m_sterne_key"],
         meaning="Seuls Salomé et Adrien Sterne avaient une clé de la vitrine 4. Elle n'a pas été forcée."),
    dict(id="e_insurance", title="4,2 millions", importance="key", suspects=["s_sterne"],
         refs=["mail:mail_avenant"],
         meaning="Trois semaines avant le gala, la valeur assurée de l'Aurore passe de 1,8 à 4,2 M€, à la demande du prêteur, sur l'estimation de son propre joaillier. C'est le mobile."),
    dict(id="e_position", title="Seul près de la vitrine", importance="supporting", suspects=["s_sterne", "s_iris"],
         refs=["photoInfo:p_room_2213"],
         meaning="Une minute avant le noir, Adrien Sterne se tient seul contre la vitrine 4, la main dans la poche — là où il garde sa clé. Iris, elle, est sur scène."),
    dict(id="e_debts", title="La dispersion Sterne", importance="supporting", suspects=["s_sterne"],
         refs=["browser:w_gazette"],
         meaning="Sterne vend douze pièces, son hôtel particulier est hypothéqué : il a besoin d'argent, vite."),
    dict(id="e_no_force", title="Ouverte avec une clé", importance="supporting", suspects=["s_sterne"],
         refs=["photoInfo:p_vitrine_2216"],
         meaning="La porte de la vitrine est entrouverte, la serrure intacte : quelqu'un l'a ouverte avec une clé, dans le noir, puis l'a mal refermée."),
    dict(id="e_coat", title="Le manteau", importance="supporting", suspects=["s_sterne"],
         refs=["message:m_live_josiane_coat"],
         meaning="À 22:35, Adrien Sterne récupère son manteau en hâte. C'est dans sa doublure que la copie sera retrouvée."),
    dict(id="e_enzo_alibi", title="L'alibi d'Enzo", importance="supporting", suspects=["s_enzo"],
         refs=["message:m_josiane_2240"],
         meaning="Enzo était au vestiaire avec Josiane pendant tout le noir, la lampe de son téléphone allumée."),
    dict(id="e_victor_alibi", title="L'alibi de Victor", importance="supporting", suspects=["s_victor"], anyOf=True,
         refs=["photoInfo:p_regie_2215", "message:m_victor_2216"],
         meaning="À 22:15, Victor est en régie, sur la mezzanine, devant sa console : « Q47 — NOIR 90 s ». Il exécutait le conducteur."),
    dict(id="e_iris_alibi", title="L'alibi d'Iris", importance="supporting", suspects=["s_iris"], anyOf=True,
         refs=["photoInfo:p_stage_2214", "message:m_samir_2226"],
         meaning="Iris est au micro sur pied quand tout s'éteint, et elle ne le lâche pas : Samir, au premier rang, l'entend parler pendant les 90 secondes."),
    dict(id="f_enzo_fled", title="La fuite de l'extra", importance="falseLead", suspects=["s_enzo"],
         refs=["message:m_team_2219"],
         meaning="Enzo s'est enfui, mais par peur : son contrat de mission ne devait être établi que le lendemain."),
    dict(id="f_victor_cut", title="« C'est Victor qui a coupé ? »", importance="falseLead", suspects=["s_victor"],
         refs=["message:m_helene_2217"],
         meaning="Victor a bien lancé le noir, mais c'était un top du conducteur, demandé par M. Sterne."),
    dict(id="f_victor_joke", title="« Un noir en plein discours »", importance="falseLead", suspects=["s_victor"],
         refs=["message:m_team_victor_joke"],
         meaning="Une blague de régisseur fâché pour des heures supplémentaires. Rien à voir avec le noir de 22:14."),
    dict(id="f_iris_access", title="Le gros plan d'Iris", importance="falseLead", suspects=["s_iris"],
         refs=["message:m_iris_access"],
         meaning="Iris voulait une belle image pour ses abonnés. On le lui a refusé, et elle n'a jamais approché la vitrine."),
    dict(id="f_iris_post", title="Le post de 22:17", importance="falseLead", suspects=["s_iris"],
         refs=["browser:w_iris_post"],
         meaning="Annoncer la disparition si vite ressemble à un aveu. C'est seulement le réflexe d'une journaliste suivie par des milliers de personnes."),
]

hints = [
    dict(id="h1", text="Et si le collier avait disparu avant le noir ?", scoreCost=0),
    dict(id="h2", text="Comparez la photo de la vitrine prise à 17:52 avec le constat de l'expert, dans vos mails.", scoreCost=8),
    dict(id="h3", text="Qui a eu la vitrine ouverte pour lui seul, et qui a demandé le noir ? Le conducteur de Victor le dit.",
         scoreCost=15, unlockAtRemainingSeconds=120),
]

solution = dict(
    culprit="s_sterne",
    headline="Adrien Sterne a volé son propre collier, deux fois.",
    summary="Le noir n'était pas une panne, et le collier exposé n'était déjà plus le vrai.",
    reveal=[
        dict(at=o(20, "15:12"), text="La valeur assurée de l'Aurore passe de 1,8 à 4,2 M€, à la demande du prêteur", evidence="e_insurance"),
        dict(at=o(29, "09:12"), text="Sterne garde le double de la clé de la vitrine 4", evidence="e_key"),
        dict(at=t(9, "19:34"), text="Il disperse douze pièces : sa maison est hypothéquée", evidence="e_debts"),
        dict(at=t(12, "17:30"), text="Vingt minutes seul avec « son joaillier », vitrine 4 ouverte", evidence="e_swap_slot"),
        dict(at=t(12, "17:52"), text="La photo pour les réseaux : 41 perles, fermoir caché. Le constat en comptait 43", evidence="e_pearls"),
        dict(at=t(12, "19:40"), text="Le conducteur : « NOIR TOTAL 90 s — à la demande de M. Sterne »", evidence="e_cue"),
        dict(at=t(12, "22:13"), text="Sterne se tient seul près de la vitrine 4, la main dans la poche", evidence="e_position"),
        dict(at=t(12, "22:16"), text="La vitrine est entrouverte, la serrure intacte : ouverte avec une clé", evidence="e_no_force"),
    ],
    story=[
        "Adrien Sterne est ruiné. Son hôtel particulier de l'avenue Foch est hypothéqué, il disperse douze pièces à Drouot. Il lui reste l'Aurore — et un acheteur privé, à l'étranger, prêt à la payer sans poser de questions.",
        "En octobre, il prête le collier à l'exposition « Éclats ». Puis il fait réévaluer la pièce par son propre joaillier, Marc Kessler : Valmont Art porte la valeur assurée de 1,8 à 4,2 M€. Il exige de garder le double de la clé de la vitrine 4.",
        "Le 12 novembre, à 17:30, il obtient vingt minutes « seul » avec son joaillier, vitrine ouverte, pour un « dernier nettoyage ». Le vrai collier repart dans une mallette ; une copie prend sa place. Le copiste a oublié deux perles, et Kessler a tourné le fermoir vers le fond pour cacher l'imitation. À 17:52, Salomé la photographie sans rien remarquer.",
        "Quelques jours plus tôt, il a obtenu de Victor un « effet de révélation » : 90 secondes de noir total à 22:14, sans prévenir la salle. Salomé n'a jamais ouvert le conducteur.",
        "À 22:14, dans le noir, il ouvre la vitrine avec son double, empoche la copie et referme mal. À 22:15:30, la poursuite éclaire une vitrine vide. L'extra s'enfuit, le régisseur est montré du doigt, l'animatrice poste la nouvelle : tout le monde regarde ailleurs. Sterne appelle Salomé à 22:31, anéanti.",
        "À 22:35, il récupère son manteau au vestiaire, pressé de partir. La police l'arrête à la porte. La copie de 41 perles est dans la doublure. L'assurance aurait payé 4,2 millions pour un collier déjà vendu.",
    ],
)

# ---------------------------------------------------------------- opening sequence
intro = dict(shots=[
    dict(kind="scene", seconds=7, scene="gala", camera="push", ambience=["hall"],
         lines=[dict(text="PAVILLON MERCURE · JEUDI 12 NOVEMBRE · 22:13", at=0.3),
                dict(text="Mesdames et messieurs… dans quelques instants, le collier Aurore.", at=2.4, speaker="Iris Nakamura", voiced=True)]),
    dict(kind="scene", seconds=4, scene="vitrine", camera="push", ambience=["hall"]),
    dict(kind="scene", seconds=5, scene="gala", camera="still", effect="blackout", ambience=["hall"],
         cues=[dict(sound="powerdown", at=0.3), dict(sound="sting", at=1.2)],
         lines=[dict(text="22:14", at=0.5)]),
    dict(kind="scene", seconds=4.5, scene="vitrine_empty", camera="push", ambience=["crowd"],
         lines=[dict(text="La vitrine 4 est vide.", at=1.2)]),
    dict(kind="phoneOnTable", seconds=6.5, time="2026-11-12 22:31", surface="marble", label="Salon d'honneur — 22:31", ambience=["crowd"],
         cues=[dict(sound="vibrate", at=0.6), dict(sound="notification", at=0.65), dict(sound="notification", at=1.9), dict(sound="ring", at=3.2)],
         notifications=[dict(app="messages", title="Victor Almeida", body="C'était pas une panne. Personne t'a prévenue ??", at=0.6),
                        dict(app="messages", title="Éclats — équipe gala", body="Hélène : la police est là", at=1.9),
                        dict(app="phone", title="Adrien Sterne", body="Appel entrant", at=3.2, call=True)]),
    dict(kind="unlock", seconds=2.4),
])

case = dict(
    schemaVersion=1, id="case_004", number=4, title="90 SECONDES",
    tagline="Quatre-vingt-dix secondes de noir. Un collier de 4 millions.",
    synopsis=[
        "Jeudi 12 novembre, gala d'ouverture de l'exposition « Éclats — joaillerie du XXᵉ siècle » au Pavillon Mercure, à Paris. Pièce maîtresse : le collier Aurore, 1928, prêté par le collectionneur Adrien Sterne.",
        "À 22h14, la salle plonge dans le noir pendant 90 secondes. Quand la lumière revient, la vitrine 4 est vide. Aucune effraction.",
        "La commissaire de l'exposition, Salomé Tessier, vous confie son téléphone. Tout le monde a une théorie.",
    ],
    objective="Découvrir qui a fait disparaître le collier Aurore.",
    difficulty=1, durationSeconds=480, phoneStartTime=LIVE_AT,
    challengeDurations={"investigator": 900, "detective": 480, "expert": 300},
    introScene=intro,
    devices=[device], suspects=suspects, evidence=evidence, hints=hints, solution=solution,
)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(case, f, ensure_ascii=False, indent=1)
n_msgs = sum(len(c["messages"]) for c in convs)
print(f"case_004: {len(contacts)} contacts, {len(convs)} conversations, {n_msgs} messages, {len(calls)} calls, "
      f"{len(photos)} photos, {len(calendar)} events, {len(notes)} notes, {len(mails)} mails, {len(browser)} web, "
      f"{len(places)} places, {len(tracks)} tracks, {len(live)} live events")
