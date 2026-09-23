# HANDOFF_INTEGRATION — état de l'intégration du design

Source : handoff Claude Design v1.0 du 23/09/2026, rangé **sans modification** dans `docs/design/`.
Ouvrir `docs/design/Bistro Handoff.dc.html` dans un navigateur pour la vue d'ensemble.
Direction retenue : **« Riso chaud »**.

Ce document dit ce qui est intégré dans le code, ce qui reste à faire (et à quel jalon), et la
liste des illustrations à commander.

---

## 1. Ce qui est intégré

| Élément | Où dans le code | État |
|---|---|---|
| Tokens couleurs (27), typographies (12), espacements, marges, rayons, bordures, ombres, animations | `BistroKit/Sources/BistroUI/Theme/DesignTokens.swift` | ✅ valeurs exactes du handoff |
| Polices Bricolage Grotesque (400/500/700/800) + IBM Plex Mono (600), licence OFL | `BistroUI/Resources/Fonts/` + `Theme/BistroFonts.swift` | ✅ embarquées, enregistrées au lancement |
| Format des nombres (9 850 · 12,4 k · 45,7 Md / 12.4K · 45.7B) | `GameCore/Formatting/CompactNumber.swift` (+ tests) | ✅ |
| Boutons btn.primary / btn.secondary (normal, pressé, désactivé, en attente, badge, 2 lignes) | `Components/Buttons.swift` | ✅ |
| hud.currency, badge, gauge.progress, carte/panneau, en-tête de sheet | `Components/` | ✅ |
| Barre d'actions 5 entrées (Habitués · Améliorer · **Labo** 78 pt · Menu · Boutique) | `Screens/Main/ActionBar.swift` | ✅ |
| HUD haut : pièces à gauche, réglages à droite | `Screens/Main/HUDView.swift` | ✅ (gemmes au M7, réputation au M5) |
| Écran Menu (5a), version tap pour ajouter/retirer | `Screens/MenuScreen.swift` | 🟡 glisser-déposer + revenu estimé au M3 |
| Réglages (13a), version M1 : version/build, stats, reset debug | `Screens/SettingsScreen.swift` | 🟡 interrupteurs, langue, achats, légal au M8 |
| **Croquis vectoriels comme placeholders améliorés** (73 : ingrédients, plats, habitués × 5 poses, staff, stations × 3 niveaux, 4 décos, marmite) | `BistroUI/Resources/Sketches.xcassets`, régénérables avec `scripts/design/export-sketches.sh` | ✅ tremblement figé à l'export, PNG @2x/@3x |
| Icône d'app : concept B « La marmite » (recommandé) reconstruit en 1024 px opaque | `Bistro/Assets.xcassets/AppIcon.appiconset` | ✅ provisoire (à remplacer par le master final) |
| Noms d'assets alignés sur le handoff | `GameCore/Assets/AssetName.swift` | ✅ zone `main_room`, staff `chef/waiter` × `idle/working/walking`, `bg_story_<id>_<n>`, `ui_<nom>` |

**Ordre de recherche d'une image** (`GameImage`) :
1. `Bistro/Assets.xcassets` : c'est là que vont les **illustrations finales** ;
2. les croquis du handoff ;
3. pour les icônes `ui_icon_*` : un SF Symbol provisoire. Pour les monnaies : la forme du design
   (pièce ronde or, gemme losange vert-de-gris) ;
4. sinon, un placeholder visible (tirets + nom de l'asset).

Une illustration finale déposée avec le bon nom **remplace donc automatiquement** le croquis, sans
toucher au code.

---

## 2. Écrans : quand ils seront construits

Chaque écran sera construit **directement selon les maquettes annotées** du handoff, au jalon où son
système de jeu existe :

| Écran du handoff | Jalon |
|---|---|
| 1 · Principal (scène SpriteKit, caméra, zoom), 1c chargement, 1d jour 1 | M2 |
| 2 · Bulles (commande, spéciale, pourboire, accélérer) | M2 (spéciale : M4) |
| 8 · Améliorations | M2 |
| 3 · Labo + storyboards découverte / échec | M3 |
| 4 · Livre de recettes · 5 · Menu complet (glisser-déposer) | M3 |
| 6 · Carnet · 7 · Fiche habitué · 15b popup palier | M4 |
| 9 · Carte d'expansion · 10 · Hors ligne · 11 · Demande du jour · 15a level up · 15c nouvel ingrédient | M5 |
| 12 · Boutique · btn.rewardedAd · btn.purchase | M7 |
| 13 · Réglages complets · 14 · Tutoriel · haptiques désactivables | M8 |

Composants encore à construire : card.dish, card.regular, gauge.affinity (M3–M4), sheet 50 %
(M2), popup + file d'attente (M3), bubble (M2), tooltip.tutorial (M8), tabs.segmented (M3),
btn.rewardedAd, btn.purchase (M7).

---

## 3. Illustrations à commander (M9)

Règles de livraison (handoff §05) :
- Source SVG.
- **PDF vectoriel** (« Preserve Vector Data ») pour les usages SwiftUI.
- **PNG @2x/@3x** pour les textures SpriteKit, avec le tremblement figé à l'export.
- Noms **exacts** ci-dessous, à déposer dans `Bistro/Assets.xcassets`.

Les croquis du handoff fixent silhouettes, palette et règles. Ce ne sont pas des finaux :
**toutes** les entrées ci-dessous sont à produire par un illustrateur.

| Famille | Noms | Nombre | Croquis dispo | Tailles (pt) · format |
|---|---|---|---|---|
| Ingrédients | `ing_tomato`, `ing_cheese`, `ing_bread`, `ing_egg`, `ing_rice`, `ing_noodles`, `ing_chicken`, `ing_fish`, `ing_chili`, `ing_basil`, `ing_lemon`, `ing_honey` | 12 | ✅ 12 | 48 · 62 · 96 · PDF + PNG |
| Plats existants | `dish_bruschetta`, `dish_omelette`, `dish_sushi_roll`, `dish_spicy_noodles`, `dish_honey_lemonade`, `dish_chicken_rice`, `dish_tomato_soup`, `dish_grilled_cheese` | 8 | ✅ 8 | 34 · 48 · 80 · 176 · PDF + PNG |
| Plats proposés (à valider, voir §4) | `dish_caprese_toast`, `dish_cheese_omelette`, `dish_egg_fried_rice`, `dish_lemon_fish`, `dish_fish_rice_bowl`, `dish_basil_pesto_noodles`, `dish_honey_chicken`, `dish_spicy_chicken_rice`, `dish_tomato_noodles`, `dish_cheese_toast`, `dish_egg_soup`, `dish_fish_soup`, `dish_chili_honey_wings`, `dish_lemon_tart`, `dish_honey_toast`, `dish_basil_lemonade`, `dish_rice_pudding`, `dish_chili_cheese_bites`, `dish_herb_chicken`, `dish_fish_tacos`, `dish_egg_sandwich`, `dish_french_toast` | 22 | ❌ | idem |
| Habitués (scène, rig par parties : tête, corps, bras G/D, jambes) | `char_<id>_idle/happy/sad/eating` pour margot, tomas, mei, leon, priya, oscar | 24 | ✅ 24 | 60 (scène) · 200 (fiche) · PNG par parties |
| Portraits | `char_<id>_portrait` × 6 | 6 | ✅ 6 | 32 · 40 · 60 · 120 · PDF |
| Staff (calques de tenue ; marche en 8 images) | `staff_chef_idle/working/walking`, `staff_waiter_idle/working/walking` | 6 | ✅ 6 | 60 · PNG par parties |
| Stations | `station_{stove,oven,cutting_board,drinks_bar}_lv{1,2,3}` | 12 | ✅ 12 | 70 (liste) · 120–160 (scène) · PNG + PDF |
| Décorations | `deco_plant_pothos`, `deco_lamp_pendant`, `deco_chalkboard`, `deco_frame_photo` | 4 | ✅ 4 | 48–120 · PNG + PDF |
| Décorations | `deco_awning_striped`, `deco_stool_wood`, `deco_table_round`, `deco_table_square`, `deco_shelf_jars`, `deco_rug_kilim`, `deco_radio_vintage`, `deco_bell_counter` | 8 | ❌ | idem |
| Fonds de zone (calques mur / sol / lumière) | `bg_main_room`, `bg_counter`, `bg_terrace`, `bg_upstairs`, `bg_garden` | 5 | ❌ | 390 × 844, panoramique ×1,5 · PNG |
| Illustrations d'histoires | `bg_story_<id>_<1…5>` × 6 habitués | 30 | ❌ | 342 × 220 · PNG |
| Écran de chargement | `bg_splash` | 1 | ❌ | 390 × 844 · PDF |
| Icônes d'interface (template 2 tons) | `ui_icon_` + lab, book, upgrade, menu, shop, settings, close, back, lock, video, check, heart, star, clock, map, gift, calendar, sound, music, vibration, globe, restore, shield, info, hint, grip, plus, people, table, flame, sparkle, x2 | 32 | ❌ (SF Symbols en attendant) | 16 · 20 · 24 · 30 · PDF |
| Icônes utilisées par le code, absentes du handoff | `ui_icon_customer` | 1 | ❌ | idem |
| Labo | `ui_lab_pot` | 1 | ✅ | 150 × 128 · PNG |
| Labo | `ui_lab_pot_open` | 1 | ❌ | idem |
| Bulles (9-slice) | `ui_bubble_order`, `ui_bubble_special`, `ui_bubble_tip`, `ui_bubble_boost` | 4 | ❌ | h 38–50 · PDF |
| Monnaies | `currency_coins`, `currency_gems` | 2 | ❌ (formes dessinées en code) | 11–40 · PDF (+ PNG particules pour les pièces) |
| Icône d'app | `app_icon_marmite` → `AppIcon` | 1 | 🟡 reconstruite depuis le concept B | 1024 · PNG opaque |

Total : **180 fichiers** à produire, dont 73 ont déjà un croquis utilisé en attendant.
Les 146 entrées du tableau du handoff regroupent certaines lignes (par exemple les 30 illustrations
d'histoires, sur une seule ligne `bg_story__`). Le tableau ci-dessus les détaille et ajoute ce
dont le code a besoin : `ui_icon_customer`, les monnaies et l'icône d'app.

---

## 4. Écarts et informations manquantes (à trancher, je n'ai pas improvisé)

**Contradictions avec le brief initial ou le moteur**

1. **Pourboires et paiement.** Le design fait payer le plat automatiquement et ne laisse que le
   *pourboire* à toucher, récolté seul après **60 s**. Le moteur M1 laisse *prix + pourboire* sur la
   table, récoltés seuls après 20 s, et **la table reste bloquée tant que ce n'est pas récolté**. →
   Faut-il suivre le design ? (Changement moteur au M2 ; le délai de 60 s est un simple réglage JSON.)
2. **Accélérer une station.** Le brief prévoit de *taper sur la station* pour accélérer. Le design
   propose une bulle « Accélérer », seulement si la préparation dure plus de 20 s : pub ×2 ou
   5 gemmes, une pub par station toutes les 10 min. → Garder les deux (taper = petit gain,
   bulle = gros gain) ou seulement la bulle ?
3. **Tutoriel, étape 1** : « Touche une commande pour servir ». Or le design dit aussi que « le
   service est automatique ; toucher [une commande] affiche simplement l'info ». → Que fait le
   toucher pendant le tutoriel ?
4. **Coût des essais au labo.** Le brief demande un coût en pièces ou des tentatives rechargeables
   (configurable). Le design recommande des essais **gratuits**, ingrédients non consommés. → Je
   rends les deux possibles dans `lab.json` ; quelle valeur par défaut ?
5. **3e ingrédient au labo.** Le design affiche l'emplacement 3 (« opt. ») dès le début. Le brief le
   débloque plus tard. → Réglable ; à partir de quel niveau ?
6. **Carte du fidèle.** Le brief parle d'un *achat unique*. Le design montre un **abonnement**
   (4,99 €/mois, 20 gemmes/jour). → À décider avant M7 (l'abonnement impose des textes légaux).
7. **Hors ligne.** Le brief prévoit un plafond de 2 h, améliorable jusqu'à 8 h. L'écran 10 affiche
   « 8 h maximum ». → Je garde 2 h → 8 h et le texte affichera le plafond réel.
8. **Série avec jour de repos** (proposition du design). → À valider.

**Données manquantes dans le modèle de contenu** (ajout au M3, pas bloquant)

9. **Type de plat** (Entrée, Plat, Bol, Boisson, Dessert) pour les filtres du livre et la
   silhouette-contenant. Nos catégories actuelles sont des goûts (sucré, épicé…). → J'ajouterai un
   champ `course` dans `recipes.json`.
10. **Rareté** (commun, rare, raffiné, légendaire) : champ `rarity` à ajouter.
11. **Les 22 plats proposés** : ingrédients, station, prix et temps non définis. Je les proposerai au
    M3 (table des combinaisons).
12. **Couleur signature de chaque habitué** (en-tête de fiche) : nommée mais sans valeur hex. Je
    peux la déduire des croquis ; à confirmer au M4.
13. **Âge, métier, jour de passage, textes d'histoire** : seuls ceux de Margot sont esquissés.
    → Rédacteur (le handoff demande une traduction humaine, pas automatique).
14. **Accès au Livre de recettes** : il n'est pas dans la barre d'actions. → Depuis le Labo et le
    Menu (proposition).
15. **Oscar en réputation 8** : à confirmer (M4).

**Petites incohérences internes au handoff**

16. hud.currency : h 36 dans le tableau du handoff, h 38 dans le design system. → J'ai pris **38**.
17. Barre d'actions : le design la décrit comme une barre d'*actions* au-dessus de la scène. Je l'ai
    implémentée ainsi (chaque entrée ouvre sa page en sheet à 92 %), pas comme des onglets qui
    remplacent la scène.

---

## 5. Procédure d'intégration des illustrations finales (M9)

1. Déposer les fichiers dans `Bistro/Assets.xcassets`, en respectant exactement les noms du §3.
   PDF : cocher « Preserve Vector Data ».
2. Rien d'autre à faire côté code : `GameImage` les préfère automatiquement aux croquis.
3. Les personnages et le staff « par parties » (rig SpriteKit) demanderont une petite intégration
   dédiée dans la scène : noms des parties à convenir avec l'illustrateur.
4. Quand tout est livré, on pourra supprimer `Sketches.xcassets` (5,5 Mo) pour alléger l'app.
