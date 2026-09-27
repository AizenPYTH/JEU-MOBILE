# Sons du jeu (scripts/audio)

## Sons du mode Histoire

Générés par `scripts/audio/gen_story_sounds.py` (Python pur, aucune dépendance, aucun son tiers), écrits dans
`ScreenshotKit/Sources/ScreenshotUI/Resources/Sounds/` à côté des sons de `gen_sounds.py`, que ce script ne touche
jamais.

```bash
python3 scripts/audio/gen_story_sounds.py
```

- **Format** : WAV mono 16 bits, comme les sons existants. Effets ponctuels à 22 050 Hz (la fréquence des sons
  existants) ; ambiances à 11 025 Hz (contenu grave et sombre) pour garder l'app légère : 20 fichiers, 2,9 Mo au total.
- **Déterministe** : chaque son a sa propre graine (tirée de son nom) ; relancer le script redonne les mêmes fichiers,
  et modifier un son ne change pas les autres.
- **Boucles sans raccord** : bruit fondu dans son propre début (`env_loop`, à puissance constante), sons tenus avec
  un nombre entier de cycles, filtres et réverbérations calculés en boucle, événements qui repassent par le début.
- **Direction** (docs/design_story/TRANSITIONS.md §5) : sobre, administratif, nocturne, réaliste. Ni musique ni
  effet dramatique. Niveaux fixés dans le fichier : ambiances très basses (RMS −20 à −26 dBFS, donc environ −30 dB
  au volume 0,35 de `StoryCoordinator`), effets secs et courts (−12 à −19 dBFS sur 50 ms), plus discrets que les
  sons d'interface.

### Ambiances (en boucle, `AudioDirector.loop`)

| Fichier | Durée | Contenu | Utilisation |
|---|---|---|---|
| `ben_hvac` | 12 s | Climatisation : souffle grave continu, léger sifflement des bouches, faible ronflement secteur 50 Hz | Couloir du 3ᵉ, bureau du joueur, salle de réunion |
| `ben_office_night` | 20 s | Climatisation plus douce, ville lointaine derrière la fenêtre, deux voitures très lointaines | Bureau 312 (Lacaze), la nuit |
| `ben_office_dawn` | 20 s | Même bureau à l'aube, plus léger : une voiture lointaine, quelques oiseaux très bas en fin de boucle | Scènes du petit matin (S01-02, S02-02) |
| `ben_openspace` | 20 s | Climatisation, murmure de voix lointaines (inintelligibles), claviers épars, une imprimante au loin | Open space |
| `ben_archives` | 16 s | Sous-sol : ronflement plus grave, grésillement faible d'un néon à 100 Hz, rare claquement de tuyau | Archives |
| `ben_interrogation` | 10 s | Presque silence : ton de la pièce, faible ronflement électrique du matériel d'enregistrement | Salle d'audition |

### Effets ponctuels (joués par leur nom, `AudioDirector.play`)

| Fichier | Durée | Contenu |
|---|---|---|
| `steps_lino` | 1,85 s | Cinq pas sur du lino, semelles souples |
| `door_glass` | 1 s | Porte de bureau vitrée qui s'ouvre (poignée, pêne, vitre, battant) |
| `door_close` | 0,8 s | Porte pleine refermée doucement (bois, pêne) |
| `chair` | 0,8 s | Quelqu'un s'assoit dans un fauteuil de bureau (craquement, tissu) |
| `drawer` | 0,9 s | Tiroir de bureau en bois qu'on ouvre |
| `page` | 0,5 s | Une page tournée |
| `paper_slide` | 0,6 s | Une chemise glissée sur le bureau |
| `plastic_bag` | 0,9 s | Sachet de scellé en plastique manipulé |
| `neon_buzz` | 1,2 s | Néon qui grésille trois fois |
| `phone_distant` | 2 s | Téléphone fixe qui sonne deux fois au fond du couloir (étouffé, réverbéré) |
| `desk_phone_ring` | 1,5 s | Téléphone de bureau qui sonne une fois, tout près (trille à deux tons) |
| `keyboard` | 1,2 s | Courte frappe au clavier |
| `printer` | 1,8 s | Imprimante laser qui sort une page |
| `coffee_machine` | 1,8 s | Machine à expresso : ronronnement de la pompe |

Un nom de son absent est ignoré sans erreur par `AudioDirector` : on peut nommer un son dans une scène avant de le
générer.
