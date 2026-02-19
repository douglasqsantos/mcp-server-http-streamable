# mcp-server-http-streamable

A minimal [Model Context Protocol (MCP)](https://modelcontextprotocol.io) server using **Streamable HTTP** transport. It exposes a `greeting` tool and runs as an HTTP service so clients can connect over the network. The project uses **uv** both locally and in Docker/Kubernetes for a single, consistent approach. You can run it locally with `uv run mcp-server`, from Git with **uvx**, or in Docker/Kubernetes.

## Project structure

```
mcp-server-http-streamable/
├── src/mcpserver/
│   ├── __init__.py
│   ├── __main__.py      # Entry point (mcp-server)
│   └── server.py        # FastMCP app and tools
├── k8s/                 # Kubernetes manifests (00-, 01-, 02-)
├── pyproject.toml       # Project and [project.scripts] mcp-server
├── uv.lock
├── Dockerfile
├── docker-compose.yml
└── README.md
```

## Prerequisites

- **Python 3.12+**
- **[uv](https://docs.astral.sh/uv/)** (recommended) or pip

For Docker: [Docker](https://docs.docker.com/get-docker/) and Docker Compose.

For Kubernetes deploy: [kubectl](https://kubernetes.io/docs/tasks/tools/) and a cluster (minikube, kind, EKS, etc.).

## Deploy to Kubernetes

Follow these steps to build the image, push it to a registry, and run the server in Kubernetes.

**Manifests** (in `k8s/`): `00-namespace.yaml`, `01-deployment.yaml`, `02-service.yaml` — numbered so `kubectl apply -f k8s/` runs them in the right order.

1. **Build the Docker image** (from the project root; image uses **uv** like local):

   ```bash
   docker build -t douglasqsantos/mcp-server-http-streamable:latest .
   ```

2. **Push the image** to Docker Hub (or your registry):

   ```bash
   docker push douglasqsantos/mcp-server-http-streamable:latest
   ```

   Log in first with `docker login` if needed.

3. **Deploy to the cluster** (namespace, deployment, and service):

   ```bash
   kubectl apply -f k8s/
   ```

   Manifests are numbered (`00-namespace.yaml`, `01-deployment.yaml`, `02-service.yaml`) so they apply in the correct order.

4. **Wait for the pod to be ready:**

   ```bash
   kubectl -n mcp-server get pods -l app=mcp-server-http-streamable
   ```

   Wait until `STATUS` is `Running` and `READY` is `1/1`.

5. **Access the MCP server:**
   - **Port-forward** (works on any cluster):

     ```bash
     kubectl -n mcp-server port-forward svc/mcp-server-http-streamable 8000:8000
     ```

     Use **<http://localhost:8000/mcp>** in your MCP client. Leave the command running.
   - **NodePort** (if you use the NodePort service): use `http://<NODE_IP>:30800/mcp`. Get node IP with `kubectl get nodes -o wide` or `minikube ip` (minikube).

6. **Update and redeploy** after image changes:

   ```bash
   docker build -t douglasqsantos/mcp-server-http-streamable:latest .
   docker push douglasqsantos/mcp-server-http-streamable:latest
   kubectl -n mcp-server rollout restart deployment/mcp-server-http-streamable
   ```

7. **Remove the deployment:**

   ```bash
   kubectl delete -f k8s/
   ```

## How to run

### Option 1: Local (uv)

From the project directory:

```bash
uv sync
uv run mcp-server
```

The server listens on **<http://0.0.0.0:8000>** by default. The MCP endpoint is at **<http://localhost:8000/mcp>**.

**Environment variables (optional):**

| Variable    | Default    | Description              |
|------------|------------|--------------------------|
| `MCP_HOST` | `0.0.0.0`  | Bind address             |
| `MCP_PORT` | `8000`     | Port                     |

Example with a custom port:

```bash
MCP_PORT=9000 uv run mcp-server
```

### Option 2: Run with uvx (from Git)

Install and run from the repository without cloning (requires [uv](https://docs.astral.sh/uv/)):

```bash
uvx --from git+https://github.com/douglasqsantos/mcp-server-http-streamable.git mcp-server
```

Use your repo URL if different. The server runs with the same defaults (port 8000, endpoint **http://localhost:8000/mcp**). To use a different port, set `MCP_PORT` before running (e.g. in your shell or in the process that invokes uvx).

### Option 3: Docker

The image uses **uv** (same as local) so dependency install and run match your usual workflow. Build and run:

```bash
docker build -t mcp-server-http-streamable .
docker run -p 8000:8000 mcp-server-http-streamable
```

The server is available at **<http://localhost:8000/mcp>**.

### Option 4: Docker Compose

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

### Option 5: Kubernetes

Manifests in `k8s/` (`00-namespace.yaml`, `01-deployment.yaml`, `02-service.yaml`) deploy the image `douglasqsantos/mcp-server-http-streamable:latest` into the `mcp-server` namespace. For the full flow (build → push → deploy), see [Deploy to Kubernetes](#deploy-to-kubernetes) above.

1. **Create namespace, deployment, and service:**

   ```bash
   kubectl apply -f k8s/
   ```

   (Numbered filenames ensure the namespace is created before the deployment and service.)

2. **Wait for the pod to be ready:**

   ```bash
   kubectl -n mcp-server get pods -l app=mcp-server-http-streamable -w
   ```

   (Ctrl+C when `Running` and `1/1` ready.)

3. **Access the MCP server:**

   - **NodePort (cluster node IP):** The service exposes port **30800** on each node. Use:

     ```text
     http://<NODE_IP>:30800/mcp
     ```

     Get a node IP with `kubectl get nodes -o wide` or, on minikube, `minikube ip`.

   - **Port-forward (any cluster):**

     ```bash
     kubectl -n mcp-server port-forward svc/mcp-server-http-streamable 8000:8000
     ```

     Then use **<http://localhost:8000/mcp>** in your MCP client.

4. **Clean up:**

   ```bash
   kubectl delete -f k8s/
   ```

## Connecting a client

Use the Streamable HTTP URL when adding this server to an MCP client (e.g. Cursor, Claude Desktop):

- **URL:** `http://localhost:8000/mcp` (or your host/port if different)

**Cursor with uvx:** To run the server via uvx from Git in Cursor, add to your MCP config (e.g. `~/.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "McpServerHttpStreamable": {
      "command": "/opt/homebrew/bin/uvx",
      "args": [
        "--from",
        "git+https://github.com/douglasqsantos/mcp-server-http-streamable.git",
        "mcp-server"
      ]
    }
  }
}
```

Start the server from Cursor (or run `uvx --from git+https://... mcp-server` in a terminal), then use **http://localhost:8000/mcp** in clients that connect by URL.

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
   uv run mcp-server
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

### Testing with the server in Kubernetes (via proxy)

When the MCP server is running in the cluster (see [Deploy to Kubernetes](#deploy-to-kubernetes)), you can test it from your machine using the MCP Inspector and a **Streamable HTTP** connection **via proxy**.

1. **Deploy the server** and ensure the pod is running:

   ```bash
   kubectl apply -f k8s/
   kubectl -n mcp-server get pods -l app=mcp-server-http-streamable
   ```

2. **Get the NodePort** from the service (our manifest uses **30800**):

   ```bash
   kubectl -n mcp-server get svc mcp-server-http-streamable
   ```

   Note the **PORT(S)** value (e.g. `8000:30800/TCP`) — the second number is the NodePort.

3. **Expose the service to localhost** (so the inspector can reach it):

   ```bash
   kubectl -n mcp-server port-forward svc/mcp-server-http-streamable 30800:8000
   ```

   Leave this running. The MCP endpoint is then at **<http://127.0.0.1:30800/mcp>**.

4. **Open the MCP Inspector** (run locally):

   ```bash
   mcp dev
   ```

   This starts the inspector; the server itself runs in the cluster (step 3).

5. **In the inspector, add a new connection:**
   - **Transport type:** **Streamable HTTP**
   - **Connection type:** **Via proxy** (use the proxy option so the inspector connects to the K8s-exposed URL)
   - **URL:** **`http://127.0.0.1:30800/mcp`** (with the port-forward above; if you use the node IP and NodePort instead, use `http://<NODE_IP>:30800/mcp` and get the node IP with `kubectl get nodes -o wide` or `minikube ip`)

6. Connect and test the **greeting** tool as in the steps above.

## Tools

- **`greeting(name)`** — Returns a greeting for the given name.

## License

MIT License. See [LICENSE](LICENSE) for details. You may use, copy, modify, and distribute this sample for any purpose.
