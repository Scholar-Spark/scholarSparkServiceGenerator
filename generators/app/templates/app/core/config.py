from typing import List
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Application Configuration
    APP_NAME: str = "<%= name %>"
    PORT: int = <%= port %>
    API_PATH: str = "/api/v1"
    DEBUG: bool = True

    # Service Identity
    SERVICE_NAME: str = "<%= name %>"
    SERVICE_VERSION: str = "0.1.0"
    ENVIRONMENT: str = "development"

    # Security
    JWT_SECRET_KEY: str
    CORS_ORIGINS: List[str]

    # Database Configuration
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_DB: str = "<%= pythonName %>"
    DATABASE_URL: str

    # Observability Configuration
    OTEL_SERVICE_NAME: str
    OTEL_SERVICE_VERSION: str
    OTEL_ENVIRONMENT: str
    OTEL_DEBUG: bool = True
    OTEL_TEMPO_ENDPOINT: str
    TRACES_ENDPOINT: str

    # Logging
    LOGGING_APP: str
    LOGS_ENDPOINT: str

    # Kubernetes & Helm Configuration
    K8S_NAMESPACE: str
    HELM_REGISTRY: str
    ORGANIZATION_PREFIX: str = "<%= organizationName %>"

    # Resource Limits
    MEMORY_LIMIT: str
    CPU_LIMIT: str
    MEMORY_REQUEST: str
    CPU_REQUEST: str

    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()