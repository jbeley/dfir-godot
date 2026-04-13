# DFIR Simulator — Content Research Creative Brief

This brief captures the creative direction set by the project lead before deep
research began. Every research document in this directory must align with it.
If something in research conflicts with the brief, the brief wins until the
brief is explicitly amended.

## North star

> **Production-grade DFIR authenticity wrapped in dry workplace comedy. A
> working analyst should nod along at every log line while laughing at the
> people around them.**

The audience is DFIR practitioners and students. The game doubles as a
recognition-of-craft love letter and a low-friction way for curious players to
learn what real incident response looks like.

## Tonal references

- **Office Space / Severance** — corporate absurdity, optics-over-substance,
  middle-management nonsense, mandatory meetings during active incidents.
- **IT Crowd / Silicon Valley** — competence vs. user helplessness, bad
  infrastructure as physical comedy, "have you tried restoring from backup?"
- **30 Rock / Veep** — rapid-fire wit, escalating misunderstandings, characters
  who are too smart for their own good.

Tone is **dry**, not slapstick. Comedy comes from competence under
ridiculous conditions, not from goofy characters. The cat is the only
unambiguously silly element and that is intentional.

## Setting

- **Present day, 2024–2026.** Real CVEs, real tooling versions, recognizable
  stack. The game can age — that's a feature, it pins the snapshot.
- **Regulatory acronyms stay light.** Clients panic about "the regulators"
  more than they panic about specific frameworks. No textbook detours.
- **Geography agnostic.** US-default but we will not lean on
  HIPAA/SEC/CIRCIA/GDPR/NIS2 vocabulary as plot drivers.

## Player

- **Blank-slate protagonist** with a career ladder
  (Intern → Junior → Analyst → Senior → Principal → Lead → Director).
- Has a cat. The cat is canon.
- **Starts as a host-forensics specialist** under an NPC Incident Commander.
  Promoted into the Incident Commander role at the **Senior** tier — this
  promotion is a campaign beat, not a stat unlock.

## DFIR is a team sport

The defining design decision: **the player is never alone on a case.** The
firm is a small ensemble cast and most cases pull in a rotating mix of
specialists. Solo-keyboard-hero framing is rejected.

### The firm

- **6–8 named teammates** at the player's boutique DFIR firm.
- **Player + 2–3 recurring teammates** form the core of most cases.
- **Specialists rotate in by case** — pulling whoever the incident needs.
- **Managing partner** is the wise/dry mentor who fields client intake,
  takes the worst client calls, and shields the team from billing nonsense.
  Tone-setter for the firm's voice.

### Extended cast (recurring NPCs across cases)

- **Rival DFIR firm.** A bigger competitor that shows up on shared incidents,
  poaches the player's people, and races to attribution. Frenemy energy.
- **Government liaisons.** FBI cyber agent and CISA SSA contact. Neutral
  allies who appear on big cases — weighty, plain-spoken, slightly tired.
- **Cyber insurance panel + ransomware negotiator.** Insurance-mandated
  breach counsel and panel forensics. Helpful-but-obstructive third parties.

### Client-side recurring NPC archetypes

- **Panicked CEO / founder** — denial → bargaining → escalating panic.
- **Hostile lawyer / breach counsel** — privilege gatekeeper. "Don't put
  that in writing." Slows evidence access, demands redactions.
- **Exhausted lone IT admin** — knows more than the CEO, has been warning
  about this for months. Best ally and most unreliable witness.

### Team gameplay mechanics (all three coexist)

Task assignment supports **three input methods, all available simultaneously**:
terminal commands (`page dana`, `assign dana evtx-triage DC01`), click-the-
teammate menus in the Teams pane, and natural-language messages in the
Teams input box (`@dana pull sysmon from DC01`). Power users live in the
terminal; new players discover via menus; roleplay-inclined players write
messages. All three resolve to the same underlying `TeamManager.assign_task`
call.

1. **Task assignment / async.** "Dana, pull Sysmon from the DCs." Results
   come back after in-game time. Specialists do specialist work.
2. **Autonomous Teams chatter.** Teammates proactively message findings,
   ask questions, disagree with each other. The player reads/reacts.
   Microsoft Teams war-room atmosphere — yes, Teams, not Slack. Enterprise
   DFIR lives in Teams, and Teams' particular corporate soullessness pairs
   naturally with the dry-workplace tone. Presented in-game via a
   **dockable widget with unread-count badge** that expands in-place.
   Chatter pacing is **event-driven + thin ambient**: teammates post when
   the player runs a meaningful command, finds an IOC, crosses a time
   threshold, or hits a case milestone, with a light background layer of
   ambient bickering on a 3–5 minute cadence during active cases.
3. **Pair-programming handoff.** Player can hand the terminal to a
   specialist for sub-tasks they're better at. They narrate and solve;
   player gets the output. Highlights specialty differentiation.

### Team dynamic drivers (sources of comedy and drama)

- **Specialty clashes.** Network engineer insists it's the firewall; host
  forensics insists it's lateral movement. Tribal rivalries about what
  "really" happened.
- **Burnout & on-call hell.** Sleep trading, 4am typos, competence under
  duress. Maps onto the existing Focus/Energy/Stress stats.
- **Generational/culture gap.** Old-school (EnCase, ticket-everything) vs
  new-school (Velociraptor, Teams-first, LLM-curious) tooling wars.

We are deliberately **not** leaning on firm politics / billing nonsense as
a primary comedy engine. Comedy is about the work and the people doing it.

## Story

Existing campaign structure stands:

- **DarkLock Ransomware Gang** (Acts 1–2)
- **Phantom Bear APT** (Acts 2–3)
- **The Insider** (Act 1, escalates)
- **Convergence** (Act 3 finale — all three hit the same target)

### The orchestrator: rogue Initial Access Broker

The Convergence is not coincidence. A **rogue IAB / access broker**
mercenary, morally grey, not ideological — sold the same foothold to
DarkLock, Phantom Bear, and the Insider's handler. They are a **shadow in
the margins**: a handle that surfaces in forum scrapes, passive DNS, chat
leaks, and sandbox sample telemetry. Never seen on screen until Convergence.
Players who pay attention across many cases will start to feel the shape
of them before the reveal.

### Side cases

The bulk of this research pass goes into building a deep **side-case
backlog**, not new arcs. Side cases run parallel to the main campaign and
pull from all incident classes:

- Ransomware & extortion
- BEC / cloud identity (M365/Entra, OAuth, AiTM phishing, token theft)
- APT / edge device exploitation
- Insider threat / data theft
- Web app & initial access brokers
- OT/ICS & critical infrastructure
- macOS / Linux forensics
- Mobile / messaging / commercial spyware

Cases must feel **fictionalized but inspired by real recent breaches**.
Practitioners should recognize the bones. The reference set includes
Change Healthcare, MOVEit, Snowflake, Okta/Lapsus$, CrowdStrike outage,
SolarWinds, NotPetya, Kaseya — files-off-serial-numbers style.

**Sensitivity guardrails:**

- **Avoid mass-casualty / human-harm framing.** Hospital ransomware is
  fair game; on-screen patient deaths are not.
- **Don't punch down at recognizable victims.** Fictionalize hard enough
  that no real org could feel attacked.

## Forensic surface area

### Evidence formats to make feel authentic

- **Windows artifacts** — EVTX, MFT, ShimCache, Amcache, Prefetch, SRUM,
  UsnJrnl, registry hives. The Hayabusa/Plaso backbone.
- **Network & EDR telemetry** — Zeek logs, PCAP excerpts, Sysmon process
  trees, script-block logs, proxy/DNS.
- **Cloud & SaaS logs** — M365 Unified Audit Log, Entra sign-in logs, AWS
  CloudTrail, Okta system log, GitHub audit.

(Memory forensics and email-header forensics deprioritized for this pass.)

### In-game terminal — tools to echo

- **Velociraptor / KAPE** for triage collection. VQL-flavored queries,
  targets, artifact packs.
- **Splunk SPL / KQL / Sigma** for SIEM and detection-engineer flavor.
- **Plaso + Hayabusa expansion** — already in-game; deepen with more
  artifact parsers, Chainsaw / EvtxECmd flavor.

(Memory tooling — Volatility / MemProcFS — deprioritized for this pass.)

## Research output rules

- **Markdown research docs** live under `docs/research/`. Each document is
  a standalone deep-dive on one topic. Human-readable, reviewable in PRs.
- **JSON case packs** that exemplify the research drop into
  `assets/data/case_packs/` and must conform to the schema demonstrated by
  `assets/data/case_packs/sample_pack.json`.
- **Realism budget:** every log line, command output, IOC, ATT&CK
  technique ID, and tool flag must pass a senior analyst's smell test.
  When in doubt, look it up. When still in doubt, flag it in a "needs
  practitioner review" callout in the doc.
- **Comedy budget:** every case carries at least one dry comedic beat
  appropriate to the tonal references above. The job is grim; the people
  are funny.

## What lives in this directory

| File | Purpose |
|---|---|
| `00_creative_brief.md` | This document. The contract. |
| `01_threat_actors.md` | Real-world threat actor profiles, fictional analogs for DarkLock / Phantom Bear / Insider arcs, IAB villain shadow lore. |
| `02_case_catalog.md` | Side-case scenario seeds across all incident classes, each with attack chain, evidence list, IOCs, ATT&CK techniques, comedy hook. |
| `03_terminal_expansion.md` | Velociraptor VQL / KAPE / Plaso / Hayabusa / Splunk / KQL / Sigma syntax research and proposals for new in-game terminal commands. |
| `04_team_and_dialogue.md` | The 6–8 firm teammates (names, specialties, voices, backstories), managing partner, recurring NPC archetype dialogue patterns, rival firm, gov liaisons, insurance/negotiator. |
| `05_comedy_beats.md` | Catalog of running gags, interruption types, Slack-room exchanges, absurd client moments. |
| `06_evidence_corpus.md` | Reference excerpts of authentic Windows / Network / Cloud logs annotated with what each attack pattern looks like in the artifact. Source-of-truth for case-pack writers. |

A separate follow-up pass will turn this research into shipping content:
new JSON case packs, dialogue trees, terminal command implementations, and
campaign-manager additions.
