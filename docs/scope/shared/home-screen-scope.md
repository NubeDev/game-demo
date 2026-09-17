# Shared — kid-friendly home screen (scope)

- Date: 2026-09-17
- Status: shipped
- Session: [../../sessions/shared/kid-shell-and-first-game-session.md](../../sessions/shared/kid-shell-and-first-game-session.md)

## Why

The home screen is the only place a child has to make a decision, and they cannot read a word of
it. It has to answer "what can I play?" with pictures alone, and it has to be impossible to get
lost in. The template's main menu — a title, a Play button, a Settings link, all text — fails
every part of that.

It also has to hide the parent's door in plain sight: settings must be reachable by an adult and
effectively unreachable by the child.

## What

- A **picture menu**: one big button per mini-game, each a distinct colour and icon/illustration,
  no labels. Balloon Pop first; the remaining slots are visibly **"coming soon"** placeholders
  (greyed, muted, and non-tappable or gently wobbling when tapped) so the layout doesn't jump
  around as games are added.
- Buttons are **large** — far above the 80×80 minimum; on a landscape tablet each should be a
  comfortable palm-sized target — and widely spaced so a stray finger cannot hit two.
- Tapping a game button plays a friendly sound and animates into the game.
- A **small settings button** in a corner, visually quiet (a cog, adult-looking, not part of the
  colourful game row), behind the parental gate —
  [`parental-gate-scope.md`](parental-gate-scope.md).
- Optionally a Rive character on the menu that idles and reacts to taps, once
  [`celebration-and-sound-scope.md`](celebration-and-sound-scope.md) lands. **Not done** — the menu
  ships without one; revisit when real character art exists.

## Not this

- **No text anywhere on the child-facing part of this screen** — not even the app title. If we want
  branding, it is a logo image.
- No scrolling. Every game visible at once; when we outgrow one screen we redesign, we don't add a
  scrollbar a five-year-old has to discover.
- No "recently played", no sorting, no favourites. The menu is the same every time — predictability
  is the feature.
- No settings content on this screen; the cog leads to the existing settings screen.

## Kid-rules impact

- **The settings cog is the one thing a child might tap and shouldn't reach.** The parental gate is
  what makes that safe, so this screen cannot ship before the gate does.
- **"Coming soon" placeholders must not read as broken.** A dead button that does nothing teaches
  the child the screen is unreliable. They should respond — a wobble, a soft sound — just not
  navigate.
- The template's main menu is also where its audio/settings buttons live; make sure removing them
  doesn't strand the mute control somewhere a parent can't find.

## Open questions

- [x] Settings cog visible, or hidden behind a gesture? **Visible but gated** — conventional, and a
      parent can find it. Top-right, small, grey.
- [x] How many placeholder slots? **Two**, alongside the one real game. Three tiles fill a
      landscape row without looking sparse or crowded.
- [ ] Placeholder art for game buttons: flat coloured shapes with a simple icon, or does it need
      illustration to read as "a game" to a child? Shipped flat (a Material icon per tile) —
      **needs testing on a child** to see whether an icon reads as "a game I can play".
- [ ] Does a muted "coming soon" tile read as broken rather than not-yet? It wobbles and makes a
      sound when tapped, but a child may still just think it doesn't work.

## Done when

A child can look at the screen, tap the balloon picture, and be playing — without an adult saying
anything — and an adult can find and open settings, while the child cannot.
