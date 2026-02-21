# mini — Features (MVP → v2.0)

Short description

- mini is a minimal, distraction-reducing Android launcher centered around a terminal-style home screen. It surfaces device status and a command-based workflow while keeping the app list hidden by default.

Contract

- Inputs: user typed commands, system events (app launches, time, accessibility), configuration stored in local Hive DB.
- Outputs: UI state (terminal, app list), system actions (open app, change settings), telemetry for optional digest.
- Success: quick, reliable terminal-first navigation with predictable minimalism.
- Error modes: clear formatted error messages; built‑ins cannot be overwritten.

## MVP (Minimum Viable Product)

Goal: Provide a usable terminal-first launcher that replaces the home screen with a retro terminal interface and a hidden, discoverable app list.

UI / Interaction

- Terminal home screen
  - Full-screen terminal UI on home.
  - Pure black background + green monospace text (classic matrix-style palette).
- Prompt + input
  - Persistent prompt line with editable input field.
  - Keyboard does not auto-open — user activates it manually (tap input or use a dedicated key).
  - Blinking cursor when input is focused.
- Scrollable history
  - Full vertical scrollback for prior output and commands.
  - Smooth scrolling; quick-scroll gestures supported.
- Empty Enter behavior
  - Pressing Enter on an empty input replays the last 5 commands (displayed in history) to encourage reuse.
- System info
  - Top or header line shows concise system info: time, battery %, connection status, Do Not Disturb indicator.
- Haptic feedback
  - Subtle haptic taps for key actions (enter command, reveal apps, long-press menu).

Commands & storage

- Configurable commands stored locally via Hive
  - Simple key/value command mapping persisted via Hive (fast, offline).
  - Commands can execute app opens, settings changes, or run built-in actions.
- Aliases
  - Users may create aliases that map to commands or sequences.
- Built-ins protected
  - A namespace for built-in commands (e.g., help, settings, reveal) that cannot be overwritten by user aliases or commands.
- Error formatting
  - Errors are shown with clear, colorized formatting (e.g., red text + timestamp), and a short suggestion where applicable.

App list & discovery

- App list is hidden by default to reduce clutter.
- Reveal gesture
  - A deliberate "6‑swipe" unlock gesture reveals the app list (assumption: six short swipes from the edge or across the screen in a quick sequence). This makes the drawer intentionally unobvious.
  - Note: if you prefer, this can be implemented as a six-finger swipe or six-tap sequence — implementation detail to confirm.
- App list layout
  - Alphabetical ordering by default.
  - Favorites section pinned to the top for quick access.
  - Search box accessible when list is revealed.
- Long-press app options
  - Long-press on an app entry opens a contextual menu: open, open in split, app info, add/remove favorite, uninstall (if allowed).
- Home button behavior
  - Pressing the device Home button always returns to the terminal home screen (when mini is the default Home/Launcher).

Settings & configuration UX

- Settings accessible via:
  - a built-in command (e.g., settings) typed at the prompt, or
  - long-press on the terminal background / app list header.
- Quick settings accessible from a small command palette or settings UI.
- Theme
  - Default pure black + green theme; theme toggles reserved for later versions.

Accessibility / edge cases

- Basic keyboard navigation supported (hardware keyboard).
- Graceful behavior if Hive DB is corrupt: fallback to safe defaults and an import/repair command.

Security & privacy

- Local-only command store by default (Hive); no cloud unless user opts in.
- Built-ins protected from overwriting to avoid accidental lockout.

MVP implementation notes

- Data model: commands/aliases table in Hive, favorites list, usage counters.
- Undo / recovery: a protected "safe mode" command to reset custom commands.
- Assumptions: "6-swipe" implemented as six quick swipes; clarify if alternate gesture semantics are preferred.

## v1.1 (Mindful features + accessibility / opt-ins)

Goal: Introduce behavior nudges and accessibility awareness, while giving the user moderate control and reporting.

Mindful delay (focus nudge)

- 30s mindful delay
  - A configurable 30-second delay that intercepts app launches for non-essential apps.
  - Default: enabled on first install as an opt-in.
- Configurable delay
  - User can set the delay length (e.g., off, 5s, 15s, 30s, 60s).
- Back disabled during delay
  - Back navigation (system back) is disabled while the delay countdown is active to prevent bypassing the nudge.
- Post-delay options
  - After countdown finishes, present clear options:
    - Launch app now
    - Return to terminal
    - Add app to essential whitelist (so it bypasses future delays)
    - Delay again (shorter or same)

Accessibility and detection

- Accessibility detection
  - Detect screen reader / TalkBack and adapt:
    - Announce countdown via TTS.
    - Optionally skip mindful delay if accessibility services require immediate access.
  - Respect accessibility needs first — never block critical flows for assistive tech users.

Controls & settings

- Monochrome toggle
  - Accessibility-friendly monochrome mode (green → white/gray on black) for high-contrast or color-vision concerns.
- Essential whitelist
  - UI to mark apps as essential (always bypass mindful delay).
- Notification digest & usage tracking
  - Optional weekly notification digest summarizing usage and time saved:
    - Tracks app launches, time spent in terminal, and how often the delay prevented quick launches.
  - Usage tracking is opt-in; data stored locally and optionally exportable.
- Post-install onboarding
  - Gentle onboarding to explain mindful delay and privacy.

Other UX

- Quick "snooze" for the delay.
- More granular per-app delay settings.

## v2.0 (Automation, scripting & integrations)

Goal: Turn mini into an automation and focus hub with scripting and workflow integrations for advanced users.

Multi-command scripting

- Scripted commands
  - Allow multi-command scripts that run sequentially (e.g., set brightness, open app, start timer).
  - Scripts saved in Hive, with optional human-readable descriptions.
- Safe sandbox for scripts
  - Restrict destructive operations; built-ins remain protected.
  - Confirm elevation for scripts that change system settings.

Focus profiles

- Named profiles
  - Profiles define which apps are essential, which triggers are active, UI density, and notification behavior.
  - Quickly switchable via command (e.g., profile work) or scheduled.

Integrations & automations

- n8n integration
  - Webhook / API hook to send usage events to a user’s n8n instance for custom workflows.
  - Option to trigger n8n flows on events: app launch, profile switch, delay block, script executed.
- Automation triggers
  - Local triggers to run scripts or switch profiles:
    - Time-of-day
    - Battery state (low/charging)
    - Wi‑Fi network connected
    - App open / close
    - Geofence (optional)
- Actions
  - Launch apps, run scripts, toggle profiles, send notification, call webhooks.

Reporting & analytics

- Weekly reports
  - Detailed weekly report summarizing:
    - App launches (counts/times)
    - Delay events prevented
    - Time saved
    - Top used commands and scripts
  - Exportable CSV / JSON for personal analysis.

Security

- OAuth / tokenized integration for remote n8n webhooks.
- Local-only telemetry by default; any remote sharing is opt-in.

## Setup wizard (6 pages)

Purpose: guided first-run setup to get users running quickly while explaining the core philosophy.

Page 1 — Welcome & Philosophy

- Short intro: why terminal-first, focus-first design.
- Two CTA buttons: Continue / Learn more.
- Toggle: choose default minimal theme (black+green) or monochrome accessibility palette.

Page 2 — Make mini your launcher

- Explain steps to set as default Home.
- Show a single button to open system chooser and instructions to set mini as the Home app.
- Explain Home button behavior.

Page 3 — Core interactions

- Demo (interactive or animated) showing:
  - Typing a command
  - Revealing app list with the 6-swipe gesture (tutorial + practice area)
  - Long-press for app options
- Practice step: user performs reveal gesture; success unlocks next page.

Page 4 — Mindful delay (opt-in)

- Explain the 30s delay concept and benefits.
- Controls: enable/disable, default delay length (30s default), essential whitelist example.
- Accessibility note with "detect and adapt" option (enable/disable adaptive behavior).

Page 5 — Privacy & permissions

- List required permissions and why (see Permissions section below).
- Consent toggles:
  - Usage tracking (on/off)
  - Weekly digest (on/off)
  - n8n/webhook sharing (off by default)
- Link to full privacy policy.

Page 6 — Finish & backup

- Option: import commands / aliases from file or sample templates.
- Option: enable encrypted backup to user-selected cloud (optional; not enabled by default).
- Quick checklist with shortcuts: how to open settings, how to add an alias, how to mark favorites.
- CTA: Done → land on terminal home.

## Required permissions and rationale

Note: Android permission model applies; some are normal, some runtime. All requests will include clear rationale in-app.

1. Set as default launcher

- Mechanism: ACTION_HOME chooser.
- Rationale: required for mini to act as home screen.

2. Query installed apps / Package visibility

- Permission(s): QUERY_ALL_PACKAGES (or use package visibility APIs, limit where possible).
- Rationale: build the app list and present long-press actions and favorites.

3. Usage Access (PACKAGE_USAGE_STATS)

- Rationale: optional—needed for accurate usage tracking, digest, and mindful delay heuristics. Explicit opt-in with OS settings link.

4. Accessibility service (optional)

- Rationale: to detect screen reader and provide enhanced support, and optionally to allow more reliable detection of on-screen events needed for automation triggers.
- Behavior: accessibility features are honored and used only to improve UX; user can opt-out.

5. Notifications (POST_NOTIFICATIONS on newer Android)

- Rationale: send countdown notifications, weekly digest, and automation alerts.

6. VIBRATE

- Rationale: haptic feedback for tactile UX.

7. Network / INTERNET (normal)

- Rationale: optional for n8n integration, webhook calls, and backups (opt-in).

8. External storage / file access (optional)

- Rationale: import/export commands and backups; use SAF (Storage Access Framework) where possible; avoid broad storage access.

9. Draw over other apps / SYSTEM_ALERT_WINDOW (avoid if possible)

- Rationale: not required for the launcher itself; flagged as sensitive—prefer Notifications for cross-app alerts. If required for certain automation overlays, obtain explicit consent and keep optional.

Privacy & safety

- Usage tracking and remote integrations are opt-in only.
- Local Hive DB is primary storage; backups/encryption are explicit user options.

## Implementation details & small API notes

- Storage: Hive boxes for commands, aliases, favorites, usage counters, profiles.
- Built‑in namespace: prefix built-ins with a reserved token (e.g., \_\_builtin:help).
- Error format: timestamped entries, red text + inline suggestion; retained in history with a built-in command to view detailed logs.
- Gesture detection: configurable sensitivity; fallback reveal (e.g., hold long-press on header) if gesture fails or for accessibility.
- Essential whitelist: per-app boolean; quick access in app long-press menu.

## Edge cases & design tradeoffs

- Empty-enter replay vs accidental re-run: confirm with small on-screen hint and allow disable.
- 6‑swipe discovery can be obscure for new users — onboarding includes practice page and a fallback reveal method.
- Accessibility always prioritized: mindful delay will skip or adapt where required by assistive tech.
- Permissions: Android 11+ package visibility is limited — prefer targeted queries and document implications.

## Next steps & low-risk additions

- Add sample command templates (open app, set ringer, start timer).
- Provide import/export buttons in setup finish.
- Add unit tests around command parsing and Hive migrations.

## Requirements coverage

- All items listed in the user's outline are included and mapped into the document:
  - MVP features: Done.
  - v1.1 features: Done.
  - v2.0 features: Done.
  - Setup wizard (6 pages): Done.
  - Required permissions + rationale: Done.

If you'd like, I can:

- commit this as `FEATURES.md` in the repo,
- or expand any section into UI wireframes, command schema, or a sample Hive schema and migration plan.

Which next step do you want me to take?
