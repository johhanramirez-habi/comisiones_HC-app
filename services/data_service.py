"""Capa de datos de la app de confirmacion de comisiones.

Expone dos backends con la misma interfaz:

- DemoService:     datos de ejemplo en CSV locales (para probar sin BigQuery).
- BigQueryService: lectura de la tabla oficial de comisiones y escritura
                   (MERGE) en la tabla de seguimiento comisiones_confirmaciones.

La app NUNCA escribe en la tabla oficial de comisiones.
"""
from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

import config

# Columnas que la app espera de la fuente de comisiones.
COLUMNAS_COMISIONES = [
    "id_comision",
    "periodo",
    "correo_usuario",
    "posicion",
    "indicador",
    "meta",
    "ejecucion",
    "cumplimiento",
    "monto_comision",
]

COLUMNAS_CONFIRMACIONES = [
    "id_comision",
    "periodo",
    "correo_usuario",
    "monto_comision",
    "estado",
    "comentario",
    "fecha_respuesta",
    "fecha_creacion",
    "fecha_modificacion",
]

def _ahora() -> datetime:
    return datetime.now(timezone.utc)

# ---------------------------------------------------------------------------
# Backend DEMO (CSV locales)
# ---------------------------------------------------------------------------
class DemoService:
    def __init__(self) -> None:
        config.DATA_DIR.mkdir(exist_ok=True)
        if not config.DEMO_COMISIONES_CSV.exists():
            self._crear_datos_ejemplo()

    def _crear_datos_ejemplo(self) -> None:
        filas = []
        usuarios = [
            ("ana.gomez@habicredit.co", "Analista Legalización"),
            ("carlos.perez@habicredit.co", "Analista de Radicación"),
            ("laura.diaz@habicredit.co", "K.A.M. - General"),
            ("johhanramirez@habi.co", "Gerente Ops Liquidez"),
        ]
        indicadores = [
            ("desembolsos", 10, 12, 3_500_000),
            ("radicacion", 25, 21, 1_200_000),
            ("radicacion_monto", 900_000_000, 750_000_000, 800_000),
        ]
        for periodo in ("2026-05", "2026-06"):
            for correo, posicion in usuarios:
                for indicador, meta, ejecucion, monto in indicadores:
                    filas.append(
                        {
                            "id_comision": f"{periodo}|{correo}|{indicador}",
                            "periodo": periodo,
                            "correo_usuario": correo,
                            "posicion": posicion,
                            "indicador": indicador,
                            "meta": meta,
                            "ejecucion": ejecucion,
                            "cumplimiento": round(ejecucion / meta, 3),
                            "monto_comision": monto,
                        }
                    )
        pd.DataFrame(filas).to_csv(config.DEMO_COMISIONES_CSV, index=False)

    def get_comisiones(self, correo: str | None = None, periodo: str | None = None) -> pd.DataFrame:
        df = pd.read_csv(config.DEMO_COMISIONES_CSV, dtype={"periodo": str})
        if correo:
            df = df[df["correo_usuario"].str.lower() == correo.strip().lower()]
        if periodo:
            df = df[df["periodo"] == periodo]
        return df.reset_index(drop=True)

    def get_confirmaciones(self, correo: str | None = None, periodo: str | None = None) -> pd.DataFrame:
        if not config.DEMO_CONFIRMACIONES_CSV.exists():
            return pd.DataFrame(columns=COLUMNAS_CONFIRMACIONES)
        df = pd.read_csv(config.DEMO_CONFIRMACIONES_CSV, dtype={"periodo": str})
        if correo:
            df = df[df["correo_usuario"].str.lower() == correo.strip().lower()]
        if periodo:
            df = df[df["periodo"] == periodo]
        return df.reset_index(drop=True)

    def responder_comision(
        self,
        id_comision: str,
        periodo: str,
        correo: str,
        monto_comision: float,
        estado: str,
        comentario: str = "",
    ) -> None:
        assert estado in config.ESTADOS, f"Estado invalido: {estado}"
        ahora = _ahora().isoformat()
        df = self.get_confirmaciones()
        mask = df["id_comision"] == id_comision if not df.empty else pd.Series(dtype=bool)

        if not df.empty and mask.any():
            df.loc[mask, ["estado", "comentario", "fecha_respuesta", "fecha_modificacion"]] = [
                estado, comentario, ahora, ahora,
            ]
        else:
            nueva = pd.DataFrame(
                [
                    {
                        "id_comision": id_comision,
                        "periodo": periodo,
                        "correo_usuario": correo,
                        "monto_comision": monto_comision,
                        "estado": estado,
                        "comentario": comentario,
                        "fecha_respuesta": ahora,
                        "fecha_creacion": ahora,
                        "fecha_modificacion": ahora,
                    }
                ]
            )
            df = nueva if df.empty else pd.concat([df, nueva], ignore_index=True)

        config.DATA_DIR.mkdir(exist_ok=True)
        df.to_csv(config.DEMO_CONFIRMACIONES_CSV, index=False)

# ---------------------------------------------------------------------------
# Backend PROD (BigQuery)
# ---------------------------------------------------------------------------
class BigQueryService:
    def __init__(self) -> None:
        from google.cloud import bigquery 

        self._bq = bigquery
        self.client = bigquery.Client(project=config.GCP_PROJECT)

    def get_comisiones(self, correo: str | None = None, periodo: str | None = None) -> pd.DataFrame:
        filtros, params = [], []
        if correo:
            filtros.append("LOWER(beneficiado) = LOWER(@correo)")
            params.append(self._bq.ScalarQueryParameter("correo", "STRING", correo))
        if periodo:
            filtros.append("FORMAT_DATE('%Y-%m', mes_comision) = @periodo")
            params.append(self._bq.ScalarQueryParameter("periodo", "STRING", periodo))
        where = f"WHERE {' AND '.join(filtros)}" if filtros else ""

        query = f"""
            SELECT
              CONCAT(
                FORMAT_DATE('%Y-%m', mes_comision), '|',
                LOWER(beneficiado), '|',
                indicador
              )                                         AS id_comision,
              FORMAT_DATE('%Y-%m', mes_comision)        AS periodo,
              LOWER(beneficiado)                        AS correo_usuario,
              posicion,
              indicador,
              meta_value                                AS meta,
              ejecucion,
              IFNULL(p_ejecucion, 0)                    AS cumplimiento,
              IFNULL(pago, 0)                           AS monto_comision
            FROM {config.TABLA_COMISIONES_FQN}
            {where}
            ORDER BY periodo DESC, correo_usuario, indicador
        """
        job_config = self._bq.QueryJobConfig(query_parameters=params)
        return self.client.query(query, job_config=job_config).to_dataframe()

    def get_confirmaciones(self, correo: str | None = None, periodo: str | None = None) -> pd.DataFrame:
        filtros, params = [], []
        if correo:
            filtros.append("LOWER(correo_usuario) = LOWER(@correo)")
            params.append(self._bq.ScalarQueryParameter("correo", "STRING", correo))
        if periodo:
            filtros.append("periodo = @periodo")
            params.append(self._bq.ScalarQueryParameter("periodo", "STRING", periodo))
        where = f"WHERE {' AND '.join(filtros)}" if filtros else ""

        query = f"""
            SELECT *
            FROM {config.TABLA_CONFIRMACIONES_FQN}
            {where}
        """
        job_config = self._bq.QueryJobConfig(query_parameters=params)
        return self.client.query(query, job_config=job_config).to_dataframe()

    def responder_comision(
        self,
        id_comision: str,
        periodo: str,
        correo: str,
        monto_comision: float,
        estado: str,
        comentario: str = "",
    ) -> None:
        assert estado in config.ESTADOS, f"Estado invalido: {estado}"
        query = f"""
            MERGE {config.TABLA_CONFIRMACIONES_FQN} T
            USING (
              SELECT
                @id_comision  AS id_comision,
                @periodo      AS periodo,
                @correo       AS correo_usuario,
                @monto        AS monto_comision,
                @estado       AS estado,
                @comentario   AS comentario
            ) S
            ON T.id_comision = S.id_comision
            WHEN MATCHED THEN UPDATE SET
              estado             = S.estado,
              comentario         = S.comentario,
              fecha_respuesta    = CURRENT_TIMESTAMP(),
              fecha_modificacion = CURRENT_TIMESTAMP()
            WHEN NOT MATCHED THEN INSERT (
              id_comision, periodo, correo_usuario, monto_comision,
              estado, comentario, fecha_respuesta, fecha_creacion, fecha_modificacion
            )
            VALUES (
              S.id_comision, S.periodo, S.correo_usuario, S.monto_comision,
              S.estado, S.comentario, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()
            )
        """
        job_config = self._bq.QueryJobConfig(
            query_parameters=[
                self._bq.ScalarQueryParameter("id_comision", "STRING", id_comision),
                self._bq.ScalarQueryParameter("periodo", "STRING", periodo),
                self._bq.ScalarQueryParameter("correo", "STRING", correo),
                self._bq.ScalarQueryParameter("monto", "NUMERIC", monto_comision),
                self._bq.ScalarQueryParameter("estado", "STRING", estado),
                self._bq.ScalarQueryParameter("comentario", "STRING", comentario),
            ]
        )
        self.client.query(query, job_config=job_config).result()

# ---------------------------------------------------------------------------
# Backend FILE
# ---------------------------------------------------------------------------
class FileService(DemoService):
    def __init__(self) -> None:
        config.DATA_DIR.mkdir(exist_ok=True)
        ruta = Path(config.COMISIONES_FILE)
        if not ruta.exists():
            raise FileNotFoundError(
                f"No se encontro el export de comisiones: {ruta}\n"
                "Descarga el resultado de la vista comisiones_internas_hc_final "
                "desde la consola de BigQuery y guardalo en esa ruta."
            )
        self._ruta = ruta
        try:
            self._bq = BigQueryService()  
        except Exception:
            self._bq = None

    @property
    def confirmaciones_en_bigquery(self) -> bool:
        return self._bq is not None

    def get_comisiones(self, correo: str | None = None, periodo: str | None = None) -> pd.DataFrame:
        if self._ruta.suffix.lower() in (".xlsx", ".xls"):
            df = pd.read_excel(self._ruta)
        else:
            df = pd.read_csv(self._ruta)
        df.columns = [c.strip().lower() for c in df.columns]

        mes = pd.to_datetime(df["mes_comision"]).dt.strftime("%Y-%m")
        correo_col = df["beneficiado"].astype(str).str.strip().str.lower()
        out = pd.DataFrame(
            {
                "id_comision": mes + "|" + correo_col + "|" + df["indicador"].astype(str),
                "periodo": mes,
                "correo_usuario": correo_col,
                "posicion": df["posicion"],
                "indicador": df["indicador"],
                "meta": df["meta_value"],
                "ejecucion": df["ejecucion"],
                "cumplimiento": pd.to_numeric(df["p_ejecucion"], errors="coerce").fillna(0),
                "monto_comision": pd.to_numeric(df["pago"], errors="coerce").fillna(0),
            }
        )
        if correo:
            out = out[out["correo_usuario"] == correo.strip().lower()]
        if periodo:
            out = out[out["periodo"] == periodo]
        return out.reset_index(drop=True)

    def get_confirmaciones(self, correo: str | None = None, periodo: str | None = None) -> pd.DataFrame:
        if self._bq:
            return self._bq.get_confirmaciones(correo=correo, periodo=periodo)
        return super().get_confirmaciones(correo=correo, periodo=periodo)

    def responder_comision(self, *args, **kwargs) -> None:
        if self._bq:
            self._bq.responder_comision(*args, **kwargs)
        else:
            super().responder_comision(*args, **kwargs)

# ---------------------------------------------------------------------------
# Fabrica
# ---------------------------------------------------------------------------
def get_service():
    """Devuelve el backend segun APP_MODE (.env)."""
    if config.APP_MODE == "prod":
        return BigQueryService()
    if config.APP_MODE == "file":
        return FileService()
    return DemoService()