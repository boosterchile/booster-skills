---
description: Auditoría completa READ-ONLY de booster-ai — despacha los sub-agents de auditoría y sintetiza un roadmap priorizado P0/P1/P2. No modifica código.
argument-hint: "[all | security | deps | perf | debt | sre | arch] (default: all)"
---

Ejecuta una auditoría READ-ONLY del repo booster-ai. NO modifiques código en esta fase: el objetivo es un diagnóstico priorizado, no fixes. Aplica el contrato de CLAUDE.md.

Alcance solicitado: "$ARGUMENTS" (si está vacío o es "all", corre la auditoría completa; si es un nombre de dimensión, corre solo ese sub-agent + la síntesis).

## Cobertura mínima (modo all)

apps/api, apps/web, apps/telemetry-tcp-gateway, apps/telemetry-processor, apps/document-service, apps/whatsapp-bot, apps/matching-engine, apps/notification-service; packages críticos (dte-provider, factoring-engine, carbon-calculator, pricing-engine, matching-algorithm, codec8-parser, trip-state-machine, config, logger, shared-schemas); infrastructure/ y .github/workflows/.

## Fase 1 — Despacha los sub-agents de auditoría (en paralelo vía Task)

Cada uno escribe su salida en `audit-outputs/`:

- **explore-architecture** → mapa apps/packages, acoplamientos, fronteras de dominio, violaciones de capas (lógica de negocio fuera de packages/).
- **security-scanner** → OWASP + compliance Chile (Ley 19.628, SII/DTE retención + retention lock + firma KMS, RBAC por rol shipper/carrier/driver/admin/stakeholder, consent ESG, secrets, IAM mínimo privilegio).
- **dependency-auditor** → CVEs, deps deprecadas/sin mantención, supply chain, coherencia de overrides pnpm (package.json vs pnpm-workspace.yaml).
- **performance-analyzer** → N+1, bundle size, PWA/Web Vitals, queries sin índice/partición.
- **tech-debt-detector** → `any`, `@ts-ignore`, TODO/FIXME sin issue, `console.*`, mocks en prod, localhost hardcoded.
- **sre-oncall** → observabilidad (trace_id/OTel/métricas/dashboards/alertas SLO), rollback readiness, capacity, deps externas con timeout/retry/circuit-breaker, en los caminos críticos (telemetría, documentos, pagos, factoring).

Si "$ARGUMENTS" nombra una sola dimensión (security|deps|perf|debt|sre|arch), corre solo el sub-agent correspondiente.

## Fase 2 — Síntesis

Invoca **refactor-advisor** para consolidar las salidas en un único informe priorizado:

- **P0** (bloqueante / riesgo legal o de seguridad), **P1** (este sprint), **P2** (siguiente).
- Cada hallazgo: `ruta:línea`, evidencia, impacto, recomendación. NUNCA secrets en cleartext.
- Marca explícitamente áreas CONGELADAS o legalmente vinculantes (ej. `factoring-v1.0-cl-*`): repórtalas pero NO propongas edits directos — flag "requiere versionado + revisión legal".

## Entregables persistentes

- `audit-outputs/*.md` (uno por sub-agent).
- `.specs/revision-completa-<fecha>/review.md` con el roadmap priorizado consolidado.
- Para cada P0, un stub en `.specs/_followups/` con el problema y el plan de pago (NO ejecutar los fixes).

## Cierre

Resumen en chat: top 5 P0 + recomendación de por dónde empezar. Si commiteas los audit-outputs, deja los pre-commit gates en verde. Recuerda: esto es diagnóstico; los fixes son trabajo aparte (spec → test-first → review), uno por uno.
