# Generates ScreenshotKit/Sources/CaseLibrary/Resources/Cases/case_003.json
# Case #003 — APRÈS LA FÊTE. Night of Saturday 22 to Sunday 23 August 2026, a rented villa at Cap Ferret.
# Investigation starts Sunday 23 August, 11:40 (Jeanne hands her phone to the gendarmes).
#
# Truth: Maxime (Jeanne's partner) has a secret affair with Diane (Paul's wife). At 01:49 Diane posts
# by mistake in the family group "tu descends ? il dort. escalier de la plage" and deletes it one
# minute later. Paul read it. Around 02:10-02:15, on the stone stairs down to the beach, Paul confronts
# Maxime, who pushes him. Louise's long-exposure star photos from the terrace (02:06, 02:14, 02:27)
# show Diane asleep on the sofa, then two figures on the stairs, one in yellow (only Maxime wore
# yellow, see the 23:40 group photo). At 02:21 Jeanne wakes up alone; Maxime claims he is drinking
# a glass of water downstairs.
import json, sys

OUT = sys.argv[1]
Y = 2026
def t(day, hm, month=8):
    return f"{Y}-{month:02d}-{day:02d} {hm}"

# ---------------------------------------------------------------- contacts
contacts = [
    dict(id="me", name="Jeanne Castaing", phone="+33 6 12 48 90 37", relation="Moi", email="jeanne@castaing-interieurs.fr",
         birthday="22/08/1996", avatarHue=0.07, isOwner=True),
    dict(id="maxime", name="Maxime Rivière", phone="+33 6 74 31 08 52", relation="Compagnon",
         email="maxime.riviere@mailo.fr", avatarHue=0.60),
    dict(id="paul", name="Paul Castaing", phone="+33 6 20 57 13 84", relation="Frère", avatarHue=0.52),
    dict(id="diane", name="Diane Lesage", phone="+33 6 88 12 46 09", relation="Belle-sœur", avatarHue=0.86),
    dict(id="louise", name="Louise Ferrer", phone="+33 6 45 09 71 26", relation="Meilleure amie",
         email="louise@ferrer-photo.fr", avatarHue=0.33),
    dict(id="gregoire", name="Grégoire Salles", phone="+33 6 31 66 25 70", relation="Associé de Paul (école de surf)",
         avatarHue=0.15),
    dict(id="mamie", name="Mamie Odette", phone="+33 5 56 83 14 22", relation="Grand-mère", avatarHue=0.95),
    dict(id="maman", name="Maman", phone="+33 6 07 44 19 63", relation="Mère", avatarHue=0.02),
    dict(id="papa", name="Papa", phone="+33 6 07 44 20 81", relation="Père", avatarHue=0.64),
    dict(id="nour", name="Nour Benali", phone="+33 7 62 18 90 45", relation="Amie", avatarHue=0.42),
    dict(id="basile", name="Basile Morin", phone="+33 6 53 27 84 16", relation="Ami (copain de Nour)", avatarHue=0.24),
    dict(id="chloe", name="Chloé Darrigade", phone="+33 6 29 70 35 48", relation="Castaing Intérieurs — associée",
         email="chloe@castaing-interieurs.fr", avatarHue=0.78),
    dict(id="laborde", name="Mme Laborde", phone="+33 6 84 52 07 31", relation="Chantier Caudéran", avatarHue=0.48),
    dict(id="seb", name="Seb Carrelage", phone="+33 6 16 93 42 58", relation="Artisan carreleur", avatarHue=0.10),
    dict(id="dubroca", name="M. Dubroca — Villa Les Oyats", phone="+33 6 72 05 61 39", relation="Loueur de la villa",
         avatarHue=0.56),
    dict(id="colis", name="ColiPoint", phone="36 12", avatarHue=0.20),
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

# --- Maxime (partner, culprit): short sentences, "ok", "bisous", never an emoji
conv("c_maxime", ["maxime"], [
    ("maxime", t(9, "18:40", 7), "je pars demain 17h. retour dimanche soir."),
    ("me", t(9, "18:42", 7), "le séminaire tombe VRAIMENT un week-end ?? 🙄"),
    ("maxime", t(9, "18:51", 7), "oui. c'est l'équipe de Paris qui a choisi."),
    ("me", t(9, "18:52", 7), "ok ok... ramène-moi un gâteau basque alors 😘"),
    ("maxime", t(10, "21:14", 7), "bien arrivé."),
    ("me", t(10, "21:20", 7), "tu me manques déjà 🥺🥺"),
    ("maxime", t(11, "23:48", 7), "journée longue. je dors. bisous"),
    ("me", t(12, "11:20", 7), "t'as vu la photo de Diane sur le groupe ?? elle est à Biarritz aussi 😂 vous vous êtes croisés ?"),
    ("maxime", t(12, "13:05", 7), "non. c'est grand biarritz."),
    ("maxime", t(12, "22:31", 7), "rentré. tu dors ?"),
    ("maxime", t(15, "08:20", 7), "tu peux récupérer mon costume au pressing. ticket dans l'entrée."),
    ("me", t(15, "08:34", 7), "à vos ordres 🫡"),
    ("me", t(20, "18:02", 7), "yoga ce soir, mange sans moi !! 🧘‍♀️"),
    ("maxime", t(20, "18:10", 7), "ok"),
    ("maxime", t(28, "17:45", 7), "dîner avec l'équipe ce soir. je rentre tard."),
    ("me", t(28, "17:47", 7), "ok ! prends du pain en rentrant si t'es pas mort 🥖"),
    ("maxime", t(6, "12:30"), "voiture de location réservée pour le vendredi 21. 18h30 à la gare."),
    ("me", t(6, "12:31"), "trop bien merci mon cœur ❤️❤️"),
    ("me", t(13, "21:05"), "Diane m'a dit que Paul et elle ça va pas fort en ce moment 😕 tu trouves pas Paul bizarre ?"),
    ("maxime", t(13, "21:40"), "non. fatigué c'est tout."),
    ("maxime", t(18, "19:22"), "tu veux quoi pour tes 30 ans. vraiment."),
    ("me", t(18, "19:25"), "RIEN !!! juste vous tous là-bas 🥹"),
    ("maxime", t(18, "19:26"), "ok"),
    ("me", t(21, "18:48"), "t'es où ?? on part à 19h max sinon bouchons 😩"),
    ("maxime", t(21, "18:55"), "je sors. 10 min."),
    ("maxime", t(22, "15:58"), "je pars chercher Mamie."),
    ("me", t(22, "15:59"), "prends la glace à la supérette en revenant stp 🙏🍦"),
    ("maxime", t(22, "16:00"), "ok"),
    ("me", t(22, "23:08"), "GÂTEAU dans 5 min viens !!! 🎂"),
    ("maxime", t(22, "23:09"), "j'arrive"),
    ("me", t(23, "01:45"), "je monte 😴 tu viens ?"),
    ("maxime", t(23, "01:46"), "j'arrive"),
    ("me", t(23, "02:21"), "t'es où ?", dict(id="m_max_0221")),
    ("maxime", t(23, "02:23"), "en bas, je bois un verre d'eau, j'arrive", dict(id="m_max_0223")),
    ("maxime", t(23, "10:58"), "les gendarmes veulent parler à tout le monde un par un. je suis sur la terrasse."),
    ("me", t(23, "11:02"), "ok j'arrive"),
])

# --- Paul (brother, victim): sober, no emoji
conv("c_paul", ["paul"], [
    ("paul", t(8, "20:12", 7), "Dis à Maman que je l'appelle ce week-end. Semaine de fou à l'école."),
    ("me", t(8, "20:30", 7), "dis-lui toi-même 😤 elle me demande tous les jours"),
    ("paul", t(8, "20:31", 7), "Je sais."),
    ("paul", t(21, "20:58", 7), "Grégoire veut racheter mes parts. Il m'a mis un chiffre sur la table hier soir. Ça fait des semaines qu'il me met la pression.",
     dict(id="m_paul_parts")),
    ("me", t(21, "21:02", 7), "quoi ?? mais c'est TON école !!"),
    ("paul", t(21, "21:05", 7), "C'est notre école. Il dit que je suis plus assez là. Je t'appelle."),
    ("paul", t(24, "18:15", 7), "Demain 10h au poste. Maillot une pièce, crème, et tu écoutes Grégoire."),
    ("me", t(24, "18:20", 7), "oui coach 🏄‍♀️"),
    ("me", t(25, "19:40", 7), "j'ai mal PARTOUT 😭😭 merci c'était génial"),
    ("paul", t(25, "19:52", 7), "Tu reviens quand tu veux."),
    ("paul", t(3, "21:17"), "Louise me doit toujours 3000, elle m'évite. Tu peux lui en parler ?", dict(id="m_paul_debt")),
    ("me", t(3, "21:30"), "oh Paul... elle galère avec le studio en ce moment 😕"),
    ("paul", t(3, "21:31"), "Moi aussi je galère. Ça fait huit mois."),
    ("me", t(3, "21:33"), "ok je lui en parle"),
    ("me", t(10, "18:40"), "Maman m'a demandé de t'en parler... ils veulent vendre la maison du Pyla 😢 appelle-la stp"),
    ("paul", t(10, "19:15"), "Elle m'a appelé. On en parle au Ferret."),
    ("paul", t(17, "12:04"), "On arrive samedi vers 14h. Je prends les planches, Grégoire aussi."),
    ("me", t(17, "12:10"), "yesss 🌊🌊"),
    ("paul", t(17, "12:11"), "Diane demande s'il faut des draps."),
    ("me", t(17, "12:12"), "non tout est fourni !!"),
    ("paul", t(22, "20:14"), "Il reste du rosé dans la glacière du garage."),
    ("paul", t(23, "01:58"), "t'es réveillée ?", dict(id="m_paul_0158", unread=True)),
    ("paul", t(23, "02:01"), "Jeanne. Faut que je te parle. C'est grave.", dict(id="m_paul_0201", unread=True)),
    ("paul", t(23, "02:03"), "laisse tomber. je règle ça moi-même.", dict(id="m_paul_0203", unread=True)),
])

# --- Diane (sister-in-law): friendly, a few emojis
conv("c_diane", ["diane"], [
    ("diane", t(3, "13:10", 7), "Coucou ! Tu me redonnes le nom de ta coloriste ? 💇‍♀️"),
    ("me", t(3, "13:25", 7), "Léa, à l'Atelier Mèche, rue Notre-Dame !! dis que tu viens de ma part"),
    ("diane", t(3, "13:26", 7), "merci ma belle 😘"),
    ("diane", t(30, "10:02", 7), "pour ton anniv je m'occupe du gâteau avec Louise, t'as pas le droit de demander 🤫"),
    ("me", t(30, "10:05", 7), "😍😍😍"),
    ("diane", t(11, "22:48"), "Paul est infernal en ce moment. il dort plus, il parle plus. désolée de te dire ça à toi"),
    ("me", t(11, "22:55"), "oh non 😔 c'est l'école ? Grégoire ?"),
    ("diane", t(11, "23:10"), "jsp. peut-être."),
    ("diane", t(20, "20:31"), "robe bleue ou robe verte pour samedi ? 😅 vote"),
    ("me", t(20, "20:33"), "LA BLEUE !!"),
    ("diane", t(20, "20:34"), "ok bleue 💙"),
    ("diane", t(22, "12:50"), "on part de Lacanau, arrivée vers 14h 🚗"),
    ("diane", t(23, "08:02"), "on part au CHU avec Grégoire derrière l'hélico. je t'appelle dès que je sais quelque chose"),
])

# --- Louise (best friend, photographer): lowercase, warm, "ma louloute"
conv("c_louise", ["louise"], [
    ("louise", t(6, "19:02", 7), "Jeannette !!! le studio a ENFIN l'électricité ⚡️"),
    ("me", t(6, "19:10", 7), "ENFIN 🎉🎉 champagne"),
    ("louise", t(14, "12:40", 7), "shooting mariage samedi à Saint-Émilion, 36° annoncés, je vais fondre"),
    ("me", t(14, "12:45", 7), "bois de l'eau et mets un chapeau !!"),
    ("louise", t(27, "09:15", 7), "tu me prêtes ta voiture jeudi ? la mienne est encore au garage 😩"),
    ("me", t(27, "09:20", 7), "oui tkt, les clés sont chez la gardienne"),
    ("me", t(4, "18:52"), "Louise... Paul m'a encore parlé des 3000 😕 t'en es où ?"),
    ("louise", t(4, "18:58"), "je sais je sais. je lui ai fait un virement de 300 en juin. je peux pas plus là."),
    ("louise", t(4, "18:59"), "il me regarde comme si je l'avais volé"),
    ("me", t(4, "19:02"), "je suis entre vous deux, c'est horrible 😣 je t'appelle"),
    ("louise", t(15, "16:20"), "j'ai trouvé ton cadeau 🤫🤫"),
    ("me", t(15, "16:21"), "noooon dis-moi !!"),
    ("louise", t(15, "16:21"), "jamais"),
    ("louise", t(21, "17:30"), "j'apporte le trépied : ciel dégagé samedi et la lune se couche vers 1h. parfait pour les étoiles 🌌"),
    ("louise", t(22, "23:02"), "il m'a encore sorti le coup des 3000 devant tout le monde. je sors prendre l'air 2 min"),
    ("me", t(22, "23:03"), "je suis désolée 😣 viens on fait le gâteau dans 5 min"),
    ("me", t(23, "01:44"), "je vais me coucher je suis morte 🥲 merci pour tout ma louloute", dict(id="m_lou_0144")),
    ("louise", t(23, "01:45"), "dors bien la trentenaire 🖤 moi je reste un peu sur la terrasse, le ciel est dingue"),
    ("louise", t(23, "02:34"), "ton ciel de 30 ans ✨", dict(photo="p_louise_0206")),
    ("louise", t(23, "02:34"), None, dict(photo="p_louise_0214")),
    ("louise", t(23, "02:35"), "je t'en fais un tirage. bonne nuit ❤️", dict(photo="p_louise_0227")),
    ("louise", t(23, "10:52"), "je suis dans le jardin si tu veux marcher un peu. je bouge pas."),
])

# --- Grégoire (Paul's partner): shares his location for the drive with Mamie
conv("c_gregoire", ["gregoire"], [
    ("gregoire", t(24, "12:30", 7), "Salut Jeanne ! Paul t'a dit ? cours demain 10h, je t'ai mise avec les débutants 😉"),
    ("me", t(24, "12:41", 7), "trop bien merci Greg !!"),
    ("gregoire", t(12, "09:48"), "Je peux ramener ma planche + un paddle samedi ? y a de la place au garage ?"),
    ("me", t(12, "10:02"), "oui oui tout ce que tu veux !!"),
    ("gregoire", t(23, "00:52"), "je ramène ta mamie à Arcachon, j'ai pas bu. je te partage ma position si tu veux suivre 👍"),
    ("me", t(23, "00:54"), "t'es un ange 🙏🙏 merci Greg"),
    ("gregoire", t(23, "01:06"), "c'est parti. elle a déjà mis la radio à fond 😂"),
    ("gregoire", t(23, "07:11"), "JEANNE DESCENDS VITE. C'EST PAUL", dict(id="m_greg_0711")),
    ("gregoire", t(23, "10:14"), "on est au CHU avec Diane. ils l'ont pris direct en réa. je te dis dès que je sais"),
])

# --- Mamie Odette: "..." everywhere, always signs
conv("c_mamie", ["mamie"], [
    ("mamie", t(16, "10:12", 7), "Ma chérie... Tu viens toujours déjeuner dimanche ?... Mamie"),
    ("me", t(16, "10:30", 7), "oui Mamie !! 12h30 ❤️"),
    ("mamie", t(2, "16:40"), "J'ai retrouvé des photos de vous deux petits... Paul avec son seau rouge... Je te les garde... Mamie"),
    ("mamie", t(16, "11:30"), "Qui vient me chercher samedi ?... Je serai prête à 17h... Mamie"),
    ("me", t(16, "11:34"), "c'est Maxime Mamie ! 17h pile 😘"),
    ("mamie", t(23, "02:07"), "Bien arrivée ma chérie... Grégoire est un amour. Bonne nuit. Mamie", dict(id="m_mamie_0207")),
    ("mamie", t(23, "02:09"), "Tu dors sûrement... Je t'embrasse fort... Mamie", dict(id="m_mamie_0209")),
    ("mamie", t(23, "09:05"), "Ta mère m'a appelée... Je ne comprends rien... Rappelle-moi ma chérie... Mamie"),
])

# --- Family group (Paul, Diane, Maxime, Mamie)
conv("c_family", ["paul", "diane", "maxime", "mamie"], [
    ("diane", t(12, "11:02", 7), "week-end entre filles à Biarritz 🌊", dict(id="m_fam_biarritz", photo="p_diane_biarritz")),
    ("mamie", t(12, "11:10", 7), "Que c'est beau... Profitez bien... Mamie"),
    ("paul", t(12, "11:25", 7), "Profite."),
    ("mamie", t(19, "18:20", 7), "Merci pour ce déjeuner mes chéris... Mamie"),
    ("paul", t(25, "12:10", 7), "Jeanne a tenu debout quatre secondes sur la planche. Record familial.", dict(photo="p_paul_surf")),
    ("me", t(25, "12:14", 7), "3 secondes 8 c'est pas pareil 😤😂"),
    ("diane", t(25, "12:20", 7), "championne 🏆"),
    ("me", t(5, "20:05"), "Rappel : 22 août au Cap Ferret !!! Mamie on vient te chercher 😘"),
    ("mamie", t(5, "20:40"), "Je note sur mon calendrier... Mamie"),
    ("maxime", t(5, "20:44"), "ok"),
    ("diane", t(20, "19:15"), "on apporte quoi ? 🍾"),
    ("me", t(20, "19:18"), "rien juste vous !!"),
    ("diane", t(20, "19:19"), "on apporte du champagne alors 😂"),
    ("diane", t(23, "01:49"), "tu descends ? il dort. escalier de la plage 🖤",
     dict(id="m_fam_0149", deletedAt=t(23, "01:50"))),
    ("mamie", t(23, "09:31"), "Votre mère vient de m'appeler... Qu'est-ce qui s'est passé... Personne n'a rien entendu ?... Mamie"),
    ("diane", t(23, "09:40"), "j'ai dormi à côté de lui toute la nuit, je comprends pas", dict(id="m_fam_diane_0940")),
    ("maxime", t(23, "09:44"), "on sait pas encore. les gendarmes sont là."),
    ("mamie", t(23, "09:50"), "Je prie pour lui... Mamie"),
], title="Les Castaing ☀️")

# --- Party group
P = ["paul", "diane", "maxime", "louise", "gregoire", "nour", "basile"]
conv("c_party", P, [
    ("louise", t(1, "11:02"), "groupe créé pour les 30 ans de notre Jeannette 🎂 (elle est dedans, elle sait, c'est pas une surprise 😂)"),
    ("me", t(1, "11:05"), "hâte !!!! villa réservée au Ferret le samedi 22, dodo sur place pour ceux qui veulent 🏡"),
    ("nour", t(1, "11:20"), "on vient mais on dort pas, Basile bosse le dimanche"),
    ("basile", t(1, "11:24"), "dimanche 7h, oui 😩"),
    ("gregoire", t(8, "18:40"), "je ramène les planches, qui veut surfer le dimanche matin ?"),
    ("paul", t(8, "18:52"), "Moi."),
    ("louise", t(8, "19:01"), "moi je regarde 😂"),
    ("me", t(14, "21:10"), "playlist collaborative ! ajoutez vos sons 🎶"),
    ("nour", t(14, "21:18"), "j'ai mis 14 titres de Céline Dion désolée"),
    ("basile", t(14, "21:19"), "elle ment pas"),
    ("me", t(19, "20:02"), "Adresse : Villa Les Oyats, allée des Oyats, Cap Ferret. Code du portail 2208 (non c'est pas une blague) 😂"),
    ("louise", t(19, "20:10"), "qui s'occupe des glaçons ?"),
    ("maxime", t(19, "20:31"), "moi."),
    ("nour", t(22, "13:40"), "on part de Bordeaux, arrivée vers 15h ☀️"),
    ("me", t(22, "23:20"), "30 bougies je suis vieille 😭", dict(photo="p_cake")),
    ("basile", t(22, "23:22"), "joyeux anniv la doyenne"),
    ("nour", t(23, "00:31"), "on file ! merci pour cette soirée incroyable 🥹 bonne nuit les gens"),
    ("basile", t(23, "00:32"), "merci Jeanne, gros bisous, à très vite"),
    ("me", t(23, "00:33"), "merci d'être venus 🥹❤️ rentrez bien !!"),
    ("nour", t(23, "01:48"), "bien rentrés 😴"),
    ("gregoire", t(23, "03:18"), "rentré, désolé si le portail a grincé 🙏", dict(id="m_party_0318")),
    ("nour", t(23, "08:20"), "Jeanne ?? Louise m'a dit pour Paul. Dis-moi s'il faut quoi que ce soit, on peut revenir"),
    ("basile", t(23, "08:24"), "on pense fort à vous"),
], title="30 ans Jeannette 🎂")

conv("c_maman", ["maman"], [
    ("maman", t(7, "18:30", 7), "Tu as eu ton frère ? Il ne répond jamais"),
    ("me", t(7, "18:44", 7), "il est débordé avec l'école 🙄"),
    ("maman", t(29, "12:10", 7), "On décolle pour Porto le 14 ! On sera sages 😄"),
    ("me", t(29, "12:30", 7), "profitez !!!"),
    ("maman", t(9, "11:15"), "Ma chérie tu peux en parler à Paul, pour la maison du Pyla ? Papa n'ose pas"),
    ("me", t(9, "11:40"), "ok je lui en parle 😕"),
    ("maman", t(14, "19:22"), "Bien arrivés à Porto ! 32°"),
    ("maman", t(22, "09:02"), "JOYEUX ANNIVERSAIRE ma chérie !!! 30 ans... On est tristes de ne pas être là. On t'appelle ce soir ❤️"),
    ("maman", t(22, "09:05"), "Retrouvées dans le grenier avant de partir", dict(photo="p_old_2003")),
    ("maman", t(22, "09:05"), None, dict(photo="p_old_2005")),
    ("me", t(22, "09:30"), "merci maman ❤️❤️ vous me manquez, Paul avec son bob 😂"),
    ("me", t(23, "07:36"), "Maman appelle-moi dès que tu vois ça"),
    ("maman", t(23, "08:40"), "On cherche un vol. Papa est au téléphone avec la compagnie."),
])

conv("c_papa", ["papa"], [
    ("papa", t(15, "13:02"), "Porto. Ta mère a déjà acheté trois nappes.", dict(photo="p_porto")),
    ("me", t(15, "13:10"), "😂😂 classique"),
    ("papa", t(22, "08:30"), "Bon anniversaire ma grande. 30 ans. Je suis fier de toi. Papa"),
    ("me", t(22, "09:31"), "merci papa ❤️"),
    ("papa", t(23, "08:05"), "Ma chérie on rentre au plus vite. Tiens-nous au courant de tout. Papa"),
])

conv("c_nour", ["nour"], [
    ("nour", t(22, "21:10", 7), "t'as commencé la série dont je t'ai parlé ?"),
    ("me", t(22, "22:40", 7), "oui !! épisode 3 😱"),
    ("nour", t(22, "22:41", 7), "ATTENDS le 5"),
    ("nour", t(18, "12:15"), "on t'offre quoi, t'as pas le droit de dire rien"),
    ("me", t(18, "12:20"), "rien !!!"),
    ("nour", t(18, "12:21"), "ok donc un truc"),
])

conv("c_chloe", ["chloe"], [
    ("chloe", t(13, "09:12", 7), "Mme Laborde veut revoir le carrelage de la salle de bain 🙃"),
    ("me", t(13, "09:20", 7), "encore ?? 3e fois"),
    ("chloe", t(13, "09:21", 7), "elle hésite entre le zellige blanc et le vert sauge"),
    ("me", t(13, "09:25", 7), "demande à Seb de lui déposer les deux échantillons"),
    ("chloe", t(16, "11:22", 7), "Seb a déposé les échantillons", dict(photo="p_zellige")),
    ("chloe", t(30, "16:40", 7), "Je suis en congés du 3 au 16 août, tu gères Laborde ? 🙏"),
    ("me", t(30, "16:45", 7), "tkt"),
    ("chloe", t(17, "09:05"), "Je suis rentrée ! bronzée et pas du tout motivée 🥵"),
    ("chloe", t(21, "17:10"), "Bon week-end d'anniv !!! déconnecte vraiment stp 😘"),
    ("me", t(21, "17:12"), "promis 🥂"),
    ("chloe", t(23, "11:20"), "Jeanne, Louise m'a prévenue. Je décale tout lundi, t'occupe de rien. Je t'embrasse fort"),
])

conv("c_laborde", ["laborde"], [
    ("laborde", t(20, "09:48", 7), "Bonjour Jeanne, finalement le vert sauge me semble plus lumineux. Qu'en pensez-vous ?"),
    ("me", t(20, "10:10", 7), "Bonjour Madame Laborde, je trouve aussi 🙂 je lance la commande demain"),
    ("laborde", t(12, "17:30"), "Les carreaux sont posés, c'est magnifique. Merci à vous"),
    ("me", t(12, "17:42"), "Ravie !! je passe voir demain après-midi"),
])

conv("c_seb", ["seb"], [
    ("seb", t(16, "10:58", 7), "Échantillons déposés chez Mme Laborde. Le vert est plus foncé en vrai."),
    ("seb", t(6, "17:20"), "Pose finie mardi chez Laborde si le colis arrive"),
    ("me", t(6, "17:31"), "top merci Seb"),
])

conv("c_dubroca", ["dubroca"], [
    ("dubroca", t(19, "10:40"), "Bonjour Madame Castaing, les clés seront dans la boîte à code (4417). Attention à l'escalier de la plage le matin, il glisse avec la rosée."),
    ("me", t(19, "10:52"), "Merci beaucoup, à vendredi !"),
    ("me", t(21, "20:58"), "Bien arrivés, la villa est magnifique !!"),
    ("dubroca", t(21, "21:15"), "Parfait. Bon séjour. État des lieux dimanche 17h."),
    ("me", t(23, "10:30"), "Monsieur Dubroca, il y a eu un accident cette nuit, mon frère est tombé dans l'escalier de la plage. Les gendarmes sont là. Je vous rappelle."),
    ("dubroca", t(23, "10:41"), "Mon Dieu. Je suis vraiment désolé. Prenez tout le temps qu'il faut, oubliez l'état des lieux."),
])

conv("c_colis", ["colis"], [
    ("colis", t(18, "08:10"), "ColiPoint : votre colis n°CP77120 sera livré le lundi 24/08 à votre domicile (Bordeaux)."),
    ("colis", t(21, "14:02"), "ColiPoint : expéditeur Nour B. Message : « ne l'ouvre pas avant d'avoir 30 ans »."),
])

# ---------------------------------------------------------------- calls
calls = []
def call(cid, contact, direction, at, dur):
    calls.append(dict(id=cid, contact=contact, direction=direction, at=at, durationSeconds=dur))
call("k_c01", "maman", "incoming", t(7, "19:02", 7), 620)
call("k_c02", "maxime", "outgoing", t(11, "20:30", 7), 0)
call("k_c03", "chloe", "incoming", t(13, "09:40", 7), 184)
call("k_c04", "laborde", "incoming", t(20, "10:05", 7), 262)
call("k_c05", "paul", "outgoing", t(21, "21:08", 7), 842)
call("k_c06", "louise", "outgoing", t(4, "19:05"), 1320)
call("k_c07", "mamie", "outgoing", t(16, "11:40"), 412)
call("k_c08", "dubroca", "outgoing", t(19, "10:15"), 150)
call("k_c09", "maxime", "missed", t(21, "18:52"), 0)
call("k_c10", "nour", "incoming", t(22, "15:02"), 45)
call("k_c11", "maman", "incoming", t(22, "19:40"), 548)
call("k_mamie_0208", "mamie", "missed", t(23, "02:08"), 0)
call("k_paul_0209", "paul", "missed", t(23, "02:09"), 0)
call("k_greg_0711", "gregoire", "missed", t(23, "07:11"), 0)
call("k_greg_0712", "gregoire", "incoming", t(23, "07:12"), 220)
call("k_c12", "maman", "outgoing", t(23, "07:34"), 0)
call("k_c13", "maman", "incoming", t(23, "07:52"), 611)
call("k_c14", "papa", "incoming", t(23, "08:10"), 190)
call("k_c15", "nour", "missed", t(23, "08:18"), 0)
call("k_c16", "mamie", "outgoing", t(23, "09:55"), 380)
call("k_c17", "diane", "incoming", t(23, "10:20"), 142)
call("k_c18", "dubroca", "outgoing", t(23, "10:28"), 0)
call("k_c19", "gregoire", "incoming", t(23, "11:15"), 95)

# ---------------------------------------------------------------- places & tracks
# (id, name, kind, x, y, lat, lon, revealedBy)
PLACES = [
    ("pl_villa", "Villa Les Oyats — Cap Ferret", "home", 0.30, 0.46, 44.6365, -1.2470, None),
    ("pl_stairs", "Escalier de la plage (bas du jardin)", "street", 0.33, 0.49, 44.6362, -1.2455,
     ["photoInfo:p_louise_0214", "message:m_fam_0149"]),
    ("pl_pointe", "Plage de la Pointe", "park", 0.27, 0.53, 44.6280, -1.2500, None),
    ("pl_phare", "Phare du Cap Ferret", "park", 0.26, 0.42, 44.6428, -1.2491, None),
    ("pl_mamie", "Arcachon — chez Mamie", "home", 0.47, 0.44, 44.6590, -1.1690, ["message:m_mamie_0207"]),
    ("pl_lege", "Lège-Cap-Ferret", "district", 0.44, 0.30, 44.7350, -1.1950, None),
    ("pl_teste", "La Teste-de-Buch", "district", 0.52, 0.50, 44.6310, -1.1450, None),
    ("pl_chartrons", "Appartement — Chartrons, Bordeaux", "home", 0.90, 0.22, 44.8545, -0.5705, None),
    ("pl_agence", "Castaing Intérieurs — Bordeaux", "work", 0.88, 0.28, 44.8410, -0.5745, None),
    ("pl_chu", "CHU de Bordeaux — Pellegrin", "district", 0.84, 0.31, 44.8290, -0.6070, ["call:k_greg_0712"]),
    ("pl_surf", "École de surf Les Baïnes — Lacanau", "shop", 0.36, 0.06, 45.0010, -1.2010, None),
    ("pl_biarritz", "Biarritz — Côte des Basques", "street", 0.08, 0.95, 43.4790, -1.5660,
     ["calendar:c_biarritz", "photoInfo:p_diane_biarritz"]),
]
places = []
for pid, name, kind, x, y, lat, lon, rev in PLACES:
    pl = dict(id=pid, name=name, kind=kind, x=x, y=y, latitude=lat, longitude=lon)
    if rev: pl["revealedBy"] = rev
    places.append(pl)

tracks = [
    dict(id="t_me", contact="me", points=[
        dict(id="tp_me_1", at=t(21, "17:58"), place="pl_agence"),
        dict(id="tp_me_2", at=t(21, "18:40"), place="pl_chartrons"),
        dict(id="tp_me_3", at=t(21, "20:52"), place="pl_villa", note="Arrivée"),
        dict(id="tp_me_4", at=t(22, "10:44"), place="pl_phare"),
        dict(id="tp_me_5", at=t(22, "11:52"), place="pl_villa"),
        dict(id="tp_me_6", at=t(22, "16:30"), place="pl_pointe"),
        dict(id="tp_me_7", at=t(22, "18:55"), place="pl_villa"),
        dict(id="tp_me_8", at=t(23, "07:14"), place="pl_villa"),
    ]),
    dict(id="t_gregoire", contact="gregoire", points=[
        dict(id="tp_gr_1", at=t(23, "01:05"), place="pl_villa", note="Départ"),
        dict(id="tp_gr_2", at=t(23, "01:38"), place="pl_lege"),
        dict(id="tp_gr_3", at=t(23, "02:04"), place="pl_mamie", note="Arrêt 17 min"),
        dict(id="tp_gr_4", at=t(23, "02:31"), place="pl_teste"),
        dict(id="tp_gr_5", at=t(23, "03:14"), place="pl_villa", note="Arrivée"),
    ]),
]

# ---------------------------------------------------------------- photos
photos = []
def photo(pid, taken, scene, caption, details, source="camera", place=None, frm=None, received=None, device="iPhone 15",
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

# --- the decisive pictures
photo("p_group_2340", t(22, "23:40"), "group", "Photo de groupe devant la baie vitrée, au retardateur.",
      "Tout le monde pose devant la baie vitrée. Maxime porte un sweat jaune moutarde — le seul vêtement jaune de la photo. "
      "Paul est en chemise de lin blanche, Diane en robe bleue, Louise tient son appareil photo. Mamie est assise au premier rang, "
      "Grégoire derrière elle, Nour et Basile sur le côté.",
      place="Villa Les Oyats")
photo("p_louise_0206", t(23, "02:06"), "sky", "La Voie lactée au-dessus du toit de la villa, pose longue.",
      "Pose de 20 secondes, appareil sur trépied, prise depuis la terrasse. En bas du cadre, à travers la baie vitrée, "
      "dans le salon éclairé par une lampe, Diane dort sur le canapé, un plaid sur les jambes.",
      source="received", frm="louise", received=t(23, "02:34"), place="Villa Les Oyats — terrasse", device="iPhone 14 Pro",
      style="night")
photo("p_louise_0214", t(23, "02:14"), "garden_stairs", "Le ciel au-dessus du bassin, pose longue depuis la terrasse.",
      "Pose de 25 secondes. Au fond, en bas du jardin, deux silhouettes floues sur l'escalier de la plage. L'une porte un sweat "
      "clair, jaune dans la lumière du lampadaire. L'autre, plus grande, en blanc.",
      source="received", frm="louise", received=t(23, "02:34"), place="Villa Les Oyats — terrasse", device="iPhone 14 Pro",
      style="night")
photo("p_louise_0227", t(23, "02:27"), "terrace", "Étoiles au-dessus de la terrasse, le trépied dans le cadre.",
      "Horodatage 02:27, même cadrage que la série commencée à 02:06 : le trépied n'a pas bougé. Au premier plan, la table en teck "
      "et le reflet de la lampe frontale de Louise. L'escalier, au fond, est de nouveau dans le noir.",
      source="received", frm="louise", received=t(23, "02:35"), place="Villa Les Oyats — terrasse", device="iPhone 14 Pro",
      style="night")
photo("p_diane_biarritz", t(12, "10:48", 7), "terrace", "« Week-end entre filles » : un café en terrasse face à l'océan.",
      "Deux cafés sur la table d'un café de la Côte des Basques, une paire de lunettes de soleil d'homme à monture écaille, "
      "et une veste de costume bleu marine sur le dossier d'une chaise.",
      source="received", frm="diane", received=t(12, "11:02", 7), place="Biarritz — Côte des Basques", device="iPhone 13")
photo("p_max_sunglasses", t(1, "16:20"), "beach", "Maxime lit sur la plage Pereire, à Arcachon.",
      "Il porte ses lunettes de soleil à monture écaille, celles qu'il ne quitte pas de l'été. Une serviette rayée, un livre ouvert, "
      "sa montre posée sur son sac.",
      place="Arcachon — plage Pereire")

# --- received from family and friends
photo("p_paul_surf", t(25, "11:32", 7), "beach", "Jeanne debout sur une planche (presque).",
      "Une silhouette en combinaison, bras écartés, une vague minuscule. Grégoire, au fond, applaudit.",
      source="received", frm="paul", received=t(25, "12:10", 7), place="Lacanau — plage centrale", device="iPhone 12")
photo("p_old_2003", at(2003, 7, 20, "15:30"), "beach", "Jeanne et Paul enfants, dune du Pilat, été 2003.",
      "Paul, 10 ans, un bob trop grand et un seau rouge. Jeanne, 6 ans, pleure parce qu'elle a du sable dans les yeux.",
      source="received", frm="maman", received=t(22, "09:05"), place="Pyla-sur-Mer", device="Scan", style="old")
photo("p_old_2005", at(2005, 12, 24, "20:10"), "interior_warm", "Noël 2005 chez Mamie, à Arcachon.",
      "Une nappe rouge, des bougies, Paul fait une grimace derrière Jeanne. Mamie coupe la bûche.",
      source="received", frm="maman", received=t(22, "09:05"), place="Arcachon", device="Scan", style="old")
photo("p_porto", t(15, "12:48"), "street_day", "Une rue de Porto, des nappes brodées en vitrine.",
      "Des azulejos bleus, une boutique de linge de maison. Maman, de dos, un sac à la main.",
      source="received", frm="papa", received=t(15, "13:02"), place="Porto", device="Galaxy A52")
photo("p_zellige", t(16, "11:15", 7), "document", "Deux échantillons de zellige, blanc et vert sauge.",
      "Posés sur le plan de travail de Mme Laborde. Le vert est plus foncé qu'en catalogue.",
      source="received", frm="chloe", received=t(16, "11:22", 7), place="Caudéran, Bordeaux", device="iPhone 14")

# --- Jeanne's everyday camera roll
roll = [
    # (id, taken, scene, caption, details, place, style, lines)
    ("p_old_2022", at(2022, 6, 18, "17:05"), "interior_warm", "Emménagement aux Chartrons, juin 2022.",
     "Des cartons partout, une plante sur le rebord de la fenêtre, Maxime assis par terre.", "Chartrons, Bordeaux", "old", None),
    ("p_old_2019", at(2019, 9, 7, "19:20"), "sunset", "Coucher de soleil au Pyla, 2019.",
     "Le banc d'Arguin au loin, des parapentes.", "Pyla-sur-Mer", "old", None),
    ("p_resa", t(2, "21:14", 7), "screenshot", "Capture : réservation de la villa.",
     "Confirmation affichée à l'écran.", None, "screenshot",
     ["Bassin Locations", "Réservation confirmée ✓", "Villa Les Oyats — Cap Ferret", "Du ven. 21 au dim. 23 août 2026",
      "5 chambres · 10 couchages", "Accès plage par escalier privé", "Total : 1 480,00 €"]),
    ("p_selfie_mirror", t(13, "08:10", 7), "mirror", "Selfie dans le miroir de l'agence.",
     "Jeanne, une tasse à la main, un échantillon de papier peint sous le bras.", "Castaing Intérieurs", "selfie", None),
    ("p_sky_july", t(17, "07:45", 7), "sky", "Ciel rose au-dessus des toits des Chartrons.",
     "Des martinets, une antenne. Rien d'autre.", "Chartrons, Bordeaux", None, None),
    ("p_cat", t(26, "10:12", 7), "cat", "Le chat du voisin sur notre balcon.",
     "Un chat tigré, couché dans le bac à géraniums.", "Chartrons, Bordeaux", None, None),
    ("p_rain", t(28, "08:30", 7), "rain", "Orage sur les quais.",
     "Des gouttes énormes sur la vitre du tram.", None, None, None),
    ("p_night_chartrons", t(30, "23:10", 7), "street_night", "La rue Notre-Dame, la nuit.",
     "Des terrasses qui ferment, un vélo contre un réverbère.", "Chartrons, Bordeaux", "night", None),
    ("p_laptop", t(5, "15:02"), "laptop", "Plans 3D de la salle de bain Laborde.",
     "Le zellige vert sauge en rendu 3D, une vasque blanche.", "Castaing Intérieurs", None, None),
    ("p_ceiling", t(9, "08:02"), "ceiling", "Le plafond de la chambre.",
     "Photo prise par erreur en attrapant le réveil.", "Chartrons, Bordeaux", "blurry", None),
    ("p_plant", t(9, "12:15"), "plant", "Le monstera a fait une nouvelle feuille !!",
     "Une feuille encore roulée, vert clair.", "Chartrons, Bordeaux", None, None),
    ("p_chantier", t(13, "15:10"), "interior_warm", "La salle de bain Laborde, terminée.",
     "Zellige vert sauge du sol au plafond, lumière de fin d'après-midi.", "Caudéran, Bordeaux", None, None),
    ("p_meteo", t(20, "18:10"), "screenshot", "Capture : météo marine du week-end.",
     "Soleil samedi, vent faible.", None, "screenshot",
     ["Météo marine — Bassin d'Arcachon", "Ven. 21  ☀  27°  vent NO 10 km/h", "Sam. 22  ☀  29°  vent O 8 km/h",
      "Nuit sam. → dim. : ciel clair, 18°", "Dim. 23  ⛅  26°  houle 1,2 m"]),
    ("p_quick_car", t(21, "19:32"), "car", "Bouchons à la sortie de Bordeaux.",
     "Des feux stop à perte de vue sur la rocade.", None, "quick", None),
    ("p_marees", t(21, "21:20"), "screenshot", "Capture : horaires des marées.",
     "Samedi 22 août, Cap Ferret.", None, "screenshot",
     ["Marées — Cap Ferret", "Samedi 22 août", "PM  06:58   3,9 m", "BM  13:10   1,1 m", "PM  19:23   4,0 m",
      "Dimanche 23 août", "BM  01:36   1,0 m", "PM  07:44   3,8 m"]),
    ("p_sunset_bassin", t(21, "20:58"), "sunset", "Premier coucher de soleil sur le bassin.",
     "Des pinasses au mouillage, la dune du Pilat en face, toute rose.", "Villa Les Oyats", None, None),
    ("p_ticket", t(22, "10:15"), "receipt", "Ticket de la supérette.", "Glaçons, citrons, bougies.", "Cap Ferret", "document",
     ["SUPÉRETTE DE LA POINTE", "22/08/2026  10:14", "GLAÇONS 5 KG  x2     7,80", "CITRONS              3,20",
      "CHARBON 3 KG          8,90", "BOUGIES CHIFFRES 3+0  4,40", "EAU PÉTILL. x6        5,70", "PAIN                 8,60",
      "TOTAL               38,60 €"]),
    ("p_phare", t(22, "10:52"), "view", "Le phare du Cap Ferret, vu d'en bas.",
     "Le phare blanc et rouge, un ciel sans nuage. Maxime, de dos, lit le panneau des horaires.", "Phare du Cap Ferret", None, None),
    ("p_huitres", t(22, "12:40"), "terrace", "Pause huîtres au port.",
     "Une douzaine d'huîtres sur un plateau en bois, deux verres de vin blanc, les pinasses derrière.", "Port du Cap Ferret", None, None),
    ("p_stairs_day", t(22, "16:05"), "garden_stairs", "L'escalier de pierre qui descend du jardin à la plage.",
     "Une quarantaine de marches, une rampe en bois sur la droite seulement. Un lampadaire à mi-hauteur. Les marches du bas sont "
     "verdâtres, humides.", "Villa Les Oyats", None, None),
    ("p_dune", t(22, "17:40"), "beach", "La dune du Pilat, en face, de l'autre côté du bassin.",
     "Du sable très blanc, des bateaux au mouillage, Paul et Grégoire à l'eau avec les planches.", "Plage de la Pointe", None, None),
    ("p_selfie_louise", t(22, "19:30"), "selfie", "Jeanne et Louise, joue contre joue.",
     "Des paillettes sur les joues, la baie vitrée derrière.", "Villa Les Oyats", "selfie", None),
    ("p_pocket", t(22, "21:48"), "pocket", "Photo prise dans une poche.", "Tout est noir, une lueur orange.", None, "blurry", None),
    ("p_cake", t(22, "23:15"), "party", "Le gâteau et ses deux bougies « 3 » et « 0 ».",
     "Des visages éclairés par les bougies, Mamie applaudit.", "Villa Les Oyats", None, None),
    ("p_gift", t(22, "23:48"), "gallery", "Le cadeau de Louise : un tirage encadré.",
     "Une photo de Jeanne et Paul enfants sur la dune, retirée en grand format, cadre en chêne.", "Villa Les Oyats", None, None),
    ("p_blur_party", t(23, "00:12"), "party", "Tout le monde danse dans le salon.",
     "Photo floue : des bras levés, une guirlande, un sweat jaune au milieu.", "Villa Les Oyats", "blurry", None),
    ("p_night_garden", t(23, "00:40"), "garden_stairs", "Le jardin la nuit, depuis la terrasse.",
     "Le lampadaire de l'escalier est éteint. Il s'allume quand quelqu'un passe devant.", "Villa Les Oyats", "night", None),
]
for pid, taken, scene, cap, det, place, style, lines in roll:
    dev = "iPhone 8" if taken < "2021" else ("iPhone 12" if taken < "2024" else "iPhone 15")
    photo(pid, taken, scene, cap, det, place=place, style=style, lines=lines, device=dev)

# ---------------------------------------------------------------- calendar
calendar = [
    dict(id="c_biarritz", start=t(10, "18:00", 7), end=t(12, "20:00", 7), title="Maxime — séminaire Biarritz",
         location="Biarritz", notes="Retour dimanche soir. Récupérer son costume au pressing mercredi."),
    dict(id="ev_laborde1", start=t(16, "09:00", 7), end=t(16, "10:00", 7), title="Chantier Laborde — choix carrelage",
         location="Caudéran"),
    dict(id="ev_mamie", start=t(19, "12:30", 7), title="Déjeuner chez Mamie", location="Arcachon"),
    dict(id="ev_dentiste", start=t(21, "17:30", 7), title="Dentiste — Dr Pujol", location="Cours de l'Intendance"),
    dict(id="ev_surf", start=t(25, "10:00", 7), end=t(25, "12:00", 7), title="Cours de surf (Paul & Greg) 🏄‍♀️",
         location="École de surf Les Baïnes — Lacanau"),
    dict(id="ev_laborde2", start=t(13, "15:00"), title="Réception chantier Laborde", location="Caudéran"),
    dict(id="ev_villa", start=t(21, "19:00"), end=t(23, "17:00"), title="Villa Les Oyats 🏡", location="Cap Ferret",
         notes="Boîte à code : 4417. État des lieux dimanche 17h."),
    dict(id="ev_30", start=t(22, "00:00"), title="🎂 Mes 30 ans !!", allDay=True),
    dict(id="c_brunch", start=t(23, "12:30"), end=t(23, "14:30"), title="Brunch des 30 ans", location="Villa Les Oyats",
         notes="Croissants commandés à la boulangerie du port (retrait 11h30)."),
    dict(id="ev_etat", start=t(23, "17:00"), title="État des lieux de sortie — M. Dubroca", location="Villa Les Oyats"),
    dict(id="ev_sang", start=t(27, "08:00"), title="Prise de sang (à jeun)", location="Laboratoire Chartrons"),
    dict(id="ev_parents", start=t(30, "16:40"), title="Retour des parents — vol Porto → Bordeaux", location="Aéroport de Mérignac"),
]

# ---------------------------------------------------------------- notes
notes = [
    dict(id="n_discours", title="Discours 30 ans (court !!)", createdAt=t(17, "23:50"), modifiedAt=t(22, "18:40"),
         body="Merci d'être là.\nMamie : tu es la plus belle de nous tous, et de loin.\nPaul : merci de m'avoir appris à nager, "
              "à tomber de planche et à perdre au Uno sans pleurer.\nLouise : 15 ans d'amitié, 0 dispute (presque).\n"
              "Maxime : 4 ans, 1 appartement, 1 monstera. Je t'aime.\n→ NE PAS PLEURER."),
    dict(id="n_invites", title="Invités & chambres", createdAt=t(5, "21:10"), modifiedAt=t(20, "22:15"),
         body="Chambre du haut (vue bassin) : Maxime & moi\nChambre bleue : Paul & Diane\nChambre jardin : Louise\n"
              "Bureau (canapé-lit) : Grégoire\nMamie : rentre le soir (Greg ou Maxime la raccompagne)\n"
              "Nour & Basile : repartent vers minuit\nCanapé du salon : libre"),
    dict(id="n_courses", title="Courses samedi", createdAt=t(19, "21:30"), modifiedAt=t(22, "10:05"),
         body="- glaçons x2\n- citrons\n- charbon\n- bougies 3 et 0\n- pain\n- rosé x6, champagne x4 (Diane en apporte)\n"
              "- eau pétillante\n- serviettes papier\n- sacs poubelle\n- crème solaire !!"),
    dict(id="n_cadeau_paul", title="Idées cadeau Paul (34 ans en octobre)", createdAt=t(28, "22:40", 7), modifiedAt=t(10, "22:05"),
         body="- combi neuve ? (il a la même depuis 2019)\n- montre de plongée\n- week-end à Hossegor avec Diane ?? → vu l'ambiance, pas sûr"),
]

# ---------------------------------------------------------------- mail
mails = [
    dict(id="mail_resa", folder="inbox", fromName="Bassin Locations", fromAddress="reservation@bassin-locations.fr",
         to="jeanne@castaing-interieurs.fr", at=t(2, "21:10", 7), subject="Confirmation de réservation — Villa Les Oyats",
         body="Bonjour Madame Castaing,\n\nNous vous confirmons la réservation de la Villa Les Oyats (Cap Ferret) du vendredi 21 août "
              "(arrivée à partir de 18h) au dimanche 23 août (départ 17h).\n\n5 chambres, 10 couchages, jardin avec accès direct à la "
              "plage par un escalier privé.\n\nMontant total : 1 480,00 €. Caution : 1 000 €.\n\nL'équipe Bassin Locations",
         attachments=["Contrat_Villa_Les_Oyats.pdf"]),
    dict(id="mail_infos", folder="inbox", fromName="Bassin Locations", fromAddress="reservation@bassin-locations.fr",
         to="jeanne@castaing-interieurs.fr", at=t(20, "09:12"), subject="Votre arrivée vendredi — infos pratiques",
         body="Bonjour,\n\nLes clés vous attendent dans la boîte à code à droite du portail. Wi-Fi : OYATS-GUEST.\n\n"
              "L'escalier privé qui descend à la plage est éclairé par un lampadaire à détecteur de présence. Les marches peuvent "
              "être glissantes le matin (rosée) : prudence avec les enfants.\n\nMerci de ne pas faire de bruit dans le jardin après "
              "minuit, les voisins sont proches.\n\nBon séjour !"),
    dict(id="mail_zellige", folder="sent", fromName="Jeanne Castaing", fromAddress="jeanne@castaing-interieurs.fr",
         to="commandes@terres-et-emaux.fr", at=t(21, "09:30", 7), subject="Commande zellige vert sauge — chantier Laborde",
         body="Bonjour,\n\nSuite à notre échange, je vous confirme la commande de 14 m² de zellige vert sauge (réf. ZV-12), livraison "
              "à l'adresse du chantier à Caudéran.\n\nBien cordialement,\nJeanne Castaing\nCastaing Intérieurs"),
    dict(id="mail_surf", folder="inbox", fromName="École de surf Les Baïnes", fromAddress="contact@lesbaines-surf.fr",
         to="jeanne@castaing-interieurs.fr", at=t(10, "10:00"), subject="Fin de saison : derniers créneaux d'août 🌊",
         body="Paul et Grégoire vous remercient pour cet été ! Derniers cours collectifs jusqu'au 30 août. "
              "Réservez vite, il reste peu de places."),
    dict(id="mail_parents", folder="inbox", fromName="Maman", fromAddress="c.castaing@mailo.fr", to="jeanne@castaing-interieurs.fr",
         at=t(15, "18:05"), subject="Fwd: vos billets retour",
         body="Pour que tu aies nos horaires ma chérie. On atterrit à 16h40 le dimanche 30 et on prend le train pour Arcachon "
              "voir Mamie. Bisous\n\n---------- Message transféré ----------\nVotre voyage : Porto → Bordeaux, dim. 30 août, "
              "arrivée 16:40. TER Bordeaux → Arcachon 18:12.",
         attachments=["Billets_30-08.pdf"]),
    dict(id="mail_colis", folder="inbox", fromName="ColiPoint", fromAddress="noreply@colipoint.fr", to="jeanne@castaing-interieurs.fr",
         at=t(18, "08:11"), subject="Un colis vous attend lundi 24 août",
         body="Votre colis CP77120 sera livré le lundi 24 août à votre domicile. Expéditeur : Nour B."),
    dict(id="mail_chloe", folder="inbox", fromName="Chloé Darrigade", fromAddress="chloe@castaing-interieurs.fr",
         to="jeanne@castaing-interieurs.fr", at=t(21, "16:55"), subject="Planning septembre",
         body="Je t'ai mis le planning de rentrée en pièce jointe. Trois nouveaux chantiers dont un à Pessac. On en parle lundi, "
              "profite de ton week-end !\n\nChloé",
         attachments=["Planning_septembre.xlsx"]),
]

# ---------------------------------------------------------------- browser
browser = [
    dict(id="w01", at=t(2, "20:40", 7), kind="search", text="location villa cap ferret 10 personnes accès plage"),
    dict(id="w02", at=t(2, "20:52", 7), kind="visit", text="Villa Les Oyats — Bassin Locations", url="bassin-locations.fr/villa-les-oyats",
         summary="Villa de 5 chambres côté bassin, grand jardin en pente, escalier privé en pierre jusqu'à la plage, terrasse plein sud."),
    dict(id="w03", at=t(13, "14:30", 7), kind="search", text="zellige vert sauge prix m2"),
    dict(id="w04", at=t(21, "21:40", 7), kind="search", text="associé veut racheter parts sarl refuser"),
    dict(id="w05", at=t(24, "22:15", 7), kind="search", text="surf débutant quelle taille de combinaison"),
    dict(id="w06", at=t(9, "22:10"), kind="search", text="comment annoncer à son frère que les parents vendent la maison de famille"),
    dict(id="w07", at=t(17, "23:40"), kind="search", text="discours 30 ans pour soi-même drôle court"),
    dict(id="w08", at=t(20, "18:05"), kind="search", text="marées cap ferret 22 août"),
    dict(id="w09", at=t(21, "21:30"), kind="search", text="escalier en pierre glissant rosée"),
    dict(id="w10", at=t(21, "21:32"), kind="visit", text="Pourquoi les marches extérieures glissent-elles le matin ?",
         url="maison-jardin.fr/escaliers-exterieurs-glissants",
         summary="La rosée et les mousses rendent la pierre très glissante entre la nuit et le milieu de matinée. Poser une rampe des deux côtés."),
    dict(id="w11", at=t(22, "10:20"), kind="search", text="phare du cap ferret horaires"),
    dict(id="w12", at=t(22, "10:21"), kind="visit", text="Phare du Cap Ferret — horaires et tarifs", url="phare-capferret.fr/infos",
         summary="Ouvert tous les jours de 10h à 19h30 en juillet et août. 258 marches, vue sur le bassin et l'océan."),
    dict(id="w13", at=t(23, "08:34"), kind="search", text="vol porto bordeaux aujourd'hui"),
    dict(id="w14", at=t(23, "09:12"), kind="search", text="traumatisme crânien coma chances de réveil"),
    dict(id="w15", at=t(23, "10:05"), kind="visit", text="CHU de Bordeaux — Réanimation : informations aux familles",
         url="chu-bordeaux.fr/reanimation/familles",
         summary="Les visites sont possibles de 13h à 20h, deux personnes à la fois. Un médecin reçoit les familles chaque jour."),
]

# ---------------------------------------------------------------- live events (the phone keeps living)
def live_msg(eid, after, conv_id, frm, text, title, hm, mid=None):
    mid = mid or ("m_" + eid)
    return dict(id=eid, afterSeconds=after, kind="message", app="messages", title=title, body=text,
                conversation=conv_id, message=dict(id=mid, **{"from": frm}, at=t(23, hm), text=text),
                opens=f"message:{mid}")
live = [
    live_msg("lv01", 20, "c_maman", "maman", "Jeanne on arrive ce soir, on a trouvé un vol. Des nouvelles de l'hôpital ??",
             "Maman", "11:40"),
    dict(id="lv02", afterSeconds=70, kind="call", app="phone", title="Appel manqué", body="Maxime Rivière",
         call=dict(id="k_lv02", contact="maxime", direction="missed", at=t(23, "11:41"), durationSeconds=0), opens="call:k_lv02"),
    live_msg("lv03", 130, "c_family", "diane", "quelqu'un a pris mon chargeur ?", "Les Castaing ☀️ — Diane", "11:42"),
    live_msg("lv04", 190, "c_louise", "louise", "Jeanne, je t'envoie toutes mes photos d'hier soir, la police les veut aussi",
             "Louise Ferrer", "11:43"),
    live_msg("lv05", 250, "c_maxime", "maxime", "t'es où ? les gendarmes veulent me reparler. je comprends pas pourquoi",
             "Maxime Rivière", "11:44"),
    dict(id="lv06", afterSeconds=300, kind="reminder", app="calendar", title="12:30",
         body="Brunch des 30 ans · Villa Les Oyats", opens="calendar:c_brunch"),
    live_msg("lv07", 360, "c_gregoire", "gregoire", "le médecin dit qu'il a eu de la chance", "Grégoire Salles", "11:46"),
    dict(id="lv08", afterSeconds=420, kind="deletion", app="messages", title="Les Castaing ☀️",
         body="Diane a supprimé un message", conversation="c_family", deletesMessage="m_fam_diane_0940",
         opens="message:m_fam_diane_0940"),
]
LEVELS = {"lv02": "important", "lv04": "important", "lv05": "important", "lv06": "normal", "lv08": "important"}
for e in live:
    e["level"] = LEVELS.get(e["id"], "normal")

device = dict(
    id="dev_jeanne", label="Téléphone de Jeanne", model="iPhone 15",
    lockedApps=[],
    contacts=contacts, conversations=convs, calls=calls, places=places, tracks=tracks, photos=photos,
    calendar=calendar, notes=notes, mails=mails, browser=browser, liveEvents=live,
    wallpaper="shore", batteryPercent=41,
)

# ---------------------------------------------------------------- suspects
suspects = [
    dict(id="s_maxime", contact="maxime", role="Compagnon de Jeanne", age=34, address="Chartrons, Bordeaux",
         statement="« J'ai rejoint Jeanne vers 1h45 et je ne me suis pas relevé de la nuit. »",
         verdict="Maxime Rivière a menti. À 02:21, il n'était pas dans le lit : il remontait du jardin. Descendu retrouver Diane "
                 "sur l'escalier de la plage, il y a trouvé Paul. Le sweat jaune de la photo de Louise, à 02:14, c'est le sien."),
    dict(id="s_diane", contact="diane", role="Femme de Paul", age=31, address="Lacanau",
         statement="« J'ai dormi avec Paul dans notre chambre. Je ne l'ai pas entendu se lever. »",
         alibi="À 02:06, la photo de Louise la montre endormie sur le canapé du salon, un plaid sur les jambes. Sur l'escalier, à 02:14, "
               "personne ne porte de robe bleue.",
         alibiEvidence="e_diane_alibi",
         trap="Elle a menti sur sa nuit et c'est elle qui a donné rendez-vous sur l'escalier. Mais après la dispute avec Paul, elle "
              "est descendue dormir sur le canapé et n'est jamais allée au rendez-vous.",
         verdict="Diane a menti, par honte : après une dispute avec Paul, elle a dormi sur le canapé du salon. Son message effacé "
                 "donnait bien rendez-vous sur l'escalier… à Maxime. Elle n'y est pas allée : à 02:06, elle dormait."),
    dict(id="s_louise", contact="louise", role="Meilleure amie de Jeanne — doit 3 000 € à Paul", age=30, address="Saint-Michel, Bordeaux",
         statement="« J'étais sur la terrasse à photographier les étoiles de 2h à 2h30, avec mes écouteurs. Je n'ai rien vu ni entendu. »",
         alibi="Sa série de photos est continue, depuis la terrasse, de 02:06 à 02:27, le trépied au même endroit. C'est même elle "
               "qui a photographié, sans le voir, ce qui se passait sur l'escalier.",
         alibiEvidence="e_louise_alibi",
         trap="Une dette de 3 000 €, un échange tendu devant tout le monde au dîner, et elle était dehors au moment des faits.",
         verdict="Louise avait un différend réel avec Paul, mais elle n'a pas quitté la terrasse : ses photos le prouvent, heure par "
                 "heure. Sans le savoir, elle a fixé l'instant où deux silhouettes se faisaient face sur l'escalier."),
    dict(id="s_gregoire", contact="gregoire", role="Associé de Paul à l'école de surf", age=36, address="Lacanau",
         statement="« J'ai raccompagné Mamie à Arcachon vers 1h, je suis rentré vers 3h15 et je me suis couché. J'ai trouvé Paul à 7h10. »",
         alibi="Sa position partagée le place à Arcachon à 02:04, à La Teste à 02:31, et de retour à la villa seulement à 03:14. "
               "Mamie confirme son arrivée à 02:07.",
         alibiEvidence="e_gregoire_alibi",
         trap="Il voulait racheter les parts de Paul, qui refusait, et c'est lui qui l'a « trouvé » au petit matin.",
         verdict="Grégoire avait un conflit d'affaires avec Paul, mais à l'heure de la chute il était à une heure de route, chez Mamie, "
                 "à Arcachon. Il a trouvé Paul à 7h10 en allant nager, et a donné l'alerte."),
]

# ---------------------------------------------------------------- evidence
evidence = [
    dict(id="e_not_in_bed", title="« Je bois un verre d'eau »", importance="key", suspects=["s_maxime"],
         refs=["message:m_max_0221", "message:m_max_0223"],
         meaning="À 02:21, Maxime n'est pas dans le lit, contrairement à ce qu'il affirme. « Je bois un verre d'eau » : le salon, lui, "
                 "était occupé par Diane endormie."),
    dict(id="e_stairs_photo", title="Deux silhouettes sur l'escalier", importance="key", suspects=["s_maxime"],
         refs=["photoInfo:p_louise_0214"],
         meaning="À 02:14, la pose longue de Louise saisit deux silhouettes sur l'escalier de la plage : l'une en jaune, l'autre, plus "
                 "grande, en blanc — la chemise de lin de Paul."),
    dict(id="e_yellow", title="Le sweat jaune", importance="key", suspects=["s_maxime"],
         refs=["photoInfo:p_group_2340"],
         meaning="Sur la photo de groupe de 23:40, le seul vêtement jaune de la soirée est le sweat moutarde de Maxime."),
    dict(id="e_rdv_deleted", title="Le message effacé", importance="key", suspects=["s_maxime", "s_diane"],
         refs=["message:m_fam_0149"],
         meaning="Diane donne rendez-vous à quelqu'un sur l'escalier de la plage, « il dort » : Paul. Un message qu'on efface en une "
                 "minute. Il ne visait ni Mamie ni Jeanne : dans ce groupe, il ne reste que Maxime."),
    dict(id="e_paul_awake", title="Paul ne dormait pas", importance="key", suspects=["s_maxime"], anyOf=True,
         refs=["call:k_paul_0209", "message:m_paul_0203"],
         meaning="Paul avait lu le message de 01:49. Il écrit à sa sœur, puis l'appelle à 02:09 : il voulait « régler ça lui-même »."),
    dict(id="e_affair", title="Le même week-end à Biarritz", importance="supporting", suspects=["s_maxime", "s_diane"],
         refs=["calendar:c_biarritz", "photoInfo:p_diane_biarritz"],
         meaning="Le « séminaire » de Maxime et le « week-end entre filles » de Diane tombent le même week-end, au même endroit. Sur la "
                 "table de Diane : les lunettes écaille de Maxime et une veste de costume bleu marine."),
    dict(id="e_diane_alibi", title="Diane sur le canapé", importance="supporting", suspects=["s_diane"],
         refs=["photoInfo:p_louise_0206"],
         meaning="À 02:06, à travers la baie vitrée, Diane dort sur le canapé du salon. Elle n'est pas allée à son propre rendez-vous."),
    dict(id="e_louise_alibi", title="La série de Louise", importance="supporting", suspects=["s_louise"], anyOf=True,
         refs=["photoInfo:p_louise_0227", "photo:p_louise_0206"],
         meaning="De 02:06 à 02:27, Louise photographie le ciel depuis la terrasse sans déplacer son trépied."),
    dict(id="e_gregoire_alibi", title="La route d'Arcachon", importance="supporting", suspects=["s_gregoire"], anyOf=True,
         refs=["track:t_gregoire", "message:m_mamie_0207"],
         meaning="Grégoire dépose Mamie à Arcachon à 02:04 et ne rentre à la villa qu'à 03:14."),
    dict(id="f_diane_lie", title="« À côté de lui toute la nuit »", importance="falseLead", suspects=["s_diane"],
         refs=["message:m_fam_diane_0940"],
         meaning="Diane ment : elle a dormi sur le canapé après une dispute. Elle cache la dispute et sa liaison, pas la chute."),
    dict(id="f_louise_debt", title="Les 3 000 € de Louise", importance="falseLead", suspects=["s_louise"],
         refs=["message:m_paul_debt"],
         meaning="Une vraie dette et une vraie tension, mais Louise n'a jamais quitté la terrasse."),
    dict(id="f_gregoire_found", title="Celui qui l'a trouvé", importance="falseLead", suspects=["s_gregoire"], anyOf=True,
         refs=["call:k_greg_0712", "message:m_paul_parts"],
         meaning="Grégoire voulait racheter les parts de Paul et c'est lui qui l'a trouvé. Mais cette nuit-là, il était sur la route "
                 "d'Arcachon."),
]

hints = [
    dict(id="h1", text="Tout le monde dit avoir dormi. Les photos, elles, ne dorment pas : regardez à quelle heure chacune a été prise.",
         scoreCost=0),
    dict(id="h2", text="Louise a photographié le ciel toute la nuit depuis la terrasse. Analysez sa série, puis la grande photo de groupe.",
         scoreCost=8),
    dict(id="h3", text="À 02:21, Jeanne cherche quelqu'un dans son lit. Qui portait du jaune ce soir-là ?",
         scoreCost=15, unlockAtRemainingSeconds=120),
]

solution = dict(
    culprit="s_maxime",
    headline="Maxime Rivière a poussé Paul dans l'escalier de la plage.",
    summary="Il disait ne pas s'être relevé. Il était sur l'escalier, en sweat jaune, là où Diane lui avait donné rendez-vous.",
    reveal=[
        dict(at=t(11, "12:00", 7), text="« Séminaire » à Biarritz pour lui, « week-end entre filles » à Biarritz pour elle",
             evidence="e_affair"),
        dict(at=t(22, "23:40"), text="Photo de groupe : Maxime est le seul à porter du jaune", evidence="e_yellow"),
        dict(at=t(23, "01:49"), text="Diane se trompe de conversation : « tu descends ? il dort. escalier de la plage » — effacé à 01:50",
             evidence="e_rdv_deleted"),
        dict(at=t(23, "02:03"), text="Paul, réveillé, écrit à sa sœur « je règle ça moi-même », puis l'appelle à 02:09",
             evidence="e_paul_awake"),
        dict(at=t(23, "02:04"), text="Grégoire dépose Mamie à Arcachon, à une heure de route", evidence="e_gregoire_alibi"),
        dict(at=t(23, "02:06"), text="Diane dort sur le canapé du salon", evidence="e_diane_alibi"),
        dict(at=t(23, "02:14"), text="Sur l'escalier : une silhouette en blanc, une autre en jaune", evidence="e_stairs_photo"),
        dict(at=t(23, "02:23"), text="Jeanne se réveille seule. Maxime : « en bas, je bois un verre d'eau »", evidence="e_not_in_bed"),
        dict(at=t(23, "02:27"), text="Louise n'a pas bougé de la terrasse", evidence="e_louise_alibi"),
    ],
    story=[
        "Depuis le printemps, Maxime et Diane se voient en secret. Le week-end du 11 juillet, lui est « en séminaire » à Biarritz, "
        "elle en « week-end entre filles » à Biarritz. Sur la photo qu'elle poste dans le groupe de la famille : ses lunettes écaille "
        "et sa veste de costume.",
        "Samedi 22 août, Jeanne fête ses trente ans au Cap Ferret. À 01:05, Grégoire raccompagne Mamie à Arcachon. À 01:45, Jeanne "
        "monte se coucher ; Maxime la suit. À 01:49, Diane, qui croit écrire à Maxime, poste dans le groupe de la famille : « tu "
        "descends ? il dort. escalier de la plage ». Elle l'efface une minute plus tard. Trop tard : Paul l'a lu.",
        "Paul et Diane se disputent ; elle descend dormir sur le canapé du salon. Paul écrit à sa sœur — « Faut que je te parle. "
        "C'est grave. » — puis « je règle ça moi-même ». Il l'appelle une dernière fois à 02:09, sans réponse, et descend attendre "
        "sur l'escalier de la plage.",
        "Maxime, qui a vu le message, se glisse hors du lit et descend retrouver Diane. C'est Paul qui l'attend. Ils se battent sur "
        "les marches. Maxime le repousse ; Paul tombe. Sur la terrasse, écouteurs sur les oreilles, Louise photographie le ciel : "
        "sa pose longue de 02:14 enregistre deux silhouettes sous le lampadaire, l'une en blanc, l'autre en jaune.",
        "Maxime remonte par le jardin. À 02:21, Jeanne se réveille seule et lui écrit. « En bas, je bois un verre d'eau. » Il se "
        "recouche à 02:26. Au matin, Grégoire, parti nager, trouve Paul au pied de l'escalier.",
        "Transporté au CHU de Bordeaux, Paul se réveille trois jours plus tard et confirme. Maxime avoue : il est descendu retrouver "
        "Diane, Paul l'attendait, ils se sont battus, il l'a repoussé. Il n'a appelé personne.",
    ],
)

# ---------------------------------------------------------------- opening sequence
intro = dict(shots=[
    dict(kind="scene", seconds=7, scene="villa_morning", camera="drift", effect="sunlight", ambience=["room", "sea"],
         cues=[dict(sound="gulls", at=1.4)],
         lines=[dict(text="CAP FERRET · DIMANCHE 23 AOÛT · 07:10", at=0.3),
                dict(text="Le lendemain de ses trente ans.", at=2.4)]),
    dict(kind="scene", seconds=5, scene="terrace", camera="panRight", ambience=["sea"],
         cues=[dict(sound="gulls", at=2.0)]),
    dict(kind="phoneOnTable", seconds=6.5, time="2026-08-23 07:11", surface="wood", label="Table de chevet — chambre du haut — 07:11",
         ambience=["room"],
         cues=[dict(sound="ring", at=0.8), dict(sound="vibrate", at=0.8), dict(sound="notification", at=3.4)],
         notifications=[dict(app="phone", title="Grégoire", body="Appel entrant", at=0.8, call=True),
                        dict(app="messages", title="Grégoire", body="JEANNE DESCENDS VITE. C'EST PAUL", at=3.4)],
         lines=[dict(text="Personne ne répond.", at=4.8)]),
    dict(kind="unlock", seconds=2.4),
])

case = dict(
    dossier=dict(rating=3, category="CHUTE SUSPECTE", city="Cap Ferret", place="Villa Les Oyats", subject="Paul Castaing", subjectLabel="VICTIME", subjectAge=33, subjectContact="paul", lastContact="2026-08-23 02:09"),
    schemaVersion=1, id="case_003", number=3, title="APRÈS LA FÊTE",
    tagline="Tout le monde dormait. Personne ne dit la même chose.",
    synopsis=[
        "Samedi 22 août, Jeanne Castaing fête ses 30 ans dans une villa louée au Cap Ferret, avec sa famille et ses amis.",
        "Dimanche à 7h10, son frère Paul, 33 ans, est retrouvé inconscient au pied de l'escalier de pierre qui descend du jardin "
        "à la plage. Il est dans le coma. Tous disent avoir dormi.",
        "Jeanne vous confie son téléphone : sa soirée y est entière, heure par heure.",
    ],
    objective="Établir qui était avec Paul sur l'escalier de la plage vers 2h10.",
    difficulty=1, durationSeconds=480, phoneStartTime=t(23, "11:40"),
    challengeDurations={"investigator": 900, "detective": 480, "expert": 300},
    introScene=intro,
    devices=[device], suspects=suspects, evidence=evidence, hints=hints, solution=solution,
)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(case, f, ensure_ascii=False, indent=1)
n_msgs = sum(len(c["messages"]) for c in convs)
print(f"case_003: {len(contacts)} contacts, {len(convs)} conversations, {n_msgs} messages, {len(calls)} calls, "
      f"{len(photos)} photos, {len(calendar)} events, {len(notes)} notes, {len(mails)} mails, {len(browser)} web, "
      f"{len(live)} live events, {len(places)} places, {len(tracks)} tracks")
