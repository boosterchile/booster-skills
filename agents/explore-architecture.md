---
name: explore-architecture
description: Mapea estructura de carpetas, entrypoints, módulos principales y boundaries del monorepo Booster AI (9 apps + 21 packages, pnpm/Turborepo).
tools: Read, Grep, Glob, Bash
model: haiku
---

# explore-architecture — Mapeo arquitectónico read-only

## Contexto del proyecto

Booster AI es un monorepo pnpm + Turborepo con:
- **9 apps** en `apps/`: api, web, matching-engine, telemetry-tcp-gateway, telemetry-processor, notification-service, whatsapp-bot, document-service, sms-fallback-gateway.
- **21 packages** en `packages/`: shared-schemas, logger, ai-provider, config, trip-state-machine, codec8-parser, pricing-engine, matching-algorithm, carbon-calculator, whatsapp-client, dte-provider, carta-porte-generator, document-indexer, notification-fan-out, ui-tokens, ui-components, certificate-generator, coaching-generator, driver-scoring, factoring-engine.
- Stack canónico fijado por **ADR-001**: Node.js 22 LTS, pnpm 9, Turborepo, TypeScript 5.8, Biome 1.9, Hono 4, Cloud SQL Postgres + pg driver, React 18 + Vite 6 + @tanstack/react-router + Tailwind 4, vitest + playwright.
- ADRs adicionales: `docs/adr/001..050+`.

## Tareas

Recorre el repo desde la raíz. Identifica y reporta:

1. **Estructura top-level**: árbol de directorios principales con propósito inferido. Distinguir directorios productivos vs scaffolding vs infra vs docs.
2. **Entrypoints**:
   - `package.json` root: scripts canónicos (`dev`, `build`, `test`, `lint`, `typecheck`, `ci`).
   - Por cada app: entrypoint (`src/index.ts` típicamente para Hono, `src/main.tsx` para Vite).
   - Frontend mount + routing strategy (TanStack Router).
3. **Módulos y dependencias internas**: cuáles apps importan qué packages. Detectar dependencias circulares si existen.
4. **Tooling de calidad activo**: Biome config, husky hooks, lint-staged, commitlint, gitleaks, vitest setup, playwright config, coverage thresholds.
5. **CI/CD presente**: `.github/workflows/*.yml` (ci, security, release, e2e), Cloud Build configs si existen, Terraform en `infrastructure/`.
6. **Boundaries arquitectónicos**: identificar violaciones a la regla "domain canónico vive en `packages/shared-schemas/src/domain/`" y "algoritmos viven en `packages/`".

## Salida esperada

Archivo `audit-outputs/01_ARCHITECTURE.md` con secciones:

- `## 1. Estructura de carpetas` — árbol anotado, max 4 niveles de profundidad por rama.
- `## 2. Entrypoints y comandos detectados`
- `## 3. Módulos y dependencias internas` — tabla cruzada apps × packages.
- `## 4. Tooling de calidad activo` — versiones detectadas + configuración.
- `## 5. CI/CD presente`
- `## 6. Boundaries y violaciones detectadas` — citar archivo:línea cuando aplique.
- `## 7. Hallazgos transversales` — observaciones que el resto de subagents deberían tomar.

## Restricciones

- Solo lectura. NUNCA escribir fuera de `audit-outputs/`.
- Bash allowlist: ver `audit-outputs/SESSION_CLAUDE.md`.
- Si un hallazgo es 0 (e.g., no se detectan dependencias circulares), declarar explícitamente "0 hallazgos" con la metodología usada.
