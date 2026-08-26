-- Conciliacion motor vs calculo manual, por beneficiado (email) y mes_comision.
--
-- "Motor"  = salida automatizada del pipeline (comisiones_internas_hc_final).
-- "Manual" = base de Finanzas (comisiones_internas_hc_finanzas), poblada hoy
--            con traslado manual desde la tabla oficial (ver agent.md).
--
-- Se redondea a 2 decimales antes de comparar para no marcar como diferencia
-- el ruido de punto flotante; solo se devuelven filas con diferencia != 0.

WITH motor AS (
    SELECT
        mes_comision,
        beneficiado,
        ROUND(SUM(pago), 2) AS pago_motor
    FROM `papyrus-delivery-data.habicredit.comisiones_internas_hc_final`
    GROUP BY mes_comision, beneficiado
)

, manual AS (
    SELECT
        mes_comision,
        beneficiado,
        ROUND(SUM(pago), 2) AS pago_manual
    FROM `papyrus-delivery-data.habicredit.comisiones_internas_hc_finanzas`
    GROUP BY mes_comision, beneficiado
)

SELECT
    COALESCE(motor.mes_comision, manual.mes_comision) AS mes_comision,
    COALESCE(motor.beneficiado, manual.beneficiado)   AS beneficiado,
    COALESCE(motor.pago_motor, 0)                      AS pago_motor,
    COALESCE(manual.pago_manual, 0)                    AS pago_manual,
    ROUND(COALESCE(motor.pago_motor, 0) - COALESCE(manual.pago_manual, 0), 2) AS diferencia
FROM motor
FULL OUTER JOIN manual
    ON manual.mes_comision = motor.mes_comision
    AND manual.beneficiado = motor.beneficiado
WHERE ROUND(COALESCE(motor.pago_motor, 0) - COALESCE(manual.pago_manual, 0), 2) != 0
ORDER BY mes_comision DESC, ABS(diferencia) DESC
