# Wicked Warlock BG Companion (starter v1.0.0)

## Install
1. Close WoW.
2. Copy the `WickedWarlock` folder into:
   `World of Warcraft/_classic_/Interface/AddOns/`
   (Use the actual AddOns directory for your TBC Anniversary client.)
3. Start WoW and enable **Wicked Warlock BG Companion** on the character-select AddOns screen.
4. In game, type `/ww show`.

## Commands
- `/ww intro` — emote + randomized funny invitation.
- `/ww start` — randomized BG opener.
- `/ww heals` — healer-heavy composition joke.
- `/ww tanks` — tank-heavy composition joke.
- `/ww dps` — DPS-heavy composition joke.
- `/ww unknown` — generic line.
- `/ww scan` — read available enemy class rows from the battleground scoreboard, print a class summary and estimated role-capable counts, then say a related joke.
- `/ww stats` — print team totals and top damage/healing players from the currently available scoreboard, then say a performance-based line.

- `/ww show` / `/ww hide` — show/hide panel.

## Important limitations / safety
- The addon can **scan enemy class rows exposed by the TBC battleground scoreboard** (`GetNumBattlefieldScores` / `GetBattlefieldScore`) when the client has populated them. Results may be incomplete before the scoreboard updates; press Tab, wait, then scan again.
- TBC's standard scoreboard exposes fields such as killing blows, deaths, damage and healing when populated. The addon can report the current snapshot and identify leaders; it cannot infer exact real-time combat changes unless the scoreboard itself refreshes. Healer-capable and tank-capable counts remain estimates based on class, not factual role assignments.
- Chat is sent only after a button click or slash command. There is no automatic countdown spam.
- This starter does not cast buffs or create a Healthstone automatically. WoW protected actions require a secure user click; spell names and APIs differ by client/version. Use your normal secure macro for spells.
- The panel includes a draggable frame, composition and performance scoreboard buttons, and random English lines. If your client rejects a UI API or emoji glyph, remove the emoji from button labels; some legacy clients have limited UI/font support.
- The `.toc` interface number may need updating if your specific Anniversary client reports the addon as out of date. You can temporarily enable “Load out of date AddOns” to test, but the interface number should ultimately match the client build.
