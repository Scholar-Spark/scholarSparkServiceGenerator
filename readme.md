# Scholarspark Service Generator

A Yeoman generator for creating microservices with ease.

## Prerequisites

- **Node.js**: Ensure you have Node.js installed. You can download it from [nodejs.org](https://nodejs.org/).
- **Yeoman**: Install Yeoman globally if you haven't already:

  ```bash
  npm install -g yo
  ```

## Installation

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

Once installed, you can use the generator to create a new microservice:
