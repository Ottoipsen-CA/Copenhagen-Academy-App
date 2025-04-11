# Football Academy API Tests

This directory contains test files for the Football Academy API endpoints.

## Setup

All necessary testing dependencies are specified in the root `requirements.txt` file. Make sure they are installed:

```bash
pip install -r ../requirements.txt
```

## Running Tests

### Run all tests

From the backend directory:

```bash
pytest
```

Or with coverage:

```bash
pytest --cov=.
```

### Run specific test files

```bash
pytest tests/test_api.py
```

### Run tests with markers

```bash
# Run only unit tests
pytest -m "unit"

# Run only integration tests
pytest -m "integration"

# Skip slow tests
pytest -m "not slow"
```

## Test Structure

- `conftest.py`: Contains common fixtures for all tests
- `test_api.py`: Tests for API endpoints
- `utils.py`: Utility functions to support testing
- `run_all_tests.py`: Convenience script to run all tests with coverage

## Creating New Tests

When adding new endpoints, you should add corresponding tests in the test_api.py file or create a new test file for complex endpoint groups.

For authenticated endpoints, use the `get_auth_header` utility from `utils.py`:

```python
from tests.utils import get_auth_header

def test_protected_endpoint(client):
    auth_header = get_auth_header(client)
    response = client.get("/api/v2/protected-endpoint", headers=auth_header)
    assert response.status_code == 200
```

## Test Database

Tests use an in-memory SQLite database to ensure they don't affect the production database. The database is recreated for each test function to ensure test isolation. 