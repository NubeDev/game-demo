# Shared — parental gate (scope)

- Date: 2026-09-17
- Status: shipped
- Session: [../../sessions/shared/kid-shell-and-first-game-session.md](../../sessions/shared/kid-shell-and-first-game-session.md)

## Why

Apple's Kids Category and Google Play Families both require that anything leading **out** of the
child's experience — settings that change app behaviour, external links, contact details,
purchases — sits behind a check a child cannot pass. This is not a formality: it is a review
requirement, and an app that fails it does not ship.

The mechanism works precisely because of the thing that shapes the rest of this app: **the child
cannot read**, and a five-year-old cannot sustain a deliberate 3-second hold on instruction they
cannot read. What is a minor speed bump for an adult is a real barrier for the player.

## What

- A reusable gate widget under `lib/shared/`, shown as a modal before any protected destination.
- **Hold-to-open**: a button the adult must press and hold for ~3 seconds, with a visible progress
  ring filling. Releasing early resets it.
- The instruction is **text** — deliberately. Text is the barrier.
- Cancel is always available and obvious; the child tapping around must be able to get out.
- Protects: the settings screen, and any future external link, purchase, or contact surface.
- A single entry point (e.g. `ParentalGate.guard(context, onPass:)`) so a future destination
  cannot accidentally skip it.

## Not this

- **No PIN, no password, no account.** That is state to store, forget, and reset — and storing one
  edges toward collecting data.
- No date-of-birth question, no "what year were you born" — that *is* personal data.
- No biometric check.
- Not a security boundary against a determined older child. It is a deliberate-action check, which
  is what the store programmes actually require.

## Kid-rules impact

- This is the **one place text is not just allowed but required** — it is the mechanism. Worth
  stating loudly in the code comment so a future session doesn't "fix" it by adding icons.
- The gate must never appear in front of a child during normal play. If it shows up mid-game,
  something is wired wrong.
- The failure mode when a child tries and fails must be **gentle** — the ring drains, nothing
  scolds, no sound of rejection.

## Open questions

- [x] Hold-to-open, or arithmetic? **Hold** — friendlier for adults, no localisation needed.
      Revisit if a tester's child gets through by copying a parent.
- [x] Exact hold duration — **3s** (`ParentalGate.holdDuration`).
- [x] Gate every time, or once per session? **Every time** — safer and simpler, and there is no
      session state to get wrong.
- [ ] Watch for: a child who has seen a parent do it copying the hold. Only a real child can
      answer this.

## Done when

An adult can reach settings in about three seconds, a child tapping the cog cannot, and no
protected destination in the app can be reached without passing through the gate.
