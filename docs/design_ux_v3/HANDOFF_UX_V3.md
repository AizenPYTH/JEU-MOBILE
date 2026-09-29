# CONCLUDE : ENQUÊTES — HANDOFF UX V3 · « Digital Investigation Interface »

NOREL GAMES · 2026-09-29 · pour Claude Code.

- **Maquettes** : `CONCLUDE - Refonte UX V3.dc.html`, écrans 00 à 13.
- **Principe** : on refait la forme de l'interface. Le fond du jeu (histoires, personnages, mécaniques, téléphone, preuves, Carnet, conclusion) reste identique.
- **Nom** : le logo reste CONCLUDE : ENQUÊTES. Le brief écrit « CONCLUE », mais le nom verrouillé n'est pas modifié.

## 0. Ce qui remplace quoi
- Cette V3 **remplace** les règles visuelles des documents suivants :
  - `final/FINAL_DESIGN_HANDOFF_CONCLUDE.md` §G ;
  - `story/DESIGN_SYSTEM_STORY.md` §2–4.
- Ces règles remplacées concernent la texture, la rotation et le papier partout, les capitales en Mono et la police Geist.
- **Conservés** :
  - les flux et les données ;
  - le vocabulaire (dossier, pièce, verser, Carnet, conclure) ;
  - les écrans Histoire, qui sont à re-skinner avec les tokens ci-dessous ;
  - le téléphone.
- **Le papier survit uniquement comme contenu** : un document de l'affaire affiché dans une pièce (reçu, rapport de police, note manuscrite scannée) peut garder sa texture. L'interface du BEN, elle, n'est jamais en papier.
- Les tampons PNG restent utilisés pour un seul moment : le passage OUVERT → RÉSOLU sur la CaseCard (§6).

## 1. Audit (résumé)

| Priorité | Problème | Correction |
|---|---|---|
| P0 | « Verser au dossier » caché derrière un appui long sans indication | Bouton visible `EvidenceBadge` après un tap sur un élément. L'appui long reste un raccourci |
| P0 | Pas d'action principale évidente | Un seul bouton bleu par écran, en bas |
| P0 | Les trois modes à égalité, l'affaire en cours noyée | Contrôle segmenté pour les modes, grande CaseCard au centre |
| P1 | Majuscules Mono partout | Plex Sans pour l'interface, Mono pour les données uniquement |
| P1 | 4 familles de polices | 3 familles, Caveat supprimée |
| P1 | Textures, rotations, ombres | Surfaces plates, aucune rotation |
| P1 | Contrastes secondaires < 4,5:1 | Nouveau text2 à 7,6:1 |
| P1 | Onglets du Carnet petits, sans compteur | Contrôle segmenté à 4 onglets avec compteurs |
| P2 | Connexions en graphe | Chaînes verticales dont chaque lien est expliqué |
| P2 | Téléphone et BEN visuellement proches | Téléphone clair, BEN sombre, barre BEN persistante |

**Inventaire des écrans touchés**
- Lancement
- Bureau
- Sélection des modes
- Liste des affaires
- Dossier / briefing
- Téléphone (accueil + 11 apps, pour la barre et le bouton Verser uniquement)
- Fiche pièce
- Carnet (4 onglets)
- Conclusion
- Vérification
- Rapport
- Archives
- Profil enquêteur
- Paramètres
- Écrans Alibi et Histoire (re-skin)

## 2. Direction artistique
- **Le BEN** est un logiciel d'enquête professionnel : sombre bleu-graphite, surfaces plates, typographie éditoriale pour les titres, sans-serif très lisible pour l'interface, Mono pour tout ce qui est donnée (heure, numéro, chrono).
- **Le téléphone** est un vrai téléphone : fond clair, police du système (SF Pro), couleurs d'app standard, bulles bleu et gris.
- **Signature** : on entre dans un appareil lumineux, mais la barre sombre du BEN reste toujours visible en bas. On sait toujours qu'on enquête.
- **Interdits** :
  - néon, lueurs, scanlines, HUD, grilles techniques décoratives ;
  - rotations, textures sur l'interface, ombres portées sur fond sombre ;
  - plus d'une couleur d'accent sémantique par carte.

## 3. Tokens

### Couleurs

| Token | Hex | Usage |
|---|---|---|
| bg | #0B0E13 | Fond des écrans BEN |
| bgDeep | #07090C | Conclusion, vérification (moment solennel) |
| surface | #141A22 | Cartes |
| surface2 | #1C242F | Contrôles, boutons secondaires, champs |
| surface3 | #2A3442 | Segment actif, avatars de repli |
| line | rgba(214,224,236,0.08) | Filets et bordures de carte (1 pt, en inset) |
| text | #EEF1F4 | Texte principal |
| text2 | #9AA6B4 | Texte secondaire (7,6:1 sur bg) |
| text3 | #6F7C8C | Désactivé, méta tertiaire (≥ 4,5:1 à partir de 14 pt) |
| ben | #3F6FC2 | Action principale (texte blanc, 4,9:1), sélection |
| benPressed | #345EA8 | Bouton principal enfoncé |
| benText | #8FB2EE | Liens, numéros de dossier et de pièce, « ‹ Retour » |
| critical | #E5484D (texte sur sombre #F07B7F) | Accusation, échec, erreur, pastille de non-lus du téléphone |
| success | #3FB27F (texte #6FD3A4) | Versé, résolu |
| warning | #E8A03A | Contradiction, indice manqué |
| tint(x) | x à 16 % d'opacité | Fond des badges sémantiques |
| phoneBg | #FFFFFF / #F6F6F8 (barres) | Téléphone |
| phoneText | #111111 / #8A8A8E | Téléphone |
| phoneBlue | #2F6FE4 | Bulles envoyées, liens du téléphone |
| phoneBubble | #E9E9EB | Bulles reçues |

**Règle** : sur un même écran, au plus une couleur sémantique en plus du bleu. Le vert et le rouge ne sont jamais utilisés comme décoration.

### Typographie
3 familles : Newsreader, IBM Plex Sans, IBM Plex Mono. La police système est réservée au téléphone.

| Rôle | Police | Taille/graisse | Interligne | Usage |
|---|---|---|---|---|
| display | Newsreader | 36/500, interlettrage −1 % | 1,05 | Question de la conclusion |
| title | Newsreader | 30–32/500 | 1,05 | Titre d'écran, titre d'affaire |
| quote | Newsreader | 19/400 | 1,35 | Citation d'une pièce |
| headline | Plex Sans | 17–19/600 | 1,25 | Nom de suspect, titre de carte, bouton (17/600) |
| body | Plex Sans | 16/400 | 1,5 | Contexte, mission |
| callout | Plex Sans | 14–15/400 | 1,4 | Contenu de carte |
| section | Plex Sans | 12/600, capitales, +8 % | — | En-têtes de section. Seul usage des capitales |
| caption | Plex Sans | 12–13/400 | 1,4 | Méta |
| data | Plex Mono | 11–13/600 (numéros), 15–20/500 (chrono, chiffres) | — | PIÈCE 03, #001, 23:47, 06:58, 87 % |

**Dynamic Type** : tous les rôles Plex Sans et Newsreader suivent la taille système. Plafond à xxxLarge pour title et display ; au-delà, les grilles à 2 colonnes (conclusion, rapport) passent à 1 colonne. Les données Mono suivent aussi (minimum 11).

### Espacements, rayons, hauteurs

| Catégorie | Valeurs |
|---|---|
| Espacements | 4 · 8 · 12 · 16 · 20 · 24 · 32 · 48 |
| Marges | 16 pt pour les cartes, 20 pt pour les textes pleine largeur |
| Rayons | badge 13 (pilule) · contrôle segmenté 12 (segment 9) · bouton 14 · carte 16 · grande carte 20 · feuille modale 20 |
| Hauteurs | bouton 54–56 · maintien 60 · ligne de liste 50 · segment 40 (dans une zone tactile de 44) · barre d'onglets 82 · barre d'enquête 92 |
| Profondeur | cartes sans ombre, filet 1 pt `line` en inset · feuille modale 0 20 50 noir à 50 % |

## 4. Navigation

```
Lancement ── 00 Première impression (1ʳᵉ fois) ── 01 Bureau
Barre d'onglets : BUREAU · ARCHIVES · ENQUÊTEUR  (écrans BEN hors enquête)
01 Bureau ─ contrôle segmenté [Enquêtes | Alibi | Histoire]
   Enquêtes → CaseCard → 02 Dossier → 03 Téléphone ⇄ 06–09 Carnet
                                       └→ 10 Conclusion → 11 Vérification → 12 Rapport → Bureau
   Alibi    → liste d'alibis → flux Alibi existant
   Histoire → hub Histoire (story/)
```

- **Règle « où suis-je »** : chaque écran BEN affiche en haut à gauche « ‹ {écran précédent} » en benText (zone tactile de 44 pt), et un titre en Newsreader. Le geste de retour par le bord est toujours actif.
- **En enquête, la barre d'onglets disparaît.** Elle est remplacée par la **barre d'enquête** (`InvestigationBar`), dans le téléphone comme dans le Carnet :
  - à gauche : « ‹ Dossier » ;
  - au centre : le chrono (Mono 20) et « n pièces versées » ;
  - à droite : « Carnet » (bouton surface2).
- **Dans le Carnet**, « ‹ Téléphone » en haut, et le chrono à droite. Le Carnet est un écran poussé (push), pas une feuille modale, pour que les 4 onglets aient toute la hauteur.
- **Accès à la conclusion** : « Conclure l'enquête » en bas du Carnet (bouton principal), visible à partir de 3 pièces versées. En dessous de 3 pièces, le bouton est désactivé avec « Versez au moins 3 pièces ». À 00:00, on bascule automatiquement vers l'écran 10.

## 5. Composants
États communs : normal · pressé (échelle 0,98 + fond plus sombre, 90 ms) · désactivé (surface2 + text3) · sélectionné (filet ben de 2 pt) · terminé (badge success) · erreur (filet critical + message).

| Composant | Anatomie | États spécifiques |
|---|---|---|
| CaseCard | Photo 176 pt (placeholder rayé) + pastille d'état ; `#001` data benText ; title ; « Lieu · Type » callout text2 ; grille de 3 métadonnées (Difficulté, Durée, Pièces) ; bouton principal | Nouvelle (pastille « ● Nouvelle affaire ») · En cours (bouton « Reprendre », pièces n/N, chrono restant) · Résolue (badge ✓, bouton secondaire « Voir le rapport ») · Verrouillée (ligne de liste, condition « Après #00N ») |
| ModeCard | Icône 48 pt (glyphe simple en filet de 2 pt benText) ; headline ; sous-titre en benText ; une phrase en body text2 ; méta caption | Actif (filet ben de 1,5 pt) · Verrouillé (opacité 60 %, méta = condition) |
| SuspectCard | Photo 56 × 70 pt (repli : initiales) ; nom headline + âge ; relation ; « Alibi · … » ; StatusBadge + « n pièces » | Accusé (↑ n l'accusent, critical) · Disculpé (↓ n le disculpe, success) · Neutre (Rien de relevé) |
| EvidenceCard | « PIÈCE nn » data ; « type · source » caption ; contenu callout (3 lignes, puis « Lire plus ») ; ligne de liens | Non reliée · Reliée · Sélectionnée (mode relier) · Contradiction (filet warning + « ≠ contredit PIÈCE nn ») |
| EvidenceBadge | Pilule #0B0E13, 30 pt (zone tactile de 44), « + » benText + « Verser au dossier » en Plex Sans 13/600. Placée sous l'élément, alignée sur son bord | Visible · Déjà versée (« ✓ Pièce 03 », tint success) · Masquée |
| EvidenceSheet (05) | Feuille surface de rayon 20 au-dessus de la barre ; « PIÈCE nn » + badge « ✓ Versée au dossier » ; aperçu de l'élément (surface2) ; phrase d'aide ; [Relier] secondaire + [Continuer] clair | Se referme seule après 2,5 s |
| ConnectionChain | Carte surface ; en-tête section « CONNEXION n · titre » ; nœuds (surface2, rayon 12, étiquette data + texte) ; connecteur vertical de 2 × 28 pt + verbe | Couleur du verbe : contredit = warning, confirme = success, même lieu/heure/implique = benText |
| ConclusionCard | Photo en grand (flex) ; nom headline ; relation caption | Sélectionnée (filet ben de 2 pt + coche 26 pt), les autres à 55 % |
| ReportCard | Libellé caption + valeur data 19/500, couleur sémantique | — |
| ActionButton | Principal ben / secondaire surface2 / tertiaire contour 1,5 pt à 20 % / destructif critical / maintien (fond surface2, remplissage ben de gauche à droite) | Chargement : « ··· » qui pulse · Terminé : tint success + ✓ |
| SectionHeader | section text2, marge basse de 10 | — |
| NotebookTab | Contrôle segmenté de 4 × 40 pt dans surface ; libellé + compteur data 10 | Actif : surface3 + texte text/600 |
| StatusBadge | Pilule de 26 pt : symbole + libellé (● ◐ # ✓ ✕ ↑ ↓ ≠) | Jamais la couleur seule |
| PhoneAppIcon | Carré de 62 pt, rayon 15, **SF Symbol** blanc (`message.fill`, `phone.fill`, `photo.on.rectangle`, `map.fill`, `calendar`, `note.text`, `envelope.fill`, `person.2.fill`, `globe`, `folder.fill`, `trash.fill`), libellé 12, pastille critical | Les lettres des maquettes sont des placeholders |
| InvestigationBar | 92 pt, bg, filet haut `line` ; grille 1fr/auto/1fr | Pièce versée : compteur en success pendant 1,5 s, bouton Carnet avec un halo ben de 2 pt pendant 1,5 s · chrono < 01:00 : chiffres en warning · < 00:10 : critical |

## 6. Écrans
Pour chaque écran : **test de compréhension** = question à laquelle un nouveau joueur doit pouvoir répondre en 3 s.

- **00 · Première impression** (1ᵉʳ lancement uniquement)
  - Test : « C'est un jeu d'enquête sur téléphone. »
  - Logo en Mono 15/600. 5 étapes affichées (icône 52 pt + titre + une ligne), qui s'allument successivement toutes les 0,9 s (opacité 0,3 → 1, décalage de 8 pt). La tuile 2 est claire, comme le téléphone.
  - Phrase en Newsreader 26 : « Un téléphone. Une disparition. À vous de conclure. » Bouton [Commencer], qui apparaît à 4,5 s.
  - Un tap n'importe où avant la fin affiche l'état final. Pas de vidéo, pas de musique imposée.
  - [Commencer] → choix de l'enquêteur (doc 06, re-skinné) → 01.
- **01 · Bureau**
  - Test : « J'ouvre #001. »
  - Contenu :
    - mention CONCLUDE : ENQUÊTES + avatar 36 pt (→ Profil) ;
    - title « Bonjour, {Prénom} » ;
    - contrôle segmenté des modes ;
    - CaseCard de l'affaire en cours, ou de la prochaine ;
    - « Autres affaires » : lignes de 50 pt ;
    - barre d'onglets.
  - L'état du segment est mémorisé. Alibi et Histoire sont verrouillés jusqu'à la conclusion de #001 : un tap affiche la carte 01b, avec leur condition.
  - Autres états : chargement (squelettes surface sans texte), aucune affaire en cours (CaseCard de la prochaine affaire non jouée), tout résolu (CaseCard « Toutes les affaires sont classées » + lien Archives).
- **01b · Modes**
  - Affiché au premier accès à un mode non encore ouvert. Il présente les 3 ModeCards. Tap → mode.
- **02 · Dossier**
  - Test : « Je dois trouver qui ment, dans ce téléphone. »
  - Ordre fixe :
    - ‹ Bureau ;
    - « DOSSIER #001 » data, title, « Lieu · Type » ;
    - CONTEXTE : 2 phrases maximum ;
    - VOTRE MISSION : carte surface avec filet gauche ben de 3 pt, une phrase ;
    - PERSONNES : avatars de 56 pt, prénom, relation. Tap → fiche suspect en feuille modale ;
    - COMMENT ENQUÊTER : **#001 uniquement**, 4 tuiles Explorer, Verser, Relier, Conclure, la tuile en cours surlignée en ben ;
    - PREMIÈRES INFORMATIONS : liste des éléments de départ de l'affaire, si le JSON en contient.
  - Pied fixe : [Ouvrir le téléphone] + « n pièces versées au dossier ».
  - Le contenu défile, le pied reste fixe.
  - Si l'affaire est en cours, le bouton devient « Reprendre l'enquête · 06:58 ».
- **03 · Téléphone**
  - Test : « Je suis dans le téléphone d'Alex. »
  - Écran d'accueil clair : fond d'écran (placeholder), heure et batterie de l'appareil en fiction, « Téléphone d'Alex Moreau » en 13 pendant 3 s puis masqué.
  - Grille de 4 colonnes et 11 apps (liste fixe, ordre ci-dessus).
  - InvestigationBar.
  - **Guidage #001** : la première fois, l'app Messages pulse (échelle 1 → 1,04, 2 cycles) et une bulle BEN (surface, texte clair) dit « Commencez par les messages. », jusqu'au premier tap. Aucun autre tutoriel.
- **04 · Conversation / éléments versables**
  - Test : « Je peux garder ce message comme preuve. »
  - Tap sur un élément (bulle, photo, appel, entrée d'agenda, note…) :
    - l'élément reçoit un filet ben de 2 pt ;
    - l'`EvidenceBadge` apparaît dessous (fondu + décalage de 4 pt, 150 ms) ;
    - un tap ailleurs le fait disparaître.
  - Le badge est proposé **pour tout élément**, pour ne jamais révéler lesquels sont importants.
  - L'appui long de 0,5 s reste un raccourci qui verse directement.
  - **#001 uniquement** : la première bulle versable pulse une fois et une bulle BEN dit « Touchez un message pour le verser au dossier. ».
- **05 · Pièce versée**
  - Test : « C'est enregistré, je continue. »
  - Voile noir à 35 % sur le téléphone, EvidenceSheet.
  - Une copie de l'élément vole vers le bouton Carnet (450 ms, spring standard). Le compteur passe à n+1 et vire au vert pendant 1,5 s. Haptique `success`.
  - Si c'est la 3ᵉ pièce : phrase supplémentaire « Vous pouvez maintenant conclure depuis le Carnet. ».
  - L'élément garde ensuite un badge « ✓ Pièce 03 ».
  - Un élément déjà versé ne propose plus le badge Verser, mais « Voir la pièce ».
- **06 · Carnet › Suspects**
  - Test : « Voilà ce que je sais sur chacun. »
  - SuspectCard par personne. Tap → fiche : photo, relation, alibi, pièces liées (EvidenceCards), boutons « L'accuse » / « Le disculpe » pour qualifier une pièce, selon la mécanique existante.
- **07 · Carnet › Pièces**
  - Liste d'EvidenceCards, de la plus récente à la plus ancienne. Filtre en pilules par type (Tous, Messages, Photos, Appels…) si plus de 6 pièces.
  - Tap → détail + [Relier] + « L'accuse / Le disculpe ».
- **08 · Carnet › Chronologie**
  - En-tête du jour en caption. Chaque ligne : heure Mono 14 (colonne de 52 pt), point de 10 pt + trait de 2 pt, texte callout, méta « PIÈCE nn · source ».
  - Contradiction : point warning avec halo, méta « ≠ contredit PIÈCE nn ».
  - Les déclarations (alibis) apparaissent comme des événements, avec la méta « Déclaration ».
- **09 · Carnet › Connexions**
  - Test : « Je vois pourquoi ces éléments vont ensemble. »
  - Une ConnectionChain par connexion.
  - Créer une connexion :
    1. [+ Nouvelle connexion] ;
    2. feuille modale « Choisissez le premier élément » (suspects + pièces) ;
    3. « Choisissez le second » ;
    4. « Quel est le lien ? » (5 verbes) ;
    5. la chaîne se crée : le connecteur se dessine de haut en bas en 300 ms, haptique `light`.
  - Pour prolonger une chaîne, « + Ajouter un élément » en bas de la chaîne.
  - La validation des connexions suit la logique existante. L'interface n'indique jamais si une connexion est « juste ».
- **10 · Conclusion**
  - Test : « Je choisis qui est responsable. »
  - Fond bgDeep, sans barre ni chrono (sauf si le temps est écoulé, avec la mention « Temps écoulé » en warning).
  - « DOSSIER #001 · CONCLUSION » data, display « Qui est responsable ? », grille de 2 × 2 ConclusionCards (1 colonne en AX).
  - Bouton de maintien « Maintenir pour accuser {Prénom} », désactivé tant qu'aucune carte n'est sélectionnée (« Choisissez un suspect »).
  - Maintien de 1,6 s : remplissage linéaire, haptique légère au départ puis `rigid` à la fin. Relâché avant la fin : retour en 250 ms.
  - Retour possible vers le Carnet par ‹ tant que le temps n'est pas écoulé.
- **11 · Vérification** (1,8 s, non interruptible)
  - « VÉRIFICATION DU DOSSIER… » en Mono 14.
  - 3 lignes révélées toutes les 0,5 s : Suspect désigné · Pièces décisives n/N · Connexions n.
  - Barre de progression de 2 pt.
  - Puis fondu enchaîné vers 12.
- **12 · Rapport**
  - Test : « J'ai compris pourquoi. »
  - Badge verdict : « ✓ Affaire résolue » (success) ou « ✕ Affaire non résolue » (critical).
  - #001 + title.
  - Carte RESPONSABLE : en cas d'échec, **la vraie réponse**, suivie de « Vous avez accusé : {X} ».
  - Explication en 1 ou 2 phrases, tirée du JSON.
  - Grille de 6 ReportCards : Temps restant, Pièces utilisées, Indices trouvés, Indices manqués (warning), Connexions, Note finale.
  - Lien « Voir les n indices manqués » → liste des pièces non trouvées, avec l'app où elles étaient.
  - Pied fixe : [Classer le dossier]. En cas d'échec : [Rejouer] principal + « Classer » tertiaire.
  - Au classement : retour au Bureau, et la CaseCard passe de « En cours » à « ✓ Résolue ». C'est **le seul tampon** de l'interface : le PNG `stamp_resolu` tombe sur la photo de la carte (échelle 1,3 → 1, 180 ms), haptique `rigid`.
- **13 · États vides / erreur / verrouillé**

| Contexte | Titre | Texte | Action |
|---|---|---|---|
| Pièces | Aucune pièce | Explorez le téléphone pour trouver des éléments utiles. | Ouvrir le téléphone |
| Connexions | Aucune connexion | Reliez les pièces ou les personnes lorsque vous trouvez un lien. | + Nouvelle connexion (si ≥ 2 pièces) |
| Chronologie | Aucune information | Continuez votre enquête. Les pièces datées s'afficheront ici. | — |
| Suspects | Toujours rempli (données de l'affaire) | — | — |
| Erreur de chargement | Le dossier n'a pas pu être chargé | Votre progression est conservée. | Réessayer |
| Affaire verrouillée | {Titre} | Disponible après la conclusion du dossier #00N. | — |
| Mode verrouillé | {Mode} | Disponible après #001. | — |
| App du téléphone vide | Rendu natif du téléphone (« Aucune note ») | Style téléphone, pas de ton BEN | — |

## 7. Onboarding (moins d'une minute)
1. **00** (8 s) : le concept en 5 étapes.
2. Choix de l'enquêteur (doc 06, simplifié : un seul écran de choix + confirmation).
3. **02** de #001, avec la mini-aide en 4 tuiles.
4. **03** : Messages pulse, avec la bulle « Commencez par les messages. ».
5. **04** : la première bulle versable pulse, avec la bulle « Touchez un message pour le verser au dossier. ».
6. **05** : à la 1ʳᵉ pièce, « Retrouvez-la dans le Carnet. » ; à la 3ᵉ, « Vous pouvez maintenant conclure depuis le Carnet. ».
7. Premier accès au Carnet › Connexions : l'état vide explique le geste.

Il n'y a aucun autre texte d'aide. Les bulles BEN ne s'affichent qu'une fois par compte (drapeaux `tip_*`), et un réglage « Réinitialiser les conseils » existe dans Paramètres.

## 8. Micro-animations

| Déclencheur | Animation | Durée / courbe |
|---|---|---|
| Ouverture d'une CaseCard | La carte s'agrandit jusqu'au plein écran (matched geometry), puis le contenu du Dossier apparaît en fondu | 350 ms, spring(0,35, 0,9) |
| Élément touché | Filet ben + EvidenceBadge en fondu avec décalage de 4 pt | 150 ms easeOut |
| Pièce versée | Copie qui vole vers Carnet (échelle 1 → 0,2, opacité → 0) ; compteur qui monte (roulement) | 450 ms spring ; haptique success |
| Connexion créée | Le connecteur se dessine de haut en bas, le verbe apparaît en fondu | 300 ms easeInOut ; haptique light |
| Onglet du Carnet | Le fond actif glisse d'un segment à l'autre, le contenu suit par balayage | 250 ms spring |
| Chrono < 01:00 | Les chiffres passent en warning, sans clignotement | 300 ms |
| Chrono < 00:10 | Chiffres en critical ; haptique light chaque seconde (désactivable) | — |
| Maintien | Remplissage linéaire | 1,6 s (conclusion), 1,2 s (identité) |
| Vérification | Les lignes apparaissent en fondu avec décalage de 6 pt | toutes les 0,5 s |
| Dossier résolu | Tampon RÉSOLU sur la CaseCard | 180 ms easeIn + tassement de 60 ms |
| Changement d'écran | Push iOS standard | Système |

**Réduire les animations** : remplace tous les mouvements par un fondu de 200 ms. Pas de vol de la pièce : seul le compteur change.

## 9. Accessibilité
- **Contrastes** : text et text2 sur bg ≥ 7:1 ; text3 réservé à ≥ 14 pt ; bouton ben avec texte blanc à 4,9:1.
- **Zones tactiles** ≥ 44 × 44 pt, y compris les segments de 40 pt (zone agrandie) et l'EvidenceBadge de 30 pt.
- **Jamais la couleur seule** : tous les statuts combinent un symbole et un libellé. Les contradictions portent « ≠ » et le mot « contredit ».
- **VoiceOver** :
  - EvidenceBadge = action personnalisée « Verser au dossier » sur l'élément lui-même, en plus du bouton ;
  - maintien remplacé par un double-tap suivi de l'alerte « Accuser Emma ? Confirmer / Annuler » ;
  - chrono annoncé chaque minute, puis à 30 s et à 10 s.
- **Alternatives aux gestes** : chaque appui long a un équivalent au tap. Le balayage entre onglets a un équivalent au tap.
- **Dynamic Type** : voir §3.
- **Mode sombre** : le BEN est sombre par nature. Le téléphone reste clair même si le système est en mode sombre : c'est une fiction, et le contraste des deux mondes est voulu.

## 10. Données utilisées par l'interface (existantes, non modifiées)
- **Affaire** : `number`, `title`, `place`, `category`, `difficulty`, `estimatedMinutes`, `context`, `mission`, `persons[]` (nom, âge, relation, alibi, portrait), `initialFacts[]`, `evidence[]` (id, type, source, contenu, horodatage), `solution`, `explanation`.
- **Progression** : `status`, `timeRemaining`, `depositedEvidence[]`, `connections[]` (a, b, verbe), `qualifications` (pièce → suspect, accuse ou disculpe), `hintsUsed`, `score`.
- **Seule donnée nouvelle** : le verbe d'une connexion (`contredit|confirme|même_lieu|même_heure|implique`), à stocker à côté des connexions existantes. Il n'influence pas le score sauf décision contraire de l'équipe.

## 11. Implémentation (ordre recommandé)
1. Tokens (couleurs, typos, rayons) dans `TraceDesign.swift`. Supprimer Geist et Caveat.
2. Composants §5 avec aperçus SwiftUI de chaque état.
3. InvestigationBar + EvidenceBadge + EvidenceSheet : le plus gros gain de compréhension.
4. Carnet : NotebookTab + les 4 onglets + ConnectionChain.
5. Bureau, Dossier, Conclusion, Vérification, Rapport.
6. Écran 00 et bulles d'onboarding.
7. Re-skin des écrans Alibi, Histoire, Profil, Archives et Paramètres avec les mêmes composants.
8. Test : 5 nouveaux joueurs sur #001, sans aide. Critères :
   - premier versement en moins de 90 s ;
   - aucun joueur ne demande « je fais quoi ? » ;
   - chaque joueur trouve le Carnet seul.
