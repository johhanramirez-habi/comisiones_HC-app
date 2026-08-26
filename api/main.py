"""API FastAPI de confirmacion de comisiones. Capa fina sobre services/data_service.py.

Nunca escribe en la tabla oficial de comisiones: solo llama a
service.responder_comision(), que hace MERGE/upsert unicamente en la
tabla de seguimiento comisiones_confirmaciones.
"""
from typing import Optional

from fastapi import APIRouter, Depends, FastAPI

from api.deps import get_service, require_api_key
from api.schemas import ConfirmacionIn

app = FastAPI(title="Comisiones API")

router = APIRouter(dependencies=[Depends(require_api_key)])


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@router.get("/comisiones")
def listar_comisiones(
    periodo: Optional[str] = None,
    correo: Optional[str] = None,
    service=Depends(get_service),
) -> list:
    df = service.get_comisiones(correo=correo, periodo=periodo)
    return df.to_dict(orient="records")


@router.get("/confirmaciones")
def listar_confirmaciones(
    periodo: Optional[str] = None,
    correo: Optional[str] = None,
    estado: Optional[str] = None,
    service=Depends(get_service),
) -> list:
    df = service.get_confirmaciones(correo=correo, periodo=periodo)
    if estado and not df.empty:
        df = df[df["estado"] == estado]
    return df.to_dict(orient="records")


@router.post("/confirmaciones")
def confirmar(payload: ConfirmacionIn, service=Depends(get_service)) -> dict:
    service.responder_comision(**payload.to_responder_kwargs())
    return {"ok": True, "id_comision": payload.id_comision, "estado": payload.estado}


app.include_router(router)
