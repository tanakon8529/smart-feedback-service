import asyncio
import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlmodel import SQLModel
from app.main import app
from app.core.database import db_manager, DBClusterType
from sqlalchemy.orm import sessionmaker
from sqlmodel.ext.asyncio.session import AsyncSession


@pytest_asyncio.fixture(scope="module")
async def db_session():
    writer_engine = db_manager.get_engine(DBClusterType.WRITER)
    async with writer_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    async_session = sessionmaker(writer_engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as session:
        yield session
    async with writer_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.drop_all)

@pytest_asyncio.fixture(scope="function")
async def client():
    async with AsyncClient(base_url="http://localhost:8000") as c:
        yield c
