# Ludo Lovers 🎲💖

**Ludo Lovers** is an Android-first social Ludo game concept combining classic board-game fun with friends, family, personalization, and a romance-inspired **Love Mode**.

> **Project status:** Planning and foundation stage. The brand direction and UI concept are defined; implementation is not yet complete.

## Vision

Create a polished, welcoming Ludo experience that feels like playing together in the same room—or enjoying a little date night—with an emphasis on smooth gameplay, social connection, customization, privacy, and transparent fair-play systems.

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

Tasks will be discussed by number so progress is easy to track:

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

**Step 03 — Project Setup:** prepare the Flutter project, folder structure, dependency list, environment configuration, Android settings, and Git workflow. Actual Flutter installation/building will happen when a computer is available.

---

This repository contains project planning and source code as they are added. It is not yet a released game.
