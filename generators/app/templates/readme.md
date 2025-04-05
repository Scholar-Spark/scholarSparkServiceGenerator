# <%= name %>

<%= description %>

## Overview

This is a FastAPI microservice built with Scholar-Spark's developer toolkit:

- FastAPI for the API framework
- Poetry for dependency management
- Docker for containerization
- Kubernetes/Helm for deployment
- Skaffold for local development
- GitHub Actions for CI/CD and Helm chart publishing

## Development Setup

### Prerequisites

- Python 3.9+
- Poetry
- Docker
- Kubernetes (Minikube/Kind)
- Helm
- Skaffold

### Quick Start

1. Set up your development environment:

```bash
./scripts/setup.sh
```

This script will:

1. **Download and Apply Shared Infrastructure** - Apply the Scholar-Spark shared infrastructure manifests to your Kubernetes cluster, including common dependencies needed by all services
2. **Check Dependencies** - Ensure all required tools (`gh`, `git`, `curl`, `tar`, `skaffold`, `kubectl`) are installed
3. **Start Development Environment** - Run `skaffold dev` to:
   - Build your Docker image
   - Deploy to your local Kubernetes cluster
   - Watch for file changes and hot-reload automatically
   - Forward ports for local access

If your Kubernetes context isn't configured, the script will provide instructions to set it up.

### Local Development URLs

- API Documentation: http://localhost:<%= port %>/docs
- Alternative Documentation: http://localhost:<%= port %>/redoc
- Health Check: http://localhost:<%= port %>/health

## Project Structure

```bash
.
├── app/                              # Application source code
│   ├── api/                          # API endpoints  
│   │   └── routes/                   # Route definitions
│   ├── core/                         # Core functionality
│   └── main.py                       # FastAPI application
├── helm/                             # Helm chart for Kubernetes deployment
│   ├── Chart.yaml                    # Chart version and metadata
│   ├── templates/                    # Kubernetes resource templates
│   │   ├── deployment.yaml           # Main application deployment
│   │   ├── service.yaml              # Service for network access
│   │   └── ingress.yaml              # Optional external access (disabled by default)
│   └── values.yaml                   # Default configuration values
├── scripts/                          # Utility scripts
│   ├── setup.sh                      # Development environment setup
│   └── version-updater.sh            # Version management tool
├── tests/                            # Test suite
├── .github/workflows/               # CI/CD pipelines
│   └── helm-release.yaml            # GitHub Actions workflow for Helm release
├── .dockerignore                     # Docker ignore file
├── .gitignore                        # Git ignore file
├── .env                              # Environment variables
├── .env.example                      # Environment variables example
├── Dockerfile                        # Container definition
├── pyproject.toml                    # Python dependencies and project metadata
└── skaffold.yaml                     # Skaffold configuration for development
```

## API Documentation

The API documentation is automatically generated and can be accessed at:

- Swagger UI: `/docs`
- ReDoc: `/redoc`

## Testing

Run the test suite:

```bash
poetry run pytest
```

With coverage:

```bash
poetry run pytest --cov=app
```

## Version Management and Deployment

### How to Use Version Updater

Before releasing a new version, update the version number using the version-updater script:

```bash
./scripts/version-updater.sh
```

This tool will:

1. Read the current version from `helm/Chart.yaml`
2. Prompt you to select a version increment (major, minor, patch) or enter a custom version
3. Update the version in `helm/Chart.yaml` (both `version` and `appVersion` fields)
4. Update the version in `pyproject.toml` (if it exists)
5. Create a git commit with the changes

After running the version updater, you should:

```bash
# Create a tag for the new version
git tag v{version}

# Push the changes and tag
git push origin main
git push origin v{version}
```

### Automatic Chart Publishing

The GitHub Actions workflow (`.github/workflows/helm-release.yaml`) automatically:

1. Triggers when version tags (`v*`) are pushed
2. Extracts the version from `pyproject.toml`
3. Updates the Helm chart version to match
4. Packages the Helm chart
5. Publishes the chart to GitHub Container Registry (GHCR) as an OCI artifact

This ensures your Helm chart is versioned and published consistently with your code releases, making it easy to deploy specific versions to different environments.

## Development Workflow

### 1. Local Development with Skaffold

Skaffold provides a seamless development experience:

```bash
# Start development mode
skaffold dev
```

This will:
- Build the Docker image with your code
- Deploy to your local Kubernetes cluster using Helm
- Forward the service port to your localhost
- Watch for file changes and update the running container

The `portForward` configuration in `skaffold.yaml` ensures your service is accessible at `http://localhost:<%= port %>`.

### 2. Versioning and Release

When your changes are ready for release:

1. Update the version using `./scripts/version-updater.sh`
2. Push the changes and tag
3. GitHub Actions will automatically build and publish the Helm chart

### 3. Production Deployment

For production environments:

```bash
# Deploy a specific version to production
helm upgrade --install <%= serviceName %> oci://ghcr.io/scholar-spark/<%= serviceName %> --version X.Y.Z --namespace production
```

You can also create version-specific values files for different environments in the `helm/` directory:

- `values-staging.yaml`
- `values-production.yaml`

And use them during deployment:

```bash
helm upgrade --install <%= serviceName %> oci://ghcr.io/scholar-spark/<%= serviceName %> \
  --version X.Y.Z \
  -f values-production.yaml \
  --namespace production
```

## Maintainers

- <%= author %> (<%= email %>)

## License

MIT
