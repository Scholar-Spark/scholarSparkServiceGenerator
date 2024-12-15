#!/usr/bin/env node
const Generator = require("yeoman-generator");

module.exports = class extends Generator {
  prompting() {
    return this.prompt([
      {
        type: "input",
        name: "name",
        message: "Your microservice name",
        default: "auth",
      },
      {
        type: "input",
        name: "description",
        message: "Project description",
        default: "A FastAPI microservice",
      },
      {
        type: "input",
        name: "author",
        message: "Author name",
        default: this.user.git.name(),
      },
    ]).then((answers) => {
      this.answers = answers;
      this.serviceName = answers.name;
    });
  }

  writing() {
    const baseStructure = {
      "app/api/routes/__init__.py": "",
      "app/api/routes/router.py": this._generateRouterContent(),
      "app/core/__init__.py": "",
      "app/core/config.py": this._generateConfigContent(),
      "app/core/security.py": "",
      "app/services/__init__.py": "",
      [`app/services/${this.serviceName}_service.py`]: this._generateServiceContent(),
      "app/repositories/__init__.py": "",
      [`app/repositories/${this.serviceName}_repository.py`]: this._generateRepositoryContent(),
      "app/schemas/__init__.py": "",
      [`app/schemas/${this.serviceName}.py`]: this._generateSchemaContent(),
      "app/__init__.py": "",
      "app/main.py": this._generateMainContent(),
      "tests/__init__.py": "",
      "tests/conftest.py": this._generateConfTestContent(),
      [`tests/test_${this.serviceName}.py`]: this._generateTestContent(),
      "Dockerfile": this._generateDockerfile(),
      ".env": this._generateEnvFile(),
      ".env.example": this._generateEnvExampleFile(),
      ".gitignore": this._generateGitignore(),
      "pyproject.toml": this._generatePyprojectToml(),
      "poetry.lock": "",
      "README.md": this._generateReadme(),
    };

    Object.entries(baseStructure).forEach(([path, content]) => {
      this.fs.write(this.destinationPath(path), content);
    });
  }

  _generatePyprojectToml() {
    return `[tool.poetry]
name = "${this.serviceName}"
version = "0.1.0"
description = "${this.answers.description}"
authors = ["${this.answers.author}"]

[tool.poetry.dependencies]
python = "^3.9"
fastapi = "^0.68.0"
uvicorn = "^0.15.0"
python-dotenv = "^0.19.0"
sqlalchemy = "^1.4.23"
pydantic = "^1.8.2"
alembic = "^1.7.1"

[tool.poetry.dev-dependencies]
pytest = "^6.2.5"
black = "^21.7b0"
isort = "^5.9.3"
flake8 = "^3.9.2"
pytest-cov = "^2.12.1"

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 88
target-version = ['py39']
include = '\\.pyi?$'

[tool.isort]
profile = "black"
multi_line_output = 3`;
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

  _generateGitignore() {
    return `# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
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
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
.env
.venv
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

# Logs
*.log`;
  }

  _generateEnvFile() {
    return `DATABASE_URL=postgresql://user:password@localhost:5432/${this.serviceName}
SECRET_KEY=your-super-secret-key
DEBUG=True
ENVIRONMENT=development`;
  }

  _generateEnvExampleFile() {
    return `DATABASE_URL=postgresql://user:password@localhost:5432/${this.serviceName}
SECRET_KEY=your-super-secret-key
DEBUG=True
ENVIRONMENT=development`;
  }

  _generateReadme() {
    return `# ${this.serviceName} Microservice

${this.answers.description}

## Setup

1. Install Poetry:
\`\`\`bash
curl -sSL https://install.python-poetry.org | python3 -
\`\`\`

2. Install dependencies:
\`\`\`bash
poetry install
\`\`\`

3. Copy .env.example to .env and update the values:
\`\`\`bash
cp .env.example .env
\`\`\`

4. Run the application:
\`\`\`bash
poetry run uvicorn app.main:app --reload
\`\`\`

## Testing

Run tests with:
\`\`\`bash
poetry run pytest
\`\`\`

## Docker

Build and run with Docker:
\`\`\`bash
docker build -t ${this.serviceName} .
docker run -p 8000:8000 ${this.serviceName}
\`\`\``;
  }

  // Add other _generate* methods for the remaining files...
};