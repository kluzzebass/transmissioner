# Roadmap

## Core Features (MVP+)

- [x] Multi-service configuration and selection.
- [x] Torrent list with status, progress, speeds, ETA, and error display.
- [x] Quick controls: start/pause, remove, remove + delete data, verify,
      reannounce.
- [x] Add torrent by magnet/URL.

## Session & Global Controls

- Session info display (version, default download dir).
- Session settings: speed limits, alternate limits schedule.
- Global bandwidth limits and per-direction limits.
- Encryption mode and peer limit settings.
- Blocklist enable/update.
- Port settings and port test.
- Free space lookup for a path.

## Per-Torrent Controls

- Queue order (move top/bottom, move up/down).
- Bandwidth priority per torrent.
- Set location / move data.
- Rename torrent.
- Set ratio limits and seeding options.
- File selection and priority.
- Labels / categories (if supported).

## Metadata & Details Views

- Trackers list, add/remove trackers.
- Files list with progress and priorities.
- Peers list and per-peer stats.
- Detailed error states and retry actions.
- Per-torrent stats and history.

## UX & Quality

- Search, sort, and filtering by status.
- Compact vs detailed view toggle.
- Keyboard shortcuts for common actions.
- Background refresh interval control.
- Onboarding / connection diagnostics.
- Offline / reconnect handling with clear state.

## Security & Distribution

- Keychain storage for credentials.
- TLS/HTTPS configuration hints and ATS exceptions UI.
- Developer ID signing + notarization pipeline.
- Homebrew cask packaging guide.
