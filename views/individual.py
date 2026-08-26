"""Vista individual: cada usuario ve SUS comisiones y las acepta o rechaza."""
from __future__ import annotations

import pandas as pd
import streamlit as st


def render(service, correo: str) -> None:
    st.subheader("Mis comisiones")

    comisiones = service.get_comisiones(correo=correo)
    if comisiones.empty:
        st.info("No se encontraron comisiones para tu correo en los periodos disponibles.")
        return

    periodos = sorted(comisiones["periodo"].unique(), reverse=True)
    periodo = st.selectbox("Periodo", periodos, key="periodo_individual")
    df = comisiones[comisiones["periodo"] == periodo].reset_index(drop=True)

    confirmaciones = service.get_confirmaciones(correo=correo, periodo=periodo)
    estado_por_id = (
        dict(zip(confirmaciones["id_comision"], confirmaciones["estado"]))
        if not confirmaciones.empty
        else {}
    )

    total = df["monto_comision"].sum()
    respondidas = sum(1 for i in df["id_comision"] if i in estado_por_id)

    c1, c2, c3 = st.columns(3)
    c1.metric("Total comisiones del periodo", f"${total:,.0f}")
    c2.metric("Indicadores", len(df))
    c3.metric("Respondidas", f"{respondidas}/{len(df)}")
    st.divider()

    for _, fila in df.iterrows():
        id_comision = fila["id_comision"]
        estado_actual = estado_por_id.get(id_comision, "PENDIENTE")

        with st.container(border=True):
            izq, der = st.columns([3, 2])

            with izq:
                st.markdown(f"**{fila['indicador']}** — {fila['periodo']}")
                st.write(
                    f"Meta: {fila['meta']} | Ejecucion: {fila['ejecucion']} | "
                    f"Cumplimiento: {fila['cumplimiento']:.0%}"
                )
                st.markdown(f"Monto: **${fila['monto_comision']:,.0f}**")
                _badge_estado(estado_actual)

            with der:
                if estado_actual == "PENDIENTE":
                    comentario = st.text_input(
                        "Comentario (obligatorio si rechazas)",
                        key=f"comentario_{id_comision}",
                    )
                    b1, b2 = st.columns(2)
                    if b1.button("✅ Aceptar", key=f"aceptar_{id_comision}", use_container_width=True):
                        service.responder_comision(
                            id_comision, fila["periodo"], correo,
                            float(fila["monto_comision"]), "ACEPTADA", comentario,
                        )
                        st.rerun()
                    if b2.button("❌ Rechazar", key=f"rechazar_{id_comision}", use_container_width=True):
                        if not comentario.strip():
                            st.error("Para rechazar debes indicar el motivo en el comentario.")
                        else:
                            service.responder_comision(
                                id_comision, fila["periodo"], correo,
                                float(fila["monto_comision"]), "RECHAZADA", comentario,
                            )
                            st.rerun()
                else:
                    st.caption("Ya respondiste esta comision.")
                    if st.button("↩️ Cambiar respuesta", key=f"reabrir_{id_comision}"):
                        service.responder_comision(
                            id_comision, fila["periodo"], correo,
                            float(fila["monto_comision"]), "PENDIENTE", "",
                        )
                        st.rerun()


def _badge_estado(estado: str) -> None:
    colores = {"PENDIENTE": "orange", "ACEPTADA": "green", "RECHAZADA": "red"}
    st.markdown(f":{colores.get(estado, 'gray')}[**{estado}**]")
