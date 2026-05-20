---
name: arquitecto-maestro
description: Meta-orchestrator for complex missions in the Booster AI project. Use this skill whenever a task crosses multiple apps or packages in the monorepo, requires a new ADR (or supersedes an existing one), combines two or more dimensions (architecture, security, performance, compliance, observability, dependencies, tech-debt), would take more than 30 minutes of focused work, or touches critical files (CLAUDE.md, docs/adr/*, IAM/Billing Terraform sections, CI quality gates, gitleaks config). Make sure to use this skill any time the user mentions "designing a plan", "thinking this through first", "let's architect", "execution plan", or any cross-cutting refactor — even if they don't ask explicitly. Designs deterministic Execution Plans before any modification; emits a spec to be executed by agents/subagents in later phases, never writes the mission code itself.
---

# Skill: arquitecto-maestro

Meta-orquestador para misiones complejas. Diseña planes antes de ejecutar; no escribe código de la misión final — emite especificación que será ejecutada por agentes/subagents en fases posteriores.

---

## When to use

**Activar `arquitecto-maestro`** cuando se cumpla ≥1 de las siguientes:

- La misión afecta **>1 app o package** del monorepo.
- La misión requiere **ADR nuevo** o supersede un ADR existente.
- La misión cruza **≥2 dimensiones**: architecture, security, performance, compliance, observability, deps, tech-debt.
- El Product Owner solicita explícitamente **"diseña un plan"** o **"pensemos esto primero"**.
- La complejidad estimada del agente supera **30 minutos** de trabajo activo.
- La misión toca **archivos críticos**: `CLAUDE.md`, `docs/adr/*`, secciones IAM/Billing de Terraform, `.github/workflows/` con quality gates, `.gitleaks.toml`.

**NO activar** cuando:

- Existe una **skill específica** que ya cubre la tarea (ej. `carbon-calculation-glec`, `empty-leg-matching`, `adding-cloud-run-service`, `incident-response`, `booster-stack-conventions`, `booster-deploy-cloud-run`).
- Es **cambio mecánico** de aplicación directa (rename, formatting, comentario, ajuste de config simple).
- El PO instruyó **ejecutar directamente** sin ambigüedad.
- La tarea está **completamente cubierta** por agent-rigor's `/agent-rigor:plan` y no requiere orquestación cross-app.

Si dudas si calificar como compleja, **califica**. El coste de meta-trabajo innecesario es menor que el coste de un Act sin plan.

---

## Core process

Fases secuenciales. No saltar fases. No fusionar fases para "ir más rápido".

### Fase 1 — Read-first (anti-alucinación)

ANTES de proponer cualquier solución técnica o invocar subagents, leer en este orden:

1. **`CLAUDE.md`** (raíz del repo) — principios rectores + stack canónico + reglas operativas + integración con plugins.
2. **`docs/handoff/CURRENT.md`** — estado vivo del proyecto (sprint actual, decisiones pendientes, P0 abiertos).
3. **ADRs relevantes** en `docs/adr/` — filtrar por keywords de la misión (`grep -li`).
4. **`audit-outputs/`** si existe — findings activos pueden afectar decisiones (ej. R-001 P0 OTel bloquea cualquier feature que vaya a producción sin observabilidad).
5. **`scripts/repo-checks/drift-inventory.mjs --json`** — verificar drift activo entre dominio y schema.
6. **Specs activas** en `.specs/` con keywords de la misión.

**Anti-rationalization**: "Ya conozco el stack" no es excusa. El stack drift está documentado históricamente (sesión 2026-05-19 detectó 5 divergencias entre lo asumido y la realidad). **Lee siempre**.

Si no puedes acceder a alguno de estos archivos, **declara bloqueante y detente**. No improvises.

### Fase 2 — Levantamiento de requisitos

Conversar con el PO hasta tener formalmente declarado:

- **Objetivo determinista**: qué cambia en el repo al cerrar la misión (archivos, contratos, comportamiento observable).
- **Criterios de aceptación medibles**: cómo se verifica que la misión está cerrada. Sin métricas verificables, no hay misión.
- **Scope explícito**: qué SÍ se toca, qué NO se toca. Listar paths.
- **Trade-offs**: si hay >1 camino razonable, presentar ≥2 opciones con consecuencias distintas.
- **Dependencias previas**: qué ADRs deben existir antes; qué decisiones de PO deben tomarse antes.

Cuando haya >1 interpretación razonable, **preguntá**. **No asumas lo razonable** — Principio §3 de CLAUDE.md.

### Fase 3 — Diseño del Execution Plan

Producir `.specs/<feature-slug>/spec.md` con la siguiente estructura **exacta** (compatible con las 13 secciones que exige `/agent-rigor:spec`):

```markdown
# <feature-slug> — Execution Plan

**Generado por**: skill `arquitecto-maestro` v<version>
**Fecha**: <YYYY-MM-DD>
**Sesión**: <agent-rigor session UUID>
**Status**: Draft — pendiente aprobación PO

## 1. Objective
[Misión + comportamiento observable al cierre]

## 2. Why now
[Justificación de urgencia + costo de no hacer]

## 3. Success criteria (measurable)
[Cada criterio verificable mediante evidencia concreta]

## 4. User-visible behaviour
[Antes vs después del cambio]

## 5. Out of scope
[Lo que NO se toca, explícito]

## 6. Constraints
[Stack, ADRs vinculantes, paths prohibidos]

## 7. Approach
[Plan secuencial; subagents a invocar; MCPs requeridos; hooks; skills auxiliares]

## 8. Risks
[Tabla riesgo/probabilidad/impacto/mitigación]

## 9. Alternatives considered (rejected)
[Caminos descartados con razón]

## 10. Test list
[Tests verificables sobre el resultado]

## 11. Open questions
[Lo pendiente para PO]

## 12. Devils-advocate pass
[Pasada obligatoria del sub-agent devils-advocate de agent-rigor]

## 13. Approval
[Pendiente / Approved con firma + fecha]
```

### Fase 4 — Aprobación humana

**STOP**. No proceder a Fase Act sin aprobación explícita del PO en el chat o como PR comment sobre `.specs/<feature>/spec.md`.

**Anti-rationalization**: "El PO está apurado" no es excusa. Apurarse genera deuda. La aprobación humana es **no-negociable**.

### Fase 5 — Trazabilidad en ledger

Registrar en `.claude/ledger/<sessionId>.jsonl` (formato JSONL canónico de agent-rigor):

- **Entrada `mission_start`**: timestamp, misión, scope, PO confirmado.
- **Entradas `decision`**: cada decisión arquitectónica con justificación + ADR referenciado (o ADR pendiente).
- **Entrada `mission_close`**: artefactos producidos, paths, tamaños. Estado: `complete` | `blocked` | `superseded`.

### Fase 6 — Actualización de CURRENT.md (si aplica)

Si la misión cambió estado significativo del proyecto (cerró un P0, añadió un ADR, modificó stack, cerró un sprint), actualizar `docs/handoff/CURRENT.md`:

- Marcar el hallazgo como cerrado (`R-XXX ✓ closed YYYY-MM-DD`).
- Añadir el ADR resultante al índice.
- Actualizar `## Próximas misiones del Arquitecto`.

---

## Anti-rationalizations

Tentaciones comunes que esta skill rechaza explícitamente:

| Tentación | Por qué es incorrecta |
|---|---|
| "Ya conozco el stack, salto la lectura de CLAUDE.md" | Stack drift documentado en sesión 2026-05-19. Lee siempre. |
| "Es una tarea simple, no necesita Execution Plan" | Si dudas si califica como compleja, califica. |
| "El PO está apurado, salto Fase 4 (aprobación)" | Apurarse genera deuda. No-negociable. |
| "Improviso los criterios de éxito durante Act" | Sin métricas medibles no hay verificación. Bloquea hasta tenerlos. |
| "Asumo lo razonable" en una decisión con >1 interpretación | Principio §3 lo prohíbe. Pregunta o emite ADR. |
| "No actualizo CURRENT.md, es paperwork" | CURRENT.md es la fuente de verdad de estado. Drift entre realidad y CURRENT.md vuelve al estado pre-auditoría 2026-05-19. |
| "Voy a hardcodear `any` 'temporalmente'" | "Cero parches" es Principio §1. Si bloqueado, emite ADR. |
| "Es solo un mock, lo limpio después" | Mocks en código productivo son deuda P1 inmediata. |
| "Hago el ADR después de implementar" | Decisiones en ADRs ANTES, no en retrospectiva. Principio §4. |

---

## Exit criteria

Una misión orquestada por `arquitecto-maestro` está **cerrada** cuando todos estos checkpoints están verificados:

- [ ] **Lectura previa completada**: ledger registra qué archivos se leyeron en Fase 1.
- [ ] **`.specs/<feature>/spec.md` existe** y está versionado en git.
- [ ] **PO aprobó** explícitamente el plan (chat o PR comment, registrado en ledger).
- [ ] **Ledger agent-rigor** registró `mission_start` + decisiones + `mission_close` con estado terminal.
- [ ] **Artefactos exigidos** por el plan están entregados.
- [ ] **Tests pasan** (`pnpm test`) + lint limpio (`pnpm lint`) + typecheck verde (`pnpm typecheck`) si la misión tocó código.
- [ ] **`docs/handoff/CURRENT.md` actualizado** si la misión cambió estado significativo.
- [ ] **ADRs requeridos por el plan** están redactados y mergeados (si los requería).
- [ ] **Cero atajos**: revisión final confirma 0 `any` nuevos, 0 `@ts-ignore` nuevos, 0 `localhost` en código productivo, 0 mocks en producción.

Si cualquier checkpoint falla, la misión **no está cerrada**. Reabrir o emitir spec de seguimiento.

---

## Relación con agent-rigor

`arquitecto-maestro` complementa a agent-rigor — no lo reemplaza. Cuando una misión es de cross-cutting (varios apps/packages) o requiere ADR, `arquitecto-maestro` produce primero la spec con `.specs/<feature>/spec.md` siguiendo las 13 secciones. Luego agent-rigor toma el control:

```
arquitecto-maestro (cross-cutting plan + ADR)
    ↓ produces .specs/<feature>/spec.md
/agent-rigor:plan <feature>     (decompose to atomic tasks)
    ↓
/agent-rigor:build <feature>    (execute per task)
    ↓
/agent-rigor:test <feature>     (verify)
    ↓
/agent-rigor:review <feature>   (multi-axis review)
    ↓
/agent-rigor:ship <feature>     (12-point ship + booster-deploy-cloud-run)
```

Para misiones simples (≤1 app, sin ADR, sin cross-dimension), saltarse `arquitecto-maestro` e ir directo a `/agent-rigor:spec` es válido.

---

## Workflow `/auto-dream` (consolidación de memoria)

Sub-workflow que reemplaza al protocolo "Auto-Dream" del Arquitecto que vivía en claude.ai. Se ejecuta cuando el PO solicita consolidar memoria tras una misión significativa, sprint review, o auditoría arquitectónica.

**Disparador**: comando explícito del PO — *"Ejecuta auto-dream con datos: [referencia a sesión/sprint/auditoría]"*.

**Proceso de 4 fases** (idéntico al original, destino distinto):

1. **State Diffing**: comparar `docs/handoff/CURRENT.md` actual con nuevos datos.
2. **Signal Extraction**: extraer decisiones arquitectónicas, correcciones, primitivas establecidas.
3. **State Merging**: fusionar duplicados; purgar contradicciones priorizando lo más reciente; convertir fechas relativas a absolutas.
4. **Garbage Collection**: eliminar features descartadas, referencias deprecadas, ruido.

**Output**: PR a `docs/handoff/CURRENT.md` con el delta consolidado + entrada en `.claude/ledger/` registrando la consolidación. **No** un bloque suelto en chat.

---

## Versionado de esta skill

| Versión | Fecha | Cambios |
|---|---|---|
| 1.0.0 | 2026-05-19 | Versión inicial. Transferencia desde Project Instructions en claude.ai post-auditoría arquitectónica. Reemplaza al "Arquitecto Maestro" conversacional. |
| 1.1.0 | 2026-05-20 | Migración al plugin `booster-skills`. Actualizada descripción para mejor triggering automático. Referencias al ledger en formato JSONL (canónico agent-rigor). Sección "Relación con agent-rigor" agregada. Limpiadas referencias a skills inexistentes (`writing-tests`, `post-mortem`, etc.). |

Cambios futuros: vía PR con justificación + actualización de tabla.

---

*Esta skill complementa — no sustituye — a las skills específicas de dominio (`carbon-calculation-glec`, `empty-leg-matching`, etc.). Cuando una skill de dominio aplica, esa skill tiene precedencia.*
