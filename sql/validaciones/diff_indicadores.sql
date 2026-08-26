-- Detecta desalineacion entre los indicadores usados en la tabla de metas
-- (metric_category) y el catalogo oficial de indicadores (data/Diccionario_
-- indicadores_comisiones_CO_v2 - indicadores.csv, cargado en BigQuery).
--
-- Cubre el pendiente de agent.md: "deteccion de altas/bajas de indicadores".
-- Ajustar el nombre de la tabla del catalogo si difiere.

WITH metas_indicadores AS (
    SELECT DISTINCT metric_category AS indicador
    FROM `papyrus-delivery-data.habicredit.metas_comisiones_internas`
    WHERE metric_category IS NOT NULL
)

, catalogo_indicadores AS (
    SELECT DISTINCT indicador
    FROM `papyrus-delivery-data.habicredit.diccionario_indicadores_comisiones_co`
    WHERE indicador IS NOT NULL
)

, en_metas_sin_catalogo AS (
    SELECT
        'en_metas_sin_catalogo' AS origen,
        mi.indicador,
        'metric_category presente en metas_comisiones_internas pero sin entrada en el catalogo' AS detalle
    FROM metas_indicadores mi
    LEFT JOIN catalogo_indicadores ci ON ci.indicador = mi.indicador
    WHERE ci.indicador IS NULL
)

, en_catalogo_sin_metas AS (
    SELECT
        'en_catalogo_sin_metas' AS origen,
        ci.indicador,
        'indicador definido en el catalogo pero nunca usado como metric_category en metas_comisiones_internas' AS detalle
    FROM catalogo_indicadores ci
    LEFT JOIN metas_indicadores mi ON mi.indicador = ci.indicador
    WHERE mi.indicador IS NULL
)

SELECT * FROM en_metas_sin_catalogo
UNION ALL
SELECT * FROM en_catalogo_sin_metas
ORDER BY origen, indicador
