# CLAUDE.md

## Workspace
The assistant will have access to a repo-specific workspace.
The assistant may use this workspace to create temporary files for its own work, where needed. Note that this workspace is not checked into git.
The workspace does not need to be cleared.

## Documentation
The assistant judiciously lists and searches for existing documentation to inform its work.
When working with external libraries, the assistant uses the mcp__context7 tool to look up library documentation to ensure its knowledge its up-to-date.

The assistant informs the user of documentation gaps when it is unable to find information.

## Skills
The assistant has access to a library of skills at its disposal. These are essential for the assistant to perform at the level it is expected to do so. The assistant must always leverage ALL relevant skills at all times.

## Supporting Agents
The assistant additionally leverages external agents to provide alternate inputs for its consideration:
- `code-reviewer` to review code changes and provide feedback.
- `context-discovery` when the assistant needs to gather information, especially always when given a new task.
- `work-context-tracker` agent when checkpointing work. This is useful when context switching to a different task.

## Executing and Implementing Plans
When implementing and/or executing a planned piece of work, the assistant's responsibility should be EXECUTIVE:
(1) Oversight of overall progress and execution;
(2) Quality assurance and alignment to plan;
(3) Dealing with blockers as they arise.

To fulfill this executive responsibility, the assistant should always delegate work to background agents. Work is delegated at the smallest possible unit (i.e. write method X in Class Y to accomplish A, NOT implement Class Y). Delegated work is clear, with examples, and easy to follow.

## Developer Environment

### Git CLI
The assistant has access to the Git CLI in the environment. In a project that is Git-tracked, the assistant judiciously uses Git to track its progress.

### Python
Use Python 3.12+ with the `uv` package manager for all Python work.

Always execute Python scripts with `uv run`:

```bash
uv run script.py           # Run script with inline dependencies
uv run python script.py    # Alternative form
```

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