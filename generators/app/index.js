#!/usr/bin/env node
const Generator = require("yeoman-generator");

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
            value: "basic"
          },
          {
            name: "CLI Tool (Command-line application)",
            value: "cli"
          },
          {
            name: "Library with API (Reusable library with public API)",
            value: "library"
          }
        ],
        default: "basic"
      },
      {
        type: "input",
        name: "description",
        message: "Package description",
        default: "A Python package"
      },
      {
        type: "input",
        name: "author",
        message: "Author name",
        default: this.user.git.name()
      },
      {
        type: "input",
        name: "email",
        message: "Author email",
        default: this.user.git.email()
      }
    ]).then((answers) => {
      this.answers = answers;
      this.packageName = answers.name;
    });
  }

  writing() {
    const baseStructure = {
      // Common structure for all package types
      [`src/${this.packageName}/__init__.py`]: this.generateInit(),
      [`src/${this.packageName}/core.py`]: this.generateCore(),
      "tests/__init__.py": "",
      "tests/conftest.py": this.generateConfTest(),
      [`tests/test_${this.packageName}.py`]: this.generateTests(),
      "examples/basic_usage.py": this.generateExample(),
      "pyproject.toml": this.generatePyprojectToml(),
      "README.md": this.generateReadme(),
      ".gitignore": this.generateGitignore(),
      "Makefile": this.generateMakefile(),
      "LICENSE": this.generateLicense(),
    };

    // Add package-type specific files
    switch (this.answers.packageType) {
      case "cli":
        baseStructure[`src/${this.packageName}/cli.py`] = this.generateCli();
        break;
      case "library":
        baseStructure[`src/${this.packageName}/api.py`] = this.generateApi();
        baseStructure["docs/api.md"] = this.generateApiDocs();
        break;
    }

    Object.entries(baseStructure).forEach(([path, content]) => {
      this.fs.write(this.destinationPath(path), content);
    });
  }

  generatePyprojectToml() {
    const commonDependencies = {
      python: "^3.9",
    };

    const typeSpecificDependencies = {
      cli: {
        click: "^8.1.3",
        "rich": "^13.4.2"
      },
      library: {
        requests: "^2.31.0"
      },
      basic: {}
    };

    const dependencies = {
      ...commonDependencies,
      ...typeSpecificDependencies[this.answers.packageType]
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

${this.answers.packageType === 'cli' ? '[tool.poetry.scripts]\ncli = "' + this.packageName + '.cli:main"\n' : ''}

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
    if (!str) return ''; 
    return str
      .split('-')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join('');
  }

  generateReadme() {
    const usageExample = {
      basic: `from ${this.packageName} import ${this.toPascalCase(this.packageName)}

client = ${this.toPascalCase(this.packageName)}()
result = client.example_method()`,
      cli: `# Install and run from command line
pip install ${this.packageName}
${this.packageName} hello`,
      library: `from ${this.packageName} import ${this.toPascalCase(this.packageName)}

client = ${this.toPascalCase(this.packageName)}()
result = client.example_method()`
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
};