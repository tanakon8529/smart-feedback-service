import importlib
import pkgutil
from typing import List
from fastapi import FastAPI
from .base import Microservice

def load_microservices(app: FastAPI) -> List[str]:
    loaded = []
    pkg_name = __package__ or "app.microservices"
    package = importlib.import_module(pkg_name)
    for mod in pkgutil.iter_modules(package.__path__):
        name = mod.name
        if name in {"base", "loader"}:
            continue
        module = importlib.import_module(f"{pkg_name}.{name}.service")
        service: Microservice = getattr(module, "service")
        app.include_router(service.router, prefix=service.prefix)
        loaded.append(service.name)
    return loaded
