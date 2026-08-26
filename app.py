"""App de confirmacion de comisiones Habicredit (CO y MX).

Punto de entrada de Streamlit. Ejecutar con:
    streamlit run app.py
"""
import streamlit as st

import config
from services.data_service import get_service
from views import manager

st.set_page_config(
    page_title="Confirmacion de comisiones | Habicredit",
    page_icon="✅",
    layout="wide",
)

@st.cache_resource
def _service():
    return get_service()

def main() -> None:
    st.title("✅ Confirmacion de comisiones Habicredit")

    if config.APP_MODE == "demo":
        st.caption("🧪 Modo DEMO: datos de ejemplo locales, sin conexion a BigQuery.")
    elif config.APP_MODE == "file":
        st.caption("📄 Comisiones desde export estatico de la vista final.")

    # Inicializamos el servicio
    service = _service()

    # --- Vista General ---
    st.header("📊 Vista general de comisiones")
    manager.render(service)

if __name__ == "__main__":
    main()