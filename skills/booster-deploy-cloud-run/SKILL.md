---
name: booster-deploy-cloud-run
description: Deploy a producción de Booster AI en Cloud Run (proyecto booster-ai-494222, southamerica-west1). Use when deploying, releasing, promoting a canary, rolling back, or monitoring a Cloud Run revision of the Booster AI project. Covers the real flow — `gh workflow run release.yml` → gate humano → Cloud Build canary 1 % / 30 min → 100 % → monitoreo 2 h — and the rollback procedure. No existe staging.
---

# Skill: Booster Deploy to Cloud Run

**Categoría**: operations + deploy
**Prioridad**: crítica — ejecutar mal un deploy rompe producción

## Overview

Booster AI corre como 9 apps: 8 servicios Cloud Run + `telemetry-tcp-gateway` en GKE Autopilot (ADR-065/071), todo en el proyecto GCP `booster-ai-494222`, región `southamerica-west1`.

Hechos del flujo real (verificados contra `main` de `booster-ai`, 2026-09):

1. **No hay staging.** La infra Terraform solo crea `prod`; el backlog `#STAGING-ENV` lo trackea. El nightly E2E (`e2e-staging.yml`) pega a prod — deuda declarada en `CLAUDE.md`.
2. **Un merge a `main` NO despliega.** Desde 2026-07-10 `release.yml` es `workflow_dispatch`-only. El deploy se dispara a mano: `gh workflow run release.yml --ref main`.
3. **Gate humano**: el job `deploy-production` corre bajo el GitHub Environment `production`; el PO aprueba en la UI de Actions. Antes de desplegar, el job espera el check `CI Success` del mismo SHA y aborta si CI falló.
4. **Canary en Cloud Build** (`cloudbuild.production.yaml`): despliega la revisión con tag `canary-signup-<sha>` sin tráfico → 1 % del tráfico → duerme 30 min → `canary-verify` (error rate y p95 vía Monitoring API) → promueve a 100 % (`update-traffic --to-latest`). El job tiene `timeout-minutes: 75` por esto.
5. **Monitoreo 2 h post-deploy** (error rate, latency P95, logs limpios).
6. **Versionado**: lo hace `changesets` dentro de `release.yml` (`pnpm changeset version/publish`). No crear tags ni releases a mano.

Aplica el contrato de `CLAUDE.md`: deploys y activaciones en prod son decisión del PO, no de Claude. Esta skill prepara, verifica y monitorea; la aprobación del gate la da el humano.

## When to Use

- El PO pide desplegar, "shipear", promover o hacer rollback en producción.
- Se prepara un hotfix de producción.
- Se planifica un cambio que toca infraestructura productiva (Cloud Run, Cloud SQL, Terraform).

**No aplica** a: cambios en ramas feature sin merge, cambios solo de docs o tests, trabajo local (`pnpm dev`), otros proyectos.

## Core Process

### 1. Pre-flight (antes del `workflow run`)

Cualquier `NO` bloquea el deploy:

- [ ] `main` contiene el squash del PR y el check `CI Success` está verde en ese SHA.
- [ ] El PR tenía sección `## Evidencia` completa (tests, lint, typecheck, build, curl/screenshots).
- [ ] `.specs/<slug>/ship.md` existe con **plan de rollback** escrito.
- [ ] Sin secretos en código (`pnpm security:scan` = gitleaks limpio).
- [ ] Deps nuevas con `pnpm audit --audit-level=high --prod` en 0, o issue de tracking.
- [ ] Endpoints nuevos tienen log estructurado + span OTel + métrica de negocio (verificable con grep).
- [ ] Alerta configurada si el cambio introduce un SLO nuevo (`infrastructure/slo.tf`, `monitoring.tf`).
- [ ] Si hay migración de BD: es expand-only o su rollback está probado (ADR-066). Migraciones `contract` llevan lista de verificación previa + dry-run con salida registrada (ADR-076).
- [ ] Si hay feature flag: está OFF por default.
- [ ] Si toca `terraform apply` en prod: plan revisado y guardado; `apply` es acción irreversible con gate de evidencia previa (ADR-076).
- [ ] No es viernes después de las 16:00 hora Chile, salvo waiver explícito del PO y plan de sábado.

### 2. Disparar el release

```bash
gh workflow run release.yml --ref main
gh run list --workflow=release.yml --limit=3      # obtener el run id
gh run watch <RUN_ID>                              # o seguir en la UI de Actions
```

El run se detiene en el Environment `production` esperando aprobación humana. **Claude no aprueba el gate**; avisa al PO con el link del run.

### 3. Seguir el canary

Durante los ~30 min del canary, verificar en paralelo:

```bash
# Estado del tráfico del servicio (esperado durante canary: tag canary-signup-<sha> al 1 %)
gcloud run services describe booster-ai-api --region=southamerica-west1 \
  --format="yaml(status.traffic,status.latestReadyRevisionName)"

# Errores de la revisión nueva
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="booster-ai-api" AND severity>=ERROR' \
  --limit=50 --freshness=1h --format=json
```

**Gotcha verificado (2026-07-25)**: al promover, Cloud Run expresa el 100 % como `LATEST → 100 %` y esa entrada de `trafficStatuses` **no trae nombre de revisión**; la entrada con el tag `canary-signup-<sha>` va sin porcentaje. Un monitor que busque el % en la entrada con nombre lee `0 %` y parece canary trabado. Para confirmar promoción: `LATEST` al 100 % **y** `latestReadyRevisionName` = la revisión esperada.

Si `canary-verify` falla, Cloud Build no promueve y el run termina en error: ir a Rollback (el 1 % sigue apuntando al canary hasta que se revierta).

### 4. Smoke post-promoción

```bash
curl -fsS https://api.booster-ai.com/health     # 200 y versión nueva
# Endpoint o flujo tocado por el cambio: curl autenticado o verificación manual en la PWA
```

### 5. Monitoreo 2 h post-deploy

Umbrales de rollback inmediato:

- Error rate sube > 2× baseline durante > 5 min.
- Latency P95 sube > 50 % durante > 10 min.
- Errores nuevos en logs que no se entienden en < 30 min.
- Alerta de Cloud Monitoring se dispara → activar skill `incident-response`.

### 6. Evidencia en `ship.md`

```markdown
## Ship evidence

- Date: 2026-MM-DDTHH:MM:SSZ
- Commit SHA: <sha>
- Actions run: <url del run de release.yml>
- Cloud Run revision (prod): <revision_name>   # de latestReadyRevisionName
- Canary: 1 % / 30 min → 100 % a las <hora UTC>
- Migraciones aplicadas: <ids o "ninguna">
- Approver del gate: Felipe Vicencio
- Monitoring window: 2 h, completed [✓|✗]
- Incidents during window: [none | descripción + link]
```

Si hubo `terraform apply`, registrar también el plan y la salida del apply.

### 7. Postmortem de 24 h

Tres líneas en `ship.md` al día siguiente: qué funcionó, qué sorprendió, qué haría distinto. Actualizar `docs/handoff/CURRENT.md` si el deploy cerró un frente (ver `docs/frentes-vivos.md`).

## Rollback

```bash
# 1. Revisiones recientes
gcloud run revisions list --service=booster-ai-api --region=southamerica-west1 --limit=10

# 2. 100 % del tráfico a la revisión anterior estable
gcloud run services update-traffic booster-ai-api \
  --region=southamerica-west1 \
  --to-revisions=<PREVIOUS_REVISION>=100

# 3. Verificar
curl -fsS https://api.booster-ai.com/health     # debe responder la versión anterior

# 4. Migración de BD problemática: seguir ADR-066 (expand/contract; nunca DROP en caliente)

# 5. Documentar en .specs/<slug>/ship.md sección "Rollback"
```

Runbook específico del canary de signup: `docs/qa/signup-canary-rollback.md`.

Ojo: `infrastructure/compute.tf` puede tener `traffic` en `lifecycle.ignore_changes` (`var.traffic_managed_externally`). Un `terraform apply` posterior no debe revertir el rollback; confirmar con `terraform plan` antes de aplicar.

## Anti-rationalizations

| Tentación | Por qué es error |
|---|---|
| "Es viernes pero lo despliego igual" | Sin on-call de fin de semana, un canary que falla el sábado se arregla el lunes. |
| "El canary de 30 min es mucho, lo promuevo a mano" | El gate `canary-verify` es lo único que mira error rate y p95 antes del 100 %. |
| "El monitoreo lo dejo para mañana" | Las primeras 2 h son donde aparecen los errores que el canary al 1 % no vio. |
| "Skippeo el rollback plan, no creo que sea necesario" | El plan se escribe cuando no hay presión, no durante el incidente. |
| "Es chico, no necesita gate humano" | El gate es contrato (`CLAUDE.md` §Frontera de decisiones), no una opción. |

## Exit criteria (deploy completo)

- [ ] Run de `release.yml` en `success`, gate aprobado por el PO.
- [ ] `latestReadyRevisionName` = revisión esperada, `LATEST` al 100 %.
- [ ] Migraciones esperadas aplicadas (verificado en BD, no inferido).
- [ ] Smoke `/health` 200 + flujo tocado verificado.
- [ ] 2 h de monitoreo sin incidentes.
- [ ] `ship.md` con evidencia; `CURRENT.md` actualizado si cambió el estado del proyecto.

## Cuando algo no cuadra

Si algo se ve raro en cualquier paso, **detente y escala al PO** con el diagnóstico. Demorar un deploy 4 horas es más barato que una outage de 4 días. Para incidentes activos, skill `incident-response`.
