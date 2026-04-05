# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.x.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in DFIR Simulator, please report it responsibly:

1. **Do not** open a public GitHub issue
2. Email the maintainer or use GitHub's private vulnerability reporting
3. Include steps to reproduce the vulnerability
4. Allow reasonable time for a fix before public disclosure

## Security Considerations

### Game Architecture
- **No network calls at runtime**: All threat intelligence data is pre-synced and bundled offline
- **No user data collection**: The game does not transmit any player data
- **Local saves only**: Save files are stored locally in `user://saves/` using Godot's sandboxed filesystem
- **No external API keys**: No secrets are required to build or run the game

### CI/CD Security
- **Semgrep SAST**: Static analysis runs on every PR and push to main
- **TruffleHog**: Secret scanning prevents accidental credential commits
- **Godot compile check**: All GDScript is validated on every change
- **JSON validation**: All bundled data files are syntax-checked

### Build Pipeline
- The web export uses `barichello/godot-ci` official Docker images
- GitHub Pages deployment uses OIDC token authentication (no stored secrets)
- COI service worker is included for SharedArrayBuffer (required by Godot web exports)

### Threat Intelligence Data
- CVE/KEV data is mirrored from public NVD/CISA APIs via `tools/sync_threat_intel.py`
- The sync script is rate-limited and only run manually by developers
- Mirrored data contains only public vulnerability information
