# Surf's Up

Koko the quokka sits on her surfboard out at sea. Swells roll in from behind her. **Tap as one lifts
her** and she pops up and rides it towards the beach. While she rides, **a tap is a hop**: shells on
the water are hers anyway, shells floating up in bubbles need a hop. Three waves and she glides up
the sand, where three friends are waiting for a party. Then it's the next beach: morning, midday,
sunset.

The first **Lantern Island** game. Spec: [`game-script/LANTERN_ISLAND_SPEC.md`](../../../game-script/LANTERN_ISLAND_SPEC.md) §8.
Scope: [`docs/scope/games/surfs-up-scope.md`](../../../docs/scope/games/surfs-up-scope.md).

## The one thing not to break

**Every trip reaches the beach.** The verb is *catch the moment*, and a moment can be missed. So
missing is taken out of the outcome (see `Surf` in `surf.dart`):

| The child... | What happens |
|---|---|
| taps while a swell is under Koko (`catchEarly`..`catchLate`, about 1.5 s) | she pops up and rides |
| taps too early | a paddle and a splash. Nothing lost, the swell still comes |
| lets a swell go by | she looks back. Another is coming |
| lets `helpAfterMisses` (2) go by | she catches the next one herself |

A child who never taps still rides every wave and reaches every party. Tests pin this, including
tapping every frame and a thousand random taps.

## Layout

```
surf.dart              the whole game as plain numbers — pure, tested without Flame
beaches.dart           the three times of day, and who waits on each beach
assets.dart            the one path (Koko without her leaning board)
surfs_up_game.dart     events → sounds, sparkles, haptics; screen layout
surfs_up_screen.dart   the whole screen is the control (minus the home band)
components/            sea (sky, island, swells, beach + friends), koko (board, spray),
                       shells, hud (wave dots, veil)
```

The cast lives in [`lib/shared/lantern_cast.dart`](../../shared/lantern_cast.dart), because every
Lantern Island game will use it.

## Things that look odd and are deliberate

- **Koko stays put on screen and the sea moves.** Everything is in units of screen height, measured
  from her (`screenX`).
- **`koko-surf.svg` is the approved Koko minus her leaning surfboard.** The game draws its own board
  under her feet.
- **The friends are drawn flipped**, to face Koko arriving from the left.
- **The progress dot fills on the catch, not at the end of the ride**, so the reward is tied to the
  tap that earned it.
- **The island with the lighthouse grows** with each wave. It is the horizon goal: the beach getting
  closer, for a child who can't read a bar.

## Not proven yet

Never run on a phone or tablet, and no sound heard. No voice yet: the lines the spec wants (counting
shells aloud, "Here it comes!") need the Gemini TTS pipeline and a key.
