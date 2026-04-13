# DFIR Simulator — Content Research

Research notes and reference material for game content. Produced in deep-
research passes ahead of writing shipping content (case packs, dialogue
trees, terminal commands, campaign edits).

**Start here:** [`00_creative_brief.md`](00_creative_brief.md) — the
creative direction every other doc in this directory must align with.

## Index

| # | Document | What it covers |
|---|---|---|
| 00 | [Creative brief](00_creative_brief.md) | North star, tone, team-sport framing, story, surface area, rules |
| 01 | [Threat actors](01_threat_actors.md) | Real-world adversary profiles, fictional analogs for DarkLock / Phantom Bear / Insider, IAB villain lore |
| 02 | [Case catalog](02_case_catalog.md) | Side-case scenario seeds across all incident classes |
| 03 | [Terminal expansion](03_terminal_expansion.md) | Tool syntax research (Velociraptor VQL / KAPE / Plaso / Hayabusa / SPL / KQL / Sigma) and command proposals |
| 04 | [Team & dialogue](04_team_and_dialogue.md) | Firm roster, managing partner, recurring NPCs, dialogue patterns |
| 05 | [Comedy beats](05_comedy_beats.md) | Running gags, interruption types, Slack-room exchanges |
| 06 | [Evidence corpus](06_evidence_corpus.md) | Annotated authentic log excerpts as source-of-truth for case-pack writers |

## Conventions

- Every document begins with a one-paragraph **scope** and ends with a
  **practitioner review queue** — a bulleted list of claims, syntax
  fragments, or scenario beats that should be verified by a working DFIR
  analyst before they ship in-game.
- Real-world incidents are referenced for inspiration, never reproduced
  faithfully. Files-off-serial-numbers fictionalization is the rule.
- ATT&CK technique IDs are written as `Txxxx` or `Txxxx.yyy` with the
  human-readable name on first use.
- Case scenarios use the schema from
  [`assets/data/case_packs/sample_pack.json`](../../assets/data/case_packs/sample_pack.json)
  when concrete enough to be implemented.
