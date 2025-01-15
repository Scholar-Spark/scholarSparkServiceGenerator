#!/usr/bin/env node
const Generator = require("yeoman-generator");
const chalk = require("chalk");
const path = require("path");
const mkdirp = require("mkdirp");
const fs = require("fs").promises;

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
        default: this.appname.replace(/\s+/g, "-").toLowerCase(),
        validate: (input) => {
          const valid = /^[a-z0-9][a-z0-9-]*[a-z0-9]$/.test(input);
          if (!valid) {
            return "Name must consist of lowercase letters, numbers, and hyphens, and must start and end with an alphanumeric character";
          }
          return true;
        },
        filter: (input) => input.toLowerCase(),
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
        message: "Author name (full name)",
        validate: (input) => {
          if (!input || input.length < 2) {
            return "Please enter a valid name";
          }
          return true;
        },
      },
      {
        type: "input",
        name: "email",
        message: "Author email",
        validate: (input) => {
          const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
          if (!emailRegex.test(input)) {
            return "Please enter a valid email address";
          }
          return true;
        },
      },
      {
        type: "input",
        name: "port",
        message: "Service port",
        default: "8000",
        validate: (input) => {
          const port = parseInt(input);
          return port > 0 && port < 65536
            ? true
            : "Port must be between 1 and 65535";
        },
      },
    ]);

    // Ensure we have valid names for different contexts
    this.answers.serviceName = this.answers.name;
    this.answers.pythonName = this.answers.name.replace(/-/g, "_");

    // Format author string for pyproject.toml
    this.answers.authorString = `${this.answers.author} <${this.answers.email}>`;
  }

  async writing() {
    const templateData = {
      ...this.answers,
      year: new Date().getFullYear(),
    };

    // Create base directories
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

    for (const dir of dirs) {
      await mkdirp(this.destinationPath(dir));
    }

    // Copy all files first
    const files = [
      // Python service files
      ["app/main.py", "app/main.py"],
      ["app/__init__.py", "app/__init__.py"],
      ["app/core/__init__.py", "app/core/__init__.py"],
      ["app/core/config.py", "app/core/config.py"],
      ["app/api/__init__.py", "app/api/__init__.py"],
      ["app/api/routes/__init__.py", "app/api/routes/__init__.py"],
      ["app/api/routes/router.py", "app/api/routes/router.py"],
      ["tests/__init__.py", "tests/__init__.py"],
      ["tests/test_api.py", "tests/test_api.py"],

      // Configuration files
      ["pyproject.toml", "pyproject.toml"],
      [".env", ".env"],
      [".gitignore", ".gitignore"],
      ["readme.md", "README.md"],

      // Docker files
      ["Dockerfile", "Dockerfile"],
      [".dockerignore", ".dockerignore"],

      // Kubernetes/Helm files
      ["helm/Chart.yaml", "helm/Chart.yaml"],
      ["helm/values.yaml", "helm/values.yaml"],
      ["helm/templates/_helpers.tpl", "helm/templates/_helpers.tpl"],
      ["helm/templates/deployment.yaml", "helm/templates/deployment.yaml"],
      ["helm/templates/service.yaml", "helm/templates/service.yaml"],
      ["helm/templates/ingress.yaml", "helm/templates/ingress.yaml"],
      ["skaffold.yaml", "skaffold.yaml"],

      // Scripts
      ["scripts/setup.sh", "scripts/setup.sh"],
      ["scripts/package-helm.sh", "scripts/package-helm.sh"],
    ];

    // Copy all files
    for (const [src, dest] of files) {
      try {
        this.fs.copyTpl(
          this.templatePath(src),
          this.destinationPath(dest),
          templateData
        );
      } catch (error) {
        this.log(chalk.red(`Error copying file ${src}: ${error.message}`));
        throw error;
      }
    }

    // Wait for all files to be written
    await this.fs.commit();

    // Make scripts executable
    const scriptsToMakeExecutable = [
      "scripts/setup.sh",
      "scripts/package-helm.sh",
    ];

    for (const script of scriptsToMakeExecutable) {
      const scriptPath = this.destinationPath(script);
      try {
        await fs.chmod(scriptPath, 0o755);
        this.log(chalk.green(`Made ${script} executable`));
      } catch (error) {
        this.log(
          chalk.red(`Error making ${script} executable: ${error.message}`)
        );
        // Try alternative method
        try {
          require("child_process").execSync(`chmod +x "${scriptPath}"`);
          this.log(
            chalk.green(`Made ${script} executable using chmod command`)
          );
        } catch (cmdError) {
          this.log(
            chalk.red(
              `Failed to make ${script} executable: ${cmdError.message}`
            )
          );
        }
      }
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
