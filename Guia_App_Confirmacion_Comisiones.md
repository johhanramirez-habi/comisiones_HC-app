# Guía paso a paso: API de confirmación de comisiones + UI de prueba (BigQuery + FastAPI + Streamlit)

Alineada con el plan de 2 semanas y el AGENTS.md. Enfoque **API-first**: el entregable central es la API (un tercero construirá la interfaz definitiva contra ella); Streamlit es solo un cliente mínimo para probar que el contrato funciona. Todo corre primero en local desde VS Code con Claude Code; el hosting (Cloud Run) se decide después.

## 0. Arquitectura

```
BigQuery (papyrus-delivery-data.habicredit)
  ├── comisiones_resultado        ← lo escribe el motor de cálculo (nunca la API)
  └── comisiones_confirmaciones   ← lo escribe SOLO la API (upsert)
          ▲
      FastAPI  ← entregable central; OpenAPI en /docs es el handoff al tercero
          ▲
      Streamlit  ← UI mínima de prueba; consume la API, NUNCA BigQuery directo
```

Regla clave: la UI de prueba pasa por la API. Si Streamlit leyera BigQuery directo, no estarías validando el contrato que usará el tercero.

## 1. Prerrequisitos

- Acceso de lectura a `comisiones_resultado` y permiso para crear/escribir `comisiones_confirmaciones` en el dataset `habicredit`.
- Python 3.10+, VS Code, Claude Code (extensión o CLI `claude` en la terminal integrada).
- Credenciales locales:
  ```
  gcloud auth application-default login
  ```
  La librería `google-cloud-bigquery` las detecta sola; sin archivos de llaves en desarrollo.
- Copia el `AGENTS.md` del proyecto en la raíz del repo antes de arrancar Claude Code: es el contexto que evita que el agente rompa las convenciones (motor genérico, email como llave, estados, etc.).

## 2. Tabla de seguimiento en BigQuery

`comisiones_confirmaciones` (la única tabla que escribe la API):

| Campo | Tipo | Descripción |
|---|---|---|
| periodo | STRING | mes de la comisión, ej. "2026-07" |
| email | STRING | llave de la persona (nunca el nombre) |
| estado | STRING | pendiente / confirmada / rechazada |
| comentario | STRING | obligatorio si estado = rechazada |
| negocio_id | STRING | opcional, si la disputa es por un negocio puntual |
| actualizado_por | STRING | quién registró la acción |
| fecha_actualizacion | TIMESTAMP | timestamp del upsert |

Pídele a Claude Code el `CREATE TABLE IF NOT EXISTS` junto con el resto del proyecto (paso 3) y versiona el DDL en GitLab.

## 3. Crear el proyecto con Claude Code

1. Carpeta `comisiones-api`, ábrela en VS Code, `claude` en la terminal.
2. Primer prompt (ajusta nombres de dataset/tablas si difieren):

   > Lee AGENTS.md. Construye una API en FastAPI conectada a BigQuery con esta estructura:
   > - `requirements.txt`: fastapi, uvicorn, google-cloud-bigquery, pydantic, python-dotenv; y streamlit + requests para la UI de prueba.
   > - Config por variables de entorno (`.env.example`): GCP_PROJECT, BQ_DATASET, tabla de resultados, tabla de confirmaciones, API_KEY.
   > - DDL `CREATE TABLE IF NOT EXISTS` para `comisiones_confirmaciones` (periodo, email, estado, comentario, negocio_id, actualizado_por, fecha_actualizacion).
   > - Endpoints:
   >   - GET /health
   >   - GET /periodos → periodos disponibles en comisiones_resultado
   >   - GET /comisiones?periodo=&email= → desglose por persona e indicador (email opcional: sin él devuelve todas, para la vista de manager/tercero), incluyendo el estado actual de confirmación
   >   - POST /confirmaciones → {periodo, email, estado: "confirmada"|"rechazada", comentario?, negocio_id?}; upsert con MERGE; rechaza sin comentario = error 422
    >   - GET /confirmaciones?periodo=&estado= → seguimiento
   >   - GET /indicadores → catálogo vigente
   > - Autenticación: header `X-API-Key` validado contra API_KEY en todos los endpoints menos /health.
   > - La API solo escribe en comisiones_confirmaciones; jamás en comisiones_resultado ni en metas.
   > - `ui/app.py`: Streamlit de UNA página que consume la API vía requests (nunca BigQuery directo): selector de periodo, campo de correo, tabla con el desglose, botones Confirmar / Rechazar con comentario.
   > - README con cómo correr todo en local.
   >
   > Propón la estructura de archivos antes de escribir código.

3. Revisa la estructura propuesta, ajusta y deja que genere.

## 4. Estructura esperada

```
comisiones-api/
  app/
    main.py            # FastAPI, routers
    auth.py            # validación X-API-Key
    bigquery.py        # cliente y queries (única capa que toca BQ)
    models.py          # esquemas Pydantic (el contrato)
  sql/
    confirmaciones.sql # DDL versionado
  ui/
    app.py             # Streamlit de prueba (consume la API)
  requirements.txt
  .env.example
  .gitignore           # incluye .env
  AGENTS.md
  README.md
```

## 5. Correr y probar en local

```
pip install -r requirements.txt
uvicorn app.main:app --reload          # API en http://localhost:8000
streamlit run ui/app.py               # UI en http://localhost:8501
```

Prueba en este orden:
1. `http://localhost:8000/docs` — Swagger autogenerado; es el documento que le entregarás al tercero.
2. Desde `/docs`: GET /comisiones con un periodo real → verifica que el desglose cuadre con la hoja de comisiones del mes.
3. POST /confirmaciones con estado "rechazada" sin comentario → debe fallar con 422.
4. Desde Streamlit: confirmar y rechazar → verifica en BigQuery el upsert (cambiar de opinión debe actualizar la fila, no duplicarla).

## 6. Autenticación

- **Ahora (local + tercero):** API key en header `X-API-Key`. Suficiente para desarrollo y para que el tercero integre.
- **Al desplegar:** Cloud Run con la API key como secreto (Secret Manager) y, si la UI definitiva es interna, IAP con el dominio corporativo. La service account del servicio: lectura en `comisiones_resultado`, lectura/escritura solo en `comisiones_confirmaciones`.

## 7. Handoff al tercero

Entregar: URL de la API + `/docs` (OpenAPI) + API key + 2-3 ejemplos de request/response reales (un GET de desglose, un POST de confirmación, un POST de rechazo). El contrato de `models.py` es la fuente de verdad; cualquier cambio de contrato se versiona y se avisa.

## 8. Control de versiones

```
git init && git add . && git commit -m "API confirmación de comisiones v1"
```
`.env` en `.gitignore`. SQL y DDL versionados igual que las consultas del motor.

## 9. Checklist antes de usar con el equipo real

- La API rechaza requests sin API key válida.
- GET /comisiones cuadra contra el cálculo manual del mes (conciliación previa del motor, día 5 del plan).
- Rechazo sin comentario es imposible; todo upsert queda con timestamp y actor.
- La API no puede escribir en `comisiones_resultado` ni `metas` (verifícalo en los permisos de la service account, no solo en el código).
- El tercero puede integrar solo con `/docs`, sin preguntarte nada.
