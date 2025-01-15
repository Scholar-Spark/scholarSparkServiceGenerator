from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "<%= name %>"
    DEBUG: bool = False
    PORT: int = <%= port %>
    
    class Config:
        env_file = ".env"

settings = Settings()