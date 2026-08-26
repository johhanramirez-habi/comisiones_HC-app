"""Esquemas Pydantic: el contrato de la API."""
from typing import Literal

from pydantic import BaseModel, model_validator


class ConfirmacionIn(BaseModel):
    id_comision: str
    periodo: str
    correo: str
    monto_comision: float
    estado: Literal["ACEPTADA", "RECHAZADA"]
    comentario: str = ""

    @model_validator(mode="after")
    def _comentario_obligatorio_si_rechaza(self) -> "ConfirmacionIn":
        if self.estado == "RECHAZADA" and not self.comentario.strip():
            raise ValueError("comentario es obligatorio cuando estado es RECHAZADA")
        return self

    def to_responder_kwargs(self) -> dict:
        return {
            "id_comision": self.id_comision,
            "periodo": self.periodo,
            "correo": self.correo,
            "monto_comision": self.monto_comision,
            "estado": self.estado,
            "comentario": self.comentario,
        }
