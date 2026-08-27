--CREATE OR REPLACE VIEW `papyrus-delivery-data.habicredit.comisiones_internas_hc_final_vw` AS (
    WITH comisiones_internas AS (

        SELECT
            *
            EXCEPT(ejecucion),
            -- Quema de valores por errores en la medición o en las tablas. Se hacen arreglos de manera manual
            CASE

                WHEN mes_comision = '2026-06-01' AND indicador = 'reproceso_creditos' AND beneficiado = 'leidymoscoso@habi.co' THEN 63 --61
                WHEN mes_comision = '2026-06-01' AND indicador = 'reproceso_creditos_monto' AND beneficiado = 'leidymoscoso@habi.co' THEN 19048623493 --16800798800

                WHEN mes_comision = '2026-06-01' AND indicador = 'reproceso_creditos' AND beneficiado = 'yudyzamudio@habicredit.co' THEN 59
                WHEN mes_comision = '2026-06-01' AND indicador = 'reproceso_creditos_monto' AND beneficiado = 'yudyzamudio@habicredit.co' THEN 20300678535


                WHEN mes_comision = '2026-07-01' AND indicador = 'reproceso_creditos' AND beneficiado = 'leidymoscoso@habi.co' THEN 72 --61
                WHEN mes_comision = '2026-07-01' AND indicador = 'reproceso_creditos_monto' AND beneficiado = 'leidymoscoso@habi.co' THEN 20357405848 --16800798800

                WHEN mes_comision = '2026-07-01' AND indicador = 'reproceso_creditos' AND beneficiado = 'yudyzamudio@habicredit.co' THEN 68
                WHEN mes_comision = '2026-07-01' AND indicador = 'reproceso_creditos_monto' AND beneficiado = 'yudyzamudio@habicredit.co' THEN 22353942971

                WHEN mes_comision = '2026-07-01' AND indicador = 'firma_ordenes_ofertas_escrituras' AND beneficiado = 'tatianatorres@habicredit.co' THEN 75

                WHEN mes_comision = '2026-07-01' AND indicador = 'firma_ordenes_ofertas_escrituras' AND beneficiado = 'alejandraorganista@habi.co' THEN ejecucion - 13
                WHEN mes_comision = '2026-07-01' AND indicador = 'firma_ordenes_ofertas_escrituras' AND beneficiado = 'maryipoveda@habicredit.co' THEN ejecucion - 27
                WHEN mes_comision = '2026-07-01' AND indicador = 'firma_ordenes_ofertas_escrituras' AND beneficiado = 'jeydirodriguez@habicredit.co' THEN ejecucion - 20
                WHEN mes_comision = '2026-07-01' AND indicador = 'firma_ordenes_ofertas_escrituras' AND beneficiado = 'nohoravarela@habicredit.co' THEN ejecucion + 1



                
    ------------------

                --WHEN indicador = 'monto_desembolso_leg' AND beneficiado = 'yessicabarrera@habicredit.co' THEN ejecucion + 50000000

                --WHEN indicador = 'tiempo_recaudo_garantias' AND beneficiado = 'jeydirodriguez@habicredit.co' THEN 0.08
                --WHEN indicador = 'tiempo_recaudo_garantias' AND beneficiado = 'nohoravarela@habicredit.co' THEN 0.08

            
                /*WHEN indicador = 'radicacion' AND beneficiado = 'angiealvarado@habicredit.co' THEN 249
                WHEN indicador = 'radicacion_monto' AND beneficiado = 'angiealvarado@habicredit.co' THEN null

                WHEN indicador = 'radicacion' AND beneficiado = 'ginadiaz@habicredit.co' THEN 127
                WHEN indicador = 'radicacion_monto' AND beneficiado = 'ginadiaz@habicredit.co' THEN null
                

                WHEN indicador = 'radicacion_cib' AND beneficiado = 'glorialeon@habi.co' THEN 87.32352941
                WHEN indicador = 'radicacion_cib' AND beneficiado = 'ladyparra@habicredit.co' THEN 85.41176471
                WHEN indicador = 'radicacion_cib' AND beneficiado = 'nidiasanchez@habicredit.co' THEN 90.58823529
                WHEN indicador = 'radicacion_cib' AND beneficiado = 'yulianagarcia@habi.co' THEN 88.91176471
                WHEN indicador = 'radicacion_cib' AND beneficiado = 'coordinadoribuyerliquidez@habicredit.co' THEN 352.2352941

                */


            ELSE ejecucion
            END ejecucion,

        --FROM `papyrus-delivery-data.habicredit.comisiones_internas_hc`
        FROM `papyrus-delivery-data.habicredit.comisiones_internas_hc_fn_table`
        WHERE mes_comision <= DATE_TRUNC(CURRENT_DATE('-5'), MONTH)

    )

    , condicion_rad AS (
        SELECT 

            mes_comision, beneficiado, indicador,
            SAFE_DIVIDE(ejecucion, meta_value) p_ejecucion_rad,

        FROM comisiones_internas ci
        LEFT JOIN  `papyrus-delivery-data.habicredit.metas_comisiones_internas` mci ON mci.email = ci.beneficiado AND mci.effective_date = ci.mes_comision
        AND mci.metric_category = ci.indicador AND effective_date = mes_comision
        WHERE indicador = 'radicacion_monto' OR indicador = 'radicacion' 
        QUALIFY ROW_NUMBER() OVER (PARTITION BY mes_comision, beneficiado ORDER BY p_ejecucion_rad DESC) = 1
    )

    , condicion_inmo_rad AS (
        SELECT 

            mes_comision, beneficiado, indicador,
            SAFE_DIVIDE(ejecucion, meta_value) p_ejecucion_inmo_rad,

        FROM comisiones_internas ci
        LEFT JOIN  `papyrus-delivery-data.habicredit.metas_comisiones_internas` mci ON mci.email = ci.beneficiado AND mci.effective_date = ci.mes_comision
        AND mci.metric_category = ci.indicador AND effective_date = mes_comision
        WHERE indicador = 'radicaciones_inmo_ciudades_monto' OR indicador = 'radicaciones_inmo_ciudades' 
        QUALIFY ROW_NUMBER() OVER (PARTITION BY mes_comision, beneficiado ORDER BY p_ejecucion_inmo_rad DESC) = 1
    )

    , condicion_reprocesos AS (
        SELECT 

            mes_comision, beneficiado, indicador,
            SAFE_DIVIDE(ejecucion, meta_value) p_ejecucion_repro,

        FROM comisiones_internas ci
        LEFT JOIN  `papyrus-delivery-data.habicredit.metas_comisiones_internas` mci ON mci.email = ci.beneficiado AND mci.effective_date = ci.mes_comision
        AND mci.metric_category = ci.indicador AND effective_date = mes_comision
        WHERE indicador = 'reproceso_creditos' OR indicador = 'reproceso_creditos_monto' 
        QUALIFY ROW_NUMBER() OVER (PARTITION BY mes_comision, beneficiado ORDER BY p_ejecucion_repro DESC) = 1
    )

    , condicion_reprocesos_kam AS (
        SELECT 

            mes_comision, beneficiado, indicador,
            SAFE_DIVIDE(ejecucion, meta_value) p_ejecucion_repro_kam,

        FROM comisiones_internas ci
        LEFT JOIN  `papyrus-delivery-data.habicredit.metas_comisiones_internas` mci ON mci.email = ci.beneficiado AND mci.effective_date = ci.mes_comision
        AND mci.metric_category = ci.indicador AND effective_date = mes_comision
        WHERE indicador = 'reprocesos_kam' OR indicador = 'reprocesos_monto' 
        QUALIFY ROW_NUMBER() OVER (PARTITION BY mes_comision, beneficiado ORDER BY p_ejecucion_repro_kam DESC) = 1
    )

    , condicion_vinculaciones_itau AS (
        SELECT 

            mes_comision, beneficiado, indicador,
            SAFE_DIVIDE(ejecucion, meta_value) p_ejecucion_vinculaciones_itau

        FROM comisiones_internas ci
        LEFT JOIN  `papyrus-delivery-data.habicredit.metas_comisiones_internas` mci ON mci.email = ci.beneficiado AND mci.effective_date = ci.mes_comision
        AND mci.metric_category = ci.indicador AND effective_date = mes_comision
        WHERE indicador = 'vinculacion_itau' OR indicador = 'vinculacion_itau_monto' 
        QUALIFY ROW_NUMBER() OVER (PARTITION BY mes_comision, beneficiado ORDER BY p_ejecucion_vinculaciones_itau DESC) = 1
    )

    , condicion_desembolsos AS (

        WITH main AS (
            SELECT 

            mes_comision, beneficiado, indicador,
            SAFE_DIVIDE(ejecucion, meta_value) p_ejecucion_desembolso,

        FROM comisiones_internas ci
        LEFT JOIN  `papyrus-delivery-data.habicredit.metas_comisiones_internas` mci ON mci.email = ci.beneficiado AND mci.effective_date = ci.mes_comision
        AND mci.metric_category = ci.indicador 
        WHERE posicion =  'Analista Legalización' AND (indicador = 'desembolsos' OR indicador = 'monto_desembolso_leg')
        --QUALIFY ROW_NUMBER() OVER (PARTITION BY mes_comision, beneficiado ORDER BY p_ejecucion_desembolso DESC) = 1
        )

        SELECT 
            mes_comision, beneficiado, 
            'desembolsos' AS indicador,
            AVG(p_ejecucion_desembolso) p_ejecucion_desembolso
        FROM main
        GROUP BY 1,2

    )

    , condicion_desembolsos_gs AS (

        WITH main AS (
            SELECT 

            mes_comision, beneficiado, indicador,
            SAFE_DIVIDE(ejecucion, meta_value) p_ejecucion_desembolso,

        FROM comisiones_internas ci
        LEFT JOIN  `papyrus-delivery-data.habicredit.metas_comisiones_internas` mci ON mci.email = ci.beneficiado AND mci.effective_date = ci.mes_comision
        AND mci.metric_category = ci.indicador 
        WHERE posicion IN ('Supervisor Legalización', 'Gerente Ops Liquidez')  AND (indicador = 'cantidad_desembolsos' OR indicador = 'monto_desembolso')
        --QUALIFY ROW_NUMBER() OVER (PARTITION BY mes_comision, beneficiado ORDER BY p_ejecucion_desembolso DESC) = 1
        )

        SELECT 
            mes_comision, beneficiado, 
            'cantidad_desembolsos' AS indicador,
            AVG(p_ejecucion_desembolso) p_ejecucion_desembolso
        FROM main
        GROUP BY 1,2

    )

    , condicion_radicacion_cib AS (

        WITH main AS (
            SELECT 

            mes_comision, beneficiado, indicador,
            SAFE_DIVIDE(ejecucion, meta_value) p_ejecucion_radicacion_cib,

        FROM comisiones_internas ci
        LEFT JOIN  `papyrus-delivery-data.habicredit.metas_comisiones_internas` mci ON mci.email = ci.beneficiado AND mci.effective_date = ci.mes_comision
        AND mci.metric_category = ci.indicador 
        WHERE posicion IN ('Director ibuyer', 'Ejecutivo ibuyer')  AND (indicador = 'radicacion_cib' OR indicador = 'radicacion_cib_u')
        )

        SELECT 
            mes_comision, beneficiado, 
            'radicacion_cib' AS indicador,
            AVG(p_ejecucion_radicacion_cib) p_ejecucion_radicacion_cib
        FROM main
        GROUP BY 1,2

    )


    , castigo_operanciones_no_hc AS (

        SELECT 
            mes_comision AS mes_comision_castigo_no_hc, 
            posicion AS posicion_castigo_no_hc,
            beneficiado AS beneficiado_castigo_no_hc,
            IF(ejecucion = 1.0, 0.9, 1) AS multiplicador_castigo --- Se multiplica cada indicador por el porcentaje de castigo. Se coloca acá el porcentaje de castigo que en 2025-03 es de 10% por lo tanto se coloca 0.9
        FROM comisiones_internas 
        WHERE indicador IN ('castigo_monto_supervisor', 'castigo_monto_analista')

    )

    /*,  validacion_base_nomina AS (

        SELECT 
            role, employee, effective_date, email, CORREO_CORPORATIVO, Esquema,
            CASE 
                WHEN REPLACE(role, 'Analista', 'Analistas') = Esquema THEN 1
                WHEN role = 'K.A.M. - General' AND Esquema = 'K.A.M. (Key Account Manager) - General' THEN 1
                WHEN role = 'Analista de filtros (Estados)' AND Esquema = 'Analistas de Radicación' THEN 1
                WHEN role = 'Ejecutivo Comercial Habicredit' AND Esquema = 'Ejecutivo Comercial' THEN 1
                WHEN role = 'Ejecutivo Comercial Cero Goles' AND Esquema = 'Ejecutivo Comercial' THEN 1
                WHEN role = 'Supervisor de Pre-legalización' AND Esquema = 'Supervisor de Pre - legalización' THEN 1
                WHEN role = 'Analista de Pre-legalización' AND Esquema = 'Analistas de Pre - legalización' THEN 1
                WHEN role = 'Ejecutivo Comercial Colombianos en el exterior' AND Esquema = 'Ejecutivo COLEX' THEN 1

            END valdador_esquema,
        FROM `papyrus-delivery-data.habicredit.metas_comisiones_internas` mci
        LEFT JOIN `papyrus-delivery-data.habicredit.base_nomina_comisiones_finanzas` b ON mci.email = b.CORREO_CORPORATIVO
        --WHERE effective_date = '2025-08-01' 
        QUALIFY ROW_NUMBER() OVER(PARTITION BY effective_date, email) = 1

    ) */

    , main AS (
        SELECT 

            ci.*,
            meta_value,
            base_commission,
            -- Se hace este producto debido a políticas de finanzas
            --valdador_esquema * (
            CASE
                WHEN ci.indicador = 'radicacion_monto' OR ci.indicador = 'radicacion' THEN 
                    IF(p_ejecucion_rad = SAFE_DIVIDE(ejecucion, meta_value), p_ejecucion_rad, NULL)

                WHEN ci.indicador = 'radicaciones_inmo_ciudades_monto' OR ci.indicador = 'radicaciones_inmo_ciudades' THEN 
                    IF(p_ejecucion_inmo_rad = SAFE_DIVIDE(ejecucion, meta_value), p_ejecucion_inmo_rad, NULL)

                WHEN ci.indicador = 'reproceso_creditos' OR ci.indicador = 'reproceso_creditos_monto' THEN 
                    IF(p_ejecucion_repro = SAFE_DIVIDE(ejecucion, meta_value), p_ejecucion_repro, NULL)

                WHEN ci.indicador = 'reprocesos_kam' OR ci.indicador = 'reprocesos_monto' THEN 
                    IF(p_ejecucion_repro_kam = SAFE_DIVIDE(ejecucion, meta_value), p_ejecucion_repro_kam, NULL)

                WHEN ci.indicador = 'vinculacion_itau' OR ci.indicador = 'vinculacion_itau_monto' THEN 
                    IF(p_ejecucion_vinculaciones_itau = SAFE_DIVIDE(ejecucion, meta_value), p_ejecucion_vinculaciones_itau, NULL)

                WHEN ci.indicador = 'monto_desembolso' AND ci.posicion IN ('Supervisor Legalización') THEN NULL
                WHEN ci.indicador = 'cantidad_desembolsos' THEN cd_gs.p_ejecucion_desembolso
                
                WHEN ci.indicador = 'monto_desembolso_leg' AND ci.posicion IN ('Analista Legalización')THEN NULL
                WHEN ci.indicador = 'desembolsos' THEN cd_a.p_ejecucion_desembolso

                WHEN (ci.indicador = 'radicacion_cib_u' OR ci.indicador = 'radicacion_monto_cib') AND (ci.posicion IN ('Director ibuyer', 'Ejecutivo ibuyer')) THEN NULL
                WHEN ci.indicador = 'radicacion_cib' THEN cr_cib.p_ejecucion_radicacion_cib
                
                WHEN ci.indicador = 'dias_aprobacion' THEN
                    SAFE_DIVIDE(meta_value, ejecucion)
                WHEN ci.indicador = 'dias_sancion' THEN
                    SAFE_DIVIDE(meta_value, ejecucion)
                WHEN ci.indicador = 'devolucion_broker_formados' THEN
                    SAFE_DIVIDE(meta_value, ejecucion)
                WHEN ci.indicador = 'cumplimiento_ans' THEN
                IF(ejecucion <= meta_value, 1, NULL)
                WHEN ci.indicador = 'ans_ibuyer' THEN
                IF(ejecucion <= meta_value, 1, NULL)
                WHEN ci.indicador = 'tiempo_respuesta_pre_legalizacion' THEN
                IF(ejecucion <= meta_value, 1, NULL)
                
                ELSE SAFE_DIVIDE(ejecucion, meta_value) 
            END
            --) 
            p_ejecucion,

        FROM comisiones_internas ci
        LEFT JOIN `papyrus-delivery-data.habicredit.metas_comisiones_internas` mci ON mci.email = ci.beneficiado AND mci.metric_category = ci.indicador AND mci.effective_date = ci.mes_comision
        LEFT JOIN condicion_rad cr ON cr.beneficiado = ci.beneficiado AND cr.indicador = ci.indicador AND cr.mes_comision = ci.mes_comision
        LEFT JOIN condicion_inmo_rad cir ON cir.beneficiado = ci.beneficiado AND cir.indicador = ci.indicador AND cir.mes_comision = ci.mes_comision
        LEFT JOIN condicion_reprocesos crp ON crp.beneficiado = ci.beneficiado AND crp.indicador = ci.indicador AND crp.mes_comision = ci.mes_comision
        LEFT JOIN condicion_desembolsos_gs cd_gs ON cd_gs.beneficiado = ci.beneficiado AND cd_gs.indicador = ci.indicador AND cd_gs.mes_comision = ci.mes_comision
        LEFT JOIN condicion_desembolsos cd_a ON cd_a.beneficiado = ci.beneficiado AND cd_a.indicador = ci.indicador AND cd_a.mes_comision = ci.mes_comision
        LEFT JOIN condicion_reprocesos_kam crk ON crk.beneficiado = ci.beneficiado AND crk.indicador = ci.indicador AND crk.mes_comision = ci.mes_comision
        LEFT JOIN condicion_vinculaciones_itau cvi ON cvi.beneficiado = ci.beneficiado AND cvi.indicador = ci.indicador AND cvi.mes_comision = ci.mes_comision
        LEFT JOIN condicion_radicacion_cib cr_cib ON cr_cib.beneficiado = ci.beneficiado AND cr_cib.indicador = ci.indicador AND cr_cib.mes_comision = ci.mes_comision 
        --LEFT JOIN validacion_base_nomina vbn ON vbn.email = mci.email AND vbn.effective_date = mci.effective_date
    )

    , reglas_generales AS (

    SELECT 
        
        main.*,
        CASE
            WHEN posicion IN ('Gerente Comercial', 'Director non ibuyer', 'KAM')
                THEN 
                    CASE
                        WHEN indicador IN ('radicacion_monto','radicacion', 'reprocesos_monto', 'reprocesos_kam', 'aprobaciones_kam')  ----- Condiciones Techo Desembolsos ----
                            THEN
                                CASE
                                    WHEN beneficiado IN ('luisaquijano@habicredit.co', 'evelynguzman@habicredit.co')  AND mes_comision BETWEEN '2026-07-01' AND '2027-02-01'
                                        THEN base_commission * p_ejecucion
                                    WHEN beneficiado IN ('madeleingonzalez@habicredit.co')  AND mes_comision BETWEEN '2026-07-01' AND '2027-04-01'
                                        THEN base_commission * p_ejecucion

                                    WHEN p_ejecucion <= .6999 THEN 0
                                    WHEN p_ejecucion <= .7999 THEN base_commission *.3
                                    WHEN p_ejecucion > .7999 THEN base_commission * p_ejecucion
                                END
                        WHEN indicador = 'monto_desembolso' AND mes_comision >= DATE('2026-08-01')  ----- Esquema de tramos fijos por monto desembolsado, vigente desde 2026-08-01 (Esquemas/202608 Comisiones Habicredit COL). Meses anteriores caen al esquema generico de bandas de mas abajo, igual que se calculo/pago entonces. ----
                            THEN
                                CASE
                                    WHEN posicion = 'Gerente Comercial' THEN
                                        CASE
                                            WHEN ejecucion < 134000000000 THEN 0
                                            WHEN ejecucion < 156000000000 THEN 3000000
                                            ELSE 5000000
                                        END
                                    WHEN beneficiado IN ('luisaquijano@habicredit.co', 'madeleingonzalez@habicredit.co', 'evelynguzman@habicredit.co') THEN
                                        CASE
                                            WHEN ejecucion < 3000000000 THEN 0
                                            WHEN ejecucion < 4000000000 THEN 500000
                                            ELSE 1000000
                                        END
                                    WHEN beneficiado IN ('andreaalvarez@habicredit.co', 'madianchitiva@habi.co', 'juangalan@habicredit.co', 'carlosrios@habicredit.co', 'raulerazo@habicredit.co') THEN
                                        CASE
                                            WHEN ejecucion < 10000000000 THEN 0
                                            WHEN ejecucion < 12000000000 THEN 1500000
                                            ELSE 2500000
                                        END
                                    WHEN beneficiado IN ('katherinecuartas@habicredit.co', 'lorenagutierrez@habi.co') THEN
                                        CASE
                                            WHEN ejecucion < 18000000000 THEN 0
                                            WHEN ejecucion < 20000000000 THEN 3000000
                                            ELSE 5000000
                                        END
                                    WHEN beneficiado IN ('lorenarico@habi.co', 'paolacastro@habi.co') THEN
                                        CASE
                                            WHEN ejecucion < 21000000000 THEN 0
                                            WHEN ejecucion < 24000000000 THEN 3000000
                                            ELSE 5000000
                                        END
                                END
                        WHEN indicador IN ('dev_banco_broker')
                            THEN 
                                CASE
                                    WHEN p_ejecucion BETWEEN 0.15   AND 0.20   THEN 50000
                                    WHEN p_ejecucion BETWEEN 0.10   AND 0.1499 THEN 100000
                                    WHEN p_ejecucion BETWEEN 0.05   AND 0.0999 THEN 150000
                                    WHEN p_ejecucion BETWEEN 0      AND 0.0499 THEN 200000
                                END
                        WHEN indicador IN ('dev_docs_habi')
                            THEN 
                                CASE
                                    WHEN p_ejecucion BETWEEN 0.04   AND 0.05   THEN 50000
                                    WHEN p_ejecucion BETWEEN 0.03   AND 0.0399 THEN 100000
                                    WHEN p_ejecucion BETWEEN 0.02   AND 0.0299 THEN 150000
                                    WHEN p_ejecucion BETWEEN 0      AND 0.0199 THEN 200000
                                END
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 

            WHEN posicion IN ('Ejecutivo Comercial Habicredit (Comercial Convenios inmobiliarios Ciudades)', 'Director non ibuyer Graduaciones')
                THEN 
                    CASE
                        WHEN indicador IN ('radicaciones_inmo_ciudades_monto','radicaciones_inmo_ciudades')  ----- Condiciones Techo Desembolsos ----
                            THEN
                                CASE
                                    WHEN p_ejecucion <= .6999 THEN 0
                                    WHEN p_ejecucion <= .7999 THEN base_commission *.3
                                    WHEN p_ejecucion > .7999 THEN base_commission * p_ejecucion
                                END
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 
            WHEN posicion IN ('Analista Devoluciones')
                THEN 
                    CASE
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 

            WHEN posicion IN ('Director ibuyer')
                THEN 
                    CASE
                        WHEN indicador = 'monto_desembolso'  ----- Condiciones Techo Desembolsos ----
                            THEN
                                CASE
                                    WHEN ejecucion < 5400000000 THEN 0
                                    WHEN ejecucion >= 5400000000 AND ejecucion <= 8000000000 THEN 600000
                                    WHEN ejecucion > 8000000000 AND ejecucion <= 9600000000 THEN 1000000
                                    WHEN ejecucion >= 9600000000 THEN ejecucion * 0 --Se debe definir cuál es la base ya que aquí va directo
                                END
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 


            WHEN posicion IN ('Ejecutivo ibuyer')
                THEN 
                    CASE
                        WHEN indicador = 'monto_desembolso'  ----- Condiciones Techo Desembolsos ----
                            THEN
                                CASE
                                    WHEN ejecucion < 1400000000 THEN 0
                                    WHEN ejecucion >= 1400000000 AND ejecucion <= 2500000000 THEN 300000
                                    WHEN ejecucion > 2500000000 AND ejecucion <= 3000000000 THEN 500000
                                    WHEN ejecucion > 3000000000 AND ejecucion < 3333000000 THEN 800000
                                    WHEN ejecucion >= 3333000000 THEN 900000
                                END
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 


            WHEN posicion IN ('Ejecutivo COLEX')
                THEN 
                    CASE
                        WHEN indicador = 'monto_desembolso'  ----- Condiciones Techo Desembolsos ----
                            THEN
                                CASE
                                    WHEN p_ejecucion <= .6999 THEN 0
                                    WHEN p_ejecucion <= .7999 THEN base_commission *.3
                                    WHEN p_ejecucion > .7999 THEN base_commission * p_ejecucion
                                END
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 

            WHEN posicion IN ('Ejecutivo Cero Goles')
                THEN 
                    CASE
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion > .7999 THEN base_commission * p_ejecucion
                    END 

            WHEN posicion IN ('Gerente Ops Liquidez')
                THEN 
                    CASE
                    --     WHEN indicador = 'monto_desembolso'  ----- Condiciones Techo Desembolsos ----
                    --         THEN
                    --             CASE
                    --                 WHEN p_ejecucion <= .6999 THEN 0
                    --                 WHEN p_ejecucion <= .7999 THEN base_commission *.3
                    --                 WHEN p_ejecucion > .7999 THEN base_commission * p_ejecucion
                    --             END
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 


            WHEN posicion IN ('Supervisor Radicación')
                THEN 
                    CASE
                        WHEN indicador IN ('reproceso_creditos', 'reproceso_creditos_monto')
                            THEN
                                CASE
                                    WHEN p_ejecucion <= .6999 THEN 0
                                    WHEN p_ejecucion <= .7999 THEN base_commission *.3
                                    WHEN p_ejecucion > .7999 THEN base_commission * p_ejecucion
                                END
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 


            WHEN posicion IN ('Analista Radicación', 'Analista de filtros (Estados)')
                THEN 
                    CASE
                        WHEN indicador IN ('reproceso_creditos', 'reproceso_creditos_monto')
                            THEN
                                CASE
                                    WHEN p_ejecucion <= .6999 THEN 0
                                    WHEN p_ejecucion <= .7999 THEN base_commission *.3
                                    WHEN p_ejecucion > .7999 THEN base_commission * p_ejecucion
                                END
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.4999 THEN base_commission *p_ejecucion
                        WHEN p_ejecucion > 1.4999 THEN base_commission * 1.5
                    END 
            
            WHEN posicion IN ('Supervisor Legalización')
                THEN 
                    CASE
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.5
                        WHEN p_ejecucion > .7999 THEN base_commission * p_ejecucion
                    END

            WHEN posicion IN ('Analista Legalización')
                THEN 
                    CASE
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion > .7999 THEN base_commission * p_ejecucion
                    END 

            WHEN posicion IN ('Supervisor Pre Legalización')
                THEN 
                    CASE
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 

            WHEN posicion IN ('Analista Pre Legalización')
                THEN 
                    CASE
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 


        ----- Condiciones Legalización no Habicredit ----
            --- Castigo por no cumplir meta de desembolsos en operaciones de Habicredit ----
            --- Se multiplica cada indicador por el porcentaje de castigo. Se coloca acá el porcentaje de castigo que en 2025-04 es de 10% por lo tanto se coloca 0.9
            WHEN posicion IN('Supervisor Legalización no Habicredit')
                THEN 
                    CASE
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3 * multiplicador_castigo
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion * multiplicador_castigo
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3  * multiplicador_castigo
                    END  


            --- Castigo por no cumplir meta de desembolsos en operaciones de Habicredit ----
            --- Se multiplica cada indicador por el porcentaje de castigo. Se coloca acá el porcentaje de castigo que en 2025-04 es de 10% por lo tanto se coloca 0.9
            WHEN posicion IN('Analista Legalización no Habicredit')
                THEN 
                    CASE
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3 * multiplicador_castigo
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion * multiplicador_castigo
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3  * multiplicador_castigo
                    END  
        ----- Condiciones Legalización no Habicredit ----

            WHEN posicion IN ('Analista Legalización Operacaciones iBuyer (Abogada)')
                THEN 
                    CASE
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 

        WHEN posicion IN ('Analista de Legalización (Recaudo)')
                THEN 
                    CASE
                        WHEN p_ejecucion <= .6999 THEN 0
                        WHEN p_ejecucion <= .7999 THEN base_commission *.3
                        WHEN p_ejecucion <= 1.2999 THEN base_commission * p_ejecucion
                        WHEN p_ejecucion > 1.2999 THEN base_commission * 1.3
                    END 

            ELSE NULL
        END pago,
    FROM main
    LEFT JOIN castigo_operanciones_no_hc c ON c.mes_comision_castigo_no_hc = main.mes_comision AND c.beneficiado_castigo_no_hc = main.beneficiado AND c.posicion_castigo_no_hc = main.posicion
    WHERE meta_value IS NOT NULL
    ORDER BY 1,2,3,5
    )

    ----------------------- // // // Reglas adicionales que solo aplican por mes // // // ---------------

    SELECT 
        *
        /* EXCEPT(pago), 
        CASE
            WHEN indicador = 'inicio_bolsa' AND beneficiado = 'mariamahecha@habicredit.co' THEN base_commission * p_ejecucion
            WHEN indicador = 'inicio_bolsa' AND beneficiado = 'yessicabarrera@habicredit.co' THEN base_commission * p_ejecucion
        ELSE pago
        END AS pago */
    FROM reglas_generales

    --WHERE posicion IN (

    --'Gerente Ops Liquidez'
    --'Supervisor Legalización'
    --'Ejecutivo ibuyer'
    
    --)


    UNION ALL
    SELECT
        DATE('2026-07-01') AS mes_comision,
        'Analista Legalización' AS posicion,
        'alejandraorganista@habi.co' AS beneficiado,
        'cantidad_calidad_comentarios_analista (Se hizo un pago doble para la nomina de Julio)' AS indicador,
        1.06 AS ejecucion,
        1 AS meta_value,
        150000 AS base_commission,
        1.06 AS p_ejecucion,
        -159000 AS pago
    FROM (SELECT 1)
    WHERE date_sub(date_trunc(current_date('-5'), month), interval 1 month) = '2026-07-01'

    UNION ALL
    SELECT
        DATE('2026-07-01') AS mes_comision,
        'Asistente Pre-legalización' AS posicion,
        'yeisonlopez@habicredit.co' AS beneficiado,
        'Bono junio (Se hizo un pago doble para la nomina de Julio)' AS indicador,
        1526 AS ejecucion,
        1 AS meta_value,
        1000000 AS base_commission,
        1.0718 AS p_ejecucion,
        -1000000 AS pago
    FROM (SELECT 1)
    WHERE date_sub(date_trunc(current_date('-5'), month), interval 1 month) = '2026-07-01'

    UNION ALL
    SELECT
        DATE('2026-07-01') AS mes_comision,
        'Ejecutivo Comercial Habicredit (Comercial Convenios inmobiliarios Ciudades)' AS posicion,
        'davidsolano@habicredit.co' AS beneficiado,
        'radicaciones_inmo_ciudades_monto (Se hizo un pago doble para la nomina de Julio)' AS indicador,
        12332709461 AS ejecucion,
        14000000000 AS meta_value,
        500000 AS base_commission,
        0.8809078186 AS p_ejecucion,
        -440500 AS pago
    FROM (SELECT 1)
    WHERE date_sub(date_trunc(current_date('-5'), month), interval 1 month) = '2026-07-01'

    UNION ALL
    SELECT
        DATE('2026-07-01') AS mes_comision,
        'Supervisor- Pre legalización' AS posicion,
        'yeisonlopez@habicredit.co' AS beneficiado,
        'negocios_convertidos_pre_legalziacion' AS indicador,
        1176 AS ejecucion,
        1 AS meta_value,
        1000000 AS base_commission,
        1.248407643 AS p_ejecucion,
        1248407 AS pago

        	
    FROM (SELECT 1)
    WHERE date_sub(date_trunc(current_date('-5'), month), interval 1 month) = '2026-07-01'
    
    UNION ALL
    SELECT
        DATE('2026-07-01') AS mes_comision,
        'Supervisor- Pre legalización' AS posicion,
        'yeisonlopez@habicredit.co' AS beneficiado,
        'desembolsos' AS indicador,
        124 AS ejecucion,
        1 AS meta_value,
        500000 AS base_commission,
        0.9962733188 AS p_ejecucion,
        498133 AS pago
        	
    FROM (SELECT 1)
    WHERE date_sub(date_trunc(current_date('-5'), month), interval 1 month) = '2026-07-01'





            

--);
    
