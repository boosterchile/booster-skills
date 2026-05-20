---
name: booster-stack-conventions
description: Booster AI stack conventions enforcer. Use this skill whenever writing TypeScript code, tests, API endpoints, Zod schemas, structured logs, OpenTelemetry traces, or commits in the Booster AI project. Make sure to use this skill any time the user asks to implement, refactor, add, modify, or fix any code in the apps/api, apps/web, or packages/ directories — even for trivial-seeming changes — because the conventions (zero `any`, Zod in boundaries, @booster-ai/logger instead of console, OTel trace_id, coverage 80%, Conventional Commits with scope, Evidencia section in PRs) are non-negotiable contracts that prevent technical debt from accumulating.
---

# Skill: Booster Stack Conventions

**Categoría**: core-engineering + stack-discipline
**Prioridad**: alta — estas reglas son contratos, no sugerencias

## Overview

El stack de Booster AI (Node.js 22 serverless Cloud Run + Cloud SQL + React/Vite + pnpm 9 + Biome + Hono + Drizzle + OTel) tiene convenciones no-negociables. Esta skill las hace cumplir. No es opcional: cada vez que se toca código en el proyecto Booster, estas reglas aplican.

Filosofía: *"El agente quiere agradarte. Tomar atajos lo hace eficiente y útil. Tu trabajo es darle un entorno donde el atajo cueste más que el camino correcto."* — agent-rigor

## When to Use

Aplica a **toda escritura de código** en el proyecto Booster AI, incluyendo:

- Implementar un endpoint nuevo en `apps/api`
- Crear o modificar componentes en `apps/web`
- Modificar packages compartidos en `packages/*`
- Agregar tests (unit, integration, E2E)
- Editar Zod schemas en `packages/shared-schemas`
- Crear migrations Drizzle
- Cualquier `Edit` o `Write` que toque archivos `.ts`, `.tsx`, `.test.ts`, `.test.tsx`
- Cualquier commit message en este proyecto

**NO aplica** a:

- Documentación pura (`.md`)
- Cambios en infraestructura Terraform (ese tiene sus propias reglas en otro skill)
- Edición de archivos de configuración (`.env.example`, `package.json` deps, etc.)
- Trabajo en otros proyectos (esta skill es específica de Booster AI)

## Core Process

### 1. Type Safety end-to-end

**Zero `any`** — Biome lo prohíbe. Si TypeScript no infiere un tipo correctamente:

```typescript
// ❌ NUNCA
function process(data: any) { ... }

// ✅ SIEMPRE
import { z } from 'zod';
const InputSchema = z.object({ ... });
type Input = z.infer<typeof InputSchema>;
function process(data: Input) { ... }
```

**Zero `@ts-ignore`** y **zero `@ts-expect-error`** sin issue asociado en GitHub.

**Zero `as unknown as T`** — si necesitás castear, primero validá con Zod.

### 2. Validación en boundaries

Todo input externo pasa por Zod **antes** de tocar lógica:

- HTTP body, query params, headers — Zod en el handler.
- Variables de entorno — Zod en `packages/config/env.ts` (al startup).
- Payloads de Pub/Sub, Cloud Tasks — Zod en el consumer.
- Respuestas de APIs externas (terceros) — Zod en el cliente.
- Filas de BD que no garantizan shape (joins complejos, raw queries) — Zod opcional según riesgo.

```typescript
// ✅ Ejemplo handler Hono
import { z } from 'zod';
import { zValidator } from '@hono/zod-validator';

const TripCreateSchema = z.object({
  origin: z.object({ lat: z.number(), lng: z.number() }),
  destination: z.object({ lat: z.number(), lng: z.number() }),
  cargo_weight_kg: z.number().positive(),
});

app.post('/trips', zValidator('json', TripCreateSchema), async (c) => {
  const input = c.req.valid('json');  // ya tipado y validado
  // ...
});
```

### 3. Observabilidad obligatoria

**Zero `console.*`** — usar `@booster-ai/logger`:

```typescript
// ❌ NUNCA
console.log('User created', userId);
console.error('Failed', err);

// ✅ SIEMPRE
import { logger } from '@booster-ai/logger';
logger.info({ user_id: userId, event: 'user_created' }, 'User created');
logger.error({ err, context: 'trip_creation' }, 'Failed to create trip');
```

**Cada endpoint nuevo** debe tener:

1. Log estructurado al inicio con `trace_id` correlacionado.
2. Span OpenTelemetry que envuelve la operación.
3. Métrica custom si la operación es de **negocio** (no de infra). Ejemplos: `trips_created_total`, `matching_score_distribution`, `carbon_calculation_duration_seconds`. NO crear métrica para "endpoint hit count" — eso ya lo da Cloud Run.

**No silently swallow errors**: cada `catch` debe (a) loguear con contexto + (b) re-throw o (c) recovery explícito con métrica de error.

### 4. Testing

- **Coverage 80%+** en código nuevo (líneas, branches, funciones). Si baja, el PR no pasa CI.
- **Unit tests**: `*.test.ts` al lado del archivo (`src/foo.ts` → `src/foo.test.ts`).
- **Integration tests**: `test/integration/` por workspace. Levantan DB Postgres local.
- **E2E**: `pnpm --filter @booster-ai/web test:e2e`. Playwright. Solo flujos críticos.
- **Tests existen ANTES del commit del feature** (no después).

```typescript
// ✅ Unit test colocado
// src/services/matching.ts
// src/services/matching.test.ts

// ✅ Integration test
// apps/api/test/integration/trip-creation.integration.test.ts
```

### 5. Conventional Commits con scope

Formato: `<type>(<scope>): <summary>`

- `<type>`: `feat | fix | refactor | docs | test | chore | perf | style`
- `<scope>`: dominio del cambio. Ejemplos válidos: `matching`, `telemetry`, `auth`, `web`, `api`, `infra`, `db`, `carbon`.
- `<summary>`: en español, imperativo, ≤72 chars.

```
✅ feat(matching): add proximity boost factor
✅ fix(auth): refresh token rotation race condition
✅ refactor(carbon): extract emission factors to shared package
✅ docs(adr): add ADR-052 terraform multi-env

❌ feat: stuff                              (sin scope)
❌ feat(matching) added proximity boost     (sin :, sin verbo)
❌ fix(auth): fixed the thing               (vago)
❌ feat(matching): Added proximity boost factor in algorithm because users asked for it (largo, en pasado)
```

**Squash merges** a `main` con mensaje claro. Nada de "WIP" o "checkpoint" llegando a main.

### 6. PRs con sección Evidencia obligatoria

Cada PR debe incluir una sección llamada exactamente `## Evidencia` con:

- Output de tests relevantes (`pnpm test` o test concreto)
- Screenshots si hay UI
- Curl trace si hay endpoint API
- ADR compliance checklist si aplica
- Output de `pnpm ci` final

```markdown
## Evidencia

### Tests
\`\`\`
$ pnpm --filter @booster-ai/api test
✓ src/services/matching.test.ts (12 tests) 245ms
  Tests:  12 passed
  Coverage: 87.3% lines, 84.1% branches
\`\`\`

### Endpoint
\`\`\`
$ curl -X POST https://staging.booster-ai.com/api/trips ...
{ "trip_id": "trip_abc123", "matched_carriers": [...] }
\`\`\`

### ADR compliance
- [x] ADR-001 stack: usa Hono + Zod + Drizzle
- [x] ADR-050 OTel: span agregado en `matching.ts:42`
- [x] Coverage 80%+ ✓
```

Sin sección Evidencia, el PR no se mergea.

## Anti-rationalizations

| Tentación | Por qué es error |
|---|---|
| "Uso `any` aquí porque el tipo es complicado" | Los tipos complicados son los que MÁS necesitan tipado estricto |
| "Agrego los tests después del PR" | Nunca llega ese momento |
| "Skippeo el log estructurado en este endpoint trivial" | No existen endpoints triviales en producción |
| "Hago commit grande para no fragmentar" | Los commits grandes hacen reviews malos y rollbacks imposibles |
| "Uso console.log temporalmente, lo saco antes del merge" | Llega a producción el 80% de las veces |
| "Pongo el secreto en .env solo para esta tarea" | Termina committed; usar Secret Manager siempre |
| "No agrego Zod aquí porque el caller ya validó" | El caller cambia mañana; defense in depth |

## Exit criteria (al cerrar una tarea)

- [ ] Sin `any` ni `@ts-ignore` nuevos
- [ ] Sin `console.*` nuevos
- [ ] Todo input externo nuevo pasa por Zod schema
- [ ] Endpoints nuevos tienen log + span OTel + métrica si aplica
- [ ] Tests escritos (unit + integration si toca BD) y pasando
- [ ] Coverage 80%+ en código tocado
- [ ] Commits Conventional con scope correcto
- [ ] PR tiene sección Evidencia completa
- [ ] `pnpm ci` pasa en CI (lint + typecheck + test + coverage + build)

## Cuando algo no cuadra

Si una de estas reglas parece bloquear progreso, **PARÁ y escalá al PO**. No improvises. Las reglas existen por razones específicas; saltearlas requiere waiver explícito documentado en `.claude/ledger/`.

Excepciones legítimas son raras. Ejemplos válidos: bug crítico en producción que requiere hotfix en <1h (waiver: hotfix-crítico, regularizar en 24h con PR de cleanup).
