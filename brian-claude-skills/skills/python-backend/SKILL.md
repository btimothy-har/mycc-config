---
name: python-backend
description: Use when building Python web APIs, database-backed applications, or backend services. Covers FastAPI, SQLAlchemy (async), PostgreSQL, Alembic migrations, and performance patterns. Triggers on API endpoint creation, database models, query optimization, or migration planning. Extends python-development skill.
---

# Python Backend Development

Extends the `python-development` skill. Use PostgreSQL, FastAPI, and async SQLAlchemy.

## Principles

**Database**
- **Async by default** - Use async SQLAlchemy and async endpoints for all I/O
- **Prevent N+1 queries** - Always eager load relationships with `selectinload` or `joinedload`
- **PostgreSQL features** - Leverage JSONB, arrays, and full-text search when beneficial
- **Connection pooling** - Configure pool_size and max_overflow; use `pool_pre_ping=True`
- **Index intentionally** - Create indexes for filtered/sorted columns; use composite indexes for multi-column queries
- **Bulk operations** - Use `session.add_all()` and `insert().values([...])` for batch processing
- **Raw SQL when needed** - Drop to `text()` queries when ORM adds unnecessary overhead

**Migrations**
- **Migrations are code** - Use Alembic for all schema changes, never manual DDL
- **Backwards-compatible** - Design migrations that work with both old and new application code
- **Rollback strategy** - Every migration should have a working downgrade path
- **Separate data migrations** - Handle data transformations in separate migrations from schema changes

**API Design**
- **RESTful conventions** - Proper HTTP methods, status codes, and resource naming
- **Consistent errors** - Use structured error responses with error codes and messages
- **Paginate lists** - All list endpoints return paginated results with limit/offset or cursors
- **Validate inputs** - Use Pydantic models for request validation; fail fast on bad data
- **Document with OpenAPI** - Leverage FastAPI's automatic OpenAPI generation; add descriptions

**Performance**
- **Profile first** - Use `EXPLAIN ANALYZE` before optimizing queries
- **Cache strategically** - Cache expensive queries; invalidate on writes
- **Minimize round-trips** - Batch database operations; avoid loops with queries inside

**Security**
- **Parameterized queries only** - Never use f-strings or `.format()` in SQL; use bound parameters
- **Validate and sanitize inputs** - Trust nothing from the client; validate types, lengths, and formats
- **Hash passwords properly** - Use bcrypt or argon2; never store plaintext or weak hashes
- **Authenticate then authorize** - Verify identity first, then check permissions for the resource
- **Rate limit endpoints** - Protect auth endpoints and expensive operations from abuse

## Project Dependencies

```toml
# pyproject.toml
[project]
dependencies = [
    "fastapi",
    "uvicorn[standard]",
    "sqlalchemy[asyncio]",
    "asyncpg",
    "alembic",
    "pydantic",
    "pydantic-settings",
]
```

## FastAPI Application

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from .database import get_session
from .models import User
from .schemas import UserCreate, UserResponse

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: initialize DB pool
    yield
    # Shutdown: cleanup

app = FastAPI(lifespan=lifespan)

@app.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(user: UserCreate, session: AsyncSession = Depends(get_session)):
    db_user = User(**user.model_dump())
    session.add(db_user)
    await session.commit()
    await session.refresh(db_user)
    return db_user

@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, session: AsyncSession = Depends(get_session)):
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

## Async SQLAlchemy Setup

```python
# database.py
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

DATABASE_URL = "postgresql+asyncpg://user:pass@localhost/dbname"

engine = create_async_engine(
    DATABASE_URL,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,
)

AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)

class Base(DeclarativeBase):
    pass

async def get_session() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session
```

## Model Patterns

```python
# models.py
from datetime import datetime
from sqlalchemy import String, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from .database import Base

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(100))
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    posts: Mapped[list["Post"]] = relationship(back_populates="author", lazy="selectin")

class Post(Base):
    __tablename__ = "posts"
    __table_args__ = (
        Index("ix_posts_author_created", "author_id", "created_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    author_id: Mapped[int] = mapped_column(ForeignKey("users.id"))

    author: Mapped["User"] = relationship(back_populates="posts")
```

## Pydantic Schemas

```python
# schemas.py
from pydantic import BaseModel, EmailStr, ConfigDict

class UserCreate(BaseModel):
    email: EmailStr
    name: str

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    name: str
```

## N+1 Query Prevention

```python
from sqlalchemy import select
from sqlalchemy.orm import selectinload, joinedload

# BAD: N+1 queries
users = await session.scalars(select(User))
for user in users:
    print(user.posts)  # Each access triggers a query

# GOOD: Eager load with selectinload (separate IN query)
stmt = select(User).options(selectinload(User.posts))
users = await session.scalars(stmt)

# GOOD: Eager load with joinedload (single JOIN query)
stmt = select(User).options(joinedload(User.posts))
users = await session.scalars(stmt)
```

## Alembic Migrations

```bash
# Initialize
alembic init alembic

# Generate migration
alembic revision --autogenerate -m "add users table"

# Apply migrations
alembic upgrade head

# Rollback one step
alembic downgrade -1
```

Configure `alembic/env.py` for async:

```python
from sqlalchemy.ext.asyncio import async_engine_from_config
import asyncio

def run_async_migrations():
    connectable = async_engine_from_config(config.get_section(config.config_ini_section))

    async def do_run():
        async with connectable.connect() as connection:
            await connection.run_sync(do_run_migrations)
        await connectable.dispose()

    asyncio.run(do_run())
```

## PostgreSQL Features

```python
from sqlalchemy import text
from sqlalchemy.dialects.postgresql import JSONB, ARRAY

class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True)
    metadata_: Mapped[dict] = mapped_column("metadata", JSONB, default={})
    tags: Mapped[list[str]] = mapped_column(ARRAY(String), default=[])

# JSONB query
stmt = select(Product).where(Product.metadata_["category"].astext == "electronics")

# Array contains
stmt = select(Product).where(Product.tags.contains(["sale"]))

# Full-text search (use raw SQL for complex cases)
stmt = text("SELECT * FROM products WHERE to_tsvector(name) @@ to_tsquery(:query)")
result = await session.execute(stmt, {"query": "phone"})
```

## Pagination Pattern

```python
from fastapi import Query

@app.get("/posts", response_model=list[PostResponse])
async def list_posts(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    session: AsyncSession = Depends(get_session),
):
    stmt = select(Post).offset(skip).limit(limit).order_by(Post.created_at.desc())
    posts = await session.scalars(stmt)
    return posts.all()
```

## Running the Server

```bash
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```