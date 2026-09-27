# STORY_ART_DIRECTION.md — Direction artistique du mode Histoire

## 1. Intention
Le mode Histoire, c'est **le même univers vu de l'intérieur**.
- ENQUÊTES montre le dossier posé sur la table.
- HISTOIRE montre la pièce où se trouve cette table, et les gens autour.

Le ton est celui d'un **thriller policier contemporain, réaliste et retenu** : peu de dialogues, beaucoup de silence, des objets qui parlent.

**Mots-clés** : feutré · administratif · nocturne · précis · humain · fatigué · crédible.
**Mots interdits** : épique · néon · holographique · héroïque · stylisé cartoon · anime · « gamer ».

## 2. Trois couches visuelles, une seule règle de passage

| Couche | Matière | Typo | Lumière |
|---|---|---|---|
| **Papier** (dossiers, fiches, rapports) | Texture, tampons, encre | Newsreader / Plex Mono / Caveat | Chaude, lampe de bureau |
| **3D** (scènes, bureau, personnage) | Réalisme stylisé, matériaux mats | Aucune typo dans le décor, sauf signalétique BEN | Mixte : néon froid + lampe chaude |
| **Téléphone** (enquête) | Interface moderne, plate | SF Pro | Émissive |

**Règle de passage** : on change de couche uniquement par une **transition signature** (TRANSITIONS.md). On ne superpose jamais deux couches, à une exception près : les sous-titres et les choix en papier-sombre par-dessus la 3D.

## 3. Palette de scène
- **Neutres** :

| Rôle | Valeur |
|---|---|
| Murs du BEN | #6B6F73, gris administratif mat |
| Sol | Lino #3A3C3E |
| Bois des bureaux anciens | #5A4330 |
| Métal | #8C9096, brossé mat |

- **Bleu-gris BEN** (#6F7A86) : signalétique, dossiers d'agent, tenues de service. Jamais en lumière.
- **Lumière** :

| Source | Température |
|---|---|
| Néons du couloir et de l'open space | 4 000–4 500 K |
| Lampes de bureau | 2 700–3 000 K |
| Extérieur de nuit | 6 500 K + sodium 2 100 K pour les rues |

- **Rouge** : jamais dans la lumière. Uniquement sur des objets porteurs de sens (voyant d'enregistrement de la salle d'interrogatoire, tampon, scellé).
- **Étalonnage final** :
  - noirs relevés à 4 % (jamais de noir pur dans le rendu) ;
  - saturation globale à −15 % ;
  - teinte des ombres vers #1C2230, teinte des hautes lumières vers #F2E6D2 ;
  - grain de 1,5 %, animé à 24 fps.

## 4. Composition et caméra
- **Format** : portrait 9:19,5, zone de sécurité (safe area) + 28 pt. Le sujet se place dans le tiers supérieur ou central : le tiers inférieur est réservé aux sous-titres.
- **Focales autorisées** (équivalent plein format) : 28 · 35 · 50 · 85 · 100 macro. Rien en dessous de 28 mm, pas de fish-eye.
- **Hauteur de caméra** : 1,45 m pour la hauteur d'œil (par défaut) ; 1,1 m pour les plans de présentation et d'autorité ; plongée uniquement en OBJECT FOCUS.
- **Mouvements** : travellings lents (≤ 8 cm/s), panoramiques ≤ 6°/s, push-in ≤ 15 cm par plan. Jamais de caméra à l'épaule simulée, de dutch angle, de drone ni de tremblement.
- Grammaire complète : STORY_SCENES §2.

## 5. Personnages (résumé ; détail dans NPC_DIRECTION.md)
- **Proportions** : réalistes, 7,5 têtes.
- **Peau** : shader subsurface léger, sans pores visibles au-delà du plan CLOSE.
- **Cheveux** : cartes de cheveux (hair cards) avec anisotropie.
- **Vêtements** : tissus mats, plis modérés, usure légère (col, poignets).
- **Expressions** : amplitude à 60 % d'une expression humaine ; on joue sur les yeux et la mâchoire, jamais de grimace.

## 6. Décors (résumé ; détail dans ENVIRONMENTS.md)
- Architecture administrative française des années 1970, rénovée en 2010 : faux plafonds, stores vénitiens, cloisons vitrées, radiateurs en fonte.
- **Densité d'objets** : un bureau « vécu » compte 25 à 40 props.
- **Signalétique** : BEN, numéros de porte, affiches de sécurité, **toutes fictives**.

## 7. Photographie de référence (pour les artistes)
Directions à rechercher :
- ambiance de bureau de police judiciaire parisienne la nuit ;
- éclairage de série policière nordique ;
- photographie documentaire d'administrations.

À éviter : les références de jeux AAA d'action et les visuels promotionnels à fort contraste.

## 8. Cohérence avec le papier
- **Tout document visible en 3D** (dossier, fiche, rapport) utilise **les mêmes textures** que l'interface 2D (`phase2/assets/textures`, tampons PNG). Ils sont appliqués comme textures sur des maillages plats.
- Un dossier ramassé en 3D doit pouvoir se changer en l'écran 2D équivalent au pixel près (TRANSITIONS T-SIG-1).
