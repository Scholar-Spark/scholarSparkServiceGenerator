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
    if (this.answers.packageType === "service") {
      // Generate service files
      this._generateServiceFiles();
    } else {
      // Generate library files
      this._generateLibraryFiles();
    }

    // Copy setup script from templates
    this.fs.copy(
      this.templatePath("scripts/setup.sh"),
      this.destinationPath("scripts/setup.sh")
    );
  }

  end() {
    // Make setup script executable
    const setupScript = this.destinationPath("scripts/setup.sh");
    if (fs.existsSync(setupScript)) {
      fs.chmodSync(setupScript, 0o755);
      this.log("Made setup script executable");
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
DEBUG=True # Set to False in production
`;
  }

  _generateHelmChart() {
    return `apiVersion: v2
name: ${this.answers.name}
description: ${this.answers.description}
type: application
version: 0.1.0
appVersion: "1.0.0"
maintainers:
  - name: ${this.answers.author}
    email: ${this.answers.email}`;
  }

  _generateHelmValues() {
    return `# Default values for ${this.answers.name}
replicaCount: 1

image:
  repository: ${this.answers.name}
  tag: latest
  pullPolicy: IfNotPresent

nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 80
  targetPort: 8000

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: ${this.answers.name}.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

env:
  - name: ENVIRONMENT
    value: development
  - name: APP_NAME
    value: ${this.answers.name}
  - name: DEBUG
    value: "true"

serviceAccount:
  create: true
  name: ""

podAnnotations: {}

securityContext: {}

nodeSelector: {}

tolerations: []

affinity: {}`;
  }

  _generateHelmHelpers() {
    const name = this.answers.name;
    return `{{/*
Expand the name of the chart.
*/}}
{{- define "${name}.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "${name}.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "${name}.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "${name}.labels" -}}
helm.sh/chart: {{ include "${name}.chart" . }}
{{ include "${name}.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "${name}.selectorLabels" -}}
app.kubernetes.io/name: {{ include "${name}.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}`;
  }

  _generateHelmDeployment() {
    const name = this.answers.name;
    return `apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "${name}.fullname" . }}
  labels:
    {{- include "${name}.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "${name}.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "${name}.selectorLabels" . | nindent 8 }}
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- if .Values.serviceAccount.create }}
      serviceAccountName: {{ include "${name}.fullname" . }}
      {{- end }}
      securityContext:
        {{- toYaml .Values.securityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          env:
            {{- toYaml .Values.env | nindent 12 }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}`;
  }

  _generateHelmService() {
    const name = this.answers.name;
    return `apiVersion: v1
kind: Service
metadata:
  name: {{ include "${name}.fullname" . }}
  labels:
    {{- include "${name}.labels" . }}
spec:
  selector:
    app.kubernetes.io/name: {{ include "${name}.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000`;
  }

  _generateHelmIngress() {
    const name = this.answers.name;
    return `apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "${name}.fullname" . }}
  labels:
    {{- include "${name}.labels" . }}
spec:
  rules:
    - host: {{ .Values.ingress.hosts }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ include "${name}.fullname" . }}
                port:
                  number: 80
`;
  }
};
