# MCP HTTP streamable server
FROM python:3.12-slim

WORKDIR /app

# Install dependencies from pyproject.toml
COPY pyproject.toml ./
RUN pip install --no-cache-dir "mcp[cli]>=1.26.0"

# Application
COPY server.py ./

# Streamable HTTP default port
ENV MCP_PORT=8000
EXPOSE 8000

CMD ["python", "server.py"]
