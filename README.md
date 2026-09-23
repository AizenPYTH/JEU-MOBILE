# Bistro (nom de code)

Jeu iOS idle « cozy » de gestion de bistrot de quartier : labo de recettes + habitués.

## Builds TestFlight (sans Mac)

Tout passe par GitHub Actions : suivre `docs/TESTFLIGHT_SETUP.md` une fois, puis
**Actions → iOS – Build & TestFlight → Run workflow**.

## Démarrer (Mac, facultatif)

1. Xcode 16 ou plus récent.
2. Ouvrir `Bistro.xcodeproj`. Xcode charge automatiquement le package local `BistroKit`.
3. Dans la cible *Bistro* > *Signing & Capabilities*, choisir votre équipe. Le bundle ID se change
   dans `Configs/Bistro.xcconfig`.
4. Lancer sur un simulateur iPhone.

## Tester le moteur

```bash
./scripts/test.sh
```

## Équilibrer / ajouter du contenu

- Équilibrage : `BistroKit/Sources/GameData/Resources/Config/*.json`
- Contenu : `BistroKit/Sources/GameData/Resources/Content/*.json`
- Textes (en/fr) : `BistroKit/Sources/BistroUI/Resources/Localizable.xcstrings` (éditeur intégré à Xcode)

Après une modification, lancez `./scripts/test.sh` : les tests signalent toute erreur (id inconnu,
doublon, traduction manquante…).

Voir `CLAUDE.md` pour l'architecture et `HANDOFF_INTEGRATION.md` pour l'intégration du design.
