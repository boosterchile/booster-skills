---
name: definicion-de-terminado
description: Definición de Terminado (DoD) y estándar profesional anti-parches para Booster AI. Use this skill whenever you are about to declare a task done, complete, fixed, listo, terminado, resuelto, or are about to commit, abrir un PR, or move to the next task. Make sure to use this skill any time the user or you reach for "por ahora", "rápido", "esto basta", "lo dejo así", "un parche", "patch", "workaround", "quick fix", "lo mejoro después", "MVP", "good enough", "temporal" — OR any time you are tempted to fix a symptom instead of the root cause, skip a test, swallow an error, or claim success without running the verification. Replaces the old keyword-taboo with an explicit, testable bar. Complements superpowers:verification-before-completion and superpowers:test-driven-development with Booster's professional standard.
---

# Skill: Definición de Terminado (anti-parches)

**Categoría**: stack-discipline + quality-gate
**Prioridad**: alta — esta skill existe porque el modo de falla #1 es declarar "listo" sin evidencia y parchear síntomas en vez de causas
**Relacionado**: `superpowers:verification-before-completion`, `superpowers:test-driven-development`, skill `booster-stack-conventions`, `tdd-dominio-critico`

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
- [ ] Tests escritos (o actualizados) y **vistos pasar en esta sesión** — no "deberían pasar". Para auth/dinero/datos/SII, TDD obligatorio (ver `tdd-dominio-critico`).
- [ ] `pnpm typecheck` y `pnpm lint` corren limpio (output pegado, no "creo que pasa").
- [ ] Sin `any`, sin `console.*`, sin secretos, sin `TODO`/`FIXME` sin issue enlazado (contrato `booster-stack-conventions`).
- [ ] Errores manejados explícitamente — ningún `catch` vacío ni que traga el error sin loggear vía `@booster-ai/logger`.
- [ ] Si tocaste un boundary: Zod valida la entrada. Si tocaste UI: checklist pre-entrega aplicada.
- [ ] La evidencia (salida de tests, typecheck, curl, screenshot) está pegada, no descrita.

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

Esto sustituye al antiguo hook que bloqueaba por palabras (y que hacía deadlock): la disciplina ahora vive en conducta verificable, no en un grep frágil.

## Cooling-off (rescatado de agent-rigor, como práctica)

Eres dev solo: no hay segundo par de ojos humano. Antes de cerrar un `/review` o un merge de algo no trivial:

- Si es posible, despacha un **subagente fresco** de review (superpowers ya lo hace en `subagent-driven-development`: revisor de spec + revisor de calidad por tarea). Un subagente fresco ES tu segundo par de ojos.
- Si el cambio es sensible (dinero, datos, SII, auth) y no hay subagente revisor, **deja reposar el cambio** (otra sesión / un descanso) antes de aprobarlo. La auto-revisión inmediata es la peor revisión.

## Cuándo NO aplicar el estándar máximo

Para ser justo con el pragmatismo: spikes exploratorios desechables, prototipos que vas a **borrar** (no a promover), y configuración trivial NO requieren TDD ni DoD completa — pero deben declararse explícitamente como desechables y no terminar en `main`. Lo desechable se borra; no se "gradúa" a producción sin pasar el ciclo.
