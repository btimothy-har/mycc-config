#!/bin/bash

# Accept file path as first argument
prompt_file="$1"

# Read JSON input from Claude and extract hook event name
json_input=$(cat)
hook_event_name=$(echo "$json_input" | jq -r '.hook_event_name')

# Read the prompt content if file exists
system_message=""
if [[ -f "$prompt_file" ]]; then
    system_message=$(<"$prompt_file")
fi

# Return JSON output
jq -n \
    --arg eventName "$hook_event_name" \
    --arg msg "$system_message" \
    '{hookSpecificOutput: {hookEventName: $eventName, additionalContext: $msg}}'
