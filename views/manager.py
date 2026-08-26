import streamlit as st
import pandas as pd

def render(service):
    st.write("### Detalle de Comisiones por Equipo")
    st.caption("📝 Usa los filtros, navega por las pestañas y edita la columna 'estado' para aprobar o rechazar.")

    # 1. OBTENEMOS Y UNIMOS LOS DATOS
    df_comisiones = service.get_comisiones()
    df_confirmaciones = service.get_confirmaciones()

    if not df_confirmaciones.empty:
        df = pd.merge(
            df_comisiones,
            df_confirmaciones[["id_comision", "estado", "comentario"]],
            on="id_comision",
            how="left"
        )
    else:
        df = df_comisiones.copy()
        df["estado"] = "PENDIENTE"
        df["comentario"] = ""
    
    df["estado"] = df["estado"].fillna("PENDIENTE")
    df["comentario"] = df["comentario"].fillna("")

    # 2. SECCIÓN DE FILTROS
    st.write("#### 🔍 Filtros de búsqueda")
    col1, col2, col3 = st.columns(3)
    
    with col1:
        lista_beneficiados = sorted(df["correo_usuario"].dropna().unique().tolist())
        filtro_beneficiado = st.multiselect("👤 Beneficiado (Correo)", options=lista_beneficiados)
        
    with col2:
        lista_posiciones = sorted(df["posicion"].dropna().unique().tolist())
        filtro_posicion = st.multiselect("🏢 Posición (Equipo)", options=lista_posiciones)
        
    with col3:
        lista_indicadores = sorted(df["indicador"].dropna().unique().tolist())
        filtro_indicador = st.multiselect("📊 Indicador", options=lista_indicadores)

    # 3. APLICAR FILTROS AL DATAFRAME
    df_filtrado = df.copy()
    if filtro_beneficiado:
        df_filtrado = df_filtrado[df_filtrado["correo_usuario"].isin(filtro_beneficiado)]
    if filtro_posicion:
        df_filtrado = df_filtrado[df_filtrado["posicion"].isin(filtro_posicion)]
    if filtro_indicador:
        df_filtrado = df_filtrado[df_filtrado["indicador"].isin(filtro_indicador)]

    # ORDENAR DATOS: Alfabéticamente por beneficiado y luego indicador
    df_filtrado = df_filtrado.sort_values(by=["correo_usuario", "indicador"], ascending=[True, True])

    # 4. MÉTRICA DE TOTAL GLOBAL
    st.divider()
    total_global = df_filtrado["monto_comision"].sum()
    st.metric(label="💰 Suma Total de Pagos (Según filtros actuales)", value=f"${total_global:,.0f}")
    st.divider()

    # OBTENER LISTA DE EQUIPOS BASADO EN LOS FILTROS
    equipos = sorted(df_filtrado["posicion"].dropna().unique().tolist())

    if not equipos:
        st.warning("⚠️ No hay datos que coincidan con los filtros seleccionados.")
        return

    # 5. CREAMOS PESTAÑAS POR EQUIPO
    tabs = st.tabs(equipos)
    dfs_editados = []

    for tab, equipo in zip(tabs, equipos):
        with tab:
            df_equipo = df_filtrado[df_filtrado["posicion"] == equipo].copy()
            
            # Subtotal por equipo
            total_equipo = df_equipo["monto_comision"].sum()
            st.markdown(f"**Suma de pagos para {equipo}:** `${total_equipo:,.0f}`")
            
            # Mostramos el editor
            df_editado = st.data_editor(
                df_equipo,
                key=f"editor_{equipo}", 
                use_container_width=True,
                hide_index=True,
                column_config={
                    "estado": st.column_config.SelectboxColumn(
                        "Estado",
                        options=["PENDIENTE", "ACEPTADA", "RECHAZADA"],
                        required=True,
                    ),
                    "comentario": st.column_config.TextColumn("Comentario"),
                    "id_comision": None, 
                    "correo_usuario": st.column_config.TextColumn("Beneficiado", disabled=True),
                    "posicion": st.column_config.TextColumn(disabled=True),
                    "monto_comision": st.column_config.NumberColumn(
                        "Monto Comisión", 
                        disabled=True,
                        format="$ %d" # Formato de moneda para que se vea más limpio
                    ),
                    "meta": st.column_config.NumberColumn(disabled=True),
                    "ejecucion": st.column_config.NumberColumn(disabled=True),
                }
            )
            dfs_editados.append(df_editado)

    # Unimos todas las tablas editadas
    df_final = pd.concat(dfs_editados, ignore_index=True)

    st.divider()

    # 6. GUARDAR CAMBIOS
    if st.button("💾 Guardar Confirmaciones", type="primary"):
        errores = False
        
        for index, fila in df_final.iterrows():
            estado = fila["estado"]
            comentario = str(fila.get("comentario", "")).strip()
            
            if estado == "RECHAZADA" and (comentario == "" or comentario.lower() == "nan"):
                st.error(f"❌ Error: Debes agregar un comentario para la comisión rechazada de **{fila['correo_usuario']}** (Indicador: {fila['indicador']}).")
                errores = True

        if errores:
            st.warning("⚠️ Corrige los errores en las tablas antes de guardar.")
        else:
            for index, fila in df_final.iterrows():
                if fila["estado"] != "PENDIENTE":
                    service.responder_comision(
                        id_comision=fila["id_comision"],
                        periodo=fila["periodo"],
                        correo=fila["correo_usuario"],
                        monto_comision=fila["monto_comision"],
                        estado=fila["estado"],
                        comentario=fila["comentario"]
                    )
            
            st.success("✅ ¡Las comisiones se han procesado y guardado correctamente!")
            st.balloons()