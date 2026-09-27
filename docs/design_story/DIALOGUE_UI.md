# DIALOGUE_UI.md — Sous-titres, choix, silence, notifications, objets

Maquettes : h11 (dialogue), h12 (choix + objet montré).

## 1. Principe
Les dialogues s'affichent en **sous-titres de cinéma**, sans bulle. Le personnage reste entièrement visible dans le tiers supérieur et le tiers central.

## 2. Ligne de dialogue (`DialogueLine`)
- **Voile** (`scene.scrim`) : dégradé vertical sur les 300 pt du bas, de rgba(10,9,8,0) à 0,82 (à 42 %) puis 0,94.
- **Bloc** : marges latérales de 28 pt, bas à `safeArea.bottom` + 38 pt.
  - Ligne 1 : NOM (Plex Mono 11/700, +18 %, #EFEBE3) + FONCTION (Plex Mono 10, +10 %, #A9A397), espacés de 10 pt. Fonction masquée après la première réplique du personnage dans la scène.
  - Ligne 2 : réplique (Newsreader 22/400, interligne 1,35, entre « »), 3 lignes au maximum. Au-delà, découper la réplique en données.
- **Réplique du joueur** : nom du joueur, pas de fonction, et réplique en #C9C3B6 pour la distinguer.
- **Indicateur de suite** : « ▸ » en Plex Mono 12, #A9A397, en bas à droite. Il apparaît quand la réplique est entièrement affichée (pulsation d'opacité de 0,6 à 1 en 1,2 s, désactivée si Réduire les animations).
- **Affichage** : caractère par caractère à la vitesse du réglage (28 ms par défaut).
  - Premier tap : affiche la réplique entière.
  - Tap suivant : réplique suivante.
  - Appui long de 0,5 s : ouvre le JOURNAL.

## 3. Choix (`ChoiceRow`)
- **Déclencheur** : après la réplique qui pose la question. Celle-ci reste affichée au-dessus, en Newsreader 19 #C9C3B6, sans indicateur ▸.
- **Liste** : marges de 20 pt, espacement de 10 pt, lignes de 52 pt minimum. 2 ou 3 options + le silence (optionnel, défini dans les données).

| Rang | Préfixe | Filet | Fond | Texte |
|---|---|---|---|---|
| A (option 1) | « A » Plex Mono 11/700 | 1,5 pt #EFEBE3 | rgba(239,235,227,0.06) | Newsreader 16 #EFEBE3 |
| B, C | « B », « C » #A9A397 | 1 pt à 25 % | Transparent | Newsreader 16 #EFEBE3 |
| Silence | « — » #6F6A61 | 1 pt à 15 % | Transparent | Newsreader 16 italique #A9A397, texte « Ne rien dire » |

- L'ordre des options est fixe (pas d'aléatoire). A n'est pas « la bonne réponse » : c'est simplement la première.
- **Sélection** :
  1. la ligne choisie passe en filet plein pendant 150 ms, les autres en fondu à 0 en 200 ms ;
  2. sa réplique s'affiche en sous-titre joueur ;
  3. passage au plan suivant.
- **Pas de minuteur**, pas d'indication de conséquence (« Lacaze s'en souviendra » n'apparaît qu'en h16).
- **VoiceOver** : « Choix, 3 options. A : Non, jamais vue. … Ne rien dire. »

## 4. Autres éléments

| Élément | Rendu | Comportement |
|---|---|---|
| **Silence choisi** | Aucun sous-titre joueur ; plan CLOSE du PNJ pendant 2 s | Flag `silent` |
| **Objet montré** (`EvidenceChip`) | Fiche papier en bas (marges de 20 pt) : vignette de 44 pt, « MONTRER UNE PIÈCE » en LABEL, libellé de la pièce | N'apparaît que si le Carnet contient une pièce listée dans `choice.evidence`. Tap : l'objet passe en OBJECT FOCUS dans la scène (texture de la pièce sur une feuille 3D), puis réplique spécifique |
| **Notification pendant une scène** | Bandeau du téléphone du joueur (style téléphone existant, SF Pro), en haut, pendant 3 s | Uniquement si c'est scénarisé (ex. : « Inès : j'ai trouvé quelque chose »). Tap : aucun effet ; la scène continue |
| **Objet reçu** | Toast papier en haut « AJOUTÉ AU DOSSIER · Carte BEN » (Plex Mono 10), 2 s | Son `paper_slide` |
| **Lieu et heure** (ouverture de scène) | LABEL en haut à gauche : « BEN · BUREAU 312 · 21:04 », fondu entrant puis sortant sur 2,5 s | Premier plan WIDE uniquement |

## 5. JOURNAL
- Sheet sombre (#141311, rayon de 16 pt en haut), à 90 % de hauteur.
- Liste des répliques de la scène : nom en LABEL, texte en Newsreader 16, choix du joueur précédés de « ▸ ».
- Fermeture par swipe vers le bas. La scène est en pause pendant la lecture.

## 6. HUD
- Pilules en haut à droite : JOURNAL · AUTO (état ON = fond #EFEBE3, texte #1C1A17) · PASSER (scène déjà vue uniquement).
- Pas de bouton de pause visible : l'app en arrière-plan ou un tap sur JOURNAL met en pause.
