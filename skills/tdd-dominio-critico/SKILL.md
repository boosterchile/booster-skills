---
name: tdd-dominio-critico
description: Dónde el TDD con rojo exhibido es obligatorio en Booster AI y cómo escribir ese test. Use when implementing, modifying, or refactoring code in packages/transport-documents, apps/document-service, packages/carta-porte-generator, packages/factoring-engine, packages/pricing-engine, packages/carbon-calculator, packages/matching-algorithm, packages/certificate-generator, auth/authz paths, or any database migration. Expands CLAUDE.md §Ciclo de trabajo punto 3; defers red-green-refactor mechanics to superpowers:test-driven-development when available.
---

# Skill: TDD en dominio crítico

**Categoría**: stack-discipline + compliance
**Prioridad**: crítica — un bug aquí archiva mal un documento tributario de un tercero, cobra mal, emite un certificado ESG no re-derivable o corrompe datos auditables
**Norma**: `CLAUDE.md` §Ciclo de trabajo punto 3 ("TDD con rojo exhibido en dominio crítico"). Esta skill es material extendido (ADR-072).
**Relacionado**: `superpowers:test-driven-development` (mecánica, si está instalado), `definicion-de-terminado`, `booster-stack-conventions`, skill `carbon-calculation-glec`

## Regla de dominio

La mecánica de TDD (red → green → refactor, verify-red obligatorio) la define `superpowers:test-driven-development` si está instalado; si no, se aplica igual a mano. Esta skill fija **dónde es no-negociable** en Booster, porque son los caminos donde un error tiene consecuencias legales o financieras.

> En estos caminos no existe código de producción sin un test que falló primero, y **el output del rojo va en la sección Evidencia del PR**. Sin rojo exhibido, no cierra (`CLAUDE.md`).

## Caminos donde TDD es obligatorio

- **Documentos tributarios de terceros** (`packages/transport-documents`, `apps/document-service`): Booster **no emite** DTE (ADR-069); recibe y archiva DTE 33/52 de terceros con extracción TED best-effort (ADR-070). Un archivo mal clasificado o un TED mal parseado afecta el cierre de una orden y la retención de custodia. Test primero, incluyendo PDF sin TED, PDF417 ilegible y foto de baja calidad.
- **Carta de Porte** (`packages/carta-porte-generator`): obligación legal Ley 18.290. Test sobre estructura y campos obligatorios.
- **Certificados** (`packages/certificate-generator`): PDF firmado con KMS + hash; el certificado emitido debe ser re-derivable.
- **Factoring** (`packages/factoring-engine`): mueve dinero y expone a la empresa. Test sobre cálculo de exposición y flags.
- **Pricing** (`packages/pricing-engine`): cálculo determinístico. Test sobre cada regla y borde.
- **Carbono GLEC** (`packages/carbon-calculator`): el certificado ESG debe ser re-derivable para auditoría. Test sobre factores de emisión y reproducibilidad.
- **Matching de carriers** (`packages/matching-algorithm`): transparente, determinístico, auditable. Test sobre scoring y por qué un carrier sí/no recibió oferta.
- **Migraciones de BD**: integridad de datos. Expand/contract (ADR-066); `check-migration-safety.mjs` corre en CI. Rollback verificado antes de aplicar.
- **Auth / autorización**: cualquier path de identidad, permisos o impersonación (`apps/api/src/middleware/`).

## Procedimiento

1. Si `superpowers` está instalado, invoca `superpowers:test-driven-development` y sigue su ciclo. Si no, aplica red → green → refactor a mano.
2. El test RED describe el **comportamiento de negocio**, no la implementación. Ej.: "una guía de despacho sin TED decodificable igual permite cerrar la orden cuando `REQUIRE_TED_DECODE=false`", no "la función `parse()` retorna null".
3. Incluye al menos un caso de **falla del sistema externo** (Routes API caída, WhatsApp/Twilio con timeout, PDF corrupto) — estos caminos fallan en producción, no en el happy path.
4. Corre el test, **copia el output del rojo**, implementa, corre de nuevo, copia el verde. Ambos van en la Evidencia del PR.
5. Cierra con la checklist de `definicion-de-terminado`.

## Red Flags específicos de dominio

| Pensamiento | Realidad |
|---|---|
| "El cálculo es simple, lo verifico a mano" | Verificación manual de dinero/impuestos no es auditable ni repetible. |
| "El servicio externo casi nunca falla" | "Casi nunca" ocurre en producción. Testea el rechazo y el timeout. |
| "Pongo el verde en la Evidencia, el rojo no aporta" | El rojo prueba que el test ejercita el cambio. Sin rojo, el contrato no cierra. |
| "La migración es trivial" | Las migraciones triviales son las que corrompen datos sin rollback probado. |
| "Ya hay tests, agrego mi cambio nomás" | Comportamiento nuevo = test nuevo que falló primero. |
