---
name: booster-deploy-cloud-run
description: Booster AI Cloud Run deployment workflow. Use this skill whenever the user wants to deploy, ship, release, promote, or roll out code from the Booster AI project to staging or production environments. Make sure to use this skill any time the user mentions Cloud Build, staging deploy, production promotion, rollback, smoke tests, or post-deploy monitoring — even when invoked indirectly through `/agent-rigor:ship`. This skill handles the Booster-specific deployment cycle (Cloud Build staging auto → manual approval prod → 2h monitoring) that complements agent-rigor's generic 12-point ship checklist.
---

# Skill: Booster Deploy to Cloud Run

**Categoría**: operations + deploy
**Prioridad**: crítica — ejecutar mal un deploy rompe producción

## Overview

Booster AI corre como ~8 servicios Cloud Run en GCP (project `booster-ai-494222`, region `southamerica-west1`). El flujo de deploy es:

1. **Staging automático** vía Cloud Build trigger en merge a `main`.
2. **Smoke test staging** (manual o vía script).
3. **Manual approval** en Cloud Build para promover a producción.
4. **Production rollout** progresivo si feature flags.
5. **Monitoreo 2 horas post-deploy** (error rate, latency P95, logs limpios).

Esta skill complementa el `/agent-rigor:ship` 12-point checklist con las especificidades del deploy Booster.

## When to Use

Activar cuando:

- Se ejecute `/agent-rigor:ship <feature-slug>` en proyecto Booster
- Usuario mencione "deploy", "release", "promover a prod", "shipear", "merge to main"
- Se prepare un hotfix de producción
- Se ejecute un rollback
- Se planifique un cambio que toca infraestructura productiva (Cloud Run service, Cloud SQL, etc.)

**NO activar** para:

- Cambios solo en branches feature (sin merge a main aún)
- Cambios solo en documentación o tests sin lógica
- Trabajo local (`pnpm dev`)
- Despliegues de otros proyectos (no Booster)

## Core Process

### 1. Pre-flight checks (antes de mergear a main)

Verificar todos estos puntos. Cualquier `NO` bloquea el deploy:

- [ ] CI verde en el último commit del PR (lint + typecheck + test + coverage 80%+ + build)
- [ ] `/agent-rigor:review` produjo `Approved for /ship` en `.specs/<feature>/review.md`
- [ ] Devils-advocate pass de irreversibilidad ejecutado
- [ ] Rollback plan documentado en `ship.md`
- [ ] Sin secretos en código (`gitleaks` o equivalente)
- [ ] Sin API keys nuevas sin restricciones IP/referrer en GCP
- [ ] Sin dependencias nuevas sin `pnpm audit` clean (o issue de tracking)
- [ ] Logs estructurados en endpoints nuevos (verificable con grep)
- [ ] Métricas custom definidas si hay operación de negocio nueva
- [ ] Alertas configuradas si el cambio introduce SLO nuevo
- [ ] Si involucra migración BD: down migration probada
- [ ] Si involucra feature flag: está OFF por default

### 2. Merge a main

```bash
gh pr merge <PR_NUMBER> --squash --delete-branch
```

Mensaje del commit: respeta Conventional Commits con scope. La descripción del PR (incluyendo sección Evidencia) queda en el body del squash commit.

### 3. Cloud Build staging trigger (automático)

Al mergear a `main`, Cloud Build dispara automáticamente:

```
trigger: booster-ai-staging
substitutions: _ENV=staging
```

Verificar el build:

```bash
gcloud builds list --filter="substitutions._ENV=staging" --limit=5
gcloud builds log <BUILD_ID>
```

**Si el build falla**: NO continuar al manual approval. Investigar logs, ejecutar hotfix.

### 4. Smoke test staging

Antes de promover a prod, smoke test el servicio en staging:

```bash
# Health check
curl -fsS https://staging-api.booster-ai.com/health
# Expected: {"status":"ok","version":"vX.Y.Z","trace_id":"..."}

# Endpoint específico del feature recién shipeado
curl -fsS -H "Authorization: Bearer <staging_test_token>" \
  https://staging-api.booster-ai.com/api/<endpoint-tocado>
# Inspeccionar response

# Si hay UI, abrir manualmente:
open https://staging.booster-ai.com
# Flujo crítico end-to-end relacionado al cambio
```

**Si el smoke test detecta regresión**: NO promover a prod. Rollback en staging vía Cloud Run revision rollback:

```bash
gcloud run services update-traffic <SERVICE> \
  --region=southamerica-west1 \
  --to-revisions=<PREVIOUS_REVISION>=100
```

### 5. Manual approval en Cloud Build (promoción a prod)

```bash
# Listar builds pendientes de approval
gcloud builds triggers list --filter="filename:cloudbuild-prod.yaml"

# Aprobar en la UI de Cloud Build (recomendado, deja audit trail visible)
open "https://console.cloud.google.com/cloud-build/builds?project=booster-ai-494222"

# O vía CLI
gcloud builds approve <BUILD_ID>
```

**NO aprobar viernes después de las 16:00 hora Chile** salvo waiver explícito y plan de sábado.

### 6. Production rollout

Si NO hay feature flag, el deploy es atómico (Cloud Run revision swap):

```bash
gcloud run services describe <SERVICE> --region=southamerica-west1 --format="value(status.url,status.latestReadyRevisionName)"
```

Si HAY feature flag, rollout progresivo:

```
1%  → monitorear 15 min
10% → monitorear 30 min
50% → monitorear 30 min
100% → monitorear 1 hora
```

Cada step verificar:

- `error_rate` no sube
- `latency_p95` no sube
- Logs sin spike de errores nuevos

### 7. Monitoreo 2h post-deploy

Durante las primeras **2 horas** post-deploy, monitoreo activo:

```bash
# Error rate (debe estar dentro de baseline)
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="<SERVICE>" AND severity>=ERROR' \
  --limit=50 --format=json --freshness=2h

# Latency P95 (dashboard Cloud Monitoring)
open "https://console.cloud.google.com/monitoring/dashboards/builder/<DASHBOARD_ID>?project=booster-ai-494222"

# Trazas OTel con errores
# (vía Cloud Trace UI o exporter custom)
```

Si en cualquier momento detectás:

- Error rate sube >2x baseline durante >5 min → rollback inmediato
- Latency P95 sube >50% durante >10 min → rollback inmediato
- Aparecen errores nuevos en logs no presentes en staging → investigar; si no se entiende en <30 min → rollback
- Alertas configuradas se disparan → seguir runbook de incidente (skill `incident-response`)

### 8. Actualizar spec con evidencia de ship

En `.specs/<feature-slug>/ship.md`, agregar:

```markdown
## Ship evidence

- Date: 2026-MM-DDTHH:MM:SSZ
- Version: vX.Y.Z
- Commit SHA: <sha>
- Cloud Run revision (staging): <revision_name>
- Cloud Run revision (prod): <revision_name>
- Build ID: <build_id>
- Approver: Felipe Vicencio
- Rollout strategy: <atomic | flag-progressive>
- Monitoring window: 2h, completed [✓|✗]
- Incidents during window: [none | description + link]
```

### 9. Schedule 24h self-postmortem

Recordatorio en 24h: tres líneas en `ship.md`:

```markdown
## 24h postmortem (filled 2026-MM-DD)

- **What worked**: (1 line)
- **What surprised**: (1 line)
- **What I'd do differently**: (1 line)
```

Esto alimenta el benchmark de agent-rigor (`bash ~/.claude/plugins/.../benchmark/scripts/collect-metrics.sh`).

## Anti-rationalizations

| Tentación | Por qué es error |
|---|---|
| "Es viernes pero lo mergeo igual" | Los despliegues viernes sin on-call son la causa #1 de incidentes de fin de semana |
| "Smoke test ya lo hice en mi máquina, no necesito staging" | Tu máquina ≠ staging ≠ prod. Tres ambientes distintos, tres comportamientos posibles |
| "El monitoreo lo dejo para mañana" | Las primeras 2h post-deploy son críticas; mañana ya tenés sesgo de "todo está bien" |
| "Skippeo el rollback plan, no creo que sea necesario" | El 5% de los deploys falla. El plan de rollback es lo único que evita que sea crisis |
| "El cambio es pequeño, no necesita manual approval" | Los cambios "pequeños" son los que rompen producción más a menudo (cambios grandes tienen más review) |
| "Promociono a prod sin monitorear staging porque hay urgencia" | La urgencia no anula la física de los sistemas; si rompe, romperá más caro |

## Rollback procedure

Si necesitás rollback en producción:

```bash
# 1. Identificar revisión anterior estable
gcloud run revisions list --service=<SERVICE> --region=southamerica-west1 --limit=10

# 2. Cambiar tráfico a la revisión anterior
gcloud run services update-traffic <SERVICE> \
  --region=southamerica-west1 \
  --to-revisions=<PREVIOUS_REVISION>=100

# 3. Verificar
curl -fsS https://api.booster-ai.com/health
# Debe responder con version anterior

# 4. Si hay migración BD problemática:
# (consultar runbook específico; las migrations Booster son backwards-compatible por contrato)

# 5. Documentar en .specs/<feature>/ship.md sección "Rollback"
```

## Exit criteria (deploy completo)

- [ ] Mergeado a main con squash
- [ ] Cloud Build staging green
- [ ] Smoke test staging passed (curl health + flujo crítico)
- [ ] Manual approval otorgado en Cloud Build
- [ ] Cloud Run prod revision live (verificable con `gcloud run services describe`)
- [ ] 2h monitoring sin incidentes
- [ ] `ship.md` actualizado con evidence
- [ ] Tag git creado: `git tag vX.Y.Z && git push --tags`
- [ ] GitHub release creado: `gh release create vX.Y.Z --generate-notes`
- [ ] 24h postmortem scheduled (recordatorio agendado)

## Cuando algo no cuadra

Si detectás algo raro durante el deploy (cualquier paso del 1 al 9), **PARÁ y escalá al PO**. Es mejor demorar un deploy 4 horas que arreglar una outage de 4 días.

Para incidentes activos en producción, activar skill `incident-response` (también en booster-skills).
