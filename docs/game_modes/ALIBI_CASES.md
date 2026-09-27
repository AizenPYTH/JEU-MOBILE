# Mode ALIBI — les trois affaires de lancement

> **VÉRIFIER. CROISER. CONCLURE.**
> Une personne affirme avoir été à un endroit précis à une heure précise. Le joueur reçoit un mini-dossier, fouille
> **le téléphone de cette personne**, verse au dossier ce qui confirme ou contredit sa déclaration, puis répond
> **ALIBI CONFIRMÉ** ou **ALIBI CONTREDIT**. Une partie dure 3 à 6 minutes.

Fichiers :

| Affaire | JSON | Photos (requêtes du pipeline) |
|---|---|---|
| ALIBI #001 « LE DÎNER » | `ScreenshotKit/Sources/CaseLibrary/Resources/Cases/alibi_001.json` | `config/photo_queries/case_101.json` |
| ALIBI #002 « LE DERNIER MÉTRO » | `…/Cases/alibi_002.json` | `config/photo_queries/case_102.json` |
| ALIBI #003 « LE RENDEZ-VOUS » | `…/Cases/alibi_003.json` | `config/photo_queries/case_103.json` |

Répartition des réponses : **#001 contredit, #002 confirmé, #003 contredit**. Le joueur rencontre un alibi qui tient
dès sa deuxième partie : il n'apprend jamais que « c'est toujours contredit ».

Toutes les photos sont de vraies photos (lieux, objets, ambiances — jamais un personnage de l'affaire) ; seules les
captures d'écran restent dessinées par le téléphone (`PROCEDURAL`).

---

## ALIBI #001 — « LE DÎNER » · très simple · **ALIBI CONTREDIT**

- **Ville** : Nantes / Rezé (Trentemoult). Vendredi 6 novembre 2026. Téléphone remis le 7 à 10:15.
- **Durée** : 300 s (Enquêteur 540 · Détective 300 · Expert 210). Note du dossier : 1/5.
- **Contexte** : entre 21h45 et 22h30, l'ordinateur portable de l'Atelier des Antilles (atelier partagé de l'Île de
  Nantes) disparaît. Porte non forcée : seuls les membres ont le code.
- **Personne** : Mathis Lebreton, 31 ans, graphiste, membre de l'atelier (propriétaire du téléphone).
- **Déclaration** : « J'étais au dîner chez Coline, à Rezé, de 20h à minuit. Je n'ai pas quitté la table. »
  (créneau vérifié : 20:00 → 00:00).
- **Parcours minimal** : `e_left` → `e_calls` → `e_grue`.

| Preuve | Importance | Où | Ce qu'elle montre |
|---|---|---|---|
| `e_left` « Petit truc à régler » | clé | Messages › Coline, 21:40 et 21:42 | Il est sorti avec ses clés de voiture, « je reviens dans 30-40 min ». |
| `e_calls` Deux appels manqués | clé | Téléphone › Coline, 21:55 et 22:10 (un seul suffit) | On n'appelle pas quelqu'un assis à sa table. |
| `e_grue` La grue jaune, 22:07 | clé | Photos › analyser la photo de la grue | Prise par son iPhone, quai des Antilles (Île de Nantes), en plein créneau. |
| `e_track` Historique de position | complémentaire | Localisation › Moi | Trentemoult → pont des Trois-Continents 21:46 → quai des Antilles 22:01 → retour 22:37. |
| `e_portable` Le portable neuf | complémentaire | Messages › Yoann, 04/11 | Tous les membres savaient où il était rangé. |
| `f_table` La table du dîner, 20:41 | fausse piste | Photos | Vraie, mais elle ne couvre que le début de soirée. |
| `f_merci` « Merci d'être venus » | fausse piste | Messages › groupe « Dîner vendredi », 23:47 | Il était revenu ; un merci de fin de soirée ne couvre pas le milieu. |

- **Pourquoi c'est juste** : trois éléments évidents, dans trois apps différentes (Messages, Téléphone, Photos),
  disent la même chose sans jamais conclure à la place du joueur. Les fausses pistes sont vraies (il était bien là à
  20:41 et à 23:47) : c'est l'heure du milieu qui compte — la leçon du mode.
- **Pour une première partie** : le joueur n'a qu'à lire la conversation de l'hôte, ouvrir le journal d'appels et
  analyser la seule photo de nuit.

## ALIBI #002 — « LE DERNIER MÉTRO » · simple · **ALIBI CONFIRMÉ**

- **Ville** : Lille / Villeneuve-d'Ascq. Nuit du vendredi 23 au samedi 24 octobre 2026. Téléphone remis le 24 à 11:30.
- **Durée** : 300 s (540 · 300 · 210). Note du dossier : 2/5.
- **Contexte** : à 01h10, rue Masséna, Dylan Maes reçoit un coup de poing à la sortie d'un bar. Un témoin décrit un
  homme grand en veste kaki.
- **Personne** : Léo Vandamme, 28 ans, développeur, ancien colocataire de Dylan, qui lui doit 200 €.
- **Déclaration** : « J'ai quitté la rue Masséna vers minuit et quart. J'ai pris le dernier métro à
  République–Beaux-Arts. À 1h, j'étais chez moi, à Villeneuve-d'Ascq. » (créneau : 00:30 → 01:30).
- **Parcours minimal** : `e_rame` → `e_trajet`.

| Preuve | Importance | Où | Ce qu'elle montre |
|---|---|---|---|
| `e_rame` La rame de 00:39 | clé | Photos › analyser la photo du métro | Prise par son iPhone à 00:39, ligne 1, Gare Lille-Flandres. |
| `e_trajet` Historique de position | clé | Localisation › Moi | Masséna 00:21 → République 00:29 → Lille-Flandres 00:36 → Triolo 00:52 → domicile 00:58. |
| `e_coloc` « Le vélo dans l'entrée » | clé | Messages › Robin, 01:02 et 01:03 | Le colocataire l'entend rentrer : ce n'est pas seulement le téléphone qui est rentré. |
| `f_photo_rue` La rue Masséna à 01:14 | fausse piste | Photos (reçue dans le groupe) | Dans sa galerie mais prise par le Galaxy de Warren et reçue à 01:15. |
| `f_dette` Les 200 € de Dylan | fausse piste | Messages › Dylan, 23:52 et 23:55 | Un vrai différend, un vrai mobile — aucun lieu, aucune heure. |

- **Le piège** : le joueur voit une photo de la rue Masséna à 01:14 dans la galerie, un mobile, et Warren qui a donné
  son nom à la police. Tout paraît l'accabler ; les métadonnées et la position disent le contraire.
- **Pourquoi c'est juste** : la photo de la rame et l'historique se recoupent (même station, mêmes minutes), et le
  message du colocataire répond à l'objection « le téléphone a pu voyager sans lui ». Aucun élément ne le place rue
  Masséna après 00:21.

## ALIBI #003 — « LE RENDEZ-VOUS » · intermédiaire · **ALIBI CONTREDIT**

- **Ville** : Strasbourg (Neudorf, place Kléber). Jeudi 19 novembre 2026. Téléphone remis le 20 à 09:40.
- **Durée** : 360 s (648 · 360 · 252). Note du dossier : 3/5.
- **Contexte** : entre 14h et 15h, la voiture d'Aurélie Schmitt est rayée sur toute la longueur et un pneu crevé,
  place du Marché à Neudorf, devant chez elle.
- **Personne** : Élias Muller, 34 ans, ancien associé d'Aurélie (agence d'aménagement intérieur fermée en
  septembre, en mauvais termes).
- **Déclaration** : « Entre 14h et 15h, j'avais rendez-vous à la banque, place Kléber, pour mon prêt. Je n'ai pas mis
  les pieds à Neudorf. » (créneau : 14:00 → 15:00).
- **Parcours minimal** : `e_report` → `e_pluie`.

| Preuve | Importance | Où | Ce qu'elle montre |
|---|---|---|---|
| `e_report` Le rendez-vous reporté | clé | Mail du conseiller 11:20, sa réponse 11:31, ou l'évènement du 26 dans l'Agenda (un seul suffit) | Le rendez-vous de 14h n'a pas eu lieu, et il le savait. |
| `e_pluie` La pluie sur le pare-brise, 14:31 | clé | Photos › analyser (photo aussi envoyée à Jonas) | Prise par son iPhone depuis une voiture, place du Marché à Neudorf. |
| `e_parking` Le reçu de stationnement | clé | Mail « PayStat », 14:06 | Stationnement payé place du Marché de 14:06 à 15:06. |
| `e_aurelie` « Ne reviens pas devant chez moi » | complémentaire | Messages › Aurélie, 12/11 | Il connaissait l'endroit et y avait déjà été vu. |
| `f_agenda` RDV prêt à 14:00 | fausse piste | Agenda, 19/11 | L'évènement n'a jamais été supprimé : prévu ≠ fait. |
| `f_kleber` La place Kléber | fausse piste | Photos | Bien place Kléber… à 15:24, après les faits. |

- **Ce qui la rend intermédiaire** : rien ne contredit la déclaration dans une seule app. L'Agenda la confirme, la
  photo de Kléber semble la confirmer, et il écrit à sa mère que « ça s'est bien passé ». Il faut croiser l'Agenda
  avec les Mails (report, reçu de stationnement) et les métadonnées des Photos (lieu et heure).
- **Pourquoi c'est juste** : deux sources indépendantes le placent à Neudorf pendant le créneau (reçu de
  stationnement et photo géolocalisée), et une troisième montre que le rendez-vous avancé comme alibi n'existait
  plus. Le rappel en direct (« RDV prêt — reporté ») et le message de sa mère relancent la piste sans conclure.

---

## Écrire une nouvelle affaire ALIBI

Une affaire ALIBI est un fichier `Cases/alibi_NNN.json` (numéro `100 + N`), un `CaseFile` normal plus trois champs.
Écrire le fichier par un script de génération (comme les affaires principales), puis le valider.

### Champs obligatoires

- [ ] `schemaVersion: 1`, `id: "alibi_00N"`, `number: 10N`, `mode: "alibi"`.
- [ ] `title` en majuscules (« LE DÎNER »), `tagline` d'une ligne, `synopsis` en 2–3 courts paragraphes (le contexte,
      la personne, sa déclaration), `objective` du type « Vérifiez l'alibi de X : était-il … entre …h et …h ? ».
- [ ] `difficulty` 1…3, `durationSeconds` 240–360, `challengeDurations` = Enquêteur 1,8× · Détective 1× · Expert 0,7×.
- [ ] `phoneStartTime` : le moment où le téléphone est remis, **après** tout ce qu'il contient.
- [ ] `claim` : `person: "me"`, `statement` (entre guillemets « »), `place`, `from`, `to` (`to` après `from`).
- [ ] `minimalPath` : 2 à 4 ids de preuves, dont au moins 2 `key`, jamais une fausse piste.
- [ ] `devices` : **un seul** téléphone, celui de la personne (`contacts` avec `"id": "me"`, `"isOwner": true`),
      avec son propre `wallpaper` et `batteryPercent`.
- [ ] `suspects` : **exactement un**, `id: "s_<prénom>"`, `contact: "me"`, `role`, `statement` (= la déclaration),
      `verdict` (ce qui s'est vraiment passé, montré à la fin), `trap` (pourquoi le téléphone pouvait tromper).
- [ ] `evidence` : au moins 2 `key` sur cette personne (elles prouvent la réponse, dans au moins deux apps), 0–2
      `supporting`, au moins 1 `falseLead`. Chaque `refs` pointe vers un élément existant (`message:`, `call:`,
      `photo:`, `photoInfo:`, `track:`, `calendar:`, `note:`, `mail:`, `browser:`, `contact:`).
- [ ] `hints` : exactement `h1`, `h2`, `h3`, coûts 0, 5, 10. h1 « Commencez par vérifier les horaires. », h2
      « Comparez les traces du téléphone avec ce qu'il affirme. », h3 : où regarder, **jamais la réponse**.
- [ ] `solution` : `culprit` (= l'id du suspect), `alibiHolds` (`true` = confirmé, `false` = contredit),
      `headline`, `summary`, `reveal` (étapes horodatées liées aux preuves), `story`.
- [ ] `dossier` : `category: "VÉRIFICATION D'ALIBI"`, `city`, `place` (le lieu des faits), `subject` (nom de la
      personne), `subjectLabel: "DÉCLARANT"`, `subjectContact: "me"`, `rating`.
- [ ] Pas d'`introScene`.

### Règles de conception

1. **Une personne, une déclaration, une réponse nette.** Pas de réseau de suspects : 3 à 5 éléments vraiment utiles,
   quelques éléments secondaires, 1 ou 2 fausses pistes légères.
2. **Alterner les réponses.** Sur une série d'affaires, il faut des alibis qui tiennent (malgré une fausse piste qui
   inquiète) et des alibis contredits.
3. **Les fausses pistes sont vraies.** Une photo prise au bon endroit mais à la mauvaise heure, un agenda qui dit ce
   qui était prévu, une photo reçue d'un autre téléphone, un mobile sans lieu ni heure.
4. **Un téléphone banal.** La majorité des messages ne sont pas des preuves (viser plus de 70 %) ; quelques
   conversations, des appels, 6 à 12 photos, 1 à 3 évènements d'agenda, 1 ou 2 notes, une carte de 3 à 6 lieux
   (vraies coordonnées, `x`/`y` entre 0 et 1).
5. **Tout ce qui est stocké précède `phoneStartTime`** (messages, appels, photos, réception, positions, notes, mails,
   historique). Seuls l'agenda à venir et les évènements en direct peuvent être après.
6. **Validateur** : ids uniques dans tout le fichier ; un message dans une conversation vient de `me` ou d'un
   participant ; une photo envoyée dans un message existe déjà ; une photo reçue a `from` et `receivedAt` (après
   `takenAt`) ; une preuve clé ne dépend jamais d'un évènement en direct.
7. **Photos réelles uniquement** : lieux, objets, ambiances, jamais un personnage de l'affaire. Les preuves photo
   reposent sur les métadonnées (heure, lieu, appareil, reçue de…). Écrire `config/photo_queries/case_10N.json` (une
   entrée par photo : `REAL` avec `query`, `fallbacks`, `subject`, `night`, `evidence`, `shareWith` ; ou
   `PROCEDURAL` pour une capture d'écran). Une photo d'extérieur entre 21h et 6h est une photo de nuit.
8. **Vocabulaire** : Verser au dossier, Conclure, ALIBI CONFIRMÉ / ALIBI CONTREDIT. Aucun mot interdit (voir
   `LegacyWordsTests.swift` et `LocalizationTests.swift`). Villes françaises réelles, dates d'automne cohérentes
   (jour de la semaine, nuit, météo), SMS français plausibles, ton adulte, sans violence mise en avant.
9. **Vérifier** : `python3 -m json.tool` sur chaque fichier, puis `swift run CaseLint` et `swift test` (CI).
