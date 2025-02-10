# Scholarspark Service Generator

A Yeoman generator for creating microservices with ease.

## Prerequisites

- **Node.js**: Ensure you have Node.js installed. You can download it from [nodejs.org](https://nodejs.org/).
- **Yeoman**: Install Yeoman globally if you haven't already:

  ```bash
  npm install -g yo
  ```

## Installation

**GOTCHA:** Please make sure you follow this order when you change your branch, do not use environment managers or other package managers. Bear in mind that you need to first install the dependencies of the generator and then link it to the global node_modules using NPM link. If you only link to the global node_modules, you will not be able to run the generator and you will get the following error:

```
✖️ An error occured while running scholarspark-service:app#writing
Error

mkdirp is not a function

     _-----_     ╭───────────────────────╮
    |       |    │      Bye from us!     │
    |--(o)--|    │       Chat soon.      │
   `---------´   │      Yeoman team      │
    ( _´U`_ )    │    http://yeoman.io   │
    /___A___\   /╰───────────────────────╯
     |  ~  |
   __'.___.'__
 ´   `  |° ´ Y `
```

1. **Clone the Repository**: Clone the generator repository to your local machine.

   ```bash
   git clone <your-repo-url>
   cd <your-repo-directory>
   ```

2. **Install Dependencies**: Run npm install to install the necessary dependencies.

   ```bash
   npm install
   ```

3. **Link the Generator Globally**: Use npm link to make the generator available globally. This step is crucial for development, as it allows you to test your generator as if it were installed globally.

   ```bash
   npm link
   ```

   - **Note**: Run this command from the root of your generator project (inside the `generator-scholarspark-service/` folder). This will install your project dependencies and create a symlink from the global `node_modules` directory to your local project.

4. **Verify the Installation**: To ensure the generator is correctly linked, you can list all available generators:

   ```bash
   yo --generators
   ```

   You should see `scholarspark-service` listed among the available generators.

## Usage

Once the generator is installed and linked globally, you can use it to scaffold a new microservice project. Follow these steps:

1. **Navigate to Your Desired Directory**: Open a terminal and navigate to the directory where you want to create your new microservice project.

   ```bash
   cd /path/to/your/projects
   ```

2. **Run the Generator**: Use the `yo` command followed by the generator name to start the scaffolding process. For this generator, the command is:

   ```bash
   yo scholarspark-service
   ```

3. **Follow the Prompts**: The generator will prompt you for information needed to set up your microservice. This typically includes:

   - **Microservice Name**: Enter a name for your microservice. This name will be used to create directories and files specific to your service.
   - **Additional Configuration**: Depending on how the generator is set up, you may be asked for additional configuration options, such as database settings, API endpoints, or authentication methods.

4. **Project Creation**: Once you've provided the necessary information, the generator will create a new directory with the structure and files needed for your microservice. This includes:

   - **Service Files**: Core service files, such as controllers, models, and routes.
   - **Configuration Files**: Environment and configuration files, such as `.env` and `config.js`.
   - **Documentation**: Basic documentation files, such as `README.md`.

5. **Set Up the Project with Poetry**: If your project uses Python, it's recommended to use Poetry for dependency management and virtual environment setup.

   - **Install Poetry**: If you haven't already, install Poetry by following the instructions at [python-poetry.org](https://python-poetry.org/docs/#installation).

   - **Initialize the Project**: Navigate into your project directory and use Poetry to install dependencies and set up the environment.

     ```bash
     cd your-microservice-name
     poetry install
     ```

   - **Activate the Virtual Environment**: Poetry automatically manages virtual environments. To activate it, use:

     ```bash
     poetry shell
     ```

6. **Verify the Setup**: After the generator completes, navigate into your new project directory and verify that all files and directories have been created as expected.

   ```bash
   ls
   ```

7. **Start Developing**: You can now start developing your microservice. Open the project in your favorite code editor and begin customizing it to meet your needs.

By following these steps, you can quickly set up a new microservice project using the Scholarspark Service Generator and Poetry, allowing you to focus on building features rather than setting up boilerplate code.
