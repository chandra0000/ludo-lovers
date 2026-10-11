# Step 05 — App Navigation and Shell

**Status:** Architecture and starter-code specification only. This document does not mean the Flutter application has been created, compiled, or tested.

## Goal

Create a stable navigation foundation for Ludo Lovers before adding real gameplay and backend features. The first shell should feel premium and welcoming, use the approved brand palette, and make the main destinations easy to reach.

## Navigation decisions

Use `go_router` for declarative navigation and a persistent bottom-navigation shell.

Primary destinations:
1. **Home** — Play Now, game modes, friends online, and Rejoin Game when a private game can be recovered.
2. **Friends** — friend requests, online friends, search, and invitations.
3. **Play** — emphasized central destination for game-mode selection. It is a destination, not a real match yet.
4. **Profile** — avatar/frame, Ludo ID, stats, achievements, and settings entry point.

The initial version should use placeholder screens for destinations that are not implemented. Do not fake online status, wallet balances, game invitations, or match state with production-looking claims. Clearly mark demo/sample data in development builds.

## Suggested files

```text
apps/mobile/lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── router.dart
├── features/
│   ├── home/presentation/screens/home_screen.dart
│   ├── friends/presentation/screens/friends_screen.dart
│   ├── game/presentation/screens/play_screen.dart
│   └── profile/presentation/screens/profile_screen.dart
└── shared/widgets/
    └── app_navigation_bar.dart
```

This is the target layout; create files as part of implementation. Keep the existing approved Ludo Lovers logo as a fixed asset and do not redesign it.

## Route map

| Route | Destination | Initial behavior |
|---|---|---|
| `/` | Home | Default landing screen |
| `/friends` | Friends | Placeholder list / empty state |
| `/play` | Play | Game-mode selection placeholder |
| `/profile` | Profile | Profile placeholder |
| `/settings` | Settings | Add when the settings feature begins |
| `/room/:roomCode` | Private room | Add when private-room flows begin |

Use named routes where practical. Deep links to rooms must be validated by the future room service; a route parameter alone must never grant access to a game.

## Navigation behavior

- Keep the bottom navigation visible on the four primary destinations.
- Preserve the selected destination after switching tabs.
- Tapping the central Play destination opens game-mode selection; it must not start a match without explicit mode/setup choices.
- Use a stack/push route for secondary pages such as settings, player profile, room lobby, and match results; those pages should not replace the primary navigation shell unless there is a deliberate full-screen game flow.
- The active tab needs a clear icon + label state, not color alone.
- Provide semantic labels for icons and adequate touch targets.
- Respect Android back behavior and avoid duplicate copies of the same primary page on the navigation stack.
- Game-board screens may use a full-screen route without the bottom bar.

## Starter-code outline

These snippets are a guide to implement in the app; they have not been compiled against a Flutter SDK.

### `app/router.dart`

Use a `StatefulShellRoute.indexedStack` with four branches for Home, Friends, Play, and Profile. Each branch should have a stable route name and use its corresponding feature screen. Use the same `AppShell` navigation widget for the four branches. Keep room and game routes outside the shell when those features are added.

### `app/app.dart`

Create a `MaterialApp.router` that:
- uses the project theme from `app/theme/app_theme.dart`;
- receives the router configuration;
- sets a consistent title such as `Ludo Lovers`;
- enables a debug banner only if the team explicitly wants it during development.

### `main.dart`

Initialize Flutter bindings and run the app. Do not initialize Supabase or any production service until Step 12 and environment configuration are implemented. Keep startup small and predictable.

### Shared shell widget

The shell should display the active branch and a custom bottom bar. Suggested labels are Home, Friends, Play, and Profile. The Play item can use a larger raised button or visual emphasis, but must remain accessible and must not obscure the other tabs.

## Screen-state requirements

Every initial screen should support:
- loading state where loading is applicable;
- useful empty state;
- error state for future data requests;
- safe-area handling on Android;
- responsive layout for small screens;
- text scaling and accessible contrast;
- a clear route back to the primary destinations.

For this navigation-only milestone, static placeholder content is acceptable. Do not add Supabase calls, matchmaking, wallet logic, or game rules to these screens.

## Design-system alignment

- Use the shared color, spacing, typography, and theme definitions from Step 04 rather than hard-coded colors in each screen.
- Keep the official logo unchanged.
- Use the brand palette consistently: orange `#FF8928`, green `#33FF28`, blue `#289EFF`, magenta `#F428FF`.
- Treat the palette as brand accents, not a requirement to fill every screen with saturated color. Use supporting neutral/dark surfaces for readability.
- Avoid unrelated gradients, random colors, and excessive glow/shadow effects.

## Acceptance checklist

- [ ] App launches to Home.
- [ ] All four primary destinations can be opened by tapping the bottom navigation.
- [ ] The selected tab is visibly and accessibly indicated.
- [ ] Android back behavior is sensible and does not create duplicate primary tabs.
- [ ] Secondary routes can be added without rebuilding the navigation model.
- [ ] No screen pretends that online services or real matches already exist.
- [ ] Theme values come from the shared design system.
- [ ] `flutter analyze` and relevant widget tests pass after actual implementation.
- [ ] Test on at least one small Android screen and one larger screen before marking the step complete.

## Out of scope

This step does not implement authentication, friends backend, chat, room invitations, game rendering, online multiplayer, coins, notifications, or the production settings flow. Those are later roadmap items.

## Next step

After the app shell is implemented and tested, proceed to **Step 06 — Ludo Game Rules**, defining exact rules and test cases before building the game engine.
