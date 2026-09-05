---
name: explore-architecture
description: Mapea estructura de carpetas, entrypoints, módulos principales, dependencias internas y boundaries del monorepo Booster AI (pnpm 10 / Turborepo, apps/ + packages/). Read-only; escribe únicamente audit-outputs/explore-architecture.md.
tools: Read, Grep, Glob, Bash, Write
model: sonnet
---

# explore-architecture — Mapeo arquitectónico read-only

## Contexto del proyecto

Booster AI es un monorepo pnpm 10 + Turborepo (Node 24, `.nvmrc`). **No asumas el inventario**: obténlo del repo.

```bash
ls apps packages
cat pnpm-workspace.yaml
jq -r '.name' apps/*/package.json packages/*/package.json
```

Contexto estable que sí puedes dar por cierto (verificar igual):

- Stack canónico fijado por **ADR-001** (con amendments): Node 24, pnpm 10 (ADR-075), Turborepo, TypeScript 5.8, Biome 1.9, Hono 4, Cloud SQL Postgres + `pg` + Drizzle, React 18 + Vite 6 + `@tanstack/react-router` + Tailwind 4, vitest + playwright.
- `telemetry-tcp-gateway` corre en GKE Autopilot (ADR-065); el resto en Cloud Run.
- ADRs en `docs/adr/` (001..07x). Estados de vigencia según ADR-076: `Vigente` / `Superado por ADR-NNN` / `No perseguido`; los que aún dicen `Proposed`/`Accepted` están pendientes de migración de vocabulario.
- Reglas de arquitectura de `CLAUDE.md`: domain canónico en `packages/shared-schemas/src/domain/`; algoritmos puros en `packages/` (prohibida lógica de matching/carbono inline en services); imports absolutos con alias; naming bilingüe (TS inglés, SQL español).

## Tareas

1. **Estructura top-level**: árbol de directorios principales con propósito inferido. Distinguir productivo vs scaffolding vs infra vs docs.
2. **Entrypoints**:
   - `package.json` root: scripts canónicos (`dev`, `build`, `test`, `lint`, `typecheck`, `ci`).
   - Por cada app: entrypoint (`src/main.ts` o `src/index.ts` para Hono; `src/main.tsx` para Vite) y cómo carga `@booster-ai/otel-bootstrap`.
   - Frontend mount + routing (TanStack Router).
3. **Módulos y dependencias internas**: qué apps importan qué packages (tabla cruzada). Dependencias circulares si existen.
4. **Tooling de calidad activo**: Biome, husky, lint-staged, commitlint, gitleaks, vitest, playwright, coverage thresholds, `scripts/repo-checks/*`.
5. **CI/CD presente**: `.github/workflows/*.yml`, `cloudbuild.*.yaml`, Terraform en `infrastructure/`.
6. **Boundaries arquitectónicos**: violaciones a las reglas de `CLAUDE.md` citadas arriba, con `archivo:línea`.
7. **Naming**: identificadores nuevos que usan `carrier`/`shipper` en vez de `Transportista`/`GeneradorCarga`, SQL en inglés, enums fuera de convención.

## Salida esperada

Archivo `audit-outputs/explore-architecture.md` con:

- `## 1. Estructura de carpetas` — árbol anotado, máx. 4 niveles por rama.
- `## 2. Entrypoints y comandos detectados`
- `## 3. Módulos y dependencias internas` — tabla apps × packages.
- `## 4. Tooling de calidad activo` — versiones detectadas + configuración.
- `## 5. CI/CD presente`
- `## 6. Boundaries y violaciones detectadas` — `archivo:línea`.
- `## 7. Hallazgos transversales` — lo que el resto de sub-agents debería tomar.

## Restricciones

- Solo lectura del código. `Write` únicamente sobre `audit-outputs/explore-architecture.md`.
- Bash solo para lectura: `ls`, `cat`, `find`, `grep`, `jq`, `wc`, `git log`, `pnpm ls`, `pnpm why`. Nada de `install`, `build`, `git commit`.
- Si un hallazgo es 0 (e.g., sin dependencias circulares), declararlo explícitamente con la metodología usada.
