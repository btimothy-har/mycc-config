---
name: git-commit
description: Use when committing code changes. Covers conventional commit format, commit structure, best practices, and pre-commit validation. Triggers on commit requests, git add/commit operations, or when reviewing changes before committing.
---

# Git Commit

Use conventional commits for consistent, parseable history. Follow atomic commit principles.

## Principles

**Commits**
- **Atomic commits** - Each commit is one logical change that can be reverted independently
- **Conventional format** - Use `type(scope): summary` for consistent, parseable history
- **Imperative mood** - "Add feature" not "Added feature" or "Adds feature"
- **Explain why in body** - Summary says what; body explains why and notes tradeoffs

## Commit Format

```
type(scope)!: short summary

Optional body explaining what and why, not how.
Wrap lines at ~72 characters.

Footer with references and metadata.
```

### Types

| Type | Use For |
|------|---------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `perf` | Performance improvement |
| `refactor` | Code change that neither fixes nor adds |
| `docs` | Documentation only |
| `style` | Formatting, whitespace (no code change) |
| `test` | Adding or updating tests |
| `build` | Build system or dependencies |
| `ci` | CI/CD configuration |
| `chore` | Maintenance tasks |
| `revert` | Reverting previous commit |

### Scopes

Use folder, package, or domain: `api`, `app`, `db`, `data`, `infra`, `deps`, `tests`, `docs`, `security`, `ui`, `pipeline`, `auth`, `users`

### Examples

```bash
# Feature
git commit -m "feat(api): add user export endpoint"

# Bug fix with issue reference
git commit -m "fix(auth): prevent nil pointer on login

The session lookup was not checking for missing tokens
before dereferencing.

Closes #234"

# Breaking change (note the !)
git commit -m "feat(api)!: require API key for all endpoints

BREAKING CHANGE: All API requests now require authentication.
Unauthenticated requests return 401."

# With co-author
git commit -m "feat(ui): add dark mode toggle

Co-authored-by: Jane Smith <jane@example.com>"
```

## Pre-Commit Checklist

Before committing:

```bash
# Check for related issues
gh issue list --search "keyword"

# Review staged changes
git diff --staged

# Run tests
uv run pytest

# Run linting
uv run ruff check .
```

## GitHub CLI for Issues

```bash
# List open issues
gh issue list

# Search issues
gh issue list --search "rate limit"

# View issue details
gh issue view 123

# Create issue
gh issue create --title "Bug: login fails" --body "Description..."
```
