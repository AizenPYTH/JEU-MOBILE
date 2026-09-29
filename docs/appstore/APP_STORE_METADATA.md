# App Store Connect — fiche de l'application (brouillon)

Valeurs **vérifiées dans le projet** marquées ✓ ; valeurs **à décider / saisir** par le porteur de projet marquées ☐.

## Identité et build

| Champ | Valeur | Source |
|---|---|---|
| Bundle ID | `com.aizenpyth.screenshot` ✓ (ne pas changer : TestFlight y est lié) | `Configs/Screenshot.xcconfig` |
| Nom sous l'icône | « Conclude » ✓ | `INFOPLIST_KEY_CFBundleDisplayName`, `Screenshot/InfoPlist.xcstrings` |
| Nom App Store (30 car. max) | ☐ « CONCLUDE : ENQUÊTES » (logo, CLAUDE.md) **ou** « CONCLUE : ENQUÊTES » (brief) — **à trancher**, puis vérifier la disponibilité dans App Store Connect | — |
| Version | 0.2.0 ✓ (☐ passer à 1.0.0 pour la sortie) | `MARKETING_VERSION` |
| Build | `<run_number + BUILD_NUMBER_OFFSET>.<attempt>` ✓ | `ios-testflight.yml` |
| Cible | iOS 17.0 ✓, iPhone uniquement ✓ (`TARGETED_DEVICE_FAMILY = 1`), portrait ✓, plein écran ✓ | `project.pbxproj` |
| Catégorie | Jeux › Réflexion (`public.app-category.puzzle-games`) ✓ ; secondaire ☐ Aventure | `LSApplicationCategoryType` |
| Écran de lancement | fond + tuile du logo ✓ | `Configs/Info.plist` |
| Icône | 1024 × 1024, un seul fichier ✓ | `Screenshot/Assets.xcassets/AppIcon.appiconset` |
| Chiffrement | `ITSAppUsesNonExemptEncryption = NO` ✓ (aucun chiffrement propre) | `project.pbxproj` |
| Copyright | ☐ « © 2026 NOREL GAMES » | — |

## Confidentialité (« App Privacy »)

- **Données collectées : aucune** (« Data Not Collected ») ✓ — aucun SDK tiers, aucune analyse, aucun compte,
  aucune publicité, aucun achat (vérifié dans le code : pas d'URLSession, pas de StoreKit, pas d'ATT, pas de CloudKit).
- **Suivi (tracking) : non** ✓ (`NSPrivacyTracking = false`, aucun domaine de suivi).
- **Manifeste de confidentialité** ✓ `Screenshot/PrivacyInfo.xcprivacy` : API à justification — `UserDefaults`
  (CA92.1). Pas d'horodatage de fichiers, d'uptime ni d'espace disque utilisés (vérifié).
- **Autorisations** : aucune clé `NS…UsageDescription` ✓ — le jeu n'en demande aucune (MapKit n'affiche que des lieux
  fictifs, sans position de l'utilisateur).
- **URL de politique de confidentialité** : ☐ **obligatoire** — publier `docs/appstore/PRIVACY_POLICY.md`.
- **URL d'assistance** : ☐ **obligatoire** — une page avec un moyen de contact.

## Classification par âge (questionnaire) — proposition ☐

Contenu vérifié dans les affaires : disparitions, chute grave (coma), vol, fraude, mentions d'alcool en soirée
(« ivre »), aucune image violente, aucune scène sexuelle, pas de jeu d'argent, pas de contenu généré par
d'autres joueurs, pas de navigateur web réel.
Réponses proposées : violence réaliste **rare / légère** ; thèmes matures ou suggestifs **rares / légers** ;
alcool, tabac, drogues **rare / léger** ; tout le reste **aucun**. Résultat attendu : **12+** (à confirmer).

## Textes (fr)

- **Sous-titre** (30 car.) ☐ : « Un téléphone. À vous de conclure. »
- **Mots-clés** (100 car.) ☐ : `enquête,détective,mystère,téléphone,indices,suspect,alibi,polar,énigme,investigation`
- **Texte promotionnel** ☐ : « Fouillez le téléphone d'une personne disparue. Chaque action coûte du temps. »
- **Description** ☐ :

  > On vous confie le téléphone d'une personne liée à une affaire. Quelques minutes pour le fouiller : messages,
  > appels, photos, agenda, notes, lieux. Chaque action coûte du temps.
  >
  > Versez au dossier ce qui compte, reliez les pièces et les personnes, puis désignez le responsable. Le jeu ne
  > conclut jamais à votre place : un mauvais choix s'explique, et la solution complète n'est montrée que si vous
  > la demandez.
  >
  > • 5 enquêtes, de très accessible à intermédiaire
  > • Mode ALIBI : une déclaration, un téléphone, vérifiez-la
  > • Mode HISTOIRE : votre carrière au Bureau des enquêtes numériques
  > • Aucune publicité, aucun compte, aucune donnée collectée
  >
  > Toutes les personnes, conversations et lieux sont fictifs. Photographies réelles sous licence libre (crédits
  > dans l'application).

## Captures d'écran ☐ (bloquant pour la soumission)

- Requises : iPhone 6,9" (1320 × 2868 ou 1290 × 2796) ; 6,5" facultatif si 6,9" fourni. 3 à 10 par langue.
- Source possible : les captures des tests d'interface publiées par la CI sur la branche `ci/ui-screenshots`
  (simulateur), **une fois le design UX V3 validé** ; à refaire en taille 6,9".
- Suggestion d'ordre : Bureau · Dossier #001 · Téléphone (Messages) · « Verser au dossier » · Carnet ›
  Connexions · Conclusion · Rapport.

## Divers

- Pas d'achat intégré, pas d'abonnement, pas de Game Center, pas de connexion : rien à déclarer.
- Crédits photos (CC BY / CC BY-SA / CC0) affichés dans Paramètres › À propos ✓ (`PhotoCredits.json`).
- Polices : Newsreader, IBM Plex Sans, IBM Plex Mono — OFL ✓ (licences dans `Resources/Fonts`).
