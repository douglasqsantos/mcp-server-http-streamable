# MCP HTTP streamable server (uv for local/remote parity)
FROM python:3.12-slim

# Install uv from official image (same tool as local)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Avoid link warnings when cache and target are on different filesystems
ENV UV_LINK_MODE=copy

# Install project with uv (mirrors local: uv sync)
COPY pyproject.toml uv.lock ./
COPY src ./src/
RUN uv sync --frozen

# Streamable HTTP default port
ENV MCP_PORT=8000
EXPOSE 8000

# Run with venv Python only — no uv or launcher scripts at runtime (no install on bootstrap)
CMD ["/app/.venv/bin/python", "-m", "mcpserver"]
