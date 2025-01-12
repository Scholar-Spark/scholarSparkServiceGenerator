#!/usr/bin/env node
const Generator = require("yeoman-generator");
const fs = require("fs");
const path = require("path");

// Suppress shelljs warnings
process.env.SUPPRESS_NO_CONFIG_WARNING = "true";

module.exports = class extends Generator {
  prompting() {
    return this.prompt([
      {
        type: "input",
        name: "name",
        message: "Your package name",
        default: "my-package",
      },
      {
        type: "list",
        name: "packageType",
        message: "What type of package are you creating?",
        choices: [
          {
            name: "Basic Package (Simple reusable module)",
            value: "basic",
          },
          {
            name: "CLI Tool (Command-line application)",
            value: "cli",
          },
          {
            name: "Library with API (Reusable library with public API)",
            value: "library",
          },
        ],
        default: "basic",
      },
      {
        type: "input",
        name: "description",
        message: "Package description",
        default: "A Python package",
      },
      {
        type: "input",
        name: "author",
        message: "Author name",
        default: this.user.git.name(),
      },
      {
        type: "input",
        name: "email",
        message: "Author email",
        default: this.user.git.email(),
      },
    ]).then((answers) => {
      this.answers = answers;
      this.packageName = answers.name;
    });
  }

  writing() {
    const baseStructure = {
      "app/api/routes/__init__.py": "",
      "app/api/routes/router.py": this._generateRouterContent(),
      "app/core/__init__.py": "",
      "app/core/config.py": this._generateConfigContent(),
      "app/services/__init__.py": "",
      [`app/services/${this.answers.name.replace(/-/g, "_")}_service.py`]:
        this._generateServiceContent(),
      "app/repositories/__init__.py": "",
      [`app/repositories/${this.answers.name.replace(
        /-/g,
        "_"
      )}_repository.py`]: this._generateRepositoryContent(),
      "app/schemas/__init__.py": "",
      [`app/schemas/${this.answers.name.replace(/-/g, "_")}.py`]:
        this._generateSchemaContent(),
      "app/__init__.py": "",
      "app/main.py": this._generateMainContent(),
      "tests/__init__.py": "",
      "tests/conftest.py": this._generateConfTestContent(),
      "tests/test_api.py": this._generateTestContent(),
      "pyproject.toml": this.generatePyprojectToml(),
      "README.md": this.generateReadme(),
      ".gitignore": this.generateGitignore(),
      Makefile: this.generateMakefile(),
      ".env": this._generateEnvFile(),
      ".env.example": this._generateEnvFile(),
      Dockerfile: this._generateDockerfile(),
      "k8s/base/deployment.yaml": this._generateK8sDeployment(),
      "k8s/base/service.yaml": this._generateK8sService(),
      "k8s/base/ingress.yaml": this._generateK8sIngress(),
      "k8s/base/kustomization.yaml": this._generateBaseKustomization(),
      "k8s/overlays/development/kustomization.yaml":
        this._generateDevKustomization(),
      "k8s/overlays/development/patch.yaml": this._generateDevPatch(),
      "k8s/overlays/production/kustomization.yaml":
        this._generateProdKustomization(),
      "k8s/overlays/production/patch.yaml": this._generateProdPatch(),
      "scripts/setup-dev.sh": this._generateSetupScript(),
      "scripts/start-local.sh": this._generateStartScript(),
      "scripts/deploy-k8s.sh": this._generateDeployScript(),
      "scripts/run-tests.sh": this._generateTestScript(),
      "docker-compose.yml": this._generateDockerCompose(),
      ".dockerignore": this._generateDockerignore(),
      "skaffold.yaml": this._generateSkaffold(),
    };

    Object.entries(baseStructure).forEach(([path, content]) => {
      this.fs.write(this.destinationPath(path), content);
    });

    // Make scripts executable using fs
    const scriptsDir = this.destinationPath("scripts");
    if (fs.existsSync(scriptsDir)) {
      const files = fs.readdirSync(scriptsDir);
      files.forEach((file) => {
        const filePath = path.join(scriptsDir, file);
        fs.chmodSync(filePath, "755");
      });
    }
  }

  generatePyprojectToml() {
    const commonDependencies = {
      python: "^3.9",
    };

    const typeSpecificDependencies = {
      cli: {
        click: "^8.1.3",
        rich: "^13.4.2",
      },
      library: {
        requests: "^2.31.0",
      },
      basic: {},
    };

    const dependencies = {
      ...commonDependencies,
      ...typeSpecificDependencies[this.answers.packageType],
    };

    const depsString = Object.entries(dependencies)
      .map(([pkg, ver]) => `${pkg} = "${ver}"`)
      .join("\n");

    return `[tool.poetry]
name = "${this.packageName}"
version = "0.1.0"
description = "${this.answers.description}"
authors = ["${this.answers.author} <${this.answers.email}>"]
readme = "README.md"
packages = [{include = "${this.packageName}", from = "src"}]

[tool.poetry.dependencies]
${depsString}

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.0"
black = "^23.7.0"
isort = "^5.12.0"
mypy = "^1.4.1"
pytest-cov = "^4.1.0"
pre-commit = "^3.3.3"

${
  this.answers.packageType === "cli"
    ? '[tool.poetry.scripts]\ncli = "' + this.packageName + '.cli:main"\n'
    : ""
}

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 88
target-version = ['py39']
include = '\\.pyi?$'

[tool.isort]
profile = "black"
multi_line_output = 3`;
  }

  generateInit() {
    return `"""
${this.answers.description}
"""

__version__ = "0.1.0"`;
  }

  generateCore() {
    return `"""
Core functionality for ${this.packageName}
"""

class ${this.toPascalCase(this.packageName)}:
    """
    Main class for ${this.packageName}
    """
    def __init__(self):
        pass

    def example_method(self):
        """Example method"""
        return "Hello from ${this.packageName}!"`;
  }

  generateCli() {
    return `import click
from rich import print

@click.group()
def cli():
    """${this.answers.description}"""
    pass

@cli.command()
def hello():
    """Say hello"""
    print("[green]Hello from ${this.packageName}![/green]")

def main():
    cli()

if __name__ == "__main__":
    main()`;
  }

  generateApi() {
    return `"""
Public API for ${this.packageName}
"""

from .core import ${this.toPascalCase(this.packageName)}

__all__ = ["${this.toPascalCase(this.packageName)}"]`;
  }

  toPascalCase(str) {
    if (!str) return "";
    return str
      .split("-")
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join("");
  }

  generateReadme() {
    const usageExample = {
      basic: `from ${this.packageName} import ${this.toPascalCase(
        this.packageName
      )}

client = ${this.toPascalCase(this.packageName)}()
result = client.example_method()`,
      cli: `# Install and run from command line
pip install ${this.packageName}
${this.packageName} hello`,
      library: `from ${this.packageName} import ${this.toPascalCase(
        this.packageName
      )}

client = ${this.toPascalCase(this.packageName)}()
result = client.example_method()`,
    };

    return `# ${this.packageName}

${this.answers.description}

## Installation

\`\`\`bash
pip install ${this.packageName}
\`\`\`

Or with poetry:

\`\`\`bash
poetry add ${this.packageName}
\`\`\`

## Usage

\`\`\`python
${usageExample[this.answers.packageType]}
\`\`\`

## Development

1. Clone the repository
2. Install dependencies:
   \`\`\`bash
   poetry install
   \`\`\`
3. Run tests:
   \`\`\`bash
   poetry run pytest
   \`\`\`

## License

MIT`;
  }

  generateConfTest() {
    return `"""
Pytest configuration file.
"""
import pytest`;
  }

  generateTests() {
    return `"""
Test suite for ${this.packageName}
"""
from ${this.packageName} import ${this.toPascalCase(this.packageName)}

def test_example_method():
    client = ${this.toPascalCase(this.packageName)}()
    assert client.example_method() == "Hello from ${this.packageName}!"`;
  }

  generateExample() {
    return `"""
Basic usage example for ${this.packageName}
"""
from ${this.packageName} import ${this.toPascalCase(this.packageName)}

def main():
    client = ${this.toPascalCase(this.packageName)}()
    result = client.example_method()
    print(result)

if __name__ == "__main__":
    main()`;
  }

  generateLicense() {
    return `MIT License

Copyright (c) ${new Date().getFullYear()} ${this.answers.author}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.`;
  }

  generateMakefile() {
    return `test:
	poetry run pytest tests/ --cov=${this.packageName} --cov-report=term-missing

format:
	poetry run black .
	poetry run isort .

typecheck:
	poetry run mypy src/

lint: format typecheck

build:
	poetry build

.PHONY: test format typecheck lint build`;
  }

  generateApiDocs() {
    return `# API Documentation

## ${this.toPascalCase(this.packageName)}

Main class for ${this.packageName}.

### Methods

#### example_method()

Returns a greeting message.

Returns:
    str: A greeting message`;
  }

  generateGitignore() {
    return `# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
.env
.venv
env/
venv/
ENV/

# IDE
.idea/
.vscode/
*.swp
*.swo

# Testing
.coverage
htmlcov/
.pytest_cache/
.mypy_cache/

# Distribution
dist/
build/

# Poetry
poetry.lock

# Jupyter Notebook
.ipynb_checkpoints

# pyenv
.python-version

# Logs
*.log

# Local development settings
.env.local
.env.development.local
.env.test.local
.env.production.local`;
  }

  _generateRouterContent() {
    return `from fastapi import APIRouter, Depends, HTTPException
from typing import List

router = APIRouter()

@router.get("/")
async def root():
    """
    Root endpoint for ${this.answers.name} service
    """
    return {"message": "Welcome to ${this.answers.name} service"}

@router.get("/health")
async def health_check():
    """
    Health check endpoint
    """
    return {"status": "healthy"}`;
  }

  _generateConfigContent() {
    return `from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    """
    Application settings
    """
    APP_NAME: str = "${this.answers.name}"
    DEBUG: bool = False
    
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings() -> Settings:
    return Settings()`;
  }

  _generateServiceContent() {
    const serviceName = this.answers.name.replace(/-/g, "_");
    return `from typing import List, Optional

class ${this.toPascalCase(serviceName)}Service:
    """
    Service layer for ${this.answers.name}
    """
    
    async def example_operation(self) -> dict:
        """
        Example service operation
        """
        return {"message": "Service operation completed"}`;
  }

  _generateRepositoryContent() {
    const serviceName = this.answers.name.replace(/-/g, "_");
    return `from typing import List, Optional

class ${this.toPascalCase(serviceName)}Repository:
    """
    Repository layer for ${this.answers.name}
    """
    
    async def example_query(self) -> dict:
        """
        Example database query
        """
        return {"data": "Query result"}`;
  }

  _generateSchemaContent() {
    const serviceName = this.answers.name.replace(/-/g, "_");
    return `from pydantic import BaseModel
from typing import Optional, List

class ExampleSchema(BaseModel):
    """
    Example Pydantic schema
    """
    id: int
    name: str
    description: Optional[str] = None

    class Config:
        from_attributes = True`;
  }

  _generateMainContent() {
    return `from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .api.routes.router import router
from .core.config import get_settings

settings = get_settings()

app = FastAPI(
    title="${this.answers.name}",
    description="${this.answers.description}",
    version="0.1.0",
)

# CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Modify in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(router, prefix="/api")

@app.get("/")
async def root():
    return {"message": f"Welcome to {settings.APP_NAME}"}`;
  }

  _generateConfTestContent() {
    return `import pytest
from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture
def client():
    return TestClient(app)`;
  }

  _generateTestContent() {
    return `from fastapi.testclient import TestClient

def test_root_endpoint(client):
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()

def test_health_check(client):
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"`;
  }

  _generateEnvFile() {
    return `# Application Settings
APP_NAME=${this.packageName}
DEBUG=True
ENVIRONMENT=development

# Database Settings
DATABASE_URL=postgresql://user:password@localhost:5432/${this.packageName}

# Security Settings
SECRET_KEY=your-secret-key-here

# API Settings
API_VERSION=v1
API_PREFIX=/api/${this.answers.packageType === "library" ? "v1" : ""}

# Logging
LOG_LEVEL=INFO`;
  }

  _generateDockerfile() {
    return `FROM python:3.9-slim

WORKDIR /app

RUN pip install poetry

COPY pyproject.toml poetry.lock ./
RUN poetry config virtualenvs.create false \
    && poetry install --no-dev --no-interaction --no-ansi

COPY . .

CMD ["poetry", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]`;
  }

  _generateK8sDeployment() {
    return `apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${this.answers.name}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${this.answers.name}
  template:
    metadata:
      labels:
        app: ${this.answers.name}
    spec:
      containers:
      - name: ${this.answers.name}
        image: ${this.answers.name}:latest
        ports:
        - containerPort: 8000
        env:
        - name: ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: ${this.answers.name}-config
              key: ENVIRONMENT`;
  }

  _generateK8sService() {
    return `apiVersion: v1
kind: Service
metadata:
  name: ${this.answers.name}
spec:
  selector:
    app: ${this.answers.name}
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000
  type: ClusterIP`;
  }

  _generateK8sIngress() {
    return `apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${this.answers.name}
spec:
  rules:
  - host: ${this.answers.name}.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${this.answers.name}
            port:
              number: 80`;
  }

  _generateBaseKustomization() {
    return `apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
- ingress.yaml`;
  }

  _generateDevKustomization() {
    return `apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
- ../../base
patchesStrategicMerge:
- patch.yaml`;
  }

  _generateProdKustomization() {
    return `apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
- ../../base
patchesStrategicMerge:
- patch.yaml`;
  }

  _generateDevPatch() {
    return `apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${this.answers.name}
spec:
  template:
    spec:
      containers:
      - name: ${this.answers.name}
        env:
        - name: ENVIRONMENT
          value: development
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"`;
  }

  _generateProdPatch() {
    return `apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${this.answers.name}
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: ${this.answers.name}
        env:
        - name: ENVIRONMENT
          value: production
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "400m"`;
  }

  _generateSetupScript() {
    return `#!/bin/bash
set -e

# Install dependencies
poetry install

# Setup pre-commit hooks
poetry run pre-commit install

# Setup local development environment
if [ ! -f .env ]; then
    cp .env.example .env
fi

echo "Development environment setup complete!"`;
  }

  _generateStartScript() {
    return `#!/bin/bash
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000`;
  }

  _generateDeployScript() {
    return `#!/bin/bash
set -e

ENVIRONMENT=\${1:-development}

kubectl apply -k k8s/overlays/$ENVIRONMENT`;
  }

  _generateTestScript() {
    return `#!/bin/bash
set -e

# Run tests with coverage
poetry run pytest tests/ --cov=app --cov-report=term-missing`;
  }

  _generateDockerCompose() {
    return `version: '3.8'
services:
  app:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    environment:
      - ENVIRONMENT=development
    depends_on:
      - db
  db:
    image: postgres:13
    environment:
      POSTGRES_DB: ${this.answers.name}
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password`;
  }

  _generateDockerignore() {
    return `# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
*.egg-info/

# Environment
.env
.venv
env/
venv/
ENV/

# IDE
.idea/
.vscode/
*.swp
*.swo

# Testing
.coverage
htmlcov/
.pytest_cache/
.mypy_cache/

# Git
.git
.gitignore

# Docker
Dockerfile
docker-compose.yml
.docker

# Kubernetes
k8s/

# Documentation
docs/
*.md`;
  }

  _generateSkaffold() {
    return `apiVersion: skaffold/v2beta28
kind: Config
build:
  artifacts:
  - image: ${this.answers.name}
    docker:
      dockerfile: Dockerfile
deploy:
  kustomize:
    paths:
    - k8s/overlays/development`;
  }
};
