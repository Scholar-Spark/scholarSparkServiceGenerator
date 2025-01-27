# <%= name %>

<%= description %>

## Overview

This is a FastAPI microservice built with:

- FastAPI for the API framework
- Poetry for dependency management
- Docker for containerization
- Kubernetes/Helm for deployment
- Skaffold for local development

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

This will:

- Build the Docker image
- Deploy to local Kubernetes cluster
- Watch for changes and hot-reload

### Local Development URLs

- API Documentation: http://localhost:<%= port %>/docs
- Alternative Documentation: http://localhost:<%= port %>/redoc
- Health Check: http://localhost:<%= port %>/health

## Project Structure

```bash
.
├── app/ # Application source code
│ ├── api/ # API endpoints
│ │ └── routes/ # Route definitions
│ ├── core/ # Core functionality
│ └── main.py # FastAPI application
├── helm/ # Helm chart for Kubernetes deployment
├── tests/ # Test suite
├── scripts/ # Scripts
├── .github/workflows/helm-release.yaml # GitHub Actions workflow for Helm release
├── .dockerignore # Docker ignore file
├── .gitignore # Git ignore file
├── .prettierignore # Prettier ignore file
├── .editorconfig # Editorconfig file
├── .env # Environment variables
├── .env.example # Environment variables example
├── Dockerfile # Container definition
├── pyproject.toml # Python dependencies and project metadata
└── skaffold.yaml # Skaffold configuration
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

## Version Management

Before pushing changes to main/master, update the version using verion-updated script in the scripts folder. This will:

1. Update version in pyproject.toml
2. Update version in helm/Chart.yaml
3. Update version in app/main.py
4. Create a git commit and tag

Then you should:

1. Push changes and tag
2. git push origin master
3. git push origin v{version}

The GitHub workflow will automatically:

1. Detect the version from pyproject.toml
2. Package the Helm chart with matching version
3. Push the chart to GitHub Container Registry

## Maintainers

- <%= author %> (<%= email %>)

## License

MIT
