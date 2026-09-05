---
name: carbon-calculation-glec
description: Cálculo de huella de carbono por viaje según GLEC v3.0 y GHG Protocol en Booster AI. Use when writing, modifying, debugging, or auditing emission calculations in packages/carbon-calculator, adjusting emission factors, reconciling an issued ESG certificate against what the client measures, or wiring measured (CAN bus) vs modelled distance/fuel into the trip lifecycle. Fixes the determinism, auditability, and explicit-degradation rules (never 0, never silent).
---

# Skill: Carbon Footprint Calculation (GLEC v3.0)

**Categoría**: core-engineering + compliance
**Relacionado**: ADR-004 modelo Uber-like, ADR-005 telemetría, ADR-073 tipologías de flota / configuración GLEC, `docs/frentes-vivos.md` Slot 1 (huella punta a punta)

## Overview

Booster AI calcula huella de carbono por viaje según **Global Logistics Emissions Council Framework v3.0** (GLEC v3.0) y GHG Protocol. La implementación vive en `packages/carbon-calculator` como librería pura, determinística, exhaustivamente testeada. El cálculo es **auditable**: dados los mismos inputs, siempre produce el mismo output; y dada una emisión reportada, se puede re-derivar desde los inputs originales.

**Regla de degradación (Slot 1 de `docs/frentes-vivos.md`)**: un viaje cerrado tiene `metricas_viaje.emisiones_kgco2e_reales` poblado, **o** degradación explícita registrada (`emisiones_kgco2e_reales = null` + métrica de data-quality + certificación marcada como degradada). Nunca `0`, nunca fallo silencioso. Hoy la flota puede tener 0 vehículos con CAN funcional (CURRENT.md 2026-07-25): el camino modelado no es la excepción, es el caso común.

## When to Use

- Al escribir nuevos cálculos de emisión
- Al ajustar factores de emisión (nuevos combustibles, nuevos vehicle classes)
- Al debuggear una discrepancia entre certificado ESG emitido y la medición que ve el cliente
- Al actualizar a una nueva versión del GLEC Framework

## Core Process

### 1. Identificar el tipo de cálculo

GLEC v3.0 define emisiones en dos dimensiones:

| Scope GHG | Qué cubre | Método |
|-----------|-----------|--------|
| Scope 1 | Emisiones directas del vehículo (combustible que quema) | **Combustible real** (vía CAN bus Teltonika) si disponible; si no, **distancia × intensity factor** |
| Scope 3 | Emisiones aguas arriba/abajo (producción del combustible, disposición del vehículo, etc.) | Factor GLEC "well-to-tank" multiplicado por consumo |

**Total carbon footprint** = Scope 1 + Scope 3 (GLEC v3.0 los combina).

### 2. Seleccionar método de medición

Orden de prioridad (GLEC recomienda siempre el más preciso disponible):

1. **Actual energy consumption** (preferido): consumo de combustible medido vía CAN bus del Teltonika. Precisión ~95%.
2. **Modelled energy consumption**: consumo estimado con factores de emisión específicos del vehículo (tipo, carga, topografía). Precisión ~80%.
3. **Default energy consumption**: promedio industria por vehicle class GLEC. Precisión ~60%. Usar solo cuando no hay CAN bus ni perfil del vehículo.

Para cada trip, registrar **qué método se usó**. Esto se refleja en el certificado ESG con atributo `precision_method`.

### 3. Identificar factores de emisión

Los factores GLEC v3.0 son tablas publicadas que multiplican consumo/distancia por kg CO2e. Se actualizan periódicamente. En el repo viven como módulos TS de datos, separados de la lógica:

```
packages/carbon-calculator/src/
├── factores/
│   ├── sec-chile-2024.ts       # factores de combustible (fuente SEC Chile 2024)
│   └── defaults-por-tipo.ts    # defaults por tipología de flota (ADR-073)
├── glec/
│   ├── factor-carga.ts         # load factor
│   └── empty-backhaul.ts       # ajuste por retorno vacío
├── modos/                      # modos de cálculo (medido / modelado / default)
├── certificacion/
├── calcular-emisiones.ts       # función pura de entrada
└── tipos.ts
```

Verificar el árbol real antes de editar (`ls packages/carbon-calculator/src`); esta lista es del 2026-09. **Nunca poner un factor numérico dentro de la lógica de cálculo**: todo factor vive en `src/factores/` con fuente y fecha en el nombre o en un comentario de cabecera, y el output del cálculo reporta qué factores usó.

### 4. Calcular con función pura

```typescript
// packages/carbon-calculator/src/calculate.ts
export function calculateTripEmissions(input: TripEmissionInput): TripEmissionResult {
  const method = selectMethod(input);
  const scope1 = calculateScope1(input, method);
  const scope3 = calculateScope3(input, method);

  return {
    scope1_kgco2e: scope1,
    scope3_kgco2e: scope3,
    total_kgco2e: scope1 + scope3,
    intensity_kgco2e_per_tonne_km: (scope1 + scope3) / (input.cargo_weight_t * input.distance_km),
    precision_method: method,
    factors_used: {
      fuel_factor: ...,
      vehicle_intensity: ...,
    },
    glec_version: "3.0",
    calculated_at: new Date().toISOString(),
  };
}
```

**Propiedades no negociables**:
- **Pura**: sin side effects, sin I/O, sin `Date.now()` oculto. Recibe timestamp como input si lo necesita.
- **Determinística**: mismo input → mismo output exacto (hasta precisión IEEE 754).
- **Unit-safe**: usar tipos nominales (`Kilograms`, `Kilometers`, etc.) para prevenir errores de unidades.
- **Retorna factores usados**: el output incluye qué factors numéricos se multiplicaron, para auditabilidad.

### 5. Tests deterministas

```typescript
// packages/carbon-calculator/test/calculate.test.ts
import fixtures from './fixtures/reference-trips.json';

describe('calculateTripEmissions', () => {
  test.each(fixtures)('GLEC reference case: $name', (fixture) => {
    const result = calculateTripEmissions(fixture.input);
    expect(result.scope1_kgco2e).toBeCloseTo(fixture.expected.scope1, 2);
    expect(result.scope3_kgco2e).toBeCloseTo(fixture.expected.scope3, 2);
    expect(result.total_kgco2e).toBeCloseTo(fixture.expected.total, 2);
  });
});
```

`fixtures/reference-trips.json` contiene casos publicados por el GLEC Framework (anexos técnicos) + casos propios. **Si un test falla después de cambiar la tabla de factores, NO cambiar el test — abrir conversación con Product Owner y Auditor ESG**.

### 6. Persistencia auditable

El resultado se persiste en Cloud SQL en `metricas_viaje` (tabla 1:1 con `viajes`, Drizzle `tripMetrics` en `apps/api/src/db/schema.ts`): `emisiones_kgco2e_estimadas`, `emisiones_kgco2e_reales` (`carbonEmissionsKgco2eActual`), `distancia_km_real` (híbrida GPS + Routes API, PR #624) y `cobertura_pct`. El cálculo lo dispara `apps/api/src/services/calcular-metricas-viaje.ts`. Leer el schema antes de escribir persistencia; no asumir tablas ni columnas que no están ahí (nota: `docs/frentes-vivos.md` cita nombres en inglés que no coinciden con el schema; manda el schema).

Lo que debe quedar persistido para poder re-derivar: inputs (distancia y método, carga, tipología), método de precisión, versión GLEC, versión del algoritmo y los factores usados. Si el schema actual no guarda los factores, eso es parte del trabajo, no un detalle opcional.

Consulta de verificación (Slot 1 de `frentes-vivos.md`, con los nombres reales):

```sql
SELECT v.id, m.distancia_km_real, m.emisiones_kgco2e_reales, m.emisiones_kgco2e_estimadas, m.cobertura_pct
FROM viajes v JOIN metricas_viaje m ON m.viaje_id = v.id
WHERE v.recogido_en IS NOT NULL AND v.entregado_en IS NOT NULL
ORDER BY v.entregado_en DESC LIMIT 10;
```

Un backfill que re-deriva certificados ya emitidos tiene **gate del PO** (impacto legal/ESG).

### 7. Certificado ESG

Al cerrar el viaje, `packages/certificate-generator` (invocado desde el lifecycle de entrega en `apps/api`) genera el PDF con:
- Resumen de emisiones
- Método usado (EXACT_CANBUS vs MODELED vs DEFAULT)
- Factores usados (transparencia)
- Hash SHA-256 del cálculo — incluido en el PDF
- Firma digital del PDF con KMS

El hash permite validar meses después que el certificado NO fue alterado.

## Common Rationalizations

| Tentación | Por qué es un error |
|-----------|---------------------|
| "Uso el promedio de combustible estimado aunque haya CAN bus" | Pierde precisión certificable. Siempre usar el método más preciso disponible. |
| "Factores en código para ir más rápido" | Rompe auditabilidad. Siempre en JSON versionado. |
| "Skippeo el hash en el certificado" | Sin hash, el PDF puede ser alterado sin detección. El auditor ESG exige esto. |
| "Redondeo a entero kg CO2e para que se vea bonito" | Pérdida de precisión. Mantener decimales internos; redondeo solo en display. |

## Red Flags

- Test fixture editado para "que pase" después de cambio de factors
- Cálculo con `Math.random()` o `Date.now()` directo
- Commit que cambia factors JSON sin referenciar fuente GLEC
- Certificado sin `glec_version` o `precision_method`
- Intensidad (kgCO2e/tonne-km) fuera de rango razonable (típico camión pesado: 0.05-0.15)

## Exit Criteria

- [ ] Cálculo vive en `packages/carbon-calculator` como función pura
- [ ] Factores en `src/factores/` con fuente + fecha; ninguno inline en la lógica
- [ ] Test escrito primero, rojo exhibido en la Evidencia (`tdd-dominio-critico`); coverage ≥95 %
- [ ] Tests usan fixtures con casos de referencia GLEC
- [ ] Persistencia con inputs + método + factores, verificada contra `schema.ts`
- [ ] Degradación explícita (`null` + métrica) cuando falta insumo; nunca `0`
- [ ] Certificado PDF incluye hash SHA-256 + glec_version + precision_method
- [ ] Cambios a factores revisados por el PO / Sustainability Stakeholder

## Referencias

- GLEC Framework v3.0: https://www.smartfreightcentre.org/en/our-programs/global-logistics-emissions-council/
- GHG Protocol Scope 3 Standard: https://ghgprotocol.org/standards/scope-3-standard
- ISO 14064-2: https://www.iso.org/standard/66454.html
- ADR-004 (modelo Uber-like, Sustainability Stakeholder), ADR-005 (telemetría, CAN bus), ADR-073 (tipologías de flota / configuración GLEC) en `docs/adr/` de `booster-ai`
