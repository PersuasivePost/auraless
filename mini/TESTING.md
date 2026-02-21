# TESTING CHECKLIST

Short plan: this document lists manual and automated tests to validate the app's features and edge-cases before release. Follow each scenario, record PASS/FAIL and notes.

Quick start

- Device: Android (recommended: one Pixel or AOSP device, one Samsung/OEM device)
- Build: `flutter build apk` or run from IDE
- Test box names used in app: `settings` (Hive), Setup Wizard (`SetupWizard`), native channels (`NativeChannelService`), `MindfulDelayActivity` (Android activity)

How to use this file

- For each scenario follow steps and observe expected results. Mark: PASS / FAIL / OBSERVATION.
- Where helpful, include logs from Logcat (tag: `MINI` or the app package) and terminal output.

## 1. Basic navigation

- Goal: verify navigation and back behavior across main screens

Test cases

- Home button / launcher
  - Steps: From any screen tap the device Home button, re-open the app from recent apps or launcher.
  - Expect: App returns to previous state (unless OS reclaimed it). No crashes.
- Back button behavior
  - Steps: Navigate into Settings and SetupWizard pages, press Back.
  - Expect: Back navigates to previous page; `SetupWizard` uses page-prev behavior until root then exits.
- Swipe gestures (if implemented)
  - Steps: Attempt system/back gestures and in-app swipe gestures used by pages.
  - Expect: App responds (page-swipes move between pages) and system gestures still work.

Edge cases

- Press back during `MindfulDelayActivity` while timer running -> should be ignored until timer finished.

## 2. Terminal commands

- Goal: validate terminal command parser and command behaviors

Commands to verify (happy path + variations)

- `help` — lists commands
- `open <app name|package>` — opens app (test with exact name, partial name, package name)
- `ls` — lists installed apps
- `status` — shows system info (battery, ram, storage)
- `stats [today|yesterday|yyyy-mm-dd]` — shows usage stats; verify permission prompts when missing
- `lock <app> [minutes]` — blocks app using accessibility; test with and without minutes
- `unlock <app|package>` and `unlock` (list blocked apps)
- `grayscale on|off` — enable/disable grayscale; verify permission denied message when WRITE_SECURE_SETTINGS not granted
- `notifications` — show last notifications (requires notification-listener enabled)
- `essential add|remove|list <app>` — modify essentials list
- `alias add|remove <name> <command>` — alias management
- `battery` and `battery open` — check battery optimization and open settings
- `setup` — re-open SetupWizard

For each command

- Steps: run command, observe output text in terminal widget
- Expect: Correct success/failure messages; when settings required, app opens system settings

Edge cases

- Unknown command -> error message
- Partial match ambiguous -> should pick best match or show warning
- Long output scrolling: ensure terminal scrolls and performance remains smooth

## 3. Permission flows

- Goal: validate all permission granting flows and runtime revocation detection

Permissions to test

- Usage access (UsageStats)
  - Steps: attempt usage-dependent commands or `stats` -> if missing, request settings; grant; re-run
  - Expect: Permission prompt opens settings; after granted, usage data visible
- Accessibility service
  - Steps: try `lock` flow or open `SetupWizard` Accessibility page; enable service in system settings
  - Expect: Service can be enabled; when disabled later, app detects revocation on resume/periodic check and logs to terminal
- Notification listener
  - Steps: enable/disable and send notifications (see Notifications section)
  - Expect: Digest lists notifications when enabled; revocation logged
- Contacts permission (if asked)
  - Steps: On SetupWizard, grant contacts; revoke and resume app
  - Expect: Revocation detected and logged

Revocation detection tests

- Steps: grant permission, then revoke via Settings while app in background, return to app
- Expect: LifecycleProvider posts a warning to terminal and any affected features behave accordingly

## 4. Blocking flow / Mindful delay

- Goal: verify lock flow, `MindfulDelayActivity` behavior and resume after interruptions

Scenarios

- Lock and attempt open
  - Steps: run `lock <app>`; try to open locked app via launcher
  - Expect: `MindfulDelayActivity` launches and shows countdown; system incoming-call UI should appear above it when a call comes in
- Open app when timer finishes
  - Steps: wait until timer finishes, press "Open App"
  - Expect: target app launches
- Back to launcher while timer running
  - Steps: press "Back to Launcher" after timer finished
  - Expect: returns to launcher/home of this app
- Incoming call during delay (important)
  - Steps: while `MindfulDelayActivity` countdown is running, simulate an incoming call (use emulator or another device). Answer call.
  - Expect: when call answered, `MindfulDelayActivity` is paused; countdown paused; when call ends and activity resumes the countdown resumes from remaining time (or remains paused if configured). Verify timer resume.
- Pause/Resume by other interruptions (alarm, notification shade)
  - Steps: open notification shade or switch to other full-screen activity and return
  - Expect: countdown pauses and resumes correctly

Edge cases

- Call comes in and the system kills our activity (rare) — in this case, saved state should restore remaining time when user returns. Check `onSaveInstanceState` behavior.

## 5. Notification flow

- Goal: ensure notification listener collects digests and `notifications` command shows them

Steps

- Enable notification-listener in settings
- Send multiple notifications from different apps (use `adb shell am broadcast` or test app)
- Run `notifications` command and compare digest
- Revoke notification access and confirm app detects revocation and shows warning

Edge cases

- Large number of notifications -> confirm pagination/last-20 logic works
- Notification text null/large payloads handled gracefully

## 6. Grayscale (ADB WRITE_SECURE_SETTINGS)

- Goal: verify enable/disable and proper permission messaging

Steps

- Run `grayscale on` command
- If adb permission present, UI should indicate success and device should show grayscale
- If permission not present, message should instruct: `adb shell pm grant <pkg> android.permission.WRITE_SECURE_SETTINGS`
- Test `grayscale off`

Edge cases

- Device OEMs with different secure-settings behavior. Document failures and vendor notes.

## 7. App install / uninstall events

- Goal: package change receiver forwards installs/removals and `AppsProvider` reacts

Steps

- Install an app (adb install or Play Store)
- Observe app list in app (run `ls` or refresh view)
- Uninstall an app that is in favorites/blocked
- Expect: `AppsProvider` removes the package from Hive `favorites` and `blockedApps` boxes; terminal logs removal
- Update app (reinstall with same package) -> `PACKAGE_REPLACED` event observed

Edge cases

- Install/remove while app not running -> pending event stored in SharedPreferences should be forwarded on next app start
- Conflicting package names/instant apps

## 8. Reboot / persistence

- Goal: ensure settings and persistence survive reboot

Steps

- Set favorites/blocked/aliases in app
- Reboot device
- Launch app
- Expect: Hive boxes and settings preserved; BootReceiver no-op doesn't break operation

Edge cases

- Timed blocks (if implemented) should persist timestamps and re-evaluate after reboot

## 9. Battery optimization detection

- Goal: detect whether app is ignored by battery optimizations and be able to open settings

Steps

- Run `battery` command -> shows current state
- Run `battery open` -> opens the battery optimization settings page
- Test on API 23+ devices and note OEM behavior

Edge cases

- Some vendors provide per-app aggressive optimization not surfaced via `isIgnoringBatteryOptimizations` — note differences

## 10. Incoming call during delay (specific regression test)

- Goal: validate the change you requested: `MindfulDelayActivity` pauses timer on `onPause` and resumes on `onResume` after a phone call

Steps

1. From `lock <app>` cause `MindfulDelayActivity` to appear.
2. While countdown running, simulate incoming call and answer.
3. During call, confirm `MindfulDelayActivity` is paused (no UI visible). Optionally check logs.
4. End the call and return to the device/app.
5. Verify the countdown continues from the remaining time (or remains paused if configured).

Pass criteria

- Timer pauses while activity is paused and resumes on resume without jumping to finish early.
- Saved state restores remaining time if the system kills the activity while in-call.

## 11. Performance

- Goal: check app list load time and terminal responsiveness

Metrics

- App list: time to load `getInstalledApps()` and render list (target: < 1.5s on mid-range device). Measure via adb log timestamps or simple stopwatch.
- Terminal scrolling: ensure smooth scroll when large output (>200 lines)

Steps

- Populate terminal with 300 lines (script or repeated command)
- Try scroll up/down quickly
- Launch `ls` and measure time until first item visible

Edge cases

- Very large number of installed apps (500+) - memory usage and GC

## Automation hints

- Terminal commands can be scripted using Flutter Driver / integration_test or by directly calling the internal `CommandParser` in unit tests (mock `NativeChannelService`).
- Use `adb` for notifications and package install/uninstall simulation:
  - Install: `adb install -r app.apk`
  - Uninstall: `adb uninstall com.example.app`
  - Notification send (toy): `adb shell cmd notification post --user current --tag test --id 1 --ticker "t" --title "T" --text "body" com.example.app`
- Use `adb shell am start -a android.intent.action.CALL -d tel:123456789` to simulate incoming calls on some emulators (note: emulator telephony support varies).

## Recording results

- Add a short table per test in this document recording: Test, Device, OS, Steps, Result (PASS/FAIL), Notes, Logfile (path)

## Final smoke checklist (run before release)

- [ ] Launch app, SetupWizard does not reappear when `isSetupComplete` true
- [ ] Run `status`, `ls`, `help` commands
- [ ] Enable and then revoke each permission to validate lifecycle warnings
- [ ] Lock + incoming call test (timer pause/resume)
- [ ] Install/uninstall app test
- [ ] Battery check and open settings
- [ ] Grayscale on/off test (with and without WRITE_SECURE_SETTINGS)
- [ ] Terminal stress test (300 lines)

---

Notes & contact

- If you find device-specific behavior (OEM), capture vendor and OS version and attach logs.
- For unclear behaviors I can add targeted test harnesses or small instrumentation hooks in the app to gather timings or lifecycle traces.
