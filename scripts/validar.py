"""Corre las validaciones SQL de sql/validaciones/ contra BigQuery.

Imprime cada fila problematica que devuelva alguna de las consultas y
termina con exit code 1 si hubo al menos un hallazgo (0 si todo esta limpio).

Uso:
    python scripts/validar.py
"""
from __future__ import annotations

import sys
from pathlib import Path

from google.cloud import bigquery

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import config  # noqa: E402  (requiere el sys.path.insert de arriba)

SQL_DIR = Path(__file__).resolve().parent.parent / "sql" / "validaciones"

ARCHIVOS = (
    "validacion_metas.sql",
    "diff_indicadores.sql",
    "conciliacion.sql",
)


def _correr(client: bigquery.Client, nombre: str) -> int:
    sql = (SQL_DIR / nombre).read_text(encoding="utf-8")
    print(f"\n=== {nombre} ===")

    filas = list(client.query(sql).result())
    if not filas:
        print("OK - sin hallazgos")
        return 0

    for fila in filas:
        print(dict(fila.items()))
    print(f"-> {len(filas)} fila(s) problematica(s)")
    return len(filas)


def main() -> int:
    client = bigquery.Client(project=config.GCP_PROJECT)
    total_hallazgos = sum(_correr(client, nombre) for nombre in ARCHIVOS)

    if total_hallazgos:
        print(f"\nTotal hallazgos: {total_hallazgos}")
        return 1

    print("\nTodas las validaciones pasaron sin hallazgos.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
