# Affaire #004 — « 90 SECONDES » : fiche de game design

Vol du collier Aurore pendant le gala « Éclats » au Pavillon Mercure (Paris 16e). Téléphone : Salomé Tessier,
commissaire de l'exposition. Coupable : **Adrien Sterne**, le prêteur (inchangé). Suspects : Enzo Barros,
Victor Almeida, Iris Nakamura, Adrien Sterne (inchangés).

## Difficulté

| | Avant | Après |
|---|---|---|
| Difficulté ressentie (1–5) | 4 | 3 (intermédiaire) |
| Note du dossier (`dossier.rating`) | 3 | 3 (inchangée) |
| Durée (détective) | 480 s | 480 s (inchangée) |

L'écart venait de difficultés inutiles (un seul accès à chaque preuve clé, des indices trop directs ou trop
tardifs, une incohérence dans l'histoire), pas du raisonnement : ce dernier est gardé tel quel.

## Audit (partie jouée comme un nouveau joueur)

- **Contexte et objectif** : le briefing était clair sur les faits (noir de 90 s, vitrine vide, pas
  d'effraction) mais ne nommait pas les pistes que « tout le monde » a en tête. Le joueur découvrait les quatre
  suspects sans savoir pourquoi chacun est soupçonné.
- **Accès aux indices clés** : chaque preuve clé n'avait qu'une seule porte d'entrée. Le créneau de 17:30
  (« Vingt minutes, seuls ») n'était reconnu que dans le Calendrier, alors que le même fait est écrit par
  Sterne dans ses messages. Le double de la clé n'était reconnu que dans un message de Sterne, alors qu'Hélène le
  rappelle aussi. Un joueur qui versait le « bon » message ne voyait pas la preuve comptée.
- **Lisibilité** : la photo de 17:52 avait une légende anodine ; rien ne poussait à l'analyser (15 s) alors
  que c'est la preuve la plus élégante. Le constat de l'expert n'était signalé nulle part dans les messages.
- **Quantité d'information** : correcte pour un téléphone réel (176 messages, 40 photos, 9 mails). Le bruit
  reste largement au-dessus du seuil (93,75 % des messages ne sont pas des preuves).
- **Ordre de découverte** : les notifications en direct (Sterne « anéanti », Josiane et le manteau) arrivent
  bien ; le mail du conducteur est non lu et saute aux yeux. Bon rythme.
- **Cohérence des preuves** : l'histoire faisait arrêter Sterne « à la porte » à 22:35, alors qu'il appelle et
  écrit à Salomé à 23:26–23:27. Corrigé : il s'éclipse à 22:35 et il est interpellé chez lui dans la nuit.
- **Clarté des suspects** : bonne. Chacun a un piège (fuite, blague, post, demande d'accès) et un alibi.
- **Difficulté de la conclusion** : juste. Trois faits suffisent à désigner Sterne sans que le jeu ne le dise.
- **Indices** : h1 était une question vague, h2 donnait la réponse technique complète pour 8 points, h3 se
  débloquait trop tard (120 s) pour être utile au niveau expert.
- **Fausses pistes** : loyales. Enzo (fuite), Victor (a lancé le noir, blague sur un « noir en plein
  discours »), Iris (demande d'ouvrir la vitrine, post à 22:17) ont chacun un alibi trouvable.
- **Risques de blocage** : preuves à accès unique (voir plus haut) ; photos montrant des personnages de
  l'affaire (Sterne, Iris, Victor) impossibles à représenter par une vraie photo.

## Chemin minimal de résolution

`"minimalPath": ["e_cue", "e_key", "e_swap_slot", "e_insurance"]`

| Catégorie | Éléments |
|---|---|
| **Essentiels** | `e_cue` (le conducteur : noir « à la demande de M. Sterne »), `e_key` (Sterne garde le double de la clé), `e_swap_slot` (vitrine ouverte 20 min pour lui seul à 17:30), `e_insurance` (valeur assurée portée à 4,2 M€) |
| **Secondaires** | `e_pearls` (41 perles contre 43 : la copie était déjà en vitrine), `e_no_force` (serrure intacte), `e_position` (seul devant la vitrine à 22:13), `e_debts` (dispersion, maison hypothéquée), `e_coat` (manteau à 22:35) ; alibis `e_enzo_alibi`, `e_victor_alibi`, `e_iris_alibi` |
| **Ambiance** | groupe « équipe gala » (logistique, badges, cartels), Camille, Samir, Noémie (presse), Lemaire (socles), Arteo, banque, notes « Appart » et « Après Éclats », photos personnelles |
| **Fausses pistes** | `f_enzo_fled`, `f_victor_cut`, `f_victor_joke`, `f_iris_access`, `f_iris_post` |
| **Inutiles** | coquille du cartel V2, rayure de la vitrine 6, livraison Arteo retardée, footing, météo, reçu de taxi |

Coût estimé du chemin minimal : Mails (conducteur, avenant) + Messages (Sterne) + Calendrier ≈ 20 s d'actions
et 4 lectures, bien sous les 300 s du niveau expert.

## Modifications

1. **Briefing** : le 3e paragraphe nomme les trois théories de la salle (l'extra en fuite, le régisseur, l'animatrice)
   et l'état du prêteur, sans rien conclure. Objectif : « …qui a fait disparaître le collier Aurore, et comment. »
2. **`e_swap_slot`** devient `anyOf` : Calendrier `c_sterne_1730` **ou** message `m_sterne_1712`.
3. **`e_key`** devient `anyOf` : message `m_sterne_key` **ou** `m_helene_008` (« M. Sterne garde le double ») ;
   le sens précise que la clé de Salomé était au coffre.
4. **`e_position`** devient `anyOf` : analyse de `p_room_2213` **ou** message de Noémie `m_noemie_012`, qui
   dit désormais « M. Sterne est scotché à sa vitrine » (la photo ne montre plus qu'une silhouette de dos).
5. **Photo de 17:52** : légende « …(juste après le « nettoyage ») » pour relier la photo au créneau de 17:30.
6. **`m_sterne_007`** : Salomé annonce que le constat de l'expert « arrive ce soir par mail, avec la photo de
   face » : le joueur sait où chercher la description du collier.
7. **`m_victor_2216`** : Victor cite lui-même « top Q47, 90 s » (le texte de l'écran de la console n'est plus
   lisible sur une vraie photo).
8. **Indices en paliers** : h1 (0 pt) = la zone (l'après-midi du 12, Calendrier et Photos) ; h2 (5 pts) = quoi
   comparer (description de l'expert contre photo de 17:52, puis qui a eu la vitrine ouverte) ; h3 (10 pts,
   à 180 s) = trois questions dont une seule personne réunit les réponses, plus le mail de l'assureur. Aucun indice ne nomme le coupable.
9. **Cohérence** : fin de l'histoire et sens de `e_coat` (Sterne s'éclipse à 22:35, interpellé dans la nuit).
10. **`minimalPath`** ajouté après `hints`.

Rien n'a changé dans la solution, le coupable, les suspects, les ids ni la logique (substitution à 17:30,
noir commandé, double de la clé, mobile d'assurance).

## Adaptation des photos (vraies photos uniquement)

Fichier : `config/photo_queries/case_004.json`. **32 REAL, 8 PROCEDURAL, 0 CUSTOM.**

| Photo | Avant | Après |
|---|---|---|
| `p_vitrine_1752` (preuve) | collier en vitrine, 41 perles | inchangé (le compte et le fermoir sont dans l'analyse) ; vraie photo d'un collier de perles sur velours |
| `p_b20` | pose du collier, Hélène tient la porte | plus de personne ; **partage la source** de `p_vitrine_1752` (même collier, autre recadrage : la copie ressemble au vrai) |
| `p_vitrine_2216` (preuve) | vitrine vide | inchangé ; vitrine vide sous projecteur |
| `p_b15` | essais lumière sur vitrine vide | **partage la source** de `p_vitrine_2216` (même vitrine sous la poursuite) |
| `p_room_2213` (preuve) | Sterne reconnaissable, main dans la poche | salle vue du fond, une silhouette de dos devant la vitrine ; l'identité passe par le message de Noémie |
| `p_stage_2214` (preuve) | Iris au micro | le micro sur pied d'Iris, dernier point éclairé ; l'alibi passe aussi par le message de Samir |
| `p_regie_2215` (preuve) | écran lisible « Q47… » + reflet de Victor | console lumière dans le noir ; « Q47, 90 s » est dans le message de Victor |
| `p_iris_look` | selfie d'Iris | la robe à sequins sur un cintre |
| `p_jules` | enfant | la dent de lait |
| `p_b17`, `p_b22` | selfies (Camille, Noémie) | table du dîner ; miroir de loge avec les badges |
| `p_b10` | Samir essoufflé | temple de la Sibylle, Buttes-Chaumont |
| `p_old01`, `p_old03` | Salomé de dos ; Camille et Jules | vases sur socles ; château de sable |
| `p_b24` | Hélène au pupitre | pupitre de loin, flou |
| `p_b16` | panneau d'affichage lisible | hall de la gare de Lyon |
| `p_b02`, `p_b08` | écran à lire, rayure à voir | ordinateur en réunion ; vitrines emballées |
| Lieux réels de Paris | — | tour Eiffel dans la brume (vue du perron, avenue du Président-Wilson), Belleville la nuit, Buttes-Chaumont, gare de Lyon |
| PROCEDURAL | — | `p_b04`, `p_b09`, `p_b11`, `p_b12` (documents, captures, reçu), `p_scr01`, `p_scr02` (captures), `p_blur01`, `p_blur02` (photos accidentelles) |

Une seule photo du chat Pistache (`p_b03`) : pas de partage nécessaire.

## Risques restants

- `e_pearls` repose sur le texte de l'analyse (« on compte 41 perles ») : une vraie photo de collier ne se compte
  pas à l'œil. Si le pipeline choisit une image où le fermoir est bien visible de face, l'image contredit un peu
  l'analyse ; à vérifier dans `PHOTO_AUDIT` (préférer un recadrage serré sur les perles).
- `p_room_2213` et `p_stage_2214` doivent rester des photos de salle ou de scène sans visage reconnaissable ;
  les requêtes l'imposent, mais la sélection automatique est à relire.
- Le noir de 22:14 est au cœur de l'affaire, mais les photos de salle sont prises juste avant ou dans une
  pénombre : une photo trop lumineuse pour `p_stage_2214` serait incohérente (`night: true`).
- `e_pearls` n'est plus dans le chemin minimal : un joueur peut conclure juste sans comprendre la double
  substitution. Le rapport de clôture la révèle ; c'est voulu (rejouabilité).
