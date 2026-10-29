# Tests et diagnostic — Wicked Warlock BG Companion

## 1. Tests statiques (réalisés, aucun interprète requis)

| Test | Résultat | Preuve |
|---|---|---|
| Présence des fichiers attendus (`.toc`, `.lua`, README, harness) | PASS | `WickedWarlock/` contient les 4 fichiers |
| `.toc` directement à la racine du dossier `WickedWarlock/` | PASS | `WickedWarlock/WickedWarlock.toc` |
| `.toc` Interface build cohérent avec le client | PASS (après fix) | `20506` = build client Anniversary |
| Aucun secret / token / chemin personnel dans le code | PASS | revue du code source |
| Revue statique de la syntaxe Lua 5.1 | PASS (lecture) | aucune erreur de syntaxe évidente |

## 2. Harness simulé (`tests/mock_wow_harness.lua`)

Le harness requiert un **interpréteur Lua 5.1** (`lua5.1`).

**Blocage :** aucun interpréteur Lua n'est installé sur cette machine
(recherche effectuée sur `C:\`, `Program Files`, `Program Files (x86)`,
`Users`, `Git\usr\bin`). L'installation d'un logiciel système est exclue
sans autorisation. Le harness n'a donc pas pu être exécuté.

Critère d'acceptation concerné : *"Harness simulé exécuté si
l'interpréteur nécessaire est disponible"* → **non applicable
(interpréteur absent)**.

## 3. Vérification dans le véritable client WoW (à planifier)

Une fois l'addon installé (voir `INSTALL.md`) et une session de jeu
autorisée, vérifier :

1. **Chargement de l'addon** : aucune erreur rouge au lancement / entrée en BG.
2. **Affichage / masquage** : `/ww show` et `/ww hide`.
3. **Déplacement de la fenêtre** : glisser le panneau, la position persiste.
4. **Lecture du tableau des scores** : `/ww scan` affiche DMG/HEAL/Kills/Deaths.
5. **Données manquantes** : scan avant ouverture du scoreboard → message "No scoreboard rows yet" (pas d'erreur).
6. **Lignes humoristiques** : `/ww intro`, `/ww start`, `/ww tip` envoient une ligne (uniquement sur clic/commande, pas de spam).
7. **Boutons sécurisés** : Fel Armor / Healthstone / Soulstone (clic utilisateur, hors combat ou selon restrictions).
8. **Combat / hors combat** : pas d'erreur en combat.
9. **Absence d'erreurs répétitives** : aucun flood Lua.
10. **Pas de ralentissement manifeste** : l'auto-scan tourne toutes les 15 s maximum.

## 4. Capture des erreurs Lua en direct

WoW écrit les erreurs de chargement des addons dans :

```
C:\Program Files (x86)\World of Warcraft\_anniversary_\Logs\FrameXML.log
```

Une surveillance de ce fichier (et des rapports d'erreurs du collecteur
dedié, le cas échéant) permet de détecter les erreurs de Wicked Warlock
pendant une session de jeu. Voir `DIAGNOSTIC.md` pour le détail.

## 5. Résultat des tests exécutés

| Suite | Statut | Commentaire |
|---|---|---|
| Statique (fichiers, .toc, revue code) | PASS | vérifié sur l'environnement réel |
| Harness Lua (simulateur) | NON RÉALISABLE | pas d'interpréteur Lua 5.1 |
| Client WoW réel | À faire | en attente de session de jeu autorisée |

## 6. Retour arrière

Supprimer le dossier `Interface\AddOns\WickedWarlock\` ou le remplacer par
la sauvegarde effectuée avant l'installation. Puis relancer l'interface
(`/reload`) ou redémarrer le client.
