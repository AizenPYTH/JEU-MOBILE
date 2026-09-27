import json, sys
OUT = sys.argv[1]
chapters = [
 {"id": "chapter_01", "number": 1, "title": "PREMIÈRE AFFECTATION", "status": "playable",
  "synopsis": "Premier soir au Bureau des Enquêtes Numériques. Le commandant Lacaze vous remet un téléphone sous scellé : Alex Moreau, vingt-six ans, a disparu à Marseille.",
  "summary": "Vous avez rendu votre premier rapport avant l'aube, et Lacaze l'a lu sans rien corriger. Au BEN, c'est une manière de dire bienvenue.",
  "summaryUnsolved": "Votre premier rapport désignait la mauvaise personne. Lacaze l'a classé sans un mot, puis vous a remis votre carte quand même.",
  "note": "Premier dossier rendu dans les temps. On continue. — B. L.",
  "steps": [
    {"id": "arrival", "kind": "scene", "scene": "S01-01", "title": "Arrivée au BEN"},
    {"id": "office312", "kind": "scene", "scene": "S01-01B", "title": "Bureau 312"},
    {"id": "case", "kind": "investigation", "caseID": "case_001", "title": "Le dernier message"},
    {"id": "return", "kind": "scene", "scene": "S01-02", "title": "Retour", "surprise": True},
    {"id": "result", "kind": "result", "title": "Fin du chapitre",
     "reward": {"items": [{"id": "office_card", "name": "Carte BEN", "provenance": "Remise par le Cdt. Lacaze, bureau 312"}],
                "unlocks": ["office_01"]}},
    {"id": "my_office", "kind": "scene", "scene": "S01-03", "title": "Mon bureau", "surprise": True},
    {"id": "office", "kind": "office", "title": "Mon bureau"},
  ]},
 {"id": "chapter_02", "number": 2, "title": "UNE AFFAIRE PLUS COMPLEXE", "status": "playable",
  "synopsis": "Des plans confidentiels ont quitté un cabinet d'architectes du 11ᵉ, et le code d'alarme d'une employée a servi à 22 h 31. Inès a déjà extrait son téléphone.",
  "summary": "Thomas Bellec avait ouvert l'Atelier Varin avec le code de Maëlle Rocher, et votre rapport l'a désigné. Il devait douze mille euros à Olivier Laurier ; le dossier de Montreuil en était le prix.",
  "summaryUnsolved": "Votre rapport désignait la mauvaise personne ; Inès a repris la corbeille du téléphone derrière vous. Thomas Bellec a tout reconnu devant Aubrac : douze mille euros de dette, effacés contre un dossier de concours.",
  "note": "Aubrac dit que vous écoutez. Venant de lui, c'est beaucoup. — B. L.",
  "steps": [
    {"id": "c02_openspace", "kind": "scene", "scene": "S02-01", "title": "Open space"},
    {"id": "c02_office312", "kind": "scene", "scene": "S02-02", "title": "Bureau 312"},
    {"id": "c02_case", "kind": "investigation", "caseID": "story_001", "title": "Le dossier Varin"},
    {"id": "c02_debrief", "kind": "scene", "scene": "S02-03", "title": "Salle d'audition"},
    {"id": "c02_result", "kind": "result", "title": "Fin du chapitre",
     "reward": {"items": [{"id": "office_frame", "name": "Esquisse encadrée",
                           "provenance": "Médiathèque de Montreuil, envoyée au BEN par l'Atelier Varin"}]}},
    {"id": "c02_archives", "kind": "scene", "scene": "S02-04", "title": "BEN-2019-114", "surprise": True},
  ]},
 {"id": "chapter_03", "number": 3, "title": "UNE ANOMALIE DANS UN ANCIEN DOSSIER", "status": "planned", "steps": [],
  "synopsis": "Un dossier classé en 2019, BEN-2019-114, refait surface dans une signature de mail. Colette retrouve le carton ; il y manque une extraction."},
 {"id": "chapter_04", "number": 4, "title": "UNE AFFAIRE QUI TOUCHE LE BEN", "status": "planned", "steps": [],
  "synopsis": "Une nouvelle affaire croise l'ancienne, et les registres du laboratoire montrent une erreur de procédure commise au BEN même."},
 {"id": "chapter_05", "number": 5, "title": "CE QUE LE BEN N'A JAMAIS DIT", "status": "planned", "steps": [],
  "synopsis": "Pourquoi Bernard Lacaze a-t-il classé BEN-2019-114 ? Face à sa propre signature, le commandant doit s'expliquer, et vous devez décider de ce que vous en faites."},
]
career = [{"rank": "enqueteur", "cases": 0}, {"rank": "inspecteur", "cases": 1, "chapter": 1},
          {"rank": "senior", "cases": 20, "chapter": 4}, {"rank": "experimente", "cases": 30, "chapter": 7}]
json.dump({"chapters": chapters, "career": career, "monthsPerChapter": 3}, open(OUT, "w"), ensure_ascii=False, indent=2)
