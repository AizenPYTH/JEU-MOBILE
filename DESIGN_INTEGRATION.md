# Intégration du handoff design SCREENSHOT v1.0

Source : `docs/design/` (non modifié). Ce document dit ce qui est intégré, ce qui reste à faire, et
les points où le handoff contredit le brief ou le moteur — **à trancher par le porteur de projet**.

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
| [08] Accueil du téléphone : tuiles « tableau périodique » 2 lettres, dock, badges, app verrouillée à .45 | `HomeScreen.swift` |
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

## 2. Conflits entre le handoff et le brief / le moteur — à trancher

1. **Contenu de l'affaire #001.** Le handoff décrit une autre histoire (dimanche 20 sept., coupable
   **Lucas**, noms Lemaire / Benali / Ferrand / Moreau, prêt de 4 000 €, 10 preuves E1–E10, 6 événements
   en direct). L'affaire livrée suit le brief initial : coupable **Emma**, samedi 12 sept., fausses
   factures du collectif, 6 preuves clés. Je n'ai pas réécrit l'histoire sans ton accord.
   → Garder l'affaire actuelle, ou la réécrire selon le handoff (c'est un seul fichier JSON, le moteur
   ne change pas) ?
2. **Coût en temps des actions.** Le brief demande que chaque action coûte du temps (ouvrir une
   conversation 3 s, analyser une photo 15 s…) ; le handoff ne parle que du temps réel et demande de
   charger l'historique ancien « sans spinner ». Le moteur applique les coûts (réglables dans
   `rules.json`, mettre 0 pour les supprimer).
3. **Définition de « trouvée ».** Une preuve est trouvée quand elle a été **vue** (brief). Le handoff
   laisse penser qu'il faut l'**épingler**. Actuellement : vue = trouvée, et l'épinglage compte dans
   la « Précision du carnet ».
4. **Apps.** Le handoff a une app **Fichiers** (vide) et pas d'app Notifications ; le téléphone livré a
   l'app **Notifications** (historique des notifications, demandé par le brief) et pas Fichiers.
5. **Affaire 000 « Premier accès »** (tutoriel) et **Mode sans chrono** : présents dans le handoff,
   absents du brief. Non faits.

## 3. Reste à faire (handoff)

- [01] Onboarding en 3 étapes jouables, puis Affaire 000.
- Reprise d'une partie en cours (« Continuer ») : l'enquête n'est pas encore sauvegardée.
- Recherche **globale** multi-apps avec chips et reconnaissance des dates en français (aujourd'hui :
  recherche dans Messages uniquement).
- Rail années/mois dans une conversation, « Aller à une date ».
- Animation d'ouverture d'app (zoom depuis la tuile), transition « Déverrouillage » après l'intro.
- [24] Écran d'appel entrant plein écran + message vocal.
- [14] Fiche infos de photo en sheet avec mini-carte ; [15] curseur temporel de la carte synchronisé.
- Pile propre par app conservée en revenant à l'accueil, lien retour « ‹ App » 6 s entre apps.
- Rang et distinctions du Profil ; réglages Ambiance, Effets, Notifications en direct, Contraste élevé.
- Sons (Ambiance, Effets).
- Chargement « Déchiffrement… » [36], erreurs diégétiques [38], blocage 30 s après 2 codes faux [39].

## 4. Vérification

- Moteur, affaire, traductions fr/en et absence de vocabulaire de l'ancien prototype : `swift test`
  (37 tests) et `swift run CaseLint` passent sous Linux.
- L'interface (ScreenshotUI) ne se compile qu'avec Xcode : elle n'a **pas** pu être compilée dans le
  conteneur. Le workflow macOS (`ios-testflight.yml`) la compilera ; à défaut, ouvrir le projet sur un Mac.
