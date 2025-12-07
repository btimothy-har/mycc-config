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
    msg="No branch found"
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

workspace_dir="$repo_root/.claude/workspace/$branch_name"
mkdir -p "$workspace_dir"

json_output=$(jq -n \
    --arg hookEventName "UserPromptSubmit" \
    --arg additionalContext "The assistant's workspace is at $workspace_dir" \
    '{
      hookSpecificOutput: {
        hookEventName: $hookEventName,
        additionalContext: $additionalContext
      }
    }')
echo "$json_output"
exit 0
