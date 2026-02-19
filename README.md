# mcp-server-http-streamable

A minimal [Model Context Protocol (MCP)](https://modelcontextprotocol.io) server using **Streamable HTTP** transport. It exposes a `greeting` tool and runs as an HTTP service so clients can connect over the network.

## Prerequisites

- **Python 3.12+**
- **[uv](https://docs.astral.sh/uv/)** (recommended) or pip

For Docker: [Docker](https://docs.docker.com/get-docker/) and Docker Compose.

## How to run

### Option 1: Local (uv)

From the project directory:

```bash
uv sync
uv run server.py
```

The server listens on **<http://0.0.0.0:8000>** by default. The MCP endpoint is at **<http://localhost:8000/mcp>**.

**Environment variables (optional):**

| Variable    | Default    | Description              |
|------------|------------|--------------------------|
| `MCP_HOST` | `0.0.0.0`  | Bind address             |
| `MCP_PORT` | `8000`     | Port                     |

Example with a custom port:

```bash
MCP_PORT=9000 uv run server.py
```

### Option 2: Docker

Build and run the image:

```bash
docker build -t mcp-server-http-streamable .
docker run -p 8000:8000 mcp-server-http-streamable
```

The server is available at **<http://localhost:8000/mcp>**.

### Option 3: Docker Compose

Build and start the service (foreground):

```bash
docker compose up --build
```

Run in the background:

```bash
docker compose up --build -d
```

Stop:

```bash
docker compose down
```

Port **8000** is mapped to the host. Connect to **<http://localhost:8000/mcp>** from your MCP client.

## Connecting a client

Use the Streamable HTTP URL when adding this server to an MCP client (e.g. Cursor, Claude Desktop):

- **URL:** `http://localhost:8000/mcp` (or your host/port if different)

### Claude Desktop (via mcp-remote)

Claude Desktop talks to MCP servers over stdio by default. To use this **HTTP** server, run it via **mcp-remote**, which bridges stdio to your running HTTP server.

1. **Start this server** (local or Docker) so it is listening on `http://localhost:8000/mcp` (or your host/port).

2. **Edit Claude’s MCP config**
   - **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

3. **Add a server entry** that uses `npx` and `mcp-remote` with your server URL and `--allow-http`:

   ```json
   {
     "mcpServers": {
       "RemoteExample": {
         "command": "npx",
         "args": [
           "mcp-remote",
           "http://localhost:8000/mcp",
           "--allow-http"
         ]
       }
     }
   }
   ```

   Use `http://0.0.0.0:8000/mcp` only if Claude and the server run on the same machine and you intend to bind to all interfaces; otherwise prefer **`http://localhost:8000/mcp`**.

4. Restart Claude Desktop. The server’s tools (e.g. **greeting**) should appear once connected.

5. **Use it in chat** — In Claude, you can ask in plain language and Claude will call the tool. For example:
   - *“Send a greeting to Douglas”* → Claude uses the **greeting** tool with `name: "Douglas"` and replies with “Hi Douglas”.
   - You can substitute any name: *“Say hello to Maria”*, *“Greet the team”*, etc.

**Requirements:** [Node.js](https://nodejs.org/) (for `npx`) and the [mcp-remote](https://www.npmjs.com/package/mcp-remote) package (installed automatically when you use `npx mcp-remote`).

## Using the MCP Inspector

The [MCP Inspector](https://modelcontextprotocol.io/tools/inspector) lets you test tools and resources without a full client. Use it with this server as follows.

1. **Start the server** (in one terminal):

   ```bash
   uv run server.py
   ```

   Leave it running. The server must be up before the inspector connects.

2. **Open the MCP Inspector**
   - **From Cursor:** Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`) → run **“MCP: Open Inspector”** (or use **Settings → MCP** and open the inspector from there).
   - **From the CLI:** Run `mcp dev`; when prompted for a connection type, choose the option to connect to a **remote** or **Streamable HTTP** server (if your CLI supports it).

3. **Connect to this server**
   - In the inspector UI, add a new connection or “Connect to server”.
   - Choose **Streamable HTTP** (or “HTTP” / “Remote URL”).
   - Enter the server URL: **`http://localhost:8000/mcp`** (use a different host/port if you changed `MCP_HOST` or `MCP_PORT`).
   - Confirm or connect.

4. **Test the server**
   - After connecting, the inspector should list tools (e.g. **greeting**).
   - Open the **greeting** tool, set `name` (e.g. `"World"`), and run it to see the response.

If the inspector only supports stdio, start the server as above and use another MCP client that supports Streamable HTTP (e.g. Cursor with an MCP server config that uses the `http://localhost:8000/mcp` URL).

## Tools

- **`greeting(name)`** — Returns a greeting for the given name.
