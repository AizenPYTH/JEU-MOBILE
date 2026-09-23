# Mise en place TestFlight sans Mac — pas à pas

Ce guide prépare tout ce qu'il faut pour que le workflow GitHub **« iOS – Build & TestFlight »**
compile, signe et envoie l'app sur TestFlight. Il n'y a rien à faire sur un Mac.

Compte environ 30 à 45 minutes la première fois. Tu fais toutes ces étapes une seule fois (sauf le
certificat et le profil, à renouveler chaque année).

**Ce que tu vas créer :**

| # | Élément | Où | Sert à |
|---|---|---|---|
| 1 | App ID (bundle ID) | developer.apple.com | Identifier l'app |
| 2 | App | appstoreconnect.apple.com | Recevoir les builds TestFlight |
| 3 | Clé API App Store Connect (.p8) | appstoreconnect.apple.com | Envoyer le build depuis GitHub |
| 4 | Certificat Apple Distribution (.p12) | developer.apple.com + terminal | Signer l'app |
| 5 | Profil de provisionnement App Store (.mobileprovision) | developer.apple.com | Autoriser cette app signée avec ce certificat |
| 6 | 6 secrets GitHub | github.com | Donner tout ça au workflow |

---

## 0. Le bundle ID

Bundle ID proposé : **`com.aizenpyth.screenshot`**

- Si tu utilises déjà un préfixe pour tes autres jeux (par ex. `com.monstudio.`), prends plutôt
  `com.monstudio.screenshot`.
- Il se définit à **un seul endroit** du code : `Configs/Screenshot.xcconfig`, ligne
  `PRODUCT_BUNDLE_IDENTIFIER = …`. Si tu en choisis un autre, dis-le-moi (ou modifie cette ligne).
- Le bundle ID ne peut plus être changé une fois l'app publiée. Le nom affiché sur l'App Store, lui,
  peut changer quand tu veux.

Dans la suite, remplace `com.aizenpyth.screenshot` par ton choix si besoin.

---

## 1. Créer l'App ID

1. Va sur <https://developer.apple.com/account> → **Certificates, IDs & Profiles** → **Identifiers**.
2. Clique sur le **+** bleu.
3. Choisis **App IDs** → **Continue** → type **App** → **Continue**.
4. Remplis :
   - **Description** : `SCREENSHOT`
   - **Bundle ID** : **Explicit**, `com.aizenpyth.screenshot`
   - **Capabilities** : ne coche rien de plus. *In-App Purchase* est déjà incluse par défaut. On
     ajoutera Game Center ou iCloud plus tard si besoin, en régénérant le profil.
5. **Continue** → **Register**.

---

## 2. Créer l'app dans App Store Connect

1. Va sur <https://appstoreconnect.apple.com> → **Apps** → **+** → **New App**.
2. Remplis :
   - **Platforms** : iOS
   - **Name** : un nom provisoire unique sur l'App Store, par ex. `SCREENSHOT (beta)`.
     Si le nom est déjà pris, essaie une variante. Tu pourras le changer avant la sortie.
   - **Primary Language** : French (ou English (U.S.)).
   - **Bundle ID** : sélectionne `SCREENSHOT - com.aizenpyth.screenshot` (créé à l'étape 1).
   - **SKU** : `screenshot-001` (référence interne, jamais visible).
   - **User Access** : Full Access.
3. **Create**.

---

## 3. Créer la clé API App Store Connect

1. Dans App Store Connect → **Users and Access** → onglet **Integrations** →
   **App Store Connect API** → **Team Keys**.
   (Si c'est la première fois, clique sur **Request Access** et accepte les conditions.)
2. Note l'**Issuer ID** affiché en haut de la page (format `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).
   → secret **`ASC_ISSUER_ID`**
3. Clique sur **+** (Generate API Key) :
   - **Name** : `GitHub Actions SCREENSHOT`
   - **Access** : **App Manager**. C'est suffisant pour envoyer des builds ; n'utilise pas Admin
     sans raison.
4. **Generate**. Dans la liste, note le **Key ID** (10 caractères). → secret **`ASC_KEY_ID`**
5. Clique sur **Download** pour récupérer `AuthKey_XXXXXXXXXX.p8`.
   ⚠️ **On ne peut le télécharger qu'une seule fois.** Garde-le dans un endroit sûr (gestionnaire de
   mots de passe).
6. Ouvre le fichier `.p8` avec un éditeur de texte. Tout son contenu, lignes
   `-----BEGIN PRIVATE KEY-----` et `-----END PRIVATE KEY-----` comprises, sera le secret
   **`ASC_KEY_P8`**.

---

## 4. Certificat de distribution (sans Mac)

> **Tu as déjà un certificat « Apple Distribution » en `.p12` avec son mot de passe** (par exemple
> d'un de tes jeux précédents) ? Réutilise-le : un même certificat signe toutes les apps de ton
> compte. Passe directement à l'étape 5 (profil), puis à l'étape 6 (base64). Apple limite le nombre
> de certificats de distribution par compte : n'en crée pas un nouveau si ce n'est pas nécessaire.

Sinon, on le crée avec `openssl`. Il te faut un terminal avec openssl, au choix :

- **GitHub Codespaces** (le plus simple, dans le navigateur) : sur la page du dépôt → bouton vert
  **Code** → onglet **Codespaces** → **Create codespace**. Un terminal s'ouvre en bas.
  ⚠️ Travaille dans `~/signing` (hors du dépôt) et **ne commite jamais** ces fichiers.
  Supprime le codespace à la fin.
- **Windows** : « Git Bash » (installé avec Git for Windows) contient openssl.
- **Linux** : n'importe quel terminal.

### 4a. Générer la clé privée et la demande de certificat (CSR)

```bash
mkdir -p ~/signing && cd ~/signing
openssl genrsa -out dist.key 2048
openssl req -new -key dist.key -out dist.csr \
  -subj "/emailAddress=TON_EMAIL_APPLE/CN=TON NOM/C=FR"
```

(Remplace `TON_EMAIL_APPLE` et `TON NOM`. Sur Git Bash Windows, si `-subj` pose problème, écris
`-subj "//emailAddress=…/CN=…/C=FR"` avec deux barres au début.)

Télécharge `dist.csr` sur ton ordinateur. Dans Codespaces : clic droit sur le fichier dans
l'explorateur → **Download**.

### 4b. Faire signer la demande par Apple

1. <https://developer.apple.com/account> → **Certificates** → **+**.
2. Choisis **Apple Distribution** → **Continue**.
3. Envoie `dist.csr` → **Continue** → **Download**. Tu obtiens `distribution.cer`.
4. Remets `distribution.cer` dans `~/signing` (dans Codespaces : glisser-déposer le fichier dans
   l'explorateur).

### 4c. Fabriquer le .p12 (certificat + clé privée)

```bash
cd ~/signing
openssl x509 -in distribution.cer -inform DER -out distribution.pem -outform PEM
openssl pkcs12 -export -inkey dist.key -in distribution.pem -out dist.p12 \
  -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1 \
  -passout pass:CHOISIS_UN_MOT_DE_PASSE
```

- Le mot de passe choisi deviendra le secret **`APPLE_DIST_CERT_PASSWORD`**.
- Les options `PBE-SHA1-3DES` / `sha1` sont **indispensables** : sans elles, OpenSSL 3 produit un
  .p12 que macOS refuse (« MAC verification failed »).
- Garde `dist.p12` et son mot de passe en lieu sûr : ce fichier contient ta clé de signature.

---

## 5. Profil de provisionnement App Store

1. <https://developer.apple.com/account> → **Profiles** → **+**.
2. Section **Distribution** → **App Store Connect** → **Continue**.
3. **App ID** : `SCREENSHOT (com.aizenpyth.screenshot)` → **Continue**.
4. Choisis le certificat Apple Distribution (celui de l'étape 4, ou ton certificat existant) →
   **Continue**.
5. **Provisioning Profile Name** : `Screenshot App Store`. Le workflow lit le nom lui-même, donc un autre
   nom fonctionne aussi.
6. **Generate** → **Download**. Tu obtiens `Screenshot_App_Store.mobileprovision`.

Le profil expire en même temps que le certificat, au bout d'un an. Il faudra alors refaire les
étapes 4 et 5 puis mettre à jour les secrets.

---

## 6. Encoder les fichiers en base64

Les secrets GitHub ne contiennent que du texte : on encode les deux fichiers binaires.

**Linux / Codespaces / Git Bash :**

```bash
base64 -w0 dist.p12 > dist.p12.b64
base64 -w0 Screenshot_App_Store.mobileprovision > profile.b64
```

(Si `-w0` n'est pas reconnu, utilise `base64 dist.p12 | tr -d '\n' > dist.p12.b64`.)

**Windows PowerShell :**

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\chemin\dist.p12")) | Set-Content dist.p12.b64
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\chemin\Screenshot_App_Store.mobileprovision")) | Set-Content profile.b64
```

Ouvre chaque fichier `.b64` et copie son contenu (une seule longue ligne).

---

## 7. Ajouter les secrets dans GitHub

Sur GitHub : dépôt **jeu-mobile** → **Settings** → **Secrets and variables** → **Actions** →
onglet **Secrets** → **New repository secret**. Crée ces 6 secrets (noms exacts, en majuscules) :

| Nom du secret | Valeur |
|---|---|
| `APPLE_DIST_CERT_P12_BASE64` | contenu de `dist.p12.b64` |
| `APPLE_DIST_CERT_PASSWORD` | mot de passe choisi à l'étape 4c (ou celui de ton .p12 existant) |
| `APPLE_PROFILE_BASE64` | contenu de `profile.b64` |
| `ASC_KEY_ID` | Key ID de la clé API (étape 3) |
| `ASC_ISSUER_ID` | Issuer ID (étape 3) |
| `ASC_KEY_P8` | contenu complet du fichier `AuthKey_XXXXXXXXXX.p8` |

L'identifiant d'équipe (Team ID) n'est pas nécessaire : le workflow le lit dans le profil.

**Variables facultatives** (même page, onglet **Variables**) :

| Nom | Quand l'utiliser |
|---|---|
| `BUILD_NUMBER_OFFSET` | Si TestFlight refuse un numéro de build déjà utilisé : mets par ex. `100` |
| `XCODE_VERSION` | Pour forcer une version d'Xcode, par ex. `16.4` (sinon : la plus récente du runner) |
| `MACOS_RUNNER` | Pour changer de machine macOS, par ex. `macos-26` (défaut : `macos-15`) |

Ensuite, **supprime les fichiers de signature** du codespace ou de ton PC. Garde uniquement une copie
de `dist.p12`, de son mot de passe et du `.p8` dans ton gestionnaire de mots de passe.

---

## 8. Branche à utiliser

Le jeu actuel est sur la branche **`claude/busy-hopper-5dgev5`**. La branche `main` contient encore
l'ancien prototype : **ne lance pas le build depuis `main`** tant qu'elle n'a pas été mise à jour
(fusion de la branche de travail, par une PR que tu valides).

Plus tard, pour que chaque PR vers `main` produise automatiquement un build TestFlight : fusionne la
branche de travail dans `main`, puis GitHub → dépôt → **Settings** → **General** → **Default branch**
→ ⇄ → `main` → **Update**.

## 9. Lancer le build

1. GitHub → onglet **Actions** → **iOS – Build & TestFlight** → **Run workflow**.
   Choisis la branche **`claude/busy-hopper-5dgev5`**, puis **Run workflow**.
2. Durée : environ 15 à 30 minutes. Étapes : tests → vérification de la clé API et de l'app dans
   App Store Connect → archive Release signée → export `.ipa` → contrôle de l'IPA (bundle ID, version,
   numéro de build, signature) → envoi → **attente que App Store Connect liste le build**.
   Le run n'est vert que si Apple a réellement reçu le build ; sinon il est rouge avec la raison.
   Sans les secrets, le même workflow s'arrête après une **archive non signée** : utile pour vérifier
   que tout compile en Release (le résumé du run affiche bundle ID, version, numéro de build,
   présence du manifeste de confidentialité).
3. Le résumé du run affiche le numéro de build envoyé (par ex. `3.1`). Tu peux aussi télécharger
   l'`.ipa` dans la section **Artifacts**.

**Numéros de build** : le workflow utilise `<numéro du run>.<tentative>`, par ex. `12.1`, puis `12.2`
si tu relances ce run, puis `13.1`. Ils augmentent toujours et ne se répètent jamais, donc TestFlight
les accepte tous. La version affichée (`0.2.0`) se change dans `Configs/Screenshot.xcconfig`
(`MARKETING_VERSION`).

---

## 10. Installer sur ton iPhone

1. App Store Connect → ton app → **TestFlight**. Le build apparaît « Processing » pendant 5 à
   30 minutes.
2. La conformité export (chiffrement) est déjà réglée dans l'app (`ITSAppUsesNonExemptEncryption = NO`).
   Aucune question ne devrait donc t'être posée. Le manifeste de confidentialité
   (`Screenshot/PrivacyInfo.xcprivacy` : aucun suivi, aucune donnée collectée, `UserDefaults` pour
   les réglages du jeu) est inclus dans l'app.
3. **Internal Testing** → **+** → crée un groupe `Équipe` → ajoute-toi comme testeur. Active
   **Automatic distribution** pour recevoir chaque nouveau build automatiquement.
4. Sur l'iPhone : installe l'app **TestFlight**, connecte-toi avec le même compte Apple, puis
   installe **SCREENSHOT**.

---

## Dépannage

| Message | Cause probable / solution |
|---|---|
| `Missing secrets: …` (avertissement) | Un secret est absent ou mal nommé : le workflow compile seulement pour le simulateur. |
| `MAC verification failed` / `security: SecKeychainItemImport` | .p12 créé sans les options `PBE-SHA1-3DES` (étape 4c), ou mauvais mot de passe. |
| `The provisioning profile is for 'X' but the app bundle id is 'Y'` | Le profil n'est pas pour le bon App ID : corrige le profil ou `Configs/Screenshot.xcconfig`. |
| `No signing certificate "iOS Distribution" found` / `doesn't include signing certificate` | Le profil a été généré avec un autre certificat que celui du .p12 : régénère le profil (étape 5) en cochant le bon certificat. |
| `The bundle version must be higher than the previously uploaded version` | Ajoute la variable `BUILD_NUMBER_OFFSET` (par ex. `100`). |
| `401 NOT_AUTHORIZED` à l'étape « Check the App Store Connect API key » (ou `Authentication failed`) | Apple refuse la clé API : `ASC_KEY_ID` doit être le **Key ID** de la clé (10 caractères), `ASC_ISSUER_ID` l'**Issuer ID** affiché au-dessus de la liste des clés d'équipe (pas le Team ID), `ASC_KEY_P8` le contenu **complet** du fichier `.p8`. La clé ne doit pas être révoquée. En cas de doute, crée une nouvelle clé (Team Key, rôle App Manager) et remplace les trois secrets. |
| `App Store Connect has no app with the bundle ID com.aizenpyth.screenshot` | L'app n'existe pas encore dans App Store Connect (ou avec un autre bundle ID) : étape 2. |
| `Build … never appeared in App Store Connect` / `FAILED` / `INVALID` | Apple a refusé le build : regarde l'e-mail reçu par le titulaire du compte (code ITMS-xxxxx) et copie-le-moi. |
| `ITMS-90683` / `ITMS-91053` (clé Info.plist ou raison d'API manquante) | Copie-moi le mail d'Apple : il faut compléter `Screenshot/PrivacyInfo.xcprivacy` ou l'Info.plist. |
| `altool` introuvable ou refusé | Apple a changé l'outil d'envoi : copie-moi le log, je bascule l'envoi sur `xcodebuild -exportArchive` (destination `upload`). |
| Refus lié au SDK (« built with iOS xx SDK ») | Apple exige un Xcode récent : mets `MACOS_RUNNER` = `macos-26` et/ou `XCODE_VERSION`. |

En cas d'échec, copie-moi les ~30 dernières lignes du log de l'étape en rouge.
