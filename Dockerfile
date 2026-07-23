# ── Stage 1: Build React dashboard ───────────────────────────────────────────
FROM node:20-slim AS ui-builder

WORKDIR /workspace

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy workspace manifest files
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY lib/ lib/
COPY artifacts/conductor-ui/ artifacts/conductor-ui/

# Install and build
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @workspace/conductor-ui run build

# ── Stage 2: Python API server ────────────────────────────────────────────────
FROM python:3.11-slim AS api

WORKDIR /app

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY artifacts/api-server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the conductor package
COPY artifacts/api-server/conductor/ conductor/
COPY artifacts/api-server/benchmarks/ benchmarks/
COPY artifacts/api-server/tests/ tests/

# Copy built UI (serve as static files)
COPY --from=ui-builder /workspace/artifacts/conductor-ui/dist/ /app/static/

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8080/api/healthz || exit 1

# Serve static UI via uvicorn's static file mount + API
CMD ["python", "-m", "uvicorn", "conductor.api:app", \
     "--host", "0.0.0.0", "--port", "8080", "--workers", "2"]
