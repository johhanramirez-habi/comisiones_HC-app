CREATE OR REPLACE PROCEDURE `papyrus-delivery-data.habicredit.comisiones_internas_hc_fn`(mes_comision_input DATE)
BEGIN
  -- Puedes crear una tabla temporal con el resultado
  INSERT INTO `papyrus-delivery-data.habicredit.comisiones_internas_hc_fn_table`
  
  WITH main AS (
    select
      mes_comision_input AS mes_comision,
      report_id,
      correo_director_comercial,
      kam,
      correo_broker,
      analista_radicacion,
      --analista_pre_legalizacion,
      analista_legalizacion,
      date(fecha_radicacion_colex) as fecha_radicacion_colex,
      date(fecha_radicacion_u) as fecha_radicacion,  --Radicaciones únicas
      date(fecha_aprobacion) as fecha_aprobacion,
      date(fecha_desembolso) as fecha_desembolso,
      
      if(date_trunc(fecha_radicacion_u, month) = mes_comision_input, 1.0, null) as radicacion, --Radicaciones únicas
      if(date_trunc(fecha_radicacion, month) = mes_comision_input, 1.0, null) as radicacion_analista,

      if(date_trunc(fecha_radicacion_u, month) = mes_comision_input, monto_solicitado_u, null) as monto_solicitado,  --Radicaciones únicas
      if(date_trunc(fecha_radicacion, month) = mes_comision_input, monto_solicitado, null) as monto_solicitado_analista,
      
      if(date_trunc(fecha_aprobacion, month) = mes_comision_input, 1.0, null) as aprobacion,
      

      --- // COLEX // ---
      --- // COLEX // ---
      if(date_trunc(fecha_radicacion_colex, month) = mes_comision_input, 1.0, null) as radicacion_colex,
      DATE_DIFF(DATE(fecha_aprobacion), DATE(fecha_radicacion_colex),MONTH) AS mes_aprob_vs_rad_colex,
      if(
        date_trunc(fecha_radicacion_colex, month) = date_sub(mes_comision_input, interval 1 month) and mes_aprob_vs_rad <= 1,
        1.0, null) 
      as aprobacion_dual_colex,
      if(date_trunc(fecha_radicacion_colex, month) = date_sub(mes_comision_input, interval 1 month), 1.0, 0) as aprobacion_dual_meta_colex, 
      --- // COLEX // ---
      --- // COLEX // ---

      if(
        date_trunc(fecha_radicacion, month) = date_sub(mes_comision_input, interval 1 month) and mes_aprob_vs_rad <= 1,
        1.0, null) 
      as aprobacion_dual,
      if(date_trunc(fecha_radicacion, month) = date_sub(mes_comision_input, interval 1 month), 1.0, 0) as aprobacion_dual_meta, 
      if(date_trunc(fecha_desembolso, month) = mes_comision_input, 1.0, null) as desembolsos, 
      if(date_trunc(fecha_desembolso, month) = mes_comision_input, monto_desembolso, null) as monto_desembolso,

    from `papyrus-delivery-data.habicredit.main_board`
  )

  , listas_supervisores_analistas AS (
      SELECT
        ['janelynpaniagua@habicredit.co','leydemontoya@habicredit.co','maryipoveda@habicredit.co','fabianrodriguez@habicredit.co','laura.amaya@habicredit.co','ivetthecasanas@habicredit.co','edwinlizarralde@habicredit.co','linabedoya@habi.co','lauracuevas@habicredit.co','jeisonquintero@habicredit.co', 'oscaramezquita@habi.co', 'jhonathanflorez@habicredit.co', 'danielibague@habicredit.co', 'gloriaarrieta@habicredit.co'] AS analistas_sup_oscar,

      CASE
        WHEN mes_comision_input = '2026-05-01' THEN --En este mes no se cuenta los desembolsos cargados a Adriana como analista.
        ['shirlydiaz@habicredit.co','shirleydiaz@habicredit.co','yeissonortiz@habi.co','jancyruiz@habi.co','camilabonilla@habicredit.co','alejandraorganista@habi.co','johnortiz@habicredit.co','tatianatorres@habicredit.co','mariaescobar@habicredit.co','geidygonzalez@habicredit.co','eblinsmontoya@habi.co','miryamhenao@habicredit.co'] 
        WHEN mes_comision_input < '2026-07-01'
          THEN ['adrianaflorido@habi.co','shirlydiaz@habicredit.co','shirleydiaz@habicredit.co','yeissonortiz@habi.co','jancyruiz@habi.co','camilabonilla@habicredit.co','alejandraorganista@habi.co','johnortiz@habicredit.co','tatianatorres@habicredit.co','mariaescobar@habicredit.co','geidygonzalez@habicredit.co','eblinsmontoya@habi.co','miryamhenao@habicredit.co'] 
        WHEN mes_comision_input = '2026-07-01'
          THEN ['adrianaflorido@habi.co','yeissonortiz@habi.co', 'alejandraorganista@habi.co','tatianatorres@habicredit.co','geidygonzalez@habicredit.co', 'claudiapardo@habicredit.co', 'johannacardenas@habicredit.co', 'ivetthecasanas@habicredit.co']
        ----- Reasignacion de analistas de legalizacion a supervisores, vigente 2026-08-01 a 2026-08-31 -----
        -- Fuente: tabla de asignacion que entrego legalizacion para agosto 2026.
        WHEN mes_comision_input = '2026-08-01'
          THEN [
            'johannacardenas@habicredit.co',   -- Johanna Andrea Cardenas Rodriguez
            'yeissonortiz@habi.co',            -- Yeisson Ortiz Montano
            'alejandraorganista@habi.co',      -- Alejandra Organista (+stock)
            'ivetthecasanas@habicredit.co',    -- Ivetthe Sulay Casañas Arias
            'nicolfonseca@habi.co',            -- Nicole Fonseca (antes Claudia)
            'yessicabarrera@habicredit.co',    -- Yessica Tatiana Barrera Lizarazo
            'leydemontoya@habicredit.co'       -- Leyde Yovana Montoya Arias
          ]
        ----- Reasignacion vigente desde 2026-09-01 -----
        -- Fuente: imagen de asignacion de analistas para septiembre 2026 que entrego Johhan.
        -- Cambios vs agosto: sale nicolfonseca y yessicabarrera (pasan a Tom).
        WHEN mes_comision_input >= '2026-09-01'
          THEN [
            'yeissonortiz@habi.co',            -- Yeisson Ortiz Montano
            'alejandraorganista@habi.co',      -- Alejandra Organista
            'leydemontoya@habicredit.co',      -- Leyde Yovana Montoya Arias
            'ivetthecasanas@habicredit.co',    -- Ivetthe Sulay Casañas Arias
            'johannacardenas@habicredit.co'    -- Johanna Andrea Cardenas Rodriguez
          ]
        END AS analistas_sup_adriana,

        CASE
        WHEN mes_comision_input = '2026-07-01'
          THEN ['lauracuevas@habicredit.co', 'linabedoya@habi.co', 'danielibague@habicredit.co']
        ----- Reasignacion vigente 2026-08-01 a 2026-08-31 -----
        -- En la tabla de legalizacion este grupo figura bajo el supervisor "Fernando". Se mapea a
        -- Yeison Lopez: en metas_comisiones_internas solo hay tres Supervisores de Legalizacion
        -- (Adriana Florido, Edilberto Botia, Yeison Lopez), la tabla trae tres grupos y nombra a los
        -- otros dos, asi que este es el de Yeison. CONFIRMAR con legalizacion si "Fernando" es el.
        WHEN mes_comision_input = '2026-08-01'
          THEN [
            'geidygonzalez@habicredit.co',     -- Geidy Yasmin Gonzalez Garzon
            'jhonathanflorez@habicredit.co',   -- Jhonathan David Florez Castillo
            'danielibague@habicredit.co',      -- Daniel Andres Ibague Gomez
            'lauracuevas@habicredit.co',       -- Laura Nayibe Cuevas Celeita
            'linabedoya@habi.co'               -- Lina Gisela Bedoya Ardila
          ]
        ----- Reasignacion vigente desde 2026-09-01 -----
        -- Fuente: imagen de asignacion de analistas para septiembre 2026 que entrego Johhan.
        -- Cambios vs agosto: sale jhonathanflorez (no aparece en ninguno de los 3 grupos de la
        -- imagen de septiembre; CONFIRMAR a donde paso), entra maryipoveda (viene de Tom).
        WHEN mes_comision_input >= '2026-09-01'
          THEN [
            'maryipoveda@habicredit.co',       -- Maryi Jaidith Poveda Cifuentes
            'danielibague@habicredit.co',      -- Daniel Andres Ibague Gomez
            'lauracuevas@habicredit.co',       -- Laura Nayibe Cuevas Celeita
            'geidygonzalez@habicredit.co',     -- Geidy Yasmin Gonzalez Garzon
            'linabedoya@habi.co'               -- Lina Gisela Bedoya Ardila
          ]
        END AS analistas_sup_yeison,

      CASE
        WHEN mes_comision_input < '2026-07-01'
          THEN ['edilbertobotia@habi.co', 'claudiapardo@habicredit.co', 'johannacardenas@habicredit.co', 'yessicabarrera@habicredit.co', 'jefersonrincon@habicredit.co']
        WHEN mes_comision_input = '2026-07-01'
          THEN ['edilbertobotia@habi.co', 'eblinsmontoya@habi.co', 'nohoravarela@habicredit.co', 'jhonathanflorez@habicredit.co', 'maryipoveda@habicredit.co', 'leydemontoya@habicredit.co','shirleydiaz@habicredit.co','shirlydiaz@habicredit.co','yessicabarrera@habicredit.co']
        ----- Reasignacion vigente 2026-08-01 a 2026-08-31 (Tom = Edilberto Botia) -----
        WHEN mes_comision_input = '2026-08-01'
          THEN [
            'jeydirodriguez@habicredit.co',    -- Jeydi Yoana Rodriguez Carranza (en la tabla figura como "Garantias - leg"; legalizacion confirma que es de Edilberto)
            'nohoravarela@habicredit.co',      -- Nohora Amparo Varela Sarmiento
            'shirleydiaz@habicredit.co',       -- Shirley Stephany Diaz Cerpa
            'shirlydiaz@habicredit.co',        -- variante de escritura del correo de Shirley, se conserva como en meses anteriores
            'maryipoveda@habicredit.co',       -- Maryi Jaidith Poveda Cifuentes (+Monica)
            'eblinsmontoya@habi.co'            -- Eblins Montoya Franco
          ]
        ----- Reasignacion vigente desde 2026-09-01 (Tom = Edilberto Botia) -----
        -- Fuente: imagen de asignacion de analistas para septiembre 2026 que entrego Johhan.
        -- Cambios vs agosto: sale jeydirodriguez (no aparece en ninguno de los 3 grupos de la
        -- imagen de septiembre; CONFIRMAR a donde paso) y maryipoveda (pasa a Yeison), entran
        -- yessicabarrera y nicolfonseca (vienen de Adriana).
        WHEN mes_comision_input >= '2026-09-01'
          THEN [
            'nohoravarela@habicredit.co',      -- Nohora Amparo Varela Sarmiento
            'shirleydiaz@habicredit.co',       -- Shirley Stephany Diaz Cerpa
            'shirlydiaz@habicredit.co',        -- variante de escritura del correo de Shirley, se conserva como en meses anteriores
            'eblinsmontoya@habi.co',           -- Eblins Montoya Franco
            'yessicabarrera@habicredit.co',    -- Yessica Tatiana Barrera Lizarazo
            'nicolfonseca@habi.co'             -- Nicol Steffany Fonseca Camargo
          ]
          END AS analistas_sup_tom,
    )

  --// --------------- //--
  --// --------------- //--
  --// El siguiente Array debe cambiar mes a mes e incluir la semanas que se van a contemplar. 
  --// Para el mes de marzo 2026 no se usa ya que no hay datos de todo el mes. A partir de abril se debe validar que el query que usa este array esté bien
  , semanas_rotacion AS (SELECT
    CASE
      -- ---- 2026 ----
      WHEN mes_comision_input = '2026-03-01' THEN
        [DATE('2026-03-02'), DATE('2026-03-09'), DATE('2026-03-16'), DATE('2026-03-23')]
        
      WHEN mes_comision_input = '2026-04-01' THEN
        [DATE('2026-04-06'), DATE('2026-04-13'), DATE('2026-04-20'), DATE('2026-04-27')]

      WHEN mes_comision_input = '2026-05-01' THEN
        [DATE('2026-05-04'), DATE('2026-05-11'), DATE('2026-05-18'), DATE('2026-05-25')]

      WHEN mes_comision_input = '2026-06-01' THEN
        [DATE('2026-06-01'), DATE('2026-06-08'), DATE('2026-06-15'), DATE('2026-06-22')]

      WHEN mes_comision_input = '2026-07-01' THEN
        [DATE('2026-07-06'), DATE('2026-07-13'), DATE('2026-07-20'), DATE('2026-07-27')] 

      WHEN mes_comision_input = '2026-08-01' THEN
        [
        --DATE('2026-08-03'),  -- Se elimina esta semana por falta de confianzas en los datos
        DATE('2026-08-10'), DATE('2026-08-17'), DATE('2026-08-24')]

      WHEN mes_comision_input = '2026-09-01' THEN
        [DATE('2026-09-07'), DATE('2026-09-14'), DATE('2026-09-21'), DATE('2026-09-28')]

      WHEN mes_comision_input = '2026-10-01' THEN
        [DATE('2026-10-05'), DATE('2026-10-12'), DATE('2026-10-19'), DATE('2026-10-26')]

      WHEN mes_comision_input = '2026-11-01' THEN
        [DATE('2026-11-02'), DATE('2026-11-09'), DATE('2026-11-16'), DATE('2026-11-23')]

      WHEN mes_comision_input = '2026-12-01' THEN
        [DATE('2026-12-07'), DATE('2026-12-14'), DATE('2026-12-21'), DATE('2026-12-28')]

      -- ---- 2027 ----
      WHEN mes_comision_input = '2027-01-01' THEN
        [DATE('2027-01-04'), DATE('2027-01-11'), DATE('2027-01-18'), DATE('2027-01-25')]

      WHEN mes_comision_input = '2027-02-01' THEN
        [DATE('2027-02-01'), DATE('2027-02-08'), DATE('2027-02-15'), DATE('2027-02-22')]

      WHEN mes_comision_input = '2027-03-01' THEN
        [DATE('2027-03-01'), DATE('2027-03-08'), DATE('2027-03-15'), DATE('2027-03-22')]
        
      ELSE []
    END AS semanas_rot
  )
  --// --------------- //--
  --// --------------- //--

  , metas_sop AS (

    SELECT
      meta_mes_radicacion, 
      meta_mes_desembolsos,
    FROM `papyrus-delivery-data.habicredit.metas_sop`
    WHERE fecha = mes_comision_input

  )

  , meta_directores AS (

    SELECT 
      fecha, 
      director, 
      meta_radicacion, 
      meta_desembolso
    FROM `papyrus-delivery-data.habicredit.metas_directores_comerciales`
    WHERE fecha = mes_comision_input

  )

  , meta_analistas_rad AS (

    SELECT 
      fecha, 
      analista, 
      meta_radicacion, 
    FROM `papyrus-delivery-data.habicredit.meta_analistas_hc`
    WHERE fecha = mes_comision_input AND equipo = 'Radicación'
  )


  , radicaciones_coordinador_ibuyer AS (

    SELECT
      mes_comision_input AS mes_comision,
      SUM(radicacion_analista) AS radicacion_coord,
      SUM(monto_solicitado_analista) AS radicacion_monto_coord,

    FROM main
    WHERE correo_director_comercial IN ('germanvargas@habi.co', 'coordinadoribuyerhabi@gmail.com', 'coordinadoribuyerliquidez@habicredit.co')
    GROUP BY 1
  )

  , AR_CI AS (

    SELECT 
      DATE(DATE_TRUNC(c_fecha_carta_intencion, month)) AS mes, 
      SUM(cierres_habicredit_final) AS cierres,
      SUM(aplicable_final) AS aplicables, 
      SAFE_DIVIDE(SUM(cierres_habicredit_final), SUM(aplicable_final)) AS attachment_rate 
      FROM `papyrus-delivery-data.habicredit.ar_ci_co`
    GROUP BY 1

  )

  , AR_PCV AS (

    SELECT 
      DATE(DATE_TRUNC(c_fecha_promesa, month)) AS mes, 
      SUM(cierres_habicredit_final) AS cierres,
      SUM(aplicable_final) AS aplicables, 
      SAFE_DIVIDE(SUM(cierres_habicredit_final), SUM(aplicable_final)) AS attachment_rate 
      FROM `papyrus-delivery-data.habicredit.ar_pcv_co`
    GROUP BY 1

  )

  , AR_E AS (

    SELECT 
      DATE(DATE_TRUNC(c_fecha_escritura, month)) AS mes, 
      SUM(cierres_habicredit_final) AS cierres,
      SUM(aplicable_final) AS aplicables, 
      SAFE_DIVIDE(SUM(cierres_habicredit_final), SUM(aplicable_final)) AS attachment_rate 
      FROM `papyrus-delivery-data.habicredit.ar_escritura_co`
    GROUP BY 1
  )

  /*, conversion_pre_legalizacion AS (

    SELECT
      bt.*, motivo_de_regreso_a_bolsa, identificaci_n_del_cliente
    FROM `liquidez-main-prod.data_summary.bt_pre_legalization` bt
    LEFT JOIN `papyrus-delivery-data.habicredit.pipe_bolsa` pb ON CAST(bt.card_id AS STRING) = pb.card_id
    WHERE (phase_name IN ('CRÉDITOS DEFINIDOS') AND DATE(DATE_TRUNC(DATE_SUB(bt.updated_at, INTERVAL 5 HOUR), MONTH)) =  mes_comision_input)
    AND (motivo_de_regreso_a_bolsa IS NULL OR motivo_de_regreso_a_bolsa NOT IN (
      'Gravámenes sin cancelar',
      'Sin Vinculación Itaú con avalúo Favorable',
      'Avance de obra',
      'Fecha de escrituración >30 días (Informada desde de prelegalización)',
      'Error en data desde prelegalización'
    ))
  )

  */

  , conversion_pre_legalizacion_director AS (

    with btp_dedup as (
      select 
        btp.report_id,
        btp.fecha_fin_pre_legalizacion,
        btp.ciclo
      from `papyrus-delivery-data.habicredit.bt_pre_legalizacion_bi_new` btp
      qualify row_number() over(partition by btp.report_id, btp.ciclo) = 1
    )

    select 
      date(date_trunc(b.fecha_fin_pre_legalizacion, month)) mes,
      m.correo_director_comercial,
      cast(count(b.report_id) as float64) as conversion

    from btp_dedup b
    left join `papyrus-delivery-data.habicredit.main_board` m on b.report_id = cast(m.report_id as int64)
    -- Antes estaba quemado en '2026-07-01', lo que dejaba a todos los directores sin
    -- conversion_pre_leg_director desde agosto 2026. Se parametriza por mes_comision_input:
    -- para julio devuelve exactamente lo mismo que la fecha quemada, y ya sirve para cualquier mes.
    where date(date_trunc(b.fecha_fin_pre_legalizacion, month)) = mes_comision_input
    --and ciclo = 0 --Esto debe ser temporal mientras se baja la bolsa de pre-legalizados
    group by 1,2
  )

  ----- Mismo conteo que conversion_pre_legalizacion_director pero total (sin agrupar por director). -----
  ----- Usado para el indicador convertidos_pre_legalizacion de jefersonrincon@habicredit.co (Ejecutivo -----
  ----- Comercial Cero Goles) y maryrodriguez@habicredit.co (Supervisor Pre Legalizacion, desde 2026-08-01). -----
  ----- Sin filtro de mes: se resuelve al hacer join por mes_comision_input en cada CTE que lo usa, para -----
  ----- que sirva para cualquier mes sin necesidad de tocar este query cada vez. -----
  , conversion_pre_legalizacion_total AS (

    with btp_dedup as (
      select
        btp.report_id,
        btp.fecha_fin_pre_legalizacion,
        btp.ciclo
      from `papyrus-delivery-data.habicredit.bt_pre_legalizacion_bi_new` btp
      qualify row_number() over(partition by btp.report_id, btp.ciclo) = 1
    )

    select
      mes,
      ----- Agosto 2026: el conteo calculado (970) esta mal segun el usuario; el valor correcto -----
      ----- es 1001 (confirmado 2026-09-09). Afecta por igual a jefersonrincon@habicredit.co y -----
      ----- maryrodriguez@habicredit.co, que comparten este total. -----
      CASE
        WHEN mes = '2026-08-01' THEN 1001.0
        ELSE conversion
      END as conversion

    from (
      select
        date(date_trunc(fecha_fin_pre_legalizacion, month)) as mes,
        cast(count(report_id) as float64) as conversion

      from btp_dedup
      group by 1
    )
  )


  , aprobacion_dual_ejecutivo_ibuyer AS (
    WITH main AS (
      SELECT
        correo_broker,
        if(
        date_trunc(fecha_radicacion, month) = date_sub(mes_comision_input, interval 1 month) and mes_aprob_vs_rad <= 1,
        1.0, null) 
      as aprobacion_dual,
      if(date_trunc(fecha_radicacion, month) = date_sub(mes_comision_input, interval 1 month), 1.0, 0) as aprobacion_dual_meta,

      FROM `papyrus-delivery-data.habicredit.main_board`
      WHERE correo_broker IN ('yulianagarcia@habi.co', 'ladyparra@habicredit.co', 'glorialeon@habi.co', 'nidiasanchez@habicredit.co')

    )
    
    SELECT 
      mes_comision_input AS fecha,
      correo_broker AS ejecutivo,
      SAFE_DIVIDE(SUM(aprobacion_dual), SUM(aprobacion_dual_meta)) AS aprobacion_dual,
    FROM main
    GROUP BY 1,2
  )

  , dias_aprobacion_supervisor AS (
    SELECT 
      DATE_TRUNC(fecha_aprobacion, MONTH) AS fecha_aprobacion, 
      AVG(dias_radicacion_aprobacion) AS avg_dias_radicacion_aprobacion 
    FROM `papyrus-delivery-data.habicredit.main_board_radicacion`
    WHERE dias_radicacion_aprobacion >= 0 AND tu_credito_es = 'Tradicional'
    GROUP BY 1
  )

  , dias_sancion_supervisor AS (
    SELECT 
      DATE_TRUNC(fecha_sancion, MONTH) AS fecha_sancion, 
      AVG(dias_radicacion_sancion) AS avg_dias_radicacion_sancion 
    FROM `papyrus-delivery-data.habicredit.main_board_radicacion`
    WHERE dias_radicacion_sancion >= 0 AND tu_credito_es = 'Tradicional'
    GROUP BY 1
  )

  , dias_aprobacion_analista AS (
    SELECT 
      DATE_TRUNC(fecha_aprobacion, MONTH) fecha_aprobacion,
      analista_radicacion,
      AVG(dias_radicacion_aprobacion) avg_dias_radicacion_aprobacion 
    FROM `papyrus-delivery-data.habicredit.main_board_radicacion`
    WHERE dias_radicacion_aprobacion >= 0 AND tu_credito_es = 'Tradicional'
    GROUP BY 1,2
  )

  , dias_sancion_analista AS (
    SELECT 
      DATE_TRUNC(fecha_sancion, MONTH) fecha_sancion,
      analista_radicacion,
      AVG(dias_radicacion_sancion) avg_dias_radicacion_sancion 
    FROM `papyrus-delivery-data.habicredit.main_board_radicacion`
    WHERE dias_radicacion_sancion >= 0 AND tu_credito_es = 'Tradicional'
    GROUP BY 1,2
  )

  , dias_aprobacion_broker AS (
    SELECT 
      DATE_TRUNC(fecha_aprobacion, MONTH) fecha_aprobacion,
      correo_broker,
      AVG(dias_radicacion_aprobacion) avg_dias_radicacion_aprobacion 
    FROM `papyrus-delivery-data.habicredit.main_board_radicacion`
    WHERE dias_radicacion_aprobacion >= 0 AND tu_credito_es = 'Tradicional'
    GROUP BY 1,2
  )

  , reproceso_creditos AS (
    WITH base AS (
      SELECT * FROM (
        SELECT
          r.*,
          -- Salvamento dentro del mismo banco: el negocio pasa por la fase Mesa de salvamento.
          -- Es la unica forma de salvamento que midio el indicador hasta 2026-07.
          r.inicio_subproceso_mesa_salvamento IS NOT NULL AS es_mesa_salvamento,

          ----- Traslado de banco, vigente desde 2026-08-01 y SOLO para Leidy Moscoso y Yudy Zamudio -----
          -- El negocio viene negado en otro banco y la analista lo mueve a uno nuevo, donde se aprueba.
          -- Ese traslado no pasa por la fase Mesa de salvamento del board, asi que el filtro viejo
          -- (inicio_subproceso_mesa_salvamento IS NOT NULL) lo dejaba por fuera, pese a que el
          -- diccionario de indicadores si lo cuenta ("o aprobados por otros bancos").
          -- Se detecta por proxy: el mismo cliente tiene radicacion en otro banco previa a la aprobacion.
          -- Acotado a estas dos personas por decision de negocio (excepcion acordada con el gerente de
          -- radiacion); el resto de analistas se sigue midiendo solo con mesa de salvamento.
          -- Junio y julio 2026 ya estan quemados a mano con este mismo criterio en
          -- comisiones_internas_hc_final.sql, por eso el ajuste automatico arranca en agosto.
          (
            mes_comision_input >= '2026-08-01'
            AND LOWER(TRIM(r.analista_radicacion)) IN ('leidymoscoso@habi.co', 'yudyzamudio@habicredit.co')
            AND r.inicio_subproceso_mesa_salvamento IS NULL
            AND EXISTS (
              SELECT 1
              FROM `papyrus-delivery-data.habicredit.main_board_radicacion` t
              WHERE t.identificacion_cliente = r.identificacion_cliente
                AND t.report_id != r.report_id
                AND t.banco != r.banco
                AND t.fecha_radicacion <= r.fecha_aprobacion
            )
          ) AS es_traslado_banco,
        FROM `papyrus-delivery-data.habicredit.main_board_radicacion` r
      )
      WHERE es_mesa_salvamento OR es_traslado_banco
    )

    , main AS (
      SELECT
        * EXCEPT(analista_negados),
        CASE
          -- En los traslados de banco no hay analista_negados (el negocio se nego en otra tarjeta),
          -- asi que el credito va a la analista que movio y radico el negocio.
          WHEN es_traslado_banco THEN analista_radicacion
          WHEN analista_negados IS NULL THEN 'Analista de radicación'
          WHEN banco IN ('BANCODEBOGOTA', 'BANCOLOMBIA') THEN 'Analista de radicación'
          ELSE analista_negados
        END AS analista_negados,
      FROM base
    )

    , salvados AS (
      SELECT
        LOWER(TRIM(analista_negados)) AS analista_negados,
        DATE_TRUNC(fecha_aprobacion, MONTH) AS mes_salvado,
        SUM(monto_aprobado) AS monto_aprobado,
        CAST(COUNT(report_id) AS FLOAT64) AS salvados,
        -- Subtotales solo de mesa de salvamento, para que el total del supervisor no herede
        -- la excepcion de las dos analistas (ver reproceso_creditos_total).
        SUM(IF(es_mesa_salvamento, monto_aprobado, 0)) AS monto_aprobado_mesa,
        CAST(COUNTIF(es_mesa_salvamento) AS FLOAT64) AS salvados_mesa,
      FROM main
      -- WHERE responsable_reproceso = 'Analista de radicación'
    GROUP BY 1,2
    )

    SELECT * FROM salvados
  )

  , reproceso_creditos_total AS (

    -- El Supervisor de Radicacion se sigue midiendo SOLO con salvamento en mesa: el ajuste de
    -- traslado de banco es una excepcion para dos analistas, no un cambio del indicador del equipo.
    SELECT
      mes_salvado,
      SUM(monto_aprobado_mesa) AS monto_aprobado,
      SUM(salvados_mesa) AS salvados
    FROM reproceso_creditos
    GROUP BY 1

  )

  , calidad_kam AS (

    WITH calidad_raw AS (
      SELECT 
        m.KAM,
        DATE_TRUNC(r.created_at, MONTH) AS mes_calidad,
        IF(DATE_TRUNC(entrada_en_proceso_de_radicacion_banco, MONTH) = DATE_TRUNC(r.created_at, MONTH) AND entrada_devuelto_por_documentos_habi IS NULL, 1, NULL) AS calidad_numerador,
        IF(r.created_at IS NOT NULL, 1, NULL) AS calidad_denominador,
      
      FROM `papyrus-delivery-data.habicredit.main_board` m
      LEFT JOIN `papyrus-delivery-data.habicredit.pipe_radicacion_co` r ON r.report_id = CAST(m.report_id AS STRING)
    )

    SELECT 
      KAM,
      mes_calidad, 
      SAFE_DIVIDE(SUM(calidad_numerador), SUM(calidad_denominador)) AS calidad,
      SUM(calidad_numerador), SUM(calidad_denominador),
    FROM calidad_raw
    GROUP BY 1,2
  )


  , calidad_pre_legalizacion_kam AS (

    with main as (
      select 
        date(fecha_inicio_pre_legalizacion) as fecha_inicio_pre_legalizacion,
        date(fecha_fin_pre_legalizacion) as fecha_fin_pre_legalizacion,
        kam
        
      from `papyrus-delivery-data.habicredit.bt_pre_legalizacion_bi_new` btp
      left join `papyrus-delivery-data.habicredit.main_board` m on btp.report_id = cast(m.report_id as int64)
      where ciclo != 0 and devuelto_inicio_legalizacion is true
      qualify row_number() over(partition by btp.report_id, ciclo) = 1
    )

    select 

      date_trunc(fecha_inicio_pre_legalizacion, month) as fecha_inicio_devolucion,
      kam,
      count(fecha_inicio_pre_legalizacion) devoluciones,
      count(fecha_fin_pre_legalizacion) as devoluciones_resueltas,
      sum(if(date_trunc(fecha_inicio_pre_legalizacion, month) = date_trunc(fecha_fin_pre_legalizacion, month) OR date_trunc(fecha_inicio_pre_legalizacion, month) = date_sub(date_trunc(fecha_fin_pre_legalizacion, month), interval 1 month), 1, 0))
      as devoluciones_resueltas_en_tiempo,

    from main
    group by 1,2
  )


  , score_calidad_comentarios_analista AS (

    with main as ( 
      select 
        
        fecha,
        name,
        email,
        score,
        comentarios,
        if(score > 8, 1, 0) bool_score,
        if(comentarios > 80, 1, 0) bool_comentarios,

      from `papyrus-delivery-data.habicredit.score_comentarios_calidad_legalizacion`
      where email is not null and date_trunc(fecha, month) = mes_comision_input
    )

    SELECT 
      DATE_TRUNC(fecha, month) fecha,
      email,
      
      SUM(bool_score) AS bool_score, -- Opción A
      SUM(bool_comentarios) AS bool_comentarios, -- Opción A
      SAFE_DIVIDE(
        SUM(bool_score) + SUM(bool_comentarios),
        COUNT(bool_score) + COUNT(bool_comentarios)
      ) p_ejecucion_A, -- Opción A

      SAFE_DIVIDE(SUM(score), COUNT(score)) AS avg_score, -- Opción B
      SAFE_DIVIDE(SUM(comentarios), COUNT(comentarios)) AS avg_comentarios, -- Opción B

      SAFE_DIVIDE(
        SAFE_DIVIDE(SAFE_DIVIDE(SUM(score), COUNT(score)), 8) --8 Es la meta en mayo
          +
        SAFE_DIVIDE(SAFE_DIVIDE(SUM(comentarios), COUNT(comentarios)), 80) --80 Es la meta en mayo
      , 2) p_ejecucion_B

    FROM main
    GROUP BY 1,2

  )

  , score_calidad_comentarios_supervisor_adriana AS (

    SELECT 
      fecha,
      AVG(p_ejecucion_B) AS p_ejecucion_comentarios
    FROM score_calidad_comentarios_analista
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE email IN UNNEST(analistas_sup_adriana)
    GROUP BY 1
  )

  , score_calidad_comentarios_supervisor_oscar AS (

    SELECT 
      fecha,
      AVG(p_ejecucion_B) AS p_ejecucion_comentarios
    FROM score_calidad_comentarios_analista
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE email IN UNNEST(analistas_sup_oscar)
    GROUP BY 1
  )

  , score_calidad_comentarios_supervisor_tom AS (

    SELECT 
      fecha,
      AVG(p_ejecucion_B) AS p_ejecucion_comentarios
    FROM score_calidad_comentarios_analista
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE email IN UNNEST(analistas_sup_tom)
    GROUP BY 1
  )

  , score_calidad_comentarios_supervisor_yeison AS (
    SELECT 
      fecha,
      AVG(p_ejecucion_B) AS p_ejecucion_comentarios
    FROM score_calidad_comentarios_analista
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE email IN UNNEST(analistas_sup_yeison)
    GROUP BY 1
  )

  , pre_legalizacion_radicador_ibuyer AS (
    
    SELECT
      
      DATE_TRUNC(btp.fecha_fin_pre_legalizacion, MONTH) AS mes_comision,
      btp.report_id,

    FROM `papyrus-delivery-data.habicredit.bt_pre_legalizacion_bi_new` btp
    LEFT JOIN `papyrus-delivery-data.habicredit.main_board` mb ON btp.report_id = CAST(mb.report_id AS INT64)
    WHERE DATE_TRUNC(DATE(fecha_fin_pre_legalizacion), MONTH) = mes_comision_input 
    AND correo_director_comercial IN ('germanvargas@habi.co', 'coordinadoribuyerhabi@gmail.com', 'coordinadoribuyerliquidez@habicredit.co')
    QUALIFY ROW_NUMBER() OVER(PARTITION BY btp.report_id, btp.ciclo ORDER BY btp.fecha_fin_pre_legalizacion DESC) = 1
  )


  -------- Cumplimiento Rotaciones Legalización -------- 


  , cumplimiento_rotacion_gerente AS (
    SELECT
      DATE_TRUNC(fecha, MONTH) AS mes,
      SAFE_DIVIDE(SUM(salidas_semana), SUM(objetivo_semanal)) AS cumplimiento_gestion_rotacion --cumplimiento_ponderado_mensual,
    FROM `papyrus-delivery-data.habicredit.cumplimiento_productividad_rotacion_analistas`
    WHERE fase != 'Fase 5'
    GROUP BY 1
  )

  , cumplimiento_rotacion_adriana AS (
    SELECT
      DATE_TRUNC(fecha, MONTH) AS mes,
      SAFE_DIVIDE(SUM(salidas_semana), SUM(objetivo_semanal)) AS cumplimiento_gestion_rotacion --cumplimiento_ponderado_mensual,
    FROM `papyrus-delivery-data.habicredit.cumplimiento_productividad_rotacion_analistas`
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE fase != 'Fase 5' AND correo_analista IN UNNEST(analistas_sup_adriana)
    GROUP BY 1
  )

  , cumplimiento_rotacion_oscar AS (
    SELECT
      DATE_TRUNC(fecha, MONTH) AS mes,
      SAFE_DIVIDE(SUM(salidas_semana), SUM(objetivo_semanal)) AS cumplimiento_gestion_rotacion --cumplimiento_ponderado_mensual,
    FROM `papyrus-delivery-data.habicredit.cumplimiento_productividad_rotacion_analistas`
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE fase != 'Fase 5' AND correo_analista IN UNNEST(analistas_sup_oscar)
    GROUP BY 1
  )

  , cumplimiento_rotacion_tom AS (
    SELECT
      DATE_TRUNC(fecha, MONTH) AS mes,
      SAFE_DIVIDE(SUM(salidas_semana), SUM(objetivo_semanal)) AS cumplimiento_gestion_rotacion --cumplimiento_ponderado_mensual,
    FROM `papyrus-delivery-data.habicredit.cumplimiento_productividad_rotacion_analistas`
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE fase != 'Fase 5' AND correo_analista IN UNNEST(analistas_sup_tom)
    GROUP BY 1
  )

  , cumplimiento_rotacion_yeison AS (
    SELECT
      DATE_TRUNC(fecha, MONTH) AS mes,
      SAFE_DIVIDE(SUM(salidas_semana), SUM(objetivo_semanal)) AS cumplimiento_gestion_rotacion --cumplimiento_ponderado_mensual,
    FROM `papyrus-delivery-data.habicredit.cumplimiento_productividad_rotacion_analistas`
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE fase != 'Fase 5' AND correo_analista IN UNNEST(analistas_sup_yeison)
    GROUP BY 1
  )

  /*, Se depreca este query para usar el que esta abajo que guarda. mejor los cambios históricas. Este query es una vista actual de todo lo sucedido e ignora situaciones pasadas
    cumplimiento_rotacion_analistas AS (
      SELECT
        DATE_TRUNC(fecha, MONTH) AS mes,
        correo_analista,
        SAFE_DIVIDE(SUM(salidas_semana), SUM(objetivo_semanal)) AS cumplimiento_ponderado_mensual,
      FROM `papyrus-delivery-data.habicredit.cumplimiento_productividad_rotacion_analistas`
      WHERE fase != 'Fase 5'
      GROUP BY 1, 2
      ORDER BY mes DESC, cumplimiento_ponderado_mensual DESC
    )
  */

  , cumplimiento_rotacion_analistas AS (

    WITH main AS (
      SELECT
        correo_analista, salidas_semana, objetivo_semanal
      FROM `papyrus-delivery-data.habicredit.cumplimiento_productividad_rotacion_analistas_historia`
      CROSS JOIN semanas_rotacion
      WHERE fase != 'Fase 5' AND
        -- Filtramos para que solo traiga VIERNES (6 en BigQuery, donde Domingo=1)
        EXTRACT(DAYOFWEEK FROM fecha_sync_rotacion) = 6
        AND DATE_TRUNC(DATE(fecha_sync_rotacion), WEEK(MONDAY)) = DATE_TRUNC(DATE(fecha), WEEK(MONDAY))
        AND fecha IN UNNEST(semanas_rot)
      QUALIFY ROW_NUMBER() OVER(PARTITION BY DATE(fecha_sync_rotacion), fecha, fase, correo_analista ORDER BY fecha_sync_rotacion DESC) = 1
    )
    SELECT
      mes_comision_input AS mes,
      correo_analista, -- Para el mes de marzo se hace de manera manual el caulculo, para los demás meses está automático
      CASE
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'alejandraorganista@habi.co' THEN 0.6492038217
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'claudiapardo@habicredit.co' THEN 0.5206521739
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'danielibague@habicredit.co' THEN 0.5539256198
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'eblinsmontoya@habi.co' THEN 0.8015151515
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'geidygonzalez@habicredit.co' THEN 0.4694444444
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'gloriaarrieta@habicredit.co' THEN 0.5346774194
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'ivetthecasanas@habicredit.co' THEN 0.7012589928
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'jancyruiz@habi.co' THEN 0.6434971098
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'jefersonrincon@habicredit.co' THEN 0.8134615385
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'jhonathanflorez@habicredit.co' THEN 0.6715517241
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'johannacardenas@habicredit.co' THEN 0.7095637584
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'lauracuevas@habicredit.co' THEN 0.8141891892
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'leydemontoya@habicredit.co' THEN 0.6645348837
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'linabedoya@habi.co' THEN 0.7621134021
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'maryipoveda@habicredit.co' THEN 0.7694444444
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'miryamhenao@habicredit.co' THEN 0.6916666667
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'shirleydiaz@habicredit.co' THEN 0.7938172043
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'tatianatorres@habicredit.co' THEN 0.9241596639
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'yeissonortiz@habi.co' THEN 0.8583333333
        WHEN mes_comision_input = '2026-03-01' AND correo_analista = 'yessicabarrera@habicredit.co' THEN 0.8244017094


        
      ELSE SUM(salidas_semana)/SUM(objetivo_semanal) END AS cumplimiento_ponderado_mensual
    FROM main
    GROUP BY 1,2

  )

  -------- Cumplimiento Rotaciones Legalización -------- 

  -------- Reproceso KAM --------
  -- Esto viene de `papyrus-delivery-data.habicredit.reprocesos_kam`
  , reprocesos_kam_octubre_2025 AS (

    WITH main AS (
    select
      mes_comision_input AS mes_comision,
      report_id,
      correo_director_comercial,
      kam,
      correo_broker,
      analista_radicacion,
      --analista_pre_legalizacion,
      analista_legalizacion,
      monto_aprobado,
      date(fecha_radicacion) as fecha_radicacion,
      date(fecha_aprobacion) as fecha_aprobacion,
      date(fecha_desembolso) as fecha_desembolso,
      if(date_trunc(fecha_radicacion, month) = mes_comision_input, 1.0, null) as radicacion,
      if(date_trunc(fecha_radicacion, month) = mes_comision_input, monto_solicitado, null) as monto_solicitado,
      if(date_trunc(fecha_aprobacion, month) = mes_comision_input, 1.0, null) as aprobacion,
      
      if(
        date_trunc(fecha_radicacion, month) = date_sub(mes_comision_input, interval 1 month) and mes_aprob_vs_rad <= 1,
        1.0, null) 
      as aprobacion_dual,

      if(date_trunc(fecha_radicacion, month) = date_sub(mes_comision_input, interval 1 month), 1.0, 0) as aprobacion_dual_meta, -- de las radiaciones obtenidas el mes anterior a la comisión actual 60%
      if(date_trunc(fecha_desembolso, month) = mes_comision_input, 1.0, null) as desembolsos, 
      if(date_trunc(fecha_desembolso, month) = mes_comision_input, monto_desembolso, null) as monto_desembolso,

    FROM `papyrus-delivery-data.habicredit.main_board`
  ),

  negocios_en_otros_bancos AS (
    SELECT 
      identificacion_cliente, 
      analista_radicacion,
      banco,
      linea_credito,
      tipo_producto,
      correo_director_comercial,
      correo_broker,
      fecha_radicacion,
      monto_aprobado AS monto_aprobado_aprobado, 
      fecha_aprobacion AS fecha_aprobacion_aprobado,
      report_id,
      id_card_rad,
    FROM `papyrus-delivery-data.habicredit.main_board`
    WHERE monto_aprobado IS NOT NULL AND banco != 'COLPATRIA'
  )

  , pre_reprocesos_raw AS (
    
    SELECT
      mes_comision_input mes_comision,
      mbi.report_id,
      DATE(ultima_vez_ingreso_subproceso_mesa_salvamento) AS entrada_mesa_de_salvamento_ultima,
      DATE(inicio_subproceso_mesa_salvamento) AS entrada_mesa_de_salvamento,
      KAM,
      mbi.entrada_reconsideracion_banco_primera,
      mbi.banco,
      mbi.tipo_producto,
      mbi.analista_radicacion,
      mbi.identificacion_cliente,
      mbi.fecha_radicacion,
      mbi.fecha_aprobacion,
      entrada_aprobado_first,
      mbi.monto_aprobado,

      nob.fecha_radicacion AS fecha_radicacion_aprobado,
      nob.tipo_producto AS tipo_producto_aprobado,
      nob.banco AS banco_aprobado,
      nob.monto_aprobado_aprobado, 
      nob.fecha_aprobacion_aprobado,

      IF(inicio_subproceso_mesa_salvamento IS NOT NULL, 1, NULL) AS negados,
      
      IF(
        -- DATE_TRUNC(entrada_reconsideracion_banco, MONTH) = mes_comision_input OR 
        DATE_TRUNC(entrada_reconsideracion_banco_primera, MONTH) = mes_comision_input
      , 1, NULL) AS reprocesos,

      IF(
        -- DATE_TRUNC(mbi.fecha_aprobacion, MONTH) = mes_comision_input OR 
        DATE_TRUNC(mbi.fecha_aprobacion, MONTH) = mes_comision_input AND inicio_subproceso_mesa_salvamento IS NOT NULL
      , 1, NULL) AS aprobados,

      IFNULL(
      IF(
        (mbi.fecha_aprobacion IS NULL OR nob.fecha_radicacion >= inicio_subproceso_mesa_salvamento)
        AND
        (
        DATE(mbi.inicio_subproceso_mesa_salvamento) < DATE(fecha_aprobacion_aprobado) AND 
            (
            -- DATE_TRUNC(DATE(fecha_aprobacion_aprobado), MONTH) = mes_comision_input OR 
            DATE_TRUNC(DATE(fecha_aprobacion_aprobado), MONTH) = mes_comision_input)
            AND nob.tipo_producto = mbi.tipo_producto
            AND nob.banco != mbi.banco
        )
      , 1, NULL) 
      , 0) AS aprobado_otro_banco

    FROM `papyrus-delivery-data.habicredit.main_board_integrado` mbi
    LEFT JOIN negocios_en_otros_bancos nob ON nob.identificacion_cliente = mbi.identificacion_cliente
    QUALIFY ROW_NUMBER() OVER(PARTITION BY mbi.report_id ORDER BY fecha_radicacion, fecha_aprobacion_aprobado DESC) = 1

  )

  , final AS (
    SELECT
      *,
      CASE
        WHEN aprobados = 1 THEN monto_aprobado
        WHEN aprobado_otro_banco = 1 THEN monto_aprobado_aprobado
      END monto_aprobado_final

    FROM pre_reprocesos_raw
    --WHERE DATE_TRUNC(entrada_reconsideracion_banco_primera, MONTH) = mes_comision_input
    )

    , nueva_fuente_cambio_condiciones AS (

      select 
        DATE(bt.fecha_inicio_pre_legalizacion) AS fecha_incio_cambio_condiciones,
        bt.report_id,
        mb.kam,
        mb.fecha_aprobacion,
        mb.monto_aprobado,

      from `papyrus-delivery-data.habicredit.bt_pre_legalizacion_bi_new` bt
      left join `papyrus-delivery-data.habicredit.main_board` mb on bt.report_id = cast(mb.report_id as int64)
      where es_cambio_condiciones is true
      qualify row_number() over(partition by report_id, ciclo) = 1

    ) 

    ----- // Cambio de condiciones // ----
  , reproceso_cambio_condiciones AS (
      select 
          date_trunc(fecha_incio_cambio_condiciones, month) mes_cambio_condiciones,
          kam, 
          count(report_id) reprocesos_cambio_condiciones
        from nueva_fuente_cambio_condiciones
        where --etiqueta_cambio_de_condiciones is not null and 
        date_trunc(fecha_incio_cambio_condiciones, month) = mes_comision_input  
        group by 1,2
  )
      ----- // Cambio de condiciones // ----

  , aprobacion_cambio_condiciones AS (
      select 
        date_trunc(fecha_aprobacion, month) mes_cambio_condiciones,
        kam, 
        count(report_id) aprobaciones_cambio_condiciones,
        sum(safe_cast(monto_aprobado as int64)) as monto_aprobado_cambio_de_condiciones
      from nueva_fuente_cambio_condiciones
      where --(etiqueta_cambio_de_condiciones is not null) and
      date_trunc(fecha_aprobacion, month) = mes_comision_input
      group by 1,2
  )

    SELECT 
      mes_comision_input AS mes_comision,
      final.kam, 
      SUM(reprocesos) + IFNULL(MAX(rcd.reprocesos_cambio_condiciones), 0) AS reprocesos,
      SUM(aprobados + aprobado_otro_banco) + IFNULL(MAX(aprobaciones_cambio_condiciones), 0) AS aprobados,
      SUM(monto_aprobado_final) +IFNULL(MAX(SAFE_CAST(monto_aprobado_cambio_de_condiciones AS INT64)), 0) AS monto_aprobado_final
    FROM final
    LEFT JOIN reproceso_cambio_condiciones rcd ON rcd.kam = final.kam 
    LEFT JOIN aprobacion_cambio_condiciones acd ON acd.kam = final.kam 
    GROUP BY 1,2
  )

  -------- Reproceso KAM ------

  , cp_devoluciones_kam AS (
  SELECT DATE('2026-07-01') AS fecha, 'anagonzalez@habi.co' AS kam, 0.048  AS dev_docs_habi, 0.068  AS dev_banco_broker UNION ALL
  SELECT DATE('2026-07-01'), 'mairabernal@habi.co', 0.0295, 0.0314 UNION ALL
  SELECT DATE('2026-07-01'), 'dianamora@habicredit.co', 0.0398, 0.0585 UNION ALL
  SELECT DATE('2026-07-01'), 'lunalopez@habicredit.co', 0.0263, 0.065 UNION ALL
  -- Agosto 2026: tabla de devoluciones KAM (Mesa/Banco) que entrego Johhan.
  -- La imagen trae los valores en % entero (ej. "4,70%"); se dividen entre 100
  -- para que queden en la misma escala fraccion decimal que usa el resto de la
  -- CTE y las bandas de pago de dev_docs_habi/dev_banco_broker en
  -- comisiones_internas_hc_final.sql (0-0.05 y 0-0.20 respectivamente).
  SELECT DATE('2026-08-01'), 'anagonzalez@habi.co', 0.0470, 0.0775 UNION ALL
  SELECT DATE('2026-08-01'), 'mairabernal@habi.co', 0.0383, 0.0435 UNION ALL
  SELECT DATE('2026-08-01'), 'dianamora@habicredit.co', 0.0379, 0.0297 UNION ALL
  SELECT DATE('2026-08-01'), 'lunalopez@habicredit.co', 0.0352, 0.0808
  )

  , ans_anlista_estados AS (
    SELECT 
      DATE_TRUNC(fecha_conexion, month) AS mes_estados,
      AVG(dias_habiles_comentario) avg_dias_habiles,
      SAFE_DIVIDE(
        SUM(IF(cumplimiento_ans_3d ='Dentro de ANS', 1, NULL)),
        COUNT(cumplimiento_ans_3d)
      ) AS p_cumplimiento_ans_3d

    FROM `papyrus-delivery-data.habicredit.tiempo_comentario_operitee_316981488` c
    LEFT JOIN `papyrus-master.liquidez_platinum_co.fct_radicacion` fr ON fr.radicacion_id = SAFE_CAST(c.report_id AS INT64)
    WHERE ((c.banco NOT IN ('Credifamilia', 'Bancoomeva', 'Scotiabank Colpatria', 'Bancolombia', 'Banco de Occidente') AND c.solicitante_residente_en_el_exterior_colex = 'No')) --AND fr.correo_broker != 'habicreditglobal@habi.co'
    GROUP BY  1
  )

  , desembolsos_legalizacion_no_habicredit AS (

    SELECT
      DATE_TRUNC(fecha_ingreso_recursos_entidad_1, MONTH) AS fecha_desembolso,
      SUM(valor_credito_1) AS monto_desembolso
    FROM `papyrus-delivery-data.habicredit.desembolsos_ibuyer_hc`
    GROUP BY 1
  )

  , desembolsos_legalizacion_no_habicredit_analistas AS (

    SELECT
      DATE_TRUNC(fecha_ingreso_recursos_entidad_1, MONTH) AS fecha_desembolso,
      correo_analista_desembolsos,
      SUM(valor_credito_1) AS monto_desembolso
    FROM `papyrus-delivery-data.habicredit.desembolsos_ibuyer_hc`
    GROUP BY 1,2
  )
  ---------------------- // Graduaciones // ----------------------------

  , graduaciones AS (

    WITH radicaciones_categoria_broker_real AS (
      SELECT 
        DATE_TRUNC(fecha, month) fecha, correo_director_comercial, categoria, SUM(radicaciones) AS radicaciones
      FROM `papyrus-delivery-data.habicredit.radicaciones_por_categoria_1`

      GROUP BY 1,2,3
      ORDER BY 1 DESC,2,3
    )

    , radicaciones_categoria_broker_esquema AS (

      SELECT 
        be.*, brokers*productividad AS radicaciones_esquema, br.radicaciones
      FROM `papyrus-delivery-data.habicredit.tabla_productividad_brokers_comisiones` be 
      LEFT JOIN radicaciones_categoria_broker_real AS br ON br.fecha = be.fecha AND br.correo_director_comercial = be.director AND br.categoria = be.categoria
      WHERE be.fecha = mes_comision_input
    )

    , radicaciones_categoria_broker_ejecucion AS (
      SELECT 
        *, 
        IFNULL(SAFE_DIVIDE(radicaciones, radicaciones_esquema), 0) AS ejecucion 

      FROM radicaciones_categoria_broker_esquema
    )

    , graduaciones_director_gerente_comercial AS (

      WITH main AS (
        SELECT 
          fecha, categoria, AVG(ejecucion) AS p_ejecucion
        FROM radicaciones_categoria_broker_ejecucion
        WHERE director IS NOT NULL AND categoria IN ('standard', 'elite', 'plus')
        GROUP BY 1,2
      )

      , main_esquema AS (

        SELECT 

          *, 
          CASE
            WHEN categoria = 'standard' THEN SAFE_DIVIDE(p_ejecucion, .7) --- Valor del esquema
            WHEN categoria IN ('elite', 'plus') THEN SAFE_DIVIDE(p_ejecucion, .8) --- Valor del esquema
          END p_ejecucion_fix
        
        FROM main

      )

      SELECT
        fecha, 
        'Gerente Comercial' AS posicion,
        'sammyvargas@habicredit.co' AS beneficiado,
        AVG(p_ejecucion_fix) AS radicaciones_categoria -- p_ejecucion_fix (Graduacion)
      FROM main_esquema
      GROUP BY 1,2,3

    )

    , graduaciones_director_non_ibuyer AS (
      SELECT 
        fecha, 
        'Director non ibuyer' AS posicion,
        director AS beneficiado,
        AVG(ejecucion) AS radicaciones_categoria -- p_ejecucion (Graduacion)
      FROM radicaciones_categoria_broker_ejecucion
      WHERE director IS NOT NULL
      GROUP BY 1,2,3
    )

    SELECT * FROM graduaciones_director_gerente_comercial
    UNION ALL
    SELECT * FROM graduaciones_director_non_ibuyer

  )
  ---------------------- // Graduaciones // ----------------------------

  ---------------------- // Reprocesos KAM // ----------------------------

  , pre_reprocesos_raw AS(
    SELECT  * FROM `papyrus-delivery-data.habicredit.reprocesos_kam_100`
  )

  , pre_reprocesos AS (

    SELECT
      KAM,
      mes_reproceso,
      IFNULL(SUM(reprocesos), 0) AS reprocesos,
      IFNULL(SUM(aprobaciones), 0) AS aprobados,
      SUM(monto_aprobado) AS monto_aprobado,
    FROM pre_reprocesos_raw
    GROUP BY 1,2
  )

  , reprocesos_esquema AS (

    SELECT 
      KAM,
      mes_reproceso,
      SAFE_DIVIDE(reprocesos, 120) AS condicion_1, -- Se coloca aqui la cantidad  de reprocesos que se espera según el esquema
      SAFE_DIVIDE(aprobados, 60) AS condicion_2, -- Se coloca aqui la cantidad  de aprobaciones que se espera según el esquema
      monto_aprobado
    FROM pre_reprocesos
  )

  , reprocesos AS (

    SELECT
      mes_reproceso,
      KAM AS beneficiado,
      condicion_1 AS reprocesos_kam,
      condicion_2 AS aprobaciones_kam,
      -- SAFE_DIVIDE(condicion_1 + condicion_2, 2) AS cumplimiento_reprocesos, -- Dejó de usarse esta manera de medición a parrtir del esquema de 2025-08
      monto_aprobado,
    FROM reprocesos_esquema
  )

  ---------------------- // Reprocesos KAM // ----------------------------

  ---------------------- // Ordenes de escrituración/Ofertas vinculantes/Escrituras // ----------------------------
  , ordenes_firmas AS (
    WITH orden_escrituracion AS (
      SELECT  
        DATE_TRUNC(fecha_orden_escrituracion, MONTH) AS fecha,
        analista,
        COUNT(fecha_orden_escrituracion) AS orden_escrituracion,

    FROM `papyrus-delivery-data.habicredit.ordenes_escrituracion`
    GROUP BY 1,2
    )

    , oferta_vinculante AS (

      SELECT  
        DATE_TRUNC(fecha_oferta_vinculante, MONTH) AS fecha,
        analista,
        COUNT(fecha_oferta_vinculante) AS oferta_vinculante,

      FROM `papyrus-delivery-data.habicredit.ordenes_escrituracion`
      GROUP BY 1,2

    )

    , escrituras AS (

      SELECT  
        DATE_TRUNC(fecha_firma_escritura, MONTH) AS fecha,
        analista,
        COUNT(fecha_firma_escritura) AS escritura,

      FROM `papyrus-delivery-data.habicredit.ordenes_escrituracion`
      GROUP BY 1,2

    )

    ----- Version vigente hasta 2026-07-01: se conserva tal cual para no alterar meses ya pagados. -----
    ----- Arrastra un bug conocido: el listado de analistas lo maneja orden_escrituracion (oe), asi -----
    ----- que un analista con ofertas vinculantes o escrituras pero SIN orden de escrituracion en el -----
    ----- mes desaparece del conteo (queda NULL y el UNPIVOT le borra el indicador). -----
    , legacy AS (
      SELECT
        DATE_TRUNC(fechas.fecha, MONTH) AS fecha,
        REPLACE(REPLACE(oe.analista, 'nrtaco2@gmail.com', ''), ',', '') AS analista,
        CAST(IFNULL(oe.orden_escrituracion, 0) + IFNULL(ov.oferta_vinculante, 0) + IFNULL(e.escritura, 0) AS FLOAT64) AS firma_ordenes_ofertas_escrituras
      FROM `papyrus-data.habi_wh.fechas` AS fechas
      LEFT JOIN orden_escrituracion oe ON oe.fecha = DATE_TRUNC(fechas.fecha, MONTH)
      LEFT JOIN oferta_vinculante ov ON ov.fecha = DATE_TRUNC(fechas.fecha, MONTH) AND ov.analista = oe.analista
      LEFT JOIN escrituras e ON e.fecha = DATE_TRUNC(fechas.fecha, MONTH) AND e.analista = oe.analista
      WHERE fechas.fecha = DATE_TRUNC(fechas.fecha, MONTH) AND fechas.fecha <= CURRENT_DATE('-5')
    )

    ----- Version vigente desde 2026-08-01: cuenta los tres eventos (orden de escrituracion, oferta -----
    ----- vinculante y firma de escritura) sobre la union de los tres, para que ningun analista se -----
    ----- pierda por no tener orden de escrituracion ese mes. -----
    ----- Verificado contra agosto 2026: da exactamente el mismo numero que la version vieja para los -----
    ----- 16 analistas que si tenian orden, y recupera a jeydirodriguez@habicredit.co y -----
    ----- catalinabarco@habi.co, que quedaban sin ninguna fila. -----
    , eventos AS (
      SELECT DATE_TRUNC(fecha_orden_escrituracion, MONTH) AS fecha, analista
      FROM `papyrus-delivery-data.habicredit.ordenes_escrituracion`
      WHERE fecha_orden_escrituracion IS NOT NULL
      UNION ALL
      SELECT DATE_TRUNC(fecha_oferta_vinculante, MONTH) AS fecha, analista
      FROM `papyrus-delivery-data.habicredit.ordenes_escrituracion`
      WHERE fecha_oferta_vinculante IS NOT NULL
      UNION ALL
      SELECT DATE_TRUNC(fecha_firma_escritura, MONTH) AS fecha, analista
      FROM `papyrus-delivery-data.habicredit.ordenes_escrituracion`
      WHERE fecha_firma_escritura IS NOT NULL
    )

    , actual AS (
      SELECT
        fecha,
        REPLACE(REPLACE(analista, 'nrtaco2@gmail.com', ''), ',', '') AS analista,
        CAST(COUNT(*) AS FLOAT64) AS firma_ordenes_ofertas_escrituras
      FROM eventos
      GROUP BY 1,2
    )

    SELECT * FROM legacy WHERE mes_comision_input < '2026-08-01'
    UNION ALL
    SELECT * FROM actual WHERE mes_comision_input >= '2026-08-01'
  )
  ---------------------- // Ordenes de escrituración/Ofertas vinculantes/Escrituras // ----------------------------

  ---------------------- // Cumplimiento ANS Analistas Legalización // ----------------------------
  , main_gestion_ANS_FM AS (
  WITH main AS (
    SELECT 
        *EXCEPT(asignacion_analista),
        TRIM(LOWER(asignacion_analista)) AS asignacion_analista,
    FROM `papyrus-delivery-data.habicredit.dias_en_cola_legalizacion_flow_manager_actual_y_corregido_historia`
  WHERE DATE_TRUNC(DATE(fecha_sync), MONTH) = mes_comision_input
    QUALIFY ROW_NUMBER() OVER (PARTITION BY report_id, DATE(fecha_sync) ORDER BY fecha_sync DESC) = 1 -- Negocios filtrados para obtener el ultimo registro del día
  )

    , concat_fechas AS (

      SELECT 
        main.*,
        fechas.DayNameOfWeek
      FROM main
      LEFT JOIN `papyrus-master.general_dwh_mx.dim_calendario` fechas ON fechas.fecha = DATE(fecha_sync)
      WHERE phase_name NOT IN ('Registro - Boleta de ingreso Notaria', 'Fecha de visita ISA', 'Orden de Escrituración Notaria', 'Firmas Notaria', 'Firma apoderado Notaria', 'Fecha de Visita TINSA', 'Concepto de Perito TINSA')
    )

    , estado_ans AS (
      SELECT
        *,
        CASE 
          WHEN DayNameOfWeek IN ('Tuesday', 'Thursday')
          THEN 
            CASE
              WHEN fuera_de_ans = TRUE THEN 'Fuera de ANS'
              ELSE 'Dentro de ANS'
            END
          ELSE NULL
        END AS fuera_de_ans_string
      FROM concat_fechas
    )

    SELECT * FROM estado_ans

  )

  , gestion_ANS_FM AS (
    SELECT 
      mes_comision_input AS fecha_sync, 
      asignacion_analista,
      SAFE_DIVIDE(SUM(IF(fuera_de_ans_string = "Fuera de ANS",1,0)), COUNT(fuera_de_ans_string)) AS cumplimiento_ans,

    FROM main_gestion_ANS_FM
    GROUP BY 1,2
    ORDER BY 2 DESC

  )

  ---------------------- // Cumplimiento ANS Analistas Legalización // ----------------------------


  ---------------------- // Cumplimiento ANS Legalización Gerente Ops // ----------------------------

  , gestion_ANS_FM_gerente AS (
    SELECT
        mes_comision_input AS fecha_sync,
      SUM(IF(fuera_de_ans_string = "Fuera de ANS",1,0))/COUNT(fuera_de_ans_string) AS cumplimiento_ans
    FROM main_gestion_ANS_FM
    GROUP BY 1
  )

  ---------------------- // Cumplimiento ANS Legalización Gerente Ops // ----------------------------

  ---------------------- // Cumplimiento ANS Inicio (Gestión) Bolsa // ----------------------------

  , main_inicio_bolsa AS (
    SELECT 
      DISTINCT pb.card_id,
      okr.*
      EXCEPT(
        Tiempo_en_inicio,
        Tiempo_habil_en_inicio,
        cumple_okr,
        card_id,
        ultima_salida_legalizacion,
        banco_final,
        analista_de_bolsa,
        identificaci_n_del_cliente,
        nombre_y_apellidos_cliente,
        correo_broker,
        tipo,
        monto_aprobado
      ),

      okr.card_id AS card_id_leg,

      COALESCE(pb.correo_broker, okr.correo_broker) AS correo_broker,
      COALESCE(pb.nombre_y_apellidos_cliente, okr.nombre_y_apellidos_cliente) AS nombre_y_apellidos_cliente,
      COALESCE(pb.identificaci_n_del_cliente, okr.identificaci_n_del_cliente) AS identificaci_n_del_cliente,
      COALESCE(pb.tipos_de_productos, okr.tipo) AS tipo,
      COALESCE(pb.monto_aprobado, okr.monto_aprobado) AS monto_aprobado,
      COALESCE(pb.analista_de_bolsa, okr.analista_de_bolsa) AS analista_de_bolsa,
      COALESCE(pb.analista_de_bolsa_inicial, pb.analista_de_bolsa, okr.analista_de_bolsa) AS analista_de_bolsa_inicial,
      CAST(okr.ultima_salida_legalizacion AS DATE) AS ultima_salida_legalizacion,
      COALESCE(okr.banco_final, pb.banco) AS banco_final, 
      pb.entrada_gestion,
      pb.salida_gestion,

      pb.name_actual_phase AS name_actual_phase_Bolsa,

      CASE 
        WHEN cast(ultima_salida_legalizacion AS DATE) <= CAST('2024-06-11' AS DATE)
        THEN cast(ultima_salida_legalizacion AS DATE) 
        ELSE CAST(entrada_gestion AS DATE)
      END ULTIMA_SALIDA_LEGALZIACION_CORTE_CAMBIO_DE_FLUJO,

      CASE 
        WHEN CAST(okr.ultima_salida_legalizacion AS DATE) <= '2024-06-11'
        THEN okr.Tiempo_en_inicio
        ELSE COALESCE(pb.Tiempo_en_inicio, okr.Tiempo_en_inicio)
      END AS Tiempo_en_inicio, 

      CASE 
        WHEN CAST(okr.ultima_salida_legalizacion AS DATE) <= '2024-06-11'
        THEN okr.Tiempo_habil_en_inicio
        ELSE COALESCE(pb.Tiempo_habil_en_inicio, okr.Tiempo_habil_en_inicio)
      END AS Tiempo_habil_en_inicio, 

      CASE 
        WHEN CAST(okr.ultima_salida_legalizacion AS DATE) <= '2024-06-11'
        THEN okr.cumple_okr
        ELSE COALESCE(pb.cumple_okr, okr.cumple_okr)
      END AS cumple_okr, 

    FROM `papyrus-delivery-data.habicredit.HC_OKR_dias_habiles_bolsa` okr
    FULL OUTER JOIN `papyrus-delivery-data.habicredit.pipe_bolsa` pb
    ON okr.card_id_radicaci_n = pb.card_id_radicaci_n
  )

  , inicio_bolsa_supervisor AS (
    SELECT

      DATE_TRUNC(ULTIMA_SALIDA_LEGALZIACION_CORTE_CAMBIO_DE_FLUJO, MONTH) AS fecha,
      SUM(IF(Tiempo_habil_en_inicio <= 3, 1,0))/COUNT(Tiempo_habil_en_inicio) AS inicio_bolsa, -- Gestión Bolsa

    FROM main_inicio_bolsa 
    GROUP BY 1
  )

  , inicio_bolsa_analista AS (

    SELECT

      DATE_TRUNC(entrada_gestion, MONTH) AS fecha,
      CASE 
        /*WHEN analista_de_bolsa_inicial = 'Angelica Avellaneda' THEN 'angelicaavellaneda@habi.co'
        WHEN analista_de_bolsa_inicial = 'Edilberto Botia' THEN 'edilbertobotia@habi.co'
        WHEN analista_de_bolsa_inicial = 'Leidy Moscoso' THEN 'leidymoscoso@habi.co'
        WHEN analista_de_bolsa_inicial = 'Claudia Pardo' THEN 'claudiapardo@habicredit.co'
        WHEN analista_de_bolsa_inicial = 'Carol Gonzalez' THEN 'carolgonzalez@habicredit.co'
        WHEN analista_de_bolsa_inicial = 'Tatiana Barrera' THEN 'yessicabarrera@habicredit.co'
        WHEN analista_de_bolsa_inicial = 'Yeferson Pineda' THEN 'yefersonpineda@habicredit.co'
        WHEN analista_de_bolsa_inicial = 'Johanna Cardenas' THEN 'johannacardenas@habicredit.co'
        WHEN analista_de_bolsa_inicial = 'Maria Mahecha' THEN 'mariamahecha@habicredit.co'
        */
        WHEN analista_de_bolsa_inicial = 'Laura Sofia Ariza Colon' THEN 'lauraariza@habi.co'
        WHEN analista_de_bolsa_inicial = 'Jeydi Rodriguez' THEN 'jeydirodriguez@habicredit.co'
      END analista_pre_legalizacion,
      SUM(IF(Tiempo_habil_en_inicio <= 3, 1,0))/COUNT(Tiempo_habil_en_inicio) AS inicio_bolsa, -- Gestión Bolsa

    FROM main_inicio_bolsa 
    GROUP BY 1,2

  )

  ---------------------- // Cumplimiento ANS Inicio (Gestión) Bolsa // ----------------------------

  ---------------------- // Cumplimiento ANS Tiempos de respuesta buzón // ----------------------------

  , tiempo_respuesta_buzon_supervisor AS (

  SELECT 

    DATE_TRUNC(ultima_entrada_pendientes_de_asignar, MONTH) AS fecha, 
    AVG(tiempo_habil_pendientes_de_asignar) AS tiempo_habil_pendientes_de_asignar,

  FROM `papyrus-delivery-data.habicredit.pipe_buzon_pre_legalizacion`
  GROUP BY 1
  )


  , tiempo_respuesta_buzon_analista AS (

  SELECT 
    DATE_TRUNC(ultima_entrada_pendientes_de_asignar, MONTH) AS fecha, 
    CASE 
        /*WHEN analista_pre_legalizacion = 'Angelica Avellaneda' THEN 'angelicaavellaneda@habi.co'
        WHEN analista_pre_legalizacion = 'Edilberto Botia' THEN 'edilbertobotia@habi.co'
        WHEN analista_pre_legalizacion = 'Leidy Moscoso' THEN 'leidymoscoso@habi.co'
        WHEN analista_pre_legalizacion = 'Claudia Pardo' THEN 'claudiapardo@habicredit.co'
        WHEN analista_pre_legalizacion = 'Carol Gonzalez' THEN 'carolgonzalez@habicredit.co'
        WHEN analista_pre_legalizacion = 'Tatiana Barrera' THEN 'yessicabarrera@habicredit.co'
        WHEN analista_pre_legalizacion = 'Yeferson Pineda' THEN 'yefersonpineda@habicredit.co'
        WHEN analista_pre_legalizacion = 'Johanna Cardenas' THEN 'johannacardenas@habicredit.co'
        WHEN analista_pre_legalizacion = 'Maria Mahecha' THEN 'mariamahecha@habicredit.co'
        */
        WHEN analista_pre_legalizacion = 'Jeydi Rodriguez' THEN 'jeydirodriguez@habicredit.co'
        WHEN analista_pre_legalizacion = 'Laura Ariza' THEN 'lauraariza@habi.co'
      END analista_pre_legalizacion,
    AVG(tiempo_habil_pendientes_de_asignar) AS tiempo_habil_pendientes_de_asignar,
    
  FROM `papyrus-delivery-data.habicredit.pipe_buzon_pre_legalizacion`
  GROUP BY 1,2
  )

  ---------------------- // Cumplimiento ANS Tiempos de respuesta buzón // ----------------------------

  ---------------------- // ODE ibuyer // ----------------------------

  , ode_mes_supervisor AS (
    SELECT

      DATE_TRUNC(FECHA_DE_ENTREGA_A_ESCRITURACION, MONTH) AS fecha,
      CAST(COUNT(DISTINCT NID) AS FLOAT64) AS ordenes_escrituracion_ibuyer,

    FROM `papyrus-delivery-data.habicredit.legalizacion_ibuyer_hc_ops`
    WHERE IF(TRIM(ANALISTA_LEGALIZACION_2) = '', NULL, ANALISTA_LEGALIZACION_2) IS NOT NULL
    GROUP BY 1
  )

  , ode_24_supervisor AS (
    SELECT

      DATE_TRUNC(FECHA_DE_ENTREGA_A_ESCRITURACION, MONTH) AS fecha,
      CAST(COUNT(DISTINCT NID) AS FLOAT64) AS ordenes_escrituracion_ibuyer,

    FROM `papyrus-delivery-data.habicredit.legalizacion_ibuyer_hc_ops`
    WHERE DATE_TRUNC(FECHA_DE_ENTREGA_A_ESCRITURACION, DAY) <= IF(mes_comision_input = '2025-08-01', DATE_ADD(mes_comision_input, INTERVAL 24 DAY), DATE_ADD(mes_comision_input, INTERVAL 23 DAY)) -- Se realiza está condición con el fin de ajustar los datos para el mes de agosto 2025 ya que el 24 cae un domingo.
    AND IF(TRIM(ANALISTA_LEGALIZACION_2) = '', NULL, ANALISTA_LEGALIZACION_2) IS NOT NULL

  GROUP BY 1
  )


  , ode_mes_analista AS (
    SELECT

      DATE_TRUNC(FECHA_DE_ENTREGA_A_ESCRITURACION, MONTH) AS fecha,
      CASE
        WHEN UPPER(ANALISTA_LEGALIZACION_2) IN ("AN1A GONZÁLEZ","ANA GONZALEZ") THEN 'anagonzalez@habi.co'
        WHEN UPPER(ANALISTA_LEGALIZACION_2) = "LAURA BELTRAN" THEN 'laurabeltran@habi.co'
        WHEN UPPER(ANALISTA_LEGALIZACION_2) = "OSCAR SAENZ" THEN 'oscarsaenz@habicredit.co'
        WHEN UPPER(ANALISTA_LEGALIZACION_2) = "LEIDY VARGAS" THEN 'leidyvargas@habi.co'
        WHEN UPPER(ANALISTA_LEGALIZACION_2) = "NICOL FONSECA" THEN 'nicolfonseca@habi.co'
      END analista_leg_ibuyer,
      CAST(COUNT(DISTINCT NID) AS FLOAT64) AS ordenes_escrituracion_ibuyer,

    FROM `papyrus-delivery-data.habicredit.legalizacion_ibuyer_hc_ops`
    WHERE ETAPA_LEG_IBUYER2 != 'Desistidos'
    GROUP BY 1,2
  )

  , ode_24_analista AS (
    SELECT

      DATE_TRUNC(FECHA_DE_ENTREGA_A_ESCRITURACION, MONTH) AS fecha,
      CASE
        WHEN UPPER(ANALISTA_LEGALIZACION_2) IN ("ANA GONZÁLEZ","ANA GONZALEZ") THEN 'anagonzalez@habi.co'
        WHEN UPPER(ANALISTA_LEGALIZACION_2) = "LAURA BELTRAN" THEN 'laurabeltran@habi.co'
        WHEN UPPER(ANALISTA_LEGALIZACION_2) = "OSCAR SAENZ" THEN 'oscarsaenz@habicredit.co'
        WHEN UPPER(ANALISTA_LEGALIZACION_2) = "LEIDY VARGAS" THEN 'leidyvargas@habi.co'
        WHEN UPPER(ANALISTA_LEGALIZACION_2) = "NICOL FONSECA" THEN 'nicolfonseca@habi.co'
      END analista_leg_ibuyer,
      CAST(COUNT(DISTINCT NID) AS FLOAT64) AS ordenes_escrituracion_ibuyer,


    FROM `papyrus-delivery-data.habicredit.legalizacion_ibuyer_hc_ops`
    WHERE DATE_TRUNC(FECHA_DE_ENTREGA_A_ESCRITURACION, DAY) <= DATE_ADD(mes_comision_input, INTERVAL 23 DAY)
    AND ETAPA_LEG_IBUYER2 != 'Desistidos'
    GROUP BY 1,2
  )

  ---------------------- // ODE ibuyer // ----------------------------

  ---------------------- // ANS Legalización iBuyer // ----------------------------

  , ans_ibuyer_supervisor AS (

    SELECT 
      mes_comision_input AS mes_comision,
      SAFE_DIVIDE(
        COUNT(CASE WHEN dias_en_cola_str ="Fuera de ANS" then NID else null end)
        ,COUNT(NID)
      ) AS ans_ibuyer
    FROM `papyrus-delivery-data.habicredit.legalizacion_ibuyer_hc_ops_historia`
    WHERE fecha_sync = DATE_ADD(mes_comision_input, INTERVAL 1 MONTH)
    AND ETAPA_LEG_IBUYER2 NOT IN ('Desistidos', 'Finalizadas') AND ETAPA_LEG_IBUYER2 IS NOT NULL
  )

  , ans_ibuyer_analista AS (

    SELECT 
      mes_comision_input AS mes_comision,
      CASE
        WHEN ANALISTA_LEGALIZACION IN ("ANA GONZÁLEZ","ANA GONZALEZ") THEN 'anagonzalez@habi.co'
        WHEN ANALISTA_LEGALIZACION = "LAURA BELTRAN" THEN 'laurabeltran@habi.co'
        WHEN ANALISTA_LEGALIZACION = "OSCAR SAENZ" THEN 'oscarsaenz@habicredit.co'
        WHEN ANALISTA_LEGALIZACION = "LEIDY VARGAS" THEN 'leidyvargas@habi.co'
        WHEN ANALISTA_LEGALIZACION = "NICOL FONSECA" THEN 'nicolfonseca@habi.co'
      END analista_leg_ibuyer,
      CAST(COUNT(DISTINCT NID) AS FLOAT64) ordenes_escrituracion_ibuyer,

      SAFE_DIVIDE(
        COUNT(CASE WHEN dias_en_cola_str ="Fuera de ANS" then NID else null end)
        ,COUNT(NID)
      ) AS ans_ibuyer
    FROM `papyrus-delivery-data.habicredit.legalizacion_ibuyer_hc_ops_historia`
    WHERE fecha_sync = DATE_ADD(mes_comision_input, INTERVAL 1 MONTH)
    AND ETAPA_LEG_IBUYER2 NOT IN ('Desistidos', 'Finalizadas') AND ETAPA_LEG_IBUYER2 IS NOT NULL
    GROUP BY 1,2
  )
  ---------------------- // ANS Legalización iBuyer // ----------------------------

  ---------------------- // Castigo monto desembolso Legalización iBuyer // ----------------------------
  , meta_analistas_leg_ibuyer AS (

    SELECT 
      fecha, 
      analista, 
      meta_legalizacion,
    FROM `papyrus-delivery-data.habicredit.meta_analistas_hc`
    WHERE fecha = mes_comision_input AND equipo = 'Legalización'
    AND analista IN ('anagonzalez@habi.co','laurabeltran@habi.co','oscarsaenz@habicredit.co', 'leidyvargas@habi.co','nicolfonseca@habi.co')
    
  )

  , castigo_monto_desembolso_ibuyer_analista AS (
    WITH main AS (
      SELECT 
        fecha,
        analista_legalizacion,
        meta_legalizacion,
        SUM(monto_desembolso) AS monto_desembolso,
      FROM meta_analistas_leg_ibuyer
      LEFT JOIN main ON DATE_TRUNC(fecha_desembolso, MONTH) = mes_comision_input AND analista = analista_legalizacion
      GROUP BY 1,2,3
    )

    SELECT 
      *,
      IF(SAFE_DIVIDE(monto_desembolso, meta_legalizacion) <.7, 1.0, 0.0) AS castigo_monto  -- 1 y 0 funcionan como TRUE or FALSE. Aplica castigo en caso de ser 1
    FROM main
  )
  , castigo_monto_desembolso_ibuyer_supervisor AS (

    SELECT 
      fecha,
      SUM(monto_desembolso) AS monto_desembolso,
      SUM(meta_legalizacion) AS meta_legalizacion,
      IF(SAFE_DIVIDE(SUM(monto_desembolso), SUM(meta_legalizacion)) <.7, 1.0, 0.0) AS castigo_monto -- 1 y 0 funcionan como TRUE or FALSE. Aplica castigo en caso de ser 1

    FROM castigo_monto_desembolso_ibuyer_analista
    GROUP BY 1
  )
  ---------------------- // Castigo monto desembolso Legalización iBuyer // ----------------------------


  ---------------------- // Nuevos Brokers // ----------------------------

  , nuevos_brokers AS (
    WITH radicaciones_filtradas AS (

      SELECT 
        LOWER(TRIM(mb.correo_broker)) AS correo_broker,
        DATE_TRUNC(mb.fecha_radicacion, MONTH) AS mes_radicacion
      FROM papyrus-delivery-data.habicredit.main_board mb
      WHERE DATE_TRUNC(mb.fecha_radicacion, MONTH) IN (mes_comision_input,DATE_SUB(mes_comision_input, INTERVAL 1 MONTH) 
      )
  ),

    brokers_radicaciones_mayores_2 AS (
      SELECT 
        correo_broker,
        COUNT(*) AS total_radicaciones
      FROM radicaciones_filtradas
      GROUP BY correo_broker
      HAVING COUNT(*) >= 2
    ),

  pre AS (
      SELECT
        db.correo_director,
        COUNT(DISTINCT h_broker_pk) AS vinculaciones,
        COUNT(DISTINCT CASE 
            WHEN DATE_TRUNC(mb.fecha_radicacion, MONTH) = mes_comision_input 
            THEN mb.correo_broker 
          END
        ) AS brokers_radicando_octubre,
        COUNT(DISTINCT CASE 
            WHEN DATE_TRUNC(mb.fecha_radicacion, MONTH) = DATE_SUB(mes_comision_input, INTERVAL 1 MONTH) 
            THEN mb.correo_broker 
          END
        ) AS brokers_radicando_septiembre,
        COUNT(DISTINCT br.correo_broker) AS brokers_mas_2_rad,
        MAX(nb.brokers_nuevos) AS brokers_nuevos,  
        MAX(nb.broker_min_rad) AS broker_min_rad,  
        MAX(nb.productividad) AS productividad

      FROM `papyrus-master.liquidez_platinum_co.dim_brokers` db

      LEFT JOIN `papyrus-delivery-data.habicredit.main_board` mb ON mb.broker_id = db.h_broker_pk
        --ON LOWER(TRIM(db.Correo)) = LOWER(TRIM(mb.correo_broker))

      LEFT JOIN `papyrus-delivery-data.habicredit.nuevos_brokers_meta_comsiones` nb ON nb.director = db.correo_director AND DATE(nb.fecha) = DATE(mes_comision_input)

      LEFT JOIN brokers_radicaciones_mayores_2 br ON LOWER(TRIM(db.correo_personal)) = br.correo_broker

      WHERE DATE_TRUNC(DATE(fecha_inicio_contrato), MONTH) = DATE_SUB(DATE(mes_comision_input), INTERVAL 1 MONTH)

      GROUP BY db.correo_director)

      SELECT
          mes_comision_input AS mes_comision,
          correo_director AS email_director,
          pre.vinculaciones,
          --pre.brokers_nuevos,
          brokers_mas_2_rad,
          --pre.broker_min_rad,
          --pre.productividad,

          -- Desde 2026-08-01 (Esquemas/202608 Comisiones Habicredit COL): un solo indicador
          -- combinado -- broker nuevo del mes que ademas radico minimo 2 operaciones -- sobre
          -- la meta de brokers nuevos. broker_min_rad es una meta aparte que solo aplica a la
          -- Gerente Comercial (ver nuevos_brokers_gerente), no a los directores.
          -- Antes de ese mes se deja intacta la formula original (promedio de dos indicadores)
          -- para que una recorrida de un mes anterior siga reproduciendo lo que ya se pago.
          CASE
              WHEN mes_comision_input >= DATE('2026-08-01') THEN SAFE_DIVIDE(brokers_mas_2_rad, brokers_nuevos)
              ELSE SAFE_DIVIDE(
                     SAFE_DIVIDE(vinculaciones, brokers_nuevos) + SAFE_DIVIDE(brokers_mas_2_rad, broker_min_rad)
                   , 2)
          END AS nuevos_brokers,
        FROM pre
        ORDER BY 1 ASC
    ),

    nuevos_brokers_gerente AS (

      SELECT 
        mes_comision_input AS mes_comision, 
        SAFE_DIVIDE(
          SAFE_DIVIDE(SUM(vinculaciones), MAX(brokers_nuevos)) + SAFE_DIVIDE(SUM(brokers_mas_2_rad), MAX(broker_min_rad))
            , 2) AS nuevos_brokers,
      FROM nuevos_brokers nb
      LEFT JOIN papyrus-delivery-data.habicredit.nuevos_brokers_meta_comsiones mt ON mt.fecha = mes_comision_input
      AND director = 'sammyvargas@habicredit.co'
      GROUP BY 1
  )

  ---------------------- // Nuevos Brokers // ----------------------------


  ---------------------- // -------------------------------------  // ----------------------------
  ---------------------- // -------------------------------------  // ----------------------------
  ---------------------- // Integración y cálculo de cumplimientos // ----------------------------
  ---------------------- // -------------------------------------  // ----------------------------
  ---------------------- // -------------------------------------  // ----------------------------

  , cp_gerente_comercial AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Gerente Comercial' AS posicion,
      'sammyvargas@habicredit.co' AS beneficiado,
      -- monto_desembolso se reactiva desde 2026-08-01 (Esquemas/202608 Comisiones Habicredit
      -- COL). Antes de ese mes debe seguir en NULL (como se calculo/pago originalmente) si el
      -- PROCEDURE se vuelve a correr para un mes anterior.
      CASE WHEN mes_comision_input >= DATE('2026-08-01') THEN SUM(monto_desembolso) ELSE NULL END AS monto_desembolso,
      SUM(radicacion_analista) AS radicacion,
      SUM(monto_solicitado_analista) AS radicacion_monto,
      MAX(nbg.nuevos_brokers) AS nuevos_brokers,
      -- MAX(AR_CI.attachment_rate) AS AR,
      SAFE_DIVIDE(SUM(aprobacion_dual), SUM(aprobacion_dual_meta)) AS aprobacion_dual,

    FROM main
    LEFT JOIN AR_CI ON AR_CI.mes = mes_comision_input
    LEFT JOIN nuevos_brokers_gerente nbg ON mes_comision_input = nbg.mes_comision
    GROUP BY 1,2,3

  )

  , cp_director_comercial_non_ibuyer AS (

    SELECT 
      mes_comision_input AS mes_comision,
      'Director non ibuyer' AS posicion,
      main.correo_director_comercial AS beneficiado,
      SUM(monto_desembolso) AS monto_desembolso,
      SUM(radicacion) AS radicacion,
      SUM(monto_solicitado) AS radicacion_monto,
      SAFE_DIVIDE(SUM(aprobacion_dual), SUM(aprobacion_dual_meta)) AS aprobacion_dual,
      MAX(IFNULL(nb.nuevos_brokers, 0.0)) AS nuevos_brokers,
      MAX(cpd.conversion) AS conversion_pre_leg_director,

    FROM main
    LEFT JOIN nuevos_brokers nb ON nb.email_director = main.correo_director_comercial
    LEFT JOIN conversion_pre_legalizacion_director cpd ON cpd.correo_director_comercial = main.correo_director_comercial AND mes_comision_input = cpd.mes
    WHERE main.correo_director_comercial NOT IN ('germanvargas@habi.co', 'nadiapardo@habicredit.co', 'coordinadoribuyerliquidez@habicredit.co')
    GROUP BY 1,2,3
    HAVING monto_desembolso IS NOT NULL OR radicacion > 0

  )

  , cp_director_graduaciones AS(
      SELECT 
        mes_comision_input AS mes_comision,
        'Director non ibuyer Graduaciones' AS posicion,
        'michaelfelix@habicredit.co' AS beneficiado,   
        CASE
          WHEN mes_comision_input = '2026-02-01' THEN 0.0474
          WHEN mes_comision_input = '2026-03-01' THEN 0.0191
          WHEN mes_comision_input = '2026-04-01' THEN 0.0470
          WHEN mes_comision_input = '2026-05-01' THEN 0.0684
          WHEN mes_comision_input = '2026-06-01' THEN 0.0855
          WHEN mes_comision_input = '2026-07-01' THEN 0.0213
          WHEN mes_comision_input = '2026-08-01' THEN 0.0701

          ELSE NULL END devolucion_broker_formados,

        CASE
          WHEN mes_comision_input = '2026-02-01' THEN 0.7671
          WHEN mes_comision_input = '2026-03-01' THEN 0.0191
          WHEN mes_comision_input = '2026-04-01' THEN 0.7447
          WHEN mes_comision_input = '2026-05-01' THEN 0.7813
          WHEN mes_comision_input = '2026-06-01' THEN 0.8250
          WHEN mes_comision_input = '2026-07-01' THEN 0.7857
          WHEN mes_comision_input = '2026-08-01' THEN 0.68

        ELSE NULL END radicaciones_brokers_activos,
        CASE
          WHEN mes_comision_input = '2026-02-01' THEN 0.483
          WHEN mes_comision_input = '2026-03-01' THEN 0.4857
          WHEN mes_comision_input = '2026-04-01' THEN 0.4700
          WHEN mes_comision_input = '2026-05-01' THEN 0.494
          WHEN mes_comision_input = '2026-06-01' THEN 0.48875
          WHEN mes_comision_input = '2026-07-01' THEN 0.49464
          -- OJO: escala nueva desde agosto. Hasta julio la meta y la ejecucion vivian en 0-0.5
          -- (una tasa/porcentaje); en agosto el reporte trae 4.88 contra una meta de "4" (ver
          -- Comisiones Septiembre ejecucion Agosto). La meta en metas_comisiones_internas sigue
          -- en 0.4 (no se actualizo a 4) -- avisar para que se corrija en el Sheet, si no el
          -- p_ejecucion queda en 12.2 (1220%) en vez de 1.22 (122%).
          WHEN mes_comision_input = '2026-08-01' THEN 4.88

        ELSE NULL END nps_director_devoluciones,

        CASE
          WHEN mes_comision_input = '2026-02-01' THEN 0.7671
          WHEN mes_comision_input = '2026-03-01' THEN 0.06
          WHEN mes_comision_input = '2026-04-01' THEN 0.32
          WHEN mes_comision_input = '2026-05-01' THEN 0.4930
          WHEN mes_comision_input = '2026-06-01' THEN 0.4533
          WHEN mes_comision_input = '2026-07-01' THEN 0.4054
          WHEN mes_comision_input = '2026-08-01' THEN 0.50

        ELSE NULL END graduaciones,

  )

  , cp_kam AS (

    SELECT 
      mes_comision_input AS mes_comision,
      'KAM' AS posicion,
      main.KAM AS beneficiado,
      MAX(ck.calidad) AS calidad_kam,
      SAFE_DIVIDE(SUM(aprobacion_dual), SUM(aprobacion_dual_meta)) AS aprobacion_dual,
      CAST(MAX(rk.reprocesos) AS FLOAT64) AS reprocesos_kam,
      MAX(rk.monto_aprobado_final) AS reprocesos_monto,
      
      CASE
        WHEN mes_comision_input < '2026-07-01'
          THEN CAST(MAX(rk.aprobados) AS FLOAT64)
        WHEN mes_comision_input = '2026-07-01'
          THEN MAX(rk_26.aprobaciones_totales)
        ----- Agosto 2026: aprobaciones_cambio_condiciones de reprocesos_kam_new_26_group no se -----
        ----- esta calculando bien, asi que aprobaciones_kam se arma sumando los otros dos -----
        ----- componentes de la fuente mas el conteo de cambio de condiciones que se saco de forma -----
        ----- manual (ejercicio del usuario, 2026-09-09). Si el problema de la fuente sigue en -----
        ----- septiembre, hay que repetir este parche con los valores de ese mes. -----
        WHEN mes_comision_input = '2026-08-01'
          THEN MAX(rk_26.aprobaciones_reproceso) + MAX(rk_26.aprobaciones_otro_banco) +
            CASE main.kam
              WHEN 'mairabernal@habi.co' THEN 7
              WHEN 'dianamora@habicredit.co' THEN 17
              WHEN 'lunalopez@habicredit.co' THEN 3
              WHEN 'anagonzalez@habi.co' THEN 10
            END
        END AS aprobaciones_kam,

      SAFE_DIVIDE(
        MAX(cpk.devoluciones_resueltas_en_tiempo), MAX(cpk.devoluciones)
      ) AS calidad_dev_pre_legalizacion,

      MAX(dev_k.dev_banco_broker) AS dev_banco_broker,
      MAX(dev_k.dev_docs_habi) AS dev_docs_habi,


    FROM main
    LEFT JOIN reprocesos_kam_octubre_2025 rk ON rk.mes_comision = mes_comision_input AND main.kam = rk.kam
    --LEFT JOIN reprocesos r ON r.mes_reproceso = mes_comision_input AND r.beneficiado = main.KAM
    LEFT JOIN calidad_kam ck ON mes_calidad = mes_comision_input AND ck.kam = main.KAM
    LEFT JOIN `papyrus-delivery-data.habicredit.reprocesos_kam_new_26_group` rk_26 ON rk_26.kam = main.kam AND rk_26.mes = mes_comision_input
    LEFT JOIN calidad_pre_legalizacion_kam cpk ON cpk.kam = main.kam AND DATE_SUB(mes_comision_input, INTERVAL 1 MONTH) = cpk.fecha_inicio_devolucion 
    LEFT JOIN cp_devoluciones_kam dev_k ON dev_k.kam = main.kam AND mes_comision_input = dev_k.fecha
    WHERE main.KAM NOT IN ('germanvargas@habi.co', 'coordinadoribuyerliquidez@habicredit.co', 'maryrodriguez@habicredit.co')
    GROUP BY 1,2,3
  )

  , cp_ejecutivo_comercial_hc_inmo_ciudades AS (

    SELECT 
      mes_comision_input AS mes_comision,
      'Ejecutivo Comercial Habicredit (Comercial Convenios inmobiliarios Ciudades)' AS posicion,
      'davidsolano@habicredit.co' AS beneficiado,
      SAFE_DIVIDE(SUM(aprobacion_dual), SUM(aprobacion_dual_meta)) AS aprobaciones_inmo_ciudades,
      SUM(radicacion_analista) AS radicaciones_inmo_ciudades,
      SUM(monto_solicitado_analista) AS radicaciones_inmo_ciudades_monto,
      SUM(monto_desembolso) AS monto_desembolsos_inmo_ciudades,
      CASE 
        WHEN mes_comision_input = DATE_SUB(DATE_TRUNC(CURRENT_DATE('-5'), MONTH), INTERVAL 1 MONTH)
        THEN 0.0
      END vinculaciones_inmo_ciudades
    FROM main
    WHERE correo_broker = 'davidsolano@habicredit.co'
  )

  , cp_ejecutivo_comercial_hc_inmo_ciudades_other AS (

    SELECT 
       mes_comision_input AS mes_comision,
      'Ejecutivo Comercial Habicredit (Comercial Convenios inmobiliarios Ciudades)' AS posicion,
      main.correo_broker AS beneficiado,
      SAFE_DIVIDE(SUM(aprobacion_dual), SUM(aprobacion_dual_meta)) AS aprobaciones_inmo_ciudades,
      SUM(radicacion_analista) AS radicaciones_inmo_ciudades,
      SUM(monto_solicitado_analista) AS radicaciones_inmo_ciudades_monto,
      MAX(dab.avg_dias_radicacion_aprobacion) AS dias_aprobacion,

    FROM main
    LEFT JOIN dias_aprobacion_broker dab ON dab.fecha_aprobacion =  mes_comision_input AND dab.correo_broker = main.correo_broker
    WHERE main.correo_broker IN ('javiercastelblanco@habicredit.co','nelsoncervera@habicredit.co')
    GROUP BY 1,2,3

  )


  , cp_analista_devoluciones AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Analista Devoluciones' AS posicion,
      'anacortes@habicredit.co' AS beneficiado,
      0.0 AS ops_devueltas
    FROM main
    GROUP BY 1,2,3

  )

  , cp_director_comercial_ibuyer AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Director ibuyer' AS posicion,
      correo_director_comercial AS beneficiado,
      SUM(monto_desembolso) AS monto_desembolso,
      SUM(radicacion_analista) AS radicacion_cib,  --Radicaciones totales
      SUM(monto_solicitado_analista) AS radicacion_monto_cib,
      SUM(radicacion) AS radicacion_cib_u,  -- Radicaciones únicas 
      MAX(AR_CI.attachment_rate) AS AR_CI, 
      MAX(AR_PCV.attachment_rate) AS AR_PCV, 
      SAFE_DIVIDE(SUM(aprobacion_dual), SUM(aprobacion_dual_meta)) AS aprobacion_dual,

    FROM main
    LEFT JOIN AR_CI ON AR_CI.mes = mes_comision_input
    LEFT JOIN AR_PCV ON AR_PCV.mes = mes_comision_input
    WHERE correo_director_comercial IN ('germanvargas@habi.co', 'coordinadoribuyerhabi@gmail.com', 'coordinadoribuyerliquidez@habicredit.co')
    GROUP BY 1,2,3

  )

  , cp_ejecutivo_comercial_ibuyer AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Ejecutivo ibuyer' AS posicion,
      correo_broker AS beneficiado,
      SUM(monto_desembolso) AS monto_desembolso,
      SUM(radicacion_analista) AS radicacion_cib, --Radicaciones totales
      SUM(monto_solicitado_analista) AS radicacion_monto_cib,
      SUM(radicacion)AS radicacion_cib_u,  -- Radicaciones únicas
      MAX(AR_CI.attachment_rate) AS AR_CI, 
      MAX(AR_PCV.attachment_rate) AS AR_PCV,
      MAX(adei.aprobacion_dual) aprobacion_dual,

    FROM main
    LEFT JOIN AR_CI ON AR_CI.mes = mes_comision_input
    LEFT JOIN AR_PCV ON AR_PCV.mes = mes_comision_input
    LEFT JOIN aprobacion_dual_ejecutivo_ibuyer adei ON adei.fecha = mes_comision_input AND adei.ejecutivo = main.correo_broker
    WHERE correo_broker IN ('yulianagarcia@habi.co', 'ladyparra@habicredit.co', 'glorialeon@habi.co', 'nidiasanchez@habicredit.co')
    GROUP BY 1,2,3
    
  )

  , cp_ejecutivo_colex AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Ejecutivo COLEX' AS posicion,
      analista_radicacion AS beneficiado,
      SUM(radicacion_colex) AS radicacion,
      SUM(monto_solicitado_analista) AS radicacion_monto,
      SAFE_DIVIDE(SUM(aprobacion_dual_colex), SUM(aprobacion_dual_meta_colex)) AS aprobacion_dual,
      SUM(monto_desembolso) AS monto_desembolso
    FROM main
    WHERE analista_radicacion = 'colex@habicredit.co'
    GROUP BY 1,2,3

  )

  ----- Cargo nuevo vigente desde 2026-08-01: "Analista de Radicacion Colex" (Lida Valentina Sanchez -----
  ----- Valero, lidasanchez@habicredit.co). Fuente: Esquemas/202608 Comisiones Habicredit COL.docx (1).pdf. -----
  ----- Se mide sobre las mismas operaciones COLEX que el Ejecutivo COLEX (el buzon colex@habicredit.co -----
  ----- es Johanna Alzate Varon y conserva su propia meta y su propia fila), pero su esquema cambia -----
  ----- monto_desembolso por dias de aprobacion/negacion (dias_sancion, meta 6 dias habiles). -----
  ----- Se usa la posicion 'Analista Radicación' porque sus bandas del esquema (0 / 30% / % directo con -----
  ----- techo 150%) son exactamente las que comisiones_internas_hc_final.sql ya aplica a ese cargo. -----
  ----- Antes de 2026-08-01 el cargo no existia, por eso el WHERE no genera filas para meses anteriores. -----
  , cp_analista_radicacion_colex AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Analista Radicación' AS posicion,
      'lidasanchez@habicredit.co' AS beneficiado,
      SUM(radicacion_colex) AS radicacion,
      SUM(monto_solicitado_analista) AS radicacion_monto,
      SAFE_DIVIDE(SUM(aprobacion_dual_colex), SUM(aprobacion_dual_meta_colex)) AS aprobacion_dual,
      MAX(dsa.avg_dias_radicacion_sancion) AS dias_sancion
    FROM main
    LEFT JOIN dias_sancion_analista dsa
      ON dsa.fecha_sancion = mes_comision_input AND dsa.analista_radicacion = main.analista_radicacion
    WHERE main.analista_radicacion = 'colex@habicredit.co'
      AND mes_comision_input >= '2026-08-01'
    GROUP BY 1,2,3

  )

  , cp_ejecutivo_cero_goles AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Ejecutivo Cero Goles' AS posicion,
      correo_del_ejecutivo_asignado AS beneficiado,

      SAFE_DIVIDE(
        SUM(IF(venta_viene_con_precio_de_lista = 'Si', cumplimiento , NULL)),
        COUNT(IF(venta_viene_con_precio_de_lista = 'Si', cumplimiento , NULL))
      ) AS tiempo_respuesta_precio_full,

      SAFE_DIVIDE(
        SUM(IF(venta_viene_con_precio_de_lista = 'No',cumplimiento, NULL)),
        COUNT(IF(venta_viene_con_precio_de_lista = 'No',cumplimiento, NULL))
      ) AS tiempo_respuesta_precio_no_full,
    
      MAX(AR_CI.attachment_rate) AS AR_CI,
      MAX(AR_E.attachment_rate) AS AR_E,
      
      CASE 
        WHEN mes_comision_input = '2026-04-01' THEN 7.0
        WHEN mes_comision_input = '2026-05-01' THEN 7.0
        WHEN mes_comision_input = '2026-06-01' THEN 7.0
      END AS negocios_convertidos_hc,

      CASE
        WHEN mes_comision_input = '2026-07-01' THEN 1176.0
        -- Desde 2026-08-01: se calcula en vivo con la misma logica de conteo que
        -- conversion_pre_legalizacion_director (bt_pre_legalizacion_bi_new dedup por report_id+ciclo),
        -- pero total sin agrupar por director. Julio queda quemado tal cual para no alterar lo ya pagado.
        WHEN mes_comision_input >= '2026-08-01' THEN MAX(cpt.conversion)
      END AS convertidos_pre_legalizacion,

    FROM `papyrus-delivery-data.habicredit.tiempo_ans_cero_goles` tacg
    LEFT JOIN AR_CI ON AR_CI.mes = mes_comision_input
    LEFT JOIN AR_E ON AR_E.mes = mes_comision_input
    LEFT JOIN conversion_pre_legalizacion_total cpt ON cpt.mes = mes_comision_input
    WHERE estado_laboral = 'Habil' AND DATE_TRUNC(created_at, MONTH) =  mes_comision_input
    GROUP BY 1,2,3

    ----- Respaldo SOLO para 2026-04 a 2026-06: en esos meses jefersonrincon@habicredit.co todavia no -----
    ----- tenia filas propias en tiempo_ans_cero_goles (solo estaba yeisonlopez@habicredit.co), y se -----
    ----- penso el esquema para que ambos comisionaran igual ese periodo. Desde 2026-07-01 el ya aparece -----
    ----- con su propia data en la rama de arriba (agrupada por correo_del_ejecutivo_asignado), asi que -----
    ----- esta rama debe apagarse ahi: de lo contrario mezcla su data real con la de quien mas aparezca -----
    ----- ese mes (paso justamente en julio 2026 con yeisonlopez@habicredit.co) y genera fila duplicada. -----
    UNION ALL

      SELECT
      mes_comision_input AS mes_comision,
      'Ejecutivo Cero Goles' AS posicion,
      'jefersonrincon@habicredit.co' AS beneficiado,
      SAFE_DIVIDE(
        SUM(IF(venta_viene_con_precio_de_lista = 'Si', cumplimiento , NULL)),
        COUNT(IF(venta_viene_con_precio_de_lista = 'Si', cumplimiento , NULL))
      ) AS tiempo_respuesta_precio_full,

      SAFE_DIVIDE(
        SUM(IF(venta_viene_con_precio_de_lista = 'No',cumplimiento, NULL)),
        COUNT(IF(venta_viene_con_precio_de_lista = 'No',cumplimiento, NULL))
      ) AS tiempo_respuesta_precio_no_full,

      MAX(AR_CI.attachment_rate) AS AR_CI,
      MAX(AR_E.attachment_rate) AS AR_E,
      CASE
        WHEN mes_comision_input = '2026-04-01' THEN 7.0
        WHEN mes_comision_input = '2026-05-01' THEN 7.0
        WHEN mes_comision_input = '2026-06-01' THEN 7.0

      END AS negocios_convertidos_hc,

      CASE
        WHEN mes_comision_input = '2026-07-01' THEN 1176.0
      END AS convertidos_pre_legalizacion,

    FROM `papyrus-delivery-data.habicredit.tiempo_ans_cero_goles` tacg
    LEFT JOIN AR_CI ON AR_CI.mes = mes_comision_input
    LEFT JOIN AR_E ON AR_E.mes = mes_comision_input
    WHERE estado_laboral = 'Habil' AND DATE_TRUNC(created_at, MONTH) =  mes_comision_input
      AND mes_comision_input < '2026-07-01'
    GROUP BY 1,2,3

  )

  , cp_supervisor_radicacion AS (
    
    SELECT

      mes_comision_input AS mes_comision,
      'Supervisor Radicación' AS posicion,
      'oscaramezquita@habi.co' AS beneficiado, 

      CASE 
        WHEN mes_comision_input < '2026-07-01'
        THEN MAX(da.avg_dias_radicacion_aprobacion)
      END AS dias_aprobacion,
      
      CASE 
        WHEN mes_comision_input >= '2026-07-01'
        THEN MAX(ds.avg_dias_radicacion_sancion)
      END AS dias_sancion,



      SUM(radicacion_analista) AS radicacion,
      SUM(monto_solicitado_analista) AS radicacion_monto,
      MAX(rc.salvados) AS reproceso_creditos,
      MAX(rc.monto_aprobado) AS reproceso_creditos_monto

    FROM main
    LEFT JOIN dias_aprobacion_supervisor da ON da.fecha_aprobacion = mes_comision_input
    LEFT JOIN dias_sancion_supervisor ds ON ds.fecha_sancion = mes_comision_input
    LEFT JOIN reproceso_creditos_total rc on rc.mes_salvado = mes_comision_input
    GROUP BY 1,2,3

  )

  , cp_analista_radicacion AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Analista Radicación' AS posicion,
      main.analista_radicacion AS beneficiado,
      CASE 
        WHEN mes_comision_input < '2026-07-01'
        THEN MAX(daa.avg_dias_radicacion_aprobacion) 
      END AS dias_aprobacion,

      CASE 
        WHEN mes_comision_input >= '2026-07-01'
        THEN MAX(dsa.avg_dias_radicacion_sancion) 
      END AS dias_sancion,

      SUM(radicacion_analista) AS radicacion,
      SUM(monto_solicitado_analista) AS radicacion_monto,
      MAX(rc.salvados) AS reproceso_creditos,
      MAX(rc.monto_aprobado) AS reproceso_creditos_monto,

    FROM main
    LEFT JOIN dias_aprobacion_analista daa ON daa.fecha_aprobacion = mes_comision_input AND daa.analista_radicacion = main.analista_radicacion
    LEFT JOIN dias_sancion_analista dsa ON dsa.fecha_sancion = mes_comision_input AND dsa.analista_radicacion = main.analista_radicacion
    LEFT JOIN reproceso_creditos rc ON rc.mes_salvado = mes_comision_input AND rc.analista_negados = main.analista_radicacion
    WHERE main.analista_radicacion NOT IN ('ingridrada@habicredit.co', 'colex@habicredit.co')
    GROUP BY 1,2,3
  )

  , cp_analista_radicacion_ibuyer AS (

    SELECT
      DATE(mes_comision) AS mes_comision,
      'Analista Radicación' AS posicion,
      'ginadiaz@habicredit.co' AS beneficiado,
      COUNT(report_id) AS negocios_pre_legalizados
    
    FROM pre_legalizacion_radicador_ibuyer
    GROUP BY 1, 2, 3
  )

  , cp_analista_radicacion_vinculacion_itau AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Analista Radicación' AS posicion,
      'hallersonescobar@habicredit.co' AS beneficiado,
          CASE 
        WHEN mes_comision_input = '2026-04-01' THEN 23
        WHEN mes_comision_input = '2026-05-01' THEN 19
        WHEN mes_comision_input = '2026-06-01' THEN 24
        WHEN mes_comision_input = '2026-07-01' THEN 23

      END AS vinculacion_itau,
      CASE 
        WHEN mes_comision_input = '2026-04-01' THEN 7697800000
        WHEN mes_comision_input = '2026-05-01' THEN 8479000000
        WHEN mes_comision_input = '2026-06-01' THEN 8438992000
        WHEN mes_comision_input = '2026-07-01' THEN 9251021677

      END AS vinculacion_itau_monto,

  )

  , cp_analista_filtros_estados AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Analista de filtros (Estados)' AS posicion,
      'emilianodiaz@habicredit.co' AS beneficiado,
      1.0 AS filtros_enviados_banco,
      MAX(p_cumplimiento_ans_3d) AS actualizacion_estado,
    FROM ans_anlista_estados
    WHERE mes_comision_input = mes_estados
    GROUP BY 1,2,3

    UNION ALL

    SELECT
      mes_comision_input AS mes_comision,
      'Analista de filtros (Estados)' AS posicion,
      'luishueso@habicredit.co' AS beneficiado,
      0.0 AS filtros_enviados_banco, -- Luis Hueso no cuenta con este indicador
      MAX(p_cumplimiento_ans_3d) AS actualizacion_estado,
    FROM ans_anlista_estados 
    WHERE mes_comision_input = mes_estados
    GROUP BY 1,2,3
  )

  , cp_supervisor_legalizacion AS (

    WITH adriana_supervisor_ordenes_firmas AS (
      SELECT
        mes_comision_input AS fecha,
        SUM(firma_ordenes_ofertas_escrituras) AS firma_ordenes_ofertas_escrituras,
      FROM ordenes_firmas
      CROSS JOIN listas_supervisores_analistas AS lc
      WHERE fecha = mes_comision_input
      AND analista IN UNNEST(analistas_sup_adriana)
      GROUP BY 1
    )

    , oscar_supervisor_ordenes_firmas AS (
      SELECT
        mes_comision_input AS fecha,
        SUM(firma_ordenes_ofertas_escrituras) AS firma_ordenes_ofertas_escrituras,
      FROM ordenes_firmas
      CROSS JOIN listas_supervisores_analistas AS lc
      WHERE fecha = mes_comision_input
      AND analista IN UNNEST(analistas_sup_oscar)
      GROUP BY 1
    )

    , tom_supervisor_ordenes_firmas AS (
      SELECT
        mes_comision_input AS fecha,
        SUM(firma_ordenes_ofertas_escrituras) AS firma_ordenes_ofertas_escrituras,
      FROM ordenes_firmas
      CROSS JOIN listas_supervisores_analistas AS lc
      WHERE fecha = mes_comision_input
      AND analista IN UNNEST(analistas_sup_tom)
      GROUP BY 1
    )

    , yeison_supervisor_ordenes_firmas AS (
      SELECT
        mes_comision_input AS fecha,
        SUM(firma_ordenes_ofertas_escrituras) AS firma_ordenes_ofertas_escrituras,
      FROM ordenes_firmas
      CROSS JOIN listas_supervisores_analistas AS lc
      WHERE fecha = mes_comision_input
      AND analista IN UNNEST(analistas_sup_yeison)
      GROUP BY 1
    )

      , adriana_gestion_ANS_FM AS (
      SELECT
        mes_comision_input AS fecha_sync,
        AVG(cumplimiento_ans) AS cumplimiento_ans,
      FROM gestion_ANS_FM
      CROSS JOIN listas_supervisores_analistas AS lc
      WHERE fecha_sync = mes_comision_input
      AND asignacion_analista IN UNNEST(analistas_sup_adriana)
      GROUP BY 1
    )

    , oscar_gestion_ANS_FM AS (
      SELECT
        mes_comision_input AS fecha_sync,
        AVG(cumplimiento_ans) AS cumplimiento_ans,
      FROM gestion_ANS_FM
      CROSS JOIN listas_supervisores_analistas AS lc
      WHERE fecha_sync = mes_comision_input
      AND asignacion_analista IN UNNEST(analistas_sup_oscar)
      GROUP BY 1
    )

      , tom_gestion_ANS_FM AS (
      SELECT
        mes_comision_input AS fecha_sync,
        AVG(cumplimiento_ans) AS cumplimiento_ans,
      FROM gestion_ANS_FM
      CROSS JOIN listas_supervisores_analistas AS lc
      WHERE fecha_sync = mes_comision_input
      AND asignacion_analista IN UNNEST(analistas_sup_tom)
      GROUP BY 1
    )

      , yeison_gestion_ANS_FM AS (
      SELECT
        mes_comision_input AS fecha_sync,
        AVG(cumplimiento_ans) AS cumplimiento_ans,
      FROM gestion_ANS_FM
      CROSS JOIN listas_supervisores_analistas AS lc
      WHERE fecha_sync = mes_comision_input
      AND asignacion_analista IN UNNEST(analistas_sup_yeison)
      GROUP BY 1
    )

    SELECT
      mes_comision_input AS mes_comision,
      'Supervisor Legalización' AS posicion,
      'adrianaflorido@habi.co' AS beneficiado,    
      SUM(monto_desembolso) AS monto_desembolso,
      SUM(desembolsos) AS cantidad_desembolsos,
      MAX(firma_ordenes_ofertas_escrituras) AS firma_ordenes_ofertas_escrituras,
      AVG(IFNULL(cumplimiento_ans, 0)) AS cumplimiento_ans,
      MAX(cumplimiento_gestion_rotacion) AS cumplimiento_gestion_rotacion,
      MAX(p_ejecucion_comentarios) AS cantidad_calidad_comentarios

    FROM main
    LEFT JOIN adriana_supervisor_ordenes_firmas ON adriana_supervisor_ordenes_firmas.fecha = mes_comision_input 
    LEFT JOIN adriana_gestion_ANS_FM ans ON ans.fecha_sync = mes_comision_input
    LEFT JOIN cumplimiento_rotacion_adriana cr ON cr.mes = mes_comision_input
    LEFT JOIN score_calidad_comentarios_supervisor_adriana sccs ON sccs.fecha = mes_comision_input
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE analista_legalizacion IN UNNEST(analistas_sup_adriana)
    GROUP BY 1,2,3

    UNION ALL 

    SELECT
      mes_comision_input AS mes_comision,
      'Supervisor Legalización' AS posicion,
      'oscaramezquita@habi.co' AS beneficiado,
      SUM(monto_desembolso) AS monto_desembolso,
      SUM(desembolsos) AS cantidad_desembolsos,
      MAX(firma_ordenes_ofertas_escrituras) AS firma_ordenes_ofertas_escrituras,
      AVG(IFNULL(cumplimiento_ans, 0)) AS cumplimiento_ans,
      MAX(cumplimiento_gestion_rotacion) AS cumplimiento_gestion_rotacion,
      MAX(p_ejecucion_comentarios) AS cantidad_calidad_comentarios

    FROM main 
    LEFT JOIN oscar_supervisor_ordenes_firmas ON oscar_supervisor_ordenes_firmas.fecha = mes_comision_input
    LEFT JOIN oscar_gestion_ANS_FM ans ON ans.fecha_sync = mes_comision_input
    LEFT JOIN cumplimiento_rotacion_oscar cr ON cr.mes = mes_comision_input
    LEFT JOIN score_calidad_comentarios_supervisor_oscar sccs ON sccs.fecha = mes_comision_input
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE analista_legalizacion IN UNNEST(analistas_sup_oscar)
    GROUP BY 1,2,3

      UNION ALL 

    SELECT
      mes_comision_input AS mes_comision,
      'Supervisor Legalización' AS posicion,
      'edilbertobotia@habi.co' AS beneficiado,
      SUM(monto_desembolso) AS monto_desembolso,
      SUM(desembolsos) AS cantidad_desembolsos,
      MAX(firma_ordenes_ofertas_escrituras) AS firma_ordenes_ofertas_escrituras,
      AVG(IFNULL(cumplimiento_ans, 0)) AS cumplimiento_ans,
      MAX(cumplimiento_gestion_rotacion) AS cumplimiento_gestion_rotacion,
      MAX(p_ejecucion_comentarios) AS cantidad_calidad_comentarios


    FROM main 
    LEFT JOIN tom_supervisor_ordenes_firmas ON tom_supervisor_ordenes_firmas.fecha = mes_comision_input
    LEFT JOIN tom_gestion_ANS_FM ans ON ans.fecha_sync = mes_comision_input
    LEFT JOIN cumplimiento_rotacion_tom cr ON cr.mes = mes_comision_input
    LEFT JOIN score_calidad_comentarios_supervisor_tom sccs ON sccs.fecha = mes_comision_input
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE analista_legalizacion IN UNNEST(analistas_sup_tom)
    GROUP BY 1,2,3

    UNION ALL 

    SELECT
      mes_comision_input AS mes_comision,
      'Supervisor Legalización' AS posicion,
      'yeisonlopez@habicredit.co' AS beneficiado,
      SUM(monto_desembolso) AS monto_desembolso,
      SUM(desembolsos) AS cantidad_desembolsos,
      MAX(firma_ordenes_ofertas_escrituras) AS firma_ordenes_ofertas_escrituras,
      AVG(IFNULL(cumplimiento_ans, 0)) AS cumplimiento_ans,
      MAX(cumplimiento_gestion_rotacion) AS cumplimiento_gestion_rotacion,
      MAX(p_ejecucion_comentarios) AS cantidad_calidad_comentarios


    FROM main 
    LEFT JOIN yeison_supervisor_ordenes_firmas ON yeison_supervisor_ordenes_firmas.fecha = mes_comision_input
    LEFT JOIN yeison_gestion_ANS_FM ans ON ans.fecha_sync = mes_comision_input
    LEFT JOIN cumplimiento_rotacion_yeison cr ON cr.mes = mes_comision_input
    LEFT JOIN score_calidad_comentarios_supervisor_yeison sccs ON sccs.fecha = mes_comision_input
    CROSS JOIN listas_supervisores_analistas AS lc
    WHERE analista_legalizacion IN UNNEST(analistas_sup_yeison)
    GROUP BY 1,2,3

  )

  , cp_analista_legalizacion AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Analista Legalización' AS posicion,
      main.analista_legalizacion AS beneficiado,
      SUM(desembolsos) AS desembolsos,
      SUM(monto_desembolso) AS monto_desembolso_leg,
      MAX(firma_ordenes_ofertas_escrituras) AS firma_ordenes_ofertas_escrituras,
      MAX(IFNULL(ans.cumplimiento_ans, 0)) AS cumplimiento_ans,
      MAX(IFNULL(cra.cumplimiento_ponderado_mensual, 0)) AS cumplimiento_rotacion,
      MAX(SC.p_ejecucion_B) AS cantidad_calidad_comentarios_analista,
      

    FROM main
    LEFT JOIN ordenes_firmas ON ordenes_firmas.fecha = mes_comision_input AND main.analista_legalizacion  = ordenes_firmas.analista
    LEFT JOIN gestion_ANS_FM ans ON ans.fecha_sync = mes_comision_input AND main.analista_legalizacion = ans.asignacion_analista
    LEFT JOIN cumplimiento_rotacion_analistas cra ON cra.mes = mes_comision_input AND main.analista_legalizacion = cra.correo_analista
    LEFT JOIN score_calidad_comentarios_analista sc ON sc.fecha = mes_comision_input AND main.analista_legalizacion = sc.email
    WHERE main.analista_legalizacion NOT IN ('oscaramezquita@habi.co', 'adrianaflorido@habi.co', 'edilbertobotia@habi.co')
    GROUP BY 1,2,3
  )


  , cp_gerente_ops_liquidez AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Gerente Ops Liquidez' AS posicion,
      'alejandranaranjo@habi.co' AS beneficiado,

      ----- Esquema vigente hasta 2026-07-01: comisiona sobre desembolsos, ANS y rotacion -----
      CASE WHEN mes_comision_input < '2026-08-01' THEN SUM(main.monto_desembolso) END AS monto_desembolso,
      CASE WHEN mes_comision_input < '2026-08-01' THEN SUM(desembolsos) END AS cantidad_desembolsos,
      CASE WHEN mes_comision_input < '2026-08-01' THEN MAX(d.monto_desembolso) END AS monto_desembolso_ibuyer,
      CASE WHEN mes_comision_input < '2026-08-01' THEN MAX(IFNULL(cpl.cumplimiento_ans, 0)) END AS cumplimiento_ans,
      CASE WHEN mes_comision_input < '2026-08-01' THEN MAX(AR_CI.attachment_rate) END AS AR_CI,
      CASE WHEN mes_comision_input < '2026-08-01' THEN MAX(radicacion_coord) END AS radicaciones_ibuyer,
      CASE WHEN mes_comision_input < '2026-08-01' THEN MAX(cumplimiento_gestion_rotacion) END AS cumplimiento_gestion_rotacion,

      ----- Reasignacion vigente desde 2026-08-01: pasa a comisionar por radicacion, mesa de -----
      ----- salvamento y dias de aprobacion/negacion, igual que Supervisor Radicacion (mismas metas). -----
      ----- Fuente: Esquemas/202608 Comisiones Habicredit COL.docx (1).pdf, seccion "Gerente de Ops Liquidez". -----
      CASE WHEN mes_comision_input >= '2026-08-01' THEN MAX(ds.avg_dias_radicacion_sancion) END AS dias_sancion,
      CASE WHEN mes_comision_input >= '2026-08-01' THEN SUM(radicacion_analista) END AS radicacion,
      CASE WHEN mes_comision_input >= '2026-08-01' THEN SUM(monto_solicitado_analista) END AS radicacion_monto,
      CASE WHEN mes_comision_input >= '2026-08-01' THEN MAX(rc.salvados) END AS reproceso_creditos,
      CASE WHEN mes_comision_input >= '2026-08-01' THEN MAX(rc.monto_aprobado) END AS reproceso_creditos_monto,

    FROM main
    LEFT JOIN gestion_ANS_FM_gerente ans ON ans.fecha_sync = mes_comision_input
    LEFT JOIN AR_CI ON AR_CI.mes = mes_comision_input
    LEFT JOIN desembolsos_legalizacion_no_habicredit d ON mes_comision_input = d.fecha_desembolso
    LEFT JOIN (
      SELECT
        mes_comision, AVG(cumplimiento_ans) cumplimiento_ANS
      FROM cp_supervisor_legalizacion
      GROUP BY 1
    ) cpl ON mes_comision_input = cpl.mes_comision
    LEFT JOIN radicaciones_coordinador_ibuyer rci ON rci.mes_comision = mes_comision_input
    LEFT JOIN cumplimiento_rotacion_gerente cr ON cr.mes = mes_comision_input
    LEFT JOIN dias_sancion_supervisor ds ON ds.fecha_sancion = mes_comision_input
    LEFT JOIN reproceso_creditos_total rc ON rc.mes_salvado = mes_comision_input
    GROUP BY 1,2,3

  )

  , cp_supervisor_pre_legalizacion AS (

    ----- Hasta 2026-02-01: Edilberto Botia, medido con la gestion de bolsa. Se conserva tal cual -----
    ----- para no alterar meses ya pagados. El cargo quedo inactivo entre 2026-03-01 y 2026-07-01. -----
    SELECT
      mes_comision_input AS mes_comision,
      'Supervisor Pre Legalización' AS posicion,
      'edilbertobotia@habi.co' AS beneficiado,
      0.0 AS creditos_convertidos,
      MAX(inicio_bolsa) AS inicio_bolsa,
      MAX(tiempo_habil_pendientes_de_asignar) AS tiempo_respuesta_pre_legalizacion,
      CAST(NULL AS FLOAT64) AS convertidos_pre_legalizacion

    FROM inicio_bolsa_supervisor ibs
    LEFT JOIN tiempo_respuesta_buzon_supervisor rb ON rb.fecha = mes_comision_input
    WHERE ibs.fecha = mes_comision_input
      AND mes_comision_input < '2026-03-01'
    GROUP BY 1,2,3

    UNION ALL

    ----- Desde 2026-08-01: Mary Gineth Rodriguez (maryrodriguez@habicredit.co) reactiva el cargo. -----
    ----- Su unico indicador en el esquema de agosto es convertidos_pre_legalizacion (meta 950), con -----
    ----- la misma logica de conteo que conversion_pre_legalizacion_director pero total, sin agrupar -----
    ----- por director. -----
    ----- OJO: esta rama NO se cuelga de inicio_bolsa_supervisor a proposito. Esa CTE depende de -----
    ----- pipe_bolsa.entrada_gestion, que dejo de alimentarse en marzo 2026 (justo cuando el cargo -----
    ----- desaparecio); si dependiera de ella no se generaria ninguna fila. inicio_bolsa y -----
    ----- tiempo_respuesta_pre_legalizacion quedan en NULL porque Mary no tiene meta de esos dos. -----
    SELECT
      mes_comision_input AS mes_comision,
      'Supervisor Pre Legalización' AS posicion,
      'maryrodriguez@habicredit.co' AS beneficiado,
      CAST(NULL AS FLOAT64) AS creditos_convertidos,
      CAST(NULL AS FLOAT64) AS inicio_bolsa,
      CAST(NULL AS FLOAT64) AS tiempo_respuesta_pre_legalizacion,
      MAX(cpt.conversion) AS convertidos_pre_legalizacion

    FROM conversion_pre_legalizacion_total cpt
    WHERE cpt.mes = mes_comision_input
      AND mes_comision_input >= '2026-08-01'
    GROUP BY 1,2,3

  )

  , cp_analista_pre_legalizacion AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Analista Pre Legalización' AS posicion,
      iba.analista_pre_legalizacion AS beneficiado,
      CASE
        --WHEN iba.analista_pre_legalizacion = 'yessicabarrera@habicredit.co' THEN 0.0
        --WHEN iba.analista_pre_legalizacion = 'angelicaavellaneda@habi.co' THEN 0.0
        --WHEN iba.analista_pre_legalizacion = 'claudiapardo@habicredit.co' THEN 0.0
        --WHEN iba.analista_pre_legalizacion = 'johannacardenas@habicredit.co' THEN 0.0
        WHEN iba.analista_pre_legalizacion = 'jeydirodriguez@habicredit.co' THEN 0.0 
        WHEN iba.analista_pre_legalizacion = 'lauraariza@habi.co' THEN 0.0
      END AS creditos_convertidos,
      MAX(inicio_bolsa) AS inicio_bolsa,
      MAX(tiempo_habil_pendientes_de_asignar) AS tiempo_respuesta_pre_legalizacion

    FROM inicio_bolsa_analista iba
    LEFT JOIN tiempo_respuesta_buzon_analista rb ON rb.fecha = mes_comision_input AND iba.analista_pre_legalizacion = rb.analista_pre_legalizacion
    WHERE iba.fecha = mes_comision_input
    GROUP BY 1,2,3

  )


  , cp_analista_legalizacion_recaudo AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Analista de Legalización (Recaudo)' AS posicion,
      'jeydirodriguez@habicredit.co' AS beneficiado,
      CASE
        WHEN mes_comision_input = '2026-04-01' THEN 162.0
        WHEN mes_comision_input = '2026-05-01' THEN 271.0
        WHEN mes_comision_input = '2026-06-01' THEN 214.0
        WHEN mes_comision_input = '2026-07-01' THEN 266.0
        WHEN mes_comision_input = '2026-08-01' THEN 36.0
      END AS recaudo_garantias,

      CASE
        WHEN mes_comision_input = '2026-04-01' THEN 0.0
        WHEN mes_comision_input = '2026-05-01' THEN 0.0
        WHEN mes_comision_input = '2026-06-01' THEN 0.47
        WHEN mes_comision_input = '2026-07-01' THEN 0.73
        WHEN mes_comision_input = '2026-08-01' THEN 0.0

      END AS tiempo_recaudo_garantias,
      
    UNION ALL

      SELECT
      mes_comision_input AS mes_comision,
      'Analista de Legalización (Recaudo)' AS posicion,
      'nohoravarela@habicredit.co' AS beneficiado,
      CASE 
        WHEN mes_comision_input = '2026-04-01' THEN 246.0
        WHEN mes_comision_input = '2026-05-01' THEN 251.0
        WHEN mes_comision_input = '2026-06-01' THEN 218.0
      END AS recaudo_garantias,
      
      CASE 
        WHEN mes_comision_input = '2026-04-01' THEN 0.0
        WHEN mes_comision_input = '2026-05-01' THEN 0.0
        WHEN mes_comision_input = '2026-06-01' THEN 0.94


      END AS tiempo_recaudo_garantias,

  )

  , cp_supervisor_legalizacion_no_HC AS (

    SELECT
    DISTINCT 
      mes_comision_input AS mes_comision,
      'Supervisor Legalización no Habicredit' AS posicion,
      'alejandralaverde@habi.co' AS beneficiado,
      SUM(ode_s.ordenes_escrituracion_ibuyer)AS ordenes_escrituracion_ibuyer,
      -- MAX(ais.ans_ibuyer) AS ans_ibuyer,
      .0 AS ans_ibuyer,
      SUM(ode24_s.ordenes_escrituracion_ibuyer)AS ordenes_escrituracion_ibuyer_24,
      MAX(d.monto_desembolso) AS monto_desembolso_ibuyer,
      MAX(castigo_monto) AS castigo_monto_supervisor

    FROM ode_mes_supervisor ode_s
    LEFT JOIN ode_24_supervisor ode24_s ON ode_s.fecha = ode24_s.fecha
    LEFT JOIN ans_ibuyer_supervisor ais ON ode_s.fecha = ais.mes_comision
    LEFT JOIN castigo_monto_desembolso_ibuyer_supervisor cs ON ode_s.fecha = cs.fecha 
    LEFT JOIN desembolsos_legalizacion_no_habicredit d ON ode_s.fecha = d.fecha_desembolso
    WHERE ode_s.fecha = mes_comision_input
    GROUP BY 1,2,3

  )

  , cp_analista_legalizacion_no_HC AS (

    SELECT
    DISTINCT 
      mes_comision_input AS mes_comision,
      'Analista Legalización no Habicredit' AS posicion,
      ode_a.analista_leg_ibuyer AS beneficiado,
      SUM(ode_a.ordenes_escrituracion_ibuyer) AS ordenes_escrituracion_ibuyer,
      -- MAX(aia.ans_ibuyer) AS ans_ibuyer,
      CASE
        WHEN ode_a.analista_leg_ibuyer = 'laurabeltran@habi.co' THEN .120
        WHEN ode_a.analista_leg_ibuyer = 'leidyvargas@habi.co' THEN .120
        WHEN ode_a.analista_leg_ibuyer = 'nicolfonseca@habi.co' THEN .120
        WHEN ode_a.analista_leg_ibuyer = 'oscarsaenz@habicredit.co' THEN .120
      END AS ans_ibuyer,
      SUM(ode24_a.ordenes_escrituracion_ibuyer)AS ordenes_escrituracion_ibuyer_24,
      MAX(da.monto_desembolso) AS monto_desembolso_ibuyer,
      MAX(castigo_monto) AS castigo_monto_analista

    FROM ode_mes_analista ode_a
    LEFT JOIN ode_24_analista ode24_a ON ode_a.fecha = ode24_a.fecha AND ode24_a.analista_leg_ibuyer = ode_a.analista_leg_ibuyer
    LEFT JOIN ans_ibuyer_analista aia ON ode_a.fecha = aia.mes_comision AND aia.analista_leg_ibuyer = ode_a.analista_leg_ibuyer
    LEFT JOIN castigo_monto_desembolso_ibuyer_analista cs ON ode_a.fecha = cs.fecha AND cs.analista_legalizacion = ode_a.analista_leg_ibuyer
      LEFT JOIN desembolsos_legalizacion_no_habicredit_analistas da ON ode_a.fecha = da.fecha_desembolso AND  da.correo_analista_desembolsos = ode_a.analista_leg_ibuyer

    WHERE ode_a.fecha = mes_comision_input
    GROUP BY 1,2,3

  )

  , cp_analista_legalizacion_ops_ibuyer_abogada AS (

    SELECT
      mes_comision_input AS mes_comision,
      'Analista Legalización Operacaciones iBuyer (Abogada)' AS posicion,
      asignacion_abogados_legalizacion_ibuyer AS beneficiado,
      SAFE_DIVIDE((COUNT(DISTINCT IF(l.tiempo_habil_revision_inicial <= 3, l.card_id, NULL))),(COUNT(DISTINCT l.card_id))) AS estudio_titulos,
      SAFE_DIVIDE((COUNT(DISTINCT i.card_id)) - COUNT(DISTINCT IF(fase_solicitante_de_las_inconsistencias != 'Revisión inicial', i.card_id, NULL)), (COUNT(DISTINCT i.card_id))) AS estudio_titulos_sin_devolucion,
    FROM papyrus-delivery-data.mudate_data.pipe_ibuyer2_all i
    LEFT JOIN papyrus-delivery-data.habicredit.legalizacion_ibuyer_2_co l on i.card_id = l.card_id
    WHERE  DATE_TRUNC(salida_revision_inicial, MONTH) = mes_comision_input
    GROUP BY 1,2,3
  )

  , condensado AS (

  SELECT * FROM cp_gerente_comercial
  UNPIVOT (
    ejecucion FOR indicador IN (monto_desembolso, radicacion, radicacion_monto, aprobacion_dual, nuevos_brokers)
  )

  UNION ALL
  SELECT * FROM cp_director_comercial_non_ibuyer
  UNPIVOT (
    ejecucion FOR indicador IN (monto_desembolso, radicacion, radicacion_monto, aprobacion_dual, nuevos_brokers, conversion_pre_leg_director)
  )

  UNION ALL
  SELECT * FROM graduaciones
  UNPIVOT (
    ejecucion FOR indicador IN (radicaciones_categoria)
  )

  UNION ALL
  SELECT * FROM cp_kam
  UNPIVOT (
    ejecucion FOR indicador IN (aprobacion_dual, reprocesos_kam, aprobaciones_kam, reprocesos_monto, calidad_kam, calidad_dev_pre_legalizacion, dev_banco_broker, dev_docs_habi)
  )

  UNION ALL
  SELECT * FROM cp_ejecutivo_comercial_hc_inmo_ciudades
  UNPIVOT (
    ejecucion FOR indicador IN (aprobaciones_inmo_ciudades, radicaciones_inmo_ciudades, radicaciones_inmo_ciudades_monto, monto_desembolsos_inmo_ciudades, vinculaciones_inmo_ciudades)
  )
  
  UNION ALL
  SELECT * FROM cp_ejecutivo_comercial_hc_inmo_ciudades_other
  UNPIVOT (
    ejecucion FOR indicador IN (aprobaciones_inmo_ciudades, radicaciones_inmo_ciudades, radicaciones_inmo_ciudades_monto, dias_aprobacion)
  )

  UNION ALL
  SELECT * FROM cp_analista_devoluciones
  UNPIVOT (
    ejecucion FOR indicador IN (ops_devueltas)
  )

  UNION ALL
  SELECT * FROM cp_director_comercial_ibuyer
  UNPIVOT (
    ejecucion FOR indicador IN (monto_desembolso, radicacion_cib, radicacion_monto_cib, radicacion_cib_u, AR_CI, AR_PCV, aprobacion_dual)
  )
  UNION ALL
  SELECT * FROM cp_director_graduaciones
  UNPIVOT (
    ejecucion FOR indicador IN (devolucion_broker_formados, radicaciones_brokers_activos, nps_director_devoluciones, graduaciones)
  )

  UNION ALL
  SELECT * FROM cp_ejecutivo_comercial_ibuyer
  UNPIVOT (
    ejecucion FOR indicador IN (monto_desembolso, radicacion_cib, radicacion_monto_cib, radicacion_cib_u, AR_CI, AR_PCV, aprobacion_dual)
  )

  UNION ALL
  SELECT * FROM cp_ejecutivo_colex
  UNPIVOT (
    ejecucion FOR indicador IN (radicacion, aprobacion_dual, radicacion_monto, monto_desembolso)
  )

  UNION ALL
  SELECT * FROM cp_analista_radicacion_colex
  UNPIVOT (
    ejecucion FOR indicador IN (radicacion, aprobacion_dual, radicacion_monto, dias_sancion)
  )

  UNION ALL
  SELECT * FROM cp_ejecutivo_cero_goles
  UNPIVOT (
    ejecucion FOR indicador IN (tiempo_respuesta_precio_full, tiempo_respuesta_precio_no_full, AR_CI, AR_E, negocios_convertidos_hc, convertidos_pre_legalizacion)
  )

  UNION ALL
  SELECT * FROM cp_gerente_ops_liquidez
  UNPIVOT (
    ejecucion FOR indicador IN (monto_desembolso, monto_desembolso_ibuyer, cumplimiento_ans, AR_CI, cantidad_desembolsos, radicaciones_ibuyer, cumplimiento_gestion_rotacion, dias_sancion, radicacion, radicacion_monto, reproceso_creditos, reproceso_creditos_monto)
  )

  UNION ALL
  SELECT * FROM cp_supervisor_radicacion
  UNPIVOT (
    ejecucion FOR indicador IN (dias_aprobacion, dias_sancion, radicacion, radicacion_monto, reproceso_creditos, reproceso_creditos_monto)
  )

  UNION ALL
  SELECT * FROM cp_analista_radicacion
  UNPIVOT (
    ejecucion FOR indicador IN (dias_aprobacion, dias_sancion, radicacion, radicacion_monto, reproceso_creditos, reproceso_creditos_monto)
  )

  UNION ALL
  SELECT * FROM cp_analista_radicacion_ibuyer
  UNPIVOT (
    ejecucion FOR indicador IN (negocios_pre_legalizados)
  )

  UNION ALL
  SELECT * FROM cp_analista_filtros_estados
  UNPIVOT (
    ejecucion FOR indicador IN (filtros_enviados_banco, actualizacion_estado)
  )

  UNION ALL
  SELECT * FROM cp_supervisor_legalizacion
  UNPIVOT (
    ejecucion FOR indicador IN (monto_desembolso, firma_ordenes_ofertas_escrituras, cumplimiento_ans, cantidad_desembolsos, cumplimiento_gestion_rotacion, cantidad_calidad_comentarios)
  )

  UNION ALL
  SELECT * FROM cp_analista_legalizacion
  UNPIVOT (
    ejecucion FOR indicador IN (desembolsos, monto_desembolso_leg, firma_ordenes_ofertas_escrituras, cumplimiento_ans, cumplimiento_rotacion, cantidad_calidad_comentarios_analista)
  )

  UNION ALL
  SELECT * FROM cp_supervisor_pre_legalizacion
  UNPIVOT (
    ejecucion FOR indicador IN (creditos_convertidos, inicio_bolsa, tiempo_respuesta_pre_legalizacion, convertidos_pre_legalizacion)
  )

  UNION ALL
  SELECT * FROM cp_analista_pre_legalizacion
  UNPIVOT (
    ejecucion FOR indicador IN (creditos_convertidos, inicio_bolsa, tiempo_respuesta_pre_legalizacion)
  )

  UNION ALL
  SELECT * FROM cp_analista_legalizacion_recaudo
  UNPIVOT (
    ejecucion FOR indicador IN (recaudo_garantias, tiempo_recaudo_garantias)
  )

  UNION ALL
  SELECT * FROM cp_analista_radicacion_vinculacion_itau
  UNPIVOT (
    ejecucion FOR indicador IN (vinculacion_itau, vinculacion_itau_monto)
  )

  /* A partir de 2026 el equipo deja de ser parte de Habicredit

  UNION ALL
  SELECT * FROM cp_supervisor_legalizacion_no_HC
  UNPIVOT (
    ejecucion FOR indicador IN (ordenes_escrituracion_ibuyer, ans_ibuyer, ordenes_escrituracion_ibuyer_24, monto_desembolso_ibuyer, castigo_monto_supervisor)
  )

  UNION ALL
  SELECT * FROM cp_analista_legalizacion_no_HC
  UNPIVOT (
    ejecucion FOR indicador IN (ordenes_escrituracion_ibuyer, ans_ibuyer, ordenes_escrituracion_ibuyer_24, monto_desembolso_ibuyer, castigo_monto_analista)
  )
    
  UNION ALL
  SELECT * FROM cp_analista_legalizacion_ops_ibuyer_abogada
  UNPIVOT (
    ejecucion FOR indicador IN (estudio_titulos, estudio_titulos_sin_devolucion)
  )
  */

  )
  SELECT * FROM condensado;

END;