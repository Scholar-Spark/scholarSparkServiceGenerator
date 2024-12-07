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
    ]).then((answers) => {
      this.serviceName = answers.name;
    }); // testing comment
  }

  writing() {
    const baseStructure = {
      "app/api/routes/__init__.py": "",
      "app/api/routes/router.py": "",
      "app/core/__init__.py": "",
      "app/core/config.py": "",
      "app/core/security.py": "",
      "app/services/__init__.py": "",
      [`app/services/${this.serviceName}_service.py`]: "",
      "app/repositories/__init__.py": "",
      [`app/repositories/${this.serviceName}_repository.py`]: "",
      "app/schemas/__init__.py": "",
      [`app/schemas/${this.serviceName}.py`]: "",
      "app/__init__.py": "",
      "app/main.py": "",
      "tests/__init__.py": "",
      Dockerfile: "",
      "requirements.txt": "",
      ".env.example": "",
    };

    Object.entries(baseStructure).forEach(([path, content]) => {
      this.fs.write(this.destinationPath(path), content);
    });
  }
};
