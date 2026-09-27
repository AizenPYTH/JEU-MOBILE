# TRANSITIONS.md — Transitions entre les couches

Maquettes : planche 13·14. Seuls trois types sont autorisés : **CUT · FADE · DISSOLVE**, plus le **match cut** des transitions signatures.

## 1. Transitions signatures

### T-SIG-1 · Scène 3D → téléphone (≈ 2,4 s)

| t | Plan / état | Détail |
|---|---|---|
| 0,0 | MEDIUM | Le PNJ pose le téléphone sous scellé ou la chemise (anim `put_down`). Son : carton, puis plastique |
| 0,9 | CUT → OBJECT FOCUS | Caméra `cam_*_desk_top`, 100 mm. Push-in de 12 cm en 0,8 s (ease-in-out). Profondeur de champ de 0 à 60 % |
| 1,7 | Match cut | L'écran du téléphone 3D (texture de rendu de l'écran verrouillé réel) remplit 88 % du cadre. Au même pixel, la vue SwiftUI du téléphone remplace la vue 3D : fondu enchaîné de 150 ms, puis rendu 3D mis en pause |
| 1,9 | UI | Écran verrouillé du téléphone de l'affaire (existant) ; vibration + notification |
| 2,4 | UI | Déverrouillage (existant), le chrono démarre |

- **Variante dossier** : si la sortie est `CASE_FOLDER`, le match cut se fait sur la chemise → h15 (écran 2D de la chemise, même position). Ensuite, briefing puis ouverture du téléphone, comme en ENQUÊTES.
- **Réduire les animations** : CUT direct de la scène vers l'écran 2D final, puis fondu de 200 ms.

### T-SIG-2 · Téléphone → retour au BEN (≈ 2,2 s)

| t | État | Détail |
|---|---|---|
| 0,0 | Rapport | Tap sur [CLASSER LE DOSSIER] |
| 0,0–0,3 | Fondu au noir | Luminosité de l'UI de 1 à 0 (courbe ease-in). Son : verrouillage du téléphone |
| 0,3–0,7 | Noir complet | Silence narratif, puis ambiance BEN en fondu entrant (climatisation, pas) |
| 0,7–1,3 | Fondu depuis le noir | Premier plan WIDE de la scène de retour (`cam_corr_wide` ou bureau de Lacaze) |
| 1,3+ | Scène | Comme d'habitude |

## 2. Transitions d'interface (hors 3D)

| ID | De → vers | Animation | Durée |
|---|---|---|---|
| T-UI-1 | Bureau → mode | La chemise touchée monte à l'échelle 1,02, les autres en fondu à 0 ; push avec décalage (offset) de 24 pt | 300 ms, `paper` |
| T-UI-2 | Hub Histoire → scène | Bouton [CONTINUER] → fondu au noir 400 ms → noir 300 ms → WIDE en fondu entrant 600 ms | 1,3 s |
| T-UI-3 | Création → scène 01-01 | Cachet (180 ms) → pause de 400 ms → fondu au noir 600 ms → ambiance seule 800 ms → WIDE | 2 s |
| T-UI-4 | h09 → objet | Fondu enchaîné de caméra `cam_po_wide` → `cam_po_obj_x`, puis la sheet monte | 450 ms + 300 ms |
| T-UI-5 | h16 → h17 → h18 | Push papier (feuille qui glisse de 40 pt) | 380 ms chacune |
| T-UI-6 | Sheet (Journal, description) | Présentation iOS standard, poignée visible | Système |

## 3. Micro-interactions
Spring `paper` : réponse 0,42, amortissement 0,86.

| Élément | Déclencheur | Animation |
|---|---|---|
| Papier au repos | Feuille active sur un écran statique | Rotation de ±0,3° sur 6 s (easeInOut), désactivée si Réduire les animations |
| Tampon | Événement | Échelle 1,35 → 1, flou 2 → 0, 180 ms, puis tassement de 60 ms ; haptique `rigid` |
| Dossier qui s'ouvre | Tap | Rotation 3D de la couverture 0 → −170°, 450 ms |
| Page qui tourne | Journal, rapport multi-page | Rotation 3D de −180° autour de l'axe gauche, 380 ms |
| Badge / carte | Récompense, profil | Carte qui entre de +20 pt avec rotation de 4 → 0°, 420 ms |
| Notification | Événement | Bandeau qui descend de −60 pt en 280 ms ; haptique `light` |
| Bouton physique | Toucher | Échelle 0,98, luminosité −4 %, 90 ms |
| Apparition de texte | Réplique | 28 ms par caractère ; LABEL tapé à 22 ms par caractère |
| Focus caméra | OBJECT FOCUS | Profondeur de champ en 500 ms, jamais de « respiration » de mise au point |
| Choix | Sélection | Voir DIALOGUE_UI §3 |

## 4. Son lié aux transitions
Voir la direction sonore ci-dessous. Chaque FADE vers le noir coupe la musique en 300 ms. Le noir est **toujours** accompagné d'une ambiance ou d'un silence voulu, jamais d'un blanc technique.

## 5. Direction sonore (mode Histoire)
- **BEN** :
  - ambiance `ben_hvac` (climatisation) à −32 dB ;
  - `ben_computer_hum` ;
  - néon qui grésille (ponctuel) ;
  - pas sur lino (4 variantes) ;
  - portes (vitrée, pleine) ;
  - papier : page, chemise, tampon ;
  - téléphone fixe lointain.
- **Téléphone** : sons existants (notification, vibration, clavier, appel).
- **Scènes** : une ambiance par décor, en boucle de 60 s sans raccord audible.
  - Tension : une nappe grave (drone) de 55 Hz, entre −28 et −22 dB, uniquement sur des plans désignés.
  - Musique minimale : piano et cordes graves, 3 thèmes au total (BEN, tension, résolution), jamais sous un dialogue au-dessus de −24 dB.
- **Silence narratif** : à 3 moments par scène au plus, toutes les pistes sauf l'ambiance descendent à −60 dB (cloche de volume sur 0,5 s). C'est marqué `silence: true` sur le plan.
- **Mixage** : dialogues à −16 LUFS ; effets entre −20 et −14 dB ; ambiance à −30 dB. Tout respecte le mode silencieux, qui coupe musique et effets mais garde les sous-titres.
