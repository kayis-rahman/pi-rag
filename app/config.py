"""Synapse configuration — pydantic-settings"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # App
    APP_NAME: str = "Synapse"
    APP_ENV: str = "development"
    DEBUG: bool = False

    # Pi
    PI_HOSTNAME: str = "dietpi.local"
    PI_USER: str = "pi"

    # LLM (llama.cpp)
    LLAMA_HOST: str = "http://localhost:8081"
    LLAMA_MODEL: str = "gemma-4-e4b-q4.gguf"
    LLAMA_IDLE_TIMEOUT: int = 300  # seconds before auto-unload

    # Fallback LLM (GPUHub)
    GPUHUB_API_KEY: str = ""
    GPUHUB_ENDPOINT: str = ""
    GPUHUB_MODEL: str = "qwen3-27b"

    # Qdrant
    QDRANT_HOST: str = "localhost"
    QDRANT_PORT: int = 6333
    QDRANT_API_KEY: str = ""

    # Redis
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0

    # Gmail
    GMAIL_API_ENABLED: bool = False
    GMAIL_CREDENTIALS_PATH: str = ""

    # GitHub
    GITHUB_TOKEN: str = ""
    GITHUB_OWNER: str = "kayis-rahman"
    GITHUB_PROJECT_NUMBER: int = 7

    # iCal
    ICAL_URLS: list[str] = []

    # Voice
    WHISPER_MODEL: str = "indicwhisper-medium"
    PARLER_TTS_ENDPOINT: str = ""

    # Open WebUI
    OPENWEBUI_URL: str = "http://localhost:8080"


settings = Settings()
