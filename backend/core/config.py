from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Redis
    redis_url: str = "redis://localhost:6379"
    
    # API
    api_title: str = "Event-Driven API"
    api_version: str = "1.0.0"
    
    # Security
    secret_key: str  # Required: Must be set via environment variable
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # Environment
    environment: str = "development"
    debug: bool = True
    
    class Config:
        env_file = ".env"


settings = Settings()