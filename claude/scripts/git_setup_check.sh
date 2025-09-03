#!/bin/bash

json_input=$(cat)

# Extract cwd and check if it's a git repository
cwd=$(echo "$json_input" | jq -r '.cwd')
if ! git -C "$cwd" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    # Not in a git repository - output JSON to stop execution
    msg="Not in a git repository"
    json_output=$(jq -n \
        --arg decision "block" \
        --arg reason "$msg" \
        --arg hookEventName "UserPromptSubmit" \
        --arg additionalContext "$msg" \
        '{
          decision: $decision,
          reason: $reason,
          hookSpecificOutput: {
            hookEventName: $hookEventName,
            additionalContext: $additionalContext
          }
        }')
    echo "$json_output"
    exit 2
fi

# Get the repository name (basename of the git root directory)
repo_root=$(git -C "$cwd" rev-parse --show-toplevel)
repo_name=$(basename "$repo_root")

# Get the current branch name
branch_name=$(git -C "$cwd" branch --show-current)
# If detached HEAD or no branch, use a default
if [ -z "$branch_name" ]; then
    branch_name="detached"
fi

# Determine workspace directory with priority order:
# 1) CLAUDE_WORKSPACE environment variable if set
# 2) .cursor/workspace in the repo if it exists
# 3) Default to ~/.claude/workspace/$repo_name

if [ -n "$CLAUDE_WORKSPACE" ]; then
    # Priority 1: Environment variable
    workspace_dir="$CLAUDE_WORKSPACE"
elif [ -d "$repo_root/.cursor/workspace" ]; then
    # Priority 2: .cursor/workspace folder in the repo
    workspace_dir="$repo_root/.cursor/workspace"
else
    # Priority 3: Default location
    workspace_dir="$HOME/.claude/workspace/$repo_name"
fi

branch_dir="$workspace_dir/$branch_name"
mkdir -p "$branch_dir"

json_output=$(jq -n \
    --arg hookEventName "UserPromptSubmit" \
    --arg additionalContext "The assistant's workspace is at $branch_dir" \
    '{
      hookSpecificOutput: {
        hookEventName: $hookEventName,
        additionalContext: $additionalContext
      }
    }')
echo "$json_output"
exit 2

# All good - continue execution
exit 0
