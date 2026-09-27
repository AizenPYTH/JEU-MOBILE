# Pipeline photo — CONCLUDE : ENQUÊTES

Objectif : passer de « il nous faut 200 photos » à « un catalogue de 30 à 60 sources, quelques preuves sur mesure, et
le pipeline fait le reste ». Les photos sont **préparées avant le build et embarquées dans l'app** : le jeu ne contacte
jamais Pexels ni Openverse, il se joue hors ligne.

## Architecture

```
case_00N.json ─┐
               ├─ audit ──▶ config/photo_catalog.json   (1 décision par photo, sources partagées)
config/photo_pipeline.json ┘        │
                                    ├─ search ───▶ cache/photos/search/…   (Pexels puis Openverse, résultats en cache)
                                    │               cache/photos/selection.json (candidats classés par score)
                                    ├─ download ─▶ cache/photos/originals/… (+ contrôle de luminosité jour / nuit)
                                    │               config/photo_sources.json  (manifeste = provenance + verrou)
                                    ├─ process ──▶ Art.xcassets/Photos/caseNNN_photo_<id>.imageset (recadrage, JPEG)
                                    ├─ validate ─▶ contrôles (fichiers, tailles, licences, doublons, clé d'API)
                                    └─ report ───▶ docs/photo_pipeline/PHOTO_AUDIT.md, PHOTO_SOURCES.md,
                                                   ScreenshotUI/Resources/PhotoCredits.json (crédits dans le jeu)
```

| Fichier | Rôle | Modifié par |
|---|---|---|
| `config/photo_pipeline.json` | Fournisseurs, profil de sortie, modèles de requêtes par scène, contexte de chaque affaire (ville), requêtes particulières (`overrides`), exclusions (`audit.forceCustom`), critères de sélection | la main |
| `config/photo_catalog.json` | Une entrée par photo du jeu (décision, raison, source, variante) et les sources partagées | `audit` (une entrée `"manual": true` est conservée telle quelle) |
| `config/photo_sources.json` | Manifeste : pour chaque image téléchargée, fournisseur, id, auteur, licence, URLs, requête, date, score, luminosité, empreinte ; pour chaque image du jeu, sa source et sa transformation. Sert aussi de **verrou** : une source récupérée n'est plus recherchée | le pipeline |
| `cache/photos/` (hors git) | Réponses des API, images originales | le pipeline |
| `Art.xcassets/Photos/` | Les images livrées dans le jeu (`caseNNN_photo_<id>`) | `process` uniquement |
| `ScreenshotUI/Resources/PhotoCredits.json` | Crédits affichés dans Paramètres › À propos › Crédits photos | `report` |

## Commandes

```bash
./scripts/photos.sh audit        # classe les 212 photos, écrit le catalogue et PHOTO_AUDIT.md
./scripts/photos.sh search       # cherche des candidats pour chaque source pas encore récupérée
./scripts/photos.sh download     # télécharge le meilleur candidat, vérifie jour/nuit, l'inscrit au manifeste
./scripts/photos.sh process      # recadre, redimensionne, compresse, écrit les .imageset
./scripts/photos.sh validate     # contrôles (code de sortie ≠ 0 si un problème)
./scripts/photos.sh report       # PHOTO_SOURCES.md + crédits du jeu
./scripts/photos.sh status       # combien à récupérer / récupérées / validées / rejetées / sur mesure, requêtes API
./scripts/photos.sh all          # tout, dans l'ordre
./scripts/photos.sh all --dry-run   # affiche recherches et choix, n'écrit que reports/photo_pipeline_dry_run.md
./scripts/photos.sh all --offline   # n'utilise que le cache (aucun appel réseau)
python3 scripts/photos/test_pipeline.py   # tests hors ligne du pipeline
```

Aucune commande n'est interactive. `--dry-run` n'écrit ni image, ni manifeste, ni cache d'originaux.

**Où le lancer.** Le conteneur de développement n'a pas accès à `api.pexels.com` ni `api.openverse.org`. Le
workflow GitHub **`photo-pipeline.yml`** le fait : il se lance à chaque modification de `config/photo_*.json` ou
de `scripts/photos/`, ou à la main (Actions › Photo pipeline › Run workflow, option « dry run »). Il exécute les tests,
puis `all`, et commite les images, le manifeste, les crédits et les rapports sur la même branche. Le cache
(`cache/photos`) est conservé entre deux exécutions par `actions/cache`.

## Fournisseurs

1. **Pexels** (principal) — API officielle `GET https://api.pexels.com/v1/search`, en-tête `Authorization`,
   paramètres `query`, `orientation=landscape`, `per_page=30`. Image téléchargée : `src.large2x`. Licence Pexels
   (usage gratuit, modification autorisée, attribution appréciée ; l'API demande un lien vers Pexels et le nom du
   photographe quand c'est possible). La clé est lue dans la variable **`PEXELS_API_KEY`** (secret GitHub du même
   nom) ; **jamais** dans le dépôt ni dans l'app. Sans clé, Pexels est simplement ignoré.
2. **Openverse** (secours) — API officielle `GET https://api.openverse.org/v1/images/`, accès anonyme, filtres
   `license_type=commercial,modification`, `mature=false`, `size=large`, `aspect_ratio=wide`. Seules les licences
   **CC0, PDM, CC BY, CC BY-SA** sont acceptées (usage commercial + modification, puisque l'image est recadrée).
   Une image sans page source, sans URL de licence, ou sans auteur alors que la licence exige l'attribution, est
   **rejetée**. Les métadonnées de licence sont conservées telles quelles dans le manifeste.
3. Si aucun fournisseur ne donne d'image acceptable : la photo garde son **rendu procédural** (dessiné par le jeu) et
   la source est marquée `missing` dans le manifeste et dans `PHOTO_SOURCES.md`.

Ordre de repli pour chaque source : requête principale → requêtes alternatives → autre fournisseur → rendu existant
→ `missing`. Une source introuvable n'arrête jamais le reste du pipeline.

**Limites et erreurs.** Délai minimal entre deux appels (Pexels 1 s, Openverse 4 s), trois tentatives avec attente
croissante, respect de `Retry-After` sur 429. Un 429 persistant, un 401/403 ou un réseau indisponible désactive le
fournisseur pour l'exécution en cours ; les sources restantes seront reprises à la suivante (le cache et le
manifeste évitent de refaire ce qui est fait). Pagination : la première page (30 résultats Pexels, 20 Openverse) et
jusqu'à 3 requêtes par source suffisent en pratique ; au-delà, la source passe en `missing` plutôt que d'épuiser le
quota.

## Catalogue et décisions (audit)

Chaque photo des affaires reçoit une décision (`docs/photo_pipeline/PHOTO_AUDIT.md`) :

| Décision | Règle |
|---|---|
| `CUSTOM_REQUIRED` | photo citée par une preuve (`evidence.refs` `photo:`/`photoInfo:`) ; personne de l'affaire à l'image (selfie, groupe, miroir, prénom d'un contact, « silhouette », « enfant »…) ; texte, écran ou marque précis décrit (« », affiche, panneau, écran, plaque…) ; exclusions manuelles `audit.forceCustom` (détails utiles à l'enquête repérés à la relecture). Le rendu procédural reste en attendant une image sur mesure |
| `PROCEDURAL` | capture d'écran, document, ticket (texte exact généré par le jeu), photo ratée (poche, plafond) |
| `REPLACE_BY_API` | photo d'ambiance sans rôle dans le raisonnement |
| `DUPLICATE` | même scène et même légende qu'une autre photo de l'affaire : même source, autre cadrage |
| `KEEP` / `UNUSED` | image réelle existante conservée / photo jamais affichée (aucune aujourd'hui) |

**Règle des preuves** : une preuve n'est **jamais** remplacée par une photo de banque d'images (le pipeline le
vérifie, les tests aussi). **Les affaires ne sont pas modifiées** : c'est la photo qui s'adapte aux données.

**Sources partagées.** Les photos d'ambiance d'une même affaire qui ont la même requête (même lieu, même type de
vue) partagent une source ; une source sert au plus 3 photos (`selection.photosPerSource`), chacune avec un cadrage
différent (voir « Variantes »). Les requêtes viennent du modèle de la scène (`scenes`, avec `{city}` remplacé par la
ville de l'affaire) ou d'une requête particulière (`overrides`, clé `NNN/<photoId>`). Deux photos d'un même lieu
(la salle 2 du Pavillon vide puis avec les vitrines, le Silo avant la soirée…) reçoivent la même requête exprès.

**Nuit.** Une photo est « de nuit » si son style est `night`, si sa scène est nocturne, ou si c'est une scène
d'extérieur prise entre 21 h et 6 h (sauf ciels et couchers de soleil). Les requêtes de nuit le disent, le score
favorise les mots et couleurs moyennes sombres, et **après téléchargement la luminance moyenne réelle est mesurée** :
une image trop claire (> 95/255) est rejetée pour une scène d'extérieur de nuit, une image trop sombre (< 45) pour
une photo de jour.

## Sélection (score)

Pour chaque candidat : correspondance des mots de la requête avec le titre/alt/tags (+3 max), résolution (rejet sous
1200 × 800, bonus au-delà de 1,5 ×), orientation paysage (+1,5, portrait −2), écart au format 4:3, présence de
personnes (−3 : « person, woman, face, portrait, child… »), marques et textes (−2 : « logo, brand, billboard, sign… »),
mots exclus (rejet : « watermark, logo, weapon… »), contenu signalé sensible (rejet), cohérence jour/nuit (mots et
couleur moyenne), léger bonus Pexels. Seuil minimal 1,0 ; le meilleur score gagne ; une même image n'est jamais
utilisée par deux sources. Les critères sont dans `config/photo_pipeline.json › selection`.

Limites assumées (sans dépendance lourde) : pas de détection de visages ni de filigranes dans les pixels ; le filtre
se fonde sur les métadonnées des fournisseurs, la luminance et l'exclusion des scènes à personnes dès l'audit.

## Traitement

Profil unique **`phone-photo` : 1024 × 768 JPEG (qualité 76, progressif, sans EXIF)**, choisi à partir des vues
réelles : détail Photos en 4:3 pleine largeur (≈ 390 pt), bulle de message 200 × 150 pt, grille carrée ≈ 130 pt
(recadrée au centre à l'affichage), pièce du Carnet ≤ 200 pt de haut, feuille de versement 78 pt. iOS réduit l'image
pour les petites vues : un seul fichier par photo suffit. ≈ 100–150 Ko par image.

**Recadrage intelligent** : la fenêtre 4:3 est placée là où l'image a le plus de détails (énergie des contours
calculée sur une réduction de l'image), avec une légère attraction vers le centre, et verticalement entre 15 % et
85 % de la hauteur pour garder l'horizon. Déterministe : la même source donne toujours le même résultat.

**Variantes** (photos d'ambiance uniquement) : variante 1 = meilleur cadrage plein cadre ; variante 2 = zoom ×1,2 dans
la moitié gauche ; variante 3 = zoom ×1,2 dans la moitié droite. Aucune retouche qui inventerait un détail ; les
effets de style du jeu (nuit, flou, vieille photo, bougé, flash de selfie) restent appliqués à l'affichage par
`GeneratedPhoto`, comme pour les photos dessinées.

## Attribution

- Dans le jeu : **Paramètres › À propos › Crédits photos** : « Photos fournies par Pexels » (lien vers pexels.com)
  quand au moins une image Pexels est livrée, puis une ligne par image : « Photo by X on Pexels » ou « « titre » by X,
  CC BY 4.0 », avec les liens vers la page source et la licence. Hors du jeu, jamais pendant l'enquête.
- Dans le dépôt : `docs/photo_pipeline/PHOTO_SOURCES.md` (tableau lisible) et `config/photo_sources.json` (tout).

## Validation

`validate` (et les tests `PhotoPipelineTests` côté Swift, `test_pipeline.py` côté Python) vérifie : catalogue
complet (chaque photo des affaires une fois, décisions connues), aucune source sans requête, aucune preuve issue d'une
banque d'images, provenance complète de chaque image (fournisseur, id, page, licence, URL de licence, requête, date,
texte d'attribution), licences Openverse autorisées, fichiers présents au bon format (JPEG 1024 × 768), aucun
doublon exact, aucune image orpheline dans `Art.xcassets/Photos`, crédits du jeu à jour, **aucune clé d'API dans le
dépôt**, **aucun appel à une API photo dans le code du jeu** (pas de `URLSession`).

## Ajouter une affaire

1. Écrire l'affaire (`case_00N.json`, voir `docs/CASE_AUTHORING.md`).
2. Dans `config/photo_pipeline.json › cases`, ajouter `"00N": {"city": "…", "region": "…", "extraPeople": [...]}`
   (prénoms qui apparaissent dans les légendes sans être des contacts).
3. Au besoin, des requêtes particulières dans `overrides` (`"00N/p_id": {"query": "…", "fallbacks": ["…"]}`) —
   donner la même requête à deux photos d'un même lieu pour qu'elles partagent une source.
4. Pousser : le workflow fait le reste. Relire `PHOTO_AUDIT.md` (décisions) et `PHOTO_SOURCES.md` (images choisies).
   Une image refusée à la relecture : ajouter `"fournisseur:id"` à `selection.excluded` (ou la photo à
   `audit.forceCustom`, ou changer sa requête), puis supprimer l'entrée de sa source dans
   `config/photo_sources.json › sources` : elle sera recherchée à nouveau sans jamais reprendre l'image refusée.
