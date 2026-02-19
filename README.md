# AlphaStrat

Algorithmic trading platform with a visual strategy builder, multi-strategy backtesting engine, and live execution via Interactive Brokers. Built with a FastAPI backend, React frontend, and the IBKR Client Portal REST API gateway.

## Architecture

```
AlphaStrat/
├── server-local/          # submodule: ibkr_trading_system
│   ├── algo/              # trading pipeline (Python)
│   │   └── trading-pipeline/
│   │       ├── src/       # engine, strategies, API server
│   │       ├── configs/   # YAML strategy configs (22 presets)
│   │       └── tests/     # integration tests
│   ├── client/            # IBKR Client Portal Gateway (Java)
│   ├── run.sh             # full-stack launcher
│   ├── gateway.sh         # IBKR gateway start/stop
│   ├── pipeline.sh        # trading pipeline start/stop
│   ├── serverlocal.sh     # API server start/stop
│   └── status.sh          # terminal status dashboard
├── app/                   # submodule: trading-strategy-builder
│   └── frontend/          # React + Vite dashboard
├── start.sh               # all-services launcher
└── docker-compose.yml     # containerised deployment
```

### Services

| Service | Port | Description |
|---------|------|-------------|
| IBKR Client Portal Gateway | 5000 | Java REST API for market data & order execution |
| Backend API (FastAPI) | 8020 | Pipeline orchestration, backtesting, config management |
| Frontend (React + Vite) | 5173 | Visual strategy builder & monitoring dashboard |

## Prerequisites

- Python 3.10+
- Node.js 18+ / npm
- Java 11+ (for IBKR Client Portal Gateway)
- An Interactive Brokers account (paper or live)

## Setup

### 1. Clone with submodules

```bash
git clone --recurse-submodules https://github.com/AlphaStrat/AlphaStrat.git
cd AlphaStrat
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

### 2. Install Python dependencies

```bash
cd server-local/algo/trading-pipeline
pip install -r requirements.txt
cd ../../..
```

### 3. Install frontend dependencies

```bash
cd app/frontend
npm install
cd ../..
```

### 4. Configure environment

```bash
# server-local/algo/.env
DRY_RUN=true          # set to false for live order execution
```

## Running

### Option A — Full stack via `run.sh` (recommended)

```bash
cd server-local
./run.sh                           # starts gateway → API → waits
./run.sh --config configs/system_hmm_montecarlo.yaml   # also starts a pipeline
```

This will:
1. Start the IBKR Client Portal Gateway on `:5000`
2. Open a browser for IBKR authentication
3. Start the API server on `:8020`
4. Optionally launch a trading pipeline

### Option B — Individual services

```bash
# Terminal 1: IBKR Gateway
cd server-local && ./gateway.sh

# Terminal 2: API Server
cd server-local && ./serverlocal.sh

# Terminal 3: Trading Pipeline
cd server-local && ./pipeline.sh configs/system_hmm_montecarlo.yaml

# Terminal 4: Frontend
cd app/frontend && npm run dev
```

### Option C — Docker Compose

#### Prerequisites

- Docker 20.10+
- Docker Compose V2 plugin

If you only have the `docker.io` package (common on Ubuntu), install the Compose V2 plugin:

```bash
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
```

> **Note:** The legacy `docker-compose` (V1, pip-installed) may fail with `URLSchemeUnknown: http+docker` on newer Python/requests versions. Use the V2 plugin (`docker compose`) instead.

#### Build & Run

```bash
# Initialise submodules (if not already done)
git submodule update --init --recursive

# Build images and start all services
docker compose up --build -d

# Verify everything is running
docker compose ps
```

This starts three containers:

| Container | Service | Port | Healthcheck |
|-----------|---------|------|-------------|
| `alphastrat-backend-1` | Trading Engine API (FastAPI) | 8020 | `GET /api/health` |
| `alphastrat-frontend-api-1` | Strategy Builder API (FastAPI) | 8010 | `GET /` |
| `alphastrat-frontend-ui-1` | React + Vite dev server | 5173 | — |

#### Stopping

```bash
docker compose down
```

#### Port Conflicts

If a port is already in use, free it before starting:

```bash
sudo lsof -ti:8020 | xargs -r sudo kill -9
docker compose up -d
```

### Option D — All-in-one script

```bash
./start.sh
```

Installs dependencies automatically, starts backend + frontend API + UI dev server.

## Web App

Open **http://localhost:5173** in your browser.

### Visual Strategy Builder

The main canvas is a node-based editor where you build strategies by connecting:
- **Indicator nodes** — RSI, SMA, EMA, MACD, Bollinger Bands, Stochastic, ATR, ADX
- **Logic nodes** — comparison operators (>, <, crossover, etc.)
- **Action nodes** — Buy/Sell with optional stop-loss and take-profit

### Backtest Panel

Click the **Backtest** tab in the right panel to run a backtest:
1. Enter symbols (comma-separated), years, starting capital, and slippage
2. Click **Run Backtest**
3. Results show total return, Sharpe ratio, max drawdown, equity curve, and trade log

If no strategy nodes are on the canvas, it falls back to a default RSI(14) strategy (buy < 30, sell > 70).

### Pipeline Monitor

Click the **Monitor** tab to view live system status:
- Gateway status (running, authenticated, PID)
- Pipeline status (phase, step count, PID)
- Live log stream from the trading engine
- Start/stop controls for gateway and pipeline
- Config selector with dry-run toggle

### Config Editor

Click the **Configs** tab to browse, edit, and create YAML strategy configurations. 22 presets are included.

## Terminal Status Dashboard

```bash
cd server-local
./status.sh           # one-shot status
./status.sh --loop    # auto-refresh every 5 seconds
```

Shows services, authentication, account summary, positions, and recent decisions.

## Running Tests

### Running tests in Docker

With the containers running (`docker compose up -d`), you can execute the full test suites inside the containers.

#### Backend Trading Engine tests (server-local)

```bash
# Copy tests into the container (not included in the production image)
docker cp server-local/algo/trading-pipeline/tests alphastrat-backend-1:/app/tests

# Install test dependencies
docker compose exec backend pip install pytest httpx hmmlearn
docker compose exec backend apt-get update -qq && \
  docker compose exec backend apt-get install -y -qq libgomp1

# Run the full suite
docker compose exec -w /app backend python -m pytest tests/ -v

# Run specific test files
docker compose exec -w /app backend python -m pytest tests/test_api_integration.py -v
docker compose exec -w /app backend python -m pytest tests/test_backtesting_engine_basic.py -v
docker compose exec -w /app backend python -m pytest tests/test_expression_engine.py -v

# Run specific test classes
docker compose exec -w /app backend python -m pytest tests/test_api_integration.py -v -k "TestBacktesting"
docker compose exec -w /app backend python -m pytest tests/test_api_integration.py -v -k "TestConfigCRUD"
```

**Expected results:** ~181 passed, 6 failed, 1 skipped. The 6 failures are in `TestHealthStatus`, `TestGatewayControl`, `TestPipelineControl`, and `TestResponseContracts` — these require a live IBKR Client Portal Gateway which is not available in the Docker environment.

#### Frontend Strategy Builder API tests (app)

```bash
# Install test dependencies
docker compose exec frontend-api pip install pytest requests matplotlib

# Run the full suite
docker compose exec -w /app frontend-api python -m pytest -v
```

**Expected results:** 20 passed, 3 skipped. The 3 skips are cross-service tests (`TestCrossService`) that require the backend engine to be reachable from the frontend-api container.

#### Backend test coverage (Docker)

| Test File | Tests | What it covers |
|-----------|-------|----------------|
| `test_api_integration.py` | 63 | All API endpoints (health, configs, backtest, gateway, pipeline, logs, CORS) |
| `test_backtesting_engine_basic.py` | 5 | Core backtesting engine logic |
| `test_backtesting_summary.py` | 4 | Backtest summary statistics |
| `test_cli_preflight_offline.py` | 1 | CLI preflight checks (offline mode) |
| `test_cli_safety_and_thresholds.py` | 2 | Safety guards and threshold validation |
| `test_expression_engine.py` | 3 | Expression-based strategy evaluation |
| `test_hmm_xgb_strategy.py` | 11 | HMM regime detection + XGBoost signal strategy |
| `test_mean_rev_and_factor_strategies.py` | 27 | Mean-reversion and composite factor strategies |
| `test_order_roundtrip.py` | 13 | Order lifecycle and round-trip execution |
| `test_system.py` | 40 | Full system integration |
| `test_vol_regime_categorical_strategy.py` | 19 | Volatility regime categorical strategy |

#### Frontend API test coverage (Docker)

| Test Class | Tests | What it covers |
|------------|-------|----------------|
| `TestAppRoot` | 4 | Root endpoint, indicators list, required fields, known indicators |
| `TestCompilation` | 11 | PineScript/C#/MQL compilation, RSI/MACD/crossover strategies, edge cases |
| `TestStrategyStorage` | 2 | Save and list strategies |
| `TestCrossService` | 3 | Cross-service integration (skipped without backend engine) |
| `TestValidation` | 3 | Strategy validation (valid, invalid node type, missing ID) |

### Running tests locally (without Docker)

The integration test suite covers all API endpoints:

```bash
cd server-local/algo/trading-pipeline

# Start the API server first
cd src && python3 api.py &
cd ..

# Run the full test suite
python -m pytest tests/test_api_integration.py -v

# Run specific test classes
python -m pytest tests/test_api_integration.py -v -k "TestBacktesting"
python -m pytest tests/test_api_integration.py -v -k "TestConfigCRUD"
python -m pytest tests/test_api_integration.py -v -k "TestGatewayPipeline"
```

### Local test coverage

| Test Class | Tests | What it covers |
|------------|-------|----------------|
| `TestHealthStatus` | 4 | Root, health, status, response time |
| `TestIndicatorsPresets` | 7 | Indicator list, fields, categories, presets |
| `TestConfigCRUD` | 6 | List, read, create, update, delete configs |
| `TestGraphConversion` | 4 | Visual graph to engine config conversion |
| `TestBacktesting` | 4 | Async backtest launch, polling, from-config |
| `TestMarketData` | 3 | OHLCV fetch, multi-symbol, invalid symbol |
| `TestLogsEndpoints` | 6 | Log lines, sources, levels, runs |
| `TestGatewayPipeline` | 6 | Gateway start/stop/login, pipeline control |
| `TestCORSAndEdgeCases` | 7 | CORS, preflight, content-type, 404/405 |
| `TestFrontendContracts` | 6 | Frontend component API contracts |

### Frontend tests

```bash
cd app/frontend
npx vitest run
```

## Strategies

| Strategy | Config | Description |
|----------|--------|-------------|
| HMM Monte Carlo | `system_hmm_montecarlo.yaml` | Hidden Markov Model regime detection + Monte Carlo path simulation |
| HMM XGBoost | `system_hmm_xgb.yaml` | HMM regimes + XGBoost signal prediction |
| Mean Reversion | `system_mean_reversion.yaml` | Statistical mean-reversion with z-score entry/exit |
| Composite Factor | `system_factor_*.yaml` | Multi-factor scoring (momentum, value, quality) |
| Vol Regime | `system_vol_regime_*.yaml` | Volatility-regime categorical classification |
| Expression-based | `rsi_only.yaml`, `rsi_sma.yaml`, etc. | Simple expression pipelines for visual builder |

## API Reference

The API server runs on `http://localhost:8020`. Key endpoint groups:

| Group | Endpoints | Purpose |
|-------|-----------|---------|
| System | `GET /api/health`, `GET /api/status` | Health checks, full system status |
| Configs | `GET/PUT/POST/DELETE /api/configs/*` | YAML config CRUD |
| Backtest | `POST /api/backtest`, `GET /api/backtest/progress/{id}` | Async backtest with progress polling |
| Pipeline | `POST /api/pipeline/start`, `POST /api/pipeline/stop` | Live pipeline control |
| Gateway | `POST /api/gateway/start`, `POST /api/gateway/stop`, `POST /api/gateway/login` | IBKR gateway lifecycle |
| Logs | `GET /api/logs`, `GET /api/logs/runs` | Pipeline and gateway log access |
| Graph | `POST /api/convert-graph`, `POST /api/graph-to-yaml` | Visual strategy conversion |

## License

Proprietary. All rights reserved.