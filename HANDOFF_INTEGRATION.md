# HANDOFF_INTEGRATION — ce que le code attend du design

Ce document décrit comment le design final (Claude Design) s'intègre au jeu. Objectif : une intégration
**mécanique**, sans toucher à la logique. Il sera enrichi à chaque jalon (écrans et composants ajoutés).

Version : M0 (tokens, conventions d'assets, liste d'ids). Les écrans et composants détaillés arrivent en M2+.

---

## 1. Design tokens

Tous les tokens vivent dans un seul fichier :
`BistroKit/Sources/BistroUI/Theme/DesignTokens.swift`. Aucune vue n'a de valeur en dur.

Merci de livrer les valeurs pour chacun de ces noms (ajouter des tokens est possible, en supprimer demande
une mise à jour du code) :

| Groupe | Tokens attendus |
|---|---|
| Couleurs | `background`, `surface`, `surfaceMuted`, `primary`, `primaryPressed`, `secondary`, `accent`, `adReward`, `textPrimary`, `textSecondary`, `textOnPrimary`, `coins`, `gems`, `success`, `warning`, `danger`, `affinity`, `scrim` |
| Typographie | `display`, `title`, `headline`, `body`, `caption`, `tiny`, `number` (chiffres à chasse fixe) — police, taille, graisse. Si police personnalisée : fichiers .ttf/.otf + licence |
| Espacements | `xxs` 2, `xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24, `xxl` 32 (grille de 4 pt — ajustables) |
| Rayons | `sm`, `md`, `lg`, `pill` |
| Tailles | `minTapTarget` (≥ 44), `iconSm`, `iconMd`, `iconLg`, `ingredientTile`, `portrait`, `buttonHeight` |
| Ombres | `card`, `elevated` (couleur, opacité, flou, décalage x/y) |
| Animations | `fast`, `normal`, `slow`, `celebration` (secondes) + courbes `standard`, `bouncy` |

Format idéal : un tableau (ou JSON) nom → valeur. Couleurs en hex sRGB.

## 2. Composants (à venir en M2)

Chaque composant sera isolé dans `BistroUI/Components/` avec des previews. Liste prévue :
bouton primaire, bouton secondaire, bouton pub récompensée, carte, panneau, jauge (affinité / progression),
badge, popup, barre d'onglets, compteur de monnaie. Pour chacun, merci de fournir : états (normal,
pressé, désactivé), tailles, et éventuelles animations.

## 3. Convention de nommage des assets (stricte)

Le code construit les noms via `AssetName` (`BistroKit/Sources/GameCore/Assets/AssetName.swift`).
**Tout asset manquant s'affiche comme un placeholder** (forme colorée + nom de l'asset) : vous pouvez
livrer progressivement.

| Type | Motif | Exemple |
|---|---|---|
| Ingrédient | `ing_<id>` | `ing_tomato` |
| Plat | `dish_<id>` | `dish_bruschetta` |
| Habitué | `char_<id>_<pose>` — poses : `idle`, `happy`, `sad`, `eating`, `portrait` | `char_margot_portrait` |
| Staff | `staff_<role>_<pose>` — poses : `idle`, `walking`, `carrying`, `cooking` | `staff_waiter_walking` |
| Station | `station_<id>_lv<n>` | `station_stove_lv1` |
| Décoration | `deco_<id>` | `deco_plant_pot` |
| Fond / zone | `bg_<zone>` | `bg_main_hall` |
| Icône d'UI | `ui_icon_<nom>` | `ui_icon_settings` |
| Monnaie | `currency_<coins\|gems>` | `currency_coins` |

Formats : PNG (ou PDF vectoriel pour les icônes), fond transparent, @2x et @3x (ou une image unique
en haute résolution « single scale »), à déposer dans `Bistro/Assets.xcassets` avec **exactement** ces noms.

Tailles de référence (points, provisoires, à confirmer au M2) :

| Type | Taille (pt) |
|---|---|
| Ingrédient, plat | 72 × 72 |
| Portrait d'habitué | 96 × 96 |
| Habitué en scène (poses) | ~64 × 96 |
| Staff | ~64 × 96 |
| Station | ~96 × 96 |
| Icône d'UI | 32 × 32 (et 20 × 20 lisible) |
| Monnaie | 32 × 32 |
| Fond de zone | 390 × 844 (plein écran iPhone portrait) |

Icônes d'UI déjà utilisées par le code : `ui_icon_customer`, `ui_icon_table`.

Icône de l'app : un PNG 1024 × 1024, **opaque (sans transparence)**, à remplacer dans
`Bistro/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (l'actuelle est un placeholder).

## 4. Identifiants de contenu (partagés code ↔ design)

Source de vérité : `BistroKit/Sources/GameData/Resources/Content/*.json`. Un test vérifie que ces ids existent.

- **Ingrédients (12)** : `tomato`, `cheese`, `bread`, `egg`, `rice`, `noodles`, `chicken`, `fish`, `chili`, `basil`, `lemon`, `honey`
- **Stations (4)** : `stove`, `oven`, `cutting_board`, `drinks_bar`
- **Habitués (6)** : `margot`, `tomas`, `mei`, `leon`, `priya`, `oscar`
- **Zones (5)** : `main_hall`, `counter`, `terrace`, `upstairs`, `garden`
- **Plats (8 pour l'instant, ~30 au M3)** : `bruschetta`, `omelette`, `grilled_cheese`, `tomato_soup`, `honey_lemonade`, `chicken_rice`, `spicy_noodles`, `sushi_roll`

Assets attendus pour le MVP (hors UI) : 12 `ing_*`, ~30 `dish_*`, 6 × 5 `char_*`, 4 stations × niveaux,
5 `bg_*`, 2 `currency_*`, staff (serveur + cuisinier) × 4 poses.

## 5. Textes

Les textes ne sont pas dans les maquettes : ils vivent dans `BistroUI/Resources/Localizable.xcstrings`
(anglais par défaut + français). Merci de prévoir des mises en page qui supportent un français ~30 % plus long.

## 6. Écrans (à venir)

Liste complétée au fil des jalons : restaurant (scène + HUD), labo, livre de recettes, menu actif,
carnet des habitués, boutique, écran de retour hors ligne, réglages, tutoriel.
