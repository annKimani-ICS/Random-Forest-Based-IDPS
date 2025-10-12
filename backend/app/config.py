from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    DATABASE_URL: str
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 480  # 8 hours
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    ISSUER: str = "IDS-IDPS"
    CORS_ORIGINS: str = "http://localhost:5173"
    RATE_LIMIT_LOGIN: str = "5/minute"
    RATE_LIMIT_MFA: str = "5/minute"
    MAX_LOGIN_ATTEMPTS: int = 10
    LOCKOUT_DURATION_MINUTES: int = 5
    
    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()

