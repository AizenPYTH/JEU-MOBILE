# CONCLUDE : ENQUÊTES — RELEASE READINESS AUDIT

**Date :** 26 septembre 2026 · **Studio :** NOREL GAMES · **Commit audité :** `9ccafc0` (état d'avant V3)
**État actuel vérifié :** branche `claude/busy-hopper-5dgev5` après l'intégration du handoff final V3, HEAD `0fad7aa` (+ 4 corrections marquées « RÉSOLU » après coup : musique, solution, repli de portrait)
(V3 = `def10f9` → `babe6dd`, puis `0fad7aa` : correctifs P0/P1 d'un autre agent, commités pendant cette revue).

**Méthode.** L'audit de sortie (43 agents : 21 domaines, vérification contradictoire, critique de complétude) avait
retenu **671 constats vérifiés** sur `9ccafc0` (12 P0, 57 P1, 222 P2, 380 P3). Chaque constat a été repris un par un
contre le code actuel : lecture des fichiers concernés, `grep`, `git diff 9ccafc0` (75 fichiers modifiés par V3), le
handoff final `docs/design_final/FINAL_DESIGN_HANDOFF_CONCLUDE.md` et `DESIGN_INTEGRATION.md` (section « V3 »). Point
important : **le moteur (`CaseEngine`), les 5 affaires JSON, `rules.json`, le peintre de photos `GeneratedPhoto`
(hors style nuit), les scripts et les workflows CI n'ont pas changé depuis `9ccafc0`** : les constats qui en dépendent
restent donc vrais tels quels. Un « RÉSOLU » n'est écrit que s'il a été vérifié dans le code ; les numéros de ligne
renvoient à HEAD `0fad7aa`.

**Statuts utilisés**

| Statut | Sens |
|---|---|
| RÉSOLU (V3) | Corrigé par le travail V3 (on dit par quoi) |
| OBSOLÈTE | L'écran ou la fonction n'existe plus (onboarding, cinématiques, TimeUpView, ScoreView, pastille « ENQ »…) |
| EN COURS DE CORRECTION | Les 4 correctifs confiés à un autre agent : code commité dans `0fad7aa`, pas encore validé par la CI iOS ni sur appareil |
| OUVERT | Toujours vrai : priorité P0–P3 et solution proposée |
| REQUIRES DECISION | Choix produit du porteur de projet (voir §20) |
| BLOQUÉ – ASSETS | Attend des images ou des sons à produire (voir §19) |
| BLOQUÉ – EXTERNE | Se règle hors du code (App Store Connect, compte développeur, pages web) |

« OUVERT (réduit par V3) » signale un constat que V3 a en partie corrigé : la ligne dit ce qui reste. Dans les tableaux,
plusieurs identifiants sur une même ligne sont des **doublons** : le même problème relevé par plusieurs domaines.

---

## 1. RÉSUMÉ

**État général.** V3 a changé le visage du jeu. Le premier lancement tient désormais en 4 écrans
(Lancement → Titre → « Qui enquête ? » → Dossier #001 → téléphone), avec un tutoriel en 3 bulles dans l'affaire #001.
Le joueur a une identité (Élise Morel / Vincent Delmas, matricule BEN fixe). Les rangs suivent l'échelle verrouillée et
« Stagiaire » a disparu. Le vocabulaire est unifié (EXPLORER · VERSER AU DOSSIER · CONCLURE) et protégé par un test. Le
geste de versement est le même dans toutes les apps, le Carnet est simplifié, la conclusion est nommée et le rapport
explique avant de noter. Les cinématiques et l'ancien onboarding ont été retirés, ce qui rend obsolètes une centaine de
constats. Le correctif `0fad7aa` traite le P0 du clavier, la fuite de la Corbeille, la perte silencieuse d'une enquête
et les photos de nuit, mais il reste à le valider sur la CI iOS.

Ce qui reste se range en quatre familles :
1. **L'administratif App Store Connect** : 6 P0, tous hors code.
2. **Les assets** : portraits des suspects, photos réelles, captures App Store.
3. **Les incohérences de contenu dans les JSON**, auxquels V3 n'a pas touché.
4. **Quelques règles de jeu à trancher** : un bon suspect sans preuve donne RÉSOLU, et après « Consulter la solution »
   on peut rejouer et être classé.

**Verdict.** Prêt pour **TestFlight** dès que la CI iOS valide `0fad7aa`. **Pas encore prêt pour l'App Store** (voir §22).

**Chiffres (constats de l'audit, doublons compris)**

| | P0 | P1 | P2 | P3 | Total |
|---|---|---|---|---|---|
| Constats audités sur 9ccafc0 | 12 | 57 | 222 | 380 | **671** |
| dont RÉSOLU (V3) | 1 | 13 | 62 | 104 | **180** |
| dont OBSOLÈTE | 0 | 5 | 48 | 60 | **113** |
| dont encore ouverts (tous statuts ouverts) | 11 | 39 | 112 | 216 | **378** |
| **Encore ouverts, par priorité actuelle** (après re-priorisation) | **11** | **41** | **92** | **234** | **378** |

**Avant → maintenant :** P0 12 → 11 · P1 57 → 41 · P2 222 → 92 · P3 380 → 234 · total 671 → 378 (293 constats fermés, soit 44 %).

**Répartition des 378 constats ouverts :** OUVERT 269 · REQUIRES DECISION 53 · BLOQUÉ – ASSETS 36 · EN COURS DE CORRECTION
13 · BLOQUÉ – EXTERNE 7.

**En problèmes distincts** (doublons fusionnés) :
- **P0 :** 8 → 7. Le clavier compte pour 5 constats : il est en cours. Restent les 6 points App Store Connect ; le rang « Stagiaire » est résolu.
- **P1 :** 25 → 19. Détail : 3 en cours, 3 ouverts (musique coupée au lancement, petits iPhone, photo du col #005),
  3 bloqués par des assets (portraits, photos, prompts #002), 2 externes, 8 décisions.

---

## 2. PREMIER LANCEMENT

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `onboarding-spoils-case001-key-clue`, `onboarding-spoils-case-001` | Onboarding étape 1 | La démo reprenait la preuve clé de #001 (photo « au lit depuis 20h », 19:42) | Spoil de la première affaire | P1 | — | OBSOLÈTE : `OnboardingView.swift` supprimé ; le tutoriel est fait de 3 bulles dans #001, qui ne montrent aucune preuve (`Tutorial.swift`, `CoachBubble.swift`) |
| `onboarding-geste-different`, `onboarding-pin-gesture-differs-from-game`, `onboarding-holdcue-clipped`, `onboarding-copy-goal-and-linking`, `onboarding-qui-ment`, `onboarding-composition-generique`, `onboarding-demo-accusation-obsolete`, `onboarding-vocabulaire` | Onboarding 3 étapes | Geste différent du jeu, indication « Maintenez » coupée, vocabulaire non verrouillé, composition générique, ancienne accusation | Apprend un faux geste | P2 | — | OBSOLÈTE (onboarding retiré) |
| `cinematic-caption-over-seal-tag`, `cinematic-subtitle-over-seal` | Cinématique #001 | Sous-titre écrit par-dessus l'étiquette de scellé | Texte illisible | P2 | — | OBSOLÈTE (`CinematicView.swift` supprimé) |
| `dossier-header-non-ouvert-vs-ouvert` | Dossier #001 | « NON OUVERT » en tête et « STATUT : OUVERT » en dessous | Contradiction | P2 | — | RÉSOLU (V3) : le briefing 04 n'a plus ni cet en-tête ni ce champ (`DossierView.swift`) |
| `handoff06-first-launch-flow-missing`, `no-premise-who-am-i`, `identite-joueur-absente` (player-profile) | Premier lancement | Pas de prémisse (qui suis-je, pourquoi ce téléphone), pas de choix d'enquêteur | Le joueur ne sait pas qui il est | P2 | — | RÉSOLU (V3) : 02 Titre avec accroche, mission et 3 verbes ; 03 « Qui enquête ? » ; 04 briefing ; 12 affectation (`TitleScreens.swift`, `Player.swift`, `AssignmentView.swift`) |
| `onboarding-commencer-lands-on-bureau` | Fin d'onboarding | « Commencer » menait au Bureau, soit environ 10 interactions avant le téléphone | Friction | P2 | — | RÉSOLU (V3) : Titre → Qui enquête ? → Dossier #001 → téléphone (`RootView.beginFirstCase`) |
| `level-default-and-enqueteur-collision` | Dossier #001 | Niveau Détective imposé, sélecteur en bas de page ; le niveau « Enquêteur » porte le nom du rang 0 | Confusion | P2 → P3 | Le niveau est désormais caché à la 1re partie (`DossierView.showsLevels`) ; reste à renommer les niveaux (§20, D11) | REQUIRES DECISION |

**P3 (15 constats)**
- **OBSOLÈTE** (onboarding et cinématique retirés) : `onboarding-maintenez-masque`, `onboarding-demo-ui-differs-from-game`,
  `onboarding-empty-lower-half`, `onboarding-hardcoded-costs`, `onboarding-inert-app-tiles`, `onboarding-holdcue-overlap`,
  `onboarding-demo-not-the-real-ui`, `onboarding-photo-clipart`, `cinematic-replayed-on-every-retry`,
  `cinematique-recrutement-absente` (décision : aucune cinématique), `first-10-seconds-assessment`. Ce dernier bilan
  est à refaire en test joueur sur le nouveau parcours ; le critère 1 du handoff (téléphone atteint en ≤ 4 taps) est
  déjà couvert par `testFirstLaunchToTheBureau`.
- **RÉSOLU (V3)** : `launch-screen-plain-black` (écran de lancement système = écran 01 : `LaunchBackground` +
  `LaunchTile`, `Configs/Info.plist`) ; `loading-vs-handoff-01` et `chargement-apparition-et-test` (écran 01 réel,
  1,6–4 s, fondu) ; `bureau-first-visit-copy` (« Prochaine enquête » au lieu de « Dossier suivant »).

---

## 3. UX / GAMEPLAY

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `vocabulaire-accuser-designer-clore` | Tout le jeu | La même action portait 5 noms (accuser, désigner, clore…) | Confusion | P2 | — | RÉSOLU (V3) : EXPLORER · VERSER AU DOSSIER · CONCLURE ; test `bannedWordsAreGone` |
| `quit-button-looks-like-back` | Téléphone | Bouton « Quitter » dessiné comme un retour « ‹ » | Sorties involontaires | P2 | — | RÉSOLU (V3) : bouton pause ⏸ + feuille « Mettre l'enquête en pause ? » (`PhoneView.QuitButton`) |
| `no-first-play-coaching-in-phone` | Téléphone, 1re partie | Aucune indication à l'arrivée dans le téléphone | Joueur perdu | P2 | — | RÉSOLU (V3) : 3 bulles EXPLORER / VERSER / RELIER + relance à 90 s (`Tutorial.swift`) |
| `link-no-visual-trace` | Téléphone / Carnet | Rien ne montrait qu'une pièce accuse ou disculpe | Lien invisible | P2 | — | RÉSOLU (V3) : ligne « ▲ L'accuse : Emma » sur la fiche de pièce, ▲▼ sur les fiches suspects et à la conclusion |
| `level-choice-hidden-default-detective` | Dossier | Choix du niveau enfoui, Détective par défaut | Choix subi | P2 | — | RÉSOLU (V3) : « NIVEAU : DÉTECTIVE » replié mais visible, durée au pied de la feuille (conforme §F-04) |
| `veille-ecran-non-desactivee` | Enquête, conclusion | `isIdleTimerDisabled` n'est jamais réglé : l'écran s'éteint pendant la lecture ou la réflexion (0 occurrence dans le code) | Pause involontaire, chrono « EN PAUSE » | P2 | Désactiver la veille en phase `.investigating` et sur la conclusion ; la réactiver ailleurs | OUVERT |
| `spam-versement-rentable` | Carnet / score | Verser est gratuit ; les pièces trouvées valent 25 pts, la précision seulement 5 (`rules.json`) | « Tout verser » est rentable | P2 | Voir §20, D7 | REQUIRES DECISION |
| `coupable-toujours-en-bout-de-liste` | Conclusion 09, Carnet | Le coupable est toujours 1er ou dernier (ordre du JSON) | Biais exploitable | P2 | Ordre alphabétique ou mélange déterministe (§20, D16) | REQUIRES DECISION |
| `live-events-not-scaled-by-level` | Moteur | Les événements en direct ne suivent pas la durée du niveau : en Expert, certaines pièces n'arrivent jamais | Note plafonnée | P2 | §20, D10 | REQUIRES DECISION |
| `costs-not-announced` | Téléphone | Seuls 5 gestes affichent leur coût avant l'action | Coûts découverts après coup | P2 | §20, D15 | REQUIRES DECISION |

**P3 (13 constats)**
- **RÉSOLU (V3)** :
  - `confirmation-sans-annuler` et `confirmations-systeme` : feuilles papier `PaperConfirmSheet` avec « Retour », plus de boîte système ;
  - `resume-while-quit-alert-open` : un retour au premier plan ne relance plus le chrono sous la feuille de pause, `InvestigationShell.swift` ;
  - `no-objective-reminder-in-phone` : Carnet › « Dossier » ;
  - `carnet-vs-dossier-naming` : barre « DOSSIER #001 · n pièces versées · CARNET » ;
  - `accuse-cta-wording` : « CONCLURE L'ENQUÊTE ».
- **OBSOLÈTE** : `aide-permanent-red-dot` (l'aide est une ampoule dans le Carnet), `walkthrough-step-by-step`,
  `walkthrough-nine-questions` (parcours refait : à rejouer en test).
- **OUVERT** :
  - `disponible-a-ambigu` : « Disponible à 02:00 » alors que le téléphone affiche aussi l'heure ; écrire « Quand il restera 02:00 » (`InvestigationView.swift:1058`) ;
  - `navigation-double-tap-sans-garde` : `GameSession.open` empile sans vérifier, donc un double tap facture deux fois ;
  - `free-thinking-time-accusation-and-quit` : chrono arrêté sur l'écran de conclusion et pendant la feuille de pause ; faible, mais exploitable.

---

## 4. BUREAU / ARCHIVES

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `dossier-status-contradiction`, `statut-dossier-contradictoire`, `c004-status-contradiction`, `closed-case-shows-not-opened`, `dossier-status-contradictions`, `dossier-statut-apres-cloture`, `dossier-statuts-contradictoires` | Dossier ouvert | « NON OUVERT » et « STATUT OUVERT » ensemble, même sur un dossier résolu | Incohérence visible partout | P2 | — | RÉSOLU (V3) : le briefing n'affiche plus d'état ; Bureau et Archives lisent `DossierStatus` |
| `bureau-surtitres-minuscules-espaces` | Bureau | Surtitres en minuscules très espacées | Lisibilité | P2 | — | RÉSOLU (V3) : `DeskOverline` en capitales, interlettrage 1,8 |
| `dossier-onglets-debordent` | Dossier | Les intercalaires débordaient de l'écran | Onglet Rapport caché | P2 | — | OBSOLÈTE : le dossier n'a plus d'intercalaires |
| `archive-report-tab-hidden` | Archives → dossier | Le rapport n'était pas visible depuis les Archives | Rapport introuvable | P2 → P3 | Depuis les Archives, ouvrir directement le « Rapport de clôture » (handoff §N : « Rapport en lecture seule + [REJOUER] ») ; aujourd'hui c'est un lien en bas du briefing | OUVERT (réduit par V3) |
| `back-from-archives-goes-bureau` | Dossier ouvert depuis les Archives | « ‹ Bureau » ramène toujours au Bureau (`DossierView.swift:106-121`, `RootView.leaveBriefing`) | Perte de contexte | P2 → P3 | Mémoriser l'écran d'origine | OUVERT (réduit : le libellé VoiceOver est corrigé) |
| `report-tab-content` | Rapport archivé | « Responsable désigné : Oui/Non », sans niveau ni temps utilisé (`DossierView.swift:563-568`) | Rapport pauvre, ambigu | P2 | « Responsable identifié : {nom} », niveau, temps utilisé (déjà dans `Attempt`) | OUVERT |
| `c004-cover-object-image` | Bureau / dossier #004 | Le tirage « collier » était une vitrine avec un « V » lumineux | Ressemblait à un logo | P2 → P3 | Fiche objet « Collier Aurore » à produire | BLOQUÉ – ASSETS (réduit : V3 met un tirage neutre sur le Bureau et aucun tirage au briefing) |
| `closed-dossier-loses-work`, `closed-case-pieces-not-kept` | Dossier clos | Le travail du joueur (pièces, liens) n'est pas conservé | Relecture impossible | P2 | §20, D17 | REQUIRES DECISION |
| `sans-faute-unreachable` | Archives, profil | « SANS FAUTE » exige 100/100, or le maximum réel est 99 | Distinction impossible | P2 | §20, D9 | REQUIRES DECISION |

**P3 (24 constats)**
- **RÉSOLU (V3)** :
  - `c002-dossier-status-labels`, `c5-dossier-non-ouvert-vs-ouvert` ;
  - `score-next-last-case-and-no-bureau` : « Classer le dossier » ramène au Bureau ;
  - `settings-return-and-edge-swipe` : les Paramètres reviennent à leur origine ;
  - `all-solved-bureau-state` : feuille « Tous les dossiers sont classés » ;
  - `bureau-no-hook-no-case-loading` : accroche sur la chemise ;
  - `dossier-objectif-sous-la-ligne` : VOTRE MISSION juste sous le résumé.
- **OBSOLÈTE** (champs LIEU et légende du tirage plus affichés, bande de chemise retirée) : `c004-dossier-place-double-dash`,
  `c004-cover-caption-truncated`, `dossier-legende-tronquee`, `dossier-tiret-orphelin`, `bureau-feuille-qui-depasse`.
- **REQUIRES DECISION** : `no-locked-state-progression` (aucun dossier verrouillé ; le handoff §F-13 prévoit un état
  VERROUILLÉ ; voir §20, D24).
- **OUVERT** :
  - `niveaux-libelles-details`, `level-best-result-format`, `niveaux-ligne-resultat` : ligne « RÉSOLUE 00:14 69 / 100 » sans libellés ; condition de verrou mal rédigée (`MetaScreens.swift:63-77`) ;
  - `archives-consulter-casse`, `archives-casse-boutons` : « Consulter » en casse mixte (`DeskScreens.swift:563`) ;
  - `archives-wording-filters` : le filtre « En cours » inclut les dossiers neufs (`DeskScreens.swift:478`) ;
  - `archives-effet-liste` : fiches identiques et plates ;
  - `settings-missing-items` : réduit par V3, qui a ajouté À propos, Temps détendu et Revoir le tutoriel ; manquent la confidentialité, le contact et la remise à zéro ;
  - `report-key-found-mislabel` : « Pièces clés trouvées 1/12 » compte toutes les pièces ;
  - `dead-archive-stages` : `Stage.archived` et `ArchivedCaseView` morts ;
  - `tabbar-icone-bureau-vide` : icône `rectangle.fill` (`TraceDesign.swift:570`).

---

## 5. JOUEUR / PROFIL / RANGS

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `bureau-rang-stagiaire` (P0), `c001-rang-stagiaire-visible`, `rang-stagiaire-et-seuils`, `rank-stagiaire-bureau`, `rank-ladder-not-locked-stagiaire`, `bureau-rank-stagiaire-first-screen`, `rank-stagiaire-visible`, `rang-echelle-stagiaire`, `rangs-vocabulaire-verrouille` | Bureau, profil | Rang « Stagiaire » (mot interdit) dès le premier écran ; échelle à 5 rangs | Identité verrouillée violée | P0 / P1 | — | RÉSOLU (V3) : `Rank.forSolved` 0 → ENQUÊTEUR, 1 → INSPECTEUR, 2–3 → SENIOR, 4+ → EXPÉRIMENTÉ (`Player.swift`) ; rang visible seulement après l'affectation ; « Stagiaire », « Trainee » et « Recrue » bannis par test |
| `player-identity-absent-desk`, `identite-joueur-absente` (content-strings), `no-player-identity` | Bureau, profil | Aucun nom d'enquêteur, pastille « ENQ » en dur | Menu anonyme | P1 / P2 | — | RÉSOLU (V3) : Élise Morel / Vincent Delmas, pastille portrait, « É. MOREL · INSPECTEUR », carte d'agent |
| `matricule-TR-carte-agent`, `matricule-tr-variable` (desk, player-profile), `enqueteur-matricule-trace` | Carte Enquêteur | Matricule « TR-xxxx » recalculé à chaque affaire | Reste de TRACE | P2 | — | RÉSOLU (V3) : BEN-04821 / BEN-05307 fixes, « Carte d'agent · BEN » |
| `carte-silhouette-person-fill`, `enqueteur-photo-silhouette` | Carte Enquêteur | Silhouette SF Symbol (interdite) | Placeholder | P2 | — | RÉSOLU (V3) : `PlayerPrint` (portrait, sinon initiales sur bleu BEN) |
| `lacaze-absent` | Tout le jeu | Le Cdt. Lacaze n'apparaissait nulle part | Hiérarchie absente | P2 | — | RÉSOLU (V3) : écran 12 signé (nom, signature PNG, sceau BEN) ; plis d'indice non signés, conformes à V3 |
| `avancement-silencieux`, `avancement-apres-cloture` | Après le Rapport de clôture | Aucun écran quand le rang change (écran 10 du document 06) | Progression muette | P2 | Feuille « BEN · DÉCISION » après [CLASSER] quand le rang change, avec le cachet `stamp_{rang}_rouge` (déjà livré). Le handoff V3 « conserve tel quel » cet écran | OUVERT |
| `niveaux-vs-rangs-collision`, `niveaux-nom-enqueteur` | Dossier, profil | Niveau « Enquêteur » = rang ENQUÊTEUR = onglet Enquêteur ; niveau « Expert » ≈ rang EXPÉRIMENTÉ | Confusion | P2 | §20, D11 | REQUIRES DECISION |
| `brute-force-solve-by-replay` | Résolution / rang | Une accusation juste sans pièce vaut environ 69/100 et fait monter de rang ; rejouer est illimité. **Aggravé par V3** : [REPRENDRE L'ENQUÊTE] garde les pièces et remet le chrono plein | Rangs vidés de leur valeur | P2 | §20, D6 | REQUIRES DECISION |
| `distinction-parfaite-inatteignable` | Profil | « Enquête parfaite (100 %) » ne peut pas être obtenue (`DeskScreens.swift:822`) | Distinction morte | P2 | §20, D9 | REQUIRES DECISION |

**P3 (7 constats)**
- **RÉSOLU (V3)** :
  - `rang-logique-hors-moteur` : `Rank` dans `Player.swift`, plus dans une vue ;
  - `rang-prochain-seuil-faux` : « Encore n dossiers résolus pour INSPECTEUR » ;
  - `carte-marque-jeu` ;
  - `handoff06-statut-ecrans` : écrans 02–06 et 12 faits, seul l'écran 10 manque ;
  - `handoff-incoherences-rangs` : le code suit l'échelle verrouillée.
- **REQUIRES DECISION** : `collision-enqueteur-niveau-rang` (voir D11).
- **OUVERT** : `genre-enquetrice-a-prevoir`, réduit par V3 (ENQUÊTRICE et « affectée » sont gérés). Restent
  « NOTES DE L'ENQUÊTEUR », l'onglet « Enquêteur » et « Carte d'enquêteur » quand le joueur est Élise.

---

## 6. ENQUÊTE #001

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `photo-time-free-but-analysis-required` (+ `c001-heure-photo-visible-avant-analyse`, §8) | Photos › « chez moi » | L'heure de prise (19:42) est affichée avant l'analyse (`PhotosViews.swift:148-151`), mais la preuve ne compte que si l'analyse (−15 s) a été vue | « J'avais trouvé, le jeu dit non » sur la preuve phare | P1 | §20, D8 | REQUIRES DECISION |
| `photo-caption-without-person` | Photo « chez moi » | La légende parle d'Emma sous la couette, l'image montre un lit vide ; le ciel clair se lit mal | La pièce phare contredit son texte | P1 | Photo générée `photo_001_p_emma_couch` ; en attendant, retirer « Emma » de la légende (JSON) | BLOQUÉ – ASSETS |
| `c001-aides-paliers-inverses` | Indices #001 | L'indice gratuit en dit plus que le palier 2 | Paliers faux | P2 | Réécrire les 3 textes (§20, D14) | REQUIRES DECISION |
| `c001-evenements-direct-non-etales` | Événements en direct | En Expert, lv07, lv08 et lv09 n'arrivent jamais | Pièces impossibles à obtenir | P2 | §20, D10 | REQUIRES DECISION |
| `c001-sarah-savait-avant-hugo` | Messages Sarah ↔ Alex | Sarah connaît le secret d'Hugo avant qu'il l'annonce (27/08) | Incohérence | P2 | Remplacer 2 messages par du bruit, même nombre (`gen_case_001.py:121-122`) | OUVERT |
| `c001-partage-coupe-gratuit-non-versable` | Réglages, conversation Emma | L'arrêt du partage (21:31) s'affiche gratuitement mais ne peut pas être versé ; seule la fiche Carte compte | Injustice ; contredit « tout élément affiché peut être versé » (§F-06) | P2 | §20, D13 | REQUIRES DECISION |
| `objective-vs-final-question` | Briefing, conclusion | Objectif « qui a vu Alex en dernier » ≠ « Qui est responsable ? » | Deux questions | P2 | §20, D12 | REQUIRES DECISION |
| `c001-reportage-nuit-a-0954`, `sous-titre-cinematique-scelle` | Cinématique #001 | Reportage de nuit daté 09:54 ; sous-titre sur l'étiquette | — | P2 | — | OBSOLÈTE (cinématique retirée) |

**P3 (7 constats)**
- **OUVERT** (JSON inchangé) :
  - `c001-ines-veste-jean` : le lien veste claire → Emma repose sur un seul message ;
  - `c001-role-karim-dette-perimee` : « lui doit 1 200 € », alors qu'il en a déjà remboursé 600 ;
  - `c001-telephone-apres-chute` : messages lus et positions après la chute de 22:28 ;
  - `c001-recit-grace-a-votre-enquete` : « Grâce à votre enquête… » s'affiche aux Archives même après un échec suivi de la solution (`DossierView.swift:595`).
- **OBSOLÈTE** : `c001-ecran-verrouille-maintenant` (l'ouverture n'a plus de notifications) et `c001-apprentissage-nouveau-joueur`.
- **RÉSOLU (V3)** : `seal-number-vs-piece-one` (le téléphone est « SCELLÉ N° 001-01 », les pièces commencent à 01).

---

## 7. ENQUÊTES #002-#005

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `c004-story-arrest-contradiction` | Récit #004 (Archives) | Sterne est arrêté à 22:35 dans le récit, mais il écrit librement à 23:26 et 23:27 | Contradiction majeure lue par tous | P1 | Placer l'interpellation après la fenêtre d'enquête (vers minuit) ; texte à valider (§20, D23) | REQUIRES DECISION |
| `c5-photo-col-2314-voiture-de-solene` | Photos › p_col_2314 (preuve clé e_4x4) | Le peintre `road_night` dessine la voiture de Solène de dos, feux de détresse allumés, au lieu de phares qui arrivent de face | La pièce maîtresse contredit sa légende | P1 | Scène dédiée : phares de face, brouillard, pare-brise ; à terme `photo_005_p_col_2314` | OUVERT |
| `c5-photo-enfants-fenetre-jour` | Photos › p_kids_2305, p_platre | Scène `bed` de jour (fenêtre claire, télé, tasse), identique à la photo d'alibi d'Emma dans #001 | Fausse piste involontaire contre des innocents | P1 | `0fad7aa` peint p_kids_2305 (style nuit) de nuit. **Reste :** p_platre (sans style, toujours la chambre de jour) et le décor `bed` réutilisé : scène hôpital, lits superposés | EN COURS DE CORRECTION |
| `c002-yanis-alibi-wrong-time`, `c002-motive-meaning-wrong-day`, `c002-story-0252-vs-reveal-0258` | Textes #002 | L'alibi de Yanis est ancré à 02:48 au lieu de 03:07 ; « le soir même » au lieu du lendemain ; 02:52 contre 02:58 | Incohérences de solution | P2 | Corrections déjà rédigées (générateur, lignes citées dans l'audit) | OUVERT |
| `c003-everyone-slept-contradiction`, `c003-paul-messages-unread-implausible`, `c003-tripod-framing-contradiction`, `c003-yellow-under-lamp-ambiguity` | Textes #003 | « Tout le monde dormait » ; messages de Paul non lus ; trépied incohérent ; « sweat jaune » ambigu | Logique fragile | P2 | Réécritures proposées (§20, D23) | REQUIRES DECISION |
| `c004-expert-coat-unreachable` | #004 en Expert | La pièce e_coat dépend de lv07 (370 s) alors que l'Expert dure 300 s | Note plafonnée | P2 | Avancer lv07 à 280 s (données) ou voir §20, D10 | OUVERT |
| `c5-appel-vocal-faux-julien` | Appels #005 | Le faux Julien parle 70 s à Solène, qui connaît sa voix | Invraisemblance | P2 | Appel manqué ou coupé (§20, D23) | REQUIRES DECISION |
| `c5-declaration-julien-1h` | Déclaration de Julien | « Aux urgences jusqu'à 1h » contredit « ils me gardent pour la nuit » | Incohérence | P2 | Aligner la déclaration | OUVERT |
| `c5-photo-n24-voiture-fantome` | Photos › p_n24 | La légende dit « aucune voiture », l'image en montre une | Contradiction | P2 | Scène sans voiture (brouillard, sapins) | OUVERT |
| `c5-photos-scenes-reutilisees-001` | Photos #005 | Images clés de #001 réutilisées (parking du Quai 9 pour p_mairie_4x4…) | Confusion entre affaires | P2 | Photos du handoff 02 §2.4 + prompt p_mairie_4x4 à écrire | BLOQUÉ – ASSETS |
| `c5-recherche-numero-formats` | Recherche #005 | « +33 7 58… » ne trouve pas « 07 58… » | **Mécanique centrale de #005 cassée** pour qui tape le numéro | P2 | Normaliser les chiffres (+33 → 0) dans `MessageSearch` + tests moteur | OUVERT |
| `c5-releve-bancaire-deborde` | Photo relevé Brassac | Texte hors de la feuille | Illisible | P2 | Raccourcir les lignes + ajuster le peintre (voir aussi §10) | OUVERT |
| `c002-intro-title-overlap` | Ouverture #002 | Ligne de lieu sur le panneau | — | P2 | — | OBSOLÈTE |

**P3 (35 constats)**
- **#002, OUVERT** :
  - `c002-casque-contradiction`, `c002-objective-0230` (le téléphone était encore à Clémence à 02:46) ;
  - `c002-bastien-track-misses-bar`, `c002-story-0436-vs-browser-0431`, `c002-style-clue-dilution` ;
  - `c002-tagline-literal` (« a pris le premier métro », affichée sur la chemise du Bureau) ;
  - `c002-raphael-statement-discrepancy`, `c002-browser-0431-unexploited` ;
  - `c002-raphael-reflection-concluded` (le détail conclut à la place du joueur), `c002-real-places-brand` (club réel « Le Silo »).
- **#002, OBSOLÈTE** : `c002-intro-anais-name`, `c002-lastcontact-0217` (champ plus affiché), `c002-dossier-place-dashes`.
- **#003, OUVERT** : `c003-deleted-message-rule-inconsistent`, `c003-evidence-meaning-weak-logic`,
  `c003-chu-revealed-by-wrong-item`, `c003-live-events-tone`. **OBSOLÈTE** : `c003-intro-time-jump-repeated-line`.
- **#004, OUVERT** :
  - `c004-vitrine-oct21-necklace`, `c004-photo-2216-concludes` (l'analyse conclut à la place du joueur) ;
  - `c004-police-before-arrival`, `c004-garrel-timeline`, `c004-kessler-address-unsourced` ;
  - `c004-owner-age-pack`, `c004-copyist-plausibility`, `c004-map-decorative`, `c004-difficulty-field`.
- **#004, OBSOLÈTE** : `c004-veo-prompt-clasp`, `c004-en-dossier-labels` (libellés de couverture plus affichés).
- **#005, OUVERT** : `c5-voiture-parking-ou-bas-cote` (synopsis contre données), `c5-indice-code-ma-date` (« Ma date (JJMM) »),
  `c5-iphone12-dynamic-island` (un iPhone 12 dessiné avec un îlot). **OBSOLÈTE** : `c5-intro-ligne-coupee`.
- **Transverse** : `lieu-double-tiret-troncature` OBSOLÈTE ; `formats-heure-narration` OUVERT (« 22h », « 21h30 » et « 22:30 » mêlés dans les JSON).

---

## 8. TÉLÉPHONE

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `lock-keypad-zero-hidden-under-carnet`, `notes-keypad-zero-hidden`, `notes-keypad-hidden-under-carnet`, `lock-keypad-under-carnet`, `notes-clavier-0-sous-carnet` | Notes verrouillée (#001, #005) | La rangée « 0 / ⌫ » passait sous la barre ; codes 1609 et 1403 impossibles à taper. V3 l'avait aggravé (barre de 64 pt) | Mécanique « tenter un code » cassée, preuve e_motive inaccessible | **P0** | `0fad7aa` : `ViewThatFits` (touches 72 → 52 pt, défilement en dernier recours) + marge `PhoneLayout.barClearance` (`NotesViews.swift`). **Reste à faire :** valider en CI iOS sur petit et grand simulateur, et ajouter un test UI qui tape le code (aucun test ne le fait encore) | EN COURS DE CORRECTION |
| `trash-pin-leaks-deleted-message` | Corbeille | Un message non récupéré pouvait être versé, donc lu et compté gratuitement | Triche sur 2 preuves clés (#001, #003) | P1 | `0fad7aa` : `.pinnable` seulement après récupération (`OtherApps.swift:505-513`). Reste : garde moteur et bulle « supprimé par l'expéditeur », voir §9 | EN COURS DE CORRECTION |
| `track-view-fixed-map-small-screens` | Carte › trajet | Carte de 390 pt fixe : la chronologie disparaît sur un SE | Inutilisable sur petit écran | P2 | `0fad7aa` : hauteur réduite pour garder 130 pt de liste (`LocationViews.swift:180-185`) ; à valider sur SE | EN COURS DE CORRECTION |
| `small-iphone-layouts-unverified` | Toutes les apps, petit iPhone | Aucun test sur SE ; hauteurs fixes. V3 réserve 150 pt en bas (barre du dossier de 64 pt) : l'espace utile a diminué | Écrans coupés chez les joueurs et en revue Apple | P1 | Passe de tests UI sur iPhone SE (3e gén.) ; rendre la feuille de Carte (300 pt fixe, `LocationViews.swift:70`) proportionnelle. Le clavier et la carte de trajet sont traités par `0fad7aa` | OUVERT |
| `c001-heure-photo-visible-avant-analyse` | Photo | Voir §6 | — | P2 | §20, D8 | REQUIRES DECISION |
| `c5-initiales-J-parenthese` | Contacts #005 | L'avatar de « Julien (nouveau n°) » affiche « J( » | Défaut visible | P2 | Ne garder que des lettres dans `Contact.initials` (moteur) | OUVERT |
| `carte-mentions-legales-milieu` (performance-assets, visual-phone), `map-legal-and-bleed-under-header` | Carte | Le logo « Plans / Mentions légales » flotte au milieu et recouvre les lieux | Carte sale, attribution mal placée | P2 | Neutraliser la marge basse héritée (`contentMargins(.bottom, 150)`, `PhoneView.swift:243`) sur la `Map` | OUVERT |
| `global-search-result-loses-results`, `global-search-results-lost` | Recherche globale | Ouvrir un résultat vide la pile ; au retour, les résultats (payés 8 s) sont perdus (`GameSession.swift:346-357`) | Double paiement | P2 | Empiler le résultat sur la recherche, ou garder la requête dans `GameSession` | OUVERT |
| `photo-analysis-result-below-fold` (+ doublon P3 game-feel) | Photo analysée | « CE QU'ON REMARQUE » arrive sous la barre du dossier | L'indice payé passe inaperçu | P2 | Défiler automatiquement jusqu'au panneau (`ScrollViewReader`) | OUVERT |
| `quit-chevron-looks-like-back` | Barre d'état | Deux « ‹ » à l'écran | — | P2 | — | RÉSOLU (V3) : bouton pause |
| `stopped-sharing-pill-misordered`, `conversation-ordre-chronologique` | Conversation Emma | La pastille « a cessé de partager · 21:31 » s'affiche sous le séparateur « 22:30 » (`MessagesViews.swift:246-262`) | Le temps paraît reculer | P2 | Afficher la pastille avant le séparateur du message suivant | OUVERT |
| `track-step-numbers-missing` | Carte › trajet | Une épingle ne porte que le 1er passage (`CaseMap.swift:59`) : les étapes 5 et 7 manquent | Trajet illisible | P2 | Numéros multiples « 3·5 » | OUVERT |
| `cost-flash-hidden-by-banner`, `cout-temps-masque` | Barre d'état | La pastille « −n s » était cachée par les bannières | Coût invisible | P2 | — | RÉSOLU (V3) : coût affiché à côté de l'étiquette du chrono, au-dessus du filet (`PhoneView.swift:405-425`) ; à confirmer sur capture |
| `timer-tag-reads-as-clock` | Étiquette du chrono | Un « mm:ss » sans libellé peut se lire comme une heure | Confusion possible | P2 → P3 | Conforme au handoff §F-05 ; à observer en test (§20, D22) | REQUIRES DECISION |
| `carte-heure-tronquee` | Carte | « lieu · jour à heure » limité à 2 lignes : l'heure est coupée | Donnée clé perdue | P2 | Lieu sur une ligne, date et heure sur la suivante | OUVERT |

**P3 (41 constats)**
- **Carte, OUVERT** : `c001-carte-epingles-superposees`, `c002-map-pins-legal`, `map-pins-overlap-no-tap`,
  `carte-epingles-superposees`, `location-sheet-cramped-fake-grabber`, `carte-liste-positions-trop-petite`,
  `carte-recentrer-et-sous-titre`, `c5-carte-col-masque-mais-connu` (lieu masqué, mais son nom est lisible gratuitement).
- **Photos** : OUVERT pour `photo-zoom-no-pan`, `photo-zoom-sans-deplacement` et `zoom-photo-pixelise` ; RÉSOLU (V3) pour
  `fullscreen-pinnable-detail-screens` (sur une photo, seule l'image est versable ; un écran entier ne grossit plus).
- **Bannières** :
  - OUVERT : `c002-home-banner-covers-date`, `banner-covers-app-header` (phone-apps et phone-shell), `banniere-masque-entete-et-retour` ;
  - OUVERT : `banner-timer-runs-during-pause` (`GameSession.pause()` n'annule pas `bannerTask`), `low-battery-banner-repeats-after-resume` ;
  - OUVERT : `urgent-pin-signals-evidence`, `banniere-urgente-glyphe-incoherent` (« ◆ » en texte) ;
  - RÉSOLU (V3) : `urgent-banner-pin-toggles` (`session.file` ne retire jamais une pièce).
- **Pastilles, messages, agenda, OUVERT** : `c5-badge-appels-manques`, `badges-never-clear`, `mail-unread-never-cleared`,
  `c001-pastille-partage-avant-heure`, `stopped-sharing-pill-order`, `messages-avatar-groupe-chiffre`,
  `mail-apercu-double-espace-avatar`, `calendar-allday-label-truncated`, `calendar-list-starts-oldest`,
  `icone-calendrier-sans-jour`, `widget-tiret-orphelin`.
- **Coque** :
  - RÉSOLU (V3) : `cost-chip-over-app-header`, `objective-absent-in-phone`, `bouton-quitter-ressemble-retour` ;
  - OUVERT : `swipe-home-from-edge`, `handoff-v1-phone-features-missing`, `contacts-section-personnes-affaire` ;
  - OUVERT : `cinq-telephones-meme-disposition`, `recherche-redondances`, `polices-tailles-en-dur` (touches du clavier en police système).

---

## 9. CARNET / PIÈCES / RÉSOLUTION

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `toast-accuses-cle-brute` (carnet-pieces), `link-toast-raw-key` | Étiquette après L'accuse / Le disculpe | Affichait « TOAST.ACCUSES » (clé brute) | Bug visible sur le geste central | P1 | — | RÉSOLU (V3) : clés ajoutées (`babe6dd`) ; `LocalizationTests` voit désormais les clés choisies par un ternaire |
| `trash-pin-reveals-deleted-message` | Corbeille → Verser | Vu et versé sans payer les 12 s ; le texte caché fuit | Contourne la règle du temps | P1 | `0fad7aa` bloque le versement dans la Corbeille. **Reste :** `Investigation.togglePin/link` accepte toujours un message supprimé non récupéré (aucune garde moteur) ; ~~la bulle « Ce message a été supprimé » reste versable~~ (corrigé ensuite : ni versement ni texte d'origine lu par VoiceOver avant récupération) | EN COURS DE CORRECTION |
| `intuition-recompensee` | Conclusion → rapport | Bon suspect sans aucune pièce = RÉSOLU (environ 69/100), niveau suivant et rang. Élimination en ≤ 4 essais, plus rapide avec [REPRENDRE L'ENQUÊTE] (pièces gardées, chrono plein) | Contredit la promesse d'enquête | P1 | §20, D6 | REQUIRES DECISION |
| `resultat-negatif-sans-sortie` | Rapport NON RÉSOLU | Impasse : « Rouvrir » ou « Solution », pas de retour | Joueur bloqué | P1 | — | RÉSOLU (V3) : [REPRENDRE L'ENQUÊTE], « Classer quand même » (→ Bureau), « Consulter la solution » |
| `passer-verification-attente-fixe`, `dossier-clos-trop-bref` | Vérification | Attente fixe de 4 s ; chemise tamponnée visible 1,5 s seulement | Rythme | P2 | — | RÉSOLU (V3) : frappe de 1,4 s, tampon PNG, puis [LIRE LE RAPPORT] à la main du joueur |
| `reconstitution-tap-bug` | Reconstitution | Les étapes réapparaissaient une à une après un tap | Bug d'animation | P2 | — | OBSOLÈTE (reconstitution affichée d'un bloc) |
| `aide-verrou-libelle` | Indice 3 | « Disponible à 02:00 » ambigu (`InvestigationView.swift:1058`) ; bug moteur : `.locked(untilRemaining: 120)` renvoyé après l'échéance si l'indice 2 n'est pas ouvert | Indice bloqué à tort | P2 | « Quand il restera 02:00 » ; renvoyer `untilRemaining: 0` quand le verrou vient de l'ordre (moteur + test) | OUVERT |
| `carnet-chrono-invisible`, `carnet-hides-running-timer` | Carnet (plein écran) | Le chrono tourne sous le Carnet mais n'y est pas affiché | Temps perdu sans le voir | P2 | Étiquette du chrono dans l'en-tête du Carnet | OUVERT |
| `exhibit-message-sans-photo` | Pièce « message » | La photo jointe disparaît : on voit « Photo » en texte (`Dossier.swift:142`) | La pièce clé m_emma_2230 est vide | P2 | Imprimer la vignette au-dessus de la bulle | OUVERT |
| `exhibit-pied-heure-tronquee`, `pieces-pied-tronque` | Carnet › pièces | L'heure était tronquée dans la grille à 2 colonnes | Info perdue | P2 | — | RÉSOLU (V3) : fiches pleine largeur « PIÈCE 01 · MESSAGE · LUCAS · 12.09 22:47 » |
| `piece-detail-absente` | Carnet | Aucune vue « pièce en détail » ; aperçus limités à 4 lignes | Relecture limitée | P2 → P3 | §20, D19 | REQUIRES DECISION |
| `vu-non-verse-inexplique` | Rapport | « Vu mais jamais versé » est confondu avec « jamais vu » | Sentiment d'injustice | P2 | §20, D18 | REQUIRES DECISION |
| `c001-dossier-statut-contradictoire` | Dossier #001 | Voir §4 | — | P2 | — | RÉSOLU (V3) |
| `c001-libelles-rapport` | Rapports | « RAPPORT DE CONCLUSION » et « Pièces clés trouvées 1/12 » | Libellés faux | P2 → P3 | Le premier a disparu ; reste le second dans le rapport archivé (`DossierView.swift:567`) : écrire « Éléments trouvés » | OUVERT (réduit par V3) |
| `c001-numerotation-pieces-conflit`, `piece-numero-1-telephone`, `piece-numero-1-double` | Dossier / pièces | Le téléphone s'appelait « Pièce n° 1 », comme la 1re pièce versée | Deux pièces n° 1 | P2 | — | RÉSOLU (V3) : le téléphone est « SCELLÉ N° 001-01 » (`CaseOpening.swift:120`) |
| `c001-reconstitution-sans-dates` | Reconstitution | Heures sans jour : 10:05 (dimanche) semble hors d'ordre | Chronologie trompeuse | P2 | Préfixe de jour quand il change (`RevealTimeline`) | OUVERT |
| `rapport-libelles-ambigus`, `found-counts-inconsistent` | Rapport archivé | « RESPONSABLE DÉSIGNÉ : Oui » ; « Pièces clés 1/12 » alors que le rapport V3 dit « Pièces clés · 1/6 » | Chiffres contradictoires | P2 | Aligner le rapport archivé sur le rapport V3 | OUVERT |
| `resultat-accords-genre` | Rapport | « LE RESPONSABLE » au-dessus d'Emma ; « trouvé » ou « manqué » au masculin | Grammaire | P2 → P3 | « LE RESPONSABLE » a disparu ; restent `a11y.found`, `a11y.missed` et « non trouvé » | OUVERT (réduit par V3) |
| `perfect-score-unreachable`, `sans-faute-impossible` | Score | La part « temps » n'atteint jamais 10 : maximum réel 99 | SANS FAUTE impossible | P2 | §20, D9 | REQUIRES DECISION |
| `resolution-admin-chain` | Fin de partie | Trois feuilles administratives à la suite | Lourdeur | P2 | — | RÉSOLU (V3) : vérification → un seul rapport |
| `result-missing-epilogue`, `epilogue-absent-du-rapport` | Rapport | L'épilogue n'était jamais montré | Pas de récompense émotionnelle | P2 | — | RÉSOLU (V3) : « CE QUI S'EST PASSÉ » (titre + résumé, conforme §F-11) ; le récit long reste aux Archives |
| `confirmation-solution-systeme` | Consulter la solution | Boîte système iOS | Hors univers | P2 | — | RÉSOLU (V3), mais voir `NEW-solution-sans-confirmation` ci-dessous |
| `formulaire-cloture-incomplet`, `verification-lignes-generiques`, `rapport-cloture-chiffres-mysteres`, `rapport-cloture-sans-signature` | Maquettes TRACE 15, 16, 19 | Formulaire, lignes de vérification, détail de la note, signature | — | P2 | — | OBSOLÈTE : écrans 09–11 redéfinis par le handoff final (§F-09 à §F-11) |
| `manque-vs-non-verse` | Rapport NON RÉSOLU | « Ce que vous avez manqué (n) » ou « Ce que vous n'avez pas vu » alors que le joueur a parfois vu sans verser | Reproche injuste | P2 | Parler de pièces « non versées » | OUVERT |
| `solution-consultee-sans-cout` | Après « Consulter la solution » | Seule la tentative ratée devient non classée. **Aggravé par V3** : sur le rapport révélé, [REPRENDRE L'ENQUÊTE] reste proposé ; la partie suivante est classée RÉSOLU et fait monter de rang (`EndScreens.swift:836`, `ProgressStore.swift:60`) | Rang obtenu en connaissant la réponse | P2 → **P1** | §20, D6 | RÉSOLU en partie (option c de D6) : après « Consulter la solution », seul [CLASSER LE DOSSIER] reste ; (a) et (b) restent à décider |
| `manuscrit-ecrit-par-le-jeu` | Carnet, conclusion | Le jeu écrivait en Caveat à la place du joueur | Règle d'auteur violée | P2 | — | RÉSOLU (V3) : Caveat ne sert plus qu'à l'état vide des Archives |
| `rapport-conclusion-vs-cloture`, `verification-selection-masquee` | Fin de partie | Deux rapports aux noms voisins ; la fiche choisie était masquée | — | P2 | — | RÉSOLU (V3) |
| `NEW-solution-sans-confirmation` (nouveau) | Rapport NON RÉSOLU | « Consulter la solution » révèle tout et déclasse la tentative dès le premier tap, sans confirmation (`RootView.swift:250`, `475`) | Spoil irréversible par mégarde | P3 | Feuille papier de confirmation (comme la pause) | RÉSOLU : feuille papier « Consulter la solution ? » (la partie ne compte pas, le dossier peut être rejoué plus tard) |

**P3 (50 constats)**
- **RÉSOLU (V3)** :
  - `rythme-resolution-trop-long`, `verification-skip-son-fantome` (les tâches vérifient l'annulation) ;
  - `retirer-sans-garde` (« Retirer du dossier » est un lien séparé) ;
  - `aide-ouverture-un-tap` : un bouton explicite qui affiche son coût en points, conforme §F-14 ;
  - `banniere-urgente-toggle`, `onglets-petits-ecrans` (3 onglets), `verification-bouton-instruction` ;
  - `rapport-conclusion-doublon` (content-strings), `piece-01-collision`, `piece-numero-1-double-meaning`, `piece-number-collision` ;
  - `rouvrir-vs-rejouer`, `fin-de-saison-silencieuse` (feuille « Tous les dossiers sont classés ») ;
  - `carnet-annotation-coupee`, `chronologie-typo-alignement`, `carnet-entete-redondant`, `resultat-hierarchie-typo`.
- **OBSOLÈTE** (Carnet et fin de partie redessinés) : `connexions-etiquettes-muettes`, `hypothese-absente`,
  `disculpe-incoherent-carnet`, `principal-auto`, `arrondi-temps-restant`, `chrono-arrete-libelle`,
  `temps-ecoule-hierarchie`, `aide-enveloppe-ficelle-sceau`, `clore-maintenant-vide`, `verification-surtitre-coupe`,
  `rapport-sans-visa-marque`.
- **REQUIRES DECISION** : `lien-unique-par-piece` (le handoff veut plusieurs suspects par pièce, le moteur un seul : D26),
  `c001-question-vs-objectif` et `question-vs-objectif` (D12), `c001-resolu-avec-une-piece` (D6), `pin-everything-dominant` (D7).
- **OUVERT** :
  - heure des pièces : `live-message-heure-json`, `live-message-wrong-time-in-dossier` (heure du JSON au lieu de l'heure d'arrivée) ;
  - numérotation : `renumerotation-pieces`, `piece-numbers-shift-on-removal` (retirer une pièce renumérote les suivantes) ;
  - précision du score : `precision-photoinfo-asymetrie`, `precision-photoinfo-asymmetry` (photo et analyse traitées de façon asymétrique) ;
  - `aide-note-maximale-fausse` (« Note maximale actuelle » ignore le temps) ;
  - Carnet : `retrait-lien-silencieux`, `onglet-carnet-non-memorise`, `fiche-suspect-sans-titre`, `doublons-photo-analyse-message` ;
  - rapport archivé : `c001-archive-tout-trouve` (toutes les étapes y sont cochées), `c002-story-grace-unsolved`,
    `c5-reconstitution-grace-a-votre-enquete` (« Grâce à votre enquête » après un échec) ;
  - `quatrieme-mur-le-jeu` (« le jeu ne les vérifie pas », `InvestigationView.swift:853`) ;
  - `verdict-not-persisted-reveal-lost` ;
  - `solution-promise-inaccessible` (le rapport archivé promet « consultez la solution » sans bouton, `DossierView.swift:604`).

---

## 10. VISUEL

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `night-photos-render-daylight`, `c003-night-photos-rendered-daylight` | Photos #003, #005, #001 | Le style « night » était peint en plein jour (Voie lactée sur ciel bleu) | Fausses pistes, effet prototype | P1 | `0fad7aa` : « nuit américaine » (désaturation, bleu nuit, lumières de la scène conservées, étoiles), `GeneratedPhoto.swift`. À vérifier sur captures : série de Louise 02:06, 02:14, 02:27 (trois scènes différentes pour un même trépied) | EN COURS DE CORRECTION |
| `photos-procedurales-placeholder` (visual-phone), `evidence-photos-contradict-captions`, `photos-preuves-contredisent-legende`, `c002-key-photos-indistinct` | Photos, 5 affaires | Dessins procéduraux : le même décor d'une affaire à l'autre, des légendes qui décrivent des personnes jamais dessinées, les photos clés impossibles à distinguer | C'est la première impression « maquette » du téléphone, et l'action payante « Analyser » perd son sens | P1 | Photos générées (voir §19). En attendant, en code : scènes dédiées hôpital, lits superposés, régie, cabine DJ rouge ; ne jamais réutiliser une scène de preuve | BLOQUÉ – ASSETS |
| `cinematic-broadcast-placeholder-silhouette`, `cinematique-placeholders-vectoriels`, `cinematic-tag-caption-overlap`, `c001-cine-etiquette-chevauche-soustitre`, `cinematique-appel-rogne`, `cinematique-sous-titre-sur-scelle`, `cinematique-sans-point-d-accroche-media` | Cinématiques | Plans vectoriels, chevauchements, pas de lecteur vidéo | — | P1 / P2 | — | OBSOLÈTE (cinématiques retirées ; ouverture courte « sachet → téléphone » dans `CaseOpening.swift`) |
| `loading-art-low-res-and-baked-text`, `loading-art-basse-resolution`, `chargement-vs-bureau-rupture`, `onboarding-demo-photo-cartoon` | Chargement, onboarding | Image de chargement basse résolution avec texte incrusté ; photo de démo cartoon | — | P2 | — | OBSOLÈTE (`loading_main.jpg` supprimé : écran 01 = tuile logo sur #0A0908) |
| `overline-typography` | Bureau | Surtitres en minuscules espacées | — | P2 | — | RÉSOLU (V3) |
| `textures-stamps-not-integrated`, `papier-textures-plates`, `tampons-vectoriels` | Papier, tampons | Textures et tampons encrés livrés mais non intégrés | Papier plat | P2 | — | RÉSOLU (V3) : `tex_paper_grain` et `tex_kraft_fibers` en tuile ; PNG RÉSOLU, NON RÉSOLU, 4 rangs, sceau et signature (`Art.xcassets/Stamps`) |
| `tampons-verdict-trop-petits` | Vérification, rapport | Tampon de verdict de 10–13 pt | Se lisait comme un badge | P2 | — | RÉSOLU (V3) : PNG de 220 pt qui tombe, 84–100 pt en tête du rapport |
| `tampons-trop-petits` | Archives, niveaux, fiche suspect, rapport archivé | Il reste des tampons vectoriels de 8 à 10 pt (`MetaScreens.swift:68`, `DeskScreens.swift:545-546`, `InvestigationView.swift:720`) | Illisibles | P2 → P3 | ≥ 22 pt, ou libellé tapé | OUVERT (réduit par V3) |
| `manuscrit-voix-du-jeu` | Conclusion | Phrases du jeu en Caveat | — | P2 | — | RÉSOLU (V3) |
| `agrafes-comme-poignees` | Papier | Agrafe dessinée comme une poignée de feuille iOS | — | P2 → P3 | Une seule reste, sur la fiche suspect (`InvestigationView.swift:694`) | OUVERT (réduit par V3) |
| `placeholder-portrait-style-app`, `portrait-repli-tuile-app` | Carnet › Suspects, fiche suspect | Sans portrait, on voit une tuile d'icône d'app rayée. V3 a appliqué le repli §N (initiales Newsreader sur bleu BEN) au Bureau, au briefing, à la conclusion et au profil, **mais pas à `IDPhoto`** (`TraceDesign.swift:288`, `Dossier.swift:303`, `InvestigationView.swift:709`) | Deux styles de repli coexistent | P2 | Faire passer `IDPhoto` par `PortraitOrInitials` | RÉSOLU : `IDPhoto` passe par `PortraitOrInitials` |
| `c004-procedural-necklace-contradicts-clue` | Photos #004 | Le collier procédural a toujours 41 perles, fermoir visible, zoomable ×4 | Contredit « 43 perles, trop loin pour compter » | P2 | Rang flou non comptable | OUVERT |
| `document-text-overflows-paper`, `photo-document-texte-deborde` | Photos de documents | Le texte déborde de la feuille | Illisible, amateur | P2 | Retour à la ligne ou réduction, découpe à la feuille | OUVERT |
| `screenshot-scene-hardcoded-941`, `photo-capture-heure-941` | Captures dans Photos | Toujours « 9:41 » dans la barre d'état | Incohérence | P2 | Afficher `takenAt` | OUVERT |
| `photo-asset-hook-absent` | Photos | `ArtLibrary` ne cherche aucun `photo_<NNN>_<id>` : une photo livrée ne s'afficherait pas | **Prérequis** à l'intégration des photos | P2 | `ArtLibrary.photo(case:id:)`, repli sur le procédural (même principe pour les fonds d'écran) | OUVERT |
| `double-island-phone-in-phone` | Téléphone | Téléphone dessiné dans le vrai téléphone : deux îlots | Perte de place, étrangeté | P2 | §20, D21 | REQUIRES DECISION |
| `pieces-supports-simples` | Pièces | Supports simples (capture sur bande noire) | Esthétique | P2 → P3 | §20, D20 | REQUIRES DECISION |
| `fonds-ecran-degrades` | Accueil du téléphone | Fonds en dégradés | Téléphone générique | P2 | 5 fonds photo (§19) | BLOQUÉ – ASSETS |

**P3 (36 constats)**
- **RÉSOLU (V3)** :
  - `coupe-seche-telephone-accusation` (fondu), `aide-manuscrite-jeu`, `polices-couleurs-en-dur` (chronologie) ;
  - `annotation-rognee`, `manuscrit-ecrit-par-le-jeu` (content-strings), `game-handwriting-rule` ;
  - `brand-wordmark-inconsistent` (dérivés du logo maître §H) ;
  - `timer-tag-low-state-spec` (étiquette rouge sous 01:00) ;
  - `dossiers-meme-composition`, `rapports-papier-ligne` (plus de papier ligné) ;
  - `sdk26-system-alert-style` (feuilles papier au lieu d'alertes).
- **OBSOLÈTE** : `anneau-verse-forme` (remplacé par l'étiquette « PIÈCE 0N »), `caption-and-place-wrapping`,
  `folder-sheet-strip-glitch`, `caveat-lacaze-conflit`, `cinematique-etiquette-rognee`, `cinematique-titre-lieu-coupure`.
- **OUVERT** :
  - tokens et identité : `tokens-motion-dupliques`, `accent-color-off-palette` (cyan #64D6FF dans `AccentColor`) ;
  - icône : `app-icon-small-sizes-variants` (pas de variantes sombre et teintée) ;
  - `extrait-carte-factice` ;
  - `c001-titre-casse` : le rapport et la vérification affichent « LE DERNIER MESSAGE » en capitales, le briefing
    « Le dernier message » (`EndScreens.swift:561`, `616`) ;
  - photos : `c002-screenshot-941`, `c003-terrace-pines-in-water`, `c003-old-style-on-digital-photos` ;
  - polices : `glyphes-absents-polices` ;
  - repli de portrait : `portrait-fallback-app-tile` ;
  - téléphone : `tabbar-icons-contrast`, `group-avatar-digit-placeholder`, `calls-missed-triple-red`,
    `trash-redacted-looks-loading`, `double-bottom-inset` (150 pt de `contentMargins` + `.padding(.bottom, bottomInset)`),
    `same-home-layout-all-phones` ;
  - papier : `ombres-papier-sur-papier`, `ui-ios-sur-papier`, `pieces-couleurs-en-dur` (`Dossier.swift:252-262`).

---

## 11. AUDIO / HAPTIQUE

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `audio-warmup-coupe-musique-joueur` | Lancement | `AudioDirector.warmUp()` prépare 10 lecteurs **avant** de poser la catégorie `.ambient` + `.mixWithOthers`, sans vérifier le réglage « Effets sonores » (`AudioDirector.swift:57-61`, appelé par `LaunchScreen.swift:71`) | Peut couper la musique ou le podcast du joueur à chaque lancement, même son coupé | P1 | Poser la catégorie une fois, dans `init()`, avant toute préparation ; ne rien précharger si les sons sont désactivés | RÉSOLU (après V3, `AudioDirector.warmUp` pose d'abord la session « ambient, mix with others ») |
| `chrono-seuils-muets` | Chrono | Rien à 00:10 | — | P2 | — | RÉSOLU (V3) : tic sous 01:00, haptique légère sous 00:10 (`GameSession.swift:241-248`) |
| `maintien-cloture-sans-retour` | Conclusion | Maintien de 1,2 s sans retour | — | P2 | — | RÉSOLU (V3) : haptique légère au début, rigide à la fin (conforme §L) |
| `tampon-inaudible-haut-parleur` | Vérification, affectation | `stamp.wav` (sinus 90 Hz) presque inaudible sur le haut-parleur de l'iPhone ; même son pour RÉSOLU et NON RÉSOLU | Le moment fort tombe à plat | P2 | Régénérer le son (180–400 Hz + attaque 1–4 kHz) ou livrer `stamp_heavy` (§19) | OUVERT |
| `pas-d-ambiance-hors-cinematique` | Bureau, briefing, rapport | Aucune ambiance hors téléphone (le handoff §K prévoit `office_room` à −30 dB et une nappe grave au briefing et au rapport) | Silence | P2 → P3 | Livrer `office_room` et la nappe (§19) | BLOQUÉ – ASSETS |
| `mix-ambiances-desequilibre`, `temps-ecoule-jingle-info` | Cinématiques, TEMPS ÉCOULÉ | Mixage des ambiances ; jingle d'info à la fin du temps | — | P2 | — | OBSOLÈTE (plus d'ambiances jouées ; `TimeUpView` supprimé) |
| `voix-langue-et-desynchro`, `voice-language-follows-ui-not-case`, `c002-tts-voice-locale`, `voix-reporter-en-gb`, `tts-voice-english-on-french-text`, `voix-anglaise-texte-francais`, `tts-robotic-reporter-voice`, `voix-synthese-robotique` | Répliques voisées | Voix de synthèse anglaise ou robotique | — | P2 | — | OBSOLÈTE (`AudioDirector.speak` n'est plus appelé) |

**P3 (15 constats)**
- **RÉSOLU (V3)** :
  - `taches-annulees-sons-fantomes` ;
  - `coherence-haptique-actions` (table §L appliquée) ;
  - `tampon-son-avant-impact` (le son part à l'impact, `ConcludeKit.swift:255-257`) ;
  - `frappe-mecanique-reguliere` (1,4 s, conforme §F-10) ;
  - `mode-silencieux-coupe-tout` (conforme §K : « tous les sons respectent le commutateur silencieux ») ;
  - `maintien-retour-haptique`.
- **OBSOLÈTE** : `passer-cinematique-coupure-nette`, `vibreur-cinematique-un-seul-coup`, `c004-tts-wrong-language`,
  `test-noms-sons-affaires`, `note-finale-sans-impact` (`ScoreView` supprimé), `reglage-sons-unique` (seuls des effets restent).
- **OUVERT** :
  - `notifications-haptique-par-niveau` : haptique sur toutes les notifications, y compris les normales (`GameSession.swift:198`) ;
  - `bannieres-son-apres-fin-enquete` : les bannières en file ne sont pas annulées à la fin ;
  - `resolu-non-resolu-meme-son`.

---

## 12. ACCESSIBILITÉ

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `reduce-motion-setting-ignored`, `reduire-animations-deux-sources` | Tout le jeu | Le réglage « Réduire les animations » du jeu n'était lu que par `RootView` | Réglage sans effet | P2 | — | RÉSOLU (V3) : système OU réglage du jeu partout, fondus de 200 ms |
| `pin-only-via-context-menu` | Téléphone, Carnet | Verser ou relier était impossible sans appui long | VoiceOver bloqué | P2 | — | RÉSOLU (V3) : action « Verser au dossier » sur chaque élément ; L'ACCUSE / LE DISCULPE et Retirer en actions VoiceOver des pièces |
| `notebook-pieces-truncated` | Carnet | Pièces tronquées en 2 colonnes | — | P2 | — | RÉSOLU (V3) |
| `sealed-hint-envelope-unreadable`, `unguarded-motion-and-flashing` | Enveloppe d'indice, cinématiques | Contraste de l'enveloppe ; flashs non protégés | — | P2 | — | OBSOLÈTE |
| `dynamic-type-fixed-heights` | Téléphone | Aucun plafond Dynamic Type ; hauteurs fixes (lignes de 78 pt, barres) | Textes coupés en très grande taille | P2 | Les écrans papier V3 passent en 1 colonne en AX (réduit). Reste le téléphone : plafonner la coque à `.xxxLarge`, `minHeight` au lieu de hauteurs fixes. Critère 17 du handoff (AX3 sur SE) à vérifier | OUVERT (réduit par V3) |
| `inkfaint-used-for-active-text`, `locked-level-contrast` | Niveaux | « Résolvez l'affaire en Détective… » en `inkFaint` à 50 % d'opacité, soit environ 1,7:1 (`MetaScreens.swift:52`, `65`, `77`) | Illisible | P2 (P3 pour inkfaint) | `inkSoft` à pleine opacité | OUVERT (réduit par V3 : les autres usages ont disparu) |
| `contraste-textes-papier` | Kraft | `kraftLabel` sur kraft : 3,8:1 | Petit texte faible | P2 → P3 | Foncer le jeton ou réserver ce texte au décoratif | OUVERT (réduit par V3) |
| `lock-keypad-a11y-feedback` | App verrouillée | « ⌫ » sans libellé ; nombre de chiffres saisis non annoncé ; code faux signalé par une secousse seulement | VoiceOver perdu | P2 | Libellé « Effacer », valeur « n chiffres sur 4 », texte et annonce « Code incorrect » | OUVERT |
| `no-voiceover-announcements` | Téléphone | Aucune annonce du coût, de la pièce versée, du temps faible ni de la fin (seules les bulles du tutoriel le sont) | Info uniquement visuelle | P2 | `AccessibilityNotification.Announcement` dans `GameSession` | OUVERT (réduit par V3) |
| `photo-thumbnails-no-a11y-label` | Photos (grille) | Vignettes annoncées « Bouton » sans nom | VoiceOver inutilisable dans Photos | P2 | Libellé neutre « Photo, jour, heure » | OUVERT |
| `tap-targets-under-44pt` | Divers | Cibles < 44 pt | Précision | P2 | Réduit (le chrono n'est plus une cible ; filtres des Archives à 44 pt). Restent « Messages plus anciens » (32 pt, `MessagesViews.swift:232`) et les puces de recherche | OUVERT (réduit par V3) |
| `voiceover-reads-deleted-message` | Conversation | VoiceOver lit le texte d'un message que l'écran dit supprimé (`MessagesViews.swift:452`) | Fuite + incohérence | P2 | Libellé selon l'état | OUVERT |

**P3 (30 constats)**
- **RÉSOLU (V3)** :
  - `non-scrollable-screens-small-large-text` (Paramètres défilants ; clavier dans `0fad7aa`), `settings-no-scroll` ;
  - `label-in-name-mismatch`, `pastille-enq-non-localisee` ;
  - `hold-to-close-voiceover-semantics`, `voiceover-cloture-sans-garde` (VoiceOver ou Switch Control : bouton + feuille de confirmation, `EndScreens.swift`) ;
  - `timer-voiceover-state` (« 4 minutes et 12 secondes ») ;
  - `few-headers-and-glyph-labels` (25 en-têtes déclarés) ;
  - `tilts-handwriting-legibility-default`, `a11y-etat-verse` (étiquette « PIÈCE 0N » libellée) ;
  - `reduire-animations-supprime-verdict`, `reduce-motion-setting-ignored-intro`, `reglage-reduire-animations-ignore`.
- **OBSOLÈTE** : `cinematic-lower-third-contrast`, `cinematique-004-flash-rapide`.
- **REQUIRES DECISION** : `phone-in-phone-usable-area` (D21).
- **OUVERT** :
  - contrastes : `bone3-overlines-tabbar-contrast` (onglets inactifs), `kraft-label-token-contrast`,
    `text-tertiary-critical-info`, `sent-bubble-contrast` (3,67:1), `low-contrast-cost-texts` ;
  - libellés VoiceOver : `locked-app-and-hint-state-not-announced`, `mentions-and-calendar-a11y-semantics`, `a11y-badge-lock-labels` ;
  - tailles : `stamps-below-min-size-fixed`, `small-tap-targets`, `fixed-row-heights-dynamic-type` ;
  - bannières : `banner-timeout-and-urgent-escape` ;
  - Photos : `photo-grid-no-a11y-label` ;
  - app verrouillée : `lock-screen-feedback-a11y`.

---

## 13. PERFORMANCE

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `artlibrary-cache-memoire` | Lancement, tous les écrans | `ArtLibrary.warmUp` décode les portraits en pleine résolution sur le MainActor et les garde à vie (cache sans limite) | Sans effet aujourd'hui (2 portraits). Avec environ 60 portraits et 200 photos : pics mémoire et saccades | P2 | Vignettes à la taille d'affichage, hors du fil principal, dans un `NSCache` purgé sur alerte mémoire | OUVERT |

**P3 (9 constats)**
- **RÉSOLU (V3)** : `papergrain-canvas-couteux` (texture en tuile, le Canvas ne sert plus qu'en secours),
  `phoneview-rafraichi-4hz` et `phoneview-rerender-4hz` (seule la barre d'état lit le temps restant).
- **OBSOLÈTE** : `dossier-investigation-rebuilt`, `dossier-rebuilds-investigation-each-render` (le briefing ne
  reconstruit plus le moteur).
- **OUVERT** :
  - `generatedphoto-rendu-non-cache`, `recherche-globale-non-lazy`, `fond-ecran-flou-80` ;
  - `poids-sons-format` : **nouveau depuis V3**, 16 WAV d'ambiance et de cinématique (street, sirens, metro, sea…) et la
    police Instrument Serif ne sont plus utilisés mais restent dans l'app.

---

## 14. SAUVEGARDE

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `save-lost-starting-other-case`, `starting-other-case-wipes-save` | Lancer une autre affaire | L'enquête en cours d'une autre affaire était effacée sans avertissement | Perte de progression silencieuse | P1 | `0fad7aa` : feuille « Une autre enquête est en cours » (Commencer quand même / Annuler), `RootView.start`/`begin` ; testée par le test UI des affaires #002–#005. À valider en CI iOS | EN COURS DE CORRECTION |
| `progressstore-corruption-wipes-history` | Historique | `ProgressStore.attempts()` renvoie `[]` au moindre échec de décodage (`ProgressStore.swift:51`), puis `record` réécrit le tout | Tout l'historique (rangs, déblocages) perdu | P2 | Décoder élément par élément ; copier les données illisibles dans une clé de secours avant d'écrire | OUVERT |

**P3 (4 constats)**
- **OUVERT** :
  - `resume-level-not-shown` : le niveau de l'enquête en cours n'est pas affiché ;
  - `resume-silent-failure` : une sauvegarde illisible est effacée sans rien dire (`RootView.resumeSaved`) ; le handoff §N prévoit le post-it « Votre dossier n'a pas pu être relu » ;
  - `snapshot-no-ref-validation-no-migration`.
- **RÉSOLU** : `save-cadence-observation` (constat toujours vrai : sauvegarde atomique environ toutes les 5 s et à chaque changement).

---

## 15. ERREURS / FALLBACKS

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `portraits-suspects-mixtes` | Conclusion 09, Carnet, briefing #001 | #001 : Sarah et Karim ont une vraie photo, Lucas et Emma (la coupable) des initiales. **Plus visible en V3**, sur la grille « QUI EST RESPONSABLE ? » | Le visuel désigne la solution ; aspect « maquette » | P1 | §20, D5 (règle « tout ou rien » par affaire en attendant les portraits) | REQUIRES DECISION |

**P3 (9 constats)**
- **RÉSOLU (V3)** : `load-error-raw-debug-text`, `erreur-chargement-brute`, `erreur-chargement-texte-technique`. Le
  post-it « FICHIER ENDOMMAGÉ » affiche un texte lisible ; le détail technique n'apparaît qu'en Debug (`RootView.DamagedFileView`).
- **OBSOLÈTE** : `cinematique-arriere-plan-interruptions`.
- **OUVERT** :
  - `one-bad-case-blocks-game-raw-error`, `launch-error-dead-end` : une seule affaire illisible vide toute la liste,
    sans bouton RÉESSAYER (`LaunchScreen.swift:68`) ;
  - `fallbacks-silent` ;
  - `mapkit-offline-behaviour`, `carte-hors-ligne` : hors ligne, les tuiles restent vides. Le critère 19 du handoff
    (« Mode avion : le parcours complet fonctionne ») est donc à vérifier ; la carte stylisée `CityMap` existe et peut
    servir de repli.

---

## 16. BUILD / RELEASE

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `public-repo-exposes-solutions-ipa` | GitHub | Dépôt public : solutions, art, IPA signée en artefact, captures sur `ci/ui-screenshots` | Spoilers, copie | P1 | §20, D4 | REQUIRES DECISION |
| `ui-tests-no-small-screen-no-a11y-audit` | CI iOS | Un seul simulateur (le plus grand non Pro), pas de grande taille de texte, pas d'audit d'accessibilité | Régressions invisibles (le clavier en est la preuve) | P2 | Matrice SE + grand, lancement en `AccessibilityL`, `performAccessibilityAudit()` | OUVERT |
| `testflight-not-gated-untested-configs` | TestFlight | L'envoi ne dépend pas des tests UI | Build cassée envoyée aux testeurs | P2 | §20, D25 | REQUIRES DECISION |
| `tests-carnet-couverture`, `test-localisation-cles-dynamiques` | Tests | Les clés choisies par un ternaire échappaient au test | — | P2 → P3 | Ternaires couverts (`babe6dd`). Restent les familles interpolées (`rank.\(key)`, `challenge.\(level)`, `hints.what\(n)`), à énumérer depuis les enums | OUVERT (réduit par V3) |
| `ci-ios17-18-non-teste` | CI iOS | Minimum iOS 17, tests seulement sur iOS 26 | Branches iOS 17–18 (transition zoom, `onGeometryChange`…) jamais exécutées | P2 | Seconde destination iOS 17 ou 18 | OUVERT |
| `phone-apps-ui-test-gaps` | Tests UI | Aucun test ne tape un code, ne récupère un message, ne charge l'historique… | Le P0 du clavier est passé inaperçu | P2 | Test « tour des interactions du téléphone » (le code 1609 en premier) | OUVERT |
| `test-ui-enqueteur-absent` | Tests UI | Profil et Paramètres jamais ouverts | — | P2 | — | RÉSOLU (V3) : `testFirstLaunchToTheBureau`, `testSettingsRelaxedTime` |

**P3 (26 constats)**
- **RÉSOLU (V3)** :
  - `design-integration-obsolete`, `doc-integration-profil` (section « V3 » de `DESIGN_INTEGRATION.md`) ;
  - mots interdits : `mots-interdits-test`, `tests-guard-and-snap`, `forbidden-words-test-missing`, `test-mots-interdits` (`bannedWordsAreGone`) ;
  - `first-launch-not-covered-by-ui-tests`, `tests-captures-ecrans-papier` ;
  - `sons-tick-mort-wav` (le tic est joué) ;
  - `engine-build-and-caselint-green` (constat toujours vrai : 70 tests Linux, CaseLint valide les 5 affaires).
- **OBSOLÈTE** : `c004-ui-test-black-capture`, `test-captures-fin-ouverture-vides`.
- **OUVERT** :
  - `marketing-version-0-2-0` : `MARKETING_VERSION = 0.2.0` ; passer à 1.0 pour la sortie ;
  - `repo-hygiene-pycache-gitignore` : `scripts/ci/__pycache__/asc.cpython-311.pyc` versionné ;
  - `workflows-permissions-node20` : pas de bloc `permissions:` dans `ios-testflight.yml` ni `tests-linux.yml` ;
  - `docs-outdated-screenshot-names` : `TESTFLIGHT_SETUP.md` et `README.md` disent encore « SCREENSHOT » ;
  - tests : `c003-ui-test-coverage`, `tests-ui-reessais-masquent-taps-perdus`, `tests-cannot-catch-unreachable-evidence`,
    `tests-miss-dynamic-keys-and-unlock` (le code n'est toujours pas tapé), `tests-resolution-lacunes` ;
  - code mort : `dead-code-archived`, `code-mort-resolution` (`Stage.archived`, `ArchivedCaseView`, `HoldToConfirmButton`,
    `FallingStamp`) ;
  - poids : `polices-inutilisees` (Instrument Serif désormais inutilisée), `images-joueurs-inutilisees` (`npc_lacaze` jamais affiché),
    `budget-integration-handoff`.

---

## 17. APP STORE / TESTFLIGHT

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `asc-app-name-trace` | App Store Connect (app 6815301974) | La fiche s'appelle « TRACE: Case Files » : c'est ce nom que voient les testeurs TestFlight | Nom interdit publié tel quel | **P0** | Renommer en « CONCLUDE : ENQUÊTES » (Informations sur l'app › Nom), français en langue principale. Le SKU TRACE-001 peut rester | BLOQUÉ – EXTERNE |
| `store-privacy-policy-support-url` | App Store Connect | Ni politique de confidentialité, ni URL d'assistance, ni contact | Soumission impossible | **P0** | Rédiger (aucune donnée collectée, sauvegarde locale, cartes Apple Plans), héberger (site du studio ou GitHub Pages), renseigner | BLOQUÉ – EXTERNE |
| `store-privacy-label-data-not-collected` | Confidentialité de l'app | Étiquette non remplie | Soumission impossible | **P0** | « Données non collectées », suivi : non. `PrivacyInfo.xcprivacy` est déjà conforme | BLOQUÉ – EXTERNE |
| `store-age-rating` | Classification par âge | Questionnaire non rempli | Soumission impossible | **P0** | Réponses préparées dans l'audit (thèmes matures légers, violence évoquée, alcool, pas de web réel) ; cible 13+ ou 16+ (§20, D1) | BLOQUÉ – EXTERNE |
| `store-screenshots-missing` | Fiche App Store | Aucune capture | Soumission impossible | **P0** | « Stagiaire » a disparu, mais portraits mélangés ou initiales et photos procédurales. Produire 3 à 10 captures 6,9″ (§19) après la décision D5 | BLOQUÉ – ASSETS |
| `store-metadata-missing` | Description, sous-titre, mots-clés, catégorie, copyright | Rien n'est rédigé ni décidé | Soumission impossible | **P0** | §20, D1 | REQUIRES DECISION |
| `in-app-about-privacy-version` | Paramètres › À propos | Pas de version, de crédits, de lien vers la politique ni de contact | Règle 5.1.1(i), retours testeurs | P1 | V3 a ajouté la tuile, « NOREL GAMES » et « Version x (build) » (`MetaScreens.swift:253-282`). **Reste :** lien vers la politique et contact, qui attendent l'URL ; crédits OFL | BLOQUÉ – EXTERNE (réduit par V3) |
| `seller-individual-account-dsa` | Vendeur / DSA (UE) | Compte individuel ; statut de professionnel UE non déclaré | Pas de sortie en France sans statut DSA ; coordonnées personnelles publiées | P1 | Choisir compte individuel ou organisation (D-U-N-S NOREL GAMES) ; déclarer le statut DSA avec des coordonnées professionnelles | BLOQUÉ – EXTERNE |
| `store-languages-en-vs-french-cases`, `anglais-interface-contenu-francais` | Langues | Interface fr + en, mais les 5 affaires sont uniquement en français | Promesse non tenue, risque 2.3 et avis négatifs | P1 | §20, D2 | REQUIRES DECISION |
| `tarification-disponibilite` | Tarifs et disponibilité | Prix et territoires non choisis | Soumission impossible | P1 | §20, D3 | REQUIRES DECISION |

**P3 (7 constats)**
- **RÉSOLU (V3)** : `icone-plaque-integree` (icône recadrée depuis `docs/brand/logo_conclude_master.png` selon §H ; à contrôler à l'œil sur l'écran d'accueil).
- **BLOQUÉ – EXTERNE** : `etiquettes-accessibilite-app-store` (déclarer dans ASC les fonctions d'accessibilité réellement prises en charge).
- **OUVERT** :
  - `apple-ui-imitation-review-risk`, `ressemblance-ios-guideline-525`, `fictional-phone-is-real-iphone` : le téléphone
    fictif imite iOS et affiche « iPhone 13 » ; risque 5.2.5 faible. Préparer une note pour la revue et éviter le mot « iPhone » ;
  - `device-availability-ipad-vision-mac` : iPhone seulement ; décider si l'app est proposée sur iPad en compatibilité ;
  - `credits-norel-absent` : réduit par V3 (studio et version présents), crédits OFL absents.

---

## 18. CONTENU / TEXTES

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `toast-accuses-cle-brute` (content-strings) | Étiquette de lien | Clé brute affichée | — | P1 | — | RÉSOLU (V3) (`babe6dd`) |
| `service-ben-signature`, `signature-rapport-hors-fiction` | Rapport, Bureau | « bureau des enquêtes numériques » en minuscules ; rapport signé « CONCLUDE : ENQUÊTES » | Hors fiction | P2 | — | RÉSOLU (V3) : pied de rapport supprimé ; « BUREAU DES ENQUÊTES NUMÉRIQUES » en capitales sur l'écran 12 |
| `vocab-rapport-de-conclusion` | Rapport | « RAPPORT DE CONCLUSION » hors vocabulaire | — | P2 | — | RÉSOLU (V3) |
| `onboarding-vocabulary-not-locked` | Onboarding | Vocabulaire ancien | — | P2 | — | OBSOLÈTE |
| `appreciation-commandant-absente` | Rapport | Pas d'« appréciation du commandant » (maquette TRACE 19) | — | P2 | — | OBSOLÈTE (absente de la spécification du rapport V3, §F-11) |
| `fictional-numbers-emails-real-ranges` | Affaires | Numéros fictifs dans des plages réellement attribuées ; vrais domaines et marques | Risque juridique et réputationnel | P2 | §20, D24 | REQUIRES DECISION |
| `level-rank-name-collision` | Niveaux | Voir §5 | — | P2 | §20, D11 | REQUIRES DECISION |
| `vocabulaire-metriques-incoherent` | Profil, rapports | « MEILLEUR SCORE », « PREUVES TROUVÉES », « Pièces clés trouvées », « Indices » : plusieurs mots pour la même chose | Flou | P2 → P3 | Un terme par notion (« Meilleure note », « Pièces clés trouvées ») | OUVERT (réduit par V3) |

**P3 (46 constats)**
- **RÉSOLU (V3)** :
  - numérotation : `toast-numero-format`, `formats-numeros-incoherents` (« PIÈCE 0N » partout) ;
  - supérieur anonyme : `superviseur-lacaze`, `plis-superviseur-lacaze`, `aide-plis-superviseur-anonyme` ;
  - `c003-status-open-vs-not-opened` ;
  - `cles-inutilisees` (214 clés mortes supprimées) ;
  - `vocab-timer-hint-en-piece` ;
  - `rapport-conclusion-doublon` (resolution), `responsable-genre`.
- **OBSOLÈTE** : `handoff-04-rang-recrue` (document de cinématique non utilisé).
- **REQUIRES DECISION** : `question-vs-objectif` (resolution) → D12.
- **OUVERT** :
  - textes des affaires, #001 : `c001-ticket-total-faux` (18,50 € contre 23,40 €), `c001-meteo-jours-manquants`,
    `c001-partage-dix-minutes`, `c001-mail-comptable-grammaire`, `c001-heures-soleil`, `c001-domaines-reels`,
    `c001-doc-duree-affaires` ;
  - #002 à #005 : `c002-french-nbsp`, `c003-reveal-and-verdict-wording`, `c004-iris-journaliste`, `c004-cue-misquote`,
    `c004-real-looking-domains`, `c5-grammaire-meme-personne` (« Ce ne sont pas la même personne »),
    `c5-distances-incoherentes`, `c5-age-leo`, `c5-pot-lina-date`, `c5-alibi-julien-1720`, `c5-note-trajet-moteur` ;
  - catalogue, typographie et traduction : `typographie-francaise` (aucune espace insécable), `pluriels-manquants`,
    `traductions-en-incoherentes` (« Piece »), `mails-e-mails-courriel`, `case-number-format`, `search-help-wording`
    (« agenda » ; exemples français dans l'aide anglaise), `preview-double-spaces-and-subtitles`, `calendar-created-at-in-notes` ;
  - textes de fiction et d'interface : `vocabulaire-pieces-note-aide`, `vocabulaire-etats-service`, `copie-quatrieme-mur`,
    `fiche-suspect-textes-meta` (« le jeu ne les vérifie pas »), `report-locked-impossible-action`,
    `epilogue-incoherent-apres-revelation`, `verdict-suspect-non-affiche` (le champ `verdict` des suspects n'est affiché
    nulle part), `code-mort-chaines` (`toast.linked`, `toast.linkedDetail` via un `GameSession.link` inutilisé).

---

## 19. ASSETS MANQUANTS

**Tableau des constats (section 19 de l'audit)**

| ID | Écran | Problème | Impact | Priorité | Solution | Statut |
|---|---|---|---|---|---|---|
| `portraits-mixtes-carnet`, `c001-portraits-melanges-fuite`, `suspect-portraits-asymmetric`, `portraits-coupables-absents`, `portraits-manquants`, `portraits-avatars-manquants`, `subject-portraits-missing`, `c003-portraits-missing`, `c004-portraits-missing`, `c002-portraits-missing`, `c5-portraits-absents`, `victim-placeholder-first-dossier` | Briefing, Bureau, Carnet, conclusion, profil | 2 portraits sur 33 (Sarah et Karim). Suspects, victimes et propriétaires sont en initiales ; Alex (« AM ») est le premier visage du jeu, sur le briefing #001 | Dossier criminel sans visages ; biais sur la conclusion | P1 (`victim-placeholder-first-dossier` : P2 → P1) | Produire le pack verrouillé `05_PERSONNAGES.md` (liste ci-dessous) ; le simple dépôt dans `Art.xcassets/Portraits` suffit | BLOQUÉ – ASSETS |
| `photos-procedurales-placeholder` (performance-assets), `procedural-photo-library-placeholder`, `c004-key-photos-procedural`, `c003-key-photos-procedural-no-asset-path` | Photos | Les 212 photos sont procédurales | Voir §10 | P1 / P2 | Photos de niveau A puis B (liste ci-dessous) ; **d'abord** coder `photo_<NNN>_<photoId>` (§10, `photo-asset-hook-absent`) | BLOQUÉ – ASSETS |
| `c002-handoff-photo-prompts-contradict-evidence`, `c002-handoff-age-mismatch` | Handoff 02 / 05, #002 | Prompts des photos clés contraires aux données (porte-clés rouge absent…) ; âges faux (Anaïs 26 ans, Clémence 29) | Des photos produites telles quelles fabriqueraient de faux indices | P1 / P2 | Réécrire les prompts à partir de `caption` et `details` du JSON, puis générer | BLOQUÉ – ASSETS |
| `c004-photo-brief-contradictions`, `c003-handoff-photo-prompts-contradict-case` | Handoff 02, #004 et #003 | Brief photo contraire au JSON (atelier de Lemaire, 41 perles, Iris au micro ; silhouettes sous le lampadaire) | Faux indices | P1 / P2 | Corriger le brief, faire valider par le porteur (§20, D23) | REQUIRES DECISION |
| `c004-cinematic-procedural`, `cinematique-silhouette-procedurale`, `c002-intro-procedural`, `c003-intro-procedural-placeholder`, `c5-cinematique-placeholder`, `c004-voice-asset`, `voix-synthese-systeme` | Cinématiques, voix | Plans Veo, reportage Quai 9, voix ElevenLabs | — | P1 / P2 | — | OBSOLÈTE (plus de cinématique ni de voix) |
| `studio-identity-absent` | Lancement, À propos | NOREL GAMES absent | — | P2 | — | RÉSOLU (V3) : « NOREL GAMES » en texte sur l'écran 01 et dans À propos (le logo vectoriel reste facultatif) |
| `artlibrary-sans-hook-photos` | Code | Aucun point d'entrée `photo_` ; les tests d'assets n'acceptent que `.jpg` portrait ou avatar | Bloque l'intégration | P2 | `ArtLibrary.photo(case:id:)` + élargir `ArtAssetsTests` à `photo_` | OUVERT |
| `gradient-wallpapers` | Accueil du téléphone | Fonds dégradés | Téléphone générique | P2 | 5 fonds photo | BLOQUÉ – ASSETS |
| `desk-objects-folder-states` | Bureau | Pas d'objets de bureau | Hors périmètre V3 (une seule grande chemise) | P2 → P3 | Facultatif | BLOQUÉ – ASSETS |
| `bruitages-synthetiques-lofi` | Sons | 24 sons synthétisés, mono, 22 kHz | Rendu « lo-fi » | P2 → P3 | Sons dédiés §K (liste ci-dessous) | BLOQUÉ – ASSETS |

**P3 (6 constats)**
- **RÉSOLU (V3)** : `norel-games-logo-missing` (carton texte « NOREL GAMES » sur l'écran 01).
- **BLOQUÉ – ASSETS** : `tampons-png-couverture`, `sons-placeholder-lofi`, `dossier004-objet-logo` (réduit : plus de « V »), `avatars-telephone-initiales`.
- **BLOQUÉ – ASSETS, P3 → P2** : `portraits-meta-hors-fiche`. `player_elise_a`, `player_vincent_a` et `npc_lacaze` ne
  correspondent pas aux fiches verrouillées, et **les deux premiers sont désormais visibles dès l'écran 03 « Qui enquête ? »**.

**Liste exhaustive des assets à produire (noms de fichiers et emplacement)**

*A. Portraits des affaires : `ScreenshotKit/Sources/ScreenshotUI/Resources/Art.xcassets/Portraits/`, JPEG 1024 × 1280,
`portrait_<NNN>_<contactId>`. Ils s'affichent sans code (`ArtLibrary.portrait`).*

| Affaire | Obligatoires (suspects + personne concernée) | Facultatifs (témoins, propriétaire) | Déjà livrés |
|---|---|---|---|
| #001 | `portrait_001_me` (Alex Moreau, briefing et Bureau), `portrait_001_emma`, `portrait_001_lucas` | `portrait_001_ines`, `portrait_001_tom` | `portrait_001_sarah`, `portrait_001_karim` |
| #002 | `portrait_002_me` (Clémence Aubry), `portrait_002_mathilde`, `portrait_002_yanis`, `portrait_002_bastien`, `portrait_002_raphael` | `portrait_002_anais` (26 ans, sœur cadette), `portrait_002_kader` | — |
| #003 | `portrait_003_paul` (Paul Castaing), `portrait_003_maxime`, `portrait_003_diane`, `portrait_003_louise`, `portrait_003_gregoire` | `portrait_003_me` (Jeanne) | — |
| #004 | `portrait_004_enzo`, `portrait_004_victor`, `portrait_004_iris`, `portrait_004_sterne` (pas de personne concernée : objet volé) | `portrait_004_me` (Salomé), `portrait_004_camille`, `portrait_004_helene` | — |
| #005 | `portrait_005_me` (Solène Marchetti), `portrait_005_gilles`, `portrait_005_thierry`, `portrait_005_romain`, `portrait_005_agathe`, `portrait_005_julien` | — | — |

Total : 23 obligatoires manquants (21 suspects + 4 personnes concernées, dont 2 déjà livrés) et 8 facultatifs, soit 31.
**Tant que le lot d'une affaire est incomplet, appliquer la décision D5** pour ne pas mélanger photos et initiales.

*B. Enquêteurs et commandant : `Art.xcassets/Players/` et `Art.xcassets/NPC/`, JPEG 1024 × 1280.*
- `player_elise_b.jpg` et `player_vincent_b.jpg` : manquants (choix d'apparence dans le profil après l'affectation).
- `player_elise_a.jpg` et `player_vincent_a.jpg` : présents mais **hors fiche 05 §2**, à régénérer (visibles à l'écran 03).
- `npc_lacaze.jpg` : présent, hors fiche (lunettes, moustache) et affiché nulle part aujourd'hui : facultatif.

*C. Avatars du téléphone (facultatif, les initiales sont conformes au brief) : `Art.xcassets/Avatars/`, 512 × 512,
`avatar_<NNN>_<contactId>` ; 0 sur 33 livrés.*

*D. Photos du téléphone : `Art.xcassets/Photos/` (dossier à créer), `photo_<NNN>_<photoId>`. **Prérequis :** coder la
recherche dans `ArtLibrary` + `GeneratedPhoto` (§10). Les documents (niveau C : `p_invoice` #001, `p_doc_virements` et
`p_bat_2301` #005) restent rendus dans l'app.*

| Affaire | Photos clés, niveau A (priorité : preuves du JSON) | À produire aussi |
|---|---|---|
| #001 | `photo_001_p_emma_couch` (femme sous la couette, télé allumée, fenêtre **claire** à 19:42), `photo_001_p_parking`, `photo_001_p_sarah_jade`, `photo_001_p_karim_desk` (horloge 22:47) | `p_vernissage` (veste en jean claire), `p_lucas_car` |
| #002 (prompts à corriger d'abord) | `photo_002_p_pocket_0309` (parquet clair + porte-clés rouge « M »), `photo_002_p_apero_keys`, `photo_002_p_booth_0248` (horloge de régie 02:48), `photo_002_p_door_0304` (file d'attente, enseigne 03:04) | `p_issue_1`, `p_issue_2`, `p_pistache` |
| #003 | `photo_003_p_group_2340` (sweat jaune moutarde), `photo_003_p_louise_0206`, `photo_003_p_louise_0214` (deux silhouettes sous le lampadaire), `photo_003_p_louise_0227`, `photo_003_p_diane_biarritz` | `p_max_sunglasses`, `p_stairs_day`, `p_night_garden`, `p_blur_party` |
| #004 (brief à corriger d'abord) | `photo_004_p_vitrine_1752` (41 perles, fermoir caché), `photo_004_p_vitrine_2216`, `photo_004_p_room_2213` (Sterne seul près de la vitrine 4), `photo_004_p_stage_2214` (Iris au micro), `photo_004_p_regie_2215` (écran « Q47 — NOIR 90 s ») | `p_b20` (pose de l'Aurore, de loin), `p_b05` (atelier de scénographe, **sans perles**), `p_blur02` (photo noire, bloc SORTIE), `p_iris_look` |
| #005 | `photo_005_p_col_2314` (phares de face dans le brouillard), `photo_005_p_kids_2305` (lits superposés, veilleuse), `photo_005_p_platre` (jambe plâtrée, brancard, néon), `photo_005_p_mairie_4x4` (**prompt à écrire**) | `p_n23` (tableau de bord + pochette cartonnée), `p_n24`, `p_n04`, `p_n17`, `p_n03` |

Puis environ 180 photos banales (niveau B), générées en lot à partir des légendes JSON (handoff 02 §2.3).

*E. Fonds d'écran des 5 téléphones (nom à fixer, par exemple `wallpaper_<NNN>` ; branchement dans `Wallpaper` à coder) :*
#001 Alex (aujourd'hui « night »), #002 Clémence (« ice »), #003 Jeanne (« shore »), #004 Salomé (« gold »),
#005 Solène (« storm ») ; sombres et désaturés.

*F. Sons dédiés du handoff V3 §K : `Resources/Sounds/`, WAV 48 kHz. Les sons générés actuels servent de repli ; il faut
les brancher dans `AudioDirector.Sound`.*
- `ui_paper_tap`, `paper_folder_open`, `paper_slide`, `evidence_bag` ;
- `phone_unlock`, `typewriter_key`, `stamp_heavy` (prioritaire, voir §11), `clock_tick_soft` ;
- facultatifs : `office_room` (ambiance hors téléphone, −30 dB) et une nappe grave pour le briefing et le rapport.

*G. App Store (voir §17)*
- Captures iPhone 6,9″ (1320 × 2868 ; taille exacte à confirmer dans ASC), 3 à 10, en français, plus l'anglais si la langue est gardée.
  Scènes suggérées :
  - 02 Titre ;
  - 04 Briefing #001 ;
  - téléphone et Messages avec « PIÈCE 01 » ;
  - feuille « VERSER AU DOSSIER » ;
  - Carnet (L'ACCUSE) ;
  - 09 « QUI EST RESPONSABLE ? » ;
  - 10 tampon RÉSOLU ;
  - 11 rapport.
- Barre d'état propre (9:41).
- Aperçu vidéo : facultatif.

*H. Facultatifs :*
- logo NOREL GAMES vectoriel ;
- variantes sombre et teintée de l'icône (iOS 18) ;
- fiche objet « Collier Aurore, 1928 » (#004) ;
- tampons PNG SOLUTION CONSULTÉE, SANS FAUTE, DÉSIGNÉ, CONFIDENTIEL, DISCULPÉ (le handoff en contient déjà une partie, non intégrée).

*Plus nécessaires depuis V3 :* plans vidéo Veo, reportage du Quai 9, voix ElevenLabs, clips de recrutement,
`loading_main.jpg`, surfaces des plans « téléphone posé ».

---

## 20. DÉCISIONS À PRENDRE

Toutes les entrées « REQUIRES DECISION » (53 constats, regroupés en 27 décisions). Les recommandations sont les miennes.

| # | Décision | IDs | Options | Recommandation |
|---|---|---|---|---|
| D1 | **Fiche App Store** (texte, catégorie, âge, copyright) | `store-metadata-missing` (P0), et `store-age-rating` pour la cible d'âge | Rédiger en fr (+ en ?) ; catégorie Jeux › Réflexion ou Aventure ; cible 13+ ou 16+ | Nom « CONCLUDE : ENQUÊTES ». Sous-titre (≤ 30 car.) : « Fouillez. Versez. Concluez. ». Catégorie Jeux › Réflexion (cohérente avec `LSApplicationCategoryType = puzzle-games`), secondaire Aventure. Mots-clés : enquête, détective, téléphone, mystère, indices, suspect, polar, investigation, chrono. Copyright « © 2026 NOREL GAMES » si l'entité existe, sinon le nom légal. Âge : viser le 13+ du barème Apple en répondant honnêtement (violence évoquée, alcool) |
| D2 | **Langues de la v1** | `store-languages-en-vs-french-cases`, `anglais-interface-contenu-francais` | (a) Français seul : retirer `en` des langues publiées (`CFBundleLocalizations = fr` ou localisations `en` retirées de l'app) ; (b) traduire les 5 affaires | **(a)** pour la v1 : c'est rapide et honnête. L'anglais complet viendra en v1.x |
| D3 | **Prix et territoires** | `tarification-disponibilite` | Gratuit sans achat ; payant (1,99–4,99 €) ; gratuit avec achats (tickets d'indices, feuille de route) | Gratuit sans achat intégré, pays francophones (France, Belgique, Suisse, Luxembourg, Monaco, Canada) : pas de contrat Paid Apps ni de StoreKit, et l'étiquette de confidentialité reste simple. Revoir quand les affaires #006+ arriveront |
| D4 | **Dépôt GitHub public** | `public-repo-exposes-solutions-ipa` | Passer en privé (minutes macOS payantes) ; ou garder public sans artefact IPA ni branche de captures | Passer en **privé** avant toute communication publique ; sinon, au minimum, ne plus publier l'IPA ni `ci/ui-screenshots` |
| D5 | **Portraits mélangés** (photos + initiales) | `portraits-suspects-mixtes` | (a) Règle « tout ou rien » par affaire dans `ArtLibrary.portrait` ; (b) retirer Sarah et Karim du bundle ; (c) attendre le pack | **(a)** : environ 10 lignes de code. Les portraits restent au catalogue et apparaissent quand le lot d'une affaire est complet (conforme au critère 20 du handoff) |
| D6 | **Valeur de RÉSOLU** (intuition, force brute, solution consultée) | `intuition-recompensee` (P1), `brute-force-solve-by-replay`, `solution-consultee-sans-cout` (P1), `c001-resolu-avec-une-piece` | (a) RÉSOLU seulement avec ≥ 1 pièce clé liée « L'ACCUSE » au coupable, sinon « RÉSOLU SANS PREUVE », non classé ; (b) ne compter pour le rang et Expert que la première réussite classée ; (c) après « Consulter la solution », masquer [REPRENDRE L'ENQUÊTE] ou rendre les parties suivantes du niveau non classées | **(c) tout de suite** : c'est une faille nette, facile à corriger. Puis **(a)**, qui garde le tampon mais distingue l'intuition, et **(b)** pour le rang |
| D7 | **Verser « tout » est rentable** | `spam-versement-rentable`, `pin-everything-dominant` | Poids de la précision plus fort ; plafond de pièces ; coût en secondes | Garder le versement gratuit (principe V3 §F-06) et monter `scoring.notebookPrecision` de 5 à 15, en compensant sur `found` (`rules.json` seulement) |
| D8 | **Heure de la photo « chez moi »** (#001) | `photo-time-free-but-analysis-required` (P1), `c001-heure-photo-visible-avant-analyse` | (A) En-tête « Reçue à 22:30 », l'heure de prise n'apparaît qu'après l'analyse ; (B) compter la preuve si la photo est versée et l'heure vue | **(A)** : l'analyse payante garde son sens, sans toucher au moteur (`PhotosViews.swift:148-151`) |
| D9 | **Note parfaite / SANS FAUTE** | `sans-faute-unreachable`, `perfect-score-unreachable`, `sans-faute-impossible`, `distinction-parfaite-inatteignable` | Définir « sans faute » sans le temps ; ou arrondir la part temps vers le haut | « Sans faute » = bon suspect + toutes les pièces clés + 0 indice, calculé dans `Verdict` (+ test) |
| D10 | **Événements en direct et niveaux** | `live-events-not-scaled-by-level`, `c001-evenements-direct-non-etales` (+ `c004-expert-coat-unreachable`, ouvert) | Mettre `afterSeconds` à l'échelle de la durée ; ou exclure du total les pièces jamais livrées à ce niveau | Exclure du dénominateur du `Verdict` les pièces dont toutes les références sont des événements non livrés, **et** avancer lv07 de #004 à 280 s |
| D11 | **Noms des niveaux** | `niveaux-vs-rangs-collision`, `niveaux-nom-enqueteur`, `level-rank-name-collision`, `collision-enqueteur-niveau-rang`, `level-default-and-enqueteur-collision` | Garder Enquêteur, Détective, Expert ; ou nommer d'après le temps | « DÉLAI LARGE 15:00 · DÉLAI STANDARD 08:00 · DÉLAI COURT 05:00 » (catalogue seulement) |
| D12 | **Objectif ou question finale** | `objective-vs-final-question`, `question-vs-objectif` (×2), `c001-question-vs-objectif` | Question par affaire ; ou objectifs alignés sur « Qui est responsable ? » | Réécrire les 5 `objective` du JSON : « Identifier la personne responsable de la disparition d'Alex. » |
| D13 | **Arrêt du partage de position versable** (#001) | `c001-partage-coupe-gratuit-non-versable` | (a) Ligne Réglages et pastille versables, équivalentes à `track:t_emma` ; (b) retirer l'heure affichée | **(a)**, cohérent avec « tout élément affiché peut être versé » (§F-06) |
| D14 | **Textes des indices de #001** | `c001-aides-paliers-inverses` | Réécrire selon les paliers piste → où chercher → preuve | Valider les textes proposés dans l'audit (`gen_case_001.py:676-678`) |
| D15 | **Coûts affichés** | `costs-not-announced` | Coût sur chaque ligne ; ou tableau récapitulatif | Ajouter un tableau « Ce que coûte chaque geste » dans « Rappel des règles » (briefing), sans alourdir le téléphone |
| D16 | **Ordre des suspects** | `coupable-toujours-en-bout-de-liste` | Alphabétique ; mélange déterministe par affaire ; réordonner le JSON | Ordre alphabétique du prénom, à l'affichage |
| D17 | **Dossier clos : garder le travail** | `closed-dossier-loses-work`, `closed-case-pieces-not-kept` | Garder un instantané léger (pièces et liens) dans `Attempt` ; ou afficher le rapport seul | Le rapport seul pour la v1 (déjà le cas en V3) ; l'instantané plus tard |
| D18 | **« Vu, jamais versé »** | `vu-non-verse-inexplique` | Ligne distincte dans le rapport ; ou rien | Ajouter la ligne « Vu, jamais versé au dossier (n) » : le moteur sait déjà `isSeen` |
| D19 | **Pièce en détail** | `piece-detail-absente` | Vue détail ; ou aperçu seul | Plus tard (P3) |
| D20 | **Supports des pièces** | `pieces-supports-simples` | Modèles de documents du pack ; ou supports actuels | Garder les supports actuels pour la v1 |
| D21 | **Téléphone dessiné dans le téléphone** | `double-island-phone-in-phone`, `phone-in-phone-usable-area` | (a) Garder l'objet, retirer l'îlot dessiné ; (b) plein écran | **(a)** : l'identité est gardée et le double îlot disparaît |
| D22 | **Étiquette du chrono sans libellé** | `timer-tag-reads-as-clock` | Micro-libellé « RESTE » ; ou tel quel | Tel quel (conforme §F-05), à observer lors des tests joueurs |
| D23 | **Textes et briefs des affaires** | `c004-story-arrest-contradiction` (P1), `c004-photo-brief-contradictions` (P1), `c003-handoff-photo-prompts-contradict-case`, `c003-everyone-slept-contradiction`, `c003-paul-messages-unread-implausible`, `c003-tripod-framing-contradiction`, `c003-yellow-under-lamp-ambiguity`, `c5-appel-vocal-faux-julien` | Valider ou ajuster les réécritures proposées par l'audit | Valider **avant** de commander les photos #003 et #004 ; #004 en premier (l'arrestation est lue par tous les joueurs) |
| D24 | **Numéros, domaines, verrouillage des dossiers** | `fictional-numbers-emails-real-ranges`, `no-locked-state-progression` | Plages ARCEP réservées à la fiction, domaines `.example` ; dossiers ouverts ou verrouillés | Numéros fictifs ARCEP avant la sortie publique. Pas de verrou (5 dossiers ouverts) |
| D25 | **Conditionner TestFlight aux tests UI** | `testflight-not-gated-untested-configs` | Exiger « iOS – Compile » vert sur le même commit ; ou non | Oui |
| D26 | **Une pièce, plusieurs suspects ?** | `lien-unique-par-piece` | Moteur à un seul lien (actuel) ; ou plusieurs (handoff §F-08) | Un seul lien pour la v1 (écart déjà noté dans `DESIGN_INTEGRATION.md`) |
| D27 | **Priorités des assets** | (transverse, §19) | Portraits d'abord ; ou photos d'abord | Portraits #001 (Alex, Emma, Lucas), puis les photos clés #001 et #005 ; les autres affaires ensuite |

---

## 21. CE QUI EST DÉJÀ PRÊT

- **Premier lancement V3 complet et testé.**
  - Parcours : 01 Lancement (1,6–4 s, préchargement réel) → 02 Titre → 03 « Qui enquête ? » → 04 Briefing #001 → ouverture « sachet → téléphone » ;
    le téléphone est atteint en 4 taps ou moins.
  - Écran de lancement système identique à l'écran 01 ; relances vers le Bureau, ou vers 02b si une enquête est en cours.
  - Affectation (écran 12) montrée une seule fois ; les anciens joueurs sont migrés.
- **Tutoriel** : 3 bulles non bloquantes (EXPLORER, VERSER AU DOSSIER, RELIER), une seule fois, au-dessus de 06:30, relance
  douce à 90 s, « Revoir le tutoriel ».
- **Téléphone.**
  - 12 apps crédibles ; coûts en temps (`rules.json`) ; horloge et batterie qui avancent ; notifications en direct avec file de priorité.
  - Recherche globale ; Corbeille avec récupération payante (versement bloqué avant récupération, `0fad7aa`) ; app verrouillée
    (clavier adaptatif, `0fad7aa`) ; carte MapKit réelle avec lieux révélés.
  - Étiquette de chrono papier (rouge sous 01:00, tic, haptique sous 00:10, EN PAUSE) ; pause automatique en arrière-plan ;
    feuille de pause.
- **Geste unique « Verser au dossier ».**
  - Appui long de 0,4 s dans toutes les apps → feuille papier → copie qui vole vers la barre → étiquette « PIÈCE 0N ».
  - « Déjà au dossier » + VOIR DANS LE CARNET.
- **Carnet.**
  - 3 onglets (PIÈCES, SUSPECTS, CHRONOLOGIE) ; L'ACCUSE / LE DISCULPE avec choix du suspect ; compteurs ▲▼ ; chronologie automatique.
  - Indice en 3 niveaux, payé en points, jamais en temps ; CONCLURE toujours possible.
- **Fin de partie.**
  - « QUI EST RESPONSABLE ? » avec maintien nommé de 1,2 s ; alternative VoiceOver ou Switch Control par confirmation ;
    TEMPS ÉCOULÉ forcé, sans retour.
  - Vérification tapée, tampons PNG RÉSOLU / NON RÉSOLU ; rapport qui explique d'abord.
  - [REPRENDRE L'ENQUÊTE] (pièces gardées), « Classer quand même ».
- **Identité et carrière.**
  - Élise Morel / Vincent Delmas ; matricules BEN fixes ; échelle de rangs verrouillée ; cachets de rang PNG.
  - Carte d'agent et profil avant et après l'affectation ; signature et sceau du Cdt. Lacaze.
- **Réglages** : Effets sonores, Vibrations, Réduire les animations (une seule source, fondus), Écriture manuscrite
  lisible, Temps détendu (×1,5, mention sur le rapport), Revoir le tutoriel, À propos (tuile, NOREL GAMES, version et build).
- **Textes.**
  - Vocabulaire verrouillé partout ; 505 clés fr et en, toutes traduites.
  - Tests : mots interdits (`bannedWordsAreGone`), clés en ternaire, collisions de symboles Xcode.
  - Plus aucune clé brute affichée.
- **Moteur et contenu.**
  - 70 tests Swift sous Linux ; CaseLint valide les 5 affaires (plus de 90 % de bruit, résolubles aux 3 niveaux).
  - Générateurs et JSON identiques octet pour octet ; chronologies vérifiées à la minute ; jours de la semaine justes.
- **Sauvegarde** : reprise sur le même écran avec le même carnet et le même temps ; écriture atomique environ toutes les
  5 s ; confirmation avant d'écraser une enquête en cours (`0fad7aa`) ; tentative enregistrée avant le résultat.
- **Accessibilité de base.**
  - Écrans papier en Dynamic Type AX (grilles en 1 colonne) ; chrono lu « 4 minutes et 12 secondes ».
  - Pièces lues « Pièce 1, message, Lucas… » ; tampons lus ; aucune information portée par la couleur seule (▲▼, « ✓ CHOISIE »).
- **Confidentialité et build.**
  - `PrivacyInfo.xcprivacy` complet : aucune collecte, aucun suivi, aucune permission demandée, aucun SDK tiers ; `ITSAppUsesNonExemptEncryption = NO`.
  - Build iOS en CI avec 10 tests UI et captures ; chaîne TestFlight opérationnelle (archive signée, numéro de build croissant, dSYM) ; aucun secret dans le dépôt.
- **Assets livrés et intégrés.**
  - Logo : AppIcon recadré, `LaunchTile`, `logo_tile`, `logo_wordmark`.
  - Tampons et sceaux : 2 tampons de verdict, 4 cachets de rang, sceau BEN, signature de Lacaze.
  - Textures papier et kraft ; portraits de Sarah et Karim ; `player_elise_a` et `player_vincent_a` (à régénérer, voir §19).

---

## 22. CE QUI BLOQUE RÉELLEMENT LA PUBLICATION

Seulement ce qui empêche une sortie **App Store** (TestFlight n'est pas concerné, à part le point C1).

**A. Soumission impossible tant que ce n'est pas fait (App Store Connect, hors code)**
1. Renommer la fiche « TRACE: Case Files » en **CONCLUDE : ENQUÊTES** (`asc-app-name-trace`).
2. Publier une **politique de confidentialité** et une **URL d'assistance**, puis les renseigner (`store-privacy-policy-support-url`).
3. Remplir l'**étiquette de confidentialité** : « Données non collectées » (`store-privacy-label-data-not-collected`).
4. Remplir la **classification par âge** (`store-age-rating`).
5. Fournir des **captures 6,9″** (`store-screenshots-missing`), après la décision D5 pour ne pas montrer de portraits mélangés.
6. Rédiger la **fiche** : description, sous-titre, mots-clés, catégorie, copyright (`store-metadata-missing`, D1).
7. Choisir le **prix et les territoires** (D3) ; signer le contrat Paid Apps si l'app est payante.
8. Déclarer le **statut de professionnel UE (DSA)** et choisir le compte vendeur (`seller-individual-account-dsa`).

**B. Refus probable à la revue**
1. **Lien vers la politique de confidentialité dans l'app** (règle 5.1.1(i)) : À propos existe, il manque le lien et le
   contact (`in-app-about-privacy-version`).
2. **Langue annoncée non tenue** : interface anglaise, affaires en français. Publier en français seul, ou traduire (D2).

**C. Défauts bloquants du produit** (Apple accepterait peut-être, mais on ne publie pas avec)
1. **Valider `0fad7aa` sur la CI iOS et sur un iPhone SE** : clavier du code (P0), versement depuis la Corbeille,
   confirmation avant d'écraser une enquête, photos de nuit. Ajouter le test UI qui tape « 1609 ». C'est aussi la
   condition pour la prochaine build TestFlight.
2. ~~**Musique du joueur coupée au lancement**~~ (`audio-warmup-coupe-musique-joueur`, P1) : corrigé après la rédaction de ce document.
3. **Rejouer après avoir consulté la solution donne RÉSOLU et un rang** (`solution-consultee-sans-cout`, D6-c).

Le reste relève de la qualité et peut suivre la v1 : portraits et photos réels, décisions D5 à D27, incohérences de
textes des affaires, accessibilité avancée, CI multi-simulateurs. Dans l'ordre recommandé : D5 (≈ 10 lignes) avant les
captures, puis les portraits de #001, puis `photo_` + les photos clés.
