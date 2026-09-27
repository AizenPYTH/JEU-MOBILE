# Affaire #003 — « APRÈS LA FÊTE » : refonte de la difficulté et des photos

Coupable, suspects, solution et logique inchangés : **Maxime Rivière** a rejoint Paul sur l'escalier de la plage
(rendez-vous de Diane lu par Paul), l'a repoussé, puis a menti (« je ne me suis pas relevé »).

## Difficulté

| | Avant | Après |
|---|---|---|
| Note (1–5) | 4 — beaucoup d'opacité | 3 — intermédiaire |
| Pourquoi | Les deux preuves d'identité (« silhouette jaune » à 02:14 et « seul vêtement jaune » à 23:40) n'existaient que dans le texte d'**analyse** (15 s) de deux photos sans légende parlante, parmi 38 : il fallait deviner lesquelles analyser. | Les mêmes faits sont trouvables par le raisonnement : Louise (suspecte, donc à vérifier) écrit ce qu'elle a vu ; le groupe de la fête parle du sweat moutarde ; la photo du sweat dit à qui il est. |

## Audit (joueur débutant)

- **Contexte / objectif** : clair, mais « vers 2h10 » ne correspondait pas à l'instant clé (02:14). Objectif réécrit :
  « Paul n'est pas tombé seul. Établir qui l'a rejoint sur l'escalier de la plage, entre 2h10 et 2h20. »
- **Accessibilité des preuves clés** : `e_stairs_photo` et `e_yellow` étaient cachées derrière l'analyse de photos
  anodines (« Le ciel au-dessus du bassin », photo de groupe) → difficulté de chance, pas de raisonnement.
  `e_rdv_deleted` (Corbeille) n'avait aucun indice qui y mène avant l'événement en direct de la 7e minute.
- **Lisibilité / quantité** : bonne ; 205 messages, 95 % de bruit. Le lien costume/pressing ↔ veste bleu marine était
  trop fin (et infigurable en photo réelle) : retiré de la preuve, laissé comme bruit.
- **Ordre de découverte** : naturel (Louise, suspecte, est une conversation qu'on ouvre tôt ; les messages non lus de
  Paul attirent l'œil).
- **Cohérence** : la photo de 02:27 disait « le trépied dans le cadre » et « même cadrage » à la fois → corrigé.
- **Suspects** : clairs, chacun a un piège et un alibi. Louise disait « rien vu » : sa déclaration mentionne désormais
  le lampadaire, ce qui oriente vers l'escalier sans rien conclure.
- **Conclusion** : il faut croiser 3 apps (Messages, Photos, Téléphone/Corbeille) et vérifier la fiabilité de Louise.
- **Indices** : l'ancien h3 nommait presque le coupable (« Jeanne cherche quelqu'un dans son lit ») ; refaits en paliers.
- **Fausses pistes** : justes (dette de Louise, parts de Grégoire, mensonge de Diane), chacune démentie par une pièce.
- **Blocage** : aucun élément clé dans un événement en direct ; pas d'app verrouillée.

## Chemin minimal (`minimalPath`)

`e_stairs_photo` → `e_yellow` → `e_not_in_bed` → `e_paul_awake`

1. Louise, 02:34 (`m_louise_019`, ou l'analyse de `p_louise_0214`) : à 02:14 le lampadaire s'allume, quelqu'un en jaune
   descend, quelqu'un attend déjà en bas.
2. Photo `p_group_2340` : le sweat moutarde est celui de Maxime (Basile, `m_party_yellow` : « seul jaune de la soirée »).
3. Maxime, 02:21–02:23 : « en bas, je bois un verre d'eau » alors qu'il dit ne pas s'être relevé.
4. Paul, 02:03 / 02:09 : réveillé, il « règle ça lui-même » (c'est lui qui attend en bas).

- **Essentiel** : les 4 ci-dessus.
- **Secondaire** : `e_rdv_deleted` (le mobile : rendez-vous effacé, désormais signalé par Mamie à 08:50),
  `e_affair`, alibis `e_diane_alibi`, `e_louise_alibi`, `e_gregoire_alibi`.
- **Ambiance** : Laborde/zellige, parents à Porto, colis de Nour, marées, météo, réservation, discours.
- **Fausses pistes** : `f_diane_lie`, `f_louise_debt`, `f_gregoire_found`.
- **Inutile** : pressing / costume (anciennement lié à la veste), idées cadeau pour Paul.

## Modifications

- `objective` réécrit (voir plus haut).
- `m_louise_019` reçoit un texte : lampadaire allumé en pleine pose, « quelqu'un en jaune qui descendait, et il y avait
  déjà quelqu'un en bas ». `m_louise_018` : « Diane dort sur le canapé du salon depuis 2h ».
- Nouveau `m_party_yellow` (Basile, 00:36) : le sweat moutarde, « seul jaune au milieu des chemises blanches ».
- Nouveau `m_family_mamie_0850` (Mamie) : elle a vu passer un message de Diane dans la nuit, qui a disparu → mène à la
  Corbeille par raisonnement.
- `e_stairs_photo` : `anyOf` [`message:m_louise_019`, `photoInfo:p_louise_0214`], titre « Quelqu'un en jaune sous le
  lampadaire ». `e_yellow` : `photo:p_group_2340` (la légende suffit, plus besoin d'analyse).
  `e_diane_alibi` : `anyOf` [`message:m_louise_018`, `photoInfo:p_louise_0206`]. Textes `meaning` mis à jour
  (`e_not_in_bed`, `e_rdv_deleted`, `e_affair`, `e_louise_alibi`).
- Suspects : déclaration et alibi de Louise, alibi et verdict de Diane, verdict de Maxime.
- `pl_stairs` révélé aussi par `m_louise_019`.
- Indices en paliers : h1 (0) zone = la nuit 01:45–02:35, les conversations de ceux qui ne dormaient pas ; h2 (5)
  comparer déclarations / heures des messages, et ce que Louise a vu / tenues ; h3 (10, à 180 s restantes) : le
  vêtement jaune de 02:14 → à qui il appartient → relire le message de 02:23.
- `minimalPath` ajouté ; étapes de `solution.reveal` et `story` ajustées (même histoire).

## Photos (réelles)

Bilan : **32 REAL · 6 PROCEDURAL · 0 CUSTOM** (`config/photo_queries/case_003.json`).

| Photo | Avant → Après | Pourquoi |
|---|---|---|
| p_group_2340 | Photo de groupe, Maxime en sweat jaune → le sweat moutarde seul sur une chaise du salon, légende « offert à Maxime » | Aucun groupe de personnages ; le sweat seul est photographiable et garde la preuve |
| p_louise_0214 | Deux silhouettes (jaune / blanc) sur l'escalier → l'escalier la nuit, lampadaire allumé ; le « jaune » passe dans le message de Louise | Des personnes précises en couleur ne sont pas figurables ; le lampadaire à détecteur et l'heure le sont |
| p_louise_0206 | Diane endormie derrière la baie → la baie vitrée avec la lampe du salon allumée ; Diane dans le message de Louise | Pas de personnage visible |
| p_louise_0227 | « trépied dans le cadre » + « même cadrage » → même cadrage qu'à 02:06 (`shareWith` p_louise_0206) | Incohérence corrigée ; deux recadrages d'une même photo prouvent que l'appareil n'a pas bougé |
| p_diane_biarritz | Lunettes écaille + veste bleu marine → deux tasses et les lunettes, face à l'océan | La veste n'est pas figurable ; les lunettes suffisent |
| p_max_sunglasses | Maxime lisant à la plage Pereire → ses lunettes oubliées sur la table du balcon (`shareWith` p_diane_biarritz) | Plus de personnage ; les mêmes lunettes sur les deux photos |
| p_paul_surf | Jeanne sur la planche → silhouette lointaine, méconnaissable, à Lacanau | Personne reconnaissable |
| p_old_2003 | Jeanne et Paul enfants → le seau rouge sur la dune du Pilat, légende au dos | Idem |
| p_old_2005 | Famille à Noël → la bûche, la nappe rouge | Idem |
| p_porto | Maman de dos → rue d'azulejos seule | Idem |
| p_old_2022 | Maxime assis par terre → cartons et plante | Idem |
| p_selfie_mirror | Selfie → tasse et échantillon sur le bureau (scène `office`) | Idem |
| p_phare | Maxime de dos → le phare seul | Idem |
| p_dune | Paul et Grégoire à l'eau → deux planches plantées dans le sable | Idem |
| p_selfie_louise | Selfie joue contre joue → coupes et paillettes sur la terrasse (scène `terrace`) | Idem |
| p_cake | Visages éclairés → bougies dans le noir, mains en bord de cadre | Idem |
| p_gift | Tirage de Jeanne et Paul enfants → tirage de la dune au seau rouge | Cohérence avec p_old_2003 |
| p_zellige | scène `document` → `interior_warm` (vrais carreaux) | Photographiable, pas un document |
| p_blur_party | inchangée (foule floue, tache jaune) | Foule floue non identifiable |
| p_resa, p_meteo, p_marees, p_ticket, p_ceiling, p_pocket | PROCEDURAL | Captures, ticket, photos accidentelles |

Lieux réels privilégiés : Phare du Cap Ferret, Dune du Pilat, Bassin d'Arcachon, Lacanau, Côte des Basques (Biarritz),
rue Notre-Dame et Chartrons (Bordeaux), rocade de Bordeaux, Porto.

## Risques restants

- `AllCasesTests.levelsAndHintsFollowTheRules` attend encore des coûts d'indices `[0, 8, 15]` : les nouveaux coûts
  `[0, 5, 10]` demandés le font échouer tant que le test n'est pas mis à jour.
- Le témoignage de Louise rend l'affaire plus directe : le joueur doit toutefois vérifier que Louise (suspecte, avec un
  mobile) ne ment pas, ce que prouve sa série de photos.
- Unicité du jaune : repose sur la remarque de Basile (« seul jaune »), pas sur une image.
- Les photos p_louise_0206/0227 (maison sous la Voie lactée) et p_diane_biarritz/p_max_sunglasses (partagées) dépendent
  de la qualité des recadrages du pipeline.
