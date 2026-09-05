---
name: adding-cloud-run-service
description: Scaffold de un servicio Cloud Run nuevo en el monorepo Booster AI con observabilidad, seguridad y ops-readiness desde day 0. Use when creating a new Cloud Run service, extracting a bounded context out of apps/api, or adding a Pub/Sub consumer that needs its own runtime — covers directory layout, Zod env parsing, Dockerfile pattern, Terraform module, CI, runbook stub. Not for adding an endpoint to an existing service or a shared package.
---

# Skill: Adding a Cloud Run Service

**Categoría**: core-engineering
**Relacionado**: ADR-001 stack, ADR-005 telemetría, ADR-065/071 (gateway en GKE), skill `incident-response`, skill `booster-stack-conventions`

## Overview

Booster AI tiene 9 apps en `apps/`: 8 en Cloud Run (api, web, matching-engine, telemetry-processor, notification-service, whatsapp-bot, document-service, sms-fallback-gateway) y `telemetry-tcp-gateway` en GKE Autopilot (conexiones TCP persistentes de Teltonika; ADR-065). Añadir un servicio nuevo requiere un proceso que garantiza observabilidad, seguridad y ops-readiness desde day 0. Crear un servicio es una decisión de arquitectura: requiere ADR y aprobación del PO (`CLAUDE.md` §Frontera de decisiones).

## When to Use

- Nuevo bounded context que justifica su propio servicio (ver criterios en Techniques)
- Extracción de un bounded context existente desde `apps/api`
- Nuevo consumer de Pub/Sub que necesita runtime dedicado

**NO crear servicio nuevo** cuando:
- Es un endpoint más en un servicio existente
- Es lógica que cabe como package compartido
- Es un script one-off (usar Cloud Run Jobs o Cloud Function)

## Core Process

### 1. Justificar con ADR corto o sección en ADR existente

En 1-2 párrafos: por qué este bounded context justifica servicio dedicado. Criterios válidos:
- Throughput muy distinto al resto (ej. TCP gateway con 1000 conexiones persistentes)
- Lifecycle de deploy independiente (ej. updates críticos del whatsapp-bot sin redeploy de api)
- Perfil de escalado muy distinto (ej. matching-engine picos cortos vs api sostenido)
- Perfil de seguridad distinto (ej. document-service con acceso a KMS + retention locks)

Registrar en ADR-001 Amendment o ADR nuevo.

### 2. Crear estructura del servicio

```
apps/<service-name>/
├── package.json              # deps mínimas, extends root
├── tsconfig.json             # extends tsconfig.base.json
├── Dockerfile                # multi-stage build
├── src/
│   ├── main.ts               # entry point, bootstrap
│   ├── server.ts             # Hono instance (o equivalente)
│   ├── config.ts             # env parsing con Zod
│   ├── routes/               # endpoints
│   ├── services/             # lógica de negocio
│   ├── middleware/
│   │   ├── logging.ts        # Pino request logger
│   │   ├── tracing.ts        # OpenTelemetry
│   │   └── auth.ts           # Firebase Admin verify
│   └── health.ts             # /health + /ready endpoints
├── test/
│   ├── unit/
│   └── integration/
└── README.md                 # qué hace, cómo ejecutar local
```

### 3. Dependencias estándar (sin negociar)

Desde day 0, el servicio debe importar:
- `@booster-ai/logger` — logging estructurado Pino
- `@booster-ai/shared-schemas` — Zod schemas
- `@booster-ai/config` — env parsing
- `@booster-ai/otel-bootstrap` — SDK OTel cargado con `node --import` antes de `main` (exporta a Cloud Trace vía ADC, con `RedactingSpanExporter`); copiar el patrón `src/instrumentation.ts` de `apps/telemetry-tcp-gateway`

### 4. Endpoints obligatorios

- `GET /health` — liveness probe, retorna 200 si el proceso está vivo
- `GET /ready` — readiness probe, retorna 200 si puede aceptar tráfico (BD conectada, Redis conectado, etc.)
- `GET /metrics` — (si se usa Prometheus format) — endpoint para scraping

### 5. Variables de entorno con Zod

```typescript
// src/config.ts
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'staging', 'production']),
  PORT: z.coerce.number().default(8080),
  LOG_LEVEL: z.enum(['trace', 'debug', 'info', 'warn', 'error']).default('info'),
  DATABASE_URL: z.string().url().optional(),
  // ... específicas del servicio
});

export const config = envSchema.parse(process.env);
```

Parse al arranque. Si falla, el servicio muere con error claro (no arranca con config inválida).

### 6. Dockerfile

No escribir uno desde cero: **copiar `apps/api/Dockerfile`** (o `apps/whatsapp-bot/Dockerfile`, que documenta el rationale) y adaptar los `COPY` de `package.json` de los packages que el servicio importa. Invariantes del patrón vigente:

- `FROM node:24-alpine` (Node 24, `.nvmrc`), `corepack enable`.
- Stage `deps` copia solo los `package.json` de los workspaces necesarios + lockfile, luego `pnpm install --frozen-lockfile`.
- Stage `build` compila con `pnpm --filter @booster-ai/<service> build`.
- Runtime se arma con `pnpm --prod deploy --legacy` (pnpm 10 cambió el default; sin `--legacy` falla con `ERR_PNPM_DEPLOY_NONINJECTED_WORKSPACE`, ADR-075).
- `USER node`, `ENV NODE_ENV=production`, `EXPOSE 8080`.
- Cada package con deps nativas/wasm que el bundler deja como `external` necesita su `package.json` copiado en `deps` (ver comentarios F4/P2 en `apps/api/Dockerfile`).

El check "Docker build + smoke" de CI construye la imagen; `pnpm ci` local **no** lo cubre. Correr `docker build` local antes del PR.

### 7. Terraform module

La infra es plana en `infrastructure/*.tf` (no hay `environments/<env>/`). Añadir el servicio en `infrastructure/compute.tf` usando el módulo existente:

```hcl
module "<service_name>" {
  source = "./modules/cloud-run-service"

  project_id       = var.project_id
  region           = var.region
  service_name     = "<service-name>"
  service_account  = google_service_account.cloud_run_sa.email
  container_image  = "${var.artifact_registry}/<service-name>:${var.image_tag}"
  min_instances    = 0  # o 1 si requiere warm
  max_instances    = 10
  concurrency      = 80
  cpu              = "1"
  memory           = "512Mi"

  secrets = {
    DATABASE_URL = google_secret_manager_secret.db_url.id
    # ...
  }

  env_vars = {
    LOG_LEVEL = "info"
  }
}
```

### 8. Tests mínimos

- `test/unit/*.test.ts` — cobertura de lógica pura (≥80%)
- `test/integration/health.test.ts` — que `/health` y `/ready` respondan correctamente
- `test/integration/<endpoint>.test.ts` — al menos 1 test por endpoint público
- **Todos** los tests determinísticos — sin `setTimeout`, sin dependencia de red externa (mocks con MSW)

### 9. CI actualizado

Leer `.github/workflows/ci.yml` y `cloudbuild.production.yaml` antes de tocar: el job de Docker build + smoke hoy cubre `api` y tiene un follow-up para el resto vía matrix. Añadir el servicio donde corresponda y verificar que `release.yml` / Cloud Build lo despliegue. Los quality gates de CI son archivos protegidos (`CLAUDE.md`): el cambio se propone al PO, no se aplica solo.

### 10. Observability config

- Log structured con `service=<service-name>` default field
- OTel tracer con service name correcto para que aparezca en Cloud Trace bajo etiqueta clara
- Custom metrics si hay operaciones de negocio (ej. `trips_matched_total`, `documents_emitted_total`)

### 11. Runbook stub

Crear `docs/runbooks/<service-name>-operations.md` con secciones placeholder:
- Health check manual
- Cómo ver logs en Cloud Logging
- Cómo deployar manualmente (rollback)
- SLOs de este servicio
- On-call escalation path

Este runbook se completa a medida que el servicio madure.

## Anti-rationalizations

| Tentación | Por qué es un error |
|-----------|---------------------|
| "No añado /ready porque la app es simple" | Cloud Run necesita distinguir liveness de readiness para updates zero-downtime. |
| "Skippeo OTel, lo agrego después" | Nunca se agrega después. Observability desde day 0. |
| "Env vars con `process.env.FOO` directo, sin Zod" | Env inválida crasheando a medio request es peor que al arranque. |
| "Sin runbook, es obvio cómo operarlo" | En un incidente a las 3am, nada es obvio. |

## Red Flags

- Un servicio nuevo sin entradas en Cloud Monitoring (dashboards, alertas)
- Un servicio nuevo sin referencia en `docs/runbooks/`
- Env parsing que no usa Zod
- Dockerfile sin `USER` no-root
- Min instances > 0 sin justificación (costo desperdiciado)

## Exit Criteria

- [ ] ADR (o amendment) justifica la existencia del servicio
- [ ] Estructura de carpetas según convención
- [ ] Dependencias obligatorias (`logger`, `shared-schemas`, `config`, OTel) presentes
- [ ] Endpoints `/health` y `/ready` implementados y testeados
- [ ] Env parsing con Zod, crash al arranque si inválido
- [ ] Dockerfile multi-stage con usuario no-root
- [ ] Terraform module agregado y `terraform plan` limpio
- [ ] Tests unitarios + integración con coverage ≥80%
- [ ] CI matrix incluye el nuevo servicio
- [ ] Pino logs con `service` field + OTel tracer configurado
- [ ] Runbook stub en `docs/runbooks/`
- [ ] README del servicio explica qué hace y cómo correrlo local
- [ ] Deploy a staging exitoso, health check verde

## Referencias

- ADR-001 (stack), ADR-005 (telemetría IoT), ADR-065 (gateway GKE), ADR-075 (pnpm 10, `pnpm deploy --legacy`) en `docs/adr/` de `booster-ai`
- `infrastructure/modules/cloud-run-service/` (módulo Terraform vigente)
- Cloud Run best practices: https://cloud.google.com/run/docs/tips/general
- skill `booster-stack-conventions` (reglas no-negociables del stack)
- skill `booster-deploy-cloud-run` (flow de deploy)
- skill `incident-response` (runbook scaffolding al promover a prod)
