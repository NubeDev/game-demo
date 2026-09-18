# Scope index

The ask, before the work. One row per scope doc. See [`../SCOPE-WRITTING.md`](../SCOPE-WRITTING.md)
for how to write one and [`../ABOUT-DOCS.md`](../ABOUT-DOCS.md) for where it sits.

## Project-wide

| Scope | Status | What |
|---|---|---|
| [little-games-scope.md](little-games-scope.md) | agreed | The whole app: who it is for, the rules it is built under, what it will and will not be |

## `setup/` — project, tooling, platform config

| Scope | Status | What |
|---|---|---|
| [setup/project-from-template-scope.md](setup/project-from-template-scope.md) | shipped | Stand the project up from the Casual Games Toolkit `endless_runner` template |
| [setup/landscape-and-platform-config-scope.md](setup/landscape-and-platform-config-scope.md) | partly done | Lock orientation to landscape, set icons/launch screens, strip desktop targets we don't ship |

## `shared/` — the reusable pieces under `lib/shared/`

| Scope | Status | What |
|---|---|---|
| [shared/home-screen-scope.md](shared/home-screen-scope.md) | shipped | Kid-friendly menu: big picture buttons, parent-gated settings |
| [shared/parental-gate-scope.md](shared/parental-gate-scope.md) | shipped | The hold-to-open gate protecting settings and any external link |
| [shared/celebration-and-sound-scope.md](shared/celebration-and-sound-scope.md) | shipped | Reward effect, sound helper, home button, Rive character component |

## `games/` — one per mini-game

| Scope | Status | What |
|---|---|---|
| [games/balloon-pop-scope.md](games/balloon-pop-scope.md) | shipped | First game: balloons float up, tap to pop, celebrate every 10 |
| [games/dress-the-dog-scope.md](games/dress-the-dog-scope.md) | proposed | Second game: dress a dog, toggle the weather, the dog reacts to what it is wearing |
