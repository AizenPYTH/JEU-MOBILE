# Affaire #005 « ROUTE DE NUIT » — passe de difficulté et photos réelles

Objectif de la passe : garder le caractère d'enquête (le jeu ne donne jamais la réponse) mais retirer la
difficulté inutile (confusion, information clé trop cachée). Cible : **intermédiaire +**, la plus dure des cinq
mais juste. Solution, coupable (Gilles Arnaud), suspects et logique centrale : inchangés.

## Difficulté (1 à 5)

| | Avant | Après |
|---|---|---|
| Raisonnement (croiser deux « Julien », un numéro, une voiture) | 4 | 4 |
| Accès aux indices clés | 4 | 3 |
| Lisibilité / cohérence | 3 | 2 |
| Risque de blocage | 3 | 2 |
| **Ressenti global** | **4,5** | **3,5 – 4** |

La note affichée sur le dossier (`rating: 4`) reste juste.

## Audit (partie jouée en nouveau joueur)

- **Contexte / objectif** : clairs. « Identifier la personne qui a donné rendez-vous à Solène au col » pose la
  bonne question. Le synopsis disait « Il pleut » alors que tout le téléphone parle de brouillard : corrigé.
- **Les deux Julien** (cœur de l'affaire) : bien construit et juste. L'ancien numéro écrit en minuscules sans
  accents, le « nouveau » écrit proprement, ne connaît pas l'heure prévue, refuse les appels ; à 21:03 le vrai
  est gardé aux urgences, à 21:40 l'autre « peut finalement ». Rien à cacher de plus, rien à révéler de plus.
- **Le numéro dans la signature** (clé) : trop caché pour une mauvaise raison. Le contact affichait
  `+33 7 58 11 20 94`, le mail de 2024 `07 58 11 20 94` : deux écritures différentes, et la recherche globale
  ne les rapprochait pas. Difficulté opaque → même écriture des deux côtés.
- **Le 4×4** (clé + appui) : reposait sur des détails qu'aucune photo réelle ne peut porter (macaron « ÉLU »
  lisible, autocollant du club de ski). Réécrit : les deux photos montrent **la même photographie réelle**
  (deux recadrages, `shareWith`), et le texte dit où la première a été prise (place réservée à l'adjoint à
  l'urbanisme). Le Berlingo blanc du vrai Julien (message du 15/10) reste le contre-exemple.
- **Incohérence** : un appel **décroché de 70 s** du faux Julien à 22:52 — Solène aurait reconnu la voix
  d'Arnaud. Passé en appel manqué.
- **Alibi de Julien** : le texte citait un bracelet d'hôpital lisible et une chute « à 17:20 » que rien dans
  le téléphone ne montrait. Réécrit sur ce que le téléphone porte : photo prise aux urgences (18:38, CHU),
  appel de 19:12, message de 21:03 (et le message en direct de 00:54).
- **Suspects** : cinq, chacun avec mobile + alibi vérifiable. Le rôle de Julien dans les contacts (« Carrière »)
  était flou → « Carrière Brassac — conducteur d'engins ».
- **Fausses pistes** : justes (menace de Brassac, menace de garde de Romain, Agathe savait, message de 23:47
  du faux Julien). Chacune est démontée par un alibi horodaté.
- **Quantité d'information** : 157 messages, 38 photos, 10 mails ; bruit messages ≈ 96 % (> 70 % requis).
  Conservé : c'est la difficulté voulue (affaire la plus dense).
- **Indices payants** : l'ancien h1 donnait déjà la clé (« sont-ils la même personne ? »), h3 nommait le 4×4.
  Réécrits en paliers.
- **Détail** : la photo du pot de Lina était datée du 13/11 alors que le pot a lieu le vendredi 30/10 : recalée.

## Chemin minimum de résolution

`minimalPath` = `e_two_juliens`, `e_signature`, `e_4x4`, `e_same_car`

- **Essentiel** : `e_two_juliens` (le « nouveau » Julien n'est pas Julien), `e_signature` (ce numéro est la
  ligne directe d'Arnaud), `e_4x4` + `e_same_car` (le 4×4 du col est celui garé sur la place de l'adjoint).
- **Secondaire** (renforce, non requis) : `e_motive` (25 000 € à « G.A. »), `e_council_early` (conseil levé à
  21h10, il part le premier), alibis `e_julien_alibi`, `e_thierry_alibi`, `e_romain_alibi`, `e_agathe_alibi`.
- **Ambiance** : vie de famille (Romain, Maman, nounou, école), rédaction, garage, pistes de fond, photos du
  plateau, notes (courses, Wi-Fi, sujets, garde), navigateur.
- **Fausses pistes** : `f_julien_rdv` (« Je suis au parking du col » à 23:47), `f_brassac_threat`,
  `f_romain_custody`, `f_agathe_knew`.
- **Inutile** : chat de Maman, dent de Léo, Halloween, météo, facture des pneus, photos accidentelles.

## Indices (paliers)

| id | coût | contenu |
|---|---|---|
| h1 | 0 | Zone : les Messages, les deux conversations « Julien », vendredi soir. |
| h2 | 5 | Nature : comparer les heures (21:03 / 21:40) et les numéros ; un numéro peut réapparaître dans la signature d'un vieux mail. |
| h3 | 10 (dès 180 s restantes) | Orientation forte : la voiture de 23:14 n'est pas celle de Julien ; retrouver ce 4×4 plus tôt dans la pellicule ; qui a quitté sa réunion en avance. Le coupable n'est jamais nommé. |

## Liste des modifications (case_005.json)

1. Synopsis : « Il pleut » → brouillard sur le plateau.
2. Contact `julien` : rôle précisé.
3. `mail_arnaud_2024` : « Portable (ligne directe) : +33 7 58 11 20 94 » (même écriture que la fiche contact).
4. `k_new_2252` : appel entrant de 70 s → appel manqué.
5. `m_julien_platre` : texte adapté à la nouvelle photo (« vue de mon brancard… »).
6. Photos réécrites (voir ci-dessous) ; `e_4x4`, `e_same_car`, `e_julien_alibi`, `e_romain_alibi`, `e_signature`
   (sens), étapes de révélation, alibis/verdicts de Julien, Romain et Gilles mis en accord.
7. Indices h1/h2/h3 réécrits (coûts 0 / 5 / 10, h3 à 180 s).
8. Nouveau champ `minimalPath` juste après `hints`.

## Photos (config/photo_queries/case_005.json)

29 REAL · 9 PROCEDURAL · 0 CUSTOM.

- **PROCEDURAL** (captures et papiers à lire, photos accidentelles) : `p_n06`, `p_n09`, `p_n12`, `p_n13`,
  `p_n14`, `p_n15`, `p_n20`, `p_doc_virements` (relevé, ligne du 12/09 à lire), `p_bat_2301` (BAT à lire).
- **Personnages retirés de l'image** :
  - `p_old02` Léo dans l'escalier → l'escalier du jardin, un seau oublié.
  - `p_old03` silhouettes autour d'une table → le gâteau aux bougies 3 et 0.
  - `p_old04` premiers pas de Nina → le parc Paul-Mistral, une poussette vide.
  - `p_n02` silhouettes des enfants → le sentier en automne.
  - `p_n05` Léo et Nina déguisés → la citrouille sur le pas de la porte (photo de nuit).
  - `p_n11` selfie de groupe → le gâteau de Lina en salle de conf (date corrigée au 30/10).
  - `p_r_dent` Léo sourit → la dent de lait dans la boîte d'allumettes.
  - `p_kids_2305` (preuve, alibi de Romain) → la chambre des enfants, lits superposés, veilleuse ; la preuve
    reste l'heure (23:04) et le lieu (Île Verte) des métadonnées.
  - `p_platre` (preuve, alibi de Julien) → le couloir des urgences vu du brancard ; la preuve reste l'heure
    (18:38), le lieu (CHU) et l'appareil (Galaxy A52, celui du relevé).
- **Texte lisible retiré** : banderole « Bonne retraite Jacques » (`p_old06`), « papa » barré (`p_n08`),
  « Accès interdit » (`p_n17`), thermomètre du tableau de bord (`p_n23`), panneau du col (`p_n24`),
  macaron « ÉLU » et autocollant (`p_mairie_4x4`, `p_col_2314`).
- **Même véhicule** : `p_col_2314` a `shareWith: p_mairie_4x4` (requête « dark grey SUV parked night ») :
  deux recadrages de la même photo réelle, de nuit.
- **Lieux réels du Vercors / de l'Isère** privilégiés : Villard-de-Lans, Moucherotte, Autrans, Bois Barbu,
  col de la Croix-Perrin, parc Paul-Mistral (Grenoble). Vallières-en-Vercors est fictif : requêtes génériques.
- Nuit (`night: true`) : `p_n05`, `p_n18`, `p_n22`, `p_n23`, `p_n24`, `p_mairie_4x4`, `p_col_2314`,
  `p_kids_2305`.

## Risques restants

- **Test `levelsAndHintsFollowTheRules`** (AllCasesTests) attend encore les coûts `[0, 8, 15]` : il faut
  l'aligner sur la nouvelle grille `[0, 5, 10]` (fichier hors de mon périmètre).
- **Catalogue photo** (`config/photo_catalog.json`) : à régénérer (`./scripts/photos.sh audit`) ; le test
  actuel impose CUSTOM_REQUIRED aux photos preuves alors que la nouvelle règle les veut REAL.
- **Le 4×4** : l'identification repose désormais sur l'image partagée. Si le pipeline ne trouve pas de photo
  (rendu procédural en attendant), les scènes `parking_night` et `road_night` diffèrent : le lien passe alors
  par le texte seul (« 4×4 gris foncé » des deux côtés + place de l'adjoint). Plus faible qu'avant ; la preuve
  par le numéro (`e_signature`) suffit à conclure.
- Le brouillard de `p_col_2314` n'est pas dans la photo source (partagée avec une photo de mairie) : à rendre
  par le style de l'image si le pipeline le permet.
- Densité : l'affaire reste longue à lire en Expert (5 min) ; la recherche globale et h1 compensent.
