# Changelog

All notable changes to `booster-skills` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] — 2026-06-14

### Added

#### 2 Skills (rescue from agent-rigor, redesigned as content)

- **`definicion-de-terminado`** — NEW. Definition of Done + anti-rationalization standard (Spanish). Replaces agent-rigor's keyword-taboo "no MVP / cero deuda" (which was enforced by a broken hook) with a verifiable bar. Attacks the real failure mode: declaring "done" without evidence and patching symptoms instead of root cause. Complements `superpowers:verification-before-completion` and `superpowers:test-driven-development`.
- **`tdd-dominio-critico`** — NEW. Fixes WHERE TDD is non-negotiable in Booster (DTE/SII, carta de porte, factoring, pricing, GLEC, matching, DB migrations, auth), delegating the red-green-refactor mechanics to `superpowers:test-driven-development`.

#### Observational ledger + weekly scorecard (rescue of agent-rigor mechanism #2)

- **`hooks/`** — `session-start.sh` (bootstrap ledger), `log-event.sh` (PostToolUse: Write/Edit/MultiEdit/Read/Task), `stop.sh` (turn summary), `lib-ledger.sh` (shared helpers). Registered via `hooks/hooks.json`.
- **`benchmark/score-week.sh`** — weekly observational scorecard (artifacts by kind, test:source ratio, subagent invocations, skill reads, commits). No gates, no pass/fail threshold.
- **`tests/ledger.bats`** — 8 tests covering the hooks and scorecard.

### Changed

- `plugin.json` / `marketplace.json`: version 0.1.0 → 0.2.0; description 7 → 9 skills + ledger; **"Companion to agent-rigor" → "Companion to superpowers"**.

### Notes

- **Capa 1 de disciplina migrada de `agent-rigor` a `superpowers`** (ver ADR-051 en booster-ai). Este plugin deja de ser companion de agent-rigor.
- **El ledger es observacional, sin gates** (ningún hook hace `exit 2`), corrigiendo los dos defectos que volvieron ficción al original de agent-rigor: el gate "leíste CLAUDE.md" era código muerto (PostToolUse no cableaba `Read`) y el escape valve anti-drift hacía deadlock. Aquí `Read` y `Task` están correctamente cableados y nada bloquea.
- **Límites honestos del ledger**: mide lo observable (archivos, ratio test:source, subagentes, lecturas, commits). No mide comprensión del contrato ni intención de drift — eso no es observable sin teatro.


## [0.1.0] — 2026-05-20

### Added

Initial release of `booster-skills` plugin for Claude Code.

#### 7 Skills

- **`arquitecto-maestro`** (v1.1.0) — Meta-orchestrator for complex missions. Migrated from `booster-ai` repo with description updated for better auto-triggering, ledger format updated to JSONL (agent-rigor canonical), and references to non-existent skills (`writing-tests`, `dte-integration-chile`, etc.) removed.
- **`adding-cloud-run-service`** (v1.1.0) — Scaffold new Cloud Run services. Migrated with full YAML frontmatter added (was missing `name`/`description` for auto-triggering).
- **`carbon-calculation-glec`** (v1.1.0) — GLEC v3.0 + GHG Protocol carbon footprint calculation. Migrated with full YAML frontmatter added.
- **`empty-leg-matching`** (v1.1.0) — Transparent, auditable carrier matching algorithm. Migrated with full YAML frontmatter added.
- **`incident-response`** (v1.1.0) — Production incident response (detect → stabilize → understand). Migrated with full YAML frontmatter added, references to non-existent `skills/post-mortem` and `skills/rotate-credential` replaced with inline procedures.
- **`booster-stack-conventions`** (v1.0.0) — NEW. Stack-wide conventions (Zod, Biome, Logger, OTel, coverage 80%, Conventional Commits with scope, Evidencia section in PRs). Absorbs the stack-specific content that was scattered across the 6 local commands in `.claude/commands/`.
- **`booster-deploy-cloud-run`** (v1.0.0) — NEW. Deploy workflow (Cloud Build staging auto → prod manual approval → 2h post-deploy monitoring + 24h self-postmortem). Absorbs the Booster-specific shipping content that was in the local `/ship` command.

#### 6 Sub-agents (migrated as-is)

- `dependency-auditor` — pnpm audit + vulnerability scan + stack canonical verification
- `explore-architecture` — top-level repo mapping (9 apps × 21 packages)
- `performance-analyzer` — backend N+1 + frontend bundle size + PWA + Web Vitals
- `refactor-advisor` — synthesizes outputs from the other 5 audit sub-agents, produces priority P0/P1/P2 + roadmap
- `security-scanner` — secrets + JWT + SQL injection + CORS + OWASP Top 10
- `tech-debt-detector` — any, ts-ignore, TODO/FIXME, localhost, mocks, console violations

### Notes

- This plugin is a **companion to `agent-rigor` 0.2.0+**. Both must be installed for the full Booster AI Claude Code experience.
- **Canonical path for specs is `.specs/<feature-slug>/`** (defined by `agent-rigor`), not `docs/specs/`. The Booster project will be migrated to this convention in a separate PR.
- **2 redundant skills NOT migrated** from `booster-ai`:
  - `writing-adrs` — covered by `agent-rigor`'s `63-documentation-and-adrs`
  - `using-agent-skills` — covered by `agent-rigor`'s `00-using-this-pack`
- The 6 local commands in `.claude/commands/` of the booster-ai repo (`build`, `plan`, `review`, `ship`, `spec`, `test`) are NOT migrated — they are deprecated in favor of `/agent-rigor:*` commands. Their Booster-specific content has been absorbed into `booster-stack-conventions` and `booster-deploy-cloud-run`.

### Migration audit trail

Each migrated file documents its changes from the original in the version bump notes within the YAML frontmatter (`version: 1.1.0`). Full migration report available in `docs/migration-from-booster-ai-repo.md` (the spec that produced this release).

[Unreleased]: https://github.com/boosterchile/booster-skills/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/boosterchile/booster-skills/releases/tag/v0.2.0
[0.1.0]: https://github.com/boosterchile/booster-skills/releases/tag/v0.1.0
