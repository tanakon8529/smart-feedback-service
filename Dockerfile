FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Copy dependency manifest first for better caching
COPY requirements.txt .

# Install dependencies with uv (cached across builds)
RUN --mount=type=cache,target=/root/.cache/uv uv pip install --system -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Command to run the application with Granian
# Removed invalid --workers auto. Default is 1. 
# For production, you should specify a number (e.g., --workers 4)
CMD ["granian", "--interface", "asgi", "--host", "0.0.0.0", "--port", "8000", "--reload", "app.main:app"]
