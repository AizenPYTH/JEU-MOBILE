# Écrire une affaire SCREENSHOT

Une affaire est **un seul fichier JSON** dans `ScreenshotKit/Sources/CaseLibrary/Resources/Cases/`
(par ex. `case_002.json`). Le moteur ne change pas : il lit le fichier, et le jeu la propose.

Après chaque modification :

```bash
cd ScreenshotKit && swift run CaseLint && swift test
```

CaseLint signale tout id inconnu, doublon ou incohérence, et vérifie que l'affaire est résolvable
dans son temps. Les tests échouent si une affaire est invalide.

## Structure

```jsonc
{
  "schemaVersion": 1,
  "id": "case_002", "number": 2,
  "title": "…", "tagline": "Une ligne sous le titre.",
  "synopsis": ["Paragraphe 1 du briefing", "…"],
  "objective": "Ce que le joueur doit déterminer.",
  "difficulty": 1,                 // 1 = affaires 1–5, 2 = 6–15, 3 = 16+
  "durationSeconds": 300,          // 5 min (1–5), 8–10 min (6–15)
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
| `places`, `tracks` | Lieux sur la carte stylisée (`x`, `y` entre 0 et 1) et historiques de position (le propriétaire `"me"` ou un ami qui partage sa position). `sharingStoppedAt` = a coupé le partage. |
| `photos` | `takenAt` (date des métadonnées), `source` (`camera` / `received` / `screenshot`), `from` + `receivedAt` pour une photo reçue, `place`, `device`, `scene` (ambiance de l'image générée), `caption` (ce qu'on voit), `details` (ce qu'une analyse révèle). |
| `calendar`, `notes`, `mails`, `browser` | Rendez-vous, notes, e-mails (`inbox` / `sent`), historique web (`search` / `visit`, `summary` = contenu de la page). |
| `lockedApps` | App protégée par un code (`app`, `code`, `hint`) ; le code doit être déductible ailleurs dans le téléphone. |
| `liveEvents` | Ce qui arrive **pendant** l'enquête, après `afterSeconds` : `message` (dans `conversation`), `call`, `reminder`, `deletion` (quelqu'un supprime un de ses messages → « Ce message a été supprimé »). `title`/`body` = la notification, `opens` = ce qu'elle ouvre. |

Scènes de photo disponibles : `sunset`, `sky`, `rain`, `street_day`, `street_night`, `parking_night`,
`concert`, `bar`, `party`, `group`, `selfie`, `gallery`, `climbing`, `cat`, `books`, `interior_warm`,
`bed`, `station`, `laptop`, `desk_night`, `car`, `park`, `plant`, `document`, `screenshot`.

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
6. Difficulté : 1–5 → 4 suspects, peu de données, 5 min ; 6–15 → 6 suspects, plus de contradictions,
   8–10 min ; 16+ → plusieurs téléphones, faux alibis, informations supprimées.
