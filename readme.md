# FastAPI Microservice Generator

A Yeoman generator that creates production-ready FastAPI microservices with best practices built-in.

## Features

- 🚀 FastAPI setup with modern Python practices
- 📊 OpenTelemetry integration (optional)
- 🐳 Docker support (optional)
- 🔐 Basic security configurations
- ✅ Testing setup
- 💻 Development tools configuration

## Prerequisites

Make sure you have the following installed:

- Python 3.10 or higher
- Node.js 18.17.1 or higher
- Docker 20.10.21 or higher (optional)

## Installation

```bash
npm install -g yo generator-fastapi-microservice
```

## Usage

1. Create a new directory for your project and navigate to it:

```bash
mkdir my-fastapi-service && cd my-fastapi-service
```

2. Run the generator:

```bash
yo fastapi-microservice <service-name>
```

3. Follow the prompts to configure your service.

## Project Structure

```
├── app/
│   ├── api/
│   │   └── v1/
│   ├── core/
│   │   ├── config.py
│   │   └── logging.py
│   ├── models/
│   ├── services/
│   └── main.py
├── tests/
├── Dockerfile
├── .env.example
```

## Configuration

The service can be configured using environment variables or a `.env` file. Key configuration options include:

- `APP_ENV`: Environment (development/staging/production)
- `LOG_LEVEL`: Logging level (debug/info/warning/error)
- `PORT`: Application port (default: 8000)
- `CORS_ORIGINS`: Allowed CORS origins

## Development

1. Install Poetry if you haven't already:

```bash
curl -sSL https://install.python-poetry.org | python3
```

2. Install dependencies:

```bash
poetry install
```

3. Run the service:

```bash
poetry run python app/main.py
```

4. Run the tests:

```bash
poetry run pytest
```
