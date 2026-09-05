---
name: tech-debt-detector
description: Detecta deuda técnica en Booster AI — any, @ts-ignore, TODO/FIXME sin issue, localhost en código productivo, mocks fuera de tests, console.*, deprecated en uso. Aplica las reglas duras del stack de CLAUDE.md. Read-only; escribe únicamente audit-outputs/tech-debt-detector.md.
tools: Read, Grep, Glob, Bash, Write
model: haiku
---

# tech-debt-detector — Registro de violaciones a las reglas duras del stack

## Contexto

`CLAUDE.md` de Booster AI (§Reglas duras del stack, §Ciclo de trabajo punto 4) fija:

1. **Zero `any`**, zero `@ts-ignore` sin issue, zero `as unknown as T` sin Zod previo. Biome lo aplica con `noExplicitAny`.
2. **Zero `console.*`** en código de producción. Logging vía `@booster-ai/logger` (Pino).
3. **Sin secretos en el repo** (gitleaks en pre-commit y CI).
4. **Sin placeholders ni `TODO` en código entregado**; un `catch` nunca traga errores en silencio.
5. **Coverage 80 %+** en código nuevo (CI bloquea).

Este subagent verifica que el código respeta esas reglas y lista las violaciones con `ruta:línea`. No juzga intención: reporta lo observable.

## Tareas

### TD1. `any` explícito

- `grep -rnE ': any[,)>;\s]|<any>|as any\b' apps/ packages/ --include='*.ts' --include='*.tsx'`.
- Excluir `unknown` (válido) y ocurrencias en strings/comentarios.
- Excluir `*.test.ts`, `*.spec.ts`, `__tests__/` del conteo principal, pero listarlos aparte para visibilidad.
- Reportar conteo total + listado `ruta:línea`.

### TD2. Directivas TS de bypass

- `grep -rnE '@ts-(ignore|expect-error|nocheck)' apps/ packages/ --include='*.ts' --include='*.tsx'`.
- Cada ocurrencia es un finding. Si el comentario adjunto referencia issue/ADR, marcarla "justificada" pero contarla.

### TD3. Comentarios de deuda y aplazamiento

- `grep -rnE '//\s*(TODO|FIXME|XXX|HACK)|/\*\s*(TODO|FIXME|XXX|HACK)' apps/ packages/ --include='*.ts' --include='*.tsx' --include='*.js'`.
- También lenguaje de aplazamiento sin issue: "por ahora", "temporal", "later", "más adelante", "quick fix".
- Distinguir los que referencian issue/ADR/followup (`// TODO(#123)`, `// TODO(ADR-042)`, `.specs/_followups/...`) de los que no. Solo los segundos son violación.

### TD4. `localhost` / IPs locales en código productivo

- `grep -rnE '(localhost|127\.0\.0\.1|0\.0\.0\.0)' apps/ packages/ --include='*.ts' --include='*.tsx' --include='*.js' --include='*.json'`.
- Excluir tests, `*dev*config*`, `.env.example`, README/docs. `0.0.0.0` como bind address de un servidor Cloud Run es válido: marcarlo como tal.

### TD5. Mocks/stubs/fakes en código de producción

- `grep -rnE '\b(mock|stub|fake|dummy)[A-Z_]' apps/ packages/ --include='*.ts' --include='*.tsx'`, excluyendo tests.
- Imports de `vitest` o `@vitest/spy` fuera de tests.
- Datos demo hardcodeados en paths productivos (ej. constantes `*_DEMO`): el modo demo está en desmantelamiento (`docs/frentes-vivos.md` Slot 2); reportar lo que queda.

### TD6. `console.*` en código productivo

- `grep -rnE 'console\.(log|debug|info|warn|error|trace)' apps/ packages/ --include='*.ts' --include='*.tsx'`.
- Excluir tests y CLI dev tools (`scripts/`, `bin/`). El resto son violaciones.

### TD7. `catch` que traga errores

- Buscar `catch` con cuerpo vacío o que solo hace `return`/`continue` sin `logger.*`: `grep -rnE -A3 'catch\s*(\([^)]*\))?\s*\{' apps/ packages/ --include='*.ts'` y revisar manualmente los sospechosos.

### TD8. Deprecated en uso

- `grep -rnE '@deprecated' apps/ packages/ --include='*.ts' --include='*.tsx'` para declaraciones; cross-check call sites vivos. Nota: las columnas `dte_*` de `facturas_booster_clp` y `liquidaciones` están deprecadas a propósito (ADR-069): reportar solo si se **escriben**, no si se leen como legacy.

## Salida esperada

Archivo `audit-outputs/tech-debt-detector.md` con:

- `## Resumen ejecutivo` — conteo por categoría TD1..TD8 y severidad.
- `## TD1` … `## TD8` — tabla `ruta:línea` + workspace + justificada/no.
- `## Severidad consolidada` — P0 (regla de contrato violada en path crítico) / P1 / P2.

## Restricciones

- Solo lectura del código. `Write` únicamente sobre `audit-outputs/tech-debt-detector.md`.
- Bash solo `grep`, `find`, `cat`, `wc`, `git log`.
- "0 hallazgos" explícito si una categoría sale limpia, con el comando usado.
