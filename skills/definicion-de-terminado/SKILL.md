---
name: definicion-de-terminado
description: Definición de Terminado y estándar anti-parches de Booster AI. Use when about to declare a task done, commit, open a PR, or move on; also when a fix would patch a symptom instead of the root cause, skip a test, swallow an error, or take technical debt silently. Checklist verificable con evidencia fresca; expande el punto "Terminado = evidencia fresca" de CLAUDE.md.
---

# Skill: Definición de Terminado (anti-parches)

**Categoría**: stack-discipline + quality-gate
**Prioridad**: alta — esta skill existe porque el modo de falla #1 es declarar "listo" sin evidencia y parchear síntomas en vez de causas
**Norma**: `CLAUDE.md` §Ciclo de trabajo (puntos 3, 4 y 6). Esta skill es material extendido (ADR-072); si contradice al contrato, gana el contrato.
**Relacionado**: `superpowers:verification-before-completion`, `superpowers:test-driven-development` (si `superpowers` está instalado), skills `booster-stack-conventions`, `tdd-dominio-critico`

## Por qué existe esta skill

El objetivo NO es prohibir palabras. Es impedir dos conductas concretas:

1. **Declarar "listo" sin evidencia fresca.** "Debería funcionar", "ya quedó", "lo probé antes" no son evidencia.
2. **Parchear el síntoma en vez de la causa.** Agregar un `try/catch` que traga el error, un `if` defensivo sobre un `undefined` que no debería existir, o un `// TODO` sin issue, es deuda — no solución.

Si una tarea es genuinamente pequeña, hacerla bien también es pequeño. "Pequeño" no autoriza "a medias".

## La regla de oro (reemplaza "no MVP, cero deuda")

> Una tarea está **terminada** cuando un staff engineer, mirando solo el diff y la evidencia adjunta, aprobaría el merge sin pedir aclaraciones. No antes.

Esto es verificable. "No MVP" no lo era.

## Definición de Terminado (checklist obligatoria)

Antes de decir "listo" / commitear / abrir PR, TODOS los puntos aplicables deben estar verificados con evidencia fresca en este mensaje:

- [ ] El cambio resuelve la **causa raíz**, no el síntoma. Si parcheas, está justificado por escrito y tiene issue/ADR asociado.
- [ ] Tests escritos (o actualizados) y **vistos pasar en esta sesión** — no "deberían pasar". En dominio crítico (DTE recibidos, factoring, pricing, GLEC, matching, migraciones, auth) el test se escribió primero y **el output del rojo va en la Evidencia del PR** (`CLAUDE.md` §Ciclo 3; ver `tdd-dominio-critico`).
- [ ] `pnpm typecheck`, `pnpm lint` y `pnpm build` corren limpio (output pegado, no "creo que pasa").
- [ ] Sin `any`, sin `console.*`, sin secretos, sin placeholders ni `TODO`/`FIXME` sin issue enlazado (contrato `booster-stack-conventions`).
- [ ] Errores manejados explícitamente — ningún `catch` vacío ni que traga el error sin loggear vía `@booster-ai/logger`.
- [ ] Si tocaste un boundary: Zod valida la entrada. Si tocaste UI: screenshot del estado final.
- [ ] La evidencia (salida de tests, typecheck, curl, screenshot) está pegada, no descrita.
- [ ] Commit + push de la rama feature, incluyendo `.specs/`. Lo no persistido se declara, no se deja pendiente en silencio.

Si no puedes marcar todas: **no está terminado**. Dilo con el estado real, no con un eufemismo.

## Red Flags — STOP, estás racionalizando

Estos pensamientos significan que estás a punto de bajar el estándar:

| Pensamiento | Realidad |
|---|---|
| "Esto basta para que funcione" | "Funciona en mi prueba" ≠ correcto. ¿Corriste la verificación? |
| "Lo dejo así por ahora y lo mejoro después" | "Después" no existe. Si es deuda, va con issue + justificación, no en silencio. |
| "Un parche rápido y sigo" | Parchear el síntoma deja la causa viva. Arregla la causa o documenta por qué no. |
| "Es muy chico para un test" | El código chico también rompe. El test toma 30 segundos. |
| "Agrego un try/catch defensivo" | ¿Por qué llega ese estado inválido? Arregla el origen, no escondas el error. |
| "Debería pasar / ya quedó" | Sin output fresco no afirmas éxito. Corre el comando. |
| "El usuario tiene apuro" | Apuro ≠ permiso para deuda silenciosa. Ofrece deuda *explícita* con plan. |
| "Es solo refactor, no necesita test" | Refactor sin test que lo respalde es cambio sin red de seguridad. |

## Deuda técnica: prohibida en silencio, permitida explícita

No estás obligado a hacer todo perfecto siempre. Estás obligado a **no ocultar** los cortes:

- Si vas a tomar deuda deliberada, decláralo así, en una sola frase: qué dejas pendiente, por qué, y dónde queda trackeado (issue/`.specs/_followups/` o ADR).
- Pide confirmación humana antes de proceder.
- Sin justificación trackeada, no hay corte. Reescribe la solución completa.

Tomar deuda deliberada es decisión del PO (`CLAUDE.md` §Frontera de decisiones).

## Cooling-off

El PO es operador único (ADR-076): no hay segundo par de ojos humano. Antes de cerrar un review o un merge de algo no trivial:

- Si es posible, despacha un **subagente fresco** de review (`superpowers:subagent-driven-development` si está instalado; si no, un `Task` con el diff y la spec, sin el contexto de la conversación). Un subagente fresco ES tu segundo par de ojos.
- Si el cambio es sensible (dinero, datos, SII, auth) y no hay subagente revisor, **deja reposar el cambio** (otra sesión / un descanso) antes de aprobarlo. La auto-revisión inmediata es la peor revisión.

## Cuándo NO aplicar el estándar máximo

Para ser justo con el pragmatismo: spikes exploratorios desechables, prototipos que vas a **borrar** (no a promover), y configuración trivial NO requieren TDD ni DoD completa — pero deben declararse explícitamente como desechables y no terminar en `main`. Lo desechable se borra; no se "gradúa" a producción sin pasar el ciclo.
