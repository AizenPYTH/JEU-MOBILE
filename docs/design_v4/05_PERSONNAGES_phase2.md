# CONCLUDE : ENQUÊTES — Pack personnages v1.0 (verrouillé)

NOREL GAMES · 2026-09-25

Ce document **remplace** la section 1 de `02_PORTRAITS_PHOTOS.md`. Les noms, âges et rôles des suspects viennent des fichiers `case_00N.json`. Les **ids de contact** ont été vérifiés dans ces fichiers : l'id est le prénom en minuscules sans accent, et le propriétaire du téléphone est `me`. Les anciens noms en `c_<prénom>` étaient des ids de conversation et ne doivent plus être utilisés.

## 0. Décisions verrouillées

| Décision | Valeur |
|---|---|
| Joueur femme | **Élise Morel** (inchangé) |
| Joueur homme | **Vincent Delmas**. Ni « Vincent » ni « Delmas » n'existent dans les 5 affaires (vérifié par recherche dans `ScreenshotKit/Sources` ; « Saint-Vincent » est un nom de lieu à Lyon, sans conflit). Remplace Julien Vasseur partout. |
| Rang de départ | **ENQUÊTEUR**. Échelle : ENQUÊTEUR (0) → INSPECTEUR (1) → SENIOR (2–3) → EXPÉRIMENTÉ (4–5). « Recrue » est supprimé. |
| Supérieur / recruteur | **Cdt. Bernard Lacaze** (nom absent des affaires, vérifié) |
| Studio · jeu | **NOREL GAMES** · **CONCLUDE : ENQUÊTES** |
| Service fictif | Bureau des Enquêtes Numériques (BEN) |

## 1. Quatre styles photographiques (communs à plusieurs personnages)

Le style dit **d'où vient la photo** dans le dossier. C'est aussi ce qui distingue une victime d'un suspect au premier regard.

| Code | Usage | Fond | Lumière | Cadrage |
|---|---|---|---|---|
| **S1 · Identité BEN** | Suspects et témoins entendus par le BEN | Mur gris clair #C9C8C3, peinture mate légèrement inégale | Néon plafond 4 000 K + fenêtre à gauche, ombre douce à droite, pas de flash | Tête et épaules, yeux à 38 % du haut, tête = 52 % de la hauteur, 4:5 |
| **S2 · Photo fournie par la famille** | Victimes et personnes disparues | Intérieur ou extérieur réel, flou (f/2) | Naturelle, du jour, non maîtrisée | Photo de la vie courante recadrée au format identité, un peu plus large (tête = 45 %) |
| **S3 · Photo professionnelle / badge** | Propriétaires dont le dossier contient une photo d'employeur | Gris moyen uni #9E9E9A ou blanc cassé | Flash frontal direct, ombre portée nette derrière | Identité stricte, face, tête = 55 % |
| **S4 · Carte d'agent BEN** | Joueur et Cdt. Lacaze | Bleu-gris uni #6F7A86 | Deux sources diffuses de face, très régulières | Identité stricte, face, épaules droites, tête = 55 % |

**Technique commune** : 1024 × 1280 px (4:5), JPEG 85 ou HEIC. Pas de retouche : pores, petites asymétries, cernes et imperfections visibles. Couleurs fidèles, grain léger d'appareil numérique.

---

## 2. Fiches des personnages

Carnation : échelle de Fitzpatrick (I très claire → VI très foncée), pour garder des peaux cohérentes d'une génération à l'autre.

### Affaire #001 · LE DERNIER MESSAGE · Marseille, zone portuaire

**CHR-001-01 · Alex MOREAU**
- **Identité** : 26 ans · H · photographe, co-fondateur du collectif Lumen · #001
- **Relation avec l'affaire** : personne disparue ; propriétaire du téléphone
- **Carnation** : III, claire mate
- **Visage** : forme longue, pommettes marquées
- **Cheveux** : brun très foncé, bouclés serrés, courts, en désordre
- **Yeux** : noisette, un peu enfoncés, cernes marqués
- **Sourcils** : épais, droits ; petite cicatrice verticale dans le sourcil gauche
- **Nez** : droit et fin, légère bosse
- **Barbe** : de 2 jours, irrégulière
- **Morphologie** : mince, épaules étroites, 1,78 m
- **Vêtements** : t-shirt noir délavé au col usé, surchemise anthracite ouverte
- **Accessoires** : aucun
- **Expression** : neutre, fatiguée, esquisse de sourire retenu
- **Photo** : S2 · fond mur blanc cassé d'appartement, flou · lumière de fenêtre à gauche · ¾ vers la gauche, regard caméra
- **Fichier** : `portrait_001_me.jpg`

**CHR-001-02 · Sarah VASSEUR**
- **Identité** : 27 ans · F · ex-compagne d'Alex · #001
- **Relation avec l'affaire** : suspecte
- **Carnation** : II, claire rosée ; taches de rousseur sur le nez et les pommettes
- **Visage** : ovale, menton fin
- **Cheveux** : châtain clair, raides, mi-longs, attachés bas, mèches qui s'échappent
- **Yeux** : vert-gris
- **Sourcils** : fins, légèrement arqués
- **Nez** : petit, retroussé
- **Barbe** : sans objet
- **Morphologie** : mince, 1,65 m
- **Vêtements** : pull en maille bleu marine, col rond, bouloché
- **Accessoires** : petites créoles en argent
- **Expression** : méfiante, bouche fermée
- **Photo** : S1 · face, tête très légèrement inclinée à droite
- **Fichier** : `portrait_001_sarah.jpg`

**CHR-001-03 · Karim HADDAD**
- **Identité** : 30 ans · H · ami d'Alex (Alex lui doit 1 200 €) · #001
- **Relation avec l'affaire** : suspect
- **Carnation** : IV, mate olive
- **Visage** : carré, mâchoire large
- **Cheveux** : noirs, courts, dégradé bas sur les côtés, dessus texturé
- **Yeux** : marron foncé
- **Sourcils** : épais, rapprochés
- **Nez** : droit, large, arête marquée
- **Barbe** : courte, taillée, contours nets
- **Morphologie** : épaules larges, sportif, 1,82 m
- **Vêtements** : bomber kaki foncé sur un sweat à capuche gris chiné
- **Accessoires** : fine chaîne en argent visible au col
- **Expression** : défiante, menton légèrement levé
- **Photo** : S1 · face
- **Fichier** : `portrait_001_karim.jpg`

**CHR-001-04 · Lucas FERRAND**
- **Identité** : 27 ans · H · meilleur ami d'Alex · #001
- **Relation avec l'affaire** : suspect
- **Carnation** : I–II, très claire, rougeurs
- **Visage** : rond, joues pleines
- **Cheveux** : blond sable, mi-courts, en bataille
- **Yeux** : bleu clair
- **Sourcils** : blond clair, peu visibles
- **Nez** : court, arrondi
- **Barbe** : rasé de près, irritation de rasoir au cou
- **Morphologie** : moyenne, légèrement enveloppée, 1,76 m
- **Vêtements** : sweat à capuche gris clair
- **Accessoires** : lunettes rondes à fine monture métal
- **Expression** : nerveuse, demi-sourire gêné
- **Photo** : S1 · ¾ léger vers la droite
- **Fichier** : `portrait_001_lucas.jpg`

**CHR-001-05 · Emma ROUSSEL**
- **Identité** : 28 ans · F · co-fondatrice du collectif Lumen · #001
- **Relation avec l'affaire** : suspecte
- **Carnation** : II–III, claire neutre
- **Visage** : en cœur, pommettes hautes, menton pointu
- **Cheveux** : brun foncé, carré net au menton, raie sur le côté
- **Yeux** : marron clair, regard posé
- **Sourcils** : structurés, naturels
- **Nez** : fin, droit
- **Barbe** : sans objet
- **Morphologie** : mince, élancée, 1,70 m
- **Vêtements** : col roulé noir fin
- **Accessoires** : puces d'oreilles dorées
- **Expression** : calme, inspire confiance, très légère ébauche de sourire
- **Photo** : S1 · face
- **Fichier** : `portrait_001_emma.jpg`

**CHR-001-06 · Inès CARPENTIER**
- **Identité** : 27 ans · F · amie du groupe · #001
- **Relation avec l'affaire** : témoin (soirée au Levant, vernissage)
- **Carnation** : V, brun chaud
- **Visage** : ovale large
- **Cheveux** : noirs, longs, ondulés, volumineux
- **Yeux** : marron foncé, grands
- **Sourcils** : pleins
- **Nez** : large, doux
- **Barbe** : sans objet
- **Morphologie** : moyenne, 1,63 m
- **Vêtements** : veste en jean oversize sur un t-shirt blanc
- **Accessoires** : trois petits anneaux dorés à l'oreille gauche
- **Expression** : inquiète mais ouverte
- **Photo** : S1 · ¾ vers la gauche
- **Fichier** : `portrait_001_ines.jpg`

**CHR-001-07 · Tom DELORME**
- **Identité** : 28 ans · H · partenaire d'escalade d'Alex · #001
- **Relation avec l'affaire** : témoin
- **Carnation** : II hâlée, nez brûlé par le soleil
- **Visage** : long, anguleux
- **Cheveux** : crâne tondu à 3 mm
- **Yeux** : gris-bleu
- **Sourcils** : clairs, fins
- **Nez** : aquilin
- **Barbe** : de 3 jours, claire
- **Morphologie** : sec, athlétique, 1,80 m
- **Vêtements** : t-shirt technique bleu pétrole
- **Accessoires** : aucun
- **Expression** : détendue, un peu méfiante
- **Photo** : S1 · face
- **Fichier** : `portrait_001_tom.jpg`

### Affaire #002 · PREMIER MÉTRO · Lyon, Confluence — Le Silo

**CHR-002-01 · Clémence AUBRY**
- **Identité** : 30 ans · F · régisseuse son au Silo · #002
- **Relation avec l'affaire** : personne disparue ; propriétaire du téléphone
- **Carnation** : II, claire
- **Visage** : ovale fin, traits anguleux
- **Cheveux** : pixie décoloré platine, racines foncées de 2 cm, en désordre
- **Yeux** : bleu-gris, cernes marqués
- **Sourcils** : foncés, naturels (contraste avec les cheveux)
- **Nez** : fin, droit
- **Barbe** : sans objet
- **Morphologie** : mince, 1,68 m
- **Vêtements** : veste de travail softshell noire, écussons techniques sans texte
- **Accessoires** : petit anneau à la narine gauche
- **Expression** : directe, fatiguée
- **Photo** : S3 (photo du badge du Silo) · face
- **Fichier** : `portrait_002_me.jpg`

**CHR-002-02 · Anaïs AUBRY**
- **Identité** : 33 ans · F · sœur de Clémence, infirmière · #002
- **Relation avec l'affaire** : témoin (dernier appel)
- **Carnation** : II, claire. Ressemblance familiale avec Clémence : mêmes yeux bleu-gris, même nez.
- **Visage** : ovale, plus plein que celui de Clémence
- **Cheveux** : châtain foncé, longs, queue de cheval basse
- **Yeux** : bleu-gris, rougis
- **Sourcils** : naturels
- **Nez** : fin, droit (comme Clémence)
- **Barbe** : sans objet
- **Morphologie** : moyenne, 1,66 m
- **Vêtements** : polaire hospitalière bleu marine, sans logo
- **Accessoires** : aucun
- **Expression** : anxieuse
- **Photo** : S1 · face
- **Fichier** : `portrait_002_anais.jpg`

**CHR-002-03 · Mathilde ROCHE**
- **Identité** : 41 ans · F · gérante du Silo · #002
- **Relation avec l'affaire** : suspecte
- **Carnation** : II–III, claire chaude, fines rides au coin des yeux
- **Visage** : carré doux, mâchoire définie
- **Cheveux** : auburn cuivré, chignon pratique, quelques mèches grises
- **Yeux** : noisette
- **Sourcils** : auburn, dessinés
- **Nez** : droit, un peu long
- **Barbe** : sans objet
- **Morphologie** : moyenne, tonique, 1,69 m
- **Vêtements** : blazer noir sur un t-shirt de groupe noir délavé (motif illisible)
- **Accessoires** : créoles argent moyennes
- **Expression** : professionnelle, maîtrisée
- **Photo** : S1 · ¾ léger vers la gauche
- **Fichier** : `portrait_002_mathilde.jpg`

**CHR-002-04 · Yanis FERHAT**
- **Identité** : 32 ans · H · DJ résident du Silo, ex de Clémence · #002
- **Relation avec l'affaire** : suspect
- **Carnation** : III–IV, mate claire
- **Visage** : long, joues creuses
- **Cheveux** : noirs, bouclés denses, mi-longs
- **Yeux** : marron foncé, paupières lourdes
- **Sourcils** : épais
- **Nez** : fort, légèrement busqué
- **Barbe** : fine moustache et barbe clairsemée
- **Morphologie** : longiligne, 1,84 m
- **Vêtements** : t-shirt noir oversize
- **Accessoires** : casque audio autour du cou
- **Expression** : fatigue de fin de nuit, regard un peu fuyant
- **Photo** : S1 · face
- **Fichier** : `portrait_002_yanis.jpg`

**CHR-002-05 · Bastien KERMARREC**
- **Identité** : 30 ans · H · colocataire de Clémence · #002
- **Relation avec l'affaire** : suspect
- **Carnation** : I, très claire, rougeurs aux pommettes
- **Visage** : large, rond-carré
- **Cheveux** : blond-roux, courts, en bataille
- **Yeux** : bleus
- **Sourcils** : roux clair
- **Nez** : large
- **Barbe** : blond-roux fournie, 1 cm
- **Morphologie** : trapu, 1,80 m
- **Vêtements** : pull marin en laine écrue
- **Accessoires** : aucun
- **Expression** : encore endormi, surpris
- **Photo** : S1 · face
- **Fichier** : `portrait_002_bastien.jpg`

**CHR-002-06 · Raphaël SANÉ**
- **Identité** : 35 ans · H · responsable sécurité du Silo · #002
- **Relation avec l'affaire** : suspect
- **Carnation** : VI, brun foncé
- **Visage** : ovale allongé, mâchoire nette
- **Cheveux** : noirs, presque ras
- **Yeux** : marron foncé
- **Sourcils** : nets
- **Nez** : large, arête plate
- **Barbe** : rasé de près
- **Morphologie** : grand et massif, 1,92 m
- **Vêtements** : polo noir sans logo
- **Accessoires** : fil d'oreillette transparent
- **Expression** : sérieuse, neutre
- **Photo** : S1 · face
- **Fichier** : `portrait_002_raphael.jpg`

**CHR-002-07 · Kader BENSLIMANE**
- **Identité** : 42 ans · H · membre du staff du Silo · #002
- **Relation avec l'affaire** : témoin
- **Carnation** : IV, mate
- **Visage** : rond
- **Cheveux** : sous un bonnet noir, tempes grisonnantes visibles
- **Yeux** : marron
- **Sourcils** : fournis, grisonnants
- **Nez** : rond
- **Barbe** : courte, poivre et sel
- **Morphologie** : corpulent, 1,75 m
- **Vêtements** : veste noire de staff sans texte
- **Accessoires** : bonnet noir
- **Expression** : calme, bienveillante
- **Photo** : S1 · ¾ vers la droite
- **Fichier** : `portrait_002_kader.jpg`

### Affaire #003 · APRÈS LA FÊTE · Cap Ferret, Villa Les Oyats

**CHR-003-01 · Paul CASTAING**
- **Identité** : 33 ans · H · frère de Jeanne, gère une école de surf · #003
- **Relation avec l'affaire** : victime (chute dans l'escalier de la plage)
- **Carnation** : III, claire très hâlée, peau marquée par le sel
- **Visage** : carré, ouvert
- **Cheveux** : châtain décoloré par le soleil, mi-longs, ondulés, rejetés en arrière
- **Yeux** : verts
- **Sourcils** : châtain clair, épais
- **Nez** : droit, un peu large, coup de soleil
- **Barbe** : de 3 jours
- **Morphologie** : athlétique, large, 1,83 m
- **Vêtements** : sweat délavé gris-bleu
- **Accessoires** : aucun
- **Expression** : sourire décontracté
- **Photo** : S2 · fond extérieur de plage flou, lumière de fin de journée · face
- **Fichier** : `portrait_003_paul.jpg`

**CHR-003-02 · Jeanne CASTAING**
- **Identité** : 30 ans · F · architecte d'intérieur, sœur de Paul · #003
- **Relation avec l'affaire** : propriétaire du téléphone ; organisatrice de la fête
- **Carnation** : II–III, claire, coup de soleil aux pommettes. Ressemblance avec Paul : yeux verts, même nez.
- **Visage** : ovale
- **Cheveux** : châtain clair, relevés en pince, mèches qui tombent
- **Yeux** : verts, rougis
- **Sourcils** : fins
- **Nez** : droit (comme Paul)
- **Barbe** : sans objet
- **Morphologie** : mince, 1,67 m
- **Vêtements** : chemise en lin blanc froissée
- **Accessoires** : pince à cheveux écaille
- **Expression** : bouleversée, yeux gonflés
- **Photo** : S1 · face
- **Fichier** : `portrait_003_me.jpg`

**CHR-003-03 · Maxime RIVIÈRE**
- **Identité** : 34 ans · H · compagnon de Jeanne · #003
- **Relation avec l'affaire** : suspect
- **Carnation** : II, claire
- **Visage** : ovale régulier
- **Cheveux** : brun foncé, courts, nets, raie sur le côté
- **Yeux** : bleu foncé
- **Sourcils** : droits, nets
- **Nez** : fin, droit
- **Barbe** : rasé de près
- **Morphologie** : mince, athlétique, 1,81 m
- **Vêtements** : polo bleu marine repassé
- **Accessoires** : aucun visible
- **Expression** : polie, rassurante, très composée
- **Photo** : S1 · face
- **Fichier** : `portrait_003_maxime.jpg`

**CHR-003-04 · Diane LESAGE**
- **Identité** : 31 ans · F · femme de Paul · #003
- **Relation avec l'affaire** : suspecte
- **Carnation** : II hâlée
- **Visage** : long, mâchoire serrée
- **Cheveux** : blond miel, tresse lâche à moitié défaite
- **Yeux** : bleu clair, gonflés
- **Sourcils** : blonds
- **Nez** : fin, pointu
- **Barbe** : sans objet
- **Morphologie** : sportive, fine, 1,72 m
- **Vêtements** : sweat gris chiné, col rond
- **Accessoires** : alliance (hors cadre)
- **Expression** : douleur contenue
- **Photo** : S1 · ¾ vers la gauche
- **Fichier** : `portrait_003_diane.jpg`

**CHR-003-05 · Louise FERRER**
- **Identité** : 30 ans · F · meilleure amie de Jeanne (doit 3 000 € à Paul) · #003
- **Relation avec l'affaire** : suspecte
- **Carnation** : III, mate claire méditerranéenne
- **Visage** : rond, joues marquées
- **Cheveux** : brun très foncé, longs, épais, ondulés
- **Yeux** : marron chaud, grands
- **Sourcils** : épais, arqués
- **Nez** : court, légèrement retroussé
- **Barbe** : sans objet
- **Morphologie** : moyenne, ronde, 1,62 m
- **Vêtements** : marinière bleu et blanc
- **Accessoires** : plusieurs bagues fines en argent (une main visible au bas du cadre)
- **Expression** : agitée, regard mobile
- **Photo** : S1 · face
- **Fichier** : `portrait_003_louise.jpg`

**CHR-003-06 · Grégoire SALLES**
- **Identité** : 36 ans · H · associé de Paul à l'école de surf · #003
- **Relation avec l'affaire** : suspect
- **Carnation** : II burinée, rides de soleil
- **Visage** : carré, massif
- **Cheveux** : crâne rasé
- **Yeux** : marron clair, plissés
- **Sourcils** : épais, foncés
- **Nez** : légèrement dévié (ancienne fracture)
- **Barbe** : courte, foncée, taillée
- **Morphologie** : trapu, musclé, 1,79 m
- **Vêtements** : col de lycra de surf noir sous une polaire
- **Accessoires** : aucun
- **Expression** : dure, méfiante
- **Photo** : S1 · face
- **Fichier** : `portrait_003_gregoire.jpg`

### Affaire #004 · 90 SECONDES · Paris, Pavillon Mercure

**CHR-004-01 · Salomé TESSIER**
- **Identité** : 35 ans · F · commissaire d'exposition · #004
- **Relation avec l'affaire** : propriétaire du téléphone ; responsable de l'exposition
- **Carnation** : II, claire
- **Visage** : ovale fin, cou long
- **Cheveux** : brun foncé, chignon bas défait
- **Yeux** : marron foncé, mascara légèrement coulé
- **Sourcils** : fins
- **Nez** : fin, légèrement busqué
- **Barbe** : sans objet
- **Morphologie** : mince, 1,70 m
- **Vêtements** : manteau noir sur une robe de soirée noire (bretelle visible)
- **Accessoires** : aucun
- **Expression** : épuisée, choquée
- **Photo** : S1 · ¾ vers la droite
- **Fichier** : `portrait_004_me.jpg`

**CHR-004-02 · Camille TESSIER**
- **Identité** : 32 ans · F · sœur de Salomé · #004
- **Relation avec l'affaire** : témoin (proche)
- **Carnation** : II, claire. Ressemblance avec Salomé : yeux et nez.
- **Visage** : plus rond que celui de Salomé
- **Cheveux** : châtain, carré long
- **Yeux** : marron foncé
- **Sourcils** : naturels
- **Nez** : fin, légèrement busqué
- **Barbe** : sans objet
- **Morphologie** : moyenne, 1,65 m
- **Vêtements** : pull camel
- **Accessoires** : aucun
- **Expression** : inquiète
- **Photo** : S1 · face
- **Fichier** : `portrait_004_camille.jpg`

**CHR-004-03 · Adrien STERNE**
- **Identité** : 61 ans · H · collectionneur, propriétaire du collier Aurore · #004
- **Relation avec l'affaire** : suspect
- **Carnation** : III, claire bronzée, peau fine et ridée
- **Visage** : long, menton fort
- **Cheveux** : argentés, épais, coiffés en arrière
- **Yeux** : gris clair
- **Sourcils** : gris, fournis
- **Nez** : long, droit
- **Barbe** : rasé de près
- **Morphologie** : grand, mince, 1,85 m
- **Vêtements** : costume sombre sur mesure, chemise blanche col ouvert
- **Accessoires** : aucun visible
- **Expression** : courtoise, indéchiffrable
- **Photo** : S1 · face
- **Fichier** : `portrait_004_sterne.jpg`

**CHR-004-04 · Enzo BARROS**
- **Identité** : 23 ans · H · extra serveur embauché le jour même · #004
- **Relation avec l'affaire** : suspect
- **Carnation** : III, mate claire ; légères marques d'acné sur les joues
- **Visage** : rond, jeune
- **Cheveux** : noirs, courts, gominés vers le haut
- **Yeux** : marron foncé
- **Sourcils** : fins
- **Nez** : court, large
- **Barbe** : duvet de moustache
- **Morphologie** : mince, 1,74 m
- **Vêtements** : chemise blanche de serveur
- **Accessoires** : nœud papillon noir défait
- **Expression** : apeurée
- **Photo** : S1 · face
- **Fichier** : `portrait_004_enzo.jpg`

**CHR-004-05 · Victor ALMEIDA**
- **Identité** : 47 ans · H · régisseur lumière du Pavillon · #004
- **Relation avec l'affaire** : suspect
- **Carnation** : III–IV, mate
- **Visage** : carré, large
- **Cheveux** : poivre et sel, bouclés
- **Yeux** : marron
- **Sourcils** : broussailleux
- **Nez** : large, rond
- **Barbe** : poivre et sel, 5 jours
- **Morphologie** : corpulent, 1,77 m
- **Vêtements** : t-shirt noir de technicien
- **Accessoires** : lunettes remontées sur la tête
- **Expression** : agacée
- **Photo** : S1 · ¾ vers la gauche
- **Fichier** : `portrait_004_victor.jpg`

**CHR-004-06 · Iris NAKAMURA**
- **Identité** : 34 ans · F · animatrice de la soirée · #004
- **Relation avec l'affaire** : suspecte
- **Carnation** : II–III, claire neutre
- **Visage** : ovale, pommettes hautes
- **Cheveux** : noirs, lisses, carré court au menton, brillants
- **Yeux** : marron foncé en amande, eye-liner précis
- **Sourcils** : droits
- **Nez** : petit, fin
- **Barbe** : sans objet
- **Morphologie** : mince, 1,64 m
- **Vêtements** : encolure d'une robe noire à sequins
- **Accessoires** : fines boucles d'oreilles pendantes
- **Expression** : sourire de scène qui s'efface
- **Photo** : S1 · face
- **Fichier** : `portrait_004_iris.jpg`

**CHR-004-07 · Hélène DUBREUIL**
- **Identité** : 58 ans · F · intervenante officielle du gala (discours) · #004
- **Relation avec l'affaire** : témoin
- **Carnation** : II, claire, rides
- **Visage** : rond
- **Cheveux** : gris, courts, coupe nette
- **Yeux** : bleus
- **Sourcils** : gris, fins
- **Nez** : rond
- **Barbe** : sans objet
- **Morphologie** : moyenne, 1,62 m
- **Vêtements** : tailleur bleu nuit
- **Accessoires** : puces d'oreilles en perle
- **Expression** : officielle, sérieuse
- **Photo** : S1 · face
- **Fichier** : `portrait_004_helene.jpg`

### Affaire #005 · ROUTE DE NUIT · Vercors, col de la Croix-Perrin

**CHR-005-01 · Solène MARCHETTI**
- **Identité** : 34 ans · F · journaliste à L'Écho des Alpes, mère de Léo et Nina · #005
- **Relation avec l'affaire** : personne disparue ; propriétaire du téléphone
- **Carnation** : III, mate claire
- **Visage** : en losange, pommettes marquées
- **Cheveux** : brun foncé, ondulés, aux épaules
- **Yeux** : marron foncé
- **Sourcils** : épais, marqués
- **Nez** : droit, légère bosse
- **Barbe** : sans objet
- **Morphologie** : moyenne, 1,66 m
- **Vêtements** : veste de pluie kaki, col relevé
- **Accessoires** : cordon de badge de presse, sans texte
- **Expression** : déterminée, fatiguée
- **Photo** : S3 (trombinoscope de la rédaction) · face
- **Fichier** : `portrait_005_me.jpg`

**CHR-005-02 · Gilles ARNAUD**
- **Identité** : 54 ans · H · adjoint à l'urbanisme de Vallières-en-Vercors · #005
- **Relation avec l'affaire** : suspect
- **Carnation** : II, claire, teint rougeaud
- **Visage** : rond, léger double menton
- **Cheveux** : gris, clairsemés, coiffés en arrière, front dégarni
- **Yeux** : marron
- **Sourcils** : gris, fins
- **Nez** : court
- **Barbe** : rasé
- **Morphologie** : enveloppé, 1,72 m
- **Vêtements** : gilet matelassé beige sur une chemise bleu ciel et une cravate
- **Accessoires** : lunettes rondes écaille
- **Expression** : aimable d'élu local
- **Photo** : S1 · face
- **Fichier** : `portrait_005_gilles.jpg`

**CHR-005-03 · Thierry BRASSAC**
- **Identité** : 61 ans · H · patron de Brassac Granulats · #005
- **Relation avec l'affaire** : suspect
- **Carnation** : II, rougie par le grand air, couperose
- **Visage** : large, massif
- **Cheveux** : blancs, courts, en brosse
- **Yeux** : bleu pâle, petits
- **Sourcils** : blancs, épais
- **Nez** : fort, épaté
- **Barbe** : blanche, 3 jours
- **Morphologie** : lourd, 1,80 m
- **Vêtements** : veste de travail bleue poussiéreuse sur une chemise à carreaux
- **Accessoires** : aucun
- **Expression** : hostile
- **Photo** : S1 · face
- **Fichier** : `portrait_005_thierry.jpg`

**CHR-005-04 · Romain VIDAL**
- **Identité** : 37 ans · H · ex-mari de Solène · #005
- **Relation avec l'affaire** : suspect
- **Carnation** : II, claire
- **Visage** : ovale allongé
- **Cheveux** : châtain, courts, un peu longs sur le dessus
- **Yeux** : marron clair, cernés
- **Sourcils** : moyens
- **Nez** : droit
- **Barbe** : de 3 jours, châtain
- **Morphologie** : mince, 1,79 m
- **Vêtements** : polaire grise zippée
- **Accessoires** : aucun
- **Expression** : lassitude de père fatigué
- **Photo** : S1 · ¾ vers la droite
- **Fichier** : `portrait_005_romain.jpg`

**CHR-005-05 · Agathe LEMOINE**
- **Identité** : 49 ans · F · directrice de la rédaction · #005
- **Relation avec l'affaire** : suspecte
- **Carnation** : II, claire
- **Visage** : anguleux, pommettes hautes
- **Cheveux** : blond cendré argenté, coupe courte garçonne
- **Yeux** : gris-vert
- **Sourcils** : fins
- **Nez** : fin, droit
- **Barbe** : sans objet
- **Morphologie** : mince, 1,70 m
- **Vêtements** : blazer noir sur une chemise blanche
- **Accessoires** : lunettes de lecture sur un cordon
- **Expression** : vive, pressée
- **Photo** : S1 · face
- **Fichier** : `portrait_005_agathe.jpg`

**CHR-005-06 · Julien FAURE**
- **Identité** : 29 ans · H · conducteur d'engins à la carrière, source de Solène · #005
- **Relation avec l'affaire** : suspect
- **Carnation** : II hâlée, nuque rouge
- **Visage** : carré, jeune
- **Cheveux** : châtain, courts, aplatis par un casque
- **Yeux** : bleu-vert
- **Sourcils** : châtain
- **Nez** : légèrement épaté
- **Barbe** : rasage irrégulier
- **Morphologie** : robuste, 1,78 m
- **Vêtements** : veste haute visibilité orange sur un sweat gris, sans texte
- **Accessoires** : aucun
- **Expression** : effrayée
- **Photo** : S1 · face
- **Fichier** : `portrait_005_julien.jpg`

### Méta · joueur et BEN

**CHR-P-01 · Élise MOREL, apparence A**
- **Identité** : 38 ans · F · enquêtrice (joueuse)
- **Relation** : rejoint le BEN, affectée au dossier #001
- **Carnation** : II, claire
- **Visage** : ovale, pommettes larges, fines rides d'expression
- **Cheveux** : blond foncé, queue de cheval basse
- **Yeux** : gris-bleu
- **Sourcils** : naturels, moyens
- **Nez** : droit
- **Barbe** : sans objet
- **Morphologie** : moyenne, 1,70 m
- **Vêtements** : manteau de laine marine sur un pull gris
- **Accessoires** : aucun
- **Expression** : calme, expérimentée
- **Photo** : S4 · face stricte
- **Fichier** : `player_elise_a.jpg`

**CHR-P-02 · Élise MOREL, apparence B**
- **Identité** : 36 ans · F · enquêtrice (joueuse)
- **Carnation** : IV, mate (origine nord-africaine)
- **Visage** : long, menton fin
- **Cheveux** : noirs, chignon bas
- **Yeux** : marron foncé
- **Sourcils** : épais
- **Nez** : droit, long
- **Barbe** : sans objet
- **Morphologie** : mince, 1,68 m
- **Vêtements** : trench sombre sur un col roulé noir
- **Accessoires** : aucun
- **Expression** : concentrée
- **Photo** : S4 · face stricte
- **Fichier** : `player_elise_b.jpg`

**CHR-P-03 · Vincent DELMAS, apparence A**
- **Identité** : 40 ans · H · enquêteur (joueur)
- **Carnation** : II, claire
- **Visage** : carré
- **Cheveux** : châtain grisonnant, courts
- **Yeux** : marron
- **Sourcils** : épais, droits
- **Nez** : droit, légèrement large
- **Barbe** : de 3 jours, poivre et sel
- **Morphologie** : solide, 1,81 m
- **Vêtements** : parka sombre sur une chemise blanche
- **Accessoires** : aucun
- **Expression** : regard posé, stable
- **Photo** : S4 · face stricte
- **Fichier** : `player_vincent_a.jpg`

**CHR-P-04 · Vincent DELMAS, apparence B**
- **Identité** : 37 ans · H · enquêteur (joueur)
- **Carnation** : V–VI, brun foncé (origine ouest-africaine)
- **Visage** : ovale
- **Cheveux** : noirs, très courts
- **Yeux** : marron foncé
- **Sourcils** : nets
- **Nez** : large
- **Barbe** : rasé de près
- **Morphologie** : grand, mince, 1,86 m
- **Vêtements** : manteau anthracite sur un pull noir
- **Accessoires** : aucun
- **Expression** : autorité tranquille
- **Photo** : S4 · face stricte
- **Fichier** : `player_vincent_b.jpg`

**CHR-N-01 · Cdt. Bernard LACAZE**
- **Identité** : 58 ans · H · commandant du BEN, recruteur
- **Relation** : remet le dossier #001 ; signe les rapports ; voix de la cinématique
- **Carnation** : II, claire, peau marquée
- **Visage** : long, joues creusées
- **Cheveux** : gris, courts
- **Yeux** : bleu délavé
- **Sourcils** : gris, broussailleux
- **Nez** : long, légèrement aquilin
- **Barbe** : moustache grise, rasé ailleurs
- **Morphologie** : mince, un peu voûté, 1,79 m
- **Vêtements** : chemise blanche aux manches retroussées, cravate desserrée
- **Accessoires** : lunettes de lecture demi-lune
- **Expression** : fatiguée mais vive
- **Photo** : S4 · face
- **Fichier** : `npc_lacaze.jpg`

---

## 3. Tableau maître (38)

| ID | Nom | Âge | Sexe | Affaire | Rôle | Style | Fichier |
|---|---|---|---|---|---|---|---|
| CHR-001-01 | Alex Moreau | 26 | H | #001 | Disparu · propriétaire | S2 | `portrait_001_me` |
| CHR-001-02 | Sarah Vasseur | 27 | F | #001 | Suspecte | S1 | `portrait_001_sarah` |
| CHR-001-03 | Karim Haddad | 30 | H | #001 | Suspect | S1 | `portrait_001_karim` |
| CHR-001-04 | Lucas Ferrand | 27 | H | #001 | Suspect | S1 | `portrait_001_lucas` |
| CHR-001-05 | Emma Roussel | 28 | F | #001 | Suspecte | S1 | `portrait_001_emma` |
| CHR-001-06 | Inès Carpentier | 27 | F | #001 | Témoin | S1 | `portrait_001_ines` |
| CHR-001-07 | Tom Delorme | 28 | H | #001 | Témoin | S1 | `portrait_001_tom` |
| CHR-002-01 | Clémence Aubry | 30 | F | #002 | Disparue · propriétaire | S3 | `portrait_002_me` |
| CHR-002-02 | Anaïs Aubry | 33 | F | #002 | Témoin (sœur) | S1 | `portrait_002_anais` |
| CHR-002-03 | Mathilde Roche | 41 | F | #002 | Suspecte | S1 | `portrait_002_mathilde` |
| CHR-002-04 | Yanis Ferhat | 32 | H | #002 | Suspect | S1 | `portrait_002_yanis` |
| CHR-002-05 | Bastien Kermarrec | 30 | H | #002 | Suspect | S1 | `portrait_002_bastien` |
| CHR-002-06 | Raphaël Sané | 35 | H | #002 | Suspect | S1 | `portrait_002_raphael` |
| CHR-002-07 | Kader Benslimane | 42 | H | #002 | Témoin | S1 | `portrait_002_kader` |
| CHR-003-01 | Paul Castaing | 33 | H | #003 | Victime | S2 | `portrait_003_paul` |
| CHR-003-02 | Jeanne Castaing | 30 | F | #003 | Propriétaire | S1 | `portrait_003_me` |
| CHR-003-03 | Maxime Rivière | 34 | H | #003 | Suspect | S1 | `portrait_003_maxime` |
| CHR-003-04 | Diane Lesage | 31 | F | #003 | Suspecte | S1 | `portrait_003_diane` |
| CHR-003-05 | Louise Ferrer | 30 | F | #003 | Suspecte | S1 | `portrait_003_louise` |
| CHR-003-06 | Grégoire Salles | 36 | H | #003 | Suspect | S1 | `portrait_003_gregoire` |
| CHR-004-01 | Salomé Tessier | 35 | F | #004 | Propriétaire | S1 | `portrait_004_me` |
| CHR-004-02 | Camille Tessier | 32 | F | #004 | Témoin (sœur) | S1 | `portrait_004_camille` |
| CHR-004-03 | Adrien Sterne | 61 | H | #004 | Suspect | S1 | `portrait_004_sterne` |
| CHR-004-04 | Enzo Barros | 23 | H | #004 | Suspect | S1 | `portrait_004_enzo` |
| CHR-004-05 | Victor Almeida | 47 | H | #004 | Suspect | S1 | `portrait_004_victor` |
| CHR-004-06 | Iris Nakamura | 34 | F | #004 | Suspecte | S1 | `portrait_004_iris` |
| CHR-004-07 | Hélène Dubreuil | 58 | F | #004 | Témoin | S1 | `portrait_004_helene` |
| CHR-005-01 | Solène Marchetti | 34 | F | #005 | Disparue · propriétaire | S3 | `portrait_005_me` |
| CHR-005-02 | Gilles Arnaud | 54 | H | #005 | Suspect | S1 | `portrait_005_gilles` |
| CHR-005-03 | Thierry Brassac | 61 | H | #005 | Suspect | S1 | `portrait_005_thierry` |
| CHR-005-04 | Romain Vidal | 37 | H | #005 | Suspect | S1 | `portrait_005_romain` |
| CHR-005-05 | Agathe Lemoine | 49 | F | #005 | Suspecte | S1 | `portrait_005_agathe` |
| CHR-005-06 | Julien Faure | 29 | H | #005 | Suspect | S1 | `portrait_005_julien` |
| CHR-P-01 | Élise Morel (A) | 38 | F | — | Joueuse | S4 | `player_elise_a` |
| CHR-P-02 | Élise Morel (B) | 36 | F | — | Joueuse | S4 | `player_elise_b` |
| CHR-P-03 | Vincent Delmas (A) | 40 | H | — | Joueur | S4 | `player_vincent_a` |
| CHR-P-04 | Vincent Delmas (B) | 37 | H | — | Joueur | S4 | `player_vincent_b` |
| CHR-N-01 | Cdt. Bernard Lacaze | 58 | H | — | Recruteur / supérieur | S4 | `npc_lacaze` |

Tous les fichiers sont en `.jpg`. Le tableau ne dit volontairement pas qui est coupable : les portraits doivent être produits sans le savoir.

---

## 4. Prompts individuels (GPT Image)

Chaque prompt est autonome. Taille demandée : **1024 × 1536** (portrait), puis recadrage au 4:5 selon le §7. Toujours générer **4 propositions** et retenir la moins « parfaite ».

**Fin commune** (déjà incluse dans chaque prompt) : `Fictional person, not a real or famous person. Photorealistic, natural skin texture with visible pores and small imperfections, no retouching, no beauty filter, no text, no watermark, no border.`

- **S1** = `ID photograph taken at a police office: plain light grey matte wall with slightly uneven paint, overhead fluorescent light plus a window on the left, soft shadow on the right side of the face, no flash, basic digital camera at eye level, 50mm, head and shoulders.`
- **S2** = `Casual photo provided by the family, taken with a smartphone in real life, cropped to an ID-style head-and-shoulders framing, background softly out of focus.`
- **S3** = `Employee badge photo: plain mid-grey background, direct on-camera flash with a hard shadow behind the head, straight-on head and shoulders.`
- **S4** = `Official agent ID card photo: plain blue-grey background, soft even frontal lighting from two diffused sources, straight-on head and shoulders, neutral posture.`

**#001**
1. `portrait_001_me` — `[S2] Indoor, off-white apartment wall behind, window light from the left. A 26-year-old French man, light matte skin, long face with marked cheekbones, short tight dark-brown curls in a mess, hazel slightly deep-set eyes with dark circles, thick straight eyebrows with a small vertical scar in the left eyebrow, thin straight nose with a slight bump, uneven two-day stubble, slim with narrow shoulders, faded black t-shirt with worn collar under an open charcoal overshirt, neutral tired expression with a held-back half smile, face turned three-quarters to the left, eyes to camera. [fin commune]`
2. `portrait_001_sarah` — `[S1] A 27-year-old French woman, fair pinkish skin with freckles across nose and cheeks, oval face with a fine chin, straight light-chestnut shoulder-length hair tied low with loose strands, green-grey eyes, thin softly arched eyebrows, small upturned nose, pilled navy crew-neck knit sweater, small silver hoop earrings, wary closed-mouth expression, facing camera with head slightly tilted right. [fin commune]`
3. `portrait_001_karim` — `[S1] A 30-year-old French man of North African descent, olive skin, square face with a wide jaw, short black hair with a low fade and textured top, dark brown eyes, thick close-set eyebrows, straight broad nose with a strong bridge, short neatly trimmed beard, broad athletic shoulders, dark khaki bomber jacket over a heather-grey hoodie, thin silver chain at the collar, defiant look with chin slightly raised, facing camera. [fin commune]`
4. `portrait_001_lucas` — `[S1] A 27-year-old French man, very fair skin with redness, round face with full cheeks, messy medium-short sandy-blond hair, light blue eyes behind thin round metal glasses, barely visible light-blond eyebrows, short rounded nose, clean shaven with razor irritation on the neck, slightly heavy build, light grey hoodie, nervous embarrassed half smile, face turned slightly to the right. [fin commune]`
5. `portrait_001_emma` — `[S1] A 28-year-old French woman, fair neutral skin, heart-shaped face with high cheekbones and a pointed chin, sleek dark-brown chin-length bob with a side parting, light-brown steady eyes, groomed natural eyebrows, thin straight nose, slim and tall, thin black turtleneck, small gold stud earrings, calm trustworthy expression with the faintest smile, facing camera. [fin commune]`
6. `portrait_001_ines` — `[S1] A 27-year-old French woman with warm brown skin, wide oval face, long voluminous wavy black hair, large dark-brown eyes, full eyebrows, broad soft nose, oversized denim jacket over a white t-shirt, three small gold rings in the left ear, worried but open expression, face three-quarters to the left. [fin commune]`
7. `portrait_001_tom` — `[S1] A 28-year-old French man, fair tanned skin with a sunburnt nose, long angular face, buzz-cut head (3 mm), grey-blue eyes, thin light eyebrows, aquiline nose, light three-day stubble, lean climber build, petrol-blue technical t-shirt, relaxed but slightly suspicious expression, facing camera. [fin commune]`

**#002**
8. `portrait_002_me` — `[S3] A 30-year-old French woman sound engineer, fair skin, fine angular oval face, messy platinum-bleached pixie cut with 2 cm dark roots, blue-grey eyes with heavy dark circles, dark natural eyebrows, thin straight nose with a small ring in the left nostril, black softshell work jacket with blank technical patches, direct tired gaze, facing camera. [fin commune]`
9. `portrait_002_anais` — `[S1] A 33-year-old French woman nurse, fair skin, fuller oval face, long dark-chestnut hair in a low ponytail, blue-grey red-rimmed eyes, natural eyebrows, thin straight nose, navy hospital fleece without logo, anxious expression, facing camera. She looks like the older sister of a woman with the same blue-grey eyes and nose. [fin commune]`
10. `portrait_002_mathilde` — `[S1] A 41-year-old French woman club manager, fair warm skin with fine lines at the eyes, soft square face with a defined jaw, copper-auburn hair in a practical bun with a few grey strands, hazel eyes, groomed auburn eyebrows, straight slightly long nose, black blazer over a faded black band t-shirt with an unreadable print, medium silver hoops, professional controlled expression, face slightly three-quarters to the left. [fin commune]`
11. `portrait_002_yanis` — `[S1] A 32-year-old French man of Algerian descent, light olive skin, long face with hollow cheeks, dense medium-length black curls, heavy-lidded dark-brown eyes, thick eyebrows, strong slightly hooked nose, thin moustache and sparse beard, tall and lanky, oversized black t-shirt, DJ headphones around the neck, end-of-night tiredness, gaze slightly avoiding the lens, facing camera. [fin commune]`
12. `portrait_002_bastien` — `[S1] A 30-year-old man from Brittany, very fair skin with red cheeks, broad round-square face, short messy strawberry-blond hair, blue eyes, light ginger eyebrows, wide nose, full 1 cm strawberry-blond beard, stocky build, cream wool fisherman sweater, just-woken-up surprised expression, facing camera. [fin commune]`
13. `portrait_002_raphael` — `[S1] A 35-year-old French man of Senegalese descent, very dark skin, long oval face with a clean jawline, near-shaved black hair, dark-brown eyes, neat eyebrows, broad flat-bridged nose, clean shaven, very tall and heavily built, plain black polo shirt without logo, clear earpiece wire, serious neutral expression, facing camera. [fin commune]`
14. `portrait_002_kader` — `[S1] A 42-year-old French man, olive skin, round face, black beanie with greying temples showing, brown eyes, bushy greying eyebrows, round nose, short salt-and-pepper beard, heavy build, plain black staff jacket without text, calm kind expression, face three-quarters to the right. [fin commune]`

**#003**
15. `portrait_003_paul` — `[S2] Outdoors near a beach at late afternoon, blurred sand and sky behind. A 33-year-old French man surf instructor, deeply tanned salt-weathered skin, open square face, sun-bleached wavy medium-length brown hair pushed back, green eyes, thick light-brown eyebrows, straight slightly wide sunburnt nose, three-day stubble, broad athletic build, faded grey-blue sweatshirt, easy relaxed smile, facing camera. [fin commune]`
16. `portrait_003_me` — `[S1] A 30-year-old French woman interior architect, fair skin with sunburnt cheeks, oval face, light-brown hair in a tortoiseshell claw clip with fallen strands, red swollen green eyes, thin eyebrows, straight nose, wrinkled white linen shirt, devastated expression, facing camera. She shares the green eyes and nose of her brother. [fin commune]`
17. `portrait_003_maxime` — `[S1] A 34-year-old French man, fair skin, regular oval face with even features, short neat dark-brown hair with a side parting, dark-blue eyes, straight neat eyebrows, thin straight nose, clean shaven, slim athletic build, ironed navy polo shirt, polite reassuring and very composed expression, facing camera. [fin commune]`
18. `portrait_003_diane` — `[S1] A 31-year-old French woman, fair tanned skin, long face with a clenched jaw, honey-blonde hair in a half-undone loose braid, puffy light-blue eyes, blonde eyebrows, thin pointed nose, slim sporty build, heather-grey crew-neck sweatshirt, contained grief, face three-quarters to the left. [fin commune]`
19. `portrait_003_louise` — `[S1] A 30-year-old French woman of Spanish descent, light olive Mediterranean skin, round face with full cheeks, long thick wavy very dark brown hair, large warm brown eyes, thick arched eyebrows, short slightly upturned nose, curvy build, blue-and-white Breton striped top, several thin silver rings on a hand visible at the bottom edge, restless expression with moving eyes, facing camera. [fin commune]`
20. `portrait_003_gregoire` — `[S1] A 36-year-old French man surf school co-owner, weathered fair skin with sun wrinkles, massive square face, shaved head, squinting light-brown eyes, thick dark eyebrows, slightly crooked once-broken nose, short dark trimmed beard, stocky muscular build, black surf rash-guard collar under a fleece, hard suspicious look, facing camera. [fin commune]`

**#004**
21. `portrait_004_me` — `[S1] A 35-year-old French woman exhibition curator after a long night, fair skin, fine oval face and long neck, dark-brown hair in a loosened low chignon, dark-brown eyes with slightly smudged mascara, thin eyebrows, thin slightly hooked nose, black coat over a black evening dress with one strap visible, exhausted shocked expression, face three-quarters to the right. [fin commune]`
22. `portrait_004_camille` — `[S1] A 32-year-old French woman, fair skin, rounder face, long chestnut bob, dark-brown eyes, natural eyebrows, thin slightly hooked nose, camel sweater, worried expression, facing camera. She looks like the younger sister of a woman with the same eyes and nose. [fin commune]`
23. `portrait_004_sterne` — `[S1] A 61-year-old French art collector, fair tanned thin wrinkled skin, long aristocratic face with a strong chin, thick silver hair swept back, pale grey eyes, full grey eyebrows, long straight nose, clean shaven, tall and slim, tailored dark suit with an open-collar white shirt, courteous unreadable expression, facing camera. [fin commune]`
24. `portrait_004_enzo` — `[S1] A 23-year-old French man of Portuguese descent, light olive skin with faint acne marks on the cheeks, young round face, short black hair gelled upwards, dark-brown eyes, thin eyebrows, short wide nose, faint moustache fuzz, slim, white waiter shirt with an untied black bow tie, frightened expression, facing camera. [fin commune]`
25. `portrait_004_victor` — `[S1] A 47-year-old French lighting technician, olive skin, broad square face, curly salt-and-pepper hair with glasses pushed up on the head, brown eyes, bushy eyebrows, wide round nose, five-day salt-and-pepper stubble, heavy build, black technician t-shirt, irritated expression, face three-quarters to the left. [fin commune]`
26. `portrait_004_iris` — `[S1] A 34-year-old French-Japanese woman event host, fair neutral skin, oval face with high cheekbones, glossy straight black chin-length bob, almond-shaped dark-brown eyes with precise eyeliner, straight eyebrows, small thin nose, slim, neckline of a black sequin dress, thin drop earrings, a fading stage smile, facing camera. [fin commune]`
27. `portrait_004_helene` — `[S1] A 58-year-old French woman official, fair wrinkled skin, round face, short neat grey hair, blue eyes, thin grey eyebrows, round nose, midnight-blue skirt suit jacket, pearl stud earrings, official serious expression, facing camera. [fin commune]`

**#005**
28. `portrait_005_me` — `[S3] Newsroom staff directory photo with an off-white background. A 34-year-old French woman journalist of Italian descent, light olive skin, diamond-shaped face with marked cheekbones, shoulder-length wavy dark-brown hair, dark-brown eyes, thick defined eyebrows, straight nose with a slight bump, khaki rain jacket with the collar up, blank press lanyard, determined tired expression, facing camera. [fin commune]`
29. `portrait_005_gilles` — `[S1] A 54-year-old French local councillor, fair ruddy skin, round face with a slight double chin, thinning grey hair combed back with a receding hairline, brown eyes behind round tortoiseshell glasses, thin grey eyebrows, short nose, clean shaven, portly build, beige quilted sleeveless gilet over a light-blue shirt and tie, friendly small-town-official expression, facing camera. [fin commune]`
30. `portrait_005_thierry` — `[S1] A 61-year-old French quarry owner, fair weather-reddened skin with broken capillaries, massive broad face, short white brush-cut hair, small pale-blue eyes, thick white eyebrows, big flat nose, three-day white stubble, heavy build, dusty blue work jacket over a checked shirt, hostile stare, facing camera. [fin commune]`
31. `portrait_005_romain` — `[S1] A 37-year-old French man, fair skin, long oval face, short brown hair a bit longer on top, light-brown eyes with dark circles, medium eyebrows, straight nose, three-day brown stubble, slim build, grey zip fleece, weary tired-father expression, face three-quarters to the right. [fin commune]`
32. `portrait_005_agathe` — `[S1] A 49-year-old French newspaper editor-in-chief, fair skin, angular face with high cheekbones, short ash-silver-blonde pixie haircut, grey-green eyes, thin eyebrows, thin straight nose, slim, black blazer over a white shirt, reading glasses hanging on a cord, sharp busy expression, facing camera. [fin commune]`
33. `portrait_005_julien` — `[S1] A 29-year-old French heavy-machinery operator, fair tanned skin with a red neck, young square face, short brown hair flattened by a helmet, blue-green eyes, brown eyebrows, slightly flat nose, patchy shave, sturdy build, orange high-visibility jacket over a grey hoodie with no text, frightened expression, facing camera. [fin commune]`

**Méta**
34. `player_elise_a` — `[S4] A 38-year-old French woman detective, fair skin, oval face with broad cheekbones and fine expression lines, dark-blonde hair in a low ponytail, grey-blue eyes, medium natural eyebrows, straight nose, navy wool coat over a grey sweater, calm experienced expression, facing camera. [fin commune]`
35. `player_elise_b` — `[S4] A 36-year-old French woman detective of North African descent, olive skin, long face with a fine chin, black hair in a low bun, dark-brown eyes, thick eyebrows, long straight nose, dark trench coat over a black turtleneck, focused expression, facing camera. [fin commune]`
36. `player_vincent_a` — `[S4] A 40-year-old French man detective, fair skin, square face, short greying brown hair, brown eyes, thick straight eyebrows, straight slightly broad nose, three-day salt-and-pepper stubble, solid build, dark parka over a white shirt, steady grounded gaze, facing camera. [fin commune]`
37. `player_vincent_b` — `[S4] A 37-year-old French man detective of West African descent, dark brown skin, oval face, very short black hair, dark-brown eyes, neat eyebrows, broad nose, clean shaven, tall and slim, charcoal overcoat over a black sweater, calm authority, facing camera. [fin commune]`
38. `npc_lacaze` — `[S4] A 58-year-old French police commander, fair lined skin, long face with hollow cheeks, short grey hair, washed-out blue eyes behind half-moon reading glasses, bushy grey eyebrows, long slightly aquiline nose, grey moustache and otherwise clean shaven, lean slightly stooped build, white shirt with rolled-up sleeves and a loosened tie, tired but sharp expression, facing camera. [fin commune]`

---

## 5. Les 4 apparences du joueur

| Fichier | Personnage | Âge | Carnation | Signes distinctifs | Tenue (même famille pour les 4) |
|---|---|---|---|---|---|
| `player_elise_a` | Élise Morel · A | 38 | II claire | Blond foncé en queue basse, yeux gris-bleu, rides d'expression | Manteau de laine marine, pull gris |
| `player_elise_b` | Élise Morel · B | 36 | IV mate | Chignon noir bas, yeux marron foncé, sourcils épais | Trench sombre, col roulé noir |
| `player_vincent_a` | Vincent Delmas · A | 40 | II claire | Châtain grisonnant, barbe de 3 jours poivre et sel | Parka sombre, chemise blanche |
| `player_vincent_b` | Vincent Delmas · B | 37 | V–VI brun foncé | Cheveux très courts, rasé, grand | Manteau anthracite, pull noir |

- Les 4 tenues sont sombres et neutres (marine, anthracite, noir). Les plans de dos et d'épaule de la cinématique de recrutement fonctionnent ainsi pour les 4 sans retournage : il faut **un manteau sombre mi-long** dans tous les plans vidéo.
- Chaque apparence a aussi une version « tirage agrafé » (fiche d'agent, rendue en code) et une vignette 256 × 256 recadrée sur le visage (`player_<nom>_<a|b>_thumb.jpg`) pour la carte d'enquêteur.

## 6. Personnages avec une seconde photo d'archive

Fichier `archive_<case>_<contactId>.jpg`, 1024 × 1280. Style indiqué pour chacun. Cette photo est utilisée dans le dossier (fiche d'affaire, écran de chargement, rapport), jamais dans le téléphone.

| Personnage | Pourquoi | Seconde photo | Prompt (ajout au prompt du portrait, qui sert d'image de référence) |
|---|---|---|---|
| Alex Moreau · #001 | Avis de disparition | Photo d'identité administrative d'il y a 5 ans : plus jeune, cheveux plus courts, rasé | `Same man five years younger, official ID photo, plain white background, flat flash, shorter hair, clean shaven, neutral expression, slightly faded print look.` |
| Clémence Aubry · #002 | Avis de disparition | Photo de famille : cheveux encore châtains, souriante | `Same woman two years earlier with natural chestnut shoulder-length hair, smiling at a family dinner, warm indoor light, cropped to head and shoulders.` |
| Paul Castaing · #003 | Rapport (identification) | Photo de permis de conduire, 8 ans avant | `Same man eight years younger, driving licence photo, plain light background, harsh flash, shorter hair, serious expression.` |
| Solène Marchetti · #005 | Avis de disparition | Photo de famille, en extérieur avec la neige, visage seul (enfants hors cadre) | `Same woman outdoors in snowy mountains, wool beanie, laughing, cold daylight, cropped to head and shoulders, nobody else in frame.` |
| Adrien Sterne · #004 | Presse (collectionneur connu) | Photo de presse, soirée de vente 2019 | `Same man at an auction gala in 2019, black tie, press photographer flash, slightly from below, blurred warm background.` |
| Thierry Brassac · #005 | Article de L'Écho des Alpes | Photo de presse sur le site de la carrière | `Same man standing at a gravel quarry in daylight, hi-vis vest over his jacket, local newspaper photo style, squinting.` |
| Gilles Arnaud · #005 | Trombinoscope municipal | Photo officielle d'élu | `Same man in an official municipal portrait, navy suit and tie, tricolour-free plain background, soft studio light, polite smile.` |

Les deux suspects de #005 et le suspect de #004 qui ont une photo publique ne sont pas tous coupables : la seconde photo **ne désigne personne**.

## 7. Nomenclature finale

```
Art.xcassets/
  Portraits/  portrait_<NNN>_<contactId>.jpg      1024×1280 (4:5)     38 fichiers − 5 méta = 33
  Archives/   archive_<NNN>_<contactId>.jpg       1024×1280           7
  Avatars/    avatar_<NNN>_<contactId>.jpg        512×512 (1:1)       33 (dérivés : photo informelle, style S2, référence = portrait)
  Players/    player_<elise|vincent>_<a|b>.jpg        1024×1280        4
              player_<elise|vincent>_<a|b>_thumb.jpg  256×256          4
  NPC/        npc_lacaze.jpg                      1024×1280           1
```

- `<NNN>` = numéro d'affaire sur 3 chiffres (`001`…`005`).
- `<contactId>` = id du contact dans l'affaire, en minuscules sans accent, `me` pour le propriétaire du téléphone. Ids vérifiés :
  - #001 : `me` `sarah` `karim` `lucas` `emma` `ines` `tom`
  - #002 : `me` `anais` `mathilde` `yanis` `bastien` `raphael` `kader`
  - #003 : `me` `paul` `maxime` `diane` `louise` `gregoire`
  - #004 : `me` `camille` `sterne` `enzo` `victor` `iris` `helene`
  - #005 : `me` `gilles` `thierry` `romain` `agathe` `julien`
- **Recadrage**, appliqué à la main ou par script depuis le 1024 × 1536 généré :
  - yeux à 38 % du haut ;
  - axe du nez centré (±3 %) ;
  - sommet du crâne à 6–9 % du haut ;
  - épaules coupées à 90 % de la hauteur.
- **Traitements** : le tirage papier (bord blanc, désaturation −15 %, photocopie) est appliqué **en code**, pas dans les fichiers.
- **Correctif** aux documents précédents : dans `02_PORTRAITS_PHOTOS.md` et `README.md`, remplacer `c_<prénom>` par `<prénom>` dans les noms de fichiers, Julien Vasseur par **Vincent Delmas**, et RECRUE par **ENQUÊTEUR** comme rang de départ.
