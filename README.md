# App de confirmación de comisiones Habicredit

App en **Python + Streamlit** para que cada usuario de Habicredit (CO y MX) confirme o manifieste inconformidad con sus comisiones, y para que el manager vea el consolidado.

**Regla de oro:** la app escribe **únicamente** en la tabla de seguimiento `comisiones_confirmaciones` (vía `MERGE`). La tabla oficial de comisiones nunca se modifica desde aquí. Los rechazos se enrutan a BI y alimentan el motor de retroactivos.

## Estructura

```
comisiones_HC-app/
├── app.py                     # Punto de entrada Streamlit (login placeholder + tabs)
├── config.py                  # Configuración desde .env
├── requirements.txt
├── .env.example               # Plantilla de configuración
├── services/
│   └── data_service.py        # Backends: DemoService (CSV) y BigQueryService (MERGE)
├── views/
│   ├── individual.py          # Vista por usuario: aceptar / rechazar con comentario
│   └── manager.py             # Vista consolidada: KPIs, rechazos, detalle, export CSV
├── sql/
│   └── create_comisiones_confirmaciones.sql   # DDL de la tabla de seguimiento
└── data/                      # Datos del modo demo (se generan solos)
```

## Mapa del repositorio y flujo de datos

### 1. Archivos `.sql` — cuál es el motor y cuál la salida

**`sql/comisiones_co/comisiones_internas_hc.sql`** — **Motor, paso 1 (ejecución).**
`CREATE OR REPLACE PROCEDURE habicredit.comisiones_internas_hc_fn(mes_comision_input DATE)`.
Lee `habicredit.main_board` y ~20 tablas operativas más (radicación, aprobación, rotaciones,
reprocesos, ANS, graduaciones, escrituración...) más tres tablas de metas propias de este paso
— `habicredit.metas_sop`, `habicredit.metas_directores_comerciales`, `habicredit.meta_analistas_hc`
(**PENDIENTE DE CONFIRMAR** si salen de la misma fuente que las metas del paso 2 o son
independientes; el código no lo dice). Calcula la ejecución de cada indicador por beneficiado y
mes, y hace `INSERT INTO habicredit.comisiones_internas_hc_fn_table`.

**`sql/comisiones_co/comisiones_internas_hc_final.sql`** — **Motor, paso 2 (comisión final).**
Lee `habicredit.comisiones_internas_hc_fn_table` (salida del paso 1) y hace `LEFT JOIN` contra
`habicredit.metas_comisiones_internas` (ver flujo de metas, punto 2) por
`email = beneficiado AND metric_category = indicador AND effective_date = mes_comision`. Aplica
quemas manuales por indicador/beneficiado/mes, condiciones especiales por indicador (radicación,
desembolsos, reprocesos, ITAU, CIB...) y el esquema de pago según `posicion` (CTE
`reglas_generales`), con `WHERE meta_value IS NOT NULL` — una fila sin meta vigente ese mes no se
comisiona. Termina en un `SELECT` (columnas: `mes_comision, posicion, beneficiado, indicador,
ejecucion, meta_value, base_commission, p_ejecucion, pago`) más varios `UNION ALL` de ajustes
puntuales por mes.
⚠️ **PENDIENTE DE CONFIRMAR:** el `CREATE OR REPLACE VIEW comisiones_internas_hc_final_vw` que
envuelve la query está comentado en el archivo (línea 1 y línea final), así que tal como está
versionado es un `SELECT` plano, no una vista. Tampoco hay en el repo un DDL que diga en qué
tabla/vista real aterriza este resultado en BigQuery: el repo usa dos nombres para "la tabla de
comisiones" en lugares distintos — `comisiones_internas_hc_final` (default en `.env.example`, y
nombre del export en `data/`) y `comisiones_internas_hc_finanzas` (default *hardcodeado* en
`config.py`, y la "base de Finanzas" de `agent.md`). No hay evidencia en código de cuál de las
dos recibe directamente este `SELECT` y cuál es la copia manual.

**`sql/create_comisiones_confirmaciones.sql`** — DDL de `habicredit.comisiones_confirmaciones`,
la única tabla que escribe la app/API (vía `MERGE`); nunca la toca el motor.

**`sql/validaciones/validacion_metas.sql`** — Solo lectura. Corre 5 checks de calidad sobre
`habicredit.metas_comisiones_internas` (correos vacíos, `metric_category` fuera del catálogo
`habicredit.diccionario_indicadores_comisiones_co`, duplicados `email+metric_category+effective_date`,
`base_commission` < 1.000.000, `meta_value` fuera de `[0,1]` cuando `unit='%'`).

**`sql/validaciones/diff_indicadores.sql`** — Solo lectura. Anti-join en ambas direcciones entre
`metric_category` (en `metas_comisiones_internas`) e `indicador` (en el catálogo).

**`sql/validaciones/conciliacion.sql`** — Solo lectura. Compara `SUM(pago)` por
`mes_comision + beneficiado` entre `comisiones_internas_hc_final` (motor) y
`comisiones_internas_hc_finanzas` (manual/Finanzas); solo devuelve filas con diferencia != 0.
Hereda el mismo **PENDIENTE DE CONFIRMAR** de arriba sobre cuál nombre es cuál.

### 2. Flujo de metas: Sheet → BigQuery → motor

- **Origen:** `agent.md` describe la fuente como el Sheet **"Ejecución y comisiones"**. Este
  enunciado la llama **"Metas comisiones internas HC"**, nombre que coincide con el archivo local
  `data/Metas comisiones internas HC - data.csv` (columnas: `rule_id, role, employee,
  metric_category, meta_value, base_commission, unit, description, effective_date, email, Check`).
  ⚠️ **PENDIENTE DE CONFIRMAR:** no hay evidencia en el código de que "Ejecución y comisiones" y
  "Metas comisiones internas HC" sean la misma hoja (podrían ser dos hojas o dos nombres de la
  misma; el repo no lo dice).
- **Tabla en BigQuery:** `` `papyrus-delivery-data.habicredit.metas_comisiones_internas` ``. Este
  es el nombre exacto de la tabla externa que referencian todos los `JOIN` de metas en
  `comisiones_internas_hc_final.sql`.
  ⚠️ **PENDIENTE DE CONFIRMAR:** no existe en el repo ningún `CREATE EXTERNAL TABLE ...
  OPTIONS(format='GOOGLE_SHEETS', ...)` ni ningún job de carga para esta tabla, así que no se
  puede verificar en código si es una external table de BigQuery vinculada en vivo al Sheet o una
  tabla nativa alimentada por un proceso de carga aparte. Solo se puede confirmar *cómo la
  consume* el motor, no *cómo se llena*.
- **Consumo por el motor:** en `comisiones_internas_hc_final.sql`, el `CTE main` y los CTEs de
  condición (`condicion_rad`, `condicion_inmo_rad`, `condicion_reprocesos`,
  `condicion_reprocesos_kam`, `condicion_vinculaciones_itau`, `condicion_desembolsos`,
  `condicion_desembolsos_gs`, `condicion_radicacion_cib`) hacen `LEFT JOIN` contra
  `metas_comisiones_internas` por `email + metric_category + effective_date` para traer
  `meta_value` y `base_commission` vigentes ese mes. Sin fila vigente en metas, la comisión de esa
  fila no se paga (`WHERE meta_value IS NOT NULL`).

### 3. Diccionario de indicadores (`data/`)

`data/diccionario_indicadores_comisiones_co.csv` — catálogo con columnas `indicador, definicion,
unidad, fuente, vista_ejecucion, activo_desde, activo_hasta` (55 filas). Ningún código Python de
este repo lo lee (no hay referencia fuera de `sql/validaciones/`).
⚠️ **PENDIENTE DE CONFIRMAR:** qué tabla real de BigQuery lo alimenta. `validacion_metas.sql` y
`diff_indicadores.sql` asumen `` `papyrus-delivery-data.habicredit.diccionario_indicadores_comisiones_co` ``
(mismo nombre que el CSV) porque no hay en el repo ninguna evidencia de un nombre distinto; si el
catálogo vive en BigQuery con otro nombre, hay que ajustar esas dos consultas.

### 4. Qué lee y qué escribe cada componente

| Componente | Lee | Escribe |
|---|---|---|
| Motor paso 1 (`comisiones_internas_hc.sql`) | `main_board` + ~20 tablas operativas, `metas_sop`, `metas_directores_comerciales`, `meta_analistas_hc` | `habicredit.comisiones_internas_hc_fn_table` |
| Motor paso 2 (`comisiones_internas_hc_final.sql`) | `comisiones_internas_hc_fn_table`, `metas_comisiones_internas` | `SELECT` final (destino real: **PENDIENTE DE CONFIRMAR**, ver punto 1) |
| App Streamlit (`services/data_service.py`) | tabla configurada en `BQ_TABLA_COMISIONES` (solo lectura), `comisiones_confirmaciones` (lectura) | `comisiones_confirmaciones` (`MERGE` vía `responder_comision`) — nunca la tabla de comisiones |
| API futura (`api/`, sobre `services/data_service.py`) | igual que la app | igual que la app — nunca `comisiones_resultado` ni metas |
| `sql/validaciones/*.sql` | `metas_comisiones_internas`, `diccionario_indicadores_comisiones_co` (nombre asumido), `comisiones_internas_hc_final`, `comisiones_internas_hc_finanzas` | nada — solo `SELECT` |
| `scripts/validar.py` | ejecuta los 3 `.sql` de arriba contra BigQuery | nada (imprime hallazgos, sale con `exit 1` si hay alguno) |

## Puesta en marcha (local)

```bash
cd ~/Documents/comisiones_HC-app

# 1. Entorno virtual
python3 -m venv .venv
source .venv/bin/activate

# 2. Dependencias
pip install -r requirements.txt

# 3. Configuración
cp .env.example .env    # arranca en APP_MODE=demo

# 4. Ejecutar
streamlit run app.py
```

Se abre en `http://localhost:8501`. En modo **demo** hay 4 usuarios de ejemplo (incluido `johhanramirez@habi.co`, que además es manager y ve ambas pestañas).

## Pasar a producción (BigQuery)

1. **Autenticarse:**
   ```bash
   gcloud auth application-default login
   ```
2. **Crear la tabla de seguimiento** (una sola vez): ejecutar `sql/create_comisiones_confirmaciones.sql` en BigQuery.
3. **Ajustar `.env`:** `APP_MODE=prod`, y verificar `GCP_PROJECT`, `BQ_DATASET`, `BQ_TABLA_COMISIONES`, `BQ_TABLA_CONFIRMACIONES`, `MANAGER_EMAILS`.
4. **Ajustar el SELECT** de `BigQueryService.get_comisiones()` en `services/data_service.py` a los nombres reales de columnas de la tabla oficial (está marcado con `TODO`). La app espera: `id_comision`, `periodo`, `correo_usuario`, `nombre`, `indicador`, `meta`, `ejecucion`, `cumplimiento`, `monto_comision` — si la tabla oficial usa otros nombres, basta con aliasarlos en ese query.

## Roles

- **Usuario individual:** ingresa su correo (placeholder de login) y ve solo sus comisiones. Puede aceptar, o rechazar con comentario obligatorio, y cambiar su respuesta.
- **Manager:** correos listados en `MANAGER_EMAILS` (`.env`). Ve pestaña adicional con filtros (periodo/usuario/estado), KPIs, panel de rechazos y descarga en CSV.

## Próximos pasos (según el plan)

- [ ] Login real: Cloud Run + IAP (recomendado) o `streamlit-google-auth`.
- [ ] Hosting: Cloud Run (recomendado) vs Streamlit Community Cloud.
- [ ] Notificación a BI cuando llega un rechazo (correo/Slack).
- [ ] Conexión del flujo de rechazos con el motor de retroactivos.
- [ ] Versionar este repo en GitLab.
