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

# Create the workspace directory and branch subdirectory
# Allow override via CLAUDE_WORKSPACE env var; fallback to original default
workspace_dir="${CLAUDE_WORKSPACE:-$HOME/.claude/workspace/$repo_name}"
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
