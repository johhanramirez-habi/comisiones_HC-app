-- Validaciones de calidad sobre la tabla de metas (Sheet "Ejecucion y comisiones").
-- Cada bloque detecta un tipo de hallazgo distinto; se devuelven todos juntos
-- para que scripts/validar.py los imprima y falle si hay al menos una fila.
--
-- Catalogo de indicadores vigentes: ajustar el nombre de la tabla si el
-- diccionario (`data/Diccionario_indicadores_comisiones_CO_v2 - indicadores.csv`)
-- se carga con otro nombre en BigQuery.

WITH metas AS (
    SELECT *
    FROM `papyrus-delivery-data.habicredit.metas_comisiones_internas`
)

, correos_vacios AS (
    SELECT
        'correo_vacio'  AS tipo_hallazgo,
        rule_id, role, employee, email, metric_category, unit,
        meta_value, base_commission, effective_date,
        'El correo (email) esta vacio o nulo' AS detalle
    FROM metas
    WHERE email IS NULL OR TRIM(email) = ''
)

, indicadores_fuera_catalogo AS (
    SELECT
        'indicador_fuera_de_catalogo' AS tipo_hallazgo,
        m.rule_id, m.role, m.employee, m.email, m.metric_category, m.unit,
        m.meta_value, m.base_commission, m.effective_date,
        CONCAT('metric_category "', m.metric_category, '" no existe en el catalogo de indicadores') AS detalle
    FROM metas m
    LEFT JOIN `papyrus-delivery-data.habicredit.diccionario_indicadores_comisiones_co` cat
        ON cat.indicador = m.metric_category
    WHERE m.metric_category IS NOT NULL
      AND cat.indicador IS NULL
)

, duplicados AS (
    SELECT
        'duplicado_persona_indicador_periodo' AS tipo_hallazgo,
        rule_id, role, employee, email, metric_category, unit,
        meta_value, base_commission, effective_date,
        CONCAT(
            'Hay ', CAST(COUNT(*) OVER (PARTITION BY email, metric_category, effective_date) AS STRING),
            ' filas para email + metric_category + effective_date'
        ) AS detalle
    FROM metas
    QUALIFY COUNT(*) OVER (PARTITION BY email, metric_category, effective_date) > 1
)

, montos_bajos AS (
    SELECT
        'monto_cop_menor_a_1_millon' AS tipo_hallazgo,
        rule_id, role, employee, email, metric_category, unit,
        meta_value, base_commission, effective_date,
        CONCAT('base_commission = ', CAST(base_commission AS STRING), ' COP (< 1.000.000)') AS detalle
    FROM metas
    WHERE base_commission IS NOT NULL
      AND base_commission < 1000000
)

, porcentajes_fuera_rango AS (
    SELECT
        'porcentaje_fuera_de_rango' AS tipo_hallazgo,
        rule_id, role, employee, email, metric_category, unit,
        meta_value, base_commission, effective_date,
        CONCAT('meta_value = ', CAST(meta_value AS STRING), ' fuera de [0,1] para unit = "%"') AS detalle
    FROM metas
    WHERE unit = '%'
      AND (meta_value < 0 OR meta_value > 1)
)

SELECT * FROM correos_vacios
UNION ALL
SELECT * FROM indicadores_fuera_catalogo
UNION ALL
SELECT * FROM duplicados
UNION ALL
SELECT * FROM montos_bajos
UNION ALL
SELECT * FROM porcentajes_fuera_rango
ORDER BY tipo_hallazgo, effective_date, email, metric_category
