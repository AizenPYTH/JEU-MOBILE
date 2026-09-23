# SCREENSHOT — DESIGN HANDOFF V1.0

Jeu mobile d'enquête iOS (portrait). Document destiné à Claude Code / un développeur : il doit suffire pour implémenter le design sans autre échange.

---

## 0. À propos des fichiers

Les fichiers `.dc.html` de ce dossier sont des **références de design en HTML** (maquettes haute fidélité), pas du code de production. La tâche est de **recréer ces écrans dans l'environnement cible**. Aucun code n'existe encore : stack recommandée **SwiftUI (iOS 17+)**, ou React Native + Reanimated si un portage Android est prévu. Les valeurs ci-dessous sont en points iOS (1 pt = 1 px dans les maquettes, base iPhone 15/16 : 390 × 844).

**Fidélité : haute (hi-fi).** Couleurs, typographies, espacements, rayons et comportements sont définitifs. Les images (portraits, photos, fond d'écran) sont des **placeholders rayés** : à remplacer par des visuels réels (photo réaliste, sombre, étalonnage froid désaturé).

| Fichier | Contenu |
|---|---|
| `Screenshot — 1 Jeu.dc.html` | 01–07 : onboarding, accueil, affaires, intro, dossiers, profil, paramètres |
| `Screenshot — 2 Téléphone.dc.html` | 08–21 : accueil téléphone et toutes les apps |
| `Screenshot — 3 Enquête.dc.html` | 22–39 : notifications, chrono, carnet, indices, fin, résultats, score, états |
| `Screenshot — Design System.dc.html` | tokens, typo, composants, motion, son/haptique |
| `StatusBar.dc.html`, `CarnetBar.dc.html` | composants partagés (barre d'état + chrono, capsule carnet) |

Chaque écran porte un numéro (01…39) ; ce document y renvoie par ce numéro.

---

## A. Vision

Le joueur reçoit le téléphone d'Alex Moreau, disparu après une soirée. Il a **8 minutes** pour explorer le téléphone (messages, appels, photos, localisation…), **épingler** les éléments qui comptent dans un **carnet**, puis **accuser** un des quatre suspects. Toute l'enquête se fait à travers l'interface du téléphone, un OS fictif crédible.

Boucle de jeu : **Explorer → Remarquer → Épingler → Relier → Accuser.**
Émotion cible : « Je dois trouver » → « Attends… » → « Ça contredit son message » → « Il me reste 43 s » → « C'est lui. »

Principes :
1. **Le téléphone est le monde.** Seuls deux éléments de jeu se superposent à l'OS : le chrono (à la place de l'heure) et la capsule Carnet/Indice (au pouce).
2. **Le jeu ne dit jamais « indice ».** Aucun élément n'est mis en valeur tant que le joueur ne l'a pas épinglé.
3. **Lire doit être facile.** Le contenu est dense ; l'interface est donc très calme.
4. **La pression reste élégante.** Le chrono change de couleur et de rythme, il ne clignote jamais.

## B. Direction artistique

« OS fictif conçu pour une enquête ». Premium, sombre, adulte, minimaliste.
- **L'obscurité comme matière** : 6 noirs étagés, aucun dégradé décoratif (seuls les scrims en ont un).
- **Le blanc comme action** : le bouton primaire est blanc cassé plein (#ECEAE6), texte noir. Les bulles envoyées par Alex sont aussi blanches, les reçues gris foncé. Pas de bulles bleues.
- **L'ambre comme signal** : épinglé, non lu, progression, chrono bas. Rouge seulement pour le critique ou le destructif. Bleu « trace » seulement pour la géolocalisation.
- **Trois voix typographiques** : Geist (interface), JetBrains Mono (données : heures, durées, chrono, numéros), Instrument Serif italique (narration : intro, indices, citations, verdict).
- **Icônes d'apps « tableau périodique »** : tuiles monochromes avec 2 lettres (Ms, Ap, Ph…). C'est la signature de l'OS fictif : aucune ressemblance avec iOS, compréhensible tout de suite grâce au libellé.
- **Logo** : « SCREENSHOT » en Geist 600, interlettrage +34 %, encadré par 4 repères de capture ; celui en bas à droite est ambre.

## C. Palette

| Token | Hex | Usage |
|---|---|---|
| `ink.0` | #050607 | Écrans narratifs (intro, carnet, accusation, résultats) |
| `bg.base` | #08090B | Fond des apps du téléphone |
| `bg.surface` | #0F1114 | Cartes, sheets |
| `bg.raised` | #16191D | Champs, tuiles, cellules groupées |
| `bg.bubbleIn` | #1C1F24 | Bulles reçues, menus, toasts |
| `bg.elevated` | #1E2227 | Avatars, chips internes |
| `bg.selected` | #2A2E34 | Segment actif, état pressé |
| `text.primary` | #ECEAE6 | Texte, bouton primaire, bulles envoyées |
| `text.secondary` | #A3A29D | Aperçus, métadonnées (8.1:1 sur bg.base) |
| `text.tertiary` | #6B6B67 | Horodatages, captions (≥ 11 pt, jamais pour du texte critique) |
| `text.onLight` | #0B0C0E | Texte sur fonds clairs |
| `signal` | #E3B158 | Épinglé, non lu, progression, chrono ≤ 01:00 |
| `signal.tint` | rgba(227,177,88,.14) / contour .35–.55 | Fonds et contours ambre |
| `alert` | #E5534B (texte : #FF6B61) | Chrono ≤ 00:10, appel manqué, erreur, destructif |
| `alert.tint` | rgba(229,83,75,.14–.20) / contour .50 | |
| `trace` | #7AB4DB | Localisation, adresses cliquables |
| `clear` | #63C58E | Résolu (écrans de fin seulement) |
| `line.1/2/3` | rgba(236,234,230,.06 / .10 / .20) | Séparateurs / contours / focus |
| `scrim` | rgba(0,0,0,.50–.60) | Sous les sheets, menus, notification urgente |

Règles : les accents ont une chroma et une luminance équivalentes (oklch ≈ 0.78 / 0.12), seule la teinte change. Un seul accent par composant. **Un état n'est jamais exprimé par la couleur seule** : il y a toujours aussi un symbole ou un libellé (◆ ✓ ✕ ↙ ↗ ○).

## D. Typographie

Polices (Google Fonts, licence OFL, à embarquer dans le bundle) : **Geist** 300/400/500/600, **JetBrains Mono** 400/500/600/700, **Instrument Serif** Regular + Italic.

| Style | Police | Taille/interligne | Poids | Interlettrage | Usage |
|---|---|---|---|---|---|
| display | Geist | 40/1.02 | 600 | −3.5 % | Titre de l'intro |
| titleLarge | Geist | 34/1.1 | 600 | −3 % | Titre d'app/écran (large title) |
| title2 | Geist | 28–32/1.08 | 600 | −3 % | Titres de verdict |
| title3 | Geist | 20–24/1.2 | 600 | −2 % | Titres de carte, sheets |
| headline | Geist | 16–17/1.3 | 600 | 0 | Noms, lignes importantes |
| body | Geist | 15–16/1.4 | 400 | 0 | Bulles, texte |
| callout | Geist | 14/1.4 | 400 | 0 | Aperçus, descriptions |
| caption | Geist | 12–13/1.4 | 400 | 0 | Sous-titres |
| tabLabel | Geist | 11 | 400 | 0 | Libellés d'icônes |
| overline | Mono | 11 | 500–600 | +14 % CAPS | « AFFAIRE 001 », en-têtes de section |
| data | Mono | 12–13 | 400–600 | 0, tnum | Heures, durées |
| timer | Mono | 14 | 600 (700 en critique) | −2 %, tnum | Chrono de la barre d'état |
| timerHero | Mono | 34 (intro) / 88 (temps écoulé) / 108 (score) | 600 | −3 à −6 % | |
| narrative | Instrument Serif Italic | 19–25/1.25–1.35 | 400 | 0 | Intro, indices, citations |
| notification | Geist | 14 (urgent 15–17) | titre 600 / corps 400–500 | | |

Dynamic Type : tous les styles UI suivent la taille système (`relativeTo:`). Le chrono, les tuiles d'app et les capsules restent fixes. Minimum : 11 pt en mono, 12 pt en Geist.

## E. Design system : composants

Voir `Screenshot — Design System.dc.html`.

### DESIGN TOKENS
```text
colors      : voir §C
typography  : voir §D
spacing     : 2, 4, 8, 12, 16, 20, 24, 32, 48, 64
              marge écran : 16 (apps compactes) / 20 (listes) / 24 (écrans de jeu)
radius      : xs 6 (badge) · sm 12 (champ, segment) · md 14 (bouton) · icon 17 (tuile 62)
              lg 18–20 (carte, bulle 19) · sheet 28 (haut) · device 52 · pill = h/2
              bulle : 19, coin côté émetteur 6 (groupé/dernier)
shadows     : e0 inset 0 0 0 1px line.1
              e1 0 12 32 rgba(0,0,0,.5) + inset line.2      (capsule, toast)
              e2 0 24 60 rgba(0,0,0,.7)                      (banner, menu)
              ring 0 0 0 2px signal                          (épinglé)
              ring 0 0 0 2px text.primary                    (sélectionné)
              vignette critique : inset 0 0 90px rgba(229,83,75,.20)
blur        : barres 20 · banners/dock 24 · scrim menu 6 · fond urgent 1.5
opacity     : disabled .45 · non sélectionné .60 · scrim .50/.60 · chrono critique 1 ↔ .72
animation   : fast 150 · base 240–300 · slow 360–420 · hero 700–900 ms
              standard (.32,.72,0,1) · emphasized (.2,.8,.2,1) · dramatic (.65,0,.35,1)
              spring: app 280/30 · sheet 260/32 · notif 300/28 (stiffness/damping, masse 1)
```

### COMPONENT INVENTORY
| Composant | Variantes / états | Spéc clé |
|---|---|---|
| `StatusBar` | mode clock / timer · niveau normal / low / critical · piste de progression | h 54, padding 8/26/0/30 ; pastille chrono h 26 r 13, point 6 pt ; piste 2 pt à bottom −4 |
| `CarnetBar` | count · indice disponible/non | capsule h 46 r 23, fond rgba(28,31,36,.88) + blur 20, e1 ; bas à 8 + home indicator ; dégradé scrim 96 pt au-dessus |
| `HomeIndicator` | — | 134 × 5 r 3, bottom 8 |
| `AppTile` | défaut · badge · verrouillée (.45) · Agenda dynamique | 62 × 62 r 17, bg.raised + line.1.5 ; libellé 11 pt ; badge 20 pt signal |
| `Dock` | — | 4 tuiles, r 30, blur 24, marge 14 |
| `NavBar` | retour + titre large · compact (conversation) · action à droite | ligne retour h 44 ; large title 34 |
| `SearchField` | vide · focus (contour line.3 + curseur signal) · rempli + clear | h 40 r 12 |
| `SegmentedControl` | 2–3 segments | h 38, pad 3, segment actif bg.selected r 9 |
| `Chip` / `FilterChip` | actif (blanc plein) · inactif | h 32 r 16 |
| `Toggle` | on (piste blanche, pouce noir) · off (piste #2A2E34, pouce #6B6B67) | 48 × 28 |
| `Slider` | — | piste 4, pouce 20 blanc |
| `ButtonPrimary` | défaut · pressé (scale .98, #C9C7C2) · disabled · loading (3 points) | h 56/52/44, r 14, 16/600 |
| `ButtonSecondary` | — | fond line.1 + contour line.2 |
| `ButtonTertiary` | — | texte secondaire |
| `ButtonDestructive` | contour · plein | alert |
| `HoldToConfirm` | repos · remplissage · validé · annulé | 900 ms, remplissage gauche→droite, retour 200 ms linéaire |
| `ConversationRow` | lu · non lu (point signal + 600 + aperçu blanc) · groupe · service | h 78, avatar 48 |
| `MessageBubble` | reçu · envoyé · groupé (coins) · supprimé (pointillés, italique) · épinglé (contour signal + point) · lien · pièce jointe | max 76 %, pad 9/13 |
| `SystemMessage` | pastille centrée | 12 pt, fond line.1 |
| `DateSeparator` | — | mono 11, +6 % |
| `TimelineScrubber` | années/mois + bulle de date | rail 22 pt à droite |
| `CallRow` | entrant ↙ · sortant ↗ · manqué ↙ rouge · épinglé | h 62 |
| `PhotoGrid` | 3/5/7 colonnes · vignette épinglée · vidéo | gap 2 |
| `PhotoViewer` | zoom 1–5× + minimap · infos (sheet) | — |
| `MapView` | points numérotés · point actif (trace + halo) · tracé en pointillés · zone | — |
| `TimelineRow` | passé · actif · interrompu (pointillés) | h 46 |
| `CalendarWeekStrip` / `EventCard` / `ReminderRow` | événement · rendez-vous · rappel (pointillés) | — |
| `NoteCard` | épinglée · ancienne · incomplète · mystérieuse (serif 22) | — |
| `HistoryRow` | recherche (guillemets) · page (titre + domaine) | — |
| `ContactRow` / `ContactHub` | compteurs inter-apps | tuiles 68 h |
| `TrashItem` | note · photo · message · fichier | contour pointillé line.3 |
| `NotificationBanner` | normal · important · urgent (inversé, contexte de réponse, actions) | r 22, e2, blur 24 |
| `Toast` | ajout carnet · erreur système | h 40 r 20 |
| `ContextMenu` | — | 250 large, lignes 48 |
| `Sheet` | crans 120 / 420 / plein · poignée 36 × 5 | r 28 |
| `SuspectCard` | défaut · sélectionné (ring blanc + ✓) · atténué (.60) · compteur de preuves | grille 2 col, gap 10 |
| `EvidenceRow` | heure mono + libellé + app source | h 48 |
| `HintCard` | révélé (serif) · disponible (coût) · verrouillé (heure) | — |
| `CaseCard` | disponible · en cours · terminée · parfaite · verrouillée | r 20, pad 18 |
| `DifficultyMeter` | 1–5 carrés 8 pt + « n/5 » | — |
| `StatCard` / `ScoreRow` | — | — |
| `RevealTimeline` | trouvé (point plein) · manqué (cercle vide) | ligne verticale 1 pt |
| `Skeleton` | — | balayage 1,2 s |
| `EmptyState` | carré pointillé 56 + titre + phrase utile | — |
| `PinPad` | — | touches 72, r 36 |

## F. Navigation : arbre des écrans

```
Launch
└─ Onboarding (1ʳᵉ fois : 3 étapes) [01]
Home [02]
├─ Continuer → Investigation (reprise)
├─ Affaires [03] → Case Intro [04] → Investigation
├─ Dossiers [05] → Case Archive (reconstitution)
├─ Profil [06]
└─ Paramètres [07]

Investigation (session chronométrée)
├─ Phone Home [08]
│  ├─ Messages [09] → Conversation [10] ; Recherche [11]
│  ├─ Appels [12] → Détail d'appel ; Appel entrant [24]
│  ├─ Photos [13] → Photo plein écran [14] → Infos (sheet) → Localisation
│  ├─ Localisation [15]
│  ├─ Agenda [16] → Détail d'événement
│  ├─ Notes [17] → Note
│  ├─ Navigateur [18] → Page visitée (figée)
│  ├─ Contacts [19] → Fiche contact [20] → (Messages | Appels | Photos | Agenda filtrés)
│  ├─ Mail (verrouillée [39] → liste → mail)
│  ├─ Fichiers (vide [37])
│  └─ Corbeille [21]
├─ Overlays : Notification [22/23] · Menu épingler [27] · Toast
├─ Sheet Carnet : Suspects [28] → Fiche suspect [29] · Preuves · Chronologie
├─ Sheet Indices [30]
└─ Tap chrono → « Accuser maintenant ? »
Temps écoulé [31] (ou accusation anticipée) → Accusation [32]
→ Résultat positif [33] → Score [35] → (Rejouer | Affaire suivante)
→ Résultat négatif [34] → (Rejouer | Révéler la solution → [33] en mode révélé, score non classé)
```

Règles de navigation :
- Chaque app a sa **pile propre**. Revenir à l'accueil (swipe depuis le bas, ou tap sur le home indicator) conserve la pile ; rouvrir l'app restaure la position de scroll.
- **Retour** : bouton « ‹ Parent » en haut à gauche, et swipe interactif depuis le bord gauche.
- **Liens inter-apps** (fiche contact, lieu d'une photo, résultat de recherche) : ils poussent l'écran cible *dans l'app cible*. Un bouton pastille « ‹ Photos » apparaît alors en haut à gauche pendant 6 s pour revenir à l'app d'origine.
- Le Carnet et les Indices sont des sheets **au-dessus** de tout. Le chrono continue de tourner.
- Pause (app en arrière-plan) : le chrono se met en pause et un écran flou affiche « Enquête en pause ».

## G. Spécification des écrans

Structure commune d'un écran d'app : `StatusBar(timer)` → `NavBar` (ligne retour 44 + large title 34, marge 20) → contenu scrollable (inset bas 110 pour la capsule) → `CarnetBar`.

**01 Onboarding.** Montré au premier lancement seulement. 3 étapes : Explorer (tap sur des apps) · Épingler (maintenir un élément, montrée ici) · Accuser. Un indicateur à 3 traits (18 × 3) en haut. Chaque démo est réellement jouable : l'étape se valide quand le geste est fait. Passer = aller à l'Accueil. CTA en bas (24 de marge, 42 au-dessus du home indicator).

**02 Accueil.** Logo en haut à gauche, avatar joueur (36) en haut à droite. Carte « Reprendre » en bas : visuel 150, overline, titre 24, méta mono (temps restant, preuves), barre de progression 3 pt signal, CTA primaire 52. Menu en 4 lignes de 56 (Affaires, Dossiers, Profil, Paramètres) avec valeur mono à droite. Sans partie en cours, la carte devient « Affaire suivante / Commencer ».

**03 Affaires.** Segments Toutes / À jouer / Terminées. `CaseCard` avec les 5 états (voir inventaire). Carte verrouillée : titre masqué par ▒, condition affichée, tap = secousse + « Résolvez 002 pour débloquer ». Tap sur une carte disponible = Intro.

**04 Intro.** Fond ink.0. Fermer (×) en haut à gauche. Overline signal « AFFAIRE 001 », titre display sur 2 lignes. 3 phrases en serif 25 qui apparaissent en fondu une par une (400 ms chacune, 600 ms d'écart ; un tap affiche tout). Pile d'avatars des 4 suspects, puis ligne « Téléphone d'Alex Moreau, remis le 20 sept., 08:12 » + « 08:00 » en mono 34. CTA « Commencer l'enquête », actif tout de suite. Transition : Déverrouillage (§I).

**05 Dossiers.** Carte de l'affaire la mieux réussie + liste des tentatives (statut ✓/✕ + score). Ouvrir un dossier affiche la reconstitution ([33] en lecture seule), disponible seulement si l'affaire est résolue ou si la solution a été révélée.

**06 Profil.** Rang (titre 34) + barre de points. Grille de 4 `StatCard`. Distinctions : obtenue (contour signal ◆), obtenue sans rareté (◇), cachée (pointillés ?).

**07 Paramètres.** Groupes : Son & haptique (curseur Ambiance, toggles Effets et Vibrations) · Enquête (Notifications en direct, Mode sans chrono) · Accessibilité (Taille du texte → système, Réduire les animations, Contraste élevé). Un score obtenu en Mode sans chrono est « non classé ».

**08 Accueil du téléphone.** Fond d'écran (photo sombre) + date 15 + heure fictive 64/300 (heure de l'histoire, figée à 08:12). Grille 4 colonnes, marge 22, 22 d'espace vertical, 11 tuiles sur la page 1. Page 2 : apps de décor. Dock 4 apps (Ct, Ap, Ms, Ph). Badges : Messages 3, Appels 2. Réglages verrouillée.

**09 Messages.** Titre large, champ de recherche (un tap ouvre [11]). Lignes de 78 : avatar 48, nom (600 si non lu), heure mono à droite (signal si non lu), aperçu sur 1 ligne. Point non lu 7 pt à −13 pt du bord. Swipe gauche sur une ligne = Épingler la conversation. Tri : dernier message.

**10 Conversation.** En-tête compact translucide (blur 20) : retour, avatar 36, nom + méta (« Ami · 1 214 messages depuis 2021 »), bouton recherche dans la conversation. **Pas de champ de saisie.** Les messages sont groupés si moins de 5 min les séparent (un seul horodatage centré). Séparateur de date à chaque changement de jour. Types : texte, lien (carte 38 + domaine), photo (vignette 200 max, tap = [14]), supprimé, système. **Historique long** : liste virtualisée, qui s'ouvre au dernier message ; rail années/mois à droite (drag = scrub avec bulle de date + haptique selection à chaque mois) ; pastille « Aller à une date » (ouvre un sélecteur jour/mois) ; plus de 3 semaines chargées à la demande sans spinner visible (préchargement). Appui long sur une bulle = [27].

**11 Recherche.** Recherche globale sur tout le téléphone (messages, agenda, notes, navigateur, contacts). Filtres par chips avec compteurs. Résultats groupés par app, puis triés par date ascendante. Ligne : nom + date mono + extrait sur 2 lignes, terme surligné (fond signal 22 %). Reconnaît les dates en français (« 19 sept », « samedi », « 19/09 »), les noms et les lieux. Tap = ouvre la source avec l'élément centré et surligné 2 s. Vide : « Aucun résultat pour “x”. Essayez un nom, un lieu ou une date. » Debounce 120 ms.

**12 Appels.** Segments Tous / Manqués (n). Groupes par jour. Ligne de 62 : flèche de direction, nom (rouge si manqué), type + durée mono, heure mono, bouton « i ». Détail : numéro, durée, antenne approximative, liens vers contact et messages.

**13 Photos.** Groupes par jour avec résumé de lieu. Grille 3 colonnes, gap 2 ; pincer = 3/5/7 colonnes. Rail de mois (pastille « SEPT ▾ »). Vignette épinglée : contour signal 2 pt + point. Onglet Albums : Récents, Captures, Vidéos, Récemment supprimés (= Corbeille/photos).

**14 Photo plein écran.** Fond noir. En-tête date + heure mono. Zoom par pincement ou double tap (1–5×), indicateur « 2,4× » et minimap. Swipe haut = sheet d'infos : nom de fichier, format, résolution, taille, « non modifiée », carte miniature + lieu (tap = [15] au bon horaire). Swipe bas = fermer vers la vignette. Barre du bas : bouton Épingler (état épinglé en signal) + position « 4 / 6 ».

**15 Localisation.** Carte fictive vectorielle (routes, rivière, zones avec libellés mono 9 +10 %). Tracé en pointillés entre des points numérotés dans l'ordre chronologique ; point actif en trace + halo 6 pt. Chips de personne en haut : « Alex · ce téléphone » et « Lucas · partagé » (partage arrêté à 21:50, affiché comme message dans la liste). Sheet à 3 crans : jour (‹ ›), curseur temporel (21:30–23:30), liste chronologique. **Carte, curseur et liste sont synchronisés** : toucher l'un met les deux autres à jour. Un trou dans l'historique = ligne en pointillés « Historique interrompu », sans explication.

**16 Agenda.** Bandeau semaine (38 pt par jour, sélection blanche pleine, point = activité). Vue jour : heures mono à gauche, `EventCard` (titre, lieu, heure, chips de personnes cliquables), rendez-vous en contour plus marqué avec overline, rappel en pointillés + case + état « non fait ». Bouton « Liste » = vue liste sur 30 jours.

**17 Notes.** Cartes : épinglée (fond raised + overline), mystérieuse (texte en serif 22), code (mono), notes normales (titre + aperçu + date). Tap = note plein écran, lecture seule, 17/1.5.

**18 Navigateur.** Favoris en grille de 4 (tuiles 52). Historique groupé par jour : heure mono + recherche entre guillemets ou titre de page + domaine. Barre de recherche **en bas** (h 48, e1) qui filtre l'historique. Les pages visitées sont des pages statiques internes (HTML/Markdown embarqué), jamais le web réel.

**19 Contacts.** Section « Personnes de l'affaire » en tête (les 4 suspects), puis ordre alphabétique avec index de lettres à droite (scrub + haptique).

**20 Fiche contact.** Portrait 96, nom 26, relation. 4 compteurs cliquables (Messages, Appels, Photos, Agenda), chacun ouvre l'app filtrée sur la personne. Champs : mobile (mono), domicile (en trace, ouvre la localisation), véhicule, anniversaire.

**21 Corbeille.** Chips par type. Tous les éléments ont un contour pointillé et affichent leur type (overline) + la date de suppression (mono, blanche si elle compte dans l'histoire). Lecture directe au tap.

**22 Notifications.** Banner r 22, marge 10, top 62 (sous la Dynamic Island). Normal : 4 s puis se masque tout seul. Important : 6 s, contour line.3, haptique légère. Urgent : inversé (fond #ECEAE6, texte noir), reste affiché jusqu'à une action, affiche le contexte et deux actions (Ouvrir, ◆ Épingler). File d'attente : 1 banner visible, 3 en attente, priorité urgent > important > normal. Tap = ouvre la source ; swipe haut = ignorer (reste dans le centre de notifications, qu'on tire depuis le haut).

**23 Événement urgent (Emma).** Scrim 50 % + flou du fond 1.5, banner urgent avec « EN RÉPONSE À · ENVOYÉ DEPUIS CE TÉLÉPHONE · SAM. 23:48 ». Le chrono continue. Déclencheur : première ouverture de Messages après 45 s de jeu, ou à 07:12 au plus tard.

**24 Appel entrant.** Plein écran. On ne peut pas décrocher. Au bout de 6 s, ou si le joueur choisit « Écouter », la transcription de la messagerie s'affiche puis est ajoutée au journal d'appels. « Ignorer » = appel manqué ajouté au journal.

**25–26 Chrono.** Voir §I et le composant StatusBar. Tap sur le chrono = sheet « Accuser maintenant ? » avec le bonus de temps affiché.

**27 Épingler.** Appui long 400 ms (haptique medium au seuil) → scrim .60 + flou 6, élément soulevé (scale 1.03, e2) + méta sous l'élément + menu (Épingler au carnet / Lier à un suspect ▸ / Voir le contexte). Après validation : toast « ◆ Ajouté au carnet · n » et badge de la capsule +1. Élément épinglé : contour signal + point 10 pt. Rejouer le geste = « Retirer du carnet ». Tout ce qui s'affiche dans une app peut être épinglé (message, appel, photo, point de localisation, événement, note, historique, élément de corbeille, transcription).

**28 Carnet.** Sheet plein écran sur ink.0. Onglets Suspects / Preuves (n) / Chronologie. Suspects : grille 2×2 (portrait 120, nom, relation, « n preuves liées », en signal si n > 0). Preuves : `EvidenceRow` triées par heure, avec swipe = lier/délier à un suspect. Chronologie : preuves sur un axe vertical de 21:00 à 09:00. CTA contour « Accuser maintenant ».

**29 Fiche suspect.** Portrait 84 × 104, nom 28, relation, âge, adresse. « Ce qu'il/elle affirme » = déclaration connue (pré-remplie par les données de l'affaire, en serif). « Preuves liées » = celles liées par le joueur, triées par heure ; tap = aller à la source.

**30 Indices.** Sheet avec 3 paliers : Piste (gratuit), Lieu (−8 %), Preuve (−15 %, débloqué à 02:00). Le coût est affiché avant le tap. Un indice révélé s'affiche en serif 22.

**31 Temps écoulé.** Le contenu s'éteint en fondu (240 ms), le chrono va au centre en mono 88 rouge, « TEMPS ÉCOULÉ » +32 %, « Le téléphone se verrouille. » Barre de progression de 1,8 s, puis passage automatique à [32].

**32 Accusation.** Titre, rappel de l'objectif (« Celui ou celle qui ment sur son alibi. »). Grille 2×2 de `SuspectCard` avec compteur de preuves. Sélection = ring blanc 2 + ✓, les autres cartes à .60. CTA `HoldToConfirm` (désactivé tant que personne n'est sélectionné : « Sélectionnez un suspect »). Tap sur une carte déjà sélectionnée = ouvre la fiche [29].

**33 Résultat positif.** Badge « ✓ AFFAIRE RÉSOLUE », titre, phrase en serif, puis `RevealTimeline` de 5 à 8 étapes qui se révèlent toutes les 700 ms (point plein = trouvé, cercle vide = manqué) ; un tap accélère. CTA « Voir le score ».

**34 Résultat négatif.** Badge « ✕ AFFAIRE NON RÉSOLUE ». Titre qui disculpe le suspect choisi, avec la preuve de son alibi (carte). Carte « Le piège » (pourquoi c'était trompeur). « Ce qui vous a échappé » = nombre d'éléments manqués par app, sans dire lesquels. CTA « Rejouer l'affaire » ; action secondaire « Révéler la solution » (confirmation : le score ne sera pas classé).

**35 Score.** Pourcentage en mono 108 (le chiffre défile de 0 à la valeur en 900 ms), puis 5 lignes en cascade (60 ms) : Suspect, Temps restant, Éléments trouvés, Indices, Précision du carnet. Gain de points pour le rang. CTA Rejouer (secondaire) + Affaire suivante (primaire).
Formule : `score = 60·[bon suspect] + 25·(trouvés/total) + 10·(restant/480) + 5·(pertinentes/épinglées) − coûtIndices` (1er 0, 2e 8, 3e 15), arrondi à l'inférieur, borné 0–100. Mauvais suspect : les 60 points ne sont pas acquis et le résultat est affiché « non résolu ». 100 = Parfaite.

**36–39 États transverses.** Voir §K.

## H. iPhone / responsive

- Portrait uniquement. Base 390 × 844. S'adapte de 375 × 667 (SE) à 440 × 956 (Pro Max) : largeurs fluides, grille d'accueil à 4 colonnes fixes avec gouttières élastiques, grilles de suspects en 2 colonnes.
- Safe areas : haut = barre d'état (54, Dynamic Island 124 × 36 à top 11) ; bas = home indicator + capsule : réserver **110 pt** en bas du contenu scrollable.
- iPhone SE (sans Dynamic Island) : barre d'état de 20 pt, le chrono passe en pastille flottante à top 6, gauche 12.
- Zones tactiles ≥ 44 × 44. Actions principales dans le tiers bas (CTA, capsule, barre du navigateur, sheets).
- Gestes : swipe bord gauche = retour · swipe depuis le bas = accueil du téléphone · pull-down = recherche (listes) · appui long = épingler · pincement = zoom/colonnes · swipe haut sur une photo = infos.
- Les gestes système iOS ne sont pas bloqués. Le swipe du bas passe par un home indicator « deferred » (`defersSystemGestures(on: .bottom)`) : un premier swipe dans le jeu, un second vers iOS.

## I. Animations

| Animation | Déclencheur | Durée | Easing | Comportement |
|---|---|---|---|---|
| Ouverture d'app | tap sur une tuile | 320 ms | spring 280/30 | zoom depuis le cadre de la tuile (scale .86→1, rayon 17→52), fond noir 0→1 |
| Fermeture d'app | swipe haut / home indicator | 280 ms | interactif puis (.32,.72,0,1) | l'app suit le doigt, retourne vers sa tuile |
| Push / Pop | navigation | 300 ms | (.32,.72,0,1) | +100 % X ; le parent va à −30 % X et s'assombrit de 20 % ; pop interactif |
| Sheet | ouverture Carnet/Indices/Infos | 360 ms | spring 260/32 | Y depuis le bas, scrim 0→.5, crans aimantés |
| Modal | Accusation, Résultat | 420 ms | (.2,.8,.2,1) | fondu + Y 24→0 |
| Notification | événement scripté | 380 / 240 ms | spring 300/28 | −120 % Y + blur 24→0 ; sortie vers le haut |
| Urgent | événement urgent | 300 ms | (.2,.8,.2,1) | scrim + flou du fond en même temps |
| Message reçu | message en direct | 1,2 s de « … » puis 260 ms | (.2,.8,.2,1) | opacity 0→1, Y 8→0, scale .96→1 depuis le coin de l'émetteur |
| Recherche | focus sur le champ | 240 ms | (.32,.72,0,1) | le titre se replie, le champ monte ; résultats en cascade 30 ms |
| Épingler | seuil d'appui long | 200 ms | (.2,.8,.2,1) | élément scale 1.03 + ring ; le compteur de la capsule défile verticalement |
| Chrono normal | chaque seconde | — | — | aucun mouvement (chiffres tabulaires) |
| Chrono bas | ≤ 01:00 | boucle 2 s | sine | halo 3 pt signal .25 ↔ .10 |
| Chrono critique | ≤ 00:10 | boucle 1 s | sine | opacité 1 ↔ .72 + vignette .20 ↔ .12 |
| Temps écoulé | 00:00 | 240 + 500 ms | (.65,0,.35,1) | contenu éteint → chrono au centre (scale ×6) |
| Hold-to-confirm | appui sur le CTA | 900 ms / retour 200 ms | linéaire | remplissage gauche→droite |
| Déverrouillage | CTA de l'intro | 700 ms | (.65,0,.35,1) | 4 repères qui se referment sur les bords, flash blanc 6 %, accueil du téléphone |
| Révélation | résultat | 700 ms par ligne | (.2,.8,.2,1) | la ligne verticale se trace, les éléments passent de .0 à 1 |
| Score | apparition | 900 ms + 60 ms/ligne | (.2,.8,.2,1) | le chiffre défile |
| Erreur de code | code faux | 300 ms | — | secousse X ±6 × 3 |
| Skeleton | chargement > 150 ms | 1,2 s en boucle | linéaire | balayage lumineux |

**Réduire les animations** (système ou réglage du jeu) : tous les déplacements deviennent des fondus de 150 ms, sans boucle de respiration ni vignette animée. Le chrono garde ses couleurs.

**Son & haptique** : table complète dans le Design System §10. Correspondances iOS : `UIImpactFeedbackGenerator(.light/.medium/.heavy/.soft/.rigid)`, `UINotificationFeedbackGenerator(.success/.warning/.error)`, `UISelectionFeedbackGenerator`, Core Haptics pour le continu du hold-to-confirm. Deux bus audio : ambiance (musique, ducking à 40 % pendant les urgences) et effets.

## J. Données

Chaque affaire est un fichier JSON statique (`cases/001.json`). L'état de la partie est séparé.

```ts
Case { id, number:"001", title, synopsis:string[3], durationSec:480, difficulty:1..5,
  phoneOwner: PersonId, storyNow: ISODate /* 2026-09-20T08:12 */,
  suspects: Suspect[], persons: Person[], evidence: EvidenceDef[],
  apps: { messages, calls, photos, locations, calendar, notes, browser, contacts, mail, files, trash },
  liveEvents: LiveEvent[], hints: Hint[3], solution: Solution, locks?: Lock[] }
Person { id, firstName, lastName, relation, avatar, phone, address?, vehicle?, birthday? }
Suspect { personId, age, statement:{ text, sourceRef } }
Conversation { id, participants:PersonId[], isGroup, pinnedByOwner?, messages: Message[] }
Message { id, from:PersonId, at:ISODate, type:"text"|"link"|"photo"|"deleted"|"system",
  text?, link?:{domain,title}, photoId?, deletedAt? }
Call { id, personId, direction:"in"|"out"|"missed", at, durationSec, cell?:string, voicemail?:string }
Photo { id, file:"IMG_2318", at, place?:{ label, lat, lng, precisionM }, asset, meta:{format,mp,sizeMB,edited}, deletedAt? }
LocationTrack { personId, shared:boolean, stoppedAt?, points: { at, placeLabel, x, y }[], gapFrom? }
CalendarItem { id, kind:"event"|"meeting"|"reminder", at, end?, title, place?, people?:PersonId[], note?, done? }
Note { id, title?, body, at, style:"normal"|"pinned"|"mysterious"|"code", deletedAt? }
BrowserEntry { id, at, kind:"search"|"page", query?, title?, domain?, pageContent? }
TrashItem { ref:{app, id}, deletedAt }
EvidenceDef { id, ref:{app, id}, weight:1, relevantTo:PersonId|null /* red herring = null */ }
LiveEvent { id, trigger:{ type:"time"|"appOpen"|"evidence", value }, action:
  { type:"notification"|"incomingCall"|"newMessage"|"deleteMessage", level:"normal"|"important"|"urgent", payload } }
Hint { tier:1|2|3, text, cost:0|8|15, unlockAtSec? }
Solution { culpritId, liesAbout:"alibi", reveal: { at, text, evidenceId }[], alibis: Record<PersonId,{ text, evidenceId }>, traps: Record<PersonId, string> }

GameState { caseId, status:"locked"|"available"|"inProgress"|"completed"|"perfect",
  remainingSec, pinned:{ evidenceRef, linkedTo?:PersonId, at }[], hintsUsed:number[],
  firedEvents:string[], navStacks:Record<App, Route[]>, scroll:Record<string, number>,
  attempts:{ at, accused, score, resolved }[] }
```
Chaque interface lit uniquement sa section `apps.*`. La recherche globale passe par un index construit au chargement de l'affaire (texte normalisé sans accents + dates parsées).

## K. États

| État | Rendu | Où |
|---|---|---|
| Normal | maquettes | partout |
| Loading | skeleton à la géométrie exacte, affiché seulement si > 150 ms ; au lancement d'une affaire : « Déchiffrement… » en mono + barre fine (600 ms max) [36] | apps, lancement |
| Vide | carré pointillé 56 + titre 17/600 + phrase utile (jamais une impasse) [37] | Fichiers, Carnet (« Maintenez un élément pour l'épingler »), Recherche, Dossiers |
| Erreur diégétique | dans la fiction, style OS, overline rouge « FICHIER ENDOMMAGÉ », métadonnées lisibles [38] | vidéos, fichiers |
| Erreur système | toast e1 avec contour alert + action « Réessayer » ; **le chrono se met en pause** pendant l'affichage [38] | sauvegarde, chargement |
| Verrouillé | app : PinPad (2 essais puis 30 s de blocage, qui consomment le chrono) [39] ; affaire : titre masqué + condition ; tuile : opacité .45 | Mail, Réglages, affaires |
| Sélectionné | ring blanc 2 + ✓, les autres à .60 | suspects, segments, chips |
| Notification | badges signal, point non lu, banners | apps |
| Épinglé | contour signal + point 10 + libellé « ◆ Épinglé » | tout contenu |
| Terminé / Parfait | badge ✓ n % (contour vert) / ◆ PARFAITE (signal plein) | affaires, dossiers |
| Désactivé | fond line.1, texte tertiaire, aucune interaction | boutons |

## L. UX : parcours

1. **Premier lancement** : Onboarding 3 étapes (60 s max) → Affaire 000 « Premier accès » (tutoriel de 3 min, 2 suspects, 4 preuves, sans pénalité) → Accueil.
2. **Partie type** : Accueil → Affaires → Intro (≤ 10 s) → Téléphone. Pendant l'exploration, le chrono tourne et des événements scriptés arrivent (en moyenne un toutes les 90 s, jamais deux à moins de 20 s d'écart). Le joueur épingle et lie des éléments, ouvre le Carnet pour relier les suspects, peut acheter un indice. Il accuse à 00:00, ou plus tôt via le Carnet ou le chrono → Résultat → Score → Rejouer / Affaire suivante.
3. **Échec** : explication → Rejouer (nouvelle partie, même contenu, les événements sont rejoués) ou Révéler la solution.
4. **Reprise** : quitter l'app met la partie en pause ; « Continuer » sur l'Accueil restaure tout (piles, scroll, carnet, chrono).

Frustration et rythme : l'intro ne bloque jamais ; les indices sont progressifs ; l'accusation anticipée est récompensée ; un échec explique toujours l'erreur ; le Mode sans chrono existe pour l'accessibilité. Rétention : rang, distinctions liées au style de jeu, objectif 100 % visible par les cercles vides de la révélation, rejouabilité grâce à l'ordre des événements en direct (variantes de timing ± 15 s).

## M. Affaire #001 : « Le dernier message »

**Contexte.** Téléphone d'Alex Moreau (29 ans), remis le dimanche 20 sept. 2026 à 08:12. Soirée chez Inès (Rue Vauban) le samedi 19 sept. Suspects : **Sarah Lemaire** (compagne), **Karim Benali** (collègue), **Lucas Ferrand** (ami), **Emma Moreau** (sœur). Coupable : **Lucas**, qui ment sur son alibi.

**Vérité.** Le 17 sept., Alex prête 4 000 € à Lucas. Le samedi, il lui fixe un rendez-vous au Parking Central à 22:00 pour parler du remboursement. Lucas écrit « Bien rentré » à 21:52 alors qu'il est en route pour le parking, et coupe le partage de sa position à 21:50. Il appelle Alex à 22:19 depuis la zone industrielle. Le téléphone d'Alex finit chez Lucas (14 rue des Tanneurs) à 22:41. À 23:02, depuis le téléphone d'Alex, quelqu'un cherche comment effacer l'historique de localisation, supprime une note et une photo (23:05–23:06), puis écrit à Emma à 23:48 pour savoir ce qu'elle sait.

**10 preuves (total affiché au score)**
| # | App | Élément | Écran |
|---|---|---|---|
| E1 | Messages | Alex → Lucas « Après la soirée. Parking Central, 22h. » (19/09 18:0x) | 10 |
| E2 | Messages | Lucas « Bien rentré. Je dors, on se capte demain. » 21:52 (**mensonge**) | 10 |
| E3 | Agenda | 22:00 Rendez-vous · Parking Central · « avec L. » | 16 |
| E4 | Photos | IMG_2318 · 22:08 · Parking Central −2 · Golf grise, plaque partielle | 14 |
| E5 | Appels | Lucas entrant 22:19 · 02:31 · antenne Zone industrielle Nord | 12 |
| E6 | Localisation | 22:41 · 14 rue des Tanneurs (+ Lucas a coupé son partage à 21:50) | 15 |
| E7 | Contacts | Fiche Lucas : domicile 14 rue des Tanneurs · véhicule Golf grise | 20 |
| E8 | Navigateur | 23:02 « comment supprimer historique localisation » / 23:04 | 18 |
| E9 | Messages (Emma) | 23:48 « T'as dit à quelqu'un où j'étais ce soir ? » + réponse en direct | 23, 26 |
| E10 | Corbeille | Note supprimée 23:05 « L. me rembourse samedi. 4 000 €… » | 21 |

Soutiens (non comptés) : virement de la banque Alterne « 4 000 € — L. FERRAND » (liste Messages), message supprimé de Lucas « Viens seul. » (Corbeille), photo IMG_2319 supprimée à 23:06.

**Fausses pistes.** Karim : dette de 300 €, 2 appels manqués à 23:40, note « Ne jamais faire confiance à K. » (datée du 2 mars 2024). Alibi : sa garde de nuit (message vocal à 05:30, visible au [24]). Sarah : dispute (« Je veux plus en parler, Alex. »), appel de 20:12 ; alibi : elle est restée chez Inès (photos de groupe à 22:30 dans l'album d'Inès partagé). Emma : elle savait pour le rendez-vous (« Je vois Lucas au parking », 21:58) ; alibi : sa réponse « Pourquoi tu me demandes ça ? » montre qu'elle ne sait rien de ce qui s'est passé ensuite.

**Événements en direct (chrono)**
| Chrono | Événement | Niveau |
|---|---|---|
| 07:40 | Maman « Tu passes dimanche ? » | normal |
| 07:12 ou 1ʳᵉ ouverture de Messages après 45 s | Emma « Pourquoi tu me demandes ça ? » (réponse au message de 23:48) | **urgent** |
| 06:00 | Rappel « Appeler Emma » (en retard) | important |
| 05:30 | Appel entrant de Karim → message vocal (son alibi) | important |
| 03:00 | Message « Lucas a supprimé un message » (le fil se met à jour en direct) | important |
| 01:30 | Lucas « T'es où ? Réponds. » | urgent |

**Indices** : 1 « Comparez les déplacements de Lucas avec ses messages. » (gratuit) · 2 « L'agenda d'Alex dit où il devait être à 22:00. » (−8) · 3 « Regardez où était ce téléphone à 22:41, puis à qui appartient cette adresse. » (−15, débloqué à 02:00).

**Révélation (écran 33)** : 21:52 « Bien rentré » → 22:04 Alex au parking → 22:08 la Golf de Lucas sur la photo → 22:19 appel de Lucas depuis la zone industrielle → 22:41 le téléphone chez Lucas → 23:02 tentative d'effacer la trace → 23:48 message à Emma.

## N. Instructions d'implémentation (Claude Code)

1. **Projet** : SwiftUI, iOS 17+, portrait verrouillé. Modules : `DesignSystem` (tokens + composants), `CaseEngine` (chargement JSON, index de recherche, chrono, événements, score), `PhoneOS` (apps), `Meta` (accueil, affaires, profil…).
2. **Tokens d'abord** : `Color.ss.*`, `Font.ss.*` (avec `relativeTo:`), `Spacing`, `Radius`, `Elevation` (ViewModifiers), `Motion` (`Animation.ss.push`, etc.), à partir des tables §C, D, E et I. Aucune valeur en dur dans les vues.
3. **Chrono** : source unique `@Observable TimerStore` (tick de 1 s basé sur `ContinuousClock`, en pause sur `scenePhase != .active` et pendant une erreur système). Il expose `level` (normal > 60, low ≤ 60, critical ≤ 10) et `progress`. La `StatusBar` le lit. Les seuils déclenchent haptique et son une seule fois.
4. **OS fictif** : `PhoneShell` (ZStack : accueil, app active avec sa `NavigationStack` par app, overlays, sheets, `CarnetBar`). Ouverture d'app par `matchedGeometryEffect` depuis la tuile. Swipe du bas géré par le shell.
5. **Épingler** : `ViewModifier .pinnable(ref:)` applicable à toute cellule (appui long 0,4 s → menu). L'état est dans `GameState.pinned` et le ring s'affiche à partir de cet état.
6. **Listes longues** : `List`/`LazyVStack` avec `ScrollViewReader` ; rail de scrub dans un overlay, qui mappe la position verticale à un index de date ; « Aller à une date » fait un `scrollTo(messageId)`.
7. **Carte** : dessin vectoriel `Canvas` à partir de coordonnées normalisées (`x`, `y` entre 0 et 1) du JSON. Pas de MapKit (lieux fictifs).
8. **Événements en direct** : `LiveEventScheduler` évalue les déclencheurs à chaque tick et à chaque changement de route. File de notifications avec priorité. Un événement ne se déclenche qu'une fois (`firedEvents`).
9. **Score et résultat** : fonction pure `score(state, case)` conforme au §G-35. Le résultat négatif lit `solution.alibis[accused]` et `solution.traps[accused]`.
10. **Accessibilité** : VoiceOver (chaque bulle est lue « Lucas, 21 h 52 : Bien rentré… »), les symboles d'état sont vocalisés (« épinglé »), le chrono est annoncé seulement aux seuils (60 s, 30 s, 10 s), Réduire les animations est respecté, Contraste élevé = text.secondary #C4C3BE, text.tertiary #8E8E89, lignes ×1,5.
11. **Assets** : polices dans le bundle ; portraits (4) et photos (≈ 30 pour 001) = visuels réalistes à produire. Garder le ratio des placeholders. Glyphes UI : Lucide ou SF Symbols avec un trait équivalent à 1.5.
12. **Fidélité** : comparer chaque écran à sa maquette numérotée. Les notes grises sous chaque maquette décrivent son comportement et font partie de la spécification.

---

### SCREEN INVENTORY
01 Onboarding · 02 Accueil · 03 Affaires · 04 Intro · 05 Dossiers · 06 Profil · 07 Paramètres · 08 Accueil du téléphone · 09 Messages · 10 Conversation · 11 Recherche · 12 Appels · 13 Photos · 14 Photo plein écran · 15 Localisation · 16 Agenda · 17 Notes · 18 Navigateur · 19 Contacts · 20 Fiche contact · 21 Corbeille · 22 Notifications (niveaux) · 23 Événement urgent · 24 Appel entrant · 25 Chrono (paliers) · 26 Dernières secondes · 27 Épingler · 28 Carnet/Suspects · 29 Fiche suspect · 30 Indices · 31 Temps écoulé · 32 Accusation · 33 Résultat positif · 34 Résultat négatif · 35 Score · 36 Chargement · 37 Vide · 38 Erreur · 39 Verrouillé.
Non maquettés (ils réutilisent les composants existants) : Mail (liste/lecture = motif Messages + Notes), Fichiers (liste = motif Corbeille sans pointillés), Détail d'appel, Détail d'événement, Note plein écran, Page web figée, Carnet › Preuves et Chronologie (`EvidenceRow` + `RevealTimeline`), Centre de notifications (pile de banners), Pause.

### USER FLOW
```
[Lancement] → (1ʳᵉ fois) Onboarding → Affaire 000 → Accueil
Accueil → Affaires → Intro → [Téléphone ⟲ Apps ⟲ Notifications ⟲ Carnet ⟲ Indices]
       → (00:00 | Accuser maintenant) → Accusation → hold 900 ms
       → Résolue → Révélation → Score → Rejouer | Affaire suivante
       → Non résolue → Explication → Rejouer | Révéler → Révélation (non classé)
Accueil → Continuer → reprise exacte de la partie
Accueil → Dossiers → Reconstitution · Profil · Paramètres
```
