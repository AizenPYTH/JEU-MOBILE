# Mode ALIBI — « VÉRIFIER. CROISER. CONCLURE. »

Second mode de CONCLUDE : ENQUÊTES, à côté des enquêtes (le cœur du jeu). Même univers, même BEN, même téléphone, même
Carnet, mêmes gestes ; une partie plus courte et plus simple.

> Une personne affirme avoir été à un endroit précis à une heure précise. Le joueur fouille son téléphone et décide :
> **ALIBI CONFIRMÉ** ou **ALIBI CONTREDIT**.

## Boucle

```
DOSSIER → AFFIRMATION → EXPLORER → CROISER LES INDICES → VÉRIFIER → VERDICT
```

- 3 à 6 minutes par partie (niveau Détective ; « Temps détendu » s'applique aussi).
- 1 personne, 1 affirmation, 3 à 5 indices vraiment utiles, quelques éléments secondaires, 1 ou 2 fausses pistes
  légères, 1 conclusion claire. Pas de liste de suspects, pas de réseau compliqué.

## Parcours à l'écran

| Écran | Contenu | Action unique |
|---|---|---|
| **Bureau** | sous les dossiers d'enquête, section « Autre mode » : carte papier ALIBI (titre, « VÉRIFIER. CROISER. CONCLURE. », « Vérifiez une déclaration à partir des traces laissées sur un téléphone. », avancement) — visible sans voler la vedette : le bouton plein du Bureau reste celui de l'enquête | toucher la carte |
| **ALIBI** (liste) | les vérifications en fiches (ALIBI #001…, titre, accroche, durée, difficulté ●○○, état NOUVEAU / EN COURS / VÉRIFIÉ / À REPRENDRE) | [COMMENCER] (la suivante) ou [REPRENDRE] |
| **Mini-dossier** | ALIBI #00N · catégorie, titre, ville ; **Déclarant** ; l'affirmation citée ; **Lieu déclaré** ; **Créneau** ; OBJECTIF ; 2–3 lignes de contexte ; « 1. Explorez son téléphone… 2. Versez au dossier… 3. Rendez votre verdict. » ; temps | [COMMENCER] |
| **Ouverture** | la même que les enquêtes (sachet de scellé → écran verrouillé) | déverrouiller |
| **Téléphone** | identique au mode principal : apps, notifications en direct, coût en temps des actions, appui long 0,4 s → « Verser au dossier » | explorer, verser |
| **Carnet** | onglets PIÈCES · DÉCLARATION · CHRONOLOGIE. En tête des pièces : la déclaration à vérifier et la prochaine étape. Sur chaque pièce : [▲ CONTREDIT] / [▼ CONFIRME] (une seule personne : pas de choix de suspect). Onglet DÉCLARATION : l'affirmation, le lieu, le créneau, le décompte ▲/▼ du joueur. Indices : l'ampoule, comme partout | [CONCLURE L'ENQUÊTE] |
| **Verdict** | « SON ALIBI EST-IL FIABLE ? » ; rappel de l'affirmation et du décompte ; deux fiches [ALIBI CONFIRMÉ] / [ALIBI CONTREDIT] | maintenir 1,2 s « MAINTENIR : ALIBI … » (VoiceOver / Switch Control : bouton + confirmation) |
| **Vérification** | « VÉRIFICATION DU DOSSIER… » tapé, le dossier se ferme, tampon RÉSOLU (verdict juste) / NON RÉSOLU, « VOTRE VERDICT : … » | [LIRE LE RAPPORT] |
| **Rapport** | votre verdict ; juste : la réponse, ce qui s'est passé, la chronologie (● trouvé / ○ manqué) ; faux : « votre verdict ne tient pas », le piège, les pièces clés trouvées (les manquées restent cachées) ; indices, note | juste : [CLASSER LE DOSSIER] · faux : [REPRENDRE LA VÉRIFICATION] (chrono plein, pièces gardées), « Voir la réponse », « Classer quand même » |

Le jeu ne conclut jamais à la place du joueur : le Carnet ne fait que compter ce que le joueur a dit de chaque pièce.

## Indices

Trois plis, comme les enquêtes, encore plus simples (coûts 0 / 5 / 10 points) :

1. « Commencez par vérifier les horaires. » (où regarder)
2. « Comparez les traces du téléphone avec ce qu'il affirme. » (quoi comparer)
3. une orientation forte vers l'endroit qui tranche — **jamais la réponse** (ni « confirmé » ni « contredit » :
   vérifié par `AlibiCasesTests.shortAndSimple`).

## Note

La même formule que les enquêtes (`rules.json › scoring`) : 60 · verdict juste + 25 · pièces clés trouvées / total +
10 · temps restant (verdict juste seulement) + 5 · pièces versées pertinentes − coût des indices. Elle reste secondaire :
le plaisir vient du raisonnement. Le rang d'enquêteur ne compte que les enquêtes.

## Données (pour les futures affaires)

Une vérification ALIBI est un fichier `ScreenshotKit/Sources/CaseLibrary/Resources/Cases/alibi_NNN.json` : une affaire
normale (voir `docs/CASE_AUTHORING.md`) avec en plus :

```json
"mode": "alibi",
"number": 104,
"claim": {"person": "me", "statement": "« … »", "place": "…", "from": "2026-11-06 22:00", "to": "2026-11-06 23:00"},
"minimalPath": ["e_…", "e_…"],
"solution": { "culprit": "s_<personne>", "alibiHolds": false, "headline": "…", "summary": "…", "reveal": […], "story": […] }
```

Règles vérifiées par `CaseValidator` et les tests (`AlibiTests`, `AlibiCasesTests`) :

- numéro ≥ 101 (affiché « ALIBI #001 » pour 101) ; les enquêtes restent entre 1 et 100 ;
- exactement **un** « suspect » : la personne de la déclaration (`claim.person`, en général le propriétaire `me`),
  `solution.culprit` = son id ; `solution.alibiHolds` obligatoire ;
- au moins 2 pièces `key` sur elle, au moins 1 `falseLead` ; `minimalPath` de 2 à 4 pièces, visibles en moins de la
  moitié du temps ;
- 240 à 360 s ; 3 indices à 0 / 5 / 10 points ; pas d'`introScene` ;
- un téléphone réaliste mais petit : plus de la moitié des messages ne sont pas des indices ;
- photos : uniquement de vraies photographies (fiche `config/photo_queries/case_NNN.json`, voir
  docs/photo_pipeline/PHOTO_PIPELINE.md), aucune personne de l'histoire à l'image ;
- parmi les vérifications livrées, au moins une CONFIRMÉE et une CONTREDITE (le joueur ne doit pas apprendre que
  « c'est toujours contredit »).

Les affaires livrées et leur solution : [ALIBI_CASES.md](ALIBI_CASES.md).

## Code

- Moteur : `CaseFile.mode / claim / minimalPath`, `Solution.alibiHolds`, `Investigation.concludeAlibi(holds:)`,
  `Verdict.alibiAnswer` (CaseEngine) ; `CaseAnalysis.minimalPathSeconds`.
- Interface : `Screens/AlibiScreens.swift` (carte du Bureau, liste, mini-dossier, verdict, rapport), le Carnet
  (`InvestigationView.swift` : onglet DÉCLARATION, [CONTREDIT] / [CONFIRME]), `RootView` (étapes `.alibi`,
  `.alibiIntro`).
- Tests : `CaseEngineTests/AlibiTests.swift`, `CaseLibraryTests/AlibiCasesTests.swift`, test d'interface
  `testAlibiModeFirstCheck`.
