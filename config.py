"""Configuracion central de la app de confirmacion de comisiones.

Lee variables desde .env (o del entorno) y expone constantes usadas
por el resto de la aplicacion.
"""
import os
from pathlib import Path

from dotenv import load_dotenv

# Carga .env desde la raiz del proyecto
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

# --- Modo de la app ---
# demo -> datos de ejemplo locales
# file -> comisiones desde un export estatico (CSV/Excel de la vista final);
#         confirmaciones en BigQuery si hay acceso, si no en CSV local
# prod -> todo en BigQuery (requiere scope de Drive por las metas en Sheets)
APP_MODE = os.getenv("APP_MODE", "demo").strip().lower()

# Export estatico de la vista comisiones_internas_hc_final (modo file)
COMISIONES_FILE = os.getenv(
    "COMISIONES_FILE",
    str(Path(__file__).resolve().parent / "data" / "comisiones_internas_hc_final.csv"),
)

# --- BigQuery ---
GCP_PROJECT = os.getenv("GCP_PROJECT", "papyrus-delivery-data")
BQ_DATASET = os.getenv("BQ_DATASET", "comisiones")
BQ_TABLA_COMISIONES = os.getenv("BQ_TABLA_COMISIONES", "comisiones_internas_hc_finanzas")
BQ_TABLA_CONFIRMACIONES = os.getenv("BQ_TABLA_CONFIRMACIONES", "comisiones_confirmaciones")

TABLA_COMISIONES_FQN = f"`{GCP_PROJECT}.{BQ_DATASET}.{BQ_TABLA_COMISIONES}`"
TABLA_CONFIRMACIONES_FQN = f"`{GCP_PROJECT}.{BQ_DATASET}.{BQ_TABLA_CONFIRMACIONES}`"

# --- API ---
# Header X-API-Key requerido por api/main.py en todos los endpoints menos /health.
API_KEY = os.getenv("API_KEY", "")

# --- Acceso ---
MANAGER_EMAILS = [
    e.strip().lower()
    for e in os.getenv("MANAGER_EMAILS", "").split(",")
    if e.strip()
]

# --- Datos demo ---
DATA_DIR = BASE_DIR / "data"
DEMO_COMISIONES_CSV = DATA_DIR / "sample_comisiones.csv"
DEMO_CONFIRMACIONES_CSV = DATA_DIR / "confirmaciones_demo.csv"

# --- Estados validos de una confirmacion ---
ESTADOS = ("PENDIENTE", "ACEPTADA", "RECHAZADA")


def es_manager(correo: str) -> bool:
    """True si el correo tiene acceso a la vista consolidada de manager."""
    return correo.strip().lower() in MANAGER_EMAILS
