# Mode HISTOIRE — prompts des cinématiques (scènes des chapitres)

> Généré par `scripts/story/export_cinematic_prompts.py` à partir des données du jeu (`ScreenshotKit/Sources/StoryLibrary/Resources/Story`) : chaque scène, chaque plan, chaque réplique, chaque réponse. Relancer le script après toute modification d'une scène.

Chaque scène est jouée en 3D temps réel par le jeu (SceneKit). Pour la refaire en vidéo : un prompt par **plan** (une coupe caméra = un plan), à monter ensuite dans l'ordre. Les répliques du joueur n'ont pas de voix (sous-titres seulement). Les répliques des PNJ peuvent être dites dans la vidéo ou doublées (ElevenLabs, fiches voix ci-dessous) ; les sous-titres sont toujours affichés par le jeu. Les choix du joueur créent des **branches** : il faut une vidéo par branche pour les plans concernés (repérés « Réponse A / B / — »).

Intégration : chaque scène a un champ `video` prévu dans les données (non lu par le jeu pour l'instant). Livrer les vidéos par plan et par branche, nommées `<scène>_plan<N>[_<réponse>].mp4` (ex. `S01-01B_plan7_c01_defiant.mp4`).

**Le nom du joueur** : certaines répliques le disent (« {player.lastName}. Fermez la porte. »). Les prompts l'écrivent avec le modèle Vincent Delmas ; pour un doublage, enregistrer une version par nom ou couper le nom au montage (le jeu affiche toujours la réplique exacte en sous-titre).

## Style commun (déjà inclus dans chaque prompt)

```
Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

Règles du handoff (STORY_SCENES, STORY_ART_DIRECTION) : une scène = un lieu, 3 personnes au plus à l'écran, toujours un plan large en ouverture, jamais plus de 2 plans serrés d'affilée, au moins un plan muet de 2 à 4 s, un plan sur objet avant chaque passage au téléphone, transitions coupe / fondu enchaîné / fondu au noir uniquement. Focales : 28 · 35 · 50 · 85 · 100 mm. Hauteur de caméra par défaut 1,45 m.

## Personnages

### Le joueur (personnalisé)

Le joueur crée son enquêteur (2 bases, teint, visage, cheveux, yeux, 4 tenues × 2 couleurs). Pour qu'une seule vidéo serve à tous : **le filmer de dos, par-dessus l'épaule, ou visage hors de mise au point**. Modèles de départ :

- Élise Morel: woman, 1.68 m, light skin, oval face, brown hair in a low ponytail, grey-green eyes, charcoal wool coat over a roll-neck
- Vincent Delmas: man, 1.80 m, medium skin, square face, short black faded hair, stubble, brown eyes, navy parka over an écru shirt

### Cdt. Bernard Lacaze
- 58 ans. Commande le BEN. Trente ans de police judiciaire ; parle peu, sans élever la voix.
- Voix : masculine, 55–60 ans, grave, légèrement éraillée ; lent, phrases courtes.
```
Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice. Realistic proportions, matte skin, no heroic pose.
```

### Analyste Inès Carvalho
- 31 ans. Analyste du laboratoire d'extraction : personne ne touche un téléphone saisi avant elle.
- Voix : féminine, 30 ans, claire ; rapide, vocabulaire technique simple.
```
Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic. Realistic proportions, matte skin, no heroic pose.
```

### Insp. senior Marc Aubrac
- 49 ans. Inspecteur senior, sceptique par principe. Rival bienveillant.
- Voix : masculine, 50 ans, ronde ; posé.
```
Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival. Realistic proportions, matte skin, no heroic pose.
```

### Archiviste Colette Vidal
- 63 ans. Archiviste du BEN depuis sa création. Se souvient de chaque carton.
- Voix : féminine, 60+ ans, douce ; lente.
```
Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow. Realistic proportions, matte skin, no heroic pose.
```

### Agent Julien Roche
- Un agent de l'open space.
- Figurant, pas de réplique.
```
Julien Roche, a BEN officer in the background: 30s, navy polo shirt, busy, out of focus. Realistic proportions, matte skin, no heroic pose.
```

## Décors

### Couloir, 3ᵉ étage (`ENV_BEN_CORRIDOR`)

The BEN's 3rd-floor corridor: 24 m long, 2.2 m wide, glass partitions on the left, numbered doors 301 to 318 on the right, 60 × 60 cm suspended ceiling tiles with fluorescent panels (one flickers), dark grey linoleum, administrative grey walls, a water fountain, a trolley of cardboard files, a safety poster, night windows and a BEN sign at the far end.

Caméras : `cam_corr_wide` (28 mm), `cam_corr_follow` (50 mm), `cam_corr_door312` (35 mm), `cam_corr_hero` (50 mm), `cam_corr_cu` (85 mm).

### Bureau 312 (`ENV_BEN_OFFICE_LACAZE`)

Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off.

Caméras : `cam_lac_wide` (28 mm), `cam_lac_door` (35 mm), `cam_lac_ms` (50 mm), `cam_lac_cu` (85 mm), `cam_lac_os` (50 mm), `cam_lac_rev` (50 mm), `cam_lac_player_cu` (85 mm), `cam_lac_desk_top` (100 mm).

### Mon bureau (`ENV_BEN_OFFICE_PLAYER`)

The player's own office at the BEN: a 3.5 × 4 m box, grey metal desk, articulated lamp, a computer screen, a desk phone, two files, a window on the courtyard, a ceiling neon (from level 2: an archive cabinet, a framed picture, a mug, a plant, a shelf for rewards).

Caméras : `cam_po_wide` (28 mm), `cam_po_ms` (50 mm), `cam_po_obj_phone` (100 mm), `cam_po_obj_computer` (85 mm), `cam_po_obj_files` (100 mm), `cam_po_obj_card` (100 mm), `cam_po_obj_archives` (50 mm), `cam_po_obj_rewards` (50 mm), `cam_po_obj_board` (50 mm), `cam_po_obj_safe` (50 mm).

### Open space (`ENV_BEN_OPENSPACE`)

The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning.

Caméras : `cam_os_wide` (28 mm), `cam_os_ines` (50 mm), `cam_os_ines_cu` (85 mm), `cam_os_player` (50 mm), `cam_os_aubrac` (50 mm), `cam_os_desk_top` (100 mm), `cam_os_aubrac_desk` (50 mm), `cam_os_aubrac_turn` (50 mm), `cam_os_aubrac_cu` (85 mm), `cam_os_ots_aubrac` (50 mm), `cam_os_log` (100 mm).

### Archives, sous-sol (`ENV_BEN_ARCHIVES`)

The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk.

Caméras : `cam_arc_aisle` (28 mm), `cam_arc_table` (35 mm), `cam_arc_ms` (50 mm), `cam_arc_cu` (85 mm), `cam_arc_colette` (50 mm), `cam_arc_box` (100 mm), `cam_arc_os_desk` (50 mm), `cam_arc_desk_top` (100 mm), `cam_arc_os_table` (50 mm), `cam_arc_colette_cu` (85 mm), `cam_arc_player` (50 mm).

### Salle d'audition (`ENV_BEN_INTERROGATION`)

The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup.

Caméras : `cam_int_wide` (28 mm), `cam_int_os_suspect` (50 mm), `cam_int_cu` (85 mm), `cam_int_mirror` (35 mm), `cam_int_table` (100 mm), `cam_int_ms` (50 mm), `cam_int_ines` (50 mm), `cam_int_ines_cu` (85 mm).

### Salle de réunion (`ENV_BEN_BRIEFING`)

The BEN's meeting room: 6 × 8 m, a long table, ten chairs, a wall screen, a whiteboard, dimmed neons.

Caméras : `cam_brf_wide` (28 mm), `cam_brf_screen` (35 mm), `cam_brf_ms` (50 mm).


---

## Chapitre 01 — PREMIÈRE AFFECTATION

*Premier soir au Bureau des Enquêtes Numériques. Le commandant Lacaze vous remet un téléphone sous scellé : Alex Moreau, vingt-six ans, a disparu à Marseille.*

Déroulé : scène S01-01 « Arrivée au BEN » → scène S01-01B « Bureau 312 » → **téléphone** : affaire `case_001` « Le dernier message » → scène S01-02 « Retour » → fin de chapitre (écrans papier) → scène S01-03 « Mon bureau » → mon bureau (écran 3D interactif).

### S01-01 — Arrivée au BEN

**Lieu** : Couloir, 3ᵉ étage (`ENV_BEN_CORRIDOR`) · **Carton** : « BEN · 3ᵉ ÉTAGE · 21:04 » · **Personnages** : le joueur

**Décor** : The BEN's 3rd-floor corridor: 24 m long, 2.2 m wide, glass partitions on the left, numbered doors 301 to 318 on the right, 60 × 60 cm suspended ceiling tiles with fluorescent panels (one flickers), dark grey linoleum, administrative grey walls, a water fountain, a trolley of cardboard files, a safety poster, night windows and a BEN sign at the far end.


#### Plan 1 — WIDE sur le joueur (≈ 6 s)

- caméra `cam_corr_wide` · 28 mm · hauteur 1.70 m · à 10.9 m de sa cible · mouvement : static camera · point de reprise
- Action : the investigator walks and ends a few steps in ; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet).
- Son : air conditioning hum, a glass door opening, footsteps on linoleum.

```
A scene from a fictional contemporary French police drama. The BEN's 3rd-floor corridor: 24 m long, 2.2 m wide, glass partitions on the left, numbered doors 301 to 318 on the right, 60 × 60 cm suspended ceiling tiles with fluorescent panels (one flickers), dark grey linoleum, administrative grey walls, a water fountain, a trolley of cardboard files, a safety poster, night windows and a BEN sign at the far end. Wide establishing shot, people at most a third of the frame height on the investigator, 28 mm lens, static camera. In the scene: the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, a few steps in. Action: the investigator walks and ends a few steps in; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet). Audio: air conditioning hum, a glass door opening, footsteps on linoleum. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 2 — MEDIUM sur le joueur (≈ 5 s)

- caméra `cam_corr_follow` · 50 mm · hauteur 1.50 m · à 4.4 m de sa cible · mouvement : a slow lateral tracking shot (under 8 cm/s)
- Action : the investigator walks and ends halfway down the corridor ; a silent beat of 2.5 s.
- Son : air conditioning hum, a neon tube crackling, a landline ringing far away.

```
A scene from a fictional contemporary French police drama. The BEN's 3rd-floor corridor: 24 m long, 2.2 m wide, glass partitions on the left, numbered doors 301 to 318 on the right, 60 × 60 cm suspended ceiling tiles with fluorescent panels (one flickers), dark grey linoleum, administrative grey walls, a water fountain, a trolley of cardboard files, a safety poster, night windows and a BEN sign at the far end. Medium shot, waist to head on the investigator, 50 mm lens, a slow lateral tracking shot (under 8 cm/s). In the scene: the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, halfway down the corridor. Action: the investigator walks and ends halfway down the corridor; a silent beat of 2.5 s. Audio: air conditioning hum, a neon tube crackling, a landline ringing far away. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 3 — WIDE sur le joueur (≈ 5 s)

- caméra `cam_corr_door312` · 35 mm · hauteur 1.45 m · à 3.0 m de sa cible · mouvement : static camera · point de reprise
- Action : the investigator walks and ends at the door of office 312 ; a silent beat of 2.5 s.
- Son : air conditioning hum.

```
A scene from a fictional contemporary French police drama. The BEN's 3rd-floor corridor: 24 m long, 2.2 m wide, glass partitions on the left, numbered doors 301 to 318 on the right, 60 × 60 cm suspended ceiling tiles with fluorescent panels (one flickers), dark grey linoleum, administrative grey walls, a water fountain, a trolley of cardboard files, a safety poster, night windows and a BEN sign at the far end. Wide establishing shot, people at most a third of the frame height on the investigator, 35 mm lens, static camera. In the scene: the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, at the door of office 312. Action: the investigator walks and ends at the door of office 312; a silent beat of 2.5 s. Audio: air conditioning hum. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

### S01-01B — Bureau 312

**Lieu** : Bureau 312 (`ENV_BEN_OFFICE_LACAZE`) · **Carton** : « BEN · BUREAU 312 · 21:06 » · **Personnages** : le joueur, Bernard Lacaze

**Décor** : Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off.


#### Plan 1 — WIDE sur Bernard Lacaze (≈ 4 s)

- caméra `cam_lac_door` · 35 mm · hauteur 1.50 m · à 4.0 m de sa cible · mouvement : static camera · point de reprise
- Action : Lacaze reads a file and turns a page ; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet).
- Son : quiet office at night, distant city.

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Wide establishing shot, people at most a third of the frame height on Lacaze, 35 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, just inside the door. Action: Lacaze reads a file and turns a page; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet). Audio: quiet office at night, distant city. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 2 — MEDIUM sur Bernard Lacaze (≈ 3 s)

- caméra `cam_lac_ms` · 50 mm · hauteur 1.20 m · à 2.1 m de sa cible · mouvement : static camera
- Son : quiet office at night, distant city, a door closing softly.
- Dialogue :
  - **BERNARD LACAZE** : « {player.lastName}. Fermez la porte. »

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Medium shot, waist to head on Lacaze, 50 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, just inside the door. Lacaze says quietly in French: "Delmas. Fermez la porte." Audio: quiet office at night, distant city, a door closing softly. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 3 — PAR-DESSUS L'ÉPAULE sur le joueur (≈ 4 s)

- caméra `cam_lac_os` · 50 mm · hauteur 1.50 m · à 2.7 m de sa cible · mouvement : static camera
- Action : the investigator walks and ends seated in the visitor's chair ; a silent beat of 2 s ; a grey-blue agent's file (DOSSIER D'AGENT) appears (put on the desk / brought in).
- Son : quiet office at night, distant city, a chair creaking.

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Over-the-shoulder shot, the foreground shoulder out of focus at the frame's edge on the investigator, 50 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: the investigator walks and ends seated in the visitor's chair; a silent beat of 2 s; a grey-blue agent's file (DOSSIER D'AGENT) appears (put on the desk / brought in). Audio: quiet office at night, distant city, a chair creaking. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 4 — CLOSE sur Bernard Lacaze (≈ 5 s)

- caméra `cam_lac_cu` · 85 mm · hauteur 1.21 m · à 1.9 m de sa cible · mouvement : static camera · point de reprise
- Action : Lacaze reads a file and turns a page.
- Son : quiet office at night, distant city.
- Dialogue :
  - **BERNARD LACAZE** : « Douze ans de terrain. Vous êtes là parce qu'on me l'a demandé. »
    - **Réponse A** « Et vous, vous l'auriez demandé ? » *(fin de chapitre : « Vous avez demandé à Lacaze s'il vous aurait {g:choisi|choisie|choisi}. »)*
      - **JOUEUR** : « Et vous, vous l'auriez demandé ? »
      - *(coupe : CLOSE `cam_lac_cu`)*
      - **BERNARD LACAZE** : « Pas encore. »
    - **Réponse B** « Je ferai le travail. » *(fin de chapitre : « Vous avez promis à Lacaze de faire le travail. »)*
      - **JOUEUR** : « Je ferai le travail. »
      - *(coupe : CLOSE `cam_lac_cu`)*
      - **BERNARD LACAZE** : « On verra. » — *nods*
    - **Réponse —** « Ne rien dire » *(fin de chapitre : « Vous n'avez rien répondu à Lacaze, et il a levé les yeux. »; silence tenu 2 s, CLOSE `cam_lac_cu`)*

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Close shot, shoulders to head on Lacaze, 85 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: Lacaze reads a file and turns a page. Lacaze says quietly in French: "Douze ans de terrain. Vous êtes là parce qu'on me l'a demandé." Audio: quiet office at night, distant city. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 4 · réponse A — CLOSE (`cam_lac_cu`)*

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Close shot, shoulders to head on Lacaze, 85 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice. Lacaze says quietly in French: "Pas encore." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 4 · réponse B — CLOSE (`cam_lac_cu`)*

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Close shot, shoulders to head on Lacaze, 85 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice. Lacaze says quietly in French: "On verra." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 4 · silence — CLOSE (`cam_lac_cu`)*

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Close shot, shoulders to head on Lacaze, 85 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice. He holds a silence for two seconds, then looks up. Lacaze says quietly in French: "" Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 5 — MEDIUM sur Bernard Lacaze (≈ 4 s)

- caméra `cam_lac_ms` · 50 mm · hauteur 1.20 m · à 2.1 m de sa cible · mouvement : static camera · point de reprise
- Action : a grey-blue agent's file (DOSSIER D'AGENT) is taken away ; Lacaze takes something out of a drawer ; a silent beat of 1.5 s ; a worn kraft case folder (N° 001) appears (put on the desk / brought in) ; Lacaze puts it down on the desk.
- Son : quiet office at night, distant city, a wooden drawer sliding.

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Medium shot, waist to head on Lacaze, 50 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: a grey-blue agent's file (DOSSIER D'AGENT) is taken away; Lacaze takes something out of a drawer; a silent beat of 1.5 s; a worn kraft case folder (N° 001) appears (put on the desk / brought in); Lacaze puts it down on the desk. Audio: quiet office at night, distant city, a wooden drawer sliding. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 6 — OBJET · objet : a worn kraft case folder (N° 001) (≈ 3 s)

- caméra `cam_lac_desk_top` · 100 mm · hauteur 1.22 m · à 0.7 m de sa cible · mouvement : static camera
- Action : a transparent sealed evidence bag with a red seal strip, a black smartphone inside appears (put on the desk / brought in).
- Son : quiet office at night, distant city, a plastic evidence bag crinkling.
- Dialogue :
  - **BERNARD LACAZE** : « Marseille. Un homme de vingt-six ans. »

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Macro insert on the object, background out of focus on a worn kraft case folder (N° 001), 100 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: a transparent sealed evidence bag with a red seal strip, a black smartphone inside appears (put on the desk / brought in). Lacaze says quietly in French: "Marseille. Un homme de vingt-six ans." Audio: quiet office at night, distant city, a plastic evidence bag crinkling. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 7 — OBJET · objet : a transparent sealed evidence bag with a red seal strip, a black smartphone inside (≈ 3 s)

- caméra `cam_lac_desk_top` · 100 mm · hauteur 1.22 m · à 0.7 m de sa cible · mouvement : a very slow push-in (about 12 cm over the shot) · point de reprise
- Son : quiet office at night, distant city.
- Dialogue :
  - **BERNARD LACAZE** : « Son téléphone a été retrouvé ce matin. À vous. »

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Macro insert on the object, background out of focus on a transparent sealed evidence bag with a red seal strip, a black smartphone inside, 100 mm lens, a very slow push-in (about 12 cm over the shot). In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Lacaze says quietly in French: "Son téléphone a été retrouvé ce matin. À vous." Audio: quiet office at night, distant city. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

### S01-02 — Retour

**Lieu** : Bureau 312 (`ENV_BEN_OFFICE_LACAZE`) · **Carton** : « BEN · BUREAU 312 · 05:40 » · **Personnages** : le joueur, Bernard Lacaze

**Décor** : Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off.


#### Plan 1 — WIDE sur Bernard Lacaze (≈ 3 s)

- caméra `cam_lac_wide` · 28 mm · hauteur 1.55 m · à 4.1 m de sa cible · mouvement : static camera · point de reprise
- Action : a silent beat of 3 s (narrative silence: everything but the ambience goes quiet).
- Son : quiet office at dawn, a few distant birds.

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Wide establishing shot, people at most a third of the frame height on Lacaze, 28 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: a silent beat of 3 s (narrative silence: everything but the ambience goes quiet). Audio: quiet office at dawn, a few distant birds. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 2 — MEDIUM sur Bernard Lacaze (≈ 3 s)

- caméra `cam_lac_ms` · 50 mm · hauteur 1.20 m · à 2.1 m de sa cible · mouvement : static camera
- Action : Lacaze reads a file and turns a page ; a silent beat of 2 s.
- Son : quiet office at dawn, a few distant birds, a page turned.

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Medium shot, waist to head on Lacaze, 50 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: Lacaze reads a file and turns a page; a silent beat of 2 s. Audio: quiet office at dawn, a few distant birds, a page turned. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 3 — CLOSE sur Bernard Lacaze (≈ 4 s)

- caméra `cam_lac_cu` · 85 mm · hauteur 1.21 m · à 1.9 m de sa cible · mouvement : static camera · point de reprise
- Son : quiet office at dawn, a few distant birds.
- Dialogue :
  - *Si l’affaire est résolue :*
    - **BERNARD LACAZE** : « Bien. » — *nods*
  - *Si l’affaire n’est pas résolue :*
    - **BERNARD LACAZE** : « Ça arrive. Pas deux fois. »

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Close shot, shoulders to head on Lacaze, 85 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Lacaze says quietly in French: "Bien." Lacaze says quietly in French: "Ça arrive. Pas deux fois." Audio: quiet office at dawn, a few distant birds. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 4 — PAR-DESSUS L'ÉPAULE sur le joueur (≈ 4 s)

- caméra `cam_lac_os` · 50 mm · hauteur 1.50 m · à 2.7 m de sa cible · mouvement : static camera
- Action : Lacaze hands something over ; a white BEN ID card with the player's name and service number appears (put on the desk / brought in).
- Son : quiet office at dawn, a few distant birds.
- Dialogue :
  - **BERNARD LACAZE** : « Elle est à votre nom. Ne la perdez pas. »
    - **Réponse A** « Merci, commandant. »
      - **BERNARD LACAZE** : « Ne me remerciez pas. Ce n'est qu'une carte. »
    - **Réponse B** « Et le dossier Moreau ? » *(fin de chapitre : « Vous avez demandé ce que deviendrait le dossier Moreau. »)*
      - **BERNARD LACAZE** : « Il part au parquet de Marseille ce matin. Avec votre nom dessus. »
    - **Réponse —** « Ne rien dire » *(silence tenu 2 s, CLOSE `cam_lac_cu`)*

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Over-the-shoulder shot, the foreground shoulder out of focus at the frame's edge on the investigator, 50 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: Lacaze hands something over; a white BEN ID card with the player's name and service number appears (put on the desk / brought in). Lacaze says quietly in French: "Elle est à votre nom. Ne la perdez pas." Audio: quiet office at dawn, a few distant birds. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 4 · silence — CLOSE (`cam_lac_cu`)*

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Close shot, shoulders to head on Lacaze, 85 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice. He holds a silence for two seconds, then looks up. Lacaze says quietly in French: "" Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 5 — OBJET · objet : a white BEN ID card with the player's name and service number (≈ 2 s)

- caméra `cam_lac_desk_top` · 100 mm · hauteur 1.22 m · à 0.7 m de sa cible · mouvement : a very slow push-in (about 12 cm over the shot) · point de reprise
- Action : a silent beat of 2.5 s.
- Son : quiet office at dawn, a few distant birds.

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Macro insert on the object, background out of focus on a white BEN ID card with the player's name and service number, 100 mm lens, a very slow push-in (about 12 cm over the shot). In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: a silent beat of 2.5 s. Audio: quiet office at dawn, a few distant birds. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 6 — MEDIUM sur Bernard Lacaze (≈ 4 s)

- caméra `cam_lac_ms` · 50 mm · hauteur 1.20 m · à 2.1 m de sa cible · mouvement : static camera
- Action : transition: fade (1.3 s).
- Son : quiet office at dawn, a few distant birds.
- Dialogue :
  - **BERNARD LACAZE** : « Votre bureau est au bout du couloir. »

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Medium shot, waist to head on Lacaze, 50 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: transition: fade (1.3 s). Lacaze says quietly in French: "Votre bureau est au bout du couloir." Audio: quiet office at dawn, a few distant birds. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

### S01-03 — Mon bureau

**Lieu** : Mon bureau (`ENV_BEN_OFFICE_PLAYER`) · **Carton** : « BEN · BUREAU 327 · 06:05 » · **Personnages** : le joueur

**Décor** : The player's own office at the BEN: a 3.5 × 4 m box, grey metal desk, articulated lamp, a computer screen, a desk phone, two files, a window on the courtyard, a ceiling neon (from level 2: an archive cabinet, a framed picture, a mug, a plant, a shelf for rewards).


#### Plan 1 — WIDE sur le joueur (≈ 8 s)

- caméra `cam_po_wide` · 28 mm · hauteur 1.80 m · à 3.5 m de sa cible · mouvement : static camera · point de reprise
- Action : a silent beat of 2 s (narrative silence: everything but the ambience goes quiet) ; the investigator walks and ends standing by the desk ; the investigator puts it down on the desk ; a silent beat of 2 s.
- Son : air conditioning hum, a file slid on a desk, a desk phone ringing.

```
A scene from a fictional contemporary French police drama. The player's own office at the BEN: a 3.5 × 4 m box, grey metal desk, articulated lamp, a computer screen, a desk phone, two files, a window on the courtyard, a ceiling neon (from level 2: an archive cabinet, a framed picture, a mug, a plant, a shelf for rewards). Wide establishing shot, people at most a third of the frame height on the investigator, 28 mm lens, static camera. In the scene: the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, standing by the desk. Action: a silent beat of 2 s (narrative silence: everything but the ambience goes quiet); the investigator walks and ends standing by the desk; the investigator puts it down on the desk; a silent beat of 2 s. Audio: air conditioning hum, a file slid on a desk, a desk phone ringing. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 2 — OBJET · objet : desk_phone (≈ 4 s)

- caméra `cam_po_obj_phone` · 100 mm · hauteur 1.15 m · à 0.7 m de sa cible · mouvement : a very slow push-in (about 12 cm over the shot) · point de reprise
- Action : a silent beat of 2.5 s ; transition: fade (1 s).
- Son : air conditioning hum.

```
A scene from a fictional contemporary French police drama. The player's own office at the BEN: a 3.5 × 4 m box, grey metal desk, articulated lamp, a computer screen, a desk phone, two files, a window on the courtyard, a ceiling neon (from level 2: an archive cabinet, a framed picture, a mug, a plant, a shelf for rewards). Macro insert on the object, background out of focus on desk_phone, 100 mm lens, a very slow push-in (about 12 cm over the shot). In the scene: the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, standing by the desk. Action: a silent beat of 2.5 s; transition: fade (1 s). Audio: air conditioning hum. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```


---

## Chapitre 02 — UNE AFFAIRE PLUS COMPLEXE

*Des plans confidentiels ont quitté un cabinet d'architectes du 11ᵉ, et le code d'alarme d'une employée a servi à 22 h 31. Inès a déjà extrait son téléphone.*

Déroulé : scène S02-01 « Open space » → scène S02-02 « Bureau 312 » → **téléphone** : affaire `story_001` « Le dossier Varin » → scène S02-03 « Salle d'audition » → fin de chapitre (écrans papier) → scène S02-04 « BEN-2019-114 ».

### S02-01 — Open space

**Lieu** : Open space (`ENV_BEN_OPENSPACE`) · **Carton** : « BEN · OPEN SPACE · 08:15 » · **Personnages** : le joueur, Inès Carvalho, Marc Aubrac

**Décor** : The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning.


#### Plan 1 — WIDE sur le joueur (≈ 9 s)

- caméra `cam_os_wide` · 28 mm · hauteur 1.90 m · à 12.3 m de sa cible · mouvement : static camera · point de reprise
- Action : the investigator walks and ends in the aisle ; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet) ; a silent beat of 2.5 s ; Inès types on a keyboard.
- Son : open-plan office murmur, keyboards, a glass door opening, footsteps on linoleum, a landline ringing far away, typing.

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Wide establishing shot, people at most a third of the frame height on the investigator, 28 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, seated at his desk; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the aisle. Action: the investigator walks and ends in the aisle; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet); a silent beat of 2.5 s; Inès types on a keyboard. Audio: open-plan office murmur, keyboards, a glass door opening, footsteps on linoleum, a landline ringing far away, typing. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 2 — MEDIUM sur Inès Carvalho (≈ 19 s)

- caméra `cam_os_ines` · 50 mm · hauteur 1.30 m · à 2.2 m de sa cible · mouvement : static camera
- Action : a silent beat of 3.5 s ; the investigator walks and ends standing beside Inès's desk ; a silent beat of 2 s ; Inès turns towards the investigator.
- Son : open-plan office murmur, keyboards.
- Dialogue :
  - **INÈS CARVALHO** : « Vous êtes {player.lastName}. Deux secondes. » — *types on a keyboard*
  - **INÈS CARVALHO** : « Le téléphone de Maëlle Rocher. Extrait samedi, copie intégrale. »
  - *(coupe : CLOSE `cam_os_ines_cu`)*
  - **INÈS CARVALHO** : « Personne ne touche un téléphone saisi avant moi. Pas même Lacaze. »

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Medium shot, waist to head on Inès, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, seated at his desk; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, standing beside Inès's desk. Action: a silent beat of 3.5 s; the investigator walks and ends standing beside Inès's desk; a silent beat of 2 s; Inès turns towards the investigator. Inès says quietly in French: "Vous êtes Delmas. Deux secondes." Inès says quietly in French: "Le téléphone de Maëlle Rocher. Extrait samedi, copie intégrale." Audio: open-plan office murmur, keyboards. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 3 — MEDIUM sur Marc Aubrac (≈ 5 s)

- caméra `cam_os_aubrac_desk` · 50 mm · hauteur 1.35 m · à 1.7 m de sa cible · mouvement : static camera · point de reprise
- Action : Aubrac turns towards the investigator ; Aubrac crosses the arms.
- Son : open-plan office murmur, keyboards.
- Dialogue :
  - **MARC AUBRAC** : « C'est donc vous, {g:le nouveau|la nouvelle|le nouvel agent} de Lacaze. »

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Medium shot, waist to head on Aubrac, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, seated at his desk; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, standing beside Inès's desk. Action: Aubrac turns towards the investigator; Aubrac crosses the arms. Aubrac says quietly in French: "C'est donc vous, le nouveau de Lacaze." Audio: open-plan office murmur, keyboards. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 4 — MEDIUM sur Marc Aubrac (≈ 4 s)

- caméra `cam_os_aubrac_turn` · 50 mm · hauteur 1.30 m · à 1.6 m de sa cible · mouvement : static camera
- Son : open-plan office murmur, keyboards.
- Dialogue :
  - **MARC AUBRAC** : « Un dossier à Marseille, et on vous confie déjà celui-là. »

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Medium shot, waist to head on Aubrac, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, seated at his desk; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, standing beside Inès's desk. Aubrac says quietly in French: "Un dossier à Marseille, et on vous confie déjà celui-là." Audio: open-plan office murmur, keyboards. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 5 — MEDIUM sur Inès Carvalho (≈ 16 s)

- caméra `cam_os_ines` · 50 mm · hauteur 1.30 m · à 2.2 m de sa cible · mouvement : static camera
- Action : Inès puts it down on the desk ; a printed sheet (22:31 · CODE 03) appears (put on the desk / brought in).
- Son : open-plan office murmur, keyboards, a file slid on a desk.
- Dialogue :
  - **INÈS CARVALHO** : « Atelier Varin. Des architectes, rue de la Folie-Méricourt, dans le 11ᵉ. »
  - **INÈS CARVALHO** : « Un concours public : la médiathèque de Montreuil. Leur dossier partait vendredi avant midi. »
  - *(coupe : MEDIUM `cam_os_aubrac_turn`)*
  - **MARC AUBRAC** : « Vendredi à neuf heures, un concurrent dépose presque le même projet. Laurier & Fils. »

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Medium shot, waist to head on Inès, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, seated at his desk; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, standing beside Inès's desk. Action: Inès puts it down on the desk; a printed sheet (22:31 · CODE 03) appears (put on the desk / brought in). Inès says quietly in French: "Atelier Varin. Des architectes, rue de la Folie-Méricourt, dans le 11ᵉ." Audio: open-plan office murmur, keyboards, a file slid on a desk. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 6 — OBJET · objet : a printed sheet (22:31 · CODE 03) (≈ 10 s)

- caméra `cam_os_log` · 100 mm · hauteur 1.25 m · à 0.7 m de sa cible · mouvement : a very slow push-in (about 12 cm over the shot) · point de reprise
- Action : the investigator turns towards Aubrac.
- Son : open-plan office murmur, keyboards.
- Dialogue :
  - **INÈS CARVALHO** : « Le journal de l'alarme. Jeudi, 22 h 31 : le code de Maëlle Rocher, l'office manager. »
  - *(coupe : MEDIUM `cam_os_ines`)*
  - **INÈS CARVALHO** : « Elle dit qu'elle n'y était pas. Elle nous a confié son téléphone elle-même. »

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Macro insert on the object, background out of focus on a printed sheet (22:31 · CODE 03), 100 mm lens, a very slow push-in (about 12 cm over the shot). In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, seated at his desk; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, standing beside Inès's desk. Action: the investigator turns towards Aubrac. Inès says quietly in French: "Le journal de l'alarme. Jeudi, 22 h 31 : le code de Maëlle Rocher, l'office manager." Audio: open-plan office murmur, keyboards. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 7 — PAR-DESSUS L'ÉPAULE sur le joueur (≈ 5 s)

- caméra `cam_os_ots_aubrac` · 50 mm · hauteur 1.69 m · à 4.3 m de sa cible · mouvement : static camera
- Son : open-plan office murmur, keyboards.
- Dialogue :
  - **MARC AUBRAC** : « Quelques minutes sur son téléphone, et vous nous direz qui a ouvert cette porte ? »
    - **Réponse A** « Oui. Avec les preuves. » *(fin de chapitre : « Vous avez promis un nom à Aubrac avant d'avoir ouvert le téléphone. »)*
      - **JOUEUR** : « Oui. Avec les preuves. »
      - *(coupe : CLOSE `cam_os_aubrac_cu`)*
      - **MARC AUBRAC** : « Alors je note l'heure. »
    - **Réponse B** « Je vous dirai ce que dit le téléphone. » *(fin de chapitre : « Vous avez répondu à Aubrac que le téléphone parlerait pour vous. »)*
      - **JOUEUR** : « Je vous dirai ce que dit le téléphone. »
      - *(coupe : CLOSE `cam_os_ines_cu`)*
      - **INÈS CARVALHO** : « Bonne réponse. »
      - *(coupe : MEDIUM `cam_os_aubrac_turn`)*
      - **MARC AUBRAC** : « Un téléphone dit ce qu'on veut bien y lire. » — *shrugs*
    - **Réponse —** « Ne rien dire » *(fin de chapitre : « Vous avez laissé Aubrac douter, sans lui répondre. »; silence tenu 2 s, CLOSE `cam_os_aubrac_cu`)*
      - **MARC AUBRAC** : « Au moins, vous ne promettez rien. »

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Over-the-shoulder shot, the foreground shoulder out of focus at the frame's edge on the investigator, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, seated at his desk; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, standing beside Inès's desk. Aubrac says quietly in French: "Quelques minutes sur son téléphone, et vous nous direz qui a ouvert cette porte ?" Audio: open-plan office murmur, keyboards. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 7 · réponse A — CLOSE (`cam_os_aubrac_cu`)*

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Close shot, shoulders to head on Aubrac, 85 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival. Aubrac says quietly in French: "Alors je note l'heure." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 7 · réponse B — CLOSE (`cam_os_ines_cu`)*

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Close shot, shoulders to head on Inès, 85 mm lens, static camera. In the scene: Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic. Inès says quietly in French: "Bonne réponse." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 7 · réponse B — MEDIUM (`cam_os_aubrac_turn`)*

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Medium shot, waist to head on Aubrac, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival. Aubrac says quietly in French: "Un téléphone dit ce qu'on veut bien y lire." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 7 · silence — CLOSE (`cam_os_aubrac_cu`)*

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Close shot, shoulders to head on Aubrac, 85 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival. He holds a silence for two seconds, then looks up. Aubrac says quietly in French: "" Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 8 — MEDIUM sur Inès Carvalho (≈ 7 s)

- caméra `cam_os_ines` · 50 mm · hauteur 1.30 m · à 2.2 m de sa cible · mouvement : static camera · point de reprise
- Action : Inès types on a keyboard ; the investigator walks and ends in the aisle.
- Son : open-plan office murmur, keyboards.
- Dialogue :
  - **INÈS CARVALHO** : « Je l'ai remis sous scellé. Lacaze vous attend, bureau 312. »

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Medium shot, waist to head on Inès, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, seated at his desk; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the aisle. Action: Inès types on a keyboard; the investigator walks and ends in the aisle. Inès says quietly in French: "Je l'ai remis sous scellé. Lacaze vous attend, bureau 312." Audio: open-plan office murmur, keyboards. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 9 — WIDE sur le joueur (≈ 6 s)

- caméra `cam_os_wide` · 28 mm · hauteur 1.90 m · à 12.3 m de sa cible · mouvement : static camera
- Action : a silent beat of 3 s ; the investigator leaves ; a silent beat of 2 s ; transition: fade (1.3 s).
- Son : open-plan office murmur, keyboards, a glass door opening.

```
A scene from a fictional contemporary French police drama. The BEN's open-plan office: 12 × 18 m, sixteen grey metal desks with screens, concrete columns, rows of fluorescent panels, early morning. Wide establishing shot, people at most a third of the frame height on the investigator, 28 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, seated at his desk; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the aisle. Action: a silent beat of 3 s; the investigator leaves; a silent beat of 2 s; transition: fade (1.3 s). Audio: open-plan office murmur, keyboards, a glass door opening. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

### S02-02 — Le dossier C02-A

**Lieu** : Bureau 312 (`ENV_BEN_OFFICE_LACAZE`) · **Carton** : « BEN · BUREAU 312 · 08:40 » · **Personnages** : le joueur, Bernard Lacaze

**Décor** : Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off.


#### Plan 1 — WIDE sur Bernard Lacaze (≈ 12 s)

- caméra `cam_lac_door` · 35 mm · hauteur 1.50 m · à 4.0 m de sa cible · mouvement : static camera · point de reprise
- Action : a silent beat of 3 s (narrative silence: everything but the ambience goes quiet) ; the investigator walks and ends seated in the visitor's chair ; a silent beat of 1.5 s ; Lacaze walks and ends seated behind his desk.
- Son : quiet office at dawn, a few distant birds, a glass door opening.
- Dialogue :
  - **BERNARD LACAZE** : « Entrez. Asseyez-vous. »

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Wide establishing shot, people at most a third of the frame height on Lacaze, 35 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: a silent beat of 3 s (narrative silence: everything but the ambience goes quiet); the investigator walks and ends seated in the visitor's chair; a silent beat of 1.5 s; Lacaze walks and ends seated behind his desk. Lacaze says quietly in French: "Entrez. Asseyez-vous." Audio: quiet office at dawn, a few distant birds, a glass door opening. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 2 — WIDE sur Bernard Lacaze (≈ 2 s)

- caméra `cam_lac_wide` · 28 mm · hauteur 1.55 m · à 4.1 m de sa cible · mouvement : static camera
- Action : a silent beat of 2 s.
- Son : quiet office at dawn, a few distant birds, a chair creaking.

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Wide establishing shot, people at most a third of the frame height on Lacaze, 28 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: a silent beat of 2 s. Audio: quiet office at dawn, a few distant birds, a chair creaking. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 3 — MEDIUM sur Bernard Lacaze (≈ 14 s)

- caméra `cam_lac_ms` · 50 mm · hauteur 1.20 m · à 2.1 m de sa cible · mouvement : static camera
- Action : Lacaze reads a file and turns a page ; a silent beat of 2 s.
- Son : quiet office at dawn, a few distant birds, a page turned.
- Dialogue :
  - **BERNARD LACAZE** *(si `c02_promised`)* : « Aubrac m'a dit que vous lui aviez promis un nom. »
  - **BERNARD LACAZE** *(si `c02_phone_speaks`)* : « Inès dit que vous écoutez. Elle ne le dit de personne. »
  - **BERNARD LACAZE** *(si `c02_silent_aubrac`)* : « Aubrac dit que vous ne répondez pas. Ici, ce n'est pas un défaut. »

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Medium shot, waist to head on Lacaze, 50 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: Lacaze reads a file and turns a page; a silent beat of 2 s. Lacaze says quietly in French: "Aubrac m'a dit que vous lui aviez promis un nom." Audio: quiet office at dawn, a few distant birds, a page turned. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 4 — CLOSE sur Bernard Lacaze (≈ 9 s)

- caméra `cam_lac_cu` · 85 mm · hauteur 1.21 m · à 1.9 m de sa cible · mouvement : static camera · point de reprise
- Son : quiet office at dawn, a few distant birds.
- Dialogue :
  - **BERNARD LACAZE** : « Des plans d'architecte. Pas de mort, pas de sang. »
  - **BERNARD LACAZE** : « Mais un concours public, et des mois de travail sortis en une nuit. »
  - **BERNARD LACAZE** : « Des questions ? »
    - **Réponse A** « Pourquoi le BEN, pour des plans ? »
      - **JOUEUR** : « Pourquoi le BEN, pour des plans ? »
      - *(coupe : CLOSE `cam_lac_cu`)*
      - **BERNARD LACAZE** : « Parce que la seule preuve est dans un téléphone. »
      - **BERNARD LACAZE** : « Et que les téléphones, ici, on sait les lire. »
    - **Réponse B** « Aucune. »
      - **JOUEUR** : « Aucune. »
      - *(coupe : CLOSE `cam_lac_cu`)*
      - **BERNARD LACAZE** : « Bien. » — *nods*
    - **Réponse —** « Ne rien dire » *(silence tenu 2 s, CLOSE `cam_lac_cu`)*

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Close shot, shoulders to head on Lacaze, 85 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Lacaze says quietly in French: "Des plans d'architecte. Pas de mort, pas de sang." Audio: quiet office at dawn, a few distant birds. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 4 · réponse A — CLOSE (`cam_lac_cu`)*

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Close shot, shoulders to head on Lacaze, 85 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice. Lacaze says quietly in French: "Parce que la seule preuve est dans un téléphone." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 4 · réponse B — CLOSE (`cam_lac_cu`)*

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Close shot, shoulders to head on Lacaze, 85 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice. Lacaze says quietly in French: "Bien." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 4 · silence — CLOSE (`cam_lac_cu`)*

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Close shot, shoulders to head on Lacaze, 85 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice. He holds a silence for two seconds, then looks up. Lacaze says quietly in French: "" Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 5 — MEDIUM sur Bernard Lacaze (≈ 16 s)

- caméra `cam_lac_ms` · 50 mm · hauteur 1.20 m · à 2.1 m de sa cible · mouvement : static camera
- Action : Lacaze takes something out of a drawer ; a silent beat of 1 s ; a worn kraft case folder (N° C02-A) appears (put on the desk / brought in) ; Lacaze puts it down on the desk.
- Son : quiet office at dawn, a few distant birds, a wooden drawer sliding, a file slid on a desk.
- Dialogue :
  - **BERNARD LACAZE** *(si `c01_defiant`)* : « Vous m'aviez demandé si je vous aurais {g:choisi|choisie|choisi}. Je ne sais toujours pas. »
  - **BERNARD LACAZE** *(si `c01_dutiful`)* : « Vous m'aviez promis de faire le travail. En voilà. »
  - **BERNARD LACAZE** *(si `c01_silent`)* : « Vous ne parlez toujours pas beaucoup. Gardez ça pour les témoins. »

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Medium shot, waist to head on Lacaze, 50 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: Lacaze takes something out of a drawer; a silent beat of 1 s; a worn kraft case folder (N° C02-A) appears (put on the desk / brought in); Lacaze puts it down on the desk. Lacaze says quietly in French: "Vous m'aviez demandé si je vous aurais choisi. Je ne sais toujours pas." Audio: quiet office at dawn, a few distant birds, a wooden drawer sliding, a file slid on a desk. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 6 — OBJET · objet : a worn kraft case folder (N° C02-A) (≈ 11 s)

- caméra `cam_lac_desk_top` · 100 mm · hauteur 1.22 m · à 0.7 m de sa cible · mouvement : static camera
- Action : a silent beat of 2 s.
- Son : quiet office at dawn, a few distant birds.
- Dialogue :
  - **BERNARD LACAZE** : « Plainte de Sonia Varin, la cofondatrice. Déposée vendredi midi. »
  - **BERNARD LACAZE** : « Trois noms dans le dossier. Et un code d'alarme qui n'était à aucun d'eux. »

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Macro insert on the object, background out of focus on a worn kraft case folder (N° C02-A), 100 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: a silent beat of 2 s. Lacaze says quietly in French: "Plainte de Sonia Varin, la cofondatrice. Déposée vendredi midi." Audio: quiet office at dawn, a few distant birds. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 7 — PAR-DESSUS L'ÉPAULE sur le joueur (≈ 8 s)

- caméra `cam_lac_os` · 50 mm · hauteur 1.50 m · à 2.7 m de sa cible · mouvement : static camera · point de reprise
- Son : quiet office at dawn, a few distant birds.
- Dialogue :
  - **BERNARD LACAZE** : « Maëlle Rocher nous a remis son téléphone vendredi, à quinze heures. De son plein gré. »
  - **BERNARD LACAZE** : « Personne ne la met en cause. Pour l'instant. »

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Over-the-shoulder shot, the foreground shoulder out of focus at the frame's edge on the investigator, 50 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Lacaze says quietly in French: "Maëlle Rocher nous a remis son téléphone vendredi, à quinze heures. De son plein gré." Audio: quiet office at dawn, a few distant birds. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 8 — CLOSE sur le joueur (≈ 4 s)

- caméra `cam_lac_player_cu` · 85 mm · hauteur 1.20 m · à 1.9 m de sa cible · mouvement : static camera
- Action : a silent beat of 3 s (narrative silence: everything but the ambience goes quiet) ; Lacaze hands something over ; a transparent sealed evidence bag with a red seal strip, a black smartphone inside appears (put on the desk / brought in).
- Son : quiet office at dawn, a few distant birds, a plastic evidence bag crinkling.

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Close shot, shoulders to head on the investigator, 85 mm lens, static camera. In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Action: a silent beat of 3 s (narrative silence: everything but the ambience goes quiet); Lacaze hands something over; a transparent sealed evidence bag with a red seal strip, a black smartphone inside appears (put on the desk / brought in). Audio: quiet office at dawn, a few distant birds, a plastic evidence bag crinkling. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 9 — OBJET · objet : a transparent sealed evidence bag with a red seal strip, a black smartphone inside (≈ 6 s)

- caméra `cam_lac_desk_top` · 100 mm · hauteur 1.22 m · à 0.7 m de sa cible · mouvement : a very slow push-in (about 12 cm over the shot)
- Son : quiet office at dawn, a few distant birds.
- Dialogue :
  - **BERNARD LACAZE** : « Vous signerez le registre des scellés en sortant. »
  - **BERNARD LACAZE** : « Le téléphone de Maëlle Rocher. À vous. »

```
A scene from a fictional contemporary French police drama. Office 312, Commandant Lacaze's office: 4 × 5 m, an old wooden desk, a green banker's lamp as the main light, venetian blinds with orange sodium street light behind, a frosted glass door, two visitor chairs, a metal cabinet, shelves of files, a photo frame lying face down on the desk, a coat rack, the ceiling neon switched off. Macro insert on the object, background out of focus on a transparent sealed evidence bag with a red seal strip, a black smartphone inside, 100 mm lens, a very slow push-in (about 12 cm over the shot). In the scene: Commandant Bernard Lacaze, 58, head of the BEN: tall and lean (1.88 m), slightly stooped, short receding grey hair, clean-shaven, grey eyes, half-moon reading glasses, white shirt with sleeves rolled up and a loosened navy tie; tired but sharp, rare half-smile, never raises his voice, seated behind his desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, seated in the visitor's chair. Lacaze says quietly in French: "Vous signerez le registre des scellés en sortant." Audio: quiet office at dawn, a few distant birds. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

### S02-03 — Salle d'audition

**Lieu** : Salle d'audition (`ENV_BEN_INTERROGATION`) · **Carton** : « BEN · SALLE D'AUDITION · 19:40 » · **Personnages** : le joueur, Marc Aubrac, Inès Carvalho

**Décor** : The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup.


#### Plan 1 — WIDE sur Marc Aubrac (≈ 10 s)

- caméra `cam_int_wide` · 28 mm · hauteur 1.90 m · à 3.2 m de sa cible · mouvement : static camera · point de reprise
- Action : Aubrac reads a file and turns a page ; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet) ; Inès makes a small gesture of the hand ; the small red recording light is taken away ; the investigator walks and ends in the investigator's chair ; a silent beat of 2 s.
- Son : near silence, electrical hum, a door closing softly, a chair creaking.

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Wide establishing shot, people at most a third of the frame height on Aubrac, 28 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, in the suspect's chair; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, by the one-way mirror; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the investigator's chair. Action: Aubrac reads a file and turns a page; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet); Inès makes a small gesture of the hand; the small red recording light is taken away; the investigator walks and ends in the investigator's chair; a silent beat of 2 s. Audio: near silence, electrical hum, a door closing softly, a chair creaking. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 2 — PAR-DESSUS L'ÉPAULE sur le joueur (≈ 28 s)

- caméra `cam_int_os_suspect` · 50 mm · hauteur 1.33 m · à 2.5 m de sa cible · mouvement : static camera
- Action : Aubrac puts it down on the desk ; a printed sheet (PV · T. BELLEC) appears (put on the desk / brought in).
- Son : near silence, electrical hum, a file slid on a desk.
- Dialogue :
  - **MARC AUBRAC** *(si l'affaire est résolue)* : « Bellec a parlé. Votre rapport tenait. »
  - **MARC AUBRAC** *(si l'affaire n'est pas résolue)* : « Votre rapport désignait quelqu'un d'autre. Inès a repris la corbeille derrière vous. »
  - **MARC AUBRAC** *(si l'affaire n'est pas résolue)* : « Bellec est venu à quinze heures. Il a parlé. »
  - *(coupe : CLOSE `cam_int_cu`)*
  - **MARC AUBRAC** *(si l'affaire est résolue)* : « J'avais noté l'heure. Votre nom est arrivé à temps. »
  - *(coupe : CLOSE `cam_int_cu`)*
  - **MARC AUBRAC** *(si l'affaire n'est pas résolue)* : « J'avais noté l'heure. Le nom n'était pas le bon. »
  - *(coupe : MEDIUM `cam_int_ms`)*
  - **MARC AUBRAC** : « Douze mille euros. Il les devait à Olivier Laurier depuis l'an dernier. »
  - **MARC AUBRAC** : « Laurier lui a proposé d'effacer la dette. Contre le dossier Montreuil. »

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Over-the-shoulder shot, the foreground shoulder out of focus at the frame's edge on the investigator, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, in the suspect's chair; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, by the one-way mirror; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the investigator's chair. Action: Aubrac puts it down on the desk; a printed sheet (PV · T. BELLEC) appears (put on the desk / brought in). Aubrac says quietly in French: "Bellec a parlé. Votre rapport tenait." Audio: near silence, electrical hum, a file slid on a desk. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 3 — OBJET · objet : a printed sheet (PV · T. BELLEC) (≈ 2 s)

- caméra `cam_int_table` · 100 mm · hauteur 1.20 m · à 0.8 m de sa cible · mouvement : static camera
- Action : a silent beat of 2 s.
- Son : near silence, electrical hum.

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Macro insert on the object, background out of focus on a printed sheet (PV · T. BELLEC), 100 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, in the suspect's chair; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, by the one-way mirror; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the investigator's chair. Action: a silent beat of 2 s. Audio: near silence, electrical hum. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 4 — MEDIUM sur Inès Carvalho (≈ 10 s)

- caméra `cam_int_ines` · 50 mm · hauteur 1.50 m · à 2.0 m de sa cible · mouvement : static camera · point de reprise
- Son : near silence, electrical hum.
- Dialogue :
  - **INÈS CARVALHO** : « « On est quittes. » C'était pour Laurier. Il l'a envoyé à Maëlle. »
  - *(coupe : MEDIUM `cam_int_ms`)*
  - **MARC AUBRAC** : « Une minute plus tard, il l'effaçait. Il croyait que ça suffisait. »
  - *(coupe : CLOSE `cam_int_ines_cu`)*
  - **INÈS CARVALHO** : « Ils le croient tous. »

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Medium shot, waist to head on Inès, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, in the suspect's chair; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, by the one-way mirror; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the investigator's chair. Inès says quietly in French: "« On est quittes. » C'était pour Laurier. Il l'a envoyé à Maëlle." Audio: near silence, electrical hum. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 5 — MEDIUM sur Inès Carvalho (≈ 9 s)

- caméra `cam_int_ines` · 50 mm · hauteur 1.50 m · à 2.0 m de sa cible · mouvement : static camera
- Son : near silence, electrical hum.
- Dialogue :
  - **INÈS CARVALHO** : « Maëlle Rocher a confirmé. Elle lui a donné son code, puis elle s'est tue. »
  - **INÈS CARVALHO** : « Donner son code est interdit, à l'atelier. Elle avait peur pour sa place. »

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Medium shot, waist to head on Inès, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, in the suspect's chair; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, by the one-way mirror; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the investigator's chair. Inès says quietly in French: "Maëlle Rocher a confirmé. Elle lui a donné son code, puis elle s'est tue." Audio: near silence, electrical hum. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 6 — PAR-DESSUS L'ÉPAULE sur le joueur (≈ 5 s)

- caméra `cam_int_os_suspect` · 50 mm · hauteur 1.33 m · à 2.5 m de sa cible · mouvement : static camera · point de reprise
- Son : near silence, electrical hum.
- Dialogue :
  - **MARC AUBRAC** : « Elle a donné son code à un homme qui mentait. On l'écrit, dans la synthèse ? »
    - **Réponse A** « Oui. Elle a donné son code. » *(fin de chapitre : « Vous avez fait écrire que Maëlle Rocher avait donné son code. »)*
      - **JOUEUR** : « Oui. Elle a donné son code. »
      - *(coupe : CLOSE `cam_int_cu`)*
      - **MARC AUBRAC** : « C'est la procédure. Le parquet fera le tri. » — *nods*
    - **Réponse B** « Elle s'est fait avoir. On écrit ça. » *(fin de chapitre : « Vous avez écrit que Maëlle Rocher s'était fait avoir. »)*
      - **JOUEUR** : « Elle s'est fait avoir. On écrit ça. »
      - *(coupe : CLOSE `cam_int_ines_cu`)*
      - **INÈS CARVALHO** : « Merci. »
      - *(coupe : MEDIUM `cam_int_ms`)*
      - **MARC AUBRAC** : « On écrira les deux. Le parquet choisira. » — *shrugs*
    - **Réponse —** « Ne rien dire » *(fin de chapitre : « Vous n'avez rien dit quand Aubrac a parlé de Maëlle Rocher. »; silence tenu 2 s, CLOSE `cam_int_cu`)*
      - **MARC AUBRAC** : « Alors j'écris les faits. Rien d'autre. »

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Over-the-shoulder shot, the foreground shoulder out of focus at the frame's edge on the investigator, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, in the suspect's chair; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, by the one-way mirror; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the investigator's chair. Aubrac says quietly in French: "Elle a donné son code à un homme qui mentait. On l'écrit, dans la synthèse ?" Audio: near silence, electrical hum. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 6 · réponse A — CLOSE (`cam_int_cu`)*

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Close shot, shoulders to head on Aubrac, 85 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival. Aubrac says quietly in French: "C'est la procédure. Le parquet fera le tri." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 6 · réponse B — CLOSE (`cam_int_ines_cu`)*

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Close shot, shoulders to head on Inès, 85 mm lens, static camera. In the scene: Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic. Inès says quietly in French: "Merci." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 6 · réponse B — MEDIUM (`cam_int_ms`)*

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Medium shot, waist to head on Aubrac, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival. Aubrac says quietly in French: "On écrira les deux. Le parquet choisira." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 6 · silence — CLOSE (`cam_int_cu`)*

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Close shot, shoulders to head on Aubrac, 85 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival. He holds a silence for two seconds, then looks up. Aubrac says quietly in French: "" Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 7 — MEDIUM sur le joueur (≈ 2 s)

- caméra `cam_int_mirror` · 35 mm · hauteur 1.50 m · à 2.5 m de sa cible · mouvement : static camera
- Action : a silent beat of 2 s.
- Son : near silence, electrical hum.

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Medium shot, waist to head on the investigator, 35 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, in the suspect's chair; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, by the one-way mirror; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the investigator's chair. Action: a silent beat of 2 s. Audio: near silence, electrical hum. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 8 — MEDIUM sur Marc Aubrac (≈ 4 s)

- caméra `cam_int_ms` · 50 mm · hauteur 1.35 m · à 1.7 m de sa cible · mouvement : static camera
- Son : near silence, electrical hum.
- Dialogue :
  - **MARC AUBRAC** : « Rentrez dormir, {player.lastName}. Lacaze lira tout ça demain. »

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Medium shot, waist to head on Aubrac, 50 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, in the suspect's chair; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, by the one-way mirror; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the investigator's chair. Aubrac says quietly in French: "Rentrez dormir, Delmas. Lacaze lira tout ça demain." Audio: near silence, electrical hum. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 9 — WIDE sur Marc Aubrac (≈ 5 s)

- caméra `cam_int_wide` · 28 mm · hauteur 1.90 m · à 3.2 m de sa cible · mouvement : static camera · point de reprise
- Action : the investigator stands up ; the investigator leaves ; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet) ; transition: fade (1.3 s).
- Son : near silence, electrical hum, a door closing softly.

```
A scene from a fictional contemporary French police drama. The BEN's interview room: 3 × 4 m, a one-way mirror, acoustic wall panels, a hard 5000 K ceiling light, a small red recording light, a grey table, three chairs, a microphone, a paper cup. Wide establishing shot, people at most a third of the frame height on Aubrac, 28 mm lens, static camera. In the scene: Marc Aubrac, 49, senior inspector: stocky (1.74 m), fair skin, round face, very short grey hair, short grey beard, brown eyes, brown corduroy jacket over an off-white roll-neck; sceptical, a benevolent rival, in the suspect's chair; Inès Carvalho, 31, digital forensics analyst: petite (1.60 m), straight shoulders, olive skin, heart-shaped face, black hair in a low ponytail, brown eyes, grey sweatshirt, BEN badge on a burgundy lanyard, headphones around her neck; focused, ironic, by the one-way mirror; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, in the investigator's chair. Action: the investigator stands up; the investigator leaves; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet); transition: fade (1.3 s). Audio: near silence, electrical hum, a door closing softly. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

### S02-04 — Cent quatorze

**Lieu** : Archives, sous-sol (`ENV_BEN_ARCHIVES`) · **Carton** : « BEN · ARCHIVES · 20:10 » · **Personnages** : le joueur, Colette Vidal

**Décor** : The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk.


#### Plan 1 — WIDE sur Colette Vidal (≈ 6 s)

- caméra `cam_arc_table` · 35 mm · hauteur 1.50 m · à 1.9 m de sa cible · mouvement : static camera · point de reprise
- Action : Colette reads a file and turns a page ; the investigator walks and ends across the reading table ; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet) ; Colette turns towards the investigator.
- Son : basement hum, faint neon buzz, a neon tube crackling, footsteps on linoleum.

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Wide establishing shot, people at most a third of the frame height on Colette, 35 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Action: Colette reads a file and turns a page; the investigator walks and ends across the reading table; a silent beat of 3 s (narrative silence: everything but the ambience goes quiet); Colette turns towards the investigator. Audio: basement hum, faint neon buzz, a neon tube crackling, footsteps on linoleum. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 2 — MEDIUM sur Colette Vidal (≈ 6 s)

- caméra `cam_arc_colette` · 50 mm · hauteur 1.30 m · à 1.7 m de sa cible · mouvement : static camera
- Son : basement hum, faint neon buzz.
- Dialogue :
  - **COLETTE VIDAL** : « Je fermais. »
  - **COLETTE VIDAL** : « Le dossier Moreau, c'était vous. Je l'ai rangé la semaine dernière. »

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Medium shot, waist to head on Colette, 50 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Colette says quietly in French: "Je fermais." Audio: basement hum, faint neon buzz. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 3 — PAR-DESSUS L'ÉPAULE sur le joueur (≈ 3 s)

- caméra `cam_arc_os_desk` · 50 mm · hauteur 1.75 m · à 2.4 m de sa cible · mouvement : static camera
- Action : the investigator puts it down on the desk ; a printed sheet (BEN-2019-114 — TÉMOIN) appears (put on the desk / brought in).
- Son : basement hum, faint neon buzz, a file slid on a desk.
- Dialogue :
  - **COLETTE VIDAL** : « Montrez. »

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Over-the-shoulder shot, the foreground shoulder out of focus at the frame's edge on the investigator, 50 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Action: the investigator puts it down on the desk; a printed sheet (BEN-2019-114 — TÉMOIN) appears (put on the desk / brought in). Colette says quietly in French: "Montrez." Audio: basement hum, faint neon buzz, a file slid on a desk. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 4 — OBJET · objet : a printed sheet (BEN-2019-114 — TÉMOIN) (≈ 3 s)

- caméra `cam_arc_desk_top` · 100 mm · hauteur 1.25 m · à 0.8 m de sa cible · mouvement : a very slow push-in (about 12 cm over the shot)
- Action : a silent beat of 3 s.
- Son : basement hum, faint neon buzz.

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Macro insert on the object, background out of focus on a printed sheet (BEN-2019-114 — TÉMOIN), 100 mm lens, a very slow push-in (about 12 cm over the shot). In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, seated at her desk; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Action: a silent beat of 3 s. Audio: basement hum, faint neon buzz. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 5 — MEDIUM sur Colette Vidal (≈ 14 s)

- caméra `cam_arc_colette` · 50 mm · hauteur 1.30 m · à 1.7 m de sa cible · mouvement : static camera · point de reprise
- Action : Colette reads a file and turns a page ; a silent beat of 2.5 s ; Colette stands up ; Colette walks and ends in the aisle.
- Son : basement hum, faint neon buzz.
- Dialogue :
  - **COLETTE VIDAL** : « « Affaire classée BEN-2019-114 — témoin. » »
  - **COLETTE VIDAL** : « Cent quatorze. »
  - **COLETTE VIDAL** : « Allée F. Je sais où il est. »

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Medium shot, waist to head on Colette, 50 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, in the aisle; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Action: Colette reads a file and turns a page; a silent beat of 2.5 s; Colette stands up; Colette walks and ends in the aisle. Colette says quietly in French: "« Affaire classée BEN-2019-114 — témoin. »" Colette says quietly in French: "Cent quatorze." Audio: basement hum, faint neon buzz. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 6 — WIDE sur Colette Vidal (≈ 10 s)

- caméra `cam_arc_aisle` · 28 mm · hauteur 1.60 m · à 7.8 m de sa cible · mouvement : static camera
- Action : a silent beat of 3 s (narrative silence: everything but the ambience goes quiet) ; a silent beat of 2.5 s ; Colette takes something out of a drawer ; a silent beat of 1.5 s ; Colette walks and ends at the reading table.
- Son : basement hum, faint neon buzz, footsteps on linoleum, a file slid on a desk, footsteps on linoleum.

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Wide establishing shot, people at most a third of the frame height on Colette, 28 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, at the reading table; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Action: a silent beat of 3 s (narrative silence: everything but the ambience goes quiet); a silent beat of 2.5 s; Colette takes something out of a drawer; a silent beat of 1.5 s; Colette walks and ends at the reading table. Audio: basement hum, faint neon buzz, footsteps on linoleum, a file slid on a desk, footsteps on linoleum. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 7 — MEDIUM sur le joueur (≈ 5 s)

- caméra `cam_arc_player` · 50 mm · hauteur 1.45 m · à 1.7 m de sa cible · mouvement : static camera
- Action : a silent beat of 4 s ; a cardboard archive box labelled BEN-2019-114 appears (put on the desk / brought in) ; Colette puts it down on the desk.
- Son : basement hum, faint neon buzz.

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Medium shot, waist to head on the investigator, 50 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, at the reading table; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Action: a silent beat of 4 s; a cardboard archive box labelled BEN-2019-114 appears (put on the desk / brought in); Colette puts it down on the desk. Audio: basement hum, faint neon buzz. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 8 — OBJET · objet : a cardboard archive box labelled BEN-2019-114 (≈ 2 s)

- caméra `cam_arc_box` · 100 mm · hauteur 1.20 m · à 0.7 m de sa cible · mouvement : static camera · point de reprise
- Action : a silent beat of 2.5 s.
- Son : basement hum, faint neon buzz.

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Macro insert on the object, background out of focus on a cardboard archive box labelled BEN-2019-114, 100 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, at the reading table; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Action: a silent beat of 2.5 s. Audio: basement hum, faint neon buzz. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 9 — PAR-DESSUS L'ÉPAULE sur le joueur (≈ 4 s)

- caméra `cam_arc_os_table` · 50 mm · hauteur 1.75 m · à 2.3 m de sa cible · mouvement : static camera
- Son : basement hum, faint neon buzz.
- Dialogue :
  - **COLETTE VIDAL** : « Pour l'ouvrir, il me faut une demande signée du commandant. »
    - **Réponse A** « Je la demanderai demain à Lacaze. »
      - **JOUEUR** : « Je la demanderai demain à Lacaze. »
      - *(coupe : CLOSE `cam_arc_colette_cu`)*
      - **COLETTE VIDAL** : « Demain, alors. Il reste ici. »
    - **Réponse B** « Je voulais savoir s'il existait. »
      - **JOUEUR** : « Je voulais savoir s'il existait. »
      - *(coupe : CLOSE `cam_arc_colette_cu`)*
      - **COLETTE VIDAL** : « Il existe. »
    - **Réponse —** « Ne rien dire » *(silence tenu 2 s, CLOSE `cam_arc_colette_cu`)*
      - **COLETTE VIDAL** : « Je le garde de côté. Le soir, personne ne descend. »

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Over-the-shoulder shot, the foreground shoulder out of focus at the frame's edge on the investigator, 50 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, at the reading table; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Colette says quietly in French: "Pour l'ouvrir, il me faut une demande signée du commandant." Audio: basement hum, faint neon buzz. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 9 · réponse A — CLOSE (`cam_arc_colette_cu`)*

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Close shot, shoulders to head on Colette, 85 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow. Colette says quietly in French: "Demain, alors. Il reste ici." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 9 · réponse B — CLOSE (`cam_arc_colette_cu`)*

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Close shot, shoulders to head on Colette, 85 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow. Colette says quietly in French: "Il existe." Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

*Plan 9 · silence — CLOSE (`cam_arc_colette_cu`)*

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Close shot, shoulders to head on Colette, 85 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow. He holds a silence for two seconds, then looks up. Colette says quietly in French: "" Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 10 — MEDIUM sur le joueur (≈ 2 s)

- caméra `cam_arc_player` · 50 mm · hauteur 1.45 m · à 1.7 m de sa cible · mouvement : static camera
- Action : a silent beat of 2.5 s.
- Son : basement hum, faint neon buzz.

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Medium shot, waist to head on the investigator, 50 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, at the reading table; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Action: a silent beat of 2.5 s. Audio: basement hum, faint neon buzz. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 11 — CLOSE sur Colette Vidal (≈ 8 s)

- caméra `cam_arc_colette_cu` · 85 mm · hauteur 1.45 m · à 1.9 m de sa cible · mouvement : static camera · point de reprise
- Action : Colette takes something out of a drawer.
- Son : basement hum, faint neon buzz.
- Dialogue :
  - **COLETTE VIDAL** : « Personne ne l'a demandé en sept ans. Vous êtes {g:le premier|la première|la première personne}. »
  - **COLETTE VIDAL** : « Il est léger. »

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Close shot, shoulders to head on Colette, 85 mm lens, static camera. In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, at the reading table; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Action: Colette takes something out of a drawer. Colette says quietly in French: "Personne ne l'a demandé en sept ans. Vous êtes le premier." Colette says quietly in French: "Il est léger." Audio: basement hum, faint neon buzz. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```

#### Plan 12 — OBJET · objet : a cardboard archive box labelled BEN-2019-114 (≈ 4 s)

- caméra `cam_arc_box` · 100 mm · hauteur 1.20 m · à 0.7 m de sa cible · mouvement : a very slow push-in (about 12 cm over the shot)
- Action : a silent beat of 3 s (narrative silence: everything but the ambience goes quiet) ; transition: fade (1.3 s).
- Son : basement hum, faint neon buzz.

```
A scene from a fictional contemporary French police drama. The BEN's archives in the basement: low 2.3 m ceiling, aisles of 2.4 m metal shelves full of numbered cardboard archive boxes, strips of 3500 K neon with dark zones, a reading table with a green lamp, a ladder, the archivist's small wooden desk. Macro insert on the object, background out of focus on a cardboard archive box labelled BEN-2019-114, 100 mm lens, a very slow push-in (about 12 cm over the shot). In the scene: Colette Vidal, 63, the BEN's archivist: slight (1.57 m), fair skin, grey bob, grey eyes, glasses on a thin chain, beige cardigan over grey; kind and slow, at the reading table; the investigator (a man or a woman chosen by the player: only seen from behind, over the shoulder or with the face out of focus), in a dark coat, across the reading table. Action: a silent beat of 3 s (narrative silence: everything but the ambience goes quiet); transition: fade (1.3 s). Audio: basement hum, faint neon buzz. Contemporary restrained French police thriller, stylised realism (believable at first glance, simplified micro-details, matte materials), renovated 1970s French administrative building, night. Cool 4000 K fluorescent light mixed with warm 2700 K desk lamps, desaturated colours (-15 %), lifted blacks (never pure black), shadows tinted towards #1C2230, highlights towards #F2E6D2, 1.5 % film grain, light vignette. Vertical 9:16. Slow camera moves only (never handheld shake, never a dutch angle, no drone, no lens flare, no motion blur, no bloom). Red only on meaningful objects (a seal, a recording light). No subtitles, no on-screen text, no captions, no logos, no readable signs.
```


---

Durée totale estimée des scènes : ≈ 6 min (hors branches).

