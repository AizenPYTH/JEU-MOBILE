# Cinématiques des affaires #002 à #005 — prompts Veo 3.1

Chaque affaire a sa propre séquence d'ouverture. Elle est **déjà jouable dans le jeu** : elle est décrite dans le
fichier de l'affaire (`introScene`) et rendue par `CinematicView` avec des images générées et des sons synthétisés.
Ce document sert à produire la **version filmée** avec Veo 3.1, plan par plan, pour remplacer ou enrichir la version
du jeu.

## Règles communes

- **Format** : 9:16 vertical (comme le téléphone du jeu), 1080p, 8 s par plan, audio activé. Enchaîner les plans avec
  « Extend » ou au montage.
- **Toujours présenter la scène comme une scène de film de fiction** (« a scene from a fictional French thriller
  film »). Ne jamais faire prononcer de nom de personne par un personnage dans un format « reportage » : Veo le bloque
  (voir l'affaire #001). Les textes à l'écran (heures, noms d'affaire) s'ajoutent au montage, pas dans Veo.
- **Aucun texte généré dans l'image** : terminer chaque prompt par « No subtitles, no on-screen text, no captions, no
  logos. » Les écrans de téléphone sont flous ou vus de biais : l'interface réelle est celle du jeu.
- **Personnages** : jamais de gros plan de visage identifiable ; silhouettes, mains, dos, reflets. C'est cohérent avec
  la règle « aucune illustration de personnage » de TRACE et ça évite les refus.
- **Transition vers le jeu** : chaque séquence se termine sur le téléphone (posé, qui vibre, qui s'allume). Le jeu
  enchaîne ensuite : le téléphone est pris en main, déverrouillé, et devient le téléphone de TRACE (même cadrage).
  Ne jamais générer l'interface TRACE dans Veo.
- **Son** : Veo génère l'ambiance ; le jeu a ses propres sons (`metro`, `chime`, `train`, `room`, `sea`, `gulls`,
  `hall`, `powerdown`, `rain`, `engine`, `ring`, `vibrate`, `notification`). Garder la même logique sonore au montage.

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
