# CHARACTER_CUSTOMIZATION.md — Création et évolution de l'enquêteur

## 1. Principe
**Une création sobre, sur un nombre fini de combinaisons.** Deux bases 3D (FÉMININE / MASCULINE), puis des options prédéfinies. Pas de curseurs de morphologie : chaque combinaison doit avoir été testée en éclairage de scène.

Total : 2 bases × 6 teints × 6 visages × 6 coiffures × 6 couleurs d'yeux × 8 tenues. Tout est piloté par des *morph targets* et des remplacements de maillages. Aucun maillage n'est généré.

## 2. Étape 1 · IDENTITÉ

| Champ | Règle |
|---|---|
| Prénom | 2–20 caractères. Lettres (accents compris), espace, apostrophe, tiret. Majuscule initiale automatique |
| Nom | Mêmes règles |
| Base | `PLAYER_BASE_FEMALE` / `PLAYER_BASE_MALE`. Détermine le squelette, les proportions et la voix d'annonce du nom (sans voix du joueur en dialogue) |
| Modèle de départ | Élise Morel (F) ou Vincent Delmas (M) : préremplit le nom et l'apparence A de 05_PERSONNAGES |
| Matricule | Généré : `BEN-0` + 4 chiffres aléatoires, unique localement. Non modifiable |
| Accord | Le jeu choisit Enquêteur / Enquêtrice et affecté / affectée selon la base. Réglage « Accord » : féminin, masculin ou neutre (« Agent ») |

**Filtre** : liste locale de grossièretés FR et EN, et des noms des personnages du jeu. Sur refus, afficher le post-it « Nom non valide pour un dossier officiel. »

## 3. Étape 2 · APPARENCE (6 options par catégorie)

| Catégorie | Options | Mise en œuvre |
|---|---|---|
| TEINT | #F1D3BC, #E2B593, #C68E68, #9C6644, #6E4630, #4A2F22 (albédo moyen des joues) | Jeux de textures peau : albédo + rugosité + subsurface. Aucun libellé d'origine affiché : « Teint 1–6 » |
| VISAGE | 6 préréglages par base : ovale, long, carré, rond, anguleux, cœur. Chacun a son nez et sa mâchoire | Morph targets combinés, figés par préréglage |
| CHEVEUX | Coupe × couleur : 6 coupes par base, puis 6 couleurs (noir, brun foncé, châtain, blond foncé, roux cuivré, gris) | Cartes de cheveux (hair cards), un maillage par coupe |
| YEUX | Marron foncé, marron, noisette, vert-gris, gris-bleu, bleu | Texture d'iris |

**Coupes par base**

| Base | Coupes |
|---|---|
| FÉMININE | Queue basse, chignon bas, carré court, mi-longs détachés, tresse basse, courts |
| MASCULINE | Courts dégradés, très courts, mi-longs arrière, ondulés courts, rasé, raie de côté |

**Pilosité** (base masculine, dans VISAGE) : rasé, barbe de 3 jours, barbe courte, moustache.

**Interdits** : maquillage appuyé, piercings, tatouages visibles, couleurs de cheveux non naturelles. Le joueur est un agent en service.

## 4. Étape 3 · TENUE (4 tenues × 2 variantes)

| ID | Tenue | Variantes | Silhouette |
|---|---|---|---|
| OUTFIT_01 | Parka sombre, chemise, pantalon droit | Marine / olive foncé | Terrain |
| OUTFIT_02 | Manteau de laine, col roulé | Anthracite / camel | Classique |
| OUTFIT_03 | Veste de costume sans cravate, chemise ouverte | Gris charbon / bleu nuit | Bureau |
| OUTFIT_04 | Blouson de cuir mat, pull | Noir / brun | Nuit |

**Communs à toutes les tenues**
- Chaussures de ville sombres.
- Carte BEN à la ceinture ou en tour de cou selon la tenue.
- Montre discrète.

Une seule tenue est portée dans toutes les scènes, sauf scènes spéciales (voir §6).

## 5. Étape 4 · CONFIRMATION
- **Portrait** : capture en temps réel du buste 3D, en caméra « S4 » :
  - 85 mm, hauteur 1,55 m, fond #6F7A86 ;
  - lumière principale douce à 30° à gauche + lumière d'appoint (fill) à −2 EV ;
  - sortie 1024 × 1280, puis sépia à 8 % et grain.
- **Stockage** : `player_portrait.jpg` dans Application Support. Il est régénéré à chaque changement d'apparence.
- **Contenu de la feuille** : NOM, MATRICULE, SERVICE BEN, RANG INITIAL ENQUÊTEUR, AFFECTATION UNITÉ ENQUÊTES NUMÉRIQUES.

## 6. Évolution visuelle (liée au rang, non achetable)

| Rang | Condition (les 2 critères sont requis) | Ajout sur le personnage | Bureau |
|---|---|---|---|
| ENQUÊTEUR | Départ | Carte BEN en plastique | OFFICE_01 |
| INSPECTEUR | 1 affaire résolue + chapitre 01 terminé | Carte BEN métal ; la tenue choisie gagne un détail (écharpe ou gants selon la tenue) | OFFICE_02 |
| INSPECTEUR SENIOR | 20 affaires résolues + chapitre 04 | Montre remplacée, porte-document en cuir | OFFICE_03 |
| EXPÉRIMENTÉ | 30 affaires résolues + chapitre 07 | Insigne de revers BEN, légères marques de fatigue (texture) | OFFICE_04 |

⚠ **Seuils de rang** : ces seuils (1 / 20 / 30) remplacent l'échelle 0 / 1 / 2–3 / 4–5 du doc 06. Celle-ci n'était pensée que pour 5 affaires, alors que la carrière s'étend maintenant sur plusieurs chapitres. Tant que le mode Histoire n'est pas livré, l'échelle du doc 06 reste en vigueur.

## 7. Modification ultérieure
- Apparence et tenue sont modifiables à tout moment (h19). Le portrait est alors ré-imprimé et une ligne s'ajoute à l'historique (« Photo de dossier mise à jour »).
- Nom et base ne sont modifiables que par une réinitialisation de l'histoire.

## 8. Données

```
Player {
  firstName, lastName, base: F|M, agreement: F|M|N,
  matricule, skin: 1–6, face: 1–6, facialHair: 0–3,
  hairCut: 1–6, hairColor: 1–6, eyes: 1–6,
  outfit: 1–4, outfitVariant: A|B,
  rank, casesHandled, casesSolved, storyChapter, createdAt,
  history: [{date, type, text}]
}
```

- Stockage local, avec synchronisation iCloud si elle existe déjà.
- Les apparences prédéfinies d'Élise et de Vincent correspondent à des valeurs de cette structure.
