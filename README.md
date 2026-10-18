# Ludo Lovers 🎲💖

**Ludo Lovers** is an Android-first social Ludo game concept combining classic board-game fun with friends, family, personalization, and a romance-inspired **Love Mode**.

> **Project status (2026-10-18):** The Flutter foundation and board-backed local-match prototype are in place. The latest verified main-branch workflow for commit `63c72092e6715f86d8f2db98125db1d95618ffc6` passed formatting, dependency resolution, Flutter analysis, automated tests, Android debug APK build, and APK artifact upload. UI coverage now includes legal moves, capture/safe-cell/stacked-pawn scenarios, home-lane overshoot, winner/rematch, restart, stale taps, and the provisional-rules help flow. The route and safe-cell mapping remain **provisional**: the four diagonal corner connections now pass structural validation, but `isGameplayReady` remains false until the visual board topology is explicitly approved. See [the board-route acceptance checklist](docs/board-route-acceptance.md) before changing the route or enabling gameplay readiness.

## Vision

Create a polished, welcoming Ludo experience that feels like playing together in the same room—or enjoying a little date night—with an emphasis on smooth gameplay, social connection, customization, and fair rules.

## Product principles

- **Play first:** no intrusive ads during active gameplay.
- **Trust by design:** online game state and competitive outcomes are validated by the server.
- **Social by choice:** friend connections and communication controls remain in players' hands.
- **Smooth and accessible:** responsive animations, battery-conscious rendering, reduced-motion options, and readable UI.
- **Virtual-only economy:** coins have no real-world cash value and cannot be withdrawn or exchanged for cash.

## Planned features

- Classic Ludo, AI matches, local play, online multiplayer, and private rooms
- Friends, player profiles, online status, invitations, and rematches
- Love Mode with themed boards, tokens, emotes, and date-night experiences
- Customizable boards, dice, pawns, avatars, frames, and effects
- Match history, XP, achievements, leaderboards, and virtual coins
- Reconnection support for interrupted matches
- Safety controls: mute, block, report, and communication preferences
- Fairness verification based on a documented server-side commitment-and-reveal protocol

These are product goals, not claims that the features are already implemented.

## Brand palette

| Color | Hex |
| --- | --- |
| Orange | `#FF8928` |
| Green | `#33FF28` |
| Blue | `#289EFF` |
| Magenta | `#F428FF` |

| Gold | `#FFD700` |
| Red | `#FF3830` |
| Black background | `#080B0B` |
| Cream accent | `#FFF8E1` |

The existing Ludo Lovers logo is the fixed brand asset and should not be redesigned or recolored unless explicitly requested.

## Planned technology

- **Mobile app:** Flutter + Dart
- **Game rendering:** Flame
- **Social and application data:** Supabase (Auth, PostgreSQL, Storage, and Realtime where appropriate)
- **Online gameplay:** separate authoritative WebSocket game server
- **Version control:** Git + GitHub

Technology choices may be refined as the prototype is validated.

## Architecture principles

1. The UI presents state; it does not own game rules.
2. The client renders online matches but does not decide authoritative dice, legal moves, winners, or coin balances.
3. The server validates online commands and maintains versioned game state.
4. Game rules should be isolated and testable.
5. Supabase supports application data and social features—not the real-time 60-FPS game loop.
6. Exposed database tables must use appropriate Row Level Security (RLS) policies.
7. Never commit passwords, access tokens, private keys, service-role keys, or production secrets.

## Development roadmap

Tasks are tracked by step number so progress is easy to follow:

1. Brand identity and UI concept
2. Project setup and repository structure
3. Design system and navigation
4. Ludo rules and local game engine
5. Board rendering, pawn movement, and animation
6. First playable local/AI alpha
7. Supabase foundation and accounts
8. Authoritative game server and private rooms
9. Online multiplayer, reconnection, and fair-dice verification
10. Virtual coins, customization, and social features
11. Love Mode, progression, accessibility, testing, beta, and release

## Current implementation status

This repository now contains a foundation layer that is intentionally engineering-driven:

- The path-based local engine is the canonical rules engine; the old overlapping engine has been removed.
- Typed domain events, an immutable rules profile, centralized seat metadata, and engine/controller tests are in place.
- A provisional 52-cell track and five physical home-lane cells per player plus a separate center finish are represented in board fixtures and geometry tests. The route includes four documented diagonal corner connections and has **not** been visually approved for gameplay.
- The Board Preview and Local Game Lab include a board-backed local-match prototype for testing legal pawn selection, movement, captures, safe cells, finishing, and rematches. It is not release-approved gameplay.
- Recent route-acceptance tests cover each seat's track wrap, home-lane entry, exact finish, and overshoot behavior. These tests verify movement-model boundaries, not whether the physical route matches the intended board art.

## Initial alpha target

The first playable prototype should focus on a small, testable slice:

- Open the app and enter as a guest
- Reach the home screen
- Start a Classic match
- Play a complete local match against simple AI
- Roll dice and move pawns with clear legal-move feedback
- See the match result and return home

Online multiplayer, wallet logic, tournaments, voice, and advanced social systems should follow after the core local game is reliable.

## Planned repository structure

```text
ludo-lovers/
├── apps/
│   └── mobile/                 # Flutter Android app
├── services/
│   └── game_server/            # Authoritative online game server
├── supabase/
│   ├── migrations/             # Versioned database changes
│   └── seed.sql
├── docs/
│   ├── architecture/
│   ├── game-rules/
│   ├── api/
│   └── product/
└── README.md
```

Directories will be added as implementation begins.

## How we will work

- Track tasks by step number (for example, **Step 03**).
- Keep modules small and responsibilities clear.
- Add tests for game rules and state transitions.
- Document API and database decisions.
- Build locally first, then add online features in deliberate stages.

## Current next step

**Board reference reviewed — topology still needs a clearer source.** The supplied composite visual-design sheet is now accepted for visual direction: keep the fixed Ludo Lovers logo, dark luxury presentation with glowing gold accents, and Orange/Green/Blue/Magenta seats in the shown quadrants. However, its small embedded board image does not reliably identify all 52 physical track cells, exact start cells, home-lane transitions, or safe-cell IDs. A read-only cross-check against a public Flutter Ludo implementation found matching 52-cell shared-track coordinates, start indexes, and safe-cell IDs, including the same four diagonal corner transitions. However, its home-stretch/finish indexing differs from this app's prior six-cell lane model. The user has confirmed Option A: five coloured home-lane cells plus a separate centre finish, and the definition and tests now use that model. The four documented diagonal corner connections now pass structural validation; full board artwork, entry orientation, and safe-cell placement still require visual approval. Keep `ClassicLudoBoardCoordinateFactory.isGameplayReady == false` and the Local Game Lab warning visible. Details are recorded in [the route acceptance checklist](docs/board-route-acceptance.md). Selected home-lane model: five coloured cells per player plus a separate centre finish. Route corner connections and safe-cell placement still require visual review before gameplay readiness can be enabled. After visual topology approval, prioritize smooth pawn movement animation and a simple local AI opponent; board-backed widget tests already cover roll → legal pawn highlights → move → capture/bonus/turn → win/rematch.

## Current engineering decision records

- [Local game integration gate](docs/architecture/step-10-local-game-integration-gate.md) — route-approval prerequisites, engine-to-board integration order, Alpha 0.1 acceptance criteria, and device-validation limits.

- [Canonical game engine consolidation](docs/architecture/step-07-canonical-engine-consolidation-decision.md) — source of truth for engine migration, rules/profile requirements, immutable state, and the final rules boundary.
- [Step 07 validation plan](docs/architecture/step-07-edge-case-review-and-validation-plan.md) — known edge cases and engine exit criteria.
- [Step 08 board geometry and rendering](docs/architecture/step-08-board-geometry-and-rendering-plan.md) — route geometry, coordinate mapping, rendering separation, and brand constraints.
- [Classic board fixture](apps/mobile/lib/features/game/domain/board/classic_ludo_board_fixture.dart) — explicit canonical route data used to validate board invariants.

---

This repository contains project planning and source code as they are added. It is not yet a released game.
