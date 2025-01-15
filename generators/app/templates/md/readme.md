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

2. Start local development with Skaffold:

```bash
skaffold dev
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

## Deployment

### Local Kubernetes

The service is configured to run in Kubernetes using Helm and Skaffold.

Development mode with hot reload

skaffold dev

One-time deployment

skaffold run

### Production Deployment

1. Package the Helm chart:

```bash
./scripts/package.sh
```

2. Deploy to your cluster:

```bash
helm install <%= name %> oci://${HELM_REGISTRY}/charts/<%= name %> --version <version>
```

## Configuration

Configuration is handled through environment variables:

| Variable    | Description            | Default     |
| ----------- | ---------------------- | ----------- |
| PORT        | Service port           | <%= port %> |
| LOG_LEVEL   | Logging level          | INFO        |
| ENVIRONMENT | Deployment environment | development |

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests
4. Submit a pull request

## Maintainers

- <%= author %> (<%= email %>)

## License

MIT
