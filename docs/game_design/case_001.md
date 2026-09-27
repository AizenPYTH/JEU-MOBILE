# Affaire #001 — « LE DERNIER MESSAGE » : révision de difficulté

Fichier : `ScreenshotKit/Sources/CaseLibrary/Resources/Cases/case_001.json` · requêtes photo : `config/photo_queries/case_001.json`.

Objectif de la révision : l'affaire #001 est le **tutoriel naturel** du jeu (explorer → verser une pièce → Carnet →
conclure). Elle doit être **très accessible** sans que le jeu donne la réponse. La solution, la coupable (Emma), les
quatre suspects et la logique d'ensemble sont inchangés.

## Difficulté

| | Avant | Après |
|---|---|---|
| Note (1 = très accessible, 5 = expert) | **3 / 5** | **1 / 5** (2 / 5 sans aucun indice) |
| Pièces « clés » à trouver | 6 | 4 |
| Chemin minimal | non défini | 3 pièces (voir plus bas) |
| Indices | 0 / 8 / 15 pts, le 3ᵉ débloqué à 2 min de la fin | 0 / 5 / 10 pts, tous disponibles tout de suite |

## Audit (partie jouée « à froid »)

- **Contexte et objectif** : l'objectif « Identifier la personne qui a vu Alex en dernier » ne disait pas quoi chercher.
  Le joueur ne savait pas qu'Alex partait à un rendez-vous, ni qu'il fallait confronter des alibis. Le synopsis citait
  « quatre personnes » sans dire qui elles étaient.
- **Accessibilité des indices clés** : bonne dans l'ensemble. Toutes les pièces utiles sont sur la première page de leur
  conversation (18 messages par page) ; le mail du comptable est en boîte de réception ; l'app Notes verrouillée n'est
  jamais indispensable (le mobile est aussi dans Mail). Le seul passage obligé « caché » est la Corbeille (messages
  effacés de 21:40), mais le Calendrier (« P. Quai 9 — E. ») offre une seconde porte d'entrée.
- **Quantité d'information** : 6 pièces « clés » pour un tutoriel, c'est trop. Le rapport final reprochait au joueur
  d'avoir « manqué » le partage de position coupé ou le détour de Lucas, qui sont des confirmations, pas des preuves
  indispensables.
- **Lisibilité des suspects** : rôle d'Emma flou (« co-fondatrice ») alors que le mail parle de « la trésorière ».
- **Indices** : h1 (positions sur la carte) orientait vers la Carte, qui fait surtout soupçonner Lucas (fausse piste) ;
  h3 n'arrivait qu'à 2 minutes de la fin, donc trop tard pour aider.
- **Événements en direct** : les aveux indirects (Emma, Lucas) arrivaient à 340 s et 400 s, souvent après que le joueur
  a déjà conclu. Aucun ne l'orientait vers le rendez-vous ou l'association.
- **Cohérence des preuves / photos** : la « silhouette en veste claire » du parking reposait sur un détail visuel (une
  veste précise sur une personne précise) qu'aucune vraie photo ne peut porter, et sur la photo de groupe du vernissage
  (personnages à l'image). Plusieurs photos d'ambiance montraient des personnages (selfies, Tom, Lucas, groupe).
- **Fausses pistes** : justes et bien expliquées (dette de Karim, « Je sais ce que tu as fait » de Sarah, note « K. »,
  mensonge de Lucas). Conservées.
- **Risques de blocage** : faibles. Code des Notes trouvable (anniversaire dans Contacts et chez Maman), mais inutile
  pour résoudre.
- **Durée** : 480 s en Détective. Les tests d'interface et `AllCasesTests.levelsAndHintsFollowTheRules` imposent
  900 / 480 / 300 s : la durée n'a pas été touchée ; l'accessibilité passe par l'objectif, les indices et le tri des
  pièces.

## Chemin minimal de résolution

`"minimalPath": ["e_rdv", "e_photo_meta", "e_motive"]`

| Catégorie | Pièces |
|---|---|
| **Essentielles** | `e_rdv` (Corbeille : « Parking du Quai 9. 22h. Viens seul. » d'Emma) · `e_photo_meta` (la photo « chez moi » envoyée à 22:30, prise à 19:42) · `e_motive` (4 300 € de fausses factures validées par la trésorière) |
| Alternative à `e_rdv` | `e_calendar` (« P. Quai 9 — E. », créé à 21:44) — clé, sans passer par la Corbeille |
| **Secondaires** | `e_calendar`, `e_sharing` (partage de position coupé à 21:31), `e_lucas_route` (Lucas passe rue Paradis puis au port), `e_parking` (la citadine grise qui repart à 22:18), `e_quit`, `e_lucas_confession`, `e_draft` |
| **Alibis des innocents** | `e_sarah_alibi`, `e_karim_alibi`, `e_draft` (Lucas) |
| **Fausses pistes** | `f_sarah_threat`, `f_karim_debt`, `f_note_k`, `f_lucas_lie` |
| **Ambiance** | Le groupe « Les Levantins », Maman, Élodie, Tom, Hugo, banque, colis, 48 photos du quotidien, navigateur, agenda |
| **Inutiles (bruit pur)** | Notes Wi-Fi / Lisbonne / idées d'expo, captures (horaires, météo, mème, itinéraire, commande), mails promo |

Lecture : Emma donne rendez-vous au Quai 9 à 22h (e_rdv), ment ensuite en envoyant une vieille photo « au lit »
(e_photo_meta), et avait tout à perdre au bureau de lundi (e_motive).

## Modifications

1. **Synopsis** : les quatre suspects sont présentés en une phrase (Sarah l'ex, Karim le créancier, Lucas le meilleur ami,
   Emma du collectif Lumen).
2. **Objectif** : « Alex a quitté le Levant à 21:36 pour un rendez-vous. Trouvez qui il a rejoint, et qui ment sur sa
   soirée. » — dit quoi chercher sans désigner personne.
3. **Rôle d'Emma** : « Co-fondatrice et trésorière du collectif Lumen » (relie directement le mail du comptable).
4. **Importance** : `e_sharing` et `e_lucas_route` passent de *key* à *supporting* (4 pièces clés au lieu de 6).
5. **Chemin minimal** ajouté (`minimalPath`).
6. **Événements en direct** : nouveau message d'Inès à 150 s (`lv10`, `m_live_ines_rdv`) : « samedi, Alex m'a dit
   qu'il avait un rendez-vous après le Levant. Une histoire avec l'asso. » — oriente vers Calendrier / Mail sans nommer.
   Suppression du message d'Emma avancée à 270 s, « quand je l'ai quitté » à 300 s, aveu de Lucas à 350 s, message de
   Sarah à 400 s.
7. **Indices en paliers** :
   - h1 (0 pt) — la zone : samedi soir après 21:36 ; Messages (Corbeille comprise), Calendrier, photos reçues.
   - h2 (5 pts) — quoi comparer : ce que chacun affirme vs l'heure réelle des photos et les positions de la Carte.
   - h3 (10 pts, sans délai) — « Un élément du téléphone contredit l'alibi de l'un d'eux : une photo « preuve » n'a pas
     été prise à l'heure où elle a été envoyée. Et le rendez-vous de 22h a laissé des traces, même effacées. »
8. **Facture Studio Nova** (`p_invoice`) : l'adresse rue Paradis et « Validé : E.R. — trésorière » sont maintenant
   lisibles sur le document lui-même.
9. **Lieux réels de Marseille** : « Gare centrale » → Gare Saint-Charles ; « Quai des Arts » → Esplanade du J4 ;
   « Parc des Tilleuls » → Parc Borély ; rue du centre → Cours Julien.
10. **Preuve du parking** (`e_parking`) réécrite : plus de silhouette en veste claire, mais la citadine grise (celle de
    Lucas) qui quitte le parking à 22:18 : la personne qu'il a déposée est restée avec Alex.

## Adaptations des photos (vraies photos uniquement)

Bilan : **48 REAL · 10 PROCEDURAL · 0 CUSTOM** (58 photos).

| Photo | Avant → Après | Pourquoi |
|---|---|---|
| p_b01 | « Quai des Arts » → port vu de l'Esplanade du J4 | lieu réel de Marseille |
| p_b02 | « Tom dans une voie jaune » → « La voie jaune que Tom a enchaînée » (prises jaunes) | personnage à l'image |
| p_b04 | rue anonyme → Cours Julien, graffitis et disquaire | lieu réel |
| p_b05 | Parc des Tilleuls → Parc Borély (nuit) | lieu réel |
| p_b06 | « Inès rit » → guirlandes au-dessus de la terrasse | personnage à l'image |
| p_b09 | noms d'auteurs lisibles → rangée de livres + appareil argentique | texte lisible non requis |
| p_b12 | « Lucas fait un pouce levé » → canapé neuf et cartons | personnage à l'image |
| p_b13 | Gare centrale, panneau « retard 10 min » → Gare Saint-Charles, hall | lieu réel, texte lisible |
| p_b14 | « affiche bleue et orange » → portable ouvert, maquette | détail impossible à garantir |
| p_b16 | scène `document` → `interior_warm`, objectif posé sur le bureau | c'est un objet, pas un papier |
| p_b19 | « des visiteurs devant les tirages » → table de la buvette en fin de soirée | évite les visages |
| p_b20 | parc anonyme → Parc Borély | lieu réel |
| p_b26 | « Tom en haut du mur » → le haut du mur vu d'en bas | personnage à l'image |
| p_b28 | Lucas, Sarah, Inès décrits → verres et téléphones sur la table | personnages à l'image |
| p_b29 | « Tom montre une vidéo à Lucas » → écran de téléphone au-dessus des verres | personnages à l'image |
| p_b30 | écran « bus dans 4 min » → abribus éclairé, direction Port en légende | texte lisible |
| p_old07 | `group`, quatre silhouettes → `gallery`, quatre tirages et un escabeau | personnages à l'image |
| p_self01 | selfie miroir d'Alex → gobelet de café à la fenêtre de l'agence (`office`) | personnage à l'image |
| p_self02 | selfie avec Lucas → serviettes et tongs, Plage des Catalans | personnages à l'image |
| p_self03 | selfie fatigué → tasse et rideaux tirés (`interior_warm`) | personnage à l'image |
| p_blur03 | « un bras » → lampe, reflets, verres | partie de personne |
| p_quick01 | affiche « Nuits du Port — 18 septembre » → colonne d'affiches déchirées | texte lisible |
| p_night02 | + Notre-Dame de la Garde éclairée au loin | ancrage Marseille |
| p_lucas_car | « La Clio grise », plaque cachée → « La citadine grise », devant l'atelier | pas de marque comme sujet |
| p_vernissage | Emma, Inès, Alex, veste en jean → la salle vue du fond, visiteurs de dos (`gallery`) | personnages à l'image |
| p_bar_selfie | selfie de six personnages → six verres, veste de Karim sur une chaise, chaise vide d'Emma (`bar`) | personnages à l'image |
| p_emma_couch (preuve) | « Emma sous la couette » → « Chez moi » : couette, tasse, télé, jour à la fenêtre | personnage à l'image ; la preuve reste l'heure de prise (19:42) et la lumière du jour |
| p_parking (preuve) | silhouette en veste claire + citadine → parking vide, feux arrière d'une citadine grise | détail vestimentaire impossible ; preuve réécrite (voir e_parking) |
| p_sarah_jade (preuve) | Sarah et Jade au premier plan → jardin, guirlandes, ballons, invités | personnages à l'image ; l'alibi repose sur l'heure (22:19) et le lieu |
| p_karim_desk (preuve) | logo « Le Cygne » et horloge lisible → comptoir, sonnette, clés, hall vide | texte/logo lisible ; l'alibi repose sur les métadonnées (22:47) |

Restent **PROCEDURAL** (rendus par le téléphone) : p_b08, p_b21, p_scr01–03 (captures), p_doc01 (ticket),
p_doc02 et p_invoice (documents), p_blur01 (poche), p_blur02 (plafond).

## Risques restants

- **Tests à mettre à jour** (hors de mon périmètre) : `AllCasesTests.levelsAndHintsFollowTheRules` attend encore
  des indices à `[0, 8, 15]` et un dernier indice avec `unlockAtRemainingSeconds` ; la nouvelle grille est `[0, 5, 10]`
  sans délai pour #001. `scripts/photos/test_pipeline.py` attend encore `p_b02` et `p_emma_couch` en
  CUSTOM_REQUIRED.
- La vraie photo de `p_parking` peut ne pas montrer de feux arrière : le détail reste dans le texte d'analyse, et la
  preuve fonctionne surtout avec la position de Lucas (Quai 9 à 22:17).
- `p_emma_couch` doit être une photo de jour (fenêtre claire) : c'est ce qui rend la contradiction visible.
- Le Calendrier « E. » peut encore faire hésiter avec Élodie ; c'est voulu, et levé par les messages effacés.
- La durée reste 8 minutes en Détective (verrouillée par les tests).
