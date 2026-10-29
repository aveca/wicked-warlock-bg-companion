# RAPPORT DE DIAGNOSTIC INITIAL — Wicked Warlock BG Companion
## Phase A — Inventaire et diagnostic

**Date :** 29/10/2026  
**Agent :** Nemotron (OpenCode)  
**Statut :** Diagnostic terminé — aucun blocage critique sauf l'absence d'interpréteur Lua (voir § Blocages)

---

## 1. Environnement hôte

| Élément | Valeur |
|---|---|
| OS | Microsoft Windows 11 Famille 10.0.26300 |
| Plateforme | win32 |
| Git | 2.53.0.windows.1 (`C:\Program Files\Git\cmd\git.exe`) |
| GitHub CLI (`gh`) | 2.103.3 — connecté au compte `aveca`, scopes `repo`, `gist`, protocole https, keyring |
| Git user | Factory Bot / factory@aveca.com |
| Lua / lua5.1 / luac / luajit | **NON installé** (introuvable sur PATH et sur C:\\) |
| Node.js | présent (`C:\Program Files\nodejs`) |
| Docker | présent |
| C:\factory | existe, n'est PAS un dépôt git |

## 2. Archive source — `WickedWarlock-addon-v2.2-mocktest.zip`

| Élément | Valeur |
|---|---|
| Chemin | `C:\Users\user\Downloads\WickedWarlock-addon-v2.2-mocktest.zip` |
| Taille | 9 526 octets |
| Date | 29/10/2026 05:04 |
| Extraction | `C:\Users\user\AppData\Local\Temp\opencode\wicked-diag\WickedWarlock\` |
| Intégrité | Extraction réussie, aucun fichier corrompu |

**Contenu de l'archive (tous présents) :**
- `WickedWarlock/WickedWarlock.toc` (253 octets)
- `WickedWarlock/WickedWarlock.lua` (17 928 octets)
- `WickedWarlock/README.md` (2 468 octets)
- `WickedWarlock/tests/mock_wow_harness.lua` (4 074 octets)

**Structure :** dossier racine `WickedWarlock/` contenant le `.toc` directement à la racine du dossier — structure correcte pour une installation `Interface/AddOns/WickedWarlock/`.

## 3. Client WoW identifié : TBC Anniversary

| Élément | Valeur |
|---|---|
| Dossier d'installation | `C:\Program Files (x86)\World of Warcraft\_anniversary_` |
| Flavor (`.flavor.info`) | `wow_anniversary` |
| Executable | `WowClassic.exe` (WoW non lancé) |
| Interface/AddOns | `...\Interface\AddOns\` |
| WTF | `...\WTF\` (Account / SavedVariables) |
| Logs | `...\Logs\` (FrameXML.log, General.log, Client.log, etc.) |

**WoW en cours d'exécution ?** NON (aucun processus `Wow.exe`, `Wow-64.exe`, `WowTBC.exe`). Aucun risque d'interruption de session.

**Interface build du client :** `20506` (confirmé par plusieurs addons TBC installés : Questie_TBC, RXPGuides_TBC, Casinobabe, CbDiag, GuideLime_TUGs_TBC, JunkManager déclarent tous `## Interface: 20506`).

**WickedWarlock déjà installé ?** NON. Le dossier `Interface\AddOns\` contient : Auctionator, AutoLoot, AutoRepair, AutoSellGray, Casinobabe, CbDiag, GatherMate2, GatherMate2_Data, GuideLime_TUGs_TBC, InfectionExport, JunkManager, LootTrackerTBC, Questie, QuestieDB, RestedXP-TomTom, Routes, SimpleDungeonMap, TBCGearExporter, TomTom, TradeSkillMaster, TradeSkillMaster_AppHelper, VendorPrice. Aucun dossier `WickedWarlock`.

**Comptes WTF détectés :** `103329567#1` (royaumes Dreamscythe, Nightslayer), `1192107334#1` (Nightslayer), `YACOV972` (Thunderstrike). Le compte actif du joueur n'a pas pu être déterminé sans lancer le jeu.

## 4. Analyse du code source (statique, sans exécution)

### `WickedWarlock.toc`
```
## Interface: 20505
## Title: Wicked Warlock BG Companion
## Notes: Hideable Warlock battleground dashboard with score monitoring, jokes and secure spell buttons.
## Author: OpenAI
## Version: 2.0.0
## SavedVariables: WickedWarlockDB
WickedWarlock.lua
```
- ⚠️ **Incompatibilité démontrée :** `Interface: 20505` alors que le client Anniversary est en build `20506`. L'addon sera marqué "out of date" et ne se chargera pas par défaut.
- Version affichée 2.0.0 alors que l'archive est nommée v2.2 et le README parle de "starter v1.0.0" — incohérence de versionnement à clarifier.

### `WickedWarlock.lua` (revue statique, Lua 5.1)
Le code est syntaxiquement cohérent avec Lua 5.1. Points notables :
- Défensif sur les API absentes : `if not GetNumBattlefieldScores or not GetBattlefieldScore then ...`, `if IsInInstance then ...`, `if SendChatMessage then SendChatMessage(...) end`, `if DoEmote then DoEmote(emote) end`, `if GetRealZoneText then ...`, `if UnitFactionGroup and UnitFactionGroup("player") then ...`.
- `math.randomseed((time and time() or 1) + ...)` : `time()` n'est pas un global standard WoW, mais l'expression est défensive (retombe sur `1` si `time` est nil).
- `GetBattlefieldScore(i)` déballé sur 10 valeurs (signature TBC attendue : name, killingBlows, honorableKills, deaths, honorGained, faction, race, className, damageDone, healingDone).
- Boutons sécurisés (`SecureActionButtonTemplate`, `type=macro`, `macrotext`) créés au chargement, pas pendant le combat — respecte les restrictions TBC.
- Aucun envoi de chat automatique : `SendChatMessage` n'est appelé que dans `announce()`, déclenché par clic bouton ou commande slash. ✓ pas de spam.
- Emoji dans les libellés de boutons ("😈 INTRO", "⚔ BG PEP TALK", etc.) : risque d'affichage sur les clients avec police limitée (mentionné dans le README), pas d'erreur Lua.

**Aucune erreur de syntaxe évidente détectée à la lecture.** Confirmation d'exécution impossible sans interpréteur Lua (voir blocages).

### `tests/mock_wow_harness.lua`
- Harness Lua 5.1, mocke les API WoW (CreateFrame, GetBattlefieldScore, SendChatMessage, etc.).
- Charge `WickedWarlock.lua` via `loadfile`, vérifie compilation, initialisation, slash command, scan, boutons sécurisés.
- **Nécessite `lua5.1`** — indisponible sur cette machine.

## 5. Baseline d'erreurs (FrameXML.log)

`...\Logs\FrameXML.log` (158 octets, 13/10/2026) :
```
10/13 18:19:21.361  AddOn [Guidelime] failure to load: missing
10/13 18:19:21.361  AddOn [GuideLime_TUGs_TBC] Failed to load missing dependency [Guidelime]
```
Ce sont des erreurs pré-existantes d'autres addons (Guidelime manquant), **aucune n'est liée à Wicked Warlock**. Ce log est un mécanisme de capture côté client pouvant être réutilisé (Phase F).

## 6. GitHub

| Élément | Valeur |
|---|---|
| Compte connecté | `aveca` (authentifié via keyring) |
| Scopes | `gist`, `read:org`, `repo`, `workflow` |
| Dépôts existants | 14 dépôts (sargagame, bot-wow, factory-control, factory-v3, Casinobabe, ai-factory, replaypilot, factory-e2e-staging, vision-agent, AcimCaisse, A, adaptive-automation, naming, trading-bot) |
| Dépôt WoW addon dédié | **INEXISTANT** — aucun dépôt ne correspond à Wicked Warlock |
| `C:\factory` | pas un dépôt git |

Conformément aux règles (ne pas mélanger Factory / Sargagame / BOT-WOW / Casinobabe), un **nouveau dépôt dédié** doit être créé pour l'addon.

## 7. Synthèse — État initial

| Critère | Statut |
|---|---|
| Archive identifiée et inspectée | ✅ Oui |
| Fichiers attendus présents | ✅ Oui (toc, lua, README, harness) |
| Intégrité de l'archive | ✅ OK |
| Client TBC Anniversary identifié | ✅ Oui (`_anniversary_`) |
| Interface build client | 20506 |
| `.toc` Interface compatible | ❌ Non (20505 vs 20506) → correction nécessaire |
| Addon déjà installé | ❌ Non |
| WoW lancé | ❌ Non (bon pour l'installation) |
| Lua 5.1 disponible | ❌ Non → harness non exécutable pour l'instant |
| GitHub CLI authentifié | ✅ Oui (`aveca`) |
| Dépôt GitHub dédié | ❌ À créer |
| Erreurs pré-existantes FrameXML | Guidelime uniquement (non liées) |

## 8. Blocages identifiés

1. **Aucun interpréteur Lua 5.1 installé.** Le harness `tests/mock_wow_harness.lua` ne peut pas être exécuté. L'installation d'un logiciel système est exclue sans autorisation. Critère d'acceptation "Harness simulé exécuté" marqué **non applicable (interpréteur absent)** jusqu'à résolution.
2. **`.toc` Interface 20505 ≠ client 20506** → l'addon ne se chargera pas par défaut sur le client. Correction ciblée prévue (passer à `20506` ou `20505, 20506`) avec sauvegarde de l'original.

## 9. Prochaine action concrète

1. Créer le rapport de diagnostic finalisé (ce document).
2. Corriger le `.toc` (Interface: 20506) avec sauvegarde de l'original.
3. Créer un dépôt GitHub dédié (`aveca/wicked-warlock-bg-companion`).
4. Créer la branche `feat/wicked-warlock-live-validation`, committer, pousser, ouvrir une PR.
5. Installer l'addon localement dans `Interface/AddOns/WickedWarlock/`.
6. Mettre en place la capture d'erreurs Lua (FrameXML.log + mécanisme dédié).
7. Poursuivre les phases B–I.

---

*Ce rapport sera versionné et intégré au rapport final (Phase I). Aucun secret ni token n'est inclus.*
