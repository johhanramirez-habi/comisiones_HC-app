# Queries de comisiones internas Habicredit CO

Pipeline versionado de las comisiones de Colombia (corre como scheduled queries en
BigQuery, proyecto `papyrus-delivery-data`, dataset `habicredit`).

## Orden de ejecución

```
1. comisiones_internas_hc.sql
   Lee main_board, metas_sop, metas_directores_comerciales, rotaciones,
   reprocesos, ANS, graduaciones, etc. y calcula la EJECUCION de cada
   indicador por beneficiado y mes.
   → escribe: habicredit.comisiones_internas_hc

2. comisiones_internas_hc_final.sql
   Lee habicredit.comisiones_internas_hc + habicredit.metas_comisiones_internas,
   aplica quemas manuales, condiciones por indicador (radicación, desembolsos,
   reprocesos, ITAU, CIB...), castigos y el esquema de pago por posición.
   → produce las COMISIONES FINALES (una fila por mes_comision + beneficiado + indicador)
```

## Esquema de salida del query final

| Columna | Tipo | Nota |
|---|---|---|
| `mes_comision` | DATE | Primer día del mes de la comisión |
| `posicion` | STRING | Cargo (define el esquema de pago) |
| `beneficiado` | STRING | Correo del beneficiario |
| `indicador` | STRING | Indicador comisionable |
| `ejecucion` | FLOAT | Ejecución del indicador |
| `meta_value` | FLOAT | Meta vigente (de metas_comisiones_internas) |
| `base_commission` | NUMERIC | Comisión base del esquema |
| `p_ejecucion` | FLOAT | % de cumplimiento (ejecucion/meta) |
| `pago` | NUMERIC | Monto final a pagar |

**Llave única de una comisión:** `mes_comision + beneficiado + indicador`
(así se construye el `id_comision` de la app: `YYYY-MM|correo|indicador`).

## ⚠️ Mantenimiento mensual (manual hoy — candidatos a automatizar)

En `comisiones_internas_hc.sql`:
- **`CREATE TEMP FUNCTION mes_comision`**: tiene la fecha del mes quemada
  (`DATE('2026-06-01')`) — hay que cambiarla cada mes.
- **CTE `semanas_rotacion`**: array de semanas a contemplar por mes (ya está
  precargado hasta 2027-03, revisar festivos).
- **CTE `listas_supervisores_analistas`**: altas/bajas de analistas por supervisor.

En `comisiones_internas_hc_final.sql`:
- **CTE `comisiones_internas` (inicio)**: "quemas" manuales de valores por
  errores de medición (CASE WHEN indicador/beneficiado THEN valor).
- **`UNION ALL` al final**: bonos puntuales agregados a mano por mes.
- **CTE `castigo_operanciones_no_hc`**: multiplicador de castigo vigente.

## Archivos

- `comisiones_internas_hc.sql` — paso 1 (ejecuciones por indicador)
- `comisiones_internas_hc_final.sql` — paso 2 (comisión final con esquema de pago)
- `_originales_rtf/` — respaldos de los archivos RTF originales que compartió Johhan
  (los `.sql` de esta carpeta son la versión convertida a texto plano)
