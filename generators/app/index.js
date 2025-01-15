#!/usr/bin/env node
const Generator = require("yeoman-generator");
const fs = require("fs");
const path = require("path");

// Suppress shelljs warningf
process.env.SUPPRESS_NO_CONFIG_WARNING = "true";

module.exports = class extends Generator {
  prompting() {
    return this.prompt([
      {
        type: "input",
        name: "name",
        message: "Your microservice name",
        default: "my-service",
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
      },
    ]).then((answers) => {
      this.answers = answers;
      this.answers.pythonName = answers.name.replace(/-/g, "_");
    });
  }

  writing() {
    this._copyServiceFiles();
    this._copyKubernetesFiles();
    this._copyDockerFiles();
    this._copyDevScripts();
  }

  _copyServiceFiles() {
    // FastAPI service structure
    const files = [
      "app/__init__.py",
      "app/main.py",
      "app/core/__init__.py",
      "app/core/config.py",
      "app/api/__init__.py",
      "app/api/routes/__init__.py",
      "app/api/routes/router.py",
      "tests/__init__.py",
      "tests/test_api.py",
      "pyproject.toml",
      ".env",
      ".gitignore",
    ];

    files.forEach((file) => {
      this.fs.copyTpl(
        this.templatePath(`service/${file}`),
        this.destinationPath(file),
        this.answers
      );
    });
  }

  _copyKubernetesFiles() {
    // Kubernetes/Helm files
    const files = ["helm/Chart.yaml", "helm/values.yaml"];

    files.forEach((file) => {
      this.fs.copyTpl(
        this.templatePath(`service/${file}`),
        this.destinationPath(file),
        this.answers
      );
    });
  }

  _copyDockerFiles() {
    // Docker files
    const files = ["Dockerfile", ".dockerignore"];

    files.forEach((file) => {
      this.fs.copyTpl(
        this.templatePath(`service/${file}`),
        this.destinationPath(file),
        this.answers
      );
    });
  }

  _copyDevScripts() {
    // Dev scripts
    const files = [
      "skaffold.yaml",
      "docker-compose.override.yml",
      "kubeconfig",
    ];

    files.forEach((file) => {
      this.fs.copyTpl(
        this.templatePath(`service/${file}`),
        this.destinationPath(file),
        this.answers
      );
    });
  }
};
