# Ludo Lovers — Approved Visual Reference Baseline

**Status:** User-approved visual reference received on 2026-10-13.  
**Purpose:** This specification is the source of truth for implementing the board and app UI. The supplied reference image shows the brand system and 18 screen concepts. It is a visual target, not proof that every screen or interaction is already implemented.

## Non-negotiable design rules

- Preserve the supplied Ludo Lovers logo as the fixed brand asset. Do not redraw, recolor, or replace it unless explicitly requested.
- Preserve the palette below exactly. Use dark/near-black surfaces, gold borders/highlights, warm cream text, and restrained glow effects to match the reference.
- Preserve the visual direction: premium royal gaming, luminous gold trim, dark backgrounds, saturated player colors, rounded panels, clear hierarchy, and romantic details in Love Mode. Avoid turning the interface into a generic Material app or childish cartoon style.
- Keep the board recognizable as Ludo with four home quadrants, shared track, player home lanes, center finish, and clear token positions.
- The screenshot is a reference for appearance, not a coordinate specification. Do not guess final logical-cell-to-pixel mappings from the screenshot. The current local-match prototype may render the provisional route for development testing only; do not approve it for release or competitive play until a normalized 15×15 board layout has been checked against an explicitly reviewed coordinate map.
- Treat all screen mockups as target designs. Do not claim a screen is finished until it exists in the app and has been validated.

## Brand palette

| Token | Hex | Intended use |
| --- | --- | --- |
| Orange | `#FF8928` | Primary player color and primary action accents |
| Green | `#33FF28` | Player color, ready/success accents (use with contrast checks) |
| Blue | `#289EFF` | Player color and secondary information accents |
| Magenta | `#F428FF` | Player color, Love Mode and romantic highlights |
| Gold | `#FFD700` | Premium trim, active highlights, currency, headings |
| Red | `#FF3830` | Error/alert and player-related accents |
| Black | `#080B0B` | Main dark background and panels |
| Cream | `#FFF8E1` | Primary readable text and light surfaces |

Use the exact hex values as design tokens. Derive lighter/darker shades only as supporting shades; never substitute them for the canonical values.

## Visual language

- **Background:** near-black, subtle cinematic gradients and restrained colored light.
- **Panels:** dark surfaces with thin gold/bronze borders and rounded corners.
- **Primary button:** bright orange-to-gold appearance, readable dark text, rounded pill shape.
- **Secondary button:** dark fill, gold or blue outline as appropriate.
- **Love Mode:** magenta/pink accents and heart motifs without obscuring gameplay.
- **Typography:** gold display serif treatment for the Ludo Lovers brand/headlines; clean, high-legibility sans-serif for controls, labels, stats, and body copy. Exact font files are not yet locked.
- **Tokens:** glossy, dimensional, color-coded pawns with readable silhouettes; heart/romance variants must remain easy to distinguish.
- **Dice:** ivory/cream face, dark pips, warm gold light and subtle 3D depth.
- **Motion:** brief, tactile dice roll; cell-by-cell pawn movement with lift and landing shadow; optional subtle sparkle/heart effects. Provide reduced-motion settings and avoid excessive battery-intensive effects.
- **Accessibility:** ensure text/control contrast, readable sizes, clear active-turn indicators, and status cues that do not rely on color alone.

## Screen concepts in the supplied reference

1. Splash Screen
2. Onboarding
3. Sign In / Continue (guest, Google, email, phone)
4. Username Setup
5. Home Dashboard
6. Game Mode
7. Private Room
8. Friends
9. Game Board
10. Dice Roll
11. Match Result
12. Settings/Profile area shown in the reference
13. Customization
14. Wallet / My Coins
15. Achievements
16. Leaderboard
17. Settings
18. Love Mode Theme

The reference also includes shared UI elements: primary and secondary buttons, Love Mode button, navigation icons, player tokens, coin display, player profile cards, and status indicators. Keep the bottom navigation consistent with the concept: Home, Friends, central Play action, Feed/Community, Profile (the exact fourth tab label should be finalized before implementation).

## Board implementation contract

- Logical model: 52 shared track cells and six home-lane cells per player, as currently documented in the engine fixtures.
- Renderer grid: 15×15 logical board grid, responsive and square.
- Keep logical cell IDs separate from pixel coordinates.
- Maintain one reviewed mapping from each track/home-lane ID to a normalized board coordinate.
- Safe cells and each player's start cell must be verified against the approved board reference and chosen rules profile before enabling capture logic in rendered gameplay.
- Test route adjacency, wraparound, start positions, home-lane entry, exact finish, overshoot, safe cells, and touch hit-testing.
- Keep tokens, dice, and UI overlays in separate render layers so gameplay logic remains independent of painting.
- Current board painter is a visual prototype; current geometry contract validates layout completeness but does not yet prove exact visual alignment with this reference.

## Implementation status guardrail

Current repository work includes a board preview, a pure coordinate-layout model, a classic-board fixture, geometry checks, and a development-only local-match screen connected to the rules engine. The route still reports four diagonal transitions at indexes 4, 17, 30, and 43, so the gameplay-readiness gate correctly remains false. Final route/safe-cell approval, complete gameplay acceptance coverage, and device-level visual validation remain outstanding. The uploaded reference image is in the conversation; it has not yet been committed as a binary asset in the repository.
