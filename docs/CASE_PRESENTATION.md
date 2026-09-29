# Présentation d'une affaire — le dossier, sans cinématique

> Décision définitive du porteur de projet (septembre 2026) : **aucune cinématique vidéo** dans le jeu, ni
> aujourd'hui ni plus tard. Aucun écran ne lit, n'attend ni ne charge de vidéo. Les anciens prompts sont archivés
> dans `docs/archive/` (hors production). `NoCinematicTests` (CaseLibraryTests) échoue si un fichier vidéo, un
> lecteur vidéo (AVKit, AVPlayer, VideoPlayer) ou une clé de données `introScene` / `video` réapparaît.

## Le parcours

```
BUREAU ─ tap sur l'affaire ─▶ DOSSIER #00N (écran 02) ─ [OUVRIR LE TÉLÉPHONE] ─▶ ouverture courte ─▶ TÉLÉPHONE
```

- **Dossier** : un seul écran qui se lit de haut en bas en quelques secondes. Le contenu défile, le bouton
  principal reste fixe en bas. Rien ne se déclenche seul : le joueur lit à son rythme et ouvre le téléphone quand
  il veut (moins de 10 s suffisent).
- **Ouverture** (`CaseOpeningView`) : le sachet de scellé glisse, le téléphone en sort (1,8 s au plus). Un toucher
  passe directement au téléphone. #001 se déverrouille seul ; #002–#005 attendent un glissement vers le haut sur
  l'écran verrouillé. Le chrono ne tourne pas pendant l'ouverture.
- **Reprise** : si l'affaire est en cours, le bouton devient « Reprendre l'enquête » (temps restant, pièces gardées).

## Les sections du dossier et leurs données

| Section | Données (JSON de l'affaire) | Règle |
|---|---|---|
| DOSSIER #00N · titre · lieu · type | `number`, `title`, `dossier.city`, `dossier.category` | — |
| Statut · difficulté | état de la partie ; `dossier.rating` (1–5, sinon `difficulty` + 1) | Ouvert / en cours / classé |
| CONTEXTE | `synopsis` : le 1ᵉʳ paragraphe visible, la suite dépliable | 2 à 4 paragraphes courts (testé) |
| VOTRE MISSION | `objective` | Une phrase |
| PERSONNES CONCERNÉES | `dossier.subjectContact` + `suspects` (nom du contact, `role`) | Initiales, jamais de portrait ; rien ne dit qui ment |
| COMMENT ENQUÊTER | #001 seulement : Explorer · Verser · Relier · Conclure | Tutoriel |
| PREMIÈRE PISTE | `firstLead` | Où commencer, jamais qui : le validateur refuse le nom du responsable ; 20–160 caractères (testé) |

ENQUÊTES (#001–#005) et l'affaire du mode HISTOIRE (`story_001`) utilisent le même dossier. ALIBI garde son
propre briefing (une personne, une déclaration).

## Ajouter une affaire

Écrire ces champs dans le JSON (voir `docs/CASE_AUTHORING.md`), lancer `./scripts/test.sh`. Aucun code à toucher.
