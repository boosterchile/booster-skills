---
description: Auditoría completa READ-ONLY de booster-ai — despacha los sub-agents de auditoría y sintetiza un roadmap priorizado P0/P1/P2. No modifica código.
argument-hint: "[all | security | deps | perf | debt | sre | arch] (default: all)"
---

Ejecuta una auditoría READ-ONLY del repo booster-ai. No modifiques código en esta fase: el objetivo es un diagnóstico priorizado, no fixes. Aplica el contrato de `CLAUDE.md`. Una auditoría no abre frente (`docs/frentes-vivos.md`): produce diagnóstico; los fixes entran después, cada uno con su spec, y solo si caben en un slot vivo.

Alcance solicitado: "$ARGUMENTS" (vacío o "all" = auditoría completa; un nombre de dimensión = solo ese sub-agent + la síntesis).

## Cobertura mínima (modo all)

Obtén el inventario real con `ls apps packages` antes de despachar (no asumas la lista). Al 2026-09: `apps/{api,web,telemetry-tcp-gateway,telemetry-processor,document-service,whatsapp-bot,matching-engine,notification-service,sms-fallback-gateway}`; packages críticos `{transport-documents,factoring-engine,carbon-calculator,pricing-engine,matching-algorithm,codec8-parser,trip-state-machine,certificate-generator,config,logger,otel-bootstrap,shared-schemas}`; `infrastructure/` y `.github/workflows/`.

## Fase 1 — Despacha los sub-agents de auditoría (en paralelo vía Task)

Cada uno escribe su salida en `audit-outputs/<nombre-del-agent>.md` y devuelve un resumen corto:

- **explore-architecture** → mapa apps/packages, acoplamientos, fronteras de dominio, violaciones de capas (lógica de negocio fuera de `packages/`), naming bilingüe.
- **security-scanner** → OWASP + compliance Chile (Ley 19.628/21.719, consentimiento ESG ADR-068, documentos de terceros ADR-069/070, RBAC por rol, secrets, IAM mínimo privilegio).
- **dependency-auditor** → CVEs, deps deprecadas/sin mantención, supply chain, security pins de `pnpm-workspace.yaml` (ADR-075).
- **performance-analyzer** → N+1, bundle size, PWA/Web Vitals, queries sin índice/partición, path de telemetría.
- **tech-debt-detector** → `any`, `@ts-ignore`, TODO/FIXME sin issue, `console.*`, mocks y restos de modo demo en prod, localhost hardcoded, `catch` que traga errores.
- **sre-oncall** → observabilidad (trace_id/OTel/métricas/dashboards/alertas SLO, salud de señal en telemetría), rollback readiness, capacity, deps externas con timeout/retry/circuit-breaker, en los caminos críticos (telemetría, documentos, pagos, factoring, carbono).

Si "$ARGUMENTS" nombra una sola dimensión (security|deps|perf|debt|sre|arch), corre solo el sub-agent correspondiente.

## Fase 2 — Síntesis

Invoca **refactor-advisor** para consolidar las salidas en `audit-outputs/refactor-advisor.md`:

- **P0** (bloqueante / riesgo legal o de seguridad), **P1** (este frente), **P2** (siguiente).
- Cada hallazgo: `ruta:línea`, evidencia, impacto, recomendación. Nunca secrets en cleartext.
- Áreas CONGELADAS o legalmente vinculantes (ej. `factoring-v1.0-cl-*`, certificados ya emitidos): reportarlas sin proponer edits directos; flag "requiere versionado + revisión del PO".
- Roadmap ordenado por "se cierra lo que más libera" y acotado a los tres slots de `docs/frentes-vivos.md`.

## Entregables persistentes

- `audit-outputs/<agent>.md` (uno por sub-agent) + `audit-outputs/refactor-advisor.md`.
- `.specs/revision-completa-<fecha>/review.md` con el roadmap priorizado consolidado.
- Para cada P0, un stub en `.specs/_followups/` con el problema y el plan de pago (sin ejecutar los fixes).

## Cierre

Resumen en chat: top 5 P0 + recomendación de por dónde empezar. Los audit-outputs se commitean en una rama `chore/<slug>` con pre-commit en verde; jamás a `main` directo. Los fixes son trabajo aparte (spec → test-first con rojo exhibido → review), uno por uno.
