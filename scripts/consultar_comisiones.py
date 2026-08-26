"""Corre el motor de comisiones (paso 2, solo lectura) para un periodo y
acumula el resultado en data/historico_comisiones.csv con un timestamp de
ejecucion. Nunca escribe en BigQuery -- es control de versiones manual de
como se vieron las comisiones en distintos momentos (util mientras el mes
sigue abierto y los numeros cambian).

Usa el CLI `bq` (no el cliente Python) porque metas_comisiones_internas es
una tabla externa sobre Google Sheets y el cliente Python con las
credenciales ADC actuales no tiene el scope de Drive que si tiene `bq`.

Uso:
    python scripts/consultar_comisiones.py 2026-08
    python scripts/consultar_comisiones.py            # mes actual (UTC)
"""
from __future__ import annotations

import io
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

QUERY_FINAL = Path(__file__).resolve().parent.parent / "sql" / "comisiones_co" / "comisiones_internas_hc_final.sql"
HISTORICO = Path(__file__).resolve().parent.parent / "data" / "historico_comisiones.csv"

FILTRO_ORIGINAL = "WHERE mes_comision <= DATE_TRUNC(CURRENT_DATE('-5'), MONTH)"


def _query_para_periodo(periodo: str) -> str:
    sql = QUERY_FINAL.read_text(encoding="utf-8")
    if sql.count(FILTRO_ORIGINAL) != 1:
        raise RuntimeError(
            "El filtro base de comisiones_internas_hc_final.sql cambio de forma; "
            "ajustar FILTRO_ORIGINAL en este script antes de continuar."
        )
    filtro_nuevo = f"WHERE mes_comision = DATE('{periodo}-01')"
    return sql.replace(FILTRO_ORIGINAL, filtro_nuevo)


def _correr_bq(sql: str) -> pd.DataFrame:
    proceso = subprocess.run(
        ["bq", "query", "--use_legacy_sql=false", "--format=csv", "--max_rows=100000"],
        input=sql,
        capture_output=True,
        text=True,
        check=True,
    )
    return pd.read_csv(io.StringIO(proceso.stdout))


def main() -> int:
    periodo = sys.argv[1] if len(sys.argv) > 1 else datetime.now(timezone.utc).strftime("%Y-%m")

    df = _correr_bq(_query_para_periodo(periodo))
    # Descarta los ajustes puntuales (UNION ALL) de otros meses que la query trae siempre.
    df = df[df["mes_comision"].astype(str) == f"{periodo}-01"].reset_index(drop=True)

    df["fecha_ejecucion_utc"] = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M")

    HISTORICO.parent.mkdir(exist_ok=True)
    escribir_encabezado = not HISTORICO.exists()
    df.to_csv(HISTORICO, mode="a", header=escribir_encabezado, index=False)

    print(f"{len(df)} fila(s) del periodo {periodo} agregadas a {HISTORICO}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
