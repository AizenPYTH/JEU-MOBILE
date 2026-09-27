# ASSET_MANIFEST.md — Assets du mode Histoire

**Priorités**
- **P0** : indispensable au chapitre 01 et au Bureau à 3 modes.
- **P1** : nécessaire au système complet.
- **P2** : contenu futur.

**Déjà existants et réutilisés tels quels** :
- textures papier et kraft ;
- tampons (`phase2/assets/stamps`) ;
- sceaux, signature et cachets de rang (`phase2/assets/joueur`) ;
- logo ;
- portraits 2D des personnages (05) ;
- sons de base.

## P0 · Chapitre 01 et Bureau

| ID | Nom | Type | Dimensions / budget | Format | Usage | Style | Réutilisation |
|---|---|---|---|---|---|---|---|
| UI_MODEFOLDER_SET | Chemises de mode (3) | UI code | 358 × 118–156 pt | SwiftUI | h01 | DESIGN_SYSTEM §5 | Permanent |
| UI_ALIBI_CARD | Fiche déclaration | UI code | 358 pt × auto | SwiftUI | h03, h01 | Papier #DCDFE2 | Tous les alibis |
| UI_DIALOGUE | Sous-titre, choix, journal, HUD | UI code | — | SwiftUI | h11, h12 | DIALOGUE_UI | Toutes les scènes |
| STAMP_NOUVEAU | Tampon NOUVEAU | 2D | ≈ 600 × 180 px, 3 encres | PNG transparent | Dossiers | Même générateur que `phase2/assets/stamps` | Permanent |
| STAMP_CLASSE | Tampon CLASSÉ | 2D | Idem | PNG | Dossiers, chapitre | Idem | Permanent |
| PLAYER_BASE_FEMALE | Base joueuse | 3D personnage | 45 k tris, 2 × 2K | USDZ/GLB | Toutes les scènes, h04–h06 | 3D_DIRECTION §2 | Permanent |
| PLAYER_BASE_MALE | Base joueur | 3D personnage | Idem | USDZ/GLB | Idem | Idem | Permanent |
| PLAYER_SKIN_01–06 | Teints | Textures | 2K albédo, rugosité, SSS | KTX2 | Création | CUSTOMIZATION §3 | Deux bases |
| PLAYER_FACE_F01–06 / M01–06 | Visages | Morph targets | — | Dans la base | Création | Idem | — |
| PLAYER_HAIR_F01–06 / M01–06 | Coupes | Hair cards | ≤ 12 k tris chacune | USDZ/GLB | Création | Idem | — |
| PLAYER_HAIRCOLOR_01–06 | Couleurs de cheveux | Paramètres de matériau | — | — | Création | — | Toutes les coupes |
| PLAYER_EYES_01–06 | Iris | Texture | 512 | KTX2 | Création | — | — |
| PLAYER_FACIALHAIR_M01–03 | Pilosité | Texture + cartes | — | — | Création | — | — |
| OUTFIT_01–04 (A/B) | Tenues × 2 variantes | 3D vêtements | 12–18 k tris chacune | USDZ/GLB | Création, scènes | CUSTOMIZATION §4 | Deux bases (ajustement par base) |
| NPC_LACAZE | Cdt. Lacaze | 3D personnage | 40 k tris | USDZ/GLB | Toutes les scènes de briefing | NPC_DIRECTION | Permanent |
| NPC_BEN_AGENT_A | Figurant | 3D personnage | 20 k tris | USDZ/GLB | Arrière-plans | — | Tous les décors BEN |
| ANIM_BODY_SET_20 | Bibliothèque de 20 animations | Animation | — | FBX/USD | Tous les personnages | 3D_DIRECTION §6 | Permanent |
| ANIM_FACE_SET_12 | 12 expressions | Blendshapes | — | — | Idem | Idem | Permanent |
| ANIM_HANDS_SET_6 | 6 poses de mains | Animation | — | — | Idem | — | — |
| ENV_BEN_CORRIDOR | Couloir | 3D décor | 250 k tris max, lightmaps | USDZ/GLB | S01-01, h04, T-SIG-2 | ENVIRONMENTS §1 | Tous les chapitres |
| ENV_BEN_OFFICE_LACAZE | Bureau 312 | 3D décor | Idem | USDZ/GLB | S01-01, S01-02 | Idem | Tous les chapitres |
| ENV_BEN_OFFICE_PLAYER_L01 | Bureau du joueur, niveau 1 | 3D décor | Idem | USDZ/GLB | S01-03, h09 | ENVIRONMENTS §2 | Base des L02–L04 |
| KIT_BEN | Kit modulaire | 3D props | ~40 pièces | USDZ/GLB | Tous les décors BEN | — | Permanent |
| PROP_BEN_BADGE | Carte BEN (plastique / métal) | 3D prop | 2 k tris, texture générée (nom, matricule) | USDZ/GLB | S01-02, personnage | — | Permanent |
| PROP_EVIDENCE_BAG_PHONE | Sachet de scellé + téléphone | 3D prop | 6 k tris, écran = texture de rendu | USDZ/GLB | T-SIG-1 | — | Toutes les affaires |
| PROP_CASE_FOLDER | Chemise kraft, élastique, étiquette | 3D prop | 3 k tris, textures 2D existantes | USDZ/GLB | T-SIG-1, h15 | STORY_ART_DIRECTION §8 | Toutes les affaires |
| PROP_AGENT_FOLDER | Chemise d'agent grise | 3D prop | 3 k tris | USDZ/GLB | S01-01 | — | Profil |
| STUDIO_PLAYER_BG | Couloir flou précalculé | 2D | 1170 × 2532 | JPG | h04–h06 | 3D_DIRECTION §4 | Permanent |
| CAM_S4_RIG | Caméra portrait | Configuration | — | Données | Portraits | CUSTOMIZATION §5 | Tous les portraits 3D |
| AMB_BEN_HVAC, AMB_BEN_OFFICE_NIGHT | Ambiances | Audio | Boucles de 60 s | CAF/M4A | Scènes | TRANSITIONS §5 | Permanent |
| SFX_STEPS_LINO ×4, SFX_DOOR ×2, SFX_CHAIR, SFX_DRAWER | Bruitages | Audio | — | CAF | Scènes | — | Permanent |
| VO_LACAZE_C01 | Répliques du chapitre 01 | Audio | ≈ 20 répliques | M4A | S01-01/02 | NPC_DIRECTION §3 | — |
| MUS_THEME_BEN | Thème BEN | Musique | 90 s, boucle | M4A | Hub, scènes | Piano et cordes graves | Permanent |

## P1 · Système complet

| ID | Nom | Type | Usage | Réutilisation |
|---|---|---|---|---|
| ENV_BEN_OFFICE_PLAYER_L02 / L03 / L04 | Bureau du joueur, niveaux 2 à 4 | 3D décor (dérivés de L01) | h09 | — |
| ENV_BEN_OPENSPACE | Open space | 3D décor | Scènes | Arrière-plan L01–L02 |
| ENV_BEN_ARCHIVES | Archives | 3D décor | Scènes | — |
| ENV_BEN_INTERROGATION | Salle d'audition | 3D décor | Interrogatoires | Tous les chapitres à partir du 03 |
| ENV_BEN_BRIEFING | Salle de réunion | 3D décor | Débuts de chapitre | — |
| NPC_BEN_ANALYST / NPC_BEN_SENIOR / NPC_BEN_ARCHIVIST | Récurrents | 3D personnage | Scènes | Permanent |
| NPC_BEN_AGENT_B / C | Figurants | 3D personnage | Arrière-plans | — |
| NPC_LACAZE_B | Variante de nuit (veste) | 3D tenue | Scènes spéciales | — |
| PROP_REWARD_01–12 | Objets de récompense | 3D props, 8 k tris | h18, h09 | Emplacements fixes des bureaux |
| PROP_CORKBOARD | Tableau en liège avec fil | 3D prop | OFFICE_03+ | — |
| PROP_SAFE | Coffre | 3D prop | OFFICE_04 | — |
| SFX_PAPER_SET_2 | Variantes papier | Audio | UI | — |
| MUS_THEME_TENSION, MUS_THEME_RESOLUTION | Thèmes | Musique | Scènes, h16 | — |
| VO_{NPC}_C02… | Voix des chapitres | Audio | Scènes | — |

## P2 · Contenu futur

| ID | Nom | Type | Réutilisation prévue |
|---|---|---|---|
| ENV_STREET | Rue (3 éclairages) | 3D décor | #002, #004, chapitres |
| ENV_APARTMENT | Appartement (3 jeux de mobilier) | 3D décor | Témoins, victimes |
| ENV_CAFE | Café | 3D décor | Rencontres |
| ENV_PARKING | Parking souterrain | 3D décor | #001, chapitres |
| ENV_METRO | Quai de métro | 3D décor | #002 |
| ENV_WAREHOUSE | Entrepôt portuaire | 3D décor | #001, #005 |
| NPC_CASE_{ID} | PNJ d'affaire (1 par chapitre) | 3D personnage dérivé | Interrogatoires |
| OUTFIT_05–06 | Tenues supplémentaires (hiver, formelle) | 3D vêtements | — |

**Totaux visés**
- Décors : 10 (3 en P0, 5 en P1, puis 6 extérieurs en P2, en réutilisant le kit).
- Personnages : 2 bases joueur, 4 PNJ récurrents, 3 figurants.
- Animations : 20 corps, 12 visages, 6 mains.
