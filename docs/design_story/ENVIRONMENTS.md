# ENVIRONMENTS.md — Décors

**Règle d'économie** : au total, 10 décors excellents, construits à partir d'un **kit modulaire commun** :
- murs, portes et fenêtres ;
- faux plafonds, néons et mobilier.

Chaque décor extérieur doit servir à au moins 2 affaires ou chapitres.

**Kit commun `KIT_BEN`** :
- panneaux muraux de 1 m et 2 m ;
- porte vitrée et porte pleine ;
- store vénitien ;
- plafond de dalles de 60 × 60 cm avec néon ;
- radiateur en fonte ;
- prises murales ;
- bureau métal, bureau bois ;
- chaise de bureau et chaise visiteur ;
- armoire à rideau, étagère d'archives, boîtes d'archives ;
- lampe de bureau verte et lampe articulée ;
- téléphone fixe, écran et clavier, gobelet.

## 1. Décors du BEN (P0 / P1)

| ID | Lieu | Architecture | Lumière | Mobilier clé | Caméras nommées | Réutilisation |
|---|---|---|---|---|---|---|
| ENV_BEN_CORRIDOR (P0) | Couloir, 3ᵉ étage | 24 m de long, 2,2 m de large, cloisons vitrées à gauche, portes numérotées 301 à 318 | Néons de 4 000 K dont un qui grésille, fenêtres de nuit au fond | Chariot à dossiers, fontaine à eau, panneau BEN | `cam_corr_wide`, `cam_corr_follow`, `cam_corr_door312` | Hub h04, transitions T-SIG-2, toutes les entrées |
| ENV_BEN_OFFICE_LACAZE (P0) | Bureau 312 | 4 × 5 m, fenêtre à stores, porte vitrée | Lampe verte de 2 700 K (principale), rue sodium en contre-jour, néon éteint | Bureau en bois ancien, 2 chaises visiteur, armoire, piles de dossiers, cadre de photo retourné | `cam_lac_wide`, `cam_lac_ms`, `cam_lac_cu`, `cam_lac_os`, `cam_lac_desk_top` (OBJECT FOCUS) | Briefings et retours de tous les chapitres |
| ENV_BEN_OFFICE_PLAYER (P0) | Bureau du joueur | Niveaux 01–02 : box de 3 × 3 m dans l'open space ; niveaux 03–04 : bureau fermé de 3,5 × 4 m (même géométrie avec cloison ajoutée) | Néon + lampe | Voir §2 | `cam_po_wide` (h09), `cam_po_obj_{hotspot}` | h09, S01-03, récompenses |
| ENV_BEN_OPENSPACE (P1) | Open space | 12 × 18 m, 16 postes, colonnes | Néons, écrans | Postes répétés en instances | `cam_os_wide`, `cam_os_ines` | Scènes avec Inès et Aubrac, fond des bureaux 01–02 |
| ENV_BEN_ARCHIVES (P1) | Sous-sol | Allées d'étagères de 2,4 m, plafond bas de 2,3 m | Néons de 3 500 K en bandes, zones sombres | Boîtes numérotées, échelle, table de lecture | `cam_arc_aisle`, `cam_arc_table` | Colette, anciens dossiers |
| ENV_BEN_INTERROGATION (P1) | Salle d'audition | 3 × 4 m, miroir sans tain, murs isolés | Plafonnier de 5 000 K, dur ; voyant d'enregistrement rouge | Table, 3 chaises, micro, gobelet | `cam_int_wide`, `cam_int_os_suspect`, `cam_int_cu`, `cam_int_mirror` | Interrogatoires à partir du chapitre 03 |
| ENV_BEN_BRIEFING (P1) | Salle de réunion | 6 × 8 m, écran mural, table longue | Néons atténués, écran émissif | 10 chaises, tableau blanc | `cam_brf_wide`, `cam_brf_screen` | Débuts de chapitre et affaires d'équipe |

## 2. Bureau du joueur : 4 niveaux

| Niveau | Rang | Contenu | Points interactifs (hotspots) |
|---|---|---|---|
| OFFICE_01 | Enquêteur | Bureau métal gris, écran, lampe articulée, téléphone fixe, 2 chemises, mur nu, fenêtre sur la cour | TÉLÉPHONE, ORDINATEUR, DOSSIERS |
| OFFICE_02 | Inspecteur | + armoire d'archives, cadre (1ᵉʳ dossier résolu), mug, plante | + ARCHIVES, RÉCOMPENSES |
| OFFICE_03 | Insp. senior | Bureau fermé : bureau en bois, tableau en liège avec fil et photos, deuxième écran, lampe en laiton | + TABLEAU |
| OFFICE_04 | Expérimenté | + store, coffre à dossiers sensibles, distinctions au mur, fauteuil, porte à son nom | + COFFRE |

- **Récompenses** : objets posés à des emplacements fixes numérotés (`slot_01` à `slot_12`) ; au plus 12 par bureau. Un objet non encore débloqué n'est pas visible (pas de silhouette).
- **Évolution subtile** : entre deux niveaux, au plus 4 éléments nouveaux. La lumière et le cadrage de `cam_po_wide` restent identiques pour que la comparaison soit lisible.

## 3. Décors extérieurs et civils (P2, réutilisables)

| ID | Lieu | Variantes d'éclairage | Réutilisation prévue |
|---|---|---|---|
| ENV_STREET | Rue urbaine, immeubles haussmanniens et modernes, 40 m | Nuit sodium / pluie / aube | Paris (#004), Lyon (#002), chapitres |
| ENV_APARTMENT | Appartement 2 pièces, mobilier interchangeable (3 jeux) | Jour / nuit | Témoins, victimes |
| ENV_CAFE | Café de quartier, comptoir et terrasse | Matin / soir | Rencontres, témoins |
| ENV_PARKING | Parking souterrain, 2 niveaux | Néon / panne partielle | #001, chapitres |
| ENV_METRO | Quai et couloir, signalétique fictive | Premier métro / nuit | #002 |
| ENV_WAREHOUSE | Entrepôt portuaire, conteneurs | Nuit pluie / jour gris | #001 (zone portuaire), #005 |

**Règles pour les décors extérieurs**
- Signalétique entièrement fictive.
- Aucune marque ni plaque d'immatriculation lisible.
- Figurants limités à 4 silhouettes en arrière-plan flou.

## 4. Caméras
- Chaque décor livre ses caméras nommées : position, rotation, focale et mise au point par défaut.
- Les scènes ne font que référencer ces caméras. Un plan non prévu entraîne l'ajout d'une caméra dans le décor, jamais une caméra libre dans le script.
