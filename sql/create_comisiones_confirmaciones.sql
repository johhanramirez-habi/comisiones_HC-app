-- Tabla de seguimiento de confirmaciones de comisiones.
-- La app de Streamlit escribe UNICAMENTE en esta tabla (via MERGE);
-- la tabla oficial de comisiones nunca se modifica desde la app.
--
-- Ejecutar una sola vez en BigQuery (ajusta proyecto/dataset si aplica):

CREATE TABLE IF NOT EXISTS `papyrus-delivery-data.habicredit.comisiones_confirmaciones` (
  id_comision       STRING    NOT NULL OPTIONS (description = 'Identificador unico de la fila de comision en la tabla oficial'),
  periodo           STRING    NOT NULL OPTIONS (description = 'Periodo de pago de la comision, formato YYYY-MM'),
  correo_usuario    STRING    NOT NULL OPTIONS (description = 'Correo del asesor/usuario dueno de la comision'),
  monto_comision    NUMERIC            OPTIONS (description = 'Monto de la comision al momento de la respuesta (snapshot)'),
  estado            STRING    NOT NULL OPTIONS (description = 'PENDIENTE | ACEPTADA | RECHAZADA'),
  comentario        STRING             OPTIONS (description = 'Comentario del usuario; obligatorio cuando el estado es RECHAZADA'),
  fecha_respuesta   TIMESTAMP          OPTIONS (description = 'Momento en que el usuario acepto o rechazo'),
  fecha_creacion    TIMESTAMP NOT NULL OPTIONS (description = 'Momento en que se creo el registro de seguimiento'),
  fecha_modificacion TIMESTAMP         OPTIONS (description = 'Ultima modificacion del registro')
)
PARTITION BY DATE(fecha_creacion)
CLUSTER BY periodo, correo_usuario
OPTIONS (
  description = 'Seguimiento de confirmacion/inconformidad de comisiones Habicredit. Poblada por la app de Streamlit. Los rechazos se enrutan a BI y alimentan el motor de retroactivos.'
);
