.PHONY: install dev test test-coverage benchmark-quick benchmark-full lint clean docker-build docker-up docker-down help

# ── Variables ─────────────────────────────────────────────────────────────────
PYTHON      ?= python
PIP         := $(PYTHON) -m pip
PYTEST      := $(PYTHON) -m pytest
API_DIR     := artifacts/api-server
UI_DIR      := artifacts/conductor-ui
BENCH_DIR   := $(API_DIR)/benchmarks

# ── Help ──────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  CONDUCTOR — Multi-Agent Orchestration OS"
	@echo ""
	@echo "  Usage: make <target>"
	@echo ""
	@echo "  Development:"
	@echo "    install          Install all Python and Node.js dependencies"
	@echo "    dev              Start API server and dashboard (requires tmux or two terminals)"
	@echo "    dev-api          Start only the FastAPI backend"
	@echo "    dev-ui           Start only the React dashboard"
	@echo ""
	@echo "  Testing:"
	@echo "    test             Run all pytest tests"
	@echo "    test-coverage    Run tests with HTML coverage report"
	@echo "    lint             Run ruff linter on Python code"
	@echo ""
	@echo "  Benchmarks:"
	@echo "    benchmark-quick  Run 5-task quick benchmark"
	@echo "    benchmark-full   Run 20-task full benchmark"
	@echo "    benchmark-api    Run API-only benchmark (requires all API keys)"
	@echo ""
	@echo "  Docker:"
	@echo "    docker-build     Build Docker image"
	@echo "    docker-up        Start with docker-compose"
	@echo "    docker-down      Stop docker-compose services"
	@echo ""
	@echo "  Cleanup:"
	@echo "    clean            Remove build artifacts and cache"
	@echo ""

# ── Install ───────────────────────────────────────────────────────────────────
install:
	@echo "→ Installing Python dependencies..."
	cd $(API_DIR) && $(PIP) install -r requirements.txt
	@echo "→ Installing Node.js dependencies..."
	pnpm install
	@echo "✓ Installation complete"

# ── Dev servers ───────────────────────────────────────────────────────────────
dev-api:
	@echo "→ Starting CONDUCTOR API on :8080..."
	cd $(API_DIR) && $(PYTHON) -m uvicorn conductor.api:app --host 0.0.0.0 --port 8080 --reload

dev-ui:
	@echo "→ Starting CONDUCTOR Dashboard..."
	pnpm --filter @workspace/conductor-ui run dev

dev:
	@echo "→ Starting API (background) and Dashboard..."
	@trap 'kill %1 %2 2>/dev/null' INT; \
	  (cd $(API_DIR) && $(PYTHON) -m uvicorn conductor.api:app --host 0.0.0.0 --port 8080 --reload) & \
	  (pnpm --filter @workspace/conductor-ui run dev) & \
	  wait

# ── Tests ─────────────────────────────────────────────────────────────────────
test:
	@echo "→ Running tests..."
	cd $(API_DIR) && $(PYTEST) tests/ -v --tb=short

test-coverage:
	@echo "→ Running tests with coverage..."
	cd $(API_DIR) && $(PYTEST) tests/ -v \
	  --cov=conductor \
	  --cov-report=term-missing \
	  --cov-report=html:coverage_html \
	  --cov-fail-under=70
	@echo "✓ Coverage report: $(API_DIR)/coverage_html/index.html"

test-fast:
	@echo "→ Running fast tests (no network)..."
	cd $(API_DIR) && $(PYTEST) tests/ -v --tb=short -m "not asyncio"

# ── Linting ───────────────────────────────────────────────────────────────────
lint:
	@echo "→ Running ruff..."
	cd $(API_DIR) && $(PYTHON) -m ruff check conductor/ benchmarks/ tests/ --fix || true

# ── Benchmarks ────────────────────────────────────────────────────────────────
benchmark-quick:
	@echo "→ Running quick benchmark (5 tasks)..."
	cd $(API_DIR) && $(PYTHON) benchmarks/evaluate.py --suite quick --output benchmark_quick.json
	@echo "✓ Report: $(API_DIR)/benchmark_quick.json"

benchmark-full:
	@echo "→ Running full benchmark (20 tasks)..."
	cd $(API_DIR) && $(PYTHON) benchmarks/evaluate.py --suite full --output benchmark_full.json
	@echo "✓ Report: $(API_DIR)/benchmark_full.json"

benchmark-api:
	@echo "→ Running API-only benchmark (requires all API keys)..."
	cd $(API_DIR) && $(PYTHON) benchmarks/evaluate.py --suite api_only --output benchmark_api.json

benchmark-reasoning:
	@echo "→ Running reasoning-only benchmark..."
	cd $(API_DIR) && $(PYTHON) benchmarks/evaluate.py --suite reasoning_only --output benchmark_reasoning.json

# ── Docker ────────────────────────────────────────────────────────────────────
docker-build:
	@echo "→ Building Docker image..."
	docker build -t conductor:latest .

docker-up:
	@echo "→ Starting with docker-compose..."
	docker-compose up --build -d
	@echo "✓ API:       http://localhost:8080/api/healthz"
	@echo "✓ Dashboard: http://localhost:3000"

docker-down:
	@echo "→ Stopping docker-compose..."
	docker-compose down

# ── Clean ─────────────────────────────────────────────────────────────────────
clean:
	@echo "→ Cleaning..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "coverage_html" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.pyc" -delete 2>/dev/null || true
	find . -name "benchmark_*.json" -delete 2>/dev/null || true
	@echo "✓ Clean complete"
