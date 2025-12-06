---
name: python-development
description: Core Python development skill for scripts, utilities, and general Python code. Covers uv package management, script dependencies, project setup, and coding standards. Use for Python file creation, running scripts, dependency management, or general Python tasks. For web APIs and servers, see python-backend skill. For testing, see python-testing skill.
---

# Python Development

Use Python 3.12+ with the `uv` package manager for all Python work.

## Principles

**Workflow**
- **Understand before coding** - Analyze requirements thoroughly before writing code
- **Clarify ambiguity** - Ask questions when specifications are unclear or incomplete
- **Break down complexity** - Decompose complex problems into smaller, focused functions
- **State assumptions** - When requirements are ambiguous, state assumptions explicitly and proceed

**Code Quality**
- **Google Python Style Guide** - Follow it for formatting, naming, and structure
- **Type hints everywhere** - All function signatures, return types, and complex variables
- **Specific exceptions** - Catch and raise specific exception types, never bare `except:`
- **Context managers** - Use `with` for files, connections, locks, and any resource cleanup
- **No mutable defaults** - Never use `[]` or `{}` as default arguments

**Decision Making**
- **Readability over cleverness** - Clear code beats clever code
- **Simple over complex** - Choose straightforward solutions; add complexity only when justified
- **Stdlib first** - Use Python's standard library before adding external dependencies
- **Minimal dependencies** - Every external package must justify its inclusion

## Running Python

Always execute Python scripts with `uv run`:

```bash
uv run script.py           # Run script with inline dependencies
uv run python script.py    # Alternative form
```

## Script Dependencies

For standalone scripts, include inline metadata at the top of the file:

```python
# /// script
# dependencies = [
#   "httpx",
#   "pandas",
# ]
# requires-python = ">=3.12"
# ///
```

`uv run` automatically installs these dependencies in an isolated environment.

## Project Setup

For multi-file projects, use `pyproject.toml`:

```bash
uv init project-name       # Create new project
uv add package-name        # Add dependency
uv add --dev package       # Add dev dependency
uv sync                    # Install all dependencies
uv run python main.py      # Run within project
```

## Code Standards

Follow Google Python Style Guide:
- Type hints on all functions
- Docstrings for public APIs
- f-strings for formatting
- `pathlib` for file operations
- Context managers for resources
- Specific exception types (not bare `except:`)

## Common Patterns

### CLI Script
```python
# /// script
# dependencies = ["typer"]
# requires-python = ">=3.12"
# ///
import typer

def main(name: str, count: int = 1) -> None:
    """Greet someone COUNT times."""
    for _ in range(count):
        typer.echo(f"Hello, {name}!")

if __name__ == "__main__":
    typer.run(main)
```

### Data Processing
```python
# /// script
# dependencies = ["pandas", "httpx"]
# requires-python = ">=3.12"
# ///
import pandas as pd
import httpx

def fetch_and_process(url: str) -> pd.DataFrame:
    """Fetch JSON data and return as DataFrame."""
    response = httpx.get(url)
    response.raise_for_status()
    return pd.DataFrame(response.json())
```

### Async Operations
```python
# /// script
# dependencies = ["httpx"]
# requires-python = ">=3.12"
# ///
import asyncio
import httpx

async def fetch_all(urls: list[str]) -> list[dict]:
    """Fetch multiple URLs concurrently."""
    async with httpx.AsyncClient() as client:
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks)
        return [r.json() for r in responses]

if __name__ == "__main__":
    results = asyncio.run(fetch_all(["https://api.example.com/1"]))
```

## Library Preferences

| Use Case | Preferred Library |
|----------|------------------|
| HTTP client | httpx |
| Data manipulation | pandas, polars |
| Data validation | pydantic |
| CLI tools | typer, click |
| File paths | pathlib (stdlib) |
| Date/time | datetime, zoneinfo (stdlib) |
| JSON/config | tomllib, json (stdlib) |

## Debugging

When scripts fail:

1. Check dependency spelling and version constraints
2. Run with `uv run --verbose` for detailed output
3. Verify Python version compatibility
4. Test imports interactively: `uv run python -c "import package"`