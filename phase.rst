Complete Phase Planning — Terminal-First Minimalist Launcher
============================================================

PHASE 0: Research and Pre-Production
====================================

Task 0.1 — Install and Study Competitor Apps
--------------------------------------------

Duration: 2-3 Days

Download and install these launchers on your daily phone:

- minimalist phone
- Olauncher
- Niagara Launcher

Use each one as your default for a full day.

For EACH launcher, answer:

- What is the very first thing you see when you press the home button
- What information is displayed without interaction
- How are apps listed
- How many apps visible without scrolling
- Tap behavior
- Long press behavior
- Swipe behavior (left, right, up, down)
- Back button behavior
- Home button behavior
- How to access settings
- Search behavior
- Search performance
- App drawer architecture
- Notification handling
- Permissions requested
- Friction points
- Smooth interactions
- Missing features
- Non-technical usability

After using all three, write:

"What My Launcher Will Do Differently"

Focus on:

- Terminal-first interaction vs list-first
- Hidden app access vs visible lists
- Configurable command system vs fixed UI

---

Task 0.2 — Feature Specification Document
------------------------------------------

Duration: 1 Day

Create:

DevLauncher Feature Specification v1.0

Section 1 — MVP Features
~~~~~~~~~~~~~~~~~~~~~~~~

- The home screen is a full-screen terminal
- System info paragraph at top
- Updates on foreground
- Scrollable history
- Input field with prompt prefix
- Keyboard manual activation
- Blinking cursor
- Configurable commands (Hive)
- Aliases supported
- Built-ins protected
- Conflict detection
- Multiple aliases allowed
- Duplicate alias names rejected
- Error syntax formatting
- Empty enter shows last 5 commands
- App list hidden
- 6 consecutive right swipes required
- Swipe ratio logic
- Haptic feedback per swipe
- 200ms feedback on 6th swipe
- Swipe counter reset rules
- App list alphabetical
- Favorites section
- Long press app options
- Settings via command or long press
- Home button returns to terminal
- Pure black + green theme

Section 2 — V1.1 Features
~~~~~~~~~~~~~~~~~~~~~~~~~~

- 30s minimum mindful delay
- Configurable delay
- Back disabled during delay
- Post-delay options
- Accessibility detection
- Usage tracking
- Monochrome toggle
- Notification digest
- Essential whitelist

Section 3 — V2.0 Features
~~~~~~~~~~~~~~~~~~~~~~~~~~

- Multi-command scripting
- Focus profiles
- n8n integration
- Automation triggers
- Weekly reports

---

Task 0.3 — Design Every Screen
-------------------------------

Screen 1 — Terminal Home Screen
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

    [OK] DevLauncher v1.0.0
    [OK] Device: Samsung Galaxy S24
    [OK] Android: 15 | API: 35
    [OK] Kernel: 6.1.43
    [OK] Uptime: 4h 23m
    [OK] Battery: 67%
    [OK] RAM: 4.2 / 8.0 GB
    [OK] Storage: 87.3 / 128.0 GB
    [OK] Network: WiFi
    [OK] All systems operational

Colors:

- Background: #000000
- Primary: #00FF00
- Output: #00CC00
- Dim: #008800
- Accent: #00AA00
- Error: #FF4444

Screen 2 — Recent Commands Popup
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Floating list above input field.
Last 5 commands.
Dismiss on outside tap.

Screen 3 — Hidden App List
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Sections:

- FAVORITES
- ALL APPS

Plain text rows.
48dp row height.
No icons.

Screen 4 — Settings
~~~~~~~~~~~~~~~~~~~~

Categories:

- Terminal Configuration
- Digital Wellbeing
- Notifications
- Appearance
- Permissions
- About

Screen 5 — Mindful Delay
~~~~~~~~~~~~~~~~~~~~~~~~~

- Full black background
- App name large
- Countdown circle
- Back disabled
- Buttons after timer

Screen 6 — Setup Wizard
~~~~~~~~~~~~~~~~~~~~~~~~

Pages:

1. Welcome
2. Set Default
3. Usage Access
4. Accessibility
5. Notification Access
6. ADB Grayscale
7. Contacts
8. Complete

---

Task 0.4 — Development Setup
-----------------------------

Verify tools:

::

    flutter doctor
    flutter --version
    flutter devices

Create project:

::

    flutter create com.yourname.devlauncher

Folder structure:

::

    lib/
    ├── main.dart
    ├── app.dart
    ├── core/
    ├── features/
    ├── models/
    └── providers/

Dependencies:

- hive
- hive_flutter
- provider or riverpod
- google_fonts
- intl
- permission_handler

Android:

- minSdkVersion 26
- targetSdkVersion 34+
- QUERY_ALL_PACKAGES

Constants:

::

    background: #000000
    primaryGreen: #00FF00
    outputGreen: #00CC00
    dimGreen: #008800
    accentGreen: #00AA00
    errorRed: #FF4444

---

PHASE 1: Making It a Launcher
=============================

Task 1.1 — Register as Home Screen
-----------------------------------

Add second intent filter:

::

    <action android:name="android.intent.action.MAIN" />
    <category android:name="android.intent.category.HOME" />
    <category android:name="android.intent.category.DEFAULT" />

Test with home button.

---

Task 1.2 — Handle Home Button
------------------------------

Override:

- onNewIntent
- onBackPressed

Flutter side:
Pop to terminal.
Swallow back on terminal.

---

Task 1.3 — Lifecycle Handling
-----------------------------

Use WidgetsBindingObserver.

On resume:

- Reset swipe
- Refresh system info
- Refresh apps

---

Task 1.4 — Method Channels
---------------------------

Create:

- AppChannel.kt
- UsageStatsChannel.kt
- GrayscaleChannel.kt
- ContactsChannel.kt
- SystemInfoChannel.kt

Flutter wrapper:

::

    class NativeChannelService {
        Future<List<Map>> getInstalledApps()
        Future<void> launchApp(String packageName)
    }

---

PHASE 2: Terminal Screen
========================

Task 2.1 — System Info Panel
-----------------------------

Use:

- Build.MODEL
- BatteryManager
- ActivityManager
- StatFs

Return Map to Flutter.

---

Task 2.2 — Terminal History
----------------------------

Provider:

- history list
- commandHistory list
- scroll controller

Entry types:

- command
- output
- error

---

Task 2.3 — Terminal Input
--------------------------

- No autocorrect
- Prefix not editable
- Submit handler
- Up/down recall

---

Task 2.4 — Assemble Screen
---------------------------

Layout:

- SystemInfoPanel
- TerminalHistory
- TerminalInput

---

Task 2.5 — Recent Commands Popup
---------------------------------

OverlayEntry.
Last 5 commands.
Tap executes.

---

Task 2.6 — 6 Swipe Secret Gesture
----------------------------------

SecretSwipeDetector:

- swipeCount
- lastSwipeTime
- timeout 8s
- required 6

Logic:

- RIGHT increments
- LEFT/UP/DOWN reset
- Diagonal ignored

---

Task 2.7 — Command Parser
--------------------------

Commands:

- help
- open
- call
- search
- ls
- top
- stats
- status
- lock
- unlock
- focus
- grayscale
- alias
- settings
- clear

Error format:

::

    Invalid duration.
    Usage: lock <app> <minutes>
    Example: lock instagram 30

---

Task 2.8 — App List Screen
---------------------------

- Alphabetical
- Favorites section
- Long press options

---

Task 2.9 — Hive Persistence
----------------------------

Boxes:

- settings
- favorites
- blockedApps
- aliases
- userCommands
- terminalHistory
- notifications

---

Task 2.10 — Settings Access
----------------------------

Accessible via:

- settings command
- long press terminal

---

PHASE 3: Digital Detox Features
===============================

Permissions:

- PACKAGE_USAGE_STATS
- RECEIVE_BOOT_COMPLETED
- READ_CONTACTS
- VIBRATE

AccessibilityService:

- TYPE_WINDOW_STATE_CHANGED
- Block apps
- Start MindfulDelayActivity

MindfulDelayActivity:

- CountDownTimer
- Disable back
- Buttons after timer

UsageStats:

- UsageStatsManager
- Query INTERVAL_DAILY

Grayscale:

::

    adb shell pm grant com.yourname.devlauncher android.permission.WRITE_SECURE_SETTINGS

NotificationListenerService:

- Intercept
- Cancel non-essential
- Store for digest

---

PHASE 4: Setup Wizard
=====================

PageView based.
Check setupComplete flag.
Grant permissions sequentially.

---

PHASE 5: Edge Cases
===================

Handle:

- App install/uninstall
- Permission revocation
- Reboot persistence
- Battery optimization
- Incoming call during delay
- Daily drive testing

---

PHASE 6: Polish
===============

Add:

- Welcome message
- Session started line
- Refined error messages
- about command
- Final checklist

---

PHASE 7: Documentation
======================

README includes:

- Screenshots
- Architecture diagram
- Setup instructions
- Command reference
- Philosophy

---

Timeline
========

+---------+----------------------+---------------------------------------------+
| Phase   | Duration             | Milestone                                   |
+=========+======================+=============================================+
| Phase 0 | 3-5 days             | Research + setup                            |
+---------+----------------------+---------------------------------------------+
| Phase 1 | 2-3 days             | Launcher registered                         |
+---------+----------------------+---------------------------------------------+
| Phase 2 | 7-10 days            | Terminal fully functional                   |
+---------+----------------------+---------------------------------------------+
| Phase 3 | 7-10 days            | Blocking + delay + grayscale + notifications|
+---------+----------------------+---------------------------------------------+
| Phase 4 | 2-3 days             | Setup wizard complete                       |
+---------+----------------------+---------------------------------------------+
| Phase 5 | 3-4 days + 1 week    | Edge cases + optimization                   |
+---------+----------------------+---------------------------------------------+
| Phase 6 | 2-3 days             | Polish complete                             |
+---------+----------------------+---------------------------------------------+
| Phase 7 | 1-2 days             | Documentation + demo                        |
+---------+----------------------+---------------------------------------------+
| Total   | 6-9 weeks            | Complete launcher                           |
+---------+----------------------+---------------------------------------------+