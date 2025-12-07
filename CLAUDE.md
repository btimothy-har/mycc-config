# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a personal Claude Code configuration organized as a local plugin marketplace. It provides custom agents, skills, commands, and hooks that extend Claude Code's capabilities.

### Plugin Architecture

Four plugin types work together to enhance Claude Code:

1. **brian-claude-agents**: Autonomous agents for specialized tasks
   - `code-reviewer`: Reviews code changes against project standards
   - `context-discovery`: Expands task descriptions into comprehensive scope analysis
   - `work-context-tracker`: Captures and contextualizes work progress

2. **brian-claude-skills**: Domain-specific expertise modules
   - `python-development`: Core Python patterns with uv package management
   - `python-backend`: FastAPI, SQLAlchemy, PostgreSQL backend development
   - `python-testing`: pytest patterns with fixtures and mocking
   - `git-commit`: Conventional commit format and commit best practices
   - `git-pull-request`: PR structure, GitHub CLI, and review workflow
   - `code-documentation`: Docstrings (Google style), README, and ADR patterns
   - `sql`: PostgreSQL query patterns and optimization

3. **brian-claude-commands**: Custom slash commands
   - `/commit`: Intelligent git commit workflow with issue linking
   - `/pullrequest`: PR creation with generated descriptions

4. **brian-claude-hooks**: Event-driven automation
   - `SessionStart`: Injects session context from SessionStart.md
   - `UserPromptSubmit`: Sets up branch-specific workspace at `.claude/<branch_name>`
   - `PreToolUse`: Validates GPG configuration before git operations

### Workspace Management

The hooks automatically create a branch-specific workspace at:
```
.claude/<branch_name>/
```

This workspace is:
- Created automatically on first prompt in a git repository
- Branch-isolated (different branches have separate workspaces)
- Not tracked in git (listed in .gitignore)
- Available for temporary working files

## Plugin Structure

Each plugin follows a consistent directory layout:

```
brian-claude-<type>/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── <type>/                  # agents/, skills/, commands/, or hooks-scripts/
│   └── <name>.md            # Plugin definitions
└── (hooks only) hooks/
    └── hooks.json           # Hook configuration
```

### Agent Definitions

Agents are defined in markdown files with YAML frontmatter:
```markdown
---
name: agent-name
description: When and how to use this agent...
tools: [list, of, tools]
model: opus|sonnet|haiku
color: red
---

Agent system prompt goes here...
```

### Skill Definitions

Skills are defined in `SKILL.md` files with YAML frontmatter:
```markdown
---
name: skill-name
description: When to invoke this skill...
---

# Skill Content

Detailed instructions and patterns...
```

### Command Definitions

Commands are simple markdown files containing the command prompt:
```markdown
Description of what the command does.

#$ARGUMENTS
```

The `#$ARGUMENTS` placeholder receives any arguments passed to the command.

### Hook Configuration

Hooks are configured in `hooks/hooks.json`:
```json
{
  "hooks": {
    "HookEventName": [
      {
        "matcher": "optional-regex",
        "hooks": [
          {
            "type": "command",
            "command": "shell command to execute"
          }
        ]
      }
    ]
  }
}
```

Hook scripts receive JSON input via stdin and output JSON results via stdout.

## Development Workflow

### Working with Agents

Agents should be invoked using the Task tool:
- After completing code changes (code-reviewer)
- At the start of new tasks (context-discovery)
- Before context switches (work-context-tracker)

### Working with Skills

Skills are invoked via the Skill tool when domain-specific expertise is needed:
- Python development tasks → python-development, python-backend, or python-testing
- Git commits → git-commit
- Pull requests → git-pull-request
- Documentation → code-documentation
- Database queries → sql

Skills are automatically activated when relevant to the task context.

### Testing Changes

When modifying plugins:

1. **Validate JSON syntax** in plugin.json and hooks.json files
2. **Test agent prompts** by invoking them in a sample repository
3. **Verify hook scripts** by checking their JSON input/output handling
4. **Check skill formatting** ensuring YAML frontmatter is valid

### Installing Plugins

This repository acts as a local marketplace. To install:

1. Ensure the repository is available at a stable path
2. Add the marketplace in Claude Code settings
3. Install desired plugins individually or all at once

The marketplace definition is in `.claude-plugin/marketplace.json`.

## Hook Script Behavior

### repo_setup.sh
- Validates current directory is a git repository
- Blocks execution if not in a git repo or detached HEAD
- Creates branch-specific workspace at `.claude/<branch_name>`
- Outputs workspace path to additional context

### SessionStart.md injection
- Runs on session startup or `/clear` command
- Adds content from `SessionStart.md` to session context
- Currently defines workspace usage and agent/skill preferences

### git_gpg_check.sh
- Runs before any Bash tool invocation
- Validates GPG signing configuration for git commits
- Prevents commits without proper GPG setup

## Plugin Relationships

The plugins form a cohesive system:

1. **Hooks** set up the environment (workspace, validation)
2. **Agents** perform autonomous analysis (code review, context discovery)
3. **Skills** provide domain expertise (Python, Git, SQL)
4. **Commands** streamline common workflows (commits, PRs)

When making changes, consider how modifications to one plugin might affect others. For example:
- Changes to SessionStart.md affect all sessions
- Updates to git-commit or git-pull-request skills should align with commit/pullrequest command behavior
- Agent tool lists may need updating if new capabilities are added
