# cloudflared-armv5

Docker image for Cloudflare Tunnel (cloudflared) built for ARMv5 architecture.

## About

This repository automatically builds Docker images for cloudflared targeting ARMv5 devices. The workflow monitors the [official cloudflared repository](https://github.com/cloudflare/cloudflared) for new releases and automatically builds and publishes Docker images.

## Docker Image

The Docker images are available on Docker Hub:
- `vyzu/cloudflared-armv5:latest` - Latest version
- `vyzu/cloudflared-armv5:<version>` - Specific version tags

## Usage

```bash
docker run -d \
  -e TUNNEL_TOKEN="your_tunnel_token_here" \
  vyzu/cloudflared-armv5:latest
```

## Build Workflow

The build workflow (`.github/workflows/build.yml`) runs automatically:
- **Daily**: At midnight UTC (checks for new cloudflared releases)
- **Manual**: Can be triggered on-demand

### Manually Triggering the Workflow

#### Option 1: GitHub Web UI
1. Go to the [Actions tab](../../actions)
2. Select "Check for Cloudflared Releases and Build Docker Image" workflow
3. Click "Run workflow" button
4. Select the branch and click "Run workflow"

#### Option 2: GitHub CLI
If you have the [GitHub CLI](https://cli.github.com/) installed:

```bash
gh workflow run build.yml
```

Or use the helper script:

```bash
./trigger-build.sh
```

#### Option 3: GitHub API
Using curl:

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/zvyzu/cloudflared-armv5/actions/workflows/build.yml/dispatches \
  -d '{"ref":"master"}'
```

## Build Process

The build process involves:

1. **Version Check**: Monitors cloudflared releases
2. **Go Toolchain Build**: Multi-stage bootstrap process
   - Stage 0: Download Go 1.20.7 binary (amd64)
   - Stage 1: Build Go 1.22.6 from source
   - Stage 2: Build required Go version for ARMv5
3. **Docker Build**: Cross-compile cloudflared for ARMv5
4. **Publish**: Push to Docker Hub
5. **Release**: Create GitHub release and tag

## Local Building

To build locally:

```bash
# Build Go toolchain for ARMv5 (this takes time!)
./build-cloudflared-armv5.sh <cloudflared_version>

# Build Docker image
docker build \
  --build-arg CLOUDFLARED_VERSION=<version> \
  --build-arg GO_TOOLCHAIN_TARBALL=<tarball_name> \
  -t cloudflared-armv5:local .
```

## Requirements

For the GitHub Actions workflow:
- Repository secrets:
  - `DOCKER_USERNAME`: Docker Hub username
  - `DOCKERHUB_TOKEN`: Docker Hub access token
  - `GITHUB_TOKEN`: Automatically provided by GitHub Actions

## License

This repository contains build scripts and configurations. Cloudflared itself is licensed by Cloudflare.
