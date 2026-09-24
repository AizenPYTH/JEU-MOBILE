# Écrire une affaire SCREENSHOT

Une affaire est **un seul fichier JSON** dans `ScreenshotKit/Sources/CaseLibrary/Resources/Cases/`
(par ex. `case_002.json`). Le moteur ne change pas : il lit le fichier, et le jeu la propose.

Après chaque modification :

```bash
cd ScreenshotKit && swift run CaseLint && swift test
```

CaseLint signale tout id inconnu, doublon ou incohérence, et vérifie que l'affaire est résolvable
dans son temps. Les tests échouent si une affaire est invalide.

L'affaire #001 est produite par un script (`scripts/cases/gen_case_001.py`) : modifier le script,
puis le relancer — ne pas éditer le JSON à la main :

```bash
python3 scripts/cases/gen_case_001.py ScreenshotKit/Sources/CaseLibrary/Resources/Cases/case_001.json
```

## Structure

```jsonc
{
  "schemaVersion": 1,
  "id": "case_002", "number": 2,
  "title": "…", "tagline": "Une ligne sous le titre.",
  "synopsis": ["Paragraphe 1 du briefing", "…"],
  "objective": "Ce que le joueur doit déterminer.",
  "difficulty": 1,                 // 1 = affaires 1–5, 2 = 6–15, 3 = 16+
  "durationSeconds": 300,          // durée du niveau Détective
  "challengeDurations": { "investigator": 900, "detective": 480, "expert": 300 },  // facultatif
  "introScene": { "shots": [ … ] },                                               // facultatif
  "phoneStartTime": "2026-10-04 09:30",   // heure affichée par le téléphone au début
  "devices": [ { … } ],            // un ou plusieurs téléphones saisis
  "suspects": [ … ], "evidence": [ … ], "hints": [ … ], "solution": { … }
}
```

Toutes les heures s'écrivent `"AAAA-MM-JJ HH:MM"` (heure locale de l'affaire, sans fuseau).
**Tous les ids sont uniques dans le fichier** (messages, photos, appels…), car les preuves et les
indices y font référence.

## Un téléphone (`devices[]`)

| Champ | Contenu |
|---|---|
| `contacts` | Dont le propriétaire : `"id": "me"`, `"isOwner": true`. `avatarHue` (0–1) teinte l'avatar à initiales. |
| `conversations` | `participants` (sans le propriétaire), `messages`, `title` pour un groupe, `draft` (brouillon non envoyé). Un message : `from` (`"me"` = propriétaire), `at`, `text` et/ou `photo`. `deletedAt` = supprimé avant l'enquête → il n'apparaît que dans la Corbeille, jusqu'à récupération. `unread` = non lu. |
| `calls` | `contact`, `direction` (`incoming` / `outgoing` / `missed`), `at`, `durationSeconds`. |
| `places`, `tracks` | Lieux et historiques de position (le propriétaire `"me"` ou un ami qui partage sa position). `sharingStoppedAt` = a coupé le partage. Un lieu a `latitude` + `longitude` (vraie carte, MapKit) et `x`, `y` (0–1, carte stylisée de secours). `revealedBy` (refs `"type:id"`) : le lieu reste absent de la carte tant que le joueur n'a vu aucun de ces éléments (ou ouvert un historique qui y passe) ; sans `revealedBy`, il est connu dès le départ. |
| `photos` | `takenAt` (date des métadonnées), `source` (`camera` / `received` / `screenshot`), `from` + `receivedAt` pour une photo reçue, `place`, `device`, `scene` (ambiance de l'image générée), `caption` (ce qu'on voit), `details` (ce qu'une analyse révèle). `style` (facultatif) : `standard`, `selfie`, `night`, `document`, `screenshot`, `blurry`, `old`, `quick` (cadrage, grain, flou, flash, sépia…). `lines` : le texte lisible sur un document ou une capture. |
| `calendar`, `notes`, `mails`, `browser` | Rendez-vous, notes, e-mails (`inbox` / `sent`, `attachments` = noms des pièces jointes, jamais téléchargées), historique web (`search` / `visit`, `summary` = contenu de la page). |
| `lockedApps` | App protégée par un code (`app`, `code`, `hint`) ; le code doit être déductible ailleurs dans le téléphone. |
| `liveEvents` | Ce qui arrive **pendant** l'enquête, après `afterSeconds` : `message` (dans `conversation`), `call`, `reminder`, `deletion` (quelqu'un supprime un de ses messages → « Ce message a été supprimé »). `title`/`body` = la notification, `opens` = ce qu'elle ouvre. |

Scènes de photo disponibles : `sunset`, `sky`, `rain`, `street_day`, `street_night`, `parking_night`,
`concert`, `bar`, `party`, `group`, `selfie`, `gallery`, `climbing`, `cat`, `books`, `interior_warm`,
`bed`, `station`, `laptop`, `desk_night`, `car`, `park`, `plant`, `document`, `screenshot`, `beach`,
`snow`, `ceiling`, `pocket`, `receipt`, `mirror`, `view`. Une pellicule crédible mélange les années
(photos `old`), des selfies, des photos ratées (`blurry` : poche, plafond), des captures, des tickets.

## Niveaux de défi

Chaque affaire se joue en **Enquêteur** (15 min), **Détective** (8 min) et **Expert** (5 min) : même
scénario, mêmes preuves, seul le temps change. Sans `challengeDurations`, les durées découlent de
`durationSeconds` × les facteurs de `rules.json` (`challenges`). Expert se débloque après une réussite
en Détective. CaseLint vérifie que l'affaire reste résoluble au niveau le plus court.

## Séquence d'ouverture (`introScene`)

Une suite de plans joués avant de rendre le téléphone au joueur (le chrono ne tourne pas pendant ;
« Passer » est toujours possible). Chaque plan : `kind`, `seconds`, `ambience` (sons en boucle :
`street`, `sirens`, `crowd`), `cues` (sons ponctuels `{sound, at}` : `vibrate`, `notification`,
`unlock`, `key`, `sting`), `lines` (`{text, at, speaker?, voiced?}` — `voiced` = lu par la voix du
système).

| `kind` | Plan | Champs propres |
|---|---|---|
| `title` | Écran noir, sons, une ou deux lignes | — |
| `broadcast` | Reportage en direct devant le lieu (caméra à l'épaule, gyrophares, sous-titres) | `channel`, `label` (heure), `location`, `headline`, `ticker`, `scene` (image de fond) |
| `phoneOnTable` | Le téléphone saisi sur une table, l'écran verrouillé s'allume | `label` (étiquette de scellé), `notification` `{app, title, body, at}` |
| `unlock` | Le téléphone est pris en main et déverrouillé : l'écran d'accueil devient celui du jeu | — |

Tous les décalages (`at`) sont relatifs au début du plan et doivent tenir dans sa durée (validé).
La notification de l'écran verrouillé devrait exister dans le téléphone (même personne, même texte).

## Suspects, preuves, indices, solution

- `suspects` : `contact`, `role`, `statement` (déclaration à la police, montrée au briefing),
  `verdict` (texte affiché si le joueur accuse cette personne : pourquoi c'était elle / pourquoi non).
- `evidence` : une information que le joueur doit **voir puis épingler** dans le Carnet (appui long).
  Une preuve n'est « trouvée » que si tout ce qu'elle exige a été vu **et** qu'au moins un de ses
  éléments est épinglé (épingler la photo vaut pour son analyse et inversement).
  - `refs` : références `"type:id"` — `message:`, `draft:`, `call:`, `photo:` (ouverte),
    `photoInfo:` (analysée), `track:`, `calendar:`, `note:`, `mail:`, `browser:`, `contact:`.
  - `anyOf: true` = une seule référence suffit.
  - `importance` : `key` (nécessaire), `supporting` (aide, disculpe), `falseLead` (vraie information
    qui mène sur une fausse piste).
  - `meaning` : ce que ça voulait vraiment dire (révélé à la fin).
- `suspects` (compléments) : `age`, `address`, `alibi` (pourquoi un innocent ne peut pas l'être —
  obligatoire pour un innocent), `alibiEvidence` (id de la preuve qui le montre), `trap` (pourquoi il
  avait l'air coupable).
- `hints` : `text` (oriente sans donner la réponse), `scoreCost` (points retirés, 0 = gratuit),
  `unlockAtRemainingSeconds` (optionnel : disponible seulement quand le chrono est descendu jusque-là).
  Les indices coûtent des points, jamais du temps.
- `solution` : `culprit`, `headline`, `summary` (une phrase), `reveal` (reconstitution pas à pas :
  `at`, `text`, `evidence` = id de la preuve affichée ● trouvée / ○ manquée), `story` (paragraphes).
- `liveEvents[].level` : `normal`, `important` ou `urgent` (bannière inversée qui reste affichée).

## Règles de conception

1. **Du bruit** : au moins 70 % des messages ne sont pas des preuves (vérifié). Conversations banales,
   photos inutiles, recherches normales, rendez-vous ordinaires.
2. **Au moins deux preuves clés** contre le coupable, dans **au moins deux applications différentes**,
   qui ne prennent leur sens qu'une fois croisées.
3. **Au moins une fausse piste** crédible par suspect innocent, et un moyen de la lever.
4. **Jamais d'indice qui conclut** : le jeu ne doit jamais écrire « X ment ».
5. Les événements en direct relancent la pression (dernière minute, contradiction tardive).
6. Difficulté : 1–5 → 4 suspects, peu de données, 5 min (exception : l'affaire #001 dure 8 min, choix du
   brief) ; 6–15 → 6 suspects, plus de contradictions,
   8–10 min ; 16+ → plusieurs téléphones, faux alibis, informations supprimées.
