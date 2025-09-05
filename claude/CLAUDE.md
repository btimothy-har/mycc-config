# CLAUDE.md

## Workspace
The assistant will have access to a repo-specific workspace.
The assistant may use this workspace to create temporary files for its own work, where needed. Note that this workspace is not checked into git.

The workspace does not need to be cleared.

## Documentation
The assistant judiciously lists and searches for existing documentation to inform its work.
When working with external libraries, the assistant uses the mcp__context7 tool to look up library documentation to ensure its knowledge its up-to-date.

The assistant informs the user of documentation gaps when it is unable to find information.

## Completing Tasks
When completing tasks, the assistant shall assign work to the best agent available to complete the task. The assistant provides oversight and guidance to these agents.

- `context-discovery` agent when the assistant needs to gather information, especially always when given a new task.
- `python-backend-engineer` when developing backend layers in Python (e.g. SQLAlchemy, data models, FastAPI, etc).
- `python-test-engineer` agent when developing test suites for Python code.
- `python-engineer-generic` agent when writing Python code, regardless of scope.
- `dbt-data-engineer` agent when working SQL or working with DBT models.
- `work-context-tracker` agent when checkpointing work. This is useful when context switching to a different task.
- `documentation-generator` agent when developing documentation for a given codebase.
- `code-reviewer` when reviewing code changes and providing feedback. This can be used to get feedback on your own code as well.

Work assigned to agents should always be assigned at the smallest unit of work possible.

- [Correct] Writing tests for a specific instance method .v.s. [Incorrect] Writing tests for a whole feature
- [Correct] Writing a method to accomplish X .v.s. [Incorrect] Implementing a whole feature

## Python Environment
You exclusively use `uv` for all Python environment and dependency management:
- Always use `uv run` to execute Python scripts
- Configure project dependencies in pyproject.toml for projects
- For standalone scripts, use inline metadata format with script dependencies
- Specify Python version requirements (prefer Python 3.12)
- Keep dependencies minimal and well-justified

**Script Dependency Format:**
For standalone scripts, always include inline metadata:
```python
# /// script
# dependencies = [
#   "package-name>=version",
# ]
# requires-python = ">=3.12"
# ///
```