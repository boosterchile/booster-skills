# booster-skills

**Booster AI domain pack for Claude Code.**

Paquete de **conocimiento de dominio** para el monorepo `booster-ai`: convenciones del stack, flujo de deploy real, dominio (GLEC, matching, documentos), respuesta a incidentes y 7 sub-agents de auditoría. Desde ADR-072 (2026-07-06) la **disciplina normativa vive inline en el `CLAUDE.md` de `booster-ai`** + CI/pre-commit + gates de GitHub; este plugin es apoyo opcional y ninguna regla del contrato delega su cumplimiento aquí. Si un skill contradice `CLAUDE.md`, gana `CLAUDE.md`. (Historia: companion de `agent-rigor` hasta v0.2.0, ADR-060; companion de `superpowers` hasta v0.4.0.)

---

## Contenido

### 9 Skills

| Skill | Cuándo se activa |
|---|---|
| `arquitecto-maestro` | Misiones que cruzan más de una app/package, requieren ADR, combinan dimensiones o tocan archivos protegidos; produce `.specs/<slug>/spec.md` para aprobación del PO |
| `adding-cloud-run-service` | Crear un servicio Cloud Run nuevo con observabilidad + seguridad + ops-readiness desde day 0 |
| `carbon-calculation-glec` | Cálculo GLEC v3.0 + GHG Protocol; factores de emisión; degradación explícita; certificados ESG |
| `empty-leg-matching` | Algoritmo de matching carga ↔ transportista; scoring transparente, determinístico y auditable |
| `incident-response` | Cuando algo falla en producción: detectar → estabilizar → entender |
| `booster-stack-conventions` | Al escribir o revisar código TS/test/endpoint/schema/log/commit/PR en `booster-ai` |
| `booster-deploy-cloud-run` | Deploy a prod (`gh workflow run release.yml` → gate humano → canary 1 %/30 min → 100 % → monitoreo 2 h); rollback |
| `definicion-de-terminado` | Antes de declarar listo / commitear / abrir PR; anti-parches (material extendido de `CLAUDE.md` §Ciclo 4) |
| `tdd-dominio-critico` | Dónde el TDD con rojo exhibido es obligatorio (documentos de terceros, factoring, pricing, GLEC, matching, certificados, migraciones, auth) |

### 7 Sub-agents (auditoría arquitectónica)

Todos son read-only sobre el código y escriben su reporte en `audit-outputs/<agent>.md`.

| Agent | Modelo | Propósito |
|---|---|---|
| `dependency-auditor` | haiku | Dependencias (pnpm audit, drift, security pins de `pnpm-workspace.yaml`, stack ADR-001/075) |
| `explore-architecture` | sonnet | Mapa top-down del monorepo, dependencias internas, boundaries, naming |
| `performance-analyzer` | sonnet | Rendimiento (N+1, índices, pool, cold start, telemetría, bundle, Web Vitals) |
| `refactor-advisor` | opus | Síntesis transversal y priorización (consume los otros 6 reportes) |
| `security-scanner` | sonnet | Seguridad estática (auth, secrets, IAM, headers, OWASP) **+ compliance Chile** (Ley 19.628/21.719, documentos de terceros ADR-069/070, RBAC por rol, consent ESG) |
| `tech-debt-detector` | haiku | Deuda técnica (any, ts-ignore, TODOs sin issue, localhost, mocks, console, catch silenciosos) |
| `sre-oncall` | sonnet | Revisor SRE **pre-merge** (observabilidad, rollback, SLO, capacity, costos, deps externas) |

### 1 Slash command

`/audit-completo [all | security | deps | perf | debt | sre | arch]` — despacha los sub-agents en paralelo y sintetiza con `refactor-advisor`. READ-ONLY.

---

## Instalación

Dentro de una sesión de Claude Code:

```bash
/plugin marketplace add boosterchile/booster-skills
/plugin install booster-skills@booster-skills
```

Verificar:

```bash
/plugin list
```

Debes ver `booster-skills` listado y habilitado.

---

## Uso

Los componentes de este plugin se invocan **automáticamente** por Claude Code cuando detecta tareas que matchean sus descripciones. No requiere slash commands explícitos.

Ejemplos:

- Pedir "implementa un nuevo endpoint en apps/api" → `booster-stack-conventions` se activa (impone Zod, Logger, OTel).
- Pedir "calcula la huella de carbono del trip X" → `carbon-calculation-glec` se activa.
- Pedir "algo está roto en producción" → `incident-response` se activa.
- Pedir "vamos a desplegar a prod" → `booster-deploy-cloud-run` se activa.
- Pedir "crea un servicio nuevo de notificaciones en Cloud Run" → `adding-cloud-run-service` se activa.
- Pedir "diseña el plan para refactorizar X que toca varios servicios" → `arquitecto-maestro` se activa.

Los sub-agents se invocan explícitamente:

```bash
Use the security-scanner agent on the apps/api directory
Use the dependency-auditor agent on package.json
Use the refactor-advisor agent to synthesize audit-outputs/
```

---

## Relación con `CLAUDE.md` y con `superpowers`

Desde ADR-072 la distribución es:

| Responsabilidad | Dónde vive |
|---|---|
| Frontera de decisiones, un frente por vez, spec antes de construir, TDD con rojo exhibido, terminado = evidencia fresca, reglas duras del stack, naming, PRs y deploy | **`CLAUDE.md` de `booster-ai`** (normativo) + CI/pre-commit + gates de GitHub |
| Ciclo genérico brainstorming → plan → ejecución → verificación → review por subagente | `superpowers` (refuerzo opcional; los skills de este plugin lo invocan solo si está instalado) |
| Ejemplos, patrones y checklists del stack Booster | `booster-skills` (`booster-stack-conventions`, `definicion-de-terminado`, `tdd-dominio-critico`) |
| Dominio Booster (carbono GLEC, matching, documentos de terceros) | `booster-skills` |
| Flujo de deploy real y rollback | `booster-skills` (`booster-deploy-cloud-run`) |
| Sub-agents de auditoría + SRE pre-merge + `/audit-completo` | `booster-skills` |
| Orquestación cross-cutting (`arquitecto-maestro`) | `booster-skills` |

Instalación opcional de `superpowers`: `/plugin install superpowers@claude-plugins-official`.

Path canónico de specs: `.specs/<slug>/{spec,plan,verify,review,ship}.md` (convención de `CLAUDE.md`). Este plugin **no registra hooks** desde v0.5.0 (el ledger observacional se retiró por ADR-072 §4: observabilidad sin consumidor).

---

## Stack soportado

Este plugin está optimizado para el stack canónico de Booster AI:

- **Runtime**: Node.js 24 (`.nvmrc`)
- **Compute**: Google Cloud Run (8 servicios) + GKE Autopilot para el gateway TCP (ADR-065)
- **Database**: Google Cloud SQL Postgres + pg driver + Drizzle
- **Frontend**: React 18 + Vite 6 + TypeScript 5.8 + @tanstack/react-router + Tailwind 4
- **Package manager**: pnpm 10 (ADR-075; overrides en `pnpm-workspace.yaml`)
- **Monorepo**: Turborepo
- **Linter/formatter**: Biome 1.9
- **HTTP framework**: Hono 4
- **Telemetría**: OpenTelemetry (`@booster-ai/otel-bootstrap`) + Pino + Cloud Trace/Monitoring; Datadog solo infra/logs en GKE (ADR-071)
- **IaC**: Terraform (plano, un solo entorno `prod`; no hay staging)
- **CI/CD**: GitHub Actions (CI, security, `release.yml` dispatch-only) + Cloud Build con canary 1 % → 100 %
- **Auth**: Firebase Auth / Identity Platform + JWT Zero-Trust (ADR-001)
- **Carbon framework**: GLEC v3.0 + GHG Protocol
- **Telemetría IoT**: Teltonika Codec 8 + Pub/Sub
- **Documentos**: recepción y archivo de DTE de terceros con extracción TED (ADR-069/070); Booster no emite DTE

Si tu proyecto usa un stack distinto, considera bifurcar este repo o crear tu propio domain pack.

---

## Filosofía

> Cero deuda técnica desde day 0. Siempre desarrollo profesional, no MVP. Sin atajos que cuesten más mañana que hoy.

Cinco principios:

1. **El stack es contrato**, no preferencia. Cambiarlo requiere ADR.
2. **Observabilidad desde el primer endpoint**, no después.
3. **Type safety end-to-end**, sin `any`, sin `@ts-ignore`.
4. **Validación en boundaries**, todo input externo pasa por Zod.
5. **Conventional Commits con scope `<domain>`**, sección Evidencia en cada PR.

---

## Versionado

Semantic Versioning. Ver [CHANGELOG.md](CHANGELOG.md).

- v0.5.0 (2026-09): Alineación al `CLAUDE.md` post-ADR-072 y al repo real (deploy sin staging, ADR-069/070, Node 24 / pnpm 10). Descripciones sin sobre-disparo para Opus/Fable. Sub-agents con `Write` a `audit-outputs/`. Hooks de ledger retirados.
- v0.4.0 (2026-06): Slash command `/audit-completo`.
- v0.3.0 (2026-06): Consolidación de overrides locales de `booster-ai`. `security-scanner` extendido con compliance Chile, nuevo sub-agent `sre-oncall`, ADR-compliance plegado en `booster-stack-conventions`. 9 skills + 7 audit sub-agents.
- v0.2.0 (2026-06): Rescate de disciplina post-ADR-060. +2 skills (`definicion-de-terminado`, `tdd-dominio-critico`) + ledger observacional. Companion pasa de `agent-rigor` a `superpowers`.
- v0.1.0 (2026-05): Initial release. 7 skills (5 migradas del repo Booster + 2 nuevas) + 6 audit sub-agents migrados.

---

## License

MIT. See [LICENSE](LICENSE).

---

## Autor

[Felipe Vicencio](https://github.com/fueradelabox) — Booster Chile.
