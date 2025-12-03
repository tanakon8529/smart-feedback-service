from typing import Protocol
from fastapi import APIRouter

class Microservice(Protocol):
    name: str
    prefix: str
    router: APIRouter
