"""Dependencias de FastAPI: servicio de datos y autenticacion por API key."""
from typing import Optional

from fastapi import Header, HTTPException, status

import config
from services.data_service import get_service as _get_service


def get_service():
    """Backend segun APP_MODE. Los tests la sobreescriben via dependency_overrides."""
    return _get_service()


def require_api_key(x_api_key: Optional[str] = Header(None, alias="X-API-Key")) -> None:
    if not config.API_KEY or x_api_key != config.API_KEY:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="API key invalida o ausente")
