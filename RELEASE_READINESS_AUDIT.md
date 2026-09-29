# CONCLUDE : ENQUÊTES — Release readiness audit

**Date :** 29 septembre 2026 · **Studio :** NOREL GAMES · **Branche :** `claude/busy-hopper-5dgev5`
**Audit précédent (671 constats, état d'avant V3) :** archivé dans `docs/archive/RELEASE_READINESS_AUDIT_2026-09-26.md`.

## Verdict

**Pas encore prêt pour publication sur l'App Store.** Le jeu est complet, compile, et passe tous ses tests
automatiques (Linux + parcours complets sur simulateur). Il reste des **blocages externes** (URL de politique de
confidentialité et d'assistance, captures d'écran, nom définitif) et un **blocage qualité** : le design V4
« Dossier lisible » (sur les flux UX V3), intégré aujourd'hui, n'a encore été testé ni sur un iPhone réel ni par de vrais joueurs (§8 du handoff : 5 joueurs
sur #001). Un build TestFlight est la prochaine étape pour ce test.

## Ce qui a changé dans cette passe

0. **Design V4 « Dossier lisible »** (`docs/design_v4`, détail : `DESIGN_INTEGRATION.md`) : bureau en bois sombre,
   chemises kraft, feuilles, tirages agrafés, scellé, Carnet à intercalaires, fil rouge, tampons ; téléphone clair
   inchangé. Visuel seulement, aucune règle de jeu modifiée. **Mode Histoire sans 3D** : SceneKit retiré (décision du
   porteur de projet), scènes présentées en compte rendu d'entretien sur papier.

1. **Cinématiques supprimées définitivement.** Aucune vidéo, aucun lecteur vidéo, aucune séquence d'ouverture :
   `introScene` (modèle, validateur, CaseLint, JSON, générateurs) et le champ `video` des scènes HISTOIRE retirés.
   `NoCinematicTests` échoue si un fichier vidéo, AVKit/AVPlayer/VideoPlayer ou une clé `introScene`/`video` revient.
   Anciens prompts archivés (`docs/archive/`, marqués ARCHIVÉ / LEGACY).
2. **Présentation par le dossier** (`docs/CASE_PRESENTATION.md`) : contexte, mission, personnes, comment enquêter
   (#001), premières informations (nouveau champ `firstLead`, validé pour ne jamais nommer le responsable). Ouverture
   < 1 s, passable. Même dossier pour ENQUÊTES et l'affaire du mode HISTOIRE.
3. **Handoff UX V3 intégré** (`docs/design_ux_v3`, détail et écarts : `DESIGN_INTEGRATION.md`) : BEN plat sombre,
   téléphone clair, barre d'enquête, « + Verser au dossier » au toucher, pièce versée, Carnet poussé en 4 onglets
   (Pièces · Suspects · Chronologie · Connexions), Bureau à segments + carte d'affaire, conclusion / vérification /
   rapport, première impression, conseils une seule fois. 3 familles de polices (Geist, Caveat, JetBrains Mono et
   Instrument Serif supprimées ; IBM Plex Sans ajoutée, OFL).
4. **Aucune règle de jeu modifiée** (décision du porteur de projet). Le minimum de « 3 pièces » demandé par le
   handoff a été **refusé et retiré** (il n'existait nulle part avant) ; la solution reste montrée sur demande ;
   « Maintenir : {Prénom} est responsable » ; Alibi/Histoire gardent leur condition d'ouverture. Seule donnée nouvelle
   de partie : les Connexions (jamais requises, jamais notées, ignorées par le verdict — testé).
5. **App Store** : `docs/appstore/APP_STORE_METADATA.md` (fiche) et `docs/appstore/PRIVACY_POLICY.md` (à publier).

## Tests exécutés (tous verts)

| Suite | Résultat |
|---|---|
| `swift test` (CaseEngine, CaseLibrary, StoryEngine) | **133 tests OK** — dont NoCinematic, Connections, FirstLead, localisation fr/en, mots bannis, vocabulaire de l'ancien prototype, assets, pipeline photo (données) |
| `swift run CaseLint` | **9 affaires valides + histoire valide** (résolvables dans le temps, > 70 % de bruit) |
| `scripts/photos/test_pipeline.py` (pipeline photo : licences, rejet IA, catalogue) | **26 tests OK** |
| iOS – compilation simulateur (Xcode 26.3) | **OK** |
| Tests d'interface (XCUITest, 14 parcours) | **14 / 14 OK** (commit `e3b06cd`) : premier lancement (première impression → qui enquête → #001 → versement au badge → Carnet → conclusion → rapport → affectation → Bureau), parcours complet, recherche, quitter/reprendre (app tuée), pause/reprise depuis le dossier, niveaux, carte, #002–#005, code verrouillé, réglages (temps détendu, conseils), temps écoulé + mauvaise conclusion + reprise + solution, HISTOIRE (création, chapitre 1, reprise en pleine scène, bureau), ALIBI, défilement |

Bugs trouvés par ces tests et corrigés : bouton de maintien qui occupait tout l'écran (cartes suspects et verdicts
ALIBI masqués) ; « ‹ Dossier » qui renvoyait au Bureau (il ramène maintenant au dossier avec « Reprendre ») ; titre
du rapport en capitales.

## App Store — configuration vérifiée

| Élément | État |
|---|---|
| Bundle ID `com.aizenpyth.screenshot` | ✓ (inchangé, lié à TestFlight) |
| Nom sous l'icône « Conclude » | ✓ |
| Version `0.2.0` / build CI | ✓ — ☐ passer à 1.0.0 pour la sortie |
| iOS 17, iPhone seul, portrait, plein écran | ✓ |
| Icône 1024, écran de lancement (#1A140F + logo) | ✓ |
| Chiffrement non exempté : NON | ✓ |
| Manifeste de confidentialité (aucun suivi, aucune donnée collectée, UserDefaults CA92.1) | ✓ |
| Autorisations (`NS…UsageDescription`) | ✓ aucune — et aucune n'est utilisée |
| SDK tiers, publicité, analytics, comptes, achats, iCloud | ✓ aucun |
| Réseau | Seulement MapKit (fonds de carte Apple) et les liens de crédits ouverts dans le navigateur |
| Localisation fr / en | ✓ testée (clés, traductions, mots bannis) |
| Crédits photos (CC) et licences des polices (OFL) | ✓ |

## Blockers (à lever avant soumission)

1. **URL de politique de confidentialité** : publier `docs/appstore/PRIVACY_POLICY.md` (e-mail de contact à renseigner). *(externe)*
2. **URL d'assistance** : une page de contact. *(externe)*
3. **Captures d'écran iPhone 6,9"** (3 à 10) du design V4. *(à produire — les captures CI servent de base)*
4. **Nom App Store** : « CONCLUDE : ENQUÊTES » (logo) ou « CONCLUE : ENQUÊTES » (brief) — **à trancher**, puis
   vérifier la disponibilité. *(décision)*
5. **Test sur iPhone réel + test joueurs du redesign** (handoff §8 : premier versement < 90 s, personne ne demande
   « je fais quoi ? », chacun trouve le Carnet). *(qualité)*
6. Saisie App Store Connect : classification par âge (proposition 12+), description, mots-clés, copyright, catégorie
   secondaire — brouillons fournis dans `APP_STORE_METADATA.md`. *(externe)*

## Non bloquant

- Code resté sans usage après le redesign (anciens écrans titre, ancien bureau à 3 chemises, ancien bouton de
  maintien, objets papier) et quelques images (textures papier, tampons autres que RÉSOLU, bandeau du logo, < 1 Mo)
  encore exigées par `ArtAssetsTests` : nettoyage à faire dans une passe dédiée.
- Maquettes HTML du handoff UX V3 non livrées : l'intégration suit le texte ; à comparer quand elles arriveront.
- Portraits des suspects : initiales seulement (voulu : aucune image IA).
- Mode HISTOIRE : chapitres 03–05 annoncés, pas encore jouables (affichés comme tels).
- VoiceOver et Dynamic Type (tailles AX) conçus mais pas encore vérifiés sur appareil.

## Décisions restantes pour le porteur de projet

- Nom App Store (voir blocker 4) et version 1.0.0.
- Nettoyage des éléments inutilisés (oui / plus tard).
