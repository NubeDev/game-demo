# Little Games — the whole app (scope)

- Date: 2026-09-17
- Status: agreed
- Sessions: all of [`../sessions/`](../sessions/)

This is the umbrella scope. Every other scope doc inherits its rules and narrows to one feature.
The binding, always-loaded version of these rules lives in [`../../CLAUDE.md`](../../CLAUDE.md) —
this doc is the reasoning behind them.

## Why

A five-year-old wants to play on a phone or tablet, and almost everything built for them is either
too hard, full of ads, or quietly harvesting data. We want a small collection of mini-games that a
child that age can open and play **with no adult sitting next to them**, and that a parent can hand
over without thinking about it.

Two constraints follow from the age, and they shape everything:

**They cannot read.** Not "reads slowly" — cannot. So no instruction can be written, no button can
be labelled, no menu can rely on a word. Everything is picture, sound, and motion.

**They are learning that trying is safe.** A "game over" at five does not create challenge, it
creates a child who stops trying. So there is nothing to lose.

## What

A single offline app, **Little Games** (`com.example.littlegames`), shipping on iOS and Android,
containing several small games reachable from one picture menu.

- **Built on** Flutter + Flame, from the official Casual Games Toolkit `endless_runner` template —
  keeping its app skeleton (router, settings, audio, player progress) and replacing its gameplay.
- **Animated characters and rewards** via `flame_rive` + `rive`, using the **0.14+ API**
  (`File.asset`, `artboard.defaultStateMachine()`, data binding through `ViewModelInstance`).
- **Landscape only**, on both platforms — a tablet held sideways in two hands is the posture we
  are designing for, and a fixed orientation means one layout to get right instead of two.
- **Fully offline.** No network calls of any kind.
- **One folder per game** under `lib/games/`, shared pieces under `lib/shared/`. See
  [`../FILE-LAYOUT.md`](../FILE-LAYOUT.md).

### The design rules, and why each one

| Rule | Why |
|---|---|
| No text needed to play; icons, pictures, voice and sound instead | The player cannot read. Text is allowed **only** in the parent area. |
| Touch targets ≥ 80×80 logical px, generously spaced | Five-year-old motor control is coarse and the finger covers the target. Small buttons produce mis-taps, which read to the child as the game ignoring them. |
| No losing, no game over, no failure timer | Failure at this age stops play rather than sharpening it. A wrong answer gets a gentle wobble and a soft sound, then they try again. |
| Heavy positive feedback — sound, bounce, confetti, stars | This is the entire reward loop. It is what makes them want the next turn. |
| Bright, friendly, calm; no flashing, nothing scary | Avoids startling, and avoids photosensitivity risk. |
| A big, obvious home button in every game | The child must always be able to get out without finding an adult. |

### The store and privacy rules, and why

Built to clear **Apple's Kids Category**, **Google Play Families**, and **COPPA**:

- **No ads, no tracking, no analytics, no crash reporting, no third-party SDK that collects data.**
  Under-13 apps in these programmes cannot use behavioural advertising or cross-app tracking at
  all, and the simplest way to be compliant is to have nothing that could.
- **No personal data collected.** Nothing is asked for, nothing is stored off-device. The only
  persisted state is game progress and settings, in local `shared_preferences`.
- **A parental gate** — hold a button for ~3 seconds, or a simple adult arithmetic question shown
  as text — protecting the settings screen and any external link. Both programmes require that a
  child cannot stumble into anything outside the app, and text-plus-sustained-input is the standard
  mechanism precisely because a pre-reader cannot pass it.

## Not this

- **No accounts, no profiles, no cloud save.** Progress is local and anonymous.
- **No leaderboards, no head-to-head, no chat, no user-generated content.** Nothing social.
- **No in-app purchases, no subscription, no "unlock the full version".** Not in this scope.
- **No Firebase, no analytics of any kind**, including "anonymous" usage counts.
- **No web or desktop release.** macOS is a development convenience (`flutter run -d macos`), not
  a shipping target.
- **No adaptive difficulty or assessment.** This is play, not a teaching tool that measures.
- **No portrait layout.** Landscape is fixed; see above.

## Kid-rules impact

The umbrella tensions, resolved once here so individual scopes don't re-litigate them:

- **Progress and scoring.** The template ships a score and level-complete flow. A visible *score*
  invites comparison and implies a low score; we keep a **count toward the next celebration**
  instead (e.g. balloons popped out of 10), shown as filling dots or stars, never a number, and it
  never resets downward or ends a game.
- **Sound.** Positive feedback is mostly audio, but the app may be opened anywhere. Sound must be
  mutable from the parent area, must respect the device silent switch, and no cue may be startling
  — no sudden loud stings, no low rumbles.
- **The settings screen is text.** That is allowed and intentional: it is behind the parental gate
  and its reader is an adult.
- **The template's "game over" and win dialogs must go.** They are the exact failure/victory framing
  the rules forbid. Replaced by a celebration that simply flows back into more play.

## Open questions

- [ ] Which mini-games follow Balloon Pop? Candidates in [`../vision/roadmap.md`](../vision/roadmap.md).
- [ ] Do we want a spoken voice cue ("pop the balloons!") as well as sound effects? Needs recorded
      audio and a per-language story; deferred until after the first game plays well.
- [ ] Real artwork and real Rive files — placeholder coloured shapes until then. What is the art
      pipeline, and who makes them?
- [ ] Is there a parent area beyond settings (e.g. "about", time limits)? Not now; revisit once
      more than one game ships.

## Done when

A five-year-old can be handed the device, open a game from the picture menu without being told
how, play it for several minutes, get back to the menu on their own, and never see a failure
state — and a parent can look at the app and find nothing that asks for data, shows an ad, or
leaves the app without passing a gate.
