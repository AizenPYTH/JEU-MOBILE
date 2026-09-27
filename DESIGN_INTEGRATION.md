# Intégration des handoffs design (v1.0 → TRACE v2 → final V3)

Sources : `docs/design_final/` (V3, parcours), `docs/design_trace/`, `docs/design/` (non modifiés). Ce document dit ce qui est intégré, ce qui reste à faire, et
les points où le handoff contredit le brief ou le moteur — **à trancher par le porteur de projet**.

## Mode Histoire — handoff « Mode Histoire » (27 septembre 2026)

Source : `docs/design_story/` (écrans h01–h19, bible 3D, décors, PNJ, dialogues, transitions, assets). Détail
technique : `docs/story/`.

### Intégré
- h01 Bureau à trois chemises ENQUÊTES · ALIBI · HISTOIRE (mode en cours en premier) ; h02 = l'ancien Bureau
  d'ENQUÊTES avec « ‹ Bureau » ; h03 = la liste ALIBI existante.
- h04 hub (rendu 3D du couloir, travelling lent), h05 création en 4 étapes (+ h05b dossier d'enquêteur, maintien
  1,2 s), h06 studio / « Voir en 3D », h07 profil, h08 carrière (frise), h09 mon bureau (4 niveaux, points
  interactifs), h10 chapitre, h11/h12 sous-titres, choix et silence, JOURNAL · AUTO · PASSER, h13/h14 transitions
  scène ⇄ téléphone (fondu au noir, nouveau dossier h15 puis briefing existant), h16 fin de chapitre, h17 état de
  service, h18 récompense, h19 réglages (lecture, 3D, carrière, réinitialisation 1,6 s).
- Chapitre 01 exactement selon STORY_SCENES §5 (S01-01, S01-02, S01-03 ; l'affaire est #001) ; chapitre 02
  (affaire C02-A « Le dossier Varin », propre à l'histoire) ; chapitres 03–05 annoncés.
- 7 décors du BEN avec caméras nommées et focales ; PNJ Lacaze, Inès Carvalho, Marc Aubrac, Colette Vidal, un agent.
- Grammaire des plans vérifiée automatiquement (WIDE d'abord, ≤ 2 CLOSE d'affilée, plan muet, OBJECT FOCUS avant
  le téléphone, CUT / DISSOLVE / FADE, caméras du décor uniquement).

### Écarts assumés (décisions)
- **3D** : SceneKit (natif, aucune dépendance), personnages et décors construits en formes simples (réalisme
  stylisé, matériaux mats) en attendant les modèles du manifeste d'assets. Aucune vidéo, aucune IA générative.
- **Note de Lacaze (h17)** : le handoff la met en Caveat ; la règle du projet réserve l'écriture manuscrite au
  joueur. Elle est en Newsreader italique. À trancher si besoin.
- **Seuils de rang 1 / 20 / 30 + chapitre** : appliqués au joueur qui a créé son enquêteur (carrière commune,
  affaires ENQUÊTES comptées). Sans enquêteur créé, ENQUÊTES garde l'échelle 0 / 1 / 2–3 / 4–5 (comme le demande
  CHARACTER_CUSTOMIZATION §6 tant que le mode n'est pas utilisé).
- **Fusion d'identité** : le personnage créé apparaît sur le Bureau (h01 : nom, rang, portrait) et partout dans
  l'histoire. Les écrans d'ENQUÊTES (profil « Enquêteur », « AFFECTÉ À » des dossiers) gardent encore l'identité
  choisie à « Qui enquête ? » : fusion complète à faire.
- **Reprise d'une scène** : à la réplique exacte (plus fin que « au dernier plan-clé ») ; les `keyframe` sont
  présents dans les données pour un futur rendu précalculé.
- **HISTOIRE / ALIBI « verrouillés jusqu'à #001 »** : le Bureau n'est atteint qu'après l'affectation (donc après
  #001) ; l'état verrouillé existe dans la chemise mais ne se voit pas en pratique.
- **Colonne ALIBI « DÉCLARÉ / TRACÉ »** : « RELEVÉ » à la place de « TRACÉ » (mot interdit par les tests de
  vocabulaire hérités de TRACE).
- **Qualité 3D** : Auto / Économie / Haute règlent l'anticrénelage, les ombres et la profondeur de champ ; pas de
  détection automatique de la mémoire de l'appareil ni du passage en mode texte sous 24 fps.

### Reste à faire (Histoire)
- Modèles 3D, animations faciales, voix, musiques, tampons NOUVEAU / CLASSÉ en PNG (voir
  docs/story/SCENE_SYSTEM.md › Assets encore nécessaires).
- « Montrer une pièce » (EvidenceChip) pendant un dialogue ; mode « Lire en texte » en cas d'échec 3D.
- Chapitres 03 à 05, PNJ d'affaire en salle d'audition.

## V3 — Handoff final « CONCLUDE » (26 septembre 2026)

Source : `docs/design_final/FINAL_DESIGN_HANDOFF_CONCLUDE.md` (lecture seule) et le logo maître
`docs/brand/logo_conclude_master.png`. Il **remplace les parcours** des handoffs précédents ; les matières
(papier, kraft, tampons) et le téléphone restent ceux de TRACE v2 / v1.0.

### Intégré

| Écran / règle | Où |
|---|---|
| 01 Lancement : fond #0A0908, tuile 188 pt, « NOREL GAMES », 1,6–4 s, préchargement réel (portraits du #001 et des joueurs d'abord) ; écran de lancement système identique (`Configs/Info.plist`, `LaunchTile`, `LaunchBackground`) | `LaunchScreen.swift` |
| 02 Titre (bandeau logo −1,5°, accroche, mission, 3 verbes, un bouton, ⚙) · 02b Titre-reprise · 03 Qui enquête ? (Élise présélectionnée, « ✓ CHOISIE », aucun matricule) | `TitleScreens.swift` |
| 04 Briefing : chemise kraft, feuille texturée, en-tête catégorie/ville, tirage, titre, résumé, VOTRE MISSION, 3 étapes (#001) ou « Rappel des règles », pied « n SUSPECTS · TEMPS », [OUVRIR LE TÉLÉPHONE] ; niveau replié (caché à la 1re partie) | `DossierView.swift` |
| Ouverture : sachet de scellé → téléphone (≤ 1,8 s), déverrouillage automatique au #001, écran verrouillé des #002–#005 ; le chrono démarre au premier écran d'accueil | `CaseOpening.swift` |
| 05 Téléphone : étiquette chrono papier (rouge sous 01:00, tic, haptique sous 00:10, « EN PAUSE »), barre du dossier 64 pt (compteur, CARNET contour → plein) | `PhoneView.swift` |
| 06–07 Appui long 0,4 s → feuille « VERSER AU DOSSIER » (déjà versé → « PIÈCE 0N · déjà au dossier » + VOIR DANS LE CARNET), copie papier qui vole vers la barre, pulsation rouge, étiquette « PIÈCE 0N » | `Pinnable.swift`, `FilingSheet.swift` |
| Tutoriel du #001 : bulles 1 EXPLORER / 2 VERSER AU DOSSIER / 3 RELIER, une à la fois, jamais bloquantes, au-dessus de 06:30 seulement, relance à 90 s ; « Revoir le tutoriel » | `Tutorial.swift`, `CoachBubble.swift` |
| 08 Carnet : PIÈCES · n / SUSPECTS / CHRONOLOGIE, « CETTE PIÈCE… » [L'ACCUSE] [LE DISCULPE] + puces suspects, ▲n ▼n, ampoule, CONCLURE toujours actif (contour < 3 pièces reliées), feuille « Aucune pièce au dossier », état vide | `InvestigationView.swift` |
| 14 Indice : feuille papier sur voile, indices en post-it, coût en points | `InvestigationView.swift` |
| 09 Conclusion : « QUI EST RESPONSABLE ? », grille des suspects ▲▼, « MAINTENIR : {PRÉNOM} EST RESPONSABLE » 1,2 s (VoiceOver : confirmation), forcée à 00:00 avec « TEMPS ÉCOULÉ » | `EndScreens.swift` |
| 10 Vérification tapée 1,4 s + tampons PNG · 11 Rapport (ce qui s'est passé / ce que vous n'avez pas vu, pièces clés ✓/○, temps · indices · note) · [REPRENDRE L'ENQUÊTE] (chrono plein, pièces gardées), « Classer quand même », « Consulter la solution » | `EndScreens.swift` |
| 12 Affectation au BEN (une seule fois : #001 résolu, ou 2 échecs, ou « Classer quand même »), sceau, signature de Lacaze, cachet du rang | `AssignmentView.swift`, `Player.swift` |
| 13 Bureau : une grande chemise « PROCHAINE ENQUÊTE », « AUTRES DOSSIERS », état « tous classés », pas de logo · Profil avant / après affectation · Paramètres (Temps détendu ×1,5, Revoir le tutoriel, À propos) | `DeskScreens.swift`, `MetaScreens.swift` |
| Logo (§H) : AppIcon recadré, `logo_tile`, `logo_wordmark` ; tampons, sceau, signature, textures | `Assets.xcassets`, `Art.xcassets/{Brand,Stamps,Textures}` |
| Vocabulaire : EXPLORER · VERSER AU DOSSIER · CONCLURE ; « Épingler », « Accuser », « Recrue », « Stagiaire », TRACE, MoonWolf absents (test `bannedWordsAreGone`) | `Localizable.xcstrings` |

### Écarts assumés (décisions)

- **Aucune cinématique** (demande du porteur de projet) : ni la cinématique #001, ni « Voir / Revoir la
  séquence », ni la cinématique de recrutement de l'écran 12. L'affaire est présentée par le briefing et
  l'ouverture courte. `introScene` reste dans les JSON (non joué). `docs/CINEMATIQUES_VEO.md` est archivé.
- **Pas de tickets** (l'économie n'existe pas) : l'écran 14 affiche le coût de chaque indice en points de
  note et la note maximale restante. Le bouton « PLUS DE TICKETS » n'existe donc pas.
- **Une pièce = un suspect** : le moteur relie une pièce à un seul suspect (`NotebookEntry.linkedTo`) ; le
  handoff (« une pièce peut être liée à plusieurs suspects ») demanderait un changement de moteur et de
  sauvegarde — non fait.
- **Pas d'annotation manuscrite automatique** dans le Carnet : le jeu n'écrit jamais à la main à la place du
  joueur (règle du projet) ; le lien est résumé en ligne tapée (« L'accuse : Lucas »). Indices en
  Newsreader italique sur post-it (pas en Caveat), pour la même raison.
- **Bulle 1** : le texte ne nomme pas le propriétaire du téléphone (« Commencez par les messages. »), pour
  rester valable si le #001 change ; elle est posée au-dessus de l'icône Messages (dans le dock, sans place
  en dessous).
- **Choix de l'apparence (A/B)** : proposé seulement après l'affectation (profil › « Changer d'enquêteur ou
  d'apparence »), conformément au §A (couche carrière après #001).
- **Niveaux Enquêteur · Détective · Expert** : conservés, repliés sous « NIVEAU : … » dans le briefing et
  cachés à la toute première partie. ⚠ Le nom du niveau « Enquêteur » est aussi celui du premier rang
  (ENQUÊTEUR) : à renommer si cela gêne (décision du porteur de projet).
- **Paramètres › À propos** : tuile 96 pt + « NOREL GAMES » + version ; pas de carte de partage (P2).
- **Sauvegardes** : aucun changement de format. Un joueur d'une version précédente qui a déjà des parties
  est considéré comme affecté (Élise A par défaut, modifiable dans le profil).

### Reste à faire (V3)

- Portraits définitifs (joueurs A/B, suspects des 5 affaires, Lacaze) : les écrans affichent les initiales
  sur fond bleu-gris en attendant (§N).
- Sons dédiés du handoff (`paper_slide`, `evidence_bag`, `stamp_heavy`, `clock_tick_soft`, `office_room`…) :
  les sons générés existants sont utilisés à la place.
- Écran 10 de 06 (« Avancement de service » quand le rang change), carte de partage d'un rapport (P2).
- Vérifier sur appareil : Dynamic Type AX3 sur iPhone SE (critère 17), VoiceOver de bout en bout (critère 18).

## Nom et logo — CONCLUDE : ENQUÊTES (septembre 2026)

Le jeu s'appelle désormais **CONCLUDE : ENQUÊTES**. Icône de l'app = logo fourni par le porteur de projet
(`docs/brand/conclude_logo_source.png`), recadré sur la tuile et redimensionné en 1024 × 1024 (iOS
arrondit lui-même les coins). Nom sous l'icône : « Conclude » (le nom complet serait tronqué sur
l'écran d'accueil). [V3 : l'icône vient désormais du logo maître `docs/brand/logo_conclude_master.png`, et le logo
n'apparaît plus que sur 01, 02, 02b et À propos.] Avant V3, l'en-tête du Bureau reprenait le logo : CONCLUDE en capitales, puis
« ENQUÊTES » souligné de rouge ; la carte d'enquêteur et le rapport de clôture portent le nom.
Le nom sur l'App Store se change dans App Store Connect (fiche de l'app), pas dans le code.

## 0. Direction artistique TRACE v2 — « papier dehors, verre dedans » (septembre 2026)

Source : `docs/design_trace/` (handoff Claude Design « TRACE », lecture seule — lire `README.md`).
Seule retouche de la copie archivée : le titre de l’étape 8 du README devient « Vérification » (le mot d’origine est interdit
par `LegacyWordsTests`).
Elle **remplace** le handoff v1.0 pour tout ce qui est hors du téléphone ; le téléphone saisi garde
les tokens v1.0 (`Theme.*`), c'est l'objet moderne au milieu du dossier.

| Élément TRACE | Où dans le code |
|---|---|
| Tokens (bureau, papiers, kraft, encres, tampon, stylo, ruban…), polices Newsreader / IBM Plex Mono / Caveat, mouvements | `Theme/TraceDesign.swift` (`Trace.Colors/Fonts/Motion/Spacing`) |
| Matières et objets : papier + grain, kraft, lignes, agrafe, ruban adhésif, trombone, tirage photo, photo d'identité | `TraceDesign.swift` (`.paper()`, `.kraft()`, `RuledLines`, `Staple`, `Tape`, `Paperclip`, `PhotoPrint`, `IDPhoto`) |
| Tampons (RÉSOLU, NON RÉSOLU en pointillé, CONFIDENTIEL, DISCULPÉ…), tampon qui tombe (son + haptique) | `StampMark`, `FallingStamp` |
| Champs de formulaire, lignes de registre, difficulté ■■□□□, étiquettes « P.04 », écriture manuscrite | `FieldRow`, `LedgerRow`, `DifficultyMeter`, `EvidenceLabel`, `Handwritten` |
| Intercalaires, barre Bureau · Archives · Enquêteur | `DividerTabs`, `DeskTabBar` |
| 02 Bureau (dossier en cours + dossiers suivants, chemises kraft, onglet, agrafe, tampons) | `Screens/DeskScreens.swift` (`BureauView`, `FolderCard`, `FolderTabRow`) |
| 03 Archives (filtres, dossiers clos, note, tentatives) · 20 Enquêteur (carte, états de service) | `ArchivesView`, `ArchiveCard`, `InvestigatorView` |
| 04 Dossier ouvert (couverture qui pivote, intercalaires Contexte / Suspects / Pièces / Chronologie / Rapport, niveaux en cases à cocher) | `Screens/DossierView.swift` |
| 06 Pièces à conviction (un support par type : tirage, capture, relevé d'appels, extrait de carte, page d'agenda, note jaune, courriel, page web, fiche) numérotées dans l'ordre de versement | `Components/Dossier.swift` (`ExhibitView`, `PieceFormat`) |
| 07–08 Suspects en fiches bristol, fiche suspect dactylographiée, annotations « l'accuse » / « le disculpe » entourées à la main | `SuspectIndexCard`, `SuspectFileView`, `LinkedChain` |
| 11 Carnet à spirale (lignes bleues, marge rouge) : Suspects · Pièces · Chronologie · Connexions | `NotebookView`, `NotebookPaper`, `ConnectionBlock`, `ChronologySheet` |
| 13 Indices en plis kraft cachetés (cire, ficelle tant que verrouillés), note du superviseur une fois ouverts | `HintsView`, `HintCard` |
| 05 Téléphone : chrono en étiquette papier (normal / ≤ 60 s contour rouge / ≤ 10 s étiquette rouge), onglet kraft « CARNET n PIÈCES · INDICE », confirmation en étiquette scotchée | `Phone/PhoneView.swift` (`TimerPill`, `CarnetBar`), `Components/Pinnable.swift` (`ToastView`) |
| 15 Vérification finale (formulaire, cases, « Vous désignez… », maintenir **1,2 s** pour clore) | `EndScreens.swift` (`AccusationView`, `HoldToCloseButton`) |
| 16 « VÉRIFICATION DU DOSSIER… » tapé à la machine (2,4 s) puis chemise fermée + tampon | `VerificationView` |
| 17–18 Rapport de conclusion RÉSOLU / fiche de débriefing NON RÉSOLU (« Rouvrir le dossier », « Consulter la solution ») | `ResultView` |
| 19 Rapport de clôture (note finale / 100, lignes de calcul, SANS FAUTE) | `ScoreView` |
| Sons papier : tampon, feuille, chemise, machine à écrire (générés) | `scripts/audio/gen_sounds.py`, `AudioDirector.Sound` |
| Données de couverture (catégorie, ville, lieu, personne concernée, dernier contact, difficulté 1–5) | `DossierInfo` optionnel dans l'affaire (présentation seule ; anciennes sauvegardes inchangées) |

Vocabulaire appliqué : Épingler → **Verser au dossier** ; Lier → **L'accuse… / Le disculpe…** ;
Accuser → **Vérification finale / Clore le dossier** ; Score → **Rapport de clôture / Note finale** ;
Accueil → **Bureau** ; Dossiers terminés → **Archives** ; Profil → **Enquêteur**.

Règles tenues : le jeu n'annote jamais à la place du joueur (seuls les tampons administratifs sont
« imprimés » ; tout le manuscrit vient d'un geste du joueur) ; aucune texture papier dans les apps du
téléphone ; réglage « Écriture manuscrite lisible » (Caveat → Newsreader italique).

Écarts assumés : pas d'illustration de personne (photos d'identité = portraits générés, comme avant) ;
les écrans 01 Remise, 14 Notifications, 21 Vide et 22 Confirmation reprennent les composants TRACE
sans maquette dédiée ; l'onboarding garde ses démos « verre » (elles montrent le téléphone) sur fond bureau.

## 1. Intégré

| Élément du handoff | Où dans le code |
|---|---|
| Palette (6 noirs étagés, textPrimary = action, signal ambre, alert, trace, clear, lignes) | `Theme.Colors` |
| Typographie Geist / JetBrains Mono / Instrument Serif (OFL, embarquées) | `Theme.Fonts`, `Theme/Fonts.swift`, `Resources/Fonts/` |
| Espacements, rayons, tailles, élévations (contour + ombre), animations (fast/base/slow/hero, ressorts) | `Theme.Spacing/Radius/Size/Motion`, `elevation0/1/2` |
| Logo « SCREENSHOT » + 4 repères de capture (le dernier ambre) | `MetaScreens.swift` (`Logo`) |
| [02] Accueil (menu 4 lignes, carte « Affaire suivante / Commencer ») | `HomeView` |
| [03] Affaires (segments Toutes / À jouer / Terminées, `CaseCard` : disponible, jouée, ✓ n %, ◆ PARFAITE) | `CasesView`, `CaseCard` |
| [04] Intro (fond ink.0, phrases serif en fondu, un tap affiche tout, suspects, durée mono 34, CTA actif tout de suite) | `CaseIntroView` |
| [05] Dossiers (tentatives ✓/✕ + score, « non classé », reconstitution si résolue ou révélée) | `ArchiveView`, `ArchivedCaseView` |
| [06] Profil (4 `StatCard`) | `ProfileView` |
| [07] Paramètres (Vibrations, Réduire les animations) | `SettingsView`, `Preferences` |
| [08] Accueil du téléphone : icônes d'apps (voir §2.7, remplacent les tuiles 2 lettres), dock, badges, app verrouillée désaturée | `HomeScreen.swift`, `AppIcon.swift` |
| Barre d'état : pastille du chrono (normal / ≤ 60 s / ≤ 10 s), flash du coût, fine barre de progression, vignette critique | `PhoneView.swift` |
| Capsule Carnet + home indicator | `PhoneView.swift` |
| [09–10] Messages : lignes 78, séparateurs de date en capitales, groupes < 5 min, bulles envoyées blanches, pas de champ de saisie, brouillon, « a cessé de partager sa position » | `MessagesViews.swift` |
| [11] Recherche (dans Messages) avec surlignage et état vide | `MessagesViews.swift` |
| [12] Appels (segments Tous / Manqués, flèches) | `CallsView.swift` |
| [21] Corbeille (pointillés + overline) | `OtherApps.swift` |
| [22/23] Notifications normal / important (contour) / urgent (inversée, reste affichée, Ouvrir · ◆ Épingler) | `PhoneView.swift`, niveau `level` dans l'affaire |
| [27] Épingler / Lier à un suspect par appui long, toast | `Pinnable.swift`, `Investigation.togglePin/link` |
| [28–29] Carnet (Suspects · Preuves · Chronologie), fiche suspect (déclaration, cases à cocher, éléments liés) | `InvestigationView.swift` |
| [30] Indices par paliers (gratuit, −8, −15 débloqué à 02:00) — coûtent du score, pas du temps | `HintsView`, `Investigation.useHint` |
| Tap sur le chrono → « Accuser maintenant ? » | `AccuseNowSheet` |
| [31] Temps écoulé (00:00 mono 88 rouge, barre 1,8 s) | `TimeUpView` |
| [32] Accusation (grille, ring blanc + ✓, les autres à .60, maintenir 900 ms) | `AccusationView`, `HoldToConfirmButton` |
| [33] Résultat positif (révélation pas à pas, ● trouvé / ○ manqué) | `ResultView`, `RevealTimeline` |
| [34] Résultat négatif (alibi, le piège, ce que vous aviez trouvé, ce qui a été manqué par app, Rejouer / Révéler → non classé) | `ResultView` |
| [35] Score (chiffre qui défile, 5 lignes en cascade, formule du handoff) | `ScoreView`, `Verdict.score` |
| Pause quand l'app passe en arrière-plan (« Enquête en pause ») | `PauseOverlay` |
| [01] Onboarding 3 étapes jouables (Explorer : ouvrir Photos + analyser · Épingler : maintenir un message · Accuser : chrono + maintenir), « Passer », premier lancement seulement, « Revoir l'introduction » dans Paramètres | `OnboardingView` |
| Reprise d'une enquête : sauvegarde (pause, chaque action, toutes les ~5 s), carte « Reprendre l'enquête » sur l'Accueil (temps restant, épinglés, progression), même écran restauré | `InvestigationSnapshot`, `SavedInvestigationStore`, `HomeView` |
| [11] Recherche globale : pastille « Rechercher » sur l'accueil du téléphone, Messages · Agenda · Notes · Mail · Navigateur · Contacts, puces par app avec compteurs, groupes par app puis date, terme surligné, dates/jours en français, apps verrouillées exclues, coût d'une recherche | `PhoneSearch`, `GlobalSearchView` |

## 2. Conflits entre le handoff et le brief — décisions du porteur de projet

1. **Affaire #001** : on garde l'histoire du brief (coupable **Emma**). L'histoire du handoff (Lucas,
   20 sept., prêt de 4 000 €) n'est pas utilisée. Seules les données JSON changent, jamais le moteur.
2. **Coût en temps des actions** : gardé et actif, réglable dans `rules.json` (`timeCosts`).
3. **Preuve trouvée = vue + épinglée** dans le Carnet (appui long). Voir ne suffit plus. Le joueur
   peut ensuite lier l'élément épinglé à un suspect.
4. **Apps** : Notifications gardée (sert surtout aux événements en direct). Fichiers n'a pas été
   intégrée : elle pourra coexister plus tard.
5. **Affaire 000 et Mode sans chrono** : reportés.
6. **Heure du téléphone** : le handoff la montre figée (« 08:12 ») ; décision : elle **avance** avec
   l'enquête. Source unique `Investigation.phoneNow` = heure de début + temps écoulé du chrono (coûts
   compris) ; accueil, notifications, messages en direct et heures relatives l'utilisent.

7. **Passe de polish UX/UI (lisibilité, reconnaissance)** — décision du porteur de projet, qui prime
   sur le handoff sur ces points :
   - **Téléphone dessiné comme un objet** : cadre métal, bordure noire, îlot caméra, boutons latéraux,
     reflet léger, ombre sur un fond sombre (`PhoneDevice`, `CameraIsland`, `DeskBackground`).
   - **Icônes d'apps** : les tuiles « tableau périodique » (2 lettres) sont remplacées par des icônes
     originales qui reprennent les conventions connues (combiné vert, bulles bleues, page de
     calendrier avec le jour, carte avec une épingle, note lignée…) — sans copier d'icône réelle
     (`Components/AppIcon.swift`). Fond d'écran nuit avec deux halos au lieu du placeholder rayé.
   - **Chaque app s'annonce** : en-tête commun (‹ Accueil, icône, nom, ligne de contexte)
     (`Phone/AppChrome.swift`). L'app « Localisation » s'appelle désormais **Carte**.
   - **Conventions d'usage** : bulles envoyées bleues (le handoff les voulait blanches), grille du mois
     dans le Calendrier, carte lisible (îlots, routes, fleuve, parcs, épingles rouges, trajet bleu) avec
     une carte « Positions partagées » en bas, Mail avec Réception/Envoyés et non-lus, Contacts par
     lettre, barre d'adresse du Navigateur, Réglages en lignes à icônes, centre de notifications en cartes.
   - **Couleurs fonctionnelles** ajoutées au thème : `info` (bleu, navigation / information),
     `clear` (vert, confirmé / trouvé), `signal` (ambre, épinglé / attention), `alert` (rouge),
     `special` (violet, enquête : liens vers un suspect, décision). Avatars teintés selon le contact.
   - **Carnet** : objectif rappelé, progression (épinglés · liés · apps fouillées — uniquement les
     actions du joueur), onglets Suspects · Indices (liés / à classer) · Chronologie (par jour) · Notes
     (les cases cochées de chaque suspect). Le bouton d'aide de la capsule s'appelle « Aide » (le mot
     « Indices » désigne maintenant les éléments épinglés).
   - **Décision finale** : « Résoudre l'affaire — Qui est responsable ? », liste des suspects avec ce
     que le joueur leur a lié, panneau « Vous accusez X » + les éléments sur lesquels repose
     l'accusation, puis maintien 1,2 s (inchangé).
   - **Résultat** : « X était responsable », les éléments déterminants (preuves `key` de l'affaire,
     ✓ trouvé / ○ manqué, avec ce que chacune prouve), « Votre dossier » (ce que le joueur avait lié),
     puis la chronologie. Une mauvaise réponse garde la règle : alibi, piège, trouvé de juste, manqué
     par app, solution seulement sur demande.
   - Le jeu ne conclut toujours pas à la place du joueur : rien n'indique pendant l'enquête si un
     élément épinglé est une vraie preuve ; « important » = ce que le joueur a lié à un suspect.
   - Non ajoutés (hors périmètre, nouvelles apps) : Fichiers, Appareil photo, Calculatrice.

8. **Nuit d'amélioration autonome (après la passe de polish)** — décisions prises sans validation,
   à relire :
   - Logo de l'accueil : **TRACE** (même cadre de capture) + une phrase d'accroche narrative.
   - Barre d'état : la pastille « −N s » passe sous le chrono (l'îlot la cachait) ; la batterie
     du téléphone saisi affiche un pourcentage qui baisse avec le temps (23 % → 4 %, décoratif).
   - Retour d'épinglage : toast sur deux lignes (« Ajouté au carnet · 3 » + ce qui a été ajouté),
     rebond de la capsule Carnet ; lier à un suspect dit où le retrouver.
   - **Lecture du joueur sur un élément lié** : « L'accuse » / « Le disculpe » dans la fiche du
     suspect (`NotebookEntry.stance`, `Investigation.setStance`). Gratuit, jamais vérifié par le
     jeu, sans effet sur le score ; remis à zéro si l'élément est lié à quelqu'un d'autre.
   - Fiche suspect : « Dans le téléphone » (nombre de messages et d'appels, raccourcis qui ferment
     le carnet et ouvrent l'app — au coût habituel), déclaration, notes, chaîne des éléments liés
     (quand · quoi · où) avec la lecture du joueur.
   - Chronologie du carnet : qui (avatar) et où (lieu, pour une photo analysée, un trajet, un
     rendez-vous) sous chaque élément.
   - Aide (ex-« Indices ») : 3 paliers nommés (Une piste · Où chercher · La preuve), ce que chacun
     apporte, son coût en points et le score maximal qui en résulte.
   - Moment du verdict (~2,5 s, touchable pour passer) : la personne accusée, « Vérification du
     dossier… », puis le tampon RÉSOLUE / NON RÉSOLUE.
   - Ouverture des apps en zoom depuis leur icône (iOS 18+, transition standard avant).
   - Mail : pièces jointes (noms seulement, « non téléchargée sur cet appareil ») — champ
     `attachments` facultatif dans l'affaire ; recherche globale sur leurs noms.
   - Photos : albums Toutes · Appareil photo · Reçues · Captures.
   - États vides crédibles dans chaque app.
   - Accueil du téléphone : widgets Batterie et « À venir » (prochain rendez-vous, ouvre le
     Calendrier) sur les écrans assez hauts ; alerte système « Batterie faible » à 10 %.
   - Carte d'affaire (Accueil, Affaires) : l'écran verrouillé du téléphone saisi au lieu du
     placeholder rayé. Profil : rang (un par affaire résolue) et 4 distinctions.
   - Couleur par événement dans le Calendrier ; « Distribué » sous le dernier message envoyé ;
     avatars d'expéditeur dans Mail ; « Tout est lu » au lieu de « 0 non lu ».
   - « Résoudre l'affaire maintenant ? » / « Désigner le responsable » (panneau du chrono).
   - Non fait, volontairement : app Fichiers, Appareil photo, Calculatrice (nouvelles apps sans
     données d'affaire), recherche dans Mail / Carte (une recherche coûte du temps : c'est la
     recherche globale qui le fait).

Ordre de travail décidé : 1) compilation réelle sur macOS ; 2) onboarding, reprise d'une enquête,
recherche globale ; 3) immersion (rail de dates, appel entrant, fiche photo + mini-carte, rangs) ;
4) polish (sons, animations, micro-interactions). Pas de grosse fonctionnalité avant que le parcours
Accueil → Affaires → Intro → Téléphone → enquête → Carnet → accusation → résultat soit stable.

## 2 bis. Évolution gameplay & immersion (septembre 2026)

- **Quitter l'enquête** : bouton ‹ à côté du Carnet, confirmation, sauvegarde ; « Reprendre » sur
  l'accueil et sur l'écran de l'affaire (« Recommencer » demande confirmation).
- **Niveaux** Enquêteur / Détective / Expert sur l'écran de présentation de l'affaire : durée,
  meilleur résultat par niveau (résolue, temps, score, nombre de tentatives), Expert verrouillé.
- **Carte réelle** (MapKit, système — pas de dépendance tierce) : pincer, zoomer, déplacer, double
  tap, boussole, échelle ; lieux en épingles, trajet en pointillés numérotés, position « moi ».
  Style sombre, sans commerces ni points d'intérêt. Les lieux apparaissent quand le joueur les
  découvre ailleurs (`revealedBy`). La carte stylisée reste en secours pour un lieu sans coordonnées.
- **Photos** : moteur de rendu procédural enrichi (styles selfie, nuit, document lisible, capture,
  flou, ancienne, prise à la volée ; grain, vignettage, flash). Les personnes restent des
  silhouettes floues (aucune illustration de personnage).
- **Séquence d'ouverture** générique (`introScene` dans l'affaire) : noir + sons, reportage,
  coupure + vibration, téléphone sur la table, déverrouillage → téléphone du jeu, même cadrage.
  Les couleurs du décor (bois, étiquette de scellé) sont du contenu généré, comme les photos.

## 2 ter. Une identité par affaire (#002–#005)

- **Téléphone** : fond d'écran propre à chaque propriétaire (`Theme.Wallpapers` : `night` #001, `ice` #002, `shore`
  #003, `gold` #004, `storm` #005), batterie de départ différente (9 %, 41 %, 31 %, 18 %), modèle différent. Le fond
  apparaît sur l'écran verrouillé de l'ouverture, l'accueil du téléphone et la carte de l'affaire.
- **Ouvertures** : nouveau type de plan `scene` (un lieu filmé : image générée, mouvement de caméra, effet — arrivée
  d'un train, coupure de courant, pluie, feux de détresse, soleil du matin), téléphone posé sur des surfaces
  différentes (banc de métro, table de chevet, table en marbre, siège passager), notifications empilées et appel
  entrant sur l'écran verrouillé. 12 nouvelles scènes photo, 11 nouveaux sons synthétisés.
- Les couleurs des surfaces et des scènes sont du contenu généré (comme les photos) ; l'interface reste en `Theme.*`.

## 3. Reste à faire (handoff)

- Affaire 000 (tutoriel jouable de 3 min) : reportée.
- Recherche : debounce en frappe continue (aujourd'hui une recherche = validation, car elle coûte du
  temps), résultat ouvert « centré et surligné 2 s » hors Messages.
- Rail années/mois dans une conversation, « Aller à une date ».
- ~~Transition « Déverrouillage » après l'intro~~ : faite (séquence d'ouverture `CinematicView`,
  qui se termine sur le téléphone du jeu).
- [24] Écran d'appel entrant plein écran + message vocal.
- [14] Fiche infos de photo en sheet avec mini-carte ; [15] curseur temporel de la carte synchronisé.
- Pile propre par app conservée en revenant à l'accueil, lien retour « ‹ App » 6 s entre apps.
- Rang et distinctions du Profil ; réglages Ambiance, Effets, Notifications en direct, Contraste élevé.
- Sons : faits pour l'ouverture (rue, sirènes, foule, vibration, voix), les notifications, le clavier
  à code, le déverrouillage, la fin du temps (réglage « Sons »). Reste : sons de navigation fins.
- Chargement « Déchiffrement… » [36], erreurs diégétiques [38], blocage 30 s après 2 codes faux [39].

## 4. Vérification

- Moteur, affaire, traductions fr/en et absence de vocabulaire de l'ancien prototype : `swift test`
  (38 tests) et `swift run CaseLint` passent sous Linux.
- **Compilation iOS : OK** (`ios-build.yml`, Xcode 26.3, SDK iOS 26.2, cible iOS 17).
- **Parcours principal validé sur simulateur** (`ScreenshotUITests`, joués à chaque push par
  `ios-build.yml` ; une capture par étape publiée sur la branche `ci/ui-screenshots`) :
  1. résolution anticipée : Accueil → Affaires → Intro → téléphone (chrono qui tourne) →
     notification en direct → Messages → conversation → épinglage (appui long) → Photos → photo →
     analyse → app Notifications → Carnet (Suspects, Preuves) → chrono → « Accuser maintenant ? » →
     accusation (maintenir) → résultat → reconstitution (la preuve épinglée apparaît « trouvée ») →
     score → Dossiers → reconstitution archivée ;
  3. onboarding : les 3 démos jouées (gestes détectés), puis absent au lancement suivant ;
  4. reprise : épingler → quitter (arrière-plan) → tuer l'app → 10 s → relancer → « Reprendre » →
     même écran, carnet intact, chrono repris là où il était (le temps hors de l'app ne compte pas),
     horloge cohérente → affaire terminée normalement → plus rien à reprendre ;
  5. recherche globale : « Quai 9 » (agenda + navigateur, pas le message supprimé, −8 s), filtre par
     app, ouverture du résultat dans l'Agenda, recherche par date « 12 sept » ;
  2. temps écoulé (durée raccourcie en Debug) → écran 00:00 → accusation forcée → mauvais suspect →
     résultat négatif (alibi, piège, manqués par app) → révéler la solution → reconstitution.
- Défauts trouvés et corrigés grâce à ces passages : chrono invisible dans le téléphone (masqué par
  les fonds des écrans), Carnet sans bouton de fermeture, pluriels (« 1 manquées »), texte tronqué
  de « Accuser maintenant ? », message-alibi d'Emma épinglé non compté comme preuve.
- Reste à vérifier sur un vrai iPhone : sensation tactile (appui long, maintien 1,2 s, glissements),
  vibrations, lisibilité réelle, performances, mise en arrière-plan / pause, VoiceOver, écran plus
  petit ou plus grand, notifications urgentes (lv07/lv08, non atteintes dans les tests).
