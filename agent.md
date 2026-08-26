# Contexto — Automatización de comisiones Habicredit (CO y MX)

Rol: Johhan es analista BI, encargado de terminar de automatizar las comisiones de Habicredit Colombia y México.

## Estado de partida (de Confluence)

**CO**: BI Liquidez calcula comisiones desde marzo 2025. Flujo: query SQL versionado en GitLab → scheduled query en BigQuery (`papyrus-delivery-data`) → cruce con Sheet "Ejecución y comisiones" (metas) → tabla oficial → traslado manual a base de Finanzas (`comisiones_internas_hc_finanzas`). Pendiente: integración de nuevas metas, detección de altas/bajas de indicadores, indicadores aún manuales, retroactivos, socialización.

**MX**: sin automatización real. Esquema híbrido 2023/2024 según fecha de aceptación; el pago ocurre en escrituración (meses después de la aceptación); anticipo del 30% que se netea o reversa; comisiones de brokers con reglas propias por fecha. Mayor dificultad: generar histórico confiable, y esto se profundizó después — el verdadero bloqueante es que la info de las cards de Pipefy no siempre llega/sincroniza a BigQuery.

## Entregable 1 — Documento Word

Archivo: `Plan_Automatizacion_Comisiones_CO_MX.docx` (ya generado y entregado).

Incluye diagnóstico, plan CO (metas, indicadores, retroactivos, socialización, traslado a Finanzas), plan MX reestructurado en orden de dependencia:

1. Reconciliación Pipefy ↔ BigQuery como bloqueante principal.
2. Consultas de cálculo e histórico.
3. Anticipos/neteo/brokers.
4. Tablero de socialización para el manager operativo.

También incluye hoja de ruta por fases con duraciones estimadas, riesgos/dependencias y gobernanza. Se agregó una sección 9 (aplicación de confirmación/inconformidad de comisiones, aplicable a todos los usuarios de ambos países, con enrutamiento a BI y enlace al motor de retroactivos).

## Entregable 2 — Guía técnica

Archivo: `Guia_App_Confirmacion_Comisiones.md` (ya generado y entregado).

Paso a paso para construir la app de confirmación con VS Code + Claude Code. Decisiones ya tomadas por el usuario:

- Stack: **Python + Streamlit**.
- Hosting: **por decidir después** (arranca en localhost).
- Acceso: **ambas vistas** (individual por login + vista manager consolidada).

La guía cubre: prerrequisitos (Python, gcloud auth, Claude Code en VS Code), diseño de la tabla de seguimiento `comisiones_confirmaciones` en BigQuery, prompt inicial sugerido para Claude Code, estructura de archivos, conexión a BigQuery, vista individual (con placeholder de correo para probar, y ruta a login real vía Cloud Run + IAP o `streamlit-google-auth` más adelante), vista manager, lógica de botones aceptar/rechazar (MERGE en tabla de seguimiento, nunca en la tabla oficial), pruebas locales, control de versiones en GitLab, y opciones de hosting futuro (Cloud Run recomendado vs Streamlit Community Cloud).

## Mapa del repo (resumen — detalle completo en README.md § "Mapa del repositorio y flujo de datos")

- Motor paso 1 `sql/comisiones_co/comisiones_internas_hc.sql`: calcula ejecución por indicador, escribe `habicredit.comisiones_internas_hc_fn_table`.
- Motor paso 2 `sql/comisiones_co/comisiones_internas_hc_final.sql`: cruza con metas (`habicredit.metas_comisiones_internas`) y calcula el pago final; destino real de esa salida PENDIENTE DE CONFIRMAR (ver README).
- `sql/validaciones/*.sql`: audita metas, catálogo y conciliación motor-vs-Finanzas; solo lee, no escribe. `scripts/validar.py` las corre contra BigQuery y falla si hay hallazgos.
- App Streamlit y API (`api/`), ambas sobre `services/data_service.py`: solo leen la tabla de comisiones y escriben exclusivamente en `comisiones_confirmaciones`.
- Origen de las metas (Sheet → `metas_comisiones_internas`) y catálogo en `data/diccionario_indicadores_comisiones_co.csv`: varios puntos marcados PENDIENTE DE CONFIRMAR en el README (nombre real de la sheet, mecanismo de carga, tabla destino del catálogo).

## Próximo paso natural

Empezar a construir la app en VS Code siguiendo la guía, o seguir detallando/ejecutando las fases del plan de automatización (por ejemplo, la reconciliación Pipefy ↔ BigQuery de México, que quedó marcada como la entrega crítica).
