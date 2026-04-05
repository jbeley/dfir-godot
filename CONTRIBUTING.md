# Contributing to DFIR Simulator

Thanks for your interest in contributing! This guide will help you get started.

## Development Setup

1. Install [Godot 4.3+](https://godotengine.org/download) (standard, not .NET)
2. Clone the repo: `git clone https://github.com/jbeley/dfir-godot.git`
3. Open `project.godot` in Godot
4. Install pre-commit hooks: `pip install pre-commit && pre-commit install`

## Project Structure

```
src/
  autoloads/       # 7 global singletons (GameManager, TimeManager, etc.)
  data/
    models/        # Resource classes (CaseData, EvidenceData, etc.)
    generators/    # Procedural content generators
  scenes/
    main_menu/     # Title screen
    office/        # WFH apartment hub + player
    workstation/   # Terminal, log viewer, tabs
      terminal/
        commands/  # One script per CLI command
    evidence_board/
    hud/
  ui/components/   # Reusable UI widgets
  systems/
    forensics/     # VirtualFilesystem, IOC matching
    scoring/       # Case scoring engine
assets/
  data/            # Bundled threat intel (CVE, KEV, ATT&CK)
tools/             # Build-time tools (sync scripts, NPC generator)
tests/             # GUT unit tests
```

## How to Contribute

### Adding a New Terminal Command

1. Create `src/scenes/workstation/terminal/commands/cmd_yourcommand.gd`
2. Extend `BaseCommand` and implement:
   - `get_name()` - command name (lowercase)
   - `get_description()` - one-line help text
   - `get_usage()` - usage string
   - `get_min_tier()` - minimum career tier (0=Intern, see ReputationManager)
   - `execute(args, piped_input)` - the actual logic, return output string
3. Register it in `workstation.gd` `_register_commands()`
4. Add a unit test in `tests/`

### Adding a New Case

Cases are JSON-defined evidence packs. See `src/data/sample_case_loader.gd` for the tutorial case structure. A case needs:

- Case metadata (title, severity, deadline, ATT&CK techniques)
- Client NPC (personality, trust level, backstory)
- Evidence items (type, VFS path, content, hidden IOCs)
- Ground truth IOCs for scoring

### Adding Evidence Types

1. Add the type to `EvidenceData.EvidenceType` enum
2. Update `get_type_name()` in the same file
3. Ensure the virtual filesystem can serve the content

## Code Style

- **GDScript**: Follow [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- **Types**: Use explicit type annotations. Avoid Variant inference.
- **Naming**: `snake_case` for functions/variables, `PascalCase` for classes, `UPPER_CASE` for constants
- **Comments**: Only where logic isn't self-evident. No docstrings on obvious methods.
- **Line length**: 120 characters max

## Pull Request Process

1. Fork the repo and create a feature branch from `main`
2. Make your changes with clear, atomic commits
3. Ensure all CI checks pass (semgrep, gdlint, compile check)
4. Write/update tests for new functionality
5. Submit a PR with a clear description of what and why

## CI Checks

Every PR runs:
- **Semgrep SAST** - security static analysis
- **GDScript lint** - code style via gdtoolkit
- **Godot compile** - all scripts must parse without errors
- **TruffleHog** - secret scanning
- **JSON validation** - all data files must be valid
- **Unit tests** - GUT test suite must pass

## Security

See [SECURITY.md](SECURITY.md) for our security policy. Key points:
- No runtime network calls
- No user data collection
- All threat intel data is public and pre-bundled
- Report vulnerabilities privately, not via public issues
