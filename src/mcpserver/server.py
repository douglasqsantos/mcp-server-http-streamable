import os
from mcp.server.fastmcp import FastMCP

host = os.environ.get("MCP_HOST", "0.0.0.0")
port = int(os.environ.get("MCP_PORT", "8000"))
mcp = FastMCP("server", host=host, port=port)


@mcp.tool()
def greeting(name: str) -> str:
    """Send a greeting."""
    return f"Hi {name}"
