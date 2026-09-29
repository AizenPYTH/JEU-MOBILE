# Audit des photos du jeu

Généré par `./scripts/photos.sh audit` à partir des affaires (`ScreenshotKit/Sources/CaseLibrary/Resources/Cases`, mode principal et ALIBI) et des fiches `config/photo_queries/case_NNN.json`.
Ne pas éditer à la main : modifier les fiches de requêtes ou `config/photo_pipeline.json`, ou marquer une entrée `"manual": true` dans `config/photo_catalog.json`, puis relancer.

## Synthèse

| Affaire | Photos | KEEP_REAL | REPLACE_REAL | CUSTOM_REAL | PROCEDURAL | REMOVE | Sources |
|---|---|---|---|---|---|---|---|
| #001 LE DERNIER MESSAGE | 58 | 0 | 47 | 1 | 10 | 0 | 47 |
| #002 PREMIER MÉTRO | 38 | 0 | 30 | 1 | 7 | 0 | 29 |
| #003 APRÈS LA FÊTE | 38 | 0 | 29 | 3 | 6 | 0 | 27 |
| #004 90 SECONDES | 40 | 0 | 31 | 1 | 8 | 0 | 29 |
| #005 ROUTE DE NUIT | 38 | 0 | 27 | 2 | 9 | 0 | 26 |
| ALIBI #001 LE DÎNER | 10 | 0 | 9 | 0 | 1 | 0 | 9 |
| ALIBI #002 LE DERNIER MÉTRO | 9 | 0 | 8 | 0 | 1 | 0 | 8 |
| ALIBI #003 LE RENDEZ-VOUS | 9 | 0 | 6 | 2 | 1 | 0 | 6 |
| ALIBI #101 LE DOSSIER VARIN | 25 | 0 | 21 | 0 | 4 | 0 | 21 |
| **Total** | **265** | **0** | **208** | **10** | **47** | **0** | **202** |

Décisions :

- **KEEP_REAL** — vraie photographie déjà livrée, provenance documentée, conservée.
- **REPLACE_REAL** — vraie photographie d'une bibliothèque libre (Wikimedia Commons, Pexels, Openverse), choisie par la fiche de requêtes de l'affaire, vérifiée (sujet, lieu, nuit/jour, licence, pas d'IA) et recadrée. Une preuve n'y a droit que si sa fiche le dit (ce qu'elle prouve tient à son heure, son lieu ou son sujet) ; deux photos de la même chose partagent la même photographie (deux cadrages).
- **CUSTOM_REAL** — vraie photo à prendre nous-mêmes (aucune photo libre ne peut montrer ce que l'affaire décrit).
- **PROCEDURAL** — capture d'écran, document, ticket, photo ratée : un rendu du téléphone, pas une photographie.
- **REMOVE** — image à supprimer (IA, provisoire, inutilisée).

## REAL PHOTO COMPLIANCE

Règle du studio : aucune image générée par IA dans les téléphones et les galeries ; toute photo montrée comme une photographie est une vraie photographie (bibliothèque libre documentée, ou prise par nous).

| | |
|---|---|
| Photos des téléphones (toutes affaires) | 265 |
| Vraies photos livrées (photographies réelles) | **150** |
| — dont externes : openverse 21 · wikimedia 129 | 150 |
| Vraies photos prises par le studio (CUSTOM_REAL livrées) | 0 |
| Vraies photos encore à récupérer (REPLACE_REAL sans image acceptable pour l'instant) | 58 |
| Vraies photos à prendre nous-mêmes (CUSTOM_REAL) | 10 |
| Rendus du jeu voulus (captures d'écran, documents, tickets — pas des photographies) | 47 |
| Images IA supprimées | 5 |
| Images IA restantes dans les zones photo | 0 |

Images IA supprimées :

- `portrait_001_karim` — portrait « photo d'identité » de Karim (dossier #001) (image générée par IA — remplacée par les initiales)
- `portrait_001_sarah` — portrait « photo d'identité » de Sarah (dossier #001) (image générée par IA — remplacée par les initiales)
- `player_elise_a` — photo de l'enquêtrice Élise Morel (Qui enquête ?, profil) (image générée par IA — remplacée par les initiales)
- `player_vincent_a` — photo de l'enquêteur Vincent Delmas (Qui enquête ?, profil) (image générée par IA — remplacée par les initiales)
- `npc_lacaze` — photo du commandant Lacaze (affectation) (image générée par IA — remplacée par les initiales)

Tant qu'une vraie photo n'est pas livrée, le téléphone montre un rendu dessiné par le jeu, stylisé, qui ne se fait pas passer pour une photographie réelle (aucune image IA n'est jamais utilisée).

Exceptions (photo réelle pas encore livrée) :

| Photo | Décision | Justification |
|---|---|---|
| `case103_photo_p3_meinau` — Les tribunes éclairées du stade, vues d'en haut. | CUSTOM_REAL | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. |
| `case103_photo_p3_echantillons` — Des échantillons de carrelage alignés sur une table. | CUSTOM_REAL | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. |
| `case001_photo_p_b26` — Le haut du mur, vu d'en bas. | CUSTOM_REAL | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. |
| `case002_photo_p_old04` — Coucher de soleil sur la Saône, juillet 2023. | CUSTOM_REAL | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. |
| `case003_photo_p_group_2340` — Le sweat moutarde que j'ai offert à Maxime à Noël. Il l'a enfin sorti 🙄 | CUSTOM_REAL | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. |
| `case003_photo_p_sky_july` — Ciel rose au-dessus des toits des Chartrons. | CUSTOM_REAL | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. |
| `case003_photo_p_cake` — Le gâteau et ses deux bougies « 3 » et « 0 ». | CUSTOM_REAL | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. |
| `case004_photo_p_b23` — Les premiers invités. | CUSTOM_REAL | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. |
| `case005_photo_p_n16` — Autrans, première neige qui tient. | CUSTOM_REAL | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. |
| `case005_photo_p_r_dent` — La dent de Léo dans une boîte d'allumettes. | CUSTOM_REAL | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. |
| `case101_photo_p_affiche` — Des épreuves d'affiches étalées sur une grande table du studio. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case101_photo_p_grue` — La grue jaune éclairée, de nuit, au bord de la Loire. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case102_photo_p2_rame` — L'intérieur d'une rame de métro presque vide. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case001_photo_p_b06` — Le Levant, terrasse du fond. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case001_photo_p_b12` — Le canapé de Lucas, enfin monté. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case001_photo_p_b17` — Montage de l'expo Lumen au local. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case001_photo_p_b19` — Fin du vernissage : la table de la buvette. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case001_photo_p_b23` — Lever de soleil depuis la fenêtre. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case001_photo_p_b27` — Le local Lumen, rangé après l'expo. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case001_photo_p_b29` — La vidéo que Tom fait tourner à table. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case001_photo_p_self02` — Plage des Catalans, fin d'après-midi avec Lucas. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case001_photo_p_blur03` — Le Levant, photo ratée. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case001_photo_p_lucas_car` — La citadine grise de Lucas, sortie du garage. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case001_photo_p_bar_selfie` — Le Levant : la table du fond, avant le départ de Karim. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case001_photo_p_emma_couch` — « Chez moi » : la couette, une tasse fumante, la télé allumée. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case001_photo_p_sarah_jade` — L'anniversaire de Jade : ballons et guirlandes. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case002_photo_p_loge01` — Le miroir de la loge, avant le service. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case002_photo_p_quick01` — Des affiches collées sur un poteau, pentes de la Croix-Rousse. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case002_photo_p_night01` — La montée de la Grande-Côte, de nuit. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case002_photo_p_club02` — Le Silo avant la soirée Basses Fréquences. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case002_photo_p_issue_1` — La cour du Silo, de nuit : des fûts empilés. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case002_photo_p_issue_2` — La cour du Silo, encore les fûts. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case002_photo_p_apero_keys` — Apéro chez Mathilde : des verres sur la table basse. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case002_photo_p_booth_0248` — La cabine DJ, lumières rouges. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case002_photo_p_door_0304` — La file d'attente devant l'entrée du Silo. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case003_photo_p_diane_biarritz` — « Week-end entre filles » : un café en terrasse face à l'océan. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case003_photo_p_max_sunglasses` — Maxime a encore oublié ses lunettes sur la table du balcon. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case003_photo_p_old_2022` — Emménagement aux Chartrons, juin 2022. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case003_photo_p_selfie_mirror` — L'agence, 8h10 : premier café. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case003_photo_p_night_chartrons` — La rue Notre-Dame, la nuit. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case003_photo_p_quick_car` — Bouchons à la sortie de Bordeaux. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case003_photo_p_huitres` — Pause huîtres au port. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case003_photo_p_selfie_louise` — L'apéro sur la terrasse : des paillettes partout. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case003_photo_p_blur_party` — Tout le monde danse dans le salon. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case004_photo_p_b02` — Le plan v1 à l'écran, en réunion. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case004_photo_p_b05` — L'atelier de PY à Bagnolet. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case004_photo_p_b08` — Livraison des vitrines. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case004_photo_p_b13` — Épreuves du catalogue. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case004_photo_p_b15` — Essais lumière en salle 2. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case004_photo_p_b18` — Montage du 11 novembre. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case004_photo_p_b21` — La salle prête, avant l'ouverture. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case004_photo_p_b22` — La loge, juste avant l'ouverture. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case004_photo_p_b24` — Discours d'Hélène, pris de loin. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case004_photo_p_vitrine_2216` — La vitrine 4, vide, sous la poursuite. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case004_photo_p_room_2213` — La salle 2 pendant la présentation d'Iris. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case004_photo_p_regie_2215` — La console de la régie, dans le noir. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case005_photo_p_old06` — Pot de départ de l'ancien secrétaire de rédaction. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case005_photo_p_n05` — Halloween : la citrouille devant la porte des voisins. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case005_photo_p_n07` — Conférence de rédaction. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case005_photo_p_n08` — Les dessins de Nina sur le frigo. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case005_photo_p_n17` — La carrière depuis le chemin forestier. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case005_photo_p_n18` — Villard, la grande rue sous la pluie. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case005_photo_p_n21` — La rédaction, avant la conf. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case005_photo_p_n22` — La cour sous la pluie. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. |
| `case005_photo_p_mairie_4x4` — La cour de la mairie de Vallières, avant le conseil. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case005_photo_p_platre` — Le couloir des urgences, vu depuis un brancard. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case005_photo_p_kids_2305` — La chambre des enfants, veilleuse allumée. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |
| `case005_photo_p_col_2314` — Un 4×4 se gare sur le parking du col. | REPLACE_REAL | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). |

## #001 LE DERNIER MESSAGE

| ID | Écran | Fonction | Preuve | Décision | Raison | Remplacement |
|---|---|---|---|---|---|---|
| `p_b01` | Photos | sunset — Coucher de soleil sur le port, depuis le J4. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_port_de_marseille_coucher_de_soleil_01 (variante 1) |
| `p_b02` | Photos | climbing — La voie jaune que Tom a enchaînée. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_mur_d_escalade_bloc_prises_jaunes_01 (variante 1) |
| `p_b03` | Photos | rain — Pluie sur la fenêtre du bureau. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_gouttes_de_pluie_vitre_01 (variante 1) |
| `p_b04` | Photos | street_day — Le cours Julien, en plein soleil. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_cours_julien_marseille_01 (variante 1) |
| `p_b05` | Photos | concert · nuit — Concert au parc Borély — lumières violettes. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_concert_scene_lumieres_violettes_nuit_night_01 (variante 1) |
| `p_b06` | Photos | bar · nuit — Le Levant, terrasse du fond. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_terrasse_bar_guirlandes_nuit_night_01 (variante 1) |
| `p_b07` | Photos | cat — Le chat de la voisine sur le palier. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_chat_roux_endormi_paillasson_01 (variante 1) |
| `p_b08` | Photos | screenshot — Capture : horaires de la salle d'escalade. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone (texte exact) | aucun : rendu procédural conservé |
| `p_b09` | Photos | books — Étagère de livres photo. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_etagere_livres_de_photographie_01 (variante 1) |
| `p_b10` | Photos | sky — Ciel très bleu, une traînée d'avion. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_ciel_bleu_trainee_d_avion_01 (variante 1) |
| `p_b12` | Photos | interior_warm — Le canapé de Lucas, enfin monté. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_canape_neuf_cartons_demenagement_01 (variante 1) |
| `p_b13` | Photos | station — Gare Saint-Charles, le matin. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_gare_saint_charles_hall_01 (variante 1) |
| `p_b14` | Photos | laptop — Maquette Varenne à l'écran. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_ordinateur_portable_bureau_ecran_design_01 (variante 1) |
| `p_b15` | Photos | street_night · nuit — La rue Vauban sous les réverbères. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_rue_vauban_marseille_nuit_night_01 (variante 1) |
| `p_b16` | Photos | interior_warm — Colis reçu : une nouvelle optique 35 mm. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_objectif_appareil_photo_35mm_bureau_01 (variante 1) |
| `p_b17` | Photos | gallery — Montage de l'expo Lumen au local. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_cadres_bois_contre_mur_galerie_01 (variante 1) |
| `p_b19` | Photos | gallery — Fin du vernissage : la table de la buvette. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_verres_vides_table_nappe_blanche_01 (variante 1) |
| `p_b20` | Photos | park — Balade au parc Borély le lendemain. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_parc_borely_marseille_01 (variante 1) |
| `p_b21` | Photos | screenshot — Capture : météo de la semaine. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone (texte exact) | aucun : rendu procédural conservé |
| `p_b22` | Photos | climbing — Mur de bloc, voie bleue. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_mur_de_bloc_prises_bleues_magnesie_01 (variante 1) |
| `p_b23` | Photos | sky — Lever de soleil depuis la fenêtre. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_toits_de_marseille_lever_de_soleil_01 (variante 1) |
| `p_b24` | Photos | street_day — Travaux devant l'agence. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_pelleteuse_chantier_trottoir_01 (variante 1) |
| `p_b25` | Photos | plant — Le pothos du salon a doublé de taille. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_pothos_plante_verte_fenetre_01 (variante 1) |
| `p_b26` | Photos | climbing — Le haut du mur, vu d'en bas. | non | **CUSTOM_REAL** | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. | vraie photo à prendre nous-mêmes ; le rendu procédural reste en attendant |
| `p_b27` | Photos | gallery — Le local Lumen, rangé après l'expo. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_cartons_d_archives_empiles_01 (variante 1) |
| `p_b28` | Photos | bar · nuit — Le Levant, la terrasse du fond. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_table_de_bar_verres_soiree_terrasse_night_01 (variante 1) |
| `p_b29` | Photos | bar · nuit — La vidéo que Tom fait tourner à table. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_smartphone_ecran_table_bar_nuit_night_01 (variante 1) |
| `p_b30` | Photos | street_night · nuit — Arrêt de bus, ligne 12, direction Port. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_abribus_nuit_marseille_night_01 (variante 1) |
| `p_old01` | Photos | sky · nuit — Feu d'artifice du 14 juillet, 2019. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_feu_d_artifice_vieux_port_marseille_night_01 (variante 1) |
| `p_old02` | Photos | interior_warm — Confinement : le salon de l'ancien appartement. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_salon_cartons_guitare_contre_le_mur_01 (variante 1) |
| `p_old03` | Photos | beach — Plage des Catalans, août 2021. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_plage_des_catalans_marseille_01 (variante 1) |
| `p_old04` | Photos | interior_warm · nuit — Réveillon chez Maman. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_table_de_reveillon_bougies_night_01 (variante 1) |
| `p_old05` | Photos | snow — Neige à la montagne, février 2023. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_telesiege_sapins_enneiges_alpes_01 (variante 1) |
| `p_old06` | Photos | concert · nuit — Fête de la musique 2024. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_fete_de_la_musique_foule_nuit_night_01 (variante 1) |
| `p_old07` | Photos | gallery — Premier accrochage du collectif Lumen, 2024. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_photographies_encadrees_mur_blanc_escabe_01 (variante 1) |
| `p_self01` | Photos | office — Le café du matin, à l'agence. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_gobelet_cafe_rebord_fenetre_bureau_01 (variante 1) |
| `p_self02` | Photos | beach — Plage des Catalans, fin d'après-midi avec Lucas. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_plage_des_catalans_coucher_de_soleil_01 (variante 1) |
| `p_self03` | Photos | interior_warm — Le lendemain du vernissage : café et fatigue. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_tasse_cafe_table_salon_rideaux_01 (variante 1) |
| `p_blur01` | Photos | pocket — Photo prise dans une poche. | non | **PROCEDURAL** | photo ratée prise dans une poche : rendu flou du jeu | aucun : rendu procédural conservé |
| `p_blur02` | Photos | ceiling — Le plafond de la chambre. | non | **PROCEDURAL** | photo ratée du plafond : rendu flou du jeu | aucun : rendu procédural conservé |
| `p_blur03` | Photos | bar · nuit — Le Levant, photo ratée. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_bar_lumieres_floues_nuit_night_01 (variante 1) |
| `p_quick01` | Photos | street_day — Des affiches de concerts, prises en passant. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_colonne_affiches_concerts_marseille_01 (variante 1) |
| `p_quick02` | Photos | car — Une voiture mal garée devant l'agence. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_voiture_garee_sur_le_trottoir_01 (variante 1) |
| `p_night01` | Photos | street_night · nuit — La rue en bas, depuis la fenêtre. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_rue_de_nuit_vue_d_une_fenetre_scooter_night_01 (variante 1) |
| `p_night02` | Photos | view · nuit — La ville depuis le toit de l'immeuble. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_marseille_de_nuit_notre_dame_de_la_garde_night_01 (variante 1) |
| `p_doc01` | Photos | receipt — Ticket de caisse — supérette. | non | **PROCEDURAL** | ticket de caisse : texte exact rendu par le jeu | aucun : rendu procédural conservé |
| `p_doc02` | Photos | document — Attestation d'assurance habitation. | non | **PROCEDURAL** | document (attestation) : texte exact rendu par le jeu | aucun : rendu procédural conservé |
| `p_scr01` | Photos | screenshot — Capture : un mème envoyé par Tom. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone (texte exact) | aucun : rendu procédural conservé |
| `p_scr02` | Photos | screenshot — Capture : itinéraire vers l'agence. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone (texte exact) | aucun : rendu procédural conservé |
| `p_scr03` | Photos | screenshot — Capture : confirmation de commande. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone (texte exact) | aucun : rendu procédural conservé |
| `p_lucas_car` | Photos, Messages › c_lucas | car — La citadine grise de Lucas, sortie du garage. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_petite_voiture_grise_garage_01 (variante 1) |
| `p_vernissage` | Photos, Messages › c_ines | gallery — Vernissage Lumen, vu du fond de la salle. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_vernissage_exposition_photographie_visit_01 (variante 1) |
| `p_invoice` | Photos | document — Photo d'une facture « Studio Nova » n°114. | oui | **PROCEDURAL** | document (facture Studio Nova) : texte exact rendu par le jeu ; preuve portée par ses lignes et ses métadonnées | aucun : rendu procédural conservé |
| `p_bar_selfie` | Photos | bar · nuit — Le Levant : la table du fond, avant le départ de Karim. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case001_src_table_de_bar_verres_chaises_soiree_night_01 (variante 1) |
| `p_emma_couch` | Photos, Messages › c_emma | bed — « Chez moi » : la couette, une tasse fumante, la télé allumée. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case001_src_lit_couette_tasse_fenetre_jour_p_emma_couch_01 (variante 1) |
| `p_parking` | Photos | parking_night · nuit — Le parking du Quai 9, de nuit. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case001_src_parking_de_nuit_voiture_feux_arriere_p_parking_night_01 (variante 1) |
| `p_sarah_jade` | Photos, Messages › c_group | party · nuit — L'anniversaire de Jade : ballons et guirlandes. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case001_src_jardin_guirlandes_lumineuses_ballons_fet_p_sarah_jade_night_01 (variante 1) |
| `p_karim_desk` | Photos, Messages › c_karim | desk_night · nuit — Le comptoir d'accueil de l'hôtel, de nuit. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case001_src_reception_hotel_nuit_comptoir_p_karim_desk_night_01 (variante 1) |

## #002 PREMIER MÉTRO

| ID | Écran | Fonction | Preuve | Décision | Raison | Remplacement |
|---|---|---|---|---|---|---|
| `p_old01` | Photos | concert · nuit — Festival d'été, 2019. La scène au loin. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_festival_lasers_foule_nuit_night_01 (variante 1) |
| `p_old02` | Photos | street_night · nuit — Fête de la musique 2021, rue de la République. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_fete_de_la_musique_lyon_night_01 (variante 1) |
| `p_old03` | Photos | party · nuit — Anniversaire, 25 ans. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_gateau_d_anniversaire_bougies_night_01 (variante 1) |
| `p_old04` | Photos | sunset — Coucher de soleil sur la Saône, juillet 2023. | non | **CUSTOM_REAL** | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. | vraie photo à prendre nous-mêmes ; le rendu procédural reste en attendant |
| `p_old05` | Photos | interior_warm — Réveillon chez Papa. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_table_de_reveillon_bougies_01 (variante 1) |
| `p_old06` | Photos | club · nuit — La cabine du Silo, mai 2025. Première saison avec Yanis. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_dj_booth_turntables_red_light_night_01 (variante 1) |
| `p_synth01` | Photos | desk_night · nuit — Le rack de modules, câbles partout. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_eurorack_modular_synthesizer_night_01 (variante 1) |
| `p_club01` | Photos | club · nuit — Le Silo vide, avant l'ouverture. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_empty_nightclub_disco_ball_01 (variante 1) |
| `p_berges01` | Photos | park — Berges du Rhône, run du dimanche. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_berges_du_rhone_lyon_01 (variante 1) |
| `p_vinyl01` | Photos | books — Trois vinyles achetés chez le disquaire. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_vinyl_records_sleeves_01 (variante 1) |
| `p_loge01` | Photos | mirror — Le miroir de la loge, avant le service. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_backstage_mirror_lights_01 (variante 1) |
| `p_view01` | Photos | view — Lyon depuis le haut de la montée de la Grande-Côte. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_montee_de_la_grande_cote_lyon_vue_01 (variante 1) |
| `p_sunset01` | Photos | sunset — Coucher de soleil depuis la passerelle Saint-Vincent. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_passerelle_saint_vincent_lyon_01 (variante 1) |
| `p_plant01` | Photos | plant — Le monstera de Bastien a une nouvelle feuille. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_monstera_plant_window_01 (variante 1) |
| `p_ceiling01` | Photos | ceiling — Le plafond de la chambre. | non | **PROCEDURAL** | photo prise par erreur (plafond flou) rendue par le téléphone | aucun : rendu procédural conservé |
| `p_quick01` | Photos | street_day — Des affiches collées sur un poteau, pentes de la Croix-Rousse. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_affiches_collees_poteau_lyon_01 (variante 1) |
| `p_rain01` | Photos | rain — Pluie sur la fenêtre du salon. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_raindrops_on_window_street_01 (variante 1) |
| `p_friche01` | Photos | gallery — La grande salle de La Friche Nord, vide. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_usines_fagor_lyon_halle_01 (variante 1) |
| `p_night01` | Photos | street_night · nuit — La montée de la Grande-Côte, de nuit. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_montee_de_la_grande_cote_nuit_night_01 (variante 1) |
| `p_berges02` | Photos | park — Les berges du Rhône après le run avec Lou. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_pont_de_la_guillotiere_rhone_01 (variante 1) |
| `p_market01` | Photos | street_day — Le marché de la Croix-Rousse. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_marche_de_la_croix_rousse_01 (variante 1) |
| `p_metro01` | Photos | metro — Métro presque vide, le matin. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_metro_de_lyon_rame_interieur_01 (variante 1) |
| `p_club02` | Photos | club · nuit — Le Silo avant la soirée Basses Fréquences. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_sound_system_speakers_stage_empty_night_01 (variante 1) |
| `p_console01` | Photos | desk_night · nuit — La console son, prête. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_mixing_console_faders_night_01 (variante 1) |
| `p_selfie01` | Photos | club · nuit — La salle vue depuis la régie, soirée Basses Fréquences. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_nightclub_crowd_blue_light_01 (variante 1) |
| `p_receipt01` | Photos | receipt — Ticket du disquaire. | non | **PROCEDURAL** | ticket de caisse rendu par le téléphone | aucun : rendu procédural conservé |
| `p_invoice01` | Photos | document — Facture du technicien pour la console. | non | **PROCEDURAL** | document (facture) rendu par le téléphone | aucun : rendu procédural conservé |
| `p_run_screen` | Photos, Messages › c_lou | screenshot — Capture : la course de dimanche. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone | aucun : rendu procédural conservé |
| `p_contract` | Photos | document — Contrat de travail — La Friche Nord. | non | **PROCEDURAL** | document (contrat) rendu par le téléphone | aucun : rendu procédural conservé |
| `p_meteo` | Photos | screenshot — Capture : météo de la nuit. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone | aucun : rendu procédural conservé |
| `p_issue_1` | Photos, Messages › c_staff | parking_night · nuit — La cour du Silo, de nuit : des fûts empilés. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_beer_kegs_stacked_courtyard_night_01 (variante 1) |
| `p_issue_2` | Photos, Messages › c_staff | parking_night · nuit — La cour du Silo, encore les fûts. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_beer_kegs_stacked_courtyard_night_01 (variante 2) |
| `p_pistache` | Photos, Messages › c_anais | cat — Pistache, le chat d'Anaïs, couché sur une blouse. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_tabby_cat_sleeping_blue_fabric_01 (variante 1) |
| `p_pistache_synth` | Photos, Messages › c_anais | cat — Pistache couché à côté du rack de modules. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case002_src_cat_synthesizer_01 (variante 1) |
| `p_apero_keys` | Photos, Messages › c_staff | interior_warm — Apéro chez Mathilde : des verres sur la table basse. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case002_src_aperitif_table_basse_verres_de_vin_p_apero_keys_01 (variante 1) |
| `p_booth_0248` | Photos, Messages › c_staff | club · nuit — La cabine DJ, lumières rouges. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case002_src_dj_booth_red_lasers_crowd_p_booth_0248_night_01 (variante 1) |
| `p_door_0304` | Photos, Messages › c_staff | street_night · nuit — La file d'attente devant l'entrée du Silo. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case002_src_file_d_attente_boite_de_nuit_p_door_0304_night_01 (variante 1) |
| `p_pocket_0309` | Photos | pocket — Photo floue, sombre. | oui | **PROCEDURAL** | photo prise par erreur dans le noir (flou de poche) rendue par le téléphone ; l'indice est dans les métadonnées (03:09, quai Arloing) et les détails | aucun : rendu procédural conservé |

## #003 APRÈS LA FÊTE

| ID | Écran | Fonction | Preuve | Décision | Raison | Remplacement |
|---|---|---|---|---|---|---|
| `p_group_2340` | Photos | interior_warm — Le sweat moutarde que j'ai offert à Maxime à Noël. Il l'a enfin sorti 🙄 | oui | **CUSTOM_REAL** | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. | vraie photo à prendre nous-mêmes ; le rendu procédural reste en attendant |
| `p_louise_0206` | Photos, Messages › c_louise | sky · nuit — La Voie lactée au-dessus du toit de la villa, pose longue. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case003_src_maison_nuit_etoiles_pose_longue_p_louise_0206_night_01 (variante 1) |
| `p_louise_0214` | Photos, Messages › c_louise | garden_stairs · nuit — Le bas du jardin et l'escalier de la plage, pose longue : le lampadaire s'est allumé. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case003_src_escalier_jardin_lampadaire_nuit_p_louise_0214_night_01 (variante 1) |
| `p_louise_0227` | Photos, Messages › c_louise | terrace · nuit — Le toit de la villa sous les étoiles, même cadrage qu'à 02:06. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case003_src_maison_nuit_etoiles_pose_longue_p_louise_0206_night_01 (variante 2) |
| `p_diane_biarritz` | Photos, Messages › c_family | terrace — « Week-end entre filles » : un café en terrasse face à l'océan. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case003_src_cote_des_basques_biarritz_cafe_p_diane_biarritz_01 (variante 1) |
| `p_max_sunglasses` | Photos | terrace — Maxime a encore oublié ses lunettes sur la table du balcon. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_cote_des_basques_biarritz_cafe_p_diane_biarritz_01 (variante 2) |
| `p_paul_surf` | Photos, Messages › c_family | beach — Moi debout sur une planche (presque), vue de très loin. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_lacanau_plage_surf_01 (variante 1) |
| `p_old_2003` | Photos, Messages › c_maman | beach — La dune du Pilat, été 2003 : le seau rouge de Paul. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_dune_du_pilat_01 (variante 1) |
| `p_old_2005` | Photos, Messages › c_maman | interior_warm — Noël 2005 chez Mamie, à Arcachon. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_buche_de_noel_table_01 (variante 1) |
| `p_porto` | Photos, Messages › c_papa | street_day — Une rue de Porto, des nappes brodées en vitrine. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_porto_azulejos_rue_01 (variante 1) |
| `p_zellige` | Photos, Messages › c_chloe | interior_warm — Deux échantillons de zellige, blanc et vert sauge. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_zellige_carreaux_vert_01 (variante 1) |
| `p_old_2022` | Photos | interior_warm — Emménagement aux Chartrons, juin 2022. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_cartons_demenagement_appartement_01 (variante 1) |
| `p_old_2019` | Photos | sunset — Coucher de soleil au Pyla, 2019. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_dune_du_pilat_coucher_de_soleil_01 (variante 1) |
| `p_resa` | Photos | screenshot — Capture : réservation de la villa. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone | aucun : rendu procédural conservé |
| `p_selfie_mirror` | Photos | office — L'agence, 8h10 : premier café. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_bureau_tasse_cafe_echantillons_01 (variante 1) |
| `p_sky_july` | Photos | sky — Ciel rose au-dessus des toits des Chartrons. | non | **CUSTOM_REAL** | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. | vraie photo à prendre nous-mêmes ; le rendu procédural reste en attendant |
| `p_cat` | Photos | cat — Le chat du voisin sur notre balcon. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_tabby_cat_balcony_01 (variante 1) |
| `p_rain` | Photos | rain — Orage sur les quais. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_bordeaux_tram_pluie_01 (variante 1) |
| `p_night_chartrons` | Photos | street_night · nuit — La rue Notre-Dame, la nuit. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_rue_notre_dame_bordeaux_night_01 (variante 1) |
| `p_laptop` | Photos | laptop — Plans 3D de la salle de bain Laborde. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_laptop_bathroom_design_01 (variante 1) |
| `p_ceiling` | Photos | ceiling — Le plafond de la chambre. | non | **PROCEDURAL** | photo prise par erreur (plafond flou) | aucun : rendu procédural conservé |
| `p_plant` | Photos | plant — Le monstera a fait une nouvelle feuille !! | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_monstera_new_leaf_01 (variante 1) |
| `p_chantier` | Photos | interior_warm — La salle de bain Laborde, terminée. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_salle_de_bain_zellige_vert_01 (variante 1) |
| `p_meteo` | Photos | screenshot — Capture : météo marine du week-end. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone | aucun : rendu procédural conservé |
| `p_quick_car` | Photos | car — Bouchons à la sortie de Bordeaux. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_rocade_de_bordeaux_bouchons_01 (variante 1) |
| `p_marees` | Photos | screenshot — Capture : horaires des marées. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone | aucun : rendu procédural conservé |
| `p_sunset_bassin` | Photos | sunset — Premier coucher de soleil sur le bassin. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_bassin_d_arcachon_coucher_de_soleil_01 (variante 1) |
| `p_ticket` | Photos | receipt — Ticket de la supérette. | non | **PROCEDURAL** | ticket de caisse rendu par le téléphone | aucun : rendu procédural conservé |
| `p_phare` | Photos | view — Le phare du Cap Ferret, vu d'en bas. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_phare_du_cap_ferret_01 (variante 1) |
| `p_huitres` | Photos | terrace — Pause huîtres au port. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_huitres_cap_ferret_port_01 (variante 1) |
| `p_stairs_day` | Photos | garden_stairs — L'escalier de pierre qui descend du jardin à la plage. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_escalier_pierre_jardin_plage_01 (variante 1) |
| `p_dune` | Photos | beach — La dune du Pilat, en face, de l'autre côté du bassin. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_dune_du_pilat_depuis_cap_ferret_01 (variante 1) |
| `p_selfie_louise` | Photos | terrace — L'apéro sur la terrasse : des paillettes partout. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_coupes_champagne_terrasse_01 (variante 1) |
| `p_pocket` | Photos | pocket — Photo prise dans une poche. | non | **PROCEDURAL** | photo prise dans une poche (noir, lueur) | aucun : rendu procédural conservé |
| `p_cake` | Photos, Messages › c_party | party · nuit — Le gâteau et ses deux bougies « 3 » et « 0 ». | non | **CUSTOM_REAL** | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. | vraie photo à prendre nous-mêmes ; le rendu procédural reste en attendant |
| `p_gift` | Photos | gallery — Le cadeau de Louise : un tirage encadré. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_photo_encadree_cadre_bois_01 (variante 1) |
| `p_blur_party` | Photos | party · nuit — Tout le monde danse dans le salon. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_blurry_party_dancing_lights_night_01 (variante 1) |
| `p_night_garden` | Photos | garden_stairs · nuit — Le jardin la nuit, depuis la terrasse. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case003_src_jardin_nuit_terrasse_lampadaire_night_01 (variante 1) |

## #004 90 SECONDES

| ID | Écran | Fonction | Preuve | Décision | Raison | Remplacement |
|---|---|---|---|---|---|---|
| `p_old01` | Photos | gallery — Accrochage « Verre & lumière », Lyon, 2019. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_glass_vases_exhibition_plinths_01 (variante 1) |
| `p_old02` | Photos | party · nuit — Vernissage à Nantes, juin 2021. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_guirlandes_cour_pavee_soiree_night_01 (variante 1) |
| `p_old03` | Photos | beach — Le château de sable de Jules, été 2023. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_chateau_de_sable_plage_seau_01 (variante 1) |
| `p_old04` | Photos | snow — Neige au chalet, décembre 2024. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_chalet_neige_luge_01 (variante 1) |
| `p_old05` | Photos | interior_warm · nuit — Mes 35 ans. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_birthday_candles_table_glasses_night_01 (variante 1) |
| `p_b01` | Photos | gallery — Salle 2 du Pavillon, encore vide. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_empty_exhibition_room_parquet_01 (variante 1) |
| `p_b02` | Photos | laptop — Le plan v1 à l'écran, en réunion. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_laptop_floor_plan_meeting_table_01 (variante 1) |
| `p_b03` | Photos | cat — Pistache sur la pile de catalogues. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_tabby_cat_sleeping_on_papers_01 (variante 1) |
| `p_b04` | Photos | document — Convention de prêt — page 1. | non | **PROCEDURAL** | document rendu par le téléphone (convention de prêt, texte lisible) | aucun : rendu procédural conservé |
| `p_b05` | Photos | office — L'atelier de PY à Bagnolet. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_scale_model_workshop_cardboard_01 (variante 1) |
| `p_b06` | Photos | street_night · nuit — Belleville, la nuit, en rentrant. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_belleville_paris_rue_nuit_night_01 (variante 1) |
| `p_b07` | Photos | terrace — Café au Jourdain, un dimanche. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_cafe_terrasse_paris_croissant_01 (variante 1) |
| `p_b08` | Photos | vitrine — Livraison des vitrines. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_museum_display_cases_wrapped_delivery_01 (variante 1) |
| `p_b09` | Photos | screenshot — Capture : plan de salle v3. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone (plan de salle v3) | aucun : rendu procédural conservé |
| `p_b10` | Photos | park — Footing aux Buttes-Chaumont. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_temple_de_la_sibylle_buttes_chaumont_aut_01 (variante 1) |
| `p_b11` | Photos | receipt — Reçu de taxi. | non | **PROCEDURAL** | reçu de taxi rendu par le téléphone (texte lisible) | aucun : rendu procédural conservé |
| `p_b12` | Photos | document — Épreuve du cartel de la vitrine 4. | non | **PROCEDURAL** | épreuve de cartel rendue par le téléphone (texte lisible) | aucun : rendu procédural conservé |
| `p_b13` | Photos | books — Épreuves du catalogue. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_page_proofs_sticky_notes_desk_01 (variante 1) |
| `p_b14` | Photos | rain — Pluie sur la fenêtre du salon. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_rain_window_paris_rooftops_01 (variante 1) |
| `p_b15` | Photos | gallery · nuit — Essais lumière en salle 2. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_empty_museum_display_case_spotlight_p_vitrine_2216_night_01 (variante 2) |
| `p_b16` | Photos | station — Gare de Lyon, en attendant Camille. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_gare_de_lyon_hall_paris_01 (variante 1) |
| `p_b17` | Photos | interior_warm · nuit — Dîner avec Camille, à la maison. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_dinner_table_candle_wine_glasses_night_01 (variante 1) |
| `p_b18` | Photos | gallery — Montage du 11 novembre. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_exhibition_installation_ladders_display__01 (variante 1) |
| `p_b19` | Photos | view — Le matin, depuis le perron du Pavillon. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_tour_eiffel_brume_seine_01 (variante 1) |
| `p_b20` | Photos | vitrine — Pose de l'Aurore dans la vitrine 4. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_pearl_necklace_display_case_velvet_p_vitrine_1752_01 (variante 2) |
| `p_b21` | Photos | gala · nuit — La salle prête, avant l'ouverture. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_gala_hall_tables_black_tablecloths_night_01 (variante 1) |
| `p_b22` | Photos | mirror — La loge, juste avant l'ouverture. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_dressing_room_mirror_lights_01 (variante 1) |
| `p_b23` | Photos | gala — Les premiers invités. | non | **CUSTOM_REAL** | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. | vraie photo à prendre nous-mêmes ; le rendu procédural reste en attendant |
| `p_b24` | Photos | gala · nuit — Discours d'Hélène, pris de loin. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_lectern_spotlight_stage_night_01 (variante 1) |
| `p_blur01` | Photos | ceiling — Le plafond de la chambre. | non | **PROCEDURAL** | photo accidentelle floue (plafond), rendue par le téléphone | aucun : rendu procédural conservé |
| `p_blur02` | Photos | pocket — Photo déclenchée par erreur dans le noir. | non | **PROCEDURAL** | photo accidentelle dans le noir (poche), rendue par le téléphone | aucun : rendu procédural conservé |
| `p_scr01` | Photos | screenshot — Capture : météo de jeudi. | non | **PROCEDURAL** | capture d'écran météo rendue par le téléphone | aucun : rendu procédural conservé |
| `p_scr02` | Photos | screenshot — Capture : liste des badges. | non | **PROCEDURAL** | capture d'écran de la liste des badges rendue par le téléphone | aucun : rendu procédural conservé |
| `p_vitrine_1752` | Photos | vitrine — La vitrine 4 sous les projecteurs, pour les réseaux (juste après le « nettoyage »). | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case004_src_pearl_necklace_display_case_velvet_p_vitrine_1752_01 (variante 1) |
| `p_vitrine_2216` | Photos | vitrine_empty · nuit — La vitrine 4, vide, sous la poursuite. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case004_src_empty_museum_display_case_spotlight_p_vitrine_2216_night_01 (variante 1) |
| `p_room_2213` | Photos, Messages › c_noemie | gala · nuit — La salle 2 pendant la présentation d'Iris. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case004_src_gala_evening_hall_stage_crowd_p_room_2213_night_01 (variante 1) |
| `p_stage_2214` | Photos, Messages › c_samir | gala · nuit — La scène au moment où tout s'éteint. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case004_src_microphone_stand_spotlight_dark_stage_p_stage_2214_night_01 (variante 1) |
| `p_regie_2215` | Photos, Messages › c_team | desk_night · nuit — La console de la régie, dans le noir. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case004_src_lighting_console_dark_p_regie_2215_night_01 (variante 1) |
| `p_iris_look` | Photos, Messages › c_iris | mirror — La robe noire à sequins pour jeudi. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_sequin_dress_hanger_01 (variante 1) |
| `p_jules` | Photos, Messages › c_camille | interior_warm — La première dent de Jules. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case004_src_milk_tooth_01 (variante 1) |

## #005 ROUTE DE NUIT

| ID | Écran | Fonction | Preuve | Décision | Raison | Remplacement |
|---|---|---|---|---|---|---|
| `p_old01` | Photos | snow — Villard sous la neige, février 2019. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_villard_de_lans_neige_01 (variante 1) |
| `p_old02` | Photos | garden_stairs — L'escalier du jardin, le jour où Léo l'a monté tout seul. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_garden_stone_steps_01 (variante 1) |
| `p_old03` | Photos | party · nuit — Le gâteau de mes 30 ans — 14 mars 2022. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_birthday_cake_candles_30_night_01 (variante 1) |
| `p_old04` | Photos | park — Le parc Paul-Mistral, le jour des premiers pas de Nina. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_parc_paul_mistral_grenoble_01 (variante 1) |
| `p_old05` | Photos | interior_warm — Réveillon chez Maman. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_christmas_dinner_table_tree_01 (variante 1) |
| `p_old06` | Photos | office — Pot de départ de l'ancien secrétaire de rédaction. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_office_party_table_drinks_01 (variante 1) |
| `p_n01` | Photos | mountain — Le Moucherotte dans les nuages. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_moucherotte_vercors_01 (variante 1) |
| `p_n02` | Photos | forest — Balade en forêt avec les enfants. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_vercors_foret_automne_01 (variante 1) |
| `p_n03` | Photos | office — La salle du conseil municipal de Vallières, avant l'ouverture. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_salle_du_conseil_municipal_01 (variante 1) |
| `p_n04` | Photos | mountain — La carrière vue depuis la route. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_carriere_calcaire_isere_01 (variante 1) |
| `p_n05` | Photos | party · nuit — Halloween : la citrouille devant la porte des voisins. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_jack_o_lantern_doorstep_night_01 (variante 1) |
| `p_n06` | Photos | screenshot — Capture : météo de la semaine. | non | **PROCEDURAL** | capture d'écran météo rendue par le téléphone | aucun : rendu procédural conservé |
| `p_n07` | Photos | office — Conférence de rédaction. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_newsroom_whiteboard_meeting_01 (variante 1) |
| `p_n08` | Photos | interior_warm — Les dessins de Nina sur le frigo. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_children_drawings_fridge_magnets_01 (variante 1) |
| `p_n09` | Photos | receipt — Facture du garage — pneus neige. | non | **PROCEDURAL** | facture (papier) rendue par le téléphone | aucun : rendu procédural conservé |
| `p_n10` | Photos | snow — Premiers flocons sur le balcon. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_snow_balcony_railing_01 (variante 1) |
| `p_n11` | Photos | party · nuit — Le gâteau d'anniversaire de Lina, en salle de conf. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_birthday_cake_office_party_night_01 (variante 1) |
| `p_n12` | Photos | pocket — Photo prise dans une poche. | non | **PROCEDURAL** | photo accidentelle prise dans une poche | aucun : rendu procédural conservé |
| `p_n13` | Photos | document — Planning de garde de décembre, griffonné. | non | **PROCEDURAL** | document manuscrit rendu par le téléphone (texte à lire) | aucun : rendu procédural conservé |
| `p_n14` | Photos | screenshot — Capture : mon article de ce matin. | non | **PROCEDURAL** | capture d'écran d'article rendue par le téléphone | aucun : rendu procédural conservé |
| `p_n15` | Photos | ceiling — Le plafond de la chambre. | non | **PROCEDURAL** | photo accidentelle du plafond | aucun : rendu procédural conservé |
| `p_n16` | Photos | snow — Autrans, première neige qui tient. | non | **CUSTOM_REAL** | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. | vraie photo à prendre nous-mêmes ; le rendu procédural reste en attendant |
| `p_n17` | Photos | mountain — La carrière depuis le chemin forestier. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_quarry_excavator_rock_face_01 (variante 1) |
| `p_n18` | Photos | street_night · nuit — Villard, la grande rue sous la pluie. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_villard_de_lans_rue_nuit_night_01 (variante 1) |
| `p_n19` | Photos | snow — Bois Barbu : première sortie en skating. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_bois_barbu_villard_de_lans_01 (variante 1) |
| `p_n20` | Photos | screenshot — Capture : état des routes du Vercors. | non | **PROCEDURAL** | capture d'écran Inforoute rendue par le téléphone | aucun : rendu procédural conservé |
| `p_n21` | Photos | office — La rédaction, avant la conf. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_newsroom_desk_newspapers_coffee_01 (variante 1) |
| `p_n22` | Photos | rain · nuit — La cour sous la pluie. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_courtyard_rain_night_lamp_01 (variante 1) |
| `p_n23` | Photos | car · nuit — Le siège passager avant de partir. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_car_dashboard_night_01 (variante 1) |
| `p_n24` | Photos | road_night · nuit — Le parking du col : rien que du brouillard. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_col_de_la_croix_perrin_night_01 (variante 1) |
| `p_mairie_4x4` | Photos | parking_night · nuit — La cour de la mairie de Vallières, avant le conseil. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case005_src_dark_grey_suv_parked_night_p_mairie_4x4_01 (variante 1) |
| `p_doc_virements` | Photos, Messages › c_julien | document — Photo d'un relevé bancaire de Brassac Granulats. | oui | **PROCEDURAL** | relevé bancaire (document) : les lignes du 12/09 doivent se lire, rendu par le téléphone | aucun : rendu procédural conservé |
| `p_platre` | Photos, Messages › c_julien | bed — Le couloir des urgences, vu depuis un brancard. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case005_src_hopital_couloir_urgences_p_platre_01 (variante 1) |
| `p_kids_2305` | Photos, Messages › c_romain | bed · nuit — La chambre des enfants, veilleuse allumée. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case005_src_bunk_beds_night_light_p_kids_2305_01 (variante 1) |
| `p_bat_2301` | Photos, Messages › c_agathe | document — Le BAT de la une de samedi. | oui | **PROCEDURAL** | BAT de la une (épreuve imprimée à lire) rendu par le téléphone | aucun : rendu procédural conservé |
| `p_col_2314` | Photos | road_night · nuit — Un 4×4 se gare sur le parking du col. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case005_src_dark_grey_suv_parked_night_p_mairie_4x4_01 (variante 2) |
| `p_r_chat` | Photos, Messages › c_maman | cat — Le chat de Maman dans le panier à linge. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case005_src_cat_laundry_basket_01 (variante 1) |
| `p_r_dent` | Photos, Messages › c_romain | interior_warm — La dent de Léo dans une boîte d'allumettes. | non | **CUSTOM_REAL** | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. | vraie photo à prendre nous-mêmes ; le rendu procédural reste en attendant |

## ALIBI #001 LE DÎNER

| ID | Écran | Fonction | Preuve | Décision | Raison | Remplacement |
|---|---|---|---|---|---|---|
| `p_elephant` | Photos | street_day — Le Grand Éléphant qui sort de sa galerie. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case101_src_grand_elephant_machines_de_l_ile_01 (variante 1) |
| `p_loire` | Photos | sunset — La Loire au coucher du soleil. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case101_src_loire_nantes_coucher_de_soleil_01 (variante 1) |
| `p_velo` | Photos | street_day — Un vélo attaché à un arceau, pneu arrière à plat. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case101_src_bicycle_flat_tyre_01 (variante 1) |
| `p_marche` | Photos | street_day — Les halles du marché de Talensac, un samedi matin. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case101_src_marche_de_talensac_nantes_01 (variante 1) |
| `p_chat` | Photos | cat — Pixel, le chat, roulé en boule sur le canapé. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case101_src_cat_sleeping_sofa_01 (variante 1) |
| `p_tram` | Photos | screenshot — Capture : info trafic du tram. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone | aucun : rendu procédural conservé |
| `p_affiche` | Photos | office — Des épreuves d'affiches étalées sur une grande table du studio. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case101_src_poster_print_proofs_table_01 (variante 1) |
| `p_table` | Photos | interior_warm — La table du dîner chez Coline et Arthur : bougies, verres, bouteilles. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case101_src_dinner_table_candles_p_table_01 (variante 1) |
| `p_gateau` | Photos, Messages › c_coline | interior_warm — Une part de gâteau au chocolat, seule sur une assiette. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case101_src_chocolate_cake_slice_01 (variante 1) |
| `p_grue` | Photos | street_night · nuit — La grue jaune éclairée, de nuit, au bord de la Loire. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case101_src_grue_titan_jaune_nantes_p_grue_night_01 (variante 1) |

## ALIBI #002 LE DERNIER MÉTRO

| ID | Écran | Fonction | Preuve | Décision | Raison | Remplacement |
|---|---|---|---|---|---|---|
| `p2_citadelle` | Photos | park — Une allée du parc de la Citadelle couverte de feuilles mortes. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case102_src_citadelle_de_lille_parc_automne_01 (variante 1) |
| `p2_grandplace` | Photos | street_day — La Vieille Bourse et la Grand-Place, un après-midi gris. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case102_src_vieille_bourse_lille_grand_place_01 (variante 1) |
| `p2_velo` | Photos | interior_warm — Un vélo appuyé contre le mur d'une entrée d'appartement. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case102_src_bicycle_hallway_apartment_01 (variante 1) |
| `p2_code` | Photos | laptop — Un écran d'ordinateur couvert de code, une tasse à côté. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case102_src_computer_screen_source_code_01 (variante 1) |
| `p2_virement` | Photos | screenshot — Capture : un virement de 200 €. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone | aucun : rendu procédural conservé |
| `p2_pintes` | Photos | bar · nuit — Deux pintes posées sur un comptoir en bois. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case102_src_two_pints_beer_bar_counter_night_01 (variante 1) |
| `p2_rame` | Photos | metro · nuit — L'intérieur d'une rame de métro presque vide. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case102_src_metro_de_lille_val_interieur_p2_rame_night_01 (variante 1) |
| `p2_rue` | Photos, Messages › c2_massena | street_night · nuit — La rue Masséna de nuit, un attroupement devant un bar, des gyrophares au loin. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case102_src_rue_massena_lille_nuit_p2_rue_night_01 (variante 1) |
| `p2_ciel` | Photos | sky — Un ciel bas et gris au-dessus des immeubles. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case102_src_villeneuve_d_ascq_immeubles_ciel_gris_01 (variante 1) |

## ALIBI #003 LE RENDEZ-VOUS

| ID | Écran | Fonction | Preuve | Décision | Raison | Remplacement |
|---|---|---|---|---|---|---|
| `p3_petitefrance` | Photos | street_day — Les maisons à colombages de la Petite France, au bord de l'Ill. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case103_src_petite_france_strasbourg_colombages_01 (variante 1) |
| `p3_meinau` | Photos | view · nuit — Les tribunes éclairées du stade, vues d'en haut. | non | **CUSTOM_REAL** | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. | vraie photo à prendre nous-mêmes ; le rendu procédural reste en attendant |
| `p3_tram` | Photos | street_day — Un tram arrêté à la station Homme de Fer. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case103_src_tram_strasbourg_homme_de_fer_01 (variante 1) |
| `p3_cathedrale` | Photos | sunset — La cathédrale au crépuscule, la flèche dans un ciel rose. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case103_src_cathedrale_de_strasbourg_crepuscule_01 (variante 1) |
| `p3_simulation` | Photos | screenshot — Capture : une simulation de prêt. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone | aucun : rendu procédural conservé |
| `p3_echantillons` | Photos | office — Des échantillons de carrelage alignés sur une table. | non | **CUSTOM_REAL** | Aucune photo libre fidèle à la légende après trois relectures (sujet, saison, heure ou lieu faux) : vraie photo à prendre par le studio ; rendu dessiné du jeu en attendant. | vraie photo à prendre nous-mêmes ; le rendu procédural reste en attendant |
| `p3_chantier` | Photos | interior_warm — Une salle de bains en chantier, carrelage à moitié posé. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case103_src_bathroom_renovation_tiling_01 (variante 1) |
| `p3_pluie` | Photos, Messages › c3_jonas | rain — La pluie sur un pare-brise, des voitures garées floues derrière. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case103_src_rain_on_windshield_p3_pluie_01 (variante 1) |
| `p3_kleber` | Photos | street_day — La place Kléber sous la pluie, pavés luisants. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case103_src_place_kleber_strasbourg_pluie_p3_kleber_01 (variante 1) |

## ALIBI #101 LE DOSSIER VARIN

| ID | Écran | Fonction | Preuve | Décision | Raison | Remplacement |
|---|---|---|---|---|---|---|
| `p_old_etretat` | Photos | beach — Les falaises d'Étretat, août 2024. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_falaises_d_etretat_porte_d_aval_01 (variante 1) |
| `p_old_fete` | Photos | street_night · nuit — Fête de la musique, rue Oberkampf. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_fete_de_la_musique_paris_rue_night_01 (variante 1) |
| `p_old_sapin` | Photos | interior_warm — Le sapin chez les parents, Orléans. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_christmas_tree_living_room_01 (variante 1) |
| `p_canal` | Photos | street_day — Canal Saint-Martin, dimanche matin. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_canal_saint_martin_passerelle_01 (variante 1) |
| `p_maquette` | Photos | office — La maquette de la médiathèque, avant la mise en couleur. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_architectural_model_cardboard_01 (variante 1) |
| `p_coulee` | Photos | park — La Coulée verte, pause de midi. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_promenade_plantee_paris_01 (variante 1) |
| `p_aligre` | Photos | street_day — Marché d'Aligre, samedi. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_marche_d_aligre_paris_01 (variante 1) |
| `p_dahlias` | Photos, Messages › c_famille | plant — Les dahlias du jardin de maman. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_dahlias_garden_01 (variante 1) |
| `p_planning` | Photos | screenshot — Capture : le planning du rendu Montreuil. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone | aucun : rendu procédural conservé |
| `p_lea_chat` | Photos, Messages › c_lea | cat — Pistou, le chat de Léa, sur le canapé. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_tabby_cat_sleeping_sofa_01 (variante 1) |
| `p_buttes` | Photos | park — Parc des Buttes-Chaumont, le temple de la Sibylle. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_temple_de_la_sibylle_buttes_chaumont_01 (variante 1) |
| `p_tirages` | Photos | office — Les tirages A0 étalés sur la grande table. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_architectural_drawings_on_table_01 (variante 1) |
| `p_verriere` | Photos | rain — Pluie sur la verrière de l'atelier. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_rain_drops_glass_roof_01 (variante 1) |
| `p_ticket` | Photos | receipt — Ticket de Voltaire Repro. | non | **PROCEDURAL** | ticket (document) rendu par le téléphone | aucun : rendu procédural conservé |
| `p_daumesnil` | Photos | park — Le lac Daumesnil, samedi matin. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_lac_daumesnil_bois_de_vincennes_01 (variante 1) |
| `p_cirque` | Photos | street_day — Le Cirque d'Hiver, en rentrant. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_cirque_d_hiver_paris_01 (variante 1) |
| `p_nas_orange` | Photos, Messages › c_thomas | office — Le serveur du local technique, voyant orange. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_server_rack_small_office_01 (variante 1) |
| `p_plante` | Photos | plant — Le pothos du bureau reprend. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_pothos_plant_shelf_01 (variante 1) |
| `p_belleville` | Photos | sunset — Coucher de soleil depuis le parc de Belleville. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_parc_de_belleville_vue_paris_01 (variante 1) |
| `p_republique` | Photos | street_day — Place de la République, pause de midi. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_place_de_la_republique_paris_01 (variante 1) |
| `p_vincennes_2230` | Photos, Messages › c_famille | party · nuit — Le gâteau de Juliette, 36 bougies. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case201_src_birthday_cake_candles_table_p_vincennes_2230_night_01 (variante 1) |
| `p_adrien_cigale` | Photos, Messages › c_atelier | concert · nuit — La scène de La Cigale, vue du balcon. | oui | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet). | case201_src_la_cigale_paris_salle_concert_p_adrien_cigale_night_01 (variante 1) |
| `p_chateau` | Photos | street_night · nuit — Le donjon du château de Vincennes, en allant au RER. | non | **REPLACE_REAL** | Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire. | case201_src_chateau_de_vincennes_donjon_nuit_night_01 (variante 1) |
| `p_poche` | Photos | pocket — Photo prise par erreur. | non | **PROCEDURAL** | photo ratée prise dans une poche | aucun : rendu procédural conservé |
| `p_depot_capture` | Photos, Messages › c_atelier | screenshot — Capture envoyée par Sonia : l'avis de dépôt. | non | **PROCEDURAL** | capture d'écran rendue par le téléphone | aucun : rendu procédural conservé |

