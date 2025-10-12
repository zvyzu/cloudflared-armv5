#!/bin/bash
# Script to validate that all prerequisites for the build workflow are met

set -e

echo "=== Validating Build Workflow Prerequisites ==="
echo ""

# Check Python
echo "✓ Checking Python..."
python3 --version || { echo "✗ Python 3 not found"; exit 1; }

# Check Python requests module
echo "✓ Checking Python requests module..."
python3 -c "import requests" 2>/dev/null || { echo "✗ requests module not installed. Run: pip install requests"; exit 1; }

# Check YAML syntax
echo "✓ Validating workflow YAML syntax..."
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build.yml'))" || { echo "✗ Invalid YAML syntax"; exit 1; }

# Check required files exist
echo "✓ Checking required files..."
for file in "Dockerfile" "build-cloudflared-armv5.sh" "latest_version.txt"; do
    if [ ! -f "$file" ]; then
        echo "✗ Required file missing: $file"
        exit 1
    fi
done

# Check build script is executable
echo "✓ Checking build script permissions..."
if [ ! -x "build-cloudflared-armv5.sh" ]; then
    echo "✗ build-cloudflared-armv5.sh is not executable"
    echo "  Run: chmod +x build-cloudflared-armv5.sh"
    exit 1
fi

# Validate Dockerfile syntax (basic check)
echo "✓ Validating Dockerfile syntax..."
if ! grep -q "^FROM " Dockerfile; then
    echo "✗ Dockerfile appears invalid (no FROM instruction)"
    exit 1
fi

# Check for required environment variables in workflow
echo "✓ Checking workflow configuration..."
if ! grep -q "DOCKER_USERNAME" .github/workflows/build.yml; then
    echo "⚠ Warning: Workflow expects DOCKER_USERNAME secret"
fi
if ! grep -q "DOCKERHUB_TOKEN" .github/workflows/build.yml; then
    echo "⚠ Warning: Workflow expects DOCKERHUB_TOKEN secret"
fi

# Test version check logic (without authentication, will show rate limit is expected)
echo "✓ Testing version check logic (rate limits expected without auth)..."
python3 - <<'EOF' || echo "  ⚠ Note: GitHub API rate limit is expected without authentication token"
import requests
import sys

try:
    response = requests.get(
        'https://api.github.com/repos/cloudflare/cloudflared/releases/latest',
        timeout=10
    )
    if response.status_code == 200:
        data = response.json()
        latest_version = data.get('tag_name')
        if latest_version:
            print(f"  Latest cloudflared version: {latest_version}")
        else:
            print("  ⚠ Could not parse version from GitHub API")
    elif response.status_code == 403:
        print("  ⚠ GitHub API rate limited (this is expected without auth)")
    else:
        print(f"  ⚠ GitHub API returned: {response.status_code}")
except Exception as e:
    print(f"  ⚠ Exception: {e}")
EOF

echo ""
echo "=== Prerequisites Check Complete ==="
echo ""
echo "✓ All critical prerequisites are met!"
echo ""
echo "To trigger the workflow:"
echo "  1. GitHub UI: https://github.com/zvyzu/cloudflared-armv5/actions"
echo "  2. GitHub CLI: gh workflow run build.yml"
echo "  3. Helper script: ./trigger-build.sh"
echo ""
echo "Required secrets for workflow to complete successfully:"
echo "  - DOCKER_USERNAME: Your Docker Hub username"
echo "  - DOCKERHUB_TOKEN: Your Docker Hub access token"
echo "  - GITHUB_TOKEN: Automatically provided by GitHub Actions"
