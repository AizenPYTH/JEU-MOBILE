# Affaire #002 « PREMIER MÉTRO » : fiche de conception

Lyon, nuit du 16 au 17 octobre 2026. Clémence Aubry, régisseuse son au Silo (Confluence), disparaît après son
service. Son téléphone est retrouvé à 05:12 sur un banc de Terreaux-Sud. Coupable (inchangé) : **Mathilde Roche**,
la gérante. Clémence l'a signalée à l'inspection du travail. Mathilde a récupéré Clémence en voiture, a gardé son
téléphone, a écrit « je dors chez Yanis » à la sœur depuis chez elle (quai Arloing, Vaise), puis a déposé l'appareil
dans le métro.

## Difficulté

| | Avant | Après |
|---|---|---|
| Difficulté ressentie (1–5) | 3 | 2 (ACCESSIBLE) |
| Pièces à trouver pour comprendre | 5 à 6 (dont une adresse enfouie dans l'agenda de septembre) | 4 (chemin minimal), toutes visibles sans charger d'anciens messages, sauf un chemin facultatif |
| Indices | 0 / 8 / 15 points, le 3ᵉ s'ouvre à 2 min de la fin | 0 / 5 / 10 points, le 3ᵉ s'ouvre à 4 min de la fin |

## Audit (partie jouée comme un nouveau joueur)

- **Contexte et objectif** : clairs (disparition, téléphone dans le métro). Le synopsis parlait d'un « message
  rassurant » sans en donner l'heure, et l'objectif (« après 2h30 ») ne disait pas quoi chercher. On donne
  maintenant l'heure du message (3h07) et on demande de retracer la nuit du téléphone : le joueur sait où regarder,
  sans qu'on lui dise que le message est faux.
- **Accès aux indices clés** : le message de 03:07 est dans la première page de la conversation avec Anaïs. L'appel
  de 02:19 est en haut du journal. Le trajet « Moi » est dans Localisation. Le dernier message de Mathilde (« Pas au
  club ») est visible tout de suite. **Point bloquant** : la seule preuve que Mathilde habite quai Arloing était
  un événement d'agenda du 27 septembre (« Apéro staff chez Mathilde »), trois semaines avant les faits. Le message
  du groupe disait seulement « L'adresse est dans l'invitation ». Un joueur qui ne remonte pas l'agenda voyait le
  téléphone à Vaise sans pouvoir le relier à personne. Il n'y a ni app verrouillée, ni corbeille, ni mot de passe.
- **Lisibilité et quantité** : 239 messages, 38 photos, 13 conversations. C'est un téléphone réaliste et bruité
  (97 % de bruit). La quantité reste raisonnable, parce que les pièces décisives se trouvent dans les dernières
  heures.
- **Ordre de découverte** : le message en direct d'Anaïs à 25 s (« yanis dit qu'elle est jamais venue chez lui »)
  lance bien la piste. Le rappel de l'inspection à 200 s oriente vers le mobile.
- **Cohérence des preuves** : bonne. Clémence écrit toujours sans majuscules ni accents, et seul le message de
  03:07 fait exception (vérifié sur tous ses messages). L'horaire est cohérent (02:19 appel, 02:24 Docks, 02:46
  appel coupé, 02:58 à 04:36 quai Arloing, 04:31 recherche du premier métro, 04:52 Terreaux).
- **Suspects** : quatre, chacun avec un piège crédible. Yanis a le « tu vas le regretter » et le message qui le
  nomme. Bastien a menti en disant qu'il dormait. Raphaël est le dernier à l'avoir vue et se montrait insistant.
  Mathilde s'est fait un alibi (« rentrée directement à Vaise »), et c'est justement ce qui la trahit.
- **Conclusion** : il faut croiser trois apps (Messages, Localisation, Téléphone), plus Agenda, Mail ou Photos pour
  l'adresse. C'est juste.
- **Indices** : l'ancien h2 était déjà très directif (« cherchez qui habite là »), et le h3 arrivait trop tard
  (2 min) pour aider un joueur bloqué.
- **Fausses pistes** : elles sont loyales. Chaque innocent est disculpé par une pièce datée : la photo de 02:48 et
  le planning pour Yanis, la position partagée pour Bastien, la photo de 03:04 pour Raphaël.
- **Risques de blocage** : l'adresse de Mathilde (voir plus haut). Deux autres pièces reposaient sur des détails
  visuels impossibles avec de vraies photos : le porte-clés rouge au « M » doré, et le reflet d'une doudoune avec
  l'heure lisible sur une enseigne.

## Chemin minimal de résolution

`"minimalPath": ["e_fake_message", "e_call", "e_address", "e_motive"]`

- **Essentiel** :
  - `e_fake_message` (message de 03:07 + trajet « Moi ») : envoyé depuis Vaise, et pas écrit comme Clémence.
  - `e_call` (appel de Mathilde à 02:19) : Mathilde dit ne pas l'avoir revue.
  - `e_address` : Mathilde habite 14 quai Arloing. On la trouve par l'agenda, le message du groupe staff ou la photo
    de l'apéro.
  - `e_motive` : le signalement à l'inspection et « Il faut qu'on parle ce soir. Pas au club. »
- **Secondaire** : `e_keyring` (« La photo de 03:09 », salon de Mathilde), `e_cut_call` (appel coupé de 02:46),
  les alibis `e_yanis_alibi`, `e_bastien_alibi`, `e_raphael_alibi`.
- **Ambiance utile** : le planning du 16 (mail), la recherche « premier métro » à 04:31, la météo (4 °C), les messages
  en direct.
- **Fausses pistes** : `f_yanis_threat`, `f_named_yanis`, `f_bastien_lie`, `f_raphael_last`.
- **Inutile (bruit)** : la chaudière, le dentiste, le loyer, Pistache, les courses, les runs avec Lou, les vinyles,
  l'anniversaire de Papa, le patch de synthé, la banque.

## Modifications

1. Synopsis : l'heure du message rassurant (3h07) est donnée, et la dernière phrase parle de retracer la nuit du
   téléphone.
2. Objectif : « Découvrir qui avait le téléphone de Clémence entre 2h30 et 5h du matin. »
3. Adresse de Mathilde plus accessible : le message du groupe staff du 27/09 (`m_staff_012`) donne maintenant
   l'adresse complète. `e_address` devient `anyOf` avec trois chemins : l'agenda, ce message, ou la photo de l'apéro
   analysée (géolocalisée quai Arloing). Le lieu `pl_arloing` est aussi révélé par ces deux nouvelles sources.
4. Les trois indices sont réécrits par paliers :
   - h1 (0 pt) : la zone (nuit de 2h à 5h ; Messages/Anaïs, appels, Localisation) ;
   - h2 (5 pts) : ce qu'il faut comparer (l'heure et le lieu de chaque message, la façon d'écrire) ;
   - h3 (10 pts, disponible à 240 s de la fin) : le message de 03:07 part de Vaise, puis qui y habite et qui a appelé
     juste après la sortie. Le coupable n'est jamais nommé.
5. Ajout de `minimalPath`.
6. Le sens de `e_fake_message` précise le contraste d'écriture (« partout ailleurs, pas de majuscules »).
7. `e_keyring` s'appelle maintenant « La photo de 03:09 » : parquet clair et table basse en bois clair, comme sur
   la photo de l'apéro. L'étape de révélation et le récit sont mis à jour. Solution, coupable et logique inchangés.
8. Alibis de Yanis et Raphaël réécrits sur les métadonnées (heure, lieu, téléphone qui a pris la photo) plutôt que
   sur un détail visuel.
9. Pas de changement de durée (480 s en Détective) : le test `levelsAndHintsFollowTheRules` impose
   900/480/300. Le chemin minimal tient largement dans ce temps.

## Photos (règle « vraies photos »)

31 REAL, 7 PROCEDURAL, 0 CUSTOM. Les requêtes sont dans `config/photo_queries/case_002.json`. Les lieux lyonnais
réels ont la priorité : passerelle Saint-Vincent, montée de la Grande-Côte, berges du Rhône / pont de la
Guillotière, marché de la Croix-Rousse, métro de Lyon, rue de la République, anciennes usines Fagor pour la salle
de La Friche Nord.

| Photo | Avant → après | Pourquoi |
|---|---|---|
| p_old06 | « Selfie en cabine avec Yanis » → « La cabine du Silo, mai 2025 », deux casques sur les platines | pas de personnage à l'image |
| p_loge01 | selfie dans le miroir → le miroir de la loge, un casque sur la tablette (style selfie retiré) | pas de personnage |
| p_berges02 | selfie avec Lou → les berges du Rhône, le pont de la Guillotière | pas de personnage |
| p_selfie01 | selfie en régie (scène selfie) → la salle vue depuis la régie, foule de dos (scène club, nuit) | pas de personnage |
| p_quick01 | affiche lisible « Basses Fréquences… » → affiches superposées et arrachées sur un poteau | aucun texte lisible requis |
| p_vinyl01 | étiquette « 12 € » → un autocollant de prix | aucun texte lisible requis |
| p_old02 | « des gens qui dansent » → la foule vue de loin | pas de visage identifiable |
| p_pistache_synth | chat assis sur le rack → chat couché à côté du rack | image réelle plus facile à trouver |
| p_issue_1 / p_issue_2 | porte « marquée Sortie de secours » → porte verte, l'issue de secours de la cour ; même source (`shareWith`) | pas de texte lisible, même porte sur les deux |
| p_apero_keys (preuve) | clés au porte-clés rouge « M » → table basse en bois clair, parquet, verres, bougies ; lieu « Quai Arloing — Vaise » | objet trop précis pour une photo libre ; l'indice passe par le lieu et le salon |
| p_pocket_0309 (preuve, PROCEDURAL) | porte-clés « M » → parquet clair, pied de table basse en bois clair, flamme de bougie | cohérent avec la nouvelle photo de l'apéro |
| p_booth_0248 (preuve) | « Yanis aux platines », horloge lisible 02:48 → silhouette à contre-jour vue de la piste | l'heure vient des métadonnées, le nom vient du message de Kader |
| p_door_0304 (preuve) | reflet de la doudoune de Raphaël + heure sur l'enseigne → file de dos, prise depuis la porte par le téléphone de Raphaël | pas de personne identifiable ni de texte lisible ; l'alibi repose sur les métadonnées |

Les autres photos réelles ne changent pas, puisqu'elles montrent déjà un lieu ou un objet. Photos PROCEDURAL :
p_ceiling01, p_pocket_0309 (photos prises par erreur), p_receipt01, p_invoice01, p_contract (papiers), p_run_screen,
p_meteo (captures).

## Risques restants

- **Test** : `AllCasesTests.levelsAndHintsFollowTheRules` attend des coûts d'indices `[0, 8, 15]`. Les nouveaux
  coûts `[0, 5, 10]` demandés le feront échouer tant que le test n'est pas mis à jour pour toutes les affaires.
- L'alibi de Raphaël repose maintenant sur les métadonnées de sa photo (heure, lieu, appareil). C'est un peu moins
  spectaculaire que le reflet de sa doudoune, mais c'est loyal.
- `e_keyring` rapproche deux photos par leur description (parquet clair, table basse en bois clair). Le lien visuel
  dépend donc des images que le pipeline choisira. La preuve reste secondaire, et la géolocalisation quai Arloing
  la porte.
- Le h3 est très directif (Vaise, puis l'appel juste après la sortie). C'est voulu pour une affaire ACCESSIBLE.
- La requête « cat synthesizer » (p_pistache_synth) peut ne rien donner : les requêtes de secours ramènent un chat
  sur un bureau.
