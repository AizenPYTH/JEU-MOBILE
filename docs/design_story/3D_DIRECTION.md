# 3D_DIRECTION.md — Bible 3D

**Objectif** : un réalisme stylisé premium. Crédible au premier regard, mais pas du photoréalisme : on simplifie les micro-détails, on soigne la lumière et les matériaux.

**Cible technique** : iPhone 12 et plus récents, en temps réel. Moteur au choix de l'équipe : RealityKit / SceneKit, Unity (URP) ou Unreal. Les valeurs ci-dessous restent neutres vis-à-vis du moteur.

## 1. Échelle et unités
- 1 unité = 1 m ; axe Y vers le haut.
- **Personnages** :

| Personnage | Taille |
|---|---|
| Base F | 1,68 m |
| Base M | 1,80 m |
| PNJ | 1,55 à 1,95 m |

- **Mobilier de bureau** :

| Élément | Dimension |
|---|---|
| Plateau | 0,75 m |
| Porte | 2,04 × 0,83 m |
| Hauteur sous faux plafond | 2,60 m |

## 2. Budgets

| Élément | Triangles (LOD0) | Textures | Matériaux | Os |
|---|---|---|---|---|
| Personnage joueur | 45 k | 2 × 2K : corps/visage, tenue | 4 max | 75 + blendshapes du visage (52 ARKit) |
| PNJ principal | 40 k | 2 × 2K | 4 | idem |
| PNJ secondaire | 20 k | 1 × 2K | 3 | 65, sans blendshapes (animations faciales de base) |
| Décor complet | 250 k | Atlas 4 × 2K + trim sheets | ≤ 24 | — |
| Prop de récompense | 8 k | 1K | 1 | — |

- **LOD** : 3 niveaux (100 / 50 / 20 %).
- **Mémoire de scène** : ≤ 450 Mo.
- **Fréquence d'image** : 30 fps garantis, 60 fps en qualité Haute sur les appareils Pro.

## 3. Matériaux (PBR métal/rugosité)

| Matière | Rugosité | Notes |
|---|---|---|
| Peau | 0,45–0,55 | Subsurface léger (rayon 2 mm), carte de micro-normales à partir du plan MEDIUM |
| Cheveux | Anisotrope | Cartes de cheveux, alpha-to-coverage |
| Laine, coton | 0,85–0,95 | Léger « sheen » |
| Cuir | 0,55 | Usure aux plis |
| Métal brossé du mobilier | 0,40, metallic 1 | Anisotropie faible |
| Lino | 0,70 | Rayures dans la carte de rugosité |
| Verre des cloisons | 0,05 | Réflexion d'écran uniquement (pas de ray tracing) |
| Papier | 0,90 | **Mêmes textures albedo que l'UI 2D** |
| Écran de téléphone | Émissif | Affiche l'UI réelle via une texture de rendu |

**Interdits** : surfaces miroir, chrome brillant, émissifs colorés, textures sales exagérées.

## 4. Studio de présentation du personnage (h04, h05, h06)
- **Décor** : couloir du BEN, flou d'arrière-plan à f/2 équivalent. Rendu **fixe** : pré-calculé, en billboard, pour économiser.
- **Sol** : mat, avec ombre de contact (AO).
- **Lumières** :
  1. principale : spot doux 4 500 K, 45° en haut à droite, intensité de référence ;
  2. contre-jour : 2 800 K, derrière à gauche, +0,5 EV ;
  3. remplissage : ambiance −2 EV, teinte #1C2230.
- **Caméra** : fixe. La rotation s'applique au personnage (le doigt contrôle le yaw, ±180°, inertie amortie en 400 ms).
- **Animation au repos** : respiration, transfert de poids toutes les 6 à 9 s, clignement des yeux toutes les 3 à 6 s. Aucune pose héroïque.

## 5. Éclairage des scènes
- **Lumière** : précalculée (lightmaps) pour les décors, plus 1 lumière dynamique pour les personnages et 1 lumière d'accent éventuelle.
- **Ombres** : ombres portées des personnages en temps réel (1 cascade de 1 024) ; environnement précalculé.
- **Réflexions** : une réflexion (reflection probe) par pièce.
- **Profondeur de champ** : bokeh gaussien léger. Activée par défaut en Haute, désactivée en Économie. Mise au point toujours sur les yeux de la personne qui parle, ou sur l'objet en OBJECT FOCUS.
- **Post-traitement** (dans cet ordre) :
  1. tonemapping ACES ;
  2. étalonnage (STORY_ART_DIRECTION §3) ;
  3. vignettage à 18 % ;
  4. grain de 1,5 %.
- **Interdits** : bloom (sauf 5 % sur les écrans émissifs), aberration chromatique, lens flare, flou de mouvement.

## 6. Animation
- **Bibliothèque partagée** : 20 animations corporelles réutilisées par tous les personnages, adaptées aux deux squelettes (retargeting) :

| Catégorie | Animations |
|---|---|
| Repos | Repos debout, repos assis |
| Déplacement | Marche lente, marche normale, s'asseoir, se lever |
| Gestes de bureau | Poser un objet, prendre un objet, tendre un objet, tourner une page, feuilleter |
| Écoute et réaction | Croiser les bras, se pencher en avant, se frotter les yeux, regarder un téléphone, taper sur un clavier |
| Déplacements dans le décor | Ouvrir une porte, fermer une porte, s'appuyer sur le bureau |

- **Visage** : blendshapes ARKit. 12 expressions de base (neutre, fatigue, doute, agacement, tristesse contenue, surprise légère, écoute, mépris léger, soulagement, inquiétude, sourire bref, colère froide) à 60 % d'amplitude maximum.
- **Lèvres** : synchronisation automatique à partir de la piste ElevenLabs (visèmes). Sans voix, bouche fermée et petits mouvements de mâchoire.
- **Mains** : 6 poses (détendue, tenir un dossier, tenir un téléphone, tenir un stylo, pointer, poing serré).

## 7. Caméra
- Voir STORY_SCENES §2 pour la grammaire.
- **Moteur** : caméra physique avec focale en mm et capteur 36 × 24.
- **Transitions** : exclusivement CUT, FADE et DISSOLVE (TRANSITIONS.md).

## 8. Export et nommage
- **Formats** : USDZ ou GLB selon le moteur. Textures en KTX2/ASTC.
- **Nommage** : `{TYPE}_{NOM}_{VARIANTE}_{LOD}`, par exemple `CHR_NPC_LACAZE_A_LOD0` ou `ENV_BEN_CORRIDOR_LOD1`.
- **Pivot** : au sol, au centre, face à +Z.

## 9. Profils de qualité

| Profil | Résolution de rendu | Ombres | Profondeur de champ | fps |
|---|---|---|---|---|
| Économie | 70 % | Blob | Non | 30 |
| Auto | Adaptatif 70–100 % | 1 024 | Oui (si ≥ A15) | 30 |
| Haute | 100 % | 2 048 | Oui | 60 |
