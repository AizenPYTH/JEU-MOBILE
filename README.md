# SCREENSHOT (nom de travail)

Jeu iOS d'investigation numérique : vous avez quelques minutes pour fouiller le téléphone d'une
personne liée à une affaire, croiser messages, appels, photos, localisations, notes et recherches,
et désigner le bon suspect avant la fin du temps.

## Builds TestFlight (sans Mac)

Tout passe par GitHub Actions : suivre `docs/TESTFLIGHT_SETUP.md` une fois, puis
**Actions → iOS – Build & TestFlight → Run workflow**.

## Tester le moteur et les affaires

```bash
./scripts/test.sh
```

## Écrire une affaire

Une affaire est un fichier JSON dans `ScreenshotKit/Sources/CaseLibrary/Resources/Cases/`.
Voir `docs/CASE_AUTHORING.md`. `swift run CaseLint` vérifie qu'elle est valide et résolvable.

Voir `CLAUDE.md` pour l'architecture et les principes du jeu.
