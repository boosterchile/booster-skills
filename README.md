# booster-skills

**Booster AI domain pack for Claude Code.** Companion to `agent-rigor`.

Senior-engineering discipline (`agent-rigor`) provides the cycle: Define → Plan → Build → Verify → Review → Ship. This plugin provides the **domain knowledge, stack conventions, deploy workflow, and audit sub-agents** specific to the Booster AI logistics platform on Google Cloud.

---

## Contenido

### 7 Skills

| Skill | Cuándo se activa |
|---|---|
| `arquitecto-maestro` | Misiones complejas que cruzan múltiples apps/packages, requieren ADR, o combinan dimensiones architecture/security/performance/compliance |
| `adding-cloud-run-service` | Crear un nuevo servicio Cloud Run desde cero con observabilidad + seguridad + ops-readiness desde day 0 |
| `carbon-calculation-glec` | Cálculos GLEC v3.0 + GHG Protocol; factores de emisión; certificados ESG |
| `empty-leg-matching` | Matching algoritmo carriers-CargoRequest; scoring transparente y auditable |
| `incident-response` | Cuando algo falla en producción: detectar → estabilizar → entender |
| `booster-stack-conventions` | Cada vez que se escribe código TS/test/endpoint/schema/log en el proyecto Booster |
| `booster-deploy-cloud-run` | Deploy de servicios Booster (Cloud Build staging → manual approval prod → monitoreo 2h) |

### 6 Sub-agents (auditoría arquitectónica)

| Agent | Modelo | Propósito |
|---|---|---|
| `dependency-auditor` | haiku | Auditar dependencias (pnpm audit, licencias, vulnerabilities) |
| `explore-architecture` | haiku | Exploración top-down de la arquitectura de un codebase |
| `performance-analyzer` | sonnet | Análisis de rendimiento (bottlenecks, N+1, latencia, bundle size) |
| `refactor-advisor` | opus | Síntesis transversal y priorización (consume outputs de los otros 5) |
| `security-scanner` | sonnet | Escanear superficie de seguridad (auth, secrets, IAM, headers, OWASP) |
| `tech-debt-detector` | haiku | Detectar deuda técnica (any, ts-ignore, TODOs, localhost, mocks, console) |

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

## Integración con agent-rigor

Este plugin asume que `agent-rigor` está instalado y activo:

```bash
/plugin marketplace add boosterchile/best-skill-claude
/plugin install agent-rigor@agent-rigor
/plugin list   # debe mostrar AMBOS plugins habilitados
```

Distribución de responsabilidades:

| Responsabilidad | Plugin |
|---|---|
| Ciclo Define → Plan → Build → Verify → Review → Ship | `agent-rigor` |
| Comandos `/agent-rigor:*` (spec, plan, build, test, review, ship, design, code-simplify, benchmark) | `agent-rigor` |
| Enforcement hooks (anti-racionalización, ciclo forzado) | `agent-rigor` |
| Sub-agents del ciclo (code-reviewer, devils-advocate, security-auditor, test-engineer, ux-designer) | `agent-rigor` |
| Session ledger en `.claude/ledger/<sessionId>.jsonl` | `agent-rigor` |
| 22 skills numeradas (00-using-this-pack a 64-shipping-and-launch) | `agent-rigor` |
| Stack Booster (Zod, Biome, Logger, OTel, coverage 80%) | `booster-skills` (este plugin) |
| Dominio Booster (carbon GLEC, empty-leg matching) | `booster-skills` |
| Deploy Booster (Cloud Run + Cloud Build + monitoreo 2h) | `booster-skills` |
| Sub-agents de auditoría arquitectónica | `booster-skills` (6 sub-agents) |
| Orquestación cross-cutting (arquitecto-maestro) | `booster-skills` |

Path canónico de specs: `.specs/<feature-slug>/{idea,spec,plan,verify,review,ship}.md` (definido por agent-rigor).

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

- v0.1.0 (2026-05): Initial release. 7 skills (5 migradas del repo Booster + 2 nuevas) + 6 audit sub-agents migrados.

---

## License

MIT. See [LICENSE](LICENSE).

---

## Autor

[Felipe Vicencio](https://github.com/fueradelabox) — Booster Chile.
