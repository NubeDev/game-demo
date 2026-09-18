# File layout

Where Dart goes. The rule is simple: **a mini-game owns its folder and reaches into `shared/`;
nothing reaches into a game.**

```
lib/
├── main.dart              ← app entry, orientation lock, provider wiring
├── router.dart            ← every route in the app
│
├── games/                 ← one folder per mini-game, self-contained
│   └── balloon_pop/
│       ├── balloon_pop_game.dart      ← the FlameGame
│       ├── balloon_pop_screen.dart    ← the Flutter screen hosting it
│       ├── components/                ← balloon, pop burst, sky, progress stars
│       ├── assets.dart                ← every asset path this game uses, in one place
│       └── README.md                  ← what this game is and why it is built this way
│
├── shared/                ← reusable across games
│   ├── celebration.dart   ← the reward effect
│   ├── kid_sounds.dart    ← named cues over AudioController
│   ├── kid_haptics.dart   ← the physical answer to a success (never to a mistake)
│   ├── kid_palette.dart   ← the colour vocabulary
│   ├── kid_shapes.dart    ← shapes used in more than one place
│   ├── home_button.dart   ← the one home button
│   ├── parental_gate.dart ← the gate (the one place text is required)
│   ├── rive_character.dart← Rive component, data-binding driven
│   └── README.md          ← decision record for the shared pieces
│
├── menu/                  ← the kid-friendly home screen
│
└── …                      ← from the template, kept as-is:
    audio/  settings/  player_progress/  app_lifecycle/  style/
```

## Rules

**A game folder is self-contained.** Everything specific to Balloon Pop lives under
`games/balloon_pop/`. If two games need the same thing, it moves to `shared/` — it does not get
imported across game folders.

**`shared/` never imports from `games/`.** If a shared piece needs to know about a specific game,
the dependency is backwards; pass it in instead.

**Asset paths live in the game's `assets.dart`**, never inline as string literals in components.
Placeholder art becomes real art by editing one file. The same applies to shared assets.

**The template's folders stay where they are.** `audio/`, `settings/`, `player_progress/`,
`app_lifecycle/` and `style/` came from the Casual Games Toolkit and are wired into `main.dart`
through providers. Extend them; don't restructure them without a reason written down.

**Every route is registered in `router.dart`.** No ad-hoc `Navigator.push` to a screen that isn't
in the router, so the set of reachable destinations is readable in one file — which is also how we
check nothing bypasses the parental gate.

**A README sits beside code that made a decision.** `lib/shared/README.md` and each game's README
explain *why*, close to what they explain. Sessions and scopes are history; these are current
truth.

## Naming

- Files and folders `snake_case`; one public class per file, named to match.
- A game's Flame game class is `<Game>Game` (`BalloonPopGame`), its screen `<Game>Screen`.
- Components say what they are, not what they extend: `Balloon`, not `BalloonSpriteComponent`.
- Test files mirror the path under `test/`.
