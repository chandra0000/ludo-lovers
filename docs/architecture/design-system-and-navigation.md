# Ludo Lovers — Design System and Navigation
**Status:** Product specification / planned implementation  
**Roadmap:** Step 03.3  
**Visual source of truth:** User-uploaded Ludo Lovers Visual Design System reference image.  
**Brand rule:** Use the existing official Ludo Lovers logo exactly as supplied. Do not redraw, recolor, crop destructively, or replace it without explicit approval.

## 1. Design principles
- Follow the uploaded reference image for the premium dark gaming style, gold edging, vivid player colors, and romantic accents.
- Premium royal gaming with modern romance; polished, warm, social, and readable rather than childish.
- Keep familiar Ludo gameplay cues while making the board and interface original.
- Use motion to communicate actions and outcomes, not as constant decoration.
- Prioritize clear turn state, legal actions, network state, and accessible contrast.
- Keep the same palette across the board, navigation, cards, dialogs, and dashboard.
- Avoid intrusive ads during active gameplay.

## 2. Approved color palette from the uploaded reference
Use these exact hex values for the brand palette. Do not substitute approximate colors or invent alternate brand colors.

| Token | Hex | Intended use |
|---|---|---|
| brandOrange | #FF8928 | Primary buttons, highlights, orange player identity |
| playerGreen | #33FF28 | Green player identity and accents |
| playerBlue | #289EFF | Blue player identity and accents |
| brandMagenta | #F428FF | Magenta player identity and Love Mode accents |
| brandGold | #FFD700 | Premium borders, royal details, highlights |
| brandRed | #FF3830 | Red player identity and selected warnings |
| brandBlack | #080B0B | Main dark background/surfaces |
| brandCream | #FFF8E1 | Light text and dice surfaces where contrast permits |

The eight values above are transcribed from the uploaded reference image and are the approved palette. Use darker/lighter shades only as secondary UI treatments when required for contrast or state distinction; never replace the base palette colors. Keep long text in readable cream/neutral text rather than vivid green or magenta. Validate text/background contrast and never communicate state by color alone.

### Colour-token note
The hex codes above are the exact values supplied by the product owner, even where a value looks unusual for its semantic label (for example, the supplied Blue value is green-toned and Cream is orange-toned). Do not silently reinterpret or substitute them; if visual confirmation suggests a transcription error, ask before changing any value.

## 3. Typography
- Follow the reference's premium display-heading feel for branding, while using a readable Android-safe sans-serif for most interface text.
- Provisional hierarchy: Display (28–32sp, bold), Screen title (24sp, semibold), Section title (18–20sp, semibold), Body (14–16sp), Caption/metadata (12–13sp).
- Keep important game status at a comfortably readable size; avoid tiny text for dice results, room codes, timers, and turn indicators.
- Use sentence case for labels; reserve all caps for very short tags.
- Use tabular numerals for timers, room codes, coin counts, and statistics where supported.

## 4. Spacing, shape, and elevation
- Base spacing scale: 4, 8, 12, 16, 20, 24, 32.
- Minimum interactive target: aim for 48×48 logical pixels on Android.
- Buttons/cards: consistent corner-radius family (12, 16, 24); use pill shapes for compact chips or clear primary actions.
- Use restrained shadows and gold/orange edging inspired by the reference. Reserve stronger glow for key actions, selected states, dice, and celebratory effects.
- Respect safe areas, system bars, keyboard insets, and smaller Android screens.
- Avoid layout that relies on fixed pixel positions; use responsive constraints.

## 5. Component rules
### Primary button
- Gold/orange visual treatment inspired by the reference; use the locked palette tokens `brandOrange` (#FF8928) and `brandGold` (#FFD700); do not substitute other hex values.
- Use dark readable text only when contrast passes; otherwise use a tested light text treatment.
- Clear pressed, disabled, loading, and focus states.
- Only one dominant primary action per screen where practical.

### Secondary button
- Dark raised surface with a clear border; do not compete with the primary action.

### Cards
- Use `brandBlack` (#080B0B) or a restrained dark treatment, readable `brandCream` (#FFF8E1) only where contrast permits, and restrained borders.
- Interactive cards need pressed feedback and a visible selected state.

### Status chips
- Online, In Game, DND, Offline, Connected, Reconnecting, and Verified must include text or an icon, not color alone.

### Dialogs and bottom sheets
- Use for confirmation, critical choices, and contextual actions.
- Confirm purchases, leaving an active match, account deletion, and other destructive actions.
- Do not interrupt a live game with nonessential promotional dialogs.

### Inputs
- Persistent labels, validation messages, sensible keyboard types, and paste support for room codes.
- Never expose phone numbers or private account identifiers on public profiles by default.

## 6. Motion and game feedback
- Keep routine UI transitions brief and purposeful; provide reduced-motion alternatives.
- Dice roll and pawn movement can have tactile feedback and restrained effects.
- Pawn movement should visibly travel cell-by-cell with a subtle lift and a shadow under the current position; settle with a small landing bounce.
- Legal pawn destinations must be obvious. Do not rely on animation alone to communicate a capture, win, or turn change.
- Provide sound-independent feedback and a setting to reduce animation, vibration, and effects.
- Maintain a 60 FPS target on capable devices, with adaptive effects for lower-powered phones.

## 7. Navigation model
Use a four-item bottom navigation on primary app areas:
1. **Home** — Play Now, modes, online friends, Rejoin Game, recent activity.
2. **Friends** — requests, online friends, search by Ludo ID, invites, blocked users entry.
3. **Play** — central emphasized action that opens mode selection / quick start. It should not hide the current game or discard room state.
4. **Profile** — identity, stats, achievements, frames, account and privacy entry points.

Settings is reached from the profile menu and relevant screen menus, rather than adding a fifth bottom-navigation item. Events may be added later if usage supports it.

### Navigation behavior
- Preserve the selected tab and relevant scroll position when switching top-level tabs where practical.
- If a match is active, returning Home must show **Rejoin Game** and must not silently abandon the match.
- Back navigation from a live match opens a clear in-game menu/confirmation rather than immediately exiting.
- Room invitation links should route to the invitation/lobby when possible; if authentication is required, preserve the invitation through sign-in.
- Unknown, expired, or invalid invitation links should show a helpful recovery message.
- Handle Android system back, deep links, app resume, and authentication redirects consistently.

## 8. Screen map
### First-run and account
- Splash / brand
- Onboarding (skippable)
- Continue as Guest / Google / Email / Phone OTP
- Username setup and Ludo ID assignment
- Privacy and notification permission prompts only when contextually needed

### Main app
- Home
- Mode selection: Classic, Love Mode, Friends, AI, Private Room, Local Play; events later
- Match setup
- Private-room lobby and invite flow
- Friends and friend requests
- Player profile
- Own profile and settings
- Customization and inventory
- Notifications
- Safety/report/block flows

### Match flow
- Game board with player panels, turn indicator, dice, legal pawn selection, chat/emotes entry, connection status, and menu
- Reconnect/recovery state
- Match result with rematch/invite/share actions
- Dice fairness verification and roll history

## 9. Home screen hierarchy
1. Header: official logo/wordmark treatment, profile shortcut, virtual coin balance.
2. Primary **Play Now** action.
3. Mode shortcuts: Classic, Love Mode, Friends, Private Room, AI / Local Play as space permits.
4. **Rejoin Game** card when an eligible private-room match can be recovered.
5. Friends Online / pending invites.
6. Optional events or achievements section later; never let promotional content dominate the play action.

## 10. Game screen hierarchy
1. Player names/avatars and status, with the active player unmistakable.
2. Board large enough to tap pawns accurately.
3. Dice action and current roll state.
4. Legal move highlights and clear selection feedback.
5. Compact chat/emote access and connection indicator.
6. In-game menu with sound, reduced effects, report/block, and leave-match confirmation.

The client renders the board, but online game rules, dice outcomes, legal moves, winner determination, and coin settlement are controlled by the authoritative game server.

## 11. Profile and social UI
- Show avatar, username, public Ludo ID, level/XP, match statistics, achievements, equipped frame, and presence.
- Public profiles must not reveal phone number, email, or private account connections.
- Presence options: Online, In Game, DND, Offline; last-seen visibility is user-controlled.
- Expose Block, Mute, and Report through discoverable menus.
- Support text and icon labels so status is not communicated by color alone.

## 12. Accessibility and responsiveness
- Test on narrow, low-resolution, and larger Android screens.
- Support system text scaling without clipping critical actions.
- Use semantic labels for buttons and interactive game controls.
- Ensure the game does not communicate turns, captures, or errors through sound alone.
- Offer reduced motion and vibration controls.
- Validate contrast for all color combinations, especially player colors against the board and dark surfaces.
- Keep tap targets separated to reduce accidental pawn selection.

## 13. Flutter implementation guidance
- Create shared design tokens in `app/theme/`: colors, typography, spacing, shadows, radii.
- Build reusable widgets in `shared/widgets/`: primary/secondary buttons, cards, chips, loading/error states, avatar, coin balance, dialogs.
- Use Flutter widgets for app navigation and menus; use Flame for the board rendering and game effects.
- Keep screen UI separate from repositories and game rules. UI must not query Supabase directly.
- Keep board/game state in a testable domain model and expose state to the renderer through a controller/view-model.
- Store environment-specific endpoints/configuration outside source-controlled secrets. Never commit service-role keys or private credentials.
- Add golden/widget tests for shared components and navigation tests for major flows.

## 14. Acceptance checklist
- [ ] Existing official logo is used unchanged.
- [ ] All eight approved palette hex values match the uploaded reference exactly.
- [ ] Main navigation contains Home, Friends, Play, Profile.
- [ ] Primary and secondary actions have visible states and accessible tap targets.
- [ ] Active match can be recovered from Home when eligible.
- [ ] Invalid/expired room invitations show a useful message.
- [ ] Turn, legal-move, connection, and verification states are not color-only.
- [ ] Reduced-motion and sound-independent feedback are supported.
- [ ] Game rules and online outcomes are not implemented as UI-only logic.
- [ ] No secrets are committed to the repository.

## 15. Scope note
This document records the agreed design and navigation direction. It does not mean the Flutter application or screens have already been implemented. The palette values above are fixed; typography sizing and layout details will be validated in the actual app.
