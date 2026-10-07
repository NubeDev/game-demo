# Project guide for Claude

This repo is Lantern Island, a free, ad-free, safe educational game app for children aged 3–7.

- The full product and build spec is in LANTERN_ISLAND_SPEC.md. Read it before making changes.
- Approved character artwork (soft outline style) and the expressions sheet are in /assets.
- Characters: Koko (quokka, surfer girl, host), Biggy (calico cat), Luna (unicorn), Tobi (seal), Tiko (platypus), Pacho (capybara). Names are provisional; keep them in a single config so they are easy to change.
- Build on the existing games; do not rewrite working code without approval.
- Propose a plan and wait for approval before implementing each phase.

Hard rules (never break these):
- No ads, no in-app purchases, no third-party analytics, advertising or tracking SDKs.
- No personal data, no accounts for children, no location access. Progress stays on the device.
- No streaks, push notifications, pressure timers or progress that can be lost.
- Positive feedback only. Never punish mistakes.
- Parental gate for settings, parent content and anything that leaves the app.
- The app must work offline.
- Use Australian English spelling in all English user-facing text (colour, favourite, organise).
