#!/bin/bash
# Helper script to trigger the build workflow using GitHub CLI

set -e

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    echo ""
    echo "Alternative methods to trigger the workflow:"
    echo "1. Use GitHub web UI: https://github.com/zvyzu/cloudflared-armv5/actions"
    echo "2. Use curl with GitHub API (see README.md)"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

echo "Triggering build.yml workflow..."

# Trigger the workflow
gh workflow run build.yml

echo "✓ Workflow triggered successfully!"
echo ""
echo "To view workflow runs:"
echo "  gh run list --workflow=build.yml"
echo ""
echo "Or visit: https://github.com/zvyzu/cloudflared-armv5/actions"
