#!/bin/bash

# Script to copy claude configuration to $HOME/.claude
# Replaces existing files but does not delete existing files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SRC="$SCRIPT_DIR/claude"
CLAUDE_DEST="$HOME/.claude"

echo "Installing Claude configuration..."
echo "Source: $CLAUDE_SRC"
echo "Destination: $CLAUDE_DEST"

# Create destination directory if it doesn't exist
mkdir -p "$CLAUDE_DEST"

# Copy individual files
echo "Copying configuration files..."
cp "$CLAUDE_SRC/settings.json" "$CLAUDE_DEST/"
cp "$CLAUDE_SRC/CLAUDE.md" "$CLAUDE_DEST/"
cp "$CLAUDE_SRC/claude-powerline.json" "$CLAUDE_DEST/"

# Copy directories (replace files but don't delete existing ones)
echo "Copying directories..."

# Copy agents directory
if [ -d "$CLAUDE_SRC/agents" ]; then
    mkdir -p "$CLAUDE_DEST/agents"
    cp -r "$CLAUDE_SRC/agents/"* "$CLAUDE_DEST/agents/"
fi

# Copy commands directory
if [ -d "$CLAUDE_SRC/commands" ]; then
    mkdir -p "$CLAUDE_DEST/commands"
    cp -r "$CLAUDE_SRC/commands/"* "$CLAUDE_DEST/commands/"
fi

# Copy hook_input directory
if [ -d "$CLAUDE_SRC/hook_input" ]; then
    mkdir -p "$CLAUDE_DEST/hook_input"
    cp -r "$CLAUDE_SRC/hook_input/"* "$CLAUDE_DEST/hook_input/"
fi

# Copy output-styles directory
if [ -d "$CLAUDE_SRC/output-styles" ]; then
    mkdir -p "$CLAUDE_DEST/output-styles"
    cp -r "$CLAUDE_SRC/output-styles/"* "$CLAUDE_DEST/output-styles/"
fi

# Copy scripts directory
if [ -d "$CLAUDE_SRC/scripts" ]; then
    mkdir -p "$CLAUDE_DEST/scripts"
    cp -r "$CLAUDE_SRC/scripts/"* "$CLAUDE_DEST/scripts/"
    # Make scripts executable
    chmod +x "$CLAUDE_DEST/scripts/"*.sh
fi

echo "Claude configuration installed successfully!"