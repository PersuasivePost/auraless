# Minimalistic-mobile — AuraLess (minimal launcher)

This repository contains a minimal, privacy-minded Android launcher-style Flutter app (project directory: `mini/`) originally developed as "AuraLess" (previously DevLauncher). The app is terminal-first, focuses on productivity and minimal UI, integrates with Android native features, and uses Hive for local persistence.

This README lives at the repository root. The runnable Flutter app is located in the `mini/` folder — see the Quick Start below.

Key features

- Terminal-first command interface with built-in commands
- Contact alias system for quick dialing
- Theme support with System / Light / Dark modes via a `ThemeProvider`
- Native Android integrations via MethodChannel (contacts, open dialer, usage stats, blocked apps, grayscale)
- Setup wizard and a one-time setup flow
- Small, focused codebase intended for experimentation and learning
