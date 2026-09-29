# Cinématiques d'avant (retirées du jeu) — ouverture du jeu et ouvertures des affaires #001 à #005

> **ARCHIVÉ / LEGACY.** Toutes les cinématiques vidéo sont **définitivement supprimées** du jeu : aucun écran ne
> lit ni n'attend de vidéo. Chaque affaire est présentée par son dossier (`docs/CASE_PRESENTATION.md`) puis une
> courte ouverture (sachet de scellé → téléphone). Le champ `introScene` n'existe plus. Ce document ne sert qu'à un
> travail hors du jeu (bande-annonce, réseaux). Prompts des scènes HISTOIRE : `docs/archive/PROMPTS_CINEMATIQUES_HISTOIRE.md`.


Intro du jeu (recrutement) + ouverture de chaque affaire #001 → #005, plan par plan.
Prompts en anglais (Veo / GPT Image les suivent mieux), explications en français.

## Règles communes (à respecter pour chaque plan)

- **Format** : 9:16 vertical, 1080p, 4 à 8 s par plan, audio activé (ambiance seulement). Un plan = une génération ;
  le montage enchaîne.
- **Deux façons de produire un plan** :
  - **T2V** (texte → vidéo, Veo 3.1) : on colle le prompt vidéo directement.
  - **I2V** (image → vidéo) : on génère d'abord l'image avec le prompt IMAGE (GPT Image, 1080 × 1920), puis on
    l'anime dans Veo / Kling / Runway avec le prompt MOUVEMENT. C'est la méthode à privilégier quand un personnage
    récurrent apparaît (Lacaze) : on donne son portrait validé en image de référence.
- **Toujours « a scene from a fictional French … film »** en tête de prompt : Veo refuse souvent les faux reportages
  qui nomment des personnes réelles ou plausibles.
- **Aucun nom prononcé dans la vidéo, aucun texte dans l'image** : finir chaque prompt par
  `No subtitles, no on-screen text, no captions, no logos.` Les textes (dates, lieux, « Cdt. B. LACAZE » sur la porte)
  sont ajoutés au montage ou par le jeu.
- **Voix** : jamais générées par la vidéo. Toutes les répliques sont faites dans **ElevenLabs** (fiche de casting en
  fin de document), puis posées au montage.
- **Visages** : le joueur n'est **jamais** vu de face (dos, épaule, mains, POV) : un seul tournage vaut pour les 4
  apparences (Élise A/B, Vincent A/B). Manteau sombre neutre (marine / anthracite) dans tous les plans.
  Les suspects ne sont jamais montrés dans les ouvertures d'affaire (silhouettes, reflets, de dos).
- **Téléphones** : écran flou ou vu de biais, jamais d'interface lisible : la vraie interface est celle du jeu, qui
  reprend la main sur le dernier plan (téléphone posé → déverrouillage).

**Bloc commun IMAGE** (à coller avant chaque prompt image de l'intro) :
```
Cinematic still from a French crime drama, realistic, 9:16 vertical, shot on ARRI Alexa, 35mm lens, natural film grain, muted colours, overcast November light through rain-streaked windows, renovated 1970s administrative building, no text, no logos, no readable signs.
```

---

# PARTIE 1 — Cinématique du début du jeu (≈ 1:35)

| Temps | Séquence | Qui la fait |
|---|---|---|
| 0:00–0:04 | Logo NOREL GAMES, puis « CONCLUDE » tapé à la machine + « ENQUÊTES » | Jeu (pas de prompt) |
| 0:04–0:12 | Chargement « Accès aux archives » | Jeu (écran de chargement) |
| 0:12–0:40 | **Recrutement : 10 plans** (ci-dessous) | I2V + jeu |
| 0:40–0:50 | Choix du personnage (Élise / Vincent, A / B) | Jeu (interactif) |
| 0:50–1:05 | Fiche d'agent remplie, tampons, affectation | Jeu |
| 1:05–1:20 | Remise du dossier #001 (plan 11 ci-dessous = seul plan vidéo) | Jeu + I2V |
| 1:20–1:35 | Ouverture de l'affaire #001 (Partie 2) | Vidéo |

Décor commun du recrutement : bâtiment administratif des années 70 rénové, couloirs à néons, bureaux vitrés, piles de
dossiers, pluie derrière les fenêtres, fin d'après-midi de novembre. Néons froids (4 000 K) dans les couloirs, lampe de
bureau chaude (2 700 K) chez Lacaze.

### PLAN 1 — Le couloir (4 s · I2V)
Derrière le joueur, épaule droite en amorce, il avance ; bureaux vitrés, agents flous au loin, chariot de dossiers.
Sons : pas sur le lino, néon qui grésille, téléphone qui sonne au loin.
```
IMAGE: Long institutional corridor with glass-walled offices, flickering fluorescent tubes, a trolley loaded with cardboard files, blurred officers far away, a man in a dark navy coat seen from behind on the right edge of the frame walking away from camera. [+ bloc commun]
```
```
MOTION: A scene from a fictional French crime drama. Slow steadicam follow behind the man in the dark coat as he walks down the corridor; the fluorescent tube above flickers once; far-away officers cross the corridor out of focus. Keep his face hidden, only his back and right shoulder visible. Audio: footsteps on linoleum, buzzing neon, a phone ringing in a distant office, ventilation hum. No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 2 — La porte (2,5 s · I2V)
Face à une porte en verre dépoli ; la main du joueur entre dans le champ et frappe deux coups. « Cdt. B. LACAZE » est
ajouté au montage.
```
IMAGE: Close shot of a frosted-glass office door with a brass handle in the fluorescent corridor, a blank rectangle where a name plate would be, a man's hand in a dark coat sleeve raised near the glass, about to knock. [+ bloc commun]
```
```
MOTION: A scene from a fictional French crime drama. The hand knocks twice on the frosted glass, then lowers; behind the glass, a warm lamp glow and a vague silhouette at a desk. Static camera. Audio: two knocks on glass, a muffled male voice from inside (no clear words), corridor hum. No subtitles, no on-screen text, no captions, no logos.
```
Voix (ElevenLabs, étouffée) : LACAZE « Entrez. »

### PLAN 3 — Le bureau (3 s · I2V, référence portrait `npc_lacaze`)
Plan large depuis la porte, légère poussée : Lacaze derrière un bureau encombré, lampe verte, stores, pluie ; il lit un
dossier sans lever les yeux.
```
IMAGE: Cluttered office seen from the doorway, green banker's lamp, venetian blinds, rain streaming on the window, piles of files, a lean man in his late fifties with short grey hair, a grey moustache and half-moon reading glasses, white shirt with rolled-up sleeves and a loosened tie, reading a grey file behind a wooden desk. [+ bloc commun]
```
```
MOTION: A scene from a fictional French crime drama. Slow push-in from the doorway towards the desk; the officer keeps reading and turns one page without looking up; rain runs down the window behind him. Audio: rain on glass, a chair being pulled out, a clock ticking. No subtitles, no on-screen text, no captions, no logos.
```
Voix : LACAZE « Asseyez-vous. »

### PLAN 4 — Le dossier du joueur (3 s · I2V)
Gros plan en plongée : les mains de Lacaze tournent une chemise grise « DOSSIER D'AGENT » ; la photo agrafée est floue
(neutre pour les 4 apparences).
```
IMAGE: Top-down close-up of a wooden desk: an older man's hands with rolled-up shirt sleeves holding a grey personnel file, a small ID photo clipped on it completely out of focus, typed pages, a fountain pen, warm lamp light. [+ bloc commun]
```
```
MOTION: A scene from a fictional French crime drama. The hands slowly turn the pages of the grey file and set the fountain pen down. Static top-down camera, shallow depth of field. Audio: paper pages, the pen placed on wood, rain. No subtitles, no on-screen text, no captions, no logos.
```
Voix : LACAZE « Douze ans de terrain. Brigade financière, puis la PJ. »

### PLAN 5 — La conversation (4 s · I2V, référence `npc_lacaze`)
Contrechamp : épaule du joueur en amorce (floue, sans visage), Lacaze en plan poitrine enlève ses lunettes et le
regarde.
```
IMAGE: Over-the-shoulder shot from behind a man in a dark coat (out of focus, face never visible) facing an older police commander with a grey moustache sitting behind a desk under a green lamp, venetian blinds and rain behind him. [+ bloc commun]
```
```
MOTION: A scene from a fictional French crime drama. The older officer slowly takes off his reading glasses, folds them and looks straight at the man in the foreground; the foreground shoulder stays out of focus. Audio: clock ticking, rain, a low music drone rising. No subtitles, no on-screen text, no captions, no logos.
```
Voix : LACAZE « Ici, on ne court pas après les gens. On lit ce qu'ils laissent derrière eux. »

### PLAN 6 — Les pages (2,5 s · I2V)
Insert sur les mains : il tourne 2 ou 3 pages (rapports, tampons).
```
IMAGE: Close-up of hands flipping through typed police reports with faded ink stamps and paper clips on a wooden desk, warm lamp light, shallow depth of field. [+ bloc commun]
```
```
MOTION: A scene from a fictional French crime drama. The hands flip three pages one after the other, stamps and paragraphs blur past. Static close-up. Audio: three page turns, rain. No subtitles, no on-screen text, no captions, no logos.
```
Voix : LACAZE « Messages, photos, appels. Un téléphone ment moins que son propriétaire. »

### PLAN 7 — La chemise (3 s · I2V)
Plan moyen de côté : il sort une chemise kraft d'un tiroir et la pose sur le bureau.
```
IMAGE: Side view of an older officer at a wooden desk pulling a worn brown kraft folder out of a desk drawer, green lamp, venetian blinds, rain. [+ bloc commun]
```
```
MOTION: A scene from a fictional French crime drama. The officer pulls the kraft folder out of the drawer, closes the drawer and lays the folder flat on the desk with a soft thud. Static medium side shot. Audio: drawer sliding, the folder landing on wood, a light low impact in the music. No subtitles, no on-screen text, no captions, no logos.
```
Voix : LACAZE « Votre première affectation. »

### PLAN 8 — Gros plan sur le dossier (2 s · JEU, pas de prompt)
Chemise kraft « N° 001 », tampon CONFIDENTIEL, élastique : rendu par le jeu pour raccorder exactement avec l'app.

### PLAN 9 — Il fait glisser la chemise (2,5 s · I2V)
POV du joueur assis, en légère plongée : la main de Lacaze pousse la chemise vers la caméra.
```
IMAGE: Point of view of a seated person looking down at a wooden desk; an older man's hand rests on a brown kraft folder with a red rubber stamp, green lamp light, rain-streaked window in the background. [+ bloc commun]
```
```
MOTION: A scene from a fictional French crime drama. The older man's hand slides the kraft folder across the desk towards the camera until it fills the lower frame. First-person camera, very slight handheld breathing. Audio: cardboard sliding on wood, rain, the music drone returns. No subtitles, no on-screen text, no captions, no logos.
```
Voix : LACAZE « Marseille. Un homme de vingt-six ans. Son téléphone a été retrouvé ce matin. »

### PLAN 10 — Vers la fiche (1,5 s · JEU)
La chemise remplit l'écran, fondu vers la fiche d'agent vierge (choix du personnage). Voix off : LACAZE « Complétez votre fiche. »

### PLAN 11 — Le téléphone sort du scellé (3 s · I2V) — remise du dossier #001
Après l'ouverture de l'affaire #001 : mains gantées qui ouvrent le sachet scellé et posent le téléphone sur le bois
(même cadrage que le plan « téléphone posé » du jeu, qui prend le relais).
```
IMAGE: Top-down close-up on a dark wooden desk: hands in thin blue nitrile gloves opening a transparent sealed evidence bag with a red tamper-evident strip, a black smartphone inside, warm desk lamp light, no readable text on the bag. [+ bloc commun]
```
```
MOTION: A scene from a fictional French crime drama. The gloved hands tear open the evidence bag, slide the smartphone out and lay it face up in the centre of the frame, then withdraw. Static top-down camera. Audio: plastic tearing, the phone set down on wood, silence. No readable text on the phone or bag, no subtitles, no on-screen text, no captions, no logos.
```
Voix : LACAZE (off) « Il a laissé son téléphone. À vous de le faire parler. »

---

# PARTIE 2 — Ouvertures des affaires

## AFFAIRE #001 — « LE DERNIER MESSAGE »

**Identité** : portuaire, humide, bleu nuit et orange sodium. Marseille, dimanche 13 septembre, 09 h 52, après une
nuit de pluie. **Idée** : un reportage télé devant le parking du Quai 9, où le téléphone d'Alex a été retrouvé ; puis le
téléphone, mis sous scellé, se met à vibrer : « Maman — Je suis très inquiète ».
Dans le jeu : titre (date, lieu) → reportage → noir + vibration → téléphone posé « SCELLÉ N°3 » → déverrouillage.

⚠ Le plan d'origine était « de nuit » : le jeu affiche 09 h 52. Les prompts ci-dessous sont donc un **matin gris
après la pluie** (flaques, lumières de police encore allumées), ce qui raccorde avec le texte à l'écran.

### PLAN 1 — Le Quai 9 (8 s · T2V ou I2V)
Parking portuaire ouvert, rubalise, gyrophares bleus dans les flaques, grues et conteneurs ; une journaliste de dos
avec un micro, un caméraman flou. Aucun visage, aucun nom prononcé : la voix du reportage vient d'ElevenLabs.
```
A scene from a fictional French crime drama. Grey Sunday morning after a night of rain at an open-air car park on the Marseille docks: police tape across the entrance, blue flashing lights of two police cars reflected in wide puddles, cranes and stacked shipping containers behind, seagulls. A TV reporter is seen from behind, holding a microphone, facing a camera operator who is out of focus; a few onlookers behind the tape, blurred. Camera: handheld TV news camera look, slow drift to the right, 9:16 vertical, photorealistic. Audio: city ambience, distant sirens, seagulls, crowd murmur, wind on the microphone (no speech). No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 2 — Le lieu de la découverte (6 s · I2V)
Gros plan au ras du sol : l'emplacement où le téléphone a été retrouvé, marqueur jaune de police numéroté, flaque.
```
IMAGE: Low close-up of wet asphalt in a port car park after rain, a yellow evidence marker tent (number not readable) next to a puddle reflecting blue police lights, a painted parking line, containers blurred in the background, 9:16, photorealistic.
```
```
MOTION: A scene from a fictional French crime drama. Very slow push-in towards the evidence marker; raindrops still fall into the puddle, the blue light pulses on the water. Audio: dripping water, distant sirens, seagulls. No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 3 — Le téléphone sous scellé (6 s · I2V)
Le téléphone d'Alex dans son sachet transparent sur un bureau, il vibre, l'écran s'allume (notification floue). Le jeu
enchaîne ensuite sur son propre plan « téléphone posé » et le déverrouillage.
```
IMAGE: Top-down close-up of a black smartphone inside a transparent sealed evidence bag with a red seal strip on a dark wooden desk, dim office light, a few raindrops still on the plastic, no readable text, 9:16, photorealistic.
```
```
MOTION: A scene from a fictional French crime drama. The phone inside the evidence bag vibrates against the desk and its screen lights up with a blurred notification, then goes dark again. Static top-down camera. Audio: phone buzzing on wood through plastic, office silence, rain outside. No readable text on the screen, no subtitles, no on-screen text, no captions, no logos.
```
Voix du reportage (ElevenLabs, journaliste, ~8 s) :
« Nous sommes devant le parking du Quai 9, où le téléphone d'Alex Moreau a été retrouvé ce matin. Le jeune homme n'a
plus donné signe de vie depuis samedi soir. Les enquêteurs espèrent que son téléphone parlera. »

---

## AFFAIRE #002 — « PREMIER MÉTRO »

**Identité** : froide, nocturne, urbaine. Bleu acier, néons, carrelage humide. Lyon, samedi 17 octobre, 5 h du matin.
**Idée** : le premier métro arrive dans une station vide. Personne ne descend, personne ne monte. Sur un banc, un
téléphone oublié se met à vibrer.

INTRO_SCENE (dans le jeu) : `scene` metro (travelling, carillon, annonce) → `scene` metro (arrivée du train) →
`phoneOnTable` sur un banc métallique (message puis appel d'Anaïs) → noir + vibration → déverrouillage.

### PLAN 1 — Le quai vide (8 s)
- **Visuel** : quai de métro souterrain vide, voûte carrelée crème, néons froids, panneau d'information allumé, bande
  jaune de sécurité, un banc métallique au fond. Poussière dans la lumière.
- **Caméra** : travelling lent le long du quai, à hauteur d'épaule, très légère instabilité.
- **Lumière** : néons blancs-verts, reflets sur le sol encore humide du nettoyage.
- **Personnages** : un agent d'entretien très loin, flou, qui pousse un chariot.
- **Audio** : souffle de ventilation, grondement lointain du tunnel, carillon de trois notes, voix d'annonce en français.
- **Dialogue (annonce)** : « Le premier métro en direction de Gare de Vaise entre en station. »
- **Transition** : le souffle du tunnel monte.
```
A scene from a fictional French thriller film. 5 a.m., an empty underground metro platform in a French city: curved cream-tiled vault, cold white-green fluorescent tubes, a lit information screen, a yellow safety line along the platform edge, one steel bench at the far end. The floor is still wet from cleaning; dust floats in the light. Far away, a blurred cleaning worker pushes a cart. Camera: slow dolly along the platform at shoulder height, very slight handheld sway, shallow depth of field, photorealistic, fine grain. Audio: ventilation hiss, a low rumble from the tunnel, a three-note station chime, then a calm female French announcement voice over the public address system saying: "Le premier métro en direction de Gare de Vaise entre en station." No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 2 — Le premier métro (8 s)
- **Visuel** : les phares sortent du tunnel, le souffle soulève un gobelet en carton, la rame entre en station, les
  portes s'ouvrent : wagons éclairés et vides. Personne ne descend.
- **Caméra** : fixe, grand angle, légère vibration au passage du train.
- **Audio** : grondement qui monte, sifflement des freins, signal sonore des portes.
- **Transition** : les portes se referment, le train repart.
```
Same fictional film, same empty metro platform at dawn. Headlights grow in the dark tunnel mouth, a gust of air pushes a paper cup along the platform, then a modern metro train rushes in and stops; its brightly lit carriages are completely empty. The doors open. Nobody gets off, nobody gets on. Camera: static wide shot at platform level, the ground trembling slightly as the train arrives, photorealistic, cold fluorescent light. Audio: rising rumble, brake squeal, the door warning beeps, the hum of the stopped train. No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 3 — Le banc (8 s)
- **Visuel** : le train est parti. Plan rapproché sur le banc métallique perforé : un téléphone posé écran vers le haut.
  Il vibre sur le métal, l'écran s'allume (notification floue), puis sonne (appel entrant, écran flou).
- **Caméra** : plan fixe en plongée légère, puis très lent zoom avant.
- **Audio** : vibration contre le métal, sonnerie étouffée, écho de la station vide.
- **Transition** : la sonnerie s'arrête ; coupe au noir ; une dernière vibration dans le noir (le jeu enchaîne sur le
  téléphone pris en main).
```
Same fictional film. The train has left; the platform is silent. Close shot of a perforated steel metro bench under cold fluorescent light: a smartphone lies on it, screen up. It vibrates against the metal and its screen lights up with a blurred notification, then it starts ringing with a blurred incoming call screen. Nobody is around to answer. Camera: static, slightly high angle, then a very slow push-in on the phone. Photorealistic, shallow depth of field, reflections of the tubes on the phone's glass. Audio: the phone buzzing on metal, a muffled ringtone echoing in the empty station, distant ventilation. At the end, hard cut to black while one last vibration is heard. No readable text on the phone screen, no subtitles, no on-screen text, no logos.
```

---

## AFFAIRE #003 — « APRÈS LA FÊTE »

**Identité** : lumineuse, domestique, psychologique. Lumière de matin, lin blanc, bois clair, bassin d'Arcachon.
Cap Ferret, dimanche 23 août, 7 h 10.
**Idée** : le lendemain d'un anniversaire. Tout est encore là (verres, ballons), le soleil entre, la mer est calme.
Là-haut, un téléphone sonne sur une table de chevet. Personne ne répond.

INTRO_SCENE : `scene` villa_morning (dérive, lumière du matin, goélands) → `scene` terrace (panoramique sur le bassin)
→ `phoneOnTable` sur une table de chevet en bois (appel puis message de Grégoire) → déverrouillage.

### PLAN 1 — Le salon, le lendemain (8 s)
- **Visuel** : grand salon d'une villa de bord de mer : voilages blancs, rayons de soleil, verres à moitié vides,
  bouteilles, ballons dorés qui se dégonflent, un chiffre « 30 » en ballon à moitié affaissé, un plaid sur le canapé.
- **Caméra** : dérive lente à travers la pièce, comme un regard qui cherche.
- **Lumière** : soleil rasant du matin, poussière en suspension.
- **Audio** : silence de maison, horloge, vagues douces au loin, goélands.
- **Transition** : la caméra atteint la baie vitrée.
```
A scene from a fictional French drama film. 7 a.m., the morning after a 30th birthday party in a seaside villa: a large bright living room with sheer white curtains, sunbeams full of floating dust, half-empty glasses and bottles on a low wooden table, gold balloons slowly deflating, a large "3" and "0" balloon sagging in a corner, a blanket left on the sofa. Nobody is there. Camera: slow drifting glide through the room, like someone looking for something, photorealistic, soft morning light, natural lens flare. Audio: the quiet of a sleeping house, a clock ticking, gentle waves outside, distant seagulls. No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 2 — La terrasse et le bassin (8 s)
- **Visuel** : depuis la terrasse en bois, le jardin descend vers le bassin ; pins maritimes, lumière dorée, un trépied
  photo oublié sur la terrasse, quatre verres sur la table. En bas du jardin, le début d'un escalier de pierre
  (on ne voit pas ce qu'il y a au pied).
- **Caméra** : panoramique lent de gauche à droite.
- **Audio** : vent dans les pins, vagues, goélands.
- **Transition** : une vibration, très faible, venue de la maison.
```
Same fictional film, same villa, 7 a.m. From a wooden deck terrace, a garden slopes down to a calm bay; maritime pines, golden morning light, the water almost still. A photographer's tripod is left standing on the terrace next to a table with four empty glasses. At the bottom of the garden, the first steps of an old stone staircase leading down to the beach disappear behind the pines — we cannot see the bottom. Camera: slow pan from left to right, photorealistic, gentle breeze in the pines. Audio: wind in the pines, soft waves, seagulls, and very faintly, from inside the house, a phone vibrating. No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 3 — La table de chevet (8 s)
- **Visuel** : chambre du haut, volets entrouverts. Sur une table de chevet en bois clair, un téléphone vibre et sonne
  (appel entrant flou). Dans le lit, une silhouette sous les draps blancs, de dos, ne bouge pas. L'autre côté du lit
  est défait. L'appel s'arrête ; un message s'allume.
- **Caméra** : plan fixe à hauteur de la table, mise au point sur le téléphone, le lit flou derrière.
- **Audio** : sonnerie, vibration contre le bois, respiration lente, goéland au loin.
- **Transition** : coupe au noir sur l'écran allumé.
```
Same fictional film. An upstairs bedroom of the villa, shutters half open, stripes of morning sun. On a light-wood bedside table, a smartphone vibrates and rings with a blurred incoming-call screen. In the bed behind it, out of focus, a figure sleeps under white sheets, back to the camera, and does not move; the other side of the bed is unmade and empty. The call stops, then the screen lights up again with a blurred message notification. Camera: static at the height of the bedside table, focus on the phone, the bed soft in the background, photorealistic. Audio: ringtone, the phone buzzing on wood, slow breathing, a distant seagull. Hard cut to black on the lit screen. No readable text on the phone, no subtitles, no on-screen text, no logos.
```

---

## AFFAIRE #004 — « 90 SECONDES »

**Identité** : spectaculaire, publique, tension. Noir et or, verrière, lustres, smokings. Paris, jeudi 12 novembre,
22 h 13.
**Idée** : un gala sous une verrière. Une vitrine éclairée, un collier. L'animatrice annonce la pièce maîtresse… et
tout s'éteint. Quatre-vingt-dix secondes de noir. La lumière revient : la vitrine est vide.

INTRO_SCENE : `scene` gala (poussée, voix de l'animatrice) → `scene` vitrine → `scene` gala (coupure : noir, lumières
de secours) → `scene` vitrine_empty → `phoneOnTable` sur une table haute en marbre (messages, appel du collectionneur)
→ déverrouillage.

### PLAN 1 — Le gala (8 s)
- **Visuel** : grande salle sous verrière, lustres, colonnes, invités en tenue de soirée (flous, de dos), quatuor à
  cordes, scène à gauche avec une animatrice au micro dans une poursuite, vitrine éclairée à droite.
- **Caméra** : poussée lente à travers la foule vers la vitrine.
- **Audio** : brouhaha élégant, quatuor, verres qui tintent. Voix de l'animatrice (off, amplifiée).
- **Dialogue** : « Mesdames et messieurs… dans quelques instants, le collier Aurore. »
- **Transition** : la caméra atteint la vitrine.
```
A scene from a fictional French heist thriller film. Night, a grand exhibition hall under a glass roof in Paris: crystal chandeliers, stone columns, elegant guests in black tie seen from behind and out of focus, a string quartet playing, champagne glasses. On a small stage to the left, a woman host in a black dress speaks into a microphone in a spotlight, seen from afar. To the right, a single glass display case glows under a pin spot. Camera: slow push through the crowd towards the glowing display case, photorealistic, warm golden light, shallow depth of field. Audio: elegant crowd murmur, the string quartet, glasses clinking, and the host's amplified voice in French: "Mesdames et messieurs… dans quelques instants, le collier Aurore." No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 2 — La vitrine (8 s)
- **Visuel** : gros plan sur la vitrine : un collier de perles sur un buste de velours sombre, cône de lumière, reflets
  des invités dans le verre.
- **Caméra** : poussée très lente, légère parallaxe.
- **Audio** : la musique et la foule s'éloignent, un léger bourdonnement électrique.
- **Transition** : le bourdonnement grésille.
```
Same fictional film. Close-up of the glass display case: an antique pearl necklace with a platinum clasp rests on a dark velvet bust under a narrow cone of light; the silhouettes of guests are reflected in the glass. Camera: very slow push-in with a slight parallax, photorealistic, luxurious, the pearls glinting. Audio: the music and the crowd fade into the background, a faint electrical hum from the lighting grows, then crackles. No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 3 — Le noir (8 s)
- **Visuel** : les lumières vacillent puis s'éteignent d'un coup : noir complet. Cris étouffés, verres qui tombent.
  Après deux secondes, seuls les blocs de secours rouges et verts ; quelques lampes de téléphone s'allument dans la
  foule.
- **Caméra** : fixe, plan large sur la salle.
- **Audio** : « clac » électrique, bourdonnement qui meurt, souffle de la foule, un verre qui se brise, murmures.
- **Transition** : le noir dure.
```
Same fictional film, the same grand hall. Suddenly the lights flicker twice and go out completely: total darkness. Stifled gasps, a glass shatters, the crowd murmurs in panic. After two seconds, only small red and green emergency exit lights glow, and a few phone flashlights switch on here and there in the crowd, moving nervously. Nothing can be seen clearly. Camera: static wide shot of the dark hall, photorealistic low-light, heavy darkness. Audio: an electrical clunk, the hum dying, gasps, broken glass, anxious whispers. No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 4 — La vitrine vide (8 s)
- **Visuel** : la lumière revient progressivement, une poursuite se pose sur la vitrine : le buste de velours est vide,
  la porte de la vitrine entrouverte, sans aucune trace d'effraction. Les invités se retournent.
- **Caméra** : poussée lente vers la vitrine vide.
- **Audio** : la foule qui comprend, un murmure qui monte, un cri « Le collier ! » (sans nom de personne).
- **Transition** : coupe sur le téléphone.
```
Same fictional film. The lights slowly come back; a follow spot lands on the glass display case: the dark velvet bust is empty, the case's glass door is slightly ajar, with no sign of forced entry. Guests turn around, out of focus, in shock. Camera: slow push-in towards the empty display case, photorealistic. Audio: a rising murmur of disbelief, someone exclaims in French "Le collier !", the quartet has stopped. No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 5 — Le téléphone de la commissaire (8 s)
- **Visuel** : table haute en marbre du salon d'honneur, flûtes de champagne, un téléphone posé : les notifications
  s'empilent (floues), puis un appel entrant fait vibrer les verres.
- **Caméra** : plongée fixe, mise au point sur le téléphone.
- **Audio** : vibrations, tintement des flûtes, foule agitée, talkie-walkie de la sécurité au loin.
- **Transition** : coupe au noir (le jeu reprend le téléphone en main).
```
Same fictional film. On a white marble high table in a reception room, among half-empty champagne flutes, a smartphone lies screen up. Blurred notifications pile up on its lock screen one after another, then an incoming call makes it vibrate so hard the flutes tremble and clink. Nobody picks it up. Camera: static high angle, focus on the phone, warm golden background bokeh. Audio: repeated vibrations, clinking glasses, an agitated crowd, a security walkie-talkie crackling far away. Hard cut to black. No readable text on the phone, no subtitles, no on-screen text, no logos.
```

---

## AFFAIRE #005 — « ROUTE DE NUIT »

**Identité** : sombre, isolée, thriller. Pluie froide, brouillard, forêt, feux de détresse orange. Vercors, vendredi
27 novembre, 23 h 48.
**Idée** : une voiture arrêtée sur une route de col, moteur allumé, portière ouverte, feux de détresse. Personne. Sur
le siège passager, un téléphone s'allume, deux messages, puis un appel. Personne ne répond.

INTRO_SCENE : `scene` road_night (poussée, feux de détresse) → `scene` road_night (pluie sur le pare-brise) →
`phoneOnTable` sur le siège passager (deux messages, un appel) → noir + vibration → déverrouillage.

### PLAN 1 — La voiture arrêtée (8 s)
- **Visuel** : route de montagne étroite entre des sapins, nuit, pluie fine, brouillard ; une voiture arrêtée sur le
  bas-côté, feux de détresse qui clignotent, portière conducteur ouverte, lumière intérieure allumée, moteur qui tourne.
- **Caméra** : poussée lente depuis l'arrière de la voiture.
- **Audio** : pluie, ralenti du moteur, cliquetis du relais des feux de détresse, vent dans les sapins.
- **Transition** : la caméra atteint la portière ouverte.
```
A scene from a fictional French thriller film. Night, cold rain and fog on a narrow mountain pass road between dark fir trees. A car is stopped on the shoulder with its orange hazard lights blinking, the driver's door wide open, the interior light on, exhaust vapour rising: the engine is still running. Nobody is around. Camera: slow push-in from behind the car, handheld, photorealistic, the hazard lights pulsing orange on the wet asphalt and the fog. Audio: steady rain, the engine idling, the ticking of the hazard relay, wind in the firs. No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 2 — L'habitacle vide (8 s)
- **Visuel** : intérieur de la voiture : pluie qui ruisselle sur le pare-brise, essuie-glaces arrêtés, tableau de bord
  allumé, siège conducteur vide, ceinture qui pend, clés sur le contact.
- **Caméra** : dérive lente depuis la banquette arrière vers l'avant.
- **Audio** : pluie sur le toit, moteur, clignotant.
- **Transition** : une vibration sur le siège passager.
```
Same fictional film. Inside the stopped car: rain streams down the windscreen, the wipers are off, the dashboard glows, the driver's seat is empty with the seatbelt hanging loose, the keys in the ignition. The orange hazard light flashes through the rainy windows. Camera: slow drift from the back seat towards the front, photorealistic, moody low light. Audio: rain drumming on the roof, the idling engine, the hazard indicator ticking, then a phone vibration on fabric. No subtitles, no on-screen text, no captions, no logos.
```

### PLAN 3 — Le siège passager (8 s)
- **Visuel** : sur le siège passager en tissu sombre, un téléphone s'allume : une notification (floue), une deuxième,
  puis un appel entrant (écran flou) qui vibre longtemps. Personne ne répond.
- **Caméra** : plan rapproché fixe, reflets orange des feux de détresse sur l'écran.
- **Audio** : vibrations, sonnerie étouffée, pluie, moteur.
- **Transition** : la sonnerie s'arrête ; noir ; une vibration dans le noir.
```
Same fictional film. Close shot of the dark fabric passenger seat of the car: a smartphone lights up with a blurred notification, then a second one, then a blurred incoming call that keeps ringing and vibrating. Nobody answers. The orange hazard light pulses across the phone's glass. Camera: static close shot, photorealistic, shallow depth of field. Audio: phone vibrations on fabric, a muffled ringtone, rain on the roof, the idling engine. The ringing stops; hard cut to black while one last vibration is heard. No readable text on the phone screen, no subtitles, no on-screen text, no logos.
```

### PLAN 4 (optionnel) — Le gyrophare (8 s)
- **Visuel** : plan large, la voiture seule dans le brouillard ; au loin, derrière, le gyrophare orange d'un engin de
  déneigement qui approche lentement.
- **Audio** : moteur lourd qui approche, pluie.
- **Transition** : coupe au noir.
```
Same fictional film. Wide shot: the lone car with blinking hazard lights on the foggy mountain road, dark forest all around. Far behind it, the rotating orange beacon of a snowplough slowly approaches through the fog and rain. Camera: static, low, photorealistic. Audio: rain, the heavy diesel of the approaching snowplough, wind. Hard cut to black. No subtitles, no on-screen text, no captions, no logos.
```

---

# Fiche de casting ElevenLabs

| Rôle | Voix | Ton | Répliques |
|---|---|---|---|
| Cdt. Bernard Lacaze | masculine, grave, légère raucité, 55–60 ans, accent neutre du sud-ouest | sobre, lent, phrases courtes, fatigué mais exigeant, jamais théâtral | intro plans 2, 3, 4, 5, 6, 7, 9, 10, 11 (~22 s) |
| Journaliste #001 | féminine, claire, articulée, ~35 ans | rythme télé, neutre, légère tension | reportage #001 (~8 s) |
| Annonce métro #002 | féminine, neutre, sonorisée | plate, officielle | « Le premier métro en direction de Gare de Vaise entre en station. » |
| Animatrice #004 | féminine, chaleureuse, amplifiée, ~34 ans | enjouée | « Mesdames et messieurs… dans quelques instants, le collier Aurore. » |

Réglages : stabilité 55–65, similarité 75, style 10–20. Export WAV 48 kHz mono, 300 ms de silence avant et après,
normalisé à −16 LUFS.
