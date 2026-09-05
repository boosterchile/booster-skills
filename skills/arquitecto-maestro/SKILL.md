---
name: arquitecto-maestro
description: Orquestador de misiones complejas en Booster AI. Use when a task spans more than one app or package of the monorepo, requires a new ADR or supersedes one, combines two or more dimensions (architecture, security, performance, compliance, observability, deps, tech debt), or touches protected files (CLAUDE.md, docs/adr, IAM/Billing/KMS Terraform, CI quality gates). Produces an Execution Plan in .specs/<slug>/spec.md for PO approval before any code is written; does not write the mission code itself.
---

# Skill: arquitecto-maestro

Orquestador para misiones complejas. Diseña el plan antes de ejecutar; no escribe el código de la misión final — emite una spec que se ejecuta en fases posteriores.

Esta skill es **material de apoyo** (ADR-072): la norma es `CLAUDE.md` de `booster-ai`. Si algo aquí contradice el contrato, gana el contrato.

---

## When to use

Activar cuando se cumpla al menos una:

- La misión afecta **más de una app o package** del monorepo.
- Requiere **ADR nuevo** o supersede uno existente.
- Cruza **dos o más dimensiones**: architecture, security, performance, compliance, observability, deps, tech-debt.
- Toca **archivos protegidos** (`CLAUDE.md` §Archivos que NUNCA se tocan): `CLAUDE.md`, `docs/adr/*`, `.tf` con IAM/Billing/service accounts/KMS/firewall, quality gates de `.github/workflows/`.
- El PO pide explícitamente un plan antes de construir.

**No activar** cuando una skill de dominio ya cubre la tarea (`carbon-calculation-glec`, `empty-leg-matching`, `adding-cloud-run-service`, `incident-response`, `booster-deploy-cloud-run`), cuando es un cambio mecánico (rename, formato, config simple), o cuando el PO instruyó ejecutar directamente sin ambigüedad. Para una misión acotada a una app y sin ADR, basta el `.specs/<slug>/spec.md` que exige `CLAUDE.md` §Ciclo de trabajo.

---

## Core process

### Fase 1 — Read-first

Antes de proponer solución, leer en este orden:

1. **`CLAUDE.md`** — contrato vigente: frontera de decisiones, ciclo de trabajo, reglas duras del stack, archivos protegidos.
2. **`docs/frentes-vivos.md`** — solo se trabaja sobre los tres slots vivos. Si la misión no pertenece a ninguno, decirlo y detenerse; no abrir frente nuevo.
3. **`docs/handoff/CURRENT.md`** — estado vivo (pendientes que no pasan por GitHub, gates del PO, P0 abiertos).
4. **ADRs relevantes** en `docs/adr/` — filtrar por keywords (`grep -li`). Los ADR tienen estado de vigencia (`Vigente` / `Superado por ADR-NNN` / `No perseguido`, ADR-076); un ADR superado no fija nada.
5. **Specs activas** en `.specs/` con keywords de la misión, y `.specs/_followups/` para deuda ya trackeada.
6. **`audit-outputs/`** si la misión responde a una auditoría.
7. Si toca schema o specs canónicas: `scripts/repo-checks/` (`spec-canonical-drift.mjs`, `drift-inventory.mjs`, `check-migration-safety.mjs`).

Razón: el stack drift está documentado (sesión 2026-05-19: 5 divergencias entre lo asumido y la realidad). Lo que el modelo "recuerda" del repo no sustituye leerlo. Si un archivo no existe, declararlo en la spec como hallazgo, no inventar su contenido.

### Fase 2 — Levantamiento de requisitos

Con el PO, dejar formalmente declarado:

- **Objetivo determinista**: qué cambia en el repo al cerrar (archivos, contratos, comportamiento observable).
- **Criterios de aceptación medibles**, verificables por un tercero. Sin métricas, no hay misión.
- **Scope explícito**: paths que SÍ y que NO se tocan.
- **Trade-offs**: si hay más de un camino razonable, presentar ≥ 2 opciones con consecuencias distintas y una recomendación.
- **Dependencias previas**: ADRs o decisiones del PO que deben existir antes.

Cuando haya más de una interpretación razonable de algo que cae en "Claude NO decide" (`CLAUDE.md` §Frontera de decisiones), preguntar. Lo que cae en "Claude decide solo", decidirlo y dejarlo escrito en la spec.

### Fase 3 — Execution Plan

Producir `.specs/<slug>/spec.md` con esta estructura:

```markdown
# <slug> — Execution Plan

**Generado por**: skill `arquitecto-maestro` v1.2.0
**Fecha**: <YYYY-MM-DD>
**Frente**: <slot de docs/frentes-vivos.md al que pertenece>
**Status**: Draft — pendiente aprobación PO

## 1. Objective
## 2. Why now
## 3. Success criteria (measurable)
## 4. User-visible behaviour (antes / después)
## 5. Out of scope
## 6. Constraints (stack, ADRs vinculantes, paths prohibidos)
## 7. Approach (plan secuencial; subagents; skills auxiliares)
## 8. Risks (tabla riesgo / probabilidad / impacto / mitigación)
## 9. Alternatives considered (rejected)
## 10. Test list (incluye los tests en rojo exigidos en dominio crítico)
## 11. Open questions (para el PO)
## 12. Revisión adversarial (subagente fresco que intenta romper el plan; resumen de objeciones y respuestas)
## 13. Approval (Pendiente / Approved + fecha)
```

La sección 12 la produce un subagente sin contexto de la conversación (si `superpowers` está instalado, `superpowers:writing-plans` y su revisión encajan aquí; si no, un `Task` con el rol "abogado del diablo").

### Fase 4 — Aprobación

Todo lo listado en "Claude NO decide" de `CLAUDE.md` requiere aprobación explícita del PO (chat o comentario en el PR de la spec) antes de ejecutar. Las secciones 11 y 13 dejan constancia. Un PO apurado no cambia esto: la aprobación es contrato.

### Fase 5 — Actualización de `CURRENT.md` (si aplica)

Si la misión cerró un P0, añadió un ADR, cambió el stack o cerró un frente: actualizar `docs/handoff/CURRENT.md` (respetando su presupuesto de ~150 líneas; el detalle va a un snapshot fechado en `docs/handoff/`).

---

## Anti-rationalizations

| Tentación | Por qué es incorrecta |
|---|---|
| "Ya conozco el stack, salto la lectura" | Stack drift documentado. Lee siempre. |
| "El PO está apurado, salto la aprobación" | La frontera de decisiones es contrato, no preferencia. |
| "Improviso los criterios de éxito durante la ejecución" | Sin métricas no hay verificación posible. Bloquea hasta tenerlos. |
| "No actualizo CURRENT.md, es paperwork" | Es la fuente de estado; el drift entre realidad y CURRENT.md fue la causa de la auditoría 2026-05-19. |
| "Hago el ADR después de implementar" | Las decisiones se registran antes; después ya no son decisiones sino justificaciones. |
| "Este trabajo no está en frentes-vivos pero es chico" | Tres slots. Lo que no cabe se declara y se detiene. |

---

## Exit criteria

- [ ] `.specs/<slug>/spec.md` existe, versionado en git, con las 13 secciones.
- [ ] Pertenece a un slot de `docs/frentes-vivos.md` (o el PO abrió uno).
- [ ] PO aprobó explícitamente (sección 13).
- [ ] Artefactos exigidos por el plan entregados.
- [ ] Si tocó código: `pnpm ci` verde con output en la Evidencia del PR.
- [ ] ADRs requeridos redactados y mergeados.
- [ ] `docs/handoff/CURRENT.md` actualizado si cambió estado significativo.

---

## Relación con `superpowers` (opcional)

Si el plugin `superpowers` está instalado, la spec alimenta su ciclo: `superpowers:writing-plans` → `superpowers:executing-plans` o `superpowers:subagent-driven-development` → `superpowers:verification-before-completion`. Si no está, el `plan.md` se escribe a mano en `.specs/<slug>/plan.md` (convención `{spec,plan,verify,review,ship}.md` de `CLAUDE.md`).

---

## Workflow `/auto-dream` (consolidación de memoria)

Se ejecuta solo cuando el PO lo pide explícitamente (*"Ejecuta auto-dream con datos: [sesión/sprint/auditoría]"*), tras una misión significativa.

1. **State diffing**: comparar `docs/handoff/CURRENT.md` con los datos nuevos.
2. **Signal extraction**: decisiones arquitectónicas, correcciones, primitivas establecidas.
3. **State merging**: fusionar duplicados; purgar contradicciones priorizando lo más reciente; fechas absolutas.
4. **Garbage collection**: eliminar features descartadas y referencias deprecadas.

Output: PR a `docs/handoff/CURRENT.md` con el delta consolidado. No un bloque suelto en chat.

---

## Versionado de esta skill

| Versión | Fecha | Cambios |
|---|---|---|
| 1.0.0 | 2026-05-19 | Versión inicial, transferida desde Project Instructions en claude.ai. |
| 1.1.0 | 2026-05-20 | Migración al plugin `booster-skills`. |
| 1.2.0 | 2026-09-05 | Alineada a `CLAUDE.md` post-ADR-072 y a `docs/frentes-vivos.md`. Retiradas referencias a `agent-rigor`, al ledger y a la sesión UUID. Criterios de activación objetivos (sin "si dudas, califica" ni umbral de 30 min) para evitar sobre-disparo en Opus/Fable. |

*Cuando una skill de dominio aplica, esa skill tiene precedencia.*
