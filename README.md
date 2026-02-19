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

```bash
docker compose up
```

Starts the backend API (`:8020`), frontend API (`:8010`), and frontend UI (`:5173`).

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

The integration test suite covers all API endpoints:

```bash
cd server-local/algo/trading-pipeline

# Start the API server first
cd src && python3 api.py &
cd ..

# Run the full test suite (63 tests)
python -m pytest tests/test_api_integration.py -v

# Run specific test classes
python -m pytest tests/test_api_integration.py -v -k "TestBacktesting"
python -m pytest tests/test_api_integration.py -v -k "TestConfigCRUD"
python -m pytest tests/test_api_integration.py -v -k "TestGatewayPipeline"
```

### Test coverage

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