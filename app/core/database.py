import os
from typing import Dict, Optional
from contextvars import ContextVar
from enum import Enum
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from sqlmodel import SQLModel
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlalchemy.ext.asyncio import create_async_engine, AsyncEngine
from sqlalchemy.orm import sessionmaker

# --- 1. Configuration & Enums ---

class DBClusterType(str, Enum):
    WRITER = "writer"
    READER = "reader"
    ANALYTICS = "analytics"

# Context variable to hold the current requested DB cluster (default to WRITER)
_db_cluster_ctx: ContextVar[DBClusterType] = ContextVar("db_cluster_ctx", default=DBClusterType.WRITER)

# Default Config (Single Node fallback)
DEFAULT_DB_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://user:password@localhost:5432/feedback_db")

# Simulating Multi-Cluster Config (In real prod, load from env/config map)
DB_CONFIG = {
    DBClusterType.WRITER: os.getenv("DB_WRITER_URL", DEFAULT_DB_URL),
    DBClusterType.READER: os.getenv("DB_READER_URL", DEFAULT_DB_URL),
    DBClusterType.ANALYTICS: os.getenv("DB_ANALYTICS_URL", DEFAULT_DB_URL),
}

# --- 2. Engine Manager (Singleton-ish) ---

class DBManager:
    def __init__(self):
        self.engines: Dict[DBClusterType, AsyncEngine] = {}

    def get_engine(self, cluster_type: DBClusterType) -> AsyncEngine:
        if cluster_type not in self.engines:
            # Lazy initialization of engines
            url = DB_CONFIG.get(cluster_type, DEFAULT_DB_URL)
            print(f"[DBManager] Initializing engine for {cluster_type} -> {url}")
            self.engines[cluster_type] = create_async_engine(
                url,
                echo=os.getenv("DB_ECHO", "False").lower() == "true",
                future=True,
                pool_pre_ping=False,
                pool_size=20,
                max_overflow=10
            )
        return self.engines[cluster_type]

    async def close_all(self):
        for engine in self.engines.values():
            await engine.dispose()

db_manager = DBManager()

# --- 3. Middleware for Routing Strategy ---

class DBRoutingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Strategy: 
        # - GET requests -> READER (default)
        # - POST/PUT/DELETE -> WRITER
        # - Specific headers can override (e.g. X-DB-Target: analytics)
        
        target = DBClusterType.WRITER # Default safe
        
        method = request.method
        if method == "GET":
            target = DBClusterType.READER
        
        # Header override
        if "X-DB-Target" in request.headers:
            requested_target = request.headers["X-DB-Target"].lower()
            if requested_target in [t.value for t in DBClusterType]:
                target = DBClusterType(requested_target)
                
        # Set context
        token = _db_cluster_ctx.set(target)
        
        try:
            response = await call_next(request)
            return response
        finally:
            _db_cluster_ctx.reset(token)

# --- 4. Session Factory & Dependency ---

async def init_db():
    # Initialize schemas on the WRITER node (others usually replicate)
    writer_engine = db_manager.get_engine(DBClusterType.WRITER)
    async with writer_engine.begin() as conn:
        # await conn.run_sync(SQLModel.metadata.drop_all) 
        await conn.run_sync(SQLModel.metadata.create_all)

async def get_session() -> AsyncSession:
    """
    Dependency to get a session for the current request context.
    Automatically picks the right engine based on Middleware decision.
    """
    cluster_type = _db_cluster_ctx.get()
    engine = db_manager.get_engine(cluster_type)
    
    async_session_factory = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with async_session_factory() as session:
        yield session
