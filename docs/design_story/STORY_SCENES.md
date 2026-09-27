# STORY_SCENES.md — Grammaire des scènes et scènes du chapitre 01

## 1. Principes
- **Scènes courtes** : 1 à 3 min, 8 à 25 plans. Pas plus de 3 personnages à l'écran.
- **Une scène = un lieu.** Les changements de lieu se font entre les scènes.
- **Le silence est une réplique.** Chaque scène comporte au moins un plan muet de 2 à 4 s (ambiance seule).
- **Le joueur ne parle qu'à travers ses choix.** Il n'a pas de voix enregistrée : ses répliques s'affichent en sous-titre, avec son nom.
- **Les choix changent le ton et la mémoire des personnages** (flags `remembered`), **jamais la solution d'une affaire.**

## 2. Grammaire des plans

| Plan | Focale | Cadrage | Usage | Durée type |
|---|---|---|---|---|
| WIDE | 28–35 mm | Personnages ≤ 1/3 de la hauteur | Ouvrir une scène, entrée ou sortie | 3–5 s |
| MEDIUM | 50 mm | Taille → tête | Dialogue par défaut | Longueur de la réplique |
| CLOSE | 85 mm | Épaules → tête | Réplique importante, réaction, silence | 2–4 s |
| OVER SHOULDER | 50 mm | Épaule du joueur en amorce floue | Échange joueur ↔ PNJ, choix | Longueur de la réplique |
| OBJECT FOCUS | 100 mm macro | Objet net, arrière-plan flou | Pièce, dossier, téléphone ; précède une transition | 2–3 s |

**Règles**
- Règle des 180° respectée.
- Au plus 2 CLOSE consécutifs.
- Toujours un WIDE en ouverture.
- OBJECT FOCUS obligatoire avant une transition vers le téléphone.

**Transitions entre plans**

| Transition | Durée | Usage |
|---|---|---|
| CUT | — | Par défaut |
| DISSOLVE | 0,6 s | Ellipse temporelle dans le même lieu |
| FADE (noir) | 0,4 s + 0,3 s de noir + 0,6 s | Changement de scène |

Rien d'autre.

## 3. Format d'une scène (données)

```
Scene {
  id: "S01-01", chapter: 1, location: ENV_BEN_OFFICE_LACAZE,
  cast: [NPC_LACAZE, PLAYER], ambience: "ben_office_night",
  shots: [
    { id, type: WIDE|MEDIUM|CLOSE|OS|OBJ, camera: "cam_lacaze_ms",
      subject, anim: {NPC_LACAZE: "sit_idle"}, line?: lineId,
      duration?: s (si pas de réplique), transitionIn: CUT|DISSOLVE|FADE, keyframe?: bool }
  ],
  choices: [{ afterShot, options: [{text, flag, reply}] , silence: {flag, reply} }],
  exit: { type: PHONE|CASE_FOLDER|SCENE|CHAPTER_END, target }
}
```

- Les caméras sont des objets nommés placés dans le décor (`cam_*`), jamais calculées à la volée.
- `keyframe: true` marque un point de reprise.

## 4. Reprise et relecture
- **Reprise** au dernier `keyframe` (1 tous les 4 à 6 plans).
- **« PASSER »** : n'apparaît que pour une scène déjà vue. Il passe directement à la sortie en conservant les choix précédents.
- **JOURNAL** : toutes les répliques de la scène en texte (DIALOGUE_UI §5).

## 5. Chapitre 01, « Première affectation »
Ce chapitre remplace la cinématique de recrutement de 06 §5 pour les joueurs en mode Histoire. Il réutilise les mêmes plans, mais en 3D temps réel.

**S01-01 · Arrivée au BEN** (≈ 70 s) · lieu ENV_BEN_CORRIDOR → ENV_BEN_OFFICE_LACAZE

| # | Plan | Contenu | Réplique / son |
|---|---|---|---|
| 1 | WIDE | Hall du BEN, 21 h, le joueur entre de dos | Pas, climatisation, porte |
| 2 | MEDIUM (dos) | Couloir, travelling derrière le joueur à 6 cm/s | Néon qui grésille, téléphone lointain |
| 3 | WIDE | Porte ouverte, Lacaze lit à son bureau | Silence (3 s) |
| 4 | MEDIUM | Lacaze, sans lever les yeux | « {Nom}. Fermez la porte. » |
| 5 | OS | Le joueur s'assoit (anim `sit`) | Chaise |
| 6 | CLOSE | Lacaze feuillette le dossier d'agent | « Douze ans de terrain. Vous êtes là parce qu'on me l'a demandé. » (texte selon la base ou le modèle) |
| 7 | Choix | A « Et vous, vous l'auriez demandé ? » · B « Je ferai le travail. » · — silence | Flags `c01_defiant`, `c01_dutiful`, `c01_silent` |
| 8 | CLOSE | Réaction de Lacaze (3 variantes) | A « Pas encore. » · B « On verra. » · — il lève les yeux, 2 s |
| 9 | MEDIUM | Il sort une chemise kraft du tiroir | Tiroir |
| 10 | OBJECT FOCUS | Chemise posée, « N° 001 » | « Marseille. Un homme de vingt-six ans. » |
| 11 | OBJECT FOCUS | Sachet de scellé et téléphone posés sur la chemise | « Son téléphone a été retrouvé ce matin. À vous. » |
| → | Sortie | T-SIG-1 vers le téléphone (dossier #001) | — |

**S01-02 · Retour** (≈ 50 s) · après le rapport de #001 · ENV_BEN_OFFICE_LACAZE

| # | Plan | Contenu |
|---|---|---|
| 1 | FADE IN · WIDE | Même bureau, lumière de fin de nuit |
| 2 | MEDIUM | Lacaze lit le rapport (feuille 2D identique à l'écran 11 du final) |
| 3 | CLOSE | Résolu : « Bien. » ; non résolu : « Ça arrive. Pas deux fois. » |
| 4 | OS | Il tend la carte BEN |
| 5 | OBJECT FOCUS | Carte avec le nom et le matricule du joueur (texture générée) |
| 6 | MEDIUM | « Votre bureau est au bout du couloir. » |
| → | FADE → h16, puis h17 et h18 (récompense : OFFICE_01 débloqué, objet « Carte BEN ») |

**S01-03 · Mon bureau** (≈ 30 s, jouable une fois) · ENV_BEN_OFFICE_PLAYER niveau 01
WIDE d'entrée → le joueur pose ses affaires → OBJECT FOCUS sur le téléphone fixe qui sonne → fondu vers h09 (hotspots actifs).

## 6. Durées de référence

| Élément | Durée |
|---|---|
| Réplique | 1,2 s + 45 ms par caractère (avance automatique) |
| Plan muet | 2–4 s |
| Scène | 60–180 s |
| Chapitre | 3 à 6 scènes + 1 à 3 affaires, 25 à 45 min au total |
