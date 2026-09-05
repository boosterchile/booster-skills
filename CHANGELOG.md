# Changelog

All notable changes to `booster-skills` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] — 2026-09-05

Alineación del plugin al estado real de `booster-ai` (contrato `CLAUDE.md` reescrito en ADR-072, remoción de emisión DTE en ADR-069/070, pnpm 10 en ADR-075, gobernanza de operador único en ADR-076) y a las recomendaciones de prompting para Claude 4.5+/Opus/Fable. Sin cambios de comportamiento en `booster-ai`: el plugin sigue siendo conocimiento opcional.

### Changed

- **Descripciones de las 9 skills** reescritas sin el patrón "Make sure to use this skill any time the user mentions …" (la guía oficial documenta que los modelos recientes sobre-disparan con lenguaje enfático) y con criterios de activación objetivos. `arquitecto-maestro` deja de activarse por "más de 30 minutos" o "si dudas, califica".
- **`booster-deploy-cloud-run`** reescrita sobre el flujo real: no existe staging (`#STAGING-ENV`); un merge a `main` no despliega; `gh workflow run release.yml --ref main` → espera `CI Success` → gate humano del Environment `production` → Cloud Build canary 1 %/30 min con `canary-verify` → 100 % → monitoreo 2 h; versionado por changesets. Incluye el gotcha de `LATEST → 100 %` sin nombre de revisión.
- **`arquitecto-maestro`**: retiradas todas las referencias a `agent-rigor` (comandos, sesión UUID, devils-advocate, ledger manual). Fase 1 incorpora `docs/frentes-vivos.md` (tres slots) y el vocabulario de vigencia de ADR-076. Aprobación anclada a la Frontera de decisiones de `CLAUDE.md`.
- **`tdd-dominio-critico`** y **`security-scanner`**: `packages/dte-provider` ya no existe; Booster recibe y archiva DTE de terceros (`packages/transport-documents`, `apps/document-service`). Se exige el rojo exhibido en la Evidencia del PR (`CLAUDE.md` §Ciclo 3). Retirado el requisito de Object Retention Lock (ADR-070: retención de custodia O-3).
- **`booster-stack-conventions`**: Node 24 / pnpm 10; summary de commit en español con ejemplos en español; nueva sección de naming bilingüe (`Transportista`/`GeneradorCarga`); deuda deliberada con followup en `.specs/_followups/`, no waiver en ledger.
- **`carbon-calculation-glec`**: factores en `src/factores/` (no `data/*.json`); persistencia en `metricas_viaje` con nombres reales del schema (`emisiones_kgco2e_reales`, `distancia_km_real`, `cobertura_pct`); regla de degradación explícita del Slot 1 (nunca `0`, nunca silencioso).
- **`adding-cloud-run-service`**: `node:24-alpine`, Dockerfile por copia del patrón `pnpm deploy --prod --legacy` (ADR-075), infra plana en `infrastructure/compute.tf`, gateway en GKE.
- **`empty-leg-matching`, `incident-response`, `definicion-de-terminado`**: naming bilingüe, rollback en GKE, feature flags reales, referencia a `superpowers` condicionada a que esté instalado. Enlaces relativos a `../../docs/adr/` (rotos desde el plugin) sustituidos por referencias textuales.
- **Sub-agents**: los 7 deben escribir en `audit-outputs/` y ninguno tenía `Write`; ahora lo tienen, acotado por instrucción a `audit-outputs/<agent>.md`. Nombres de salida unificados a `<agent>.md` (los que ya existen en `booster-ai`); `refactor-advisor` consume los 6 reportes (antes 5, sin `sre-oncall`, con nombres numerados que nadie producía). `explore-architecture` pasa a `sonnet` y obtiene el inventario del repo en vez de una lista hardcodeada. `security-scanner` deja de intentar invocar `/security-review` desde un subagente. `tech-debt-detector` pierde el mecanismo `drift_justified` de `agent-rigor`. `dependency-auditor` verifica los security pins de `pnpm-workspace.yaml`.
- **`/audit-completo`**: inventario real de packages, salida por agent, no abre frente.
- `README.md`: reframe según ADR-072 (la disciplina vive en `CLAUDE.md`; el plugin es conocimiento opcional), stack actualizado.

### Removed

- **Hooks de ledger observacional** (`hooks/`, `benchmark/score-week.sh`, `tests/ledger.bats`), según ADR-072 §4: "observabilidad sin consumidor es peso muerto; si a futuro se quiere medición, se diseña con el consumidor primero". Costaban un `jq` + `shasum` por cada `Read`/`Write`/`Edit`/`Task` de cada sesión. El plugin ya no registra hooks.

## [0.4.0] — 2026-06-14

Primer **slash command** del plugin. `/audit-completo` orquesta los 7 audit sub-agents en una auditoría READ-ONLY y sintetiza un roadmap priorizado P0/P1/P2, sin modificar código.

### Added

- **`commands/audit-completo.md`** — NEW slash command `/audit-completo [all | security | deps | perf | debt | sre | arch]` (default `all`). Despacha en paralelo `explore-architecture`, `security-scanner`, `dependency-auditor`, `performance-analyzer`, `tech-debt-detector`, `sre-oncall` y consolida con `refactor-advisor`. Entregables: `audit-outputs/*.md`, `.specs/revision-completa-<fecha>/review.md` y un stub en `.specs/_followups/` por cada P0. READ-ONLY: diagnóstico, no fixes. Marca áreas CONGELADAS / legalmente vinculantes (ej. `factoring-v1.0-cl-*`) sin proponer edits directos.

### Changed

- `plugin.json` / `marketplace.json`: version 0.3.0 → 0.4.0; description "+1 slash command /audit-completo".

## [0.3.0] — 2026-06-14

Consolidación de los 3 sub-agents locales que quedaban en `agents/` del repo `booster-ai` (huérfanos tras el retiro de `agent-rigor` en ADR-060). Sin duplicar lo que `superpowers` y este plugin ya cubren. Resultado: 6 → **7 audit sub-agents**.

### Added

- **`agents/sre-oncall.md`** — NEW sub-agent. Revisor SRE **pre-merge** (observabilidad, rollback readiness, SLOs, capacity, costos GCP, dependencias externas con timeout/retry/circuit-breaker, compliance operacional). Distinto de la skill `incident-response` (que actúa *durante* un incidente). Portado del override local de `booster-ai`.
- **`security-scanner`** — extendido con **compliance Chile** (secciones 13–16 + anti-rationalizations + referencias): RBAC por rol (shipper/carrier/driver/admin/stakeholder), Ley 19.628 (PII + `stakeholder_access_log`), SII/DTE (Object Retention Lock, hash SHA-256 + firma KMS), criptografía (CMEK, sin MD5/SHA-1). Absorbe el contenido único de `agents/security-auditor.md` de `booster-ai`. El contenido OWASP/secrets/SQLi existente (tareas 1–12) se conserva intacto.
- **`booster-stack-conventions`** — nuevo paso **7. ADR compliance** en Core Process + checkbox en Exit criteria. Pliega el único bit único de `agents/code-reviewer.md` de `booster-ai` (review genérico ya lo cubre `superpowers:subagent-driven-development`).

### Changed

- `plugin.json` / `marketplace.json`: version 0.2.0 → 0.3.0; description "6 audit sub-agents" → "7 audit sub-agents (security-scanner con compliance Chile, + sre-oncall pre-merge)".
- `README.md`: reframe `agent-rigor` → `superpowers` (companion + tabla de responsabilidades); corrige conteos a 9 skills / 7 sub-agents; añade fila `sre-oncall` y v0.3.0.

### Notes

- **Cierra la consolidación** trackeada en `.specs/_followups/migrate-booster-agents-to-plugin-v0.2.0.md` de `booster-ai`. Tras este release, el repo `booster-ai` borra los 3 overrides locales (`agents/`).
- **Decisiones del PO (2026-06-14)**: extender `security-scanner` (un solo agente de seguridad, menos superficie); retirar `code-reviewer` plegando solo el chequeo ADR; traer `sre-oncall` como sub-agent nuevo. NO se recrea `code-reviewer` (review genérico = superpowers) ni se crea un agente de compliance separado.

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

[Unreleased]: https://github.com/boosterchile/booster-skills/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/boosterchile/booster-skills/releases/tag/v0.5.0
[0.4.0]: https://github.com/boosterchile/booster-skills/releases/tag/v0.4.0
[0.3.0]: https://github.com/boosterchile/booster-skills/releases/tag/v0.3.0
[0.2.0]: https://github.com/boosterchile/booster-skills/releases/tag/v0.2.0
[0.1.0]: https://github.com/boosterchile/booster-skills/releases/tag/v0.1.0
