"""Tests de api/main.py con TestClient. BigQuery nunca se toca: get_service()
se sobreescribe por un FakeService en memoria via dependency_overrides.
"""
import pandas as pd
import pytest
from fastapi.testclient import TestClient

import config
from api.deps import get_service
from api.main import app

API_KEY = "test-key"
HEADERS = {"X-API-Key": API_KEY}


class FakeService:
    """Doble de DemoService/BigQueryService, en memoria, sin CSV ni BigQuery."""

    def __init__(self) -> None:
        self._comisiones = pd.DataFrame(
            [
                {
                    "id_comision": "2026-06|ana@habicredit.co|radicacion",
                    "periodo": "2026-06",
                    "correo_usuario": "ana@habicredit.co",
                    "posicion": "Analista de Radicacion",
                    "indicador": "radicacion",
                    "meta": 25,
                    "ejecucion": 21,
                    "cumplimiento": 0.84,
                    "monto_comision": 1_200_000,
                }
            ]
        )
        self._confirmaciones: dict[str, dict] = {}

    def get_comisiones(self, correo=None, periodo=None):
        df = self._comisiones
        if correo:
            df = df[df["correo_usuario"].str.lower() == correo.strip().lower()]
        if periodo:
            df = df[df["periodo"] == periodo]
        return df.reset_index(drop=True)

    def get_confirmaciones(self, correo=None, periodo=None):
        filas = list(self._confirmaciones.values())
        df = pd.DataFrame(filas) if filas else pd.DataFrame(
            columns=["id_comision", "periodo", "correo_usuario", "monto_comision", "estado", "comentario"]
        )
        if correo and not df.empty:
            df = df[df["correo_usuario"].str.lower() == correo.strip().lower()]
        if periodo and not df.empty:
            df = df[df["periodo"] == periodo]
        return df.reset_index(drop=True)

    def responder_comision(self, id_comision, periodo, correo, monto_comision, estado, comentario=""):
        self._confirmaciones[id_comision] = {
            "id_comision": id_comision,
            "periodo": periodo,
            "correo_usuario": correo,
            "monto_comision": monto_comision,
            "estado": estado,
            "comentario": comentario,
        }


@pytest.fixture
def fake_service():
    return FakeService()


@pytest.fixture
def client(fake_service, monkeypatch):
    monkeypatch.setattr(config, "API_KEY", API_KEY)
    app.dependency_overrides[get_service] = lambda: fake_service
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_sin_api_key_da_401(client):
    resp = client.get("/comisiones")
    assert resp.status_code == 401


def test_rechazar_sin_comentario_da_422(client):
    resp = client.post(
        "/confirmaciones",
        headers=HEADERS,
        json={
            "id_comision": "2026-06|ana@habicredit.co|radicacion",
            "periodo": "2026-06",
            "correo": "ana@habicredit.co",
            "monto_comision": 1_200_000,
            "estado": "RECHAZADA",
            "comentario": "",
        },
    )
    assert resp.status_code == 422


def test_estado_invalido_da_422(client):
    resp = client.post(
        "/confirmaciones",
        headers=HEADERS,
        json={
            "id_comision": "2026-06|ana@habicredit.co|radicacion",
            "periodo": "2026-06",
            "correo": "ana@habicredit.co",
            "monto_comision": 1_200_000,
            "estado": "APROBADA",
        },
    )
    assert resp.status_code == 422


def test_confirmar_y_rechazar_deja_una_fila_rechazada(client):
    id_comision = "2026-06|ana@habicredit.co|radicacion"
    base = {
        "id_comision": id_comision,
        "periodo": "2026-06",
        "correo": "ana@habicredit.co",
        "monto_comision": 1_200_000,
    }

    resp_aceptar = client.post("/confirmaciones", headers=HEADERS, json={**base, "estado": "ACEPTADA"})
    assert resp_aceptar.status_code == 200

    resp_rechazar = client.post(
        "/confirmaciones",
        headers=HEADERS,
        json={**base, "estado": "RECHAZADA", "comentario": "Monto incorrecto"},
    )
    assert resp_rechazar.status_code == 200

    resp_listado = client.get("/confirmaciones", headers=HEADERS, params={"correo": "ana@habicredit.co"})
    assert resp_listado.status_code == 200
    filas = resp_listado.json()
    filas_del_id = [f for f in filas if f["id_comision"] == id_comision]
    assert len(filas_del_id) == 1
    assert filas_del_id[0]["estado"] == "RECHAZADA"


def test_correo_inexistente_da_lista_vacia(client):
    resp = client.get("/comisiones", headers=HEADERS, params={"correo": "noexiste@habicredit.co"})
    assert resp.status_code == 200
    assert resp.json() == []
