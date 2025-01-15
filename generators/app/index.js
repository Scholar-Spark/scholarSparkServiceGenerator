#!/usr/bin/env node
const Generator = require("yeoman-generator");
const chalk = require("chalk");
const path = require("path");
const fs = require("fs");
const mkdirp = require("mkdirp");

// Suppress shelljs warning
process.env.SUPPRESS_NO_CONFIG_WARNING = "true";

module.exports = class extends Generator {
  constructor(args, opts) {
    super(args, opts);
    this.log(chalk.blue("Initializing FastAPI Microservice Generator"));
  }

  async prompting() {
    this.answers = await this.prompt([
      {
        type: "input",
        name: "name",
        message: "Your microservice name",
        default: path.basename(process.cwd()),
        validate: (input) =>
          /^[a-zA-Z][a-zA-Z0-9-]*$/.test(input) || "Invalid service name",
      },
      {
        type: "input",
        name: "description",
        message: "Microservice description",
        default: "A FastAPI microservice",
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
      {
        type: "input",
        name: "port",
        message: "Service port",
        default: "8000",
        validate: (input) => /^\d+$/.test(input) || "Port must be a number",
      },
    ]);

    // Derive additional properties
    this.answers.pythonName = this.answers.name.replace(/-/g, "_");
    this.answers.serviceName = this.answers.name;
  }

  async writing() {
    const templateData = {
      ...this.answers,
      year: new Date().getFullYear(),
    };

    // Create directory structure
    const dirs = [
      "app",
      "app/api",
      "app/api/routes",
      "app/core",
      "tests",
      "helm",
      "helm/templates",
      "scripts",
    ];

    // Create directories using mkdirp
    for (const dir of dirs) {
      await mkdirp(this.destinationPath(dir));
    }

    // Copy files
    await this._copyServiceFiles(templateData);
    await this._copyKubernetesFiles(templateData);
    await this._copyDockerFiles(templateData);
    await this._copyScripts(templateData);
  }

  async _copyServiceFiles(templateData) {
    const files = [
      ["service/app/__init__.py", "app/__init__.py"],
      ["service/app/main.py", "app/main.py"],
      ["service/app/core/__init__.py", "app/core/__init__.py"],
      ["service/app/core/config.py", "app/core/config.py"],
      ["service/app/api/__init__.py", "app/api/__init__.py"],
      ["service/app/api/routes/__init__.py", "app/api/routes/__init__.py"],
      ["service/app/api/routes/router.py", "app/api/routes/router.py"],
      ["service/tests/__init__.py", "tests/__init__.py"],
      ["service/tests/test_api.py", "tests/test_api.py"],
      ["md/readme.md", "README.md"],
      ["service/pyproject.toml", "pyproject.toml"],
      ["service/.env", ".env"],
      ["service/.gitignore", ".gitignore"],
    ];

    await this._copyTemplateFiles(files, templateData);
  }

  async _copyKubernetesFiles(templateData) {
    const files = [
      ["kubernetes/helm/Chart.yaml", "helm/Chart.yaml"],
      ["kubernetes/helm/values.yaml", "helm/values.yaml"],
      ["kubernetes/helm/templates/_helpers.tpl", "helm/templates/_helpers.tpl"],
      [
        "kubernetes/helm/templates/deployment.yaml",
        "helm/templates/deployment.yaml",
      ],
      ["kubernetes/helm/templates/service.yaml", "helm/templates/service.yaml"],
      ["kubernetes/helm/templates/ingress.yaml", "helm/templates/ingress.yaml"],
      ["kubernetes/skaffold.yaml", "skaffold.yaml"],
    ];

    await this._copyTemplateFiles(files, templateData);
  }

  async _copyDockerFiles(templateData) {
    const files = [
      ["docker/Dockerfile", "Dockerfile"],
      ["docker/.dockerignore", ".dockerignore"],
    ];

    await this._copyTemplateFiles(files, templateData);
  }

  async _copyScripts(templateData) {
    const files = [
      ["scripts/setup.sh", "scripts/setup.sh"],
      ["scripts/package-helm.sh", "scripts/package-helm.sh"],
    ];

    await this._copyTemplateFiles(files, templateData);

    // Make scripts executable
    fs.chmodSync(this.destinationPath("scripts/setup.sh"), 0o755);
    fs.chmodSync(this.destinationPath("scripts/package-helm.sh"), 0o755);
  }

  async _copyTemplateFiles(files, templateData) {
    for (const [src, dest] of files) {
      this.fs.copyTpl(
        this.templatePath(src),
        this.destinationPath(dest),
        templateData
      );
    }
  }

  end() {
    this.log(chalk.green("\nProject generated successfully!"));
    this.log(chalk.blue("\nNext steps:"));
    this.log(chalk.yellow("1. Run: cd " + this.answers.name));
    this.log(chalk.yellow("2. Run: ./scripts/setup.sh"));
    this.log(chalk.yellow("3. Run: skaffold dev"));
  }
};
