# Installation — Wicked Warlock BG Companion

## Emplacement du client WoW TBC Anniversary

Dossier d'installation découvert sur cette machine :

```
C:\Program Files (x86)\World of Warcraft\_anniversary_
```

Répertoire cible des addons :

```
C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\
```

## Procédure d'installation

1. **Fermez WoW** si le jeu est lancé (recommandé, non bloquant).
2. Copiez le dossier `WickedWarlock/` (celui de ce dépôt) dans le
   répertoire `Interface\AddOns\` ci-dessus.
3. Vérifiez que le fichier `.toc` se trouve directement dans le dossier
   d'installation, sans dossier imbriqué :

   ```
   Interface\AddOns\WickedWarlock\WickedWarlock.toc
   Interface\AddOns\WickedWarlock\WickedWarlock.lua
   Interface\AddOns\WickedWarlock\README.md
   Interface\AddOns\WickedWarlock\tests\mock_wow_harness.lua
   ```

4. Lancez WoW. Sur l'écran de sélection de personnage, cliquez sur
   **AddOns** et cochez **Wicked Warlock BG Companion**.
5. Entrez dans un champ de bataille, puis tapez `/ww show` pour afficher
   le panneau.

## Commandes en jeu

- `/ww show` / `/ww hide` — affiche / masque le panneau
- `/ww intro` — emote + phrase d'accueil aléatoire
- `/ww start` — cri de ralliement aléatoire
- `/ww scan` / `/ww stats` — lit le tableau des scores BG et affiche un résumé
- `/ww tip` — conseil tactique basé sur le scoreboard
- `/ww lock` / `/ww unlock` — verrouille / déverrouille le déplacement du panneau
- `/ww autoon` / `/ww autooff` — rafraîchissement automatique du scoreboard (toutes les 15 s en BG)

## Version et compatibilité

- Version de l'addon : **2.0.0**
- `.toc` Interface : **20506** (build du client TBC Anniversary vérifié)
- Le panneau est déplaçable (glisser-déposer) et sa position est mémorisée.
- Les boutons de sorts sont des **boutons sécurisés** (clic utilisateur requis) :
  Fel Armor, Create Healthstone, Create Soulstone, castsequence.

## Sauvegarde

Avant d'installer sur une version existante de l'addon, copiez le dossier
`Interface\AddOns\WickedWarlock\` existant vers un emplacement de sauvegarde.
Aucun fichier existant n'est supprimé par ce dépôt : il ajoute le dossier
`WickedWarlock/` s'il est absent.
