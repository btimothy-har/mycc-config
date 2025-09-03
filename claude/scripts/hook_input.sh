#!/bin/bash

json_input=$(cat)

# Extract hook event name and cwd from JSON input
hook_event_name=$(echo "$json_input" | jq -r '.hook_event_name')
cwd=$(echo "$json_input" | jq -r '.cwd')

# Get the repository name (basename of the git root directory)
if git -C "$cwd" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    repo_root=$(git -C "$cwd" rev-parse --show-toplevel)
    repo_name=$(basename "$repo_root")
else
    repo_name=""
fi

# Define potential prompt file paths (repo-specific first, then default)
repo_specific_file="$HOME/.claude/hook_input/$hook_event_name/$repo_name.md"
default_file="$HOME/.claude/hook_input/$hook_event_name/default.md"

# Determine which file to use
prompt_file=""
if [[ -n "$repo_name" && -f "$repo_specific_file" ]]; then
    prompt_file="$repo_specific_file"
elif [[ -f "$default_file" ]]; then
    prompt_file="$default_file"
fi

echo "DEBUG: $prompt_file"
# Read the prompt content if file exists
system_message=""
if [[ -n "$prompt_file" ]]; then
    system_message=$(<"$prompt_file")
fi

# Return JSON output
json_output=$(jq -n \
    --arg systemMessage "$system_message" \
    '{
        continue: true,
        stopReason: "",
        suppressOutput: false,
        systemMessage: $systemMessage
    }')

echo "$json_output"
exit 0
