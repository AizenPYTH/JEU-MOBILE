# Intégration des photos dans le jeu

## D'où vient une photo à l'écran

Toutes les photos du téléphone saisi sont décrites dans les affaires (`case_00N.json › devices[].photos[]` : `id`,
`scene`, `style`, `caption`, `details`, `lines`, `takenAt`…). Elles s'affichent dans :

| Écran | Vue | Taille à l'écran |
|---|---|---|
| Photos › grille | `PhotosViews.swift` (`GeneratedPhoto`, recadrage carré) | ≈ 130 pt |
| Photos › détail (zoom, analyse) | `PhotoDetailView` (4:3 pleine largeur) | ≈ 390 × 292 pt |
| Messages › photo reçue/envoyée | `MessageBubble` | 200 × 150 pt |
| Carnet › pièce versée | `ExhibitView` (`Components/Dossier.swift`) | ≤ 200 pt de haut |
| Feuille « Verser au dossier » | `FilingSheet` | 78 × 78 pt |

Toutes passent par **`GeneratedPhoto(photo:)`**. Depuis le pipeline :

1. `GeneratedPhoto` cherche **`ArtLibrary.photo(case:id:)`**, c'est-à-dire l'image `caseNNN_photo_<id>` dans
   `ScreenshotUI/Resources/Art.xcassets/Photos` (le numéro d'affaire vient de l'environnement `\.caseNumber`,
   déjà posé par chaque écran d'affaire).
2. Si elle existe (photo d'ambiance préparée par le pipeline), elle est affichée **à la place du dessin**, en
   remplissant le cadre sans le déborder.
3. Sinon (preuve, personne, texte, capture, ou source introuvable), le **rendu procédural** habituel est peint.
4. Dans les deux cas, les effets de style du jeu s'appliquent par-dessus : nuit (grain, désaturation), flou, bougé
   (inclinaison), vieille photo (tons sépia, bord blanc), flash de selfie, vignettage.

Rien d'autre ne change : le moteur, les affaires, les preuves, l'analyse des métadonnées (« Analyser ») et le texte des
légendes restent ceux de l'affaire. Une preuve reste toujours dessinée par le jeu tant qu'aucune image sur mesure n'est
fournie.

## Nom des fichiers

`case<NNN>_photo_<photoId>` — le numéro de l'affaire sur 3 chiffres et l'identifiant de la photo dans l'affaire
(`case001_photo_p_b01`). Déterministe : le nom se déduit des données, aucun tableau de correspondance à maintenir
dans le code. Les sources téléchargées s'appellent `caseNNN_src_<requête>_<n>` dans le catalogue et le manifeste.

## Hors ligne

Les images sont dans le catalogue d'assets du paquet `ScreenshotUI` : elles sont compilées dans l'app. Le jeu ne
contient aucun appel réseau vers un service photo (vérifié par `PhotoPipelineTests.theGameNeverCallsAPhotoApi`).
Seuls les liens de l'écran « Crédits photos » ouvrent Safari, à la demande du joueur.

Mémoire : les photos ne sont pas gardées dans le cache permanent d'`ArtLibrary` (contrairement aux portraits) ; le
cache système d'`UIImage(named:)` les libère en cas de besoin.

## Crédits

`ScreenshotUI/Resources/PhotoCredits.json` (généré par `report`) → **Paramètres › À propos › Crédits photos**
(`Screens/PhotoCredits.swift`) : « Photos fournies par Pexels » avec un lien vers pexels.com si une image Pexels est
livrée, puis pour chaque image : le texte d'attribution, un lien vers la page source, la licence et son lien. Le bouton
n'apparaît que s'il y a au moins une image externe.

## Remplacer une photo par une image sur mesure

Une image faite à la main (preuve, personne de l'affaire) se dépose sous le même nom `caseNNN_photo_<id>` dans un
**autre** groupe du catalogue d'assets (par exemple `Art.xcassets/Custom/`, pas `Photos/` qui appartient au
pipeline) : `GeneratedPhoto` l'affichera de la même façon. Mettre alors la photo en `"manual": true, "decision":
"KEEP"` dans `config/photo_catalog.json` pour que le pipeline ne s'en occupe plus.

## Taille de l'app

Environ 100 à 150 Ko par photo préparée (1024 × 768, JPEG 76) : pour les 72 photos d'ambiance, ≈ 8 à 10 Mo au
maximum (voir `./scripts/photos.sh status`, ligne « images prêtes », pour la valeur réelle).
