---
name: python-testing
description: Use when writing or running Python tests with pytest. Covers fixtures, mocking, parametrization, freezegun for time, and async testing. Triggers on test file creation, fixture design, mocking external dependencies, or test suite architecture. Extends python-development skill.
---

# Python Testing

Extends the `python-development` skill. Use pytest for all testing.

## Principles

**Test Design**
- **Isolate tests** - No test depends on another test's state or execution order
- **Mock external dependencies** - Never make real network calls, database connections to production, or filesystem writes outside tmp_path
- **Freeze time** - Use freezegun for any datetime-dependent logic
- **One behavior per test** - Each test verifies a single specific behavior or edge case
- **Descriptive names** - `test_create_user_raises_on_duplicate_email` not `test_create_user_2`

**Fixtures**
- **Reusable fixtures** - Design fixtures for reuse; use `conftest.py` for shared, inline for test-specific
- **Appropriate scope** - Use `session` for expensive setup (DB engine), `function` for test isolation (sessions, data)
- **Fixture factories** - Create factory fixtures when tests need similar objects with variations
- **Prefer pytest builtins** - Use `tmp_path`, `monkeypatch`, `capsys`, `caplog` before custom solutions

**Mocking**
- **Patch where used** - Mock at `myapp.service.requests.get`, not `requests.get`
- **Verify interactions** - Use `assert_called_once_with` when the call itself is the behavior being tested
- **Use `side_effect` for sequences** - Return different values on successive calls or raise exceptions

**Organization**
- **Mirror source structure** - `tests/test_users.py` tests `myapp/users.py`
- **Parametrize over duplication** - Use `@pytest.mark.parametrize` instead of copy-pasting tests
- **Group with classes** - Use test classes to group related tests and share class-scoped fixtures

## Running Tests

```bash
uv run pytest                          # Run all tests
uv run pytest tests/test_api.py        # Single file
uv run pytest -k "test_create"         # Match test names
uv run pytest -x                       # Stop on first failure
uv run pytest --tb=short               # Shorter tracebacks
uv run pytest -v --tb=long             # Verbose with full tracebacks
```

## Project Dependencies

```toml
# pyproject.toml
[project.optional-dependencies]
dev = [
    "pytest",
    "pytest-asyncio",
    "pytest-mock",
    "freezegun",
    "httpx",  # For FastAPI TestClient
]
```

## Basic Test Structure

```python
# tests/test_users.py
import pytest
from myapp.users import create_user, get_user

class TestCreateUser:
    def test_creates_user_with_valid_email(self, db_session):
        user = create_user(db_session, email="test@example.com", name="Test")
        
        assert user.id is not None
        assert user.email == "test@example.com"

    def test_raises_on_duplicate_email(self, db_session, existing_user):
        with pytest.raises(ValueError, match="already exists"):
            create_user(db_session, email=existing_user.email, name="Other")
```

## Fixtures

### conftest.py for Shared Fixtures

```python
# tests/conftest.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from myapp.database import Base

@pytest.fixture(scope="session")
def engine():
    """Create test database engine once per session."""
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    yield engine
    engine.dispose()

@pytest.fixture
def db_session(engine):
    """Fresh database session for each test, rolled back after."""
    connection = engine.connect()
    transaction = connection.begin()
    Session = sessionmaker(bind=connection)
    session = Session()
    
    yield session
    
    session.close()
    transaction.rollback()
    connection.close()

@pytest.fixture
def existing_user(db_session):
    """Pre-created user for tests that need one."""
    from myapp.models import User
    user = User(email="existing@example.com", name="Existing")
    db_session.add(user)
    db_session.commit()
    return user
```

### Fixture Factories

```python
@pytest.fixture
def make_user(db_session):
    """Factory to create users with custom attributes."""
    created = []
    
    def _make_user(email="test@example.com", name="Test", **kwargs):
        from myapp.models import User
        user = User(email=email, name=name, **kwargs)
        db_session.add(user)
        db_session.commit()
        created.append(user)
        return user
    
    yield _make_user
    
    # Cleanup if needed
    for user in created:
        db_session.delete(user)
    db_session.commit()
```

## Mocking

### Patch External Services

```python
from unittest.mock import patch, MagicMock

class TestPaymentProcessor:
    def test_processes_payment_successfully(self):
        # Patch where it's USED, not where it's defined
        with patch("myapp.payments.stripe.Charge.create") as mock_charge:
            mock_charge.return_value = MagicMock(id="ch_123", status="succeeded")
            
            result = process_payment(amount=1000, token="tok_visa")
            
            assert result.charge_id == "ch_123"
            mock_charge.assert_called_once_with(amount=1000, source="tok_visa")

    def test_handles_payment_failure(self):
        with patch("myapp.payments.stripe.Charge.create") as mock_charge:
            mock_charge.side_effect = stripe.error.CardError("declined", None, None)
            
            with pytest.raises(PaymentError, match="declined"):
                process_payment(amount=1000, token="tok_bad")
```

### pytest-mock (Cleaner Syntax)

```python
def test_sends_welcome_email(mocker):
    mock_send = mocker.patch("myapp.users.send_email")
    
    create_user(email="new@example.com", name="New")
    
    mock_send.assert_called_once_with(
        to="new@example.com",
        template="welcome",
    )
```

### Mock HTTP Requests

```python
def test_fetches_external_data(mocker):
    mock_response = mocker.Mock()
    mock_response.json.return_value = {"data": "value"}
    mock_response.raise_for_status = mocker.Mock()
    
    mocker.patch("httpx.get", return_value=mock_response)
    
    result = fetch_external_data("https://api.example.com")
    
    assert result == {"data": "value"}
```

## Freezegun for Time

```python
from freezegun import freeze_time
from datetime import datetime

class TestSubscription:
    @freeze_time("2024-01-15 10:00:00")
    def test_subscription_active_before_expiry(self):
        sub = Subscription(expires_at=datetime(2024, 1, 20))
        assert sub.is_active() is True

    @freeze_time("2024-01-25 10:00:00")
    def test_subscription_inactive_after_expiry(self):
        sub = Subscription(expires_at=datetime(2024, 1, 20))
        assert sub.is_active() is False

    def test_trial_duration(self):
        with freeze_time("2024-01-01") as frozen:
            trial = start_trial()
            assert trial.days_remaining == 14
            
            frozen.tick(delta=timedelta(days=7))
            assert trial.days_remaining == 7
```

## Parametrized Tests

```python
@pytest.mark.parametrize("email,valid", [
    ("user@example.com", True),
    ("user@sub.example.com", True),
    ("invalid", False),
    ("@example.com", False),
    ("user@", False),
    ("", False),
])
def test_email_validation(email, valid):
    assert is_valid_email(email) == valid


@pytest.mark.parametrize("a,b,expected", [
    (1, 2, 3),
    (0, 0, 0),
    (-1, 1, 0),
    (100, 200, 300),
])
def test_addition(a, b, expected):
    assert add(a, b) == expected
```

## Async Testing

```python
import pytest

# Mark entire module as async
pytestmark = pytest.mark.asyncio

async def test_async_fetch(db_session):
    result = await fetch_user_async(db_session, user_id=1)
    assert result.name == "Test"


# Or mark individual tests
class TestAsyncOperations:
    @pytest.mark.asyncio
    async def test_concurrent_requests(self):
        results = await asyncio.gather(
            fetch_data("endpoint1"),
            fetch_data("endpoint2"),
        )
        assert len(results) == 2
```

## FastAPI Testing

```python
import pytest
from httpx import AsyncClient, ASGITransport
from myapp.main import app

@pytest.fixture
async def client():
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test"
    ) as client:
        yield client

@pytest.mark.asyncio
async def test_create_user_endpoint(client):
    response = await client.post("/users", json={"email": "a@b.com", "name": "A"})
    
    assert response.status_code == 201
    assert response.json()["email"] == "a@b.com"

@pytest.mark.asyncio
async def test_get_user_not_found(client):
    response = await client.get("/users/99999")
    
    assert response.status_code == 404
```

## Test File Organization

```
tests/
├── conftest.py          # Shared fixtures
├── test_models.py       # Unit tests for models
├── test_services.py     # Unit tests for business logic
├── test_api.py          # API endpoint tests
└── integration/
    ├── conftest.py      # Integration-specific fixtures
    └── test_workflows.py
```