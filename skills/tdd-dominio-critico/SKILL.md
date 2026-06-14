---
name: tdd-dominio-critico
description: TDD obligatorio para los caminos críticos de dominio de Booster AI — facturación electrónica y DTE (SII), carta de porte, factoring, cálculo de carbono GLEC, pricing, matching de carriers, migraciones de base de datos, y todo lo que toque dinero, datos legales o integridad. Use this skill whenever the user implements, modifies, debugs, or refactors code in packages/dte-provider, packages/factoring-engine, packages/carta-porte-generator, packages/carbon-calculator, packages/pricing-engine, packages/matching-algorithm, apps/document-service, or any database migration. Make sure to use this skill any time the user mentions "DTE", "factura", "boleta", "SII", "carta de porte", "factoring", "pricing", "precio", "matching", "carbono", "GLEC", "migración", "schema change", "money", "dinero" — these paths are non-negotiable TDD. Defers the red-green-refactor mechanics to superpowers:test-driven-development and adds Booster's domain rule about which paths are mandatory.
---

# Skill: TDD en dominio crítico

**Categoría**: stack-discipline + compliance
**Prioridad**: crítica — un bug aquí emite un documento tributario inválido, cobra mal, o corrompe datos auditables
**Relacionado**: `superpowers:test-driven-development` (mecánica), `definicion-de-terminado`, `booster-stack-conventions`, skill `carbon-calculation-glec`

## Regla de dominio

La mecánica de TDD (red → green → refactor, "delete means delete", verify-red obligatorio) la define **`superpowers:test-driven-development`**. Esta skill solo fija **dónde es no-negociable** en Booster, porque son los caminos donde un error tiene consecuencias legales o financieras.

> En estos caminos, NO existe código de producción sin un test que falló primero. Sin excepción de "es chico" ni "tengo apuro".

## Caminos donde TDD es OBLIGATORIO (no "recomendado")

- **DTE / facturación electrónica** (`packages/dte-provider`, `apps/document-service`): un documento mal emitido es un problema con el SII, no un bug interno. Test primero, incluyendo casos de rechazo del proveedor acreditado.
- **Carta de Porte** (`packages/carta-porte-generator`): obligación legal Ley 18.290. Test sobre estructura y campos obligatorios.
- **Factoring** (`packages/factoring-engine`): mueve dinero y expone a la empresa. Test sobre cálculo de exposición y flags.
- **Pricing** (`packages/pricing-engine`): cálculo determinístico. Test sobre cada regla y borde.
- **Carbono GLEC** (`packages/carbon-calculator`): el certificado ESG debe ser re-derivable para auditoría. Test sobre factores de emisión y reproducibilidad.
- **Matching de carriers** (`packages/matching-algorithm`): transparente, determinístico, auditable. Test sobre scoring y por qué un carrier sí/no recibió oferta.
- **Migraciones de BD**: integridad de datos. Test/verificación de la migración y su rollback antes de aplicar.
- **Auth / autorización**: cualquier path de identidad o permisos.

## Procedimiento

1. Invoca `superpowers:test-driven-development` y sigue su ciclo al pie de la letra. Esta skill no lo reemplaza.
2. Para el caso de dominio, el test RED debe describir el **comportamiento de negocio**, no la implementación. Ej.: "una factura con monto neto negativo es rechazada antes de enviarse al SII", no "la función `validate()` retorna false".
3. Incluye al menos un caso de **falla del sistema externo** (proveedor DTE caído, timeout, respuesta de rechazo) — estos caminos fallan en producción, no en el happy path.
4. Cierra con la checklist de `definicion-de-terminado`. Evidencia (output de tests) pegada, no descrita.

## Red Flags específicos de dominio

| Pensamiento | Realidad |
|---|---|
| "El cálculo es simple, lo verifico a mano" | Verificación manual de dinero/impuestos no es auditable ni repetible. |
| "El proveedor DTE casi nunca falla" | "Casi nunca" ocurre en producción. Testea el rechazo y el timeout. |
| "La migración es trivial" | Las migraciones triviales son las que corrompen datos sin rollback probado. |
| "Ya hay tests, agrego mi cambio nomás" | Comportamiento nuevo = test nuevo que falló primero. |
