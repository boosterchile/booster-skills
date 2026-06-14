# booster-skills

**Booster AI domain pack for Claude Code.** Companion to `superpowers`.

Senior-engineering discipline (`superpowers`) provides the generic cycle: brainstorming → spec/plan → TDD → verification-before-completion → subagent-driven review. This plugin provides the **domain knowledge, stack conventions, deploy workflow, audit sub-agents, and an observational ledger** specific to the Booster AI logistics platform on Google Cloud. (Hasta v0.2.0 era companion de `agent-rigor`, retirado en ADR-060.)

---

## Contenido

### 9 Skills

| Skill | Cuándo se activa |
|---|---|
| `arquitecto-maestro` | Misiones complejas que cruzan múltiples apps/packages, requieren ADR, o combinan dimensiones architecture/security/performance/compliance |
| `adding-cloud-run-service` | Crear un nuevo servicio Cloud Run desde cero con observabilidad + seguridad + ops-readiness desde day 0 |
| `carbon-calculation-glec` | Cálculos GLEC v3.0 + GHG Protocol; factores de emisión; certificados ESG |
| `empty-leg-matching` | Matching algoritmo carriers-CargoRequest; scoring transparente y auditable |
| `incident-response` | Cuando algo falla en producción: detectar → estabilizar → entender |
| `booster-stack-conventions` | Cada vez que se escribe código TS/test/endpoint/schema/log en el proyecto Booster |
| `booster-deploy-cloud-run` | Deploy de servicios Booster (Cloud Build staging → manual approval prod → monitoreo 2h) |
| `definicion-de-terminado` | Estándar de Definición de Terminado anti-parches (antes de declarar listo / commitear / abrir PR) |
| `tdd-dominio-critico` | TDD obligatorio en dominio crítico (DTE/SII, factoring, pricing, GLEC, matching, migraciones, auth) |

### 7 Sub-agents (auditoría arquitectónica)

| Agent | Modelo | Propósito |
|---|---|---|
| `dependency-auditor` | haiku | Auditar dependencias (pnpm audit, licencias, vulnerabilities) |
| `explore-architecture` | haiku | Exploración top-down de la arquitectura de un codebase |
| `performance-analyzer` | sonnet | Análisis de rendimiento (bottlenecks, N+1, latencia, bundle size) |
| `refactor-advisor` | opus | Síntesis transversal y priorización (consume outputs de los otros 5) |
| `security-scanner` | sonnet | Seguridad estática (auth, secrets, IAM, headers, OWASP) **+ compliance Chile** (Ley 19.628, SII/DTE, RBAC por rol, consent ESG) |
| `tech-debt-detector` | haiku | Detectar deuda técnica (any, ts-ignore, TODOs, localhost, mocks, console) |
| `sre-oncall` | sonnet | Revisor SRE **pre-merge** (observabilidad, rollback, SLO, capacity, costos, deps externas) |

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

## Integración con superpowers

Este plugin es **companion de `superpowers`** (capa de disciplina genérica). Hasta v0.2.0 fue companion de `agent-rigor`, retirado en ADR-060 (su gate bash de enforcement no era operativo de facto). Instalar ambos:

```bash
/plugin install superpowers@claude-plugins-official
/plugin marketplace add boosterchile/booster-skills
/plugin install booster-skills@booster-skills
/plugin list   # debe mostrar AMBOS plugins habilitados
```

Distribución de responsabilidades:

| Responsabilidad | Plugin |
|---|---|
| Brainstorming → spec → plan → build → verify → review | `superpowers` |
| TDD iron-law + verificación antes de declarar terminado | `superpowers` |
| Subagent-driven-development (review de spec + calidad por tarea) | `superpowers` |
| Estándar de Terminado anti-parches (Definición de Terminado) | `booster-skills` (skill `definicion-de-terminado`) |
| TDD obligatorio en dominio crítico (DTE, factoring, pricing…) | `booster-skills` (skill `tdd-dominio-critico`) |
| Stack Booster (Zod, Biome, Logger, OTel, coverage 80%) | `booster-skills` (este plugin) |
| Dominio Booster (carbon GLEC, empty-leg matching) | `booster-skills` |
| Deploy Booster (Cloud Run + Cloud Build + monitoreo 2h) | `booster-skills` |
| Sub-agents de auditoría + SRE pre-merge | `booster-skills` (7 sub-agents) |
| Orquestación cross-cutting (arquitecto-maestro) | `booster-skills` |
| Ledger observacional + scorecard semanal (sin gates) | `booster-skills` (hooks) |

Path canónico de specs: `.specs/<feature-slug>/{spec,plan,verify,review,ship}.md` (convención del proyecto Booster; ya no la impone un hook).

---

## Stack soportado

Este plugin está optimizado para el stack canónico de Booster AI:

- **Runtime**: Node.js 22+
- **Compute**: Google Cloud Run (serverless containers)
- **Database**: Google Cloud SQL Postgres + pg driver
- **Frontend**: React 18 + Vite 6 + TypeScript + @tanstack/react-router + Tailwind 4
- **Package manager**: pnpm 9
- **Monorepo**: Turborepo
- **Linter/formatter**: Biome 1.9
- **HTTP framework**: Hono 4
- **ORM**: Drizzle (cuando aplica)
- **Telemetría**: OpenTelemetry + Pino + Google Cloud Trace/Monitoring
- **IaC**: Terraform (multi-environment)
- **CI/CD**: Google Cloud Build
- **Auth**: JWT Zero-Trust (per ADR-001)
- **Carbon framework**: GLEC v3.0 + GHG Protocol
- **Telemetría IoT**: Teltonika Codec 8 + Pub/Sub

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

- v0.3.0 (2026-06): Consolidación de overrides locales de `booster-ai`. `security-scanner` extendido con compliance Chile, nuevo sub-agent `sre-oncall`, ADR-compliance plegado en `booster-stack-conventions`. 9 skills + 7 audit sub-agents.
- v0.2.0 (2026-06): Rescate de disciplina post-ADR-060. +2 skills (`definicion-de-terminado`, `tdd-dominio-critico`) + ledger observacional. Companion pasa de `agent-rigor` a `superpowers`.
- v0.1.0 (2026-05): Initial release. 7 skills (5 migradas del repo Booster + 2 nuevas) + 6 audit sub-agents migrados.

---

## License

MIT. See [LICENSE](LICENSE).

---

## Autor

[Felipe Vicencio](https://github.com/fueradelabox) — Booster Chile.
